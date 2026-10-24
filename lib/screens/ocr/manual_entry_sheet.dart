import '../../providers/manual_measurement_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/device_actions_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/grip_strength_sheet.dart';
import '../../widgets/hilo_report_import_sheet.dart';
import '../../widgets/polar_h10_hrv_sheet.dart';
import '../../utils/decimal.dart';

class ManualEntrySheet extends ConsumerStatefulWidget {
  const ManualEntrySheet({super.key});
  @override
  ConsumerState<ManualEntrySheet> createState() => _EntryState();
}

class _EntryState extends ConsumerState<ManualEntrySheet> {
  String? type;
  DateTime at = DateTime.now();
  bool saving = false;
  String? error;
  // RENPHO scale flow: shown instead of the type list while active.
  bool scaleActive = false;
  String scaleStatus = 'Scanning… step on the scale when ready.';
  ScaleSummary? scaleSaved;
  final fields = <String, TextEditingController>{};
  TextEditingController field(String key) =>
      fields.putIfAbsent(key, () => TextEditingController());
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? read(String key) => parseDecimal(field(key).text);
  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref.read(manualMeasurementActionsProvider).save(type, at, {
        for (final e in fields.entries) e.key: e.value.text,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> cuff() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref.read(deviceActionsProvider).measureAndSave(DeviceRole.cuff);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> scale() async {
    setState(() {
      scaleActive = true;
      saving = true;
      error = null;
      scaleSaved = null;
      scaleStatus = 'Scanning… step on the scale when ready.';
    });
    try {
      final actions = ref.read(deviceActionsProvider);
      final role = await actions.scaleRole();
      if (await actions.pairedId(role) == null) {
        final found = await actions.scan(role);
        if (!mounted) return;
        final chosen = await showDialog<NearbyDevice>(
          context: context,
          builder: (c) => SimpleDialog(
            title: const Text('Choose scale'),
            children: [
              if (found.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No scales found. Step on your scale and try again.',
                  ),
                ),
              for (final s in found)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(c, s),
                  child: Text('${s.name} · ${s.rssi} dBm'),
                ),
            ],
          ),
        );
        if (chosen == null) {
          if (mounted) setState(() => scaleActive = false);
          return;
        }
        await actions.pair(role, chosen);
      }
      final summary = await actions.measureAndSave(
        role,
        onStatus: (text) {
          if (mounted) setState(() => scaleStatus = text);
        },
      );
      if (mounted) {
        setState(() => scaleSaved = summary ?? const ScaleSummary());
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _scaleView(BuildContext context) {
    final saved = scaleSaved;
    if (saved != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        children: [
          const Icon(Icons.check_circle_outline, size: 84, color: mint),
          const SizedBox(height: 28),
          const Text(
            'RENPHO saved:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            saved.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          if (saved.weightKg != null && !saved.hasBodyComposition) ...[
            const SizedBox(height: 16),
            const Text(
              'Only the weight was received. For body fat, muscle and the '
              'other values stand barefoot on the metal electrodes and stay '
              'on until the scale finishes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      );
    }
    final waist = ref.watch(userProfileProvider).valueOrNull?.waistCm;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: mint.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bluetooth_searching, color: mint),
            ),
            const SizedBox(width: 14),
            const Text(
              'RENPHO Scale (BLE)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: mint.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: mint.withValues(alpha: .3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bluetooth, color: mint, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Step on your RENPHO scale and stay on until the '
                      'reading appears.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.straighten, color: muted, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      waist == null
                          ? 'Add your waist in Profile for visceral fat.'
                          : 'Waist: ${waist.toStringAsFixed(waist % 1 == 0 ? 0 : 1)} cm — update monthly in Profile',
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.redAccent))
              else
                Text(scaleStatus, style: const TextStyle(color: mint)),
              const SizedBox(height: 10),
              if (saving) const LinearProgressIndicator(minHeight: 4),
            ],
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: saving ? null : scale,
          child: Text(saving ? 'Measuring…' : 'Try again'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: saving
              ? null
              : () => setState(() {
                  scaleActive = false;
                  error = null;
                }),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Change measurement type'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final definitions = <String, List<(String, String)>>{
      'Blood Pressure': [
        ('Systolic', 'mmHg'),
        ('Diastolic', 'mmHg'),
        ('Heart Rate', 'bpm'),
      ],
      'Weight Scale': [('Weight', 'kg'), ('Body Fat', '%'), ('BMI', '')],
      'Sleep': [('Duration', 'h'), ('Deep', 'h'), ('REM', 'h')],
      'SpO₂ / Pulse Oximeter': [('SpO₂', '%'), ('Heart Rate', 'bpm')],
      'Manual Activity': [
        ('Activity name', ''),
        ('Sport', ''),
        ('Duration', 'min'),
        ('Distance', 'km'),
        ('Heart Rate', 'bpm'),
      ],
    };
    if (scaleActive) {
      return SheetPage(
        title: scaleSaved != null ? 'Saved' : 'RENPHO Scale (BLE)',
        child: _scaleView(context),
      );
    }
    return SheetPage(
      title: 'Add Measurement',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        children: [
          if (saving) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
          if (type == null) ...[
            const Text(
              'What are you measuring?',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final e in <(String, IconData)>[
              ('Manual Activity', Icons.directions_run),
              ('Sleep', Icons.bedtime_outlined),
              ('Blood Pressure', Icons.monitor_heart_outlined),
              ('Add Hilo BP report (PDF)', Icons.picture_as_pdf_outlined),
              ('Hilo Cuff (BLE)', Icons.bluetooth),
              ('RENPHO Scale (BLE)', Icons.monitor_weight_outlined),
              ('SpO₂ / Pulse Oximeter', Icons.air),
              ('Weight Scale', Icons.monitor_weight_outlined),
              ('Grip Strength', Icons.back_hand_outlined),
              ('Polar H10 HRV measurement', Icons.monitor_heart_outlined),
            ])
              SectionCard(
                child: ListTile(
                  enabled: !saving,
                  dense: true,
                  leading: Icon(e.$2, color: mint),
                  title: Text(e.$1),
                  onTap: () {
                    if (e.$1 == 'Polar H10 HRV measurement') {
                      showAppSheet(context, const PolarH10HrvSheet());
                    } else if (e.$1 == 'Add Hilo BP report (PDF)') {
                      showAppSheet(context, const HiloReportImportSheet());
                    } else if (e.$1 == 'Grip Strength') {
                      showAppSheet(context, const GripStrengthSheet());
                    } else if (e.$1 == 'Hilo Cuff (BLE)') {
                      cuff();
                    } else if (e.$1 == 'RENPHO Scale (BLE)') {
                      scale();
                    } else {
                      setState(() => type = e.$1);
                    }
                  },
                ),
              ),
          ] else ...[
            TextButton(
              onPressed: saving ? null : () => setState(() => type = null),
              child: const Text('Choose another measurement'),
            ),
            SectionLabel(type!),
            ListTile(
              title: Text(dayText(at)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: at,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (d == null || !context.mounted) return;
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(at),
                );
                if (t != null) {
                  setState(
                    () =>
                        at = DateTime(d.year, d.month, d.day, t.hour, t.minute),
                  );
                }
              },
            ),
            for (final e in definitions[type] ?? <(String, String)>[])
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextField(
                  controller: field(e.$1),
                  keyboardType: e.$1 == 'Sport' || e.$1 == 'Activity name'
                      ? TextInputType.text
                      : const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: e.$1,
                    suffixText: e.$2,
                  ),
                ),
              ),
            FilledButton(
              onPressed: saving ? null : save,
              child: const Text('Save measurement'),
            ),
          ],
        ],
      ),
    );
  }
}
