import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import '../db/database.dart';
import '../models/ecg.dart';
import '../services/coach_tasks.dart' show ecgClinical, ecgClinicalMode;
import '../services/ecg_analysis.dart';
import '../services/ecg_coach_context.dart';
import '../services/ecg_ble_service.dart';
import '../services/ecg_storage_service.dart';
import '../services/ecg_sleep_staging_service.dart';
import '../services/ecg_respiration_review.dart';
import '../utils/log.dart';
import '../services/training_ble.dart';
import '../services/activity_background.dart';
import 'activity_background_provider.dart';
import 'database_provider.dart';
import 'day_data_provider.dart' show syncStatusListenerProvider;
import 'polar_h10_provider.dart';
import 'device_recording_owner_provider.dart';
import 'hrv_reminder_provider.dart' show hrvCaptureActiveProvider;

export '../models/ecg.dart';
export 'device_recording_owner_provider.dart';
export '../services/ecg_storage_service.dart' show EcgImport, decodeEcgImport;
export '../services/training_ble.dart' show TrainingDevice;

final ecgStorageProvider = Provider(
  (ref) => EcgStorageService(ref.watch(databaseProvider)),
);
final ecgHistoryProvider = StreamProvider(
  (ref) => ref.watch(ecgStorageProvider).watchHistory(),
);

/// Exploratory H10 EDR/movement visualization for a completed paired capture.
final ecgRespirationReviewProvider = FutureProvider.family((
  ref,
  String id,
) async {
  final storage = ref.read(ecgStorageProvider);
  final row = await storage.recording(id);
  if (row == null || row.sampleRateHz == null) return null;
  final metadata = jsonDecode(row.metadataJson) as Map<String, dynamic>;
  final accelerationRate = (metadata['accelerometer_sample_rate_hz'] as num?)
      ?.toDouble();
  if (accelerationRate == null || accelerationRate <= 0) return null;
  final acceleration = await storage.accelerationChunks(id);
  if (acceleration.isEmpty) return null;
  return reviewH10Signals(
    ecg: await storage.chunks(id),
    acceleration: acceleration,
    ecgRateHz: row.sampleRateHz!,
    accelerationRateHz: accelerationRate,
  );
});

/// Recordings swiped away while their undo is still on offer: hidden from the
/// lists, deleted for good once the offer has passed.
final pendingEcgDeletesProvider = StateProvider<Set<String>>((ref) => const {});

/// The analysis of one waveform recording, worked out off the UI thread
/// once and kept (a few kilobytes), so follow-up questions in the coach chat
/// do not analyse it again.
final ecgAnalysisProvider = FutureProvider.family<EcgAnalysis, String>((
  ref,
  id,
) async {
  final storage = ref.read(ecgStorageProvider);
  final row = await storage.recording(id);
  final hz = row?.sampleRateHz;
  if (row == null || row.kind != 'waveform' || hz == null) {
    throw StateError('ECG $id has no waveform to analyse.');
  }
  final chunks = await storage.chunks(id);
  // FjeliaPro's medical reading runs in the same isolate, when available.
  final clinical = ecgClinicalMode ? ecgClinical : null;
  return Isolate.run(() => analyzeEcg(chunks, hz, clinical: clinical));
});

/// What the coach chat adds to its context about ECGs for one question.
class EcgCoachContext {
  const EcgCoachContext({this.lines = const [], this.detail});

  /// Lines to add as they are: availability, or a request to choose.
  final List<String> lines;

  /// The recording whose full analysis the question needs; the chat asks
  /// for the medical warning to be confirmed before loading it.
  final EcgRecording? detail;
}

final ecgCoachProvider = Provider(EcgCoach.new);

/// ECG awareness by default, the full analysis on demand.
class EcgCoach {
  EcgCoach(this.ref);
  final Ref ref;

