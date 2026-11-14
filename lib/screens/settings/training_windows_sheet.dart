import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../models/training_windows.dart';
import '../../providers/missed_workout_provider.dart'
    show missedWorkoutReminderProvider;
import '../../providers/plan_schedule_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';

/// The sky pair of Fjelia Aurora: time to move, recovery, open air.
const _sky = [Color(0xFF6FA8FF), Color(0xFF3EE0FF)];

/// [weekday]'s windows as text, e.g. "6:00–7:30, 17:00–20:00".
String trainingWindowsText(TrainingWindows w, int weekday) =>
    [for (final (start, end) in w.ranges(weekday)) '${_hm(start)}–${_hm(end)}']
        .join(', ');

String _hm(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

/// When in the week training fits, painted in half-hour slots like a router's
/// parental-control schedule: pick the brush or the eraser, then tap or swipe
/// along a day.
class TrainingWindowsSheet extends ConsumerStatefulWidget {
  const TrainingWindowsSheet({super.key});

  @override
  ConsumerState<TrainingWindowsSheet> createState() => _WindowsState();
}

class _WindowsState extends ConsumerState<TrainingWindowsSheet> {
  TrainingWindows? windows;
  bool paint = true;
  bool saving = false;

  void _set(int weekday, int slot) {
    final w = windows!;
    if (slot < 0 || slot >= TrainingWindows.slotsPerDay) return;
    if (w.isOpen(weekday, slot) == paint) return;
    HapticFeedback.selectionClick();
    setState(() => windows = w.withSlot(weekday, slot, paint));
  }

  /// Paints [from] to [to] (half-hour slots, end excluded) on [days].
  void _preset(List<int> days, int from, int to) {
    var w = windows!;
    for (final d in days) {
      for (var s = from; s < to; s++) {
        w = w.withSlot(d, s, true);
      }
    }
    setState(() => windows = w);
  }

  Future<void> _save() async {
    final profile = await ref.read(userProfileProvider.future);
    if (!mounted) return;
    setState(() => saving = true);
    await runUiAction(context, () async {
      await ref
          .read(userProfileProvider.notifier)
          .save(profile.copyWith(trainingWindows: windows));
      // The athlete changed when they can train: the plan follows at once.
      await ref.read(applyScheduleProvider)();
      unawaited(ref.read(missedWorkoutReminderProvider).reconcile());
      if (mounted) Navigator.of(context).maybePop();
    });
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    windows ??= profile?.trainingWindows;
    final w = windows;
    final days = profile?.weekStartsOnMonday ?? true
        ? const [1, 2, 3, 4, 5, 6, 7]
        : const [7, 1, 2, 3, 4, 5, 6];
    final dayNames = [l.mon, l.tue, l.wed, l.thu, l.fri, l.sat, l.sun];
    return SheetPage(
      title: l.trainingWindowsTitle,
      child: w == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  l.trainingWindowsHint,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: l.week,
                  accent: _sky,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: true,
                            icon: const Icon(Icons.brush_rounded, size: 18),
                            label: Text(l.trainingWindowsPaint),
                          ),
                          ButtonSegment(
                            value: false,
                            icon: const Icon(Icons.block_rounded, size: 18),
                            label: Text(l.trainingWindowsErase),
                          ),
                        ],
                        selected: {paint},
                        onSelectionChanged: (v) =>
                            setState(() => paint = v.first),
                      ),
                      const SizedBox(height: 14),
                      const _HourScale(),
                      for (final d in days)
                        _DayRow(
                          label: dayNames[d - 1],
                          windows: w,
                          weekday: d,
                          onSlot: (slot) => _set(d, slot),
                        ),
                      const _HourScale(),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            label: Text('${l.windowPresetMorning} 6–8'),
                            onPressed: () =>
                                _preset(const [1, 2, 3, 4, 5], 12, 16),
                          ),
                          ActionChip(
                            label: Text('${l.windowPresetLunch} 12–13'),
                            onPressed: () =>
                                _preset(const [1, 2, 3, 4, 5], 24, 26),
                          ),
                          ActionChip(
                            label: Text('${l.windowPresetEvening} 17–21'),
                            onPressed: () =>
                                _preset(const [1, 2, 3, 4, 5], 34, 42),
                          ),
                          ActionChip(
                            label: Text('${l.windowPresetWeekend} 8–20'),
                            onPressed: () => _preset(const [6, 7], 16, 40),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.clear_rounded, size: 16),
                            label: Text(l.trainingWindowsClear),
                            onPressed: () => setState(
                              () => windows = const TrainingWindows(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (w.isEmpty)
                        Text(
                          l.trainingWindowsNotSet,
                          style: TextStyle(fontSize: 12, color: muted),
                        )
                      else
                        for (final d in days)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: _labelWidth + 6,
                                  child: Text(
                                    dayNames[d - 1].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: muted,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    w.hasWindow(d)
                                        ? trainingWindowsText(w, d)
                                        : l.restDay,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: w.hasWindow(d) ? fjInk : muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: saving || w == profile?.trainingWindows
                      ? null
                      : _save,
                  child: Text(l.save),
                ),
              ],
            ),
    );
  }
}

