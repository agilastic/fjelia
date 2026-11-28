import 'package:fjelia_views/fjelia_views.dart';
import 'package:intl/intl.dart';

import '../db/database.dart';

// What the records are lives in fjelia_core and fjelia_views, shared with
// the desktop; this file keeps the app's wording.
export 'package:fjelia_core/services/best_efforts.dart';
export 'package:fjelia_views/fjelia_views.dart'
    show BestEffort, SportStats, StatsSport, StatsTotals, statsSportOf;

/// Works out the numbers for both sports from the stored activities.
Future<Map<StatsSport, SportStats>> computeSportStats(
  AppDatabase db,
  DateTime now,
) => loadSportStats(db, now);

String _duration(double seconds) {
  final s = seconds.round();
  final h = s ~/ 3600, m = s ~/ 60 % 60, sec = s % 60;
  return h > 0
      ? '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}'
      : '$m:${sec.toString().padLeft(2, '0')}';
}

String _hours(double seconds) =>
    '${seconds ~/ 3600}h ${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}m';

/// The numbers as context lines for the Pro analyses.
List<String> sportStatsLines(Map<StatsSport, SportStats> stats, DateTime now) {
  String day(DateTime? d) =>
      d == null ? '' : ' (${DateFormat('yyyy-MM-dd').format(d)})';
  String totals(StatsTotals t) =>
      'act ${countText(t.count)},dist ${(t.meters / 1000).toStringAsFixed(1)}km,'
      'time ${_hours(t.seconds)},elev ${t.elevation.round()}m';
  final lines = <String>[];
  for (final s in stats.values) {
    if (s.allTime.count == 0) continue;
    final name = s.sport == StatsSport.run ? 'Run' : 'Ride';
    lines.add(
      '[SportStats:$name,Last4wPerWeek(${totals(s.last4PerWeek)}),'
      'Year${now.year}(${totals(s.year)}),AllTime(${totals(s.allTime)})'
      '${s.longest == null ? '' : ',Longest:${(s.longest! / 1000).toStringAsFixed(1)}km${day(s.longestDate)}'}'
      '${s.mostElevation == null ? '' : ',MostElevation:${s.mostElevation!.round()}m${day(s.mostElevationDate)}'}]',
    );
    final efforts = [
      for (final e in s.efforts)
        if (e.allTime != null)
          '${e.label}:${_duration(e.allTime!)}${day(e.allTimeDate)}'
              '${e.year == null ? '' : ' year ${_duration(e.year!)}${day(e.yearDate)}'}',
    ];
    if (efforts.isNotEmpty) {
      lines.add('[BestEfforts:$name,${efforts.join(',')}]');
    }
  }
  return lines;
}

/// A count as a whole number, or with one decimal when it is an average.
String countText(double count) => count == count.roundToDouble()
    ? '${count.round()}'
    : count.toStringAsFixed(1);

/// For the view: a duration like 22:02 or 1:47:27.
String effortTime(double seconds) => _duration(seconds);

/// For the view: hours and minutes like 3h 27m.
String statsHours(double seconds) => _hours(seconds);