  /// The training-only notice is new to everyone who confirmed the medical
  /// warning before, so it has its own key.
  static String get _warningKey => ecgClinicalMode
      ? 'ecg_coach_warning_confirmed_v1'
      : 'ecg_coach_training_notice_confirmed_v1';

  /// The medical warning before an ECG goes to the coach is shown once ever;
  /// these record and read that it was confirmed.
  Future<bool> warningConfirmed() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_warningKey) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> confirmWarning() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_warningKey, true);
    } catch (_) {}
  }

  /// Reads [question]: an ECG question about a recording that can be told
  /// apart asks for its [EcgCoachContext.detail]; otherwise the coach only
  /// learns which recordings exist. [current] is the recording this chat is
  /// already about; [choosing] says the coach just asked which one.
  Future<EcgCoachContext> prepare({
    required String question,
    ActivityRecord? activity,
    String? current,
    bool choosing = false,
    DateTime? now,
  }) async {
    final rows = await ref.read(ecgStorageProvider).history();
    final at = now ?? DateTime.now();
    // A follow-up in a chat already about a recording stays with it, unless
    // the question names another time.
    if (current != null && askedClock(question) == null) {
      final row = rows.where((r) => r.recordingId == current).firstOrNull;
      if (row != null) return EcgCoachContext(detail: row);
    }
    final own = activity == null
        ? [
            for (final r in rows)
              if (at.difference(r.recordedAt).inDays < 14) r,
          ].take(3).toList()
        : activityEcgs(rows, activity);
    final available = [
      for (final r in withoutFragments(own)) ecgAvailableLine(r),
    ];
    if (!choosing && !asksAboutEcg(question)) {
      return EcgCoachContext(lines: available);
    }
    return switch (pickEcg(
      rows,
      question: question,
      activity: activity,
      now: at,
    )) {
      OneEcg(:final recording) => EcgCoachContext(detail: recording),
      SeveralEcgs(:final recordings) => EcgCoachContext(
        lines: [...available, ecgChoiceLine(recordings)],
      ),
      NoEcg() => EcgCoachContext(lines: available),
    };
  }

  /// The full analysis lines of [row] for [question].
  Future<List<String>> detail(
    EcgRecording row,
    String question, {
    ActivityRecord? activity,
  }) async {
    final analysis = row.kind == 'waveform' && row.sampleRateHz != null
        ? await ref.read(ecgAnalysisProvider(row.recordingId).future)
        : null;
    String? reportText;
    if (row.kind == 'report' && ecgClinicalMode) {
      try {
        reportText = await ref.read(ecgStorageProvider).extractReportText(row);
      } catch (_) {
        // The context builder tells the coach when report text is unavailable.
      }
    }
    return ecgDetailLines(
      row,
      analysis,
      reportText: reportText,
      minutes: askedMinutes(question),
      activity: activity,
    );
  }
}

final ecgDeviceFactoryProvider = Provider<EcgDeviceService Function()>(
  (ref) => EcgDeviceService.new,
);
final ecgChunksProvider = FutureProvider.autoDispose
    .family<List<EcgChunk>, String>(
      (ref, id) => ref.watch(ecgStorageProvider).chunks(id),
    );
final recordingActivitiesProvider =
    FutureProvider.autoDispose<List<ActivityRecord>>(
      (ref) =>
          (ref
                  .watch(databaseProvider)
                  .select(ref.watch(databaseProvider).activityRecords)
                ..orderBy([(t) => OrderingTerm.desc(t.startDate)])
                ..limit(100))
              .get(),
    );

final ecgActionsProvider = Provider(EcgActions.new);

class EcgActions {
  EcgActions(this.ref);
  final Ref ref;
  Future<List<TrainingDevice>> scan() =>
      scanTrainingDevices(nameContains: 'Polar H10');
  Future<void> remember(TrainingDevice device) => ref
      .read(polarH10ActionsProvider)
      .pair(H10Device(device.id, device.name, device.rssi));
  Future<({String name, List<int> bytes, EcgImport preview})?> pick() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return null;
    final file = files.first;
    final bytes = await file.xFile.readAsBytes();
    return (name: file.name, bytes: bytes, preview: decodeEcgImport(bytes));
  }
}

