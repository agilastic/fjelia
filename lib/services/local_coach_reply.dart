import 'package:fjelia_core/services/local_coach_reply.dart' as core;

import '../l10n/app_localizations.dart';
import 'briefing_brief.dart';

export 'package:fjelia_core/services/local_coach_reply.dart'
    show localCoachReplyIssue;

class _LocalCoachTexts implements core.LocalCoachTexts {
  const _LocalCoachTexts(this.l);
  final AppLocalizations l;

  @override
  String get coachDataFallback => l.coachDataFallback;

  @override
  String get coachSevenDayAverage => l.coachSevenDayAverage;

  @override
  String get currentEnergy => l.currentEnergy;

  @override
  String get cycling => l.cycling;

  @override
  String get hrvSleep => l.hrvSleep;

  @override
  String get restingHr => l.restingHr;

  @override
  String get running => l.running;

  @override
  String get sleep => l.sleep;

  @override
  String get stress => l.stress;

  @override
  String get swimming => l.swimming;

  @override
  String get typeBloodPressure => l.typeBloodPressure;

  @override
  String coachCurrentForm(String value) => l.coachCurrentForm(value);

  @override
  String coachSleepNeedAndShortfall(String need, String shortfall) =>
      l.coachSleepNeedAndShortfall(need, shortfall);

  @override
  String raceGoalsLength(Object length) => l.raceGoalsLength(length);

  @override
  String? plannedTodaySentence(BriefingBrief brief) =>
      brief.plannedTodaySentence(l);
}

String localCoachDataSummary(
  String context,
  AppLocalizations l,
  String locale,
) => core.localCoachDataSummary(context, _LocalCoachTexts(l), locale);

/// The app supplies the complete list when a local answer about goals omits
/// entries.
String completeLocalCoachCalendar(
  String reply,
  String context,
  String question,
  AppLocalizations l,
  String locale,
) => core.completeLocalCoachCalendar(
  reply,
  context,
  question,
  _LocalCoachTexts(l),
  locale,
);

String localCoachCalendarSummary(
  String context,
  AppLocalizations l,
  String locale,
) => core.localCoachCalendarSummary(context, _LocalCoachTexts(l), locale);
