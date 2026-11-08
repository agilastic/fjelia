import '../theme/fjelia_style.dart';
import '../l10n/l10n_ext.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bio_age_provider.dart';
import '../services/bio_age_activity.dart';
import '../services/bio_age_service.dart';
import 'app_widgets.dart';

const _accent = [Color(0xFF9D7BFF), Color(0xFFFF7AD9)];
const _fit = [mint, Color(0xFF3EE0FF)];
const _band = [Color(0xFF3EE0FF), Color(0xFF9D7BFF), Color(0xFFFF7AD9)];
const _helps = [mint, Color(0xFF3EE0FF)];
const _slows = [Color(0xFFFFB13D), Color(0xFFFF7A59)];

/// Fitness age and where life tends to lead, without pretending to know a
/// year: the fitness age compares VO₂max with age norms; the lifespan is a
/// band from population statistics and the factors only say which way they
/// push.
class BioAgeCard extends ConsumerWidget {
  const BioAgeCard({super.key, this.expanded = false});
  final bool expanded;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(bioAgeProvider);
    return result.when(
      loading: () => SectionCard(
        title: context.l10n.biologicalAge,
        accent: _accent,
        child: const LinearProgressIndicator(),
      ),
      error: (e, _) => DataError(e),
      data: (r) => SectionCard(
        title: context.l10n.biologicalAge,
        accent: _accent,
        onTap: expanded
            ? null
            : () => showAppSheet(
                context,
                SheetPage(
                  title: context.l10n.biologicalAge,
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: BioAgeCard(expanded: true),
                  ),
                ),
              ),
        child: r == null
            ? EmptyState(context.l10n.addYourBirthYearIn)
            : _Body(r: r, expanded: expanded),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.r, required this.expanded});
  final BioAgeResult r;
  final bool expanded;

  @override
  State<_Body> createState() => _BodyState();
}

/// Everything comes in once: the ring fills while the fitness age counts,
/// the band glows up on the life line, the factors follow one by one.
class _BodyState extends State<_Body> with SingleTickerProviderStateMixin {
  late final _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_run.isDismissed) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _run.value = 1;
      } else {
        _run.forward();
      }
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  Animation<double> _phase(double from, double to) => CurvedAnimation(
    parent: _run,
    curve: Interval(from, to, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) {
    final r = widget.r, l10n = context.l10n;
    final years = (r.age - r.fitnessAge).round();
    final lean = switch (r.lean) {
      BioAgeLean.muchYounger => l10n.bioLeanMuchYounger,
      BioAgeLean.younger => l10n.bioLeanYounger,
      BioAgeLean.even => l10n.bioLeanEven,
      BioAgeLean.older => l10n.bioLeanOlder,
      BioAgeLean.muchOlder => l10n.bioLeanMuchOlder,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FitnessOrb(
              value: r.fitnessAge,
              atMost20: r.fitnessAge <= 20,
              progress: _phase(0, .55),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientTitle(lean, colors: _accent, size: 17),
                  const SizedBox(height: 6),
                  _Pill(
                    text: years > 0
                        ? l10n.fitnessYoungerBy(years)
                        : years < 0
                        ? l10n.fitnessOlderBy(-years)
                        : l10n.fitnessSameAsAge,
                    colors: years >= 0 ? _fit : _slows,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'VO₂max ${valueText(r.vo2max, 1)} · '
                    '${switch (r.vo2Class) {
                      'Below Avg' => l10n.vo2ClassBelowAvg,
                      'Average' => l10n.vo2ClassAverage,
                      'Above Avg' => l10n.vo2ClassAboveAvg,
                      'Good' => l10n.vo2ClassGood,
                      'Excellent' => l10n.vo2ClassExcellent,
                      'Elite' => l10n.vo2ClassElite,
                      _ => r.vo2Class,
                    }}',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _LifespanLine(r: r, glow: _phase(.3, 1)),
        if (!r.activity.isComplete || r.activity.usesStepEstimate)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.activity.isComplete
                        ? l10n.bioAgeActivityEstimatedLabel
                        : l10n.bioAgeActivityUnknownLabel,
                    style: TextStyle(fontSize: 11, color: muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        if (widget.expanded) ...[
          const SizedBox(height: 18),
          _Factors(pushes: r.pushes, activity: r.activity, run: _run),
          const SizedBox(height: 14),
          _ActivityDetails(activity: r.activity),
          const SizedBox(height: 12),
          Text(
            l10n.bioAgeModelNote,
            style: TextStyle(color: muted, fontSize: 11, height: 1.4),
          ),
        ],
      ],
    );
  }
}

