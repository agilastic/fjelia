// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get freeAi => 'Free AI';

  @override
  String get freeAiUsageTracking =>
      'Så Free AI fortsat fungerer pålideligt for alle, sender vi et tilfældigt installations-id. Det hjælper os med at opdage usædvanlig brug og blokere anmodninger, der misbruger tjenesten. Id\'et indeholder hverken dit navn eller kontooplysninger.';

  @override
  String freeAiDescription(String host) {
    return 'Gratis AI-chat og opsummeringer via $host. Ingen separat konto eller API-nøgle er nødvendig. Efter din bekræftelse sendes beskeder og en opsummering af helbred og træning til tjenesten.';
  }

  @override
  String get freeAiUnavailable =>
      'Free AI er ikke tilgængelig i denne version. Vælg en anden udbyder.';

  @override
  String shareBriefingContextWithName(String name) {
    return 'En opsummering af dine helbreds- og træningsdata sendes til $name.';
  }

  @override
  String get language => 'Sprog';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get settings => 'Indstillinger';

  @override
  String get profile => 'Profil';

  @override
  String get training => 'Træning';

  @override
  String get weatherLocation => 'Vejr og placering';

  @override
  String get display => 'Visning';

  @override
  String get connections => 'Forbindelser';

  @override
  String get aiAndMore => 'AI og mere';

  @override
  String get system => 'System';

  @override
  String get runSetupAgain => 'Kør opsætningen igen';

  @override
  String get runSetupAgainSubtitle => 'Konti, løbsmål og træningsplan';

  @override
  String get back => 'Tilbage';

  @override
  String get close => 'Luk';

  @override
  String get dataExport => 'Dataeksport';

  @override
  String get dataExportSubtitle => 'CSV-eksport, sikkerhedskopi og gendannelse';

  @override
  String get developer => 'Udvikler';

  @override
  String get developerSubtitle => 'Fejlfindingstilstand, diagnostik';

  @override
  String get debug => 'Fejlfinding';

  @override
  String get debugMode => 'Fejlfindingstilstand';

  @override
  String get debugModeSubtitle => 'Viser fanen DEBUG';

  @override
  String get support => 'Support';

  @override
  String get reportBug => 'Rapportér en fejl';

  @override
  String get aiCoach => 'AI-træner';

  @override
  String get enableAiCoach => 'Aktivér AI-træneren';

  @override
  String get onDeviceAiOrCloud => 'AI på enheden eller cloududbyder';

  @override
  String get provider => 'Udbyder';

  @override
  String get model => 'Model';

  @override
  String get chatAndAiBriefingsUse =>
      'Chat og AI-briefinger bruger Apple Intelligence på denne enhed. Ingen API-nøgle nødvendig. Hvis modellen ikke er tilgængelig, viser briefingerne et resumé uden AI.';

  @override
  String get briefing => 'Briefing';

  @override
  String get useAppleIntelligenceForBriefings =>
      'Brug Apple Intelligence til briefinger';

  @override
  String get useOnDeviceAiFor =>
      'Brug AI på enheden til briefinger, og behold den valgte udbyder til chat.';

  @override
  String get healthDataSharing => 'Deling af sundhedsdata';

  @override
  String get askOncePerChatSession => 'Spørg én gang pr. chatsession';

  @override
  String get otherwiseAskBeforeEveryCloud =>
      'Ellers spørg før hver cloudbesked';

  @override
  String get reportABug => 'Rapportér en fejl';

  @override
  String get weatherData => 'Vejrdata';

  @override
  String get openSourceLibraries => 'Open source-biblioteker';

  @override
  String get license => 'Licens';

  @override
  String get licenses => 'Licenser';

  @override
  String get apiKey => 'API-nøgle';

  @override
  String get saveApiKey => 'Gem API-nøgle';

  @override
  String get feedbackBugReport => 'Feedback og fejlrapport';

  @override
  String get reportSentThankYou => 'Rapport sendt. Tak!';

  @override
  String get weReadEveryMessageIf =>
      'Vi læser alle beskeder. Hvis du har angivet din e-mail, kan du få et svar.';

  @override
  String get done => 'Færdig';

  @override
  String get shareAnIdeaSuggestAn =>
      'Del en idé, foreslå en forbedring, eller fortæl, hvad der skete, og hvad du forventede.';

  @override
  String get whatHappenedAndWhatDid => 'Hvad skete der, og hvad forventede du?';

  @override
  String get pleaseLeaveOutPasswordsApi =>
      'Udelad adgangskoder, API-nøgler og personlige sundhedsmålinger.';

  @override
  String get includeDiagnostics => 'Inkludér diagnostik';

  @override
  String get optionalLogsMayContainAccount =>
      'Valgfrit. Logfiler kan indeholde konto- eller sundhedsoplysninger. Gennemgå dem nedenfor, før du sender.';

  @override
  String get diagnosticsPreview => 'FORHÅNDSVISNING AF DIAGNOSTIK';

  @override
  String get sendingSharesYourEmailSubject =>
      'Ved afsendelse deles din e-mail, emne, besked og valgt diagnostik med Fjelia-support på cloud.ebeling-hoppe.de.';

  @override
  String get copyReport => 'Kopiér rapport';

  @override
  String get shareReport => 'Del rapport';

  @override
  String get appleHealth => 'Apple Sundhed';

  @override
  String get connectedServices => 'Tilsluttede tjenester';

  @override
  String get hiloBloodPressureBle => 'Hilo blodtryk (BLE)';

  @override
  String get writeHeartDataToApple => 'Skriv hjertedata til Apple Sundhed';

  @override
  String get writeWeightDataToApple => 'Skriv vægtdata til Apple Sundhed';

  @override
  String get renphoScaleBle => 'Renpho-vægt (BLE)';

  @override
  String get polarH10HrvStrapBle => 'Polar H10 (HRV-bælte, BLE)';

  @override
  String get dataSourcePriority => 'Prioritet for datakilder';

  @override
  String get whenMultipleSourcesProvideThe =>
      'Når flere kilder leverer samme måling, vinder den højeste kilde. Træk for at ændre rækkefølgen.';

  @override
  String get resetToDefault => 'Nulstil til standard';

  @override
  String get disconnect => 'Afbryd forbindelsen';

  @override
  String get healthPage => 'Sundhedsside';

  @override
  String get loadPage => 'Belastningsside';

  @override
  String get healthMonitor => 'Sundhedsmonitor';

  @override
  String get hrZones => 'Pulszoner';

  @override
  String get t30MinTtAvailableSync =>
      '30-min TT tilgængelig – synkronisér pulszoner';

  @override
  String lt2Lt2BpmAt(Object lt2, Object at) {
    return 'LT2 $lt2 bpm · $at';
  }

  @override
  String get syncLabel => 'SYNK';

  @override
  String get autoadjust => 'AUTOJUSTÉR';

  @override
  String zoneI(Object i) {
    return 'Zone $i';
  }

  @override
  String get hrZones2 => 'PULSZONER';

  @override
  String ageRound(Object round) {
    return 'alder $round';
  }

  @override
  String get basics => 'Grundoplysninger';

  @override
  String get updateWaistMonthlyUsedFor =>
      'ⓘ Opdatér taljemålet månedligt – bruges til at estimere visceralt fedt.';

  @override
  String get alcohol => 'Alkohol';

  @override
  String get t1Drink033L => '1 drink ≈ 0,33 l øl / 0,2 l vin / 4 cl spiritus';

  @override
  String get clinicalLabsOptional => 'Laboratorieværdier (valgfrit)';

  @override
  String get glycemic => 'Blodsukker';

  @override
  String get optimalForLongevity48 =>
      'Optimalt for lang levetid: 4,8–5,4 % · Prædiabetes: 5,7–6,4 %';

  @override
  String get lipids => 'Lipider';

  @override
  String get apobReplacesLdlWhenBoth =>
      'ApoB erstatter LDL, når begge er indtastet.';

  @override
  String get inflammationKidney => 'Inflammation og nyrer';

  @override
  String get changesAreSavedAutomatically => 'Ændringer gemmes automatisk';

  @override
  String get optionalTotalClimbingForThis =>
      'Valgfri samlet stigning for dette løb.';

  @override
  String get moreAboutThisEvent => 'Mere om dette arrangement';

  @override
  String distanceOfDistancekmKm(Object distanceKm) {
    return 'Distance på $distanceKm km?';
  }

  @override
  String keepDistancekmKm(Object distanceKm) {
    return 'Behold $distanceKm km';
  }

  @override
  String useLikelyKm(Object likely) {
    return 'Brug $likely km';
  }

  @override
  String get thisBackupContainsNoCalendar =>
      'Denne sikkerhedskopi indeholder ingen kalenderaktiviteter.';

  @override
  String get activities => 'Aktiviteter';

  @override
  String get exportActivitiesCsv => 'Eksportér aktiviteter som CSV';

  @override
  String get backupRestore => 'Sikkerhedskopi og gendannelse';

  @override
  String get backup => 'Sikkerhedskopi';

  @override
  String get restoreFromBackup => 'Gendan fra sikkerhedskopi';

  @override
  String get backupRestoredRestartTheApp =>
      'Sikkerhedskopi gendannet. Genstart appen for at indlæse alle indstillinger.';

  @override
  String get raceGoals => 'Løbsmål';

  @override
  String get yourActivities => 'Dine aktiviteter';

  @override
  String get usedByAiCoachAnd =>
      'Bruges af AI-træneren og træningsplanen. Sportsgrene i planen er markeret med ✦.';

  @override
  String get calendarWeekStart => 'Ugestart i kalenderen';

  @override
  String get planDefaultView => 'Standardvisning for planen';

  @override
  String get weeklySchedule => 'Ugeplan';

  @override
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      trainingDaysPerWeek,
      locale: localeName,
      other: '$trainingDaysPerWeek træningsdage',
      one: '$trainingDaysPerWeek træningsdag',
    );
    return '$_temp0 · tryk for at skifte mellem Træning / Hvile / Styrke';
  }

  @override
  String get updatePlanToThisSchedule => 'Opdatér planen til denne ugeplan';

  @override
  String get updateStrengthSessions => 'Opdatér styrkesessionerne';

  @override
  String get sessionsPerDay => 'Sessioner pr. dag';

  @override
  String get canYouFitTwoWorkouts => 'Kan du nå to træninger på én dag?';

  @override
  String get strengthLoadUnit => 'Enhed for styrkebelastning';

  @override
  String get weightsThemselvesAreSetIn =>
      'Selve vægtene indstilles i hver træning og huskes fra din historik.';

  @override
  String get hoursAvailableWeek => 'Tilgængelige timer / uge';

  @override
  String hoursperweekHWeek(Object hoursPerWeek) {
    return '$hoursPerWeek t / uge';
  }

  @override
  String hoursperweekH(Object hoursPerWeek) {
    return '$hoursPerWeek t';
  }

  @override
  String get heatAcclimation => 'Varmetilvænning';

  @override
  String get showHeatAcclimation => 'Vis varmetilvænning';

  @override
  String get weatherEvaluatedAgainstAConfigurable =>
      'Vejret vurderes for et valgfrit sted.';

  @override
  String get trainingPlan => 'Træningsplan';

  @override
  String get regenerateReplacesFutureSessionsAnd =>
      'Gendan erstatter fremtidige sessioner og genopbygger planen fra i dag med de aktuelle indstillinger.';

  @override
  String valueUpcomingWorkoutsGenerated(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value kommende træninger oprettet',
      one: '$value kommende træning oprettet',
    );
    return '$_temp0';
  }

  @override
  String get generationFailedCheckYourRace =>
      'Oprettelsen mislykkedes. Tjek dit løbsmål, og prøv igen.';

  @override
  String get deleteAllWorkouts => 'Slet alle træninger';

  @override
  String get changesAreSavedAutomatically2 => '✓ Ændringer gemmes automatisk';

  @override
  String countUpcomingWorkoutsGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kommende træninger oprettet',
      one: '$count kommende træning oprettet',
    );
    return '$_temp0';
  }

  @override
  String get importRaceGoalsFromGarmin => 'Importér løbsmål fra Garmin';

  @override
  String get addRaceGoal => 'Tilføj løbsmål';

  @override
  String priorityTouppercase(Object toUpperCase) {
    return 'Prioritet $toUpperCase';
  }

  @override
  String get goalsAreSharedWithAi =>
      'Mål deles med AI-træneren. Prioritet A, B og C afgør, hvordan planen vægter dine løb mod hinanden.';

  @override
  String get deletingWorkouts => 'Sletter træninger';

  @override
  String get cityOrTown => 'By eller stad';

  @override
  String get eGHannoverOrPalma => 'fx Hannover eller Palma';

  @override
  String get noCitiesFoundTryA => 'Ingen byer fundet. Prøv en by i nærheden.';

  @override
  String get chooseTheLocationForThe =>
      'Vælg stedet til planens vejrudsigt, radar og varmetilvænning. Vejret virker også, når varmetilvænning er slået fra.';

  @override
  String get none => 'Ingen';

  @override
  String get disableLocalWeatherAndLocation =>
      'Deaktivér lokalt vejr og positionsforespørgsler';

  @override
  String get currentLocation => 'Nuværende placering';

  @override
  String get followYourDeviceLocation => 'Følg enhedens placering';

  @override
  String get fixedLocation => 'Fast placering';

  @override
  String get chooseACityOrEnter => 'Vælg en by, eller indtast koordinater';

  @override
  String get chooseCity => 'Vælg by';

  @override
  String get coordinates => 'Koordinater';

  @override
  String get latitude => 'Breddegrad';

  @override
  String get longitude => 'Længdegrad';

  @override
  String get saveLocation => 'Gem placering';

  @override
  String get refreshCurrentLocation => 'Opdatér nuværende placering';

  @override
  String get citySearchOpenMeteoGeonames => 'Bysøgning: Open-Meteo / GeoNames';

  @override
  String get cityNamesOpenstreetmap => 'Bynavne: © OpenStreetMap';

  @override
  String get energy => 'ENERGI';

  @override
  String get currentEnergy => 'NUVÆRENDE ENERGI';

  @override
  String get dailyTimeline => 'DAGSFORLØB';

  @override
  String valueValue2(Object value, Object value2) {
    return '$value → $value2';
  }

  @override
  String get energy2 => 'Energi';

  @override
  String get noData => 'Ingen data';

  @override
  String get bloodPressureInsights => 'BLODTRYKSANALYSE';

  @override
  String get sys => ' Sys';

  @override
  String get diaMmhg => ' Dia · mmHg';

  @override
  String get previousBloodPressurePeriod => 'Forrige blodtryksperiode';

  @override
  String get nextBloodPressurePeriod => 'Næste blodtryksperiode';

  @override
  String get nightDipping => 'Natligt fald';

  @override
  String get noMeasurementsInThisPeriod => 'Ingen målinger i denne periode';

  @override
  String get fullscreenBloodPressureChart => 'Blodtryksdiagram i fuld skærm';

  @override
  String get barsMinMaxLineDots =>
      'Søjler: min–maks · linje/prikker: gennemsnit · tryk eller træk for at se nærmere';

  @override
  String get noMeasurements => 'Ingen målinger';

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
      other: '$length målinger',
      one: '$length måling',
    );
    return '$_temp0 · gennemsnit / min–maks';
  }

  @override
  String bloodPressureTouppercaseMmhg(Object toUpperCase) {
    return 'BLODTRYK · $toUpperCase · mmHg';
  }

  @override
  String get closeFullscreenBloodPressureChart =>
      'Luk blodtryksdiagrammet i fuld skærm';

  @override
  String get chooseScale => 'Vælg vægt';

  @override
  String get noScalesFoundStepOn =>
      'Ingen vægte fundet. Stil dig på vægten, og prøv igen.';

  @override
  String nameRssiDbm(Object name, Object rssi) {
    return '$name · $rssi dBm';
  }

  @override
  String get renphoSaved => 'RENPHO gemt:';

  @override
  String get renphoScaleBle2 => 'RENPHO-vægt (BLE)';

  @override
  String get changeMeasurementType => 'Skift målingstype';

  @override
  String get addMeasurement => 'Tilføj måling';

  @override
  String get whatAreYouMeasuring => 'Hvad måler du?';

  @override
  String get chooseAnotherMeasurement => 'Vælg en anden måling';

  @override
  String get saveMeasurement => 'Gem måling';

  @override
  String get skip => 'Spring over';

  @override
  String get connectHiloService => 'Tilslut Hilo-tjenesten';

  @override
  String get connectHilo => 'Tilslut Hilo';

  @override
  String get connectCoros => 'Tilslut Coros';

  @override
  String get europe => 'Europa';

  @override
  String get unitedStates => 'USA';

  @override
  String get asia => 'Asien';

  @override
  String get bluetoothBloodPressure => 'Bluetooth · blodtryk';

  @override
  String get cloudCuffData => 'Cloud · manchetdata';

  @override
  String get apiSync => 'API-synkronisering';

  @override
  String get bluetoothHrvStrap => 'Bluetooth · HRV-bælte';

  @override
  String get accesslinkApi => 'AccessLink API';

  @override
  String get systemHealthData => 'Systemets sundhedsdata';

  @override
  String get cloudScaleHistory => 'Cloud · vægthistorik';

  @override
  String get bluetoothWeightBody => 'Bluetooth · vægt og krop';

  @override
  String get connectYourDevices => 'Tilslut dine enheder';

  @override
  String get continueLabel => 'Fortsæt';

  @override
  String get connectGarmin => 'Tilslut Garmin';

  @override
  String get connectAppleHealth => 'Tilslut Apple Sundhed';

  @override
  String get dataSynced => 'DATA SYNKRONISERET';

  @override
  String get pairHiloPod => 'Par Hilo Pod';

  @override
  String get chooseStrap => 'Vælg bælte';

  @override
  String namePaired(Object name) {
    return '$name er parret.';
  }

  @override
  String get pairPolarH10 => 'Par Polar H10';

  @override
  String get forget => 'Glem';

  @override
  String get sendWorkoutToPolar => 'Send træning til Polar';

  @override
  String get connectPolar => 'Tilslut Polar';

  @override
  String get signInWithPolarFlow => 'Log ind med Polar Flow';

  @override
  String get syncsSleepStagesHrvResting =>
      'Synkroniserer søvnfaser · HRV · hvilepuls · træninger · skridt';

  @override
  String savedForV(Object v) {
    return 'Gemt for $v';
  }

  @override
  String get remove => 'Fjern';

  @override
  String get polarEMail => 'Polar-e-mail';

  @override
  String get polarPassword => 'Polar-adgangskode';

  @override
  String get pairRenphoScale => 'Par RENPHO-vægt';

  @override
  String get connectRenpho => 'Tilslut Renpho';

  @override
  String get connectSuunto => 'Tilslut Suunto';

  @override
  String smsSentToTrim(Object trim) {
    return 'SMS sendt til $trim';
  }

  @override
  String get resendSms => 'Send SMS igen';

  @override
  String get retryLoadingPreferences => 'Prøv at indlæse indstillingerne igen';

  @override
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed) {
    return 'UGENTLIG TRÆNINGSTID · $toStringAsFixed t';
  }

  @override
  String get tapADayToCycle =>
      'Tryk på en dag for at skifte mellem Træning / Hvile / Styrke.';

  @override
  String get doubleDayOk => 'Dobbeltdag ok';

  @override
  String get birthYearOptional => 'Fødselsår (valgfrit)';

  @override
  String get addAnother => 'Tilføj en til';

  @override
  String get knowYourBodyTrainSmarter => 'Kend din krop.\nTræn smartere.';

  @override
  String get allYourHealthDevicesOne =>
      'Alle dine sundhedsenheder. Ét intelligent overblik.';

  @override
  String get areYouReadyToTrain => 'Er du klar til at træne i dag?';

  @override
  String get hrvRecoveryScoreRestingHr => 'HRV · Restitutionsscore · Hvilepuls';

  @override
  String get didYouActuallyRecoverLast => 'Fik du virkelig restitueret i nat?';

  @override
  String get sleepStagesDeepSleepSpo => 'Søvnfaser · Dyb søvn · SpO₂';

  @override
  String get isYourBloodPressureUnder => 'Er dit blodtryk under kontrol?';

  @override
  String get continuousBpNightDippingTrends =>
      'Kontinuerligt blodtryk · Natligt fald · Tendenser';

  @override
  String get howHardDidYouPush => 'Hvor hårdt pressede du dig i denne uge?';

  @override
  String get trainingLoadTrimpStrainScore =>
      'Træningsbelastning · TRIMP · Strain-score';

  @override
  String get isYourBodyCompositionImproving =>
      'Forbedres din kropssammensætning?';

  @override
  String get weightBodyFatMuscleMass => 'Vægt · Kropsfedt · Muskelmasse';

  @override
  String get getStarted => 'Kom i gang';

  @override
  String get yourDataStaysOnYour => 'Dine data. Du vælger, hvad du deler.';

  @override
  String get bodyScale => 'Kropsvægt';

  @override
  String get bodyComposition => 'Kropssammensætning';

  @override
  String get sleep => 'SØVN';

  @override
  String get sleepPerformance => 'SØVNPRÆSTATION';

  @override
  String get sleepHistory => 'Søvnhistorik';

  @override
  String labelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String lessLabel(Object label) {
    return 'Mindre $label';
  }

  @override
  String moreLabel(Object label) {
    return 'Mere $label';
  }

  @override
  String get gymMode => 'Fitnessmodus';

  @override
  String get finishWorkout => 'Afslut træning';

  @override
  String get workoutActions => 'Træningshandlinger';

  @override
  String get discardWorkout => 'Kassér træning';

  @override
  String get allSetsRecorded => 'Alle sæt registreret';

  @override
  String get reviewSets => 'Gennemse sæt';

  @override
  String get rest => 'HVILE';

  @override
  String plannedResttarget(Object restTarget) {
    return 'Planlagt $restTarget';
  }

  @override
  String get startSet => 'Start sæt';

  @override
  String get seconds => 'Sekunder';

  @override
  String get previousSet => 'Forrige sæt';

  @override
  String get allSets => 'Alle sæt';

  @override
  String get nextSet => 'Næste sæt';

  @override
  String get everySetIsSavedAs =>
      'Hvert sæt gemmes undervejs. Luk skærmen når som helst, og fortsæt fra den planlagte træning.';

  @override
  String get cancel => 'Annuller';

  @override
  String get apply => 'Anvend';

  @override
  String get effortScale => 'Anstrengelsesskala';

  @override
  String get setType => 'Sættype';

  @override
  String get reps => 'Gentagelser';

  @override
  String get range => 'Interval';

  @override
  String get time => 'Tid';

  @override
  String get t45Or100 => '45 eller 1:00';

  @override
  String get blankWhenNotSet => 'Tomt, hvis ikke angivet';

  @override
  String get redBand => 'Rødt bånd';

  @override
  String get t90Or130 => '90 eller 1:30';

  @override
  String get blankWhenUnknown => 'Tomt, hvis ukendt';

  @override
  String get usePlannedLoad => 'Brug planlagt belastning';

  @override
  String get blankWhenNotMeasured => 'Tomt, hvis ikke målt';

  @override
  String get exercise => 'Øvelse';

  @override
  String get changingTheLoadConventionStarts =>
      'Hvis du ændrer belastningskonventionen, startes en separat historik for denne øvelse.';

  @override
  String get barbellMachine => 'Stang, maskine …';

  @override
  String get load => 'Belastning';

  @override
  String get loadRefersTo => 'Belastning refererer til';

  @override
  String get t2ForAPair => '2 for et par';

  @override
  String get repetitions => 'Gentagelser';

  @override
  String get availablePlatesOrDumbbells =>
      'Tilgængelige skiver eller håndvægte';

  @override
  String get rememberForThisEquipment => 'Husk til dette udstyr';

  @override
  String get findOrNameAnExercise => 'Find eller navngiv en øvelse';

  @override
  String createTrim(Object trim) {
    return 'Opret “$trim”';
  }

  @override
  String get customExercise => 'Egen øvelse';

  @override
  String get smallestLoadStep => 'Mindste belastningstrin';

  @override
  String whatRemoved(Object what) {
    return '$what fjernet';
  }

  @override
  String get undo => 'Fortryd';

  @override
  String get retry => 'Prøv igen';

  @override
  String get performance => 'Præstation';

  @override
  String get addExercise => 'Tilføj øvelse';

  @override
  String get finishLog => 'Afslut log';

  @override
  String get keepAsDraft => 'Behold som kladde';

  @override
  String actionsForName(Object name) {
    return 'Handlinger for $name';
  }

  @override
  String get editExercise => 'Redigér øvelse';

  @override
  String get moveUp => 'Flyt op';

  @override
  String get moveDown => 'Flyt ned';

  @override
  String get addSet => 'Tilføj sæt';

  @override
  String get removeLastSet => 'Fjern sidste sæt';

  @override
  String get saveAsTemplate => 'Gem som skabelon';

  @override
  String savedTitleAsATemplate(Object title) {
    return '“$title” gemt som skabelon. Denne træning er uændret, indtil du gemmer den.';
  }

  @override
  String nameSetN(Object name, Object n) {
    return '$name · Sæt $n';
  }

  @override
  String nameAllWorkingSets(Object name) {
    return '$name · Alle arbejdssæt';
  }

  @override
  String labelRest(Object label) {
    return '$label hvile';
  }

  @override
  String get secondsOrMSs => 'Sekunder eller m:ss';

  @override
  String get applyToAllSets => 'Anvend på alle sæt';

  @override
  String get duplicate => 'Duplikér';

  @override
  String get supersetWithNext => 'Superset med næste';

  @override
  String get circuitWithNext => 'Cirkel med næste';

  @override
  String actionsForSetN(Object n) {
    return 'Handlinger for sæt $n';
  }

  @override
  String get editSet => 'Redigér sæt';

  @override
  String get duplicateSet => 'Duplikér sæt';

  @override
  String get removeSet => 'Fjern sæt';

  @override
  String labelActions(Object label) {
    return '$label-handlinger';
  }

  @override
  String get editRests => 'Redigér pauser';

  @override
  String get ungroup => 'Opdel gruppering';

  @override
  String get editExercises => 'Redigér øvelser';

  @override
  String get unsavedChanges => 'Ikke-gemte ændringer';

  @override
  String couldNotSaveError(Object error) {
    return 'Kunne ikke gemme: $error';
  }

  @override
  String get history => 'Historik';

  @override
  String get exercises => 'Øvelser';

  @override
  String get noExercisesArePlannedFor =>
      'Der er endnu ikke planlagt øvelser til denne træning. Noterne ovenfor beskriver den.';

  @override
  String get addExercises => 'Tilføj øvelser';

  @override
  String get fromTheBuiltInTemplate =>
      'Fra den indbyggede skabelon. Belastningerne indstiller du selv; historik vises, når du har logget en træning.';

  @override
  String get shareExerciseList => 'Del øvelsesliste';

  @override
  String get noSavedStrengthTemplatesYet =>
      'Ingen gemte styrkeskabeloner endnu. Gem først en fra en planlagt træning.';

  @override
  String get compareWith => 'Sammenlign med';

  @override
  String estimated1rmUnit(Object unit) {
    return 'Estimeret 1RM $unit';
  }

  @override
  String get plannedNotRecorded => 'Planlagt, ikke registreret';

  @override
  String get notes => 'Noter';

  @override
  String get editPerformance => 'Redigér præstation';

  @override
  String get compareWithASavedWorkout => 'Sammenlign med en gemt træning';

  @override
  String get sessions => 'Sessioner';

  @override
  String get radarUnavailableRetry => 'Radar utilgængelig · Prøv igen';

  @override
  String get radar => 'Radar';

  @override
  String get weatherDataByRainviewer => 'Vejrdata fra RainViewer';

  @override
  String get openstreetmapContributors => '© OpenStreetMap-bidragydere';

  @override
  String get weather => 'Vejr';

  @override
  String get weatherUnavailableRetry => 'Vejr utilgængeligt · Prøv igen';

  @override
  String get chooseAFixedLocationIn =>
      'Vælg en fast placering i indstillingerne for Vejr og placering, eller tillad adgang til placering for lokalt vejr.';

  @override
  String get locationSettings => 'Placeringsindstillinger';

  @override
  String get retryLocation => 'Prøv placering igen';

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
    return 'Våd temp. $toStringAsFixed°C';
  }

  @override
  String get previousForecastDay => 'Forrige prognosedag';

  @override
  String get nextForecastDay => 'Næste prognosedag';

  @override
  String daysDayForecast(Object days) {
    return '$days-dages prognose';
  }

  @override
  String thisProviderCurrentlySuppliesDays(Object days, Object days2) {
    return 'Denne udbyder leverer i øjeblikket $days af $days2 prognosedage.';
  }

  @override
  String get now => 'Nu';

  @override
  String get sunriseSunset => 'Solopgang / solnedgang';

  @override
  String keyKey2(Object key, Object key2) {
    return '☀ $key   ☾ $key2';
  }

  @override
  String get use => 'Brug';

  @override
  String get exerciseDetailsWereNotProvided =>
      'Øvelsesdetaljer blev ikke leveret af denne aktivitetskilde.';

  @override
  String get logFromPlan => 'Log fra plan';

  @override
  String get addExerciseDetails => 'Tilføj øvelsesdetaljer';

  @override
  String get loadSuggestion => 'Belastningsforslag';

  @override
  String get applyToThisWorkout => 'Anvend på denne træning';

  @override
  String get keepCurrentLoad => 'Behold nuværende belastning';

  @override
  String get setLoadStep => 'Angiv belastningstrin';

  @override
  String get viewSupportingSets => 'Se understøttende sæt';

  @override
  String get supportingSets => 'Understøttende sæt';

  @override
  String get noRecordedSessionsYet => 'Ingen registrerede sessioner endnu.';

  @override
  String nameDemonstrationCue(Object name, Object cue) {
    return 'Demonstration af $name. $cue';
  }

  @override
  String get noScalesFoundStepOn2 =>
      'Ingen vægte fundet. Stil dig på vægten, og prøv igen.';

  @override
  String get scalePaired => 'Vægt parret';

  @override
  String get ok => 'OK';

  @override
  String get pairedReadyToMeasure => '✓ Parret – klar til at måle';

  @override
  String get chooseHiloCuff => 'Vælg Hilo-manchet';

  @override
  String get noCuffFoundWakeYour =>
      'Ingen manchet fundet. Væk din manchet, og søg igen.';

  @override
  String get hiloCuffAktiiaC => 'Hilo-manchet (AKTIIA C…)';

  @override
  String get onDemandBloodPressureVia => 'Blodtryk efter behov via BLE';

  @override
  String get selectHiloPodWristband => 'Vælg Hilo Pod (armbånd)';

  @override
  String get rescan => 'Søg igen';

  @override
  String get noDevicesFoundTapTo =>
      'Ingen enheder fundet. Tryk på ↻ for at søge igen.';

  @override
  String get polarH10SpotHrv => 'Polar H10 · Spot-HRV';

  @override
  String get aSeparateHrvReadingBefore =>
      'En separat HRV-måling før eller efter træning. Disse målinger erstatter ikke Garmins HRV om natten og ændrer ikke din parathedsscore.';

  @override
  String get wearTheStrapWithMoist =>
      'Tag båndet på med fugtede elektroder. Hold dig stille, og træk vejret normalt. Brug samme kropsposition og optagelseslængde til sammenligninger. Efter træning: noter, hvor længe du hvilede først.';

  @override
  String get measurement => 'Måling';

  @override
  String get posture => 'Kropsposition';

  @override
  String get recordingLengthPlus1Min =>
      'Optagelseslængde · plus 1 min hvile før optagelse';

  @override
  String get t2Minutes => '2 minutter';

  @override
  String get t5Minutes => '5 minutter';

  @override
  String get minutesSinceTrainingEndedOptional =>
      'Minutter siden træningen sluttede (valgfrit)';

  @override
  String get sessionOrNotesOptional => 'Session eller noter (valgfrit)';

  @override
  String connectName(Object name) {
    return 'Tilslut $name';
  }

  @override
  String get findPolarH10 => 'Find Polar H10';

  @override
  String signalRssiDbm(Object rssi) {
    return 'Signal $rssi dBm';
  }

  @override
  String connectedName(Object name) {
    return 'Forbundet: $name';
  }

  @override
  String get waitingForHeartRateAnd =>
      'Venter på puls og RR-intervaller. Tjek bæltets kontakt.';

  @override
  String get startMeasurement => 'Start måling';

  @override
  String get cancelMeasurement => 'Annuller måling';

  @override
  String get spotHrvRmssd => 'Spot-HRV · RMSSD';

  @override
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  ) {
    return '$accepted/$length brugbare intervaller · $toStringAsFixed % dækning';
  }

  @override
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs) {
    return 'lnRMSSD: $lnRmssd · Rå RMSSD: $rawRmssdMs ms';
  }

  @override
  String get signalQualityIsTooLow =>
      'Signalkvaliteten er for lav til at gemme. Gentag målingen med god kontakt til bæltet. Mindst 95 % brugbare intervaller og 90 % dækning kræves.';

  @override
  String get savedToSpotHrvHistory => 'Gemt i Spot-HRV-historikken.';

  @override
  String get newMeasurement => 'Ny måling';

  @override
  String get signalScreeningExcludesPoorContact =>
      'Signalfiltreringen udelukker dårlig kontakt, RR uden for 250–2500 ms og intervaller mere end 25 % fra den lokale median. Huller udfyldes ikke. Dette er ikke en medicinsk test og ingen selvstændig parathedsscore.';

  @override
  String historyLabelLabel2DurationMin(
    Object label,
    Object label2,
    Object duration,
  ) {
    return 'Historik · $label · $label2 · $duration min';
  }

  @override
  String get onlyReadingsWithTheSame =>
      'Kun målinger med samme kontekst, kropsposition og varighed vises sammen.';

  @override
  String get noMatchingMeasurementsYet => 'Ingen tilsvarende målinger endnu.';

  @override
  String tostringasfixedMsRmssdTostringasfixed2Bpm(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return '$toStringAsFixed ms RMSSD · $toStringAsFixed2 bpm';
  }

  @override
  String get exportRrIntervalsCsv => 'Eksportér RR-intervaller (CSV)';

  @override
  String get deleteMeasurement => 'Slet måling';

  @override
  String get remindMeToMeasureHrv => 'Påmind mig om at måle HRV efter træning';

  @override
  String get appleHealthIsNoLonger =>
      'Apple Sundhed er ikke længere tilgængelig';

  @override
  String get later => 'Senere';

  @override
  String get reconnect => 'Tilslut igen';

  @override
  String get gripStrength => 'Grebstyrke';

  @override
  String get leftKg => 'Venstre (kg)';

  @override
  String get rightKg => 'Højre (kg)';

  @override
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg) {
    return 'V $leftKg · H $rightKg kg';
  }

  @override
  String get notificationsAreOffYouCan =>
      'Notifikationer er slået fra. Du kan stadig måle fra din træning.';

  @override
  String get noRemindersFrom2200 => 'Ingen påmindelser fra 22:00 til 07:00';

  @override
  String get aReminderThatWouldFall =>
      'En påmindelse, der ville falde i dette tidsrum, springes over og flyttes ikke til morgenen.';

  @override
  String get remindersArriveQuietlyInThe =>
      'Påmindelser kommer lydløst i notifikationslisten.';

  @override
  String get noForecastForThisDay => 'Ingen prognose for denne dag';

  @override
  String get fullscreen => 'Fuld skærm';

  @override
  String source(Object source) {
    return '● $source';
  }

  @override
  String get shadedAreaProviderSpread =>
      'Skraveret område: spredning mellem udbydere';

  @override
  String get temperatureC => '● Temperatur °C';

  @override
  String get rainMm => '▥ Regn mm';

  @override
  String get uvIndex => '— UV-indeks';

  @override
  String get closeFullscreenWeatherChart => 'Luk vejrdiagrammet i fuld skærm';

  @override
  String get sleepStages => 'SØVNFASER';

  @override
  String get noStageTimelineForThis => 'Ingen faseoversigt for denne nat.';

  @override
  String round3(Object round) {
    return '$round%';
  }

  @override
  String get examplesOnlyCheckAndEnter =>
      'Kun eksempler: tjek og indtast værdierne fra produktetiketten pr. portion. Lad ukendte næringsstoffer stå tomme; indtast kun 0, hvis værdien er kendt.';

  @override
  String get nutritionStrategy => 'Ernæringsstrategi';

  @override
  String get noPreWorkoutNutritionStrategy =>
      'Der blev ikke gemt nogen ernæringsstrategi før træningen.';

  @override
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium) {
    return '$carbs g kulhydrater/t · $fluid ml/t · $sodium mg natrium/t';
  }

  @override
  String get forecastUpdatedReviewOrRecalculate =>
      'Prognosen er opdateret – gennemgå eller genberegn den gemte strategi.';

  @override
  String strategySavedSavedat(Object savedAt) {
    return 'Strategi gemt $savedAt';
  }

  @override
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  ) {
    return 'I alt under: $totalCarbs g kulhydrater · $totalFluid ml · $totalSodium mg natrium';
  }

  @override
  String every20MinAboutCarbs(Object carbs, Object fluid) {
    return 'Hvert 20. minut: ca. $carbs g kulhydrater og $fluid ml.';
  }

  @override
  String get packQuantitiesIncludeFullContainers =>
      'Pakkemængderne omfatter hele beholdere; du behøver ikke indtage det hele.';

  @override
  String get workoutChangedReviewOrRecalculate =>
      'Træningen er ændret – gennemgå eller genberegn den gemte strategi.';

  @override
  String get conditionsAndFeedingPlan => 'Forhold og ernæringsplan';

  @override
  String get editStrategy => 'Redigér strategi';

  @override
  String get recalculate => 'Genberegn';

  @override
  String get actualNutrition => 'Faktisk ernæring';

  @override
  String get someProductValuesAreUnknown =>
      'Nogle produktværdier er ukendte; totalerne er ufuldstændige.';

  @override
  String get logFoodAndFluids => 'Log mad og væske';

  @override
  String get recordWhatYouActuallyHad =>
      'Registrer, hvad du faktisk indtog. Planlagt indtag kopieres ikke til denne log.';

  @override
  String get elapsedMinutesIncludingStopsOptional =>
      'Forløbne minutter inkl. stop (valgfrit)';

  @override
  String recordedDurationActivityMin(Object activity) {
    return 'Registreret varighed: $activity min';
  }

  @override
  String get compareWithSavedStrategy => 'Sammenlign med gemt strategi';

  @override
  String get useMatchedSessionIfAvailable =>
      'Brug den matchende session, hvis den findes';

  @override
  String get noPlanComparison => 'Ingen sammenligning med planen';

  @override
  String titleDate(Object title, Object date) {
    return '$title · $date';
  }

  @override
  String get linkedStrategyUnavailable => 'Tilknyttet strategi er utilgængelig';

  @override
  String quantityName(Object quantity, Object name) {
    return '$quantity × $name';
  }

  @override
  String get removeIntake => 'Fjern indtag';

  @override
  String get addFoodOrDrink => 'Tilføj mad eller drikke';

  @override
  String get iHadNoIntake => 'Jeg indtog ingenting';

  @override
  String get giGutComfort => 'Mavekomfort';

  @override
  String get whatWorkedSymptomsAccessProblems =>
      'Hvad virkede / symptomer / adgangsproblemer';

  @override
  String get saveDraft => 'Gem kladde';

  @override
  String get skipLoggingThisActivity =>
      'Spring logning af denne aktivitet over';

  @override
  String get nutritionAndFluids => 'Ernæring og væske';

  @override
  String get productsToleranceAndMeasuredSweat =>
      'Produkter, tolerance og målte sveddtab';

  @override
  String get postWorkoutIntakeReminder => 'Påmindelse om indtag efter træning';

  @override
  String get onceAfterARecentEndurance =>
      'Én gang efter en nylig udholdenhedstræning; stille timer 22:00–08:00.';

  @override
  String get addHiloBpReport => 'Tilføj Hilo-blodtryksrapport';

  @override
  String get readingPdfReportsIsOnly =>
      'Læsning af PDF-rapporter er kun tilgængelig på iOS og macOS.';

  @override
  String get chooseAnotherReport => 'Vælg en anden rapport';

  @override
  String get biologicalAge => 'Biologisk alder';

  @override
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class) {
    return 'VO₂max $vo2max ml/kg/min · $vo2Class';
  }

  @override
  String get factorContributions => 'Faktorernes bidrag';

  @override
  String estimatedRangeRoundRound2Years(Object round, Object round2) {
    return 'Anslået interval $round–$round2 år. Et modelestimat, ikke en medicinsk diagnose.';
  }

  @override
  String get noEnergyMeasurementsForThis =>
      'Ingen energimålinger for denne dag';

  @override
  String get scanningStepOnTheScale =>
      'Søger … stil dig på vægten, når du er klar.';

  @override
  String waistWaistCmUpdateMonthly(Object waist) {
    return 'Talje: $waist cm – opdatér månedligt i Profil';
  }

  @override
  String get measuring => 'Måler …';

  @override
  String get tryAgain => 'Prøv igen';

  @override
  String get systolic => 'Systolisk';

  @override
  String get diastolic => 'Diastolisk';

  @override
  String get heartRate => 'Puls';

  @override
  String get weight => 'Vægt';

  @override
  String get bodyFat => 'Kropsfedt';

  @override
  String get duration => 'Varighed';

  @override
  String get deep => 'Dyb';

  @override
  String get spo => 'SpO₂';

  @override
  String get activityName => 'Aktivitetsnavn';

  @override
  String get sport => 'Sportsgren';

  @override
  String get distance => 'Distance';

  @override
  String get saved => 'Gemt';

  @override
  String get connectionFailedCheckYourInternet =>
      'Forbindelsen mislykkedes. Tjek din internetforbindelse.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Adgangskode';

  @override
  String get passwordTooShort => 'Adgangskoden er for kort';

  @override
  String get loginFailedCheckYourEmail =>
      'Login mislykkedes. Tjek din e-mail og adgangskode.';

  @override
  String get connectionFailedCheckYourCredentials =>
      'Forbindelsen mislykkedes. Tjek dine loginoplysninger og internetforbindelsen.';

  @override
  String get region => 'Region';

  @override
  String get hiloPod => 'Hilo Pod';

  @override
  String get hiloAccount => 'Hilo-konto';

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
  String get renphoAccount => 'Renpho-konto';

  @override
  String get garminConnectEmail => 'Garmin Connect-e-mail';

  @override
  String get verifyMfaCode => 'Bekræft MFA-kode';

  @override
  String get verificationCode => 'Bekræftelseskode';

  @override
  String errorE(Object e) {
    return 'Fejl: $e';
  }

  @override
  String get noHiloPodFoundMake =>
      'Ingen Hilo Pod fundet. Sørg for, at den er opladet og i nærheden.';

  @override
  String scanFailedE(Object e) {
    return 'Søgningen mislykkedes: $e';
  }

  @override
  String get hiloPod2 => 'Hilo Pod';

  @override
  String get scanForPod => 'Søg efter pod';

  @override
  String get scanForPolarH10 => 'Søg efter Polar H10';

  @override
  String get couldNotReachPolarCheck =>
      'Kunne ikke nå Polar. Tjek din forbindelse.';

  @override
  String get signInAndSendWorkout => 'Log ind og send træning';

  @override
  String get scanForScale => 'Søg efter vægt';

  @override
  String get passwordRequired => 'Adgangskode påkrævet';

  @override
  String get enterYourPhoneNumberWith =>
      'Indtast dit telefonnummer (med landekode, fx +45 …) og din Suunto-e-mail.';

  @override
  String get enterThePinFromThe => 'Indtast PIN-koden fra SMS\'en.';

  @override
  String get incorrectPinPleaseTryAgain => 'Forkert PIN-kode. Prøv igen.';

  @override
  String get phoneNumber => 'Telefonnummer';

  @override
  String get suuntoAccountEmail => 'E-mail til Suunto-konto';

  @override
  String get enterPinFromSms => 'Indtast PIN fra SMS';

  @override
  String get verifyConnect => 'Bekræft og tilslut';

  @override
  String get sendSmsCode => 'Send SMS-kode';

  @override
  String couldNotSavePreferencesE(Object e) {
    return 'Kunne ikke gemme indstillingerne: $e';
  }

  @override
  String get mon => 'Man';

  @override
  String get tue => 'Tir';

  @override
  String get wed => 'Ons';

  @override
  String get thu => 'Tor';

  @override
  String get fri => 'Fre';

  @override
  String get sat => 'Lør';

  @override
  String get sun => 'Søn';

  @override
  String get male => 'Mand';

  @override
  String get female => 'Kvinde';

  @override
  String get other => 'Andet';

  @override
  String get running => 'Løb';

  @override
  String get trailRunning => 'Trailløb';

  @override
  String get cycling => 'Cykling';

  @override
  String get swimming => 'Svømning';

  @override
  String get triathlon => 'Triatlon';

  @override
  String get hiking => 'Vandring';

  @override
  String get rowing => 'Roning';

  @override
  String get buildMyPlan => 'Opret min plan';

  @override
  String get keepAConsistentBedtimeAnd =>
      'Hold faste sengetider og opstandstider for at støtte din søvnrutine.';

  @override
  String get thisWorkoutHasNoSets => 'Denne træning har ingen sæt.';

  @override
  String loadName(Object name) {
    return 'Belastning ($name)';
  }

  @override
  String get setLabel => 'Sæt';

  @override
  String get lowestReps => 'Laveste gentagelser';

  @override
  String get highestReps => 'Højeste gentagelser';

  @override
  String get repsPerSide => 'Gentagelser pr. side';

  @override
  String get fromReps => 'Fra (gent.)';

  @override
  String get toReps => 'Til (gent.)';

  @override
  String get addedLoad => 'Tillægsbelastning';

  @override
  String get assistance => 'Assistance';

  @override
  String get tempoOptional => 'Tempo (valgfrit)';

  @override
  String get notesOptional => 'Noter (valgfrit)';

  @override
  String get enterTheRepetitionsDone => 'Indtast de udførte gentagelser.';

  @override
  String plannedUnit(Object unit) {
    return 'Planlagt $unit';
  }

  @override
  String get repsDone => 'Udførte gentagelser';

  @override
  String get resistance => 'Modstand';

  @override
  String get implementsLabel => 'Redskaber';

  @override
  String get name => 'Navn';

  @override
  String get instructionsOptional => 'Instruktioner (valgfrit)';

  @override
  String get remember => 'Husk';

  @override
  String get notSavedYet => 'Endnu ikke gemt';

  @override
  String get saving => 'Gemmer …';

  @override
  String get couldNotSave => 'Kunne ikke gemme';

  @override
  String get plannedValuesAreHintsNot =>
      'Planlagte værdier er vejledende, ikke resultater. Tryk på et sæt for at registrere det.';

  @override
  String get completedAsPlanned => 'Gennemført som planlagt';

  @override
  String get save => 'Gem';

  @override
  String get nameTheTemplate => 'Giv skabelonen et navn.';

  @override
  String setN(Object n) {
    return 'Sæt $n';
  }

  @override
  String get changesApplyToThisWorkout =>
      'Ændringerne gælder kun denne træning. Gennemførte træninger og andre sessioner forbliver uændrede.';

  @override
  String get saveForThisWorkout => 'Gem til denne træning';

  @override
  String knownForKnownOfOf(Object known, Object of) {
    return 'Kendt for $known af $of sæt med belastning';
  }

  @override
  String get sessionEstimate => 'Sessionsestimat';

  @override
  String get calculatedRange => 'Beregnet interval';

  @override
  String get timedWork => 'Tidsbaseret arbejde';

  @override
  String get strengthTraining => 'Styrketræning';

  @override
  String get theExercisesCouldNotBe => 'Øvelserne kunne ikke indlæses.';

  @override
  String get resumeWorkout => 'Genoptag træning';

  @override
  String get strengthWorkout => 'Styrketræning';

  @override
  String get untitledTemplate => 'Unavngiven skabelon';

  @override
  String get theRecordedExercisesCouldNot =>
      'De registrerede øvelser kunne ikke indlæses.';

  @override
  String get exercisesPerformed => 'Udførte øvelser';

  @override
  String get comparedWithThePlanAs =>
      'Sammenlignet med planen, som den var, da loggingen startede.';

  @override
  String topWorkingLoadName(Object name) {
    return 'Højeste arbejdsbelastning ($name)';
  }

  @override
  String get estimated1rmMiddleOfRange => 'Estimeret 1RM, midt i intervallet';

  @override
  String get noLoggedSessionsYet => 'Ingen loggede sessioner endnu.';

  @override
  String get noRadarFramesAvailable => 'Ingen radarbilleder tilgængelige';

  @override
  String get playRadar => 'Afspil radar';

  @override
  String get pauseRadar => 'Sæt radar på pause';

  @override
  String get high => 'Høj';

  @override
  String get clear => 'Klart';

  @override
  String get bodyweight => 'Kropsvægt';

  @override
  String get resistance2 => 'Modstand —';

  @override
  String assistUnit(Object unit) {
    return 'Assistance $unit';
  }

  @override
  String get reps2 => 'Gent. —';

  @override
  String get notRecorded => 'Ikke registreret';

  @override
  String get skipped => 'Sprunget over';

  @override
  String get health => 'Sundhed';

  @override
  String get manual => 'Manuel';

  @override
  String expandName(Object name) {
    return 'Udvid $name';
  }

  @override
  String get open => 'Åbn';

  @override
  String get noScalePaired => 'Ingen vægt parret';

  @override
  String get paired => 'Parret';

  @override
  String get change => 'Skift';

  @override
  String get noCuffPaired => 'Ingen manchet parret';

  @override
  String get noPolarH10FoundWear =>
      'Ingen Polar H10 fundet. Tag båndet på, fugt elektroderne, og tjek at ingen anden app bruger begge Bluetooth-forbindelser.';

  @override
  String get enterMinutesSinceTrainingEnded =>
      'Indtast minutter siden træningen sluttede, fra 0 til 1440.';

  @override
  String get timingFollowsYourWorkout => 'Timingen følger din træning.';

  @override
  String get recordingStayStill => 'Optagelse · hold dig stille';

  @override
  String get meanHrBpm => 'Gns. puls · bpm';

  @override
  String get pairAPolarH10First => 'Par først en Polar H10.';

  @override
  String get around30MinutesAfterTraining =>
      'Omkring 30 minutter efter træning, når træningen er tilgængelig i tide.';

  @override
  String get reminderDiagnostics => 'Påmindelsesdiagnostik';

  @override
  String get forecast => 'Prognose';

  @override
  String get enterAName => 'Indtast et navn';

  @override
  String get enterAValidAmount => 'Indtast en gyldig mængde';

  @override
  String get enterAPositiveAmount => 'Indtast en positiv mængde';

  @override
  String get maximum120GH => 'Maksimalt 120 g/t';

  @override
  String get carbohydrateTargetGH => 'Kulhydratmål g/t';

  @override
  String get fluidTargetMlH => 'Væskemål ml/t';

  @override
  String get sodiumTargetMgHNot => 'Natriummål mg/t (ikke salt)';

  @override
  String get surfaceFeedingAccess => 'Underlag / adgang til forplejning';

  @override
  String get expectedAscentM => 'Forventet stigning m';

  @override
  String get expectedAltitudeM => 'Forventet højde m';

  @override
  String get humidity => 'Luftfugtighed %';

  @override
  String get windKmH => 'Vind km/t';

  @override
  String get dayForecast => 'Dagsprognose';

  @override
  String get enteredConditions => 'Indtastede forhold';

  @override
  String get productFoodName => 'Produkt- / madnavn';

  @override
  String get servingsQuantity => 'Portioner / mængde';

  @override
  String get when => 'Hvornår';

  @override
  String get carbohydrateGServing => 'Kulhydrater g / portion';

  @override
  String get fluidMlServing => 'Væske ml / portion';

  @override
  String get caffeineMgServing => 'Koffein mg / portion';

  @override
  String get proteinGServing => 'Protein g / portion';

  @override
  String get gel => 'Gel';

  @override
  String get water => 'Vand';

  @override
  String get sportsDrink => 'Sportsdrik';

  @override
  String get bar => 'Bar';

  @override
  String get finishIntakeLog => 'Afslut indtagslog';

  @override
  String get importing => 'Importerer …';

  @override
  String importNewreadings(Object newReadings) {
    return 'Importér $newReadings';
  }

  @override
  String get reading => 'Læser …';

  @override
  String get chooseReportPdf => 'Vælg rapport (PDF)';

  @override
  String get yourTrainingHistoryIsReady => 'Din træningshistorik er klar';

  @override
  String get importingYourTrainingHistory => 'Din træningshistorik importeres';

  @override
  String get stopImport => 'Stop importen';

  @override
  String get dismiss => 'Afvis';

  @override
  String get openai => 'OpenAI';

  @override
  String get appleIntelligence => 'Apple Intelligence';

  @override
  String get nonAiBriefing => 'Briefing uden AI';

  @override
  String get noBriefing => 'Ingen briefing';

  @override
  String get ruleBasedSummaryFromYour =>
      'Regelbaseret resumé af dine sundhedsdata – ingen API-kald';

  @override
  String get hideTheBriefingCard => 'Skjul briefingkortet';

  @override
  String get flutter => 'Flutter';

  @override
  String get stateManagement => 'Tilstandshåndtering';

  @override
  String get bluetoothLe => 'Bluetooth LE';

  @override
  String get interactiveMaps => 'Interaktive kort';

  @override
  String get chartsGraphs => 'Diagrammer og grafer';

  @override
  String get secureCredentialStorage => 'Sikker lagring af loginoplysninger';

  @override
  String get markdownRendering => 'Markdown-visning';

  @override
  String get appleOnDeviceAi => 'Apples AI på enheden';

  @override
  String get cryptography => 'Kryptografi';

  @override
  String get appleHealthHealthConnect => 'Apple Sundhed og Health Connect';

  @override
  String get runtimePermissions => 'Kørselstidstilladelser';

  @override
  String get shareExport => 'Deling og eksport';

  @override
  String get openUrls => 'Åbn URL\'er';

  @override
  String get internationalisation => 'Internationalisering';

  @override
  String get utilities => 'Hjælpeprogrammer';

  @override
  String get icons => 'Ikoner';

  @override
  String get fjelia => 'Fjelia';

  @override
  String get fjeliaFeedback => 'Fjelia-feedback';

  @override
  String get couldNotSendTheReport =>
      'Rapporten kunne ikke sendes. Din tekst er stadig her. Prøv igen.';

  @override
  String get yourEmail => 'Din e-mail';

  @override
  String get enterAValidEmailAddress => 'Indtast en gyldig e-mailadresse.';

  @override
  String get subject => 'Emne';

  @override
  String get sending => 'Sender …';

  @override
  String get sendReport => 'Send rapport';

  @override
  String get sleepRecovery => 'Søvn og restitution';

  @override
  String get activitiesTraining => 'Aktiviteter og træning';

  @override
  String get bodyWellness => 'Krop og velvære';

  @override
  String get hilo => 'Hilo';

  @override
  String get hiloBle => 'Hilo BLE';

  @override
  String get garminApi => 'Garmin (API)';

  @override
  String get renphoScale => 'Renpho-vægt';

  @override
  String get connected => 'Forbundet';

  @override
  String get notConnected => 'Ikke forbundet';

  @override
  String get manage => 'Administrer';

  @override
  String get connect => 'Tilslut';

  @override
  String get habits => 'Vaner';

  @override
  String get smokingAlcohol => 'Rygning, alkohol';

  @override
  String get clinicalLab => 'Laboratorieværdier';

  @override
  String get hba1cLipidsKidney => 'HbA1c, lipider, nyrer';

  @override
  String get sex => 'Køn';

  @override
  String get smoking => 'Rygning';

  @override
  String get never => 'Aldrig';

  @override
  String get former => 'Tidligere';

  @override
  String get current => 'Nuværende';

  @override
  String get hba1c => 'HbA1c';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get prediabetes => 'Prædiabetes';

  @override
  String get type1 => 'Type 1';

  @override
  String get type2 => 'Type 2';

  @override
  String get apob => 'ApoB';

  @override
  String get optionalPlansAndPaceGuides =>
      'Valgfrit. Planer og tempovejledning bruger det; stigningen ovenfor former også træningen.';

  @override
  String get addRaceGoal2 => 'Tilføj løbsmål';

  @override
  String get editRaceGoal => 'Redigér løbsmål';

  @override
  String get trailRunning2 => 'Trailløb';

  @override
  String get roadCycling => 'Landevejscykling';

  @override
  String get gravel => 'Gravel';

  @override
  String get indoorRowing => 'Indendørs roning';

  @override
  String get selectDate => 'Vælg dato';

  @override
  String get committed => 'Forpligtet';

  @override
  String get flexible => 'Fleksibel';

  @override
  String get notGoing => 'Deltager ikke';

  @override
  String get notSaid => 'Ikke oplyst';

  @override
  String get finish => 'Sluttid';

  @override
  String get saveGoal => 'Gem mål';

  @override
  String get exportAllRecordedWorkoutsAs =>
      'Eksportér alle registrerede træninger som regneark.';

  @override
  String get backupsIncludeYourHealthData =>
      'Sikkerhedskopier omfatter dine sundhedsdata, træningsplaner og profilindstillinger. Loginoplysninger er udeladt. Gendannelse erstatter lokale data.';

  @override
  String get trail => 'Trail';

  @override
  String get inlineSkating => 'Inlineskating';

  @override
  String get nordicClassic => 'Klassisk langrend';

  @override
  String get skateSkiing => 'Skating (langrend)';

  @override
  String get strength => 'Styrke';

  @override
  String get walking => 'Gang';

  @override
  String get yoga => 'Yoga';

  @override
  String get skiing => 'Skiløb';

  @override
  String get climbing => 'Klatring';

  @override
  String get monday => 'Mandag';

  @override
  String get sunday => 'Søndag';

  @override
  String get month => 'Måned';

  @override
  String get week => 'Uge';

  @override
  String get list => 'Liste';

  @override
  String get train => 'Træning';

  @override
  String get restDay => 'Hvile';

  @override
  String get kilogramsKg => 'Kilogram (kg)';

  @override
  String get poundsLb => 'Pund (lb)';

  @override
  String get regenerateWorkouts => 'Genopret træninger';

  @override
  String get starting => 'Starter';

  @override
  String get allPlannedWorkoutsDeleted =>
      'Alle planlagte træninger er slettet.';

  @override
  String get searching => 'Søger …';

  @override
  String get searchCity => 'Søg efter by';

  @override
  String get fixedLocationSavedWeatherWill =>
      'Fast placering gemt. Vejret opdateres.';

  @override
  String get locationDisabledThePlanWeather =>
      'Placering deaktiveret. Vejrkortet i planen er skjult.';

  @override
  String locationSetToName(Object name) {
    return 'Placering sat til $name';
  }

  @override
  String get notEnoughDaytimeAndNighttime => 'Ikke nok dag- og natmålinger';

  @override
  String get onlyTheWeightWasReceived =>
      'Kun vægten blev modtaget. For kropsfedt, muskler og de øvrige værdier skal du stå barfodet på metalelektroderne, til vægten er færdig.';

  @override
  String get addYourWaistInProfile =>
      'Tilføj taljemål i Profil for visceralt fedt.';

  @override
  String get manualActivity => 'Manuel aktivitet';

  @override
  String get theseCredentialsAreStoredEncrypted =>
      'Disse loginoplysninger gemmes krypteret på din enhed (iOS-nøglering / Android Keystore). De sendes aldrig til andre servere end Hilo.';

  @override
  String get corosCredentialsAreStoredEncrypted =>
      'Coros-loginoplysninger gemmes krypteret på din enhed. Fjelia læser data direkte fra Coros\' cloud-API, det samme som webappen Coros Training Hub bruger.';

  @override
  String get connectAnyCombinationYouCan =>
      'Tilslut en vilkårlig kombination – du kan altid tilføje flere senere i Indstillinger.';

  @override
  String get garminCredentialsAreStoredEncrypted =>
      'Garmin-loginoplysninger gemmes krypteret på din enhed. Fjelia bruger den uofficielle Garmin Connect-API – samme tilgang som mange community-apps.';

  @override
  String get enterTheVerificationCode => 'Indtast bekræftelseskoden';

  @override
  String get appleHealthDataAccess =>
      'Fjelia læser dine sundhedsdata fra Apple Sundhed. Med din tilladelse kan den også skrive synkroniserede data til Apple Sundhed. Administrer adgangen i enhedens indstillinger.';

  @override
  String get scanAgain => 'Søg igen';

  @override
  String get wearTheHiloBandDuring =>
      'Bær Hilo-båndet under søvn for kontinuerlig blodtryksmåling. Data synkroniseres automatisk hver morgen, når appen åbnes.';

  @override
  String get noPolarH10FoundWear2 =>
      'Ingen Polar H10 fundet. Tag båndet på med fugtige elektroder, og sørg for, at ingen anden app (eller ur) er forbundet til det; søg derefter igen.';

  @override
  String get wearTheStrapWithMoist2 =>
      'Tag båndet på med fugtige elektroder før søgningen. Mål senere med + → Polar H10 HRV-måling; resultaterne vises ved siden af din natlige HRV.';

  @override
  String get signedInPlannedWorkoutsCan =>
      'Logget ind. Planlagte træninger kan nu sendes til Polar. Ældre sessioner importeres ved næste fulde historiksynkronisering.';

  @override
  String get saveYourPolarFlowLogin =>
      'Gem dit Polar Flow-login for at sende planlagte træninger og importere sessioner ældre end 30 dage. Det bliver i nøgleringen på denne enhed og sendes kun til Polar. Send en træning fra planlæggerarket, og synkronisér derefter Polar Flow til dit ur. Tjek, at dine pulszoner i Polar passer med Fjelia.';

  @override
  String get signInToSendThis =>
      'Log ind for at sende denne træning til din Polar Flow-kalender. Dit login bliver i nøgleringen på denne enhed og sendes kun til Polar. Efter afsendelse synkroniserer du Polar Flow til dit ur.';

  @override
  String get checkAndSave => 'Tjek og gem';

  @override
  String get noScaleFoundStepOn =>
      'Ingen vægt fundet. Stil dig på vægten, så den vågner, og søg igen.';

  @override
  String get stepOnTheScaleBefore =>
      'Stil dig på vægten før søgningen, så den vågner. Senere bruger du + → RENPHO-vægt til at måle.';

  @override
  String get renphoCredentialsAreStoredEncrypted =>
      'Renpho-loginoplysninger gemmes krypteret på din enhed. Fjelia taler direkte med Renphos cloud-API.';

  @override
  String get couldNotSendSmsCheck =>
      'SMS kunne ikke sendes. Tjek dit telefonnummer og din internetforbindelse.';

  @override
  String get theEmailIsUsedFor =>
      'E-mailen bruges til sikker signering af forespørgsler og sendes ikke til Suunto-servere.';

  @override
  String get suuntoUsesSmsVerificationSame =>
      'Suunto bruger SMS-verifikation (ligesom Suunto-appen). En engangs-PIN sendes til din telefon. Dine loginoplysninger gemmes kun krypteret på enheden.';

  @override
  String get tellUsAboutYourRace =>
      'Fortæl os om dit løb og din tidsplan. Fjelia opbygger din plan nu og finder dit niveau ud fra dine tidligere aktiviteter (Garmin, Suunto, Polar, COROS, Apple Sundhed), når de er hentet.';

  @override
  String get noAccountConnectedSoFjelia =>
      'Ingen konto er forbundet, så Fjelia har ingen historik at lære af. Tilslut Garmin, Suunto, Polar, COROS eller Apple Sundhed, så afgør din faktiske træning.';

  @override
  String get yourPastActivitiesAreStill =>
      'Dine tidligere aktiviteter importeres stadig. Du kan opbygge din plan nu – den finjusteres automatisk, når importen er færdig.';

  @override
  String get buildingYourPlan => 'Opbygger din plan …';

  @override
  String get saveContinue => 'Gem og fortsæt';

  @override
  String get addYourMainPriorityA =>
      'Tilføj dit hovedløb (prioritet A). Planen periodiseres frem mod det: grundlag, opbygning, top og nedtrapning. Uden løbsmål oprettes der endnu ingen plan.';

  @override
  String get noMeasurementsYet => 'Ingen målinger endnu';

  @override
  String get date => 'Dato';

  @override
  String deepSleepIsBelowOptimal(Object round) {
    return 'Dyb søvn er under det optimale ($round %). Undgå alkohol og tunge måltider 3 timer før sengetid.';
  }

  @override
  String get finishWithSetsOpen => 'Afslutte med åbne sæt?';

  @override
  String get completeThePlannedWorkout => 'Fuldføre den planlagte træning?';

  @override
  String get marksThePlannedSessionAs =>
      'Markerer den planlagte session som gennemført med denne træning.';

  @override
  String get discardThisWorkout => 'Kassere denne træning?';

  @override
  String get removesTheWorkoutAndEvery =>
      'Fjerner træningen og alle sæt, der er registreret i den.';

  @override
  String assistanceName(Object name) {
    return 'Assistance ($name)';
  }

  @override
  String get enterSecondsOrMSs => 'Indtast sekunder eller m:ss.';

  @override
  String get enterTheLoadAsA => 'Indtast belastningen som et tal.';

  @override
  String get loadCannotBeNegative => 'Belastningen kan ikke være negativ.';

  @override
  String get enterTheEffortValue => 'Indtast anstrengelsesværdien.';

  @override
  String get nameTheExercise => 'Giv øvelsen et navn.';

  @override
  String get atLeastOneImplement => 'Mindst ét redskab.';

  @override
  String get anIncrementMustBePositive => 'Et trin skal være positivt.';

  @override
  String get enterAPositiveStep => 'Indtast et positivt trin.';

  @override
  String get repsInReserve => 'Gentagelser i reserve';

  @override
  String get loadPerImplement => 'Belastning pr. redskab';

  @override
  String get restAfterThisSet => 'Pause efter dette sæt';

  @override
  String get enterHowLongTheSet => 'Indtast, hvor længe sættet varede.';

  @override
  String get repsDonePerSide => 'Udførte gentagelser pr. side';

  @override
  String plannedRepminRepmax(Object repMin, Object repMax) {
    return 'Planlagt $repMin–$repMax';
  }

  @override
  String get restTakenBeforeTheNext => 'Hvile holdt før næste sæt';

  @override
  String get equipment => 'Udstyr';

  @override
  String get implementsUsedTogether => 'Redskaber brugt sammen';

  @override
  String get smallestLoadStepOptional => 'Mindste belastningstrin (valgfrit)';

  @override
  String get theSmallestChangeYourPlates =>
      'Den mindste ændring, dine skiver, håndvægte eller maskine tillader, husket til dette udstyr.';

  @override
  String get loadStep => 'Belastningstrin';

  @override
  String get finishWithIncompleteData => 'Afslutte med ufuldstændige data?';

  @override
  String get leaveWithoutSaving => 'Forlade uden at gemme?';

  @override
  String get theLastChangeCouldNot => 'Den seneste ændring kunne ikke gemmes.';

  @override
  String get comparedWithAPlanChosen =>
      'Sammenlignet med en plan valgt efter træningen. Planlagte værdier er vejledende, ikke resultater.';

  @override
  String get lastSet => 'Sidste sæt';

  @override
  String get templateName => 'Skabelonnavn';

  @override
  String get betweenExercises => 'Mellem øvelser';

  @override
  String get betweenRounds => 'Mellem runder';

  @override
  String get discardChanges => 'Kassere ændringer?';

  @override
  String get yourEditsToThisWorkout =>
      'Dine ændringer af denne træning er ikke gemt.';

  @override
  String get estimatedDuration => 'Estimeret varighed';

  @override
  String get workingSets => 'Arbejdssæt';

  @override
  String get estimatedExternalVolume => 'Estimeret eksternt volumen';

  @override
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion) {
    return 'Belastning øget fra $unit til $unit2 efter din gennemgang (regel v$ruleVersion).';
  }

  @override
  String get thePlannedWorkoutHasNo =>
      'Den planlagte træning har ingen øvelser at logge fra.';

  @override
  String get completedSets => 'Gennemførte sæt';

  @override
  String get knownExternalVolume => 'Kendt eksternt volumen';

  @override
  String get updateStrengthSessions2 => 'Opdatere styrkesessionerne?';

  @override
  String get upcomingSessionsArePlannedAgain =>
      'Kommende sessioner planlægges igen fra i dag: styrke følger dine løbsmål hver styrkedag med varierede sessioner. Gennemførte og oversprungne træninger bevares; øvelser, du har ændret i en kommende styrkesession, erstattes.';

  @override
  String get thisSessionUsesAnEarlier =>
      'Denne session bruger en tidligere styrkeskabelon. Opdaterede planer varierer styrke efter fase og løbsmål og bruger hver styrkedag.';

  @override
  String get estimated1rmUsesEpleyAnd =>
      'Estimeret 1RM bruger Epley og Brzycki på gennemførte arbejdssæt med 1–10 gentagelser og kendt belastning, vist som intervallet imellem. Det er et estimat, ikke et testet maksimum.';

  @override
  String get localWeather => 'Lokalt vejr';

  @override
  String get today => 'I dag';

  @override
  String get low => 'Lav';

  @override
  String get moderate => 'Moderat';

  @override
  String get overcast => 'Overskyet';

  @override
  String get partlyCloudy => 'Delvist skyet';

  @override
  String collapseName(Object name) {
    return 'Skjul $name';
  }

  @override
  String get variableLoads => 'Variable belastninger';

  @override
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  ) {
    return 'Regel v$strengthProgressionRuleVersion: de seneste $strengthProgressionMinSessions sammenlignelige sessioner, hvert sæt i toppen af gentagelsesmålet, med registreret anstrengelse og ikke hårdere end tilsigtet. $reason';
  }

  @override
  String get stepOnYourScaleBefore => 'Stil dig på vægten før søgningen';

  @override
  String get scanning => 'Søger …';

  @override
  String get pair => 'Par';

  @override
  String get selectYourAktiiaPWristband =>
      'Vælg dit AKTIIA P…-armbånd. Læg det på opladeren for at vække det, hvis det ikke vises.';

  @override
  String get measurementInterruptedWhileTheApp =>
      'Målingen blev afbrudt, mens appen var i baggrunden. Gentag den.';

  @override
  String get noRecentRrDataWith =>
      'Ingen nylige RR-data med god kontakt. Tjek båndet, og gentag målingen.';

  @override
  String get settlingStayStill => 'Falder til ro · hold dig i ro';

  @override
  String get deleteSpotHrvMeasurement => 'Slette Spot-HRV-målingen?';

  @override
  String get thisRemovesTheRecordingAnd =>
      'Dette fjerner optagelsen og dens rå RR-intervaller.';

  @override
  String get appleHealthStoppedAnsweringSo =>
      'Apple Sundhed holdt op med at svare, så Fjelia afbrød forbindelsen og læser eller skriver ikke længere sundhedsdata.\n\nTillad Fjelia igen under Indstillinger → Sundhed → Dataadgang og enheder → Fjelia, og tilslut derefter Apple Sundhed igen.';

  @override
  String get thisRemovesTheSelectedGrip =>
      'Dette fjerner den valgte grebstyrkemåling.';

  @override
  String get hideReminderDiagnostics => 'Skjul påmindelsesdiagnostik';

  @override
  String get loading => 'Indlæser …';

  @override
  String get touchTheChartForDetails => 'Tryk på diagrammet for detaljer';

  @override
  String get indoor => 'Indendørs';

  @override
  String get road => 'Vej';

  @override
  String get technical => 'Teknisk';

  @override
  String get snow => 'Sne';

  @override
  String get pool => 'Pool';

  @override
  String get openWater => 'Åbent vand';

  @override
  String get ambientTemperatureC => 'Omgivelsestemperatur °C';

  @override
  String carryAboutGelsGelsGelcarbs(
    Object gels,
    Object gelCarbs,
    Object bottles,
    Object bottleMl,
    Object drinkCarbs,
  ) {
    return 'Medbring omkring $gels geler ($gelCarbs g kulhydrater hver) + $bottles × $bottleMl ml flasker. $drinkCarbs g kulhydrater kommer fra drikkepulveret.';
  }

  @override
  String get intakeNotRecorded => 'Indtag ikke registreret';

  @override
  String get loggingDeclinedIntakeUnknown => 'Logning afvist – indtag ukendt';

  @override
  String get confirmedNoIntake => 'Bekræftet: intet indtag';

  @override
  String get draft => 'Kladde · ';

  @override
  String get actualIntakePerServing => 'Faktisk indtag · pr. portion';

  @override
  String get minuteIntoWorkoutDuringOnly =>
      'Minut i træningen (kun under, valgfrit)';

  @override
  String get sodiumMgServingNotSalt => 'Natrium mg / portion (ikke salt)';

  @override
  String get comfortable => 'Behageligt';

  @override
  String get mildSymptoms => 'Milde symptomer';

  @override
  String get moderateSymptoms => 'Moderate symptomer';

  @override
  String get severeSymptoms => 'Alvorlige symptomer';

  @override
  String get personalNutritionSettings => 'Personlige ernæringsindstillinger';

  @override
  String get practisedCarbohydrateToleranceGH =>
      'Trænet kulhydrattolerance g/t (op til 120)';

  @override
  String get exportTheMonthlyReportAs =>
      'Eksportér månedsrapporten som PDF i Hilo-appen, og vælg den her. Kun målingerne importeres; navn, e-mail og kropsdata i rapporten ignoreres.';

  @override
  String get nothingNewAllReadingsWere =>
      'Intet nyt: alle målinger var allerede gemt.';

  @override
  String get historyImportIncomplete => 'Historikimport ufuldstændig';

  @override
  String get youCanKeepUsingFjelia =>
      'Du kan fortsætte med at bruge Fjelia, men hold den åben: iOS sætter importen på pause, når appen er i baggrunden, og den fortsætter næste gang, du åbner Fjelia. Din plan kalibreres, når importen er færdig.';

  @override
  String get addYourBirthYearIn =>
      'Tilføj dit fødselsår under Indstillinger → Profil for at se dit estimat.';

  @override
  String get fitnessAge => 'Konditionsalder';

  @override
  String get estLifespan => 'Est. levetid';

  @override
  String get delta => 'Forskel';

  @override
  String couldNotOpenKey(Object key) {
    return 'Kunne ikke åbne $key';
  }

  @override
  String get appleIntelligenceIsNotAvailable =>
      'Apple Intelligence er ikke tilgængelig på denne enhed. Brug Free AI, eller vælg en anden udbyder.';

  @override
  String get personalisedMorningLunchAfternoonEvening =>
      'Personligt resumé for morgen/frokost/eftermiddag/aften';

  @override
  String get enterASubject => 'Indtast et emne.';

  @override
  String get message => 'Besked';

  @override
  String get enterAMessageOfAt => 'Indtast en besked på mindst 10 tegn.';

  @override
  String get garminConnect => 'Garmin Connect';

  @override
  String get hiloBloodPressure => 'Hilo (blodtryk)';

  @override
  String get renphoBodyScale => 'Renpho (kropsvægt)';

  @override
  String get hiloPodCuff => 'Hilo Pod / manchet';

  @override
  String disconnectLabel(Object label) {
    return 'Afbryde forbindelsen til $label?';
  }

  @override
  String get yourSavedMeasurementsWillRemain =>
      'Dine gemte målinger forbliver på denne enhed.';

  @override
  String get notEnoughRecentHeartRate =>
      'Ikke nok nylige pulsdata til at justere zonerne.';

  @override
  String get aerobicBase => 'Aerob base';

  @override
  String get tempo => 'Tempo';

  @override
  String get lactateThreshold => 'Laktattærskel';

  @override
  String get birthYearHeightWaist => 'Fødselsår, højde, talje';

  @override
  String get enterAValidValue => 'Indtast en gyldig værdi';

  @override
  String get birthYear => 'Fødselsår';

  @override
  String get height => 'Højde';

  @override
  String get waist => 'Talje';

  @override
  String get yearsSinceQuit => 'År siden du stoppede';

  @override
  String get cigarettesPerDay => 'Cigaretter pr. dag';

  @override
  String get standardDrinksPerMonth => 'Standarddrinks pr. måned';

  @override
  String get enterAValidNumber => 'Indtast et gyldigt tal';

  @override
  String get enterARaceName => 'Indtast et løbsnavn';

  @override
  String get useHMmOrH =>
      'Brug t:mm eller t:mm:ss, en tid du virkelig kunne løbe';

  @override
  String get flexibleThePlanMayDrop =>
      'Fleksibel: Planen kan droppe dette arrangement, hvis det kolliderer med et vigtigere.';

  @override
  String get selectARaceDate => 'Vælg en løbsdato';

  @override
  String thatIsTenTimesOr(Object likely) {
    return 'Det er ti gange (eller en tiendedel af) de sædvanlige $likely km. Brug $likely km i stedet?';
  }

  @override
  String get addGoal => 'Tilføj mål';

  @override
  String get restoreFailed => 'Gendannelse mislykkedes';

  @override
  String get replaceLocalData => 'Erstatte lokale data?';

  @override
  String get restoringThisBackupReplacesAll =>
      'Gendannelse af denne sikkerhedskopi erstatter alle lokale sundheds- og træningsdata. Eksisterende loginoplysninger bevares.';

  @override
  String get openingBackupZip => 'Åbner sikkerhedskopi-ZIP';

  @override
  String get addAFutureRaceGoal => 'Tilføj først et fremtidigt løbsmål.';

  @override
  String get deleteAllWorkouts2 => 'Slette alle træninger?';

  @override
  String get thisDeletesPlannedWorkoutsOn =>
      'Dette sletter planlagte træninger på denne telefon og på din tilsluttede urplatform. Gennemførte aktiviteter bevares.';

  @override
  String get regenerateWorkouts2 => 'Genoprette træninger?';

  @override
  String get noRaceGoalsYetAdd =>
      'Ingen løbsmål endnu. Tilføj et eller synkronisér fra Garmin.';

  @override
  String get deleteRaceGoal => 'Slette løbsmålet?';

  @override
  String deletingFailedFailure(Object failure) {
    return 'Sletning mislykkedes: $failure';
  }

  @override
  String allPlannedWorkoutsDeletedRemoved(Object removed) {
    return 'Alle planlagte træninger er slettet. Fjernet fra dine platforme: $removed.';
  }

  @override
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return 'Bruger nuværende placering: $toStringAsFixed, $toStringAsFixed2';
  }

  @override
  String get typeSleep => 'Søvn';

  @override
  String get typeBloodPressure => 'Blodtryk';

  @override
  String get addHiloBpReportPdf => 'Tilføj Hilo-blodtryksrapport (PDF)';

  @override
  String get hiloCuffBle => 'Hilo-manchet (BLE)';

  @override
  String get typeSpo2 => 'SpO₂ / pulsoximeter';

  @override
  String get typeWeightScale => 'Personvægt';

  @override
  String get polarH10HrvMeasurement => 'Polar H10 HRV-måling';

  @override
  String samplingWouldStartMinutes(Object minutes) {
    return 'Målingen ville starte omkring $minutes min efter, at træningen sluttede.';
  }

  @override
  String samplingStartedMinutes(Object minutes) {
    return 'Målingen startede $minutes min efter, at træningen sluttede.';
  }

  @override
  String get unknown => 'Ukendt';

  @override
  String get before => 'Før';

  @override
  String get during => 'Under';

  @override
  String get after => 'Efter';

  @override
  String get enumWarmUp => 'Opvarmning';

  @override
  String get enumWorking => 'Arbejdssæt';

  @override
  String get enumBackOff => 'Back-off';

  @override
  String get enumTechnique => 'Teknik';

  @override
  String get enumExternalLoad => 'Ekstern belastning';

  @override
  String get enumBandResistance => 'Bånd / modstand';

  @override
  String get enumTotalLoad => 'Samlet belastning';

  @override
  String get enumPerImplement => 'Pr. redskab';

  @override
  String get enumOneImplement => 'Ét redskab';

  @override
  String get enumBothSides => 'Begge sider';

  @override
  String get enumAlternatingTotalReps => 'Vekslende, gentagelser i alt';

  @override
  String get enumPartial => 'Delvist';

  @override
  String get enumFailed => 'Mislykket';

  @override
  String get enumStraightSets => 'Almindelige sæt';

  @override
  String get enumSuperset => 'Superset';

  @override
  String get enumCircuit => 'Cirkel';

  @override
  String get enumRir => 'RIR';

  @override
  String get enumRpe110 => 'RPE 1–10';

  @override
  String get enumBeforeTraining => 'Før træning';

  @override
  String get enumAfterTraining => 'Efter træning';

  @override
  String get enumResting => 'I hvile';

  @override
  String get enumSeated => 'Siddende';

  @override
  String get enumLyingDown => 'Liggende';

  @override
  String get duringRoutineGelsAreNot =>
      'Under: Almindelige geler er ikke nødvendige til denne korte/lette session. Drik efter tørst.';

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      'Under: Fordel kulhydrater og drikke over små, regelmæssige indtag. Tæl drikkens kulhydrater med i samme total som geler og mad.';

  @override
  String get fluidIsAnEditableStarting =>
      'Væske er et redigerbart startestimat, ikke en kvote. Brug tørst, indøvet indtag og målte sveddtab; tving ikke ekstra vand i dig.';

  @override
  String get afterHaveCarbohydrateAndA =>
      'Efter: spis kulhydrater og et måltid med protein. Prioritér genopfyldning og rehydrering, når der snart er en ny session.';

  @override
  String get swimmingPlaceALabelledBottle =>
      'Svømning: sæt en mærket flaske ved bassinkanten, og brug pauserne mellem sæt til slurke eller forplejning. Forholdene i bassinet kan afvige fra vejret udenfor.';

  @override
  String get runningCarryAccessibleGelsFlasks =>
      'Løb: tag lettilgængelige geler/flasker med, eller planlæg forplejning ved poster; øv de samme produkter og timing før løbet.';

  @override
  String get servingSizesAndToleranceMust =>
      'Portionsstørrelser og tolerance skal være positive.';

  @override
  String get enterFiniteNonNegativeMeasurements =>
      'Indtast endelige, ikke-negative målinger.';

  @override
  String get targetsMustBeFiniteAnd =>
      'Mål skal være endelige og ikke-negative.';

  @override
  String get conditionsMustBeFiniteOr =>
      'Forhold skal være endelige eller ukendte.';

  @override
  String get humidityMustBeBetween0 =>
      'Luftfugtigheden skal være mellem 0 og 100 %.';

  @override
  String get noIntakeCannotIncludeFood =>
      '“Intet indtag” kan ikke indeholde mad eller drikke.';

  @override
  String get addAnItemOrConfirm =>
      'Tilføj en post, eller bekræft, at du ikke indtog noget.';

  @override
  String get eachIntakeNeedsAProduct =>
      'Hvert indtag kræver et produkt og et gyldigt tidspunkt.';

  @override
  String get quantityMustBePositive => 'Mængden skal være positiv.';

  @override
  String get thisActivityNoLongerExists =>
      'Denne aktivitet findes ikke længere.';

  @override
  String get practisedCarbohydrateToleranceMustNot =>
      'Trænet kulhydrattolerance må ikke overstige 120 g/t.';

  @override
  String get measuredSweatRateMustBe =>
      'Målt svedrate skal være positiv eller stå ukendt.';

  @override
  String get increasePractisedToleranceInNutrition =>
      'Øg trænet tolerance i ernæringsindstillingerne, før du vælger et højere mål.';

  @override
  String get fluidTargetExceedsYourMeasured =>
      'Væskemålet overstiger din målte svedrate. Gennemgå målingen eller målet.';

  @override
  String get elapsedWorkoutTimeMustBe =>
      'Forløbet træningstid skal være positiv eller stå tom.';

  @override
  String get intakeAmountsMustBeFinite =>
      'Indtagsmængder skal være endelige og ikke-negative.';

  @override
  String get selectedStrategyUnavailableChooseAnother =>
      'Den valgte strategi er ikke tilgængelig. Vælg en anden strategi eller ingen sammenligning.';

  @override
  String get recordYourWorkoutNutrition => 'Registrer din træningsernæring';

  @override
  String get addTheFoodAndFluids =>
      'Tilføj den mad og væske, du faktisk indtog, i din aktivitetshistorik.';

  @override
  String get logIntake => 'Log indtag';

  @override
  String get in30Minutes => 'Om 30 minutter';

  @override
  String get loadSuggestionsCoverStraightSets =>
      'Belastningsforslag dækker kun almindelige sæt med gentagelser.';

  @override
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  ) {
    return 'Kræver $strengthProgressionMinSessions registrerede sessioner med denne øvelse.';
  }

  @override
  String get recentHistoryIsTooOld =>
      'Den seneste historik er for gammel til et forslag.';

  @override
  String get theLastSessionDidNot =>
      'Den seneste session brugte ikke én kendt belastning.';

  @override
  String get theLoadChangedBetweenThe =>
      'Belastningen ændrede sig mellem de seneste sessioner.';

  @override
  String get notEverySetReachedThe =>
      'Ikke alle sæt nåede toppen af gentagelsesmålet.';

  @override
  String get recordEffortRirOrRpe =>
      'Registrér anstrengelse (RIR eller RPE) på sidste sæt for at få forslag.';

  @override
  String get recentSetsWereHarderThan =>
      'De seneste sæt var hårdere end tilsigtet.';

  @override
  String get thisWorkoutAlreadyHasIts =>
      'Denne træning har allerede sin egen belastning; den forbliver som indstillet.';

  @override
  String get yourRecentSetsMetThe =>
      'Dine seneste sæt opfyldte progressionsreglen. Angiv det mindste belastningstrin for dette udstyr for at gennemgå en belastning.';

  @override
  String get thisWorkoutNoLongerExists => 'Denne træning findes ikke længere.';

  @override
  String thisStrengthPlanCannotBe(Object message) {
    return 'Denne styrkeplan kan ikke læses ($message).';
  }

  @override
  String get thisStrengthPlanCannotBe2 => 'Denne styrkeplan kan ikke læses.';

  @override
  String get addAtLeastOneExercise => 'Tilføj mindst én øvelse.';

  @override
  String get thisWorkoutWasChangedElsewhere =>
      'Denne træning blev ændret et andet sted. Dine ændringer bevares; genindlæs for at se den nyere version.';

  @override
  String get thePlanThisWorkoutIs =>
      'Den plan, som denne træning sammenlignes med, kan ikke læses.';

  @override
  String get thisLogWasChangedElsewhere =>
      'Denne log blev ændret et andet sted. Dine poster bevares; genindlæs for at se den nyere version.';

  @override
  String get thisZipIsNotA =>
      'Denne ZIP er ikke en understøttet Fjelia-sikkerhedskopi.';

  @override
  String get theBackupDatabaseIsDamaged =>
      'Sikkerhedskopiens database er beskadiget.';

  @override
  String get invalidBackupData => 'Ugyldige sikkerhedskopidata.';

  @override
  String get backupTablesDoNotMatch =>
      'Sikkerhedskopiens tabeller passer ikke.';

  @override
  String get invalidBackupColumns => 'Ugyldige kolonner i sikkerhedskopien.';

  @override
  String get migratingOriginalAppBackup =>
      'Migrerer sikkerhedskopi fra den oprindelige app';

  @override
  String get theOriginalBackupIsMissing =>
      'Den oprindelige sikkerhedskopi mangler nødvendige tabeller.';

  @override
  String get backupFormatOrDatabaseVersion =>
      'Sikkerhedskopiens format eller databaseversion passer ikke.';

  @override
  String get restoringRecords => 'Gendanner poster';

  @override
  String get restoringSettings => 'Gendanner indstillinger';

  @override
  String get restoreComplete => 'Gendannelse fuldført';

  @override
  String get effortMustBeANumber => 'Anstrengelse skal være et tal.';

  @override
  String get theDurationEstimateMustBe =>
      'Varighedsestimatet skal være positivt.';

  @override
  String get restCannotBeNegative => 'Hvilen kan ikke være negativ.';

  @override
  String get enterTheRepetitionsDoneThe =>
      'Indtast de udførte gentagelser; planen har et interval.';

  @override
  String get enterTheLoadThePlan => 'Indtast belastningen; planen har ingen.';

  @override
  String get enterTheResistanceThePlan =>
      'Indtast modstanden; planen har ingen.';

  @override
  String get poorSensorContact => 'Dårlig sensorkontakt';

  @override
  String get moreThan25FromLocal => 'Mere end 25 % fra den lokale median';

  @override
  String get workoutNutrition => 'Træningsernæring';

  @override
  String get postWorkoutFoodAndFluid =>
      'Påmindelse om mad- og væskelog efter træning';

  @override
  String get postTrainingHrvMeasurementReminder =>
      'Påmindelse om HRV-måling efter træning';

  @override
  String get rirRunsFrom0To => 'RIR går fra 0 til 10+.';

  @override
  String get rpeRunsFrom1To => 'RPE går fra 1 til 10.';

  @override
  String get repetitionsCannotBeNegative =>
      'Gentagelser kan ikke være negative.';

  @override
  String get timedWorkMustBeLonger =>
      'Tidsbaseret arbejde skal vare længere end nul sekunder.';

  @override
  String get chooseRepetitionsOrTimedWork =>
      'Vælg gentagelser eller tidsbaseret arbejde, ikke begge.';

  @override
  String get loadMustBeAFinite =>
      'Belastningen skal være et endeligt, ikke-negativt tal.';

  @override
  String get durationCannotBeNegative => 'Varigheden kan ikke være negativ.';

  @override
  String get hrTimeline => 'Pulsforløb';

  @override
  String get dayTrainingLoad => 'Daglig træningsbelastning';

  @override
  String get weekdayComparison => 'Ugedagssammenligning';

  @override
  String get weeklyTrainingLoad => 'Ugentlig træningsbelastning';

  @override
  String get zonePolarization => 'Zonepolarisering';

  @override
  String get elevationOverview => 'Højdeoversigt';

  @override
  String get trainingMonitor => 'Træningsmonitor';

  @override
  String get formAtlCtlTsb => 'ATL / CTL / TSB-form';

  @override
  String get trainingPlanProgress => 'Fremdrift i træningsplanen';

  @override
  String get rhrSleep => 'Hvilepuls under søvn';

  @override
  String get hrvSleep => 'HRV under søvn';

  @override
  String get spo2Sleep => 'SpO₂ under søvn';

  @override
  String get respRate => 'Respirationsfrekvens';

  @override
  String get stress => 'Stress';

  @override
  String get skinTemp => 'Hudtemperatur';

  @override
  String get steps => 'Skridt';

  @override
  String get tonightsSleep => 'Nattens søvn';

  @override
  String get activityLog => 'Aktivitetslog';

  @override
  String get activityLog2 => 'Aktivitetslog';

  @override
  String get history2 => 'HISTORIK';

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
  String get heatAcclimation2 => 'VARMETILVÆNNING';

  @override
  String score(Object score) {
    return '$score%';
  }

  @override
  String get elevation => 'HØJDEMETER';

  @override
  String get t12WeekHistory => '12-UGERS HISTORIK';

  @override
  String get zonePolarization2 => 'ZONEPOLARISERING';

  @override
  String get t5WeekHistory => '5-UGERS HISTORIK';

  @override
  String get easy => 'LET %';

  @override
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded) {
    return '$withZones af $recorded aktiviteter med pulszonedata';
  }

  @override
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples) {
    return '$fromSamples rekonstrueret fra registrerede pulsmålinger';
  }

  @override
  String get easyZ12ModerateZ3 => 'Let: Z1–2 · Moderat: Z3 · Hård: Z4–5';

  @override
  String get activitiesWithoutHrZoneData =>
      'Aktiviteter uden pulszonedata udelades fra procenterne.';

  @override
  String avgAverageUnit(Object average, Object unit) {
    return 'GNS $average $unit';
  }

  @override
  String get weekdayComparison2 => 'UGEDAGSSAMMENLIGNING';

  @override
  String get trainingPlanProgress2 => 'FREMDRIFT I TRÆNINGSPLANEN';

  @override
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  ) {
    return 'Uge $currentWeek / $durationInWeeks';
  }

  @override
  String get t30MinTimeTrialLt2 => '30-MIN TIDSKØRSEL – LT2';

  @override
  String get run30MinutesAtThe =>
      'Løb 30 minutter med den hårdeste indsats, du kan holde – kontrolleret, ikke sprint. Byg op i indsatsen; start ikke for hurtigt. Gennemsnitstempo og puls de sidste 20 minutter er din LT2.';

  @override
  String get recordAsANormalOutdoor =>
      'Registrér det som en almindelig udendørs løbetur. Start dit ur, notér tiden, og løb 30 min med løbsindsats.';

  @override
  String get t50MinTotalFlatCourse =>
      '~50 min i alt · flad rute · ikke efter hård træning';

  @override
  String get doNotStartTooFast =>
      'Start ikke for hurtigt. Sigt efter jævne mellemtider.';

  @override
  String get theAppAveragesHrAnd =>
      'Appen beregner gennemsnittet af puls og tempo over testens sidste 20 minutter, efter opvarmningen og de første 10 minutter. Vælg den registrerede aktivitet under Beregn.';

  @override
  String get lt2Pace => 'LT2-TEMPO';

  @override
  String get activityRunningEnoughTimeFor =>
      'Aktivitet (løb, nok tid til opvarmning + 30 min, med puls)';

  @override
  String get selectTheTtActivity => 'Vælg TT-aktiviteten';

  @override
  String nameStartdate(Object name, Object startDate) {
    return '$name · $startDate';
  }

  @override
  String get warmUpBeforeTt => 'Opvarmning før testen';

  @override
  String roundMin(Object round) {
    return '$round min';
  }

  @override
  String get clearResults => 'Ryd resultater';

  @override
  String get heartRate2 => 'PULS';

  @override
  String get paceSecKmLowerIs => 'Tempo (sek/km – lavere er hurtigere)';

  @override
  String get thresholdsFitnessTests => 'Tærskler og konditionstests';

  @override
  String get lt1 => 'LT1';

  @override
  String get lt2 => 'LT2';

  @override
  String get voPace => 'VO₂-tempo';

  @override
  String get ftp => 'FTP';

  @override
  String get setFtpManually => 'Angiv FTP manuelt';

  @override
  String get calculateFromAnActivity => 'Beregn ud fra en aktivitet';

  @override
  String get setFtp => 'Angiv FTP';

  @override
  String get ftpWatts => 'FTP (watt)';

  @override
  String get ftpCyclingThresholdPower => 'FTP – TÆRSKELEFFEKT I CYKLING';

  @override
  String get ftpHistory => 'FTP-HISTORIK';

  @override
  String get updateFromActivity => 'OPDATÉR FRA AKTIVITET';

  @override
  String get tapAnActivityFtpBest =>
      'Tryk på en aktivitet – FTP = bedste 20-min-effekt × 0,95';

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
      'Ingen ture med 20 minutters sammenhængende effektdata.';

  @override
  String get enterFtpManually => 'Indtast FTP manuelt';

  @override
  String get selectTheTestActivity => 'Vælg testaktiviteten';

  @override
  String get formAtlCtlTsb2 => 'FORM · ATL / CTL / TSB';

  @override
  String get closeTrainingFormFullscreen => 'Luk træningsformen i fuld skærm';

  @override
  String get expandTrainingForm => 'Udvid træningsformen';

  @override
  String get calculatedFromTheFirstAvailable =>
      'Beregnet fra den første tilgængelige belastningsregistrering. Dage uden registreret belastning tæller som nul; tidligere træning er ukendt.';

  @override
  String get trainingMonitor2 => 'TRÆNINGSMONITOR';

  @override
  String get pfitzingerZones => 'PFITZINGER-ZONER';

  @override
  String get cyclingPowerZones => 'EFFEKTZONER I CYKLING';

  @override
  String znumber(Object number) {
    return 'Z$number';
  }

  @override
  String paceHrDescription(Object pace, Object hr, Object description) {
    return '$pace · $hr\n$description';
  }

  @override
  String get weeklyTrainingLoad2 => 'UGENTLIG TRÆNINGSBELASTNING';

  @override
  String get prevWeek => 'FORRIGE UGE';

  @override
  String get bySport => 'EFTER SPORTSGREN';

  @override
  String get noActivitiesThisWeek => 'Ingen aktiviteter denne uge';

  @override
  String garminWorkoutScheduleddate(Object scheduledDate) {
    return 'Garmin-træning · $scheduledDate';
  }

  @override
  String get yourNote => 'Din note';

  @override
  String get askAiCoach => 'Spørg AI-træneren';

  @override
  String get aiSettings => 'AI-indstillinger';

  @override
  String get askYourCoach => 'Spørg din træner …';

  @override
  String get sendMessage => 'Send besked';

  @override
  String get sendFeedbackOrReportA => 'Send feedback eller rapportér en fejl';

  @override
  String get addMeasurement2 => 'Tilføj måling';

  @override
  String get syncLabel2 => 'Synkroniser';

  @override
  String get syncToday => 'Synkroniser i dag';

  @override
  String get fullSync1Year => 'Fuld synkronisering · 1 år';

  @override
  String get fullSyncComplete => 'Fuld synkronisering · Fuldført';

  @override
  String get syncingYourData => 'Synkroniserer dine data …';

  @override
  String lLeftkgRRightkgKg2(Object leftKg, Object rightKg) {
    return 'V $leftKg  H $rightKg kg';
  }

  @override
  String weightKgFatBodyfatMuscle(
    Object weight,
    Object bodyFat,
    Object muscleMass,
  ) {
    return '$weight kg · Fedt $bodyFat % · Muskler $muscleMass kg';
  }

  @override
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase) {
    return '$title, $sport, $toLowerCase';
  }

  @override
  String get weatherUnavailableTapToRetry =>
      'Vejr utilgængeligt · Tryk for at prøve igen';

  @override
  String get weatherSetYourLocation => 'Vejr · Angiv din placering';

  @override
  String get t7DayForecast => '7-DAGES PROGNOSE';

  @override
  String get minMax => 'min/maks';

  @override
  String get rainMm2 => 'regn mm';

  @override
  String get uvMax => 'UV maks';

  @override
  String get kmH => 'km/t';

  @override
  String alt(Object alt) {
    return '→ $alt';
  }

  @override
  String raceGoalsLength(Object length) {
    return 'Løbsmål · $length';
  }

  @override
  String gWk(Object g) {
    return '$g uger';
  }

  @override
  String weeks(Object weeks) {
    return '$weeks';
  }

  @override
  String get weeks2 => 'uger';

  @override
  String get upcoming => 'KOMMENDE';

  @override
  String lengthMoreDays(Object length) {
    return '+ $length dage mere';
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
  String get plannedCompletedSkipped =>
      '○ Planlagt   ● Gennemført   ✕ Sprunget over';

  @override
  String get heartRate3 => 'Puls';

  @override
  String get watts => 'Watt';

  @override
  String theStepsAddUpTo(Object total, Object plannedDurationMin) {
    return 'Trinene summerer til $total; planen tæller $plannedDurationMin min.';
  }

  @override
  String get typicalSplitForThisKind =>
      'Typisk fordeling for denne type session; ingen trin at beregne den ud fra.';

  @override
  String labelGetsEachExerciseWith(Object label) {
    return '$label får hver øvelse med sæt, gentagelser og belastning. Gentagelsesintervaller, anstrengelse og tempo bliver i Fjelia.';
  }

  @override
  String get markAsRest => 'Markér som hvile';

  @override
  String get restoreWorkout => 'Gendan træning';

  @override
  String get skipThisWorkout => 'Springe denne træning over?';

  @override
  String get previousWeek => 'Forrige uge';

  @override
  String get backToThisWeek => 'Tilbage til denne uge';

  @override
  String get thisWeek => 'Denne uge';

  @override
  String get nextWeek => 'Næste uge';

  @override
  String get today2 => 'I DAG';

  @override
  String get route => 'RUTE';

  @override
  String get feedback => 'Feedback';

  @override
  String get plannedWorkout => 'Planlagt træning';

  @override
  String get delete => 'Slet';

  @override
  String get chatAi => 'AI-chat';

  @override
  String get trainingLoad => 'Træningsbelastning';

  @override
  String get dayTrainingLoad2 => 'DAGLIG TRÆNINGSBELASTNING';

  @override
  String get trimp => ' TRIMP';

  @override
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter) {
    return '$scoreBefore → $scoreAfter';
  }

  @override
  String get temperatureOverTime => 'TEMPERATUR OVER TID';

  @override
  String roundh(Object round) {
    return '${round}h';
  }

  @override
  String get timeInHrZones => 'Tid i pulszoner';

  @override
  String get route2 => 'Rute';

  @override
  String get start => 'Start';

  @override
  String get gpx => 'GPX';

  @override
  String touppercasesubstringBriefing(Object toUpperCase, Object substring) {
    return '$toUpperCase$substring-briefing';
  }

  @override
  String get chatWithAiAboutThis => 'Chat med AI om denne briefing';

  @override
  String get whyThisRecommendation => 'Hvorfor denne anbefaling?';

  @override
  String titleDateLabel(Object title, Object date, Object label) {
    return '$title, $date, $label';
  }

  @override
  String get previousDay => 'Forrige dag';

  @override
  String get nextDay => 'Næste dag';

  @override
  String get updating => 'Opdaterer';

  @override
  String get resting => 'I HVILE';

  @override
  String get noTimedReadings => 'Ingen tidsstemplede målinger';

  @override
  String get avg => 'GNS';

  @override
  String get peak => 'TOP';

  @override
  String tolocalRoundmin(Object toLocal, Object round) {
    return '$toLocal · ${round}min';
  }

  @override
  String avgheartrateBpmAvg(Object avgHeartRate) {
    return '$avgHeartRate bpm gns.';
  }

  @override
  String get timeWeightedAverageOverRecorded =>
      'Tidsvægtet gennemsnit over registrerede perioder. Huller uden målinger er udeladt.';

  @override
  String get previousHeartRatePeriod => 'Forrige pulsperiode';

  @override
  String get nextHeartRatePeriod => 'Næste pulsperiode';

  @override
  String get avgHr => 'Gns. puls';

  @override
  String get restingHr => 'Hvilepuls';

  @override
  String get both => 'Begge';

  @override
  String averagelabelFixedMs(Object averageLabel, Object fixed) {
    return '$averageLabel $fixed ms';
  }

  @override
  String get measureWithPolarH10 => 'Mål med Polar H10';

  @override
  String get ms => 'ms';

  @override
  String get noWorkoutInThisPeriod =>
      'Ingen træning i denne periode har et sammenligneligt før/efter-par.';

  @override
  String textEachWorkoutCountsOnce(Object text) {
    return '$text. Hver træning tæller én gang; dette beskriver dine par, det scorer dem ikke.';
  }

  @override
  String get workoutFinished => 'Træning færdig?';

  @override
  String get yourWorkoutIsNotIn =>
      'Din træning er ikke i Fjelia endnu. Hvis den er slut, så sig hvornår, så kan påmindelsen følge dens faktiske slutning. Ellers vises den, når dit ur synkroniserer.';

  @override
  String get workoutFinished2 => 'Træning færdig';

  @override
  String get theWorkoutMustStartAfter =>
      'Træningen skal starte efter målingen og slutte efter sin start, ikke i fremtiden.';

  @override
  String daysDAvg(Object days) {
    return '$days D gns.';
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
  String get previousPeriod => 'Forrige periode';

  @override
  String get nextPeriod => 'Næste periode';

  @override
  String get overnightHrvReflectsRecoveryCompare =>
      'HRV om natten afspejler restitution. Sammenlign dine målinger med din egen baseline over tid.';

  @override
  String get moveThisWorkout => 'FLYT DENNE TRÆNING';

  @override
  String get pickDate => 'Vælg dato';

  @override
  String movedFromMovedfrom(Object movedFrom) {
    return 'Flyttet fra $movedFrom';
  }

  @override
  String get hrvAroundThisWorkout => 'HRV omkring denne træning';

  @override
  String get measureAfterTraining => 'Mål efter træning';

  @override
  String get measureAgain => 'Mål igen';

  @override
  String get explainWithAi => 'Forklar med AI';

  @override
  String beforeEndedPregapAheadOf(Object preGap) {
    return 'Før sluttede $preGap før start.';
  }

  @override
  String lengthFurtherMeasurementSAfter(Object length) {
    return '$length yderligere måling(er) efter denne træning bevares som ekstra observationer.';
  }

  @override
  String get noHrvMeasurementRecordedAround =>
      'Ingen HRV-måling registreret omkring denne træning.';

  @override
  String get measureHrv => 'Mål HRV';

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
      'En beskrivelse af dette par, ikke en score for træningen.';

  @override
  String notEnoughComparableWorkoutsYet(Object eligible, Object need) {
    return 'Endnu ikke nok sammenlignelige træninger, $eligible af $need.';
  }

  @override
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need) {
    return 'Endnu ikke nok sammenlignelige træninger ($eligible af $need).';
  }

  @override
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  ) {
    return 'Dine $eligible lignende træninger · $toLocal–$toLocal2';
  }

  @override
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  ) {
    return 'Midterste halvdel $q1Ms til $q3Ms ms · median $medianMs ms · denne træning $delta ms';
  }

  @override
  String rpeI(Object i) {
    return 'RPE $i';
  }

  @override
  String get easy2 => 'let';

  @override
  String get allOut => 'Alt hvad du har';

  @override
  String workoutProfileDescription(Object description) {
    return 'Træningsprofil: $description';
  }

  @override
  String get noActivitiesInThisPeriod => 'Ingen aktiviteter i denne periode';

  @override
  String get enableHeatAcclimationInTraining =>
      'Slå varmetilvænning til i træningsindstillingerne.';

  @override
  String get noElevationThisWeek => 'Ingen højdemeter denne uge';

  @override
  String get noActivitiesSynced => 'Ingen aktiviteter synkroniseret';

  @override
  String get noHrZoneData => 'Ingen pulszonedata';

  @override
  String get easyJogGetHrElevated => 'Let løbetur – få pulsen op, løse ben';

  @override
  String get fastestSustainablePaceLikeA =>
      'Hurtigste holdbare tempo – som et 30-min-løb';

  @override
  String get walkCardiacRecovery => 'Gang – hjerterestitution';

  @override
  String get selectTheTtActivityFirst => 'Vælg først TT-aktiviteten.';

  @override
  String get calculating => 'Beregner …';

  @override
  String get calculateLt2 => 'Beregn LT2';

  @override
  String get enterFtpBetween30And => 'Indtast en FTP mellem 30 og 1000 W.';

  @override
  String get aerobicThreshold => 'Aerob tærskel';

  @override
  String get functionalThresholdPower => 'Funktionel tærskeleffekt';

  @override
  String get estimated => 'Estimeret';

  @override
  String get afterWarmingUpRunFive =>
      'Løb efter opvarmningen fem minutter med din hurtigste holdbare indsats. Registrér løbet med fart- eller distancedata.';

  @override
  String get recordAtLeast40Minutes =>
      'Registrér mindst 40 minutters jævnt løb med konstant indsats. Testen sammenligner pulsen i hver halvdel for at estimere aerob drift.';

  @override
  String get theFastestFiveMinuteWindow =>
      'Det hurtigste fem-minutters vindue giver dit VO2max-tempo.';

  @override
  String get noResultYet => 'Intet resultat endnu';

  @override
  String get calculateVo2maxPace => 'Beregn VO2max-tempo';

  @override
  String get calculateLt1 => 'Beregn LT1';

  @override
  String get loading2 => 'Indlæser';

  @override
  String get unavailable => 'Utilgængelig';

  @override
  String get noTrainingHistory => 'Ingen træningshistorik';

  @override
  String get fitnessCtl => 'Fitness (CTL)';

  @override
  String get fatigueAtl => 'Træthed (ATL)';

  @override
  String get formTsb => 'Dagsform (TSB)';

  @override
  String get noHistory => 'Ingen historik';

  @override
  String get fresh => 'Frisk';

  @override
  String get optimal => 'Optimal';

  @override
  String get neutral => 'Neutral';

  @override
  String get tired => 'Træt';

  @override
  String get veryFatigued => 'Meget træt';

  @override
  String get garminRunningVo2max => 'Garmin VO2max løb';

  @override
  String get garminCyclingVo2max => 'Garmin VO2max cykling';

  @override
  String get aerobicThreshold2 => 'Aerob tærskel';

  @override
  String driftDriftAt(Object drift, Object at) {
    return 'Drift $drift % · $at';
  }

  @override
  String get activityHours => 'Aktivitetstimer';

  @override
  String get activityKm => 'Aktivitets-km';

  @override
  String get tap5MinuteMaxTest => 'Tryk · 5-min maksimaltest';

  @override
  String get setFtpToCalculatePower => 'Angiv FTP for at beregne effektzoner';

  @override
  String get cyclingPowerZones2 => 'Effektzoner i cykling';

  @override
  String get pfitzingerZones2 => 'Pfitzinger-zoner';

  @override
  String get completeAnLt2TestTo =>
      'Gennemfør en LT2-test for at beregne løbezoner.';

  @override
  String get setFtpToCalculatePower2 => 'Angiv FTP for at beregne effektzoner.';

  @override
  String get endurance => 'Udholdenhed';

  @override
  String get threshold => 'Tærskel';

  @override
  String get anaerobic => 'Anaerob';

  @override
  String get whatExplainsThisRise => 'Hvad forklarer denne stigning?';

  @override
  String get whatExplainsThisDrop => 'Hvad forklarer dette fald';

  @override
  String get whatExplainsThisRise2 => 'Hvad forklarer denne stigning';

  @override
  String get editsAreKeptInFjelia =>
      'Ændringer gemmes i Fjelia som en lokal kopi for denne dato. Træningen hos Garmin ændres ikke.';

  @override
  String get howDoIExecuteThis => 'Hvordan gennemfører jeg denne træning?';

  @override
  String shareHealthContextWithName(Object name) {
    return 'Dele sundhedskontekst med $name?';
  }

  @override
  String get yourMessageAndAHealth =>
      'Din besked og et sundheds-/træningsresumé sendes til denne cloud-AI-udbyder. Navne og GPS udelades fra det genererede resumé.';

  @override
  String get couldNotGetAReply =>
      'Kunne ikke få et svar. Tjek dine AI-indstillinger, og prøv igen.';

  @override
  String get askAboutYourRecoveryTraining =>
      'Spørg om din restitution, træning eller dagens plan.';

  @override
  String get noSyncYet => 'Endnu ikke synkroniseret';

  @override
  String lastSyncLastContext(Object last, Object context) {
    return 'Seneste synkronisering: $last $context';
  }

  @override
  String get seasonWithTradeOffs => 'Sæson: med kompromisser';

  @override
  String get seasonNeedsYourDecision => 'Sæson: kræver din beslutning';

  @override
  String get seasonCannotBeCombined => 'Sæson: kan ikke kombineres';

  @override
  String get seasonProvisional => 'Sæson: foreløbig';

  @override
  String get season => 'Sæson';

  @override
  String get allGoalsFit => 'Alle mål passer.';

  @override
  String goalTargetfinishsecondsgoal(Object targetFinishSeconds, Object goal) {
    return 'Mål $targetFinishSeconds$goal';
  }

  @override
  String estEstimateestimate2(Object estimate, Object estimate2) {
    return 'Est. $estimate$estimate2';
  }

  @override
  String doneDoneby(Object doneBy) {
    return 'Færdig · $doneBy';
  }

  @override
  String garminWorkoutWorkout(Object workout) {
    return 'Garmin-træning · $workout';
  }

  @override
  String get moveAnyway => 'Flytte alligevel?';

  @override
  String get wattsNeedYourFtpSet =>
      'Watt kræver din FTP: angiv den under Belastning, Tærskler.';

  @override
  String get mainTargetInWattsFrom =>
      'Hovedmål i watt ud fra din FTP, puls som rettesnor.';

  @override
  String get mainTargetHeartRateWatts =>
      'Hovedmål puls; watt er ikke angivet på uret.';

  @override
  String get taperPhase => 'Nedtrapningsfase';

  @override
  String get recoverySession => 'Restitutionssession';

  @override
  String get closeToYourEvent => 'Tæt på dit arrangement';

  @override
  String get noWorkoutStructureAvailable =>
      'Ingen træningsstruktur tilgængelig.';

  @override
  String get aerobic => 'Aerob';

  @override
  String get pushAgainToUpdateYour =>
      'Send igen for at opdatere dit urs kalender.';

  @override
  String workoutSentToLabel(Object label) {
    return 'Træning sendt til $label';
  }

  @override
  String get updating2 => 'Opdaterer …';

  @override
  String pushToLabel(Object label) {
    return 'Send til $label';
  }

  @override
  String shareExerciseListForLabel(Object label) {
    return 'Del øvelsesliste til $label';
  }

  @override
  String shareWorkoutForLabel(Object label) {
    return 'Del træning til $label';
  }

  @override
  String get whyNothingIsAddedTo =>
      'Hvorfor? Der tilføjes intet for at udfylde det.';

  @override
  String get workout => 'Træning';

  @override
  String get recordedActivityLinkedToThis =>
      'Registreret aktivitet knyttet til denne træning';

  @override
  String get matchedToTheRecordedWorkout =>
      'Matchet med starten på den registrerede træning';

  @override
  String get matchedByWorkoutNameSport =>
      'Matchet efter træningsnavn, sportsgren og dato';

  @override
  String get matchedBySportDateAnd =>
      'Matchet efter sportsgren, dato og varighed';

  @override
  String planPlannedminutesMin(Object plannedMinutes) {
    return 'Plan $plannedMinutes min';
  }

  @override
  String get maxHr => 'Maks. puls';

  @override
  String get trainingLoad2 => 'Træningsbelastning';

  @override
  String get active => 'Aktiv';

  @override
  String get avgPace => 'Gns. tempo';

  @override
  String get avgSpeed => 'Gns. fart';

  @override
  String get avgPower => 'Gns. effekt';

  @override
  String get elevation2 => 'Højdemeter';

  @override
  String get altitude => 'Højde';

  @override
  String get explainMyHrvBeforeAnd =>
      'Forklar min HRV før og efter denne træning. Hvad er sammenligneligt, hvad er ikke, og hvad er stadig ukendt?';

  @override
  String get deleteActivity => 'Slette aktiviteten?';

  @override
  String get removeThisActivityFromThe =>
      'Fjerne denne aktivitet fra den lokale historik? En senere synkronisering fra udbyderen kan importere den igen.';

  @override
  String get howDidThisSessionGo =>
      'Hvordan gik denne session, og hvad betyder den for mine næste dage?';

  @override
  String currentFixedFixed2(Object fixed, Object fixed2) {
    return 'Nuværende $fixed, $fixed2';
  }

  @override
  String get setUpInTrainingSettings => 'Opsæt i træningsindstillingerne';

  @override
  String get couldNotLoadHeatData =>
      'Kunne ikke indlæse varmedata – tryk for detaljer';

  @override
  String get loadingHeatHistory => 'Indlæser varmehistorik …';

  @override
  String get noHeatDataYet => 'Ingen varmedata endnu';

  @override
  String optimalLowHigh(Object low, Object high) {
    return 'Optimalt $low–$high';
  }

  @override
  String optimalLowHighTrimp(Object low, Object high) {
    return 'Optimalt: $low–$high TRIMP';
  }

  @override
  String get targetUnavailableSyncTrainingHistory =>
      'Mål utilgængeligt – synkroniser træningshistorikken';

  @override
  String get workoutQualifiedForHeatAccumulation =>
      'Træningen tællede med i varmeakkumuleringen.';

  @override
  String get workoutDidNotAddHeat =>
      'Træningen tilføjede ikke varmeakkumulering.';

  @override
  String get performanceTime => 'Præstation / Tid';

  @override
  String get performanceDistance => 'Præstation / Distance';

  @override
  String get noRecordedRoute => 'Ingen registreret rute';

  @override
  String get zoomIn => 'Zoom ind';

  @override
  String get zoomOut => 'Zoom ud';

  @override
  String get fitRoute => 'Tilpas rute';

  @override
  String get fullscreenMap => 'Kort i fuld skærm';

  @override
  String get openstreetmapContributors2 => 'OpenStreetMap-bidragydere';

  @override
  String get appleIntelligenceIsUnavailableShowing =>
      'Apple Intelligence er ikke tilgængelig. Viser et resumé uden AI.';

  @override
  String get generateAiBriefing => 'Generere AI-briefing?';

  @override
  String get retryAiBriefing => 'Prøv AI-briefing igen';

  @override
  String get generateBriefing => 'Generer briefing';

  @override
  String discussThisBriefingWithMe(Object text) {
    return 'Diskutér denne briefing med mig, og foreslå den bedste næste handling.\n\n$text';
  }

  @override
  String whyThisRecommendationWhichOf(Object text) {
    return 'Hvorfor denne anbefaling? Hvilke af mine tal og hvilke huller i data førte til den, og hvad ville ændre den?\n\n$text';
  }

  @override
  String get avg2 => 'Gns.';

  @override
  String get peak2 => 'Top';

  @override
  String get notEnoughContinuousReadingsFor =>
      'Ikke nok sammenhængende målinger til et gennemsnit.';

  @override
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  ) {
    return 'Registreret dækning: $inHours t $inMinutes min · tidsvægtet gennemsnit';
  }

  @override
  String get lying => 'Liggende';

  @override
  String get noHrvReadingsInThis => 'Ingen HRV-målinger i denne periode';

  @override
  String get overnightHrvComesFromYour =>
      'HRV om natten kommer fra dit ur, spotmålinger fra Polar H10 (RMSSD). Metoderne er forskellige: sammenlign tendenser, ikke enkeltværdier.';

  @override
  String get noReadings => 'Ingen målinger';

  @override
  String get whenDidTheWorkoutStart => 'Hvornår startede træningen?';

  @override
  String get whenDidItEnd => 'Hvornår sluttede den?';

  @override
  String get last3Months => 'Seneste 3 måneder';

  @override
  String get lastYear => 'Seneste år';

  @override
  String lastDaysDays(Object days) {
    return 'Seneste $days dage';
  }

  @override
  String nowOnCurrentTapA(Object current) {
    return 'Nu på $current. Tryk på en dag, eller træk træningen hen på en. Trinene forbliver som de er.';
  }

  @override
  String get monthView => 'Månedsvisning';

  @override
  String get syncing => 'Synkroniserer';

  @override
  String get trendUnavailable => 'Tendens utilgængelig';

  @override
  String get stable => 'Stabil';

  @override
  String get increasing => 'Stigende';

  @override
  String get decreasing => 'Faldende';

  @override
  String get unclear => 'Uklar';

  @override
  String get notComparable => 'Ikke sammenlignelig';

  @override
  String get waitingForAfter => 'Venter på efter';

  @override
  String get afterOnly => 'Kun efter';

  @override
  String get waitingForTheActualWorkout =>
      'Venter på træningens faktiske slutning.';

  @override
  String reminderAroundTolocal(Object toLocal) {
    return 'Påmindelse omkring $toLocal';
  }

  @override
  String get reminderIsDueMeasureWhen =>
      'Påmindelsen er klar. Mål, når du er klar.';

  @override
  String get thisReminderIsNoLonger =>
      'Denne påmindelse er ikke længere aktuel. Åbn træningen for at se dine målinger.';

  @override
  String beforeFixedMilliseconds(Object fixed) {
    return 'Før $fixed millisekunder. ';
  }

  @override
  String afterFixedMilliseconds(Object fixed) {
    return 'Efter $fixed millisekunder';
  }

  @override
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  ) {
    return 'Ændring $deltaMs millisekunder, $deltaPercent procent.';
  }

  @override
  String get noPreTrainingMeasurementRecorded =>
      'Ingen måling før træning registreret.';

  @override
  String get notMeasuredYet => 'Endnu ikke målt';

  @override
  String leftOutOfTheComparison(Object excludedTotal, Object c) {
    return 'Udeladt fra sammenligningen: $excludedTotal træninger ($c).';
  }

  @override
  String get notFromThisWorkout => 'Ikke fra denne træning';

  @override
  String get useAsBefore => 'Brug som før';

  @override
  String get useAsAfter => 'Brug som efter';

  @override
  String get beforeNotMeasured => 'Før · ikke målt';

  @override
  String beforeTolocal(Object toLocal) {
    return 'Før · $toLocal';
  }

  @override
  String workoutWorkouttext(Object workoutText) {
    return 'Træning · $workoutText';
  }

  @override
  String get afterNotMeasuredYet => 'Efter · endnu ikke målt';

  @override
  String afterTolocal(Object toLocal) {
    return 'Efter · $toLocal';
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
    return 'Dine lignende træninger ($eligible, $toLocal–$toLocal2): median $medianMs ms, midterste halvdel $q1Ms til $q3Ms ms.';
  }

  @override
  String get howHardDidItFeel => 'Hvor hårdt føltes det? (RPE)';

  @override
  String get loadMetric => 'Belastning';

  @override
  String get clearAction => 'Ryd';

  @override
  String get routeFinish => 'Mål';

  @override
  String get month2 => 'MÅNED';

  @override
  String get week2 => 'UGE';

  @override
  String get quarter => 'KVARTAL';

  @override
  String get year => 'ÅR';

  @override
  String get easy3 => 'LET';

  @override
  String get mod => 'MOD.';

  @override
  String get hard => 'HÅRD';

  @override
  String get protocol => 'PROTOKOL';

  @override
  String get calculate => 'BEREGN';

  @override
  String get warmUp => 'OPVARMNING';

  @override
  String get coolDown => 'NEDKØLING';

  @override
  String get ftpCycling => 'FTP cykling';

  @override
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg) {
    return 'FTP $ftpWatts W · $wattsPerKg W/kg';
  }

  @override
  String get thisWeekSoFar => 'DENNE UGE · INDTIL NU';

  @override
  String get duration2 => 'VARIGHED';

  @override
  String get distance2 => 'DISTANCE';

  @override
  String get sport2 => 'SPORTSGREN';

  @override
  String get repeatSets => 'GENTAGELSESSÆT';

  @override
  String get aboutThisWorkout => 'OM DENNE TRÆNING';

  @override
  String get workoutStructure => 'TRÆNINGSSTRUKTUR';

  @override
  String get health2 => 'SUNDHED';

  @override
  String get high2 => 'HØJ';

  @override
  String get elevated => 'FORHØJET';

  @override
  String get normal => 'NORMAL';

  @override
  String get tomorrow => 'I MORGEN';

  @override
  String get skipped2 => 'SPRUNGET OVER';

  @override
  String get weeklyPlan => 'UGEPLAN';

  @override
  String get activityLog3 => 'AKTIVITETSLOG';

  @override
  String skippedTouppercase(Object toUpperCase) {
    return 'SPRUNGET OVER · $toUpperCase';
  }

  @override
  String get primaryZone => 'HOVEDZONE';

  @override
  String get coachingCues => 'TRÆNERTIPS';

  @override
  String get targets => 'MÅL';

  @override
  String get adaptation => 'TILPASNING';

  @override
  String get done2 => 'FÆRDIG';

  @override
  String get notRecorded2 => 'IKKE REGISTRERET';

  @override
  String get planned => 'PLANLAGT';

  @override
  String get extra => 'EKSTRA';

  @override
  String get optimal2 => 'OPTIMAL';

  @override
  String get qualified => 'KVALIFICERET';

  @override
  String get temp => 'TEMP.';

  @override
  String get humidity2 => 'LUFTFUGTIGHED';

  @override
  String get pressure => 'LUFTTRYK';

  @override
  String get wetBulb => 'VÅD TEMP.';

  @override
  String get paceMinKm => 'Tempo (min/km)';

  @override
  String get speedKmH => 'Fart (km/t)';

  @override
  String get elevationM => 'Højde (m)';

  @override
  String get powerW => 'EFFEKT (W)';

  @override
  String get performanceTime2 => 'PRÆSTATION / TID';

  @override
  String get performanceDistance2 => 'PRÆSTATION / DISTANCE';

  @override
  String get load2 => 'BELASTNING';

  @override
  String get day2 => 'DAG';

  @override
  String get allTime => 'SAMLET';

  @override
  String get hrvAroundThisWorkout2 => 'HRV omkring denne træning. ';

  @override
  String get lowReserve => 'LAV RESERVE';

  @override
  String get goodReserve => 'GOD RESERVE';

  @override
  String latestReadingAtTolocal(Object toLocal) {
    return 'Seneste måling kl. $toLocal';
  }

  @override
  String get weeklyAvg => 'UGEGENNEMSNIT';

  @override
  String get monthlyAvg => 'MÅNEDSGENNEMSNIT';

  @override
  String get systolic2 => 'SYSTOLISK';

  @override
  String get diastolic2 => 'DIASTOLISK';

  @override
  String get hourlyVariation => 'TIMEVARIATION';

  @override
  String get dailyVariation => 'DØGNVARIATION';

  @override
  String get sys2 => 'SYS';

  @override
  String get dia => 'DIA';

  @override
  String get bluetoothDevices => 'BLUETOOTH-ENHEDER';

  @override
  String get accountsServices => 'KONTI OG TJENESTER';

  @override
  String get flowLoginOptional => 'FLOW-LOGIN (VALGFRIT)';

  @override
  String get polarFlowLogin => 'POLAR FLOW-LOGIN';

  @override
  String get raceGoal => 'LØBSMÅL';

  @override
  String get experienceLevel => 'ERFARINGSNIVEAU';

  @override
  String get weeklySchedule2 => 'UGEPLAN';

  @override
  String get sessionsPerDay2 => 'SESSIONER PR. DAG';

  @override
  String get aboutYou => 'OM DIG';

  @override
  String get yourActivities2 => 'DINE AKTIVITETER';

  @override
  String latestReadingAtTimestamp(Object timestamp) {
    return 'Seneste måling kl. $timestamp';
  }

  @override
  String get poorSleep => 'DÅRLIG SØVN';

  @override
  String get fairSleep => 'MIDDEL SØVN';

  @override
  String get goodSleep => 'GOD SØVN';

  @override
  String get hoursOfSleep => 'TIMERS SØVN';

  @override
  String get sleepNeeded => 'NØDVENDIG SØVN';

  @override
  String get deepSleep => 'DYB SØVN';

  @override
  String get exercises2 => 'ØVELSER';

  @override
  String get strengthSummary => 'STYRKERESUMÉ';

  @override
  String get strengthDraft => 'STYRKE · KLADDE';

  @override
  String get strengthFinishedWithGaps => 'STYRKE · AFSLUTTET MED HULLER';

  @override
  String get strength2 => 'STYRKE';

  @override
  String get wind => 'VIND';

  @override
  String get sun2 => 'SOL';

  @override
  String get cloud => 'SKYER';

  @override
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt) {
    return 'Data: $source · Opdateret $fetchedAt';
  }

  @override
  String get coros2 => 'COROS';

  @override
  String get rmssdMs => 'RMSSD · ms';

  @override
  String get sdnnMs => 'SDNN · ms';

  @override
  String get now2 => 'NU';

  @override
  String get awake => 'VÅGEN';

  @override
  String get light => 'LET';

  @override
  String get deep2 => 'DYB';

  @override
  String get sqliteOrm => 'SQLite ORM';

  @override
  String get httpClients => 'HTTP-klienter';

  @override
  String get gpsLocation => 'GPS-placering';

  @override
  String get hdlCholesterol => 'HDL-kolesterol';

  @override
  String get ldlCholesterol => 'LDL-kolesterol';

  @override
  String get raceName => 'LØBSNAVN';

  @override
  String get mtb => 'MTB';

  @override
  String get distanceKm => 'Distance (km)';

  @override
  String get priority => 'PRIORITET';

  @override
  String get elevationGainM => 'Stigning (m)';

  @override
  String get targetTime => 'MÅLTID';

  @override
  String get raceDate => 'LØBSDATO';

  @override
  String get participation => 'DELTAGELSE';

  @override
  String get whatIWantFromIt => 'HVAD JEG VIL HAVE UD AF DET';

  @override
  String periodTimeline(Object period) {
    return '$period · FORLØB';
  }

  @override
  String get tabPlan => 'PLAN';

  @override
  String get tabLoad => 'BELASTNING';

  @override
  String get tabCoach => 'TRÆNER';

  @override
  String get hrDriftTestLt1 => 'PULSDRIFTTEST – LT1';

  @override
  String get asSentByGarmin => 'SOM SENDT AF GARMIN';

  @override
  String get noData2 => 'INGEN DATA';

  @override
  String get noTarget => 'INTET MÅL';

  @override
  String get noHeatLoad => 'INGEN VARMEBELASTNING';

  @override
  String get hrBpm => 'Puls (bpm)';

  @override
  String get aiBriefingUnavailableShowingA =>
      'AI-briefing er ikke tilgængelig. Viser et resumé uden AI.';

  @override
  String get uvIndex2 => 'UV-INDEKS';

  @override
  String get aiBriefing => 'AI-briefing';

  @override
  String get uiFrameworkByGoogle => 'UI-framework fra Google';

  @override
  String get unableToLoadData => 'Kunne ikke indlæse data';

  @override
  String briefingSummary(Object recovery, Object sleep, Object load) {
    return 'Restitution $recovery / 100. Søvn $sleep / 100. Dagens træningsbelastning er $load TRIMP.';
  }

  @override
  String get morningBriefing => 'Morgenbriefing';

  @override
  String get lunchBriefing => 'Frokostbriefing';

  @override
  String get afternoonBriefing => 'Eftermiddagsbriefing';

  @override
  String get eveningBriefing => 'Aftenbriefing';

  @override
  String get appleUnusableAnswer =>
      'Apple Intelligence kunne ikke give et brugbart svar: den gentog sig selv eller dine data. Omformulér spørgsmålet, eller vælg en anden AI-udbyder i indstillingerne.';

  @override
  String get appleCouldNotAnswer =>
      'Apple Intelligence kunne ikke svare. Prøv igen.';

  @override
  String get appleNotAvailableOnDevice =>
      'Apple Intelligence er ikke tilgængelig på denne enhed.';

  @override
  String get appleLanguageRejected =>
      'Apple Intelligence afviste forespørgslens sprog. Prøv et kort spørgsmål på engelsk. Tjek også sprogindstillingerne for iPhone og Siri.';

  @override
  String get appleRequestTooLarge =>
      'Apple Intelligence kunne ikke rumme denne forespørgsel. Prøv et kortere spørgsmål.';

  @override
  String get messageTooLongForApple =>
      'Denne besked er for lang til Apple Intelligence. Forkort den, og send igen.';

  @override
  String get vo2maxRunning => 'VO₂max løb';

  @override
  String get vo2maxCycling => 'VO₂max cykling';

  @override
  String get vo2maxPaceLabel => 'VO₂max-tempo';

  @override
  String get lt1Threshold => 'LT1-tærskel';

  @override
  String get lt2Threshold => 'LT2-tærskel';

  @override
  String hoursPreviousWeek(Object value) {
    return '$value t sidste uge';
  }

  @override
  String kmPreviousWeek(Object value) {
    return '$value km sidste uge';
  }

  @override
  String get thirtyMinuteTimeTrial => '30-minutters tidskørsel';

  @override
  String thirtyMinTtDate(Object date) {
    return '30-min TT · $date';
  }

  @override
  String get yesterday2 => 'I GÅR';

  @override
  String get briefHeadGreen => 'Du er godt restitueret.';

  @override
  String get briefHeadYellow => 'Du er lidt belastet.';

  @override
  String get briefHeadRed => 'Du er tydeligt belastet.';

  @override
  String briefMain(Object reasons) {
    return 'Hovedårsager: $reasons.';
  }

  @override
  String get briefAllClear => 'Ingen af dine værdier viser et advarselssignal.';

  @override
  String get briefAdviceGreen => 'Træn som planlagt.';

  @override
  String get briefAdviceYellow =>
      'Behold din plan, men tilføj ingen ekstra intensitet.';

  @override
  String get briefAdviceRed => 'Restitution først: tag en let dag eller hvil.';

  @override
  String get briefReasonHrvLow => 'lav søvn-HRV';

  @override
  String get briefReasonHrvHigh => 'høj søvn-HRV';

  @override
  String get briefReasonRhrUp => 'forhøjet hvilepuls';

  @override
  String get briefReasonRhrDown => 'lav hvilepuls';

  @override
  String get briefReasonSleepShort => 'for lidt søvn';

  @override
  String get briefReasonSleepGood => 'søvnbehovet er dækket';

  @override
  String get briefReasonEnergyLow => 'lidt energi';

  @override
  String get briefReasonEnergyHigh => 'god energi';

  @override
  String get briefReasonStressHigh => 'højt stressniveau';

  @override
  String get briefReasonRespHigh => 'forhøjet respirationsfrekvens';

  @override
  String get briefReasonSpo2Low => 'lavt ilt i blodet';

  @override
  String get briefReasonSkinTempOff => 'usædvanlig hudtemperatur';

  @override
  String get briefReasonFormTired => 'ophobet træningstræthed';

  @override
  String get briefReasonFormVeryTired => 'meget høj træningstræthed';

  @override
  String get briefReasonFormFresh => 'frisk og udhvilet';

  @override
  String get briefTrainingHrvUp =>
      'Din HRV steg efter træningen, et godt tegn.';

  @override
  String get briefTrainingHrvDown =>
      'Din HRV faldt efter træningen, et mindre godt tegn.';

  @override
  String get reminderNeedsNotifications =>
      'Påmindelsen kræver notifikationer. Tillad dem for Fjelia i systemindstillingerne, og slå den til igen.';

  @override
  String get whatDidYouHave => 'Hvad indtog du?';

  @override
  String get intakeSomething => 'Jeg indtog noget';

  @override
  String get intakeNothing => 'Intet';

  @override
  String get totalIntake => 'Samlet indtag';

  @override
  String get carbsLabel => 'Kulhydrater';

  @override
  String get fluidLabel => 'Væske';

  @override
  String get sodiumLabel => 'Natrium';

  @override
  String get caffeineLabel => 'Koffein';

  @override
  String get detailsOptional => 'Detaljer (valgfrit)';

  @override
  String atMinute(Object minute) {
    return 'minut $minute';
  }

  @override
  String get nothingAddedYet =>
      'Intet tilføjet endnu. Tilføj, hvad du spiste eller drak, eller vælg “Intet”.';

  @override
  String get followFocusWeek => 'Hvad skal jeg fokusere på i denne uge?';

  @override
  String get followRecoveryTrend => 'Hvordan udvikler min restitution sig?';

  @override
  String get followLoadTooHigh => 'Er min træningsbelastning for høj?';

  @override
  String get followImproveSleep => 'Hvad ville forbedre min søvn?';

  @override
  String get followIntervalsFeel => 'Hvordan skal intervallerne føles?';

  @override
  String get followTiredToday => 'Hvad hvis jeg er træt i dag?';

  @override
  String get followEatBefore => 'Hvad skal jeg spise før?';

  @override
  String get followAdjustToday => 'Skal jeg justere den i dag?';

  @override
  String get followNextDays => 'Hvad betyder det for mine næste dage?';

  @override
  String get followCompareSimilar =>
      'Hvordan er det i forhold til lignende sessioner?';

  @override
  String get followRecover => 'Hvad skal jeg gøre for at restituere?';

  @override
  String get followIntensityRight => 'Var intensiteten rigtig?';

  @override
  String get statusPlanned => 'Planlagt';

  @override
  String get statusAdapted => 'Tilpasset';

  @override
  String get statusCompleted => 'Gennemført';

  @override
  String get statusRest => 'Hvile';

  @override
  String loadValue(Object value) {
    return 'Belastning $value';
  }

  @override
  String get actIntensityEasy => 'Det var en let aerob session.';

  @override
  String get actIntensityModerate => 'Det var en moderat session.';

  @override
  String get actIntensityHard => 'Det var en hård session.';

  @override
  String get actIntensityUnknown => 'Sessionen er registreret.';

  @override
  String get actLenLonger => 'Den var længere end dine lignende sessioner.';

  @override
  String get actLenShorter => 'Den var kortere end dine lignende sessioner.';

  @override
  String get actLoadHigher => 'Belastningen var højere end normalt.';

  @override
  String get actLoadLower => 'Belastningen var lavere end normalt.';

  @override
  String get actLoadSame => 'Belastningen var omtrent som normalt.';

  @override
  String get actHrLower =>
      'Din puls var lavere end normalt, det føltes lettere.';

  @override
  String get actHrHigher =>
      'Din puls var højere end normalt, det føltes hårdere.';

  @override
  String get actAdviceUnknown =>
      'Planlæg dine næste dage efter, hvordan du har det.';

  @override
  String briefOutlookRest(Object days) {
    return 'Med omkring $days rolige dage er din form tilbage i det optimale område.';
  }

  @override
  String get briefOutlookLongRest =>
      'Din form har brug for mere end nogle få rolige dage for at komme sig.';

  @override
  String get briefOutlookPlanTired =>
      'Hvis du følger planen, forbliver din form lav de næste dage.';

  @override
  String get localQwen => 'Qwen3.5 · lokal';

  @override
  String get localModelDescription =>
      'Valgfri Qwen3.5, 4-bit MLX. Download én gang, og brug chat og opsummeringer på denne enhed uden API-nøgle. Dine sundhedsdata bliver på denne enhed.';

  @override
  String localModelSizeMb(Object megabytes) {
    return '$megabytes MB download · der kræves ekstra hukommelse under brug.';
  }

  @override
  String get localModelDownload => 'Download model';

  @override
  String get localModelResumeDownload => 'Fortsæt download';

  @override
  String localModelDownloading(Object downloaded, Object total) {
    return '$downloaded / $total MB';
  }

  @override
  String get localModelInstalled => 'Downloadet · tilgængelig offline';

  @override
  String get localModelRemove => 'Slet model';

  @override
  String get localModelUnsupported =>
      'Denne MLX-model kræver en iPhone med iOS 17 eller nyere og en A14-chip eller nyere. Ældre enheder understøttes ikke.';

  @override
  String get localModelMemoryUnsupported =>
      'Denne enhed har ikke nok hukommelse til at køre den lokale model.';

  @override
  String get localModelDownloadFailed =>
      'Download mislykkedes. Prøv igen; komplette filer bevares.';

  @override
  String get localModelDownloadFirst =>
      'Download først Qwen under Indstillinger → AI og mere.';

  @override
  String get localModelContextTooLong =>
      'Denne samtale er for lang til den lokale model. Start en ny chat, eller forkort spørgsmålet.';

  @override
  String get localModelBusy =>
      'Den lokale model besvarer en anden forespørgsel. Prøv igen om lidt.';

  @override
  String get localModelInterrupted =>
      'Lokal generering blev afbrudt. Hold Fjelia åben, og prøv igen.';

  @override
  String get localModelCouldNotAnswer =>
      'Den lokale model kunne ikke svare. Tjek modellen under Indstillinger → AI og mere, og prøv igen.';

  @override
  String get localModelBriefingUnavailable =>
      'Lokal AI-opsummering er utilgængelig. Viser appens opsummering.';

  @override
  String get localModelInfo => 'Modeldetaljer og licens';

  @override
  String localModelRamGb(int gigabytes) {
    return 'Kræver mindst $gigabytes GB arbejdshukommelse.';
  }

  @override
  String get localModelIPhone18 => '4B er tilgængelig på iPhone 18 og nyere.';

  @override
  String briefPlannedTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Der er planlagt $count træningspas i dag.',
      one: 'Der er planlagt 1 træningspas i dag.',
    );
    return '$_temp0';
  }

  @override
  String get coachDataFallback =>
      'Modellens svar modsiger dataene. Her er Fjelias opsummering:';

  @override
  String get coachSevenDayAverage => '7-dages gennemsnit';

  @override
  String coachSleepNeedAndShortfall(String need, String shortfall) {
    return 'Søvnbehov: $need t; underskud: $shortfall t.';
  }

  @override
  String coachCurrentForm(String value) {
    return 'Aktuel form (TSB): $value point.';
  }

  @override
  String get aiOnboardingStep => 'Trin 2 af 3';

  @override
  String get aiOnboardingTitle => 'Din coach.\nPå din måde.';

  @override
  String get aiOnboardingSubtitle =>
      'Gør dine sundhedsdata til råd om bedre træning og restitution.';

  @override
  String get aiOnboardingChoose => 'VÆLG DIN AI-COACH';

  @override
  String get aiOnboardingFreeDetail => 'Gratis · Ingen AI-konto nødvendig';

  @override
  String get aiOnboardingFreeBody => 'AI i skyen til træning og restitution.';

  @override
  String get aiOnboardingRecommended => 'Anbefalet';

  @override
  String get aiOnboardingOnDevice => 'På din enhed';

  @override
  String get aiOnboardingLocalBody =>
      'Dine AI-forespørgsler bliver på denne enhed.';

  @override
  String get aiOnboardingUnavailable => 'Ikke tilgængelig lige nu';

  @override
  String get aiOnboardingMore => 'Flere AI-modeller';

  @override
  String get aiOnboardingMoreBody => 'Lokal Qwen eller din egen cloududbyder';

  @override
  String get aiOnboardingConsent =>
      'Cloudforespørgsler kræver din bekræftelse.';

  @override
  String get aiOnboardingError =>
      'Dit AI-valg kunne ikke gemmes eller indlæses. Prøv igen.';

  @override
  String get aiOnboardingWithout => 'Fortsæt uden AI';

  @override
  String get aiOnboardingConfigure => 'Konfigurer model';

  @override
  String aiOnboardingContinue(String provider) {
    return 'Fortsæt med $provider';
  }

  @override
  String get aiOnboardingChangeLater =>
      'Du kan altid ændre dette i indstillingerne.';

  @override
  String get creditsAndLicenses => 'Licenser og tak';

  @override
  String get bioAgeActivity => 'Aktivitet';

  @override
  String get bioAgeActivityBasis => 'Aktivitetsdata · seneste 7 dage';

  @override
  String bioAgeActivityReported(String minutes) {
    return '$minutes registrerede moderate minutter';
  }

  @override
  String bioAgeActivitySteps(String minutes) {
    return '≈ $minutes gangminutter anslået ud fra skridt';
  }

  @override
  String bioAgeActivityCoverage(int days) {
    return 'Data for $days af 7 dage';
  }

  @override
  String get bioAgeActivityEstimateNotice =>
      'Antagelse: 100 skridt ≈ 1 gangminut. Daglige skridttal viser hverken tempo eller intensitet. Registrerede minutter har forrang hver dag; skridtene fra samme dag tælles ikke med igen.';

  @override
  String get bioAgeActivityIncomplete =>
      'Der mangler aktivitetsdata. Aktivitetens bidrag i år beregnes først, når alle 7 dage har data.';

  @override
  String get bioAgeActivityEstimatedLabel =>
      'Aktiviteten indeholder anslået gangtid.';

  @override
  String get bioAgeActivityUnknownLabel => 'Aktivitetsdata er ufuldstændige';
}
