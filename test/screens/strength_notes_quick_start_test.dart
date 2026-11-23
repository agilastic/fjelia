import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/screens/strength/strength_exercise_sheet.dart';
import 'package:fjelia/screens/strength/strength_focus_screen.dart';
import 'package:fjelia/services/strength/strength_repository.dart';
import 'package:fjelia/theme/fjelia_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _plan = StrengthWorkoutPlan(
  title: 'Pull Day',
  notes: 'Slow negatives on every pulling set.',
  blocks: [
    StrengthBlock(
      id: 'b',
      exercises: [
        StrengthPlannedExercise(
          id: 'e',
          variantId: 'pull_up',
          name: 'Pull-up',
          equipment: 'Bar',
          notes: 'Full hang at the bottom.',
          sets: [
            StrengthSetTarget(id: 't1', repMin: 6, repMax: 6),
            StrengthSetTarget(id: 't2', repMin: 6, repMax: 6),
          ],
        ),
      ],
    ),
  ],
);

Future<void> frames(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late StrengthRepository repo;
  setUpAll(() async {
    if (Platform.environment['FJELIA_UI_PREVIEW_DIR'] == null) return;
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    if (font.existsSync()) {
      final bytes = ByteData.sublistView(await font.readAsBytes());
      for (final family in ['Roboto', 'Ahem']) {
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    repo = StrengthRepository(db);
  });
  tearDown(() async {
    Fjelia.style = FjeliaStyle.dark;
    await db.close();
  });

  Widget app(Widget child, {bool light = false}) {
    Fjelia.style = light ? FjeliaStyle.light : FjeliaStyle.dark;
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: light ? ThemeData.light() : ThemeData.dark(),
        home: Scaffold(
          backgroundColor: fjBackground,
          body: RepaintBoundary(
            key: const ValueKey('preview'),
            child: ColoredBox(color: fjBackground, child: child),
          ),
        ),
      ),
    );
  }

  Future<void> preview(WidgetTester tester, String name) async {
    final output = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    if (output == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Quick Start opens an empty gym mode that adds exercises', (
    tester,
  ) async {
    phone(tester);
    final live = await tester.runAsync(
      () => repo.startQuickSession(title: 'Strength training'),
    );
    await tester.pumpWidget(
      app(StrengthFocusScreen(initial: live!, startedAt: DateTime.now())),
    );
    await frames(tester);
    expect(
      find.text('No exercises yet. Add each one as you start it.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Add exercise'), findsOneWidget);
    expect(find.text('Discard workout'), findsOneWidget);
    await preview(tester, 'strength_quick_start');
  });

  for (final light in [false, true]) {
    testWidgets(
      'gym mode shows routine, planned and pinned notes (${light ? 'light' : 'dark'})',
      (tester) async {
        phone(tester);
        final live = await tester.runAsync(() async {
          await repo.setExerciseNote('pull_up', 'Thumbs over the bar.');
          final stored = await repo.savePlan(
            StrengthPlanOwner.session('s'),
            _plan,
            expectedRevision: 0,
          );
          final l = await repo.startLiveSession(stored: stored, title: 'Pull');
          return repo.saveLog(l.copyWith(notes: () => 'Short on time'));
        });
        await tester.pumpWidget(
          app(
            StrengthFocusScreen(initial: live!, startedAt: DateTime.now()),
            light: light,
          ),
        );
        await frames(tester);
        expect(
          find.text('Slow negatives on every pulling set.'),
          findsOneWidget,
        );
        expect(find.text('Short on time'), findsOneWidget);
        expect(find.text('Full hang at the bottom.'), findsOneWidget);
        expect(find.text('Thumbs over the bar.'), findsOneWidget);
        await preview(tester, 'strength_gym_notes_${light ? 'light' : 'dark'}');

        await tester.tap(find.byTooltip('Workout actions'));
        await frames(tester, 4);
        for (final item in [
          'Add exercise',
          'Add set',
          'Note for today',
          'Pinned note',
          'Workout note',
        ]) {
          expect(find.text(item), findsOneWidget, reason: item);
        }
      },
    );

    testWidgets(
      'exercise sheet shows muscles, pinned note and YouTube (${light ? 'light' : 'dark'})',
      (tester) async {
        phone(tester);
        await tester.runAsync(
          () => repo.setExerciseNote('bench_press', 'Squeeze the lats.'),
        );
        await tester.pumpWidget(
          app(
            const StrengthExerciseSheet(
              variantId: 'bench_press',
              name: 'Bench press',
              equipment: 'Barbell',
              convention: StrengthConvention(),
              contextKey: 'bench_press|Barbell',
            ),
            light: light,
          ),
        );
        await frames(tester);
        expect(find.text('Chest'), findsOneWidget);
        expect(find.text('Triceps'), findsOneWidget);
        expect(find.text('Squeeze the lats.'), findsOneWidget);
        await preview(
          tester,
          'strength_exercise_about_${light ? 'light' : 'dark'}',
        );
        await tester.scrollUntilVisible(
          find.text('Search on YouTube'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Search on YouTube'), findsOneWidget);
        await tester.tap(find.text('History'));
        await frames(tester);
        expect(find.text('No logged sessions yet.'), findsOneWidget);
      },
    );
  }

  testWidgets('an own exercise says it has no muscle data', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      app(
        const StrengthExerciseSheet(
          variantId: 'custom-1',
          name: 'Sled push',
          equipment: 'Sled',
          convention: StrengthConvention(),
          contextKey: 'custom-1|Sled',
        ),
      ),
    );
    await frames(tester);
    expect(find.text('No muscle data for your own exercises.'), findsOneWidget);
    expect(
      find.text('Shows every time you do this exercise, in every workout.'),
      findsOneWidget,
    );
  });
}
