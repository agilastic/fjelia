import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/health_metric.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/metric_history_provider.dart';
import 'package:fjelia/providers/user_profile_provider.dart';
import 'package:fjelia/providers/waist_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  WaistActions actions() => container.read(waistActionsProvider);
  Future<double?> profileWaist() async =>
      (await container.read(userProfileProvider.future)).waistCm;

  test('the newest measurement becomes the waist in Settings', () async {
    await actions().add(DateTime(2026, 11, 1, 7), 88, hipCm: 100);
    expect(await profileWaist(), 88);
    // An older one goes into the history, Settings keep the newest.
    await actions().add(DateTime(2026, 10, 1, 7), 90);
    expect(await profileWaist(), 88);
    final rows = await container.read(waistMeasurementsProvider.future);
    expect([for (final r in rows) r.waistCm], [90, 88]);
  });

  test('deleting the newest falls back to the one before', () async {
    await actions().add(DateTime(2026, 10, 1), 90);
    await actions().add(DateTime(2026, 11, 1), 88);
    final newest = (await db.getWaistMeasurements()).last;
    await actions().delete(newest.id);
    expect(await profileWaist(), 90);
  });

  test('a waist typed in Settings is one measurement of today', () async {
    for (final v in [85.0, 85.5, 86.0]) {
      await actions().fromProfile(v);
    }
    final rows = await db.getWaistMeasurements();
    expect(rows, hasLength(1));
    expect(rows.single.waistCm, 86);
    expect(rows.single.source, 'profile');
  });

  test('the chart keeps old scale readings before the first one', () async {
    await db.upsertRenphoMeasurements([
      RenphoRecordsCompanion.insert(
        measuredAt: DateTime(2026, 1, 1),
        waistCm: const Value(95),
        rawJson: '{}',
      ),
      RenphoRecordsCompanion.insert(
        measuredAt: DateTime(2026, 11, 2),
        waistCm: const Value(95),
        rawJson: '{}',
      ),
    ]);
    await actions().add(DateTime(2026, 6, 1), 90);
    final points = await container.read(
      metricHistoryProvider(HealthMetric.waist).future,
    );
    expect([for (final p in points) p.value], [95, 90]);
  });
}
