import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/threshold_candidate.dart';
import 'package:fjelia/services/device_threshold_store.dart';
import 'package:fjelia/services/dfa_alpha1_service.dart';
import 'package:fjelia/services/threshold_choice_store.dart';

final _now = DateTime(2026, 11, 2);

ThresholdCandidate _c(
  String source,
  int value, {
  int daysAgo = 10,
  ThresholdKind kind = ThresholdKind.lt2,
}) => ThresholdCandidate(
  kind: kind,
  source: source,
  value: value,
  date: _now.subtract(Duration(days: daysAgo)),
);

void main() {
  group('bestThreshold', () {
    test(
      'app test, then watch, then DFA, then Polar profile, then formula',
      () {
        final all = [
          _c('formula', 150),
          _c('polar_profile', 160),
          _c('dfa', 165),
          _c('garmin_api', 168),
          _c('tt', 170, daysAgo: 60),
        ];
        expect(bestThreshold(all, _now)!.source, 'tt');
        expect(bestThreshold(all.sublist(0, 4), _now)!.source, 'garmin_api');
        expect(bestThreshold(all.sublist(0, 3), _now)!.source, 'dfa');
        expect(bestThreshold(all.sublist(0, 2), _now)!.source, 'polar_profile');
      },
    );

    test('the newer of two watch values wins', () {
      final best = bestThreshold([
        _c('garmin_api', 168, daysAgo: 40),
        _c('coros', 166, daysAgo: 5),
      ], _now);
      expect(best!.source, 'coros');
    });

    test('values older than six months are not used', () {
      final best = bestThreshold([
        _c('tt', 170, daysAgo: 200),
        _c('dfa', 165),
      ], _now);
      expect(best!.source, 'dfa');
    });
  });

  group('thresholdProposal', () {
    test('proposes a difference of at least 3 bpm', () {
      final candidates = [_c('garmin_api', 168)];
      expect(
        thresholdProposal(
          candidates: candidates,
          inUse: 170,
          kept: {},
          now: _now,
        ),
        isNull,
      );
      expect(
        thresholdProposal(
          candidates: candidates,
          inUse: 172,
          kept: {},
          now: _now,
        )!.value,
        168,
      );
    });

    test('FTP needs a 3 % difference', () {
      final candidates = [_c('garmin_api', 255, kind: ThresholdKind.ftp)];
      expect(
        thresholdProposal(
          candidates: candidates,
          inUse: 250,
          kept: {},
          now: _now,
        ),
        isNull,
      );
      expect(
        thresholdProposal(
          candidates: candidates,
          inUse: 240,
          kept: {},
          now: _now,
        ),
        isNotNull,
      );
    });

    test('a kept proposal returns only when the value changes', () {
      final kept = {_c('garmin_api', 168).fingerprint};
      expect(
        thresholdProposal(
          candidates: [_c('garmin_api', 168)],
          inUse: 175,
          kept: kept,
          now: _now,
        ),
        isNull,
      );
      // A move of 2 bpm (DFA medians wander) stays kept, 4 bpm does not.
      expect(
        thresholdProposal(
          candidates: [_c('garmin_api', 166)],
          inUse: 175,
          kept: kept,
          now: _now,
        ),
        isNull,
      );
      expect(
        thresholdProposal(
          candidates: [_c('garmin_api', 164)],
          inUse: 175,
          kept: kept,
          now: _now,
        ),
        isNotNull,
      );
    });

    test('a formula is shown but never proposed', () {
      expect(
        thresholdProposal(
          candidates: [_c('formula', 140, kind: ThresholdKind.lt1)],
          inUse: 152,
          kept: {},
          now: _now,
        ),
        isNull,
      );
    });

    test('without a value in use the best candidate is proposed', () {
      expect(
        thresholdProposal(
          candidates: [_c('dfa', 160)],
          inUse: null,
          kept: {},
          now: _now,
        )!.source,
        'dfa',
      );
    });
  });

  test('median needs a minimum number of sessions', () {
    expect(medianOf([150, 160], minimum: 3), isNull);
    expect(medianOf([150, 170, 160], minimum: 3), 160);
    expect(medianOf([150, 160, 170, 180], minimum: 3), 165);
  });

  test('pace converts from s/km or m/s, implausible values are dropped', () {
    expect(paceSecPerKm(270), 270);
    expect(paceSecPerKm(3.7), 270);
    expect(paceSecPerKm(0.37 * 10), 270);
    expect(paceSecPerKm(30), isNull);
    expect(plausibleBpm(165), 165);
    expect(plausibleBpm(0), isNull);
    expect(plausibleBpm('171'), 171);
  });

  test('parallel platform saves keep every platform', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const store = DeviceThresholdStore();
    await Future.wait([
      for (final source in ['garmin_api', 'coros', 'polar_profile'])
        store.save(DeviceThreshold(source: source, date: _now, lt2Bpm: 165)),
    ]);
    expect((await store.all()).keys.toSet(), {
      'garmin_api',
      'coros',
      'polar_profile',
    });
  });

  test('zones stop following the device after another source is applied', () {
    expect(runZonesFollowDevice({}), isTrue);
    expect(runZonesFollowDevice({ThresholdKind.lt2: 'garmin_api'}), isTrue);
    expect(runZonesFollowDevice({ThresholdKind.lt1: 'dfa'}), isFalse);
    expect(runZonesFollowDevice({ThresholdKind.ftp: 'garmin_api'}), isTrue);
    expect(bikeZonesFollowDevice({ThresholdKind.lt2Bike: 'coros'}), isFalse);
  });

  test('DFA sessions are listed per sport, newest first', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    Future<void> session(
      String id,
      String type,
      int daysAgo,
      double hrvt1,
    ) async {
      await db
          .into(db.activityRecords)
          .insert(
            ActivityRecordsCompanion.insert(
              activityId: id,
              name: id,
              type: type,
              startDate: DateTime.now().subtract(Duration(days: daysAgo)),
              durationSeconds: 3600,
            ),
          );
      await db
          .into(db.dfaAlpha1Results)
          .insert(
            DfaAlpha1ResultsCompanion.insert(
              activityId: id,
              rrCount: 5000,
              artifacts: 0.01,
              windowsJson: '[]',
              hrvt1Bpm: Value(hrvt1),
              computedAt: DateTime.now(),
            ),
          );
    }

    await session('r1', 'running', 3, 150);
    await session('r2', 'running', 1, 152);
    await session('b1', 'cycling', 2, 140);
    await session('old', 'running', 60, 140);
    final runs = await DfaAlpha1Service(db).recent(cycling: false);
    expect(runs.map((r) => r.hrvt1), [152, 150]);
    final rides = await DfaAlpha1Service(db).recent(cycling: true);
    expect(rides.single.hrvt1, 140);
  });
}
