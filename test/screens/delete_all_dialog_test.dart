import 'package:fjelia/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/heat_acclimation_provider.dart';
import 'package:fjelia/providers/workout_push_provider.dart';
import 'package:fjelia/screens/settings/training_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> open(
    WidgetTester tester,
    Future<DeleteAllResult> Function(
      void Function(int done, int total, String label),
    )
    run,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          heatPreferredLocationProvider.overrideWith((ref) async => null),
          deleteAllWorkoutsProvider.overrideWithValue(run),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TrainingTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Delete All Workouts'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete All Workouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump();
  }

  testWidgets('the dialog shows the work and closes when it is done', (
    tester,
  ) async {
    await open(tester, (onProgress) async {
      onProgress(1, 1, 'On this phone');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      onProgress(2, 4, 'Garmin');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return const DeleteAllResult(
        removed: {'garmin': 4},
        labels: {'garmin': 'Garmin'},
      );
    });
    expect(find.text('Deleting workouts'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('Garmin · 2 of 4'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Deleting workouts'), findsNothing);
    expect(
      find.textContaining('Removed from your platforms: Garmin 4'),
      findsOneWidget,
    );
  });

  testWidgets('a failure closes the dialog too, and says so', (tester) async {
    await open(tester, (onProgress) async {
      onProgress(1, 1, 'On this phone');
      throw StateError('no connection');
    });
    await tester.pumpAndSettle();
    expect(find.text('Deleting workouts'), findsNothing);
    expect(find.textContaining('Deleting failed'), findsOneWidget);
  });
}
