import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/strength_workout.dart';
import '../services/strength/strength_progression.dart';
import '../services/strength/strength_repository.dart';
import '../theme/activity_colors.dart';
import 'app_widgets.dart';

/// Shared strength presentation: summary tiles, exercise cards and set rows
/// for planned targets and recorded results alike.

const _tile = Color(0xFF282828);
const _tabular = [FontFeature.tabularFigures()];

String _repsText(int reps, StrengthConvention c) =>
    c.side == StrengthSide.unilateral ? '$reps/side' : '$reps';

/// "70 kg", "20 kg each", "+10 kg", "Assist 20 kg", "Red band", "Bodyweight".
String strengthLoadText(
  StrengthConvention c,
  MassUnit unit, {
  StrengthLoad? load,
  String? resistance,
}) {
  switch (c.loadKind) {
    case StrengthLoadKind.bodyweight:
      return 'Bodyweight';
    case StrengthLoadKind.band:
      return resistance ?? 'Resistance —';
    case StrengthLoadKind.assisted:
      return load == null
          ? 'Assist —'
          : 'Assist ${formatStrengthLoad(load.kg, unit)}';
    case StrengthLoadKind.added:
      return load == null
          ? '+— ${unit.name}'
          : '+${formatStrengthLoad(load.kg, unit)}';
    case StrengthLoadKind.external:
      if (load == null) return '— ${unit.name}';
      final each = c.basis == StrengthLoadBasis.perImplement ? ' each' : '';
      return '${formatStrengthLoad(load.kg, unit)}$each';
  }
}

/// "8–10 reps · 70 kg" or "45 s" for a planned set.
String strengthTargetText(
  StrengthSetTarget t,
  StrengthConvention c,
  MassUnit unit,
) {
  final work = t.timed
      ? formatStrengthSeconds(t.durationSeconds!)
      : t.reps != null
      ? '${_repsText(t.reps!, c)} reps'
      : t.isRange
      ? '${t.repMin}–${t.repMax}${c.side == StrengthSide.unilateral ? '/side' : ''} reps'
      : 'Reps —';
  // No load set yet: the target is the work; a history hint may follow.
  if (c.loadKind == StrengthLoadKind.bodyweight ||
      (c.loadKind.hasKg && t.load == null) ||
      (c.loadKind == StrengthLoadKind.band && t.resistance == null)) {
    return work;
  }
  return '$work · ${strengthLoadText(c, unit, load: t.load, resistance: t.resistance)}';
}

/// "10 × 70 kg", "60 s", or "Not recorded" for an actual set. Unknown
/// values show as a dash, never as zero.
String strengthResultText(
  StrengthSetResult r,
  StrengthConvention c,
  MassUnit unit,
) {
  if (r.status == StrengthSetStatus.unrecorded) return 'Not recorded';
  if (r.status == StrengthSetStatus.skipped) return 'Skipped';
  final work = r.durationSeconds != null
      ? formatStrengthSeconds(r.durationSeconds!)
      : r.reps != null
      ? _repsText(r.reps!, c)
      : '—';
  if (c.loadKind == StrengthLoadKind.bodyweight) {
    return r.durationSeconds != null ? work : '$work reps';
  }
  return '$work × ${strengthLoadText(c, unit, load: r.load, resistance: r.resistance)}';
}

/// Sets with their display numbers: working sets count 1, 2, 3; warm-ups
/// are marked W and do not take a number.
List<(T, int)> numberedSets<T>(List<T> sets) {
  var n = 0;
  return [
    for (final s in sets)
      (
        s,
        switch (s) {
          StrengthSetTarget(kind: StrengthSetKind.warmup) ||
          StrengthSetResult(kind: StrengthSetKind.warmup) => 0,
          _ => ++n,
        },
      ),
  ];
}

String _setLabel(StrengthSetKind kind, int index) =>
    kind == StrengthSetKind.warmup ? 'W' : '$index';

class StrengthTile {
  const StrengthTile(this.label, this.value, {this.caption});
  final String label, value;
  final String? caption;
}

