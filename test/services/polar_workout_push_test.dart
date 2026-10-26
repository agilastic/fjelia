import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fjelia/api/polar_flow_web_client.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/prepared_workout.dart';
import 'package:fjelia/services/polar_service.dart';
import 'package:fjelia/services/workout_providers/polar_workout_provider.dart';
import 'package:fjelia/services/workout_providers/workout_providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

class _FlowState {
  final targets = <String, Map<String, dynamic>>{};
  final updated = <String>[];
  final deleted = <String>[];
  var creates = 0;
  var logins = 0;
  var refuseWrites = false;
  var refuseDeletes = false;
}

class _Flow extends PolarFlowWebClient {
  _Flow(this.state)
    : super(client: MockClient((_) async => http.Response('', 500)));
  final _FlowState state;

  @override
  Future<void> login(String email, String password) async {
    expect(email, 'me@example.com');
    expect(password, 'secret');
    state.logins++;
  }

  @override
  Future<String> createTrainingTarget(Map<String, dynamic> target) async {
    if (state.refuseWrites) {
      throw PolarFlowException('Refused', statusCode: 400);
    }
    final id = '${++state.creates}';
    final saved = jsonDecode(jsonEncode(target)) as Map<String, dynamic>;
    saved['id'] = int.parse(id);
    (saved['exerciseTargets'] as List).single['id'] = int.parse(id) + 100;
    state.targets[id] = saved;
    return id;
  }

  @override
  Future<Map<String, dynamic>?> trainingTarget(String id) async =>
      state.targets[id];

  @override
  Future<void> updateTrainingTarget(
    String id,
    Map<String, dynamic> target,
  ) async {
    if (state.refuseWrites) {
      throw PolarFlowException('Refused', statusCode: 400);
    }
    expect(
      (target['exerciseTargets'] as List).single['id'],
      (state.targets[id]!['exerciseTargets'] as List).single['id'],
    );
    state.updated.add(id);
    state.targets[id] = target;
  }

  @override
  Future<void> deleteTrainingTarget(String id) async {
    if (state.refuseDeletes) {
      throw PolarFlowException('Unavailable', statusCode: 503);
    }
    state.deleted.add(id);
    state.targets.remove(id);
  }
}

