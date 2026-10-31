import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/health_connect_service.dart';
import 'package:fjelia/services/nutrition_reminder_service.dart';
import 'package:fjelia/services/nutrition_service.dart';
import 'package:fjelia/services/workout_background.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notification_gateway.dart';

/// Apple Health with one finished run, or a read that fails like a locked
/// phone does.
class _FakeHealth extends HealthConnectService {
  _FakeHealth(super.db, this.at, {this.fail = false});
  final DateTime at;
  final bool fail;
  int reads = 0;

  @override
  Future<int> syncRecentWorkouts({
    Duration lookback = const Duration(days: 2),
  }) async {
    reads++;
    if (fail) throw StateError('Protected health data is inaccessible');
    await db
        .into(db.activityRecords)
        .insert(
          ActivityRecordsCompanion.insert(
            activityId: 'hc_1',
            name: 'Run',
            type: 'running',
            startDate: at.subtract(const Duration(minutes: 70)),
            durationSeconds: 3600,
          ),
        );
    return 1;
  }
}

void main() {
  final now = DateTime(2026, 10, 31, 12);
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late NutritionReminderService nutrition;
  var hrvRuns = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    nutrition = NutritionReminderService(
      NutritionService(db),
      gateway,
      now: () => now,
    );
    hrvRuns = 0;
  });
  tearDown(() => db.close());

  Future<int> check(HealthConnectService health, {bool connected = true}) =>
      checkNewWorkouts(
        healthConnected: () async => connected,
        health: health,
        reconcileHrv: () async => hrvRuns++,
        nutrition: nutrition,
      );

  test('a new Health workout is imported and reminded about', () async {
    expect(await check(_FakeHealth(db, now)), 1);
    expect(hrvRuns, 1);
    expect(gateway.pending.values.single.title, 'New activity: Run');
  });

  test('nothing is read while Apple Health is not connected', () async {
    final health = _FakeHealth(db, now);
    expect(await check(health, connected: false), 0);
    expect(health.reads, 0);
    expect(gateway.scheduled, isEmpty);
  });

  test('a failed Health read still settles the reminders', () async {
    expect(await check(_FakeHealth(db, now, fail: true)), 0);
    expect(hrvRuns, 1);
    expect(gateway.scheduled, isEmpty);
  });
}
