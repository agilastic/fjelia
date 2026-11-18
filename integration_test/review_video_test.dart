import 'package:fjelia/main.dart' as app;
import 'package:fjelia/providers/fjelia_pro_provider.dart';
import 'package:fjelia/providers/locale_provider.dart';
import 'package:fjelia/providers/plan_view_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/screens/activities/sport_stats_card.dart';
import 'package:fjelia/screens/activities/training_form_card.dart';
import 'package:fjelia/screens/home/home_screen.dart';
import 'package:fjelia/screens/planner/pro_analysis_sheet.dart';
import 'package:fjelia/screens/settings/fjelia_pro_sheet.dart';
import 'package:fjelia/widgets/health_monitor_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Walks the real app on a device, in English and at a pace a reviewer can
/// follow, for the App Review screen recording: the four tabs, then where
/// FjeliaPro is offered and its sheet down to the terms links. The iPhone's
/// own screen recording films it; `scripts/review-video.sh` runs it and
/// waits for `REVIEW_VIDEO done`. The athlete's language and debug tab are
/// restored at the end.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  // The reviewer sees the sheet as someone without Pro: the stored access
  // is dropped first (a valid subscription comes back with a restore).
  const withoutPro = bool.fromEnvironment('REVIEW_WITHOUT_PRO');

  testWidgets('review video', timeout: Timeout.none, (tester) async {
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
    BuildContext home() => tester.element(find.byType(HomeScreen));

    Future<void> tab(IconData icon) async {
      await tester.tap(find.byIcon(icon).last);
      await wait(2.5);
    }

    // A finger-speed scroll, so the recording shows it move.
    Future<void> scroll(Finder scrollable, double dy, {double hold = 2}) async {
      await tester.timedDrag(
        scrollable,
        Offset(0, -dy),
        const Duration(milliseconds: 900),
      );
      await wait(hold);
    }

    Future<void> reveal(Finder finder, {double alignment = .15}) async {
      // The list builds lazily: scroll down until the card exists.
      for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
        await scroll(find.byType(Scrollable).first, 400, hold: .6);
      }
      // A card hidden in this athlete's settings is skipped, not a failure.
      if (finder.evaluate().isEmpty) return;
      await Scrollable.ensureVisible(
        tester.element(finder.first),
        alignment: alignment,
        duration: const Duration(milliseconds: 700),
      );
      await wait(3);
    }

    Future<void> toTop() async {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
      await wait(1.5);
    }

    if (withoutPro) {
      await container.read(proAccessStoreProvider).clear();
      container.invalidate(fjeliaProProvider);
      container.read(fjeliaProProvider);
    }

    try {
      // The one-time FjeliaPro question may open first: the athlete answers
      // it on the iPhone, in the recording.
      await wait(3);
      for (
        var i = 0;
        i < 120 && find.byType(AlertDialog).evaluate().isNotEmpty;
        i++
      ) {
        await wait(1);
      }
      if (profile.debugMode) {
        await profiles.save(profile.copyWith(debugMode: false));
      }
      await container.read(languageProvider.notifier).set('en');
      await wait(4);

      // Health: readiness and the health monitors.
      await tab(Icons.favorite_border);
      await wait(3);
      await reveal(find.byType(HealthMonitorGrid), alignment: .08);
      await toTop();

      // Plan: list, week and month, then the Pro analyses card.
      await tab(Icons.calendar_month_outlined);
      final view = container.read(planViewProvider.notifier);
      await view.setView('list');
      await wait(3);
      await view.setView('week');
      await wait(3);
      await view.setView('month');
      await wait(3);
      await view.setView('list');
      await wait(1.5);
      await reveal(find.byType(ProToolsCard));
      await toTop();

      // Load: form and the Pro training stats.
      await tab(Icons.bar_chart);
      // Top to bottom: the stats card sits above the form.
      await reveal(find.byType(SportStatsCard), alignment: .3);
      await reveal(find.byType(TrainingFormCard), alignment: .3);
      await toTop();

      // Coach.
      await tab(Icons.smart_toy_outlined);
      await wait(4);

      // Settings > FjeliaPro, down to the auto-renewal text and the links.
      await tab(Icons.favorite_border);
      await tester.tap(find.byIcon(Icons.menu).first);
      await wait(3);
      await tester.tap(find.byKey(const ValueKey('settings-fjelia-pro')));
      await wait(4);
      final pro = find.descendant(
        of: find.byType(FjeliaProSheet),
        matching: find.byType(Scrollable),
      );
      for (var i = 0; i < 4; i++) {
        await scroll(pro.first, 350, hold: 2.5);
      }
      await wait(3);
      Navigator.of(home()).pop();
      await wait(1.5);
      Navigator.of(home()).pop();
      await wait(2);
    } finally {
      await container.read(languageProvider.notifier).set(previous);
      if (profile.debugMode) await profiles.save(profile);
      debugPrint('REVIEW_VIDEO done');
      await wait(2);
    }
  });
}
