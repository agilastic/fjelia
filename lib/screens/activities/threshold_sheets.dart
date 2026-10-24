import '../../providers/activity_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/lt1_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../providers/lt1_drift_provider.dart';
import '../../providers/lt2_tt_provider.dart';
import '../../providers/vo2max_provider.dart';
import '../../providers/ftp_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../services/activity_power_estimator.dart';
import 'load_visuals.dart';

class ThresholdSheets extends ConsumerWidget {
  const ThresholdSheets({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lt1 = ref.watch(lt1Provider),
        lt2 = ref.watch(lt2TtProvider).valueOrNull,
        vo2 = ref.watch(vo2MaxProvider).valueOrNull,
        ftp = ref.watch(ftpProvider).valueOrNull;
    return SheetPage(
      title: 'Thresholds & Fitness Tests',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'LT1',
            child: StatPair('Aerobic Threshold', '${lt1?.bpm ?? '—'} bpm'),
          ),
          SectionCard(
            title: 'LT2',
            child: StatPair(
              'Lactate Threshold',
              '${lt2?.lt2 ?? '—'} bpm · ${lt2?.pace ?? '—'}',
            ),
          ),
          SectionCard(
            title: 'VO₂ Pace',
            child: StatPair('5-minute max', vo2?.pace ?? '—'),
          ),
          SectionCard(
            title: 'FTP',
            child: Column(
              children: [
                StatPair(
                  'Functional Threshold Power',
                  '${ftp?.ftpWatts ?? '—'} W',
                ),
                TextButton(
                  onPressed: () => showAppSheet(context, const _FtpEditor()),
                  child: const Text('Set FTP manually'),
                ),
              ],
            ),
          ),
          const SectionLabel('Calculate from an activity'),
          ref
              .watch(loadActivitiesProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => DataError(e),
                data: (rows) => Column(
                  children: [
                    for (final a in rows.take(20))
                      ListTile(
                        title: Text(a.name),
                        subtitle: Text(dayText(a.startDate)),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (_) => [
                            for (final test in [
                              'LT1 drift',
                              'LT2 30-minute TT',
                              'VO₂ 5-minute max',
                            ])
                              PopupMenuItem(value: test, child: Text(test)),
                          ],
                          onSelected: (test) => runUiAction(context, () async {
                            final error = await switch (test) {
                              'LT1 drift' =>
                                ref
                                    .read(lt1DriftProvider.notifier)
                                    .calculate(a),
                              'LT2 30-minute TT' =>
                                ref.read(lt2TtProvider.notifier).calculate(a),
                              _ =>
                                ref.read(vo2MaxProvider.notifier).calculate(a),
                            };
                            if (error != null) throw StateError(error);
                          }),
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _FtpEditor extends ConsumerStatefulWidget {
  const _FtpEditor();
  @override
  ConsumerState<_FtpEditor> createState() => _FtpEditorState();
}

class _FtpEditorState extends ConsumerState<_FtpEditor> {
  final c = TextEditingController();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SheetPage(
    title: 'Set FTP',
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'FTP (watts)'),
            keyboardType: TextInputType.number,
          ),
          FilledButton(
            onPressed: () => runUiAction(context, () async {
              final watts = int.tryParse(c.text);
              if (watts == null || watts < 30 || watts > 1000) {
                throw StateError('Enter FTP between 30 and 1000 W.');
              }
              await ref.read(ftpProvider.notifier).saveManual(watts);
              ref.invalidate(thresholdHistoryProvider);
              if (context.mounted) Navigator.pop(context);
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

class FtpDetailSheet extends ConsumerWidget {
  const FtpDetailSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ftp = ref.watch(ftpProvider).valueOrNull;
    final history = ref.watch(thresholdHistoryProvider).valueOrNull ?? [];
    final rides = [
      for (final activity
          in ref.watch(loadActivitiesProvider).valueOrNull ?? [])
        if (activity.type.toLowerCase().contains('cycl') ||
            activity.type.toLowerCase().contains('bik'))
          (activity, best20MinutePower(activity.metricsJson)),
    ];
    return LoadSheet(
      title: 'FTP — CYCLING THRESHOLD POWER',
      centerTitle: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: loadBlue.withValues(alpha: .08),
              border: Border.all(color: loadBlue.withValues(alpha: .35)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 20, color: loadBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${ftp?.ftpWatts ?? '—'} W',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' · ${valueText(ftp?.wattsPerKg, 2)} W/kg',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFBBBBBB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: ftp == null
                      ? null
                      : () => runUiAction(context, () async {
                          await ref.read(ftpProvider.notifier).clear();
                          ref.invalidate(thresholdHistoryProvider);
                        }),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: loadRed, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (ftp != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${ftp.source == 'manual' ? 'Manual' : 'Estimated'} · ${loadDate(ftp.updatedAt)}',
                style: loadCaption,
              ),
            ),
          const SizedBox(height: 16),
          const Text('FTP HISTORY', style: loadLabel),
          const SizedBox(height: 12),
          LoadTrendChart(
            points: [
              for (final h in history)
                if (h.ftpWatts != null)
                  ChartPoint(h.date, h.ftpWatts!.toDouble()),
            ],
            color: loadBlue,
            height: 105,
            step: true,
            unit: 'W',
          ),
          const SizedBox(height: 16),
          const Text('UPDATE FROM ACTIVITY', style: loadLabel),
          const SizedBox(height: 5),
          const Text(
            'Tap an activity — FTP = best 20-min power × 0.95',
            style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 10),
          for (final ride in rides.where((r) => r.$2 != null).take(20))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: loadInset,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => runUiAction(context, () async {
                    await ref
                        .read(ftpProvider.notifier)
                        .saveFromActivity(
                          ride.$2!,
                          'ftp_mmp20',
                          ride.$1.startDate,
                        );
                    ref.invalidate(thresholdHistoryProvider);
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_bike,
                          size: 16,
                          color: muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.$1.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                loadDate(ride.$1.startDate),
                                style: loadCaption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${valueText(ride.$2)}W',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '→ FTP ${(ride.$2! * .95).round()}W',
                              style: const TextStyle(
                                fontSize: 11,
                                color: loadBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!rides.any((r) => r.$2 != null))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No rides with 20 minutes of continuous power samples.',
                style: loadCaption,
              ),
            ),
          Center(
            child: TextButton(
              onPressed: () =>
                  showLoadSheet(context, const _FtpEditor(), height: .45),
              child: const Text(
                'Enter FTP manually',
                style: TextStyle(
                  color: Color(0xFFBBBBBB),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dedicated destinations for the LT1 and five-minute pace tiles; they are
/// not routed through a combined test menu.
class ThresholdTestSheet extends ConsumerStatefulWidget {
  const ThresholdTestSheet({super.key, this.vo2 = false});
  final bool vo2;
  @override
  ConsumerState<ThresholdTestSheet> createState() => _ThresholdTestState();
}

class _ThresholdTestState extends ConsumerState<ThresholdTestSheet> {
  String? selectedId;
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final vo2 = ref.watch(vo2MaxProvider).valueOrNull;
    final drift = ref.watch(lt1DriftProvider).valueOrNull;
    final history = ref.watch(thresholdHistoryProvider).valueOrNull ?? [];
    final rows = (ref.watch(loadActivitiesProvider).valueOrNull ?? [])
        .where(
          (a) =>
              a.type.toLowerCase().contains('run') &&
              a.metricsJson != null &&
              a.durationSeconds >= (widget.vo2 ? 300 : 2400),
        )
        .toList();
    final selected = rows.where((a) => a.activityId == selectedId).firstOrNull;
    return DefaultTabController(
      length: 3,
      child: LoadSheet(
        title: widget.vo2
            ? '5-MIN MAX TEST — VO2MAX PACE'
            : 'HR DRIFT TEST — LT1',
        centerTitle: true,
        child: Column(
          children: [
            const TabBar(
              labelColor: loadBlue,
              indicatorColor: loadBlue,
              labelStyle: TextStyle(fontSize: 12),
              tabs: [
                Tab(text: 'PROTOCOL'),
                Tab(text: 'CALCULATE'),
                Tab(text: 'HISTORY'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        widget.vo2
                            ? 'After warming up, run five minutes at your fastest sustainable effort. Record the run with speed or distance data.'
                            : 'Record at least 40 minutes of steady running at a constant effort. The test compares heart rate in each half to estimate aerobic drift.',
                        style: const TextStyle(color: Color(0xFFBBBBBB)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.vo2
                            ? 'The fastest five-minute window provides your VO2max pace.'
                            : 'A low drift indicates that this steady effort is at or below your aerobic threshold.',
                        style: loadCaption,
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        widget.vo2
                            ? vo2?.pace ?? 'No result yet'
                            : drift == null
                            ? 'No result yet'
                            : '${drift.lt1} bpm · Drift ${valueText(drift.drift, 1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: selected?.activityId,
                        hint: const Text('Select the test activity'),
                        items: [
                          for (final a in rows)
                            DropdownMenuItem(
                              value: a.activityId,
                              child: Text(
                                a.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: busy
                            ? null
                            : (v) => setState(() => selectedId = v),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: selected == null || busy
                            ? null
                            : () async {
                                setState(() => busy = true);
                                try {
                                  await runUiAction(context, () async {
                                    final error = widget.vo2
                                        ? await ref
                                              .read(vo2MaxProvider.notifier)
                                              .calculate(selected)
                                        : await ref
                                              .read(lt1DriftProvider.notifier)
                                              .calculate(selected);
                                    if (error != null) throw StateError(error);
                                  });
                                } finally {
                                  if (mounted) setState(() => busy = false);
                                }
                              },
                        child: Text(
                          busy
                              ? 'Calculating…'
                              : widget.vo2
                              ? 'Calculate VO2max pace'
                              : 'Calculate LT1',
                        ),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => runUiAction(
                                context,
                                () => widget.vo2
                                    ? ref.read(vo2MaxProvider.notifier).clear()
                                    : ref
                                          .read(lt1DriftProvider.notifier)
                                          .clear(),
                              ),
                        child: const Text('Clear results'),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      LoadTrendChart(
                        pace: widget.vo2,
                        color: loadOrange,
                        points: [
                          for (final h in history)
                            if ((widget.vo2 ? h.vo2PaceSec : h.lt1Bpm) != null)
                              ChartPoint(
                                h.date,
                                (widget.vo2 ? h.vo2PaceSec : h.lt1Bpm)!
                                    .toDouble(),
                              ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
