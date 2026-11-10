import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../models/strength_workout.dart';
import 'missed_workout_planner.dart'
    show SessionWeight, hasIndoorAlternative, weightOf;
import 'strength/strength_repository.dart';
import 'workout_semantics.dart';

/// FjeliaPro's morning revision: when the readiness check asks for a change,
/// the coach reworks today's session itself (its steps, or the sets of a
/// strength session) or swaps it with a session of this week. The rules
/// check every answer against the plan and Settings → Training; nothing is
/// sent to a watch, the athlete does that.

/// One step of an endurance session as the coach writes it.
class RevisionStep {
  const RevisionStep({
    required this.type,
    required this.minutes,
    required this.zone,
  });
  final String type;
  final double minutes;
  final int zone;
}

/// A step or a repeated group of steps.
class RevisionItem {
  const RevisionItem.step(RevisionStep this.step)
    : repeat = 1,
      steps = const [];
  const RevisionItem.repeat(this.repeat, this.steps) : step = null;
  final RevisionStep? step;
  final int repeat;
  final List<RevisionStep> steps;
}

/// A strength exercise afterwards: fewer working sets, fewer repetitions,
/// a lighter load, or left out.
class RevisionExercise {
  const RevisionExercise({
    required this.id,
    this.sets,
    this.reps,
    this.loadPercent,
    this.drop = false,
  });
  final String id;
  final int? sets, reps, loadPercent;
  final bool drop;
}

enum RevisionOp { revise, swap, rest, keep }

class RevisionChange {
  const RevisionChange({
    required this.op,
    required this.sessionId,
    this.withId,
    this.steps,
    this.exercises,
    this.why,
    this.indoor,
  });
  final RevisionOp op;
  final String sessionId;

  /// Do it indoors (treadmill, trainer) instead, e.g. for the weather.
  final bool? indoor;

  /// The coach's reason for this session, one short sentence.
  final String? why;

  /// The session of this week a swap trades days with.
  final String? withId;

  /// New steps of an endurance session.
  final List<RevisionItem>? steps;

  /// New targets of a strength session's exercises.
  final List<RevisionExercise>? exercises;
}

/// The coach's whole answer: the push and the changes.
class MorningRevision {
  const MorningRevision({
    required this.title,
    required this.body,
    required this.changes,
    this.alternative,
  });
  final String title, body;
  final List<RevisionChange> changes;

  /// A second way the coach offers, usually a swap within the week; the
  /// athlete picks one of the two.
  final MorningRevision? alternative;

  MorningRevision withoutAlternative() =>
      MorningRevision(title: title, body: body, changes: changes);
}

/// Today's sessions, the rest of the week and the athlete's training
/// settings: what the coach may work with.
class RevisionContext {
  RevisionContext({
    required this.day,
    required this.week,
    required this.restWeekdays,
    required this.strengthWeekdays,
    required this.maxPerDay,
    this.strengthPlans = const {},
    this.readinessLevel = 'yellow',
    this.reason = '',
    this.races = const [],
    this.weather = const {},
    this.hoursPerWeek,
    this.trainingDaysPerWeek,
    this.onWatch = const {},
    this.feeling,
    DateTime? today,
  }) : realToday = today ?? DateTime.now();

  /// Race goals from [day] on: date, priority (A/B/C) and sport; names stay
  /// out of the context.
  final List<({DateTime date, String priority, String sport})> races;

  /// The forecast by day (midnight): rain from 7 to 20 h, the day's high.
  final Map<DateTime, ({bool rain, double? maxC})> weather;

  /// Settings → Training: the weekly time and the training days.
  final double? hoursPerWeek;
  final int? trainingDaysPerWeek;

  /// Sessions already on a watch or platform: changed, they need sending
  /// again.
  final Set<String> onWatch;

  /// What the athlete says about today (good, tired, sore, ill, short on
  /// time); null when not said.
  final String? feeling;

  final DateTime day;

  /// The calendar's today; [day] is a later one only in the debug test.
  final DateTime realToday;

  /// Every planned session from the week's first to its last day.
  final List<TrainingSession> week;
  final List<int> restWeekdays, strengthWeekdays;
  final int maxPerDay;

