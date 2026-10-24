import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/daily_readiness_service.dart';
import '../services/readiness_notification_service.dart';
import '../services/session_adaptation_service.dart';
import '../utils/log.dart';
import 'database_provider.dart';
import 'planner_providers.dart';
import 'user_profile_provider.dart';
import 'workout_generation_provider.dart' show planAthleteOf;

final dailyReadinessServiceProvider = Provider<DailyReadinessService>(
  (ref) => DailyReadinessService(ref.watch(databaseProvider)),
);

final sessionAdaptationServiceProvider = Provider<SessionAdaptationService>(
  (ref) => SessionAdaptationService(ref.watch(databaseProvider)),
);

final readinessNotificationServiceProvider =
    Provider<ReadinessNotificationService>(
      (ref) => const ReadinessNotificationService(),
    );

final morningAdaptationProvider =
    StateNotifierProvider<MorningAdaptationNotifier, MorningAdaptationState>(
      (ref) => MorningAdaptationNotifier(ref),
    );

class MorningAdaptationState {
  const MorningAdaptationState({this.running = false, this.notification});

  final bool running;

  /// The morning message produced by the last run.
  final ReadinessNotification? notification;
}

/// Once per day: score readiness, adapt today's (and tomorrow's) sessions,
/// replan when load/HRV trends demand it and push changes to Garmin.
class MorningAdaptationNotifier extends StateNotifier<MorningAdaptationState> {
  MorningAdaptationNotifier(this._ref) : super(const MorningAdaptationState());

  final Ref _ref;
  DateTime? _lastRun;

  Future<void> runIfNeeded() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (state.running || _lastRun == today) return;
    state = const MorningAdaptationState(running: true);
    try {
      final readiness = await _ref
          .read(dailyReadinessServiceProvider)
          .compute(today);
      final adaptation = _ref.read(sessionAdaptationServiceProvider);
      final adapted = await adaptation.adaptDay(readiness);
      final tomorrow = today.add(const Duration(days: 1));

      final replanned = await _replanIfNeeded(readiness);
      if (adapted.any((a) => a.adapted)) {
        await _pushAdaptedSessions(today, adapted);
      }
      if (replanned != null) {
        await _pushAdaptedSessions(today, const []);
        await _pushAdaptedSessions(tomorrow, const []);
      } else if (readiness.level != ReadinessLevel.green) {
        await _pushAdaptedSessions(tomorrow, const []);
      }

      final db = _ref.read(databaseProvider);
      final first =
          await (db.select(db.trainingSessions)
                ..where(
                  (t) =>
                      t.sessionDate.equals(today) & t.athleteId.equals('self'),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.sessionNumber)])
                ..limit(1))
              .get();
      final main = adapted.isNotEmpty
          ? adapted.first
          : first.isEmpty
          ? null
          : AdaptationResult(
              session: first.first,
              reason: readiness.adaptationReason,
            );
      final notification = _ref
          .read(readinessNotificationServiceProvider)
          .buildMorning(
            readiness.level,
            sessionTitle: main?.session.title,
            adaptedDurationMin: main?.adapted == true
                ? main!.session.plannedDurationMin
                : null,
            planUpdate: replanned,
          );
      log('[Readiness] ${readiness.level.name}: ${notification.body}');

      _lastRun = today;
      _ref.invalidate(upcomingSessionsProvider);
      state = MorningAdaptationState(notification: notification);
    } catch (e) {
      log('[Readiness] morning adaptation error: $e');
      state = const MorningAdaptationState();
    }
  }

  /// Re-pushes the day's adapted sessions so Garmin shows the new targets.
  Future<void> _pushAdaptedSessions(
    DateTime day,
    List<AdaptationResult> adapted,
  ) async {
    try {
      final db = _ref.read(databaseProvider);
      final sessions =
          await (db.select(db.trainingSessions)
                ..where(
                  (t) => t.sessionDate.equals(day) & t.athleteId.equals('self'),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.sessionNumber)]))
              .get();
      final plans = _ref.read(trainingPlanServiceProvider);
      for (final s in sessions) {
        if (s.status != 'adapted' && s.garminWorkoutId != null) continue;
        try {
          await plans.pushToGarmin(s.id);
        } catch (e) {
          log('[Readiness] Garmin push failed for ${s.id}: $e');
        }
      }
    } catch (e) {
      log('[Readiness] push sessions error: $e');
    }
  }

  /// Replans when last week's load jumped >15 % or HRV is >10 % suppressed.
  /// Returns the reason when a replan happened.
  Future<String?> _replanIfNeeded(ReadinessResult readiness) async {
    final db = _ref.read(databaseProvider);
    final plan =
        await (db.select(db.trainingPlans)
              ..where(
                (t) => t.athleteId.equals('self') & t.status.equals('active'),
              )
              ..limit(1))
            .getSingleOrNull();
    if (plan == null) return null;
    // Don't replan more than once every 3 days.
    final last = plan.lastReplannedAt;
    if (last != null && DateTime.now().difference(last).inDays < 3) {
      return null;
    }

    final weeks =
        await (db.select(db.weekSummaries)
              ..where((t) => t.athleteId.equals('self'))
              ..orderBy([(t) => OrderingTerm.desc(t.weekStart)])
              ..limit(2))
            .get();
    double nts(WeekSummary w) =>
        w.weeklyNtsz1 +
        w.weeklyNtsz2 +
        w.weeklyNtsz3 +
        w.weeklyNtsz4 +
        w.weeklyNtsz5 +
        w.weeklyNtsz6;

    final reasons = <String>[];
    if (weeks.length == 2) {
      final current = nts(weeks[0]);
      final previous = nts(weeks[1]);
      if (previous > 0 && current > previous * 1.15) {
        reasons.add('ATL spike >15%');
      }
    }
    final hrv = readiness.hrvToday, base = readiness.hrvBaseline;
    if (hrv != null && base != null && base > 0 && hrv < base * (1 - 0.1)) {
      reasons.add('HRV suppressed >10%');
    }
    if (reasons.isEmpty) return null;

    final reason = reasons.join(' + ');
    log('[Readiness] replanning — $reason');
    try {
      final profile = _ref.read(userProfileProvider).valueOrNull;
      await _ref
          .read(trainingPlanServiceProvider)
          .replan(
            planId: plan.id,
            reason: reason,
            daysPerWeek: profile?.trainingDaysPerWeek ?? 5,
            restDays: profile?.restDays ?? const [7],
            strengthDays: profile?.preferredStrengthDays ?? const [3],
            hoursPerWeek: profile?.hoursPerWeek ?? 8.0,
            maxSessionsPerDay: profile?.maxSessionsPerDay ?? 1,
            preferredSports: profile?.preferredSports ?? const [],
            weekStartsOnMonday: profile?.weekStartsOnMonday ?? true,
            athlete: planAthleteOf(profile),
          );
      _ref.invalidate(upcomingSessionsProvider);
      log('[Readiness] replan done');
      return reason;
    } catch (e) {
      log('[Readiness] replan error: $e');
      return null;
    }
  }
}
