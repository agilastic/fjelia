import '../../theme/activity_colors.dart';
import '../../models/calendar_activity.dart';

import 'package:flutter/material.dart';

Color calendarActivityColor(CalendarActivity activity) =>
    completedActivityColor(activity.sport);

class CalendarActivityBubbles extends StatelessWidget {
  const CalendarActivityBubbles({super.key, required this.activities});
  final List<CalendarActivity> activities;
  @override
  Widget build(BuildContext context) {
    // One bubble per sport/status; the day's tooltip lists every activity.
    final groups = <String, CalendarActivity>{
      for (final activity in activities)
        '${activity.sport}:${activity.completed}:${activity.phase}:${activity.skipped}':
            activity,
    };
    final visible = groups.values.toList();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final activity in visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Semantics(
                label:
                    '${activity.title}, ${activity.sport}, ${activity.statusLabel.toLowerCase()}',
                // A cancelled session is a small cross in its sport's colour,
                // not a dot: it is still in the plan, but it will not happen.
                child: activity.skipped
                    ? Icon(
                        Icons.close,
                        size: 9,
                        color: calendarActivityColor(
                          activity,
                        ).withValues(alpha: .6),
                      )
                    : Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activity.completed
                              ? calendarActivityColor(activity)
                              : Colors.transparent,
                          border: Border.all(
                            color: calendarActivityColor(activity),
                            width: 1.4,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
