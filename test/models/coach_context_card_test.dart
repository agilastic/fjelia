import 'package:fjelia/l10n/app_localizations.dart';

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/coach_context_card.dart';
import 'package:fjelia/models/garmin_data.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/screens/ai_coach/ai_coach_screen.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/widgets/coach_context_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<TrainingSession> session(
  AppDatabase db, {
  String status = 'planned',
}) async {
  await db
      .into(db.trainingPlans)
      .insert(
        TrainingPlansCompanion.insert(
          id: 'p',
          athleteId: 'a',
          startDate: DateTime(2026, 10, 19),
          endDate: DateTime(2027, 1, 1),
          status: 'active',
          generatedAt: DateTime(2026, 10, 19),
        ),
        mode: InsertMode.insertOrReplace,
      );
  await db
      .into(db.trainingSessions)
      .insert(
        TrainingSessionsCompanion.insert(
          id: 's1',
          planId: 'p',
          athleteId: 'a',
          sessionDate: DateTime(2026, 10, 23),
          sessionNumber: 1,
          weekNumber: 3,
          sport: 'cycling_road',
          sessionType: 'endurance',
          phase: 'base',
          primaryZone: 2,
          title: '35m easy endurance ride',
          stepsJson: Value(
            jsonEncode([
              {
                'stepType': {'stepTypeKey': 'warmup'},
                'endCondition': {'conditionTypeKey': 'time'},
                'endConditionValue': 480,
              },
              {
                'stepType': {'stepTypeKey': 'interval'},
                'endCondition': {'conditionTypeKey': 'time'},
                'endConditionValue': 900,
                'zoneNumber': 2,
              },
            ]),
          ),
          plannedDurationMin: 35,
          plannedTrimp: 26,
          sessionLevel: 1,
          status: Value(status),
        ),
        mode: InsertMode.insertOrReplace,
      );
  return (await db.select(db.trainingSessions).get()).single;
}

void main() {
  group('CoachContextCard', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('a planned session describes itself without its name', () async {
      final card = CoachContextCard.planned(await session(db));
      expect(card.title, '35m easy endurance ride');
      expect(card.status, CoachCardStatus.planned);
      expect(card.facts, ['35 min', 'Z2']);
      expect(
        card.contextLine,
        startsWith('[Session:Status:planned,Date:2026-10-23'),
      );
      expect(card.contextLine, contains('Sport:cycling road'));
      expect(card.contextLine, contains('Duration:35min'));
      expect(card.contextLine, contains('Zone:Z2'));
      expect(
        card.contextLine,
        contains('Structure:8 min Warm-up>15 min Interval Z2'),
      );
      expect(card.contextLine, isNot(contains('easy endurance ride')));
      expect(card.questions, [
        'How do I execute this workout?',
        'Why this workout today?',
        'Should I adjust it today?',
      ]);
    });

    test('the structure names the range of each zone as of today', () async {
      final card = CoachContextCard.planned(
        await session(db),
        zoneTarget: (z) => 'Z$z · 137–147 bpm · 150–180 W',
      );
      expect(
        card.contextLine,
        contains(
          'Structure:8 min Warm-up Z1 · 137–147 bpm · 150–180 W>15 min Interval Z2 · 137–147 bpm · 150–180 W',
        ),
      );
    });

    test('the status follows the session', () async {
      expect(
        CoachContextCard.planned(await session(db, status: 'completed')).status,
        CoachCardStatus.completed,
      );
      final skipped = CoachContextCard.planned(
        await session(db, status: 'skipped'),
      );
      expect(skipped.status.label, 'Rest');
      expect(skipped.questions.first, 'Why is this a rest day?');
      expect(
        CoachContextCard.planned(await session(db, status: 'adapted'))
            .status
            .label,
        'Adapted',
      );
    });

    test(
      'a completed activity reports its zones and length, not its name',
      () async {
        final card = CoachContextCard.completed(
          GarminActivity(
            id: 'a',
            name: 'Morgenlauf am Fluss',
            type: 'running',
            startTime: DateTime(2026, 10, 22, 14, 19),
            duration: const Duration(minutes: 46),
            distanceMeters: 8400,
            trainingLoad: 40,
            hrZoneSeconds: const {
              'zone1': 10,
              'zone2': 60,
              'zone3': 20,
              'zone4': 10,
              'zone5': 0,
            },
          ),
        );
        expect(card.status, CoachCardStatus.completed);
        expect(card.facts, ['46 min', '8.4 km', '40 load']);
        expect(card.contextLine, contains('Status:completed'));
        expect(card.contextLine, contains('HRZonePct:10/60/20/10/0'));
        expect(card.contextLine, isNot(contains('Morgenlauf')));
      },
    );

    test('an activity without distance shows no kilometres', () async {
      final card = CoachContextCard.completed(
        GarminActivity(
          id: 'a',
          name: 'Kraft',
          type: 'strength_training',
          startTime: DateTime(2026, 10, 22),
          duration: const Duration(minutes: 30),
        ),
      );
      expect(card.facts, ['30 min']);
    });

    test('withContext puts the session before the request context', () async {
      final card = CoachContextCard.planned(await session(db));
      final text = card.withContext('[Context:V4]');
      expect(text.split('\n').first, startsWith('[Session:'));
      expect(text.split('\n').last, '[Context:V4]');
      expect(
        CoachContextCard(
          sport: 'x',
          title: 't',
          date: DateTime(2026, 1, 1),
          status: CoachCardStatus.planned,
        ).withContext('c'),
        'c',
      );
    });
  });

  group('chat with a context card', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    testWidgets(
      'shows the card first, starts from a question and sends the session',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = _Client();
        await db
            .into(db.activityRecords)
            .insert(
              ActivityRecordsCompanion.insert(
                activityId: 'x',
                name: 'Ride',
                type: 'cycling',
                startDate: DateTime(2026, 10, 22, 8),
                durationSeconds: 3000,
              ),
            );
        final record = (await db.select(db.activityRecords).get()).single;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              aiCoachSettingsProvider.overrideWith(_Settings.new),
              aiCoachClientProvider.overrideWithValue(client),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AiCoachScreen(
                  activity: record,
                  contextCard: CoachContextCard.planned(await session(db)),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CoachContextCardView), findsOneWidget);
        expect(find.text('35m easy endurance ride'), findsOneWidget);
        expect(find.text('Planned'), findsOneWidget);
        expect(find.text('How do I execute this workout?'), findsOneWidget);
        expect(find.text('Should I adjust it today?'), findsOneWidget);

        await tester.tap(find.text('Why this workout today?'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(client.sent, hasLength(1));
        expect(client.sent.single.last.text, 'Why this workout today?');
        expect(
          client.context!.split('\n').first,
          startsWith('[Session:Status:planned'),
        );
        expect(client.context, contains('[Activity:'));
        expect(find.text('Reply'), findsOneWidget);
        // The card stays on top of the conversation; the starters are gone.
        expect(find.byType(CoachContextCardView), findsOneWidget);
        expect(find.text('Should I adjust it today?'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
      },
    );
  });
}

class _Settings extends AiCoachSettingsNotifier {
  @override
  Future<AiCoachSettings> build() async =>
      const AiCoachSettings(enabled: true, onDeviceAvailable: true);
}

class _Client extends AiCoachClient {
  String? context;
  final sent = <List<ChatMessage>>[];
  @override
  Future<String> send(
    AiCoachSettings settings,
    List<ChatMessage> messages,
    String toonContext, [
    AiConsentToken? consent,
  ]) async {
    context = toonContext;
    sent.add(messages);
    return 'Reply';
  }
}
