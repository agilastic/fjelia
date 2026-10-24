import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/screens/settings/bug_report_sheet.dart';
import 'package:fjelia/services/bug_report_service.dart';
import 'package:fjelia/services/debug_log.dart';

class _Reports extends BugReportService {
  String? body;
  bool fail = false;
  int calls = 0;
  @override
  Future<void> send({
    required String email,
    required String subject,
    required String body,
  }) async {
    calls++;
    this.body = body;
    if (fail) throw const BugReportException('Could not reach the server.');
  }
}

Future<void> fill(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Your email'),
    'tester@example.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'What happened?'),
    'My latest workout is missing.',
  );
  await tester.ensureVisible(find.text('Send report'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    DebugLog.clear();
    DebugLog.add('Private diagnostic detail');
  });
  tearDown(DebugLog.clear);
  testWidgets('validates fields and sends without diagnostics by default', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reports = _Reports();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BugReportSheet(service: reports)),
      ),
    );
    await tester.ensureVisible(find.text('Send report'));
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(reports.calls, 0);
    await fill(tester);
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(reports.body, 'My latest workout is missing.');
    expect(find.text('Report sent. Thank you!'), findsOneWidget);
    expect(find.text('Send report'), findsNothing);
  });
  testWidgets(
    'failed send preserves text and allows retry; diagnostics are opt-in',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reports = _Reports()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BugReportSheet(service: reports)),
        ),
      );
      await fill(tester);
      await tester.ensureVisible(find.text('Include diagnostics'));
      await tester.tap(find.text('Include diagnostics'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(reports.body, contains('Private diagnostic detail'));
      expect(find.text('Could not reach the server.'), findsOneWidget);
      expect(find.text('My latest workout is missing.'), findsOneWidget);
      reports.fail = false;
      await tester.ensureVisible(find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(reports.calls, 2);
      expect(find.text('Report sent. Thank you!'), findsOneWidget);
    },
  );
}
