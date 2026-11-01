import 'dart:convert';

import '../db/database.dart';
import 'missed_workout_planner.dart';
import 'season/goal_set.dart' show DayLoad;

/// What a change does to one session.
enum RebalanceOp { move, adjust, drop }

/// How hard a session is afterwards. Never harder than planned.
enum RebalanceIntensity { keep, easier, recovery }

/// One change to one session, as the coach (or the rules) proposes it.
class RebalanceChange {
  const RebalanceChange({
    required this.op,
    required this.sessionId,
    this.to,
    this.indoor,
    this.durationMin,
    this.intensity = RebalanceIntensity.keep,
  });
  final RebalanceOp op;
  final String sessionId;

  /// The new day of a move.
  final DateTime? to;

  /// Do it indoors (treadmill, trainer) instead.
  final bool? indoor;

  /// Shorter than planned; never longer.
  final int? durationMin;
  final RebalanceIntensity intensity;
}

/// A complete answer: one sentence for the athlete and up to three changes.
class RebalanceProposal {
  const RebalanceProposal({
    required this.changes,
    this.summary,
    this.fromCoach = false,
  });
  final String? summary;
  final List<RebalanceChange> changes;
  final bool fromCoach;

  RebalanceChange? changeFor(String id) {
    for (final c in changes) {
      if (c.sessionId == id) return c;
    }
    return null;
  }
}

/// The days a missed session may be fitted into, and what is on them.
class RebalanceContext {
  RebalanceContext({
    required this.missed,
    required List<TrainingSession> upcoming,
    required DateTime today,
    this.daysAhead = 3,
    this.maxPerDay = 1,
    this.restWeekdays = const [],
    this.dayLoad,
    this.rainyOn,
    this.raceName,
    this.raceDate,
  }) : today = DateTime(today.year, today.month, today.day) {
    bool inside(DateTime d, int from, int to) {
      final x = DateTime(d.year, d.month, d.day);
      return !x.isBefore(day(from)) && !x.isAfter(day(to));
    }

    final usable = [
      for (final s in upcoming)
        if (s.id != missed.id &&
            const {'planned', 'adapted'}.contains(s.status))
          s,
    ];
    window = [
      for (final s in usable)
        if (inside(s.sessionDate, 1, daysAhead)) s,
    ];
    // The day after the window only counts for back-to-back hard days.
    beyond = [
      for (final s in usable)
        if (inside(s.sessionDate, daysAhead + 1, daysAhead + 1)) s,
    ];
  }

  final TrainingSession missed;
  final DateTime today;
  final int daysAhead, maxPerDay;
  final List<int> restWeekdays;
  final DayLoad Function(DateTime day)? dayLoad;
  final bool Function(DateTime day)? rainyOn;
  final String? raceName;
  final DateTime? raceDate;
  late final List<TrainingSession> window, beyond;

  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  /// Today and the days a session may move to.
  List<DateTime> get days => [for (var i = 0; i <= daysAhead; i++) day(i)];

  TrainingSession? byId(String id) {
    if (id == missed.id) return missed;
    for (final s in window) {
      if (s.id == id) return s;
    }
    return null;
  }
}

String _date(DateTime d) =>
    DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// The question for the coach, as compact JSON. History, readiness and race
/// goals travel separately in the usual coach context.
String rebalanceInputJson(RebalanceContext c) {
  Map<String, Object?> session(TrainingSession s) => {
    'id': s.id,
    'sport': s.sport,
    'type': s.sessionType,
    'zone': s.primaryZone,
    'min': s.plannedDurationMin,
    if (s.indoor) 'indoor': true,
    'title': s.title,
  };
  return jsonEncode({
    'today': _date(c.today),
    'missed': session(c.missed),
    'days': [
      for (final d in c.days.skip(1))
        {
          'date': _date(d),
          if (c.restWeekdays.contains(d.weekday)) 'rest_day': true,
          if (c.rainyOn?.call(d) ?? false) 'rain': true,
          'load': (c.dayLoad?.call(d) ?? DayLoad.free).name,
          'sessions': [
            for (final s in c.window)
              if (_sameDay(s.sessionDate, d)) session(s),
          ],
        },
    ],
    if (c.raceName != null && c.raceDate != null)
      'race': {'name': c.raceName, 'date': _date(c.raceDate!)},
    'rules': {
      'max_per_day': c.maxPerDay,
      'max_changes': 3,
      'never_longer_or_harder': true,
      'no_hard_back_to_back': true,
    },
  });
}

