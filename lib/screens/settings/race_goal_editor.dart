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
import '../../models/race_profile.dart';
import '../../utils/decimal.dart';
import '../../utils/target_time.dart';

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
        style: const TextStyle(
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
      hintStyle: const TextStyle(color: muted),
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white12),
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
              color: Colors.white24,
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
                  TextFormField(
                    controller: name,
                    decoration: decoration('e.g. UTMB 2027'),
                    style: TextStyle(fontSize: 14),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? context.l10n.enterARaceName
                        : null,
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
                          backgroundColor: Colors.white.withValues(alpha: .04),
                          side: BorderSide(
                            color: sport == e.key ? accent : Colors.white12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            color: sport == e.key ? accent : Colors.white70,
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
                                              : Colors.white70,
                                          backgroundColor: p == priority
                                              ? accent.withValues(alpha: .15)
                                              : Colors.white.withValues(
                                                  alpha: .04,
                                                ),
                                          side: BorderSide(
                                            color: p == priority
                                                ? accent
                                                : Colors.white12,
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
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                  number(elevation, 'e.g. 2400 (optional)', optional: true),
                  label(context.l10n.targetTime),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _paceHint(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
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
                      foregroundColor: date == null ? muted : Colors.white,
                      side: const BorderSide(color: Colors.white12),
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
                        foregroundColor: Colors.white70,
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
                        style: TextStyle(fontSize: 12, color: Colors.white70),
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
