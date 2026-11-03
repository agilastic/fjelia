import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/activity_file_import_service.dart';

import '../support/polar_fit_fixture.dart';

const _zones = [108, 137, 148, 158, 166];

const _gpx = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="StravaGPX"
  xmlns="http://www.topografix.com/GPX/1/1"
  xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1">
 <metadata><name>Evening Ride</name></metadata>
 <trk>
  <name>Evening Ride</name>
  <type>Ride</type>
  <trkseg>
   <trkpt lat="52.1000" lon="9.7000"><ele>50</ele><time>2026-10-30T16:00:00Z</time>
    <extensions><power>210</power><gpxtpx:TrackPointExtension><gpxtpx:hr>120</gpxtpx:hr><gpxtpx:cad>85</gpxtpx:cad></gpxtpx:TrackPointExtension></extensions></trkpt>
   <trkpt lat="52.1100" lon="9.7000"><ele>51</ele><time>2026-10-30T16:20:00Z</time>
    <extensions><power>230</power><gpxtpx:TrackPointExtension><gpxtpx:hr>140</gpxtpx:hr></gpxtpx:TrackPointExtension></extensions></trkpt>
   <trkpt lat="52.1200" lon="9.7000"><ele>60</ele><time>2026-10-30T16:40:00Z</time>
    <extensions><gpxtpx:TrackPointExtension><gpxtpx:hr>160</gpxtpx:hr></gpxtpx:TrackPointExtension></extensions></trkpt>
  </trkseg>
 </trk>
</gpx>''';

const _tcx = '''<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">
 <Activities>
  <Activity Sport="Running">
   <Id>2026-08-19T06:30:00.000Z</Id>
   <Lap StartTime="2026-08-19T06:30:00.000Z">
    <TotalTimeSeconds>1800.0</TotalTimeSeconds>
    <DistanceMeters>5000.0</DistanceMeters>
    <AverageHeartRateBpm><Value>140</Value></AverageHeartRateBpm>
    <Track>
     <Trackpoint><Time>2026-08-19T06:30:00.000Z</Time><HeartRateBpm><Value>120</Value></HeartRateBpm></Trackpoint>
     <Trackpoint><Time>2026-08-19T06:30:05.000Z</Time><HeartRateBpm><Value>130</Value></HeartRateBpm></Trackpoint>
    </Track>
   </Lap>
  </Activity>
 </Activities>
</TrainingCenterDatabase>''';

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

/// A run with a point every 5 s, enough for time in zone.
String _denseGpx() {
  final start = DateTime.utc(2026, 10, 29, 7);
  return '''<gpx xmlns="http://www.topografix.com/GPX/1/1"><trk><type>running</type><trkseg>
