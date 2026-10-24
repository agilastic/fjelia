import 'package:fjelia/services/hilo_report_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Synthetic page text in the layout PDFKit returns for a two-column report:
  // header, repeated table header, left/right rows interleaved, footer.
  const page = '''
Monatsbericht
Max Mustermann
max@example.com
Oktober, 2026
Blutdruck- und Herzfrequenzmessungen
DATUM UHRZEIT SBP DBP HR
DATUM UHRZEIT SBP DBP HR
25 September, 26 20:08 126 73 61
1 Oktober, 26 19:55 130 73 49
1 Oktober, 26 00:15 116 57 52
1 Oktober, 26 20:03 125 67 50
Kalibrierung mit Manschette Manschettenmessung Telefonmessung
Dieser Bericht wurde dir von Aktiia SA bereitgestellt
''';

  test('reads readings, ignores header and sorts across columns', () {
    final report = HiloReportParser.parse([page]);
    expect(report.readings, hasLength(4));
    expect(report.first, DateTime(2026, 9, 25, 20, 8));
    expect(report.last, DateTime(2026, 10, 1, 20, 3));
    expect(report.readings[1].at, DateTime(2026, 10, 1, 0, 15));
    expect(report.readings[1].systolic, 116);
    expect(report.readings[1].diastolic, 57);
    expect(report.readings[1].heartRate, 52);
    expect(report.rejected, 0);
  });

  test('accepts other languages and four digit years', () {
    final report = HiloReportParser.parse([
      'SBP DBP HR\n3 October 2026 08:05 120 80 60\n4 octobre, 26 09:00 121 81 61\n'
          '5 Okt. 26 10:00 122 82 62',
    ]);
    expect(report.readings.map((r) => r.at.day), [3, 4, 5]);
  });

  test('drops duplicate rows and implausible values', () {
    final report = HiloReportParser.parse([
      'SBP DBP HR\n1 Oktober, 26 10:00 120 80 60\n1 Oktober, 26 10:00 120 80 60\n'
          '1 Oktober, 26 11:00 80 120 60\n31 September, 26 12:00 120 80 60',
    ]);
    expect(report.readings, hasLength(1));
    expect(report.rejected, 2);
  });

  test('rejects documents that are not a report', () {
    expect(
      () =>
          HiloReportParser.parse(['Rechnung 2026\n1 Oktober, 26 10:00 1 2 3']),
      throwsA(isA<HiloReportFormatException>()),
    );
  });

  test('rejects an unknown month name instead of guessing', () {
    expect(
      () => HiloReportParser.parse(['SBP DBP HR\n1 Foo, 26 10:00 120 80 60']),
      throwsA(
        isA<HiloReportFormatException>().having(
          (e) => e.message,
          'message',
          contains('Foo'),
        ),
      ),
    );
  });

  test('a report without readings is an error', () {
    expect(
      () => HiloReportParser.parse(['SBP DBP HR\nnothing here']),
      throwsA(isA<HiloReportFormatException>()),
    );
  });
}
