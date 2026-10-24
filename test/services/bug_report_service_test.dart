import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fjelia/services/bug_report_service.dart';

void main() {
  test('posts UTF-8 form fields to the website endpoint', () async {
    final service = BugReportService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://cloud.ebeling-hoppe.de/fjelia/report/',
        );
        expect(request.followRedirects, isFalse);
        expect(request.bodyFields, {
          'fromemail': 'tester@example.com',
          'subject': 'Sync & sleep',
          'body': 'Missing workout: Grüße\nSecond line',
        });
        return http.Response('Received', 200);
      }),
    );
    await service.send(
      email: ' tester@example.com ',
      subject: ' Sync & sleep ',
      body: 'Missing workout: Grüße\nSecond line',
    );
  });
  test(
    'accepts a same-server confirmation redirect without resending',
    () async {
      var calls = 0;
      final service = BugReportService(
        client: MockClient((request) async {
          calls++;
          return http.Response(
            '',
            303,
            headers: {'location': '/fjelia/report/sent'},
          );
        }),
      );
      await service.send(
        email: 'a@example.com',
        subject: 'Bug',
        body: 'A report message',
      );
      expect(calls, 1);
    },
  );
  for (final status in [422, 429, 500]) {
    test('HTTP $status is a failed submission', () async {
      final service = BugReportService(
        client: MockClient((_) async => http.Response('error', status)),
      );
      await expectLater(
        service.send(
          email: 'a@example.com',
          subject: 'Bug',
          body: 'A report message',
        ),
        throwsA(isA<BugReportException>()),
      );
    });
  }
  test('does not treat an unrelated redirect as success', () async {
    final service = BugReportService(
      client: MockClient(
        (_) async => http.Response(
          '',
          303,
          headers: {'location': 'https://example.com/login'},
        ),
      ),
    );
    await expectLater(
      service.send(
        email: 'a@example.com',
        subject: 'Bug',
        body: 'A report message',
      ),
      throwsA(isA<BugReportException>()),
    );
  });
  test('timeout explains that delivery is uncertain', () async {
    final service = BugReportService(
      client: MockClient((_) => throw TimeoutException('timeout')),
    );
    await expectLater(
      service.send(
        email: 'a@example.com',
        subject: 'Bug',
        body: 'A report message',
      ),
      throwsA(
        isA<BugReportException>().having(
          (e) => e.message,
          'message',
          contains('may have arrived'),
        ),
      ),
    );
  });
}
