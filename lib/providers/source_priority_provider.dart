import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/source_priority_service.dart';
export '../services/source_priority_service.dart';

const _storage = FlutterSecureStorage();
const _key = 'source_priority_v3';

Map<String, List<String>> _deepCopy(Map<String, List<String>> m) => {
  for (final e in m.entries) e.key: List<String>.of(e.value),
};

class SourcePriorityNotifier extends AsyncNotifier<Map<String, List<String>>> {
  @override
  Future<Map<String, List<String>>> build() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return _deepCopy(defaultSourcePriorities);
    final saved = jsonDecode(raw) as Map<String, dynamic>;
    final result = <String, List<String>>{};
    for (final group in defaultSourcePriorities.keys) {
      final defaults = defaultSourcePriorities[group]!;
      final list = (saved[group] as List?)?.cast<String>() ?? defaults;
      // Keep only known sources, append new defaults the user hasn't seen.
      final merged = [
        ...list.where(defaults.contains),
        ...defaults.where((s) => !list.contains(s)),
      ];
      result[group] = merged;
    }
    return result;
  }

  Future<void> reorder(SourceGroup group, int oldIndex, int newIndex) async {
    final current = _deepCopy(state.requireValue);
    final list = current[group.name]!;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    await _storage.write(key: _key, value: jsonEncode(current));
    state = AsyncData(current);
  }

  Future<void> reset() async {
    await _storage.delete(key: _key);
    state = AsyncData(_deepCopy(defaultSourcePriorities));
  }
}

final sourcePriorityProvider =
    AsyncNotifierProvider<SourcePriorityNotifier, Map<String, List<String>>>(
      SourcePriorityNotifier.new,
    );
