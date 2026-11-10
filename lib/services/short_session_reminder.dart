import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../utils/log.dart';
import 'control/execution.dart' show shortReasons;
import 'notifications/local_notification_gateway.dart';
import 'post_workout_scorer.dart';

/// Notification ids: the base plus a number from the session id.
const shortSessionNotificationBase = 7530000;

const _askedKey = 'short_session_asked_v1';

/// A planned session done clearly shorter: the push that asks why.
class ShortSessionPayload {
  const ShortSessionPayload(this.sessionId);
  final String sessionId;

  String encode() =>
      jsonEncode({'v': 1, 'feature': 'short_session', 'session': sessionId});

  static ShortSessionPayload? decode(String? raw) {
    if (raw == null || raw.length > 300) return null;
    try {
      final j = jsonDecode(raw);
      if (j is! Map || j['v'] != 1 || j['feature'] != 'short_session') {
        return null;
      }
      final id = j['session'];
      return id is String && id.isNotEmpty ? ShortSessionPayload(id) : null;
    } catch (_) {
      return null;
    }
  }
}

/// The reason in the athlete's language, as the chips and the note say it.
String shortReasonText(AppLocalizations l, String reason) => switch (reason) {
  'time' => l.shortReasonTime,
  'weather' => l.shortReasonWeather,
  'fatigue' => l.shortReasonFatigue,
  'pain' => l.shortReasonPain,
  _ => l.shortReasonOther,
};

/// Asks once, about 5 minutes after a planned session ended clearly
/// shorter, why; the answer goes to the session (its reason) and to the
/// activity as the athlete's note, which the coach reads.
class ShortSessionReminder {
  ShortSessionReminder(
    this.db,
    this.gateway,
    this.scorer, {
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final AppDatabase db;
  final LocalNotificationGateway gateway;
  final PostWorkoutScorer scorer;
  final DateTime Function() now;

  static int idFor(String sessionId) =>
      shortSessionNotificationBase + (sessionId.hashCode & 0x7fff);

  /// After a sync: a push for each shorter session of the last day that has
  /// no reason yet and was not asked about before.
  Future<int> reconcile() async {
    if (!(await gateway.permission()).allowed) return 0;
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getStringList(_askedKey) ?? const <String>[];
    final since = now().subtract(const Duration(days: 1));
    final rows =
        await (db.select(db.sessionActuals)..where(
              (t) =>
                  t.outcome.equals('partial') &
                  t.shortReason.isNull() &
                  t.startedAt.isBiggerThanValue(since),
            ))
            .get();
    var scheduled = 0;
    final next = [...asked];
    for (final a in rows) {
      if (asked.contains(a.sessionId)) continue;
      final s = await (db.select(
        db.trainingSessions,
      )..where((t) => t.id.equals(a.sessionId))).getSingleOrNull();
      if (s == null) continue;
      final done =
          s.actualDurationMin ??
          ((a.durationRatio ?? 0) * s.plannedDurationMin).round();
      final ended = a.completedAt ?? a.startedAt ?? now();
      var at = ended.add(const Duration(minutes: 5));
      final soon = now().add(const Duration(seconds: 30));
      if (at.isBefore(soon)) at = soon;
      await gateway.schedule(
        ScheduledNotification(
          id: idFor(s.id),
          at: at,
          payload: ShortSessionPayload(s.id).encode(),
          title: tr.shortSessionTitle,
          body: tr.shortSessionLine(s.title, done, s.plannedDurationMin),
          feature: NotificationFeature.shortSession,
          actionLabels: {
            for (final r in shortReasons)
              if (r != 'other') r: shortReasonText(tr, r),
          },
        ),
      );
      next.add(s.id);
      scheduled++;
    }
    if (scheduled > 0) {
      // Only the last weeks matter; the list stays short.
      await prefs.setStringList(
        _askedKey,
        next.length > 60 ? next.sublist(next.length - 60) : next,
      );
      log('[ShortSession] $scheduled push(es) set');
    }
    return scheduled;
  }

  /// The athlete's answer: the session's reason and the activity's note
  /// ("Shorter than planned (31 of 45 min): Tired – <text>").
  Future<void> answer(String sessionId, String reason, {String? text}) async {
    await scorer.setShortReason(sessionId, reason);
    await gateway.cancel(idFor(sessionId));
    final a = await (db.select(
      db.sessionActuals,
    )..where((t) => t.sessionId.equals(sessionId))).getSingleOrNull();
    final s = await (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    final activityId = a?.activityId;
    if (activityId == null || s == null) return;
    final done =
        s.actualDurationMin ??
        ((a?.durationRatio ?? 0) * s.plannedDurationMin).round();
    final extra = text?.trim() ?? '';
    final note = [
      '${tr.shortSessionNote(done, s.plannedDurationMin)}: '
          '${shortReasonText(tr, reason)}',
      if (extra.isNotEmpty) extra,
    ].join(' – ');
    final row = await (db.select(
      db.activityRecords,
    )..where((t) => t.activityId.equals(activityId))).getSingleOrNull();
    final before = row?.athleteNote?.trim() ?? '';
    await (db.update(
      db.activityRecords,
    )..where((t) => t.activityId.equals(activityId))).write(
      ActivityRecordsCompanion(
        athleteNote: Value(before.isEmpty ? note : '$before\n$note'),
      ),
    );
  }
}
