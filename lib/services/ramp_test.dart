/// The DFA alpha1 ramp test the plan schedules every few weeks.
///
/// alpha1 reads the thresholds only from a session that builds from easy to
/// hard (see `rampWindows`): a warm-up, then short stages that rise step by
/// step to just above LT2, then a cool-down. The plan builds exactly that.
library;

/// The sub type that marks a planned ramp test.
const rampTestSubType = 'dfaRamp';

const rampTestTitle = 'Ramp test (DFA α1)';

/// A test at most this often; a progression the athlete ran on their own
/// counts as one.
const rampTestEvery = Duration(days: 28);

const rampTestDescription =
    'Ramp test for the aerobic and anaerobic threshold from DFA alpha1. '
    'Chest strap required: optical sensors do not record beat-to-beat data.';

const rampTestCues =
    'Moisten the chest strap. Nothing hard the day before. Run each stage '
    'evenly and get faster only at the next one (on a treadmill about '
    '+0.5 km/h, incline 1 %). End the stages when it gets hard, then cool '
    'down.';

const _stageSeconds = 180;
const _warmSeconds = 600;
const _coolSeconds = 600;

/// Warm-up, 6 to 12 stages of three minutes and a cool-down.
///
/// With [power] the stages rise from 50 % to 105 % of FTP; otherwise they
/// are heart-rate stages from 20 bpm below [lt1] to 5 above [lt2], each
/// with a fixed target of ±2 bpm that the zones do not overwrite.
/// [zoneOf] gives a heart rate's zone, for the load estimate.
List<Map<String, dynamic>> rampTestSteps({
  required int lt1,
  required int lt2,
  required int Function(int hr) zoneOf,
  bool power = false,
}) {
  final top = lt2 + 5;
  final bottom = lt1 - 20 > top - 25 ? top - 25 : lt1 - 20;
  final count = (((top - bottom) / 5).round() + 1).clamp(6, 12);
  Map<String, dynamic> time(String key, int id, int seconds) => {
    'type': 'ExecutableStepDTO',
    'stepType': {'stepTypeId': id, 'stepTypeKey': key},
    'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
    'endConditionValue': seconds,
  };
  return [
    {
      ...time('warmup', 1, _warmSeconds),
      'targetType': {
        'workoutTargetTypeId': 4,
        'workoutTargetTypeKey': 'heart.rate.zone',
      },
      'zoneNumber': 1,
    },
    for (var i = 0; i < count; i++)
      if (power)
        {
          ...time('interval', 3, _stageSeconds),
          'targetType': {
            'workoutTargetTypeId': 2,
            'workoutTargetTypeKey': 'power.zone',
          },
          'ftpFraction': 0.5 + 0.55 * i / (count - 1),
          'description': 'Stage ${i + 1} of $count',
        }
      else
        () {
          final hr = (bottom + (top - bottom) * i / (count - 1)).round();
          return {
            ...time('interval', 3, _stageSeconds),
            'targetType': {
              'workoutTargetTypeId': 4,
              'workoutTargetTypeKey': 'heart.rate.zone',
            },
            'targetValueOne': (hr - 2).toDouble(),
            'targetValueTwo': (hr + 2).toDouble(),
            'zoneNumber': zoneOf(hr),
            'fixedTarget': true,
            'description': 'Stage ${i + 1} of $count: HR $hr bpm',
          };
        }(),
    {
      ...time('cooldown', 2, _coolSeconds),
      'targetType': {
        'workoutTargetTypeId': 4,
        'workoutTargetTypeKey': 'heart.rate.zone',
      },
      'zoneNumber': 1,
    },
  ];
}
