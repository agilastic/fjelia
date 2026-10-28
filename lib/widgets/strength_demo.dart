import '../l10n/l10n_ext.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/activity_colors.dart';
import 'app_widgets.dart';

/// Simplified, looping figure demonstrations of the built-in exercises.
///
/// Drawn in code, not bundled media: a side-view stick figure is posed by
/// its hip, torso angle and the targets of its hands and feet; elbows and
/// knees follow by two-bone inverse kinematics, so a hand on the floor or a
/// bar stays there. Poses ease into each other with short holds. Units are
/// "figure units": standing height ≈ 1, the floor at y = 0, y pointing down,
/// the figure facing right.

// ── Rig ───────────────────────────────────────────────────────────────────

const _thigh = .24, _shin = .24, _torso = .30, _neck = .045, _headR = .055;
const _upperArm = .17, _forearm = .16;

enum _From { world, shoulder, hip }

class _Pose {
  const _Pose({
    required this.hip,
    required this.torso,
    required this.foot,
    Offset? farFoot,
    required this.hand,
    Offset? farHand,
    this.from = _From.world,
    this.farFrom,
  }) : farFoot = farFoot ?? foot,
       farHand = farHand ?? hand;

  final Offset hip;

  /// Direction from hip to shoulder, degrees; −90 is upright.
  final double torso;
  final Offset foot, farFoot, hand, farHand;

  /// What the hand targets are relative to.
  final _From from;
  final _From? farFrom;

  _Pose lerp(_Pose b, double t) => _Pose(
    hip: Offset.lerp(hip, b.hip, t)!,
    torso: torso + (b.torso - torso) * t,
    foot: Offset.lerp(foot, b.foot, t)!,
    farFoot: Offset.lerp(farFoot, b.farFoot, t)!,
    hand: Offset.lerp(hand, b.hand, t)!,
    farHand: Offset.lerp(farHand, b.farHand, t)!,
    from: from,
    farFrom: farFrom,
  );
}

class _Key {
  const _Key(this.pose, {this.hold = .35, this.move = 1.0});
  final _Pose pose;

  /// Seconds held at this pose, then seconds to reach the next one.
  final double hold, move;
}

enum _Prop { none, barbell, curlBar, dumbbells, dumbbell, goblet }

/// Fixed equipment drawn behind the figure.
class _Scene {
  const _Scene({
    this.bench,
    this.pullBar,
    this.bandAnchor,
    this.sled = false,
    this.seat,
  });
  final Rect? bench, seat;
  final double? pullBar;
  final Offset? bandAnchor;

  /// A leg-press platform at the feet.
  final bool sled;
}

/// One exercise's demonstration.
class _Demo {
  const _Demo({
    required this.keys,
    required this.cue,
    this.prop = _Prop.none,
    this.scene = const _Scene(),
    this.knee = -1,
    this.elbow = 1,
    this.farElbow,
    this.farKnee,
    this.view = const Rect.fromLTRB(-.6, -1.0, .6, .05),
    this.still = 1,
  });
  final List<_Key> keys;

  /// One line on how to move.
  final String cue;
  final _Prop prop;
  final _Scene scene;

  /// Bend directions (±1) for knees and elbows.
  final double knee, elbow;
  final double? farElbow, farKnee;
  final Rect view;

  /// The key pose shown when motion is reduced.
  final int still;

  double get period => keys.fold(0.0, (sum, k) => sum + k.hold + k.move);

  /// The pose at [seconds] into the loop.
  _Pose poseAt(double seconds) {
    var t = seconds % period;
    for (var i = 0; i < keys.length; i++) {
      final k = keys[i];
      if (t < k.hold) return k.pose;
      t -= k.hold;
      if (t < k.move) {
        final next = keys[(i + 1) % keys.length].pose;
        return k.pose.lerp(next, Curves.easeInOut.transform(t / k.move));
      }
      t -= k.move;
    }
    return keys.first.pose;
  }
}

Offset _dir(double degrees) {
  final r = degrees * math.pi / 180;
  return Offset(math.cos(r), math.sin(r));
}

