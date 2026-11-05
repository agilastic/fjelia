import '../l10n/l10n_ext.dart';

import 'dart:math' as math;

import 'package:equatable/equatable.dart';

double number(Map j, String key, [double fallback = 0]) =>
    (j[key] as num?)?.toDouble() ?? fallback;

class NutritionWorkout extends Equatable {
  const NutritionWorkout({
    required this.key,
    required this.title,
    required this.sport,
    required this.date,
    required this.minutes,
    this.zone,
    this.indoor = false,
  });
  final String key, title, sport;
  final DateTime date;
  final double minutes;
  final int? zone;
  final bool indoor;
  @override
  List<Object?> get props => [key, title, sport, date, minutes, zone, indoor];
  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'sport': sport,
    'date': date.toIso8601String(),
    'minutes': minutes,
    'zone': zone,
    'indoor': indoor,
  };
  factory NutritionWorkout.fromJson(Map j) => NutritionWorkout(
    key: j['key'] as String,
    title: j['title'] as String,
    sport: j['sport'] as String,
    date: DateTime.parse(j['date'] as String),
    minutes: number(j, 'minutes'),
    zone: j['zone'] as int?,
    indoor: j['indoor'] == true,
  );
}

/// A gel from a maker's label, as a starting point the athlete checks.
/// Sodium is null where it was not confirmed; flavours with caffeine exist,
/// so caffeine is left to the label.
class GelProduct {
  const GelProduct(this.name, this.carbs, {this.sodium});
  final String name;
  final double carbs;
  final double? sodium;
}

/// Common gels, per sachet (labels checked 2026-10-31).
const commonGels = [
  GelProduct('Maurten Gel 100', 25, sodium: 20),
  GelProduct('PowerBar PowerGel', 26, sodium: 205),
  GelProduct('PowerBar PowerGel Hydro', 26, sodium: 205),
  GelProduct('SiS Beta Fuel', 40),
  GelProduct('Maurten Gel 160', 40, sodium: 30),
];

class NutritionPreferences {
  const NutritionPreferences({
    this.trainedCarbs = 60,
    this.gelCarbs = 25,
    this.bottleMl = 500,
    this.drinkCarbs = 0,
    this.sweatMl,
    this.sweatSodium,
    this.reminders = true,
  });
  final double trainedCarbs, gelCarbs, bottleMl, drinkCarbs;
  final double? sweatMl, sweatSodium;
  final bool reminders;
  Map<String, dynamic> toJson() => {
    'trainedCarbs': trainedCarbs,
    'gelCarbs': gelCarbs,
    'bottleMl': bottleMl,
    'drinkCarbs': drinkCarbs,
    'sweatMl': sweatMl,
    'sweatSodium': sweatSodium,
    'reminders': reminders,
  };
  factory NutritionPreferences.fromJson(Map j) => NutritionPreferences(
    trainedCarbs: number(j, 'trainedCarbs', 60),
    gelCarbs: number(j, 'gelCarbs', 25),
    bottleMl: number(j, 'bottleMl', 500),
    drinkCarbs: number(j, 'drinkCarbs'),
    sweatMl: (j['sweatMl'] as num?)?.toDouble(),
    sweatSodium: (j['sweatSodium'] as num?)?.toDouble(),
    reminders: j['reminders'] != false,
  );
}

class NutritionConditions {
  const NutritionConditions({
    this.temperature,
    this.humidity,
    this.wind,
    this.uv,
    this.ascent,
    this.altitude,
    this.surface = 'Unknown',
    this.forecast = false,
    this.feeds = 'Unknown',
  });
  final double? temperature, humidity, wind, uv, ascent, altitude;
  final String surface;
  final bool forecast;

  /// Open water: `Supported` (boat, kayak or shore feeds), `Unsupported` or
  /// `Unknown`.
  final String feeds;
  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
    'wind': wind,
    'uv': uv,
    'ascent': ascent,
    'altitude': altitude,
    'surface': surface,
    'forecast': forecast,
    'feeds': feeds,
  };
  factory NutritionConditions.fromJson(Map j) => NutritionConditions(
    temperature: (j['temperature'] as num?)?.toDouble(),
    humidity: (j['humidity'] as num?)?.toDouble(),
    wind: (j['wind'] as num?)?.toDouble(),
    uv: (j['uv'] as num?)?.toDouble(),
    ascent: (j['ascent'] as num?)?.toDouble(),
    altitude: (j['altitude'] as num?)?.toDouble(),
    surface: j['surface'] as String? ?? 'Unknown',
    forecast: j['forecast'] == true,
    feeds: j['feeds'] as String? ?? 'Unknown',
  );
}

