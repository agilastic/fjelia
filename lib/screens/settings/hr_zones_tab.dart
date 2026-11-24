import '../../theme/fjelia_style.dart';
import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/hr_zones_provider.dart';
import '../../providers/hr_zone_autoadjust_provider.dart';
import '../../providers/lt2_tt_provider.dart';
import '../../providers/lt1_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/app_widgets.dart';

/// Saves zones set here as a new entry of the zone history, from now on.
Future<void> _save(WidgetRef ref, HrZones zones, {required bool bike}) {
  final notifier = ref.read(hrZonesProvider.notifier);
  return bike ? notifier.saveCycling(zones) : notifier.saveRunning(zones);
}

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
                    }),
                    child: Text(
                      context.l10n.syncLabel,
                      style: TextStyle(color: Colors.orange, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          for (final bike in [false, true]) ...[
            SectionLabel(
              bike ? context.l10n.cycling : context.l10n.running,
              color: bike ? Colors.blue : Colors.red,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => runUiAction(context, () async {
                  final suggestion = await ref.read(
                    hrAutoAdjustProvider.future,
                  );
                  final max = bike
                      ? suggestion?.cyclingMaxHr
                      : suggestion?.runningMaxHr;
                  if (max == null) {
                    throw StateError(tr.notEnoughRecentHeartRate);
                  }
                  // Karvonen from that sport's maximum and the resting
                  // heart rate of the last nights.
                  final zones = await ref
                      .read(hrZonesProvider.notifier)
                      .karvonen(max);
                  await _save(ref, bike: bike, HrZones(zones));
                }),
                child: Text(context.l10n.autoadjust),
              ),
            ),
            for (var i = 0; i < 5; i++)
              SectionCard(
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 42,
                      color: const [
                        Colors.blue,
                        mint,
                        Colors.yellow,
                        Colors.orange,
                        Colors.red,
                      ][i],
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.zoneI(i + 1),
                            style: TextStyle(
                              color: [
                                Colors.blue,
                                mint,
                                Colors.yellow,
                                Colors.orange,
                                Colors.red,
                              ][i],
                            ),
                          ),
                          Text(
                            [
                              'Recovery / Easy',
                              context.l10n.aerobicBase,
                              context.l10n.tempo,
                              context.l10n.lactateThreshold,
                              'VO₂max',
                            ][i],
                            style: TextStyle(fontSize: 10, color: muted),
                          ),
                          Text(
                            hrZoneRange(
                              bike ? zones.cycling : zones.running,
                              i,
                              maxHr,
                            ),
                            style: TextStyle(fontSize: 9, color: fjInk),
                          ),
                        ],
                      ),
                    ),
                    for (final delta in [-1, 0, 1])
                      if (delta == 0)
                        Text(
                          '${(bike ? zones.cycling : zones.running).bounds[i]}',
                        )
                      else
                        IconButton(
                          icon: Icon(
                            delta < 0 ? Icons.remove : Icons.add,
                            size: 16,
                          ),
                          onPressed: () => runUiAction(context, () async {
                            final z = bike
                                ? ref.read(hrZonesProvider).cycling
                                : ref.read(hrZonesProvider).running;
                            final b = [...z.bounds];
                            b[i] += delta;
                            if (b[i] < 30 ||
                                b[i] > 240 ||
                                (i > 0 && b[i] <= b[i - 1]) ||
                                (i < 4 && b[i] >= b[i + 1])) {
                              return;
                            }
                            await _save(ref, bike: bike, HrZones(b));
                          }),
                        ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

String _sportName(BuildContext context, String sport) => switch (sport) {
  'cycling' => context.l10n.cycling,
  'swimming' => context.l10n.swimming,
  _ => context.l10n.running,
};

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
      onTap: () =>
          runUiAction(context, () => notifier.resolveConflict(sport, choose)),
    );
    return SectionCard(
      key: ValueKey('zone-conflict-$sport'),
      color: Colors.orange.withValues(alpha: .08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.hrZoneConflictTitle(_sportName(context, sport)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.hrZones2,
          style: TextStyle(color: muted, fontSize: 9, letterSpacing: 1),
        ),
        if (state.conflicts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.l10n.hrZoneConflictCheck,
              style: const TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ),
        const SizedBox(height: 10),
        for (final bike in [false, true])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  bike ? Icons.directions_bike : Icons.directions_run,
                  color: bike ? Colors.blue : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 6),
                for (var i = 0; i < 5; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: const [
                          Colors.blue,
                          mint,
                          Colors.yellow,
                          Colors.orange,
                          Colors.red,
                        ][i].withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Z${i + 1}',
                            style: TextStyle(fontSize: 8, color: muted),
                          ),
                          Text(
                            '${(bike ? state.cycling : state.running).bounds[i]}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            i < 4
                                ? '${(bike ? state.cycling : state.running).bounds[i + 1] - 1}'
                                : maxHr != null &&
                                      maxHr >
                                          (bike ? state.cycling : state.running)
                                              .bounds
                                              .last
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
