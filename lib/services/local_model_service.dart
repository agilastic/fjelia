import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'local_model_catalog.dart';

export 'local_model_catalog.dart';

class LocalModelStatus {
  const LocalModelStatus({
    required this.supported,
    this.reason,
    this.installed = false,
    this.downloading = false,
    this.downloadedBytes = 0,
    required this.totalBytes,
    this.error,
  });

  final bool supported, installed, downloading;
  final String? reason, error;
  final int downloadedBytes, totalBytes;
  double get progress =>
      totalBytes == 0 ? 0 : (downloadedBytes / totalBytes).clamp(0.0, 1.0);

  LocalModelStatus copyWith({
    bool? installed,
    bool? downloading,
    int? downloadedBytes,
    String? error,
  }) => LocalModelStatus(
    supported: supported,
    reason: reason,
    installed: installed ?? this.installed,
    downloading: downloading ?? this.downloading,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    totalBytes: totalBytes,
    error: error,
  );
}

class LocalModelException implements Exception {
  const LocalModelException(this.code);
  final String code;
  @override
  String toString() => 'LocalModelException($code)';
}

/// Owns the optional weights. Only explicit Download actions make HTTP calls;
/// inference reads local files and passes messages straight to the MLX bridge.
class LocalModelService {
  LocalModelService({
    MethodChannel channel = const MethodChannel('fjelia/local_model'),
    Future<Directory> Function()? directory,
    http.Client Function()? clientFactory,
    this.model = localQwen2b,
    List<LocalModelFile>? files,
    String? modelId,
    String? revision,
  }) : // Keep the injected channel's public parameter name stable.
       // ignore: prefer_initializing_formals
       _channel = channel,
       files = files ?? model.files,
       modelId = modelId ?? model.id,
       revision = revision ?? model.revision,
       _directory = directory ?? (() => _defaultDirectory(model)),
       _clientFactory = clientFactory ?? http.Client.new;

  final LocalModelSpec model;
  final MethodChannel _channel;
  final Future<Directory> Function() _directory;
  final http.Client Function() _clientFactory;
  final List<LocalModelFile> files;
  final String modelId, revision;
  http.Client? _downloadClient;
  bool _cancelled = false;
  bool _downloading = false;

  int get totalBytes => files.fold(0, (n, f) => n + f.bytes);

  static Future<Directory> _defaultDirectory(
    LocalModelSpec model,
  ) async => Directory(
    '${(await getApplicationSupportDirectory()).path}/local_models/${model.directoryName}',
  );

  Future<LocalModelStatus> inspect() async {
    Map<String, dynamic>? availability;
    try {
      availability = await _channel
          .invokeMapMethod<String, dynamic>('availability', {
            'minimumMemoryBytes': model.minimumMemoryBytes,
            'requiresIPhone18': model.requiresIPhone18,
          });
    } on MissingPluginException {
      // Android, unsupported builds and Dart-only tests have no MLX bridge.
    } on PlatformException {
      // Availability is informational; an unsupported device remains usable.
    }
    final supported = availability?['supported'] == true;
    final reason = supported
        ? null
        : availability?['reason'] as String? ?? 'platform';
    if (availability == null) {
      return LocalModelStatus(
        supported: false,
        reason: reason,
        totalBytes: totalBytes,
      );
    }
    final directory = await _directory();
    final marker = File('${directory.path}/installed.json');
    var installed = false;
    try {
      final metadata = jsonDecode(await marker.readAsString());
      if (metadata is! Map) {
        throw const FormatException('Invalid installation marker');
      }
      installed =
          metadata['model'] == modelId && metadata['revision'] == revision;
      for (final entry in files) {
        final file = File('${directory.path}/${entry.name}');
        installed =
            installed &&
            await file.exists() &&
            await file.length() == entry.bytes;
        if (!installed) break;
      }
    } on FileSystemException {
      // Missing/incomplete installation, including a killed download.
      installed = false;
    } on FormatException {
      // A damaged marker must never activate partially downloaded weights.
      installed = false;
    }
    return LocalModelStatus(
      supported: supported,
      reason: reason,
      installed: installed,
      downloadedBytes: installed ? totalBytes : await _partialBytes(directory),
      totalBytes: totalBytes,
    );
  }

  Future<int> _partialBytes(Directory directory) async {
    var bytes = 0;
    for (final entry in files) {
      for (final suffix in ['', '.part']) {
        final file = File('${directory.path}/${entry.name}$suffix');
        if (await file.exists()) {
          bytes += (await file.length()).clamp(0, entry.bytes);
          break;
        }
      }
    }
    return bytes;
  }

