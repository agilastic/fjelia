import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/log.dart';

/// Persistent, device-local cache for completed AI answers.
///
/// The cache stores only a digest of the complete request as its key. The
/// request text is never written to disk or included in diagnostics. Answers
/// live in the app's private support directory for at most five hours.
class AiResponseCache {
  AiResponseCache({
    Future<Directory> Function()? supportDirectory,
    DateTime Function()? clock,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
       _clock = clock ?? DateTime.now;

  static const ttl = Duration(hours: 5);
  static const _maxEntries = 80;
  static const _maxAnswerBytes = 512 * 1024;
  static const _keyVersion = 'fjelia-ai-response-v1';
  static Future<void> _operationQueue = Future<void>.value();

  final Future<Directory> Function() _supportDirectory;
  final DateTime Function() _clock;

  /// Hash all request inputs that can change the answer, scoped to this app
  /// installation. This makes model, prompt, context, question and parameter
  /// changes naturally invalidate earlier answers.
  static String keyFor({
    required String installationId,
    required String provider,
    required String model,
    required String kind,
    required Object request,
  }) {
    final encoded = jsonEncode({
      'version': _keyVersion,
      'installation': installationId,
      'provider': provider,
      'model': model,
      'kind': kind,
      'request': request,
    });
    return sha256.convert(utf8.encode(encoded)).toString();
  }

  Future<AiCachedAnswer?> read(String key) => _serialized(() async {
    final now = _clock().millisecondsSinceEpoch;
    final entries = await _readEntries();
    var changed = false;
    entries.removeWhere((_, value) {
      final expires = value['expiresAt'] as int? ?? 0;
      final expired = expires <= now;
      changed |= expired;
      return expired;
    });
    final value = entries[key];
    if (changed) await _writeEntries(entries);
    if (value == null) {
      log('[AiCache] miss key=${key.substring(0, 12)}');
      return null;
    }
    final text = value['text'];
    if (text is! String || text.trim().isEmpty) {
      entries.remove(key);
      await _writeEntries(entries);
      log('[AiCache] miss key=${key.substring(0, 12)} reason=invalid_entry');
      return null;
    }
    final answer = AiCachedAnswer(
      text: text,
      source: value['source'] as String?,
      model: value['model'] as String?,
      inputTokensEstimate: value['inputTokensEstimate'] as int? ?? 0,
      outputTokensEstimate: value['outputTokensEstimate'] as int? ?? 0,
      costUsdEstimate: (value['costUsdEstimate'] as num?)?.toDouble(),
    );
    final savedCost = answer.costUsdEstimate == null
        ? 'not_reported'
        : answer.costUsdEstimate!.toStringAsFixed(6);
    log(
      '[AiCache] hit key=${key.substring(0, 12)} '
      'input_tokens_saved_est=${answer.inputTokensEstimate} '
      'output_tokens_saved_est=${answer.outputTokensEstimate} '
      'cost_saved_usd_est=$savedCost',
    );
    return answer;
  });

  Future<void> write(
    String key,
    AiCachedAnswer answer, {
    required String kind,
    required String model,
    required int inputBytes,
  }) => _serialized(() async {
    if (answer.text.trim().isEmpty ||
        utf8.encode(answer.text).length > _maxAnswerBytes) {
      log('[AiCache] skip_store kind=$kind reason=empty_or_large');
      return;
    }
    final entries = await _readEntries();
    final now = _clock();
    entries.removeWhere((_, value) {
      final expires = value['expiresAt'] as int? ?? 0;
      return expires <= now.millisecondsSinceEpoch;
    });
    entries[key] = {
      'createdAt': now.millisecondsSinceEpoch,
      'expiresAt': now.add(ttl).millisecondsSinceEpoch,
      'kind': kind,
      'model': model,
      'text': answer.text,
      if (answer.source != null) 'source': answer.source,
      'inputTokensEstimate': answer.inputTokensEstimate > 0
          ? answer.inputTokensEstimate
          : _estimateTokens(inputBytes),
      'outputTokensEstimate': answer.outputTokensEstimate > 0
          ? answer.outputTokensEstimate
          : _estimateTokens(utf8.encode(answer.text).length),
      if (answer.costUsdEstimate != null)
        'costUsdEstimate': answer.costUsdEstimate,
    };
    final ordered = entries.entries.toList()
      ..sort(
        (a, b) => (b.value['createdAt'] as int? ?? 0).compareTo(
          a.value['createdAt'] as int? ?? 0,
        ),
      );
    final trimmed = Map<String, Map<String, Object?>>.fromEntries(
      ordered.take(_maxEntries),
    );
    await _writeEntries(trimmed);
    log(
      '[AiCache] store kind=$kind model=$model '
      'input_tokens_est=${_estimateTokens(inputBytes)} '
      'output_tokens_est=${_estimateTokens(utf8.encode(answer.text).length)} '
      'ttl_minutes=${ttl.inMinutes}',
    );
  });

  static int _estimateTokens(int bytes) => (bytes / 4).ceil();

  Future<Map<String, Map<String, Object?>>> _readEntries() async {
    final file = await _cacheFile();
    try {
      if (!await file.exists()) return {};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is Map)
            entry.key as String: Map<String, Object?>.from(entry.value as Map),
      };
    } on FileSystemException {
      return {};
    } on FormatException {
      log('[AiCache] cache file unreadable; resetting local cache');
      return {};
    }
  }

  Future<void> _writeEntries(Map<String, Map<String, Object?>> entries) async {
    final file = await _cacheFile();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(entries), flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<File> _cacheFile() async => File(
    '${(await _supportDirectory()).path}/ai_response_cache/cache_v1.json',
  );

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }
}

class AiCachedAnswer {
  const AiCachedAnswer({
    required this.text,
    this.source,
    this.model,
    this.inputTokensEstimate = 0,
    this.outputTokensEstimate = 0,
    this.costUsdEstimate,
    this.cacheable = true,
  });

  final String text;
  final String? source;
  final String? model;
  final int inputTokensEstimate;
  final int outputTokensEstimate;
  final double? costUsdEstimate;
  final bool cacheable;
}
