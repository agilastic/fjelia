/// A drink mixed at home: powders by the spoon, juice or cola, topped up with
/// water to the bottle size. Values are typical label and kitchen values; a
/// spoon is a household spoon, not a measuring spoon.
library;

enum MixIngredient {
  maltodextrin,
  sugar,
  dextrose,
  honey,
  salt,
  orangeJuice,
  appleJuice,
  cola,
}

enum MixUnit { grams, ml, tspLevel, tspHeaped, tbspLevel, tbspHeaped, pinch }

/// What one ingredient brings, per gram (powders, honey, salt) or per ml
/// (juice, cola).
class IngredientFacts {
  const IngredientFacts({
    required this.units,
    this.carbs = 0,
    this.glucoseShare = 0,
    this.sodium = 0,
    this.caffeine = 0,
    this.liquid = false,
    this.spoonGrams = const {},
  });

  /// The units offered, the first is the default.
  final List<MixUnit> units;

  /// Carbohydrate per gram or ml.
  final double carbs;

  /// Share of the carbohydrate that ends up as glucose; the rest is fructose.
  /// Sucrose counts half and half, maltodextrin as glucose.
  final double glucoseShare;

  /// Sodium in mg and caffeine in mg, per gram or ml.
  final double sodium, caffeine;

  /// Counted in ml and part of the bottle's volume.
  final bool liquid;

  /// Grams per spoon or pinch.
  final Map<MixUnit, double> spoonGrams;
}

const _powderUnits = [
  MixUnit.tbspLevel,
  MixUnit.tbspHeaped,
  MixUnit.tspLevel,
  MixUnit.tspHeaped,
  MixUnit.grams,
];

const mixFacts = <MixIngredient, IngredientFacts>{
  MixIngredient.maltodextrin: IngredientFacts(
    units: _powderUnits,
    carbs: .95,
    glucoseShare: 1,
    spoonGrams: {
      MixUnit.tspLevel: 3,
      MixUnit.tspHeaped: 5,
      MixUnit.tbspLevel: 8,
      MixUnit.tbspHeaped: 13,
    },
  ),
  MixIngredient.sugar: IngredientFacts(
    units: _powderUnits,
    carbs: 1,
    glucoseShare: .5,
    spoonGrams: {
      MixUnit.tspLevel: 4,
      MixUnit.tspHeaped: 6,
      MixUnit.tbspLevel: 12,
      MixUnit.tbspHeaped: 18,
    },
  ),
  // Dextrose monohydrate: about a tenth of it is water.
  MixIngredient.dextrose: IngredientFacts(
    units: _powderUnits,
    carbs: .91,
    glucoseShare: 1,
    spoonGrams: {
      MixUnit.tspLevel: 3,
      MixUnit.tspHeaped: 5,
      MixUnit.tbspLevel: 10,
      MixUnit.tbspHeaped: 15,
    },
  ),
  // Honey is about 31 % glucose and 38 % fructose; a spoon of it is never
  // heaped.
  MixIngredient.honey: IngredientFacts(
    units: [MixUnit.tbspLevel, MixUnit.tspLevel, MixUnit.grams],
    carbs: .82,
    glucoseShare: .45,
    spoonGrams: {MixUnit.tspLevel: 7, MixUnit.tbspLevel: 21},
  ),
  // Sodium is 39.3 % of table salt.
  MixIngredient.salt: IngredientFacts(
    units: [MixUnit.pinch, MixUnit.tspLevel, MixUnit.grams],
    sodium: 393,
    spoonGrams: {MixUnit.pinch: .5, MixUnit.tspLevel: 6},
  ),
  // Sucrose, glucose and fructose in about equal parts.
  MixIngredient.orangeJuice: IngredientFacts(
    units: [MixUnit.ml],
    carbs: .09,
    glucoseShare: .5,
    liquid: true,
  ),
  // Apple juice is fructose-heavy, about one part glucose to two fructose.
  MixIngredient.appleJuice: IngredientFacts(
    units: [MixUnit.ml],
    carbs: .105,
    glucoseShare: .35,
    liquid: true,
  ),
  // Cola with sugar as sold in Europe: 10.6 g sugar and 10 mg caffeine per
  // 100 ml.
  MixIngredient.cola: IngredientFacts(
    units: [MixUnit.ml],
    carbs: .106,
    glucoseShare: .5,
    caffeine: .1,
    liquid: true,
  ),
};

/// How far one tap on + or − moves an amount in this unit.
double mixStep(MixIngredient ingredient, MixUnit unit) => switch (unit) {
  MixUnit.grams => ingredient == MixIngredient.salt ? .5 : 5,
  MixUnit.ml => 50,
  MixUnit.pinch => 1,
  _ => ingredient == MixIngredient.salt ? .25 : .5,
};

class MixItem {
  const MixItem(this.ingredient, this.amount, this.unit);
  final MixIngredient ingredient;
  final double amount;
  final MixUnit unit;

