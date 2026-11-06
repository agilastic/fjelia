import 'dart:math' as math;

import 'activity_location.dart';

import 'training_device.dart';
import 'ftms.dart';

class IndoorStep {
  const IndoorStep({
    required this.label,
    this.seconds,
    this.meters,
    this.target,
    this.low,
    this.high,
    this.zone,
  });
  final String label;
  final double? seconds, meters, low, high;
  final String? target;
  final int? zone;
  Map<String, Object?> toJson() => {
    'label': label,
    'seconds': seconds,
    'meters': meters,
    'target': target,
    'low': low,
    'high': high,
    'zone': zone,
  };
  factory IndoorStep.fromJson(Map<String, dynamic> j) => IndoorStep(
    label: j['label'] as String,
    seconds: (j['seconds'] as num?)?.toDouble(),
    meters: (j['meters'] as num?)?.toDouble(),
    target: j['target'] as String?,
    low: (j['low'] as num?)?.toDouble(),
    high: (j['high'] as num?)?.toDouble(),
    zone: (j['zone'] as num?)?.toInt(),
  );
}

List<IndoorStep> indoorSteps(List<Map<String, dynamic>> steps) {
  final out = <IndoorStep>[];
  double? positive(Object? n) =>
      n is num && n.isFinite && n > 0 ? n.toDouble() : null;
  void read(List items, int depth) {
    if (depth > 8) return;
    for (final item in items) {
      if (item is! Map || out.length >= 200) continue;
      if (item['workoutSteps'] is List) {
        final times =
            positive(item['numberOfIterations'] ?? item['endConditionValue'])
                ?.round()
                .clamp(1, 100) ??
            1;
        for (var i = 0; i < times && out.length < 200; i++) {
          read(item['workoutSteps'] as List, depth + 1);
        }
        continue;
      }
      final type = item['stepType'];
      final label = type is Map
          ? type['stepTypeKey']?.toString()
          : type?.toString();
      final condition = item['endCondition'];
      final end = condition is Map ? condition['conditionTypeKey'] : condition;
      final target = item['targetType'];
      final key = target is Map
          ? target['workoutTargetTypeKey']?.toString()
          : target?.toString();
      out.add(
        IndoorStep(
          label: label ?? 'interval',
          seconds: end == 'time' ? positive(item['endConditionValue']) : null,
          meters: end == 'distance'
              ? positive(item['endConditionValue'])
              : null,
          target: key,
          low: positive(item['targetValueOne']),
          high: positive(item['targetValueTwo']),
          zone: (item['zoneNumber'] as num?)?.toInt(),
        ),
      );
    }
  }

  read(steps, 0);
  return out;
}

/// Samples use the phone's timestamp axis, including background delivery.
/// Device counters use a baseline, so connecting halfway through the machine's
/// own workout does not import its earlier distance/calories into this one.
class IndoorCapture {
  IndoorCapture({
    required this.id,
    required this.startedAt,
    required this.device,
    required this.machine,
    required this.name,
    this.sessionId,
    this.plannedStepsJson,
    this.plannedDurationSeconds,
    this.steps = const [],
    this.dataProtocol = 'ftms',
    this.activityTypeOverride,
    this.gpsEnabled = false,
    this.includeBloodPressure = false,
  });
  final String id, name;
  final String dataProtocol;
  final String? activityTypeOverride;
  final bool gpsEnabled, includeBloodPressure;
  final route = <Map<String, num>>[];
  ActivityLocation? _gpsAnchor, _lastGps;
  int? _gpsSampleTime;
  int _gpsSegment = 0;
  String get activityType => activityTypeOverride ?? machine.activityType;
  bool get isManual => dataProtocol == 'manual';
  TrainingDevice? ecgDevice;
  final ecgRecordingIds = <String>[];
  final DateTime startedAt;
  final TrainingDevice device;
  final FtmsMachine machine;
  final String? sessionId, plannedStepsJson;
  final int? plannedDurationSeconds;
  final List<IndoorStep> steps;
  TrainingDevice? heartRateDevice;
  bool preferExternalHeartRate = false;
  final samples = <Map<String, num>>[];
  final events = <Map<String, Object?>>[];
  final _latest = <String, ({num value, DateTime at})>{};
  final _counters = <String, num>{};
  final totals = <String, double>{};
  int elapsedMs = 0, movingMs = 0, stepIndex = 0, stepStartedMs = 0;
  double stepStartedMeters = 0;
  int _lastSnapshotMs = 0;
  DateTime? _speedAt;
  double? _speed;
  bool _deviceDistance = false;
  int disconnects = 0;

