import 'dart:convert';

import 'package:fjelia_core/services/race_library.dart';
import 'package:http/http.dart' as http;

export 'package:fjelia_core/services/race_library.dart';

/// Public race library at races.fjelia.com: typeahead for race names, and
/// the date, distances and climb of the chosen race. Only the typed text goes
/// out; nothing about the user. Any failure gives no suggestions, so entering
/// a race by hand always works.
class RaceLibrary {
  RaceLibrary({http.Client? client, Uri? base})
    : _client = client ?? http.Client(),
      _base = base ?? raceLibraryBase;

  final http.Client _client;
  final Uri _base;
  static const _timeout = Duration(seconds: 5);

  /// Races whose name or town matches [query]; empty under 3 characters.
  Future<List<RaceHit>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final json = await _get('/v1/search', {
      'q': q.length > 80 ? q.substring(0, 80) : q,
      'limit': '8',
    });
    return json == null ? const [] : parseRaceHits(json);
  }

  /// The edition's races (distances), longest first; null when unavailable.
  Future<RaceEdition?> edition(String id) async {
    final json = await _get('/v1/editions/${Uri.encodeComponent(id)}', {});
    return json == null ? null : parseRaceEdition(json);
  }

  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, String> query,
  ) async {
    try {
      final response = await _client
          .get(_base.replace(path: path, queryParameters: query))
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }

  /// The course GPX of [race], or null when the library has none or it
  /// cannot be fetched. The library forwards to the organiser's file.
  Future<String?> courseGpx(RaceDistance race) async {
    final path = race.gpxPath;
    if (path == null) return null;
    try {
      final response = await _client
          .get(_base.resolve(path))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }
}
