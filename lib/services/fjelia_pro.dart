import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/fjelia_pro.dart';
import '../utils/log.dart';

/// What a verified FjeliaPro subscription gives this device: the
/// subscription's own key for the Pro AI route, until [expiresAt]. The key
/// is the service's, never Fjelia's shared one.
class ProAccess {
  const ProAccess({
    required this.transactionId,
    required this.key,
    required this.productId,
    required this.expiresAt,
    required this.checkedAt,
  });

  final String transactionId, key, productId;
  final DateTime expiresAt, checkedAt;

  bool activeAt(DateTime now) => now.isBefore(expiresAt);

  /// Checked again once a day, and whenever the period has run out (a
  /// renewal moves the expiry).
  bool staleAt(DateTime now) =>
      !activeAt(now) || now.difference(checkedAt) > const Duration(days: 1);

  Map<String, Object> toJson() => {
    'transaction_id': transactionId,
    'key': key,
    'product_id': productId,
    'expires_at': expiresAt.millisecondsSinceEpoch ~/ 1000,
    'checked_at': checkedAt.millisecondsSinceEpoch ~/ 1000,
  };

  static ProAccess? fromJson(Map<String, dynamic> j) {
    final key = j['key'], id = j['transaction_id'], expires = j['expires_at'];
    if (key is! String || id is! String || expires is! int) return null;
    DateTime at(int s) => DateTime.fromMillisecondsSinceEpoch(s * 1000);
    return ProAccess(
      transactionId: id,
      key: key,
      productId: j['product_id'] as String? ?? '',
      expiresAt: at(expires),
      checkedAt: at(j['checked_at'] as int? ?? 0),
    );
  }
}

/// The access in the keychain, so Pro works offline until it expires.
class ProAccessStore {
  const ProAccessStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;
  static const _key = 'fjelia_pro_access_v1';

  Future<ProAccess?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return ProAccess.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(ProAccess access) =>
      _storage.write(key: _key, value: jsonEncode(access.toJson()));

  Future<void> clear() => _storage.delete(key: _key);
}

/// The answer of the Fjelia service for a transaction.
sealed class ProCheck {
  const ProCheck();
}

class ProActive extends ProCheck {
  const ProActive(this.access);
  final ProAccess access;
}

/// Apple says the subscription has ended, was refunded or is unknown.
class ProInactive extends ProCheck {
  const ProInactive();
}

/// The Fjelia service asks Apple; the app never decides Pro by itself.
class ProServer {
  ProServer({http.Client? client, DateTime Function()? clock})
    : _http = client ?? http.Client(),
      _clock = clock ?? DateTime.now;
  final http.Client _http;
  final DateTime Function() _clock;

  Future<ProCheck> activate(String transactionId) async {
    final response = await _http
        .post(
          proActivateUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'transaction_id': transactionId}),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw ProServerException(response.statusCode);
    }
    final j = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    if (j['active'] != true) return const ProInactive();
    return ProActive(
      ProAccess(
        transactionId: transactionId,
        key: j['key'] as String,
        productId: j['product_id'] as String? ?? '',
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          (j['expires_at'] as int) * 1000,
        ),
        checkedAt: _clock(),
      ),
    );
  }
}

class ProServerException implements Exception {
  const ProServerException(this.status);
  final int status;
  @override
  String toString() => 'FjeliaPro service answered $status';
}

/// The App Store side, behind an interface so tests need no StoreKit.
abstract class ProStore {
  Stream<List<PurchaseDetails>> get purchases;
  Future<bool> available();
  Future<List<ProductDetails>> products();
  Future<void> buy(ProductDetails product);
  Future<void> restore();
  Future<void> complete(PurchaseDetails purchase);
}

/// No App Store: FjeliaPro is sold on iOS only for now (Android, tests).
class NoProStore implements ProStore {
  const NoProStore();
  @override
  Stream<List<PurchaseDetails>> get purchases => const Stream.empty();
  @override
  Future<bool> available() async => false;
  @override
  Future<List<ProductDetails>> products() async => const [];
  @override
  Future<void> buy(ProductDetails product) async {}
  @override
  Future<void> restore() async {}
  @override
  Future<void> complete(PurchaseDetails purchase) async {}
}

/// StoreKit 2 through the in_app_purchase plugin.
class AppStoreProStore implements ProStore {
  AppStoreProStore([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance;
  final InAppPurchase _iap;

  @override
  Stream<List<PurchaseDetails>> get purchases => _iap.purchaseStream;

  @override
  Future<bool> available() => _iap.isAvailable();

  @override
  Future<List<ProductDetails>> products() async {
    final response = await _iap.queryProductDetails(proProductIds);
    if (response.notFoundIDs.isNotEmpty) {
      log('[FjeliaPro] products not found: ${response.notFoundIDs}');
    }
    // A plain List<ProductDetails>: StoreKit's list has a narrower runtime
    // type, which breaks code that adds a ProductDetails to it.
    return List<ProductDetails>.of(response.productDetails)
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
  }

  @override
  Future<void> buy(ProductDetails product) => _iap.buyNonConsumable(
    purchaseParam: PurchaseParam(productDetails: product),
  );

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}
