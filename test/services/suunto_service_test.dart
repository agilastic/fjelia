import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/suunto_service.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Signer implements SuuntoRequestSigner {
  _Signer({this.isAvailable = true});
  @override
  final bool isAvailable;
  final salts = <String>[];
  @override
  String totp(String salt) {
    salts.add(salt);
    return '123456';
  }
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('without a signer Suunto says it is unavailable and sends nothing', () {
    var requests = 0;
    final service = SuuntoService(
      db,
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
      signer: _Signer(isAvailable: false),
    );
    expect(
      service.requestSmsPin('+491234'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('not available in this build'),
        ),
      ),
    );
    expect(requests, 0);
  });

  test(
    'requests carry the code of the signer, salted with the phone',
    () async {
      final signer = _Signer();
      late http.Request seen;
      final service = SuuntoService(
        db,
        client: MockClient((request) async {
          seen = request;
          return http.Response('{"result":"ok"}', 200);
        }),
        signer: signer,
      );
      expect(await service.requestSmsPin('+491234'), isTrue);
      expect(seen.headers['x-totp'], '123456');
      expect(signer.salts, ['+491234']);
    },
  );
}
