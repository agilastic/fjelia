import '../theme/fjelia_style.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/formats.dart';
import '../l10n/l10n_ext.dart';
import '../models/drink_mix.dart';
import '../providers/nutrition_provider.dart';
import 'app_widgets.dart';

/// Where the mix goes: one logged drink, or the athlete's usual bottle.
enum DrinkMixPurpose { intake, bottle }

class DrinkMixResult {
  const DrinkMixResult(this.mix, this.name);
  final DrinkMix mix;
  final String name;
}

const _lastMixKey = 'nutrition:mix:last';
const _blue = Color(0xFF6EC1F0);
const _fructose = Color(0xFFFFA94D);
const _amber = Color(0xFFFFC857);
const _red = Color(0xFFFF6B6B);

/// Highest strength the gauge shows, in g per 100 ml.
const _gaugeMax = 15.0;

/// Opens the mixer. Returns the mix and its name, or null when closed.
Future<DrinkMixResult?> showDrinkMixSheet(
  BuildContext context, {
  required DrinkMixPurpose purpose,
  double bottleMl = 500,
}) => showAppSheet<DrinkMixResult>(
  context,
  DrinkMixSheet(purpose: purpose, bottleMl: bottleMl),
);

/// Builds a drink from spoons of powder, juice or cola, and shows what it
/// adds up to while it is put together.
class DrinkMixSheet extends ConsumerStatefulWidget {
  const DrinkMixSheet({super.key, required this.purpose, this.bottleMl = 500});
  final DrinkMixPurpose purpose;
  final double bottleMl;

  @override
  ConsumerState<DrinkMixSheet> createState() => _DrinkMixSheetState();
}

class _DrinkMixSheetState extends ConsumerState<DrinkMixSheet> {
  late DrinkMix mix = mixRecipe(
    MixRecipe.maltoSugar,
    bottleMl: widget.bottleMl,
  );

  /// The recipe while it is unchanged, so the entry keeps its name.
  MixRecipe? recipe = MixRecipe.maltoSugar;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  /// The last mix, so a usual drink is one tap away.
  Future<void> _restore() async {
    try {
      final saved = await ref.read(nutritionServiceProvider).read(_lastMixKey);
      if (saved == null || !mounted) return;
      final last = DrinkMix.fromJson(saved, bottleMl: widget.bottleMl);
      if (last.items.isEmpty) return;
      setState(() {
        mix = last;
        recipe = null;
      });
    } catch (_) {
      // A broken record only means starting from the recipe.
    }
  }

  void _change(DrinkMix next) => setState(() {
    mix = next;
    recipe = null;
  });

  void _setItem(int index, MixItem item) =>
      _change(mix.copyWith(items: [...mix.items]..[index] = item));

  Future<void> _done() async {
    final name = recipe == null
        ? context.l10n.mixDefaultName
        : _recipeName(context, recipe!);
    try {
      await ref
          .read(nutritionServiceProvider)
          .write(_lastMixKey, 'mix', mix.toJson());
    } catch (_) {
      // Remembering the mix is a convenience; the result still counts.
    }
    if (mounted) Navigator.pop(context, DrinkMixResult(mix, name));
  }

