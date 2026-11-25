import 'package:fjelia_core/models/health_metric.dart';
import 'package:fjelia_core/models/hrv_series.dart';
import 'app_localizations.dart';

/// [HealthMetric.label] in the app language.
String healthMetricLabel(AppLocalizations l, HealthMetric m) => switch (m) {
  HealthMetric.hrv => l.metricHrvSleep,
  HealthMetric.rhr => l.metricRhrSleep,
  HealthMetric.spo2 => l.metricSpo2Sleep,
  HealthMetric.respiration => l.metricRespRate,
  HealthMetric.stress => l.stress,
  HealthMetric.skinTemperature => l.metricSkinTemp,
  HealthMetric.steps => l.steps,
  HealthMetric.sleep => l.metricTonightSleep,
  HealthMetric.weight => l.weight,
  HealthMetric.bodyFat => l.bodyFat,
  HealthMetric.muscle => l.metricMuscleMass,
  HealthMetric.bmi => l.metricBmi,
  HealthMetric.water => l.metricBodyWater,
  HealthMetric.protein => l.metricProtein,
  HealthMetric.visceralFat => l.metricVisceralFat,
  HealthMetric.bmr => l.metricBmr,
  HealthMetric.bone => l.metricBoneMass,
  HealthMetric.waist => l.waist,
};

/// [HealthMetric.directionHint] in the app language.
String? healthMetricHint(AppLocalizations l, HealthMetric m) => switch (m) {
  HealthMetric.rhr || HealthMetric.stress => l.metricHintLower,
  HealthMetric.hrv || HealthMetric.spo2 => l.metricHintHigher,
  HealthMetric.respiration || HealthMetric.skinTemperature => l.metricHintUsual,
  HealthMetric.steps => l.metricHintSteps,
  HealthMetric.sleep => l.metricHintSleep,
  _ => null,
};

/// [HrvSeries.label] in the app language.
String hrvSeriesLabel(AppLocalizations l, HrvSeries s) => switch (s) {
  HrvSeries.sleep => l.hrvSeriesSleep,
  HrvSeries.before => l.hrvSeriesBefore,
  HrvSeries.after => l.hrvSeriesAfter,
  HrvSeries.resting => l.hrvSeriesResting,
};

/// Why a day usually has no reading of [m]; null for body measurements,
/// which are taken now and then, so an older one is not a gap.
String? healthMetricGapReason(AppLocalizations l, HealthMetric m) =>
    switch (m) {
      HealthMetric.hrv ||
      HealthMetric.rhr ||
      HealthMetric.spo2 ||
      HealthMetric.respiration ||
      HealthMetric.skinTemperature ||
      HealthMetric.sleep => l.metricGapNight,
      HealthMetric.stress || HealthMetric.steps => l.metricGapDay,
      _ => null,
    };
