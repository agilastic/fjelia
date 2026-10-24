import 'package:flutter/material.dart';

import '../models/workout_profile.dart';
import 'app_widgets.dart';

/// Colour of intensity zone 1 to 5.
const workoutZoneColors = [
  Color(0xFF4FC3F7),
  Color(0xFF00D4A0),
  Color(0xFFFFCC00),
  Color(0xFFFF9800),
  Color(0xFFFF5252),
];

/// The course of a workout as blocks: the width of a block is its duration,
/// its height and colour the intensity zone. Tapping a block shows what it is.
class WorkoutProfileBar extends StatefulWidget {
  const WorkoutProfileBar({super.key, required this.blocks, this.height = 96});

  final List<WorkoutBlock> blocks;
  final double height;

  @override
  State<WorkoutProfileBar> createState() => _State();
}

class _State extends State<WorkoutProfileBar> {
  int? selected;

  double _factor(int zone) => .28 + .18 * zone;

  String get _summary {
    final total = widget.blocks.fold<double>(0, (sum, b) => sum + b.seconds);
    final zones = widget.blocks.map((b) => b.zone).toSet().toList()..sort();
    final range = zones.length == 1
        ? 'Z${zones.first}'
        : 'Z${zones.first}–Z${zones.last}';
    final estimated = widget.blocks.any((b) => b.estimated);
    return '${estimated ? '≈ ' : ''}${formatBlockDuration(total)} · $range';
  }

  @override
  Widget build(BuildContext context) {
    final blocks = widget.blocks;
    if (blocks.isEmpty) return const SizedBox.shrink();
    final block = selected == null ? null : blocks[selected!];
    final description = [
      for (final b in blocks)
        '${b.label} ${b.duration} zone ${b.zone}${b.estimated ? ' estimated' : ''}',
    ].join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Workout profile: $description',
          child: SizedBox(
            height: widget.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < blocks.length; i++)
                  Expanded(
                    flex: blocks[i].seconds.round().clamp(1, 1000000),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          setState(() => selected = selected == i ? null : i),
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i == blocks.length - 1 ? 0 : 2,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: _factor(blocks[i].zone),
                            widthFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    workoutZoneColors[blocks[i].zone - 1],
                                    workoutZoneColors[blocks[i].zone - 1]
                                        .withValues(alpha: .55),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                                border: selected == i
                                    ? Border.all(color: Colors.white, width: 2)
                                    : blocks[i].estimated
                                    ? Border.all(color: Colors.white38)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          block == null
              ? _summary
              : '${block.label} · ${block.estimated ? '≈ ' : ''}${block.duration} · Z${block.zone}'
                    '${block.estimated ? ' · estimated length' : ''}',
          style: TextStyle(
            fontSize: 12,
            color: block == null ? muted : Colors.white,
            fontWeight: block == null ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
