import 'dart:developer';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';

/// Deletes everything Fjelia keeps on this phone, as after a new install:
/// every database row, the photos, videos and caches, the settings and the
/// stored logins and keys, and the scheduled notifications. Kept: the
/// downloaded on-device AI models (gigabytes, no personal data). Apple
/// Health and the connected services keep their own copies.
class DataWipeService {
  DataWipeService(
    this.db, {
    this.documents,
    this.support,
    this.temporary,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final AppDatabase db;

  /// The app's folders; the platform's unless given (tests).
  final Directory? documents, support, temporary;
  final FlutterSecureStorage _storage;

  /// The open database's files in the documents folder: emptied by SQL,
  /// never deleted under the running app.
  static bool _isDatabase(String name) => name.startsWith('fjelia_db.sqlite');

  /// The on-device models in the support folder.
  static const _models = 'local_models';

  Future<void> wipe() async {
    await db.transaction(() async {
      for (final table in db.allTables) {
        await db.customStatement('DELETE FROM "${table.actualTableName}"');
      }
      db.markTablesUpdated(db.allTables);
    });
    // Free the deleted pages, so the data is not left in the file.
    await db.customStatement('VACUUM');

    Future<void> empty(Directory dir, bool Function(String) keep) async {
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (keep(p.basename(entity.path))) continue;
        try {
          await entity.delete(recursive: true);
        } catch (e) {
          log('[Wipe] could not delete ${entity.path}: $e');
        }
      }
    }

    await empty(
      documents ?? await getApplicationDocumentsDirectory(),
      _isDatabase,
    );
    await empty(
      support ?? await getApplicationSupportDirectory(),
      (name) => name == _models || _isDatabase(name),
    );
    await empty(temporary ?? await getTemporaryDirectory(), (_) => false);

    await _storage.deleteAll();
    await (await SharedPreferences.getInstance()).clear();
    try {
      await fln.FlutterLocalNotificationsPlugin().cancelAll();
    } catch (e) {
      log('[Wipe] notifications not cancelled: $e');
    }
    log('[Wipe] all local data deleted');
  }
}
