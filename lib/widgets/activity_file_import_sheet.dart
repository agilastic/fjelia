import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/formats.dart';
import '../l10n/l10n_ext.dart';
import '../providers/activity_file_import_provider.dart';
import '../screens/planner/plan_week_agenda.dart' show sportLabel;
import 'app_widgets.dart';
import 'strength_widgets.dart' show strengthSourceLabel;

/// Imports workouts from FIT, GPX or TCX files: chosen here, or opened in
/// Fjelia from the share sheet ([files]).
class ActivityFileImportSheet extends ConsumerStatefulWidget {
  const ActivityFileImportSheet({super.key, this.files});

  final List<PickedActivityFile>? files;

  @override
  ConsumerState<ActivityFileImportSheet> createState() => _State();
}

class _State extends ConsumerState<ActivityFileImportSheet> {
  List<ActivityFilePreview>? previews;
  int? added;
  bool busy = false;
  String? error;

  ActivityFileImportActions get _actions =>
      ref.read(activityFileImportActionsProvider);

  @override
  void initState() {
    super.initState();
    final files = widget.files;
    if (files != null) _read(() async => files);
  }

  Future<void> _read(Future<List<PickedActivityFile>> Function() files) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final picked = await files();
      if (picked.isEmpty) return;
      final result = await _actions.previews(picked);
      if (mounted) setState(() => previews = result);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _import(List<ActivityFilePreview> all) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final count = await _actions.import(all);
      if (mounted) setState(() => added = count);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = previews;
    final importable = all?.where((p) => p.canImport).length ?? 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(l10n.importActivityFile),
            const SizedBox(height: 8),
            Text(
              l10n.activityFileImportHint,
              style: TextStyle(color: muted, fontSize: 12),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            if (all != null)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [for (final p in all) _PreviewTile(p)],
                ),
              ),
            const SizedBox(height: 12),
            if (added != null) ...[
              Text(l10n.activitiesImported(added!)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.done),
              ),
            ] else if (all != null) ...[
              FilledButton(
                onPressed: busy || importable == 0 ? null : () => _import(all),
                child: Text(
                  busy ? l10n.importing : l10n.importActivities(importable),
                ),
              ),
              TextButton(
                onPressed: busy ? null : () => _read(_actions.pick),
                child: Text(l10n.chooseOtherFiles),
              ),
            ] else
              FilledButton.icon(
                onPressed: busy ? null : () => _read(_actions.pick),
                icon: const Icon(Icons.file_open_outlined),
                label: Text(busy ? l10n.reading : l10n.chooseActivityFiles),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile(this.preview);
  final ActivityFilePreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final file = preview.file;
    final duplicate = preview.duplicateSource;
    final status = file == null
        ? l10n.activityFileUnreadable
        : preview.alreadyImported
        ? l10n.activityFileAlreadyImported
        : duplicate != null
        ? l10n.activityFileAlreadyFrom(
            strengthSourceLabel(duplicate) ?? duplicate,
          )
        : null;
    final facts = file == null
        ? preview.fileName
        : [
            '${sportLabel(file.type)} · ${file.format}',
            DateFormat.yMMMd().add_Hm().format(file.start.toLocal()),
            _duration(file.durationSeconds),
            if (file.distanceMeters != null)
              '${(file.distanceMeters! / 1000).fixed(1)} km',
            if (file.avgHeartRate != null) '${file.avgHeartRate!.round()} bpm',
            if (file.avgWatts != null) '${file.avgWatts!.round()} W',
          ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        preview.canImport
            ? Icons.check_circle_outline
            : Icons.remove_circle_outline,
        color: preview.canImport ? Colors.greenAccent : muted,
      ),
      title: Text(file?.name ?? preview.fileName),
      subtitle: Text(
        status == null ? facts : '$facts\n$status',
        style: TextStyle(fontSize: 12, color: muted),
      ),
    );
  }

  static String _duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }
}
