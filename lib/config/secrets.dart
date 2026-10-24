/// Credentials of the services Fjelia talks to, supplied when the app is
/// built — never stored in the source:
///
///     flutter run --dart-define-from-file=secrets.json
///
/// `secrets.example.json` lists the keys. A service whose credentials are
/// missing is simply unavailable in that build (for example Polar
/// and Renpho need their developer/app credentials; without the
/// optional weather keys Open-Meteo and Bright Sky are used).
///
/// The credentials identify the Fjelia app towards each service, not a user:
/// every user signs in with their own account in the built app.
class Secrets {
  const Secrets._();

  /// Polar AccessLink API client (https://admin.polaraccesslink.com).
  static const polarClientId = String.fromEnvironment('POLAR_CLIENT_ID');
  static const polarClientSecret = String.fromEnvironment(
    'POLAR_CLIENT_SECRET',
  );

  /// AES-128 key of the Renpho cloud protocol.
  static const renphoAesKey = String.fromEnvironment('RENPHO_AES_KEY');

  static const pirateWeatherKey = String.fromEnvironment('PIRATE_WEATHER_KEY');
  static const weatherApiKey = String.fromEnvironment('WEATHER_API_KEY');

  static bool get hasPolar =>
      polarClientId.isNotEmpty && polarClientSecret.isNotEmpty;
  static bool get hasRenpho => renphoAesKey.length == 16;

  /// Error shown when a service is used in a build without its credentials.
  static StateError missing(String service) => StateError(
    '$service is not available in this build: its app credentials were not '
    'provided (see README, "Build-time credentials").',
  );
}
