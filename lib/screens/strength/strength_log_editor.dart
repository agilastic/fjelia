import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/strength_workout.dart';
import '../../providers/strength_provider.dart';
import '../../services/strength/strength_repository.dart';
import '../../theme/activity_colors.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/strength_widgets.dart';
import 'strength_forms.dart';

enum _SaveState { idle, saving, saved, failed }

/// Records what was actually done in one activity. Every confirmed change is
/// saved at once; planned values appear as hints and never count as done
/// without an explicit action.
class StrengthLogEditor extends ConsumerStatefulWidget {
  const StrengthLogEditor({super.key, required this.initial});
  final StrengthActivityLog initial;
  @override
  ConsumerState<StrengthLogEditor> createState() => _LogEditorState();
}

class _LogEditorState extends ConsumerState<StrengthLogEditor> {
  late StrengthActivityLog log = widget.initial;
  _SaveState state = _SaveState.idle;
  String? error;

  /// The latest edit is not stored yet (a failed save).
  bool pending = false;
  StrengthRepository get repo => ref.read(strengthRepositoryProvider);
  MassUnit get unit => ref.read(massUnitProvider);

  Map<String, StrengthSetTarget> get targets => {
    for (final e in log.baseline?.plan.exercises ?? <StrengthPlannedExercise>[])
      for (final s in e.sets) s.id: s,
  };

