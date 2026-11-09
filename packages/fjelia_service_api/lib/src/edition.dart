/// FjeliaPro: the paid tier of the hosted service. The private package
/// decides it; builds without it are always the free edition.
abstract class FjeliaEdition {
  /// Whether this build may offer FjeliaPro at all (store product live).
  /// While false the app shows no Pro hint.
  bool get proOffered;

  /// Whether the athlete has FjeliaPro.
  bool get isPro;
}

/// The FjeliaPro subscription this device holds, as the app last verified
/// it with the Fjelia service (StoreKit 2 transaction checked against the
/// App Store). Set by the app; the private package's edition reads it.
abstract final class FjeliaProEntitlement {
  static bool active = false;
}
