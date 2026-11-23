import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/fjelia_edition_provider.dart';
import 'package:fjelia/providers/hr_zone_trends_provider.dart';
import 'package:fjelia/screens/activities/hr_zone_trends_sheet.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Edition implements FjeliaEdition {
  const _Edition({required this.isPro, required this.proOffered});
  @override
  final bool isPro, proOffered;
}

HrZoneWorkout _workout(int daysAgo, List<double> zoneMinutes, double minutes) {
  final now = DateTime.now();
  return HrZoneWorkout(
    activityId: 'w$daysAgo',
    sport: 'running',
    start: DateTime(now.year, now.month, now.day - daysAgo, 7),
    elapsedSeconds: minutes * 60,
    coveredSeconds: zoneMinutes.fold(0.0, (a, b) => a + b) * 60,
    zoneSeconds: [for (final m in zoneMinutes) m * 60],
    definitionId: 1,
  );
}

void main() {
  Future<void> show(WidgetTester tester, FjeliaEdition edition) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fjeliaEditionProvider.overrideWithValue(edition),
          hrZoneWorkoutsProvider.overrideWith(
            (ref) async => [
              for (var d = 0; d < 56; d += 3)
                _workout(d, [10, 40, d < 28 ? 8 : 2, d < 28 ? 6 : 0, 0], 70),
            ],
          ),
          hrZonePlannedProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HrZoneTrendsTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('without FjeliaPro on offer there is nothing', (tester) async {
    await show(tester, const _Edition(isPro: false, proOffered: false));
    expect(find.text('HEART RATE ZONE TRENDS'), findsNothing);
  });

  testWidgets('offered but not bought: locked', (tester) async {
    await show(tester, const _Edition(isPro: false, proOffered: true));
    expect(find.text('HEART RATE ZONE TRENDS'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byType(HrZoneTrendsSheet), findsNothing);
  });

  testWidgets('Pro opens the trends with the comparison and the plan', (
    tester,
  ) async {
    await show(tester, const _Edition(isPro: true, proOffered: true));
    await tester.tap(find.text('HEART RATE ZONE TRENDS'));
    await tester.pumpAndSettle();
    expect(find.byType(HrZoneTrendsSheet), findsOneWidget);
    // The legend names every zone and the missing heart rate in text.
    for (var z = 1; z <= 5; z++) {
      expect(find.text('Z$z'), findsWidgets);
    }
    expect(find.text('No heart rate'), findsOneWidget);
    // Shares are of the heart-rate time: no missing-heart-rate segment.
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.text('No heart rate'), findsNothing);
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    final list = find.descendant(
      of: find.byType(HrZoneTrendsSheet),
      matching: find.byType(Scrollable),
    );
    // More hard time with more training time: said as it is, not judged.
    await tester.scrollUntilVisible(
      find.text('• Time in Z4+Z5 rose while total training time rose as well.'),
      300,
      scrollable: list.first,
    );
    await tester.scrollUntilVisible(
      find.text('No comparable planned sessions in this week.'),
      300,
      scrollable: list.first,
    );
  });
}
