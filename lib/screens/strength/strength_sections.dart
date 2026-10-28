import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../db/database.dart' show ActivityRecord;
import '../../models/strength_workout.dart';
import '../../providers/plan_schedule_provider.dart';
import '../../providers/strength_provider.dart';
import '../../services/strength/strength_estimates.dart';
import '../../services/strength/strength_plan_edits.dart';
import '../../services/strength/strength_progression.dart';
import '../../services/strength/strength_repository.dart';
import '../../services/strength/strength_statistics.dart';
import '../../theme/activity_colors.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/strength_demo.dart';
import '../../widgets/strength_widgets.dart';
import 'strength_focus_screen.dart';
import 'strength_forms.dart';
import 'strength_trend_sheet.dart';
import 'strength_log_editor.dart';
import 'strength_plan_editor.dart';

/// Strength content for the existing planned and completed detail sheets.

String _minutes(int seconds) => '${(seconds / 60).round()} min';

String _volumeText(PartialTotal v, MassUnit unit) {
  String n(double kg) => formatStrengthNumber(unit.fromKg(kg));
  return v.isRange
      ? '${n(v.min)}–${n(v.max)} ${unit.name}·reps'
      : '${n(v.min)} ${unit.name}·reps';
}

String? _volumeCaption(PartialTotal v) =>
    v.complete ? null : tr.knownForKnownOfOf(v.known, v.of);

Widget _heading(String title) => Padding(
  padding: const EdgeInsets.only(top: 22, bottom: 10),
  child: Semantics(
    header: true,
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        color: muted,
        fontWeight: FontWeight.w700,
        letterSpacing: .8,
      ),
    ),
  ),
);