  /// The strength plan of each strength session of today, by session id.
  final Map<String, StoredStrengthPlan> strengthPlans;
  final String readinessLevel, reason;

  List<TrainingSession> get today => [
    for (final s in week)
      if (_sameDay(s.sessionDate, day) && _open(s)) s,
  ];

  /// The day after [day]: the coach may rework it too.
  DateTime get nextDay => DateTime(day.year, day.month, day.day + 1);

  List<TrainingSession> get next => [
    for (final s in week)
      if (_sameDay(s.sessionDate, nextDay) && _open(s)) s,
  ];

  /// The sessions the coach may change: the day's and the next day's.
  List<TrainingSession> get focus => [...today, ...next];

  TrainingSession? byId(String id) {
    for (final s in week) {
      if (s.id == id) return s;
    }
    return null;
  }
}

bool _open(TrainingSession s) =>
    const {'planned', 'adapted'}.contains(s.status);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _date(DateTime d) =>
    DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

bool isStrengthSession(TrainingSession s) => isStrengthSport(s.sport);

/// The question for the coach as compact JSON; history, health and goals go
/// in the usual context.
String revisionInputJson(RevisionContext c) {
  List<Object> stepsOf(TrainingSession s) {
    final raw = s.stepsJson;
    if (raw == null) return const [];
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    final items = decoded is Map
        ? decoded['workoutSteps'] ?? decoded['steps']
        : decoded;
    if (items is! List) return const [];
    Object? one(Object? i) {
      if (i is! Map) return null;
      if (i['workoutSteps'] is List) {
        return {
          'repeat': i['numberOfIterations'] ?? 1,
          'steps': [for (final c in i['workoutSteps'] as List) ?one(c)],
        };
      }
      final type = (i['stepType'] as Map?)?['stepTypeKey'] ?? 'interval';
      final seconds = (i['endConditionValue'] as num?)?.toDouble();
      return {
        'type': type,
        if (seconds != null) 'min': (seconds / 60 * 10).round() / 10,
        if (i['zoneNumber'] != null) 'zone': i['zoneNumber'],
      };
    }

    return [for (final i in items) ?one(i)];
  }

  Map<String, Object?> session(TrainingSession s, {bool detail = false}) => {
    'id': s.id,
    'date': _date(s.sessionDate),
    'sport': s.sport,
    'type': s.sessionType,
    'zone': s.primaryZone,
    'min': s.plannedDurationMin,
    'hard': weightOf(s) == SessionWeight.hard,
    'phase': s.phase,
    if (s.status == 'adapted') 'status': 'adapted',
    if (s.locked) 'locked': true,
    if (s.indoor) 'indoor': true,
    if (hasIndoorAlternative(s)) 'can_go_indoor': true,
    'title': s.title,
    if (detail && !isStrengthSession(s)) 'steps': stepsOf(s),
    if (detail && isStrengthSession(s))
      'exercises': [
        for (final b in c.strengthPlans[s.id]?.plan.blocks ?? const [])
          for (final e in b.exercises)
            {
              'id': e.id,
              'name': e.name,
              'equipment': e.equipment,
              'working_sets': e.sets
                  .where((x) => x.kind != StrengthSetKind.warmup)
                  .length,
              'reps': ?_reps(e),
              'kg': ?_load(e),
            },
      ],
  };

  return jsonEncode({
    'day': _date(c.day),
    'today': _date(c.realToday),
    'day_is_today': _sameDay(c.day, c.realToday),
    'readiness': c.readinessLevel,
    if (c.reason.isNotEmpty) 'reason': c.reason,
    'day_sessions': [for (final s in c.today) session(s, detail: true)],
    'next_day': _date(c.nextDay),
    'next_day_sessions': [for (final s in c.next) session(s, detail: true)],
    'week': [
      for (final s in c.week)
        if (_open(s) && s.sessionDate.isAfter(c.nextDay)) session(s),
    ],
    if (c.feeling != null) 'athlete_says': c.feeling,
    if (c.races.isNotEmpty)
      'races': [
        for (final r in c.races.take(4))
          {
            'date': _date(r.date),
            'priority': r.priority,
            'sport': r.sport,
            'days_from_day': DateTime(
              r.date.year,
              r.date.month,
              r.date.day,
            ).difference(c.day).inDays,
          },
      ],
    if (c.weather.isNotEmpty)
      'weather': [
        for (final e in c.weather.entries)
          if (!e.key.isBefore(c.day))
            {
              'date': _date(e.key),
              'rain': e.value.rain,
              if (e.value.maxC != null) 'max_c': e.value.maxC!.round(),
            },
      ],
    'settings': {
      'rest_weekdays': c.restWeekdays,
      'strength_weekdays': c.strengthWeekdays,
      'max_sessions_per_day': c.maxPerDay,
      if (c.hoursPerWeek != null) 'hours_per_week': c.hoursPerWeek,
      if (c.trainingDaysPerWeek != null)
        'training_days_per_week': c.trainingDaysPerWeek,
    },
  });
}

