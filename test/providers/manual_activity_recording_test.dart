import 'dart:async';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/activity_background_provider.dart';
import 'package:fjelia/models/activity_location.dart';
import 'package:fjelia/providers/ecg_provider.dart';
import 'package:fjelia/providers/indoor_recording_provider.dart';
import 'package:fjelia/services/ecg_ble_service.dart';
import 'package:fjelia/services/ftms_device_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_activity_background.dart';

class _H10 extends EcgDeviceService {
  final data = StreamController<EcgFrame>.broadcast();
  final hr = StreamController<H10HeartRatePacket>.broadcast();
  final entered = Completer<void>();
  Completer<void>? connecting;
  Completer<void>? stopping;
  bool fail = false, closed = false;
  @override
  Stream<EcgFrame> get frames => data.stream;
  @override
  Stream<H10HeartRatePacket> get heartRate => hr.stream;
  @override
  Future<void> connect(
    TrainingDevice device, {
    bool withAcceleration = false,
  }) async {
    entered.complete();
    await connecting?.future;
    if (fail) throw StateError('Sensor unavailable');
  }

  @override
  Future<void> start({bool withAcceleration = false}) async {
    data.add(EcgFrame(1000000000, List.filled(130, 50)));
    hr.add(H10HeartRatePacket.decode([0, 145]));
  }

  @override
  Future<void> stop() async {
    await stopping?.future;
  }

  @override
  Future<void> dispose() async {
    if (closed) return;
    closed = true;
    await data.close();
    await hr.close();
  }
}

class _Treadmill extends FtmsDeviceService {
  final data = StreamController<Map<String, num>>.broadcast();
  final statuses = StreamController<String>.broadcast();
  bool closed = false;
  @override
  Stream<Map<String, num>> get measurements => data.stream;
  @override
  Stream<String> get status => statuses.stream;
  @override
  Future<void> connect(TrainingDevice device, {FtmsMachine? preferred}) async {
    // A PM5 with old firmware: a rower whose erg type is unknown.
    concept2 = device.name.startsWith('PM5');
    machine = concept2 ? FtmsMachine.rower : FtmsMachine.treadmill;
  }

  @override
  Future<void> dispose() async {
    if (closed) return;
    closed = true;
    await data.close();
    await statuses.close();
  }
}

class _Hr extends IndoorHeartRateService {
  final data = StreamController<H10HeartRatePacket>.broadcast();
  bool closed = false;
  @override
  Stream<H10HeartRatePacket> get packets => data.stream;
  @override
  Future<void> connect(TrainingDevice device) async {
    data.add(const H10HeartRatePacket(151, [], true));
  }

