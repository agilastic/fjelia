import '../config/secrets.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/renpho_data.dart';
import '../utils/log.dart';

class RenphoApiException implements Exception {
  const RenphoApiException(this.operation, this.message, {this.code});

  final String operation;
  final int? code;
  final String message;

  @override
  String toString() => '$operation failed: code=$code, msg=$message';
}

abstract class RenphoStorage {}

class _FlutterSecureRenphoStorage implements RenphoStorage {
  const _FlutterSecureRenphoStorage(this.storage);

  final FlutterSecureStorage storage;
}

/// Client for the Renpho Health cloud (app version 6.6.0 protocol). Request
/// and response payloads are AES-128/ECB encrypted JSON.
class RenphoClient {
  RenphoClient({http.Client? client})
      : _http = client ?? http.Client(),
        _store = const _FlutterSecureRenphoStorage(FlutterSecureStorage());

  final http.Client _http;
  // ignore: unused_field
  final RenphoStorage _store;

  static const _baseUrl = 'https://cloud.renpho.com';
  static const _appVersion = '6.6.0';
  static const _pageSize = 50;

  static const _storage = FlutterSecureStorage();
  static const _kToken = 'renpho_token';
  static const _kUserId = 'renpho_user_id';
  static const _kEmail = 'renpho_email';
  static const _kPassword = 'renpho_password';

  /// AES key of the Renpho protocol (build-time secret).
  static Encrypter get _encrypter {
    if (!Secrets.hasRenpho) throw Secrets.missing('Renpho');
    return Encrypter(AES(
      Key.fromUtf8(Secrets.renphoAesKey),
      mode: AESMode.ecb,
      padding: 'PKCS7',
    ));
  }

