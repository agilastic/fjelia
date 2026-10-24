/// One blood-pressure reading of a Hilo monthly report.
class HiloReportReading {
  const HiloReportReading({
    required this.at,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
  });

  /// Local time as printed in the report (the report carries no time zone).
  final DateTime at;
  final int systolic;
  final int diastolic;
  final int heartRate;
}

class HiloReport {
  const HiloReport({required this.readings, this.rejected = 0});

  /// Readings sorted by time, without duplicates.
  final List<HiloReportReading> readings;

  /// Rows that looked like readings but had implausible values.
  final int rejected;

  DateTime get first => readings.first.at;
  DateTime get last => readings.last.at;
}

/// Thrown when a document is not a recognised Hilo report.
class HiloReportFormatException implements Exception {
  HiloReportFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads the measurement table of a Hilo "monthly report" PDF from its page
/// texts. The report prints the table in two columns per page, so the text
/// arrives with left and right rows interleaved; rows are therefore matched
/// one by one and sorted by time instead of relying on their order.
class HiloReportParser {
  const HiloReportParser._();

  // `1 Oktober, 26 19:55 130 73 49`
  static final _row = RegExp(
    r'^(\d{1,2})\.?\s+([\p{L}\.]+),?\s+(\d{2}|\d{4})\s+(\d{1,2}):(\d{2})\s+'
    r'(\d{2,3})\s+(\d{2,3})\s+(\d{2,3})$',
    unicode: true,
  );

  static const _months = <String, int>{
    // de
    'januar': 1, 'jan': 1, 'jän': 1, 'februar': 2, 'feb': 2, 'märz': 3,
    'maerz': 3, 'mär': 3, 'mrz': 3, 'april': 4, 'apr': 4, 'mai': 5,
    'juni': 6, 'jun': 6, 'juli': 7, 'jul': 7, 'august': 8, 'aug': 8,
    'september': 9, 'sep': 9, 'sept': 9, 'oktober': 10, 'okt': 10,
    'november': 11, 'nov': 11, 'dezember': 12, 'dez': 12,
    // en
    'january': 1, 'february': 2, 'march': 3, 'mar': 3, 'may': 5, 'june': 6,
    'july': 7, 'october': 10, 'oct': 10, 'december': 12, 'dec': 12,
    // fr
    'janvier': 1, 'janv': 1, 'février': 2, 'fevrier': 2, 'févr': 2,
    'fév': 2, 'mars': 3, 'avril': 4, 'avr': 4, 'juin': 6, 'juillet': 7,
    'juil': 7, 'août': 8, 'aout': 8, 'septembre': 9, 'octobre': 10,
    'novembre': 11, 'décembre': 12, 'decembre': 12, 'déc': 12,
    // es
    'enero': 1, 'ene': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'abr': 4,
    'mayo': 5, 'junio': 6, 'julio': 7, 'agosto': 8, 'ago': 8,
    'septiembre': 9, 'setiembre': 9, 'octubre': 10, 'noviembre': 11,
    'diciembre': 12, 'dic': 12,
    // it
    'gennaio': 1, 'gen': 1, 'febbraio': 2, 'aprile': 4, 'maggio': 5,
    'mag': 5, 'giugno': 6, 'giu': 6, 'luglio': 7, 'lug': 7, 'settembre': 9,
    'set': 9, 'ottobre': 10, 'ott': 10, 'dicembre': 12,
  };

  static int? _month(String word) =>
      _months[word.toLowerCase().replaceAll('.', '')];

  /// Parses the report. Throws [HiloReportFormatException] when the document
  /// is not a Hilo report, uses an unknown month name or has no readings.
  static HiloReport parse(List<String> pages) {
    final text = pages.join('\n');
    if (!text.contains('SBP') || !text.contains('DBP')) {
      throw HiloReportFormatException(
        'This PDF is not a Hilo blood-pressure report.',
      );
    }
    final seen = <String>{};
    final readings = <HiloReportReading>[];
    var rejected = 0;
    for (final raw in text.split(RegExp(r'[\r\n]+'))) {
      final m = _row.firstMatch(raw.trim());
      if (m == null) continue;
      final month = _month(m[2]!);
      if (month == null) {
        throw HiloReportFormatException(
          'Unknown month name "${m[2]}": this report language is not '
          'supported yet.',
        );
      }
      var year = int.parse(m[3]!);
      if (year < 100) year += 2000;
      final day = int.parse(m[1]!);
      final hour = int.parse(m[4]!);
      final minute = int.parse(m[5]!);
      final sys = int.parse(m[6]!);
      final dia = int.parse(m[7]!);
      final hr = int.parse(m[8]!);
      final at = DateTime(year, month, day, hour, minute);
      final plausible =
          day >= 1 &&
          day <= 31 &&
          at.month == month &&
          hour < 24 &&
          minute < 60 &&
          sys >= 60 &&
          sys <= 260 &&
          dia >= 30 &&
          dia <= 160 &&
          sys > dia &&
          hr >= 25 &&
          hr <= 220;
      if (!plausible) {
        rejected++;
        continue;
      }
      if (!seen.add('${at.millisecondsSinceEpoch}/$sys/$dia/$hr')) continue;
      readings.add(
        HiloReportReading(at: at, systolic: sys, diastolic: dia, heartRate: hr),
      );
    }
    if (readings.isEmpty) {
      throw HiloReportFormatException(
        'No blood-pressure readings found in this report.',
      );
    }
    readings.sort((a, b) => a.at.compareTo(b.at));
    return HiloReport(readings: readings, rejected: rejected);
  }
}
