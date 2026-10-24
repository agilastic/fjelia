import 'dart:convert';

double? _toDouble(Object? v) => (v as num?)?.toDouble();
int? _toInt(Object? v) => (v as num?)?.toInt();

class LatLng {
  const LatLng(this.lat, this.lng);

  final double lat;
  final double lng;
}

/// One recorded sample of an activity (one Garmin detail row, or one split
/// for activities without details). Stored in `metrics_json` as
/// `{d, hr, spd, ele, w}`.
class ActivitySample {
  const ActivitySample({
    required this.distanceMeters,
    this.heartRate,
    this.speed,
    this.elevation,
    this.cadence,
    this.power,
    this.timestamp,
  });

  /// Cumulative distance from the start.
  final DateTime? timestamp;
  final double distanceMeters;
  final double? heartRate;

  /// Metres per second.
  final double? speed;
  final double? elevation;
  final double? cadence;
  final double? power;
}

class GarminActivity {
  const GarminActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.startTime,
    required this.duration,
    this.distanceMeters,
    this.avgHeartRate,
    this.maxHeartRate,
    this.trainingLoad,
    this.avgPower,
    this.elevationGain,
    this.route = const [],
    this.samples = const [],
    this.hrZoneSeconds = const {},
    this.source,
    this.plannedWorkoutName,
    this.plannedDuration,
    this.plannedDistanceMeters,
    this.plannedSteps = const [],
    this.aerobicTrainingEffect,
    this.anaerobicTrainingEffect,
    this.recoveryTimeSeconds,
    this.activityFeedbackPhrase,
    this.avgRunCadence,
    this.vo2max,
    this.movingDuration,
  });

  factory GarminActivity.fromGarminJson(Map<String, dynamic> json) {
    final splits = (json['splitSummaries'] as List?) ?? const [];
    final samples = <ActivitySample>[];
    var cumulative = 0.0;
    for (final split in splits.cast<Map<String, dynamic>>()) {
      cumulative += _toDouble(split['distance']) ?? 0.0;
      samples.add(
        ActivitySample(
          distanceMeters: cumulative,
          heartRate: _toDouble(split['averageHR']),
          speed: _toDouble(split['averageSpeed']),
          elevation: _toDouble(split['elevationGain']),
        ),
      );
    }

    // Garmin reports recovery time in hours.
    final recoveryHours = _toDouble(json['recoveryTime']);
    final moving = json['movingDuration'] as num?;

    return GarminActivity(
      id: json['activityId'].toString(),
      name: json['activityName'] as String? ?? 'Activity',
      type: (json['activityType'] as Map?)?['typeKey'] as String? ?? 'unknown',
      startTime: DateTime.parse(json['startTimeLocal'] as String),
      duration: Duration(seconds: (_toDouble(json['duration']) ?? 0).round()),
      distanceMeters: _toDouble(json['distance']),
      avgHeartRate: _toDouble(json['averageHR']),
      maxHeartRate: _toDouble(json['maxHR']),
      trainingLoad:
          _toDouble(json['activityTrainingLoad']) ??
          _toDouble(json['trainingEffect']),
      avgPower: _toDouble(json['averagePower']),
      elevationGain: _toDouble(json['elevationGain']),
      samples: samples,
      source: 'garmin',
      aerobicTrainingEffect: _toDouble(json['aerobicTrainingEffect']),
      anaerobicTrainingEffect: _toDouble(json['anaerobicTrainingEffect']),
      recoveryTimeSeconds: recoveryHours == null
          ? null
          : (recoveryHours * 3600).round(),
      activityFeedbackPhrase: json['activityFeedbackPhrase'] as String?,
      avgRunCadence: _toDouble(json['avgRunCadence']),
      vo2max: _toDouble(json['vO2MaxValue']),
      movingDuration: moving == null ? null : Duration(seconds: moving.round()),
    );
  }

  final String id;
  final String name;
  final String type;
  final DateTime startTime;
  final Duration duration;
  final double? distanceMeters;
  final double? avgHeartRate;
  final double? maxHeartRate;
  final double? trainingLoad;
  final double? avgPower;
  final double? elevationGain;
  final List<LatLng> route;
  final List<ActivitySample> samples;

  /// Seconds spent per HR zone, keyed `zone1`…`zone5`.
  final Map<String, double> hrZoneSeconds;
  final String? source;
  final String? plannedWorkoutName;
  final Duration? plannedDuration;
  final double? plannedDistanceMeters;
  final List<WorkoutStep> plannedSteps;
  final double? aerobicTrainingEffect;
  final double? anaerobicTrainingEffect;
  final int? recoveryTimeSeconds;
  final String? activityFeedbackPhrase;
  final double? avgRunCadence;
  final double? vo2max;
  final Duration? movingDuration;
}