enum EcgPhase { idle, connecting, recording, saving, saved, failed }

class EcgRecorderState {
  const EcgRecorderState({
    this.phase = EcgPhase.idle,
    this.recordingId,
    this.device,
    this.count = 0,
    this.durationMs = 0,
    this.rate = 130,
    this.gaps = 0,
    this.preview = const [],
    this.accelerationSamples = 0,
    this.withAcceleration = false,
    this.error,
    this.heartRate,
    this.heartRateAt,
    this.contact,
  });
  final EcgPhase phase;
  final String? recordingId, error;
  final TrainingDevice? device;
  final int count, durationMs, gaps;
  final int accelerationSamples;
  final bool withAcceleration;
  final double rate;
  final int? heartRate;
  final DateTime? heartRateAt;
  final bool? contact;
  final List<EcgChunk> preview;
  bool get active =>
      phase == EcgPhase.connecting ||
      phase == EcgPhase.recording ||
      phase == EcgPhase.saving;
}

final ecgRecorderProvider =
    StateNotifierProvider<EcgRecorder, EcgRecorderState>(EcgRecorder.new);

class EcgRecorder extends StateNotifier<EcgRecorderState>
    with WidgetsBindingObserver {
  EcgRecorder(this.ref) : super(const EcgRecorderState()) {
    _ready = ref.read(ecgStorageProvider).recoverInterrupted();
    _background = ref.read(activityBackgroundProvider);
    _actions = _background.actions.listen((action) {
      if (_ownsLease &&
          state.active &&
          {'pause', 'stop', 'interrupted'}.contains(action)) {
        unawaited(stop(interrupted: action == 'interrupted'));
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }
  final Ref ref;
  late final Future<void> _ready;
  late final ActivityBackground _background;
  StreamSubscription<String>? _actions;
  EcgDeviceService? _sensor;
  StreamSubscription<EcgFrame>? _frames;
  StreamSubscription<AccelerationFrame>? _accelerationFrames;
  StreamSubscription<dynamic>? _heartRate;
  int? _bpm;
  DateTime? _bpmAt;
  bool? _contact;
  bool _ownsLease = true;
  EcgTimeline? _timeline;
  AccelerationTimeline? _accelerationTimeline;
  bool _withAcceleration = false;
  Timer? _timer;
  final _pending = <EcgChunk>[], _preview = <EcgChunk>[];
  Future<void> _writes = Future.value();
  Future<void>? _stopping;
  Object? _writeError;
  int _sequence = 0, _generation = 0;
  int _lastFlushUs = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (this.state.active) _enqueue();
  }

  Future<void> start(
    TrainingDevice device, {
    String? activityId,
    String? parentOwner,
    bool withAcceleration = false,
    String purpose = 'ecg',
  }) async {
    if (state.active) return;
    final owner = ref.read(deviceRecordingOwnerProvider);
    if ((parentOwner == null ? owner != null : owner != parentOwner) ||
        ref.read(hrvCaptureActiveProvider)) {
      throw StateError('Finish the other device recording first.');
    }
    _ownsLease = parentOwner == null;
    if (_ownsLease) {
      ref.read(deviceRecordingOwnerProvider.notifier).state = 'ecg';
    }
    final generation = ++_generation;
    state = EcgRecorderState(phase: EcgPhase.connecting, device: device);
    _stopping = null;
    _writeError = null;
    _sequence = 0;
    _lastFlushUs = 0;
    _pending.clear();
    _preview.clear();
    _bpm = null;
    _bpmAt = null;
    _contact = null;
    _withAcceleration = withAcceleration;
    _pendingAcceleration.clear();
    try {
      await _ready;
      if (generation != _generation) return;
      final sensor = ref.read(ecgDeviceFactoryProvider)();
      _sensor = sensor;
      await sensor.connect(device, withAcceleration: withAcceleration);
      if (generation != _generation) {
        await sensor.dispose();
        return;
      }
      final id = await ref
          .read(ecgStorageProvider)
          .begin(
            deviceId: device.id,
            deviceName: device.name,
            rate: sensor.sampleRateHz,
            resolution: sensor.resolutionBits,
            accelerationRate: withAcceleration
                ? sensor.accelerationRateHz
                : null,
            purpose: purpose,
            activityId: activityId,
          );
      if (generation != _generation) {
        await ref.read(ecgStorageProvider).finish(id, interrupted: true);
        await sensor.dispose();
        return;
      }
      _timeline = EcgTimeline(sensor.sampleRateHz);
      _accelerationTimeline = withAcceleration
          ? AccelerationTimeline(sensor.accelerationRateHz)
          : null;
      _heartRate = sensor.heartRate.listen((packet) {
        _bpm = packet.bpm;
        _bpmAt = DateTime.now().toUtc();
        _contact = packet.contact;
        _publish(state.phase);
      });
      state = EcgRecorderState(
        phase: EcgPhase.connecting,
        recordingId: id,
        device: device,
        rate: sensor.sampleRateHz,
        withAcceleration: withAcceleration,
      );
      _frames = sensor.frames.listen(
        _receive,
        onError: (Object error) {
          unawaited(stop(interrupted: true, error: error.toString()));
        },
      );
      if (withAcceleration) {
        _accelerationFrames = sensor.acceleration.listen(
          _receiveAcceleration,
          onError: (Object error) {
            unawaited(stop(interrupted: true, error: error.toString()));
          },
        );
      }
      if (_ownsLease) await _background.prepare(gps: false);
      await _background.start(
        'ecg',
        gps: false,
        bluetooth: true,
        name: device.name,
      );
      if (generation != _generation) {
        await _background.stop('ecg');
        return;
      }
      await sensor.start(withAcceleration: withAcceleration);
      if (generation != _generation) return;
      _publish(EcgPhase.recording);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _enqueue());
    } catch (e) {
      if (generation != _generation) return;
      await stop(interrupted: true, error: e.toString());
    }
  }

  final _pendingAcceleration = <AccelerationChunk>[];

  void _receiveAcceleration(AccelerationFrame frame) {
    if (state.phase != EcgPhase.recording &&
        state.phase != EcgPhase.connecting) {
      return;
    }
    final chunk = _accelerationTimeline?.add(frame, DateTime.now().toUtc());
    if (chunk == null) return;
    _pendingAcceleration.add(chunk);
    _publish(state.phase);
    if (_pendingAcceleration.length >= 25) _enqueue();
  }

  void _receive(EcgFrame frame) {
    if (state.phase != EcgPhase.recording &&
        state.phase != EcgPhase.connecting) {
      return;
    }
    try {
      final chunk = _timeline!.add(frame, DateTime.now().toUtc());
      if (chunk == null) return;
      _pending.add(chunk);
      _preview.add(chunk);
      final cutoff = _timeline!.durationUs - 8000000;
      _preview.removeWhere(
        (c) => c.offsetUs + c.microvolts.length / state.rate * 1e6 < cutoff,
      );
      _publish(state.phase);
      // BLE delivery wakes iOS even when Dart timers were suspended. Flush
      // on the signal's clock as well, rather than relying on a UI timer.
      if (_timeline!.durationUs - _lastFlushUs >= 1000000) _enqueue();
    } catch (e) {
      unawaited(stop(interrupted: true, error: e.toString()));
    }
  }

  void _publish(EcgPhase phase, {String? error}) {
    final t = _timeline;
    state = EcgRecorderState(
      phase: phase,
      recordingId: state.recordingId,
      device: state.device,
      rate: state.rate,
      count: t?.sampleCount ?? 0,
      durationMs: (t?.durationUs ?? 0) ~/ 1000,
      gaps: t?.gaps ?? 0,
      accelerationSamples: _accelerationTimeline?.sampleCount ?? 0,
      withAcceleration: _withAcceleration,
      preview: List.unmodifiable(_preview),
      error: error,
      heartRate: _bpm,
      heartRateAt: _bpmAt,
      contact: _contact,
    );
  }

  void _enqueue() {
    if ((_pending.isEmpty && _pendingAcceleration.isEmpty) ||
        _writeError != null ||
        state.recordingId == null) {
      return;
    }
    final chunks = List.of(_pending);
    final acceleration = List.of(_pendingAcceleration);
    _lastFlushUs = _timeline!.durationUs;
    _pending.clear();
    _pendingAcceleration.clear();
    final sequence = _sequence;
    _sequence += chunks.length + acceleration.length;
    final id = state.recordingId!, t = _timeline!;
    final count = t.sampleCount, duration = t.durationUs ~/ 1000, gaps = t.gaps;
    _writes = _writes
        .then(
          (_) => ref
              .read(ecgStorageProvider)
              .append(
                id,
                chunks,
                sequence,
                acceleration: acceleration,
                count: count,
                durationMs: duration,
                gaps: gaps,
              ),
        )
        .catchError((Object error) {
          _writeError = error;
          unawaited(
            stop(interrupted: true, error: 'Could not save the ECG samples.'),
          );
        });
  }

  Future<void> stop({bool interrupted = false, String? error}) =>
      _stopping ??= _stop(interrupted: interrupted, error: error);

  Future<void> _stop({required bool interrupted, String? error}) async {
    ++_generation;
    _timer?.cancel();
    _timer = null;
    if (!state.active) return;
    _publish(EcgPhase.saving, error: error);
    try {
      try {
        await _sensor?.stop();
      } catch (_) {
        interrupted = true;
      }
      await _frames?.cancel();
      await _accelerationFrames?.cancel();
      await _heartRate?.cancel();
      _heartRate = null;
      _frames = null;
      _accelerationFrames = null;
      await _sensor?.dispose();
      _sensor = null;
      _enqueue();
      await _writes;
      final id = state.recordingId;
      if (id != null) {
        final storage = ref.read(ecgStorageProvider);
        final completed = !interrupted && _writeError == null;
        await storage.finish(id, interrupted: !completed);
        if (completed) {
          try {
            final row = await storage.recording(id);
            if (row != null &&
                row.kind == 'waveform' &&
                row.sampleRateHz != null &&
                jsonDecode(row.metadataJson)['capture_purpose'] == 'sleep') {
              final estimate = await EcgSleepStagingService().estimate(
                chunks: await storage.chunks(id),
                sampleRateHz: row.sampleRateHz!,
                recordedAt: row.recordedAt,
              );
              await storage.saveSleepStageEstimate(id, estimate);
              ref.read(syncStatusListenerProvider.notifier).state++;
            }
          } catch (e) {
            log('[ECG] automatic sleep-stage estimate failed: $e');
          }
        }
      }
      _publish(
        id == null ? EcgPhase.failed : EcgPhase.saved,
        error:
            error ??
            (_writeError == null
                ? null
                : 'Some ECG samples could not be saved.'),
      );
    } catch (e) {
      _publish(EcgPhase.failed, error: e.toString());
    } finally {
      await _background.stop('ecg');
      if (_ownsLease && ref.read(deviceRecordingOwnerProvider) == 'ecg') {
        ref.read(deviceRecordingOwnerProvider.notifier).state = null;
      }
    }
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_frames?.cancel());
    unawaited(_accelerationFrames?.cancel());
    unawaited(_heartRate?.cancel());
    unawaited(_sensor?.dispose());
    unawaited(_actions?.cancel());
    unawaited(_background.stop('ecg').catchError((Object _) {}));
    super.dispose();
  }
}