/// Instructions for the coach: the answer format and its limits.
String rebalanceInstructions(String language) =>
    'You are the athlete\'s endurance coach. A planned workout was missed '
    'today. Fit the week around it, using the plan days in the question and '
    'the training history, readiness and race goals in the context. '
    'Reply with JSON only, no other text:\n'
    '{"version":1,"summary":"...","changes":[...]}\n'
    'Each change is one of:\n'
    '{"op":"move","session":"<id>","to":"YYYY-MM-DD","indoor":true|false,'
    '"duration_min":N,"intensity":"keep"|"easier"|"recovery"}\n'
    '{"op":"adjust","session":"<id>","indoor":true|false,"duration_min":N,'
    '"intensity":"keep"|"easier"|"recovery"}\n'
    '{"op":"drop","session":"<id>"}\n'
    'Rules: at most 3 changes. The missed session must be moved or dropped. '
    'Only use session ids and dates from the question. Never make a session '
    'longer or harder. Respect max_per_day, never put two hard sessions on '
    'one day or on two days in a row, nothing hard on an easy_only day and '
    'nothing on a blocked day. Prefer indoor on rain days for outdoor sports. '
    'An easy missed session is usually best dropped. "summary" is one short '
    'sentence in $language, addressed to the athlete, without ids.';

/// Reads the coach's answer. Null when it is not the expected JSON.
RebalanceProposal? parseRebalance(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    final j = jsonDecode(raw.substring(start, end + 1));
    if (j is! Map || j['version'] != 1 || j['changes'] is! List) return null;
    final changes = <RebalanceChange>[];
    for (final c in j['changes'] as List) {
      if (c is! Map) return null;
      final op = switch (c['op']) {
        'move' => RebalanceOp.move,
        'adjust' => RebalanceOp.adjust,
        'drop' => RebalanceOp.drop,
        _ => null,
      };
      final id = c['session'];
      if (op == null || id is! String || id.isEmpty) return null;
      final to = c['to'] is String
          ? DateTime.tryParse(c['to'] as String)
          : null;
      if (op == RebalanceOp.move && to == null) return null;
      final minutes = c['duration_min'];
      final intensity = switch (c['intensity']) {
        null || 'keep' => RebalanceIntensity.keep,
        'easier' => RebalanceIntensity.easier,
        'recovery' => RebalanceIntensity.recovery,
        _ => null,
      };
      if (intensity == null) return null;
      changes.add(
        RebalanceChange(
          op: op,
          sessionId: id,
          to: to,
          indoor: c['indoor'] is bool ? c['indoor'] as bool : null,
          durationMin: minutes is num ? minutes.round() : null,
          intensity: intensity,
        ),
      );
    }
    final summary = j['summary'];
    return RebalanceProposal(
      changes: changes,
      summary: summary is String && summary.trim().isNotEmpty
          ? (summary.trim().length > 220
                ? '${summary.trim().substring(0, 217)}…'
                : summary.trim())
          : null,
      fromCoach: true,
    );
  } catch (_) {
    return null;
  }
}

/// A session as it would be after a proposal.
class _After {
  _After(this.s, this.date, this.weight);
  final TrainingSession s;
  DateTime date;
  SessionWeight weight;
  bool dropped = false;
}

SessionWeight _weightAfter(TrainingSession s, RebalanceIntensity i) =>
    switch (i) {
      RebalanceIntensity.keep => weightOf(s),
      RebalanceIntensity.recovery => SessionWeight.easy,
      RebalanceIntensity.easier =>
        weightOf(s) == SessionWeight.hard
            ? SessionWeight.moderate
            : SessionWeight.easy,
    };

