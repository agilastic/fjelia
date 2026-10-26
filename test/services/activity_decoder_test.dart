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
      int durationSeconds = 1800,
      int? movingSeconds,
    }) async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: 'a1',
              name: 'Run',
              type: 'running',
              startDate: DateTime(2026, 10, 20, 7),
              durationSeconds: durationSeconds,
              movingDurationSeconds: Value(movingSeconds),
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

    String speedSamples({
      bool denseHr = false,
      bool stopped = false,
      int gap = 5,
    }) {
      final start = DateTime.utc(2026, 10, 25, 14, 28).millisecondsSinceEpoch;
      return '[${[for (var i = 0; i <= 2 * gap; i += denseHr ? 1 : gap) '{"d":${stopped ? 0 : i * 2.5},"t":${start + i * 1000},"hr":132${i % gap == 0 ? ',"spd":${stopped ? 0 : 2.5}' : ''}}'].join(',')}]';
    }

    test(
      'timed speed intervals are not shortened by intervening HR rows',
      () async {
        final a = decodeActivityRecord(
          await store(
            metrics: speedSamples(denseHr: true),
            durationSeconds: 10,
          ),
        );
        expect(a.movingDuration, const Duration(seconds: 10));
      },
    );
    test(
      'partial speed coverage is not a whole-workout moving-time estimate',
      () async {
        final a = decodeActivityRecord(
          await store(metrics: speedSamples(), durationSeconds: 3600),
        );
        expect(a.movingDuration, isNull);
      },
    );
    test('long unobserved gaps do not become moving time', () async {
      final a = decodeActivityRecord(
        await store(metrics: speedSamples(gap: 1800), durationSeconds: 3600),
      );
      expect(a.movingDuration, isNull);
    });
    test('complete stationary data can represent zero moving time', () async {
      final a = decodeActivityRecord(
        await store(metrics: speedSamples(stopped: true), durationSeconds: 10),
      );
      expect(a.movingDuration, Duration.zero);
    });
    test(
      'a source-reported moving time takes precedence over estimates',
      () async {
        final a = decodeActivityRecord(
          await store(
            metrics: speedSamples(),
            durationSeconds: 3600,
            movingSeconds: 3500,
          ),
        );
        expect(a.movingDuration, const Duration(seconds: 3500));
      },
    );
    test('recorded cadence survives decoding', () async {
      final a = decodeActivityRecord(
        await store(metrics: '[{"d":0,"cad":79}]'),
      );
      expect(a.samples.single.cadence, 79);
    });
    test('HR-only records need no invented stored distance field', () async {
      final a = decodeActivityRecord(
        await store(metrics: '[{"hr":132,"t":1792938480000}]'),
      );
      expect(a.samples.single.heartRate, 132);
      expect(a.samples.single.distanceMeters, 0);
      expect(a.movingDuration, isNull);
    });
  });
}
