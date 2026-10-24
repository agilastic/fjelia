import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'app_widgets.dart';

/// What a day looks like to a workout that wants to move there.
class MoveDay {
  const MoveDay({
    required this.date,
    this.sessions = 0,
    this.isRestDay = false,
    this.isFull = false,
  });

  final DateTime date;

  /// Sessions already planned that day.
  final int sessions;
  final bool isRestDay;

  /// The day already holds as many sessions as the athlete allows.
  final bool isFull;
}

/// Moves a workout to another day: a strip of days to tap, the workout itself
/// as a chip to drag onto one, and a date picker for anything further away.
/// Days show what is on them (rest day, other sessions), so a move is never
/// blind.
class MoveWorkoutCard extends StatefulWidget {
  const MoveWorkoutCard({
    super.key,
    required this.title,
    required this.current,
    required this.days,
    required this.onMove,
    this.onPickDate,
    this.enabled = true,
    this.movedFrom,
    this.onUndo,
    this.note,
  });

  /// The workout's name, on the chip that is dragged.
  final String title;

  /// The day the workout is on now.
  final DateTime current;

  /// The days offered, in order; each earlier than today is left out by the
  /// caller.
  final List<MoveDay> days;

  /// Called with the chosen day; the caller checks and does the move.
  final Future<void> Function(DateTime day) onMove;

  /// Opens a date picker for a day outside the strip.
  final VoidCallback? onPickDate;

  final bool enabled;

  /// The day the workout was on before it was moved here, to offer the way
  /// back. Null when it has not been moved.
  final DateTime? movedFrom;
  final VoidCallback? onUndo;

  /// A hint that goes with the move, such as the watch calendar needing an
  /// update.
  final String? note;

  @override
  State<MoveWorkoutCard> createState() => _MoveWorkoutCardState();
}

class _MoveWorkoutCardState extends State<MoveWorkoutCard> {
  static const _chipWidth = 54.0, _gap = 8.0;
  final _scroll = ScrollController();
  DateTime? _hover;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centre(animate: false),
    );
  }

  @override
  void didUpdateWidget(MoveWorkoutCard old) {
    super.didUpdateWidget(old);
    if (!DateUtils.isSameDay(old.current, widget.current)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centre());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Brings the workout's day to the middle of the strip.
  void _centre({bool animate = true}) {
    if (!mounted || !_scroll.hasClients) return;
    final index = widget.days.indexWhere(
      (d) => DateUtils.isSameDay(d.date, widget.current),
    );
    if (index < 0) return;
    final target =
        (index * (_chipWidth + _gap) -
                (_scroll.position.viewportDimension - _chipWidth) / 2)
            .clamp(0.0, _scroll.position.maxScrollExtent);
    if (animate) {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  void _move(DateTime day) {
    if (!widget.enabled || DateUtils.isSameDay(day, widget.current)) return;
    HapticFeedback.selectionClick();
    widget.onMove(day);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, size: 20, color: mint),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'MOVE THIS WORKOUT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                    color: muted,
                  ),
                ),
              ),
              if (widget.onPickDate != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: mint,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: widget.enabled ? widget.onPickDate : null,
                  icon: const Icon(Icons.calendar_month_outlined, size: 16),
                  label: const Text(
                    'Pick date',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Now on ${DateFormat('EEEE, d MMMM').format(widget.current)}. '
            'Tap a day, or drag the workout onto one. The steps stay as they are.',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          if (widget.movedFrom != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
              decoration: BoxDecoration(
                color: mint.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mint.withValues(alpha: .4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: mint,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Moved from ${DateFormat('EEEE d MMMM').format(widget.movedFrom!)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: mint,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: widget.enabled ? widget.onUndo : null,
                        child: const Text('Undo'),
                      ),
                    ],
                  ),
                  if (widget.note != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                      child: Text(
                        widget.note!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: Draggable<DateTime>(
              data: widget.current,
              maxSimultaneousDrags: widget.enabled ? 1 : 0,
              onDragStarted: HapticFeedback.mediumImpact,
              feedback: Material(
                color: Colors.transparent,
                child: _Pill(title: widget.title, lifted: true),
              ),
              childWhenDragging: Opacity(
                opacity: .35,
                child: _Pill(title: widget.title),
              ),
              child: _Pill(title: widget.title, grip: true),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 78,
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              itemCount: widget.days.length,
              separatorBuilder: (_, _) => const SizedBox(width: _gap),
              itemBuilder: (context, i) {
                final day = widget.days[i];
                final isCurrent = DateUtils.isSameDay(day.date, widget.current);
                return DragTarget<DateTime>(
                  onWillAcceptWithDetails: (_) {
                    if (!isCurrent) setState(() => _hover = day.date);
                    return !isCurrent;
                  },
                  onLeave: (_) => setState(() => _hover = null),
                  onAcceptWithDetails: (_) {
                    setState(() => _hover = null);
                    _move(day.date);
                  },
                  builder: (context, candidates, _) => _DayChip(
                    day: day,
                    isCurrent: isCurrent,
                    isToday: DateUtils.isSameDay(day.date, today),
                    hovered:
                        _hover != null && DateUtils.isSameDay(_hover, day.date),
                    onTap: widget.enabled ? () => _move(day.date) : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _Key(icon: Icons.nightlight_outlined, text: 'rest day'),
              _Key(icon: Icons.circle, text: 'has a session', small: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.title, this.grip = false, this.lifted = false});

  final String title;
  final bool grip;
  final bool lifted;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 280),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          mint.withValues(alpha: lifted ? .95 : .22),
          mint.withValues(alpha: lifted ? .75 : .1),
        ],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: mint.withValues(alpha: lifted ? 1 : .6)),
      boxShadow: lifted
          ? const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ]
          : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (grip) ...[
          const Icon(Icons.drag_indicator, size: 18, color: mint),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: lifted ? Colors.black : Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isCurrent,
    required this.isToday,
    required this.hovered,
    required this.onTap,
  });

  final MoveDay day;
  final bool isCurrent, isToday, hovered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fill = isCurrent
        ? mint
        : hovered
        ? mint.withValues(alpha: .28)
        : Colors.white.withValues(alpha: .05);
    final textColor = isCurrent ? Colors.black : Colors.white;
    return Semantics(
      button: true,
      selected: isCurrent,
      label:
          '${DateFormat('EEEE d MMMM').format(day.date)}'
          '${isCurrent ? ', where the workout is' : ''}'
          '${day.isRestDay ? ', rest day' : ''}'
          '${day.sessions > 0 ? ', ${day.sessions} sessions planned' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: _MoveWorkoutCardState._chipWidth,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hovered
                  ? mint
                  : isToday
                  ? Colors.amber
                  : Colors.white12,
              width: hovered || isToday ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('E').format(day.date).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: .6,
                  fontWeight: FontWeight.w600,
                  color: isCurrent ? Colors.black87 : muted,
                ),
              ),
              Text(
                '${day.date.day}',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              SizedBox(
                height: 14,
                child: day.isRestDay
                    ? Icon(
                        Icons.nightlight_outlined,
                        size: 12,
                        color: isCurrent ? Colors.black87 : muted,
                      )
                    : day.sessions > 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < day.sessions.clamp(1, 3); i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              child: Icon(
                                Icons.circle,
                                size: 5,
                                color: day.isFull
                                    ? Colors.orangeAccent
                                    : isCurrent
                                    ? Colors.black87
                                    : Colors.white54,
                              ),
                            ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.icon, required this.text, this.small = false});

  final IconData icon;
  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: small ? 6 : 12, color: muted),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 10, color: muted)),
    ],
  );
}
