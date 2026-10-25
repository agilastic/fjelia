import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/auth_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/workout_providers_provider.dart';
import 'package:fjelia/providers/workout_push_provider.dart';
import 'package:fjelia/services/workout_providers/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_workout_garmin.dart';
import '../support/recording_workout_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('delete all finishes, every time, with nothing connected', () async {
    // Garmin stands in when no platform is connected, so work is still done.
    for (var i = 0; i < 5; i++) {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          garminClientProvider.overrideWithValue(FakeWorkoutGarmin()),
        ],
      );
      final seen = <String>[];
      final result = await container
          .read(deleteAllWorkoutsProvider)((d, t, l) => seen.add(l))
          .timeout(const Duration(seconds: 10));
      expect(result.removed.keys, ['garmin']);
      expect(
        seen,
        containsAllInOrder(['Deleting on this phone', 'On this phone']),
      );
      container.dispose();
    }
  });

  test('delete all asks each connected platform, by name', () async {
    final acme = RecordingProvider(db, 'acme');
    final off = RecordingProvider(db, 'off', label: 'Off', connected: false);
    await acme.ledger.put('s1', fingerprint: 'x');
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        workoutProvidersProvider.overrideWithValue(
          WorkoutProviders([acme, off]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final seen = <String>{};
    final result = await container
        .read(deleteAllWorkoutsProvider)((d, t, l) => seen.add(l))
        .timeout(const Duration(seconds: 10));
    expect(result.removed, {'acme': 1});
    expect(result.labels, {'acme': 'Acme'});
    expect(result.summary, 'Acme 1');
    expect(seen, contains('Acme'));
    expect(seen, isNot(contains('Off')));
    expect(off.removed, isEmpty);
  });
}