/// Two-bone chain from [a] towards [target]: the middle joint and the end.
/// [bend] (±1) chooses the side the joint bends to.
(Offset, Offset) _chain(
  Offset a,
  Offset target,
  double l1,
  double l2,
  double bend,
) {
  final d = target - a;
  final dir = d.distance < 1e-9 ? const Offset(0, 1) : d / d.distance;
  final dist = d.distance.clamp((l1 - l2).abs() + 1e-6, l1 + l2 - 1e-6);
  final cosA = ((l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist)).clamp(
    -1.0,
    1.0,
  );
  final ang = math.acos(cosA) * bend;
  final c = math.cos(ang), s = math.sin(ang);
  final joint =
      a + Offset(dir.dx * c - dir.dy * s, dir.dx * s + dir.dy * c) * l1;
  final rest = target - joint;
  final end = rest.distance < 1e-9
      ? joint + dir * l2
      : joint + rest / rest.distance * l2;
  return (joint, end);
}

/// Joint positions of a pose.
class _Body {
  factory _Body(_Demo demo, _Pose p) {
    final hip = p.hip;
    final shoulder = hip + _dir(p.torso) * _torso;
    Offset target(Offset v, _From from) => switch (from) {
      _From.world => v,
      _From.shoulder => shoulder + v,
      _From.hip => hip + v,
    };
    final (knee, ankle) = _chain(hip, p.foot, _thigh, _shin, demo.knee);
    final (farKnee, farAnkle) = _chain(
      hip,
      p.farFoot,
      _thigh,
      _shin,
      demo.farKnee ?? demo.knee,
    );
    final (elbow, hand) = _chain(
      shoulder,
      target(p.hand, p.from),
      _upperArm,
      _forearm,
      demo.elbow,
    );
    final (farElbow, farHand) = _chain(
      shoulder,
      target(p.farHand, p.farFrom ?? p.from),
      _upperArm,
      _forearm,
      demo.farElbow ?? demo.elbow,
    );
    return _Body._(
      hip: hip,
      shoulder: shoulder,
      head: shoulder + _dir(p.torso) * (_neck + _headR),
      knee: knee,
      ankle: ankle,
      farKnee: farKnee,
      farAnkle: farAnkle,
      elbow: elbow,
      hand: hand,
      farElbow: farElbow,
      farHand: farHand,
    );
  }
  _Body._({
    required this.hip,
    required this.shoulder,
    required this.head,
    required this.knee,
    required this.ankle,
    required this.farKnee,
    required this.farAnkle,
    required this.elbow,
    required this.hand,
    required this.farElbow,
    required this.farHand,
  });
  final Offset hip, shoulder, head, knee, ankle, farKnee, farAnkle;
  final Offset elbow, hand, farElbow, farHand;
}

// ── Exercises ─────────────────────────────────────────────────────────────

const _stand = Offset(.03, 0);
const _standHip = Offset(-.01, -.47);
const _floorView = Rect.fromLTRB(-.68, -.7, .68, .05);

