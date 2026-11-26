import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/fjelia_edition_provider.dart';
import 'package:fjelia/screens/races/race_course_sheet.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:fjelia_views/fjelia_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Edition implements FjeliaEdition {
  const _Edition(this.isPro);
  @override
  final bool isPro;
  @override
  bool get proOffered => true;
}

class _NoTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGPYcunOfwAI'
          'AgNiJBgw5wAAAABJRU5ErkJggg==',
        ),
      );
}

/// 10 km: up 500 m at 10 % to a checkpoint, then down.
String gpx() {
  const perDegree = 111195.0;
  final b = StringBuffer('<gpx version="1.1">')
    ..write('<wpt lat="${5000 / perDegree}" lon="0"><name>Summit</name></wpt>')
    ..write('<trk><trkseg>');
  for (var m = 0.0; m <= 10000; m += 25) {
    final ele = m <= 5000 ? 200 + m * 0.1 : 700 - (m - 5000) * 0.1;
    b.write('<trkpt lat="${m / perDegree}" lon="0"><ele>$ele</ele></trkpt>');
  }
  return '$b</trkseg></trk></gpx>';
}

void main() {
  late AppDatabase db;
  late RaceGoal goal;
  setUp(() async {
    courseTileProvider = _NoTiles();
    db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();
    await db
        .into(db.raceGoals)
        .insert(
          RaceGoalsCompanion.insert(
            id: 'g',
            athleteId: 'self',
            name: 'Hill Race',
            primarySport: 'trail_running',
            distanceM: 10000,
            raceDate: now.add(const Duration(days: 30)),
            priority: 'A',
            source: 'manual',
            createdAt: now,
          ),
        );
    goal = await db.select(db.raceGoals).getSingle();
    await RaceCourseEdits(db).setFromGpx('g', gpx());
    for (final (id, grade, pace) in [('f', 0.0, 330.0), ('h', 0.1, 520.0)]) {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: id,
              name: 'Run',
              type: 'trail_running',
              startDate: now.subtract(const Duration(days: 4)),
              durationSeconds: 3600,
              metricsJson: Value(
                jsonEncode([
                  for (var s = 0; s <= 3600; s += 10)
                    {
                      't': s * 1000,
                      'd': s / pace * 1000,
                      'ele': s / pace * 1000 * grade,
                    },
                ]),
              ),
            ),
          );
    }
  });
  tearDown(() async {
    courseTileProvider = null;
    await db.close();
  });

  Future<void> show(WidgetTester tester, {required bool pro}) async {
    await tester.binding.setSurfaceSize(const Size(430, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          fjeliaEditionProvider.overrideWithValue(_Edition(pro)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RaceCourseSheet(goal: goal)),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
    }
  }

  testWidgets('the course is analysed for everyone', (tester) async {
    await show(tester, pro: false);
    expect(find.text('10 km'), findsOneWidget);
    expect(find.textContaining('of 50 m or more').evaluate(), isEmpty);
    expect(find.text('+10 %'), findsWidgets);
    expect(
      find.textContaining('from your own running on hills'),
      findsOneWidget,
    );
    expect(find.text('Summit'), findsNothing);
  });

  testWidgets('with FjeliaPro: the finish and each checkpoint', (tester) async {
    await show(tester, pro: true);
    expect(find.text('Summit'), findsOneWidget);
    expect(find.textContaining('Grade-adjusted pace'), findsOneWidget);
  });
}
