import 'package:fjelia/services/bio_age_activity.dart';
import 'package:fjelia/services/bio_age_service.dart';
import 'package:flutter_test/flutter_test.dart';

BioAgeResult _result({
  required double age,
  required double delta,
  required double lifeExpectancy,
  Map<String, double> contributions = const {},
}) => BioAgeResult(
  bioAge: age + delta,
  deltaYears: delta,
  lifeExpectancy: lifeExpectancy,
  vo2max: 45,
  vo2Class: 'Good',
  fitnessAge: 40,
  rangeLow: age + delta - 4,
  rangeHigh: age + delta + 4,
  contributions: contributions,
  activity: BioAgeActivity.fromWeekly(minutes: 200),
);

void main() {
  test('the lifespan is a band in five-year steps, never a year', () {
    final band = _result(age: 47, delta: -3, lifeExpectancy: 84.3).lifespanBand;
    expect(band, (low: 80, high: 90));
    expect(band.low % 5, 0);
    expect(band.high % 5, 0);
    expect(band.high - band.low, greaterThanOrEqualTo(10));
  });

  test('the band never starts at or before today', () {
    final band = _result(age: 88, delta: 4, lifeExpectancy: 91).lifespanBand;
    expect(band.low, greaterThan(88));
    expect(band.high, greaterThanOrEqualTo(band.low + 5));
  });

  test('the lean has five steps and no years', () {
    BioAgeLean lean(double d) =>
        _result(age: 40, delta: d, lifeExpectancy: 82).lean;
    expect(lean(-7), BioAgeLean.muchYounger);
    expect(lean(-2), BioAgeLean.younger);
    expect(lean(0.4), BioAgeLean.even);
    expect(lean(3), BioAgeLean.older);
    expect(lean(6), BioAgeLean.muchOlder);
  });

  test('factors say only which way they push, small ones are left out', () {
    final r = _result(
      age: 40,
      delta: -2,
      lifeExpectancy: 82,
      contributions: {
        'vo2max': -3.1,
        'resting_hr': -0.8,
        'blood_pressure': 1.2,
        'lipids': 2.4,
        'activity': 0.37,
      },
    );
    expect(r.pushes, [
      (factor: 'vo2max', push: FactorPush.helpsMuch),
      (factor: 'lipids', push: FactorPush.slowsMuch),
      (factor: 'blood_pressure', push: FactorPush.slows),
      (factor: 'resting_hr', push: FactorPush.helps),
    ]);
  });
}
