import 'package:fjelia/services/bio_age_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the HUNT means map back to the middle of their decade', () {
    expect(fitnessAgeFromNorms(54.4, true), closeTo(25, .01));
    expect(fitnessAgeFromNorms(49.1, true), closeTo(35, .01));
    expect(fitnessAgeFromNorms(42.6, true), closeTo(55, .01));
    expect(fitnessAgeFromNorms(43.0, false), closeTo(25, .01));
    expect(fitnessAgeFromNorms(34.4, false), closeTo(55, .01));
  });

  test('fit athletes get different ages, not all 20', () {
    final ages = [
      42.0,
      46.0,
      50.0,
      53.0,
    ].map((v) => fitnessAgeFromNorms(v, true)).toList();
    expect(ages.toSet(), hasLength(4));
    expect(ages, everyElement(greaterThan(20)));
    // Between the 30s and 40s mean: a man at 48 ml/kg/min is about 41.
    expect(fitnessAgeFromNorms(48, true), closeTo(40.8, .1));
  });

  test('beyond the table the mean decline carries on, within 20–95', () {
    // 2 ml above the 20s mean at 0.382 ml per year: about 20.
    expect(fitnessAgeFromNorms(56.3, true), closeTo(20, .2));
    expect(fitnessAgeFromNorms(65, true), 20);
    expect(fitnessAgeFromNorms(31.5, true), closeTo(84.9, .1));
    expect(fitnessAgeFromNorms(10, true), 95);
  });
}
