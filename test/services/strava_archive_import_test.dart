import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/media_service.dart';
import 'package:fjelia/services/strava_archive_import.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/strava_archive_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('strava_test');
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  String archive() => writeStravaArchive(dir);

  Future<void> seed() async {
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'garmin_ride',
            name: 'Morning Ride',
            type: 'cycling',
            startDate: DateTime.utc(2026, 11, 1, 8),
            durationSeconds: 3590,
            source: const Value('garmin_api'),
          ),
        );
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'strava_333',
            name: 'Lauf',
            type: 'running',
            startDate: DateTime.utc(2026, 10, 30, 7),
            durationSeconds: 1800,
            source: const Value('strava'),
          ),
        );
    await db.deleteActivityByUser('strava_333');
  }

  test('dates, CSV quoting and sport names', () {
    expect(
      parseStravaDate('03.11.2026, 17:44:51'),
      DateTime.utc(2026, 11, 3, 17, 44, 51),
    );
    expect(
      parseStravaDate('Nov 3, 2026, 5:44:51 PM'),
      DateTime.utc(2026, 11, 3, 17, 44, 51),
    );
    expect(parseStravaDate('01.01.1970, 00:00:00'), isNull);
    expect(parseCsv('a,"b, ""c""\nd",e\n1,2,3'), [
      ['a', 'b, "c"\nd', 'e'],
      ['1', '2', '3'],
    ]);
    expect(stravaType('Virtuelle Radfahrt'), 'virtual_ride');
    expect(stravaType('Weight Training'), 'strength_training');
    expect(stravaType('Wandern'), 'hiking');
  });

  test(
    'preview, import, photos, duplicates, deletions and a second run',
    () async {
      await seed();
      final media = MediaService(db, root: Directory('${dir.path}/app'));
      final importer = StravaArchiveImporter(db, media);
      final a = StravaArchive.open(archive())!;
      addTearDown(a.close);
      expect(a.rows, hasLength(4));
      expect(a.rows.first.name, 'Abendrunde, "kurz"');
      expect(a.rows.first.description, 'zwei\nZeilen');

      final preview = await importer.preview(a);
      expect(preview.activities, 4);
      expect(preview.photos, 3);
      // The Garmin ride, and 444, which has the same recording as 111.
      expect(preview.duplicates, 2);
      expect(preview.toImport, 1);
      expect(preview.deleted, 1);

      final done = await importer.run(a);
      expect(done.errors, isEmpty);
      expect(done.complete, isTrue);
      // 111 is new; 444 has the same recording as 111 once its date comes from
      // the file, so it is a duplicate.
      expect(done.imported, 1);
      expect(done.duplicates, 2);
      expect(done.deleted, 1);
      expect(done.photos, 3);

      final walk = (await db.getActivityById('strava_111'))!;
      expect(walk.source, 'strava');
      expect(walk.type, 'walking');
      expect(walk.durationSeconds, 120);
      expect(walk.movingDurationSeconds, 110);
      expect(walk.avgHeartRate, 140);
      expect(walk.metricsJson, contains('"hr"'));
      expect(walk.gpxJson, isNotNull);
      expect(walk.description, 'zwei\nZeilen');
      expect(walk.calories, 136);
      expect(walk.maxSpeedMps, 3.85);
      expect(
        await media.list(const MediaOwner.activity('strava_111')),
        hasLength(2),
      );
      // The Garmin ride stays as it is and gets its Strava photo.
      expect(await db.getActivityById('strava_222'), isNull);
      expect(
        await media.list(const MediaOwner.activity('garmin_ride')),
        hasLength(1),
      );
      // Deleted stays deleted.
      expect(await db.getActivityById('strava_333'), isNull);

      // An earlier import without calories gets them; nothing else changes.
      await (db.update(db.activityRecords)
            ..where((t) => t.activityId.equals('strava_111')))
          .write(const ActivityRecordsCompanion(calories: Value(null)));

      // Safe to run again: nothing new, no photo twice.
      final again = await importer.run(a);
      expect((await db.getActivityById('strava_111'))!.calories, 136);
      expect(again.imported, 0);
      expect(again.photos, 0);
      expect(await db.select(db.mediaItems).get(), hasLength(3));
    },
  );

  test('a ZIP without activities.csv is not a Strava archive', () {
    final path = '${dir.path}/other.zip';
    File(path).writeAsBytesSync(
      ZipEncoder().encodeBytes(
        Archive()..addFile(ArchiveFile.string('x.txt', 'x')),
      ),
    );
    expect(StravaArchive.open(path), isNull);
  });
}
