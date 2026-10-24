import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/daily_readiness_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> load(DateTime day, double strain) => db
      .into(db.dayScoreRecords)
      .insert(
        DayScoreRecordsCompanion.insert(date: day, strainScore: Value(strain)),
        mode: InsertMode.insertOrReplace,
      );

  test(
    'form at a past date does not see the load that came after it',
    () async {
      // Easy days, then a very hard stretch long after the date asked about.
      for (var d = 0; d < 20; d++) {
        await load(DateTime(2026, 8, 1 + d), 40);
      }
      final before = await DailyReadinessService(
        db,
      ).tsbAsOf(DateTime(2026, 8, 21));
      for (var d = 0; d < 30; d++) {
        await load(DateTime(2026, 8, 21 + d), 300);
      }
      final after = await DailyReadinessService(
        db,
      ).tsbAsOf(DateTime(2026, 8, 21));
      expect(after, before);
      // Later in the hard stretch the form is clearly lower.
      final later = await DailyReadinessService(
        db,
      ).tsbAsOf(DateTime(2026, 9, 15));
      expect(later, lessThan(before!));
    },
  );
}
