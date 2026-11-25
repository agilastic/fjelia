import 'package:fjelia_core/models/bp_category.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';

export 'package:fjelia_core/models/bp_category.dart';

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
