import 'package:fjelia/providers/sync_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const settle = Duration(milliseconds: 60);
  const poll = Duration(milliseconds: 10);

  test('returns only after the sync is over and stays over', () async {
    var busy = true;
    Future<void>.delayed(const Duration(milliseconds: 80), () => busy = false);
    final started = DateTime.now();
    await waitUntilIdle(() => busy, settle: settle, poll: poll);
    expect(
      DateTime.now().difference(started).inMilliseconds,
      greaterThanOrEqualTo(80 + 60),
    );
  });

  test('a sync that starts during the verification wait is caught', () async {
    var busy = false;
    // Idle at first, then busy 30 ms in, then idle again.
    Future<void>.delayed(const Duration(milliseconds: 30), () => busy = true);
    Future<void>.delayed(const Duration(milliseconds: 120), () => busy = false);
    final started = DateTime.now();
    await waitUntilIdle(() => busy, settle: settle, poll: poll);
    expect(
      DateTime.now().difference(started).inMilliseconds,
      greaterThanOrEqualTo(120 + 60),
    );
  });

  test('gives up after the timeout and stops when no longer wanted', () async {
    final started = DateTime.now();
    await waitUntilIdle(
      () => true,
      settle: settle,
      poll: poll,
      timeout: const Duration(milliseconds: 100),
    );
    expect(DateTime.now().difference(started).inMilliseconds, lessThan(400));
    await waitUntilIdle(() => true, stillWanted: () => false, poll: poll);
  });
}
