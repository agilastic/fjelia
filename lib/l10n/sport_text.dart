import 'app_localizations.dart';

/// The sports a done activity can be changed to, by family: outdoor first,
/// then indoor and virtual. The keys are the ones the syncs store.
const activitySportChoices = [
  ['running', 'trail_running', 'treadmill_running', 'virtual_run'],
  [
    'cycling',
    'mountain_biking',
    'gravel_cycling',
    'indoor_cycling',
    'virtual_ride',
  ],
  ['lap_swimming', 'open_water_swimming'],
  ['rowing', 'indoor_rowing'],
  ['hiking', 'walking', 'cross_country_skiing'],
  ['elliptical', 'stair_climbing', 'strength_training', 'yoga'],
];

/// An activity's sport in the app language; an unknown key reads as words.
String activitySportLabel(AppLocalizations l, String type) => switch (type) {
  'running' => l.running,
  'trail_running' => l.trailRunning,
  'treadmill_running' => l.manualTreadmill,
  'virtual_run' => l.sportVirtualRun,
  'cycling' || 'road_biking' => l.cycling,
  'mountain_biking' => l.sportMountainBike,
  'gravel_cycling' || 'cycling_gravel' => '${l.cycling} · ${l.gravel}',
  'indoor_cycling' => l.sportIndoorCycling,
  'virtual_ride' => l.sportVirtualRide,
  'lap_swimming' || 'swimming' => '${l.swimming} · ${l.pool}',
  'open_water_swimming' => '${l.swimming} · ${l.openWater}',
  'rowing' => l.rowing,
  'indoor_rowing' => l.indoorRowing,
  'hiking' => l.hiking,
  'walking' => l.walking,
  'cross_country_skiing' || 'cross_country_skiing_ws' => l.nordicClassic,
  'elliptical' => l.sportElliptical,
  'stair_climbing' => l.sportStairClimber,
  'strength_training' => l.strengthTraining,
  'yoga' => l.yoga,
  _ =>
    type
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' '),
};
