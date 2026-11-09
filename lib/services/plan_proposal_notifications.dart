import 'dart:convert';
import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../l10n/formats.dart';
import '../l10n/l10n_ext.dart';
import '../utils/log.dart';
import 'missed_workout_reminder_service.dart';
import 'notifications/local_notification_gateway.dart';
import 'plan_proposal_store.dart';

/// Notification ids of plan proposals: the base plus the day number.
const planProposalNotificationBase = 7500000;
const pastMissedNotificationBase = 7510000;
const planProposalNotificationLimit = 7520000;

int _dayNumber(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2020)).inDays;

String _dayKey(DateTime d) =>
    DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

/// The readiness proposal of a day, in the notification.
class PlanProposalPayload {
  const PlanProposalPayload(this.day);
  final DateTime day;

  String encode() =>
      jsonEncode({'v': 1, 'feature': 'plan_proposal', 'day': _dayKey(day)});

  static PlanProposalPayload? decode(String? raw) {
    if (raw == null || raw.length > 200) return null;
    try {
      final j = jsonDecode(raw);
      if (j is! Map || j['v'] != 1 || j['feature'] != 'plan_proposal') {
        return null;
      }
      final day = DateTime.tryParse('${j['day']}');
      return day == null
          ? null
          : PlanProposalPayload(DateTime(day.year, day.month, day.day));
    } catch (_) {
      return null;
    }
  }
}

/// What a readiness proposal says in a notification.
typedef ProposalText = ({DateTime day, String title, String body});

/// Tells about proposals the athlete has not answered: today's readiness
/// change as one push in the morning ([scheduleMorning]), sessions missed
/// in the last two days once the app is in the background, a few minutes
/// late, so a quick switch to another app does not ring (the Plan shows
/// those as cards).
class PlanProposalNotifications {
  PlanProposalNotifications(
    this.gateway,
    this.missed, {
    DateTime Function()? now,
    math.Random? random,
  }) : now = now ?? DateTime.now,
       random = random ?? math.Random();

  final LocalNotificationGateway gateway;
  final MissedWorkoutReminderService missed;
  final DateTime Function() now;
  final math.Random random;

  /// 3 to 6 minutes from now.
  DateTime _due() => now().add(Duration(seconds: 180 + random.nextInt(181)));

  /// When the morning push about today's plan appears: 10 to 20 minutes
  /// after the sync that found it.
  Duration _morningDelay() => Duration(seconds: 600 + random.nextInt(601));

  /// After noon the day is half gone; the push is not sent.
  static const morningLatestHour = 12;

  /// Today's readiness proposal as one push in the morning, 10 to 20
  /// minutes after the first full sync. Once per day; later syncs change
  /// nothing.
  Future<DateTime?> scheduleMorning(ProposalText readiness) async {
    final key = readinessKey(readiness.day);
    if (await PlanProposalStore.notifiedAt(key) != null) return null;
    final due = now().add(_morningDelay());
    if (due.hour >= morningLatestHour ||
        _dayNumber(due) != _dayNumber(readiness.day)) {
      log('[PlanProposal] morning push skipped: due ${due.toLocal()}');
      return null;
    }
    if (!(await gateway.permission()).allowed) return null;
    await gateway.schedule(
      ScheduledNotification(
        id: planProposalNotificationBase + _dayNumber(readiness.day),
        at: due,
        payload: PlanProposalPayload(readiness.day).encode(),
        title: readiness.title,
        body: readiness.body,
        feature: NotificationFeature.planProposal,
        actionLabels: {'open': tr.reviewChange, 'keep': tr.keepPlan},
      ),
    );
    await PlanProposalStore.markNotified(key, due);
    log('[PlanProposal] morning push set for ${due.toLocal()}');
    return due;
  }

  /// Settings → System → Debug: the morning push after [delay], whatever the
  /// time of day.
  Future<void> scheduleTest(ProposalText readiness, Duration delay) async {
    if (!(await gateway.permission()).allowed) return;
    final due = now().add(delay);
    await gateway.schedule(
      ScheduledNotification(
        id: planProposalNotificationBase + _dayNumber(readiness.day),
        at: due,
        payload: PlanProposalPayload(readiness.day).encode(),
        title: readiness.title,
        body: readiness.body,
        feature: NotificationFeature.planProposal,
        actionLabels: {'open': tr.reviewChange, 'keep': tr.keepPlan},
      ),
    );
    await PlanProposalStore.markNotified(readinessKey(readiness.day), due);
  }

  /// The app went to the background with missed sessions still open.
  Future<void> onBackground() async {
    if (!(await gateway.permission()).allowed) return;
    final due = _due();
    // Missed sessions follow the evening reminder's switch.
    final missedOn = (await missed.settings()).enabled;
    for (final m in missedOn ? await missed.pastMissed() : const []) {
      final key = 'm:${_dayKey(m.day)}';
      if (await PlanProposalStore.notifiedAt(key) != null) continue;
      final names = [
        for (final i in m.items)
          i.plannedMinutes == null
              ? i.plannedTitle
              : '${i.plannedTitle} (${planDuration(i.plannedMinutes!)})',
      ].join(', ');
      final yesterday = _dayNumber(now()) - _dayNumber(m.day) == 1;
      await gateway.schedule(
        ScheduledNotification(
          id: pastMissedNotificationBase + _dayNumber(m.day),
          at: due,
          payload: MissedWorkoutPayload(m.day).encode(),
          title: yesterday
              ? tr.missedYesterdayTitle
              : tr.missedOnDayTitle(DateFormat.EEEE().format(m.day)),
          body: tr.missedPastBody(names),
          feature: NotificationFeature.missedWorkout,
          actionLabels: {'move': tr.moveWorkoutAction, 'skip': tr.skip},
        ),
      );
      await PlanProposalStore.markNotified(key, due);
    }
    log('[PlanProposal] background: notifications set for ${due.toLocal()}');
  }

  /// Back in the app: missed sessions not shown yet are taken back (the
  /// cards show them) and may come again the next time the app is left.
  /// The morning push stays: it has no card.
  Future<void> onForeground() async {
    final at = now();
    for (final n in await PlanProposalStore.notifications()) {
      if (!n.at.isAfter(at) || n.key.startsWith('r:')) continue;
      final id = _idOf(n.key);
      if (id != null) await gateway.cancel(id);
      await PlanProposalStore.forget(n.key);
    }
  }

  /// The proposal of [key] was answered: its notification goes, also from
  /// the notification centre.
  Future<void> resolved(String key) async {
    final id = _idOf(key);
    if (id != null) await gateway.cancel(id);
  }

  static int? _idOf(String key) {
    final day = DateTime.tryParse(key.substring(2));
    if (day == null) return null;
    return switch (key[0]) {
      'r' => planProposalNotificationBase + _dayNumber(day),
      'm' => pastMissedNotificationBase + _dayNumber(day),
      _ => null,
    };
  }

  static String readinessKey(DateTime day) => 'r:${_dayKey(day)}';
  static String missedKey(DateTime day) => 'm:${_dayKey(day)}';
}
