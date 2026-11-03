import 'package:flutter_test/flutter_test.dart';

import 'package:fjelia/models/bp_category.dart';

void main() {
  test('123/61 is normal, not elevated (ESH 2023)', () {
    expect(bpCategory(123, 61), BpCategory.normal);
  });

  test('categories by the higher of systolic and diastolic', () {
    expect(bpCategory(118, 76), BpCategory.optimal);
    expect(bpCategory(119, 81), BpCategory.normal);
    expect(bpCategory(132, 70), BpCategory.highNormal);
    expect(bpCategory(124, 87), BpCategory.highNormal);
    expect(bpCategory(141, 70), BpCategory.high);
    expect(bpCategory(128, 92), BpCategory.high);
  });

  test('limits belong to the higher category', () {
    expect(bpCategory(120, 60), BpCategory.normal);
    expect(bpCategory(130, 60), BpCategory.highNormal);
    expect(bpCategory(110, 90), BpCategory.high);
    expect(bpCategory(119.6, 79.4), BpCategory.optimal);
  });

  test('low only from a systolic under 90', () {
    expect(bpCategory(88, 55), BpCategory.low);
    expect(bpCategory(108, 58), BpCategory.optimal);
    // An athlete's low diastolic alone is not low.
    expect(bpCategory(123, 58), BpCategory.normal);
  });
}
