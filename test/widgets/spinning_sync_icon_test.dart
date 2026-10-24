import 'dart:math' as math;

import 'package:fjelia/widgets/spinning_sync_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const tau = 2 * math.pi;

void main() {
  group('SyncSpin', () {
    test('rests until it is started', () {
      final spin = SyncSpin();
      expect(spin.atRest, isTrue);
      spin.step(.1);
      expect(spin.spin, 0);
      expect(spin.circuit, 0);
    });

    test('ramps up to a fast spin and a quicker circuit', () {
      final spin = SyncSpin()..start();
      spin.step(1 / 60);
      expect(spin.atRest, isFalse);
      expect(spin.spinSpeed, lessThan(SyncSpin.spinRate * tau * .5));
      for (var i = 0; i < 90; i++) {
        spin.step(1 / 60);
      }
      expect(spin.spinSpeed, closeTo(SyncSpin.spinRate * tau, 1e-6));
      expect(spin.circuitSpeed, closeTo(SyncSpin.circuitRate * tau, 1e-6));
      // The spin around its own axis is much faster than the circuit.
      expect(spin.spinSpeed, greaterThan(2 * spin.circuitSpeed));
    });

    test('slows down smoothly from the current speed and lands at rest', () {
      final spin = SyncSpin()..start();
      for (var i = 0; i < 200; i++) {
        spin.step(1 / 60);
      }
      final before = spin.spinSpeed;
      spin.stop();
      expect(spin.isSlowing, isTrue);
      // No jump in speed when the slow-down begins.
      expect(spin.spinSpeed, closeTo(before, before * .001));

      var previous = spin.spinSpeed;
      var seconds = 0.0;
      var lastAngle = spin.spin;
      var maxWobble = 1.0;
      while (!spin.atRest && seconds < 10) {
        lastAngle = spin.spin;
        spin.step(1 / 60);
        seconds += 1 / 60;
        if (spin.isSlowing) {
          expect(spin.spinSpeed, lessThanOrEqualTo(previous + 1e-9));
          previous = spin.spinSpeed;
          maxWobble = math.max(maxWobble, spin.wobble);
        }
      }
      expect(spin.atRest, isTrue);
      expect(seconds, inInclusiveRange(1.5, 4.0));
      // It wobbles more while slowing and ends exactly in the resting pose.
      expect(maxWobble, greaterThan(1.5));
      expect(spin.wobble, 1);
      expect(spin.spin, 0);
      expect(spin.circuit, 0);
      final remainder = lastAngle % tau;
      expect(math.min(remainder, tau - remainder), lessThan(.4));
    });

    test('stopping straight after starting also ends at rest', () {
      final spin = SyncSpin()..start();
      spin.step(.05);
      spin.stop();
      var seconds = 0.0;
      while (!spin.atRest && seconds < 10) {
        spin.step(1 / 60);
        seconds += 1 / 60;
      }
      expect(spin.atRest, isTrue);
      expect(spin.spin, 0);
    });

    test('starting again while it slows down picks the motion up', () {
      final spin = SyncSpin()..start();
      for (var i = 0; i < 150; i++) {
        spin.step(1 / 60);
      }
      spin.stop();
      for (var i = 0; i < 40; i++) {
        spin.step(1 / 60);
      }
      expect(spin.isSlowing, isTrue);
      spin.start();
      expect(spin.isSlowing, isFalse);
      expect(spin.atRest, isFalse);
      for (var i = 0; i < 120; i++) {
        spin.step(1 / 60);
      }
      expect(spin.spinSpeed, closeTo(SyncSpin.spinRate * tau, 1e-6));
    });

    test('restarting while it slows down does not change the speed', () {
      for (final slowedFor in [5, 20, 60, 100]) {
        final spin = SyncSpin()..start();
        for (var i = 0; i < 150; i++) {
          spin.step(1 / 60);
        }
        spin.stop();
        for (var i = 0; i < slowedFor; i++) {
          spin.step(1 / 60);
        }
        final slowed = spin.spinSpeed;
        spin.start();
        expect(spin.spinSpeed, closeTo(slowed, slowed * .001 + 1e-6));
      }
    });
  });

  group('SpinningSyncIcon', () {
    final rest = Matrix4.identity()..setEntry(3, 2, 0.0028);

    Matrix4 pose(WidgetTester tester) => tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(SpinningSyncIcon),
            matching: find.byType(Transform),
          ),
        )
        .transform;

    Widget app({required bool spinning, bool reduceMotion = false}) =>
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Scaffold(
              body: Center(
                child: SpinningSyncIcon(
                  spinning: spinning,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        );

    testWidgets('rests while nothing is syncing', (tester) async {
      await tester.pumpWidget(app(spinning: false));
      await tester.pump(const Duration(milliseconds: 500));
      expect(pose(tester), rest);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('spins while syncing, then slows down and rests', (
      tester,
    ) async {
      await tester.pumpWidget(app(spinning: true));
      Matrix4 sample = pose(tester);
      var changes = 0;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        final next = pose(tester);
        if (next != sample) changes++;
        sample = next;
      }
      expect(changes, greaterThan(15));
      expect(sample, isNot(rest));

      await tester.pumpWidget(app(spinning: false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(pose(tester), rest);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a short pause between sync steps does not slow it down', (
      tester,
    ) async {
      await tester.pumpWidget(app(spinning: true));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      final state = tester.state<SpinningSyncIconState>(
        find.byType(SpinningSyncIcon),
      );
      final speed = state.motion.spinSpeed;

      // "Done" for under a second, then the next step starts.
      await tester.pumpWidget(app(spinning: false));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(state.motion.isSlowing, isFalse);
      expect(state.motion.spinSpeed, closeTo(speed, 1e-6));
      await tester.pumpWidget(app(spinning: true));
      await tester.pump(const Duration(milliseconds: 40));
      expect(state.motion.isSlowing, isFalse);
      expect(state.motion.spinSpeed, closeTo(speed, 1e-6));

      // When it really ends, it slows down after the pause.
      await tester.pumpWidget(app(spinning: false));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(state.motion.isSlowing, isTrue);
      for (var i = 0; i < 250; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(state.motion.atRest, isTrue);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('does not move when the system asks to reduce motion', (
      tester,
    ) async {
      await tester.pumpWidget(app(spinning: true, reduceMotion: true));
      await tester.pump(const Duration(milliseconds: 500));
      expect(pose(tester), rest);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
