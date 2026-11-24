import 'package:intl/intl.dart' show DateFormat;

import '../db/database.dart';
import '../l10n/app_localizations.dart';
import '../providers/hr_zones_provider.dart';
import '../services/hr_zone_history.dart';

/// Where a zone set came from, in the app language.
String zoneSourceLabel(AppLocalizations l, String method) => switch (method) {
  ZoneMethod.manual => l.zoneSourceManual,
  ZoneMethod.device => l.zoneSourceDevice,
  ZoneMethod.lt1 => l.zoneSourceLt1,
  ZoneMethod.lt2 => l.zoneSourceLt2,
  ZoneMethod.lt2Bike => l.zoneSourceLt2Bike,
  ZoneMethod.derived => l.zoneSourceDerived,
  ZoneMethod.estimate => l.zoneSourceEstimate,
  ZoneMethod.resolved => l.zoneSourceResolved,
  _ => l.zoneSourceInitial,
};

/// Since when a zone set is in force: "von Beginn an" for the first ones.
String zoneSinceText(AppLocalizations l, HrZoneDefinition d) =>
    d.effectiveFrom.millisecondsSinceEpoch <= 0
    ? l.hrZoneFromStart
    : l.hrZoneSince(DateFormat.yMMMd().format(d.effectiveFrom));

/// "von deiner Uhr · ab 23. Nov. 2026" for the zones of [sport] in force.
String? zoneOriginText(AppLocalizations l, HrZonesState state, String sport) {
  final d = state.book.latest(sport);
  if (d == null) return null;
  return '${zoneSourceLabel(l, d.method)} · ${zoneSinceText(l, d)}';
}

String zoneSportName(AppLocalizations l, String sport) => switch (sport) {
  'cycling' => l.cycling,
  'swimming' => l.swimming,
  _ => l.running,
};

/// The hint when [sport]'s zones look wrong (HrZonesState.check), or null.
String? zoneCheckText(AppLocalizations l, HrZonesState state, String sport) =>
    switch (state.check(sport)) {
      'cyclingAboveRunning' => l.hrZoneCyclingAboveRunning,
      'estimate' => l.hrZoneFarFromEstimate(
        zoneSportName(l, sport),
        state.estimateFor(sport)!.join(' · '),
      ),
      _ => null,
    };
