enum HeatStatus { none, partial, full }

class HeatPlanForecast {
  const HeatPlanForecast();
}

class HeatDailyStateData {
  const HeatDailyStateData({
    required this.date,
    required this.score,
    required this.status,
    required this.decayApplied,
    required this.workoutGain,
    this.lastActivityId,
    this.recommendation,
    required this.updatedAt,
  });

  final DateTime date;
  final double score;
  final HeatStatus status;
  final double decayApplied;
  final double workoutGain;
  final String? lastActivityId;
  final String? recommendation;
  final DateTime updatedAt;
}

class HeatWorkoutContextData {
  const HeatWorkoutContextData({
    required this.activityId,
    required this.activityStart,
    required this.source,
    required this.isOutdoor,
    required this.qualifies,
    required this.durationMinutes,
    this.temperatureC,
    this.humidityPct,
    this.pressureHpa,
    this.wetBulbC,
    required this.scoreBefore,
    required this.scoreAfter,
    this.weatherCacheKey,
    this.rawJson,
  });

  final String activityId;
  final DateTime activityStart;
  final String source;
  final bool isOutdoor;
  final bool qualifies;
  final double durationMinutes;
  final double? temperatureC;
  final double? humidityPct;
  final double? pressureHpa;
  final double? wetBulbC;
  final double scoreBefore;
  final double scoreAfter;
  final String? weatherCacheKey;
  final String? rawJson;

  Map<String, dynamic> toJson() => {
        'activityId': activityId,
        'activityStart': activityStart.toIso8601String(),
        'source': source,
        'isOutdoor': isOutdoor,
        'qualifies': qualifies,
        'durationMinutes': durationMinutes,
        'temperatureC': temperatureC,
        'humidityPct': humidityPct,
        'pressureHpa': pressureHpa,
        'wetBulbC': wetBulbC,
        'scoreBefore': scoreBefore,
        'scoreAfter': scoreAfter,
        'weatherCacheKey': weatherCacheKey,
        'rawJson': rawJson,
      };
}

class WeatherSnapshotData {
  const WeatherSnapshotData({
    required this.cacheKey,
    required this.source,
    required this.observedAt,
    required this.latitude,
    required this.longitude,
    required this.temperatureC,
    required this.humidityPct,
    this.pressureHpa,
    required this.wetBulbC,
    required this.rawJson,
  });

  final String cacheKey;
  final String source;
  final DateTime observedAt;
  final double latitude;
  final double longitude;
  final double temperatureC;
  final double humidityPct;
  final double? pressureHpa;
  final double wetBulbC;
  final String rawJson;

  Map<String, dynamic> toJson() => {
        'cacheKey': cacheKey,
        'source': source,
        'observedAt': observedAt.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'temperatureC': temperatureC,
        'humidityPct': humidityPct,
        'pressureHpa': pressureHpa,
        'wetBulbC': wetBulbC,
        'rawJson': rawJson,
      };
}
