import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/models/drink_mix.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/widgets/drink_mix_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  /// Opens the mixer from a button and records what it returns.
  Future<List<DrinkMixResult?>> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final results = <DrinkMixResult?>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showDrinkMixSheet(
                  context,
                  purpose: DrinkMixPurpose.intake,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    return results;
  }

  testWidgets('starts with the 2:1 recipe and reads it out', (tester) async {
    await open(tester);
    expect(find.text('Mix a drink'), findsOneWidget);
    expect(find.text('39'), findsOneWidget);
    expect(find.text('per 500 ml bottle'), findsOneWidget);
    expect(find.text('2.3 : 1'), findsOneWidget);
    expect(find.text('7.8 %'), findsOneWidget);
    expect(find.text('Easy on the stomach – up to 8 %.'), findsOneWidget);
    expect(find.text('level tbsp'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.textContaining('Spoon sizes vary'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Spoon sizes vary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cola brings caffeine; more spoons make it stronger', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Cola spritzer'));
    await settle(tester);
    expect(find.text('25 mg'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
    await tester.tap(find.text('Malto + sugar 2:1'));
    await settle(tester);
    // Two more level tablespoons of sugar: about 63 g in 500 ml.
    expect(find.text('≈ 16 g · 15 g Carbs'), findsOneWidget);
    final plus = find.descendant(
      of: find.byKey(const ValueKey(MixIngredient.sugar)),
      matching: find.byIcon(Icons.add_rounded),
    );
    for (var i = 0; i < 4; i++) {
      await tester.tap(plus);
      await tester.pump();
    }
    await settle(tester);
    expect(find.text('Very concentrated – add water.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returns the mix with the recipe name and remembers it', (
    tester,
  ) async {
    final results = await open(tester);
    await tester.tap(find.text('Juice spritzer'));
    await settle(tester);
    await tester.tap(find.text('Add to intake'));
    await settle(tester);
    expect(results.single!.name, 'Juice spritzer');
    expect(results.single!.mix.carbs, closeTo(22.5, .01));
    final saved = await tester.runAsync(
      () => db.select(db.nutritionRecords).getSingle(),
    );
    expect(saved!.recordKey, 'nutrition:mix:last');
    final last = DrinkMix.fromJson(jsonDecode(saved.dataJson) as Map);
    expect(last.carbs, closeTo(22.5, .01));
  });

  testWidgets('German labels fit on a phone, every recipe and unit', (
    tester,
  ) async {
    await open(tester, locale: const Locale('de'));
    expect(find.text('Getränk mischen'), findsOneWidget);
    expect(find.text('gestr. EL'), findsNWidgets(2));
    for (final recipe in [
      'Saftschorle + Malto',
      'Cola-Schorle',
      'Malto + Zucker 2:1',
    ]) {
      await tester.tap(find.text(recipe));
      await settle(tester);
    }
    await tester.tap(find.text('gestr. EL').first);
    await settle(tester);
    await tester.tap(find.text('gehäufter EL').last);
    await settle(tester);
    expect(find.text('gehäufter EL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
