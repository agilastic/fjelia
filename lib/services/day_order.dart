import 'dart:math' as math;

/// One open session of today: `sport/minutes` as in the brief, and its kind
/// (`long`, `key`, `recovery`, …).
typedef DaySession = ({String sport, int minutes, String type});

/// A session put into the day and the training window it goes in, in
/// minutes of the day (null without training times).
typedef DaySlot = ({DaySession session, (int, int)? window});

/// Why the order is as it is: `priority` (the key endurance session first,
/// strength after it), `fit` (the windows' lengths decide it) or `together`
/// (both in one window: the endurance session, then strength right after).
typedef DayOrder = ({List<DaySlot> slots, String reason});

bool _strength(DaySession s) => s.sport == 'strength';

/// 0: the session the day is for (long or key endurance), 1: strength,
/// 2: easy endurance.
int _priority(DaySession s) => _strength(s)
    ? 1
    : s.type == 'long' || s.type == 'key'
    ? 0
    : 2;

/// Which of today's open sessions comes first, and in which of the
/// remaining training windows. Each session has to fit the time its window
/// still has; within that, the key endurance session goes first while the
/// athlete is fresh and strength after it, in another window when there is
/// one (the hours between let the legs recover). Null for fewer than two
/// sessions.
DayOrder? dayOrder(
  List<DaySession> sessions,
  List<(int, int)> windows, {
  required int nowMinute,
}) {
  if (sessions.length < 2) return null;
  // Only what is still ahead today; a window running now has what is left.
  final open = [
    for (final w in windows)
      if (w.$2 - math.max(w.$1, nowMinute) >= 20) w,
  ];
  int room((int, int) w) => w.$2 - math.max(w.$1, nowMinute);
  final byPriority = [...sessions]
    ..sort((a, b) => _priority(a).compareTo(_priority(b)));
  if (open.isEmpty) {
    return (
      slots: [for (final s in byPriority) (session: s, window: null)],
      reason: 'priority',
    );
  }

  // Few sessions and windows: try every order and placement.
  List<List<DaySession>> orders(List<DaySession> rest) => rest.length <= 1
      ? [rest]
      : [
          for (var i = 0; i < rest.length; i++)
            for (final tail in orders([...rest]..removeAt(i)))
              [rest[i], ...tail],
        ];
  ({List<DaySlot> slots, int score, bool inverted, bool shared})? best;
  for (final order in orders(sessions)) {
    // Windows in day order, never going back: a later session sits in the
    // same or a later window.
    void place(int i, int from, List<int> chosen) {
      if (i == order.length) {
        var score = 0;
        final used = <int, int>{};
        for (var k = 0; k < order.length; k++) {
          used.update(
            chosen[k],
            (v) => v + order[k].minutes,
            ifAbsent: () => order[k].minutes,
          );
        }
        // Not fitting outweighs everything else.
        for (final e in used.entries) {
          final over = e.value - room(open[e.key]);
          if (over > 0) score += 1000 + over * 10;
        }
        var inverted = false;
        for (var a = 0; a < order.length; a++) {
          for (var b = a + 1; b < order.length; b++) {
            if (_priority(order[a]) > _priority(order[b])) {
              score += 30;
              inverted = true;
            }
            // Strength and endurance in one window when another is free:
            // apart weighs more than the order.
            if (chosen[a] == chosen[b] &&
                open.length > 1 &&
                _strength(order[a]) != _strength(order[b])) {
              score += 40;
            }
          }
        }
        if (best == null || score < best!.score) {
          best = (
            slots: [
              for (var k = 0; k < order.length; k++)
                (session: order[k], window: open[chosen[k]]),
            ],
            score: score,
            inverted: inverted,
            shared: chosen.toSet().length < chosen.length,
          );
        }
        return;
      }
      for (var w = from; w < open.length; w++) {
        place(i + 1, w, [...chosen, w]);
      }
    }

    place(0, 0, const []);
  }
  final found = best!;
  return (
    slots: found.slots,
    reason: found.inverted
        ? 'fit'
        : found.shared
        ? 'together'
        : 'priority',
  );
}

String _hm(int m) =>
    '${(m ~/ 60).toString().padLeft(2, '0')}:'
    '${(m % 60).toString().padLeft(2, '0')}';

/// Brief form: `strength/45@06:00-07:30|trail_running/114@17:00-20:00`.
String dayOrderLine(DayOrder order) => order.slots
    .map(
      (s) =>
          '${s.session.sport}/${s.session.minutes}'
          '${s.window == null ? '' : '@${_hm(s.window!.$1)}-${_hm(s.window!.$2)}'}',
    )
    .join('|');