/// Two columns of summary tiles. Values wrap rather than disappear at large
/// text sizes.
class StrengthSummaryGrid extends StatelessWidget {
  const StrengthSummaryGrid({super.key, required this.tiles});
  final List<StrengthTile> tiles;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = (box.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in tiles)
            Semantics(
              container: true,
              label:
                  '${t.label}: ${t.value}${t.caption == null ? '' : ', ${t.caption}'}',
              excludeSemantics: true,
              child: Container(
                width: width,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _tile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.label.toUpperCase(),
                      style: const TextStyle(
                        color: muted,
                        fontSize: 9,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t.value,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        fontFeatures: _tabular,
                      ),
                    ),
                    if (t.caption != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          t.caption!,
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// One exercise in execution order. Planned and recorded cards share this
/// shell; what differs is passed in as rows and actions.
class StrengthExerciseCard extends StatefulWidget {
  const StrengthExerciseCard({
    super.key,
    required this.number,
    required this.name,
    required this.detail,
    this.summary,
    this.rows = const [],
    this.hint,
    this.footer = const [],
    this.menu,
    this.initiallyExpanded = false,
  });
  final int number;
  final String name, detail;
  final String? summary;
  final List<Widget> rows;
  final Widget? hint;
  final List<Widget> footer;
  final Widget? menu;
  final bool initiallyExpanded;
  @override
  State<StrengthExerciseCard> createState() => _StrengthExerciseCardState();
}

class _StrengthExerciseCardState extends State<StrengthExerciseCard> {
  late bool open = widget.initiallyExpanded;
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.number.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: strengthColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .4,
                            ),
                          ),
                          if (widget.detail.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                widget.detail,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: muted,
                                ),
                              ),
                            ),
                          if (widget.summary != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                widget.summary!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontFeatures: _tabular,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  ?widget.menu,
                  if (widget.rows.isNotEmpty)
                    IconButton(
                      tooltip: open
                          ? 'Collapse ${widget.name}'
                          : 'Expand ${widget.name}',
                      onPressed: () => setState(() => open = !open),
                      icon: AnimatedRotation(
                        turns: open ? .5 : 0,
                        duration: reduce
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: const Icon(Icons.expand_more, color: muted),
                      ),
                    ),
                ],
              ),
              if (widget.hint != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(27, 8, 10, 0),
                  child: widget.hint!,
                ),
              AnimatedSize(
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: open
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [...widget.rows, ...widget.footer],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetBadge extends StatelessWidget {
  const _SetBadge(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: strengthColor.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: strengthColor,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        fontFeatures: _tabular,
      ),
    ),
  );
}

