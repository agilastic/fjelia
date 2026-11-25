import 'package:fjelia_core/services/briefing_brief.dart';

import '../l10n/app_localizations.dart';
import '../l10n/plan_text.dart' show absenceKindLabel;
import '../theme/activity_colors.dart';

export 'package:fjelia_core/services/briefing_brief.dart';

/// The briefing in the app language.
extension BriefingBriefText on BriefingBrief {
  /// The order of today's sessions as a sentence in the app language, with
  /// the training windows' times.
  String? orderText(AppLocalizations l) {
    if (order.length < 2) return null;
    final first = BriefingBrief.orderItem(order[0]),
        second = BriefingBrief.orderItem(order[1]);
    String name(({String sport, String minutes, int? start, int? end}) i) =>
        '${_sportName(l, i.sport)} ${i.minutes} min';
    String hm(int m) =>
        '${(m ~/ 60).toString().padLeft(2, '0')}:'
        '${(m % 60).toString().padLeft(2, '0')}';
    String? when(({String sport, String minutes, int? start, int? end}) i) =>
        i.start == null || i.end == null
        ? null
        : '${hm(i.start!)}–${hm(i.end!)}';
    final a = when(first), b = when(second);
    return a == null || b == null
        ? l.briefOrderTwoNoTimes(name(first), name(second))
        : l.briefOrderTwo(name(first), a, name(second), b);
  }

  String? plannedTodaySentence(AppLocalizations l) => away != null
      ? l.briefAwayToday(absenceKindLabel(l, away!))
      : today.isNotEmpty
      ? l.briefPlannedTodayCount(today.length)
      : restDay
      ? l.briefRestDayToday
      : null;

  /// Tomorrow's absence or rest day as a sentence, for the app's own text.
  String? tomorrowSentence(AppLocalizations l) => awayTomorrow != null
      ? l.briefAwayTomorrow(absenceKindLabel(l, awayTomorrow!))
      : tomorrow.isEmpty && restTomorrow
      ? l.briefRestDayTomorrow
      : null;

  /// The plan is a database fact, even when recovery advice suggests reducing
  /// it. A small model must not turn several sessions into one optional idea.
  String scheduleInstruction(AppLocalizations l) {
    final sentence = plannedTodaySentence(l);
    if (sentence != null && away != null) {
      return 'Today the athlete is ${BriefingBrief.awayEnglish(away!)}; the plan holds no training. '
          'Include this exact sentence as one of your sentences: "$sentence" '
          'Do not suggest a workout for today${away == 'illness' || away == 'injury' ? '; recovery comes first' : ''}. ';
    }
    if (sentence != null && today.isEmpty) {
      return 'Today is a planned rest day in the training plan. '
          'Include this exact sentence as one of your sentences: "$sentence" '
          'Do not suggest a workout for today. ';
    }
    return sentence == null
        ? ''
        : 'Today has ${today.length} scheduled ${today.length == 1 ? 'session' : 'sessions'}, not alternatives. '
              'Include this exact sentence as one of your sentences: "$sentence" '
              'The schedule exists even if you recommend reducing it or resting. '
              'Mention the number of sessions ONLY in that sentence, nowhere else. ';
  }

  String _reason(AppLocalizations l, String id) => switch (id) {
    'hrvLow' => l.briefReasonHrvLow,
    'hrvHigh' => l.briefReasonHrvHigh,
    'rhrUp' => l.briefReasonRhrUp,
    'rhrDown' => l.briefReasonRhrDown,
    'sleepShort' => l.briefReasonSleepShort,
    'sleepGood' => l.briefReasonSleepGood,
    'energyLow' => l.briefReasonEnergyLow,
    'energyHigh' => l.briefReasonEnergyHigh,
    'stressHigh' => l.briefReasonStressHigh,
    'respHigh' => l.briefReasonRespHigh,
    'spo2Low' => l.briefReasonSpo2Low,
    'skinTempOff' => l.briefReasonSkinTempOff,
    'formTired' => l.briefReasonFormTired,
    'formVeryTired' => l.briefReasonFormVeryTired,
    'formFresh' => l.briefReasonFormFresh,
    _ => id,
  };

  /// The briefing written by the app, in the app language: used when a model
  /// is not available or its answer is not usable. Short on purpose.
  String localText(AppLocalizations l) {
    final head = switch (readiness) {
      'red' => l.briefHeadRed,
      'yellow' => l.briefHeadYellow,
      _ => l.briefHeadGreen,
    };
    // An open proposal is the advice: the briefing must not tell the athlete
    // to keep a plan the app has just offered to change.
    final advice = switch (proposal) {
      'shorter' => l.briefProposalShorter,
      'rest' => l.briefProposalRest,
      'replan' => l.briefProposalReplan,
      _ => switch (readiness) {
        'red' => l.briefAdviceRed,
        'yellow' => l.briefAdviceYellow,
        _ => l.briefAdviceGreen,
      },
    };
    final reasons = [
      for (final e in (readiness == 'green' ? good.take(2) : findings.take(3)))
        _reason(l, e),
    ];
    final why = reasons.isEmpty
        ? l.briefAllClear
        : l.briefMain(reasons.join(', '));
    // The chest-strap reading is its own remark, not a reason for strain: a
    // rise after the workout is the favourable direction.
    final training = trainingHrv == null
        ? ''
        : ' ${trainingHrv == 'up' ? l.briefTrainingHrvUp : l.briefTrainingHrvDown}';
    final outlookSentence = _outlookText(l, outlook);
    final schedule = plannedTodaySentence(l);
    final back = backFrom == null
        ? null
        : l.briefBackFrom(absenceKindLabel(l, backFrom!));
    final next = tomorrowSentence(l);
    final orderSentence = away == null ? orderText(l) : null;
    return '$head $why$training${outlookSentence == null ? '' : ' $outlookSentence'}'
        '${schedule == null ? '' : ' $schedule'}'
        '${orderSentence == null ? '' : ' $orderSentence'}${back == null ? '' : ' $back'}'
        '${next == null ? '' : ' $next'} $advice';
  }
}

String _sportName(AppLocalizations l, String sport) =>
    switch (activityKind(sport)) {
      ActivityKind.running => l.running,
      ActivityKind.cycling => l.cycling,
      ActivityKind.swimming => l.swimming,
      ActivityKind.strength => l.strength,
      ActivityKind.rowing => l.rowing,
      ActivityKind.hiking => l.hiking,
      ActivityKind.walking => l.walking,
      ActivityKind.yoga => l.yoga,
      ActivityKind.other => l.workout,
    };

/// The outlook as a sentence in the app language.
String? _outlookText(AppLocalizations l, String? id) {
  if (id == null) return null;
  if (id.startsWith('restFixes:')) return l.briefOutlookRest(id.substring(10));
  return switch (id) {
    'needsLongRest' => l.briefOutlookLongRest,
    'planKeepsTired' => l.briefOutlookPlanTired,
    _ => null,
  };
}
