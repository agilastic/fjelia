import '../../widgets/strava_import_sheet.dart';
import '../../l10n/formats.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/manual_measurement_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/device_actions_provider.dart';
import '../../providers/polar_h10_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/grip_strength_sheet.dart';
import '../../widgets/hilo_report_import_sheet.dart';
import '../../widgets/polar_h10_hrv_sheet.dart';
import '../../widgets/waist_sheet.dart';
import '../../widgets/ecg_sheet.dart';
import '../../widgets/manual_activity_sheet.dart';
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
      title: type == null
          ? context.l10n.plusTitle
          : context.l10n.addMeasurement,
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
            ..._menu(context),
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

  /// Opens what an entry of the menu stands for. [id] is an identifier,
  /// never the translated label: the forms and the save look it up.
  void _open(String id) {
    switch (id) {
      case 'Record':
        showAppSheet(context, const ManualActivitySheet());
      case 'ECG':
        showAppSheet(context, const EcgSheet());
      case 'Polar H10 HRV measurement':
        showAppSheet(context, const PolarH10HrvSheet());
      case 'Add Hilo BP report (PDF)':
        showAppSheet(context, const HiloReportImportSheet());
      case 'Grip Strength':
        showAppSheet(context, const GripStrengthSheet());
      case 'Waist Circumference':
        showAppSheet(context, const WaistSheet());
      case 'Import':
        showAppSheet(context, const ImportSheet());
      case 'Hilo Cuff (BLE)':
        cuff();
      case 'RENPHO Scale (BLE)':
        scale();
      default:
        setState(() => type = id);
    }
  }

  /// The menu: the live workout on top, then everything by topic.
  List<Widget> _menu(BuildContext context) {
    final l = context.l10n;
    final h10 = ref.watch(polarH10PairedProvider).valueOrNull != null;
    final groups = <(String, Color, List<_Entry>)>[
      (
        l.plusGroupTraining,
        mint,
        [
          _Entry(
            'Manual Activity',
            Icons.edit_calendar_rounded,
            l.plusLogWorkout,
            l.plusLogWorkoutHint,
          ),
          _Entry(
            'Import',
            Icons.download_rounded,
            l.plusImport,
            l.plusImportHint,
          ),
        ],
      ),
      (
        l.plusGroupHeart,
        _heartColor,
        [
          _Entry(
            'ECG',
            Icons.monitor_heart_rounded,
            l.plusEcg,
            l.plusEcgHint,
            badge: 'LIVE',
          ),
          // Only with a strap paired in Settings → Connections.
          if (h10)
            _Entry(
              'Polar H10 HRV measurement',
              Icons.favorite_rounded,
              l.plusHrv,
              l.plusHrvHint,
              badge: 'LIVE',
            ),
          _Entry(
            'Hilo Cuff (BLE)',
            Icons.bluetooth_rounded,
            l.plusBpMeasure,
            l.plusBpMeasureHint,
            badge: 'BLE',
          ),
          _Entry(
            'Blood Pressure',
            Icons.speed_rounded,
            l.plusBpLog,
            l.plusBpLogHint,
          ),
          _Entry(
            'Add Hilo BP report (PDF)',
            Icons.picture_as_pdf_rounded,
            l.plusBpReport,
            l.plusBpReportHint,
            badge: 'PDF',
          ),
          _Entry(
            'SpO₂ / Pulse Oximeter',
            Icons.air_rounded,
            l.plusSpo2,
            l.plusSpo2Hint,
          ),
        ],
      ),
      (
        l.plusGroupBody,
        _bodyColor,
        [
          _Entry(
            'RENPHO Scale (BLE)',
            Icons.monitor_weight_rounded,
            l.plusWeigh,
            l.plusWeighHint,
            badge: 'BLE',
          ),
          _Entry(
            'Weight Scale',
            Icons.scale_rounded,
            l.plusWeightLog,
            l.plusWeightLogHint,
          ),
          _Entry(
            'Waist Circumference',
            Icons.straighten_rounded,
            l.plusWaist,
            l.plusWaistHint,
          ),
          _Entry(
            'Grip Strength',
            Icons.back_hand_rounded,
            l.plusGrip,
            l.plusGripHint,
          ),
        ],
      ),
      (
        l.plusGroupRecovery,
        _recoveryColor,
        [_Entry('Sleep', Icons.bedtime_rounded, l.plusSleep, l.plusSleepHint)],
      ),
    ];
    final enabled = !saving;
    return [
      _HeroTile(
        title: l.plusStartWorkout,
        hint: l.plusStartWorkoutHint,
        onTap: enabled ? () => _open('Record') : null,
      ),
      for (final (title, color, entries) in groups) ...[
        const SizedBox(height: 22),
        _GroupHeader(title, color),
        const SizedBox(height: 10),
        for (var i = 0; i < entries.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final e in [
                    entries[i],
                    if (i + 1 < entries.length) entries[i + 1],
                  ]) ...[
                    if (e != entries[i]) const SizedBox(width: 10),
                    Expanded(
                      child: _PlusTile(
                        entry: e,
                        color: color,
                        onTap: enabled ? () => _open(e.id) : null,
                      ),
                    ),
                  ],
                  if (i + 1 >= entries.length) ...[
                    const SizedBox(width: 10),
                    const Expanded(child: SizedBox()),
                  ],
                ],
              ),
            ),
          ),
      ],
    ];
  }
}

const _heartColor = Color(0xFFFF5C7A);
const _bodyColor = Color(0xFFA78BFA);
const _recoveryColor = Color(0xFF60A5FA);

class _Entry {
  const _Entry(this.id, this.icon, this.title, this.hint, {this.badge});
  final String id, title, hint;
  final IconData icon;

  /// LIVE, BLE or PDF: the same in every language.
  final String? badge;
}

/// The main action: a live workout, as a bright card above the rest.
class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.title, required this.hint, this.onTap});
  final String title, hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('plus-start-workout'),
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [mint, Color(0xFF38BDF8)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hint,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: .72),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.black),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.title, this.color);
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: .6), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    ),
  );
}

/// One entry: an icon in a gradient bubble, a short name and a hint.
class _PlusTile extends StatelessWidget {
  const _PlusTile({required this.entry, required this.color, this.onTap});
  final _Entry entry;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: .16), panel],
            ),
            border: Border.all(color: color.withValues(alpha: .28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withValues(alpha: .55)],
                      ),
                    ),
                    child: Icon(entry.icon, color: Colors.black, size: 22),
                  ),
                  const Spacer(),
                  if (entry.badge case final badge?)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: color,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                entry.hint,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The type names are identifiers; this is what the user reads.
String _typeLabel(BuildContext context, String type) => switch (type) {
  'Manual Activity' => context.l10n.plusLogWorkout,
  'Sleep' => context.l10n.plusSleep,
  'Blood Pressure' => context.l10n.plusBpLog,
  'SpO₂ / Pulse Oximeter' => context.l10n.plusSpo2,
  'Weight Scale' => context.l10n.plusWeightLog,
  _ => type,
};