/// One planned set: target, load, rest and optional effort/tempo.
class StrengthTargetRow extends StatelessWidget {
  const StrengthTargetRow({
    super.key,
    required this.index,
    required this.target,
    required this.convention,
    required this.unit,
    this.onTap,
    this.trailing,
  });
  final int index;
  final StrengthSetTarget target;
  final StrengthConvention convention;
  final MassUnit unit;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final t = target;
    final value = strengthTargetText(t, convention, unit);
    final extra = [
      if (t.kind != StrengthSetKind.working) t.kind.label,
      if (t.restSeconds != null)
        'Rest ${formatStrengthSeconds(t.restSeconds!)}',
      if (t.effort != null) t.effort!.text,
      if (t.tempo != null) 'Tempo ${t.tempo}',
      if (t.notes != null) t.notes!,
    ];
    return Semantics(
      container: true,
      button: onTap != null,
      label:
          'Set $index${t.kind == StrengthSetKind.working ? '' : ', ${t.kind.label}'}: '
          'target $value${extra.isEmpty ? '' : ', ${extra.join(', ')}'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                _SetBadge(_setLabel(t.kind, index)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFeatures: _tabular,
                        ),
                      ),
                      if (extra.isNotEmpty)
                        Text(
                          extra.join(' · '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: muted,
                            fontFeatures: _tabular,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One recorded set, with the planned target beneath it when linked.
class StrengthResultRow extends StatelessWidget {
  const StrengthResultRow({
    super.key,
    required this.index,
    required this.result,
    required this.convention,
    required this.unit,
    this.target,
    this.onTap,
    this.trailing,
  });
  final int index;
  final StrengthSetResult result;
  final StrengthSetTarget? target;
  final StrengthConvention convention;
  final MassUnit unit;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final r = result;
    final value = strengthResultText(r, convention, unit);
    final planned = target == null
        ? null
        : 'Planned ${strengthTargetText(target!, convention, unit)}';
    final extra = [
      if (r.kind != StrengthSetKind.working) r.kind.label,
      ?planned,
      if (r.restSeconds != null)
        'Rest ${formatStrengthSeconds(r.restSeconds!)}',
      if (r.effort != null) r.effort!.text,
      if (r.notes != null) r.notes!,
    ];
    return Semantics(
      container: true,
      button: onTap != null,
      label:
          'Set $index: ${r.status.label}, $value'
          '${extra.isEmpty ? '' : ', ${extra.join(', ')}'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                _SetBadge(_setLabel(r.kind, index)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFeatures: _tabular,
                          color: r.status == StrengthSetStatus.unrecorded
                              ? muted
                              : null,
                        ),
                      ),
                      if (extra.isNotEmpty)
                        Text(
                          extra.join(' · '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: muted,
                            fontFeatures: _tabular,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StrengthStatusChip(r.status),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

(IconData, Color) strengthStatusStyle(StrengthSetStatus s) => switch (s) {
  StrengthSetStatus.completed => (Icons.check_circle, mint),
  StrengthSetStatus.partial => (Icons.timelapse, const Color(0xFFFFC857)),
  StrengthSetStatus.failed => (Icons.cancel, Colors.redAccent),
  StrengthSetStatus.skipped => (Icons.skip_next, Colors.white54),
  StrengthSetStatus.unrecorded => (Icons.radio_button_unchecked, muted),
};

/// Status by icon and word, never by colour alone.
class StrengthStatusChip extends StatelessWidget {
  const StrengthStatusChip(this.status, {super.key});
  final StrengthSetStatus status;
  @override
  Widget build(BuildContext context) {
    final (icon, color) = strengthStatusStyle(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          status == StrengthSetStatus.unrecorded ? 'Open' : status.label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}

/// "SUPERSET · 3 rounds" with its rest rule.
class StrengthGroupHeader extends StatelessWidget {
  const StrengthGroupHeader({super.key, required this.block, this.menu});
  final StrengthBlock block;
  final Widget? menu;
  @override
  Widget build(BuildContext context) {
    final rests = [
      if (block.restBetweenExercisesSeconds != null)
        '${formatStrengthSeconds(block.restBetweenExercisesSeconds!)} between exercises',
      if (block.restBetweenRoundsSeconds != null)
        '${formatStrengthSeconds(block.restBetweenRoundsSeconds!)} between rounds',
    ];
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.link, size: 16, color: strengthColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${block.kind.label.toUpperCase()} · ${block.rounds} ${block.rounds == 1 ? 'round' : 'rounds'}',
                    style: const TextStyle(
                      color: strengthColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                    ),
                  ),
                  if (rests.isNotEmpty)
                    Text(
                      'Rest ${rests.join(', ')}',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                ],
              ),
            ),
            ?menu,
          ],
        ),
      ),
    );
  }
}

/// Previous comparable values, distinguishable from targets until applied.
class StrengthHistoryHint extends StatelessWidget {
  const StrengthHistoryHint({
    super.key,
    required this.entry,
    required this.convention,
    required this.unit,
    this.onUse,
  });
  final StrengthHistoryEntry entry;
  final StrengthConvention convention;
  final MassUnit unit;
  final VoidCallback? onUse;
  @override
  Widget build(BuildContext context) {
    final load = entry.commonLoad;
    final reps = entry.sets
        .map(
          (s) => s.durationSeconds != null
              ? formatStrengthSeconds(s.durationSeconds!)
              : s.reps?.toString() ?? '—',
        )
        .join(' / ');
    final loads = load != null
        ? strengthLoadText(convention, unit, load: load)
        : entry.sets.any((s) => s.load != null)
        ? 'Variable loads'
        : null;
    final text = 'Last time: ${[?loads, reps].join(' · ')}';
    final when =
        '${DateFormat('d MMM').format(entry.date)}${entry.source == null ? '' : ' · ${entry.source}'}${entry.stale ? ' · older than ${strengthHistoryStaleAfter.inDays ~/ 7} weeks' : ''}';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        border: Border.all(color: strengthColor.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, size: 16, color: strengthColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 12, fontFeatures: _tabular),
                ),
                Text(
                  when,
                  style: TextStyle(
                    fontSize: 10,
                    color: entry.stale ? const Color(0xFFFFC857) : muted,
                  ),
                ),
              ],
            ),
          ),
          if (onUse != null)
            TextButton(
              onPressed: onUse,
              style: TextButton.styleFrom(
                foregroundColor: strengthColor,
                minimumSize: const Size(48, 48),
              ),
              child: Text('Use', semanticsLabel: 'Use $text'),
            ),
        ],
      ),
    );
  }
}