  double get distanceMeters => totals['d'] ?? 0;
  IndoorStep? get currentStep =>
      stepIndex < steps.length ? steps[stepIndex] : null;
  double? get remainingSeconds => currentStep?.seconds == null
      ? null
      : math.max(0, currentStep!.seconds! - (elapsedMs - stepStartedMs) / 1000);
  double? get remainingMeters => currentStep?.meters == null
      ? null
      : math.max(
          0,
          currentStep!.meters! - (distanceMeters - stepStartedMeters),
        );

  void clearContinuity() {
    _counters.clear();
    _latest.clear();
    _speedAt = null;
    _speed = null;
    _gpsAnchor = null;
    _lastGps = null;
    _gpsSegment++;
  }

  /// Reject stale/imprecise/teleport fixes. A pause or long GPS gap starts a
  /// new segment; its missing distance is never joined with a straight line.
  bool ingestLocation(
    ActivityLocation fix,
    DateTime receivedAt, {
    required bool recording,
  }) {
    if (!gpsEnabled || !recording) return false;
    final age = receivedAt.difference(fix.at).inMilliseconds;
    if (fix.at.isBefore(startedAt) ||
        age < -2000 ||
        age > 10000 ||
        fix.accuracy > 30 ||
        fix.accuracy < 0 ||
        !fix.latitude.isFinite ||
        !fix.longitude.isFinite ||
        fix.latitude.abs() > 90 ||
        fix.longitude.abs() > 180 ||
        !fix.accuracy.isFinite ||
        (_lastGps != null && !fix.at.isAfter(_lastGps!.at))) {
      return false;
    }
    final previous = _lastGps;
    final limit = activityType == 'cycling' ? 45.0 : 17.0;
    if (previous != null) {
      final seconds = fix.at.difference(previous.at).inMilliseconds / 1000;
      if (seconds <= 15 && previous.distanceTo(fix) / seconds > limit) {
        return false;
      }
      if (seconds > 15) {
        _gpsAnchor = null;
        _gpsSegment++;
      }
    }
    final anchor = _gpsAnchor;
    totals.putIfAbsent('d', () => 0);
    if (anchor != null) {
      final delta = anchor.distanceTo(fix);
      // Keep an anchor until movement exceeds the uncertainty, reducing
      // stationary GPS drift without summing every wobble as distance.
      final threshold = math.max(
        3.0,
        math.min(anchor.accuracy, fix.accuracy) * .5,
      );
      if (fix.speed != null && fix.speed! < .5) {
        _gpsAnchor = fix;
      } else if (delta >= threshold) {
        totals['d'] = distanceMeters + delta;
        _gpsAnchor = fix;
      }
    } else {
      _gpsAnchor = fix;
    }
    _lastGps = fix;
    route.add({
      't': fix.at.millisecondsSinceEpoch,
      'lat': fix.latitude,
      'lng': fix.longitude,
      'accuracy': fix.accuracy,
      'segment': _gpsSegment,
      if (fix.altitude != null) 'ele': fix.altitude!,
    });
    _latest['gps_accuracy'] = (value: fix.accuracy, at: fix.at);
    if (fix.speed != null && fix.speed! <= limit) {
      _latest['spd'] = (value: fix.speed!, at: fix.at);
    }
    if (fix.altitude != null) {
      _latest['ele'] = (value: fix.altitude!, at: fix.at);
    }
    return true;
  }

