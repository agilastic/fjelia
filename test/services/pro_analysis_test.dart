import 'dart:convert';

import 'package:fjelia/db/database.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/fjelia_pro.dart';
import 'package:fjelia/services/pro_analysis.dart';
import 'package:fjelia_service/fjelia_service.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

RaceGoal goal() => RaceGoal(
  id: 'g1',
  athleteId: 'self',
  name: 'Frankfurt Half',
  primarySport: 'running',
  distanceM: 21097,
  targetFinishSeconds: 6300,
  raceDate: DateTime(2026, 12, 13),
  priority: 'A',
  elevationM: 40,
  source: 'manual',
  createdAt: DateTime(2026, 10, 1),
  participation: 'committed',
);

void main() {
  test('each analysis has its own reference', () {
    final day = DateTime(2026, 11, 9);
    expect(ProAnalysisRef.planCheck(day).id, 'planCheck:2026-11-09');
    expect(ProAnalysisRef.weekReview(day).id, 'weekReview:2026-W46');
    // ISO weeks: 1 January 2026 is a Thursday, so it is in week 1.
    expect(ProAnalysisRef.weekReview(DateTime(2026, 1, 1)).key, '2026-W01');
    expect(ProAnalysisRef.racePlan(goal()).id, 'racePlan:g1');
    expect(ProAnalysisRef.season(day).id, 'season:2026');
  });

  test('the race request carries the goal', () {
    final ref = ProAnalysisRef.racePlan(goal());
    final request = proAnalysisRequest(ref, DateTime(2026, 11, 9, 8));
    expect(request, contains('Frankfurt Half'));
    expect(request, contains('21.1 km'));
    expect(request, contains('34 days from today'));
    expect(request, contains('target time 1:45:00'));
  });

  test(
    'the instructions come from the private package',
    skip: !hasServicePackage,
    () {
      final rules = proAnalysisInstructions(ProAnalysisRef.racePlan(goal()));
      expect(rules, contains('taper'));
      expect(rules, contains('never a diagnosis'));
      expect(
        proAnalysisInstructions(ProAnalysisRef.planCheck(DateTime(2026))),
        contains('verdict'),
      );
    },
  );

  group('sending', () {
    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      await const ProAccessStore().write(
        ProAccess(
          transactionId: '1001',
          key: 'sk-pro-1001',
          productId: 'fjelia.pro.yearly',
          expiresAt: DateTime.now().add(const Duration(days: 30)),
          checkedAt: DateTime.now(),
        ),
      );
      FjeliaProEntitlement.active = true;
    });
    tearDown(() => FjeliaProEntitlement.active = false);

    AiCoachClient client(
      List<String> models, {
      bool deepRefused = false,
      bool proOut = false,
    }) => AiCoachClient(
      store: const AiCoachSettingsStore(freeAiApiKey: 'free'),
      client: MockClient((r) async {
        final body = jsonDecode(r.body) as Map;
        models.add(body['model'] as String);
        if (body['model'] == 'default') {
          // Free AI on its own key.
          expect(r.headers['Authorization'], 'Bearer free');
        } else {
          expect(r.headers['Authorization'], 'Bearer sk-pro-1001');
        }
        if (proOut && body['model'] != 'default') {
          return http.Response(
            jsonEncode({
              'error': {'message': 'All deployments are in cooldown'},
            }),
            429,
          );
        }
        if (deepRefused && body['model'] == 'ProAI-deep') {
          return http.Response(
            jsonEncode({
              'error': {'message': 'key not allowed to access model'},
            }),
            401,
          );
        }
        final system = (body['messages'] as List).first['content'];
        expect(system, startsWith('You are Fjelia'));
        expect(system, contains('HEALTH_CONTEXT:'));
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': '## Verdict\nAs planned.'},
              },
            ],
          }),
          200,
        );
      }),
    );

    test('the large model writes the race plan and the season', () async {
      final models = <String>[];
      final answer = await client(models).sendProAnalysis(
        proAnalysisInstructions(ProAnalysisRef.planCheck(DateTime.now())),
        'Plan check',
        '[HRV:Latest:52ms]',
      );
      expect(models, ['ProAI-deep']);
      expect(answer.model, 'ProAI-deep');
      expect(answer.text, contains('As planned'));
    });

    test('without the large model on the key, the Pro model answers', () async {
      final models = <String>[];
      final answer = await client(models, deepRefused: true).sendProAnalysis(
        proAnalysisInstructions(ProAnalysisRef.season(DateTime.now())),
        'Season',
        '[HRV:Latest:52ms]',
      );
      expect(models, ['ProAI-deep', 'ProAI']);
      expect(answer.model, 'ProAI');
    });

    test('a quick request asks the Pro model only', () async {
      final models = <String>[];
      final answer = await client(models).sendProAnalysis(
        proAnalysisInstructions(ProAnalysisRef.planCheck(DateTime.now())),
        'Plan check',
        '[HRV:Latest:52ms]',
        deep: false,
      );
      expect(models, ['ProAI']);
      expect(answer.model, 'ProAI');
    });

    test('both Pro models out: Free AI writes the analysis', () async {
      final models = <String>[];
      final answer = await client(models, proOut: true).sendProAnalysis(
        proAnalysisInstructions(ProAnalysisRef.season(DateTime.now())),
        'Season',
        '[HRV:Latest:52ms]',
      );
      expect(models, ['ProAI-deep', 'ProAI', 'default']);
      expect(answer.model, 'default');
      expect(answer.text, contains('As planned'));
    });

    test('nothing is sent without Pro', () async {
      FjeliaProEntitlement.active = false;
      final models = <String>[];
      await expectLater(
        client(models).sendProAnalysis('x', 'y', 'z'),
        throwsStateError,
      );
      expect(models, isEmpty);
    });
  });
}
