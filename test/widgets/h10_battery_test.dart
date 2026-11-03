import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/polar_h10_provider.dart';
import 'package:fjelia/widgets/h10_battery.dart';

class _Actions extends PolarH10Actions {
  _Actions(super.ref, this.answer);
  final int? answer;
  int checks = 0;

  @override
  Future<int?> checkBattery() async {
    checks++;
    if (answer != null) await PolarH10Pairing.writeBattery(answer!);
    ref.invalidate(polarH10BatteryProvider);
    return answer;
  }
}

void main() {
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'polar_h10_id': 'AA:BB',
      'polar_h10_name': 'Polar H10 9F3A1B2C',
    }),
  );

  test(
    'the last reading is kept with its time and removed on unpair',
    () async {
      expect(await PolarH10Pairing.readBattery(), isNull);
      await PolarH10Pairing.writeBattery(80);
      final stored = (await PolarH10Pairing.readBattery())!;
      expect(stored.level, 80);
      expect(DateTime.now().difference(stored.at).inMinutes, 0);
      await PolarH10Pairing.clear();
      expect(await PolarH10Pairing.readBattery(), isNull);
    },
  );

  test('levels and the low warning', () {
    expect(h10BatteryIcon(100), Icons.battery_full);
    expect(h10BatteryIcon(45), Icons.battery_3_bar);
    expect(h10BatteryIcon(10), Icons.battery_alert);
    expect(h10BatteryColor(10), Colors.redAccent);
    expect(h10BatteryColor(30), Colors.amber);
  });

  Future<_Actions> pump(WidgetTester tester, int? answer) async {
    late _Actions actions;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          polarH10ActionsProvider.overrideWith(
            (ref) => actions = _Actions(ref, answer),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: PolarH10BatteryTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return actions;
  }

  testWidgets('Settings reads the battery on request and warns when low', (
    tester,
  ) async {
    final actions = await pump(tester, 15);
    expect(find.text('Battery not read yet'), findsOneWidget);
    await tester.tap(find.byTooltip('Check battery'));
    await tester.pumpAndSettle();
    expect(actions.checks, 1);
    expect(find.text('Battery 15 %'), findsOneWidget);
    expect(find.textContaining('CR2025'), findsOneWidget);
  });

  testWidgets('a strap that does not answer says how to wake it', (
    tester,
  ) async {
    await pump(tester, null);
    await tester.tap(find.byTooltip('Check battery'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Put it on'), findsOneWidget);
  });
}
