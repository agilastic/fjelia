import '../theme/fjelia_style.dart';
import '../l10n/l10n_ext.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/day_data_provider.dart';
import '../providers/training_load_provider.dart';
import '../screens/sleep/sleep_screen.dart';
import '../screens/battery/battery_screen.dart';
import 'app_widgets.dart';

class DaySummaryCard extends ConsumerWidget {
  const DaySummaryCard({super.key, required this.openLoad});
  final VoidCallback openLoad;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(selectedDateProvider),
        s = ref.watch(dayScoresProvider(d)).valueOrNull,
        h = ref.watch(hrvForDateProvider(d)).valueOrNull;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: _Gauge(
              context.l10n.sleep,
              s?.sleep?.score,
              100,
              () => showAppSheet(context, const SleepScreen()),
              colors: const [Color(0xFF9D7BFF), Color(0xFF3EE0FF)],
            ),
          ),
          Expanded(
            child: _Gauge(
              context.l10n.energy,
              h?.computedEnergie,
              100,
              () => showAppSheet(context, const BatteryScreen()),
              colors: const [mint, Color(0xFFC6FF4D)],
            ),
          ),
          Expanded(
            child: _Gauge(
              context.l10n.load2,
              s?.strain.score,
              trainingLoadScale(
                s?.strain.score,
                ref.watch(trainingLoadProvider).valueOrNull?.optimalHigh,
              ),
              openLoad,
              colors: const [Color(0xFFFFB13D), Color(0xFFFF4D8D)],
              isLoad: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// A ring three quarters round in its gradient. When it appears the arc
/// sweeps in, a glint runs along it to the value and the glow breathes
/// twice before it settles; once, so the page comes to rest.
class _Gauge extends StatefulWidget {
  const _Gauge(
    this.label,
    this.value,
    this.max,
    this.tap, {
    required this.colors,
    this.isLoad = false,
  });
  final String label;
  final num? value;
  final double max;
  final VoidCallback tap;
  final List<Color> colors;

  /// The training-load gauge shows TRIMP, not a percentage.
  final bool isLoad;

  @override
  State<_Gauge> createState() => _GaugeState();
}

class _GaugeState extends State<_Gauge> with SingleTickerProviderStateMixin {
  late final _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  double get _fraction => widget.value == null
      ? 0.0
      : (widget.value! / widget.max).clamp(0, 1).toDouble();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_run.isDismissed) _play();
  }

  @override
  void didUpdateWidget(_Gauge old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _play();
  }

  void _play() {
    // Without motion the ring shows its value and glow at once.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _run.value = 1;
    } else {
      _run.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return InkWell(
      onTap: widget.tap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 92,
            child: AnimatedBuilder(
              animation: _run,
              builder: (context, child) {
                final t = _run.value;
                // The arc in the first 40 %, then a glint runs along it
                // from the start to the value.
                final fill = Curves.easeOutCubic.transform(
                  (t / .4).clamp(0, 1),
                );
                final glint = t > .38 && t < .78
                    ? Curves.easeInOut.transform((t - .38) / .4)
                    : null;
                // Two breaths of light, fading to a glow above rest.
                final breath = t <= .4
                    ? fill
                    : 1 +
                          .6 *
                              math.sin((t - .4) / .6 * 2 * math.pi).abs() *
                              (1 - (t - .4) / .6);
                return CustomPaint(
                  painter: _GaugePaint(
                    _fraction * fill,
                    widget.colors,
                    glow: breath,
                    glint: glint == null ? null : _fraction * glint,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value == null ? '—' : valueText(value),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 23,
                        height: 1.1,
                      ),
                    ),
                    // The unit sits centred below the number; every gauge
                    // keeps the same height so the numbers line up.
                    SizedBox(
                      height: 11,
                      child: Text(
                        value == null
                            ? ''
                            : widget.isLoad
                            ? 'TRIMP'
                            : '%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: muted,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: LinearGradient(
              colors: [for (final c in widget.colors) fjAccent(c)],
            ).createShader,
            child: Text(
              widget.label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePaint extends CustomPainter {
  _GaugePaint(this.value, this.colors, {this.glow = 1, this.glint});
  final double value;
  final List<Color> colors;

  /// How strong the light is: 1 at rest, more while it breathes.
  final double glow;

  /// Where the running glint is, as a share of the ring; null when done.
  final double? glint;

  static const _start = math.pi * .75;
  static const _sweep = math.pi * 1.5;

  Offset _at(Rect rect, double share) {
    final angle = _start + _sweep * share;
    return rect.center +
        Offset(math.cos(angle), math.sin(angle)) * (rect.width / 2);
  }

  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromLTWH(7, 7, s.width - 14, s.height - 14);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    p.color = fjInk.withValues(alpha: .07);
    c.drawArc(rect, _start, _sweep, false, p);
    if (value <= 0) return;
    // Round the whole circle, so the rounded start cap just before the
    // first angle takes the first colour, not the last.
    final shader = SweepGradient(
      colors: [colors.first, colors.last, colors.last, colors.first],
      stops: const [0, .75, .85, 1],
      transform: const GradientRotation(_start),
    ).createShader(rect);
    final sweep = _sweep * value;
    Paint light(double width, double blur, double alpha) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..shader = shader
      ..color = Colors.white.withValues(alpha: alpha.clamp(0, 1))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    // A wide halo, a tight glow, then the sharp arc on top.
    c.drawArc(rect, _start, sweep, false, light(16, 14 * glow, .45 * glow));
    c.drawArc(rect, _start, sweep, false, light(10, 6, .9 * glow));
    c.drawArc(rect, _start, sweep, false, p..shader = shader);
    final tip = _at(rect, value);
    c.drawCircle(
      tip,
      7 + 3 * (glow - 1),
      Paint()
        ..color = colors.last.withValues(alpha: (.7 * glow).clamp(0, 1))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    c.drawCircle(tip, 3, Paint()..color = Colors.white);
    if (glint case final g?) {
      final at = _at(rect, g);
      c.drawCircle(
        at,
        9,
        Paint()
          ..color = Colors.white.withValues(alpha: .55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      c.drawCircle(at, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePaint old) =>
      old.value != value ||
      old.colors != colors ||
      old.glow != glow ||
      old.glint != glint;
}
