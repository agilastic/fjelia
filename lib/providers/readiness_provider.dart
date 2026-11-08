import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/replan_triggers.dart';
import '../utils/week.dart';

import '../db/database.dart';
import '../services/daily_readiness_service.dart';
import '../services/readiness_notification_service.dart';
import '../services/session_adaptation_service.dart';
import '../utils/log.dart';
import 'database_provider.dart';
import 'planner_providers.dart';
import 'user_profile_provider.dart';
import 'workout_destination_provider.dart';
import 'workout_generation_provider.dart' show planAthleteOf;
import '../services/plan_proposal_store.dart';

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
  const MorningAdaptationState({
    this.running = false,
    this.notification,
    this.proposal,
  });

  final bool running;

  /// The morning message produced by the last run.
  final ReadinessNotification? notification;

  /// What the morning check would change, waiting for the athlete's answer.
  final ReadinessProposal? proposal;
}

/// Today's sessions as readiness would change them, and a replan the load
/// or HRV trend asks for. Nothing of it is applied until the athlete agrees.
class ReadinessProposal {
  const ReadinessProposal({
    required this.day,
    required this.readiness,
    this.changes = const [],
    this.replanReason,
  });

  final DateTime day;
  final ReadinessResult readiness;
  final List<AdaptationPreview> changes;

  /// Why the plan should be rebuilt (English, for the plan's log).
  final String? replanReason;
}

