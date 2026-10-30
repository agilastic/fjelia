import 'dart:math' as math;

import 'bio_age_activity.dart';

/// Inputs for the biological-age estimate. Everything but sex and age is
/// optional; missing factors simply don't contribute.
class BioAgePerson {
  const BioAgePerson({
    required this.sex,
    required this.age,
    this.vo2max,
    this.gripKg,
    this.bmi,
    this.visceralFat,
    this.dailySteps,
    this.restingHr,
    this.systolic,
    this.weeklyActivityMinutes,
    this.activity,
    this.smoking = 'never',
    this.cigarettesPerDay,
    this.yearsSinceQuit,
    this.alcoholGramsPerWeek,
    this.diabetes = 'none',
    this.hba1c,
    this.ldl,
    this.hdl,
    this.apob,
    this.crp,
    this.egfr,
  });

  /// `m` or `f`.
  final String sex;
  final double age;
  final double? vo2max;
  final double? gripKg;
  final double? bmi;
  final double? visceralFat;
  final double? dailySteps;
  final double? restingHr;
  final double? systolic;
  final double? weeklyActivityMinutes;
  final BioAgeActivity? activity;

  /// `never`, `former` or `current`.
  final String smoking;
  final double? cigarettesPerDay;
  final double? yearsSinceQuit;
  final double? alcoholGramsPerWeek;

  /// `none`, `prediabetes`, `type1` or `type2`.
  final String diabetes;
  final double? hba1c;
  final double? ldl;
  final double? hdl;
  final double? apob;
  final double? crp;
  final double? egfr;

  bool get isMale => sex == 'm';
}

class BioAgeResult {
  const BioAgeResult({
    required this.bioAge,
    required this.deltaYears,
    required this.lifeExpectancy,
    required this.vo2max,
    required this.vo2Class,
    required this.fitnessAge,
    required this.rangeLow,
    required this.rangeHigh,
    required this.contributions,
    required this.activity,
  });

  final double bioAge;

  /// Biological minus chronological age (negative = younger).
  final double deltaYears;
  final double lifeExpectancy;
  final double vo2max;
  final String vo2Class;
  final double fitnessAge;
  final double rangeLow;
  final double rangeHigh;

  /// Years added (+) or removed (−) per factor.
  final Map<String, double> contributions;
  final BioAgeActivity activity;
}

/// Mortality doubles roughly every 8 years of age (Gompertz law).
final double gompertzB = math.log(2) / 8;

/// Correlated risk factors overlap; scale the summed log-HR down.
const _overlap = 0.6;

const _medianVo2Male = {
  25: 39.0,
  35: 37.0,
  45: 34.0,
  55: 30.5,
  65: 27.5,
  75: 24.5,
};
const _medianVo2Female = {
  25: 31.0,
  35: 29.0,
  45: 27.0,
  55: 24.0,
  65: 20.5,
  75: 18.5,
};

/// VO2max class thresholds per age band (Below Avg … Elite).
const _vo2ClassMale = {
  (20, 29): [31, 37, 42, 47, 53, 61],
  (30, 39): [29, 35, 40, 44, 49, 57],
  (40, 49): [26, 32, 37, 42, 47, 55],
  (50, 59): [23, 29, 33, 38, 43, 50],
  (60, 69): [20, 26, 30, 34, 39, 46],
  (70, 120): [17, 23, 27, 31, 36, 43],
};
const _vo2ClassFemale = {
  (20, 29): [24, 29, 34, 39, 44, 51],
  (30, 39): [22, 27, 32, 37, 42, 48],
  (40, 49): [20, 25, 30, 34, 39, 46],
  (50, 59): [17, 22, 27, 31, 35, 41],
  (60, 69): [15, 19, 23, 28, 32, 37],
  (70, 120): [13, 17, 21, 25, 29, 35],
};
const _vo2Labels = [
  'Below Avg',
  'Average',
  'Above Avg',
  'Good',
  'Excellent',
  'Elite',
];