  @override
  Widget build(BuildContext context) => SheetPage(
    title: context.l10n.mixTitle,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _MixSummary(mix: mix),
              _heading(context.l10n.mixRecipes),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in MixRecipe.values)
                    ChoiceChip(
                      label: Text(_recipeName(context, r)),
                      selected: recipe == r,
                      onSelected: (_) => setState(() {
                        mix = mixRecipe(r, bottleMl: mix.bottleMl);
                        recipe = r;
                      }),
                    ),
                ],
              ),
              _heading(context.l10n.mixIngredients),
              _bottleRow(context),
              for (final (i, item) in mix.items.indexed)
                _IngredientRow(
                  key: ValueKey(item.ingredient),
                  item: item,
                  onChanged: (next) => _setItem(i, next),
                  onRemove: () =>
                      _change(mix.copyWith(items: [...mix.items]..removeAt(i))),
                ),
              if (mix.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    context.l10n.mixEmpty,
                    style: TextStyle(color: muted),
                  ),
                ),
              _addButton(context),
              ..._hints(context),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: mix.items.isEmpty ? null : _done,
                icon: Icon(
                  widget.purpose == DrinkMixPurpose.intake
                      ? Icons.add_rounded
                      : Icons.check_rounded,
                ),
                label: Text(
                  widget.purpose == DrinkMixPurpose.intake
                      ? context.l10n.mixAddToIntake
                      : context.l10n.mixUseAsBottle,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: muted,
      ),
    ),
  );

  Widget _bottleRow(BuildContext context) => _RowCard(
    icon: Icons.water_drop_rounded,
    color: _blue,
    title: context.l10n.mixBottle,
    subtitle: context.l10n.mixFilledWithWater,
    trailing: _Stepper(
      value: '${mix.bottleMl.round()} ml',
      onMinus: mix.bottleMl > 250
          ? () => _change(mix.copyWith(bottleMl: mix.bottleMl - 50))
          : null,
      onPlus: mix.bottleMl < 1500
          ? () => _change(mix.copyWith(bottleMl: mix.bottleMl + 50))
          : null,
    ),
  );

  Widget _addButton(BuildContext context) {
    final present = {for (final i in mix.items) i.ingredient};
    final missing = MixIngredient.values.where((i) => !present.contains(i));
    if (missing.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: PopupMenuButton<MixIngredient>(
        tooltip: context.l10n.mixAddIngredient,
        color: duo(0xFF242424, 0xFFEEF1F5),
        onSelected: (ingredient) {
          final facts = mixFacts[ingredient]!;
          final unit = facts.units.first;
          final amount = switch (unit) {
            MixUnit.ml => mix.bottleMl / 2,
            _ => 1.0,
          };
          _change(
            mix.copyWith(
              items: [...mix.items, MixItem(ingredient, amount, unit)],
            ),
          );
        },
        itemBuilder: (context) => [
          for (final i in missing)
            PopupMenuItem(
              value: i,
              child: Row(
                children: [
                  Icon(_icon(i), color: _color(i), size: 20),
                  const SizedBox(width: 12),
                  Text(_ingredientName(context, i)),
                ],
              ),
            ),
        ],
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _blue.withValues(alpha: .6)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: _blue),
              const SizedBox(width: 8),
              Text(
                context.l10n.mixAddIngredient,
                style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _hints(BuildContext context) {
    final ratio = mix.ratio;
    final usesSpoons = mix.items.any(
      (i) => i.unit != MixUnit.grams && i.unit != MixUnit.ml,
    );
    final hints = <(IconData, Color, String)>[
      if (mix.overfilled)
        (Icons.error_outline_rounded, _red, context.l10n.mixTooMuchLiquid),
      if (mix.carbs > 0 && ratio == null)
        (Icons.info_outline_rounded, _amber, context.l10n.mixNoFructoseHint),
      if (ratio != null && ratio < .8)
        (Icons.info_outline_rounded, _amber, context.l10n.mixFructoseHeavyHint),
      if (usesSpoons)
        (Icons.straighten_rounded, muted, context.l10n.mixSpoonNote),
    ];
    return [
      if (hints.isNotEmpty) const SizedBox(height: 16),
      for (final (icon, color, text) in hints)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: color == muted ? muted : fjInk70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

/// The numbers that matter, live: carbohydrate, glucose to fructose, and how
/// strong the bottle is against what a stomach tolerates.
class _MixSummary extends StatelessWidget {
  const _MixSummary({required this.mix});
  final DrinkMix mix;

  @override
  Widget build(BuildContext context) {
    final ratio = mix.ratio;
    final (verdictColor, verdict) = switch (mix.strength) {
      MixStrength.none => (muted, ''),
      MixStrength.gentle => (mint, context.l10n.mixGentle),
      MixStrength.strong => (_amber, context.l10n.mixStrong),
      MixStrength.tooStrong => (_red, context.l10n.mixTooStrong),
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: fjInk10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _blue.withValues(alpha: .22),
            duo(0xFF1A1A1A, 0xFFF7F8FA),
            verdictColor.withValues(alpha: .14),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: mix.carbs),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '${value.round()}',
                  style: const TextStyle(
                    fontSize: 46,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Wraps on a small phone or with large text.
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    'g ${context.l10n.carbsLabel}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fjInk70,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.mixPerBottle('${mix.bottleMl.round()}'),
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          _labelled(
            context.l10n.mixRatio,
            ratio == null
                ? (mix.carbs > 0 ? context.l10n.mixGlucoseOnly : '—')
                : '${ratio.fixed(1)} : 1',
          ),
          const SizedBox(height: 8),
          _RatioBar(glucose: mix.glucose, fructose: mix.fructose),
          const SizedBox(height: 6),
          Row(
            children: [
              _legend(mint, context.l10n.mixGlucose),
              const SizedBox(width: 14),
              _legend(_fructose, context.l10n.mixFructose),
            ],
          ),
          const SizedBox(height: 18),
          _labelled(context.l10n.mixStrength, '${mix.percent.fixed(1)} %'),
          const SizedBox(height: 8),
          _StrengthGauge(percent: mix.percent),
          if (verdict.isNotEmpty) ...[
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Row(
                key: ValueKey(verdict),
                children: [
                  Icon(
                    mix.strength == MixStrength.gentle
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: verdictColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      verdict,
                      style: TextStyle(color: verdictColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _fact(
                Icons.water_drop_outlined,
                '${mix.bottleMl.round()} ml',
                context.l10n.fluidLabel,
              ),
              _fact(
                Icons.grain_rounded,
                '${mix.sodium.round()} mg',
                context.l10n.sodiumLabel,
              ),
              if (mix.caffeine > 0)
                _fact(
                  Icons.coffee_rounded,
                  '${mix.caffeine.round()} mg',
                  context.l10n.caffeineLabel,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelled(String label, String value) => Row(
    children: [
      Expanded(
        child: Text(label, style: TextStyle(color: muted, fontSize: 12)),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );

  Widget _legend(Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(color: muted, fontSize: 11)),
    ],
  );

  Widget _fact(IconData icon, String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: fjInk.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fjInk70),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: muted, fontSize: 12)),
      ],
    ),
  );
}

/// Glucose and fructose as two parts of one bar.
class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.glucose, required this.fructose});
  final double glucose, fructose;

  @override
  Widget build(BuildContext context) {
    final total = glucose + fructose;
    final share = total <= 0 ? 0.0 : glucose / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Container(color: fjInk10),
              if (total > 0) ...[
                Container(color: _fructose),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: c.maxWidth * share,
                  color: mint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Strength from 0 to 15 %: gentle up to 8, concentrated up to 12.
class _StrengthGauge extends StatelessWidget {
  const _StrengthGauge({required this.percent});
  final double percent;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final x = (percent.clamp(0, _gaugeMax) / _gaugeMax) * c.maxWidth;
      return SizedBox(
        height: 18,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: Container(color: mint.withValues(alpha: .55)),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(color: _amber.withValues(alpha: .55)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(color: _red.withValues(alpha: .55)),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              left: (x - 9).clamp(-2, c.maxWidth - 16),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: fjInk,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: duo(0xFF111111, 0xFFF2F4F7),
                    width: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
    decoration: BoxDecoration(
      color: duo(0xFF1E1E1E, 0xFFFFFFFF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: fjInk10),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });
  final MixItem item;
  final ValueChanged<MixItem> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final step = mixStep(item.ingredient, item.unit);
    final facts = item.facts;
    final color = _color(item.ingredient);
    final details = [
      if (!facts.liquid && item.unit != MixUnit.grams)
        context.l10n.mixRowGrams(_number(item.quantity)),
      if (facts.carbs > 0) '${item.carbs.round()} g ${context.l10n.carbsLabel}',
      if (facts.sodium > 0)
        '${item.sodium.round()} mg ${context.l10n.sodiumLabel}',
      if (facts.caffeine > 0)
        '${item.caffeine.round()} mg ${context.l10n.caffeineLabel}',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 10),
      decoration: BoxDecoration(
        color: duo(0xFF1E1E1E, 0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fjInk10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon(item.ingredient), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ingredientName(context, item.ingredient),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details.join(' · '),
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.mixRemove,
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: Icon(Icons.close_rounded, size: 18, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 8),
            child: Row(
              children: [
                if (facts.units.length > 1)
                  Flexible(child: _unitPicker(context, facts)),
                const Spacer(),
                _Stepper(
                  value: _amount(item),
                  onMinus: item.amount > 0
                      ? () => onChanged(
                          item.copyWith(
                            amount: (item.amount - step).clamp(
                              0,
                              double.infinity,
                            ),
                          ),
                        )
                      : null,
                  onPlus: () =>
                      onChanged(item.copyWith(amount: item.amount + step)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitPicker(BuildContext context, IngredientFacts facts) =>
      PopupMenuButton<MixUnit>(
        tooltip: '',
        color: duo(0xFF242424, 0xFFEEF1F5),
        initialValue: item.unit,
        onSelected: (unit) => onChanged(
          MixItem(item.ingredient, unit == MixUnit.grams ? 10 : 1, unit),
        ),
        itemBuilder: (context) => [
          for (final u in facts.units)
            PopupMenuItem(
              value: u,
              child: Text(_unitName(context, item.ingredient, u)),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          decoration: BoxDecoration(
            color: fjInk.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _unitName(context, item.ingredient, item.unit),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, size: 18),
            ],
          ),
        ),
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, this.onMinus, this.onPlus});
  final String value;
  final VoidCallback? onMinus, onPlus;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _round(Icons.remove_rounded, onMinus),
      SizedBox(
        width: 58,
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      _round(Icons.add_rounded, onPlus),
    ],
  );

  Widget _round(IconData icon, VoidCallback? onTap) => Material(
    color: fjInk.withValues(alpha: onTap == null ? .03 : .08),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: onTap == null ? fjInk24 : fjInk),
      ),
    ),
  );
}

/// An amount as a cook writes it: ½, 1¼, 2.
String _amount(MixItem item) {
  final a = item.amount;
  return switch (item.unit) {
    MixUnit.ml => '${a.round()} ml',
    MixUnit.grams => '${_number(a)} g',
    _ => _fraction(a),
  };
}

/// Whole numbers without a decimal, others with one.
String _number(double v) => v.fixed(v == v.roundToDouble() ? 0 : 1);

String _fraction(double a) {
  final whole = a.floor();
  final rest = ((a - whole) * 4).round();
  final part = const ['', '¼', '½', '¾'][rest.clamp(0, 3)];
  if (whole == 0) return part.isEmpty ? '0' : part;
  return '$whole$part';
}

String _ingredientName(BuildContext context, MixIngredient i) => switch (i) {
  MixIngredient.maltodextrin => context.l10n.mixMaltodextrin,
  MixIngredient.sugar => context.l10n.mixSugar,
  MixIngredient.dextrose => context.l10n.mixDextrose,
  MixIngredient.honey => context.l10n.mixHoney,
  MixIngredient.salt => context.l10n.mixSalt,
  MixIngredient.orangeJuice => context.l10n.mixOrangeJuice,
  MixIngredient.appleJuice => context.l10n.mixAppleJuice,
  MixIngredient.cola => context.l10n.mixCola,
};

/// Honey is measured by the spoon, never heaped, so its spoons need no
/// "level".
String _unitName(BuildContext context, MixIngredient i, MixUnit u) =>
    switch (u) {
      MixUnit.grams => 'g',
      MixUnit.ml => 'ml',
      MixUnit.pinch => context.l10n.unitPinch,
      MixUnit.tspLevel when i == MixIngredient.honey => context.l10n.unitTsp,
      MixUnit.tbspLevel when i == MixIngredient.honey => context.l10n.unitTbsp,
      MixUnit.tspLevel => context.l10n.unitTspLevel,
      MixUnit.tspHeaped => context.l10n.unitTspHeaped,
      MixUnit.tbspLevel => context.l10n.unitTbspLevel,
      MixUnit.tbspHeaped => context.l10n.unitTbspHeaped,
    };

String _recipeName(BuildContext context, MixRecipe r) => switch (r) {
  MixRecipe.maltoSugar => context.l10n.mixRecipeMaltoSugar,
  MixRecipe.juice => context.l10n.mixRecipeJuice,
  MixRecipe.juicePlus => context.l10n.mixRecipeJuicePlus,
  MixRecipe.cola => context.l10n.mixRecipeCola,
};

IconData _icon(MixIngredient i) => switch (i) {
  MixIngredient.maltodextrin => Icons.bolt_rounded,
  MixIngredient.sugar => Icons.grain_rounded,
  MixIngredient.dextrose => Icons.flash_on_rounded,
  MixIngredient.honey => Icons.hive_rounded,
  MixIngredient.salt => Icons.scatter_plot_rounded,
  MixIngredient.orangeJuice => Icons.local_drink_rounded,
  MixIngredient.appleJuice => Icons.local_drink_rounded,
  MixIngredient.cola => Icons.local_cafe_rounded,
};

Color _color(MixIngredient i) => switch (i) {
  MixIngredient.maltodextrin => mint,
  MixIngredient.sugar => _fructose,
  MixIngredient.dextrose => mint,
  MixIngredient.honey => _amber,
  MixIngredient.salt => fjInk70,
  MixIngredient.orangeJuice => _fructose,
  MixIngredient.appleJuice => const Color(0xFF9BD770),
  MixIngredient.cola => const Color(0xFFB98563),
};
