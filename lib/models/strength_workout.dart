import 'package:fjelia_core/models/strength_workout.dart';

import '../l10n/l10n_ext.dart';

export 'package:fjelia_core/models/strength_workout.dart';

/// Text for the strength model from fjelia_core, in the app language.

extension StrengthSetKindLabel on StrengthSetKind {
  String get label => switch (this) {
    StrengthSetKind.warmup => tr.enumWarmUp,
    StrengthSetKind.working => tr.enumWorking,
    StrengthSetKind.backoff => tr.enumBackOff,
    StrengthSetKind.technique => tr.enumTechnique,
  };
}

extension StrengthLoadKindLabel on StrengthLoadKind {
  String get label => switch (this) {
    StrengthLoadKind.external => tr.enumExternalLoad,
    StrengthLoadKind.bodyweight => tr.bodyweight,
    StrengthLoadKind.added => tr.addedLoad,
    StrengthLoadKind.assisted => tr.assistance,
    StrengthLoadKind.band => tr.enumBandResistance,
  };
}

extension StrengthLoadBasisLabel on StrengthLoadBasis {
  String get label => switch (this) {
    StrengthLoadBasis.total => tr.enumTotalLoad,
    StrengthLoadBasis.perImplement => tr.enumPerImplement,
    StrengthLoadBasis.single => tr.enumOneImplement,
  };
}

extension StrengthSideLabel on StrengthSide {
  String get label => switch (this) {
    StrengthSide.bilateral => tr.enumBothSides,
    StrengthSide.unilateral => tr.repsPerSide,
    StrengthSide.alternating => tr.enumAlternatingTotalReps,
  };
}

extension StrengthSetStatusLabel on StrengthSetStatus {
  String get label => switch (this) {
    StrengthSetStatus.unrecorded => tr.notRecorded,
    StrengthSetStatus.completed => tr.done,
    StrengthSetStatus.partial => tr.enumPartial,
    StrengthSetStatus.failed => tr.enumFailed,
    StrengthSetStatus.skipped => tr.skipped,
  };
}

extension StrengthBlockKindLabel on StrengthBlockKind {
  String get label => switch (this) {
    StrengthBlockKind.straight => tr.enumStraightSets,
    StrengthBlockKind.superset => tr.enumSuperset,
    StrengthBlockKind.circuit => tr.enumCircuit,
  };
}

extension StrengthEffortScaleLabel on StrengthEffortScale {
  String get label => switch (this) {
    StrengthEffortScale.rir => tr.enumRir,
    StrengthEffortScale.rpe => tr.enumRpe110,
  };
}

extension StrengthConventionText on StrengthConvention {
  String get text => [
    loadKind.label,
    if (loadKind.hasKg) basis.label,
    if (basis == StrengthLoadBasis.perImplement) '× $implements',
    if (side != StrengthSide.bilateral) side.label,
  ].join(' · ');
}

extension StrengthEffortError on StrengthEffort {
  String? get error => issue?.text;
}

extension StrengthIssueText on StrengthIssue {
  String get text {
    final base = switch (kind) {
      StrengthIssueKind.repetitionsNegative => tr.repetitionsCannotBeNegative,
      StrengthIssueKind.repRangeIncomplete =>
        'A rep range needs a lowest and a highest value.',
      StrengthIssueKind.repRangeInverted => 'The rep range is inverted.',
      StrengthIssueKind.repsAndRange =>
        'Use either exact repetitions or a range.',
      StrengthIssueKind.timedWorkTooShort => tr.timedWorkMustBeLonger,
      StrengthIssueKind.repsAndTime => tr.chooseRepetitionsOrTimedWork,
      StrengthIssueKind.workingSetWithoutTarget =>
        'A working set needs repetitions, a range or a duration.',
      StrengthIssueKind.restNegative => tr.restCannotBeNegative,
      StrengthIssueKind.loadInvalid => tr.loadMustBeAFinite,
      StrengthIssueKind.loadWithoutKg => '${loadKind!.label} has no kg load.',
      StrengthIssueKind.tempoInvalid =>
        'Tempo has four phases, such as 3-1-1-0.',
      StrengthIssueKind.effortNotANumber => tr.effortMustBeANumber,
      StrengthIssueKind.rirOutOfRange => tr.rirRunsFrom0To,
      StrengthIssueKind.rpeOutOfRange => tr.rpeRunsFrom1To,
      StrengthIssueKind.durationNegative => tr.durationCannotBeNegative,
      StrengthIssueKind.recordedRestWithoutSource =>
        'Recorded rest needs its source.',
      StrengthIssueKind.skippedSetWithWork =>
        'A skipped set has no repetitions or time.',
      StrengthIssueKind.durationEstimateInvalid => tr.theDurationEstimateMustBe,
      StrengthIssueKind.duplicateId => 'Duplicate id $subject.',
      StrengthIssueKind.groupWithoutExercises => 'A group has no exercises.',
      StrengthIssueKind.straightSetsWithSeveralExercises =>
        'Straight sets hold a single exercise.',
      StrengthIssueKind.exerciseWithoutName => 'An exercise has no name.',
      StrengthIssueKind.exerciseWithoutSets => '$subject has no sets.',
      StrengthIssueKind.exerciseWithoutImplement =>
        '$subject: at least one implement.',
      StrengthIssueKind.setsNotRecorded =>
        '$count ${count == 1 ? 'set is' : 'sets are'} '
            'not recorded. Confirm to finish with incomplete data.',
      StrengthIssueKind.rangeNeedsRepsDone => tr.enterTheRepetitionsDoneThe,
      StrengthIssueKind.planWithoutReps =>
        'The plan has no repetitions for this set.',
      StrengthIssueKind.planWithoutLoad => tr.enterTheLoadThePlan,
      StrengthIssueKind.planWithoutResistance => tr.enterTheResistanceThePlan,
    };
    return exercise == null ? base : '$exercise: $base';
  }
}

extension StrengthSetTargetValidation on StrengthSetTarget {
  List<String> validate(StrengthConvention c) => [
    for (final i in issues(c)) i.text,
  ];
}

extension StrengthSetResultValidation on StrengthSetResult {
  List<String> validate(StrengthConvention c) => [
    for (final i in issues(c)) i.text,
  ];
}

extension StrengthWorkoutPlanValidation on StrengthWorkoutPlan {
  /// Every problem that keeps the plan from being saved.
  List<String> validate() => [for (final i in issues()) i.text];
}

extension StrengthActivityLogValidation on StrengthActivityLog {
  List<String> validate() => [for (final i in issues()) i.text];
}

/// Why a set cannot be completed as planned, or null when it can: exact
/// repetitions or a duration, and a known load where the exercise has one.
String? completeAsPlannedBlocker(
  StrengthSetTarget target,
  StrengthConvention c,
) => completeAsPlannedIssue(target, c)?.text;

/// The set recorded exactly as planned. Planned rest is not copied: it was
/// not measured.
StrengthSetResult completedAsPlanned(
  StrengthSetResult result,
  StrengthSetTarget target,
  StrengthConvention c,
) {
  final blocker = completeAsPlannedBlocker(target, c);
  if (blocker != null) throw StrengthValidationException(blocker);
  return withPlannedValues(result, target);
}
