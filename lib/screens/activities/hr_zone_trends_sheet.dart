import 'dart:math' as math;

import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/fjelia_edition_provider.dart';
import '../../providers/hr_zone_trends_provider.dart';
import '../settings/fjelia_pro_sheet.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';
import 'load_visuals.dart';

/// Zone colours that stay apart for most kinds of colour blindness, and a
/// grey for time without heart rate. Every chart also names its zones in
/// text, so colour is never the only cue.
const hrZoneColors = [
  Color(0xFF9AA5B1),
  Color(0xFF4BC0EB),
  Color(0xFF3CC18A),
  Color(0xFFFFB020),
  Color(0xFFE0457B),
];
Color get _missingColor => duo(0x55FFFFFF, 0x33000000);

/// "1 h 05 min" or "45 min".
String hrZoneDuration(double seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} min';
}

String _signed(double seconds) =>
    '${seconds >= 0 ? '+' : '−'}${hrZoneDuration(seconds.abs())}';

String _relative(double? r) =>
    r == null ? '—' : '${r >= 0 ? '+' : '−'}${(r.abs() * 100).round()} %';

/// FjeliaPro: how the time in Z1–Z5 changes over weeks and months, against
/// the plan (fjelia_pro_hr_zone_trends_requirements).
class HrZoneTrendsSheet extends ConsumerStatefulWidget {
  const HrZoneTrendsSheet({super.key});

  @override
  ConsumerState<HrZoneTrendsSheet> createState() => _HrZoneTrendsSheetState();
}

class _HrZoneTrendsSheetState extends ConsumerState<HrZoneTrendsSheet> {
  String _window = '28';
  bool _share = false;
  String? _sport;
  int? _selected;
  bool _perZone = false;
  String _planWeek = 'this';

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  ({DateTime from, DateTime to, HrZoneGrouping grouping}) get _range {
    final to = DateTime(_today.year, _today.month, _today.day + 1);
    return switch (_window) {
      '7' => (
        from: DateTime(to.year, to.month, to.day - 7),
        to: to,
        grouping: HrZoneGrouping.day,
      ),
      '90' => (
        from: DateTime(to.year, to.month, to.day - 90),
        to: to,
        grouping: HrZoneGrouping.week,
      ),
      '12' => (
        from: DateTime(_today.year, _today.month - 11),
        to: to,
        grouping: HrZoneGrouping.month,
      ),
      _ => (
        from: DateTime(to.year, to.month, to.day - 28),
        to: to,
        grouping: HrZoneGrouping.week,
      ),
    };
  }

