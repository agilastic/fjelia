import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../utils/log.dart';

/// Built-in Garmin-format workout templates for every supported sport.
/// Rows are tagged `fjelia_builtin` and replaced wholesale when the set changes.
class WorkoutTemplateLibrary {
  WorkoutTemplateLibrary(this._db);

  final AppDatabase _db;

  static const _source = 'fjelia_builtin';

  Future<void> seedIfEmpty() async {
    final templates = _allTemplates();
    final existing = await (_db.select(
      _db.workoutTemplates,
    )..where((t) => t.source.equals(_source))).get();
    if (existing.length != templates.length) {
      await _reseed(templates);
      return;
    }
    // A template whose steps changed is replaced too: what is stored must be
    // what the library says, not what an earlier version said.
    final current = {
      for (final t in templates) '${t.name.value}\u0001${t.stepsJson.value}',
    };
    if (existing.any(
      (t) => !current.contains('${t.name}\u0001${t.stepsJson}'),
    )) {
      await _reseed(templates);
    }
  }

  Future<void> reseed() => _reseed(_allTemplates());

  Future<void> _reseed(List<WorkoutTemplatesCompanion> templates) async {
    await (_db.delete(
      _db.workoutTemplates,
    )..where((t) => t.source.equals(_source))).go();
    for (final t in templates) {
      await _db.into(_db.workoutTemplates).insert(t);
    }
    log('[Templates] reseeded ${templates.length} built-in templates');
  }

  List<WorkoutTemplatesCompanion> _allTemplates() => [
    ..._runningTemplates(),
    ..._runningExtraTemplates(),
    ..._cyclingTemplates(),
    ..._cyclingExtraTemplates(),
    ..._swimmingTemplates(),
    ..._strengthTemplates(),
    ..._yogaTemplates(),
    ..._rowingTemplates(),
    ..._hikingTemplates(),
    ..._inlineSkatingTemplates(),
    ..._nordicSkiingTemplates(),
    ..._skateSkiingTemplates(),
  ];

  WorkoutTemplatesCompanion _t({
    required String sport,
    required String sessionType,
    String? subType,
    required String targetPhase,
    required String name,
    required String description,
    required String coachingCues,
    required String parameterizedFor,
    required int durationMin,
    required int tss,
    required List<String> tags,
    required List<Map<String, dynamic>> steps,
  }) => WorkoutTemplatesCompanion.insert(
    id: const Uuid().v4(),
    sport: sport,
    sessionType: sessionType,
    subType: Value(subType),
    targetPhase: targetPhase,
    name: name,
    description: description,
    coachingCues: Value(coachingCues),
    stepsJson: jsonEncode(steps),
    parameterizedFor: parameterizedFor,
    // The steps are the truth: derive the duration from them (declared
    // values drifted for some templates).
    estimatedDurationMin: _minutesOf(steps, durationMin),
    estimatedTss: tss,
    tagsJson: Value(jsonEncode(tags)),
    source: _source,
    createdAt: DateTime.now(),
  );

  /// Total minutes of a step list (repeats expanded) when every step is timed;
  /// [fallback] otherwise (distance-based steps have no known duration).
  static int _minutesOf(List<Map<String, dynamic>> steps, int fallback) {
    var timed = true;
    int seconds(List<dynamic> list, int mult) {
      var total = 0;
      for (final s in list.cast<Map<String, dynamic>>()) {
        if (s['type'] == 'RepeatGroupDTO') {
          total += seconds(
            s['workoutSteps'] as List,
            mult * ((s['numberOfIterations'] as num?)?.toInt() ?? 1),
          );
        } else if ((s['endCondition'] as Map?)?['conditionTypeKey'] == 'time') {
          total += mult * ((s['endConditionValue'] as num?)?.toInt() ?? 0);
        } else {
          timed = false;
        }
      }
      return total;
    }

    final total = seconds(steps, 1);
    return timed && total > 0 ? (total / 60).round() : fallback;
  }

  /// One timed Garmin step; zone 0 means no HR target.
  Map<String, dynamic> _step(String type, int seconds, int zone) {
    final typeId = switch (type) {
      'warmup' => 1,
      'cooldown' => 2,
      'interval' => 3,
      'recovery' => 4,
      'rest' => 5,
      _ => 8,
    };
    return {
      'type': 'ExecutableStepDTO',
      'stepType': {'stepTypeId': typeId, 'stepTypeKey': type},
      'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
      'endConditionValue': seconds,
      'targetType': {
        'workoutTargetTypeId': zone > 0 ? 4 : 1,
        'workoutTargetTypeKey': zone > 0 ? 'heart.rate.zone' : 'no.target',
      },
      'zoneNumber': zone,
    };
  }

  Map<String, dynamic> _repeatBlock(
    int iterations,
    List<Map<String, dynamic>> steps,
  ) => {
    'type': 'RepeatGroupDTO',
    'stepType': {'stepTypeId': 6, 'stepTypeKey': 'repeat'},
    'endCondition': {'conditionTypeId': 7, 'conditionTypeKey': 'iterations'},
    'endConditionValue': iterations,
    'numberOfIterations': iterations,
    'workoutSteps': steps,
  };

  /// Gives every step that names no zone one, with its heart-rate target, so a
  /// workout written by distance (swimming) still says how hard each part is.
  /// Warm-up is zone 2, recovery and cool-down zone 1, and the work steps take
  /// [intervals] in order (the last one repeats). Steps with a zone are left
  /// as they are.
  List<Map<String, dynamic>> _zoned(
    List<Map<String, dynamic>> steps, {
    required List<int> intervals,
  }) {
    var next = 0;
    Map<String, dynamic> zone(Map<String, dynamic> step) {
      if (step['workoutSteps'] is List) {
        return {
          ...step,
          'workoutSteps': [
            for (final inner in (step['workoutSteps'] as List))
              zone(Map<String, dynamic>.from(inner as Map)),
          ],
        };
      }
      if (step['zoneNumber'] != null) return step;
      final type = (step['stepType'] as Map)['stepTypeKey'];
      final z = switch (type) {
        'warmup' => 2,
        'recovery' || 'rest' || 'cooldown' => 1,
        _ => intervals[next < intervals.length ? next++ : intervals.length - 1],
      };
      return {
        ...step,
        'zoneNumber': z,
        'targetType': {
          'workoutTargetTypeId': 4,
          'workoutTargetTypeKey': 'heart.rate.zone',
        },
      };
    }

    return [for (final step in steps) zone(step)];
  }

  /// One timed power step as a share of FTP (`lo`…`hi`); with an FTP known the
  /// planner turns it into watts, otherwise it falls back to the zone's heart
  /// rate.
  Map<String, dynamic> _pstep(
    String type,
    int seconds,
    double lo,
    double hi,
    int zone,
  ) {
    final typeId = switch (type) {
      'warmup' => 1,
      'cooldown' => 2,
      'interval' => 3,
      'recovery' => 4,
      'rest' => 5,
      _ => 8,
    };
    return {
      'type': 'ExecutableStepDTO',
      'stepType': {'stepTypeId': typeId, 'stepTypeKey': type},
      'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
      'endConditionValue': seconds,
      'targetType': {
        'workoutTargetTypeId': 2,
        'workoutTargetTypeKey': 'power.zone',
      },
      'zoneNumber': zone,
      if ((hi - lo).abs() < 0.005)
        'ftpFraction': lo
      else ...{'ftpLow': lo, 'ftpHigh': hi},
    };
  }

