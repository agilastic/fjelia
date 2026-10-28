import '../../l10n/formats.dart';
import '../../l10n/l10n_ext.dart';
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
  String scaleStatus = tr.scanningStepOnTheScale;
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
      scaleStatus = context.l10n.scanningStepOnTheScale;
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
            title: Text(context.l10n.chooseScale),
            children: [
              if (found.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(context.l10n.noScalesFoundStepOn),
                ),
              for (final s in found)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(c, s),
                  child: Text(context.l10n.nameRssiDbm(s.name, s.rssi)),
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
          Text(
            context.l10n.renphoSaved,
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
            Text(
              context.l10n.onlyTheWeightWasReceived,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.done),
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
            Text(
              context.l10n.renphoScaleBle2,
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
                          ? context.l10n.addYourWaistInProfile
                          : context.l10n.waistWaistCmUpdateMonthly(
                              waist.fixed(waist % 1 == 0 ? 0 : 1),
                            ),
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
          child: Text(saving ? context.l10n.measuring : context.l10n.tryAgain),
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
          label: Text(context.l10n.changeMeasurementType),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final definitions = <String, List<(String, String)>>{
      'Blood Pressure': [
        (context.l10n.systolic, 'mmHg'),
        (context.l10n.diastolic, 'mmHg'),
        (context.l10n.heartRate, 'bpm'),
      ],
      'Weight Scale': [
        (context.l10n.weight, 'kg'),
        (context.l10n.bodyFat, '%'),
        ('BMI', ''),
      ],
      'Sleep': [
        (context.l10n.duration, 'h'),
        (context.l10n.deep, 'h'),
        ('REM', 'h'),
      ],
      'SpO₂ / Pulse Oximeter': [
        (context.l10n.spo, '%'),
        (context.l10n.heartRate, 'bpm'),
      ],
      'Manual Activity': [
        (context.l10n.activityName, ''),
        (context.l10n.sport, ''),
        (context.l10n.duration, 'min'),
        (context.l10n.distance, 'km'),
        (context.l10n.heartRate, 'bpm'),
      ],
    };
    if (scaleActive) {
      return SheetPage(
        title: scaleSaved != null
            ? context.l10n.saved
            : context.l10n.renphoScaleBle2,
        child: _scaleView(context),
      );
    }
    return SheetPage(
      title: context.l10n.addMeasurement,
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
            Text(
              context.l10n.whatAreYouMeasuring,
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final e in <(String, IconData)>[
              (context.l10n.manualActivity, Icons.directions_run),
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
                  title: Text(_typeLabel(context, e.$1)),
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
              child: Text(context.l10n.chooseAnotherMeasurement),
            ),
            SectionLabel(_typeLabel(context, type!)),
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
                  keyboardType:
                      e.$1 == context.l10n.sport ||
                          e.$1 == context.l10n.activityName
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
              child: Text(context.l10n.saveMeasurement),
            ),
          ],
        ],
      ),
    );
  }
}

/// The type names are identifiers; this is what the user reads.
String _typeLabel(BuildContext context, String type) => switch (type) {
  'Manual Activity' => context.l10n.manualActivity,
  'Sleep' => context.l10n.typeSleep,
  'Blood Pressure' => context.l10n.typeBloodPressure,
  'Add Hilo BP report (PDF)' => context.l10n.addHiloBpReportPdf,
  'Hilo Cuff (BLE)' => context.l10n.hiloCuffBle,
  'RENPHO Scale (BLE)' => context.l10n.renphoScaleBle2,
  'SpO₂ / Pulse Oximeter' => context.l10n.typeSpo2,
  'Weight Scale' => context.l10n.typeWeightScale,
  'Grip Strength' => context.l10n.gripStrength,
  'Polar H10 HRV measurement' => context.l10n.polarH10HrvMeasurement,
  _ => type,
};
