import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../l10n/formats.dart';
import '../providers/ecg_provider.dart';
import '../providers/indoor_recording_provider.dart';
import '../theme/fjelia_style.dart';
import 'ecg_sheet.dart';

const _lime = Color(0xFFD3FF62);
const _pink = Color(0xFFFF5C91);
const _cyan = Color(0xFF65E4FF);
const _mint = Color(0xFF00D4A0);

/// The rowing cockpit keeps its four important readings and live ECG together.
/// The smoothing comes from the recorder, so rebuilding or switching the main
/// figure does not change which strokes contribute to it.
class RowingRecordingDashboard extends StatefulWidget {
  const RowingRecordingDashboard({
    super.key,
    required this.state,
    required this.ecg,
    required this.clock,
    required this.availableHeight,
    this.onRestartEcg,
  });

  final IndoorRecorderState state;
  final EcgRecorderState ecg;
  final String clock;
  final double availableHeight;
  final VoidCallback? onRestartEcg;

  @override
  State<RowingRecordingDashboard> createState() => _RowingDashboardState();
}

class _RowingDashboardState extends State<RowingRecordingDashboard> {
  bool _showRate = false;

  String _pace(double? seconds) {
    if (seconds == null ||
        !seconds.isFinite ||
        seconds <= 0 ||
        seconds >= 3600) {
      return '--:--';
    }
    final rounded = seconds.round();
    return '${rounded ~/ 60}:${(rounded % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = widget.state;
    final capture = state.capture!;
    final paused = state.phase == IndoorPhase.paused;
    final compact = widget.availableHeight < 620;
    final pace = paused ? const RowingMetric() : state.rowing.pace;
    final rate = paused ? const RowingMetric() : state.rowing.rate;
    final power = paused ? const RowingMetric() : state.rowing.power;
    final hr = paused ? null : state.live['hr'];
    final primary = _showRate ? rate : pace;
    final value = _showRate ? rate.value?.fixed(0) ?? '—' : _pace(pace.value);
    final alternate = _showRate
        ? '${_pace(pace.value)} /500 m'
        : '${rate.value?.fixed(0) ?? '—'} /min';
    final status = paused
        ? l.recordingPaused
        : state.reconnecting
        ? l.recordingReconnecting
        : state.connected
        ? l.recLive
        : l.recordingInterrupted;
    final signal = paused || !state.connected ? _pink : _mint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.rowing_rounded, color: fjAccent(_lime), size: 20),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                capture.device.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fjInk60, fontSize: 12),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: signal, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fjAccent(signal),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ContextFigure(
                label: l.recordingTime,
                value: widget.clock,
                valueKey: const ValueKey('record-clock'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ContextFigure(
                label: l.recDistanceKm,
                value: capture.totals['d'] == null
                    ? '—'
                    : (capture.distanceMeters / 1000).fixed(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: '${_showRate ? l.rowingStrokeRate : l.recPace500}: $value',
          hint: l.rowingTapToSwitch,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _lime.withValues(alpha: .4)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    duo(0xFF26341F, 0xFFF0F8D9),
                    duo(0xFF171C18, 0xFFFFFFFF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _lime.withValues(alpha: Fjelia.light ? .04 : .07),
                    blurRadius: 22,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                key: const ValueKey('rowing-primary'),
                borderRadius: BorderRadius.circular(28),
                onTap: () => setState(() => _showRate = !_showRate),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (_showRate ? l.rowingStrokeRate : l.recPace500)
                                  .toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: fjAccent(_lime),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                          _AverageBadge(metric: primary),
                        ],
                      ),
                      SizedBox(
                        height: compact ? 88 : 110,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              value,
                              key: const ValueKey('rowing-primary-value'),
                              style: TextStyle(
                                color: fjInk,
                                fontSize: compact ? 94 : 116,
                                fontWeight: FontWeight.w900,
                                height: .95,
                                letterSpacing: -4,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            color: fjAccent(_lime),
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              l.rowingTapToSwitch,
                              style: TextStyle(color: fjInk60, fontSize: 11),
                            ),
                          ),
                          Text(
                            alternate,
                            key: const ValueKey('rowing-secondary-value'),
                            style: TextStyle(
                              color: fjAccent(_lime),
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PerformanceFigure(
                valueKey: const ValueKey('rowing-heart-rate'),
                icon: Icons.favorite_rounded,
                label: l.recHeartRate,
                value: hr?.round().toString() ?? '—',
                unit: 'bpm',
                accent: _pink,
                compact: compact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PerformanceFigure(
                valueKey: const ValueKey('rowing-power'),
                icon: Icons.bolt_rounded,
                label: l.recordingPower,
                value: power.value?.fixed(0) ?? '—',
                unit: 'W',
                accent: _cyan,
                compact: compact,
                average: power,
              ),
            ),
          ],
        ),
        if (capture.ecgDevice != null) ...[
          const SizedBox(height: 12),
          _EcgPanel(
            ecg: widget.ecg,
            capture: capture,
            compact: compact,
            paused: paused,
            onRestart: widget.onRestartEcg,
          ),
        ],
      ],
    );
  }
}

