import '../../l10n/formats.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/blood_pressure_insights_provider.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';

import 'package:intl/intl.dart';

import 'bp_variation_chart.dart';
import '../../utils/week.dart';
import '../../providers/week_start_provider.dart';

class BpScreen extends ConsumerStatefulWidget {
  const BpScreen({super.key});
  @override
  ConsumerState<BpScreen> createState() => _BpState();
}

class _BpState extends ConsumerState<BpScreen> {
  BpPeriod period = BpPeriod.day;
  int offset = 0;
  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final d = period == BpPeriod.month
        ? DateTime(selected.year, selected.month - offset)
        : DateTime(
            selected.year,
            selected.month,
            selected.day - offset * (period == BpPeriod.week ? 7 : 1),
          );
    final start = period == BpPeriod.month
        ? DateTime(d.year, d.month)
        : period == BpPeriod.week
        ? weekStartOf(d, mondayFirst: ref.watch(weekStartsOnMondayProvider))
        : d;
    final end = period == BpPeriod.month
        ? DateTime(start.year, start.month + 1)
        : DateTime(
            start.year,
            start.month,
            start.day + (period == BpPeriod.week ? 7 : 1),
          );
    final today = DateUtils.dateOnly(DateTime.now());
    final state = ref.watch(
      bloodPressureInsightsProvider((start: start, end: end, period: period)),
    );
    final bp = state.valueOrNull?.summary;
    final buckets = state.valueOrNull?.buckets ?? <BpVariationBucket>[];
    final periodLabel = period == BpPeriod.month
        ? DateFormat.yMMMM().format(start)
        : period == BpPeriod.week
        ? '${DateFormat.MMMd().format(start)} – ${DateFormat.MMMd().format(DateTime(end.year, end.month, end.day - 1))}'
        : DateUtils.isSameDay(d, today)
        ? context.l10n.today
        : dayText(d);
    return SheetPage(
      title: context.l10n.bloodPressureInsights,
      showBack: false,
      titleSize: 12,
      backgroundColor: panel,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 164,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(252, 152),
                  painter: _BpArc(systolic: bp?.avgSystolic),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      period == BpPeriod.week
                          ? context.l10n.weeklyAvg
                          : period == BpPeriod.month
                          ? context.l10n.monthlyAvg
                          : DateUtils.isSameDay(d, today)
                          ? "TODAY’S READING"
                          : dayText(d),
                      style: const TextStyle(
                        fontSize: 9,
                        color: muted,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      bp == null
                          ? '—/—'
                          : '${bp.avgSystolic.round()}/${bp.avgDiastolic.round()}',
                      style: const TextStyle(
                        color: Color(0xFFD3E96D),
                        fontSize: 39,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      bp == null
                          ? context.l10n.noMeasurements
                          : bp.avgSystolic >= 140
                          ? context.l10n.high2
                          : bp.avgSystolic >= 120
                          ? context.l10n.elevated
                          : context.l10n.normal,
                      style: const TextStyle(fontSize: 10, color: mint),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatPair(
                context.l10n.systolic2,
                bp == null ? '—' : '${bp.minSystolic}–${bp.maxSystolic}',
              ),
              StatPair(
                context.l10n.diastolic2,
                bp == null ? '—' : '${bp.minDiastolic}–${bp.maxDiastolic}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: [
                          for (final p in BpPeriod.values)
                            ChoiceChip(
                              label: Text(
                                p.name[0].toUpperCase() + p.name.substring(1),
                              ),
                              selected: period == p,
                              onSelected: (_) => setState(() {
                                period = p;
                                offset = 0;
                              }),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.horizontal_rule, color: mint, size: 18),
                    Text(
                      context.l10n.sys,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.horizontal_rule, color: Colors.orange, size: 18),
                    Text(
                      context.l10n.diaMmhg,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.previousBloodPressurePeriod,
                      onPressed: () => setState(() => offset++),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        periodLabel,
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.nextBloodPressurePeriod,
                      onPressed: offset == 0
                          ? null
                          : () => setState(() => offset--),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                if (state.isLoading)
                  const LinearProgressIndicator()
                else if (state.hasError)
                  DataError(state.error!)
                else
                  BpVariationChart(buckets: buckets, period: period),
              ],
            ),
          ),
          SectionCard(
            title: context.l10n.nightDipping,
            child: Text(
              bp?.nightDippingPercent == null
                  ? context.l10n.notEnoughDaytimeAndNighttime
                  : '${bp!.nightDippingPercent!.fixed(1)}% nocturnal BP reduction',
              style: const TextStyle(color: mint),
            ),
          ),
        ],
      ),
    );
  }
}

class _BpArc extends CustomPainter {
  _BpArc({this.systolic});
  final double? systolic;
  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromLTWH(5, 10, s.width - 10, (s.width - 10));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    for (var i = 0; i < 4; i++) {
      p.color = const [
        Color(0xFF50C3A7),
        Color(0xFFA8CE58),
        Color(0xFFFFD15C),
        Color(0xFFF46D75),
      ][i];
      c.drawArc(rect, math.pi + i * math.pi / 4, math.pi / 4 - .025, false, p);
    }
    if (systolic != null) {
      final angle = math.pi + math.pi * ((systolic! - 90) / 90).clamp(0, 1),
          r = rect.width / 2;
      c.drawLine(
        rect.center +
            Offset(math.cos(angle) * (r - 14), math.sin(angle) * (r - 14)),
        rect.center +
            Offset(math.cos(angle) * (r + 9), math.sin(angle) * (r + 9)),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BpArc oldDelegate) =>
      oldDelegate.systolic != systolic;
}
