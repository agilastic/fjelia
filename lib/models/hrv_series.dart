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
/// [details] and [episodeIds] line up with [points]: what to say about a
/// point, and the workout it belongs to (null for none).
class HrvSeriesData {
  const HrvSeriesData(
    this.series,
    this.points, {
    this.details = const [],
    this.episodeIds = const [],
    this.postures = const {},
  });
  final HrvSeries series;
  final List<ChartPoint> points;
  final List<String?> details;
  final List<String?> episodeIds;

  /// The positions the readings were taken in. Readings in different
  /// positions are shown, but never averaged together.
  final Set<String> postures;

  int get count => points.length;

  bool get mixedPostures => postures.length > 1;

  /// Mean of the readings, or null when there are none or when seated and
  /// lying readings are mixed (their values are not on one scale).
  double? get average => points.isEmpty || mixedPostures
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
    this.detail,
    this.episodeId,
  });
  final DateTime at;
  final String context;
  final String posture;
  final double rmssdMs;

  /// Position, length, quality and timing against the workout, as one line.
  final String? detail;

  /// The workout this reading is the pre or post of.
  final String? episodeId;
}

/// Groups overnight HRV and spot readings into the chart series. Readings
/// with another [posture] are left out when a posture is given, because
/// lying down and sitting give different values.
List<HrvSeriesData> buildHrvSeries({
  required List<ChartPoint> sleep,
  required List<SpotHrvPoint> spot,
  String? posture,
}) {
  final sorted = <HrvSeries, List<(ChartPoint, String?, String?, String?)>>{
    HrvSeries.sleep: [
      for (final p in sleep)
        if (p.value.isFinite && p.value > 0) (p, null, null, null),
    ],
  };
  for (final row in spot) {
    if (posture != null && row.posture != posture) continue;
    final series = HrvSeries.ofSpotContext(row.context);
    if (series == null) continue;
    (sorted[series] ??= []).add((
      ChartPoint(row.at, row.rmssdMs),
      row.detail,
      row.episodeId,
      row.posture,
    ));
  }
  return [
    for (final series in HrvSeries.values)
      () {
        final rows = [...?sorted[series]]
          ..sort((a, b) => a.$1.at.compareTo(b.$1.at));
        return HrvSeriesData(
          series,
          [for (final r in rows) r.$1],
          details: [for (final r in rows) r.$2],
          episodeIds: [for (final r in rows) r.$3],
          postures: {
            for (final r in rows)
              if (r.$4 != null) r.$4!,
          },
        );
      }(),
  ];
}
