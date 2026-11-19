import 'package:fjelia/config/build_features.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/main.dart' as app;
import 'package:fjelia/providers/auth_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/ecg_provider.dart';
import 'package:fjelia/providers/plan_view_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/providers/week_start_provider.dart';
import 'package:fjelia/screens/activities/heat_weather_sheet.dart';
import 'package:fjelia/screens/activities/load_metric_sheet.dart';
import 'package:fjelia/screens/activities/load_visuals.dart';
import 'package:fjelia/screens/activities/lt2_test_sheet.dart';
import 'package:fjelia/screens/activities/threshold_sheets.dart';
import 'package:fjelia/screens/activities/training_metrics_sheet.dart';
import 'package:fjelia/screens/activities/training_monitor_card.dart';
import 'package:fjelia/screens/activities/workout_detail_sheet.dart';
import 'package:fjelia/screens/ai_coach/coach_memories_screen.dart';
import 'package:fjelia/screens/battery/battery_screen.dart';
import 'package:fjelia/screens/bloodpressure/bp_screen.dart';
import 'package:fjelia/screens/debug/debug_screen.dart';
import 'package:fjelia/screens/home/home_screen.dart';
import 'package:fjelia/screens/ocr/manual_entry_sheet.dart';
import 'package:fjelia/screens/onboarding/ai_coach_onboarding_screen.dart';
import 'package:fjelia/screens/onboarding/connect_aktiia_screen.dart';
import 'package:fjelia/screens/onboarding/connect_coros_screen.dart';
import 'package:fjelia/screens/onboarding/connect_devices_screen.dart';
import 'package:fjelia/screens/onboarding/connect_garmin_screen.dart';
import 'package:fjelia/screens/onboarding/connect_health_screen.dart';
import 'package:fjelia/screens/onboarding/connect_hilo_ble_screen.dart';
import 'package:fjelia/screens/onboarding/connect_mywhoosh_screen.dart';
import 'package:fjelia/screens/onboarding/connect_polar_h10_screen.dart';
import 'package:fjelia/screens/onboarding/connect_polar_screen.dart';
import 'package:fjelia/screens/onboarding/connect_renpho_ble_screen.dart';
import 'package:fjelia/screens/onboarding/connect_renpho_screen.dart';
import 'package:fjelia/screens/onboarding/connect_suunto_screen.dart';
import 'package:fjelia/screens/onboarding/missed_workout_onboarding_screen.dart';
import 'package:fjelia/screens/onboarding/welcome_screen.dart';
import 'package:fjelia/screens/planner/missed_workout_sheet.dart';
import 'package:fjelia/screens/planner/plan_proposal_cards.dart';
import 'package:fjelia/screens/planner/plan_session_sheet.dart';
import 'package:fjelia/screens/planner/pro_analysis_sheet.dart';
import 'package:fjelia/screens/planner/short_session_sheet.dart';
import 'package:fjelia/screens/renpho/renpho_screen.dart';
import 'package:fjelia/screens/settings/ai_settings_tab.dart';
import 'package:fjelia/screens/settings/bug_report_sheet.dart';
import 'package:fjelia/screens/settings/connections_tab.dart';
import 'package:fjelia/screens/settings/credits_page.dart';
import 'package:fjelia/screens/settings/display_tab.dart';
import 'package:fjelia/screens/settings/fjelia_pro_sheet.dart';
import 'package:fjelia/screens/settings/hr_zones_tab.dart';
import 'package:fjelia/screens/settings/language_page.dart';
import 'package:fjelia/screens/settings/own_keys_page.dart';
import 'package:fjelia/screens/settings/profile_tab.dart';
import 'package:fjelia/screens/settings/race_goal_editor.dart';
import 'package:fjelia/screens/settings/system_tab.dart';
import 'package:fjelia/screens/settings/training_tab.dart';
import 'package:fjelia/screens/settings/training_windows_sheet.dart';
import 'package:fjelia/screens/settings/weather_city_picker.dart';
import 'package:fjelia/screens/settings/weather_location_tab.dart';
import 'package:fjelia/screens/sleep/sleep_screen.dart';
import 'package:fjelia/screens/strain/activity_detail_sheet.dart';
import 'package:fjelia/screens/strain/strain_screen.dart';
import 'package:fjelia/screens/weather/weather_radar.dart';
import 'package:fjelia/screens/weather/weather_screen.dart';
import 'package:fjelia/services/pro_analysis.dart';
import 'package:fjelia/widgets/absence_sheet.dart';
import 'package:fjelia/widgets/activity_file_import_sheet.dart';
import 'package:fjelia/widgets/app_widgets.dart';
import 'package:fjelia/widgets/bp_monitors.dart';
import 'package:fjelia/widgets/drink_mix_sheet.dart';
import 'package:fjelia/widgets/ecg_sheet.dart';
import 'package:fjelia/widgets/grip_strength_sheet.dart';
import 'package:fjelia/widgets/gym_treadmill_sheet.dart';
import 'package:fjelia/widgets/hilo_report_import_sheet.dart';
import 'package:fjelia/widgets/hr_timeline_card.dart';
import 'package:fjelia/widgets/hrv_sleep_detail_sheet.dart';
import 'package:fjelia/widgets/manual_activity_sheet.dart';
import 'package:fjelia/widgets/metric_detail_sheet.dart';
import 'package:fjelia/widgets/nutrition_widgets.dart';
import 'package:fjelia/widgets/omron_ble_import_sheet.dart';
import 'package:fjelia/widgets/recently_deleted_sheet.dart';
import 'package:fjelia/widgets/strava_import_sheet.dart';
import 'package:fjelia/widgets/waist_sheet.dart';
import 'package:fjelia/widgets/weather_range_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Opens every page of the real app on a device, scrolls each one to the
/// end and back, and reports what Flutter reported meanwhile (exceptions,
/// overflows) per page instead of stopping at the first. Prints
/// `PAGE_SHOT <name>` when a page is ready for a screenshot,
/// `PAGE_FAIL <name>: <error>` per problem and `ALL_PAGES done <failed>/<pages>`
/// at the end; `scripts/test-pages.sh` runs it on an iPhone or Android phone.
/// Nothing is saved or sent: pages that would start an import or a
/// measurement are left out. The debug tab is restored at the end.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('all pages', timeout: Timeout.none, (tester) async {
    Future<void> wait(double seconds) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    app.main();
    for (var i = 0; i < 60 && find.byType(HomeScreen).evaluate().isEmpty; i++) {
      await wait(1);
      // A phone without a connected account (e.g. a fresh Fjelia CE) starts
      // in setup: skip it, as the athlete can.
      if (i > 5 && find.byType(WelcomeScreen).evaluate().isNotEmpty) {
        await ProviderScope.containerOf(
          tester.element(find.byType(WelcomeScreen)),
        ).read(authProvider.notifier).skipGarmin();
      }
    }
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    final profile = await container.read(userProfileProvider.future);
    final profiles = container.read(userProfileProvider.notifier);
    BuildContext home() => tester.element(find.byType(HomeScreen));
    final db = container.read(databaseProvider);

    // Errors land on the current page rather than failing the test at once.
    final reportError = FlutterError.onError;
    final errors = <String>[];
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString().split('\n').first);
      FlutterError.dumpErrorToConsole(details, forceReport: true);
    };
    final failed = <String>[];
    var pages = 0;

    // The vertical list in front: the one whose centre takes a tap.
    Finder front() => find
        .byWidgetPredicate(
          (w) =>
              w is Scrollable &&
              axisDirectionToAxis(w.axisDirection) == Axis.vertical,
        )
        .hitTestable();

    Future<void> scrollThrough() async {
      if (front().evaluate().isEmpty) return;
      final list = front().first;
      final state = tester.state<ScrollableState>(list);
      for (var i = 0; i < 40; i++) {
        final before = state.position.pixels;
        await tester.drag(list, const Offset(0, -500), warnIfMissed: false);
        await wait(.4);
        if (state.position.pixels <= before) break;
      }
      await tester.drag(list, const Offset(0, 6000), warnIfMissed: false);
      await wait(.8);
    }

    Future<void> check(String name, Future<void> Function() body) async {
      pages++;
      errors.clear();
      try {
        await body();
      } catch (e) {
        errors.add('$e'.split('\n').first);
      }
      if (errors.isEmpty) {
        debugPrint('PAGE_OK $name');
      } else {
        failed.add(name);
        for (final e in errors.toSet()) {
          debugPrint('PAGE_FAIL $name: $e');
        }
      }
    }

    // Range and filter selectors of the page in front: each choice once,
    // then back to the one that was selected, so no preference changes.
    // Only for pages whose chips select what is shown, not settings.
    Future<void> interact() async {
      final chips = find.byType(ChoiceChip).hitTestable();
      final count = chips.evaluate().length;
      if (count > 1 && count <= 12) {
        final selected = [
          for (final e in chips.evaluate()) (e.widget as ChoiceChip).selected,
        ].indexOf(true);
        for (var i = 0; i < count; i++) {
          if (i == selected || chips.evaluate().length <= i) continue;
          await tester.tap(chips.at(i), warnIfMissed: false);
          await wait(.8);
        }
        if (selected >= 0 && chips.evaluate().length > selected) {
          await tester.tap(chips.at(selected), warnIfMissed: false);
          await wait(.8);
        }
      }
      final groups = find.byWidgetPredicate((w) => w is SegmentedButton);
      for (
        var k = 0;
        k < groups.hitTestable().evaluate().length && k < 4;
        k++
      ) {
        final group = groups.hitTestable().at(k);
        final button = tester.widget(group) as SegmentedButton;
        final values = [for (final s in button.segments) s.value];
        final selected = values.indexOf(button.selected.firstOrNull);
        final segments = find.descendant(
          of: group,
          matching: find.byType(TextButton),
        );
        for (var i = 0; i < segments.evaluate().length; i++) {
          if (i == selected) continue;
          await tester.tap(segments.at(i), warnIfMissed: false);
          await wait(.8);
        }
        if (selected >= 0 && segments.evaluate().length > selected) {
          await tester.tap(segments.at(selected), warnIfMissed: false);
          await wait(.8);
        }
      }
      // The weather's day / week / 14 days switch, ending on the day.
      final ranges = find.descendant(
        of: find.byType(WeatherRangeSwitcher),
        matching: find.byType(InkWell),
      );
      for (var i = ranges.evaluate().length - 1; i >= 0; i--) {
        await tester.tap(ranges.at(i), warnIfMissed: false);
        await wait(1.2);
      }
      // Back and forward by one period: a left arrow with a right arrow in
      // the same row (day, week, month), not a disclosure chevron.
      final back = find.byIcon(Icons.chevron_left).hitTestable();
      if (back.evaluate().isNotEmpty) {
        final row = find.ancestor(of: back.first, matching: find.byType(Row));
        final forward = find.descendant(
          of: row.first,
          matching: find.byIcon(Icons.chevron_right),
        );
        if (forward.evaluate().isNotEmpty) {
          await tester.tap(back.first, warnIfMissed: false);
          await wait(1.5);
          await tester.tap(forward.first, warnIfMissed: false);
          await wait(1.5);
        }
      }
    }

    Future<void> shown(String name, {bool taps = false}) async {
      await wait(2.5);
      debugPrint('PAGE_SHOT $name');
      // The Mac takes the screenshot in about a second.
      await wait(2);
      if (taps) await interact();
      await scrollThrough();
    }

    Future<void> tab(String name, IconData icon, {bool taps = true}) =>
        check(name, () async {
          await tester.tap(find.byIcon(icon).last);
          await shown(name, taps: taps);
        });

    // Back to Home, also when a tap opened something on top of the page.
    Future<void> close(NavigatorState navigator) async {
      navigator.popUntil((route) => route.isFirst);
      await wait(1.2);
    }

    Future<void> sheet(
      String name,
      Widget child, {
      bool load = false,
      bool taps = false,
    }) => check(name, () async {
      final navigator = Navigator.of(home());
      load
          ? showLoadSheet(home(), child, height: .92)
          : showAppSheet(home(), child);
      try {
        await shown(name, taps: taps);
      } finally {
        await close(navigator);
      }
    });

    Future<void> page(String name, Widget child, {bool taps = false}) =>
        check(name, () async {
          // Home is offstage under the page, so keep its navigator.
          final navigator = Navigator.of(home());
          navigator.push(MaterialPageRoute<void>(builder: (_) => child));
          try {
            await shown(name, taps: taps);
          } finally {
            await close(navigator);
          }
        });

    try {
      if (profile.debugMode) {
        await profiles.save(profile.copyWith(debugMode: false));
      }
      await wait(3);
      // A one-time question (e.g. the morning push) waits for an answer.
      for (
        var i = 0;
        i < 120 && find.byType(AlertDialog).evaluate().isNotEmpty;
        i++
      ) {
        await wait(1);
      }

      await tab('health', Icons.favorite_border);
      await tab('plan-list', Icons.calendar_month_outlined);
      final view = container.read(planViewProvider.notifier);
      for (final v in ['week', 'month']) {
        await check('plan-$v', () async {
          await view.setView(v);
          await shown('plan-$v', taps: true);
        });
      }
      await view.setView('list');
      await tab('load', Icons.bar_chart);
      // No taps: the coach must not send anything.
      await tab('coach', Icons.smart_toy_outlined, taps: false);
      await tester.tap(find.byIcon(Icons.favorite_border).last);
      await wait(1.5);

      // The health screens.
      await page('sleep', const SleepScreen(), taps: true);
      await sheet('blood-pressure', const BpScreen(), taps: true);
      await page('battery', const BatteryScreen(), taps: true);
      await page('body-scale', const RenphoScreen(), taps: true);
      await page('weather', const WeatherScreen(), taps: true);
      await page(
        'weather-radar',
        const Scaffold(body: SafeArea(child: WeatherRadar(fullscreen: true))),
      );
      await page('strain', const StrainScreen(), taps: true);
      await page('hr-timeline', const HrTimelineScreen(), taps: true);
      await sheet('manual-entry', const ManualEntrySheet());
      for (final m in HealthMetric.values) {
        await sheet(
          'metric-${m.name}',
          MetricDetailSheet(metric: m),
          taps: true,
        );
      }
      await sheet('hrv-sleep', const HrvSleepDetailSheet(), taps: true);
      await sheet(
        'resting-hr-sleep',
        const HrvSleepDetailSheet(restingHr: true),
        taps: true,
      );
      await sheet('ecg', const EcgSheet());
      final ecg = await container.read(ecgStorageProvider).history();
      if (ecg.isNotEmpty) {
        await sheet('ecg-detail', EcgDetailSheet(recording: ecg.first));
      }
      await sheet('waist', const WaistSheet());
      await sheet('grip-strength', const GripStrengthSheet());
      await sheet('bp-measure', const BpMeasureSheet());
      await sheet('bp-add-monitor', const AddBpMonitorSheet());

      // Load sheets.
      await sheet('thresholds', const ThresholdSheets(), load: true);
      await sheet('ftp', const FtpDetailSheet(), load: true);
      await sheet('training-metrics', const TrainingMetricsSheet(), load: true);
      await sheet(
        'heat-weather',
        const HeatWeatherSheet(),
        load: true,
        taps: true,
      );
      await sheet('lt2-test', const Lt2TestSheet(), load: true);
      await sheet('threshold-test', const ThresholdTestSheet(), load: true);
      await sheet('vo2-test', const ThresholdTestSheet(vo2: true), load: true);
      await sheet('zones-hr', const LoadZonesSheet(), load: true);
      await sheet('zones-power', const LoadZonesSheet(power: true), load: true);
      for (final m in [
        'VO₂max running',
        'VO₂max cycling',
        'Activity hours',
        'Activity km',
      ]) {
        await sheet(
          'load-${m.toLowerCase().replaceAll(RegExp('[^a-z]+'), '-')}',
          LoadMetricSheet(metric: m),
          load: true,
        );
      }

      // One activity per sport and one session per kind, so each sport's
      // and the strength sections are shown.
      final activities = <String, ActivityRecord>{};
      for (final a in await db.getRecentActivities(365)) {
        activities.putIfAbsent(a.type, () => a);
      }
      for (final a in activities.values.take(10)) {
        await sheet(
          'activity-${a.type.toLowerCase()}',
          ActivityDetailSheet(activity: a),
        );
      }
      if (activities.isNotEmpty) {
        await sheet(
          'nutrition-intake',
          NutritionIntakeSheet(activity: activities.values.first),
        );
      }
      final sessions = <String, TrainingSession>{};
      for (final s in await db.getUpcomingTrainingSessions()) {
        sessions.putIfAbsent('${s.sport}-${s.sessionType}', () => s);
      }
      for (final e in sessions.entries.take(8)) {
        await sheet(
          'session-${e.key.toLowerCase()}',
          PlanSessionSheet(session: e.value),
        );
      }
      if (sessions.isNotEmpty) {
        await sheet(
          'short-session',
          ShortSessionSheet(sessionId: sessions.values.first.id),
        );
      }
      final workouts = await container.read(scheduledWorkoutsProvider.future);
      if (workouts.isNotEmpty) {
        await sheet(
          'workout-detail',
          WorkoutDetailSheet(workout: workouts.first),
        );
      }

      // Plan sheets. The missed-workout sheet does not sync first here, and
      // the Pro analyses only write when their button is tapped.
      final today = DateUtils.dateOnly(DateTime.now());
      await sheet(
        'missed-workout',
        MissedWorkoutSheet(
          day: today.subtract(const Duration(days: 1)),
          syncFirst: false,
        ),
      );
      await sheet('readiness-proposal', ReadinessProposalSheet(day: today));
      await sheet('absence', const AbsenceSheet());
      await sheet(
        'pro-plan-check',
        ProAnalysisSheet(
          analysis: ProAnalysisRef.planCheck(today),
          title: home().l10n.proPlanCheck,
        ),
      );
      await sheet(
        'pro-week-review',
        ProAnalysisSheet(
          analysis: ProAnalysisRef.lastWeekReview(
            today,
            mondayFirst: container.read(weekStartsOnMondayProvider),
          ),
          title: home().l10n.proWeekReview,
        ),
      );
      await sheet(
        'pro-season',
        ProAnalysisSheet(
          analysis: ProAnalysisRef.season(today),
          title: home().l10n.proSeason,
        ),
      );
      await sheet(
        'drink-mix',
        const DrinkMixSheet(purpose: DrinkMixPurpose.intake),
      );

      // Recording, import and history sheets (opening them starts nothing).
      await sheet('manual-activity', const ManualActivitySheet());
      await sheet('gym-treadmill', const GymTreadmillSheet());
      await sheet('gym-summary', const GymSummarySheet());
      await sheet('matrix-xid', const MatrixXidSheet());
      await sheet('activity-file-import', const ActivityFileImportSheet());
      await sheet('strava-import', const StravaImportSheet());
      await sheet('import', const ImportSheet());
      await sheet('hilo-report-import', const HiloReportImportSheet());
      await sheet('omron-import', const OmronBleImportSheet());
      await sheet('recently-deleted', const RecentlyDeletedSheet());

      // Settings: the sheet itself, then each of its pages.
      await check('settings', () async {
        await tester.tap(find.byIcon(Icons.menu).first);
        await shown('settings');
        Navigator.of(home()).pop();
        await wait(1.2);
      });
      await sheet('settings-pro', const FjeliaProSheet());
      await sheet('settings-profile', const ProfileTab());
      for (final section in [0, 1, 2]) {
        await sheet(
          'settings-profile-$section',
          ProfileEditor(section: section),
        );
      }
      await sheet('settings-training', const TrainingTab());
      await sheet('settings-hr-zones', const HrZonesTab());
      await sheet('settings-training-windows', const TrainingWindowsSheet());
      await sheet('settings-race-goal', const RaceGoalEditor());
      await sheet('settings-weather', const WeatherLocationTab());
      await sheet('settings-city', WeatherCityPicker(onSelected: (_) async {}));
      await sheet('settings-display', const DisplayTab());
      await sheet('settings-connections', const ConnectionsTab());
      await sheet('settings-ai', const AiSettingsTab());
      if (communityEdition) {
        await sheet('settings-own-keys', const OwnKeysPage());
      }
      await sheet('settings-system', const SystemTab());
      await sheet('settings-data-export', const DataExportPage());
      await sheet('settings-language', const LanguagePage());
      await sheet('settings-credits', const CreditsPage());
      await sheet('bug-report', const BugReportSheet());
      await page('coach-memories', const CoachMemoriesScreen());
      await page('debug', const DebugScreen());

      // Setup and connection pages (opening them connects nothing).
      await page('welcome', const WelcomeScreen());
      await page('connect-devices', const ConnectDevicesScreen());
      await page('ai-coach-setup', const AiCoachOnboardingScreen());
      await page('missed-workout-setup', const MissedWorkoutOnboardingScreen());
      // Apple Health is not offered on Android.
      if (systemHealthAvailable) {
        await page('connect-health', const ConnectHealthScreen());
      }
      await page('connect-garmin', const ConnectGarminScreen());
      await page('connect-coros', const ConnectCorosScreen());
      // Hilo, Suunto and the Renpho cloud are not in Fjelia CE.
      if (!communityEdition) {
        await page('connect-suunto', const ConnectSuuntoScreen());
      }
      await page('connect-polar', const ConnectPolarScreen());
      await page('connect-polar-h10', const ConnectPolarH10Screen());
      await page('connect-mywhoosh', const ConnectMyWhooshScreen());
      if (!communityEdition) {
        await page('connect-aktiia', const ConnectAktiiaScreen());
        await page('connect-renpho', const ConnectRenphoScreen());
      }
      await page('connect-renpho-ble', const ConnectRenphoBleScreen());
      if (!communityEdition) {
        await page('connect-hilo-ble', const ConnectHiloBleScreen());
      }
    } finally {
      if (profile.debugMode) await profiles.save(profile);
      FlutterError.onError = reportError;
      debugPrint('ALL_PAGES failed: ${failed.join(', ')}');
      debugPrint('ALL_PAGES done ${failed.length}/$pages');
      await wait(2);
    }
  });
}
