import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';

import '../../models/strength_workout.dart';
import '../../theme/activity_colors.dart';
import '../../utils/decimal.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/strength_widgets.dart';

/// Bottom-sheet forms for strength editing. Each returns the edited value,
/// or null when cancelled; nothing is saved here.

/// Seconds from "90", "1:30" or "1:30.0"; null when blank. Throws for text
/// that is not a duration.
int? parseStrengthSeconds(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final m = RegExp(r'^(\d+):([0-5]?\d)$').firstMatch(t);
  if (m != null) return int.parse(m[1]!) * 60 + int.parse(m[2]!);
  final s = int.tryParse(t);
  if (s == null) throw FormatException(tr.enterSecondsOrMSs);
  return s;
}

int? _int(String text, String what) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final v = int.tryParse(t);
  if (v == null) throw FormatException('$what must be a whole number.');
  return v;
}

String _secondsField(int? s) => s == null
    ? ''
    : s < 60
    ? '$s'
    : formatStrengthSeconds(s);

String _loadField(StrengthLoad? load, MassUnit unit) {
  if (load == null) return '';
  final v = unit.fromKg(load.kg);
  final r = (v * 100).round() / 100;
  return r == r.roundToDouble() ? r.round().toString() : '$r';
}

/// Parses a load in [unit]; an unchanged field keeps the stored kilograms
/// exactly, so a display round trip never drifts.
StrengthLoad? _load(String text, MassUnit unit, StrengthLoad? previous) {
  final t = text.trim();
  if (t.isEmpty) return null;
  if (previous != null && t == _loadField(previous, unit)) return previous;
  final v = parseDecimal(t);
  if (v == null || !v.isFinite) {
    throw FormatException(tr.enterTheLoadAsA);
  }
  if (v < 0) throw FormatException(tr.loadCannotBeNegative);
  return StrengthLoad.entered(v, unit);
}

class _FormSheet extends StatelessWidget {
  const _FormSheet({
    required this.title,
    required this.children,
    required this.onSave,
    this.error,
    this.subtitle,
  });
  final String title;
  final String? subtitle, error;
  final List<Widget> children;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .92,
    child: Material(
      color: const Color(0xFF111111),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                subtitle!,
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ),
          ...children,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.cancel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: strengthColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: onSave,
                  child: Text(context.l10n.apply),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _field(
  TextEditingController c,
  String label, {
  String? suffix,
  String? hint,
  bool number = true,
  bool decimal = false,
}) => Padding(
  padding: const EdgeInsets.only(top: 12),
  child: TextField(
    controller: c,
    keyboardType: number
        ? TextInputType.numberWithOptions(decimal: decimal)
        : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      hintText: hint,
    ),
  ),
);

Future<T?> _sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => child,
    );

enum _Mode { reps, range, time }

class _EffortFields {
  _EffortFields(StrengthEffort? e)
    : scale = e?.scale,
      value = TextEditingController(
        text: e == null
            ? ''
            : e.value == e.value.roundToDouble()
            ? '${e.value.round()}'
            : '${e.value}',
      );
  StrengthEffortScale? scale;
  final TextEditingController value;

  StrengthEffort? read() {
    if (scale == null) return null;
    final v = parseDecimal(value.text);
    if (v == null) throw FormatException(tr.enterTheEffortValue);
    return StrengthEffort(scale!, v);
  }

