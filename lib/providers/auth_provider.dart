import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:fjelia_service/fjelia_service.dart';
import 'package:fjelia_service_api/fjelia_service_api.dart';
import '../api/garmin_client.dart';
import '../api/renpho_client.dart';
import '../services/oauth_token_store.dart';

final aktiiaClientProvider = Provider<AktiiaClient>((ref) => createAktiiaClient());
final garminClientProvider = Provider<GarminClient>((ref) => GarminClient());
final renphoClientProvider = Provider<RenphoClient>((ref) => RenphoClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(aktiiaClientProvider),
    ref.watch(garminClientProvider),
    ref.watch(renphoClientProvider),
  );
});

enum LoginStatus { loading, loggedIn, needsOnboarding }

class AuthState {
  const AuthState({
    this.aktiiaConnected = false,
    this.garminConnected = false,
    this.renphoConnected = false,
    this.aktiiaEmail,
    this.garminEmail,
    this.renphoEmail,
    this.status = LoginStatus.loading,
  });

  final bool aktiiaConnected;
  final bool garminConnected;
  final bool renphoConnected;
  final String? aktiiaEmail;
  final String? garminEmail;
  final String? renphoEmail;
  final LoginStatus status;

  AuthState copyWith({
    bool? aktiiaConnected,
    String? aktiiaEmail,
    bool? garminConnected,
    String? garminEmail,
    bool? renphoConnected,
    String? renphoEmail,
    LoginStatus? status,
  }) => AuthState(
    aktiiaConnected: aktiiaConnected ?? this.aktiiaConnected,
    aktiiaEmail: aktiiaEmail ?? this.aktiiaEmail,
    garminConnected: garminConnected ?? this.garminConnected,
    garminEmail: garminEmail ?? this.garminEmail,
    renphoConnected: renphoConnected ?? this.renphoConnected,
    renphoEmail: renphoEmail ?? this.renphoEmail,
    status: status ?? this.status,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._aktiia, this._garmin, this._renpho)
    : super(const AuthState()) {
    _checkExistingLogin();
  }

  final AktiiaClient _aktiia;
  final GarminClient _garmin;
  final RenphoClient _renpho;

  static const _storage = FlutterSecureStorage();

  Future<void> _checkExistingLogin() async {
    final aktiia = await _aktiia.isLoggedIn;
    final garmin = await _garmin.isLoggedIn;
    final renpho = await _renpho.isLoggedIn;
    final aktiiaEmail = await _storage.read(key: 'aktiia_email');
    final garminEmail = await _storage.read(key: 'garmin_email');
    final renphoEmail = await _storage.read(key: 'renpho_email');
    final hilo = await _storage.read(key: 'hilo_mac_address') != null;
    final polar = await oauthTokenStore.isConnected('polar');
    final suunto = await oauthTokenStore.isConnected('suunto');
    final coros = await oauthTokenStore.isConnected('coros');

    final anyConnected =
        aktiia || garmin || renpho || hilo || polar || suunto || coros;
    state = AuthState(
      aktiiaConnected: aktiia,
      aktiiaEmail: aktiiaEmail,
      garminConnected: garmin,
      garminEmail: garminEmail,
      renphoConnected: renpho,
      renphoEmail: renphoEmail,
      status: anyConnected ? LoginStatus.loggedIn : LoginStatus.needsOnboarding,
    );
  }

  /// Called when a client reports its session is gone (401 on refresh).
  void markAktiiaDisconnected() {
    _aktiia.logout();
    state = state.copyWith(aktiiaConnected: false);
  }

  void markGarminDisconnected() {
    _garmin.logout();
    state = state.copyWith(garminConnected: false);
  }

  void markRenphoDisconnected() {
    _renpho.logout();
    state = state.copyWith(renphoConnected: false);
  }

  Future<void> loginAktiia(String email, String password) async {
    await _aktiia.login(email, password);
    await _storage.write(key: 'aktiia_email', value: email);
    state = state.copyWith(
      aktiiaConnected: true,
      aktiiaEmail: email,
      status: LoginStatus.loggedIn,
    );
  }

  Future<void> loginRenpho(String email, String password) async {
    await _renpho.login(email, password);
    await _storage.write(key: 'renpho_email', value: email);
    state = state.copyWith(renphoConnected: true, renphoEmail: email);
  }

  Future<void> loginGarmin(String email, String password) async {
    await _garmin.login(email, password);
    await _storage.write(key: 'garmin_email', value: email);
    state = state.copyWith(
      garminConnected: true,
      garminEmail: email,
      status: LoginStatus.loggedIn,
    );
  }

  Future<void> loginGarminMfa(String email, String code) async {
    await _garmin.loginWithMfa(code);
    await _storage.write(key: 'garmin_email', value: email);
    state = state.copyWith(
      garminConnected: true,
      garminEmail: email,
      status: LoginStatus.loggedIn,
    );
  }

  /// Finishes onboarding without connecting Garmin.
  Future<void> skipGarmin() async {
    state = state.copyWith(status: LoginStatus.loggedIn);
  }

  Future<void> logoutRenpho() async {
    await _renpho.logout();
    await _storage.delete(key: 'renpho_email');
    state = AuthState(
      aktiiaConnected: state.aktiiaConnected,
      aktiiaEmail: state.aktiiaEmail,
      garminConnected: state.garminConnected,
      garminEmail: state.garminEmail,
      status: state.status,
    );
  }

  Future<void> logoutAktiia() async {
    await _aktiia.logout();
    await _storage.delete(key: 'aktiia_email');
    state = AuthState(
      garminConnected: state.garminConnected,
      garminEmail: state.garminEmail,
      renphoConnected: state.renphoConnected,
      renphoEmail: state.renphoEmail,
      status: state.garminConnected
          ? LoginStatus.loggedIn
          : LoginStatus.needsOnboarding,
    );
  }

  Future<void> logoutGarmin() async {
    await _garmin.logout();
    await _storage.delete(key: 'garmin_email');
    state = AuthState(
      aktiiaConnected: state.aktiiaConnected,
      aktiiaEmail: state.aktiiaEmail,
      renphoConnected: state.renphoConnected,
      renphoEmail: state.renphoEmail,
      status: state.aktiiaConnected
          ? LoginStatus.loggedIn
          : LoginStatus.needsOnboarding,
    );
  }
}