class _ContextFigure extends StatelessWidget {
  const _ContextFigure({
    required this.label,
    required this.value,
    this.valueKey,
  });
  final String label, value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: fjInk60, fontSize: 11)),
      const SizedBox(height: 3),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          key: valueKey,
          style: TextStyle(
            color: fjInk,
            fontSize: 28,
            height: 1,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
  );
}

class _AverageBadge extends StatelessWidget {
  const _AverageBadge({required this.metric});
  final RowingMetric metric;

  @override
  Widget build(BuildContext context) => Text(
    metric.value == null
        ? '—'
        : metric.strokes == 0
        ? context.l10n.recLive
        : context.l10n.rowingStrokeAverage(metric.strokes),
    style: TextStyle(color: fjInk60, fontSize: 11, fontWeight: FontWeight.w600),
  );
}

class _PerformanceFigure extends StatelessWidget {
  const _PerformanceFigure({
    required this.valueKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accent,
    required this.compact,
    this.average,
  });
  final Key valueKey;
  final IconData icon;
  final String label, value, unit;
  final Color accent;
  final bool compact;
  final RowingMetric? average;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: Fjelia.light ? .07 : .09),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: accent.withValues(alpha: .32)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: fjAccent(accent)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fjAccent(accent),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: compact ? 53 : 65,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              key: valueKey,
              style: TextStyle(
                color: fjInk,
                fontSize: compact ? 58 : 70,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        Row(
          children: [
            Text(unit, style: TextStyle(color: fjAccent(accent), fontSize: 13)),
            const Spacer(),
            if (average case final metric?) _AverageBadge(metric: metric),
          ],
        ),
      ],
    ),
  );
}

class _EcgPanel extends StatelessWidget {
  const _EcgPanel({
    required this.ecg,
    required this.capture,
    required this.compact,
    required this.paused,
    this.onRestart,
  });
  final EcgRecorderState ecg;
  final IndoorCapture capture;
  final bool compact, paused;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ownsPreview = capture.ecgRecordingIds.contains(ecg.recordingId);
    return Container(
      key: const ValueKey('rowing-ecg'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: duo(0xFF10211C, 0xFFF2FAF6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _mint.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_rounded,
                color: fjAccent(_mint),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                l.recEcg,
                style: TextStyle(color: fjInk, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  capture.ecgDevice!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fjInk60, fontSize: 11),
                ),
              ),
              Text(
                paused
                    ? l.recordingPaused
                    : ecg.active
                    ? l.recLive
                    : '—',
                style: TextStyle(color: fjAccent(_mint), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RepaintBoundary(
            child: EcgWaveform(
              chunks: ownsPreview ? ecg.preview : const [],
              hz: ecg.rate,
              duration: ownsPreview ? ecg.durationMs / 1000 : 0,
              live: true,
              height: compact ? 88 : 116,
              showControls: false,
              strokeWidth: 2,
            ),
          ),
          if (!paused && !ecg.active)
            TextButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l.manualRestartEcg),
            ),
        ],
      ),
    );
  }
}
