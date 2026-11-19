import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fjelia/config/secrets.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/oauth_token_store.dart';
import 'package:fjelia/services/polar_service.dart';

const _tokens = {
  'access_token': 'access-1',
  'refresh_token': 'refresh-1',
  'expires_in': 3600,
  'x_user_id': 42,
};

void main() {
  late AppDatabase db;
  late List<http.Request> requests;

  MockClient polar({int tokenStatus = 200}) => MockClient((request) async {
    requests.add(request);
    if (request.url.path.endsWith('/users')) return http.Response('{}', 201);
    return tokenStatus == 200
        ? http.Response(jsonEncode(_tokens), 200)
        : http.Response('{"error":"invalid_grant"}', tokenStatus);
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    requests = [];
    Secrets.debugBuiltPolarClientId = 'fjelia-client';
    await Secrets.load();
  });
  tearDown(() async {
    Secrets.debugBuiltPolarClientId = null;
    await db.close();
  });

  test('the build client sends only the code to push.fjelia.com', () async {
    expect(Secrets.polarViaServer, isTrue);
    final service = PolarService(db, client: polar());
    expect(await service.handleAuthCallback('code-1'), isTrue);

    final exchange = requests.first;
    expect(exchange.url.toString(), 'https://push.fjelia.com/v1/polar/token');
    expect(jsonDecode(exchange.body), {'code': 'code-1'});
    expect(exchange.headers.containsKey('Authorization'), isFalse);
    expect((await oauthTokenStore.load('polar'))?.accessToken, 'access-1');
  });

  test('a refused code signs nobody in', () async {
    final service = PolarService(db, client: polar(tokenStatus: 400));
    expect(await service.handleAuthCallback('used-code'), isFalse);
    expect(await oauthTokenStore.load('polar'), isNull);
  });

  test(
    'an own client (Fjelia CE) asks Polar directly with its secret',
    () async {
      await OwnKey.polarClientId.write('own-id');
      await OwnKey.polarClientSecret.write('own-secret');
      expect(Secrets.polarOwnClient, isTrue);
      final service = PolarService(db, client: polar());
      expect(await service.handleAuthCallback('code-2'), isTrue);

      final exchange = requests.first;
      expect(exchange.url.host, 'polarremote.com');
      expect(
        exchange.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('own-id:own-secret'))}',
      );
      expect(exchange.bodyFields, {
        'grant_type': 'authorization_code',
        'code': 'code-2',
      });
    },
  );

  test('half an own client disables Polar instead of mixing clients', () async {
    await OwnKey.polarClientSecret.write('own-secret');
    expect(Secrets.hasPolar, isFalse);
    expect(
      await PolarService(db, client: polar()).handleAuthCallback('c'),
      isFalse,
    );
    expect(requests, isEmpty);
  });
}