/// Demonstrations by built-in exercise id.
final Map<String, _Demo> _demos = {
  'back_squat': _Demo(
    cue: 'Bar on the upper back. Hips back and down, chest up, drive up.',
    prop: _Prop.barbell,
    elbow: -1,
    keys: const [
      _Key(
        _Pose(
          hip: _standHip,
          torso: -87,
          foot: _stand,
          hand: Offset(-.06, .01),
          from: _From.shoulder,
        ),
        hold: .5,
        move: 1.2,
      ),
      _Key(
        _Pose(
          hip: Offset(-.19, -.25),
          torso: -50,
          foot: _stand,
          hand: Offset(-.06, .01),
          from: _From.shoulder,
        ),
        hold: .2,
        move: 1.0,
      ),
    ],
  ),
  'front_squat': _Demo(
    cue: 'Bar on the front of the shoulders, elbows high, torso upright.',
    prop: _Prop.barbell,
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(.07, -.01),
          from: _From.shoulder,
        ),
        hold: .5,
        move: 1.2,
      ),
      _Key(
        _Pose(
          hip: Offset(-.14, -.24),
          torso: -68,
          foot: _stand,
          hand: Offset(.07, -.01),
          from: _From.shoulder,
        ),
        hold: .2,
        move: 1.0,
      ),
    ],
  ),
  'goblet_squat': _Demo(
    cue: 'Hold the weight at the chest. Sit between the heels, stand tall.',
    prop: _Prop.goblet,
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(.09, .09),
          from: _From.shoulder,
        ),
        hold: .5,
        move: 1.2,
      ),
      _Key(
        _Pose(
          hip: Offset(-.14, -.23),
          torso: -64,
          foot: _stand,
          hand: Offset(.09, .09),
          from: _From.shoulder,
        ),
        hold: .2,
        move: 1.0,
      ),
    ],
  ),
  'leg_press': _Demo(
    cue: 'Lower the platform with control, press through the whole foot.',
    scene: const _Scene(
      sled: true,
      seat: Rect.fromLTRB(-.55, -.24, -.12, -.18),
    ),
    knee: -1,
    elbow: 1,
    view: const Rect.fromLTRB(-.7, -.8, .5, .05),
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.22, -.24),
          torso: -152,
          foot: Offset(.17, -.5),
          hand: Offset(-.16, -.2),
        ),
        hold: .4,
        move: 1.1,
      ),
      _Key(
        _Pose(
          hip: Offset(-.22, -.24),
          torso: -152,
          foot: Offset(.02, -.38),
          hand: Offset(-.16, -.2),
        ),
        hold: .2,
        move: 1.0,
      ),
    ],
  ),
  'deadlift': _Demo(
    cue: 'Bar over mid-foot, back flat. Push the floor away, hips through.',
    prop: _Prop.barbell,
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.15, -.31),
          torso: -28,
          foot: _stand,
          hand: Offset(.05, -.11),
        ),
        hold: .4,
        move: 1.2,
      ),
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(.02, -.44),
        ),
        hold: .5,
        move: 1.1,
      ),
    ],
  ),
  'romanian_deadlift': _Demo(
    cue: 'Soft knees. Push the hips back until the hamstrings stretch.',
    prop: _Prop.barbell,
    elbow: 1,
    still: 1,
    keys: const [
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(.02, -.44),
        ),
        hold: .4,
        move: 1.3,
      ),
      _Key(
        _Pose(
          hip: Offset(-.13, -.44),
          torso: -16,
          foot: _stand,
          hand: Offset(.16, -.2),
        ),
        hold: .25,
        move: 1.1,
      ),
    ],
  ),
  'bench_press': _bench(
    _Prop.barbell,
    'Lower the bar to the chest, press it back up over the shoulders.',
  ),
  'db_bench_press': _bench(
    _Prop.dumbbells,
    'Lower the dumbbells beside the chest, press them up together.',
  ),
  'overhead_press': _Demo(
    cue: 'Brace, press the bar straight up, head through at the top.',
    prop: _Prop.barbell,
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(.07, -.02),
          from: _From.shoulder,
        ),
        hold: .35,
        move: 1.0,
      ),
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(.01, -.29),
          from: _From.shoulder,
        ),
        hold: .4,
        move: 1.1,
      ),
    ],
  ),
  'barbell_row': _Demo(
    cue: 'Hinge forward, flat back. Pull the bar to the lower ribs.',
    prop: _Prop.barbell,
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.13, -.43),
          torso: -20,
          foot: _stand,
          hand: Offset(.16, -.21),
        ),
        hold: .3,
        move: .8,
      ),
      _Key(
        _Pose(
          hip: Offset(-.13, -.43),
          torso: -20,
          foot: _stand,
          hand: Offset(.05, -.41),
        ),
        hold: .35,
        move: 1.0,
      ),
    ],
  ),
  'db_row': _Demo(
    cue: 'Support on the bench. Pull the dumbbell to the hip, lower slowly.',
    prop: _Prop.dumbbell,
    scene: const _Scene(bench: Rect.fromLTRB(.1, -.3, .55, -.25)),
    elbow: 1,
    farElbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.08, -.43),
          torso: -8,
          foot: Offset(-.2, 0),
          farFoot: Offset(.02, 0),
          hand: Offset(.2, -.17),
          farHand: Offset(.36, -.3),
        ),
        hold: .3,
        move: .8,
      ),
      _Key(
        _Pose(
          hip: Offset(-.08, -.43),
          torso: -8,
          foot: Offset(-.2, 0),
          farFoot: Offset(.02, 0),
          hand: Offset(.08, -.38),
          farHand: Offset(.36, -.3),
        ),
        hold: .35,
        move: 1.0,
      ),
    ],
  ),
  'pull_up': _Demo(
    cue: 'Hang long. Pull the chest to the bar, lower all the way.',
    scene: const _Scene(pullBar: -1.17),
    knee: 1,
    elbow: -1,
    view: const Rect.fromLTRB(-.6, -1.25, .6, .02),
    keys: const [
      _Key(
        _Pose(
          hip: Offset(0, -.54),
          torso: -90,
          foot: Offset(-.06, -.08),
          hand: Offset(.02, -1.17),
        ),
        hold: .35,
        move: 1.1,
      ),
      _Key(
        _Pose(
          hip: Offset(0, -.79),
          torso: -90,
          foot: Offset(-.06, -.33),
          hand: Offset(.02, -1.17),
        ),
        hold: .3,
        move: 1.1,
      ),
    ],
  ),
  'push_up': _Demo(
    cue: 'Body in one line. Lower the chest between the hands, press up.',
    knee: -1,
    elbow: 1,
    view: _floorView,
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.08, -.2),
          torso: -26,
          foot: Offset(-.52, 0),
          hand: Offset(.22, 0),
        ),
        hold: .3,
        move: 1.0,
      ),
      _Key(
        _Pose(
          hip: Offset(-.05, -.09),
          torso: -10,
          foot: Offset(-.52, 0),
          hand: Offset(.22, 0),
        ),
        hold: .2,
        move: .9,
      ),
    ],
  ),
  'walking_lunge': _Demo(
    cue: 'Long step, lower the back knee towards the floor, torso tall.',
    prop: _Prop.dumbbells,
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.02, -.44),
          torso: -88,
          foot: Offset(.2, 0),
          farFoot: Offset(-.24, 0),
          hand: Offset(.01, .32),
          from: _From.shoulder,
        ),
        hold: .35,
        move: 1.0,
      ),
      _Key(
        _Pose(
          hip: Offset(-.02, -.26),
          torso: -88,
          foot: Offset(.2, 0),
          farFoot: Offset(-.24, 0),
          hand: Offset(.01, .32),
          from: _From.shoulder,
        ),
        hold: .2,
        move: 1.0,
      ),
    ],
  ),
  'split_squat': _Demo(
    cue: 'Rear foot on the bench. Lower straight down on the front leg.',
    prop: _Prop.dumbbells,
    scene: const _Scene(bench: Rect.fromLTRB(-.6, -.24, -.32, -.19)),
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.06, -.42),
          torso: -86,
          foot: Offset(.16, 0),
          farFoot: Offset(-.38, -.24),
          hand: Offset(.01, .32),
          from: _From.shoulder,
        ),
        hold: .35,
        move: 1.0,
      ),
      _Key(
        _Pose(
          hip: Offset(-.08, -.24),
          torso: -82,
          foot: Offset(.16, 0),
          farFoot: Offset(-.38, -.24),
          hand: Offset(.01, .32),
          from: _From.shoulder,
        ),
        hold: .2,
        move: 1.0,
      ),
    ],
  ),
  'calf_raise': _Demo(
    cue: 'Rise onto the balls of the feet, pause, lower the heels slowly.',
    prop: _Prop.barbell,
    elbow: -1,
    keys: const [
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(-.06, .01),
          from: _From.shoulder,
        ),
        hold: .35,
        move: .7,
      ),
      _Key(
        _Pose(
          hip: Offset(-.01, -.54),
          torso: -88,
          foot: Offset(.03, -.07),
          hand: Offset(-.06, .01),
          from: _From.shoulder,
        ),
        hold: .5,
        move: .9,
      ),
    ],
  ),
  'barbell_curl': _Demo(
    cue: 'Elbows at the sides. Curl the bar up, lower it under control.',
    prop: _Prop.curlBar,
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(.02, .32),
          from: _From.shoulder,
        ),
        hold: .3,
        move: .9,
      ),
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(.08, .03),
          from: _From.shoulder,
        ),
        hold: .35,
        move: 1.1,
      ),
    ],
  ),
  'hip_thrust': _Demo(
    cue: 'Upper back on the bench. Drive the hips up, squeeze, lower.',
    prop: _Prop.barbell,
    scene: const _Scene(bench: Rect.fromLTRB(-.62, -.24, -.24, -.19)),
    knee: -1,
    elbow: 1,
    view: _floorView,
    keys: const [
      _Key(
        _Pose(
          hip: Offset(0, -.1),
          torso: -148,
          foot: Offset(.27, 0),
          hand: Offset(.0, -.07),
          from: _From.hip,
        ),
        hold: .25,
        move: 1.0,
      ),
      _Key(
        _Pose(
          hip: Offset(.04, -.3),
          torso: -188,
          foot: Offset(.27, 0),
          hand: Offset(.0, -.07),
          from: _From.hip,
        ),
        hold: .5,
        move: 1.0,
      ),
    ],
  ),
  'plank': _Demo(
    cue: 'Forearms down, body in one straight line, breathe steadily.',
    knee: -1,
    elbow: 1,
    view: _floorView,
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.08, -.11),
          torso: -13,
          foot: Offset(-.55, 0),
          hand: Offset(.34, 0),
        ),
        hold: .8,
        move: 1.4,
      ),
      _Key(
        _Pose(
          hip: Offset(-.08, -.125),
          torso: -14.5,
          foot: Offset(-.55, 0),
          hand: Offset(.34, 0),
        ),
        hold: .8,
        move: 1.4,
      ),
    ],
  ),
  'side_plank': _Demo(
    cue: 'On one forearm, lift the hips into a straight line, hold.',
    knee: -1,
    elbow: 1,
    farElbow: 1,
    view: _floorView,
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.08, -.04),
          torso: -5,
          foot: Offset(-.55, 0),
          hand: Offset(.34, 0),
          farHand: Offset(.0, -.28),
          farFrom: _From.shoulder,
        ),
        hold: .3,
        move: 1.0,
      ),
      _Key(
        _Pose(
          hip: Offset(-.08, -.11),
          torso: -13,
          foot: Offset(-.55, 0),
          hand: Offset(.34, 0),
          farHand: Offset(.0, -.28),
          farFrom: _From.shoulder,
        ),
        hold: 1.2,
        move: 1.0,
      ),
    ],
  ),
  'dead_bug': _Demo(
    cue: 'Back flat on the floor. Reach one arm back as the opposite leg extends.',
    knee: 1,
    farKnee: 1,
    elbow: 1,
    view: _floorView,
    keys: const [
      _Key(_deadBugStart, hold: .3, move: 1.0),
      _Key(
        _Pose(
          hip: Offset(-.05, -.06),
          torso: 0,
          foot: Offset(-.29, -.3),
          farFoot: Offset(-.5, -.1),
          hand: Offset(.58, -.1),
          farHand: Offset(.25, -.35),
        ),
        hold: .3,
        move: 1.0,
      ),
      _Key(_deadBugStart, hold: .3, move: 1.0),
      _Key(
        _Pose(
          hip: Offset(-.05, -.06),
          torso: 0,
          foot: Offset(-.5, -.1),
          farFoot: Offset(-.29, -.3),
          hand: Offset(.25, -.35),
          farHand: Offset(.58, -.1),
        ),
        hold: .3,
        move: 1.0,
      ),
    ],
  ),
  'bird_dog': _Demo(
    cue: 'On hands and knees. Reach one arm forward and the opposite leg back.',
    knee: -1,
    farKnee: -1,
    elbow: 1,
    view: _floorView,
    keys: const [
      _Key(_birdDogStart, hold: .3, move: 1.0),
      _Key(
        _Pose(
          hip: Offset(-.06, -.25),
          torso: -12,
          foot: Offset(-.3, -.02),
          farFoot: Offset(-.54, -.29),
          hand: Offset(.56, -.3),
          farHand: Offset(.24, 0),
        ),
        hold: .5,
        move: 1.0,
      ),
      _Key(_birdDogStart, hold: .3, move: 1.0),
      _Key(
        _Pose(
          hip: Offset(-.06, -.25),
          torso: -12,
          foot: Offset(-.54, -.29),
          farFoot: Offset(-.3, -.02),
          hand: Offset(.24, 0),
          farHand: Offset(.56, -.3),
        ),
        hold: .5,
        move: 1.0,
      ),
    ],
  ),
  'step_up': _Demo(
    cue: 'Whole foot on the box. Drive up through the front leg, step down slowly.',
    prop: _Prop.dumbbells,
    scene: const _Scene(bench: Rect.fromLTRB(.04, -.22, .36, -.17)),
    elbow: 1,
    view: const Rect.fromLTRB(-.6, -1.2, .6, .05),
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.09, -.44),
          torso: -86,
          foot: Offset(.13, -.22),
          farFoot: Offset(-.12, 0),
          hand: Offset(.01, .32),
          from: _From.shoulder,
        ),
        hold: .35,
        move: 1.0,
      ),
      _Key(
        _Pose(
          hip: Offset(.1, -.68),
          torso: -88,
          foot: Offset(.13, -.22),
          farFoot: Offset(.03, -.34),
          hand: Offset(.01, .32),
          from: _From.shoulder,
        ),
        hold: .4,
        move: 1.1,
      ),
    ],
  ),
  'single_leg_rdl': _Demo(
    cue: 'Stand on one leg. Hinge forward as the free leg reaches back, back flat.',
    prop: _Prop.dumbbell,
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          farFoot: Offset(-.02, -.02),
          hand: Offset(.01, .32),
          from: _From.shoulder,
        ),
        hold: .35,
        move: 1.3,
      ),
      _Key(
        _Pose(
          hip: Offset(-.06, -.45),
          torso: -12,
          foot: _stand,
          farFoot: Offset(-.5, -.4),
          hand: Offset(.01, .32),
          from: _From.shoulder,
        ),
        hold: .35,
        move: 1.1,
      ),
    ],
  ),
  'step_down': _Demo(
    cue:
        'Stand on the box. Lower the free heel to the floor over four seconds.',
    prop: _Prop.dumbbells,
    scene: const _Scene(bench: Rect.fromLTRB(-.16, -.22, .14, -.17)),
    elbow: 1,
    view: const Rect.fromLTRB(-.65, -1.25, .65, .05),
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.02, -.68),
          torso: -88,
          foot: Offset(.0, -.22),
          farFoot: Offset(.12, -.3),
          hand: Offset(.01, .32),
          from: _From.shoulder,
        ),
        hold: .35,
        move: 2.4,
      ),
      _Key(
        _Pose(
          hip: Offset(-.08, -.5),
          torso: -76,
          foot: Offset(.0, -.22),
          farFoot: Offset(.3, -.01),
          hand: Offset(.01, .32),
          from: _From.shoulder,
        ),
        hold: .15,
        move: .8,
      ),
    ],
  ),
  'leg_curl': _Demo(
    cue: 'Seated, pad above the heels. Curl the heels under the seat, return slowly.',
    scene: const _Scene(seat: Rect.fromLTRB(-.36, -.24, .1, -.19)),
    knee: -1,
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.12, -.28),
          torso: -96,
          foot: Offset(.15, -.04),
          hand: Offset(-.02, -.26),
        ),
        hold: .3,
        move: .9,
      ),
      _Key(
        _Pose(
          hip: Offset(-.12, -.28),
          torso: -96,
          foot: Offset(-.02, -.08),
          hand: Offset(-.02, -.26),
        ),
        hold: .35,
        move: 1.2,
      ),
    ],
  ),
  'lat_pulldown': _Demo(
    cue: 'Seated, chest up. Pull the bar to the upper chest, let it rise under control.',
    scene: const _Scene(
      seat: Rect.fromLTRB(-.34, -.24, .06, -.19),
      bandAnchor: Offset(-.04, -1.05),
    ),
    knee: -1,
    elbow: 1,
    view: const Rect.fromLTRB(-.6, -1.12, .6, .04),
    keys: const [
      _Key(
        _Pose(
          hip: Offset(-.12, -.27),
          torso: -98,
          foot: Offset(.18, 0),
          hand: Offset(-.06, -.92),
        ),
        hold: .3,
        move: .9,
      ),
      _Key(
        _Pose(
          hip: Offset(-.12, -.27),
          torso: -104,
          foot: Offset(.18, 0),
          hand: Offset(.02, -.58),
        ),
        hold: .35,
        move: 1.1,
      ),
    ],
  ),
  'jump_squat': _Demo(
    cue: 'Quarter squat, then jump as high as you can. Land softly and reset.',
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(.02, .32),
          from: _From.shoulder,
        ),
        hold: .4,
        move: .6,
      ),
      _Key(
        _Pose(
          hip: Offset(-.13, -.32),
          torso: -58,
          foot: _stand,
          hand: Offset(-.12, .26),
          from: _From.shoulder,
        ),
        hold: .05,
        move: .25,
      ),
      _Key(
        _Pose(
          hip: Offset(.0, -.6),
          torso: -90,
          foot: Offset(.04, -.11),
          hand: Offset(.18, -.22),
          from: _From.shoulder,
        ),
        hold: .05,
        move: .35,
      ),
      _Key(
        _Pose(
          hip: Offset(-.1, -.38),
          torso: -66,
          foot: _stand,
          hand: Offset(.14, .2),
          from: _From.shoulder,
        ),
        hold: .25,
        move: .6,
      ),
    ],
  ),
  'pallof_press': _Demo(
    cue: 'Side-on to the band. Press the hands straight out and resist the turn.',
    scene: const _Scene(bandAnchor: Offset(-.58, -.66)),
    elbow: 1,
    keys: const [
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(.06, .13),
          from: _From.shoulder,
        ),
        hold: .3,
        move: .9,
      ),
      _Key(
        _Pose(
          hip: _standHip,
          torso: -88,
          foot: _stand,
          hand: Offset(.28, .12),
          from: _From.shoulder,
        ),
        hold: .7,
        move: .9,
      ),
    ],
  ),
};

