import 'dart:io';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/workout_providers/delivery_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'schema 49 deliveries retain their records when remote ids are added',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'fjelia-delivery-migration-',
      );
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/db.sqlite');
      final old = AppDatabase(NativeDatabase(file));
      await DeliveryLedger(old, 'garmin').put(
        'existing',
        fingerprint: 'before',
        day: '20261028',
        name: 'Easy run',
      );
      await old.customStatement(
        'ALTER TABLE workout_deliveries DROP COLUMN remote_id',
      );
      await old.customStatement('PRAGMA user_version = 49');
      await old.close();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final before = await DeliveryLedger(db, 'garmin').get('existing');
      expect(before!.fingerprint, 'before');
      expect(before.remoteId, isNull);
      expect(before.name, 'Easy run');
      await DeliveryLedger(db, 'polar').put('new', remoteId: '12345');
      expect((await DeliveryLedger(db, 'polar').get('new'))!.remoteId, '12345');
    },
  );
}
