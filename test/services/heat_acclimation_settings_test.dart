import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fjelia/services/heat_acclimation_settings.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('heat acclimation is on by default', () async {
    const store = HeatAcclimationSettingsStore();
    expect(const HeatAcclimationSettings().enabled, isTrue);
    expect(await store.isEnabled(), isTrue);
    expect((await store.load()).enabled, isTrue);
  });

  test('an explicit choice to switch it off is kept', () async {
    const store = HeatAcclimationSettingsStore();
    await store.saveEnabled(false);
    expect(await store.isEnabled(), isFalse);
    expect((await store.load()).enabled, isFalse);
  });
}
