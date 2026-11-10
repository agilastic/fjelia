import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';

import '../services/short_session_reminder.dart';
import 'database_provider.dart';
import 'hrv_reminder_provider.dart' show localNotificationGatewayProvider;
import 'planner_providers.dart'
    show postWorkoutScorerProvider, shortSessionsProvider;

/// Asks after a shorter session why, and keeps the answer as a note.
final shortSessionReminderProvider = Provider(
  (ref) => ShortSessionReminder(
    ref.watch(databaseProvider),
    ref.watch(localNotificationGatewayProvider),
    ref.watch(postWorkoutScorerProvider),
  ),
);

/// Records the athlete's answer and refreshes what shows it.
final answerShortSessionProvider =
    Provider<
      Future<void> Function(String sessionId, String reason, {String? text})
    >(
      (ref) => (sessionId, reason, {text}) async {
        await ref
            .read(shortSessionReminderProvider)
            .answer(sessionId, reason, text: text);
        ref.invalidate(shortSessionsProvider);
      },
    );

/// The planned session a "shorter than planned" push is about.
final shortSessionProvider = FutureProvider.autoDispose
    .family<TrainingSession?, String>((ref, id) {
      final db = ref.watch(databaseProvider);
      return (db.select(
        db.trainingSessions,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
    });

/// The athlete's note on an activity, as stored now.
final activityNoteProvider = StreamProvider.autoDispose.family<String?, String>(
  (ref, activityId) {
    final db = ref.watch(databaseProvider);
    return (db.select(db.activityRecords)
          ..where((t) => t.activityId.equals(activityId)))
        .watchSingleOrNull()
        .map((a) => a?.athleteNote);
  },
);

/// Saves the athlete's note on an activity; empty removes it.
final saveActivityNoteProvider =
    Provider<Future<void> Function(String activityId, String note)>(
      (ref) => (activityId, note) async {
        final db = ref.read(databaseProvider);
        final text = note.trim();
        await (db.update(
          db.activityRecords,
        )..where((t) => t.activityId.equals(activityId))).write(
          ActivityRecordsCompanion(
            athleteNote: Value(text.isEmpty ? null : text),
          ),
        );
      },
    );
