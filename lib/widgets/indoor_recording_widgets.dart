import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_ext.dart';
import '../l10n/plan_text.dart';
import '../providers/indoor_recording_provider.dart';
import 'app_widgets.dart';
import 'ecg_sheet.dart' show recordingDuration;

/// What a connected machine reports: time, distance, speed, power, heart
/// rate, cadence, incline, resistance and energy. Averages once saved.
class IndoorMetrics extends StatelessWidget {
  const IndoorMetrics({super.key, required this.state, required this.saved});
  final IndoorRecorderState state;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, capture = state.capture;
    return Wrap(
      spacing: 20,
      runSpacing: 16,
      children: [
        _metric(l.recordingTime, recordingDuration(capture?.elapsedMs ?? 0)),
        _metric(
          l.distance,
          capture?.totals['d'] == null
              ? '—'
              : '${(capture!.distanceMeters / 1000).toStringAsFixed(2)} km',
        ),
        if (state.live.containsKey('spd') ||
            saved && capture?.average('spd') != null)
          _metric(
            l.recordingSpeed,
            '${((saved ? capture!.average('spd')! : state.live['spd']!) * 3.6).toStringAsFixed(1)} km/h',
          ),
        if (state.live.containsKey('w') ||
            saved && capture?.average('w') != null)
          _metric(
            l.recordingPower,
            '${(saved ? capture!.average('w')! : state.live['w']!).round()} W',
          ),
        if (state.live.containsKey('hr') ||
            saved && capture?.average('hr') != null)
          _metric(
            l.heartRate,
            '${(saved ? capture!.average('hr')! : state.live['hr']!).round()} bpm',
          ),
        if (state.live.containsKey('cad'))
          _metric(
            l.recordingCadence,
            '${state.live['cad']!.toStringAsFixed(1)} /min',
          ),
        if (state.live.containsKey('incline'))
          _metric(
            l.recordingIncline,
            '${state.live['incline']!.toStringAsFixed(1)}%',
          ),
        if (state.live.containsKey('resistance'))
          _metric(l.recordingResistance, '${state.live['resistance']}'),
        if (capture?.totals['kcal'] != null)
          _metric('kcal', capture!.totals['kcal']!.round().toString()),
      ],
    );
  }

  Widget _metric(String label, String value) => SizedBox(
    width: 140,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: muted)),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

/// The current and next interval of a planned session.
class IndoorIntervalCard extends ConsumerWidget {
  const IndoorIntervalCard({super.key, required this.waiting});
  final bool waiting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(indoorRecorderProvider);
    final capture = state.capture;
    if (capture == null || capture.steps.isEmpty) {
      return const SizedBox.shrink();
    }
    final recorder = ref.read(indoorRecorderProvider.notifier);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.indoorCurrentInterval,
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          if (capture.currentStep case final step?) ...[
            Text(
              '${capture.stepIndex + 1}/${capture.steps.length} · ${_stepLabel(context, step.label)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              _stepTarget(step),
              style: const TextStyle(color: mint, fontSize: 20),
            ),
            Text(
              capture.remainingSeconds != null
                  ? recordingDuration(
                      (capture.remainingSeconds! * 1000).round(),
                    )
                  : capture.remainingMeters != null
                  ? '${capture.remainingMeters!.round()} m'
                  : l.recordingNext,
            ),
            if (capture.stepIndex + 1 < capture.steps.length)
              Text(
                '${l.indoorNextInterval}: ${_stepLabel(context, capture.steps[capture.stepIndex + 1].label)} · ${_stepTarget(capture.steps[capture.stepIndex + 1])}',
                style: const TextStyle(color: muted),
              ),
            TextButton.icon(
              onPressed: waiting || state.phase != IndoorPhase.recording
                  ? null
                  : recorder.nextStep,
              icon: const Icon(Icons.skip_next),
              label: Text(l.recordingNext),
            ),
          ] else
            Text(l.indoorPlanComplete),
        ],
      ),
    );
  }
}

