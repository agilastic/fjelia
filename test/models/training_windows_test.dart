import 'package:fjelia_core/models/training_windows.dart';
import 'package:fjelia/services/missed_workout_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// [weekday] open from [from] to [to] (hours, end excluded).
TrainingWindows open(TrainingWindows w, int weekday, double from, double to) {
  for (var s = (from * 2).round(); s < (to * 2).round(); s++) {
    w = w.withSlot(weekday, s, true);
  }
  return w;
}

void main() {
  // Monday: before work and evening; Saturday: a long morning.
  var w = const TrainingWindows();
  w = open(w, 1, 6, 7.5);
  w = open(w, 1, 17, 20);
  w = open(w, 6, 8, 12);

  test('windows read as ranges, longest window and last end', () {
    expect(w.ranges(1), [(360, 450), (1020, 1200)]);
    expect(w.longestMinutes(1), 180);
    expect(w.lastEnd(1), 1200);
    expect(w.longestMinutes(2), isNull);
    expect(w.dayCapMinutes(), {1: 180, 6: 240});
  });

  test('days without a window become rest days, once any is set', () {
    expect(const TrainingWindows().restDaysWith(const [7]), [7]);
    expect(w.restDaysWith(const [7]), [2, 3, 4, 5, 7]);
  });

  test('round trip and erasing', () {
    expect(TrainingWindows.fromJson(w.toJson()), w);
    expect(TrainingWindows.fromJson('bad'), const TrainingWindows());
    final erased = w.withSlot(1, 12, false);
    expect(erased.ranges(1).first, (390, 450));
  });

  test('the reminder comes an hour before the last window ends', () {
    const settings = MissedWorkoutSettings();
    final monday = DateTime(2026, 11, 16);
    expect(
      MissedWorkoutReminderService.dueOn(monday, settings, w),
      DateTime(2026, 11, 16, 19),
    );
    // A day without a window keeps the set time.
    final tuesday = DateTime(2026, 11, 17);
    expect(
      MissedWorkoutReminderService.dueOn(tuesday, settings, w),
      DateTime(2026, 11, 17, 19, 30),
    );
  });
}
