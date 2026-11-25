import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations_de.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/hr_zones_provider.dart';
import 'package:fjelia/services/coach_day_message.dart';
import 'package:fjelia/services/hr_zone_change_notice.dart';
import 'package:fjelia/services/hr_zone_history.dart';
import 'package:fjelia/services/notifications/local_notification_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  final l = AppLocalizationsDe();
  final noon = DateTime(2026, 11, 25, 12);

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
  });
  tearDown(() => db.close());

  Future<void> ride(DateTime at) => db
      .into(db.activityRecords)
      .insert(
        ActivityRecordsCompanion.insert(
          activityId: 'ride-${at.millisecondsSinceEpoch}',
          name: 'Ride',
          type: 'cycling',
          startDate: at,
          durationSeconds: 3600,
        ),
      );

  HrZoneChange bike({List<int>? before, DateTime? at}) => HrZoneChange(
    sport: 'cycling',
    before: before ?? [110, 126, 139, 151, 166],
    after: [93, 122, 132, 142, 149],
    method: ZoneMethod.device,
    at: at ?? noon,
  );

  test('one notice a day, with what moved, for a sport trained lately', () async {
    await ride(noon.subtract(const Duration(days: 3)));
    await HrZoneChangeNotice.add(bike());
    final notice = HrZoneChangeNotice(db, gateway);
    expect(await notice.run(l, now: noon), isTrue);
    final n = gateway.scheduled.single;
    expect(n.feature, NotificationFeature.hrZones);
    expect(n.title, 'Deine HF-Zonen haben sich geändert');
    expect(
      n.body,
      'Radfahren (von deiner Uhr): Z2 ab 122, Z3 ab 132, Z4 ab 142, Z5 ab 149',
    );
    expect(HrZonesPayload.decode(n.payload), isNotNull);
    // A second change the same day waits for tomorrow.
    await HrZoneChangeNotice.add(bike());
    expect(
      await notice.run(l, now: noon.add(const Duration(hours: 2))),
      isFalse,
    );
    expect(await notice.run(l, now: noon.add(const Duration(days: 1))), isTrue);
  });

  test('no notice for a sport not trained, or when switched off', () async {
    final notice = HrZoneChangeNotice(db, gateway);
    await HrZoneChangeNotice.add(bike());
    expect(await notice.run(l, now: noon), isFalse);
    await ride(noon.subtract(const Duration(days: 3)));
    await HrZoneChangeNotice.setEnabled(false);
    await HrZoneChangeNotice.add(bike());
    expect(await notice.run(l, now: noon), isFalse);
    expect(gateway.scheduled, isEmpty);
  });

  test('watch changes are kept for the notice, the app\'s own are not; the '
      'first measured zones after the estimate are no change', () async {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hrZonesProvider.overrideWith((ref) => HrZonesNotifier(db)),
      ],
    );
    addTearDown(c.dispose);
    final zones = c.read(hrZonesProvider.notifier);
    await zones.record('running', [
      118,
      129,
      140,
      151,
      162,
    ], method: ZoneMethod.estimate);
    await zones.applyDeviceZones(running: [105, 133, 144, 154, 163]);
    expect(await HrZoneChangeNotice.forCoach(), isEmpty);
    await zones.saveCycling(const HrZones([100, 120, 132, 142, 150]));
    expect(await HrZoneChangeNotice.forCoach(), isEmpty);
    await zones.applyDeviceZones(
      running: [105, 133, 144, 154, 163],
      cycling: [93, 122, 132, 142, 149],
    );
    final kept = await HrZoneChangeNotice.forCoach();
    expect(kept.single.sport, 'cycling');
    expect(kept.single.before, [100, 120, 132, 142, 150]);
    expect(kept.single.after, [93, 122, 132, 142, 149]);
  });

  test('FjeliaPro: the coach answers a zone change once a day', () {
    expect(
      dueCoachDaySignal(now: noon, sentToday: const {}, zonesChanged: true),
      CoachDaySignal.zones,
    );
    expect(
      dueCoachDaySignal(
        now: noon,
        sentToday: const {CoachDaySignal.zones},
        zonesChanged: true,
      ),
      isNull,
    );
    expect(
      coachDayQuestion(CoachDaySignal.zones, now: noon, zones: bike()),
      contains('"zones_now":"93/122/132/142/149"'),
    );
  });
}
