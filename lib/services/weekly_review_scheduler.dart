import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import '../l10n/l10n_ext.dart';
import '../utils/log.dart';
import '../utils/week.dart';
import 'notifications/local_notification_gateway.dart';
import 'pro_analysis.dart';

/// Notification ids: the base plus the day number of the week's start.
const weeklyReviewNotificationBase = 7600000;

/// "Your review is ready": its own range, so the reconcile of the start push
/// never takes it back.
const weeklyReviewReadyBase = 7700000;

const _autoKey = 'weekly_review_auto_v1';
const _attemptKey = 'weekly_review_attempt_v1';

/// After a failed attempt the next one waits this long.
const weeklyReviewRetryAfter = Duration(minutes: 30);

/// The push at the start of a week: which week's review it is about.
class WeeklyReviewPayload {
  const WeeklyReviewPayload(this.weekStart);
  final DateTime weekStart;

  String encode() => jsonEncode({
    'v': 1,
    'feature': 'weekly_review',
    'week': weekStart.toIso8601String().substring(0, 10),
  });

  static WeeklyReviewPayload? decode(String? raw) {
    if (raw == null || raw.length > 200) return null;
    try {
      final j = jsonDecode(raw);
      if (j is! Map || j['v'] != 1 || j['feature'] != 'weekly_review') {
        return null;
      }
      final day = DateTime.tryParse('${j['week']}');
      return day == null
          ? null
          : WeeklyReviewPayload(DateTime(day.year, day.month, day.day));
    } catch (_) {
      return null;
    }
  }
}

/// Whether the review is written by itself when a week begins. Turning it on
/// is the athlete's consent to send the week's training context to Fjelia AI
/// Pro without asking each time.
class WeeklyReviewSettings {
  static Future<bool> auto() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_autoKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setAuto(bool on) async =>
      (await SharedPreferences.getInstance()).setBool(_autoKey, on);
}

/// The week review of the finished week: a push at 00:00 of the athlete's
/// first weekday, and the review itself written the next time the app runs
/// (a start, a resume, a sync, also one in the background). iOS cannot wake
/// the app at midnight, so the push is scheduled in advance. A failed
/// attempt is tried again after [weeklyReviewRetryAfter].
class WeeklyReviewScheduler {
  WeeklyReviewScheduler({
    required this.db,
    required this.gateway,
    required this.generate,
    required this.isPro,
    required this.mondayFirst,
    Future<bool> Function()? auto,
    DateTime Function()? now,
  }) : auto = auto ?? WeeklyReviewSettings.auto,
       now = now ?? DateTime.now;

  final AppDatabase db;
  final LocalNotificationGateway gateway;

  /// The same call the button on the plan makes.
  final Future<void> Function(ProAnalysisRef analysis) generate;
  final bool Function() isPro;
  final Future<bool> Function() mondayFirst;
  final Future<bool> Function() auto;
  final DateTime Function() now;

  bool _running = false;

  static int notificationId(DateTime weekStart) =>
      weeklyReviewNotificationBase +
      DateTime.utc(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      ).difference(DateTime.utc(2020)).inDays;

  Future<bool> _enabled() async => isPro() && await auto();

  /// Schedules the push for the start of the next week, or takes it back
  /// when the review is off.
  Future<void> reconcile() async {
    try {
      final first = await mondayFirst();
      final at = now();
      final start = weekStartOf(at, mondayFirst: first);
      final next = DateTime(start.year, start.month, start.day + 7);
      final pending = await gateway.pendingIds();
      final enabled = await _enabled();
      for (final id in pending) {
        if (id >= weeklyReviewNotificationBase &&
            id < weeklyReviewNotificationBase + 100000 &&
            (!enabled || id != notificationId(next))) {
          await gateway.cancel(id);
        }
      }
      if (!enabled || !(await gateway.permission()).allowed) return;
      if (pending.contains(notificationId(next))) return;
      await gateway.schedule(
        ScheduledNotification(
          id: notificationId(next),
          at: next,
          payload: WeeklyReviewPayload(next).encode(),
          title: tr.weeklyReviewPushTitle,
          body: tr.weeklyReviewPushBody,
          feature: NotificationFeature.weeklyReview,
        ),
      );
    } catch (e) {
      log('[WeeklyReview] reconcile: $e');
    }
  }

  /// Tells the athlete the review is there: right away, also after a sync in
  /// the background. The text says nothing of the training itself, as it
  /// can show on the lock screen.
  Future<void> _ready(DateTime weekStart) async {
    try {
      if (!(await gateway.permission()).allowed) return;
      await gateway.schedule(
        ScheduledNotification(
          id:
              weeklyReviewReadyBase +
              notificationId(weekStart) -
              weeklyReviewNotificationBase,
          at: now().add(const Duration(seconds: 2)),
          payload: WeeklyReviewPayload(weekStart).encode(),
          title: tr.weeklyReviewReadyTitle,
          body: tr.weeklyReviewReadyBody,
          feature: NotificationFeature.weeklyReview,
        ),
      );
    } catch (e) {
      log('[WeeklyReview] ready push: $e');
    }
  }

  /// The review of the finished week, unless it is written already. One
  /// written before the week was over (from the button, mid-week) is
  /// written again.
  Future<void> runIfDue() async {
    if (_running) return;
    _running = true;
    try {
      final pro = isPro(), on = await auto();
      if (!pro || !on) {
        log('[WeeklyReview] skipped: pro=$pro auto=$on');
        return;
      }
      final first = await mondayFirst();
      final at = now();
      final start = weekStartOf(at, mondayFirst: first);
      final analysis = ProAnalysisRef.lastWeekReview(at, mondayFirst: first);
      final existing = await (db.select(
        db.proReports,
      )..where((t) => t.id.equals(analysis.id))).getSingleOrNull();
      if (existing != null &&
          existing.body.trim().isNotEmpty &&
          !existing.createdAt.isBefore(start)) {
        log('[WeeklyReview] ${analysis.id} already written');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString(_attemptKey)?.split('|');
      if (last != null && last.length == 2 && last[0] == analysis.key) {
        final tried = DateTime.tryParse(last[1]);
        if (tried != null && at.difference(tried) < weeklyReviewRetryAfter) {
          return;
        }
      }
      await prefs.setString(
        _attemptKey,
        '${analysis.key}|${at.toIso8601String()}',
      );
      log('[WeeklyReview] writing ${analysis.id}');
      await generate(analysis);
      log('[WeeklyReview] ${analysis.id} written');
      await _ready(start);
    } catch (e) {
      log('[WeeklyReview] failed, tried again later: $e');
    } finally {
      _running = false;
    }
  }
}
