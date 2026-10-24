import 'dart:async';
import 'package:http/http.dart' as http;

class BugReportException implements Exception {
  const BugReportException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BugReportService {
  BugReportService({this.client});
  final http.Client? client;
  static final endpoint = Uri.parse(
    'https://cloud.ebeling-hoppe.de/fjelia/report/',
  );

  Future<void> send({
    required String email,
    required String subject,
    required String body,
  }) async {
    final transport = client ?? http.Client();
    try {
      final request = http.Request('POST', endpoint)
        ..followRedirects = false
        ..bodyFields = {
          'fromemail': email.trim(),
          'subject': subject.trim(),
          'body': body,
        };
      final response = await transport
          .send(request)
          .timeout(const Duration(seconds: 30));
      await response.stream.drain<void>().timeout(const Duration(seconds: 10));
      final status = response.statusCode;
      // The website endpoint may return a confirmation page or redirect to one.
      final location = response.headers['location'];
      final redirect = location == null ? null : endpoint.resolve(location);
      if ((status >= 200 && status < 300) ||
          (status == 303 &&
              redirect != null &&
              redirect.origin == endpoint.origin &&
              redirect.path.startsWith(endpoint.path))) {
        return;
      }
      throw BugReportException(switch (status) {
        429 =>
          'Too many reports. Please wait a few minutes before trying again.',
        413 => 'The report is too long. Try sending it without diagnostics.',
        400 || 422 =>
          'The server could not accept the report. Check your email and message.',
        _ =>
          'The report could not be sent (HTTP $status). Your text is still here.',
      });
    } on TimeoutException {
      throw const BugReportException(
        'The server did not confirm in time. The report may have arrived. Your text is still here.',
      );
    } on http.ClientException {
      throw const BugReportException(
        'Could not reach the report server. Check your connection and try again.',
      );
    } finally {
      if (client == null) transport.close();
    }
  }
}
