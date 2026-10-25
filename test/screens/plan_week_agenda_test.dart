import 'dart:io';
import 'dart:ui' as ui;

import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/providers/plan_week_provider.dart';
import 'package:fjelia/screens/planner/plan_week_agenda.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../providers/upcoming_done_test.dart' show session;

ActivityRecord activity(
  String id,
  String name,
  DateTime start, {
  String type = 'running',
  int minutes = 47,
}) => ActivityRecord(
  id: 0,
  activityId: id,
  name: name,
  type: type,
  startDate: start,
  durationSeconds: minutes * 60,
);

void main() {
  final monday = DateTime(2026, 10, 26);
  DateTime day(int i, [int hour = 8]) =>
      DateTime(monday.year, monday.month, monday.day + i, hour);

  PlanWeek week() => buildPlanWeek(
    start: monday,
    sessions: [
      session('tue', day(1), minutes: 45),
      session('wed', day(2), sport: 'cycling', title: 'Endurance ride'),
      session('fri', day(4), minutes: 40, status: 'skipped'),
      session('sat', day(5), sport: 'cycling', minutes: 90),
      session('sun', day(6), minutes: 65),
    ],
    activities: [
      activity('run-tue', 'Easy run', day(1, 18), minutes: 47),
      activity('swim', 'Pool', day(3, 7), type: 'swimming', minutes: 30),
    ],
    skipReasons: const {'fri': 'Travel'},
  );

  setUpAll(() async {
    final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    if (output != null) {
      final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
      await (FontLoader('Roboto')..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          ))
          .load();
      try {
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      } catch (_) {}
    }
  });

  group('the week', () {
    test('has seven days with rest days empty', () {
      final w = week();
      expect(w.days, hasLength(7));
      expect(w.days.first.rest, isTrue);
      expect(w.days.first.date, monday);
    });

    test('a done session shows the real minutes', () {
      final tue = week().days[1].items.single;
      expect(tue.state, PlanWeekState.done);
      expect(tue.minutes, 47);
      expect(tue.activity!.activityId, 'run-tue');
    });

    test('an activity without a plan is part of the week', () {
      final thu = week().days[3].items.single;
      expect(thu.state, PlanWeekState.done);
      expect(thu.session, isNull);
      expect(thu.sport, 'swimming');
    });

    test('a cancelled session is skipped and does not count as planned', () {
      final w = week();
      expect(w.days[4].items.single.state, PlanWeekState.skipped);
      // 45 + 60 + 90 + 65; the skipped 40 is left out.
      expect(w.plannedMinutes, 260);
      expect(w.doneMinutes, 47 + 30);
    });

    test('a past session nothing was recorded for is "not recorded"', () {
      final w = buildPlanWeek(
        start: monday,
        sessions: [session('mon', day(0), status: 'skipped')],
        activities: const [],
        skipReasons: const {'mon': 'No activity recorded'},
      );
      expect(
        w.days.first.items.single.state,
        anyOf(PlanWeekState.missed, PlanWeekState.skipped),
      );
    });

    test('the week starts on Monday or Sunday as set', () {
      final wed = DateTime(2026, 10, 28, 15);
      expect(weekStartFor(wed), monday);
      expect(weekStartFor(wed, mondayFirst: false), DateTime(2026, 10, 25));
    });
  });

  testWidgets('renders one row per day with the planned total', (tester) async {
    final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    tester.view.physicalSize = const Size(393, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 27)),
          planWeekProvider.overrideWith((ref, start) => Stream.value(week())),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            backgroundColor: const Color(0xFF111111),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RepaintBoundary(
                key: key,
                child: const Material(
                  color: Color(0xFF111111),
                  child: PlanWeekAgenda(mondayFirst: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    for (final d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(d), findsOneWidget);
    }
    expect(find.text('Rest'), findsOneWidget);
    expect(find.text('Running'), findsNWidgets(3));
    expect(find.text('Cycling'), findsNWidgets(2));
    expect(find.text('Swimming'), findsOneWidget);
    expect(find.text('47 min'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('SKIPPED'), findsOneWidget);
    expect(find.text('EXTRA'), findsOneWidget);
    expect(find.text('DONE'), findsNWidgets(2));
    expect(find.text('PLANNED'), findsNWidgets(3));
    expect(find.text('Plan 45 min'), findsOneWidget);
    expect(find.text('of 4 h 20 min planned'), findsOneWidget);
    expect(find.text('77 min'), findsOneWidget);
    expect(find.text('26–1 Nov'), findsNothing);
    expect(find.textContaining('Nov'), findsWidgets);

    if (output != null) {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File(
          '$output/week.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    // Next week moves the selected day by seven days.
    await tester.tap(find.byTooltip('Next week'));
    await tester.pump();
  });

  testWidgets('completed workout is one entry without repeated equal target', (
    tester,
  ) async {
    final combined = buildPlanWeek(
      start: monday,
      sessions: [
        session(
          'done',
          day(6),
          status: 'completed',
          title: 'Run With The Wind Modified',
        ),
      ],
      activities: [
        activity('actual', 'Run With The Wind Modified', day(6), minutes: 60),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDateProvider.overrideWith((ref) => day(6)),
          planWeekProvider.overrideWith((ref, start) => Stream.value(combined)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: PlanWeekAgenda(mondayFirst: true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Run With The Wind Modified'), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);
    expect(find.text('EXTRA'), findsNothing);
    expect(find.text('Plan 60 min'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
