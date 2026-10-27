import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/strength_workout.dart';
import '../../providers/strength_provider.dart';
import '../../services/strength/strength_focus.dart';
import '../../services/strength/strength_repository.dart';
import '../../theme/activity_colors.dart';
import '../../utils/decimal.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/strength_demo.dart';
import '../../widgets/strength_widgets.dart';
import 'strength_forms.dart';

const _tabular = [FontFeature.tabularFigures()];

String _clock(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
  return '${h > 0 ? '$h:' : ''}$mm:${s.toString().padLeft(2, '0')}';
}

/// Gym mode: one set at a time, large controls, every confirmed set saved
/// at once. Rest is timed from a set's end to the next set's start and
/// stored as measured; the planned rest is only a target on screen.
class StrengthFocusScreen extends ConsumerStatefulWidget {
  const StrengthFocusScreen({
    super.key,
    required this.initial,
    required this.startedAt,
    this.sessionId,
  });
  final StrengthActivityLog initial;
  final DateTime startedAt;

  /// The planned session this workout completes when finished, if any.
  final String? sessionId;
  @override
  ConsumerState<StrengthFocusScreen> createState() => _FocusState();
}

class _FocusState extends ConsumerState<StrengthFocusScreen> {
  late StrengthActivityLog log = widget.initial;
  late List<StrengthFocusStep> order = strengthFocusOrder(log);
  late int index = strengthFocusStart(order);
  int? reps, seconds;
  double? kg;

  /// Running rest: when the last set ended, and which set it belongs to.
  DateTime? restFrom;
  String? restFor;
  bool restBuzzed = false;
  bool saving = false;
  String? error;
  Timer? ticker;

  StrengthRepository get repo => ref.read(strengthRepositoryProvider);
  StrengthFocusStep get step => order[index];

