import '../theme/fjelia_style.dart';
import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/garmin_data.dart';
import 'app_widgets.dart';

/// Stage rows, top to bottom.
const sleepStageOrder = ['awake', 'rem', 'light', 'deep'];

Map<String, String> get _stageLabels => {
  'awake': tr.awake,
  'rem': 'REM',
  'light': tr.light,
  'deep': tr.deep2,
};

/// Bar colors: white awake, then teal getting darker with depth.
Map<String, Color> get sleepStageColors => {
  'awake': duo(0xFFFFFFFF, 0xFF15171A),
  'rem': Color(0xFF00BFBF),
  'light': Color(0xFF007B7B),
  'deep': Color(0xFF004A4A),
};

// Label/legend tints readable on the dark panel (deep is too dark as is).
Map<String, Color> get _stageTextColors => {
  'awake': duo(0xFFFFFFFF, 0xFF15171A),
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

String _clock(DateTime t) => DateFormat.jm().format(t.toLocal()).toLowerCase();

String _sleepSourceLabel(BuildContext context, String source) {
  final normalized = source.toLowerCase();
  if (normalized == 'fjelia_ecg') {
    return 'Fjelia · Polar H10 · ${context.l10n.estimated}';
  }
  if (normalized.contains('garmin')) return 'Garmin';
  if (normalized.contains('coros')) return 'COROS';
  if (normalized.contains('polar')) return 'Polar';
  if (normalized.contains('suunto')) return 'Suunto';
  if (normalized.contains('aktiia') || normalized.contains('hilo')) {
    return 'Hilo / Aktiia';
  }
  if (normalized.contains('health')) return 'Apple Health';
  return source;
}

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
        Text(
          context.l10n.sleepStages,
          style: TextStyle(fontSize: 11, color: muted, letterSpacing: 1.2),
        ),
        const SizedBox(height: 14),
        if (phases.isNotEmpty)
          SleepStagesChart(
            phases: phases,
            start: sleep.sleepStart,
            end: sleep.sleepEnd,
          ),
        if (phases.isNotEmpty && sleep.phasesEstimated)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.l10n.stagesEstimated,
                    style: TextStyle(fontSize: 11, color: muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        if (sleep.source != null && sleep.source!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: Text(
              context.l10n.source(_sleepSourceLabel(context, sleep.source!)),
              style: TextStyle(fontSize: 10, color: muted, height: 1.3),
            ),
          ),
        if (phases.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              context.l10n.noStageTimelineForThis,
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
                    context.l10n.round3(
                      (durations[stage]!.inSeconds / total * 100).round(),
                    ),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, color: muted),
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

  /// Keep the rendered hypnogram exclusive even if an upstream source sends
  /// overlapping intervals. A new stage takes over at its own start time;
  /// gaps remain gaps instead of being filled with invented stages.
  List<SleepPhase> get _chartPhases {
    final source = widget.phases
        .where(
          (p) =>
              sleepStageColors.containsKey(p.phase) && p.end.isAfter(p.start),
        )
        .toList();
    final boundaries =
        source
            .expand(
              (p) => [
                p.start.millisecondsSinceEpoch,
                p.end.millisecondsSinceEpoch,
              ],
            )
            .toSet()
            .toList()
          ..sort();
    final normalized = <SleepPhase>[];
    for (var i = 0; i + 1 < boundaries.length; i++) {
      final startMs = boundaries[i], endMs = boundaries[i + 1];
      if (endMs <= startMs) continue;
      final active =
          source
              .where(
                (p) =>
                    p.start.millisecondsSinceEpoch <= startMs &&
                    p.end.millisecondsSinceEpoch >= endMs,
              )
              .toList()
            ..sort((a, b) => a.start.compareTo(b.start));
      if (active.isEmpty) continue;
      final stage = active.last.phase;
      final start = DateTime.fromMillisecondsSinceEpoch(
        startMs,
        isUtc: active.last.start.isUtc,
      );
      final end = DateTime.fromMillisecondsSinceEpoch(
        endMs,
        isUtc: active.last.start.isUtc,
      );
      if (normalized.isNotEmpty &&
          normalized.last.phase == stage &&
          normalized.last.end.isAtSameMomentAs(start)) {
        normalized[normalized.length - 1] = SleepPhase(
          normalized.last.start,
          end,
          stage,
        );
      } else {
        normalized.add(SleepPhase(start, end, stage));
      }
    }
    return normalized;
  }

  DateTime get _from =>
      widget.start ??
      widget.phases.map((p) => p.start).reduce((a, b) => a.isBefore(b) ? a : b);
  DateTime get _to =>
      widget.end ??
      widget.phases.map((p) => p.end).reduce((a, b) => a.isAfter(b) ? a : b);

  SleepPhase? _phaseAt(DateTime t) {
    for (final p in _chartPhases) {
      if (!t.isBefore(p.start) && t.isBefore(p.end)) return p;
    }
    return null;
  }

  void _touch(double dx, double width) =>
      setState(() => _touchFraction = (dx / width).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final phases = _chartPhases;
    if (phases.isEmpty) return const SizedBox.shrink();
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
                        phases: phases,
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
                ? context.l10n.touchTheChartForDetails
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
      ..color = duo(0xFF333333, 0xFFE3E7EC)
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
      final width = x1.clamp(0.0, size.width) - left;
      if (width <= 0) continue;
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
    final style = TextStyle(fontSize: 10, color: muted);
    final axisTop = sleepStageOrder.length * _rowHeight + 6;
    var n = 0;
    while (tick.isBefore(to)) {
      if (n % stepHours == 0) {
        final x = tick.difference(from).inMilliseconds / span * size.width;
        final label = TextPainter(
          text: TextSpan(
            text: DateFormat.j().format(tick).toLowerCase(),
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
          ..color = fjInk54
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