  Widget build(BuildContext context, void Function(void Function()) setState) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<StrengthEffortScale?>(
                initialValue: scale,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.l10n.effortScale,
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(context.l10n.none)),
                  for (final s in StrengthEffortScale.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => scale = v),
              ),
            ),
            if (scale != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: scale == StrengthEffortScale.rir
                        ? context.l10n.repsInReserve
                        : 'RPE',
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// Edits one planned set. Switching between repetitions, a range and time
/// clears the fields of the other modes.
Future<StrengthSetTarget?> showSetTargetForm(
  BuildContext context, {
  required StrengthSetTarget target,
  required StrengthConvention convention,
  required MassUnit unit,
  String? title,
}) => _sheet(
  context,
  _SetTargetForm(target, convention, unit, title ?? tr.setLabel),
);

class _SetTargetForm extends StatefulWidget {
  const _SetTargetForm(this.target, this.convention, this.unit, this.title);
  final StrengthSetTarget target;
  final StrengthConvention convention;
  final MassUnit unit;
  final String title;
  @override
  State<_SetTargetForm> createState() => _SetTargetFormState();
}

class _SetTargetFormState extends State<_SetTargetForm> {
  late final t = widget.target;
  late StrengthSetKind kind = t.kind;
  late _Mode mode = t.timed
      ? _Mode.time
      : t.isRange
      ? _Mode.range
      : _Mode.reps;
  late final reps = TextEditingController(text: t.reps?.toString() ?? '');
  late final min = TextEditingController(text: t.repMin?.toString() ?? '');
  late final max = TextEditingController(text: t.repMax?.toString() ?? '');
  late final seconds = TextEditingController(
    text: _secondsField(t.durationSeconds),
  );
  late final load = TextEditingController(
    text: _loadField(t.load, widget.unit),
  );
  late final resistance = TextEditingController(text: t.resistance ?? '');
  late final rest = TextEditingController(text: _secondsField(t.restSeconds));
  late final tempo = TextEditingController(text: t.tempo ?? '');
  late final notes = TextEditingController(text: t.notes ?? '');
  late final effort = _EffortFields(t.effort);
  String? error;

  @override
  void dispose() {
    for (final c in [
      reps,
      min,
      max,
      seconds,
      load,
      resistance,
      rest,
      tempo,
      notes,
      effort.value,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void save() {
    final c = widget.convention;
    try {
      final next = StrengthSetTarget(
        id: t.id,
        kind: kind,
        reps: mode == _Mode.reps
            ? _int(reps.text, context.l10n.repetitions)
            : null,
        repMin: mode == _Mode.range
            ? _int(min.text, context.l10n.lowestReps)
            : null,
        repMax: mode == _Mode.range
            ? _int(max.text, context.l10n.highestReps)
            : null,
        durationSeconds: mode == _Mode.time
            ? parseStrengthSeconds(seconds.text)
            : null,
        load: c.loadKind.hasKg ? _load(load.text, widget.unit, t.load) : null,
        resistance:
            c.loadKind == StrengthLoadKind.band &&
                resistance.text.trim().isNotEmpty
            ? resistance.text.trim()
            : null,
        restSeconds: parseStrengthSeconds(rest.text),
        tempo: tempo.text.trim().isEmpty
            ? null
            : tempo.text.trim().toUpperCase(),
        effort: effort.read(),
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      );
      final problems = next.validate(c);
      if (problems.isNotEmpty) {
        setState(() => error = problems.first);
        return;
      }
      Navigator.pop(context, next);
    } on FormatException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.convention;
    return _FormSheet(
      title: widget.title,
      subtitle: c.text,
      error: error,
      onSave: save,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<StrengthSetKind>(
            initialValue: kind,
            decoration: InputDecoration(labelText: context.l10n.setType),
            items: [
              for (final k in StrengthSetKind.values)
                DropdownMenuItem(value: k, child: Text(k.label)),
            ],
            onChanged: (v) => setState(() => kind = v!),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 14),
          child: SegmentedButton<_Mode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: _Mode.reps, label: Text(context.l10n.reps)),
              ButtonSegment(
                value: _Mode.range,
                label: Text(context.l10n.range),
              ),
              ButtonSegment(value: _Mode.time, label: Text(context.l10n.time)),
            ],
            selected: {mode},
            onSelectionChanged: (v) => setState(() => mode = v.first),
          ),
        ),
        if (mode == _Mode.reps)
          _field(
            reps,
            c.side == StrengthSide.unilateral
                ? context.l10n.repsPerSide
                : context.l10n.reps,
          ),
        if (mode == _Mode.range)
          Row(
            children: [
              Expanded(child: _field(min, context.l10n.fromReps)),
              const SizedBox(width: 10),
              Expanded(child: _field(max, context.l10n.toReps)),
            ],
          ),
        if (mode == _Mode.time)
          _field(
            seconds,
            context.l10n.duration,
            hint: context.l10n.t45Or100,
            number: false,
          ),
        if (c.loadKind.hasKg)
          _field(
            load,
            switch (c.loadKind) {
              StrengthLoadKind.added => context.l10n.addedLoad,
              StrengthLoadKind.assisted => context.l10n.assistance,
              _ when c.basis == StrengthLoadBasis.perImplement =>
                context.l10n.loadPerImplement,
              _ => context.l10n.load,
            },
            suffix: widget.unit.name,
            hint: context.l10n.blankWhenNotSet,
            decimal: true,
          ),
        if (c.loadKind == StrengthLoadKind.band)
          _field(
            resistance,
            context.l10n.resistance,
            hint: context.l10n.redBand,
            number: false,
          ),
        _field(
          rest,
          context.l10n.restAfterThisSet,
          hint: context.l10n.t90Or130,
          number: false,
        ),
        effort.build(context, setState),
        _field(
          tempo,
          context.l10n.tempoOptional,
          hint: '3-0-1-0',
          number: false,
        ),
        _field(notes, context.l10n.notesOptional, number: false),
      ],
    );
  }
}

