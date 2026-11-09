import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/fjelia_edition_provider.dart';
import '../../providers/sport_stats_provider.dart';
import '../../services/sport_stats.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';
import '../settings/fjelia_pro_sheet.dart';

const _accent = [Color(0xFF6FA8FF), Color(0xFF3EE0FF)];

/// FjeliaPro: running and riding at a glance. Without Pro, while Pro is on
/// offer, a short card leads to the Pro sheet; otherwise nothing.
class SportStatsCard extends ConsumerWidget {
  const SportStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final edition = ref.watch(fjeliaEditionProvider);
    if (edition.isPro) return const _SportStats();
    if (!edition.proOffered) return const SizedBox.shrink();
    final l = context.l10n;
    return SectionCard(
      key: const ValueKey('sport-stats-locked'),
      title: l.statsTitle,
      accent: _accent,
      onTap: () => showAppSheet(context, const FjeliaProSheet()),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.proBenefitStats,
              style: TextStyle(fontSize: 13, color: fjInk70),
            ),
          ),
          const GradientTitle('Pro', colors: _accent),
        ],
      ),
    );
  }
}

/// The statistics as an accordion. Folded, one line cycles through the
/// highlights every few seconds; unfolded: the period (4 weeks per week,
/// this year, all time) as four figures, the records and the best efforts.
class _SportStats extends ConsumerStatefulWidget {
  const _SportStats();
  @override
  ConsumerState<_SportStats> createState() => _SportStatsState();
}

enum _Period { weeks, year, all }

