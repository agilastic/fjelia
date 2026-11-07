import 'package:flutter/material.dart';

import 'app_widgets.dart' show mint, muted;

/// What is still ahead: violet into cyan.
const planGradient = [Color(0xFF9D7BFF), Color(0xFF3EE0FF)];

/// What is done: the app's green into lime.
const doneGradient = [mint, Color(0xFFC6FF4D)];

/// The background of a card that is only planned: darker than a done one,
/// so it reads as not there yet.
const ghostPanel = Color(0xFF161616);

/// The heading of the Upcoming or History part of the plan: a glowing
/// badge and the label in the part's gradient, so the two never look alike.
class TimelineSectionHeader extends StatelessWidget {
  const TimelineSectionHeader({
    super.key,
    required this.label,
    required this.icon,
    required this.colors,
  });
  final String label;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(colors: colors);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: .45),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(icon, size: 17, color: Colors.black87),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: gradient.createShader,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                colors: [
                  colors.last.withValues(alpha: .5),
                  colors.last.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A day heading in the plan. Ahead it has a hollow ring, done a filled,
/// glowing dot.
class TimelineDayLabel extends StatelessWidget {
  const TimelineDayLabel(
    this.text, {
    super.key,
    required this.future,
    this.highlight = false,
  });
  final String text;
  final bool future;

  /// Today: the label is set in the part's colour.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = future ? planGradient.last : doneGradient.first;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: future ? null : color,
              border: future ? Border.all(color: color, width: 1.6) : null,
              boxShadow: future
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: .6),
                        blurRadius: 6,
                      ),
                    ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: highlight ? color : muted,
                fontWeight: highlight ? FontWeight.w800 : null,
                letterSpacing: .7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The line between what is planned and what is done.
class NowDivider extends StatelessWidget {
  const NowDivider({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    Widget line(List<Color> colors) => Expanded(
      child: Container(
        height: 1.5,
        decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          line([planGradient.last.withValues(alpha: 0), planGradient.last]),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [Color(0xFF3EE0FF), mint]),
              boxShadow: [
                BoxShadow(color: mint.withValues(alpha: .4), blurRadius: 14),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
          line([doneGradient.first, doneGradient.first.withValues(alpha: 0)]),
        ],
      ),
    );
  }
}

/// A dashed rounded outline: the edge of a card that is only planned.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.radius = 14,
    this.strokeWidth = 1.5,
  });
  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}