${[for (var i = 0; i < 12; i++) '<trkpt lat="${52 + i * 0.0001}" lon="9.7"><time>${start.add(Duration(seconds: i * 5)).toIso8601String()}</time><extensions><hr>${140 + i}</hr></extensions></trkpt>'].join('\n')}
</trkseg></trk></gpx>''';
}

void main() {
  group('decodeActivityFile', () {
    test('reads a FIT ride with heart rate from its records', () {
      final file = decodeActivityFile(polarFitFixture(sport: 2))!;
      expect(file.format, 'FIT');
      expect(file.type, 'cycling');
      expect(file.start, DateTime.utc(2026, 10, 25, 14, 28));
      expect(file.durationSeconds, 3645);
      expect(file.distanceMeters, closeTo(9530, 0.1));
      expect(file.avgHeartRate, closeTo((120 + 132 + 152) / 3, 0.01));
      expect(file.maxHeartRate, 152);
      expect(file.movingSeconds, 3600);
      expect(file.samples, hasLength(3));
      expect(file.route, hasLength(3));
    });

    test('reads a Strava GPX ride with heart rate and power extensions', () {
      final file = decodeActivityFile(_bytes(_gpx))!;
      expect(file.format, 'GPX');
      expect(file.type, 'cycling');
      expect(file.name, 'Evening Ride');
      expect(file.durationSeconds, 2400);
      expect(file.distanceMeters, closeTo(2224, 5));
      expect(file.avgHeartRate, 140);
      expect(file.maxHeartRate, 160);
      expect(file.avgWatts, 220);
      // A 1 m step alone is jitter; the rise from 50 m to 60 m counts.
      expect(file.ascentMeters, 10);
      expect(file.samples.first['cad'], 85);
    });

    test('reads a TCX run', () {
      final file = decodeActivityFile(_bytes(_tcx))!;
      expect(file.format, 'TCX');
      expect(file.type, 'running');
      expect(file.durationSeconds, 1800);
      expect(file.distanceMeters, 5000);
    });

    test('rejects other files and routes without times', () {
      expect(decodeActivityFile(_bytes('hello')), isNull);
      expect(
        decodeActivityFile(
          _bytes(_gpx.replaceAll(RegExp('<time>[^<]*</time>'), '')),
        ),
        isNull,
      );
    });

    test('the same file always gets the same id', () {
      expect(
        decodeActivityFile(_bytes(_gpx))!.activityId,
        decodeActivityFile(_bytes(_gpx))!.activityId,
      );
    });

    test('maps sport names from other apps', () {
      expect(activityFileType('Ride'), 'cycling');
      expect(activityFileType('VirtualRide'), 'cycling');
      expect(activityFileType('Biking'), 'cycling');
      expect(activityFileType('Run'), 'running');
      expect(activityFileType('9'), 'other');
      expect(activityFileType(null), 'other');
    });
  });

  group('ActivityFileImportService', () {
    late AppDatabase db;
    late ActivityFileImportService service;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      service = ActivityFileImportService(db);
    });
    tearDown(() => db.close());

    Future<void> insert(
      String id,
      String source,
      DateTime start,
      int seconds,
    ) => db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: id,
            name: id,
            type: 'cycling',
            startDate: start,
            durationSeconds: seconds,
            source: Value(source),
          ),
        );

    Future<bool> import(ActivityFilePreview p) =>
        service.import(p, runningZones: _zones, cyclingZones: _zones);

    test(
      'stores the activity with zones and reports a second import',
      () async {
        final preview = await service.preview('run.gpx', _bytes(_denseGpx()));
        expect(preview.canImport, isTrue);
        expect(await import(preview), isTrue);
        final stored = (await db.select(db.activityRecords).get()).single;
        expect(stored.source, 'file');
        expect(stored.type, 'running');
        expect(stored.avgHeartRate, 145.5);
        expect(stored.hrZonesJson, isNotNull);
        expect(jsonDecode(stored.gpxJson!), hasLength(12));

        final again = await service.preview('run.gpx', _bytes(_denseGpx()));
        expect(again.alreadyImported, isTrue);
        expect(again.canImport, isFalse);
      },
    );

    test('a workout a platform already synced is not imported again', () async {
      await insert(
        'garmin_1',
        'garmin_api',
        DateTime.utc(2026, 10, 30, 16),
        2400,
      );
      final preview = await service.preview('ride.gpx', _bytes(_gpx));
      expect(preview.duplicateSource, 'garmin_api');
      expect(preview.canImport, isFalse);
    });

    test('the file replaces an Apple Health copy', () async {
      await insert(
        'hc_1',
        'health_connect',
        DateTime.utc(2026, 10, 30, 16),
        2400,
      );
      final preview = await service.preview('ride.gpx', _bytes(_gpx));
      expect(preview.canImport, isTrue);
      await import(preview);
      final rows = await db.select(db.activityRecords).get();
      expect(rows.map((r) => r.source), ['file']);
    });

    test('a platform that syncs the workout later replaces the file', () async {
      await import(await service.preview('ride.gpx', _bytes(_gpx)));
      await insert(
        'garmin_1',
        'garmin_api',
        DateTime.utc(2026, 10, 30, 16),
        2400,
      );
      await db.deduplicateActivities();
      final rows = await db.select(db.activityRecords).get();
      expect(rows.map((r) => r.source), ['garmin_api']);
    });
  });
}
