import 'dart:math' as math;

/// The moon's phase from the time since a known new moon (6 Jan 2000,
/// 18:14 UTC) over the mean synodic month. Accurate to about a day, which is
/// what a weather screen needs.
enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  full,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

const synodicMonthDays = 29.530588853;
final _knownNewMoon = DateTime.utc(2000, 1, 6, 18, 14);

/// Days since the last new moon, 0 to 29.53.
double moonAge(DateTime time) {
  final days =
      time.toUtc().difference(_knownNewMoon).inSeconds / Duration.secondsPerDay;
  return (days % synodicMonthDays + synodicMonthDays) % synodicMonthDays;
}

/// Share of the disc that is lit, 0 (new) to 1 (full).
double moonIllumination(DateTime time) =>
    (1 - math.cos(2 * math.pi * moonAge(time) / synodicMonthDays)) / 2;

/// Whether the lit part grows (new to full).
bool moonWaxing(DateTime time) => moonAge(time) < synodicMonthDays / 2;

MoonPhase moonPhaseOf(DateTime time) {
  // Eight equal parts, each centred on its phase.
  final eighth = synodicMonthDays / 8;
  final index = ((moonAge(time) + eighth / 2) / eighth).floor() % 8;
  return MoonPhase.values[index];
}
