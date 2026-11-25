import '../../theme/fjelia_style.dart';
import '../../l10n/formats.dart';
import '../../l10n/l10n_ext.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/plan_goal_sync_provider.dart';
import '../../providers/planner_providers.dart';
import '../../providers/week_start_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../services/race_goal_service.dart';
import '../../db/database.dart' show RaceGoal;
import 'package:fjelia_core/models/race_profile.dart';
import 'package:fjelia_core/utils/decimal.dart';
import 'package:fjelia_core/utils/target_time.dart';
import '../../providers/media_provider.dart';
import '../../providers/race_library_provider.dart';
import '../../services/race_library.dart';
import '../../widgets/media_gallery.dart';

/// Opens the race goal sheet: a new goal, or [goal] to change.
Future<void> showRaceGoalEditor(BuildContext context, {RaceGoal? goal}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: .8,
        child: RaceGoalEditor(goal: goal),
      ),
    );

class RaceGoalEditor extends ConsumerStatefulWidget {
  const RaceGoalEditor({super.key, this.goal});

  /// The goal to change; null adds a new one.
  final RaceGoal? goal;
  @override
  ConsumerState<RaceGoalEditor> createState() => _RaceEditorState();
}

class _RaceEditorState extends ConsumerState<RaceGoalEditor> {
  final name = TextEditingController(),
      km = TextEditingController(),
      elevation = TextEditingController(),
      target = TextEditingController();
  final form = GlobalKey<FormState>();
  DateTime? date;
  String sport = 'running', priority = 'a', participation = 'committed';
  String? ambition;
  String? dateError;
  bool saving = false, more = false;