  void ingest(Map<String, num> values, DateTime at, {required bool recording}) {
    for (final v in values.entries) {
      if (v.value.isFinite) _latest[v.key] = (value: v.value, at: at);
    }
    if (!recording) {
      _counters.clear();
      _speedAt = null;
      return;
    }
    const counters = {
      'machine_distance': 'd',
      'machine_kcal': 'kcal',
      'machine_ascent': 'ascent',
      'machine_descent': 'descent',
      'machine_strokes': 'strokes',
      'machine_steps': 'steps',
      'machine_floors': 'floors',
      'machine_strides': 'strides',
    };
    final beforeDistance = distanceMeters;
    for (final e in counters.entries) {
      final value = values[e.key];
      if (value == null || value < 0) continue;
      final old = _counters[e.key];
      _counters[e.key] = value;
      totals.putIfAbsent(e.value, () => 0);
      if (e.key == 'machine_distance') _deviceDistance = true;
      // A reset begins a fresh baseline; it does not fabricate a jump.
      if (old != null && value >= old) {
        totals[e.value] = (totals[e.value] ?? 0) + value - old;
      }
    }
    final speed = values['spd']?.toDouble();
    if (speed != null && speed >= 0) {
      if (!_deviceDistance && _speedAt != null && _speed != null) {
        final seconds = at.difference(_speedAt!).inMilliseconds / 1000;
        if (seconds >= 0 && seconds <= 5) {
          totals['d'] = distanceMeters + (_speed! + speed) / 2 * seconds;
        }
      }
      _speedAt = at;
      _speed = speed;
    }
    // Only estimate climb when the machine supplies distance and incline,
    // and does not supply its own cumulative ascent.
    if (!_counters.containsKey('machine_ascent') && values['incline'] != null) {
      final delta = distanceMeters - beforeDistance,
          grade = values['incline']!.toDouble() / 100;
      if (delta > 0 && grade > 0) {
        totals['ascent'] =
            (totals['ascent'] ?? 0) + delta * math.sin(math.atan(grade));
      }
    }
  }

  void externalHeartRate(int bpm, DateTime at, {bool? contact}) {
    if (bpm <= 0 || bpm >= 255 || contact == false) {
      _latest.remove('external_hr');
      return;
    }
    _latest['external_hr'] = (value: bpm, at: at);
  }

  void clearExternalHeartRate() {
    _latest.remove('external_hr');
  }

  Map<String, num> live(DateTime at) {
    final values = <String, num>{};
    for (final e in _latest.entries) {
      final age = at.difference(e.value.at).inMilliseconds;
      if (age >= 0 && age <= 5000 && e.key != 'external_hr') {
        values[e.key] = e.value.value;
      }
    }
    if (preferExternalHeartRate) {
      values.remove('hr');
      final hr = _latest['external_hr'];
      if (hr != null &&
          at.difference(hr.at).inMilliseconds >= 0 &&
          at.difference(hr.at).inMilliseconds <= 5000) {
        values['hr'] = hr.value;
        values['hr_source'] = 1;
      }
    } else if (values['hr'] != null) {
      values['hr_source'] = 0;
    }
    return values;
  }

  void snapshot(DateTime at, int activeMs) {
    elapsedMs = activeMs;
    final values = live(at);
    if ((values['spd'] ?? 0) > .1 ||
        (values['cad'] ?? 0) > 0 ||
        (values['w'] ?? 0) > 0) {
      movingMs += (activeMs - _lastSnapshotMs).clamp(0, 2000);
    }
    _lastSnapshotMs = activeMs;
    while (currentStep != null &&
        (remainingSeconds == 0 || remainingMeters == 0)) {
      nextStep(at, automatic: true);
    }
    final gps = _lastGps;
    final hasNewFix =
        gps != null && gps.at.millisecondsSinceEpoch != _gpsSampleTime;
    if (hasNewFix) _gpsSampleTime = gps.at.millisecondsSinceEpoch;
    samples.add({
      't': at.toUtc().millisecondsSinceEpoch,
      'timer': activeMs / 1000,
      ...values,
      ...totals,
      'step': stepIndex,
      if (hasNewFix) ...{
        'lat': gps.latitude,
        'lng': gps.longitude,
        'gps_t': gps.at.millisecondsSinceEpoch,
        'gps_accuracy': gps.accuracy,
        'gps_segment': _gpsSegment,
      },
    });
  }

  void nextStep(DateTime at, {bool automatic = false}) {
    final step = currentStep;
    if (step == null) return;
    final boundary = automatic && step.seconds != null
        ? stepStartedMs + (step.seconds! * 1000).round()
        : elapsedMs;
    final distance = automatic && step.meters != null
        ? stepStartedMeters + step.meters!
        : distanceMeters;
    final ended = at.subtract(Duration(milliseconds: elapsedMs - boundary));
    events.add({
      'type': 'interval',
      'index': stepIndex,
      'ended_at': ended.toUtc().toIso8601String(),
      'timer_seconds': boundary / 1000,
      'distance_m': distance,
    });
    stepIndex++;
    stepStartedMs = boundary;
    stepStartedMeters = distance;
  }

  void event(String type, DateTime at) => events.add({
    'type': type,
    'at': at.toUtc().toIso8601String(),
    'timer_seconds': elapsedMs / 1000,
  });
  double? average(String key) {
    final values = [
      for (final s in samples)
        if (s[key] != null && s[key]! >= 0) s[key]!.toDouble(),
    ];
    return values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;
  }