/// Remaining life expectancy by age (period life tables).
const _lifeMale = <int, double>{
  0: 78.47,
  1: 77.73,
  2: 76.75,
  3: 75.77,
  4: 74.78,
  5: 73.79,
  6: 72.79,
  7: 71.8,
  8: 70.81,
  9: 69.81,
  10: 68.82,
  11: 67.83,
  12: 66.83,
  13: 65.84,
  14: 64.84,
  15: 63.85,
  16: 62.86,
  17: 61.88,
  18: 60.89,
  19: 59.92,
  20: 58.94,
  21: 57.97,
  22: 57.0,
  23: 56.02,
  24: 55.05,
  25: 54.07,
  26: 53.09,
  27: 52.12,
  28: 51.14,
  29: 50.17,
  30: 49.19,
  31: 48.22,
  32: 47.24,
  33: 46.27,
  34: 45.3,
  35: 44.34,
  36: 43.37,
  37: 42.41,
  38: 41.46,
  39: 40.5,
  40: 39.55,
  41: 38.6,
  42: 37.65,
  43: 36.71,
  44: 35.77,
  45: 34.83,
  46: 33.9,
  47: 32.97,
  48: 32.05,
  49: 31.14,
  50: 30.22,
  51: 29.32,
  52: 28.43,
  53: 27.54,
  54: 26.66,
  55: 25.78,
  56: 24.92,
  57: 24.07,
  58: 23.22,
  59: 22.39,
  60: 21.58,
  61: 20.77,
  62: 19.98,
  63: 19.21,
  64: 18.45,
  65: 17.71,
  66: 16.98,
  67: 16.26,
  68: 15.56,
  69: 14.86,
  70: 14.18,
  71: 13.51,
  72: 12.85,
  73: 12.2,
  74: 11.57,
  75: 10.94,
  76: 10.33,
  77: 9.73,
  78: 9.14,
  79: 8.56,
  80: 8.0,
  81: 7.47,
  82: 6.94,
  83: 6.43,
  84: 5.94,
  85: 5.47,
  86: 5.03,
  87: 4.61,
  88: 4.22,
  89: 3.87,
  90: 3.55,
  91: 3.25,
  92: 2.99,
  93: 2.76,
  94: 2.56,
  95: 2.37,
  96: 2.2,
  97: 2.06,
  98: 1.94,
  99: 1.86,
  100: 1.76,
};
const _lifeFemale = <int, double>{
  0: 83.19,
  1: 82.44,
  2: 81.45,
  3: 80.47,
  4: 79.47,
  5: 78.48,
  6: 77.49,
  7: 76.5,
  8: 75.5,
  9: 74.51,
  10: 73.51,
  11: 72.52,
  12: 71.52,
  13: 70.53,
  14: 69.53,
  15: 68.54,
  16: 67.55,
  17: 66.56,
  18: 65.57,
  19: 64.58,
  20: 63.6,
  21: 62.61,
  22: 61.62,
  23: 60.63,
  24: 59.64,
  25: 58.65,
  26: 57.66,
  27: 56.68,
  28: 55.69,
  29: 54.7,
  30: 53.71,
  31: 52.73,
  32: 51.74,
  33: 50.76,
  34: 49.78,
  35: 48.8,
  36: 47.82,
  37: 46.84,
  38: 45.86,
  39: 44.89,
  40: 43.92,
  41: 42.95,
  42: 41.99,
  43: 41.02,
  44: 40.06,
  45: 39.1,
  46: 38.14,
  47: 37.18,
  48: 36.23,
  49: 35.28,
  50: 34.34,
  51: 33.4,
  52: 32.47,
  53: 31.54,
  54: 30.61,
  55: 29.7,
  56: 28.78,
  57: 27.87,
  58: 26.97,
  59: 26.08,
  60: 25.19,
  61: 24.32,
  62: 23.45,
  63: 22.59,
  64: 21.74,
  65: 20.91,
  66: 20.08,
  67: 19.26,
  68: 18.45,
  69: 17.65,
  70: 16.86,
  71: 16.07,
  72: 15.3,
  73: 14.54,
  74: 13.79,
  75: 13.05,
  76: 12.32,
  77: 11.61,
  78: 10.92,
  79: 10.24,
  80: 9.57,
  81: 8.93,
  82: 8.3,
  83: 7.69,
  84: 7.1,
  85: 6.53,
  86: 6.0,
  87: 5.5,
  88: 5.04,
  89: 4.61,
  90: 4.21,
  91: 3.85,
  92: 3.53,
  93: 3.24,
  94: 2.99,
  95: 2.75,
  96: 2.55,
  97: 2.37,
  98: 2.22,
  99: 2.1,
  100: 2.0,
};

const _hba1cKnots = [5.4, 5.7, 6.4, 7.0, 8.0];
const _hba1cLnHr = [0.0, 0.09531, 0.22314, 0.43825, 0.61519];

double _ln(double x) => math.log(x);