ButtonStyle _outlined() => OutlinedButton.styleFrom(
  foregroundColor: strengthColor,
  side: BorderSide(color: strengthColor.withValues(alpha: .5)),
  minimumSize: const Size(0, 48),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

/// Opens the exercise's trend in its own comparable context.
Widget _historyButton(
  BuildContext context, {
  required String name,
  required String contextKey,
  required String equipment,
  required StrengthConvention convention,
}) => Align(
  alignment: Alignment.centerLeft,
  child: TextButton.icon(
    style: TextButton.styleFrom(
      foregroundColor: strengthColor,
      minimumSize: const Size(0, 48),
    ),
    onPressed: () => showAppSheet<void>(
      context,
      StrengthTrendSheet(
        name: name,
        contextKey: contextKey,
        equipment: equipment,
        convention: convention,
      ),
    ),
    icon: const Icon(Icons.show_chart, size: 18),
    label: Text(context.l10n.history, semanticsLabel: 'History of $name'),
  ),
);

List<StrengthTile> plannedStrengthTiles(StrengthPlanSummary s, MassUnit unit) {
  final d = s.duration;
  return [
    if (d != null)
      StrengthTile(
        tr.estimatedDuration,
        d.minSeconds == d.maxSeconds || (d.maxSeconds - d.minSeconds) < 120
            ? _minutes(d.maxSeconds)
            : '${(d.minSeconds / 60).round()}–${_minutes(d.maxSeconds)}',
        caption: d.explicit ? tr.sessionEstimate : tr.calculatedRange,
      ),
    StrengthTile(tr.exercises, '${s.exercises}'),
    StrengthTile(
      tr.workingSets,
      '${s.workingSets}',
      caption: s.warmupSets > 0 ? '+ ${s.warmupSets} warm-up' : null,
    ),
    if (s.volume.known > 0)
      StrengthTile(
        tr.estimatedExternalVolume,
        _volumeText(s.volume, unit),
        caption: _volumeCaption(s.volume),
      )
    else if (s.holdSeconds > 0)
      StrengthTile(tr.timedWork, formatStrengthSeconds(s.holdSeconds))
    else if (s.repsMax > 0)
      StrengthTile(
        tr.repetitions,
        s.repsMin == s.repsMax ? '${s.repsMax}' : '${s.repsMin}–${s.repsMax}',
      ),
  ];
}

/// Planned strength workout: summary, exercise cards, history hints and
/// editing. [fallback] is a verified bundled structure shown until the
/// athlete saves one for this workout.
class PlannedStrengthSection extends ConsumerWidget {
  const PlannedStrengthSection({
    super.key,
    required this.owner,
    required this.sessionDate,
    this.fallback,
    this.editable = true,
    this.ownershipNote,
    this.progressionBlockedReason,
    this.onLiveFinished,
  });
  final StrengthPlanOwner owner;
  final DateTime sessionDate;
  final StrengthWorkoutPlan? fallback;
  final bool editable;
  final String? ownershipNote;

  /// Why the programme does not progress loads now (taper, recovery), or
  /// null when it may.
  final String? progressionBlockedReason;

  /// Called after a gym-mode workout of this plan ends or closes, so the
  /// sheet can show a completed session.
  final VoidCallback? onLiveFinished;

  /// Opens gym mode, resuming an unfinished workout of this plan. A plan
  /// shown from a template is saved for this workout first, so the
  /// comparison names a revision.
  Future<void> _gym(
    BuildContext context,
    WidgetRef ref,
    StrengthWorkoutPlan plan,
    StoredStrengthPlan? stored,
  ) async {
    final repo = ref.read(strengthRepositoryProvider);
    var live = await repo.openLiveSession(owner);
    if (live == null) {
      final saved =
          stored ?? await repo.savePlan(owner, plan, expectedRevision: 0);
      live = await repo.startLiveSession(
        stored: saved,
        title: plan.title ?? tr.strengthTraining,
      );
    }
    final started = await repo.activityStart(live.activityId) ?? DateTime.now();
    if (!context.mounted) return;
    await showAppSheet<bool>(
      context,
      StrengthFocusScreen(
        initial: live,
        startedAt: started,
        sessionId: owner.kind == 'session' ? owner.key : null,
      ),
    );
    invalidateStrength(ref.invalidate);
    onLiveFinished?.call();
  }

  Future<void> _edit(
    BuildContext context,
    StrengthWorkoutPlan plan,
    int revision,
  ) => showAppSheet<bool>(
    context,
    StrengthPlanEditor(
      owner: owner,
      initial: plan,
      expectedRevision: revision,
      ownershipNote: ownershipNote,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(massUnitProvider);
    final async = ref.watch(strengthPlanProvider(owner));
    if (async.hasError) {
      final e = async.error;
      return SectionCard(
        title: context.l10n.exercises,
        child: Text(
          e is StrengthUnreadableException
              ? '${e.message} The workout details above are unaffected.'
              : context.l10n.theExercisesCouldNotBe,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      );
    }
    if (!async.hasValue) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final stored = async.value;
    final plan = stored?.plan ?? fallback;
    final revision = stored?.revision ?? 0;
    if (plan == null || plan.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(context.l10n.exercises2),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.noExercisesArePlannedFor,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (editable) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: _outlined(),
                    onPressed: () =>
                        _edit(context, const StrengthWorkoutPlan(), revision),
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.addExercises),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }
    final summary = summarisePlan(plan);
    final cards = <Widget>[];
    var number = 0;
    for (final b in plan.blocks) {
      if (b.grouped) cards.add(StrengthGroupHeader(block: b));
      for (final e in b.exercises) {
        number++;
        cards.add(
          _PlannedExerciseCard(
            key: ValueKey(e.id),
            number: number,
            exercise: e,
            block: b,
            plan: plan,
            revision: revision,
            owner: owner,
            editable: editable,
            blockedReason: progressionBlockedReason,
            unit: unit,
            before: DateUtils.dateOnly(sessionDate),
            onUse: !editable
                ? null
                : (entry) => runUiAction(context, () async {
                    final next = plan.applyHistory(e.id, entry);
                    await ref
                        .read(strengthRepositoryProvider)
                        .savePlan(owner, next, expectedRevision: revision);
                    ref.invalidate(strengthPlanProvider(owner));
                  }),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context.l10n.strengthSummary),
        StrengthSummaryGrid(tiles: plannedStrengthTiles(summary, unit)),
        if (stored == null && plan.template != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              context.l10n.fromTheBuiltInTemplate,
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ),
        if (plan.notes != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              plan.notes!,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        _heading(context.l10n.exercises2),
        ...cards,
        if (editable) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: strengthColor,
              foregroundColor: Colors.black,
              minimumSize: const Size(0, 52),
            ),
            onPressed: () =>
                runUiAction(context, () => _gym(context, ref, plan, stored)),
            icon: const Icon(Icons.fitness_center, size: 20),
            label: Text(
              ref.watch(strengthLiveSessionProvider(owner)).valueOrNull == null
                  ? 'Start workout'
                  : context.l10n.resumeWorkout,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (editable)
          OutlinedButton.icon(
            style: _outlined(),
            onPressed: () => _edit(context, plan, revision),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(context.l10n.editExercises),
          ),
        const SizedBox(height: 8),
        Builder(
          builder: (buttonContext) => TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () {
              final box = buttonContext.findRenderObject() as RenderBox?;
              SharePlus.instance.share(
                ShareParams(
                  subject: plan.title,
                  text:
                      '${plan.title ?? context.l10n.strengthWorkout}\n\n'
                      '${strengthPlanText(plan, unit)}',
                  sharePositionOrigin: box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                ),
              );
            },
            icon: const Icon(Icons.ios_share, size: 18),
            label: Text(context.l10n.shareExerciseList),
          ),
        ),
      ],
    );
  }
}

class _PlannedExerciseCard extends ConsumerWidget {
  const _PlannedExerciseCard({
    super.key,
    required this.number,
    required this.exercise,
    required this.block,
    required this.plan,
    required this.revision,
    required this.owner,
    required this.editable,
    required this.unit,
    required this.before,
    this.blockedReason,
    this.onUse,
  });
  final int number;
  final StrengthPlannedExercise exercise;
  final StrengthBlock block;
  final StrengthWorkoutPlan plan;
  final int revision;
  final StrengthPlanOwner owner;
  final bool editable;
  final String? blockedReason;
  final MassUnit unit;
  final DateTime before;
  final void Function(StrengthHistoryEntry)? onUse;

  /// The progression rule's verdict, or null while loading or when the
  /// workout cannot be changed. Calculated, never stored.
  StrengthProgressionEvaluation? _evaluate(WidgetRef ref) {
    final e = exercise;
    if (!editable || !e.convention.loadKind.countsVolume) return null;
    final recent = ref.watch(
      strengthRecentSessionsProvider((
        contextKey: e.contextKey,
        before: before,
      )),
    );
    final step = ref.watch(strengthIncrementProvider(e.contextKey));
    if (!recent.hasValue || !step.hasValue) return null;
    return evaluateStrengthProgression(
      exercise: e,
      block: block,
      recent: recent.value!,
      increment: step.value,
      blockedReason: blockedReason,
    );
  }

  Widget? _progression(BuildContext context, WidgetRef ref) {
    final e = exercise;
    final eval = _evaluate(ref);
    final decisions =
        ref.watch(strengthProposalDecisionsProvider(owner)).valueOrNull ??
        const {};
    final repo = ref.read(strengthRepositoryProvider);
    final working = e.sets.where((s) => s.kind != StrengthSetKind.warmup);
    // Provenance of an accepted proposal while its load is still the target.
    final accepted = decisions.values
        .where(
          (d) =>
              d.exerciseId == e.id &&
              d.decision == 'accepted' &&
              working.every(
                (s) => s.load != null && (s.load!.kg - d.toKg).abs() < 1e-6,
              ),
        )
        .firstOrNull;
    final note = accepted == null
        ? null
        : Text(
            context.l10n.loadRaisedFromUnitTo(
              formatStrengthLoad(accepted.fromKg, unit),
              formatStrengthLoad(accepted.toKg, unit),
              accepted.ruleVersion,
            ),
            style: const TextStyle(fontSize: 11, color: muted),
          );
    if (eval == null ||
        !eval.qualifies ||
        (eval.fingerprint != null && decisions.containsKey(eval.fingerprint))) {
      return note;
    }
    void supporting() => showStrengthSupportingSets(
      context,
      evaluation: eval,
      convention: e.convention,
      unit: unit,
    );
    if (eval.outcome == StrengthProgressionOutcome.blocked) {
      return Text(
        eval.reason,
        style: const TextStyle(fontSize: 11, color: muted),
      );
    }
    return StrengthProgressionCard(
      evaluation: eval,
      convention: e.convention,
      unit: unit,
      onViewSupporting: supporting,
      onSetIncrement: eval.outcome == StrengthProgressionOutcome.needsIncrement
          ? () async {
              final step = await showIncrementForm(context, unit: unit);
              if (step == null || !context.mounted) return;
              await runUiAction(context, () async {
                await repo.rememberIncrement(e.contextKey, step);
                ref.invalidate(strengthIncrementProvider(e.contextKey));
              });
            }
          : null,
      onApply: eval.outcome == StrengthProgressionOutcome.propose
          ? () => runUiAction(context, () async {
              await repo.acceptProposal(
                owner: owner,
                plan: applyProgression(plan, e.id, eval.proposedLoad!),
                expectedRevision: revision,
                exerciseId: e.id,
                fingerprint: eval.fingerprint!,
                ruleVersion: strengthProgressionRuleVersion,
                fromKg: eval.currentLoad!.kg,
                toKg: eval.proposedLoad!.kg,
              );
              ref.invalidate(strengthPlanProvider(owner));
              ref.invalidate(strengthProposalDecisionsProvider(owner));
            })
          : null,
      onKeep: eval.outcome == StrengthProgressionOutcome.propose
          ? () => runUiAction(context, () async {
              await repo.dismissProposal(
                owner: owner,
                exerciseId: e.id,
                fingerprint: eval.fingerprint!,
                ruleVersion: strengthProgressionRuleVersion,
                fromKg: eval.currentLoad!.kg,
                toKg: eval.proposedLoad!.kg,
              );
              ref.invalidate(strengthProposalDecisionsProvider(owner));
            })
          : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = exercise;
    final progression = _progression(context, ref);
    final hasLoad = e.sets.any(
      (s) => s.kind != StrengthSetKind.warmup && s.load != null,
    );
    // An explicit load wins; history is only a hint when none is set.
    final history = e.convention.loadKind.hasKg && !hasLoad
        ? ref
              .watch(
                strengthHistoryProvider((
                  contextKey: e.contextKey,
                  before: before,
                  exclude: null,
                )),
              )
              .valueOrNull
        : null;
    final pattern = loadPatternText(
      e.sets.where((s) => s.kind != StrengthSetKind.warmup).map((s) => s.load),
      unit,
    );
    return StrengthExerciseCard(
      number: number,
      name: e.name,
      detail: [
        if (e.equipment.isNotEmpty) e.equipment,
        e.convention.text,
      ].join(' · '),
      summary: [plannedExerciseLine(e), ?pattern].join(' · '),
      hint: history == null && progression == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (history != null)
                  StrengthHistoryHint(
                    entry: history,
                    convention: e.convention,
                    unit: unit,
                    onUse: onUse == null || !historyApplies(e, history)
                        ? null
                        : () => onUse!(history),
                  ),
                if (history != null && progression != null)
                  const SizedBox(height: 8),
                ?progression,
              ],
            ),
      rows: [
        if (StrengthExerciseDemo.has(e.variantId))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: StrengthExerciseDemo(
              variantId: e.variantId,
              name: e.name,
              height: 130,
            ),
          ),
        for (final (s, n) in numberedSets(e.sets))
          StrengthTargetRow(
            index: n,
            target: s,
            convention: e.convention,
            unit: unit,
          ),
        if (e.notes != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              e.notes!,
              style: const TextStyle(fontSize: 12, color: muted),
            ),
          ),
      ],
      footer: [
        _historyButton(
          context,
          name: e.name,
          contextKey: e.contextKey,
          equipment: e.equipment,
          convention: e.convention,
        ),
      ],
    );
  }
}

