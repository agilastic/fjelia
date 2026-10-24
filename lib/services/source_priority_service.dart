import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Which kind of data a priority list applies to.
enum SourceGroup { sleep, activity, body }

const defaultSourcePriorities = <String, List<String>>{
  'sleep': [
    'health_connect',
    'aktiia',
    'hilo_ble',
    'garmin_api',
    'coros',
    'polar',
    'suunto',
  ],
  'activity': ['garmin_api', 'coros', 'polar', 'suunto', 'health_connect'],
  'body': [
    'health_connect',
    'garmin_api',
    'renpho',
    'coros',
    'polar',
    'suunto',
  ],
};

const _storage = FlutterSecureStorage();
const _key = 'source_priority_v3';

/// Whether data from [incoming] may replace data stored from [existing].
/// Earlier in [priority] wins; unknown incoming sources never overwrite.
bool shouldOverwrite(String? existing, String incoming, List<String> priority) {
  if (existing == null || existing.isEmpty) return true;
  if (existing == incoming) return true;
  final existingIdx = priority.indexOf(existing);
  final incomingIdx = priority.indexOf(incoming);
  if (incomingIdx == -1) return false;
  if (existingIdx == -1) return true;
  return incomingIdx < existingIdx;
}

/// Saved priority list for [group] (defaults if never customised).
Future<List<String>> priorityForGroup(SourceGroup group) async {
  final raw = await _storage.read(key: _key);
  if (raw != null) {
    final saved = jsonDecode(raw) as Map<String, dynamic>;
    final list = (saved[group.name] as List?)?.cast<String>();
    if (list != null && list.isNotEmpty) return list;
  }
  return defaultSourcePriorities[group.name]!;
}
