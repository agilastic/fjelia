import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/plan_week_context.dart';
import '../services/pro_analysis.dart';
import '../services/season_context.dart';
import '../services/sport_stats.dart';
import 'ai_coach_provider.dart';
import 'database_provider.dart';
import 'fjelia_pro_provider.dart';
import 'sport_stats_provider.dart';
import 'user_profile_provider.dart';

/// The stored analysis for an id ([ProAnalysisRef.id]), or null.
final proReportProvider = StreamProvider.autoDispose.family<ProReport?, String>(
  (ref, id) => ref.watch(databaseProvider).watchProReport(id),
);

final proAnalysisActionsProvider = Provider(ProAnalysisActions.new);

/// Writes a FjeliaPro analysis with the large model and keeps it. The
/// screen asks for the athlete's consent first, as the chat does.
class ProAnalysisActions {
  ProAnalysisActions(this.ref);
  final Ref ref;

  Future<ProReport> generate(ProAnalysisRef analysis) async {
    if (!proAnalysisPrompts.isAvailable) {
      throw StateError('FjeliaPro analyses are not part of this build.');
    }
    final now = ref.read(proClockProvider)();
    final profile = await ref.read(userProfileProvider.future);
    final general = await ref
        .read(toonCacheProvider.notifier)
        .getOrBuild(null, profile.raceGoals ?? '', null);
    // The plan of the last days as it went: the general context lists only
    // the coming sessions.
    final week = switch (analysis.kind) {
      ProAnalysisKind.planCheck || ProAnalysisKind.weekReview =>
        await planWeekLines(ref.read(databaseProvider), now),
      // The season by weeks: the build until the last goal and the real
      // training behind it, plus the last month as it went.
      ProAnalysisKind.season => [
        ...await seasonCheckLines(ref.read(databaseProvider)),
        ...sportStatsLines(await ref.read(sportStatsProvider.future), now),
        ...await seasonWeekLines(ref.read(databaseProvider), now),
        ...await planWeekLines(ref.read(databaseProvider), now, days: 28),
      ],
      ProAnalysisKind.racePlan => [
        ...sportStatsLines(await ref.read(sportStatsProvider.future), now),
        ...await seasonWeekLines(ref.read(databaseProvider), now),
      ],
    };
    final toon = [general, ...week].join('\n');
    final answer = await ref
        .read(aiCoachClientProvider)
        .sendProAnalysis(
          proAnalysisInstructions(analysis),
          proAnalysisRequest(analysis, now),
          toon,
          // The daily ones on the quick model; only the race plan and the
          // season, a few times a month, on the larger one.
          deep:
              analysis.kind == ProAnalysisKind.racePlan ||
              analysis.kind == ProAnalysisKind.season,
        );
    final report = ProReport(
      id: analysis.id,
      kind: analysis.kind.name,
      refKey: analysis.key,
      body: answer.text,
      model: answer.model,
      createdAt: now,
    );
    await ref.read(databaseProvider).saveProReport(report);
    return report;
  }
}