PreparedWorkout _workout({
  int seconds = 1800,
  DateTime? date,
  String sport = 'running',
}) => PreparedWorkout(
  sessionId: 's1',
  title: 'Easy run',
  date: date ?? DateTime(2026, 10, 28),
  sport: sport,
  steps: [
    {
      'type': 'ExecutableStepDTO',
      'stepType': {'stepTypeKey': 'interval'},
      'endCondition': {'conditionTypeKey': 'time'},
      'endConditionValue': seconds,
      'zoneNumber': 2,
      'targetType': {'workoutTargetTypeKey': 'heart.rate.zone'},
      'targetValueOne': 110,
      'targetValueTwo': 127,
    },
  ],
  description: 'Easy aerobic work.',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late TrainingSession session;
  late _FlowState flow;
  late PolarService service;
  late PolarWorkoutProvider provider;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'polar_flow_email': 'me@example.com',
      'polar_flow_password': 'secret',
    });
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: 's1',
            planId: 'plan',
            athleteId: 'self',
            sessionDate: DateTime(2026, 10, 28),
            sessionNumber: 1,
            weekNumber: 1,
            sport: 'running',
            sessionType: 'easy',
            phase: 'base',
            primaryZone: 2,
            title: 'Easy run',
            plannedDurationMin: 30,
            plannedTrimp: 30,
            sessionLevel: 1,
          ),
        );
    session = await db.select(db.trainingSessions).getSingle();
    flow = _FlowState();
    service = PolarService(db, flowClientFactory: () => _Flow(flow));
    provider = PolarWorkoutProvider(db, service, connected: () async => false);
  });
  tearDown(() => db.close());

  test(
    'explicit upload checks Flow login without automatic plan delivery',
    () async {
      expect(await provider.isConnected(), isTrue);
      expect(await provider.mode(), DeliveryMode.push);
      expect(await provider.needsFlowLogin, isFalse);
      final registry = WorkoutProviders([provider]);
      expect(await registry.connected(), [provider]);
      expect(await registry.pushTargets(), isEmpty);
      expect(flow.creates, 0);
      await service.clearFlowLogin();
      expect(await provider.isConnected(), isFalse);
      expect(await provider.mode(), DeliveryMode.push);
      expect(await provider.needsFlowLogin, isTrue);
    },
  );

  test(
    'sends once and keeps a durable Polar target id across provider instances',
    () async {
      await provider.deliver(session, () async => _workout());
      expect(await provider.hasDelivered(session), isTrue);
      final row = await db.select(db.workoutDeliveries).getSingle();
      expect(row.remoteId, '1');
      expect(row.providerId, 'polar');
      expect(row.day, '20261028');
      expect(row.name, 'Easy run');
      final restarted = PolarWorkoutProvider(
        db,
        service,
        connected: () async => true,
      );
      await restarted.deliver(session, () async => _workout());
      expect(flow.creates, 1);
      expect(flow.updated, isEmpty);
    },
  );

  test('disconnecting Polar also disables Flow workout delivery', () async {
    await service.disconnect();
    expect(await service.hasFlowLogin, isFalse);
    expect(await provider.needsFlowLogin, isTrue);
    expect(await provider.isConnected(), isFalse);
  });

  test('concurrent button presses create a single target', () async {
    await Future.wait([
      provider.deliver(session, () async => _workout()),
      provider.deliver(session, () async => _workout()),
    ]);
    expect(flow.creates, 1);
  });

  test(
    'changed and moved workouts update the original target and exercise id',
    () async {
      await provider.deliver(session, () async => _workout());
      await provider.deliver(session, () async => _workout(seconds: 2400));
      await provider.deliver(
        session,
        () async => _workout(seconds: 2400, date: DateTime(2026, 10, 29)),
      );
      expect(flow.creates, 1);
      expect(flow.updated, ['1', '1']);
      expect(flow.targets['1']!['datetime'], '2026-10-29T18:00');
      final exercise = (flow.targets['1']!['exerciseTargets'] as List).single;
      expect(exercise['id'], 101);
      expect((exercise['phases'] as List).single['duration'], '00:40:00');
    },
  );

  test('an externally deleted target can be sent again', () async {
    await provider.deliver(session, () async => _workout());
    flow.targets.clear();
    await provider.deliver(session, () async => _workout());
    expect(flow.creates, 2);
    expect((await db.select(db.workoutDeliveries).getSingle()).remoteId, '2');
  });

  test(
    'a refused create is not recorded; a refused update retains the old record',
    () async {
      flow.refuseWrites = true;
      await expectLater(
        provider.deliver(session, () async => _workout()),
        throwsA(isA<PolarFlowException>()),
      );
      expect(await provider.hasDelivered(session), isFalse);
      flow.refuseWrites = false;
      await provider.deliver(session, () async => _workout());
      final before = await db.select(db.workoutDeliveries).getSingle();
      flow.refuseWrites = true;
      await expectLater(
        provider.deliver(session, () async => _workout(seconds: 2400)),
        throwsA(isA<PolarFlowException>()),
      );
      expect(
        (await db.select(db.workoutDeliveries).getSingle()).fingerprint,
        before.fingerprint,
      );
      expect(flow.creates, 1);
    },
  );

  test(
    'unsupported workouts and missing credentials make no target writes',
    () async {
      await expectLater(
        provider.deliver(session, () async => _workout(sport: 'yoga')),
        throwsA(isA<WorkoutNotSupported>()),
      );
      expect(flow.logins, 0);
      await service.clearFlowLogin();
      await expectLater(
        provider.deliver(session, () async => _workout()),
        throwsA(isA<PolarFlowException>()),
      );
      expect(flow.logins, 0);
      expect(flow.creates, 0);
    },
  );

  test('failed removals are queued and retried by recorded id', () async {
    await provider.deliver(session, () async => _workout());
    flow.refuseDeletes = true;
    await provider.remove(session);
    expect(await provider.hasDelivered(session), isFalse);
    final queued = await db.select(db.providerCleanups).getSingle();
    expect(queued.remoteId, '1');
    expect(queued.providerId, 'polar');
    expect(await provider.retryCleanup(), 0);
    expect((await db.select(db.providerCleanups).getSingle()).attempts, 2);
    flow.refuseDeletes = false;
    expect(await provider.retryCleanup(), 1);
    expect(await db.select(db.providerCleanups).get(), isEmpty);
    expect(flow.deleted, ['1']);
  });

  test(
    'ending a plan offline queues removal without losing the target id',
    () async {
      await provider.deliver(session, () async => _workout());
      await service.clearFlowLogin();
      await provider.remove(session);
      expect(await provider.hasDelivered(session), isFalse);
      expect((await db.select(db.providerCleanups).getSingle()).remoteId, '1');
    },
  );

  test(
    'delete all touches only targets Fjelia recorded, including matching names',
    () async {
      await provider.deliver(session, () async => _workout());
      flow.targets['999'] = {'name': 'Easy run'};
      final progress = <(int, int)>[];
      expect(
        await provider.removeAll(
          titles: {'Easy run'},
          onProgress: (done, total) => progress.add((done, total)),
        ),
        1,
      );
      expect(flow.deleted, ['1']);
      expect(flow.targets.keys, ['999']);
      expect(progress.last, (1, 1));
      expect(await db.select(db.workoutDeliveries).get(), isEmpty);
    },
  );
}
