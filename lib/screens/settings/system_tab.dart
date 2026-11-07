import '../../widgets/strava_import_sheet.dart';
import '../../providers/activity_history_provider.dart';
import '../../widgets/recently_deleted_sheet.dart';
import '../../l10n/formats.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/data_export_provider.dart';
import '../../models/backup_restore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/user_profile_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../widgets/activity_file_import_sheet.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/settings_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/ecg_provider.dart';
import 'bug_report_sheet.dart';

class SystemTab extends StatelessWidget {
  const SystemTab({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.system,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsGroup(
            dividerIndent: 58,
            children: [
              ListTile(
                leading: const SettingsIcon(
                  Icons.archive_outlined,
                  Colors.blue,
                ),
                title: Text(l10n.dataExport),
                subtitle: Text(l10n.dataExportSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAppSheet(context, const DataExportPage()),
              ),
              ListTile(
                leading: const SettingsIcon(
                  Icons.bug_report_outlined,
                  Colors.orange,
                ),
                title: Text(l10n.developer),
                subtitle: Text(l10n.developerSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAppSheet(context, const DeveloperPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeveloperPage extends ConsumerWidget {
  const DeveloperPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.developer,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionLabel(l10n.debug),
          SwitchListTile(
            title: Text(l10n.debugMode),
            subtitle: Text(l10n.debugModeSubtitle),
            value:
                ref.watch(userProfileProvider).valueOrNull?.debugMode ?? false,
            onChanged: (v) => runUiAction(context, () async {
              final p = await ref.read(userProfileProvider.future);
              await ref
                  .read(userProfileProvider.notifier)
                  .save(p.copyWith(debugMode: v));
            }),
          ),
          SectionLabel(l10n.support),
          ListTile(
            title: Text(l10n.reportBug),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAppSheet(context, const BugReportSheet()),
          ),
        ],
      ),
    );
  }
}

class DataExportPage extends ConsumerStatefulWidget {
  const DataExportPage({super.key});
  @override
  ConsumerState<DataExportPage> createState() => _ExportState();
}

class _ExportState extends ConsumerState<DataExportPage> {
  bool busy = false;
  BackupRestoreProgress? restoreProgress;
  BackupRestoreResult? restoreResult;
  String? restoreError;
  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    await runUiAction(context, action);
    if (mounted) setState(() => busy = false);
  }

  Future<void> share(String path) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SettingsPage(
    title: AppLocalizations.of(context).dataExport,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (busy && restoreProgress == null) const LinearProgressIndicator(),
        if (restoreProgress != null)
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restoreError != null
                      ? context.l10n.restoreFailed
                      : restoreProgress!.stage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: restoreProgress!.fraction,
                  color: mint,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(restoreProgress!.fraction * 100).round()}%'
                  '${restoreProgress!.total > 0 ? ' · ${restoreProgress!.completed} / ${restoreProgress!.total} records' : ''}',
                ),
                if (restoreError != null)
                  Text(
                    restoreError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                if (restoreResult != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${restoreResult!.activities} activities · '
                    '${restoreResult!.plannedSessions} planned sessions · '
                    '${restoreResult!.scheduledWorkouts} scheduled workouts',
                  ),
                  if (restoreResult!.activities == 0 &&
                      restoreResult!.plannedSessions == 0 &&
                      restoreResult!.scheduledWorkouts == 0)
                    Text(context.l10n.thisBackupContainsNoCalendar),
                ],
              ],
            ),
          ),
        SettingsGroup(
          title: context.l10n.activities,
          footer: context.l10n.exportAllRecordedWorkoutsAs,
          children: [
            ListTile(
              enabled: !busy,
              title: Text(context.l10n.ecgExportMetadata),
              leading: const SettingsIcon(Icons.monitor_heart_outlined, mint),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => run(() async {
                final file = await ref
                    .read(ecgStorageProvider)
                    .exportMetadataCsv();
                await share(file.path);
              }),
            ),
            ListTile(
              enabled: !busy,
              title: Text(context.l10n.exportActivitiesCsv),
              leading: const SettingsIcon(Icons.ios_share, mint),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => run(() async {
                final file = await ref
                    .read(activityExportProvider)
                    .exportActivitiesCsv();
                await share(file.path);
              }),
            ),
            ListTile(
              enabled: !busy,
              title: Text(context.l10n.importActivityFile),
              leading: const SettingsIcon(Icons.file_open_outlined, mint),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () =>
                  showAppSheet(context, const ActivityFileImportSheet()),
            ),
            ListTile(
              enabled: !busy,
              title: Text(context.l10n.stravaArchive),
              leading: const SettingsIcon(
                Icons.inventory_2_outlined,
                Color(0xFFFF7A3D),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => showAppSheet(context, const StravaImportSheet()),
            ),
            ListTile(
              enabled: !busy,
              title: Text(context.l10n.recentlyDeleted),
              leading: const SettingsIcon(
                Icons.delete_outline,
                Colors.redAccent,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((ref.watch(deletedActivitiesProvider).valueOrNull ?? [])
                      .isNotEmpty)
                    Text(
                      '${ref.watch(deletedActivitiesProvider).value!.length}',
                      style: TextStyle(color: muted),
                    ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              onTap: () => showAppSheet(context, const RecentlyDeletedSheet()),
            ),
          ],
        ),
        SettingsGroup(
          title: context.l10n.backupRestore,
          dividerIndent: 58,
          footer: context.l10n.backupsIncludeYourHealthData,
          children: [
            ListTile(
              enabled: !busy,
              title: Text(context.l10n.backup),
              leading: const SettingsIcon(Icons.backup_outlined, Colors.blue),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => run(() async {
                final backup = ref.read(backupServiceProvider);
                // Videos can make a backup very large: ask first.
                final videos = await backup.videoSummary();
                var includeVideos = true;
                if (videos.count > 0) {
                  if (!context.mounted) return;
                  final choice = await showDialog<bool>(
                    context: context,
                    builder: (dialog) => AlertDialog(
                      title: Text(context.l10n.backupVideosTitle),
                      content: Text(
                        context.l10n.backupVideosMessage(
                          '${(videos.bytes / 1048576).fixed(0)} MB',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialog, false),
                          child: Text(context.l10n.backupWithoutVideos),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialog, true),
                          child: Text(context.l10n.backupWithVideos),
                        ),
                      ],
                    ),
                  );
                  if (choice == null) return;
                  includeVideos = choice;
                }
                final file = await backup.export(includeVideos: includeVideos);
                await share(file.path);
              }),
            ),
            ListTile(
              enabled: !busy,
              title: Text(
                context.l10n.restoreFromBackup,
                style: TextStyle(color: Colors.red),
              ),
              leading: const SettingsIcon(Icons.restore, Colors.orange),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => run(() async {
                final file = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['zip'],
                );
                if (file.isEmpty) return;
                // A backup with videos is read from disk, not into memory.
                final path = file.single.path;
                final bytes = path == null
                    ? await file.single.xFile.readAsBytes()
                    : null;
                if (!context.mounted ||
                    !await confirmAction(
                      context,
                      context.l10n.replaceLocalData,
                      context.l10n.restoringThisBackupReplacesAll,
                    )) {
                  return;
                }
                setState(() {
                  restoreProgress = BackupRestoreProgress(
                    context.l10n.openingBackupZip,
                    0,
                  );
                  restoreResult = null;
                  restoreError = null;
                });
                try {
                  void onProgress(BackupRestoreProgress progress) {
                    if (mounted) setState(() => restoreProgress = progress);
                  }

                  final backup = ref.read(backupServiceProvider);
                  final result = bytes != null
                      ? await backup.restore(bytes, onProgress: onProgress)
                      : await backup.restoreFile(path!, onProgress: onProgress);
                  if (mounted) setState(() => restoreResult = result);
                } catch (error) {
                  if (mounted) setState(() => restoreError = error.toString());
                  rethrow;
                }
                ref.read(syncStatusListenerProvider.notifier).state++;
                ref.invalidate(userProfileProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.backupRestoredRestartTheApp),
                    ),
                  );
                }
              }),
            ),
          ],
        ),
      ],
    ),
  );
}
