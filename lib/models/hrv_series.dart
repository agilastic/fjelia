import 'chart_point.dart';

/// The HRV readings that are compared in one view.
enum HrvSeries {
  sleep('Sleep'),
  before('Before training'),
  after('After training'),
  resting('Resting');

  const HrvSeries(this.label);
  final String label;

  /// Series of a stored Polar H10 spot reading, by its context name.
  static HrvSeries? ofSpotContext(String context) => switch (context) {
    'beforeTraining' => before,
    'afterTraining' => after,
    'resting' => resting,
    _ => null,
  };
}

/// One series of an HRV chart together with its readings in time order.
class HrvSeriesData {
  const HrvSeriesData(this.series, this.points);
  final HrvSeries series;
  final List<ChartPoint> points;

  int get count => points.length;

  double? get average => points.isEmpty
      ? null
      : points.fold<double>(0, (sum, p) => sum + p.value) / points.length;
}

/// A spot reading reduced to what the HRV chart needs.
class SpotHrvPoint {
  const SpotHrvPoint({
    required this.at,
    required this.context,
    required this.posture,
    required this.rmssdMs,
  });
  final DateTime at;
  final String context;
  final String posture;
  final double rmssdMs;
}

/// Groups overnight HRV and spot readings into the chart series. Readings
/// with another [posture] are left out when a posture is given, because
/// lying down and sitting give different values.
List<HrvSeriesData> buildHrvSeries({
  required List<ChartPoint> sleep,
  required List<SpotHrvPoint> spot,
  String? posture,
}) {
  final sorted = <HrvSeries, List<ChartPoint>>{
    HrvSeries.sleep: [
      for (final p in sleep)
        if (p.value.isFinite && p.value > 0) p,
    ],
  };
  for (final row in spot) {
    if (posture != null && row.posture != posture) continue;
    final series = HrvSeries.ofSpotContext(row.context);
    if (series == null) continue;
    (sorted[series] ??= []).add(ChartPoint(row.at, row.rmssdMs));
  }
  return [
    for (final series in HrvSeries.values)
      HrvSeriesData(
        series,
        (sorted[series] ?? [])..sort((a, b) => a.at.compareTo(b.at)),
      ),
  ];
}

/// Average after-training minus average before-training HRV in ms, or null
/// when either has no readings.
double? afterMinusBefore(List<HrvSeriesData> series) {
  final before = series.firstWhere((s) => s.series == HrvSeries.before).average;
  final after = series.firstWhere((s) => s.series == HrvSeries.after).average;
  return before == null || after == null ? null : after - before;
}
