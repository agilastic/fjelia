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
import 'bug_report_sheet.dart';

class SystemTab extends StatelessWidget {
  const SystemTab({super.key});
  @override
  Widget build(BuildContext context) => SettingsPage(
    title: 'System',
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsGroup(
          dividerIndent: 58,
          children: [
            ListTile(
              leading: const SettingsIcon(Icons.archive_outlined, Colors.blue),
              title: const Text('Data Export'),
              subtitle: const Text('CSV export, backup & restore'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAppSheet(context, const DataExportPage()),
            ),
            ListTile(
              leading: const SettingsIcon(
                Icons.bug_report_outlined,
                Colors.orange,
              ),
              title: const Text('Developer'),
              subtitle: const Text('Debug mode, diagnostics'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAppSheet(context, const DeveloperPage()),
            ),
          ],
        ),
      ],
    ),
  );
}

class DeveloperPage extends ConsumerWidget {
  const DeveloperPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsPage(
    title: 'Developer',
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionLabel('Debug'),
        SwitchListTile(
          title: const Text('Debug mode'),
          subtitle: const Text('Shows the DEBUG tab'),
          value: ref.watch(userProfileProvider).valueOrNull?.debugMode ?? false,
          onChanged: (v) => runUiAction(context, () async {
            final p = await ref.read(userProfileProvider.future);
            await ref
                .read(userProfileProvider.notifier)
                .save(p.copyWith(debugMode: v));
          }),
        ),
        const SectionLabel('Support'),
        ListTile(
          title: const Text('Report a bug'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showAppSheet(context, const BugReportSheet()),
        ),
      ],
    ),
  );
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
    title: 'Data Export',
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
                      ? 'Restore failed'
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
                    const Text('This backup contains no calendar activities.'),
                ],
              ],
            ),
          ),
        SettingsGroup(
          title: 'Activities',
          footer: 'Export all recorded workouts as a spreadsheet.',
          children: [
            ListTile(
              enabled: !busy,
              title: const Text('Export activities CSV'),
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
          title: 'Backup & restore',
          dividerIndent: 58,
          footer: 'Backups include your health data, training plans and profile settings. Login credentials are excluded. Restoring replaces local data.',
          children: [
            ListTile(
              enabled: !busy,
              title: const Text('Backup'),
              leading: const SettingsIcon(Icons.backup_outlined, Colors.blue),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => run(() async {
                final file = await ref.read(backupServiceProvider).export();
                await share(file.path);
              }),
            ),
            ListTile(
              enabled: !busy,
              title: const Text(
                'Restore from backup',
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
                      'Replace local data?',
                      'Restoring this backup replaces all local health and training records. Existing login credentials are kept.',
                    )) {
                  return;
                }
                setState(() {
                  restoreProgress = const BackupRestoreProgress(
                    'Opening backup ZIP',
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
                    const SnackBar(
                      content: Text(
                        'Backup restored. Restart the app to reload all settings.',
                      ),
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
