import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/polar_push_service.dart';
import 'package:fjelia/services/polar_service.dart';

final _apnsToken = 'ab' * 32;

class _Polar extends PolarService {
  _Polar(super.db);
  ({int userId, String accessToken})? credentials = (
    userId: 4242,
    accessToken: 'polar-access',
  );

  @override
  Future<({int userId, String accessToken})?> pushCredentials() async =>
      credentials;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late _Polar polar;
  late List<http.Request> requests;
  late int serverStatus;

  PolarPushService service() => PolarPushService(
    polar,
    client: MockClient((request) async {
      requests.add(request);
      return http.Response('', serverStatus);
    }),
    supported: true,
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    polar = _Polar(db);
    requests = [];
    serverStatus = 204;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(polarPushChannel, (call) async {
          return switch (call.method) {
            'register' => _apnsToken,
            'environment' => 'sandbox',
            'takeOpened' => true,
            _ => null,
          };
        });
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(polarPushChannel, null);
    await db.close();
  });

  test('registers the device with the Polar user and its token', () async {
    await service().register();

    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(requests.single.url, PolarPushService.devicesUri);
    expect(body['polar_user_id'], 4242);
    expect(body['polar_access_token'], 'polar-access');
    expect(body['apns_token'], _apnsToken);
    expect(body['environment'], 'sandbox');
    expect(body['installation_id'], isNotEmpty);
  });

  test('asks the server again only after a change or a week', () async {
    final now = DateTime(2026, 11, 19, 8);
    await service().register(now: now);
    await service().register(now: now.add(const Duration(days: 1)));
    expect(requests, hasLength(1));

    polar.credentials = (userId: 7, accessToken: 'other');
    await service().register(now: now.add(const Duration(days: 1)));
    expect(requests, hasLength(2));

    await service().register(now: now.add(const Duration(days: 9)));
    expect(requests, hasLength(3));
  });

  test('calls while one registration runs share it', () async {
    final push = service();
    await Future.wait([push.register(), push.register(), push.register()]);
    expect(requests, hasLength(1));
  });

  test('a refused registration is tried again next time', () async {
    serverStatus = 403;
    await service().register();
    serverStatus = 204;
    await service().register();
    expect(requests, hasLength(2));
  });

  test('without Polar credentials nothing is sent', () async {
    polar.credentials = null;
    await service().register();
    expect(requests, isEmpty);
  });

  test('unregister deletes the device it registered, once', () async {
    await service().register();
    final installation =
        (jsonDecode(requests.single.body) as Map)['installation_id'];
    requests.clear();

    await service().unregister();
    expect(requests.single.url, PolarPushService.deleteUri);
    expect(jsonDecode(requests.single.body), {
      'installation_id': installation,
      'apns_token': _apnsToken,
    });

    requests.clear();
    await service().unregister();
    expect(requests, isEmpty);
  });

  test('outside iOS or with an own Polar client it stays silent', () async {
    final off = PolarPushService(
      polar,
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('', 204);
      }),
      supported: false,
    );
    await off.register();
    expect(await off.takeOpened(), isFalse);
    expect(requests, isEmpty);
  });
}