/// Checks a proposal against the plan's limits. Null when it may be shown,
/// else a short reason (for the log; the rules proposal is shown instead).
String? rebalanceProblem(RebalanceProposal p, RebalanceContext c) {
  if (p.changes.isEmpty || p.changes.length > 3) return 'change count';
  final ids = p.changes.map((x) => x.sessionId).toSet();
  if (ids.length != p.changes.length) return 'session changed twice';
  final first = c.day(1), last = c.day(c.daysAhead);
  for (final x in p.changes) {
    final s = c.byId(x.sessionId);
    if (s == null) return 'unknown session ${x.sessionId}';
    final missed = s.id == c.missed.id;
    if (missed && x.op == RebalanceOp.adjust) return 'missed only adjusted';
    if (x.durationMin != null &&
        (x.durationMin! < 10 || x.durationMin! > s.plannedDurationMin)) {
      return 'duration out of range';
    }
    if ((x.indoor ?? false) && !s.indoor && !hasIndoorAlternative(s)) {
      return 'no indoor form';
    }
    if (x.op == RebalanceOp.move) {
      final to = DateTime(x.to!.year, x.to!.month, x.to!.day);
      if (to.isBefore(first) || to.isAfter(last)) return 'date outside window';
    }
  }
  if (!ids.contains(c.missed.id)) return 'missed not handled';

  List<_After> state(bool applied) {
    final out = [
      for (final s in [...c.window, ...c.beyond])
        _After(s, s.sessionDate, weightOf(s)),
    ];
    final m = _After(c.missed, c.today, weightOf(c.missed));
    out.add(m);
    if (!applied) return out;
    for (final x in p.changes) {
      final a = out.firstWhere((e) => e.s.id == x.sessionId);
      if (x.op == RebalanceOp.drop) {
        a.dropped = true;
        continue;
      }
      if (x.op == RebalanceOp.move) a.date = x.to!;
      a.weight = x.intensity == RebalanceIntensity.keep
          ? a.weight
          : _weightAfter(a.s, x.intensity);
    }
    // The missed session does not happen today either way.
    m.dropped = m.dropped || _sameDay(m.date, c.today);
    return out;
  }

  Set<String> hardPairs(List<_After> st) {
    bool hardOn(DateTime d) => st.any(
      (a) =>
          !a.dropped && _sameDay(a.date, d) && a.weight == SessionWeight.hard,
    );
    return {
      for (var i = 0; i <= c.daysAhead; i++)
        if (hardOn(c.day(i)) && hardOn(c.day(i + 1))) _date(c.day(i)),
    };
  }

  // Only what the proposal makes worse counts: a plan that already has two
  // hard sessions on a day must not block every answer, even a plain drop.
  final before = state(false);
  final after = state(true);
  List<_After> on(List<_After> st, DateTime d) => [
    for (final a in st)
      if (!a.dropped && _sameDay(a.date, d)) a,
  ];
  int hardIn(List<_After> xs) =>
      xs.where((a) => a.weight == SessionWeight.hard).length;
  for (var i = 1; i <= c.daysAhead; i++) {
    final d = c.day(i);
    final was = on(before, d), now = on(after, d);
    final load = c.dayLoad?.call(d) ?? DayLoad.free;
    final arrived = now.where((a) => !was.any((b) => b.s.id == a.s.id));
    if (arrived.isNotEmpty && load == DayLoad.blocked) return 'blocked day';
    final limit = c.maxPerDay.clamp(1, 3);
    if (now.length > limit && now.length > was.length) {
      return 'too many on ${_date(d)}';
    }
    final hardNow = hardIn(now), hardWas = hardIn(was);
    if (hardNow > 1 && hardNow > hardWas) return 'two hard on ${_date(d)}';
    if (load == DayLoad.easyOnly && hardNow > hardWas) {
      return 'hard on easy-only day';
    }
  }
  final newPairs = hardPairs(after).difference(hardPairs(before));
  if (newPairs.isNotEmpty) return 'hard back to back';
  return null;
}

/// The rules' own proposal: move the missed session to the best day that
/// passes [rebalanceProblem] (indoors when it rains there, a bit easier when
/// that is what makes it fit), or drop it when it is easy or nothing fits.
RebalanceProposal rulesRebalance(RebalanceContext c) {
  final s = suggestMove(
    missed: c.missed,
    upcoming: [...c.window, ...c.beyond],
    today: c.today,
    daysAhead: c.daysAhead,
    restWeekdays: c.restWeekdays,
    maxPerDay: c.maxPerDay,
    dayLoad: c.dayLoad,
    rainyOn: c.rainyOn,
  );
  if (!s.recommendDrop) {
    for (final candidate in s.candidates) {
      final fit = fittingMove(c, candidate.date);
      if (fit != null) return fit;
    }
  }
  return dropMissed(c);
}