class NutritionStrategy {
  const NutritionStrategy({
    required this.workout,
    required this.preferences,
    required this.conditions,
    required this.carbs,
    required this.fluid,
    required this.sodium,
    required this.carbLow,
    required this.carbHigh,
    required this.guidance,
    required this.savedAt,
  });
  final NutritionWorkout workout;
  final NutritionPreferences preferences;
  final NutritionConditions conditions;
  final double carbs, fluid, sodium, carbLow, carbHigh;
  final List<String> guidance;
  final DateTime savedAt;
  double get hours => workout.minutes / 60;
  double get totalCarbs => carbs * hours;
  double get totalFluid => fluid * hours;
  double get totalSodium => sodium * hours;
  double get drinkCarbs =>
      totalFluid / preferences.bottleMl * preferences.drinkCarbs;

  /// Whether gels are a practical way to take the carbohydrate during this
  /// workout. In the water they are not: a swim fuels from a drink at the
  /// pool edge or at feeds.
  bool get gelsPractical => swimDiscipline(workout, conditions) == null;
  int get gels => gelsPractical
      ? (math.max(0, totalCarbs - drinkCarbs) / preferences.gelCarbs).ceil()
      : 0;
  int get bottles => (totalFluid / preferences.bottleMl).ceil();
  Map<String, dynamic> toJson() => {
    'v': 1,
    'workout': workout.toJson(),
    'preferences': preferences.toJson(),
    'conditions': conditions.toJson(),
    'carbs': carbs,
    'fluid': fluid,
    'sodium': sodium,
    'carbLow': carbLow,
    'carbHigh': carbHigh,
    'guidance': guidance,
    'savedAt': savedAt.toIso8601String(),
  };
  factory NutritionStrategy.fromJson(Map j) => NutritionStrategy(
    workout: NutritionWorkout.fromJson(j['workout'] as Map),
    preferences: NutritionPreferences.fromJson(j['preferences'] as Map),
    conditions: NutritionConditions.fromJson(j['conditions'] as Map),
    carbs: number(j, 'carbs'),
    fluid: number(j, 'fluid'),
    sodium: number(j, 'sodium'),
    carbLow: number(j, 'carbLow'),
    carbHigh: number(j, 'carbHigh'),
    guidance: (j['guidance'] as List).cast<String>(),
    savedAt: DateTime.parse(j['savedAt'] as String),
  );
}

/// `pool` or `open` for a swim, null for any other sport.
String? swimDiscipline(NutritionWorkout workout, NutritionConditions c) {
  final sport = workout.sport.toLowerCase();
  if (!sport.contains('swim') &&
      c.surface != 'Pool' &&
      c.surface != 'Open water') {
    return null;
  }
  return sport.contains('open') || c.surface == 'Open water' ? 'open' : 'pool';
}

/// Carbohydrate during a swim, g/h, from the general range for its length:
/// none below 90 minutes, whatever the intensity, then the usual range,
/// taken as a drink at breaks or at feeds. An open-water swim without feeds
/// takes nothing during: it is fuelled before and after. (SwimCamp, swim
/// performance nutrition guide; Domínguez et al. 2017, J Exerc Nutrition
/// Biochem 21(4).)
(double, double) swimCarbRange(
  String discipline,
  double minutes,
  NutritionConditions c,
  (double, double) general,
) {
  if (minutes < 90) return (0, 0);
  if (discipline == 'open' && c.feeds == 'Unsupported') return (0, 0);
  return general;
}

