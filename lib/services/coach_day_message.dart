import 'dart:convert';

/// What makes the coach speak up during the day (FjeliaPro).
enum CoachDaySignal {
  /// Today's stress clearly above the athlete's usual level.
  stress,

  /// The energy estimate running low before the evening.
  energy,

  /// Stress back near the usual level after a stress message today.
  stressEased,
}

/// At most this many coach messages a day.
const coachDayMessageLimit = 3;

/// The signal the coach should answer now, or null. One message per sync,
/// each signal at most once a day, only between 09:00 and 20:00. Stress is
/// judged in points like the briefing (from 40, 10 above the usual week);
/// [sentToday] holds the signals already answered today.
CoachDaySignal? dueCoachDaySignal({
  required DateTime now,
  required Set<CoachDaySignal> sentToday,
  double? stress,
  double? stressUsual,
  double? energy,
}) {
  if (sentToday.length >= coachDayMessageLimit) return null;
  if (now.hour < 9 || now.hour >= 20) return null;
  final high =
      stress != null &&
      stressUsual != null &&
      stress >= 40 &&
      stress >= stressUsual + 10;
  if (high && !sentToday.contains(CoachDaySignal.stress)) {
    return CoachDaySignal.stress;
  }
  if (energy != null &&
      energy <= 25 &&
      now.hour < 18 &&
      !sentToday.contains(CoachDaySignal.energy)) {
    return CoachDaySignal.energy;
  }
  if (sentToday.contains(CoachDaySignal.stress) &&
      !sentToday.contains(CoachDaySignal.stressEased) &&
      stress != null &&
      stressUsual != null &&
      stress < stressUsual + 5) {
    return CoachDaySignal.stressEased;
  }
  return null;
}

/// The question for the coach: the signal and the values behind it.
String coachDayQuestion(
  CoachDaySignal signal, {
  required DateTime now,
  double? stress,
  double? stressUsual,
  double? energy,
}) => jsonEncode({
  'signal': switch (signal) {
    CoachDaySignal.stress => 'stress',
    CoachDaySignal.energy => 'energy',
    CoachDaySignal.stressEased => 'stress_eased',
  },
  'time':
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}',
  'stress_today': ?stress?.round(),
  'stress_usual': ?stressUsual?.round(),
  'energy_now': ?energy?.round(),
});

/// The coach's answer as it may be shown: one short plain paragraph, or
/// null when it is empty, too long or not plain text.
String? usableCoachDayMessage(String answer) {
  final text = answer
      .replaceAll(RegExp(r'[*_#`>]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.isEmpty || text.length > 320) return null;
  if (text.startsWith('{') || text.startsWith('[')) return null;
  return text;
}
