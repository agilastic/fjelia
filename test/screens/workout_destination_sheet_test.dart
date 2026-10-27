import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/api/polar_flow_web_client.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/coros_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/polar_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/services/coros_service.dart';
import 'package:fjelia/services/polar_service.dart';
import 'package:fjelia/widgets/move_workout_card.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:fjelia/providers/workout_destination_provider.dart';
import 'package:fjelia/providers/workout_providers_provider.dart';
import 'package:fjelia/screens/planner/plan_session_sheet.dart';
import 'package:fjelia/services/workout_destination.dart';
import 'package:fjelia/services/workout_providers/workout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _PolarFlowState {
  final targets = <Map<String, dynamic>>[];
  bool refuseUploads = false;
}

class _PolarFlow extends PolarFlowWebClient {
  _PolarFlow(this.state)
    : super(client: MockClient((_) async => http.Response('', 500)));

  final _PolarFlowState state;

  @override
  Future<void> login(String email, String password) async {
    if (email != 'me@example.com' || password != 'secret') {
      throw PolarFlowException('Incorrect Polar e-mail or password.');
    }
  }

  @override
  Future<String> createTrainingTarget(Map<String, dynamic> target) async {
    if (state.refuseUploads) throw PolarFlowException('Upload refused.');
    state.targets.add(target);
    return '123456';
  }
}

class _PolarService extends PolarService {
  _PolarService(super.db, this.flow)
    : super(flowClientFactory: () => _PolarFlow(flow));

  final _PolarFlowState flow;

