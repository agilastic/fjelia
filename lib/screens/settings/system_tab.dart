import '../../l10n/l10n_ext.dart';
import '../../providers/data_export_provider.dart';
import '../../models/backup_restore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/user_profile_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/settings_widgets.dart';
import '../../l10n/app_localizations.dart';
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
                final file = await ref.read(backupServiceProvider).export();
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
                final bytes = await file.single.xFile.readAsBytes();
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
                  final result = await ref
                      .read(backupServiceProvider)
                      .restore(
                        bytes,
                        onProgress: (progress) {
                          if (mounted) {
                            setState(() => restoreProgress = progress);
                          }
                        },
                      );
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
