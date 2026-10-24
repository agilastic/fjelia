/// Reading and writing a race target time.
///
/// Accepted: `3:30:00`, `3:30`, `3h30`, `3h 30m`, `45:00` and a plain number
/// of minutes. With two parts the meaning depends on the race: `3:30` is
/// 3 h 30 min for a marathon, `25:00` is 25 min for a 5 km. [distanceKm]
/// decides, by which reading gives a pace a person could hold.

/// Seconds per kilometre a race of [sport] could be done at, fastest and
/// slowest. Wide on purpose: it catches a typo, not an ambitious goal.
(double, double) _paceRange(String? sport) => switch (sport) {
  'running' || 'trail_running' => (150, 1200),
  'cycling_road' || 'cycling_gravel' || 'cycling_mtb' => (45, 400),
  'swimming' => (500, 2400),
  'indoor_rowing' => (180, 500),
  _ => (45, 1500),
};

bool _plausible(int seconds, double? distanceKm, String? sport) {
  if (distanceKm == null || distanceKm <= 0) return true;
  final perKm = seconds / distanceKm;
  final (fastest, slowest) = _paceRange(sport);
  return perKm >= fastest && perKm <= slowest;
}

/// The time in seconds, or null when [input] is not a usable time.
int? parseTargetTime(String? input, {double? distanceKm, String? sport}) {
  final text = input?.trim().toLowerCase().replaceAll(',', '.') ?? '';
  if (text.isEmpty) return null;

  final hm = RegExp(
    r'^(\d{1,3})\s*h\s*(?:(\d{1,2})\s*(?:m|min)?)?\s*$',
  ).firstMatch(text);
  if (hm != null) {
    final minutes = int.tryParse(hm.group(2) ?? '0') ?? 0;
    if (minutes >= 60) return null;
    return _check(
      int.parse(hm.group(1)!) * 3600 + minutes * 60,
      distanceKm,
      sport,
    );
  }

  if (RegExp(r'^\d{1,4}$').hasMatch(text)) {
    return _check(int.parse(text) * 60, distanceKm, sport);
  }

  final parts = text.split(':');
  if (parts.length < 2 ||
      parts.length > 3 ||
      parts.any((p) => !RegExp(r'^\d{1,3}$').hasMatch(p))) {
    return null;
  }
  final n = parts.map(int.parse).toList();
  if (parts.length == 3) {
    if (n[1] >= 60 || n[2] >= 60) return null;
    return _check(n[0] * 3600 + n[1] * 60 + n[2], distanceKm, sport);
  }
  if (n[1] >= 60) return null;
  final hoursAndMinutes = n[0] * 3600 + n[1] * 60;
  if (_plausible(hoursAndMinutes, distanceKm, sport)) {
    return _check(hoursAndMinutes, distanceKm, sport);
  }
  return _check(n[0] * 60 + n[1], distanceKm, sport);
}

int? _check(int seconds, double? distanceKm, String? sport) =>
    seconds > 0 &&
        seconds <= 100 * 3600 &&
        _plausible(seconds, distanceKm, sport)
    ? seconds
    : null;

/// `3:30:00`, or `45:00` below an hour.
String formatTargetTime(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// `4:59/km` for [secondsPerKm].
String formatPace(double secondsPerKm) {
  final total = secondsPerKm.round();
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}/km';
}
