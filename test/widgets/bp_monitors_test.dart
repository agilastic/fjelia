import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/bp_monitor_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/omron_ble_provider.dart';
import 'package:fjelia/services/bp_monitor_registry.dart';
import 'package:fjelia/services/omron_ble_service.dart';
import 'package:fjelia/widgets/bp_monitors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A monitor without Bluetooth: what was asked and what it returns.
class _FakeOmron extends OmronBleService {
  _FakeOmron({this.devices = const []});
  final List<OmronFoundDevice> devices;
  final reads = <({String deviceId, String? model})>[];

  @override
  Future<List<OmronFoundDevice>> scan() async => devices;

  @override
  Future<String?> pairedModel(String deviceId) async => null;

  @override
  Future<bool> needsPairing(String deviceId, String model) async => false;

  @override
  Future<List<OmronBpRecord>> readRecords({
    required String deviceId,
    String? model,
    required bool authorizeFirstPairing,
    void Function(String status)? onStatus,
  }) async {
    reads.add((deviceId: deviceId, model: model));
    return [
      OmronBpRecord(
        measuredAt: DateTime(2026, 11, 16, 7),
        systolic: 124,
        diastolic: 78,
        heartRate: 58,
      ),
    ];
  }
}

const _standard = OmronFoundDevice('AA:BB', 'BP Monitor', -55, [
  '00001810-0000-1000-8000-00805f9b34fb',
]);

const _hilo = BpMonitor(kind: 'hilo', id: 'hilo', name: 'AKTIIA C1');
const _omron = BpMonitor(
  kind: 'memory',
  id: '11:22',
  name: 'BLESmart_0000',
  model: 'HEM-7600T',
);

void main() {
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> pump(
    WidgetTester tester,
    Widget sheet,
    _FakeOmron fake, {
    List<BpMonitor>? monitors,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          omronBleServiceProvider.overrideWithValue(fake),
          if (monitors != null)
            bpMonitorsProvider.overrideWith((ref) async => monitors),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: sheet),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('several monitors: the athlete picks one, then it is read', (
    tester,
  ) async {
    final fake = _FakeOmron();
    await pump(
      tester,
      const BpMeasureSheet(),
      fake,
      monitors: const [_hilo, _omron],
    );
    expect(find.text('WHICH MONITOR DO YOU MEASURE WITH?'), findsOneWidget);
    expect(find.text('AKTIIA C1'), findsOneWidget);
    await tester.tap(find.text('BLESmart_0000'));
    await tester.pumpAndSettle();
    // Straight to reading, with the saved model: no search, no model choice.
    expect(fake.reads.single, (deviceId: '11:22', model: 'HEM-7600T'));
    expect(find.text('Search BLE blood-pressure monitors'), findsNothing);
  });

  testWidgets('one monitor goes straight to its measurement', (tester) async {
    final fake = _FakeOmron();
    await pump(tester, const BpMeasureSheet(), fake, monitors: const [_omron]);
    expect(find.text('WHICH MONITOR DO YOU MEASURE WITH?'), findsNothing);
    expect(fake.reads, hasLength(1));
  });

  testWidgets('without a monitor the sheet leads to adding one', (
    tester,
  ) async {
    await pump(tester, const BpMeasureSheet(), _FakeOmron(), monitors: []);
    expect(find.text('Add monitor'), findsOneWidget);
  });

  testWidgets('a standard monitor is found, chosen and saved', (tester) async {
    await pump(
      tester,
      const AddBpMonitorSheet(),
      _FakeOmron(devices: [_standard]),
    );
    await tester.tap(find.byKey(const ValueKey('bp-monitor-search')));
    await tester.pumpAndSettle();
    expect(find.text('BP Monitor'), findsOneWidget);
    // A device with the standard service selects the standard profile.
    expect(
      find.text('Standard Bluetooth blood-pressure monitor'),
      findsWidgets,
    );
    await tester.tap(find.byKey(const ValueKey('bp-monitor-save')));
    await tester.pumpAndSettle();
    final saved = await const BpMonitorStore().list();
    expect(saved.single.id, 'AA:BB');
    expect(saved.single.model, standardBpModel);
  });

  test('the store replaces a monitor by id and removes it', () async {
    const store = BpMonitorStore();
    await store.save(_omron);
    await store.save(
      const BpMonitor(kind: 'memory', id: '11:22', name: 'Renamed'),
    );
    expect((await store.list()).single.name, 'Renamed');
    await store.remove('11:22');
    expect(await store.list(), isEmpty);
  });
}