int? _reps(StrengthPlannedExercise e) {
  for (final s in e.sets) {
    if (s.kind == StrengthSetKind.warmup) continue;
    return s.reps ?? s.repMax;
  }
  return null;
}

double? _load(StrengthPlannedExercise e) {
  for (final s in e.sets) {
    if (s.kind == StrengthSetKind.warmup) continue;
    return s.load?.kg;
  }
  return null;
}

/// Reads the coach's answer; null when it is not the expected JSON. An
/// alternative that cannot be read is left out.
MorningRevision? parseMorningRevision(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    final j = jsonDecode(raw.substring(start, end + 1));
    if (j is! Map || j['version'] != 1) return null;
    final main = _revisionOf(j);
    if (main == null) return null;
    final alt = j['alternative'] is Map
        ? _revisionOf(j['alternative'] as Map)
        : null;
    return MorningRevision(
      title: main.title,
      body: main.body,
      changes: main.changes,
      alternative: alt,
    );
  } catch (_) {
    return null;
  }
}

MorningRevision? _revisionOf(Map j) {
  if (j['changes'] is! List) return null;
  final title = '${j['title'] ?? ''}'.trim();
  final body = '${j['body'] ?? ''}'.trim();
  if (title.isEmpty || title.length > 60 || body.length > 240) return null;
  RevisionStep? step(Object? s) {
    if (s is! Map) return null;
    final min = s['min'], zone = s['zone'];
    if (min is! num || zone is! num) return null;
    return RevisionStep(
      type: '${s['type'] ?? 'interval'}',
      minutes: min.toDouble(),
      zone: zone.round(),
    );
  }

  final changes = <RevisionChange>[];
  for (final c in j['changes'] as List) {
    if (c is! Map || c['session'] is! String) return null;
    final id = c['session'] as String;
    final whyRaw = '${c['why'] ?? ''}'.trim();
    final why = whyRaw.isEmpty
        ? null
        : whyRaw.length > 160
        ? '${whyRaw.substring(0, 157)}…'
        : whyRaw;
    switch (c['op']) {
      case 'keep':
        changes.add(
          RevisionChange(op: RevisionOp.keep, sessionId: id, why: why),
        );
      case 'rest':
        changes.add(
          RevisionChange(op: RevisionOp.rest, sessionId: id, why: why),
        );
      case 'swap':
        if (c['with'] is! String) return null;
        changes.add(
          RevisionChange(
            op: RevisionOp.swap,
            sessionId: id,
            withId: c['with'] as String,
            why: why,
            indoor: c['indoor'] is bool ? c['indoor'] as bool : null,
          ),
        );
      case 'revise':
        final items = <RevisionItem>[];
        for (final s in (c['steps'] as List? ?? const [])) {
          if (s is Map && s['repeat'] is num && s['steps'] is List) {
            final inner = [for (final x in s['steps'] as List) step(x)];
            if (inner.contains(null) || inner.isEmpty) return null;
            items.add(
              RevisionItem.repeat(
                (s['repeat'] as num).round(),
                inner.cast<RevisionStep>(),
              ),
            );
          } else {
            final one = step(s);
            if (one == null) return null;
            items.add(RevisionItem.step(one));
          }
        }
        final exercises = <RevisionExercise>[];
        for (final e in (c['exercises'] as List? ?? const [])) {
          if (e is! Map || e['id'] is! String) return null;
          int? whole(Object? v) => v is num ? v.round() : null;
          exercises.add(
            RevisionExercise(
              id: e['id'] as String,
              sets: whole(e['sets']),
              reps: whole(e['reps']),
              loadPercent: whole(e['load_pct']),
              drop: e['drop'] == true,
            ),
          );
        }
        final indoor = c['indoor'] is bool ? c['indoor'] as bool : null;
        if (items.isEmpty && exercises.isEmpty && indoor != true) return null;
        changes.add(
          RevisionChange(
            op: RevisionOp.revise,
            sessionId: id,
            steps: items.isEmpty ? null : items,
            exercises: exercises.isEmpty ? null : exercises,
            why: why,
            indoor: indoor,
          ),
        );
      default:
        return null;
    }
  }
  return MorningRevision(title: title, body: body, changes: changes);
}

