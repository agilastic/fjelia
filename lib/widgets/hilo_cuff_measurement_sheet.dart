import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_ext.dart';
import '../providers/device_actions_provider.dart';
import '../theme/fjelia_style.dart';
import 'app_widgets.dart';

/// Full-size BLE flow for measuring blood pressure with a paired Hilo cuff.
class HiloCuffMeasurementSheet extends ConsumerStatefulWidget {
  const HiloCuffMeasurementSheet({super.key});

  @override
  ConsumerState<HiloCuffMeasurementSheet> createState() =>
      _HiloCuffMeasurementState();
}

class _HiloCuffMeasurementState
    extends ConsumerState<HiloCuffMeasurementSheet> {
  bool busy = false;
  bool complete = false;
  String? error;
  String status = '';
  ({int systolic, int diastolic, int heartRate})? result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => measure());
  }

  Future<void> measure() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
      complete = false;
      result = null;
      status = context.l10n.scanning;
    });
    try {
      final actions = ref.read(deviceActionsProvider);
      if (await actions.pairedName(DeviceRole.cuff) == null) {
        final found = await actions.scan(DeviceRole.cuff);
        if (!mounted) return;
        final chosen = await showDialog<NearbyDevice>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: Text(context.l10n.chooseHiloCuff),
            children: [
              if (found.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(context.l10n.noCuffFoundWakeYour),
                ),
              for (final device in found)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, device),
                  child: Text(
                    context.l10n.nameRssiDbm(device.name, device.rssi),
                  ),
                ),
            ],
          ),
        );
        if (chosen == null) {
          if (mounted) setState(() => busy = false);
          return;
        }
        await actions.pair(DeviceRole.cuff, chosen);
      }
      if (!mounted) return;
      setState(() => status = context.l10n.measuring);
      final reading = await actions.measureCuffAndSave();
      if (mounted) {
        setState(() {
          result = reading;
          complete = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SheetPage(
    title: context.l10n.plusBpMeasure,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: [
        Icon(
          complete ? Icons.check_circle_outline : Icons.bloodtype_rounded,
          size: 86,
          color: complete ? mint : const Color(0xFFFF5478),
        ),
        const SizedBox(height: 22),
        Text(
          complete ? context.l10n.saved : context.l10n.plusBpMeasure,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        if (result case final reading?) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${reading.systolic}',
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: TextStyle(fontSize: 34, color: fjInk70),
                ),
              ),
              Text(
                '${reading.diastolic}',
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text('mmHg', style: TextStyle(fontSize: 16, color: fjInk70)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${reading.heartRate} bpm',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          context.l10n.plusBpMeasureHint,
          textAlign: TextAlign.center,
          style: TextStyle(color: fjInk70, fontSize: 17, height: 1.4),
        ),
        const SizedBox(height: 28),
        if (busy) ...[
          const LinearProgressIndicator(minHeight: 5),
          const SizedBox(height: 16),
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ],
        if (error != null) ...[
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: busy ? null : measure,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.tryAgain),
          ),
        ],
        if (complete)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.done),
          ),
      ],
    ),
  );
}
