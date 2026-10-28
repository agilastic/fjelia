import 'package:fjelia/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:fjelia/providers/health_monitor_alerts_provider.dart';
import 'package:fjelia/widgets/app_widgets.dart' show HistoryChart, SectionCard;
import 'package:fjelia/widgets/health_monitor_grid.dart';
import 'package:fjelia/widgets/metric_card.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fjelia/widgets/activity_route_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/heat_acclimation_provider.dart';
import 'package:fjelia/providers/nutrition_provider.dart';
import 'package:fjelia/models/workout_nutrition.dart';
import 'package:fjelia/models/heat_acclimation.dart';
import 'package:fjelia/services/location_service.dart';
import 'package:fjelia/services/lt2_tt_service.dart';
import 'package:fjelia/services/lt1_drift_service.dart';
import 'package:fjelia/screens/activities/load_visuals.dart';
import 'package:fjelia/screens/activities/load_optional_cards.dart';
import 'package:fjelia/widgets/hr_timeline_card.dart';
import 'package:fjelia/models/heart_rate.dart';
import 'package:fjelia/widgets/bio_age_card.dart';
import 'package:fjelia/providers/source_priority_provider.dart';
import 'package:fjelia/screens/onboarding/connect_garmin_screen.dart';
import 'package:fjelia/screens/home/home_screen.dart';
import 'package:fjelia/screens/strain/activity_detail_sheet.dart';
import 'package:fjelia/screens/activities/activities_screen.dart';
import 'package:fjelia/screens/strain/strain_screen.dart';
import 'package:fjelia/screens/activities/load_metric_sheet.dart';
import 'package:fjelia/screens/activities/training_monitor_card.dart';
import 'package:fjelia/screens/activities/training_form_card.dart';
import 'package:fjelia/screens/activities/lt2_test_sheet.dart';
import 'package:fjelia/screens/activities/threshold_sheets.dart';
import 'package:fjelia/screens/activities/heat_weather_sheet.dart';
import 'package:fjelia/screens/planner/plan_screen.dart';
import 'package:fjelia/screens/planner/plan_session_sheet.dart';
import 'package:fjelia/screens/ai_coach/ai_coach_screen.dart';
import 'package:fjelia/widgets/coach_context_card.dart';
import 'package:fjelia/services/activity_decoder.dart';
import 'package:fjelia/models/coach_context_card.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/auth_provider.dart';
import 'package:fjelia/api/garmin_client.dart';
import 'package:fjelia/services/workout_template_library.dart';

import '../support/fake_workout_garmin.dart';

import 'package:fjelia/screens/settings/settings_sheet.dart';
import 'package:fjelia/screens/settings/profile_tab.dart';
import 'package:fjelia/screens/settings/hr_zones_tab.dart';
import 'package:fjelia/screens/settings/display_tab.dart';
import 'package:fjelia/screens/settings/training_tab.dart';
import 'package:fjelia/screens/settings/race_goal_editor.dart';
import 'package:fjelia/screens/settings/connections_tab.dart';
import 'package:fjelia/screens/settings/ai_settings_tab.dart';
import 'package:fjelia/screens/settings/system_tab.dart';
import 'package:fjelia/screens/settings/bug_report_sheet.dart';
import 'package:fjelia/screens/sleep/sleep_screen.dart';
import 'package:fjelia/screens/battery/battery_screen.dart';
import 'package:fjelia/screens/bloodpressure/bp_screen.dart';
import 'package:fjelia/screens/renpho/renpho_screen.dart';
import 'package:fjelia/screens/ocr/manual_entry_sheet.dart';
import 'package:fjelia/widgets/grip_strength_sheet.dart';
import 'package:fjelia/widgets/metric_detail_sheet.dart';
import 'package:fjelia/theme/app_theme.dart';