/// Whether [ch] changes too little to bother the athlete: an endurance
/// session less than 5 % shorter with no lower zone, or strength targets
/// that only lose a few percent of the load. Such a change counts as keep.
bool _tooSmall(RevisionChange ch, RevisionContext c) {
  if (ch.op != RevisionOp.revise || (ch.indoor ?? false)) return false;
  final s = c.byId(ch.sessionId);
  if (s == null) return false;
  if (ch.steps != null) {
    final before = WorkoutSemantics.of(s.stepsJson, sport: s.sport);
    final after = WorkoutSemantics.of(
      revisionStepsJson(ch.steps!),
      sport: s.sport,
    );
    final planned = before.isEmpty
        ? s.plannedDurationMin * 60.0
        : before.totalSeconds;
    if (planned <= 0) return false;
    final shorter = (planned - after.totalSeconds) / planned;
    final planZone = before.isEmpty ? s.primaryZone : _maxZone(before);
    final easier = _maxZone(after) < planZone;
    return shorter < .05 && !easier;
  }
  if (ch.exercises != null) {
    return ch.exercises!.every(
      (e) =>
          !e.drop &&
          e.sets == null &&
          e.reps == null &&
          (e.loadPercent == null || e.loadPercent! >= 95),
    );
  }
  return false;
}

/// [r] as it may be shown: null when its own changes fail a check (see
/// [revisionProblem]), without the alternative when only that one fails.
MorningRevision? checkedRevision(
  MorningRevision raw,
  RevisionContext c, {
  void Function(String problem)? log,
}) {
  // "Keep" changes nothing: one about a session that is not the day's (done
  // already, another day) is left out instead of failing the answer.
  MorningRevision pruned(MorningRevision x) {
    final day = {for (final s in c.focus) s.id};
    final kept = [
      for (final ch in x.changes)
        if (ch.op != RevisionOp.keep || day.contains(ch.sessionId))
          _tooSmall(ch, c)
              ? RevisionChange(
                  op: RevisionOp.keep,
                  sessionId: ch.sessionId,
                  why: ch.why,
                )
              : ch,
    ];
    return MorningRevision(
      title: x.title,
      body: x.body,
      changes: kept,
      alternative: x.alternative == null ? null : pruned(x.alternative!),
    );
  }

  final r = pruned(raw);
  final problem = revisionProblem(r, c);
  if (problem != null) {
    log?.call(problem);
    final alt = r.alternative;
    if (alt != null && revisionProblem(alt, c) == null) {
      log?.call('main refused, the alternative is shown');
      return alt;
    }
    return null;
  }
  final alt = r.alternative;
  if (alt == null) return r;
  final altProblem = revisionProblem(alt, c);
  if (altProblem == null) return r;
  log?.call('alternative: $altProblem');
  return r.withoutAlternative();
}

