/// Reads the text answers of COROS's official MCP tools. COROS writes them
/// for people ("Sleep Score: 91", "Deep: 1h 54min"); every value is optional
/// and a line Fjelia does not know is skipped. Dates are wake-up days.
library;

/// One night, dated by the morning it ended.
class CorosNight {
  CorosNight(this.date);
  final DateTime date;
  int? score, asleepMin, periodMin, deepMin, lightMin, remMin, awakeMin;
  int? avgHr, minHr, maxHr;
  DateTime? start, end;

  bool get hasSleep => (asleepMin ?? 0) > 0;
}

/// One day's other health values.
class CorosDay {
  CorosDay(this.date);
  final DateTime date;
  int? stress, steps, restingHr;
  double? hrv;
}

/// "6h 27min", "10 min", "3h 0min", "45min" → minutes.
int? corosMinutes(String? text) {
  if (text == null) return null;
  final m = RegExp(r'(?:(\d+)\s*h)?\s*(?:(\d+)\s*min)?')
      .firstMatch(text.trim());
  if (m == null || (m[1] == null && m[2] == null)) return null;
  return int.parse(m[1] ?? '0') * 60 + int.parse(m[2] ?? '0');
}

DateTime? _date(String s) {
  final iso = RegExp(r'(\d{4})-?(\d{2})-?(\d{2})').firstMatch(s);
  if (iso == null) return null;
  return DateTime(int.parse(iso[1]!), int.parse(iso[2]!), int.parse(iso[3]!));
}

/// Splits [text] into blocks that start with a date line: `2026-11-04`,
/// `2026-11-04:` or `--- 20261104 ---`.
Map<DateTime, List<String>> _blocks(String text) {
  final out = <DateTime, List<String>>{};
  List<String>? current;
  final head = RegExp(r'^\s*(?:-+\s*)?(\d{4}-?\d{2}-?\d{2})\s*(?:-+|:)?\s*$');
  for (final line in text.split('\n')) {
    final m = head.firstMatch(line);
    if (m != null) {
      current = out.putIfAbsent(_date(m[1]!)!, () => <String>[]);
    } else {
      current?.add(line.trim());
    }
  }
  return out;
}

String? _field(List<String> lines, String label) {
  for (final l in lines) {
    if (l.startsWith('$label:')) return l.substring(label.length + 1).trim();
  }
  return null;
}

int? _int(String? s) {
  if (s == null) return null;
  final m = RegExp(r'-?\d[\d,]*').firstMatch(s);
  return m == null ? null : int.tryParse(m[0]!.replaceAll(',', ''));
}

/// `querySleepOverview`: score, main sleep, period and window per night.
Map<DateTime, CorosNight> parseCorosSleepOverview(String text) {
  final out = <DateTime, CorosNight>{};
  for (final MapEntry(key: day, value: lines) in _blocks(text).entries) {
    final night = CorosNight(day);
    night.score = _int(_field(lines, 'Sleep Score'));
    night.asleepMin = corosMinutes(_field(lines, 'Main Sleep (asleep)'));
    night.periodMin = corosMinutes(
      _field(lines, 'Main Sleep Period (incl. awake)'),
    );
    night.awakeMin = corosMinutes(_field(lines, 'Awake Time'));
    final window = _field(lines, 'Main Sleep Window');
    final times = RegExp(r'(\d{4}-\d{2}-\d{2}) (\d{2}):(\d{2})')
        .allMatches(window ?? '')
        .toList();
    if (times.length == 2) {
      DateTime at(RegExpMatch m) => _date(m[1]!)!
          .add(Duration(hours: int.parse(m[2]!), minutes: int.parse(m[3]!)));
      night.start = at(times[0]);
      night.end = at(times[1]);
    }
    // A night COROS has no detail for yet ("Sleep Score: 0") is left out.
    if (night.hasSleep) out[day] = night;
  }
  return out;
}

/// `queryDailyHealthData`: stages in minutes, sleep heart rate, steps and
/// stress per day. Adds the stages to [nights] (creating nights COROS's
/// overview did not list).
Map<DateTime, CorosDay> parseCorosDailyHealth(
  String text, {
  Map<DateTime, CorosNight>? nights,
}) {
  final out = <DateTime, CorosDay>{};
  for (final MapEntry(key: day, value: lines) in _blocks(text).entries) {
    final d = CorosDay(day);
    for (final l in lines) {
      if (l.startsWith('Steps:')) d.steps = _int(l.substring(6));
      if (l.startsWith('Stress:')) d.stress = _int(l.substring(7));
      if (l.startsWith('Total:') && nights != null) {
        final n = nights.putIfAbsent(day, () => CorosNight(day));
        String? part(String name) => RegExp('$name: ([^|]+)').firstMatch(l)?[1];
        n.periodMin ??= corosMinutes(part('Total'));
        n.deepMin = corosMinutes(part('Deep'));
        n.lightMin = corosMinutes(part('Light'));
        n.remMin = corosMinutes(part('REM'));
        n.awakeMin ??= corosMinutes(part('Awake'));
        if (n.asleepMin == null && n.periodMin != null) {
          n.asleepMin = n.periodMin! - (n.awakeMin ?? 0);
        }
      }
      if (l.startsWith('Sleep HR:') && nights != null) {
        final n = nights.putIfAbsent(day, () => CorosNight(day));
        n.avgHr = _int(RegExp(r'Avg (\d+)').firstMatch(l)?[1]);
        n.minHr = _int(RegExp(r'Min (\d+)').firstMatch(l)?[1]);
        n.maxHr = _int(RegExp(r'Max (\d+)').firstMatch(l)?[1]);
      }
    }
    out[day] = d;
  }
  return out;
}