  double? maximum(String key) {
    final values = [
      for (final s in samples)
        if (s[key] != null) s[key]!.toDouble(),
    ];
    return values.isEmpty ? null : values.reduce(math.max);
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'data_protocol': dataProtocol,
    'activity_type': activityType,
    'gps_enabled': gpsEnabled,
    'include_blood_pressure': includeBloodPressure,
    'route': route,
    'ecg_device': ecgDevice?.toJson(),
    'ecg_recording_ids': ecgRecordingIds,
    'id': id,
    'name': name,
    'started_at': startedAt.toUtc().toIso8601String(),
    'device': device.toJson(),
    'ftms_compatibility': ftmsCompatibilityForName(device.name).name,
    'machine': machine.name,
    'session_id': sessionId,
    'planned_steps_json': plannedStepsJson,
    'planned_duration_seconds': plannedDurationSeconds,
    'steps': steps.map((s) => s.toJson()).toList(),
    'samples': samples,
    'events': events,
    'elapsed_ms': elapsedMs,
    'moving_ms': movingMs,
    'totals': totals,
    'step_index': stepIndex,
    'step_started_ms': stepStartedMs,
    'step_started_m': stepStartedMeters,
    'hr_device': heartRateDevice?.toJson(),
    'prefer_external_hr': preferExternalHeartRate,
    'disconnects': disconnects,
    'distance_basis': gpsEnabled
        ? 'gps'
        : isManual
        ? 'manual'
        : _deviceDistance
        ? 'machine'
        : 'integrated_speed',
  };

  factory IndoorCapture.fromJson(Map<String, dynamic> j) {
    final capture = IndoorCapture(
      id: j['id'] as String,
      name: j['name'] as String,
      startedAt: DateTime.parse(j['started_at'] as String),
      device: TrainingDevice.fromJson(j['device'] as Map<String, dynamic>),
      machine: FtmsMachine.values.byName(j['machine'] as String),
      dataProtocol: j['data_protocol'] as String? ?? 'ftms',
      activityTypeOverride: j['activity_type'] as String?,
      gpsEnabled: j['gps_enabled'] == true,
      includeBloodPressure: j['include_blood_pressure'] == true,
      sessionId: j['session_id'] as String?,
      plannedStepsJson: j['planned_steps_json'] as String?,
      plannedDurationSeconds: (j['planned_duration_seconds'] as num?)?.toInt(),
      steps: [
        for (final s in j['steps'] as List? ?? [])
          IndoorStep.fromJson(s as Map<String, dynamic>),
      ],
    );
    capture.route.addAll([
      for (final p in j['route'] as List? ?? []) (p as Map).cast<String, num>(),
    ]);
    capture._gpsSegment = capture.route.isEmpty
        ? 0
        : (capture.route.last['segment']?.toInt() ?? 0) + 1;
    if (j['ecg_device'] is Map<String, dynamic>) {
      capture.ecgDevice = TrainingDevice.fromJson(
        j['ecg_device'] as Map<String, dynamic>,
      );
    }
    capture.ecgRecordingIds.addAll(
      (j['ecg_recording_ids'] as List? ?? []).cast<String>(),
    );
    capture.samples.addAll([
      for (final s in j['samples'] as List) (s as Map).cast<String, num>(),
    ]);
    capture.events.addAll([
      for (final s in j['events'] as List) (s as Map).cast<String, Object?>(),
    ]);
    capture.elapsedMs = (j['elapsed_ms'] as num).toInt();
    capture.movingMs = (j['moving_ms'] as num).toInt();
    capture._lastSnapshotMs = capture.elapsedMs;
    capture.totals.addAll({
      for (final e in (j['totals'] as Map).entries)
        e.key as String: (e.value as num).toDouble(),
    });
    capture.stepIndex = (j['step_index'] as num).toInt();
    capture.stepStartedMs = (j['step_started_ms'] as num).toInt();
    capture.stepStartedMeters = (j['step_started_m'] as num).toDouble();
    capture.preferExternalHeartRate = j['prefer_external_hr'] == true;
    if (j['hr_device'] is Map<String, dynamic>) {
      capture.heartRateDevice = TrainingDevice.fromJson(
        j['hr_device'] as Map<String, dynamic>,
      );
    }
    capture.disconnects = (j['disconnects'] as num?)?.toInt() ?? 0;
    capture._deviceDistance = j['distance_basis'] == 'machine';
    return capture;
  }
}