/// The coach's steps as stored workout steps.
String revisionStepsJson(List<RevisionItem> items) {
  Map<String, Object?> one(RevisionStep s) => {
    'type': 'ExecutableStepDTO',
    'stepType': {'stepTypeKey': s.type},
    'endCondition': {'conditionTypeKey': 'time'},
    'endConditionValue': (s.minutes * 60).round(),
    'zoneNumber': s.zone,
  };
  return jsonEncode([
    for (final i in items)
      if (i.step case final s?)
        one(s)
      else
        {
          'type': 'RepeatGroupDTO',
          'stepType': {'stepTypeKey': 'repeat'},
          'numberOfIterations': i.repeat,
          'endConditionValue': i.repeat,
          'workoutSteps': [for (final s in i.steps) one(s)],
        },
  ]);
}

int _maxZone(WorkoutSemantics w) =>
    w.zoneSeconds.keys.fold(0, (m, z) => math.max(m, z));

/// Checks the coach's answer against the plan and Settings → Training. Null
/// when it may be shown; else a short reason (for the log; the rules'
/// proposal is shown instead).
String? revisionProblem(MorningRevision r, RevisionContext c) {
  final real = r.changes.where((x) => x.op != RevisionOp.keep).length;
  if (real == 0 || real > 3) return 'change count';
  final touched = <String>{};
  // Day by day after the changes, for the settings checks.
  final dayOf = {for (final s in c.week) s.id: s.sessionDate};
  final gone = <String>{};
  for (final x in r.changes) {
    final s = c.byId(x.sessionId);
    if (s == null || !_open(s)) {
      return 'unknown session ${x.sessionId} (${x.op.name})';
    }
    if (!_sameDay(s.sessionDate, c.day) &&
        !_sameDay(s.sessionDate, c.nextDay)) {
      return 'not the day or the next ${x.sessionId}';
    }
    // A session the athlete fixed stays as it is.
    if (s.locked && x.op != RevisionOp.keep) return 'locked ${s.id}';
    if (!touched.add(s.id)) return 'session changed twice';
    if ((x.indoor ?? false) && !hasIndoorAlternative(s)) {
      return 'no indoor form ${s.id}';
    }
    // A key, long or test session is the week's backbone: only red
    // readiness takes it out completely.
    if (x.op == RevisionOp.rest &&
        weightOf(s) == SessionWeight.hard &&
        c.readinessLevel != 'red' &&
        c.feeling != 'ill') {
      return 'key session dropped without red readiness';
    }
    switch (x.op) {
      case RevisionOp.keep:
        break;
      case RevisionOp.rest:
        gone.add(s.id);
      case RevisionOp.swap:
        final other = c.byId(x.withId!);
        if (other == null || !_open(other)) return 'unknown swap partner';
        if (_sameDay(other.sessionDate, s.sessionDate) ||
            other.sessionDate.isBefore(s.sessionDate)) {
          return 'swap partner not later';
        }
        if (other.locked) return 'locked ${other.id}';
        if (!touched.add(other.id)) return 'session changed twice';
        // The harder session must not come earlier.
        if (weightOf(other).index > weightOf(s).index) {
          return 'swap brings a harder session earlier';
        }
        dayOf[s.id] = other.sessionDate;
        dayOf[other.id] = s.sessionDate;
      case RevisionOp.revise:
        if (x.steps != null) {
          if (isStrengthSession(s)) return 'steps for strength';
          for (final i in x.steps!) {
            for (final st in i.step == null ? i.steps : [i.step!]) {
              if (st.minutes <= 0 || st.zone < 1 || st.zone > 5) {
                return 'bad step';
              }
            }
            if (i.repeat < 1 || i.repeat > 20) return 'bad repeat';
          }
          final before = WorkoutSemantics.of(s.stepsJson, sport: s.sport);
          final after = WorkoutSemantics.of(
            revisionStepsJson(x.steps!),
            sport: s.sport,
          );
          final plannedSeconds = before.isEmpty
              ? s.plannedDurationMin * 60.0
              : before.totalSeconds;
          if (after.totalSeconds < 600) return 'too short';
          if (after.totalSeconds > plannedSeconds + 30) return 'longer';
          final planZone = before.isEmpty ? s.primaryZone : _maxZone(before);
          if (_maxZone(after) > planZone) return 'harder zone';
          if (!before.isEmpty && after.legacyLoad > before.legacyLoad * 1.02) {
            return 'more load';
          }
        }
        if (x.exercises != null) {
          if (!isStrengthSession(s)) return 'exercises for endurance';
          final plan = c.strengthPlans[s.id]?.plan;
          if (plan == null) return 'no strength plan';
          final byId = {
            for (final b in plan.blocks)
              for (final e in b.exercises) e.id: e,
          };
          var kept = 0;
          for (final e in x.exercises!) {
            final p = byId[e.id];
            if (p == null) return 'unknown exercise ${e.id}';
            if (e.drop) continue;
            final working = p.sets
                .where((s) => s.kind != StrengthSetKind.warmup)
                .length;
            if (e.sets != null && (e.sets! < 1 || e.sets! > working)) {
              return 'more sets';
            }
            final reps = _reps(p);
            if (e.reps != null &&
                (e.reps! < 1 || (reps != null && e.reps! > reps))) {
              return 'more reps';
            }
            if (e.loadPercent != null &&
                (e.loadPercent! < 40 || e.loadPercent! > 100)) {
              return 'load out of range';
            }
          }
          final dropped = {
            for (final e in x.exercises!)
              if (e.drop) e.id,
          };
          kept = byId.keys.where((id) => !dropped.contains(id)).length;
          if (kept == 0) return 'every exercise dropped';
        }
    }
  }

  // Settings → Training: rest days, strength days, sessions per day, and no
  // new pair of hard days in a row.
  final days = {for (final d in dayOf.values) DateTime(d.year, d.month, d.day)};
  for (final x in r.changes.where((x) => x.op == RevisionOp.swap)) {
    for (final id in [x.sessionId, x.withId!]) {
      final s = c.byId(id)!;
      final to = dayOf[id]!;
      if (c.restWeekdays.contains(to.weekday)) return 'onto a rest day';
      if (isStrengthSession(s) &&
          c.strengthWeekdays.isNotEmpty &&
          !c.strengthWeekdays.contains(to.weekday)) {
        return 'strength off its days';
      }
    }
  }
  for (final d in days) {
    final on = [
      for (final s in c.week)
        if (!gone.contains(s.id) && _open(s) && _sameDay(dayOf[s.id]!, d)) s,
    ];
    final was = [
      for (final s in c.week)
        if (_open(s) && _sameDay(s.sessionDate, d)) s,
    ];
    if (on.length > c.maxPerDay.clamp(1, 3) && on.length > was.length) {
      return 'too many on ${_date(d)}';
    }
  }
  bool hardOn(DateTime d, bool after) => c.week.any(
    (s) =>
        _open(s) &&
        !(after && gone.contains(s.id)) &&
        _sameDay(after ? dayOf[s.id]! : s.sessionDate, d) &&
        weightOf(s) == SessionWeight.hard,
  );
  for (final d in days) {
    for (final n in [
      d.add(const Duration(days: 1)),
      d.subtract(const Duration(days: 1)),
    ]) {
      if (hardOn(d, true) &&
          hardOn(n, true) &&
          !(hardOn(d, false) && hardOn(n, false))) {
        return 'hard back to back';
      }
    }
  }

  // Strength the day before a key or long session takes the legs: no new
  // such pair.
  bool strengthBeforeHard(DateTime d, bool after) {
    DateTime on(TrainingSession s) => after ? dayOf[s.id]! : s.sessionDate;
    final next = DateTime(d.year, d.month, d.day + 1);
    final live = [
      for (final s in c.week)
        if (_open(s) && !(after && gone.contains(s.id))) s,
    ];
    return live.any((s) => isStrengthSession(s) && _sameDay(on(s), d)) &&
        live.any(
          (s) =>
              !isStrengthSession(s) &&
              weightOf(s) == SessionWeight.hard &&
              _sameDay(on(s), next),
        );
  }

  for (final d in {
    ...days,
    for (final d in days) d.subtract(const Duration(days: 1)),
  }) {
    if (strengthBeforeHard(d, true) && !strengthBeforeHard(d, false)) {
      return 'strength the day before a key session';
    }
  }

  // Races: no hard session newly in the two days before an A or B race.
  for (final race in c.races) {
    if (race.priority.toUpperCase() == 'C') continue;
    final rd = DateTime(race.date.year, race.date.month, race.date.day);
    for (final s in c.week) {
      if (!_open(s) || gone.contains(s.id)) continue;
      if (weightOf(s) != SessionWeight.hard) continue;
      final to = dayOf[s.id]!;
      final gap = rd.difference(DateTime(to.year, to.month, to.day)).inDays;
      final was = rd
          .difference(
            DateTime(
              s.sessionDate.year,
              s.sessionDate.month,
              s.sessionDate.day,
            ),
          )
          .inDays;
      if (gap >= 0 && gap <= 2 && !(was >= 0 && was <= 2)) {
        return 'hard session moved next to a race';
      }
    }
  }

  // Weather: an outdoor session moved onto a rainy day goes inside, when it
  // can.
  for (final x in r.changes.where((x) => x.op == RevisionOp.swap)) {
    for (final id in [x.sessionId, x.withId!]) {
      final s = c.byId(id)!;
      final to = dayOf[id]!;
      final rain = c.weather[DateTime(to.year, to.month, to.day)]?.rain;
      final wasRain = c
          .weather[DateTime(
            s.sessionDate.year,
            s.sessionDate.month,
            s.sessionDate.day,
          )]
          ?.rain;
      final inside = s.indoor || (id == x.sessionId && (x.indoor ?? false));
      if ((rain ?? false) &&
          !(wasRain ?? false) &&
          !inside &&
          hasIndoorAlternative(s)) {
        return 'moved outdoors onto a rain day';
      }
    }
  }

  // Settings → Training: the weekly hours and training days, never more
  // than before where the plan already uses them up.
  DateTime monday(DateTime d) =>
      DateTime(d.year, d.month, d.day - d.weekday + 1);
  final weeks = {for (final d in days) monday(d)};
  for (final w in weeks) {
    bool inWeek(DateTime d) =>
        !d.isBefore(w) && d.isBefore(w.add(const Duration(days: 7)));
    var minutesBefore = 0, minutesAfter = 0;
    final daysBefore = <DateTime>{}, daysAfter = <DateTime>{};
    for (final s in c.week) {
      if (!_open(s)) continue;
      if (inWeek(s.sessionDate)) {
        minutesBefore += s.plannedDurationMin;
        daysBefore.add(
          DateTime(s.sessionDate.year, s.sessionDate.month, s.sessionDate.day),
        );
      }
      final to = dayOf[s.id]!;
      if (!gone.contains(s.id) && inWeek(to)) {
        minutesAfter += s.plannedDurationMin;
        daysAfter.add(DateTime(to.year, to.month, to.day));
      }
    }
    final hours = c.hoursPerWeek;
    if (hours != null &&
        minutesAfter > hours * 60 &&
        minutesAfter > minutesBefore) {
      return 'over the weekly hours';
    }
    final trainingDays = c.trainingDaysPerWeek;
    if (trainingDays != null &&
        daysAfter.length > trainingDays &&
        daysAfter.length > daysBefore.length) {
      return 'more training days than set';
    }
  }
  return null;
}

