import 'dart:async';
import 'dart:convert';

import 'package:fjelia/providers/fjelia_pro_provider.dart';
import 'package:fjelia/services/ai_coach_client.dart';
import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/fjelia_pro.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

final now = DateTime(2026, 11, 9, 12);

class FakeStore implements ProStore {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String?>[];
  int restores = 0;

  @override
  Stream<List<PurchaseDetails>> get purchases => controller.stream;
  @override
  Future<bool> available() async => true;
  @override
  Future<List<ProductDetails>> products() async => [
    ProductDetails(
      id: 'fjelia.pro.monthly',
      title: 'FjeliaPro',
      description: '',
      price: '4,99 €',
      rawPrice: 4.99,
      currencyCode: 'EUR',
    ),
  ];
  @override
  Future<void> buy(ProductDetails product) async {}
  @override
  Future<void> restore() async => restores++;
  @override
  Future<void> complete(PurchaseDetails purchase) async =>
      completed.add(purchase.purchaseID);
}

class FakeServer extends ProServer {
  FakeServer() : super(clock: () => now);
  ProCheck Function(String id) answer = (id) => const ProInactive();
  final asked = <String>[];
  @override
  Future<ProCheck> activate(String transactionId) async {
    asked.add(transactionId);
    return answer(transactionId);
  }
}

ProAccess access(String id, {Duration left = const Duration(days: 20)}) =>
    ProAccess(
      transactionId: id,
      key: 'sk-pro-$id',
      productId: 'fjelia.pro.monthly',
      expiresAt: now.add(left),
      checkedAt: now,
    );

PurchaseDetails purchase(String id, PurchaseStatus status) => PurchaseDetails(
  purchaseID: id,
  productID: 'fjelia.pro.monthly',
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: '',
    source: 'app_store',
  ),
  transactionDate: null,
  status: status,
)..pendingCompletePurchase = true;