/// A workout scheduled in the Garmin Connect calendar.
class ScheduledWorkout {
  const ScheduledWorkout({
    required this.workoutId,
    required this.scheduleId,
    this.trainingPlanId,
    required this.name,
    required this.sportType,
    required this.scheduledDate,
    this.estimatedDuration,
    this.estimatedDistanceMeters,
    this.description,
    this.itemType,
    this.seriesName,
    this.steps = const [],
    this.userNote,
  });

  factory ScheduledWorkout.fromCalendarItem(Map<String, dynamic> item) {
    final date = item['date'] as String? ?? '';
    final duration = item['duration'] as num?;
    return ScheduledWorkout(
      scheduleId: item['id']?.toString() ?? '',
      workoutId: (item['workoutId'] ?? item['id'])?.toString() ?? '',
      trainingPlanId: item['trainingPlanId']?.toString(),
      name: item['title'] as String? ?? 'Workout',
      sportType: item['sportTypeKey'] as String? ?? 'other',
      scheduledDate: DateTime.tryParse(date) ?? DateTime.now(),
      estimatedDuration: duration == null
          ? null
          : Duration(seconds: duration.round()),
      estimatedDistanceMeters: _toDouble(item['distance']),
      itemType: item['itemType'] as String?,
    );
  }

  final String workoutId;
  final String scheduleId;
  final String? trainingPlanId;
  final String name;
  final String sportType;
  final DateTime scheduledDate;
  final Duration? estimatedDuration;
  final double? estimatedDistanceMeters;
  final String? description;
  final String? itemType;
  final String? seriesName;
  final List<WorkoutStep> steps;
  final String? userNote;
}

/// A step of a structured Garmin workout (repeat groups nest [steps]).
class WorkoutStep {
  const WorkoutStep({
    required this.order,
    required this.type,
    this.stepName,
    this.intensity,
    this.description,
    this.durationUnit,
    this.durationValue,
    this.targetType,
    this.targetZone,
    this.targetFrom,
    this.targetTo,
    this.repeatCount,
    this.steps = const [],
  });

