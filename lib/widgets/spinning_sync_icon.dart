import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const _tau = 2 * math.pi;

/// Motion of the sync icon, kept apart from the widget so it can be tested.
///
/// Two rotations run together: a fast spin around the icon's own vertical axis
/// like a top, and a quicker clockwise circuit with a tilt. Starting, the speed
/// ramps up. Stopping, both rotations slow down smoothly and come to rest
/// exactly in the resting pose, wobbling more while they slow, like a top
/// running out of energy.
class SyncSpin {
  /// Turns per second around the icon's own axis at full speed.
  static const spinRate = 4.0;

  /// Turns per second of the clockwise circuit at full speed.
  static const circuitRate = 1.7;

  /// Seconds to reach full speed.
  static const rampUp = 0.7;

  /// Target length of the slow-down in seconds; the real length follows from
  /// landing exactly on the resting pose.
  static const slowDown = 2.4;

  double spin = 0; // radians
  double circuit = 0; // radians
  double _ramp = 0; // 0..1
  bool _running = false;
  bool _slowing = false;

  // Slow-down: angle = start + travel * easeOut(progress).
  double _spinStart = 0, _spinTravel = 0;
  double _circuitStart = 0, _circuitTravel = 0;
  double _length = 1, _progress = 0;

  bool get atRest => !_running && !_slowing;
  bool get isSlowing => _slowing;

  /// Wobble factor of the tilt: grows while slowing, 1 while running.
  double get wobble => _slowing ? 1 + 1.1 * math.sin(math.pi * _progress) : 1;

  static double _smooth(double x) => x * x * (3 - 2 * x);

  /// The x in 0..1 with [_smooth] of x equal to [y].
  static double _inverseSmooth(double y) {
    final c = y.clamp(0.0, 1.0).toDouble();
    return 0.5 - math.sin(math.asin(1 - 2 * c) / 3);
  }

  double get _speedFactor => _smooth(_ramp.clamp(0, 1));

  /// Current angular speeds in radians per second.
  double get spinSpeed => _slowing
      ? _spinTravel * 3 * math.pow(1 - _progress, 2) / _length
      : spinRate * _tau * _speedFactor;
  double get circuitSpeed => _slowing
      ? _circuitTravel * 3 * math.pow(1 - _progress, 2) / _length
      : circuitRate * _tau * _speedFactor;

  void start() {
    _running = true;
    if (_slowing) {
      // Pick the motion up again at the speed it has slowed down to, without a
      // jump: find the point of the ramp that gives exactly this speed.
      _ramp = _inverseSmooth(spinSpeed / (spinRate * _tau));
      _slowing = false;
    }
  }

  /// Begins the slow-down from the current speed, if it is turning.
  void stop() {
    if (!_running) return;
    _running = false;
    final spinNow = spinSpeed;
    if (spinNow < 0.5 && spin % _tau == 0) {
      _reset();
      return;
    }
    final spinAngle = spin % _tau;
    final circuitAngle = circuit % _tau;
    // Cubic ease-out starts at 3 * travel / length. Choosing the length as
    // 3 * travel / speed makes the slow-down begin at exactly the current
    // speed, and rounding the travel up lands both rotations on a whole turn.
    final wanted = math.max(spinNow, 4.0) * slowDown / 3;
    final spinTravel =
        (((spinAngle + wanted) / _tau).ceil() * _tau) - spinAngle;
    _length = math.max(0.8, 3 * spinTravel / math.max(spinNow, 4.0));
    final circuitWanted = circuitSpeed * _length / 3;
    var circuitTravel =
        (((circuitAngle + circuitWanted) / _tau).round() * _tau) - circuitAngle;
    if (circuitTravel < 0) circuitTravel += _tau;
    _spinStart = spinAngle;
    _spinTravel = spinTravel;
    _circuitStart = circuitAngle;
    _circuitTravel = circuitTravel;
    _progress = 0;
    _slowing = true;
  }

  void _reset() {
    spin = 0;
    circuit = 0;
    _ramp = 0;
    _running = false;
    _slowing = false;
    _progress = 0;
  }

  /// Advances the motion by [dt] seconds.
  void step(double dt) {
    if (_slowing) {
      _progress = math.min(1, _progress + dt / _length);
      final eased = 1 - math.pow(1 - _progress, 3);
      spin = _spinStart + _spinTravel * eased;
      circuit = _circuitStart + _circuitTravel * eased;
      if (_progress >= 1) _reset();
    } else if (_running) {
      _ramp = math.min(1, _ramp + dt / rampUp);
      spin += spinRate * _tau * _speedFactor * dt;
      circuit += circuitRate * _tau * _speedFactor * dt;
      // Keep the angles small so they stay precise over a long sync.
      if (spin > 1000 * _tau) spin -= 1000 * _tau;
      if (circuit > 1000 * _tau) circuit -= 1000 * _tau;
    }
  }

  Matrix4 pose() => Matrix4.identity()
    ..setEntry(3, 2, 0.0028)
    ..rotateZ(circuit)
    ..rotateX(0.45 * wobble * math.sin(circuit))
    ..rotateY(spin);
}

/// The sync icon. While [spinning] it spins around its own axis like a top in
/// 3D perspective while circling clockwise; when [spinning] ends it slows down
/// smoothly and comes to rest. Nothing moves when the system asks to reduce
/// motion.
class SpinningSyncIcon extends StatefulWidget {
  const SpinningSyncIcon({
    super.key,
    required this.spinning,
    required this.color,
    this.size = 20,
    this.icon = Icons.sync,
  });

  final bool spinning;
  final Color color;
  final double size;
  final IconData icon;

  @override
  State<SpinningSyncIcon> createState() => SpinningSyncIconState();
}

class SpinningSyncIconState extends State<SpinningSyncIcon>
    with SingleTickerProviderStateMixin {
  /// A sync reports "done" between its steps for a moment. Slowing down at
  /// every such gap would stop the icon in the middle of a sync, so it only
  /// begins to slow down when the sync has stayed over for this long.
  static const _grace = Duration(milliseconds: 1200);

  final _motion = SyncSpin();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  Timer? _graceTimer;

  @visibleForTesting
  SyncSpin get motion => _motion;

  void _tick(Duration elapsed) {
    final dt = math.min(0.05, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    setState(() => _motion.step(dt));
    if (_motion.atRest) _ticker.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(SpinningSyncIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  void _update() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.spinning && !reduce) {
      _graceTimer?.cancel();
      _graceTimer = null;
      _motion.start();
      if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    } else if (reduce) {
      _graceTimer?.cancel();
      _graceTimer = null;
      _slowDown();
    } else if (_graceTimer == null && !_motion.atRest && !_motion.isSlowing) {
      _graceTimer = Timer(_grace, () {
        _graceTimer = null;
        if (mounted && !widget.spinning) _slowDown();
      });
    }
  }

  void _slowDown() {
    _motion.stop();
    if (_motion.atRest && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.spinning ? 'Syncing' : 'Sync',
    child: Transform(
      alignment: Alignment.center,
      transform: _motion.pose(),
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    ),
  );
}
