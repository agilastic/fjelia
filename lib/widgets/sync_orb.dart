import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/fjelia_style.dart';
import 'app_widgets.dart';
import 'spinning_sync_icon.dart';

/// How fresh the data is, shown as the orb's dot.
enum SyncFreshness { fresh, stale, error }

/// The sync button, plain like the other header icons. While a sync runs
/// it turns mint with a soft light behind it and a ring around it fills with
/// the sync's progress; a small dot tells when the data is getting old or the
/// last sync failed.
class SyncOrb extends StatelessWidget {
  const SyncOrb({
    super.key,
    required this.spinning,
    required this.freshness,
    this.progress,
  });

  final bool spinning;
  final SyncFreshness freshness;

  /// 0–1 while a sync runs; null hides the ring.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final dot = switch (freshness) {
      SyncFreshness.fresh => null,
      SyncFreshness.stale => Colors.amber,
      SyncFreshness.error => const Color(0xFFFF5A7A),
    };
    final ring = progress;
    return SizedBox.square(
      dimension: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (ring != null)
            Positioned(
              left: -5,
              top: -5,
              right: -5,
              bottom: -5,
              // Eases from where it was to the new step of the sync.
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: ring.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CustomPaint(
                  key: const ValueKey('sync-progress-ring'),
                  painter: _RingPainter(value),
                ),
              ),
            ),
          // The light fades by its colour; an Opacity layer over a blurred
          // shadow trips Impeller's validation.
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: mint.withValues(alpha: spinning ? .45 : 0),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          SpinningSyncIcon(spinning: spinning, color: spinning ? mint : muted),
          if (dot != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                  border: Border.all(color: fjBackground, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The sync's progress as a thin ring in the aurora pair, on a faint track.
class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(1.2);
    canvas.drawArc(
      arc,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = fjInk10,
    );
    if (value <= 0) return;
    canvas.drawArc(
      arc,
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        // Mint at the start, cyan at the tip, over the filled arc only.
        ..shader = SweepGradient(
          endAngle: math.max(.01, 2 * math.pi * value),
          transform: const GradientRotation(-math.pi / 2),
          colors: [mint, fjAccent(const Color(0xFF3EE0FF))],
        ).createShader(rect),
    );
    // The round cap before the start would take the gradient's last colour;
    // it is painted in the first one.
    canvas.drawCircle(
      Offset(arc.center.dx, arc.top),
      1.1,
      Paint()..color = mint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
