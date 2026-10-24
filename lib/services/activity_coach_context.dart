import '../db/database.dart';
import '../providers/training_load_provider.dart' show effectiveLoad;

/// Compact TOON context for chatting about one activity: the activity, the
/// 30 days of training leading up to it and the year's progression (with the
/// same period of the previous year). Anchored to the activity's date, so
/// older activities are judged against the training around them. Names and
/// GPS are never included.
class ActivityCoachContextBuilder {
  ActivityCoachContextBuilder(this._db);

  final AppDatabase _db;

  Future<String> build(ActivityRecord activity) async {
    final from = DateTime(activity.startDate.year - 1, 1, 1);
    final days = DateTime.now().difference(from).inDays + 1;
    final all = await _db.getActivitiesInRange(days);
    return buildFrom(activity, all, hrvLine: await _hrvAround(activity));
  }

  /// HRV before and after the activity, when it was recorded: the night
  /// before and the night after (watch), and Polar H10 spot readings taken
  /// before the start and after the end.
  Future<String> _hrvAround(ActivityRecord a) async {
    final end = a.startDate.add(Duration(seconds: a.durationSeconds));
    final day = DateTime(a.startDate.year, a.startDate.month, a.startDate.day);
    final before = await _db.getHrvForDate(day);
    final after = await _db.getHrvForDate(
      DateTime(day.year, day.month, day.day + 1),
    );
    final spots = await _db.getSpotHrvBetween(
      a.startDate.subtract(const Duration(hours: 6)),
      end.add(const Duration(hours: 8)),
    );
    return hrvAroundLine(
      start: a.startDate,
      end: end,
      preNight: before?.hrvLastNight,
      preDate: before?.date,
      weeklyAverage: before?.hrvWeeklyAvg,
      postNight: after?.hrvLastNight,
      postDate: after?.date,
      spots: spots,
    );
  }

