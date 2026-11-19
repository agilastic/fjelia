import 'package:fjelia/config/secrets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keys entered in the app win and an empty save removes them', () async {
    FlutterSecureStorage.setMockInitialValues({
      'own_key_pirate_weather': ' pw-key ',
      'own_key_polar_client_id': 'id',
    });
    await Secrets.load();
    expect(Secrets.pirateWeatherKey, 'pw-key');
    expect(Secrets.polarClientId, 'id');
    // A Polar client needs both halves.
    expect(Secrets.hasPolar, isFalse);

    await OwnKey.polarClientSecret.write('secret');
    expect(Secrets.hasPolar, isTrue);

    await OwnKey.pirateWeather.write('  ');
    expect(Secrets.pirateWeatherKey, isEmpty);
    expect(await OwnKey.pirateWeather.read(), isNull);
  });
}
