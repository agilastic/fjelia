import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/hilo_report_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late HiloReportImportService service;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = HiloReportImportService(db);
  });
  tearDown(() => db.close());

  const pages = [
    'SBP DBP HR\n1 Oktober, 26 08:00 130 80 60\n1 Oktober, 26 09:00 128 78 58',
    'SBP DBP HR\n2 Oktober, 26 08:00 126 76 56',
  ];

  test('imports readings once and marks them as report data', () async {
    final preview = await service.previewPages(pages);
    expect(preview.newReadings, 3);
    expect(preview.alreadyStored, 0);
    expect(await service.import(preview), 3);

    final stored = await db.getBpInRange(
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 3),
    );
    expect(stored, hasLength(3));
    expect(
      stored.every(
        (r) => r.measurementType == HiloReportImportService.measurementType,
      ),
      isTrue,
    );

    final again = await service.previewPages(pages);
    expect(again.newReadings, 0);
    expect(again.alreadyStored, 3);
    expect(await service.import(again), 0);
  });

  test(
    'does not duplicate readings that arrived from another source',
    () async {
      await db.insertBpMeasurements([
        BpMeasurementsCompanion.insert(
          measuredAt: DateTime(2026, 10, 1, 8, 0, 25),
          systolic: 130,
          diastolic: 80,
          heartRate: 60,
        ),
      ]);
      final preview = await service.previewPages(pages);
      expect(preview.alreadyStored, 1);
      expect(preview.newReadings, 2);
    },
  );
}
