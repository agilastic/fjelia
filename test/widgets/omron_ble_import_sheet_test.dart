import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/omron_ble_provider.dart';
import 'package:fjelia/services/omron_ble_service.dart';
import 'package:fjelia/widgets/omron_ble_import_sheet.dart';

/// A monitor without Bluetooth: what the sheet asked and what it returns.
class _FakeOmron extends OmronBleService {
  _FakeOmron({this.devices = const [], this.records = const [], this.paired});
  final List<OmronFoundDevice> devices;
  final List<OmronBpRecord> records;
  final String? paired;
  final reads = <({String deviceId, String? model, bool authorized})>[];
  Object? failRead;

  @override
  Future<List<OmronFoundDevice>> scan() async => devices;

  @override
  Future<String?> pairedModel(String deviceId) async => paired;

  @override
  Future<bool> needsPairing(String deviceId, String model) async =>
      model != standardBpModel && paired == null;

  @override
  Future<List<OmronBpRecord>> readRecords({
    required String deviceId,
    String? model,
    required bool authorizeFirstPairing,
    void Function(String status)? onStatus,
  }) async {
    reads.add((
      deviceId: deviceId,
      model: model,
      authorized: authorizeFirstPairing,
    ));
    if (failRead != null) throw failRead!;
    onStatus?.call('Reading stored measurements…');
    return records;
  }
}

const _standard = OmronFoundDevice('AA:BB:CC:DD', 'BP Monitor', -55, [
  '00001810-0000-1000-8000-00805f9b34fb',
]);
const _omron = OmronFoundDevice('11:22:33:44', 'BLESmart_0000', -60, [
  'ecbe3980-c9a2-11e1-b1bd-0002a5d5c51b',
]);

OmronBpRecord _reading(int day, int sys, {int user = 1}) => OmronBpRecord(
  measuredAt: DateTime(2026, 11, day, 7, 30),
  systolic: sys,
  diastolic: 80,
  heartRate: 60,
  user: user,
);

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, _FakeOmron fake) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          omronBleServiceProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: OmronBleImportSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, Pattern text) async {
    final finder = text is String
        ? find.text(text)
        : find.textContaining(text as RegExp);
    // The sheet's list builds lazily: scroll rows into existence first.
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  Future<List<BpMeasurement>> stored(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.bpMeasurements).get()))!;

  testWidgets('scan, read and import only the chosen readings', (tester) async {
    final fake = _FakeOmron(
      devices: [_standard],
      records: [_reading(10, 121), _reading(11, 135), _reading(12, 128)],
    );
    await pump(tester, fake);
    await tapText(tester, 'Search BLE blood-pressure monitors');
    // A device with the standard service selects the standard profile.
    expect(find.textContaining('BP Monitor'), findsOneWidget);
    await tapText(tester, 'Read measurements');
    expect(fake.reads.single.model, standardBpModel);
    expect(
      find.text('3 readings found. Choose which ones to import.'),
      findsOneWidget,
    );

    // Leave out the middle reading.
    await tapText(tester, '135/80 mmHg  ·  60 bpm');
    await tapText(tester, 'Import 2 selected readings');

    final rows = await stored(tester);
    expect(rows.map((r) => r.systolic), [121, 128]);
    expect(rows.every((r) => r.measurementType == 'BLE_STANDARD'), isTrue);
    expect(find.text('2 new readings saved'), findsOneWidget);
    expect(find.text('LATEST READINGS'), findsOneWidget);
  });

  testWidgets('a first Omron pairing asks before anything is read', (
    tester,
  ) async {
    final fake = _FakeOmron(devices: [_omron], records: [_reading(10, 121)]);
    await pump(tester, fake);
    await tapText(tester, 'Search BLE blood-pressure monitors');

    // An Omron-protocol device needs its exact model.
    await tester.tap(find.text('Monitor model'));
    await tester.pumpAndSettle();
    await tapText(tester, 'HEM-7322T · M700 Intelli IT');
    await tapText(tester, 'Read measurements');
    expect(find.text('Pair this Omron monitor?'), findsOneWidget);

    await tapText(tester, 'Cancel');
    expect(fake.reads, isEmpty);

    await tapText(tester, 'Read measurements');
    await tapText(tester, 'Pair and import');
    expect(fake.reads.single, (
      deviceId: '11:22:33:44',
      model: 'HEM-7322T',
      authorized: true,
    ));
    await tapText(tester, 'Import 1 selected readings');
    expect((await stored(tester)).single.measurementType, 'OMRON');
  });

  testWidgets('a paired monitor comes back with its model', (tester) async {
    final fake = _FakeOmron(
      devices: [_omron],
      records: const [],
      paired: 'HEM-7322T',
    );
    await pump(tester, fake);
    await tapText(tester, 'Search BLE blood-pressure monitors');
    await tapText(tester, 'Read measurements');
    expect(find.text('Pair this Omron monitor?'), findsNothing);
    expect(fake.reads.single.model, 'HEM-7322T');
    expect(
      find.text('0 readings found. Choose which ones to import.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed read shows its reason and saves nothing', (
    tester,
  ) async {
    final fake = _FakeOmron(devices: [_standard])
      ..failRead = StateError('The monitor disconnected.');
    await pump(tester, fake);
    await tapText(tester, 'Search BLE blood-pressure monitors');
    await tapText(tester, 'Read measurements');
    expect(find.textContaining('The monitor disconnected.'), findsOneWidget);
    expect(await stored(tester), isEmpty);
  });

  testWidgets('no device found', (tester) async {
    await pump(tester, _FakeOmron());
    await tapText(tester, 'Search BLE blood-pressure monitors');
    expect(
      find.text('No BLE devices found. Turn on Bluetooth and the monitor.'),
      findsOneWidget,
    );
  });
}
