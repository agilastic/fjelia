import '../theme/fjelia_style.dart';
import '../l10n/l10n_ext.dart';

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
    this.event,
    this.isEasyOnly = false,
  });

  final DateTime date;

  /// Sessions already planned that day.
  final int sessions;
  final bool isRestDay;

  /// The day already holds as many sessions as the athlete allows.
  final bool isFull;

  /// The event that owns the day (its day, or the rest day before); no
  /// workout can move there.
  final String? event;

  /// Days just after an event: easy sessions only.
  final bool isEasyOnly;
}

/// Moves a workout to another day: a compact strip of days to tap and a
/// date picker for anything further away. Days show what is on them (rest
/// day, event, other sessions), so a move is never blind; a move can be
/// undone right on the card.
class MoveWorkoutCard extends StatefulWidget {
  const MoveWorkoutCard({
    super.key,
    required this.current,
    required this.days,
    required this.onMove,
    this.onPickDate,
    this.enabled = true,
    this.movedFrom,
    this.onUndo,
    this.note,
  });

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
  static const _chipWidth = 46.0, _gap = 6.0;
  final _scroll = ScrollController();

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
    final days = widget.days;
    // Only the marks that are on the strip need explaining.
    final keys = [
      if (days.any((d) => d.isRestDay && d.event == null))
        _Key(
          icon: Icons.nightlight_outlined,
          text: context.l10n.moveKeyRestDay,
        ),
      if (days.any((d) => d.event != null))
        _Key(icon: Icons.flag, text: context.l10n.moveKeyEvent),
      if (days.any((d) => d.isEasyOnly && d.sessions == 0))
        _Key(icon: Icons.self_improvement, text: context.l10n.moveKeyEasyOnly),
      if (days.any((d) => d.sessions > 0))
        _Key(
          icon: Icons.circle,
          text: context.l10n.moveKeyHasSession,
          small: true,
        ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 10),
      decoration: BoxDecoration(
        color: duo(0xFF282828, 0xFFEEF1F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fjInk10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.moveThisWorkout,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                    color: muted,
                  ),
                ),
              ),
              if (widget.onPickDate != null)
                IconButton(
                  tooltip: context.l10n.pickDate,
                  visualDensity: VisualDensity.compact,
                  color: mint,
                  onPressed: widget.enabled ? widget.onPickDate : null,
                  icon: const Icon(Icons.calendar_month_outlined, size: 20),
                ),
            ],
          ),
          if (widget.movedFrom != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
                decoration: BoxDecoration(
                  color: mint.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: mint.withValues(alpha: .4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 15,
                          color: mint,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.movedFromMovedfrom(
                              DateFormat.MMMMEEEEd().format(widget.movedFrom!),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: mint,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: widget.enabled ? widget.onUndo : null,
                          child: Text(context.l10n.undo),
                        ),
                      ],
                    ),
                    if (widget.note != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 6),
                        child: Text(
                          widget.note!,
                          style: TextStyle(fontSize: 11, color: fjInk70),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(
            height: 58,
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 6),
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: _gap),
              itemBuilder: (context, i) {
                final day = days[i];
                return _DayChip(
                  day: day,
                  isCurrent: DateUtils.isSameDay(day.date, widget.current),
                  isToday: DateUtils.isSameDay(day.date, today),
                  onTap: widget.enabled ? () => _move(day.date) : null,
                );
              },
            ),
          ),
          if (keys.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 4, children: keys),
          ],
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isCurrent,
    required this.isToday,
    required this.onTap,
  });

  final MoveDay day;
  final bool isCurrent, isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fill = isCurrent ? mint : fjInk.withValues(alpha: .05);
    final textColor = isCurrent ? Colors.black : fjInk;
    return Semantics(
      button: true,
      selected: isCurrent,
      label:
          '${DateFormat.MMMMEEEEd().format(day.date)}'
          '${isCurrent ? ', where the workout is' : ''}'
          '${day.isRestDay ? ', rest day' : ''}'
          '${day.event != null ? ', ${day.event}, not available' : ''}'
          '${day.isEasyOnly ? ', easy sessions only after an event' : ''}'
          '${day.sessions > 0 ? ', ${day.sessions} sessions planned' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: _MoveWorkoutCardState._chipWidth,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday ? Colors.amber : fjInk12,
              width: isToday ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat.E().format(day.date).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: .6,
                  fontWeight: FontWeight.w600,
                  color: isCurrent ? Colors.black87 : muted,
                ),
              ),
              Text(
                context.l10n.day(day.date.day),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              SizedBox(
                height: 12,
                child: day.event != null
                    ? const Icon(Icons.flag, size: 12, color: Colors.orange)
                    : day.isRestDay
                    ? Icon(
                        Icons.nightlight_outlined,
                        size: 12,
                        color: isCurrent ? Colors.black87 : muted,
                      )
                    : day.isEasyOnly && day.sessions == 0
                    ? Icon(
                        Icons.self_improvement,
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
                                    : fjInk54,
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
      Text(text, style: TextStyle(fontSize: 10, color: muted)),
    ],
  );
}