/// The fitness age inside a glowing ring that sweeps in as it counts up.
class _FitnessOrb extends StatelessWidget {
  const _FitnessOrb({
    required this.value,
    required this.atMost20,
    required this.progress,
  });
  final double value;
  final bool atMost20;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 104,
    child: AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value;
        return CustomPaint(
          painter: _OrbPaint(t),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: LinearGradient(
                    colors: [for (final c in _fit) fjAccent(c)],
                  ).createShader,
                  child: Text(
                    '${atMost20 ? '≤' : ''}${(value * t).round()}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.fitnessAge.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _OrbPaint extends CustomPainter {
  _OrbPaint(this.t);
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromLTWH(8, 8, s.width - 16, s.height - 16);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = fjInk.withValues(alpha: .07);
    c.drawArc(rect, 0, math.pi * 2, false, track);
    if (t <= 0) return;
    const start = -math.pi / 2;
    final shader = SweepGradient(
      colors: [..._fit, _accent.first, _fit.first],
      transform: const GradientRotation(start),
    ).createShader(rect);
    Paint arc(double width, double blur, double alpha) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..shader = shader
      ..color = Colors.white.withValues(alpha: alpha)
      ..maskFilter = blur == 0 ? null : MaskFilter.blur(BlurStyle.normal, blur);
    final sweep = math.pi * 2 * t * .999;
    c.drawArc(rect, start, sweep, false, arc(14, 10, .5));
    c.drawArc(rect, start, sweep, false, arc(7, 0, 1));
    final tip =
        rect.center +
        Offset(math.cos(start + sweep), math.sin(start + sweep)) *
            (rect.width / 2);
    c.drawCircle(
      tip,
      7,
      Paint()
        ..color = Colors.white.withValues(alpha: .6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    c.drawCircle(tip, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _OrbPaint old) => old.t != t;
}

/// The life line from today on, with the lifespan as a glowing band, not a
/// point: the model cannot say a year, only where life tends to lead.
class _LifespanLine extends StatelessWidget {
  const _LifespanLine({required this.r, required this.glow});
  final BioAgeResult r;
  final Animation<double> glow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final band = r.lifespanBand;
    final today = r.age.floor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                l10n.lifespanBandTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: muted,
                ),
              ),
            ),
            GradientTitle(
              l10n.lifespanBandYears(band.low, band.high),
              colors: _band,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: AnimatedBuilder(
            animation: glow,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _LinePaint(
                today: today,
                low: band.low,
                high: band.high,
                t: glow.value,
                todayLabel: l10n.todayAge(today),
                // The app's font: a painter does not inherit it.
                labelStyle: DefaultTextStyle.of(context).style.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: fjInk70,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.lifespanBandNote,
          style: TextStyle(fontSize: 11, color: muted, height: 1.4),
        ),
      ],
    );
  }
}

class _LinePaint extends CustomPainter {
  _LinePaint({
    required this.today,
    required this.low,
    required this.high,
    required this.t,
    required this.todayLabel,
    required this.labelStyle,
  });
  final int today, low, high;
  final double t;
  final String todayLabel;
  final TextStyle labelStyle;

