import 'dart:async';

import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/fjelia_pro_provider.dart';
import 'package:fjelia/screens/settings/fjelia_pro_sheet.dart';
import 'package:fjelia/services/fjelia_pro.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

final now = DateTime(2026, 11, 9, 12);

class _Store implements ProStore {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  final bought = <String>[];
  @override
  Stream<List<PurchaseDetails>> get purchases => controller.stream;
  @override
  Future<bool> available() async => true;
  // Like StoreKit: the list's runtime type is a subtype of ProductDetails.
  @override
  Future<List<ProductDetails>> products() async => <_StoreProduct>[
    for (final (id, price, raw) in [
      ('fjelia.pro.monthly', '4,99 €', 4.99),
      ('fjelia.pro.yearly', '39,99 €', 39.99),
    ])
      _StoreProduct(
        id: id,
        title: 'FjeliaPro',
        description: '',
        price: price,
        rawPrice: raw,
        currencyCode: 'EUR',
      ),
  ];
  @override
  Future<void> buy(ProductDetails product) async => bought.add(product.id);
  @override
  Future<void> restore() async {}
  @override
  Future<void> complete(PurchaseDetails purchase) async {}
}

class _StoreProduct extends ProductDetails {
  _StoreProduct({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.rawPrice,
    required super.currencyCode,
  });
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    FjeliaProEntitlement.active = false;
  });
  tearDown(() => FjeliaProEntitlement.active = false);

  Future<_Store> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final store = _Store();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proStoreProvider.overrideWithValue(store),
          proServerProvider.overrideWithValue(ProServer(clock: () => now)),
          proClockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: FjeliaProSheet()),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return store;
  }

  testWidgets('shows both plans with App Store prices and buys the chosen', (
    tester,
  ) async {
    final store = await show(tester);
    expect(find.text('4,99 € / month'), findsOneWidget);
    expect(find.text('39,99 € / year'), findsOneWidget);
    expect(find.text('BEST VALUE'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.textContaining('renews automatically'), findsOneWidget);
    // The yearly plan is chosen first; the monthly one can be picked.
    await tester.tap(find.byKey(const ValueKey('pro-buy')));
    await tester.pump();
    expect(store.bought, ['fjelia.pro.yearly']);
    await tester.tap(find.byKey(const ValueKey('pro-plan-fjelia.pro.monthly')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byKey(const ValueKey('pro-buy')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an active subscription shows until when, no plans', (
    tester,
  ) async {
    await const ProAccessStore().write(
      ProAccess(
        transactionId: '1001',
        key: 'sk-pro-1001',
        productId: 'fjelia.pro.yearly',
        expiresAt: now.add(const Duration(days: 300)),
        checkedAt: now,
      ),
    );
    await show(tester);
    expect(find.byKey(const ValueKey('pro-active')), findsOneWidget);
    expect(find.textContaining('Pro is on until'), findsOneWidget);
    expect(find.byKey(const ValueKey('pro-buy')), findsNothing);
    expect(find.text('Manage subscription'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
