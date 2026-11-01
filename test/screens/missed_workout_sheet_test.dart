import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/providers/heat_acclimation_provider.dart';
import 'package:fjelia/providers/planner_providers.dart';
import 'package:fjelia/screens/planner/missed_workout_sheet.dart';
import 'package:fjelia/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/upcoming_done_test.dart' show session;

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime day(int i) => DateTime(today.year, today.month, today.day + i);

  setUpAll(() async {
    if (Platform.environment['FJELIA_UI_PREVIEW_DIR'] == null) return;
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
  });

  testWidgets('one proposal with the next days and one Apply button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.trainingPlans)
        .insert(
          TrainingPlansCompanion.insert(
            id: 'p',
            athleteId: 'self',
            startDate: day(-7),
            endDate: day(30),
            status: 'active',
            generatedAt: day(-7),
          ),
        );
    final missed = session(
      'missed',
      day(0),
      title: 'Long endurance run (62 min)',
      minutes: 62,
    );
    final tue = session(
      'key',
      day(1),
      title: 'Threshold ride',
      sport: 'cycling',
      minutes: 60,
    ).copyWith(sessionType: 'key', primaryZone: 4);
    final easy = session(
      'easy',
      day(3),
      title: 'Recovery run',
      minutes: 40,
    ).copyWith(sessionType: 'recovery', primaryZone: 1);
    for (final s in [missed, tue, easy]) {
      await db.into(db.trainingSessions).insert(s);
    }
    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          upcomingSessionsProvider.overrideWith((ref) async => [tue, easy]),
          heatHourlyWeatherProvider.overrideWith((ref) async => null),
          aiCoachSettingsProvider.overrideWith(_CloudCoach.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark(),
          home: Scaffold(
            backgroundColor: const Color(0xFF161616),
            body: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: const Color(0xFF161616),
                child: MissedWorkoutSheet(day: today, syncFirst: false),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Long endurance run (62 min)'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Other day'), findsOneWidget);
    expect(find.textContaining('Move it to'), findsOneWidget);
    // The minutes are in the title already.
    expect(find.text('missed today'), findsOneWidget);
    // A cloud coach waits for an explicit tap, under the provider's name.
    expect(find.text('Ask coach'), findsOneWidget);
    expect(find.textContaining('Free AI'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final out = Platform.environment['FJELIA_UI_PREVIEW_DIR'];
    if (out != null) {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(out).create(recursive: true);
        await File(
          '$out/missed_sheet.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}

class _CloudCoach extends AiCoachSettingsNotifier {
  @override
  Future<AiCoachSettings> build() async => const AiCoachSettings(
    provider: AiProvider.freeAi,
    model: 'free',
    hasApiKey: true,
    enabled: true,
  );
}