  @override
  void initState() {
    super.initState();
    _load();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final from = restFrom;
      final planned = _restTarget;
      if (from != null &&
          planned != null &&
          !restBuzzed &&
          DateTime.now().difference(from).inSeconds >= planned) {
        restBuzzed = true;
        HapticFeedback.heavyImpact();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  int? get _restTarget => restFor == null
      ? null
      : order.where((s) => s.set.id == restFor).firstOrNull?.restAfter;

  /// Values for the current set: what was recorded, else exact targets, else
  /// the previous set of this exercise today. A rep range starts empty.
  void _load() {
    if (order.isEmpty) return;
    final s = step.set, t = step.target;
    final previous = order
        .take(index)
        .where(
          (o) => o.exercise.id == step.exercise.id && o.set.status.attempted,
        )
        .lastOrNull
        ?.set;
    if (s.status != StrengthSetStatus.unrecorded) {
      reps = s.reps;
      seconds = s.durationSeconds;
      kg = s.load?.kg;
      return;
    }
    reps = t?.reps ?? previous?.reps;
    seconds = t?.durationSeconds ?? previous?.durationSeconds;
    kg = t?.load?.kg ?? previous?.load?.kg;
    if (t?.isRange ?? false) reps = previous?.reps;
  }

  void _go(int i) => setState(() {
    index = i.clamp(0, order.length - 1);
    error = null;
    _load();
  });

  StrengthActivityLog _replace(StrengthSetResult set) => log.copyWith(
    exercises: [
      for (final e in log.exercises)
        e.copyWith(sets: [for (final s in e.sets) s.id == set.id ? set : s]),
    ],
  );

  Future<bool> _save(StrengthActivityLog next) async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final saved = await repo.saveLog(next);
      if (!mounted) return true;
      setState(() {
        log = saved;
        order = strengthFocusOrder(saved);
        saving = false;
      });
      return true;
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = '$e';
        });
      }
      return false;
    }
  }

  Future<void> _record(StrengthSetStatus status) async {
    final c = step.exercise.convention;
    final StrengthSetResult next;
    try {
      next = recordFocusSet(
        step.set,
        status,
        reps: reps,
        seconds: seconds,
        load: kg == null || !c.loadKind.hasKg
            ? null
            : step.set.load != null && (step.set.load!.kg - kg!).abs() < 1e-9
            ? step.set.load
            : StrengthLoad(kg!, unit: ref.read(massUnitProvider)),
      );
    } on StrengthValidationException catch (e) {
      setState(() => error = e.message);
      return;
    }
    // A rest still running was never ended by "Start set": its length is
    // not known, so nothing is recorded for it.
    restFrom = null;
    restFor = null;
    HapticFeedback.mediumImpact();
    if (!await _save(_replace(next))) return;
    final last = index == order.length - 1;
    if (!last && status != StrengthSetStatus.skipped) {
      restFrom = DateTime.now();
      restFor = next.id;
      restBuzzed = false;
    }
    final open = order.indexWhere(
      (s) => s.set.status == StrengthSetStatus.unrecorded,
    );
    if (open >= 0) _go(open);
  }

  Future<void> _startSet() async {
    final from = restFrom, id = restFor;
    if (from == null || id == null) return;
    final set = log.sets.where((s) => s.id == id).firstOrNull;
    setState(() {
      restFrom = null;
      restFor = null;
    });
    if (set == null) return;
    HapticFeedback.selectionClick();
    await _save(_replace(withTimedRest(set, DateTime.now().difference(from))));
  }

  Future<void> _enter(
    String label,
    String? current,
    void Function(String) apply,
  ) async {
    final values = await showStrengthFieldsDialog(
      context,
      title: label,
      fields: [strengthDialogField(label, initial: current ?? '')],
    );
    if (values != null && mounted) setState(() => apply(values.single));
  }

  Future<void> _finish() async {
    var next = log.copyWith(status: StrengthLogStatus.finished);
    final open = log.unrecordedSets;
    if (open > 0) {
      if (!await confirmAction(
        context,
        'Finish with sets open?',
        '$open ${open == 1 ? 'set is' : 'sets are'} not recorded. They stay '
            'unrecorded; finishing does not mark them as done.',
      )) {
        return;
      }
      next = next.copyWith(incompleteAcknowledged: true);
    }
    if (!mounted) return;
    var complete = false;
    if (widget.sessionId != null) {
      complete = await confirmAction(
        context,
        'Complete the planned workout?',
        'Marks the planned session as done with this workout.',
      );
    }
    if (!await _save(next)) return;
    try {
      await repo.finishLiveSession(
        log.activityId,
        sessionId: complete ? widget.sessionId : null,
      );
    } on Object catch (e) {
      if (mounted) setState(() => error = '$e');
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _discard() async {
    if (!await confirmAction(
      context,
      'Discard this workout?',
      'Removes the workout and every set recorded in it.',
    )) {
      return;
    }
    if (!mounted) return;
    await runUiAction(context, () async {
      await repo.discardLiveSession(log.activityId);
      if (mounted) Navigator.pop(context, true);
    });
  }

  Widget _stepper({
    required String label,
    required String value,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
    required VoidCallback onTap,
  }) => Semantics(
    container: true,
    label: '$label: $value',
    child: Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: muted, letterSpacing: .8),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              tooltip: 'Less $label',
              iconSize: 28,
              onPressed: onMinus,
              icon: const Icon(Icons.remove),
            ),
            Flexible(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Center(
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'More $label',
              iconSize: 28,
              onPressed: onPlus,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(massUnitProvider);
    if (order.isEmpty) {
      return SheetPage(
        title: 'Gym mode',
        child: const EmptyState('This workout has no sets.'),
      );
    }
    final s = step, c = s.exercise.convention;
    final step0 = ref
        .watch(strengthIncrementProvider(s.exercise.contextKey))
        .valueOrNull;
    final stepKg = step0?.kg ?? unit.toKg(unit == MassUnit.kg ? 2.5 : 5);
    final elapsed = DateTime.now().difference(widget.startedAt);
    final exerciseIds = [for (final o in order) o.exercise.id];
    final exerciseNo = exerciseIds.toSet().toList().indexOf(s.exercise.id) + 1;
    final setsOfExercise = order
        .where((o) => o.exercise.id == s.exercise.id)
        .toList();
    final setNo = setsOfExercise.indexOf(s) + 1;
    final timed =
        s.target?.timed ??
        builtInStrengthVariant(s.exercise.variantId)?.timed ??
        false;
    final resting = restFrom != null;
    final rest = resting ? DateTime.now().difference(restFrom!) : Duration.zero;
    final restTarget = _restTarget;
    final done = log.sets
        .where((x) => x.status != StrengthSetStatus.unrecorded)
        .length;
    void enterLoad() => _enter(
      'Load (${unit.name})',
      kg == null ? null : formatStrengthLoad(kg!, unit).split(' ').first,
      (v) {
        final x = parseDecimal(v);
        kg = x == null || !x.isFinite || x < 0 ? kg : unit.toKg(x);
      },
    );

    return PopScope(
      canPop: !saving,
      child: SheetPage(
        title: 'Gym mode',
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Workout actions',
            onSelected: (v) => v == 'discard' ? _discard() : null,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'discard', child: Text('Discard workout')),
            ],
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: muted),
                const SizedBox(width: 6),
                Text(
                  _clock(elapsed),
                  style: const TextStyle(color: muted, fontFeatures: _tabular),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      saving
                          ? 'Saving…'
                          : error != null
                          ? 'Could not save'
                          : '$done of ${order.length} sets recorded',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 12,
                        color: error != null ? Colors.redAccent : muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 14),
            Text(
              'EXERCISE $exerciseNo · SET $setNo OF ${setsOfExercise.length}'
              '${s.set.kind == StrengthSetKind.working ? '' : ' · ${s.set.kind.label.toUpperCase()}'}',
              style: const TextStyle(
                color: strengthColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 4),
            Semantics(
              header: true,
              child: Text(
                s.exercise.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              [
                if (s.exercise.equipment.isNotEmpty) s.exercise.equipment,
                c.text,
              ].join(' · '),
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            if (StrengthExerciseDemo.has(s.exercise.variantId))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: StrengthExerciseDemo(
                  key: ValueKey(s.exercise.variantId),
                  variantId: s.exercise.variantId,
                  name: s.exercise.name,
                  height: 170,
                ),
              ),
            if (s.target != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Planned ${strengthTargetText(s.target!, c, unit)}'
                  '${s.target!.effort == null ? '' : ' · ${s.target!.effort!.text}'}',
                  style: const TextStyle(fontSize: 15, color: Colors.white70),
                ),
              ),
            if (s.set.status != StrengthSetStatus.unrecorded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    StrengthStatusChip(s.set.status),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strengthResultText(s.set, c, unit),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 22),
            if (resting) ...[
              Semantics(
                liveRegion: true,
                label:
                    'Rest ${_clock(rest)}'
                    '${restTarget == null ? '' : ' of ${formatStrengthSeconds(restTarget)} planned'}',
                child: Column(
                  children: [
                    const Text(
                      'REST',
                      style: TextStyle(
                        fontSize: 11,
                        color: muted,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _clock(rest),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        fontFeatures: _tabular,
                        color:
                            restTarget != null && rest.inSeconds >= restTarget
                            ? mint
                            : null,
                      ),
                    ),
                    if (restTarget != null)
                      Text(
                        'Planned ${formatStrengthSeconds(restTarget)}',
                        style: const TextStyle(color: muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: strengthColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 56),
                ),
                onPressed: saving ? null : _startSet,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start set', style: TextStyle(fontSize: 17)),
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () => setState(() {
                  restFrom = null;
                  restFor = null;
                }),
                child: const Text("Don't time this rest"),
              ),
              const SizedBox(height: 12),
            ],
            if (timed)
              _stepper(
                label: 'Seconds',
                value: seconds == null ? '—' : formatStrengthSeconds(seconds!),
                onMinus: (seconds ?? 0) <= 0
                    ? null
                    : () => setState(
                        () => seconds = (seconds! - 5).clamp(0, 36000),
                      ),
                onPlus: () => setState(() => seconds = (seconds ?? 0) + 5),
                onTap: () => _enter('Seconds', seconds?.toString(), (v) {
                  seconds = int.tryParse(v.trim());
                }),
              )
            else
              _stepper(
                label: c.side == StrengthSide.unilateral
                    ? 'Reps per side'
                    : 'Reps',
                value: reps?.toString() ?? '—',
                onMinus: (reps ?? 0) <= 0
                    ? null
                    : () => setState(() => reps = reps! - 1),
                onPlus: () => setState(
                  () =>
                      reps = reps == null ? (s.target?.repMin ?? 1) : reps! + 1,
                ),
                onTap: () => _enter('Reps', reps?.toString(), (v) {
                  reps = int.tryParse(v.trim());
                }),
              ),
            if (c.loadKind.hasKg) ...[
              const SizedBox(height: 14),
              _stepper(
                label: c.loadKind == StrengthLoadKind.assisted
                    ? 'Assistance (${unit.name})'
                    : 'Load (${unit.name})',
                value: kg == null
                    ? '—'
                    : formatStrengthLoad(kg!, unit).split(' ').first,
                onMinus: kg == null || kg! - stepKg < -1e-9
                    ? null
                    : () => setState(() => kg = kg! - stepKg),
                // No load yet: "+" asks for it rather than inventing one.
                onPlus: kg == null
                    ? enterLoad
                    : () => setState(() => kg = kg! + stepKg),
                onTap: enterLoad,
              ),
            ],
            const SizedBox(height: 22),
            if (!resting)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: strengthColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 56),
                ),
                onPressed: saving
                    ? null
                    : () => _record(StrengthSetStatus.completed),
                icon: const Icon(Icons.check),
                label: const Text('Done', style: TextStyle(fontSize: 17)),
              ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final st in const [
                  StrengthSetStatus.partial,
                  StrengthSetStatus.failed,
                  StrengthSetStatus.skipped,
                ])
                  TextButton.icon(
                    style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: saving ? null : () => _record(st),
                    icon: Icon(strengthStatusStyle(st).$1, size: 18),
                    label: Text(st.label),
                  ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous set',
                  onPressed: index == 0 ? null : () => _go(index - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: () async {
                      final i = await showModalBottomSheet<int>(
                        context: context,
                        builder: (_) => ListView(
                          children: [
                            for (var j = 0; j < order.length; j++)
                              ListTile(
                                selected: j == index,
                                leading: Icon(
                                  strengthStatusStyle(order[j].set.status).$1,
                                ),
                                title: Text(order[j].exercise.name),
                                subtitle: Text(
                                  order[j].set.status ==
                                              StrengthSetStatus.unrecorded &&
                                          order[j].target != null
                                      ? 'Planned ${strengthTargetText(order[j].target!, order[j].exercise.convention, unit)}'
                                      : strengthResultText(
                                          order[j].set,
                                          order[j].exercise.convention,
                                          unit,
                                        ),
                                ),
                                onTap: () => Navigator.pop(context, j),
                              ),
                          ],
                        ),
                      );
                      if (i != null) _go(i);
                    },
                    child: const Text('All sets'),
                  ),
                ),
                IconButton(
                  tooltip: 'Next set',
                  onPressed: index >= order.length - 1
                      ? null
                      : () => _go(index + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: saving ? null : _finish,
              child: const Text('Finish workout'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Every set is saved as you go. Close this screen any time and resume from the planned workout.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
