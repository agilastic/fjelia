import 'dart:convert';

import 'package:fjelia_core/services/source_priority.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

export 'package:fjelia_core/services/source_priority.dart';

const _storage = FlutterSecureStorage();
const _key = 'source_priority_v3';

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
