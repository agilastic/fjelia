import '../../l10n/l10n_ext.dart';
import '../../providers/activity_history_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/day_data_provider.dart';
import '../../providers/lt2_tt_provider.dart';
import '../../widgets/app_widgets.dart';
import 'load_visuals.dart';

class Lt2TestSheet extends ConsumerStatefulWidget {
  const Lt2TestSheet({super.key});
  @override
  ConsumerState<Lt2TestSheet> createState() => _Lt2TestState();
}

class _Lt2TestState extends ConsumerState<Lt2TestSheet> {
  String? activityId;
  double warmup = 15;
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final result = ref.watch(lt2TtProvider).valueOrNull;
    final candidates = (ref.watch(loadActivitiesProvider).valueOrNull ?? [])
        .where(
          (a) =>
              a.type.toLowerCase().contains('run') &&
              a.durationSeconds >= (warmup + 30) * 60 &&
              a.metricsJson != null,
        )
        .toList();
    final selected = candidates
        .where((a) => a.activityId == activityId)
        .firstOrNull;
    final history = ref.watch(thresholdHistoryProvider).valueOrNull ?? [];
    return DefaultTabController(
      length: 3,
      child: LoadSheet(
        title: context.l10n.t30MinTimeTrialLt2,
        centerTitle: true,
        child: Column(
          children: [
            TabBar(
              labelColor: loadBlue,
              indicatorColor: loadBlue,
              dividerColor: Colors.white10,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
              tabs: [
                Tab(text: context.l10n.protocol),
                Tab(text: context.l10n.calculate),
                Tab(text: context.l10n.history2),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(context.l10n.run30MinutesAtThe),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: loadInset,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.watch_outlined, size: 18, color: muted),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.recordAsANormalOutdoor,
                                style: TextStyle(
                                  color: Color(0xFFBBBBBB),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.l10n.t50MinTotalFlatCourse,
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                      const SizedBox(height: 20),
                      for (final step in [
                        (
                          context.l10n.warmUp,
                          context.l10n.easyJogGetHrElevated,
                          '15 min',
                          mint,
                        ),
                        (
                          '30-MIN TT',
                          context.l10n.fastestSustainablePaceLikeA,
                          '30 min',
                          loadOrange,
                        ),
                        (
                          context.l10n.coolDown,
                          context.l10n.walkCardiacRecovery,
                          '5 min',
                          muted,
                        ),
                      ])
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 24,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: step.$4,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: step.$1 == 'COOL-DOWN'
                                            ? Colors.transparent
                                            : Colors.white12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    bottom: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              step.$1,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: step.$4,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            step.$3,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        step.$2,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFBBBBBB),
                                        ),
                                      ),
                                      if (step.$1 == '30-MIN TT')
                                        Padding(
                                          padding: EdgeInsets.only(top: 5),
                                          child: Text(
                                            context.l10n.doNotStartTooFast,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: muted,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 30, color: Colors.white10),
                      Text(
                        context.l10n.theAppAveragesHrAnd,
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        children: [
                          const LoadBadge('LT2', color: loadBlue),
                          const SizedBox(width: 10),
                          Text(
                            '${result?.lt2 ?? '—'} bpm',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.l10n.lt2Pace, style: loadCaption),
                                Text(
                                  result?.pace ?? '—',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32, color: Colors.white10),
                      Text(context.l10n.recalculate),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.activityRunningEnoughTimeFor,
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: selected?.activityId,
                        hint: Text(context.l10n.selectTheTtActivity),
                        items: [
                          for (final a in candidates)
                            DropdownMenuItem(
                              value: a.activityId,
                              child: Text(
                                context.l10n.nameStartdate(
                                  a.name,
                                  dayText(a.startDate),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: busy
                            ? null
                            : (v) => setState(() => activityId = v),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.l10n.warmUpBeforeTt),
                          Text(context.l10n.roundMin(warmup.round())),
                        ],
                      ),
                      Slider(
                        value: warmup,
                        min: 5,
                        max: 20,
                        divisions: 15,
                        activeColor: loadBlue,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => warmup = v),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: loadBlue,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: busy
                            ? null
                            : () async {
                                if (selected == null) {
                                  await runUiAction(
                                    context,
                                    () async => throw StateError(
                                      context.l10n.selectTheTtActivityFirst,
                                    ),
                                  );
                                  return;
                                }
                                setState(() => busy = true);
                                try {
                                  await runUiAction(context, () async {
                                    final error = await ref
                                        .read(lt2TtProvider.notifier)
                                        .calculate(
                                          selected,
                                          warmupMinutes: warmup.round(),
                                        );
                                    if (error != null) throw StateError(error);
                                  });
                                } finally {
                                  if (mounted) setState(() => busy = false);
                                }
                              },
                        child: Text(
                          busy
                              ? context.l10n.calculating
                              : context.l10n.calculateLt2,
                        ),
                      ),
                      TextButton(
                        onPressed: busy || result == null
                            ? null
                            : () => runUiAction(
                                context,
                                () => ref.read(lt2TtProvider.notifier).clear(),
                              ),
                        child: Text(
                          context.l10n.clearResults,
                          style: TextStyle(color: muted, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(context.l10n.heartRate2, style: loadLabel),
                      const SizedBox(height: 16),
                      LoadTrendChart(
                        points: [
                          for (final h in history)
                            if (h.lt2Bpm != null)
                              ChartPoint(h.date, h.lt2Bpm!.toDouble()),
                        ],
                        color: loadOrange,
                        height: 145,
                      ),
                      const SizedBox(height: 12),
                      const LoadLegend('LT2', loadOrange),
                      const SizedBox(height: 24),
                      Text(context.l10n.paceSecKmLowerIs, style: loadLabel),
                      const SizedBox(height: 16),
                      LoadTrendChart(
                        pace: true,
                        points: [
                          for (final h in history)
                            if (h.lt2PaceSec != null)
                              ChartPoint(h.date, h.lt2PaceSec!.toDouble()),
                        ],
                        color: loadOrange,
                        height: 145,
                      ),
                      const SizedBox(height: 12),
                      const LoadLegend('LT2 pace', loadOrange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