/// Records one performed set. Fields start from what was recorded, never
/// from the plan; "Use planned load" copies it on request only.
Future<StrengthSetResult?> showSetResultForm(
  BuildContext context, {
  required StrengthSetResult result,
  required StrengthConvention convention,
  required MassUnit unit,
  StrengthSetTarget? target,
  bool timed = false,
  String? title,
}) => _sheet(
  context,
  _SetResultForm(result, target, convention, unit, timed, title ?? tr.setLabel),
);

class _SetResultForm extends StatefulWidget {
  const _SetResultForm(
    this.result,
    this.target,
    this.convention,
    this.unit,
    this.timed,
    this.title,
  );
  final StrengthSetResult result;
  final StrengthSetTarget? target;
  final StrengthConvention convention;
  final MassUnit unit;
  final bool timed;
  final String title;
  @override
  State<_SetResultForm> createState() => _SetResultFormState();
}

class _SetResultFormState extends State<_SetResultForm> {
  late final r = widget.result;
  late StrengthSetStatus status = r.status == StrengthSetStatus.unrecorded
      ? StrengthSetStatus.completed
      : r.status;
  late StrengthSetKind kind = r.kind;
  late bool timed =
      r.durationSeconds != null ||
      (r.reps == null && (widget.target?.timed ?? widget.timed));
  late final reps = TextEditingController(text: r.reps?.toString() ?? '');
  late final seconds = TextEditingController(
    text: _secondsField(r.durationSeconds),
  );
  late final load = TextEditingController(
    text: _loadField(r.load, widget.unit),
  );
  late final resistance = TextEditingController(text: r.resistance ?? '');
  late final rest = TextEditingController(text: _secondsField(r.restSeconds));
  late final notes = TextEditingController(text: r.notes ?? '');
  late final effort = _EffortFields(r.effort);
  String? error;

