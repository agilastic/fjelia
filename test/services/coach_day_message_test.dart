import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/providers/ai_coach_provider.dart';
import 'package:fjelia/providers/coach_day_message_provider.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/fjelia_pro_provider.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_context_toon_builder.dart';
import 'package:fjelia_core/services/bio_age_service.dart';
import 'package:fjelia/services/coach_day_message.dart';
import 'package:fjelia_service/fjelia_service.dart' show hasServicePackage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Client extends AiCoachClient {
  final questions = <String>[];
  String reply =
      'Stress is well above your usual today. Keep the evening '
      'run easy and get to bed early.';
  @override
  Future<({String text, String model})> sendProAnalysis(
    String systemPrompt,
    String userPrompt,
    String toonContext, {
    bool deep = true,
  }) async {
    questions.add(userPrompt);
    return (text: reply, model: 'ProAI');
  }
}

class _Toon extends ToonCacheNotifier {
  _Toon(super.ref);
  @override
  Future<String> getOrBuild(
    AiContextTrainingMonitor? monitor,
    String raceGoals,
    String? weatherSummary, {
    BioAgeResult? bioAge,
    AiContextPlanInfo? planInfo,
  }) async => '[Today:Date:2026-11-23]';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('when the coach speaks up', () {
    DateTime at(int hour) => DateTime(2026, 11, 23, hour);
    test('stress counts from 40 and 10 points above the usual week', () {
      expect(
        dueCoachDaySignal(
          now: at(15),
          sentToday: {},
          stress: 52,
          stressUsual: 38,
        ),
        CoachDaySignal.stress,
      );
      expect(
        dueCoachDaySignal(
          now: at(15),
          sentToday: {},
          stress: 45,
          stressUsual: 38,
        ),
        isNull,
      );
      // 33 against 20 is a jump, but not high stress.
      expect(
        dueCoachDaySignal(
          now: at(15),
          sentToday: {},
          stress: 33,
          stressUsual: 20,
        ),
        isNull,
      );
    });

    test('low energy only before the evening', () {
      expect(
        dueCoachDaySignal(now: at(14), sentToday: {}, energy: 22),
        CoachDaySignal.energy,
      );
      expect(dueCoachDaySignal(now: at(18), sentToday: {}, energy: 22), isNull);
      expect(dueCoachDaySignal(now: at(14), sentToday: {}, energy: 30), isNull);
    });

    test('stress eased only after a stress message', () {
      expect(
        dueCoachDaySignal(
          now: at(17),
          sentToday: {CoachDaySignal.stress},
          stress: 40,
          stressUsual: 38,
        ),
        CoachDaySignal.stressEased,
      );
      expect(
        dueCoachDaySignal(
          now: at(17),
          sentToday: {},
          stress: 30,
          stressUsual: 38,
        ),
        isNull,
      );
    });

    test('once per signal, three a day, never at night', () {
      expect(
        dueCoachDaySignal(
          now: at(15),
          sentToday: {CoachDaySignal.stress},
          stress: 60,
          stressUsual: 38,
        ),
        isNull,
      );
      expect(
        dueCoachDaySignal(
          now: at(15),
          sentToday: CoachDaySignal.values.toSet(),
          energy: 10,
        ),
        isNull,
      );
      for (final hour in [6, 8, 20, 23]) {
        expect(
          dueCoachDaySignal(
            now: at(hour),
            sentToday: {},
            stress: 70,
            stressUsual: 30,
          ),
          isNull,
          reason: '$hour',
        );
      }
    });

    test('the question carries the signal and only known values', () {
      expect(
        coachDayQuestion(
          CoachDaySignal.energy,
          now: DateTime(2026, 11, 23, 15, 5),
          energy: 21.6,
        ),
        '{"signal":"energy","time":"15:05","energy_now":22}',
      );
    });

    test('only a short plain answer is shown', () {
      expect(
        usableCoachDayMessage('**Stress** is high.\n\nTake a walk.'),
        'Stress is high. Take a walk.',
      );
      expect(usableCoachDayMessage('  '), isNull);
      expect(usableCoachDayMessage('{"text":"x"}'), isNull);
      expect(usableCoachDayMessage('word ' * 80), isNull);
    });
  });

  group('the runner', skip: !hasServicePackage, () {
    late AppDatabase db;
    late _Client client;
    late ProviderContainer container;
    final today = DateTime(2026, 11, 23);

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      client = _Client();
      for (var i = 1; i <= 7; i++) {
        await db.upsertHrv(
          HrvRecordsCompanion(
            date: Value(today.subtract(Duration(days: i))),
            stressLevel: const Value(36),
          ),
        );
      }
      await db.upsertHrv(
        HrvRecordsCompanion(
          date: Value(today),
          stressLevel: const Value(55),
          computedEnergie: const Value(60),
        ),
      );
    });
    tearDown(() async {
      container.dispose();
      await db.close();
    });

    ProviderContainer make({required bool pro, required bool on}) {
      SharedPreferences.setMockInitialValues({'coach_day_messages_v1': on});
      FlutterSecureStorage.setMockInitialValues({});
      return container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          aiCoachClientProvider.overrideWithValue(client),
          proSubscribedProvider.overrideWithValue(pro),
          toonCacheProvider.overrideWith(_Toon.new),
        ],
      );
    }

    test('writes one stress message and keeps it for the day', () async {
      final c = make(pro: true, on: true);
      final runner = c.read(coachDayMessageRunnerProvider);
      final text = await runner.run(now: DateTime(2026, 11, 23, 15, 20));
      expect(text, startsWith('Stress is well above'));
      expect(client.questions.single, contains('"signal":"stress"'));
      expect(client.questions.single, contains('"stress_usual":36'));
      final kept = await db.coachMessagesOn(today);
      expect(kept.single.kind, coachDayKind);
      expect(kept.single.period, 'stress');
      // The same signal is not answered twice the same day.
      expect(await runner.run(now: DateTime(2026, 11, 23, 16)), isNull);
      expect(client.questions, hasLength(1));
    });

    test('nothing is sent without Pro or without the switch', () async {
      expect(
        await make(pro: false, on: true)
            .read(coachDayMessageRunnerProvider)
            .run(now: DateTime(2026, 11, 23, 15)),
        isNull,
      );
      container.dispose();
      expect(
        await make(pro: true, on: false)
            .read(coachDayMessageRunnerProvider)
            .run(now: DateTime(2026, 11, 23, 15)),
        isNull,
      );
      expect(client.questions, isEmpty);
    });
  });
}
