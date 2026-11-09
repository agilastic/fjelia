import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/formats.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../services/coach_language.dart';
import '../services/daily_readiness_service.dart';
import '../services/morning_revision.dart';
import '../services/plan_week_context.dart';
import '../services/strength/strength_repository.dart'
    show StoredStrengthPlan, StrengthPlanOwner;
import '../services/pro_analysis.dart' show proAnalysisPrompts;
import '../services/plan_proposal_notifications.dart';
import '../services/plan_proposal_store.dart';
import '../utils/log.dart';
import 'ai_coach_provider.dart';
import 'database_provider.dart';
import 'day_data_provider.dart' show activityListProvider;
import 'fjelia_edition_provider.dart';
import 'hrv_reminder_provider.dart';
import 'missed_workout_provider.dart';
import 'plan_week_provider.dart' show PlanWeekItem, weekStartFor;
import 'planner_providers.dart';
import 'readiness_provider.dart';
import 'strength_provider.dart' show strengthRepositoryProvider;
import 'user_profile_provider.dart';

/// Whether the app is in front; set by the app's lifecycle.
final appInForegroundProvider = StateProvider<bool>((ref) => true);

final planProposalNotificationsProvider = Provider(
  (ref) => PlanProposalNotifications(
    ref.watch(localNotificationGatewayProvider),
    ref.watch(missedWorkoutReminderProvider),
  ),
);

/// Ask before readiness changes the day or a trend rebuilds the plan.
final askBeforePlanChangesProvider =
    AsyncNotifierProvider<AskBeforePlanChangesNotifier, bool>(
      AskBeforePlanChangesNotifier.new,
    );

class AskBeforePlanChangesNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => PlanProposalStore.askFirst();

  Future<void> set(bool value) async {
    await PlanProposalStore.setAskFirst(value);
    state = AsyncData(value);
  }
}

/// FjeliaPro: the coach writes the morning push (on by default for Pro).
final proposalProCoachProvider =
    AsyncNotifierProvider<ProposalProCoachNotifier, bool>(
      ProposalProCoachNotifier.new,
    );

class ProposalProCoachNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => PlanProposalStore.proCoach();

  Future<void> set(bool value) async {
    await PlanProposalStore.setProCoach(value);
    state = AsyncData(value);
  }
}

/// Builds what the coach may work with on [day]: the week's sessions, the
/// strength plans of the day and Settings → Training.
final revisionContextProvider = Provider(
  (ref) => (DateTime day, ReadinessResult readiness) async {
    final db = ref.read(databaseProvider);
    final profile = await ref.read(userProfileProvider.future);
    final start = weekStartFor(day, mondayFirst: profile.weekStartsOnMonday);
    final week =
        await (db.select(db.trainingSessions)
              ..where(
                (t) =>
                    t.athleteId.equals('self') &
                    t.sessionDate.isBiggerOrEqualValue(start) &
                    // The week, and the day after when the day is the
                    // week's last.
                    t.sessionDate.isSmallerThanValue(
                      DateTime(
                            day.year,
                            day.month,
                            day.day + 2,
                          ).isAfter(start.add(const Duration(days: 7)))
                          ? DateTime(day.year, day.month, day.day + 2)
                          : start.add(const Duration(days: 7)),
                    ),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.sessionDate),
                (t) => OrderingTerm.asc(t.sessionNumber),
              ]))
            .get();
    final strength = ref.read(strengthRepositoryProvider);
    final plans = <String, StoredStrengthPlan>{};
    for (final s in week) {
      final next = DateTime(day.year, day.month, day.day + 1);
      bool on(DateTime d) =>
          s.sessionDate.year == d.year &&
          s.sessionDate.month == d.month &&
          s.sessionDate.day == d.day;
      if (!isStrengthSession(s) || !(on(day) || on(next))) continue;
      try {
        final plan = await strength.loadPlan(StrengthPlanOwner.session(s.id));
        if (plan != null) plans[s.id] = plan;
      } catch (e) {
        log('[PlanProposal] strength plan ${s.id}: $e');
      }
    }
    return RevisionContext(
      day: day,
      week: week,
      restWeekdays: profile.restDays,
      strengthWeekdays: profile.preferredStrengthDays,
      maxPerDay: profile.maxSessionsPerDay,
      strengthPlans: plans,
      readinessLevel: readiness.level.name,
      reason: readiness.adaptationReason,
    );
  },
);

/// The coach's checked revision of [day] with what it was checked against,
/// or null when there is none (not Pro, or the rules' proposal stands).
final coachRevisionProvider = FutureProvider.autoDispose
    .family<({MorningRevision revision, RevisionContext context})?, DateTime>((
      ref,
      day,
    ) async {
      final raw = await PlanProposalStore.revision(day);
      if (raw == null) return null;
      final r = parseMorningRevision(raw);
      final p = ref.watch(morningAdaptationProvider).proposal;
      if (r == null || p == null || p.day != day) return null;
      final c = await ref.read(revisionContextProvider)(day, p.readiness);
      // The plan may have changed since the coach answered.
      final checked = checkedRevision(r, c);
      if (checked == null) return null;
      return (revision: checked, context: c);
    });

