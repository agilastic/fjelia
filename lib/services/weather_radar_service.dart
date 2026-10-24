import 'dart:convert';

import 'package:http/http.dart' as http;

class RadarFrame {
  const RadarFrame(this.time, this.tileUrl);
  final DateTime time;
  final String tileUrl;
}

class WeatherRadarService {
  WeatherRadarService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  void dispose() => _client.close();
  Future<List<RadarFrame>> fetch() async {
    final response = await _client
        .get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw StateError('Radar unavailable');
    return parse(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static List<RadarFrame> parse(Map<String, dynamic> json) {
    final host = Uri.parse(json['host'] as String);
    if (host.scheme != 'https' || !host.host.endsWith('.rainviewer.com')) {
      throw const FormatException('Invalid radar host');
    }
    final radar = json['radar'] as Map?;
    return [
      for (final raw in (radar?['past'] as List? ?? []))
        RadarFrame(
          DateTime.fromMillisecondsSinceEpoch(
            (raw['time'] as num).toInt() * 1000,
            isUtc: true,
          ).toLocal(),
          '${host.toString()}${raw['path']}/256/{z}/{x}/{y}/2/1_1.png',
        ),
    ]..sort((a, b) => a.time.compareTo(b.time));
  }
}
