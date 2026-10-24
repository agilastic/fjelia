import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/activity_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeStoredJson', () {
    test('reads valid JSON', () {
      expect(decodeStoredJson('[1,2]'), [1, 2]);
      expect(decodeStoredJson('{"a":1}'), {'a': 1});
    });

    test('a missing, blank or unreadable value gives null', () {
      expect(decodeStoredJson(null), isNull);
      expect(decodeStoredJson(''), isNull);
      expect(decodeStoredJson('   '), isNull);
      expect(decodeStoredJson('[1,'), isNull);
    });
  });

  group('decodeActivityRecord', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<ActivityRecord> store({
      String? gpx,
      String? metrics,
      String? zones,
      String? steps,
    }) async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'a1',
              name: 'Run',
              type: 'running',
              startDate: DateTime(2026, 10, 20, 7),
              durationSeconds: 1800,
              gpxJson: Value(gpx),
              metricsJson: Value(metrics),
              hrZonesJson: Value(zones),
              plannedStepsJson: Value(steps),
            ),
          );
      return (await db.select(db.activityRecords).get()).single;
    }

    test('blank JSON columns do not break decoding', () async {
      final activity = decodeActivityRecord(
        await store(gpx: '', metrics: ' ', zones: '', steps: ''),
      );
      expect(activity.id, 'a1');
      expect(activity.route, isEmpty);
      expect(activity.samples, isEmpty);
      expect(activity.hrZoneSeconds, isEmpty);
      expect(activity.plannedSteps, isEmpty);
    });

    test('valid columns are still decoded', () async {
      final activity = decodeActivityRecord(
        await store(
          gpx: '[{"lat":50.1,"lng":8.6}]',
          metrics: '[{"d":10,"t":0,"hr":120}]',
          zones: '{"z1":60,"z2":120}',
        ),
      );
      expect(activity.route, hasLength(1));
      expect(activity.samples, hasLength(1));
      expect(activity.hrZoneSeconds['z2'], 120);
    });
  });
}