  factory WorkoutStep.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'ExecutableStepDTO';
    final nested =
        (json['workoutSteps'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(WorkoutStep.fromJson)
            .toList() ??
        <WorkoutStep>[];

    final endCondition = json['endCondition'];
    final durationUnit = endCondition is Map
        ? endCondition['conditionTypeKey'] as String?
        : json['durationUnit'] as String?;
    final durationValue =
        _toDouble(json['endConditionValue']) ??
        _toDouble(json['durationValue']);

    final target = json['targetType'];
    final rawTarget = target is Map
        ? target['workoutTargetTypeKey'] as String?
        : target as String?;
    final targetType = switch (rawTarget) {
      'heart.rate' || 'heart.rate.zone' => 'heartRate',
      'pace.zone' => 'pace',
      'cadence.zone' => 'cadence',
      'speed.zone' => 'speed',
      'no.target' => null,
      _ => rawTarget,
    };

    final stepType = json['stepType'];
    final intensity = json['intensity'];

    return WorkoutStep(
      order: _toInt(json['stepOrder'] ?? json['order']) ?? 0,
      type: type,
      stepName:
          json['stepName'] as String? ??
          (stepType is Map ? stepType['stepTypeKey'] as String? : null),
      intensity: intensity is Map
          ? intensity['intensityType'] as String?
          : json['intensity'] as String? ?? json['intensityType'] as String?,
      description: json['description'] as String?,
      durationUnit: durationUnit,
      durationValue: durationValue,
      targetType: targetType,
      targetZone: _toInt(json['zoneNumber'] ?? json['targetZone']),
      targetFrom: _toDouble(json['targetValueOne'] ?? json['targetFrom']),
      targetTo: _toDouble(json['targetValueTwo'] ?? json['targetTo']),
      repeatCount: _toInt(json['numberOfIterations'] ?? json['repeatCount']),
      steps: nested,
    );
  }

  final int order;
  final String type;
  final String? stepName;
  final String? intensity;
  final String? description;
  final String? durationUnit;
  final double? durationValue;
  final String? targetType;
  final int? targetZone;
  final double? targetFrom;
  final double? targetTo;
  final int? repeatCount;
  final List<WorkoutStep> steps;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['order'] = order;
    json['type'] = type;
    if (stepName != null) json['stepName'] = stepName;
    if (intensity != null) json['intensity'] = intensity;
    if (description != null) json['description'] = description;
    if (durationUnit != null) json['durationUnit'] = durationUnit;
    if (durationValue != null) json['durationValue'] = durationValue;
    if (targetType != null) json['targetType'] = targetType;
    if (targetZone != null) json['targetZone'] = targetZone;
    if (targetFrom != null) json['targetFrom'] = targetFrom;
    if (targetTo != null) json['targetTo'] = targetTo;
    if (repeatCount != null) json['repeatCount'] = repeatCount;
    if (steps.isNotEmpty) {
      json['workoutSteps'] = steps.map((s) => s.toJson()).toList();
    }
    return json;
  }
}

class BodyBatterySample {
  const BodyBatterySample(this.timestamp, this.value);

  final DateTime timestamp;
  final int value;
}

class BodyBatteryReport {
  const BodyBatteryReport({
    required this.date,
    required this.samples,
    this.charged,
    this.drained,
  });

  /// Parses `bodyBatteryValuesArray` entries `[timestampMs, status, level, …]`.
  factory BodyBatteryReport.fromGarminJson(Map<String, dynamic> json) {
    final samples = <BodyBatterySample>[];
    for (final entry in (json['bodyBatteryValuesArray'] as List?) ?? const []) {
      if (entry is! List || entry.length <= 2) continue;
      final ts = entry[0];
      final level = entry[2];
      if (ts is! int || level is! num) continue;
      if (level < 0 || level > 100) continue;
      samples.add(
        BodyBatterySample(
          DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true),
          level.toInt(),
        ),
      );
    }
    samples.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return BodyBatteryReport(
      date: DateTime.parse(json['date'] as String),
      samples: samples,
      charged: _toInt(json['charged']),
      drained: _toInt(json['drained']),
    );
  }

  final DateTime date;
  final List<BodyBatterySample> samples;
  final int? charged;
  final int? drained;

  /// Latest sample not in the future, falling back to the last one.
  BodyBatterySample? get _currentSample {
    if (samples.isEmpty) return null;
    final now = DateTime.now();
    for (final s in samples.reversed) {
      if (!s.timestamp.isAfter(now)) return s;
    }
    return samples.last;
  }

  int? get currentValue => _currentSample?.value;
  DateTime? get currentTimestamp => _currentSample?.timestamp;
}

class WellnessData {
  const WellnessData({
    required this.date,
    this.steps,
    this.activeCalories,
    this.totalCalories,
    this.averageStress,
    this.bodyBatteryHighest,
    this.bodyBatteryLowest,
    this.floorsAscended,
    this.intensityMinutes,
    this.restingHeartRate,
    this.respirationRate,
    this.fitnessAge,
  });

