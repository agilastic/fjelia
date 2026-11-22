/// A rough load of one session for spacing hard and long days:
/// minutes × intensity × how hard the sport is on the legs. Not a training
/// load model (that is TRIMP); only enough to tell a long easy ride from a
/// long trail run before the session exists (docs/training-plan-rethink.md,
/// §3 #5).
double sessionStress({
  required String sport,
  required int minutes,
  required int zone,
}) => minutes * _intensity(zone) * sportImpact(sport);

/// A day this heavy on its own (3 h on a trail, 150 min of running, an
/// event) is a load day even in zone 2.
const heavyDayStress = 150.0;

/// A key session next to a heavy day is too much when the two days together
/// reach this: 60 min of VO₂max running (210) the day before 3 h on a trail
/// (234) is, 60 min of bike intervals (126) before 150 min of easy riding
/// (90) is not, and a hard day followed by an easy one never is.
const heavyPairStress = 300.0;

/// Whether a key session with [keyStress] next to a day with [neighbour]
/// load makes a pair of days too heavy.
/// [margin] below 1 judges more strictly: the planner decides before the
/// workout and its exact length exist.
bool heavyPair(double keyStress, double neighbour, {double margin = 1}) =>
    neighbour >= heavyDayStress * margin &&
    keyStress + neighbour >= heavyPairStress * margin;

double _intensity(int zone) => switch (zone) {
  <= 1 => 0.6,
  2 => 1.0,
  3 => 1.5,
  4 => 2.5,
  _ => 3.5,
};

/// Muscular impact per minute against road running: trail running with its
/// climbing and descents more, the bike and the pool much less.
double sportImpact(String sport) => switch (sport) {
  'trail_running' => 1.3,
  'running' || 'treadmill_running' => 1.0,
  'hiking' => 0.7,
  'indoor_rowing' || 'nordic_skiing' => 0.7,
  'strength' => 0.8,
  'swimming' => 0.4,
  _ when sport.startsWith('cycl') || sport.contains('cycling') => 0.6,
  _ => 0.8,
};
