import '../l10n/l10n_ext.dart';

import 'dart:convert';

import '../db/database.dart';
import '../models/workout_nutrition.dart';
import '../models/heart_rate.dart';

/// Recorded timestamps can include pauses omitted from the imported timer.
int nutritionElapsedSeconds(ActivityRecord activity) {
  var seconds = activity.durationSeconds;
  try {
    final samples = jsonDecode(activity.metricsJson ?? '[]');
    if (samples is List) {
      for (final sample in samples.whereType<Map>()) {
        final time = heartRateTimestamp(
          sample['t'] ?? sample['timestamp'] ?? sample['time'],
        );
        if (time != null) {
          final elapsed = time.difference(activity.startDate).inSeconds;
          if (elapsed > seconds && elapsed < 7 * 24 * 3600) seconds = elapsed;
        }
      }
    }
  } catch (_) {
    /* Imported duration remains available. */
  }
  return seconds;
}

class NutritionService {
  NutritionService(this.db);
  final AppDatabase db;
  Future<ActivityRecord?> activity(String id) => (db.select(
    db.activityRecords,
  )..where((t) => t.activityId.equals(id))).getSingleOrNull();
  Future<Map<String, dynamic>?> read(String key) async {
    final row = await (db.select(
      db.nutritionRecords,
    )..where((t) => t.recordKey.equals(key))).getSingleOrNull();
    return row == null
        ? null
        : jsonDecode(row.dataJson) as Map<String, dynamic>;
  }

