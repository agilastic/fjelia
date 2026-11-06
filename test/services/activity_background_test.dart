import 'package:fjelia/services/activity_background.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('fjelia/background_test');
  late ActivityBackground service;
  final configs = <Map>[];
  bool failNext = false;
  setUp(() {
    configs.clear();
    failNext = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'clock') return 987654321;
      final config = call.arguments as Map;
      configs.add(config);
      if (failNext) {
        failNext = false;
        throw PlatformException(code: 'test');
      }
      return null;
    });
    service = ActivityBackground(channel: channel);
  });
  tearDown(() async {
    await service.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  test(
    'ECG stopping cannot stop its parent GPS workout or vice versa',
    () async {
      await service.start('activity', gps: true, bluetooth: false, name: 'Run');
      await service.start('ecg', gps: false, bluetooth: true, name: 'H10');
      expect(configs.last, containsPair('gps', true));
      expect(configs.last, containsPair('bluetooth', true));
      expect(configs.last['name'], 'Run');
      await service.stop('ecg');
      expect(configs.last['active'], true);
      expect(configs.last['gps'], true);
      expect(configs.last['bluetooth'], false);
      await service.start('ecg', gps: false, bluetooth: true, name: 'H10');
      await service.stop('activity');
      expect(configs.last['active'], true);
      expect(configs.last['gps'], false);
      await service.stop('ecg');
      expect(configs.last['active'], false);
    },
  );
  test(
    'a failed native start rolls back GPS without dropping an existing ECG',
    () async {
      await service.start('ecg', gps: false, bluetooth: true, name: 'H10');
      failNext = true;
      await expectLater(
        service.start('activity', gps: true, bluetooth: true, name: 'Run'),
        throwsA(isA<PlatformException>()),
      );
      expect(configs.last['active'], true);
      expect(configs.last['gps'], false);
      expect(configs.last['name'], 'H10');
      await service.stop('ecg');
      expect(configs.last['active'], false);
    },
  );
  test(
    'native continuous clock is independent of the UI and wall clock',
    () async {
      expect(await service.monotonicMilliseconds(), 987654321);
    },
  );
  test(
    'native GPS callbacks retain observed timestamps and accuracy',
    () async {
      final fix = service.locations.first;
      const codec = StandardMethodCodec();
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(
          const MethodCall('location', {
            't': 1793872800000,
            'lat': 52.3,
            'lng': 9.7,
            'accuracy': 5.0,
          }),
        ),
        (_) {},
      );
      final observed = await fix;
      expect(observed.latitude, 52.3);
      expect(observed.at.millisecondsSinceEpoch, 1793872800000);
      expect(observed.accuracy, 5);
    },
  );
}
