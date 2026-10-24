import 'log.dart';

/// A single Aktiia cuffless BP reading.
class BloodPressureMeasurement {
  const BloodPressureMeasurement({
    required this.dateTime,
    this.timezone = 'UTC',
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    this.measurementType = 'POD',
    this.algoVersion,
    this.dayNightTag,
    this.isBedTime,
    this.isWakeUpTime,
  });

  factory BloodPressureMeasurement.fromJson(Map<String, dynamic> json) {
    return BloodPressureMeasurement(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dateTime'] as int)
          .toLocal(),
      timezone: json['timezone'] as String? ?? 'UTC',
      systolic: json['sys'] as int,
      diastolic: json['dia'] as int,
      heartRate: json['hr'] as int,
      measurementType: json['measurementType'] as String? ?? 'POD',
      algoVersion: json['algoVersion'] as String?,
      dayNightTag: json['dayNightTag'] as String?,
      isBedTime: json['bedTime'] as bool?,
      isWakeUpTime: json['wakeUpTime'] as bool?,
    );
  }

  final DateTime dateTime;
  final String timezone;
  final int systolic;
  final int diastolic;
  final int heartRate;
  final String measurementType;
  final String? algoVersion;
  final String? dayNightTag;
  final bool? isBedTime;
  final bool? isWakeUpTime;
}

/// One aggregated block of readings inside a daily Aktiia summary.
class BpSegment {
  const BpSegment({
    required this.time,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.maxSystolic,
    this.minSystolic,
    this.count,
    this.dayNightTag,
    this.isBedTime,
    this.isWakeUpTime,
  });

  factory BpSegment.fromJson(Map<String, dynamic> json) {
    return BpSegment(
      systolic: json['sys'] as int?,
      diastolic: json['dia'] as int?,
      heartRate: json['hr'] as int?,
      maxSystolic: json['maxSys'] as int?,
      minSystolic: json['minSys'] as int?,
      count: json['count'] as int?,
      time: DateTime.fromMillisecondsSinceEpoch(
        (json['_id'] ?? json['dateTime'] ?? json['timestamp']) as int,
      ).toLocal(),
      dayNightTag: json['dayNightTag'] as String?,
      isBedTime: json['bedTime'] as bool?,
      isWakeUpTime: json['wakeUpTime'] as bool?,
    );
  }

  final DateTime time;
  final int? systolic;
  final int? diastolic;
  final int? heartRate;
  final int? maxSystolic;
  final int? minSystolic;
  final int? count;
  final String? dayNightTag;
  final bool? isBedTime;
  final bool? isWakeUpTime;
}

/// Daily summary as returned by Aktiia's `/daily` endpoint.
class DailyBpSummary {
  const DailyBpSummary({
    required this.date,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.avgHeartRate,
    required this.maxSystolic,
    required this.minSystolic,
    required this.maxDiastolic,
    required this.minDiastolic,
    required this.count,
    this.normalBpPercent,
    this.trend,
    this.segments = const [],
  });

  factory DailyBpSummary.fromJson(DateTime date, Map<String, dynamic> json) {
    final avg = json['avg'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final summary =
        json['summary'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final measurements =
        json['measurements'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final segments = <BpSegment>[];
    for (final e in measurements.entries) {
      try {
        segments.add(BpSegment.fromJson(e.value as Map<String, dynamic>));
      } catch (err) {
        log('[Aktiia] daily: skipping unparsable segment ${e.key} ($err): ${e.value}');
      }
    }

    return DailyBpSummary(
      date: date,
      avgSystolic: (avg['sys'] as num?)?.toDouble() ?? 0.0,
      avgDiastolic: (avg['dia'] as num?)?.toDouble() ?? 0.0,
      avgHeartRate: (avg['hr'] as num?)?.toDouble() ?? 0.0,
      maxSystolic: summary['maxSys'] as int? ?? 0,
      minSystolic: summary['minSys'] as int? ?? 0,
      maxDiastolic: summary['maxDia'] as int? ?? 0,
      minDiastolic: summary['minDia'] as int? ?? 0,
      count: summary['count'] as int? ?? 0,
      normalBpPercent: (summary['normalBPPercentage'] as num?)?.toDouble(),
      trend: json['comparing'] as String?,
      segments: segments,
    );
  }

  final DateTime date;
  final double avgSystolic;
  final double avgDiastolic;
  final double avgHeartRate;
  final int maxSystolic;
  final int minSystolic;
  final int maxDiastolic;
  final int minDiastolic;
  final int count;
  final double? normalBpPercent;
  final String? trend;
  final List<BpSegment> segments;

  /// Nocturnal systolic dip relative to the daytime average, in percent.
  /// A healthy "dipper" drops more than 10 % at night.
  double? get nightDippingPercent {
    final day = segments
        .where((s) => s.dayNightTag == 'DAY' && s.systolic != null)
        .toList();
    final night = segments
        .where((s) => s.dayNightTag == 'NIGHT' && s.systolic != null)
        .toList();
    if (day.isEmpty || night.isEmpty) return null;
    final dayAvg =
        day.map((s) => s.systolic!).reduce((a, b) => a + b) / day.length;
    final nightAvg =
        night.map((s) => s.systolic!).reduce((a, b) => a + b) / night.length;
    return (dayAvg - nightAvg) / dayAvg * 100;
  }
}
