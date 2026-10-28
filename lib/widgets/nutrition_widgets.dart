import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../models/workout_nutrition.dart';
import '../providers/nutrition_provider.dart';
import '../providers/hrv_reminder_provider.dart';
import '../services/nutrition_service.dart';
import '../utils/decimal.dart';
import 'app_widgets.dart';

String _v(double? value) => value == null ? '—' : value.round().toString();
const _nutrients = ['carbs', 'fluid', 'sodium', 'caffeine', 'protein'];

Future<Map<String, String>?> _fields(
  BuildContext context,
  String title,
  Map<String, (String, String)> fields, {
  Set<String> optional = const {},
  Map<String, Map<String, String>> presets = const {},
}) => showModalBottomSheet<Map<String, String>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _NutritionFields(
    title: title,
    fields: fields,
    optional: optional,
    presets: presets,
  ),
);

class _NutritionFields extends StatefulWidget {
  const _NutritionFields({
    required this.title,
    required this.fields,
    required this.optional,
    required this.presets,
  });
  final String title;
  final Map<String, (String, String)> fields;
  final Set<String> optional;
  final Map<String, Map<String, String>> presets;
  @override
  State<_NutritionFields> createState() => _NutritionFieldsState();
}

class _NutritionFieldsState extends State<_NutritionFields> {
  late final controllers = {
    for (final e in widget.fields.entries)
      e.key: TextEditingController(text: e.value.$2),
  };
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .92,
    child: Form(
      key: form,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          if (widget.presets.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(context.l10n.examplesOnlyCheckAndEnter),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final p in widget.presets.entries)
                  ActionChip(
                    label: Text(p.key),
                    onPressed: () => setState(() {
                      for (final e in p.value.entries) {
                        controllers[e.key]?.text = e.value;
                      }
                    }),
                  ),
              ],
            ),
          ],
          for (final e in widget.fields.entries)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: e.key == 'surface' || e.key == 'phase'
                  ? DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: controllers[e.key]!.text,
                      decoration: InputDecoration(labelText: e.value.$1),
                      items: [
                        for (final value
                            in e.key == 'surface'
                                ? [
                                    'Unknown',
                                    'Indoor',
                                    'Road',
                                    context.l10n.trail,
                                    context.l10n.technical,
                                    context.l10n.snow,
                                    context.l10n.pool,
                                    context.l10n.openWater,
                                  ]
                                : ['before', 'during', 'after'])
                          DropdownMenuItem(
                            value: value,
                            child: Text(
                              _choiceLabel(context, value),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) => controllers[e.key]!.text = value!,
                    )
                  : TextFormField(
                      controller: controllers[e.key],
                      keyboardType: e.key == 'name'
                          ? TextInputType.text
                          : const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                      decoration: InputDecoration(
                        labelText: e.value.$1,
                        hintText: widget.optional.contains(e.key)
                            ? 'Unknown'
                            : null,
                      ),
                      validator: (text) {
                        if (widget.optional.contains(e.key) &&
                            (text?.trim().isEmpty ?? true)) {
                          return null;
                        }
                        if (e.key == 'name') {
                          return text!.trim().isEmpty
                              ? context.l10n.enterAName
                              : null;
                        }
                        final n = parseDecimal(text);
                        if (n == null ||
                            !n.isFinite ||
                            (!['temperature', 'altitude'].contains(e.key) &&
                                n < 0)) {
                          return context.l10n.enterAValidAmount;
                        }
                        if ([
                              'quantity',
                              'bottleMl',
                              'gelCarbs',
                              'trainedCarbs',
                            ].contains(e.key) &&
                            n <= 0) {
                          return context.l10n.enterAPositiveAmount;
                        }
                        if (e.key == 'trainedCarbs' && n > 120) {
                          return context.l10n.maximum120GH;
                        }
                        return null;
                      },
                    ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, {
                  for (final e in controllers.entries) e.key: e.value.text,
                });
              }
            },
            child: Text(context.l10n.apply),
          ),
        ],
      ),
    ),
  );
}