  static String buildFrom(
    ActivityRecord activity,
    List<ActivityRecord> all, {
    String? hrvLine,
  }) {
    final anchor = activity.startDate;
    final end = DateTime(anchor.year, anchor.month, anchor.day + 1);
    final start30 = end.subtract(const Duration(days: 30));
    final last30 = [
      for (final a in all)
        if (!a.startDate.isBefore(start30) && a.startDate.isBefore(end)) a,
    ];
    final sport = _sport(activity.type);
    final earlier = [
      for (final a in all)
        if (a.startDate.isBefore(anchor)) a.startDate,
    ]..sort();
    final out = <String>[
      '[Activity:${_date(anchor)} ${_weekday(anchor)},Sport:$sport,'
          '${_stats(activity)}]',
      // A long gap may be a pause or missing data: the model must not treat
      // it as rest.
      '[DataStatus:PreviousActivity:${earlier.isEmpty ? 'NoneInLoadedHistory' : '${_date(earlier.last)},DaysBefore:${DateTime(anchor.year, anchor.month, anchor.day).difference(DateTime(earlier.last.year, earlier.last.month, earlier.last.day)).inDays}'},'
          'MissingRecord:Unknown]',
      ?hrvLine,
    ];

    // Last 30 days.
    final t = _Totals.of(last30);
    out.add(
      '[Last30d:${_date(start30)}..${_date(anchor)},Sessions:${t.n},'
      'ActiveDays:${last30.map((a) => _date(a.startDate)).toSet().length},'
      'H:${_dec(t.hours)},Km:${_int(t.km)},Load:${_int(t.load)}]',
    );
    final bySport = _groupBySport(last30);
    out.add(
      '[Last30d:Sports:${bySport.entries.map((e) {
        final s = _Totals.of(e.value);
        return '${e.key} ${s.n}x ${_dec(s.hours)}h ${_int(s.km)}km L${_int(s.load)}';
      }).join(';')}]',
    );
    final weeks = <String>[];
    for (var w = 3; w >= 0; w--) {
      final wEnd = end.subtract(Duration(days: 7 * w));
      final wStart = wEnd.subtract(const Duration(days: 7));
      final s = _Totals.of([
        for (final a in last30)
          if (!a.startDate.isBefore(wStart) && a.startDate.isBefore(wEnd)) a,
      ]);
      weeks.add('${_dec(s.hours)}h/L${_int(s.load)}');
    }
    out.add('[Last30d:Weeks(oldest..newest):${weeks.join(';')}]');

    // This activity vs other sessions of the same sport.
    final same = [
      for (final a in last30)
        if (_sport(a.type) == sport && a.activityId != activity.activityId) a,
    ];
    if (same.isNotEmpty) {
      final s = _Totals.of(same);
      final hr = _avg(same.map((a) => a.avgHeartRate));
      out.add(_compare(activity, sport, s, hr));
      out.add(
        '[Similar30d:$sport,N:${s.n},AvgMin:${_int(s.hours * 60 / s.n)},'
        'AvgKm:${_dec(s.km / s.n)},AvgHR:${_int(hr)},AvgLoad:${_int(s.load / s.n)}'
        '${_speedPart(sport, s.km, s.movingSeconds)}]',
      );
    }

    // Year progression up to the activity, against the same span last year.
    final year = anchor.year;
    bool inYearToDate(ActivityRecord a, int y) {
      final cutoff = DateTime(y, anchor.month, anchor.day + 1);
      return a.startDate.year == y && a.startDate.isBefore(cutoff);
    }

    for (final y in [year, year - 1]) {
      final ytd = [
        for (final a in all)
          if (inYearToDate(a, y)) a,
      ];
      final s = _Totals.of(ytd);
      out.add(
        '[Year:$y:ToDate(${anchor.month}/${anchor.day}),Sessions:${s.n},'
        'H:${_int(s.hours)},Km:${_int(s.km)},Load:${_int(s.load)}]',
      );
    }
    final months = <String>[];
    for (var m = 1; m <= anchor.month; m++) {
      final s = _Totals.of([
        for (final a in all)
          if (a.startDate.year == year && a.startDate.month == m) a,
      ]);
      months.add('${_monthNames[m - 1]} ${_int(s.hours)}h ${_int(s.km)}km');
    }
    out.add('[Year:$year:Months:${months.join(';')}]');
    final ytdSport = _groupBySport([
      for (final a in all)
        if (inYearToDate(a, year)) a,
    ]);
    out.add(
      '[Year:$year:Sports:${ytdSport.entries.map((e) {
        final s = _Totals.of(e.value);
        return '${e.key} ${s.n}x ${_int(s.hours)}h ${_int(s.km)}km';
      }).join(';')}]',
    );
    return out.join('\n');
  }

  /// This activity against the average of the other sessions of the sport:
  /// the figures and their ratios are worked out here, so a model does not
  /// have to compare numbers itself.
  static String _compare(
    ActivityRecord a,
    String sport,
    _Totals others,
    double? othersHr,
  ) {
    String ratio(double mine, double avg) =>
        avg > 0 ? ' (${(mine / avg).toStringAsFixed(1)}x)' : '';
    final minutes = a.durationSeconds / 60;
    final avgMinutes = others.hours * 60 / others.n;
    final km = (a.distanceMeters ?? 0) / 1000;
    final avgKm = others.km / others.n;
    final load = effectiveLoad(a);
    final avgLoad = others.load / others.n;
    final parts = <String>[
      'Min:${_int(minutes)} vs ${_int(avgMinutes)}${ratio(minutes, avgMinutes)}',
      if (km > 0 && avgKm > 0)
        'Km:${_dec(km)} vs ${_dec(avgKm)}${ratio(km, avgKm)}',
      'Load:${_int(load)} vs ${_int(avgLoad)}${ratio(load, avgLoad)}',
      if (a.avgHeartRate != null && othersHr != null)
        'AvgHR:${_int(a.avgHeartRate)} vs ${_int(othersHr)}'
            ' (${a.avgHeartRate! - othersHr >= 0 ? '+' : '-'}${(a.avgHeartRate! - othersHr).abs().round()} bpm)',
    ];
    return '[Compare:$sport,N:${others.n},${parts.join(',')}]';
  }

  static String _stats(ActivityRecord a) {
    final km = (a.distanceMeters ?? 0) / 1000;
    final moving = a.movingDurationSeconds ?? a.durationSeconds;
    return [
      'Min:${_int(a.durationSeconds / 60)}',
      if (km > 0) 'Km:${_dec(km)}',
      if (km > 0) _speedPart(_sport(a.type), km, moving).substring(1),
      if (a.avgHeartRate != null) 'AvgHR:${_int(a.avgHeartRate)}',
      if (a.maxHeartRate != null) 'MaxHR:${_int(a.maxHeartRate)}',
      'Load:${_int(effectiveLoad(a))}',
      if ((a.totalElevation ?? 0) > 0) 'ElevM:${_int(a.totalElevation)}',
      if (a.avgWatts != null) 'AvgW:${_int(a.avgWatts)}',
      if (a.aerobicTrainingEffect != null)
        'TE:${_dec(a.aerobicTrainingEffect)}/${_dec(a.anaerobicTrainingEffect)}',
    ].where((s) => s.isNotEmpty).join(',');
  }

  /// Pace for running/walking/hiking, speed otherwise; ',' prefixed.
  static String _speedPart(String sport, double km, int seconds) {
    if (km <= 0 || seconds <= 0) return '';
    if (sport == 'run' || sport == 'walk' || sport == 'hike') {
      final secPerKm = (seconds / km).round();
      return ',Pace:${secPerKm ~/ 60}:${(secPerKm % 60).toString().padLeft(2, '0')}/km';
    }
    return ',Kmh:${_dec(km / (seconds / 3600))}';
  }

  static Map<String, List<ActivityRecord>> _groupBySport(
    List<ActivityRecord> list,
  ) {
    final map = <String, List<ActivityRecord>>{};
    for (final a in list) {
      map.putIfAbsent(_sport(a.type), () => []).add(a);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Map.fromEntries(entries);
  }

  static String _sport(String type) {
    final t = type.toLowerCase();
    if (t.contains('run')) return 'run';
    if (t.contains('cycl') || t.contains('bik') || t.contains('ride')) {
      return 'ride';
    }
    if (t.contains('swim')) return 'swim';
    if (t.contains('walk')) return 'walk';
    if (t.contains('hik')) return 'hike';
    if (t.contains('strength') || t.contains('weight')) return 'strength';
    if (t.contains('ski')) return 'ski';
    if (t.contains('row')) return 'row';
    if (t.contains('yoga') || t.contains('mobility')) return 'mobility';
    return t.replaceAll('_', ' ');
  }

  static double? _avg(Iterable<double?> values) {
    final v = values.whereType<double>().toList();
    return v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;
  }

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  static String _weekday(DateTime d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
  static String _int(num? v) =>
      v == null || !v.isFinite ? 'na' : v.round().toString();
  static String _dec(num? v) =>
      v == null || !v.isFinite ? 'na' : v.toStringAsFixed(1);
}

class _Totals {
  _Totals(this.n, this.hours, this.km, this.load, this.movingSeconds);

  factory _Totals.of(List<ActivityRecord> list) {
    var seconds = 0, moving = 0;
    var km = 0.0, load = 0.0;
    for (final a in list) {
      seconds += a.durationSeconds;
      moving += a.movingDurationSeconds ?? a.durationSeconds;
      km += (a.distanceMeters ?? 0) / 1000;
      load += effectiveLoad(a);
    }
    return _Totals(list.length, seconds / 3600, km, load, moving);
  }

  final int n;
  final double hours, km, load;
  final int movingSeconds;
}

/// One TOON line with the HRV around an activity, the changes already worked
/// out. Overnight HRV and H10 spot readings are measured differently, so the
/// line states both separately and flags that.
String hrvAroundLine({
  required DateTime start,
  required DateTime end,
  double? preNight,
  DateTime? preDate,
  double? weeklyAverage,
  double? postNight,
  DateTime? postDate,
  List<SpotHrvMeasurement> spots = const [],
}) {
  String date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String ms(double v) => '${v.round()}ms';
  String change(double from, double to) {
    final d = (to - from).round();
    final pct = from > 0 ? ((to - from) / from * 100).round() : null;
    return '${d >= 0 ? '+' : '-'}${d.abs()}ms${pct == null ? '' : '(${pct >= 0 ? '+' : '-'}${pct.abs()}%)'}';
  }

  // The reading closest before the start and the first one after the end.
  SpotHrvMeasurement? before, after;
  for (final s in spots) {
    if (s.startedAt.isBefore(start)) {
      before = s;
    } else if (after == null &&
        !s.startedAt.isBefore(end.subtract(const Duration(minutes: 10)))) {
      after = s;
    }
  }
  String spot(SpotHrvMeasurement s, {bool afterTraining = false}) {
    final posture = s.posture == 'supine' ? 'lying' : 'seated';
    final minutes = afterTraining && s.minutesAfterTraining != null
        ? ',${s.minutesAfterTraining}min after training'
        : '';
    return '${ms(s.rmssdMs)}(${time(s.startedAt)},$posture,'
        '${(s.durationSeconds / 60).round()}min$minutes)';
  }

  final parts = <String>[
    if (preNight != null && preDate != null)
      'PreNight:${ms(preNight)}(${date(preDate)})',
    if (postNight != null && postDate != null)
      'PostNight:${ms(postNight)}(${date(postDate)})',
    if (preNight != null && postNight != null)
      'NightChange:${change(preNight, postNight)}',
    if (weeklyAverage != null) 'WeeklyAvg:${ms(weeklyAverage)}',
    if (before != null) 'SpotBefore:${spot(before)}',
    if (after != null) 'SpotAfter:${spot(after, afterTraining: true)}',
    if (before != null && after != null)
      'SpotChange:${change(before.rmssdMs, after.rmssdMs)}',
  ];
  if (parts.isEmpty) return '[HRV:AroundActivity,Unavailable]';
  return '[HRV:AroundActivity,${parts.join(',')},Note:MethodsDiffer]';
}
