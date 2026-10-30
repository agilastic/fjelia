import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/bio_age_service.dart';
import '../services/bio_age_activity.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'user_profile_provider.dart';

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  values.sort();
  return values[values.length ~/ 2];
}

/// Biological age from the latest wearable, scale, BP and lab data.
final bioAgeProvider = FutureProvider<BioAgeResult?>((ref) async {
  ref.watch(syncStatusListenerProvider);
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final db = ref.read(databaseProvider);
  final age = profile?.age;
  if (profile == null || age == null) return null;

  final rhr = _median(
    (await db.getHrvRange(7))
        .where((h) => h.restingHeartRate != null)
        .map((h) => h.restingHeartRate!.toDouble())
        .toList(),
  );
  final systolic = _median(
    (await db.getRecentBp(14))
        .where((b) => b.systolic > 0)
        .map((b) => b.systolic.toDouble())
        .toList(),
  );

  final scale = await db.getRenphoRange(90);
  final latestScale = scale.isEmpty ? null : scale.last;

  final grips = await db.getGripStrengthRange();
  final latestGrip = grips.isEmpty ? null : grips.last;
  final gripKg = latestGrip == null
      ? null
      : [
          latestGrip.leftKg ?? 0.0,
          latestGrip.rightKg ?? 0.0,
        ].reduce((a, b) => a > b ? a : b);

  final wellness = await db.getWellnessRange(30);
  final activity = BioAgeActivity.fromDays(
    wellness.map(
      (day) => BioAgeActivityDay(
        date: day.date,
        reportedMinutes: day.intensityMinutes,
        steps: day.steps,
      ),
    ),
    today: DateTime.now(),
  );
  double? vo2max;
  for (final w in wellness.reversed) {
    if (w.vo2max != null) {
      vo2max = w.vo2max;
      break;
    }
  }

  var bmi = latestScale?.bmi;
  if (bmi == null && latestScale?.weight != null) {
    final h = (profile.heightCm ?? 175) / 100;
    bmi = latestScale!.weight! / (h * h);
  }

  return estimateBioAge(
    BioAgePerson(
      sex: profile.sex,
      age: age,
      vo2max: vo2max,
      gripKg: gripKg == null || gripKg <= 0 ? null : gripKg,
      bmi: bmi,
      visceralFat: latestScale?.visceralFat,
      activity: activity,
      restingHr: rhr,
      systolic: systolic,
      // Walking-time estimates inform the activity factor, not a second,
      // exercise-derived VO2max estimate.
      weeklyActivityMinutes: activity.reportedDays == 0
          ? null
          : activity.reportedMinutes,
      smoking: profile.smokingStatus,
      cigarettesPerDay: profile.cigarettesPerDay?.toDouble(),
      yearsSinceQuit: profile.yearsSinceQuit?.toDouble(),
      alcoholGramsPerWeek: profile.alcoholDrinksPerMonth == null
          ? null
          : profile.alcoholDrinksPerMonth! * 12 / 4.345,
      diabetes: profile.diabetesType ?? 'none',
      hba1c: profile.hba1cPercent,
      ldl: profile.ldlCholesterol,
      hdl: profile.hdlCholesterol,
      apob: profile.apoB,
      crp: profile.hsCrp,
      egfr: profile.eGfr,
    ),
  );
});
