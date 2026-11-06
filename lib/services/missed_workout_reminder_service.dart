import '../l10n/formats.dart';

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import '../l10n/l10n_ext.dart';
import '../providers/plan_week_provider.dart';
import '../utils/log.dart';
import 'notifications/local_notification_gateway.dart';

/// Notification ids of this reminder: the base plus the day number, so each
/// day has exactly one and a new schedule replaces the old one.
const missedWorkoutNotificationBase = 7300000;
const missedWorkoutNotificationLimit = 7400000;

/// How many days ahead reminders are scheduled. iOS cannot wake the app at
/// 19:30, so the notification is set up in advance and taken back as soon as
/// the workout is recorded, moved or skipped.
const _scheduleDays = 7;

const _enabledKey = 'missed_workout_reminder_enabled_v1';
const _minutesKey = 'missed_workout_reminder_minutes_v1';
const _daysAheadKey = 'missed_workout_move_days_v1';
const _ackKey = 'missed_workout_reminder_ack_v1';

/// On by default at 19:30; a missed session may move up to 3 days ahead.
class MissedWorkoutSettings {
  const MissedWorkoutSettings({
    this.enabled = true,
    this.minutes = 19 * 60 + 30,
    this.daysAhead = 3,
  });
  final bool enabled;

  /// Minutes after midnight.
  final int minutes;

  /// 3 to 5 days to look ahead for a new slot.
  final int daysAhead;

  int get hour => minutes ~/ 60;
  int get minute => minutes % 60;

  MissedWorkoutSettings copyWith({
    bool? enabled,
    int? minutes,
    int? daysAhead,
  }) => MissedWorkoutSettings(
    enabled: enabled ?? this.enabled,
    minutes: minutes ?? this.minutes,
    daysAhead: daysAhead ?? this.daysAhead,
  );

  static Future<MissedWorkoutSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MissedWorkoutSettings(
      enabled: prefs.getBool(_enabledKey) ?? true,
      minutes: (prefs.getInt(_minutesKey) ?? 19 * 60 + 30).clamp(
        0,
        24 * 60 - 1,
      ),
      daysAhead: (prefs.getInt(_daysAheadKey) ?? 3).clamp(3, 5),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    await prefs.setInt(_minutesKey, minutes.clamp(0, 24 * 60 - 1));
    await prefs.setInt(_daysAheadKey, daysAhead.clamp(3, 5));
  }
}

/// The only data the notification carries: which day it is about.
class MissedWorkoutPayload {
  const MissedWorkoutPayload(this.day);
  final DateTime day;

  String encode() =>
      jsonEncode({'v': 1, 'feature': 'missed_workout', 'day': _dayKey(day)});

  static MissedWorkoutPayload? decode(String? raw) {
    if (raw == null || raw.length > 200) return null;
    try {
      final j = jsonDecode(raw);
      if (j is! Map || j['v'] != 1 || j['feature'] != 'missed_workout') {
        return null;
      }
      final day = DateTime.tryParse('${j['day']}');
      return day == null ? null : MissedWorkoutPayload(_dateOnly(day));
    } catch (_) {
      return null;
    }
  }
}

enum MissedWorkoutActionKind { open, move, skip }

/// What the app should show after a tap on the reminder.
class MissedWorkoutAction {
  const MissedWorkoutAction(this.day, this.kind);
  final DateTime day;
  final MissedWorkoutActionKind kind;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
String _dayKey(DateTime d) => _dateOnly(d).toIso8601String().substring(0, 10);

/// The id of the reminder for [day].
int missedWorkoutNotificationId(DateTime day) =>
    missedWorkoutNotificationBase +
    DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(2020)).inDays;

/// Reminds in the evening of planned sessions that are still open that day.
class MissedWorkoutReminderService {
  MissedWorkoutReminderService(
    this.db,
    this.gateway, {
    DateTime Function()? now,
    Future<MissedWorkoutSettings> Function()? settings,
  }) : now = now ?? DateTime.now,
       settings = settings ?? MissedWorkoutSettings.load;

  final AppDatabase db;
  final LocalNotificationGateway gateway;
  final DateTime Function() now;
  final Future<MissedWorkoutSettings> Function() settings;

  Future<void> _pending = Future.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final run = _pending.then((_) => action());
    _pending = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  /// Planned sessions and watch workouts of [day] that are neither done nor
  /// skipped.
  Future<List<PlanWeekItem>> openItems(
    DateTime day, [
    Map<DateTime, Future<PlanWeek>>? weeks,
  ]) async {
    final d = _dateOnly(day);
    final start = weekStartFor(d);
    final week = await (weeks == null
        ? loadPlanWeek(db, start)
        : weeks.putIfAbsent(start, () => loadPlanWeek(db, start)));
    for (final w in week.days) {
      if (_dayKey(w.date) != _dayKey(d)) continue;
      return [
        for (final i in w.items)
          if (i.hasPlan && i.state == PlanWeekState.planned) i,
      ];
    }
    return const [];
  }

