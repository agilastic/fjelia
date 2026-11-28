import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/screens/body/diary_sheet.dart';
import 'package:fjelia/screens/body/gear_sheet.dart';
import 'package:fjelia/screens/body/lab_tests_sheet.dart';
import 'package:fjelia_views/fjelia_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> show(WidgetTester tester, Widget sheet) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: sheet),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  testWidgets('gear shows its distance and wear', (tester) async {
    await tester.runAsync(() async {
      await GearEdits(db).add(
        kind: 'shoes',
        name: 'Pegasus',
        sports: ['running'],
        startKm: 520,
        retireAtKm: 600,
        firstUsed: DateTime(2026, 1, 1),
      );
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'r',
              name: 'Run',
              type: 'running',
              startDate: DateTime(2026, 3, 1),
              durationSeconds: 3600,
              distanceMeters: const Value(30000),
            ),
          );
    });
    await show(tester, const GearSheet());
    expect(find.text('PEGASUS'), findsOneWidget); // card titles are capitals
    expect(find.textContaining('1 activity'), findsOneWidget);
    expect(find.text('550 km'), findsOneWidget);
    expect(find.text('50 km left of 600'), findsOneWidget);
  });

  testWidgets('the diary lists notes', (tester) async {
    await tester.runAsync(
      () => db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'r',
              name: 'Hill Run',
              type: 'running',
              startDate: DateTime(2026, 11, 20),
              durationSeconds: 3600,
              athleteNote: const Value('Calves tight'),
            ),
          ),
    );
    await show(tester, const DiarySheet());
    expect(find.text('Calves tight'), findsOneWidget);
  });

  testWidgets('a lab test shows its thresholds', (tester) async {
    await tester.runAsync(
      () => LabTestEdits(db).add(
        date: DateTime(2026, 11, 20),
        sport: 'cycling',
        steps: const [
          LactateStep(intensity: 150, lactate: 1.0, heartRate: 124),
          LactateStep(intensity: 200, lactate: 1.3, heartRate: 137),
          LactateStep(intensity: 250, lactate: 2.0, heartRate: 151),
          LactateStep(intensity: 300, lactate: 3.6, heartRate: 166),
          LactateStep(intensity: 350, lactate: 7.2, heartRate: 180),
        ],
      ),
    );
    await show(tester, const LabTestsSheet());
    expect(find.text('Aerobic threshold (LT1)'), findsOneWidget);
    expect(find.text('Use as thresholds'), findsOneWidget);
  });
}
