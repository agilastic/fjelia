import 'package:drift/drift.dart';

import '../models/heart_rate.dart';
import '../services/source_priority_service.dart'
    show SourceGroup, defaultSourcePriorities, shouldOverwrite;

part 'database.g.dart';
part 'summary_metrics.dart';

class SummaryMetricOrigins extends Table {
  TextColumn get summaryTable => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get metric => text()();
  TextColumn get source => text()();
  TextColumn get quality => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {summaryTable, date, metric};
}

class HeartRateSamples extends Table {
  TextColumn get source => text()();
  DateTimeColumn get measuredAt => dateTime()();
  RealColumn get bpm => real()();
  @override
  Set<Column> get primaryKey => {source, measuredAt};
}

class BpMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get measuredAt => dateTime()();
  TextColumn get timezone => text().withDefault(const Constant('UTC'))();
  IntColumn get systolic => integer()();
  IntColumn get diastolic => integer()();
  IntColumn get heartRate => integer()();
  TextColumn get measurementType => text().withDefault(const Constant('POD'))();
  TextColumn get dayNightTag => text().nullable()();
  BoolColumn get isBedTime => boolean().nullable()();
  BoolColumn get isWakeUpTime => boolean().nullable()();
}

class DailyBpSummaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get avgSystolic => real()();
  RealColumn get avgDiastolic => real()();
  RealColumn get avgHeartRate => real()();
  IntColumn get maxSystolic => integer()();
  IntColumn get minSystolic => integer()();
  IntColumn get count => integer()();
  RealColumn get normalBpPercent => real().nullable()();
  TextColumn get trend => text().nullable()();
  TextColumn get rawJson => text()();
}

class HrvRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get hrvLastNight => real().nullable()();
  RealColumn get hrvWeeklyAvg => real().nullable()();
  IntColumn get restingHeartRate => integer().nullable()();
  RealColumn get stressLevel => real().nullable()();
  RealColumn get bodyBattery => real().nullable()();
  RealColumn get computedEnergie => real().nullable()();
  RealColumn get spo2 => real().nullable()();
  RealColumn get respirationRate => real().nullable()();
  RealColumn get skinTempDelta => real().nullable()();
  TextColumn get hrvIntradayJson => text().nullable()();
  TextColumn get source => text().nullable()();
}

class SleepRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalSleepSeconds => integer()();
  IntColumn get deepSleepSeconds => integer()();
  IntColumn get remSleepSeconds => integer()();
  IntColumn get lightSleepSeconds => integer()();
  IntColumn get awakeSleepSeconds => integer()();
  RealColumn get sleepScore => real().nullable()();
  DateTimeColumn get sleepStart => dateTime().nullable()();
  DateTimeColumn get sleepEnd => dateTime().nullable()();
  TextColumn get phasesJson => text().nullable()();
  RealColumn get avgOvernightHrv => real().nullable()();
  IntColumn get sleepNeedSeconds => integer().nullable()();
  TextColumn get source => text().nullable()();
}

class WellnessRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get steps => integer().nullable()();
  IntColumn get activeCalories => integer().nullable()();
  IntColumn get totalCalories => integer().nullable()();
  IntColumn get floorsAscended => integer().nullable()();
  RealColumn get intensityMinutes => real().nullable()();
  RealColumn get averageStress => real().nullable()();
  RealColumn get bodyBatteryHighest => real().nullable()();
  RealColumn get bodyBatteryLowest => real().nullable()();
  IntColumn get bodyBatteryCharged => integer().nullable()();
  IntColumn get bodyBatteryDrained => integer().nullable()();
  TextColumn get bodyBatteryJson => text().nullable()();
  RealColumn get vo2max => real().nullable()();
  RealColumn get fitnessAge => real().nullable()();
  RealColumn get avgSpo2 => real().nullable()();
  TextColumn get source => text().nullable()();
  RealColumn get vo2maxCycling => real().nullable()();
}

class RenphoRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get measuredAt => dateTime().unique()();
  TextColumn get scaleName => text().nullable()();
  RealColumn get weight => real().nullable()();
  RealColumn get bmi => real().nullable()();
  RealColumn get bodyFat => real().nullable()();
  RealColumn get bodyWater => real().nullable()();
  RealColumn get muscleMass => real().nullable()();
  RealColumn get boneMass => real().nullable()();
  RealColumn get bmr => real().nullable()();
  RealColumn get visceralFat => real().nullable()();
  RealColumn get subcutaneousFat => real().nullable()();
  RealColumn get protein => real().nullable()();
  RealColumn get bodyAge => real().nullable()();
  RealColumn get leanBodyMass => real().nullable()();
  RealColumn get fatFreeWeight => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  IntColumn get heartRate => integer().nullable()();
  RealColumn get cardiacIndex => real().nullable()();
  TextColumn get bodyShape => text().nullable()();
  TextColumn get rawJson => text()();
}

class ActivityRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get activityId => text().unique()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  DateTimeColumn get startDate => dateTime()();
  IntColumn get durationSeconds => integer()();
  RealColumn get distanceMeters => real().nullable()();
  RealColumn get avgHeartRate => real().nullable()();
  RealColumn get maxHeartRate => real().nullable()();
  RealColumn get trainingLoad => real().nullable()();
  RealColumn get avgWatts => real().nullable()();
  RealColumn get totalElevation => real().nullable()();
  TextColumn get hrZonesJson => text().nullable()();
  TextColumn get gpxJson => text().nullable()();
  TextColumn get metricsJson => text().nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get plannedWorkoutName => text().nullable()();
  IntColumn get plannedDurationSeconds => integer().nullable()();
  RealColumn get plannedDistanceMeters => real().nullable()();
  TextColumn get plannedStepsJson => text().nullable()();
  RealColumn get aerobicTrainingEffect => real().nullable()();
  RealColumn get anaerobicTrainingEffect => real().nullable()();
  IntColumn get recoveryTimeSeconds => integer().nullable()();
  TextColumn get activityFeedbackPhrase => text().nullable()();
  RealColumn get avgRunCadence => real().nullable()();
  RealColumn get vo2maxActivity => real().nullable()();
  IntColumn get movingDurationSeconds => integer().nullable()();
}

class DayScoreRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  RealColumn get recoveryScore => real().nullable()();
  RealColumn get sleepScore => real().nullable()();
  RealColumn get strainScore => real().nullable()();
  RealColumn get bpScore => real().nullable()();
  RealColumn get readinessScore => real().nullable()();
  TextColumn get recoveryLevel => text().nullable()();
  TextColumn get recommendation => text().nullable()();
}

class SpotHrvMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  TextColumn get context => text()();
  TextColumn get posture => text()();
  IntColumn get durationSeconds => integer()();
  IntColumn get settleSeconds => integer()();
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();
  RealColumn get rmssdMs => real()();
  RealColumn get rawRmssdMs => real().nullable()();
  RealColumn get sdnnMs => real()();
  RealColumn get meanHr => real()();
  RealColumn get lnRmssd => real().nullable()();
  IntColumn get acceptedIntervals => integer()();
  IntColumn get totalIntervals => integer()();
  RealColumn get coverage => real()();
  TextColumn get rrJson => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get minutesAfterTraining => integer().nullable()();
}

class GripStrengthRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get measuredAt => dateTime()();
  RealColumn get leftKg => real().nullable()();
  RealColumn get rightKg => real().nullable()();
}

class OcrMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get measuredAt => dateTime()();
  TextColumn get deviceType => text()();
  TextColumn get rawOcrText => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get systolic => integer().nullable()();
  IntColumn get diastolic => integer().nullable()();
  IntColumn get heartRate => integer().nullable()();
  RealColumn get spo2 => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get rawValuesJson => text().nullable()();
}

class ScheduledWorkoutRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get workoutId => text()();
  TextColumn get scheduleId => text().unique()();
  TextColumn get trainingPlanId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get sportType => text()();
  DateTimeColumn get scheduledDate => dateTime()();
  IntColumn get estimatedDurationSeconds => integer().nullable()();
  RealColumn get estimatedDistanceMeters => real().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get itemType => text().nullable()();
  TextColumn get seriesName => text().nullable()();
  TextColumn get stepsJson => text().nullable()();
  TextColumn get userNote => text().nullable()();
}

class WeatherSnapshotRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cacheKey => text().unique()();
  TextColumn get source => text()();
  DateTimeColumn get observedAt => dateTime()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get temperatureC => real()();
  RealColumn get humidityPct => real()();
  RealColumn get pressureHpa => real().nullable()();
  RealColumn get wetBulbC => real()();
  TextColumn get rawJson => text()();
}

class HeatWorkoutContexts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get activityId => text().unique()();
  DateTimeColumn get activityStart => dateTime()();
  TextColumn get source => text()();
  BoolColumn get isOutdoor => boolean()();
  BoolColumn get qualifies => boolean()();
  RealColumn get durationMinutes => real()();
  RealColumn get temperatureC => real().nullable()();
  RealColumn get humidityPct => real().nullable()();
  RealColumn get pressureHpa => real().nullable()();
  RealColumn get wetBulbC => real().nullable()();
  RealColumn get scoreBefore => real()();
  RealColumn get scoreAfter => real()();
  TextColumn get weatherCacheKey => text().nullable()();
  TextColumn get rawJson => text().nullable()();
}

class HeatDailyStateRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  RealColumn get score => real()();
  TextColumn get status => text()();
  RealColumn get decayApplied => real()();
  RealColumn get workoutGain => real()();
  TextColumn get lastActivityId => text().nullable()();
  TextColumn get recommendation => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}

class ThresholdRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get activityId => text()();
  TextColumn get source => text()();
  IntColumn get lt1Bpm => integer().nullable()();
  IntColumn get lt2Bpm => integer().nullable()();
  IntColumn get lt2PaceSec => integer().nullable()();
  IntColumn get vo2PaceSec => integer().nullable()();
  IntColumn get ftpWatts => integer().nullable()();
}

class RaceGoals extends Table {
  TextColumn get id => text()();
  TextColumn get athleteId => text()();
  TextColumn get name => text()();
  TextColumn get primarySport => text()();
  RealColumn get distanceM => real()();
  IntColumn get targetFinishSeconds => integer().nullable()();
  DateTimeColumn get raceDate => dateTime()();
  TextColumn get priority => text()();
  RealColumn get elevationM => real().nullable()();
  TextColumn get source => text()();
  TextColumn get garminEventId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TrainingPlans extends Table {
  TextColumn get id => text()();
  TextColumn get athleteId => text()();
  TextColumn get coachId => text().nullable()();
  TextColumn get raceGoalId => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get status => text()();
  DateTimeColumn get generatedAt => dateTime()();
  DateTimeColumn get lastReplannedAt => dateTime().nullable()();
  TextColumn get replannedReason => text().nullable()();
  IntColumn get daysPerWeek => integer().withDefault(const Constant(5))();
  TextColumn get restDaysJson => text().nullable()();
  TextColumn get strengthDaysJson => text().nullable()();
  RealColumn get hoursPerWeek => real().withDefault(const Constant(8.0))();

  @override
  Set<Column> get primaryKey => {id};
}

class TrainingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();
  TextColumn get athleteId => text()();
  TextColumn get coachId => text().nullable()();
  DateTimeColumn get sessionDate => dateTime()();
  TextColumn get preferredTimeOfDay => text().nullable()();
  IntColumn get sessionNumber => integer()();
  IntColumn get weekNumber => integer()();
  TextColumn get sport => text()();
  TextColumn get sessionType => text()();
  TextColumn get subType => text().nullable()();
  TextColumn get phase => text()();
  IntColumn get primaryZone => integer()();
  TextColumn get title => text()();
  TextColumn get sessionNotes => text().nullable()();
  TextColumn get athleteNotes => text().nullable()();
  TextColumn get warmUp => text().nullable()();
  TextColumn get mainSet => text().nullable()();
  TextColumn get coolDown => text().nullable()();
  IntColumn get warmUpDurationMin => integer().nullable()();
  TextColumn get stepsJson => text().nullable()();
  TextColumn get plannedZonesJson => text().nullable()();
  TextColumn get hrRangesJson => text().nullable()();
  TextColumn get paceRangesJson => text().nullable()();
  TextColumn get powerRangesJson => text().nullable()();
  IntColumn get plannedDurationMin => integer()();
  IntColumn get plannedTrimp => integer()();
  IntColumn get sessionLevel => integer()();
  IntColumn get originalSessionLevel => integer().nullable()();
  BoolColumn get tspAdjusted => boolean().withDefault(const Constant(false))();
  TextColumn get adaptationTrigger => text().nullable()();
  TextColumn get originalSessionId => text().nullable()();
  TextColumn get garminWorkoutId => text().nullable()();
  TextColumn get garminAlternativeId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('planned'))();
  RealColumn get warmUpCompletionPct => real().nullable()();
  RealColumn get mainSetCompletionPct => real().nullable()();
  BoolColumn get createdByCoach =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get adjustedByCoach =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get addedByAthlete =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get historical => boolean().withDefault(const Constant(false))();
  BoolColumn get indoor => boolean().withDefault(const Constant(false))();
  TextColumn get sessionLocation => text().nullable()();

  /// 'hr' or 'power': the main target of a ride; null until chosen.
  TextColumn get targetMetric => text().nullable()();
  TextColumn get sessionStackName => text().nullable()();
  TextColumn get multiSportWorkoutId => text().nullable()();
  BoolColumn get isMovedFromDifferentWeek =>
      boolean().withDefault(const Constant(false))();
  TextColumn get priorSessionDate => text().nullable()();
  IntColumn get actualDurationMin => integer().nullable()();
  DateTimeColumn get dateModified => dateTime().nullable()();
  TextColumn get modifiedBy => text().nullable()();
  TextColumn get sessionDateOriginal => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SessionActuals extends Table {
  TextColumn get sessionId => text()();
  IntColumn get z1ActualSeconds => integer().withDefault(const Constant(0))();
  IntColumn get z2ActualSeconds => integer().withDefault(const Constant(0))();
  IntColumn get z3ActualSeconds => integer().withDefault(const Constant(0))();
  IntColumn get z4ActualSeconds => integer().withDefault(const Constant(0))();
  IntColumn get z5ActualSeconds => integer().withDefault(const Constant(0))();
  IntColumn get z6ActualSeconds => integer().withDefault(const Constant(0))();
  IntColumn get executionScore => integer().nullable()();
  RealColumn get durationRatio => real().nullable()();
  RealColumn get tssRatio => real().nullable()();
  BoolColumn get scoredVsAdapted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get adaptedTargetsJson => text().nullable()();
  IntColumn get avgHrBpm => integer().nullable()();
  IntColumn get maxHrBpm => integer().nullable()();
  RealColumn get avgPaceSecPerKm => real().nullable()();
  IntColumn get avgPowerWatts => integer().nullable()();
  IntColumn get normalizedPowerWatts => integer().nullable()();
  RealColumn get intensityFactor => real().nullable()();
  IntColumn get rpe => integer().nullable()();
  TextColumn get skipReason => text().nullable()();
  RealColumn get polarizationIndex => real().nullable()();
  TextColumn get executionVerdict => text().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// The activity that completed the session. One activity completes at most
  /// one session (a unique index); null for skips and for completions from
  /// before the link existed.
  TextColumn get activityId => text().nullable()();

  @override
  Set<Column> get primaryKey => {sessionId};
}

class SessionNts extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().unique()();
  TextColumn get ntsType => text()();
  IntColumn get intensityTypeId => integer().nullable()();
  RealColumn get nts => real().withDefault(const Constant(0.0))();
  RealColumn get ntsz1 => real().withDefault(const Constant(0.0))();
  RealColumn get ntsz2 => real().withDefault(const Constant(0.0))();
  RealColumn get ntsz3 => real().withDefault(const Constant(0.0))();
  RealColumn get ntsz4 => real().withDefault(const Constant(0.0))();
  RealColumn get ntsz5 => real().withDefault(const Constant(0.0))();
  RealColumn get ntsz6 => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

