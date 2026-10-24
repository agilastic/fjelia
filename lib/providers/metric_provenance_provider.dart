import '../db/database.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/metric_provenance.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';

final metricProvenanceProvider =
    FutureProvider.family<
      Map<String, MetricProvenance>,
      ({SummaryKind kind, DateTime date})
    >((ref, request) async {
      ref.watch(syncStatusListenerProvider);
      final table = switch (request.kind) {
        SummaryKind.recovery => 'hrv_records',
        SummaryKind.sleep => 'sleep_records',
        SummaryKind.wellness => 'wellness_records',
      };
      final rows = await ref
          .watch(databaseProvider)
          .getMetricOrigins(table, request.date);
      return {
        for (final e in rows.entries)
          e.key: MetricProvenance(
            source: e.value.source,
            quality: e.value.quality,
            updatedAt: e.value.updatedAt,
          ),
      };
    });
