import 'package:fjelia_core/models/calendar_activity.dart';

import '../l10n/l10n_ext.dart';

export 'package:fjelia_core/models/calendar_activity.dart';

extension CalendarActivityLabel on CalendarActivity {
  /// Short status for tooltips and screen readers.
  String get statusLabel => skipped
      ? (skipReason == null ? tr.skipped : '${tr.skipped} · $skipReason')
      : completed
      ? tr.calendarCompleted
      : tr.calendarPlanned;
}
