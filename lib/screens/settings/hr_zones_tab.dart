import '../../theme/fjelia_style.dart';
import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/hr_zones_provider.dart';
import '../../providers/hr_zone_autoadjust_provider.dart';
import '../../providers/lt2_tt_provider.dart';
import '../../providers/lt1_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/hr_zone_sync_provider.dart';
import '../../services/hr_zone_history.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/hr_zone_labels.dart';

/// Saves zones set here as a new entry of the zone history, from now on.
Future<void> _save(WidgetRef ref, HrZones zones, {required String sport}) => ref
    .read(hrZonesProvider.notifier)
    .record(sport, zones.bounds, method: ZoneMethod.manual);

const _zoneColors = [
  Colors.blue,
  mint,
  Colors.yellow,
  Colors.orange,
  Colors.red,
];

/// Settings → HF-Zonen: per sport the zones in force with where they came
/// from, a hint when they look wrong, the editable zones and their history.
class HrZonesTab extends ConsumerWidget {
  const HrZonesTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(hrZonesProvider);
    final tt = ref.watch(lt2TtProvider).valueOrNull;
    final maxHr = ref.watch(userProfileProvider).valueOrNull?.maxHrEstimate;
    return SheetPage(
      title: context.l10n.hrZones,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final e in zones.conflicts.entries)
            _ZoneConflictCard(sport: e.key, earlier: e.value),
          if (tt != null)
            SectionCard(
              color: Colors.orange.withValues(alpha: .08),
              child: Row(
                children: [
                  const Icon(Icons.sync, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.t30MinTtAvailableSync,
                          style: TextStyle(color: Colors.orange, fontSize: 11),
                        ),
                        Text(
                          context.l10n.lt2Lt2BpmAt(tt.lt2, dayText(tt.at)),
                          style: TextStyle(color: muted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => runUiAction(context, () async {
                      final n = ref.read(hrZonesProvider.notifier);
                      // From the test's day on, like the test itself.
                      await n.applyFromLt2Hr(tt.lt2, from: tt.at);
                      final lt1 = ref.read(lt1Provider);
                      if (lt1 != null) {
                        await n.applyLt1Ceiling(lt1.bpm, from: tt.at);
                      }
                      await ref.read(zoneRecalculationProvider)();
                    }),
                    child: Text(
                      context.l10n.syncLabel,
                      style: TextStyle(color: Colors.orange, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          for (final sport in zoneSports)
            _SportZones(sport: sport, zones: zones, maxHr: maxHr),
        ],
      ),
    );
  }
}

/// One sport: name, origin, the hint when the zones look wrong, the five
/// zones to adjust and the history.
class _SportZones extends ConsumerWidget {
  const _SportZones({
    required this.sport,
    required this.zones,
    required this.maxHr,
  });
  final String sport;
  final HrZonesState zones;
  final int? maxHr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final color = switch (sport) {
      'cycling' => Colors.blue,
      'swimming' => Colors.cyan,
      _ => Colors.red,
    };
    final current = zones.forSport(sport);
    final origin = zoneOriginText(l, zones, sport);
    final check = zoneCheckText(l, zones, sport);
    final estimate = zones.estimateFor(sport);
    final history = zones.book.of(sport).reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(zoneSportName(l, sport), color: color),
        Row(
          children: [
            if (origin != null)
              Expanded(
                child: Text(
                  origin,
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              )
            else
              const Spacer(),
            if (sport != 'swimming')
              TextButton(
                onPressed: () => runUiAction(context, () async {
                  final suggestion = await ref.read(
                    hrAutoAdjustProvider.future,
                  );
                  final max = sport == 'cycling'
                      ? suggestion?.cyclingMaxHr
                      : suggestion?.runningMaxHr;
                  if (max == null) {
                    throw StateError(tr.notEnoughRecentHeartRate);
                  }
                  // Karvonen from that sport's maximum and the resting
                  // heart rate of the last nights.
                  final karvonen = await ref
                      .read(hrZonesProvider.notifier)
                      .karvonen(max);
                  await _save(ref, sport: sport, HrZones(karvonen));
                }),
                child: Text(l.autoadjust),
              ),
          ],
        ),
        if (check != null)
          SectionCard(
            key: ValueKey('zone-check-$sport'),
            color: Colors.orange.withValues(alpha: .08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(check, style: const TextStyle(fontSize: 12)),
                if (estimate != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => runUiAction(
                        context,
                        () => _save(ref, sport: sport, HrZones(estimate)),
                      ),
                      child: Text(l.hrZoneUseEstimate),
                    ),
                  ),
              ],
            ),
          ),
        for (var i = 0; i < 5; i++)
          SectionCard(
            child: Row(
              children: [
                Container(width: 3, height: 42, color: _zoneColors[i]),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.zoneI(i + 1),
                        style: TextStyle(color: _zoneColors[i]),
                      ),
                      Text(
                        [
                          'Recovery / Easy',
                          l.aerobicBase,
                          l.tempo,
                          l.lactateThreshold,
                          'VO₂max',
                        ][i],
                        style: TextStyle(fontSize: 10, color: muted),
                      ),
                      Text(
                        hrZoneRange(current, i, maxHr),
                        style: TextStyle(fontSize: 9, color: fjInk),
                      ),
                    ],
                  ),
                ),
                for (final delta in [-1, 0, 1])
                  if (delta == 0)
                    Text('${current.bounds[i]}')
                  else
                    IconButton(
                      icon: Icon(
                        delta < 0 ? Icons.remove : Icons.add,
                        size: 16,
                      ),
                      onPressed: () => runUiAction(context, () async {
                        final b = [
                          ...ref.read(hrZonesProvider).forSport(sport).bounds,
                        ];
                        b[i] += delta;
                        if (b[i] < 30 ||
                            b[i] > 240 ||
                            (i > 0 && b[i] <= b[i - 1]) ||
                            (i < 4 && b[i] >= b[i + 1])) {
                          return;
                        }
                        await _save(ref, sport: sport, HrZones(b));
                      }),
                    ),
              ],
            ),
          ),
        if (history.isNotEmpty)
          ExpansionTile(
            key: ValueKey('zone-history-$sport'),
            tilePadding: EdgeInsets.zero,
            title: Text(
              l.hrZoneHistoryTitle,
              style: const TextStyle(fontSize: 13),
            ),
            children: [
              for (final d in history)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    zoneFloorsOf(d.floorsJson)?.join(' · ') ?? d.floorsJson,
                  ),
                  subtitle: Text(
                    '${zoneSourceLabel(l, d.method)} · ${zoneSinceText(l, d)}',
                  ),
                ),
              // The zones in force from an earlier day on, e.g. the day of
              // a test: the workouts since then are measured again.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.event, size: 16),
                  label: Text(l.zoneChangeStart),
                  onPressed: () async {
                    final now = DateTime.now();
                    final from = await showDatePicker(
                      context: context,
                      initialDate:
                          history.first.effectiveFrom.isAfter(DateTime(2000))
                          ? history.first.effectiveFrom
                          : now,
                      firstDate: DateTime(2000),
                      lastDate: now,
                    );
                    if (from == null || !context.mounted) return;
                    await runUiAction(context, () async {
                      await ref
                          .read(hrZonesProvider.notifier)
                          .backdate(sport, from);
                      await ref.read(zoneRecalculationProvider)();
                    });
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// The older settings and the zone history held different zones for a
/// sport: the athlete chooses (neither had a reliable date), with the
/// Karvonen estimate as a third option.
class _ZoneConflictCard extends ConsumerWidget {
  const _ZoneConflictCard({required this.sport, required this.earlier});
  final String sport;
  final List<int> earlier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(hrZonesProvider);
    final history = state.forSport(sport).bounds;
    final estimate = state.estimateFor(sport);
    final notifier = ref.read(hrZonesProvider.notifier);
    Widget option(String label, List<int> zones, List<int>? choose) => ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      subtitle: Text(zones.join(' · ')),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => runUiAction(context, () async {
        await notifier.resolveConflict(sport, choose);
        await ref.read(zoneRecalculationProvider)();
      }),
    );
    return SectionCard(
      key: ValueKey('zone-conflict-$sport'),
      color: Colors.orange.withValues(alpha: .08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.hrZoneConflictTitle(zoneSportName(l, sport)),
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.hrZoneConflictBody,
            style: TextStyle(fontSize: 12, color: muted),
          ),
          option(l.hrZoneConflictHistory, history, null),
          option(l.hrZoneConflictSettings, earlier, earlier),
          if (estimate != null)
            option(l.hrZoneConflictEstimate, estimate, estimate),
        ],
      ),
    );
  }
}