/// Scrolls [target] clear of the bottom edge and taps it. A plain
/// `ensureVisible` leaves a button at the very edge of a short test screen.
Future<void> tapLow(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
  await tester.pumpAndSettle();
  await tester.tap(target);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUpAll(() async {
    // No Apple Intelligence in widget tests: the availability check errors.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.foundation_models_framework.'
          'FoundationModelsApi.checkAvailability',
          (_) async => const StandardMessageCodec().encodeMessage(<Object?>[
            'unavailable',
            'Not available in tests',
            null,
          ]),
        );
    if (Platform.environment['FJELIA_UI_PREVIEW_DIR'] == null) return;
    final font = File(
      Platform.environment['FJELIA_UI_FONT'] ??
          '/System/Library/Fonts/Supplemental/Arial.ttf',
    );
    if (font.existsSync()) {
      final loader = FontLoader('Roboto');
      loader.addFont(
        Future.value(ByteData.sublistView(await font.readAsBytes())),
      );
      await loader.load();
    }
    try {
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    } catch (_) {
      /* The regular test runner may not bundle icon fonts. */
    }
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'user_profile_v1': jsonEncode({
        'birthYear': 1982,
        'heightCm': 192,
        'debugMode': true,
      }),
      'ai_coach_enabled': 'false',
    });
    SharedPreferences.setMockInitialValues({'heat_acclimation_enabled': false});
    db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();
    for (var i = 0; i < 20; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      await db.upsertHrv(
        HrvRecordsCompanion.insert(
          date: d,
          hrvLastNight: Value(38.0 + i),
          restingHeartRate: Value(50 - i % 5),
          spo2: const Value(95),
          respirationRate: const Value(14.1),
          stressLevel: const Value(25),
          skinTempDelta: const Value(-.4),
          computedEnergie: const Value(46),
        ),
      );
      await db.upsertWellness(
        WellnessRecordsCompanion.insert(date: d, steps: const Value(683)),
      );
      await db.upsertSleep(
        SleepRecordsCompanion.insert(
          date: d,
          totalSleepSeconds: 24000,
          deepSleepSeconds: 3000,
          remSleepSeconds: 6000,
          lightSleepSeconds: 15000,
          awakeSleepSeconds: 1800,
          sleepScore: const Value(44),
        ),
      );
      await db.upsertRenphoMeasurements([
        RenphoRecordsCompanion.insert(
          measuredAt: d,
          rawJson: '{}',
          weight: Value(86.7 + i / 10),
          bodyFat: const Value(16.5),
          muscleMass: const Value(54.2),
          bmi: const Value(23.5),
        ),
      ]);
    }
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'preview-run',
            name: 'Alcúdia Laufen',
            type: 'running',
            startDate: now.subtract(const Duration(days: 1)),
            durationSeconds: 3501,
            distanceMeters: const Value(7580),
            movingDurationSeconds: const Value(3358),
            avgHeartRate: const Value(150),
            maxHeartRate: const Value(167),
            avgWatts: const Value(267),
            totalElevation: const Value(70),
            trainingLoad: const Value(165.6),
            hrZonesJson: const Value(
              '{"zone1":11,"zone2":13,"zone3":32,"zone4":37,"zone5":7}',
            ),
            metricsJson: Value(
              jsonEncode([
                for (var i = 0; i < 30; i++)
                  {
                    'd': i * 250.0,
                    'hr': 130 + i.toDouble(),
                    'spd': 2.0 + i % 3,
                    'ele': 2.0 + i % 10,
                    'w': 200.0 + i,
                  },
              ]),
            ),
          ),
        );
    await db.upsertHeatWorkoutContext(
      HeatWorkoutContextsCompanion.insert(
        activityId: 'preview-run',
        activityStart: now.subtract(const Duration(days: 1)),
        source: 'test',
        isOutdoor: true,
        qualifies: true,
        durationMinutes: 58,
        temperatureC: const Value(23.5),
        humidityPct: const Value(70),
        pressureHpa: const Value(1025),
        wetBulbC: const Value(19.5),
        weatherCacheKey: const Value('weather-0'),
        scoreBefore: 16,
        scoreAfter: 28,
      ),
    );
    for (var i = 0; i < 4; i++) {
      await db.upsertWeatherSnapshot(
        WeatherSnapshotRecordsCompanion.insert(
          cacheKey: 'weather-$i',
          source: 'test',
          observedAt: now
              .subtract(const Duration(days: 1))
              .add(Duration(minutes: i * 15)),
          latitude: 39.74,
          longitude: 3.15,
          temperatureC: 23.5 - i,
          humidityPct: 70,
          wetBulbC: 19.5,
          rawJson: '{}',
        ),
      );
    }
    await db.insertBpMeasurements([
      BpMeasurementsCompanion.insert(
        measuredAt: now,
        systolic: 126,
        diastolic: 67,
        heartRate: 58,
      ),
    ]);
  });
  tearDown(() => db.close());
  final previewKey = GlobalKey();
  Future<void> capture(WidgetTester tester, String name) async {
    final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    if (output != null) {
      final boundary =
          previewKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File('$output/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpAndSettle();
    }
  }

  Future<void> seedLoadReference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('visible_load_weekday_load', false);
    await prefs.setBool('visible_load_plan_banner', false);
    final date = DateTime(2026, 10, 19);
    await Lt2TtService.save(
      Lt2TtResult(
        lt2: 165,
        pace: '4:41/km',
        paceSec: 281,
        at: DateTime(2026, 7, 28),
        activityId: 'fixture-tt',
      ),
    );
    await Lt1DriftService.save(
      Lt1DriftResult(
        lt1: 136,
        h1: 137,
        h2: 136,
        drift: -.8,
        pace: 404,
        at: DateTime(2026, 7, 28),
        activityId: 'fixture-drift',
      ),
    );
    for (var i = 0; i < 90; i++) {
      final d = DateTime(date.year, date.month, date.day - i);
      await db.upsertWellness(
        WellnessRecordsCompanion.insert(date: d, vo2max: const Value(51)),
      );
    }
    await db.upsertThresholdRecord(
      date: DateTime(2026, 6, 29),
      activityId: 'fixture-tt',
      source: 'tt',
      lt2Bpm: 165,
      lt2PaceSec: 281,
    );
    await db.insertFtpSnapshot(264, 'ftp_manual', date: DateTime(2026, 7, 28));
    await db.insertFtpSnapshot(251, 'ftp_manual', date: DateTime(2026, 10, 19));
    await db
        .into(db.athleteThresholds)
        .insertOnConflictUpdate(
          AthleteThresholdsCompanion(
            athleteId: const Value('self'),
            ftpWatts: const Value(264),
            lastUpdatedAt: Value(date),
          ),
        );
    for (var i = 0; i < 12; i++) {
      await db
          .into(db.activityRecords)
          .insertOnConflictUpdate(
            ActivityRecordsCompanion.insert(
              activityId: 'fixture-week-$i',
              name: 'Weekly training',
              type: i.isEven ? 'cycling' : 'running',
              startDate: DateTime(
                date.year,
                date.month,
                date.day - 7 * (i + 1) + 2,
              ),
              durationSeconds: 7200,
              distanceMeters: const Value(50000),
              trainingLoad: Value(
                [
                  2097,
                  700,
                  650,
                  670,
                  950,
                  690,
                  730,
                  500,
                  710,
                  560,
                  300,
                  2100,
                ][i].toDouble(),
              ),
              totalElevation: Value(i == 0 ? 1100.0 : 130.0 + i * 30),
              hrZonesJson: i == 4
                  ? const Value('{"zone1":30,"zone2":16,"zone3":53,"zone4":1}')
                  : i == 5
                  ? const Value('{"zone1":60,"zone2":40}')
                  : i == 6
                  ? const Value('{"zone1":30,"zone2":21,"zone3":40,"zone4":9}')
                  : const Value.absent(),
            ),
          );
    }
    for (var i = 0; i < 4; i++) {
      await db
          .into(db.activityRecords)
          .insertOnConflictUpdate(
            ActivityRecordsCompanion.insert(
              activityId: 'fixture-power-$i',
              name: [
                'Indoor Cycling',
                'Indoor Cycling',
                'Zürich Virtuelles Radfahren',
                'Houyet Virtuelles Radfahren',
              ][i],
              type: 'cycling',
              startDate: DateTime(2026, 7 - i, 28),
              durationSeconds: 1800,
              metricsJson: Value(
                jsonEncode([
                  for (var t = 0; t <= 1800; t += 10)
                    {
                      'd': t * 5,
                      'spd': 5,
                      'w': [278, 260, 222, 230][i],
                    },
                ]),
              ),
            ),
          );
    }
  }

  List<HeatDailyStateData> heatFixture(int days) => [
    for (var i = 0; i < days; i++)
      HeatDailyStateData(
        date: DateTime(2026, 10, 20 - days + i),
        score: days == 7
            ? [17.0, 16.0, 29.0, 40.0, 37.0, 35.0, 33.0][i]
            : 20 + i % 25.toDouble(),
        status: HeatStatus.partial,
        decayApplied: 0,
        workoutGain: 0,
        updatedAt: DateTime(2026, 10, 19),
      ),
  ];

  Future<void> render(
    WidgetTester tester,
    Widget view,
    String name, {
    FakeWorkoutGarmin? garmin,
  }) async {
    final referenceLoad =
        Platform.environment['FJELIA_UI_PREVIEW_DIR'] != null &&
        name.startsWith('load');
    if (referenceLoad) await seedLoadReference();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          nutritionConditionsProvider.overrideWith(
            (ref, workout) async => const NutritionConditions(),
          ),
          nutritionPlanProvider.overrideWith(
            (ref, workout) async => planNutrition(
              workout,
              const NutritionPreferences(),
              const NutritionConditions(),
            ),
          ),
          if (!referenceLoad)
            heatPreferredLocationProvider.overrideWith((ref) async => null),
          if (referenceLoad) ...[
            selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 19)),
            heatTodayStateProvider.overrideWith(
              (ref) async => heatFixture(7).last,
            ),
            heatHistoryProvider.overrideWith(
              (ref, days) async => heatFixture(days),
            ),
            heatPreferredLocationProvider.overrideWith(
              (ref) async => CurrentLocationData(
                latitude: 39.8021,
                longitude: 3.1191,
                timestamp: DateTime(2026, 10, 19),
              ),
            ),
            trainingMonitorProvider.overrideWith(
              (ref, date) async => const TrainingMonitorSummary(
                dayLoad: 41,
                ctl: 182,
                atl: 308,
                optimalLow: 146,
                optimalHigh: 201,
                vo2max: 51,
                weekHours: 0,
                previousWeekHours: 15.2,
                weekKm: 0,
                previousWeekKm: 296.8,
                weekLoad: 0,
              ),
            ),
            trainingFormSeriesProvider.overrideWith(
              (ref) async => [
                for (var i = 0; i < 90; i++)
                  FormPoint(
                    date: DateTime(2026, 10, 19 - 89 + i),
                    ctl: 160 + i / 5,
                    atl: i > 85 ? 250 + (i - 86) * 20 : 150 + (i % 8) * 3,
                    load: 100,
                  ),
              ],
            ),
          ],
          if (garmin != null) garminClientProvider.overrideWithValue(garmin),
        ],
        child: RepaintBoundary(
          key: previewKey,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            home: Scaffold(body: SafeArea(child: view)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: name);
    await capture(tester, name);
  }

  Future<TrainingSession> plannedSession(
    String name,
    String sport,
    int zone,
    int duration,
    int trimp,
  ) async {
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    final template = await (db.select(
      db.workoutTemplates,
    )..where((t) => t.name.equals(name))).getSingle();
    final date = DateTime(
      2026,
      10,
      sport == 'cycling_gravel'
          ? 32
          : sport == 'swimming'
          ? 25
          : 27,
    );
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'preview-plan',
            athleteId: 'self',
            startDate: DateTime(2026, 10, 19),
            endDate: DateTime(2027, 4, 9),
            status: 'active',
            generatedAt: DateTime.now(),
          ),
        );
    await db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: 'planned-preview',
            planId: 'preview-plan',
            athleteId: 'self',
            sessionDate: date,
            sessionNumber: 1,
            weekNumber: sport == 'cycling_gravel' ? 3 : 2,
            sport: sport,
            sessionType: template.sessionType,
            subType: Value(template.subType),
            phase: 'base',
            primaryZone: zone,
            title: name,
            sessionNotes: Value(template.description),
            mainSet: Value(template.coachingCues),
            stepsJson: Value(template.stepsJson),
            plannedDurationMin: duration,
            plannedTrimp: trimp,
            sessionLevel: 2,
          ),
        );
    return (await db.select(db.trainingSessions).get()).single;
  }

  final pages = <String, Widget>{
    'health': const HomeScreen(),
    'settings': const SettingsSheet(),
    'profile': const ProfileTab(),
    'basics': const ProfileEditor(section: 0),
    'habits': const ProfileEditor(section: 1),
    'labs': const ProfileEditor(section: 2),
    'hr-zones': const HrZonesTab(),
    'display': const DisplayTab(),
    'training': const TrainingTab(),
    'race-goal': const RaceGoalEditor(),
    'connections': const ConnectionsTab(),
    'ai-settings': const AiSettingsTab(),
    'system': const SystemTab(),
    'export': const DataExportPage(),
    'developer': const DeveloperPage(),
    'bug-report': const BugReportSheet(),
    'blood-pressure': const BpScreen(),
    'body': const RenphoScreen(),
    'weekday-comparison': const SingleChildScrollView(child: WeekdayLoadCard()),
    'sleep': const SleepScreen(),
    'energy': const BatteryScreen(),
    'grip': const GripStrengthSheet(),
    'weight-history': const MetricDetailSheet(metric: HealthMetric.weight),
    'hrv-history': const MetricDetailSheet(metric: HealthMetric.hrv),
    'rhr-history': const MetricDetailSheet(metric: HealthMetric.rhr),
    'body-fat-history': const MetricDetailSheet(metric: HealthMetric.bodyFat),
    'muscle-history': const MetricDetailSheet(metric: HealthMetric.muscle),
    'bmi-history': const MetricDetailSheet(metric: HealthMetric.bmi),
    'bio-age': const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: BioAgeCard(expanded: true),
    ),
    'heart-timeline': const HrTimelineScreen(),
    'measurement': const ManualEntrySheet(),
    'load': const StrainScreen(embedded: true),
    'load-monitor': const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: TrainingMonitorCard(),
      ),
    ),
    'load-form': const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: TrainingFormCard(),
      ),
    ),
    'load-vo2-running': const LoadMetricSheet(metric: 'VO₂max running'),
    'load-vo2-cycling': const LoadMetricSheet(metric: 'VO₂max cycling'),
    'load-hours': const LoadMetricSheet(metric: 'Activity hours'),
    'load-distance': const LoadMetricSheet(metric: 'Activity km'),
    'load-lt2': const Lt2TestSheet(),
    'load-ftp': const FtpDetailSheet(),
    'load-running-zones': const LoadZonesSheet(),
    'load-power-zones': const LoadZonesSheet(power: true),
    'load-heat': const HeatWeatherSheet(),
    'activity-log': const ActivitiesScreen(),
    'plan-history': const PlanScreen(),
    'activity-map': ActivityRouteMap(
      route: const [
        LatLng(39.74, 3.15),
        LatLng(39.78, 3.10),
        LatLng(39.77, 3.18),
      ],
      tileProvider: AuditTiles(),
      exportGpx: (_) async {},
    ),
  };
  for (final page in pages.entries) {
    testWidgets('${page.key} renders at iPhone width', (tester) async {
      await render(tester, page.value, page.key);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    });
  }
  testWidgets('LT2 tabs expose calculation controls and history', (
    tester,
  ) async {
    await render(tester, const Lt2TestSheet(), 'load-lt2-protocol');
    expect(find.text('30-MIN TT'), findsOneWidget);
    await tester.tap(find.text('CALCULATE'));
    await tester.pumpAndSettle();
    expect(find.text('Warm-up before TT'), findsOneWidget);
    expect(find.text('Calculate LT2'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Calculate LT2'),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Calculate LT2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Select the TT activity first'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await capture(tester, 'load-lt2-calculate');
    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();
    await capture(tester, 'load-lt2-history');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('LOAD monitor opens the selected metric and LT2 tabs', (
    tester,
  ) async {
    await render(
      tester,
      const SingleChildScrollView(child: TrainingMonitorCard()),
      'load-monitor',
    );
    await tester.tap(find.text('ACTIVITY HOURS'));
    await tester.pumpAndSettle();
    expect(find.text('14D'), findsOneWidget);
    await tester.tap(find.text('30D'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<LoadRange>(find.byType(LoadRange))
          .any((range) => range.selected == '30D'),
      isTrue,
    );
    await tester.dragFrom(
      tester.getTopLeft(find.byType(LoadSheet).last) + const Offset(100, 14),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('LT2 THRESHOLD'));
    await tester.pumpAndSettle();
    expect(find.text('PROTOCOL'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('LOAD lower cards and form expansion remain reachable', (
    tester,
  ) async {
    await render(tester, const StrainScreen(embedded: true), 'load');
    await tester.scrollUntilVisible(
      find.text('ZONE POLARIZATION'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await capture(tester, 'load-history');
    await tester.scrollUntilVisible(
      find.byTooltip('Expand training form'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Expand training form'));
    await tester.tap(find.byTooltip('Expand training form'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      tester
          .widgetList<TrainingFormCard>(find.byType(TrainingFormCard))
          .where((card) => card.fullscreen),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'FTP activity selection saves 95 percent of the best twenty minutes',
    (tester) async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'power-test-ride',
              name: 'Power test ride',
              type: 'cycling',
              startDate: DateTime.now(),
              durationSeconds: 1800,
              metricsJson: Value(
                jsonEncode([
                  for (var t = 0; t <= 1800; t += 10)
                    {'d': t * 5, 'spd': 5, 'w': 300},
                ]),
              ),
            ),
          );
      await render(tester, const FtpDetailSheet(), 'load-ftp');
      await tester.ensureVisible(find.text('Power test ride'));
      await tester.tap(find.text('Power test ride'));
      await tester.pumpAndSettle();
      final records = await db.getAllThresholdRecords();
      expect(records.where((r) => r.ftpWatts == 285), hasLength(1));
      expect(find.textContaining('285 W'), findsWidgets);
      await capture(tester, 'load-ftp-saved');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'LOAD full dashboard includes original toolbar and tab navigation',
    (tester) async {
      await render(tester, const HomeScreen(), 'load-shell');
      await tester.tap(find.text('LOAD').last);
      await tester.pumpAndSettle();
      await capture(tester, 'load-shell');
      expect(find.byTooltip('Send feedback or report a bug'), findsOneWidget);
      expect(find.byTooltip('Add measurement'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('LOAD overview renders every card in one continuous comparison', (
    tester,
  ) async {
    await render(tester, const StrainScreen(embedded: true), 'load');
    tester.view.physicalSize = const Size(393, 2250);
    await tester.binding.setSurfaceSize(const Size(393, 2250));
    await tester.pumpAndSettle();
    await capture(tester, 'load-overview-all');
    expect(find.text('ZONE POLARIZATION'), findsOneWidget);
    expect(find.text('ELEVATION'), findsOneWidget);
    expect(find.text('TRAINING MONITOR'), findsOneWidget);
    // Twelve polarization weeks make the overview taller. Every card must
    // remain reachable in the same scroll view, including the form card.
    await tester.scrollUntilVisible(
      find.text('FORM · ATL / CTL / TSB'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('FORM · ATL / CTL / TSB'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'activity history average uses recorded days and keeps empty calendar days',
    (tester) async {
      await render(
        tester,
        const LoadMetricSheet(metric: 'Activity hours'),
        'activity-average',
      );
      expect(find.text('AVG  1.0 h'), findsOneWidget);
      await tester.tap(find.text('30D'));
      await tester.pumpAndSettle();
      expect(find.text('AVG  1.0 h'), findsOneWidget);
      expect(
        tester.widget<LoadTrendChart>(find.byType(LoadTrendChart)).points,
        hasLength(30),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('form status boundaries', (tester) async {
    expect(formStatus(16), 'Fresh');
    expect(formStatus(15), 'Optimal');
    expect(formStatus(5), 'Neutral');
    expect(formStatus(-10), 'Tired');
    expect(formStatus(-20), 'Very Fatigued');
    expect(formStatus(null), 'No history');
    expect(loadWeekNumber(DateTime(2026, 10, 19)), 43);
    expect(loadWeekNumber(DateTime(2021, 1, 1)), 53);
  });
  testWidgets(
    'LOAD metric modal matches the short sheet and dismisses by dragging',
    (tester) async {
      await render(tester, const HomeScreen(), 'load-shell');
      await tester.tap(find.text('LOAD').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('VO2MAX RUNNING'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('VO2MAX RUNNING'));
      await tester.tap(find.text('VO2MAX RUNNING'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        tester.getSize(find.byType(LoadSheet)).height,
        closeTo(852 * .55, 1),
      );
      await capture(tester, 'load-vo2-running-modal');
      await tester.dragFrom(
        tester.getTopLeft(find.byType(LoadSheet)) + const Offset(100, 14),
        const Offset(0, 600),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'LOAD reference sheets preserve their original heights and backdrop',
    (tester) async {
      await render(tester, const HomeScreen(), 'load-shell');
      await tester.tap(find.text('LOAD').last);
      await tester.pumpAndSettle();
      for (final target in [
        ('VO2MAX RUNNING', 'load-vo2-running-modal', .55),
        ('ACTIVITY HOURS', 'load-hours-modal', .55),
        ('ACTIVITY KM', 'load-distance-modal', .55),
        ('FTP CYCLING', 'load-ftp-modal', .72),
        ('LT2 THRESHOLD', 'load-lt2-protocol-modal', .625),
      ]) {
        await tester.scrollUntilVisible(
          find.text(target.$1),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(target.$1));
        await tester.tap(find.text(target.$1));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(LoadSheet)).height,
          closeTo(852 * target.$3, 1),
        );
        await capture(tester, target.$2);
        if (target.$1 == 'LT2 THRESHOLD') {
          await tester.tap(find.text('CALCULATE'));
          await tester.pumpAndSettle();
          await capture(tester, 'load-lt2-calculate-modal');
          await tester.tap(find.text('HISTORY'));
          await tester.pumpAndSettle();
          await capture(tester, 'load-lt2-history-modal');
        }
        await tester.dragFrom(
          tester.getTopLeft(find.byType(LoadSheet)) + const Offset(100, 14),
          const Offset(0, 700),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
      }
      if (Platform.environment['FJELIA_UI_PREVIEW_DIR'] != null) {
        await tester.scrollUntilVisible(
          find.text('HEAT ACCLIMATION'),
          -300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('HEAT ACCLIMATION'));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(LoadSheet)).height,
          closeTo(852 * .82, 1),
        );
        await capture(tester, 'load-heat-modal');
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'heat setup remains reachable when disabled and follows its visibility setting',
    (tester) async {
      await render(tester, const StrainScreen(embedded: true), 'heat-disabled');
      expect(find.text('HEAT ACCLIMATION'), findsOneWidget);
      expect(find.text('Set up in Training settings'), findsOneWidget);
      await tester.tap(find.text('HEAT ACCLIMATION'));
      await tester.pumpAndSettle();
      expect(find.byType(TrainingTab), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('visible_load_heat_acclimation', false);
      await render(tester, const StrainScreen(embedded: true), 'heat-hidden');
      expect(find.text('HEAT ACCLIMATION'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'profile basics and habits save values and show conditional fields',
    (tester) async {
      await render(tester, const ProfileEditor(section: 0), 'basics');
      expect(find.text('age 44'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('waistCm')), '88');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();
      var raw = await const FlutterSecureStorage().read(key: 'user_profile_v1');
      expect(jsonDecode(raw!)['waistCm'], 88);
      expect(jsonDecode(raw)['sex'], 'f');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await render(tester, const ProfileEditor(section: 1), 'habits');
      await tester.tap(find.text('Former'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('yearsSinceQuit')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('yearsSinceQuit')),
        '20',
      );
      await tester.pumpAndSettle();
      raw = await const FlutterSecureStorage().read(key: 'user_profile_v1');
      expect(jsonDecode(raw!)['yearsSinceQuit'], 20);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'Health Monitor alerts compare previous fourteen days excluding selected day',
    (tester) async {
      final day = DateTime(2020, 10, 20);
      for (final row in [
        (15, 200, -.8),
        (14, 60, -.2),
        (1, 70, -.1),
        (0, 74, -.22),
      ]) {
        await db.upsertHrv(
          HrvRecordsCompanion(
            date: Value(DateTime(day.year, day.month, day.day - row.$1)),
            restingHeartRate: Value(row.$2),
            skinTempDelta: Value(row.$3),
          ),
        );
      }
      await render(
        tester,
        const SingleChildScrollView(child: HealthMonitorGrid()),
        'health-monitor-alerts',
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HealthMonitorGrid)),
      );
      container.read(selectedDateProvider.notifier).state = day;
      await tester.pumpAndSettle();
      final alerts = await container.read(
        healthMonitorAlertsProvider(day).future,
      );
      expect(
        alerts,
        containsAll([HealthMetric.rhr, HealthMetric.skinTemperature]),
      );
      await tester.pumpAndSettle();
      final tile = tester.widget<MetricCard>(
        find.byWidgetPredicate(
          (w) => w is MetricCard && w.label == HealthMetric.rhr.label,
        ),
      );
      expect(tile.highlighted, isTrue);
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byWidget(tile),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, const Color(0xFFFF454B));
      final value = tester.widget<Text>(
        find
            .descendant(
              of: find.byWidget(tile),
              matching: find.byWidgetPredicate(
                (w) => w is Text && w.textSpan != null,
              ),
            )
            .first,
      );
      final spans = (value.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(spans.every((span) => span.style!.color == Colors.black), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Health Monitor values open details with 14 and 30 day autoscaled charts',
    (tester) async {
      await render(
        tester,
        const SingleChildScrollView(child: HealthMonitorGrid()),
        'health-monitor-detail',
      );
      final value = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is MetricCard && w.label == HealthMetric.rhr.label,
        ),
        matching: find.byWidgetPredicate(
          (w) => w is Text && w.textSpan != null,
        ),
      );
      await tester.tap(value);
      await tester.pumpAndSettle();
      expect(find.byType(MetricDetailSheet), findsOneWidget);
      expect(find.text('Lower is better'), findsOneWidget);
      expect(find.text('14 Days'), findsOneWidget);
      await tester.tap(find.text('30 Days'));
      await tester.pumpAndSettle();
      expect(find.text('Last 30 days'), findsOneWidget);
      final chart = tester.widget<HistoryChart>(find.byType(HistoryChart));
      expect(chart.minY, isNotNull);
      expect(chart.maxY, greaterThan(chart.minY!));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'metric history periods page backward and return without changing selection',
    (tester) async {
      await render(
        tester,
        const MetricDetailSheet(metric: HealthMetric.weight),
        'weight-history',
      );
      await tester.tap(find.text('Q'));
      await tester.pumpAndSettle();
      expect(find.text('Last 3 months'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous period'));
      await tester.pumpAndSettle();
      expect(find.text('Last 3 months'), findsNothing);
      await tester.tap(find.byTooltip('Next period'));
      await tester.pumpAndSettle();
      expect(find.text('Last 3 months'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('Week plan does not append the activity history list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'plan_default_view': 'week',
      'heat_acclimation_enabled': false,
    });
    await render(tester, const PlanScreen(), 'plan-week-only');
    expect(find.text('WEEKLY PLAN'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -2500));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityHistory), findsNothing);
    expect(find.text('HISTORY'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'Month calendar shows colored planned and completed sport bubbles',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'plan_default_view': 'month',
        'heat_acclimation_enabled': false,
      });
      final now = DateTime.now();
      await db
          .into(db.scheduledWorkoutRecords)
          .insert(
            ScheduledWorkoutRecordsCompanion.insert(
              workoutId: 'swim',
              scheduleId: 'swim',
              name: 'Swim intervals',
              sportType: 'swimming',
              scheduledDate: DateTime(now.year, now.month, now.day - 1),
            ),
          );
      await db
          .into(db.scheduledWorkoutRecords)
          .insert(
            ScheduledWorkoutRecordsCompanion.insert(
              workoutId: 'strength',
              scheduleId: 'strength',
              name: 'Strength planned',
              sportType: 'strength',
              scheduledDate: DateTime(now.year, now.month, now.day + 1),
            ),
          );
      await render(tester, const PlanScreen(), 'plan-calendar');
      expect(find.text('○ Planned   ● Completed   ✕ Skipped'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'new heart rate references show daily pulse workout and both histories',
    (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final workoutDay = DateTime(now.year, now.month, now.day - 2);
      await db.upsertHrv(
        HrvRecordsCompanion(
          date: Value(today),
          restingHeartRate: const Value(47),
        ),
      );
      await db.saveHeartRateSamples([
        for (var i = 0; i < 12; i++)
          TimedHeartRate(
            DateTime(
              today.year,
              today.month,
              today.day,
              2 + i ~/ 2,
              i.isOdd ? 30 : 0,
            ),
            <double>[57, 53, 47, 50, 50, 49, 50, 49, 59, 51, 56, 52][i],
            'suunto',
          ),
        for (var i = 0; i < 24; i++)
          TimedHeartRate(
            DateTime(workoutDay.year, workoutDay.month, workoutDay.day, i),
            i >= 11 && i <= 16 ? 130.0 + i % 5 * 5 : 48.0 + i % 4 * 5,
            'garmin_api',
          ),
      ]);
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'heart-reference-bike',
              name: 'Muro Rennradfahren',
              type: 'cycling',
              startDate: DateTime(
                workoutDay.year,
                workoutDay.month,
                workoutDay.day,
                10,
                38,
              ),
              durationSeconds: 348 * 60,
              avgHeartRate: const Value(132),
            ),
          );
      await render(tester, const HrTimelineScreen(), 'heart-timeline-day');
      await tester.tap(find.text('WEEK'));
      await tester.pumpAndSettle();
      await capture(tester, 'heart-timeline-week');
      await tester.tap(find.text('MONTH'));
      await tester.pumpAndSettle();
      await capture(tester, 'heart-timeline-month');
      await tester.tap(find.text('DAY'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byTooltip('Previous heart-rate period'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Muro Rennradfahren'), findsOneWidget);
      await capture(tester, 'heart-timeline-activity');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await render(tester, HrTimelineCard(date: today), 'heart-timeline-card');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('blood pressure variation charts render in Day Week and Month', (
    tester,
  ) async {
    final now = DateTime.now();
    await db.insertBpMeasurements([
      for (var day = 0; day < 7; day++)
        for (final hour in [2, 8, 14, 20])
          for (final delta in [-8, 8])
            BpMeasurementsCompanion.insert(
              measuredAt: DateTime(
                now.year,
                now.month,
                now.day - day,
                hour,
                delta < 0 ? 5 : 35,
              ),
              systolic: 125 + day + delta,
              diastolic: 70 + day + delta ~/ 2,
              heartRate: 60,
            ),
    ]);
    await render(tester, const BpScreen(), 'blood-pressure');
    await tester.scrollUntilVisible(
      find.text('HOURLY VARIATION'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    for (final period in ['Week', 'Month']) {
      await tester.tap(find.text(period));
      await tester.pumpAndSettle();
      expect(find.text('DAILY VARIATION'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'blood-pressure-${period.toLowerCase()}');
    }
    await tester.tap(find.byTooltip('Fullscreen blood-pressure chart'));
    await tester.pumpAndSettle();
    expect(tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns, 1);
    await capture(tester, 'blood-pressure-fullscreen');
    await tester.tap(find.byTooltip('Close fullscreen blood-pressure chart'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'heart-rate and blood-pressure date controls move back and forward',
    (tester) async {
      await render(tester, const HrTimelineScreen(), 'heart-timeline');
      await tester.tap(find.byTooltip('Previous heart-rate period'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsNothing);
      await tester.tap(find.byTooltip('Next heart-rate period'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await render(tester, const BpScreen(), 'blood-pressure');
      await tester.tap(find.byTooltip('Previous blood-pressure period'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsNothing);
      await tester.tap(find.byTooltip('Next blood-pressure period'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'connection settings return from login instead of starting onboarding',
    (tester) async {
      await render(tester, const ConnectionsTab(), 'connections');
      await tester.tap(find.text('Garmin Connect'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ConnectGarminScreen>(find.byType(ConnectGarminScreen))
            .fromOnboarding,
        isTrue,
      );
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.byType(ConnectionsTab), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('source priorities reorder, persist and reset', (tester) async {
    await render(tester, const ConnectionsTab(), 'connections');
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(ConnectionsTab)),
    );
    final before = (await scope.read(
      sourcePriorityProvider.future,
    ))[SourceGroup.activity.name]!;
    final first = before.first;
    await scope
        .read(sourcePriorityProvider.notifier)
        .reorder(SourceGroup.activity, 0, 3);
    expect(
      scope
          .read(sourcePriorityProvider)
          .requireValue[SourceGroup.activity.name]![2],
      first,
    );
    await scope.read(sourcePriorityProvider.notifier).reset();
    expect(
      scope
          .read(sourcePriorityProvider)
          .requireValue[SourceGroup.activity.name]!
          .first,
      first,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'cached energy keeps charged and drained totals and uses a full-day axis',
    (tester) async {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      await db.upsertWellness(
        WellnessRecordsCompanion.insert(
          date: day,
          bodyBatteryCharged: const Value(53),
          bodyBatteryDrained: const Value(15),
          bodyBatteryJson: Value(
            jsonEncode([
              for (final p in [(0, 15), (8, 63), (19, 46)])
                [
                  DateTime(
                    day.year,
                    day.month,
                    day.day,
                    p.$1,
                  ).millisecondsSinceEpoch,
                  p.$2,
                ],
            ]),
          ),
        ),
      );
      await render(tester, const BatteryScreen(), 'energy');
      expect(find.text('+53'), findsOneWidget);
      expect(find.text('−15'), findsOneWidget);
      expect(find.byType(EnergyTimeline), findsOneWidget);
      await capture(tester, 'energy');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('source and attribution sections remain reachable by scrolling', (
    tester,
  ) async {
    await render(tester, const ConnectionsTab(), 'connections');
    await tester.scrollUntilVisible(
      find.text('Reset to default'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await capture(tester, 'connections-priority');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await render(tester, const AiSettingsTab(), 'ai-settings');
    await tester.scrollUntilVisible(
      find.text('Licenses'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await capture(tester, 'ai-attributions');
    await tester.tap(find.text('Licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('LOAD display toggles control weekday and plan-progress cards', (
    tester,
  ) async {
    Widget page() => ProviderScope(
      overrides: [
        trainingPlanMetaProvider.overrideWith(
          (ref) async => TrainingPlanMeta(
            planId: 'fixture',
            planName: 'Fixture Garmin plan',
            durationInWeeks: 12,
            avgWeeklyWorkouts: 5,
            startDate: DateTime(2026, 10, 1),
            currentWeek: 3,
          ),
        ),
      ],
      child: const StrainScreen(embedded: true),
    );
    await render(tester, page(), 'optional-cards');
    await tester.scrollUntilVisible(
      find.text('TRAINING PLAN PROGRESS'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await capture(tester, 'training-plan-progress');
    expect(find.text('Fixture Garmin plan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('visible_load_weekday_load', false);
    await prefs.setBool('visible_load_plan_banner', false);
    await render(tester, page(), 'optional-hidden');
    expect(find.byType(WeekdayLoadCard), findsNothing);
    expect(find.byType(TrainingPlanProgressCard), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'Home heart-rate preview is no taller than blood pressure and opens detail',
    (tester) async {
      await render(tester, const HomeScreen(), 'compact-heart-home');
      await tester.scrollUntilVisible(
        find.byType(HrTimelineCard),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final bloodPressure = find
          .ancestor(
            of: find.text('BLOOD PRESSURE'),
            matching: find.byType(SectionCard),
          )
          .first;
      expect(
        tester.getSize(find.byType(HrTimelineCard)).height,
        lessThanOrEqualTo(tester.getSize(bloodPressure).height),
      );
      await tester.tap(find.byType(HrTimelineCard));
      await tester.pumpAndSettle();
      expect(find.byType(HrTimelineScreen), findsOneWidget);
      expect(find.text('DAY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Health Monitor ends immediately below its last tile', (
    tester,
  ) async {
    await render(
      tester,
      const SingleChildScrollView(child: HealthMonitorGrid()),
      'health-monitor-compact',
    );
    final cardBottom = tester.getBottomLeft(find.byType(HealthMonitorGrid)).dy;
    final lastTileBottom = tester
        .getBottomLeft(find.byType(MetricCard).last)
        .dy;
    // Section padding (16) plus the card's outer spacing (12).
    expect(cardBottom - lastTileBottom, closeTo(28, 1));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'screenshot settings and health sections remain visible at the bottom',
    (tester) async {
      await render(tester, const DisplayTab(), 'display');
      await tester.scrollUntilVisible(
        find.text('Training Plan Progress'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await capture(tester, 'display-load');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await render(tester, const ConnectionsTab(), 'connections');
      await tester.scrollUntilVisible(
        find.textContaining('Hilo Blood Pressure BLE'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await capture(tester, 'connections-ble');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await render(tester, const HomeScreen(), 'health');
      await tester.scrollUntilVisible(
        find.text('BIOLOGICAL AGE'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await capture(tester, 'health-lower');
      await tester.tap(find.text('COACH').last);
      await tester.pumpAndSettle();
      final scaffold = tester.widgetList<Scaffold>(find.byType(Scaffold)).last;
      expect(scaffold.extendBody, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('all main tabs open and settings is reachable', (tester) async {
    await render(tester, const HomeScreen(), 'navigation');
    for (final title in ['PLAN', 'LOAD', 'COACH', 'DEBUG', 'HEALTH']) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: title);
    }
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Connections'), findsOneWidget);
    expect(find.text('AI & More'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'activity details render charts, fullscreen and confirm or cancel deletion',
    (tester) async {
      final row = (await db.select(db.activityRecords).get()).single;
      await render(
        tester,
        ActivityDetailSheet(activity: row),
        'activity-detail',
      );
      expect(find.text('Max HR'.toUpperCase()), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Fullscreen'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Fullscreen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fullscreen'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Back').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('PERFORMANCE / DISTANCE').first);
      await tester.pumpAndSettle();
      await capture(tester, 'activity-performance');
      await tester.scrollUntilVisible(
        find.text('TIME IN HR ZONES'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await capture(tester, 'activity-zones');
      await tester.scrollUntilVisible(
        find.text('Delete'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await db.select(db.activityRecords).get()).length, 1);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(await db.select(db.activityRecords).get(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'strength activity shows strength content, no endurance panels (STR-A02)',
    (tester) async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'gym-1',
              name: 'Evening lift',
              type: 'strength_training',
              startDate: DateTime(2026, 10, 27, 18),
              durationSeconds: 3300,
              avgHeartRate: const Value(112),
              distanceMeters: const Value(0),
            ),
          );
      final row = await (db.select(
        db.activityRecords,
      )..where((t) => t.activityId.equals('gym-1'))).getSingle();
      await render(
        tester,
        ActivityDetailSheet(activity: row),
        'activity-strength',
      );
      await tester.pumpAndSettle();
      for (final label in ['DISTANCE', 'AVG PACE', 'AVG SPEED', 'ELEVATION']) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.text('AVG HR'), findsOneWidget);
      expect(
        find.text(
          'Exercise details were not provided by this activity source.',
        ),
        findsOneWidget,
      );
      expect(find.text('PERFORMANCE / DISTANCE'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('activity AI button opens an editable activity-specific draft', (
    tester,
  ) async {
    final row = (await db.select(db.activityRecords).get()).single;
    await render(
      tester,
      ActivityDetailSheet(activity: row),
      'activity-chat-button',
    );
    final button = find.text('Chat AI');
    final scroller = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(button, 300, scrollable: scroller);
    // The HRV card reads the database before it takes its place in the list
    // and pushes what follows down, so wait for it and look again.
    for (var i = 0; i < 30; i++) {
      if (find.text('HRV AROUND THIS WORKOUT').evaluate().isNotEmpty) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(button, 300, scrollable: scroller);
    await tester.pumpAndSettle();
    // Side by side: same row, chat to the right of delete.
    expect(
      tester.getCenter(button).dy,
      closeTo(tester.getCenter(find.text('Delete')).dy, 1),
    );
    expect(
      tester.getTopLeft(button).dx,
      greaterThan(tester.getTopLeft(find.text('Delete')).dx),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ActivityDetailSheet)),
    );
    container.read(pendingCoachPromptProvider.notifier).state =
        'Unrelated pending prompt';
    await tester.tap(button);
    await tester.pumpAndSettle();
    // The coach opens in the Coach tab: the sheet only hands over a request.
    final request = container.read(coachRequestProvider)!;
    expect(request.prompt, startsWith('How did this session go'));
    expect(request.prompt, isNot(contains(row.name)));
    expect(request.activity?.activityId, row.activityId);
    expect(request.card?.title, row.name);
    expect(request.card?.status.label, 'Completed');
    expect(request.card?.facts, contains('7.6 km'));
    expect(
      container.read(pendingCoachPromptProvider),
      'Unrelated pending prompt',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('a coach request shows the Coach tab with the session card', (
    tester,
  ) async {
    final row = (await db.select(db.activityRecords).get()).single;
    await render(tester, const HomeScreen(), 'coach-tab');
    expect(find.byType(AiCoachScreen), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    container.read(coachRequestProvider.notifier).state = CoachRequest(
      prompt: 'How did this session go?',
      activity: row,
      card: CoachContextCard.completed(decodeActivityRecord(row)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AiCoachScreen), findsOneWidget);
    final card = find.byType(CoachContextCardView);
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text(row.name)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Completed')),
      findsOneWidget,
    );
    final input = tester.widget<TextField>(find.byType(TextField).last);
    // No draft: the card offers the questions.
    expect(input.controller!.text, isEmpty);
    // The request is consumed: opening the tab again later does not repeat it.
    expect(container.read(coachRequestProvider), isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  for (final variant in [
    ('planned-swim', 'Aerobic Base Swim 4×500m Z2', 'swimming', 1, 40, 36),
    ('planned-run', 'Easy Recovery Run', 'running', 2, 40, 43),
    ('planned-gravel', 'Gravel Easy Spin', 'cycling_gravel', 1, 60, 60),
  ]) {
    testWidgets('${variant.$1} renders planned workout structure and targets', (
      tester,
    ) async {
      final session = await plannedSession(
        variant.$2,
        variant.$3,
        variant.$4,
        variant.$5,
        variant.$6,
      );
      await render(tester, PlanSessionSheet(session: session), variant.$1);
      expect(find.text('ABOUT THIS WORKOUT'), findsOneWidget);
      expect(find.text('COACHING CUES'), findsOneWidget);
      expect(find.text('WORKOUT STRUCTURE'), findsOneWidget);
      expect(find.textContaining('ExecutableStepDTO'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('TARGETS'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await capture(tester, '${variant.$1}-targets');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    });
  }
  testWidgets('planned strength shows exercises, not zones (STR-A01)', (
    tester,
  ) async {
    final session = await plannedSession(
      'Full Body Strength — Base',
      'strength',
      3,
      55,
      50,
    );
    await render(
      tester,
      PlanSessionSheet(session: session),
      'planned-strength',
    );
    await tester.pumpAndSettle();
    expect(find.text('STRENGTH SUMMARY'), findsOneWidget);
    expect(find.text('PRIMARY ZONE'), findsNothing);
    expect(find.text('WORKOUT STRUCTURE'), findsNothing);
    expect(find.text('TARGETS'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('BACK SQUAT'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('3 sets · 8–10 reps · Rest 2:00'), findsWidgets);
    await capture(tester, 'planned-strength');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('planned controls shift dates, push once and mark rest', (
    tester,
  ) async {
    var session = await plannedSession(
      'Easy Recovery Run',
      'running',
      2,
      40,
      43,
    );
    var original = DateUtils.dateOnly(DateTime.now())
        .add(const Duration(days: 1));
    while (original.weekday != DateTime.tuesday) {
      original = DateTime(original.year, original.month, original.day + 1);
    }
    final next = DateTime(original.year, original.month, original.day + 1);
    final previous = DateTime(original.year, original.month, original.day - 1);
    session = session.copyWith(sessionDate: original);
    await (db.update(db.trainingSessions)
          ..where((t) => t.id.equals(session.id)))
        .write(TrainingSessionsCompanion(sessionDate: Value(original)));
    Finder day(DateTime date) => find.bySemanticsLabel(
      RegExp('^${RegExp.escape(DateFormat('EEEE d MMMM').format(date))}'),
    );
    final garmin = FakeWorkoutGarmin();
    await render(
      tester,
      PlanSessionSheet(session: session),
      'planned-actions',
      garmin: garmin,
    );
    await tester.scrollUntilVisible(
      find.text('MOVE THIS WORKOUT'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    // Tap the next day on the strip: the workout moves, with an undo.
    await tester.ensureVisible(day(next));
    await tester.pumpAndSettle();
    await tester.tap(day(next));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.trainingSessions).get()).single.sessionDate,
      next,
    );
    // No snackbar: the way back is a line on the card.
    expect(find.byType(SnackBar), findsNothing);
    expect(
      find.text('Moved from ${DateFormat('EEEE d MMMM').format(original)}'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Undo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.trainingSessions).get()).single.sessionDate,
      original,
    );
    // And back to the day before by tapping it.
    await tester.ensureVisible(day(previous));
    await tester.pumpAndSettle();
    await tester.tap(day(previous));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.trainingSessions).get()).single.sessionDate,
      previous,
    );
    await tester.ensureVisible(day(original));
    await tester.pumpAndSettle();
    await tester.tap(day(original));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.trainingSessions).get()).single.sessionDate,
      original,
    );
    // The undo snackbar goes away by itself before the next action.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Push to Garmin'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tapLow(tester, find.text('Push to Garmin'));
    await tester.pumpAndSettle();
    expect(garmin.creates, 1);
    expect(garmin.dates.single, original);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mark as Rest'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    // The snackbar of the push sits over the buttons; clear it first.
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
        .clearSnackBars();
    await tester.pumpAndSettle();
    await tapLow(tester, find.text('Mark as Rest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.trainingSessions).get()).single.status,
      'planned',
    );
    await tester.pumpAndSettle();
    await tapLow(tester, find.text('Mark as Rest'));
    await tester.pumpAndSettle();
    // The reason is asked for; it is stored with the skip.
    expect(find.text('Illness'), findsOneWidget);
    await tester.tap(find.text('Travel'));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.trainingSessions).get()).single.status,
      'skipped',
    );
    expect(
      (await db.select(db.sessionActuals).get()).single.skipReason,
      'Travel',
    );
    expect(garmin.removedSchedules, ['schedule-1']);
    // The sheet says what happened and why.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.text('SKIPPED · TRAVEL'), findsOneWidget);
    // The skip can be undone.
    await tester.scrollUntilVisible(
      find.text('Restore workout'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore workout'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.trainingSessions).get()).single.status,
      'planned',
    );
    expect(await db.select(db.sessionActuals).get(), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('race goal validates and saves sport, priority and elevation', (
    tester,
  ) async {
    await render(tester, const RaceGoalEditor(), 'race-goal-entry');
    await tester.enterText(find.byType(TextFormField).at(0), 'Island Gravel');
    await tester.tap(find.text('Gravel'));
    await tester.enterText(find.byType(TextFormField).at(1), '80.5');
    await tester.tap(find.text('B'));
    await tester.enterText(find.byType(TextFormField).at(2), '2400');
    await tapLow(tester, find.text('Add Goal', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(find.text('Select a race date'), findsOneWidget);
    expect(await db.select(db.raceGoals).get(), isEmpty);
    await tester.ensureVisible(find.text('Select date'));
    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapLow(tester, find.text('Add Goal', skipOffstage: false));
    await tester.pumpAndSettle();
    final goal = (await db.select(db.raceGoals).get()).single;
    expect(goal.name, 'Island Gravel');
    expect(goal.primarySport, 'cycling_gravel');
    expect(goal.priority, 'b');
    expect(goal.distanceM, 80500);
    expect(goal.elevationM, 2400);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('a race goal saves its target time and shows the pace', (
    tester,
  ) async {
    await render(tester, const RaceGoalEditor(), 'race-goal-target');
    await tester.enterText(find.byType(TextFormField).at(0), 'Hannover');
    await tester.enterText(find.byType(TextFormField).at(1), '42,2');
    await tester.enterText(find.byType(TextFormField).at(2), '100');
    // A time nobody could run is refused.
    await tester.enterText(find.byType(TextFormField).at(3), '0:40:00');
    await tester.ensureVisible(find.text('Select date'));
    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapLow(tester, find.text('Add Goal', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(find.textContaining('a time you could really run'), findsOneWidget);
    expect(await db.select(db.raceGoals).get(), isEmpty);
    // A real one saves, and the pace is shown while typing.
    await tester.enterText(find.byType(TextFormField).at(3), '3:30');
    await tester.pumpAndSettle();
    expect(find.textContaining('4:59/km on average'), findsOneWidget);
    await tester.tap(find.text('Add Goal', skipOffstage: false));
    await tester.pumpAndSettle();
    final goal = (await db.select(db.raceGoals).get()).single;
    expect(goal.targetFinishSeconds, 12600);
    expect(goal.elevationM, 100);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('an existing goal is edited, its time set and cleared', (
    tester,
  ) async {
    await db
        .into(db.raceGoals)
        .insert(
          RaceGoalsCompanion.insert(
            id: 'g',
            athleteId: 'self',
            name: 'Hannover',
            primarySport: 'running',
            distanceM: 42200,
            raceDate: DateTime.now().add(const Duration(days: 120)),
            priority: 'a',
            source: 'manual',
            createdAt: DateTime.now(),
          ),
        );
    final goal = (await db.select(db.raceGoals).get()).single;
    await render(tester, RaceGoalEditor(goal: goal), 'race-goal-edit');
    expect(find.text('Edit Race Goal'), findsOneWidget);
    expect(find.text('Hannover'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), '2400');
    await tester.enterText(find.byType(TextFormField).at(3), '3h25');
    await tapLow(tester, find.text('Save Goal', skipOffstage: false));
    await tester.pumpAndSettle();
    var saved = (await db.select(db.raceGoals).get()).single;
    expect(saved.targetFinishSeconds, 12300);
    expect(saved.elevationM, 2400);
    expect(saved.id, 'g');
    // The same sheet again: the time is there, and can be taken out.
    await tester.pumpWidget(const SizedBox());
    await render(tester, RaceGoalEditor(goal: saved), 'race-goal-edit-2');
    expect(find.text('3:25:00'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(3), '');
    await tapLow(tester, find.text('Save Goal', skipOffstage: false));
    await tester.pumpAndSettle();
    saved = (await db.select(db.raceGoals).get()).single;
    expect(saved.targetFinishSeconds, isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('whether the athlete goes and what they want is saved', (
    tester,
  ) async {
    await db
        .into(db.raceGoals)
        .insert(
          RaceGoalsCompanion.insert(
            id: 'g',
            athleteId: 'self',
            name: 'Brevet 200',
            primarySport: 'cycling_road',
            distanceM: 200000,
            raceDate: DateTime.now().add(const Duration(days: 120)),
            priority: 'b',
            source: 'manual',
            createdAt: DateTime.now(),
          ),
        );
    final goal = (await db.select(db.raceGoals).get()).single;
    expect(goal.participation, 'committed');
    expect(goal.ambition, isNull);
    await render(tester, RaceGoalEditor(goal: goal), 'race-goal-more');
    // Closed until asked for: the form stays short.
    expect(find.text('PARTICIPATION'), findsNothing);
    await tester.tap(find.text('More about this event'));
    await tester.pumpAndSettle();
    await tapLow(tester, find.text('Flexible', skipOffstage: false));
    await tester.pumpAndSettle();
    await tapLow(tester, find.text('Finish', skipOffstage: false));
    await tester.pumpAndSettle();
    await tapLow(tester, find.text('Save Goal', skipOffstage: false));
    await tester.pumpAndSettle();
    var saved = (await db.select(db.raceGoals).get()).single;
    expect(saved.participation, 'flexible');
    expect(saved.ambition, 'finish');
    // Opened again it shows what was chosen, and "Not said" clears it.
    await tester.pumpWidget(const SizedBox());
    await render(tester, RaceGoalEditor(goal: saved), 'race-goal-more-2');
    expect(find.text('PARTICIPATION'), findsOneWidget);
    await tapLow(tester, find.text('Not said', skipOffstage: false));
    await tester.pumpAndSettle();
    await tapLow(tester, find.text('Save Goal', skipOffstage: false));
    await tester.pumpAndSettle();
    saved = (await db.select(db.raceGoals).get()).single;
    expect(saved.participation, 'flexible');
    expect(saved.ambition, isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('a ten-fold distance is questioned, both separators work', (
    tester,
  ) async {
    await render(tester, const RaceGoalEditor(), 'race-goal-ten-fold');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'marathon Hannover',
    );
    // 422 is what 42,2 became when the separator got lost.
    await tester.enterText(find.byType(TextFormField).at(1), '422');
    await tester.ensureVisible(find.text('Select date'));
    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapLow(tester, find.text('Add Goal', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(find.text('Distance of 422 km?'), findsOneWidget);
    expect(await db.select(db.raceGoals).get(), isEmpty);
    await tester.tap(find.text('Use 42.2 km'));
    await tester.pumpAndSettle();
    expect((await db.select(db.raceGoals).get()).single.distanceM, 42195);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'Plan shows race countdown, phased upcoming workouts and expands days',
    (tester) async {
      final now = DateTime.now();
      await db
          .into(db.raceGoals)
          .insert(
            RaceGoalsCompanion.insert(
              id: 'goal',
              athleteId: 'self',
              name: 'marathon Hannover',
              primarySport: 'running',
              distanceM: 42195,
              elevationM: const Value(150),
              raceDate: now.add(const Duration(days: 175)),
              priority: 'a',
              source: 'manual',
              createdAt: now,
            ),
          );
      await db
          .into(db.trainingPlans)
          .insert(
            TrainingPlansCompanion.insert(
              id: 'plan',
              athleteId: 'self',
              raceGoalId: const Value('goal'),
              startDate: now,
              endDate: now.add(const Duration(days: 175)),
              status: 'active',
              generatedAt: now,
            ),
          );
      for (var i = 0; i < 7; i++) {
        await db
            .into(db.trainingSessions)
            .insert(
              TrainingSessionsCompanion.insert(
                id: 'session-$i',
                planId: 'plan',
                athleteId: 'self',
                sessionDate: DateTime(now.year, now.month, now.day + i + 1),
                sessionNumber: i,
                weekNumber: 1,
                sport: i == 2 ? 'yoga' : 'running',
                sessionType: 'recovery',
                phase: i < 4 ? 'recovery' : 'base',
                primaryZone: 2,
                title: i == 2 ? 'Athlete Yoga Flow' : 'Short Shakeout $i',
                plannedDurationMin: 30,
                plannedTrimp: 32,
                sessionLevel: 2,
              ),
            );
      }
      await render(tester, const PlanScreen(), 'plan-upcoming');
      expect(find.text('marathon Hannover'), findsOneWidget);
      expect(find.text('UPCOMING'), findsOneWidget);
      expect(find.text('Short Shakeout 0'), findsOneWidget);
      final more = find.text('+ 5 more days');
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Athlete Yoga Flow'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await capture(tester, 'plan-expanded');
      await tester.tap(find.text('Athlete Yoga Flow'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanSessionSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'Training generation controls match lower screenshot and save sessions setting',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'heat_acclimation_enabled': true,
        'heat_acclimation_location_mode': 'fixed',
        'heat_acclimation_fixed_latitude': 52.292775,
        'heat_acclimation_fixed_longitude': 9.767329,
      });
      await render(tester, const TrainingTab(), 'training-overview');
      final doubleDay = find.text('2 — Double day possible');
      await tester.scrollUntilVisible(
        doubleDay,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(doubleDay);
      await tester.pumpAndSettle();
      final raw = await const FlutterSecureStorage().read(
        key: 'user_profile_v1',
      );
      expect(jsonDecode(raw!)['maxSessionsPerDay'], 2);
      await tester.scrollUntilVisible(
        find.text('Regenerate Workouts'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Delete All Workouts'));
      await tester.pumpAndSettle();
      await capture(tester, 'training-generation');
      expect(find.text('Weather & Location'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('manual blood pressure saves to selected date and validates', (
    tester,
  ) async {
    await render(tester, const ManualEntrySheet(), 'entry');
    await tester.tap(find.text('Blood Pressure'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '125');
    await tester.enterText(find.byType(TextField).at(1), '75');
    await tester.enterText(find.byType(TextField).at(2), '60');
    await tester.ensureVisible(find.text('Save measurement'));
    await tester.tap(find.text('Save measurement'));
    await tester.pumpAndSettle();
    final readings = await db.select(db.bpMeasurements).get();
    expect(readings.any((r) => r.systolic == 125 && r.diastolic == 75), isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.binding.setSurfaceSize(null);
  });
}

class AuditTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGPYcunOfwAIAgNiJBgw5wAAAABJRU5ErkJggg==',
        ),
      );
}
