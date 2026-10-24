import 'package:home_widget/home_widget.dart';

import '../db/database.dart';
import '../providers/training_load_provider.dart';

/// Feeds the iOS home-screen widgets (week load / time / distance).
class WidgetDataService {
  WidgetDataService(this._db);

  final AppDatabase _db;

  static const _appGroup = 'group.de.ebeling-hoppe.fjelia';

  Future<void> push() async {
    await HomeWidget.setAppGroupId(_appGroup);
    await _pushWeekData();
    await HomeWidget.updateWidget(iOSName: 'FjeliaWeekLoadWidget');
    await HomeWidget.updateWidget(iOSName: 'FjeliaWeekTimeWidget');
    await HomeWidget.updateWidget(iOSName: 'FjeliaWeekDistWidget');
  }

  Future<void> _pushWeekData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final activities = await _db.getActivitiesInRange(14);

    final load = List<double>.filled(7, 0);
    final hours = List<double>.filled(7, 0);
    final km = List<double>.filled(7, 0);
    for (final a in activities) {
      final d = a.startDate;
      final day = DateTime(d.year, d.month, d.day);
      if (day.isBefore(monday)) continue;
      final idx = d.weekday - 1;
      if (day.difference(monday).inDays >= 7) continue;
      load[idx] += effectiveLoad(a);
      hours[idx] += a.durationSeconds / 3600.0;
      km[idx] += (a.distanceMeters ?? 0) / 1000.0;
    }

    for (var i = 0; i < 7; i++) {
      await HomeWidget.saveWidgetData<double>('load_d$i', load[i]);
      await HomeWidget.saveWidgetData<double>('time_d$i', hours[i]);
      await HomeWidget.saveWidgetData<double>('dist_d$i', km[i]);
    }
    await HomeWidget.saveWidgetData<int>('today_idx', now.weekday - 1);
    await HomeWidget.saveWidgetData<String>('week_label', _weekLabel(monday));
  }

  String _weekLabel(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    return '${monday.day}.${monday.month} – ${sunday.day}.${sunday.month}';
  }
}