  Future<bool> persist(StrengthActivityLog next) async {
    setState(() {
      log = next;
      pending = true;
      state = _SaveState.saving;
      error = null;
    });
    try {
      final saved = await repo.saveLog(next);
      ref.invalidate(strengthLogProvider(next.activityId));
      ref.invalidate(strengthHistoryProvider);
      if (!mounted) return true;
      setState(() {
        log = saved;
        pending = false;
        state = _SaveState.saved;
      });
      return true;
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          state = _SaveState.failed;
          error = '$e';
        });
      }
      return false;
    }
  }

  StrengthActivityLog withExercise(
    String id,
    StrengthPerformedExercise Function(StrengthPerformedExercise) f,
  ) => log.copyWith(
    exercises: [for (final e in log.exercises) e.id == id ? f(e) : e],
  );

  StrengthActivityLog withSet(String exerciseId, StrengthSetResult set) =>
      withExercise(
        exerciseId,
        (e) => e.copyWith(
          sets: [for (final s in e.sets) s.id == set.id ? set : s],
        ),
      );

  Future<void> editSet(
    StrengthPerformedExercise e,
    StrengthSetResult s,
    int n,
  ) async {
    final variant = builtInStrengthVariant(e.variantId);
    final next = await showSetResultForm(
      context,
      result: s,
      target: targets[s.plannedSetId],
      convention: e.convention,
      unit: unit,
      timed: variant?.timed ?? false,
      title: '${e.name} · Set ${n == 0 ? 'W' : n}',
    );
    if (next != null) await persist(withSet(e.id, next));
  }

  Future<void> doneAsPlanned(
    StrengthPerformedExercise e,
    StrengthSetResult s,
    StrengthSetTarget t,
  ) async {
    HapticFeedback.lightImpact();
    await persist(withSet(e.id, completedAsPlanned(s, t, e.convention)));
  }

  Future<void> addExercise() async {
    final custom = await ref.read(strengthCustomVariantsProvider.future);
    if (!mounted) return;
    final picked = await showExercisePicker(context, custom: custom);
    if (picked == null || !mounted) return;
    var v = picked.variant;
    if (v == null) {
      final d = await showExerciseForm(
        context,
        name: picked.customName!,
        equipment: '',
        convention: const StrengthConvention(),
        unit: unit,
      );
      if (d == null || !mounted) return;
      v = await repo.addCustomVariant(
        name: d.name,
        equipment: d.equipment,
        convention: d.convention,
      );
      ref.invalidate(strengthCustomVariantsProvider);
    }
    await persist(
      log.copyWith(
        exercises: [
          ...log.exercises,
          StrengthPerformedExercise(
            id: newStrengthId('pe'),
            variantId: v.id,
            name: v.name,
            equipment: v.equipment,
            convention: v.convention,
            sets: [StrengthSetResult(id: newStrengthId('ps'))],
          ),
        ],
      ),
    );
  }

  Future<void> editExercise(StrengthPerformedExercise e) async {
    final d = await showExerciseForm(
      context,
      name: e.name,
      equipment: e.equipment,
      convention: e.convention,
      notes: e.notes,
      unit: unit,
    );
    if (d == null) return;
    await persist(
      withExercise(
        e.id,
        (e) => e.copyWith(
          name: d.name,
          equipment: d.equipment,
          convention: d.convention,
          notes: () => d.notes,
          sets: d.convention.loadKind.hasKg
              ? e.sets
              : [for (final s in e.sets) s.copyWith(load: () => null)],
        ),
      ),
    );
  }

  Future<void> move(StrengthPerformedExercise e, int delta) async {
    final list = [...log.exercises];
    final i = list.indexOf(e), j = i + delta;
    if (j < 0 || j >= list.length) return;
    HapticFeedback.selectionClick();
    list.insert(j, list.removeAt(i));
    await persist(log.copyWith(exercises: list));
  }

  Future<void> removeWithUndo(StrengthActivityLog next, String what) async {
    final before = log;
    if (!await persist(next) || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.whatRemoved(what)),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () => persist(before.copyWith(revision: log.revision)),
          ),
        ),
      );
  }

  Future<void> finish() async {
    var next = log.copyWith(status: StrengthLogStatus.finished);
    final open = log.unrecordedSets;
    if (open > 0) {
      final ok = await confirmAction(
        context,
        context.l10n.finishWithIncompleteData,
        '$open ${open == 1 ? 'set is' : 'sets are'} not recorded. '
        'They stay unrecorded; finishing does not mark them as done.',
      );
      if (!ok) return;
      next = next.copyWith(incompleteAcknowledged: true);
    }
    if (await persist(next) && mounted) Navigator.pop(context, true);
  }

  Widget statusLine() {
    final (text, color) = switch (state) {
      _SaveState.idle => (
        log.revision == 0 ? context.l10n.notSavedYet : context.l10n.saved,
        muted,
      ),
      _SaveState.saving => (context.l10n.saving, muted),
      _SaveState.saved => (context.l10n.saved, mint),
      _SaveState.failed => (context.l10n.couldNotSave, Colors.redAccent),
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(
            state == _SaveState.failed
                ? Icons.error_outline
                : Icons.cloud_done_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: color)),
          ),
          if (state == _SaveState.failed)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => persist(log),
              child: Text(context.l10n.retry),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(massUnitProvider);
    final targets = this.targets;
    final baseline = log.baseline;
    return PopScope(
      canPop: !pending,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await confirmAction(
              context,
              context.l10n.leaveWithoutSaving,
              context.l10n.theLastChangeCouldNot,
            ) &&
            context.mounted) {
          pending = false;
          Navigator.pop(context, false);
        }
      },
      child: SheetPage(
        title: context.l10n.performance,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            statusLine(),
            if (error != null)
              Text(
                error!,
                style: const TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
            if (baseline != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  baseline.retrospective
                      ? context.l10n.comparedWithAPlanChosen
                      : context.l10n.plannedValuesAreHintsNot,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ),
            const SizedBox(height: 12),
            for (var i = 0; i < log.exercises.length; i++)
              _exerciseCard(log.exercises[i], i, targets, unit),
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
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: strengthColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(0, 48),
              ),
              onPressed: state == _SaveState.saving || log.isEmpty
                  ? null
                  : finish,
              child: Text(context.l10n.finishLog),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: pending ? null : () => Navigator.pop(context, true),
              child: Text(context.l10n.keepAsDraft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseCard(
    StrengthPerformedExercise e,
    int i,
    Map<String, StrengthSetTarget> targets,
    MassUnit unit,
  ) => StrengthExerciseCard(
    key: ValueKey(e.id),
    number: i + 1,
    name: e.name,
    detail: [
      if (e.equipment.isNotEmpty) e.equipment,
      e.convention.text,
    ].join(' · '),
    initiallyExpanded: true,
    menu: PopupMenuButton<String>(
      tooltip: context.l10n.actionsForName(e.name),
      icon: const Icon(Icons.more_horiz, color: muted),
      onSelected: (v) {
        switch (v) {
          case 'edit':
            editExercise(e);
          case 'up':
            move(e, -1);
          case 'down':
            move(e, 1);
          case 'remove':
            removeWithUndo(
              log.copyWith(
                exercises: [...log.exercises.where((x) => x.id != e.id)],
              ),
              e.name,
            );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Text(context.l10n.editExercise)),
        if (i > 0) PopupMenuItem(value: 'up', child: Text(context.l10n.moveUp)),
        if (i < log.exercises.length - 1)
          PopupMenuItem(value: 'down', child: Text(context.l10n.moveDown)),
        PopupMenuItem(value: 'remove', child: Text(context.l10n.remove)),
      ],
    ),
    rows: [
      for (final (s, n) in numberedSets(e.sets))
        StrengthResultRow(
          index: n,
          result: s,
          target: targets[s.plannedSetId],
          convention: e.convention,
          unit: unit,
          onTap: () => editSet(e, s, n),
          trailing: _quickDone(e, s, n, targets[s.plannedSetId]),
        ),
    ],
    footer: [
      Wrap(
        spacing: 4,
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: strengthColor,
              minimumSize: const Size(0, 48),
            ),
            onPressed: () => persist(
              withExercise(
                e.id,
                (e) => e.copyWith(
                  sets: [
                    ...e.sets,
                    StrengthSetResult(
                      id: newStrengthId('ps'),
                      kind: e.sets.lastOrNull?.kind ?? StrengthSetKind.working,
                    ),
                  ],
                ),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(context.l10n.addSet),
          ),
          if (e.sets.isNotEmpty)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () => removeWithUndo(
                withExercise(
                  e.id,
                  (e) => e.copyWith(sets: [...e.sets]..removeLast()),
                ),
                context.l10n.lastSet,
              ),
              child: Text(context.l10n.removeLastSet),
            ),
        ],
      ),
    ],
  );

  /// One tap for a set whose plan is precise enough; nothing otherwise.
  Widget? _quickDone(
    StrengthPerformedExercise e,
    StrengthSetResult s,
    int n,
    StrengthSetTarget? t,
  ) {
    if (t == null || s.status != StrengthSetStatus.unrecorded) return null;
    final blocker = completeAsPlannedBlocker(t, e.convention);
    return IconButton(
      tooltip: blocker ?? context.l10n.completedAsPlanned,
      onPressed: blocker == null
          ? () => doneAsPlanned(e, s, t)
          : () => editSet(e, s, n),
      icon: Icon(
        blocker == null ? Icons.check : Icons.edit_outlined,
        color: blocker == null ? mint : muted,
      ),
    );
  }
}
