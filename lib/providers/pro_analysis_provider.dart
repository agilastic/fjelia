import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/plan_week_context.dart';
import '../services/pro_analysis.dart';
import '../services/season_context.dart';
import '../services/sport_stats.dart';
import '../services/weekly_review_scheduler.dart';
import 'ai_coach_provider.dart';
import 'database_provider.dart';
import 'fjelia_edition_provider.dart';
import 'hrv_reminder_provider.dart' show localNotificationGatewayProvider;
import 'fjelia_pro_provider.dart';
import 'sport_stats_provider.dart';
import 'training_load_provider.dart' show effectiveLoad;
import 'user_profile_provider.dart';

/// The stored analysis for an id ([ProAnalysisRef.id]), or null.
final proReportProvider = StreamProvider.autoDispose.family<ProReport?, String>(
  (ref, id) => ref.watch(databaseProvider).watchProReport(id),
);

final proAnalysisActionsProvider = Provider(ProAnalysisActions.new);

/// What a week held: the figures beside its review.
typedef WeekFigures = ({int sessions, int minutes, double km, double load});

/// The activities of the seven days from [start].
final weekFiguresProvider = FutureProvider.autoDispose
    .family<WeekFigures, DateTime>((ref, start) async {
      final db = ref.watch(databaseProvider);
      final end = DateTime(start.year, start.month, start.day + 7);
      final rows =
          await (db.select(db.activityRecords)..where(
                (t) =>
                    t.startDate.isBiggerOrEqualValue(start) &
                    t.startDate.isSmallerThanValue(end),
              ))
              .get();
      return (
        sessions: rows.length,
        minutes: rows.fold(0, (a, r) => a + r.durationSeconds ~/ 60),
        km: rows.fold(0.0, (a, r) => a + (r.distanceMeters ?? 0) / 1000),
        load: rows.fold(0.0, (a, r) => a + effectiveLoad(r)),
      );
    });

/// Up to five photos and videos of the week's activities, in the order the
/// activities were done: the pictures of the diary.
final weekMediaProvider = FutureProvider.autoDispose
    .family<List<MediaItem>, DateTime>((ref, start) async {
      final db = ref.watch(databaseProvider);
      final end = DateTime(start.year, start.month, start.day + 7);
      final activities =
          await (db.select(db.activityRecords)
                ..where(
                  (t) =>
                      t.startDate.isBiggerOrEqualValue(start) &
                      t.startDate.isSmallerThanValue(end),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
              .get();
      if (activities.isEmpty) return const [];
      final order = {for (final (i, a) in activities.indexed) a.activityId: i};
      final items =
          await (db.select(db.mediaItems)..where(
                (t) =>
                    t.ownerKind.equals('activity') & t.ownerId.isIn(order.keys),
              ))
              .get();
      items.sort((a, b) {
        final byActivity = order[a.ownerId]!.compareTo(order[b.ownerId]!);
        return byActivity != 0 ? byActivity : a.position.compareTo(b.position);
      });
      return items.take(5).toList();
    });

/// Whether the week review is written by itself at the start of a week.
final weeklyReviewAutoProvider = FutureProvider<bool>(
  (ref) => WeeklyReviewSettings.auto(),
);

/// Every stored week review, newest first: the diary.
final weekReviewsProvider = FutureProvider.autoDispose<List<ProReport>>(
  (ref) => ref.watch(databaseProvider).proReportsOfKind('weekReview'),
);

/// The week review written when a week begins, with its push at 00:00.
final weeklyReviewSchedulerProvider = Provider(
  (ref) => WeeklyReviewScheduler(
    db: ref.watch(databaseProvider),
    gateway: ref.watch(localNotificationGatewayProvider),
    generate: (analysis) =>
        ref.read(proAnalysisActionsProvider).generate(analysis),
    isPro: () =>
        ref.read(fjeliaEditionProvider).isPro && proAnalysisPrompts.isAvailable,
    mondayFirst: () async =>
        (await ref.read(userProfileProvider.future)).weekStartsOnMonday,
  ),
);

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
        await planWeekLines(ref.read(databaseProvider), analysis.until ?? now),
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
    if (analysis.kind == ProAnalysisKind.weekReview) {
      ref.invalidate(weekReviewsProvider);
    }
    return report;
  }
}
