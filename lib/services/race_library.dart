import 'package:fjelia_core/services/race_library.dart';
import 'package:http/http.dart' as http;

export 'package:fjelia_core/services/race_library.dart';

/// The race library over the app's HTTP client.
RaceLibrary httpRaceLibrary([http.Client? client]) {
  final c = client ?? http.Client();
  return RaceLibrary((url) async {
    final r = await c.get(url);
    return (status: r.statusCode, body: r.bodyBytes);
  });
}
