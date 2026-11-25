import '../../theme/fjelia_style.dart';
import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/day_data_provider.dart';
import '../../providers/lt1_provider.dart';
import '../../providers/lt1_drift_provider.dart';
import '../../providers/lt2_tt_provider.dart';
import '../../providers/vo2max_provider.dart';
import '../../providers/ftp_provider.dart';
import '../../providers/threshold_overview_provider.dart';
import 'threshold_overview_section.dart';
import '../../widgets/app_widgets.dart';
import 'threshold_sheets.dart';
import 'load_metric_sheet.dart';
import 'load_visuals.dart';

import '../../providers/hr_zones_provider.dart';
import '../../widgets/hr_zone_labels.dart';
import '../../services/hr_zone_history.dart' show zoneSports, ZoneMethod;

import 'package:intl/intl.dart' show DateFormat;

import '../settings/hr_zones_tab.dart';

class TrainingMonitorCard extends ConsumerWidget {
  const TrainingMonitorCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref
        .watch(trainingMonitorProvider(ref.watch(selectedDateProvider)))
        .valueOrNull;
    final lt1 = ref.watch(lt1Provider),
        lt2 = ref.watch(lt2TtProvider).valueOrNull,
        vo2 = ref.watch(vo2MaxProvider).valueOrNull,
        ftp = ref.watch(ftpProvider).valueOrNull;
    final drift = ref.watch(lt1DriftProvider).valueOrNull;
    // The thresholds in use and where they come from (all sources).
    final overview = ref.watch(thresholdOverviewProvider).valueOrNull;
    ThresholdRow? row(ThresholdKind kind) =>
        overview?.rows.where((r) => r.kind == kind).firstOrNull;
    final lt1Row = row(ThresholdKind.lt1), lt2Row = row(ThresholdKind.lt2);
    final ftpRow = row(ThresholdKind.ftp);
    String pace(int? s) => s == null
        ? ''
        : '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')} /km';
    // A proposal first; else where the best value comes from.
    String? origin(ThresholdRow? r) {
      if (r?.proposal case final p?) {
        return context.l10n.thresholdProposal(
          thresholdValue(p.kind, p.value, p.paceSecPerKm),
          thresholdSourceLabel(p),
        );
      }
      final best = r?.best;
      if (best == null) return null;
      return [
        thresholdSourceLabel(best),
        if (best.date case final d?) loadDate(d),
      ].join(' · ');
    }

    final proposed = {
      if (lt1Row?.proposal != null) 'LT1 threshold',
      if (lt2Row?.proposal != null) 'LT2 threshold',
      if (ftpRow?.proposal != null) 'FTP cycling',
    };
    final cells = <(String, String, String)>[
      (
        'VO₂max running',
        '${valueText(m?.vo2max, 1)} ml/kg/min',
        context.l10n.garminRunningVo2max,
      ),
      (
        'VO₂max cycling',
        '${valueText(m?.vo2maxCycling, 1)} ml/kg/min',
        context.l10n.garminCyclingVo2max,
      ),
      (
        'LT1 threshold',
        '${lt1Row?.inUse ?? lt1?.bpm ?? '—'} bpm  ${drift?.lt1Pace ?? ''}',
        origin(lt1Row) ??
            (drift == null
                ? context.l10n.aerobicThreshold2
                : context.l10n.driftDriftAt(
                    valueText(drift.drift, 1),
                    loadDate(drift.at),
                  )),
      ),
      (
        'Activity hours',
        '${valueText(m?.weekHours, 1)} h',
        context.l10n.hoursPreviousWeek(valueText(m?.previousWeekHours, 1)),
      ),
      (
        'LT2 threshold',
        '${lt2Row?.inUse ?? lt2?.lt2 ?? '—'} bpm  '
            '${lt2Row?.inUsePaceSecPerKm != null ? pace(lt2Row!.inUsePaceSecPerKm) : lt2?.pace ?? ''}',
        origin(lt2Row) ??
            (lt2 == null
                ? context.l10n.thirtyMinuteTimeTrial
                : context.l10n.thirtyMinTtDate(loadDate(lt2.at))),
      ),
      (
        'Activity km',
        '${valueText(m?.weekKm, 1)} km',
        context.l10n.kmPreviousWeek(valueText(m?.previousWeekKm, 1)),
      ),
      ('VO₂max pace', vo2?.pace ?? '—', context.l10n.tap5MinuteMaxTest),
      (
        'FTP cycling',
        '${ftp?.ftpWatts ?? '—'} W',
        ftpRow?.proposal != null
            ? origin(ftpRow)!
            : '${valueText(ftp?.wattsPerKg, 2)} W/kg',
      ),
    ];
    return LoadCard(
      accent: const [Color(0xFF9D7BFF), Color(0xFFFF7AD9)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientTitle(
            context.l10n.trainingMonitor2,
            colors: const [Color(0xFF9D7BFF), Color(0xFFFF7AD9)],
          ),
          const SizedBox(height: 10),
          GridView.count(
            // Inside a card: no safe-area padding of its own (a scroll view
            // without padding adds the screen's top and bottom insets).
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            childAspectRatio: 1.9,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final c in cells)
                Material(
                  color: fjInk.withValues(alpha: .04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: c.$1 == 'VO₂max pace'
                        ? BorderSide(color: loadBlue.withValues(alpha: .5))
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => showLoadSheet(
                      context,
                      c.$1.startsWith('VO₂max ') && c.$1 != 'VO₂max pace' ||
                              c.$1.startsWith('Activity ')
                          ? LoadMetricSheet(metric: c.$1)
                          // Every source, the value in use and the tests.
                          : c.$1 == 'LT1 threshold' ||
                                c.$1 == 'LT2 threshold' ||
                                c.$1 == 'FTP cycling'
                          ? const ThresholdSheets()
                          : ThresholdTestSheet(vo2: c.$1 == 'VO₂max pace'),
                      height:
                          c.$1.contains('threshold') || c.$1 == 'FTP cycling'
                          ? .9
                          : c.$1 == 'VO₂max pace'
                          ? .72
                          : .55,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                c.$1.contains('cycling')
                                    ? Icons.directions_bike
                                    : c.$1.contains('hours')
                                    ? Icons.schedule
                                    : c.$1.contains('km')
                                    ? Icons.straighten
                                    : c.$1.contains('threshold')
                                    ? Icons.show_chart
                                    : Icons.directions_run,
                                size: 12,
                                color: muted,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  loadMetricLabel(
                                    context,
                                    c.$1,
                                  ).toUpperCase().replaceAll('₂', '2'),
                                  maxLines: 1,
                                  style: TextStyle(fontSize: 10, color: muted),
                                ),
                              ),
                              // A newer value from a source waits to be
                              // applied or kept.
                              if (proposed.contains(c.$1))
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: mint,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: c.$2.split(' ').first,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: fjInk,
                                          ),
                                        ),
                                        TextSpan(
                                          text: c.$2.contains(' ')
                                              ? ' ${c.$2.substring(c.$2.indexOf(' ') + 1)}'
                                              : '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: duo(0xFFBBBBBB, 0xFF4B5563),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (c.$1.startsWith('Activity') &&
                                  m != null &&
                                  (c.$1 == 'Activity hours'
                                      ? m.weekHours != m.previousWeekHours
                                      : m.weekKm != m.previousWeekKm))
                                Icon(
                                  (c.$1 == 'Activity hours'
                                          ? m.weekHours < m.previousWeekHours
                                          : m.weekKm < m.previousWeekKm)
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: loadOrange,
                                  size: 16,
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Flexible(
                            child: Text(
                              c.$3,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9, color: muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const _ZoneHint(),
          Divider(height: 24, color: fjInk10),
        ],
      ),
    );
  }
}