  /// Road-cycling sessions (power targets as a share of FTP, with a zone
  /// number as heart-rate fallback).
  List<WorkoutTemplatesCompanion> _cyclingExtraTemplates() => [
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'VO2max 11×30 s (36 min)',
      description:
          'Intervals near VO2max that raise your aerobic ceiling. Warm-up 10 min. '
          '11 × 30 s at 150% FTP, 1.5 min easy between. Cool-down 5.5 min.',
      coachingCues:
          'Breathe hard but rhythmically and hold the same power in every repetition.',
      parameterizedFor: 'power',
      durationMin: 36,
      tss: 38,
      tags: ['z5', 'vo2'],
      steps: [
        _pstep('warmup', 600, 0.5, 0.75, 2),
        _repeatBlock(10, [
          _pstep('interval', 30, 1.5, 1.5, 5),
          _pstep('recovery', 90, 0.55, 0.55, 1),
        ]),
        _pstep('interval', 30, 1.5, 1.5, 5),
        _pstep('cooldown', 330, 0.4, 0.75, 2),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Mixed Intervals (47 min)',
      description:
          'Varied intensities in one session to train several energy systems. '
          'Warm-up 8 min. 3 sets of (2 × (2 min at 84% FTP, 60 s at 115% FTP, 2 '
          'min at 93% FTP)), 3 min easy between sets. Cool-down 3 min.',
      coachingCues:
          'Treat each effort on its own target and recover fully between them.',
      parameterizedFor: 'power',
      durationMin: 47,
      tss: 54,
      tags: ['z3', 'z4', 'z5', 'mixed'],
      steps: [
        _pstep('warmup', 480, 0.5, 0.75, 2),
        _repeatBlock(2, [
          _pstep('interval', 120, 0.84, 0.84, 3),
          _pstep('interval', 60, 1.15, 1.15, 5),
          _pstep('interval', 120, 0.93, 0.93, 4),
        ]),
        _pstep('recovery', 180, 0.45, 0.45, 1),
        _repeatBlock(2, [
          _pstep('interval', 120, 0.84, 0.84, 3),
          _pstep('interval', 60, 1.15, 1.15, 5),
          _pstep('interval', 120, 0.93, 0.93, 4),
        ]),
        _pstep('recovery', 180, 0.45, 0.45, 1),
        _repeatBlock(2, [
          _pstep('interval', 120, 0.84, 0.84, 3),
          _pstep('interval', 60, 1.15, 1.15, 5),
          _pstep('interval', 120, 0.93, 0.93, 4),
        ]),
        _pstep('cooldown', 180, 0.4, 0.75, 2),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'VO2max 24×30 s (47 min)',
      description:
          'Intervals near VO2max that raise your aerobic ceiling. Warm-up 10 min. '
          '3 sets of (8 × 30 s at 115% FTP with 30 s easy between), 4 min easy '
          'between sets. Cool-down 5 min.',
      coachingCues:
          'Breathe hard but rhythmically and hold the same power in every repetition.',
      parameterizedFor: 'power',
      durationMin: 47,
      tss: 44,
      tags: ['z5', 'vo2'],
      steps: [
        _pstep('warmup', 600, 0.5, 0.75, 2),
        _repeatBlock(8, [
          _pstep('interval', 30, 1.15, 1.15, 5),
          _pstep('recovery', 30, 0.5, 0.5, 1),
        ]),
        _pstep('recovery', 240, 0.5, 0.5, 1),
        _repeatBlock(8, [
          _pstep('interval', 30, 1.15, 1.15, 5),
          _pstep('recovery', 30, 0.5, 0.5, 1),
        ]),
        _pstep('recovery', 240, 0.5, 0.5, 1),
        _repeatBlock(8, [
          _pstep('interval', 30, 1.15, 1.15, 5),
          _pstep('recovery', 30, 0.5, 0.5, 1),
        ]),
        _pstep('cooldown', 300, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Sprints 10×6 s (56 min)',
      description:
          'Short maximal efforts that train neuromuscular power and punch. Warm- '
          'up 10 min. 10 × 6 s at 180% FTP with 4 min easy between. Cool-down 5 '
          'min.',
      coachingCues:
          'Go all out for the full effort, seated or standing, then spin easy '
          'until fully recovered before the next one.',
      parameterizedFor: 'power',
      durationMin: 56,
      tss: 31,
      tags: ['z5', 'sprint'],
      steps: [
        _pstep('warmup', 600, 0.5, 0.75, 2),
        _repeatBlock(10, [
          _pstep('interval', 6, 1.8, 1.8, 5),
          _pstep('recovery', 240, 0.5, 0.5, 1),
        ]),
        _pstep('cooldown', 300, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'VO2max 2×10 min (60 min)',
      description:
          'Intervals near VO2max that raise your aerobic ceiling. Warm-up 15 min. '
          '10 min at 106% FTP; 10 min at 60% FTP; 10 min at 106% FTP. Cool-down '
          '15 min.',
      coachingCues:
          'Breathe hard but rhythmically and hold the same power in every repetition.',
      parameterizedFor: 'power',
      durationMin: 60,
      tss: 65,
      tags: ['z2', 'z5', 'vo2'],
      steps: [
        _pstep('warmup', 900, 0.56, 0.75, 2),
        _pstep('interval', 600, 1.06, 1.06, 5),
        _pstep('interval', 600, 0.6, 0.6, 2),
        _pstep('interval', 600, 1.06, 1.06, 5),
        _pstep('cooldown', 900, 0.56, 0.75, 2),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'VO2max 12×3 min (105 min)',
      description:
          'Intervals near VO2max that raise your aerobic ceiling. Warm-up 14 min. '
          '3 sets of (4 × 3 min at 110% FTP with 3 min easy between), 5 min easy '
          'between sets. Cool-down 9 min.',
      coachingCues:
          'Breathe hard but rhythmically and hold the same power in every repetition.',
      parameterizedFor: 'power',
      durationMin: 105,
      tss: 105,
      tags: ['z5', 'vo2'],
      steps: [
        _pstep('warmup', 840, 0.5, 0.75, 2),
        _repeatBlock(4, [
          _pstep('interval', 180, 1.1, 1.1, 5),
          _pstep('recovery', 180, 0.5, 0.5, 1),
        ]),
        _pstep('recovery', 300, 0.5, 0.5, 1),
        _repeatBlock(4, [
          _pstep('interval', 180, 1.1, 1.1, 5),
          _pstep('recovery', 180, 0.5, 0.5, 1),
        ]),
        _pstep('recovery', 300, 0.5, 0.5, 1),
        _repeatBlock(4, [
          _pstep('interval', 180, 1.1, 1.1, 5),
          _pstep('recovery', 180, 0.5, 0.5, 1),
        ]),
        _pstep('cooldown', 540, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Sweet Spot 3×7 min (45 min)',
      description:
          'Sustained effort just below threshold with a high aerobic return per '
          'hour. Warm-up 8 min. 2 min at 70% FTP; 3 × 7 min at 90% FTP with 3 min '
          'easy between. Cool-down 5 min.',
      coachingCues:
          'Hard but sustainable; stay seated and smooth and keep the power even.',
      parameterizedFor: 'power',
      durationMin: 45,
      tss: 42,
      tags: ['z2', 'z4', 'sweetspot'],
      steps: [
        _pstep('warmup', 480, 0.5, 0.75, 2),
        _pstep('interval', 120, 0.7, 0.7, 2),
        _repeatBlock(3, [
          _pstep('interval', 420, 0.9, 0.9, 4),
          _pstep('recovery', 180, 0.55, 0.55, 1),
        ]),
        _pstep('cooldown', 300, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Sweet Spot Blocks (65 min)',
      description:
          'Sustained effort just below threshold with a high aerobic return per '
          'hour. Warm-up 10 min. 3 × 12 min at 90% FTP with 3 min easy between; 3 '
          'min at 90% FTP. Cool-down 7 min.',
      coachingCues:
          'Hard but sustainable; stay seated and smooth and keep the power even.',
      parameterizedFor: 'power',
      durationMin: 65,
      tss: 72,
      tags: ['z4', 'sweetspot'],
      steps: [
        _pstep('warmup', 600, 0.4, 0.8, 2),
        _repeatBlock(3, [
          _pstep('interval', 720, 0.9, 0.9, 4),
          _pstep('recovery', 180, 0.8, 0.8, 3),
        ]),
        _pstep('interval', 180, 0.9, 0.9, 4),
        _pstep('cooldown', 420, 0.4, 0.7, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Tempo 3×10 min (65 min)',
      description:
          'Sustained moderate-hard riding that builds endurance and muscular '
          'stamina. Warm-up 10 min. 2 × (10 min at 81% FTP, 5 min at 65% FTP); 10 '
          'min at 81% FTP. Cool-down 15 min.',
      coachingCues:
          'Comfortably hard: you can speak in short sentences. Do not drift above the target.',
      parameterizedFor: 'power',
      durationMin: 65,
      tss: 50,
      tags: ['z2', 'z3', 'tempo'],
      steps: [
        _pstep('warmup', 600, 0.25, 0.75, 1),
        _repeatBlock(2, [
          _pstep('interval', 600, 0.81, 0.81, 3),
          _pstep('interval', 300, 0.65, 0.65, 2),
        ]),
        _pstep('interval', 600, 0.81, 0.81, 3),
        _pstep('cooldown', 900, 0.25, 0.75, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Tempo Blocks (87 min)',
      description:
          'Sustained moderate-hard riding that builds endurance and muscular '
          'stamina. Warm-up 10 min. 6 × 60 s at 87% FTP with 60 s easy between; 3 '
          '× (15 min at 87% FTP, 5 min at 72% FTP). Cool-down 5 min.',
      coachingCues:
          'Comfortably hard: you can speak in short sentences. Do not drift above the target.',
      parameterizedFor: 'power',
      durationMin: 87,
      tss: 93,
      tags: ['z2', 'z3', 'tempo'],
      steps: [
        _pstep('warmup', 600, 0.55, 0.72, 2),
        _repeatBlock(6, [
          _pstep('interval', 60, 0.87, 0.87, 3),
          _pstep('recovery', 60, 0.72, 0.72, 2),
        ]),
        _repeatBlock(3, [
          _pstep('interval', 900, 0.87, 0.87, 3),
          _pstep('interval', 300, 0.72, 0.72, 2),
        ]),
        _pstep('cooldown', 300, 0.55, 0.72, 2),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Sweet Spot 6×5 min (88 min)',
      description:
          'Sustained effort just below threshold with a high aerobic return per '
          'hour. Warm-up 20 min. 5 min easy; 6 × 5 min at 90% FTP with 5 min easy '
          'between. Cool-down 3 min.',
      coachingCues:
          'Hard but sustainable; stay seated and smooth and keep the power even.',
      parameterizedFor: 'power',
      durationMin: 88,
      tss: 63,
      tags: ['z4', 'sweetspot'],
      steps: [
        _pstep('warmup', 1200, 0.35, 0.85, 2),
        _pstep('recovery', 300, 0.4, 0.4, 1),
        _repeatBlock(6, [
          _pstep('interval', 300, 0.9, 0.9, 4),
          _pstep('recovery', 300, 0.4, 0.4, 1),
        ]),
        _pstep('cooldown', 180, 0.4, 0.75, 2),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Sweet Spot 4×12 min (90 min)',
      description:
          'Sustained effort just below threshold with a high aerobic return per '
          'hour. Warm-up 13 min. 4 × 12 min at 90% FTP with 5 min easy between. '
          'Cool-down 9 min.',
      coachingCues:
          'Hard but sustainable; stay seated and smooth and keep the power even.',
      parameterizedFor: 'power',
      durationMin: 90,
      tss: 88,
      tags: ['z4', 'sweetspot'],
      steps: [
        _pstep('warmup', 780, 0.5, 0.75, 2),
        _repeatBlock(4, [
          _pstep('interval', 720, 0.9, 0.9, 4),
          _pstep('recovery', 300, 0.55, 0.55, 1),
        ]),
        _pstep('cooldown', 540, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Sweet Spot 2×30 min (95 min)',
      description:
          'Sustained effort just below threshold with a high aerobic return per '
          'hour. Warm-up 15 min. 2 × 30 min at 90% FTP with 5 min easy between. '
          'Cool-down 10 min.',
      coachingCues:
          'Hard but sustainable; stay seated and smooth and keep the power even.',
      parameterizedFor: 'power',
      durationMin: 95,
      tss: 101,
      tags: ['z4', 'sweetspot'],
      steps: [
        _pstep('warmup', 900, 0.5, 0.75, 2),
        _repeatBlock(2, [
          _pstep('interval', 1800, 0.9, 0.9, 4),
          _pstep('recovery', 300, 0.55, 0.55, 1),
        ]),
        _pstep('cooldown', 600, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Tempo Ride 1 h 20 min (100 min)',
      description:
          'Sustained moderate-hard riding that builds endurance and muscular '
          'stamina. Warm-up 12 min. 1 h 20 min at 78% FTP. Cool-down 8 min.',
      coachingCues:
          'Comfortably hard: you can speak in short sentences. Do not drift above the target.',
      parameterizedFor: 'power',
      durationMin: 100,
      tss: 91,
      tags: ['z3', 'tempo'],
      steps: [
        _pstep('warmup', 720, 0.45, 0.65, 1),
        _pstep('interval', 4800, 0.78, 0.78, 3),
        _pstep('cooldown', 480, 0.4, 0.6, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Sweet Spot 2×17 min (105 min)',
      description:
          'Sustained effort just below threshold with a high aerobic return per '
          'hour. Warm-up 15 min. 2 × 17 min at 89% FTP with 5 min easy between; '
          '36 min at 65% FTP. Cool-down 10 min.',
      coachingCues:
          'Hard but sustainable; stay seated and smooth and keep the power even.',
      parameterizedFor: 'power',
      durationMin: 105,
      tss: 84,
      tags: ['z2', 'z4', 'sweetspot'],
      steps: [
        _pstep('warmup', 900, 0.25, 0.75, 1),
        _repeatBlock(2, [
          _pstep('interval', 1020, 0.89, 0.89, 4),
          _pstep('recovery', 300, 0.5, 0.5, 1),
        ]),
        _pstep('interval', 2160, 0.65, 0.65, 2),
        _pstep('cooldown', 600, 0.25, 0.66, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Sweet Spot 3×20 min (105 min)',
      description:
          'Sustained effort just below threshold with a high aerobic return per '
          'hour. Warm-up 15 min. 3 × 20 min at 92% FTP with 5 min easy between. '
          'Cool-down 15 min.',
      coachingCues:
          'Hard but sustainable; stay seated and smooth and keep the power even.',
      parameterizedFor: 'power',
      durationMin: 105,
      tss: 108,
      tags: ['z4', 'sweetspot'],
      steps: [
        _pstep('warmup', 900, 0.25, 0.75, 1),
        _repeatBlock(3, [
          _pstep('interval', 1200, 0.92, 0.92, 4),
          _pstep('recovery', 300, 0.65, 0.65, 2),
        ]),
        _pstep('cooldown', 900, 0.25, 0.75, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'threshold',
      targetPhase: 'base,build,peak',
      name: 'Threshold 2×10 min (42 min)',
      description:
          'Work at threshold power to lift the effort you can sustain for an '
          'hour. Warm-up 6 min. 2 min easy; 2 × 10 min at 100% FTP, 6 min easy '
          'between. Cool-down 8 min.',
      coachingCues:
          'Settle into a steady, controlled effort; the last repetition should '
          'feel hard but not desperate.',
      parameterizedFor: 'power',
      durationMin: 42,
      tss: 45,
      tags: ['z4', 'threshold'],
      steps: [
        _pstep('warmup', 360, 0.5, 0.75, 2),
        _pstep('recovery', 120, 0.5, 0.5, 1),
        _repeatBlock(1, [
          _pstep('interval', 600, 1.0, 1.0, 4),
          _pstep('recovery', 360, 0.5, 0.5, 1),
        ]),
        _pstep('interval', 600, 1.0, 1.0, 4),
        _pstep('cooldown', 480, 0.6, 0.5, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'threshold',
      targetPhase: 'base,build,peak',
      name: 'Threshold 3×8 min (60 min)',
      description:
          'Work at threshold power to lift the effort you can sustain for an '
          'hour. Warm-up 12.5 min. 3 × 8 min at 95% FTP with 5 min easy between. '
          'Cool-down 8.5 min.',
      coachingCues:
          'Settle into a steady, controlled effort; the last repetition should '
          'feel hard but not desperate.',
      parameterizedFor: 'power',
      durationMin: 60,
      tss: 56,
      tags: ['z4', 'threshold'],
      steps: [
        _pstep('warmup', 750, 0.5, 0.75, 2),
        _repeatBlock(3, [
          _pstep('interval', 480, 0.95, 0.95, 4),
          _pstep('recovery', 300, 0.55, 0.55, 1),
        ]),
        _pstep('cooldown', 510, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'threshold',
      targetPhase: 'base,build,peak',
      name: 'Threshold 4×10 min (64 min)',
      description:
          'Work at threshold power to lift the effort you can sustain for an '
          'hour. Warm-up 10 min. 4 × 10 min at 104% FTP, 2 min easy between. '
          'Cool-down 8 min.',
      coachingCues:
          'Settle into a steady, controlled effort; the last repetition should '
          'feel hard but not desperate.',
      parameterizedFor: 'power',
      durationMin: 64,
      tss: 86,
      tags: ['z4', 'threshold'],
      steps: [
        _pstep('warmup', 600, 0.5, 0.75, 2),
        _repeatBlock(3, [
          _pstep('interval', 600, 1.04, 1.04, 4),
          _pstep('recovery', 120, 0.5, 0.5, 1),
        ]),
        _pstep('interval', 600, 1.04, 1.04, 4),
        _pstep('cooldown', 480, 0.47, 0.75, 2),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'threshold',
      targetPhase: 'base,build,peak',
      name: 'Threshold 3×10 min (65 min)',
      description:
          'Work at threshold power to lift the effort you can sustain for an '
          'hour. Warm-up 12 min. 3 × 10 min at 100% FTP with 5 min easy between. '
          'Cool-down 8 min.',
      coachingCues:
          'Settle into a steady, controlled effort; the last repetition should '
          'feel hard but not desperate.',
      parameterizedFor: 'power',
      durationMin: 65,
      tss: 69,
      tags: ['z4', 'threshold'],
      steps: [
        _pstep('warmup', 720, 0.5, 0.75, 2),
        _repeatBlock(3, [
          _pstep('interval', 600, 1.0, 1.0, 4),
          _pstep('recovery', 300, 0.55, 0.55, 1),
        ]),
        _pstep('cooldown', 480, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'threshold',
      targetPhase: 'base,build,peak',
      name: 'Threshold 3×12 min (70 min)',
      description:
          'Work at threshold power to lift the effort you can sustain for an '
          'hour. Warm-up 11.5 min. 3 × 12 min at 95% FTP with 5 min easy between. '
          'Cool-down 7.5 min.',
      coachingCues:
          'Settle into a steady, controlled effort; the last repetition should '
          'feel hard but not desperate.',
      parameterizedFor: 'power',
      durationMin: 70,
      tss: 73,
      tags: ['z4', 'threshold'],
      steps: [
        _pstep('warmup', 690, 0.5, 0.75, 2),
        _repeatBlock(3, [
          _pstep('interval', 720, 0.95, 0.95, 4),
          _pstep('recovery', 300, 0.55, 0.55, 1),
        ]),
        _pstep('cooldown', 450, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'threshold',
      targetPhase: 'base,build,peak',
      name: 'Threshold 6×6 min (75 min)',
      description:
          'Work at threshold power to lift the effort you can sustain for an '
          'hour. Warm-up 12.5 min. 6 × 6 min at 100% FTP with 3 min easy between. '
          'Cool-down 8.5 min.',
      coachingCues:
          'Settle into a steady, controlled effort; the last repetition should '
          'feel hard but not desperate.',
      parameterizedFor: 'power',
      durationMin: 75,
      tss: 81,
      tags: ['z4', 'threshold'],
      steps: [
        _pstep('warmup', 750, 0.5, 0.75, 2),
        _repeatBlock(6, [
          _pstep('interval', 360, 1.0, 1.0, 4),
          _pstep('recovery', 180, 0.55, 0.55, 1),
        ]),
        _pstep('cooldown', 510, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'threshold',
      targetPhase: 'base,build,peak',
      name: 'Threshold 2×12 min (79 min)',
      description:
          'Work at threshold power to lift the effort you can sustain for an '
          'hour. Warm-up 20 min. 5 min easy; 2 × 12 min at 100% FTP with 10 min '
          'easy between. Cool-down 10 min.',
      coachingCues:
          'Settle into a steady, controlled effort; the last repetition should '
          'feel hard but not desperate.',
      parameterizedFor: 'power',
      durationMin: 79,
      tss: 68,
      tags: ['z4', 'threshold'],
      steps: [
        _pstep('warmup', 1200, 0.45, 0.75, 2),
        _pstep('recovery', 300, 0.52, 0.52, 1),
        _repeatBlock(2, [
          _pstep('interval', 720, 1.0, 1.0, 4),
          _pstep('recovery', 600, 0.52, 0.52, 1),
        ]),
        _pstep('cooldown', 600, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'threshold',
      targetPhase: 'base,build,peak',
      name: 'Threshold 3×18 min (82 min)',
      description:
          'Work at threshold power to lift the effort you can sustain for an '
          'hour. Warm-up 10.5 min. 3 × 18 min at 100% FTP with 4 min easy '
          'between. Cool-down 5.5 min.',
      coachingCues:
          'Settle into a steady, controlled effort; the last repetition should '
          'feel hard but not desperate.',
      parameterizedFor: 'power',
      durationMin: 82,
      tss: 106,
      tags: ['z4', 'threshold'],
      steps: [
        _pstep('warmup', 630, 0.5, 0.75, 2),
        _repeatBlock(3, [
          _pstep('interval', 1080, 1.0, 1.0, 4),
          _pstep('recovery', 240, 0.55, 0.55, 1),
        ]),
        _pstep('cooldown', 330, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'threshold',
      targetPhase: 'base,build,peak',
      name: 'Threshold 3×15 min (85 min)',
      description:
          'Work at threshold power to lift the effort you can sustain for an '
          'hour. Warm-up 15 min. 3 × 15 min at 95% FTP with 5 min easy between. '
          'Cool-down 10 min.',
      coachingCues:
          'Settle into a steady, controlled effort; the last repetition should '
          'feel hard but not desperate.',
      parameterizedFor: 'power',
      durationMin: 85,
      tss: 90,
      tags: ['z4', 'threshold'],
      steps: [
        _pstep('warmup', 900, 0.5, 0.75, 2),
        _repeatBlock(3, [
          _pstep('interval', 900, 0.95, 0.95, 4),
          _pstep('recovery', 300, 0.55, 0.55, 1),
        ]),
        _pstep('cooldown', 600, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'threshold',
      targetPhase: 'base,build,peak',
      name: 'Threshold 2×30 min (86 min)',
      description:
          'Work at threshold power to lift the effort you can sustain for an '
          'hour. Warm-up 10 min. 2 × 30 min at 95% FTP with 5 min easy between. '
          'Cool-down 6 min.',
      coachingCues:
          'Settle into a steady, controlled effort; the last repetition should '
          'feel hard but not desperate.',
      parameterizedFor: 'power',
      durationMin: 86,
      tss: 105,
      tags: ['z4', 'threshold'],
      steps: [
        _pstep('warmup', 600, 0.5, 0.75, 2),
        _repeatBlock(2, [
          _pstep('interval', 1800, 0.95, 0.95, 4),
          _pstep('recovery', 300, 0.55, 0.55, 1),
        ]),
        _pstep('cooldown', 360, 0.45, 0.65, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Endurance Ride (75 min)',
      description:
          'Steady aerobic riding that builds the base for everything else. Warm- '
          'up 15 min. 50 min at 68% FTP. Cool-down 10 min.',
      coachingCues:
          'Keep it conversational and fuel early and regularly.',
      parameterizedFor: 'power',
      durationMin: 75,
      tss: 50,
      tags: ['z2', 'endurance'],
      steps: [
        _pstep('warmup', 900, 0.45, 0.65, 1),
        _pstep('interval', 3000, 0.68, 0.68, 2),
        _pstep('cooldown', 600, 0.4, 0.6, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Endurance Ride (85 min)',
      description:
          'Steady aerobic riding that builds the base for everything else. Warm- '
          'up 15 min. 1 h at 62% FTP. Cool-down 10 min.',
      coachingCues:
          'Keep it conversational and fuel early and regularly.',
      parameterizedFor: 'power',
      durationMin: 85,
      tss: 50,
      tags: ['z2', 'endurance'],
      steps: [
        _pstep('warmup', 900, 0.45, 0.65, 1),
        _pstep('interval', 3600, 0.62, 0.62, 2),
        _pstep('cooldown', 600, 0.4, 0.6, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Endurance Ride (100 min)',
      description:
          'Steady aerobic riding that builds the base for everything else. Warm- '
          'up 15 min. 1 h 15 min at 62% FTP. Cool-down 10 min.',
      coachingCues:
          'Keep it conversational and fuel early and regularly.',
      parameterizedFor: 'power',
      durationMin: 100,
      tss: 60,
      tags: ['z2', 'endurance'],
      steps: [
        _pstep('warmup', 900, 0.45, 0.65, 1),
        _pstep('interval', 4500, 0.62, 0.62, 2),
        _pstep('cooldown', 600, 0.4, 0.6, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Endurance Ride (150 min)',
      description:
          'Steady aerobic riding that builds the base for everything else. Warm- '
          'up 15 min. 2 h 5 min at 62% FTP. Cool-down 10 min.',
      coachingCues:
          'Keep it conversational and fuel early and regularly.',
      parameterizedFor: 'power',
      durationMin: 150,
      tss: 92,
      tags: ['z2', 'endurance'],
      steps: [
        _pstep('warmup', 900, 0.45, 0.65, 1),
        _pstep('interval', 7500, 0.62, 0.62, 2),
        _pstep('cooldown', 600, 0.4, 0.6, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Endurance Ride with Tempo Blocks (150 min)',
      description:
          'Aerobic riding with steady blocks that train fatigue resistance. Warm- '
          'up 15 min. 1 h 39 min at 66% FTP; 2 × (8 min at 80% FTP, 5 min at 60% '
          'FTP). Cool-down 10 min.',
      coachingCues:
          'Ride the easy parts truly easy so the blocks stay on target.',
      parameterizedFor: 'power',
      durationMin: 150,
      tss: 107,
      tags: ['z2', 'z3', 'endurance_blocks'],
      steps: [
        _pstep('warmup', 900, 0.45, 0.65, 1),
        _pstep('interval', 5940, 0.66, 0.66, 2),
        _repeatBlock(2, [
          _pstep('interval', 480, 0.8, 0.8, 3),
          _pstep('interval', 300, 0.6, 0.6, 2),
        ]),
        _pstep('cooldown', 600, 0.4, 0.6, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Endurance Ride (225 min)',
      description:
          'Steady aerobic riding that builds the base for everything else. Warm- '
          'up 15 min. 3 h 20 min at 62% FTP. Cool-down 10 min.',
      coachingCues:
          'Keep it conversational and fuel early and regularly.',
      parameterizedFor: 'power',
      durationMin: 225,
      tss: 140,
      tags: ['z2', 'endurance'],
      steps: [
        _pstep('warmup', 900, 0.45, 0.65, 1),
        _pstep('interval', 12000, 0.62, 0.62, 2),
        _pstep('cooldown', 600, 0.4, 0.6, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Recovery Spin (35 min)',
      description:
          'Very easy spinning that promotes recovery between hard days. Warm-up '
          '10 min. 15 min at 65% FTP. Cool-down 10 min.',
      coachingCues:
          'Light pressure on the pedals and a comfortable cadence; if it feels like work, ease off.',
      parameterizedFor: 'power',
      durationMin: 35,
      tss: 19,
      tags: ['z2', 'recovery'],
      steps: [
        _pstep('warmup', 600, 0.25, 0.75, 1),
        _pstep('interval', 900, 0.65, 0.65, 2),
        _pstep('cooldown', 600, 0.75, 0.26, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Recovery Spin (55 min)',
      description:
          'Very easy spinning that promotes recovery between hard days. Warm-up 5 '
          'min. 3 × 10 min at 60% FTP with 5 min easy between. Cool-down 5 min.',
      coachingCues:
          'Light pressure on the pedals and a comfortable cadence; if it feels like work, ease off.',
      parameterizedFor: 'power',
      durationMin: 55,
      tss: 28,
      tags: ['z2', 'recovery'],
      steps: [
        _pstep('warmup', 300, 0.25, 0.75, 1),
        _repeatBlock(3, [
          _pstep('interval', 600, 0.6, 0.6, 2),
          _pstep('recovery', 300, 0.5, 0.5, 1),
        ]),
        _pstep('cooldown', 300, 0.5, 0.25, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Recovery Spin (60 min)',
      description:
          'Very easy spinning that promotes recovery between hard days. 30 min at '
          '53% FTP; 30 min easy.',
      coachingCues:
          'Light pressure on the pedals and a comfortable cadence; if it feels like work, ease off.',
      parameterizedFor: 'power',
      durationMin: 60,
      tss: 28,
      tags: ['z1', 'recovery'],
      steps: [
        _pstep('interval', 1800, 0.53, 0.53, 1),
        _pstep('recovery', 1800, 0.53, 0.53, 1),
      ],
    ),
  ];

  /// Running sessions with heart-rate zone targets.
  List<WorkoutTemplatesCompanion> _runningExtraTemplates() => [
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Speed Repeats 10×60 s (48 min)',
      description:
          'Short fast repetitions that sharpen speed and running economy. Warm-up '
          '10 min. 5 × 60 s at Z5 with 2 min easy between; 3 min at Z2; 5 × 60 s '
          'at Z5 with 2 min easy between. Cool-down 5 min.',
      coachingCues:
          'Run fast but relaxed with tall posture, and walk or jog easily between repetitions.',
      parameterizedFor: 'hr',
      durationMin: 48,
      tss: 38,
      tags: ['z2', 'z5', 'interval'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(5, [
          _step('interval', 60, 5),
          _step('recovery', 120, 1),
        ]),
        _step('interval', 180, 2),
        _repeatBlock(5, [
          _step('interval', 60, 5),
          _step('recovery', 120, 1),
        ]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Speed Repeats 12×60 s (49 min)',
      description:
          'Short fast repetitions that sharpen speed and running economy. Warm-up '
          '10 min. 6 × 60 s at Z5 with 60 s easy between; 5 min at Z2; 6 × 60 s '
          'at Z5 with 60 s easy between. Cool-down 10 min.',
      coachingCues:
          'Run fast but relaxed with tall posture, and walk or jog easily between repetitions.',
      parameterizedFor: 'hr',
      durationMin: 49,
      tss: 49,
      tags: ['z2', 'z5', 'interval'],
      steps: [
        _step('warmup', 600, 2),
        _repeatBlock(6, [
          _step('interval', 60, 5),
          _step('recovery', 60, 1),
        ]),
        _step('interval', 300, 2),
        _repeatBlock(6, [
          _step('interval', 60, 5),
          _step('recovery', 60, 1),
        ]),
        _step('cooldown', 600, 2),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'VO2max Intervals 6×4.3 min (52 min)',
      description:
          'Hard intervals near VO2max that raise your aerobic ceiling. Warm-up 10 '
          'min. 6 × 4.3 min at Z5 with 60 s easy between. Cool-down 10 min.',
      coachingCues:
          'Controlled, hard breathing; aim for the same pace on every repetition.',
      parameterizedFor: 'hr',
      durationMin: 52,
      tss: 61,
      tags: ['z5', 'interval'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(6, [
          _step('interval', 260, 5),
          _step('recovery', 60, 1),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Fartlek (56 min)',
      description:
          'Unstructured speed play within a continuous run. Warm-up 15 min. 6 × '
          '1.5 min at Z5 with 1.5 min easy between; 5 min at Z4; 4 × 60 s at Z5 '
          'with 60 s easy between. Cool-down 10 min.',
      coachingCues:
          'Alternate effort by feel; keep the easy sections easy.',
      parameterizedFor: 'hr',
      durationMin: 56,
      tss: 51,
      tags: ['z4', 'z5', 'mixed'],
      steps: [
        _step('warmup', 900, 1),
        _repeatBlock(6, [
          _step('interval', 90, 5),
          _step('recovery', 90, 1),
        ]),
        _step('interval', 300, 4),
        _repeatBlock(4, [
          _step('interval', 60, 5),
          _step('recovery', 60, 1),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Threshold Intervals 3×6 min (57 min)',
      description:
          'Intervals at threshold effort that raise the pace you can hold. Warm- '
          'up 10 min. 3 × 6 min at Z4 with 3 min easy between; 15 min at Z2. '
          'Cool-down 5 min.',
      coachingCues:
          'Comfortably hard and even; you can say a few words but not hold a conversation.',
      parameterizedFor: 'hr',
      durationMin: 57,
      tss: 56,
      tags: ['z2', 'z4', 'interval'],
      steps: [
        _step('warmup', 600, 2),
        _repeatBlock(3, [
          _step('interval', 360, 4),
          _step('recovery', 180, 1),
        ]),
        _step('interval', 900, 2),
        _step('cooldown', 300, 2),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Threshold Intervals 8×4 min (63 min)',
      description:
          'Intervals at threshold effort that raise the pace you can hold. Warm- '
          'up 10 min. 8 × 4 min at Z4 with 2 min easy between. Cool-down 5 min.',
      coachingCues:
          'Comfortably hard and even; you can say a few words but not hold a conversation.',
      parameterizedFor: 'hr',
      durationMin: 63,
      tss: 69,
      tags: ['z4', 'interval'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(8, [
          _step('interval', 240, 4),
          _step('recovery', 120, 2),
        ]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Speed Repeats 16×60 s (65 min)',
      description:
          'Short fast repetitions that sharpen speed and running economy. Warm-up '
          '10 min. 8 × 60 s at Z5 with 1.5 min easy between; 5 min at Z2; 8 × 60 '
          's at Z5 with 1.5 min easy between. Cool-down 10 min.',
      coachingCues:
          'Run fast but relaxed with tall posture, and walk or jog easily between repetitions.',
      parameterizedFor: 'hr',
      durationMin: 65,
      tss: 56,
      tags: ['z2', 'z5', 'interval'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(8, [
          _step('interval', 60, 5),
          _step('recovery', 90, 1),
        ]),
        _step('interval', 300, 2),
        _repeatBlock(8, [
          _step('interval', 60, 5),
          _step('recovery', 90, 1),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'VO2max Intervals 10×4 min (65 min)',
      description:
          'Hard intervals near VO2max that raise your aerobic ceiling. Warm-up 5 '
          'min. 10 × 4 min at Z5 with 1.5 min easy between. Cool-down 5 min.',
      coachingCues:
          'Controlled, hard breathing; aim for the same pace on every repetition.',
      parameterizedFor: 'hr',
      durationMin: 65,
      tss: 89,
      tags: ['z5', 'interval'],
      steps: [
        _step('warmup', 300, 2),
        _repeatBlock(10, [
          _step('interval', 240, 5),
          _step('recovery', 90, 1),
        ]),
        _step('cooldown', 300, 2),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Alternating Pace Run (70 min)',
      description:
          'A continuous run that alternates between steady-hard and easier pace '
          'to build stamina. Warm-up 15 min. 3 × 10 min at Z4 with 1.5 min easy '
          'between; 5 min at Z5. Cool-down 15 min.',
      coachingCues:
          'Keep the harder sections even and the easier ones relaxed; do not let '
          'the easier pace drift too fast.',
      parameterizedFor: 'hr',
      durationMin: 70,
      tss: 72,
      tags: ['z4', 'z5', 'mixed'],
      steps: [
        _step('warmup', 900, 1),
        _repeatBlock(3, [
          _step('interval', 600, 4),
          _step('recovery', 90, 1),
        ]),
        _step('interval', 300, 5),
        _step('cooldown', 900, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'VO2max Intervals 6×5 min (70 min)',
      description:
          'Hard intervals near VO2max that raise your aerobic ceiling. Warm-up 10 '
          'min. 6 × 5 min at Z5 with 3.3 min easy between. Cool-down 10 min.',
      coachingCues:
          'Controlled, hard breathing; aim for the same pace on every repetition.',
      parameterizedFor: 'hr',
      durationMin: 70,
      tss: 82,
      tags: ['z5', 'interval'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(6, [
          _step('interval', 300, 5),
          _step('recovery', 200, 2),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Tempo Blocks 3×5 min (42 min)',
      description:
          'Sustained steady-hard running that builds stamina. Warm-up 5 min. 3 × '
          '5 min at Z3 with 2.5 min easy between; 10 min at Z2. Cool-down 5 min.',
      coachingCues:
          'Hold an even effort; ease slightly if breathing runs away from you.',
      parameterizedFor: 'hr',
      durationMin: 42,
      tss: 37,
      tags: ['z2', 'z3', 'tempo'],
      steps: [
        _step('warmup', 300, 2),
        _repeatBlock(3, [
          _step('interval', 300, 3),
          _step('recovery', 150, 1),
        ]),
        _step('interval', 600, 2),
        _step('cooldown', 300, 2),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Tempo Blocks 4×4 min (44 min)',
      description:
          'Sustained steady-hard running that builds stamina. Warm-up 10 min. 4 × '
          '4 min at Z3 with 2 min easy between. Cool-down 10 min.',
      coachingCues:
          'Hold an even effort; ease slightly if breathing runs away from you.',
      parameterizedFor: 'hr',
      durationMin: 44,
      tss: 32,
      tags: ['z3', 'tempo'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(4, [
          _step('interval', 240, 3),
          _step('recovery', 120, 1),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Tempo Blocks 5×5 min (50 min)',
      description:
          'Sustained steady-hard running that builds stamina. Warm-up 15 min. 5 × '
          '5 min at Z3 with 60 s easy between. Cool-down 5 min.',
      coachingCues:
          'Hold an even effort; ease slightly if breathing runs away from you.',
      parameterizedFor: 'hr',
      durationMin: 50,
      tss: 41,
      tags: ['z3', 'tempo'],
      steps: [
        _step('warmup', 900, 1),
        _repeatBlock(5, [
          _step('interval', 300, 3),
          _step('recovery', 60, 1),
        ]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Tempo Blocks 4×8 min (56 min)',
      description:
          'Sustained steady-hard running that builds stamina. Warm-up 10 min. 60 '
          's at Z1; 4 × 8 min at Z3 with 2 min easy between. Cool-down 5 min.',
      coachingCues:
          'Hold an even effort; ease slightly if breathing runs away from you.',
      parameterizedFor: 'hr',
      durationMin: 56,
      tss: 48,
      tags: ['z1', 'z3', 'tempo'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 60, 1),
        _repeatBlock(4, [
          _step('interval', 480, 3),
          _step('recovery', 120, 1),
        ]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Tempo Blocks 8×4.5 min (66 min)',
      description:
          'Sustained steady-hard running that builds stamina. Warm-up 10 min. 4 × '
          '5 min at Z3 with 60 s easy between; 3 min at Z2; 4 × 4 min at Z3 with '
          '2 min easy between. Cool-down 5 min.',
      coachingCues:
          'Hold an even effort; ease slightly if breathing runs away from you.',
      parameterizedFor: 'hr',
      durationMin: 66,
      tss: 56,
      tags: ['z2', 'z3', 'tempo'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(4, [
          _step('interval', 300, 3),
          _step('recovery', 60, 1),
        ]),
        _step('interval', 180, 2),
        _repeatBlock(4, [
          _step('interval', 240, 3),
          _step('recovery', 120, 1),
        ]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Run with Steady Blocks (77 min)',
      description:
          'A long run with steady-hard blocks that train running on tired legs. '
          'Warm-up 10 min. 5 × 4 min at Z2 with 2 min easy between; 4 × 3 min at '
          'Z2 with 1.5 min easy between; 3 × 2 min at Z3 with 60 s easy between. '
          'Cool-down 10 min.',
      coachingCues:
          'Keep the easy running easy so that the blocks stay controlled.',
      parameterizedFor: 'hr',
      durationMin: 77,
      tss: 53,
      tags: ['z2', 'z3', 'long_finish'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(5, [
          _step('interval', 240, 2),
          _step('recovery', 120, 1),
        ]),
        _repeatBlock(4, [
          _step('interval', 180, 2),
          _step('recovery', 90, 1),
        ]),
        _repeatBlock(3, [
          _step('interval', 120, 3),
          _step('recovery', 60, 2),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Run with Threshold Blocks (80 min)',
      description:
          'A long run with steady-hard blocks that train running on tired legs. '
          'Warm-up 15 min. 5 × 4 min at Z4 with 6 min easy between. Cool-down 15 '
          'min.',
      coachingCues:
          'Keep the easy running easy so that the blocks stay controlled.',
      parameterizedFor: 'hr',
      durationMin: 80,
      tss: 60,
      tags: ['z4', 'long_finish'],
      steps: [
        _step('warmup', 900, 1),
        _repeatBlock(5, [
          _step('interval', 240, 4),
          _step('recovery', 360, 1),
        ]),
        _step('cooldown', 900, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Run with Steady Blocks (103 min)',
      description:
          'A long run with steady-hard blocks that train running on tired legs. '
          'Warm-up 10 min. 5 × 3.3 min at Z3 with 1.7 min easy between; 5 × 5 min '
          'at Z2 with 1.7 min easy between; 5 × 3.3 min at Z3 with 1.7 min easy '
          'between. Cool-down 10 min.',
      coachingCues:
          'Keep the easy running easy so that the blocks stay controlled.',
      parameterizedFor: 'hr',
      durationMin: 103,
      tss: 80,
      tags: ['z2', 'z3', 'long_finish'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(5, [
          _step('interval', 200, 3),
          _step('recovery', 100, 1),
        ]),
        _repeatBlock(5, [
          _step('interval', 300, 2),
          _step('recovery', 100, 1),
        ]),
        _repeatBlock(5, [
          _step('interval', 200, 3),
          _step('recovery', 100, 1),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Run with Steady Blocks (110 min)',
      description:
          'A long run with steady-hard blocks that train running on tired legs. '
          'Warm-up 15 min. 2 × 15 min at Z2 with 5 min easy between; 2 × 15 min '
          'at Z3 with 5 min easy between. Cool-down 15 min.',
      coachingCues:
          'Keep the easy running easy so that the blocks stay controlled.',
      parameterizedFor: 'hr',
      durationMin: 110,
      tss: 90,
      tags: ['z2', 'z3', 'long_finish'],
      steps: [
        _step('warmup', 900, 1),
        _repeatBlock(2, [
          _step('interval', 900, 2),
          _step('recovery', 300, 2),
        ]),
        _repeatBlock(2, [
          _step('interval', 900, 3),
          _step('recovery', 300, 2),
        ]),
        _step('cooldown', 900, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Run with Threshold Blocks (110 min)',
      description:
          'A long run with steady-hard blocks that train running on tired legs. '
          'Warm-up 10 min. 10 min at Z2; 5 × 10 min at Z4 with 5 min easy '
          'between; 10 min at Z2. Cool-down 5 min.',
      coachingCues:
          'Keep the easy running easy so that the blocks stay controlled.',
      parameterizedFor: 'hr',
      durationMin: 110,
      tss: 112,
      tags: ['z2', 'z4', 'long_finish'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 600, 2),
        _repeatBlock(5, [
          _step('interval', 600, 4),
          _step('recovery', 300, 1),
        ]),
        _step('interval', 600, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build,peak',
      name: 'Long Run (115 min)',
      description:
          'A long steady run that builds endurance and fatigue resistance. Warm- '
          'up 15 min. 1 h 30 min at Z1. Cool-down 10 min.',
      coachingCues:
          'Start easy and keep the effort even; take fluids and fuel on long runs.',
      parameterizedFor: 'hr',
      durationMin: 115,
      tss: 58,
      tags: ['z1', 'long'],
      steps: [
        _step('warmup', 900, 1),
        _step('interval', 5400, 1),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Run (35 min)',
      description:
          'An easy run that adds aerobic volume without stress. Warm-up 5 min. 5 '
          '× 3 min at Z1 with 2 min easy between. Cool-down 5 min.',
      coachingCues:
          'Conversational pace throughout; shorten it if you feel run down.',
      parameterizedFor: 'hr',
      durationMin: 35,
      tss: 18,
      tags: ['z1', 'easy'],
      steps: [
        _step('warmup', 300, 1),
        _repeatBlock(5, [
          _step('interval', 180, 1),
          _step('recovery', 120, 1),
        ]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Run with Strides (41 min)',
      description:
          'An easy run with a few short relaxed accelerations that keep your legs '
          'fast. Warm-up 15 min. 5 × 10 s at Z5 with 3 min easy between. Cool- '
          'down 10 min.',
      coachingCues:
          'Keep the easy running truly easy; the strides are quick and smooth, '
          'not sprints, with full recovery in between.',
      parameterizedFor: 'hr',
      durationMin: 41,
      tss: 22,
      tags: ['z5', 'easy_strides'],
      steps: [
        _step('warmup', 900, 1),
        _repeatBlock(5, [
          _step('interval', 10, 5),
          _step('recovery', 180, 1),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Run (53 min)',
      description:
          'An easy run that adds aerobic volume without stress. 40 min at Z2; 3 '
          'min at Z3; 10 min at Z2.',
      coachingCues:
          'Conversational pace throughout; shorten it if you feel run down.',
      parameterizedFor: 'hr',
      durationMin: 53,
      tss: 44,
      tags: ['z2', 'z3', 'easy'],
      steps: [
        _step('interval', 2400, 2),
        _step('interval', 180, 3),
        _step('interval', 600, 2),
      ],
    ),
  ];

  List<WorkoutTemplatesCompanion> _runningTemplates() => [
    _t(
      sport: 'running',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Recovery Run',
      description: 'Low-intensity aerobic flush. Stay Z1–Z2.',
      coachingCues:
          'Conversational pace. If you can\'t finish a sentence, slow down.',
      parameterizedFor: 'hr',
      durationMin: 40,
      tss: 8,
      tags: ['z1', 'z2', 'recovery', 'aerobic'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 1800, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Short Shakeout',
      description: '30-minute flush run. Legs only — no effort.',
      coachingCues:
          'Zero intensity. HR should stay below 130 bpm the whole run.',
      parameterizedFor: 'hr',
      durationMin: 30,
      tss: 6,
      tags: ['z1', 'recovery', 'shakeout'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 1200, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Recovery Run with Strides',
      description: 'Easy run with 4 × 20s strides at end to keep legs sharp.',
      coachingCues:
          'Easy throughout. Strides are fast but relaxed — not sprints.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 8,
      tags: ['z1', 'z2', 'strides', 'neuromuscular'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2100, 2),
        _repeatBlock(4, [_step('interval', 20, 5), _step('recovery', 90, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Long Aerobic Run',
      description: 'Long Z2 effort. Primary aerobic base builder.',
      coachingCues:
          'First third easy, last third can feel moderate. Fuel every 45 min.',
      parameterizedFor: 'hr',
      durationMin: 90,
      tss: 6,
      tags: ['z2', 'long', 'aerobic_base'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 4200, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Long Run with Progression',
      description: 'Start Z2, finish final 20 min at marathon pace (Z3).',
      coachingCues:
          'Build into it. Last 20 min controlled hard, not race effort.',
      parameterizedFor: 'hr',
      durationMin: 100,
      tss: 8,
      tags: ['z2', 'z3', 'long', 'progression'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 3600, 2),
        _step('interval', 1200, 3),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Run with Race Pace Blocks',
      description: '3 × 10 min at goal race pace within a long Z2 run.',
      coachingCues:
          'Race pace blocks should feel controlled, not desperate. Lock into rhythm.',
      parameterizedFor: 'hr',
      durationMin: 1,
      tss: 8,
      tags: ['z2', 'z4', 'long', 'race_pace'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 1800, 2),
        _repeatBlock(3, [_step('interval', 600, 4), _step('recovery', 300, 2)]),
        _step('interval', 1800, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'hills',
      targetPhase: 'base,build,peak',
      name: 'Hilly Long Run',
      description: 'Long Z2 run on hilly terrain. Power hike steep sections.',
      coachingCues:
          'Run on effort/HR not pace. Hike anything >8% grade to keep HR in Z2.',
      parameterizedFor: 'hr',
      durationMin: 95,
      tss: 8,
      tags: ['z2', 'long', 'hills', 'vert'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 4800, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Threshold Tempo 2×20min',
      description:
          'Two 20-min threshold blocks, 5 min recovery. Classic LT2 driver.',
      coachingCues:
          '"Comfortably hard." Controlled breathing, HR at 88–92% LTHR.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 8,
      tags: ['z4', 'threshold', 'tempo', 'lt2'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(2, [
          _step('interval', 1200, 4),
          _step('recovery', 300, 2),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Cruise Intervals 4×10min',
      description:
          '4 × 10 min at threshold with 2 min jog recovery. High lactate volume.',
      coachingCues:
          'More volume than 2×20 but easier to maintain quality. Each rep should feel same.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 6,
      tags: ['z4', 'threshold', 'cruise_intervals'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 600, 4), _step('recovery', 120, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Tempo Run Continuous',
      description: 'Sustained 30-min tempo at comfortably hard effort.',
      coachingCues: 'No breaks. If you need to stop, you went out too fast.',
      parameterizedFor: 'hr',
      durationMin: 50,
      tss: 6,
      tags: ['z4', 'tempo', 'continuous'],
      steps: [
        _step('warmup', 900, 2),
        _step('interval', 1800, 4),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Marathon Pace Run',
      description: '40 min at goal marathon pace (Z3). Race-specificity work.',
      coachingCues:
          'This should feel controlled and sustainable. You should be able to hold a short conversation.',
      parameterizedFor: 'hr',
      durationMin: 1,
      tss: 6,
      tags: ['z3', 'marathon_pace', 'race_specific'],
      steps: [
        _step('warmup', 600, 2),
        _step('interval', 2400, 3),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'taper',
      name: 'Taper Tempo',
      description:
          '20 min at goal race pace (Z3–Z4). Short, sharp, confidence-building.',
      coachingCues:
          'This should feel easy — you\'re rested. Run relaxed, not forced.',
      parameterizedFor: 'hr',
      durationMin: 1,
      tss: 8,
      tags: ['z4', 'taper', 'race_pace', 'tempo'],
      steps: [
        _step('warmup', 900, 2),
        _step('interval', 1200, 4),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'VO2max 5×5min',
      description: '5 × 5 min hard with 3 min jog recovery.',
      coachingCues: '3–5km race effort. Breathing very hard by rep 3.',
      parameterizedFor: 'hr',
      durationMin: 55,
      tss: 6,
      tags: ['z5', 'vo2max', 'intervals'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(5, [_step('interval', 300, 5), _step('recovery', 180, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Track 6×800m',
      description: '6 × 800m at 5km race pace, 90s jog recovery.',
      coachingCues:
          'Even splits. First 400m should feel easy — the second 400m shows your fitness.',
      parameterizedFor: 'hr',
      durationMin: 50,
      tss: 8,
      tags: ['z5', 'track', 'intervals', '800m'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(6, [_step('interval', 200, 5), _step('recovery', 90, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Short Power 10×400m',
      description: '10 × 400m at mile race pace, 60s recovery.',
      coachingCues:
          'Aggressive but controlled. Think fast turnover, not all-out sprint.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 8,
      tags: ['z6', 'track', 'speed', '400m'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(10, [_step('interval', 90, 6), _step('recovery', 60, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Fartlek 8×1min',
      description: '8 × 1 min surges at 5km effort within an easy run.',
      coachingCues:
          'Surges should feel sharp. Recovery is easy jog — do not stop.',
      parameterizedFor: 'hr',
      durationMin: 50,
      tss: 6,
      tags: ['z5', 'fartlek', 'surges'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(8, [_step('interval', 60, 5), _step('recovery', 120, 2)]),
        _step('interval', 600, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'peak,taper',
      name: 'Race Sharpener 4×1km',
      description: '4 × 1km at 10km race pace with full 3 min recovery.',
      coachingCues:
          'Quality over quantity. Fresh and fast. This is sharpening, not building.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 8,
      tags: ['z5', 'sharpener', 'taper', 'race_pace'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 300, 5), _step('recovery', 180, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'base,build,peak,taper',
      name: 'Hill Sprints 10×10s',
      description:
          '10 × 10s explosive uphill sprints. Pure neuromuscular power.',
      coachingCues:
          'All-out for 10s. Full recovery between reps. Quality not quantity.',
      parameterizedFor: 'hr',
      durationMin: 1,
      tss: 8,
      tags: ['z6', 'hills', 'neuromuscular', 'power'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(10, [_step('interval', 10, 6), _step('recovery', 110, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'base,build,peak',
      name: 'Hill Repeats 6×2min',
      description: '6 × 2 min uphill at Z4–Z5, jog down as recovery.',
      coachingCues: 'Drive knees, short quick steps. Jog down — do not walk.',
      parameterizedFor: 'hr',
      durationMin: 50,
      tss: 6,
      tags: ['z5', 'hills', 'strength_endurance'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(6, [_step('interval', 120, 5), _step('recovery', 150, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'base,build,peak',
      name: 'Hill Repeats 8×90s',
      description: '8 × 90s uphill at Z4–Z5, jog back down.',
      coachingCues:
          'Attack with short quick steps. Walk first descent if needed.',
      parameterizedFor: 'hr',
      durationMin: 55,
      tss: 6,
      tags: ['z5', 'hills', 'strength_endurance'],
      steps: [
        _step('warmup', 1200, 2),
        _repeatBlock(8, [_step('interval', 90, 5), _step('recovery', 120, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'build,peak',
      name: 'Long Hill Repeats 4×4min',
      description: '4 × 4 min sustained uphill at threshold effort.',
      coachingCues:
          'These are long — settle into a rhythm. HR will drift, that\'s fine.',
      parameterizedFor: 'hr',
      durationMin: 55,
      tss: 8,
      tags: ['z4', 'z5', 'hills', 'threshold'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 240, 4), _step('recovery', 180, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'taper',
      name: 'Hill Strides 8×20s',
      description:
          '8 × 20s uphill strides at race effort. Short, sharp, feel fast.',
      coachingCues:
          'Stay relaxed. Full walk recovery. These prime legs, not fatigue them.',
      parameterizedFor: 'hr',
      durationMin: 35,
      tss: 8,
      tags: ['z5', 'hills', 'taper', 'strides'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(8, [_step('interval', 20, 5), _step('recovery', 100, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Fast Finish 15+5min',
      description: '15 min Z2 then 5 min Z3 surge to finish.',
      coachingCues:
          'The finish surge should feel hard but controlled. Not a sprint.',
      parameterizedFor: 'hr',
      durationMin: 30,
      tss: 8,
      tags: ['z2', 'z3', 'fast_finish', 'race_specific'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 900, 2),
        _step('interval', 300, 3),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Fast Finish 30+10min',
      description: '30 min Z2 then 10 min Z3 surge to finish.',
      coachingCues:
          'Hold back in the Z2 block. The finish is where the work happens.',
      parameterizedFor: 'hr',
      durationMin: 50,
      tss: 8,
      tags: ['z2', 'z3', 'fast_finish', 'race_specific'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 1800, 2),
        _step('interval', 600, 3),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Fast Finish 45+12min',
      description: '45 min Z2 then 12 min Z3 surge to finish.',
      coachingCues: 'This is long — pace the Z2 section conservatively.',
      parameterizedFor: 'hr',
      durationMin: 67,
      tss: 8,
      tags: ['z2', 'z3', 'fast_finish', 'race_specific'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2700, 2),
        _step('interval', 720, 3),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Fast Finish 16km+1.6km',
      description: '16 km easy Z2 then 1.6 km Z3 push to finish.',
      coachingCues:
          'The finish kilometre should be noticeably harder. Don\'t go out too fast.',
      parameterizedFor: 'hr',
      durationMin: 1,
      tss: 10,
      tags: ['z2', 'z3', 'long', 'fast_finish', 'race_specific'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 4800, 2),
        _step('interval', 480, 3),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Fast Finish 24km+2.4km',
      description: '24 km easy Z2 then 2.4 km Z3 push to finish.',
      coachingCues:
          'Nutrition on board before the surge. Practice your race-day fueling.',
      parameterizedFor: 'hr',
      durationMin: 140,
      tss: 10,
      tags: ['z2', 'z3', 'long', 'fast_finish', 'race_specific'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 7200, 2),
        _step('interval', 720, 3),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Run with 8 Pickups',
      description: 'Long Z2 run with 8 × (400m Z3 surge + 1.2km Z2 recovery).',
      coachingCues:
          'Surges should feel controlled, not an all-out effort. Return to Z2 fully before next surge.',
      parameterizedFor: 'hr',
      durationMin: 100,
      tss: 10,
      tags: ['z2', 'z3', 'long', 'pickups', 'speed'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(8, [_step('interval', 120, 3), _step('recovery', 360, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Run with 14 Pickups',
      description: 'Long Z2 run with 14 × (400m Z3 surge + 1.2km Z2 recovery).',
      coachingCues:
          'Later reps will feel harder. That\'s the point. Stay patient in the recovery.',
      parameterizedFor: 'hr',
      durationMin: 150,
      tss: 12,
      tags: ['z2', 'z3', 'long', 'pickups', 'speed', 'advanced'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(14, [
          _step('interval', 120, 3),
          _step('recovery', 360, 2),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'taper',
      name: 'Taper Long Run',
      description:
          'Reduced-volume long run. Keep the aerobic feel, protect freshness.',
      coachingCues:
          'Easy Z2. Cut 30–40 % vs peak long run. No heroics — race day is close.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 6,
      tags: ['z2', 'long', 'taper'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 3000, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Anaerobic 4×2.5min',
      description: '4 × 2.5 min Z4 with 5 min Z1 recovery between sets.',
      coachingCues:
          'Z4 here means hard but not all-out. You should still have form.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 6,
      tags: ['z4', 'anaerobic', 'neuromuscular'],
      steps: [
        _step('warmup', 900, 1),
        _repeatBlock(4, [_step('interval', 150, 4), _step('recovery', 300, 1)]),
        _step('cooldown', 900, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Anaerobic 6×2.5min',
      description: '6 × 2.5 min Z4 with 5 min Z1 recovery between sets.',
      coachingCues:
          'Each rep should feel the same. If rep 5 feels easier than rep 1, you went too easy.',
      parameterizedFor: 'hr',
      durationMin: 55,
      tss: 6,
      tags: ['z4', 'anaerobic', 'neuromuscular'],
      steps: [
        _step('warmup', 900, 1),
        _repeatBlock(6, [_step('interval', 150, 4), _step('recovery', 300, 1)]),
        _step('cooldown', 450, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Long Intervals 3×3min Z4',
      description: '3 × 3 min at Z4 with 2 min Z1 recovery.',
      coachingCues:
          'Z4 = threshold effort. Breathing hard but controlled. Not a sprint.',
      parameterizedFor: 'hr',
      durationMin: 30,
      tss: 6,
      tags: ['z4', 'intervals', 'threshold'],
      steps: [
        _step('warmup', 300, 2),
        _repeatBlock(3, [_step('interval', 180, 4), _step('recovery', 120, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Long Intervals 6×3min Z4',
      description: '6 × 3 min at Z4 with 2 min Z1 recovery.',
      coachingCues:
          'Middle reps 3–4 are the hardest. Dig in. Pace yourself — same effort every rep.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 6,
      tags: ['z4', 'intervals', 'threshold'],
      steps: [
        _step('warmup', 300, 2),
        _repeatBlock(6, [_step('interval', 180, 4), _step('recovery', 120, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Long Intervals 5×5min Z4',
      description: '5 × 5 min at Z4 with 3 min Z1 recovery.',
      coachingCues:
          'Longer reps — find a rhythm. HR will drift up through each rep, that\'s normal.',
      parameterizedFor: 'hr',
      durationMin: 55,
      tss: 8,
      tags: ['z4', 'intervals', 'threshold', 'advanced'],
      steps: [
        _step('warmup', 300, 2),
        _repeatBlock(5, [_step('interval', 300, 4), _step('recovery', 180, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Long Intervals 8×5min Z4',
      description: '8 × 5 min at Z4 with 3 min Z1 recovery.',
      coachingCues:
          'High-volume threshold session. Only do this when CTL is high and TSB > -5.',
      parameterizedFor: 'hr',
      durationMin: 75,
      tss: 8,
      tags: ['z4', 'intervals', 'threshold', 'advanced'],
      steps: [
        _step('warmup', 300, 2),
        _repeatBlock(8, [_step('interval', 300, 4), _step('recovery', 180, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Moderate Intervals Z5+Z4 Pyramid',
      description:
          'Z5 opener → Z4 middle → Z3 peak → Z4 → Z5. Multi-system session.',
      coachingCues:
          'Not all-out — each zone has a different feel. Z5 is hard, Z3 block is the recovery.',
      parameterizedFor: 'hr',
      durationMin: 50,
      tss: 10,
      tags: ['z4', 'z5', 'mixed', 'pyramid', 'advanced'],
      steps: [
        _step('warmup', 300, 2),
        _step('interval', 60, 5),
        _step('recovery', 120, 1),
        _step('interval', 180, 4),
        _step('recovery', 120, 1),
        _step('interval', 600, 3),
        _step('recovery', 120, 1),
        _step('interval', 180, 4),
        _step('recovery', 120, 1),
        _step('interval', 60, 5),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'base,build,peak,taper',
      name: 'Speed Strides 6×1min Z4',
      description: 'Z2 base with 6 × 1 min Z4 strides, 2 min recovery each.',
      coachingCues:
          'Strides should feel fast and light. Full recovery before each one.',
      parameterizedFor: 'hr',
      durationMin: 35,
      tss: 8,
      tags: ['z4', 'strides', 'speed', 'neuromuscular'],
      steps: [
        _step('warmup', 300, 1),
        _repeatBlock(6, [_step('interval', 60, 4), _step('recovery', 120, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'base,build,peak',
      name: 'Speed Strides 10×1min Z4',
      description: 'Z2 base with 10 × 1 min Z4 strides, 2 min recovery each.',
      coachingCues: 'Quality over quantity. Stop if form breaks down.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 8,
      tags: ['z4', 'strides', 'speed', 'neuromuscular'],
      steps: [
        _step('warmup', 300, 1),
        _repeatBlock(10, [_step('interval', 60, 4), _step('recovery', 120, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Speed Strides 8×2min Z4',
      description: 'Z2 base with 8 × 2 min Z4 strides, 2 min recovery each.',
      coachingCues:
          'Longer strides — find a rhythm. Don\'t go Z5, stay controlled at Z4.',
      parameterizedFor: 'hr',
      durationMin: 50,
      tss: 8,
      tags: ['z4', 'strides', 'speed', 'neuromuscular'],
      steps: [
        _step('warmup', 300, 1),
        _repeatBlock(8, [_step('interval', 120, 4), _step('recovery', 120, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'trail_running',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Trail Recovery',
      description: 'Easy trail jog. Feel the terrain, no intensity.',
      coachingCues: 'Walk any technical section. HR below 130.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 8,
      tags: ['z1', 'z2', 'trail', 'recovery'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2100, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'trail_running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build,peak',
      name: 'Trail Long Run with Vert',
      description:
          'Long trail run. Heart rate governs pace — hike steep grades.',
      coachingCues:
          'Power hike grades >10%. Run on HR not pace. Practice nutrition.',
      parameterizedFor: 'hr',
      durationMin: 120,
      tss: 8,
      tags: ['z2', 'trail', 'long', 'vert'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 6000, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'trail_running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Back-to-Back Trail Day 1',
      description: 'First day of B2B weekend. Long Z2 trail effort.',
      coachingCues: 'Hold back! Day 2 requires something left in the legs.',
      parameterizedFor: 'hr',
      durationMin: 150,
      tss: 8,
      tags: ['z2', 'trail', 'long', 'b2b'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 7800, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'trail_running',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'build,peak',
      name: 'Hill Repeats 8×90s',
      description: '8 × 90s uphill at Z4–Z5 effort, jog back down as recovery.',
      coachingCues:
          'Attack with short quick steps. Walk the first descent if needed.',
      parameterizedFor: 'hr',
      durationMin: 55,
      tss: 8,
      tags: ['z5', 'hills', 'trail', 'strength_endurance'],
      steps: [
        _step('warmup', 1200, 2),
        _repeatBlock(8, [_step('interval', 90, 5), _step('recovery', 120, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'trail_running',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'build,peak',
      name: 'Vert Block 5×3min Uphill',
      description: '5 × 3 min sustained uphill, walk/jog descent.',
      coachingCues:
          'Use poles if you have them. Focus on consistent uphill effort.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 8,
      tags: ['z4', 'trail', 'hills', 'vert'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(5, [_step('interval', 180, 4), _step('recovery', 180, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'trail_running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Trail Fartlek 6×2min',
      description: '6 × 2 min hard on rolling trail, jog recovery.',
      coachingCues:
          'Pick natural landmarks as targets. Surges on flat or uphill.',
      parameterizedFor: 'hr',
      durationMin: 50,
      tss: 6,
      tags: ['z5', 'trail', 'fartlek'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(6, [_step('interval', 120, 5), _step('recovery', 120, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'trail_running',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'base',
      name: 'Trail Hill Strides 4×60s',
      description: 'Intro hill work. 4 × 60 s Z4 uphill, walk/jog down.',
      coachingCues:
          'Shorten stride, drive knees. Walk recovery — fully reset between reps.',
      parameterizedFor: 'hr',
      durationMin: 40,
      tss: 8,
      tags: ['z4', 'trail', 'hills', 'base'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 60, 4), _step('recovery', 120, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'trail_running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'base',
      name: 'Trail Fartlek 4×2min',
      description: '4 × 2 min moderate effort on rolling trail. Base intro.',
      coachingCues:
          'Comfortable-hard effort, not all-out. Learn to run on technical terrain at pace.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 8,
      tags: ['z4', 'trail', 'fartlek', 'base'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 120, 4), _step('recovery', 120, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'trail_running',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'taper',
      name: 'Taper Trail Long Run',
      description:
          'Reduced-volume long trail run. Keep legs moving, protect freshness.',
      coachingCues:
          'Cut volume 30–40 % vs peak long run. Z2 effort, enjoy the trail.',
      parameterizedFor: 'hr',
      durationMin: 75,
      tss: 8,
      tags: ['z2', 'trail', 'long', 'taper'],
      steps: [
        _step('warmup', 600, 2),
        _step('interval', 3600, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'trail_running',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'taper',
      name: 'Taper Hill Activations 4×60s',
      description: 'Short hill activations to keep legs sharp pre-race.',
      coachingCues:
          'Race effort for 60 s, full walk recovery. Not for fitness — for feel.',
      parameterizedFor: 'hr',
      durationMin: 35,
      tss: 8,
      tags: ['z5', 'trail', 'hills', 'taper'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 60, 5), _step('recovery', 180, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'trail_running',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'taper',
      name: 'Taper Trail Strides 6×30s',
      description: '6 × 30 s race-pace strides on trail. Keep legs sharp.',
      coachingCues:
          'Full recovery between each. These are feel-good efforts, not a workout.',
      parameterizedFor: 'hr',
      durationMin: 35,
      tss: 8,
      tags: ['z5', 'trail', 'strides', 'taper'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(6, [_step('interval', 30, 5), _step('recovery', 90, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
  ];

  List<WorkoutTemplatesCompanion> _cyclingTemplates() => [
    _t(
      sport: 'cycling_road',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Spin',
      description: 'Active recovery ride. Legs only, no strain.',
      coachingCues:
          'High cadence (90+ rpm), zero pressure. If you feel nothing, that\'s correct.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 6,
      tags: ['z1', 'recovery', 'spin'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2100, 1),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Long Aerobic Ride',
      description:
          'Z2 endurance ride. The most important session for aerobic development.',
      coachingCues:
          'Nose breathing if possible. Fuelling from the start — 60–90g carbs/hr.',
      parameterizedFor: 'hr',
      durationMin: 180,
      tss: 6,
      tags: ['z2', 'long', 'aerobic_base'],
      steps: [
        _step('warmup', 900, 2),
        _step('interval', 9000, 2),
        _step('cooldown', 900, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Sweet Spot 3×15min',
      description:
          '3 × 15 min at 88–93% FTP (Z3–Z4). High aerobic yield per hour.',
      coachingCues:
          'Just below threshold — sustainable but not conversational. 5 min recovery between.',
      parameterizedFor: 'power',
      durationMin: 75,
      tss: 8,
      tags: ['z3', 'z4', 'sweet_spot', 'ftp'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(3, [_step('interval', 900, 4), _step('recovery', 300, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'VO2max 4×8min',
      description: '4 × 8 min at 106–120% FTP with 4 min recovery.',
      coachingCues:
          'Sustainable ceiling effort. Pace yourself — should finish all 4 reps.',
      parameterizedFor: 'power',
      durationMin: 70,
      tss: 6,
      tags: ['z5', 'vo2max', 'power'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 480, 5), _step('recovery', 240, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Active Recovery Spin',
      description: '30-min easy spin. Leg flush after a hard day or race.',
      coachingCues:
          'Absolute minimum effort. Soft pedalling, 90+ rpm, zero tension.',
      parameterizedFor: 'hr',
      durationMin: 30,
      tss: 6,
      tags: ['z1', 'recovery', 'flush'],
      steps: [_step('interval', 1800, 1)],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Tempo Ride 2×20min',
      description:
          '2 × 20 min at 76–89% FTP (Z3). Builds lactate clearance and sustained power.',
      coachingCues:
          'Uncomfortable but sustainable. Breathing elevated, not desperate. 5 min easy between.',
      parameterizedFor: 'power',
      durationMin: 65,
      tss: 6,
      tags: ['z3', 'tempo', 'muscular_endurance'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(2, [
          _step('interval', 1200, 3),
          _step('recovery', 300, 2),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Muscular Endurance 3×10min',
      description:
          '3 × 10 min at 76–85% FTP, low cadence 60–70 rpm. Develops leg strength on the bike.',
      coachingCues:
          'Grind it — 65 rpm, stay in the saddle. Simulate climbing. 5 min recovery.',
      parameterizedFor: 'power',
      durationMin: 60,
      tss: 8,
      tags: ['z3', 'muscular_endurance', 'low_cadence', 'base'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(3, [_step('interval', 600, 3), _step('recovery', 300, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Sweet Spot 2×20min',
      description:
          '2 × 20 min at 88–93% FTP. Bigger blocks than 3×15 — more threshold stress.',
      coachingCues:
          'Hold power steady throughout. Second block harder than first — that\'s normal.',
      parameterizedFor: 'power',
      durationMin: 65,
      tss: 8,
      tags: ['z4', 'sweet_spot', 'ftp', 'threshold'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(2, [
          _step('interval', 1200, 4),
          _step('recovery', 300, 2),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Over-Under Intervals 4×8min',
      description:
          '4 × 8 min alternating 1 min over FTP (105%) / 1 min under (94%). Race-specific lactate tolerance.',
      coachingCues:
          'Over = slightly uncomfortable. Under = briefly recover but never stop. Mimics surging in a group.',
      parameterizedFor: 'power',
      durationMin: 70,
      tss: 10,
      tags: ['z4', 'z5', 'over_under', 'threshold', 'race_specific'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [
          _repeatBlock(4, [_step('interval', 60, 5), _step('recovery', 60, 4)]),
          _step('recovery', 300, 2),
        ]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'VO2max 5×5min',
      description:
          '5 × 5 min at 106–120% FTP with 5 min easy recovery. Norwegian-style VO2 block.',
      coachingCues:
          'Go out controlled — rep 1 should feel hard but not maximal. Rep 5 is all-in.',
      parameterizedFor: 'power',
      durationMin: 65,
      tss: 8,
      tags: ['z5', 'vo2max', 'power', 'norwegian'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(5, [_step('interval', 300, 5), _step('recovery', 300, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Anaerobic Repeats 8×1min',
      description:
          '8 × 1 min all-out (130–150% FTP) with 3 min recovery. Neuromuscular power and sprint capacity.',
      coachingCues:
          'Max effort every rep. If you aren\'t gasping by 45 sec, go harder. Full 3 min recovery.',
      parameterizedFor: 'power',
      durationMin: 50,
      tss: 8,
      tags: ['z6', 'anaerobic', 'neuromuscular', 'sprint'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(8, [_step('interval', 60, 6), _step('recovery', 180, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'peak',
      name: 'Climbing Repeats 5×5min',
      description:
          '5 × 5 min sustained climb at 95–105% FTP. Specific for road races with repeated climbs.',
      coachingCues:
          'Simulate a 5 min climb. Seated, 70–80 rpm. Recover fully on descent (easy spin).',
      parameterizedFor: 'power',
      durationMin: 70,
      tss: 8,
      tags: ['z4', 'z5', 'climbing', 'race_specific'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(5, [_step('interval', 300, 4), _step('recovery', 300, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Ride with Sweet Spot Blocks',
      description:
          '3–4 hr Z2 ride with 3 × 10 min sweet spot blocks in the middle. Race simulation.',
      coachingCues:
          'Hold Z2 throughout. Sweet spot blocks at 88–93% FTP — not maximal. Fuel well.',
      parameterizedFor: 'hr',
      durationMin: 210,
      tss: 10,
      tags: ['z2', 'z4', 'long', 'sweet_spot', 'race_sim'],
      steps: [
        _step('warmup', 900, 2),
        _step('interval', 3600, 2),
        _repeatBlock(3, [_step('interval', 600, 4), _step('recovery', 300, 2)]),
        _step('interval', 3600, 2),
        _step('cooldown', 900, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build,peak,taper',
      name: 'Aerobic Base Ride',
      description:
          'Pure Z1–Z2 aerobic base. The bread and butter of cycling fitness.',
      coachingCues:
          'Nose-breathable effort throughout. Fuelling starts at 30 min.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 8,
      tags: ['z1', 'z2', 'aerobic_base', 'endurance'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 2700, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build,peak',
      name: 'Aerobic Base Ride Long',
      description: '2 hr Z2 steady ride. Primary aerobic development session.',
      coachingCues:
          'Consistent Z2 power/HR. HR drift in final 30 min is normal — don\'t chase it.',
      parameterizedFor: 'hr',
      durationMin: 120,
      tss: 8,
      tags: ['z2', 'aerobic_base', 'endurance', 'long'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 6300, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Anaerobic Bursts 4×2.5min in Z2',
      description: '4 × 2.5 min Z4 bursts embedded in a Z2 base ride.',
      coachingCues:
          'Z2 base keeps lactate low between bursts. Each burst should feel very hard.',
      parameterizedFor: 'hr',
      durationMin: 55,
      tss: 8,
      tags: ['z4', 'anaerobic', 'neuromuscular', 'base_ride'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 600, 2),
        _repeatBlock(4, [_step('interval', 150, 4), _step('recovery', 300, 1)]),
        _step('interval', 900, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Anaerobic Bursts 6×2.5min in Z2',
      description: '6 × 2.5 min Z4 bursts in a longer Z2 base ride.',
      coachingCues:
          'More reps — pace the Z2 sections. Full 5 min recovery between bursts.',
      parameterizedFor: 'hr',
      durationMin: 75,
      tss: 8,
      tags: ['z4', 'anaerobic', 'neuromuscular', 'base_ride'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 600, 2),
        _repeatBlock(6, [_step('interval', 150, 4), _step('recovery', 300, 1)]),
        _step('interval', 1800, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'base,build',
      name: 'Cruise Intervals 3×8min Z3',
      description:
          '3 × 8 min Z3 cruise intervals with 3 min Z1 recovery in a Z2 base ride.',
      coachingCues:
          'Z3 = comfortably hard. Controlled breathing. Z2 base before and after.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 6,
      tags: ['z3', 'cruise_intervals', 'tempo'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 600, 2),
        _repeatBlock(3, [_step('interval', 480, 3), _step('recovery', 180, 1)]),
        _step('interval', 1260, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Cruise Intervals 4×10min Z3',
      description:
          '4 × 10 min Z3 cruise intervals with 3 min recovery. High aerobic volume.',
      coachingCues:
          'Longer blocks — settle in. Each block should feel the same.',
      parameterizedFor: 'hr',
      durationMin: 80,
      tss: 8,
      tags: ['z3', 'cruise_intervals', 'tempo', 'threshold'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 900, 2),
        _repeatBlock(4, [_step('interval', 600, 3), _step('recovery', 180, 1)]),
        _step('interval', 600, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Fast Finish Ride 30+15min',
      description: '30 min Z2 then 15 min Z3 surge to finish.',
      coachingCues:
          'Hold back in the Z2 block. The last 15 min is where the training happens.',
      parameterizedFor: 'hr',
      durationMin: 55,
      tss: 8,
      tags: ['z2', 'z3', 'fast_finish', 'race_specific'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 1800, 2),
        _step('interval', 900, 3),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Fast Finish Ride 60+15min',
      description: '60 min Z2 then 15 min Z3 surge to finish.',
      coachingCues:
          'Fuel well in the Z2 block. Push Z3 hard — you\'re nearly done.',
      parameterizedFor: 'hr',
      durationMin: 85,
      tss: 8,
      tags: ['z2', 'z3', 'fast_finish', 'race_specific'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 3600, 2),
        _step('interval', 900, 3),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'base,build,peak,taper',
      name: 'Neuromuscular Openers 10×30s Z5',
      description:
          '10 × 30s Z5 sharp efforts in a Z2 ride. Activates fast-twitch fibres.',
      coachingCues:
          'Short and sharp. Full 2 min Z1 recovery. These prime, not fatigue.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 8,
      tags: ['z5', 'neuromuscular', 'openers', 'fast_twitch'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 300, 2),
        _repeatBlock(10, [_step('interval', 30, 5), _step('recovery', 120, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Mixed Intervals Z3+Z4',
      description:
          'Z3 sustained blocks + Z4 short bursts. Hits threshold and VO2max in one session.',
      coachingCues:
          'Z3 blocks = sustainable hard. Z4 bursts = go. Full Z1 recovery between sets.',
      parameterizedFor: 'hr',
      durationMin: 75,
      tss: 10,
      tags: ['z3', 'z4', 'mixed', 'threshold', 'advanced'],
      steps: [
        _step('warmup', 900, 1),
        _repeatBlock(2, [
          _step('interval', 1200, 3),
          _step('recovery', 900, 1),
        ]),
        _repeatBlock(10, [_step('interval', 60, 4), _step('recovery', 120, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'base,build,peak,taper',
      name: 'Speed Strides 6×2min Z4',
      description: 'Z2 base with 6 × 2 min Z4 strides, 2 min recovery each.',
      coachingCues:
          'Strides should feel fast and controlled. Not sprints — Z4 is threshold-adjacent.',
      parameterizedFor: 'hr',
      durationMin: 40,
      tss: 8,
      tags: ['z4', 'strides', 'speed', 'neuromuscular'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 300, 2),
        _repeatBlock(6, [_step('interval', 120, 4), _step('recovery', 120, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'taper',
      name: 'Pre-Race Openers',
      description:
          '45 min activation with 6 × 20s sharp efforts. Wakes up legs without adding fatigue.',
      coachingCues:
          'The day before your race. Efforts feel sharp and fast. Stop if legs feel heavy.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 8,
      tags: ['taper', 'openers', 'activation', 'pre_race'],
      steps: [
        _step('warmup', 900, 2),
        _step('interval', 600, 2),
        _repeatBlock(6, [_step('interval', 20, 6), _step('recovery', 100, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_road',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'taper',
      name: 'Taper Sharpener 3×5min',
      description:
          '3 × 5 min at threshold. Short but quality — keeps the engine sharp without digging a hole.',
      coachingCues:
          'Same intensity as usual threshold, half the volume. You should feel fast and controlled.',
      parameterizedFor: 'power',
      durationMin: 50,
      tss: 8,
      tags: ['z4', 'taper', 'sharpener', 'threshold'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(3, [_step('interval', 300, 4), _step('recovery', 300, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_gravel',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Gravel Easy Spin',
      description:
          'Easy gravel spin on flat terrain. Recovery between hard days.',
      coachingCues: 'Smooth flat route, no punchy climbs. Z1 the whole time.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 6,
      tags: ['z1', 'gravel', 'recovery'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 3000, 1),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_gravel',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'Gravel Power Surges 6×3min',
      description:
          '6 × 3 min hard surges simulating punchy gravel climbs. 3 min easy between.',
      coachingCues:
          'Attack each rep like a short steep rise. Recover fully on the descent.',
      parameterizedFor: 'power',
      durationMin: 65,
      tss: 8,
      tags: ['z5', 'gravel', 'surges', 'climbing'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(6, [_step('interval', 180, 5), _step('recovery', 180, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_mtb',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'MTB Easy Trail Spin',
      description:
          'Easy trail loop on familiar terrain. No pushing, no technical challenges.',
      coachingCues:
          'Choose your easiest loop. Ride for feel, not fitness. Z1–Z2 only.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 8,
      tags: ['z1', 'z2', 'mtb', 'recovery'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 3000, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'cycling_mtb',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build,peak',
      name: 'MTB Long Trail Ride',
      description:
          'Long trail ride on varied terrain. HR governs — technical features naturally create intensity spikes.',
      coachingCues:
          'Ride to HR not power. Technical sections will spike HR — recover on smoother segments.',
      parameterizedFor: 'hr',
      durationMin: 180,
      tss: 8,
      tags: ['z2', 'mtb', 'long', 'trail'],
      steps: [
        _step('warmup', 600, 2),
        _step('interval', 9600, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_mtb',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'MTB Climb Repeats 4×6min',
      description:
          '4 × 6 min sustained uphill effort at threshold. Find a consistent climb.',
      coachingCues:
          'Seated climbing, 70–75 rpm. Same effort each rep. Descend easy as recovery.',
      parameterizedFor: 'power',
      durationMin: 70,
      tss: 8,
      tags: ['z4', 'mtb', 'climbing', 'threshold'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 360, 4), _step('recovery', 300, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'cycling_gravel',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Gravel Long Ride',
      description:
          'Mixed terrain long ride. HR governs effort — technical sections lower average.',
      coachingCues:
          'Allow HR to drift on climbs. Recover on descents. Treat like trail running.',
      parameterizedFor: 'hr',
      durationMin: 210,
      tss: 6,
      tags: ['z2', 'gravel', 'long'],
      steps: [
        _step('warmup', 900, 2),
        _step('interval', 11400, 2),
        _step('cooldown', 900, 1),
      ],
    ),
    _t(
      sport: 'cycling_mtb',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: 'MTB Short Power Repeats',
      description:
          '8 × 30 sec full-power sprint with 3 min recovery. Neuromuscular.',
      coachingCues:
          'Maximum effort each rep. Full recovery mandatory. Stop if power drops >15%.',
      parameterizedFor: 'power',
      durationMin: 50,
      tss: 8,
      tags: ['z6', 'neuromuscular', 'mtb', 'sprint'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(8, [_step('interval', 30, 6), _step('recovery', 180, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
  ];

  List<WorkoutTemplatesCompanion> _swimmingTemplates() => [
    _t(
      sport: 'swimming',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Swim',
      description: 'Low-intensity continuous swim. Technique focus.',
      coachingCues: 'Long strokes, high elbow catch. Breathe every 3 strokes.',
      parameterizedFor: 'css',
      durationMin: 35,
      tss: 8,
      tags: ['z1', 'z2', 'recovery', 'technique'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 1500, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'swimming',
      sessionType: 'key',
      subType: 'poolSwim',
      targetPhase: 'build,peak',
      name: 'CSS Threshold Set 10×100m',
      description:
          '10 × 100m at Critical Swim Speed with 15 sec rest. Primary CSS driver.',
      coachingCues:
          'Consistent splits every rep. Use a pace clock. Last 2 reps should feel hard.',
      parameterizedFor: 'css',
      durationMin: 45,
      tss: 8,
      tags: ['css', 'threshold', 'pool', 'structured'],
      steps: _zoned([
        _step('warmup', 600, 2),
        _repeatBlock(10, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 100,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 2,
            'stepType': {'stepTypeId': 4, 'stepTypeKey': 'recovery'},
            'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
            'endConditionValue': 15,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
        ]),
        _step('cooldown', 300, 1),
      ], intervals: [4]),
    ),
    _t(
      sport: 'swimming',
      sessionType: 'key',
      subType: 'poolSwim',
      targetPhase: 'base,build',
      name: 'CSS Threshold Set 6×200m',
      description:
          '6 × 200m at CSS with 20 sec rest. Builds aerobic swim capacity.',
      coachingCues:
          'Even pace per 200. Split target into 50m chunks on the pace clock.',
      parameterizedFor: 'css',
      durationMin: 45,
      tss: 6,
      tags: ['css', 'threshold', 'pool'],
      steps: _zoned([
        _step('warmup', 600, 2),
        _repeatBlock(6, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 200,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 2,
            'stepType': {'stepTypeId': 4, 'stepTypeKey': 'recovery'},
            'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
            'endConditionValue': 20,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
        ]),
        _step('cooldown', 300, 1),
      ], intervals: [4]),
    ),
    _t(
      sport: 'swimming',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Aerobic Base Swim 4×500m Z2',
      description: '4 × 500m Z2 with 60s rest. Distance-based aerobic base.',
      coachingCues:
          'Consistent stroke rate. Focus on long, efficient strokes. Rest fully between sets.',
      parameterizedFor: 'css',
      durationMin: 40,
      tss: 8,
      tags: ['z2', 'aerobic_base', 'distance', 'pool'],
      steps: _zoned([
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 1,
          'stepType': {'stepTypeId': 1, 'stepTypeKey': 'warmup'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 250,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        _repeatBlock(4, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 500,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 2,
            'stepType': {'stepTypeId': 4, 'stepTypeKey': 'recovery'},
            'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
            'endConditionValue': 60,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
        ]),
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 6,
          'stepType': {'stepTypeId': 2, 'stepTypeKey': 'cooldown'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 250,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
      ], intervals: [2]),
    ),
    _t(
      sport: 'swimming',
      sessionType: 'long',
      subType: 'poolSwim',
      targetPhase: 'base,build',
      name: 'Long Swim 2000m Z2',
      description:
          'Continuous Z2 swim or broken into 4 × 500m with short rest.',
      coachingCues:
          'Nose-breathing cadence. Long reach, full hip rotation. First km should feel easy.',
      parameterizedFor: 'css',
      durationMin: 45,
      tss: 8,
      tags: ['z2', 'long', 'aerobic_base', 'pool'],
      steps: _zoned([
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 1,
          'stepType': {'stepTypeId': 1, 'stepTypeKey': 'warmup'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 200,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        _repeatBlock(4, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 500,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 2,
            'stepType': {'stepTypeId': 4, 'stepTypeKey': 'recovery'},
            'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
            'endConditionValue': 30,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
        ]),
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 6,
          'stepType': {'stepTypeId': 2, 'stepTypeKey': 'cooldown'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 200,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
      ], intervals: [2]),
    ),
    _t(
      sport: 'swimming',
      sessionType: 'long',
      subType: 'poolSwim',
      targetPhase: 'build,peak',
      name: 'Long Swim 3000m Z2',
      description: '6 × 500m Z2 with 30s rest. Primary aerobic swim volume.',
      coachingCues:
          'Aim for even splits across all 6 reps. If pace drops >5s/100m, take more rest.',
      parameterizedFor: 'css',
      durationMin: 65,
      tss: 8,
      tags: ['z2', 'long', 'aerobic_base', 'pool'],
      steps: _zoned([
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 1,
          'stepType': {'stepTypeId': 1, 'stepTypeKey': 'warmup'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 200,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        _repeatBlock(6, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 500,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 2,
            'stepType': {'stepTypeId': 4, 'stepTypeKey': 'recovery'},
            'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
            'endConditionValue': 30,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
        ]),
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 8,
          'stepType': {'stepTypeId': 2, 'stepTypeKey': 'cooldown'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 200,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
      ], intervals: [2]),
    ),
    _t(
      sport: 'swimming',
      sessionType: 'long',
      subType: 'poolSwim',
      targetPhase: 'taper',
      name: 'Taper Long Swim 1500m',
      description: '3 × 500m easy Z2. Reduced volume, keep water feel.',
      coachingCues:
          'No pushing. Relaxed strokes, focus on technique. This is maintenance.',
      parameterizedFor: 'css',
      durationMin: 35,
      tss: 8,
      tags: ['z2', 'long', 'pool', 'taper'],
      steps: _zoned([
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 1,
          'stepType': {'stepTypeId': 1, 'stepTypeKey': 'warmup'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 200,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        _repeatBlock(3, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 500,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 2,
            'stepType': {'stepTypeId': 4, 'stepTypeKey': 'recovery'},
            'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
            'endConditionValue': 60,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
        ]),
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 5,
          'stepType': {'stepTypeId': 2, 'stepTypeKey': 'cooldown'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 100,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
      ], intervals: [2]),
    ),
    _t(
      sport: 'swimming',
      sessionType: 'key',
      subType: 'poolSwim',
      targetPhase: 'build,peak',
      name: 'Swim Tempo 500m Z3 + Z2',
      description:
          '500m Z3 tempo block followed by 1000m Z2 aerobic. Race-pace specificity.',
      coachingCues:
          'Z3 = comfortably hard. Settle into Z2 for the back half — don\'t stop.',
      parameterizedFor: 'css',
      durationMin: 40,
      tss: 8,
      tags: ['z3', 'tempo', 'pool', 'race_specific'],
      steps: _zoned([
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 1,
          'stepType': {'stepTypeId': 1, 'stepTypeKey': 'warmup'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 250,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 2,
          'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 500,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 3,
          'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 1000,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 4,
          'stepType': {'stepTypeId': 2, 'stepTypeKey': 'cooldown'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 250,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
      ], intervals: [3, 2]),
    ),
    _t(
      sport: 'swimming',
      sessionType: 'key',
      subType: 'poolSwim',
      targetPhase: 'build,peak,taper',
      name: 'Speed Strides 8×50m Z4',
      description:
          'Z2 base with 8 × 50m Z4 strides, 20s rest. Neuromuscular activation.',
      coachingCues:
          'Fast turnover, high elbow. Full recovery between 50s. These sharpen, not fatigue.',
      parameterizedFor: 'css',
      durationMin: 35,
      tss: 10,
      tags: ['z4', 'strides', 'speed', 'neuromuscular', 'pool'],
      steps: _zoned([
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 1,
          'stepType': {'stepTypeId': 1, 'stepTypeKey': 'warmup'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 500,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        _repeatBlock(8, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 50,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 2,
            'stepType': {'stepTypeId': 4, 'stepTypeKey': 'recovery'},
            'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
            'endConditionValue': 20,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
        ]),
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 3,
          'stepType': {'stepTypeId': 2, 'stepTypeKey': 'cooldown'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 500,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
      ], intervals: [4]),
    ),
    _t(
      sport: 'swimming',
      sessionType: 'key',
      subType: 'poolSwim',
      targetPhase: 'build,peak',
      name: 'Short Intervals 8×50m Z5',
      description:
          'Z2 base + 8 × 50m Z5 sprints with 10s rest. VO2max swim speed.',
      coachingCues:
          'All-out on the 50s. 10s rest is short — these hurt. Count strokes per lap.',
      parameterizedFor: 'css',
      durationMin: 40,
      tss: 8,
      tags: ['z5', 'intervals', 'vo2max', 'pool'],
      steps: _zoned([
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 1,
          'stepType': {'stepTypeId': 1, 'stepTypeKey': 'warmup'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 250,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 2,
          'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 500,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        _repeatBlock(8, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 50,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 2,
            'stepType': {'stepTypeId': 4, 'stepTypeKey': 'recovery'},
            'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
            'endConditionValue': 10,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
        ]),
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 4,
          'stepType': {'stepTypeId': 2, 'stepTypeKey': 'cooldown'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 250,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
      ], intervals: [2, 5]),
    ),
    _t(
      sport: 'swimming',
      sessionType: 'key',
      subType: 'poolSwim',
      targetPhase: 'build,peak',
      name: 'Mixed Intervals Z3+Z4',
      description:
          'Z3 cruise set + Z4 speed set. Two energy systems in one session.',
      coachingCues:
          'Z3 100s = CSS effort. Z4 50s = faster than CSS. Rest fully between sets.',
      parameterizedFor: 'css',
      durationMin: 45,
      tss: 8,
      tags: ['z3', 'z4', 'mixed', 'pool'],
      steps: _zoned([
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 1,
          'stepType': {'stepTypeId': 1, 'stepTypeKey': 'warmup'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 500,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        _repeatBlock(5, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 100,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 2,
            'stepType': {'stepTypeId': 4, 'stepTypeKey': 'recovery'},
            'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
            'endConditionValue': 15,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
        ]),
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 3,
          'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 250,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        _repeatBlock(5, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 50,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 2,
            'stepType': {'stepTypeId': 4, 'stepTypeKey': 'recovery'},
            'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
            'endConditionValue': 20,
            'targetType': {
              'workoutTargetTypeId': 1,
              'workoutTargetTypeKey': 'no.target',
            },
          },
        ]),
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 5,
          'stepType': {'stepTypeId': 2, 'stepTypeKey': 'cooldown'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 250,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
      ], intervals: [3, 2, 4]),
    ),
    _t(
      sport: 'swimming',
      sessionType: 'assessment',
      subType: 'poolSwim',
      targetPhase: 'base,build,peak',
      name: 'CSS Test 400m + 200m',
      description:
          'Time trial: 400m all-out, rest 5 min, then 200m all-out. CSS = (400m pace + 200m pace) / 2.',
      coachingCues:
          'Even effort on the 400m — don\'t sprint the first 100m. Log both times to calculate CSS.',
      parameterizedFor: 'css',
      durationMin: 30,
      tss: 8,
      tags: ['css', 'assessment', 'threshold_test', 'pool'],
      steps: _zoned([
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 1,
          'stepType': {'stepTypeId': 1, 'stepTypeKey': 'warmup'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 400,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 2,
          'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 400,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 3,
          'stepType': {'stepTypeId': 4, 'stepTypeKey': 'recovery'},
          'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
          'endConditionValue': 300,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 4,
          'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 200,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
        {
          'type': 'ExecutableStepDTO',
          'stepOrder': 5,
          'stepType': {'stepTypeId': 2, 'stepTypeKey': 'cooldown'},
          'endCondition': {
            'conditionTypeId': 3,
            'conditionTypeKey': 'distance',
          },
          'endConditionValue': 200,
          'targetType': {
            'workoutTargetTypeId': 1,
            'workoutTargetTypeKey': 'no.target',
          },
        },
      ], intervals: [5, 5]),
    ),
    _t(
      sport: 'swimming',
      sessionType: 'long',
      subType: 'openWaterSwim',
      targetPhase: 'base,build,peak',
      name: 'Open Water Endurance',
      description:
          'Open water time+RPE session. No pace targets — conditions vary.',
      coachingCues:
          'RPE 5–6. Sight every 10 strokes. Stay within safe distance of shore or buoys.',
      parameterizedFor: 'rpe',
      durationMin: 50,
      tss: 6,
      tags: ['open_water', 'endurance', 'rpe'],
      steps: [
        _step('warmup', 300, 2),
        _step('interval', 2400, 3),
        _step('cooldown', 300, 1),
      ],
    ),
  ];

  List<WorkoutTemplatesCompanion> _strengthTemplates() => [
    _t(
      sport: 'strength',
      sessionType: 'key',
      subType: 'strengthFull',
      targetPhase: 'base',
      name: 'Full Body Strength — Base',
      description:
          'Compound lifts: squat, deadlift, press, row. 3 sets × 8–10 reps. Base phase volume.',
      coachingCues:
          'Control the eccentric (3 sec down). Rest 90–120 sec between sets. Log weights.',
      parameterizedFor: 'hr',
      durationMin: 55,
      tss: 8,
      tags: ['strength', 'compound', 'full_body', 'base'],
      steps: [
        _step('warmup', 600, 1),
        _repeatBlock(3, [_step('interval', 480, 3), _step('recovery', 120, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'strength',
      sessionType: 'key',
      subType: 'strengthLower',
      targetPhase: 'build,peak',
      name: 'Lower Body Power — Build',
      description:
          'Squat, lunge, RDL, calf raise. 4 sets × 5–6 reps heavy. Strength phase.',
      coachingCues:
          'Heavier than base. Rest 2–3 min between sets. Explosive concentric, controlled eccentric.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 8,
      tags: ['strength', 'lower', 'build', 'power'],
      steps: [
        _step('warmup', 600, 2),
        _repeatBlock(4, [_step('interval', 360, 3), _step('recovery', 150, 1)]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'strength',
      sessionType: 'key',
      subType: 'strengthCore',
      targetPhase: 'base,build,peak,taper',
      name: 'Core & Stability',
      description:
          'Plank, dead bug, bird dog, pallof press. Injury prevention focus.',
      coachingCues:
          'Quality over quantity. Breathe through every rep. Stop if form breaks.',
      parameterizedFor: 'rpe',
      durationMin: 30,
      tss: 6,
      tags: ['core', 'stability', 'injury_prevention'],
      steps: [
        _step('warmup', 300, 1),
        _repeatBlock(3, [_step('interval', 300, 3), _step('recovery', 60, 1)]),
        _step('cooldown', 180, 1),
      ],
    ),
  ];

  List<WorkoutTemplatesCompanion> _yogaTemplates() => [
    _t(
      sport: 'yoga',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper,recovery',
      name: 'Athlete Yoga Flow',
      description:
          'Hip flexors, hamstrings, thoracic mobility. Active recovery.',
      coachingCues:
          'No forcing. Every pose exploratory. Breathe into tight spots.',
      parameterizedFor: 'rpe',
      durationMin: 40,
      tss: 8,
      tags: ['yoga', 'mobility', 'recovery', 'hip_flexor'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2100, 1),
        _step('cooldown', 0, 1),
      ],
    ),
    _t(
      sport: 'stretching',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper,recovery',
      name: 'Post-Run Stretch',
      description:
          '15 min targeted stretch for runners. Calves, quads, hip flexors, hamstrings.',
      coachingCues: 'Hold each stretch 30–45 sec. Do not bounce. Breathe.',
      parameterizedFor: 'rpe',
      durationMin: 15,
      tss: 6,
      tags: ['stretching', 'recovery', 'post_run'],
      steps: [_step('interval', 900, 1)],
    ),
    _t(
      sport: 'pilates',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Pilates Core Activation',
      description:
          'Mat pilates for core stability and spinal mobility. Athlete-specific.',
      coachingCues:
          'Precision and breath control. 100s, roll-up, single leg circles, spine stretch.',
      parameterizedFor: 'rpe',
      durationMin: 45,
      tss: 6,
      tags: ['pilates', 'core', 'recovery'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2400, 2),
        _step('cooldown', 0, 1),
      ],
    ),
  ];

  List<WorkoutTemplatesCompanion> _rowingTemplates() => [
    _t(
      sport: 'indoor_rowing',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Row',
      description:
          'Light aerobic row. Cross-training for runners and cyclists.',
      coachingCues:
          'Legs–body–arms sequence. Ratio 1:2 drive to recovery. Z1–Z2 only.',
      parameterizedFor: 'hr',
      durationMin: 30,
      tss: 6,
      tags: ['z2', 'rowing', 'recovery'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 1200, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'indoor_rowing',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'base',
      name: '4×500m Row Intervals',
      description: '4 × 500m aerobic-threshold row, 2 min rest. Base intro.',
      coachingCues:
          'Controlled Z3–Z4 effort. Focus on stroke mechanics and consistent split.',
      parameterizedFor: 'hr',
      durationMin: 30,
      tss: 10,
      tags: ['z3', 'z4', 'rowing', 'intervals', 'base'],
      steps: [
        _step('warmup', 600, 2),
        _repeatBlock(4, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 500,
            'targetType': {
              'workoutTargetTypeId': 4,
              'workoutTargetTypeKey': 'heart.rate.zone',
            },
            'zoneNumber': 3,
          },
          _step('recovery', 120, 2),
        ]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'indoor_rowing',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'build,peak',
      name: '6×500m Row Intervals',
      description: '6 × 500m at threshold pace with 2 min rest.',
      coachingCues:
          'Split target: threshold 500m pace. Full leg drive. Hold split ±2 sec.',
      parameterizedFor: 'hr',
      durationMin: 40,
      tss: 8,
      tags: ['z4', 'z5', 'rowing', 'intervals'],
      steps: [
        _step('warmup', 600, 2),
        _repeatBlock(6, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 500,
            'targetType': {
              'workoutTargetTypeId': 4,
              'workoutTargetTypeKey': 'heart.rate.zone',
            },
            'zoneNumber': 4,
          },
          _step('recovery', 120, 2),
        ]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'indoor_rowing',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'taper',
      name: 'Taper Row Activations 4×250m',
      description: '4 × 250m at race pace — keeps power without fatigue.',
      coachingCues:
          'Full 3 min recovery. Race-feel effort, not a training block.',
      parameterizedFor: 'hr',
      durationMin: 1,
      tss: 6,
      tags: ['z5', 'rowing', 'taper'],
      steps: [
        _step('warmup', 600, 2),
        _repeatBlock(4, [
          {
            'type': 'ExecutableStepDTO',
            'stepOrder': 1,
            'stepType': {'stepTypeId': 3, 'stepTypeKey': 'interval'},
            'endCondition': {
              'conditionTypeId': 3,
              'conditionTypeKey': 'distance',
            },
            'endConditionValue': 250,
            'targetType': {
              'workoutTargetTypeId': 4,
              'workoutTargetTypeKey': 'heart.rate.zone',
            },
            'zoneNumber': 5,
          },
          _step('recovery', 180, 1),
        ]),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'indoor_rowing',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base',
      name: 'Long Steady Row',
      description: 'Continuous Z2 row. Aerobic foundation for rowers.',
      coachingCues:
          'Maintain stroke rate 18–22 spm. Nose breathing if possible. Fuelling optional for <60 min.',
      parameterizedFor: 'hr',
      durationMin: 40,
      tss: 8,
      tags: ['z2', 'rowing', 'long', 'base'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2100, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'indoor_rowing',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'build,peak',
      name: 'Long Steady Row Extended',
      description:
          'Sustained Z2 row. Primary aerobic builder for indoor rowing.',
      coachingCues:
          'Stroke rate 18–22 spm. Stay aerobic — if HR drifts over Z2, take a 1 min easy.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 6,
      tags: ['z2', 'rowing', 'long'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 3300, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'indoor_rowing',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'taper',
      name: 'Taper Row',
      description: 'Reduced-volume aerobic row. Legs moving, no fatigue.',
      coachingCues:
          'Z1–Z2 only. Cut stroke rate if HR climbs. This is maintenance, not training.',
      parameterizedFor: 'hr',
      durationMin: 30,
      tss: 8,
      tags: ['z2', 'rowing', 'long', 'taper'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 1500, 2),
        _step('cooldown', 300, 1),
      ],
    ),
  ];

  List<WorkoutTemplatesCompanion> _hikingTemplates() => [
    _t(
      sport: 'hiking',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Hike',
      description: 'Gentle Z1–Z2 hike. Active recovery and fresh air.',
      coachingCues:
          'Flat or rolling terrain. Hiking poles optional. Conversational pace throughout.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 8,
      tags: ['z1', 'z2', 'hiking', 'recovery'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 3000, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'hiking',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Long Aerobic Hike',
      description:
          'Multi-hour Z2 hike on trail. Primary aerobic base builder for hikers.',
      coachingCues:
          'Power-hike steep grades, run easy flat sections if comfortable. Fuelling from hour 1.',
      parameterizedFor: 'hr',
      durationMin: 180,
      tss: 8,
      tags: ['z2', 'hiking', 'long', 'aerobic_base'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 9600, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'hiking',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'peak',
      name: 'Peak Long Hike with Vert',
      description:
          'Longest training hike. Sustained Z2 with significant elevation gain.',
      coachingCues:
          'Efficient power-hike technique on climbs. Poles = 10–15 % energy saving. Descend controlled.',
      parameterizedFor: 'hr',
      durationMin: 240,
      tss: 8,
      tags: ['z2', 'hiking', 'long', 'vert'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 13200, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'hiking',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'taper',
      name: 'Taper Long Hike',
      description:
          'Reduced-volume long hike. Keep legs moving, protect freshness.',
      coachingCues: 'Easy Z1–Z2. Cut duration 30–40 % vs peak. No big climbs.',
      parameterizedFor: 'hr',
      durationMin: 90,
      tss: 8,
      tags: ['z2', 'hiking', 'long', 'taper'],
      steps: [
        _step('warmup', 600, 1),
        _step('interval', 4800, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'hiking',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'base,build',
      name: 'Uphill Power-Hike Intervals 4×10min',
      description:
          '4 × 10 min sustained uphill power-hike at Z3–Z4 with easy descent recovery.',
      coachingCues:
          'Lean forward, short steps, drive with poles. Descent is recovery — don\'t rush.',
      parameterizedFor: 'hr',
      durationMin: 75,
      tss: 8,
      tags: ['z4', 'hiking', 'hills', 'power_hike'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 600, 4), _step('recovery', 300, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'hiking',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'peak',
      name: 'Uphill Power-Hike Intervals 6×10min',
      description:
          '6 × 10 min Z4 uphill power-hike blocks. Race-specific strength.',
      coachingCues:
          'Consistent effort across all reps. Trekking poles mandatory. Fuelling mid-session.',
      parameterizedFor: 'hr',
      durationMin: 100,
      tss: 8,
      tags: ['z4', 'hiking', 'hills', 'power_hike'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(6, [_step('interval', 600, 4), _step('recovery', 300, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'hiking',
      sessionType: 'key',
      subType: 'hills',
      targetPhase: 'taper',
      name: 'Taper Uphill Activations 3×5min',
      description:
          'Short uphill activations. Keeps legs sharp without fatigue.',
      coachingCues:
          'Race-effort power-hike for 5 min. Full walk recovery. Confidence session.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 8,
      tags: ['z4', 'hiking', 'hills', 'taper'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(3, [_step('interval', 300, 4), _step('recovery', 300, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
  ];

  List<WorkoutTemplatesCompanion> _inlineSkatingTemplates() => [
    _t(
      sport: 'inline_skating',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Skate',
      description: 'Z1–Z2 recovery skate. Smooth, relaxed glide.',
      coachingCues:
          'Long strokes, no pushing hard. If you feel resistance, back off.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 6,
      tags: ['z2', 'inline', 'recovery'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2100, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'inline_skating',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Long Aerobic Skate',
      description:
          'Z2 endurance skate. Builds aerobic base and skating economy.',
      coachingCues:
          'Maintain consistent push-off. Arms relaxed, core engaged. Fuel after 45 min.',
      parameterizedFor: 'hr',
      durationMin: 90,
      tss: 8,
      tags: ['z2', 'inline', 'long', 'aerobic_base'],
      steps: [
        _step('warmup', 600, 2),
        _step('interval', 4800, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'inline_skating',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'peak',
      name: 'Long Skate with Tempo Finish',
      description: 'Z2 long skate with 15 min Z3 tempo finish.',
      coachingCues:
          'Save something for the finish. Lock into race rhythm over the last 15 min.',
      parameterizedFor: 'hr',
      durationMin: 105,
      tss: 10,
      tags: ['z2', 'z3', 'inline', 'long', 'tempo'],
      steps: [
        _step('warmup', 600, 2),
        _step('interval', 4800, 2),
        _step('interval', 900, 3),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'inline_skating',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'taper',
      name: 'Taper Skate',
      description: 'Short easy skate. Feel the glide, no strain.',
      coachingCues: 'Z1–Z2 only. This is for legs and feel, not fitness.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 8,
      tags: ['z2', 'inline', 'long', 'taper'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2100, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'inline_skating',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'base,build',
      name: 'Skate Intervals 6×2min',
      description: '6 × 2 min Z4 efforts with 2 min easy glide recovery.',
      coachingCues:
          'Full leg extension each stroke. Keep upper body quiet during intervals.',
      parameterizedFor: 'hr',
      durationMin: 50,
      tss: 6,
      tags: ['z4', 'inline', 'intervals'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(6, [_step('interval', 120, 4), _step('recovery', 120, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'inline_skating',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'peak',
      name: 'Skate Intervals 8×2min',
      description: '8 × 2 min Z4 with 90s recovery. Build anaerobic capacity.',
      coachingCues:
          'Consistent splits across all 8 reps. If you fade on rep 6+, rest longer.',
      parameterizedFor: 'hr',
      durationMin: 55,
      tss: 6,
      tags: ['z4', 'inline', 'intervals'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(8, [_step('interval', 120, 4), _step('recovery', 90, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'inline_skating',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'taper',
      name: 'Taper Skate Strides 4×1min',
      description: '4 × 1 min race-pace strides. Legs stay sharp.',
      coachingCues: 'Full recovery between each. Fast but not frantic.',
      parameterizedFor: 'hr',
      durationMin: 35,
      tss: 8,
      tags: ['z5', 'inline', 'strides', 'taper'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 60, 5), _step('recovery', 180, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'inline_skating',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Skate Tempo',
      description: '20 min sustained Z3 skating. Threshold aerobic work.',
      coachingCues:
          'Comfortably hard — controlled breathing. Maintain stroke frequency, not speed.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 6,
      tags: ['z3', 'inline', 'tempo'],
      steps: [
        _step('warmup', 900, 2),
        _step('interval', 1200, 3),
        _step('cooldown', 600, 1),
      ],
    ),
  ];

  List<WorkoutTemplatesCompanion> _nordicSkiingTemplates() => [
    _t(
      sport: 'nordic_skiing',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Nordic Ski',
      description: 'Z1–Z2 recovery ski. Technique focus, no intensity.',
      coachingCues:
          'Diagonal stride, easy tempo. Full glide phase — let the ski carry you. No pole rush.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 6,
      tags: ['z2', 'nordic', 'recovery'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2100, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'nordic_skiing',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Long Nordic Ski',
      description: 'Z2 distance ski. Core aerobic session for cross-country.',
      coachingCues:
          'Maintain diagonal stride efficiency. Fuel every 30–45 min. Stay in Z2 on climbs.',
      parameterizedFor: 'hr',
      durationMin: 120,
      tss: 8,
      tags: ['z2', 'nordic', 'long', 'aerobic_base'],
      steps: [
        _step('warmup', 600, 2),
        _step('interval', 6600, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'nordic_skiing',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'peak',
      name: 'Long Nordic Ski with Surges',
      description: 'Z2 long ski with 6 × 3 min Z4 uphill surges embedded.',
      coachingCues:
          'Attack climbs at Z4, recover on flats back to Z2. Race simulation.',
      parameterizedFor: 'hr',
      durationMin: 135,
      tss: 10,
      tags: ['z2', 'z4', 'nordic', 'long', 'surges'],
      steps: [
        _step('warmup', 600, 2),
        _step('interval', 2400, 2),
        _repeatBlock(6, [_step('interval', 180, 4), _step('recovery', 300, 2)]),
        _step('interval', 1800, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'nordic_skiing',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'taper',
      name: 'Taper Nordic Ski',
      description: 'Short easy ski. Maintain feel on snow without fatigue.',
      coachingCues: 'Z2 max. Focus on glide and technique — not distance.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 8,
      tags: ['z2', 'nordic', 'long', 'taper'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 3300, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'nordic_skiing',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'base,build',
      name: 'Nordic Uphill Intervals 6×3min',
      description: '6 × 3 min Z4 uphill diagonal stride, ski down recovery.',
      coachingCues:
          'Drive knees high on climbs. Poling power from core, not shoulders.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 8,
      tags: ['z4', 'nordic', 'intervals', 'uphill'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(6, [_step('interval', 180, 4), _step('recovery', 180, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'nordic_skiing',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'peak',
      name: 'Nordic Intervals 8×3min',
      description: '8 × 3 min Z4–Z5 on hilly course. VO2max stimulus.',
      coachingCues: 'Last 2 reps should feel hard. If form breaks, stop.',
      parameterizedFor: 'hr',
      durationMin: 70,
      tss: 8,
      tags: ['z4', 'z5', 'nordic', 'intervals'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(8, [_step('interval', 180, 5), _step('recovery', 180, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'nordic_skiing',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'taper',
      name: 'Taper Nordic Strides 4×1min',
      description: '4 × 1 min race-pace efforts. Keeps speed sharp.',
      coachingCues: 'Full recovery between each. Focus on technique at speed.',
      parameterizedFor: 'hr',
      durationMin: 35,
      tss: 8,
      tags: ['z5', 'nordic', 'strides', 'taper'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 60, 5), _step('recovery', 180, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'nordic_skiing',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Nordic Tempo',
      description: '20 min continuous Z3 ski. Lactate threshold work.',
      coachingCues:
          'Comfortably hard. Breathing rhythmically with the poling cycle.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 6,
      tags: ['z3', 'nordic', 'tempo'],
      steps: [
        _step('warmup', 900, 2),
        _step('interval', 1200, 3),
        _step('cooldown', 600, 1),
      ],
    ),
  ];

  List<WorkoutTemplatesCompanion> _skateSkiingTemplates() => [
    _t(
      sport: 'skate_skiing',
      sessionType: 'recovery',
      targetPhase: 'base,build,peak,taper',
      name: 'Easy Skate Ski',
      description:
          'Z1–Z2 recovery skate ski. Technique and glide, no intensity.',
      coachingCues:
          'V2 alternate on flats. Slow cadence — full weight transfer each stroke. No V1 on climbs.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 6,
      tags: ['z2', 'skate_ski', 'recovery'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2100, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'skate_skiing',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'base,build',
      name: 'Long Skate Ski Z2',
      description:
          'Z2 endurance skate ski. Builds aerobic base and skating efficiency.',
      coachingCues:
          'Maintain V2 alternate on flats, V1 on climbs. HR stays in Z2 — walk climbs if needed.',
      parameterizedFor: 'hr',
      durationMin: 90,
      tss: 8,
      tags: ['z2', 'skate_ski', 'long', 'aerobic_base'],
      steps: [
        _step('warmup', 600, 2),
        _step('interval', 4800, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'skate_skiing',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'peak',
      name: 'Long Skate Ski with Surges',
      description: 'Z2 long skate ski with 6 × 3 min Z4 uphill surges.',
      coachingCues:
          'Attack climbs with V1 at race effort, recover on flats back to Z2.',
      parameterizedFor: 'hr',
      durationMin: 120,
      tss: 10,
      tags: ['z2', 'z4', 'skate_ski', 'long', 'surges'],
      steps: [
        _step('warmup', 600, 2),
        _step('interval', 2400, 2),
        _repeatBlock(6, [_step('interval', 180, 4), _step('recovery', 300, 2)]),
        _step('interval', 1800, 2),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'skate_skiing',
      sessionType: 'long',
      subType: 'endurance',
      targetPhase: 'taper',
      name: 'Taper Skate Ski',
      description:
          'Short easy skate ski. Maintain feel on snow, protect freshness.',
      coachingCues:
          'Z2 max. Focus on glide and technique — not distance or pace.',
      parameterizedFor: 'hr',
      durationMin: 50,
      tss: 8,
      tags: ['z2', 'skate_ski', 'long', 'taper'],
      steps: [
        _step('warmup', 300, 1),
        _step('interval', 2700, 2),
        _step('cooldown', 300, 1),
      ],
    ),
    _t(
      sport: 'skate_skiing',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'base,build',
      name: 'Skate Ski Intervals 6×3min',
      description: '6 × 3 min Z4 uphill V1 skate, glide back down as recovery.',
      coachingCues:
          'Drive off each skate — full extension. Pole plant = power, not balance.',
      parameterizedFor: 'hr',
      durationMin: 60,
      tss: 8,
      tags: ['z4', 'skate_ski', 'intervals', 'uphill'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(6, [_step('interval', 180, 4), _step('recovery', 180, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'skate_skiing',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'peak',
      name: 'Skate Ski Intervals 8×3min',
      description:
          '8 × 3 min Z4–Z5 on course. High aerobic and anaerobic stimulus.',
      coachingCues:
          'Last 2 reps should feel hard. If technique collapses, stop the rep.',
      parameterizedFor: 'hr',
      durationMin: 70,
      tss: 8,
      tags: ['z4', 'z5', 'skate_ski', 'intervals'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(8, [_step('interval', 180, 5), _step('recovery', 180, 2)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'skate_skiing',
      sessionType: 'key',
      subType: 'intervals',
      targetPhase: 'taper',
      name: 'Taper Skate Strides 4×1min',
      description: '4 × 1 min race-pace skate efforts. Legs stay sharp.',
      coachingCues:
          'Full recovery between each. Fast and crisp — not a workout, a reminder.',
      parameterizedFor: 'hr',
      durationMin: 35,
      tss: 8,
      tags: ['z5', 'skate_ski', 'strides', 'taper'],
      steps: [
        _step('warmup', 900, 2),
        _repeatBlock(4, [_step('interval', 60, 5), _step('recovery', 180, 1)]),
        _step('cooldown', 600, 1),
      ],
    ),
    _t(
      sport: 'skate_skiing',
      sessionType: 'key',
      subType: 'tempo',
      targetPhase: 'build,peak',
      name: 'Skate Ski Tempo',
      description: '20 min sustained Z3 skate skiing. Lactate threshold work.',
      coachingCues:
          'Comfortably hard. V2 alternate with steady cadence. Breathing matches pole cycle.',
      parameterizedFor: 'hr',
      durationMin: 45,
      tss: 6,
      tags: ['z3', 'skate_ski', 'tempo'],
      steps: [
        _step('warmup', 900, 2),
        _step('interval', 1200, 3),
        _step('cooldown', 600, 1),
      ],
    ),
  ];
}
