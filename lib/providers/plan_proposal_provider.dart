import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/formats.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../services/daily_readiness_service.dart';
import '../services/plan_proposal_notifications.dart';
import '../services/plan_proposal_store.dart';
import '../utils/log.dart';
import 'day_data_provider.dart' show activityListProvider;
import 'hrv_reminder_provider.dart';
import 'missed_workout_provider.dart';
import 'plan_week_provider.dart' show PlanWeekItem;
import 'planner_providers.dart';
import 'readiness_provider.dart';

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
    final p = ref.read(morningAdaptationProvider).proposal;
    try {
      await ref
          .read(planProposalNotificationsProvider)
          .onBackground(readiness: p == null ? null : readinessProposalText(p));
    } catch (e) {
      log('[PlanProposal] background: $e');
    }
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
