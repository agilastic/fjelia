import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/strava_archive_import.dart';
import '../utils/log.dart';
import 'activity_history_provider.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'hr_zones_provider.dart';
import 'media_provider.dart';

enum StravaImportPhase { idle, reading, preview, importing, done, failed }

class StravaImportState {
  const StravaImportState({
    this.phase = StravaImportPhase.idle,
    this.preview,
    this.progress,
    this.error,
  });

  final StravaImportPhase phase;
  final StravaPreview? preview;
  final StravaImportProgress? progress;
  final String? error;
}

/// The Strava archive import. It lives outside the sheet, so it goes on
/// while the athlete uses the rest of the app.
final stravaImportProvider =
    StateNotifierProvider<StravaImportNotifier, StravaImportState>(
      StravaImportNotifier.new,
    );

class StravaImportNotifier extends StateNotifier<StravaImportState> {
  StravaImportNotifier(this._ref) : super(const StravaImportState());

  final Ref _ref;
  StravaArchive? _archive;
  String? _pickedPath;
  bool _cancel = false;

  Future<StravaArchiveImporter> _importer() async {
    await _ref.read(hrZonesProvider.notifier).loaded;
    final zones = _ref.read(hrZonesProvider);
    return StravaArchiveImporter(
      _ref.read(databaseProvider),
      _ref.read(mediaServiceProvider),
      runningZones: zones.running.bounds,
      cyclingZones: zones.cycling.bounds,
    );
  }

  /// Lets the athlete choose the ZIP and shows what it holds.
  Future<void> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = files.isEmpty ? null : files.single.path;
    if (path == null) return;
    await open(path, picked: true);
  }

  /// Reads the archive at [path]; [picked] marks a copy the picker made,
  /// removed again at the end.
  Future<void> open(String path, {bool picked = false}) async {
    _close();
    _pickedPath = picked ? path : null;
    state = const StravaImportState(phase: StravaImportPhase.reading);
    final archive = StravaArchive.open(path);
    if (archive == null || archive.rows.isEmpty) {
      _close();
      state = const StravaImportState(
        phase: StravaImportPhase.failed,
        error: 'notStrava',
      );
      return;
    }
    _archive = archive;
    final preview = await (await _importer()).preview(archive);
    state = StravaImportState(
      phase: StravaImportPhase.preview,
      preview: preview,
    );
  }

  /// Imports the archive that was read.
  Future<void> start() async {
    final archive = _archive;
    if (archive == null || state.phase == StravaImportPhase.importing) return;
    _cancel = false;
    final preview = state.preview;
    state = StravaImportState(
      phase: StravaImportPhase.importing,
      preview: preview,
      progress: StravaImportProgress()..total = archive.rows.length,
    );
    try {
      final result = await (await _importer()).run(
        archive,
        isCancelled: () => _cancel,
        onProgress: (p) {
          if (!mounted) return;
          state = StravaImportState(
            phase: StravaImportPhase.importing,
            preview: preview,
            progress: p,
          );
        },
      );
      if (!mounted) return;
      state = StravaImportState(
        phase: StravaImportPhase.done,
        preview: preview,
        progress: result,
      );
    } catch (e) {
      log('[Strava] import stopped: $e');
      if (mounted) {
        state = StravaImportState(
          phase: StravaImportPhase.failed,
          preview: preview,
          progress: state.progress,
          error: '$e',
        );
      }
    } finally {
      _close();
      _ref.invalidate(loadActivitiesProvider);
      _ref.read(syncStatusListenerProvider.notifier).state++;
    }
  }

  void cancel() => _cancel = true;

  /// Back to the start, letting go of the archive.
  void reset() {
    _close();
    state = const StravaImportState();
  }

  void _close() {
    _archive?.close();
    _archive = null;
    final picked = _pickedPath;
    _pickedPath = null;
    // The picker's copy of a large archive is not kept. Only a copy in the
    // app's temporary folder: where a picker hands out the original file,
    // that file stays untouched.
    if (picked != null &&
        File(picked).absolute.path
            .startsWith(Directory.systemTemp.absolute.path)) {
      try {
        File(picked).deleteSync();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }
}
