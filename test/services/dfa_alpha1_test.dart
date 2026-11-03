import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/activity_file_import_service.dart';
import 'package:fjelia/services/dfa_alpha1.dart';
import 'package:fjelia/services/dfa_alpha1_service.dart';
import 'package:fjelia/services/fit_activity_data.dart';

import '../support/polar_fit_fixture.dart';

/// Gaussian noise around [mean] ms (Box–Muller), seeded.
List<double> _whiteNoise(
  int n, {
  double mean = 500,
  double sd = 20,
  int seed = 1,
}) {
  final random = math.Random(seed);
  return [
    for (var i = 0; i < n; i++)
      mean +
          sd *
              math.sqrt(-2 * math.log(1 - random.nextDouble())) *
              math.cos(2 * math.pi * random.nextDouble()),
  ];
}

/// Integrated noise: strongly correlated, alpha1 well above 1.
List<double> _brownNoise(int n, {int seed = 2}) {
  final steps = _whiteNoise(n, mean: 0, sd: 3, seed: seed);
  var level = 800.0;
  return [
    for (final s in steps) level = (level + s).clamp(700, 900).toDouble(),
  ];
}

void main() {
  group('dfaAlpha1', () {
    test('uncorrelated beats give about 0.5', () {
      final values = [
        for (var seed = 1; seed <= 5; seed++)
          dfaAlpha1(_whiteNoise(240, seed: seed))!,
      ];
      final mean = values.reduce((a, b) => a + b) / values.length;
      expect(mean, closeTo(0.5, 0.12));
    });

    test('strongly correlated beats give well above 1', () {
      expect(dfaAlpha1(_brownNoise(240))!, greaterThan(1.2));
    });

    test('too few beats give nothing', () {
      expect(dfaAlpha1(_whiteNoise(20)), isNull);
    });
  });

  group('analyseDfaAlpha1', () {
    final start = DateTime.utc(2026, 11, 1, 8);

    test('rolls 2-minute windows every 30 s over the session', () {
      // 10 minutes at 120 bpm.
      final rr = _whiteNoise(1200);
      final analysis = analyseDfaAlpha1(RrSeries.fromIntervals(start, rr));
      expect(analysis.rrCount, 1200);
      expect(analysis.windows.length, inInclusiveRange(15, 17));
      expect(analysis.windows.first.heartRate, closeTo(120, 2));
      expect(analysis.artifacts, lessThan(0.01));
    });

    test('takes power and speed of each window from the samples', () {
      final rr = _whiteNoise(600);
      final analysis = analyseDfaAlpha1(
        RrSeries.fromIntervals(start, rr),
        samples: [
          for (var s = 0; s < 300; s++)
            {
              't': start.millisecondsSinceEpoch + s * 1000,
              'w': 200,
              'spd': 3.5,
            },
        ],
      );
      expect(analysis.windows.first.watts, 200);
      expect(analysis.windows.first.speed, 3.5);
    });

    test('skips windows with too many artifacts', () {
      final rr = _whiteNoise(600);
      // Every 10th beat doubled: a missed beat, 10 % artifacts.
      for (var i = 0; i < rr.length; i += 10) {
        rr[i] *= 2;
      }
      final analysis = analyseDfaAlpha1(RrSeries.fromIntervals(start, rr));
      expect(analysis.artifacts, closeTo(0.1, 0.02));
      expect(analysis.windows, isEmpty);
    });
  });

  group('dfaThreshold', () {
    List<DfaWindow> ramp({bool withPower = true}) => [
      for (var hr = 110.0; hr <= 170; hr += 4)
        DfaWindow(
          t: hr.toInt() * 60000,
          alpha1: 1.2 - 0.02 * (hr - 120),
          heartRate: hr,
          artifacts: 0,
          watts: withPower ? hr * 2 : null,
        ),
    ];

    test('finds heart rate and power where alpha1 crosses 0.75 and 0.5', () {
      final t1 = dfaThreshold(ramp(), hrvt1Alpha)!;
      expect(t1.heartRate, closeTo(142.5, 0.01));
      expect(t1.watts, closeTo(285, 0.01));
      final t2 = dfaThreshold(ramp(), hrvt2Alpha)!;
      expect(t2.heartRate, closeTo(155, 0.01));
    });

    test('a steady session does not cross the threshold', () {
      final steady = [
        for (var i = 0; i < 20; i++)
          DfaWindow(
            t: i * 30000,
            alpha1: 1.0 + (i % 3) * 0.02,
            heartRate: 130 + (i % 4).toDouble(),
            artifacts: 0,
          ),
      ];
      expect(dfaThreshold(steady, hrvt1Alpha), isNull);
    });

    test('power is left out when it was not recorded', () {
      expect(dfaThreshold(ramp(withPower: false), hrvt1Alpha)!.watts, isNull);
    });
  });

  test('FIT HRV messages become RR intervals in ms', () {
    final fit = parseFitActivity(
      polarFitFixture(rrMs: [512, 498, 65535, 505]),
    )!;
    expect(fit.rrIntervals, [512, 498, 505]);
  });

  test('activity files are read from a ZIP', () {
    final archive = Archive()
      ..add(ArchiveFile.bytes('123_ACTIVITY.fit', polarFitFixture()))
      ..add(ArchiveFile.string('readme.txt', 'hello'));
    final zip = Uint8List.fromList(ZipEncoder().encode(archive));
    final files = activityFilesInZip(zip);
    expect(files.map((f) => f.name), ['123_ACTIVITY.fit']);
    expect(parseFitActivity(files.single.bytes), isNotNull);
    expect(activityFilesInZip(polarFitFixture()), isEmpty);
  });

  group('DfaAlpha1Service', () {
    late AppDatabase db;
    late DfaAlpha1Service service;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      service = DfaAlpha1Service(db);
    });
    tearDown(() => db.close());

    test('stores and loads an analysis', () async {
      await service.save(
        'garmin_1',
        start: DateTime.utc(2026, 11, 1, 8),
        rrIntervals: _whiteNoise(1200),
      );
      expect(await service.checked('garmin_1'), isTrue);
      final loaded = (await service.load('garmin_1'))!;
      expect(loaded.rrCount, 1200);
      expect(loaded.windows, isNotEmpty);
      expect(loaded.windows.first.alpha1, inInclusiveRange(0.2, 0.9));
    });

    test('a file without RR data is checked but has no analysis', () async {
      await service.save('garmin_2', start: null, rrIntervals: const []);
      expect(await service.checked('garmin_2'), isTrue);
      expect(await service.load('garmin_2'), isNull);
      expect(await service.checked('garmin_3'), isFalse);
    });

    test(
      'the analysis follows the copy that stays after deduplication',
      () async {
        final start = DateTime.utc(2026, 11, 1, 8);
        Future<void> activity(String id, String source) => db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: id,
                name: id,
                type: 'cycling',
                startDate: start,
                durationSeconds: 3600,
                source: Value(source),
              ),
            );
        await activity('file_1', 'file');
        await service.save(
          'file_1',
          start: start,
          rrIntervals: _whiteNoise(1200),
        );
        await activity('garmin_9', 'garmin_api');
        await service.save('garmin_9', start: null, rrIntervals: const []);
        await db.deduplicateActivities();
        expect(await service.load('garmin_9'), isNotNull);
        expect(await service.checked('file_1'), isFalse);
      },
    );
  });
}
