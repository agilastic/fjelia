import 'package:fjelia_core/services/strength/strength_progression.dart';

import '../../l10n/l10n_ext.dart';

export 'package:fjelia_core/services/strength/strength_progression.dart';

extension StrengthProgressionReasonText on StrengthProgressionEvaluation {
  /// Why, in words fit for the athlete.
  String get reason => switch (why) {
    StrengthProgressionReason.straightSetsOnly =>
      tr.loadSuggestionsCoverStraightSets,
    StrengthProgressionReason.tooFewSessions =>
      tr.needsStrengthprogressionminsessionsRecordedSessionsOf(
        strengthProgressionMinSessions,
      ),
    StrengthProgressionReason.historyStale => tr.recentHistoryIsTooOld,
    StrengthProgressionReason.noCommonLoad => tr.theLastSessionDidNot,
    StrengthProgressionReason.fewerSets =>
      'A recent session had fewer sets than programmed.',
    StrengthProgressionReason.incompleteSets =>
      'A recent session has partial, failed, skipped or unrecorded sets.',
    StrengthProgressionReason.loadChanged => tr.theLoadChangedBetweenThe,
    StrengthProgressionReason.repsShort => tr.notEverySetReachedThe,
    StrengthProgressionReason.effortMissing => tr.recordEffortRirOrRpe,
    StrengthProgressionReason.tooHard => tr.recentSetsWereHarderThan,
    StrengthProgressionReason.loadAlreadySet => tr.thisWorkoutAlreadyHasIts,
    StrengthProgressionReason.blocked =>
      '$blockedBy: the load stays as programmed.',
    StrengthProgressionReason.needsIncrement => tr.yourRecentSetsMetThe,
    StrengthProgressionReason.propose =>
      "Your recent comparable sets met this programme's progression rule. "
          'Review the next available load increment.',
  };
}
