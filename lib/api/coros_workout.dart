import '../models/prepared_workout.dart';

/// The workout cannot be expressed for COROS, for a reason to tell the
/// athlete.
class CorosUnsupportedWorkout implements Exception {
  const CorosUnsupportedWorkout(this.reason);
  final String reason;
  @override
  String toString() => reason;
}

/// A workout in the form the COROS Training Hub takes: the program (its
/// steps), the calendar entry and the version record.
class CorosWorkout {
  const CorosWorkout({
    required this.program,
    required this.entity,
    required this.versionObject,
  });

  final Map<String, dynamic> program;
  final Map<String, dynamic> entity;
  final Map<String, dynamic> versionObject;

  /// The body of the schedule update request, with the day written as
  /// [happenDay].
  Map<String, dynamic> payload(String happenDay) => {
    'entities': [
      {...entity, 'happenDay': happenDay},
    ],
    'programs': [program],
    'versionObjects': [versionObject],
    'pbVersion': 2,
  };

  /// A short fingerprint of the steps, to tell a sent workout from a changed
  /// one. The format version is part of it: a workout sent in an earlier
  /// form that COROS misread counts as different and can be sent again.
  int get fingerprint => Object.hashAll([
    _formatVersion,
    program['name'],
    program['duration'],
    program['distance'],
    for (final e in program['exercises'] as List)
      Object.hashAll([
        (e as Map)['exerciseType'],
        e['targetType'],
        e['targetValue'],
        e['sets'],
        e['hrType'],
        e['intensityCustom'],
        e['intensityPercent'],
        e['intensityPercentExtend'],
      ]),
  ]);
}

/// Bumped when the form of a step changes in a way that matters to COROS.
const _formatVersion = 2;

/// Sports the Training Hub's structured workouts cover: run, bike, swim.
const _sportCodes = {
  'running': 1,
  'trail_running': 1,
  'cycling_road': 2,
  'cycling_gravel': 2,
  'cycling_mtb': 2,
  'swimming': 5,
};

// Step kinds and targets, as the Training Hub numbers them.
const _warmUp = 1, _training = 2, _coolDown = 3, _rest = 4;
const _targetOpen = 1, _targetTime = 2, _targetDistance = 5;
const _intensityPercentOfThresholdHr = 2;

/// Zones 0 to 5 are COROS's named heart-rate zones with fixed shares of
/// threshold (Recovery 55-75 %, Aerobic Endurance 75-91 %, Aerobic Power
/// 91-95 %, and so on); 6 takes the range as sent. Sending 2 with a custom
/// range made the Training Hub show the named zone "Aerobic Power" and ignore
/// the range, so every step came out as 91-95 % of threshold.
const _customHeartRateRange = 6;
const _groupSortNo = 67108864; // 2^26, the marker of a repeat group

const _overview = {
  _warmUp: 'sid_run_warm_up_dist',
  _training: 'sid_run_training',
  _coolDown: 'sid_run_cool_down_dist',
  _rest: 'sid_run_cool_down_dist',
};

const _barHeight = {_warmUp: 83, _training: 93, _coolDown: 88, _rest: 5};

