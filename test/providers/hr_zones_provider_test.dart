import 'package:fjelia/providers/hr_zones_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('device zones applied right after startup are not overwritten', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // First access (as the first sync after app start does) and apply at once.
    final notifier = container.read(hrZonesProvider.notifier);
    await notifier.applyDeviceZones(
      running: [92, 110, 128, 146, 165],
      cycling: [112, 126, 139, 151, 166],
    );
    await notifier.loaded;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(hrZonesProvider).running.bounds, [
      92,
      110,
      128,
      146,
      165,
    ]);
    expect(container.read(hrZonesProvider).cycling.bounds, [
      112,
      126,
      139,
      151,
      166,
    ]);
  });

  test('stored zones are loaded on the next start', () async {
    final first = ProviderContainer();
    await first
        .read(hrZonesProvider.notifier)
        .applyDeviceZones(running: [92, 110, 128, 146, 165]);
    first.dispose();
    final second = ProviderContainer();
    addTearDown(second.dispose);
    final notifier = second.read(hrZonesProvider.notifier);
    await notifier.loaded;
    expect(second.read(hrZonesProvider).running.bounds, [92, 110, 128, 146, 165]);
  });
}