  @override
  void dispose() {
    for (final c in [
      reps,
      seconds,
      load,
      resistance,
      rest,
      notes,
      effort.value,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void save() {
    final c = widget.convention;
    final skipped = status == StrengthSetStatus.skipped;
    try {
      final newReps = skipped || timed
          ? null
          : _int(reps.text, context.l10n.repetitions);
      final newSeconds = skipped || !timed
          ? null
          : parseStrengthSeconds(seconds.text);
      final newLoad = skipped || !c.loadKind.hasKg
          ? null
          : _load(load.text, widget.unit, r.load);
      final newRest = parseStrengthSeconds(rest.text);
      final origins = {...r.origins};
      void mark(String field, bool changed) {
        if (changed) origins[field] = StrengthOrigin.manual;
      }

      mark('status', status != r.status);
      mark('reps', newReps != r.reps);
      mark('durationSeconds', newSeconds != r.durationSeconds);
      mark('load', newLoad != r.load);
      final next = r.copyWith(
        kind: kind,
        status: status,
        reps: () => newReps,
        durationSeconds: () => newSeconds,
        load: () => newLoad,
        resistance: () =>
            c.loadKind == StrengthLoadKind.band &&
                resistance.text.trim().isNotEmpty &&
                !skipped
            ? resistance.text.trim()
            : null,
        restSeconds: () => newRest,
        restOrigin: () => newRest == null
            ? null
            : newRest == r.restSeconds
            ? r.restOrigin
            : StrengthOrigin.manual,
        effort: () => skipped ? null : effort.read(),
        notes: () => notes.text.trim().isEmpty ? null : notes.text.trim(),
        origins: origins,
      );
      if (status == StrengthSetStatus.completed &&
          next.reps == null &&
          next.durationSeconds == null) {
        setState(
          () => error = timed
              ? context.l10n.enterHowLongTheSet
              : context.l10n.enterTheRepetitionsDone,
        );
        return;
      }
      final problems = next.validate(c);
      if (problems.isNotEmpty) {
        setState(() => error = problems.first);
        return;
      }
      Navigator.pop(context, next);
    } on FormatException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.convention;
    final target = widget.target;
    final skipped = status == StrengthSetStatus.skipped;
    return _FormSheet(
      title: widget.title,
      subtitle: target == null
          ? c.text
          : context.l10n.plannedUnit(
              strengthTargetText(target, c, widget.unit),
            ),
      error: error,
      onSave: save,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in [
                StrengthSetStatus.completed,
                StrengthSetStatus.partial,
                StrengthSetStatus.failed,
                StrengthSetStatus.skipped,
                StrengthSetStatus.unrecorded,
              ])
                ChoiceChip(
                  avatar: Icon(strengthStatusStyle(s).$1, size: 16),
                  label: Text(s.label),
                  selected: status == s,
                  onSelected: (_) => setState(() => status = s),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<StrengthSetKind>(
            initialValue: kind,
            decoration: InputDecoration(labelText: context.l10n.setType),
            items: [
              for (final k in StrengthSetKind.values)
                DropdownMenuItem(value: k, child: Text(k.label)),
            ],
            onChanged: (v) => setState(() => kind = v!),
          ),
        ),
        if (!skipped) ...[
          Padding(
            padding: EdgeInsets.only(top: 14),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(context.l10n.reps)),
                ButtonSegment(value: true, label: Text(context.l10n.time)),
              ],
              selected: {timed},
              onSelectionChanged: (v) => setState(() => timed = v.first),
            ),
          ),
          if (timed)
            _field(
              seconds,
              context.l10n.duration,
              hint: context.l10n.t45Or100,
              number: false,
            )
          else
            _field(
              reps,
              c.side == StrengthSide.unilateral
                  ? context.l10n.repsDonePerSide
                  : context.l10n.repsDone,
              hint: target?.isRange == true
                  ? context.l10n.plannedRepminRepmax(
                      target!.repMin ?? 0,
                      target.repMax ?? 0,
                    )
                  : null,
            ),
          if (c.loadKind.hasKg) ...[
            _field(
              load,
              c.loadKind == StrengthLoadKind.assisted
                  ? context.l10n.assistance
                  : context.l10n.load,
              suffix: widget.unit.name,
              hint: context.l10n.blankWhenUnknown,
              decimal: true,
            ),
            if (target?.load != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: () => setState(
                    () => load.text = _loadField(target!.load, widget.unit),
                  ),
                  child: Text(context.l10n.usePlannedLoad),
                ),
              ),
          ],
          if (c.loadKind == StrengthLoadKind.band)
            _field(resistance, context.l10n.resistance, number: false),
          effort.build(context, setState),
        ],
        _field(
          rest,
          context.l10n.restTakenBeforeTheNext,
          hint: context.l10n.blankWhenNotMeasured,
          number: false,
        ),
        _field(notes, context.l10n.notesOptional, number: false),
      ],
    );
  }
}

/// Name, equipment and load convention of an exercise occurrence.
typedef StrengthExerciseDetails = ({
  String name,
  String equipment,
  StrengthConvention convention,
  String? notes,
  StrengthLoad? increment,
  bool rememberIncrement,
});

Future<StrengthExerciseDetails?> showExerciseForm(
  BuildContext context, {
  required String name,
  required String equipment,
  required StrengthConvention convention,
  required MassUnit unit,
  String? notes,
  StrengthLoad? increment,
}) => _sheet(
  context,
  _ExerciseForm(name, equipment, convention, unit, notes, increment),
);

