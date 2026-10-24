import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/day_data_provider.dart';
import '../../providers/lt1_provider.dart';
import '../../providers/lt1_drift_provider.dart';
import '../../providers/lt2_tt_provider.dart';
import '../../providers/vo2max_provider.dart';
import '../../providers/ftp_provider.dart';
import '../../widgets/app_widgets.dart';
import 'threshold_sheets.dart';
import 'load_metric_sheet.dart';
import 'lt2_test_sheet.dart';
import '../../services/pfitzinger_zones.dart';
import 'load_visuals.dart';

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
    final cells = <(String, String, String)>[
      (
        'VO₂max running',
        '${valueText(m?.vo2max, 1)} ml/kg/min',
        'Garmin running VO2max',
      ),
      (
        'VO₂max cycling',
        '${valueText(m?.vo2maxCycling, 1)} ml/kg/min',
        'Garmin cycling VO2max',
      ),
      (
        'LT1 threshold',
        '${lt1?.bpm ?? '—'} bpm  ${drift?.lt1Pace ?? ''}',
        drift == null
            ? 'Aerobic threshold'
            : 'Drift ${valueText(drift.drift, 1)}% · ${loadDate(drift.at)}',
      ),
      (
        'Activity hours',
        '${valueText(m?.weekHours, 1)} h',
        '${valueText(m?.previousWeekHours, 1)} h previous week',
      ),
      (
        'LT2 threshold',
        '${lt2?.lt2 ?? '—'} bpm  ${lt2?.pace ?? ''}',
        lt2 == null
            ? '30-minute time trial'
            : '30-min TT · ${loadDate(lt2.at)}',
      ),
      (
        'Activity km',
        '${valueText(m?.weekKm, 1)} km',
        '${valueText(m?.previousWeekKm, 1)} km previous week',
      ),
      ('VO₂max pace', vo2?.pace ?? '—', 'Tap · 5-minute max test'),
      (
        'FTP cycling',
        '${ftp?.ftpWatts ?? '—'} W',
        '${valueText(ftp?.wattsPerKg, 2)} W/kg',
      ),
    ];
    return LoadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TRAINING MONITOR', style: loadLabel),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.9,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final c in cells)
                Material(
                  color: Colors.white.withValues(alpha: .04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                    side: c.$1 == 'VO₂max pace'
                        ? BorderSide(color: loadBlue.withValues(alpha: .5))
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () => showLoadSheet(
                      context,
                      c.$1.startsWith('VO₂max ') && c.$1 != 'VO₂max pace' ||
                              c.$1.startsWith('Activity ')
                          ? LoadMetricSheet(metric: c.$1)
                          : c.$1 == 'LT2 threshold'
                          ? const Lt2TestSheet()
                          : c.$1 == 'FTP cycling'
                          ? const FtpDetailSheet()
                          : ThresholdTestSheet(vo2: c.$1 == 'VO₂max pace'),
                      height: c.$1 == 'LT2 threshold'
                          ? .625
                          : c.$1 == 'FTP cycling'
                          ? .72
                          : c.$1 == 'LT1 threshold' || c.$1 == 'VO₂max pace'
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
                                  c.$1.toUpperCase().replaceAll('₂', '2'),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: muted,
                                  ),
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
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        TextSpan(
                                          text: c.$2.contains(' ')
                                              ? ' ${c.$2.substring(c.$2.indexOf(' ') + 1)}'
                                              : '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFBBBBBB),
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
                              style: const TextStyle(fontSize: 9, color: muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ZoneStrip(
            title: 'PFITZINGER ZONES',
            running: true,
            subtitle: 'LT2 ${lt2?.lt2 ?? '—'} bpm · ${lt2?.pace ?? '—'}',
            onTap: () =>
                showLoadSheet(context, const LoadZonesSheet(), height: .7),
          ),
          const SizedBox(height: 8),
          _ZoneStrip(
            title: 'CYCLING POWER ZONES',
            subtitle: ftp == null
                ? 'Set FTP to calculate power zones'
                : 'FTP ${ftp.ftpWatts} W · ${valueText(ftp.wattsPerKg, 2)} W/kg',
            onTap: () => showLoadSheet(
              context,
              const LoadZonesSheet(power: true),
              height: .7,
            ),
          ),
          const Divider(height: 24, color: Colors.white10),
        ],
      ),
    );
  }
}

const _zoneColors = [
  Color(0xFF888888),
  loadBlue,
  mint,
  Color(0xFFFFCC00),
  loadOrange,
  loadRed,
];
const _runningColors = [
  mint,
  mint,
  Color(0xFF81B784),
  Color(0xFFFFCC00),
  loadOrange,
  Color(0xFF777777),
];

class _ZoneStrip extends StatelessWidget {
  const _ZoneStrip({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.running = false,
  });
  final String title, subtitle;
  final bool running;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: loadInset,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: const BorderSide(color: Colors.white10),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(title, style: loadLabel.copyWith(fontSize: 10)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  running ? Icons.table_chart_outlined : Icons.directions_bike,
                  size: 14,
                  color: muted,
                ),
                const SizedBox(width: 8),
                for (var i = 0; i < 6; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: (running ? _runningColors : _zoneColors)[i]
                            .withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: (running ? _runningColors : _zoneColors)[i]
                              .withValues(alpha: .35),
                        ),
                      ),
                      child: Text(
                        running && i >= 4
                            ? (i == 4 ? '5A' : '5B')
                            : 'Z${i + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: (running ? _runningColors : _zoneColors)[i],
                        ),
                      ),
                    ),
                  ),
                const Icon(Icons.chevron_right, size: 16, color: muted),
              ],
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(subtitle, style: loadCaption.copyWith(fontSize: 9)),
            ),
          ],
        ),
      ),
    ),
  );
}

class LoadZonesSheet extends ConsumerWidget {
  const LoadZonesSheet({super.key, this.power = false});
  final bool power;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lt2 = ref.watch(lt2TtProvider).valueOrNull;
    final vo2 = ref.watch(vo2MaxProvider).valueOrNull;
    final ftp = ref.watch(ftpProvider).valueOrNull;
    final zones = lt2 == null
        ? <PfitzingerZone>[]
        : PfitzingerZones.calculate(
            lt2Hr: lt2.lt2,
            lt2PaceSec: lt2.paceSec,
            vo2PaceSec: vo2?.paceSec,
          );
    return LoadSheet(
      close: true,
      title: power ? 'Cycling power zones' : 'Pfitzinger zones',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!power && lt2 == null)
            const EmptyState(
              'Complete an LT2 test to calculate running zones.',
            ),
          if (power && ftp == null)
            const EmptyState('Set FTP to calculate power zones.'),
          if (!power)
            for (final zone in zones)
              ListTile(
                leading: Text(
                  'Z${zone.number}',
                  style: TextStyle(color: _zoneColors[zone.number - 1]),
                ),
                title: Text(zone.name),
                subtitle: Text(
                  '${zone.pace} · ${zone.hr}\n${zone.description}',
                ),
              ),
          if (power && ftp != null)
            for (var i = 0; i < 6; i++)
              ListTile(
                leading: Text(
                  'Z${i + 1}',
                  style: TextStyle(color: _zoneColors[i]),
                ),
                title: Text(
                  [
                    'Active recovery',
                    'Endurance',
                    'Tempo',
                    'Threshold',
                    'VO₂max',
                    'Anaerobic',
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
