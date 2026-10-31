import 'package:fjelia/models/drink_mix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('malto + sugar recipe is about 2:1, 39 g and gentle', () {
    final mix = mixRecipe(MixRecipe.maltoSugar);
    expect(mix.carbs, closeTo(39.2, .01));
    expect(mix.ratio, closeTo(2.27, .01));
    expect(mix.percent, closeTo(7.84, .01));
    expect(mix.strength, MixStrength.gentle);
    expect(mix.sodium, closeTo(196.5, .1));
  });

  test('cola brings caffeine and counts as liquid', () {
    final mix = mixRecipe(MixRecipe.cola);
    expect(mix.carbs, closeTo(26.5, .01));
    expect(mix.caffeine, closeTo(25, .01));
    expect(mix.liquidMl, 250);
    expect(mix.overfilled, isFalse);
  });

  test('glucose only has no ratio; apple juice leans to fructose', () {
    const malto = DrinkMix(
      bottleMl: 500,
      items: [MixItem(MixIngredient.maltodextrin, 40, MixUnit.grams)],
    );
    expect(malto.ratio, isNull);
    const apple = DrinkMix(
      bottleMl: 500,
      items: [MixItem(MixIngredient.appleJuice, 500, MixUnit.ml)],
    );
    expect(apple.ratio!, lessThan(1));
  });

  test('strength bands and overfilling', () {
    DrinkMix sugar(double g, {double ml = 500}) => DrinkMix(
      bottleMl: ml,
      items: [MixItem(MixIngredient.sugar, g, MixUnit.grams)],
    );
    expect(sugar(0).strength, MixStrength.none);
    expect(sugar(40).strength, MixStrength.gentle);
    expect(sugar(55).strength, MixStrength.strong);
    expect(sugar(70).strength, MixStrength.tooStrong);
    const juice = DrinkMix(
      bottleMl: 500,
      items: [MixItem(MixIngredient.orangeJuice, 600, MixUnit.ml)],
    );
    expect(juice.overfilled, isTrue);
  });

  test('a recipe scales with the bottle', () {
    final big = mixRecipe(MixRecipe.maltoSugar, bottleMl: 750);
    expect(big.items.first.amount, 3);
    expect(big.percent, closeTo(7.84, .01));
  });

  test('round-trips through JSON and drops unknown entries', () {
    final mix = mixRecipe(MixRecipe.juicePlus, bottleMl: 600);
    final back = DrinkMix.fromJson(mix.toJson());
    expect(back.bottleMl, 600);
    expect(back.carbs, closeTo(mix.carbs, 1e-9));
    final broken = DrinkMix.fromJson({
      'bottleMl': 500,
      'items': [
        {'ingredient': 'unicorn', 'amount': 1, 'unit': 'grams'},
        {'ingredient': 'cola', 'amount': 1, 'unit': 'tbspHeaped'},
      ],
    });
    expect(broken.items, isEmpty);
  });
}
