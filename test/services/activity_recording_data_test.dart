import 'dart:convert';
import 'dart:async';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/activity_location.dart';
import 'package:fjelia/models/ftms.dart';
import 'package:fjelia/models/indoor_recording.dart';
import 'package:fjelia/models/training_device.dart';
import 'package:fjelia/services/fit_decode.dart';
import 'package:fjelia/services/fit_activity_data.dart';
import 'package:fjelia/services/indoor_fit_export.dart';
import 'package:fjelia/services/indoor_recording_service.dart';
import 'package:fit_sdk/fit_sdk.dart' as fit;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/activity_blood_pressure_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final start = DateTime.utc(2026, 11, 5, 10);
  IndoorCapture capture({bool gps = true, bool bp = true}) => IndoorCapture(
    id: 'manual-test',
    startedAt: start,
    device: const TrainingDevice(id: 'phone', name: 'Fjelia'),
    machine: FtmsMachine.treadmill,
    name: 'Run',
    dataProtocol: 'manual',
    activityTypeOverride: 'running',
    gpsEnabled: gps,
    includeBloodPressure: bp,
  )..event('start', start);
  ActivityLocation fix(
    int seconds, {
    double lat = 52,
    double accuracy = 5,
    double? speed,
  }) => ActivityLocation(
    at: start.add(Duration(seconds: seconds)),
    latitude: lat,
    longitude: 9,
    accuracy: accuracy,
    speed: speed,
    altitude: 80,
  );
  bool ingest(IndoorCapture c, ActivityLocation p, {DateTime? received}) =>
      c.ingestLocation(p, received ?? p.at, recording: true);
  BpMeasurement bp(int seconds, {int id = 1}) => BpMeasurement(
    id: id,
    measuredAt: start.add(Duration(seconds: seconds)),
    timezone: 'UTC',
    systolic: 124,
    diastolic: 76,
    heartRate: 63,
    measurementType: 'HILO',
  );

  test('GPS rejects stale, inaccurate, nonfinite and teleport fixes', () {
    final c = capture();
    expect(ingest(c, fix(1, accuracy: 100)), false);
    expect(
      ingest(c, fix(1), received: start.add(const Duration(seconds: 20))),
      false,
    );
    expect(ingest(c, fix(1, lat: double.nan)), false);
    expect(ingest(c, fix(1)), true);
    expect(ingest(c, fix(1)), false);
    expect(ingest(c, fix(2, lat: 53)), false);
    expect(ingest(c, fix(3, lat: 52.00005)), true);
    expect(c.route, hasLength(2));
    expect(c.distanceMeters, closeTo(5.56, .1));
  });
  test('stationary drift and distance over a GPS gap are not added', () {
    final c = capture();
    ingest(c, fix(1, speed: 0));
    ingest(c, fix(2, lat: 52.00005, speed: 0));
    expect(c.distanceMeters, 0);
    ingest(c, fix(30, lat: 52.01));
    expect(c.distanceMeters, 0);
    ingest(c, fix(32, lat: 52.01005, speed: 3));
    expect(c.distanceMeters, closeTo(5.56, .1));
    expect(c.route.first['segment'], isNot(c.route.last['segment']));
  });
  test('pause or recovery starts a GPS segment without joining the gap', () {
    final c = capture();
    ingest(c, fix(1));
    ingest(c, fix(3, lat: 52.00005));
    c.snapshot(start.add(const Duration(seconds: 3)), 3000);
    final restored = IndoorCapture.fromJson(jsonDecode(jsonEncode(c.toJson())));
    expect(restored.gpsEnabled, true);
    expect(restored.includeBloodPressure, true);
    expect(restored.route, c.route);
    ingest(restored, fix(50, lat: 53));
    expect(restored.distanceMeters, c.distanceMeters);
    restored.clearContinuity();
    ingest(restored, fix(60, lat: 54));
    expect(restored.distanceMeters, c.distanceMeters);
  });
  test(
    'snapshots contain each actual GPS fix once, without repeated positions',
    () {
      final c = capture();
      ingest(c, fix(1));
      c.snapshot(start.add(const Duration(seconds: 1)), 1000);
      c.snapshot(start.add(const Duration(seconds: 2)), 2000);
      expect(c.samples.first['lat'], 52);
      expect(c.samples.last.containsKey('lat'), false);
      expect(c.samples.first['gps_t'], fix(1).at.millisecondsSinceEpoch);
    },
  );
  test(
    'legacy checkpoints keep GPS and BP disabled and do not invent a route',
    () {
      final c = capture(gps: false, bp: false);
      final json = c.toJson()
        ..remove('gps_enabled')
        ..remove('include_blood_pressure')
        ..remove('route');
      final restored = IndoorCapture.fromJson(jsonDecode(jsonEncode(json)));
      expect(restored.gpsEnabled, false);
      expect(restored.includeBloodPressure, false);
      expect(restored.route, isEmpty);
      expect(restored.totals, isEmpty);
    },
  );
  test(
    'BP associations exclude observations outside the run and in pauses',
    () {
      final c = capture();
      c.event('pause', start.add(const Duration(seconds: 20)));
      c.event('resume', start.add(const Duration(seconds: 40)));
      c.snapshot(start.add(const Duration(seconds: 60)), 40000);
      expect(bloodPressureDuringActivity(c, bp(-1)), false);
      expect(bloodPressureDuringActivity(c, bp(10)), true);
      expect(bloodPressureDuringActivity(c, bp(30)), false);
      expect(bloodPressureDuringActivity(c, bp(50)), true);
      expect(bloodPressureDuringActivity(c, bp(61)), false);
      final disabled = capture(bp: false)
        ..snapshot(start.add(const Duration(seconds: 60)), 60000);
      expect(bloodPressureDuringActivity(disabled, bp(10)), false);
    },
  );
  test('GPS coordinates and real BP observations survive FIT interchange', () {
    final c = capture();
    ingest(c, fix(1));
    c.snapshot(start.add(const Duration(seconds: 1)), 1000);
    ingest(c, fix(6, lat: 52.0001));
    c.snapshot(start.add(const Duration(seconds: 6)), 6000);
    final bytes = indoorFit(c, bloodPressure: [bp(-1), bp(3), bp(10)]);
    final decoded = parseFitActivity(bytes)!;
    expect(decoded.route, hasLength(2));
    expect(decoded.route.last['lat'], closeTo(52.0001, .000001));
    expect(decoded.distanceMeters, closeTo(11.12, .1));
    final pressures = <fit.BloodPressureMesg>[];
    final decoder = FitDecode()
      ..onMesg = (m) {
        if (m.num == fit.MesgNum.bloodPressure) {
          pressures.add(fit.BloodPressureMesg.fromMesg(m));
        }
      };
    decoder.read(bytes);
    expect(pressures, hasLength(1));
    expect(pressures.single.getSystolicPressure(), 124);
    expect(pressures.single.getDiastolicPressure(), 76);
    expect(pressures.single.getTimestamp()!.toUtc(), bp(3).measuredAt);
    expect(
      c.samples.any((s) => s.containsKey('sys') || s.containsKey('dia')),
      false,
    );
  });
  test('the real BP provider observes later database inserts', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    final changed = Completer<List<BpMeasurement>>();
    final listener = container.listen(activityBloodPressureProvider(start), (
      _,
      current,
    ) {
      if ((current.valueOrNull?.isNotEmpty ?? false) && !changed.isCompleted) {
        changed.complete(current.value!);
      }
    });
    expect(
      await container
          .read(activityBloodPressureProvider(start).future)
          .timeout(const Duration(seconds: 3)),
      isEmpty,
    );
    await db
        .into(db.bpMeasurements)
        .insert(
          BpMeasurementsCompanion.insert(
            measuredAt: start.add(const Duration(minutes: 5)),
            systolic: 122,
            diastolic: 75,
            heartRate: 62,
          ),
        );
    expect(
      (await changed.future.timeout(const Duration(seconds: 3)))
          .single
          .systolic,
      122,
    );
    listener.close();
    container.dispose();
    await db.close();
  });
  test('saved routes and later-synced BP are available without rewriting an activity', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final storage = IndoorRecordingService(db);
    final c = capture();
    ingest(c, fix(1));
    c.snapshot(start.add(const Duration(seconds: 1)), 1000);
    ingest(c, fix(60, lat: 52.001));
    c.snapshot(start.add(const Duration(seconds: 60)), 60000);
    await storage.save(c, zones: [100, 120, 140, 160]);
    final activity = (await db.getActivityById(c.id))!;
    expect(jsonDecode(activity.gpxJson!), hasLength(2));
    expect(await storage.bloodPressure(c), isEmpty);
    await db
        .into(db.bpMeasurements)
        .insert(
          BpMeasurementsCompanion.insert(
            measuredAt: bp(30).measuredAt,
            systolic: 124,
            diastolic: 76,
            heartRate: 63,
          ),
        );
    expect(
      await storage.bloodPressure((await storage.load(c.id))!),
      hasLength(1),
    );
    expect((await db.getActivityById(c.id))!.metricsJson, activity.metricsJson);
  });
}