class PlannedNutritionCard extends ConsumerWidget {
  const PlannedNutritionCard({
    super.key,
    required this.workout,
    this.editable = true,
  });
  final NutritionWorkout workout;
  final bool editable;
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    NutritionStrategy plan,
  ) async {
    final c = plan.conditions;
    final values = await _fields(
      context,
      context.l10n.nutritionStrategy,
      {
        'carbs': (context.l10n.carbohydrateTargetGH, '${plan.carbs}'),
        'fluid': (context.l10n.fluidTargetMlH, '${plan.fluid}'),
        'sodium': (context.l10n.sodiumTargetMgHNot, '${plan.sodium}'),
        'surface': (context.l10n.surfaceFeedingAccess, c.surface),
        'ascent': (context.l10n.expectedAscentM, c.ascent?.toString() ?? ''),
        'altitude': (
          context.l10n.expectedAltitudeM,
          c.altitude?.toString() ?? '',
        ),
        'temperature': (
          context.l10n.ambientTemperatureC,
          c.temperature?.toString() ?? '',
        ),
        'humidity': (context.l10n.humidity, c.humidity?.toString() ?? ''),
        'wind': (context.l10n.windKmH, c.wind?.toString() ?? ''),
      },
      optional: {'ascent', 'altitude', 'temperature', 'humidity', 'wind'},
    );
    if (values == null || !context.mounted) return;
    final edited = NutritionConditions(
      surface: values['surface']!,
      ascent: parseDecimal(values['ascent']),
      altitude: parseDecimal(values['altitude']),
      temperature: parseDecimal(values['temperature']),
      humidity: parseDecimal(values['humidity']),
      wind: parseDecimal(values['wind']),
      uv: c.uv,
    );
    await runUiAction(context, () async {
      final prefs = await ref.read(nutritionServiceProvider).preferences();
      await ref
          .read(nutritionServiceProvider)
          .savePlan(
            planNutrition(
              workout,
              prefs,
              edited,
              carbs: parseDecimal(values['carbs']),
              fluid: parseDecimal(values['fluid']),
              sodium: parseDecimal(values['sodium']),
            ),
          );
      ref.invalidate(nutritionPlanProvider(workout));
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditions = editable
        ? ref.watch(nutritionConditionsProvider(workout)).valueOrNull
        : null;
    final AsyncValue<NutritionStrategy?> state = editable
        ? ref.watch(nutritionPlanProvider(workout))
        : ref.watch(nutritionSavedPlanProvider(workout.key));
    return SectionCard(
      title: context.l10n.nutritionStrategy,
      child: state.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => DataError(
          e,
          retry: () {
            if (editable) {
              ref.invalidate(nutritionPlanProvider(workout));
            } else {
              ref.invalidate(nutritionSavedPlanProvider(workout.key));
            }
          },
        ),
        data: (plan) => plan == null
            ? Text(context.l10n.noPreWorkoutNutritionStrategy)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.carbsGCarbsHFluid(
                      _v(plan.carbs),
                      _v(plan.fluid),
                      _v(plan.sodium),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (conditions?.forecast == true &&
                      (conditions!.temperature != plan.conditions.temperature ||
                          conditions.humidity != plan.conditions.humidity ||
                          conditions.wind != plan.conditions.wind))
                    Text(
                      context.l10n.forecastUpdatedReviewOrRecalculate,
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  Text(
                    context.l10n.strategySavedSavedat(dayText(plan.savedAt)),
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.duringTotalTotalcarbsGCarbs(
                      _v(plan.totalCarbs),
                      _v(plan.totalFluid),
                      _v(plan.totalSodium),
                    ),
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                  if (plan.carbs > 0)
                    Text(
                      context.l10n.every20MinAboutCarbs(
                        _v(plan.carbs / 3),
                        _v(plan.fluid / 3),
                      ),
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.carryAboutGelsGelsGelcarbs(
                      plan.gels,
                      _v(plan.preferences.gelCarbs),
                      plan.bottles,
                      _v(plan.preferences.bottleMl),
                      _v(plan.drinkCarbs),
                    ),
                  ),
                  Text(
                    context.l10n.packQuantitiesIncludeFullContainers,
                    style: TextStyle(fontSize: 10, color: muted),
                  ),
                  if (plan.workout != workout)
                    Text(
                      context.l10n.workoutChangedReviewOrRecalculate,
                      style: TextStyle(color: Colors.orange),
                    ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      context.l10n.conditionsAndFeedingPlan,
                      style: TextStyle(fontSize: 12),
                    ),
                    children: [
                      Text(
                        '${plan.conditions.forecast ? context.l10n.dayForecast : context.l10n.enteredConditions}: '
                        '${_v(plan.conditions.temperature)} °C · ${_v(plan.conditions.humidity)}% humidity · '
                        '${_v(plan.conditions.wind)} km/h wind. '
                        '${plan.conditions.surface} · ascent ${_v(plan.conditions.ascent)} m · altitude ${_v(plan.conditions.altitude)} m.',
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                      for (final note in plan.guidance)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            note,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  if (editable)
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => _edit(context, ref, plan),
                          child: Text(context.l10n.editStrategy),
                        ),
                        TextButton(
                          onPressed: () => runUiAction(context, () async {
                            final prefs = await ref
                                .read(nutritionServiceProvider)
                                .preferences();
                            final conditions = await ref.refresh(
                              nutritionConditionsProvider(workout).future,
                            );
                            await ref
                                .read(nutritionServiceProvider)
                                .savePlan(
                                  planNutrition(workout, prefs, conditions),
                                );
                            ref.invalidate(nutritionPlanProvider(workout));
                          }),
                          child: Text(context.l10n.recalculate),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

class ActivityNutritionCard extends ConsumerWidget {
  const ActivityNutritionCard({super.key, required this.activity});
  final ActivityRecord activity;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref
        .watch(nutritionLogProvider(activity.activityId))
        .valueOrNull;
    final plan = ref
        .watch(nutritionLinkedPlanProvider(activity.activityId))
        .valueOrNull;
    final elapsed =
        log?.elapsedMinutes ?? nutritionElapsedSeconds(activity) / 60;
    String total(
      String name,
      double Function(NutritionEntry) value,
      String unit, {
      bool during = true,
    }) {
      final unknown = log!.entries.any(
        (e) => (!during || e.phase == 'during') && e.unknown.contains(name),
      );
      return '${unknown ? '≥' : ''}${_v(log.total(value, during: during))} $unit';
    }

    return SectionCard(
      title: context.l10n.actualNutrition,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log == null || (log.entries.isEmpty && !log.finished)
                ? context.l10n.intakeNotRecorded
                : log.status == 'declined'
                ? context.l10n.loggingDeclinedIntakeUnknown
                : log.noIntake
                ? context.l10n.confirmedNoIntake
                : '${log.status == 'draft' ? context.l10n.draft : ''}During: '
                      '${total('carbs', (e) => e.carbs, 'g carbs')} · ${total('fluid', (e) => e.fluid, 'ml')} · '
                      '${total('sodium', (e) => e.sodium, 'mg sodium')}',
          ),
          if (log != null && log.entries.any((e) => e.unknown.isNotEmpty))
            Text(
              context.l10n.someProductValuesAreUnknown,
              style: TextStyle(fontSize: 11, color: muted),
            ),
          if (log != null && log.entries.isNotEmpty)
            Text(
              'All phases: '
              '${total('caffeine', (e) => e.caffeine, 'mg caffeine', during: false)} · '
              '${total('protein', (e) => e.protein, 'g protein', during: false)}',
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          if (log != null &&
              log.status == 'complete' &&
              plan != null &&
              elapsed > 0 &&
              !log.entries.any(
                (e) => e.phase == 'during' && e.unknown.contains('carbs'),
              ))
            Text(
              'During: ${_v(log.total((e) => e.carbs, during: true) / (elapsed / 60))} g/h '
              '· saved plan ${_v(plan.carbs)} g/h',
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          TextButton.icon(
            onPressed: () =>
                showAppSheet(context, NutritionIntakeSheet(activity: activity)),
            icon: const Icon(Icons.restaurant_outlined, size: 18),
            label: Text(context.l10n.logFoodAndFluids),
          ),
        ],
      ),
    );
  }
}

class NutritionIntakeSheet extends ConsumerStatefulWidget {
  const NutritionIntakeSheet({super.key, required this.activity});
  final ActivityRecord activity;
  @override
  ConsumerState<NutritionIntakeSheet> createState() => _IntakeState();
}

class _IntakeState extends ConsumerState<NutritionIntakeSheet> {
  List<NutritionEntry> entries = [];
  bool loaded = false, busy = false, noIntake = false;
  String? loadError;
  String gut = 'Not recorded';
  String? planKey;
  List<NutritionStrategy> plans = [];
  final note = TextEditingController();
  final elapsed = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final log = await ref
          .read(nutritionServiceProvider)
          .log(widget.activity.activityId);
      final candidates = await ref
          .read(nutritionServiceProvider)
          .candidatePlans(widget.activity.startDate.toLocal());
      if (log.planKey?.isNotEmpty == true &&
          !candidates.any((p) => p.workout.key == log.planKey)) {
        final linked = await ref
            .read(nutritionServiceProvider)
            .savedPlan(log.planKey!);
        if (linked != null) candidates.add(linked);
      }
      if (!mounted) return;
      setState(() {
        entries = [...log.entries];
        noIntake = log.noIntake;
        gut = log.gut;
        note.text = log.note;
        elapsed.text = log.elapsedMinutes?.toString() ?? '';
        loaded = true;
        plans = candidates;
        planKey = log.planKey;
        loadError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loaded = true;
          loadError = '$e';
        });
      }
    }
  }

  @override
  void dispose() {
    note.dispose();
    elapsed.dispose();
    super.dispose();
  }

  Future<void> _entry([int? index]) async {
    final old = index == null ? null : entries[index];
    String value(String key, double? amount) =>
        old == null || old.unknown.contains(key) ? '' : '$amount';
    final values = await _fields(
      context,
      context.l10n.actualIntakePerServing,
      {
        'name': (context.l10n.productFoodName, old?.name ?? ''),
        'quantity': (context.l10n.servingsQuantity, '${old?.quantity ?? 1}'),
        'phase': (context.l10n.when, old?.phase ?? 'during'),
        'minute': (
          context.l10n.minuteIntoWorkoutDuringOnly,
          old?.minute?.toString() ?? '',
        ),
        'carbs': (
          context.l10n.carbohydrateGServing,
          value('carbs', old?.carbs),
        ),
        'fluid': (context.l10n.fluidMlServing, value('fluid', old?.fluid)),
        'sodium': (
          context.l10n.sodiumMgServingNotSalt,
          value('sodium', old?.sodium),
        ),
        'caffeine': (
          context.l10n.caffeineMgServing,
          value('caffeine', old?.caffeine),
        ),
        'protein': (
          context.l10n.proteinGServing,
          value('protein', old?.protein),
        ),
      },
      optional: {'minute', ..._nutrients},
      presets: {
        for (final p in [
          (context.l10n.gel, '25', '0', '0'),
          (context.l10n.water, '0', '500', '0'),
          (context.l10n.sportsDrink, '30', '500', '250'),
          (context.l10n.bar, '30', '0', '0'),
        ])
          p.$1: {
            'name': '${p.$1} (edit label values)',
            'carbs': p.$2,
            'fluid': p.$3,
            'sodium': p.$4,
            'caffeine': '0',
            'protein': '0',
          },
      },
    );
    if (values == null || !mounted) return;
    final entry = NutritionEntry(
      name: values['name']!.trim(),
      quantity: parseDecimal(values['quantity'])!,
      phase: values['phase']!,
      minute: values['phase'] == 'during'
          ? parseDecimal(values['minute'])
          : null,
      carbs: parseDecimal(values['carbs']) ?? 0,
      fluid: parseDecimal(values['fluid']) ?? 0,
      sodium: parseDecimal(values['sodium']) ?? 0,
      caffeine: parseDecimal(values['caffeine']) ?? 0,
      protein: parseDecimal(values['protein']) ?? 0,
      unknown: [
        for (final key in _nutrients)
          if (values[key]!.trim().isEmpty) key,
      ],
    );
    setState(() {
      if (index == null) {
        entries.add(entry);
      } else {
        entries[index] = entry;
      }
      noIntake = false;
    });
  }

  Future<void> _save(String status) async {
    setState(() => busy = true);
    await runUiAction(context, () async {
      await ref
          .read(nutritionServiceProvider)
          .saveLog(
            widget.activity.activityId,
            NutritionLog(
              entries: entries,
              status: status,
              planKey: planKey,
              noIntake: noIntake,
              gut: gut,
              note: note.text.trim(),
              elapsedMinutes: elapsed.text.trim().isEmpty
                  ? null
                  : parseDecimal(elapsed.text) ?? double.nan,
            ),
          );
      ref.invalidate(nutritionLogProvider(widget.activity.activityId));
      ref.invalidate(nutritionLinkedPlanProvider(widget.activity.activityId));
      await ref.read(nutritionReminderProvider).reconcile();
      if (mounted) Navigator.pop(context);
    });
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => SheetPage(
    title: context.l10n.actualNutrition,
    child: loadError != null
        ? DataError(loadError!, retry: _load)
        : !loaded
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.activity.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(context.l10n.recordWhatYouActuallyHad),
              TextField(
                controller: elapsed,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.elapsedMinutesIncludingStopsOptional,
                  hintText: context.l10n.recordedDurationActivityMin(
                    _v(nutritionElapsedSeconds(widget.activity) / 60),
                  ),
                ),
              ),
              if (plans.isNotEmpty || planKey?.isNotEmpty == true)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: planKey,
                  decoration: InputDecoration(
                    labelText: context.l10n.compareWithSavedStrategy,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        context.l10n.useMatchedSessionIfAvailable,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: '',
                      child: Text(context.l10n.noPlanComparison),
                    ),
                    for (final p in plans)
                      DropdownMenuItem(
                        value: p.workout.key,
                        child: Text(
                          context.l10n.titleDate(
                            p.workout.title,
                            dayText(p.workout.date),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (planKey?.isNotEmpty == true &&
                        !plans.any((p) => p.workout.key == planKey))
                      DropdownMenuItem(
                        value: planKey,
                        child: Text(context.l10n.linkedStrategyUnavailable),
                      ),
                  ],
                  onChanged: (key) => planKey = key,
                ),
              for (final e in entries.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.quantityName(e.$2.quantity, e.$2.name),
                  ),
                  subtitle: Text(
                    '${e.$2.phase}${e.$2.minute == null ? '' : ' · minute ${_v(e.$2.minute)}'}',
                  ),
                  onTap: busy ? null : () => _entry(e.$1),
                  trailing: IconButton(
                    tooltip: context.l10n.removeIntake,
                    onPressed: busy
                        ? null
                        : () => setState(() => entries.removeAt(e.$1)),
                    icon: const Icon(Icons.close),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => _entry(),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.addFoodOrDrink),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.iHadNoIntake),
                value: noIntake,
                onChanged: busy || entries.isNotEmpty
                    ? null
                    : (value) => setState(() => noIntake = value!),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: gut,
                decoration: InputDecoration(
                  labelText: context.l10n.giGutComfort,
                ),
                items: [
                  for (final value in [
                    'Not recorded',
                    'Comfortable',
                    'Mild symptoms',
                    'Moderate symptoms',
                    'Severe symptoms',
                  ])
                    DropdownMenuItem(
                      value: value,
                      child: Text(_choiceLabel(context, value)),
                    ),
                ],
                onChanged: (value) => gut = value!,
              ),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.whatWorkedSymptomsAccessProblems,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : () => _save('complete'),
                child: Text(
                  busy ? context.l10n.saving : context.l10n.finishIntakeLog,
                ),
              ),
              TextButton(
                onPressed: busy ? null : () => _save('draft'),
                child: Text(context.l10n.saveDraft),
              ),
              TextButton(
                onPressed: busy ? null : () => _save('declined'),
                child: Text(context.l10n.skipLoggingThisActivity),
              ),
            ],
          ),
  );
}