  @override
  void paint(Canvas c, Size s) {
    // From a little before today to past the band, so both have room.
    final from = math.max(0, today - 10).toDouble();
    final to = math.max(high + 8, 100).toDouble();
    double x(num age) => (age - from) / (to - from) * s.width;
    final y = s.height - 12;

    // The line: solid up to today, then fading into the future.
    c.drawLine(
      Offset(0, y),
      Offset(x(today), y),
      Paint()
        ..color = fjInk.withValues(alpha: .35)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      Offset(x(today), y),
      Offset(s.width, y),
      Paint()
        ..shader = LinearGradient(
          colors: [fjInk.withValues(alpha: .18), fjInk.withValues(alpha: .02)],
        ).createShader(Rect.fromLTWH(x(today), y - 1, s.width, 2))
        ..strokeWidth = 2,
    );

    // The band grows out from its middle and glows; its ends are soft, as
    // the statistics are.
    final mid = (x(low) + x(high)) / 2;
    final half = (x(high) - x(low)) / 2 * t;
    if (half > 0) {
      final band = Rect.fromLTRB(mid - half, y - 9, mid + half, y + 9);
      final shader = LinearGradient(
        colors: [
          _band.first.withValues(alpha: 0),
          for (final col in _band) col,
          _band.last.withValues(alpha: 0),
        ],
        stops: const [0, .2, .5, .8, 1],
      ).createShader(band);
      c.drawRRect(
        RRect.fromRectAndRadius(band.inflate(6), const Radius.circular(14)),
        Paint()
          ..shader = shader
          ..color = Colors.white.withValues(alpha: .45 * t)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(band, const Radius.circular(9)),
        Paint()
          ..shader = shader
          ..color = Colors.white.withValues(alpha: .9 * t),
      );
    }

    // Today: a bright dot with its age above.
    final dot = Offset(x(today), y);
    c.drawCircle(
      dot,
      8,
      Paint()
        ..color = mint.withValues(alpha: .5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    c.drawCircle(dot, 4.5, Paint()..color = mint);
    final label = TextPainter(
      text: TextSpan(text: todayLabel, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final lx = (dot.dx - label.width / 2).clamp(0.0, s.width - label.width);
    label.paint(c, Offset(lx, y - 30));
  }

  @override
  bool shouldRepaint(covariant _LinePaint old) =>
      old.t != t ||
      old.today != today ||
      old.low != low ||
      old.high != high ||
      old.labelStyle != labelStyle;
}

/// What helps and what slows, as chips that come in one by one; how much
/// only as one or two dots, never in years.
class _Factors extends StatelessWidget {
  const _Factors({
    required this.pushes,
    required this.activity,
    required this.run,
  });
  final List<({String factor, FactorPush push})> pushes;
  final BioAgeActivity activity;
  final Animation<double> run;

  String _name(BuildContext context, String key) {
    final l10n = context.l10n;
    return switch (key) {
      'vo2max' => 'VO₂max',
      'grip' => l10n.gripStrength,
      'resting_hr' => l10n.restingHr,
      'blood_pressure' => l10n.bioFactorBloodPressure,
      'visceral_fat' => l10n.bioFactorVisceralFat,
      'activity' => l10n.bioAgeActivity,
      'smoking' => l10n.smoking,
      'alcohol' => l10n.alcohol,
      'diabetes' => l10n.diabetes,
      'hba1c' => l10n.hba1c,
      'lipids' => l10n.bioFactorLipids,
      'apob' => l10n.apob,
      'inflammation' => l10n.bioFactorInflammation,
      'kidney_health' => l10n.bioFactorKidney,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final helps = [
      for (final p in pushes)
        if (p.push == FactorPush.helps || p.push == FactorPush.helpsMuch) p,
    ];
    final slows = [
      for (final p in pushes)
        if (p.push == FactorPush.slows || p.push == FactorPush.slowsMuch) p,
    ];
    var i = 0;
    Widget group(
      String title,
      List<Color> colors,
      List<({String factor, FactorPush push})> items,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradientTitle(title.toUpperCase(), colors: colors, size: 10.5),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in items)
              _ChipIn(
                run: run,
                index: i++,
                child: _FactorChip(
                  name:
                      '${p.factor == 'activity' && activity.usesStepEstimate ? '≈ ' : ''}'
                      '${_name(context, p.factor)}',
                  strong:
                      p.push == FactorPush.helpsMuch ||
                      p.push == FactorPush.slowsMuch,
                  colors: colors,
                ),
              ),
          ],
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (helps.isNotEmpty) group(context.l10n.factorHelps, _helps, helps),
        if (helps.isNotEmpty && slows.isNotEmpty) const SizedBox(height: 14),
        if (slows.isNotEmpty) group(context.l10n.factorSlows, _slows, slows),
      ],
    );
  }
}

/// Moves and grows in after the ones before it (no opacity layer over the
/// chip's glow, which Impeller cannot pass down).
class _ChipIn extends StatelessWidget {
  const _ChipIn({required this.run, required this.index, required this.child});
  final Animation<double> run;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (.45 + index * .06).clamp(0.0, .9);
    final a = CurvedAnimation(
      parent: run,
      curve: Interval(
        start,
        math.min(1, start + .3),
        curve: Curves.easeOutBack,
      ),
    );
    return AnimatedBuilder(
      animation: a,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (1 - a.value) * 10),
        child: Transform.scale(scale: .6 + .4 * a.value, child: child),
      ),
      child: child,
    );
  }
}

class _FactorChip extends StatelessWidget {
  const _FactorChip({
    required this.name,
    required this.strong,
    required this.colors,
  });
  final String name;
  final bool strong;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        colors: [for (final c in colors) c.withValues(alpha: .16)],
      ),
      border: Border.all(color: colors.first.withValues(alpha: .45)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Long names (French, Finnish, large text) wrap inside the chip.
        Flexible(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fjInk,
            ),
          ),
        ),
        const SizedBox(width: 6),
        for (var d = 0; d < (strong ? 2 : 1); d++)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fjAccent(colors.first),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: .6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.colors});
  final String text;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        colors: [for (final c in colors) c.withValues(alpha: .18)],
      ),
      border: Border.all(color: colors.first.withValues(alpha: .4)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: fjAccent(colors.first),
      ),
    ),
  );
}

class _ActivityDetails extends StatelessWidget {
  const _ActivityDetails({required this.activity});

  final BioAgeActivity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fjInk.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fjInk10),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontSize: 11, color: muted, height: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bioAgeActivityBasis,
              style: TextStyle(color: fjInk70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (activity.reportedDays > 0)
              Text(
                l10n.bioAgeActivityReported(
                  valueText(activity.reportedMinutes),
                ),
              ),
            if (activity.usesStepEstimate)
              Text(
                l10n.bioAgeActivitySteps(
                  valueText(activity.estimatedWalkingMinutes),
                ),
              ),
            Text(l10n.bioAgeActivityCoverage(activity.coveredDays)),
            if (activity.usesStepEstimate) ...[
              const SizedBox(height: 8),
              Text(l10n.bioAgeActivityEstimateNotice),
            ],
            if (!activity.isComplete) ...[
              const SizedBox(height: 8),
              Text(l10n.bioAgeActivityIncomplete),
            ],
          ],
        ),
      ),
    );
  }
}
