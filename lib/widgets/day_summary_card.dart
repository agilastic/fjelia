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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: _Gauge(
              'SLEEP',
              s?.sleep?.score,
              100,
              () => showAppSheet(context, const SleepScreen()),
            ),
          ),
          Expanded(
            child: _Gauge(
              'ENERGY',
              h?.computedEnergie,
              100,
              () => showAppSheet(context, const BatteryScreen()),
            ),
          ),
          Expanded(
            child: _Gauge(
              'LOAD',
              s?.strain.score,
              trainingLoadScale(
                s?.strain.score,
                ref.watch(trainingLoadProvider).valueOrNull?.optimalHigh,
              ),
              openLoad,
            ),
          ),
        ],
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge(this.label, this.value, this.max, this.tap);
  final String label;
  final num? value;
  final double max;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: tap,
    child: Column(
      children: [
        SizedBox(
          height: 65,
          width: 105,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CustomPaint(
                size: const Size(100, 65),
                painter: _GaugePaint(
                  value == null ? 0 : (value! / max).clamp(0, 1).toDouble(),
                  label == 'LOAD' ? const Color(0xFF8C9EFF) : Colors.orange,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value == null
                            ? '—'
                            : label == 'LOAD'
                            ? valueText(value)
                            : '${valueText(value)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                        ),
                      ),
                      if (label == 'LOAD')
                        const TextSpan(
                          text: ' TRIMP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: muted, fontSize: 9, letterSpacing: 1.3),
        ),
      ],
    ),
  );
}

class _GaugePaint extends CustomPainter {
  _GaugePaint(this.value, this.color);
  final double value;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(8, 14, s.width - 16, s.width - 16);
    p.color = Colors.white12;
    c.drawArc(rect, math.pi, math.pi, false, p);
    p.color = Colors.white;
    p.shader = SweepGradient(
      startAngle: math.pi,
      endAngle: 2 * math.pi,
      colors: [Colors.red, color, Colors.amber],
    ).createShader(rect);
    c.drawArc(rect, math.pi, math.pi * value, false, p);
    if (value > 0) {
      final center = rect.center;
      final angle = math.pi + math.pi * value;
      final r = rect.width / 2;
      final needle = Paint()
        ..color = Colors.white
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      c.drawLine(
        center + Offset(math.cos(angle) * (r - 5), math.sin(angle) * (r - 5)),
        center + Offset(math.cos(angle) * (r + 5), math.sin(angle) * (r + 5)),
        needle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePaint old) => old.value != value;
}
