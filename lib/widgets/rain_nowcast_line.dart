import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_ext.dart';
import '../providers/plan_weather_provider.dart';
import '../services/rain_nowcast.dart';
import 'app_widgets.dart';

/// One line from the DWD radar: rain soon, raining and when it stops, or dry
/// for the next hour. Nothing outside Germany or without a radar answer.
class RainNowcastLine extends ConsumerStatefulWidget {
  const RainNowcastLine({super.key, this.padding = EdgeInsets.zero});
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<RainNowcastLine> createState() => _RainNowcastLineState();
}

class _RainNowcastLineState extends ConsumerState<RainNowcastLine> {
  // The radar moves on every 5 minutes; so does the line while it shows.
  late final Timer _refresh = Timer.periodic(
    const Duration(minutes: 5),
    (_) => ref.invalidate(rainNowcastProvider),
  );

  @override
  void initState() {
    super.initState();
    _refresh;
  }

  @override
  void dispose() {
    _refresh.cancel();
    super.dispose();
  }

  /// Minutes rounded to 5, at least 5.
  static int _minutes(Duration d) {
    final m = (d.inSeconds / 300).round() * 5;
    return m < 5 ? 5 : m;
  }

  @override
  Widget build(BuildContext context) {
    final nowcast = ref.watch(rainNowcastProvider).valueOrNull;
    if (nowcast == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final (icon, text, wet) = switch (nowcast.outlook(DateTime.now())) {
      NowcastUnknown() => (null, null, false),
      NowcastDry(:final horizon) => (
        Icons.wb_cloudy_outlined,
        l10n.nowcastDry(_minutes(horizon)),
        false,
      ),
      NowcastRainSoon(:final after) => (
        Icons.umbrella,
        l10n.nowcastRainSoon(_minutes(after)),
        true,
      ),
      NowcastRaining(:final stopsIn?) => (
        Icons.umbrella,
        l10n.nowcastRainingStops(_minutes(stopsIn)),
        true,
      ),
      NowcastRaining(:final horizon) => (
        Icons.umbrella,
        l10n.nowcastRainingOn(_minutes(horizon)),
        true,
      ),
    };
    if (icon == null || text == null) return const SizedBox.shrink();
    final color = wet ? Colors.lightBlueAccent : muted;
    return Padding(
      padding: widget.padding,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: wet ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text('DWD', style: TextStyle(fontSize: 9, color: muted)),
        ],
      ),
    );
  }
}