/// Control of a connected machine while recording: authorise, take back
/// manual control, set targets, and automatic power for planned intervals.
class IndoorControlCard extends ConsumerStatefulWidget {
  const IndoorControlCard({super.key});
  @override
  ConsumerState<IndoorControlCard> createState() => _ControlState();
}

class _ControlState extends ConsumerState<IndoorControlCard> {
  bool busy = false;

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    await runUiAction(context, action);
    if (mounted) setState(() => busy = false);
  }

  Future<void> setTarget(FtmsTarget target, FtmsRange range) => run(() async {
    final l = context.l10n, state = ref.read(indoorRecorderProvider);
    final controller = TextEditingController();
    final treadmill =
        state.machine == FtmsMachine.treadmill &&
        (target == FtmsTarget.speed || target == FtmsTarget.incline);
    double? value;
    try {
      value = await showDialog<double>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(_targetLabel(context, target)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${range.min}–${range.max} ${target.unit} · Δ ${range.increment}',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _targetLabel(context, target),
                    suffixText: target.unit,
                  ),
                ),
                if (treadmill)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l.indoorTreadmillSafety),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );
                if (value != null && range.accepts(value)) {
                  Navigator.pop(dialog, value);
                }
              },
              child: Text(l.indoorApplyTarget),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
    if (value != null) {
      await ref
          .read(indoorRecorderProvider.notifier)
          .target(target, value, treadmillConfirmed: treadmill);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(indoorRecorderProvider);
    final recorder = ref.read(indoorRecorderProvider.notifier);
    if (!state.connected ||
        state.phase != IndoorPhase.recording ||
        state.ranges.isEmpty) {
      return const SizedBox.shrink();
    }
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!state.authorized)
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => run(() async {
                      if (await confirmAction(
                        context,
                        l.indoorAuthorizeControl,
                        l.indoorControlPrompt,
                      )) {
                        await recorder.authorize();
                      }
                    }),
              icon: const Icon(Icons.tune),
              label: Text(l.indoorAuthorizeControl),
            )
          else ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
              ),
              onPressed: recorder.manualOverride,
              icon: const Icon(Icons.pan_tool_outlined),
              label: Text(l.indoorManualOverride),
            ),
            for (final entry in state.ranges.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_targetLabel(context, entry.key)),
                trailing: const Icon(Icons.edit_outlined),
                onTap: busy ? null : () => setTarget(entry.key, entry.value),
              ),
            if (state.machine == FtmsMachine.bike &&
                state.ranges.containsKey(FtmsTarget.power) &&
                (state.capture?.steps.any(
                      (s) => s.target?.contains('power') ?? false,
                    ) ??
                    false))
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.indoorAutoPower),
                value: state.automaticPower,
                onChanged: busy
                    ? null
                    : (value) => run(() => recorder.automaticPower(value)),
              ),
          ],
        ],
      ),
    );
  }
}

String _targetLabel(BuildContext context, FtmsTarget target) =>
    switch (target) {
      FtmsTarget.speed => context.l10n.recordingSpeed,
      FtmsTarget.incline => context.l10n.recordingIncline,
      FtmsTarget.resistance => context.l10n.recordingResistance,
      FtmsTarget.power => context.l10n.recordingPower,
    };
String _stepLabel(BuildContext context, String label) =>
    stepRoleLabel(context.l10n, switch (label) {
      'warmup' => 'Warm-up',
      'cooldown' => 'Cool-down',
      'recovery' => 'Recovery',
      'rest' => 'Rest',
      'interval' => 'Interval',
      _ => 'Workout',
    });
String _stepTarget(IndoorStep step) {
  if (step.low == null) return step.zone == null ? '—' : 'Z${step.zone}';
  final unit = step.target?.contains('power') ?? false
      ? 'W'
      : step.target?.contains('heart') ?? false
      ? 'bpm'
      : 'm/s';
  return '${step.low!.toStringAsFixed(1)}${step.high == null ? '' : '–${step.high!.toStringAsFixed(1)}'} $unit';
}
