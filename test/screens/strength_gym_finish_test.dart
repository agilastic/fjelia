import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/screens/strength/strength_focus_screen.dart';
import 'package:fjelia/services/strength/strength_repository.dart';
import 'package:fjelia/services/strength/strength_templates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> frames(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Device review: skipping the last set left no visible way to finish.
void main() {
  late AppDatabase db;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  for (final template in bundledStrengthTemplates) {
    testWidgets('${template.id}: skip the last set, then finish', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = StrengthRepository(db);
      final owner = StrengthPlanOwner.session('s');
      final stored = await repo.savePlan(
        owner,
        template.build(),
        expectedRevision: 0,
      );
      final live = await repo.startLiveSession(
        stored: stored,
        title: 'Strength',
      );
      bool? closed;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      closed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            body: StrengthFocusScreen(
                              initial: live,
                              startedAt: DateTime.now(),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await frames(tester);
      final total = live.sets.length;
      bool has(String text) =>
          find.text(text, skipOffstage: false).evaluate().isNotEmpty;
      Future<void> tapText(String text) async {
        final f = find.text(text);
        if (!has(text)) fail('no "$text" on screen at step');
        await tester.ensureVisible(find.text(text, skipOffstage: false));
        await frames(tester, 3);
        await tester.tap(f);
        await frames(tester);
      }

      for (var i = 0; i < total - 1; i++) {
        if (has('Start set')) await tapText('Start set');
        // Ranges start empty: give reps and a load where needed.
        if (has('—') &&
            find
                .byTooltip('More Reps', skipOffstage: false)
                .evaluate()
                .isNotEmpty) {
          await tester.ensureVisible(
            find.byTooltip('More Reps', skipOffstage: false),
          );
          await frames(tester, 3);
          await tester.tap(find.byTooltip('More Reps'));
          await frames(tester, 2);
        }
        await tapText('Done');
      }
      if (has("Don't time this rest")) {
        await tapText("Don't time this rest");
      }
      await tapText('Skip');
      expect(
        find.textContaining(
          '$total of $total sets recorded',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      // Device review: after the last set nothing said how to finish.
      expect(find.text('All sets recorded'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
      expect(find.text('Finish workout', skipOffstage: false), findsOneWidget);
      await tapText('Finish workout');
      expect(tester.takeException(), isNull);
      final log = (await repo.loadLog(live.activityId))!;
      expect(log.sets.last.status, StrengthSetStatus.skipped);
      expect(log.status, StrengthLogStatus.finished);
      expect(closed, isTrue);
    });
  }

  testWidgets(
    'the finish flag in the top bar ends early; open sets stay open',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = StrengthRepository(db);
      final stored = await repo.savePlan(
        StrengthPlanOwner.session('s'),
        bundledStrengthTemplates.first.build(),
        expectedRevision: 0,
      );
      final live = await repo.startLiveSession(
        stored: stored,
        title: 'Strength',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: StrengthFocusScreen(
                initial: live,
                startedAt: DateTime.now(),
              ),
            ),
          ),
        ),
      );
      await frames(tester);
      await tester.tap(find.byTooltip('Finish workout'));
      await frames(tester);
      expect(find.text('Finish with sets open?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await frames(tester);
      final log = (await repo.loadLog(live.activityId))!;
      expect(log.status, StrengthLogStatus.finished);
      expect(log.incompleteAcknowledged, isTrue);
      expect(
        log.sets.every((s) => s.status == StrengthSetStatus.unrecorded),
        isTrue,
      );
      expect(
        (await db.getActivityById(live.activityId))!.durationSeconds,
        greaterThan(0),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
