import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/vitals_retention.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monday noon.
  final now = DateTime(2026, 11, 2, 12);
  DateTime at(int dayOffset, int hour, [int minute = 0, int second = 0]) =>
      DateTime(now.year, now.month, now.day + dayOffset, hour, minute, second);
  late AppDatabase db;
  late VitalsRetentionService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = VitalsRetentionService(db, now: () => now);
  });
  tearDown(() => db.close());

  Future<void> bp(DateTime t, int sys, {String type = 'POD'}) => db
      .into(db.bpMeasurements)
      .insert(
        BpMeasurementsCompanion.insert(
          measuredAt: t,
          systolic: sys,
          diastolic: 70,
          heartRate: 55,
          measurementType: Value(type),
        ),
      );

  /// A stream reading every 2 minutes for a whole day.
  Future<void> streamDay(int dayOffset) async {
    for (var m = 0; m < 24 * 60; m += 2) {
      await bp(at(dayOffset, 0, m), 120 + m % 7);
    }
  }

  Future<List<BpMeasurement>> bpOn(int dayOffset) =>
      db.getBpInRange(at(dayOffset, 0), at(dayOffset + 1, 0));

  test('today and yesterday stay as recorded', () async {
    await streamDay(0);
    await streamDay(-1);
    await service.run();
    expect(await bpOn(0), hasLength(720));
    expect(await bpOn(-1), hasLength(720));
  });

  test('older days keep one reading per 15 minutes', () async {
    await streamDay(-5);
    final r = await service.run();
    expect(await bpOn(-5), hasLength(96));
    expect(r.bpRemoved, 720 - 96);
    // Runs again without changing anything.
    expect((await service.run()).bpRemoved, 0);
  });

  test('cuff and manual readings stay, a report reading wins', () async {
    await streamDay(-5);
    await bp(at(-5, 8, 3), 131, type: 'CUFF');
    await bp(at(-5, 8, 5), 132, type: 'CUFF');
    await bp(at(-5, 9, 1), 140, type: 'REPORT');
    await bp(at(-5, 21, 7), 118, type: 'MANUAL');
    await service.run();
    final left = await bpOn(-5);
    expect(left.where((r) => r.measurementType == 'CUFF'), hasLength(2));
    expect(left.where((r) => r.measurementType == 'MANUAL'), hasLength(1));
    final nine = left.where(
      (r) => r.measuredAt.hour == 9 && r.measuredAt.minute < 15,
    );
    expect(nine.single.measurementType, 'REPORT');
    expect(nine.single.systolic, 140);
  });

  test('a Hilo report imported after thinning is kept', () async {
    await streamDay(-5);
    await service.run();
    // A report reading that the stream had too, removed by the thinning.
    final added = await db.insertBpMeasurements([
      BpMeasurementsCompanion.insert(
        measuredAt: at(-5, 9, 2),
        systolic: 120 + 122 % 7,
        diastolic: 70,
        heartRate: 55,
        measurementType: const Value('REPORT'),
      ),
    ]);
    expect(added, 1);
    await service.run();
    final nine = (await bpOn(
      -5,
    )).where((r) => r.measuredAt.hour == 9 && r.measuredAt.minute < 15);
    expect(nine.single.measurementType, 'REPORT');
  });

  test('heart rate becomes one mean per source and 15 minutes', () async {
    await db.saveHeartRateSamples(const []);
    await db.batch((b) {
      for (var s = 0; s < 3600; s += 10) {
        b.insert(
          db.heartRateSamples,
          HeartRateSamplesCompanion.insert(
            source: 'polar',
            measuredAt: at(-4, 10, 0, s),
            bpm: s < 900 ? 60 : 80,
          ),
        );
        b.insert(
          db.heartRateSamples,
          HeartRateSamplesCompanion.insert(
            source: 'polar',
            measuredAt: at(0, 10, 0, s),
            bpm: 70,
          ),
        );
      }
    });
    final r = await service.run();
    final old = await db.getHeartRateSamples(at(-4, 0), at(-3, 0));
    expect(old.map((s) => s.bpm), [60, 80, 80, 80]);
    expect(old.first.measuredAt, at(-4, 10));
    expect(r.hrRemoved, 360 - 4);
    // Today is untouched.
    expect(await db.getHeartRateSamples(at(0, 0), at(1, 0)), hasLength(360));
  });

  test('copies of one reading are removed, the best one stays', () async {
    for (var i = 0; i < 50; i++) {
      await bp(at(0, 7, 30), 127);
    }
    await bp(at(0, 7, 30), 127, type: 'REPORT');
    await bp(at(0, 7, 31), 127);
    final removed = await service.removeBpDuplicates();
    expect(removed, 50);
    final left = await bpOn(0);
    expect(left, hasLength(2));
    expect(
      left.firstWhere((r) => r.measuredAt.minute == 30).measurementType,
      'REPORT',
    );
  });

  test('parallel syncs of the same readings store them once', () async {
    List<BpMeasurementsCompanion> day() => [
      for (var m = 0; m < 11; m++)
        BpMeasurementsCompanion.insert(
          measuredAt: at(-1, 6, m * 3),
          systolic: 120 + m,
          diastolic: 70,
          heartRate: 50,
        ),
    ];
    await Future.wait([
      for (var i = 0; i < 20; i++) db.insertBpMeasurements(day()),
    ]);
    expect(await bpOn(-1), hasLength(11));
  });

  test('Apple Health gets one reading per 15 minutes, also today', () async {
    await streamDay(0);
    final rows = await bpOn(0);
    expect(bpForExport(rows), hasLength(96));
  });
}
