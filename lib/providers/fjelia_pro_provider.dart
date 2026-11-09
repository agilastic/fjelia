import 'dart:async';
import 'dart:io';

import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/fjelia_pro.dart';
import '../services/fjelia_pro.dart';
import '../utils/log.dart';

/// The App Store on iOS; elsewhere none (Pro is sold on iOS only for now).
final proStoreProvider = Provider<ProStore>(
  (ref) => Platform.isIOS ? AppStoreProStore() : const NoProStore(),
);
final proServerProvider = Provider<ProServer>((ref) => ProServer());
final proAccessStoreProvider = Provider<ProAccessStore>(
  (ref) => const ProAccessStore(),
);
final proClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Why the last purchase or restore did not give Pro.
enum ProProblem { store, service, nothingToRestore, notActive }

class ProState {
  const ProState({this.access, this.busy = false, this.problem});
  final ProAccess? access;

  /// A purchase or restore is on its way.
  final bool busy;
  final ProProblem? problem;

  bool activeAt(DateTime now) => access?.activeAt(now) ?? false;
}

/// FjeliaPro on this device. Listens to the App Store from app start, so a
/// renewal, an interrupted purchase or one made on another device arrives
/// even without the Pro sheet open. Every purchase is checked by the Fjelia
/// service before Pro is on; until then the transaction stays unfinished,
/// and StoreKit hands it over again on the next start.
final fjeliaProProvider = NotifierProvider<FjeliaProNotifier, ProState>(
  FjeliaProNotifier.new,
);

class FjeliaProNotifier extends Notifier<ProState> {
  StreamSubscription<List<PurchaseDetails>>? _purchases;
  Timer? _restoreWait;

  DateTime get _now => ref.read(proClockProvider)();

  @override
  ProState build() {
    ref.keepAlive();
    _purchases = ref
        .read(proStoreProvider)
        .purchases
        .listen(_onPurchases, onError: (Object e) => log('[FjeliaPro] $e'));
    ref.onDispose(() {
      _purchases?.cancel();
      _restoreWait?.cancel();
    });
    unawaited(_load());
    return const ProState();
  }

  /// Sets [next] and tells the edition first, so whatever rebuilds on the
  /// change already sees the new Pro state.
  void _set(ProState next) {
    FjeliaProEntitlement.active = next.activeAt(_now);
    state = next;
  }

  Future<void> _load() async {
    final stored = await ref.read(proAccessStoreProvider).read();
    if (stored == null) return;
    _set(ProState(access: stored));
    await refresh();
  }

  /// Asks the Fjelia service again once a day and when the period ran out:
  /// a renewal moves the expiry, a refund or cancellation ends Pro. Without
  /// a network the stored period stays valid until it ends.
  Future<void> refresh({bool force = false}) async {
    final access = state.access;
    if (access == null || (!force && !access.staleAt(_now))) return;
    try {
      switch (await ref
          .read(proServerProvider)
          .activate(access.transactionId)) {
        case ProActive(:final access):
          await ref.read(proAccessStoreProvider).write(access);
          _set(ProState(access: access));
        case ProInactive():
          await ref.read(proAccessStoreProvider).clear();
          _set(const ProState());
      }
    } catch (e) {
      log('[FjeliaPro] refresh failed: $e');
      _set(ProState(access: access));
    }
  }

  Future<void> buy(ProductDetails product) async {
    _set(ProState(access: state.access, busy: true));
    try {
      await ref.read(proStoreProvider).buy(product);
    } catch (e) {
      log('[FjeliaPro] buy failed: $e');
      _set(ProState(access: state.access, problem: ProProblem.store));
    }
  }

  /// Restores from the App Store. A restore without a subscription sends
  /// nothing, so after a while the sheet is told there was nothing.
  Future<void> restore() async {
    _set(ProState(access: state.access, busy: true));
    try {
      await ref.read(proStoreProvider).restore();
    } catch (e) {
      log('[FjeliaPro] restore failed: $e');
      _set(ProState(access: state.access, problem: ProProblem.store));
      return;
    }
    _restoreWait?.cancel();
    _restoreWait = Timer(const Duration(seconds: 15), () {
      if (state.busy) {
        _set(
          ProState(access: state.access, problem: ProProblem.nothingToRestore),
        );
      }
    });
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final store = ref.read(proStoreProvider);
    for (final p in purchases) {
      if (!proProductIds.contains(p.productID)) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _set(ProState(access: state.access, busy: true));
        case PurchaseStatus.canceled:
          _set(ProState(access: state.access));
          if (p.pendingCompletePurchase) await store.complete(p);
        case PurchaseStatus.error:
          log('[FjeliaPro] purchase error: ${p.error}');
          _set(ProState(access: state.access, problem: ProProblem.store));
          if (p.pendingCompletePurchase) await store.complete(p);
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          await _verify(p);
      }
    }
  }

  Future<void> _verify(PurchaseDetails p) async {
    final id = p.purchaseID;
    if (id == null) return;
    _restoreWait?.cancel();
    try {
      final check = await ref.read(proServerProvider).activate(id);
      switch (check) {
        case ProActive(:final access):
          await ref.read(proAccessStoreProvider).write(access);
          _set(ProState(access: access));
        case ProInactive():
          // An old, ended subscription came back with a restore.
          if (state.access?.activeAt(_now) != true) {
            _set(const ProState(problem: ProProblem.notActive));
          }
      }
      await ref.read(proStoreProvider).complete(p);
    } catch (e) {
      // Left unfinished: StoreKit delivers it again, and Pro follows then.
      log('[FjeliaPro] verification failed: $e');
      _set(ProState(access: state.access, problem: ProProblem.service));
    }
  }
}

/// The subscriptions with their App Store prices, cheapest first.
final proProductsProvider = FutureProvider.autoDispose<List<ProductDetails>>((
  ref,
) async {
  final store = ref.read(proStoreProvider);
  if (!await store.available()) return const [];
  return store.products();
});
