import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';

/// Blood pressure categories of the European Society of Hypertension (ESH
/// 2023), which the German Hypertension League follows. The higher of the
/// systolic and diastolic category counts. 123/61 is "normal"; the US
/// "elevated" (AHA, systolic 120–129) is not a European category.
/// Below 90 systolic it is "low": only relevant with dizziness. A diastolic
/// under 60 alone is common in endurance athletes and not called low.
enum BpCategory { low, optimal, normal, highNormal, high }

BpCategory bpCategory(num systolic, num diastolic) {
  int level(num v, List<num> from) => from.where((t) => v >= t).length;
  final s = level(systolic, const [120, 130, 140]);
  final d = level(diastolic, const [80, 85, 90]);
  final worst = math.max(s, d);
  if (worst == 0 && systolic < 90) return BpCategory.low;
  return BpCategory.values[worst + 1];
}

String bpCategoryLabel(BpCategory c) => switch (c) {
  BpCategory.low => tr.bpLow,
  BpCategory.optimal => tr.bpOptimal,
  BpCategory.normal => tr.normal,
  BpCategory.highNormal => tr.bpHighNormal,
  BpCategory.high => tr.high2,
};

Color bpCategoryColor(BpCategory c) => switch (c) {
  BpCategory.low => Colors.lightBlueAccent,
  BpCategory.optimal || BpCategory.normal => const Color(0xFFD3E96D),
  BpCategory.highNormal => Colors.amber,
  BpCategory.high => Colors.redAccent,
};
