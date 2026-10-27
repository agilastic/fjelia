import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart' show StrengthProposalDecisionRow;
import '../models/strength_workout.dart';
import '../services/strength/strength_repository.dart';
import 'database_provider.dart';
import 'user_profile_provider.dart';

final strengthRepositoryProvider = Provider(
  (ref) => StrengthRepository(ref.watch(databaseProvider)),
);

/// The athlete's display unit for loads; stored loads stay in kg.
final massUnitProvider = Provider<MassUnit>(
  (ref) => MassUnit.parse(ref.watch(userProfileProvider).valueOrNull?.massUnit),
);

final strengthPlanProvider = FutureProvider.autoDispose
    .family<StoredStrengthPlan?, StrengthPlanOwner>(
      (ref, owner) => ref.watch(strengthRepositoryProvider).loadPlan(owner),
    );

final strengthLogProvider = FutureProvider.autoDispose
    .family<StrengthActivityLog?, String>(
      (ref, id) => ref.watch(strengthRepositoryProvider).loadLog(id),
    );

/// The session explicitly linked to an activity; null without a link.
final strengthLinkedSessionProvider = FutureProvider.autoDispose
    .family<String?, String>(
      (ref, id) => ref.watch(strengthRepositoryProvider).linkedSessionId(id),
    );

/// Latest comparable history of an exercise context before a date, leaving
/// out one activity (the one being logged).
final strengthHistoryProvider = FutureProvider.autoDispose
    .family<
      StrengthHistoryEntry?,
      ({String contextKey, DateTime before, String? exclude})
    >(
      (ref, q) => ref
          .watch(strengthRepositoryProvider)
          .recentComparableHistory(
            q.contextKey,
            before: q.before,
            excludeActivityId: q.exclude,
          ),
    );

/// The latest comparable sessions for the progression rule, newest first.
final strengthRecentSessionsProvider = FutureProvider.autoDispose
    .family<List<StrengthHistoryEntry>, ({String contextKey, DateTime before})>(
      (ref, q) => ref
          .watch(strengthRepositoryProvider)
          .recentComparableSessions(q.contextKey, before: q.before),
    );

/// Decisions on load proposals for one planned workout, by fingerprint.
final strengthProposalDecisionsProvider = FutureProvider.autoDispose
    .family<Map<String, StrengthProposalDecisionRow>, StrengthPlanOwner>(
      (ref, owner) =>
          ref.watch(strengthRepositoryProvider).proposalDecisions(owner),
    );

/// An unfinished gym-mode workout of a planned workout, to resume.
final strengthLiveSessionProvider = FutureProvider.autoDispose
    .family<StrengthActivityLog?, StrengthPlanOwner>(
      (ref, owner) =>
          ref.watch(strengthRepositoryProvider).openLiveSession(owner),
    );

/// Every logged session of one exercise context, newest first, for its
/// trend.
final strengthTrendSessionsProvider = FutureProvider.autoDispose
    .family<List<StrengthHistoryEntry>, String>(
      (ref, contextKey) => ref
          .watch(strengthRepositoryProvider)
          .recentComparableSessions(
            contextKey,
            before: DateTime.now().add(const Duration(days: 1)),
            limit: 52,
          ),
    );

final strengthIncrementProvider = FutureProvider.autoDispose
    .family<StrengthLoad?, String>(
      (ref, key) => ref.watch(strengthRepositoryProvider).increment(key),
    );

final strengthCustomVariantsProvider =
    FutureProvider.autoDispose<List<StrengthExerciseVariant>>(
      (ref) => ref.watch(strengthRepositoryProvider).customVariants(),
    );

final strengthTemplatesProvider =
    FutureProvider.autoDispose<List<StoredStrengthPlan>>(
      (ref) => ref.watch(strengthRepositoryProvider).templates(),
    );

/// Drops every cached strength read, after a restore, reset or deletion.
/// Takes `ref.invalidate` of a provider or widget ref.
void invalidateStrength(void Function(ProviderOrFamily) invalidate) {
  for (final p in <ProviderOrFamily>[
    strengthPlanProvider,
    strengthLogProvider,
    strengthLinkedSessionProvider,
    strengthHistoryProvider,
    strengthRecentSessionsProvider,
    strengthProposalDecisionsProvider,
    strengthLiveSessionProvider,
    strengthTrendSessionsProvider,
    strengthIncrementProvider,
    strengthCustomVariantsProvider,
    strengthTemplatesProvider,
  ]) {
    invalidate(p);
  }
}