  String _sportName(String sport) => switch (sport) {
    'running' => context.l10n.running,
    'cycling' => context.l10n.cycling,
    'swimming' => context.l10n.swimming,
    _ => context.l10n.hrZoneOtherSports,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final workouts = ref.watch(hrZoneWorkoutsProvider);
    final planned = ref.watch(hrZonePlannedProvider).valueOrNull ?? const [];
    return LoadSheet(
      close: true,
      title: l.hrZoneTrendsTitle,
      child: workouts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => EmptyState(l.hrZoneEmpty),
        data: (all) => _content(all, planned),
      ),
    );
  }

  Widget _content(List<HrZoneWorkout> all, List<PlannedZoneSession> planned) {
    final l = context.l10n;
    final sports = {for (final w in all) w.sport}.toList()..sort();
    final r = _range;
    final periods = hrZoneTrends.periods(
      all,
      from: r.from,
      to: r.to,
      grouping: r.grouping,
      sport: _sport,
    );
    final selected = _selected != null && _selected! < periods.length
        ? _selected!
        : periods.lastIndexWhere((p) => p.totals.workouts > 0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            LoadRange(
              labels: const ['7', '28', '90', '12'],
              display: {
                '7': l.hrZoneWindowDays(7),
                '28': l.hrZoneWindowDays(28),
                '90': l.hrZoneWindowDays(90),
                '12': l.hrZoneWindowMonths(12),
              },
              selected: _window,
              onChanged: (v) => setState(() {
                _window = v;
                _selected = null;
              }),
            ),
            LoadRange(
              labels: const ['time', 'share'],
              display: {'time': l.hrZoneUnitTime, 'share': l.hrZoneUnitShare},
              selected: _share ? 'share' : 'time',
              segmented: true,
              onChanged: (v) => setState(() => _share = v == 'share'),
            ),
          ],
        ),
        if (sports.length > 1) ...[
          const SizedBox(height: 10),
          LoadRange(
            labels: ['all', ...sports],
            display: {
              'all': l.hrZoneAllSports,
              for (final s in sports) s: _sportName(s),
            },
            selected: _sport ?? 'all',
            onChanged: (v) => setState(() {
              _sport = v == 'all' ? null : v;
              _selected = null;
            }),
          ),
        ],
        const SizedBox(height: 14),
        _Legend(share: _share),
        const SizedBox(height: 8),
        if (periods.every((p) => p.totals.workouts == 0))
          EmptyState(l.hrZoneEmpty)
        else ...[
          _Chart(
            periods: periods,
            grouping: r.grouping,
            share: _share,
            selected: selected,
            phases: _phases(periods, planned, r.grouping),
            onSelect: (i) => setState(() => _selected = i),
          ),
          const SizedBox(height: 4),
          Text(l.hrZoneTapHint, style: loadCaption),
          if (selected >= 0) ...[
            const SizedBox(height: 12),
            _PeriodDetail(period: periods[selected], grouping: r.grouping),
          ],
        ],
        const SizedBox(height: 16),
        _Comparison(
          comparison: hrZoneTrends.compare28(all, today: _today, sport: _sport),
          perZone: _perZone,
          onPerZone: () => setState(() => _perZone = !_perZone),
        ),
        const SizedBox(height: 16),
        _PlanCard(
          week: _planWeek,
          onWeek: (w) => setState(() => _planWeek = w),
          comparison: _planComparison(all, planned),
        ),
        const SizedBox(height: 16),
        Text(l.hrZoneHistoricalNote, style: loadCaption),
      ],
    );
  }

  HrZonePlanComparison _planComparison(
    List<HrZoneWorkout> all,
    List<PlannedZoneSession> planned,
  ) {
    final monday = DateTime(
      _today.year,
      _today.month,
      _today.day - (_today.weekday - 1),
    );
    final from = _planWeek == 'this'
        ? monday
        : DateTime(monday.year, monday.month, monday.day - 7);
    // This week only up to today: the rest of it is not done yet.
    final to = _planWeek == 'this'
        ? DateTime(_today.year, _today.month, _today.day + 1)
        : monday;
    return hrZoneTrends.planVsActual(
      planned,
      all,
      from: from,
      to: to,
      sport: _sport,
    );
  }

  /// The plan phase of each week: the most frequent one of its sessions.
  List<String?> _phases(
    List<HrZonePeriod> periods,
    List<PlannedZoneSession> planned,
    HrZoneGrouping grouping,
  ) => [
    for (final p in periods)
      if (grouping != HrZoneGrouping.week)
        null
      else
        () {
          final counts = <String, int>{};
          for (final s in planned) {
            if (s.phase == null ||
                s.date.isBefore(p.start) ||
                !s.date.isBefore(p.end)) {
              continue;
            }
            counts[s.phase!] = (counts[s.phase!] ?? 0) + 1;
          }
          if (counts.isEmpty) return null;
          return counts.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
        }(),
  ];
}

