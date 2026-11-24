import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/hr_zones_provider.dart';
import 'package:fjelia/services/athlete_thresholds_service.dart';
import 'package:fjelia/services/hr_zone_history.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('device zones applied right after startup are not overwritten', () async {
    final c = container();
    // First access (as the first sync after app start does) and apply at once.
    final notifier = c.read(hrZonesProvider.notifier);
    await notifier.applyDeviceZones(
      running: [92, 110, 128, 146, 165],
      cycling: [112, 126, 139, 151, 166],
    );
    await notifier.loaded;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.read(hrZonesProvider).running.bounds, [92, 110, 128, 146, 165]);
    expect(c.read(hrZonesProvider).cycling.bounds, [112, 126, 139, 151, 166]);
  });

  test('stored zones are loaded on the next start', () async {
    final first = container();
    await first
        .read(hrZonesProvider.notifier)
        .applyDeviceZones(running: [92, 110, 128, 146, 165]);
    final second = container();
    await second.read(hrZonesProvider.notifier).loaded;
    expect(second.read(hrZonesProvider).running.bounds, [
      92,
      110,
      128,
      146,
      165,
    ]);
  });

  test('a sport without zones of its own follows running, lower; one with '
      'its own keeps them', () async {
    final c = container();
    final notifier = c.read(hrZonesProvider.notifier);
    await notifier.saveRunning(const HrZones([110, 130, 145, 155, 165]));
    expect(c.read(hrZonesProvider).cycling.bounds, [105, 125, 140, 150, 160]);
    expect(c.read(hrZonesProvider).swimming.bounds, [100, 120, 135, 145, 155]);
    await notifier.saveCycling(const HrZones([100, 120, 132, 142, 150]));
    await notifier.saveRunning(const HrZones([112, 132, 147, 157, 167]));
    expect(c.read(hrZonesProvider).cycling.bounds, [100, 120, 132, 142, 150]);
    expect(c.read(hrZonesProvider).swimming.bounds, [102, 122, 137, 147, 157]);
    // The plan reads the thresholds' copy of the zones in force today.
    final saved = await AthleteThresholdsService(db).get();
    expect(saved!.bikeHrZonesJson, '[100,120,132,142,150]');
    expect(saved.runHrZonesJson, '[112,132,147,157,167]');
  });

  test('an old workout keeps the zones of its day', () async {
    final c = container();
    final notifier = c.read(hrZonesProvider.notifier);
    await notifier.record(
      'running',
      const [110, 130, 145, 155, 165],
      method: ZoneMethod.initial,
      from: DateTime.fromMillisecondsSinceEpoch(0),
    );
    final test = DateTime.now().subtract(const Duration(days: 10));
    await notifier.applyLt1Ceiling(150, from: test);
    final state = c.read(hrZonesProvider);
    final before = test.subtract(const Duration(days: 1));
    expect(state.forActivity('running', before), [110, 130, 145, 155, 165]);
    expect(state.forActivity('running', DateTime.now()), [
      110,
      130,
      150,
      155,
      165,
    ]);
    // A ride before the test: the running zones of that day, lower.
    expect(state.forActivity('cycling', before), [105, 125, 140, 150, 160]);
    // Strength has no zones.
    expect(state.book.forActivity('strength_training', before), isNull);
  });

  test('older settings move into the history once; a disagreement is asked '
      'and the choice replaces the zones in force', () async {
    final history = HrZoneHistory(db);
    await history.record(
      'cycling',
      [110, 126, 139, 151, 166],
      method: ZoneMethod.initial,
      from: DateTime.fromMillisecondsSinceEpoch(0),
    );
    FlutterSecureStorage.setMockInitialValues({
      'custom_hr_zones_running': '[105,133,144,154,163]',
      'custom_hr_zones_cycling': '[93,122,132,142,149]',
      'hr_zones_cycling_from_device': '1',
    });
    final c = container();
    await c.read(hrZonesProvider.notifier).loaded;
    final state = c.read(hrZonesProvider);
    // No running history yet: the settings' zones became the first.
    expect(state.running.bounds, [105, 133, 144, 154, 163]);
    // Cycling disagreed: the history stays until the athlete chooses.
    expect(state.cycling.bounds, [110, 126, 139, 151, 166]);
    expect(state.conflicts, {
      'cycling': [93, 122, 132, 142, 149],
    });
    expect(
      await const FlutterSecureStorage().read(key: 'custom_hr_zones_cycling'),
      isNull,
    );

    await c.read(hrZonesProvider.notifier).resolveConflict('cycling', [
      93,
      122,
      132,
      142,
      149,
    ]);
    final after = c.read(hrZonesProvider);
    expect(after.conflicts, isEmpty);
    expect(after.cycling.bounds, [93, 122, 132, 142, 149]);
    // Also for the rides since the zones it replaced began.
    expect(after.forActivity('cycling', DateTime(2020)), [
      93,
      122,
      132,
      142,
      149,
    ]);
  });

  test('Karvonen as the first zones when nothing else is known', () async {
    for (var d = 1; d <= 5; d++) {
      await db
          .into(db.hrvRecords)
          .insert(
            HrvRecordsCompanion.insert(
              date: DateTime.now().subtract(Duration(days: d)),
            ).copyWith(restingHeartRate: const Value(48)),
          );
    }
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hrZonesProvider.overrideWith(
          // 44 years: Tanaka 208 - 0.7 * 44 = 177.
          (ref) => HrZonesNotifier(db, () async => 177),
        ),
      ],
    );
    addTearDown(c.dispose);
    await c.read(hrZonesProvider.notifier).loaded;
    final state = c.read(hrZonesProvider);
    // As kalcufy.com shows it for 44 years and a resting heart rate of 48.
    expect(state.running.bounds, [113, 125, 138, 151, 164]);
    expect(state.cycling.bounds, [108, 120, 133, 146, 159]);
    expect(state.book.latest('running')!.method, ZoneMethod.estimate);
  });
}