  /// Where the race library's facts came from, shown under the name.
  String? librarySource;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    if (g == null) return;
    name.text = g.name;
    sport = g.primarySport;
    priority = g.priority;
    participation = g.participation;
    ambition = g.ambition;
    more = participation != 'committed' || ambition != null;
    date = g.raceDate;
    km.text = _km(g.distanceM / 1000);
    if (g.elevationM != null) elevation.text = _km(g.elevationM!);
    if (g.targetFinishSeconds != null) {
      target.text = formatTargetTime(g.targetFinishSeconds!);
    }
  }

  @override
  void dispose() {
    name.dispose();
    km.dispose();
    elevation.dispose();
    target.dispose();
    super.dispose();
  }

  /// Fills the form from a race library hit; several distances ask which.
  Future<void> _fillFromLibrary(RaceHit hit) async {
    final edition = hit.editionId == null
        ? null
        : await ref.read(raceLibraryProvider).edition(hit.editionId!);
    if (!mounted) return;
    final races =
        edition?.races ??
        [
          for (final km in hit.distancesKm)
            RaceDistance(
              distanceKm: km,
              elevationGainM: hit.distancesKm.length == 1 ? hit.maxGainM : null,
            ),
        ];
    final race = races.length <= 1
        ? races.firstOrNull
        : await _chooseDistance(races);
    if (!mounted) return;
    setState(() {
      name.text = hit.title;
      sport = race?.sport ?? edition?.sport ?? hit.sport ?? sport;
      if (race != null) {
        km.text = _km(race.distanceKm);
        elevation.text = race.elevationGainM?.toString() ?? '';
      }
      if (hit.upcoming && hit.date != null) {
        date = hit.date;
        dateError = null;
      }
      librarySource = edition?.sourceName ?? 'races.fjelia.com';
    });
  }

  Future<RaceDistance?> _chooseDistance(List<RaceDistance> races) =>
      showModalBottomSheet<RaceDistance>(
        context: context,
        useSafeArea: true,
        backgroundColor: panel,
        builder: (context) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                context.l10n.raceLibraryWhichDistance,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            for (final race in races)
              ListTile(
                title: Text(race.name ?? '${_km(race.distanceKm)} km'),
                subtitle: Text(
                  [
                    '${_km(race.distanceKm)} km',
                    if (race.elevationGainM case final gain?) '↑ $gain m',
                  ].join(' · '),
                  style: TextStyle(color: muted),
                ),
                onTap: () => Navigator.pop(context, race),
              ),
          ],
        ),
      );

  /// What the target time means as a pace or speed, shown above the field.
  String _paceHint() {
    final distance = parseDecimal(km.text);
    final seconds = parseTargetTime(
      target.text,
      distanceKm: distance,
      sport: sport,
    );
    if (distance == null || seconds == null) {
      return context.l10n.optionalPlansAndPaceGuides;
    }
    final profile = RaceProfile(
      sport: sport,
      distanceM: distance * 1000,
      elevationM: parseDecimal(elevation.text),
      targetSeconds: seconds,
    );
    if (profile.isRide) {
      return '${profile.goalSpeedKmh!.fixed(1)} km/h on average';
    }
    final pace = formatPace(profile.goalPaceSecPerKm!);
    final flat = profile.flatEquivalentPaceSecPerKm!;
    return profile.climbPerKm == null ||
            (profile.goalPaceSecPerKm! - flat).abs() < 3
        ? '$pace on average'
        : '$pace on average, ${formatPace(flat)} on the flat';
  }

  @override
  Widget build(BuildContext context) {
    const accent = Colors.orange;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: muted,
          fontSize: 10,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    Widget choices(
      Map<String?, String> options,
      String? selected,
      void Function(String?) onChanged,
    ) => Wrap(
      spacing: 8,
      children: [
        for (final e in options.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: e.key == selected,
            onSelected: saving ? null : (_) => onChanged(e.key),
          ),
      ],
    );
    InputDecoration decoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: muted),
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: fjInk12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: fjInk12),
      ),
    );
    Widget number(
      TextEditingController controller,
      String hint, {
      bool optional = false,
    }) => TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: decoration(hint),
      style: TextStyle(fontSize: 14),
      validator: (value) {
        if (optional && (value == null || value.trim().isEmpty)) return null;
        final v = parseDecimal(value);
        return v == null || !v.isFinite || (optional ? v < 0 : v <= 0)
            ? context.l10n.enterAValidNumber
            : null;
      },
    );
    return ColoredBox(
      color: panel,
      child: Column(
        children: [
          SizedBox(height: 14),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: fjInk24,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Form(
              key: form,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 24,
                ),
                children: [
                  Text(
                    widget.goal == null
                        ? context.l10n.addRaceGoal2
                        : context.l10n.editRaceGoal,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  label(context.l10n.raceName),
                  _RaceNameField(
                    controller: name,
                    decoration: decoration('e.g. UTMB 2027'),
                    enabled: !saving,
                    onPicked: _fillFromLibrary,
                  ),
                  if (librarySource case final source?)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        context.l10n.raceLibraryFilledFrom(source),
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ),
                  label(context.l10n.sport2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in {
                        'running': context.l10n.running,
                        'trail_running': context.l10n.trailRunning2,
                        'cycling_road': context.l10n.roadCycling,
                        'cycling_gravel': context.l10n.gravel,
                        'cycling_mtb': context.l10n.mtb,
                        'swimming': context.l10n.swimming,
                        'triathlon': context.l10n.triathlon,
                        'indoor_rowing': context.l10n.indoorRowing,
                      }.entries)
                        ChoiceChip(
                          label: Text(e.value),
                          selected: sport == e.key,
                          onSelected: saving
                              ? null
                              : (_) => setState(() => sport = e.key),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          selectedColor: accent.withValues(alpha: .15),
                          backgroundColor: fjInk.withValues(alpha: .04),
                          side: BorderSide(
                            color: sport == e.key ? accent : fjInk12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            color: sport == e.key ? accent : fjInk70,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            label(context.l10n.distanceKm),
                            number(km, 'e.g. 42.2'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            label(context.l10n.priority),
                            Row(
                              children: [
                                for (final p in ['a', 'b', 'c'])
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 44),
                                          foregroundColor: p == priority
                                              ? accent
                                              : fjInk70,
                                          backgroundColor: p == priority
                                              ? accent.withValues(alpha: .15)
                                              : fjInk.withValues(alpha: .04),
                                          side: BorderSide(
                                            color: p == priority
                                                ? accent
                                                : fjInk12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                          ),
                                        ),
                                        onPressed: saving
                                            ? null
                                            : () =>
                                                  setState(() => priority = p),
                                        child: Text(p.toUpperCase()),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  label(context.l10n.elevationGainM),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      context.l10n.optionalTotalClimbingForThis,
                      style: TextStyle(fontSize: 12, color: fjInk70),
                    ),
                  ),
                  number(elevation, 'e.g. 2400 (optional)', optional: true),
                  label(context.l10n.targetTime),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _paceHint(),
                      style: TextStyle(fontSize: 12, color: fjInk70),
                    ),
                  ),
                  TextFormField(
                    controller: target,
                    keyboardType: TextInputType.text,
                    onChanged: (_) => setState(() {}),
                    decoration: decoration('e.g. 3:30:00 (optional)'),
                    style: const TextStyle(fontSize: 14),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return parseTargetTime(
                                v,
                                distanceKm: parseDecimal(km.text),
                                sport: sport,
                              ) ==
                              null
                          ? context.l10n.useHMmOrH
                          : null;
                    },
                  ),
                  label(context.l10n.raceDate),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: date == null ? muted : fjInk,
                      side: BorderSide(color: fjInk12),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_month_outlined, size: 20),
                    label: Text(
                      date == null ? context.l10n.selectDate : dayText(date!),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            final now = DateUtils.dateOnly(DateTime.now());
                            final chosen = await showDatePicker(
                              context: context,
                              builder: (context, child) => Consumer(
                                builder: (context, ref, _) =>
                                    Localizations.override(
                                      context: context,
                                      delegates: [
                                        _RaceDateLocalizationsDelegate(
                                          ref.watch(weekStartsOnMondayProvider),
                                        ),
                                      ],
                                      child: child!,
                                    ),
                              ),
                              initialDate:
                                  date ?? now.add(const Duration(days: 90)),
                              firstDate: date != null && date!.isBefore(now)
                                  ? date!
                                  : now,
                              lastDate: DateTime(
                                now.year + 10,
                                now.month,
                                now.day,
                              ),
                            );
                            if (chosen != null && mounted) {
                              setState(() {
                                date = chosen;
                                dateError = null;
                              });
                            }
                          },
                  ),
                  if (dateError != null)
                    Text(
                      dateError!,
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        foregroundColor: fjInk70,
                      ),
                      icon: Icon(
                        more ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                      ),
                      label: Text(context.l10n.moreAboutThisEvent),
                      onPressed: () => setState(() => more = !more),
                    ),
                  ),
                  if (more) ...[
                    label(context.l10n.participation),
                    choices(
                      {
                        'committed': context.l10n.committed,
                        'flexible': context.l10n.flexible,
                        'cancelled': context.l10n.notGoing,
                      },
                      participation,
                      (v) => setState(() => participation = v!),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        context.l10n.flexibleThePlanMayDrop,
                        style: TextStyle(fontSize: 12, color: fjInk70),
                      ),
                    ),
                    label(context.l10n.whatIWantFromIt),
                    choices(
                      {
                        null: context.l10n.notSaid,
                        'finish': context.l10n.finish,
                        'performance': 'A time',
                      },
                      ambition,
                      (v) => setState(() => ambition = v),
                    ),
                  ],
                  if (widget.goal case final goal?) ...[
                    const SizedBox(height: 16),
                    MediaGallery(owner: MediaOwner.raceGoal(goal.id)),
                  ],
                  SizedBox(height: more ? 24 : 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            final valid = form.currentState!.validate();
                            setState(
                              () => dateError = date == null
                                  ? context.l10n.selectARaceDate
                                  : null,
                            );
                            if (!valid || date == null) {
                              return;
                            }
                            var distanceKm = parseDecimal(km.text)!;
                            // 422 for 42.2: ask before saving a ten-fold distance.
                            final likely = likelyRaceDistanceKm(distanceKm);
                            if (likely != null) {
                              final useLikely = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    context.l10n.distanceOfDistancekmKm(
                                      _km(distanceKm),
                                    ),
                                  ),
                                  content: Text(
                                    context.l10n.thatIsTenTimesOr(_km(likely)),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                        context.l10n.keepDistancekmKm(
                                          _km(distanceKm),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        context.l10n.useLikelyKm(_km(likely)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (useLikely == null || !context.mounted) return;
                              if (useLikely) distanceKm = likely;
                            }
                            setState(() => saving = true);
                            await runUiAction(context, () async {
                              final service = ref.read(raceGoalServiceProvider);
                              final seconds = target.text.trim().isEmpty
                                  ? null
                                  : parseTargetTime(
                                      target.text,
                                      distanceKm: distanceKm,
                                      sport: sport,
                                    );
                              final climb = elevation.text.trim().isEmpty
                                  ? null
                                  : parseDecimal(elevation.text);
                              final existing = widget.goal;
                              if (existing == null) {
                                await service.create(
                                  name: name.text.trim(),
                                  primarySport: sport,
                                  distanceM: distanceKm * 1000,
                                  elevationM: climb,
                                  targetFinishSeconds: seconds,
                                  raceDate: date!,
                                  priority: priority,
                                  participation: participation,
                                  ambition: ambition,
                                );
                              } else {
                                await service.update(
                                  existing.id,
                                  name: name.text.trim(),
                                  primarySport: sport,
                                  distanceM: distanceKm * 1000,
                                  elevationM: climb,
                                  targetFinishSeconds: seconds,
                                  raceDate: date!,
                                  priority: priority,
                                  participation: participation,
                                  ambition: ambition,
                                );
                              }
                              ref.invalidate(upcomingRaceGoalsProvider);
                              ref.invalidate(primaryRaceGoalProvider);
                              ref.invalidate(goalSetProvider);
                              // Marking the last goal "Not going" leaves the
                              // plan with nothing to prepare for.
                              await ref.read(retirePlanWithoutGoalsProvider)();
                              if (context.mounted) Navigator.pop(context);
                            });
                            if (mounted) setState(() => saving = false);
                          },
                    child: Text(
                      saving
                          ? context.l10n.saving
                          : widget.goal == null
                          ? context.l10n.addGoal
                          : context.l10n.saveGoal,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Race name with typeahead from the race library (from 3 characters).
class _RaceNameField extends ConsumerStatefulWidget {
  const _RaceNameField({
    required this.controller,
    required this.decoration,
    required this.enabled,
    required this.onPicked,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final bool enabled;
  final ValueChanged<RaceHit> onPicked;

  @override
  ConsumerState<_RaceNameField> createState() => _RaceNameFieldState();
}

class _RaceNameFieldState extends ConsumerState<_RaceNameField> {
  final focus = FocusNode();
  int query = 0;

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  Future<Iterable<RaceHit>> _options(TextEditingValue value) async {
    final text = value.text.trim();
    final ticket = ++query;
    if (text.length < 3) return const [];
    // Wait for a pause in typing; a newer keystroke drops this request.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (ticket != query || !mounted) return const [];
    final hits = await ref.read(raceLibraryProvider).search(text);
    return ticket == query ? hits : const [];
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => RawAutocomplete<RaceHit>(
      textEditingController: widget.controller,
      focusNode: focus,
      displayStringForOption: (hit) => hit.title,
      optionsBuilder: _options,
      onSelected: widget.onPicked,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            enabled: widget.enabled,
            decoration: widget.decoration,
            style: TextStyle(fontSize: 14),
            textInputAction: TextInputAction.next,
            validator: (v) => v == null || v.trim().isEmpty
                ? context.l10n.enterARaceName
                : null,
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: panel,
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 280,
              maxWidth: constraints.maxWidth,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final hit in options)
                  ListTile(
                    dense: true,
                    title: Text(hit.title, style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      [
                        if (hit.date case final day?) dayText(day),
                        if (hit.distancesKm.isNotEmpty)
                          hit.distancesKm
                              .map((d) => '${_km(d)} km')
                              .join(' / '),
                        if (hit.maxGainM case final gain? when gain > 0)
                          '↑ $gain m',
                      ].join(' · '),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    onTap: () => onSelected(hit),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Keep the app's English date labels and parsing, changing only week order.
class _RaceDateLocalizations extends DefaultMaterialLocalizations {
  const _RaceDateLocalizations(this.mondayFirst);

  final bool mondayFirst;

  @override
  int get firstDayOfWeekIndex => mondayFirst ? 1 : 0;
}

class _RaceDateLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _RaceDateLocalizationsDelegate(this.mondayFirst);

  final bool mondayFirst;

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(_RaceDateLocalizations(mondayFirst));

  @override
  bool shouldReload(_RaceDateLocalizationsDelegate old) =>
      old.mondayFirst != mondayFirst;
}

String _km(double km) => km == km.roundToDouble()
    ? km.round().toString()
    : km.fixed(km < 100 ? 1 : 0);
