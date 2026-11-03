import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/hr_zones_provider.dart';
import 'package:fjelia/providers/planner_providers.dart';
import 'package:fjelia/providers/threshold_overview_provider.dart';
import 'package:fjelia/screens/activities/threshold_overview_section.dart';
import 'package:fjelia/services/threshold_choice_store.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // COROS reported 165 bpm at 4:30 /km; nothing else is known.
    FlutterSecureStorage.setMockInitialValues({
      'device_thresholds_v1': jsonEncode({
        'coros': {
          'source': 'coros',
          'date': DateTime.now()
              .subtract(const Duration(days: 3))
              .toIso8601String(),
          'lt2': 165,
          'lt2Pace': 270,
        },
      }),
    });
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    // Keeps the auto-disposed overview alive between reads, as a screen does.
    container.listen(thresholdOverviewProvider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('a COROS threshold is proposed and applied on confirmation', () async {
    final overview = await container.read(thresholdOverviewProvider.future);
    final lt2 = overview.rows.firstWhere((r) => r.kind == ThresholdKind.lt2);
    expect(lt2.inUse, isNull);
    expect(lt2.proposal!.source, 'coros');
    // LT1 falls back to the max-HR formula only when nothing else exists.
    final lt1 = overview.rows.firstWhere((r) => r.kind == ThresholdKind.lt1);
    expect(lt1.candidates.where((c) => c.source == 'coros'), isEmpty);

    await container.read(thresholdActionsProvider).apply(lt2.proposal!);

    final saved = await container.read(athleteThresholdsServiceProvider).get();
    expect(saved!.thresholdHrBpm, 165);
    expect(1000 / saved.thresholdPaceMps!, closeTo(270, 0.5));
    // Zones were rebuilt on the new LTHR and Garmin sync won't undo them.
    // Zone 5 starts at the new LTHR.
    expect(container.read(hrZonesProvider).running.bounds.last, 165);
    expect(
      runZonesFollowDevice(await const ThresholdChoiceStore().applied()),
      isFalse,
    );
    final after = await container.read(thresholdOverviewProvider.future);
    expect(
      after.rows.firstWhere((r) => r.kind == ThresholdKind.lt2).proposal,
      isNull,
    );
  });

  test('applying LT2 keeps an LT1 the athlete applied', () async {
    final actions = container.read(thresholdActionsProvider);
    await actions.apply(
      const ThresholdCandidate(
        kind: ThresholdKind.lt1,
        source: 'dfa',
        value: 142,
      ),
    );
    expect(container.read(hrZonesProvider).running.bounds[2], 142);
    final overview = await container.read(thresholdOverviewProvider.future);
    await actions.apply(
      overview.rows.firstWhere((r) => r.kind == ThresholdKind.lt2).proposal!,
    );
    final bounds = container.read(hrZonesProvider).running.bounds;
    expect(bounds[2], 142);
    expect(bounds[4], 165);
  });

  test('keeping the current value hides the proposal', () async {
    final overview = await container.read(thresholdOverviewProvider.future);
    final proposal = overview.rows
        .firstWhere((r) => r.kind == ThresholdKind.lt2)
        .proposal!;
    await container.read(thresholdActionsProvider).keep(proposal);
    final after = await container.read(thresholdOverviewProvider.future);
    expect(
      after.rows.firstWhere((r) => r.kind == ThresholdKind.lt2).proposal,
      isNull,
    );
    expect(
      await container.read(athleteThresholdsServiceProvider).get(),
      isNull,
    );
  });

  testWidgets('the overview shows the proposal with its source', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(child: ThresholdOverviewSection()),
          ),
        ),
      ),
    );
    // Real async work (database, storage); the loading bar never settles.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(
      find.textContaining('Suggested: 165 bpm · 4:30 /km'),
      findsOneWidget,
    );
    expect(find.text('Apply'), findsWidgets);
    expect(find.text('Keep current'), findsWidgets);
  });
}