/// The missed session on [day], as it is or a bit easier, whichever passes
/// the checks first; null when neither does. Indoors when it rains there.
RebalanceProposal? fittingMove(RebalanceContext c, DateTime day) {
  final indoor =
      hasIndoorAlternative(c.missed) && (c.rainyOn?.call(day) ?? false);
  for (final intensity in [
    RebalanceIntensity.keep,
    RebalanceIntensity.easier,
  ]) {
    final p = RebalanceProposal(
      changes: [
        RebalanceChange(
          op: RebalanceOp.move,
          sessionId: c.missed.id,
          to: day,
          indoor: indoor ? true : null,
          intensity: intensity,
        ),
      ],
    );
    if (rebalanceProblem(p, c) == null) return p;
  }
  return null;
}

RebalanceProposal dropMissed(RebalanceContext c) => RebalanceProposal(
  changes: [RebalanceChange(op: RebalanceOp.drop, sessionId: c.missed.id)],
);

/// How a session shows in the before/after strip.
enum PreviewKind { unchanged, missed, movedIn, adjusted, dropped }

class PreviewItem {
  const PreviewItem({
    required this.session,
    required this.kind,
    required this.minutes,
    this.minutesBefore,
    this.indoor = false,
    this.intensity = RebalanceIntensity.keep,
  });
  final TrainingSession session;
  final PreviewKind kind;
  final int minutes;

  /// Set when the length changes.
  final int? minutesBefore;
  final bool indoor;
  final RebalanceIntensity intensity;
}

class PreviewDay {
  const PreviewDay(this.date, this.items);
  final DateTime date;
  final List<PreviewItem> items;
}

/// Today and the window, day by day, as they would be after [p].
List<PreviewDay> previewRebalance(RebalanceProposal p, RebalanceContext c) {
  final days = [for (final d in c.days) PreviewDay(d, <PreviewItem>[])];
  void put(DateTime d, PreviewItem item) {
    for (final day in days) {
      if (_sameDay(day.date, d)) day.items.add(item);
    }
  }

  PreviewItem changed(TrainingSession s, RebalanceChange x, PreviewKind kind) {
    final minutes = x.intensity == RebalanceIntensity.recovery
        ? (s.plannedDurationMin < 30 ? s.plannedDurationMin : 30)
        : (x.durationMin ?? s.plannedDurationMin);
    return PreviewItem(
      session: s,
      kind: kind,
      minutes: minutes,
      minutesBefore: minutes == s.plannedDurationMin
          ? null
          : s.plannedDurationMin,
      indoor: x.indoor ?? s.indoor,
      intensity: x.intensity,
    );
  }

  final m = c.missed;
  final mx = p.changeFor(m.id);
  put(
    c.today,
    PreviewItem(
      session: m,
      kind: PreviewKind.missed,
      minutes: m.plannedDurationMin,
    ),
  );
  if (mx != null && mx.op == RebalanceOp.move) {
    put(mx.to!, changed(m, mx, PreviewKind.movedIn));
  }
  for (final s in c.window) {
    final x = p.changeFor(s.id);
    if (x == null) {
      put(
        s.sessionDate,
        PreviewItem(
          session: s,
          kind: PreviewKind.unchanged,
          minutes: s.plannedDurationMin,
          indoor: s.indoor,
        ),
      );
    } else if (x.op == RebalanceOp.drop) {
      put(
        s.sessionDate,
        PreviewItem(
          session: s,
          kind: PreviewKind.dropped,
          minutes: s.plannedDurationMin,
        ),
      );
    } else {
      put(
        x.op == RebalanceOp.move ? x.to! : s.sessionDate,
        changed(
          s,
          x,
          x.op == RebalanceOp.move ? PreviewKind.movedIn : PreviewKind.adjusted,
        ),
      );
    }
  }
  return days;
}
