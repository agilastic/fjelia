import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/plan_view_provider.dart';
import 'app_widgets.dart';

class PlanViewSwitcher extends ConsumerWidget {
  const PlanViewSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(planViewProvider).valueOrNull ?? 'list';
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in const [
            ('month', 'Month view', Icons.calendar_month_rounded),
            ('week', 'Week view', Icons.view_week_rounded),
            ('list', 'List view', Icons.format_list_bulleted_rounded),
          ])
            Semantics(
              selected: view == item.$1,
              child: Tooltip(
                message: item.$2,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        ref.read(planViewProvider.notifier).setView(item.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: 44,
                      height: 42,
                      decoration: BoxDecoration(
                        color: view == item.$1
                            ? mint.withValues(alpha: .14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: view == item.$1
                              ? mint.withValues(alpha: .25)
                              : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        item.$3,
                        size: 21,
                        color: view == item.$1 ? mint : const Color(0xFF8D9295),
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
}
