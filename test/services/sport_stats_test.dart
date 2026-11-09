import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/fjelia_edition_provider.dart';
import 'package:fjelia/providers/sport_stats_provider.dart';
import 'package:fjelia/screens/activities/sport_stats_card.dart';
import 'package:fjelia/services/sport_stats.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Samples every second at [speed] m/s for [seconds], with a stop of
/// [stopSeconds] after [stopAfter] seconds.
String run(
  double speed,
  int seconds, {
  int stopAfter = -1,
  int stopSeconds = 0,
  bool timestamps = true,
}) {
  final start = DateTime.utc(2026, 5, 1, 7).millisecondsSinceEpoch;
  final out = <Map<String, Object>>[];
  var d = 0.0;
  var clock = 0;
  for (var i = 0; i <= seconds; i++) {
    if (i == stopAfter) clock += stopSeconds;
    out.add({if (timestamps) 't': start + clock * 1000, 'd': d, 'spd': speed});
    d += speed;
    clock++;
  }
  return jsonEncode(out);
}

class _Edition implements FjeliaEdition {
  const _Edition(this.isPro);
  @override
  bool get proOffered => true;
  @override
  final bool isPro;
}

void main() {
  test('the fastest stretch, and a red light does not spoil it', () {
    // 4 m/s for 30 min: 1K in 250 s, 5K in 1250 s.
    final steady = bestEfforts(run(4, 1800), [1000, 5000, 10000]);
    expect(steady[1000], closeTo(250, 1));
    expect(steady[5000], closeTo(1250, 1));
    expect(steady.containsKey(10000), isFalse); // only 7.2 km
    final stopped = bestEfforts(
      run(4, 1800, stopAfter: 600, stopSeconds: 120),
      [5000],
    );
    expect(stopped[5000], closeTo(1250, 2));
    // Without timestamps the time comes from speed and distance.
    final speedOnly = bestEfforts(run(4, 1800, timestamps: false), [5000]);
    expect(speedOnly[5000], closeTo(1250, 1));
    expect(bestEfforts('not json', [1000]), isEmpty);
  });

  test('totals, records and efforts with their dates', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    Future<void> add(
      String id,
      String type,
      DateTime at,
      String json,
      double meters,
      int seconds,
      double elevation,
    ) => db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: id,
            name: id,
            type: type,
            startDate: at,
            durationSeconds: seconds,
            distanceMeters: Value(meters),
            totalElevation: Value(elevation),
            metricsJson: Value(json),
          ),
        );
    final now = DateTime(2026, 11, 9);
    await add(
      'old',
      'running',
      DateTime(2025, 6, 1),
      run(4.2, 1500),
      6300,
      1500,
      50,
    );
    await add(
      'new',
      'running',
      DateTime(2026, 11, 2),
      run(4, 1800),
      7200,
      1800,
      80,
    );
    await add(
      'ride',
      'cycling',
      DateTime(2026, 10, 20),
      run(9, 4000),
      36000,
      4000,
      400,
    );

    final stats = await computeSportStats(db, now);
    final r = stats[StatsSport.run]!;
    expect(r.allTime.count, 2);
    expect(r.year.count, 1);
    expect(r.last4PerWeek.meters, closeTo(7200 / 4, 1));
    final fiveK = r.efforts.firstWhere((e) => e.label == '5K');
    expect(fiveK.allTimeDate, DateTime(2025, 6, 1)); // 4.2 m/s is faster
    expect(fiveK.yearDate, DateTime(2026, 11, 2));
    final ride = stats[StatsSport.ride]!;
    expect(ride.longest, 36000);
    expect(ride.mostElevation, 400);
    expect(
      ride.efforts.firstWhere((e) => e.label == '30K').allTime,
      closeTo(30000 / 9, 2),
    );
    final lines = sportStatsLines(stats, now).join('\n');
    expect(lines, contains('[SportStats:Run,'));
    expect(lines, contains('Year2026(act 1,dist 7.2km'));
    expect(lines, contains('[BestEfforts:Run,'));
    expect(lines, contains('5K:19:50 (2025-06-01) year 20:50 (2026-11-02)'));
  });

  testWidgets('the card shows running and switches to riding', (tester) async {
    final stats = {
      StatsSport.run: SportStats(
        sport: StatsSport.run,
        last4PerWeek: const StatsTotals(4, 30100, 12420, 217),
        year: const StatsTotals(149, 1342700, 519900, 9189),
        allTime: const StatsTotals(300, 2600000, 900000, 20000),
        efforts: [
          BestEffort(
            '5K',
            5000,
            allTime: 1322,
            allTimeDate: DateTime(2025, 5, 3),
          ),
        ],
      ),
      StatsSport.ride: SportStats(
        sport: StatsSport.ride,
        last4PerWeek: const StatsTotals(2, 104600, 16020, 1052),
        year: const StatsTotals(123, 3553500, 518940, 23552),
        allTime: const StatsTotals(123, 3553500, 518940, 23552),
        efforts: const [],
        longest: 421700,
        longestDate: DateTime(2026, 6, 20),
      ),
    };
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sportStatsProvider.overrideWith((ref) async => stats),
          fjeliaEditionProvider.overrideWithValue(const _Edition(true)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: SportStatsCard()),
          ),
        ),
      ),
    );
    await tester.pump();
    // Folded: one highlight at a time, rounded.
    expect(find.text('30 km'), findsOneWidget);
    expect(find.text('22:02'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('1,343 km'), findsOneWidget);
    // Unfolded: the period as four figures, records and best efforts.
    await tester.tap(find.text('1,343 km'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('4 weeks'), findsOneWidget);
    expect(find.text('3h 27m'), findsOneWidget);
    expect(find.text('22:02'), findsOneWidget);
    await tester.tap(find.text('2026'));
    await tester.pump();
    expect(find.text('144 h'), findsOneWidget);
    expect(find.text('9,189 m'), findsOneWidget);
    await tester.tap(find.text('Cycling'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('422 km'), findsOneWidget);
    // A tap on the figures folds the card again.
    await tester.tap(find.text('422 km'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('4 weeks'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without Pro the card only leads to Pro', (tester) async {
    var computed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sportStatsProvider.overrideWith((ref) async {
            computed = true;
            return const {};
          }),
          fjeliaEditionProvider.overrideWithValue(const _Edition(false)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: SportStatsCard()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('sport-stats-locked')), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
    expect(computed, isFalse);
  });
}
