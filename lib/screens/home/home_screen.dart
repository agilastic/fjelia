import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ai_coach_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/visibility_provider.dart';
import '../../providers/body_measurements_provider.dart';
import '../../providers/grip_strength_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/history_sync_card.dart';
import '../../widgets/day_navigator.dart';
import '../../widgets/plan_view_switcher.dart';
import '../../widgets/spinning_sync_icon.dart';
import '../../widgets/day_summary_card.dart';
import '../../widgets/health_monitor_grid.dart';
import '../../widgets/hr_timeline_card.dart';
import '../../widgets/grip_strength_sheet.dart';
import '../../widgets/bio_age_card.dart';
import '../../widgets/briefing_card.dart';
import '../settings/settings_sheet.dart';
import '../settings/bug_report_sheet.dart';
import '../ocr/manual_entry_sheet.dart';
import '../bloodpressure/bp_screen.dart';
import '../renpho/renpho_screen.dart';
import '../planner/plan_screen.dart';
import '../strain/strain_screen.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../debug/debug_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  int tab = 0;

  /// The session the coach tab was last opened for.
  CoachRequest? coachRequest;
  @override
  Widget build(BuildContext context) {
    // "Ask the coach about this session" from anywhere in the app: show the
    // coach tab with that session loaded.
    ref.listen<CoachRequest?>(coachRequestProvider, (previous, next) {
      if (next == null) return;
      setState(() {
        coachRequest = next;
        tab = 3;
      });
      ref.read(coachRequestProvider.notifier).state = null;
    });
    final sync = ref.watch(syncProvider),
        debug = ref.watch(userProfileProvider).valueOrNull?.debugMode ?? false;
    final current = tab == 4 && !debug ? 0 : tab;
    return Scaffold(
      extendBody: current < 3,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.menu, size: 20, color: muted),
                onPressed: () => SettingsSheet.show(context),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: current == 1
                      ? const PlanViewSwitcher()
                      : const DayNavigator(),
                ),
              ),
              IconButton(
                tooltip: 'Send feedback or report a bug',
                icon: const Icon(
                  Icons.feedback_outlined,
                  size: 20,
                  color: muted,
                ),
                onPressed: () =>
                    showAppSheet(context, const BugReportSheet()),
              ),
              IconButton(
                tooltip: 'Add measurement',
                icon: const Icon(Icons.add, size: 20, color: muted),
                onPressed: () =>
                    showAppSheet(context, const ManualEntrySheet()),
              ),
              PopupMenuButton<String>(
                tooltip: 'Sync',
                icon: SpinningSyncIcon(
                  spinning:
                      sync.status == SyncStatus.syncing ||
                      ref.watch(historicSyncProvider).running,
                  color: sync.status == SyncStatus.syncing ? mint : muted,
                ),
                onSelected: (choice) => runUiAction(context, () async {
                  if (choice == 'today') {
                    await ref.read(syncProvider.notifier).sync();
                  } else {
                    await ref
                        .read(historicSyncProvider.notifier)
                        .start(
                          days: choice == 'year' ? 365 : 3650,
                          force: true,
                        );
                  }
                }),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'today', child: Text('Sync Today')),
                  PopupMenuItem(
                    value: 'year',
                    child: Text('Full Sync · 1 year'),
                  ),
                  PopupMenuItem(
                    value: 'all',
                    child: Text('Full Sync · Complete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (sync.status == SyncStatus.syncing) ...[
            LinearProgressIndicator(value: sync.progress / 100),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Syncing your data…',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ),
            ),
          ],
          const HistorySyncCard(),
          if (sync.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                sync.errorMessage!,
                style: const TextStyle(color: Colors.orange, fontSize: 11),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(syncProvider.notifier).sync(),
              child: switch (current) {
                0 => _HealthPage(
                  openCoach: () => setState(() => tab = 3),
                  openLoad: () => setState(() => tab = 2),
                ),
                1 => const PlanScreen(),
                2 => const StrainScreen(embedded: true),
                3 => AiCoachScreen(
                  key: ValueKey(coachRequest?.id ?? 0),
                  initialPrompt: coachRequest?.prompt,
                  activity: coachRequest?.activity,
                  contextCard: coachRequest?.card,
                ),
                _ => const DebugScreen(),
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: .5,
                  widthFactor: 1,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: .55),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: (MediaQuery.viewPaddingOf(context).bottom - 12)
                  .clamp(8.0, double.infinity)
                  .toDouble(),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: panel.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Row(
                children: [
                  for (final e in <(String, IconData)>[
                    ('HEALTH', Icons.favorite_border),
                    ('PLAN', Icons.calendar_month_outlined),
                    ('LOAD', Icons.bar_chart),
                    ('COACH', Icons.smart_toy_outlined),
                    if (debug) ('DEBUG', Icons.bug_report_outlined),
                  ].indexed)
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => tab = e.$1),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: current == e.$1
                                ? mint.withValues(alpha: .13)
                                : null,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (e.$2.$1 != 'DEBUG') ...[
                                Icon(
                                  e.$2.$2,
                                  color: current == e.$1 ? mint : muted,
                                  size: 20,
                                ),
                                const SizedBox(height: 3),
                              ] else
                                const SizedBox(height: 12),
                              Text(
                                e.$2.$1,
                                style: TextStyle(
                                  color: current == e.$1 || e.$2.$1 == 'DEBUG'
                                      ? mint
                                      : muted,
                                  fontSize: e.$2.$1 == 'DEBUG' ? 13 : 11,
                                  fontWeight:
                                      current == e.$1 || e.$2.$1 == 'DEBUG'
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              if (e.$2.$1 == 'DEBUG')
                                const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthPage extends ConsumerWidget {
  const _HealthPage({required this.openCoach, required this.openLoad});
  final VoidCallback openCoach, openLoad;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vis = ref.watch(healthVisibilityProvider).valueOrNull ?? {};
    final date = ref.watch(selectedDateProvider),
        bp = ref.watch(bpSummaryForDateProvider(date)).valueOrNull,
        grip = ref.watch(latestGripStrengthProvider).valueOrNull,
        body = ref.watch(latestBodyMeasurementProvider).valueOrNull;
    final yesterdayBp = ref
        .watch(
          bpSummaryForDateProvider(
            DateTime(date.year, date.month, date.day - 1),
          ),
        )
        .valueOrNull;
    final last = ref.watch(syncProvider).lastSync;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        DaySummaryCard(openLoad: openLoad),
        BriefingCard(openCoach: openCoach),
        if (vis['health_monitor'] ?? true) const HealthMonitorGrid(),
        SectionCard(
          title: 'Blood Pressure',
          onTap: () => showAppSheet(context, const BpScreen()),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: bp == null
                            ? '—/—'
                            : '${bp.avgSystolic.round()}/${bp.avgDiastolic.round()}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text: ' mmHg',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bp == null
                          ? 'NO DATA'
                          : bp.avgSystolic >= 140
                          ? 'HIGH'
                          : bp.avgSystolic >= 120
                          ? 'ELEVATED'
                          : 'NORMAL',
                      style: TextStyle(
                        color: bp != null && bp.avgSystolic >= 140
                            ? Colors.redAccent
                            : const Color(0xFFD3E96D),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    if (bp != null && yesterdayBp != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${bp.avgSystolic < yesterdayBp.avgSystolic
                            ? '↓'
                            : bp.avgSystolic > yesterdayBp.avgSystolic
                            ? '↑'
                            : '→'} vs. yesterday',
                        style: const TextStyle(color: muted, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        if (vis['hr_timeline'] ?? true) const HrTimelineCard(),
        if (vis['grip_strength'] ?? true)
          SectionCard(
            title: 'Grip Strength',
            onTap: () => showAppSheet(context, const GripStrengthSheet()),
            child: Text(
              'L ${valueText(grip?.leftKg, 1)}  R ${valueText(grip?.rightKg, 1)} kg',
              style: const TextStyle(
                color: Colors.lightBlue,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (vis['body_composition'] ?? true)
          SectionCard(
            title: 'Body Composition',
            onTap: () => showAppSheet(context, const RenphoScreen()),
            child: Text(
              '${valueText(body?.weight, 1)} kg · Fat ${valueText(body?.bodyFat, 1)}% · Muscle ${valueText(body?.muscleMass, 1)} kg',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ),
        if (vis['bio_age'] ?? true) const BioAgeCard(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            last == null
                ? 'No sync yet'
                : 'Last sync: ${dayText(last)} ${TimeOfDay.fromDateTime(last).format(context)}',
            style: const TextStyle(fontSize: 10, color: muted),
          ),
        ),
      ],
    );
  }
}