const _labelWidth = 30.0;

/// 0, 3, 6 … 24 above and below the grid.
class _HourScale extends StatelessWidget {
  const _HourScale();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: _labelWidth),
    child: LayoutBuilder(
      builder: (context, c) => SizedBox(
        height: 16,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var h = 0; h <= 24; h += 3)
              Positioned(
                left: c.maxWidth * h / 24 - 10,
                width: 20,
                child: Text(
                  '$h',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: fjInk54),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// One day: tap a half hour, or swipe along the day to paint or erase.
class _DayRow extends StatefulWidget {
  const _DayRow({
    required this.label,
    required this.windows,
    required this.weekday,
    required this.onSlot,
  });
  final String label;
  final TrainingWindows windows;
  final int weekday;
  final ValueChanged<int> onSlot;

  @override
  State<_DayRow> createState() => _DayRowState();
}

class _DayRowState extends State<_DayRow> {
  int? _last;

  /// Every slot between the last one and [x], so a fast swipe leaves no gap.
  void _to(double x, double width) {
    final slot = (x / width * TrainingWindows.slotsPerDay).floor().clamp(
      0,
      TrainingWindows.slotsPerDay - 1,
    );
    final from = _last ?? slot;
    final step = slot >= from ? 1 : -1;
    for (var s = from; s != slot + step; s += step) {
      widget.onSlot(s);
    }
    _last = slot;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: _labelWidth,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fjInk70,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) => GestureDetector(
              key: Key('training-window-day-${widget.weekday}'),
              behavior: HitTestBehavior.opaque,
              // A swipe paints from where the finger went down.
              dragStartBehavior: DragStartBehavior.down,
              onTapDown: (d) {
                _last = null;
                _to(d.localPosition.dx, c.maxWidth);
              },
              onHorizontalDragStart: (d) {
                _last = null;
                _to(d.localPosition.dx, c.maxWidth);
              },
              onHorizontalDragUpdate: (d) =>
                  _to(d.localPosition.dx, c.maxWidth),
              onHorizontalDragEnd: (_) => _last = null,
              child: CustomPaint(
                size: Size(c.maxWidth, 34),
                painter: _DayPainter(widget.windows, widget.weekday),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DayPainter extends CustomPainter {
  _DayPainter(this.windows, this.weekday);
  final TrainingWindows windows;
  final int weekday;

  @override
  void paint(Canvas canvas, Size size) {
    const n = TrainingWindows.slotsPerDay;
    final cell = size.width / n;
    final open = Paint()
      ..shader = LinearGradient(
        colors: [fjAccent(_sky.first), fjAccent(_sky.last)],
      ).createShader(Offset.zero & size);
    final frame = Paint()
      ..color = fjInk24
      ..style = PaintingStyle.stroke;
    final tick = Paint()..color = fjInk24;
    for (var s = 0; s < n; s++) {
      if (windows.isOpen(weekday, s)) {
        canvas.drawRect(
          Rect.fromLTWH(s * cell, 0, cell + .5, size.height),
          open,
        );
      }
    }
    // An hour line, and a short half-hour tick, as on the router's scale.
    for (var s = 0; s <= n; s++) {
      final x = s * cell;
      final hour = s.isEven;
      canvas.drawLine(
        Offset(x, hour ? 0 : size.height * .6),
        Offset(x, size.height),
        tick,
      );
    }
    canvas.drawRect(Offset.zero & size, frame);
  }

  @override
  bool shouldRepaint(_DayPainter old) =>
      old.windows != windows || old.weekday != weekday;
}