/// `querySleepHrv`: the night's average HRV per wake-up day.
Map<DateTime, double> parseCorosSleepHrv(String text) {
  final out = <DateTime, double>{};
  final section = text.split(RegExp(r'Sleep HRV Time Series')).first;
  for (final MapEntry(key: day, value: lines) in _blocks(section).entries) {
    final v = _int(_field(lines, 'HRV Avg'));
    if (v != null && v > 0) out[day] = v.toDouble();
  }
  return out;
}

/// `queryRestingHeartRate`: `2026-11-04: 48 bpm` per line.
Map<DateTime, int> parseCorosRestingHr(String text) => {
  for (final m in RegExp(
    r'^\s*(\d{4}-\d{2}-\d{2}):\s*(\d+)\s*bpm',
    multiLine: true,
  ).allMatches(text))
    _date(m[1]!)!: int.parse(m[2]!),
};

/// `queryStressLevel`: the day's average stress.
Map<DateTime, int> parseCorosStress(String text) => {
  for (final MapEntry(key: day, value: lines) in _blocks(text).entries)
    if (_int(_field(lines, 'Average Stress')) case final int v) day: v,
};

/// One point of a curve over the night.
typedef CurvePoint = ({DateTime at, double value});

List<CurvePoint> _points(String text, String key) => [
  for (final m in RegExp(
    'timestamp=(\\d+)[^\\n]*?\\b$key=(\\d+(?:\\.\\d+)?)',
  ).allMatches(text))
    (
      at: DateTime.fromMillisecondsSinceEpoch(int.parse(m[1]!) * 1000),
      value: double.parse(m[2]!),
    ),
];

/// `querySleepHrv`: the night's HRV points per wake-up day.
Map<DateTime, List<CurvePoint>> parseCorosHrvSeries(String text) {
  final parts = text.split(RegExp(r'Sleep HRV Time Series'));
  if (parts.length < 2) return const {};
  return {
    for (final MapEntry(key: day, value: lines) in _blocks(parts.last).entries)
      if (_points(lines.join('\n'), 'hrv') case final pts when pts.isNotEmpty)
        day: pts,
  };
}

/// `queryStressTimeSeries`: every stress point; 0 means not measured.
List<CurvePoint> parseCorosStressSeries(String text) => [
  for (final p in _points(text, 'stress'))
    if (p.value > 0) p,
];

/// One wellness check from the watch: the only route by which COROS gives
/// SpO2 and breathing rate, and a resting HRV taken sitting still.
typedef CorosHealthCheck = ({
  DateTime day,
  DateTime? at,
  String? device,
  double? spo2,
  double? respiration,
  double? hrv,
  double? heartRate,
});

/// `queryHealthCheckTimeSeries`: per `Date: 2026-11-04` block the measured
/// lists, e.g. `SpO2 List: [1793781086=98%]` and
/// `Respiration Rate List: [1793781086=16/min]`, averaged per check.
List<CorosHealthCheck> parseCorosHealthCheck(String text) {
  double? mean(String block, String label) {
    final list = RegExp(
      '^\\s*$label List:\\s*\\[([^\\]]*)\\]',
      multiLine: true,
    ).firstMatch(block)?[1];
    if (list == null) return null;
    final values = [
      for (final m in RegExp(r'=\s*(\d+(?:\.\d+)?)').allMatches(list))
        double.parse(m[1]!),
    ].where((v) => v > 0).toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  final out = <CorosHealthCheck>[];
  final parts = text.split(RegExp(r'^\s*Date:\s*', multiLine: true));
  for (final part in parts.skip(1)) {
    final day = _date(part.trim().split(RegExp(r'\s')).first);
    if (day == null) continue;
    final check = (
      day: day,
      at: switch (RegExp(r'\btimestamp=(\d+)').firstMatch(part)) {
        final m? => DateTime.fromMillisecondsSinceEpoch(
          int.parse(m[1]!) * 1000,
        ),
        null => null,
      },
      device: RegExp(r'\bdataSource=([^,\n]+)').firstMatch(part)?[1]?.trim(),
      spo2: mean(part, 'SpO2'),
      respiration: mean(part, 'Respiration Rate'),
      hrv: mean(part, 'HRV'),
      heartRate: mean(part, 'Heart Rate'),
    );
    if (check.spo2 == null && check.respiration == null && check.hrv == null) {
      continue;
    }
    out.add(check);
  }
  return out;
}
