import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/hr_zones_provider.dart';
import '../../providers/hr_zone_autoadjust_provider.dart';
import '../../providers/lt2_tt_provider.dart';
import '../../providers/lt1_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/app_widgets.dart';

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
                          style: const TextStyle(color: muted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => runUiAction(context, () async {
                      final n = ref.read(hrZonesProvider.notifier);
                      await n.applyFromLt2Hr(tt.lt2);
                      final lt1 = ref.read(lt1Provider);
                      if (lt1 != null) await n.applyLt1Ceiling(lt1.bpm);
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
                  if (bike) {
                    await ref
                        .read(hrZonesProvider.notifier)
                        .saveCycling(HrZones.fromMaxHrCycling(max));
                  } else {
                    await ref
                        .read(hrZonesProvider.notifier)
                        .saveRunning(HrZones.fromMaxHr(max));
                  }
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
                            style: const TextStyle(fontSize: 10, color: muted),
                          ),
                          Text(
                            hrZoneRange(
                              bike ? zones.cycling : zones.running,
                              i,
                              maxHr,
                            ),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                            ),
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
                            if (bike) {
                              await ref
                                  .read(hrZonesProvider.notifier)
                                  .saveCycling(HrZones(b));
                            } else {
                              await ref
                                  .read(hrZonesProvider.notifier)
                                  .saveRunning(HrZones(b));
                            }
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
                            style: const TextStyle(fontSize: 8, color: muted),
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
                            style: const TextStyle(fontSize: 7, color: muted),
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