void main() {
  late FakeStore store;
  late FakeServer server;
  late ProviderContainer container;

  ProviderContainer start() => ProviderContainer(
    overrides: [
      proStoreProvider.overrideWithValue(store),
      proServerProvider.overrideWithValue(server),
      proClockProvider.overrideWithValue(() => now),
    ],
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    FjeliaProEntitlement.active = false;
    store = FakeStore();
    server = FakeServer();
  });
  tearDown(() {
    container.dispose();
    FjeliaProEntitlement.active = false;
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a purchase is checked by the service before Pro is on', () async {
    container = start();
    container.read(fjeliaProProvider);
    server.answer = (id) => ProActive(access(id));
    store.controller.add([purchase('1001', PurchaseStatus.purchased)]);
    await settle();
    await settle();
    final state = container.read(fjeliaProProvider);
    expect(state.activeAt(now), isTrue);
    expect(FjeliaProEntitlement.active, isTrue);
    expect(server.asked, ['1001']);
    expect(store.completed, ['1001']);
    expect((await const ProAccessStore().read())!.key, 'sk-pro-1001');
  });

  test('a failed check leaves the purchase unfinished for StoreKit', () async {
    container = start();
    container.read(fjeliaProProvider);
    server.answer = (id) => throw const ProServerException(502);
    store.controller.add([purchase('1001', PurchaseStatus.purchased)]);
    await settle();
    await settle();
    expect(container.read(fjeliaProProvider).problem, ProProblem.service);
    expect(FjeliaProEntitlement.active, isFalse);
    expect(store.completed, isEmpty);
  });

  test('a cancelled purchase is finished and nothing changes', () async {
    container = start();
    container.read(fjeliaProProvider);
    store.controller.add([purchase('1001', PurchaseStatus.canceled)]);
    await settle();
    expect(container.read(fjeliaProProvider).busy, isFalse);
    expect(store.completed, ['1001']);
    expect(server.asked, isEmpty);
  });

  test('a stored, still valid subscription is on without asking', () async {
    await const ProAccessStore().write(access('1001'));
    container = start();
    container.read(fjeliaProProvider);
    await settle();
    await settle();
    expect(FjeliaProEntitlement.active, isTrue);
    expect(server.asked, isEmpty);
  });

  test('a run-out period is asked again; ended means Pro is off', () async {
    await const ProAccessStore().write(
      access('1001', left: const Duration(hours: -1)),
    );
    container = start();
    container.read(fjeliaProProvider);
    await settle();
    await settle();
    await settle();
    expect(server.asked, ['1001']);
    expect(container.read(fjeliaProProvider).access, isNull);
    expect(FjeliaProEntitlement.active, isFalse);
    expect(await const ProAccessStore().read(), isNull);
  });

  test('without a network the stored period stays valid', () async {
    final stale = ProAccess(
      transactionId: '1001',
      key: 'sk-pro-1001',
      productId: 'fjelia.pro.monthly',
      expiresAt: now.add(const Duration(days: 5)),
      checkedAt: now.subtract(const Duration(days: 3)),
    );
    await const ProAccessStore().write(stale);
    server.answer = (id) => throw const ProServerException(503);
    container = start();
    container.read(fjeliaProProvider);
    await settle();
    await settle();
    expect(server.asked, ['1001']);
    expect(FjeliaProEntitlement.active, isTrue);
  });

  group('Fjelia AI with Pro', () {
    Future<Map> send() async {
      Map? sent;
      final client = AiCoachClient(
        store: const AiCoachSettingsStore(freeAiApiKey: 'free-key'),
        client: MockClient((r) async {
          sent = {
            ...jsonDecode(r.body) as Map,
            'auth': r.headers['Authorization'],
          };
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Easy run today.'},
                },
              ],
            }),
            200,
          );
        }),
      );
      await client.send(
        const AiCoachSettings(
          provider: AiProvider.freeAi,
          model: 'default',
          hasApiKey: true,
          enabled: true,
        ),
        [ChatMessage(text: 'What today?', isUser: true)],
        '[HRV:Latest:52ms]',
        AiConsentToken.confirmed(),
      );
      return sent!;
    }

    test(
      'goes to the Pro model with the subscription key, no user id',
      () async {
        container = start();
        await const ProAccessStore().write(
          ProAccess(
            transactionId: '1001',
            key: 'sk-pro-1001',
            productId: 'fjelia.pro.monthly',
            expiresAt: DateTime.now().add(const Duration(days: 10)),
            checkedAt: DateTime.now(),
          ),
        );
        FjeliaProEntitlement.active = true;
        final sent = await send();
        expect(sent['model'], 'ProAI');
        expect(sent['auth'], 'Bearer sk-pro-1001');
        expect(sent.containsKey('user'), isFalse);
      },
    );

    test('a Pro key past its budget falls back to Free AI', () async {
      container = start();
      await const ProAccessStore().write(
        ProAccess(
          transactionId: '1001',
          key: 'sk-pro-1001',
          productId: 'fjelia.pro.monthly',
          expiresAt: DateTime.now().add(const Duration(days: 10)),
          checkedAt: DateTime.now(),
        ),
      );
      FjeliaProEntitlement.active = true;
      final models = <String>[];
      final client = AiCoachClient(
        store: const AiCoachSettingsStore(freeAiApiKey: 'free-key'),
        client: MockClient((r) async {
          final body = jsonDecode(r.body) as Map;
          models.add(body['model'] as String);
          if (body['model'] == 'ProAI') {
            return http.Response(
              jsonEncode({
                'error': {'message': 'Budget has been exceeded'},
              }),
              400,
            );
          }
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Easy run today.'},
                },
              ],
            }),
            200,
          );
        }),
      );
      final reply = await client.send(
        const AiCoachSettings(
          provider: AiProvider.freeAi,
          model: 'default',
          hasApiKey: true,
          enabled: true,
        ),
        [ChatMessage(text: 'What today?', isUser: true)],
        '[HRV:Latest:52ms]',
        AiConsentToken.confirmed(),
      );
      expect(reply, 'Easy run today.');
      expect(models, ['ProAI', 'default']);
    });

    test('stays on Free AI without Pro', () async {
      container = start();
      final sent = await send();
      expect(sent['model'], 'default');
      expect(sent['auth'], 'Bearer free-key');
      expect(sent['user'], isNotNull);
    });
  });
}
