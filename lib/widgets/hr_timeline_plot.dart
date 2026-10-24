import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../models/heart_rate_summary.dart';
import 'app_widgets.dart';

class HrTimelinePlot extends StatelessWidget {
  const HrTimelinePlot({
    super.key,
    required this.points,
    required this.date,
    this.secondary = const [],
    this.activities = const [],
    this.compact = false,
    this.days = 1,
    this.height,
    this.average,
  });
  final List<ChartPoint> points, secondary;
  final List<ActivityTimelineSpan> activities;
  final DateTime date;
  final bool compact;
  final int days;
  final double? height, average;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height ?? (compact ? 110 : 235),
    child: points.isEmpty && secondary.isEmpty
        ? const Center(
            child: Text(
              'No measurements in this period',
              style: TextStyle(color: muted),
            ),
          )
        : LayoutBuilder(
            builder: (context, c) => CustomPaint(
              size: Size(c.maxWidth, height ?? (compact ? 110 : 235)),
              painter: _HrPainter(
                points,
                secondary,
                activities,
                date,
                days,
                compact,
                average,
              ),
            ),
          ),
  );
}

class _HrPainter extends CustomPainter {
  _HrPainter(
    this.points,
    this.secondary,
    this.activities,
    this.date,
    this.days,
    this.compact,
    this.average,
  );
  final List<ChartPoint> points, secondary;
  final List<ActivityTimelineSpan> activities;
  final DateTime date;
  final int days;
  final bool compact;
  final double? average;
  @override
  void paint(Canvas canvas, Size size) {
    final all = [...points, ...secondary];
    final values = all.map((p) => p.value).toList();
    final lo = math.max(0, (values.reduce(math.min) - 3).floor()).toDouble();
    final hi = math
        .max(lo + 8, (values.reduce(math.max) + 3).ceil())
        .toDouble();
    final plot = compact
        ? Rect.fromLTRB(0, 4, size.width, size.height - 4)
        : Rect.fromLTRB(32, 16, size.width - 6, size.height - 30);
    final start = DateTime(date.year, date.month, date.day - days + 1);
    double fraction(DateTime t) {
      final d = t.toLocal();
      if (days == 1) return (d.hour * 60 + d.minute + d.second / 60) / 1440;
      return DateTime.utc(d.year, d.month, d.day)
              .difference(DateTime.utc(start.year, start.month, start.day))
              .inDays /
          (days - 1);
    }

    double x(DateTime t) => plot.left + fraction(t).clamp(0, 1) * plot.width;
    double y(double v) => plot.bottom - (v - lo) / (hi - lo) * plot.height;
    void text(String value, Offset at, Color color, {double font = 9}) {
      final p = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(fontFamily: 'Roboto', fontSize: font, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(canvas, at);
    }

    if (!compact) {
      for (var i = 0; i <= 4; i++) {
        final yy = plot.top + plot.height * i / 4;
        canvas.drawLine(
          Offset(plot.left, yy),
          Offset(plot.right, yy),
          Paint()..color = Colors.white.withValues(alpha: .1),
        );
        text('${(hi - (hi - lo) * i / 4).round()}', Offset(0, yy - 5), muted);
      }
      if (days == 1) {
        for (var i = 0; i <= 6; i++) {
          final xx = plot.left + plot.width * i / 6;
          canvas.drawLine(
            Offset(xx, plot.top),
            Offset(xx, plot.bottom),
            Paint()..color = Colors.white.withValues(alpha: .08),
          );
        }
        text('00:00', Offset(plot.left - 8, plot.bottom + 12), muted);
        text('12:00', Offset(plot.center.dx - 14, plot.bottom + 12), muted);
        text('24:00', Offset(plot.right - 27, plot.bottom + 12), muted);
        for (final a in activities) {
          final left = x(a.startDate),
              right = x(a.startDate.add(Duration(seconds: a.durationSeconds)));
          if (right <= left) continue;
          canvas.drawRect(
            Rect.fromLTRB(left, plot.top, right, plot.bottom),
            Paint()..color = Colors.lightBlue.withValues(alpha: .12),
          );
          canvas.drawLine(
            Offset(left, plot.top),
            Offset(right, plot.top),
            Paint()
              ..color = Colors.lightBlue
              ..strokeWidth = 3,
          );
        }
      } else {
        text(
          DateFormat('d.M').format(start),
          Offset(plot.left - 6, plot.bottom + 12),
          muted,
        );
        text(
          DateFormat('d.M').format(date),
          Offset(plot.right - 20, plot.bottom + 12),
          muted,
        );
      }
    }
    if (days == 1 && average != null) {
      final avg = average!;
      final yy = y(avg);
      for (double xx = plot.left; xx < plot.right; xx += 10) {
        canvas.drawLine(
          Offset(xx, yy),
          Offset(math.min(xx + 6, plot.right), yy),
          Paint()
            ..color = Colors.white30
            ..strokeWidth = 1,
        );
      }
      if (!compact) {
        text('ø${avg.round()}', Offset(plot.right - 25, yy - 13), muted);
      }
    }
    void series(List<ChartPoint> raw, Color color, bool intensity) {
      final sorted = raw.toList()..sort((a, b) => a.at.compareTo(b.at));
      for (var i = 1; i < sorted.length; i++) {
        final a = sorted[i - 1], b = sorted[i];
        final c = intensity
            ? b.value >= 140
                  ? Colors.orange
                  : b.value >= 100
                  ? Colors.amber
                  : mint
            : color;
        canvas.drawLine(
          Offset(x(a.at), y(a.value)),
          Offset(x(b.at), y(b.value)),
          Paint()
            ..color = c
            ..strokeWidth = compact ? 1.8 : 2
            ..strokeCap = StrokeCap.round,
        );
      }
      if (days > 1 || sorted.length == 1) {
        for (final p in sorted) {
          canvas.drawCircle(
            Offset(x(p.at), y(p.value)),
            2.8,
            Paint()..color = color,
          );
        }
      }
    }

    series(points, days == 1 ? mint : Colors.lightBlue, days == 1);
    series(secondary, Colors.redAccent, false);
  }

  @override
  bool shouldRepaint(covariant _HrPainter old) =>
      old.points != points ||
      old.secondary != secondary ||
      old.activities != activities ||
      old.date != date ||
      old.days != days ||
      old.compact != compact ||
      old.average != average;
}
