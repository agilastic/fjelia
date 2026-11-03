/// Waist-based health ratios and their usual cut-offs.
library;

/// Waist-to-height ratio; null without both values.
double? waistToHeight(double? waistCm, double? heightCm) =>
    waistCm == null || heightCm == null || heightCm <= 0
    ? null
    : waistCm / heightCm;

/// Waist-to-hip ratio; null without both values.
double? waistToHip(double? waistCm, double? hipCm) =>
    waistCm == null || hipCm == null || hipCm <= 0 ? null : waistCm / hipCm;

enum WaistRisk { low, healthy, increased, high }

/// WHtR after Ashwell: below 0.4 is very slim, up to 0.5 healthy, up to 0.6
/// increased, from 0.6 high risk. The same for men and women.
WaistRisk whtrRisk(double ratio) => ratio < .4
    ? WaistRisk.low
    : ratio < .5
    ? WaistRisk.healthy
    : ratio < .6
    ? WaistRisk.increased
    : WaistRisk.high;

/// WHR after the WHO: abdominal obesity from 0.90 (men) or 0.85 (women).
WaistRisk whrRisk(double ratio, String sex) =>
    ratio < (sex == 'f' ? .85 : .90) ? WaistRisk.healthy : WaistRisk.high;

/// Waist alone after the WHO for Europeans: men 94 / 102 cm, women 80 / 88 cm.
WaistRisk waistRisk(double waistCm, String sex) {
  final (increased, high) = sex == 'f' ? (80, 88) : (94, 102);
  return waistCm < increased
      ? WaistRisk.healthy
      : waistCm < high
      ? WaistRisk.increased
      : WaistRisk.high;
}

/// One measurement, as far as the ratios need it.
typedef WaistPoint = ({DateTime at, double waistCm, double? hipCm});

/// How much the waist changed over [period] up to the newest measurement:
/// newest minus the last one at least [period] older. Null when the history
/// does not reach back that far.
double? waistChange(List<WaistPoint> oldestFirst, Duration period) {
  if (oldestFirst.length < 2) return null;
  final latest = oldestFirst.last;
  final from = latest.at.subtract(period);
  final before = oldestFirst.lastWhere(
    (p) => !p.at.isAfter(from),
    orElse: () => latest,
  );
  return identical(before, latest) ? null : latest.waistCm - before.waistCm;
}

/// The newest hip measurement, for the WHR; hip is measured less often.
double? latestHip(List<WaistPoint> oldestFirst) =>
    oldestFirst.lastWhere((p) => p.hipCm != null, orElse: _none).hipCm;

WaistPoint _none() => (at: DateTime(0), waistCm: 0, hipCm: null);
