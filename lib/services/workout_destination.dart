/// The watch platform a planned workout goes to.
///
/// Only Garmin can receive a workout from Fjelia today. COROS, Polar and
/// Suunto accept structured workouts from partners (COROS Training API,
/// Polar's partner integrations, Suunto's Guides API), which need a
/// partnership agreement with each; without it Fjelia hands the athlete the
/// workout as text, with the same targets, to enter in that platform's app.
///
/// COROS is the exception, by an unofficial route: the COROS Training Hub
/// takes a workout from the same web interface its own page uses. The athlete
/// turns that on knowingly (Settings, Training); it can break without notice.
enum WorkoutDestination {
  garmin('Garmin', 'garmin_api', true),
  coros('COROS', 'coros', false),
  polar('Polar', 'polar', false),
  suunto('Suunto', 'suunto', false);

  const WorkoutDestination(this.label, this.sourceKey, this.canPush);

  /// Name shown to the athlete.
  final String label;

  /// The key of this platform in the source-priority lists.
  final String sourceKey;

  /// Fjelia can send the workout straight to the watch's calendar.
  final bool canPush;

  /// Why a direct push is not offered, for the athlete.
  String? get unavailableNote => canPush
      ? null
      : 'Sending workouts straight to $label needs $label\'s partner access. '
            'Until then, share the workout and enter it in the $label app: '
            'the text carries every step with its heart-rate zone.'
            '${this == coros ? ' Or turn on the experimental COROS route in Settings, Training.' : ''}';
}

/// The platform workouts go to: the first of [priority] (the athlete's order
/// of activity sources) that is in [connected]. With none connected it is
/// Garmin, where workouts always went.
WorkoutDestination pickWorkoutDestination(
  List<String> priority,
  Set<String> connected,
) {
  for (final key in priority) {
    for (final d in WorkoutDestination.values) {
      if (d.sourceKey == key && connected.contains(key)) return d;
    }
  }
  return WorkoutDestination.garmin;
}

/// Every watch platform the athlete has connected, in their order of sources.
/// With none connected it is Garmin alone, where workouts always went.
List<WorkoutDestination> connectedWorkoutDestinations(
  List<String> priority,
  Set<String> connected,
) {
  final out = <WorkoutDestination>[];
  for (final key in priority) {
    for (final d in WorkoutDestination.values) {
      if (d.sourceKey == key && connected.contains(key) && !out.contains(d)) {
        out.add(d);
      }
    }
  }
  return out.isEmpty ? const [WorkoutDestination.garmin] : out;
}
