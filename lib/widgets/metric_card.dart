import '../theme/fjelia_style.dart';
import 'trend_arrow.dart';

import 'package:flutter/material.dart';

import 'app_widgets.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.icon = Icons.favorite_border,
    this.onTap,
    this.color = mint,
    this.showTrend = false,
    this.trendDelta,
    this.higherIsBetter = true,
    this.helper,
    this.highlighted = false,
    this.accent,
  });
  final String label, value, unit;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final bool showTrend, higherIsBetter, highlighted;
  final double? trendDelta;
  final String? helper;

  /// The metric's own colour: a round glowing badge for the icon, a faint
  /// light from the corner and a tinted edge.
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    final glow = highlighted ? null : accent;
    return Material(
      color: highlighted
          ? const Color(0xFFFF454B)
          : glow == null
          ? duo(0xFF2A2A2A, 0xFFEEF1F5)
          : duo(0xFF1E1F22, 0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: glow == null
            ? BorderSide.none
            : BorderSide(color: glow.withValues(alpha: .16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: glow == null
            ? null
            : BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.3,
                  colors: [glow.withValues(alpha: .09), Colors.transparent],
                ),
              ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (glow == null)
                      Icon(
                        icon,
                        size: 13,
                        color: highlighted ? Colors.black : muted,
                      )
                    else
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: glow.withValues(alpha: .16),
                          boxShadow: [
                            BoxShadow(
                              color: glow.withValues(alpha: .18),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 12, color: fjAccent(glow)),
                      ),
                    SizedBox(width: glow == null ? 5 : 7),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                          color: highlighted
                              ? Colors.black
                              : duo(0xFFD9DCE2, 0xFF1F2937),
                        ),
                      ),
                    ),
                    if (onTap != null && !showTrend)
                      Icon(
                        Icons.chevron_right,
                        size: 12,
                        color: highlighted ? Colors.black : muted,
                      ),
                  ],
                ),
                SizedBox(height: glow == null ? 6 : 3),
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        TextSpan(
                          children: [
                            TextSpan(
                              text: value,
                              style: TextStyle(
                                fontSize: glow == null ? 16 : 18,
                                fontWeight: glow == null
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: highlighted ? Colors.black : color,
                              ),
                            ),
                            TextSpan(
                              text: ' $unit',
                              style: TextStyle(
                                fontSize: 10,
                                color: highlighted ? Colors.black : muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showTrend)
                      TrendArrow(
                        delta: trendDelta,
                        color: highlighted
                            ? Colors.black
                            : trendDelta == null || trendDelta!.abs() < .01
                            ? muted
                            : (trendDelta! > 0) == higherIsBetter
                            ? mint
                            : Colors.orange,
                      ),
                  ],
                ),
                if (helper != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      helper!,
                      style: TextStyle(
                        color: highlighted ? Colors.black : muted,
                        fontSize: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
