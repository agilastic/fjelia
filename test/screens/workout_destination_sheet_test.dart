import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/coros_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/services/coros_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fjelia/providers/workout_destination_provider.dart';
import 'package:fjelia/providers/workout_providers_provider.dart';
import 'package:fjelia/screens/planner/plan_session_sheet.dart';
import 'package:fjelia/services/workout_destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late TrainingSession session;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'p',
            athleteId: 'self',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2027, 4, 1),
            status: 'active',
            generatedAt: DateTime(2026, 10, 1),
          ),
        );
    await db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: 's',
            planId: 'p',
            athleteId: 'self',
            sessionDate: DateUtils.dateOnly(
              DateTime.now().add(const Duration(days: 3)),
            ),
            sessionNumber: 1,
            weekNumber: 1,
            sport: 'running',
            sessionType: 'long',
            phase: 'base',
            primaryZone: 2,
            title: 'Long Run',
            stepsJson: Value(
              jsonEncode([
                {
                  'type': 'ExecutableStepDTO',
                  'stepType': {'stepTypeKey': 'interval'},
                  'endCondition': {'conditionTypeKey': 'time'},
                  'endConditionValue': 3600,
                  'zoneNumber': 2,
                },
              ]),
            ),
            plannedDurationMin: 60,
            plannedTrimp: 66,
            sessionLevel: 4,
          ),
        );
    session = await (db.select(db.trainingSessions)).getSingle();
  });
  tearDown(() => db.close());

  /// A target for the platform with [id], built from the app's own wiring.
  WorkoutTarget target(Ref ref, WorkoutDestination d, WorkoutRoute route) => (
    provider: ref.watch(workoutProvidersProvider).byId(d.name)!,
    route: route,
  );

  Future<void> show(
    WidgetTester tester,
    WorkoutDestination destination, {
    List<(WorkoutDestination, WorkoutRoute)>? targets,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 1400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          workoutTargetsProvider.overrideWith(
            (ref) async => [
              for (final (d, route)
                  in targets ??
                      [
                        (
                          destination,
                          destination == WorkoutDestination.garmin
                              ? WorkoutRoute.push
                              : WorkoutRoute.share,
                        ),
                      ])
                target(ref, d, route),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: PlanSessionSheet(session: session)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  testWidgets('Garmin: the button pushes', (tester) async {
    await show(tester, WorkoutDestination.garmin);
    await tester.scrollUntilVisible(
      find.text('Push to Garmin'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Push to Garmin'), findsOneWidget);
    expect(find.textContaining('partner access'), findsNothing);
    await close(tester);
  });

  for (final d in [
    WorkoutDestination.coros,
    WorkoutDestination.polar,
    WorkoutDestination.suunto,
  ]) {
    testWidgets('${d.label}: the workout is shared, and the sheet says why', (
      tester,
    ) async {
      final shared = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/share'),
            (call) async {
              shared.add(call);
              return 'dev.fluttercommunity.plus/share/unavailable';
            },
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('dev.fluttercommunity.plus/share'),
              null,
            ),
      );
      await show(tester, d);
      await tester.scrollUntilVisible(
        find.text('Share workout for ${d.label}'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Push to Garmin'), findsNothing);
      expect(
        find.textContaining('${d.label}\'s partner access'),
        findsOneWidget,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share workout for ${d.label}'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(shared, isNotEmpty);
      final text = jsonEncode(shared.first.arguments.toString());
      expect(text, contains('Long Run'));
      expect(text, contains('TARGETS: heart rate in your zones'));
      await close(tester);
    });
  }

  group('COROS route', () {
    late List<http.Request> sent;

    Future<void> showCoros(WidgetTester tester) async {
      sent = [];
      FlutterSecureStorage.setMockInitialValues({
        'coros_auth_v1': jsonEncode({
          'accessToken': 'tok',
          'userId': '42',
          'region': 'eu',
          'timestampMs': DateTime.now().millisecondsSinceEpoch,
          'email': 'me@example.com',
        }),
        // The experimental route is on: that is what makes COROS a push.
        'user_profile_v1': jsonEncode({'corosWorkoutPush': true}),
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 1400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            workoutTargetsProvider.overrideWith(
              (ref) async => [
                target(ref, WorkoutDestination.coros, WorkoutRoute.push),
              ],
            ),
            corosServiceProvider.overrideWithValue(
              CorosService(
                db,
                client: MockClient((req) async {
                  sent.add(req);
                  return http.Response(jsonEncode({'result': '0000'}), 200);
                }),
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: PlanSessionSheet(session: session)),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    testWidgets('the workout goes to COROS, with the experimental note', (
      tester,
    ) async {
      await showCoros(tester);
      await tester.scrollUntilVisible(
        find.text('Push to COROS'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('unofficial interface'), findsOneWidget);
      expect(find.text('Share workout for COROS'), findsNothing);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Push to COROS'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(sent, hasLength(1));
      final body = jsonDecode(sent.single.body) as Map<String, dynamic>;
      final program = (body['programs'] as List).single as Map;
      expect(program['name'], 'Long Run');
      expect(program['sportType'], 1);
      expect(find.text('Workout sent to COROS'), findsOneWidget);
      await close(tester);
    });

    testWidgets(
      'a sport COROS cannot hold is shared instead, with the reason',
      (tester) async {
        final shared = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('dev.fluttercommunity.plus/share'),
              (call) async {
                shared.add(call);
                return 'dev.fluttercommunity.plus/share/unavailable';
              },
            );
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(
                const MethodChannel('dev.fluttercommunity.plus/share'),
                null,
              ),
        );
        await (db.update(db.trainingSessions)..where((t) => t.id.equals('s')))
            .write(const TrainingSessionsCompanion(sport: Value('strength')));
        session = await db.select(db.trainingSessions).getSingle();
        await showCoros(tester);
        await tester.scrollUntilVisible(
          find.text('Push to COROS'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Push to COROS'));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(sent, isEmpty);
        expect(shared, isNotEmpty);
        expect(find.textContaining('not strength'), findsOneWidget);
        await close(tester);
      },
    );
  });

  test(
    'one target per connected platform, routes by platform and switch',
    () async {
      Future<List<WorkoutTarget>> targets(
        List<WorkoutDestination> connected, {
        required bool corosOn,
      }) async {
        FlutterSecureStorage.setMockInitialValues({
          'user_profile_v1': jsonEncode({'corosWorkoutPush': corosOn}),
        });
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            connectedProvidersProvider.overrideWith(
              (ref) async => [
                for (final d in connected)
                  ref.watch(workoutProvidersProvider).byId(d.name)!,
              ],
            ),
          ],
        );
        addTearDown(container.dispose);
        await container.read(userProfileProvider.future);
        return container.read(workoutTargetsProvider.future);
      }

      // Garmin and COROS both connected: both are offered.
      var t = await targets([
        WorkoutDestination.garmin,
        WorkoutDestination.coros,
      ], corosOn: false);
      expect(t.map((e) => e.provider.id), ['garmin', 'coros']);
      expect(t.map((e) => e.route), [WorkoutRoute.push, WorkoutRoute.share]);
      // The COROS switch turns its button into a push.
      t = await targets([
        WorkoutDestination.garmin,
        WorkoutDestination.coros,
      ], corosOn: true);
      expect(t.map((e) => e.route), [WorkoutRoute.push, WorkoutRoute.push]);
      // The switch is for COROS only.
      t = await targets([
        WorkoutDestination.polar,
        WorkoutDestination.suunto,
      ], corosOn: true);
      expect(t.map((e) => e.route), [WorkoutRoute.share, WorkoutRoute.share]);
      // Order follows the athlete's, a single platform stays single.
      t = await targets([WorkoutDestination.suunto], corosOn: false);
      expect(t, hasLength(1));
    },
  );

  testWidgets('Garmin and COROS connected: both buttons are there', (
    tester,
  ) async {
    await show(
      tester,
      WorkoutDestination.garmin,
      targets: [
        (WorkoutDestination.garmin, WorkoutRoute.push),
        (WorkoutDestination.coros, WorkoutRoute.share),
        (WorkoutDestination.polar, WorkoutRoute.share),
      ],
    );
    await tester.scrollUntilVisible(
      find.text('Push to Garmin'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Push to Garmin'), findsOneWidget);
    expect(find.text('Share workout for COROS'), findsOneWidget);
    expect(find.text('Share workout for Polar'), findsOneWidget);
    await close(tester);
  });

  testWidgets(
    'COROS shared as text can be switched to the push, after a warning',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'user_profile_v1': jsonEncode({'corosWorkoutPush': false}),
      });
      await show(tester, WorkoutDestination.coros);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PlanSessionSheet)),
      );
      await container.read(userProfileProvider.future);
      await tester.scrollUntilVisible(
        find.text('Send to COROS instead (experimental)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send to COROS instead (experimental)'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('COROS has no workout import'),
        findsOneWidget,
      );
      // Cancelled: nothing changes.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        (await container.read(userProfileProvider.future)).corosWorkoutPush,
        isFalse,
      );
      await tester.tap(find.text('Send to COROS instead (experimental)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        (await container.read(userProfileProvider.future)).corosWorkoutPush,
        isTrue,
      );
      // Garmin has no such button.
      await close(tester);
    },
  );

  testWidgets('moving onto a rest day asks first, and can be undone', (
    tester,
  ) async {
    await show(tester, WorkoutDestination.garmin);
    // The profile's default rest day is Sunday: find the next one.
    final today = DateUtils.dateOnly(DateTime.now());
    var sunday = today.add(const Duration(days: 1));
    while (sunday.weekday != DateTime.sunday) {
      sunday = sunday.add(const Duration(days: 1));
    }
    String label(DateTime d) => RegExp.escape(
      '${const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d.weekday - 1]} ${d.day} '
      '${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][d.month - 1]}',
    );
    await tester.scrollUntilVisible(
      find.text('MOVE THIS WORKOUT'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    final before =
        (await db.select(db.trainingSessions).getSingle()).sessionDate;
    final chip = find.bySemanticsLabel(RegExp('^${label(sunday)}'));
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.text('Move anyway?'), findsOneWidget);
    expect(find.textContaining('is a rest day in your plan'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.trainingSessions).getSingle()).sessionDate,
      before,
    );
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.trainingSessions).getSingle()).sessionDate,
      sunday,
    );
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.trainingSessions).getSingle()).sessionDate,
      before,
    );
    await close(tester);
  });

  testWidgets('a move leaves no snackbar, the undo is a line on the card', (
    tester,
  ) async {
    await show(tester, WorkoutDestination.garmin);
    final today = DateUtils.dateOnly(DateTime.now());
    var day = today.add(const Duration(days: 5));
    while (day.weekday == DateTime.sunday) {
      day = day.add(const Duration(days: 1));
    }
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    await tester.scrollUntilVisible(
      find.text('MOVE THIS WORKOUT'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
    await tester.tap(
      find.bySemanticsLabel(RegExp('^${names[day.weekday - 1]} ${day.day} ')),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.textContaining('Moved from'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    // It stays: there is nothing to swipe away, and the way back is still there.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
    expect(
      (await db.select(db.trainingSessions).getSingle()).sessionDate,
      DateTime(today.year, today.month, today.day + 3),
    );
    await close(tester);
  });
}
