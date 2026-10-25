/// The watch platforms Fjelia knows by name: the label shown to the athlete
/// and the key of the platform in the source-priority lists. A catalogue for
/// the providers that exist today; a platform added later needs no entry
/// here, a provider carries its own label and key.
///
/// Only Garmin takes a workout from Fjelia officially. COROS, Polar and Suunto
/// accept structured workouts from partners, which needs an agreement with
/// each; without it Fjelia hands the athlete the workout as text, with the
/// same targets. COROS is the exception, by an unofficial route the athlete
/// turns on knowingly (Settings, Training); it can break without notice.
enum WorkoutDestination {
  garmin('Garmin', 'garmin_api'),
  coros('COROS', 'coros'),
  polar('Polar', 'polar'),
  suunto('Suunto', 'suunto');

  const WorkoutDestination(this.label, this.sourceKey);

  /// Name shown to the athlete.
  final String label;

  /// The key of this platform in the source-priority lists.
  final String sourceKey;
}
