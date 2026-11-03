import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../db/database.dart';
import '../l10n/formats.dart';
import '../l10n/l10n_ext.dart';
import '../models/waist_ratios.dart';
import '../providers/user_profile_provider.dart';
import '../providers/waist_provider.dart';
import '../utils/decimal.dart';
import 'app_widgets.dart';

const _hipColor = Colors.orange;

Color waistRiskColor(WaistRisk risk) => switch (risk) {
  WaistRisk.low => Colors.lightBlueAccent,
  WaistRisk.healthy => mint,
  WaistRisk.increased => Colors.amber,
  WaistRisk.high => Colors.redAccent,
};

String waistRiskLabel(BuildContext context, WaistRisk risk) => switch (risk) {
  WaistRisk.low => context.l10n.waistRiskLow,
  WaistRisk.healthy => context.l10n.waistRiskHealthy,
  WaistRisk.increased => context.l10n.waistRiskIncreased,
  WaistRisk.high => context.l10n.waistRiskHigh,
};

String _cm(double v) => v.fixed(v % 1 == 0 ? 0 : 1);

/// Waist circumference: add one, see the ratios and the history.
class WaistSheet extends ConsumerStatefulWidget {
  const WaistSheet({super.key});
  @override
  ConsumerState<WaistSheet> createState() => _WaistState();
}

class _WaistState extends ConsumerState<WaistSheet> {
  final waist = TextEditingController(), hip = TextEditingController();
  DateTime at = DateTime.now();
  bool saving = false;
  String? error;

