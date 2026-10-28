import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';

import 'app_widgets.dart';

class WeatherRangeSwitcher extends StatelessWidget {
  const WeatherRangeSwitcher({
    super.key,
    required this.days,
    required this.onChanged,
  });
  final int days;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFF1D1F20),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Row(
      children: [
        for (final item in [
          (1, context.l10n.day2, Icons.today_outlined),
          (7, 'WEEK', Icons.view_week_outlined),
          (14, '14 DAYS', Icons.date_range_outlined),
        ])
          Expanded(
            child: Semantics(
              selected: days == item.$1,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => onChanged(item.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 38,
                    decoration: BoxDecoration(
                      color: days == item.$1
                          ? mint.withValues(alpha: .14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: days == item.$1
                            ? mint.withValues(alpha: .25)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.$3,
                          size: 14,
                          color: days == item.$1 ? mint : muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: days == item.$1 ? mint : muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
