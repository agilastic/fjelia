import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../services/activity_file_import_service.dart';
import '../utils/log.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'hr_zones_provider.dart';
import 'hrv_training_provider.dart';
import 'missed_workout_provider.dart';
import 'sync_provider.dart';

export '../services/activity_file_import_service.dart'
    show ActivityFilePreview, ActivityFile;

/// A file to import: its name and content.
typedef PickedActivityFile = ({String name, Uint8List bytes});

final activityFileImportActionsProvider = Provider<ActivityFileImportActions>(
  ActivityFileImportActions.new,
);

class ActivityFileImportActions {
  ActivityFileImportActions(this.ref);
  final Ref ref;

  ActivityFileImportService get _service =>
      ActivityFileImportService(ref.read(databaseProvider));

  /// Lets the athlete choose activity files; empty when nothing was chosen.
  Future<List<PickedActivityFile>> pick() async {
    final files = await FilePicker.pickFiles();
    return [
      for (final f in files) (name: f.name, bytes: await f.xFile.readAsBytes()),
    ];
  }

  /// Previews every file; a ZIP stands for the activity files inside it.
  Future<List<ActivityFilePreview>> previews(
    List<PickedActivityFile> files,
  ) async => [
    for (final f in files)
      for (final inner in _unzipped(f))
        await _service.preview(inner.name, inner.bytes),
  ];

  static List<PickedActivityFile> _unzipped(PickedActivityFile file) {
    final inside = activityFilesInZip(file.bytes);
    return inside.isEmpty ? [file] : inside;
  }

  /// Imports every importable preview; returns how many were added.
  Future<int> import(List<ActivityFilePreview> previews) async {
    await ref.read(hrZonesProvider.notifier).loaded;
    final zones = ref.read(hrZonesProvider);
    final days = <DateTime>{};
    var added = 0;
    for (final preview in previews) {
      if (!preview.canImport) continue;
      if (await _service.import(
        preview,
        runningZones: zones.running.bounds,
        cyclingZones: zones.cycling.bounds,
      )) {
        added++;
        final start = preview.file!.start.toLocal();
        days.add(DateTime(start.year, start.month, start.day));
      }
    }
    if (added == 0) return 0;
    final sync = ref.read(syncServiceProvider);
    for (final day in days) {
      await sync.recalculateEnergie(day).catchError((Object _) {});
    }
    ref.read(syncStatusListenerProvider.notifier).state++;
    ref.read(hrvActivitiesChangedProvider.notifier).state++;
    unawaited(
      ref
          .read(missedWorkoutReminderProvider)
          .reconcile()
          .catchError((Object _) {}),
    );
    return added;
  }
}

/// Files opened in Fjelia from the share sheet or the Files app. iOS hands
/// them to `ActivityFileChannel` in AppDelegate.swift, which copies them to
/// the app's temporary folder; [take] reads and removes them.
class ActivityFileInbox {
  ActivityFileInbox([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('fjelia/activity_files');

  final MethodChannel _channel;

  /// Calls [onFiles] for files waiting now and whenever new ones arrive.
  void listen(void Function(List<PickedActivityFile> files) onFiles) {
    Future<void> deliver() async {
      final files = await take();
      if (files.isNotEmpty) onFiles(files);
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'opened') await deliver();
      return null;
    });
    unawaited(deliver());
  }

  Future<List<PickedActivityFile>> take() async {
    if (!Platform.isIOS) return const [];
    final List<Object?> paths;
    try {
      paths = await _channel.invokeListMethod<Object?>('takePending') ?? [];
    } on MissingPluginException {
      return const [];
    }
    final files = <PickedActivityFile>[];
    for (final path in paths.whereType<String>()) {
      final file = File(path);
      try {
        // The copy is named "<8 characters>-<original name>".
        final name = p
            .basename(path)
            .replaceFirst(RegExp(r'^[0-9A-F]{8}-'), '');
        files.add((name: name, bytes: await file.readAsBytes()));
      } catch (e) {
        log('[ActivityFile] could not read opened file: $e');
      } finally {
        if (await file.exists()) await file.delete();
      }
    }
    return files;
  }
}
