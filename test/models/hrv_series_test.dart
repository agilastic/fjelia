import 'package:fjelia/models/chart_point.dart';
import 'package:fjelia/models/hrv_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 10, 20);
  SpotHrvPoint spot(
    String context,
    int hour,
    double rmssd, {
    String? posture,
  }) => SpotHrvPoint(
    at: day.add(Duration(hours: hour)),
    context: context,
    posture: posture ?? 'seated',
    rmssdMs: rmssd,
  );

  test('groups sleep and spot readings into ordered series', () {
    final series = buildHrvSeries(
      sleep: [
        ChartPoint(day, 48),
        ChartPoint(day.subtract(const Duration(days: 1)), 44),
      ],
      spot: [
        spot('afterTraining', 18, 35),
        spot('beforeTraining', 8, 55),
        spot('beforeTraining', 7, 53),
        spot('resting', 12, 60),
      ],
    );
    expect(series.map((s) => s.series), HrvSeries.values);
    final sleep = series.firstWhere((s) => s.series == HrvSeries.sleep);
    expect(sleep.points.first.value, 44);
    final before = series.firstWhere((s) => s.series == HrvSeries.before);
    expect(before.points.map((p) => p.value), [53, 55]);
    expect(before.average, 54);
    expect(before.count, 2);
  });

  test('the unpaired period averages no longer exist as a comparison', () {
    // Averages of two unrelated sets of readings are not a training response.
    final series = buildHrvSeries(
      sleep: const [],
      spot: [spot('beforeTraining', 8, 60), spot('afterTraining', 18, 45)],
    );
    expect(series.firstWhere((s) => s.series == HrvSeries.before).average, 60);
    expect(series.firstWhere((s) => s.series == HrvSeries.after).average, 45);
  });

  test('readings in different positions are kept but never averaged', () {
    final series = buildHrvSeries(
      sleep: const [],
      spot: [
        spot('resting', 7, 70, posture: 'supine'),
        spot('resting', 9, 50),
      ],
    );
    final resting = series.firstWhere((s) => s.series == HrvSeries.resting);
    expect(resting.count, 2);
    expect(resting.mixedPostures, isTrue);
    expect(resting.average, isNull);
  });

  test('details and workout links stay with their points when sorted', () {
    final series = buildHrvSeries(
      sleep: const [],
      spot: [
        SpotHrvPoint(
          at: day.add(const Duration(hours: 9)),
          context: 'beforeTraining',
          posture: 'seated',
          rmssdMs: 50,
          detail: 'late',
          episodeId: 'B',
        ),
        SpotHrvPoint(
          at: day.add(const Duration(hours: 7)),
          context: 'beforeTraining',
          posture: 'seated',
          rmssdMs: 52,
          detail: 'early',
          episodeId: 'A',
        ),
      ],
    );
    final before = series.firstWhere((s) => s.series == HrvSeries.before);
    expect(before.details, ['early', 'late']);
    expect(before.episodeIds, ['A', 'B']);
  });

  test('a posture filter leaves out other postures', () {
    final series = buildHrvSeries(
      sleep: const [],
      spot: [
        spot('resting', 7, 70, posture: 'supine'),
        spot('resting', 9, 50),
      ],
      posture: 'seated',
    );
    final resting = series.firstWhere((s) => s.series == HrvSeries.resting);
    expect(resting.points.map((p) => p.value), [50]);
  });

  test('ignores unknown contexts and empty or invalid sleep values', () {
    final series = buildHrvSeries(
      sleep: [
        ChartPoint(day, 0),
        ChartPoint(day, double.nan),
        ChartPoint(day, 40),
      ],
      spot: [spot('somethingElse', 8, 50)],
    );
    expect(series.firstWhere((s) => s.series == HrvSeries.sleep).count, 1);
    expect(
      series
          .where((s) => s.series != HrvSeries.sleep)
          .every((s) => s.count == 0),
      isTrue,
    );
  });
}
