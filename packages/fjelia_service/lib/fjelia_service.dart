/// Stub of the optional service package (no Aktiia / Hilo support).
library;

import 'dart:async';

import 'package:fjelia_service_api/fjelia_service_api.dart';

/// Whether this build contains the real service implementation.
const hasServicePackage = false;

AktiiaClient createAktiiaClient() => _UnavailableAktiiaClient();

HiloBleService createHiloBleService({
  Future<bool> Function()? onUploadComplete,
}) => _UnavailableHiloBleService();

SuuntoRequestSigner createSuuntoSigner() => _UnavailableSuuntoSigner();

const _message = 'Aktiia / Hilo is not available in this build.';

class _UnavailableSuuntoSigner implements SuuntoRequestSigner {
  @override
  bool get isAvailable => false;

  @override
  String totp(String salt) =>
      throw StateError('Suunto is not available in this build.');
}

class _UnavailableAktiiaClient implements AktiiaClient {
  @override
  Future<bool> get isLoggedIn async => false;

  @override
  Future<void> login(String email, String password) =>
      Future.error(AktiiaApiException(_message));

  @override
  Future<void> logout() async {}

  @override
  Future<List<BloodPressureMeasurement>> getMeasurements(
    DateTime from,
    DateTime to, {
    int page = 0,
  }) async => const [];

  @override
  Future<DailyBpSummary> getDailyBp(DateTime date) =>
      Future.error(AktiiaApiException(_message));
}

class _UnavailableHiloBleService implements HiloBleService {
  final _controller = StreamController<HiloSyncState>.broadcast();

  @override
  HiloSyncState get state => const HiloSyncState();

  @override
  Stream<HiloSyncState> get stateStream => _controller.stream;

  @override
  Future<String?> getPairedMac() async => null;

  @override
  Future<String?> getPairedName() async => null;

  @override
  Future<String?> getCuffMac() async => null;

  @override
  Future<String?> getCuffName() async => null;

  @override
  Future<void> pairDevice(String mac, String name) async {}

  @override
  Future<void> pairCuff(String mac, String name) async {}

  @override
  Future<void> unpairDevice() async {}

  @override
  Future<void> unpairCuff() async {}

  @override
  Future<List<HiloFoundDevice>> scanForDevices() async => const [];

  @override
  Future<void> triggerSync() async {}

  @override
  Future<({int diastolic, int heartRate, int systolic})>
  triggerCuffMeasurement() => Future.error(StateError(_message));

  @override
  void dispose() => unawaited(_controller.close());
}
