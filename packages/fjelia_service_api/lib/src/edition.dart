/// FjeliaPro: the paid tier of the hosted service. The private package
/// decides it; builds without it are always the free edition.
abstract class FjeliaEdition {
  /// Whether this build may offer FjeliaPro at all (store product live).
  /// While false the app shows no Pro hint.
  bool get proOffered;

  /// Whether the athlete has FjeliaPro.
  bool get isPro;
}