List<Color> get _zoneColors => [
  duo(0xFF888888, 0xFF6B7280),
  loadBlue,
  mint,
  Color(0xFFFFCC00),
  loadOrange,
  loadRed,
];

/// One line under the thresholds, only when the heart-rate zones need a
/// look: a question or a hint is open, or the zones of a sport changed in
/// the last 14 days. The zones themselves are in Settings → HF-Zonen.
class _ZoneHint extends ConsumerWidget {
  const _ZoneHint();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(hrZonesProvider);
    String? text;
    if (state.conflicts.isNotEmpty ||
        zoneSports.any((sport) => state.check(sport) != null)) {
      text = l.hrZoneConflictCheck;
    } else {
      final now = DateTime.now();
      final recent = [
        for (final sport in zoneSports)
          if (state.book.latest(sport) case final d?
              when d.method != ZoneMethod.derived &&
                  d.method != ZoneMethod.estimate &&
                  d.effectiveFrom.millisecondsSinceEpoch > 0 &&
                  now.difference(d.effectiveFrom).inDays < 14)
            d,
      ]..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
      if (recent.isNotEmpty) {
        final d = recent.first;
        text = l.hrZonesNewSince(
          zoneSportName(l, d.sport),
          DateFormat.MMMd().format(d.effectiveFrom),
        );
      }
    }
    if (text == null) return const SizedBox(height: 12);
    return InkWell(
      key: const ValueKey('zone-hint'),
      onTap: () => showAppSheet(context, const HrZonesTab()),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
        child: Row(
          children: [
            Icon(Icons.favorite_border, size: 14, color: muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: TextStyle(fontSize: 12, color: fjInk70)),
            ),
            Icon(Icons.chevron_right, size: 16, color: muted),
          ],
        ),
      ),
    );
  }
}

class LoadZonesSheet extends ConsumerWidget {
  const LoadZonesSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ftp = ref.watch(ftpProvider).valueOrNull;
    return LoadSheet(
      close: true,
      title: context.l10n.cyclingPowerZones2,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (ftp == null) EmptyState(context.l10n.setFtpToCalculatePower2),
          if (ftp != null)
            for (var i = 0; i < 6; i++)
              ListTile(
                leading: Text(
                  'Z${i + 1}',
                  style: TextStyle(color: _zoneColors[i]),
                ),
                title: Text(
                  [
                    'Active recovery',
                    context.l10n.endurance,
                    context.l10n.tempo,
                    context.l10n.threshold,
                    'VO₂max',
                    context.l10n.anaerobic,
                  ][i],
                ),
                subtitle: Text(
                  i == 5
                      ? '≥ ${ftp.powerZoneFloors.last} W'
                      : '${i == 0 ? 0 : ftp.powerZoneFloors[i - 1]}–${ftp.powerZoneFloors[i] - 1} W',
                ),
              ),
        ],
      ),
    );
  }
}
