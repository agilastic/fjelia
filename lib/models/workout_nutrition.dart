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
  });
  final double? temperature, humidity, wind, uv, ascent, altitude;
  final String surface;
  final bool forecast;
  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
    'wind': wind,
    'uv': uv,
    'ascent': ascent,
    'altitude': altitude,
    'surface': surface,
    'forecast': forecast,
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
  int get gels =>
      (math.max(0, totalCarbs - drinkCarbs) / preferences.gelCarbs).ceil();
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
  final low = math.min(baseLow, prefs.trainedCarbs);
  final high = math.min(baseHigh, prefs.trainedCarbs);
  final sport = workout.sport.toLowerCase();
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
  final fluidTarget =
      fluid ??
      (prefs.sweatMl != null
          ? prefs.sweatMl! * .8
          : hot
          ? 700.0
          : 500.0);
  final carbTarget = carbs ?? (low + high) / 2;
  final notes = <String>[
    'Before: start fuelled and hydrated. Choose a familiar carbohydrate-rich meal; allow time to digest.',
    carbTarget == 0
        ? 'During: routine gels are not needed for this short/easy session. Drink to thirst.'
        : 'During: spread carbohydrate and drinks over small, regular feeds. Count drink carbohydrate in the same total as gels and food.',
    'Fluid is an editable starting estimate, not a quota. Use thirst, practised intake and measured sweat losses; do not force extra water.',
    'After: have carbohydrate and a protein-containing meal. Prioritise refuelling and rehydration when another session is soon.',
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
  if (swimming) {
    notes.add(
      sport.contains('open') || c.surface == 'Open water'
          ? 'Open water: arrange supported feeds and safe stops; plan the longest gap between feeds. Air forecasts do not measure water temperature; personalise fluids using your swimming experience. Do not attempt to eat while swimming.'
          : 'Swimming: place a labelled bottle on the pool deck and use set breaks for sips or feeds. Pool conditions may differ from outdoor weather.',
    );
  } else if (sport.contains('ski') || sport.contains('nordic')) {
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
          : 'Running: carry accessible gels/flasks or plan aid-station feeds; practise the same products and timing before racing.',
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
