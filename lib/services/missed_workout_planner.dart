import '../db/database.dart';
import '../theme/activity_colors.dart' show ActivityKind, activityKind;
import 'season/goal_set.dart' show DayLoad;

/// How much a session takes out of the athlete, for deciding where a missed
/// one may go.
enum SessionWeight { easy, moderate, hard }

SessionWeight weightOf(TrainingSession s) {
  if (const {'key', 'long', 'assessment'}.contains(s.sessionType) ||
      s.primaryZone >= 4) {
    return SessionWeight.hard;
  }
  if (s.sessionType == 'recovery' || s.primaryZone <= 2) {
    return SessionWeight.easy;
  }
  return SessionWeight.moderate;
}

/// Outdoor sports that have a comparable indoor form: a run on the treadmill,
/// a ride on the trainer, a hike or walk as an incline treadmill walk.
bool hasIndoorAlternative(TrainingSession s) =>
    !s.indoor &&
    const {
      ActivityKind.running,
      ActivityKind.cycling,
      ActivityKind.hiking,
      ActivityKind.walking,
    }.contains(activityKind(s.sport));

/// Why a candidate day scores lower than a free one. The sheet turns these
/// into words; they never block a day on their own.
enum MoveNote { restDay, sharesDay, nextToHard, indoorForRain, later }

/// One day the missed session could move to.
class MoveCandidate {
  const MoveCandidate({
    required this.date,
    required this.score,
    this.indoor = false,
    this.notes = const [],
  });
  final DateTime date;

  /// Higher is better; 0 for a free day tomorrow.
  final int score;

  /// Do it indoors there: rain is forecast and the sport has an indoor form.
  final bool indoor;
  final List<MoveNote> notes;
}

/// Where a missed session can go within the look-ahead window, best first.
class MissedWorkoutSuggestion {
  const MissedWorkoutSuggestion({
    required this.session,
    required this.candidates,
    required this.recommendDrop,
  });
  final TrainingSession session;
  final List<MoveCandidate> candidates;

  /// An easy session is not worth making up: dropping it is the advice, and
  /// a move stays possible.
  final bool recommendDrop;

  MoveCandidate? get best => candidates.isEmpty ? null : candidates.first;
}

/// Ranks the next [daysAhead] days for [missed].
///
/// A day is left out when it belongs to a race (or its rest day), when it is
/// easy-only (taper) and the session is hard, when it already holds
/// [maxPerDay] sessions, or when a hard session would land on the same day as
/// another hard one. Everything else is allowed and ranked: a rest day, a
/// shared day or a hard day next to another hard day costs points, and so does
/// every day of waiting. Rain on an outdoor day turns it indoors when the
/// sport has an indoor form.
MissedWorkoutSuggestion suggestMove({
  required TrainingSession missed,
  required List<TrainingSession> upcoming,
  required DateTime today,
  int daysAhead = 3,
  List<int> restWeekdays = const [],
  int maxPerDay = 1,
  DayLoad Function(DateTime day)? dayLoad,
  bool Function(DateTime day)? rainyOn,
}) {
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);
  bool same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  final others = [
    for (final s in upcoming)
      if (s.id != missed.id && s.status != 'skipped') s,
  ];
  List<TrainingSession> on(DateTime d) =>
      others.where((s) => same(s.sessionDate, d)).toList();
  bool hardOn(DateTime d) =>
      on(d).any((s) => weightOf(s) == SessionWeight.hard);

  final weight = weightOf(missed);
  final hard = weight == SessionWeight.hard;
  final candidates = <MoveCandidate>[];
  for (var offset = 1; offset <= daysAhead.clamp(1, 7); offset++) {
    final d = day(offset);
    final load = dayLoad?.call(d) ?? DayLoad.free;
    if (load == DayLoad.blocked) continue;
    if (hard && load == DayLoad.easyOnly) continue;
    final there = on(d);
    if (there.length >= maxPerDay.clamp(1, 3)) continue;
    if (hard && hardOn(d)) continue;
    var score = 0;
    final notes = <MoveNote>[];
    if (restWeekdays.contains(d.weekday)) {
      score -= 2;
      notes.add(MoveNote.restDay);
    }
    if (there.isNotEmpty) {
      score -= 2;
      notes.add(MoveNote.sharesDay);
    }
    if (hard && (hardOn(day(offset - 1)) || hardOn(day(offset + 1)))) {
      score -= 3;
      notes.add(MoveNote.nextToHard);
    }
    final indoor = hasIndoorAlternative(missed) && (rainyOn?.call(d) ?? false);
    if (indoor) {
      score -= 1;
      notes.add(MoveNote.indoorForRain);
    }
    if (offset > 1) {
      score -= offset - 1;
      notes.add(MoveNote.later);
    }
    candidates.add(
      MoveCandidate(date: d, score: score, indoor: indoor, notes: notes),
    );
  }
  // Best score first; on a tie the earlier day, so the week keeps its order.
  candidates.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.date.compareTo(b.date);
  });
  return MissedWorkoutSuggestion(
    session: missed,
    candidates: candidates,
    recommendDrop: weight == SessionWeight.easy,
  );
}

/// Whether a day's forecast is wet enough to move an outdoor session inside:
/// at least 2 mm between 7:00 and 20:00, or a 70 % chance of rain in any of
/// those hours.
bool isRainyDay(
  Iterable<({DateTime time, double mm, int? probability})> hours,
  DateTime day,
) {
  var total = 0.0;
  var likely = false;
  for (final h in hours) {
    final t = h.time;
    if (t.year != day.year || t.month != day.month || t.day != day.day) {
      continue;
    }
    if (t.hour < 7 || t.hour >= 20) continue;
    total += h.mm;
    if ((h.probability ?? 0) >= 70) likely = true;
  }
  return total >= 2 || likely;
}
