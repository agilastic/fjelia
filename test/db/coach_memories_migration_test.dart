import 'dart:io';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema 64 gains the coach memory cards', () async {
    final dir = await Directory.systemTemp.createTemp('fjelia-memories-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final old = AppDatabase(NativeDatabase(file));
    await old.customStatement('DROP TABLE coach_memories');
    await old.customStatement('PRAGMA user_version = 64');
    await old.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    await db.saveCoachMemory(
      CoachMemory(
        id: 'm',
        title: 'Left knee',
        body: 'Downhill hurts.',
        createdAt: DateTime(2026, 11, 9),
        updatedAt: DateTime(2026, 11, 9),
      ),
    );
    expect((await db.coachMemoryList()).single.title, 'Left knee');
  });
}
