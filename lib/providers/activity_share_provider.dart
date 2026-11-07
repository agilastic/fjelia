import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../services/activity_fit_export.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'indoor_recording_provider.dart';

/// What happened when a workout went to Garmin Connect.
enum GarminSendResult { sent, alreadyThere }

final activityShareProvider = Provider<ActivityShare>(ActivityShare.new);

/// Sends a finished workout elsewhere: as a FIT file through the share sheet
/// or straight to a connected platform.
class ActivityShare {
  ActivityShare(this.ref);
  final Ref ref;

  /// Garmin takes uploads; a workout that came from Garmin is there already.
  bool canSendToGarmin(String? source) =>
      ref.read(authProvider).garminConnected && source != 'garmin_api';

  Future<List<int>> _fit(String activityId) async {
    final row = await ref.read(databaseProvider).getActivityById(activityId);
    if (row == null) throw StateError('This workout no longer exists.');
    // Indoor recordings keep their full capture; that file is richer.
    if ({'ftms', 'manual_recording'}.contains(row.source)) {
      final path = await ref.read(indoorActionsProvider).exportFit(activityId);
      return File(path).readAsBytes();
    }
    return activityRecordFit(row);
  }

  static String fileName(String activityId) =>
      'fjelia_${activityId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.fit';

  /// The workout as a FIT file in the temporary folder, for the share sheet.
  Future<String> fitFile(String activityId) async {
    final bytes = await _fit(activityId);
    final dir = await getTemporaryDirectory();
    final file = await File(
      '${dir.path}/${fileName(activityId)}',
    ).writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<GarminSendResult> sendToGarmin(String activityId) async {
    final bytes = await _fit(activityId);
    final sent = await ref
        .read(garminClientProvider)
        .uploadActivityFit(Uint8List.fromList(bytes), fileName(activityId));
    return sent ? GarminSendResult.sent : GarminSendResult.alreadyThere;
  }
}