class _SportStatsState extends ConsumerState<_SportStats> {
  StatsSport sport = StatsSport.run;
  _Period period = _Period.weeks;
  bool open = false;
  int tick = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Folded, the highlights take turns: a short change every few seconds,
    // no continuous motion (style.md).
    _ticker = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && !open) setState(() => tick++);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final stats = ref.watch(sportStatsProvider).valueOrNull;
    final s = stats?[sport];
    final highlights = s == null || s.allTime.count == 0
        ? const <(String, String)>[]
        : _highlights(context, s);
    void flip() => setState(() => open = !open);
    final chips = [
      for (final (value, label) in [
        (StatsSport.run, l.running),
        (StatsSport.ride, l.cycling),
      ])
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: ChoiceChip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
            showCheckmark: false,
            selected: sport == value,
            onSelected: (_) => setState(() {
              sport = value;
              tick = 0;
            }),
          ),
        ),
    ];
    final Widget folded;
    if (stats == null) {
      folded = const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (highlights.isEmpty) {
      folded = Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(l.statsNone, style: TextStyle(color: muted)),
      );
    } else {
      folded = AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: open
            ? const SizedBox(width: double.infinity)
            : _Ticker(item: highlights[tick % highlights.length]),
      );
    }
    return SectionCard(
      key: const ValueKey('sport-stats'),
      accent: _accent,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The whole head, values included, folds and unfolds; the chevron
          // sits large and centred on the right like an ExpansionTile's.
          InkWell(
            key: const ValueKey('sport-stats-toggle'),
            borderRadius: BorderRadius.circular(16),
            onTap: highlights.isEmpty ? null : flip,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GradientTitle(
                                l.statsTitle,
                                colors: _accent,
                              ),
                            ),
                            ...chips,
                          ],
                        ),
                        const SizedBox(height: 8),
                        folded,
                      ],
                    ),
                  ),
                  if (highlights.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: AnimatedRotation(
                        turns: open ? .5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(Icons.expand_more, size: 28, color: fjInk),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open && s != null && highlights.isNotEmpty
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: flip,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _Details(
                        stats: s,
                        period: period,
                        onPeriod: (p) => setState(() => period = p),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  /// The few numbers worth a glance, in turn.
  List<(String, String)> _highlights(BuildContext context, SportStats s) {
    final l = context.l10n;
    final year = DateTime.now().year;
    return [
      (_km(s.last4PerWeek.meters), l.statsTickerWeek),
      (_km(s.year.meters), l.statsTickerYear('$year')),
      (statsHoursRounded(s.year.seconds), l.statsTickerYear('$year')),
      if (s.longest != null) (_km(s.longest!), l.statsLongest),
      for (final e in s.efforts)
        if (e.allTime != null &&
            const {
              '5K',
              '10K',
              'Half-Marathon',
              'Marathon',
              '100K',
              '180K',
            }.contains(e.label))
          (effortTime(e.allTime!), l.statsTickerBest(e.label)),
    ];
  }
}

String _km(double meters) =>
    '${NumberFormat.decimalPattern().format((meters / 1000).round())} km';

String _m(double meters) =>
    '${NumberFormat.decimalPattern().format(meters.round())} m';

/// Hours and minutes for a week, whole hours for a year or all time.
String statsHoursRounded(double seconds) => seconds >= 100 * 3600
    ? '${NumberFormat.decimalPattern().format((seconds / 3600).round())} h'
    : statsHours(seconds);

/// One highlight, sliding in from below and fading.
class _Ticker extends StatelessWidget {
  const _Ticker({required this.item});
  final (String, String) item;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    width: double.infinity,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .35),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Align(
        key: ValueKey(item),
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.$1,
              style: TextStyle(
                fontSize: 22,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: fjInk,
                letterSpacing: -.3,
              ),
            ),
            Text(item.$2, style: TextStyle(fontSize: 12, color: muted)),
          ],
        ),
      ),
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details({
    required this.stats,
    required this.period,
    required this.onPeriod,
  });
  final SportStats stats;
  final _Period period;
  final ValueChanged<_Period> onPeriod;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final totals = switch (period) {
      _Period.weeks => stats.last4PerWeek,
      _Period.year => stats.year,
      _Period.all => stats.allTime,
    };
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            children: [
              for (final (value, label) in [
                (_Period.weeks, l.statsFourWeeks),
                (_Period.year, '${DateTime.now().year}'),
                (_Period.all, l.statsAllTimeTotals),
              ])
                ChoiceChip(
                  label: Text(label, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                  selected: period == value,
                  onSelected: (_) => onPeriod(value),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Grid(totals: totals, perWeek: period == _Period.weeks),
          if (stats.longest != null || (stats.mostElevation ?? 0) > 0) ...[
            const SizedBox(height: 16),
            if (stats.longest != null)
              _Line(l.statsLongest, _km(stats.longest!), stats.longestDate),
            if ((stats.mostElevation ?? 0) > 0)
              _Line(
                l.statsMostElevation,
                _m(stats.mostElevation!),
                stats.mostElevationDate,
              ),
          ],
          if (stats.efforts.any((e) => e.allTime != null)) ...[
            const SizedBox(height: 16),
            _Label(l.statsBestEfforts),
            const SizedBox(height: 4),
            for (final e in stats.efforts)
              if (e.allTime != null) _EffortLine(effort: e),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      color: muted,
      letterSpacing: 1,
      fontWeight: FontWeight.w700,
    ),
  );
}

/// Four figures, two by two, so long numbers never run into each other.
class _Grid extends StatelessWidget {
  const _Grid({required this.totals, required this.perWeek});
  final StatsTotals totals;
  final bool perWeek;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final suffix = perWeek ? ' ${l.statsPerWeekShort}' : '';
    final cells = [
      ('${totals.count.round()}', '${l.activities}$suffix'),
      (_km(totals.meters), '${l.distance}$suffix'),
      (statsHoursRounded(totals.seconds), '${l.time}$suffix'),
      (_m(totals.elevation), '${l.statsElevation}$suffix'),
    ];
    Widget cell((String, String) c) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              c.$1,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: fjInk,
                letterSpacing: -.3,
              ),
            ),
          ),
          Text(
            c.$2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    );
    return Column(
      children: [
        Row(children: [cell(cells[0]), cell(cells[1])]),
        const SizedBox(height: 12),
        Row(children: [cell(cells[2]), cell(cells[3])]),
      ],
    );
  }
}

/// A record: label, value and its day, on one line.
class _Line extends StatelessWidget {
  const _Line(this.label, this.value, this.date);
  final String label, value;
  final DateTime? date;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 13, color: fjInk70)),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w800, color: fjInk),
        ),
        SizedBox(
          width: 96,
          child: Text(
            date == null ? '' : DateFormat.yMMMd().format(date!),
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ),
      ],
    ),
  );
}

/// One distance on one line: the label, the all-time best and its day; this
/// year's best, when it is another one, as a small second figure.
class _EffortLine extends StatelessWidget {
  const _EffortLine({required this.effort});
  final BestEffort effort;

  @override
  Widget build(BuildContext context) {
    final yearBest =
        effort.year != null && effort.yearDate != effort.allTimeDate
        ? effort.year
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                effort.label,
                maxLines: 1,
                style: TextStyle(fontSize: 13, color: fjInk70),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              effortTime(effort.allTime!),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: fjAccent(_accent.first),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              yearBest == null
                  ? ''
                  : '${DateTime.now().year} ${effortTime(yearBest)}',
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ),
          SizedBox(
            width: 92,
            child: Text(
              effort.allTimeDate == null
                  ? ''
                  : DateFormat.yMMMd().format(effort.allTimeDate!),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