/// Sessions of the last two days still open and not answered, latest first.
final pastMissedProvider =
    FutureProvider.autoDispose<
      List<({DateTime day, List<PlanWeekItem> items})>
    >((ref) {
      // A synced workout or a moved session changes what is still open.
      ref.watch(upcomingSessionsProvider);
      ref.watch(activityListProvider);
      return ref.watch(missedWorkoutReminderProvider).pastMissed();
    });

/// The readiness proposal in words, for a notification ([tr], the saved
/// language) or a card ([l10n] of the screen).
ProposalText readinessProposalText(
  ReadinessProposal p, [
  AppLocalizations? l10n,
]) {
  final tr = l10n ?? _tr;
  final rest = p.changes.any((c) => c.rest);
  final title = p.changes.isEmpty
      ? tr.proposalReplanTitle
      : rest
      ? tr.proposalRestTitle
      : p.readiness.level == ReadinessLevel.red
      ? tr.proposalRecoveryTitle
      : tr.proposalEasierTitle;
  final lines = [
    for (final c in p.changes)
      c.rest
          ? tr.proposalDropsLine(c.session.title)
          : tr.proposalChangeLine(
              '${c.session.title} (${planDuration(c.session.plannedDurationMin)})',
              '${c.title} (${planDuration(c.durationMin)})',
            ),
    if (p.replanReason != null) tr.proposalReplanBody,
  ];
  return (day: p.day, title: title, body: lines.join('\n'));
}

/// Hooks for the app's lifecycle and the end of a sync.
final planProposalLifecycleProvider = Provider(PlanProposalLifecycle.new);

class PlanProposalLifecycle {
  PlanProposalLifecycle(this.ref);
  final Ref ref;

  Future<void> background() async {
    ref.read(appInForegroundProvider.notifier).state = false;
    try {
      await ref.read(planProposalNotificationsProvider).onBackground();
    } catch (e) {
      log('[PlanProposal] background: $e');
    }
  }

  /// After the morning check of a full sync: today's proposal becomes one
  /// push 10 to 20 minutes later. FjeliaPro with the coach switch on lets
  /// the coach rework the session (or swap it within the week) and word the
  /// push; otherwise, or when its answer does not pass the checks, the
  /// rules' proposal and text.
  Future<void> morning() async {
    final p = ref.read(morningAdaptationProvider).proposal;
    if (p == null) return;
    try {
      if (await PlanProposalStore.notifiedAt(
            PlanProposalNotifications.readinessKey(p.day),
          ) !=
          null) {
        return;
      }
      final text = await _coachRevision(p) ?? readinessProposalText(p);
      await ref.read(planProposalNotificationsProvider).scheduleMorning(text);
    } catch (e) {
      log('[PlanProposal] morning: $e');
    }
  }

