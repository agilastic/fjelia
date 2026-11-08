import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart' show TrainingSession;
import '../models/ftms.dart';
import '../models/indoor_recording.dart';
import '../models/rowing_stroke_average.dart';
import '../services/ftms_device_service.dart';
import '../services/indoor_fit_export.dart';
import '../services/indoor_recording_service.dart';
import '../services/training_ble.dart';
import '../services/activity_background.dart';
import 'activity_background_provider.dart';
import '../theme/activity_colors.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'ecg_provider.dart';
import 'hrv_reminder_provider.dart' show hrvCaptureActiveProvider;
import 'hr_zones_provider.dart';
import 'hrv_training_provider.dart';
import 'planner_providers.dart';
import 'sync_provider.dart';

export '../models/ftms.dart';
export '../models/indoor_recording.dart';
export '../models/rowing_stroke_average.dart';
export '../services/training_ble.dart' show TrainingDevice;

final indoorStorageProvider = Provider(
  (ref) => IndoorRecordingService(ref.watch(databaseProvider)),
);
final indoorPendingProvider = StreamProvider(
  (ref) => ref.watch(indoorStorageProvider).watchPending(),
);
final manualRecordingPendingProvider = StreamProvider(
  (ref) => ref.watch(indoorStorageProvider).watchPending(manual: true),
);
final ftmsDeviceFactoryProvider = Provider<FtmsDeviceService Function()>(
  (ref) => FtmsDeviceService.new,
);
final indoorHeartRateFactoryProvider =
    Provider<IndoorHeartRateService Function()>(
      (ref) => IndoorHeartRateService.new,
    );
