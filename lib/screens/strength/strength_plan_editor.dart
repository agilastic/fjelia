import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/strength_workout.dart';
import '../../providers/strength_provider.dart';
import '../../services/strength/strength_plan_edits.dart';
import '../../services/strength/strength_repository.dart';
import '../../services/strength/strength_statistics.dart';
import '../../theme/activity_colors.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/strength_widgets.dart';
import 'strength_forms.dart';

/// Edits a planned strength workout. Saves a new revision for this workout
/// only; reusing it as a template is a separate, named action.
class StrengthPlanEditor extends ConsumerStatefulWidget {
  const StrengthPlanEditor({
    super.key,
    required this.owner,
    required this.initial,
    required this.expectedRevision,
    this.ownershipNote,
  });
  final StrengthPlanOwner owner;
  final StrengthWorkoutPlan initial;

  /// Revision the editor started from; 0 when nothing is saved yet.
  final int expectedRevision;
  final String? ownershipNote;
  @override
  ConsumerState<StrengthPlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends ConsumerState<StrengthPlanEditor> {
  late StrengthWorkoutPlan plan = widget.initial;
  late int revision = widget.expectedRevision;
  bool dirty = false, saving = false;
  String? error;

  StrengthRepository get repo => ref.read(strengthRepositoryProvider);
  MassUnit get unit => ref.read(massUnitProvider);

  void edit(StrengthWorkoutPlan next) => setState(() {
    plan = next;
    dirty = true;
    error = null;
  });

  /// Applies a removal with an undo on the snackbar.
  void remove(StrengthWorkoutPlan next, String what) {
    final before = plan;
    edit(next);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.whatRemoved(what)),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () => edit(before),
          ),
        ),
      );
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await repo.savePlan(widget.owner, plan, expectedRevision: revision);
      ref.invalidate(strengthPlanProvider(widget.owner));
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      // The draft stays on screen for a retry or a deliberate reload.
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> saveAsTemplate() async {
    final values = await showStrengthFieldsDialog(
      context,
      title: context.l10n.saveAsTemplate,
      confirm: context.l10n.save,
      fields: [
        strengthDialogField(
          context.l10n.templateName,
          initial: plan.title ?? '',
          number: false,
        ),
      ],
      validate: (v) =>
          v.single.trim().isEmpty ? context.l10n.nameTheTemplate : null,
    );
    final title = values?.single.trim();
    if (title == null || title.isEmpty || !mounted) return;
    await runUiAction(context, () async {
      await repo.savePlan(
        StrengthPlanOwner.template(newStrengthId('tpl')),
        plan.copyWith(title: () => title, template: () => null),
        expectedRevision: 0,
      );
      ref.invalidate(strengthTemplatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.savedTitleAsATemplate(title))),
        );
      }
    });
  }

  Future<void> addExercise() async {
    final custom = await ref.read(strengthCustomVariantsProvider.future);
    if (!mounted) return;
    final picked = await showExercisePicker(context, custom: custom);
    if (picked == null || !mounted) return;
    var variant = picked.variant;
    if (variant == null) {
      final details = await showExerciseForm(
        context,
        name: picked.customName!,
        equipment: '',
        convention: const StrengthConvention(),
        unit: unit,
      );
      if (details == null || !mounted) return;
      variant = await repo.addCustomVariant(
        name: details.name,
        equipment: details.equipment,
        convention: details.convention,
      );
      ref.invalidate(strengthCustomVariantsProvider);
    }
    edit(plan.addExercise(variant));
  }

  Future<void> editExercise(StrengthPlannedExercise e) async {
    final step = await repo.increment(e.contextKey);
    if (!mounted) return;
    final d = await showExerciseForm(
      context,
      name: e.name,
      equipment: e.equipment,
      convention: e.convention,
      notes: e.notes,
      unit: unit,
      increment: step,
    );
    if (d == null) return;
    final next = e.copyWith(
      name: d.name,
      equipment: d.equipment,
      convention: d.convention,
      notes: () => d.notes,
      // Loads no longer apply to a convention without kilograms.
      sets: d.convention.loadKind.hasKg
          ? e.sets
          : [for (final s in e.sets) s.copyWith(load: () => null)],
    );
    if (d.rememberIncrement) {
      await repo.rememberIncrement(next.contextKey, d.increment!);
      ref.invalidate(strengthIncrementProvider(next.contextKey));
    }
    edit(plan.updateExercise(e.id, (_) => next));
  }

  Future<void> editSet(
    StrengthPlannedExercise e,
    StrengthSetTarget s,
    int n,
  ) async {
    final next = await showSetTargetForm(
      context,
      target: s,
      convention: e.convention,
      unit: unit,
      title: context.l10n.nameSetN(e.name, n),
    );
    if (next != null) edit(plan.updateSet(e.id, next));
  }

  Future<void> applyToAll(StrengthPlannedExercise e) async {
    final base = e.sets.firstWhere(
      (s) => s.kind != StrengthSetKind.warmup,
      orElse: () => e.sets.first,
    );
    final next = await showSetTargetForm(
      context,
      target: base.copyWith(id: 'all'),
      convention: e.convention,
      unit: unit,
      title: context.l10n.nameAllWorkingSets(e.name),
    );
    if (next != null) edit(plan.applyToWorkingSets(e.id, next));
  }

  Future<void> editGroupRests(StrengthBlock b) async {
    String? check(List<String> v) {
      try {
        for (final t in v) {
          parseStrengthSeconds(t);
        }
        return null;
      } on FormatException catch (e) {
        return e.message;
      }
    }

    final values = await showStrengthFieldsDialog(
      context,
      title: context.l10n.labelRest(b.kind.label),
      confirm: context.l10n.done,
      fields: [
        strengthDialogField(
          context.l10n.betweenExercises,
          initial: b.restBetweenExercisesSeconds?.toString() ?? '',
          hint: context.l10n.secondsOrMSs,
          number: false,
        ),
        strengthDialogField(
          context.l10n.betweenRounds,
          initial: b.restBetweenRoundsSeconds?.toString() ?? '',
          hint: context.l10n.secondsOrMSs,
          number: false,
        ),
      ],
      validate: check,
    );
    if (values == null) return;
    final e = parseStrengthSeconds(values[0]);
    final r = parseStrengthSeconds(values[1]);
    edit(
      plan.updateBlock(
        b.id,
        (b) => b.copyWith(
          restBetweenExercisesSeconds: () => e,
          restBetweenRoundsSeconds: () => r,
        ),
      ),
    );
  }

  Widget exerciseMenu(StrengthPlannedExercise e, StrengthBlock b, bool last) =>
      PopupMenuButton<String>(
        tooltip: context.l10n.actionsForName(e.name),
        icon: Icon(Icons.more_horiz, color: muted),
        onSelected: (v) {
          switch (v) {
            case 'edit':
              editExercise(e);
            case 'all':
              applyToAll(e);
            case 'dup':
              edit(plan.duplicateExercise(e.id));
            case 'up':
              HapticFeedback.selectionClick();
              edit(plan.moveExercise(e.id, -1));
            case 'down':
              HapticFeedback.selectionClick();
              edit(plan.moveExercise(e.id, 1));
            case 'superset':
              edit(plan.groupWithNext(e.id, StrengthBlockKind.superset));
            case 'circuit':
              edit(plan.groupWithNext(e.id, StrengthBlockKind.circuit));
            case 'remove':
              remove(plan.removeExercise(e.id), e.name);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Text(context.l10n.editExercise)),
          PopupMenuItem(value: 'all', child: Text(context.l10n.applyToAllSets)),
          PopupMenuItem(value: 'dup', child: Text(context.l10n.duplicate)),
          if (plan.canMove(e.id, -1))
            PopupMenuItem(value: 'up', child: Text(context.l10n.moveUp)),
          if (plan.canMove(e.id, 1))
            PopupMenuItem(value: 'down', child: Text(context.l10n.moveDown)),
          if (!last && (!b.grouped || b.exercises.last.id == e.id)) ...[
            PopupMenuItem(
              value: 'superset',
              child: Text(context.l10n.supersetWithNext),
            ),
            PopupMenuItem(
              value: 'circuit',
              child: Text(context.l10n.circuitWithNext),
            ),
          ],
          PopupMenuItem(value: 'remove', child: Text(context.l10n.remove)),
        ],
      );

  Widget setMenu(StrengthPlannedExercise e, StrengthSetTarget s, int n) =>
      PopupMenuButton<String>(
        tooltip: context.l10n.actionsForSetN(n),
        icon: Icon(Icons.more_vert, size: 18, color: muted),
        onSelected: (v) {
          switch (v) {
            case 'edit':
              editSet(e, s, n);
            case 'dup':
              edit(plan.duplicateSet(e.id, s.id));
            case 'remove':
              remove(plan.removeSet(e.id, s.id), context.l10n.setN(n));
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Text(context.l10n.editSet)),
          PopupMenuItem(value: 'dup', child: Text(context.l10n.duplicateSet)),
          PopupMenuItem(value: 'remove', child: Text(context.l10n.removeSet)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(massUnitProvider);
    final summary = summarisePlan(plan);
    var number = 0;
    final cards = <Widget>[];
    for (var bi = 0; bi < plan.blocks.length; bi++) {
      final b = plan.blocks[bi];
      final last = bi == plan.blocks.length - 1;
      if (b.grouped) {
        cards.add(
          StrengthGroupHeader(
            block: b,
            menu: PopupMenuButton<String>(
              tooltip: context.l10n.labelActions(b.kind.label),
              icon: Icon(Icons.more_horiz, color: muted),
              onSelected: (v) =>
                  v == 'rest' ? editGroupRests(b) : edit(plan.ungroup(b.id)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'rest',
                  child: Text(context.l10n.editRests),
                ),
                PopupMenuItem(
                  value: 'ungroup',
                  child: Text(context.l10n.ungroup),
                ),
              ],
            ),
          ),
        );
      }
      for (final e in b.exercises) {
        number++;
        cards.add(
          StrengthExerciseCard(
            key: ValueKey(e.id),
            number: number,
            name: e.name,
            detail: [
              if (e.equipment.isNotEmpty) e.equipment,
              e.convention.text,
            ].join(' · '),
            summary: plannedExerciseLine(e),
            initiallyExpanded: true,
            menu: exerciseMenu(e, b, last),
            rows: [
              for (final (s, n) in numberedSets(e.sets))
                StrengthTargetRow(
                  index: n,
                  target: s,
                  convention: e.convention,
                  unit: unit,
                  onTap: () => editSet(e, s, n),
                  trailing: setMenu(e, s, n),
                ),
            ],
            footer: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: strengthColor,
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: () => edit(plan.addSet(e.id)),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.l10n.addSet),
                ),
              ),
            ],
          ),
        );
      }
    }
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await confirmAction(
              context,
              context.l10n.discardChanges,
              context.l10n.yourEditsToThisWorkout,
            ) &&
            context.mounted) {
          dirty = false;
          Navigator.pop(context, false);
        }
      },
      child: SheetPage(
        title: context.l10n.editExercises,
        actions: [
          TextButton(
            onPressed: saving || !dirty ? null : save,
            child: Text(saving ? context.l10n.saving : context.l10n.save),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Text(
              widget.ownershipNote ?? context.l10n.changesApplyToThisWorkout,
              style: const TextStyle(fontSize: 12, color: muted),
            ),
            if (dirty)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  context.l10n.unsavedChanges,
                  style: TextStyle(fontSize: 12, color: Color(0xFFFFC857)),
                ),
              ),
            const SizedBox(height: 12),
            if (!plan.isEmpty) ...[
              Text(
                '${summary.exercises} exercises · ${summary.workingSets} working sets'
                '${summary.warmupSets > 0 ? ' · ${summary.warmupSets} warm-up' : ''}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 12),
            ],
            ...cards,
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: strengthColor,
                side: BorderSide(color: strengthColor.withValues(alpha: .5)),
                minimumSize: const Size(0, 48),
              ),
              onPressed: addExercise,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addExercise),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    context.l10n.couldNotSaveError(error ?? ""),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: strengthColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(0, 48),
              ),
              onPressed: saving || plan.isEmpty ? null : save,
              child: Text(
                saving ? context.l10n.saving : context.l10n.saveForThisWorkout,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: saving || plan.isEmpty ? null : saveAsTemplate,
              child: Text(context.l10n.saveAsTemplate),
            ),
          ],
        ),
      ),
    );
  }
}
