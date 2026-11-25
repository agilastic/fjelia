import 'package:fjelia_core/models/workout_nutrition.dart';

import '../l10n/l10n_ext.dart';

export 'package:fjelia_core/models/workout_nutrition.dart';

/// The fuelling notes in the app language.
class AppNutritionTexts implements NutritionTexts {
  const AppNutritionTexts();

  @override
  String get duringRoutineGelsAreNot => tr.duringRoutineGelsAreNot;

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      tr.duringSpreadCarbohydrateAndDrinks;

  @override
  String get fluidIsAnEditableStarting => tr.fluidIsAnEditableStarting;

  @override
  String get afterHaveCarbohydrateAndA => tr.afterHaveCarbohydrateAndA;

  @override
  String get runningCarryAccessibleGelsFlasks =>
      tr.runningCarryAccessibleGelsFlasks;

  @override
  String get swimNoDuration => tr.swimNoDuration;

  @override
  String get swimOpenUnsupported => tr.swimOpenUnsupported;

  @override
  String get swimShort => tr.swimShort;

  @override
  String get swimOpenFeeds => tr.swimOpenFeeds;

  @override
  String get swimPoolLong => tr.swimPoolLong;

  @override
  String get swimFluidOpen => tr.swimFluidOpen;

  @override
  String get swimFluidPool => tr.swimFluidPool;

  @override
  String get swimBeforeAfter => tr.swimBeforeAfter;

  @override
  String get swimOpenFeedsUnknown => tr.swimOpenFeedsUnknown;
}

/// A fuelling strategy for [workout], with notes in the app language.
NutritionStrategy planNutrition(
  NutritionWorkout workout,
  NutritionPreferences prefs,
  NutritionConditions c, {
  double? carbs,
  double? fluid,
  double? sodium,
  DateTime? now,
}) => planNutritionWith(
  const AppNutritionTexts(),
  workout,
  prefs,
  c,
  carbs: carbs,
  fluid: fluid,
  sodium: sodium,
  now: now,
);
