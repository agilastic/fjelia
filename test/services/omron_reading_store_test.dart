import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/omron_ble_service.dart';
import 'package:fjelia/services/omron_reading_store.dart';

void main() {
  late AppDatabase db;
  var saved = 0;
  late OmronReadingStore store;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    saved = 0;
    store = OmronReadingStore(db, onSaved: () => saved++);
  });
  tearDown(() => db.close());

  OmronBpRecord reading(int minute, {int sys = 128, int dia = 82}) =>
      OmronBpRecord(
        measuredAt: DateTime(2026, 11, 12, 7, minute),
        systolic: sys,
        diastolic: dia,
        heartRate: 58,
      );

  test('saves readings with the transfer type and refreshes the day', () async {
    expect(await store.save([reading(1), reading(5)], model: 'HEM-7322T'), 2);
    final rows = await db.select(db.bpMeasurements).get();
    expect(rows.map((r) => (r.systolic, r.measurementType)), [
      (128, 'OMRON'),
      (128, 'OMRON'),
    ]);
    expect(saved, 1);

    await store.save([reading(9)], model: standardBpModel);
    await store.save([reading(10)]);
    expect(
      (await db.select(db.bpMeasurements).get())
          .skip(2)
          .map((r) => r.measurementType),
      ['BLE_STANDARD', 'BLE_STANDARD'],
    );
  });

  test('a second import of the same memory adds nothing', () async {
    await store.save([reading(1), reading(5)], model: 'HEM-7322T');
    expect(
      await store.save([
        reading(1),
        reading(5),
        reading(7),
      ], model: 'HEM-7322T'),
      1,
    );
    expect(await db.select(db.bpMeasurements).get(), hasLength(3));
  });

  test('impossible readings are not stored', () async {
    expect(await store.save([reading(1, sys: 80, dia: 80)]), 0);
    expect(await db.select(db.bpMeasurements).get(), isEmpty);
  });
}
