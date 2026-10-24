import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import 'database_provider.dart';

final activityHeatDetailsProvider =
    FutureProvider.family<
      ({HeatWorkoutContext? context, List<WeatherSnapshotRecord> samples}),
      String
    >((ref, id) async {
      final db = ref.watch(databaseProvider);
      final context = await db.getHeatWorkoutContextForActivity(id);
      if (context == null) {
        return (context: null, samples: <WeatherSnapshotRecord>[]);
      }
      final anchor = context.weatherCacheKey == null
          ? null
          : await db.getWeatherSnapshotByKey(context.weatherCacheKey!);
      final samples = anchor == null
          ? <WeatherSnapshotRecord>[]
          : await db.getWeatherSnapshotsForActivity(
              anchor.latitude,
              anchor.longitude,
              context.activityStart,
              context.activityStart.add(
                Duration(seconds: (context.durationMinutes * 60).round()),
              ),
            );
      return (context: context, samples: samples);
    });
