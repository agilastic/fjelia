// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get training => 'Training';

  @override
  String get weatherLocation => 'Weather & Location';

  @override
  String get display => 'Display';

  @override
  String get connections => 'Connections';

  @override
  String get aiAndMore => 'AI & More';

  @override
  String get system => 'System';

  @override
  String get runSetupAgain => 'Run setup again';

  @override
  String get runSetupAgainSubtitle => 'Accounts, race goal and training plan';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get dataExport => 'Data Export';

  @override
  String get dataExportSubtitle => 'CSV export, backup & restore';

  @override
  String get developer => 'Developer';

  @override
  String get developerSubtitle => 'Debug mode, diagnostics';

  @override
  String get debug => 'Debug';

  @override
  String get debugMode => 'Debug mode';

  @override
  String get debugModeSubtitle => 'Shows the DEBUG tab';

  @override
  String get support => 'Support';

  @override
  String get reportBug => 'Report a bug';

  @override
  String get aiCoach => 'AI Coach';

  @override
  String get enableAiCoach => 'Enable AI Coach';

  @override
  String get onDeviceAiOrCloud => 'On-device AI or cloud provider';

  @override
  String get provider => 'Provider';

  @override
  String get model => 'Model';

  @override
  String get chatAndAiBriefingsUse =>
      'Chat and AI briefings use Apple Intelligence on this device. No API key required. If the model is unavailable, briefings show a non-AI summary.';

  @override
  String get briefing => 'Briefing';

  @override
  String get useAppleIntelligenceForBriefings =>
      'Use Apple Intelligence for briefings';

  @override
  String get useOnDeviceAiFor =>
      'Use on-device AI for briefings while keeping the selected provider for chat.';

  @override
  String get healthDataSharing => 'Health data sharing';

  @override
  String get askOncePerChatSession => 'Ask once per chat session';

  @override
  String get otherwiseAskBeforeEveryCloud =>
      'Otherwise ask before every cloud message';

  @override
  String get reportABug => 'Report a Bug';

  @override
  String get weatherData => 'Weather data';

  @override
  String get openSourceLibraries => 'Open source libraries';

  @override
  String get license => 'License';

  @override
  String get licenses => 'Licenses';

  @override
  String get apiKey => 'API key';

  @override
  String get saveApiKey => 'Save API key';

  @override
  String get feedbackBugReport => 'Feedback & bug report';

  @override
  String get reportSentThankYou => 'Report sent. Thank you!';

  @override
  String get weReadEveryMessageIf =>
      'We read every message. If you left your email, you may get a reply.';

  @override
  String get done => 'Done';

  @override
  String get shareAnIdeaSuggestAn =>
      'Share an idea, suggest an improvement, or tell us what happened and what you expected.';

  @override
  String get whatHappenedAndWhatDid =>
      'What happened, and what did you expect?';

  @override
  String get pleaseLeaveOutPasswordsApi =>
      'Please leave out passwords, API keys and personal health readings.';

  @override
  String get includeDiagnostics => 'Include diagnostics';

  @override
  String get optionalLogsMayContainAccount =>
      'Optional. Logs may contain account or health details. Review them below before sending.';

  @override
  String get diagnosticsPreview => 'DIAGNOSTICS PREVIEW';

  @override
  String get sendingSharesYourEmailSubject =>
      'Sending shares your email, subject, message and any selected diagnostics with Fjelia support at cloud.ebeling-hoppe.de.';

  @override
  String get copyReport => 'Copy report';

  @override
  String get shareReport => 'Share report';

  @override
  String get appleHealth => 'Apple Health';

  @override
  String get connectedServices => 'Connected Services';

  @override
  String get hiloBloodPressureBle => 'Hilo Blood Pressure BLE';

  @override
  String get writeHeartDataToApple => 'Write Heart data to Apple Health';

  @override
  String get writeWeightDataToApple => 'Write Weight data to Apple Health';

  @override
  String get renphoScaleBle => 'Renpho Scale (BLE)';

  @override
  String get polarH10HrvStrapBle => 'Polar H10 (HRV strap, BLE)';

  @override
  String get dataSourcePriority => 'Data Source Priority';

  @override
  String get whenMultipleSourcesProvideThe =>
      'When multiple sources provide the same metric, the higher source wins. Drag to reorder.';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get healthPage => 'Health Page';

  @override
  String get loadPage => 'Load Page';

  @override
  String get healthMonitor => 'Health Monitor';

  @override
  String get hrZones => 'HR Zones';

  @override
  String get t30MinTtAvailableSync => '30-min TT available — sync HR zones';

  @override
  String lt2Lt2BpmAt(Object lt2, Object at) {
    return 'LT2 $lt2 bpm · $at';
  }

  @override
  String get syncLabel => 'SYNC';

  @override
  String get autoadjust => 'AUTOADJUST';

  @override
  String zoneI(Object i) {
    return 'Zone $i';
  }

  @override
  String get hrZones2 => 'HR ZONES';

  @override
  String ageRound(Object round) {
    return 'age $round';
  }

  @override
  String get basics => 'Basics';

  @override
  String get updateWaistMonthlyUsedFor =>
      'ⓘ Update waist monthly — used for visceral fat estimate.';

  @override
  String get alcohol => 'Alcohol';

  @override
  String get t1Drink033L => '1 drink ≈ 0.33 L beer / 0.2 L wine / 4 cl spirits';

  @override
  String get clinicalLabsOptional => 'Clinical labs (optional)';

  @override
  String get glycemic => 'Glycemic';

  @override
  String get optimalForLongevity48 =>
      'Optimal for longevity: 4.8–5.4% · Prediabetes: 5.7–6.4%';

  @override
  String get lipids => 'Lipids';

  @override
  String get apobReplacesLdlWhenBoth =>
      'ApoB replaces LDL when both are entered.';

  @override
  String get inflammationKidney => 'Inflammation & Kidney';

  @override
  String get changesAreSavedAutomatically => 'Changes are saved automatically';

  @override
  String get optionalTotalClimbingForThis =>
      'Optional total climbing for this race.';

  @override
  String get moreAboutThisEvent => 'More about this event';

  @override
  String distanceOfDistancekmKm(Object distanceKm) {
    return 'Distance of $distanceKm km?';
  }

  @override
  String keepDistancekmKm(Object distanceKm) {
    return 'Keep $distanceKm km';
  }

  @override
  String useLikelyKm(Object likely) {
    return 'Use $likely km';
  }

  @override
  String get thisBackupContainsNoCalendar =>
      'This backup contains no calendar activities.';

  @override
  String get activities => 'Activities';

  @override
  String get exportActivitiesCsv => 'Export activities CSV';

  @override
  String get backupRestore => 'Backup & restore';

  @override
  String get backup => 'Backup';

  @override
  String get restoreFromBackup => 'Restore from backup';

  @override
  String get backupRestoredRestartTheApp =>
      'Backup restored. Restart the app to reload all settings.';

  @override
  String get raceGoals => 'Race Goals';

  @override
  String get yourActivities => 'Your Activities';

  @override
  String get usedByAiCoachAnd =>
      'Used by AI Coach and training plan. Plan sports marked with ✦.';

  @override
  String get calendarWeekStart => 'Calendar week start';

  @override
  String get planDefaultView => 'Plan Default View';

  @override
  String get weeklySchedule => 'Weekly Schedule';

  @override
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      trainingDaysPerWeek,
      locale: localeName,
      other: '$trainingDaysPerWeek training days',
      one: '$trainingDaysPerWeek training day',
    );
    return '$_temp0 · tap to cycle Training / Rest / Strength';
  }

  @override
  String get updatePlanToThisSchedule => 'Update plan to this schedule';

  @override
  String get updateStrengthSessions => 'Update strength sessions';

  @override
  String get sessionsPerDay => 'Sessions per day';

  @override
  String get canYouFitTwoWorkouts => 'Can you fit two workouts in one day?';

  @override
  String get strengthLoadUnit => 'Strength load unit';

  @override
  String get weightsThemselvesAreSetIn =>
      'Weights themselves are set in each workout and remembered from your history.';

  @override
  String get hoursAvailableWeek => 'Hours available / week';

  @override
  String hoursperweekHWeek(Object hoursPerWeek) {
    return '$hoursPerWeek h / week';
  }

  @override
  String hoursperweekH(Object hoursPerWeek) {
    return '$hoursPerWeek h';
  }

  @override
  String get heatAcclimation => 'Heat Acclimation';

  @override
  String get showHeatAcclimation => 'Show Heat Acclimation';

  @override
  String get weatherEvaluatedAgainstAConfigurable =>
      'Weather evaluated against a configurable location.';

  @override
  String get trainingPlan => 'Training Plan';

  @override
  String get regenerateReplacesFutureSessionsAnd =>
      'Regenerate replaces future sessions and rebuilds from today using current settings.';

  @override
  String valueUpcomingWorkoutsGenerated(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value upcoming workouts generated',
      one: '$value upcoming workout generated',
    );
    return '$_temp0';
  }

  @override
  String get generationFailedCheckYourRace =>
      'Generation failed. Check your race goal and try again.';

  @override
  String get deleteAllWorkouts => 'Delete All Workouts';

  @override
  String get changesAreSavedAutomatically2 =>
      '✓ Changes are saved automatically';

  @override
  String countUpcomingWorkoutsGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upcoming workouts generated',
      one: '$count upcoming workout generated',
    );
    return '$_temp0';
  }

  @override
  String get importRaceGoalsFromGarmin => 'Import race goals from Garmin';

  @override
  String get addRaceGoal => 'Add race goal';

  @override
  String priorityTouppercase(Object toUpperCase) {
    return 'Priority $toUpperCase';
  }

  @override
  String get goalsAreSharedWithAi =>
      'Goals are shared with AI Coach. Priority A, B and C decide how the plan weighs your races against each other.';

  @override
  String get deletingWorkouts => 'Deleting workouts';

  @override
  String get cityOrTown => 'City or town';

  @override
  String get eGHannoverOrPalma => 'e.g. Hannover or Palma';

  @override
  String get noCitiesFoundTryA => 'No cities found. Try a nearby town.';

  @override
  String get chooseTheLocationForThe =>
      'Choose the location for the Plan forecast, radar and heat acclimation. Weather works even when heat acclimation is off.';

  @override
  String get none => 'None';

  @override
  String get disableLocalWeatherAndLocation =>
      'Disable local weather and location requests';

  @override
  String get currentLocation => 'Current location';

  @override
  String get followYourDeviceLocation => 'Follow your device location';

  @override
  String get fixedLocation => 'Fixed location';

  @override
  String get chooseACityOrEnter => 'Choose a city or enter coordinates';

  @override
  String get chooseCity => 'Choose city';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get saveLocation => 'Save location';

  @override
  String get refreshCurrentLocation => 'Refresh current location';

  @override
  String get citySearchOpenMeteoGeonames =>
      'City search: Open-Meteo / GeoNames';

  @override
  String get cityNamesOpenstreetmap => 'City names: © OpenStreetMap';

  @override
  String get energy => 'ENERGY';

  @override
  String get currentEnergy => 'CURRENT ENERGY';

  @override
  String get dailyTimeline => 'DAILY TIMELINE';

  @override
  String valueValue2(Object value, Object value2) {
    return '$value → $value2';
  }

  @override
  String get energy2 => 'Energy';

  @override
  String get noData => 'No data';

  @override
  String get bloodPressureInsights => 'BLOOD PRESSURE INSIGHTS';

  @override
  String get sys => ' Sys';

  @override
  String get diaMmhg => ' Dia · mmHg';

  @override
  String get previousBloodPressurePeriod => 'Previous blood-pressure period';

  @override
  String get nextBloodPressurePeriod => 'Next blood-pressure period';

  @override
  String get nightDipping => 'Night Dipping';

  @override
  String get noMeasurementsInThisPeriod => 'No measurements in this period';

  @override
  String get fullscreenBloodPressureChart => 'Fullscreen blood-pressure chart';

  @override
  String get barsMinMaxLineDots =>
      'Bars: min–max · line/dots: average · tap or drag to inspect';

  @override
  String get noMeasurements => 'No measurements';

  @override
  String round(Object round) {
    return '$round';
  }

  @override
  String sysSys2Mmhg(Object sys, Object sys2) {
    return '$sys–$sys2 mmHg';
  }

  @override
  String lengthReadingsAverageMinMax(int length) {
    String _temp0 = intl.Intl.pluralLogic(
      length,
      locale: localeName,
      other: '$length readings',
      one: '$length reading',
    );
    return '$_temp0 · average / min–max';
  }

  @override
  String bloodPressureTouppercaseMmhg(Object toUpperCase) {
    return 'BLOOD PRESSURE · $toUpperCase · mmHg';
  }

  @override
  String get closeFullscreenBloodPressureChart =>
      'Close fullscreen blood-pressure chart';

  @override
  String get chooseScale => 'Choose scale';

  @override
  String get noScalesFoundStepOn =>
      'No scales found. Step on your scale and try again.';

  @override
  String nameRssiDbm(Object name, Object rssi) {
    return '$name · $rssi dBm';
  }

  @override
  String get renphoSaved => 'RENPHO saved:';

  @override
  String get renphoScaleBle2 => 'RENPHO Scale (BLE)';

  @override
  String get changeMeasurementType => 'Change measurement type';

  @override
  String get addMeasurement => 'Add Measurement';

  @override
  String get whatAreYouMeasuring => 'What are you measuring?';

  @override
  String get chooseAnotherMeasurement => 'Choose another measurement';

  @override
  String get saveMeasurement => 'Save measurement';

  @override
  String get skip => 'Skip';

  @override
  String get connectHiloService => 'Connect Hilo Service';

  @override
  String get connectHilo => 'Connect Hilo';

  @override
  String get connectCoros => 'Connect Coros';

  @override
  String get europe => 'Europe';

  @override
  String get unitedStates => 'United States';

  @override
  String get asia => 'Asia';

  @override
  String get bluetoothBloodPressure => 'Bluetooth · blood pressure';

  @override
  String get cloudCuffData => 'Cloud · cuff data';

  @override
  String get apiSync => 'API sync';

  @override
  String get bluetoothHrvStrap => 'Bluetooth · HRV strap';

  @override
  String get accesslinkApi => 'AccessLink API';

  @override
  String get systemHealthData => 'System health data';

  @override
  String get cloudScaleHistory => 'Cloud · scale history';

  @override
  String get bluetoothWeightBody => 'Bluetooth · weight & body';

  @override
  String get connectYourDevices => 'Connect your devices';

  @override
  String get continueLabel => 'Continue';

  @override
  String get connectGarmin => 'Connect Garmin';

  @override
  String get connectAppleHealth => 'Connect Apple Health';

  @override
  String get dataSynced => 'DATA SYNCED';

  @override
  String get pairHiloPod => 'Pair Hilo Pod';

  @override
  String get chooseStrap => 'Choose strap';

  @override
  String namePaired(Object name) {
    return '$name paired.';
  }

  @override
  String get pairPolarH10 => 'Pair Polar H10';

  @override
  String get forget => 'Forget';

  @override
  String get sendWorkoutToPolar => 'Send workout to Polar';

  @override
  String get connectPolar => 'Connect Polar';

  @override
  String get signInWithPolarFlow => 'Sign in with Polar Flow';

  @override
  String get syncsSleepStagesHrvResting =>
      'Syncs sleep stages · HRV · resting HR · workouts · steps';

  @override
  String savedForV(Object v) {
    return 'Saved for $v';
  }

  @override
  String get remove => 'Remove';

  @override
  String get polarEMail => 'Polar e-mail';

  @override
  String get polarPassword => 'Polar password';

  @override
  String get pairRenphoScale => 'Pair RENPHO Scale';

  @override
  String get connectRenpho => 'Connect Renpho';

  @override
  String get connectSuunto => 'Connect Suunto';

  @override
  String smsSentToTrim(Object trim) {
    return 'SMS sent to $trim';
  }

  @override
  String get resendSms => 'Resend SMS';

  @override
  String get retryLoadingPreferences => 'Retry loading preferences';

  @override
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed) {
    return 'WEEKLY TRAINING TIME · $toStringAsFixed h';
  }

  @override
  String get tapADayToCycle => 'Tap a day to cycle Training / Rest / Strength.';

  @override
  String get doubleDayOk => 'Double day ok';

  @override
  String get birthYearOptional => 'Birth year (optional)';

  @override
  String get addAnother => 'Add another';

  @override
  String get knowYourBodyTrainSmarter => 'Know your body.\nTrain smarter.';

  @override
  String get allYourHealthDevicesOne =>
      'All your health devices. One intelligent view.';

  @override
  String get areYouReadyToTrain => 'Are you ready to train today?';

  @override
  String get hrvRecoveryScoreRestingHr => 'HRV · Recovery Score · Resting HR';

  @override
  String get didYouActuallyRecoverLast =>
      'Did you actually recover last night?';

  @override
  String get sleepStagesDeepSleepSpo => 'Sleep Stages · Deep Sleep · SpO₂';

  @override
  String get isYourBloodPressureUnder =>
      'Is your blood pressure under control?';

  @override
  String get continuousBpNightDippingTrends =>
      'Continuous BP · Night Dipping · Trends';

  @override
  String get howHardDidYouPush => 'How hard did you push this week?';

  @override
  String get trainingLoadTrimpStrainScore =>
      'Training Load · TRIMP · Strain Score';

  @override
  String get isYourBodyCompositionImproving =>
      'Is your body composition improving?';

  @override
  String get weightBodyFatMuscleMass => 'Weight · Body Fat · Muscle Mass';

  @override
  String get getStarted => 'Get Started';

  @override
  String get yourDataStaysOnYour =>
      'Your data stays on your device. Always private.';

  @override
  String get bodyScale => 'Body Scale';

  @override
  String get bodyComposition => 'Body Composition';

  @override
  String get sleep => 'SLEEP';

  @override
  String get sleepPerformance => 'SLEEP PERFORMANCE';

  @override
  String get sleepHistory => 'Sleep history';

  @override
  String labelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String lessLabel(Object label) {
    return 'Less $label';
  }

  @override
  String moreLabel(Object label) {
    return 'More $label';
  }

  @override
  String get gymMode => 'Gym mode';

  @override
  String get finishWorkout => 'Finish workout';

  @override
  String get workoutActions => 'Workout actions';

  @override
  String get discardWorkout => 'Discard workout';

  @override
  String get allSetsRecorded => 'All sets recorded';

  @override
  String get reviewSets => 'Review sets';

  @override
  String get rest => 'REST';

  @override
  String plannedResttarget(Object restTarget) {
    return 'Planned $restTarget';
  }

  @override
  String get startSet => 'Start set';

  @override
  String get seconds => 'Seconds';

  @override
  String get previousSet => 'Previous set';

  @override
  String get allSets => 'All sets';

  @override
  String get nextSet => 'Next set';

  @override
  String get everySetIsSavedAs =>
      'Every set is saved as you go. Close this screen any time and resume from the planned workout.';

  @override
  String get cancel => 'Cancel';

  @override
  String get apply => 'Apply';

  @override
  String get effortScale => 'Effort scale';

  @override
  String get setType => 'Set type';

  @override
  String get reps => 'Reps';

  @override
  String get range => 'Range';

  @override
  String get time => 'Time';

  @override
  String get t45Or100 => '45 or 1:00';

  @override
  String get blankWhenNotSet => 'Blank when not set';

  @override
  String get redBand => 'Red band';

  @override
  String get t90Or130 => '90 or 1:30';

  @override
  String get blankWhenUnknown => 'Blank when unknown';

  @override
  String get usePlannedLoad => 'Use planned load';

  @override
  String get blankWhenNotMeasured => 'Blank when not measured';

  @override
  String get exercise => 'Exercise';

  @override
  String get changingTheLoadConventionStarts =>
      'Changing the load convention starts a separate history for this exercise.';

  @override
  String get barbellMachine => 'Barbell, machine…';

  @override
  String get load => 'Load';

  @override
  String get loadRefersTo => 'Load refers to';

  @override
  String get t2ForAPair => '2 for a pair';

  @override
  String get repetitions => 'Repetitions';

  @override
  String get availablePlatesOrDumbbells => 'Available plates or dumbbells';

  @override
  String get rememberForThisEquipment => 'Remember for this equipment';

  @override
  String get findOrNameAnExercise => 'Find or name an exercise';

  @override
  String createTrim(Object trim) {
    return 'Create “$trim”';
  }

  @override
  String get customExercise => 'Custom exercise';

  @override
  String get smallestLoadStep => 'Smallest load step';

  @override
  String whatRemoved(Object what) {
    return '$what removed';
  }

  @override
  String get undo => 'Undo';

  @override
  String get retry => 'Retry';

  @override
  String get performance => 'Performance';

  @override
  String get addExercise => 'Add exercise';

  @override
  String get finishLog => 'Finish log';

  @override
  String get keepAsDraft => 'Keep as draft';

  @override
  String actionsForName(Object name) {
    return 'Actions for $name';
  }

  @override
  String get editExercise => 'Edit exercise';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get addSet => 'Add set';

  @override
  String get removeLastSet => 'Remove last set';

  @override
  String get saveAsTemplate => 'Save as template';

  @override
  String savedTitleAsATemplate(Object title) {
    return 'Saved “$title” as a template. This workout is unchanged until you save it.';
  }

  @override
  String nameSetN(Object name, Object n) {
    return '$name · Set $n';
  }

  @override
  String nameAllWorkingSets(Object name) {
    return '$name · All working sets';
  }

  @override
  String labelRest(Object label) {
    return '$label rest';
  }

  @override
  String get secondsOrMSs => 'Seconds or m:ss';

  @override
  String get applyToAllSets => 'Apply to all sets';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get supersetWithNext => 'Superset with next';

  @override
  String get circuitWithNext => 'Circuit with next';

  @override
  String actionsForSetN(Object n) {
    return 'Actions for set $n';
  }

  @override
  String get editSet => 'Edit set';

  @override
  String get duplicateSet => 'Duplicate set';

  @override
  String get removeSet => 'Remove set';

  @override
  String labelActions(Object label) {
    return '$label actions';
  }

  @override
  String get editRests => 'Edit rests';

  @override
  String get ungroup => 'Ungroup';

  @override
  String get editExercises => 'Edit exercises';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String couldNotSaveError(Object error) {
    return 'Could not save: $error';
  }

  @override
  String get history => 'History';

  @override
  String get exercises => 'Exercises';

  @override
  String get noExercisesArePlannedFor =>
      'No exercises are planned for this workout yet. The notes above describe it.';

  @override
  String get addExercises => 'Add exercises';

  @override
  String get fromTheBuiltInTemplate =>
      'From the built-in template. Loads are yours to set; history appears once you log a workout.';

  @override
  String get shareExerciseList => 'Share exercise list';

  @override
  String get noSavedStrengthTemplatesYet =>
      'No saved strength templates yet. Save one from a planned workout first.';

  @override
  String get compareWith => 'Compare with';

  @override
  String estimated1rmUnit(Object unit) {
    return 'Estimated 1RM $unit';
  }

  @override
  String get plannedNotRecorded => 'Planned, not recorded';

  @override
  String get notes => 'Notes';

  @override
  String get editPerformance => 'Edit performance';

  @override
  String get compareWithASavedWorkout => 'Compare with a saved workout';

  @override
  String get sessions => 'Sessions';

  @override
  String get radarUnavailableRetry => 'Radar unavailable · Retry';

  @override
  String get radar => 'Radar';

  @override
  String get weatherDataByRainviewer => 'Weather data by RainViewer';

  @override
  String get openstreetmapContributors => '© OpenStreetMap contributors';

  @override
  String get weather => 'Weather';

  @override
  String get weatherUnavailableRetry => 'Weather unavailable · Retry';

  @override
  String get chooseAFixedLocationIn =>
      'Choose a fixed location in Weather & Location settings, or allow location access for local weather.';

  @override
  String get locationSettings => 'Location settings';

  @override
  String get retryLocation => 'Retry location';

  @override
  String round2(Object round) {
    return '$round°';
  }

  @override
  String roundRhRound2Hpa(Object round, Object round2) {
    return '$round% RH · $round2 hPa';
  }

  @override
  String wetBulbTostringasfixedC(Object toStringAsFixed) {
    return 'Wet-bulb $toStringAsFixed°C';
  }

  @override
  String get previousForecastDay => 'Previous forecast day';

  @override
  String get nextForecastDay => 'Next forecast day';

  @override
  String daysDayForecast(Object days) {
    return '$days-Day Forecast';
  }

  @override
  String thisProviderCurrentlySuppliesDays(Object days, Object days2) {
    return 'This provider currently supplies $days of $days2 forecast days.';
  }

  @override
  String get now => 'Now';

  @override
  String get sunriseSunset => 'Sunrise / Sunset';

  @override
  String keyKey2(Object key, Object key2) {
    return '☀ $key   ☾ $key2';
  }

  @override
  String get use => 'Use';

  @override
  String get exerciseDetailsWereNotProvided =>
      'Exercise details were not provided by this activity source.';

  @override
  String get logFromPlan => 'Log from plan';

  @override
  String get addExerciseDetails => 'Add exercise details';

  @override
  String get loadSuggestion => 'Load suggestion';

  @override
  String get applyToThisWorkout => 'Apply to this workout';

  @override
  String get keepCurrentLoad => 'Keep current load';

  @override
  String get setLoadStep => 'Set load step';

  @override
  String get viewSupportingSets => 'View supporting sets';

  @override
  String get supportingSets => 'Supporting sets';

  @override
  String get noRecordedSessionsYet => 'No recorded sessions yet.';

  @override
  String nameDemonstrationCue(Object name, Object cue) {
    return '$name demonstration. $cue';
  }

  @override
  String get noScalesFoundStepOn2 =>
      'No scales found. Step on the scale and try again.';

  @override
  String get scalePaired => 'Scale paired';

  @override
  String get ok => 'OK';

  @override
  String get pairedReadyToMeasure => '✓ Paired — ready to measure';

  @override
  String get chooseHiloCuff => 'Choose Hilo cuff';

  @override
  String get noCuffFoundWakeYour =>
      'No cuff found. Wake your cuff and try scanning again.';

  @override
  String get hiloCuffAktiiaC => 'Hilo cuff (AKTIIA C…)';

  @override
  String get onDemandBloodPressureVia => 'On-demand blood pressure via BLE';

  @override
  String get selectHiloPodWristband => 'Select Hilo Pod (Wristband)';

  @override
  String get rescan => 'Rescan';

  @override
  String get noDevicesFoundTapTo => 'No devices found. Tap ↻ to scan again.';

  @override
  String get polarH10SpotHrv => 'Polar H10 · Spot HRV';

  @override
  String get aSeparateHrvReadingBefore =>
      'A separate HRV reading before or after training. These measurements do not replace Garmin overnight HRV or change your readiness score.';

  @override
  String get wearTheStrapWithMoist =>
      'Wear the strap with moist electrodes. Keep still and breathe normally. Use the same posture and recording length for comparisons. After training, note how long you rested first.';

  @override
  String get measurement => 'Measurement';

  @override
  String get posture => 'Posture';

  @override
  String get recordingLengthPlus1Min =>
      'Recording length · plus 1 min settling';

  @override
  String get t2Minutes => '2 minutes';

  @override
  String get t5Minutes => '5 minutes';

  @override
  String get minutesSinceTrainingEndedOptional =>
      'Minutes since training ended (optional)';

  @override
  String get sessionOrNotesOptional => 'Session or notes (optional)';

  @override
  String connectName(Object name) {
    return 'Connect $name';
  }

  @override
  String get findPolarH10 => 'Find Polar H10';

  @override
  String signalRssiDbm(Object rssi) {
    return 'Signal $rssi dBm';
  }

  @override
  String connectedName(Object name) {
    return 'Connected: $name';
  }

  @override
  String get waitingForHeartRateAnd =>
      'Waiting for heart rate and RR intervals. Check the strap contact.';

  @override
  String get startMeasurement => 'Start measurement';

  @override
  String get cancelMeasurement => 'Cancel measurement';

  @override
  String get spotHrvRmssd => 'Spot HRV · RMSSD';

  @override
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  ) {
    return '$accepted/$length usable intervals · $toStringAsFixed% coverage';
  }

  @override
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs) {
    return 'lnRMSSD: $lnRmssd · Raw RMSSD: $rawRmssdMs ms';
  }

  @override
  String get signalQualityIsTooLow =>
      'Signal quality is too low to save. Repeat the measurement with good strap contact. At least 95% usable intervals and 90% coverage are required.';

  @override
  String get savedToSpotHrvHistory => 'Saved to spot HRV history.';

  @override
  String get newMeasurement => 'New measurement';

  @override
  String get signalScreeningExcludesPoorContact =>
      'Signal screening excludes poor contact, RR outside 250–2500 ms and intervals more than 25% from the local median. Gaps are not bridged. This is not a medical test or a standalone readiness score.';

  @override
  String historyLabelLabel2DurationMin(
    Object label,
    Object label2,
    Object duration,
  ) {
    return 'History · $label · $label2 · $duration min';
  }

  @override
  String get onlyReadingsWithTheSame =>
      'Only readings with the same context, posture and duration are shown together.';

  @override
  String get noMatchingMeasurementsYet => 'No matching measurements yet.';

  @override
  String tostringasfixedMsRmssdTostringasfixed2Bpm(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return '$toStringAsFixed ms RMSSD · $toStringAsFixed2 bpm';
  }

  @override
  String get exportRrIntervalsCsv => 'Export RR intervals (CSV)';

  @override
  String get deleteMeasurement => 'Delete measurement';

  @override
  String get remindMeToMeasureHrv => 'Remind me to measure HRV after training';

  @override
  String get appleHealthIsNoLonger => 'Apple Health is no longer available';

  @override
  String get later => 'Later';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get gripStrength => 'Grip Strength';

  @override
  String get leftKg => 'Left (kg)';

  @override
  String get rightKg => 'Right (kg)';

  @override
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg) {
    return 'L $leftKg · R $rightKg kg';
  }

  @override
  String get notificationsAreOffYouCan =>
      'Notifications are off. You can still measure from your workout.';

  @override
  String get noRemindersFrom2200 => 'No reminders from 22:00 to 07:00';

  @override
  String get aReminderThatWouldFall =>
      'A reminder that would fall in this time is skipped, not moved to the morning.';

  @override
  String get remindersArriveQuietlyInThe =>
      'Reminders arrive quietly in the notification list.';

  @override
  String get noForecastForThisDay => 'No forecast for this day';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String source(Object source) {
    return '● $source';
  }

  @override
  String get shadedAreaProviderSpread => 'Shaded area: provider spread';

  @override
  String get temperatureC => '● Temperature °C';

  @override
  String get rainMm => '▥ Rain mm';

  @override
  String get uvIndex => '— UV index';

  @override
  String get closeFullscreenWeatherChart => 'Close fullscreen weather chart';

  @override
  String get sleepStages => 'SLEEP STAGES';

  @override
  String get noStageTimelineForThis => 'No stage timeline for this night.';

  @override
  String round3(Object round) {
    return '$round%';
  }

  @override
  String get examplesOnlyCheckAndEnter =>
      'Examples only: check and enter your product label values per serving. Leave unknown nutrients blank; enter 0 only when known.';

  @override
  String get nutritionStrategy => 'Nutrition strategy';

  @override
  String get noPreWorkoutNutritionStrategy =>
      'No pre-workout nutrition strategy was saved.';

  @override
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium) {
    return '$carbs g carbs/h · $fluid ml/h · $sodium mg sodium/h';
  }

  @override
  String get forecastUpdatedReviewOrRecalculate =>
      'Forecast updated — review or recalculate the saved strategy.';

  @override
  String strategySavedSavedat(Object savedAt) {
    return 'Strategy saved $savedAt';
  }

  @override
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  ) {
    return 'During total: $totalCarbs g carbs · $totalFluid ml · $totalSodium mg sodium';
  }

  @override
  String every20MinAboutCarbs(Object carbs, Object fluid) {
    return 'Every 20 min: about $carbs g carbs and $fluid ml.';
  }

  @override
  String get packQuantitiesIncludeFullContainers =>
      'Pack quantities include full containers; they are not a requirement to consume everything.';

  @override
  String get workoutChangedReviewOrRecalculate =>
      'Workout changed — review or recalculate this saved strategy.';

  @override
  String get conditionsAndFeedingPlan => 'Conditions and feeding plan';

  @override
  String get editStrategy => 'Edit strategy';

  @override
  String get recalculate => 'Recalculate';

  @override
  String get actualNutrition => 'Actual nutrition';

  @override
  String get someProductValuesAreUnknown =>
      'Some product values are unknown; totals are incomplete.';

  @override
  String get logFoodAndFluids => 'Log food and fluids';

  @override
  String get recordWhatYouActuallyHad =>
      'Record what you actually had. Planned intake is not copied into this log.';

  @override
  String get elapsedMinutesIncludingStopsOptional =>
      'Elapsed minutes including stops (optional)';

  @override
  String recordedDurationActivityMin(Object activity) {
    return 'Recorded duration: $activity min';
  }

  @override
  String get compareWithSavedStrategy => 'Compare with saved strategy';

  @override
  String get useMatchedSessionIfAvailable => 'Use matched session if available';

  @override
  String get noPlanComparison => 'No plan comparison';

  @override
  String titleDate(Object title, Object date) {
    return '$title · $date';
  }

  @override
  String get linkedStrategyUnavailable => 'Linked strategy unavailable';

  @override
  String quantityName(Object quantity, Object name) {
    return '$quantity × $name';
  }

  @override
  String get removeIntake => 'Remove intake';

  @override
  String get addFoodOrDrink => 'Add food or drink';

  @override
  String get iHadNoIntake => 'I had no intake';

  @override
  String get giGutComfort => 'GI / gut comfort';

  @override
  String get whatWorkedSymptomsAccessProblems =>
      'What worked / symptoms / access problems';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get skipLoggingThisActivity => 'Skip logging this activity';

  @override
  String get nutritionAndFluids => 'Nutrition and fluids';

  @override
  String get productsToleranceAndMeasuredSweat =>
      'Products, tolerance and measured sweat losses';

  @override
  String get postWorkoutIntakeReminder => 'Post-workout intake reminder';

  @override
  String get onceAfterARecentEndurance =>
      'Once after a recent endurance workout; quiet hours 22:00–08:00.';

  @override
  String get addHiloBpReport => 'Add Hilo BP report';

  @override
  String get readingPdfReportsIsOnly =>
      'Reading PDF reports is only available on iOS and macOS.';

  @override
  String get chooseAnotherReport => 'Choose another report';

  @override
  String get biologicalAge => 'Biological Age';

  @override
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class) {
    return 'VO₂max $vo2max ml/kg/min · $vo2Class';
  }

  @override
  String get factorContributions => 'Factor contributions';

  @override
  String estimatedRangeRoundRound2Years(Object round, Object round2) {
    return 'Estimated range $round–$round2 years. A model estimate, not a medical diagnosis.';
  }

  @override
  String get noEnergyMeasurementsForThis =>
      'No energy measurements for this day';

  @override
  String get scanningStepOnTheScale =>
      'Scanning… step on the scale when ready.';

  @override
  String waistWaistCmUpdateMonthly(Object waist) {
    return 'Waist: $waist cm — update monthly in Profile';
  }

  @override
  String get measuring => 'Measuring…';

  @override
  String get tryAgain => 'Try again';

  @override
  String get systolic => 'Systolic';

  @override
  String get diastolic => 'Diastolic';

  @override
  String get heartRate => 'Heart Rate';

  @override
  String get weight => 'Weight';

  @override
  String get bodyFat => 'Body Fat';

  @override
  String get duration => 'Duration';

  @override
  String get deep => 'Deep';

  @override
  String get spo => 'SpO₂';

  @override
  String get activityName => 'Activity name';

  @override
  String get sport => 'Sport';

  @override
  String get distance => 'Distance';

  @override
  String get saved => 'Saved';

  @override
  String get connectionFailedCheckYourInternet =>
      'Connection failed. Check your internet connection.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get passwordTooShort => 'Password too short';

  @override
  String get loginFailedCheckYourEmail =>
      'Login failed. Check your email and password.';

  @override
  String get connectionFailedCheckYourCredentials =>
      'Connection failed. Check your credentials and internet connection.';

  @override
  String get region => 'Region';

  @override
  String get hiloPod => 'Hilo pod';

  @override
  String get hiloAccount => 'Hilo account';

  @override
  String get garmin => 'Garmin';

  @override
  String get coros => 'Coros';

  @override
  String get suunto => 'Suunto';

  @override
  String get polarH10 => 'Polar H10';

  @override
  String get polar => 'Polar';

  @override
  String get renphoAccount => 'Renpho account';

  @override
  String get garminConnectEmail => 'Garmin Connect Email';

  @override
  String get verifyMfaCode => 'Verify MFA Code';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String errorE(Object e) {
    return 'Error: $e';
  }

  @override
  String get noHiloPodFoundMake =>
      'No Hilo pod found. Make sure it is charged and nearby.';

  @override
  String scanFailedE(Object e) {
    return 'Scan failed: $e';
  }

  @override
  String get hiloPod2 => 'Hilo Pod';

  @override
  String get scanForPod => 'Scan for pod';

  @override
  String get scanForPolarH10 => 'Scan for Polar H10';

  @override
  String get couldNotReachPolarCheck =>
      'Could not reach Polar. Check your connection.';

  @override
  String get signInAndSendWorkout => 'Sign in and send workout';

  @override
  String get scanForScale => 'Scan for scale';

  @override
  String get passwordRequired => 'Password required';

  @override
  String get enterYourPhoneNumberWith =>
      'Enter your phone number (with country code, e.g. +49…) and Suunto email.';

  @override
  String get enterThePinFromThe => 'Enter the PIN from the SMS.';

  @override
  String get incorrectPinPleaseTryAgain => 'Incorrect PIN. Please try again.';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get suuntoAccountEmail => 'Suunto Account Email';

  @override
  String get enterPinFromSms => 'Enter PIN from SMS';

  @override
  String get verifyConnect => 'Verify & Connect';

  @override
  String get sendSmsCode => 'Send SMS Code';

  @override
  String couldNotSavePreferencesE(Object e) {
    return 'Could not save preferences: $e';
  }

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get running => 'Running';

  @override
  String get trailRunning => 'Trail running';

  @override
  String get cycling => 'Cycling';

  @override
  String get swimming => 'Swimming';

  @override
  String get triathlon => 'Triathlon';

  @override
  String get hiking => 'Hiking';

  @override
  String get rowing => 'Rowing';

  @override
  String get buildMyPlan => 'Build My Plan';

  @override
  String get keepAConsistentBedtimeAnd =>
      'Keep a consistent bedtime and wake time to support your sleep routine.';

  @override
  String get thisWorkoutHasNoSets => 'This workout has no sets.';

  @override
  String loadName(Object name) {
    return 'Load ($name)';
  }

  @override
  String get setLabel => 'Set';

  @override
  String get lowestReps => 'Lowest reps';

  @override
  String get highestReps => 'Highest reps';

  @override
  String get repsPerSide => 'Reps per side';

  @override
  String get fromReps => 'From reps';

  @override
  String get toReps => 'To reps';

  @override
  String get addedLoad => 'Added load';

  @override
  String get assistance => 'Assistance';

  @override
  String get tempoOptional => 'Tempo (optional)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get enterTheRepetitionsDone => 'Enter the repetitions done.';

  @override
  String plannedUnit(Object unit) {
    return 'Planned $unit';
  }

  @override
  String get repsDone => 'Reps done';

  @override
  String get resistance => 'Resistance';

  @override
  String get implementsLabel => 'Implements';

  @override
  String get name => 'Name';

  @override
  String get instructionsOptional => 'Instructions (optional)';

  @override
  String get remember => 'Remember';

  @override
  String get notSavedYet => 'Not saved yet';

  @override
  String get saving => 'Saving…';

  @override
  String get couldNotSave => 'Could not save';

  @override
  String get plannedValuesAreHintsNot =>
      'Planned values are hints, not results. Tap a set to record it.';

  @override
  String get completedAsPlanned => 'Completed as planned';

  @override
  String get save => 'Save';

  @override
  String get nameTheTemplate => 'Name the template.';

  @override
  String setN(Object n) {
    return 'Set $n';
  }

  @override
  String get changesApplyToThisWorkout =>
      'Changes apply to this workout only. Completed workouts and other sessions stay as they are.';

  @override
  String get saveForThisWorkout => 'Save for this workout';

  @override
  String knownForKnownOfOf(Object known, Object of) {
    return 'Known for $known of $of loaded sets';
  }

  @override
  String get sessionEstimate => 'Session estimate';

  @override
  String get calculatedRange => 'Calculated range';

  @override
  String get timedWork => 'Timed work';

  @override
  String get strengthTraining => 'Strength training';

  @override
  String get theExercisesCouldNotBe => 'The exercises could not be loaded.';

  @override
  String get resumeWorkout => 'Resume workout';

  @override
  String get strengthWorkout => 'Strength workout';

  @override
  String get untitledTemplate => 'Untitled template';

  @override
  String get theRecordedExercisesCouldNot =>
      'The recorded exercises could not be loaded.';

  @override
  String get exercisesPerformed => 'Exercises performed';

  @override
  String get comparedWithThePlanAs =>
      'Compared with the plan as it was when logging started.';

  @override
  String topWorkingLoadName(Object name) {
    return 'Top working load ($name)';
  }

  @override
  String get estimated1rmMiddleOfRange => 'Estimated 1RM, middle of range';

  @override
  String get noLoggedSessionsYet => 'No logged sessions yet.';

  @override
  String get noRadarFramesAvailable => 'No radar frames available';

  @override
  String get playRadar => 'Play radar';

  @override
  String get pauseRadar => 'Pause radar';

  @override
  String get high => 'High';

  @override
  String get clear => 'Clear';

  @override
  String get bodyweight => 'Bodyweight';

  @override
  String get resistance2 => 'Resistance —';

  @override
  String assistUnit(Object unit) {
    return 'Assist $unit';
  }

  @override
  String get reps2 => 'Reps —';

  @override
  String get notRecorded => 'Not recorded';

  @override
  String get skipped => 'Skipped';

  @override
  String get health => 'Health';

  @override
  String get manual => 'Manual';

  @override
  String expandName(Object name) {
    return 'Expand $name';
  }

  @override
  String get open => 'Open';

  @override
  String get noScalePaired => 'No scale paired';

  @override
  String get paired => 'Paired';

  @override
  String get change => 'Change';

  @override
  String get noCuffPaired => 'No cuff paired';

  @override
  String get noPolarH10FoundWear =>
      'No Polar H10 found. Wear the strap, wet its electrodes and check that another app is not using both Bluetooth connections.';

  @override
  String get enterMinutesSinceTrainingEnded =>
      'Enter minutes since training ended, from 0 to 1440.';

  @override
  String get timingFollowsYourWorkout => 'Timing follows your workout.';

  @override
  String get recordingStayStill => 'Recording · stay still';

  @override
  String get meanHrBpm => 'Mean HR · bpm';

  @override
  String get pairAPolarH10First => 'Pair a Polar H10 first.';

  @override
  String get around30MinutesAfterTraining =>
      'Around 30 minutes after training, when the workout is available in time.';

  @override
  String get reminderDiagnostics => 'Reminder diagnostics';

  @override
  String get forecast => 'Forecast';

  @override
  String get enterAName => 'Enter a name';

  @override
  String get enterAValidAmount => 'Enter a valid amount';

  @override
  String get enterAPositiveAmount => 'Enter a positive amount';

  @override
  String get maximum120GH => 'Maximum 120 g/h';

  @override
  String get carbohydrateTargetGH => 'Carbohydrate target g/h';

  @override
  String get fluidTargetMlH => 'Fluid target ml/h';

  @override
  String get sodiumTargetMgHNot => 'Sodium target mg/h (not salt)';

  @override
  String get surfaceFeedingAccess => 'Surface / feeding access';

  @override
  String get expectedAscentM => 'Expected ascent m';

  @override
  String get expectedAltitudeM => 'Expected altitude m';

  @override
  String get humidity => 'Humidity %';

  @override
  String get windKmH => 'Wind km/h';

  @override
  String get dayForecast => 'Day forecast';

  @override
  String get enteredConditions => 'Entered conditions';

  @override
  String get productFoodName => 'Product / food name';

  @override
  String get servingsQuantity => 'Servings / quantity';

  @override
  String get when => 'When';

  @override
  String get carbohydrateGServing => 'Carbohydrate g / serving';

  @override
  String get fluidMlServing => 'Fluid ml / serving';

  @override
  String get caffeineMgServing => 'Caffeine mg / serving';

  @override
  String get proteinGServing => 'Protein g / serving';

  @override
  String get gel => 'Gel';

  @override
  String get water => 'Water';

  @override
  String get sportsDrink => 'Sports drink';

  @override
  String get bar => 'Bar';

  @override
  String get finishIntakeLog => 'Finish intake log';

  @override
  String get importing => 'Importing…';

  @override
  String importNewreadings(Object newReadings) {
    return 'Import $newReadings';
  }

  @override
  String get reading => 'Reading…';

  @override
  String get chooseReportPdf => 'Choose report (PDF)';

  @override
  String get yourTrainingHistoryIsReady => 'Your training history is ready';

  @override
  String get importingYourTrainingHistory => 'Importing your training history';

  @override
  String get stopImport => 'Stop import';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get openai => 'OpenAI';

  @override
  String get appleIntelligence => 'Apple Intelligence';

  @override
  String get nonAiBriefing => 'Non-AI Briefing';

  @override
  String get noBriefing => 'No Briefing';

  @override
  String get ruleBasedSummaryFromYour =>
      'Rule-based summary from your health data — no API calls';

  @override
  String get hideTheBriefingCard => 'Hide the briefing card';

  @override
  String get flutter => 'Flutter';

  @override
  String get stateManagement => 'State management';

  @override
  String get bluetoothLe => 'Bluetooth LE';

  @override
  String get interactiveMaps => 'Interactive maps';

  @override
  String get chartsGraphs => 'Charts & graphs';

  @override
  String get secureCredentialStorage => 'Secure credential storage';

  @override
  String get markdownRendering => 'Markdown rendering';

  @override
  String get appleOnDeviceAi => 'Apple on-device AI';

  @override
  String get cryptography => 'Cryptography';

  @override
  String get appleHealthHealthConnect => 'Apple Health & Health Connect';

  @override
  String get runtimePermissions => 'Runtime permissions';

  @override
  String get shareExport => 'Share & export';

  @override
  String get openUrls => 'Open URLs';

  @override
  String get internationalisation => 'Internationalisation';

  @override
  String get utilities => 'Utilities';

  @override
  String get icons => 'Icons';

  @override
  String get fjelia => 'Fjelia';

  @override
  String get fjeliaFeedback => 'Fjelia feedback';

  @override
  String get couldNotSendTheReport =>
      'Could not send the report. Your text is still here. Please try again.';

  @override
  String get yourEmail => 'Your email';

  @override
  String get enterAValidEmailAddress => 'Enter a valid email address.';

  @override
  String get subject => 'Subject';

  @override
  String get sending => 'Sending…';

  @override
  String get sendReport => 'Send report';

  @override
  String get sleepRecovery => 'Sleep & Recovery';

  @override
  String get activitiesTraining => 'Activities & Training';

  @override
  String get bodyWellness => 'Body & Wellness';

  @override
  String get hilo => 'Hilo';

  @override
  String get hiloBle => 'Hilo BLE';

  @override
  String get garminApi => 'Garmin (API)';

  @override
  String get renphoScale => 'Renpho Scale';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not connected';

  @override
  String get manage => 'Manage';

  @override
  String get connect => 'Connect';

  @override
  String get habits => 'Habits';

  @override
  String get smokingAlcohol => 'Smoking, alcohol';

  @override
  String get clinicalLab => 'Clinical Lab';

  @override
  String get hba1cLipidsKidney => 'HbA1c, lipids, kidney';

  @override
  String get sex => 'Sex';

  @override
  String get smoking => 'Smoking';

  @override
  String get never => 'Never';

  @override
  String get former => 'Former';

  @override
  String get current => 'Current';

  @override
  String get hba1c => 'HbA1c';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get prediabetes => 'Prediabetes';

  @override
  String get type1 => 'Type 1';

  @override
  String get type2 => 'Type 2';

  @override
  String get apob => 'ApoB';

  @override
  String get optionalPlansAndPaceGuides =>
      'Optional. Plans and pace guides use it; the climbing above shapes the training too.';

  @override
  String get addRaceGoal2 => 'Add Race Goal';

  @override
  String get editRaceGoal => 'Edit Race Goal';

  @override
  String get trailRunning2 => 'Trail Running';

  @override
  String get roadCycling => 'Road Cycling';

  @override
  String get gravel => 'Gravel';

  @override
  String get indoorRowing => 'Indoor Rowing';

  @override
  String get selectDate => 'Select date';

  @override
  String get committed => 'Committed';

  @override
  String get flexible => 'Flexible';

  @override
  String get notGoing => 'Not going';

  @override
  String get notSaid => 'Not said';

  @override
  String get finish => 'Finish';

  @override
  String get saveGoal => 'Save Goal';

  @override
  String get exportAllRecordedWorkoutsAs =>
      'Export all recorded workouts as a spreadsheet.';

  @override
  String get backupsIncludeYourHealthData =>
      'Backups include your health data, training plans and profile settings. Login credentials are excluded. Restoring replaces local data.';

  @override
  String get trail => 'Trail';

  @override
  String get inlineSkating => 'Inline Skating';

  @override
  String get nordicClassic => 'Nordic Classic';

  @override
  String get skateSkiing => 'Skate Skiing';

  @override
  String get strength => 'Strength';

  @override
  String get walking => 'Walking';

  @override
  String get yoga => 'Yoga';

  @override
  String get skiing => 'Skiing';

  @override
  String get climbing => 'Climbing';

  @override
  String get monday => 'Monday';

  @override
  String get sunday => 'Sunday';

  @override
  String get month => 'Month';

  @override
  String get week => 'Week';

  @override
  String get list => 'List';

  @override
  String get train => 'Train';

  @override
  String get restDay => 'Rest';

  @override
  String get kilogramsKg => 'Kilograms (kg)';

  @override
  String get poundsLb => 'Pounds (lb)';

  @override
  String get regenerateWorkouts => 'Regenerate Workouts';

  @override
  String get starting => 'Starting';

  @override
  String get allPlannedWorkoutsDeleted => 'All planned workouts deleted.';

  @override
  String get searching => 'Searching…';

  @override
  String get searchCity => 'Search city';

  @override
  String get fixedLocationSavedWeatherWill =>
      'Fixed location saved. Weather will refresh.';

  @override
  String get locationDisabledThePlanWeather =>
      'Location disabled. The Plan weather card is hidden.';

  @override
  String locationSetToName(Object name) {
    return 'Location set to $name';
  }

  @override
  String get notEnoughDaytimeAndNighttime =>
      'Not enough daytime and nighttime readings';

  @override
  String get onlyTheWeightWasReceived =>
      'Only the weight was received. For body fat, muscle and the other values stand barefoot on the metal electrodes and stay on until the scale finishes.';

  @override
  String get addYourWaistInProfile =>
      'Add your waist in Profile for visceral fat.';

  @override
  String get manualActivity => 'Manual Activity';

  @override
  String get theseCredentialsAreStoredEncrypted =>
      'These credentials are stored encrypted on your device (iOS Keychain / Android Keystore). They are never sent to any server other than Hilo.';

  @override
  String get corosCredentialsAreStoredEncrypted =>
      'Coros credentials are stored encrypted on your device. Fjelia reads data directly from the Coros cloud API. This uses the same API as the Coros Training Hub web app.';

  @override
  String get connectAnyCombinationYouCan =>
      'Connect any combination — you can always add more later in Settings.';

  @override
  String get garminCredentialsAreStoredEncrypted =>
      'Garmin credentials are stored encrypted on your device. Fjelia uses the unofficial Garmin Connect API – the same approach used by many community apps.';

  @override
  String get enterTheVerificationCode => 'Enter the verification code';

  @override
  String get appleHealthDataAccess =>
      'Fjelia reads your health data from Apple Health. With your permission, it can also write synced data to Apple Health. Manage access in your device settings.';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get wearTheHiloBandDuring =>
      'Wear the Hilo band during sleep for continuous blood pressure recording. Data syncs automatically each morning when the app opens.';

  @override
  String get noPolarH10FoundWear2 =>
      'No Polar H10 found. Wear the strap with moist electrodes and make sure no other app (or watch) is connected to it, then scan again.';

  @override
  String get wearTheStrapWithMoist2 =>
      'Wear the strap with moist electrodes before scanning. Measure later with + → Polar H10 HRV measurement; results appear next to your overnight HRV.';

  @override
  String get signedInPlannedWorkoutsCan =>
      'Signed in. Planned workouts can now be sent to Polar. Older sessions are imported with the next full history sync.';

  @override
  String get saveYourPolarFlowLogin =>
      'Save your Polar Flow login to send planned workouts and import sessions older than 30 days. It stays in this device\'s keychain and is sent only to Polar. Send a workout from its planner sheet, then sync Polar Flow to your watch. Check that your Polar heart-rate zones match Fjelia.';

  @override
  String get signInToSendThis =>
      'Sign in to send this workout to your Polar Flow calendar. Your login stays in this device\'s keychain and is sent only to Polar. After sending, sync Polar Flow to your watch.';

  @override
  String get checkAndSave => 'Check and save';

  @override
  String get noScaleFoundStepOn =>
      'No scale found. Step on the scale so it wakes up, then scan again.';

  @override
  String get stepOnTheScaleBefore =>
      'Step on the scale before scanning so it wakes up. Later, use + → RENPHO Scale to take a measurement.';

  @override
  String get renphoCredentialsAreStoredEncrypted =>
      'Renpho credentials are stored encrypted on your device. Fjelia talks directly to the Renpho cloud API.';

  @override
  String get couldNotSendSmsCheck =>
      'Could not send SMS. Check your phone number and internet connection.';

  @override
  String get theEmailIsUsedFor =>
      'The email is used for secure request signing and is not sent to Suunto servers.';

  @override
  String get suuntoUsesSmsVerificationSame =>
      'Suunto uses SMS verification (same as the Suunto app). A one-time PIN will be sent to your phone. Your credentials are stored encrypted on-device only.';

  @override
  String get tellUsAboutYourRace =>
      'Tell us about your race and schedule. Fjelia builds your plan now and works out your level from your past activities (Garmin, Suunto, Polar, COROS, Apple Health) once they are downloaded.';

  @override
  String get noAccountConnectedSoFjelia =>
      'No account connected, so Fjelia has no history to learn from. Connect Garmin, Suunto, Polar, COROS or Apple Health and your real training decides instead.';

  @override
  String get yourPastActivitiesAreStill =>
      'Your past activities are still being imported. You can build your plan now — it is refined automatically when the import finishes.';

  @override
  String get buildingYourPlan => 'Building your plan…';

  @override
  String get saveContinue => 'Save & Continue';

  @override
  String get addYourMainPriorityA =>
      'Add your main (priority A) race. The plan is periodised towards it: base, build, peak and taper. Without a race goal no plan is generated yet.';

  @override
  String get noMeasurementsYet => 'No measurements yet';

  @override
  String get date => 'Date';

  @override
  String deepSleepIsBelowOptimal(Object round) {
    return 'Deep sleep is below optimal ($round%). Avoid alcohol and heavy meals 3h before bed.';
  }

  @override
  String get finishWithSetsOpen => 'Finish with sets open?';

  @override
  String get completeThePlannedWorkout => 'Complete the planned workout?';

  @override
  String get marksThePlannedSessionAs =>
      'Marks the planned session as done with this workout.';

  @override
  String get discardThisWorkout => 'Discard this workout?';

  @override
  String get removesTheWorkoutAndEvery =>
      'Removes the workout and every set recorded in it.';

  @override
  String assistanceName(Object name) {
    return 'Assistance ($name)';
  }

  @override
  String get enterSecondsOrMSs => 'Enter seconds or m:ss.';

  @override
  String get enterTheLoadAsA => 'Enter the load as a number.';

  @override
  String get loadCannotBeNegative => 'Load cannot be negative.';

  @override
  String get enterTheEffortValue => 'Enter the effort value.';

  @override
  String get nameTheExercise => 'Name the exercise.';

  @override
  String get atLeastOneImplement => 'At least one implement.';

  @override
  String get anIncrementMustBePositive => 'An increment must be positive.';

  @override
  String get enterAPositiveStep => 'Enter a positive step.';

  @override
  String get repsInReserve => 'Reps in reserve';

  @override
  String get loadPerImplement => 'Load per implement';

  @override
  String get restAfterThisSet => 'Rest after this set';

  @override
  String get enterHowLongTheSet => 'Enter how long the set lasted.';

  @override
  String get repsDonePerSide => 'Reps done per side';

  @override
  String plannedRepminRepmax(Object repMin, Object repMax) {
    return 'Planned $repMin–$repMax';
  }

  @override
  String get restTakenBeforeTheNext => 'Rest taken before the next set';

  @override
  String get equipment => 'Equipment';

  @override
  String get implementsUsedTogether => 'Implements used together';

  @override
  String get smallestLoadStepOptional => 'Smallest load step (optional)';

  @override
  String get theSmallestChangeYourPlates =>
      'The smallest change your plates, dumbbells or machine allow, remembered for this equipment.';

  @override
  String get loadStep => 'Load step';

  @override
  String get finishWithIncompleteData => 'Finish with incomplete data?';

  @override
  String get leaveWithoutSaving => 'Leave without saving?';

  @override
  String get theLastChangeCouldNot => 'The last change could not be saved.';

  @override
  String get comparedWithAPlanChosen =>
      'Compared with a plan chosen after the workout. Planned values are hints, not results.';

  @override
  String get lastSet => 'Last set';

  @override
  String get templateName => 'Template name';

  @override
  String get betweenExercises => 'Between exercises';

  @override
  String get betweenRounds => 'Between rounds';

  @override
  String get discardChanges => 'Discard changes?';

  @override
  String get yourEditsToThisWorkout =>
      'Your edits to this workout are not saved.';

  @override
  String get estimatedDuration => 'Estimated duration';

  @override
  String get workingSets => 'Working sets';

  @override
  String get estimatedExternalVolume => 'Estimated external volume';

  @override
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion) {
    return 'Load raised from $unit to $unit2 after your review (rule v$ruleVersion).';
  }

  @override
  String get thePlannedWorkoutHasNo =>
      'The planned workout has no exercises to log from.';

  @override
  String get completedSets => 'Completed sets';

  @override
  String get knownExternalVolume => 'Known external volume';

  @override
  String get updateStrengthSessions2 => 'Update strength sessions?';

  @override
  String get upcomingSessionsArePlannedAgain =>
      'Upcoming sessions are planned again from today: strength follows your race goals on every strength day, with sessions that vary. Completed and skipped workouts stay; exercises you changed in an upcoming strength session are replaced.';

  @override
  String get thisSessionUsesAnEarlier =>
      'This session uses an earlier strength template. Updated plans vary strength by phase and race goal and use every strength day.';

  @override
  String get estimated1rmUsesEpleyAnd =>
      'Estimated 1RM uses Epley and Brzycki on completed working sets of 1–10 reps with a known load, shown as the range between them. It is an estimate, not a tested maximum.';

  @override
  String get localWeather => 'Local weather';

  @override
  String get today => 'Today';

  @override
  String get low => 'Low';

  @override
  String get moderate => 'Moderate';

  @override
  String get overcast => 'Overcast';

  @override
  String get partlyCloudy => 'Partly cloudy';

  @override
  String collapseName(Object name) {
    return 'Collapse $name';
  }

  @override
  String get variableLoads => 'Variable loads';

  @override
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  ) {
    return 'Rule v$strengthProgressionRuleVersion: the last $strengthProgressionMinSessions comparable sessions, every set done at the top of its repetition target with effort recorded and not harder than intended. $reason';
  }

  @override
  String get stepOnYourScaleBefore => 'Step on your scale before scanning';

  @override
  String get scanning => 'Scanning…';

  @override
  String get pair => 'Pair';

  @override
  String get selectYourAktiiaPWristband =>
      'Select your AKTIIA P… wristband. Place it on the charger to wake it up if not visible.';

  @override
  String get measurementInterruptedWhileTheApp =>
      'Measurement interrupted while the app was in the background. Please repeat it.';

  @override
  String get noRecentRrDataWith =>
      'No recent RR data with good contact. Check the strap and repeat the measurement.';

  @override
  String get settlingStayStill => 'Settling · stay still';

  @override
  String get deleteSpotHrvMeasurement => 'Delete spot HRV measurement?';

  @override
  String get thisRemovesTheRecordingAnd =>
      'This removes the recording and its raw RR intervals.';

  @override
  String get appleHealthStoppedAnsweringSo =>
      'Apple Health stopped answering, so Fjelia disconnected it and no longer reads or writes Health data.\n\nAllow Fjelia again under Settings → Health → Data Access & Devices → Fjelia, then reconnect Apple Health.';

  @override
  String get thisRemovesTheSelectedGrip =>
      'This removes the selected grip reading.';

  @override
  String get hideReminderDiagnostics => 'Hide reminder diagnostics';

  @override
  String get loading => 'Loading…';

  @override
  String get touchTheChartForDetails => 'Touch the chart for details';

  @override
  String get indoor => 'Indoor';

  @override
  String get road => 'Road';

  @override
  String get technical => 'Technical';

  @override
  String get snow => 'Snow';

  @override
  String get pool => 'Pool';

  @override
  String get openWater => 'Open water';

  @override
  String get ambientTemperatureC => 'Ambient temperature °C';

  @override
  String carryAboutGelsGelsGelcarbs(
    Object gels,
    Object gelCarbs,
    Object bottles,
    Object bottleMl,
    Object drinkCarbs,
  ) {
    return 'Carry about $gels gels ($gelCarbs g carbs each) + $bottles × $bottleMl ml bottles. $drinkCarbs g carbohydrate comes from the drink mix.';
  }

  @override
  String get intakeNotRecorded => 'Intake not recorded';

  @override
  String get loggingDeclinedIntakeUnknown =>
      'Logging declined — intake unknown';

  @override
  String get confirmedNoIntake => 'Confirmed: no intake';

  @override
  String get draft => 'Draft · ';

  @override
  String get actualIntakePerServing => 'Actual intake · per serving';

  @override
  String get minuteIntoWorkoutDuringOnly =>
      'Minute into workout (during only, optional)';

  @override
  String get sodiumMgServingNotSalt => 'Sodium mg / serving (not salt)';

  @override
  String get comfortable => 'Comfortable';

  @override
  String get mildSymptoms => 'Mild symptoms';

  @override
  String get moderateSymptoms => 'Moderate symptoms';

  @override
  String get severeSymptoms => 'Severe symptoms';

  @override
  String get personalNutritionSettings => 'Personal nutrition settings';

  @override
  String get practisedCarbohydrateToleranceGH =>
      'Practised carbohydrate tolerance g/h (up to 120)';

  @override
  String get exportTheMonthlyReportAs =>
      'Export the monthly report as PDF in the Hilo app, then choose it here. Only the readings are imported; name, e-mail and body data in the report are ignored.';

  @override
  String get nothingNewAllReadingsWere =>
      'Nothing new: all readings were already stored.';

  @override
  String get historyImportIncomplete => 'History import incomplete';

  @override
  String get youCanKeepUsingFjelia =>
      'You can keep using Fjelia, but keep it open: iOS pauses the import when the app is in the background and it continues the next time you open Fjelia. Your plan is calibrated when the import finishes.';

  @override
  String get addYourBirthYearIn =>
      'Add your birth year in Settings → Profile to see your estimate.';

  @override
  String get fitnessAge => 'Fitness Age';

  @override
  String get estLifespan => 'Est. Lifespan';

  @override
  String get delta => 'Delta';

  @override
  String couldNotOpenKey(Object key) {
    return 'Could not open $key';
  }

  @override
  String get appleIntelligenceIsNotAvailable =>
      'Apple Intelligence is not available on this device (it needs a supported iPhone or Mac with iOS/macOS 26 or later and Apple Intelligence switched on in Settings). Choose another provider and add your own API key to use the coach.';

  @override
  String get personalisedMorningLunchAfternoonEvening =>
      'Personalised morning/lunch/afternoon/evening summary';

  @override
  String get enterASubject => 'Enter a subject.';

  @override
  String get message => 'Message';

  @override
  String get enterAMessageOfAt => 'Enter a message of at least 10 characters.';

  @override
  String get garminConnect => 'Garmin Connect';

  @override
  String get hiloBloodPressure => 'Hilo (Blood Pressure)';

  @override
  String get renphoBodyScale => 'Renpho (Body Scale)';

  @override
  String get hiloPodCuff => 'Hilo pod / cuff';

  @override
  String disconnectLabel(Object label) {
    return 'Disconnect $label?';
  }

  @override
  String get yourSavedMeasurementsWillRemain =>
      'Your saved measurements will remain on this device.';

  @override
  String get notEnoughRecentHeartRate =>
      'Not enough recent heart-rate data to adjust zones.';

  @override
  String get aerobicBase => 'Aerobic Base';

  @override
  String get tempo => 'Tempo';

  @override
  String get lactateThreshold => 'Lactate Threshold';

  @override
  String get birthYearHeightWaist => 'Birth year, height, waist';

  @override
  String get enterAValidValue => 'Enter a valid value';

  @override
  String get birthYear => 'Birth year';

  @override
  String get height => 'Height';

  @override
  String get waist => 'Waist';

  @override
  String get yearsSinceQuit => 'Years since quit';

  @override
  String get cigarettesPerDay => 'Cigarettes per day';

  @override
  String get standardDrinksPerMonth => 'Standard drinks per month';

  @override
  String get enterAValidNumber => 'Enter a valid number';

  @override
  String get enterARaceName => 'Enter a race name';

  @override
  String get useHMmOrH => 'Use h:mm or h:mm:ss, a time you could really run';

  @override
  String get flexibleThePlanMayDrop =>
      'Flexible: the plan may drop this event if it clashes with a more important one.';

  @override
  String get selectARaceDate => 'Select a race date';

  @override
  String thatIsTenTimesOr(Object likely) {
    return 'That is ten times (or a tenth of) the usual $likely km. Use $likely km instead?';
  }

  @override
  String get addGoal => 'Add Goal';

  @override
  String get restoreFailed => 'Restore failed';

  @override
  String get replaceLocalData => 'Replace local data?';

  @override
  String get restoringThisBackupReplacesAll =>
      'Restoring this backup replaces all local health and training records. Existing login credentials are kept.';

  @override
  String get openingBackupZip => 'Opening backup ZIP';

  @override
  String get addAFutureRaceGoal => 'Add a future race goal first.';

  @override
  String get deleteAllWorkouts2 => 'Delete all workouts?';

  @override
  String get thisDeletesPlannedWorkoutsOn =>
      'This deletes planned workouts on this phone and on your connected watch platform. Completed activities are kept.';

  @override
  String get regenerateWorkouts2 => 'Regenerate workouts?';

  @override
  String get noRaceGoalsYetAdd =>
      'No race goals yet. Add one or sync from Garmin.';

  @override
  String get deleteRaceGoal => 'Delete race goal?';

  @override
  String deletingFailedFailure(Object failure) {
    return 'Deleting failed: $failure';
  }

  @override
  String allPlannedWorkoutsDeletedRemoved(Object removed) {
    return 'All planned workouts deleted. Removed from your platforms: $removed.';
  }

  @override
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return 'Using current location: $toStringAsFixed, $toStringAsFixed2';
  }

  @override
  String get typeSleep => 'Sleep';

  @override
  String get typeBloodPressure => 'Blood Pressure';

  @override
  String get addHiloBpReportPdf => 'Add Hilo BP report (PDF)';

  @override
  String get hiloCuffBle => 'Hilo Cuff (BLE)';

  @override
  String get typeSpo2 => 'SpO₂ / Pulse Oximeter';

  @override
  String get typeWeightScale => 'Weight Scale';

  @override
  String get polarH10HrvMeasurement => 'Polar H10 HRV measurement';

  @override
  String samplingWouldStartMinutes(Object minutes) {
    return 'Sampling would start about $minutes min after your workout ended.';
  }

  @override
  String samplingStartedMinutes(Object minutes) {
    return 'Sampling started $minutes min after your workout ended.';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get before => 'Before';

  @override
  String get during => 'During';

  @override
  String get after => 'After';

  @override
  String get enumWarmUp => 'Warm-up';

  @override
  String get enumWorking => 'Working';

  @override
  String get enumBackOff => 'Back-off';

  @override
  String get enumTechnique => 'Technique';

  @override
  String get enumExternalLoad => 'External load';

  @override
  String get enumBandResistance => 'Band / resistance';

  @override
  String get enumTotalLoad => 'Total load';

  @override
  String get enumPerImplement => 'Per implement';

  @override
  String get enumOneImplement => 'One implement';

  @override
  String get enumBothSides => 'Both sides';

  @override
  String get enumAlternatingTotalReps => 'Alternating, total reps';

  @override
  String get enumPartial => 'Partial';

  @override
  String get enumFailed => 'Failed';

  @override
  String get enumStraightSets => 'Straight sets';

  @override
  String get enumSuperset => 'Superset';

  @override
  String get enumCircuit => 'Circuit';

  @override
  String get enumRir => 'RIR';

  @override
  String get enumRpe110 => 'RPE 1–10';

  @override
  String get enumBeforeTraining => 'Before training';

  @override
  String get enumAfterTraining => 'After training';

  @override
  String get enumResting => 'Resting';

  @override
  String get enumSeated => 'Seated';

  @override
  String get enumLyingDown => 'Lying down';

  @override
  String get duringRoutineGelsAreNot =>
      'During: routine gels are not needed for this short/easy session. Drink to thirst.';

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      'During: spread carbohydrate and drinks over small, regular feeds. Count drink carbohydrate in the same total as gels and food.';

  @override
  String get fluidIsAnEditableStarting =>
      'Fluid is an editable starting estimate, not a quota. Use thirst, practised intake and measured sweat losses; do not force extra water.';

  @override
  String get afterHaveCarbohydrateAndA =>
      'After: have carbohydrate and a protein-containing meal. Prioritise refuelling and rehydration when another session is soon.';

  @override
  String get swimmingPlaceALabelledBottle =>
      'Swimming: place a labelled bottle on the pool deck and use set breaks for sips or feeds. Pool conditions may differ from outdoor weather.';

  @override
  String get runningCarryAccessibleGelsFlasks =>
      'Running: carry accessible gels/flasks or plan aid-station feeds; practise the same products and timing before racing.';

  @override
  String get servingSizesAndToleranceMust =>
      'Serving sizes and tolerance must be positive.';

  @override
  String get enterFiniteNonNegativeMeasurements =>
      'Enter finite, non-negative measurements.';

  @override
  String get targetsMustBeFiniteAnd =>
      'Targets must be finite and non-negative.';

  @override
  String get conditionsMustBeFiniteOr =>
      'Conditions must be finite or unknown.';

  @override
  String get humidityMustBeBetween0 => 'Humidity must be between 0 and 100%.';

  @override
  String get noIntakeCannotIncludeFood =>
      '“No intake” cannot include food or drinks.';

  @override
  String get addAnItemOrConfirm =>
      'Add an item or confirm that you had no intake.';

  @override
  String get eachIntakeNeedsAProduct =>
      'Each intake needs a product and a valid timing.';

  @override
  String get quantityMustBePositive => 'Quantity must be positive.';

  @override
  String get thisActivityNoLongerExists => 'This activity no longer exists.';

  @override
  String get practisedCarbohydrateToleranceMustNot =>
      'Practised carbohydrate tolerance must not exceed 120 g/h.';

  @override
  String get measuredSweatRateMustBe =>
      'Measured sweat rate must be positive or left unknown.';

  @override
  String get increasePractisedToleranceInNutrition =>
      'Increase practised tolerance in Nutrition settings before choosing a higher target.';

  @override
  String get fluidTargetExceedsYourMeasured =>
      'Fluid target exceeds your measured sweat rate. Review the measurement or target.';

  @override
  String get elapsedWorkoutTimeMustBe =>
      'Elapsed workout time must be positive or left blank.';

  @override
  String get intakeAmountsMustBeFinite =>
      'Intake amounts must be finite and non-negative.';

  @override
  String get selectedStrategyUnavailableChooseAnother =>
      'Selected strategy unavailable. Choose another strategy or no comparison.';

  @override
  String get recordYourWorkoutNutrition => 'Record your workout nutrition';

  @override
  String get addTheFoodAndFluids =>
      'Add the food and fluids you actually consumed in your activity history.';

  @override
  String get logIntake => 'Log intake';

  @override
  String get in30Minutes => 'In 30 minutes';

  @override
  String get loadSuggestionsCoverStraightSets =>
      'Load suggestions cover straight sets with repetitions only.';

  @override
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  ) {
    return 'Needs $strengthProgressionMinSessions recorded sessions of this exercise.';
  }

  @override
  String get recentHistoryIsTooOld =>
      'Recent history is too old for a suggestion.';

  @override
  String get theLastSessionDidNot =>
      'The last session did not use one known load.';

  @override
  String get theLoadChangedBetweenThe =>
      'The load changed between the recent sessions.';

  @override
  String get notEverySetReachedThe =>
      'Not every set reached the top of its repetition target.';

  @override
  String get recordEffortRirOrRpe =>
      'Record effort (RIR or RPE) on the last set to get suggestions.';

  @override
  String get recentSetsWereHarderThan =>
      'Recent sets were harder than intended.';

  @override
  String get thisWorkoutAlreadyHasIts =>
      'This workout already has its own load; it stays as set.';

  @override
  String get yourRecentSetsMetThe =>
      'Your recent sets met the progression rule. Set the smallest load step for this equipment to review a load.';

  @override
  String get thisWorkoutNoLongerExists => 'This workout no longer exists.';

  @override
  String thisStrengthPlanCannotBe(Object message) {
    return 'This strength plan cannot be read ($message).';
  }

  @override
  String get thisStrengthPlanCannotBe2 => 'This strength plan cannot be read.';

  @override
  String get addAtLeastOneExercise => 'Add at least one exercise.';

  @override
  String get thisWorkoutWasChangedElsewhere =>
      'This workout was changed elsewhere. Your edits are kept; reload to see the newer version.';

  @override
  String get thePlanThisWorkoutIs =>
      'The plan this workout is compared with cannot be read.';

  @override
  String get thisLogWasChangedElsewhere =>
      'This log was changed elsewhere. Your entries are kept; reload to see the newer version.';

  @override
  String get thisZipIsNotA => 'This ZIP is not a supported Fjelia backup.';

  @override
  String get theBackupDatabaseIsDamaged => 'The backup database is damaged.';

  @override
  String get invalidBackupData => 'Invalid backup data.';

  @override
  String get backupTablesDoNotMatch => 'Backup tables do not match.';

  @override
  String get invalidBackupColumns => 'Invalid backup columns.';

  @override
  String get migratingOriginalAppBackup => 'Migrating original app backup';

  @override
  String get theOriginalBackupIsMissing =>
      'The original backup is missing required tables.';

  @override
  String get backupFormatOrDatabaseVersion =>
      'Backup format or database version does not match.';

  @override
  String get restoringRecords => 'Restoring records';

  @override
  String get restoringSettings => 'Restoring settings';

  @override
  String get restoreComplete => 'Restore complete';

  @override
  String get effortMustBeANumber => 'Effort must be a number.';

  @override
  String get theDurationEstimateMustBe =>
      'The duration estimate must be positive.';

  @override
  String get restCannotBeNegative => 'Rest cannot be negative.';

  @override
  String get enterTheRepetitionsDoneThe =>
      'Enter the repetitions done; the plan has a range.';

  @override
  String get enterTheLoadThePlan => 'Enter the load; the plan has none.';

  @override
  String get enterTheResistanceThePlan =>
      'Enter the resistance; the plan has none.';

  @override
  String get poorSensorContact => 'Poor sensor contact';

  @override
  String get moreThan25FromLocal => 'More than 25% from local median';

  @override
  String get workoutNutrition => 'Workout nutrition';

  @override
  String get postWorkoutFoodAndFluid =>
      'Post-workout food and fluid log reminder';

  @override
  String get postTrainingHrvMeasurementReminder =>
      'Post-training HRV measurement reminder';

  @override
  String get rirRunsFrom0To => 'RIR runs from 0 to 10+.';

  @override
  String get rpeRunsFrom1To => 'RPE runs from 1 to 10.';

  @override
  String get repetitionsCannotBeNegative => 'Repetitions cannot be negative.';

  @override
  String get timedWorkMustBeLonger =>
      'Timed work must be longer than zero seconds.';

  @override
  String get chooseRepetitionsOrTimedWork =>
      'Choose repetitions or timed work, not both.';

  @override
  String get loadMustBeAFinite => 'Load must be a finite, non-negative number.';

  @override
  String get durationCannotBeNegative => 'Duration cannot be negative.';

  @override
  String get hrTimeline => 'HR Timeline';

  @override
  String get dayTrainingLoad => 'Day Training Load';

  @override
  String get weekdayComparison => 'Weekday Comparison';

  @override
  String get weeklyTrainingLoad => 'Weekly Training Load';

  @override
  String get zonePolarization => 'Zone Polarization';

  @override
  String get elevationOverview => 'Elevation Overview';

  @override
  String get trainingMonitor => 'Training Monitor';

  @override
  String get formAtlCtlTsb => 'ATL / CTL / TSB Form';

  @override
  String get trainingPlanProgress => 'Training Plan Progress';

  @override
  String get rhrSleep => 'RHR Sleep';

  @override
  String get hrvSleep => 'HRV Sleep';

  @override
  String get spo2Sleep => 'SpO₂ Sleep';

  @override
  String get respRate => 'Resp Rate';

  @override
  String get stress => 'Stress';

  @override
  String get skinTemp => 'Skin Temp';

  @override
  String get steps => 'Steps';

  @override
  String get tonightsSleep => 'Tonight\'s Sleep';

  @override
  String get activityLog => 'Activity Log';

  @override
  String get activityLog2 => 'Activity log';

  @override
  String get history2 => 'HISTORY';

  @override
  String durationsecondshDurationseconds2mDistancemetersKmAvgheartrate(
    Object durationSeconds,
    Object durationSeconds2,
    Object distanceMeters,
    Object avgHeartRate,
    Object totalElevation,
  ) {
    return '${durationSeconds}h ${durationSeconds2}m · $distanceMeters km · $avgHeartRate bpm · ↑$totalElevation m';
  }

  @override
  String get heatAcclimation2 => 'HEAT ACCLIMATION';

  @override
  String score(Object score) {
    return '$score%';
  }

  @override
  String get elevation => 'ELEVATION';

  @override
  String get t12WeekHistory => '12-WEEK HISTORY';

  @override
  String get zonePolarization2 => 'ZONE POLARIZATION';

  @override
  String get t5WeekHistory => '5-WEEK HISTORY';

  @override
  String get easy => 'EASY %';

  @override
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded) {
    return '$withZones of $recorded activities with HR-zone data';
  }

  @override
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples) {
    return '$fromSamples reconstructed from recorded HR samples';
  }

  @override
  String get easyZ12ModerateZ3 => 'Easy: Z1–2 · Moderate: Z3 · Hard: Z4–5';

  @override
  String get activitiesWithoutHrZoneData =>
      'Activities without HR-zone data are excluded from percentages.';

  @override
  String avgAverageUnit(Object average, Object unit) {
    return 'AVG  $average $unit';
  }

  @override
  String get weekdayComparison2 => 'WEEKDAY COMPARISON';

  @override
  String get trainingPlanProgress2 => 'TRAINING PLAN PROGRESS';

  @override
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  ) {
    return 'Week $currentWeek / $durationInWeeks';
  }

  @override
  String get t30MinTimeTrialLt2 => '30-MIN TIME TRIAL — LT2';

  @override
  String get run30MinutesAtThe =>
      'Run 30 minutes at the hardest effort you can sustain — controlled, not sprinting. Build into the effort; do not start too fast. The average pace and HR of the final 20 minutes are your LT2.';

  @override
  String get recordAsANormalOutdoor =>
      'Record as a normal outdoor run. Start your watch, note the time, run 30 min at race effort.';

  @override
  String get t50MinTotalFlatCourse =>
      '~50 min total · flat course · not after hard training';

  @override
  String get doNotStartTooFast => 'Do not start too fast. Aim for even splits.';

  @override
  String get theAppAveragesHrAnd =>
      'The app averages HR and pace over the final 20 minutes of the TT, after the warm-up and first 10 minutes. Select the recorded activity in Calculate.';

  @override
  String get lt2Pace => 'LT2 PACE';

  @override
  String get activityRunningEnoughTimeFor =>
      'Activity (running, enough time for warm-up + 30 min, with HR)';

  @override
  String get selectTheTtActivity => 'Select the TT activity';

  @override
  String nameStartdate(Object name, Object startDate) {
    return '$name · $startDate';
  }

  @override
  String get warmUpBeforeTt => 'Warm-up before TT';

  @override
  String roundMin(Object round) {
    return '$round min';
  }

  @override
  String get clearResults => 'Clear results';

  @override
  String get heartRate2 => 'HEART RATE';

  @override
  String get paceSecKmLowerIs => 'PACE (sec/km — lower is faster)';

  @override
  String get thresholdsFitnessTests => 'Thresholds & Fitness Tests';

  @override
  String get lt1 => 'LT1';

  @override
  String get lt2 => 'LT2';

  @override
  String get voPace => 'VO₂ Pace';

  @override
  String get ftp => 'FTP';

  @override
  String get setFtpManually => 'Set FTP manually';

  @override
  String get calculateFromAnActivity => 'Calculate from an activity';

  @override
  String get setFtp => 'Set FTP';

  @override
  String get ftpWatts => 'FTP (watts)';

  @override
  String get ftpCyclingThresholdPower => 'FTP — CYCLING THRESHOLD POWER';

  @override
  String get ftpHistory => 'FTP HISTORY';

  @override
  String get updateFromActivity => 'UPDATE FROM ACTIVITY';

  @override
  String get tapAnActivityFtpBest =>
      'Tap an activity — FTP = best 20-min power × 0.95';

  @override
  String ridew(Object ride) {
    return '${ride}W';
  }

  @override
  String ftpRoundw(Object round) {
    return '→ FTP ${round}W';
  }

  @override
  String get noRidesWith20Minutes =>
      'No rides with 20 minutes of continuous power samples.';

  @override
  String get enterFtpManually => 'Enter FTP manually';

  @override
  String get selectTheTestActivity => 'Select the test activity';

  @override
  String get formAtlCtlTsb2 => 'FORM · ATL / CTL / TSB';

  @override
  String get closeTrainingFormFullscreen => 'Close training form fullscreen';

  @override
  String get expandTrainingForm => 'Expand training form';

  @override
  String get calculatedFromTheFirstAvailable =>
      'Calculated from the first available load record. Days without recorded load count as zero; earlier training is unknown.';

  @override
  String get trainingMonitor2 => 'TRAINING MONITOR';

  @override
  String get pfitzingerZones => 'PFITZINGER ZONES';

  @override
  String get cyclingPowerZones => 'CYCLING POWER ZONES';

  @override
  String znumber(Object number) {
    return 'Z$number';
  }

  @override
  String paceHrDescription(Object pace, Object hr, Object description) {
    return '$pace · $hr\n$description';
  }

  @override
  String get weeklyTrainingLoad2 => 'WEEKLY TRAINING LOAD';

  @override
  String get prevWeek => 'PREV WEEK';

  @override
  String get bySport => 'BY SPORT';

  @override
  String get noActivitiesThisWeek => 'No activities this week';

  @override
  String garminWorkoutScheduleddate(Object scheduledDate) {
    return 'Garmin Workout · $scheduledDate';
  }

  @override
  String get yourNote => 'Your note';

  @override
  String get askAiCoach => 'Ask AI Coach';

  @override
  String get aiSettings => 'AI settings';

  @override
  String get askYourCoach => 'Ask your coach…';

  @override
  String get sendMessage => 'Send message';

  @override
  String get sendFeedbackOrReportA => 'Send feedback or report a bug';

  @override
  String get addMeasurement2 => 'Add measurement';

  @override
  String get syncLabel2 => 'Sync';

  @override
  String get syncToday => 'Sync Today';

  @override
  String get fullSync1Year => 'Full Sync · 1 year';

  @override
  String get fullSyncComplete => 'Full Sync · Complete';

  @override
  String get syncingYourData => 'Syncing your data…';

  @override
  String lLeftkgRRightkgKg2(Object leftKg, Object rightKg) {
    return 'L $leftKg  R $rightKg kg';
  }

  @override
  String weightKgFatBodyfatMuscle(
    Object weight,
    Object bodyFat,
    Object muscleMass,
  ) {
    return '$weight kg · Fat $bodyFat% · Muscle $muscleMass kg';
  }

  @override
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase) {
    return '$title, $sport, $toLowerCase';
  }

  @override
  String get weatherUnavailableTapToRetry =>
      'Weather unavailable · Tap to retry';

  @override
  String get weatherSetYourLocation => 'Weather · Set your location';

  @override
  String get t7DayForecast => '7-DAY FORECAST';

  @override
  String get minMax => 'min/max';

  @override
  String get rainMm2 => 'rain mm';

  @override
  String get uvMax => 'UV max';

  @override
  String get kmH => 'km/h';

  @override
  String alt(Object alt) {
    return '→ $alt';
  }

  @override
  String raceGoalsLength(Object length) {
    return 'Race goals · $length';
  }

  @override
  String gWk(Object g) {
    return '$g wk';
  }

  @override
  String weeks(Object weeks) {
    return '$weeks';
  }

  @override
  String get weeks2 => 'weeks';

  @override
  String get upcoming => 'UPCOMING';

  @override
  String lengthMoreDays(Object length) {
    return '+ $length more days';
  }

  @override
  String yearMonth(Object year, Object month) {
    return '$year / $month';
  }

  @override
  String day(Object day) {
    return '$day';
  }

  @override
  String get plannedCompletedSkipped => '○ Planned   ● Completed   ✕ Skipped';

  @override
  String get heartRate3 => 'Heart rate';

  @override
  String get watts => 'Watts';

  @override
  String theStepsAddUpTo(Object total, Object plannedDurationMin) {
    return 'The steps add up to $total; the plan counts $plannedDurationMin min.';
  }

  @override
  String get typicalSplitForThisKind =>
      'Typical split for this kind of session; no steps to calculate it from.';

  @override
  String labelGetsEachExerciseWith(Object label) {
    return '$label gets each exercise with its sets, reps and loads. Rep ranges, effort and tempo stay in Fjelia.';
  }

  @override
  String get markAsRest => 'Mark as Rest';

  @override
  String get restoreWorkout => 'Restore workout';

  @override
  String get skipThisWorkout => 'Skip this workout?';

  @override
  String get previousWeek => 'Previous week';

  @override
  String get backToThisWeek => 'Back to this week';

  @override
  String get thisWeek => 'This week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get today2 => 'TODAY';

  @override
  String get route => 'ROUTE';

  @override
  String get feedback => 'Feedback';

  @override
  String get plannedWorkout => 'Planned Workout';

  @override
  String get delete => 'Delete';

  @override
  String get chatAi => 'Chat AI';

  @override
  String get trainingLoad => 'Training Load';

  @override
  String get dayTrainingLoad2 => 'DAY TRAINING LOAD';

  @override
  String get trimp => ' TRIMP';

  @override
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter) {
    return '$scoreBefore → $scoreAfter';
  }

  @override
  String get temperatureOverTime => 'TEMPERATURE OVER TIME';

  @override
  String roundh(Object round) {
    return '${round}h';
  }

  @override
  String get timeInHrZones => 'Time in HR zones';

  @override
  String get route2 => 'Route';

  @override
  String get start => 'Start';

  @override
  String get gpx => 'GPX';

  @override
  String touppercasesubstringBriefing(Object toUpperCase, Object substring) {
    return '$toUpperCase$substring Briefing';
  }

  @override
  String get chatWithAiAboutThis => 'Chat with AI about this briefing';

  @override
  String get whyThisRecommendation => 'Why this recommendation?';

  @override
  String titleDateLabel(Object title, Object date, Object label) {
    return '$title, $date, $label';
  }

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get updating => 'Updating';

  @override
  String get resting => 'RESTING';

  @override
  String get noTimedReadings => 'No timed readings';

  @override
  String get avg => 'AVG';

  @override
  String get peak => 'PEAK';

  @override
  String tolocalRoundmin(Object toLocal, Object round) {
    return '$toLocal · ${round}min';
  }

  @override
  String avgheartrateBpmAvg(Object avgHeartRate) {
    return '$avgHeartRate bpm avg';
  }

  @override
  String get timeWeightedAverageOverRecorded =>
      'Time-weighted average over recorded periods. Gaps without readings are excluded.';

  @override
  String get previousHeartRatePeriod => 'Previous heart-rate period';

  @override
  String get nextHeartRatePeriod => 'Next heart-rate period';

  @override
  String get avgHr => 'Avg HR';

  @override
  String get restingHr => 'Resting HR';

  @override
  String get both => 'Both';

  @override
  String averagelabelFixedMs(Object averageLabel, Object fixed) {
    return '$averageLabel $fixed ms';
  }

  @override
  String get measureWithPolarH10 => 'Measure with Polar H10';

  @override
  String get ms => 'ms';

  @override
  String get noWorkoutInThisPeriod =>
      'No workout in this period has a comparable before and after pair.';

  @override
  String textEachWorkoutCountsOnce(Object text) {
    return '$text. Each workout counts once; this describes your pairs, it does not score them.';
  }

  @override
  String get workoutFinished => 'Workout finished?';

  @override
  String get yourWorkoutIsNotIn =>
      'Your workout is not in Fjelia yet. If it ended, say when, and the reminder can follow its real end. Otherwise it appears once your watch syncs.';

  @override
  String get workoutFinished2 => 'Workout finished';

  @override
  String get theWorkoutMustStartAfter =>
      'The workout must start after the measurement and end after it started, not in the future.';

  @override
  String daysDAvg(Object days) {
    return '$days D AVG';
  }

  @override
  String averageUnit(Object average, Object unit) {
    return '$average $unit';
  }

  @override
  String baselineUnit(Object baseline, Object unit) {
    return '$baseline $unit';
  }

  @override
  String get previousPeriod => 'Previous period';

  @override
  String get nextPeriod => 'Next period';

  @override
  String get overnightHrvReflectsRecoveryCompare =>
      'Overnight HRV reflects recovery. Compare your readings with your own baseline over time.';

  @override
  String get moveThisWorkout => 'MOVE THIS WORKOUT';

  @override
  String get pickDate => 'Pick date';

  @override
  String movedFromMovedfrom(Object movedFrom) {
    return 'Moved from $movedFrom';
  }

  @override
  String get hrvAroundThisWorkout => 'HRV around this workout';

  @override
  String get measureAfterTraining => 'Measure after training';

  @override
  String get measureAgain => 'Measure again';

  @override
  String get explainWithAi => 'Explain with AI';

  @override
  String beforeEndedPregapAheadOf(Object preGap) {
    return 'Before ended $preGap ahead of the start.';
  }

  @override
  String lengthFurtherMeasurementSAfter(Object length) {
    return '$length further measurement(s) after this workout are kept as extra observations.';
  }

  @override
  String get noHrvMeasurementRecordedAround =>
      'No HRV measurement recorded around this workout.';

  @override
  String get measureHrv => 'Measure HRV';

  @override
  String deltamsMs(Object deltaMs) {
    return '$deltaMs ms';
  }

  @override
  String deltapercent(Object deltaPercent) {
    return '$deltaPercent %';
  }

  @override
  String get aDescriptionOfThisPair =>
      'A description of this pair, not a score for the workout.';

  @override
  String notEnoughComparableWorkoutsYet(Object eligible, Object need) {
    return 'Not enough comparable workouts yet, $eligible of $need.';
  }

  @override
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need) {
    return 'Not enough comparable workouts yet ($eligible of $need).';
  }

  @override
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  ) {
    return 'Your $eligible similar workouts · $toLocal–$toLocal2';
  }

  @override
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  ) {
    return 'Middle half $q1Ms to $q3Ms ms · median $medianMs ms · this workout $delta ms';
  }

  @override
  String rpeI(Object i) {
    return 'RPE $i';
  }

  @override
  String get easy2 => 'easy';

  @override
  String get allOut => 'all out';

  @override
  String workoutProfileDescription(Object description) {
    return 'Workout profile: $description';
  }

  @override
  String get noActivitiesInThisPeriod => 'No activities in this period';

  @override
  String get enableHeatAcclimationInTraining =>
      'Enable heat acclimation in Training settings.';

  @override
  String get noElevationThisWeek => 'No elevation this week';

  @override
  String get noActivitiesSynced => 'No activities synced';

  @override
  String get noHrZoneData => 'No HR-zone data';

  @override
  String get easyJogGetHrElevated => 'Easy jog — get HR elevated, legs loose';

  @override
  String get fastestSustainablePaceLikeA =>
      'Fastest sustainable pace — like a 30-min race';

  @override
  String get walkCardiacRecovery => 'Walk — cardiac recovery';

  @override
  String get selectTheTtActivityFirst => 'Select the TT activity first.';

  @override
  String get calculating => 'Calculating…';

  @override
  String get calculateLt2 => 'Calculate LT2';

  @override
  String get enterFtpBetween30And => 'Enter FTP between 30 and 1000 W.';

  @override
  String get aerobicThreshold => 'Aerobic Threshold';

  @override
  String get functionalThresholdPower => 'Functional Threshold Power';

  @override
  String get estimated => 'Estimated';

  @override
  String get afterWarmingUpRunFive =>
      'After warming up, run five minutes at your fastest sustainable effort. Record the run with speed or distance data.';

  @override
  String get recordAtLeast40Minutes =>
      'Record at least 40 minutes of steady running at a constant effort. The test compares heart rate in each half to estimate aerobic drift.';

  @override
  String get theFastestFiveMinuteWindow =>
      'The fastest five-minute window provides your VO2max pace.';

  @override
  String get noResultYet => 'No result yet';

  @override
  String get calculateVo2maxPace => 'Calculate VO2max pace';

  @override
  String get calculateLt1 => 'Calculate LT1';

  @override
  String get loading2 => 'Loading';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get noTrainingHistory => 'No training history';

  @override
  String get fitnessCtl => 'Fitness (CTL)';

  @override
  String get fatigueAtl => 'Fatigue (ATL)';

  @override
  String get formTsb => 'Form (TSB)';

  @override
  String get noHistory => 'No history';

  @override
  String get fresh => 'Fresh';

  @override
  String get optimal => 'Optimal';

  @override
  String get neutral => 'Neutral';

  @override
  String get tired => 'Tired';

  @override
  String get veryFatigued => 'Very Fatigued';

  @override
  String get garminRunningVo2max => 'Garmin running VO2max';

  @override
  String get garminCyclingVo2max => 'Garmin cycling VO2max';

  @override
  String get aerobicThreshold2 => 'Aerobic threshold';

  @override
  String driftDriftAt(Object drift, Object at) {
    return 'Drift $drift% · $at';
  }

  @override
  String get activityHours => 'Activity hours';

  @override
  String get activityKm => 'Activity km';

  @override
  String get tap5MinuteMaxTest => 'Tap · 5-minute max test';

  @override
  String get setFtpToCalculatePower => 'Set FTP to calculate power zones';

  @override
  String get cyclingPowerZones2 => 'Cycling power zones';

  @override
  String get pfitzingerZones2 => 'Pfitzinger zones';

  @override
  String get completeAnLt2TestTo =>
      'Complete an LT2 test to calculate running zones.';

  @override
  String get setFtpToCalculatePower2 => 'Set FTP to calculate power zones.';

  @override
  String get endurance => 'Endurance';

  @override
  String get threshold => 'Threshold';

  @override
  String get anaerobic => 'Anaerobic';

  @override
  String get whatExplainsThisRise => 'What explains this rise?';

  @override
  String get whatExplainsThisDrop => 'What explains this drop';

  @override
  String get whatExplainsThisRise2 => 'What explains this rise';

  @override
  String get editsAreKeptInFjelia =>
      'Edits are kept in Fjelia as a local copy for this date. The workout on Garmin is not changed.';

  @override
  String get howDoIExecuteThis => 'How do I execute this workout?';

  @override
  String shareHealthContextWithName(Object name) {
    return 'Share health context with $name?';
  }

  @override
  String get yourMessageAndAHealth =>
      'Your message and a health/training summary will be sent to this cloud AI provider. Names and GPS are excluded from the generated summary.';

  @override
  String get couldNotGetAReply =>
      'Could not get a reply. Check your AI settings and try again.';

  @override
  String get askAboutYourRecoveryTraining =>
      'Ask about your recovery, training, or today’s plan.';

  @override
  String get noSyncYet => 'No sync yet';

  @override
  String lastSyncLastContext(Object last, Object context) {
    return 'Last sync: $last $context';
  }

  @override
  String get seasonWithTradeOffs => 'Season: with trade-offs';

  @override
  String get seasonNeedsYourDecision => 'Season: needs your decision';

  @override
  String get seasonCannotBeCombined => 'Season: cannot be combined';

  @override
  String get seasonProvisional => 'Season: provisional';

  @override
  String get season => 'Season';

  @override
  String get allGoalsFit => 'All goals fit.';

  @override
  String goalTargetfinishsecondsgoal(Object targetFinishSeconds, Object goal) {
    return 'Goal $targetFinishSeconds$goal';
  }

  @override
  String estEstimateestimate2(Object estimate, Object estimate2) {
    return 'Est. $estimate$estimate2';
  }

  @override
  String doneDoneby(Object doneBy) {
    return 'Done · $doneBy';
  }

  @override
  String garminWorkoutWorkout(Object workout) {
    return 'Garmin Workout · $workout';
  }

  @override
  String get moveAnyway => 'Move anyway?';

  @override
  String get wattsNeedYourFtpSet =>
      'Watts need your FTP: set it under Load, Thresholds.';

  @override
  String get mainTargetInWattsFrom =>
      'Main target in watts from your FTP, heart rate as the guide.';

  @override
  String get mainTargetHeartRateWatts =>
      'Main target heart rate, watts are not set on the watch.';

  @override
  String get taperPhase => 'Taper phase';

  @override
  String get recoverySession => 'Recovery session';

  @override
  String get closeToYourEvent => 'Close to your event';

  @override
  String get noWorkoutStructureAvailable => 'No workout structure available.';

  @override
  String get aerobic => 'Aerobic';

  @override
  String get pushAgainToUpdateYour =>
      'Push again to update your watch calendar.';

  @override
  String workoutSentToLabel(Object label) {
    return 'Workout sent to $label';
  }

  @override
  String get updating2 => 'Updating…';

  @override
  String pushToLabel(Object label) {
    return 'Push to $label';
  }

  @override
  String shareExerciseListForLabel(Object label) {
    return 'Share exercise list for $label';
  }

  @override
  String shareWorkoutForLabel(Object label) {
    return 'Share workout for $label';
  }

  @override
  String get whyNothingIsAddedTo => 'Why? Nothing is added to make it up.';

  @override
  String get workout => 'Workout';

  @override
  String get recordedActivityLinkedToThis =>
      'Recorded activity linked to this workout';

  @override
  String get matchedToTheRecordedWorkout =>
      'Matched to the recorded workout start';

  @override
  String get matchedByWorkoutNameSport =>
      'Matched by workout name, sport and date';

  @override
  String get matchedBySportDateAnd => 'Matched by sport, date and duration';

  @override
  String planPlannedminutesMin(Object plannedMinutes) {
    return 'Plan $plannedMinutes min';
  }

  @override
  String get maxHr => 'Max HR';

  @override
  String get trainingLoad2 => 'Training load';

  @override
  String get active => 'Active';

  @override
  String get avgPace => 'Avg pace';

  @override
  String get avgSpeed => 'Avg speed';

  @override
  String get avgPower => 'Avg power';

  @override
  String get elevation2 => 'Elevation';

  @override
  String get altitude => 'Altitude';

  @override
  String get explainMyHrvBeforeAnd =>
      'Explain my HRV before and after this workout. What is comparable, what is not, and what is still unknown?';

  @override
  String get deleteActivity => 'Delete activity?';

  @override
  String get removeThisActivityFromThe =>
      'Remove this activity from the local history? A later provider sync may import it again.';

  @override
  String get howDidThisSessionGo =>
      'How did this session go, and what does it mean for my next days?';

  @override
  String currentFixedFixed2(Object fixed, Object fixed2) {
    return 'Current $fixed, $fixed2';
  }

  @override
  String get setUpInTrainingSettings => 'Set up in Training settings';

  @override
  String get couldNotLoadHeatData =>
      'Could not load heat data — tap for details';

  @override
  String get loadingHeatHistory => 'Loading heat history…';

  @override
  String get noHeatDataYet => 'No heat data yet';

  @override
  String optimalLowHigh(Object low, Object high) {
    return 'Optimal $low–$high';
  }

  @override
  String optimalLowHighTrimp(Object low, Object high) {
    return 'Optimal: $low–$high TRIMP';
  }

  @override
  String get targetUnavailableSyncTrainingHistory =>
      'Target unavailable — sync training history';

  @override
  String get workoutQualifiedForHeatAccumulation =>
      'Workout qualified for heat accumulation.';

  @override
  String get workoutDidNotAddHeat => 'Workout did not add heat accumulation.';

  @override
  String get performanceTime => 'Performance / Time';

  @override
  String get performanceDistance => 'Performance / Distance';

  @override
  String get noRecordedRoute => 'No recorded route';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get fitRoute => 'Fit route';

  @override
  String get fullscreenMap => 'Fullscreen map';

  @override
  String get openstreetmapContributors2 => 'OpenStreetMap contributors';

  @override
  String get appleIntelligenceIsUnavailableShowing =>
      'Apple Intelligence is unavailable. Showing a non-AI summary.';

  @override
  String get generateAiBriefing => 'Generate AI briefing?';

  @override
  String get retryAiBriefing => 'Retry AI briefing';

  @override
  String get generateBriefing => 'Generate briefing';

  @override
  String discussThisBriefingWithMe(Object text) {
    return 'Discuss this briefing with me and suggest the next best action.\n\n$text';
  }

  @override
  String whyThisRecommendationWhichOf(Object text) {
    return 'Why this recommendation? Which of my figures and which gaps in the data led to it, and what would change it?\n\n$text';
  }

  @override
  String get avg2 => 'Avg';

  @override
  String get peak2 => 'Peak';

  @override
  String get notEnoughContinuousReadingsFor =>
      'Not enough continuous readings for an average.';

  @override
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  ) {
    return 'Recorded coverage: ${inHours}h ${inMinutes}min · Time-weighted average';
  }

  @override
  String get lying => 'Lying';

  @override
  String get noHrvReadingsInThis => 'No HRV readings in this period';

  @override
  String get overnightHrvComesFromYour =>
      'Overnight HRV comes from your watch, spot readings from the Polar H10 (RMSSD). The methods differ: compare trends, not single values.';

  @override
  String get noReadings => 'No readings';

  @override
  String get whenDidTheWorkoutStart => 'When did the workout start?';

  @override
  String get whenDidItEnd => 'When did it end?';

  @override
  String get last3Months => 'Last 3 months';

  @override
  String get lastYear => 'Last year';

  @override
  String lastDaysDays(Object days) {
    return 'Last $days days';
  }

  @override
  String nowOnCurrentTapA(Object current) {
    return 'Now on $current. Tap a day, or drag the workout onto one. The steps stay as they are.';
  }

  @override
  String get monthView => 'Month view';

  @override
  String get syncing => 'Syncing';

  @override
  String get trendUnavailable => 'Trend unavailable';

  @override
  String get stable => 'Stable';

  @override
  String get increasing => 'Increasing';

  @override
  String get decreasing => 'Decreasing';

  @override
  String get unclear => 'Unclear';

  @override
  String get notComparable => 'Not comparable';

  @override
  String get waitingForAfter => 'Waiting for after';

  @override
  String get afterOnly => 'After only';

  @override
  String get waitingForTheActualWorkout =>
      'Waiting for the actual workout end.';

  @override
  String reminderAroundTolocal(Object toLocal) {
    return 'Reminder around $toLocal';
  }

  @override
  String get reminderIsDueMeasureWhen =>
      'Reminder is due. Measure when you are ready.';

  @override
  String get thisReminderIsNoLonger =>
      'This reminder is no longer current. Open the workout to view your measurements.';

  @override
  String beforeFixedMilliseconds(Object fixed) {
    return 'Before $fixed milliseconds. ';
  }

  @override
  String afterFixedMilliseconds(Object fixed) {
    return 'After $fixed milliseconds';
  }

  @override
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  ) {
    return 'Change $deltaMs milliseconds, $deltaPercent percent.';
  }

  @override
  String get noPreTrainingMeasurementRecorded =>
      'No pre-training measurement recorded.';

  @override
  String get notMeasuredYet => 'Not measured yet';

  @override
  String leftOutOfTheComparison(Object excludedTotal, Object c) {
    return 'Left out of the comparison: $excludedTotal workouts ($c).';
  }

  @override
  String get notFromThisWorkout => 'Not from this workout';

  @override
  String get useAsBefore => 'Use as before';

  @override
  String get useAsAfter => 'Use as after';

  @override
  String get beforeNotMeasured => 'Before · not measured';

  @override
  String beforeTolocal(Object toLocal) {
    return 'Before · $toLocal';
  }

  @override
  String workoutWorkouttext(Object workoutText) {
    return 'Workout · $workoutText';
  }

  @override
  String get afterNotMeasuredYet => 'After · not measured yet';

  @override
  String afterTolocal(Object toLocal) {
    return 'After · $toLocal';
  }

  @override
  String yourSimilarWorkoutsEligibleTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
    Object medianMs,
    Object q1Ms,
    Object q3Ms,
  ) {
    return 'Your similar workouts ($eligible, $toLocal–$toLocal2): median $medianMs ms, middle half $q1Ms to $q3Ms ms.';
  }

  @override
  String get howHardDidItFeel => 'How hard did it feel? (RPE)';

  @override
  String get loadMetric => 'Load';

  @override
  String get clearAction => 'Clear';

  @override
  String get routeFinish => 'Finish';

  @override
  String get month2 => 'MONTH';

  @override
  String get week2 => 'WEEK';

  @override
  String get quarter => 'QUARTER';

  @override
  String get year => 'YEAR';

  @override
  String get easy3 => 'EASY';

  @override
  String get mod => 'MOD';

  @override
  String get hard => 'HARD';

  @override
  String get protocol => 'PROTOCOL';

  @override
  String get calculate => 'CALCULATE';

  @override
  String get warmUp => 'WARM-UP';

  @override
  String get coolDown => 'COOL-DOWN';

  @override
  String get ftpCycling => 'FTP cycling';

  @override
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg) {
    return 'FTP $ftpWatts W · $wattsPerKg W/kg';
  }

  @override
  String get thisWeekSoFar => 'THIS WEEK · SO FAR';

  @override
  String get duration2 => 'DURATION';

  @override
  String get distance2 => 'DISTANCE';

  @override
  String get sport2 => 'SPORT';

  @override
  String get repeatSets => 'REPEAT SETS';

  @override
  String get aboutThisWorkout => 'ABOUT THIS WORKOUT';

  @override
  String get workoutStructure => 'WORKOUT STRUCTURE';

  @override
  String get health2 => 'HEALTH';

  @override
  String get high2 => 'HIGH';

  @override
  String get elevated => 'ELEVATED';

  @override
  String get normal => 'NORMAL';

  @override
  String get tomorrow => 'TOMORROW';

  @override
  String get skipped2 => 'SKIPPED';

  @override
  String get weeklyPlan => 'WEEKLY PLAN';

  @override
  String get activityLog3 => 'ACTIVITY LOG';

  @override
  String skippedTouppercase(Object toUpperCase) {
    return 'SKIPPED · $toUpperCase';
  }

  @override
  String get primaryZone => 'PRIMARY ZONE';

  @override
  String get coachingCues => 'COACHING CUES';

  @override
  String get targets => 'TARGETS';

  @override
  String get adaptation => 'ADAPTATION';

  @override
  String get done2 => 'DONE';

  @override
  String get notRecorded2 => 'NOT RECORDED';

  @override
  String get planned => 'PLANNED';

  @override
  String get extra => 'EXTRA';

  @override
  String get optimal2 => 'OPTIMAL';

  @override
  String get qualified => 'QUALIFIED';

  @override
  String get temp => 'TEMP';

  @override
  String get humidity2 => 'HUMIDITY';

  @override
  String get pressure => 'PRESSURE';

  @override
  String get wetBulb => 'WET BULB';

  @override
  String get paceMinKm => 'PACE (min/km)';

  @override
  String get speedKmH => 'SPEED (km/h)';

  @override
  String get elevationM => 'ELEVATION (m)';

  @override
  String get powerW => 'POWER (W)';

  @override
  String get performanceTime2 => 'PERFORMANCE / TIME';

  @override
  String get performanceDistance2 => 'PERFORMANCE / DISTANCE';

  @override
  String get load2 => 'LOAD';

  @override
  String get day2 => 'DAY';

  @override
  String get allTime => 'ALL-TIME';

  @override
  String get hrvAroundThisWorkout2 => 'HRV around this workout. ';

  @override
  String get lowReserve => 'LOW RESERVE';

  @override
  String get goodReserve => 'GOOD RESERVE';

  @override
  String latestReadingAtTolocal(Object toLocal) {
    return 'Latest reading at $toLocal';
  }

  @override
  String get weeklyAvg => 'WEEKLY AVG';

  @override
  String get monthlyAvg => 'MONTHLY AVG';

  @override
  String get systolic2 => 'SYSTOLIC';

  @override
  String get diastolic2 => 'DIASTOLIC';

  @override
  String get hourlyVariation => 'HOURLY VARIATION';

  @override
  String get dailyVariation => 'DAILY VARIATION';

  @override
  String get sys2 => 'SYS';

  @override
  String get dia => 'DIA';

  @override
  String get bluetoothDevices => 'BLUETOOTH DEVICES';

  @override
  String get accountsServices => 'ACCOUNTS & SERVICES';

  @override
  String get flowLoginOptional => 'FLOW LOGIN (OPTIONAL)';

  @override
  String get polarFlowLogin => 'POLAR FLOW LOGIN';

  @override
  String get raceGoal => 'RACE GOAL';

  @override
  String get experienceLevel => 'EXPERIENCE LEVEL';

  @override
  String get weeklySchedule2 => 'WEEKLY SCHEDULE';

  @override
  String get sessionsPerDay2 => 'SESSIONS PER DAY';

  @override
  String get aboutYou => 'ABOUT YOU';

  @override
  String get yourActivities2 => 'YOUR ACTIVITIES';

  @override
  String latestReadingAtTimestamp(Object timestamp) {
    return 'Latest reading at $timestamp';
  }

  @override
  String get poorSleep => 'POOR SLEEP';

  @override
  String get fairSleep => 'FAIR SLEEP';

  @override
  String get goodSleep => 'GOOD SLEEP';

  @override
  String get hoursOfSleep => 'HOURS OF SLEEP';

  @override
  String get sleepNeeded => 'SLEEP NEEDED';

  @override
  String get deepSleep => 'DEEP SLEEP';

  @override
  String get exercises2 => 'EXERCISES';

  @override
  String get strengthSummary => 'STRENGTH SUMMARY';

  @override
  String get strengthDraft => 'STRENGTH · DRAFT';

  @override
  String get strengthFinishedWithGaps => 'STRENGTH · FINISHED WITH GAPS';

  @override
  String get strength2 => 'STRENGTH';

  @override
  String get wind => 'WIND';

  @override
  String get sun2 => 'SUN';

  @override
  String get cloud => 'CLOUD';

  @override
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt) {
    return 'Data: $source · Updated $fetchedAt';
  }

  @override
  String get coros2 => 'COROS';

  @override
  String get rmssdMs => 'RMSSD · ms';

  @override
  String get sdnnMs => 'SDNN · ms';

  @override
  String get now2 => 'NOW';

  @override
  String get awake => 'AWAKE';

  @override
  String get light => 'LIGHT';

  @override
  String get deep2 => 'DEEP';

  @override
  String get sqliteOrm => 'SQLite ORM';

  @override
  String get httpClients => 'HTTP clients';

  @override
  String get gpsLocation => 'GPS location';

  @override
  String get hdlCholesterol => 'HDL Cholesterol';

  @override
  String get ldlCholesterol => 'LDL Cholesterol';

  @override
  String get raceName => 'RACE NAME';

  @override
  String get mtb => 'MTB';

  @override
  String get distanceKm => 'DISTANCE (km)';

  @override
  String get priority => 'PRIORITY';

  @override
  String get elevationGainM => 'ELEVATION GAIN (m)';

  @override
  String get targetTime => 'TARGET TIME';

  @override
  String get raceDate => 'RACE DATE';

  @override
  String get participation => 'PARTICIPATION';

  @override
  String get whatIWantFromIt => 'WHAT I WANT FROM IT';

  @override
  String periodTimeline(Object period) {
    return '$period TIMELINE';
  }

  @override
  String get tabPlan => 'PLAN';

  @override
  String get tabLoad => 'LOAD';

  @override
  String get tabCoach => 'COACH';

  @override
  String get hrDriftTestLt1 => 'HR DRIFT TEST — LT1';

  @override
  String get asSentByGarmin => 'AS SENT BY GARMIN';

  @override
  String get noData2 => 'NO DATA';

  @override
  String get noTarget => 'NO TARGET';

  @override
  String get noHeatLoad => 'NO HEAT LOAD';

  @override
  String get hrBpm => 'HR (bpm)';

  @override
  String get aiBriefingUnavailableShowingA =>
      'AI briefing unavailable. Showing a non-AI summary.';

  @override
  String get uvIndex2 => 'UV INDEX';

  @override
  String get aiBriefing => 'AI Briefing';

  @override
  String get uiFrameworkByGoogle => 'UI framework by Google';

  @override
  String get unableToLoadData => 'Unable to load data';

  @override
  String briefingSummary(Object recovery, Object sleep, Object load) {
    return 'Recovery $recovery / 100. Sleep $sleep / 100. Today’s training load is $load TRIMP.';
  }

  @override
  String get morningBriefing => 'Morning briefing';

  @override
  String get lunchBriefing => 'Lunch briefing';

  @override
  String get afternoonBriefing => 'Afternoon briefing';

  @override
  String get eveningBriefing => 'Evening briefing';

  @override
  String get appleUnusableAnswer =>
      'Apple Intelligence could not produce a usable answer: it repeated itself or your data. Try rephrasing the question, or choose another AI provider in the settings.';

  @override
  String get appleCouldNotAnswer =>
      'Apple Intelligence could not answer. Please try again.';

  @override
  String get appleNotAvailableOnDevice =>
      'Apple Intelligence is not available on this device.';

  @override
  String get appleLanguageRejected =>
      'Apple Intelligence rejected the request’s language. Try a short question in English. Also check the language settings for iPhone and Siri.';

  @override
  String get appleRequestTooLarge =>
      'Apple Intelligence could not fit this request. Try a shorter question.';

  @override
  String get messageTooLongForApple =>
      'This message is too long for Apple Intelligence. Shorten it and send again.';

  @override
  String get vo2maxRunning => 'VO₂max running';

  @override
  String get vo2maxCycling => 'VO₂max cycling';

  @override
  String get vo2maxPaceLabel => 'VO₂max pace';

  @override
  String get lt1Threshold => 'LT1 threshold';

  @override
  String get lt2Threshold => 'LT2 threshold';

  @override
  String hoursPreviousWeek(Object value) {
    return '$value h previous week';
  }

  @override
  String kmPreviousWeek(Object value) {
    return '$value km previous week';
  }

  @override
  String get thirtyMinuteTimeTrial => '30-minute time trial';

  @override
  String thirtyMinTtDate(Object date) {
    return '30-min TT · $date';
  }

  @override
  String get yesterday2 => 'YESTERDAY';

  @override
  String get briefHeadGreen => 'You are well recovered.';

  @override
  String get briefHeadYellow => 'You are carrying some strain.';

  @override
  String get briefHeadRed => 'You are clearly under strain.';

  @override
  String briefMain(Object reasons) {
    return 'Main reasons: $reasons.';
  }

  @override
  String get briefAllClear => 'None of your values shows a warning sign.';

  @override
  String get briefAdviceGreen => 'Train as planned.';

  @override
  String get briefAdviceYellow => 'Keep your plan but add no extra intensity.';

  @override
  String get briefAdviceRed =>
      'Recovery comes first: take an easy day or rest.';

  @override
  String get briefReasonHrvLow => 'low sleep HRV';

  @override
  String get briefReasonHrvHigh => 'high sleep HRV';

  @override
  String get briefReasonRhrUp => 'raised resting heart rate';

  @override
  String get briefReasonRhrDown => 'low resting heart rate';

  @override
  String get briefReasonSleepShort => 'too little sleep';

  @override
  String get briefReasonSleepGood => 'sleep need met';

  @override
  String get briefReasonEnergyLow => 'low energy';

  @override
  String get briefReasonEnergyHigh => 'good energy';

  @override
  String get briefReasonStressHigh => 'high stress';

  @override
  String get briefReasonRespHigh => 'raised breathing rate';

  @override
  String get briefReasonSpo2Low => 'low blood oxygen';

  @override
  String get briefReasonSkinTempOff => 'unusual skin temperature';

  @override
  String get briefReasonFormTired => 'accumulated training fatigue';

  @override
  String get briefReasonFormVeryTired => 'very high training fatigue';

  @override
  String get briefReasonFormFresh => 'fresh and rested';

  @override
  String get briefTrainingHrvUp => 'Your HRV rose after training, a good sign.';

  @override
  String get briefTrainingHrvDown =>
      'Your HRV fell after training, a less good sign.';

  @override
  String get reminderNeedsNotifications =>
      'The reminder needs notifications. Allow them for Fjelia in the system settings, then switch it on again.';

  @override
  String get whatDidYouHave => 'What did you have?';

  @override
  String get intakeSomething => 'I had something';

  @override
  String get intakeNothing => 'Nothing';

  @override
  String get totalIntake => 'Total intake';

  @override
  String get carbsLabel => 'Carbs';

  @override
  String get fluidLabel => 'Fluid';

  @override
  String get sodiumLabel => 'Sodium';

  @override
  String get caffeineLabel => 'Caffeine';

  @override
  String get detailsOptional => 'Details (optional)';

  @override
  String atMinute(Object minute) {
    return 'minute $minute';
  }

  @override
  String get nothingAddedYet =>
      'Nothing added yet. Add what you ate or drank, or choose “Nothing”.';

  @override
  String get followFocusWeek => 'What should I focus on this week?';

  @override
  String get followRecoveryTrend => 'How is my recovery trending?';

  @override
  String get followLoadTooHigh => 'Is my training load too high?';

  @override
  String get followImproveSleep => 'What would improve my sleep?';

  @override
  String get followIntervalsFeel => 'How should the intervals feel?';

  @override
  String get followTiredToday => 'What if I feel tired today?';

  @override
  String get followEatBefore => 'What should I eat before it?';

  @override
  String get followAdjustToday => 'Should I adjust it today?';

  @override
  String get followNextDays => 'What does it mean for my next days?';

  @override
  String get followCompareSimilar =>
      'How does it compare with similar sessions?';

  @override
  String get followRecover => 'What should I do to recover?';

  @override
  String get followIntensityRight => 'Was the intensity right?';

  @override
  String get statusPlanned => 'Planned';

  @override
  String get statusAdapted => 'Adapted';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusRest => 'Rest';

  @override
  String loadValue(Object value) {
    return '$value load';
  }

  @override
  String get actIntensityEasy => 'That was an easy aerobic session.';

  @override
  String get actIntensityModerate => 'That was a moderate session.';

  @override
  String get actIntensityHard => 'That was a hard session.';

  @override
  String get actIntensityUnknown => 'That session is logged.';

  @override
  String get actLenLonger => 'It was longer than your similar sessions.';

  @override
  String get actLenShorter => 'It was shorter than your similar sessions.';

  @override
  String get actLoadHigher => 'The load was higher than usual.';

  @override
  String get actLoadLower => 'The load was lower than usual.';

  @override
  String get actLoadSame => 'The load was about the same as usual.';

  @override
  String get actHrLower =>
      'Your heart rate was lower than usual, so it felt easier.';

  @override
  String get actHrHigher =>
      'Your heart rate was higher than usual, so it felt harder.';

  @override
  String get actAdviceUnknown => 'Plan your next days by how you feel.';

  @override
  String briefOutlookRest(Object days) {
    return 'With about $days easy days your form is back in the optimal range.';
  }

  @override
  String get briefOutlookLongRest =>
      'Your form needs more than a few easy days to recover.';

  @override
  String get briefOutlookPlanTired =>
      'Following the plan keeps your form low for the next days.';
}
