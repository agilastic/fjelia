import 'package:fjelia/api/garmin_client.dart';
import 'package:fjelia/api/renpho_client.dart';
import 'package:fjelia/providers/auth_provider.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoAktiia implements AktiiaClient {
  @override
  Future<bool> get isLoggedIn async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoGarmin extends GarminClient {
  @override
  Future<bool> get isLoggedIn async => false;
}

Future<AuthNotifier> _start() async {
  final auth = AuthNotifier(_NoAktiia(), _NoGarmin(), RenphoClient());
  for (var i = 0; i < 50 && auth.state.status == LoginStatus.loading; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return auth;
}

void main() {
  test('finishing setup without an account is kept across starts', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final first = await _start();
    expect(first.state.status, LoginStatus.needsOnboarding);

    await first.skipGarmin();
    expect(first.state.status, LoginStatus.loggedIn);

    final next = await _start();
    expect(next.state.status, LoginStatus.loggedIn);
  });
}
