/// A display value and the number of distinct observed strokes behind it.
/// Zero means a live reading without a usable stroke counter.
class RowingMetric {
  const RowingMetric({this.value, this.strokes = 0});

  final double? value;
  final int strokes;
}

class RowingLiveMetrics {
  const RowingLiveMetrics({
    this.pace = const RowingMetric(),
    this.rate = const RowingMetric(),
    this.power = const RowingMetric(),
  });

  final RowingMetric pace, rate, power;
}

/// Smooths the rowing display over the last three reported stroke counts.
/// Split notifications update the same stroke; repeated packets never give
/// that stroke extra weight. Missing strokes/fields are not manufactured.
/// This window is deliberately separate from stored samples and FIT exports.
class RowingStrokeAverage {
  final _strokes = <({int count, Map<String, double> values})>[];
  final _latest = <String, ({double value, DateTime at})>{};
  int? _count;
  DateTime? _counterAt;

  void clear() {
    _strokes.clear();
    _latest.clear();
    _count = null;
    _counterAt = null;
  }

  static bool _fresh(DateTime? then, DateTime now) {
    if (then == null) return false;
    final age = now.difference(then).inMilliseconds;
    return age >= 0 && age <= 5000;
  }

  void ingest(Map<String, num> packet, DateTime at) {
    final reportedCount = packet['machine_strokes'];
    final count =
        reportedCount != null &&
            reportedCount.isFinite &&
            reportedCount >= 0 &&
            reportedCount < 65535 &&
            reportedCount == reportedCount.round()
        ? reportedCount.toInt()
        : null;
    if (count != null && _count != null && count < _count!) clear();
    final values = <String, double>{};
    void take(String key, num? value, {bool positive = false}) {
      if (value != null &&
          value.isFinite &&
          (positive ? value > 0 : value >= 0)) {
        values[key] = value.toDouble();
        _latest[key] = (value: value.toDouble(), at: at);
      }
    }

    final pace = packet['pace_500m'];
    final speed = packet['spd'];
    take(
      'pace',
      pace ?? (speed != null && speed > 0 ? 500 / speed : null),
      positive: true,
    );
    take('rate', packet['cad']);
    take('power', packet['w']);

    if (pace == 0 || speed == 0 || packet['cad'] == 0) {
      _latest.remove('pace');
    }
    if (!_fresh(_counterAt, at)) _strokes.clear();
    if (count != null) {
      _count = count;
      _counterAt = at;
    }
    final lastRate = _latest['rate'];
    if (lastRate != null && lastRate.value == 0 && _fresh(lastRate.at, at)) {
      _strokes.clear();
      return;
    }
    if (_count == null || !_fresh(_counterAt, at)) return;
    _strokes.removeWhere((s) => s.count < _count! - 2);
    if (_strokes.isEmpty || _strokes.last.count != _count) {
      _strokes.add((count: _count!, values: {}));
    }
    _strokes.last.values.addAll(values);
  }

  RowingLiveMetrics live(DateTime at) {
    RowingMetric metric(String key) {
      final latest = _latest[key];
      if (latest == null || !_fresh(latest.at, at)) return const RowingMetric();
      final values = _fresh(_counterAt, at)
          ? _strokes.map((s) => s.values[key]).whereType<double>().toList()
          : const <double>[];
      if (values.isEmpty) return RowingMetric(value: latest.value);
      return RowingMetric(
        value: values.reduce((a, b) => a + b) / values.length,
        strokes: values.length,
      );
    }

    return RowingLiveMetrics(
      pace: metric('pace'),
      rate: metric('rate'),
      power: metric('power'),
    );
  }
}
