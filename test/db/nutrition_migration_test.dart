import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/nutrition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'schema 50 gains nutrition storage without losing existing activities',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'fjelia-nutrition-migration-',
      );
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/db.sqlite');
      final before = AppDatabase(NativeDatabase(file));
      await before
          .into(before.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'existing',
              name: 'Ride',
              type: 'cycling',
              startDate: DateTime(2026, 10, 28),
              durationSeconds: 3600,
            ),
          );
      await before.customStatement('DROP TABLE nutrition_records');
      await before.customStatement('DROP TABLE nutrition_reminder_records');
      await before.customStatement('PRAGMA user_version = 50');
      await before.close();
      final after = AppDatabase(NativeDatabase(file));
      addTearDown(after.close);
      expect(
        (await after.select(after.activityRecords).getSingle()).activityId,
        'existing',
      );
      expect(await after.select(after.nutritionReminderRecords).get(), isEmpty);
      expect((await NutritionService(after).log('existing')).finished, isFalse);
    },
  );
  test('schema 53 gains the scheduled reminder text', () async {
    final dir = await Directory.systemTemp.createTemp(
      'fjelia-nutrition-migration-',
    );
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final before = AppDatabase(NativeDatabase(file));
    await before.customStatement(
      'ALTER TABLE nutrition_reminder_records DROP COLUMN scheduled_text',
    );
    await before.customStatement('PRAGMA user_version = 53');
    await before.close();
    final after = AppDatabase(NativeDatabase(file));
    addTearDown(after.close);
    await after
        .into(after.nutritionReminderRecords)
        .insert(
          NutritionReminderRecordsCompanion.insert(
            activityId: 'a',
            token: 't',
            notificationId: 7100000,
            dueAt: DateTime(2026, 10, 31),
            state: 'scheduled',
            scheduledText: const Value('x'),
          ),
        );
    expect(
      (await after.select(after.nutritionReminderRecords).getSingle())
          .scheduledText,
      'x',
    );
  });
}
