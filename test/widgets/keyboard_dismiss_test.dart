import 'package:fjelia/widgets/keyboard_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final first = FocusNode(), second = FocusNode();

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => DismissKeyboardOnTapOutside(child: child!),
      home: Scaffold(
        body: ListView(
          children: [
            TextField(key: const Key('first'), focusNode: first),
            TextField(key: const Key('second'), focusNode: second),
            TextFieldTapRegion(
              child: TextButton(
                key: const Key('send'),
                onPressed: () {},
                child: const Text('Send'),
              ),
            ),
            const SizedBox(height: 400),
          ],
        ),
      ),
    ),
  );

  testWidgets('a tap on the background closes the keyboard', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('first')));
    await tester.pump();
    expect(first.hasFocus, isTrue);
    // Empty space below the fields.
    await tester.tapAt(const Offset(400, 500));
    await tester.pump();
    expect(first.hasFocus, isFalse);
  });

  testWidgets('starting to scroll closes the keyboard', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('first')));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump();
    expect(first.hasFocus, isFalse);
  });

  testWidgets('another field or a send button keeps it open', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('first')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('second')));
    await tester.pump();
    expect(second.hasFocus, isTrue);
    await tester.tap(find.byKey(const Key('send')));
    await tester.pump();
    expect(second.hasFocus, isTrue);
  });
}