NutritionStrategy planNutrition(
  NutritionWorkout workout,
  NutritionPreferences prefs,
  NutritionConditions c, {
  double? carbs,
  double? fluid,
  double? sodium,
  DateTime? now,
}) {
  final minutes = workout.minutes;
  final (baseLow, baseHigh) = minutes < 75
      ? ((workout.zone ?? 0) >= 4 && minutes >= 45 ? (15.0, 30.0) : (0.0, 0.0))
      : minutes <= 150
      ? (30.0, 60.0)
      : (60.0, 90.0);
  final sport = workout.sport.toLowerCase();
  final swim = swimDiscipline(workout, c);
  final (sportLow, sportHigh) = swim == null
      ? (baseLow, baseHigh)
      : swimCarbRange(swim, minutes, c, (baseLow, baseHigh));
  final low = math.min(sportLow, prefs.trainedCarbs);
  final high = math.min(sportHigh, prefs.trainedCarbs);
  final swimming = sport.contains('swim');
  final pool =
      c.surface == 'Pool' ||
      (swimming && !sport.contains('open') && c.surface != 'Open water');
  final hot =
      !workout.indoor &&
      !swimming &&
      !pool &&
      ((c.temperature ?? 0) >= 25 ||
          ((c.temperature ?? 0) >= 20 && (c.humidity ?? 0) >= 75));
  // Without a measured sweat rate: how much a runner or rider typically needs
  // at this temperature and effort. An easy 90 minutes at 10 °C needs about a
  // third of a litre, not two bottles; drinking to thirst covers the rest.
  double typicalFluid() {
    if (swimming || pool) return 500;
    final t = c.temperature;
    final base = hot
        ? 700.0
        : workout.indoor
        ? 500.0
        : t == null
        ? 400.0
        : t < 10
        ? 250.0
        : t < 15
        ? 300.0
        : t < 20
        ? 400.0
        : 500.0;
    // In heat even an easy pace sweats a lot: no reduction for effort there.
    final zone = workout.zone;
    final effort = zone == null || hot
        ? 1.0
        : zone <= 2
        ? .8
        : zone >= 4
        ? 1.15
        : 1.0;
    return (base * effort / 10).round() * 10.0;
  }

  final fluidTarget =
      fluid ?? (prefs.sweatMl != null ? prefs.sweatMl! * .8 : typicalFluid());
  final carbTarget = carbs ?? (low + high) / 2;
  if (swim != null) {
    return NutritionStrategy(
      workout: workout,
      preferences: prefs,
      conditions: c,
      carbs: carbTarget,
      fluid: fluidTarget,
      sodium:
          sodium ??
          (minutes < 90 ? 0 : fluidTarget / 1000 * (prefs.sweatSodium ?? 500)),
      carbLow: low,
      carbHigh: high,
      guidance: _swimNotes(swim, minutes, carbTarget, prefs, c),
      savedAt: now ?? DateTime.now(),
    );
  }
  final notes = <String>[
    'Before: start fuelled and hydrated. Choose a familiar carbohydrate-rich meal; allow time to digest.',
    carbTarget == 0
        ? tr.duringRoutineGelsAreNot
        : tr.duringSpreadCarbohydrateAndDrinks,
    tr.fluidIsAnEditableStarting,
    tr.afterHaveCarbohydrateAndA,
    if (carbTarget > 60) 'Use a practised glucose/fructose combination. Build gut tolerance in training before race day.',
    if (prefs.sweatMl == null) 'Sweat rate is unknown; personalise with a measured session. Weather alone cannot determine sweat or sodium losses.',
    if (!workout.indoor && !pool && c.temperature == null) 'Weather for this workout is unavailable. Review fluids when conditions are known.',
    if (hot) 'Warm/humid conditions: arrange extra fluid access and cooling; review the estimate against your own sweat losses.',
    if (!workout.indoor && ((c.temperature ?? 20) < 5 || (c.wind ?? 0) >= 30)) 'Cold or wind can mask thirst. Keep drinks accessible and protect gels and bottles from freezing.',
    if (!workout.indoor && (c.uv ?? 0) >= 6)
      'Strong sun: plan shade, sun protection and cooling at feed stops.',
    if ((c.ascent ?? 0) >= 500 || c.surface == 'Technical') 'Climbing/technical terrain: plan by time on feet, not kilometres. Feed before difficult sections or stop somewhere safe.',
    if ((c.altitude ?? 0) >= 2000) 'At altitude, check appetite, access and tolerance. Do not replace food with a fixed altitude multiplier.',
  ];
  if (sport.contains('ski') || sport.contains('nordic')) {
    notes.add(
      'Skiing: use an insulated bottle/tube, keep gels warm and check access with gloves. Plan feed stops before long remote sections.',
    );
  } else if (sport.contains('mtb') || sport.contains('mountain')) {
    notes.add(
      'MTB: use accessible bottles or a hydration pack; eat on safe easy sections or when stopped, not on technical descents.',
    );
  } else if (sport.contains('cycl') || sport.contains('bik')) {
    notes.add(
      'Cycling: separate fuel mix from extra plain water where practical. Check bottle capacity and refill points before the ride.',
    );
  } else {
    notes.add(
      sport.contains('trail')
          ? 'Trail: map aid stations, carry supplies for the longest unsupported segment and keep one practised backup feed accessible.'
          : tr.runningCarryAccessibleGelsFlasks,
    );
  }
  return NutritionStrategy(
    workout: workout,
    preferences: prefs,
    conditions: c,
    carbs: carbTarget,
    fluid: fluidTarget,
    sodium:
        sodium ??
        (minutes < 60 ? 0 : fluidTarget / 1000 * (prefs.sweatSodium ?? 500)),
    carbLow: low,
    carbHigh: high,
    guidance: notes,
    savedAt: now ?? DateTime.now(),
  );
}