  IngredientFacts get facts => mixFacts[ingredient]!;

  /// Grams for a powder, ml for a liquid.
  double get quantity => switch (unit) {
    MixUnit.grams || MixUnit.ml => amount,
    _ => amount * (facts.spoonGrams[unit] ?? 0),
  };

  double get carbs => quantity * facts.carbs;
  double get glucose => carbs * facts.glucoseShare;
  double get fructose => carbs - glucose;
  double get sodium => quantity * facts.sodium;
  double get caffeine => quantity * facts.caffeine;

  MixItem copyWith({double? amount, MixUnit? unit}) =>
      MixItem(ingredient, amount ?? this.amount, unit ?? this.unit);

  Map<String, Object> toJson() => {
    'ingredient': ingredient.name,
    'amount': amount,
    'unit': unit.name,
  };

  static MixItem? fromJson(Map j) {
    final ingredient = MixIngredient.values
        .where((i) => i.name == j['ingredient'])
        .firstOrNull;
    final unit = MixUnit.values.where((u) => u.name == j['unit']).firstOrNull;
    final amount = j['amount'];
    if (ingredient == null || unit == null || amount is! num) return null;
    if (!mixFacts[ingredient]!.units.contains(unit)) return null;
    return MixItem(ingredient, amount.toDouble(), unit);
  }
}

enum MixStrength { none, gentle, strong, tooStrong }

class DrinkMix {
  const DrinkMix({required this.bottleMl, this.items = const []});
  final double bottleMl;
  final List<MixItem> items;

  double _sum(double Function(MixItem) f) =>
      items.fold(0, (total, item) => total + f(item));

  double get carbs => _sum((i) => i.carbs);
  double get glucose => _sum((i) => i.glucose);
  double get fructose => _sum((i) => i.fructose);
  double get sodium => _sum((i) => i.sodium);
  double get caffeine => _sum((i) => i.caffeine);
  double get liquidMl => _sum((i) => i.facts.liquid ? i.quantity : 0);

  /// Juice and cola already fill more than the bottle holds.
  bool get overfilled => liquidMl > bottleMl;

  /// Grams of carbohydrate per 100 ml.
  double get percent => bottleMl <= 0 ? 0 : carbs / bottleMl * 100;

  /// Glucose per part fructose; null without fructose.
  double? get ratio => fructose <= 0 ? null : glucose / fructose;

  /// Up to 8 % sits well in most stomachs; more needs a trained gut.
  MixStrength get strength => carbs <= 0
      ? MixStrength.none
      : percent <= 8
      ? MixStrength.gentle
      : percent <= 12
      ? MixStrength.strong
      : MixStrength.tooStrong;

  DrinkMix copyWith({double? bottleMl, List<MixItem>? items}) =>
      DrinkMix(bottleMl: bottleMl ?? this.bottleMl, items: items ?? this.items);

  Map<String, Object> toJson() => {
    'bottleMl': bottleMl,
    'items': [for (final i in items) i.toJson()],
  };

  static DrinkMix fromJson(Map j, {double bottleMl = 500}) {
    final ml = j['bottleMl'];
    final items = j['items'];
    return DrinkMix(
      bottleMl: ml is num && ml > 0 ? ml.toDouble() : bottleMl,
      items: [
        if (items is List)
          for (final raw in items.whereType<Map>()) ?MixItem.fromJson(raw),
      ],
    );
  }
}

enum MixRecipe { maltoSugar, juice, juicePlus, cola }

/// The ready mixes, for a bottle of [bottleMl].
DrinkMix mixRecipe(MixRecipe recipe, {double bottleMl = 500}) {
  final half = bottleMl / 2;
  final scale = bottleMl / 500;
  double spoons(double n) => (n * scale * 2).round() / 2;
  return DrinkMix(
    bottleMl: bottleMl,
    items: switch (recipe) {
      MixRecipe.maltoSugar => [
        MixItem(MixIngredient.maltodextrin, spoons(2), MixUnit.tbspLevel),
        MixItem(MixIngredient.sugar, spoons(2), MixUnit.tbspLevel),
        MixItem(MixIngredient.salt, spoons(1), MixUnit.pinch),
      ],
      MixRecipe.juice => [
        MixItem(MixIngredient.orangeJuice, half, MixUnit.ml),
        MixItem(MixIngredient.salt, spoons(1), MixUnit.pinch),
      ],
      MixRecipe.juicePlus => [
        MixItem(MixIngredient.orangeJuice, half, MixUnit.ml),
        MixItem(MixIngredient.maltodextrin, spoons(2), MixUnit.tbspLevel),
        MixItem(MixIngredient.salt, spoons(1), MixUnit.pinch),
      ],
      MixRecipe.cola => [MixItem(MixIngredient.cola, half, MixUnit.ml)],
    },
  );
}
