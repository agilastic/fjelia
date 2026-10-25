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
  });
  final String label, value, unit;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final bool showTrend, higherIsBetter, highlighted;
  final double? trendDelta;
  final String? helper;
  @override
  Widget build(BuildContext context) => Material(
    color: highlighted ? const Color(0xFFFF454B) : const Color(0xFF2A2A2A),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: highlighted ? Colors.black : muted),
                const SizedBox(width: 5),
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
                          : const Color(0xFFD9DCE2),
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
            const SizedBox(height: 6),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
  );
}