  Future<void> download(void Function(int bytes, int total) progress) async {
    if (_downloading) throw const LocalModelException('busy');
    _downloading = true;
    _cancelled = false;
    http.Client? client;
    try {
      final status = await inspect();
      _checkCancelled();
      if (!status.supported) throw const LocalModelException('unsupported');
      client = _downloadClient = _clientFactory();
      final directory = await _directory();
      await directory.create(recursive: true);
      await _channel.invokeMethod<void>('excludeFromBackup', directory.path);
      final marker = File('${directory.path}/installed.json');
      if (await marker.exists()) await marker.delete();
      var completed = 0;
      for (final entry in files) {
        _checkCancelled();
        final file = File('${directory.path}/${entry.name}');
        if (await _validFile(file, entry)) {
          completed += entry.bytes;
          progress(completed, totalBytes);
          continue;
        }
        final partial = File('${file.path}.part');
        var offset = await partial.exists() ? await partial.length() : 0;
        if (offset > entry.bytes) offset = 0;
        if (offset == entry.bytes) {
          if (await _validFile(partial, entry)) {
            await partial.rename(file.path);
            completed += entry.bytes;
            progress(completed, totalBytes);
            continue;
          }
          offset = 0;
        }
        final request = http.Request(
          'GET',
          Uri.https(
            'huggingface.co',
            '/$modelId/resolve/$revision/${entry.name}',
          ),
        );
        if (offset > 0) request.headers['Range'] = 'bytes=$offset-';
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 45));
        if (response.statusCode == 200) {
          offset = 0; // The server ignored Range: restart rather than append.
        } else if (response.statusCode != 206 ||
            !response.headers['content-range'].toString().startsWith(
              'bytes $offset-',
            )) {
          throw const LocalModelException('download');
        }
        final sink = partial.openWrite(
          mode: offset == 0 ? FileMode.write : FileMode.append,
        );
        var received = offset;
        try {
          await for (final chunk in response.stream.timeout(
            const Duration(seconds: 60),
          )) {
            _checkCancelled();
            received += chunk.length;
            if (received > entry.bytes) {
              throw const LocalModelException('integrity');
            }
            sink.add(chunk);
            // Await writes regularly instead of buffering a multi-GB model in RAM.
            await sink.flush();
            progress(completed + received, totalBytes);
          }
        } finally {
          await sink.close();
        }
        _checkCancelled();
        if (!await _validFile(partial, entry)) {
          await partial.delete();
          throw const LocalModelException('integrity');
        }
        await partial.rename(file.path);
        completed += entry.bytes;
        progress(completed, totalBytes);
      }
      _checkCancelled();
      final pendingMarker = File('${marker.path}.part');
      await pendingMarker.writeAsString(
        jsonEncode({'model': modelId, 'revision': revision}),
        flush: true,
      );
      await pendingMarker.rename(marker.path);
    } catch (_) {
      _checkCancelled();
      rethrow;
    } finally {
      client?.close();
      _downloadClient = null;
      _downloading = false;
    }
  }

  Future<bool> _validFile(File file, LocalModelFile entry) async {
    if (!await file.exists() || await file.length() != entry.bytes) {
      return false;
    }
    if (entry.sha256Hex == null) return true;
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == entry.sha256Hex;
  }

  void _checkCancelled() {
    if (_cancelled) throw const LocalModelException('cancelled');
  }

  void cancelDownload() {
    _cancelled = true;
    _downloadClient?.close();
  }

  Future<void> remove() async {
    if (_downloading) throw const LocalModelException('busy');
    await unload();
    final directory = await _directory();
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<void> unload() async {
    try {
      await _channel.invokeMethod<void>('unload');
    } on MissingPluginException {
      // No runtime is loaded on unsupported platforms.
    }
  }

  Future<String> generate(
    List<Map<String, String>> messages, {
    int maxTokens = 512,
  }) async {
    final status = await inspect();
    if (!status.supported) {
      throw LocalModelException(
        status.reason == 'device' ? 'device' : 'unsupported',
      );
    }
    if (!status.installed) throw const LocalModelException('notInstalled');
    try {
      final reply = await _channel.invokeMethod<String>('generate', {
        'directory': (await _directory()).path,
        'messages': messages,
        'maxTokens': maxTokens,
        'minimumMemoryBytes': model.minimumMemoryBytes,
        'requiresIPhone18': model.requiresIPhone18,
      });
      if (reply == null || reply.trim().isEmpty) {
        throw const LocalModelException('empty');
      }
      return reply.trim();
    } on PlatformException catch (e) {
      throw LocalModelException(e.code);
    }
  }
}
