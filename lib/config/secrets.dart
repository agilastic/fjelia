import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'build_features.dart';

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
///
/// Fjelia CE also takes the Polar and weather keys the user entered under
/// Settings > Own keys ([OwnKey]); those win over the build's.
class Secrets {
  const Secrets._();

  static final _own = <OwnKey, String>{};

  /// Reads the keys entered in the app; called once before the app starts.
  static Future<void> load() async {
    for (final key in OwnKey.values) {
      try {
        final value = (await key.read())?.trim() ?? '';
        value.isEmpty ? _own.remove(key) : _own[key] = value;
      } catch (_) {
        // An unreadable store leaves the build's key; the app still starts.
        _own.remove(key);
      }
    }
  }

  static String _pick(OwnKey key, String built) => _own[key] ?? built;

  /// Polar AccessLink API client (https://admin.polaraccesslink.com).
  static String get polarClientId => _pick(
    OwnKey.polarClientId,
    const String.fromEnvironment('POLAR_CLIENT_ID'),
  );
  static String get polarClientSecret => _pick(
    OwnKey.polarClientSecret,
    const String.fromEnvironment('POLAR_CLIENT_SECRET'),
  );

  /// AES-128 key of the Renpho cloud protocol.
  static const renphoAesKey = String.fromEnvironment('RENPHO_AES_KEY');

  static String get pirateWeatherKey => _pick(
    OwnKey.pirateWeather,
    const String.fromEnvironment('PIRATE_WEATHER_KEY'),
  );
  static String get weatherApiKey => _pick(
    OwnKey.weatherApi,
    const String.fromEnvironment('WEATHER_API_KEY'),
  );

  static bool get hasPolar =>
      polarClientId.isNotEmpty && polarClientSecret.isNotEmpty;
  static bool get hasRenpho => renphoAesKey.length == 16;

  /// Error shown when a service is used in a build without its credentials.
  static StateError missing(String service) => StateError(
    communityEdition
        ? '$service needs your own key: enter it under Settings > Own keys.'
        : '$service is not available in this build: its app credentials '
              'were not provided (see README, "Build-time credentials").',
  );
}

/// A service key the user enters in the app (Settings > Own keys).
enum OwnKey {
  polarClientId('own_key_polar_client_id'),
  polarClientSecret('own_key_polar_client_secret'),
  pirateWeather('own_key_pirate_weather'),
  weatherApi('own_key_weather_api');

  const OwnKey(this.storageKey);
  final String storageKey;

  static const _storage = FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: storageKey);

  /// Saves (or with an empty value removes) the key and applies it at once.
  Future<void> write(String value) async {
    value.trim().isEmpty
        ? await _storage.delete(key: storageKey)
        : await _storage.write(key: storageKey, value: value.trim());
    await Secrets.load();
  }
}
