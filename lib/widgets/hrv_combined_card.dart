import '../l10n/l10n_ext.dart';
import '../l10n/formats.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../db/database.dart' show SpotHrvMeasurement;
import '../models/hrv_series.dart';
import '../models/spot_hrv.dart';
import '../providers/hrv_training_provider.dart';
import '../providers/polar_h10_provider.dart';
import '../screens/strain/activity_detail_sheet.dart';
import '../services/hrv/hrv_texts.dart';
import '../services/hrv/hrv_training_service.dart'
    show HrvSnapshot, hrvMeasurementUid;
import '../theme/hrv_colors.dart';
import 'app_widgets.dart';
import 'hrv_finish_prompt.dart';
import 'polar_h10_hrv_sheet.dart';

const _colors = {
  HrvSeries.sleep: hrvSleepColor,
  HrvSeries.before: hrvBeforeColor,
  HrvSeries.after: hrvAfterColor,
  HrvSeries.resting: hrvRestingColor,
};

const _surface = Color(0xFF262626);
const _grid = Color(0x14FFFFFF);

/// Overnight HRV and Polar H10 spot readings (before / after training,
/// resting) in one chart, with a tile per series that also acts as its
/// on/off switch.
class HrvCombinedCard extends ConsumerStatefulWidget {
  const HrvCombinedCard({
    super.key,
    required this.start,
    required this.end,
    required this.sleepPoints,
    this.average,
    this.averageLabel = 'Average',
  });

  final DateTime start, end;
  final List<ChartPoint> sleepPoints;

  /// Average of the overnight readings, drawn as a reference line.
  final double? average;
  final String averageLabel;

  @override
  ConsumerState<HrvCombinedCard> createState() => _State();
}

class _State extends ConsumerState<HrvCombinedCard> {
  final _hidden = <HrvSeries>{};
  // Seated is the default protocol; lying readings are another scale and
  // are not mixed in unless asked for.
  String _posture = 'seated';

  /// One line about a reading: position, length, quality and, when it belongs
  /// to a workout, the real delay against it.
  String _detail(SpotHrvMeasurement r, HrvSnapshot? snapshot) {
    final parts = [
      r.posture == 'supine' ? context.l10n.lying : context.l10n.enumSeated,
      '${(r.durationSeconds / 60).round()} min',
      if (r.qualityState == 'legacyUnverified')
        'older reading, quality not recorded',
    ];
    final id = snapshot?.episodeOfMeasurement(hrvMeasurementUid(r));
    final a = id == null ? null : snapshot!.assessments[id];
    if (a != null) {
      if (a.pre?.uid == hrvMeasurementUid(r) && a.preGap != null) {
        parts.add('ended ${hrvMinutes(a.preGap!)} before the workout');
      } else if (a.post?.uid == hrvMeasurementUid(r) && a.postDelay != null) {
        parts.add('${hrvMinutes(a.postDelay!)} after the workout');
      } else if (a.additionalPosts.any((m) => m.uid == hrvMeasurementUid(r))) {
        parts.add('extra reading after the workout');
      }
    } else if (r.context != 'resting') {
      parts.add('not assigned to a workout');
    }
    return parts.join(' · ');
  }