  /// Days the athlete already answered with "still today".
  static Future<Set<String>> _acknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_ackKey) ?? const <String>[]).toSet();
  }

  /// "Still today": no further reminder for [day].
  Future<void> acknowledge(DateTime day) => _acknowledge(day);

  static Future<void> _acknowledge(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_ackKey) ?? <String>[];
    if (!list.contains(_dayKey(day))) list.add(_dayKey(day));
    await prefs.setStringList(
      _ackKey,
      list.length > 14 ? list.sublist(list.length - 14) : list,
    );
  }

  /// The reminder text: the open sessions by name, with their minutes.
  static ({String title, String body}) textFor(List<PlanWeekItem> items) {
    final names = [
      for (final i in items)
        i.plannedMinutes == null
            ? i.plannedTitle
            : '${i.plannedTitle} (${planDuration(i.plannedMinutes!)})',
    ].join(', ');
    return (title: tr.missedWorkoutTitle, body: tr.missedWorkoutBody(names));
  }

  /// Brings the scheduled reminders in line with the plan and the settings.
  /// Safe to call often: after a sync, a plan change, a new Health workout.
  Future<void> reconcile() => _serial(() async {
    final s = await settings();
    final at = now();
    final today = _dateOnly(at);
    final allowed = (await gateway.permission()).allowed;
    final acked = await _acknowledged();
    // Seven days touch at most two weeks; each is read once.
    final weeks = <DateTime, Future<PlanWeek>>{};
    for (var offset = 0; offset < _scheduleDays; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      final id = missedWorkoutNotificationId(day);
      final due = DateTime(day.year, day.month, day.day, s.hour, s.minute);
      final items = await openItems(day, weeks);
      // Nothing open (done, moved, skipped): take it back, also from the
      // notification centre if it was already shown.
      if (items.isEmpty || !s.enabled || !allowed) {
        await gateway.cancel(id);
        continue;
      }
      // Shown already, or answered: leave it as it is.
      if (!due.isAfter(at) || acked.contains(_dayKey(day))) continue;
      final text = textFor(items);
      await gateway.schedule(
        ScheduledNotification(
          id: id,
          at: due,
          payload: MissedWorkoutPayload(day).encode(),
          title: text.title,
          body: text.body,
          feature: NotificationFeature.missedWorkout,
          actionLabels: {
            'today': tr.stillToday,
            'move': tr.moveWorkoutAction,
            'skip': tr.skip,
          },
        ),
      );
    }
    log('[MissedWorkout] reconciled enabled=${s.enabled} allowed=$allowed');
  });

  /// For trying the reminder on a device: the one of the first day in the
  /// coming week with an open session (or today, with an example), shown
  /// after [delay] with the real buttons. Its own id, so [reconcile] leaves
  /// it alone. Returns the day it is about.
  Future<DateTime> scheduleTest({
    Duration delay = const Duration(seconds: 10),
  }) async {
    final today = _dateOnly(now());
    var day = today;
    var items = const <PlanWeekItem>[];
    final weeks = <DateTime, Future<PlanWeek>>{};
    for (var offset = 0; offset < _scheduleDays; offset++) {
      final d = DateTime(today.year, today.month, today.day + offset);
      final open = await openItems(d, weeks);
      if (open.isNotEmpty) {
        day = d;
        items = open;
        break;
      }
    }
    final text = items.isEmpty
        ? (
            title: tr.missedWorkoutTitle,
            body: tr.missedWorkoutBody(tr.onbExampleWorkout),
          )
        : textFor(items);
    if (!(await gateway.permission()).allowed) {
      await gateway.requestPermission();
    }
    await gateway.schedule(
      ScheduledNotification(
        id: missedWorkoutNotificationLimit - 1,
        at: now().add(delay),
        payload: MissedWorkoutPayload(day).encode(),
        title: text.title,
        body: text.body,
        feature: NotificationFeature.missedWorkout,
        actionLabels: {
          'today': tr.stillToday,
          'move': tr.moveWorkoutAction,
          'skip': tr.skip,
        },
      ),
    );
    log(
      '[MissedWorkout] test reminder for ${_dayKey(day)} in ${delay.inSeconds}s',
    );
    return day;
  }

  /// Handles a tap. "Still today" is settled here; the others tell the app
  /// what to open. Null when there is nothing to show.
  Future<MissedWorkoutAction?> handle(NotificationResponse r) =>
      _serial(() async {
        final p = MissedWorkoutPayload.decode(r.payload);
        if (p == null) return null;
        switch (r.actionId) {
          case 'today':
            await _acknowledge(p.day);
            return null;
          case 'move':
            return MissedWorkoutAction(p.day, MissedWorkoutActionKind.move);
          case 'skip':
            return MissedWorkoutAction(p.day, MissedWorkoutActionKind.skip);
          default:
            return MissedWorkoutAction(p.day, MissedWorkoutActionKind.open);
        }
      });
}
