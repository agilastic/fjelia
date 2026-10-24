class BackupRestoreProgress {
  const BackupRestoreProgress(
    this.stage,
    this.fraction, {
    this.completed = 0,
    this.total = 0,
  });
  final String stage;
  final double fraction;
  final int completed;
  final int total;
}

class BackupRestoreResult {
  const BackupRestoreResult(this.tableCounts);
  final Map<String, int> tableCounts;
  int get activities => tableCounts['activity_records'] ?? 0;
  int get plannedSessions => tableCounts['training_sessions'] ?? 0;
  int get scheduledWorkouts => tableCounts['scheduled_workout_records'] ?? 0;
}
