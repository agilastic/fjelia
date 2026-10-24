import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validates the rebuilt Drift schema against the database exported from the
/// device (iMazing backup). Works on a temp copy, never the original.
void main() {
  const deviceDb = '../fitfusion/Container/Documents/alzora_db.sqlite';

  test('v40 device database migrates to current schema', () async {
    final source = File(deviceDb);
    if (!source.existsSync()) {
      markTestSkipped('device database not available');
      return;
    }
    final copy = File(
      '${Directory.systemTemp.createTempSync().path}/db.sqlite',
    );
    source.copySync(copy.path);

    final db = AppDatabase(NativeDatabase(copy));
    addTearDown(db.close);

    expect(
      await db
          .customSelect('PRAGMA user_version')
          .getSingle()
          .then((r) => r.read<int>('user_version')),
      db.schemaVersion,
    );
    // Columns added via raw ALTER TABLE (v38-v40 migrations) carry no explicit
    // NULL constraint on device; that is the only accepted difference.
    try {
      await db.validateDatabaseSchema();
    } on SchemaMismatch catch (e) {
      final diffs = RegExp(r'([a-z_0-9]+):\s*\n\s*Not equal')
          .allMatches(e.toString())
          .map((m) => m.group(1))
          .toSet();
      expect(diffs, {
        'vo2max_cycling',
        'moving_duration_seconds',
        'ftp_watts',
      }, reason: e.toString());
    }
    expect(await db.getActivityCount(), greaterThan(0));
  });
}
