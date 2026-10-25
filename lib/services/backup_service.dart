import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import '../models/backup_restore.dart';
import '../utils/log.dart';

// Decompression and JSON parsing must not block the progress indicator.
Map<String, dynamic> _decodeBackup(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final json = archive.findFile('backup.json');
  if (json != null) {
    return {'payload': jsonDecode(utf8.decode(json.content as List<int>))};
  }
  final sqlite = archive.findFile('alzora_db.sqlite');
  final settings = archive.findFile('fjelia_settings.json');
  if (sqlite == null || settings == null) {
    throw const FormatException('This ZIP is not a supported Fjelia backup.');
  }
  return {
    'sqlite': sqlite.content as List<int>,
    'settings': jsonDecode(utf8.decode(settings.content as List<int>)),
  };
}

/// Portable data/settings backup. Credentials and provider API keys are excluded.
/// Oldest backup schema that restores into the current database.
const _oldestRestorableSchema = 44;

/// Tables added after the oldest restorable schema, with the schema that
/// added them. A backup older than that has no such table, and none is owed.
const _tableAddedIn = {
  'plan_goals': 47,
  'provider_cleanups': 48,
  'workout_deliveries': 48,
};

class BackupService {
  BackupService(this.db);
  final AppDatabase db;
  static const _storage = FlutterSecureStorage();
  static bool _include(String key) =>
      key == 'user_profile_v1' ||
      key.startsWith('custom_hr_zones_') ||
      key == 'source_priority_v3' ||
      key.startsWith('visibility_') ||
      key == 'ai_coach_enabled' ||
      key == 'ai_coach_provider' ||
      key == 'ai_coach_model' ||
      key == 'ai_coach_briefing_mode';
  Future<File> export({Directory? directory}) async {
    final tables = <String, Object?>{};
    await db.transaction(() async {
      for (final table in db.allTables) {
        final name = table.actualTableName;
        tables[name] = (await db.customSelect('SELECT * FROM "$name"').get())
            .map((r) => r.data)
            .toList();
      }
    });
    final settings = {
      for (final e in (await _storage.readAll()).entries)
        if (_include(e.key)) e.key: e.value,
    };
    final prefs = await SharedPreferences.getInstance();
    final preferences = {
      for (final key in prefs.getKeys())
        if (key == 'plan_default_view' ||
            key.startsWith('visible_') ||
            key.startsWith('heat_acclimation_') ||
            key.endsWith('_write_health_enabled'))
          key: prefs.get(key),
    };
    final content = utf8.encode(
      jsonEncode({
        'format': 'fjelia-backup',
        'version': 1,
        'schema': db.schemaVersion,
        'tables': tables,
        'settings': settings,
        'preferences': preferences,
      }),
    );
    final zip = ZipEncoder().encode(
      Archive()..addFile(ArchiveFile('backup.json', content.length, content)),
    );
    final dir = directory ?? await getTemporaryDirectory();
    return File(
      '${dir.path}/fjelia_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
    ).writeAsBytes(zip);
  }

  Future<BackupRestoreResult> restore(
    List<int> bytes, {
    void Function(BackupRestoreProgress)? onProgress,
  }) async {
    onProgress?.call(const BackupRestoreProgress('Opening backup ZIP', 0.02));
    final decoded = await compute(_decodeBackup, bytes);
    AppDatabase? source;
    Directory? temporary;
    try {
      Map<String, dynamic> payload;
      if (decoded.containsKey('sqlite')) {
        onProgress?.call(
          const BackupRestoreProgress('Migrating original app backup', 0.08),
        );
        temporary = await Directory.systemTemp.createTemp('fjelia-restore-');
        final file = File('${temporary.path}/original.sqlite');
        await file.writeAsBytes(decoded['sqlite'] as List<int>);
        source = AppDatabase(NativeDatabase.createInBackground(file));
        // Opening a private copy applies the normal database migrations. Never
        // replace the live database file while its connection is open.
        final check = await source.customSelect('PRAGMA integrity_check').get();
        if (check.length != 1 || check.single.data.values.single != 'ok') {
          throw const FormatException('The backup database is damaged.');
        }
        final actual =
            (await source
                    .customSelect(
                      "SELECT name FROM sqlite_master WHERE type = 'table'",
                    )
                    .get())
                .map((r) => r.read<String>('name'))
                .toSet();
        final expected = db.allTables.map((t) => t.actualTableName).toSet();
        if (!actual.containsAll(expected)) {
          throw const FormatException(
            'The original backup is missing required tables.',
          );
        }
        payload = {
          'format': 'fjelia-backup',
          'version': 1,
          'schema': db.schemaVersion,
          'settings': decoded['settings'],
        };
      } else {
        payload = Map<String, dynamic>.from(decoded['payload'] as Map);
      }
      return await _restorePayload(
        payload,
        source: source,
        onProgress: onProgress,
      );
    } finally {
      await source?.close();
      if (temporary != null) await temporary.delete(recursive: true);
    }
  }

