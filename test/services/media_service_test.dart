import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/backup_service.dart';
import 'package:fjelia/services/media_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late Directory root;
  late Directory picked;
  late MediaService media;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    root = await Directory.systemTemp.createTemp('fjelia-media-root');
    picked = await Directory.systemTemp.createTemp('fjelia-media-picked');
    media = MediaService(db, root: root);
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
    await picked.delete(recursive: true);
  });

  Future<String> pick(String name, [int size = 1000]) async {
    final file = File('${picked.path}/$name');
    await file.writeAsBytes(List.filled(size, 7));
    return file.path;
  }

  Future<TrainingSession> session(String id, DateTime day) async {
    await db
        .into(db.trainingSessions)
        .insert(
          TrainingSessionsCompanion.insert(
            id: id,
            planId: 'plan',
            athleteId: 'self',
            sessionDate: day,
            sessionNumber: 1,
            weekNumber: 1,
            sport: 'running',
            sessionType: 'base',
            phase: 'base',
            primaryZone: 2,
            title: 'Run',
            plannedDurationMin: 45,
            plannedTrimp: 40,
            sessionLevel: 1,
          ),
        );
    return (db.select(
      db.trainingSessions,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  test('adds photos and videos in order as copies', () async {
    const owner = MediaOwner.activity('garmin_1');
    final added = await media.add(owner, [
      await pick('a.jpg'),
      await pick('clip.MOV', 5000),
      await pick('b.heic'),
    ]);
    expect(added, 3);
    final items = await media.list(owner);
    expect(items.map((i) => i.kind), ['photo', 'video', 'photo']);
    expect(items.map((i) => i.position), [0, 1, 2]);
    expect(items[1].bytes, 5000);
    // Copies: the picked files may go, the media stay.
    await picked.delete(recursive: true);
    await picked.create();
    for (final item in items) {
      expect(await (await media.file(item.fileName)).exists(), isTrue);
    }
  });

  test('a file that cannot be read is skipped', () async {
    const owner = MediaOwner.activity('garmin_1');
    final added = await media.add(owner, [
      await pick('a.jpg'),
      '${picked.path}/missing.jpg',
    ]);
    expect(added, 1);
  });

  test('moving and deleting keep the order without gaps', () async {
    const owner = MediaOwner.raceGoal('goal');
    await media.add(owner, [
      await pick('1.jpg'),
      await pick('2.jpg'),
      await pick('3.jpg'),
    ]);
    var items = await media.list(owner);
    final third = items[2];
    await media.move(third, -2);
    items = await media.list(owner);
    expect(items.first.id, third.id);

    final file = await media.file(items[1].fileName);
    await media.delete(items[1]);
    items = await media.list(owner);
    expect(items.map((i) => i.position), [0, 1]);
    expect(await file.exists(), isFalse);

    await media.deleteAll(owner);
    expect(await media.list(owner), isEmpty);
  });

  test('media follow the session a new plan puts on the same day', () async {
    final day = DateTime(2026, 11, 10, 7);
    final old = await session('old', day);
    await media.add(MediaOwner.session(old), [await pick('route.jpg')]);
    await (db.delete(
      db.trainingSessions,
    )..where((t) => t.id.equals('old'))).go();

    // No session on that day yet: the media wait.
    expect(await media.reattachSessionMedia(), 0);

    final replacement = await session('new', day.add(const Duration(hours: 2)));
    expect(await media.reattachSessionMedia(), 1);
    expect(await media.list(MediaOwner.session(replacement)), hasLength(1));
  });

  test('media of a duplicate move to the copy that stays', () async {
    Future<void> activity(String id, String source) => db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: id,
            name: id,
            type: 'running',
            startDate: DateTime.utc(2026, 11, 2, 8),
            durationSeconds: 2280,
            source: Value(source),
          ),
        );
    await activity('hc_1', 'health_connect');
    await media.add(const MediaOwner.activity('hc_1'), [await pick('x.jpg')]);
    await activity('garmin_1', 'garmin_api');
    await db.deduplicateActivities();
    expect(
      await media.list(const MediaOwner.activity('garmin_1')),
      hasLength(1),
    );
  });

  test('backups carry the media files, videos only when asked', () async {
    const owner = MediaOwner.activity('garmin_1');
    await media.add(owner, [
      await pick('a.jpg', 300),
      await pick('c.mov', 900),
    ]);
    final backup = BackupService(db, mediaRoot: root);
    expect(await backup.videoSummary(), (count: 1, bytes: 900));

    final out = await Directory.systemTemp.createTemp('fjelia-media-backup');
    addTearDown(() => out.delete(recursive: true));
    final withVideos = await backup.export(directory: out);
    final names = ZipDecoder()
        .decodeBytes(await withVideos.readAsBytes())
        .files
        .map((f) => f.name)
        .toList();
    expect(names.where((n) => n.startsWith('media/')), hasLength(2));

    final withoutVideos = await backup.export(
      directory: out,
      includeVideos: false,
    );
    final photosOnly = ZipDecoder().decodeBytes(
      await withoutVideos.readAsBytes(),
    );
    expect(
      photosOnly.files.where((f) => f.name.startsWith('media/')),
      hasLength(1),
    );

    // Restore from disk: the data and the files come back, nothing else.
    await media.deleteAll(owner);
    await File('${root.path}/media/stray.jpg').writeAsBytes([1]);
    await backup.restoreFile(withVideos.path);
    final restored = await media.list(owner);
    expect(restored.map((i) => i.kind), ['photo', 'video']);
    for (final item in restored) {
      expect(await (await media.file(item.fileName)).length(), item.bytes);
    }
    expect(await File('${root.path}/media/stray.jpg').exists(), isFalse);
  });
}
