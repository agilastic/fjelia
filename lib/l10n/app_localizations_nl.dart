// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get freeAi => 'Free AI';

  @override
  String get freeAiUsageTracking =>
      'Om Free AI voor iedereen betrouwbaar beschikbaar te houden, sturen we een willekeurige installatie-ID mee. Daarmee herkennen we ongewoon gebruik en blokkeren we misbruik. De ID bevat geen naam of accountgegevens.';

  @override
  String freeAiDescription(String host) {
    return 'Free AI biedt gratis cloudchat en briefings via $host. Een apart account of API-sleutel is niet nodig. Berichten en een samenvatting van je gezondheid en training worden na je bevestiging naar deze dienst gestuurd.';
  }

  @override
  String get freeAiUnavailable =>
      'Free AI is niet beschikbaar in deze versie. Kies een andere aanbieder.';

  @override
  String shareBriefingContextWithName(String name) {
    return 'Een samenvatting van je gezondheids- en trainingsgegevens wordt naar $name gestuurd. Deze eenmalige toestemming geldt ook voor cloud-AI-aanbieders die je later voor briefings kiest.';
  }

  @override
  String get language => 'Taal';

  @override
  String get languageSystem => 'Systeemstandaard';

  @override
  String get settings => 'Instellingen';

  @override
  String get profile => 'Profiel';

  @override
  String get training => 'Training';

  @override
  String get weatherLocation => 'Weer & locatie';

  @override
  String get display => 'Weergave';

  @override
  String get connections => 'Koppelingen';

  @override
  String get aiAndMore => 'AI & meer';

  @override
  String get system => 'Systeem';

  @override
  String get runSetupAgain => 'Installatie opnieuw doorlopen';

  @override
  String get runSetupAgainSubtitle =>
      'Accounts, wedstrijddoel en trainingsplan';

  @override
  String get back => 'Terug';

  @override
  String get close => 'Sluiten';

  @override
  String get dataExport => 'Gegevens exporteren';

  @override
  String get dataExportSubtitle => 'CSV-export, back-up & herstel';

  @override
  String get developer => 'Ontwikkelaar';

  @override
  String get developerSubtitle => 'Debugmodus, diagnose';

  @override
  String get debug => 'Debug';

  @override
  String get debugMode => 'Debugmodus';

  @override
  String get debugModeSubtitle => 'Toont het tabblad DEBUG';

  @override
  String get support => 'Ondersteuning';

  @override
  String get reportBug => 'Fout melden';

  @override
  String get aiCoach => 'AI-coach';

  @override
  String get enableAiCoach => 'AI-coach inschakelen';

  @override
  String get onDeviceAiOrCloud => 'AI op het apparaat of cloudaanbieder';

  @override
  String get provider => 'Aanbieder';

  @override
  String get model => 'Model';

  @override
  String get chatAndAiBriefingsUse =>
      'Chat en AI-briefings gebruiken Apple Intelligence op dit apparaat. Geen API-sleutel nodig. Als het model niet beschikbaar is, tonen briefings een samenvatting zonder AI.';

  @override
  String get briefing => 'Briefing';

  @override
  String get useAppleIntelligenceForBriefings =>
      'Apple Intelligence gebruiken voor briefings';

  @override
  String get useOnDeviceAiFor =>
      'Gebruik AI op het apparaat voor briefings en houd de gekozen aanbieder voor de chat.';

  @override
  String get healthDataSharing => 'Gezondheidsgegevens delen';

  @override
  String get askOncePerChatSession => 'Eén keer per chatsessie vragen';

  @override
  String get otherwiseAskBeforeEveryCloud =>
      'Anders vóór elk cloudbericht vragen';

  @override
  String get reportABug => 'Een fout melden';

  @override
  String get weatherData => 'Weergegevens';

  @override
  String get openSourceLibraries => 'Opensourcebibliotheken';

  @override
  String get license => 'Licentie';

  @override
  String get licenses => 'Licenties';

  @override
  String get apiKey => 'API-sleutel';

  @override
  String get saveApiKey => 'API-sleutel opslaan';

  @override
  String get feedbackBugReport => 'Feedback & foutmelding';

  @override
  String get reportSentThankYou => 'Melding verstuurd. Bedankt!';

  @override
  String get weReadEveryMessageIf =>
      'We lezen elk bericht. Als je je e-mailadres hebt achtergelaten, krijg je mogelijk antwoord.';

  @override
  String get done => 'Gereed';

  @override
  String get shareAnIdeaSuggestAn =>
      'Deel een idee, stel een verbetering voor of vertel wat er gebeurde en wat je verwachtte.';

  @override
  String get whatHappenedAndWhatDid => 'Wat gebeurde er en wat verwachtte je?';

  @override
  String get pleaseLeaveOutPasswordsApi =>
      'Laat wachtwoorden, API-sleutels en persoonlijke gezondheidswaarden weg.';

  @override
  String get includeDiagnostics => 'Diagnosegegevens toevoegen';

  @override
  String get optionalLogsMayContainAccount =>
      'Optioneel. Logs kunnen account- of gezondheidsgegevens bevatten. Controleer ze hieronder voordat je verstuurt.';

  @override
  String get diagnosticsPreview => 'VOORBEELD DIAGNOSE';

  @override
  String get sendingSharesYourEmailSubject =>
      'Bij verzenden worden je e-mailadres, onderwerp, bericht en eventueel gekozen diagnosegegevens gedeeld met Fjelia-ondersteuning op www.fjelia.com.';

  @override
  String get copyReport => 'Melding kopiëren';

  @override
  String get shareReport => 'Melding delen';

  @override
  String get appleHealth => 'Apple Gezondheid';

  @override
  String get connectedServices => 'Gekoppelde diensten';

  @override
  String get hiloBloodPressureBle => 'Hilo-bloeddruk BLE';

  @override
  String get writeHeartDataToApple =>
      'Hartgegevens naar Apple Gezondheid schrijven';

  @override
  String get writeWeightDataToApple =>
      'Gewichtsgegevens naar Apple Gezondheid schrijven';

  @override
  String get renphoScaleBle => 'Renpho-weegschaal (BLE)';

  @override
  String get polarH10HrvStrapBle => 'Polar H10 (HRV-borstband, BLE)';

  @override
  String get dataSourcePriority => 'Prioriteit van gegevensbronnen';

  @override
  String get whenMultipleSourcesProvideThe =>
      'Als meerdere bronnen dezelfde waarde leveren, wint de hoogste bron. Sleep om de volgorde te wijzigen.';

  @override
  String get resetToDefault => 'Standaard herstellen';

  @override
  String get disconnect => 'Ontkoppelen';

  @override
  String get healthPage => 'Gezondheidspagina';

  @override
  String get loadPage => 'Belastingspagina';

  @override
  String get healthMonitor => 'Gezondheidsmonitor';

  @override
  String get hrZones => 'Hartslagzones';

  @override
  String get t30MinTtAvailableSync =>
      '30-min-tijdrit beschikbaar — hartslagzones synchroniseren';

  @override
  String lt2Lt2BpmAt(Object lt2, Object at) {
    return 'LT2 $lt2 bpm · $at';
  }

  @override
  String get syncLabel => 'SYNC';

  @override
  String get autoadjust => 'AUTOMATISCH';

  @override
  String zoneI(Object i) {
    return 'Zone $i';
  }

  @override
  String get hrZones2 => 'HARTSLAGZONES';

  @override
  String ageRound(Object round) {
    return 'leeftijd $round';
  }

  @override
  String get basics => 'Basis';

  @override
  String get updateWaistMonthlyUsedFor =>
      'ⓘ Werk je taille maandelijks bij — gebruikt voor de schatting van visceraal vet.';

  @override
  String get alcohol => 'Alcohol';

  @override
  String get t1Drink033L =>
      '1 glas ≈ 0,33 l bier / 0,2 l wijn / 4 cl sterke drank';

  @override
  String get clinicalLabsOptional => 'Laboratoriumwaarden (optioneel)';

  @override
  String get glycemic => 'Glykemisch';

  @override
  String get optimalForLongevity48 =>
      'Optimaal voor een lang leven: 4,8–5,4% · Prediabetes: 5,7–6,4%';

  @override
  String get lipids => 'Lipiden';

  @override
  String get apobReplacesLdlWhenBoth =>
      'ApoB vervangt LDL als beide zijn ingevuld.';

  @override
  String get inflammationKidney => 'Ontsteking & nieren';

  @override
  String get changesAreSavedAutomatically =>
      'Wijzigingen worden automatisch opgeslagen';

  @override
  String get optionalTotalClimbingForThis =>
      'Optioneel: totale hoogtemeters voor deze wedstrijd.';

  @override
  String get moreAboutThisEvent => 'Meer over dit evenement';

  @override
  String distanceOfDistancekmKm(Object distanceKm) {
    return 'Afstand van $distanceKm km?';
  }

  @override
  String keepDistancekmKm(Object distanceKm) {
    return '$distanceKm km houden';
  }

  @override
  String useLikelyKm(Object likely) {
    return '$likely km gebruiken';
  }

  @override
  String get thisBackupContainsNoCalendar =>
      'Deze back-up bevat geen kalenderactiviteiten.';

  @override
  String get activities => 'Activiteiten';

  @override
  String get exportActivitiesCsv => 'Activiteiten als CSV exporteren';

  @override
  String get backupRestore => 'Back-up & herstel';

  @override
  String get backup => 'Back-up';

  @override
  String get restoreFromBackup => 'Herstellen uit back-up';

  @override
  String get backupRestoredRestartTheApp =>
      'Back-up hersteld. Start de app opnieuw om alle instellingen te laden.';

  @override
  String get raceGoals => 'Wedstrijddoelen';

  @override
  String get yourActivities => 'Je activiteiten';

  @override
  String get usedByAiCoachAnd =>
      'Gebruikt door de AI-coach en het trainingsplan. Plansporten zijn gemarkeerd met ✦.';

  @override
  String get calendarWeekStart => 'Begin van de kalenderweek';

  @override
  String get planDefaultView => 'Standaardweergave plan';

  @override
  String get weeklySchedule => 'Weekschema';

  @override
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      trainingDaysPerWeek,
      locale: localeName,
      other: '$trainingDaysPerWeek trainingsdagen',
      one: '$trainingDaysPerWeek trainingsdag',
    );
    return '$_temp0 · tik om te wisselen tussen training / rust / kracht';
  }

  @override
  String get updatePlanToThisSchedule => 'Plan aanpassen aan dit schema';

  @override
  String get updateStrengthSessions => 'Krachttrainingen bijwerken';

  @override
  String get sessionsPerDay => 'Trainingen per dag';

  @override
  String get canYouFitTwoWorkouts => 'Kun je twee trainingen op één dag kwijt?';

  @override
  String get strengthLoadUnit => 'Eenheid voor krachtbelasting';

  @override
  String get weightsThemselvesAreSetIn =>
      'De gewichten zelf stel je per training in; ze worden onthouden uit je geschiedenis.';

  @override
  String get hoursAvailableWeek => 'Beschikbare uren / week';

  @override
  String hoursperweekHWeek(Object hoursPerWeek) {
    return '$hoursPerWeek u / week';
  }

  @override
  String hoursperweekH(Object hoursPerWeek) {
    return '$hoursPerWeek u';
  }

  @override
  String get heatAcclimation => 'Hitte-acclimatisatie';

  @override
  String get showHeatAcclimation => 'Hitte-acclimatisatie tonen';

  @override
  String get weatherEvaluatedAgainstAConfigurable =>
      'Het weer wordt beoordeeld voor een instelbare locatie.';

  @override
  String get trainingPlan => 'Trainingsplan';

  @override
  String get regenerateReplacesFutureSessionsAnd =>
      'Opnieuw genereren vervangt toekomstige trainingen en bouwt het plan vanaf vandaag opnieuw op met de huidige instellingen.';

  @override
  String valueUpcomingWorkoutsGenerated(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value komende trainingen aangemaakt',
      one: '$value komende training aangemaakt',
    );
    return '$_temp0';
  }

  @override
  String get generationFailedCheckYourRace =>
      'Genereren mislukt. Controleer je wedstrijddoel en probeer het opnieuw.';

  @override
  String get deleteAllWorkouts => 'Alle trainingen verwijderen';

  @override
  String get changesAreSavedAutomatically2 =>
      '✓ Wijzigingen worden automatisch opgeslagen';

  @override
  String countUpcomingWorkoutsGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count komende trainingen aangemaakt',
      one: '$count komende training aangemaakt',
    );
    return '$_temp0';
  }

  @override
  String get importRaceGoalsFromGarmin =>
      'Wedstrijddoelen uit Garmin importeren';

  @override
  String get addRaceGoal => 'Wedstrijddoel toevoegen';

  @override
  String priorityTouppercase(Object toUpperCase) {
    return 'Prioriteit $toUpperCase';
  }

  @override
  String get goalsAreSharedWithAi =>
      'Doelen worden gedeeld met de AI-coach. Prioriteit A, B en C bepalen hoe het plan je wedstrijden tegen elkaar afweegt.';

  @override
  String get deletingWorkouts => 'Trainingen verwijderen';

  @override
  String get cityOrTown => 'Stad of plaats';

  @override
  String get eGHannoverOrPalma => 'bijv. Hannover of Palma';

  @override
  String get noCitiesFoundTryA =>
      'Geen steden gevonden. Probeer een plaats in de buurt.';

  @override
  String get chooseTheLocationForThe =>
      'Kies de locatie voor de weersverwachting, radar en hitte-acclimatisatie in het plan. Het weer werkt ook als hitte-acclimatisatie uit staat.';

  @override
  String get none => 'Geen';

  @override
  String get disableLocalWeatherAndLocation =>
      'Lokaal weer en locatieverzoeken uitschakelen';

  @override
  String get currentLocation => 'Huidige locatie';

  @override
  String get followYourDeviceLocation => 'Locatie van je apparaat volgen';

  @override
  String get fixedLocation => 'Vaste locatie';

  @override
  String get chooseACityOrEnter => 'Kies een stad of voer coördinaten in';

  @override
  String get chooseCity => 'Stad kiezen';

  @override
  String get coordinates => 'Coördinaten';

  @override
  String get latitude => 'Breedtegraad';

  @override
  String get longitude => 'Lengtegraad';

  @override
  String get saveLocation => 'Locatie opslaan';

  @override
  String get refreshCurrentLocation => 'Huidige locatie vernieuwen';

  @override
  String get citySearchOpenMeteoGeonames =>
      'Stad zoeken: Open-Meteo / GeoNames';

  @override
  String get cityNamesOpenstreetmap => 'Plaatsnamen: © OpenStreetMap';

  @override
  String get energy => 'ENERGIE';

  @override
  String get currentEnergy => 'HUIDIGE ENERGIE';

  @override
  String get dailyTimeline => 'DAGVERLOOP';

  @override
  String valueValue2(Object value, Object value2) {
    return '$value → $value2';
  }

  @override
  String get energy2 => 'Energie';

  @override
  String get noData => 'Geen gegevens';

  @override
  String get bloodPressureInsights => 'BLOEDDRUKINZICHTEN';

  @override
  String get sys => ' Sys';

  @override
  String get diaMmhg => ' Dia · mmHg';

  @override
  String get previousBloodPressurePeriod => 'Vorige bloeddrukperiode';

  @override
  String get nextBloodPressurePeriod => 'Volgende bloeddrukperiode';

  @override
  String get nightDipping => 'Nachtelijke daling';

  @override
  String get noMeasurementsInThisPeriod => 'Geen metingen in deze periode';

  @override
  String get fullscreenBloodPressureChart =>
      'Bloeddrukgrafiek op volledig scherm';

  @override
  String get barsMinMaxLineDots =>
      'Balken: min–max · lijn/punten: gemiddelde · tik of sleep om te bekijken';

  @override
  String get noMeasurements => 'Geen metingen';

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
      other: '$length metingen',
      one: '$length meting',
    );
    return '$_temp0 · gemiddelde / min–max';
  }

  @override
  String bloodPressureTouppercaseMmhg(Object toUpperCase) {
    return 'BLOEDDRUK · $toUpperCase · mmHg';
  }

  @override
  String get closeFullscreenBloodPressureChart =>
      'Bloeddrukgrafiek op volledig scherm sluiten';

  @override
  String get chooseScale => 'Weegschaal kiezen';

  @override
  String get noScalesFoundStepOn =>
      'Geen weegschalen gevonden. Ga op je weegschaal staan en probeer het opnieuw.';

  @override
  String nameRssiDbm(Object name, Object rssi) {
    return '$name · $rssi dBm';
  }

  @override
  String get renphoSaved => 'RENPHO opgeslagen:';

  @override
  String get renphoScaleBle2 => 'RENPHO-weegschaal (BLE)';

  @override
  String get changeMeasurementType => 'Meettype wijzigen';

  @override
  String get addMeasurement => 'Meting toevoegen';

  @override
  String get whatAreYouMeasuring => 'Wat meet je?';

  @override
  String get chooseAnotherMeasurement => 'Andere meting kiezen';

  @override
  String get saveMeasurement => 'Meting opslaan';

  @override
  String get skip => 'Overslaan';

  @override
  String get connectHiloService => 'Hilo-dienst koppelen';

  @override
  String get connectHilo => 'Hilo koppelen';

  @override
  String get connectCoros => 'Coros koppelen';

  @override
  String get europe => 'Europa';

  @override
  String get unitedStates => 'Verenigde Staten';

  @override
  String get asia => 'Azië';

  @override
  String get bluetoothBloodPressure => 'Bluetooth · bloeddruk';

  @override
  String get cloudCuffData => 'Cloud · manchetgegevens';

  @override
  String get apiSync => 'API-synchronisatie';

  @override
  String get bluetoothHrvStrap => 'Bluetooth · HRV-borstband';

  @override
  String get accesslinkApi => 'AccessLink API';

  @override
  String get systemHealthData => 'Gezondheidsgegevens van het systeem';

  @override
  String get cloudScaleHistory => 'Cloud · weeggeschiedenis';

  @override
  String get bluetoothWeightBody => 'Bluetooth · gewicht & lichaam';

  @override
  String get connectYourDevices => 'Koppel je apparaten';

  @override
  String get continueLabel => 'Doorgaan';

  @override
  String get connectGarmin => 'Garmin koppelen';

  @override
  String get connectAppleHealth => 'Apple Gezondheid koppelen';

  @override
  String get dataSynced => 'GEGEVENS GESYNCHRONISEERD';

  @override
  String get pairHiloPod => 'Hilo Pod koppelen';

  @override
  String get chooseStrap => 'Borstband kiezen';

  @override
  String namePaired(Object name) {
    return '$name gekoppeld.';
  }

  @override
  String get pairPolarH10 => 'Polar H10 koppelen';

  @override
  String get forget => 'Vergeten';

  @override
  String get sendWorkoutToPolar => 'Training naar Polar sturen';

  @override
  String get connectPolar => 'Polar koppelen';

  @override
  String get signInWithPolarFlow => 'Inloggen met Polar Flow';

  @override
  String get syncsSleepStagesHrvResting =>
      'Synchroniseert slaapfasen · HRV · rusthartslag · trainingen · stappen';

  @override
  String savedForV(Object v) {
    return 'Opgeslagen voor $v';
  }

  @override
  String get remove => 'Verwijderen';

  @override
  String get polarEMail => 'Polar-e-mailadres';

  @override
  String get polarPassword => 'Polar-wachtwoord';

  @override
  String get pairRenphoScale => 'RENPHO-weegschaal koppelen';

  @override
  String get connectRenpho => 'Renpho koppelen';

  @override
  String get connectSuunto => 'Suunto koppelen';

  @override
  String smsSentToTrim(Object trim) {
    return 'Sms verstuurd naar $trim';
  }

  @override
  String get resendSms => 'Sms opnieuw versturen';

  @override
  String get retryLoadingPreferences => 'Voorkeuren opnieuw laden';

  @override
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed) {
    return 'TRAININGSTIJD PER WEEK · $toStringAsFixed u';
  }

  @override
  String get tapADayToCycle =>
      'Tik op een dag om te wisselen tussen training / rust / kracht.';

  @override
  String get doubleDayOk => 'Dubbele dag oké';

  @override
  String get birthYearOptional => 'Geboortejaar (optioneel)';

  @override
  String get addAnother => 'Nog een toevoegen';

  @override
  String get knowYourBodyTrainSmarter => 'Ken je lichaam.\nTrain slimmer.';

  @override
  String get allYourHealthDevicesOne =>
      'Al je gezondheidsapparaten. Eén slim overzicht.';

  @override
  String get areYouReadyToTrain => 'Ben je klaar om vandaag te trainen?';

  @override
  String get hrvRecoveryScoreRestingHr => 'HRV · Herstelscore · Rusthartslag';

  @override
  String get didYouActuallyRecoverLast => 'Ben je vannacht echt hersteld?';

  @override
  String get sleepStagesDeepSleepSpo => 'Slaapfasen · Diepe slaap · SpO₂';

  @override
  String get isYourBloodPressureUnder => 'Is je bloeddruk onder controle?';

  @override
  String get continuousBpNightDippingTrends =>
      'Continue bloeddruk · Nachtelijke daling · Trends';

  @override
  String get howHardDidYouPush => 'Hoe hard ben je deze week gegaan?';

  @override
  String get trainingLoadTrimpStrainScore =>
      'Trainingsbelasting · TRIMP · Strain Score';

  @override
  String get isYourBodyCompositionImproving =>
      'Verbetert je lichaamssamenstelling?';

  @override
  String get weightBodyFatMuscleMass => 'Gewicht · Lichaamsvet · Spiermassa';

  @override
  String get getStarted => 'Aan de slag';

  @override
  String get yourDataStaysOnYour => 'Jouw gegevens. Jij kiest wat je deelt.';

  @override
  String get bodyScale => 'Weegschaal';

  @override
  String get bodyComposition => 'Lichaamssamenstelling';

  @override
  String get sleep => 'SLAAP';

  @override
  String get sleepPerformance => 'SLAAPPRESTATIE';

  @override
  String get sleepHistory => 'Slaapgeschiedenis';

  @override
  String labelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String lessLabel(Object label) {
    return 'Minder $label';
  }

  @override
  String moreLabel(Object label) {
    return 'Meer $label';
  }

  @override
  String get gymMode => 'Sportschoolmodus';

  @override
  String get finishWorkout => 'Training afronden';

  @override
  String get workoutActions => 'Trainingsacties';

  @override
  String get discardWorkout => 'Training verwerpen';

  @override
  String get allSetsRecorded => 'Alle sets vastgelegd';

  @override
  String get reviewSets => 'Sets bekijken';

  @override
  String get rest => 'RUST';

  @override
  String plannedResttarget(Object restTarget) {
    return 'Gepland $restTarget';
  }

  @override
  String get startSet => 'Set starten';

  @override
  String get seconds => 'Seconden';

  @override
  String get previousSet => 'Vorige set';

  @override
  String get allSets => 'Alle sets';

  @override
  String get nextSet => 'Volgende set';

  @override
  String get everySetIsSavedAs =>
      'Elke set wordt meteen opgeslagen. Sluit dit scherm wanneer je wilt en ga verder vanuit de geplande training.';

  @override
  String get cancel => 'Annuleren';

  @override
  String get apply => 'Toepassen';

  @override
  String get effortScale => 'Inspanningsschaal';

  @override
  String get setType => 'Soort set';

  @override
  String get reps => 'Herhalingen';

  @override
  String get range => 'Bereik';

  @override
  String get time => 'Tijd';

  @override
  String get t45Or100 => '45 of 1:00';

  @override
  String get blankWhenNotSet => 'Leeg als niet ingesteld';

  @override
  String get redBand => 'Rode band';

  @override
  String get t90Or130 => '90 of 1:30';

  @override
  String get blankWhenUnknown => 'Leeg als onbekend';

  @override
  String get usePlannedLoad => 'Geplande belasting gebruiken';

  @override
  String get blankWhenNotMeasured => 'Leeg als niet gemeten';

  @override
  String get exercise => 'Oefening';

  @override
  String get changingTheLoadConventionStarts =>
      'Als je de manier van belasting noteren wijzigt, begint er een aparte geschiedenis voor deze oefening.';

  @override
  String get barbellMachine => 'Halter, machine…';

  @override
  String get load => 'Belasting';

  @override
  String get loadRefersTo => 'Belasting verwijst naar';

  @override
  String get t2ForAPair => '2 voor een paar';

  @override
  String get repetitions => 'Herhalingen';

  @override
  String get availablePlatesOrDumbbells => 'Beschikbare schijven of dumbbells';

  @override
  String get rememberForThisEquipment => 'Onthouden voor dit materiaal';

  @override
  String get findOrNameAnExercise => 'Zoek of benoem een oefening';

  @override
  String createTrim(Object trim) {
    return '“$trim” aanmaken';
  }

  @override
  String get customExercise => 'Eigen oefening';

  @override
  String get smallestLoadStep => 'Kleinste belastingsstap';

  @override
  String whatRemoved(Object what) {
    return '$what verwijderd';
  }

  @override
  String get undo => 'Ongedaan maken';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get performance => 'Prestatie';

  @override
  String get addExercise => 'Oefening toevoegen';

  @override
  String get finishLog => 'Logboek afronden';

  @override
  String get keepAsDraft => 'Als concept bewaren';

  @override
  String actionsForName(Object name) {
    return 'Acties voor $name';
  }

  @override
  String get editExercise => 'Oefening bewerken';

  @override
  String get moveUp => 'Omhoog';

  @override
  String get moveDown => 'Omlaag';

  @override
  String get addSet => 'Set toevoegen';

  @override
  String get removeLastSet => 'Laatste set verwijderen';

  @override
  String get saveAsTemplate => 'Als sjabloon opslaan';

  @override
  String savedTitleAsATemplate(Object title) {
    return '“$title” als sjabloon opgeslagen. Deze training blijft ongewijzigd tot je hem opslaat.';
  }

  @override
  String nameSetN(Object name, Object n) {
    return '$name · Set $n';
  }

  @override
  String nameAllWorkingSets(Object name) {
    return '$name · Alle werksets';
  }

  @override
  String labelRest(Object label) {
    return '$label rust';
  }

  @override
  String get secondsOrMSs => 'Seconden of m:ss';

  @override
  String get applyToAllSets => 'Op alle sets toepassen';

  @override
  String get duplicate => 'Dupliceren';

  @override
  String get supersetWithNext => 'Superset met volgende';

  @override
  String get circuitWithNext => 'Circuit met volgende';

  @override
  String actionsForSetN(Object n) {
    return 'Acties voor set $n';
  }

  @override
  String get editSet => 'Set bewerken';

  @override
  String get duplicateSet => 'Set dupliceren';

  @override
  String get removeSet => 'Set verwijderen';

  @override
  String labelActions(Object label) {
    return '$label-acties';
  }

  @override
  String get editRests => 'Rustpauzes bewerken';

  @override
  String get ungroup => 'Groep opheffen';

  @override
  String get editExercises => 'Oefeningen bewerken';

  @override
  String get unsavedChanges => 'Niet-opgeslagen wijzigingen';

  @override
  String couldNotSaveError(Object error) {
    return 'Opslaan mislukt: $error';
  }

  @override
  String get history => 'Geschiedenis';

  @override
  String get exercises => 'Oefeningen';

  @override
  String get noExercisesArePlannedFor =>
      'Voor deze training zijn nog geen oefeningen gepland. De notities hierboven beschrijven hem.';

  @override
  String get addExercises => 'Oefeningen toevoegen';

  @override
  String get fromTheBuiltInTemplate =>
      'Uit het ingebouwde sjabloon. De gewichten bepaal je zelf; de geschiedenis verschijnt zodra je een training vastlegt.';

  @override
  String get shareExerciseList => 'Oefeningenlijst delen';

  @override
  String get noSavedStrengthTemplatesYet =>
      'Nog geen opgeslagen krachtsjablonen. Sla eerst een sjabloon op vanuit een geplande training.';

  @override
  String get compareWith => 'Vergelijken met';

  @override
  String estimated1rmUnit(Object unit) {
    return 'Geschat 1RM $unit';
  }

  @override
  String get plannedNotRecorded => 'Gepland, niet vastgelegd';

  @override
  String get notes => 'Notities';

  @override
  String get editPerformance => 'Prestatie bewerken';

  @override
  String get compareWithASavedWorkout =>
      'Vergelijken met een opgeslagen training';

  @override
  String get sessions => 'Trainingen';

  @override
  String get radarUnavailableRetry =>
      'Radar niet beschikbaar · Opnieuw proberen';

  @override
  String get radar => 'Radar';

  @override
  String get weatherDataByRainviewer => 'Weergegevens van RainViewer';

  @override
  String get openstreetmapContributors => '© OpenStreetMap-bijdragers';

  @override
  String get weather => 'Weer';

  @override
  String get weatherUnavailableRetry =>
      'Weer niet beschikbaar · Opnieuw proberen';

  @override
  String get chooseAFixedLocationIn =>
      'Kies een vaste locatie in de instellingen Weer & locatie, of sta locatietoegang toe voor het lokale weer.';

  @override
  String get locationSettings => 'Locatie-instellingen';

  @override
  String get retryLocation => 'Locatie opnieuw proberen';

  @override
  String round2(Object round) {
    return '$round°';
  }

  @override
  String roundRhRound2Hpa(Object round, Object round2) {
    return '$round% RV · $round2 hPa';
  }

  @override
  String wetBulbTostringasfixedC(Object toStringAsFixed) {
    return 'Natteboltemperatuur $toStringAsFixed°C';
  }

  @override
  String get previousForecastDay => 'Vorige voorspellingsdag';

  @override
  String get nextForecastDay => 'Volgende voorspellingsdag';

  @override
  String daysDayForecast(Object days) {
    return '$days-daagse voorspelling';
  }

  @override
  String thisProviderCurrentlySuppliesDays(Object days, Object days2) {
    return 'Deze aanbieder levert momenteel $days van $days2 voorspellingsdagen.';
  }

  @override
  String get now => 'Nu';

  @override
  String get sunriseSunset => 'Zonsopkomst / zonsondergang';

  @override
  String keyKey2(Object key, Object key2) {
    return '☀ $key   ☾ $key2';
  }

  @override
  String get use => 'Gebruiken';

  @override
  String get exerciseDetailsWereNotProvided =>
      'Deze activiteitsbron leverde geen details over de oefeningen.';

  @override
  String get logFromPlan => 'Vastleggen vanuit plan';

  @override
  String get addExerciseDetails => 'Oefeningdetails toevoegen';

  @override
  String get loadSuggestion => 'Voorgestelde belasting';

  @override
  String get applyToThisWorkout => 'Op deze training toepassen';

  @override
  String get keepCurrentLoad => 'Huidige belasting houden';

  @override
  String get setLoadStep => 'Belastingsstap instellen';

  @override
  String get viewSupportingSets => 'Onderliggende sets bekijken';

  @override
  String get supportingSets => 'Onderliggende sets';

  @override
  String get noRecordedSessionsYet => 'Nog geen vastgelegde trainingen.';

  @override
  String nameDemonstrationCue(Object name, Object cue) {
    return 'Demonstratie $name. $cue';
  }

  @override
  String get noScalesFoundStepOn2 =>
      'Geen weegschalen gevonden. Ga op de weegschaal staan en probeer het opnieuw.';

  @override
  String get scalePaired => 'Weegschaal gekoppeld';

  @override
  String get ok => 'OK';

  @override
  String get pairedReadyToMeasure => '✓ Gekoppeld — klaar om te meten';

  @override
  String get chooseHiloCuff => 'Hilo-manchet kiezen';

  @override
  String get noCuffFoundWakeYour =>
      'Geen manchet gevonden. Maak je manchet wakker en zoek opnieuw.';

  @override
  String get hiloCuffAktiiaC => 'Hilo-manchet (AKTIIA C…)';

  @override
  String get onDemandBloodPressureVia => 'Bloeddruk op verzoek via BLE';

  @override
  String get selectHiloPodWristband => 'Hilo Pod (polsband) kiezen';

  @override
  String get rescan => 'Opnieuw zoeken';

  @override
  String get noDevicesFoundTapTo =>
      'Geen apparaten gevonden. Tik op ↻ om opnieuw te zoeken.';

  @override
  String get polarH10SpotHrv => 'Polar H10 · Momentane HRV';

  @override
  String get aSeparateHrvReadingBefore =>
      'Een aparte HRV-meting voor of na de training. Deze metingen vervangen de nachtelijke HRV van Garmin niet en veranderen je readiness-score niet.';

  @override
  String get wearTheStrapWithMoist =>
      'Draag de borstband met vochtige elektroden. Blijf stil en adem normaal. Gebruik voor vergelijkingen dezelfde houding en meetduur. Noteer na een training hoe lang je eerst hebt gerust.';

  @override
  String get measurement => 'Meting';

  @override
  String get posture => 'Houding';

  @override
  String get recordingLengthPlus1Min =>
      'Meetduur · plus 1 min om tot rust te komen';

  @override
  String get t2Minutes => '2 minuten';

  @override
  String get t5Minutes => '5 minuten';

  @override
  String get minutesSinceTrainingEndedOptional =>
      'Minuten sinds het einde van de training (optioneel)';

  @override
  String get sessionOrNotesOptional => 'Training of notities (optioneel)';

  @override
  String connectName(Object name) {
    return '$name koppelen';
  }

  @override
  String get findPolarH10 => 'Polar H10 zoeken';

  @override
  String signalRssiDbm(Object rssi) {
    return 'Signaal $rssi dBm';
  }

  @override
  String connectedName(Object name) {
    return 'Gekoppeld: $name';
  }

  @override
  String get waitingForHeartRateAnd =>
      'Wachten op hartslag en RR-intervallen. Controleer het contact van de borstband.';

  @override
  String get startMeasurement => 'Meting starten';

  @override
  String get cancelMeasurement => 'Meting annuleren';

  @override
  String get spotHrvRmssd => 'Momentane HRV · RMSSD';

  @override
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  ) {
    return '$accepted/$length bruikbare intervallen · $toStringAsFixed% dekking';
  }

  @override
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs) {
    return 'lnRMSSD: $lnRmssd · Ruwe RMSSD: $rawRmssdMs ms';
  }

  @override
  String get signalQualityIsTooLow =>
      'De signaalkwaliteit is te laag om op te slaan. Herhaal de meting met goed contact van de borstband. Minstens 95% bruikbare intervallen en 90% dekking zijn nodig.';

  @override
  String get savedToSpotHrvHistory =>
      'Opgeslagen in de geschiedenis van momentane HRV.';

  @override
  String get newMeasurement => 'Nieuwe meting';

  @override
  String get signalScreeningExcludesPoorContact =>
      'De signaalcontrole sluit slecht contact uit, RR buiten 250–2500 ms en intervallen die meer dan 25% van de lokale mediaan afwijken. Hiaten worden niet overbrugd. Dit is geen medische test en geen losse readiness-score.';

  @override
  String historyLabelLabel2DurationMin(
    Object label,
    Object label2,
    Object duration,
  ) {
    return 'Geschiedenis · $label · $label2 · $duration min';
  }

  @override
  String get onlyReadingsWithTheSame =>
      'Alleen metingen met dezelfde context, houding en duur worden samen getoond.';

  @override
  String get noMatchingMeasurementsYet => 'Nog geen overeenkomende metingen.';

  @override
  String tostringasfixedMsRmssdTostringasfixed2Bpm(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return '$toStringAsFixed ms RMSSD · $toStringAsFixed2 bpm';
  }

  @override
  String get exportRrIntervalsCsv => 'RR-intervallen exporteren (CSV)';

  @override
  String get deleteMeasurement => 'Meting verwijderen';

  @override
  String get remindMeToMeasureHrv =>
      'Herinner me na de training aan een HRV-meting';

  @override
  String get appleHealthIsNoLonger =>
      'Apple Gezondheid is niet meer beschikbaar';

  @override
  String get later => 'Later';

  @override
  String get reconnect => 'Opnieuw koppelen';

  @override
  String get gripStrength => 'Knijpkracht';

  @override
  String get leftKg => 'Links (kg)';

  @override
  String get rightKg => 'Rechts (kg)';

  @override
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg) {
    return 'L $leftKg · R $rightKg kg';
  }

  @override
  String get notificationsAreOffYouCan =>
      'Meldingen staan uit. Je kunt nog steeds vanuit je training meten.';

  @override
  String get noRemindersFrom2200 => 'Geen herinneringen van 22:00 tot 07:00';

  @override
  String get aReminderThatWouldFall =>
      'Een herinnering die in deze tijd valt, wordt overgeslagen en niet naar de ochtend verplaatst.';

  @override
  String get remindersArriveQuietlyInThe =>
      'Herinneringen komen stil binnen in de meldingenlijst.';

  @override
  String get noForecastForThisDay => 'Geen voorspelling voor deze dag';

  @override
  String get fullscreen => 'Volledig scherm';

  @override
  String source(Object source) {
    return '● $source';
  }

  @override
  String get temperatureC => '● Temperatuur °C';

  @override
  String get rainMm => '▥ Regen mm';

  @override
  String get uvIndex => '— UV-index';

  @override
  String get closeFullscreenWeatherChart =>
      'Weergrafiek op volledig scherm sluiten';

  @override
  String get sleepStages => 'SLAAPFASEN';

  @override
  String get noStageTimelineForThis => 'Geen slaapfaseverloop voor deze nacht.';

  @override
  String round3(Object round) {
    return '$round%';
  }

  @override
  String get examplesOnlyCheckAndEnter =>
      'Alleen voorbeelden: controleer de waarden per portie op het etiket en vul ze in. Laat onbekende voedingsstoffen leeg; vul alleen 0 in als je het zeker weet.';

  @override
  String get nutritionStrategy => 'Voedingsstrategie';

  @override
  String get noPreWorkoutNutritionStrategy =>
      'Er is geen voedingsstrategie voor de training opgeslagen.';

  @override
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium) {
    return '$carbs g koolhydraten/u · $fluid ml/u · $sodium mg natrium/u';
  }

  @override
  String get forecastUpdatedReviewOrRecalculate =>
      'Voorspelling bijgewerkt — controleer de opgeslagen strategie of bereken haar opnieuw.';

  @override
  String strategySavedSavedat(Object savedAt) {
    return 'Strategie opgeslagen $savedAt';
  }

  @override
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  ) {
    return 'Totaal tijdens: $totalCarbs g koolhydraten · $totalFluid ml · $totalSodium mg natrium';
  }

  @override
  String every20MinAboutCarbs(Object carbs, Object fluid) {
    return 'Elke 20 min: ongeveer $carbs g koolhydraten en $fluid ml.';
  }

  @override
  String get packQuantitiesIncludeFullContainers =>
      'Meeneemhoeveelheden zijn hele verpakkingen; je hoeft niet alles op te maken.';

  @override
  String get workoutChangedReviewOrRecalculate =>
      'Training gewijzigd — controleer deze opgeslagen strategie of bereken haar opnieuw.';

  @override
  String get conditionsAndFeedingPlan => 'Omstandigheden en voedingsplan';

  @override
  String get editStrategy => 'Strategie bewerken';

  @override
  String get recalculate => 'Opnieuw berekenen';

  @override
  String get actualNutrition => 'Werkelijke voeding';

  @override
  String get someProductValuesAreUnknown =>
      'Sommige productwaarden zijn onbekend; de totalen zijn onvolledig.';

  @override
  String get logFoodAndFluids => 'Eten en drinken vastleggen';

  @override
  String get recordWhatYouActuallyHad =>
      'Leg vast wat je echt hebt gegeten en gedronken. De geplande inname wordt niet in dit logboek overgenomen.';

  @override
  String get elapsedMinutesIncludingStopsOptional =>
      'Verstreken minuten inclusief stops (optioneel)';

  @override
  String recordedDurationActivityMin(Object activity) {
    return 'Vastgelegde duur: $activity min';
  }

  @override
  String get compareWithSavedStrategy => 'Vergelijken met opgeslagen strategie';

  @override
  String get useMatchedSessionIfAvailable =>
      'Gekoppelde training gebruiken indien beschikbaar';

  @override
  String get noPlanComparison => 'Geen vergelijking met plan';

  @override
  String titleDate(Object title, Object date) {
    return '$title · $date';
  }

  @override
  String get linkedStrategyUnavailable =>
      'Gekoppelde strategie niet beschikbaar';

  @override
  String quantityName(Object quantity, Object name) {
    return '$quantity × $name';
  }

  @override
  String get removeIntake => 'Inname verwijderen';

  @override
  String get addFoodOrDrink => 'Eten of drinken toevoegen';

  @override
  String get iHadNoIntake => 'Ik heb niets ingenomen';

  @override
  String get giGutComfort => 'Maag-darmcomfort';

  @override
  String get whatWorkedSymptomsAccessProblems =>
      'Wat werkte / klachten / moeite met bereikbaarheid';

  @override
  String get saveDraft => 'Concept opslaan';

  @override
  String get skipLoggingThisActivity => 'Deze activiteit niet vastleggen';

  @override
  String get nutritionAndFluids => 'Voeding en vocht';

  @override
  String get productsToleranceAndMeasuredSweat =>
      'Producten, verdraagzaamheid en gemeten zweetverlies';

  @override
  String get postWorkoutIntakeReminder =>
      'Herinnering voor inname na de training';

  @override
  String get onceAfterARecentEndurance =>
      'Eén keer na een recente duurtraining; stille uren 22:00–08:00.';

  @override
  String get addHiloBpReport => 'Hilo-bloeddrukrapport toevoegen';

  @override
  String get readingPdfReportsIsOnly =>
      'Pdf-rapporten lezen kan alleen op iOS en macOS.';

  @override
  String get chooseAnotherReport => 'Ander rapport kiezen';

  @override
  String get biologicalAge => 'Biologische leeftijd';

  @override
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class) {
    return 'VO₂max $vo2max ml/kg/min · $vo2Class';
  }

  @override
  String get factorContributions => 'Bijdrage per factor';

  @override
  String estimatedRangeRoundRound2Years(Object round, Object round2) {
    return 'Geschat bereik $round–$round2 jaar. Een modelschatting, geen medische diagnose.';
  }

  @override
  String get noEnergyMeasurementsForThis =>
      'Geen energiemetingen voor deze dag';

  @override
  String get scanningStepOnTheScale =>
      'Zoeken… ga op de weegschaal staan zodra je klaar bent.';

  @override
  String waistWaistCmUpdateMonthly(Object waist) {
    return 'Taille: $waist cm — werk maandelijks bij in Profiel';
  }

  @override
  String get measuring => 'Meten…';

  @override
  String get tryAgain => 'Opnieuw proberen';

  @override
  String get systolic => 'Systolisch';

  @override
  String get diastolic => 'Diastolisch';

  @override
  String get heartRate => 'Hartslag';

  @override
  String get weight => 'Gewicht';

  @override
  String get bodyFat => 'Lichaamsvet';

  @override
  String get duration => 'Duur';

  @override
  String get deep => 'Diep';

  @override
  String get spo => 'SpO₂';

  @override
  String get activityName => 'Naam van de activiteit';

  @override
  String get sport => 'Sport';

  @override
  String get distance => 'Afstand';

  @override
  String get saved => 'Opgeslagen';

  @override
  String get connectionFailedCheckYourInternet =>
      'Verbinding mislukt. Controleer je internetverbinding.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Wachtwoord';

  @override
  String get passwordTooShort => 'Wachtwoord te kort';

  @override
  String get loginFailedCheckYourEmail =>
      'Inloggen mislukt. Controleer je e-mailadres en wachtwoord.';

  @override
  String get connectionFailedCheckYourCredentials =>
      'Verbinding mislukt. Controleer je inloggegevens en internetverbinding.';

  @override
  String get region => 'Regio';

  @override
  String get hiloPod => 'Hilo pod';

  @override
  String get hiloAccount => 'Hilo-account';

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
  String get renphoAccount => 'Renpho-account';

  @override
  String get garminConnectEmail => 'E-mailadres Garmin Connect';

  @override
  String get verifyMfaCode => 'MFA-code verifiëren';

  @override
  String get verificationCode => 'Verificatiecode';

  @override
  String errorE(Object e) {
    return 'Fout: $e';
  }

  @override
  String get noHiloPodFoundMake =>
      'Geen Hilo pod gevonden. Zorg dat hij opgeladen is en in de buurt ligt.';

  @override
  String scanFailedE(Object e) {
    return 'Zoeken mislukt: $e';
  }

  @override
  String get hiloPod2 => 'Hilo Pod';

  @override
  String get scanForPod => 'Pod zoeken';

  @override
  String get scanForPolarH10 => 'Polar H10 zoeken';

  @override
  String get couldNotReachPolarCheck =>
      'Polar is niet bereikbaar. Controleer je verbinding.';

  @override
  String get signInAndSendWorkout => 'Inloggen en training versturen';

  @override
  String get scanForScale => 'Weegschaal zoeken';

  @override
  String get passwordRequired => 'Wachtwoord vereist';

  @override
  String get enterYourPhoneNumberWith =>
      'Voer je telefoonnummer in (met landcode, bijv. +31…) en je Suunto-e-mailadres.';

  @override
  String get enterThePinFromThe => 'Voer de pincode uit de sms in.';

  @override
  String get incorrectPinPleaseTryAgain =>
      'Onjuiste pincode. Probeer het opnieuw.';

  @override
  String get phoneNumber => 'Telefoonnummer';

  @override
  String get suuntoAccountEmail => 'E-mailadres Suunto-account';

  @override
  String get enterPinFromSms => 'Pincode uit sms invoeren';

  @override
  String get verifyConnect => 'Verifiëren & koppelen';

  @override
  String get sendSmsCode => 'Sms-code versturen';

  @override
  String couldNotSavePreferencesE(Object e) {
    return 'Voorkeuren konden niet worden opgeslagen: $e';
  }

  @override
  String get mon => 'Ma';

  @override
  String get tue => 'Di';

  @override
  String get wed => 'Wo';

  @override
  String get thu => 'Do';

  @override
  String get fri => 'Vr';

  @override
  String get sat => 'Za';

  @override
  String get sun => 'Zo';

  @override
  String get male => 'Man';

  @override
  String get female => 'Vrouw';

  @override
  String get other => 'Anders';

  @override
  String get running => 'Hardlopen';

  @override
  String get trailRunning => 'Traillopen';

  @override
  String get cycling => 'Fietsen';

  @override
  String get swimming => 'Zwemmen';

  @override
  String get triathlon => 'Triatlon';

  @override
  String get hiking => 'Wandelen';

  @override
  String get rowing => 'Roeien';

  @override
  String get buildMyPlan => 'Mijn plan maken';

  @override
  String get keepAConsistentBedtimeAnd =>
      'Houd vaste bedtijden en opstatijden aan om je slaapritme te ondersteunen.';

  @override
  String get thisWorkoutHasNoSets => 'Deze training heeft geen sets.';

  @override
  String loadName(Object name) {
    return 'Belasting ($name)';
  }

  @override
  String get setLabel => 'Set';

  @override
  String get lowestReps => 'Minste herhalingen';

  @override
  String get highestReps => 'Meeste herhalingen';

  @override
  String get repsPerSide => 'Herhalingen per kant';

  @override
  String get fromReps => 'Van herhalingen';

  @override
  String get toReps => 'Tot herhalingen';

  @override
  String get addedLoad => 'Extra gewicht';

  @override
  String get assistance => 'Ondersteuning';

  @override
  String get tempoOptional => 'Tempo (optioneel)';

  @override
  String get notesOptional => 'Notities (optioneel)';

  @override
  String get enterTheRepetitionsDone =>
      'Voer het aantal uitgevoerde herhalingen in.';

  @override
  String plannedUnit(Object unit) {
    return 'Gepland $unit';
  }

  @override
  String get repsDone => 'Uitgevoerde herhalingen';

  @override
  String get resistance => 'Weerstand';

  @override
  String get implementsLabel => 'Hulpmiddelen';

  @override
  String get name => 'Naam';

  @override
  String get instructionsOptional => 'Instructies (optioneel)';

  @override
  String get remember => 'Onthouden';

  @override
  String get notSavedYet => 'Nog niet opgeslagen';

  @override
  String get saving => 'Opslaan…';

  @override
  String get couldNotSave => 'Opslaan mislukt';

  @override
  String get plannedValuesAreHintsNot =>
      'Geplande waarden zijn hints, geen resultaten. Tik op een set om hem vast te leggen.';

  @override
  String get completedAsPlanned => 'Voltooid zoals gepland';

  @override
  String get save => 'Opslaan';

  @override
  String get nameTheTemplate => 'Geef het sjabloon een naam.';

  @override
  String setN(Object n) {
    return 'Set $n';
  }

  @override
  String get changesApplyToThisWorkout =>
      'Wijzigingen gelden alleen voor deze training. Voltooide trainingen en andere sessies blijven zoals ze zijn.';

  @override
  String get saveForThisWorkout => 'Opslaan voor deze training';

  @override
  String knownForKnownOfOf(Object known, Object of) {
    return 'Bekend voor $known van $of sets met gewicht';
  }

  @override
  String get sessionEstimate => 'Schatting voor de training';

  @override
  String get calculatedRange => 'Berekend bereik';

  @override
  String get timedWork => 'Werk op tijd';

  @override
  String get strengthTraining => 'Krachttraining';

  @override
  String get theExercisesCouldNotBe =>
      'De oefeningen konden niet worden geladen.';

  @override
  String get resumeWorkout => 'Training hervatten';

  @override
  String get strengthWorkout => 'Krachttraining';

  @override
  String get untitledTemplate => 'Naamloos sjabloon';

  @override
  String get theRecordedExercisesCouldNot =>
      'De vastgelegde oefeningen konden niet worden geladen.';

  @override
  String get exercisesPerformed => 'Uitgevoerde oefeningen';

  @override
  String get comparedWithThePlanAs =>
      'Vergeleken met het plan zoals het was toen het vastleggen begon.';

  @override
  String topWorkingLoadName(Object name) {
    return 'Hoogste werkgewicht ($name)';
  }

  @override
  String get estimated1rmMiddleOfRange => 'Geschat 1RM, midden van het bereik';

  @override
  String get noLoggedSessionsYet => 'Nog geen vastgelegde trainingen.';

  @override
  String get noRadarFramesAvailable => 'Geen radarbeelden beschikbaar';

  @override
  String get playRadar => 'Radar afspelen';

  @override
  String get pauseRadar => 'Radar pauzeren';

  @override
  String get high => 'Hoog';

  @override
  String get clear => 'Helder';

  @override
  String get bodyweight => 'Lichaamsgewicht';

  @override
  String get resistance2 => 'Weerstand —';

  @override
  String assistUnit(Object unit) {
    return 'Ondersteuning $unit';
  }

  @override
  String get reps2 => 'Herhalingen —';

  @override
  String get notRecorded => 'Niet vastgelegd';

  @override
  String get skipped => 'Overgeslagen';

  @override
  String get health => 'Gezondheid';

  @override
  String get manual => 'Handmatig';

  @override
  String expandName(Object name) {
    return '$name uitklappen';
  }

  @override
  String get open => 'Openen';

  @override
  String get noScalePaired => 'Geen weegschaal gekoppeld';

  @override
  String get paired => 'Gekoppeld';

  @override
  String get change => 'Wijzigen';

  @override
  String get noCuffPaired => 'Geen manchet gekoppeld';

  @override
  String get noPolarH10FoundWear =>
      'Geen Polar H10 gevonden. Draag de borstband, maak de elektroden nat en controleer dat geen andere app beide Bluetooth-verbindingen gebruikt.';

  @override
  String get enterMinutesSinceTrainingEnded =>
      'Voer de minuten sinds het einde van de training in, van 0 tot 1440.';

  @override
  String get timingFollowsYourWorkout => 'Het tijdstip volgt je training.';

  @override
  String get recordingStayStill => 'Opname · blijf stil';

  @override
  String get meanHrBpm => 'Gemiddelde hartslag · bpm';

  @override
  String get pairAPolarH10First => 'Koppel eerst een Polar H10.';

  @override
  String get around30MinutesAfterTraining =>
      'Ongeveer 30 minuten na de training, als de training op tijd beschikbaar is.';

  @override
  String get reminderDiagnostics => 'Diagnose van herinneringen';

  @override
  String get forecast => 'Voorspelling';

  @override
  String forecastRange(int count) {
    return 'Gearceerd: bereik van $count voorspellingen';
  }

  @override
  String get enterAName => 'Voer een naam in';

  @override
  String get enterAValidAmount => 'Voer een geldige hoeveelheid in';

  @override
  String get enterAPositiveAmount => 'Voer een positieve hoeveelheid in';

  @override
  String get maximum120GH => 'Maximaal 120 g/u';

  @override
  String get carbohydrateTargetGH => 'Koolhydraatdoel g/u';

  @override
  String get fluidTargetMlH => 'Vochtdoel ml/u';

  @override
  String get sodiumTargetMgHNot => 'Natriumdoel mg/u (geen zout)';

  @override
  String get surfaceFeedingAccess => 'Ondergrond / bereikbaarheid voeding';

  @override
  String get expectedAscentM => 'Verwachte stijging m';

  @override
  String get expectedAltitudeM => 'Verwachte hoogte m';

  @override
  String get humidity => 'Luchtvochtigheid %';

  @override
  String get windKmH => 'Wind km/u';

  @override
  String get dayForecast => 'Dagvoorspelling';

  @override
  String get enteredConditions => 'Ingevoerde omstandigheden';

  @override
  String get productFoodName => 'Product / naam van het voedsel';

  @override
  String get servingsQuantity => 'Porties / hoeveelheid';

  @override
  String get when => 'Wanneer';

  @override
  String get carbohydrateGServing => 'Koolhydraten g / portie';

  @override
  String get fluidMlServing => 'Vocht ml / portie';

  @override
  String get caffeineMgServing => 'Cafeïne mg / portie';

  @override
  String get proteinGServing => 'Eiwit g / portie';

  @override
  String get gel => 'Gel';

  @override
  String get water => 'Water';

  @override
  String get sportsDrink => 'Sportdrank';

  @override
  String get bar => 'Reep';

  @override
  String get finishIntakeLog => 'Innamelogboek afronden';

  @override
  String get importing => 'Importeren…';

  @override
  String importNewreadings(Object newReadings) {
    return '$newReadings importeren';
  }

  @override
  String get reading => 'Lezen…';

  @override
  String get chooseReportPdf => 'Rapport kiezen (pdf)';

  @override
  String get yourTrainingHistoryIsReady => 'Je trainingsgeschiedenis is klaar';

  @override
  String get importingYourTrainingHistory =>
      'Je trainingsgeschiedenis wordt geïmporteerd';

  @override
  String get stopImport => 'Import stoppen';

  @override
  String get dismiss => 'Sluiten';

  @override
  String get openai => 'OpenAI';

  @override
  String get appleIntelligence => 'Apple Intelligence';

  @override
  String get nonAiBriefing => 'Briefing zonder AI';

  @override
  String get noBriefing => 'Geen briefing';

  @override
  String get ruleBasedSummaryFromYour =>
      'Samenvatting op basis van regels uit je gezondheidsgegevens — geen API-aanroepen';

  @override
  String get hideTheBriefingCard => 'De briefingkaart verbergen';

  @override
  String get flutter => 'Flutter';

  @override
  String get stateManagement => 'Statusbeheer';

  @override
  String get bluetoothLe => 'Bluetooth LE';

  @override
  String get interactiveMaps => 'Interactieve kaarten';

  @override
  String get chartsGraphs => 'Grafieken & diagrammen';

  @override
  String get secureCredentialStorage => 'Veilige opslag van inloggegevens';

  @override
  String get markdownRendering => 'Markdown-weergave';

  @override
  String get appleOnDeviceAi => 'Apple AI op het apparaat';

  @override
  String get cryptography => 'Cryptografie';

  @override
  String get appleHealthHealthConnect => 'Apple Gezondheid & Health Connect';

  @override
  String get runtimePermissions => 'Toestemmingen tijdens gebruik';

  @override
  String get shareExport => 'Delen & exporteren';

  @override
  String get openUrls => 'URL\'s openen';

  @override
  String get internationalisation => 'Internationalisering';

  @override
  String get utilities => 'Hulpmiddelen';

  @override
  String get icons => 'Pictogrammen';

  @override
  String get fjelia => 'Fjelia';

  @override
  String get fjeliaFeedback => 'Feedback over Fjelia';

  @override
  String get couldNotSendTheReport =>
      'De melding kon niet worden verstuurd. Je tekst staat er nog. Probeer het opnieuw.';

  @override
  String get yourEmail => 'Je e-mailadres';

  @override
  String get enterAValidEmailAddress => 'Voer een geldig e-mailadres in.';

  @override
  String get subject => 'Onderwerp';

  @override
  String get sending => 'Versturen…';

  @override
  String get sendReport => 'Melding versturen';

  @override
  String get sleepRecovery => 'Slaap & herstel';

  @override
  String get activitiesTraining => 'Activiteiten & training';

  @override
  String get bodyWellness => 'Lichaam & welzijn';

  @override
  String get hilo => 'Hilo';

  @override
  String get hiloBle => 'Hilo BLE';

  @override
  String get garminApi => 'Garmin (API)';

  @override
  String get renphoScale => 'Renpho-weegschaal';

  @override
  String get connected => 'Gekoppeld';

  @override
  String get notConnected => 'Niet gekoppeld';

  @override
  String get manage => 'Beheren';

  @override
  String get connect => 'Koppelen';

  @override
  String get habits => 'Gewoonten';

  @override
  String get smokingAlcohol => 'Roken, alcohol';

  @override
  String get clinicalLab => 'Laboratorium';

  @override
  String get hba1cLipidsKidney => 'HbA1c, lipiden, nieren';

  @override
  String get sex => 'Geslacht';

  @override
  String get smoking => 'Roken';

  @override
  String get never => 'Nooit';

  @override
  String get former => 'Vroeger';

  @override
  String get current => 'Nu';

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
      'Optioneel. Plannen en tempo-adviezen gebruiken dit; de hoogtemeters hierboven bepalen ook de training.';

  @override
  String get addRaceGoal2 => 'Wedstrijddoel toevoegen';

  @override
  String get editRaceGoal => 'Wedstrijddoel bewerken';

  @override
  String get trailRunning2 => 'Traillopen';

  @override
  String get roadCycling => 'Wegwielrennen';

  @override
  String get gravel => 'Gravel';

  @override
  String get indoorRowing => 'Indoor roeien';

  @override
  String get selectDate => 'Datum kiezen';

  @override
  String get committed => 'Vast';

  @override
  String get flexible => 'Flexibel';

  @override
  String get notGoing => 'Ga niet';

  @override
  String get notSaid => 'Niet opgegeven';

  @override
  String get finish => 'Uitlopen';

  @override
  String get saveGoal => 'Doel opslaan';

  @override
  String get exportAllRecordedWorkoutsAs =>
      'Alle vastgelegde trainingen als spreadsheet exporteren.';

  @override
  String get backupsIncludeYourHealthData =>
      'Back-ups bevatten je gezondheidsgegevens, trainingsplannen en profielinstellingen. Inloggegevens worden niet meegenomen. Herstellen vervangt de lokale gegevens.';

  @override
  String get trail => 'Trail';

  @override
  String get inlineSkating => 'Inline-skaten';

  @override
  String get nordicClassic => 'Langlaufen klassiek';

  @override
  String get skateSkiing => 'Skaten (langlauf)';

  @override
  String get strength => 'Kracht';

  @override
  String get walking => 'Wandelen';

  @override
  String get yoga => 'Yoga';

  @override
  String get skiing => 'Skiën';

  @override
  String get climbing => 'Klimmen';

  @override
  String get monday => 'Maandag';

  @override
  String get sunday => 'Zondag';

  @override
  String get month => 'Maand';

  @override
  String get week => 'Week';

  @override
  String get list => 'Lijst';

  @override
  String get train => 'Training';

  @override
  String get restDay => 'Rust';

  @override
  String get kilogramsKg => 'Kilogram (kg)';

  @override
  String get poundsLb => 'Pond (lb)';

  @override
  String get regenerateWorkouts => 'Trainingen opnieuw genereren';

  @override
  String get starting => 'Starten';

  @override
  String get allPlannedWorkoutsDeleted =>
      'Alle geplande trainingen verwijderd.';

  @override
  String get searching => 'Zoeken…';

  @override
  String get searchCity => 'Stad zoeken';

  @override
  String get fixedLocationSavedWeatherWill =>
      'Vaste locatie opgeslagen. Het weer wordt vernieuwd.';

  @override
  String get locationDisabledThePlanWeather =>
      'Locatie uitgeschakeld. De weerkaart in het plan is verborgen.';

  @override
  String locationSetToName(Object name) {
    return 'Locatie ingesteld op $name';
  }

  @override
  String get notEnoughDaytimeAndNighttime =>
      'Niet genoeg metingen overdag en \'s nachts';

  @override
  String get onlyTheWeightWasReceived =>
      'Alleen het gewicht is ontvangen. Voor lichaamsvet, spieren en de andere waarden ga je blootsvoets op de metalen elektroden staan tot de weegschaal klaar is.';

  @override
  String get addYourWaistInProfile =>
      'Voeg je taille toe in Profiel voor visceraal vet.';

  @override
  String get manualActivity => 'Handmatige activiteit';

  @override
  String get theseCredentialsAreStoredEncrypted =>
      'Deze inloggegevens worden versleuteld op je apparaat opgeslagen (iOS-sleutelhanger / Android Keystore). Ze worden nooit naar een andere server dan die van Hilo gestuurd.';

  @override
  String get corosCredentialsAreStoredEncrypted =>
      'Coros-inloggegevens worden versleuteld op je apparaat opgeslagen. Fjelia leest de gegevens rechtstreeks uit de Coros-cloud-API. Dit is dezelfde API als die van de Coros Training Hub-webapp.';

  @override
  String get connectAnyCombinationYouCan =>
      'Koppel elke gewenste combinatie — je kunt later altijd meer toevoegen in Instellingen.';

  @override
  String get garminCredentialsAreStoredEncrypted =>
      'Garmin-inloggegevens worden versleuteld op je apparaat opgeslagen. Fjelia gebruikt de onofficiële Garmin Connect-API – dezelfde aanpak als veel community-apps.';

  @override
  String get enterTheVerificationCode => 'Voer de verificatiecode in';

  @override
  String get appleHealthDataAccess =>
      'Fjelia leest je gezondheidsgegevens uit Apple Gezondheid. Met je toestemming kan het ook gesynchroniseerde gegevens naar Apple Gezondheid schrijven. Beheer de toegang in de instellingen van je apparaat.';

  @override
  String get scanAgain => 'Opnieuw zoeken';

  @override
  String get wearTheHiloBandDuring =>
      'Draag de Hilo-band tijdens het slapen voor continue bloeddrukmeting. De gegevens worden elke ochtend automatisch gesynchroniseerd als je de app opent.';

  @override
  String get noPolarH10FoundWear2 =>
      'Geen Polar H10 gevonden. Draag de borstband met vochtige elektroden, zorg dat geen andere app (of horloge) ermee verbonden is en zoek opnieuw.';

  @override
  String get wearTheStrapWithMoist2 =>
      'Draag de borstband met vochtige elektroden voordat je zoekt. Meet later via + → Polar H10 HRV-meting; de resultaten verschijnen naast je nachtelijke HRV.';

  @override
  String get signedInPlannedWorkoutsCan =>
      'Ingelogd. Geplande trainingen kunnen nu naar Polar worden gestuurd. Oudere trainingen worden geïmporteerd bij de volgende volledige synchronisatie van de geschiedenis.';

  @override
  String get saveYourPolarFlowLogin =>
      'Sla je Polar Flow-login op om geplande trainingen te versturen en trainingen ouder dan 30 dagen te importeren. Hij blijft in de sleutelhanger van dit apparaat en wordt alleen naar Polar gestuurd. Stuur een training vanuit het planblad en synchroniseer Polar Flow daarna met je horloge. Controleer of je hartslagzones in Polar overeenkomen met Fjelia.';

  @override
  String get signInToSendThis =>
      'Log in om deze training naar je Polar Flow-kalender te sturen. Je login blijft in de sleutelhanger van dit apparaat en wordt alleen naar Polar gestuurd. Synchroniseer Polar Flow na het versturen met je horloge.';

  @override
  String get checkAndSave => 'Controleren en opslaan';

  @override
  String get noScaleFoundStepOn =>
      'Geen weegschaal gevonden. Ga op de weegschaal staan zodat hij wakker wordt en zoek opnieuw.';

  @override
  String get stepOnTheScaleBefore =>
      'Ga op de weegschaal staan voordat je zoekt, zodat hij wakker wordt. Meet later via + → RENPHO-weegschaal.';

  @override
  String get renphoCredentialsAreStoredEncrypted =>
      'Renpho-inloggegevens worden versleuteld op je apparaat opgeslagen. Fjelia communiceert rechtstreeks met de Renpho-cloud-API.';

  @override
  String get couldNotSendSmsCheck =>
      'Sms kon niet worden verstuurd. Controleer je telefoonnummer en internetverbinding.';

  @override
  String get theEmailIsUsedFor =>
      'Het e-mailadres wordt gebruikt om verzoeken veilig te ondertekenen en wordt niet naar Suunto-servers gestuurd.';

  @override
  String get suuntoUsesSmsVerificationSame =>
      'Suunto gebruikt verificatie per sms (net als de Suunto-app). Er wordt een eenmalige pincode naar je telefoon gestuurd. Je inloggegevens worden alleen versleuteld op het apparaat opgeslagen.';

  @override
  String get tellUsAboutYourRace =>
      'Vertel ons over je wedstrijd en je schema. Fjelia maakt nu je plan en bepaalt je niveau uit je eerdere activiteiten (Garmin, Suunto, Polar, COROS, Apple Gezondheid) zodra die zijn gedownload.';

  @override
  String get noAccountConnectedSoFjelia =>
      'Er is geen account gekoppeld, dus Fjelia heeft geen geschiedenis om van te leren. Koppel Garmin, Suunto, Polar, COROS of Apple Gezondheid, dan bepaalt je echte training het niveau.';

  @override
  String get yourPastActivitiesAreStill =>
      'Je eerdere activiteiten worden nog geïmporteerd. Je kunt je plan nu al maken — het wordt automatisch verfijnd als de import klaar is.';

  @override
  String get buildingYourPlan => 'Je plan wordt gemaakt…';

  @override
  String get saveContinue => 'Opslaan & doorgaan';

  @override
  String get addYourMainPriorityA =>
      'Voeg je hoofdwedstrijd toe (prioriteit A). Het plan wordt daarop afgestemd: basis, opbouw, piek en afbouw. Zonder wedstrijddoel wordt nog geen plan gemaakt.';

  @override
  String get noMeasurementsYet => 'Nog geen metingen';

  @override
  String get date => 'Datum';

  @override
  String deepSleepIsBelowOptimal(Object round) {
    return 'Diepe slaap is lager dan optimaal ($round%). Vermijd alcohol en zware maaltijden 3 uur voor het slapengaan.';
  }

  @override
  String get finishWithSetsOpen => 'Afronden met open sets?';

  @override
  String get completeThePlannedWorkout => 'Geplande training voltooien?';

  @override
  String get marksThePlannedSessionAs =>
      'Markeert de geplande training als gedaan met deze workout.';

  @override
  String get discardThisWorkout => 'Deze training verwerpen?';

  @override
  String get removesTheWorkoutAndEvery =>
      'Verwijdert de training en alle sets die erin zijn vastgelegd.';

  @override
  String assistanceName(Object name) {
    return 'Ondersteuning ($name)';
  }

  @override
  String get enterSecondsOrMSs => 'Voer seconden of m:ss in.';

  @override
  String get enterTheLoadAsA => 'Voer het gewicht als getal in.';

  @override
  String get loadCannotBeNegative => 'Het gewicht kan niet negatief zijn.';

  @override
  String get enterTheEffortValue => 'Voer de inspanningswaarde in.';

  @override
  String get nameTheExercise => 'Geef de oefening een naam.';

  @override
  String get atLeastOneImplement => 'Minstens één hulpmiddel.';

  @override
  String get anIncrementMustBePositive => 'Een stap moet positief zijn.';

  @override
  String get enterAPositiveStep => 'Voer een positieve stap in.';

  @override
  String get repsInReserve => 'Herhalingen in reserve';

  @override
  String get loadPerImplement => 'Gewicht per hulpmiddel';

  @override
  String get restAfterThisSet => 'Rust na deze set';

  @override
  String get enterHowLongTheSet => 'Voer in hoe lang de set duurde.';

  @override
  String get repsDonePerSide => 'Uitgevoerde herhalingen per kant';

  @override
  String plannedRepminRepmax(Object repMin, Object repMax) {
    return 'Gepland $repMin–$repMax';
  }

  @override
  String get restTakenBeforeTheNext => 'Rust vóór de volgende set';

  @override
  String get equipment => 'Materiaal';

  @override
  String get implementsUsedTogether => 'Samen gebruikte hulpmiddelen';

  @override
  String get smallestLoadStepOptional => 'Kleinste belastingsstap (optioneel)';

  @override
  String get theSmallestChangeYourPlates =>
      'De kleinste verandering die je schijven, dumbbells of machine toelaten, onthouden voor dit materiaal.';

  @override
  String get loadStep => 'Belastingsstap';

  @override
  String get finishWithIncompleteData => 'Afronden met onvolledige gegevens?';

  @override
  String get leaveWithoutSaving => 'Verlaten zonder opslaan?';

  @override
  String get theLastChangeCouldNot =>
      'De laatste wijziging kon niet worden opgeslagen.';

  @override
  String get comparedWithAPlanChosen =>
      'Vergeleken met een plan dat na de training is gekozen. Geplande waarden zijn hints, geen resultaten.';

  @override
  String get lastSet => 'Laatste set';

  @override
  String get templateName => 'Naam van het sjabloon';

  @override
  String get betweenExercises => 'Tussen oefeningen';

  @override
  String get betweenRounds => 'Tussen rondes';

  @override
  String get discardChanges => 'Wijzigingen verwerpen?';

  @override
  String get yourEditsToThisWorkout =>
      'Je wijzigingen aan deze training zijn niet opgeslagen.';

  @override
  String get estimatedDuration => 'Geschatte duur';

  @override
  String get workingSets => 'Werksets';

  @override
  String get estimatedExternalVolume => 'Geschat extern volume';

  @override
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion) {
    return 'Gewicht verhoogd van $unit naar $unit2 na je beoordeling (regel v$ruleVersion).';
  }

  @override
  String get thePlannedWorkoutHasNo =>
      'De geplande training heeft geen oefeningen om vast te leggen.';

  @override
  String get completedSets => 'Voltooide sets';

  @override
  String get knownExternalVolume => 'Bekend extern volume';

  @override
  String get updateStrengthSessions2 => 'Krachttrainingen bijwerken?';

  @override
  String get upcomingSessionsArePlannedAgain =>
      'Komende trainingen worden vanaf vandaag opnieuw gepland: kracht volgt op elke krachtdag je wedstrijddoelen, met wisselende trainingen. Voltooide en overgeslagen trainingen blijven; oefeningen die je in een komende krachttraining hebt gewijzigd, worden vervangen.';

  @override
  String get thisSessionUsesAnEarlier =>
      'Deze training gebruikt een ouder krachtsjabloon. Bijgewerkte plannen variëren kracht per fase en wedstrijddoel en gebruiken elke krachtdag.';

  @override
  String get estimated1rmUsesEpleyAnd =>
      'Het geschatte 1RM gebruikt Epley en Brzycki op voltooide werksets van 1–10 herhalingen met bekend gewicht, weergegeven als het bereik daartussen. Het is een schatting, geen geteste maximale waarde.';

  @override
  String get localWeather => 'Lokaal weer';

  @override
  String get today => 'Vandaag';

  @override
  String get low => 'Laag';

  @override
  String get moderate => 'Matig';

  @override
  String get overcast => 'Bewolkt';

  @override
  String get partlyCloudy => 'Half bewolkt';

  @override
  String collapseName(Object name) {
    return '$name inklappen';
  }

  @override
  String get variableLoads => 'Wisselende gewichten';

  @override
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  ) {
    return 'Regel v$strengthProgressionRuleVersion: de laatste $strengthProgressionMinSessions vergelijkbare trainingen, elke set uitgevoerd aan de bovenkant van het herhalingsdoel, met vastgelegde inspanning en niet zwaarder dan bedoeld. $reason';
  }

  @override
  String get stepOnYourScaleBefore =>
      'Ga op je weegschaal staan voordat je zoekt';

  @override
  String get scanning => 'Zoeken…';

  @override
  String get pair => 'Koppelen';

  @override
  String get selectYourAktiiaPWristband =>
      'Kies je AKTIIA P…-polsband. Leg hem op de lader om hem wakker te maken als hij niet zichtbaar is.';

  @override
  String get measurementInterruptedWhileTheApp =>
      'De meting is onderbroken terwijl de app op de achtergrond stond. Herhaal haar.';

  @override
  String get noRecentRrDataWith =>
      'Geen recente RR-gegevens met goed contact. Controleer de borstband en herhaal de meting.';

  @override
  String get settlingStayStill => 'Tot rust komen · blijf stil';

  @override
  String get deleteSpotHrvMeasurement => 'Momentane HRV-meting verwijderen?';

  @override
  String get thisRemovesTheRecordingAnd =>
      'Hiermee worden de opname en de ruwe RR-intervallen verwijderd.';

  @override
  String get appleHealthStoppedAnsweringSo =>
      'Apple Gezondheid reageerde niet meer, dus Fjelia heeft de koppeling verbroken en leest of schrijft geen gezondheidsgegevens meer.\n\nSta Fjelia opnieuw toe via Instellingen → Gezondheid → Gegevenstoegang en apparaten → Fjelia en koppel Apple Gezondheid daarna opnieuw.';

  @override
  String get thisRemovesTheSelectedGrip =>
      'Hiermee wordt de gekozen knijpkrachtmeting verwijderd.';

  @override
  String get hideReminderDiagnostics => 'Diagnose van herinneringen verbergen';

  @override
  String get loading => 'Laden…';

  @override
  String get touchTheChartForDetails => 'Raak de grafiek aan voor details';

  @override
  String get indoor => 'Binnen';

  @override
  String get road => 'Weg';

  @override
  String get technical => 'Technisch';

  @override
  String get snow => 'Sneeuw';

  @override
  String get pool => 'Zwembad';

  @override
  String get openWater => 'Open water';

  @override
  String get ambientTemperatureC => 'Omgevingstemperatuur °C';

  @override
  String carryAboutGelsGelsGelcarbs(
    Object gels,
    Object gelCarbs,
    Object bottles,
    Object bottleMl,
    Object drinkCarbs,
  ) {
    return 'Neem ongeveer $gels gels mee ($gelCarbs g koolhydraten per stuk) + $bottles × flessen van $bottleMl ml. $drinkCarbs g koolhydraten komt uit de sportdrank.';
  }

  @override
  String get intakeNotRecorded => 'Inname niet vastgelegd';

  @override
  String get loggingDeclinedIntakeUnknown =>
      'Vastleggen geweigerd — inname onbekend';

  @override
  String get confirmedNoIntake => 'Bevestigd: geen inname';

  @override
  String get draft => 'Concept · ';

  @override
  String get actualIntakePerServing => 'Werkelijke inname · per portie';

  @override
  String get minuteIntoWorkoutDuringOnly =>
      'Minuut in de training (alleen tijdens, optioneel)';

  @override
  String get sodiumMgServingNotSalt => 'Natrium mg / portie (geen zout)';

  @override
  String get comfortable => 'Prettig';

  @override
  String get mildSymptoms => 'Lichte klachten';

  @override
  String get moderateSymptoms => 'Matige klachten';

  @override
  String get severeSymptoms => 'Ernstige klachten';

  @override
  String get personalNutritionSettings => 'Persoonlijke voedingsinstellingen';

  @override
  String get practisedCarbohydrateToleranceGH =>
      'Getrainde koolhydraattolerantie g/u (tot 120)';

  @override
  String get exportTheMonthlyReportAs =>
      'Exporteer het maandrapport als pdf in de Hilo-app en kies het hier. Alleen de metingen worden geïmporteerd; naam, e-mailadres en lichaamsgegevens in het rapport worden genegeerd.';

  @override
  String get nothingNewAllReadingsWere =>
      'Niets nieuws: alle metingen waren al opgeslagen.';

  @override
  String get historyImportIncomplete => 'Import van geschiedenis onvolledig';

  @override
  String get youCanKeepUsingFjelia =>
      'Je kunt Fjelia blijven gebruiken, maar houd de app open: iOS pauzeert de import als de app op de achtergrond staat, en hij gaat verder als je Fjelia weer opent. Je plan wordt gekalibreerd als de import klaar is.';

  @override
  String get addYourBirthYearIn =>
      'Voeg je geboortejaar toe in Instellingen → Profiel om je schatting te zien.';

  @override
  String get fitnessAge => 'Fitnessleeftijd';

  @override
  String get estLifespan => 'Gesch. levensduur';

  @override
  String get delta => 'Verschil';

  @override
  String couldNotOpenKey(Object key) {
    return '$key kon niet worden geopend';
  }

  @override
  String get appleIntelligenceIsNotAvailable =>
      'Apple Intelligence is niet beschikbaar op dit apparaat. Gebruik Free AI of kies een andere aanbieder.';

  @override
  String get personalisedMorningLunchAfternoonEvening =>
      'Persoonlijke samenvatting voor ochtend/middag/namiddag/avond';

  @override
  String get enterASubject => 'Voer een onderwerp in.';

  @override
  String get message => 'Bericht';

  @override
  String get enterAMessageOfAt => 'Voer een bericht van minstens 10 tekens in.';

  @override
  String get garminConnect => 'Garmin Connect';

  @override
  String get hiloBloodPressure => 'Hilo (bloeddruk)';

  @override
  String get renphoBodyScale => 'Renpho (weegschaal)';

  @override
  String get hiloPodCuff => 'Hilo pod / manchet';

  @override
  String disconnectLabel(Object label) {
    return '$label ontkoppelen?';
  }

  @override
  String get yourSavedMeasurementsWillRemain =>
      'Je opgeslagen metingen blijven op dit apparaat.';

  @override
  String get notEnoughRecentHeartRate =>
      'Niet genoeg recente hartslaggegevens om de zones aan te passen.';

  @override
  String get aerobicBase => 'Aerobe basis';

  @override
  String get tempo => 'Tempo';

  @override
  String get lactateThreshold => 'Lactaatdrempel';

  @override
  String get birthYearHeightWaist => 'Geboortejaar, lengte, taille';

  @override
  String get enterAValidValue => 'Voer een geldige waarde in';

  @override
  String get birthYear => 'Geboortejaar';

  @override
  String get height => 'Lengte';

  @override
  String get waist => 'Taille';

  @override
  String get yearsSinceQuit => 'Jaren sinds stoppen';

  @override
  String get cigarettesPerDay => 'Sigaretten per dag';

  @override
  String get standardDrinksPerMonth => 'Standaardglazen per maand';

  @override
  String get enterAValidNumber => 'Voer een geldig getal in';

  @override
  String get enterARaceName => 'Voer een wedstrijdnaam in';

  @override
  String get useHMmOrH =>
      'Gebruik u:mm of u:mm:ss, een tijd die je echt kunt lopen';

  @override
  String get flexibleThePlanMayDrop =>
      'Flexibel: het plan kan dit evenement laten vallen als het botst met een belangrijker evenement.';

  @override
  String get selectARaceDate => 'Kies een wedstrijddatum';

  @override
  String thatIsTenTimesOr(Object likely) {
    return 'Dat is tien keer (of een tiende van) de gebruikelijke $likely km. $likely km gebruiken?';
  }

  @override
  String get addGoal => 'Doel toevoegen';

  @override
  String get restoreFailed => 'Herstellen mislukt';

  @override
  String get replaceLocalData => 'Lokale gegevens vervangen?';

  @override
  String get restoringThisBackupReplacesAll =>
      'Het herstellen van deze back-up vervangt alle lokale gezondheids- en trainingsgegevens. Bestaande inloggegevens blijven behouden.';

  @override
  String get openingBackupZip => 'Back-up-zip openen';

  @override
  String get addAFutureRaceGoal =>
      'Voeg eerst een toekomstig wedstrijddoel toe.';

  @override
  String get deleteAllWorkouts2 => 'Alle trainingen verwijderen?';

  @override
  String get thisDeletesPlannedWorkoutsOn =>
      'Hiermee worden geplande trainingen op deze telefoon en op je gekoppelde horlogeplatform verwijderd. Voltooide activiteiten blijven bewaard.';

  @override
  String get regenerateWorkouts2 => 'Trainingen opnieuw genereren?';

  @override
  String get noRaceGoalsYetAdd =>
      'Nog geen wedstrijddoelen. Voeg er een toe of synchroniseer vanuit Garmin.';

  @override
  String get deleteRaceGoal => 'Wedstrijddoel verwijderen?';

  @override
  String deletingFailedFailure(Object failure) {
    return 'Verwijderen mislukt: $failure';
  }

  @override
  String allPlannedWorkoutsDeletedRemoved(Object removed) {
    return 'Alle geplande trainingen verwijderd. Verwijderd van je platforms: $removed.';
  }

  @override
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return 'Huidige locatie wordt gebruikt: $toStringAsFixed, $toStringAsFixed2';
  }

  @override
  String get typeSleep => 'Slaap';

  @override
  String get typeBloodPressure => 'Bloeddruk';

  @override
  String get addHiloBpReportPdf => 'Hilo-bloeddrukrapport toevoegen (pdf)';

  @override
  String get hiloCuffBle => 'Hilo-manchet (BLE)';

  @override
  String get typeSpo2 => 'SpO₂ / pulsoximeter';

  @override
  String get typeWeightScale => 'Weegschaal';

  @override
  String get polarH10HrvMeasurement => 'Polar H10 HRV-meting';

  @override
  String samplingWouldStartMinutes(Object minutes) {
    return 'De meting zou ongeveer $minutes min na het einde van je training beginnen.';
  }

  @override
  String samplingStartedMinutes(Object minutes) {
    return 'De meting begon $minutes min na het einde van je training.';
  }

  @override
  String get unknown => 'Onbekend';

  @override
  String get before => 'Voor';

  @override
  String get during => 'Tijdens';

  @override
  String get after => 'Na';

  @override
  String get enumWarmUp => 'Warming-up';

  @override
  String get enumWorking => 'Werkset';

  @override
  String get enumBackOff => 'Back-off';

  @override
  String get enumTechnique => 'Techniek';

  @override
  String get enumExternalLoad => 'Extern gewicht';

  @override
  String get enumBandResistance => 'Band / weerstand';

  @override
  String get enumTotalLoad => 'Totaal gewicht';

  @override
  String get enumPerImplement => 'Per hulpmiddel';

  @override
  String get enumOneImplement => 'Eén hulpmiddel';

  @override
  String get enumBothSides => 'Beide kanten';

  @override
  String get enumAlternatingTotalReps => 'Afwisselend, totaal herhalingen';

  @override
  String get enumPartial => 'Gedeeltelijk';

  @override
  String get enumFailed => 'Mislukt';

  @override
  String get enumStraightSets => 'Gewone sets';

  @override
  String get enumSuperset => 'Superset';

  @override
  String get enumCircuit => 'Circuit';

  @override
  String get enumRir => 'RIR';

  @override
  String get enumRpe110 => 'RPE 1–10';

  @override
  String get enumBeforeTraining => 'Voor de training';

  @override
  String get enumAfterTraining => 'Na de training';

  @override
  String get enumResting => 'In rust';

  @override
  String get enumSeated => 'Zittend';

  @override
  String get enumLyingDown => 'Liggend';

  @override
  String get duringRoutineGelsAreNot =>
      'Tijdens: voor deze korte/rustige training zijn geen gels nodig. Drink op dorst.';

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      'Tijdens: verdeel koolhydraten en drinken over kleine, regelmatige momenten. Tel koolhydraten uit drank mee in hetzelfde totaal als gels en eten.';

  @override
  String get fluidIsAnEditableStarting =>
      'Vocht is een aanpasbare beginschatting, geen quotum. Ga uit van dorst, geoefende inname en gemeten zweetverlies; dwing jezelf niet tot extra water.';

  @override
  String get afterHaveCarbohydrateAndA =>
      'Na: neem koolhydraten en een maaltijd met eiwit. Geef voorrang aan bijtanken en rehydrateren als er snel weer een training komt.';

  @override
  String get swimmingPlaceALabelledBottle =>
      'Zwemmen: zet een gelabelde fles op de badrand en gebruik de pauzes tussen sets om te drinken of te eten. De omstandigheden in het zwembad kunnen afwijken van het weer buiten.';

  @override
  String get runningCarryAccessibleGelsFlasks =>
      'Hardlopen: neem goed bereikbare gels/flesjes mee of plan voeding bij de verzorgingsposten; oefen dezelfde producten en timing vóór de wedstrijd.';

  @override
  String get servingSizesAndToleranceMust =>
      'Portiegroottes en tolerantie moeten positief zijn.';

  @override
  String get enterFiniteNonNegativeMeasurements =>
      'Voer eindige, niet-negatieve metingen in.';

  @override
  String get targetsMustBeFiniteAnd =>
      'Doelen moeten eindig en niet-negatief zijn.';

  @override
  String get conditionsMustBeFiniteOr =>
      'Omstandigheden moeten eindig of onbekend zijn.';

  @override
  String get humidityMustBeBetween0 =>
      'Luchtvochtigheid moet tussen 0 en 100% liggen.';

  @override
  String get noIntakeCannotIncludeFood =>
      '“Geen inname” kan geen eten of drinken bevatten.';

  @override
  String get addAnItemOrConfirm =>
      'Voeg iets toe of bevestig dat je niets hebt ingenomen.';

  @override
  String get eachIntakeNeedsAProduct =>
      'Elke inname heeft een product en een geldig tijdstip nodig.';

  @override
  String get quantityMustBePositive => 'De hoeveelheid moet positief zijn.';

  @override
  String get thisActivityNoLongerExists => 'Deze activiteit bestaat niet meer.';

  @override
  String get practisedCarbohydrateToleranceMustNot =>
      'De geoefende koolhydraattolerantie mag niet hoger zijn dan 120 g/u.';

  @override
  String get measuredSweatRateMustBe =>
      'Het gemeten zweetverlies moet positief zijn of onbekend blijven.';

  @override
  String get increasePractisedToleranceInNutrition =>
      'Verhoog eerst de geoefende tolerantie in de voedingsinstellingen voordat je een hoger doel kiest.';

  @override
  String get fluidTargetExceedsYourMeasured =>
      'Het vochtdoel is hoger dan je gemeten zweetverlies. Controleer de meting of het doel.';

  @override
  String get elapsedWorkoutTimeMustBe =>
      'De verstreken trainingstijd moet positief zijn of leeg blijven.';

  @override
  String get intakeAmountsMustBeFinite =>
      'Innamehoeveelheden moeten eindig en niet-negatief zijn.';

  @override
  String get selectedStrategyUnavailableChooseAnother =>
      'Gekozen strategie niet beschikbaar. Kies een andere strategie of geen vergelijking.';

  @override
  String get recordYourWorkoutNutrition => 'Leg je trainingsvoeding vast';

  @override
  String get addTheFoodAndFluids =>
      'Voeg het eten en drinken dat je echt hebt genomen toe aan je activiteitengeschiedenis.';

  @override
  String get logIntake => 'Inname vastleggen';

  @override
  String nutritionReminderTitle(String name) {
    return 'Nieuwe activiteit: $name';
  }

  @override
  String get nutritionReminderBody =>
      'Voeg toe wat je hebt gegeten en gedronken.';

  @override
  String get nutritionReminderHrvHint =>
      'Je HRV na de training is nog niet gemeten.';

  @override
  String get in30Minutes => 'Over 30 minuten';

  @override
  String get loadSuggestionsCoverStraightSets =>
      'Gewichtsvoorstellen gelden alleen voor gewone sets met herhalingen.';

  @override
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  ) {
    return 'Hiervoor zijn $strengthProgressionMinSessions vastgelegde trainingen van deze oefening nodig.';
  }

  @override
  String get recentHistoryIsTooOld =>
      'De recente geschiedenis is te oud voor een voorstel.';

  @override
  String get theLastSessionDidNot =>
      'De laatste training gebruikte niet één bekend gewicht.';

  @override
  String get theLoadChangedBetweenThe =>
      'Het gewicht veranderde tussen de recente trainingen.';

  @override
  String get notEverySetReachedThe =>
      'Niet elke set bereikte de bovenkant van het herhalingsdoel.';

  @override
  String get recordEffortRirOrRpe =>
      'Leg de inspanning (RIR of RPE) van de laatste set vast om voorstellen te krijgen.';

  @override
  String get recentSetsWereHarderThan =>
      'De recente sets waren zwaarder dan bedoeld.';

  @override
  String get thisWorkoutAlreadyHasIts =>
      'Deze training heeft al een eigen gewicht; dat blijft zoals ingesteld.';

  @override
  String get yourRecentSetsMetThe =>
      'Je recente sets voldeden aan de progressieregel. Stel de kleinste belastingsstap voor dit materiaal in om een gewicht te beoordelen.';

  @override
  String get thisWorkoutNoLongerExists => 'Deze training bestaat niet meer.';

  @override
  String thisStrengthPlanCannotBe(Object message) {
    return 'Dit krachtplan kan niet worden gelezen ($message).';
  }

  @override
  String get thisStrengthPlanCannotBe2 =>
      'Dit krachtplan kan niet worden gelezen.';

  @override
  String get addAtLeastOneExercise => 'Voeg minstens één oefening toe.';

  @override
  String get thisWorkoutWasChangedElsewhere =>
      'Deze training is elders gewijzigd. Je wijzigingen blijven bewaard; laad opnieuw om de nieuwere versie te zien.';

  @override
  String get thePlanThisWorkoutIs =>
      'Het plan waarmee deze training wordt vergeleken, kan niet worden gelezen.';

  @override
  String get thisLogWasChangedElsewhere =>
      'Dit logboek is elders gewijzigd. Je invoer blijft bewaard; laad opnieuw om de nieuwere versie te zien.';

  @override
  String get thisZipIsNotA => 'Deze zip is geen ondersteunde Fjelia-back-up.';

  @override
  String get theBackupDatabaseIsDamaged => 'De back-updatabase is beschadigd.';

  @override
  String get invalidBackupData => 'Ongeldige back-upgegevens.';

  @override
  String get backupTablesDoNotMatch => 'De back-uptabellen komen niet overeen.';

  @override
  String get invalidBackupColumns => 'Ongeldige back-upkolommen.';

  @override
  String get migratingOriginalAppBackup =>
      'Oorspronkelijke app-back-up wordt omgezet';

  @override
  String get theOriginalBackupIsMissing =>
      'In de oorspronkelijke back-up ontbreken vereiste tabellen.';

  @override
  String get backupFormatOrDatabaseVersion =>
      'Back-upformaat of databaseversie komt niet overeen.';

  @override
  String get restoringRecords => 'Gegevens herstellen';

  @override
  String get restoringSettings => 'Instellingen herstellen';

  @override
  String get restoreComplete => 'Herstel voltooid';

  @override
  String get effortMustBeANumber => 'De inspanning moet een getal zijn.';

  @override
  String get theDurationEstimateMustBe =>
      'De geschatte duur moet positief zijn.';

  @override
  String get restCannotBeNegative => 'Rust kan niet negatief zijn.';

  @override
  String get enterTheRepetitionsDoneThe =>
      'Voer de uitgevoerde herhalingen in; het plan heeft een bereik.';

  @override
  String get enterTheLoadThePlan =>
      'Voer het gewicht in; het plan heeft er geen.';

  @override
  String get enterTheResistanceThePlan =>
      'Voer de weerstand in; het plan heeft er geen.';

  @override
  String get poorSensorContact => 'Slecht sensorcontact';

  @override
  String get moreThan25FromLocal => 'Meer dan 25% van de lokale mediaan';

  @override
  String get workoutNutrition => 'Trainingsvoeding';

  @override
  String get postWorkoutFoodAndFluid =>
      'Herinnering voor eten en drinken na de training';

  @override
  String get postTrainingHrvMeasurementReminder =>
      'Herinnering voor HRV-meting na de training';

  @override
  String get rirRunsFrom0To => 'RIR loopt van 0 tot 10+.';

  @override
  String get rpeRunsFrom1To => 'RPE loopt van 1 tot 10.';

  @override
  String get repetitionsCannotBeNegative =>
      'Herhalingen kunnen niet negatief zijn.';

  @override
  String get timedWorkMustBeLonger =>
      'Werk op tijd moet langer zijn dan nul seconden.';

  @override
  String get chooseRepetitionsOrTimedWork =>
      'Kies herhalingen of werk op tijd, niet allebei.';

  @override
  String get loadMustBeAFinite =>
      'Het gewicht moet een eindig, niet-negatief getal zijn.';

  @override
  String get durationCannotBeNegative => 'De duur kan niet negatief zijn.';

  @override
  String get hrTimeline => 'Hartslagverloop';

  @override
  String get dayTrainingLoad => 'Trainingsbelasting per dag';

  @override
  String get weekdayComparison => 'Vergelijking per weekdag';

  @override
  String get weeklyTrainingLoad => 'Trainingsbelasting per week';

  @override
  String get zonePolarization => 'Zonepolarisatie';

  @override
  String get elevationOverview => 'Hoogteoverzicht';

  @override
  String get trainingMonitor => 'Trainingsmonitor';

  @override
  String get formAtlCtlTsb => 'Vorm ATL / CTL / TSB';

  @override
  String get trainingPlanProgress => 'Voortgang trainingsplan';

  @override
  String get rhrSleep => 'Rusthartslag slaap';

  @override
  String get hrvSleep => 'HRV slaap';

  @override
  String get spo2Sleep => 'SpO₂ slaap';

  @override
  String get respRate => 'Ademfrequentie';

  @override
  String get stress => 'Stress';

  @override
  String get skinTemp => 'Huidtemperatuur';

  @override
  String get steps => 'Stappen';

  @override
  String get tonightsSleep => 'Slaap van vannacht';

  @override
  String get activityLog => 'Activiteitenlogboek';

  @override
  String get activityLog2 => 'Activiteitenlogboek';

  @override
  String get history2 => 'GESCHIEDENIS';

  @override
  String durationsecondshDurationseconds2mDistancemetersKmAvgheartrate(
    Object durationSeconds,
    Object durationSeconds2,
    Object distanceMeters,
    Object avgHeartRate,
    Object totalElevation,
  ) {
    return '${durationSeconds}u ${durationSeconds2}m · $distanceMeters km · $avgHeartRate bpm · ↑$totalElevation m';
  }

  @override
  String get heatAcclimation2 => 'HITTE-ACCLIMATISATIE';

  @override
  String score(Object score) {
    return '$score%';
  }

  @override
  String get elevation => 'HOOGTE';

  @override
  String get t12WeekHistory => '12 WEKEN GESCHIEDENIS';

  @override
  String get zonePolarization2 => 'ZONEPOLARISATIE';

  @override
  String get t5WeekHistory => '5 WEKEN GESCHIEDENIS';

  @override
  String get easy => 'RUSTIG %';

  @override
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded) {
    return '$withZones van $recorded activiteiten met hartslagzonegegevens';
  }

  @override
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples) {
    return '$fromSamples gereconstrueerd uit vastgelegde hartslagwaarden';
  }

  @override
  String get easyZ12ModerateZ3 => 'Rustig: Z1–2 · Matig: Z3 · Zwaar: Z4–5';

  @override
  String get activitiesWithoutHrZoneData =>
      'Activiteiten zonder hartslagzonegegevens tellen niet mee in de percentages.';

  @override
  String avgAverageUnit(Object average, Object unit) {
    return 'GEM.  $average $unit';
  }

  @override
  String get weekdayComparison2 => 'VERGELIJKING PER WEEKDAG';

  @override
  String get trainingPlanProgress2 => 'VOORTGANG TRAININGSPLAN';

  @override
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  ) {
    return 'Week $currentWeek / $durationInWeeks';
  }

  @override
  String get t30MinTimeTrialLt2 => 'TIJDRIT VAN 30 MIN — LT2';

  @override
  String get run30MinutesAtThe =>
      'Loop 30 minuten op de hoogste inspanning die je kunt volhouden — gecontroleerd, niet sprinten. Bouw de inspanning op; begin niet te snel. Het gemiddelde tempo en de hartslag van de laatste 20 minuten zijn je LT2.';

  @override
  String get recordAsANormalOutdoor =>
      'Leg vast als een normale buitenloop. Start je horloge, noteer de tijd, loop 30 min op wedstrijdinspanning.';

  @override
  String get t50MinTotalFlatCourse =>
      '~50 min totaal · vlak parcours · niet na een zware training';

  @override
  String get doNotStartTooFast =>
      'Begin niet te snel. Streef naar gelijke splits.';

  @override
  String get theAppAveragesHrAnd =>
      'De app neemt het gemiddelde van hartslag en tempo over de laatste 20 minuten van de tijdrit, na de warming-up en de eerste 10 minuten. Kies de vastgelegde activiteit bij Berekenen.';

  @override
  String get lt2Pace => 'LT2-TEMPO';

  @override
  String get activityRunningEnoughTimeFor =>
      'Activiteit (hardlopen, genoeg tijd voor warming-up + 30 min, met hartslag)';

  @override
  String get selectTheTtActivity => 'Kies de tijdritactiviteit';

  @override
  String nameStartdate(Object name, Object startDate) {
    return '$name · $startDate';
  }

  @override
  String get warmUpBeforeTt => 'Warming-up vóór de tijdrit';

  @override
  String roundMin(Object round) {
    return '$round min';
  }

  @override
  String get clearResults => 'Resultaten wissen';

  @override
  String get heartRate2 => 'HARTSLAG';

  @override
  String get paceSecKmLowerIs => 'TEMPO (sec/km — lager is sneller)';

  @override
  String get thresholdsFitnessTests => 'Drempels & fitnesstests';

  @override
  String get lt1 => 'LT1';

  @override
  String get lt2 => 'LT2';

  @override
  String get voPace => 'VO₂-tempo';

  @override
  String get ftp => 'FTP';

  @override
  String get setFtpManually => 'FTP handmatig instellen';

  @override
  String get calculateFromAnActivity => 'Berekenen uit een activiteit';

  @override
  String get setFtp => 'FTP instellen';

  @override
  String get ftpWatts => 'FTP (watt)';

  @override
  String get ftpCyclingThresholdPower => 'FTP — DREMPELVERMOGEN FIETSEN';

  @override
  String get ftpHistory => 'FTP-GESCHIEDENIS';

  @override
  String get updateFromActivity => 'BIJWERKEN UIT ACTIVITEIT';

  @override
  String get tapAnActivityFtpBest =>
      'Tik op een activiteit — FTP = beste 20-min-vermogen × 0,95';

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
      'Geen ritten met 20 minuten aaneengesloten vermogensgegevens.';

  @override
  String get enterFtpManually => 'FTP handmatig invoeren';

  @override
  String get selectTheTestActivity => 'Kies de testactiviteit';

  @override
  String get formAtlCtlTsb2 => 'VORM · ATL / CTL / TSB';

  @override
  String get closeTrainingFormFullscreen =>
      'Trainingsvorm op volledig scherm sluiten';

  @override
  String get expandTrainingForm => 'Trainingsvorm uitvouwen';

  @override
  String get calculatedFromTheFirstAvailable =>
      'Berekend vanaf de eerste beschikbare belastingsgegevens. Dagen zonder vastgelegde belasting tellen als nul; eerdere training is onbekend.';

  @override
  String get trainingMonitor2 => 'TRAININGSMONITOR';

  @override
  String get pfitzingerZones => 'PFITZINGER-ZONES';

  @override
  String get cyclingPowerZones => 'VERMOGENSZONES FIETSEN';

  @override
  String znumber(Object number) {
    return 'Z$number';
  }

  @override
  String paceHrDescription(Object pace, Object hr, Object description) {
    return '$pace · $hr\n$description';
  }

  @override
  String get weeklyTrainingLoad2 => 'TRAININGSBELASTING PER WEEK';

  @override
  String get prevWeek => 'VORIGE WEEK';

  @override
  String get bySport => 'PER SPORT';

  @override
  String get noActivitiesThisWeek => 'Geen activiteiten deze week';

  @override
  String garminWorkoutScheduleddate(Object scheduledDate) {
    return 'Garmin-training · $scheduledDate';
  }

  @override
  String get yourNote => 'Je notitie';

  @override
  String get askAiCoach => 'Vraag de AI-coach';

  @override
  String get aiSettings => 'AI-instellingen';

  @override
  String get askYourCoach => 'Vraag je coach…';

  @override
  String get sendMessage => 'Bericht versturen';

  @override
  String get sendFeedbackOrReportA => 'Feedback sturen of een fout melden';

  @override
  String get addMeasurement2 => 'Meting toevoegen';

  @override
  String get syncLabel2 => 'Synchroniseren';

  @override
  String get syncToday => 'Vandaag synchroniseren';

  @override
  String get fullSync1Year => 'Volledige synchronisatie · 1 jaar';

  @override
  String get fullSyncComplete => 'Volledige synchronisatie · voltooid';

  @override
  String get syncingYourData => 'Je gegevens worden gesynchroniseerd…';

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
    return '$weight kg · Vet $bodyFat% · Spieren $muscleMass kg';
  }

  @override
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase) {
    return '$title, $sport, $toLowerCase';
  }

  @override
  String get weatherUnavailableTapToRetry =>
      'Weer niet beschikbaar · Tik om opnieuw te proberen';

  @override
  String get weatherSetYourLocation => 'Weer · Stel je locatie in';

  @override
  String get t7DayForecast => '7-DAAGSE VOORSPELLING';

  @override
  String get minMax => 'min/max';

  @override
  String get rainMm2 => 'regen mm';

  @override
  String get uvMax => 'UV max';

  @override
  String get kmH => 'km/u';

  @override
  String alt(Object alt) {
    return '→ $alt';
  }

  @override
  String raceGoalsLength(Object length) {
    return 'Wedstrijddoelen · $length';
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
  String get weeks2 => 'weken';

  @override
  String get upcoming => 'KOMEND';

  @override
  String lengthMoreDays(Object length) {
    return '+ nog $length dagen';
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
      '○ Gepland   ● Voltooid   ✕ Overgeslagen';

  @override
  String get heartRate3 => 'Hartslag';

  @override
  String get watts => 'Watt';

  @override
  String theStepsAddUpTo(Object total, Object plannedDurationMin) {
    return 'De stappen tellen op tot $total; het plan rekent $plannedDurationMin min.';
  }

  @override
  String get typicalSplitForThisKind =>
      'Gebruikelijke verdeling voor dit soort training; er zijn geen stappen om haar uit te berekenen.';

  @override
  String labelGetsEachExerciseWith(Object label) {
    return '$label krijgt elke oefening met sets, herhalingen en gewichten. Herhalingsbereiken, inspanning en tempo blijven in Fjelia.';
  }

  @override
  String get markAsRest => 'Markeren als rust';

  @override
  String get changeSport => 'Sport wijzigen';

  @override
  String get replacementSport => 'Vervangende sport';

  @override
  String get replacementLoadNote =>
      'Duur, geplande hartslagzones en belastingsdoel blijven behouden. Tempo- en vermogensdoelen worden aangepast aan de nieuwe sport.';

  @override
  String replacementCalendarNote(String platforms) {
    return 'De oorspronkelijke training wordt verwijderd uit deze trainingskalenders: $platforms.';
  }

  @override
  String get applySportChange => 'Vervangende training inplannen';

  @override
  String get restoreWorkout => 'Training herstellen';

  @override
  String get skipThisWorkout => 'Deze training overslaan?';

  @override
  String get previousWeek => 'Vorige week';

  @override
  String get backToThisWeek => 'Terug naar deze week';

  @override
  String get thisWeek => 'Deze week';

  @override
  String get nextWeek => 'Volgende week';

  @override
  String get today2 => 'VANDAAG';

  @override
  String get route => 'ROUTE';

  @override
  String get feedback => 'Feedback';

  @override
  String get plannedWorkout => 'Geplande training';

  @override
  String get delete => 'Verwijderen';

  @override
  String get chatAi => 'Chat-AI';

  @override
  String get trainingLoad => 'Trainingsbelasting';

  @override
  String get dayTrainingLoad2 => 'TRAININGSBELASTING VAN DE DAG';

  @override
  String get trimp => ' TRIMP';

  @override
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter) {
    return '$scoreBefore → $scoreAfter';
  }

  @override
  String get temperatureOverTime => 'TEMPERATUURVERLOOP';

  @override
  String roundh(Object round) {
    return '${round}u';
  }

  @override
  String get timeInHrZones => 'Tijd in hartslagzones';

  @override
  String get route2 => 'Route';

  @override
  String get start => 'Start';

  @override
  String get gpx => 'GPX';

  @override
  String touppercasesubstringBriefing(Object toUpperCase, Object substring) {
    return '$toUpperCase$substring briefing';
  }

  @override
  String get chatWithAiAboutThis => 'Chat met AI over deze briefing';

  @override
  String get whyThisRecommendation => 'Waarom dit advies?';

  @override
  String titleDateLabel(Object title, Object date, Object label) {
    return '$title, $date, $label';
  }

  @override
  String get previousDay => 'Vorige dag';

  @override
  String get nextDay => 'Volgende dag';

  @override
  String get updating => 'Bijwerken';

  @override
  String get resting => 'IN RUST';

  @override
  String get noTimedReadings => 'Geen metingen met tijdstip';

  @override
  String get avg => 'GEM.';

  @override
  String get peak => 'PIEK';

  @override
  String tolocalRoundmin(Object toLocal, Object round) {
    return '$toLocal · ${round}min';
  }

  @override
  String avgheartrateBpmAvg(Object avgHeartRate) {
    return '$avgHeartRate bpm gem.';
  }

  @override
  String get timeWeightedAverageOverRecorded =>
      'Tijdgewogen gemiddelde over de vastgelegde perioden. Hiaten zonder metingen tellen niet mee.';

  @override
  String get previousHeartRatePeriod => 'Vorige hartslagperiode';

  @override
  String get nextHeartRatePeriod => 'Volgende hartslagperiode';

  @override
  String get avgHr => 'Gem. hartslag';

  @override
  String get restingHr => 'Rusthartslag';

  @override
  String get both => 'Beide';

  @override
  String averagelabelFixedMs(Object averageLabel, Object fixed) {
    return '$averageLabel $fixed ms';
  }

  @override
  String get measureWithPolarH10 => 'Meten met Polar H10';

  @override
  String get ms => 'ms';

  @override
  String get noWorkoutInThisPeriod =>
      'Geen training in deze periode heeft een vergelijkbaar paar voor en na.';

  @override
  String textEachWorkoutCountsOnce(Object text) {
    return '$text. Elke training telt één keer; dit beschrijft je paren en geeft ze geen score.';
  }

  @override
  String get workoutFinished => 'Training afgelopen?';

  @override
  String get yourWorkoutIsNotIn =>
      'Je training staat nog niet in Fjelia. Als hij voorbij is, geef dan aan wanneer, zodat de herinnering het echte einde kan volgen. Anders verschijnt hij zodra je horloge synchroniseert.';

  @override
  String get workoutFinished2 => 'Training afgelopen';

  @override
  String get theWorkoutMustStartAfter =>
      'De training moet na de meting beginnen en na het begin eindigen, niet in de toekomst.';

  @override
  String daysDAvg(Object days) {
    return '$days D GEM.';
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
  String get previousPeriod => 'Vorige periode';

  @override
  String get nextPeriod => 'Volgende periode';

  @override
  String get overnightHrvReflectsRecoveryCompare =>
      'Nachtelijke HRV weerspiegelt herstel. Vergelijk je metingen in de loop van de tijd met je eigen basislijn.';

  @override
  String get moveThisWorkout => 'DEZE TRAINING VERPLAATSEN';

  @override
  String get pickDate => 'Datum kiezen';

  @override
  String movedFromMovedfrom(Object movedFrom) {
    return 'Verplaatst van $movedFrom';
  }

  @override
  String get hrvAroundThisWorkout => 'HRV rond deze training';

  @override
  String get measureAfterTraining => 'Na de training meten';

  @override
  String get measureAgain => 'Opnieuw meten';

  @override
  String get explainWithAi => 'Uitleggen met AI';

  @override
  String beforeEndedPregapAheadOf(Object preGap) {
    return 'De meting vooraf eindigde $preGap voor de start.';
  }

  @override
  String lengthFurtherMeasurementSAfter(Object length) {
    return '$length extra meting(en) na deze training worden bewaard als aanvullende waarnemingen.';
  }

  @override
  String get noHrvMeasurementRecordedAround =>
      'Geen HRV-meting vastgelegd rond deze training.';

  @override
  String get measureHrv => 'HRV meten';

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
      'Een beschrijving van dit paar, geen score voor de training.';

  @override
  String notEnoughComparableWorkoutsYet(Object eligible, Object need) {
    return 'Nog niet genoeg vergelijkbare trainingen, $eligible van $need.';
  }

  @override
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need) {
    return 'Nog niet genoeg vergelijkbare trainingen ($eligible van $need).';
  }

  @override
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  ) {
    return 'Je $eligible vergelijkbare trainingen · $toLocal–$toLocal2';
  }

  @override
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  ) {
    return 'Middelste helft $q1Ms tot $q3Ms ms · mediaan $medianMs ms · deze training $delta ms';
  }

  @override
  String rpeI(Object i) {
    return 'RPE $i';
  }

  @override
  String get easy2 => 'makkelijk';

  @override
  String get allOut => 'voluit';

  @override
  String workoutProfileDescription(Object description) {
    return 'Trainingsprofiel: $description';
  }

  @override
  String get noActivitiesInThisPeriod => 'Geen activiteiten in deze periode';

  @override
  String get enableHeatAcclimationInTraining =>
      'Schakel hitte-acclimatisatie in bij de trainingsinstellingen.';

  @override
  String get noElevationThisWeek => 'Geen hoogtemeters deze week';

  @override
  String get noActivitiesSynced => 'Geen activiteiten gesynchroniseerd';

  @override
  String get noHrZoneData => 'Geen hartslagzonegegevens';

  @override
  String get easyJogGetHrElevated =>
      'Rustig joggen — hartslag omhoog, benen los';

  @override
  String get fastestSustainablePaceLikeA =>
      'Snelst vol te houden tempo — zoals een wedstrijd van 30 min';

  @override
  String get walkCardiacRecovery => 'Wandelen — herstel van de hartslag';

  @override
  String get selectTheTtActivityFirst => 'Kies eerst de tijdritactiviteit.';

  @override
  String get calculating => 'Berekenen…';

  @override
  String get calculateLt2 => 'LT2 berekenen';

  @override
  String get enterFtpBetween30And => 'Voer een FTP tussen 30 en 1000 W in.';

  @override
  String get aerobicThreshold => 'Aerobe drempel';

  @override
  String get functionalThresholdPower => 'Functioneel drempelvermogen';

  @override
  String get estimated => 'Geschat';

  @override
  String get afterWarmingUpRunFive =>
      'Loop na de warming-up vijf minuten op je snelst vol te houden inspanning. Leg de loop vast met snelheids- of afstandsgegevens.';

  @override
  String get recordAtLeast40Minutes =>
      'Leg minstens 40 minuten gelijkmatig lopen op constante inspanning vast. De test vergelijkt de hartslag in beide helften om de aerobe drift te schatten.';

  @override
  String get theFastestFiveMinuteWindow =>
      'Het snelste vijfminutenvenster levert je VO2max-tempo.';

  @override
  String get noResultYet => 'Nog geen resultaat';

  @override
  String get calculateVo2maxPace => 'VO2max-tempo berekenen';

  @override
  String get calculateLt1 => 'LT1 berekenen';

  @override
  String get loading2 => 'Laden';

  @override
  String get unavailable => 'Niet beschikbaar';

  @override
  String get noTrainingHistory => 'Geen trainingsgeschiedenis';

  @override
  String get fitnessCtl => 'Fitheid (CTL)';

  @override
  String get fatigueAtl => 'Vermoeidheid (ATL)';

  @override
  String get formTsb => 'Vorm (TSB)';

  @override
  String get noHistory => 'Geen geschiedenis';

  @override
  String get fresh => 'Fris';

  @override
  String get optimal => 'Optimaal';

  @override
  String get neutral => 'Neutraal';

  @override
  String get tired => 'Moe';

  @override
  String get veryFatigued => 'Zeer vermoeid';

  @override
  String get garminRunningVo2max => 'Garmin-VO2max hardlopen';

  @override
  String get garminCyclingVo2max => 'Garmin-VO2max fietsen';

  @override
  String get aerobicThreshold2 => 'Aerobe drempel';

  @override
  String driftDriftAt(Object drift, Object at) {
    return 'Drift $drift% · $at';
  }

  @override
  String get activityHours => 'Activiteitsuren';

  @override
  String get activityKm => 'Activiteitskm';

  @override
  String get tap5MinuteMaxTest => 'Tik · maximaaltest van 5 minuten';

  @override
  String get setFtpToCalculatePower =>
      'Stel FTP in om vermogenszones te berekenen';

  @override
  String get cyclingPowerZones2 => 'Vermogenszones fietsen';

  @override
  String get pfitzingerZones2 => 'Pfitzinger-zones';

  @override
  String get completeAnLt2TestTo =>
      'Doe een LT2-test om looptzones te berekenen.';

  @override
  String get setFtpToCalculatePower2 =>
      'Stel FTP in om vermogenszones te berekenen.';

  @override
  String get endurance => 'Duur';

  @override
  String get threshold => 'Drempel';

  @override
  String get anaerobic => 'Anaeroob';

  @override
  String get whatExplainsThisRise => 'Wat verklaart deze stijging?';

  @override
  String get whatExplainsThisDrop => 'Wat verklaart deze daling';

  @override
  String get whatExplainsThisRise2 => 'Wat verklaart deze stijging';

  @override
  String get editsAreKeptInFjelia =>
      'Wijzigingen worden in Fjelia bewaard als lokale kopie voor deze datum. De training op Garmin wordt niet gewijzigd.';

  @override
  String get howDoIExecuteThis => 'Hoe voer ik deze training uit?';

  @override
  String shareHealthContextWithName(Object name) {
    return 'Gezondheidscontext delen met $name?';
  }

  @override
  String get yourMessageAndAHealth =>
      'Je bericht en een samenvatting van je gezondheid en training worden naar deze cloud-AI-aanbieder gestuurd. Namen en gps staan niet in de samenvatting.';

  @override
  String get couldNotGetAReply =>
      'Geen antwoord ontvangen. Controleer je AI-instellingen en probeer het opnieuw.';

  @override
  String get askAboutYourRecoveryTraining =>
      'Vraag naar je herstel, training of het plan van vandaag.';

  @override
  String get noSyncYet => 'Nog niet gesynchroniseerd';

  @override
  String lastSyncLastContext(Object last, Object context) {
    return 'Laatste synchronisatie: $last $context';
  }

  @override
  String get seasonWithTradeOffs => 'Seizoen: met compromissen';

  @override
  String get seasonNeedsYourDecision => 'Seizoen: jouw beslissing nodig';

  @override
  String get seasonCannotBeCombined => 'Seizoen: niet te combineren';

  @override
  String get seasonProvisional => 'Seizoen: voorlopig';

  @override
  String get season => 'Seizoen';

  @override
  String get allGoalsFit => 'Alle doelen passen.';

  @override
  String goalTargetfinishsecondsgoal(Object targetFinishSeconds, Object goal) {
    return 'Doel $targetFinishSeconds$goal';
  }

  @override
  String estEstimateestimate2(Object estimate, Object estimate2) {
    return 'Gesch. $estimate$estimate2';
  }

  @override
  String doneDoneby(Object doneBy) {
    return 'Gedaan · $doneBy';
  }

  @override
  String garminWorkoutWorkout(Object workout) {
    return 'Garmin-training · $workout';
  }

  @override
  String get moveAnyway => 'Toch verplaatsen?';

  @override
  String get wattsNeedYourFtpSet =>
      'Voor watt is je FTP nodig: stel die in onder Belasting, Drempels.';

  @override
  String get mainTargetInWattsFrom =>
      'Hoofddoel in watt op basis van je FTP, hartslag als leidraad.';

  @override
  String get mainTargetHeartRateWatts =>
      'Hoofddoel is de hartslag; watt worden niet op het horloge ingesteld.';

  @override
  String get taperPhase => 'Afbouwfase';

  @override
  String get recoverySession => 'Hersteltraining';

  @override
  String get closeToYourEvent => 'Vlak voor je evenement';

  @override
  String get noWorkoutStructureAvailable => 'Geen trainingsopbouw beschikbaar.';

  @override
  String get aerobic => 'Aeroob';

  @override
  String get pushAgainToUpdateYour =>
      'Stuur opnieuw om de kalender van je horloge bij te werken.';

  @override
  String workoutSentToLabel(Object label) {
    return 'Training verstuurd naar $label';
  }

  @override
  String get updating2 => 'Bijwerken…';

  @override
  String pushToLabel(Object label) {
    return 'Naar $label sturen';
  }

  @override
  String shareExerciseListForLabel(Object label) {
    return 'Oefeningenlijst delen voor $label';
  }

  @override
  String shareWorkoutForLabel(Object label) {
    return 'Training delen voor $label';
  }

  @override
  String get whyNothingIsAddedTo =>
      'Waarom? Er wordt niets toegevoegd om het goed te maken.';

  @override
  String get workout => 'Training';

  @override
  String get recordedActivityLinkedToThis =>
      'Vastgelegde activiteit gekoppeld aan deze training';

  @override
  String get matchedToTheRecordedWorkout =>
      'Gekoppeld aan de start van de vastgelegde training';

  @override
  String get matchedByWorkoutNameSport =>
      'Gekoppeld op trainingsnaam, sport en datum';

  @override
  String get matchedBySportDateAnd => 'Gekoppeld op sport, datum en duur';

  @override
  String planPlannedminutesMin(Object plannedMinutes) {
    return 'Plan $plannedMinutes min';
  }

  @override
  String get maxHr => 'Max. hartslag';

  @override
  String get trainingLoad2 => 'Trainingsbelasting';

  @override
  String get active => 'Actief';

  @override
  String get avgPace => 'Gem. tempo';

  @override
  String get avgSpeed => 'Gem. snelheid';

  @override
  String get avgPower => 'Gem. vermogen';

  @override
  String get elevation2 => 'Hoogtemeters';

  @override
  String get altitude => 'Hoogte';

  @override
  String get explainMyHrvBeforeAnd =>
      'Leg mijn HRV voor en na deze training uit. Wat is vergelijkbaar, wat niet, en wat is nog onbekend?';

  @override
  String get deleteActivity => 'Activiteit verwijderen?';

  @override
  String get removeThisActivityFromThe =>
      'Deze activiteit verwijderen? Ze blijft verwijderd, ook nadat je apparaten opnieuw synchroniseren. Je kunt haar herstellen in Instellingen onder Recent verwijderd.';

  @override
  String get howDidThisSessionGo =>
      'Hoe ging deze training en wat betekent dat voor mijn komende dagen?';

  @override
  String currentFixedFixed2(Object fixed, Object fixed2) {
    return 'Huidig $fixed, $fixed2';
  }

  @override
  String get setUpInTrainingSettings =>
      'Instellen bij de trainingsinstellingen';

  @override
  String get couldNotLoadHeatData =>
      'Hittegegevens konden niet worden geladen — tik voor details';

  @override
  String get loadingHeatHistory => 'Hittegeschiedenis laden…';

  @override
  String get noHeatDataYet => 'Nog geen hittegegevens';

  @override
  String optimalLowHigh(Object low, Object high) {
    return 'Optimaal $low–$high';
  }

  @override
  String optimalLowHighTrimp(Object low, Object high) {
    return 'Optimaal: $low–$high TRIMP';
  }

  @override
  String get targetUnavailableSyncTrainingHistory =>
      'Doel niet beschikbaar — synchroniseer je trainingsgeschiedenis';

  @override
  String get workoutQualifiedForHeatAccumulation =>
      'De training telde mee voor hitte-opbouw.';

  @override
  String get workoutDidNotAddHeat =>
      'De training telde niet mee voor hitte-opbouw.';

  @override
  String get performanceTime => 'Prestatie / tijd';

  @override
  String get performanceDistance => 'Prestatie / afstand';

  @override
  String get noRecordedRoute => 'Geen vastgelegde route';

  @override
  String get zoomIn => 'Inzoomen';

  @override
  String get zoomOut => 'Uitzoomen';

  @override
  String get fitRoute => 'Route passend maken';

  @override
  String get fullscreenMap => 'Kaart op volledig scherm';

  @override
  String get openstreetmapContributors2 => 'OpenStreetMap-bijdragers';

  @override
  String get appleIntelligenceIsUnavailableShowing =>
      'Apple Intelligence is niet beschikbaar. Er wordt een samenvatting zonder AI getoond.';

  @override
  String get generateAiBriefing => 'AI-briefing maken?';

  @override
  String get retryAiBriefing => 'AI-briefing opnieuw proberen';

  @override
  String get generateBriefing => 'Briefing maken';

  @override
  String discussThisBriefingWithMe(Object text) {
    return 'Bespreek deze briefing met me en stel de best volgende stap voor.\n\n$text';
  }

  @override
  String whyThisRecommendationWhichOf(Object text) {
    return 'Waarom dit advies? Welke van mijn waarden en welke hiaten in de gegevens leidden ertoe, en wat zou het veranderen?\n\n$text';
  }

  @override
  String get avg2 => 'Gem.';

  @override
  String get peak2 => 'Piek';

  @override
  String get notEnoughContinuousReadingsFor =>
      'Niet genoeg aaneengesloten metingen voor een gemiddelde.';

  @override
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  ) {
    return 'Vastgelegde dekking: ${inHours}u ${inMinutes}min · tijdgewogen gemiddelde';
  }

  @override
  String get lying => 'Liggend';

  @override
  String get noHrvReadingsInThis => 'Geen HRV-metingen in deze periode';

  @override
  String get overnightHrvComesFromYour =>
      'Nachtelijke HRV komt van je horloge, momentane metingen van de Polar H10 (RMSSD). De methoden verschillen: vergelijk trends, geen losse waarden.';

  @override
  String get noReadings => 'Geen metingen';

  @override
  String get whenDidTheWorkoutStart => 'Wanneer begon de training?';

  @override
  String get whenDidItEnd => 'Wanneer eindigde hij?';

  @override
  String get last3Months => 'Laatste 3 maanden';

  @override
  String get lastYear => 'Afgelopen jaar';

  @override
  String lastDaysDays(Object days) {
    return 'Laatste $days dagen';
  }

  @override
  String nowOnCurrentTapA(Object current) {
    return 'Nu op $current. Tik op een dag of sleep de training erheen. De stappen blijven zoals ze zijn.';
  }

  @override
  String get monthView => 'Maandweergave';

  @override
  String get syncing => 'Synchroniseren';

  @override
  String get trendUnavailable => 'Trend niet beschikbaar';

  @override
  String get stable => 'Stabiel';

  @override
  String get increasing => 'Stijgend';

  @override
  String get decreasing => 'Dalend';

  @override
  String get unclear => 'Onduidelijk';

  @override
  String get notComparable => 'Niet vergelijkbaar';

  @override
  String get waitingForAfter => 'Wachten op na';

  @override
  String get afterOnly => 'Alleen na';

  @override
  String get waitingForTheActualWorkout =>
      'Wachten op het echte einde van de training.';

  @override
  String reminderAroundTolocal(Object toLocal) {
    return 'Herinnering rond $toLocal';
  }

  @override
  String get reminderIsDueMeasureWhen =>
      'Herinnering staat open. Meet wanneer je klaar bent.';

  @override
  String get thisReminderIsNoLonger =>
      'Deze herinnering is niet meer actueel. Open de training om je metingen te zien.';

  @override
  String beforeFixedMilliseconds(Object fixed) {
    return 'Voor $fixed milliseconden. ';
  }

  @override
  String afterFixedMilliseconds(Object fixed) {
    return 'Na $fixed milliseconden';
  }

  @override
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  ) {
    return 'Verandering $deltaMs milliseconden, $deltaPercent procent.';
  }

  @override
  String get noPreTrainingMeasurementRecorded =>
      'Geen meting vóór de training vastgelegd.';

  @override
  String get notMeasuredYet => 'Nog niet gemeten';

  @override
  String leftOutOfTheComparison(Object excludedTotal, Object c) {
    return 'Buiten de vergelijking gelaten: $excludedTotal trainingen ($c).';
  }

  @override
  String get notFromThisWorkout => 'Niet van deze training';

  @override
  String get useAsBefore => 'Gebruiken als voor';

  @override
  String get useAsAfter => 'Gebruiken als na';

  @override
  String get beforeNotMeasured => 'Voor · niet gemeten';

  @override
  String beforeTolocal(Object toLocal) {
    return 'Voor · $toLocal';
  }

  @override
  String workoutWorkouttext(Object workoutText) {
    return 'Training · $workoutText';
  }

  @override
  String get afterNotMeasuredYet => 'Na · nog niet gemeten';

  @override
  String afterTolocal(Object toLocal) {
    return 'Na · $toLocal';
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
    return 'Je vergelijkbare trainingen ($eligible, $toLocal–$toLocal2): mediaan $medianMs ms, middelste helft $q1Ms tot $q3Ms ms.';
  }

  @override
  String get howHardDidItFeel => 'Hoe zwaar voelde het? (RPE)';

  @override
  String get loadMetric => 'Belasting';

  @override
  String get clearAction => 'Wissen';

  @override
  String get routeFinish => 'Finish';

  @override
  String get month2 => 'MAAND';

  @override
  String get week2 => 'WEEK';

  @override
  String get quarter => 'KWARTAAL';

  @override
  String get year => 'JAAR';

  @override
  String get easy3 => 'RUSTIG';

  @override
  String get mod => 'MATIG';

  @override
  String get hard => 'ZWAAR';

  @override
  String get protocol => 'PROTOCOL';

  @override
  String get calculate => 'BEREKENEN';

  @override
  String get warmUp => 'WARMING-UP';

  @override
  String get coolDown => 'COOLING-DOWN';

  @override
  String get ftpCycling => 'FTP fietsen';

  @override
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg) {
    return 'FTP $ftpWatts W · $wattsPerKg W/kg';
  }

  @override
  String get thisWeekSoFar => 'DEZE WEEK · TOT NU TOE';

  @override
  String get duration2 => 'DUUR';

  @override
  String get distance2 => 'AFSTAND';

  @override
  String get sport2 => 'SPORT';

  @override
  String get repeatSets => 'HERHAALSETS';

  @override
  String get aboutThisWorkout => 'OVER DEZE TRAINING';

  @override
  String get workoutStructure => 'OPBOUW VAN DE TRAINING';

  @override
  String get health2 => 'STATUS';

  @override
  String get high2 => 'HOOG';

  @override
  String get elevated => 'VERHOOGD';

  @override
  String get normal => 'NORMAAL';

  @override
  String get tomorrow => 'MORGEN';

  @override
  String get skipped2 => 'OVERGESLAGEN';

  @override
  String get weeklyPlan => 'WEEKPLAN';

  @override
  String get activityLog3 => 'ACTIVITEITENLOGBOEK';

  @override
  String skippedTouppercase(Object toUpperCase) {
    return 'OVERGESLAGEN · $toUpperCase';
  }

  @override
  String get primaryZone => 'HOOFDZONE';

  @override
  String get coachingCues => 'COACHINGTIPS';

  @override
  String get targets => 'DOELEN';

  @override
  String get adaptation => 'AANPASSING';

  @override
  String get done2 => 'GEDAAN';

  @override
  String get notRecorded2 => 'NIET VASTGELEGD';

  @override
  String get planned => 'GEPLAND';

  @override
  String get extra => 'EXTRA';

  @override
  String get optimal2 => 'OPTIMAAL';

  @override
  String get qualified => 'GETELD';

  @override
  String get temp => 'TEMP';

  @override
  String get humidity2 => 'VOCHTIGHEID';

  @override
  String get pressure => 'LUCHTDRUK';

  @override
  String get wetBulb => 'NATTE BOL';

  @override
  String get paceMinKm => 'TEMPO (min/km)';

  @override
  String get speedKmH => 'SNELHEID (km/u)';

  @override
  String get elevationM => 'HOOGTE (m)';

  @override
  String get powerW => 'VERMOGEN (W)';

  @override
  String get performanceTime2 => 'PRESTATIE / TIJD';

  @override
  String get performanceDistance2 => 'PRESTATIE / AFSTAND';

  @override
  String get load2 => 'BELASTING';

  @override
  String get day2 => 'DAG';

  @override
  String get allTime => 'ALLE TIJDEN';

  @override
  String get hrvAroundThisWorkout2 => 'HRV rond deze training. ';

  @override
  String get lowReserve => 'WEINIG RESERVE';

  @override
  String get goodReserve => 'GOEDE RESERVE';

  @override
  String latestReadingAtTolocal(Object toLocal) {
    return 'Laatste meting om $toLocal';
  }

  @override
  String get weeklyAvg => 'WEEKGEMIDDELDE';

  @override
  String get monthlyAvg => 'MAANDGEMIDDELDE';

  @override
  String get systolic2 => 'SYSTOLISCH';

  @override
  String get diastolic2 => 'DIASTOLISCH';

  @override
  String get hourlyVariation => 'VARIATIE PER UUR';

  @override
  String get dailyVariation => 'VARIATIE PER DAG';

  @override
  String get sys2 => 'SYS';

  @override
  String get dia => 'DIA';

  @override
  String get bluetoothDevices => 'BLUETOOTH-APPARATEN';

  @override
  String get accountsServices => 'ACCOUNTS & DIENSTEN';

  @override
  String get flowLoginOptional => 'FLOW-LOGIN (OPTIONEEL)';

  @override
  String get polarFlowLogin => 'POLAR FLOW-LOGIN';

  @override
  String get raceGoal => 'WEDSTRIJDDOEL';

  @override
  String get experienceLevel => 'ERVARINGSNIVEAU';

  @override
  String get weeklySchedule2 => 'WEEKSCHEMA';

  @override
  String get sessionsPerDay2 => 'TRAININGEN PER DAG';

  @override
  String get aboutYou => 'OVER JOU';

  @override
  String get yourActivities2 => 'JE ACTIVITEITEN';

  @override
  String latestReadingAtTimestamp(Object timestamp) {
    return 'Laatste meting om $timestamp';
  }

  @override
  String get poorSleep => 'SLECHTE SLAAP';

  @override
  String get fairSleep => 'REDELIJKE SLAAP';

  @override
  String get goodSleep => 'GOEDE SLAAP';

  @override
  String get hoursOfSleep => 'UREN SLAAP';

  @override
  String get sleepNeeded => 'SLAAPBEHOEFTE';

  @override
  String get deepSleep => 'DIEPE SLAAP';

  @override
  String get exercises2 => 'OEFENINGEN';

  @override
  String get strengthSummary => 'KRACHTOVERZICHT';

  @override
  String get strengthDraft => 'KRACHT · CONCEPT';

  @override
  String get strengthFinishedWithGaps => 'KRACHT · AFGEROND MET HIATEN';

  @override
  String get strength2 => 'KRACHT';

  @override
  String get wind => 'WIND';

  @override
  String get sun2 => 'ZON';

  @override
  String get cloud => 'BEWOLKING';

  @override
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt) {
    return 'Gegevens: $source · Bijgewerkt $fetchedAt';
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
  String get awake => 'WAKKER';

  @override
  String get light => 'LICHT';

  @override
  String get deep2 => 'DIEP';

  @override
  String get sqliteOrm => 'SQLite-ORM';

  @override
  String get httpClients => 'HTTP-clients';

  @override
  String get gpsLocation => 'Gps-locatie';

  @override
  String get hdlCholesterol => 'HDL-cholesterol';

  @override
  String get ldlCholesterol => 'LDL-cholesterol';

  @override
  String get raceName => 'WEDSTRIJDNAAM';

  @override
  String get mtb => 'MTB';

  @override
  String get distanceKm => 'AFSTAND (km)';

  @override
  String get priority => 'PRIORITEIT';

  @override
  String get elevationGainM => 'HOOGTEMETERS (m)';

  @override
  String get targetTime => 'DOELTIJD';

  @override
  String get raceDate => 'WEDSTRIJDDATUM';

  @override
  String get participation => 'DEELNAME';

  @override
  String get whatIWantFromIt => 'WAT IK ERUIT WIL HALEN';

  @override
  String periodTimeline(Object period) {
    return 'VERLOOP $period';
  }

  @override
  String get tabPlan => 'PLAN';

  @override
  String get tabLoad => 'LOAD';

  @override
  String get tabCoach => 'COACH';

  @override
  String get hrDriftTestLt1 => 'HARTSLAGDRIFTTEST — LT1';

  @override
  String get asSentByGarmin => 'ZOALS VERSTUURD DOOR GARMIN';

  @override
  String get noData2 => 'GEEN GEGEVENS';

  @override
  String get noTarget => 'GEEN DOEL';

  @override
  String get noHeatLoad => 'GEEN HITTEBELASTING';

  @override
  String get hrBpm => 'HARTSLAG (bpm)';

  @override
  String get aiBriefingUnavailableShowingA =>
      'AI-briefing niet beschikbaar. Er wordt een samenvatting zonder AI getoond.';

  @override
  String get uvIndex2 => 'UV-INDEX';

  @override
  String get aiBriefing => 'AI-briefing';

  @override
  String get uiFrameworkByGoogle => 'UI-framework van Google';

  @override
  String get unableToLoadData => 'Gegevens konden niet worden geladen';

  @override
  String briefingSummary(Object recovery, Object sleep, Object load) {
    return 'Herstel $recovery / 100. Slaap $sleep / 100. De trainingsbelasting van vandaag is $load TRIMP.';
  }

  @override
  String get morningBriefing => 'Ochtendbriefing';

  @override
  String get lunchBriefing => 'Middagbriefing';

  @override
  String get afternoonBriefing => 'Namiddagbriefing';

  @override
  String get eveningBriefing => 'Avondbriefing';

  @override
  String get appleUnusableAnswer =>
      'Apple Intelligence kon geen bruikbaar antwoord geven: het herhaalde zichzelf of je gegevens. Formuleer de vraag anders of kies een andere AI-aanbieder in de instellingen.';

  @override
  String get appleCouldNotAnswer =>
      'Apple Intelligence kon niet antwoorden. Probeer het opnieuw.';

  @override
  String get appleNotAvailableOnDevice =>
      'Apple Intelligence is niet beschikbaar op dit apparaat.';

  @override
  String get appleLanguageRejected =>
      'Apple Intelligence wees de taal van het verzoek af. Probeer een korte vraag in het Engels. Controleer ook de taalinstellingen van iPhone en Siri.';

  @override
  String get appleRequestTooLarge =>
      'Dit verzoek was te groot voor Apple Intelligence. Probeer een kortere vraag.';

  @override
  String get messageTooLongForApple =>
      'Dit bericht is te lang voor Apple Intelligence. Maak het korter en verstuur het opnieuw.';

  @override
  String get vo2maxRunning => 'VO₂max hardlopen';

  @override
  String get vo2maxCycling => 'VO₂max fietsen';

  @override
  String get vo2maxPaceLabel => 'VO₂max-tempo';

  @override
  String get lt1Threshold => 'LT1-drempel';

  @override
  String get lt2Threshold => 'LT2-drempel';

  @override
  String hoursPreviousWeek(Object value) {
    return '$value u vorige week';
  }

  @override
  String kmPreviousWeek(Object value) {
    return '$value km vorige week';
  }

  @override
  String get thirtyMinuteTimeTrial => 'Tijdrit van 30 minuten';

  @override
  String thirtyMinTtDate(Object date) {
    return 'Tijdrit 30 min · $date';
  }

  @override
  String get yesterday2 => 'GISTEREN';

  @override
  String get briefHeadGreen => 'Je bent goed hersteld.';

  @override
  String get briefHeadYellow => 'Je draagt wat belasting mee.';

  @override
  String get briefHeadRed => 'Je staat duidelijk onder belasting.';

  @override
  String briefMain(Object reasons) {
    return 'Belangrijkste redenen: $reasons.';
  }

  @override
  String get briefAllClear => 'Geen van je waarden geeft een waarschuwing.';

  @override
  String get briefAdviceGreen => 'Train volgens plan.';

  @override
  String get briefAdviceYellow =>
      'Houd je aan je plan, maar voeg geen extra intensiteit toe.';

  @override
  String get briefAdviceRed =>
      'Herstel gaat voor: neem een rustige dag of rust.';

  @override
  String get briefReasonHrvLow => 'lage HRV in de slaap';

  @override
  String get briefReasonHrvHigh => 'hoge HRV in de slaap';

  @override
  String get briefReasonRhrUp => 'verhoogde rusthartslag';

  @override
  String get briefReasonRhrDown => 'lage rusthartslag';

  @override
  String get briefReasonSleepShort => 'te weinig slaap';

  @override
  String get briefReasonSleepGood => 'slaapbehoefte gehaald';

  @override
  String get briefReasonEnergyLow => 'weinig energie';

  @override
  String get briefReasonEnergyHigh => 'goede energie';

  @override
  String get briefReasonStressHigh => 'veel stress';

  @override
  String get briefReasonRespHigh => 'verhoogde ademfrequentie';

  @override
  String get briefReasonSpo2Low => 'laag zuurstofgehalte in het bloed';

  @override
  String get briefReasonSkinTempOff => 'ongewone huidtemperatuur';

  @override
  String get briefReasonFormTired => 'opgebouwde trainingsvermoeidheid';

  @override
  String get briefReasonFormVeryTired => 'zeer hoge trainingsvermoeidheid';

  @override
  String get briefReasonFormFresh => 'fris en uitgerust';

  @override
  String get briefTrainingHrvUp =>
      'Je HRV steeg na de training, een goed teken.';

  @override
  String get briefTrainingHrvDown =>
      'Je HRV daalde na de training, een minder goed teken.';

  @override
  String get reminderNeedsNotifications =>
      'De herinnering heeft meldingen nodig. Sta ze toe voor Fjelia in de systeeminstellingen en zet de herinnering daarna weer aan.';

  @override
  String get whatDidYouHave => 'Wat heb je genomen?';

  @override
  String get intakeSomething => 'Ik heb iets genomen';

  @override
  String get intakeNothing => 'Niets';

  @override
  String get totalIntake => 'Totale inname';

  @override
  String get carbsLabel => 'Koolhydraten';

  @override
  String get fluidLabel => 'Vocht';

  @override
  String get sodiumLabel => 'Natrium';

  @override
  String get caffeineLabel => 'Cafeïne';

  @override
  String get detailsOptional => 'Details (optioneel)';

  @override
  String atMinute(Object minute) {
    return 'minuut $minute';
  }

  @override
  String get nothingAddedYet =>
      'Nog niets toegevoegd. Voeg toe wat je hebt gegeten of gedronken, of kies “Niets”.';

  @override
  String get followFocusWeek => 'Waar moet ik me deze week op richten?';

  @override
  String get followRecoveryTrend => 'Hoe ontwikkelt mijn herstel zich?';

  @override
  String get followLoadTooHigh => 'Is mijn trainingsbelasting te hoog?';

  @override
  String get followImproveSleep => 'Wat zou mijn slaap verbeteren?';

  @override
  String get followIntervalsFeel => 'Hoe moeten de intervallen aanvoelen?';

  @override
  String get followTiredToday => 'Wat als ik me vandaag moe voel?';

  @override
  String get followEatBefore => 'Wat moet ik ervoor eten?';

  @override
  String get followAdjustToday => 'Moet ik het vandaag aanpassen?';

  @override
  String get followNextDays => 'Wat betekent het voor mijn komende dagen?';

  @override
  String get followCompareSimilar =>
      'Hoe verhoudt het zich tot vergelijkbare trainingen?';

  @override
  String get followRecover => 'Wat moet ik doen om te herstellen?';

  @override
  String get followIntensityRight => 'Was de intensiteit goed?';

  @override
  String get statusPlanned => 'Gepland';

  @override
  String get statusAdapted => 'Aangepast';

  @override
  String get statusCompleted => 'Voltooid';

  @override
  String get statusRest => 'Rust';

  @override
  String loadValue(Object value) {
    return '$value belasting';
  }

  @override
  String get actIntensityEasy => 'Dat was een rustige aerobe training.';

  @override
  String get actIntensityModerate => 'Dat was een matige training.';

  @override
  String get actIntensityHard => 'Dat was een zware training.';

  @override
  String get actIntensityUnknown => 'Die training is vastgelegd.';

  @override
  String get actLenLonger =>
      'Hij duurde langer dan je vergelijkbare trainingen.';

  @override
  String get actLenShorter => 'Hij was korter dan je vergelijkbare trainingen.';

  @override
  String get actLoadHigher => 'De belasting was hoger dan normaal.';

  @override
  String get actLoadLower => 'De belasting was lager dan normaal.';

  @override
  String get actLoadSame => 'De belasting was ongeveer zoals normaal.';

  @override
  String get actHrLower =>
      'Je hartslag was lager dan normaal, dus het voelde makkelijker.';

  @override
  String get actHrHigher =>
      'Je hartslag was hoger dan normaal, dus het voelde zwaarder.';

  @override
  String get actAdviceUnknown => 'Plan je komende dagen op gevoel.';

  @override
  String briefOutlookRest(Object days) {
    return 'Met ongeveer $days rustige dagen is je vorm weer in het optimale bereik.';
  }

  @override
  String get briefOutlookLongRest =>
      'Je vorm heeft meer dan een paar rustige dagen nodig om te herstellen.';

  @override
  String get briefOutlookPlanTired =>
      'Als je het plan volgt, blijft je vorm de komende dagen laag.';

  @override
  String get localQwen => 'Qwen3.5 · lokaal';

  @override
  String get localModelDescription =>
      'Optioneel Qwen3.5, 4-bit MLX. Download het één keer en gebruik chat en briefings daarna op dit apparaat zonder API-sleutel. Je gezondheidsgegevens blijven op dit apparaat.';

  @override
  String localModelSizeMb(Object megabytes) {
    return '$megabytes MB downloaden · tijdens gebruik is extra geheugen nodig.';
  }

  @override
  String get localModelDownload => 'Model downloaden';

  @override
  String get localModelResumeDownload => 'Download hervatten';

  @override
  String localModelDownloading(Object downloaded, Object total) {
    return '$downloaded / $total MB';
  }

  @override
  String get localModelInstalled => 'Gedownload · offline beschikbaar';

  @override
  String get localModelRemove => 'Model verwijderen';

  @override
  String get localModelUnsupported =>
      'Dit MLX-model heeft een iPhone met iOS 17 of later en een A14-chip of nieuwer nodig. Oudere apparaten worden niet ondersteund.';

  @override
  String get localModelMemoryUnsupported =>
      'Dit apparaat heeft niet genoeg geheugen om het lokale model te draaien.';

  @override
  String get localModelDownloadFailed =>
      'Downloaden mislukt. Probeer het opnieuw; voltooide bestanden blijven bewaard.';

  @override
  String get localModelDownloadFirst =>
      'Download Qwen eerst via Instellingen → AI & meer.';

  @override
  String get localModelContextTooLong =>
      'Dit gesprek is te lang voor het lokale model. Begin een nieuwe chat of maak je vraag korter.';

  @override
  String get localModelBusy =>
      'Het lokale model beantwoordt een ander verzoek. Probeer het zo meteen opnieuw.';

  @override
  String get localModelInterrupted =>
      'Lokaal genereren is onderbroken. Houd Fjelia open en probeer het opnieuw.';

  @override
  String get localModelCouldNotAnswer =>
      'Het lokale model kon niet antwoorden. Controleer het model via Instellingen → AI & meer en probeer het opnieuw.';

  @override
  String get localModelBriefingUnavailable =>
      'Lokale AI-briefing niet beschikbaar. De samenvatting van de app wordt getoond.';

  @override
  String get localModelInfo => 'Modeldetails & licentie';

  @override
  String localModelRamGb(int gigabytes) {
    return 'Vereist minstens $gigabytes GB apparaatgeheugen.';
  }

  @override
  String get localModelIPhone18 => '4B is beschikbaar op iPhone 18 en later.';

  @override
  String briefPlannedTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voor vandaag staan $count trainingen gepland.',
      one: 'Voor vandaag staat $count training gepland.',
    );
    return '$_temp0';
  }

  @override
  String get coachDataFallback =>
      'Het antwoord van het model is in strijd met de gegevens. Hier is de samenvatting van Fjelia:';

  @override
  String get coachSevenDayAverage => 'Gemiddelde van 7 dagen';

  @override
  String coachSleepNeedAndShortfall(String need, String shortfall) {
    return 'Slaapbehoefte: $need u; tekort: $shortfall u.';
  }

  @override
  String coachCurrentForm(String value) {
    return 'Huidige vorm (TSB): $value punten.';
  }

  @override
  String get aiOnboardingStep => 'Stap 2 van 3';

  @override
  String get aiOnboardingTitle => 'Jouw coach.\nOp jouw manier.';

  @override
  String get aiOnboardingSubtitle =>
      'Maak van je gezondheidsgegevens inzichten voor betere training en beter herstel.';

  @override
  String get aiOnboardingChoose => 'KIES JE AI-COACH';

  @override
  String get aiOnboardingFreeDetail => 'Gratis · geen AI-account nodig';

  @override
  String get aiOnboardingFreeBody => 'Cloud-AI voor training en herstel.';

  @override
  String get aiOnboardingRecommended => 'Aanbevolen';

  @override
  String get aiOnboardingOnDevice => 'Op je apparaat';

  @override
  String get aiOnboardingLocalBody =>
      'Je AI-verzoeken blijven op dit apparaat.';

  @override
  String get aiOnboardingUnavailable => 'Momenteel niet beschikbaar';

  @override
  String get aiOnboardingMore => 'Meer AI-modellen';

  @override
  String get aiOnboardingMoreBody => 'Lokaal Qwen of je eigen cloudaanbieder';

  @override
  String get aiOnboardingConsent => 'Cloudverzoeken alleen na je bevestiging.';

  @override
  String get aiOnboardingError =>
      'Je AI-keuze kon niet worden opgeslagen of geladen. Probeer het opnieuw.';

  @override
  String get aiOnboardingWithout => 'Doorgaan zonder AI';

  @override
  String get aiOnboardingConfigure => 'Model instellen';

  @override
  String aiOnboardingContinue(String provider) {
    return 'Doorgaan met $provider';
  }

  @override
  String get aiOnboardingChangeLater =>
      'Je kunt dit altijd wijzigen in Instellingen.';

  @override
  String get creditsAndLicenses => 'Vermeldingen & licenties';

  @override
  String get bioAgeActivity => 'Activiteit';

  @override
  String get bioAgeActivityBasis => 'Activiteitsgegevens · laatste 7 dagen';

  @override
  String bioAgeActivityReported(String minutes) {
    return '$minutes gemelde matige minuten';
  }

  @override
  String bioAgeActivitySteps(String minutes) {
    return '≈ $minutes wandelminuten geschat uit stappen';
  }

  @override
  String bioAgeActivityCoverage(int days) {
    return 'Gegevens voor $days van 7 dagen';
  }

  @override
  String get bioAgeActivityEstimateNotice =>
      'Aanname: 100 stappen ≈ 1 wandelminuut. Dagelijkse stappentotalen zeggen niets over tempo of intensiteit. Gemelde minuten gaan per dag voor; de stappen van die dag tellen dan niet nog eens mee.';

  @override
  String get bioAgeActivityIncomplete =>
      'Er ontbreken activiteitsgegevens. Een bijdrage van activiteit in jaren wordt alleen berekend als alle 7 dagen gegevens hebben.';

  @override
  String get bioAgeActivityEstimatedLabel =>
      'Activiteit bevat geschatte wandeltijd.';

  @override
  String get bioAgeActivityUnknownLabel =>
      'Activiteitsgegevens zijn onvolledig';

  @override
  String get mixTitle => 'Drank mengen';

  @override
  String get mixMyBottle => 'Mijn bidon mengen';

  @override
  String get mixRecipes => 'Recepten';

  @override
  String get mixIngredients => 'Ingrediënten';

  @override
  String get mixAddIngredient => 'Ingrediënt toevoegen';

  @override
  String get mixBottle => 'Bidon';

  @override
  String get mixFilledWithWater => 'aangevuld met water';

  @override
  String mixPerBottle(String ml) {
    return 'per bidon van $ml ml';
  }

  @override
  String get mixStrength => 'Concentratie';

  @override
  String get mixRatio => 'Glucose : fructose';

  @override
  String get mixGlucose => 'Glucose';

  @override
  String get mixFructose => 'Fructose';

  @override
  String get mixGlucoseOnly => 'Alleen glucose';

  @override
  String get mixGentle => 'Licht voor de maag – tot 8 %.';

  @override
  String get mixStrong => 'Geconcentreerd – alleen met een getrainde darm.';

  @override
  String get mixTooStrong => 'Zeer geconcentreerd – voeg water toe.';

  @override
  String get mixNoFructoseHint =>
      'Alleen glucose: boven ongeveer 60 g koolhydraten per uur voeg je fructose (suiker) toe – ongeveer 2:1 wordt beter opgenomen.';

  @override
  String get mixFructoseHeavyHint =>
      'Meer fructose dan glucose kan de maag van streek maken – voeg maltodextrine of dextrose toe.';

  @override
  String get mixSpoonNote =>
      'Lepels verschillen in grootte. Weeg je lepel één keer, of gebruik grammen voor exacte waarden.';

  @override
  String get mixTooMuchLiquid =>
      'Sap en cola alleen zijn al meer dan in de bidon past – maak de bidon groter.';

  @override
  String get mixAddToIntake => 'Aan inname toevoegen';

  @override
  String get mixUseAsBottle => 'Gebruiken als mijn bidon';

  @override
  String get mixDefaultName => 'Drankmix';

  @override
  String get mixEmpty => 'Kies een recept of voeg een ingrediënt toe.';

  @override
  String get mixRemove => 'Verwijderen';

  @override
  String mixRowGrams(String grams) {
    return '≈ $grams g';
  }

  @override
  String mixBottleSaved(String carbs, String ml) {
    return 'Opgeslagen als je bidon: $carbs g koolhydraten per $ml ml.';
  }

  @override
  String get mixMaltodextrin => 'Maltodextrine';

  @override
  String get mixSugar => 'Suiker';

  @override
  String get mixDextrose => 'Dextrose';

  @override
  String get mixHoney => 'Honing';

  @override
  String get mixSalt => 'Zout';

  @override
  String get mixOrangeJuice => 'Sinaasappelsap';

  @override
  String get mixAppleJuice => 'Appelsap';

  @override
  String get mixCola => 'Cola';

  @override
  String get unitTspLevel => 'afgestreken tl';

  @override
  String get unitTspHeaped => 'volle tl';

  @override
  String get unitTbspLevel => 'afgestreken el';

  @override
  String get unitTbspHeaped => 'volle el';

  @override
  String get unitPinch => 'snufje';

  @override
  String get unitTsp => 'tl';

  @override
  String get unitTbsp => 'el';

  @override
  String get mixRecipeMaltoSugar => 'Malto + suiker 2:1';

  @override
  String get mixRecipeJuice => 'Sapspritzer';

  @override
  String get mixRecipeJuicePlus => 'Sapspritzer + malto';

  @override
  String get mixRecipeCola => 'Colaspritzer';

  @override
  String get missedWorkoutTitle => 'Staat vandaag nog op je plan';

  @override
  String missedWorkoutBody(String workouts) {
    return '$workouts. Nog vandaag, verplaatsen of overslaan?';
  }

  @override
  String get stillToday => 'Nog vandaag';

  @override
  String get moveWorkoutAction => 'Verplaatsen…';

  @override
  String get missedWorkoutChannel => 'Gemiste trainingen';

  @override
  String get missedWorkoutChannelDescription =>
      'Herinnering \'s avonds aan geplande trainingen die die dag nog openstaan';

  @override
  String get missedWorkoutReminder => 'Herinnering voor gemiste training';

  @override
  String get missedWorkoutReminderSubtitle =>
      '\'s Avonds, als een geplande training nog openstaat';

  @override
  String get moveWithinDays => 'Verplaatsen binnen';

  @override
  String daysN(int count) {
    return '$count dagen';
  }

  @override
  String get notificationsAreOff =>
      'Meldingen staan uit voor Fjelia. Sta ze toe om deze herinnering te krijgen.';

  @override
  String get allowNotifications => 'Meldingen toestaan';

  @override
  String get openWorkoutToday => 'Vandaag nog open';

  @override
  String get checkingForWorkout => 'Je training wordt gezocht…';

  @override
  String get alreadyDone => 'Al gedaan ✓';

  @override
  String get alreadyDoneBody =>
      'Je training is vastgelegd. Vandaag hoef je niets meer te doen.';

  @override
  String get dropIt => 'Laten vallen';

  @override
  String askCoachSends(String provider) {
    return 'Stuurt je trainingsoverzicht naar $provider.';
  }

  @override
  String get coachThinking => 'De coach denkt na…';

  @override
  String get coachCouldNotAnswer =>
      'De coach kon niet antwoorden. Het voorstel hierboven blijft staan.';

  @override
  String get whySkip => 'Waarom overslaan?';

  @override
  String get skipReasonIllness => 'Ziekte';

  @override
  String get skipReasonInjury => 'Blessure of pijn';

  @override
  String get skipReasonFatigue => 'Vermoeidheid';

  @override
  String get skipReasonNoTime => 'Geen tijd';

  @override
  String get skipReasonTravel => 'Op reis';

  @override
  String get skipReasonConditions => 'Omstandigheden';

  @override
  String get skipReasonMyChoice => 'Eigen keuze';

  @override
  String get onbReminderTitle => 'Blijf op koers';

  @override
  String get onbReminderSubtitle =>
      'Als een geplande training \'s avonds nog openstaat, herinnert Fjelia je er één keer aan, zodat je hem nog kunt doen, verplaatsen of overslaan.';

  @override
  String get onbExampleWorkout => 'Rustige duurloop (45 min)';

  @override
  String get onbReminderToggle => 'Herinnering \'s avonds';

  @override
  String get onbReminderTime => 'Herinner me om';

  @override
  String get onbReminderFootnote =>
      'Je kunt dit altijd wijzigen in Instellingen → Training.';

  @override
  String get nowLabel => 'nu';

  @override
  String get coachSuggests => 'Coach stelt voor';

  @override
  String get suggestionLabel => 'Voorstel';

  @override
  String get askCoachShort => 'Vraag coach';

  @override
  String get otherDay => 'Andere dag';

  @override
  String get skipEllipsis => 'Overslaan…';

  @override
  String get pickADay => 'Tik hierboven op een dag';

  @override
  String get dayDoesNotFit => 'Die dag past niet in het plan.';

  @override
  String get planUpdated => 'Plan bijgewerkt';

  @override
  String get missedTodayTag => 'vandaag gemist';

  @override
  String summaryMove(String day) {
    return 'Verplaats hem naar $day.';
  }

  @override
  String summaryMoveIndoor(String day) {
    return 'Verplaats hem naar $day, binnen – er wordt regen verwacht.';
  }

  @override
  String get summaryDropEasy =>
      'Laat hem vallen – een rustige training hoef je niet in te halen.';

  @override
  String summaryDropNoDay(int days) {
    return 'Laat hem vallen – er past geen dag in de komende $days dagen.';
  }

  @override
  String get tagIndoor => 'binnen';

  @override
  String get tagEasier => 'lichter';

  @override
  String get tagRecovery => 'herstel';

  @override
  String summaryMoveEasier(String day) {
    return 'Verplaats hem naar $day, iets lichter – hij ligt naast een zware dag.';
  }

  @override
  String get briefRestDayToday => 'Vandaag is een geplande rustdag.';

  @override
  String get restDayPlannedNote => 'Herstel hoort bij je plan.';

  @override
  String get restDayTitle => 'Rustdag';

  @override
  String get importActivityFile => 'Activiteitsbestand importeren';

  @override
  String get activityFileImportHint =>
      'FIT-, GPX- of TCX-bestanden (ook gezipt, zoals Garmin Connect ze exporteert) van een fietscomputer, Zwift, Strava of een andere app. Je kunt een bestand ook vanuit de Bestanden-app of het deelmenu met Fjelia delen.';

  @override
  String get chooseActivityFiles => 'Bestanden kiezen';

  @override
  String get chooseOtherFiles => 'Andere bestanden kiezen';

  @override
  String get activityFileUnreadable => 'Geen leesbaar activiteitsbestand';

  @override
  String get activityFileAlreadyImported => 'Al geïmporteerd';

  @override
  String activityFileAlreadyFrom(String source) {
    return 'Al in Fjelia via $source';
  }

  @override
  String importActivities(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activiteiten importeren',
      one: '$count activiteit importeren',
    );
    return '$_temp0';
  }

  @override
  String activitiesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activiteiten geïmporteerd.',
      one: '$count activiteit geïmporteerd.',
    );
    return '$_temp0';
  }

  @override
  String get activityFileSource => 'Bestand';

  @override
  String get dfaAlpha1Title => 'Aerobe drempel (DFA α1)';

  @override
  String get dfaHrvt1 => 'Aerobe drempel (HRVT1)';

  @override
  String get dfaHrvt2 => 'Anaerobe drempel (HRVT2)';

  @override
  String dfaEasyShare(String percent) {
    return '$percent % van de training onder je aerobe drempel (α1 ≥ 0,75).';
  }

  @override
  String get dfaNoThreshold =>
      'De training ging niet duidelijk over een drempel. Een ramp of een training die van rustig naar zwaar opbouwt, levert een schatting.';

  @override
  String dfaBeats(int beats, String artifacts) {
    return '$beats slagen · $artifacts % artefacten';
  }

  @override
  String get dfaArtifactsHigh =>
      'Veel artefacten: controleer of de borstband stevig zit en de elektroden vochtig zijn.';

  @override
  String get dfaExplainer =>
      'Uit de slag-tot-slaggegevens van een borstband. α1 rond 1 is rustig, 0,75 markeert de aerobe drempel, 0,5 de anaerobe. Een schatting, geen labtest.';

  @override
  String get thresholdOrderNote =>
      'Fjelia vergelijkt alle bronnen. Eerst stelt het de eigen tests van de app voor, dan je horloge, dan DFA α1 over meerdere trainingen, dan het Polar-profiel en formules. Er verandert niets tot je het toepast.';

  @override
  String thresholdInUse(String value) {
    return 'In gebruik: $value';
  }

  @override
  String thresholdProposal(String value, String source) {
    return 'Voorgesteld: $value uit $source';
  }

  @override
  String get keepCurrent => 'Huidige houden';

  @override
  String get lt2Cycling => 'LT2 · Fietsen';

  @override
  String get thresholdSourceTt => 'Tijdrit van 30 minuten';

  @override
  String get thresholdSourceDrift => 'Hartslagdrifttest';

  @override
  String thresholdSourceDfa(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DFA α1, $count trainingen',
      one: 'DFA α1, $count training',
    );
    return '$_temp0';
  }

  @override
  String get thresholdSourceEftp => 'eFTP uit ritten';

  @override
  String get thresholdSourcePolarProfile => 'Polar-profiel';

  @override
  String get thresholdFormulaLt2 => 'LT2 − 30 bpm';

  @override
  String get thresholdFormulaMaxHr => '77 % van max. hartslag';

  @override
  String get thresholdStale => 'ouder dan 6 maanden';

  @override
  String get thresholdsCoachLocked =>
      'Je coach beheert je drempels, dus je kunt ze hier niet wijzigen.';

  @override
  String get mediaTitle => 'Foto\'s & video\'s';

  @override
  String get mediaAdd => 'Toevoegen';

  @override
  String get mediaFromLibrary => 'Kiezen uit bibliotheek';

  @override
  String get mediaTakePhoto => 'Foto maken';

  @override
  String get mediaRecordVideo => 'Video opnemen';

  @override
  String mediaAdding(int done, int total) {
    return '$done van $total toevoegen…';
  }

  @override
  String get mediaMoveEarlier => 'Naar voren';

  @override
  String get mediaMoveLater => 'Naar achteren';

  @override
  String get mediaDeleteTitle => 'Uit Fjelia verwijderen?';

  @override
  String get mediaDeleteMessage =>
      'Hiermee wordt de foto of video uit Fjelia verwijderd. Het origineel in je fotobibliotheek blijft.';

  @override
  String get mediaAddFailed =>
      'Sommige bestanden konden niet worden toegevoegd.';

  @override
  String get mediaHint =>
      'Tik om te bekijken, houd vast om te verplaatsen of te verwijderen.';

  @override
  String get backupVideosTitle => 'Video\'s meenemen?';

  @override
  String backupVideosMessage(String size) {
    return 'Je video\'s nemen $size in beslag. Zonder video\'s is de back-up veel kleiner; foto\'s gaan altijd mee.';
  }

  @override
  String get backupWithVideos => 'Met video\'s';

  @override
  String get backupWithoutVideos => 'Zonder video\'s';

  @override
  String get mediaShareCard => 'Delen als kaart';

  @override
  String get mediaShareCardHint =>
      'Sleep het paneel of de route om ze te verplaatsen. Knijp en sleep de foto om hem in te kaderen; dubbeltikken zet hem terug.';

  @override
  String get shareGymPhoto => 'Sportschoolfoto';

  @override
  String get shareWithoutPhoto => 'Zonder foto';

  @override
  String get shareStyleGlass => 'Glas';

  @override
  String get shareStylePoster => 'Poster';

  @override
  String get shareStyleMinimal => 'Minimaal';

  @override
  String get shareStyleNeon => 'Neon';

  @override
  String get shareStyleSticker => 'Sticker';

  @override
  String get shareStyleReceipt => 'Kassabon';

  @override
  String get shareStyleKpop => 'K-pop';

  @override
  String get shareStylePixel => 'Pixel';

  @override
  String get shareStyleRobot => 'Robot';

  @override
  String get shareStyleScifi => 'Sciencefiction';

  @override
  String get shareStyleCard => 'Ruilkaart';

  @override
  String get shareStyleComic => 'Strip';

  @override
  String get shareStyleOutdoor => 'Outdoor';

  @override
  String get shareStyleHolo => 'Holokaart';

  @override
  String get shareStyleHoloFull => 'Full-art-kaart';

  @override
  String nowcastRainSoon(int minutes) {
    return 'Regen over ongeveer $minutes min';
  }

  @override
  String nowcastRainingStops(int minutes) {
    return 'Het regent nu · droog over ongeveer $minutes min';
  }

  @override
  String nowcastRainingOn(int minutes) {
    return 'Het regent nu, nog minstens $minutes min';
  }

  @override
  String nowcastDry(int minutes) {
    return 'Droog in de komende $minutes min';
  }

  @override
  String get sunAndMoon => 'Zon & maan';

  @override
  String get moonNew => 'Nieuwe maan';

  @override
  String get moonWaxingCrescent => 'Wassende sikkel';

  @override
  String get moonFirstQuarter => 'Eerste kwartier';

  @override
  String get moonWaxingGibbous => 'Wassende maan';

  @override
  String get moonFull => 'Volle maan';

  @override
  String get moonWaningGibbous => 'Afnemende maan';

  @override
  String get moonLastQuarter => 'Laatste kwartier';

  @override
  String get moonWaningCrescent => 'Afnemende sikkel';

  @override
  String moonLit(int percent) {
    return '$percent % verlicht';
  }

  @override
  String daylightLength(int hours, int minutes) {
    return '$hours u $minutes min daglicht';
  }

  @override
  String h10Battery(int level) {
    return 'Batterij $level %';
  }

  @override
  String get h10BatteryUnknown => 'Batterij nog niet uitgelezen';

  @override
  String h10BatteryChecked(String date) {
    return 'Gecontroleerd $date';
  }

  @override
  String get h10BatteryLowHint =>
      'Laag: vervang de CR2025-knoopcel binnenkort.';

  @override
  String get h10BatteryCheck => 'Batterij controleren';

  @override
  String get h10BatteryUnreachable =>
      'De H10 reageerde niet. Doe hem om (of maak de contacten nat) en probeer het opnieuw.';

  @override
  String get shareRaceCalendar => 'Wedstrijdkalender delen';

  @override
  String get raceSeasonTitle => 'Mijn wedstrijdseizoen';

  @override
  String get raceShareStylePoster => 'Poster';

  @override
  String get raceShareStyleTickets => 'Tickets';

  @override
  String get raceShareStyleTimeline => 'Neontijdlijn';

  @override
  String get raceShareStyleMagazine => 'Tijdschrift';

  @override
  String get raceShareShowTarget => 'Doeltijden tonen';

  @override
  String get bpOptimal => 'OPTIMAAL';

  @override
  String get bpHighNormal => 'HOOG-NORMAAL';

  @override
  String get bpLow => 'LAAG';

  @override
  String get bpLowHint =>
      'Lage bloeddruk: alleen een punt van zorg als je duizelig of licht in het hoofd bent.';

  @override
  String get waistCircumference => 'Tailleomtrek';

  @override
  String get hipOptional => 'Heup (optioneel)';

  @override
  String get waistToHeightRatio => 'Taille-lengteverhouding';

  @override
  String get waistToHipRatio => 'Taille-heupverhouding';

  @override
  String get waistRiskLow => 'Zeer slank';

  @override
  String get waistRiskHealthy => 'Gezond';

  @override
  String get waistRiskIncreased => 'Verhoogd risico';

  @override
  String get waistRiskHigh => 'Hoog risico';

  @override
  String get waistHowToMeasure =>
      'Meet \'s ochtends staand na het uitademen: de taille halverwege de onderste rib en de bovenkant van het heupbot, de heup op het breedste punt.';

  @override
  String get waistNeedsHeight =>
      'Voeg je lengte toe in Instellingen → Profiel.';

  @override
  String get waistNeedsHip => 'Meet je heup één keer voor de WHR.';

  @override
  String get waistSyncsProfile =>
      'De nieuwste meting is ook je taille in Instellingen.';

  @override
  String get waistChange30d => '30 dagen';

  @override
  String get waistChange90d => '90 dagen';

  @override
  String get waistChange1y => '1 jaar';

  @override
  String get waistDeleteText =>
      'Hiermee wordt de gekozen taillemeting verwijderd.';

  @override
  String waistAndHip(String waist, String hip) {
    return '$waist cm · heup $hip cm';
  }

  @override
  String hipValue(String hip) {
    return 'Heup $hip cm';
  }

  @override
  String get whtrTargetHint => 'Houd je taille onder de helft van je lengte.';

  @override
  String get noWaistYet => 'Nog geen taille gemeten.';

  @override
  String get enterValidWaist =>
      'Voer een taille en heup tussen 20 en 300 cm in.';

  @override
  String get waistFromProfile => 'Uit je profiel, zonder datum';

  @override
  String get phaseBase => 'BASIS';

  @override
  String get phaseBuild => 'OPBOUW';

  @override
  String get phasePeak => 'PIEK';

  @override
  String get phaseTaper => 'AFBOUW';

  @override
  String get phaseRecovery => 'HERSTEL';

  @override
  String get phaseRace => 'WEDSTRIJD';

  @override
  String get sessionTypeKey => 'KERN';

  @override
  String get sessionTypeLong => 'LANG';

  @override
  String get sessionTypeRecovery => 'HERSTEL';

  @override
  String get sessionTypeAssessment => 'TEST';

  @override
  String get sessionTypeEndurance => 'DUUR';

  @override
  String get sessionTypeStrength => 'KRACHT';

  @override
  String get sessionTypeYoga => 'YOGA';

  @override
  String get sessionStatusCompleted => 'VOLTOOID';

  @override
  String get sessionStatusAdapted => 'AANGEPAST';

  @override
  String get stepWarmUp => 'Warming-up';

  @override
  String get stepCoolDown => 'Cooling-down';

  @override
  String get stepRecovery => 'Herstel';

  @override
  String get stepRest => 'Rust';

  @override
  String get stepInterval => 'Interval';

  @override
  String get stepWorkout => 'Training';

  @override
  String stepRepeat(int n) {
    return '$n× herhalen';
  }

  @override
  String get stepOpenEnded => 'Zonder einde';

  @override
  String stepSeconds(int n) {
    return '$n sec';
  }

  @override
  String get objectiveOptionalVariety =>
      'Optionele afwisseling die je in de instellingen hebt gekozen';

  @override
  String get objectiveStrengthSupport =>
      'Kracht ter ondersteuning van je training';

  @override
  String objectiveIntervals(String goal) {
    return 'Intervallen voor $goal';
  }

  @override
  String objectiveSteady(String sport, String goal) {
    return 'Gelijkmatige kwaliteitstraining $sport voor $goal';
  }

  @override
  String objectiveEasyRecovery(String sport, String goal) {
    return 'Rustig $sport: herstel rond $goal';
  }

  @override
  String objectiveEasyEndurance(String sport, String goal) {
    return 'Rustige duurtraining $sport voor $goal';
  }

  @override
  String objectiveLong(String sport, String goal) {
    return 'Lange $sport voor $goal';
  }

  @override
  String unmetWeekMinutes(int minutes, String sport, String goal) {
    return 'De week biedt $minutes min, te weinig voor een lange $sport voor $goal.';
  }

  @override
  String unmetWeekHours(String hours, String what) {
    return 'De week biedt $hours u, te weinig voor $what.';
  }

  @override
  String unmetTrainingDays(String what) {
    return 'Niet genoeg trainingsdagen voor $what.';
  }

  @override
  String get altMoveOneEvent => 'Verplaats een van de evenementen';

  @override
  String get altMarkOneCancelled => 'Markeer er een als geannuleerd';

  @override
  String altMakePriorityB(String goal) {
    return 'Geef $goal prioriteit B';
  }

  @override
  String altSkipGoal(String goal) {
    return '$goal overslaan';
  }

  @override
  String altTreatAsTraining(String goal) {
    return '$goal als trainingsevenement behandelen';
  }

  @override
  String altControlledEffort(String goal) {
    return '$goal als gecontroleerde inspanning rijden';
  }

  @override
  String conflictSameDay(String a, String b) {
    return '$a en $b vallen op dezelfde dag. Er kan er maar één voluit gelopen worden.';
  }

  @override
  String conflictBothPriorityA(String a, String b, int gap, int more) {
    return '$a en $b hebben allebei prioriteit A en liggen $gap dagen uit elkaar. Herstel na de eerste en aanscherping voor de tweede hebben $more dagen meer nodig.';
  }

  @override
  String conflictFlexibleOverlap(
    String a,
    String b,
    int gap,
    int overlap,
    String skip,
  ) {
    return '$a en $b liggen $gap dagen uit elkaar en overlappen $overlap dagen. $skip is als flexibel gemarkeerd: als je het laat vallen, komen de weken voor het andere evenement vrij.';
  }

  @override
  String conflictRecoveryOverlap(String a, String b, int gap, int overlap) {
    return '$a en $b liggen $gap dagen uit elkaar: het herstel na de eerste overlapt $overlap dagen met de aanscherping voor de tweede. De voorbereiding met lagere prioriteit wordt beperkt om de andere te beschermen.';
  }

  @override
  String conflictTightSpacing(String a, String b, int gap, int spare) {
    return '$a en $b liggen $gap dagen uit elkaar. Herstel en aanscherping passen met $spare dagen speling, dus elke tegenvaller laat geen ruimte.';
  }

  @override
  String seasonShortened(int n, int of) {
    return 'In $n van $of weken past de wekelijkse tijd niet alle lange trainingen van elk doel, dus worden ze samen ingekort.';
  }

  @override
  String seasonAlternating(int n) {
    return 'In $n weken passen niet alle lange trainingen in de week; de sporten wisselen elkaar af.';
  }

  @override
  String seasonLongAway(int n) {
    return 'In $n weken staat een lange training van meer dan tweeënhalf uur niet op de gebruikelijke dag, vanwege je rustdagen en de andere trainingen.';
  }

  @override
  String seasonMovedOntoEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n trainingen die je hebt verplaatst, vallen op een evenementdag of de rustdag ervoor. Het plan laat ze waar je ze hebt gezet.',
      one:
          '$n training die je hebt verplaatst, valt op een evenementdag of de rustdag ervoor. Het plan laat hem waar je hem hebt gezet.',
    );
    return '$_temp0';
  }

  @override
  String seasonNoRoom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n trainingen zijn weggelaten omdat de gekozen workouts langer duurden dan de resterende tijd in de week.',
      one:
          '$n training is weggelaten omdat de gekozen workouts langer duurden dan de resterende tijd in de week.',
    );
    return '$_temp0';
  }

  @override
  String seasonMovedHardNearEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n zware trainingen die je hebt verplaatst, vallen in de rustige dagen na een evenement. Het plan laat ze waar je ze hebt gezet.',
      one:
          '$n zware training die je hebt verplaatst, valt in de rustige dagen na een evenement. Het plan laat hem waar je hem hebt gezet.',
    );
    return '$_temp0';
  }

  @override
  String get seasonEventWeeks =>
      'In evenementweken telt het evenement als training, dus de rest van de week is lichter.';

  @override
  String seasonUnmet(int n, String detail) {
    return 'In $n weken bieden de trainingsdagen niet ruimte voor elke beschermde training: $detail';
  }

  @override
  String seasonNoHistory(String sport, String priority) {
    return 'Er staat geen recente $sport in je geschiedenis, dus het plan voor het $priority-doel is voorlopig.';
  }

  @override
  String get zoneRecovery => 'Herstel';

  @override
  String workoutSentKeptInFjelia(String provider, String items) {
    return 'Verstuurd naar $provider. Alleen in Fjelia bewaard: $items.';
  }

  @override
  String paceGuideRange(String low, String high) {
    return 'Tempo-advies $low tot $high';
  }

  @override
  String get paceGuideFromGoal => ', geschat op basis van je doel';

  @override
  String paceGuideGoalFlat(String pace) {
    return ' · doeltempo op vlak terrein $pace';
  }

  @override
  String get paceGuideHeartRateDecides => 'De hartslag beslist.';

  @override
  String get moveKeyRestDay => 'rustdag';

  @override
  String get moveKeyEvent => 'evenement';

  @override
  String get moveKeyEasyOnly => 'alleen rustig';

  @override
  String get moveKeyHasSession => 'heeft een training';

  @override
  String get calendarCompleted => 'Voltooid';

  @override
  String get calendarPlanned => 'Gepland';

  @override
  String get recentlyDeleted => 'Recent verwijderd';

  @override
  String get recentlyDeletedExplain =>
      'Verwijderde activiteiten blijven verwijderd, ook als je apparaten opnieuw synchroniseren. Herstel er een om haar terug te halen; de bron stuurt dan route en curves opnieuw als die er nog zijn.';

  @override
  String get noDeletedActivities => 'Geen verwijderde activiteiten.';

  @override
  String activityDeleted(String name) {
    return '$name verwijderd';
  }

  @override
  String activityRestored(String name) {
    return '$name hersteld';
  }

  @override
  String activityRestoredSummaryOnly(String name) {
    return '$name hersteld met de totalen; de bron stuurt geen route en curves meer.';
  }

  @override
  String deletedOn(String date) {
    return 'verwijderd $date';
  }

  @override
  String get restore => 'Herstellen';

  @override
  String get coachWhyThisToday => 'Waarom vandaag deze training?';

  @override
  String get coachHowDidItGo => 'Hoe ging deze training?';

  @override
  String get coachWhyRestDay => 'Waarom is dit een rustdag?';

  @override
  String get coachWhatInstead => 'Wat moet ik in plaats daarvan doen?';

  @override
  String get newChat => 'Nieuwe chat';

  @override
  String weekOfPlanned(String duration) {
    return 'van $duration gepland';
  }

  @override
  String get weekDoneNothingPlanned => 'voltooid · geen trainingen gepland';

  @override
  String sessionDropped(String reason, String duration) {
    return '$reason · $duration vervallen';
  }

  @override
  String get importTitle => 'Importeren';

  @override
  String get stravaArchive => 'Strava-archief';

  @override
  String get stravaArchiveZip => 'Strava-archief (zip)';

  @override
  String get stravaArchiveSubtitle =>
      'Je hele Strava-geschiedenis met routes en foto\'s';

  @override
  String get stravaIntro =>
      'Breng je hele Strava-geschiedenis naar Fjelia: activiteiten met route, hartslag en vermogen, en hun foto\'s.';

  @override
  String get stravaHowTo =>
      'Op strava.com: Instellingen → Mijn account → Je account downloaden of verwijderen → Archief aanvragen. Strava mailt je een zip; kies hem hier zoals hij is, zonder uitpakken.';

  @override
  String get stravaChooseZip => 'Zip kiezen';

  @override
  String get stravaReading => 'Archief wordt gelezen…';

  @override
  String get stravaNotArchive =>
      'Deze zip is geen Strava-accountarchief: activities.csv ontbreekt.';

  @override
  String stravaFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activiteiten gevonden',
      one: '$count activiteit gevonden',
    );
    return '$_temp0';
  }

  @override
  String stravaWithFiles(int count) {
    return '$count met opname (route en curves)';
  }

  @override
  String stravaPhotos(int photos, int videos) {
    return '$photos foto\'s, $videos video\'s';
  }

  @override
  String stravaAlready(int count) {
    return '$count dubbel, al in Fjelia of twee keer in Strava: alleen hun ontbrekende foto\'s worden toegevoegd';
  }

  @override
  String stravaDeletedSkip(int count) {
    return '$count eerder verwijderd, overgeslagen';
  }

  @override
  String stravaNew(int count) {
    return '$count nieuw';
  }

  @override
  String stravaStorage(int mb) {
    return 'ongeveer $mb MB voor foto\'s en video\'s';
  }

  @override
  String get stravaPrivacy =>
      'Alles wordt op dit apparaat gelezen. Er wordt niets geüpload en er is geen Strava-login nodig.';

  @override
  String stravaImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activiteiten importeren',
      one: '$count activiteit importeren',
    );
    return '$_temp0';
  }

  @override
  String get stravaImporting => 'Strava-archief importeren';

  @override
  String stravaProgressActivities(String done, String total) {
    return 'Activiteiten: $done / $total';
  }

  @override
  String stravaImportedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activiteiten geïmporteerd',
      one: '$count activiteit geïmporteerd',
    );
    return '$_temp0';
  }

  @override
  String stravaProgressPhotos(int count) {
    return 'Foto\'s: $count geïmporteerd';
  }

  @override
  String stravaProgressDuplicates(int count) {
    return 'Dubbel: $count overgeslagen';
  }

  @override
  String stravaProgressDeleted(int count) {
    return 'Eerder verwijderd: $count overgeslagen';
  }

  @override
  String stravaProgressErrors(int count) {
    return 'Fouten: $count';
  }

  @override
  String get stravaKeepOpen =>
      'Je kunt de app ondertussen gebruiken. Houd Fjelia open tot de import klaar is.';

  @override
  String get stravaComplete => 'Strava-import voltooid';

  @override
  String get stravaPartial => 'Strava-import onvolledig';

  @override
  String get stravaCancelled => 'Strava-import geannuleerd';

  @override
  String get stravaShowErrors => 'Fouten tonen';

  @override
  String get stravaAgainHint =>
      'Als je hetzelfde archief opnieuw importeert, wordt alleen toegevoegd wat nog ontbreekt.';

  @override
  String get renameActivity => 'Activiteit hernoemen';

  @override
  String get activityTitleLabel => 'Titel';

  @override
  String get activityTitleKept =>
      'Je titel blijft als de activiteit opnieuw synchroniseert. Hij verandert alleen in Fjelia, niet op het platform waar hij vandaan komt.';

  @override
  String originalTitle(String name) {
    return 'Origineel: $name';
  }

  @override
  String get useOriginalTitle => 'Oorspronkelijke titel gebruiken';

  @override
  String get loadOlderActivities => 'Oudere activiteiten laden';

  @override
  String get noOlderActivities => 'Geen oudere activiteiten';

  @override
  String get maxSpeed => 'Max. snelheid';

  @override
  String get caloriesLabel => 'Calorieën';

  @override
  String get activityDescription => 'Beschrijving';

  @override
  String get nightCurves => 'Nachtcurves';

  @override
  String get noPhaseTimeline =>
      'Dit horloge geeft niet aan wanneer elke slaapfase plaatsvond, alleen de totalen hierboven. Dit zijn de HRV en stress die het \'s nachts heeft gemeten.';

  @override
  String get stagesEstimated =>
      'Door Fjelia geschat uit de HRV en stress die je COROS-horloge \'s nachts heeft gemeten. De totalen per fase zijn van COROS zelf; wanneer elke fase plaatsvond, is een benadering.';

  @override
  String get nightCurvesBasis =>
      'De HRV en stress die \'s nachts zijn gemeten. De fase-schatting hierboven is daarop gebaseerd.';

  @override
  String get swimShort =>
      'Water is meestal genoeg. Geen energiegels nodig: een normale maaltijd voor en na volstaat voor deze zwemtraining.';

  @override
  String get swimPoolLong =>
      'Overweeg een koolhydraatdrank in langere pauzes tussen sets, vooral bij een intensieve training. Gels zijn in het zwembad niet nodig.';

  @override
  String get swimOpenFeeds =>
      'Plan koolhydraten en vocht rond de beschikbare voedingsmomenten (boot, kajak, kant). Reken niet op voeding die je tijdens het zwemmen niet veilig kunt bereiken.';

  @override
  String get swimOpenUnsupported =>
      'Geen voeding tijdens een zwemtocht zonder begeleiding: eet vooraf goed, houd de afstand binnen wat dat dekt en vul direct daarna aan.';

  @override
  String get swimOpenFeedsUnknown =>
      'Open water: geef onder Strategie bewerken aan of voeding mogelijk is (met of zonder begeleiding).';

  @override
  String get swimFluidPool =>
      'Ook in het zwembad telt vocht: je zweet in water minder dan op het land, maar niet niets. Zet een gelabelde fles op de kant en drink in de pauzes.';

  @override
  String get swimFluidOpen =>
      'Luchtvoorspellingen geven de watertemperatuur niet, en koud water dempt de dorst: drink vóór de start, bij elk voedingsmoment en direct na afloop.';

  @override
  String get swimBeforeAfter =>
      'Vooraf: een vertrouwde koolhydraatmaaltijd 1–4 u ervoor. Na afloop: ongeveer 1 g koolhydraten per kg met 20–25 g eiwit; als je jezelf hebt gewogen, drink ongeveer 1,5 l per verloren kg, met wat natrium.';

  @override
  String get swimNoDuration =>
      'Geen geplande duur: water aan de rand van het bad is voor de meeste zwemtrainingen genoeg; voeg alleen bij zwemmen van meer dan 90 minuten een koolhydraatdrank toe.';

  @override
  String swimCarryPool(String bottles, String bottleMl, String drinkCarbs) {
    return 'Geen gels. Fles aan de rand van het bad: $bottles × $bottleMl ml; $drinkCarbs g koolhydraten komt uit de sportdrank.';
  }

  @override
  String swimCarryOpen(String bottles, String bottleMl, String drinkCarbs) {
    return 'Geen gels tijdens het zwemmen. Bij voedingsmomenten: $bottles × $bottleMl ml; $drinkCarbs g koolhydraten komt uit de sportdrank.';
  }

  @override
  String swimPerBreak(String carbs, String fluid) {
    return 'Per 20 minuten, bij een pauze of voedingsmoment: ongeveer $carbs g koolhydraten en $fluid ml.';
  }

  @override
  String get feedsLabel => 'Voeding (open water)';

  @override
  String get feedsSupported => 'Met begeleiding (boot, kajak, kant)';

  @override
  String get feedsUnsupported => 'Zonder begeleiding';

  @override
  String get feedsUnknown => 'Onbekend';

  @override
  String get ecgTitle => 'ECG';

  @override
  String get ecgChooseDevice => 'Polar H10 kiezen';

  @override
  String get ecgStart => 'ECG opnemen';

  @override
  String get ecgStopSave => 'Stoppen en opslaan';

  @override
  String get ecgImport => 'ECG-bestand importeren';

  @override
  String get ecgHistory => 'ECG-geschiedenis';

  @override
  String get ecgWaveform => 'Golfvorm';

  @override
  String get ecgReport => 'Rapport';

  @override
  String get ecgExportCsv => 'Golfvorm exporteren (CSV)';

  @override
  String get ecgExportMetadata => 'ECG-metadata exporteren';

  @override
  String get ecgExportOriginal => 'Origineel bestand delen';

  @override
  String get ecgRecording => 'ECG wordt opgenomen';

  @override
  String get ecgRecordingDate => 'Datum en tijd van de opname';

  @override
  String get ecgLinkedWorkout => 'Gekoppelde training';

  @override
  String get ecgIndependent => 'Geen gekoppelde training';

  @override
  String get ecgNoRecordings => 'Nog geen ECG-opnamen.';

  @override
  String ecgSamples(int count) {
    return '$count meetpunten';
  }

  @override
  String ecgSignalGaps(int count) {
    return '$count signaalonderbrekingen';
  }

  @override
  String get ecgDeleteConfirm =>
      'Deze opname en het originele bestand definitief verwijderen?';

  @override
  String get ecgDescription =>
      'Neem op met de Polar H10, importeer CSV-golfvormen of bewaar pdf-rapporten.';

  @override
  String get ecgPrivacy =>
      'Opgeslagen op dit apparaat en opgenomen in je back-ups. Ruwe signalen worden niet naar de coach gestuurd.';

  @override
  String get ecgLimitations =>
      'Voor persoonlijke opname en controle. Uit ECG afgeleide HRV en signaalkwaliteit zijn hier niet gevalideerd; er wordt geen diagnose of herstelscore berekend.';

  @override
  String get ecgImportLimitations =>
      'Pdf-exports van Garmin en Apple Watch zijn rapporten. Golfvormen vereisen de CSV-kolommen time_seconds (of time_ms) en ecg_uv (of ecg_mv).';

  @override
  String get ecgReportOnly =>
      'Alleen rapport. Er zijn geen ruwe golfvormwaarden beschikbaar. Deel het originele bestand om het rapport te bekijken.';

  @override
  String get indoorTitle => 'Binnentraining';

  @override
  String get indoorEquipment => 'Fitnessapparaat';

  @override
  String get indoorChooseEquipment => 'Apparaat kiezen';

  @override
  String get indoorChooseHeartRate => 'Hartslagsensor kiezen';

  @override
  String get indoorStart => 'Opname starten';

  @override
  String get indoorPause => 'Opname pauzeren';

  @override
  String get indoorFinish => 'Afronden en opslaan';

  @override
  String get indoorSaved => 'Opgeslagen in de activiteitengeschiedenis';

  @override
  String get indoorExportFit => 'FIT-activiteit delen';

  @override
  String get indoorUnfinished => 'Onafgemaakte opnamen';

  @override
  String get indoorReviewResume => 'Bekijken of hervatten';

  @override
  String get indoorDiscard => 'Opname verwerpen';

  @override
  String get indoorDiscardConfirm =>
      'Deze onafgemaakte opname definitief verwerpen?';

  @override
  String get indoorExternalHeartRate => 'Externe hartslagsensor gebruiken';

  @override
  String get indoorEquipmentHeartRate =>
      'Uit: hartslag van het apparaat gebruiken';

  @override
  String get indoorCurrentInterval => 'Huidig interval';

  @override
  String get indoorNextInterval => 'Volgend interval';

  @override
  String get indoorPlanComplete => 'Geplande intervallen voltooid';

  @override
  String get indoorAuthorizeControl => 'Bediening van het apparaat toestaan';

  @override
  String get indoorManualOverride => 'Handmatige bediening gebruiken';

  @override
  String get indoorAutoPower => 'Intervalvermogen automatisch volgen';

  @override
  String get indoorApplyTarget => 'Doel toepassen';

  @override
  String get indoorDescription =>
      'Koppel een Bluetooth-FTMS-apparaat en leg een binnentraining vast.';

  @override
  String get indoorKeepOpen =>
      'De opname loopt door als je van app wisselt of het scherm vergrendelt. Pauzeren stopt het vastleggen van waarden; gebruik de bediening van het apparaat om de machine te pauzeren.';

  @override
  String get indoorFitHint =>
      'Sla het FIT-bestand op of open het via het deelmenu in een compatibele trainingsapp.';

  @override
  String get indoorNoEquipment =>
      'Geen FTMS-apparaat gevonden. Maak de machine wakker en schakel de Bluetooth-verbinding in.';

  @override
  String get indoorControlPrompt =>
      'Mag Fjelia de doelen voor deze training wijzigen? Blijf in de buurt van de bediening van de machine. Je kunt altijd overschakelen naar handmatige bediening.';

  @override
  String get indoorTreadmillSafety =>
      'Bevestig de veiligheidssleutel en blijf bij de bediening. Bevestig alleen kleine wijzigingen, tot 0,5 km/u of 1% helling. Gebruik voor grotere wijzigingen de bediening van de machine.';

  @override
  String get recordingTime => 'Opnametijd';

  @override
  String get recordingSpeed => 'Snelheid';

  @override
  String get recordingPower => 'Vermogen';

  @override
  String get recordingCadence => 'Cadans / slagfrequentie';

  @override
  String get recordingIncline => 'Helling';

  @override
  String get recordingResistance => 'Weerstand';

  @override
  String get recordingSource => 'Bron';

  @override
  String get recordingNext => 'Volgende stap';

  @override
  String get recordingConnecting => 'Verbinden';

  @override
  String get recordingReconnecting => 'Opnieuw verbinden';

  @override
  String get recordingInterrupted => 'Onderbroken';

  @override
  String get recordingPaused => 'Gepauzeerd';

  @override
  String get indoorMatrixReadOnly =>
      'Alleen opname van de Matrix-loopband. Gebruik de console voor snelheid en helling; bediening op afstand is voor dit model niet getest.';

  @override
  String ecgCoverage(String value) {
    return '$value% dekking van meetpunten';
  }

  @override
  String get recordingBeforeRestore =>
      'Rond de apparaatopname af voordat je een back-up herstelt.';

  @override
  String get gymTitle => 'Loopbanden in de sportschool';

  @override
  String get gymDescription =>
      'Neem op met je telefoon, importeer xID-trainingen of scan de samenvatting op de console.';

  @override
  String get gymDirectConnection => 'Directe verbinding';

  @override
  String get gymConsoleSupport =>
      'De verbindingsopties hangen af van de console. Een oudere Matrix-console ondersteunt mogelijk xID in plaats van live Bluetooth-gegevens.';

  @override
  String get gymFindEquipment => 'Sportschoolapparaat zoeken';

  @override
  String get gymLiveAvailable =>
      'Deze console kan trainingsgegevens rechtstreeks naar Fjelia sturen.';

  @override
  String get gymLiveUnavailable =>
      'Geen ondersteunde live trainingsgegevens gevonden. Importeer xID-trainingen of sla een consolesamenvatting op.';

  @override
  String get gymSpeedOnly =>
      'Snelheid en cadans zijn beschikbaar. Deze verbinding levert geen helling of bediening op afstand.';

  @override
  String get gymUseMachine => 'Dit apparaat gebruiken';

  @override
  String get gymConnectionReport => 'Verbindingsrapport';

  @override
  String get gymShareReport => 'Verbindingsrapport delen';

  @override
  String get gymXid => 'Matrix xID';

  @override
  String get gymXidDescription =>
      'Importeer loopbandtrainingen die het xID-netwerk van je sportschool heeft opgeslagen.';

  @override
  String get gymPortal => 'Netpulse-portal van de sportschool';

  @override
  String get gymPortalHelp =>
      'Voer het adres van het Netpulse-portal in dat je sportschool heeft gegeven.';

  @override
  String get gymPasscode => 'xID-toegangscode';

  @override
  String get gymSessionHelp =>
      'Je sessie wordt veilig opgeslagen. Je toegangscode wordt niet bewaard.';

  @override
  String get gymAutoSync => 'xID-trainingen automatisch synchroniseren';

  @override
  String gymLastDays(int days) {
    return 'Laatste $days dagen';
  }

  @override
  String get gymLoadWorkouts => 'Trainingen laden';

  @override
  String get gymNoWorkouts =>
      'Geen loopbandtrainingen gevonden voor deze periode.';

  @override
  String gymSkipped(int count) {
    return '$count onleesbare trainingen overgeslagen.';
  }

  @override
  String gymImported(int count, int duplicates) {
    return '$count trainingen geïmporteerd; $duplicates dubbele overgeslagen.';
  }

  @override
  String get gymSummary => 'Loopbandsamenvatting';

  @override
  String get gymSummaryDescription =>
      'Maak een foto van het eindscherm van de console en controleer de waarden voordat je opslaat.';

  @override
  String get gymTakePhoto => 'Foto maken';

  @override
  String get gymChoosePhoto => 'Foto kiezen';

  @override
  String get gymReview =>
      'Controleer de eenheden, de starttijd en de waarden. Foto\'s worden op je telefoon gelezen. Alleen de trainingssamenvatting wordt opgeslagen.';

  @override
  String get gymStartTime => 'Start van de training';

  @override
  String get gymDurationHelp =>
      'Voer mm:ss of uu:mm:ss in, bijvoorbeeld 30:00.';

  @override
  String get gymDistanceUnit => 'Afstandseenheid';

  @override
  String get gymCalories => 'Calorieën';

  @override
  String get manualRecordTitle => 'Activiteit opnemen';

  @override
  String get manualRecordDescription =>
      'Neem een activiteit op met optioneel gps, ECG en hartslag. De opname loopt door als je van app wisselt of het scherm vergrendelt, tot je op Pauze of Stop drukt.';

  @override
  String get manualTreadmill => 'Loopbandtraining';

  @override
  String get manualChooseH10 => 'Polar H10 kiezen';

  @override
  String get manualRecordEcg => 'ECG opnemen met Polar H10';

  @override
  String get manualChooseHelp =>
      'Kies een Polar H10 om ECG en hartslag op te nemen.';

  @override
  String manualEcgSegments(int count) {
    return 'Gekoppelde ECG-segmenten: $count';
  }

  @override
  String get manualEcgInterrupted =>
      'ECG gestopt. De activiteitstimer loopt nog.';

  @override
  String get manualRestartEcg => 'ECG-opname opnieuw starten';

  @override
  String get manualFinalDistance => 'Eindafstand (optioneel)';

  @override
  String get manualDiscardNote =>
      'Deze activiteit verwerpen? ECG-opnamen blijven in de ECG-geschiedenis.';

  @override
  String get manualRecordHeartRate => 'Hartslag opnemen';

  @override
  String get manualChooseHr => 'Kies een hartslagsensor';

  @override
  String get manualHrWithEcg => 'Gebruikt dezelfde H10-verbinding als de ECG.';

  @override
  String get manualRecordGps => 'Gps-route en afstand opnemen';

  @override
  String get manualGpsHelp =>
      'Voor buitenactiviteiten. Sta precieze locatie toe om je route met het scherm uit op te nemen.';

  @override
  String get manualGpsWaiting => 'Wachten op een nauwkeurige gps-positie';

  @override
  String manualGpsAccuracy(int meters) {
    return 'Gps-nauwkeurigheid: $meters m';
  }

  @override
  String get manualRecordBp => 'Bloeddrukmetingen meenemen';

  @override
  String get manualBpHelp =>
      'Toont metingen van Hilo, Aktiia en Gezondheid tijdens deze opname, ook na latere synchronisaties.';

  @override
  String get manualBpUnavailable =>
      'Bloeddrukmetingen konden niet worden geladen.';

  @override
  String get manualBpEmpty => 'Geen bloeddrukmetingen tijdens deze opname.';

  @override
  String get manualHrDisconnected => 'Hartslagsensor losgekoppeld.';

  @override
  String get manualReconnectHr => 'Hartslagsensor opnieuw koppelen';

  @override
  String get manualBackgroundNotification =>
      'De opname loopt door met het scherm uit';

  @override
  String get ecgAskCoach => 'Bespreken met de AI-coach';

  @override
  String get ecgCoachWarningTitle => 'Geen medisch advies';

  @override
  String get ecgCoachWarningBody =>
      'De AI-coach is geen arts en kan geen diagnose stellen. Een ECG met borstband heeft maar één afleiding: het kan een hartaanval of een andere hartziekte niet uitsluiten, en de analyse kan fout zijn.\n\nPijn of druk op de borst, kortademigheid, pijn in arm, kaak of rug, koud zweet of flauwvallen: bel nu 112. Wacht niet op een antwoord van de AI.\n\nDe geanalyseerde waarden en 10 seconden van het ruwe signaal gaan naar het AI-model dat in de AI-instellingen is gekozen.';

  @override
  String get ecgCoachUnderstood => 'Ik begrijp het';

  @override
  String get ecgCoachBanner =>
      'Geen medisch advies. De AI is geen arts en kan een hartaanval niet uitsluiten. Noodgeval: bel 112.';

  @override
  String get ecgCoachCardTitle => 'ECG-voorlopige analyse';

  @override
  String get statusMeasured => 'Gemeten';

  @override
  String get ecgQuestionOverview => 'Wat laat mijn ECG zien?';

  @override
  String get ecgQuestionRhythm => 'Is mijn hartritme regelmatig?';

  @override
  String get ecgQuestionDoctor => 'Moet een arts hiernaar kijken?';

  @override
  String get ecgFollowSymptoms => 'Bij welke klachten moet ik naar een arts?';

  @override
  String get ecgFollowRiskFactors => 'Hoe veranderen mijn risicofactoren dit?';

  @override
  String get ecgFollowTraining => 'Kan ik normaal trainen?';

  @override
  String get ecgFollowBetterRecording => 'Hoe neem ik een betere ECG op?';

  @override
  String get manualTreadmillConnect =>
      'Loopband koppelen (Bluetooth, optioneel)';

  @override
  String get manualTreadmillHelp =>
      'Snelheid, afstand en helling komen dan van de loopband. Zonder verbinding voer je aan het eind de afstand in.';

  @override
  String get sportIndoorCycling => 'Indoor fietsen';

  @override
  String get sportElliptical => 'Crosstrainer';

  @override
  String get sportStairClimber => 'Traploper';

  @override
  String get manualWrongMachine =>
      'Dit apparaat past niet bij de gekozen sport.';

  @override
  String get manualEquipmentHelp =>
      'Koppel een Bluetooth-apparaat (FTMS). Snelheid, vermogen, cadans en afstand komen van de machine.';

  @override
  String get plusTitle => 'Vastleggen';

  @override
  String get plusStartWorkout => 'Training starten';

  @override
  String get plusStartWorkoutHint =>
      'Live met gps, loopband of indoorfiets · ECG & hartslag';

  @override
  String get plusGroupTraining => 'Training';

  @override
  String get plusGroupHeart => 'Hart & bloedsomloop';

  @override
  String get plusGroupBody => 'Lichaam';

  @override
  String get plusGroupRecovery => 'Herstel';

  @override
  String get plusLogWorkout => 'Training vastleggen';

  @override
  String get plusLogWorkoutHint => 'Voeg een eerdere training handmatig toe';

  @override
  String get plusImport => 'Importeren';

  @override
  String get plusImportHint => 'Strava, FIT, GPX, loopband in de sportschool';

  @override
  String get plusEcg => 'ECG opnemen';

  @override
  String get plusEcgHint => 'Polar H10 of ECG-bestand';

  @override
  String get plusHrv => 'HRV-check';

  @override
  String get plusHrvHint => 'Korte meting met Polar H10';

  @override
  String get plusBpMeasure => 'Meet met de Hilo-manchet';

  @override
  String get plusBpMeasureHint =>
      'Koppel de Hilo-bloeddrukmanchet via Bluetooth';

  @override
  String get plusBpLog => 'Bloeddruk noteren';

  @override
  String get plusBpLogHint => 'Voer een meting in';

  @override
  String get plusBpReport => 'Hilo-rapport';

  @override
  String get plusBpReportHint => 'Importeer de pdf';

  @override
  String get plusSpo2 => 'SpO₂ & pols';

  @override
  String get plusSpo2Hint => 'Van een pulsoximeter';

  @override
  String get plusWeigh => 'Wegen';

  @override
  String get plusWeighHint => 'RENPHO-weegschaal via Bluetooth';

  @override
  String get plusWeightLog => 'Gewicht noteren';

  @override
  String get plusWeightLogHint => 'Gewicht, lichaamsvet, BMI';

  @override
  String get plusWaist => 'Taille';

  @override
  String get plusWaistHint => 'Omtrek & verhoudingen';

  @override
  String get plusGrip => 'Knijpkracht';

  @override
  String get plusGripHint => 'Meting met dynamometer';

  @override
  String get plusSleep => 'Slaap noteren';

  @override
  String get plusSleepHint => 'Duur, diepe slaap en REM';

  @override
  String get recPace => 'Tempo (/km)';

  @override
  String get recAvgPace => 'Gem. tempo';

  @override
  String get recPace500 => 'Tempo (/500 m)';

  @override
  String get recSpeedKmh => 'Snelheid (km/u)';

  @override
  String get recPowerW => 'Vermogen (W)';

  @override
  String get recDistanceKm => 'Afstand (km)';

  @override
  String get recHeartRate => 'Hartslag';

  @override
  String get recMap => 'Kaart';

  @override
  String get recStart => 'Start';

  @override
  String get recResume => 'Hervatten';

  @override
  String get recFinish => 'Afronden';

  @override
  String get recDiscard => 'Verwerpen';

  @override
  String get recLive => 'Opname';

  @override
  String get recNew => 'Nieuwe activiteit';

  @override
  String get recCadence => 'Cadans';

  @override
  String get recMachine => 'Apparaat';

  @override
  String get recGps => 'Gps';

  @override
  String get recEcg => 'ECG';

  @override
  String get recBloodPressure => 'Bloeddruk';

  @override
  String get recBannerOpen => 'Tik om te openen';

  @override
  String get bpActivityHint =>
      'Manchetten kunnen vaak niet meten terwijl je beweegt. Metingen van voor of na de activiteit worden hier niet getoond.';

  @override
  String objectiveKeyLong(String sport, String goal) {
    return 'Belangrijke lange $sport voor $goal';
  }

  @override
  String seasonKeyRides(int n) {
    return 'In $n weken groeit een belangrijke lange training richting de helft van het evenement, één keer per blok en nooit naast een ander evenement.';
  }

  @override
  String seasonEventAsLong(int n) {
    return 'In $n weken is een ander evenement de lange training voor een groter doel.';
  }

  @override
  String objectiveThreshold(String sport, String goal) {
    return 'Drempel $sport voor $goal';
  }

  @override
  String objectiveHills(String sport, String goal) {
    return 'Heuvel $sport voor $goal';
  }

  @override
  String objectiveOpeners(String goal) {
    return 'Openers voor $goal';
  }

  @override
  String get planAdjustedTitle => 'Plan automatisch aangepast';

  @override
  String planAdjSwap(String session, String day, String from) {
    return '$session: gedaan op $day in plaats van $from.';
  }

  @override
  String planAdjSubstitute(String activity, String session, String from) {
    return '$activity telt als $session van $from.';
  }

  @override
  String planAdjStrengthCredit(String activity, String session) {
    return '$activity dekt de beenkracht van $session.';
  }

  @override
  String planAdjMoved(String session, String day) {
    return '$session verschuift naar $day, dat vrij is gekomen.';
  }

  @override
  String planAdjMovedEasy(String session, String day, String activity) {
    return '$session verschuift naar $day, lichter: je benen herstellen van $activity.';
  }

  @override
  String get planAdjUndone => 'Wijziging ongedaan gemaakt.';

  @override
  String get shortSessionTitle => 'Korter dan gepland – waarom?';

  @override
  String shortSessionLine(String session, int done, int planned) {
    return '$session: $done van $planned min';
  }

  @override
  String get shortReasonTime => 'Geen tijd';

  @override
  String get shortReasonWeather => 'Weer';

  @override
  String get shortReasonFatigue => 'Moe';

  @override
  String get shortReasonPain => 'Pijn';

  @override
  String get shortReasonOther => 'Anders';

  @override
  String get styleTitle => 'Stijl';

  @override
  String get styleAuto => 'Automatisch';

  @override
  String get styleAutoHint =>
      'Volgt je telefoon: LightFjelia overdag, DarkFjelia \'s nachts.';

  @override
  String get connectMyWhoosh => 'MyWhoosh koppelen';

  @override
  String get myWhooshSubtitle =>
      'Log in met je MyWhoosh-account om je indoorritten met vermogen, cadans en hartslag binnen te halen.';

  @override
  String get myWhooshCredentialsInfo =>
      'MyWhoosh-inloggegevens worden versleuteld op je apparaat opgeslagen. Fjelia leest je ritten rechtstreeks uit MyWhoosh, via de interface van de MyWhoosh-app. Fjelia is niet verbonden aan MyWhoosh.';

  @override
  String get myWhooshTile => 'Indoorritten';

  @override
  String get myWhooshSignedInElsewhere =>
      'MyWhoosh staat één sessie per account toe en je bent op een ander apparaat ingelogd. Sluit MyWhoosh daar (log zo nodig uit) en probeer het opnieuw.';

  @override
  String get shareWorkout => 'Training delen';

  @override
  String get shareFitFile => 'Delen als FIT-bestand';

  @override
  String get shareFitFileHint =>
      'Voor Strava, COROS, TrainingPeaks en andere apps';

  @override
  String get sendToGarmin => 'Naar Garmin Connect sturen';

  @override
  String get sendToGarminHint => 'Uploadt de training naar je Garmin-account';

  @override
  String get sentToGarmin => 'Verstuurd naar Garmin Connect';

  @override
  String get alreadyOnGarmin => 'Deze training staat al in Garmin Connect';

  @override
  String get missedWorkoutPastTitle => 'Gemiste training';

  @override
  String get leaveIt => 'Laat maar';

  @override
  String get reviewChange => 'Bekijken';

  @override
  String get keepPlan => 'Plan houden';

  @override
  String get missedYesterdayTitle => 'Gisteren gemist';

  @override
  String get proposalReplanTitle => 'Je plan opnieuw opbouwen?';

  @override
  String get proposalRestTitle => 'Vandaag een rustdag?';

  @override
  String get proposalRecoveryTitle => 'Vandaag alleen rustig?';

  @override
  String get proposalEasierTitle => 'Vandaag iets lichter?';

  @override
  String get proposalReplanBody =>
      'Belasting of HRV wijzen op een herzien plan.';

  @override
  String get proposalCardTitle => 'Voorstel voor vandaag';

  @override
  String get replanMissed => 'Opnieuw plannen';

  @override
  String get askBeforePlanChanges => 'Vragen voor wijzigingen in het plan';

  @override
  String get askBeforePlanChangesHint =>
      'Readiness en trends stellen wijzigingen voor, jij beslist. Uit: Fjelia past het plan zelf aan.';

  @override
  String missedOnDayTitle(String day) {
    return 'Gemist op $day';
  }

  @override
  String missedPastBody(String names) {
    return '$names. Verplaatsen of overslaan?';
  }

  @override
  String proposalDropsLine(String title) {
    return '$title vervalt';
  }

  @override
  String proposalChangeLine(String from, String to) {
    return '$from → $to';
  }

  @override
  String get proposalAnswered =>
      'Al beantwoord, er valt niets meer te beslissen.';

  @override
  String get ecgTrainingWarningTitle => 'Alleen voor training';

  @override
  String get ecgTrainingWarningBody =>
      'Fjelia leest ECG\'s niet medisch. De coach legt hartslag, HRV en signaalkwaliteit alleen uit voor je training. Hij zegt niets over hartaandoeningen of ritmestoornissen: exporteer daarvoor de opname en laat haar aan een arts zien.\n\nPijn of druk op de borst, kortademigheid, pijn in arm, kaak of rug, koud zweet of flauwvallen: bel nu 112.\n\nHartslag, HRV en signaalkwaliteit gaan naar het AI-model dat in de AI-instellingen is gekozen.';

  @override
  String get ecgQuestionTraining => 'Wat zegt mijn ECG over mijn training?';

  @override
  String get ecgFollowHrv => 'Wat zegt de HRV over mijn herstel?';

  @override
  String get ecgFollowHeartRate => 'Hoe ontwikkelde mijn hartslag zich?';

  @override
  String get bioLeanMuchYounger => 'Veel jonger op de weg';

  @override
  String get bioLeanYounger => 'Jonger op de weg';

  @override
  String get bioLeanEven => 'Precies op koers';

  @override
  String get bioLeanOlder => 'Wat ruimte om te groeien';

  @override
  String get bioLeanMuchOlder => 'Veel ruimte om te groeien';

  @override
  String get fitnessSameAsAge => 'Zo fit als je leeftijd';

  @override
  String get lifespanBandTitle => 'Je levensduur';

  @override
  String get lifespanBandNote =>
      'Een bandbreedte uit statistieken voor mensen met vergelijkbare waarden, geen voorspelling voor jou.';

  @override
  String get factorHelps => 'Helpt je';

  @override
  String get factorSlows => 'Houdt je tegen';

  @override
  String get bioFactorBloodPressure => 'Bloeddruk';

  @override
  String get bioFactorVisceralFat => 'Visceraal vet';

  @override
  String get bioFactorLipids => 'Bloedvetten';

  @override
  String get bioFactorInflammation => 'Ontsteking (CRP)';

  @override
  String get bioFactorKidney => 'Nierfunctie';

  @override
  String get bioAgeModelNote =>
      'De fitnessleeftijd vergelijkt je VO₂max met leeftijdsnormen. De levensduur komt uit een model op basis van studiewaarden: geen medische uitspraak en geen persoonlijke voorspelling.';

  @override
  String fitnessYoungerBy(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years jaar jonger dan je leeftijd',
      one: '$years jaar jonger dan je leeftijd',
    );
    return '$_temp0';
  }

  @override
  String fitnessOlderBy(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years jaar boven je leeftijd',
      one: '$years jaar boven je leeftijd',
    );
    return '$_temp0';
  }

  @override
  String lifespanBandYears(int low, int high) {
    return '$low–$high';
  }

  @override
  String todayAge(int age) {
    return 'Vandaag $age';
  }

  @override
  String get vo2ClassBelowAvg => 'onder gemiddeld';

  @override
  String get vo2ClassAverage => 'gemiddeld';

  @override
  String get vo2ClassAboveAvg => 'boven gemiddeld';

  @override
  String get vo2ClassGood => 'goed';

  @override
  String get vo2ClassExcellent => 'uitstekend';

  @override
  String get vo2ClassElite => 'elite';

  @override
  String get fjeliaProHint =>
      'FjeliaPro geeft je meer gedetailleerde informatie en analyses.';

  @override
  String get rowingStrokeRate => 'Slagen / min';

  @override
  String rowingStrokeAverage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ø $count slagen',
      one: 'Ø 1 slag',
    );
    return '$_temp0';
  }

  @override
  String get rowingTapToSwitch => 'Tik om te wisselen';

  @override
  String get copyAnswer => 'Antwoord kopiëren';

  @override
  String get answerCopied => 'Gekopieerd ✨';

  @override
  String get coachMemories => 'Memory Cards';

  @override
  String get coachMemoriesIntro =>
      'Vertel je coach wat hij altijd moet weten. Je kaarten gaan bij elke chat mee.';

  @override
  String get coachMemoryNew => 'Nieuwe kaart';

  @override
  String get coachMemoryTitle => 'Titel';

  @override
  String get coachMemoryTitleHint => 'bijv. Linkerknie';

  @override
  String get coachMemoryBody => 'Wat moet je coach weten?';

  @override
  String get coachMemoryBodyHint =>
      'bijv. Bergaf lopen doet sinds het voorjaar pijn. Klimmen gaat prima.';

  @override
  String get coachMemoryEmpty => 'Nog geen kaarten. Maak je eerste 🔥';

  @override
  String get coachMemoryDeleteQuestion => 'Deze kaart verwijderen?';

  @override
  String coachMemoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaarten in het hoofd van je coach',
      one: '1 kaart in het hoofd van je coach',
      zero: 'Geen kaarten',
    );
    return '$_temp0';
  }

  @override
  String get sportSkiErg => 'SkiErg (langlauf indoor)';

  @override
  String get weatherRain => 'REGEN';

  @override
  String weatherLowHigh(int low, int high) {
    return 'Min. $low° · Max. $high°';
  }

  @override
  String get weatherDayPeak => 'Hoogtepunt van de dag';

  @override
  String get weatherDayTotal => 'Totaal voor de dag';

  @override
  String get proTagline => 'Je coach. Op pro-niveau.';

  @override
  String get proBenefitCoach =>
      'AI-coach met het Pro-model: sneller, grondiger, met een eigen budget';

  @override
  String get proBenefitMemory => 'Memory Cards: wat je coach altijd moet weten';

  @override
  String get proBenefitEcg => 'Gedetailleerde ECG-analyse';

  @override
  String get proBenefitCopy => 'Antwoorden kopiëren met één tik';

  @override
  String get proMonthly => 'Maandelijks';

  @override
  String get proYearly => 'Jaarlijks';

  @override
  String proPerMonth(String price) {
    return '$price / maand';
  }

  @override
  String proPerYear(String price) {
    return '$price / jaar';
  }

  @override
  String get proBestValue => 'VOORDELIGST';

  @override
  String get proSubscribe => 'FjeliaPro nemen';

  @override
  String get proRestore => 'Aankopen herstellen';

  @override
  String get proManage => 'Abonnement beheren';

  @override
  String proActiveUntil(String date) {
    return 'Pro is actief tot $date';
  }

  @override
  String get proAutoRenew =>
      'Het abonnement wordt automatisch verlengd, tenzij je het minstens 24 uur voor het einde van de periode opzegt in de instellingen van je Apple-account. De betaling wordt via je Apple-account afgerekend.';

  @override
  String get proTerms => 'Gebruiksvoorwaarden';

  @override
  String get proPrivacy => 'Privacy';

  @override
  String get proProblemStore => 'De App Store heeft de aankoop niet afgerond.';

  @override
  String get proProblemService =>
      'Je aankoop is er, maar kon nog niet worden gecontroleerd. Fjelia probeert het opnieuw bij de volgende start.';

  @override
  String get proProblemNothing => 'Geen FjeliaPro-abonnement om te herstellen.';

  @override
  String get proProblemNotActive => 'Dit abonnement is beëindigd.';

  @override
  String get proUnavailable =>
      'De abonnementen kunnen nu niet worden geladen. Probeer het later opnieuw.';

  @override
  String get proWelcome => 'Welkom bij FjeliaPro 🔥';

  @override
  String get proUsesFjeliaAi =>
      'Het Pro-model antwoordt als in de AI-instellingen „Fjelia AI” is gekozen.';

  @override
  String get proToolsTitle => 'Pro-analyses';

  @override
  String get proPlanCheck => 'Plancheck van vandaag';

  @override
  String get proPlanCheckHint => 'Past het plan van vandaag bij je herstel?';

  @override
  String get proWeekReview => 'Weekoverzicht';

  @override
  String get proWeekReviewHint => 'Wat werkte, wat volgende week anders moet';

  @override
  String get proRacePlan => 'Wedstrijdplan';

  @override
  String proRacePlanHint(String race) {
    return '$race: afbouw, tempoplan, voeding';
  }

  @override
  String get proSeason => 'Seizoensanalyse';

  @override
  String get proSeasonHint => 'Doelen, fasen en risico\'s van je seizoen';

  @override
  String get proAnalysisCreate => 'Analyse maken';

  @override
  String get proAnalysisRedo => 'Opnieuw maken';

  @override
  String proAnalysisFrom(String time) {
    return 'Gemaakt $time';
  }

  @override
  String get proAnalysisWorking => 'Het grote model analyseert…';

  @override
  String get proAnalysisFailed => 'De analyse is mislukt. Probeer het opnieuw.';

  @override
  String get proBenefitPlanCheck =>
      'Ochtendvoorstel en plancheck: de coach herwerkt de training van de dag';

  @override
  String get proBenefitReview => 'Weekoverzicht en seizoensanalyse';

  @override
  String get proBenefitRacePlan => 'Wedstrijdplan: afbouw, tempoplan, voeding';

  @override
  String get statsTitle => 'Statistieken';

  @override
  String get statsLast4Weeks => 'Laatste 4 weken · per week';

  @override
  String get statsElevation => 'Hoogtemeters';

  @override
  String get statsAllTimeTotals => 'Alle tijden';

  @override
  String get statsBestEfforts => 'Beste prestaties';

  @override
  String get statsLongest => 'Langste';

  @override
  String get statsMostElevation => 'Meeste hoogtemeters';

  @override
  String get statsNone => 'Nog geen activiteiten.';

  @override
  String get proBenefitStats =>
      'Statistieken: beste prestaties, dit jaar en de laatste 4 weken';

  @override
  String get statsFourWeeks => '4 weken';

  @override
  String get statsTickerWeek => 'per week, laatste 4 weken';

  @override
  String statsTickerYear(String year) {
    return 'in $year';
  }

  @override
  String statsTickerBest(String distance) {
    return 'Beste $distance';
  }

  @override
  String get statsPerWeekShort => '/ week';

  @override
  String get gripLeft => 'Links';

  @override
  String get gripRight => 'Rechts';

  @override
  String get muscleShort => 'Spier';

  @override
  String vsYesterday(String arrow) {
    return '$arrow t.o.v. gisteren';
  }

  @override
  String get proposalProCoach => 'De coach schrijft de ochtendmelding';

  @override
  String get proposalProCoachHint =>
      'FjeliaPro: de readiness, het plan en de gezondheidscontext van vandaag gaan naar Fjelia AI Pro, dat het voorstel kort na de ochtendsynchronisatie formuleert.';

  @override
  String get heatShort => 'Hitte';

  @override
  String get coachRevisionLabel => 'Voorstel van de coach';

  @override
  String get revisionBefore => 'Voor';

  @override
  String get revisionAfter => 'Na';

  @override
  String get revisionSwapped => 'Gewisseld';

  @override
  String get revisionRestDay => 'In plaats daarvan rustdag';

  @override
  String get revisionDropped => 'weggelaten';

  @override
  String get revisionAccept => 'Overnemen';

  @override
  String revisionSets(String sets, String reps) {
    return '$sets × $reps';
  }

  @override
  String get testMorningProposal => 'Ochtendvoorstel testen';

  @override
  String get testMorningProposalHint =>
      'Voert de ochtendcheck nu uit met readiness op geel; de melding komt na 5 seconden.';

  @override
  String get proposalRulesEasier =>
      'Het herstel is nog niet helemaal daar: de trainingen van vandaag worden korter en lichter, het doel blijft.';

  @override
  String get proposalRulesRecovery =>
      'Duidelijke tekenen van vermoeidheid: vandaag alleen rustig, of rust.';

  @override
  String get proposalCoachUnavailable =>
      'De coach was nu niet bereikbaar; dit is het voorstel volgens de regels.';

  @override
  String get revisionKeep => 'Blijft zoals gepland';

  @override
  String get revisionAlternative => 'Alternatief';

  @override
  String get revisionTakeAlternative => 'Dit in plaats daarvan nemen';

  @override
  String proposalForDay(String day) {
    return 'Voorstel voor $day';
  }

  @override
  String get proposalDayTomorrow => 'morgen';

  @override
  String get feelingQuestion => 'Hoe voel je je vandaag?';

  @override
  String get feelingGood => 'Goed';

  @override
  String get feelingTired => 'Moe';

  @override
  String get feelingSore => 'Spierpijn';

  @override
  String get feelingIll => 'Ziek';

  @override
  String get feelingShort => 'Weinig tijd';

  @override
  String get feelingAsking => 'De coach denkt opnieuw na…';

  @override
  String get proSwitchTitle => 'ProAI gebruiken?';

  @override
  String proSwitchBody(String provider) {
    return 'Je FjeliaPro-abonnement is actief. Moet de coach vanaf nu ProAI gebruiken in plaats van $provider?';
  }

  @override
  String get proAiRouting =>
      'FjeliaPro gebruikt een krachtigere AI voor wedstrijd- en seizoensplannen. Je coach en de dagelijkse trainingsvoorstellen gebruiken het gewone Pro-model.';

  @override
  String proActiveUntilShort(String date) {
    return 'Actief tot $date';
  }

  @override
  String shortSessionNote(int done, int planned) {
    return 'Korter dan gepland ($done van $planned min)';
  }

  @override
  String get noteForCoach => 'Notitie voor de coach (optioneel)';

  @override
  String get activityNote => 'Notitie';

  @override
  String get activityNoteAdd => 'Voeg een notitie voor de coach toe';

  @override
  String get plusOmronBle => 'BLE-bloeddrukmeters zoeken';

  @override
  String get plusOmronBleHint =>
      'Zoek naar standaard Bluetooth-bloeddrukmeters en ondersteunde Omron-profielen.';

  @override
  String get sleepEcgTitle => 'Slaap opnemen';

  @override
  String get sleepEcgHint => 'ECG en beweging met Polar H10';

  @override
  String get sleepEcgDescription =>
      'Neemt tegelijkertijd ECG op met 130 Hz en beweging over drie assen met 25 Hz. Draag de Polar H10 en houd je iPhone binnen Bluetooth-bereik. Een schatting van slaapfasen is optioneel en wordt apart uitgevoerd; ademhalingsfrequentie en medische bevindingen worden niet berekend.';

  @override
  String get sleepEcgStart => 'Nachtopname starten';

  @override
  String sleepEcgMotionSamples(int count) {
    return 'Bewegingsmetingen: $count';
  }

  @override
  String get sleepEcgKeepOpenHint =>
      'Je kunt dit scherm verlaten terwijl de opname doorloopt. Houd Fjelia open in de appkiezer en je iPhone in de buurt van de H10. Als je de app geforceerd sluit, wordt de opname onderbroken.';

  @override
  String get sleepEcgRawNote =>
      'Ruwe gegevens van de nachtelijke ECG- en bewegingsopname. Je kunt apart een experimentele schatting van slaapfasen starten. Ademhalingsfrequentie en medische bevindingen worden niet berekend.';

  @override
  String get sleepEcgExportRaw => 'Ruwe ECG- en bewegings-CSV\'s exporteren';

  @override
  String get sleepEcgStagesTitle => 'Geschatte slaapfasen';

  @override
  String get sleepEcgStagesButton => 'Slaapfasen schatten';

  @override
  String get sleepEcgStagesAgain => 'Opnieuw schatten';

  @override
  String get sleepEcgStagesDisclaimer =>
      'Experimentele schatting op basis van Polar H10-ECG met een onderzoeksmodel dat alleen ECG gebruikt. N1 en N2 worden samengevoegd tot lichte slaap. Dit is geen PSG- of medische meting.';

  @override
  String get sleepEcgStagesWorking => 'Slaapfasen schatten…';

  @override
  String get sleepEcgStagesFailed =>
      'Slaapfasen konden niet worden geschat. Controleer of de opname compleet is en probeer het opnieuw.';

  @override
  String get replacementPreviewTitle => 'Vervangende training controleren';

  @override
  String replacementGoalLoad(String objective, int load) {
    return 'Doel: $objective · geplande belasting $load';
  }

  @override
  String get replacementHistoryEstimate =>
      'Duur geschat op basis van je recente training in deze sport.';

  @override
  String get replacementFallbackEstimate =>
      'Er zijn niet genoeg recente trainingsgegevens voor deze sport. De duur is een voorzichtige schatting.';

  @override
  String get replacementRestSuggestion =>
      'Rust kan de betere keuze zijn voor je huidige trainingsschema.';

  @override
  String get replacementObjectiveRecovery => 'Herstel';

  @override
  String get replacementObjectiveBase => 'Basisuithoudingsvermogen';

  @override
  String get replacementObjectiveTempo => 'Tempo';

  @override
  String get replacementObjectiveThreshold => 'Drempel';

  @override
  String get replacementObjectiveVo2 => 'VO₂max';

  @override
  String get replacementObjectiveLong => 'Lange duur';

  @override
  String get replacementWarningNoHistory =>
      'Er is niet genoeg recente belastingsgeschiedenis voor deze sport.';

  @override
  String get replacementWarningRunningCap =>
      'De loopomvang is voorzichtig beperkt om de mechanische belasting te beperken.';

  @override
  String get replacementWarningLong =>
      'Lange of wedstrijdspecifieke trainingen zijn niet volledig te vervangen. Controleer de kortere loop.';

  @override
  String get replacementWarningRace =>
      'Deze training heeft wedstrijdprioriteit; het sportspecifieke effect blijft mogelijk niet behouden.';

  @override
  String get replacementWarningSwim =>
      'Een deel van de aerobe prikkel blijft behouden, maar niet de zwemtechniek of de sportspecifieke spierbelasting.';

  @override
  String get replacementWarningStrength =>
      'Kracht- en duurtrainingen zijn niet gelijkwaardig en kunnen niet hetzelfde trainingseffect behouden.';

  @override
  String get replacementWarningNearby =>
      'Binnen 72 uur valt nog een zware training. Controleer herstel en spreiding.';

  @override
  String get replacementWarningWeekly =>
      'Deze training is een groot deel van de overige geplande trainingsbelasting deze week.';

  @override
  String get replacementWarningLowRecovery =>
      'Je laatst opgeslagen herstelscore is laag. Overweeg de intensiteit te verlagen of te rusten.';

  @override
  String get replacementWarningRecentVolume =>
      'Je trainingsbelasting van de afgelopen zeven dagen is duidelijk hoger dan in de zeven dagen daarvoor.';

  @override
  String get replacementTrainingGoal => 'TRAININGSDOEL';

  @override
  String get replacementPreviewWarnings => 'OPMERKINGEN BIJ HET PLAN';
}