class NutritionPreferencesTile extends ConsumerWidget {
  const NutritionPreferencesTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs =
        ref.watch(nutritionPreferencesProvider).valueOrNull ??
        const NutritionPreferences();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(context.l10n.nutritionAndFluids, color: Colors.orange),
        TextButton(
          onPressed: () async {
            final values = await _fields(
              context,
              context.l10n.personalNutritionSettings,
              {
                'trainedCarbs': (
                  context.l10n.practisedCarbohydrateToleranceGH,
                  '${prefs.trainedCarbs}',
                ),
                'gelCarbs': (
                  'Your gel carbohydrate g / serving',
                  '${prefs.gelCarbs}',
                ),
                'bottleMl': ('Bottle / flask size ml', '${prefs.bottleMl}'),
                'drinkCarbs': (
                  'Drink carbohydrate g / full bottle (0 for water)',
                  '${prefs.drinkCarbs}',
                ),
                'sweatMl': (
                  'Measured sweat ml/h in comparable conditions',
                  prefs.sweatMl?.toString() ?? '',
                ),
                'sweatSodium': (
                  'Measured sweat sodium mg/L',
                  prefs.sweatSodium?.toString() ?? '',
                ),
              },
              optional: {'sweatMl', 'sweatSodium'},
            );
            if (values == null || !context.mounted) return;
            await runUiAction(context, () async {
              await ref
                  .read(nutritionServiceProvider)
                  .savePreferences(
                    NutritionPreferences(
                      trainedCarbs: parseDecimal(values['trainedCarbs'])!,
                      gelCarbs: parseDecimal(values['gelCarbs'])!,
                      bottleMl: parseDecimal(values['bottleMl'])!,
                      drinkCarbs: parseDecimal(values['drinkCarbs'])!,
                      sweatMl: parseDecimal(values['sweatMl']),
                      sweatSodium: parseDecimal(values['sweatSodium']),
                      reminders: prefs.reminders,
                    ),
                  );
              ref.invalidate(nutritionPreferencesProvider);
            });
          },
          child: Text(context.l10n.productsToleranceAndMeasuredSweat),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.postWorkoutIntakeReminder),
          subtitle: Text(context.l10n.onceAfterARecentEndurance),
          value: prefs.reminders,
          onChanged: (on) => runUiAction(context, () async {
            await ref
                .read(nutritionServiceProvider)
                .savePreferences(
                  NutritionPreferences.fromJson({
                    ...prefs.toJson(),
                    'reminders': on,
                  }),
                );
            ref.invalidate(nutritionPreferencesProvider);
            if (on) {
              await ref
                  .read(localNotificationGatewayProvider)
                  .requestPermission();
            }
            await ref.read(nutritionReminderProvider).reconcile();
          }),
        ),
        if (prefs.reminders)
          TextButton(
            onPressed: () => runUiAction(context, () async {
              final permission = await ref
                  .read(localNotificationGatewayProvider)
                  .requestPermission();
              await ref.read(nutritionReminderProvider).reconcile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      permission.allowed
                          ? context.l10n.workoutNotificationsEnabled
                          : context.l10n.allowNotificationsInSystemSettings,
                    ),
                  ),
                );
              }
            }),
            child: Text(context.l10n.enableWorkoutNotifications),
          ),
      ],
    );
  }
}

/// Dropdown values are stored as given; this is what the user reads.
String _choiceLabel(BuildContext context, String value) => switch (value) {
  'Unknown' => context.l10n.unknown,
  'Indoor' => context.l10n.indoor,
  'Road' => context.l10n.road,
  'Trail' => context.l10n.trail,
  'Technical' => context.l10n.technical,
  'Snow' => context.l10n.snow,
  'Pool' => context.l10n.pool,
  'Open water' => context.l10n.openWater,
  'Not recorded' => context.l10n.notRecorded,
  'Comfortable' => context.l10n.comfortable,
  'Mild symptoms' => context.l10n.mildSymptoms,
  'Moderate symptoms' => context.l10n.moderateSymptoms,
  'Severe symptoms' => context.l10n.severeSymptoms,
  'before' => context.l10n.before,
  'during' => context.l10n.during,
  'after' => context.l10n.after,
  _ => value,
};