  factory WellnessData.fromGarminJson(Map<String, dynamic> json) {
    return WellnessData(
      date: DateTime.parse(json['calendarDate'] as String),
      steps: _toInt(json['totalSteps']),
      activeCalories: _toInt(json['activeKilocalories']),
      totalCalories: _toInt(json['totalKilocalories']),
      averageStress: _toDouble(json['averageStressLevel']),
      bodyBatteryHighest: _toDouble(json['bodyBatteryHighestValue']),
      bodyBatteryLowest: _toDouble(json['bodyBatteryLowestValue']),
      floorsAscended: _toInt(json['floorsAscended']),
      intensityMinutes: _toDouble(json['moderateIntensityMinutes']),
      restingHeartRate: _toInt(json['restingHeartRate']),
      respirationRate: _toDouble(json['avgWakingRespirationValue']),
      fitnessAge: _toDouble(json['fitnessAge']),
    );
  }

  final DateTime date;
  final int? steps;
  final int? activeCalories;
  final int? totalCalories;
  final double? averageStress;
  final double? bodyBatteryHighest;
  final double? bodyBatteryLowest;
  final int? floorsAscended;
  final double? intensityMinutes;
  final int? restingHeartRate;
  final double? respirationRate;
  final double? fitnessAge;
}

/// A contiguous block of one sleep stage: `deep`, `light`, `rem` or `awake`.
class SleepPhase {
  const SleepPhase(this.start, this.end, this.phase);

  final DateTime start;
  final DateTime end;
  final String phase;
}

class SleepData {
  const SleepData({
    required this.date,
    required this.totalSleep,
    required this.deepSleep,
    required this.remSleep,
    required this.lightSleep,
    required this.awakeSleep,
    this.sleepScore,
    this.sleepStart,
    this.sleepEnd,
    this.phases = const [],
    this.avgSpo2,
    this.avgRespiration,
    this.skinTempDelta,
    this.avgOvernightHrv,
    this.restingHeartRate,
    this.sleepNeedSeconds,
  });

