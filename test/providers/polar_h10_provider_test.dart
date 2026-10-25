import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/polar_h10_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a paired strap is remembered until it is forgotten', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final actions = container.read(polarH10ActionsProvider);

    expect(await actions.paired(), isNull);
    expect(await container.read(polarH10PairedProvider.future), isNull);

    await actions.pair(const H10Device('AA:BB', 'Polar H10 1234ABCD', -50));
    final paired = await actions.paired();
    expect(paired?.id, 'AA:BB');
    expect(paired?.name, 'Polar H10 1234ABCD');
    expect(
      (await container.read(polarH10PairedProvider.future))?.name,
      'Polar H10 1234ABCD',
    );

    await actions.unpair();
    expect(await actions.paired(), isNull);
    expect(await container.read(polarH10PairedProvider.future), isNull);
  });
}