/// Writes an accepted revision. Watches are left alone: sending the new
/// session is the athlete's step.
Future<void> applyMorningRevision(
  AppDatabase db,
  StrengthRepository strength,
  MorningRevision r,
  RevisionContext c,
) async {
  for (final x in r.changes) {
    final s = c.byId(x.sessionId)!;
    switch (x.op) {
      case RevisionOp.keep:
        break;
      case RevisionOp.rest:
        await (db.update(
          db.trainingSessions,
        )..where((t) => t.id.equals(s.id))).write(
          const TrainingSessionsCompanion(
            status: Value('skipped'),
            adaptationTrigger: Value('coach_morning'),
          ),
        );
      case RevisionOp.swap:
        final other = c.byId(x.withId!)!;
        await db.transaction(() async {
          await (db.update(
            db.trainingSessions,
          )..where((t) => t.id.equals(s.id))).write(
            TrainingSessionsCompanion(
              sessionDate: Value(other.sessionDate),
              indoor: x.indoor == true
                  ? const Value(true)
                  : const Value.absent(),
            ),
          );
          await (db.update(
            db.trainingSessions,
          )..where((t) => t.id.equals(other.id))).write(
            TrainingSessionsCompanion(sessionDate: Value(s.sessionDate)),
          );
        });
      case RevisionOp.revise:
        if (x.indoor == true) {
          await (db.update(
            db.trainingSessions,
          )..where((t) => t.id.equals(s.id))).write(
            const TrainingSessionsCompanion(
              indoor: Value(true),
              adaptationTrigger: Value('coach_morning'),
            ),
          );
        }
        if (x.steps != null) {
          final json = revisionStepsJson(x.steps!);
          final w = WorkoutSemantics.of(json, sport: s.sport);
          await (db.update(
            db.trainingSessions,
          )..where((t) => t.id.equals(s.id))).write(
            TrainingSessionsCompanion(
              stepsJson: Value(json),
              plannedDurationMin: Value(w.totalMinutes),
              plannedTrimp: Value(w.legacyLoad.round()),
              primaryZone: Value(w.dominantZone ?? s.primaryZone),
              title: Value(retimeTitle(s.title, w.totalMinutes)),
              status: const Value('adapted'),
              originalSessionLevel: Value(
                s.originalSessionLevel ?? s.sessionLevel,
              ),
              adaptationTrigger: const Value('coach_morning'),
              tspAdjusted: const Value(true),
            ),
          );
        }
        if (x.exercises != null) {
          final stored = c.strengthPlans[s.id]!;
          final plan = reviseStrengthPlan(stored.plan, x.exercises!);
          await strength.savePlan(
            StrengthPlanOwner.session(s.id),
            plan,
            expectedRevision: stored.revision,
          );
          await (db.update(
            db.trainingSessions,
          )..where((t) => t.id.equals(s.id))).write(
            const TrainingSessionsCompanion(
              status: Value('adapted'),
              adaptationTrigger: Value('coach_morning'),
            ),
          );
        }
    }
  }
}