const _deadBugStart = _Pose(
  hip: Offset(-.05, -.06),
  torso: 0,
  foot: Offset(-.29, -.3),
  hand: Offset(.25, -.35),
);

const _birdDogStart = _Pose(
  hip: Offset(-.06, -.25),
  torso: -12,
  foot: Offset(-.3, -.02),
  hand: Offset(.24, 0),
);

_Demo _bench(_Prop prop, String cue) => _Demo(
  cue: cue,
  prop: prop,
  scene: const _Scene(bench: Rect.fromLTRB(-.45, -.24, .32, -.19)),
  knee: 1,
  elbow: 1,
  view: _floorView,
  keys: const [
    _Key(
      _Pose(
        hip: Offset(-.12, -.28),
        torso: 0,
        foot: Offset(-.44, 0),
        hand: Offset(.18, -.57),
      ),
      hold: .35,
      move: 1.2,
    ),
    _Key(
      _Pose(
        hip: Offset(-.12, -.28),
        torso: 0,
        foot: Offset(-.44, 0),
        hand: Offset(.2, -.37),
      ),
      hold: .15,
      move: .9,
    ),
  ],
);

// ── Drawing ───────────────────────────────────────────────────────────────

class _DemoPainter extends CustomPainter {
  _DemoPainter(this.demo, this.seconds, this.color);
  final _Demo demo;
  final double seconds;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final view = demo.view;
    final scale = math.min(size.width / view.width, size.height / view.height);
    canvas.save();
    canvas.translate(
      (size.width - view.width * scale) / 2 - view.left * scale,
      (size.height - view.height * scale) / 2 - view.top * scale,
    );
    canvas.scale(scale);
    final b = _Body(demo, demo.poseAt(seconds));
    const w = .034;
    Paint line(Color c, [double width = w]) => Paint()
      ..color = c
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final scenery = line(Colors.white24, .02);
    final equipment = line(Colors.white60, .022);
    final far = line(color.withValues(alpha: .4));
    final near = line(color);

