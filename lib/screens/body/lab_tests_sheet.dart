import 'package:fjelia_views/fjelia_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/body_views_provider.dart';
import '../../providers/day_data_provider.dart' show syncStatusListenerProvider;
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';

const _accent = [Color(0xFFFF4D8D), Color(0xFFFFB13D)];

String _intensity(double v, {required bool ride}) {
  if (ride) return '${v.round()} W';
  final s = (1000 / v).round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')} /km';
}

/// Lactate step tests: the thresholds of each, and putting them to use.
class LabTestsSheet extends ConsumerWidget {
  const LabTestsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tests = ref.watch(labTestsProvider);
    return SheetPage(
      title: l.labTitle,
      actions: [
        IconButton(
          tooltip: l.labEnter,
          icon: const Icon(Icons.add),
          onPressed: () => _enter(context, ref),
        ),
      ],
      child: tests.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => DataError(e),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.labExplain, style: TextStyle(fontSize: 12, color: fjInk70)),
            const SizedBox(height: 12),
            if (items.isEmpty) ...[
              Text(l.labEmpty),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _enter(context, ref),
                child: Text(l.labEnter),
              ),
            ],
            for (final t in items) _TestCard(test: t),
          ],
        ),
      ),
    );
  }
}

class _TestCard extends ConsumerWidget {
  const _TestCard({required this.test});
  final LabTestItem test;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = test.result;
    String point(LactatePoint p) => [
      _intensity(p.intensity, ride: test.isRide),
      if (p.heartRate case final hr?) '${hr.round()} bpm',
    ].join(' · ');
    final edits = ref.read(labTestEditsProvider);
    return SectionCard(
      title:
          '${DateFormat.yMMMd().format(test.date)} · ${test.isRide ? l.labBike : l.labRun}',
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (test.note case final n? when n.isNotEmpty)
            Text(n, style: TextStyle(fontSize: 12, color: fjInk70)),
          if (r == null)
            Text(l.labTooFew)
          else ...[
            Text(l.labLt1, style: TextStyle(fontSize: 12, color: fjInk70)),
            Text(
              r.lt1 == null ? '—' : point(r.lt1!),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(l.labLt2, style: TextStyle(fontSize: 12, color: fjInk70)),
            Text(
              r.lt2 == null ? '—' : point(r.lt2!),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (r?.lt2 != null)
                FilledButton(
                  onPressed: () async {
                    await edits.useAsThresholds(test);
                    // The threshold overview reads its history again.
                    ref.read(syncStatusListenerProvider.notifier).state++;
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l.labUsed)));
                    }
                  },
                  child: Text(l.labUse),
                ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await edits.delete(test.id);
                  ref.invalidate(labTestsProvider);
                },
                child: Text(l.labDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _enter(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const _EnterTest(),
      ),
    ).then((_) => ref.invalidate(labTestsProvider));

class _EnterTest extends ConsumerStatefulWidget {
  const _EnterTest();
  @override
  ConsumerState<_EnterTest> createState() => _EnterTestState();
}

class _EnterTestState extends ConsumerState<_EnterTest> {
  var _sport = 'cycling';
  final _rows = [
    for (var i = 0; i < 5; i++)
      [
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ],
  ];

  @override
  void dispose() {
    for (final r in _rows) {
      for (final c in r) {
        c.dispose();
      }
    }
    super.dispose();
  }

  double? _intensityOf(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (_sport == 'cycling') return double.tryParse(t);
    final parts = t.split(':');
    if (parts.length != 2) return null;
    final s =
        (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    return s <= 0 ? null : 1000 / s;
  }

  List<LactateStep> get _steps => [
    for (final r in _rows)
      if (_intensityOf(r[0].text) case final i?)
        if (double.tryParse(r[2].text.trim().replaceAll(',', '.'))
            case final la?)
          LactateStep(
            intensity: i,
            heartRate: double.tryParse(r[1].text.trim()),
            lactate: la,
          ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.labEnter, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'cycling', label: Text(l.labBike)),
                ButtonSegment(value: 'running', label: Text(l.labRun)),
              ],
              selected: {_sport},
              onSelectionChanged: (s) => setState(() => _sport = s.first),
            ),
            const SizedBox(height: 8),
            for (final r in _rows)
              Row(
                children: [
                  for (final (i, c) in r.indexed) ...[
                    Expanded(
                      child: TextField(
                        controller: c,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: [
                            _sport == 'cycling' ? l.labPower : l.labPace,
                            l.labHr,
                            l.labLactate,
                          ][i],
                        ),
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 8),
                  ],
                ],
              ),
            TextButton(
              onPressed: () => setState(
                () => _rows.add([
                  TextEditingController(),
                  TextEditingController(),
                  TextEditingController(),
                ]),
              ),
              child: Text(l.labAddStep),
            ),
            FilledButton(
              onPressed: _steps.length < 3
                  ? null
                  : () async {
                      await ref
                          .read(labTestEditsProvider)
                          .add(
                            date: DateTime.now(),
                            sport: _sport,
                            steps: _steps,
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text(l.labSave),
            ),
          ],
        ),
      ),
    );
  }
}