  /// Settings → System → Debug: the whole morning flow now, on today or the
  /// next day with sessions, with readiness taken as yellow. The push comes
  /// a few seconds later, whatever the time of day.
  Future<String> testMorning() async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? day;
    for (var i = 0; i < 7 && day == null; i++) {
      final d = today.add(Duration(days: i));
      final open =
          await (db.select(db.trainingSessions)..where(
                (t) =>
                    t.athleteId.equals('self') &
                    t.sessionDate.isBiggerOrEqualValue(d) &
                    t.sessionDate.isSmallerThanValue(
                      d.add(const Duration(days: 1)),
                    ) &
                    t.status.isIn(const ['planned', 'adapted']),
              ))
              .get();
      if (open.isNotEmpty) day = d;
    }
    if (day == null) return 'No planned session in the next 7 days.';
    const readiness = ReadinessResult(
      level: ReadinessLevel.yellow,
      flagCount: 2,
      hrvLow: true,
    );
    final changes = await ref
        .read(sessionAdaptationServiceProvider)
        .previewDay(readiness, day: day);
    final p = ReadinessProposal(
      day: day,
      readiness: readiness,
      changes: changes,
    );
    ref.read(morningAdaptationProvider.notifier).debugPropose(p);
    final key = PlanProposalNotifications.readinessKey(day);
    await PlanProposalStore.forget(key);
    await PlanProposalStore.clearRevision();
    final coach = await _coachRevision(p);
    final text = coach ?? readinessProposalText(p);
    await ref
        .read(planProposalNotificationsProvider)
        .scheduleTest(text, const Duration(seconds: 5));
    return coach == null
        ? 'Rules proposal for ${DateFormat('E d MMM').format(day)}, push in 5 s.'
        : 'Coach revision for ${DateFormat('E d MMM').format(day)}, push in 5 s.';
  }

  /// FjeliaPro: the coach's revision of [p]'s day, checked and kept for the
  /// sheet; its title and body are the push. Null when not Pro, switched
  /// off, or the answer fails a check.
  Future<ProposalText?> _coachRevision(ReadinessProposal p) async {
    if (!ref.read(fjeliaEditionProvider).isPro ||
        !proAnalysisPrompts.isAvailable ||
        !await PlanProposalStore.proCoach()) {
      return null;
    }
    try {
      final c = await ref.read(revisionContextProvider)(p.day, p.readiness);
      if (c.today.isEmpty) return null;
      final profile = await ref.read(userProfileProvider.future);
      final general = await ref
          .read(toonCacheProvider.notifier)
          .getOrBuild(null, profile.raceGoals ?? '', null);
      // The last 7 days as they went: done, missed and why, moved, extra.
      final toon = [
        general,
        ...await planWeekLines(ref.read(databaseProvider), p.day),
      ].join('\n');
      final answer = await ref
          .read(aiCoachClientProvider)
          .sendProAnalysis(
            '${proAnalysisPrompts.morningRevision}\n${coachLanguageDirective()}',
            'QUESTION: ${revisionInputJson(c)}',
            toon,
            deep: false,
          )
          .timeout(const Duration(seconds: 40));
      final parsed = parseMorningRevision(answer.text);
      final r = parsed == null
          ? null
          : checkedRevision(
              parsed,
              c,
              log: (problem) =>
                  log('[PlanProposal] coach revision refused: $problem'),
            );
      if (r == null) {
        if (parsed == null) log('[PlanProposal] coach revision unreadable');
        final text = answer.text;
        log(
          '[PlanProposal] coach answer: '
          '${text.length > 800 ? '${text.substring(0, 800)}…' : text}',
        );
        return null;
      }
      await PlanProposalStore.saveRevision(p.day, answer.text);
      ref.invalidate(coachRevisionProvider(p.day));
      return (day: p.day, title: r.title, body: r.body);
    } catch (e) {
      log('[PlanProposal] coach revision failed, rules: $e');
      return null;
    }
  }

  /// The coach's revision was taken: it is written (not sent to a watch)
  /// and the day's proposal is answered.
  Future<void> acceptRevision(DateTime day, {bool alternative = false}) async {
    final r = await ref.read(coachRevisionProvider(day).future);
    if (r == null) return;
    final chosen = alternative ? r.revision.alternative : r.revision;
    if (chosen == null) return;
    await applyMorningRevision(
      ref.read(databaseProvider),
      ref.read(strengthRepositoryProvider),
      chosen,
      r.context,
    );
    await PlanProposalStore.clearRevision();
    ref.invalidate(coachRevisionProvider(day));
    await ref.read(morningAdaptationProvider.notifier).acceptedElsewhere();
    await PlanProposalStore.decide(day);
    await ref
        .read(planProposalNotificationsProvider)
        .resolved(PlanProposalNotifications.readinessKey(day));
  }

  Future<void> foreground() async {
    ref.read(appInForegroundProvider.notifier).state = true;
    try {
      await ref.read(planProposalNotificationsProvider).onForeground();
    } catch (e) {
      log('[PlanProposal] foreground: $e');
    }
  }

  /// A sync that ended while the app was in the background may have found
  /// something to ask.
  Future<void> afterSync() async {
    if (!ref.read(appInForegroundProvider)) await background();
  }

  /// The readiness proposal was answered here or from its notification.
  Future<void> answerReadiness({required bool accept}) async {
    if (!accept) await PlanProposalStore.clearRevision();
    final n = ref.read(morningAdaptationProvider.notifier);
    final day = ref.read(morningAdaptationProvider).proposal?.day;
    accept ? await n.accept() : await n.decline();
    if (day != null) {
      await ref
          .read(planProposalNotificationsProvider)
          .resolved(PlanProposalNotifications.readinessKey(day));
    }
  }

  /// "Keep plan" from the notification; the app may not have the proposal
  /// in memory yet after a cold start.
  Future<void> keepFromNotification(DateTime day) async {
    if (ref.read(morningAdaptationProvider).proposal?.day == day) {
      await answerReadiness(accept: false);
    } else {
      await PlanProposalStore.decide(day);
    }
  }

  /// A missed day the athlete leaves as it is.
  Future<void> leaveMissed(DateTime day) async {
    await ref.read(missedWorkoutReminderProvider).acknowledge(day);
    await ref
        .read(planProposalNotificationsProvider)
        .resolved(PlanProposalNotifications.missedKey(day));
    ref.invalidate(pastMissedProvider);
  }
}

AppLocalizations get _tr => tr;

/// The coach's two lines as a push: a short title, then the body. Null when
/// the answer does not have that shape.
ProposalText? parseMorningPush(String raw, DateTime day) {
  final lines = [
    for (final l in raw.split('\n'))
      if (l.trim().replaceAll(RegExp(r'^[#*"\s]+|[*"\s]+$'), '') case final t
          when t.isNotEmpty)
        t,
  ];
  if (lines.length < 2) return null;
  final title = lines.first, body = lines.skip(1).join(' ');
  if (title.length > 60 || body.length > 240) return null;
  return (day: day, title: title, body: body);
}