  factory SleepData.fromGarminJson(Map<String, dynamic> json) {
    final dto = json['dailySleepDTO'] as Map<String, dynamic>? ?? json;
    final scores = dto['sleepScores'] as Map<String, dynamic>?;
    final overall = scores?['overall'] as Map<String, dynamic>?;
    final score = _toDouble(overall?['value']) ?? _toDouble(dto['sleepScore']);
    final startMs = dto['sleepStartTimestampGMT'] as int?;
    final endMs = dto['sleepEndTimestampGMT'] as int?;

    final spo2Dto =
        json['wellnessSpO2SleepSummaryDTO'] as Map<String, dynamic>?;
    final spo2 =
        _toDouble(spo2Dto?['averageSPO2']) ?? _toDouble(dto['averageSpo2']);

    double? average(String listKey, String valueKey) {
      final values = ((json[listKey] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map((e) => _toDouble(e[valueKey]))
          .whereType<double>()
          .where((v) => v > 0)
          .toList();
      if (values.isEmpty) return null;
      return values.reduce((a, b) => a + b) / values.length;
    }

    final respiration =
        average('wellnessEpochRespirationDataDTOList', 'respirationValue') ??
        average(
          'wellnessEpochRespirationAveragesList',
          'respirationAverageValue',
        );

    final levels =
        (json['sleepLevels'] as List?) ??
        (dto['sleepLevels'] as List?) ??
        const [];
    final phases = <SleepPhase>[];
    for (final level in levels.cast<Map<String, dynamic>>()) {
      final s = level['startGMT'] as String?;
      final e = level['endGMT'] as String?;
      if (s == null || e == null) continue;
      final phase = switch (_toInt(level['activityLevel'])) {
        0 => 'deep',
        1 => 'light',
        2 => 'rem',
        _ => 'awake',
      };
      final start = DateTime.tryParse('${s.replaceFirst(' ', 'T')}Z');
      final end = DateTime.tryParse('${e.replaceFirst(' ', 'T')}Z');
      if (start == null || end == null) continue;
      phases.add(SleepPhase(start.toLocal(), end.toLocal(), phase));
    }

    final need = dto['sleepNeed'] as Map<String, dynamic>?;
    int? sleepNeedSeconds;
    if (need != null && need['actual'] != null) {
      sleepNeedSeconds = (need['actual'] as num).toInt() * 60;
    } else {
      sleepNeedSeconds =
          _toInt(dto['currentSleepNeedInSeconds']) ??
          _toInt(dto['sleepNeedInSeconds']);
    }

    Duration secs(String key) => Duration(seconds: _toInt(dto[key]) ?? 0);

    return SleepData(
      date: DateTime.parse(dto['calendarDate'] as String),
      totalSleep: secs('sleepTimeSeconds'),
      deepSleep: secs('deepSleepSeconds'),
      remSleep: secs('remSleepSeconds'),
      lightSleep: secs('lightSleepSeconds'),
      awakeSleep: secs('awakeSleepSeconds'),
      sleepScore: score,
      sleepStart: startMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(startMs).toLocal(),
      sleepEnd: endMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(endMs).toLocal(),
      phases: phases,
      avgSpo2: spo2,
      avgRespiration: respiration,
      skinTempDelta: _toDouble(json['avgSkinTempDeviationC']),
      avgOvernightHrv: _toDouble(json['avgOvernightHrv']),
      restingHeartRate:
          _toInt(json['restingHeartRate']) ?? _toInt(dto['restingHeartRate']),
      sleepNeedSeconds: sleepNeedSeconds,
    );
  }

  final DateTime date;
  final Duration totalSleep;
  final Duration deepSleep;
  final Duration remSleep;
  final Duration lightSleep;
  final Duration awakeSleep;
  final double? sleepScore;
  final DateTime? sleepStart;
  final DateTime? sleepEnd;
  final List<SleepPhase> phases;
  final double? avgSpo2;
  final double? avgRespiration;
  final double? skinTempDelta;
  final double? avgOvernightHrv;
  final int? restingHeartRate;
  final int? sleepNeedSeconds;

  /// Time asleep as a share of time in bed, 0–100.
  double get efficiency {
    if (sleepStart == null || sleepEnd == null) return 0.0;
    final inBedMinutes = sleepEnd!.difference(sleepStart!).inMinutes;
    if (inBedMinutes <= 0) return 0.0;
    return (totalSleep.inMinutes / inBedMinutes * 100).clamp(0.0, 100.0);
  }

  double get remPercent {
    final total = totalSleep.inSeconds;
    if (total <= 0) return 0.0;
    return remSleep.inSeconds / total * 100;
  }

  double get deepPercent {
    final total = totalSleep.inSeconds;
    if (total <= 0) return 0.0;
    return deepSleep.inSeconds / total * 100;
  }

  /// Compact JSON for the `phases_json` column.
  String phasesToJson() => jsonEncode(
    phases
        .map(
          (p) => {
            's': p.start.toUtc().toIso8601String(),
            'e': p.end.toUtc().toIso8601String(),
            'p': p.phase,
          },
        )
        .toList(),
  );

  static List<SleepPhase> phasesFromJson(String json) {
    final list = jsonDecode(json) as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return SleepPhase(
        DateTime.parse(m['s'] as String).toLocal(),
        DateTime.parse(m['e'] as String).toLocal(),
        m['p'] as String,
      );
    }).toList();
  }
}

class HrvData {
  const HrvData({
    required this.date,
    this.lastNightAvg,
    this.weeklyAvg,
    this.restingHeartRate,
    this.spo2,
    this.respirationRate,
    this.skinTempDelta,
  });

  factory HrvData.fromGarminJson(Map<String, dynamic> json) {
    final summary = json['hrvSummary'] as Map<String, dynamic>? ?? json;
    final date = summary['calendarDate'] ?? json['calendarDate'];
    return HrvData(
      date: DateTime.parse(date as String),
      lastNightAvg: _toDouble(summary['lastNightAvg']),
      weeklyAvg: _toDouble(summary['weeklyAvg']),
      restingHeartRate: _toInt(json['restingHeartRate']),
      spo2: _toDouble(json['averageSpo2']),
      respirationRate: _toDouble(json['avgWakingRespirationValue']),
      skinTempDelta: _toDouble(json['avgSkinTempDeviation']),
    );
  }

  final DateTime date;
  final double? lastNightAvg;
  final double? weeklyAvg;
  final int? restingHeartRate;
  final double? spo2;
  final double? respirationRate;
  final double? skinTempDelta;
}