final indoorPairedProvider = FutureProvider((ref) async {
  final raw = await const FlutterSecureStorage().read(key: 'ftms_equipment_v1');
  if (raw == null) return null;
  try {
    return TrainingDevice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});
final indoorActionsProvider = Provider(IndoorActions.new);
final indoorHeartRatePairedProvider = FutureProvider((ref) async {
  final raw = await const FlutterSecureStorage().read(
    key: 'ftms_heart_rate_v1',
  );
  if (raw == null) return null;
  try {
    return TrainingDevice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

class IndoorActions {
  IndoorActions(this.ref);
  final Ref ref;
  Future<List<TrainingDevice>> scanEquipment() =>
      scanTrainingDevices(serviceUuids: const ['1826', '1814']);

  Future<List<TrainingDevice>> scanAllEquipment() => scanTrainingDevices();
  Future<List<TrainingDevice>> scanHeartRate() =>
      scanTrainingDevices(serviceUuid: '180d');
  Future<void> remember(TrainingDevice device) async {
    await const FlutterSecureStorage().write(
      key: 'ftms_equipment_v1',
      value: jsonEncode(device.toJson()),
    );
    ref.invalidate(indoorPairedProvider);
  }

  Future<void> forgetEquipment() async {
    if (ref.read(indoorRecorderProvider).active) {
      throw StateError('Finish the recording before forgetting this machine.');
    }
    await ref.read(indoorRecorderProvider.notifier).disconnectIdle();
    await const FlutterSecureStorage().delete(key: 'ftms_equipment_v1');
    ref.invalidate(indoorPairedProvider);
  }

  Future<String> exportFit(String id) async {
    final capture = await ref.read(indoorStorageProvider).load(id);
    if (capture == null) {
      throw StateError('This indoor recording no longer exists.');
    }
    final bp = await ref.read(indoorStorageProvider).bloodPressure(capture);
    final bytes = indoorFit(capture, bloodPressure: bp);
    final dir = await getTemporaryDirectory();
    final file = await File(
      '${dir.path}/fjelia_$id.fit',
    ).writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

enum IndoorPhase {
  idle,
  connecting,
  ready,
  starting,
  recording,
  paused,
  saving,
  saved,
}

class IndoorRecorderState {
  const IndoorRecorderState({
    this.phase = IndoorPhase.idle,
    this.device,
    this.machine,
    this.connected = false,
    this.capture,
    this.live = const {},
    this.rowing = const RowingLiveMetrics(),
    this.error,
    this.heartRateDevice,
    this.heartRateConnected = false,
    this.preferExternal = false,
    this.authorized = false,
    this.automaticPower = false,
    this.ranges = const {},
    this.reconnecting = false,
  });
  final IndoorPhase phase;
  final TrainingDevice? device, heartRateDevice;
  final FtmsMachine? machine;
  final bool connected,
      heartRateConnected,
      preferExternal,
      authorized,
      automaticPower,
      reconnecting;
  final IndoorCapture? capture;
  final Map<String, num> live;
  final RowingLiveMetrics rowing;
  final Map<FtmsTarget, FtmsRange> ranges;
  final String? error;
  bool get active =>
      phase == IndoorPhase.starting ||
      phase == IndoorPhase.recording ||
      phase == IndoorPhase.paused ||
      phase == IndoorPhase.saving;
}

final indoorRecorderProvider =
    StateNotifierProvider<IndoorRecorder, IndoorRecorderState>(
      IndoorRecorder.new,
    );

class IndoorRecorder extends StateNotifier<IndoorRecorderState>
    with WidgetsBindingObserver {
  IndoorRecorder(this.ref) : super(const IndoorRecorderState()) {
    _background = ref.read(activityBackgroundProvider);
    _locations = _background.locations.listen((fix) {
      if (_capture?.ingestLocation(
            fix,
            DateTime.now().toUtc(),
            recording: state.phase == IndoorPhase.recording,
          ) ??
          false) {
        unawaited(_tick());
      }
    });
    _backgroundErrors = _background.errors.listen(
      (error) => _publish(error: error),
    );
    _backgroundActions = _background.actions.listen((action) {
      if (!state.active) return;
      if (state.phase == IndoorPhase.starting &&
          {'pause', 'stop'}.contains(action)) {
        unawaited(discard());
        return;
      }
      if (action == 'stop') unawaited(finish());
      if (action == 'pause' || action == 'interrupted') unawaited(pause());
    });
    WidgetsBinding.instance.addObserver(this);
  }
  final Ref ref;
  late final ActivityBackground _background;
  StreamSubscription<dynamic>? _locations;
  StreamSubscription<String>? _backgroundActions, _backgroundErrors;
  FtmsDeviceService? _machine;
  IndoorHeartRateService? _heartRate;
  StreamSubscription<Map<String, num>>? _measurements;
  StreamSubscription<String>? _status;
  StreamSubscription<dynamic>? _hrPackets;
  IndoorCapture? _capture;
  final _clock = Stopwatch();
  int _baseMs = 0, _generation = 0, _lastCheckpoint = 0;
  int? _nativeStartedMs;
  bool _tickBusy = false;
  DateTime? _lastTickAt;
  Timer? _ticker;
  Future<void> _writes = Future.value();
  Future<void>? _pausing;
  Future<String?>? _finishing;
  bool _reconnecting = false, _autoBusy = false;
  int? _lastPowerStep;
  Object? _writeError;
  Map<String, num> _equipmentLive = {};
  final _equipmentTimes = <String, DateTime>{};
  bool _foreground = true;
  ProviderSubscription<EcgRecorderState>? _activityEcgSubscription;
  EcgRecorder? _activityEcg;
  bool _ownsActivityEcg = false;
  ({int bpm, DateTime at, bool? contact})? _lastExternal;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _foreground = false;
      // Leaving the UI relinquishes machine control, never recording.
      manualOverride();
      if (this.state.active) _checkpoint(this.state.phase.name);
    }
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      unawaited(_tick(force: true));
    }
  }

  void newRecording() {
    if (state.phase != IndoorPhase.saved) return;
    _capture = null;
    _baseMs = 0;
    _equipmentLive = {};
    _equipmentTimes.clear();
    state = const IndoorRecorderState();
    _lastExternal = null;
  }

  Future<void> disconnectIdle() async {
    if (state.active) return;
    ++_generation;
    await _closeDevices();
    if (!mounted) return;
    _capture = null;
    _equipmentLive = {};
    _equipmentTimes.clear();
    _lastExternal = null;
    state = const IndoorRecorderState();
  }

  void _publish({
    IndoorPhase? phase,
    bool? connected,
    String? error,
    TrainingDevice? device,
    TrainingDevice? heartRate,
    bool? hrConnected,
    bool? preferExternal,
    bool? automaticPower,
  }) {
    final at = DateTime.now().toUtc();
    final live = _capture?.live(at) ?? _freshEquipment(at);
    if (_capture == null && (preferExternal ?? state.preferExternal)) {
      live.remove('hr');
      final external = _lastExternal;
      if (external != null &&
          external.contact != false &&
          at.difference(external.at).inMilliseconds <= 5000) {
        live['hr'] = external.bpm;
        live['hr_source'] = 1;
      }
    }
    state = IndoorRecorderState(
      phase: phase ?? state.phase,
      device: device ?? state.device,
      machine: _machine?.machine ?? _capture?.machine ?? state.machine,
      connected: connected ?? state.connected,
      capture: _capture,
      live: Map.unmodifiable(live),
      rowing: _capture?.rowing.live(at) ?? const RowingLiveMetrics(),
      error: error,
      heartRateDevice: heartRate ?? state.heartRateDevice,
      heartRateConnected: hrConnected ?? state.heartRateConnected,
      preferExternal:
          preferExternal ??
          _capture?.preferExternalHeartRate ??
          state.preferExternal,
      authorized: _machine?.authorized ?? false,
      ranges: Map.unmodifiable(_machine?.ranges ?? {}),
      automaticPower: automaticPower ?? state.automaticPower,
      reconnecting: _reconnecting,
    );
  }

  Map<String, num> _freshEquipment(DateTime at) => {
    for (final e in _equipmentLive.entries)
      if (_equipmentTimes[e.key] != null &&
          at.difference(_equipmentTimes[e.key]!).inMilliseconds <= 5000)
        e.key: e.value,
  };

  Future<void> connect(TrainingDevice device, {FtmsMachine? preferred}) async {
    if (state.phase == IndoorPhase.connecting ||
        state.phase == IndoorPhase.saving) {
      return;
    }
    if (state.active && _capture?.device.id != device.id) {
      throw StateError('Finish this recording before changing equipment.');
    }
    final generation = ++_generation;
    final phase = state.active ? state.phase : IndoorPhase.ready;
    _publish(
      phase: IndoorPhase.connecting,
      connected: false,
      device: device,
      automaticPower: false,
    );
    try {
      await _measurements?.cancel();
      await _status?.cancel();
      await _machine?.dispose();
      final service = ref.read(ftmsDeviceFactoryProvider)();
      _machine = service;
      _measurements = service.measurements.listen((m) {
        final now = DateTime.now().toUtc();
        _equipmentLive = {..._equipmentLive, ...m};
        for (final key in m.keys) {
          _equipmentTimes[key] = now;
        }
        _capture?.ingest(
          m,
          now,
          recording: state.phase == IndoorPhase.recording,
        );
        unawaited(_tick());
        _publish();
      });
      _status = service.status.listen((status) {
        if (status == 'disconnected') {
          unawaited(_disconnected());
        } else if (status == 'manual') {
          _publish(automaticPower: false);
        } else if (status == 'invalid_packet') {
          _publish(
            error: 'A machine packet was invalid. Waiting for fresh data.',
          );
        }
      });
      await service.connect(device, preferred: preferred ?? _capture?.machine);
      if (generation != _generation) {
        await service.dispose();
        return;
      }
      _capture?.clearContinuity();
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      _publish(phase: phase, connected: true, device: device);
      await ref.read(indoorActionsProvider).remember(device);
    } catch (e) {
      if (generation != _generation) return;
      if (_capture != null && phase == IndoorPhase.recording) {
        _clock.stop();
        _baseMs += _clock.elapsedMilliseconds;
        _clock.reset();
        _capture!.elapsedMs = _baseMs;
      }
      _publish(
        phase:
            _capture != null &&
                (phase == IndoorPhase.recording || phase == IndoorPhase.paused)
            ? IndoorPhase.paused
            : IndoorPhase.idle,
        connected: false,
        error: e.toString(),
      );
    }
  }

  /// Records the connected machine. With [ecgDevice] an H10 records the ECG
  /// alongside, as in a phone-recorded activity; [includeBloodPressure] links
  /// the cuff readings taken during the session.
  Future<void> start({
    TrainingSession? session,
    TrainingDevice? ecgDevice,
    bool includeBloodPressure = false,
  }) async {
    if (state.phase != IndoorPhase.ready ||
        !state.connected ||
        _machine?.machine == null) {
      return;
    }
    if (!_foreground) return;
    if (ref.read(deviceRecordingOwnerProvider) != null ||
        ref.read(hrvCaptureActiveProvider)) {
      throw StateError('Finish the other device recording first.');
    }
    ref.read(deviceRecordingOwnerProvider.notifier).state = 'indoor';
    final generation = _generation;
    _publish(phase: IndoorPhase.starting);
    try {
      List<Map<String, dynamic>> planSteps = [];
      if (session != null) {
        if (activityKind(session.sport) !=
            activityKind(_machine!.machine!.activityType)) {
          throw StateError('Connect equipment that matches the planned sport.');
        }
        final prepared = await ref
            .read(trainingPlanServiceProvider)
            .prepareWorkout(session.id);
        planSteps = prepared.steps;
      }
      if (!_foreground) {
        throw StateError('Keep Fjelia open to start recording.');
      }
      final now = DateTime.now().toUtc();
      _capture = IndoorCapture(
        id: 'ftms_${const Uuid().v4()}',
        startedAt: now,
        device: state.device!,
        machine: _machine!.machine!,
        dataProtocol: _machine!.runningSpeedOnly ? 'rsc' : 'ftms',
        name: session?.title ?? '${_machine!.machine!.label} (Fjelia)',
        sessionId: session?.id,
        plannedStepsJson: session == null ? null : jsonEncode(planSteps),
        plannedDurationSeconds: session == null
            ? null
            : session.plannedDurationMin * 60,
        steps: indoorSteps(planSteps),
        includeBloodPressure: includeBloodPressure,
      );
      _capture!.heartRateDevice = ecgDevice ?? state.heartRateDevice;
      _capture!.preferExternalHeartRate =
          ecgDevice != null || state.preferExternal;
      _capture!.ecgDevice = ecgDevice;
      final external = _lastExternal;
      if (external != null) {
        _capture!.externalHeartRate(
          external.bpm,
          external.at,
          contact: external.contact,
        );
      }
      _capture!.event('start', now);
      _baseMs = 0;
      _writeError = null;
      _lastCheckpoint = 0;
      _lastPowerStep = null;
      await ref.read(indoorStorageProvider).checkpoint(_capture!, 'recording');
      if (!_foreground) {
        _publish(phase: IndoorPhase.paused);
        await ref.read(indoorStorageProvider).checkpoint(_capture!, 'paused');
        return;
      }
      await _background.prepare(gps: false, bluetooth: true);
      await _background.start(
        'activity',
        gps: false,
        bluetooth: true,
        name: _capture!.name,
      );
      if (ecgDevice != null) {
        await _startActivityEcg(ecgDevice);
        if (generation != _generation) return;
      }
      if (!await _startClock(generation)) return;
      _capture!.ingest(_freshEquipment(now), now, recording: true);
      _publish(
        phase: IndoorPhase.recording,
        preferExternal: _capture!.preferExternalHeartRate,
      );
    } catch (_) {
      await _stopActivityEcg();
      await _background.stop('activity');
      ref.read(deviceRecordingOwnerProvider.notifier).state = null;
      _publish(
        phase: _capture == null
            ? (state.connected ? IndoorPhase.ready : IndoorPhase.idle)
            : IndoorPhase.paused,
      );
      rethrow;
    }
  }

  /// A phone-recorded activity with optional GPS, ECG and HR. No watch needed.
  Future<void> startManual({
    required String type,
    required String name,
    TrainingDevice? ecgDevice,
    TrainingDevice? heartRateDevice,
    bool recordGps = false,
    bool includeBloodPressure = false,
  }) async {
    if (state.active || !_foreground) return;
    if (!{
      'running',
      'walking',
      'cycling',
      'treadmill_running',
    }.contains(type)) {
      throw ArgumentError('Unsupported activity type.');
    }
    if (type == 'treadmill_running' && recordGps) {
      throw ArgumentError('Turn off GPS for an indoor treadmill activity.');
    }
    if (ref.read(deviceRecordingOwnerProvider) != null ||
        ref.read(hrvCaptureActiveProvider)) {
      throw StateError('Finish the other device recording first.');
    }
    final generation = ++_generation;
    ref.read(deviceRecordingOwnerProvider.notifier).state = 'indoor';
    _capture = null;
    _equipmentLive = {};
    _equipmentTimes.clear();
    _lastExternal = null;
    _publish(phase: IndoorPhase.starting, connected: false);
    try {
      await _closeDevices();
      if (generation != _generation) return;
      await _background.prepare(
        gps: recordGps,
        bluetooth: ecgDevice != null || heartRateDevice != null,
      );
      if (generation != _generation) return;
      if (!_foreground) {
        throw StateError('Keep Fjelia open until recording starts.');
      }
      await _background.start(
        'activity',
        gps: recordGps,
        bluetooth: ecgDevice != null || heartRateDevice != null,
        name: name,
      );
      if (generation != _generation) {
        await _background.stop('activity');
        return;
      }
      final ecgId = ecgDevice == null
          ? null
          : await _startActivityEcg(ecgDevice);
      if (generation != _generation) return;
      if (ecgDevice == null && heartRateDevice != null) {
        await connectHeartRate(heartRateDevice);
      }
      if (generation != _generation) return;
      final now = DateTime.now().toUtc();
      _capture =
          IndoorCapture(
              id: 'manual_${const Uuid().v4()}',
              startedAt: now,
              device: const TrainingDevice(id: 'phone', name: 'Fjelia'),
              machine: type == 'cycling'
                  ? FtmsMachine.bike
                  : FtmsMachine.treadmill,
              dataProtocol: 'manual',
              activityTypeOverride: type,
              name: name,
              gpsEnabled: recordGps,
              includeBloodPressure: includeBloodPressure,
            )
            ..ecgDevice = ecgDevice
            ..heartRateDevice = ecgDevice ?? heartRateDevice
            ..preferExternalHeartRate =
                ecgDevice != null || heartRateDevice != null;
      if (ecgId != null) _capture!.ecgRecordingIds.add(ecgId);
      final hr = _lastExternal;
      if (hr != null) {
        _capture!.externalHeartRate(hr.bpm, hr.at, contact: hr.contact);
      }
      _capture!.event('start', now);
      _baseMs = 0;
      _writeError = null;
      _lastCheckpoint = 0;
      await ref.read(indoorStorageProvider).checkpoint(_capture!, 'recording');
      if (generation != _generation) return;
      if (!await _startClock(generation)) return;
      _ticker ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(_tick()),
      );
      _publish(
        phase: IndoorPhase.recording,
        connected: false,
        preferExternal: ecgDevice != null || heartRateDevice != null,
      );
    } catch (_) {
      if (generation != _generation) return;
      await _stopActivityEcg();
      await _background.stop('activity');
      if (ref.read(deviceRecordingOwnerProvider) == 'indoor') {
        ref.read(deviceRecordingOwnerProvider.notifier).state = null;
      }
      _publish(phase: _capture == null ? IndoorPhase.idle : IndoorPhase.paused);
      rethrow;
    }
  }

  Future<String?> _startActivityEcg(TrainingDevice device) async {
    final generation = _generation;
    _activityEcgSubscription?.close();
    final recorder = ref.read(ecgRecorderProvider.notifier);
    _activityEcg = recorder;
    _ownsActivityEcg = true;
    _activityEcgSubscription = ref.listen(ecgRecorderProvider, (_, current) {
      if (!_ownsActivityEcg || !mounted) return;
      if (current.heartRate != null && current.heartRateAt != null) {
        _lastExternal = (
          bpm: current.heartRate!,
          at: current.heartRateAt!,
          contact: current.contact,
        );
        _capture?.externalHeartRate(
          current.heartRate!,
          current.heartRateAt!,
          contact: current.contact,
        );
      }
      _publish(
        hrConnected: current.phase == EcgPhase.recording,
        error: current.error,
      );
      unawaited(_tick());
    });
    await recorder.start(device, parentOwner: 'indoor');
    if (generation != _generation) return null;
    final current = ref.read(ecgRecorderProvider);
    if (current.phase != EcgPhase.recording) {
      throw StateError(current.error ?? 'The ECG recording could not start.');
    }
    final id = current.recordingId;
    if (id != null &&
        _capture != null &&
        !_capture!.ecgRecordingIds.contains(id)) {
      _capture!.ecgRecordingIds.add(id);
    }
    return id;
  }

  Future<void> _stopActivityEcg() async {
    if (!_ownsActivityEcg) return;
    _ownsActivityEcg = false;
    _activityEcgSubscription?.close();
    _activityEcgSubscription = null;
    final recorder = _activityEcg;
    _activityEcg = null;
    await recorder?.stop();
    _lastExternal = null;
    if (mounted) _publish(hrConnected: false);
  }

  Future<void> restartActivityEcg() async {
    final capture = _capture;
    if (capture == null ||
        capture.ecgDevice == null ||
        state.phase != IndoorPhase.recording) {
      return;
    }
    await _stopActivityEcg();
    await _startActivityEcg(capture.ecgDevice!);
    _checkpoint('recording');
  }

  void manualDistance(double? meters) {
    if (_capture?.isManual != true || state.phase != IndoorPhase.paused) {
      throw StateError(
        'Pause the activity before entering its final distance.',
      );
    }
    if (_capture!.gpsEnabled) {
      throw StateError('This activity uses its recorded GPS distance.');
    }
    if (meters != null &&
        (!meters.isFinite || meters < 0 || meters > 1000000)) {
      throw ArgumentError('Check the distance and units.');
    }
    if (meters == null) {
      _capture!.totals.remove('d');
    } else {
      _capture!.totals['d'] = meters;
    }
    _publish();
    _checkpoint('paused');
  }

  Future<bool> _startClock(int generation) async {
    final origin = await _background.monotonicMilliseconds();
    if (!mounted || generation != _generation) return false;
    _nativeStartedMs = origin;
    _clock
      ..reset()
      ..start();
    _lastTickAt = null;
    return true;
  }

  Future<int> _activeMilliseconds() async {
    final fallback = _baseMs + _clock.elapsedMilliseconds;
    final origin = _nativeStartedMs;
    if (origin == null) return fallback;
    final now = await _background.monotonicMilliseconds();
    return now == null || now < origin ? fallback : _baseMs + now - origin;
  }

  Future<void> _tick({bool force = false}) async {
    if (_tickBusy || !mounted) return;
    final now = DateTime.now().toUtc();
    final since = _lastTickAt == null
        ? null
        : now.difference(_lastTickAt!).inMilliseconds;
    if (!force && since != null && since >= 0 && since < 1000) return;
    _lastTickAt = now;
    _tickBusy = true;
    final generation = _generation;
    try {
      final capture = _capture;
      if (state.phase == IndoorPhase.recording && capture != null) {
        final elapsed = await _activeMilliseconds();
        if (!mounted ||
            generation != _generation ||
            state.phase != IndoorPhase.recording) {
          return;
        }
        capture.snapshot(DateTime.now().toUtc(), elapsed);
        if (capture.elapsedMs - _lastCheckpoint >= 5000) {
          _lastCheckpoint = capture.elapsedMs;
          _checkpoint('recording');
        }
        if (state.automaticPower &&
            state.authorized &&
            _lastPowerStep != capture.stepIndex) {
          unawaited(_applyPower());
        }
      }
      _publish(
        error: _writeError == null
            ? state.error
            : 'Could not save a recording checkpoint. Pause and try saving again.',
      );
    } finally {
      _tickBusy = false;
    }
  }

  void _checkpoint(String status) {
    final capture = _capture;
    if (capture == null) return;
    _writes = _writes
        .then(
          (_) => ref.read(indoorStorageProvider).checkpoint(capture, status),
        )
        .catchError((Object e) {
          _writeError = e;
        });
  }

  Future<void> _disconnected() async {
    if (_reconnecting || !state.connected) return;
    _capture?.disconnects++;
    _capture?.clearContinuity();
    _machine?.manualOverride();
    _publish(
      connected: false,
      error: 'Connection lost. Reconnecting; recording time continues.',
      automaticPower: false,
    );
    if (!state.active || state.phase == IndoorPhase.saving) return;
    _checkpoint(state.phase.name);
    _reconnecting = true;
    final generation = _generation;
    for (var attempt = 0; attempt < 3; attempt++) {
      await Future<void>.delayed(Duration(seconds: 2 << attempt));
      if (generation != _generation ||
          !state.active ||
          state.phase == IndoorPhase.saving) {
        break;
      }
      try {
        await _machine!.connect(state.device!, preferred: _capture?.machine);
        if (generation != _generation) break;
        _reconnecting = false;
        _capture?.clearContinuity();
        _publish(connected: true, automaticPower: false);
        return;
      } catch (_) {
        /* Keep the local session; another attempt may succeed. */
      }
    }
    _reconnecting = false;
    if (generation == _generation && state.active) {
      _publish(
        connected: false,
        error: 'Reconnect the machine or finish and save the available data.',
      );
    }
  }

  Future<void> pause() {
    if (_pausing != null) return _pausing!;
    late final Future<void> pending;
    pending = _pause().whenComplete(() {
      if (identical(_pausing, pending)) _pausing = null;
    });
    _pausing = pending;
    return pending;
  }

  Future<void> _pause() async {
    if (state.phase != IndoorPhase.recording) return;
    _clock.stop();
    _baseMs = await _activeMilliseconds();
    _nativeStartedMs = null;
    _clock.reset();
    _capture!.snapshot(DateTime.now().toUtc(), _baseMs);
    _capture!.event('pause', DateTime.now().toUtc());
    _capture!.clearContinuity();
    manualOverride();
    _publish(phase: IndoorPhase.paused);
    await _background.stop('activity');
    await _stopActivityEcg();
    if (_capture!.isManual) {
      await _hrPackets?.cancel();
      _hrPackets = null;
      await _heartRate?.dispose();
      _heartRate = null;
      _lastExternal = null;
      _publish(hrConnected: false);
    }
    _checkpoint('paused');
    await _writes;
  }

  Future<void> resume() async {
    if (state.phase != IndoorPhase.paused || !_foreground) return;
    var generation = _generation;
    final capture = _capture!;
    await _background.prepare(
      gps: _capture!.gpsEnabled,
      bluetooth: !_capture!.isManual || _capture!.heartRateDevice != null,
    );
    if (generation != _generation || !_foreground) return;
    await _background.start(
      'activity',
      gps: _capture!.gpsEnabled,
      bluetooth: !_capture!.isManual || _capture!.heartRateDevice != null,
      name: _capture!.name,
    );
    if (generation != _generation || _capture != capture) return;
    try {
      if (_capture!.isManual) {
        final ecg = _capture!.ecgDevice;
        if (ecg != null) {
          await _startActivityEcg(ecg);
        } else if (_capture!.heartRateDevice != null) {
          await connectHeartRate(_capture!.heartRateDevice!);
        }
      } else if (!state.connected) {
        await connect(_capture!.device, preferred: _capture!.machine);
        if (_capture != capture) return;
        if (!state.connected) {
          await _background.stop('activity');
          return;
        }
        generation = _generation;
      }
      // A machine recording with an H10 restarts its ECG like a manual one.
      if (!_capture!.isManual && _capture!.ecgDevice != null) {
        await _startActivityEcg(_capture!.ecgDevice!);
      }
      if (generation != _generation) return;
      _capture!.clearContinuity();
      _capture!.event('resume', DateTime.now().toUtc());
      if (!await _startClock(generation)) return;
      _publish(phase: IndoorPhase.recording, automaticPower: false);
      _checkpoint('recording');
    } catch (_) {
      await _background.stop('activity');
      await _stopActivityEcg();
      rethrow;
    }
  }

  Future<void> restore(String id) async {
    if (state.active || ref.read(deviceRecordingOwnerProvider) != null) {
      throw StateError('Finish the active recording first.');
    }
    final capture = await ref.read(indoorStorageProvider).load(id);
    if (capture == null) return;
    await _closeDevices();
    _capture = capture;
    _baseMs = capture.elapsedMs;
    _clock.reset();
    _writeError = null;
    _lastCheckpoint = capture.elapsedMs;
    ref.read(deviceRecordingOwnerProvider.notifier).state = 'indoor';
    _publish(
      phase: IndoorPhase.paused,
      connected: false,
      device: capture.device,
      heartRate: capture.heartRateDevice,
      hrConnected: false,
      automaticPower: false,
    );
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> connectHeartRate(TrainingDevice device) async {
    final generation = _generation;
    final owner = ref.read(deviceRecordingOwnerProvider);
    if (ref.read(hrvCaptureActiveProvider) ||
        (owner != null && owner != 'indoor')) {
      throw StateError('Finish the other device measurement first.');
    }
    await _hrPackets?.cancel();
    await _heartRate?.dispose();
    final sensor = ref.read(indoorHeartRateFactoryProvider)();
    _heartRate = sensor;
    _hrPackets = sensor.packets.listen(
      (packet) {
        if (!mounted || generation != _generation || _heartRate != sensor) {
          return;
        }
        _lastExternal = (
          bpm: packet.bpm,
          at: DateTime.now().toUtc(),
          contact: packet.contact,
        );
        _capture?.externalHeartRate(
          packet.bpm,
          DateTime.now().toUtc(),
          contact: packet.contact,
        );
        _publish(hrConnected: true);
        unawaited(_tick());
      },
      onError: (Object error) {
        _lastExternal = null;
        _capture?.clearExternalHeartRate();
        _publish(hrConnected: false, error: error.toString());
      },
    );
    try {
      await sensor.connect(device);
      if (generation != _generation) {
        await sensor.dispose();
        return;
      }
      final preferred = await const FlutterSecureStorage().read(
        key: 'ftms_prefer_external_hr',
      );
      if (generation != _generation) {
        await sensor.dispose();
        return;
      }
      final useExternal = _capture?.isManual == true || preferred != 'false';
      _capture?.heartRateDevice = device;
      _capture?.preferExternalHeartRate = useExternal;
      _publish(
        heartRate: device,
        hrConnected: true,
        preferExternal: useExternal,
      );
      await const FlutterSecureStorage().write(
        key: 'ftms_heart_rate_v1',
        value: jsonEncode(device.toJson()),
      );
      ref.invalidate(indoorHeartRatePairedProvider);
    } catch (_) {
      await sensor.dispose();
      if (_heartRate == sensor) _heartRate = null;
      rethrow;
    }
  }

  void preferExternal(bool value) {
    _capture?.preferExternalHeartRate = value;
    _publish(preferExternal: value);
    unawaited(
      const FlutterSecureStorage()
          .write(key: 'ftms_prefer_external_hr', value: '$value')
          .catchError((Object _) {}),
    );
  }

  void nextStep() {
    _capture?.nextStep(DateTime.now().toUtc());
    _publish();
    _checkpoint(state.phase.name);
  }

  Future<void> authorize() async {
    if (state.phase != IndoorPhase.recording || !state.connected) {
      throw StateError('Start recording with a connected machine first.');
    }
    await _machine!.authorize();
    _publish();
  }

  void manualOverride() {
    _machine?.manualOverride();
    _lastPowerStep = null;
    _publish(automaticPower: false);
  }

  Future<void> target(
    FtmsTarget target,
    double value, {
    bool treadmillConfirmed = false,
  }) async {
    if (state.phase != IndoorPhase.recording || !state.connected) {
      throw StateError('The machine is not ready for control.');
    }
    if (state.machine == FtmsMachine.treadmill &&
        (target == FtmsTarget.speed || target == FtmsTarget.incline)) {
      final current = target == FtmsTarget.speed
          ? state.live['spd']?.toDouble()
          : state.live['incline']?.toDouble();
      final reference = target == FtmsTarget.speed && current != null
          ? current * 3.6
          : current;
      if (!treadmillConfirmed ||
          reference == null ||
          (value - reference).abs() >
              (target == FtmsTarget.speed ? .5 : 1) + .0001) {
        throw StateError(
          'Use the machine controls for larger changes. Fjelia needs a fresh reading and confirmation for changes up to 0.5 km/h or 1% incline.',
        );
      }
    }
    await _machine!.setTarget(target, value);
    _publish();
  }

  Future<void> automaticPower(bool value) async {
    if (value &&
        (!state.authorized ||
            state.machine != FtmsMachine.bike ||
            !state.ranges.containsKey(FtmsTarget.power))) {
      throw StateError('Authorize a bike with target-power support first.');
    }
    _lastPowerStep = null;
    _publish(automaticPower: value);
    if (value) await _applyPower();
  }

  Future<void> _applyPower() async {
    if (_autoBusy || !state.automaticPower || !state.authorized) return;
    final capture = _capture, step = _capture?.currentStep;
    if (capture == null ||
        step == null ||
        !(step.target?.contains('power') ?? false) ||
        step.low == null) {
      return;
    }
    _autoBusy = true;
    try {
      final range = state.ranges[FtmsTarget.power]!;
      final desired = (step.low! + (step.high ?? step.low!)) / 2;
      final value =
          range.min +
          ((desired - range.min) / range.increment).round() * range.increment;
      if (!range.accepts(value)) {
        throw StateError(
          'This interval exceeds the machine’s supported power range.',
        );
      }
      await target(FtmsTarget.power, value);
      _lastPowerStep = capture.stepIndex;
    } catch (e) {
      manualOverride();
      _publish(error: e.toString(), automaticPower: false);
    } finally {
      _autoBusy = false;
    }
  }

  Future<String?> finish() {
    if (_finishing != null) return _finishing!;
    late final Future<String?> pending;
    pending = _finish().whenComplete(() {
      if (identical(_finishing, pending)) _finishing = null;
    });
    _finishing = pending;
    return pending;
  }

  Future<String?> _finish() async {
    if (state.phase == IndoorPhase.saving || _capture == null) return null;
    if (state.phase == IndoorPhase.saved) return _capture!.id;
    await pause();
    ++_generation;
    manualOverride();
    _publish(phase: IndoorPhase.saving);
    try {
      await _writes;
      await ref.read(hrZonesProvider.notifier).loaded;
      final zones = ref.read(hrZonesProvider);
      final id = await ref
          .read(indoorStorageProvider)
          .save(
            _capture!,
            zones:
                (_capture!.machine == FtmsMachine.bike
                        ? zones.cycling
                        : zones.running)
                    .bounds,
          );
      _publish(phase: IndoorPhase.saved, connected: false);
      ref.read(deviceRecordingOwnerProvider.notifier).state = null;
      ref.read(syncStatusListenerProvider.notifier).state++;
      ref.read(hrvActivitiesChangedProvider.notifier).state++;
      final start = _capture!.startedAt.toLocal();
      unawaited(
        ref
            .read(syncServiceProvider)
            .recalculateEnergie(DateTime(start.year, start.month, start.day))
            .catchError((Object _) {}),
      );
      await _closeDevices();
      return id;
    } catch (e) {
      _publish(phase: IndoorPhase.paused, error: e.toString());
      return null;
    }
  }

  Future<void> discard() async {
    if (state.phase == IndoorPhase.saving) return;
    await pause();
    ++_generation;
    if (_capture != null) {
      await _writes;
      await ref.read(indoorStorageProvider).discard(_capture!.id);
    }
    await _closeDevices();
    _capture = null;
    _baseMs = 0;
    if (ref.read(deviceRecordingOwnerProvider) == 'indoor') {
      ref.read(deviceRecordingOwnerProvider.notifier).state = null;
    }
    state = const IndoorRecorderState();
  }

  Future<void> _closeDevices({bool stopEcg = true}) async {
    await _background.stop('activity');
    if (stopEcg) await _stopActivityEcg();
    _activityEcgSubscription?.close();
    _activityEcgSubscription = null;
    _ticker?.cancel();
    _ticker = null;
    _clock.stop();
    _nativeStartedMs = null;
    await _measurements?.cancel();
    await _status?.cancel();
    await _hrPackets?.cancel();
    _measurements = null;
    _status = null;
    _hrPackets = null;
    await _machine?.dispose();
    await _heartRate?.dispose();
    _machine = null;
    _heartRate = null;
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _clock.stop();
    unawaited(_locations?.cancel());
    unawaited(_backgroundActions?.cancel());
    unawaited(_backgroundErrors?.cancel());
    unawaited(_closeDevices(stopEcg: false));
    super.dispose();
  }
}
