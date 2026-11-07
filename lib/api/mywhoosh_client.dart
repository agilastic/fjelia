import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// The MyWhoosh account was refused or the session ended.
class MyWhooshAuthException implements Exception {
  const MyWhooshAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// MyWhoosh keeps one session per account: the athlete is signed in on
/// another device, usually the MyWhoosh app itself.
class MyWhooshSignedInElsewhere extends MyWhooshAuthException {
  const MyWhooshSignedInElsewhere(super.message);
}

/// A signed-in MyWhoosh account.
class MyWhooshSession {
  const MyWhooshSession({required this.accessToken, this.whooshId});
  final String accessToken;
  final String? whooshId;
}

/// One ride in the MyWhoosh activity list.
class MyWhooshActivity {
  const MyWhooshActivity({
    required this.id,
    required this.start,
    this.title,
    this.fileId,
    this.distanceKm,
    this.durationSeconds,
    this.avgWatts,
    this.avgHeartRate,
    this.elevation,
    this.routeName,
  });

  /// Null when the row has no id or no time.
  static MyWhooshActivity? fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'];
    final iso = json['startDatetime'];
    final date = json['date'];
    final start = iso is String && iso.isNotEmpty
        ? DateTime.tryParse(iso)?.toLocal()
        : date is num
        ? DateTime.fromMillisecondsSinceEpoch(
            (date * 1000).round(),
            isUtc: true,
          ).toLocal()
        : null;
    if (id == null || start == null) return null;
    double? number(Object? v) {
      final d = v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
      return d == null || d <= 0 ? null : d;
    }

    final title = json['title'];
    final route = json['routeName'];
    final file = json['activityFileId'];
    return MyWhooshActivity(
      id: '$id',
      start: start,
      title: title is String && title.trim().isNotEmpty ? title.trim() : null,
      fileId: file == null || '$file'.isEmpty ? null : '$file',
      distanceKm: number(json['distance']),
      durationSeconds: parseRideDuration(json['rideDuration']),
      avgWatts: number(json['watt']),
      avgHeartRate: number(json['heartrate']),
      elevation: number(json['elevation']),
      routeName: route is String && route.trim().isNotEmpty
          ? route.trim()
          : null,
    );
  }

  final String id;
  final DateTime start;
  final String? title, fileId, routeName;
  final double? distanceKm, avgWatts, avgHeartRate, elevation;
  final int? durationSeconds;
}

/// "01:31:54.000" in seconds; null when it is not such a time.
int? parseRideDuration(Object? v) {
  if (v is num) return v > 0 ? v.round() : null;
  if (v is! String) return null;
  final parts = v.split('.').first.split(':').map(int.tryParse).toList();
  if (parts.length != 3 || parts.contains(null)) return null;
  final s = parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
  return s > 0 ? s : null;
}

/// MyWhoosh's own app interface (undocumented): sign-in, the activity list
/// and the FIT file of a ride.
class MyWhooshClient {
  MyWhooshClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static final _login = Uri.parse(
    'https://services.mywhoosh.com/http-service/api/login',
  );
  static const _base = 'https://service14.mywhoosh.com/v2/rider/profile';

  Future<MyWhooshSession> login(String email, String password) async {
    final response = await _http.post(
      _login,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Username': email,
        'Password': password,
        'Platform': 'Android',
        'Action': 1001,
        'CorrelationId': const Uuid().v4(),
        'DeviceId': const Uuid().v4(),
        'Authorization': '',
      }),
    );
    final json = _decode(response);
    final token = json['AccessToken'];
    if (json['Success'] != true || token is! String || token.isEmpty) {
      final message = json['Message'];
      final text = message is String && message.isNotEmpty
          ? message
          : 'Login failed';
      // LoginType 4: "You are already logged in from another device."
      if (json['LoginType'] == 4) throw MyWhooshSignedInElsewhere(text);
      throw MyWhooshAuthException(text);
    }
    final id = json['WhooshId'];
    return MyWhooshSession(accessToken: token, whooshId: id?.toString());
  }

  Map<String, String> _headers(MyWhooshSession s) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${s.accessToken}',
  };

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw MyWhooshAuthException('HTTP ${response.statusCode}');
    }
    if (response.statusCode >= 400) {
      throw Exception('MyWhoosh HTTP ${response.statusCode}');
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('MyWhoosh: unexpected response');
    }
    return json;
  }

  /// One page of rides, newest first, and how many pages there are.
  Future<({List<MyWhooshActivity> rides, int pages})> activities(
    MyWhooshSession session, {
    int page = 1,
  }) async {
    final response = await _http.post(
      Uri.parse('$_base/activities'),
      headers: _headers(session),
      body: jsonEncode({'sortDate': 'DESC', 'page': page}),
    );
    final data = _decode(response)['data'];
    final results = data is Map ? data['results'] : null;
    final pages = data is Map ? data['totalPages'] : null;
    return (
      rides: [
        if (results is List)
          for (final r in results.whereType<Map<String, dynamic>>())
            ?MyWhooshActivity.fromJson(r),
      ],
      pages: pages is num ? pages.toInt() : 1,
    );
  }

  /// The FIT file of a ride, through the signed link MyWhoosh hands out.
  Future<Uint8List> fitFile(MyWhooshSession session, String fileId) async {
    final response = await _http.post(
      Uri.parse('$_base/download-activity-file'),
      headers: _headers(session),
      body: jsonEncode({'fileId': fileId}),
    );
    final link = _decode(response)['data'];
    if (link is! String || link.isEmpty) {
      throw const FormatException('MyWhoosh: no download link');
    }
    final file = await _http.get(Uri.parse(link));
    if (file.statusCode >= 400) {
      throw Exception('MyWhoosh FIT HTTP ${file.statusCode}');
    }
    return file.bodyBytes;
  }
}
