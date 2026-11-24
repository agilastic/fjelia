import '../../theme/fjelia_style.dart';
import '../../l10n/l10n_ext.dart';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/build_features.dart';
import '../../providers/ai_coach_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/visibility_provider.dart';
import '../../providers/body_measurements_provider.dart';
import '../../providers/grip_strength_provider.dart';
import '../../widgets/home_sky.dart';
import '../../widgets/absence_sheet.dart' show OpenAbsenceCard;
import '../../widgets/app_widgets.dart';
import '../../widgets/history_sync_card.dart';
import '../../widgets/recording_banner.dart';
import '../../widgets/day_navigator.dart';
import '../../widgets/plan_view_switcher.dart';
import '../../widgets/sync_orb.dart';
import '../../widgets/day_summary_card.dart';
import '../../widgets/health_monitor_grid.dart';
import '../../widgets/hr_timeline_card.dart';
import '../../widgets/grip_strength_sheet.dart';
import '../../widgets/bio_age_card.dart';
import '../../widgets/briefing_card.dart';
import '../settings/settings_sheet.dart';
import '../settings/pro_coach_consent.dart';
import '../../providers/fjelia_pro_provider.dart';
import '../settings/bug_report_sheet.dart';
import '../ocr/manual_entry_sheet.dart';
import '../bloodpressure/bp_screen.dart';
import '../renpho/renpho_screen.dart';
import '../planner/plan_screen.dart';
import '../strain/strain_screen.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../debug/debug_screen.dart';
import '../../models/bp_category.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  int tab = 0;

  /// The session the coach tab was last opened for.
  CoachRequest? coachRequest;

  /// Counts new chats, so each one starts with an empty conversation.
  int coachChat = 0;

  @override
  void initState() {
    super.initState();
    // FjeliaPro: once a subscription is active (bought, restored or on
    // another device), ask once whether the coach may write the morning push.
    ref.listenManual<bool>(proSubscribedProvider, (_, subscribed) {
      if (!subscribed) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) askProCoachOnce(context, ref);
      });
    }, fireImmediately: true);
  }

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
            // The switch lives in the developer menu: without it the stored
            // setting cannot be turned off again, so it does not count.
            debug =
            developerMenuEnabled &&
            (ref.watch(userProfileProvider).valueOrNull?.debugMode ?? false);
    final current = tab == 4 && !debug ? 0 : tab;
    // The coach keeps its input at the bottom and its chat on its own: it
    // does not run under the bars.
    final glass = current != 3 && current != 4;
    final header = MediaQuery.paddingOf(context).top + _headerHeight;
    // Today's weather as a soft sky behind the top of every main tab, the
    // header included: the coach does not run under the bars, so the sky
    // sits behind the whole page and not in its body.
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
        ),
        if (current != 4)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top + 320,
            child: const HomeSkyBand(),
          ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: current < 3,
          extendBodyBehindAppBar: glass,
          // Like the tab bar: two floating pills, the content runs under them
          // and shows between them as it scrolls.
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(_headerHeight),
            child: Stack(
              children: [
                // A soft fade behind the status bar, so the clock stays
                // readable over the content. No blur: a blur cannot fade out
                // and leaves a hard edge over the sky.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.paddingOf(context).top + 30,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          // Eased, so no line shows where it ends.
                          colors: [
                            fjBackground.withValues(alpha: .7),
                            fjBackground.withValues(alpha: .45),
                            fjBackground.withValues(alpha: .15),
                            fjBackground.withValues(alpha: 0),
                          ],
                          stops: const [0, .45, .8, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                    child: Row(
                      children: [
                        // Where you are: the settings and the day (or the plan's
                        // view).
                        // Takes the room left; the actions sit at the right edge.
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _GlassPill(
                              children: [
                                IconButton(
                                  tooltip: context.l10n.settings,
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    Icons.menu,
                                    size: 20,
                                    color: muted,
                                  ),
                                  onPressed: () => SettingsSheet.show(context),
                                ),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    // A long date or large text shrinks to fit
                                    // instead of pushing the pills apart.
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: current == 1
                                          ? const PlanViewSwitcher()
                                          : const DayNavigator(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // What you can do: report, add, sync.
                        _GlassPill(
                          children: [
                            IconButton(
                              tooltip: context.l10n.sendFeedbackOrReportA,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.feedback_outlined,
                                size: 20,
                                color: muted,
                              ),
                              onPressed: () =>
                                  showAppSheet(context, const BugReportSheet()),
                            ),
                            IconButton(
                              tooltip: context.l10n.addMeasurement2,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.add, size: 20, color: muted),
                              onPressed: () =>
                                  showAppSheet(context, ManualEntrySheet()),
                            ),
                            PopupMenuButton<String>(
                              tooltip: context.l10n.syncLabel2,
                              icon: SyncOrb(
                                progress: sync.status == SyncStatus.syncing
                                    ? sync.progress / 100
                                    : null,
                                spinning:
                                    sync.status == SyncStatus.syncing ||
                                    ref.watch(historicSyncProvider).running,
                                freshness:
                                    sync.status == SyncStatus.error ||
                                        sync.errorMessage != null
                                    ? SyncFreshness.error
                                    : sync.lastSync != null &&
                                          DateTime.now().difference(
                                                sync.lastSync!,
                                              ) <
                                              const Duration(hours: 3)
                                    ? SyncFreshness.fresh
                                    : SyncFreshness.stale,
                              ),
                              onSelected: (choice) =>
                                  runUiAction(context, () async {
                                    if (choice == 'today') {
                                      await ref
                                          .read(syncProvider.notifier)
                                          .sync();
                                    } else {
                                      await ref
                                          .read(historicSyncProvider.notifier)
                                          .start(
                                            days: choice == 'year' ? 365 : 3650,
                                            force: true,
                                          );
                                    }
                                  }),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'today',
                                  child: Text(context.l10n.syncToday),
                                ),
                                PopupMenuItem(
                                  value: 'year',
                                  child: Text(context.l10n.fullSync1Year),
                                ),
                                PopupMenuItem(
                                  value: 'all',
                                  child: Text(context.l10n.fullSyncComplete),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  // The pull spinner comes out below the header, not behind it.
                  edgeOffset: glass ? header : 0,
                  onRefresh: () => ref.read(syncProvider.notifier).sync(),
                  child: switch (current) {
                    0 => _HealthPage(
                      openCoach: () => setState(() => tab = 3),
                      openLoad: () => setState(() => tab = 2),
                    ),
                    1 => const PlanScreen(),
                    2 => const StrainScreen(embedded: true),
                    3 => AiCoachScreen(
                      key: ValueKey('${coachRequest?.id ?? 0}-$coachChat'),
                      initialPrompt: coachRequest?.prompt,
                      activity: coachRequest?.activity,
                      contextCard: coachRequest?.card,
                      autoSend: coachRequest?.autoSend ?? false,
                      onAutoSent: () => coachRequest?.autoSend = false,
                      onNewChat: () => setState(() {
                        coachRequest = null;
                        coachChat++;
                      }),
                    ),
                    _ => const DebugScreen(),
                  },
                ),
              ),
              // Sync progress and messages float below the header.
              Positioned(
                top: glass ? header : 0,
                left: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The sync's progress is the ring around the sync button;
                    // only a failure is said here.
                    if (sync.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: panel.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: duo(0xFF333333, 0xFFE3E7EC),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (sync.errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      sync.errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const RecordingBanner(),
                    const HistorySyncCard(),
                  ],
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
                                  fjBackground.withValues(alpha: .55),
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
                    border: Border.all(color: duo(0xFF333333, 0xFFE3E7EC)),
                  ),
                  child: Row(
                    children: [
                      for (final e in <(String, IconData)>[
                        (context.l10n.health2, Icons.favorite_border),
                        (context.l10n.tabPlan, Icons.calendar_month_outlined),
                        (context.l10n.tabLoad, Icons.bar_chart),
                        (context.l10n.tabCoach, Icons.smart_toy_outlined),
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
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.fade,
                                    style: TextStyle(
                                      color:
                                          current == e.$1 || e.$2.$1 == 'DEBUG'
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
        ),
      ],
    );
  }
}

/// The header's height below the status bar.
const _headerHeight = 58.0;

/// A floating pill of the header, made like the tab bar.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    // Frosted: what scrolls under the pill blurs, so its own text stays
    // clear.
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: panel.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: duo(0xFF333333, 0xFFE3E7EC)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    ),
  );
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
      // Under the floating header: it starts below it and scrolls under it.
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 4,
        16,
        100,
      ),
      children: [
        DaySummaryCard(openLoad: openLoad),
        // Ill or injured with no end known: the way back, near the top.
        const OpenAbsenceCard(),
        BriefingCard(openCoach: openCoach),
        if (vis['health_monitor'] ?? true) const HealthMonitorGrid(),
        SectionCard(
          title: context.l10n.typeBloodPressure,
          accent: const [Color(0xFFFF5A7A), Color(0xFFFF9A5A)],
          onTap: () => showAppSheet(context, const BpScreen()),
          child: HeroRow(
            value: bp == null
                ? '—/—'
                : '${bp.avgSystolic.round()}/${bp.avgDiastolic.round()}',
            unit: 'mmHg',
            status: bp == null
                ? context.l10n.noData2
                // ESH categories, systolic and diastolic.
                : bpCategoryLabel(bpCategory(bp.avgSystolic, bp.avgDiastolic)),
            statusColor: bp == null
                ? muted
                : bpCategoryColor(bpCategory(bp.avgSystolic, bp.avgDiastolic)),
            detail: bp != null && yesterdayBp != null
                ? context.l10n.vsYesterday(
                    bp.avgSystolic < yesterdayBp.avgSystolic
                        ? '↓'
                        : bp.avgSystolic > yesterdayBp.avgSystolic
                        ? '↑'
                        : '→',
                  )
                : null,
          ),
        ),

        if (vis['hr_timeline'] ?? true) const HrTimelineCard(),
        if (vis['grip_strength'] ?? true)
          SectionCard(
            title: context.l10n.gripStrength,
            accent: const [Color(0xFF6FA8FF), Color(0xFF3EE0FF)],
            onTap: () => showAppSheet(context, const GripStrengthSheet()),
            child: Row(
              children: [
                Expanded(
                  child: StatPair(
                    context.l10n.gripLeft,
                    valueText(grip?.leftKg),
                    unit: 'kg',
                  ),
                ),
                Expanded(
                  child: StatPair(
                    context.l10n.gripRight,
                    valueText(grip?.rightKg),
                    unit: 'kg',
                  ),
                ),
              ],
            ),
          ),
        if (vis['body_composition'] ?? true)
          SectionCard(
            title: context.l10n.bodyComposition,
            accent: const [Color(0xFFFFB13D), Color(0xFFFFE066)],
            onTap: () => showAppSheet(context, const RenphoScreen()),
            child: Row(
              children: [
                Expanded(
                  child: StatPair(
                    context.l10n.weight,
                    valueText(body?.weight, 1),
                    unit: 'kg',
                  ),
                ),
                Expanded(
                  child: StatPair(
                    context.l10n.bodyFat,
                    valueText(body?.bodyFat, 1),
                    unit: '%',
                  ),
                ),
                Expanded(
                  child: StatPair(
                    context.l10n.muscleShort,
                    valueText(body?.muscleMass, 1),
                    unit: 'kg',
                  ),
                ),
              ],
            ),
          ),
        if (vis['bio_age'] ?? true) const BioAgeCard(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            last == null
                ? context.l10n.noSyncYet
                : context.l10n.lastSyncLastContext(
                    dayText(last),
                    TimeOfDay.fromDateTime(last).format(context),
                  ),
            style: TextStyle(fontSize: 10, color: muted),
          ),
        ),
      ],
    );
  }
}
