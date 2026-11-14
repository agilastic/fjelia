import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/services/ai_response_cache.dart';

void main() {
  late Directory dir;
  late DateTime now;
  late AiResponseCache cache;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fjelia_ai_cache');
    now = DateTime(2026, 11, 14, 8);
    cache = AiResponseCache(
      supportDirectory: () async => dir,
      clock: () => now,
    );
  });
  tearDown(() => dir.delete(recursive: true));

  String key({String model = 'default', Object request = const {'q': 'hi'}}) =>
      AiResponseCache.keyFor(
        installationId: 'install',
        provider: 'freeAi',
        model: model,
        kind: 'chat',
        request: request,
      );

  Future<void> store(String key, String text) => cache.write(
    key,
    AiCachedAnswer(text: text, source: 'Cloud · FreeAI', model: 'default'),
    kind: 'chat',
    model: 'default',
    inputBytes: 400,
  );

  File cacheFile() => File('${dir.path}/ai_response_cache/cache_v1.json');

  test('every input that can change the answer changes the key', () {
    final base = key();
    expect(key(), base);
    expect(key(model: 'ProAI'), isNot(base));
    expect(key(request: const {'q': 'hi!'}), isNot(base));
    expect(
      AiResponseCache.keyFor(
        installationId: 'other',
        provider: 'freeAi',
        model: 'default',
        kind: 'chat',
        request: const {'q': 'hi'},
      ),
      isNot(base),
    );
    expect(base, matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('an answer comes back for five hours, then expires', () async {
    await store(key(), 'Easy 40 minutes today.');
    final hit = await cache.read(key());
    expect(hit!.text, 'Easy 40 minutes today.');
    expect(hit.source, 'Cloud · FreeAI');
    expect(hit.inputTokensEstimate, 100);
    expect(await cache.read(key(model: 'ProAI')), isNull);

    now = now.add(const Duration(hours: 4, minutes: 59));
    expect(await cache.read(key()), isNotNull);
    now = now.add(const Duration(minutes: 1));
    expect(await cache.read(key()), isNull);
    // The expired entry is gone from disk as well.
    expect(jsonDecode(await cacheFile().readAsString()), isEmpty);
  });

  test('the request itself is never written to disk', () async {
    await store(key(request: const {'q': 'my resting HR is 48'}), 'Noted.');
    final raw = await cacheFile().readAsString();
    expect(raw, isNot(contains('resting HR')));
    expect(raw, contains('Noted.'));
  });

  test('empty answers are not stored', () async {
    await store(key(), '   ');
    expect(await cache.read(key()), isNull);
  });

  test('keeps the 80 newest answers', () async {
    for (var i = 0; i < 85; i++) {
      now = now.add(const Duration(seconds: 1));
      await store(key(request: {'q': i}), 'answer $i');
    }
    expect(await cache.read(key(request: const {'q': 0})), isNull);
    expect(await cache.read(key(request: const {'q': 4})), isNull);
    expect((await cache.read(key(request: const {'q': 5})))!.text, 'answer 5');
    expect(
      (await cache.read(key(request: const {'q': 84})))!.text,
      'answer 84',
    );
  });

  test('a damaged cache file starts empty instead of failing', () async {
    await cacheFile().parent.create(recursive: true);
    await cacheFile().writeAsString('{not json');
    expect(await cache.read(key()), isNull);
    await store(key(), 'fresh');
    expect((await cache.read(key()))!.text, 'fresh');
  });

  test('parallel writes do not lose answers', () async {
    await Future.wait([
      for (var i = 0; i < 10; i++) store(key(request: {'q': i}), 'answer $i'),
    ]);
    for (var i = 0; i < 10; i++) {
      expect((await cache.read(key(request: {'q': i})))!.text, 'answer $i');
    }
  });
}
