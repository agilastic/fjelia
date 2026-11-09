import '../theme/fjelia_style.dart';
import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/day_data_provider.dart';

import 'app_widgets.dart';
import '../providers/heart_rate_provider.dart';
import 'hr_timeline_plot.dart';

import 'package:intl/intl.dart';

export '../providers/heart_rate_provider.dart';

class HrTimelineCard extends ConsumerWidget {
  const HrTimelineCard({super.key, this.expanded = false, this.date});
  final bool expanded;
  final DateTime? date;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime shownDate = date ?? ref.watch(selectedDateProvider);
    final data = ref.watch(heartRateDaySummaryProvider(shownDate));
    final summary = data.valueOrNull;
    final points = summary?.points ?? [];
    final resting = summary?.resting;
    final activities = summary?.activities ?? [];
    final avg = summary?.average;
    final peak = summary?.peak;
    if (!expanded) {
      // The same card as every other (style.md): title, resting rate, the
      // day's line, average and peak.
      return SectionCard(
        title: context.l10n.heartRate2,
        accent: const [Color(0xFFFF4D8D), Color(0xFF9D7BFF)],
        onTap: () => showAppSheet(context, const HrTimelineScreen()),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FigureLabel(context.l10n.resting),
                  const SizedBox(height: 4),
                  KeyFigure(valueText(resting), unit: 'bpm'),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: points.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.noTimedReadings,
                          style: TextStyle(fontSize: 10, color: muted),
                        ),
                      )
                    : HrTimelinePlot(
                        points: points,
                        date: shownDate,
                        activities: activities,
                        average: avg,
                        compact: true,
                        height: 44,
                      ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FigureLabel(context.l10n.peak),
                  const SizedBox(height: 4),
                  KeyFigure(valueText(peak)),
                ],
              ),
            ],
          ),
        ),
      );
    }
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.isLoading) const LinearProgressIndicator(),
        if (points.isEmpty)
          SizedBox(
            height: 80,
            child: Center(
              child: Text(
                context.l10n.noMeasurementsInThisPeriod,
                style: TextStyle(color: muted),
              ),
            ),
          )
        else
          HrTimelinePlot(
            points: points,
            date: shownDate,
            activities: activities,
            compact: !expanded,
            average: avg,
          ),
        if (expanded) ...[
          if (activities.isNotEmpty) ...[
            SectionLabel(context.l10n.activities),
            for (final a in activities)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.square_rounded,
                      size: 10,
                      color: Colors.lightBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a.name, style: const TextStyle(fontSize: 11)),
                    ),
                    Text(
                      context.l10n.tolocalRoundmin(
                        DateFormat.Hm().format(a.startDate.toLocal()),
                        (a.durationSeconds / 60).round(),
                      ),
                      style: TextStyle(color: muted, fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.avgheartrateBpmAvg(
                        valueText(a.avgHeartRate),
                      ),
                      style: const TextStyle(
                        color: Colors.lightBlue,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: duo(0xFF2A2A2A, 0xFFEEF1F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HrStat(context.l10n.enumResting, resting, mint),
                ),
                Expanded(
                  child: Tooltip(
                    message: context.l10n.timeWeightedAverageOverRecorded,
                    child: _HrStat(context.l10n.avg2, avg, fjInk),
                  ),
                ),
                if (activities.isNotEmpty)
                  Expanded(
                    child: _HrStat(context.l10n.peak2, peak, Colors.redAccent),
                  ),
              ],
            ),
          ),
          if (summary != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                summary.coveredDuration.inMinutes == 0
                    ? context.l10n.notEnoughContinuousReadingsFor
                    : context.l10n.recordedCoverageInhourshInminutesminTime(
                        summary.coveredDuration.inHours,
                        summary.coveredDuration.inMinutes % 60,
                      ),
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ),
        ],
      ],
    );
    return body;
  }
}

class HrTimelineScreen extends ConsumerStatefulWidget {
  const HrTimelineScreen({super.key});
  @override
  ConsumerState<HrTimelineScreen> createState() => _HrTimelineState();
}

class _HrTimelineState extends ConsumerState<HrTimelineScreen> {
  int days = 1, offset = 0;
  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final date = DateTime(
      selected.year,
      selected.month,
      selected.day - offset * days,
    );
    final start = DateTime(date.year, date.month, date.day - days + 1),
        end = DateTime(date.year, date.month, date.day + 1);
    final history = ref.watch(
      hrRestingHistoryProvider((start: start, end: end)),
    );
    return SheetPage(
      title: context.l10n.heartRate2,
      titleSize: 12,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in {
              1: context.l10n.day2,
              7: context.l10n.week2,
              30: context.l10n.month2,
            }.entries)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() {
                    days = e.key;
                    offset = 0;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: days == e.key
                          ? Colors.redAccent.withValues(alpha: .18)
                          : Colors.transparent,
                      border: Border.all(
                        color: days == e.key ? Colors.redAccent : fjInk12,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 10,
                        color: days == e.key ? Colors.redAccent : muted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
      showBack: false,
      backgroundColor: panel,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: context.l10n.previousHeartRatePeriod,
                onPressed: () => setState(() => offset++),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  days == 1
                      ? DateUtils.isSameDay(date, DateTime.now())
                            ? context.l10n.today
                            : DateFormat.yMd().format(date)
                      : days == 30
                      ? DateFormat.yMMM().format(date)
                      : '${DateFormat.Md().format(start)} – ${DateFormat.Md().format(date)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ),
              IconButton(
                tooltip: context.l10n.nextHeartRatePeriod,
                onPressed: offset == 0 ? null : () => setState(() => offset--),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (days == 1)
            HrTimelineCard(expanded: true, date: date)
          else
            history.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => DataError(e),
              data: (rows) {
                final resting = rows;
                final averages =
                    ref
                        .watch(
                          hrAverageHistoryProvider((start: start, end: end)),
                        )
                        .valueOrNull ??
                    [];
                return Column(
                  children: [
                    HrTimelinePlot(
                      points: resting,
                      secondary: averages,
                      date: date,
                      days: days,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.circle, color: Colors.redAccent, size: 9),
                        SizedBox(width: 6),
                        Text(
                          context.l10n.avgHr,
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                        SizedBox(width: 20),
                        Icon(Icons.circle, color: Colors.lightBlue, size: 9),
                        SizedBox(width: 6),
                        Text(
                          context.l10n.restingHr,
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HrStat extends StatelessWidget {
  const _HrStat(this.label, this.value, this.color);
  final String label;
  final num? value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 9, color: muted, letterSpacing: .8),
      ),
      const SizedBox(height: 6),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: valueText(value),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            TextSpan(
              text: ' bpm',
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
      ),
    ],
  );
}