/// Builds the COROS form of [workout] for its day. Heart-rate targets become
/// a range as a share of [PreparedWorkout.thresholdHr], which COROS turns into
/// beats per minute from the athlete's own COROS profile. Throws
/// [CorosUnsupportedWorkout] for a sport or a step it has no form for.
///
/// [firstId] numbers the steps; the caller picks one that is unique enough
/// (the clock does).
CorosWorkout buildCorosWorkout(
  PreparedWorkout workout, {
  required int firstId,
  int createdAtSeconds = 0,
}) {
  final sport = _sportCodes[workout.sport];
  if (sport == null) {
    throw CorosUnsupportedWorkout(
      'COROS structured workouts cover running, cycling and swimming, not '
      '${workout.sport.replaceAll('_', ' ')}.',
    );
  }
  var nextId = firstId;
  var order = 0;
  final exercises = <Map<String, dynamic>>[];
  final bars = <Map<String, dynamic>>[];
  final plain = <Map<String, dynamic>>[];

  int kindOf(Map<String, dynamic> step) {
    final key = (step['stepType'] as Map?)?['stepTypeKey'];
    return switch (key) {
      'warmup' => _warmUp,
      'cooldown' => _coolDown,
      'recovery' || 'rest' => _rest,
      _ => _training,
    };
  }

  String time(num seconds) {
    final s = seconds.round();
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, r = s % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(r)}' : '${two(m)}:${two(r)}';
  }

  Map<String, dynamic> step(
    Map<String, dynamic> source, {
    required Object groupId,
    required int sortNo,
  }) {
    final kind = kindOf(source);
    final condition = (source['endCondition'] as Map?)?['conditionTypeKey'];
    final raw = source['endConditionValue'];
    final value = raw is num && raw > 0 ? raw : 0;
    final int targetType;
    final int targetValue;
    final String length;
    if (condition == 'time' && value > 0) {
      targetType = _targetTime;
      targetValue = value.round();
      length = time(value);
    } else if (condition == 'distance' && value > 0) {
      targetType = _targetDistance;
      targetValue = (value * 100).round(); // metres to centimetres
      length = value >= 1000
          ? '${(value / 1000).toStringAsFixed(1)}km'
          : '${value.round()}m';
    } else {
      targetType = _targetOpen;
      targetValue = 0;
      length = 'Open';
    }

    final label = switch (kind) {
      _warmUp => 'WarmUp',
      _coolDown => 'CoolDown',
      _rest => 'Rest',
      _ => 'Training',
    };
    var name = '$label $length';
    var hrType = 0, intensityType = 0, intensityCustom = 0;
    var percent = 0, percentExtend = 0;
    var isPercent = false;
    final threshold = workout.thresholdHr;
    final key = (source['targetType'] as Map?)?['workoutTargetTypeKey'];
    final low = source['targetValueOne'], high = source['targetValueTwo'];
    if (key == 'heart.rate.zone' &&
        low is num &&
        high is num &&
        threshold != null &&
        threshold > 0 &&
        high >= low) {
      // Shares of threshold in tenths of a percent: 91 % is 91000.
      percent = (low / threshold * 100 * 1000).round();
      percentExtend = (high / threshold * 100 * 1000).round();
      hrType = 3;
      intensityType = _intensityPercentOfThresholdHr;
      intensityCustom = _customHeartRateRange;
      isPercent = true;
      final zone = source['zoneNumber'];
      name =
          '$name @ ${zone is num ? 'Z${zone.round()} ' : ''}'
          '${low.round()}-${high.round()} bpm';
    }

    final id = nextId++;
    final out = <String, dynamic>{
      'access': 0,
      'createTimestamp': createdAtSeconds,
      'defaultOrder': sortNo,
      'equipment': [1],
      'exerciseType': kind,
      'groupId': groupId,
      'hrType': hrType,
      'id': id,
      'intensityCustom': intensityCustom,
      'intensityDisplayUnit': 0,
      'intensityMultiplier': 0,
      'intensityPercent': percent,
      'intensityPercentExtend': percentExtend,
      'intensityType': intensityType,
      'intensityValue': 0,
      'intensityValueExtend': 0,
      'isDefaultAdd': 0,
      'isGroup': false,
      'isIntensityPercent': isPercent,
      'name': name,
      'originId': '',
      'overview': _overview[kind],
      'part': [0],
      'restType': 3,
      'restValue': 0,
      'sets': 1,
      'sortNo': sortNo,
      'sourceId': '0',
      'sourceUrl': '',
      'sportType': sport,
      'subType': 0,
      'targetDisplayUnit': targetType == _targetDistance ? 1 : 0,
      'targetType': targetType,
      'targetValue': targetValue,
      'userId': 0,
      'videoUrl': '',
    };
    plain.add(out);
    bars.add({
      'exerciseId': '$id',
      'exerciseType': kind,
      'height': _barHeight[kind],
      'name': name,
      'targetType': targetType,
      'targetValue': targetValue,
      'value': targetValue,
      'width': 0.0,
      'widthFill': 0,
    });
    return out;
  }

  void walk(List<Map<String, dynamic>> items) {
    for (final item in items) {
      final children = item['workoutSteps'];
      if (children is List) {
        final repeats = (item['numberOfIterations'] as num?)?.toInt() ?? 1;
        final groupId = nextId++;
        exercises.add({
          'access': 0,
          'defaultOrder': 0,
          'exerciseType': 0,
          'id': groupId,
          'intensityCustom': 0,
          'intensityMultiplier': 0,
          'intensityType': 0,
          'intensityValue': 0,
          'intensityValueExtend': 0,
          'isDefaultAdd': 0,
          'isGroup': true,
          'name': 'Training',
          'originId': '',
          'overview': '',
          'programId': '',
          'restType': 0,
          'restValue': 0,
          'sets': repeats < 1 ? 1 : repeats,
          'sortNo': _groupSortNo,
          'sourceId': '0',
          'sourceUrl': '',
          'sportType': sport,
          'subType': 0,
          'targetType': '',
          'targetValue': 0,
          'videoUrl': '',
        });
        var child = 0;
        for (final c in children.cast<Map<String, dynamic>>()) {
          if (c['workoutSteps'] is List) {
            throw const CorosUnsupportedWorkout(
              'COROS does not take repeats inside repeats.',
            );
          }
          exercises.add(step(c, groupId: groupId, sortNo: ++child));
        }
      } else {
        exercises.add(step(item, groupId: '', sortNo: ++order));
      }
    }
  }

  walk(workout.steps);
  if (plain.isEmpty) {
    throw const CorosUnsupportedWorkout('The workout has no steps.');
  }
  for (final bar in bars) {
    bar['width'] = double.parse((100 / plain.length).toStringAsFixed(2));
  }

  var duration = 0, distanceCm = 0;
  for (final e in plain) {
    if (e['targetType'] == _targetTime) duration += e['targetValue'] as int;
    if (e['targetType'] == _targetDistance) {
      distanceCm += e['targetValue'] as int;
    }
  }
  final program = <String, dynamic>{
    'access': 1,
    'authorId': '0',
    'createTimestamp': createdAtSeconds,
    'distance': (distanceCm / 100000).toStringAsFixed(2),
    'distanceDisplayUnit': 1,
    'duration': duration,
    'essence': 0,
    'estimatedType': 0,
    'estimatedValue': 0,
    'exerciseNum': 0,
    'exercises': exercises,
    'exerciseBarChart': bars,
    'fastIntensityTypeName': 'custom',
    'headPic': '',
    'id': '0',
    'idInPlan': 1,
    'name': workout.title,
    'nickname': '',
    'originEssence': 0,
    'overview': '',
    'pbVersion': 8,
    'pitch': 0,
    'planIdIndex': 0,
    'poolLength': 10000,
    'poolLengthId': 0,
    'poolLengthUnit': 0,
    'profile': '',
    'referExercise': {'intensityType': 0, 'hrType': 0, 'valueType': 0},
    'sets': plain.length,
    'shareUrl': '',
    'simple': false,
    'sourceId': '0',
    'sourceUrl': '',
    'sportType': sport,
    'star': 0,
    'subType': 65535,
    'targetType': 0,
    'targetValue': 0,
    'thirdPartyId': 0,
    'totalSets': plain.length,
    'trainingLoad': 0,
    'type': 0,
    'unit': 0,
    'userId': '0',
    'version': 0,
    'videoCoverUrl': '',
    'videoUrl': '',
  };
  final entity = <String, dynamic>{
    'dayNo': 0,
    'exerciseBarChart': bars,
    'idInPlan': 1,
    'sortNo': 1,
    'sortNoInPlan': 0,
    'sortNoInSchedule': 1,
  };
  return CorosWorkout(
    program: program,
    entity: entity,
    versionObject: const {'id': 1, 'status': 1},
  );
}