  @override
  Future<void> dispose() async {
    if (closed) return;
    closed = true;
    await data.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late ProviderContainer container;
  late IndoorRecorder recorder;
  late FakeActivityBackground background;
  final sensors = <_H10>[];
  final hrSensors = <_Hr>[];
  final treadmills = <_Treadmill>[];
  const strap = TrainingDevice(id: 'h10', name: 'Polar H10');
  _H10? next;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    sensors.clear();
    hrSensors.clear();
    treadmills.clear();
    next = null;
    background = FakeActivityBackground();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activityBackgroundProvider.overrideWithValue(background),
        ftmsDeviceFactoryProvider.overrideWithValue(() {
          final machine = _Treadmill();
          treadmills.add(machine);
          return machine;
        }),
        indoorHeartRateFactoryProvider.overrideWithValue(() {
          final sensor = _Hr();
          hrSensors.add(sensor);
          return sensor;
        }),
        ecgDeviceFactoryProvider.overrideWithValue(() {
          final sensor = next ?? _H10();
          next = null;
          sensors.add(sensor);
          return sensor;
        }),
      ],
    );
    recorder = container.read(indoorRecorderProvider.notifier);
  });
  tearDown(() async {
    if (container.read(indoorRecorderProvider).active) await recorder.discard();
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await background.dispose();
    await db.close();
  });
  test('a timed run starts without equipment, a watch, or Bluetooth', () async {
    await recorder.startManual(type: 'running', name: 'Run');
    expect(container.read(indoorRecorderProvider).phase, IndoorPhase.recording);
    expect(container.read(indoorRecorderProvider).capture!.isManual, isTrue);
    expect(sensors, isEmpty);
    expect(container.read(deviceRecordingOwnerProvider), 'indoor');
  });
  test(
    'run and ECG save linked with HR from the same H10 connection',
    () async {
      await recorder.startManual(
        type: 'running',
        name: 'Run',
        ecgDevice: strap,
      );
      await Future<void>.delayed(const Duration(milliseconds: 1150));
      await recorder.pause();
      recorder.manualDistance(5200);
      final id = await recorder.finish();
      expect(id, isNotNull);
      expect(sensors, hasLength(1));
      final activity = await db.getActivityById(id!);
      expect(activity!.type, 'running');
      expect(activity.source, 'manual_recording');
      expect(activity.distanceMeters, 5200);
      expect(activity.avgHeartRate, 145);
      expect(activity.movingDurationSeconds, isNull);
      final ecg = (await db.select(db.ecgRecordings).get()).single;
      expect(ecg.activityId, id);
      expect(ecg.sampleCount, 130);
      expect(ecg.status, 'complete');
      expect(container.read(deviceRecordingOwnerProvider), isNull);
    },
  );
  test(
    'a Bluetooth treadmill records with the H10 ECG and blood pressure',
    () async {
      const machine = TrainingDevice(id: 'tm', name: 'Treadmill');
      await recorder.connect(machine, preferred: FtmsMachine.treadmill);
      expect(container.read(indoorRecorderProvider).connected, isTrue);
      await recorder.start(ecgDevice: strap, includeBloodPressure: true);
      final state = container.read(indoorRecorderProvider);
      expect(state.phase, IndoorPhase.recording);
      expect(state.capture!.isManual, isFalse);
      expect(state.capture!.ecgDevice!.id, strap.id);
      expect(state.capture!.includeBloodPressure, isTrue);
      expect(container.read(ecgRecorderProvider).active, isTrue);
      // Machine counters count from the first reading after a (re)start.
      treadmills.single.data.add({'spd': 3.0, 'machine_distance': 100});
      treadmills.single.data.add({'spd': 3.0, 'machine_distance': 500});
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await recorder.pause();
      expect(container.read(ecgRecorderProvider).active, isFalse);
      await recorder.resume();
      expect(container.read(ecgRecorderProvider).active, isTrue);
      treadmills.last.data.add({'spd': 3.0, 'machine_distance': 500});
      treadmills.last.data.add({'spd': 3.0, 'machine_distance': 900});
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      final id = await recorder.finish();
      expect(id, isNotNull);
      final activity = await db.getActivityById(id!);
      expect(activity!.type, 'treadmill_running');
      expect(activity.source, 'ftms');
      expect(activity.distanceMeters, 800);
      final recordings = await db.select(db.ecgRecordings).get();
      expect(recordings, hasLength(2));
      expect(recordings.every((r) => r.activityId == id), isTrue);
    },
  );
  test('a SkiErg chosen before saves as Nordic skiing on any PM5', () async {
    const pm5 = TrainingDevice(id: 'pm5', name: 'PM5 430000000');
    await recorder.connect(pm5, preferred: FtmsMachine.rower);
    await recorder.start(activityType: 'nordic_skiing');
    final capture = container.read(indoorRecorderProvider).capture!;
    expect(capture.activityType, 'nordic_skiing');
    expect(capture.dataProtocol, 'concept2');
    expect(capture.name, 'SkiErg (Fjelia)');
    treadmills.single.data.add({'pace_500m': 130, 'machine_distance': 100});
    treadmills.single.data.add({'pace_500m': 130, 'machine_distance': 350});
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final id = await recorder.finish();
    final activity = await db.getActivityById(id!);
    expect(activity!.type, 'nordic_skiing');
    expect(activity.distanceMeters, 250);
  });

  test('pause and resume create ECG segments for one activity', () async {
    await recorder.startManual(
      type: 'treadmill_running',
      name: 'Treadmill',
      ecgDevice: strap,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await recorder.pause();
    expect(container.read(deviceRecordingOwnerProvider), 'indoor');
    expect(container.read(ecgRecorderProvider).active, isFalse);
    await recorder.resume();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final id = await recorder.finish();
    expect(id, isNotNull);
    final recordings = await db.select(db.ecgRecordings).get();
    expect(recordings, hasLength(2));
    expect(recordings.every((r) => r.activityId == id), isTrue);
    final saved = await container.read(indoorStorageProvider).load(id!);
    expect(saved!.ecgRecordingIds, hasLength(2));
    expect(saved.ecgDevice!.id, strap.id);
    expect(saved.activityType, 'treadmill_running');
    expect(saved.isManual, isTrue);
  });
  test(
    'an ECG failure leaves the run timer available and allows a new segment',
    () async {
      await recorder.startManual(
        type: 'running',
        name: 'Run',
        ecgDevice: strap,
      );
      sensors.single.data.addError(StateError('Disconnected'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(
        container.read(indoorRecorderProvider).phase,
        IndoorPhase.recording,
      );
      expect(container.read(ecgRecorderProvider).active, isFalse);
      await recorder.restartActivityEcg();
      expect(sensors, hasLength(2));
      expect(
        container.read(indoorRecorderProvider).capture!.ecgRecordingIds,
        hasLength(2),
      );
    },
  );
  test('discarding the run retains unlinked ECG in history', () async {
    await recorder.startManual(type: 'running', name: 'Run', ecgDevice: strap);
    await recorder.discard();
    expect(await db.select(db.activityRecords).get(), isEmpty);
    final ecg = (await db.select(db.ecgRecordings).get()).single;
    expect(ecg.sampleCount, 130);
    expect(ecg.activityId, isNull);
    expect(container.read(deviceRecordingOwnerProvider), isNull);
  });
  test(
    'cancelling while the H10 connects cannot start a late activity',
    () async {
      final blocked = _H10()..connecting = Completer<void>();
      next = blocked;
      final pending = recorder.startManual(
        type: 'running',
        name: 'Run',
        ecgDevice: strap,
      );
      await blocked.entered.future;
      await recorder.discard();
      blocked.connecting!.complete();
      await pending;
      expect(container.read(indoorRecorderProvider).phase, IndoorPhase.idle);
      expect(container.read(ecgRecorderProvider).active, isFalse);
      expect(container.read(deviceRecordingOwnerProvider), isNull);
      expect(await db.select(db.activityRecords).get(), isEmpty);
    },
  );
  test(
    'failed ECG startup does not leave an activity or a recording lease',
    () async {
      next = _H10()..fail = true;
      await expectLater(
        recorder.startManual(type: 'running', name: 'Run', ecgDevice: strap),
        throwsStateError,
      );
      expect(container.read(indoorRecorderProvider).active, isFalse);
      expect(container.read(deviceRecordingOwnerProvider), isNull);
      expect(await db.select(db.activityRecords).get(), isEmpty);
    },
  );
  test(
    'switching apps and locking preserve the run and ECG until explicit pause',
    () async {
      await recorder.startManual(
        type: 'running',
        name: 'Run',
        ecgDevice: strap,
      );
      recorder.didChangeAppLifecycleState(AppLifecycleState.paused);
      container
          .read(ecgRecorderProvider.notifier)
          .didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(
        container.read(indoorRecorderProvider).phase,
        IndoorPhase.recording,
      );
      expect(container.read(ecgRecorderProvider).active, isTrue);
      sensors.single.data.add(EcgFrame(2000000000, List.filled(130, 60)));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(container.read(ecgRecorderProvider).count, 260);
      recorder.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(
        container.read(indoorRecorderProvider).phase,
        IndoorPhase.recording,
      );
      expect(sensors, hasLength(1));
      await recorder.pause();
      expect(container.read(indoorRecorderProvider).phase, IndoorPhase.paused);
      expect(container.read(ecgRecorderProvider).active, isFalse);
    },
  );
  test(
    'continuous time includes screen-off time and excludes an explicit pause',
    () async {
      background.clock = 10000;
      await recorder.startManual(type: 'running', name: 'Run');
      recorder.didChangeAppLifecycleState(AppLifecycleState.paused);
      background.clock = 1810000;
      await recorder.pause();
      expect(
        container.read(indoorRecorderProvider).capture!.elapsedMs,
        1800000,
      );
      expect(background.owners, isEmpty);
      background.clock = 2410000;
      recorder.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await recorder.resume();
      background.clock = 2710000;
      await recorder.pause();
      expect(
        container.read(indoorRecorderProvider).capture!.elapsedMs,
        2100000,
      );
    },
  );
  test(
    'GPS callbacks continue in the background and stop contributing on pause',
    () async {
      background.clock = 10000;
      await recorder.startManual(type: 'running', name: 'Run', recordGps: true);
      recorder.didChangeAppLifecycleState(AppLifecycleState.paused);
      final capture = container.read(indoorRecorderProvider).capture!;
      background.fixes.add(
        ActivityLocation(
          at: capture.startedAt,
          latitude: 52,
          longitude: 9,
          accuracy: 5,
          speed: 3,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      background.fixes.add(
        ActivityLocation(
          at: capture.startedAt.add(const Duration(seconds: 1)),
          latitude: 52.00005,
          longitude: 9,
          accuracy: 5,
          speed: 3,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      background.clock = 12000;
      await recorder.pause();
      expect(capture.route, hasLength(2));
      expect(capture.distanceMeters, closeTo(5.56, .1));
      background.fixes.add(
        ActivityLocation(
          at: capture.startedAt.add(const Duration(seconds: 2)),
          latitude: 52.0001,
          longitude: 9,
          accuracy: 5,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(capture.route, hasLength(2));
      expect(background.owners, isEmpty);
      expect(() => recorder.manualDistance(100), throwsStateError);
      final id = await recorder.finish();
      expect((await db.getActivityById(id!))!.gpxJson, contains('52.00005'));
    },
  );
  test(
    'failure to start native background recording releases the capture lease',
    () async {
      background.failStart = true;
      await expectLater(
        recorder.startManual(type: 'running', name: 'Run'),
        throwsStateError,
      );
      expect(container.read(indoorRecorderProvider).active, false);
      expect(container.read(deviceRecordingOwnerProvider), isNull);
      expect(background.owners, isEmpty);
    },
  );
  test(
    'cancelling during the location permission prompt cannot start later',
    () async {
      background.preparing = Completer<void>();
      final start = recorder.startManual(
        type: 'running',
        name: 'Run',
        recordGps: true,
      );
      await background.entered.future;
      await recorder.discard();
      background.preparing!.complete();
      await start;
      expect(container.read(indoorRecorderProvider).phase, IndoorPhase.idle);
      expect(background.owners, isEmpty);
      expect(container.read(deviceRecordingOwnerProvider), isNull);
    },
  );
  test(
    'Android notification Pause stops the run without saving or discarding it',
    () async {
      background.clock = 10000;
      await recorder.startManual(type: 'running', name: 'Run');
      background.clock = 20000;
      background.commands.add('pause');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(container.read(indoorRecorderProvider).phase, IndoorPhase.paused);
      expect(await db.select(db.activityRecords).get(), isEmpty);
      expect(background.owners, isEmpty);
    },
  );
  test(
    'HR-only activity saves actual strap readings without an ECG session',
    () async {
      background.clock = 10000;
      await recorder.startManual(
        type: 'running',
        name: 'Run',
        heartRateDevice: strap,
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(indoorRecorderProvider).live['hr'], 151);
      expect(sensors, isEmpty);
      expect(background.owners.keys, ['activity']);
      background.clock = 15000;
      await recorder.pause();
      expect(hrSensors.single.closed, true);
      final id = await recorder.finish();
      expect((await db.getActivityById(id!))!.avgHeartRate, 151);
      expect(await db.select(db.ecgRecordings).get(), isEmpty);
    },
  );
  test(
    'Stop waits for an already-running Pause to flush ECG before saving',
    () async {
      background.clock = 10000;
      await recorder.startManual(
        type: 'running',
        name: 'Run',
        ecgDevice: strap,
      );
      sensors.single.stopping = Completer<void>();
      background.clock = 15000;
      final pausing = recorder.pause();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      var saved = false;
      final finishing = recorder.finish().then((value) {
        saved = true;
        return value;
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(saved, false);
      sensors.single.stopping!.complete();
      await pausing;
      final id = await finishing;
      expect(
        (await db.select(db.indoorRecordings).getSingle()).status,
        'saved',
      );
      expect((await db.select(db.ecgRecordings).getSingle()).activityId, id);
      expect(background.owners, isEmpty);
    },
  );
  test('Android notification Stop saves the activity and releases background resources', () async {
    background.clock = 10000;
    await recorder.startManual(type: 'running', name: 'Run');
    background.clock = 20000;
    background.commands.add('stop');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(container.read(indoorRecorderProvider).phase, IndoorPhase.saved);
    expect(await db.select(db.activityRecords).get(), hasLength(1));
    expect(background.owners, isEmpty);
    expect(container.read(deviceRecordingOwnerProvider), isNull);
  });
}
