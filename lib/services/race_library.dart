import 'dart:convert';

import 'package:http/http.dart' as http;

/// Public race library at races.fjelia.com: typeahead for race names, and
/// the date, distances and climb of the chosen race. Only the typed text goes
/// out; nothing about the user. Any failure gives no suggestions, so entering
/// a race by hand always works.
class RaceLibrary {
  RaceLibrary({http.Client? client, Uri? base})
    : _client = client ?? http.Client(),
      _base = base ?? Uri.parse('https://races.fjelia.com');

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
}

/// A search hit with its next (or latest) edition.
class RaceHit {
  const RaceHit({
    required this.eventId,
    required this.title,
    required this.sport,
    this.place,
    this.editionId,
    this.date,
    this.upcoming = false,
    this.distancesKm = const [],
    this.maxGainM,
  });

  final String eventId;

  /// "Name – Town".
  final String title;

  /// The app's sport id (`running`, `trail_running`, …), null when unknown.
  final String? sport;
  final String? place;
  final String? editionId;
  final DateTime? date;
  final bool upcoming;
  final List<double> distancesKm;
  final int? maxGainM;
}

class RaceEdition {
  const RaceEdition({
    required this.title,
    required this.date,
    required this.races,
    this.sport,
    this.sourceName,
    this.website,
  });

  final String title;
  final DateTime date;
  final String? sport;
  final List<RaceDistance> races;

  /// Where the facts come from, shown with them.
  final String? sourceName;
  final String? website;
}

class RaceDistance {
  const RaceDistance({
    required this.distanceKm,
    this.name,
    this.elevationGainM,
    this.sport,
  });

  final String? name;
  final double distanceKm;
  final int? elevationGainM;
  final String? sport;
}

/// Library sport → the race goal editor's sport id.
String? appSport(Object? sport) => switch (sport) {
  'run' => 'running',
  'trail' => 'trail_running',
  'triathlon' => 'triathlon',
  'road_bike' || 'brevet' => 'cycling_road',
  'gravel' => 'cycling_gravel',
  'mtb' => 'cycling_mtb',
  _ => null,
};

List<RaceHit> parseRaceHits(Map<String, dynamic> json) => [
  for (final hit in (json['hits'] as List? ?? const []).whereType<Map>())
    if (hit['event_id'] is String)
      RaceHit(
        eventId: hit['event_id'] as String,
        title: '${hit['title'] ?? hit['name'] ?? ''}',
        sport: appSport(hit['sport']),
        place: hit['place'] as String?,
        editionId: (hit['next_edition'] as Map?)?['id'] as String?,
        date: DateTime.tryParse(
          '${(hit['next_edition'] as Map?)?['date_start']}',
        ),
        upcoming: (hit['next_edition'] as Map?)?['upcoming'] == true,
        distancesKm: [
          for (final km
              in ((hit['next_edition'] as Map?)?['distances_km'] as List? ??
                      const [])
                  .whereType<num>())
            km.toDouble(),
        ],
        maxGainM: ((hit['next_edition'] as Map?)?['max_gain_m'] as num?)
            ?.round(),
      ),
];

RaceEdition? parseRaceEdition(Map<String, dynamic> json) {
  final date = DateTime.tryParse('${json['date_start']}');
  final event = json['event'];
  if (date == null || event is! Map) return null;
  return RaceEdition(
    title: '${event['title'] ?? event['name'] ?? ''}',
    date: date,
    sport: appSport(event['sport']),
    sourceName: (json['source'] as Map?)?['name'] as String?,
    website: event['website'] as String?,
    races: [
      for (final race in (json['races'] as List? ?? const []).whereType<Map>())
        if (race['distance_km'] is num)
          RaceDistance(
            name: race['name'] as String?,
            distanceKm: (race['distance_km'] as num).toDouble(),
            elevationGainM: (race['elevation_gain_m'] as num?)?.round(),
            sport: appSport(race['discipline']),
          ),
    ],
  );
}