    // Floor and fixed equipment.
    canvas.drawLine(
      Offset(view.left, 0),
      Offset(view.right, 0),
      line(Colors.white12, .012),
    );
    final s = demo.scene;
    for (final r in [s.bench, s.seat].whereType<Rect>()) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(.015)),
        Paint()..color = Colors.white12,
      );
      canvas.drawLine(
        Offset(r.left + .04, r.bottom),
        Offset(r.left + .04, 0),
        scenery,
      );
      canvas.drawLine(
        Offset(r.right - .04, r.bottom),
        Offset(r.right - .04, 0),
        scenery,
      );
    }
    if (s.pullBar case final y?) {
      canvas.drawLine(Offset(-.3, y), Offset(.3, y), equipment);
      canvas.drawLine(Offset(-.3, y), Offset(-.3, 0), scenery);
    }
    if (s.bandAnchor case final a?) {
      canvas.drawLine(Offset(a.dx, a.dy - .06), Offset(a.dx, 0), scenery);
      canvas.drawLine(a, b.hand, line(const Color(0xFFFFC857), .014));
    }
    if (s.sled) {
      final along = b.ankle - b.hip;
      final n = Offset(-along.dy, along.dx) / along.distance;
      final foot = b.ankle + along / along.distance * .03;
      canvas.drawLine(foot - n * .13, foot + n * .13, equipment);
      canvas.drawLine(
        b.hip + along / along.distance * .1,
        foot + along / along.distance * .25,
        scenery,
      );
    }

    // Far limbs, body, near limbs.
    void limb(Paint p, Offset a, Offset j, Offset e) => canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(j.dx, j.dy)
        ..lineTo(e.dx, e.dy),
      p,
    );
    void foot(Paint p, Offset ankle) {
      final onFloor = ankle.dy > -.12;
      canvas.drawLine(ankle, Offset(ankle.dx + .07, onFloor ? 0 : ankle.dy), p);
    }

    limb(far, b.hip, b.farKnee, b.farAnkle);
    foot(far, b.farAnkle);
    limb(far, b.shoulder, b.farElbow, b.farHand);
    canvas.drawLine(b.hip, b.shoulder, near..strokeWidth = w * 1.25);
    near.strokeWidth = w;
    canvas.drawCircle(b.head, _headR, Paint()..color = color);
    limb(near, b.hip, b.knee, b.ankle);
    foot(near, b.ankle);

    // Equipment held in the hands sits between the arms.
    final plate = Paint()..color = Colors.white.withValues(alpha: .12);
    switch (demo.prop) {
      case _Prop.barbell:
        canvas.drawCircle(b.hand, .11, plate);
        canvas.drawCircle(b.hand, .11, equipment);
        canvas.drawCircle(b.hand, .018, Paint()..color = Colors.white60);
      case _Prop.curlBar:
        canvas.drawCircle(b.hand, .065, plate);
        canvas.drawCircle(b.hand, .065, equipment);
      case _Prop.dumbbells:
        for (final h in [b.farHand, b.hand]) {
          canvas.drawCircle(h, .04, plate);
          canvas.drawCircle(h, .04, equipment);
        }
      case _Prop.dumbbell:
        canvas.drawCircle(b.hand, .045, plate);
        canvas.drawCircle(b.hand, .045, equipment);
      case _Prop.goblet:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: b.hand, width: .07, height: .11),
            const Radius.circular(.02),
          ),
          equipment,
        );
      case _Prop.none:
        break;
    }
    limb(near, b.shoulder, b.elbow, b.hand);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DemoPainter old) =>
      old.seconds != seconds || old.demo != demo || old.color != color;
}

