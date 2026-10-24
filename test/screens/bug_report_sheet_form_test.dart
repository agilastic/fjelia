import 'package:fjelia/screens/settings/bug_report_sheet.dart';
import 'package:fjelia/services/bug_report_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Reports extends BugReportService {
  int calls = 0;
  @override
  Future<void> send({
    required String email,
    required String subject,
    required String body,
  }) async => calls++;
}

Future<void> show(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: BugReportSheet(service: _Reports())),
    ),
  );
}

FocusNode? focused() => FocusManager.instance.primaryFocus;

void main() {
  testWidgets('a tap outside the field hides the keyboard', (tester) async {
    await show(tester);
    await tester.tap(find.widgetWithText(TextFormField, 'Message'));
    await tester.pump();
    expect(focused()?.hasPrimaryFocus, isTrue);
    expect(find.byType(EditableText), findsWidgets);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.widgetWithText(TextFormField, 'Message'),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );

    // A tap on the plain text above the form takes the focus away.
    await tester.tap(find.textContaining('Share an idea'));
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.widgetWithText(TextFormField, 'Message'),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isFalse,
    );
  });

  testWidgets('dragging the form hides the keyboard', (tester) async {
    await show(tester);
    await tester.tap(find.widgetWithText(TextFormField, 'Your email'));
    await tester.pump();
    final field = find.descendant(
      of: find.widgetWithText(TextFormField, 'Your email'),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
    await tester.drag(find.byType(ListView), const Offset(0, -40));
    await tester.pump();
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isFalse);
  });

  testWidgets('character counters stay hidden until a field is nearly full', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('0/254'), findsNothing);
    expect(find.text('15/200'), findsNothing);
    expect(find.text('0/8000'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Message'),
      'x' * 6500,
    );
    await tester.pump();
    expect(find.text('6500/8000'), findsOneWidget);
  });

  testWidgets('the actions are laid out as one primary and two secondary', (
    tester,
  ) async {
    await show(tester);
    await tester.ensureVisible(find.text('Send report'));
    expect(find.widgetWithText(FilledButton, 'Send report'), findsOneWidget);
    expect(find.text('Copy report'), findsOneWidget);
    expect(find.text('Share report'), findsOneWidget);
    expect(find.text('Share report instead'), findsNothing);
  });
}
