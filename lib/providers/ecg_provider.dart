import 'dart:async';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import '../db/database.dart';
import '../models/ecg.dart';
import '../services/ecg_ble_service.dart';
import '../services/ecg_storage_service.dart';
import '../services/training_ble.dart';
import '../services/activity_background.dart';
import 'activity_background_provider.dart';
import 'database_provider.dart';
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
    this.error,
    this.heartRate,
    this.heartRateAt,
    this.contact,
  });
  final EcgPhase phase;
  final String? recordingId, error;
  final TrainingDevice? device;
  final int count, durationMs, gaps;
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
  StreamSubscription<dynamic>? _heartRate;
  int? _bpm;
  DateTime? _bpmAt;
  bool? _contact;
  bool _ownsLease = true;
  EcgTimeline? _timeline;
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
    try {
      await _ready;
      if (generation != _generation) return;
      final sensor = ref.read(ecgDeviceFactoryProvider)();
      _sensor = sensor;
      await sensor.connect(device);
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
            activityId: activityId,
          );
      if (generation != _generation) {
        await ref.read(ecgStorageProvider).finish(id, interrupted: true);
        await sensor.dispose();
        return;
      }
      _timeline = EcgTimeline(sensor.sampleRateHz);
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
      );
      _frames = sensor.frames.listen(
        _receive,
        onError: (Object error) {
          unawaited(stop(interrupted: true, error: error.toString()));
        },
      );
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
      await sensor.start();
      if (generation != _generation) return;
      _publish(EcgPhase.recording);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _enqueue());
    } catch (e) {
      if (generation != _generation) return;
      await stop(interrupted: true, error: e.toString());
    }
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
      preview: List.unmodifiable(_preview),
      error: error,
      heartRate: _bpm,
      heartRateAt: _bpmAt,
      contact: _contact,
    );
  }

  void _enqueue() {
    if (_pending.isEmpty || _writeError != null || state.recordingId == null) {
      return;
    }
    final chunks = List.of(_pending);
    _lastFlushUs = _timeline!.durationUs;
    _pending.clear();
    final sequence = _sequence;
    _sequence += chunks.length;
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
      await _heartRate?.cancel();
      _heartRate = null;
      _frames = null;
      await _sensor?.dispose();
      _sensor = null;
      _enqueue();
      await _writes;
      final id = state.recordingId;
      if (id != null) {
        await ref
            .read(ecgStorageProvider)
            .finish(id, interrupted: interrupted || _writeError != null);
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
    unawaited(_heartRate?.cancel());
    unawaited(_sensor?.dispose());
    unawaited(_actions?.cancel());
    unawaited(_background.stop('ecg').catchError((Object _) {}));
    super.dispose();
  }
}
