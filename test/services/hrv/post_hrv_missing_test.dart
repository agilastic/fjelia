import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/spot_hrv.dart';
import 'package:fjelia/services/hrv/hrv_training_service.dart';
import 'package:fjelia/services/hrv/post_hrv_missing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/hrv_db.dart';

void main() {
  late AppDatabase db;
  late HrvTrainingService training;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    training = HrvTrainingService(db, clock: () => atMin(150));
  });
  tearDown(() => db.close());

  Future<Set<String>> missing() => postHrvMissing(db, training, ['a1']);

  test('a pre reading without a post is owed', () async {
    await addActivity(db, 'a1', 0, 90);
    await addReading(db, -20, SpotHrvContext.beforeTraining);
    expect(await missing(), {'a1'});
  });

  test('a resting reading earlier that day is enough', () async {
    await addActivity(db, 'a1', 0, 90);
    await addReading(db, -60, SpotHrvContext.resting);
    expect(await missing(), {'a1'});
  });

  test('a post reading, even unpaired, settles it', () async {
    await addActivity(db, 'a1', 0, 90);
    await addReading(db, -20, SpotHrvContext.beforeTraining);
    await addReading(db, 110, SpotHrvContext.afterTraining);
    expect(await missing(), isEmpty);
  });

  test('no reading, or only one from the day before, owes nothing', () async {
    await addActivity(db, 'a1', 0, 90);
    expect(await missing(), isEmpty);
    await addReading(db, -24 * 60, SpotHrvContext.resting);
    expect(await missing(), isEmpty);
  });
}