/// What a swim needs said, and no more: a short pool session gets two
/// lines, not a fuelling plan.
List<String> _swimNotes(
  String discipline,
  double minutes,
  double carbs,
  NutritionPreferences prefs,
  NutritionConditions c,
) {
  final open = discipline == 'open';
  final unsupported = open && c.feeds == 'Unsupported';
  return [
    if (minutes <= 0)
      tr.swimNoDuration
    else if (unsupported)
      tr.swimOpenUnsupported
    else if (carbs == 0)
      tr.swimShort
    else if (open)
      tr.swimOpenFeeds
    else
      tr.swimPoolLong,
    open ? tr.swimFluidOpen : tr.swimFluidPool,
    if (minutes >= 60 || open) tr.swimBeforeAfter,
    if (carbs > 60) 'Use a practised glucose/fructose combination. Build gut tolerance in training before race day.',
    if (open && (c.feeds == 'Unknown')) tr.swimOpenFeedsUnknown,
  ];
}

class NutritionEntry {
  const NutritionEntry({
    required this.name,
    this.quantity = 1,
    this.phase = 'during',
    this.minute,
    this.carbs = 0,
    this.fluid = 0,
    this.sodium = 0,
    this.caffeine = 0,
    this.protein = 0,
    this.unknown = const [],
  });
  final String name, phase;
  final double quantity, carbs, fluid, sodium, caffeine, protein;
  final double? minute;
  final List<String> unknown;
  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'phase': phase,
    'minute': minute,
    'carbs': carbs,
    'fluid': fluid,
    'sodium': sodium,
    'caffeine': caffeine,
    'protein': protein,
    'unknown': unknown,
  };
  factory NutritionEntry.fromJson(Map j) => NutritionEntry(
    name: j['name'] as String,
    quantity: number(j, 'quantity', 1),
    phase: j['phase'] as String? ?? 'during',
    minute: (j['minute'] as num?)?.toDouble(),
    carbs: number(j, 'carbs'),
    fluid: number(j, 'fluid'),
    sodium: number(j, 'sodium'),
    caffeine: number(j, 'caffeine'),
    protein: number(j, 'protein'),
    unknown: (j['unknown'] as List? ?? []).cast<String>(),
  );
}

class NutritionLog {
  const NutritionLog({
    this.entries = const [],
    this.status = 'draft',
    this.noIntake = false,
    this.gut = 'Not recorded',
    this.note = '',
    this.elapsedMinutes,
    this.planKey,
  });
  final List<NutritionEntry> entries;
  final String status, gut, note;
  final bool noIntake;
  final double? elapsedMinutes;
  final String? planKey;
  bool get finished => status == 'complete' || status == 'declined';
  double total(double Function(NutritionEntry) value, {bool during = false}) =>
      entries
          .where((e) => !during || e.phase == 'during')
          .fold(0.0, (sum, e) => sum + value(e) * e.quantity);
  Map<String, dynamic> toJson() => {
    'v': 1,
    'entries': entries.map((e) => e.toJson()).toList(),
    'status': status,
    'noIntake': noIntake,
    'gut': gut,
    'note': note,
    'elapsedMinutes': elapsedMinutes,
    'planKey': planKey,
  };
  factory NutritionLog.fromJson(Map j) => NutritionLog(
    entries: (j['entries'] as List? ?? [])
        .map((e) => NutritionEntry.fromJson(e as Map))
        .toList(),
    status: j['status'] as String? ?? 'draft',
    noIntake: j['noIntake'] == true,
    gut: j['gut'] as String? ?? 'Not recorded',
    note: j['note'] as String? ?? '',
    elapsedMinutes: (j['elapsedMinutes'] as num?)?.toDouble(),
    planKey: j['planKey'] as String?,
  );
}