/// The looping demonstration of a built-in exercise, or nothing for an
/// exercise without one. Shows a still pose when motion is reduced.
class StrengthExerciseDemo extends StatefulWidget {
  const StrengthExerciseDemo({
    super.key,
    required this.variantId,
    required this.name,
    this.height = 150,
    this.showCue = true,
  });
  final String variantId, name;
  final double height;
  final bool showCue;

  static bool has(String variantId) => _demos.containsKey(variantId);

  /// Ids of every exercise with a demonstration.
  static Iterable<String> get ids => _demos.keys;

  /// The one-line movement cue of [variantId], if it has a demonstration.
  static String? cueOf(String variantId) => _demos[variantId]?.cue;

  @override
  State<StrengthExerciseDemo> createState() => _StrengthExerciseDemoState();
}

class _StrengthExerciseDemoState extends State<StrengthExerciseDemo>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = _demos[widget.variantId];
    if (demo == null) return const SizedBox.shrink();
    final still = MediaQuery.disableAnimationsOf(context);
    final stillAt = demo.keys
        .take(demo.still)
        .fold(0.0, (t, k) => t + k.hold + k.move);
    return Semantics(
      image: true,
      label: context.l10n.nameDemonstrationCue(widget.name, demo.cue),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, _) => CustomPaint(
                painter: _DemoPainter(
                  demo,
                  still ? stillAt : controller.value * 3600,
                  strengthColor,
                ),
              ),
            ),
          ),
          if (widget.showCue)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                demo.cue,
                style: const TextStyle(fontSize: 12, color: muted, height: 1.3),
              ),
            ),
        ],
      ),
    );
  }
}

/// Draws [variantId] at [seconds] into its loop, for previews and tests.
void paintStrengthDemo(
  Canvas canvas,
  Size size,
  String variantId,
  double seconds,
) => _DemoPainter(
  _demos[variantId]!,
  seconds,
  strengthColor,
).paint(canvas, size);

/// The demonstration's key-pose times: the start of each key.
List<double> strengthDemoKeyTimes(String variantId) {
  final demo = _demos[variantId]!;
  var t = 0.0;
  return [for (final k in demo.keys) (t, t += k.hold + k.move).$1];
}