/// Once per day: score readiness, adapt today's (and tomorrow's) sessions,
/// replan when load/HRV trends demand it and push changes to Garmin. When the
/// athlete wants to be asked first (the default), the changes wait as a
/// [ReadinessProposal] instead.
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
      // Watch entries that could not be removed earlier are tried again.
      try {
        await _ref.read(trainingPlanServiceProvider).retryCleanup();
      } catch (e) {
        log('[Readiness] Garmin cleanup error: $e');
      }
      final readiness = await _ref
          .read(dailyReadinessServiceProvider)
          .compute(today);
      final adaptation = _ref.read(sessionAdaptationServiceProvider);
      final askFirst = await PlanProposalStore.askFirst();
      final decided = await PlanProposalStore.decided(today);
      final replan = await _replanIfNeeded(readiness, askFirst: askFirst);
      final replanned = replan.replanned;
      var adapted = const <AdaptationResult>[];
      ReadinessProposal? proposal;
      if (!askFirst) {
        adapted = await _apply(today, readiness, replanned: replanned);
      } else if (!decided) {
        final changes = await adaptation.previewDay(readiness);
        if (changes.isNotEmpty || replan.pending != null) {
          proposal = ReadinessProposal(
            day: today,
            readiness: readiness,
            changes: changes,
            replanReason: replan.pending,
          );
          log(
            '[Readiness] proposal: ${changes.length} changes, '
            'replan=${replan.pending}',
          );
        }
      }
      if (replanned != null && askFirst) {
        // Changed goals or schedule were applied at once; the watch follows.
        await _pushAdaptedSessions(today, const []);
        await _pushAdaptedSessions(
          today.add(const Duration(days: 1)),
          const [],
        );
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
      state = MorningAdaptationState(
        notification: notification,
        proposal: proposal,
      );
    } catch (e) {
      log('[Readiness] morning adaptation error: $e');
      state = const MorningAdaptationState();
    }
  }

  /// Applies readiness to today's sessions, releases what it cancels and
  /// brings the watches in line.
  Future<List<AdaptationResult>> _apply(
    DateTime today,
    ReadinessResult readiness, {
    String? replanned,
  }) async {
    final adapted = await _ref
        .read(sessionAdaptationServiceProvider)
        .adaptDay(readiness);
    // A session the readiness released leaves the watch calendar too.
    final actions = _ref.read(planSessionActionsProvider);
    for (final a in adapted) {
      if (a.session.status == 'skipped') {
        await actions.releaseDeliveries(a.session);
      }
    }
    if (adapted.any((a) => a.adapted)) {
      await _pushAdaptedSessions(today, adapted);
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (replanned != null) {
      await _pushAdaptedSessions(today, const []);
      await _pushAdaptedSessions(tomorrow, const []);
    } else if (readiness.level != ReadinessLevel.green) {
      await _pushAdaptedSessions(tomorrow, const []);
    }
    return adapted;
  }

  /// The athlete agreed: today's changes and the replan are applied.
  Future<void> accept() async {
    final p = state.proposal;
    if (p == null) return;
    state = MorningAdaptationState(notification: state.notification);
    await PlanProposalStore.decide(p.day);
    String? replanned;
    if (p.replanReason case final reason?) {
      final plan = await _activePlan();
      if (plan != null) replanned = await _replanNow(plan.id, reason);
    }
    await _apply(p.day, p.readiness, replanned: replanned);
    _ref.invalidate(upcomingSessionsProvider);
    log('[Readiness] proposal accepted');
  }

  /// The athlete keeps the plan as it is today.
  Future<void> decline() async {
    final p = state.proposal;
    if (p == null) return;
    state = MorningAdaptationState(notification: state.notification);
    await PlanProposalStore.decide(p.day);
    log('[Readiness] proposal declined');
  }

  /// Re-pushes the day's adapted sessions so every platform that takes
  /// workouts shows the new targets.
  Future<void> _pushAdaptedSessions(
    DateTime day,
    List<AdaptationResult> adapted,
  ) async {
    try {
      // Changed sessions go to a watch by themselves only where Fjelia can
      // send them.
      final pushers = await _ref.read(pushProvidersProvider.future);
      if (pushers.isEmpty) return;
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
        for (final p in pushers) {
          if (s.status != 'adapted' && await p.hasDelivered(s)) continue;
          try {
            await plans.deliver(s.id, p);
          } catch (e) {
            log('[Readiness] ${p.label} push failed for ${s.id}: $e');
          }
        }
      }
    } catch (e) {
      log('[Readiness] push sessions error: $e');
    }
  }

  Future<TrainingPlan?> _activePlan() {
    final db = _ref.read(databaseProvider);
    return (db.select(db.trainingPlans)
          ..where((t) => t.athleteId.equals('self') & t.status.equals('active'))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Replans when last week's load jumped >15 % or HRV is >10 % suppressed.
  /// [replanned] is the reason when a replan happened. With [askFirst] a
  /// replan for a trend alone waits as [pending]; changed goals or schedule
  /// are the athlete's own decision and apply at once.
  Future<({String? replanned, String? pending})> _replanIfNeeded(
    ReadinessResult readiness, {
    bool askFirst = false,
  }) async {
    const none = (replanned: null, pending: null);
    final db = _ref.read(databaseProvider);
    final plan = await _activePlan();
    if (plan == null) return none;
    // New or changed goals are not a trend to wait out: the plan is rebuilt
    // for them at once, whatever the last replan was.
    final goals = await _ref.read(raceGoalServiceProvider).resolveGoalSet();
    if (goals.isEmpty) {
      // Nothing left to prepare for: the plan ends, with no rebuild.
      await _ref.read(trainingPlanServiceProvider).endPlan(plan.id);
      return (replanned: 'No goals left', pending: null);
    }
    final goalsChanged = goalSetChanged(
      planRevision: plan.goalSetRevision,
      goals: goals,
    );
    // A different weekly schedule is the athlete's own decision: the plan
    // follows it at once, like changed goals.
    final profile0 = _ref.read(userProfileProvider).valueOrNull;
    final schedule =
        profile0 != null &&
        scheduleChanged(
          planRestDaysJson: plan.restDaysJson,
          planStrengthDaysJson: plan.strengthDaysJson,
          restDays: profile0.restDays,
          strengthDays: profile0.preferredStrengthDays,
        );
    // Don't replan more than once every 3 days.
    final last = plan.lastReplannedAt;
    if (!goalsChanged &&
        !schedule &&
        last != null &&
        DateTime.now().difference(last).inDays < 3) {
      return none;
    }

    // Two completed weeks only: the plan also holds summaries of future weeks
    // and the running week, which say nothing about what was done.
    final now = DateTime.now();
    final thisWeek = weekStartOf(DateTime(now.year, now.month, now.day));
    final weeks =
        await (db.select(db.weekSummaries)
              ..where(
                (t) =>
                    t.athleteId.equals('self') &
                    t.weekStart.isSmallerThanValue(thisWeek),
              )
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

    final reasons = <String>[
      if (goalsChanged) 'Your goals changed',
      if (schedule) 'Your weekly schedule changed',
    ];
    if (weeks.length == 2) {
      final jump = zoneTimeJump(nts(weeks[0]), nts(weeks[1]));
      if (jump != null) {
        reasons.add('Zone time +${jump.round()}% vs the week before');
      }
    }
    // One poor night is not a trend: HRV must be low on two nights running.
    final yesterday = await db.getHrvForDate(
      DateTime(now.year, now.month, now.day - 1),
    );
    if (hrvSuppressed([
      readiness.hrvToday,
      yesterday?.hrvLastNight,
    ], readiness.hrvBaseline)) {
      reasons.add('HRV suppressed >10% on two nights');
    }
    if (reasons.isEmpty) return none;

    final reason = reasons.join(' + ');
    if (askFirst && !goalsChanged && !schedule) {
      return (replanned: null, pending: reason);
    }
    return (replanned: await _replanNow(plan.id, reason), pending: null);
  }

  /// Rebuilds the plan for [reason]; the reason when it worked.
  Future<String?> _replanNow(String planId, String reason) async {
    log('[Readiness] replanning — $reason');
    try {
      final profile = _ref.read(userProfileProvider).valueOrNull;
      await _ref
          .read(trainingPlanServiceProvider)
          .replan(
            planId: planId,
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
