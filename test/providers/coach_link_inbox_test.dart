import 'package:fjelia/providers/coach_link_inbox.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('fjelia/links');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('takes what waits, then what arrives later', () async {
    var waiting = <String>['fjelia://link?v=1&c=a'];
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'takePending');
      final out = waiting;
      waiting = [];
      return out;
    });
    final got = <List<String>>[];
    CoachLinkInbox().listen(got.add);
    await pumpEventQueue();
    expect(got, [
      ['fjelia://link?v=1&c=a'],
    ]);
    // The native side opens another one while the app runs.
    waiting = ['fjelia://link?v=1&c=b'];
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('opened')),
      (_) {},
    );
    await pumpEventQueue();
    expect(got.last, ['fjelia://link?v=1&c=b']);
  });

  test('without the native side there is nothing to take', () async {
    expect(await CoachLinkInbox().take(), isEmpty);
  });
}
