enum HealthMetric {
  hrv,
  rhr,
  spo2,
  respiration,
  stress,
  skinTemperature,
  steps,
  sleep,
  weight,
  bodyFat,
  muscle,
  bmi,
  water,
  protein,
  visceralFat,
  bmr,
  bone,
  waist,
}

extension HealthMetricInfo on HealthMetric {
  String get label => const [
    'HRV Sleep',
    'RHR Sleep',
    'SpO2 Sleep',
    'Resp Rate',
    'Stress',
    'Skin Temp',
    'Steps',
    "Tonight’s Sleep",
    'Weight',
    'Body Fat',
    'Muscle Mass',
    'BMI',
    'Body Water',
    'Protein',
    'Visceral Fat',
    'BMR',
    'Bone Mass',
    'Waist',
  ][index];
  String get unit => const [
    'ms',
    'bpm',
    '%',
    'rpm',
    '/100',
    '°C',
    'steps',
    'h',
    'kg',
    '%',
    'kg',
    '',
    '%',
    '%',
    '',
    'kcal',
    'kg',
    'cm',
  ][index];
  bool get isBody => index >= HealthMetric.weight.index;

  String? get directionHint => switch (this) {
    HealthMetric.rhr || HealthMetric.stress => 'Lower is better',
    HealthMetric.hrv || HealthMetric.spo2 => 'Higher is better',
    HealthMetric.respiration ||
    HealthMetric.skinTemperature => 'Within your usual range is better',
    HealthMetric.steps => 'Work toward your daily step goal',
    HealthMetric.sleep => 'Aim for your recommended sleep duration',
    _ => null,
  };
}
