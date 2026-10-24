import '../../services/blood_pressure_chart_data.dart';
export '../../services/blood_pressure_chart_data.dart'
    show BpBucketMark, BpPeriod, BpVariationBucket, bpVariationBuckets;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../widgets/app_widgets.dart';

class BpVariationChart extends StatefulWidget {
  const BpVariationChart({
    super.key,
    required this.buckets,
    required this.period,
    this.fullscreen = false,
  });
  final List<BpVariationBucket> buckets;
  final BpPeriod period;
  final bool fullscreen;
  @override
  State<BpVariationChart> createState() => _BpVariationChartState();
}

class _BpVariationChartState extends State<BpVariationChart> {
  int? selected;
  @override
  void didUpdateWidget(covariant BpVariationChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buckets != widget.buckets) selected = null;
  }

  void inspect(Offset position, Size size) {
    final x = position.dx, width = size.width;
    final i = ((x - 34) / (width - 42) * widget.buckets.length).floor().clamp(
      0,
      widget.buckets.length - 1,
    );
    final bucket = widget.buckets[i];
    final values = [
      for (final b in widget.buckets)
        for (final r in b.readings) ...[r.systolic, r.diastolic],
    ];
    final range = BpAxisRange.fromValues(values);
    final lo = range.minimum;
    final hi = range.maximum;
    double y(double v) =>
        size.height - 28 - (v - lo) / (hi - lo) * (size.height - 36);
    final hit =
        bucket.readings.isNotEmpty &&
        [true, false].any(
          (sys) =>
              position.dy >= y(bucket.maximum(sys).toDouble()) - 12 &&
              position.dy <= y(bucket.minimum(sys).toDouble()) + 12,
        );
    final next = x >= 34 && x <= width - 8 && hit ? i : null;
    if (selected != next) setState(() => selected = next);
  }

  Widget plot() => LayoutBuilder(
    builder: (context, constraints) {
      final bucket = selected == null ? null : widget.buckets[selected!];
      final width = constraints.maxWidth;
      final tooltipWidth = math.min(230.0, width - 12);
      final x = selected == null
          ? 0.0
          : 34 + (width - 42) * (selected! + .5) / widget.buckets.length;
      return MouseRegion(
        onHover: (event) => inspect(event.localPosition, constraints.biggest),
        onExit: (_) => setState(() => selected = null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (tap) => inspect(tap.localPosition, constraints.biggest),
          onHorizontalDragStart: (drag) =>
              inspect(drag.localPosition, constraints.biggest),
          onHorizontalDragUpdate: (drag) =>
              inspect(drag.localPosition, constraints.biggest),
          child: Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  label:
                      'Blood pressure minimum, maximum and average by ${widget.period == BpPeriod.day ? 'hour' : 'day'}',
                  child: CustomPaint(
                    painter: _VariationPainter(
                      widget.buckets,
                      widget.period,
                      selected,
                    ),
                  ),
                ),
              ),
              if (bucket != null)
                Positioned(
                  top: 6,
                  left: (x - tooltipWidth / 2).clamp(
                    6,
                    width - tooltipWidth - 6,
                  ),
                  width: tooltipWidth,
                  child: IgnorePointer(
                    child: _BpInfoBox(bucket: bucket, period: widget.period),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final empty = widget.buckets.every((b) => b.readings.isEmpty);
    final graph = empty
        ? const Center(
            child: Text(
              'No measurements in this period',
              style: TextStyle(color: muted),
            ),
          )
        : plot();
    return TapRegion(
      onTapOutside: (_) {
        if (selected != null) setState(() => selected = null);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.period == BpPeriod.day
                      ? 'HOURLY VARIATION'
                      : 'DAILY VARIATION',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (!widget.fullscreen)
                IconButton(
                  tooltip: 'Fullscreen blood-pressure chart',
                  icon: const Icon(
                    Icons.fullscreen_rounded,
                    size: 21,
                    color: muted,
                  ),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          fullscreenDialog: true,
                          builder: (_) => BpChartFullscreen(
                            buckets: widget.buckets,
                            period: widget.period,
                          ),
                        ),
                      ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.fullscreen)
            Expanded(child: graph)
          else
            SizedBox(height: 310, child: graph),
          const SizedBox(height: 8),
          const Text(
            'Bars: min–max · line/dots: average · tap or drag to inspect',
            style: TextStyle(fontSize: 10, color: muted),
          ),
          if (widget.buckets.any((b) => b.mark != BpBucketMark.none))
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 12,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MarkLegend(Icons.directions_run_rounded, mint, 'Training'),
                  _MarkLegend(
                    Icons.watch_off_outlined,
                    muted,
                    'Not worn / no readings',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BpInfoBox extends StatelessWidget {
  const _BpInfoBox({required this.bucket, required this.period});
  final BpVariationBucket bucket;
  final BpPeriod period;
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('bp-chart-tooltip'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xF51A2325),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
      boxShadow: const [
        BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 4)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat(
            period == BpPeriod.day ? 'd MMM · HH:00' : 'EEE, d MMM yyyy',
          ).format(bucket.date),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        if (bucket.readings.isEmpty)
          const Text(
            'No measurements',
            style: TextStyle(color: muted, fontSize: 11),
          )
        else ...[
          for (final sys in [true, false])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(
                    sys ? 'SYS' : 'DIA',
                    style: TextStyle(
                      color: sys ? mint : Colors.orange,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${bucket.average(sys).round()}',
                    style: TextStyle(
                      color: sys ? mint : Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${bucket.minimum(sys)}–${bucket.maximum(sys)} mmHg',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '${bucket.readings.length} readings · average / min–max',
            style: const TextStyle(color: muted, fontSize: 9),
          ),
        ],
      ],
    ),
  );
}

/// Rotate the chart within its route so landscape works with the app's portrait lock.
class BpChartFullscreen extends StatelessWidget {
  const BpChartFullscreen({
    super.key,
    required this.buckets,
    required this.period,
  });
  final List<BpVariationBucket> buckets;
  final BpPeriod period;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF111111),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'BLOOD PRESSURE · ${period.name.toUpperCase()} · mmHg',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close fullscreen blood-pressure chart',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Expanded(
                  child: BpVariationChart(
                    buckets: buckets,
                    period: period,
                    fullscreen: true,
                  ),
                ),
              ],
            ),
          );
          return constraints.maxHeight > constraints.maxWidth
              ? RotatedBox(quarterTurns: 1, child: horizontal)
              : horizontal;
        },
      ),
    ),
  );
}