class _ExerciseForm extends StatefulWidget {
  const _ExerciseForm(
    this.name,
    this.equipment,
    this.convention,
    this.unit,
    this.notes,
    this.increment,
  );
  final String name, equipment;
  final StrengthConvention convention;
  final MassUnit unit;
  final String? notes;
  final StrengthLoad? increment;
  @override
  State<_ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends State<_ExerciseForm> {
  late final name = TextEditingController(text: widget.name);
  late final equipment = TextEditingController(text: widget.equipment);
  late final notes = TextEditingController(text: widget.notes ?? '');
  late final implements = TextEditingController(
    text: '${widget.convention.implements}',
  );
  late final increment = TextEditingController(
    text: _loadField(widget.increment, widget.unit),
  );
  late StrengthLoadKind kind = widget.convention.loadKind;
  late StrengthLoadBasis basis = widget.convention.basis;
  late StrengthSide side = widget.convention.side;
  bool remember = false;
  String? error;

  @override
  void dispose() {
    for (final c in [name, equipment, notes, implements, increment]) {
      c.dispose();
    }
    super.dispose();
  }

  void save() {
    try {
      if (name.text.trim().isEmpty) {
        throw FormatException(tr.nameTheExercise);
      }
      final n = basis == StrengthLoadBasis.perImplement
          ? _int(implements.text, context.l10n.implementsLabel) ?? 0
          : 1;
      if (n < 1) throw FormatException(tr.atLeastOneImplement);
      final step = _load(increment.text, widget.unit, widget.increment);
      if (step != null && step.kg <= 0) {
        throw FormatException(tr.anIncrementMustBePositive);
      }
      Navigator.pop<StrengthExerciseDetails>(context, (
        name: name.text.trim(),
        equipment: equipment.text.trim(),
        convention: StrengthConvention(
          loadKind: kind,
          basis: basis,
          implements: n,
          side: side,
        ),
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        increment: step,
        rememberIncrement: remember && step != null,
      ));
    } on FormatException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => _FormSheet(
    title: context.l10n.exercise,
    subtitle: context.l10n.changingTheLoadConventionStarts,
    error: error,
    onSave: save,
    children: [
      _field(name, context.l10n.name, number: false),
      _field(
        equipment,
        context.l10n.equipment,
        hint: context.l10n.barbellMachine,
        number: false,
      ),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: DropdownButtonFormField<StrengthLoadKind>(
          initialValue: kind,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.load),
          items: [
            for (final k in StrengthLoadKind.values)
              DropdownMenuItem(value: k, child: Text(k.label)),
          ],
          onChanged: (v) => setState(() => kind = v!),
        ),
      ),
      if (kind.hasKg)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<StrengthLoadBasis>(
            initialValue: basis,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.l10n.loadRefersTo),
            items: [
              for (final b in StrengthLoadBasis.values)
                DropdownMenuItem(value: b, child: Text(b.label)),
            ],
            onChanged: (v) => setState(() => basis = v!),
          ),
        ),
      if (kind.hasKg && basis == StrengthLoadBasis.perImplement)
        _field(
          implements,
          context.l10n.implementsUsedTogether,
          hint: context.l10n.t2ForAPair,
        ),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: DropdownButtonFormField<StrengthSide>(
          initialValue: side,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.repetitions),
          items: [
            for (final s in StrengthSide.values)
              DropdownMenuItem(value: s, child: Text(s.label)),
          ],
          onChanged: (v) => setState(() => side = v!),
        ),
      ),
      if (kind.hasKg) ...[
        _field(
          increment,
          context.l10n.smallestLoadStepOptional,
          suffix: widget.unit.name,
          hint: context.l10n.availablePlatesOrDumbbells,
          decimal: true,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: remember,
          onChanged: (v) => setState(() => remember = v ?? false),
          title: Text(context.l10n.rememberForThisEquipment),
        ),
      ],
      _field(notes, context.l10n.instructionsOptional, number: false),
    ],
  );
}

/// Searchable built-in and custom exercises; a custom name can be created.
/// Returns the chosen variant, or a record to create a custom one.
Future<({StrengthExerciseVariant? variant, String? customName})?>
showExercisePicker(
  BuildContext context, {
  required List<StrengthExerciseVariant> custom,
  List<StrengthExerciseVariant> recent = const [],
}) => _sheet(context, _ExercisePicker(custom, recent));

