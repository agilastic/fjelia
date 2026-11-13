import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_ext.dart';
import '../providers/ecg_provider.dart';
import '../providers/polar_h10_provider.dart';
import 'app_widgets.dart';
import 'ecg_sheet.dart' show chooseTrainingDevice;

/// Overnight H10 capture. This records raw ECG and motion only; it does not
/// infer sleep stages, breathing rate, or a medical finding.
class SleepEcgRecordingSheet extends ConsumerStatefulWidget {
  const SleepEcgRecordingSheet({super.key});

  @override
  ConsumerState<SleepEcgRecordingSheet> createState() =>
      _SleepEcgRecordingSheetState();
}

class _SleepEcgRecordingSheetState
    extends ConsumerState<SleepEcgRecordingSheet> {
  TrainingDevice? selected;
  bool busy = false;

  Future<void> _choose() async {
    setState(() => busy = true);
    try {
      final devices = await ref.read(ecgActionsProvider).scan();
      if (!mounted) return;
      final device = await chooseTrainingDevice(
        context,
        devices,
        title: context.l10n.ecgChooseDevice,
        empty: context.l10n.noPolarH10FoundWear,
      );
      if (device != null) {
        await ref.read(ecgActionsProvider).remember(device);
        if (mounted) setState(() => selected = device);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _start(TrainingDevice device) async {
    setState(() => busy = true);
    try {
      await ref
          .read(ecgRecorderProvider.notifier)
          .start(device, withAcceleration: true, purpose: 'sleep');
      final state = ref.read(ecgRecorderProvider);
      if (mounted && state.phase == EcgPhase.failed && state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final capture = ref.watch(ecgRecorderProvider);
    final paired = ref.watch(polarH10PairedProvider).valueOrNull;
    final device =
        selected ??
        (paired == null
            ? null
            : TrainingDevice(id: paired.id, name: paired.name));

    return SheetPage(
      title: l.sleepEcgTitle,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bedtime_rounded, color: mint, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.sleepEcgTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l.sleepEcgDescription),
                const SizedBox(height: 12),
                Text(
                  l.ecgPrivacy,
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (busy ||
              capture.phase == EcgPhase.connecting ||
              capture.phase == EcgPhase.saving)
            const LinearProgressIndicator(),
          if (capture.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                capture.error!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          if (capture.active) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    capture.device?.name ?? 'Polar H10',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(_duration(capture.durationMs)),
                  const SizedBox(height: 8),
                  Text(l.ecgSamples(capture.count)),
                  Text(l.sleepEcgMotionSamples(capture.accelerationSamples)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: capture.phase == EcgPhase.recording
                        ? () => ref.read(ecgRecorderProvider.notifier).stop()
                        : null,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(l.ecgStopSave),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.sleepEcgKeepOpenHint,
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ] else ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bluetooth, color: mint),
                    title: Text(device?.name ?? l.ecgChooseDevice),
                    trailing: const Icon(Icons.search),
                    onTap: busy ? null : _choose,
                  ),
                  FilledButton.icon(
                    onPressed: busy || device == null
                        ? (busy ? null : _choose)
                        : () => _start(device),
                    icon: const Icon(Icons.nightlight_round),
                    label: Text(l.sleepEcgStart),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _duration(int milliseconds) {
    final totalMinutes = milliseconds ~/ 60000;
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
