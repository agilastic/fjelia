import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/garmin_data.dart';
import 'app_widgets.dart';

/// Stage rows, top to bottom.
const sleepStageOrder = ['awake', 'rem', 'light', 'deep'];

const _stageLabels = {
  'awake': 'AWAKE',
  'rem': 'REM',
  'light': 'LIGHT',
  'deep': 'DEEP',
};

/// Bar colors: white awake, then teal getting darker with depth.
const sleepStageColors = {
  'awake': Color(0xFFFFFFFF),
  'rem': Color(0xFF00BFBF),
  'light': Color(0xFF007B7B),
  'deep': Color(0xFF004A4A),
};

// Label/legend tints readable on the dark panel (deep is too dark as is).
const _stageTextColors = {
  'awake': Color(0xFFFFFFFF),
  'rem': Color(0xFF00BFBF),
  'light': Color(0xFF2FA3A3),
  'deep': Color(0xFF4FA8A8),
};

const _rowHeight = 40.0;
const _labelWidth = 48.0;

String _duration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';
}

String _clock(DateTime t) =>
    DateFormat('h:mm a').format(t.toLocal()).toLowerCase();

/// Sleep stages of one night: a timeline chart (when the night has stage
/// data) and the time and share spent in each stage.
class SleepStagesSection extends StatelessWidget {
  const SleepStagesSection({super.key, required this.sleep});
  final SleepData sleep;

  @override
  Widget build(BuildContext context) {
    final durations = {
      'awake': sleep.awakeSleep,
      'rem': sleep.remSleep,
      'light': sleep.lightSleep,
      'deep': sleep.deepSleep,
    };
    final phases = sleep.phases
        .where((p) => sleepStageColors.containsKey(p.phase))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SLEEP STAGES',
          style: TextStyle(fontSize: 11, color: muted, letterSpacing: 1.2),
        ),
        const SizedBox(height: 14),
        if (phases.isNotEmpty)
          SleepStagesChart(
            phases: phases,
            start: sleep.sleepStart,
            end: sleep.sleepEnd,
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              'No stage timeline for this night.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ),
        SleepStageBreakdown(durations: durations),
      ],
    );
  }
}

/// Time and share per stage with a stacked bar on top.
class SleepStageBreakdown extends StatelessWidget {
  const SleepStageBreakdown({super.key, required this.durations});
  final Map<String, Duration> durations;

