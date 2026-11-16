import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/main.dart' as app;
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/locale_provider.dart';
import 'package:fjelia/providers/plan_view_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/providers/week_start_provider.dart';
import 'package:fjelia/screens/activities/load_history_cards.dart';
import 'package:fjelia/screens/activities/load_visuals.dart';
import 'package:fjelia/screens/activities/threshold_sheets.dart';
import 'package:fjelia/screens/activities/training_form_card.dart';
import 'package:fjelia/screens/bloodpressure/bp_screen.dart';
import 'package:fjelia/screens/home/home_screen.dart';
import 'package:fjelia/screens/onboarding/ai_coach_onboarding_screen.dart';
import 'package:fjelia/screens/onboarding/connect_devices_screen.dart';
import 'package:fjelia/screens/planner/pro_analysis_sheet.dart';
import 'package:fjelia/services/pro_analysis.dart';
import 'package:fjelia/widgets/app_widgets.dart';
import 'package:fjelia/widgets/health_monitor_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Walks the real app on a device through the App Store screens, once per
/// language, and prints `STORE_SHOT <language> <screen>` when a screen is
/// ready; a script on the Mac takes the screenshot then
/// (`devicectl device capture screenshot`). The athlete's language and debug
/// tab are restored at the end.
///
/// `flutter run --no-dds -t integration_test/store_screens_test.dart -d DEVICE`
/// with `--dart-define=STORE_LANGS=en,de` to pick languages.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  const langs = String.fromEnvironment('STORE_LANGS');

  testWidgets('store screens', timeout: Timeout.none, (tester) async {
    Future<void> wait(double seconds) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    app.main();
    for (var i = 0; i < 60 && find.byType(HomeScreen).evaluate().isEmpty; i++) {
      await wait(1);
    }
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    final previous = await container.read(languageProvider.future);
    final profile = await container.read(userProfileProvider.future);
    final profiles = container.read(userProfileProvider.notifier);
    if (profile.debugMode) {
      await profiles.save(profile.copyWith(debugMode: false));
    }
    BuildContext home() => tester.element(find.byType(HomeScreen));
    var lang = '';

    Future<void> shot(String name) async {
      await wait(2.5);
      debugPrint('STORE_SHOT $lang $name');
      // The Mac takes the screenshot in about a second.
      await wait(3);
    }

    Future<void> tab(IconData icon) async {
      await tester.tap(find.byIcon(icon).last);
      await wait(1.5);
    }

    Future<void> reveal(Finder finder, {double alignment = .12}) async {
      // The list builds lazily: scroll down until the card exists.
      for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await wait(.5);
      }
      await Scrollable.ensureVisible(
        tester.element(finder.first),
        alignment: alignment,
      );
      await wait(1);
    }

    Future<void> sheet(String name, Widget child, {bool load = false}) async {
      load
          ? showLoadSheet(home(), child, height: .92)
          : showAppSheet(home(), child);
      await shot(name);
      Navigator.of(home()).pop();
      await wait(1.5);
    }

    Future<void> page(String name, Widget child) async {
      // Home is offstage under the page, so keep its navigator.
      final navigator = Navigator.of(home());
      navigator.push(MaterialPageRoute<void>(builder: (_) => child));
      await shot(name);
      navigator.pop();
      await wait(1.5);
    }

    try {
      for (final code
          in langs.isEmpty ? supportedLanguageCodes : langs.split(',')) {
        lang = code;
        await container.read(languageProvider.notifier).set(code);
        await wait(2);
        // Written anew in this language while the other screens are shown.
        container.invalidate(aiBriefingProvider);
        // The briefing is written anew in each language.
        await tab(Icons.favorite_border);
        await wait(4);

        await tab(Icons.calendar_month_outlined);
        final view = container.read(planViewProvider.notifier);
        await view.setView('list');
        await shot('plan-list');
        await view.setView('week');
        await shot('plan-week');
        await view.setView('month');
        await shot('plan-month');
        await view.setView('list');

        await tab(Icons.bar_chart);
        await reveal(find.byType(LoadHistoryCards), alignment: .2);
        await shot('load-zones');
        await reveal(find.byType(TrainingFormCard), alignment: .3);
        await shot('load-form');

        await tab(Icons.favorite_border);
        await sheet('bp', const BpScreen());
        await sheet('thresholds', const ThresholdSheets(), load: true);
        // Its AI text and first picture are German: only for the German set.
        if (code == 'de') {
          await sheet(
            'week-review',
            ProAnalysisSheet(
              analysis: ProAnalysisRef.lastWeekReview(
                DateTime.now(),
                mondayFirst: container.read(weekStartsOnMondayProvider),
              ),
              title: home().l10n.proWeekReview,
            ),
          );
        }
        await page('ai-coach', const AiCoachOnboardingScreen());
        await page('devices', const ConnectDevicesScreen());

        await reveal(find.byType(HealthMonitorGrid), alignment: .08);
        await shot('status-monitor');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
        // Time for the briefing in this language.
        await wait(20);
        await shot('status');
      }
    } finally {
      await container.read(languageProvider.notifier).set(previous);
      if (profile.debugMode) await profiles.save(profile);
      debugPrint('STORE_SHOT done done');
      await wait(2);
    }
  });
}
