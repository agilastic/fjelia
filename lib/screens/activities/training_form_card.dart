import '../../l10n/l10n_ext.dart';

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';
import 'load_visuals.dart';

class TrainingFormCard extends ConsumerStatefulWidget {
  const TrainingFormCard({
    super.key,
    this.fullscreen = false,
    this.initialDays = 60,
    this.onDaysChanged,
    this.onClose,
  });
  final int initialDays;
  final bool fullscreen;
  final ValueChanged<int>? onDaysChanged;
  final VoidCallback? onClose;
  @override
  ConsumerState<TrainingFormCard> createState() => _FormState();
}

class _FormState extends ConsumerState<TrainingFormCard> {
  late int days = widget.initialDays;
  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final end = DateTime(selected.year, selected.month, selected.day + 1);
    final start = DateTime(
      selected.year,
      selected.month,
      selected.day - days + 1,
    );
    final history = ref.watch(trainingFormSeriesProvider);
    final points = (history.valueOrNull ?? [])
        .where((p) => !p.date.isBefore(start) && p.date.isBefore(end))
        .toList();
    final last = points.lastOrNull;
    final colors = [loadBlue, loadRed, mint];
    final status = !history.hasValue && history.isLoading
        ? context.l10n.loading2
        : !history.hasValue && history.hasError
        ? context.l10n.unavailable
        : formStatus(last?.tsb);
    final statusColor = last == null
        ? muted
        : last.tsb > 5
        ? mint
        : last.tsb < -10
        ? loadRed
        : loadOrange;
    final screen = MediaQuery.sizeOf(context);
    final chartHeight = widget.fullscreen
        ? screen.width > screen.height
              ? screen.height * .55
              : screen.height * .42
        : 150.0;
    return LoadCard(
      color: loadInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.formAtlCtlTsb2,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFBBBBBB),
                    letterSpacing: .7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.fullscreen)
                IconButton(
                  tooltip: context.l10n.closeTrainingFormFullscreen,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 20, color: muted),
                  onPressed: widget.onClose ?? () => Navigator.pop(context),
                )
              else
                IconButton(
                  tooltip: context.l10n.expandTrainingForm,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 30,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.fullscreen, size: 18, color: muted),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => _TrainingFormFullscreenPage(
                        initialDays: days,
                        onDaysChanged: (value) {
                          if (mounted) setState(() => days = value);
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final n in [14, 30, 60, 90, 180, 365])
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ChoiceChip(
                      label: Text(_trainingRangeLabel(n)),
                      selected: days == n,
                      onSelected: (_) {
                        setState(() => days = n);
                        widget.onDaysChanged?.call(n);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      selectedColor: loadBlue.withValues(alpha: .2),
                      backgroundColor: loadInset,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: days == n ? loadBlue : muted,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: days == n
                            ? loadBlue.withValues(alpha: .45)
                            : Colors.white12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final stat in [
                ('CTL', last?.ctl, colors[0]),
                ('ATL', last?.atl, colors[1]),
                ('TSB', last?.tsb, statusColor),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stat.$1, style: loadCaption),
                      Text(
                        valueText(stat.$2),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: stat.$3,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: LoadBadge(status, color: statusColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (history.isLoading && !history.hasValue)
            SizedBox(
              height: chartHeight,
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (history.hasError && !history.hasValue)
            DataError(
              history.error!,
              retry: () => ref.invalidate(trainingFormSeriesProvider),
            )
          else if (points.isEmpty)
            EmptyState(context.l10n.noTrainingHistory)
          else
            SizedBox(
              height: chartHeight,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (days - 1).toDouble(),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Colors.white10, strokeWidth: .6),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        minIncluded: false,
                        maxIncluded: false,
                        getTitlesWidget: (v, _) => Text(
                          valueText(v),
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 25,
                        interval: days / 4,
                        minIncluded: true,
                        maxIncluded: true,
                        getTitlesWidget: (v, _) => Text(
                          DateFormat.Md().format(
                            DateTime(
                              start.year,
                              start.month,
                              start.day + v.round(),
                            ),
                          ),
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    for (var i = 0; i < 3; i++)
                      LineChartBarData(
                        color: colors[i],
                        barWidth: i == 0 ? 2.5 : 1.5,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        belowBarData: BarAreaData(
                          show: i == 0,
                          color: loadBlue.withValues(alpha: .045),
                        ),
                        dashArray: i == 2 ? [5, 4] : null,
                        dotData: FlDotData(show: points.length == 1),
                        spots: [
                          for (final p in points)
                            FlSpot(
                              DateTime.utc(
                                    p.date.year,
                                    p.date.month,
                                    p.date.day,
                                  )
                                  .difference(
                                    DateTime.utc(
                                      start.year,
                                      start.month,
                                      start.day,
                                    ),
                                  )
                                  .inDays
                                  .toDouble(),
                              i == 0
                                  ? p.ctl
                                  : i == 1
                                  ? p.atl
                                  : p.tsb,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 5,
            children: [
              LoadLegend(context.l10n.fitnessCtl, loadBlue),
              LoadLegend(context.l10n.fatigueAtl, loadRed),
              LoadLegend(context.l10n.formTsb, mint),
            ],
          ),
          if (last?.historyStart != null) ...[
            const SizedBox(height: 8),
            Tooltip(
              message: context.l10n.calculatedFromTheFirstAvailable,
              child: Text(
                'History since ${DateFormat.yMMMd().format(last!.historyStart!)}${last.historyDays! < 42 ? ' · building baseline' : ''}',
                style: loadCaption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _trainingRangeLabel(int days) => switch (days) {
  90 => '3mo',
  180 => '6mo',
  365 => '1y',
  _ => '${days}d',
};

class _TrainingFormFullscreenPage extends StatefulWidget {
  const _TrainingFormFullscreenPage({
    required this.initialDays,
    required this.onDaysChanged,
  });

  final int initialDays;
  final ValueChanged<int> onDaysChanged;

  @override
  State<_TrainingFormFullscreenPage> createState() =>
      _TrainingFormFullscreenPageState();
}

class _TrainingFormFullscreenPageState
    extends State<_TrainingFormFullscreenPage> {
  static const _portrait = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];
  static const _chartOrientations = [
    ..._portrait,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setPreferredOrientations(_chartOrientations));
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations(_portrait));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: loadSurface,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
        child: TrainingFormCard(
          fullscreen: true,
          initialDays: widget.initialDays,
          onDaysChanged: widget.onDaysChanged,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );
}

// Form status label thresholds.
String formStatus(double? tsb) => tsb == null
    ? tr.noHistory
    : tsb > 15
    ? tr.fresh
    : tsb > 5
    ? tr.optimal
    : tsb > -10
    ? tr.neutral
    : tsb > -20
    ? tr.tired
    : tr.veryFatigued;