class _VariationPainter extends CustomPainter {
  _VariationPainter(this.buckets, this.period, this.selected);
  final List<BpVariationBucket> buckets;
  final BpPeriod period;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      for (final b in buckets)
        for (final r in b.readings) ...[r.systolic, r.diastolic],
    ];
    final range = BpAxisRange.fromValues(values);
    final minY = range.minimum;
    final maxY = range.maximum;
    final plot = Rect.fromLTRB(34, 8, size.width - 8, size.height - 28);
    double y(double v) =>
        plot.bottom - (v - minY) / (maxY - minY) * plot.height;
    void text(String value, Offset offset, Color color) {
      final p = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(fontFamily: 'Roboto', fontSize: 9, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(canvas, offset);
    }

    for (double v = minY; v <= maxY; v += 10) {
      canvas.drawLine(
        Offset(plot.left, y(v)),
        Offset(plot.right, y(v)),
        Paint()..color = Colors.white.withValues(alpha: .07),
      );
      text('${v.round()}', Offset(0, y(v) - 5), muted);
    }
    for (final v in [80.0, 120.0, 130.0, 140.0]) {
      if (v < minY || v > maxY) continue;
      canvas.drawLine(
        Offset(plot.left, y(v)),
        Offset(plot.right, y(v)),
        Paint()
          ..color =
              (v == 140
                      ? Colors.red
                      : v == 130
                      ? Colors.amber
                      : mint)
                  .withValues(alpha: .7)
          ..strokeWidth = 1.5,
      );
      text(
        '${v.round()}',
        Offset(0, y(v) - 5),
        v == 140
            ? Colors.red
            : v == 130
            ? Colors.amber
            : mint,
      );
    }
    final step = plot.width / buckets.length;
    // Bands for hours with a workout or without a worn pod, one icon per run.
    for (var i = 0; i < buckets.length;) {
      final mark = buckets[i].mark;
      var j = i;
      while (j + 1 < buckets.length && buckets[j + 1].mark == mark) {
        j++;
      }
      if (mark != BpBucketMark.none) {
        final training = mark == BpBucketMark.training;
        final color = training ? mint : Colors.blueGrey;
        final band = Rect.fromLTRB(
          plot.left + step * i,
          plot.top,
          plot.left + step * (j + 1),
          plot.bottom,
        );
        canvas.drawRect(band, Paint()..color = color.withValues(alpha: .13));
        final icon = training
            ? Icons.directions_run_rounded
            : Icons.watch_off_outlined;
        final painter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              fontSize: 18,
              color: color.withValues(alpha: .8),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        if (band.width >= painter.width) {
          painter.paint(
            canvas,
            Offset(band.center.dx - painter.width / 2, band.center.dy - 9),
          );
        }
      }
      i = j + 1;
    }
    final stride = period == BpPeriod.day
        ? 4
        : period == BpPeriod.month
        ? 5
        : 1;
    // Join the observed averages; empty buckets retain no bars or dots.
    for (final systolic in [true, false]) {
      final path = Path();
      var begun = false;
      for (var i = 0; i < buckets.length; i++) {
        final bucket = buckets[i];
        if (bucket.readings.isEmpty) continue;
        final x =
            plot.left + step * (i + .5) + (systolic ? -1 : 1) * step * .16;
        final py = y(bucket.average(systolic));
        if (!begun) {
          path.moveTo(x, py);
          begun = true;
        } else {
          path.lineTo(x, py);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = (systolic ? mint : Colors.orange).withValues(alpha: .75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
    for (var i = 0; i < buckets.length; i++) {
      final b = buckets[i];
      final x = plot.left + step * (i + .5);
      if (selected == i) {
        canvas.drawRect(
          Rect.fromLTWH(x - step / 2, plot.top, step, plot.height),
          Paint()..color = Colors.white.withValues(alpha: .06),
        );
      }
      if (i % stride == 0 || i == buckets.length - 1) {
        final label = period == BpPeriod.day
            ? '${b.date.hour}h'
            : period == BpPeriod.week
            ? DateFormat('EE').format(b.date)
            : '${b.date.day}';
        text(label, Offset(x - 6, plot.bottom + 9), muted);
      }
      if (b.readings.isEmpty) continue;
      for (final systolic in [true, false]) {
        final bx = x + (systolic ? -1 : 1) * step * .16;
        final color = systolic ? mint : Colors.orange;
        final paint = Paint()
          ..color = color.withValues(alpha: .65)
          ..strokeWidth = math.max(2, math.min(8, step * .22))
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(bx, y(b.minimum(systolic).toDouble())),
          Offset(bx, y(b.maximum(systolic).toDouble())),
          paint,
        );
        canvas.drawCircle(
          Offset(bx, y(b.average(systolic))),
          4.0,
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VariationPainter old) =>
      old.buckets != buckets ||
      old.selected != selected ||
      old.period != period;
}

class _MarkLegend extends StatelessWidget {
  const _MarkLegend(this.icon, this.color, this.text);
  final IconData icon;
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(text, style: const TextStyle(fontSize: 10, color: muted)),
    ],
  );
}