  /// A point that belongs to a workout opens that workout's card.
  Future<void> _open(String episodeId) async {
    final activity = await ref.read(episodeActivityProvider(episodeId).future);
    if (activity == null || !mounted) return;
    await showAppSheet(context, ActivityDetailSheet(activity: activity));
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref
        .watch(spotHrvWindowProvider((start: widget.start, end: widget.end)))
        .valueOrNull;
    final snapshot = ref.watch(hrvSnapshotProvider).valueOrNull;
    final all = buildHrvSeries(
      sleep: widget.sleepPoints,
      spot: [
        for (final r in rows ?? const [])
          SpotHrvPoint(
            at: r.startedAt,
            context: r.context,
            posture: r.posture,
            rmssdMs: r.rmssdMs,
            detail: _detail(r, snapshot),
            episodeId: snapshot?.episodeOfMeasurement(hrvMeasurementUid(r)),
          ),
      ],
      posture: _posture == 'all' ? null : _posture,
    );
    final visible = [
      for (final s in all)
        if (!_hidden.contains(s.series) && s.points.isNotEmpty) s,
    ];
    // The paired summary compares before with after, so it only stands while
    // both are shown.
    final showPairs =
        !_hidden.contains(HrvSeries.before) &&
        !_hidden.contains(HrvSeries.after);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Tiles(
          series: all,
          hidden: _hidden,
          onToggle: (s) => setState(
            () => _hidden.contains(s) ? _hidden.remove(s) : _hidden.add(s),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 12),
              side: const BorderSide(color: Color(0x1FFFFFFF)),
              foregroundColor: muted,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: const Color(0x3300D4A0),
            ),
            segments: [
              for (final p in SpotHrvPosture.values)
                ButtonSegment(value: p.name, label: Text(p.label)),
              ButtonSegment(value: 'all', label: Text(context.l10n.both)),
            ],
            selected: {_posture},
            onSelectionChanged: (v) => setState(() => _posture = v.first),
          ),
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          SizedBox(
            height: 180,
            child: EmptyState(context.l10n.noHrvReadingsInThis),
          )
        else
          SizedBox(
            height: 250,
            child: _Chart(
              start: widget.start,
              end: widget.end,
              series: visible,
              onOpen: _open,
              average: _hidden.contains(HrvSeries.sleep)
                  ? null
                  : widget.average,
              averageLabel: widget.averageLabel,
            ),
          ),
        if (widget.average != null && !_hidden.contains(HrvSeries.sleep))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(width: 16, height: 1.5, color: Colors.white38),
                const SizedBox(width: 6),
                Text(
                  context.l10n.averagelabelFixedMs(
                    widget.averageLabel,
                    widget.average!.fixed(0),
                  ),
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
              ],
            ),
          ),
        const HrvFinishPrompt(),
        if (showPairs) ...[
          const SizedBox(height: 14),
          _PairSummary(
            posture: _posture == 'all' ? null : _posture,
            from: widget.start,
            to: widget.end,
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0x2200D4A0),
              foregroundColor: mint,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => showAppSheet(context, const PolarH10HrvSheet()),
            icon: const Icon(Icons.monitor_heart_outlined, size: 18),
            label: Text(context.l10n.measureWithPolarH10),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.overnightHrvComesFromYour,
          style: TextStyle(color: muted, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }
}