  @override
  Future<void> saveFlowLogin(
    String email,
    String password, {
    PolarFlowWebClient? client,
  }) async {
    final web = _PolarFlow(flow);
    try {
      await super.saveFlowLogin(email, password, client: web);
    } finally {
      web.close();
    }
  }
}

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
    bool useConnectedTargets = false,
    List<Override> overrides = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 1400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          if (!useConnectedTargets)
            workoutTargetsProvider.overrideWith(
              (ref) async => [
                for (final (d, route)
                    in targets ??
                        [
                          (
                            destination,
                            destination == WorkoutDestination.garmin ||
                                    destination == WorkoutDestination.coros ||
                                    destination == WorkoutDestination.polar
                                ? WorkoutRoute.push
                                : WorkoutRoute.share,
                          ),
                        ])
                  target(ref, d, route),
              ],
            ),
          ...overrides,
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

  for (final d in [WorkoutDestination.suunto]) {
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

  group('Polar upload', () {
    late _PolarFlowState flow;
    late List<MethodCall> shared;

    Future<void> showPolar(
      WidgetTester tester, {
      bool savedLogin = false,
    }) async {
      flow = _PolarFlowState();
      shared = [];
      FlutterSecureStorage.setMockInitialValues({
        if (savedLogin) ...{
          'polar_flow_email': 'me@example.com',
          'polar_flow_password': 'secret',
        },
      });
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
      await show(
        tester,
        WorkoutDestination.polar,
        useConnectedTargets: true,
        overrides: [
          polarServiceProvider.overrideWithValue(_PolarService(db, flow)),
          connectedProvidersProvider.overrideWith(
            (ref) async => [ref.watch(workoutProvidersProvider).byId('polar')!],
          ),
        ],
      );
      await tester.scrollUntilVisible(
        find.text('Push to Polar'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Push to Polar'));
      await tester.pumpAndSettle();
      expect(find.text('Share workout for Polar'), findsNothing);
      await tester.tap(find.text('Push to Polar'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    void expectUploaded({int hour = 16}) {
      expect(flow.targets, hasLength(1));
      final payload = flow.targets.single;
      expect(payload['name'], 'Long Run');
      expect(payload['type'], 'PHASED');
      expect(
        payload['datetime'],
        '${session.sessionDate.toIso8601String().split('T').first}'
        'T${hour.toString().padLeft(2, '0')}:00',
      );
      final exercise = (payload['exerciseTargets'] as List).single as Map;
      expect(exercise['sportId'], 1);
      final phase = (exercise['phases'] as List).single as Map;
      expect(phase['duration'], '01:00:00');
      expect(phase['intensityType'], 'HEART_RATE_ZONES');
      expect(phase['lowerZone'], 2);
      expect(phase['upperZone'], 2);
      expect(shared, isEmpty);
      expect(find.text('Workout sent to Polar'), findsOneWidget);
    }

    testWidgets(
      'the saved Connections Flow login sends the workout through the uploader',
      (tester) async {
        await showPolar(tester, savedLogin: true);
        expectUploaded();
        expect(find.text('POLAR FLOW LOGIN'), findsNothing);
        final delivery = await db.select(db.workoutDeliveries).getSingle();
        expect(delivery.providerId, 'polar');
        expect(delivery.sessionId, session.id);
        expect(delivery.remoteId, '123456');
        await close(tester);
      },
    );

    for (final second in [false, true]) {
      testWidgets(
        'workout details upload the ${second ? 'second at 18:00' : 'first at 09:00'} '
        'using saved Connections credentials',
        (tester) async {
          final later = session.copyWith(id: 's2', sessionNumber: 2);
          await db.into(db.trainingSessions).insert(later);
          if (second) session = later;
          await showPolar(tester, savedLogin: true);
          expectUploaded(hour: second ? 18 : 9);
          expect(find.text('POLAR FLOW LOGIN'), findsNothing);
          final delivery = await db.select(db.workoutDeliveries).getSingle();
          expect(delivery.sessionId, session.id);
          await close(tester);
        },
      );
    }

    testWidgets('without a Flow login, sign-in resumes the selected upload', (
      tester,
    ) async {
      await showPolar(tester);
      expect(find.text('POLAR FLOW LOGIN'), findsOneWidget);
      expect(find.text('Sign in with Polar Flow'), findsNothing);
      expect(flow.targets, isEmpty);
      expect(shared, isEmpty);
      await tester.enterText(find.byType(TextField).first, 'me@example.com');
      await tester.enterText(find.byType(TextField).last, 'secret');
      await tester.tap(find.text('Sign in and send workout'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expectUploaded();
      expect(find.text('POLAR FLOW LOGIN'), findsNothing);
      await close(tester);
    });

    testWidgets('cancelling Flow sign-in neither uploads nor shares', (
      tester,
    ) async {
      await showPolar(tester);
      await tester.pageBack();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(flow.targets, isEmpty);
      expect(shared, isEmpty);
      expect(
        await const FlutterSecureStorage().read(key: 'polar_flow_email'),
        isNull,
      );
      expect(find.text('Workout sent to Polar'), findsNothing);
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Push to Polar'),
      );
      expect(button.onPressed, isNotNull);
      await close(tester);
    });

    testWidgets('a rejected Flow login stays on sign-in without sending', (
      tester,
    ) async {
      await showPolar(tester);
      await tester.enterText(find.byType(TextField).first, 'me@example.com');
      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.tap(find.text('Sign in and send workout'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Incorrect Polar e-mail or password.'), findsOneWidget);
      expect(find.text('POLAR FLOW LOGIN'), findsOneWidget);
      expect(
        await const FlutterSecureStorage().read(key: 'polar_flow_email'),
        isNull,
      );
      expect(flow.targets, isEmpty);
      expect(shared, isEmpty);
      await close(tester);
    });

    testWidgets('a refused upload shows the error without sharing text', (
      tester,
    ) async {
      await showPolar(tester);
      flow.refuseUploads = true;
      await tester.enterText(find.byType(TextField).first, 'me@example.com');
      await tester.enterText(find.byType(TextField).last, 'secret');
      await tester.tap(find.text('Sign in and send workout'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.textContaining('Upload refused.'), findsOneWidget);
      expect(find.text('Workout sent to Polar'), findsNothing);
      expect(await db.select(db.workoutDeliveries).get(), isEmpty);
      expect(shared, isEmpty);
      await close(tester);
    });
  });

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
        // Even a legacy false flag must not disable connected COROS uploads.
        'user_profile_v1': jsonEncode({'corosWorkoutPush': false}),
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
      expect(find.textContaining('Sync COROS to your watch'), findsOneWidget);
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
        // Strength is never pushed as a timed outline: COROS gets the list.
        final button = find.text('Share exercise list for COROS');
        await tester.scrollUntilVisible(
          button,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
        await tester.pumpAndSettle();
        expect(find.text('Push to COROS'), findsNothing);
        expect(
          find.textContaining('COROS does not take strength exercises'),
          findsOneWidget,
        );
        await tester.tap(button);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(sent, isEmpty);
        expect(shared, isNotEmpty);
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
        bool polarFlow = false,
      }) async {
        FlutterSecureStorage.setMockInitialValues({
          'user_profile_v1': jsonEncode({'corosWorkoutPush': corosOn}),
          if (polarFlow) ...{
            'polar_flow_email': 'me@example.com',
            'polar_flow_password': 'secret',
          },
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
      expect(t.map((e) => e.route), [WorkoutRoute.push, WorkoutRoute.push]);
      // Legacy true and false settings both use COROS upload.
      t = await targets([
        WorkoutDestination.garmin,
        WorkoutDestination.coros,
      ], corosOn: true);
      expect(t.map((e) => e.route), [WorkoutRoute.push, WorkoutRoute.push]);
      // Polar offers explicit upload even before its Flow login is saved.
      t = await targets([
        WorkoutDestination.polar,
        WorkoutDestination.suunto,
      ], corosOn: true);
      expect(t.map((e) => e.route), [WorkoutRoute.push, WorkoutRoute.share]);
      // Saving a Flow login keeps Polar on explicit upload, without enrolling
      // it in automatic delivery of all upcoming plan sessions.
      t = await targets(
        [WorkoutDestination.polar],
        corosOn: false,
        polarFlow: true,
      );
      expect(t.single.route, WorkoutRoute.push);
      expect(t.single.provider.autoDeliver, isFalse);
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
        (WorkoutDestination.coros, WorkoutRoute.push),
        (WorkoutDestination.polar, WorkoutRoute.push),
      ],
    );
    await tester.scrollUntilVisible(
      find.text('Push to Garmin'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Push to Garmin'), findsOneWidget);
    expect(find.text('Push to COROS'), findsOneWidget);
    expect(find.text('Push to Polar'), findsOneWidget);
    await close(tester);
  });

  testWidgets('connected COROS always offers upload without an opt-in', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'user_profile_v1': jsonEncode({'corosWorkoutPush': false}),
    });
    await show(tester, WorkoutDestination.coros);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlanSessionSheet)),
    );
    final provider = container.read(workoutProvidersProvider).byId('coros')!;
    expect(await provider.mode(), DeliveryMode.push);
    expect(provider.optIn, isNull);
    expect(find.text('Share workout for COROS'), findsNothing);
    expect(find.text('Send to COROS instead (experimental)'), findsNothing);
    await close(tester);
  });

  testWidgets('moving onto a rest day asks first, and can be undone', (
    tester,
  ) async {
    await show(tester, WorkoutDestination.garmin);
    // The profile's default rest day is Sunday: find the next one.
    final today = DateUtils.dateOnly(DateTime.now());
    var sunday = today.add(const Duration(days: 1));
    while (sunday.weekday != DateTime.sunday ||
        DateUtils.isSameDay(sunday, session.sessionDate)) {
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
    await tester.scrollUntilVisible(
      chip,
      200,
      scrollable: find.descendant(
        of: find.byType(MoveWorkoutCard),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(find.text('Undo'));
    await tester.pumpAndSettle();
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
    await tester.scrollUntilVisible(
      find.text('MOVE THIS WORKOUT'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
    final chip = find.bySemanticsLabel(
      RegExp('^${RegExp.escape(DateFormat('EEEE d MMMM').format(day))}'),
    );
    await tester.scrollUntilVisible(
      chip,
      200,
      scrollable: find.descendant(
        of: find.byType(MoveWorkoutCard),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.textContaining('Moved from'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    // It stays: there is nothing to swipe away, and the way back is still there.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);
    await tester.ensureVisible(find.text('Undo'));
    await tester.pumpAndSettle();
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
