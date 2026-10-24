import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/day_data_provider.dart';

class DayNavigator extends ConsumerWidget {
  const DayNavigator({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(selectedDateProvider), n = DateTime.now();
    void move(int x) => ref.read(selectedDateProvider.notifier).state =
        DateTime(d.year, d.month, d.day + x);
    final today = DateTime(n.year, n.month, n.day);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous day',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF333333),
            minimumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          onPressed: () => move(-1),
          icon: const Icon(Icons.chevron_left, size: 18),
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: d.isAfter(today) ? today : d,
              firstDate: DateTime(2000),
              lastDate: today,
            );
            if (picked != null) {
              ref.read(selectedDateProvider.notifier).state = picked;
            }
          },
          child: Text(
            d.year == n.year && d.month == n.month && d.day == n.day
                ? 'TODAY'
                : DateFormat('d MMM').format(d).toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next day',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF282828),
            disabledBackgroundColor: const Color(0xFF282828),
            minimumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          onPressed: d.isBefore(today) ? () => move(1) : null,
          icon: const Icon(Icons.chevron_right, size: 18),
        ),
      ],
    );
  }
}