class HrZonesPreview extends ConsumerWidget {
  const HrZonesPreview({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hrZonesProvider);
    final maxHr = ref.watch(userProfileProvider).valueOrNull?.maxHrEstimate;
    final check =
        state.conflicts.isNotEmpty ||
        zoneSports.any((sport) => state.check(sport) != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.hrZones2,
          style: TextStyle(color: muted, fontSize: 9, letterSpacing: 1),
        ),
        if (check)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.l10n.hrZoneConflictCheck,
              style: const TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ),
        const SizedBox(height: 10),
        for (final (sport, icon, color) in const [
          ('running', Icons.directions_run, Colors.red),
          ('cycling', Icons.directions_bike, Colors.blue),
          ('swimming', Icons.pool, Colors.cyan),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                for (var i = 0; i < 5; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _zoneColors[i].withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Z${i + 1}',
                            style: TextStyle(fontSize: 8, color: muted),
                          ),
                          Text(
                            '${state.forSport(sport).bounds[i]}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            i < 4
                                ? '${state.forSport(sport).bounds[i + 1] - 1}'
                                : maxHr != null &&
                                      maxHr > state.forSport(sport).bounds.last
                                ? '$maxHr'
                                : '+',
                            style: TextStyle(fontSize: 7, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

String hrZoneRange(HrZones zones, int index, int? maxHr) {
  final lower = zones.bounds[index];
  final upper = index < 4
      ? zones.bounds[index + 1] - 1
      : maxHr != null && maxHr > lower
      ? maxHr
      : null;
  return upper == null ? '$lower+ bpm' : '$lower–$upper bpm';
}
