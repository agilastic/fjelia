import 'dart:io';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/strength/strength_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema 72 gains the pinned exercise notes', () async {
    final dir = await Directory.systemTemp.createTemp('fjelia-pinned-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final old = AppDatabase(NativeDatabase(file));
    await old.customStatement('DROP TABLE strength_exercise_notes');
    await old.customStatement('PRAGMA user_version = 72');
    await old.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final repo = StrengthRepository(db);
    await repo.setExerciseNote('bench_press', 'Squeeze the lats.');
    expect(await repo.exerciseNotes(), {'bench_press': 'Squeeze the lats.'});
  });
}
