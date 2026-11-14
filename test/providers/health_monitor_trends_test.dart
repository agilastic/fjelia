import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/health_monitor_trends_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

HrvRecord _row(
  DateTime date, {
  double skin = 0,
  double spo2 = 97,
  double resp = 14,
  double stress = 28,
}) => HrvRecord(
  id: date.day,
  date: date,
  hrvLastNight: 40,
  hrvWeeklyAvg: null,
  restingHeartRate: 48,
  stressLevel: stress,
  bodyBattery: null,
  computedEnergie: null,
  spo2: spo2,
  respirationRate: resp,
  skinTempDelta: skin,
  hrvIntradayJson: null,
  source: null,
);

void main() {
  final today = DateTime(2026, 11, 14);
  Future<HealthTrends> trends(
    HrvRecord current,
    List<HrvRecord> history,
  ) async {
    final container = ProviderContainer(
      overrides: [
        hrvForDateProvider.overrideWith((ref, date) async => current),
        hrvRangeProvider.overrideWith((ref, days) async => history),
      ],
    );
    addTearDown(container.dispose);
    await container.read(hrvForDateProvider(today).future);
    await container.read(hrvRangeProvider(15).future);
    return container.read(healthMonitorTrendsProvider(today));
  }

  final history = [
    for (var i = 1; i <= 14; i++)
      _row(today.subtract(Duration(days: i)), skin: i.isEven ? .1 : -.1),
  ];

  test('skin temperature is compared with its two-week average', () async {
    final t = await trends(_row(today, skin: .6), history);
    expect(t.skinTemp, closeTo(.6, .001));
  });

  test('changes inside the day-to-day noise are steady', () async {
    final t = await trends(
      _row(today, skin: .1, spo2: 96.5, resp: 14.3, stress: 31),
      history,
    );
    expect(t.skinTemp, 0);
    expect(t.spo2, 0);
    expect(t.resp, 0);
    expect(t.stress, 0);
  });

  test('a clear change shows its direction', () async {
    final t = await trends(
      _row(today, spo2: 94, resp: 16, stress: 45),
      history,
    );
    expect(t.spo2, lessThan(0));
    expect(t.resp, greaterThan(0));
    expect(t.stress, greaterThan(0));
  });
}
