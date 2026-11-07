import '../theme/fjelia_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../db/database.dart';
import '../l10n/formats.dart';
import '../l10n/l10n_ext.dart';
import '../providers/activity_history_provider.dart';
import '../theme/activity_colors.dart';
import 'app_widgets.dart';
import 'strength_widgets.dart' show strengthSourceLabel;

/// Deletes [activity] and offers to undo it. The snack bar outlives the
/// screen it came from, so it keeps what it needs to restore.
Future<void> deleteActivityWithUndo(
  BuildContext context,
  ActivityRecord activity,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final container = ProviderScope.containerOf(context);
  final l10n = context.l10n;
  await container.read(deleteActivityProvider)(activity.activityId);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.activityDeleted(activity.name)),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () =>
              container.read(restoreActivityProvider)(activity.activityId),
        ),
      ),
    );
}

/// Restores a deleted activity and says how it went: back with everything,
/// back while its source sends route and curves, or back from its summary.
Future<void> restoreDeletedActivity(
  BuildContext context,
  WidgetRef ref,
  DeletedActivity d,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;
  final result = await ref.read(restoreActivityProvider)(d.activityId);
  final a = result.activity;
  if (a == null) return;
  final complete = a.metricsJson != null || a.gpxJson != null;
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        complete
            ? l10n.activityRestored(a.name)
            : l10n.activityRestoredSummaryOnly(a.name),
      ),
    ),
  );
}

/// Activities the athlete deleted. They stay deleted through every sync
/// until they are restored here.
class RecentlyDeletedSheet extends ConsumerStatefulWidget {
  const RecentlyDeletedSheet({super.key});
  @override
  ConsumerState<RecentlyDeletedSheet> createState() => _DeletedState();
}

class _DeletedState extends ConsumerState<RecentlyDeletedSheet> {
  final _restoring = <String>{};

  Future<void> _restore(DeletedActivity d) async {
    setState(() => _restoring.add(d.activityId));
    try {
      await restoreDeletedActivity(context, ref, d);
    } finally {
      if (mounted) setState(() => _restoring.remove(d.activityId));
    }
  }

  @override
  Widget build(BuildContext context) => SheetPage(
    title: context.l10n.recentlyDeleted,
    child: ref
        .watch(deletedActivitiesProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => DataError(e),
          data: (rows) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                context.l10n.recentlyDeletedExplain,
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 48, color: muted),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.noDeletedActivities,
                        style: TextStyle(color: muted),
                      ),
                    ],
                  ),
                ),
              for (final d in rows)
                _DeletedTile(
                  deleted: d,
                  busy: _restoring.contains(d.activityId),
                  onRestore: () => _restore(d),
                ),
            ],
          ),
        ),
  );
}

class _DeletedTile extends StatelessWidget {
  const _DeletedTile({
    required this.deleted,
    required this.busy,
    required this.onRestore,
  });

  final DeletedActivity deleted;
  final bool busy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final d = deleted;
    final color = completedActivityColor(d.type);
    final minutes = (d.durationSeconds / 60).round();
    final when = DateFormat.yMMMd().add_Hm().format(d.startDate.toLocal());
    final facts = [
      minutes >= 60 ? '${minutes ~/ 60} h ${minutes % 60} min' : '$minutes min',
      if ((d.distanceMeters ?? 0) > 0)
        '${(d.distanceMeters! / 1000).fixed(1)} km',
    ].join(' · ');
    final source = strengthSourceLabel(d.source);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fjInk10),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(activitySportIcon(d.type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(when, style: TextStyle(color: fjInk70, fontSize: 12)),
                  Text(facts, style: TextStyle(color: fjInk70, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      ?source,
                      context.l10n.deletedOn(
                        DateFormat.yMMMd().format(d.deletedAt.toLocal()),
                      ),
                    ].join(' · '),
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filledTonal(
                    tooltip: context.l10n.restore,
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore),
                  ),
          ],
        ),
      ),
    );
  }
}