  Future<BackupRestoreResult> _restorePayload(
    Map<String, dynamic> payload, {
    AppDatabase? source,
    void Function(BackupRestoreProgress)? onProgress,
  }) async {
    // A backup from the previous schema restores: the later versions only
    // added columns, which an older row simply leaves empty. Anything older
    // or newer than that is refused.
    final schema = payload['schema'];
    if (payload['format'] != 'fjelia-backup' ||
        payload['version'] != 1 ||
        schema is! int ||
        schema < _oldestRestorableSchema ||
        schema > db.schemaVersion) {
      throw const FormatException(
        'Backup format or database version does not match.',
      );
    }
    final raw = payload['tables'];
    if (source == null && raw is! Map) {
      throw const FormatException('Invalid backup data.');
    }
    final names = db.allTables.map((t) => t.actualTableName).toSet();
    if (source == null &&
        ((raw as Map).keys.toSet().difference(names).isNotEmpty ||
            names
                .difference(raw.keys.cast<String>().toSet())
                .where((n) => (_tableAddedIn[n] ?? 0) <= schema)
                .isNotEmpty)) {
      throw const FormatException('Backup tables do not match.');
    }
    final settings = Map<String, dynamic>.from(payload['settings'] as Map);
    final preferences = Map<String, dynamic>.from(
      payload['preferences'] as Map? ?? {},
    );
    final counts = <String, int>{};
    for (final name in names) {
      counts[name] = source != null
          ? (await source
                    .customSelect('SELECT COUNT(*) AS n FROM "$name"')
                    .getSingle())
                .read<int>('n')
          : (((raw as Map)[name] as List?)?.length ?? 0);
    }
    final total = counts.values.fold(0, (a, b) => a + b);
    var completed = 0;
    log(
      '[Backup] restore validated: ${counts['activity_records']} activities, '
      '${counts['training_sessions']} planned sessions, $total records',
    );
    onProgress?.call(
      BackupRestoreProgress('Restoring records', 0.15, total: total),
    );
    await db.transaction(() async {
      for (final name in names) {
        await db.customStatement('DELETE FROM "$name"');
      }
      for (final name in names) {
        final columns =
            (await db.customSelect('PRAGMA table_info("$name")').get())
                .map((r) => r.read<String>('name'))
                .toSet();
        for (var offset = 0; offset < counts[name]!; offset += 100) {
          final rows = source != null
              ? (await source
                        .customSelect(
                          'SELECT * FROM "$name" LIMIT 100 OFFSET $offset',
                        )
                        .get())
                    .map((r) => r.data)
                    .toList()
              : ((raw as Map)[name] as List).skip(offset).take(100).toList();
          for (final row in rows) {
            final values = Map<String, dynamic>.from(row as Map);
            if (values.isEmpty ||
                values.keys.any((k) => !columns.contains(k))) {
              throw const FormatException('Invalid backup columns.');
            }
            final cols = values.keys.map((k) => '"$k"').join(',');
            await db.customStatement(
              'INSERT INTO "$name" ($cols) VALUES (${List.filled(values.length, '?').join(',')})',
              values.values.toList(),
            );
            completed++;
          }
          onProgress?.call(
            BackupRestoreProgress(
              'Restoring ${name.replaceAll('_', ' ')}',
              0.15 + 0.75 * (total == 0 ? 1 : completed / total),
              completed: completed,
              total: total,
            ),
          );
          // Allow frames to paint between batches, even with a local executor.
          await Future<void>.delayed(Duration.zero);
        }
      }
      // Raw SQL bypasses Drift's automatic table notifications. Publish these
      // updates as part of the transaction so open views see committed data.
      db.markTablesUpdated(db.allTables);
    });
    onProgress?.call(
      BackupRestoreProgress(
        'Restoring settings',
        0.93,
        completed: completed,
        total: total,
      ),
    );
    for (final e in settings.entries) {
      if (_include(e.key) && e.value is String) {
        await _storage.write(key: e.key, value: e.value as String);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    for (final e in preferences.entries) {
      if (!(e.key == 'plan_default_view' ||
          e.key.startsWith('visible_') ||
          e.key.startsWith('heat_acclimation_') ||
          e.key.endsWith('_write_health_enabled'))) {
        continue;
      }
      final v = e.value;
      if (v is bool) {
        await prefs.setBool(e.key, v);
      } else if (v is double) {
        await prefs.setDouble(e.key, v);
      } else if (v is int) {
        await prefs.setInt(e.key, v);
      } else if (v is String) {
        await prefs.setString(e.key, v);
      }
    }
    log(
      '[Backup] restore complete: ${counts['activity_records']} activities, '
      '${counts['training_sessions']} planned sessions',
    );
    onProgress?.call(
      BackupRestoreProgress(
        'Restore complete',
        1,
        completed: completed,
        total: total,
      ),
    );
    return BackupRestoreResult(Map.unmodifiable(counts));
  }
}
