import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/formats.dart';
import '../l10n/l10n_ext.dart';
import '../providers/strava_import_provider.dart';
import '../services/strava_archive_import.dart' show StravaPreview;
import 'activity_file_import_sheet.dart';
import 'app_widgets.dart';

const _accent = Color(0xFFFF7A3D);

/// What can be imported: a whole Strava archive, or single activity files.
/// Built to take more archive formats later.
class ImportSheet extends StatelessWidget {
  const ImportSheet({super.key});

  @override
  Widget build(BuildContext context) => SheetPage(
    title: context.l10n.importTitle,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final (icon, color, title, subtitle, page) in [
          (
            Icons.inventory_2_outlined,
            _accent,
            context.l10n.stravaArchiveZip,
            context.l10n.stravaArchiveSubtitle,
            const StravaImportSheet() as Widget,
          ),
          (
            Icons.file_open_outlined,
            mint,
            context.l10n.importActivityFile,
            'FIT · GPX · TCX',
            const ActivityFileImportSheet() as Widget,
          ),
        ])
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: color),
              title: Text(title),
              subtitle: Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAppSheet(context, page),
            ),
          ),
      ],
    ),
  );
}

/// The Strava archive import: choose the ZIP, see what it holds, import,
/// read the result.
class StravaImportSheet extends ConsumerWidget {
  const StravaImportSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stravaImportProvider);
    final actions = ref.read(stravaImportProvider.notifier);
    final l10n = context.l10n;
    return SheetPage(
      title: l10n.stravaArchive,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: switch (s.phase) {
          StravaImportPhase.idle => [
            _Hero(icon: Icons.inventory_2_outlined, text: l10n.stravaIntro),
            const SizedBox(height: 14),
            _Note(l10n.stravaHowTo),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => runUiAction(context, actions.pick),
              icon: const Icon(Icons.folder_zip_outlined),
              label: Text(l10n.stravaChooseZip),
            ),
          ],
          StravaImportPhase.reading => [
            const SizedBox(height: 60),
            const Center(child: CircularProgressIndicator(color: _accent)),
            const SizedBox(height: 16),
            Center(child: Text(l10n.stravaReading)),
          ],
          StravaImportPhase.preview => _preview(context, s.preview!, actions),
          StravaImportPhase.importing => _progress(context, s, actions),
          StravaImportPhase.done ||
          StravaImportPhase.failed => _summary(context, s, actions),
        },
      ),
    );
  }

  List<Widget> _preview(
    BuildContext context,
    StravaPreview p,
    StravaImportNotifier actions,
  ) {
    final l10n = context.l10n;
    final known = p.alreadyImported + p.duplicates;
    return [
      _Hero(
        icon: Icons.fact_check_outlined,
        text: l10n.stravaFound(p.activities),
      ),
      const SizedBox(height: 12),
      _Stats([
        (Icons.route_outlined, l10n.stravaWithFiles(p.withFile), mint),
        (
          Icons.photo_library_outlined,
          l10n.stravaPhotos(p.photos, p.videos),
          Colors.lightBlueAccent,
        ),
        if (known > 0)
          (Icons.layers_outlined, l10n.stravaAlready(known), Colors.amber),
        if (p.deleted > 0)
          (Icons.delete_outline, l10n.stravaDeletedSkip(p.deleted), muted),
        (Icons.add_circle_outline, l10n.stravaNew(p.toImport), _accent),
        (
          Icons.sd_storage_outlined,
          l10n.stravaStorage((p.storageBytes / 1e6).round()),
          muted,
        ),
      ]),
      const SizedBox(height: 12),
      _Note(l10n.stravaPrivacy),
      const SizedBox(height: 20),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _accent),
        onPressed: actions.start,
        child: Text(l10n.stravaImportButton(p.toImport)),
      ),
      TextButton(onPressed: actions.reset, child: Text(l10n.cancel)),
    ];
  }

  List<Widget> _progress(
    BuildContext context,
    StravaImportState s,
    StravaImportNotifier actions,
  ) {
    final l10n = context.l10n;
    final p = s.progress!;
    final share = p.total == 0 ? 0.0 : p.processed / p.total;
    return [
      _Hero(icon: Icons.downloading, text: l10n.stravaImporting),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: share,
          minHeight: 10,
          color: _accent,
          backgroundColor: Colors.white12,
        ),
      ),
      const SizedBox(height: 14),
      _Stats([
        (
          Icons.directions_run,
          l10n.stravaProgressActivities(p.processed.fixed(0), p.total.fixed(0)),
          _accent,
        ),
        (
          Icons.check_circle_outline,
          l10n.stravaImportedCount(p.imported),
          mint,
        ),
        (
          Icons.photo_library_outlined,
          l10n.stravaProgressPhotos(p.photos),
          Colors.lightBlueAccent,
        ),
        (
          Icons.layers_outlined,
          l10n.stravaProgressDuplicates(p.duplicates + p.alreadyImported),
          Colors.amber,
        ),
        if (p.deleted > 0)
          (Icons.delete_outline, l10n.stravaProgressDeleted(p.deleted), muted),
        if (p.failed > 0)
          (
            Icons.error_outline,
            l10n.stravaProgressErrors(p.failed),
            Colors.redAccent,
          ),
      ]),
      const SizedBox(height: 12),
      _Note(l10n.stravaKeepOpen),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: actions.cancel, child: Text(l10n.cancel)),
    ];
  }

  List<Widget> _summary(
    BuildContext context,
    StravaImportState s,
    StravaImportNotifier actions,
  ) {
    final l10n = context.l10n;
    final p = s.progress;
    if (p == null) {
      return [
        _Hero(
          icon: Icons.error_outline,
          color: Colors.redAccent,
          text: s.error == 'notStrava' ? l10n.stravaNotArchive : '${s.error}',
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: actions.reset, child: Text(l10n.tryAgain)),
      ];
    }
    final title = p.cancelled
        ? l10n.stravaCancelled
        : p.complete
        ? l10n.stravaComplete
        : l10n.stravaPartial;
    final color = p.complete ? mint : Colors.amber;
    return [
      _Hero(
        icon: p.complete ? Icons.task_alt : Icons.warning_amber_rounded,
        color: color,
        text: title,
      ),
      const SizedBox(height: 12),
      _Stats([
        (Icons.fact_check_outlined, l10n.stravaFound(p.total), muted),
        (
          Icons.check_circle_outline,
          l10n.stravaImportedCount(p.imported),
          mint,
        ),
        (
          Icons.layers_outlined,
          l10n.stravaProgressDuplicates(p.duplicates + p.alreadyImported),
          Colors.amber,
        ),
        if (p.deleted > 0)
          (Icons.delete_outline, l10n.stravaProgressDeleted(p.deleted), muted),
        (
          Icons.photo_library_outlined,
          l10n.stravaProgressPhotos(p.photos),
          Colors.lightBlueAccent,
        ),
        if (p.failed > 0)
          (
            Icons.error_outline,
            l10n.stravaProgressErrors(p.failed),
            Colors.redAccent,
          ),
      ]),
      if (p.errors.isNotEmpty) ...[
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.stravaShowErrors),
            children: [
              for (final e in p.errors.take(200))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    e,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
      if (!p.complete) ...[
        const SizedBox(height: 8),
        _Note(l10n.stravaAgainHint),
      ],
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () {
          actions.reset();
          Navigator.of(context).maybePop();
        },
        child: Text(l10n.done),
      ),
    ];
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.text, this.color = _accent});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: .25), panel],
      ),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 34),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _Stats extends StatelessWidget {
  const _Stats(this.items);
  final List<(IconData, String, Color)> items;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      children: [
        for (final (icon, text, color) in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(text)),
              ],
            ),
          ),
      ],
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: muted, fontSize: 12, height: 1.4),
  );
}
