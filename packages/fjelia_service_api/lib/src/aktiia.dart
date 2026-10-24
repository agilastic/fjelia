import 'blood_pressure.dart';

/// Days of detailed (intraday) Aktiia readings that are fetched and stored:
/// today and the six days before it, the span the Hilo app shows without a
/// subscription. Older readings come from imported Hilo reports (PDF).
const aktiiaDetailDays = 7;

/// First day of the detailed Aktiia window.
DateTime aktiiaWindowStart([DateTime? now]) {
  final t = now ?? DateTime.now();
  return DateTime(t.year, t.month, t.day - (aktiiaDetailDays - 1));
}

/// Whether [day] lies inside the detailed Aktiia window.
bool isInAktiiaWindow(DateTime day, [DateTime? now]) =>
    !DateTime(day.year, day.month, day.day).isBefore(aktiiaWindowStart(now));

/// Raised when the Aktiia service rejects a request.
class AktiiaApiException implements Exception {
  AktiiaApiException(this.message);

  final String message;

  @override
  String toString() => 'AktiiaApiException: $message';
}

/// Raised when the Aktiia login is missing or no longer valid.
class AktiiaAuthException implements Exception {
  AktiiaAuthException(this.message);

  final String message;

  @override
  String toString() => 'AktiiaAuthException: $message';
}

/// Blood-pressure data of an Aktiia / Hilo account. The implementation is
/// supplied by the `fjelia_service` package; public builds get an
/// implementation that reports the feature as unavailable.
abstract class AktiiaClient {
  Future<bool> get isLoggedIn;

  Future<void> login(String email, String password);

  Future<void> logout();

  /// Readings between [from] and [to] (one page).
  Future<List<BloodPressureMeasurement>> getMeasurements(
    DateTime from,
    DateTime to, {
    int page = 0,
  });

  Future<DailyBpSummary> getDailyBp(DateTime date);
}