/// Completed strength activity: recorded sets when present, an honest empty
/// state otherwise, and the comparison with an explicitly linked plan.
class CompletedStrengthSection extends ConsumerWidget {
  const CompletedStrengthSection({super.key, required this.activity});
  final ActivityRecord activity;

  Future<void> _open(BuildContext context, StrengthActivityLog log) =>
      showAppSheet<bool>(context, StrengthLogEditor(initial: log));

  Future<void> _compare(
    BuildContext context,
    WidgetRef ref,
    StrengthActivityLog log,
  ) async {
    final templates = await ref.read(strengthTemplatesProvider.future);
    if (!context.mounted) return;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noSavedStrengthTemplatesYet)),
      );
      return;
    }
    final picked = await showDialog<StoredStrengthPlan>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(context.l10n.compareWith),
        children: [
          for (final t in templates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, t),
              child: Text(t.plan.title ?? context.l10n.untitledTemplate),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    final baseline = StrengthPlanBaseline(
      ownerKind: picked.owner.kind,
      ownerKey: picked.owner.key,
      revisionId: picked.revisionId,
      plan: picked.plan,
      retrospective: true,
    );
    // Linking never rewrites recorded sets; an empty log gets the layout.
    await _open(
      context,
      log.copyWith(
        baseline: () => baseline,
        exercises: log.isEmpty ? logLayoutFromPlan(picked.plan) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(massUnitProvider);
    final async = ref.watch(strengthLogProvider(activity.activityId));
    final linked = ref
        .watch(strengthLinkedSessionProvider(activity.activityId))
        .valueOrNull;
    if (async.hasError) {
      final e = async.error;
      return SectionCard(
        title: context.l10n.exercises,
        child: Text(
          e is StrengthUnreadableException
              ? '${e.message} The activity itself is unaffected.'
              : context.l10n.theRecordedExercisesCouldNot,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      );
    }
    if (!async.hasValue) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final log =
        async.value ?? StrengthActivityLog(activityId: activity.activityId);
    if (log.isEmpty) {
      return StrengthMissingDataCard(
        onAdd: () => _open(context, log),
        onLogFromPlan: linked == null
            ? null
            : () => runUiAction(context, () async {
                final baseline = await ref
                    .read(strengthRepositoryProvider)
                    .sessionBaseline(linked);
                if (!context.mounted) return;
                if (baseline == null) {
                  throw StateError(context.l10n.thePlannedWorkoutHasNo);
                }
                await _open(
                  context,
                  log.copyWith(
                    baseline: () => baseline,
                    exercises: logLayoutFromPlan(baseline.plan),
                  ),
                );
              }),
        onCompare: () => _compare(context, ref, log),
      );
    }
    final s = summariseLog(log);
    final comparison = compareWithBaseline(log);
    final targets = {
      for (final e
          in log.baseline?.plan.exercises ?? <StrengthPlannedExercise>[])
        for (final t in e.sets) t.id: t,
    };
    final missing = comparison.where((c) => c.missing).toList();
    final other = [
      if (s.partialSets > 0) '${s.partialSets} partial',
      if (s.failedSets > 0) '${s.failedSets} failed',
      if (s.skippedSets > 0) '${s.skippedSets} skipped',
      if (s.unrecordedSets > 0) '${s.unrecordedSets} not recorded',
    ];
    final work = [
      if (s.reps > 0 || s.repsUnknownSets > 0)
        '${s.reps} reps${s.repsUnknownSets > 0 ? ' known (${s.repsUnknownSets} sets unknown)' : ''}',
      if (s.holdSeconds > 0)
        '${formatStrengthSeconds(s.holdSeconds)} timed work',
      if (s.restSeconds != null)
        'Average rest ${formatStrengthSeconds(s.restSeconds!.round())} '
            '(${s.restIntervals} recorded)',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          log.status == StrengthLogStatus.draft
              ? context.l10n.strengthDraft
              : log.incompleteAcknowledged
              ? context.l10n.strengthFinishedWithGaps
              : context.l10n.strength2,
        ),
        StrengthSummaryGrid(
          tiles: [
            StrengthTile(
              context.l10n.exercisesPerformed,
              '${s.exercises ?? '—'}',
            ),
            StrengthTile(
              context.l10n.completedSets,
              '${s.completedSets}',
              caption: other.isEmpty ? null : other.join(' · '),
            ),
            if (s.volume.known > 0)
              StrengthTile(
                context.l10n.knownExternalVolume,
                _volumeText(s.volume, unit),
                caption: _volumeCaption(s.volume),
              ),
          ],
        ),
        if (work.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              work.join(' · '),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        if (log.baseline != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              log.baseline!.retrospective
                  ? 'Compared with “${log.baseline!.plan.title ?? 'a saved workout'}”, chosen after the workout.'
                  : context.l10n.comparedWithThePlanAs,
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ),
        _heading(context.l10n.exercises2),
        for (var i = 0; i < log.exercises.length; i++)
          () {
            final e = log.exercises[i];
            final done = e.sets
                .where((x) => x.status == StrengthSetStatus.completed)
                .length;
            final pattern = loadPatternText(
              e.sets
                  .where((x) => x.status == StrengthSetStatus.completed)
                  .map((x) => x.load),
              unit,
            );
            final oneRm = bestOneRm(e.sets, e.convention);
            return StrengthExerciseCard(
              key: ValueKey(e.id),
              number: i + 1,
              name: e.name,
              detail: [
                if (e.equipment.isNotEmpty) e.equipment,
                e.convention.text,
                if (log.baseline != null && e.plannedExerciseId == null)
                  'Added',
              ].join(' · '),
              summary: [
                '$done completed ${done == 1 ? 'set' : 'sets'}',
                ?pattern,
              ].join(' · '),
              rows: [
                for (final (r, n) in numberedSets(e.sets))
                  StrengthResultRow(
                    index: n,
                    result: r,
                    target: targets[r.plannedSetId],
                    convention: e.convention,
                    unit: unit,
                  ),
                if (e.notes != null)
                  Text(
                    e.notes!,
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                if (oneRm != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      context.l10n.estimated1rmUnit(oneRmText(oneRm, unit)),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
              footer: [
                _historyButton(
                  context,
                  name: e.name,
                  contextKey: e.contextKey,
                  equipment: e.equipment,
                  convention: e.convention,
                ),
              ],
            );
          }(),
        if (missing.isNotEmpty)
          SectionCard(
            title: context.l10n.plannedNotRecorded,
            child: Text(
              missing.map((m) => m.planned!.name).join(', '),
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        if (log.notes != null)
          SectionCard(title: context.l10n.notes, child: Text(log.notes!)),
        OutlinedButton.icon(
          style: _outlined(),
          onPressed: () => _open(context, log),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(context.l10n.editPerformance),
        ),
        if (log.baseline == null)
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => _compare(context, ref, log),
            child: Text(context.l10n.compareWithASavedWorkout),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Asks, then rebuilds the plan's future so strength sessions follow the
/// race goals on every strength day. Returns whether it ran.
Future<bool> confirmStrengthUpdate(BuildContext context, WidgetRef ref) async {
  if (!await confirmAction(
    context,
    context.l10n.updateStrengthSessions2,
    context.l10n.upcomingSessionsArePlannedAgain,
  )) {
    return false;
  }
  if (!context.mounted) return false;
  var done = false;
  await runUiAction(context, () async {
    await ref.read(updateStrengthProgrammeProvider)();
    done = true;
  });
  return done;
}

/// Shown on a planned session that still uses an earlier strength template.
class StrengthProgrammeUpdateCard extends ConsumerWidget {
  const StrengthProgrammeUpdateCard({super.key, this.onUpdated});
  final VoidCallback? onUpdated;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SectionCard(
    color: strengthColor.withValues(alpha: .08),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.thisSessionUsesAnEarlier,
          style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: _outlined(),
          onPressed: () async {
            if (await confirmStrengthUpdate(context, ref)) onUpdated?.call();
          },
          icon: const Icon(Icons.fitness_center, size: 18),
          label: Text(context.l10n.updateStrengthSessions),
        ),
      ],
    ),
  );
}