  @override
  Widget build(BuildContext context) {
    final total = durations.values.fold<int>(0, (a, d) => a + d.inSeconds);
    if (total <= 0) return const SizedBox.shrink();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (final stage in sleepStageOrder)
                  if (durations[stage]!.inSeconds > 0)
                    Expanded(
                      flex: durations[stage]!.inSeconds,
                      child: ColoredBox(color: sleepStageColors[stage]!),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final stage in sleepStageOrder)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: sleepStageColors[stage],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _stageLabels[stage]!,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: .8,
                    color: _stageTextColors[stage],
                  ),
                ),
                const Spacer(),
                Text(
                  _duration(durations[stage]!),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    '${(durations[stage]!.inSeconds / total * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Hypnogram: one row per stage, a bar for every phase, hour ticks below.
/// Touch or drag to read the stage and time at that point.
class SleepStagesChart extends StatefulWidget {
  const SleepStagesChart({
    super.key,
    required this.phases,
    this.start,
    this.end,
  });

  final List<SleepPhase> phases;
  final DateTime? start, end;

  @override
  State<SleepStagesChart> createState() => _SleepStagesChartState();
}

class _SleepStagesChartState extends State<SleepStagesChart> {
  double? _touchFraction;

  DateTime get _from =>
      widget.start ??
      widget.phases.map((p) => p.start).reduce((a, b) => a.isBefore(b) ? a : b);
  DateTime get _to =>
      widget.end ??
      widget.phases.map((p) => p.end).reduce((a, b) => a.isAfter(b) ? a : b);

  SleepPhase? _phaseAt(DateTime t) {
    for (final p in widget.phases) {
      if (!t.isBefore(p.start) && t.isBefore(p.end)) return p;
    }
    return null;
  }

  void _touch(double dx, double width) =>
      setState(() => _touchFraction = (dx / width).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final from = _from, to = _to;
    final span = to.difference(from).inSeconds;
    if (span <= 0) return const SizedBox.shrink();
    final fraction = _touchFraction;
    final at = fraction == null
        ? null
        : from.add(Duration(seconds: (span * fraction).round()));
    final selected = at == null ? null : _phaseAt(at);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _rowHeight * sleepStageOrder.length + 26,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _labelWidth,
                child: Column(
                  children: [
                    for (final stage in sleepStageOrder)
                      SizedBox(
                        height: _rowHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _stageLabels[stage]!,
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: .6,
                              color: _stageTextColors[stage],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _touch(d.localPosition.dx, c.maxWidth),
                    onHorizontalDragUpdate: (d) =>
                        _touch(d.localPosition.dx, c.maxWidth),
                    child: CustomPaint(
                      size: Size(c.maxWidth, c.maxHeight),
                      painter: _SleepStagesPainter(
                        phases: widget.phases,
                        from: from,
                        to: to,
                        touchFraction: fraction,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 14),
          child: Text(
            selected == null
                ? 'Touch the chart for details'
                : '${_stageLabels[selected.phase]} · ${_clock(selected.start)}'
                      ' – ${_clock(selected.end)} · '
                      '${_duration(selected.end.difference(selected.start))}',
            style: TextStyle(
              fontSize: 12,
              color: selected == null
                  ? muted
                  : _stageTextColors[selected.phase],
            ),
          ),
        ),
      ],
    );
  }
}

class _SleepStagesPainter extends CustomPainter {
  _SleepStagesPainter({
    required this.phases,
    required this.from,
    required this.to,
    this.touchFraction,
  });

  final List<SleepPhase> phases;
  final DateTime from, to;
  final double? touchFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final span = to.difference(from).inMilliseconds.toDouble();
    if (span <= 0) return;
    final grid = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 1;
    for (var i = 0; i <= sleepStageOrder.length; i++) {
      final y = i * _rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (final p in phases) {
      final row = sleepStageOrder.indexOf(p.phase);
      if (row < 0) continue;
      final x0 = p.start.difference(from).inMilliseconds / span * size.width;
      final x1 = p.end.difference(from).inMilliseconds / span * size.width;
      final left = x0.clamp(0.0, size.width);
      final width = (x1.clamp(0.0, size.width) - left).clamp(2.0, size.width);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, row * _rowHeight + 4, width, _rowHeight - 8),
          const Radius.circular(3),
        ),
        Paint()..color = sleepStageColors[p.phase]!,
      );
    }
    // Hour ticks: at most about six labels.
    final hours = to.difference(from).inMinutes / 60;
    final stepHours = hours <= 6 ? 1 : (hours / 6).ceil();
    var tick = DateTime(from.year, from.month, from.day, from.hour + 1);
    final style = const TextStyle(fontSize: 10, color: muted);
    final axisTop = sleepStageOrder.length * _rowHeight + 6;
    var n = 0;
    while (tick.isBefore(to)) {
      if (n % stepHours == 0) {
        final x = tick.difference(from).inMilliseconds / span * size.width;
        final label = TextPainter(
          text: TextSpan(
            text: DateFormat('h a').format(tick).toLowerCase(),
            style: style,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(
          canvas,
          Offset(
            (x - label.width / 2).clamp(0.0, size.width - label.width),
            axisTop,
          ),
        );
      }
      tick = tick.add(const Duration(hours: 1));
      n++;
    }
    final f = touchFraction;
    if (f != null) {
      canvas.drawLine(
        Offset(f * size.width, 0),
        Offset(f * size.width, sleepStageOrder.length * _rowHeight),
        Paint()
          ..color = Colors.white54
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_SleepStagesPainter old) =>
      old.phases != phases ||
      old.from != from ||
      old.to != to ||
      old.touchFraction != touchFraction;
}