class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker(this.custom, this.recent);
  final List<StrengthExerciseVariant> custom, recent;
  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.trim().toLowerCase();
    final seen = <String>{};
    final all = [
      ...widget.recent,
      ...widget.custom,
      ...builtInStrengthVariants,
    ].where((v) => seen.add(v.id)).toList();
    final shown = q.isEmpty
        ? all
        : all
              .where(
                (v) =>
                    v.name.toLowerCase().contains(q) ||
                    v.equipment.toLowerCase().contains(q),
              )
              .toList();
    return FractionallySizedBox(
      heightFactor: .92,
      child: Material(
        color: const Color(0xFF111111),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: TextField(
                controller: search,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.l10n.findOrNameAnExercise,
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                ),
                children: [
                  if (q.isNotEmpty &&
                      !all.any((v) => v.name.toLowerCase() == q))
                    ListTile(
                      leading: const Icon(Icons.add, color: strengthColor),
                      title: Text(context.l10n.createTrim(search.text.trim())),
                      subtitle: Text(context.l10n.customExercise),
                      onTap: () => Navigator.pop(context, (
                        variant: null,
                        customName: search.text.trim(),
                      )),
                    ),
                  for (final v in shown)
                    ListTile(
                      leading: Icon(
                        v.timed ? Icons.timer_outlined : Icons.fitness_center,
                        color: muted,
                      ),
                      title: Text(v.name),
                      subtitle: Text(
                        [
                          if (v.equipment.isNotEmpty) v.equipment,
                          v.convention.text,
                          if (widget.recent.any((r) => r.id == v.id)) 'Recent',
                        ].join(' · '),
                      ),
                      onTap: () => Navigator.pop(context, (
                        variant: v,
                        customName: null,
                      )),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One field of [showStrengthFieldsDialog].
typedef StrengthDialogField = ({
  String label,
  String initial,
  String? hint,
  String? suffix,
  bool number,
});

StrengthDialogField strengthDialogField(
  String label, {
  String initial = '',
  String? hint,
  String? suffix,
  bool number = true,
}) => (
  label: label,
  initial: initial,
  hint: hint,
  suffix: suffix,
  number: number,
);

/// A small dialog of text fields. It owns its controllers, so they live
/// until the dialog has finished closing; a caller never disposes them
/// while the closing animation still draws the fields. [validate] returns
/// a message to keep the dialog open, or null to accept.
Future<List<String>?> showStrengthFieldsDialog(
  BuildContext context, {
  required String title,
  required List<StrengthDialogField> fields,
  String? message,
  String confirm = 'OK',
  String? Function(List<String> values)? validate,
}) => showDialog<List<String>>(
  context: context,
  builder: (_) => _FieldsDialog(
    title: title,
    fields: fields,
    message: message,
    confirm: confirm,
    validate: validate,
  ),
);

class _FieldsDialog extends StatefulWidget {
  const _FieldsDialog({
    required this.title,
    required this.fields,
    required this.confirm,
    this.message,
    this.validate,
  });
  final String title, confirm;
  final String? message;
  final List<StrengthDialogField> fields;
  final String? Function(List<String>)? validate;
  @override
  State<_FieldsDialog> createState() => _FieldsDialogState();
}

class _FieldsDialogState extends State<_FieldsDialog> {
  late final controllers = [
    for (final f in widget.fields) TextEditingController(text: f.initial),
  ];
  String? error;

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void submit() {
    final values = [for (final c in controllers) c.text];
    final problem = widget.validate?.call(values);
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    Navigator.pop(context, values);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null)
            Text(
              widget.message!,
              style: const TextStyle(fontSize: 12, color: muted),
            ),
          for (var i = 0; i < widget.fields.length; i++)
            TextField(
              controller: controllers[i],
              autofocus: i == 0,
              keyboardType: widget.fields[i].number
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              textInputAction: i == widget.fields.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              onSubmitted: i == widget.fields.length - 1
                  ? (_) => submit()
                  : null,
              decoration: InputDecoration(
                labelText: widget.fields[i].label,
                hintText: widget.fields[i].hint,
                suffixText: widget.fields[i].suffix,
                errorText: i == widget.fields.length - 1 ? error : null,
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      TextButton(onPressed: submit, child: Text(widget.confirm)),
    ],
  );
}

/// The smallest load step available for one exercise's equipment.
Future<StrengthLoad?> showIncrementForm(
  BuildContext context, {
  required MassUnit unit,
  StrengthLoad? current,
}) async {
  StrengthLoad? read(String text) {
    final step = _load(text, unit, current);
    if (step == null || step.kg <= 0) {
      throw FormatException(tr.enterAPositiveStep);
    }
    return step;
  }

  final values = await showStrengthFieldsDialog(
    context,
    title: context.l10n.smallestLoadStep,
    message: context.l10n.theSmallestChangeYourPlates,
    confirm: context.l10n.remember,
    fields: [
      strengthDialogField(
        context.l10n.loadStep,
        initial: _loadField(current, unit),
        suffix: unit.name,
      ),
    ],
    validate: (v) {
      try {
        read(v.single);
        return null;
      } on FormatException catch (e) {
        return e.message;
      }
    },
  );
  return values == null ? null : read(values.single);
}
