import 'package:flutter/material.dart';
import 'metric_detail_sheet.dart';

class HrvSleepDetailSheet extends StatelessWidget {
  const HrvSleepDetailSheet({super.key, this.restingHr = false});
  final bool restingHr;
  @override
  Widget build(BuildContext context) => MetricDetailSheet(
    metric: restingHr ? HealthMetric.rhr : HealthMetric.hrv,
  );
}
