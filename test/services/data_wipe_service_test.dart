import 'dart:io';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/data_wipe_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('deletes every row, file, setting and login; keeps the open '
      'database file and the AI models', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final root = await Directory.systemTemp.createTemp('wipe');
    addTearDown(() => root.delete(recursive: true));
    final documents = await Directory('${root.path}/doc').create();
    final support = await Directory('${root.path}/sup').create();
    final temporary = await Directory('${root.path}/tmp').create();
    File('${documents.path}/fjelia_db.sqlite').writeAsStringSync('db');
    File('${documents.path}/fjelia_db.sqlite-wal').writeAsStringSync('db');
    File('${documents.path}/export.fit').writeAsStringSync('x');
    await Directory('${support.path}/media').create();
    File('${support.path}/media/photo.jpg').writeAsStringSync('x');
    await Directory('${support.path}/local_models/qwen')
        .create(recursive: true);
    File('${temporary.path}/backup.zip').writeAsStringSync('x');

    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'a',
            name: 'Run',
            type: 'running',
            startDate: DateTime(2026, 11, 24, 7),
            durationSeconds: 3600,
          ),
        );
    FlutterSecureStorage.setMockInitialValues({
      'garmin_email': 'me@example.com',
      'setup_finished_v1': 'true',
    });
    SharedPreferences.setMockInitialValues({'home_sky_v1': false});

    await DataWipeService(
      db,
      documents: documents,
      support: support,
      temporary: temporary,
    ).wipe();

    expect(await db.select(db.activityRecords).get(), isEmpty);
    expect(documents.listSync().map((e) => p.basename(e.path)).toSet(), {
      'fjelia_db.sqlite',
      'fjelia_db.sqlite-wal',
    });
    expect(support.listSync().map((e) => p.basename(e.path)), ['local_models']);
    expect(temporary.listSync(), isEmpty);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
}