/// [plan] with the coach's targets: working sets cut from the end, warm-ups
/// kept, repetitions and load lowered, dropped exercises (and empty blocks)
/// left out. The equipment of every exercise stays as planned.
StrengthWorkoutPlan reviseStrengthPlan(
  StrengthWorkoutPlan plan,
  List<RevisionExercise> changes,
) {
  final byId = {for (final e in changes) e.id: e};
  final blocks = <StrengthBlock>[];
  for (final b in plan.blocks) {
    final exercises = <StrengthPlannedExercise>[];
    for (final e in b.exercises) {
      final x = byId[e.id];
      if (x == null) {
        exercises.add(e);
        continue;
      }
      if (x.drop) continue;
      var working = 0;
      final sets = <StrengthSetTarget>[];
      for (final s in e.sets) {
        if (s.kind != StrengthSetKind.warmup) {
          working++;
          if (x.sets != null && working > x.sets!) continue;
        }
        sets.add(
          s.kind == StrengthSetKind.warmup
              ? s
              : s.copyWith(
                  reps: x.reps == null || s.reps == null
                      ? null
                      : () => math.min(s.reps!, x.reps!),
                  repMax: x.reps == null || s.repMax == null
                      ? null
                      : () => math.min(s.repMax!, x.reps!),
                  repMin: x.reps == null || s.repMin == null
                      ? null
                      : () => math.min(s.repMin!, x.reps!),
                  load: x.loadPercent == null || s.load == null
                      ? null
                      : () => StrengthLoad(
                          s.load!.kg * x.loadPercent! / 100,
                          unit: s.load!.unit,
                        ),
                ),
        );
      }
      exercises.add(e.copyWith(sets: sets));
    }
    if (exercises.isNotEmpty) blocks.add(b.copyWith(exercises: exercises));
  }
  return plan.copyWith(blocks: blocks);
}