  Future<bool> get isLoggedIn async =>
      await _storage.read(key: _kToken) != null;

  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: _kToken),
      _storage.delete(key: _kUserId),
      _storage.delete(key: _kEmail),
      _storage.delete(key: _kPassword),
    ]);
  }

  Future<void> login(String email, String password) async {
    log('[Renpho] login: $email');
    final payload = {
      'questionnaire': <String, dynamic>{},
      'login': {
        'password': password,
        'areaCode': 'US',
        'appRevision': _appVersion,
        'cellphoneType': 'Fjelia',
        'systemType': '11',
        'email': email,
        'platform': 'android',
      },
      'bindingList': {
        'deviceTypes': const [
          '01', '02', '03', '04', '05', '06', '07', '08', '09', '0A', //
          '0B', '0C', '0D', '0E', '0F', '10', '11', '12', '13', '14',
        ],
      },
    };
    final json = await _post('renpho-aggregation/user/login',
        {'encryptData': _encryptJson(payload)},
        auth: false);
    _checkResponse(json, 'Login');

    final data = _decryptData(json['data'] as String);
    final login = data['login'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final token = login['token'] as String?;
    if (token == null) {
      throw const RenphoApiException('Login', 'No token in login response');
    }
    final userId = login['id'];
    await Future.wait([
      _storage.write(key: _kToken, value: token),
      if (userId != null) _storage.write(key: _kUserId, value: '$userId'),
      _storage.write(key: _kEmail, value: email),
      _storage.write(key: _kPassword, value: password),
    ]);
    log('[Renpho] login: success userId=${userId ?? '—'}');
  }

  /// All measurements of the logged-in user across every bound scale,
  /// oldest first.
  Future<List<RenphoMeasurement>> getAllMeasurements() async {
    if (!await isLoggedIn) {
      throw const RenphoApiException('GetAllMeasurements', 'Not logged in');
    }
    log('[Renpho] getAllMeasurements: starting');

    Map<String, dynamic> info;
    try {
      info = await getDeviceInfo();
    } on RenphoApiException {
      log('[Renpho] getAllMeasurements: token expired, attempting relogin');
      if (!await _reloginIfNeeded()) rethrow;
      info = await getDeviceInfo();
    }

    final scales =
        (info['scale'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final storedUid = await _storage.read(key: _kUserId);
    final uid = int.tryParse(storedUid ?? '');

    final all = <RenphoMeasurement>[];
    for (final scale in scales) {
      final table = scale['tableName'] as String?;
      final count = (scale['count'] as num?)?.toInt() ?? 0;
      final bodyComp = scale['bodyCompositionScale'] == true ||
          scale['bodyCompositionScaleImpedanceExists'] == true;
      final userIds =
          (scale['userIds'] as List?)?.map((e) => '$e').toList() ?? const [];
      var scaleUid = uid;
      if (scaleUid == null || !userIds.contains('$scaleUid')) {
        scaleUid = userIds.isNotEmpty ? int.tryParse(userIds.first) : uid;
      }
      log('[Renpho] scale: table=$table count=$count bodyComp=$bodyComp '
          'scaleUserIds=$userIds uid=$scaleUid');
      if (table == null || scaleUid == null) continue;

      if (bodyComp) {
        all.addAll(await getBodyCompositionMeasurements(table, scaleUid));
      }
      all.addAll(await getMeasurements(table, count, scaleUid));
    }

    all.sort((a, b) => (a.timestamp.millisecondsSinceEpoch ~/ 1000)
        .compareTo(b.timestamp.millisecondsSinceEpoch ~/ 1000));
    log('[Renpho] getAllMeasurements: ${all.length} measurements');
    return all;
  }

  Future<List<RenphoMeasurement>> getMeasurements(
      String table, int total, int userId) async {
    final result = <RenphoMeasurement>[];
    var page = 1;
    while (true) {
      log('[Renpho] getMeasurements: table=$table page=$page total=$total');
      final json = await _post('RenphoHealth/scale/queryAllMeasureDataList', {
        'encryptData': _encryptJson({
          'pageNum': page,
          'pageSize': _pageSize,
          'userIds': ['$userId'],
          'tableName': table,
        }),
      });
      _checkResponse(json, 'Measurements page $page');
      final records = _extractRecords(_decryptData(json['data'] as String));
      result.addAll(records.map(RenphoMeasurement.fromJson));
      if (records.length < _pageSize || result.length >= total) break;
      page++;
    }
    return result;
  }

  Future<List<RenphoMeasurement>> getBodyCompositionMeasurements(
      String table, int userId) async {
    final result = <RenphoMeasurement>[];
    var page = 1;
    while (true) {
      // ignore: avoid_print
      print('[Renpho] getBodyCompositionMeasurements: table=$table page=$page');
      final json =
          await _post('RenphoHealth/scale/queryBodyCompositionMeasureData', {
        'encryptData': _encryptJson({
          'pageNum': page,
          'pageSize': _pageSize,
          'userIds': ['$userId'],
          'tableName': table,
        }),
      });
      _checkResponse(json, 'BodyCompositionMeasurements page $page');
      final records = _extractRecords(_decryptData(json['data'] as String));
      result.addAll(records.map(RenphoMeasurement.fromJson));
      if (records.length < _pageSize) break;
      page++;
    }
    return result;
  }

  /// Bound devices. The endpoint accepts either an encrypted empty byte
  /// payload or an encrypted empty object depending on the account, so both
  /// are tried.
  Future<Map<String, dynamic>> getDeviceInfo() async {
    log('[Renpho] getDeviceInfo');
    Map<String, dynamic>? fallback;
    Object? lastError;
    for (final body in [_encryptEmptyBytes(), _encryptEmptyObject()]) {
      try {
        final json = await _post('renpho-aggregation/device/count', body);
        final data = json['data'];
        final decrypted = data is String ? _decryptData(data) : null;
        _checkResponse(json, 'GetDeviceInfo');
        if (decrypted != null && decrypted['scale'] is List) {
          log('[Renpho] getDeviceInfo: scales='
              '${(decrypted['scale'] as List).length}');
          return decrypted;
        }
        fallback ??= decrypted;
      } catch (e) {
        log('[Renpho] getDeviceInfo attempt error: $e');
        lastError = e;
      }
    }
    if (fallback != null) {
      log('[Renpho] getDeviceInfo: using fallback decrypted data');
      return fallback;
    }
    if (lastError != null) throw lastError;
    throw const RenphoApiException('GetDeviceInfo', 'No response');
  }

  Future<bool> _reloginIfNeeded() async {
    final email = await _storage.read(key: _kEmail);
    final password = await _storage.read(key: _kPassword);
    if (email == null || password == null) {
      log('[Renpho] relogin: no stored credentials');
      return false;
    }
    log('[Renpho] relogin: attempting with stored credentials');
    try {
      await login(email, password);
      log('[Renpho] relogin: success');
      return true;
    } catch (e) {
      log('[Renpho] relogin: failed — $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl/$path');
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.read(key: _kToken);
      final userId = await _storage.read(key: _kUserId);
      headers['token'] = token ?? 'None';
      if (userId != null) headers['userId'] = userId;
    }
    headers['appVersion'] = _appVersion;
    headers['platform'] = 'android';

    final response =
        await _http.post(uri, headers: headers, body: jsonEncode(body));
    log('[Renpho] POST $path → ${response.statusCode}');
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw RenphoApiException(path, 'Unexpected response',
        code: response.statusCode);
  }

  static void _checkResponse(Map<String, dynamic> json, String operation) {
    final code = json['code'];
    final msg = json['msg'] as String? ?? '';
    log('[Renpho] $operation: code=$code msg=$msg');
    const ok = <Object>{
      'success', 0, '0', 1, '1', 101, '101', 200, '200', 20000, '20000', //
    };
    if (ok.contains(code)) return;
    throw RenphoApiException(operation, msg, code: int.tryParse('$code'));
  }

  String _encryptJson(Object payload) =>
      base64.encode(_encrypter.encrypt(jsonEncode(payload)).bytes);

  Map<String, dynamic> _encryptEmptyObject() =>
      {'encryptData': _encryptJson(<String, dynamic>{})};

  Map<String, dynamic> _encryptEmptyBytes() =>
      {'encryptData': _encryptEmptyBytePayload()};

  String _encryptEmptyBytePayload() =>
      base64.encode(_encrypter.encryptBytes(Uint8List(0)).bytes);

  Map<String, dynamic> _decryptData(String data) {
    final decoded = jsonDecode(_encrypter.decrypt64(data));
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  /// Renpho wraps record lists differently per endpoint.
  static List<Map<String, dynamic>> _extractRecords(Object? data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .where((m) => m.containsKey('weight'))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      for (final key in const ['list', 'data', 'records', 'measurements']) {
        final value = data[key];
        if (value is String) return _extractRecords(jsonDecode(value));
        if (value is List || value is Map) return _extractRecords(value);
      }
    }
    return const [];
  }
}
