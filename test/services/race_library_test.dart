import 'dart:convert';

import 'package:fjelia/services/race_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const hit = {
    'hits': [
      {
        'event_id': 'zugspitz-utmb',
        'name': 'Zugspitz Ultra Trail by UTMB',
        'title': 'Zugspitz Ultra Trail by UTMB – Garmisch-Partenkirchen',
        'sport': 'trail',
        'place': 'Garmisch-Partenkirchen',
        'next_edition': {
          'id': 'zugspitz-utmb-2027-06-18',
          'date_start': '2027-06-18',
          'upcoming': true,
          'distances_km': [107.5, 15.7],
          'max_gain_m': 5280,
        },
      },
    ],
  };
  const edition = {
    'date_start': '2027-06-18',
    'source': {'name': 'UTMB World Series'},
    'event': {
      'title': 'Zugspitz Ultra Trail by UTMB – Garmisch-Partenkirchen',
      'sport': 'trail',
      'website': 'https://zugspitz.utmb.world',
    },
    'races': [
      {
        'name': 'ZUT 100',
        'distance_km': 107.5,
        'elevation_gain_m': 5280,
        'discipline': 'trail',
      },
      {
        'name': 'Grainau Trail',
        'distance_km': 15.7,
        'elevation_gain_m': 600,
        'discipline': 'trail',
      },
    ],
  };

  test('search sends only the typed text and maps the hit', () async {
    final seen = <Uri>[];
    final library = httpRaceLibrary(
      MockClient((request) async {
        seen.add(request.url);
        return http.Response.bytes(utf8.encode(jsonEncode(hit)), 200);
      }),
    );
    final hits = await library.search('  zugsp ');
    expect(seen.single.path, '/v1/search');
    expect(seen.single.queryParameters, {'q': 'zugsp', 'limit': '8'});
    expect(hits.single.title, endsWith('– Garmisch-Partenkirchen'));
    expect(hits.single.sport, 'trail_running');
    expect(hits.single.date, DateTime(2027, 6, 18));
    expect(hits.single.distancesKm, [107.5, 15.7]);
    expect(await library.search('zu'), isEmpty);
    expect(seen, hasLength(1));
  });

  test('edition lists the distances with their climb and source', () async {
    final library = httpRaceLibrary(
      MockClient(
        (_) async => http.Response.bytes(utf8.encode(jsonEncode(edition)), 200),
      ),
    );
    final result = (await library.edition('zugspitz-utmb-2027-06-18'))!;
    expect(result.sourceName, 'UTMB World Series');
    expect(result.races.map((r) => (r.name, r.distanceKm, r.elevationGainM)), [
      ('ZUT 100', 107.5, 5280),
      ('Grainau Trail', 15.7, 600),
    ]);
  });

  test('failures give no suggestions instead of errors', () async {
    final down = httpRaceLibrary(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(await down.search('hannover'), isEmpty);
    expect(await down.edition('x'), isNull);
    final busy = httpRaceLibrary(
      MockClient((_) async => http.Response('slow down', 429)),
    );
    expect(await busy.search('hannover'), isEmpty);
  });

  test('library sports map to the editor sports', () {
    expect(appSport('run'), 'running');
    expect(appSport('brevet'), 'cycling_road');
    expect(appSport('gravel'), 'cycling_gravel');
    expect(appSport('swimrun'), isNull);
  });
}
