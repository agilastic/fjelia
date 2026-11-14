import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../db/database.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../providers/plan_schedule_provider.dart';
import '../services/absence_service.dart';
import '../theme/fjelia_style.dart';
import 'app_widgets.dart';

IconData absenceIcon(String kind) => switch (kind) {
  'illness' => Icons.sick_outlined,
  'injury' => Icons.healing_rounded,
  'vacation' => Icons.beach_access_rounded,
  _ => Icons.ac_unit_rounded,
};

String absenceLabel(AppLocalizations l, String kind) => switch (kind) {
  'illness' => l.absenceIllness,
  'injury' => l.absenceInjury,
  'vacation' => l.absenceVacation,
  _ => l.absenceOffseason,
};

/// From the Aurora palette: attention amber, warning pink, sky, plan violet.
Color _absenceColor(String kind) => switch (kind) {
  'illness' => const Color(0xFFFFB13D),
  'injury' => const Color(0xFFFF4D8D),
  'vacation' => const Color(0xFF6FA8FF),
  _ => const Color(0xFF9D7BFF),
};

/// The sky pair: rest and recovery.
const _sky = [Color(0xFF6FA8FF), Color(0xFF3EE0FF)];

String _range(BuildContext context, DateTime from, DateTime to) {
  final f = DateFormat.MMMEd(Localizations.localeOf(context).toString());
  return from == to ? f.format(from) : '${f.format(from)} – ${f.format(to)}';
}

/// Ill, injured, on holiday or in the off-season, for a span of days: the
/// plan leaves those days free and builds itself again around them.
class AbsenceSheet extends ConsumerStatefulWidget {
  const AbsenceSheet({super.key});

  @override
  ConsumerState<AbsenceSheet> createState() => _AbsenceState();
}

class _AbsenceState extends ConsumerState<AbsenceSheet> {
  String kind = 'illness';
  DateTimeRange? range;
  final note = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today.subtract(const Duration(days: 60)),
      lastDate: today.add(const Duration(days: 400)),
      initialDateRange: range ?? DateTimeRange(start: today, end: today),
    );
    if (picked != null) setState(() => range = picked);
  }

  Future<void> _save() async {
    final r = range;
    if (r == null) return;
    setState(() => saving = true);
    await runUiAction(context, () async {
      await ref.read(addAbsenceProvider)(
        kind: kind,
        start: r.start,
        end: r.end,
        note: note.text,
      );
      if (!mounted) return;
      note.clear();
      setState(() => range = null);
    });
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final recent = DateTime(now.year, now.month, now.day - 30);
    final absences = [
      for (final a
          in ref.watch(absencesProvider).valueOrNull ?? const <Absence>[])
        if (!a.endDay.isBefore(recent)) a,
    ];
    final r = range;
    return SheetPage(
      title: l.plusAbsence,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 32,
        ),
        children: [
          SectionCard(
            accent: _sky,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final k in absenceKinds)
                      ChoiceChip(
                        label: Text(absenceLabel(l, k)),
                        selected: kind == k,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => kind = k),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const Key('absence-range'),
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(
                    r == null
                        ? l.absencePeriod
                        : _range(context, r.start, r.end),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  maxLength: 120,
                  decoration: InputDecoration(labelText: l.absenceNote),
                ),
                Text(
                  l.absenceExplain,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 14),
                // The sheet's one action, plain like Save on training times.
                FilledButton(
                  onPressed: r == null || saving ? null : _save,
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.absenceSave),
                ),
              ],
            ),
          ),
          if (absences.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: l.absenceEntered,
              accent: _sky,
              child: Column(
                children: [
                  for (final a in absences)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // The tile head of a metric card: a tinted circle
                          // with the kind's icon.
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _absenceColor(a.kind)
                                  .withValues(alpha: .16),
                            ),
                            child: Icon(
                              absenceIcon(a.kind),
                              size: 14,
                              color: fjAccent(_absenceColor(a.kind)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  absenceLabel(l, a.kind),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: fjInk,
                                  ),
                                ),
                                Text(
                                  [
                                    _range(context, a.startDay, a.endDay),
                                    if (a.note != null) a.note!,
                                  ].join(' · '),
                                  style: TextStyle(fontSize: 12, color: muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l.absenceRemove,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: muted,
                            ),
                            onPressed: saving
                                ? null
                                : () => runUiAction(
                                    context,
                                    () => ref.read(removeAbsenceProvider)(a),
                                  ),
                          ),
                        ],
                      ),
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
