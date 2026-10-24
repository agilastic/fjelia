import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

BpMeasurementsCompanion bp(
  DateTime at,
  int sys,
  int dia, {
  String type = 'POD',
}) => BpMeasurementsCompanion.insert(
  measuredAt: at,
  systolic: sys,
  diastolic: dia,
  heartRate: 60,
  measurementType: Value(type),
);

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  final at = DateTime(2026, 10, 20, 8, 30);

  test('inserting the same reading twice stores it once', () async {
    expect(await db.insertBpMeasurements([bp(at, 130, 80)]), 1);
    expect(await db.insertBpMeasurements([bp(at, 130, 80)]), 0);
    expect(await db.getBpForDate(at), hasLength(1));
  });

  test(
    'a reading from another source in the same minute is a duplicate',
    () async {
      await db.insertBpMeasurements([
        bp(at.add(const Duration(seconds: 40)), 130, 80),
      ]);
      final added = await db.insertBpMeasurements([
        bp(at, 130, 80, type: 'REPORT'),
      ]);
      expect(added, 0);
    },
  );

  test('different values or minutes are kept', () async {
    await db.insertBpMeasurements([bp(at, 130, 80)]);
    final added = await db.insertBpMeasurements([
      bp(at, 131, 80),
      bp(at.add(const Duration(minutes: 1)), 130, 80),
    ]);
    expect(added, 2);
  });

  test('duplicates inside one batch are stored once', () async {
    final added = await db.insertBpMeasurements([
      bp(at, 130, 80),
      bp(at, 130, 80),
    ]);
    expect(added, 1);
  });

  test('newBpMeasurements reports what an import would add', () async {
    await db.insertBpMeasurements([bp(at, 130, 80)]);
    final fresh = await db.newBpMeasurements([
      bp(at, 130, 80),
      bp(at.add(const Duration(hours: 1)), 120, 70),
    ]);
    expect(fresh, hasLength(1));
    expect(await db.getBpForDate(at), hasLength(1));
  });
}
