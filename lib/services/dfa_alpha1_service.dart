import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../utils/log.dart';
import 'dfa_alpha1.dart';
import 'fit_activity_data.dart';

/// Stores the DFA alpha1 of activities whose FIT file carries beat-to-beat
/// intervals (file import, Polar and Garmin sync).
class DfaAlpha1Service {
  DfaAlpha1Service(this._db);

  final AppDatabase _db;

  /// Whether [activityId] was analysed already, with or without RR data.
  Future<bool> checked(String activityId) async =>
      await _row(activityId) != null;

  Future<DfaAlpha1Result?> _row(String activityId) => (_db.select(
    _db.dfaAlpha1Results,
  )..where((t) => t.activityId.equals(activityId))).getSingleOrNull();

  /// The analysis of [activityId]; null when its file had no RR intervals.
  Future<DfaAlpha1Analysis?> load(String activityId) async {
    final row = await _row(activityId);
    if (row == null || row.rrCount == 0) return null;
    final raw = jsonDecode(row.windowsJson);
    DfaThreshold? threshold(double? bpm, double? watts, double? speed) =>
        bpm == null
        ? null
        : DfaThreshold(heartRate: bpm, watts: watts, speed: speed);
    return DfaAlpha1Analysis(
      windows: [
        if (raw is List)
          for (final w in raw) ?DfaWindow.fromJson(w),
      ],
      rrCount: row.rrCount,
      artifacts: row.artifacts,
      hrvt1: threshold(row.hrvt1Bpm, row.hrvt1Watts, row.hrvt1Speed),
      hrvt2: threshold(row.hrvt2Bpm, row.hrvt2Watts, row.hrvt2Speed),
    );
  }

  /// HRVT1 and HRVT2 heart rates of the recent sessions of one sport kind,
  /// newest first, for the threshold candidates.
  Future<List<({DateTime date, double? hrvt1, double? hrvt2})>> recent({
    required bool cycling,
    Duration within = const Duration(days: 42),
  }) async {
    final since = DateTime.now().subtract(within);
    final query =
        _db.select(_db.dfaAlpha1Results).join([
            innerJoin(
              _db.activityRecords,
              _db.activityRecords.activityId.equalsExp(
                _db.dfaAlpha1Results.activityId,
              ),
            ),
          ])
          ..where(
            _db.activityRecords.startDate.isBiggerOrEqualValue(since) &
                (_db.dfaAlpha1Results.hrvt1Bpm.isNotNull() |
                    _db.dfaAlpha1Results.hrvt2Bpm.isNotNull()),
          )
          ..orderBy([OrderingTerm.desc(_db.activityRecords.startDate)]);
    return [
      for (final row in await query.get())
        if (_isCycling(row.readTable(_db.activityRecords).type) == cycling)
          (
            date: row.readTable(_db.activityRecords).startDate,
            hrvt1: row.readTable(_db.dfaAlpha1Results).hrvt1Bpm,
            hrvt2: row.readTable(_db.dfaAlpha1Results).hrvt2Bpm,
          ),
    ];
  }

  static bool _isCycling(String type) {
    final t = type.toLowerCase();
    return t.contains('cycl') || t.contains('bik') || t.contains('ride');
  }

  /// Analyses the RR intervals of [fit] for [activityId] and stores the
  /// result; a file without them is recorded as checked.
  Future<DfaAlpha1Analysis?> saveFromFit(
    String activityId,
    FitActivityData fit,
  ) {
    final start =
        fit.start ??
        (fit.samples.isEmpty
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                fit.samples.first['t']!.toInt(),
                isUtc: true,
              ));
    return save(
      activityId,
      start: start,
      rrIntervals: fit.rrIntervals,
      samples: fit.samples,
    );
  }

  Future<DfaAlpha1Analysis?> save(
    String activityId, {
    required DateTime? start,
    required List<double> rrIntervals,
    List<Map<String, num>> samples = const [],
  }) async {
    final analysis = start == null || rrIntervals.isEmpty
        ? null
        : analyseDfaAlpha1(
            RrSeries.fromIntervals(start, rrIntervals),
            samples: samples,
          );
    await _db
        .into(_db.dfaAlpha1Results)
        .insertOnConflictUpdate(
          DfaAlpha1ResultsCompanion.insert(
            activityId: activityId,
            rrCount: analysis?.rrCount ?? 0,
            artifacts: analysis?.artifacts ?? 0,
            windowsJson: jsonEncode([
              for (final w in analysis?.windows ?? <DfaWindow>[]) w.toJson(),
            ]),
            hrvt1Bpm: Value(analysis?.hrvt1?.heartRate),
            hrvt1Watts: Value(analysis?.hrvt1?.watts),
            hrvt1Speed: Value(analysis?.hrvt1?.speed),
            hrvt2Bpm: Value(analysis?.hrvt2?.heartRate),
            hrvt2Watts: Value(analysis?.hrvt2?.watts),
            hrvt2Speed: Value(analysis?.hrvt2?.speed),
            computedAt: DateTime.now(),
          ),
        );
    if (analysis != null) {
      log(
        '[DFA] $activityId: ${analysis.rrCount} beats, '
        '${(analysis.artifacts * 100).toStringAsFixed(1)} % artifacts, '
        '${analysis.windows.length} windows, '
        'HRVT1 ${analysis.hrvt1?.heartRate.toStringAsFixed(0) ?? '-'}',
      );
    }
    return analysis;
  }
}
