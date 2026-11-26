import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/synced_plan_followup.dart';
import 'package:fjelia/services/training_plan_service.dart';
import 'package:fjelia/services/workout_providers/workout_providers.dart';
import 'package:fjelia/services/workout_template_library.dart';
import 'package:fjelia_core/services/sync/sync_change.dart';
import 'package:fjelia_data/sync.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_workout_provider.dart';

/// Sessions the computer skipped or edited come off or go up again on the
/// watch platforms once the sync brought them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late RecordingProvider acme;
  late TrainingPlanService service;
  final clock = DateTime(2026, 10, 25, 9);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await WorkoutTemplateLibrary(db).seedIfEmpty();
    acme = RecordingProvider(db, 'acme');
    service = TrainingPlanService(
      db,
      WorkoutProviders([acme]),
      clock: () => clock,
    );
  });
  tearDown(() => db.close());

  test('a skip comes off, an edit goes up again', () async {
    await service.generatePlan(
      athleteId: 'self',
      raceDate: clock.add(const Duration(days: 70)),
      sport: 'running',
      raceDistanceM: 21097,
      daysPerWeek: 5,
      restDays: const [1],
      strengthDays: const [],
      hoursPerWeek: 6,
      gadSports: const ['running'],
    );
    await service.deliverPlan('self');
    final sent = [...acme.delivered];
    expect(sent.length, greaterThan(2));
    final before = await db.syncHeadSeq();

    // The computer skips the first and renames the second.
    final changes = await db.syncChangesSince(0);
    SyncChange edited(
      String id,
      Map<String, Object?> Function(Map<String, Object?>) f,
    ) {
      final c = changes.lastWhere(
        (c) => c.table == 'training_sessions' && c.key.first == id,
      );
      return SyncChange(
        seq: c.seq,
        table: c.table,
        key: c.key,
        op: c.op,
        category: c.category,
        athleteId: c.athleteId,
        changedAt: DateTime.now().add(const Duration(minutes: 1)),
        row: f({...c.row!}),
      );
    }

    await db.applySyncChanges([
      edited(sent[0], (r) => r..['status'] = 'skipped'),
      edited(sent[1], (r) => r..['title'] = 'Hills with the coach'),
    ], fromDevice: 'mac');
    acme.delivered.clear();

    await SyncedPlanFollowUp(
      db,
      service,
      WorkoutProviders([acme]),
    ).run('mac', afterSeq: before);
    expect(acme.released, [sent[0]]);
    expect(acme.delivered, [sent[1]]);
  });
}
