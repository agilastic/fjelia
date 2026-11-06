import 'dart:async';
import 'dart:convert';

import 'package:fjelia/models/training_ble_profile.dart';
import 'package:fjelia/providers/device_recording_owner_provider.dart';
import 'package:fjelia/providers/gym_treadmill_provider.dart';
import 'package:fjelia/providers/hrv_reminder_provider.dart';
import 'package:fjelia/services/matrix_xid_client.dart';
import 'package:fjelia/services/training_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const machine = TrainingDevice(id: 'matrix', name: 'Matrix T7xi');

class _ProbeConnection extends TrainingBleConnection {
  _ProbeConnection({this.wait, this.fail = false});
  final Completer<void>? wait;
  final bool fail;
  int closed = 0, connected = 0;
  @override
  Future<void> connect(TrainingDevice found) async {
    connected++;
    await wait?.future;
    if (fail) throw StateError('Connection failed');
  }

  @override
  TrainingBleReport report(TrainingDevice device) =>
      TrainingBleReport(device: device, services: const []);
  @override
  Future<void> close() async {
    closed++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'equipment inspection owns its connection until discovery has completed',
    () async {
      final wait = Completer<void>();
      final connection = _ProbeConnection(wait: wait);
      final container = ProviderContainer(
        overrides: [gymBleFactoryProvider.overrideWithValue(() => connection)],
      );
      addTearDown(container.dispose);
      final actions = container.read(gymTreadmillActionsProvider);
      final pending = actions.inspect(machine);
      expect(container.read(deviceRecordingOwnerProvider), 'gym_inspect');
      await expectLater(actions.inspect(machine), throwsStateError);
      expect(connection.connected, 1);
      wait.complete();
      expect((await pending).device.id, machine.id);
      expect(connection.closed, 1);
      expect(container.read(deviceRecordingOwnerProvider), isNull);
    },
  );
  test(
    'failed discovery closes its connection and releases ownership',
    () async {
      final connection = _ProbeConnection(fail: true);
      final container = ProviderContainer(
        overrides: [gymBleFactoryProvider.overrideWithValue(() => connection)],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(gymTreadmillActionsProvider).inspect(machine),
        throwsStateError,
      );
      expect(connection.closed, 1);
      expect(container.read(deviceRecordingOwnerProvider), isNull);
    },
  );
  test('an active ECG or HRV measurement prevents inspection', () async {
    final connection = _ProbeConnection();
    final container = ProviderContainer(
      overrides: [gymBleFactoryProvider.overrideWithValue(() => connection)],
    );
    addTearDown(container.dispose);
    container.read(deviceRecordingOwnerProvider.notifier).state = 'ecg';
    await expectLater(
      container.read(gymTreadmillActionsProvider).inspect(machine),
      throwsStateError,
    );
    expect(container.read(deviceRecordingOwnerProvider), 'ecg');
    container.read(deviceRecordingOwnerProvider.notifier).state = null;
    container.read(hrvCaptureActiveProvider.notifier).state = true;
    await expectLater(
      container.read(gymTreadmillActionsProvider).inspect(machine),
      throwsStateError,
    );
    expect(connection.connected, 0);
  });

  Future<ProviderContainer> account({required http.Client httpClient}) async {
    final client = MatrixXidClient(client: httpClient);
    final container = ProviderContainer(
      overrides: [matrixXidClientProvider.overrideWithValue(client)],
    );
    addTearDown(() {
      container.dispose();
      client.close();
    });
    await container
        .read(gymTreadmillActionsProvider)
        .signIn('gym.netpulse.com', '1234567890', 'private-pin');
    return container;
  }

  http.Response login() => http.Response(
    '{"uuid":"user"}',
    200,
    headers: {'set-cookie': 'JSESSIONID=fixture; Secure; HttpOnly'},
  );

  test('only the session is persisted; disconnect removes it', () async {
    final container = await account(
      httpClient: MockClient((r) async => login()),
    );
    final stored = await const FlutterSecureStorage().readAll();
    expect(jsonEncode(stored), contains('JSESSIONID=fixture'));
    expect(jsonEncode(stored), isNot(contains('private-pin')));
    expect(
      (await container.read(matrixXidSessionProvider.future))!.userId,
      'user',
    );
    await container.read(gymTreadmillActionsProvider).disconnect();
    expect(await container.read(matrixXidSessionProvider.future), isNull);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });
  test(
    'expired history sessions are removed and require explicit sign-in',
    () async {
      final container = await account(
        httpClient: MockClient(
          (r) async =>
              r.method == 'POST' ? login() : http.Response('secret', 401),
        ),
      );
      await expectLater(
        container.read(gymTreadmillActionsProvider).load(days: 7),
        throwsA(isA<MatrixXidException>()),
      );
      expect(await container.read(matrixXidSessionProvider.future), isNull);
      expect(container.read(matrixXidErrorProvider), contains('Sign in again'));
      expect(
        await const FlutterSecureStorage().read(key: 'matrix_xid_session_v1'),
        isNull,
      );
    },
  );
  test('disabled automatic sync performs no history request', () async {
    var histories = 0;
    final container = await account(
      httpClient: MockClient((r) async {
        if (r.method == 'POST') return login();
        histories++;
        return http.Response(
          '{"distanceUnit":"kilometer","intervals":[]}',
          200,
        );
      }),
    );
    final actions = container.read(gymTreadmillActionsProvider);
    await actions.setAutoSync(false);
    await actions.sync();
    expect(histories, 0);
  });

  test(
    'disconnect during login cannot restore the session afterwards',
    () async {
      final reply = Completer<http.Response>();
      final entered = Completer<void>();
      final client = MatrixXidClient(
        client: MockClient((r) async {
          entered.complete();
          return reply.future;
        }),
      );
      final container = ProviderContainer(
        overrides: [matrixXidClientProvider.overrideWithValue(client)],
      );
      addTearDown(() {
        container.dispose();
        client.close();
      });
      final actions = container.read(gymTreadmillActionsProvider);
      final pending = actions.signIn('gym.netpulse.com', 'xid', 'pin');
      await entered.future;
      await actions.disconnect();
      reply.complete(login());
      await pending;
      expect(await container.read(matrixXidSessionProvider.future), isNull);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    },
  );

  test(
    'disconnect during history loading cancels delivery of that account’s data',
    () async {
      final reply = Completer<http.Response>();
      final entered = Completer<void>();
      final container = await account(
        httpClient: MockClient((r) async {
          if (r.method == 'POST') return login();
          entered.complete();
          return reply.future;
        }),
      );
      final actions = container.read(gymTreadmillActionsProvider);
      final pending = actions.load(days: 7);
      final cancelled = expectLater(pending, throwsStateError);
      await entered.future;
      await actions.disconnect();
      reply.complete(
        http.Response('{"distanceUnit":"kilometer","intervals":[]}', 200),
      );
      await cancelled;
      expect(await container.read(matrixXidSessionProvider.future), isNull);
    },
  );
}
