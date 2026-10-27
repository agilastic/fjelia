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
  if (s == null) throw const FormatException('Enter seconds or m:ss.');
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
    throw const FormatException('Enter the load as a number.');
  }
  if (v < 0) throw const FormatException('Load cannot be negative.');
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
                  child: const Text('Cancel'),
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
                  child: const Text('Apply'),
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
    if (v == null) throw const FormatException('Enter the effort value.');
    return StrengthEffort(scale!, v);
  }

  Widget build(void Function(void Function()) setState) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<StrengthEffortScale?>(
            initialValue: scale,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Effort scale'),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
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
                    ? 'Reps in reserve'
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
  String title = 'Set',
}) => _sheet(context, _SetTargetForm(target, convention, unit, title));

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
        reps: mode == _Mode.reps ? _int(reps.text, 'Repetitions') : null,
        repMin: mode == _Mode.range ? _int(min.text, 'Lowest reps') : null,
        repMax: mode == _Mode.range ? _int(max.text, 'Highest reps') : null,
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
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<StrengthSetKind>(
            initialValue: kind,
            decoration: const InputDecoration(labelText: 'Set type'),
            items: [
              for (final k in StrengthSetKind.values)
                DropdownMenuItem(value: k, child: Text(k.label)),
            ],
            onChanged: (v) => setState(() => kind = v!),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: SegmentedButton<_Mode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Mode.reps, label: Text('Reps')),
              ButtonSegment(value: _Mode.range, label: Text('Range')),
              ButtonSegment(value: _Mode.time, label: Text('Time')),
            ],
            selected: {mode},
            onSelectionChanged: (v) => setState(() => mode = v.first),
          ),
        ),
        if (mode == _Mode.reps)
          _field(
            reps,
            c.side == StrengthSide.unilateral ? 'Reps per side' : 'Reps',
          ),
        if (mode == _Mode.range)
          Row(
            children: [
              Expanded(child: _field(min, 'From reps')),
              const SizedBox(width: 10),
              Expanded(child: _field(max, 'To reps')),
            ],
          ),
        if (mode == _Mode.time)
          _field(seconds, 'Duration', hint: '45 or 1:00', number: false),
        if (c.loadKind.hasKg)
          _field(
            load,
            switch (c.loadKind) {
              StrengthLoadKind.added => 'Added load',
              StrengthLoadKind.assisted => 'Assistance',
              _ when c.basis == StrengthLoadBasis.perImplement =>
                'Load per implement',
              _ => 'Load',
            },
            suffix: widget.unit.name,
            hint: 'Blank when not set',
            decimal: true,
          ),
        if (c.loadKind == StrengthLoadKind.band)
          _field(resistance, 'Resistance', hint: 'Red band', number: false),
        _field(rest, 'Rest after this set', hint: '90 or 1:30', number: false),
        effort.build(setState),
        _field(tempo, 'Tempo (optional)', hint: '3-0-1-0', number: false),
        _field(notes, 'Notes (optional)', number: false),
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
  String title = 'Set',
}) => _sheet(
  context,
  _SetResultForm(result, target, convention, unit, timed, title),
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
      final newReps = skipped || timed ? null : _int(reps.text, 'Repetitions');
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
              ? 'Enter how long the set lasted.'
              : 'Enter the repetitions done.',
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
          : 'Planned ${strengthTargetText(target, c, widget.unit)}',
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
            decoration: const InputDecoration(labelText: 'Set type'),
            items: [
              for (final k in StrengthSetKind.values)
                DropdownMenuItem(value: k, child: Text(k.label)),
            ],
            onChanged: (v) => setState(() => kind = v!),
          ),
        ),
        if (!skipped) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Reps')),
                ButtonSegment(value: true, label: Text('Time')),
              ],
              selected: {timed},
              onSelectionChanged: (v) => setState(() => timed = v.first),
            ),
          ),
          if (timed)
            _field(seconds, 'Duration', hint: '45 or 1:00', number: false)
          else
            _field(
              reps,
              c.side == StrengthSide.unilateral
                  ? 'Reps done per side'
                  : 'Reps done',
              hint: target?.isRange == true
                  ? 'Planned ${target!.repMin}–${target.repMax}'
                  : null,
            ),
          if (c.loadKind.hasKg) ...[
            _field(
              load,
              c.loadKind == StrengthLoadKind.assisted ? 'Assistance' : 'Load',
              suffix: widget.unit.name,
              hint: 'Blank when unknown',
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
                  child: const Text('Use planned load'),
                ),
              ),
          ],
          if (c.loadKind == StrengthLoadKind.band)
            _field(resistance, 'Resistance', number: false),
          effort.build(setState),
        ],
        _field(
          rest,
          'Rest taken before the next set',
          hint: 'Blank when not measured',
          number: false,
        ),
        _field(notes, 'Notes (optional)', number: false),
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
        throw const FormatException('Name the exercise.');
      }
      final n = basis == StrengthLoadBasis.perImplement
          ? _int(implements.text, 'Implements') ?? 0
          : 1;
      if (n < 1) throw const FormatException('At least one implement.');
      final step = _load(increment.text, widget.unit, widget.increment);
      if (step != null && step.kg <= 0) {
        throw const FormatException('An increment must be positive.');
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
    title: 'Exercise',
    subtitle: 'Changing the load convention starts a separate history for this exercise.',
    error: error,
    onSave: save,
    children: [
      _field(name, 'Name', number: false),
      _field(equipment, 'Equipment', hint: 'Barbell, machine…', number: false),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: DropdownButtonFormField<StrengthLoadKind>(
          initialValue: kind,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Load'),
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
            decoration: const InputDecoration(labelText: 'Load refers to'),
            items: [
              for (final b in StrengthLoadBasis.values)
                DropdownMenuItem(value: b, child: Text(b.label)),
            ],
            onChanged: (v) => setState(() => basis = v!),
          ),
        ),
      if (kind.hasKg && basis == StrengthLoadBasis.perImplement)
        _field(implements, 'Implements used together', hint: '2 for a pair'),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: DropdownButtonFormField<StrengthSide>(
          initialValue: side,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Repetitions'),
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
          'Smallest load step (optional)',
          suffix: widget.unit.name,
          hint: 'Available plates or dumbbells',
          decimal: true,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: remember,
          onChanged: (v) => setState(() => remember = v ?? false),
          title: const Text('Remember for this equipment'),
        ),
      ],
      _field(notes, 'Instructions (optional)', number: false),
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
                decoration: const InputDecoration(
                  labelText: 'Find or name an exercise',
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
                      title: Text('Create “${search.text.trim()}”'),
                      subtitle: const Text('Custom exercise'),
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
        child: const Text('Cancel'),
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
      throw const FormatException('Enter a positive step.');
    }
    return step;
  }

  final values = await showStrengthFieldsDialog(
    context,
    title: 'Smallest load step',
    message:
        'The smallest change your plates, dumbbells or machine allow, '
        'remembered for this equipment.',
    confirm: 'Remember',
    fields: [
      strengthDialogField(
        'Load step',
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
