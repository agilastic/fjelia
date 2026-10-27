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
          content: Text('$what removed'),
          action: SnackBarAction(label: 'Undo', onPressed: () => edit(before)),
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
      title: 'Save as template',
      confirm: 'Save',
      fields: [
        strengthDialogField(
          'Template name',
          initial: plan.title ?? '',
          number: false,
        ),
      ],
      validate: (v) => v.single.trim().isEmpty ? 'Name the template.' : null,
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
          SnackBar(
            content: Text(
              'Saved “$title” as a template. This workout is unchanged until you save it.',
            ),
          ),
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
      title: '${e.name} · Set $n',
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
      title: '${e.name} · All working sets',
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
      title: '${b.kind.label} rest',
      confirm: 'Done',
      fields: [
        strengthDialogField(
          'Between exercises',
          initial: b.restBetweenExercisesSeconds?.toString() ?? '',
          hint: 'Seconds or m:ss',
          number: false,
        ),
        strengthDialogField(
          'Between rounds',
          initial: b.restBetweenRoundsSeconds?.toString() ?? '',
          hint: 'Seconds or m:ss',
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
        tooltip: 'Actions for ${e.name}',
        icon: const Icon(Icons.more_horiz, color: muted),
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
          const PopupMenuItem(value: 'edit', child: Text('Edit exercise')),
          const PopupMenuItem(value: 'all', child: Text('Apply to all sets')),
          const PopupMenuItem(value: 'dup', child: Text('Duplicate')),
          if (plan.canMove(e.id, -1))
            const PopupMenuItem(value: 'up', child: Text('Move up')),
          if (plan.canMove(e.id, 1))
            const PopupMenuItem(value: 'down', child: Text('Move down')),
          if (!last && (!b.grouped || b.exercises.last.id == e.id)) ...[
            const PopupMenuItem(
              value: 'superset',
              child: Text('Superset with next'),
            ),
            const PopupMenuItem(
              value: 'circuit',
              child: Text('Circuit with next'),
            ),
          ],
          const PopupMenuItem(value: 'remove', child: Text('Remove')),
        ],
      );

  Widget setMenu(StrengthPlannedExercise e, StrengthSetTarget s, int n) =>
      PopupMenuButton<String>(
        tooltip: 'Actions for set $n',
        icon: const Icon(Icons.more_vert, size: 18, color: muted),
        onSelected: (v) {
          switch (v) {
            case 'edit':
              editSet(e, s, n);
            case 'dup':
              edit(plan.duplicateSet(e.id, s.id));
            case 'remove':
              remove(plan.removeSet(e.id, s.id), 'Set $n');
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit set')),
          PopupMenuItem(value: 'dup', child: Text('Duplicate set')),
          PopupMenuItem(value: 'remove', child: Text('Remove set')),
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
              tooltip: '${b.kind.label} actions',
              icon: const Icon(Icons.more_horiz, color: muted),
              onSelected: (v) =>
                  v == 'rest' ? editGroupRests(b) : edit(plan.ungroup(b.id)),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rest', child: Text('Edit rests')),
                PopupMenuItem(value: 'ungroup', child: Text('Ungroup')),
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
                  label: const Text('Add set'),
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
              'Discard changes?',
              'Your edits to this workout are not saved.',
            ) &&
            context.mounted) {
          dirty = false;
          Navigator.pop(context, false);
        }
      },
      child: SheetPage(
        title: 'Edit exercises',
        actions: [
          TextButton(
            onPressed: saving || !dirty ? null : save,
            child: Text(saving ? 'Saving…' : 'Save'),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Text(
              widget.ownershipNote ?? 'Changes apply to this workout only. Completed workouts and other sessions stay as they are.',
              style: const TextStyle(fontSize: 12, color: muted),
            ),
            if (dirty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Unsaved changes',
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
              label: const Text('Add exercise'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    'Could not save: $error',
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
              child: Text(saving ? 'Saving…' : 'Save for this workout'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: saving || plan.isEmpty ? null : saveAsTemplate,
              child: const Text('Save as template'),
            ),
          ],
        ),
      ),
    );
  }
}
