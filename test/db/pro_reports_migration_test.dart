import 'dart:io';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema 65 gains the Pro analyses', () async {
    final dir = await Directory.systemTemp.createTemp('fjelia-pro-reports-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final old = AppDatabase(NativeDatabase(file));
    await old.customStatement('DROP TABLE pro_reports');
    await old.customStatement('PRAGMA user_version = 65');
    await old.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    await db.saveProReport(
      ProReport(
        id: 'planCheck:2026-11-09',
        kind: 'planCheck',
        refKey: '2026-11-09',
        body: 'As planned.',
        model: 'ProAI-deep',
        createdAt: DateTime(2026, 11, 9, 7),
      ),
    );
    expect(
      (await db.watchProReport('planCheck:2026-11-09').first)!.body,
      'As planned.',
    );
  });
}
