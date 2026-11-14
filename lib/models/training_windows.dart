/// When in the week the athlete can train, in half-hour slots: one bit per
/// slot, 48 per day, one mask per ISO weekday (index 0 = Monday). Empty
/// means nothing is set, and the plan and the reminder work as before.
class TrainingWindows {
  const TrainingWindows([this.masks = const [0, 0, 0, 0, 0, 0, 0]]);

  static const slotsPerDay = 48;
  static const slotMinutes = 30;

  final List<int> masks;

  bool get isEmpty => masks.every((m) => m == 0);

  int _mask(int weekday) => masks[(weekday - 1) % 7];

  bool isOpen(int weekday, int slot) => _mask(weekday) & (1 << slot) != 0;

  bool hasWindow(int weekday) => _mask(weekday) != 0;

  /// The same windows with [slot] of [weekday] set to [open].
  TrainingWindows withSlot(int weekday, int slot, bool open) {
    final next = [...masks];
    final i = (weekday - 1) % 7;
    next[i] = open ? next[i] | (1 << slot) : next[i] & ~(1 << slot);
    return TrainingWindows(next);
  }

  /// [weekday]'s windows as [start, end) minute ranges from midnight.
  List<(int, int)> ranges(int weekday) {
    final out = <(int, int)>[];
    int? start;
    for (var s = 0; s <= slotsPerDay; s++) {
      final open = s < slotsPerDay && isOpen(weekday, s);
      if (open && start == null) start = s;
      if (!open && start != null) {
        out.add((start * slotMinutes, s * slotMinutes));
        start = null;
      }
    }
    return out;
  }

  /// The longest window of [weekday] in minutes; null when it has none.
  int? longestMinutes(int weekday) {
    final r = ranges(weekday);
    if (r.isEmpty) return null;
    return r.map((w) => w.$2 - w.$1).reduce((a, b) => a > b ? a : b);
  }

  /// When [weekday]'s last window ends, in minutes from midnight.
  int? lastEnd(int weekday) {
    final r = ranges(weekday);
    return r.isEmpty ? null : r.last.$2;
  }

  /// The rest days the plan uses: the athlete's own, and, once windows are
  /// set, every day without one.
  List<int> restDaysWith(List<int> restDays) => isEmpty
      ? restDays
      : ({
          ...restDays,
          for (var d = 1; d <= 7; d++)
            if (!hasWindow(d)) d,
        }.toList()..sort());

  /// The longest session each training day has room for, by ISO weekday.
  Map<int, int> dayCapMinutes() => {
    for (var d = 1; d <= 7; d++) d: ?longestMinutes(d),
  };

  List<int> toJson() => masks;

  static TrainingWindows fromJson(Object? json) {
    final list = json is List
        ? json.whereType<num>().map((n) => n.toInt())
        : null;
    if (list == null || list.length != 7) return const TrainingWindows();
    return TrainingWindows(list.toList());
  }

  @override
  bool operator ==(Object other) =>
      other is TrainingWindows &&
      List.generate(7, (i) => masks[i] == other.masks[i]).every((s) => s);

  @override
  int get hashCode => Object.hashAll(masks);
}