  Future<void> write(String key, String kind, Map<String, dynamic> data) => db
      .into(db.nutritionRecords)
      .insertOnConflictUpdate(
        NutritionRecordsCompanion.insert(
          recordKey: key,
          kind: kind,
          dataJson: jsonEncode(data),
          updatedAt: DateTime.now(),
        ),
      );
  Future<NutritionPreferences> preferences() async =>
      NutritionPreferences.fromJson(await read('nutrition:preferences') ?? {});
  Future<void> savePreferences(NutritionPreferences p) async {
    for (final value in [p.trainedCarbs, p.gelCarbs, p.bottleMl]) {
      if (!value.isFinite || value <= 0) {
        throw ArgumentError(tr.servingSizesAndToleranceMust);
      }
    }
    if (p.trainedCarbs > 120) {
      throw ArgumentError(tr.practisedCarbohydrateToleranceMustNot);
    }
    for (final value in [
      p.drinkCarbs,
      p.sweatMl,
      p.sweatSodium,
    ].whereType<double>()) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError(tr.enterFiniteNonNegativeMeasurements);
      }
    }
    if (p.sweatMl == 0) {
      throw ArgumentError(tr.measuredSweatRateMustBe);
    }
    await write('nutrition:preferences', 'preferences', p.toJson());
  }

  Future<NutritionStrategy?> savedPlan(String key) async {
    final j = await read(key);
    return j == null ? null : NutritionStrategy.fromJson(j);
  }

  Future<void> savePlan(NutritionStrategy plan) async {
    for (final value in [
      plan.carbs,
      plan.fluid,
      plan.sodium,
      plan.workout.minutes,
    ]) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError(tr.targetsMustBeFiniteAnd);
      }
    }
    if (plan.carbs > plan.preferences.trainedCarbs || plan.carbs > 120) {
      throw ArgumentError(tr.increasePractisedToleranceInNutrition);
    }
    if (plan.preferences.sweatMl != null &&
        plan.fluid > plan.preferences.sweatMl!) {
      throw ArgumentError(tr.fluidTargetExceedsYourMeasured);
    }
    for (final value in [
      plan.conditions.temperature,
      plan.conditions.humidity,
      plan.conditions.wind,
      plan.conditions.uv,
      plan.conditions.ascent,
      plan.conditions.altitude,
    ].whereType<double>()) {
      if (!value.isFinite) {
        throw ArgumentError(tr.conditionsMustBeFiniteOr);
      }
    }
    final humidity = plan.conditions.humidity;
    if (humidity != null && (humidity < 0 || humidity > 100)) {
      throw ArgumentError(tr.humidityMustBeBetween0);
    }
    await write(plan.workout.key, 'plan', plan.toJson());
  }

  Future<NutritionLog> log(String activityId) async =>
      NutritionLog.fromJson(await read('intake:$activityId') ?? {});

  Future<List<NutritionStrategy>> candidatePlans(DateTime date) async {
    final rows = await (db.select(
      db.nutritionRecords,
    )..where((t) => t.kind.equals('plan'))).get();
    final result = <NutritionStrategy>[];
    final day = DateTime.utc(date.year, date.month, date.day);
    for (final row in rows) {
      try {
        final plan = NutritionStrategy.fromJson(
          jsonDecode(row.dataJson) as Map,
        );
        final d = plan.workout.date;
        if (DateTime.utc(d.year, d.month, d.day).difference(day).inDays.abs() <=
            1) {
          result.add(plan);
        }
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return result..sort((a, b) => a.workout.date.compareTo(b.workout.date));
  }

  Future<void> saveLog(String activityId, NutritionLog log) async {
    if (log.elapsedMinutes != null &&
        (!log.elapsedMinutes!.isFinite || log.elapsedMinutes! <= 0)) {
      throw ArgumentError(tr.elapsedWorkoutTimeMustBe);
    }
    if (!['draft', 'complete', 'declined'].contains(log.status)) {
      throw ArgumentError('Unknown log state.');
    }
    if (log.noIntake && log.entries.isNotEmpty) {
      throw ArgumentError(tr.noIntakeCannotIncludeFood);
    }
    if (log.status == 'complete' && log.entries.isEmpty && !log.noIntake) {
      throw ArgumentError(tr.addAnItemOrConfirm);
    }
    for (final entry in log.entries) {
      if (entry.unknown.any(
        (key) =>
            !['carbs', 'fluid', 'sodium', 'caffeine', 'protein'].contains(key),
      )) {
        throw ArgumentError('Unknown nutrient field.');
      }
      if (entry.name.trim().isEmpty ||
          !['before', 'during', 'after'].contains(entry.phase)) {
        throw ArgumentError(tr.eachIntakeNeedsAProduct);
      }
      for (final value in [
        entry.quantity,
        entry.carbs,
        entry.fluid,
        entry.sodium,
        entry.caffeine,
        entry.protein,
        entry.minute,
      ].whereType<double>()) {
        if (!value.isFinite || value < 0) {
          throw ArgumentError(tr.intakeAmountsMustBeFinite);
        }
      }
      if (entry.quantity <= 0) {
        throw ArgumentError(tr.quantityMustBePositive);
      }
    }
    final activity = await (db.select(
      db.activityRecords,
    )..where((t) => t.activityId.equals(activityId))).getSingleOrNull();
    if (activity == null) throw StateError(tr.thisActivityNoLongerExists);
    final explicit = log.planKey;
    if (explicit != null &&
        explicit.isNotEmpty &&
        await savedPlan(explicit) == null) {
      throw ArgumentError(tr.selectedStrategyUnavailableChooseAnother);
    }
    final matched = explicit == null ? await _matchedPlan(activityId) : null;
    await write('intake:$activityId', 'intake', {
      ...log.toJson(),
      'planKey': explicit ?? matched?.workout.key,
    });
  }

  Future<NutritionStrategy?> planForActivity(String activityId) async {
    final manual = (await log(activityId)).planKey;
    if (manual != null) return manual.isEmpty ? null : savedPlan(manual);
    return _matchedPlan(activityId);
  }

  Future<NutritionStrategy?> _matchedPlan(String activityId) async {
    final linked = await (db.select(
      db.sessionActuals,
    )..where((t) => t.activityId.equals(activityId))).getSingleOrNull();
    return linked == null ? null : savedPlan('plan:${linked.sessionId}');
  }
}
