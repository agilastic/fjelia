import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

const _deleteColors = [Color(0xFFFF4D6D), Color(0xFFFF2E93)];
const _coachColors = [Color(0xFF00D4A0), Color(0xFF22D3E6), Color(0xFF8B5CF6)];

/// A card that does something when swiped: to the left it deletes, to the
/// right it asks the coach. Past the point of no return the phone ticks and
/// the icon pops; let go before it and the card springs back.
class SwipeActionTile extends StatefulWidget {
  const SwipeActionTile({
    super.key,
    required this.child,
    required this.onDelete,
    required this.onCoach,
    required this.deleteLabel,
    required this.coachLabel,
    this.borderRadius = 12,
    this.peek = false,
  });

  final Widget child;

  /// Called once the card has flown out and folded away.
  final Future<void> Function() onDelete;
  final VoidCallback onCoach;
  final String deleteLabel, coachLabel;
  final double borderRadius;

  /// Wiggles once to show that the card can be swiped.
  final bool peek;

  @override
  State<SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<SwipeActionTile>
    with TickerProviderStateMixin {
  /// How far the card is dragged, in logical pixels; negative is left.
  double _dx = 0;
  double _width = 1;
  bool _armed = false;
  bool _busy = false;

  late final _settle = AnimationController(vsync: this);
  late final _fold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Animation<double>? _settleTo;

  /// The share of the width that triggers an action.
  static const _trigger = .32;
  double get _threshold => _width * _trigger;
  double get _progress => (_dx.abs() / _threshold).clamp(0, 1.4).toDouble();

  @override
  void initState() {
    super.initState();
    _settle.addListener(() {
      final to = _settleTo;
      if (to != null) setState(() => _dx = to.value);
    });
    if (widget.peek) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _peek());
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    _fold.dispose();
    super.dispose();
  }

  Future<void> _animateTo(
    double target, {
    Duration duration = const Duration(milliseconds: 520),
    Curve curve = Curves.elasticOut,
  }) async {
    _settleTo = Tween(
      begin: _dx,
      end: target,
    ).animate(CurvedAnimation(parent: _settle, curve: curve));
    _settle
      ..duration = duration
      ..reset();
    await _settle.forward().orCancel.catchError((_) {});
  }

  /// A pause, a nudge left, a nudge right, settle: one animation, so
  /// nothing is left waiting when the card goes away.
  Future<void> _peek() async {
    if (!mounted || _dx != 0) return;
    _settleTo = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 600),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -42,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 260,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -42,
          end: 30,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 320,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 30,
          end: 0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 520,
      ),
    ]).animate(_settle);
    _settle
      ..duration = const Duration(milliseconds: 1700)
      ..reset();
    await _settle.forward().orCancel.catchError((_) {});
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_busy) return;
    _settle.stop();
    // Past the trigger point the card follows the finger less: a rubber band.
    final raw = _dx + d.delta.dx * (_progress >= 1 ? .35 : 1);
    setState(() => _dx = raw.clamp(-_width * .8, _width * .8));
    final armed = _progress >= 1;
    if (armed != _armed) {
      _armed = armed;
      armed ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
    }
  }

  Future<void> _onEnd(DragEndDetails d) async {
    if (_busy) return;
    final v = d.primaryVelocity ?? 0;
    final deleting = _dx < 0 && (_progress >= 1 || v < -1200);
    final coaching = _dx > 0 && (_progress >= 1 || v > 1200);
    _armed = false;
    if (deleting) {
      await _delete();
    } else if (coaching) {
      HapticFeedback.lightImpact();
      await _animateTo(0, duration: const Duration(milliseconds: 600));
      widget.onCoach();
    } else {
      await _animateTo(0);
    }
  }

  Future<void> _delete() async {
    _busy = true;
    HapticFeedback.heavyImpact();
    await _animateTo(
      -_width * 1.1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInCubic,
    );
    if (!mounted) return;
    await _fold.forward().orCancel.catchError((_) {});
    try {
      await widget.onDelete();
    } catch (_) {
      // Still here: show it again.
      if (!mounted) return;
      _fold.reset();
      await _animateTo(0);
      _busy = false;
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final left = _dx < 0;
    final progress = _progress;
    final colors = left ? _deleteColors : _coachColors;
    final glow = colors.last.withValues(alpha: .45 * progress.clamp(0, 1));
    final radius = BorderRadius.circular(widget.borderRadius);
    return SizeTransition(
      sizeFactor: ReverseAnimation(
        CurvedAnimation(parent: _fold, curve: Curves.easeInOutCubic),
      ),
      alignment: Alignment.topCenter,
      child: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(label: widget.deleteLabel): _delete,
          CustomSemanticsAction(label: widget.coachLabel): widget.onCoach,
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            _width = math.max(1, constraints.maxWidth);
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: _onUpdate,
              onHorizontalDragEnd: _onEnd,
              child: Stack(
                children: [
                  if (_dx != 0)
                    Positioned.fill(
                      bottom: 8,
                      child: _Backdrop(
                        left: left,
                        progress: progress,
                        colors: colors,
                        radius: radius,
                        label: left ? widget.deleteLabel : widget.coachLabel,
                        revealed: _dx.abs(),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(_dx, 0),
                    child: Transform.rotate(
                      angle: _dx / _width * .05,
                      child: Transform.scale(
                        scale: 1 - .025 * progress.clamp(0, 1),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            boxShadow: [
                              if (_dx != 0)
                                BoxShadow(
                                  color: glow,
                                  blurRadius: 24,
                                  spreadRadius: -4,
                                ),
                            ],
                          ),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({
    required this.left,
    required this.progress,
    required this.colors,
    required this.radius,
    required this.label,
    required this.revealed,
  });

  /// How much of the backdrop the card uncovers, in logical pixels.
  final double revealed;
  final bool left;
  final double progress;
  final List<Color> colors;
  final BorderRadius radius;
  final String label;

  @override
  Widget build(BuildContext context) {
    final armed = progress >= 1;
    final reveal = progress.clamp(0, 1).toDouble();
    final icon = left ? Icons.delete_rounded : Icons.auto_awesome;
    final badge = SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: reveal,
            strokeWidth: 2.5,
            color: Colors.white,
            backgroundColor: Colors.white24,
          ),
          AnimatedScale(
            scale: armed ? 1.25 : .7 + .3 * reveal,
            duration: const Duration(milliseconds: 260),
            curve: Curves.elasticOut,
            child: Transform.rotate(
              // The trash can wobbles, the sparkle turns as it fills.
              angle: left
                  ? (armed ? math.sin(progress * 18) * .18 : 0)
                  : reveal * math.pi / 2,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
    // The label appears once there is room for it next to the badge.
    final text = Opacity(
      opacity: ((revealed - 150) / 40).clamp(0, 1).toDouble(),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: left ? Alignment.centerRight : Alignment.centerLeft,
          end: left ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            for (final c in colors) c.withValues(alpha: .35 + .65 * reveal),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisAlignment: left
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: left
              ? [text, const SizedBox(width: 10), badge]
              : [badge, const SizedBox(width: 10), text],
        ),
      ),
    );
  }
}
