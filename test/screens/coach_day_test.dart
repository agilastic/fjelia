import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/coach_day_message_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/day_data_provider.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/theme/fjelia_style.dart';
import 'package:fjelia/widgets/briefing_card.dart';
import 'package:fjelia/widgets/coach_day_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Settings extends AiCoachSettingsNotifier {
  @override
  Future<AiCoachSettings> build() async => const AiCoachSettings(
    provider: AiProvider.appleIntelligence,
    enabled: true,
  );
}

Future<void> frames(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  final tuesday = DateTime(2026, 11, 10);
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
  });
  tearDown(() async {
    Fjelia.style = FjeliaStyle.dark;
    await db.close();
  });

  Future<void> keepTuesday(WidgetTester tester) => tester.runAsync(() async {
    for (final (period, hour, body) in [
      ('morning', 7, 'Make room for rest. Recovery is at 41 %.'),
      ('morning', 9, 'Recovery is back to 77 %, the interval run can stay.'),
      ('evening', 19, 'Keep tonight low-key and aim for bed by 22:30.'),
    ]) {
      await db.archiveCoachMessage(
        day: tuesday,
        kind: 'briefing',
        period: period,
        body: body,
        source: 'Local · Apple Intelligence',
        now: DateTime(2026, 11, 10, hour, 12),
      );
    }
  });

  Widget app(Widget child, {bool light = false}) {
    Fjelia.style = light ? FjeliaStyle.light : FjeliaStyle.dark;
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        aiCoachSettingsProvider.overrideWith(_Settings.new),
        selectedDateProvider.overrideWith((_) => tuesday),
      ],
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

  testWidgets('an earlier day shows the briefing the coach left that day', (
    tester,
  ) async {
    phone(tester);
    await keepTuesday(tester);
    await tester.pumpWidget(
      app(
        Padding(
          padding: const EdgeInsets.all(16),
          child: BriefingCard(openCoach: () {}),
        ),
      ),
    );
    await frames(tester);
    expect(find.byKey(const ValueKey('briefing-past-day')), findsOneWidget);
    expect(find.text('EVENING BRIEFING'), findsOneWidget);
    expect(
      find.text('Keep tonight low-key and aim for bed by 22:30.'),
      findsOneWidget,
    );
    // Nothing is generated for a day gone by.
    expect(find.text('Generate briefing'), findsNothing);
    expect(find.text('Day overview (3)'), findsOneWidget);
  });

  testWidgets('a day without a kept briefing says so', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      app(
        Padding(
          padding: const EdgeInsets.all(16),
          child: BriefingCard(openCoach: () {}),
        ),
      ),
    );
    await frames(tester);
    expect(
      find.text('The coach left no briefing for this day.'),
      findsOneWidget,
    );
    expect(find.textContaining('Day overview'), findsNothing);
  });

  for (final light in [false, true]) {
    testWidgets('the day overview lists every message, newest first '
        '(${light ? 'light' : 'dark'})', (tester) async {
      phone(tester);
      await keepTuesday(tester);
      await tester.pumpWidget(app(CoachDaySheet(day: tuesday), light: light));
      await frames(tester);
      expect(find.textContaining('10 November'), findsOneWidget);
      expect(find.text('EVENING BRIEFING · 19:12'), findsOneWidget);
      expect(find.text('MORNING BRIEFING · 09:12'), findsOneWidget);
      expect(find.text('MORNING BRIEFING · 07:12'), findsOneWidget);
      final evening = tester.getTopLeft(find.text('EVENING BRIEFING · 19:12'));
      final early = tester.getTopLeft(find.text('MORNING BRIEFING · 07:12'));
      expect(evening.dy, lessThan(early.dy));
      await preview(tester, 'coach_day_${light ? 'light' : 'dark'}');
    });
  }

  testWidgets('a Pro message of today shows under the briefing', (
    tester,
  ) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({'coach_day_messages_v1': true});
    final now = DateTime.now();
    await tester.runAsync(
      () => db.archiveCoachMessage(
        day: now,
        kind: coachDayKind,
        period: 'stress',
        body: 'Stress is well above your usual. Keep tonight easy.',
        source: 'FjeliaPro',
        now: DateTime(now.year, now.month, now.day, 15, 20),
      ),
    );
    await tester.pumpWidget(app(const CoachDayMessageLine()));
    await frames(tester);
    expect(find.byKey(const ValueKey('coach-day-message')), findsOneWidget);
    expect(find.text('Coach message · 15:20'), findsOneWidget);
    expect(
      find.text('Stress is well above your usual. Keep tonight easy.'),
      findsOneWidget,
    );
  });

  testWidgets('without the switch no message line shows', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(
      () => db.archiveCoachMessage(
        day: DateTime.now(),
        kind: coachDayKind,
        period: 'energy',
        body: 'Energy is low.',
      ),
    );
    await tester.pumpWidget(app(const CoachDayMessageLine()));
    await frames(tester);
    expect(find.byKey(const ValueKey('coach-day-message')), findsNothing);
  });
}