  @override
  void dispose() {
    waist.dispose();
    hip.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: at,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(at),
    );
    if (t != null) {
      setState(() => at = DateTime(d.year, d.month, d.day, t.hour, t.minute));
    }
  }

  Future<void> _save() async {
    final w = parseDecimal(waist.text);
    final h = hip.text.trim().isEmpty ? null : parseDecimal(hip.text);
    bool valid(double? v) => v != null && v >= 20 && v <= 300;
    if (!valid(w) || (hip.text.trim().isNotEmpty && !valid(h))) {
      setState(() => error = context.l10n.enterValidWaist);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref.read(waistActionsProvider).add(at, w!, hipCm: h);
      if (!mounted) return;
      waist.clear();
      hip.clear();
      FocusScope.of(context).unfocus();
      setState(() => at = DateTime.now());
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    return SheetPage(
      title: context.l10n.waistCircumference,
      child: ref
          .watch(waistMeasurementsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => DataError(e),
            data: (rows) => ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              children: [
                WaistSummaryCard(
                  points: [for (final r in rows) waistPoint(r)],
                  profileWaistCm: profile?.waistCm,
                  heightCm: profile?.heightCm,
                  sex: profile?.sex ?? 'm',
                ),
                _entry(context),
                if (rows.isNotEmpty) ...[
                  SectionLabel(context.l10n.history),
                  SectionCard(
                    child: HistoryChart(
                      height: 170,
                      points: [
                        for (final r in rows)
                          ChartPoint(r.measuredAt, r.waistCm),
                      ],
                      secondary: [
                        for (final r in rows)
                          if (r.hipCm != null)
                            ChartPoint(r.measuredAt, r.hipCm!),
                      ],
                      secondaryColor: _hipColor,
                    ),
                  ),
                  for (final r in rows.reversed) _row(context, r),
                ],
              ],
            ),
          ),
    );
  }

  Widget _entry(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: saving ? null : _pickTime,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.event, size: 18, color: muted),
                const SizedBox(width: 10),
                Expanded(child: Text(DateFormat.yMMMd().add_Hm().format(at))),
                const Icon(
                  Icons.edit_calendar_outlined,
                  size: 18,
                  color: muted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: waist,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.waist,
                  suffixText: 'cm',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: hip,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.hipOptional,
                  suffixText: 'cm',
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(context.l10n.saveMeasurement),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.waistHowToMeasure,
          style: const TextStyle(color: muted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.waistSyncsProfile,
          style: const TextStyle(color: muted, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _row(BuildContext context, WaistMeasurement r) => ListTile(
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: Icon(
      r.source == 'profile' ? Icons.settings_outlined : Icons.straighten,
      size: 18,
      color: muted,
    ),
    title: Text(
      r.hipCm == null
          ? '${_cm(r.waistCm)} cm'
          : context.l10n.waistAndHip(_cm(r.waistCm), _cm(r.hipCm!)),
    ),
    subtitle: Text(DateFormat.yMMMd().add_Hm().format(r.measuredAt)),
    trailing: IconButton(
      tooltip: context.l10n.deleteMeasurement,
      icon: const Icon(Icons.delete_outline),
      onPressed: () async {
        if (await confirmAction(
              context,
              context.l10n.deleteMeasurement,
              context.l10n.waistDeleteText,
            ) &&
            context.mounted) {
          await runUiAction(
            context,
            () => ref.read(waistActionsProvider).delete(r.id),
          );
        }
      },
    ),
  );
}

/// The waist now, how it changed, and the ratios that follow from it.
class WaistSummaryCard extends StatelessWidget {
  const WaistSummaryCard({
    super.key,
    required this.points,
    required this.profileWaistCm,
    required this.heightCm,
    required this.sex,
  });

  /// Oldest first.
  final List<WaistPoint> points;
  final double? profileWaistCm, heightCm;
  final String sex;

  @override
  Widget build(BuildContext context) {
    final latest = points.lastOrNull;
    final current = latest?.waistCm ?? profileWaistCm;
    if (current == null) {
      return SectionCard(
        child: Row(
          children: [
            const Icon(Icons.straighten, color: muted),
            const SizedBox(width: 12),
            Expanded(child: Text(context.l10n.noWaistYet)),
          ],
        ),
      );
    }
    final whtr = waistToHeight(current, heightCm);
    final hipCm = latestHip(points);
    final whr = waistToHip(current, hipCm);
    final risk = waistRisk(current, sex);
    final changes = [
      (
        context.l10n.waistChange30d,
        waistChange(points, const Duration(days: 30)),
      ),
      (
        context.l10n.waistChange90d,
        waistChange(points, const Duration(days: 90)),
      ),
      (
        context.l10n.waistChange1y,
        waistChange(points, const Duration(days: 365)),
      ),
    ].where((c) => c.$2 != null).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [waistRiskColor(risk).withValues(alpha: .22), panel],
        ),
        border: Border.all(color: waistRiskColor(risk).withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _cm(current),
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                child: Text('cm', style: TextStyle(color: muted)),
              ),
              const Spacer(),
              _Badge(waistRiskLabel(context, risk), waistRiskColor(risk)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            latest == null
                ? context.l10n.waistFromProfile
                : DateFormat.yMMMd().add_Hm().format(latest.at),
            style: const TextStyle(color: muted, fontSize: 11),
          ),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, delta) in changes)
                  _ChangeChip(label, delta!),
              ],
            ),
          ],
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Ratio(
                    title: context.l10n.waistToHeightRatio,
                    short: 'WHtR',
                    value: whtr,
                    risk: whtr == null ? null : whtrRisk(whtr),
                    missing: context.l10n.waistNeedsHeight,
                    hint: context.l10n.whtrTargetHint,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Ratio(
                    title: context.l10n.waistToHipRatio,
                    short: 'WHR',
                    value: whr,
                    risk: whr == null ? null : whrRisk(whr, sex),
                    missing: context.l10n.waistNeedsHip,
                    hint: hipCm == null
                        ? null
                        : context.l10n.hipValue(_cm(hipCm)),
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

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip(this.label, this.delta);
  final String label;
  final double delta;
  @override
  Widget build(BuildContext context) {
    // A smaller waist is the good direction.
    final color = delta.abs() < .5
        ? muted
        : delta < 0
        ? mint
        : Colors.amber;
    final sign = delta > 0
        ? '+'
        : delta < 0
        ? '−'
        : '±';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
            TextSpan(
              text: '$sign${delta.abs().fixed(1)} cm',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ratio extends StatelessWidget {
  const _Ratio({
    required this.title,
    required this.short,
    required this.value,
    required this.risk,
    required this.missing,
    this.hint,
  });
  final String title, short, missing;
  final String? hint;
  final double? value;
  final WaistRisk? risk;

  @override
  Widget build(BuildContext context) {
    final color = risk == null ? muted : waistRiskColor(risk!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            short,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .8,
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 10),
          ),
          const SizedBox(height: 6),
          if (value == null)
            Text(missing, style: const TextStyle(fontSize: 11))
          else ...[
            Text(
              value!.fixed(2),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              waistRiskLabel(context, risk!),
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
          if (hint != null && value != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: const TextStyle(color: muted, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}
