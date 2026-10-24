import 'dart:async';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/health_connect_provider.dart';
import 'package:fjelia/services/health_connect_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Health implements Health {
  _Health(this.read);
  final Future<List<HealthDataPoint>> Function() read;

  @override
  Future<void> configure() async {}

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    Map<HealthDataType, HealthDataUnit>? preferredUnits,
    required DateTime startTime,
    required DateTime endTime,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) => read();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  group('probeAccess', () {
    test('answers ok when Health responds', () async {
      final service = HealthConnectService(db, health: _Health(() async => []));
      expect(await service.probeAccess(), HealthAccess.ok);
    });

    test('a read that never answers is unresponsive', () async {
      final service = HealthConnectService(
        db,
        health: _Health(() => Completer<List<HealthDataPoint>>().future),
      );
      expect(
        await service.probeAccess(timeout: const Duration(milliseconds: 50)),
        HealthAccess.unresponsive,
      );
    });

    test('an error is reported as failed', () async {
      final service = HealthConnectService(
        db,
        health: _Health(() async => throw StateError('denied')),
      );
      expect(await service.probeAccess(), HealthAccess.failed);
    });
  });

  group('revoked access', () {
    test(
      'marking it revoked disconnects Health until it is reconnected',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(
          healthConnectPermissionProvider.notifier,
        );
        await notifier.markGranted();
        expect(await notifier.isRevoked(), isFalse);

        await notifier.markRevoked();
        expect(await notifier.isRevoked(), isTrue);
        expect(container.read(healthConnectPermissionProvider).value, isFalse);

        await notifier.markGranted();
        expect(await notifier.isRevoked(), isFalse);
        expect(container.read(healthConnectPermissionProvider).value, isTrue);
      },
    );
  });
}
