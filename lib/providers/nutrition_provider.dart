import 'dart:math' as math;
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_nutrition.dart';
import '../services/nutrition_service.dart';
import '../services/nutrition_reminder_service.dart';
import '../services/open_meteo_client.dart';
import 'database_provider.dart';
import 'heat_acclimation_provider.dart';
import 'hrv_reminder_provider.dart';

final nutritionServiceProvider = Provider(
  (ref) => NutritionService(ref.watch(databaseProvider)),
);
final nutritionReminderProvider = Provider(
  (ref) => NutritionReminderService(
    ref.watch(nutritionServiceProvider),
    ref.watch(localNotificationGatewayProvider),
  ),
);
final nutritionPreferencesProvider = FutureProvider<NutritionPreferences>(
  (ref) => ref.watch(nutritionServiceProvider).preferences(),
);
final nutritionLogProvider = FutureProvider.autoDispose
    .family<NutritionLog, String>(
      (ref, id) => ref.watch(nutritionServiceProvider).log(id),
    );
final nutritionLinkedPlanProvider = FutureProvider.autoDispose
    .family<NutritionStrategy?, String>(
      (ref, id) => ref.watch(nutritionServiceProvider).planForActivity(id),
    );
final nutritionPlanProvider = FutureProvider.autoDispose
    .family<NutritionStrategy, NutritionWorkout>((ref, workout) async {
      final service = ref.watch(nutritionServiceProvider);
      var disposed = false;
      ref.onDispose(() => disposed = true);
      final existing = await service.savedPlan(workout.key);
      if (existing != null) return existing;
      if (disposed) {
        return planNutrition(
          workout,
          const NutritionPreferences(),
          const NutritionConditions(),
        );
      }
      final prefs = await service.preferences();
      if (disposed) {
        return planNutrition(workout, prefs, const NutritionConditions());
      }
      final conditions = await ref.watch(
        nutritionConditionsProvider(workout).future,
      );
      final plan = planNutrition(workout, prefs, conditions);
      if (!disposed) {
        await service.savePlan(plan);
      }
      return plan;
    });
final nutritionSavedPlanProvider = FutureProvider.autoDispose
    .family<NutritionStrategy?, String>(
      (ref, key) => ref.watch(nutritionServiceProvider).savedPlan(key),
    );
final nutritionConditionsProvider = FutureProvider.autoDispose
    .family<NutritionConditions, NutritionWorkout>((ref, workout) async {
      if (workout.indoor) return const NutritionConditions(surface: 'Indoor');
      if (workout.sport.contains('swim') && !workout.sport.contains('open')) {
        return const NutritionConditions(surface: 'Pool');
      }
      try {
        ref.watch(heatHourlyWeatherProvider);
        final ready = Completer<OpenMeteoResult?>();
        final timer = Timer(const Duration(seconds: 4), () {
          if (!ready.isCompleted) ready.complete(null);
        });
        ref.onDispose(() {
          timer.cancel();
          if (!ready.isCompleted) ready.complete(null);
        });
        unawaited(
          ref
              .watch(heatHourlyWeatherProvider.future)
              .then<void>(
                (value) {
                  if (!ready.isCompleted) ready.complete(value);
                },
                onError: (Object _, StackTrace _) {
                  if (!ready.isCompleted) ready.complete(null);
                },
              ),
        );
        final result = await ready.future;
        timer.cancel();
        final points =
            result?.points
                .where(
                  (p) =>
                      p.time.year == workout.date.year &&
                      p.time.month == workout.date.month &&
                      p.time.day == workout.date.day,
                )
                .toList() ??
            [];
        if (points.isEmpty) return const NutritionConditions();
        final uv = points
            .map((p) => p.uvIndex)
            .whereType<num>()
            .map((v) => v.toDouble())
            .toList();
        return NutritionConditions(
          temperature: points.map((p) => p.temperatureC).reduce(math.max),
          humidity: points.map((p) => p.humidityPct).reduce(math.max),
          wind: points.map((p) => p.windSpeedKmh).reduce(math.max),
          uv: uv.isEmpty ? null : uv.reduce(math.max),
          forecast: true,
        );
      } catch (_) {
        return const NutritionConditions();
      }
    });
