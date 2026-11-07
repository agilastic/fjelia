import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/gym_workout.dart';

/// Original interoperability code based on the supplied Matrix Home build's
/// LoginClient, WorkoutsParameters, Interval and DistanceMetric wire formats.
/// No third-party application keys, code or account credentials are embedded.
class MatrixXidSession {
  const MatrixXidSession({
    required this.origin,
    required this.userId,
    required this.cookie,
  });
  final Uri origin;
  final String userId, cookie;
  Map<String, Object> toJson() => {
    'origin': origin.toString(),
    'user': userId,
    'cookie': cookie,
  };
  factory MatrixXidSession.fromJson(Map<String, dynamic> j) {
    final session = MatrixXidSession(
      origin: matrixXidOrigin(j['origin'] as String),
      userId: j['user'] as String,
      cookie: j['cookie'] as String,
    );
    if (session.userId.isEmpty ||
        !RegExp(r'^JSESSIONID=[^;\s,]+$').hasMatch(session.cookie)) {
      throw const FormatException('Invalid xID session.');
    }
    return session;
  }
}

Uri matrixXidOrigin(String text) {
  final value = text.trim();
  final uri = Uri.tryParse(value.contains('://') ? value : 'https://$value');
  if (uri == null ||
      uri.scheme != 'https' ||
      !(uri.host == 'netpulse.com' || uri.host.endsWith('.netpulse.com')) ||
      uri.userInfo.isNotEmpty ||
      uri.port != 443 ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/')) {
    throw const FormatException(
      'Use your gym’s HTTPS Netpulse portal address.',
    );
  }
  return Uri(scheme: 'https', host: uri.host.toLowerCase());
}

class MatrixXidException implements Exception {
  const MatrixXidException(this.message, {this.expired = false});
  final String message;
  final bool expired;
  @override
  String toString() => message;
}

class MatrixXidBatch {
  const MatrixXidBatch(this.workouts, this.skipped);
  final List<GymWorkout> workouts;
  final int skipped;
}

class MatrixXidClient {
  MatrixXidClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;
  void close() => _http.close();

  Future<http.Response> _send(http.Request request) async {
    request.followRedirects = false;
    request.headers.addAll({
      'Accept': 'application/json',
      'X-NP-API-Version': '1.5',
      'User-Agent': 'Fjelia',
      'X-NP-User-Agent': 'clientType=MOBILE_DEVICE; applicationName=Fjelia; applicationVersion=1.3.1',
    });
    try {
      return await (() async {
        final response = await _http.send(request);
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > 5 * 1024 * 1024) {
            throw const MatrixXidException(
              'The workout response is too large.',
            );
          }
          bytes.add(chunk);
        }
        return http.Response.bytes(
          bytes.takeBytes(),
          response.statusCode,
          headers: response.headers,
        );
      })().timeout(const Duration(seconds: 25));
    } on MatrixXidException {
      rethrow;
    } catch (_) {
      // Never surface request URLs, passcodes, cookies or response bodies.
      throw const MatrixXidException(
        'Could not reach the gym’s workout service. Try again.',
      );
    }
  }

  Map<String, dynamic> _json(http.Response response, {bool login = false}) {
    if (response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode >= 300 && response.statusCode < 400) {
      throw MatrixXidException(
        login
            ? 'Sign-in was not accepted. Check the portal, xID and passcode. '
                  'Accounts migrated to EGYM may require the gym’s login page.'
            : 'Your xID session expired. Sign in again.',
        expired: !login,
      );
    }
    if (response.statusCode != 200) {
      throw const MatrixXidException(
        'The gym’s workout service could not complete this request.',
      );
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw const MatrixXidException(
        'This portal did not return supported workout data.',
      );
    }
  }

  Future<MatrixXidSession> login(
    String portal,
    String xid,
    String passcode,
  ) async {
    final origin = matrixXidOrigin(portal);
    if (xid.trim().isEmpty || passcode.isEmpty) {
      throw const FormatException('Enter your xID and passcode.');
    }
    final request = http.Request('POST', origin.replace(path: '/np/login'))
      ..bodyFields = {'username': xid.trim(), 'password': passcode};
    final response = await _send(request);
    final data = _json(response, login: true);
    final user = data['uuid'];
    final cookie = RegExp(
      r'(?:^|[,\s])JSESSIONID=([^;,\s]+)',
      caseSensitive: false,
    ).firstMatch(response.headers['set-cookie'] ?? '')?.group(1);
    if (user is! String || user.isEmpty || cookie == null) {
      throw const MatrixXidException(
        'This portal did not provide a supported xID session.',
      );
    }
    return MatrixXidSession(
      origin: origin,
      userId: user,
      cookie: 'JSESSIONID=$cookie',
    );
  }

  Future<MatrixXidBatch> workouts(
    MatrixXidSession session, {
    required DateTime from,
    required DateTime through,
  }) async {
    // Validate even a caller-created session before sending its cookie.
    MatrixXidSession.fromJson(session.toJson());
    final first = DateTime.utc(from.year, from.month, from.day);
    final last = DateTime.utc(through.year, through.month, through.day);
    if (last.isBefore(first) || last.difference(first).inDays > 365) {
      throw const FormatException('Choose a period of at most one year.');
    }
    final result = <String, GymWorkout>{};
    var skipped = 0;
    // Small date windows avoid silently truncating a long account history.
    for (
      var day = first;
      !day.isAfter(last);
      day = day.add(const Duration(days: 7))
    ) {
      final next = day.add(const Duration(days: 6));
      final end = next.isAfter(last) ? last : next;
      String date(DateTime d) =>
          '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
      final uri = session.origin.replace(
        pathSegments: ['np', 'exerciser', session.userId, 'workouts'],
        queryParameters: {
          'interval': 'single',
          'filter': 'treadmill',
          'intervalCount': '200',
          'startDate': date(day),
          'endDate': date(end),
        },
      );
      final response = await _send(
        http.Request('GET', uri)..headers['Cookie'] = session.cookie,
      );
      final batch = decodeMatrixWorkouts(_json(response), session);
      if (batch.workouts.length + batch.skipped >= 200) {
        throw const MatrixXidException(
          'Too many workouts in one week. Choose a shorter import period.',
        );
      }
      skipped += batch.skipped;
      for (final w in batch.workouts) {
        if (!w.startedAt.isBefore(first) &&
            w.startedAt.isBefore(last.add(const Duration(days: 1)))) {
          result[w.id] = w;
        }
      }
    }
    final workouts = result.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return MatrixXidBatch(workouts, skipped);
  }
}

