import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fjelia/services/local_model_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('fjelia/local_model_test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory directory;
  late List<String> nativeCalls;
  final bytes = utf8.encode('model weights');
  late LocalModelFile entry;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'fjelia-local-model-test-',
    );
    nativeCalls = [];
    entry = LocalModelFile(
      'model.safetensors',
      bytes.length,
      sha256.convert(bytes).toString(),
    );
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call.method);
      if (call.method == 'availability') return {'supported': true};
      if (call.method == 'generate') return 'A local reply';
      return null;
    });
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  LocalModelService service(http.Client client) => LocalModelService(
    channel: channel,
    directory: () async => directory,
    clientFactory: () => client,
    files: [entry],
  );

  test(
    'an explicit pinned download validates before becoming available',
    () async {
      var requests = 0;
      final model = service(
        MockClient((request) async {
          requests++;
          expect(request.url.host, 'huggingface.co');
          expect(request.url.path, contains('/resolve/$localQwenRevision/'));
          expect(request.body, isEmpty);
          return http.Response.bytes(bytes, 200);
        }),
      );
      expect((await model.inspect()).installed, isFalse);
      expect(requests, 0);
      final progress = <int>[];
      await model.download((n, _) => progress.add(n));
      expect(progress.last, bytes.length);
      expect((await model.inspect()).installed, isTrue);
      expect(nativeCalls, contains('excludeFromBackup'));
      expect(
        await model.generate([
          {'role': 'user', 'content': 'private data'},
        ]),
        'A local reply',
      );
      expect(requests, 1, reason: 'inference must not make HTTP requests');
    },
  );

  test('an unsupported device never downloads or runs a model', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'supported': false, 'reason': 'gpu'},
    );
    final model = service(
      MockClient((_) async => fail('No HTTP request is allowed')),
    );
    expect((await model.inspect()).supported, isFalse);
    await expectLater(
      model.download((_, _) {}),
      throwsA(isA<LocalModelException>()),
    );
    await expectLater(model.generate([]), throwsA(isA<LocalModelException>()));
    expect(await File('${directory.path}/installed.json').exists(), isFalse);
  });

  test(
    '4B uses its own pinned files, installation and native memory budget',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'availability') return {'supported': true};
        if (call.method == 'generate') return 'A 4B reply';
        return null;
      });
      LocalModelService create(LocalModelSpec spec) => LocalModelService(
        model: spec,
        channel: channel,
        files: [entry],
        directory: () async =>
            Directory('${directory.path}/${spec.directoryName}'),
        clientFactory: () => MockClient((request) async {
          expect(
            request.url.path,
            contains('/${spec.id}/resolve/${spec.revision}/'),
          );
          return http.Response.bytes(bytes, 200);
        }),
      );
      final small = create(localQwen2b);
      final large = create(localQwen4b);
      await small.download((_, _) {});
      expect((await large.inspect()).installed, isFalse);
      await large.download((_, _) {});
      expect((await large.inspect()).installed, isTrue);
      expect(
        await large.generate([
          {'role': 'user', 'content': 'Training?'},
        ]),
        'A 4B reply',
      );
      final generation =
          calls.lastWhere((call) => call.method == 'generate').arguments as Map;
      expect(generation['directory'], endsWith(localQwen4b.directoryName));
      expect(generation['minimumMemoryBytes'], 7500000000);
      expect(generation['requiresIPhone18'], isTrue);
      final availability =
          calls.lastWhere((call) => call.method == 'availability').arguments
              as Map;
      expect(availability['minimumMemoryBytes'], 7500000000);
      expect(availability['requiresIPhone18'], isTrue);
      final marker = File(
        '${directory.path}/${localQwen4b.directoryName}/installed.json',
      );
      await marker.writeAsString(
        jsonEncode({'model': localQwenModelId, 'revision': localQwenRevision}),
      );
      expect(
        (await large.inspect()).installed,
        isFalse,
        reason: 'A 2B marker cannot activate 4B',
      );
      await large.remove();
      expect((await small.inspect()).installed, isTrue);
    },
  );

  test(
    'older iPhones cannot download or run 4B but can delete cached weights',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        nativeCalls.add(call.method);
        if (call.method == 'availability') {
          expect((call.arguments as Map)['requiresIPhone18'], isTrue);
          return {'supported': false, 'reason': 'device'};
        }
        if (call.method == 'generate') fail('4B inference must be blocked');
        return null;
      });
      final model = LocalModelService(
        model: localQwen4b,
        channel: channel,
        directory: () async => directory,
        files: [entry],
        clientFactory: () =>
            MockClient((_) async => fail('4B download must be blocked')),
      );
      await File('${directory.path}/${entry.name}').writeAsBytes(bytes);
      await File('${directory.path}/installed.json').writeAsString(
        jsonEncode({
          'model': localQwen4bModelId,
          'revision': localQwen4bRevision,
        }),
      );
      final status = await model.inspect();
      expect(status.supported, isFalse);
      expect(status.reason, 'device');
      expect(
        status.installed,
        isTrue,
        reason: 'Existing files must remain removable',
      );
      await expectLater(
        model.download((_, _) {}),
        throwsA(isA<LocalModelException>()),
      );
      await expectLater(
        model.generate([
          {'role': 'user', 'content': 'Training?'},
        ]),
        throwsA(
          isA<LocalModelException>().having((e) => e.code, 'code', 'device'),
        ),
      );
      await model.remove();
      expect(await directory.exists(), isFalse);
      expect(nativeCalls, contains('unload'));
    },
  );

  test(
    'resumes partial bytes with Range and validates the whole result',
    () async {
      await File(
        '${directory.path}/${entry.name}.part',
      ).writeAsBytes(bytes.take(4).toList());
      final model = service(
        MockClient((request) async {
          expect(request.headers['Range'], 'bytes=4-');
          return http.Response.bytes(
            bytes.sublist(4),
            206,
            headers: {
              'content-range': 'bytes 4-${bytes.length - 1}/${bytes.length}',
            },
          );
        }),
      );
      await model.download((_, _) {});
      expect(
        await File('${directory.path}/${entry.name}').readAsBytes(),
        bytes,
      );
      expect((await model.inspect()).installed, isTrue);
    },
  );

  test(
    'a server ignoring Range replaces the partial file rather than appending',
    () async {
      await File(
        '${directory.path}/${entry.name}.part',
      ).writeAsBytes(bytes.take(4).toList());
      final model = service(
        MockClient((_) async => http.Response.bytes(bytes, 200)),
      );
      await model.download((_, _) {});
      expect(
        await File('${directory.path}/${entry.name}').readAsBytes(),
        bytes,
      );
    },
  );

  test('invalid resumed offsets cannot activate a model', () async {
    await File(
      '${directory.path}/${entry.name}.part',
    ).writeAsBytes(bytes.take(4).toList());
    final model = service(
      MockClient(
        (_) async => http.Response.bytes(
          bytes.sublist(4),
          206,
          headers: {
            'content-range': 'bytes 5-${bytes.length - 1}/${bytes.length}',
          },
        ),
      ),
    );
    await expectLater(
      model.download((_, _) {}),
      throwsA(isA<LocalModelException>()),
    );
    expect((await model.inspect()).installed, isFalse);
  });

  test(
    'same-length corruption fails the checksum and leaves no installation',
    () async {
      final model = service(
        MockClient(
          (_) async => http.Response.bytes(List.filled(bytes.length, 42), 200),
        ),
      );
      await expectLater(
        model.download((_, _) {}),
        throwsA(isA<LocalModelException>()),
      );
      expect((await model.inspect()).installed, isFalse);
      expect(await File('${directory.path}/installed.json').exists(), isFalse);
      expect(
        await File('${directory.path}/${entry.name}.part').exists(),
        isFalse,
      );
    },
  );

  test(
    'cancelled downloads remain resumable and cannot be used for inference',
    () async {
      final model = service(
        MockClient((_) async => http.Response.bytes(bytes, 200)),
      );
      await expectLater(
        model.download((_, _) => model.cancelDownload()),
        throwsA(
          isA<LocalModelException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      expect(
        await File('${directory.path}/${entry.name}.part').exists(),
        isTrue,
      );
      expect((await model.inspect()).installed, isFalse);
    },
  );

  test('preflight is cancellable and excludes a second download', () async {
    final started = Completer<void>();
    final availability = Completer<Map<String, dynamic>>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'availability') {
        if (!started.isCompleted) started.complete();
        return availability.future;
      }
      return null;
    });
    final model = service(
      MockClient((_) async => fail('Cancelled preflight must not use HTTP')),
    );
    final pending = expectLater(
      model.download((_, _) {}),
      throwsA(
        isA<LocalModelException>().having((e) => e.code, 'code', 'cancelled'),
      ),
    );
    await started.future;
    await expectLater(
      model.download((_, _) {}),
      throwsA(isA<LocalModelException>().having((e) => e.code, 'code', 'busy')),
    );
    model.cancelDownload();
    availability.complete({'supported': true});
    await pending;
    expect(await directory.exists(), isTrue);
    expect(await File('${directory.path}/installed.json').exists(), isFalse);
  });

  test('damaged markers and missing weights are not installed', () async {
    final model = service(
      MockClient((_) async => http.Response.bytes(bytes, 200)),
    );
    await File('${directory.path}/installed.json').writeAsString('[]');
    expect((await model.inspect()).installed, isFalse);
    await model.download((_, _) {});
    await File('${directory.path}/${entry.name}').delete();
    expect((await model.inspect()).installed, isFalse);
  });

  test(
    'deleting a model unloads native inference and removes its files',
    () async {
      final model = service(
        MockClient((_) async => http.Response.bytes(bytes, 200)),
      );
      await model.download((_, _) {});
      await model.remove();
      expect(nativeCalls, contains('unload'));
      expect(await directory.exists(), isFalse);
      expect((await model.inspect()).installed, isFalse);
    },
  );
}