/// Biological age from mortality hazard ratios: summed log-HR (scaled for
/// overlap) divided by the Gompertz slope gives the equivalent age shift.
BioAgeResult estimateBioAge(BioAgePerson p) {
  final vo2 = estimateVo2max(p);
  final activity =
      p.activity ??
      BioAgeActivity.fromWeekly(
        minutes: p.weeklyActivityMinutes,
        dailySteps: p.dailySteps,
      );
  final activityMinutes = activity.minutesForScore;
  final lnHr = <String, double>{
    'vo2max': _lnHrVo2max(vo2, p),
    if (p.gripKg != null) 'grip': _lnHrGrip(p.gripKg!, p.isMale),
    if (p.restingHr != null) 'resting_hr': (p.restingHr! - 60) / 10 * _ln(1.09),
    if (p.systolic != null)
      'blood_pressure': math.max(p.systolic! - 120, 0.0) / 10 * _ln(1.07),
    if (p.visceralFat != null)
      'visceral_fat': math.max(p.visceralFat! - 12, 0.0) * _ln(1.04),
    if (activityMinutes != null) 'activity': _lnHrActivity(activityMinutes),
    'smoking': _lnHrSmoking(p),
    if (p.alcoholGramsPerWeek != null)
      'alcohol': _lnHrAlcohol(p.alcoholGramsPerWeek!),
    'diabetes': _lnHrDiabetes(p.diabetes),
    if (p.hba1c != null) 'hba1c': _lnHrHba1c(p.hba1c!),
    if (p.ldl != null || p.hdl != null) 'lipids': _lnHrLipids(p),
    if (p.apob != null) 'apob': _lnHrApoB(p.apob!),
    if (p.crp != null && p.crp! > 1)
      'inflammation': (math.min(p.crp!, 5.0) - 1) / 2 * _ln(1.4),
    if (p.egfr != null) 'kidney_health': _lnHrEgfr(p.egfr!),
  };

  final total = lnHr.values.fold<double>(0.0, (a, b) => a + b) * _overlap;
  final delta = (total / gompertzB).clamp(-16.0, 12.0);
  final bioAge = p.age + delta;
  final remaining = math.max(
    _interpLifeExpectancy(p.age, p.isMale) - delta,
    0.5,
  );
  final vo2Class = classifyVo2max(vo2, p.age, p.isMale).$1;
  final fitnessAge = fitnessAgeFromNorms(vo2, p.isMale);

  double r1(double v) => double.parse(v.toStringAsFixed(1));
  return BioAgeResult(
    bioAge: r1(bioAge),
    deltaYears: r1(delta),
    lifeExpectancy: r1(p.age + remaining),
    vo2max: r1(vo2),
    vo2Class: vo2Class,
    fitnessAge: r1(fitnessAge),
    activity: activity,
    rangeLow: r1(bioAge - 4),
    rangeHigh: r1(bioAge + 4),
    contributions: lnHr.map(
      (k, v) => MapEntry(k, r1(v * _overlap / gompertzB)),
    ),
  );
}

/// Measured VO2max, or a non-exercise estimate from age, BMI and activity.
/// (Approximated regression shape.)
double estimateVo2max(BioAgePerson p) {
  if (p.vo2max != null && p.vo2max! > 0) return p.vo2max!;
  final bmi = p.bmi ?? 25.0;
  final activity = ((p.weeklyActivityMinutes ?? 0) / 100)
      .clamp(0.0, 4.0)
      .toDouble();
  final paIndex = math.sqrt(activity);
  if (p.isMale) {
    return 56.869 - 0.289 * p.age - 0.552 * (bmi - 25) + 5.863 * paIndex;
  }
  return 62.719 - 0.381 * p.age - 0.754 * (bmi - 25) + 10.987 * paIndex;
}

double computeFitnessAge(double vo2max, bool male) =>
    fitnessAgeFromNorms(vo2max, male);

/// Age at which [vo2max] is the population median (20–95).
double fitnessAgeFromNorms(double vo2max, bool male) {
  final table = male ? _medianVo2Male : _medianVo2Female;
  final ages = table.keys.toList()..sort();
  if (vo2max >= table[ages.first]!) {
    final slope = (table[ages.first]! - table[ages[1]]!) / 10;
    return (ages.first - (vo2max - table[ages.first]!) / slope).clamp(
      20.0,
      95.0,
    );
  }
  for (var i = 0; i < ages.length - 1; i++) {
    final hi = table[ages[i]]!, lo = table[ages[i + 1]]!;
    if (vo2max <= hi && vo2max >= lo) {
      return ages[i] + (hi - vo2max) / (hi - lo) * (ages[i + 1] - ages[i]);
    }
  }
  final last = ages.last;
  final slope = (table[ages[ages.length - 2]]! - table[last]!) / 10;
  return (last + (table[last]! - vo2max) / slope).clamp(20.0, 95.0);
}

(String, int) classifyVo2max(double vo2max, double age, bool male) {
  final thresholds = _ageGroup(age, male);
  var idx = -1;
  for (var i = 0; i < thresholds.length; i++) {
    if (vo2max >= thresholds[i]) idx = i;
  }
  return idx < 0 ? ('Poor', -1) : (_vo2Labels[idx], idx);
}

List<int> _ageGroup(double age, bool male) {
  final table = male ? _vo2ClassMale : _vo2ClassFemale;
  for (final entry in table.entries) {
    if (age >= entry.key.$1 && age <= entry.key.$2) return entry.value;
  }
  return age < 20 ? table.values.first : table.values.last;
}

