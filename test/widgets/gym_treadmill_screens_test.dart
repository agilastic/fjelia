import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/models/gym_workout.dart';
import 'package:fjelia/models/training_ble_profile.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/gym_treadmill_provider.dart';
import 'package:fjelia/services/gym_workout_import_service.dart';
import 'package:fjelia/services/training_ble.dart';
import 'package:fjelia/services/workout_photo_service.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:fjelia/widgets/gym_treadmill_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const device = TrainingDevice(id: 'gym', name: 'Matrix T5x');

class _Actions extends GymTreadmillActions {
  _Actions(super.ref, this.db, {this.report});
  final AppDatabase db;
  final TrainingBleReport? report;
  @override
  Future<List<TrainingDevice>> scan() async => [device];
  @override
  Future<TrainingBleReport> inspect(TrainingDevice d) async =>
      report ?? const TrainingBleReport(device: device, services: []);
  @override
  Future<GymWorkoutImportResult> save(List<GymWorkout> workouts) =>
      GymWorkoutImportService(db).save(workouts);
}

class _Photo extends WorkoutPhotoService {
  _Photo(this.draft);
  final WorkoutPhotoDraft draft;
  @override
  Future<WorkoutPhotoDraft?> pick({required bool camera}) async => draft;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => db.close());
  Widget app(
    Widget child, {
    WorkoutPhotoDraft? photo,
    TrainingBleReport? report,
  }) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      gymTreadmillActionsProvider.overrideWith(
        (ref) => _Actions(ref, db, report: report),
      ),
      if (photo != null)
        workoutPhotoServiceProvider.overrideWithValue(_Photo(photo)),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  Future<void> tapVisible(
    WidgetTester t,
    Finder finder, {
    bool settle = true,
  }) async {
    if (finder.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        finder,
        150,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await t.ensureVisible(finder);
    await t.tap(finder);
    if (settle) {
      await t.pumpAndSettle();
    } else {
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets(
    'gym flow offers direct data, xID and a summary without a watch',
    (t) async {
      await t.pumpWidget(app(const GymTreadmillSheet()));
      await t.pumpAndSettle();
      expect(find.text('Direct connection'), findsOneWidget);
      expect(find.text('Matrix xID'), findsOneWidget);
      expect(find.text('Treadmill summary'), findsOneWidget);
      await tapVisible(t, find.text('Find gym equipment'), settle: false);
      await tapVisible(t, find.textContaining('Matrix T5x').last);
      expect(
        find.textContaining('No supported live workout data found'),
        findsOneWidget,
      );
      expect(find.text('Use this machine'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('xID sign-in requires no Apple Health or watch connection', (
    t,
  ) async {
    await t.pumpWidget(app(const MatrixXidSheet()));
    await t.pumpAndSettle();
    expect(find.text('Gym Netpulse portal'), findsOneWidget);
    expect(find.text('xID passcode'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Apple Health'), findsNothing);
    expect(
      t.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'reviewed console photo saves real summary units on a small phone',
    (t) async {
      t.view.physicalSize = const Size(320, 740);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        app(
          const GymSummarySheet(),
          photo: const WorkoutPhotoDraft(
            seconds: 1800,
            distance: 3.1,
            unit: GymDistanceUnit.miles,
            calories: 320,
            heartRate: 145,
          ),
        ),
      );
      await t.pumpAndSettle();
      await tapVisible(t, find.text('Take photo'));
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('gym-duration')))
            .controller!
            .text,
        '30:00',
      );
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('gym-distance')))
            .controller!
            .text,
        '3.1',
      );
      await tapVisible(t, find.text('Save'));
      final saved = await db.select(db.activityRecords).get();
      expect(saved, hasLength(1));
      expect(saved.single.durationSeconds, 1800);
      expect(saved.single.distanceMeters, closeTo(4988.9664, .001));
      expect(saved.single.avgHeartRate, 145);
      expect(saved.single.metricsJson, isNull);
      expect(find.textContaining('1 workouts imported'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('manual summary validates duration before writing an activity', (
    t,
  ) async {
    await t.pumpWidget(app(const GymSummarySheet()));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('gym-duration')), '30:70');
    await tapVisible(t, find.text('Save'));
    expect(await db.select(db.activityRecords).get(), isEmpty);
    expect(find.textContaining('Enter mm:ss'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'a photo without distance units requires an explicit unit selection',
    (t) async {
      await t.pumpWidget(
        app(
          const GymSummarySheet(),
          photo: const WorkoutPhotoDraft(seconds: 1800, distance: 3.1),
        ),
      );
      await t.pumpAndSettle();
      await tapVisible(t, find.text('Take photo'));
      await tapVisible(t, find.text('Save'));
      expect(await db.select(db.activityRecords).get(), isEmpty);
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
      final dropdown = find.byType(DropdownButtonFormField<GymDistanceUnit>);
      await tapVisible(t, dropdown);
      await t.tap(find.text('mi').last);
      await t.pumpAndSettle();
      await tapVisible(t, find.text('Save'));
      expect(
        (await db.select(db.activityRecords).get()).single.distanceMeters,
        closeTo(4988.9664, .001),
      );
      expect(t.takeException(), isNull);
    },
  );
}
