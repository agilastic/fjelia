import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/pro_analysis.dart';
import 'package:fjelia/services/weekly_review_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_notification_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late DateTime now;
  late List<ProAnalysisRef> written;
  Object? failure;
  var auto = true, mondayFirst = true;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    // Monday 16 November 2026, ten past midnight.
    now = DateTime(2026, 11, 16, 0, 10);
    written = [];
    failure = null;
    auto = true;
    mondayFirst = true;
  });
  tearDown(() => db.close());

  WeeklyReviewScheduler scheduler() => WeeklyReviewScheduler(
    db: db,
    gateway: gateway,
    generate: (analysis) async {
      written.add(analysis);
      if (failure != null) throw failure!;
      await db.saveProReport(
        ProReport(
          id: analysis.id,
          kind: analysis.kind.name,
          refKey: analysis.key,
          body: 'A good week.',
          model: 'test',
          createdAt: now,
        ),
      );
    },
    isPro: () => true,
    mondayFirst: () async => mondayFirst,
    auto: () async => auto,
    now: () => now,
  );

  test('a new week writes the review of the week before', () async {
    await scheduler().runIfDue();
    expect(written, hasLength(1));
    expect(written.single.id, 'weekReview:2026-W46');
    expect(written.single.until, DateTime(2026, 11, 15));
    // And says so at once, apart from the push at the start of the week.
    final ready = gateway.scheduled.single;
    expect(ready.id, greaterThanOrEqualTo(weeklyReviewReadyBase));
    expect(ready.title, 'Your week in review is ready');
    expect(ready.at.isAfter(now), isTrue);
    // A reconcile does not take it back.
    await scheduler().reconcile();
    expect(gateway.cancelled, isNot(contains(ready.id)));
    // Written once: the next run finds it.
    await scheduler().runIfDue();
    expect(written, hasLength(1));
  });

  test(
    'a review written mid-week is written again when the week is over',
    () async {
      await db.saveProReport(
        ProReport(
          id: 'weekReview:2026-W46',
          kind: 'weekReview',
          refKey: '2026-W46',
          body: 'Half a week.',
          model: 'test',
          createdAt: DateTime(2026, 11, 12, 18),
        ),
      );
      await scheduler().runIfDue();
      expect(written, hasLength(1));
    },
  );

  test('a failed attempt is tried again after half an hour', () async {
    failure = StateError('offline');
    await scheduler().runIfDue();
    now = now.add(const Duration(minutes: 20));
    await scheduler().runIfDue();
    expect(written, hasLength(1));
    failure = null;
    now = now.add(const Duration(minutes: 11));
    await scheduler().runIfDue();
    expect(written, hasLength(2));
    expect((await db.select(db.proReports).get()).single.body, 'A good week.');
  });

  test('without the switch nothing is written or scheduled', () async {
    auto = false;
    await scheduler().reconcile();
    await scheduler().runIfDue();
    expect(written, isEmpty);
    expect(gateway.scheduled, isEmpty);
  });

  test('the push is set for 00:00 of the next first weekday', () async {
    now = DateTime(2026, 11, 18, 14);
    await scheduler().reconcile();
    final push = gateway.scheduled.single;
    expect(push.at, DateTime(2026, 11, 23));
    expect(
      WeeklyReviewPayload.decode(push.payload)!.weekStart,
      DateTime(2026, 11, 23),
    );
    // Sunday first: the Sunday before.
    mondayFirst = false;
    await scheduler().reconcile();
    expect(gateway.scheduled.last.at, DateTime(2026, 11, 22));
    expect(gateway.cancelled, contains(push.id));
    // Turned off: taken back.
    auto = false;
    await scheduler().reconcile();
    expect(gateway.pending, isEmpty);
  });

  test('a week starting on Sunday has one name, whatever its day', () {
    // The week from Sunday 8 to Saturday 14 November is named after its
    // Monday, the 9th: ISO week 46.
    for (var d = 8; d <= 14; d++) {
      expect(
        ProAnalysisRef.weekReview(
          DateTime(2026, 11, d),
          mondayFirst: false,
        ).key,
        '2026-W46',
        reason: 'day $d',
      );
    }
    expect(ProAnalysisRef.weekReviewMonday('2026-W46'), DateTime(2026, 11, 9));
    expect(ProAnalysisRef.weekReviewMonday('2026-W01'), DateTime(2025, 12, 29));
    expect(ProAnalysisRef.weekReviewMonday('nonsense'), isNull);
    expect(
      ProAnalysisRef.lastWeekReview(
        DateTime(2026, 11, 15, 0, 5),
        mondayFirst: false,
      ).key,
      '2026-W46',
    );
  });
}