double _interpLifeExpectancy(double age, bool male) {
  final table = male ? _lifeMale : _lifeFemale;
  if (age <= 0) return table[0]!;
  if (age >= 100) return table[100]!;
  final lo = age.floor();
  final frac = age - lo;
  return table[lo]! + (table[lo + 1]! - table[lo]!) * frac;
}

double _medianVo2max(double age, bool male) {
  final table = male ? _medianVo2Male : _medianVo2Female;
  final ages = table.keys.toList()..sort();
  if (age <= ages.first) {
    return table[ages.first]! + (ages.first - age) * 0.2;
  }
  if (age >= ages.last) {
    return math.max(table[ages.last]! - (age - ages.last) * 0.3, 8.0);
  }
  for (var i = 0; i < ages.length - 1; i++) {
    if (age >= ages[i] && age <= ages[i + 1]) {
      final t = (age - ages[i]) / (ages[i + 1] - ages[i]);
      return table[ages[i]]! + (table[ages[i + 1]]! - table[ages[i]]!) * t;
    }
  }
  return table[ages.last]!;
}

/// Each MET (3.5 ml/kg/min) above the age median lowers risk by 12 %.
double _lnHrVo2max(double vo2, BioAgePerson p) {
  final mets = ((vo2 - _medianVo2max(p.age, p.isMale)) / 3.5).clamp(-6.0, 6.0);
  return mets * _ln(0.88);
}

double _lnHrGrip(double grip, bool male) {
  final reference = male ? 45.0 : 28.0;
  final steps = ((grip - reference) / 5).clamp(-3.0, 3.0);
  return -steps * _ln(1.1);
}

/// The existing activity curve applied to a complete week's input. Reported
/// moderate minutes take priority over step-derived walking estimates per day.
double _lnHrActivity(double minutes) {
  return -0.15 * _ln(math.max(minutes / 600, 0.1));
}

double _lnHrSmoking(BioAgePerson p) {
  switch (p.smoking) {
    case 'former':
      final years = p.yearsSinceQuit ?? 0.0;
      return _ln(1.4) * math.max(0.0, 1 - years / 15);
    case 'current':
      final cigs = p.cigarettesPerDay ?? 15.0;
      return _ln(1.5 + 1.733333 * (cigs / 20));
    default:
      return 0.0;
  }
}

/// Up to 100 g/week mildly harmful, steeper beyond.
double _lnHrAlcohol(double grams) {
  if (grams <= 0) return 0.0;
  final low = math.min(grams, 100.0);
  final high = math.max(grams - 100, 0.0);
  return _ln(1.05) * low / 100 + _ln(1.14) * high / 100;
}

double _lnHrDiabetes(String type) {
  switch (type) {
    case 'prediabetes':
      return _ln(1.15);
    case 'type1':
      return _ln(1.8 * 1.1);
    case 'type2':
      return _ln(1.8);
    default:
      return 0.0;
  }
}

/// Piecewise-linear over clinical HbA1c thresholds; low values form the
/// left arm of the U-curve.
double _lnHrHba1c(double h) {
  if (h < 4.8) return ((4.8 - h) / 0.8).clamp(0.0, 0.8) * _ln(1.1);
  if (h <= _hba1cKnots.first) return 0.0;
  final v = h.clamp(5.4, 9.0);
  for (var i = 0; i < _hba1cKnots.length - 1; i++) {
    if (v <= _hba1cKnots[i + 1]) {
      final t = (v - _hba1cKnots[i]) / (_hba1cKnots[i + 1] - _hba1cKnots[i]);
      return _hba1cLnHr[i] + (_hba1cLnHr[i + 1] - _hba1cLnHr[i]) * t;
    }
  }
  // Beyond 8 %: extrapolate the last segment up to 9 %.
  return _hba1cLnHr.last + (v - 8.0) * 0.615190 / 8.0 * 2.2;
}

double _lnHrLipids(BioAgePerson p) {
  var lnHr = 0.0;
  final ldl = p.ldl;
  if (ldl != null && ldl > 100) lnHr += (ldl - 100) / 40 * _ln(1.2);
  final hdl = p.hdl;
  if (hdl != null && hdl < 45) lnHr += (45 - hdl) / 15 * _ln(1.15);
  return lnHr;
}

double _lnHrApoB(double apob) {
  final d = apob - 80;
  final v = d / 30 * _ln(1.34);
  return d < 0 ? math.max(v, -0.25) : math.min(v, _ln(3));
}

/// Kidney function: risk rises below an eGFR of 60, capped at 3×.
double _lnHrEgfr(double egfr) {
  if (egfr >= 60) return 0.0;
  final steps = ((60 - egfr) / 15).clamp(0.0, 3.0);
  return math.min(_ln(1.1) + steps * _ln(1.8) / 3, _ln(3));
}
