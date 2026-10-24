import '../models/health_metric.dart';
import '../providers/metric_history_provider.dart';
export '../models/health_metric.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/day_data_provider.dart';
import 'app_widgets.dart';
import 'hrv_combined_card.dart';
import '../screens/activities/load_visuals.dart';

class MetricDetailSheet extends ConsumerStatefulWidget {
  const MetricDetailSheet({super.key, required this.metric});
  final HealthMetric metric;
  static Future<void> show(BuildContext context, HealthMetric metric) =>
      showLoadSheet(
        context,
        MetricDetailSheet(metric: metric),
        height: metric.isBody ? .62 : .78,
      );
  @override
  ConsumerState<MetricDetailSheet> createState() => _MetricDetailState();
}

class _MetricDetailState extends ConsumerState<MetricDetailSheet> {
  int days = 14, offset = 0;
  @override
  void initState() {
    super.initState();
    if (widget.metric.isBody) {
      days =
          widget.metric == HealthMetric.muscle ||
              widget.metric == HealthMetric.bmi
          ? 90
          : 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final data = ref.watch(
      metricHistoryWindowProvider((
        metric: widget.metric,
        days: days,
        offset: offset,
        selected: selected,
      )),
    );
    return SheetPage(
      title: widget.metric.label.toUpperCase(),
      showHeader: false,
      backgroundColor: panel,
      child: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DataError(
          e,
          retry: () => ref.invalidate(metricHistoryProvider(widget.metric)),
        ),
        data: (window) {
          final start = window.start, end = window.end;
          final points = window.points, latest = window.latest;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatPair(
                    widget.metric.label.toUpperCase(),
                    '${valueText(latest?.value, widget.metric.isBody || [HealthMetric.skinTemperature, HealthMetric.respiration, HealthMetric.sleep].contains(widget.metric) ? 1 : 0)} ${widget.metric.unit}',
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$days D AVG',
                        style: const TextStyle(color: muted, fontSize: 9),
                      ),
                      Text(
                        '${valueText(window.average, 1)} ${widget.metric.unit}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.metric == HealthMetric.hrv
                            ? '7D BASELINE'
                            : widget.metric == HealthMetric.rhr
                            ? '30D AVG'
                            : 'ALL-TIME',
                        style: const TextStyle(color: muted, fontSize: 9),
                      ),
                      Text(
                        '${valueText(window.baseline, 1)} ${widget.metric.unit}',
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.metric.directionHint case final String hint)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 12, color: muted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          hint,
                          style: const TextStyle(fontSize: 10, color: muted),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final range in {
                    14: widget.metric.isBody ? '14D' : '14 Days',
                    30: widget.metric.isBody ? 'M' : '30 Days',
                    if (widget.metric.isBody) 90: 'Q',
                    if (widget.metric.isBody) 365: 'Y',
                  }.entries)
                    ChoiceChip(
                      label: Text(range.value),
                      selected: days == range.key,
                      onSelected: (_) => setState(() {
                        days = range.key;
                        offset = 0;
                      }),
                    ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous period',
                    onPressed: () => setState(() => offset += days),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      offset == 0
                          ? days == 90
                                ? 'Last 3 months'
                                : days == 365
                                ? 'Last year'
                                : 'Last $days days'
                          : '${dayText(start)} – ${dayText(DateTime(end.year, end.month, end.day - 1))}',
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next period',
                    onPressed: offset == 0
                        ? null
                        : () => setState(
                            () => offset = (offset - days).clamp(0, 100000),
                          ),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              HistoryChart(
                points: points,
                bars: widget.metric == HealthMetric.steps,
                minY: window.range.minimum,
                maxY: window.range.maximum,
                color: widget.metric.isBody
                    ? const Color(0xFF7D8CFF)
                    : Colors.lightBlue,
                referenceLine: widget.metric.isBody ? null : window.average,
                height: 240,
              ),
              if (!widget.metric.isBody)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LoadLegend('${days}D average', mint, line: true),
                ),
              if (widget.metric == HealthMetric.hrv)
                HrvCombinedCard(
                  start: start,
                  end: end,
                  sleepPoints: points,
                ),
              if (widget.metric == HealthMetric.hrv)
                const SectionCard(
                  child: Text(
                    'Overnight HRV reflects recovery. Compare your readings with your own baseline over time.',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