class _Legend extends StatelessWidget {
  const _Legend({required this.share});
  final bool share;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 6,
    children: [
      for (var i = 0; i < hrZoneCount; i++)
        LoadLegend('Z${i + 1}', hrZoneColors[i]),
      if (!share) LoadLegend(context.l10n.hrZoneNoHr, _missingColor),
    ],
  );
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.periods,
    required this.grouping,
    required this.share,
    required this.selected,
    required this.phases,
    required this.onSelect,
  });
  final List<HrZonePeriod> periods;
  final HrZoneGrouping grouping;
  final bool share;
  final int selected;
  final List<String?> phases;
  final ValueChanged<int> onSelect;

  String _label(DateTime d) => switch (grouping) {
    HrZoneGrouping.day => DateFormat.E().format(d),
    HrZoneGrouping.week => DateFormat.MMMd().format(d),
    HrZoneGrouping.month => DateFormat.MMM().format(d),
  };

  String _phase(BuildContext context, String phase) => switch (phase) {
    'base' => context.l10n.phaseBase,
    'build' => context.l10n.phaseBuild,
    'peak' => context.l10n.phasePeak,
    'taper' => context.l10n.phaseTaper,
    'recovery' => context.l10n.phaseRecovery,
    'race' => context.l10n.phaseRace,
    _ => phase.toUpperCase(),
  };

  /// A round step for about four lines up to [top] hours.
  static double _step(double top) {
    for (final s in const [0.25, 0.5, 1.0, 2.0, 3.0, 5.0, 10.0, 20.0, 50.0]) {
      if (top / s <= 5) return s;
    }
    return 100;
  }

  /// Segment heights of one bar: Z1–Z5 and, in hours, the missing time.
  List<double> _values(HrZoneTotals t) => share
      ? [for (final s in t.zoneShares) s * 100]
      : [for (final s in t.zoneSeconds) s / 3600, t.missingSeconds / 3600];

  @override
  Widget build(BuildContext context) {
    final values = [for (final p in periods) _values(p.totals)];
    final top = share
        ? 100.0
        : math.max(
            0.5,
            values.map((v) => v.fold(0.0, (a, b) => a + b)).fold(0.0, math.max),
          );
    final hasPhases = phases.any((p) => p != null);
    return Semantics(
      label: [
        for (var i = 0; i < periods.length; i++)
          '${_label(periods[i].start)}: '
              '${[for (var z = 0; z < hrZoneCount; z++) 'Z${z + 1} ${share ? '${values[i][z].round()} %' : hrZoneDuration(periods[i].totals.zoneSeconds[z])}'].join(', ')}',
      ].join('; '),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: top * 1.05,
            minY: 0,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: share ? 25 : _step(top),
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: fjInk12, strokeWidth: .6),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              enabled: true,
              handleBuiltInTouches: false,
              touchCallback: (event, response) {
                final spot = response?.spot;
                if (event is FlTapUpEvent && spot != null) {
                  onSelect(spot.touchedBarGroupIndex);
                }
              },
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(),
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: hasPhases,
                  reservedSize: hasPhases ? 18 : 0,
                  getTitlesWidget: (x, meta) {
                    final i = x.toInt();
                    final phase = i >= 0 && i < phases.length
                        ? phases[i]
                        : null;
                    // A phase is named where it starts.
                    if (phase == null || (i > 0 && phases[i - 1] == phase)) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        _phase(context, phase),
                        style: loadCaption.copyWith(fontSize: 8),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  // Four steps: labels never crowd near zero.
                  interval: share ? 25 : _step(top),
                  getTitlesWidget: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      share
                          ? '${v.round()}%'
                          : '${valueText(v, v < 2 ? 1 : 0)}h',
                      style: loadCaption.copyWith(fontSize: 9),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (x, meta) {
                    final i = x.toInt();
                    if (i < 0 || i >= periods.length) {
                      return const SizedBox.shrink();
                    }
                    // Every label where there is room for it.
                    final step = (periods.length / 7).ceil();
                    if (i % step != 0 && i != periods.length - 1) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        _label(periods[i].start),
                        style: loadCaption.copyWith(fontSize: 9),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < periods.length; i++)
                _group(i, values[i], periods[i].partial, i == selected),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _group(int i, List<double> v, bool partial, bool on) {
    final colors = [...hrZoneColors, _missingColor];
    // A period not complete is lighter: its totals are not a full one.
    final alpha = partial ? .55 : 1.0;
    var y = 0.0;
    final items = <BarChartRodStackItem>[];
    for (var k = 0; k < v.length; k++) {
      if (v[k] <= 0) continue;
      items.add(
        BarChartRodStackItem(
          y,
          y + v[k],
          colors[k].withValues(alpha: colors[k].a * alpha),
        ),
      );
      y += v[k];
    }
    return BarChartGroupData(
      x: i,
      barRods: [
        BarChartRodData(
          toY: y,
          width: periods.length > 20 ? 8 : 16,
          rodStackItems: items,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          borderSide: on
              ? BorderSide(color: fjInk, width: 1.2)
              : BorderSide.none,
        ),
      ],
    );
  }
}

class _PeriodDetail extends StatelessWidget {
  const _PeriodDetail({required this.period, required this.grouping});
  final HrZonePeriod period;
  final HrZoneGrouping grouping;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = period.totals;
    final last = DateTime(
      period.end.year,
      period.end.month,
      period.end.day - 1,
    );
    final title = grouping == HrZoneGrouping.day
        ? DateFormat.yMMMEd().format(period.start)
        : '${DateFormat.MMMd().format(period.start)} – '
              '${DateFormat.yMMMd().format(last)}';
    return LoadCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < hrZoneCount; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  LoadLegend('Z${i + 1}', hrZoneColors[i]),
                  const Spacer(),
                  Text(
                    '${hrZoneDuration(t.zoneSeconds[i])}  ·  '
                    '${(t.zoneShares[i] * 100).round()} %',
                    style: TextStyle(
                      fontSize: 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: fjInk,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            l.hrZoneDetail(
              hrZoneDuration(t.coveredSeconds),
              hrZoneDuration(t.elapsedSeconds),
              (t.coverage * 100).round(),
            ),
            style: loadCaption,
          ),
          Text(l.hrZoneWorkouts(t.workouts), style: loadCaption),
          if (period.partial) Text(l.hrZonePartial, style: loadCaption),
          if (t.mixedSports) Text(l.hrZoneMixedSports, style: loadCaption),
        ],
      ),
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({
    required this.comparison,
    required this.perZone,
    required this.onPerZone,
  });
  final HrZoneComparison comparison;
  final bool perZone;
  final VoidCallback onPerZone;

  String _observation(BuildContext context, HrZoneObservation o) {
    final l = context.l10n;
    final pct = ((comparison.duration.relative ?? 0).abs() * 100).round();
    return switch (o) {
      HrZoneObservation.insufficientData => l.hrZoneObsInsufficient,
      HrZoneObservation.volumeUp => l.hrZoneObsVolumeUp(pct),
      HrZoneObservation.volumeDown => l.hrZoneObsVolumeDown(pct),
      HrZoneObservation.volumeSteady => l.hrZoneObsVolumeSteady,
      HrZoneObservation.hardUpWithVolumeUp => l.hrZoneObsHardUpVolumeUp,
      HrZoneObservation.hardUpWithVolumeDown => l.hrZoneObsHardUpVolumeDown,
      HrZoneObservation.hardUpWithVolumeSteady => l.hrZoneObsHardUpVolumeSteady,
      HrZoneObservation.hardDown => l.hrZoneObsHardDown,
      HrZoneObservation.easyShareUp => l.hrZoneObsEasyShareUp,
      HrZoneObservation.easyShareDown => l.hrZoneObsEasyShareDown,
      HrZoneObservation.middleUp => l.hrZoneObsMiddleUp,
      HrZoneObservation.middleDown => l.hrZoneObsMiddleDown,
      HrZoneObservation.coverageChanged => l.hrZoneObsCoverage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = comparison;
    final rows = <(String, HrZoneChange)>[
      (l.hrZoneTrainingTime, c.duration),
      ('Z1+Z2', c.easy),
      ('Z3', c.middle),
      ('Z4+Z5', c.hard),
      if (perZone)
        for (var i = 0; i < hrZoneCount; i++) ('  Z${i + 1}', c.zone(i)),
    ];
    final style = TextStyle(
      fontSize: 12,
      color: fjInk,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return LoadCard(
      title: l.hrZoneCompareTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Table(
            columnWidths: const {0: FlexColumnWidth(1.4)},
            children: [
              for (final (label, change) in rows)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(label, style: style),
                    ),
                    Text(hrZoneDuration(change.previous), style: style),
                    Text(hrZoneDuration(change.recent), style: style),
                    Text(
                      '${_signed(change.delta)}\n${_relative(change.relative)}',
                      style: style.copyWith(color: muted, fontSize: 11),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${l.hrZoneCoverageLabel}: '
            '${(c.previous.coverage * 100).round()} % → '
            '${(c.recent.coverage * 100).round()} %',
            style: loadCaption,
          ),
          TextButton(onPressed: onPerZone, child: Text(l.hrZonePerZone)),
          for (final o in c.observations)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${_observation(context, o)}', style: style),
            ),
          const SizedBox(height: 4),
          Text(l.hrZoneObservationsNote, style: loadCaption),
          if (c.recent.mixedSports || c.previous.mixedSports)
            Text(l.hrZoneMixedSports, style: loadCaption),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.week,
    required this.onWeek,
    required this.comparison,
  });
  final String week;
  final ValueChanged<String> onWeek;
  final HrZonePlanComparison comparison;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = comparison;
    final deviating = {for (final d in c.deviations) d.zone};
    final style = TextStyle(
      fontSize: 12,
      color: fjInk,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return LoadCard(
      title: l.hrZonePlanTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadRange(
            labels: const ['this', 'last'],
            display: {'this': l.hrZoneThisWeek, 'last': l.hrZoneLastWeek},
            selected: week,
            segmented: true,
            onChanged: onWeek,
          ),
          const SizedBox(height: 10),
          if (c.comparableSessions == 0)
            Text(l.hrZonePlanNone, style: loadCaption)
          else
            Table(
              children: [
                TableRow(
                  children: [
                    const SizedBox.shrink(),
                    Text(l.hrZonePlanned, style: loadCaption),
                    Text(l.hrZoneRecorded, style: loadCaption),
                    const SizedBox.shrink(),
                  ],
                ),
                for (var i = 0; i < hrZoneCount; i++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: LoadLegend('Z${i + 1}', hrZoneColors[i]),
                      ),
                      Text(hrZoneDuration(c.planned[i]), style: style),
                      Text(
                        hrZoneDuration(c.actual.zoneSeconds[i]),
                        style: style,
                      ),
                      deviating.contains(i)
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: LoadBadge(l.hrZoneDeviation, fontSize: 9),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 8),
          if (c.sessions > 0)
            Text(
              l.hrZonePlanCoverage(c.comparableSessions, c.sessions),
              style: loadCaption,
            ),
          if (c.missedSessions > 0)
            Text(l.hrZonePlanMissed(c.missedSessions), style: loadCaption),
          for (final MapEntry(key: gap, value: n) in c.gaps.entries)
            Text(switch (gap) {
              PlanZoneGap.power => l.hrZoneGapPower(n),
              PlanZoneGap.pace => l.hrZoneGapPace(n),
              _ => l.hrZoneGapNoHr(n),
            }, style: loadCaption),
          const SizedBox(height: 4),
          Text(l.hrZonePlanNote, style: loadCaption),
        ],
      ),
    );
  }
}

/// FjeliaPro heart-rate zone trends: open for Pro, a lock and the Pro sheet
/// where Pro is offered, nothing where it is not.
class HrZoneTrendsTile extends ConsumerWidget {
  const HrZoneTrendsTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final edition = ref.watch(fjeliaEditionProvider);
    if (!edition.isPro && !edition.proOffered) return const SizedBox.shrink();
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: loadInset,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: fjInk10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => edition.isPro
              ? showLoadSheet(context, const HrZoneTrendsSheet(), height: .92)
              : showAppSheet(context, const FjeliaProSheet()),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.stacked_bar_chart, size: 18, color: muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.hrZoneTrendsTitle.toUpperCase(),
                        style: loadLabel.copyWith(fontSize: 10),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l.hrZoneTrendsHint,
                        style: loadCaption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (!edition.isPro)
                  Icon(Icons.lock_outline, size: 16, color: muted)
                else
                  Icon(Icons.chevron_right, size: 16, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