class SessionXp extends Table {
  TextColumn get sessionId => text()();
  IntColumn get earnedPoints => integer().withDefault(const Constant(0))();
  IntColumn get possiblePoints => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {sessionId};
}

class DailyReadinessRecords extends Table {
  TextColumn get id => text()();
  TextColumn get athleteId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get hrv7dBaseline => real().nullable()();
  RealColumn get hrvToday => real().nullable()();
  RealColumn get hrvDropPct => real().nullable()();
  RealColumn get restingHr7dBaseline => real().nullable()();
  RealColumn get restingHrToday => real().nullable()();
  RealColumn get restingHrElevation => real().nullable()();
  IntColumn get sleepScore => integer().nullable()();
  IntColumn get bodyBattery => integer().nullable()();
  RealColumn get skinTempDelta => real().nullable()();
  RealColumn get tsb => real().nullable()();
  BoolColumn get flagHrv => boolean().withDefault(const Constant(false))();
  BoolColumn get flagHr => boolean().withDefault(const Constant(false))();
  BoolColumn get flagSleep => boolean().withDefault(const Constant(false))();
  BoolColumn get flagBattery => boolean().withDefault(const Constant(false))();
  BoolColumn get flagSkinTemp => boolean().withDefault(const Constant(false))();
  BoolColumn get flagFatigue => boolean().withDefault(const Constant(false))();
  IntColumn get flagCount => integer().withDefault(const Constant(0))();
  TextColumn get level => text()();
  BoolColumn get athleteOverrode =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SessionAdaptations extends Table {
  TextColumn get id => text()();
  TextColumn get originalSessionId => text()();
  TextColumn get adaptedSessionId => text()();
  DateTimeColumn get adaptedAt => dateTime()();
  TextColumn get readinessLevel => text()();
  IntColumn get flagCount => integer()();
  TextColumn get flagsFiredJson => text()();
  IntColumn get originalSessionLevel => integer()();
  IntColumn get adaptedSessionLevel => integer()();
  IntColumn get originalDurationMin => integer()();
  IntColumn get adaptedDurationMin => integer()();
  TextColumn get zoneShiftJson => text().nullable()();
  IntColumn get executionScore => integer().nullable()();
  IntColumn get rpe => integer().nullable()();
  BoolColumn get athleteOverrode => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WeekSummaries extends Table {
  TextColumn get athleteId => text()();
  DateTimeColumn get weekStart => dateTime()();
  IntColumn get weekNumber => integer()();
  TextColumn get phase => text()();
  BoolColumn get isRecoveryWeek =>
      boolean().withDefault(const Constant(false))();
  IntColumn get plannedTrimp => integer().withDefault(const Constant(0))();
  IntColumn get actualTrimp => integer().withDefault(const Constant(0))();
  IntColumn get sessionsPlanned => integer().withDefault(const Constant(0))();
  IntColumn get sessionsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get sessionsMissed => integer().withDefault(const Constant(0))();
  IntColumn get sessionsAdapted => integer().withDefault(const Constant(0))();
  RealColumn get atl => real().nullable()();
  RealColumn get ctl => real().nullable()();
  RealColumn get tsb => real().nullable()();
  IntColumn get weeklyXpEarned => integer().withDefault(const Constant(0))();
  IntColumn get weeklyXpPossible => integer().withDefault(const Constant(0))();
  RealColumn get weeklyNtsz1 => real().withDefault(const Constant(0.0))();
  RealColumn get weeklyNtsz2 => real().withDefault(const Constant(0.0))();
  RealColumn get weeklyNtsz3 => real().withDefault(const Constant(0.0))();
  RealColumn get weeklyNtsz4 => real().withDefault(const Constant(0.0))();
  RealColumn get weeklyNtsz5 => real().withDefault(const Constant(0.0))();
  RealColumn get weeklyNtsz6 => real().withDefault(const Constant(0.0))();
  IntColumn get greenDays => integer().withDefault(const Constant(0))();
  IntColumn get yellowDays => integer().withDefault(const Constant(0))();
  IntColumn get redDays => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {athleteId, weekStart};
}

class AthleteThresholds extends Table {
  TextColumn get athleteId => text()();
  IntColumn get thresholdHrBpm => integer().nullable()();
  RealColumn get thresholdPaceMps => real().nullable()();
  IntColumn get maxHrBpm => integer().nullable()();
  IntColumn get ftpWatts => integer().nullable()();
  IntColumn get thresholdHrCyclingBpm => integer().nullable()();
  RealColumn get cssPerHundredM => real().nullable()();
  IntColumn get thresholdHrSwimBpm => integer().nullable()();
  RealColumn get threshold500mSplitSec => real().nullable()();
  IntColumn get thresholdHrRowingBpm => integer().nullable()();
  IntColumn get strengthWorkingHrBpm => integer().nullable()();
  TextColumn get runHrZonesJson => text().nullable()();
  TextColumn get bikeHrZonesJson => text().nullable()();
  TextColumn get swimHrZonesJson => text().nullable()();
  TextColumn get runPaceZonesJson => text().nullable()();
  TextColumn get swimCssZonesJson => text().nullable()();
  TextColumn get bikePowerZonesJson => text().nullable()();
  RealColumn get estimatedFtp => real().nullable()();
  RealColumn get eFtpDelta => real().nullable()();
  DateTimeColumn get lastUpdatedAt => dateTime().nullable()();
  BoolColumn get coachLocked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {athleteId};
}

class CoachProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get bio => text().nullable()();
  TextColumn get profileImageUrl => text().nullable()();
  TextColumn get specialtiesJson => text().nullable()();
  TextColumn get certificationsJson => text().nullable()();
  TextColumn get languagesJson => text().nullable()();
  TextColumn get country => text().nullable()();
  RealColumn get monthlyFeeUsd => real().nullable()();
  IntColumn get maxAthletes => integer().withDefault(const Constant(20))();
  IntColumn get currentAthleteCount =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();
  RealColumn get averageRating => real().withDefault(const Constant(0.0))();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  TextColumn get stripeAccountId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CoachAthleteRelations extends Table {
  TextColumn get id => text()();
  TextColumn get coachId => text()();
  TextColumn get athleteId => text()();
  TextColumn get assistantCoachId => text().nullable()();
  TextColumn get status => text()();
  TextColumn get planAccess => text()();
  TextColumn get dataAccess => text()();
  RealColumn get monthlyFeeUsd => real().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get coachNotes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CoachNotes extends Table {
  TextColumn get id => text()();
  TextColumn get coachId => text()();
  TextColumn get athleteId => text()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get content => text()();
  TextColumn get type => text()();
  BoolColumn get isVisibleToAthlete =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CoachReviews extends Table {
  TextColumn get id => text()();
  TextColumn get coachId => text()();
  TextColumn get athleteId => text()();
  IntColumn get rating => integer()();
  TextColumn get comment => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get sport => text()();
  TextColumn get sessionType => text()();
  TextColumn get subType => text().nullable()();
  TextColumn get targetPhase => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get coachingCues => text().nullable()();
  TextColumn get stepsJson => text()();
  TextColumn get parameterizedFor => text()();
  IntColumn get estimatedDurationMin => integer()();
  IntColumn get estimatedTss => integer()();
  TextColumn get tagsJson => text().nullable()();
  TextColumn get source => text()();
  TextColumn get createdByCoachId => text().nullable()();
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    BpMeasurements,
    HeartRateSamples,
    SummaryMetricOrigins,
    DailyBpSummaries,
    HrvRecords,
    SleepRecords,
    WellnessRecords,
    RenphoRecords,
    ActivityRecords,
    DayScoreRecords,
    GripStrengthRecords,
    SpotHrvMeasurements,
    OcrMeasurements,
    ScheduledWorkoutRecords,
    WeatherSnapshotRecords,
    HeatWorkoutContexts,
    HeatDailyStateRecords,
    ThresholdRecords,
    RaceGoals,
    TrainingPlans,
    TrainingSessions,
    SessionActuals,
    SessionNts,
    SessionXp,
    DailyReadinessRecords,
    SessionAdaptations,
    WeekSummaries,
    AthleteThresholds,
    CoachProfiles,
    CoachAthleteRelations,
    CoachNotes,
    CoachReviews,
    WorkoutTemplates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(
    super.e, {
    Future<List<String>> Function(SourceGroup)? metricPriorityReader,
  }) : _metricPriorityReader = metricPriorityReader ?? _defaultMetricPriority;
  final Future<List<String>> Function(SourceGroup) _metricPriorityReader;
  static Future<List<String>> _defaultMetricPriority(SourceGroup group) async =>
      defaultSourcePriorities[group.name]!;

  @override
  int get schemaVersion => 46;

  Future<void> saveHeartRateSamples(List<TimedHeartRate> samples) async {
    if (samples.isEmpty) return;
    await batch(
      (b) => b.insertAllOnConflictUpdate(heartRateSamples, [
        for (final s in samples)
          if (s.bpm.isFinite && s.bpm > 0)
            HeartRateSamplesCompanion.insert(
              source: s.source,
              measuredAt: s.timestamp,
              bpm: s.bpm,
            ),
      ]),
    );
  }

  Future<List<HeartRateSample>> getHeartRateSamples(
    DateTime start,
    DateTime end,
  ) =>
      (select(heartRateSamples)
            ..where(
              (t) =>
                  t.measuredAt.isBiggerOrEqualValue(start) &
                  t.measuredAt.isSmallerThanValue(end),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.measuredAt)]))
          .get();

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  // ── HRV ──────────────────────────────────────────────────────────────────

  Future<void> upsertHrv(
    HrvRecordsCompanion entry, {
    Map<String, String> metricSources = const {},
  }) => _mergeSummary(
    hrvRecords,
    entry.date.value,
    entry.toColumns(true),
    SourceGroup.sleep,
    metricSources: metricSources,
  );

  Future<HrvRecord?> getHrvForDate(DateTime date) {
    final start = _dayStart(date);
    final end = start.add(const Duration(days: 1));
    return (select(hrvRecords)
          ..where(
            (t) =>
                (t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end)),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<HrvRecord>> getHrvRange(int days) {
    final since = DateTime.now().subtract(Duration(days: days));
    return (select(hrvRecords)
          ..where((t) => t.date.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.date)]))
        .get();
  }

  Future<void> updateHrvEnergie(DateTime date, int energie) => upsertHrv(
    HrvRecordsCompanion(
      date: Value(_dayStart(date)),
      computedEnergie: Value(energie.toDouble()),
    ),
    metricSources: const {'computed_energie': 'computed'},
  );

  // ── Sleep ────────────────────────────────────────────────────────────────

  Future<void> upsertSleep(
    SleepRecordsCompanion entry, {
    Map<String, String> metricSources = const {},
  }) => _mergeSummary(
    sleepRecords,
    entry.date.value,
    entry.toColumns(true),
    SourceGroup.sleep,
    metricSources: metricSources,
  );

  Future<SleepRecord?> getSleepForDate(DateTime date) {
    final start = _dayStart(date);
    final end = start.add(const Duration(days: 1));
    return (select(sleepRecords)
          ..where(
            (t) =>
                (t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end)),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<SleepRecord>> getSleepRange(int days) {
    final since = DateTime.now().subtract(Duration(days: days));
    return (select(sleepRecords)
          ..where((t) => t.date.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.date)]))
        .get();
  }

  // ── Wellness ─────────────────────────────────────────────────────────────

  Future<WellnessRecord?> getWellnessForDate(DateTime date) {
    final start = _dayStart(date);
    final end = start.add(const Duration(days: 1));
    return (select(wellnessRecords)
          ..where(
            (t) =>
                (t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end)),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsertWellness(
    WellnessRecordsCompanion entry, {
    Map<String, String> metricSources = const {},
  }) => _mergeSummary(
    wellnessRecords,
    entry.date.value,
    entry.toColumns(true),
    SourceGroup.body,
    metricSources: metricSources,
  );

  Future<List<WellnessRecord>> getWellnessRange(int days) {
    final since = DateTime.now().subtract(Duration(days: days));
    return (select(wellnessRecords)
          ..where((t) => t.date.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.date)]))
        .get();
  }

  Future<void> updateWellnessVo2max(
    DateTime date, {
    required String source,
    double? vo2max,
    double? vo2maxCycling,
    double? fitnessAge,
  }) => upsertWellness(
    WellnessRecordsCompanion(
      date: Value(_dayStart(date)),
      source: Value(source),
      vo2max: Value(vo2max),
      vo2maxCycling: Value(vo2maxCycling),
      fitnessAge: Value(fitnessAge),
    ),
  );

  // ── Activities ───────────────────────────────────────────────────────────

  /// Removes duplicate workouts imported from several sources. Two activities
  /// are the same when they start within 60 s of each other and their
  /// durations differ by at most 2 %. The Health Connect copy is dropped.
  Future<int> deduplicateActivities() async {
    final all = await (select(
      activityRecords,
    )..orderBy([(t) => OrderingTerm(expression: t.startDate)])).get();
    final toDelete = <String>{};
    for (var i = 0; i < all.length; i++) {
      final a = all[i];
      if (toDelete.contains(a.activityId)) continue;
      for (var j = i + 1; j < all.length; j++) {
        final b = all[j];
        if (toDelete.contains(b.activityId)) continue;
        final gap = b.startDate.difference(a.startDate).inSeconds;
        if (gap > 120) break;
        if (gap.abs() > 60) continue;
        final durDiff = (a.durationSeconds - b.durationSeconds).abs();
        final tolerance = (a.durationSeconds * 0.02).ceil();
        if (durDiff > tolerance) continue;
        if (a.source == 'health_connect') {
          toDelete.add(a.activityId);
          break;
        } else if (b.source == 'health_connect') {
          toDelete.add(b.activityId);
        }
      }
    }
    if (toDelete.isEmpty) return 0;
    return (delete(
      activityRecords,
    )..where((t) => t.activityId.isIn(toDelete))).go();
  }

  Future<List<ActivityRecord>> getRecentActivities(int days) {
    final since = DateTime.now().subtract(Duration(days: days));
    return (select(activityRecords)
          ..where((t) => t.startDate.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
  }

  Future<ActivityRecord?> getActivityById(String activityId) {
    return (select(activityRecords)
          ..where((t) => t.activityId.equals(activityId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<ActivityRecord>> getActivitiesForDate(DateTime date) {
    final start = _dayStart(date);
    final end = start.add(const Duration(days: 1));
    return (select(activityRecords)
          ..where(
            (t) =>
                (t.startDate.isBiggerOrEqualValue(start) &
                t.startDate.isSmallerThanValue(end)),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
  }

  Future<List<ActivityRecord>> getActivitiesPaginated(int page) {
    return (select(activityRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)])
          ..limit(20, offset: page * 20))
        .get();
  }

  Future<List<ActivityRecord>> getActivitiesInRange(int days) {
    final since = DateTime.now().subtract(Duration(days: days));
    return (select(activityRecords)
          ..where((t) => t.startDate.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.startDate)]))
        .get();
  }

  Future<List<ActivityRecord>> getActivitiesForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (select(activityRecords)
          ..where(
            (t) =>
                t.startDate.isBiggerOrEqualValue(start) &
                t.startDate.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
  }

  Future<List<ActivityRecord>> getUnmatchedActivitiesInRange(
    DateTime from,
    DateTime to,
  ) {
    return (select(activityRecords)
          ..where(
            (t) =>
                t.startDate.isBetweenValues(from, to) &
                t.plannedWorkoutName.isNull(),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.startDate)]))
        .get();
  }

  /// Links a completed activity to the planned workout it fulfilled.
  Future<int> stampPlannedWorkout(
    String activityId, {
    required String? name,
    required int? durationSeconds,
    required double? distanceMeters,
    required String? stepsJson,
  }) {
    return (update(
      activityRecords,
    )..where((t) => t.activityId.equals(activityId))).write(
      ActivityRecordsCompanion(
        plannedWorkoutName: Value(name),
        plannedDurationSeconds: Value(durationSeconds),
        plannedDistanceMeters: Value(distanceMeters),
        plannedStepsJson: Value(stepsJson),
      ),
    );
  }

  Future<int> getActivityCount() async {
    final count = activityRecords.id.count();
    final query = selectOnly(activityRecords)..addColumns([count]);
    return query.map((row) => row.read(count)!).getSingle();
  }

  Future<List<ActivityRecord>> getCyclingActivitiesWithPower() {
    return (select(activityRecords)
          ..where(
            (t) =>
                (t.type.like('%cycl%') |
                    t.type.like('%bike%') |
                    t.type.like('%indoor%') |
                    t.type.like('%virtual_ride%')) &
                t.durationSeconds.isBiggerThanValue(0),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
  }

  Future<List<ActivityRecord>> getRunningActivitiesForPrediction() {
    return (select(activityRecords)
          ..where(
            (t) =>
                t.type.like('%run%') &
                t.distanceMeters.isBiggerThanValue(1000.0) &
                t.durationSeconds.isBiggerThanValue(0),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
  }

  Future<int> deleteActivityById(String activityId) {
    return (delete(
      activityRecords,
    )..where((t) => t.activityId.equals(activityId))).go();
  }

  // ── Scheduled workouts ───────────────────────────────────────────────────

  Future<int> deleteWorkoutsNotIn(List<String> scheduleIds) {
    if (scheduleIds.isEmpty) {
      return delete(scheduledWorkoutRecords).go();
    }
    return (delete(
      scheduledWorkoutRecords,
    )..where((t) => t.scheduleId.isNotIn(scheduleIds))).go();
  }

  /// Inserts or refreshes a workout from the Garmin calendar. The user note is
  /// owned by the app and survives a re-sync.
  Future<int> upsertScheduledWorkout(ScheduledWorkoutRecordsCompanion entry) {
    final withoutNote = entry.copyWith(userNote: const Value.absent());
    return into(scheduledWorkoutRecords).insert(
      withoutNote,
      onConflict: DoUpdate(
        (old) => withoutNote,
        target: [scheduledWorkoutRecords.scheduleId],
      ),
    );
  }

  Future<List<ScheduledWorkoutRecord>> getScheduledWorkoutsInRange(
    DateTime from,
    DateTime to,
  ) {
    return (select(scheduledWorkoutRecords)
          ..where((t) => t.scheduledDate.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledDate)]))
        .get();
  }

  Future<List<ScheduledWorkoutRecord>> getUpcomingWorkouts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (select(scheduledWorkoutRecords)
          ..where((t) => t.scheduledDate.isBiggerOrEqualValue(today))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledDate)]))
        .get();
  }

  Future<int> updateWorkoutStepsJson(String scheduleId, String? stepsJson) {
    return (update(scheduledWorkoutRecords)
          ..where((t) => t.scheduleId.equals(scheduleId)))
        .write(ScheduledWorkoutRecordsCompanion(stepsJson: Value(stepsJson)));
  }

  Future<int> updateWorkoutUserNote(String scheduleId, String? note) {
    final trimmed = note?.trim();
    return (update(
      scheduledWorkoutRecords,
    )..where((t) => t.scheduleId.equals(scheduleId))).write(
      ScheduledWorkoutRecordsCompanion(
        userNote: Value(trimmed == null || trimmed.isEmpty ? null : trimmed),
      ),
    );
  }

  /// Tags a workout that Fjelia pushed to Garmin so it can be recognised
  /// on the next calendar sync.
  Future<int> markWorkoutAsFjelia(String workoutId, String? description) {
    final trimmed = description?.trim();
    return (update(
      scheduledWorkoutRecords,
    )..where((t) => t.workoutId.equals(workoutId))).write(
      ScheduledWorkoutRecordsCompanion(
        description: Value(trimmed == null || trimmed.isEmpty ? null : trimmed),
      ),
    );
  }

  // ── Scores ───────────────────────────────────────────────────────────────

  /// Scores are keyed by the UTC midnight of their local calendar day.
  Future<void> upsertScore(DayScoreRecordsCompanion entry) async {
    final d = entry.date.value;
    final keyed = entry.copyWith(
      date: Value(DateTime.utc(d.year, d.month, d.day)),
    );
    await into(dayScoreRecords).insert(keyed, mode: InsertMode.insertOrReplace);
  }

  Future<DayScoreRecord?> getScoreForDate(DateTime date) {
    final key = DateTime.utc(date.year, date.month, date.day);
    return (select(dayScoreRecords)
          ..where((t) => t.date.equals(key))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<DayScoreRecord>> getAllScores() {
    return (select(
      dayScoreRecords,
    )..orderBy([(t) => OrderingTerm(expression: t.date)])).get();
  }

  Future<List<DayScoreRecord>> getScoreRange() async {
    final now = DateTime.now();
    final since = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 60));
    return (select(dayScoreRecords)
          ..where((t) => t.date.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.date)]))
        .get();
  }

  // ── Blood pressure ───────────────────────────────────────────────────────

  Future<List<BpMeasurement>> getBpForDate(DateTime date) {
    final start = _dayStart(date);
    final end = start.add(const Duration(days: 1));
    return (select(bpMeasurements)
          ..where(
            (t) =>
                (t.measuredAt.isBiggerOrEqualValue(start) &
                t.measuredAt.isSmallerThanValue(end)),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.measuredAt)]))
        .get();
  }

  /// Local-calendar range, inclusive start and exclusive end.
  Future<List<BpMeasurement>> getBpInRange(DateTime start, DateTime end) {
    return (select(bpMeasurements)
          ..where(
            (t) =>
                t.measuredAt.isBiggerOrEqualValue(start) &
                t.measuredAt.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.measuredAt)]))
        .get();
  }

  Future<List<BpMeasurement>> getBpForWeek(DateTime weekStart) {
    final start = _dayStart(weekStart);
    final end = start.add(const Duration(days: 7));
    return (select(bpMeasurements)
          ..where(
            (t) =>
                (t.measuredAt.isBiggerOrEqualValue(start) &
                t.measuredAt.isSmallerThanValue(end)),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.measuredAt)]))
        .get();
  }

  /// Polar H10 spot HRV readings that started in [from, to), oldest first.
  Future<List<SpotHrvMeasurement>> getSpotHrvBetween(
    DateTime from,
    DateTime to,
  ) {
    return (select(spotHrvMeasurements)
          ..where(
            (t) =>
                t.startedAt.isBiggerOrEqualValue(from) &
                t.startedAt.isSmallerThanValue(to),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.startedAt)]))
        .get();
  }

  Future<List<BpMeasurement>> getRecentBp(int days) {
    final since = DateTime.now().subtract(Duration(days: days));
    return (select(bpMeasurements)
          ..where((t) => t.measuredAt.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.measuredAt)]))
        .get();
  }

  /// The measurements that are not stored yet. A reading counts as stored when
  /// a row exists in the same minute with the same systolic and diastolic
  /// value, whatever its source, so the same reading arriving from the cloud,
  /// a report import or a repeated sync is kept once.
  Future<List<BpMeasurementsCompanion>> newBpMeasurements(
    List<BpMeasurementsCompanion> measurements,
  ) async {
    if (measurements.isEmpty) return const [];
    int minute(DateTime t) => t.millisecondsSinceEpoch ~/ 60000;
    String key(DateTime t, int sys, int dia) => '${minute(t)}/$sys/$dia';
    var first = measurements.first.measuredAt.value;
    var last = first;
    for (final m in measurements) {
      final t = m.measuredAt.value;
      if (t.isBefore(first)) first = t;
      if (t.isAfter(last)) last = t;
    }
    final stored = await getBpInRange(
      first.subtract(const Duration(minutes: 1)),
      last.add(const Duration(minutes: 2)),
    );
    final seen = {
      for (final r in stored) key(r.measuredAt, r.systolic, r.diastolic),
    };
    final fresh = <BpMeasurementsCompanion>[];
    for (final m in measurements) {
      if (seen.add(
        key(m.measuredAt.value, m.systolic.value, m.diastolic.value),
      )) {
        fresh.add(m);
      }
    }
    return fresh;
  }

  /// Stores the measurements that are not stored yet and returns how many
  /// were added.
  Future<int> insertBpMeasurements(
    List<BpMeasurementsCompanion> measurements,
  ) async {
    final fresh = await newBpMeasurements(measurements);
    if (fresh.isEmpty) return 0;
    await batch((b) => b.insertAll(bpMeasurements, fresh));
    return fresh.length;
  }

  // ── Renpho ───────────────────────────────────────────────────────────────

  Future<void> upsertRenphoMeasurements(
    List<RenphoRecordsCompanion> measurements,
  ) async {
    await batch((b) {
      for (final m in measurements) {
        b.insert(
          renphoRecords,
          m,
          onConflict: DoUpdate((old) => m, target: [renphoRecords.measuredAt]),
        );
      }
    });
  }

  Future<List<RenphoRecord>> getRenphoRange(int days) {
    final since = DateTime.now().subtract(Duration(days: days));
    return (select(renphoRecords)
          ..where((t) => t.measuredAt.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.measuredAt)]))
        .get();
  }

  // ── Grip strength / OCR ──────────────────────────────────────────────────

  Future<List<GripStrengthRecord>> getGripStrengthRange() {
    return (select(
      gripStrengthRecords,
    )..orderBy([(t) => OrderingTerm(expression: t.measuredAt)])).get();
  }

  Future<GripStrengthRecord?> getLatestGripStrength() {
    return (select(gripStrengthRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertGripStrength(GripStrengthRecordsCompanion entry) =>
      into(gripStrengthRecords).insert(entry);

  Future<int> deleteGripStrength(int id) =>
      (delete(gripStrengthRecords)..where((t) => t.id.equals(id))).go();

  Future<int> insertOcrMeasurement(OcrMeasurementsCompanion entry) =>
      into(ocrMeasurements).insert(entry);

  // ── Heat acclimation / weather ───────────────────────────────────────────

  Future<int> upsertHeatDailyState(HeatDailyStateRecordsCompanion entry) =>
      into(
        heatDailyStateRecords,
      ).insert(entry, mode: InsertMode.insertOrReplace);

  Future<int> upsertHeatWorkoutContext(HeatWorkoutContextsCompanion entry) =>
      into(heatWorkoutContexts).insert(entry, mode: InsertMode.insertOrReplace);

  Future<int> upsertWeatherSnapshot(WeatherSnapshotRecordsCompanion entry) =>
      into(
        weatherSnapshotRecords,
      ).insert(entry, mode: InsertMode.insertOrReplace);

  /// Cached weather within ~1 km and ±30 min of [at].
  Future<WeatherSnapshotRecord?> getWeatherSnapshotNear(
    double latitude,
    double longitude,
    DateTime at, {
    Duration window = const Duration(minutes: 30),
  }) {
    return (select(weatherSnapshotRecords)
          ..where(
            (t) =>
                t.latitude.isBetweenValues(latitude - 0.01, latitude + 0.01) &
                t.longitude.isBetweenValues(
                  longitude - 0.01,
                  longitude + 0.01,
                ) &
                t.observedAt.isBetweenValues(
                  at.subtract(window),
                  at.add(window),
                ),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<WeatherSnapshotRecord>> getWeatherSnapshotsForActivity(
    double latitude,
    double longitude,
    DateTime from,
    DateTime to,
  ) {
    return (select(weatherSnapshotRecords)
          ..where(
            (t) =>
                t.latitude.isBetweenValues(latitude - 0.01, latitude + 0.01) &
                t.longitude.isBetweenValues(
                  longitude - 0.01,
                  longitude + 0.01,
                ) &
                t.observedAt.isBetweenValues(from, to),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.observedAt)]))
        .get();
  }

  Future<List<WeatherSnapshotRecord>> getWeatherSnapshotsByTimeWindow(
    DateTime from,
    DateTime to,
  ) {
    return (select(weatherSnapshotRecords)
          ..where((t) => t.observedAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm(expression: t.observedAt)]))
        .get();
  }

  Future<WeatherSnapshotRecord?> getWeatherSnapshotByKey(String cacheKey) {
    return (select(weatherSnapshotRecords)
          ..where((t) => t.cacheKey.equals(cacheKey))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<HeatDailyStateRecord?> getHeatStateForDate(DateTime date) {
    final start = _dayStart(date);
    final end = start.add(const Duration(days: 1));
    return (select(heatDailyStateRecords)
          ..where(
            (t) =>
                (t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end)),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<HeatDailyStateRecord>> getHeatStateRange(int days) {
    final since = DateTime.now().subtract(Duration(days: days));
    return (select(heatDailyStateRecords)
          ..where((t) => t.date.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.date)]))
        .get();
  }

  Future<HeatWorkoutContext?> getHeatWorkoutContextForActivity(
    String activityId,
  ) {
    return (select(heatWorkoutContexts)
          ..where((t) => t.activityId.equals(activityId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> deleteHeatWorkoutContextForActivity(String activityId) {
    return (delete(
      heatWorkoutContexts,
    )..where((t) => t.activityId.equals(activityId))).go();
  }

  // ── Thresholds ───────────────────────────────────────────────────────────

  Future<List<ThresholdRecord>> getAllThresholdRecords() {
    return (select(
      thresholdRecords,
    )..orderBy([(t) => OrderingTerm(expression: t.date)])).get();
  }

  /// One threshold row per source activity; later detections for the same
  /// activity only fill in the values they found.
  Future<void> upsertThresholdRecord({
    required DateTime date,
    required String activityId,
    required String source,
    int? lt1Bpm,
    int? lt2Bpm,
    int? lt2PaceSec,
    int? vo2PaceSec,
  }) async {
    final existing = await (select(
      thresholdRecords,
    )..where((t) => t.activityId.equals(activityId))).getSingleOrNull();
    final entry = ThresholdRecordsCompanion(
      date: Value(date),
      activityId: Value(activityId),
      source: Value(source),
      lt1Bpm: Value(lt1Bpm ?? existing?.lt1Bpm),
      lt2Bpm: Value(lt2Bpm ?? existing?.lt2Bpm),
      lt2PaceSec: Value(lt2PaceSec ?? existing?.lt2PaceSec),
      vo2PaceSec: Value(vo2PaceSec ?? existing?.vo2PaceSec),
    );
    if (existing == null) {
      await into(thresholdRecords).insert(entry);
    } else {
      await (update(
        thresholdRecords,
      )..where((t) => t.activityId.equals(activityId))).write(entry);
    }
  }

  Future<void> insertFtpSnapshot(
    int ftpWatts,
    String source, {
    DateTime? date,
  }) async {
    final at = date ?? DateTime.now();
    await into(thresholdRecords).insert(
      ThresholdRecordsCompanion(
        date: Value(at),
        activityId: Value('ftp_${at.millisecondsSinceEpoch ~/ 1000}'),
        source: Value(source),
        ftpWatts: Value(ftpWatts),
      ),
    );
  }

  Future<int> deleteThresholdRecord(int id) =>
      (delete(thresholdRecords)..where((t) => t.id.equals(id))).go();

  // ── Training plan ────────────────────────────────────────────────────────

  Future<List<TrainingSession>> getUpcomingTrainingSessions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final until = today.add(const Duration(days: 14));
    return (select(trainingSessions)
          ..where(
            (t) =>
                t.athleteId.equals('self') &
                t.sessionDate.isBiggerOrEqualValue(today) &
                t.sessionDate.isSmallerOrEqualValue(until) &
                t.status.isIn(const ['planned', 'adapted']),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.sessionDate),
            (t) => OrderingTerm(expression: t.sessionNumber),
          ]))
        .get();
  }

  Future<DailyReadinessRecord?> getTodayReadiness() {
    final start = _dayStart(DateTime.now());
    final end = start.add(const Duration(days: 1));
    return (select(dailyReadinessRecords)
          ..where(
            (t) =>
                t.athleteId.equals('self') &
                (t.date.isBiggerOrEqualValue(start) &
                    t.date.isSmallerThanValue(end)),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  // ── Migrations ───────────────────────────────────────────────────────────

  /// Older versions stored empty text in the JSON columns of activities
  /// without a route or samples. Empty text is not JSON, so it becomes NULL.
  Future<void> _clearBlankActivityJson() async {
    for (final column in const [
      'gpx_json',
      'metrics_json',
      'hr_zones_json',
      'planned_steps_json',
    ]) {
      await customStatement(
        "UPDATE activity_records SET $column = NULL "
        "WHERE $column IS NOT NULL AND trim($column) = ''",
      );
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await _clearBlankActivityJson();
      // An activity completes one session; the index makes that a rule of
      // the data, not only of the code. Null links stay unconstrained.
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_session_actuals_activity '
        'ON session_actuals(activity_id) WHERE activity_id IS NOT NULL',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 46) {
        await _addColumnIfMissing(
          'training_sessions',
          'target_metric',
          () => customStatement(
            'ALTER TABLE training_sessions ADD COLUMN target_metric TEXT',
          ),
        );
      }
      if (from < 45) {
        await _addColumnIfMissing(
          'session_actuals',
          'activity_id',
          () => customStatement(
            'ALTER TABLE session_actuals ADD COLUMN activity_id TEXT',
          ),
        );
      }
      if (from < 44) await m.createTable(spotHrvMeasurements);
      if (from < 41) await m.createTable(heartRateSamples);
      if (from < 42) {
        await m.createTable(summaryMetricOrigins);
        await _backfillUnknownMetricOrigins();
      }
      if (from < 43) {
        // Garmin time-in-zone was stored as z1…z5; every reader expects
        // zone1…zone5.
        var expr = 'hr_zones_json';
        for (var i = 1; i <= 5; i++) {
          expr = "replace($expr, '\"z$i\"', '\"zone$i\"')";
        }
        await customStatement(
          "UPDATE activity_records SET hr_zones_json = $expr "
          "WHERE hr_zones_json LIKE '%\"z1\"%'",
        );
      }
      if (from < 3) {
        await _addColumnIfMissing(
          'activity_records',
          'gpx_json',
          () => m.addColumn(activityRecords, activityRecords.gpxJson),
        );
      }
      if (from < 4) {
        await _addColumnIfMissing(
          'activity_records',
          'metrics_json',
          () => m.addColumn(activityRecords, activityRecords.metricsJson),
        );
      }
      if (from < 5) {
        await _addColumnIfMissing(
          'sleep_records',
          'phases_json',
          () => m.addColumn(sleepRecords, sleepRecords.phasesJson),
        );
        await _addColumnIfMissing(
          'sleep_records',
          'avg_overnight_hrv',
          () => m.addColumn(sleepRecords, sleepRecords.avgOvernightHrv),
        );
        await _addColumnIfMissing(
          'wellness_records',
          'total_calories',
          () => m.addColumn(wellnessRecords, wellnessRecords.totalCalories),
        );
        await _addColumnIfMissing(
          'wellness_records',
          'floors_ascended',
          () => m.addColumn(wellnessRecords, wellnessRecords.floorsAscended),
        );
        await _addColumnIfMissing(
          'wellness_records',
          'intensity_minutes',
          () => m.addColumn(wellnessRecords, wellnessRecords.intensityMinutes),
        );
        await _addColumnIfMissing(
          'activity_records',
          'total_elevation',
          () => m.addColumn(activityRecords, activityRecords.totalElevation),
        );
        await _addColumnIfMissing(
          'activity_records',
          'hr_zones_json',
          () => m.addColumn(activityRecords, activityRecords.hrZonesJson),
        );
      }
      if (from < 6) await m.createTable(renphoRecords);
      if (from < 7) await m.createTable(gripStrengthRecords);
      if (from < 8) {
        await _addColumnIfMissing(
          'wellness_records',
          'vo2max',
          () => m.addColumn(wellnessRecords, wellnessRecords.vo2max),
        );
        await _addColumnIfMissing(
          'wellness_records',
          'fitness_age',
          () => m.addColumn(wellnessRecords, wellnessRecords.fitnessAge),
        );
      }
      if (from < 9) await m.createTable(ocrMeasurements);
      if (from < 10) {
        await _addColumnIfMissing(
          'sleep_records',
          'sleep_need_seconds',
          () => m.addColumn(sleepRecords, sleepRecords.sleepNeedSeconds),
        );
      }
      if (from < 11) {
        await _addColumnIfMissing(
          'hrv_records',
          'source',
          () => m.addColumn(hrvRecords, hrvRecords.source),
        );
        await _addColumnIfMissing(
          'sleep_records',
          'source',
          () => m.addColumn(sleepRecords, sleepRecords.source),
        );
        await _addColumnIfMissing(
          'day_score_records',
          'readiness_score',
          () => m.addColumn(dayScoreRecords, dayScoreRecords.readinessScore),
        );
      }
      if (from < 12) {
        await _addColumnIfMissing(
          'wellness_records',
          'source',
          () => m.addColumn(wellnessRecords, wellnessRecords.source),
        );
      }
      if (from < 13) {
        await _addColumnIfMissing(
          'hrv_records',
          'computed_energie',
          () => m.addColumn(hrvRecords, hrvRecords.computedEnergie),
        );
      }
      if (from < 14) {
        await customStatement('UPDATE hrv_records SET computed_energie = NULL');
        await customStatement(
          "UPDATE hrv_records SET body_battery = NULL WHERE body_battery IS NOT NULL AND (source IS NULL      OR source != 'garmin_api')",
        );
      }
      if (from < 15) {
        await customStatement('UPDATE hrv_records SET computed_energie = NULL');
      }
      if (from < 16) {
        await _addColumnIfMissing(
          'activity_records',
          'source',
          () => m.addColumn(activityRecords, activityRecords.source),
        );
      }
      if (from < 17) {
        await customStatement(
          'UPDATE hrv_records SET body_battery = NULL WHERE body_battery > 100',
        );
        await customStatement(
          'UPDATE wellness_records SET body_battery_highest = NULL WHERE body_battery_highest > 100',
        );
      }
      if (from < 18) await m.createTable(scheduledWorkoutRecords);
      if (from < 19) {
        await _addColumnIfMissing(
          'wellness_records',
          'body_battery_charged',
          () =>
              m.addColumn(wellnessRecords, wellnessRecords.bodyBatteryCharged),
        );
        await _addColumnIfMissing(
          'wellness_records',
          'body_battery_drained',
          () =>
              m.addColumn(wellnessRecords, wellnessRecords.bodyBatteryDrained),
        );
        await _addColumnIfMissing(
          'wellness_records',
          'body_battery_json',
          () => m.addColumn(wellnessRecords, wellnessRecords.bodyBatteryJson),
        );
      }
      if (from < 20) {
        await _addColumnIfMissing(
          'activity_records',
          'planned_workout_name',
          () =>
              m.addColumn(activityRecords, activityRecords.plannedWorkoutName),
        );
        await _addColumnIfMissing(
          'activity_records',
          'planned_duration_seconds',
          () => m.addColumn(
            activityRecords,
            activityRecords.plannedDurationSeconds,
          ),
        );
        await _addColumnIfMissing(
          'activity_records',
          'planned_distance_meters',
          () => m.addColumn(
            activityRecords,
            activityRecords.plannedDistanceMeters,
          ),
        );
        await _addColumnIfMissing(
          'activity_records',
          'planned_steps_json',
          () => m.addColumn(activityRecords, activityRecords.plannedStepsJson),
        );
      }
      if (from < 21) {
        await _addColumnIfMissing(
          'hrv_records',
          'hrv_intraday_json',
          () => m.addColumn(hrvRecords, hrvRecords.hrvIntradayJson),
        );
      }
      if (from < 22) {
        await _addColumnIfMissing(
          'scheduled_workout_records',
          'user_note',
          () => m.addColumn(
            scheduledWorkoutRecords,
            scheduledWorkoutRecords.userNote,
          ),
        );
      }
      if (from < 23) {
        await _addColumnIfMissing(
          'wellness_records',
          'avg_spo2',
          () => m.addColumn(wellnessRecords, wellnessRecords.avgSpo2),
        );
      }
      if (from < 24) {
        await m.createTable(weatherSnapshotRecords);
        await m.createTable(heatWorkoutContexts);
        await m.createTable(heatDailyStateRecords);
      }
      if (from < 25) {
        await _addColumnIfMissing(
          'weather_snapshot_records',
          'pressure_hpa',
          () => m.addColumn(
            weatherSnapshotRecords,
            weatherSnapshotRecords.pressureHpa,
          ),
        );
        await _addColumnIfMissing(
          'heat_workout_contexts',
          'pressure_hpa',
          () =>
              m.addColumn(heatWorkoutContexts, heatWorkoutContexts.pressureHpa),
        );
      }
      if (from < 26) await m.createTable(thresholdRecords);
      if (from < 28) {
        // Backfill Banister TRIMP for activities synced without a load.
        await customStatement('''
              UPDATE activity_records
              SET training_load = (duration_seconds / 60.0)
                    * ((avg_heart_rate - 55.0) / 135.0)
                    * exp(1.92 * ((avg_heart_rate - 55.0) / 135.0))
              WHERE (training_load IS NULL OR training_load <= 0)
                AND avg_heart_rate IS NOT NULL
                AND avg_heart_rate > 0
                AND duration_seconds > 0
            ''');
      }
      if (from < 29) {
        await customStatement('DELETE FROM heat_workout_contexts');
        await customStatement('DELETE FROM heat_daily_state_records');
      }
      if (from < 30) {
        await m.createTable(raceGoals);
        await m.createTable(trainingPlans);
        await m.createTable(trainingSessions);
        await m.createTable(sessionActuals);
        await m.createTable(sessionNts);
        await m.createTable(sessionXp);
        await m.createTable(dailyReadinessRecords);
        await m.createTable(sessionAdaptations);
        await m.createTable(weekSummaries);
        await m.createTable(athleteThresholds);
        await m.createTable(coachProfiles);
        await m.createTable(coachAthleteRelations);
        await m.createTable(coachNotes);
        await m.createTable(coachReviews);
        await m.createTable(workoutTemplates);
      }
      if (from < 31) {
        await _addColumnIfMissing(
          'race_goals',
          'elevation_m',
          () => customStatement(
            'ALTER TABLE race_goals ADD COLUMN elevation_m REAL',
          ),
        );
      }
      if (from < 32) {
        await _addColumnIfMissing(
          'session_actuals',
          'polarization_index',
          () => customStatement(
            'ALTER TABLE session_actuals ADD COLUMN polarization_index REAL',
          ),
        );
        await _addColumnIfMissing(
          'session_actuals',
          'execution_verdict',
          () => customStatement(
            'ALTER TABLE session_actuals ADD COLUMN execution_verdict TEXT',
          ),
        );
      }
      if (from < 33) {
        await _addColumnIfMissing(
          'training_plans',
          'days_per_week',
          () => customStatement(
            'ALTER TABLE training_plans ADD COLUMN days_per_week INTEGER NOT NULL DEFAULT 5',
          ),
        );
        await _addColumnIfMissing(
          'training_plans',
          'rest_days_json',
          () => customStatement(
            'ALTER TABLE training_plans ADD COLUMN rest_days_json TEXT',
          ),
        );
        await _addColumnIfMissing(
          'training_plans',
          'strength_days_json',
          () => customStatement(
            'ALTER TABLE training_plans ADD COLUMN strength_days_json TEXT',
          ),
        );
      }
      if (from < 34) {
        await _addColumnIfMissing(
          'training_plans',
          'hours_per_week',
          () => customStatement(
            'ALTER TABLE training_plans ADD COLUMN hours_per_week REAL NOT NULL DEFAULT 8.0',
          ),
        );
      }
      if (from < 36) {
        await _addColumnIfMissing(
          'renpho_records',
          'waist_cm',
          () => customStatement(
            'ALTER TABLE renpho_records ADD COLUMN waist_cm REAL',
          ),
        );
      }
      if (from < 35) {
        await _addColumnIfMissing(
          'activity_records',
          'aerobic_training_effect',
          () => customStatement(
            'ALTER TABLE activity_records ADD COLUMN aerobic_training_effect REAL',
          ),
        );
        await _addColumnIfMissing(
          'activity_records',
          'anaerobic_training_effect',
          () => customStatement(
            'ALTER TABLE activity_records ADD COLUMN anaerobic_training_effect REAL',
          ),
        );
        await _addColumnIfMissing(
          'activity_records',
          'recovery_time_seconds',
          () => customStatement(
            'ALTER TABLE activity_records ADD COLUMN recovery_time_seconds INTEGER',
          ),
        );
        await _addColumnIfMissing(
          'activity_records',
          'activity_feedback_phrase',
          () => customStatement(
            'ALTER TABLE activity_records ADD COLUMN activity_feedback_phrase TEXT',
          ),
        );
        await _addColumnIfMissing(
          'activity_records',
          'avg_run_cadence',
          () => customStatement(
            'ALTER TABLE activity_records ADD COLUMN avg_run_cadence REAL',
          ),
        );
        await _addColumnIfMissing(
          'activity_records',
          'vo2max_activity',
          () => customStatement(
            'ALTER TABLE activity_records ADD COLUMN vo2max_activity REAL',
          ),
        );
      }
      if (from < 37) {
        // Bad step import (2026-07-10 … 2026-07-19) and runaway strain values.
        await customStatement(
          'UPDATE wellness_records SET steps = NULL WHERE date >= 1783634400 AND date <= 1784419200',
        );
        await customStatement(
          'UPDATE day_score_records SET strain_score = NULL WHERE strain_score > 2000',
        );
      }
      if (from < 38) {
        await _addColumnIfMissing(
          'wellness_records',
          'vo2max_cycling',
          () => customStatement(
            'ALTER TABLE wellness_records ADD COLUMN vo2max_cycling REAL',
          ),
        );
      }
      if (from < 39) {
        await _addColumnIfMissing(
          'threshold_records',
          'ftp_watts',
          () => customStatement(
            'ALTER TABLE threshold_records ADD COLUMN ftp_watts INTEGER',
          ),
        );
      }
      if (from < 40) {
        await customStatement(
          'ALTER TABLE training_sessions RENAME COLUMN planned_tss TO planned_trimp',
        );
        await customStatement(
          'ALTER TABLE week_summaries RENAME COLUMN planned_tss TO planned_trimp',
        );
        await customStatement(
          'ALTER TABLE week_summaries RENAME COLUMN actual_tss TO actual_trimp',
        );
        await _addColumnIfMissing(
          'activity_records',
          'moving_duration_seconds',
          () => customStatement(
            'ALTER TABLE activity_records ADD COLUMN moving_duration_seconds INTEGER',
          ),
        );
      }
    },
  );

  Future<void> _addColumnIfMissing(
    String table,
    String column,
    Future<void> Function() add,
  ) async {
    if (!await _columnExists(table, column)) await add();
  }

  Future<bool> _columnExists(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.any((r) => r.read<String>('name') == column);
  }
}