/// One tile per series with its average and count; tapping hides or shows it.
class _Tiles extends StatelessWidget {
  const _Tiles({
    required this.series,
    required this.hidden,
    required this.onToggle,
  });
  final List<HrvSeriesData> series;
  final Set<HrvSeries> hidden;
  final ValueChanged<HrvSeries> onToggle;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 10.0;
      final width = (box.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final s in series)
            SizedBox(
              width: width,
              child: _Tile(
                data: s,
                off: hidden.contains(s.series),
                onTap: s.count == 0 ? null : () => onToggle(s.series),
              ),
            ),
        ],
      );
    },
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.data, required this.off, this.onTap});
  final HrvSeriesData data;
  final bool off;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colors[data.series]!;
    final empty = data.count == 0;
    final dim = off || empty;
    final average = data.average;
    final mixed = !empty && average == null;
    return Semantics(
      button: !empty,
      label:
          '${data.series.label}, ${empty
              ? 'no readings'
              : mixed
              ? '${data.count} readings in different positions, no average'
              : '${average!.round()} milliseconds, ${data.count} readings'}',
      child: Material(
        color: dim ? _surface : color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dim
                    ? const Color(0x1AFFFFFF)
                    : color.withValues(alpha: .55),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dim ? const Color(0x55FFFFFF) : color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.series.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: dim ? const Color(0x80FFFFFF) : muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      empty || mixed ? '—' : '${average!.round()}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: dim ? const Color(0x80FFFFFF) : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.ms,
                      style: TextStyle(
                        fontSize: 11,
                        color: dim ? const Color(0x66FFFFFF) : muted,
                      ),
                    ),
                  ],
                ),
                Text(
                  empty
                      ? context.l10n.noReadings
                      : mixed
                      ? '${data.count} readings · mixed positions'
                      : data.count == 1
                      ? '1 reading'
                      : '${data.count} readings',
                  style: TextStyle(
                    fontSize: 10,
                    color: dim ? const Color(0x66FFFFFF) : muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The paired change of the workouts in view: one pair per workout, from the
/// same assessment as the workout card. Never two sets of readings averaged
/// against each other.
class _PairSummary extends ConsumerWidget {
  const _PairSummary({
    required this.posture,
    required this.from,
    required this.to,
  });
  final String? posture;
  final DateTime from, to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref
        .watch(hrvPairSummaryProvider((posture: posture, from: from, to: to)))
        .valueOrNull;
    if (summary == null) return const SizedBox.shrink();
    if (summary.pairs == 0) {
      return Text(
        context.l10n.noWorkoutInThisPeriod,
        style: TextStyle(color: muted, fontSize: 12),
      );
    }
    final color = _colors[HrvSeries.after]!;
    final text =
        '${summary.pairs} comparable workout ${summary.pairs == 1 ? 'pair' : 'pairs'} · '
        'median change ${hrvSigned(summary.medianMs!)} ms '
        '(${hrvSigned(summary.medianPercent!)} %)';
    return Semantics(
      container: true,
      label: text,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            Icon(Icons.compare_arrows_rounded, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.textEachWorkoutCountsOnce(text),
                style: const TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.start,
    required this.end,
    required this.series,
    required this.average,
    required this.averageLabel,
    required this.onOpen,
  });
  final DateTime start, end;
  final List<HrvSeriesData> series;
  final ValueChanged<String> onOpen;
  final double? average;
  final String averageLabel;

  @override
  Widget build(BuildContext context) {
    final span = end.difference(start).inMinutes / 1440.0;
    double x(DateTime t) =>
        (t.difference(start).inMinutes / 1440.0).clamp(0, span).toDouble();
    final values = [
      for (final s in series)
        for (final p in s.points) p.value,
      ?average,
    ];
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final pad = ((high - low) * .18).clamp(4, 1000).toDouble();
    final minY = ((low - pad) / 5).floor() * 5.0;
    final maxY = ((high + pad) / 5).ceil() * 5.0;
    return LineChart(
      duration: const Duration(milliseconds: 250),
      LineChartData(
        minX: 0,
        maxX: span <= 0 ? 1 : span,
        minY: minY.clamp(0, 100000).toDouble(),
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) > 40 ? 10 : 5,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: _grid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (average != null)
              HorizontalLine(
                y: average!,
                color: Colors.white38,
                strokeWidth: 1,
                dashArray: const [5, 4],
              ),
          ],
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
              reservedSize: 32,
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (v, _) => Text(
                v.fixed(0),
                style: const TextStyle(fontSize: 10, color: muted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: (span / 3).clamp(1, 1000).toDouble(),
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  // The right edge is the end of the last day, so it carries
                  // that day's date and not the next one.
                  DateFormat.MMMd().format(
                    v >= span - .001
                        ? end.subtract(const Duration(days: 1))
                        : start.add(Duration(minutes: (v * 1440).round())),
                  ),
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            final spot = response?.lineBarSpots?.firstOrNull;
            if (spot == null) return;
            final data = series[spot.barIndex];
            final id = spot.spotIndex < data.episodeIds.length
                ? data.episodeIds[spot.spotIndex]
                : null;
            if (id != null) onOpen(id);
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2E2E2E),
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            getTooltipItems: (touched) => [
              for (final spot in touched)
                LineTooltipItem(
                  '${series[spot.barIndex].series.label}\n',
                  TextStyle(
                    color: _colors[series[spot.barIndex].series],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: '${spot.y.fixed(0)} ms',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text:
                          '\n${DateFormat.MMMd().add_Hm().format(series[spot.barIndex].points[spot.spotIndex].at)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (spot.spotIndex < series[spot.barIndex].details.length &&
                        series[spot.barIndex].details[spot.spotIndex] != null)
                      TextSpan(
                        text:
                            '\n${series[spot.barIndex].details[spot.spotIndex]}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        lineBarsData: [for (final s in series) _bar(s, x)],
      ),
    );
  }

  LineChartBarData _bar(HrvSeriesData s, double Function(DateTime) x) {
    final color = _colors[s.series]!;
    final sleep = s.series == HrvSeries.sleep;
    return LineChartBarData(
      spots: [for (final p in s.points) FlSpot(x(p.at), p.value)],
      color: color,
      // Overnight HRV is a continuous trend; spot readings are single points
      // and are drawn as rings only.
      barWidth: sleep ? 2.5 : 0,
      isCurved: sleep,
      curveSmoothness: .18,
      preventCurveOverShooting: true,
      belowBarData: BarAreaData(
        show: sleep,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .28), color.withValues(alpha: 0)],
        ),
      ),
      dotData: FlDotData(
        show: !sleep || s.count <= 20,
        getDotPainter: (spot, percent, bar, index) => sleep
            ? FlDotCirclePainter(radius: 2.5, color: color, strokeWidth: 0)
            : FlDotCirclePainter(
                radius: 5.5,
                color: _surface,
                strokeColor: color,
                strokeWidth: 3,
              ),
      ),
    );
  }
}