MatrixXidBatch decodeMatrixWorkouts(
  Map<String, dynamic> data,
  MatrixXidSession session,
) {
  final intervals = data['intervals'];
  if (intervals is! List) {
    throw const MatrixXidException(
      'This portal returned an unsupported workout format.',
    );
  }
  double? number(dynamic v) => v is num && v.isFinite ? v.toDouble() : null;
  final workouts = <GymWorkout>[];
  var skipped = 0;
  for (final raw in intervals) {
    try {
      if (raw is! Map) throw const FormatException();
      final j = raw.cast<String, dynamic>();
      final id = j['id'];
      final time = j['startDateUtc'];
      final seconds = j['totalDuration'];
      if (id == null ||
          '$id'.isEmpty ||
          time is! num ||
          !time.isFinite ||
          time < 946684800000 ||
          time > 7258118400000 ||
          seconds is! num ||
          !seconds.isFinite ||
          seconds != seconds.round() ||
          j['totalWorkout'] != null && j['totalWorkout'] != 1) {
        throw const FormatException();
      }
      final distance = number(j['totalDistance']);
      for (final key in ['totalDistance', 'totalCalories', 'avgHeartRate']) {
        if (j[key] != null && number(j[key]) == null) {
          throw const FormatException();
        }
      }
      final unit = j['distanceUnit'] ?? data['distanceUnit'];
      final factor = switch (unit) {
        'kilometer' => 1000.0,
        'mile' => 1609.344,
        'meter' => 1.0,
        'foot' => 0.3048,
        _ => null,
      };
      if (distance != null && factor == null) throw const FormatException();
      final hr = number(j['avgHeartRate']);
      final workout = GymWorkout(
        id: GymWorkout.stableId(
          'matrix_xid',
          '${session.origin}|${session.userId}|$id',
        ),
        startedAt: DateTime.fromMillisecondsSinceEpoch(
          time.toInt(),
          isUtc: true,
        ),
        durationSeconds: seconds.toInt(),
        distanceMeters: distance == null ? null : distance * factor!,
        calories: number(j['totalCalories']),
        avgHeartRate: hr == null || hr == 0 ? null : hr,
        source: 'matrix_xid',
        name:
            'Matrix · ${j['equipmentType'] is String && (j['equipmentType'] as String).isNotEmpty ? j['equipmentType'] : 'Treadmill'}',
      );
      workout.validate();
      workouts.add(workout);
    } catch (_) {
      skipped++;
    }
  }
  return MatrixXidBatch(workouts, skipped);
}
