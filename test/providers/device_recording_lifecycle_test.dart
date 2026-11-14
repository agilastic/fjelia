import 'dart:async';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/ecg_provider.dart';
import 'package:fjelia/providers/indoor_recording_provider.dart';
import 'package:fjelia/services/ecg_ble_service.dart';
import 'package:fjelia/services/ftms_device_service.dart';
import 'package:fjelia/services/polar_h10_service.dart';
import 'package:fjelia/providers/hrv_reminder_provider.dart'
    show hrvCaptureActiveProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeEcgDevice extends EcgDeviceService {
  final data = StreamController<EcgFrame>.broadcast();
  Completer<void>? connecting;
  final entered = Completer<void>();
  int starts = 0, stops = 0;
  bool closed = false;
  @override
  Stream<EcgFrame> get frames => data.stream;
  @override
  Future<void> connect(
    TrainingDevice device, {
    bool withAcceleration = false,
  }) async {
    entered.complete();
    await connecting?.future;
  }

  @override
  Future<void> start({bool withAcceleration = false}) async {
    starts++;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    if (!closed) {
      closed = true;
      await data.close();
    }
  }
}

class FakeFtmsDevice extends FtmsDeviceService {
  FakeFtmsDevice() {
    machine = FtmsMachine.bike;
  }
  final data = StreamController<Map<String, num>>.broadcast();
  final statuses = StreamController<String>.broadcast();
  bool closed = false;
  @override
  Stream<Map<String, num>> get measurements => data.stream;
  @override
  Stream<String> get status => statuses.stream;
  @override
  Future<void> connect(TrainingDevice device, {FtmsMachine? preferred}) async {
    machine = preferred ?? FtmsMachine.bike;
  }

  @override
  Future<void> dispose() async {
    if (!closed) {
      closed = true;
      await data.close();
      await statuses.close();
    }
  }
}

class FakeHeartRateDevice extends IndoorHeartRateService {
  final data = StreamController<H10HeartRatePacket>.broadcast();
  bool closed = false;
  @override
  Stream<H10HeartRatePacket> get packets => data.stream;
  @override
  Future<void> connect(TrainingDevice device) async {}
  @override
  Future<void> dispose() async {
    if (!closed) {
      closed = true;
      await data.close();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late ProviderContainer container;
  late FakeEcgDevice ecg;
  late FakeFtmsDevice machine;
  late FakeHeartRateDevice hr;
  const strap = TrainingDevice(id: 'h10', name: 'Polar H10');
  const equipment = TrainingDevice(id: 'bike', name: 'Indoor bike');

  test(
    'H10 HRV and battery connections respect an active device recording',
    () async {
      final sensor = PolarH10Service(connectionAllowed: () => false);
      await expectLater(
        sensor.connect(const H10Device('h10', 'Polar H10', 0)),
        throwsStateError,
      );
      await expectLater(
        sensor.readBattery(const H10Device('h10', 'Polar H10', 0)),
        throwsStateError,
      );
      await sensor.dispose();
    },
  );
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    ecg = FakeEcgDevice();
    machine = FakeFtmsDevice();
    hr = FakeHeartRateDevice();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        ecgDeviceFactoryProvider.overrideWithValue(() => ecg),
        ftmsDeviceFactoryProvider.overrideWithValue(() => machine),
        indoorHeartRateFactoryProvider.overrideWithValue(() => hr),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await ecg.dispose();
    await machine.dispose();
    await hr.dispose();
    await db.close();
  });

  test(
    'an open HRV measurement prevents a competing ECG or indoor capture',
    () async {
      container.read(hrvCaptureActiveProvider.notifier).state = true;
      await expectLater(
        container.read(ecgRecorderProvider.notifier).start(strap),
        throwsStateError,
      );
      final recorder = container.read(indoorRecorderProvider.notifier);
      await recorder.connect(equipment);
      await expectLater(recorder.start(), throwsStateError);
      expect(ecg.starts, 0);
      expect(await db.select(db.indoorRecordings).get(), isEmpty);
    },
  );

