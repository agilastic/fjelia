/// Signs requests to the Suunto service. The implementation is supplied by the
/// `fjelia_service` package; public builds get a signer that reports Suunto as
/// unavailable.
abstract class SuuntoRequestSigner {
  /// Whether this build can sign Suunto requests.
  bool get isAvailable;

  /// The code that accompanies a request for the account [salt] (phone number
  /// or e-mail address).
  String totp(String salt);
}
