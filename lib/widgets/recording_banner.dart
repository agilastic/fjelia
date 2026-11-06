import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_ext.dart';
import '../providers/indoor_recording_provider.dart';
import 'app_widgets.dart';
import 'manual_activity_sheet.dart';

/// Shown above the home pages while an activity records in the background:
/// time and state at a glance, one tap back to the recording.
class RecordingBanner extends ConsumerWidget {
  const RecordingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(indoorRecorderProvider);
    final capture = state.capture;
    if (!state.active || capture == null) return const SizedBox.shrink();
    final l = context.l10n;
    final paused = state.phase == IndoorPhase.paused;
    final s = capture.elapsedMs ~/ 1000;
    String two(int v) => v.toString().padLeft(2, '0');
    final time = '${two(s ~/ 3600)}:${two(s ~/ 60 % 60)}:${two(s % 60)}';
    final hr = state.live['hr'];
    final foreground = Colors.black;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Semantics(
        button: true,
        liveRegion: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('recording-banner'),
            borderRadius: BorderRadius.circular(999),
            onTap: () => showAppSheet(context, const ManualActivitySheet()),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: paused
                    ? null
                    : const LinearGradient(colors: [mint, Color(0xFF38BDF8)]),
                color: paused ? const Color(0xFFFFC53D) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    paused ? Icons.pause_rounded : Icons.fiber_manual_record,
                    color: paused ? foreground : const Color(0xFFE0002A),
                    size: paused ? 20 : 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${paused ? l.recordingPaused : l.recLive} · ${capture.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (hr != null && !paused) ...[
                    Icon(Icons.favorite_rounded, size: 14, color: foreground),
                    const SizedBox(width: 3),
                    Text(
                      '${hr.round()}',
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    time,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: l.recBannerOpen,
                    child: Icon(Icons.chevron_right_rounded, color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