/// Metadata-first fallback for an activity without exercise details.
class StrengthMissingDataCard extends StatelessWidget {
  const StrengthMissingDataCard({
    super.key,
    this.onAdd,
    this.onLogFromPlan,
    this.onCompare,
  });
  final VoidCallback? onAdd, onLogFromPlan, onCompare;
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Exercises',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Exercise details were not provided by this activity source.',
          style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 12),
        if (onLogFromPlan != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: onLogFromPlan,
              icon: const Icon(Icons.playlist_add_check, size: 18),
              label: const Text('Log from plan'),
            ),
          ),
        if (onAdd != null)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: strengthColor,
              side: BorderSide(color: strengthColor.withValues(alpha: .5)),
              minimumSize: const Size(0, 48),
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add exercise details'),
          ),
        if (onCompare != null)
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: onCompare,
            child: const Text('Compare with a saved workout'),
          ),
      ],
    ),
  );
}

/// A reviewed load proposal: the rule, the change and the athlete's choice.
/// Nothing changes until "Apply to this workout".
class StrengthProgressionCard extends StatelessWidget {
  const StrengthProgressionCard({
    super.key,
    required this.evaluation,
    required this.convention,
    required this.unit,
    this.onApply,
    this.onKeep,
    this.onSetIncrement,
    required this.onViewSupporting,
  });
  final StrengthProgressionEvaluation evaluation;
  final StrengthConvention convention;
  final MassUnit unit;
  final VoidCallback? onApply, onKeep, onSetIncrement;
  final VoidCallback onViewSupporting;
  @override
  Widget build(BuildContext context) {
    final e = evaluation;
    final propose = e.outcome == StrengthProgressionOutcome.propose;
    final change = propose
        ? '${strengthLoadText(convention, unit, load: e.currentLoad)} → '
              '${strengthLoadText(convention, unit, load: e.proposedLoad)}'
        : null;
    final button = TextButton.styleFrom(
      foregroundColor: strengthColor,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
    return Semantics(
      container: true,
      label: 'Load suggestion',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 4),
        decoration: BoxDecoration(
          color: strengthColor.withValues(alpha: propose ? .10 : .05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  propose ? Icons.trending_up : Icons.tune,
                  size: 16,
                  color: strengthColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.reason,
                        style: const TextStyle(fontSize: 12, height: 1.35),
                      ),
                      if (change != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            change,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFeatures: _tabular,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              children: [
                if (onApply != null)
                  TextButton(
                    style: button,
                    onPressed: onApply,
                    child: const Text('Apply to this workout'),
                  ),
                if (onKeep != null)
                  TextButton(
                    style: button,
                    onPressed: onKeep,
                    child: const Text('Keep current load'),
                  ),
                if (onSetIncrement != null)
                  TextButton(
                    style: button,
                    onPressed: onSetIncrement,
                    child: const Text('Set load step'),
                  ),
                TextButton(
                  style: button,
                  onPressed: onViewSupporting,
                  child: const Text('View supporting sets'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The sessions behind a proposal, set by set.
Future<void> showStrengthSupportingSets(
  BuildContext context, {
  required StrengthProgressionEvaluation evaluation,
  required StrengthConvention convention,
  required MassUnit unit,
}) => showDialog<void>(
  context: context,
  builder: (c) => AlertDialog(
    title: const Text('Supporting sets'),
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rule v$strengthProgressionRuleVersion: the last '
            '$strengthProgressionMinSessions comparable sessions, every set '
            'done at the top of its repetition target with effort recorded '
            'and not harder than intended. ${evaluation.reason}',
            style: const TextStyle(fontSize: 12, color: muted),
          ),
          for (final s in evaluation.supporting) ...[
            const SizedBox(height: 14),
            Text(
              '${DateFormat('EEE d MMM').format(s.date)}${s.source == null ? '' : ' · ${s.source}'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final (r, n) in numberedSets(s.sets))
              Text(
                'Set $n: ${strengthResultText(r, convention, unit)}'
                '${r.effort == null ? '' : ' · ${r.effort!.text}'}'
                '${r.status == StrengthSetStatus.completed ? '' : ' · ${r.status.label}'}',
                style: const TextStyle(fontSize: 13, fontFeatures: _tabular),
              ),
          ],
          if (evaluation.supporting.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('No recorded sessions yet.'),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
    ],
  ),
);
