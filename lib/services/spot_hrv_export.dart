import 'dart:convert';
import '../db/database.dart';

String spotHrvCsv(SpotHrvMeasurement row) {
  String cell(Object? v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';
  final samples = jsonDecode(row.rrJson) as List<dynamic>;
  final rows = <List<Object?>>[
    [
      'source',
      'measured_at',
      'context',
      'posture',
      'duration_seconds',
      'settle_seconds',
      'minutes_after_training',
      'rmssd_ms',
      'raw_rmssd_ms',
      'sdnn_ms',
      'ln_rmssd',
      'mean_hr_bpm',
      'device',
      'notes',
      'elapsed_ms',
      'rr_ms',
      'contact',
      'excluded_reason',
    ],
    for (final sample in samples)
      [
        'polar_h10_rr',
        row.startedAt.toIso8601String(),
        row.context,
        row.posture,
        row.durationSeconds,
        row.settleSeconds,
        row.minutesAfterTraining,
        row.rmssdMs,
        row.rawRmssdMs,
        row.sdnnMs,
        row.lnRmssd,
        row.meanHr,
        row.deviceName,
        row.notes,
        sample['elapsed_ms'],
        sample['rr_ms'],
        sample['contact'],
        sample['excluded'],
      ],
  ];
  return rows.map((r) => r.map(cell).join(',')).join('\r\n');
}
