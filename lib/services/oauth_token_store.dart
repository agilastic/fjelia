import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OAuthToken {
  const OAuthToken({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
}

/// OAuth tokens of third-party fitness platforms, keyed by provider
/// (`oauth_<provider>_access`, …).
class OAuthTokenStore {
  const OAuthTokenStore();

  static const _storage = FlutterSecureStorage();

  String _key(String provider, String field) => 'oauth_${provider}_$field';

  Future<OAuthToken?> load(String provider) async {
    final access = await _storage.read(key: _key(provider, 'access'));
    if (access == null) return null;
    final refresh = await _storage.read(key: _key(provider, 'refresh'));
    final expiry = await _storage.read(key: _key(provider, 'expiry'));
    return OAuthToken(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
          expiry != null ? int.parse(expiry) : 0),
    );
  }

  Future<void> save(String provider, OAuthToken token) async {
    await Future.wait([
      _storage.write(key: _key(provider, 'access'), value: token.accessToken),
      if (token.refreshToken != null)
        _storage.write(
            key: _key(provider, 'refresh'), value: token.refreshToken),
      _storage.write(
          key: _key(provider, 'expiry'),
          value: '${token.expiresAt.millisecondsSinceEpoch}'),
    ]);
  }

  Future<bool> isConnected(String provider) async =>
      await load(provider) != null;

  /// Expired, or expiring within five minutes.
  Future<bool> isExpired(String provider) async {
    final token = await load(provider);
    if (token == null) return true;
    return DateTime.now()
        .isAfter(token.expiresAt.subtract(const Duration(minutes: 5)));
  }

  Future<void> clear(String provider) async {
    await Future.wait([
      _storage.delete(key: _key(provider, 'access')),
      _storage.delete(key: _key(provider, 'refresh')),
      _storage.delete(key: _key(provider, 'expiry')),
    ]);
  }
}

final oauthTokenStore = const OAuthTokenStore();