  test('ECG disconnection commits partial samples once and releases capture ownership', () async {
    final recorder = container.read(ecgRecorderProvider.notifier);
    await recorder.start(strap);
    await recorder.start(strap);
    expect(ecg.starts, 1);
    ecg.data.add(const EcgFrame(1000000000, [10, 20, 30]));
    await Future<void>.delayed(Duration.zero);
    ecg.data.addError(StateError('Sensor disconnected'));
    await Future<void>.delayed(Duration.zero);
    await recorder.stop(interrupted: true);
    final row = await db.select(db.ecgRecordings).getSingle();
    expect(row.status, 'interrupted');
    expect(row.sampleCount, 3);
    expect(await db.select(db.ecgSampleChunks).get(), hasLength(1));
    expect(container.read(deviceRecordingOwnerProvider), isNull);
    expect(container.read(ecgRecorderProvider).phase, EcgPhase.saved);
    expect(
      container.read(ecgRecorderProvider).error,
      contains('Sensor disconnected'),
    );
  });

  test(
    'cancelling during ECG connection cannot start a hidden recording',
    () async {
      ecg.connecting = Completer<void>();
      final recorder = container.read(ecgRecorderProvider.notifier);
      final starting = recorder.start(strap);
      await ecg.entered.future;
      await recorder.stop(interrupted: true);
      ecg.connecting!.complete();
      await starting;
      expect(ecg.starts, 0);
      expect(ecg.closed, isTrue);
      expect(await db.select(db.ecgRecordings).get(), isEmpty);
      expect(container.read(deviceRecordingOwnerProvider), isNull);
    },
  );

  test(
    'ECG keeps receiving while backgrounded and stops only explicitly',
    () async {
      final recorder = container.read(ecgRecorderProvider.notifier);
      await recorder.start(strap);
      ecg.data.add(const EcgFrame(1000000000, [10, 20, 30]));
      await Future<void>.delayed(Duration.zero);
      recorder.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(container.read(ecgRecorderProvider).phase, EcgPhase.recording);
      await recorder.stop();
      expect(
        (await db.select(db.ecgRecordings).getSingle()).status,
        'complete',
      );
    },
  );

  test(
    'indoor and ECG recording cannot own a capture simultaneously',
    () async {
      final indoor = container.read(indoorRecorderProvider.notifier);
      await indoor.connect(equipment);
      await indoor.start();
      expect(
        container.read(indoorRecorderProvider).phase,
        IndoorPhase.recording,
      );
      await expectLater(
        container.read(ecgRecorderProvider.notifier).start(strap),
        throwsStateError,
      );
      await indoor.discard();
      expect(container.read(deviceRecordingOwnerProvider), isNull);
      expect(await db.select(db.indoorRecordings).get(), isEmpty);
    },
  );

  test(
    'an explicitly paused indoor session restores without resuming itself',
    () async {
      final indoor = container.read(indoorRecorderProvider.notifier);
      await indoor.connect(equipment);
      await indoor.start();
      machine.data.add({
        'spd': 5,
        'w': 200,
        'hr': 120,
        'machine_distance': 100,
      });
      await Future<void>.delayed(Duration.zero);
      await indoor.pause();
      final id = container.read(indoorRecorderProvider).capture!.id;
      expect(
        (await db.select(db.indoorRecordings).getSingle()).status,
        'paused',
      );
      container.invalidate(indoorRecorderProvider);
      // A process restart has no in-memory lease.
      container.read(deviceRecordingOwnerProvider.notifier).state = null;
      await Future<void>.delayed(Duration.zero);
      final fresh = container.read(indoorRecorderProvider.notifier);
      await fresh.restore(id);
      expect(container.read(indoorRecorderProvider).phase, IndoorPhase.paused);
      expect(container.read(indoorRecorderProvider).capture!.id, id);
      expect(container.read(indoorRecorderProvider).connected, isFalse);
      await fresh.discard();
    },
  );

  test(
    'heart-rate preference survives connection and rejects poor contact',
    () async {
      final indoor = container.read(indoorRecorderProvider.notifier);
      await indoor.connect(equipment);
      await indoor.connectHeartRate(strap);
      hr.data.add(const H10HeartRatePacket(150, [], true));
      await Future<void>.delayed(Duration.zero);
      await indoor.start();
      machine.data.add({'spd': 5, 'hr': 110});
      await Future<void>.delayed(Duration.zero);
      expect(container.read(indoorRecorderProvider).live['hr'], 150);
      hr.data.add(const H10HeartRatePacket(180, [], false));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(indoorRecorderProvider).live.containsKey('hr'),
        isFalse,
      );
      indoor.preferExternal(false);
      expect(container.read(indoorRecorderProvider).live['hr'], 110);
      await indoor.discard();
    },
  );
}
