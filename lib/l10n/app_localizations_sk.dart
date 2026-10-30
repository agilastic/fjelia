// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get freeAi => 'Free AI';

  @override
  String get freeAiUsageTracking =>
      'Aby bola služba Free AI spoľahlivo dostupná pre všetkých, odosielame náhodný identifikátor inštalácie. Pomáha nám rozpoznať neobvyklé používanie a blokovať požiadavky zneužívajúce službu. Identifikátor neobsahuje vaše meno ani údaje o účte.';

  @override
  String freeAiDescription(String host) {
    return 'Bezplatný AI chat a súhrny cez $host. Nepotrebujete vlastný účet ani API kľúč. Po vašom potvrdení sa správy a súhrn zdravotných a tréningových údajov odošlú tejto službe.';
  }

  @override
  String get freeAiUnavailable =>
      'Free AI nie je v tejto verzii dostupná. Vyberte iného poskytovateľa.';

  @override
  String shareBriefingContextWithName(String name) {
    return 'Súhrn vašich zdravotných a tréningových údajov sa odošle poskytovateľovi $name.';
  }

  @override
  String get language => 'Jazyk';

  @override
  String get languageSystem => 'Predvolené systémom';

  @override
  String get settings => 'Nastavenia';

  @override
  String get profile => 'Profil';

  @override
  String get training => 'Tréning';

  @override
  String get weatherLocation => 'Počasie a poloha';

  @override
  String get display => 'Zobrazenie';

  @override
  String get connections => 'Pripojenia';

  @override
  String get aiAndMore => 'AI a ďalšie';

  @override
  String get system => 'Systém';

  @override
  String get runSetupAgain => 'Spustiť nastavenie znova';

  @override
  String get runSetupAgainSubtitle => 'Účty, cieľ pretekov a tréningový plán';

  @override
  String get back => 'Späť';

  @override
  String get close => 'Zavrieť';

  @override
  String get dataExport => 'Export údajov';

  @override
  String get dataExportSubtitle => 'Export CSV, zálohovanie a obnova';

  @override
  String get developer => 'Vývojár';

  @override
  String get developerSubtitle => 'Režim ladenia, diagnostika';

  @override
  String get debug => 'Ladenie';

  @override
  String get debugMode => 'Režim ladenia';

  @override
  String get debugModeSubtitle => 'Zobrazí kartu DEBUG';

  @override
  String get support => 'Podpora';

  @override
  String get reportBug => 'Nahlásiť chybu';

  @override
  String get aiCoach => 'AI tréner';

  @override
  String get enableAiCoach => 'Zapnúť AI trénera';

  @override
  String get onDeviceAiOrCloud => 'AI v zariadení alebo cloudový poskytovateľ';

  @override
  String get provider => 'Poskytovateľ';

  @override
  String get model => 'Model';

  @override
  String get chatAndAiBriefingsUse =>
      'Chat a AI prehľady používajú Apple Intelligence v tomto zariadení. Nie je potrebný kľúč API. Ak model nie je k dispozícii, prehľady zobrazia súhrn bez AI.';

  @override
  String get briefing => 'Prehľad';

  @override
  String get useAppleIntelligenceForBriefings =>
      'Použiť Apple Intelligence pre prehľady';

  @override
  String get useOnDeviceAiFor =>
      'Použiť AI v zariadení pre prehľady a ponechať vybraného poskytovateľa pre chat.';

  @override
  String get healthDataSharing => 'Zdieľanie zdravotných údajov';

  @override
  String get askOncePerChatSession => 'Opýtať sa raz za reláciu chatu';

  @override
  String get otherwiseAskBeforeEveryCloud =>
      'Inak sa opýtať pred každou cloudovou správou';

  @override
  String get reportABug => 'Nahlásiť chybu';

  @override
  String get weatherData => 'Údaje o počasí';

  @override
  String get openSourceLibraries => 'Knižnice s otvoreným kódom';

  @override
  String get license => 'Licencia';

  @override
  String get licenses => 'Licencie';

  @override
  String get apiKey => 'Kľúč API';

  @override
  String get saveApiKey => 'Uložiť kľúč API';

  @override
  String get feedbackBugReport => 'Spätná väzba a hlásenie chyby';

  @override
  String get reportSentThankYou => 'Hlásenie odoslané. Ďakujeme!';

  @override
  String get weReadEveryMessageIf =>
      'Čítame každú správu. Ak ste uviedli e-mail, môžete dostať odpoveď.';

  @override
  String get done => 'Hotovo';

  @override
  String get shareAnIdeaSuggestAn =>
      'Podeľte sa o nápad, navrhnite zlepšenie alebo nám napíšte, čo sa stalo a čo ste očakávali.';

  @override
  String get whatHappenedAndWhatDid => 'Čo sa stalo a čo ste očakávali?';

  @override
  String get pleaseLeaveOutPasswordsApi =>
      'Neuvádzajte heslá, kľúče API ani osobné zdravotné údaje.';

  @override
  String get includeDiagnostics => 'Pripojiť diagnostiku';

  @override
  String get optionalLogsMayContainAccount =>
      'Voliteľné. Záznamy môžu obsahovať údaje o účte alebo zdraví. Pred odoslaním ich skontrolujte nižšie.';

  @override
  String get diagnosticsPreview => 'NÁHĽAD DIAGNOSTIKY';

  @override
  String get sendingSharesYourEmailSubject =>
      'Odoslaním sa zdieľa váš e-mail, predmet, správa a vybraná diagnostika s podporou Fjelia na cloud.ebeling-hoppe.de.';

  @override
  String get copyReport => 'Kopírovať hlásenie';

  @override
  String get shareReport => 'Zdieľať hlásenie';

  @override
  String get appleHealth => 'Apple Zdravie';

  @override
  String get connectedServices => 'Pripojené služby';

  @override
  String get hiloBloodPressureBle => 'Hilo krvný tlak (BLE)';

  @override
  String get writeHeartDataToApple =>
      'Zapisovať údaje o srdci do Apple Zdravie';

  @override
  String get writeWeightDataToApple =>
      'Zapisovať údaje o hmotnosti do Apple Zdravie';

  @override
  String get renphoScaleBle => 'Váha Renpho (BLE)';

  @override
  String get polarH10HrvStrapBle => 'Polar H10 (hrudný pás HRV, BLE)';

  @override
  String get dataSourcePriority => 'Priorita zdrojov údajov';

  @override
  String get whenMultipleSourcesProvideThe =>
      'Ak viac zdrojov poskytuje rovnakú metriku, vyhrá vyššie postavený. Poradie zmeníte presunutím.';

  @override
  String get resetToDefault => 'Obnoviť predvolené';

  @override
  String get disconnect => 'Odpojiť';

  @override
  String get healthPage => 'Stránka Zdravie';

  @override
  String get loadPage => 'Stránka Záťaž';

  @override
  String get healthMonitor => 'Monitor zdravia';

  @override
  String get hrZones => 'Zóny TF';

  @override
  String get t30MinTtAvailableSync =>
      'K dispozícii je 30-min TT – synchronizovať zóny TF';

  @override
  String lt2Lt2BpmAt(Object lt2, Object at) {
    return 'LT2 $lt2 bpm · $at';
  }

  @override
  String get syncLabel => 'SYNCH';

  @override
  String get autoadjust => 'AUTOMATICKÉ PRISPÔSOBENIE';

  @override
  String zoneI(Object i) {
    return 'Zóna $i';
  }

  @override
  String get hrZones2 => 'ZÓNY TF';

  @override
  String ageRound(Object round) {
    return 'vek $round';
  }

  @override
  String get basics => 'Základné údaje';

  @override
  String get updateWaistMonthlyUsedFor =>
      'ⓘ Aktualizujte obvod pásu mesačne – používa sa na odhad viscerálneho tuku.';

  @override
  String get alcohol => 'Alkohol';

  @override
  String get t1Drink033L =>
      '1 nápoj ≈ 0,33 l piva / 0,2 l vína / 4 cl liehoviny';

  @override
  String get clinicalLabsOptional => 'Laboratórne hodnoty (voliteľné)';

  @override
  String get glycemic => 'Glykémia';

  @override
  String get optimalForLongevity48 =>
      'Optimum pre dlhovekosť: 4,8–5,4 % · Prediabetes: 5,7–6,4 %';

  @override
  String get lipids => 'Lipidy';

  @override
  String get apobReplacesLdlWhenBoth => 'ApoB nahrádza LDL, keď sú zadané oba.';

  @override
  String get inflammationKidney => 'Zápal a obličky';

  @override
  String get changesAreSavedAutomatically => 'Zmeny sa ukladajú automaticky';

  @override
  String get optionalTotalClimbingForThis =>
      'Voliteľné celkové prevýšenie pre tieto preteky.';

  @override
  String get moreAboutThisEvent => 'Viac o tomto podujatí';

  @override
  String distanceOfDistancekmKm(Object distanceKm) {
    return 'Vzdialenosť $distanceKm km?';
  }

  @override
  String keepDistancekmKm(Object distanceKm) {
    return 'Ponechať $distanceKm km';
  }

  @override
  String useLikelyKm(Object likely) {
    return 'Použiť $likely km';
  }

  @override
  String get thisBackupContainsNoCalendar =>
      'Táto záloha neobsahuje žiadne aktivity z kalendára.';

  @override
  String get activities => 'Aktivity';

  @override
  String get exportActivitiesCsv => 'Exportovať aktivity do CSV';

  @override
  String get backupRestore => 'Zálohovanie a obnova';

  @override
  String get backup => 'Záloha';

  @override
  String get restoreFromBackup => 'Obnoviť zo zálohy';

  @override
  String get backupRestoredRestartTheApp =>
      'Záloha bola obnovená. Reštartujte aplikáciu, aby sa načítali všetky nastavenia.';

  @override
  String get raceGoals => 'Ciele pretekov';

  @override
  String get yourActivities => 'Vaše aktivity';

  @override
  String get usedByAiCoachAnd =>
      'Používa ho AI tréner a tréningový plán. Športy v pláne sú označené ✦.';

  @override
  String get calendarWeekStart => 'Začiatok týždňa v kalendári';

  @override
  String get planDefaultView => 'Predvolené zobrazenie plánu';

  @override
  String get weeklySchedule => 'Týždenný rozvrh';

  @override
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      trainingDaysPerWeek,
      locale: localeName,
      other: '$trainingDaysPerWeek tréningových dní',
      few: '$trainingDaysPerWeek tréningové dni',
      one: '$trainingDaysPerWeek tréningový deň',
    );
    return '$_temp0 · ťuknutím prepnete Tréning / Odpočinok / Sila';
  }

  @override
  String get updatePlanToThisSchedule =>
      'Aktualizovať plán podľa tohto rozvrhu';

  @override
  String get updateStrengthSessions => 'Aktualizovať silové tréningy';

  @override
  String get sessionsPerDay => 'Tréningy za deň';

  @override
  String get canYouFitTwoWorkouts => 'Zvládnete dva tréningy v jeden deň?';

  @override
  String get strengthLoadUnit => 'Jednotka silovej záťaže';

  @override
  String get weightsThemselvesAreSetIn =>
      'Samotné váhy nastavujete v každom tréningu a pamätajú sa z vašej histórie.';

  @override
  String get hoursAvailableWeek => 'Dostupné hodiny / týždeň';

  @override
  String hoursperweekHWeek(Object hoursPerWeek) {
    return '$hoursPerWeek h / týždeň';
  }

  @override
  String hoursperweekH(Object hoursPerWeek) {
    return '$hoursPerWeek h';
  }

  @override
  String get heatAcclimation => 'Aklimatizácia na teplo';

  @override
  String get showHeatAcclimation => 'Zobraziť aklimatizáciu na teplo';

  @override
  String get weatherEvaluatedAgainstAConfigurable =>
      'Počasie sa vyhodnocuje pre nastaviteľné miesto.';

  @override
  String get trainingPlan => 'Tréningový plán';

  @override
  String get regenerateReplacesFutureSessionsAnd =>
      'Opätovné vytvorenie nahradí budúce tréningy a prebuduje plán od dnes s aktuálnymi nastaveniami.';

  @override
  String valueUpcomingWorkoutsGenerated(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: 'Vytvorených $value nadchádzajúcich tréningov',
      few: 'Vytvorené $value nadchádzajúce tréningy',
      one: 'Vytvorený $value nadchádzajúci tréning',
    );
    return '$_temp0';
  }

  @override
  String get generationFailedCheckYourRace =>
      'Vytvorenie zlyhalo. Skontrolujte cieľ pretekov a skúste to znova.';

  @override
  String get deleteAllWorkouts => 'Odstrániť všetky tréningy';

  @override
  String get changesAreSavedAutomatically2 => '✓ Zmeny sa ukladajú automaticky';

  @override
  String countUpcomingWorkoutsGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vytvorených $count nadchádzajúcich tréningov',
      few: 'Vytvorené $count nadchádzajúce tréningy',
      one: 'Vytvorený $count nadchádzajúci tréning',
    );
    return '$_temp0';
  }

  @override
  String get importRaceGoalsFromGarmin => 'Importovať ciele pretekov z Garminu';

  @override
  String get addRaceGoal => 'Pridať cieľ pretekov';

  @override
  String priorityTouppercase(Object toUpperCase) {
    return 'Priorita $toUpperCase';
  }

  @override
  String get goalsAreSharedWithAi =>
      'Ciele sa zdieľajú s AI trénerom. Priorita A, B alebo C určuje, ako plán váži vaše preteky voči sebe.';

  @override
  String get deletingWorkouts => 'Odstraňovanie tréningov';

  @override
  String get cityOrTown => 'Mesto alebo obec';

  @override
  String get eGHannoverOrPalma => 'napr. Hannover alebo Palma';

  @override
  String get noCitiesFoundTryA =>
      'Nenašli sa žiadne mestá. Skúste blízku obec.';

  @override
  String get chooseTheLocationForThe =>
      'Vyberte miesto pre predpoveď plánu, radar a aklimatizáciu na teplo. Počasie funguje aj pri vypnutej aklimatizácii.';

  @override
  String get none => 'Žiadna';

  @override
  String get disableLocalWeatherAndLocation =>
      'Vypnúť miestne počasie a požiadavky na polohu';

  @override
  String get currentLocation => 'Aktuálna poloha';

  @override
  String get followYourDeviceLocation => 'Sledovať polohu zariadenia';

  @override
  String get fixedLocation => 'Pevná poloha';

  @override
  String get chooseACityOrEnter => 'Vyberte mesto alebo zadajte súradnice';

  @override
  String get chooseCity => 'Vybrať mesto';

  @override
  String get coordinates => 'Súradnice';

  @override
  String get latitude => 'Zemepisná šírka';

  @override
  String get longitude => 'Zemepisná dĺžka';

  @override
  String get saveLocation => 'Uložiť polohu';

  @override
  String get refreshCurrentLocation => 'Obnoviť aktuálnu polohu';

  @override
  String get citySearchOpenMeteoGeonames =>
      'Vyhľadávanie miest: Open-Meteo / GeoNames';

  @override
  String get cityNamesOpenstreetmap => 'Názvy miest: © OpenStreetMap';

  @override
  String get energy => 'ENERGIA';

  @override
  String get currentEnergy => 'AKTUÁLNA ENERGIA';

  @override
  String get dailyTimeline => 'DENNÝ PRIEBEH';

  @override
  String valueValue2(Object value, Object value2) {
    return '$value → $value2';
  }

  @override
  String get energy2 => 'Energia';

  @override
  String get noData => 'Žiadne údaje';

  @override
  String get bloodPressureInsights => 'PREHĽAD KRVNÉHO TLAKU';

  @override
  String get sys => ' Sys';

  @override
  String get diaMmhg => ' Dia · mmHg';

  @override
  String get previousBloodPressurePeriod =>
      'Predchádzajúce obdobie krvného tlaku';

  @override
  String get nextBloodPressurePeriod => 'Nasledujúce obdobie krvného tlaku';

  @override
  String get nightDipping => 'Nočný pokles';

  @override
  String get noMeasurementsInThisPeriod =>
      'V tomto období nie sú žiadne merania';

  @override
  String get fullscreenBloodPressureChart =>
      'Graf krvného tlaku na celú obrazovku';

  @override
  String get barsMinMaxLineDots =>
      'Stĺpce: min–max · čiara/body: priemer · ťuknutím alebo ťahaním si zobrazíte detail';

  @override
  String get noMeasurements => 'Žiadne merania';

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
      other: '$length meraní',
      few: '$length merania',
      one: '$length meranie',
    );
    return '$_temp0 · priemer / min–max';
  }

  @override
  String bloodPressureTouppercaseMmhg(Object toUpperCase) {
    return 'KRVNÝ TLAK · $toUpperCase · mmHg';
  }

  @override
  String get closeFullscreenBloodPressureChart =>
      'Zavrieť graf krvného tlaku na celú obrazovku';

  @override
  String get chooseScale => 'Vybrať váhu';

  @override
  String get noScalesFoundStepOn =>
      'Nenašli sa žiadne váhy. Postavte sa na váhu a skúste to znova.';

  @override
  String nameRssiDbm(Object name, Object rssi) {
    return '$name · $rssi dBm';
  }

  @override
  String get renphoSaved => 'RENPHO uložená:';

  @override
  String get renphoScaleBle2 => 'Váha RENPHO (BLE)';

  @override
  String get changeMeasurementType => 'Zmeniť typ merania';

  @override
  String get addMeasurement => 'Pridať meranie';

  @override
  String get whatAreYouMeasuring => 'Čo meriate?';

  @override
  String get chooseAnotherMeasurement => 'Vybrať iné meranie';

  @override
  String get saveMeasurement => 'Uložiť meranie';

  @override
  String get skip => 'Preskočiť';

  @override
  String get connectHiloService => 'Pripojiť službu Hilo';

  @override
  String get connectHilo => 'Pripojiť Hilo';

  @override
  String get connectCoros => 'Pripojiť Coros';

  @override
  String get europe => 'Európa';

  @override
  String get unitedStates => 'USA';

  @override
  String get asia => 'Ázia';

  @override
  String get bluetoothBloodPressure => 'Bluetooth · krvný tlak';

  @override
  String get cloudCuffData => 'Cloud · údaje z manžety';

  @override
  String get apiSync => 'Synchronizácia cez API';

  @override
  String get bluetoothHrvStrap => 'Bluetooth · hrudný pás HRV';

  @override
  String get accesslinkApi => 'AccessLink API';

  @override
  String get systemHealthData => 'Systémové zdravotné údaje';

  @override
  String get cloudScaleHistory => 'Cloud · história váhy';

  @override
  String get bluetoothWeightBody => 'Bluetooth · hmotnosť a telo';

  @override
  String get connectYourDevices => 'Pripojte svoje zariadenia';

  @override
  String get continueLabel => 'Pokračovať';

  @override
  String get connectGarmin => 'Pripojiť Garmin';

  @override
  String get connectAppleHealth => 'Pripojiť Apple Zdravie';

  @override
  String get dataSynced => 'ÚDAJE SYNCHRONIZOVANÉ';

  @override
  String get pairHiloPod => 'Spárovať Hilo Pod';

  @override
  String get chooseStrap => 'Vybrať pás';

  @override
  String namePaired(Object name) {
    return '$name je spárovaný.';
  }

  @override
  String get pairPolarH10 => 'Spárovať Polar H10';

  @override
  String get forget => 'Zabudnúť';

  @override
  String get sendWorkoutToPolar => 'Odoslať tréning do Polaru';

  @override
  String get connectPolar => 'Pripojiť Polar';

  @override
  String get signInWithPolarFlow => 'Prihlásiť sa cez Polar Flow';

  @override
  String get syncsSleepStagesHrvResting =>
      'Synchronizuje fázy spánku · HRV · pokojovú TF · tréningy · kroky';

  @override
  String savedForV(Object v) {
    return 'Uložené pre $v';
  }

  @override
  String get remove => 'Odstrániť';

  @override
  String get polarEMail => 'E-mail Polar';

  @override
  String get polarPassword => 'Heslo Polar';

  @override
  String get pairRenphoScale => 'Spárovať váhu RENPHO';

  @override
  String get connectRenpho => 'Pripojiť Renpho';

  @override
  String get connectSuunto => 'Pripojiť Suunto';

  @override
  String smsSentToTrim(Object trim) {
    return 'SMS odoslaná na $trim';
  }

  @override
  String get resendSms => 'Odoslať SMS znova';

  @override
  String get retryLoadingPreferences => 'Skúsiť znova načítať predvoľby';

  @override
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed) {
    return 'TÝŽDENNÝ ČAS TRÉNINGU · $toStringAsFixed h';
  }

  @override
  String get tapADayToCycle =>
      'Ťuknutím na deň prepnete Tréning / Odpočinok / Sila.';

  @override
  String get doubleDayOk => 'Dvojitý deň ok';

  @override
  String get birthYearOptional => 'Rok narodenia (voliteľné)';

  @override
  String get addAnother => 'Pridať ďalší';

  @override
  String get knowYourBodyTrainSmarter =>
      'Poznajte svoje telo.\nTrénujte múdrejšie.';

  @override
  String get allYourHealthDevicesOne =>
      'Všetky vaše zdravotné zariadenia. Jeden inteligentný prehľad.';

  @override
  String get areYouReadyToTrain => 'Ste dnes pripravení trénovať?';

  @override
  String get hrvRecoveryScoreRestingHr =>
      'HRV · Skóre regenerácie · Pokojová TF';

  @override
  String get didYouActuallyRecoverLast => 'Naozaj ste sa v noci zregenerovali?';

  @override
  String get sleepStagesDeepSleepSpo => 'Fázy spánku · Hlboký spánok · SpO₂';

  @override
  String get isYourBloodPressureUnder => 'Je váš krvný tlak pod kontrolou?';

  @override
  String get continuousBpNightDippingTrends =>
      'Nepretržitý krvný tlak · Nočný pokles · Trendy';

  @override
  String get howHardDidYouPush => 'Ako tvrdo ste tento týždeň trénovali?';

  @override
  String get trainingLoadTrimpStrainScore =>
      'Tréningová záťaž · TRIMP · Skóre záťaže';

  @override
  String get isYourBodyCompositionImproving =>
      'Zlepšuje sa vaše zloženie tela?';

  @override
  String get weightBodyFatMuscleMass =>
      'Hmotnosť · Telesný tuk · Svalová hmota';

  @override
  String get getStarted => 'Začať';

  @override
  String get yourDataStaysOnYour => 'Tvoje údaje. Ty rozhoduješ, čo zdieľaš.';

  @override
  String get bodyScale => 'Osobná váha';

  @override
  String get bodyComposition => 'Zloženie tela';

  @override
  String get sleep => 'SPÁNOK';

  @override
  String get sleepPerformance => 'VÝKON SPÁNKU';

  @override
  String get sleepHistory => 'História spánku';

  @override
  String labelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String lessLabel(Object label) {
    return 'Menej $label';
  }

  @override
  String moreLabel(Object label) {
    return 'Viac $label';
  }

  @override
  String get gymMode => 'Režim posilňovne';

  @override
  String get finishWorkout => 'Ukončiť tréning';

  @override
  String get workoutActions => 'Akcie tréningu';

  @override
  String get discardWorkout => 'Zahodiť tréning';

  @override
  String get allSetsRecorded => 'Všetky série zaznamenané';

  @override
  String get reviewSets => 'Skontrolovať série';

  @override
  String get rest => 'ODPOČINOK';

  @override
  String plannedResttarget(Object restTarget) {
    return 'Plánované $restTarget';
  }

  @override
  String get startSet => 'Začať sériu';

  @override
  String get seconds => 'Sekundy';

  @override
  String get previousSet => 'Predchádzajúca séria';

  @override
  String get allSets => 'Všetky série';

  @override
  String get nextSet => 'Ďalšia séria';

  @override
  String get everySetIsSavedAs =>
      'Každá séria sa ukladá priebežne. Túto obrazovku môžete kedykoľvek zavrieť a pokračovať z plánovaného tréningu.';

  @override
  String get cancel => 'Zrušiť';

  @override
  String get apply => 'Použiť';

  @override
  String get effortScale => 'Stupnica námahy';

  @override
  String get setType => 'Typ série';

  @override
  String get reps => 'Opakovania';

  @override
  String get range => 'Rozsah';

  @override
  String get time => 'Čas';

  @override
  String get t45Or100 => '45 alebo 1:00';

  @override
  String get blankWhenNotSet => 'Prázdne, ak nie je nastavené';

  @override
  String get redBand => 'Červená guma';

  @override
  String get t90Or130 => '90 alebo 1:30';

  @override
  String get blankWhenUnknown => 'Prázdne, ak nie je známe';

  @override
  String get usePlannedLoad => 'Použiť plánovanú záťaž';

  @override
  String get blankWhenNotMeasured => 'Prázdne, ak nie je merané';

  @override
  String get exercise => 'Cvik';

  @override
  String get changingTheLoadConventionStarts =>
      'Zmena konvencie záťaže začne pre tento cvik samostatnú históriu.';

  @override
  String get barbellMachine => 'Činka, stroj…';

  @override
  String get load => 'Záťaž';

  @override
  String get loadRefersTo => 'Záťaž sa vzťahuje na';

  @override
  String get t2ForAPair => '2 pre pár';

  @override
  String get repetitions => 'Opakovania';

  @override
  String get availablePlatesOrDumbbells => 'Dostupné kotúče alebo jednoručky';

  @override
  String get rememberForThisEquipment => 'Zapamätať pre toto vybavenie';

  @override
  String get findOrNameAnExercise => 'Nájsť alebo pomenovať cvik';

  @override
  String createTrim(Object trim) {
    return 'Vytvoriť „$trim“';
  }

  @override
  String get customExercise => 'Vlastný cvik';

  @override
  String get smallestLoadStep => 'Najmenší krok záťaže';

  @override
  String whatRemoved(Object what) {
    return '$what odstránené';
  }

  @override
  String get undo => 'Vrátiť späť';

  @override
  String get retry => 'Skúsiť znova';

  @override
  String get performance => 'Výkon';

  @override
  String get addExercise => 'Pridať cvik';

  @override
  String get finishLog => 'Dokončiť záznam';

  @override
  String get keepAsDraft => 'Ponechať ako koncept';

  @override
  String actionsForName(Object name) {
    return 'Akcie pre $name';
  }

  @override
  String get editExercise => 'Upraviť cvik';

  @override
  String get moveUp => 'Posunúť hore';

  @override
  String get moveDown => 'Posunúť dole';

  @override
  String get addSet => 'Pridať sériu';

  @override
  String get removeLastSet => 'Odstrániť poslednú sériu';

  @override
  String get saveAsTemplate => 'Uložiť ako šablónu';

  @override
  String savedTitleAsATemplate(Object title) {
    return '„$title“ uložené ako šablóna. Tento tréning zostane nezmenený, kým ho neuložíte.';
  }

  @override
  String nameSetN(Object name, Object n) {
    return '$name · Séria $n';
  }

  @override
  String nameAllWorkingSets(Object name) {
    return '$name · Všetky pracovné série';
  }

  @override
  String labelRest(Object label) {
    return 'Odpočinok $label';
  }

  @override
  String get secondsOrMSs => 'Sekundy alebo m:ss';

  @override
  String get applyToAllSets => 'Použiť na všetky série';

  @override
  String get duplicate => 'Duplikovať';

  @override
  String get supersetWithNext => 'Superséria s ďalším';

  @override
  String get circuitWithNext => 'Okruh s ďalším';

  @override
  String actionsForSetN(Object n) {
    return 'Akcie pre sériu $n';
  }

  @override
  String get editSet => 'Upraviť sériu';

  @override
  String get duplicateSet => 'Duplikovať sériu';

  @override
  String get removeSet => 'Odstrániť sériu';

  @override
  String labelActions(Object label) {
    return 'Akcie $label';
  }

  @override
  String get editRests => 'Upraviť pauzy';

  @override
  String get ungroup => 'Zrušiť zoskupenie';

  @override
  String get editExercises => 'Upraviť cviky';

  @override
  String get unsavedChanges => 'Neuložené zmeny';

  @override
  String couldNotSaveError(Object error) {
    return 'Nepodarilo sa uložiť: $error';
  }

  @override
  String get history => 'História';

  @override
  String get exercises => 'Cviky';

  @override
  String get noExercisesArePlannedFor =>
      'Pre tento tréning zatiaľ nie sú naplánované žiadne cviky. Opisujú ho poznámky vyššie.';

  @override
  String get addExercises => 'Pridať cviky';

  @override
  String get fromTheBuiltInTemplate =>
      'Z vstavanej šablóny. Záťaž si nastavujete sami; história sa zobrazí po zaznamenaní tréningu.';

  @override
  String get shareExerciseList => 'Zdieľať zoznam cvikov';

  @override
  String get noSavedStrengthTemplatesYet =>
      'Zatiaľ žiadne uložené silové šablóny. Najprv jednu uložte z plánovaného tréningu.';

  @override
  String get compareWith => 'Porovnať s';

  @override
  String estimated1rmUnit(Object unit) {
    return 'Odhadované 1RM $unit';
  }

  @override
  String get plannedNotRecorded => 'Naplánované, nezaznamenané';

  @override
  String get notes => 'Poznámky';

  @override
  String get editPerformance => 'Upraviť výkon';

  @override
  String get compareWithASavedWorkout => 'Porovnať s uloženým tréningom';

  @override
  String get sessions => 'Tréningy';

  @override
  String get radarUnavailableRetry => 'Radar nedostupný · Skúsiť znova';

  @override
  String get radar => 'Radar';

  @override
  String get weatherDataByRainviewer => 'Údaje o počasí od RainViewer';

  @override
  String get openstreetmapContributors => '© prispievatelia OpenStreetMap';

  @override
  String get weather => 'Počasie';

  @override
  String get weatherUnavailableRetry => 'Počasie nedostupné · Skúsiť znova';

  @override
  String get chooseAFixedLocationIn =>
      'Vyberte pevnú polohu v nastaveniach Počasie a poloha alebo povoľte prístup k polohe pre miestne počasie.';

  @override
  String get locationSettings => 'Nastavenia polohy';

  @override
  String get retryLocation => 'Skúsiť polohu znova';

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
    return 'Mokrý teplomer $toStringAsFixed°C';
  }

  @override
  String get previousForecastDay => 'Predchádzajúci deň predpovede';

  @override
  String get nextForecastDay => 'Nasledujúci deň predpovede';

  @override
  String daysDayForecast(Object days) {
    return '$days-dňová predpoveď';
  }

  @override
  String thisProviderCurrentlySuppliesDays(Object days, Object days2) {
    return 'Tento poskytovateľ momentálne dodáva $days z $days2 dní predpovede.';
  }

  @override
  String get now => 'Teraz';

  @override
  String get sunriseSunset => 'Východ / západ slnka';

  @override
  String keyKey2(Object key, Object key2) {
    return '☀ $key   ☾ $key2';
  }

  @override
  String get use => 'Použiť';

  @override
  String get exerciseDetailsWereNotProvided =>
      'Zdroj tejto aktivity neposkytol podrobnosti o cvikoch.';

  @override
  String get logFromPlan => 'Zaznamenať z plánu';

  @override
  String get addExerciseDetails => 'Pridať podrobnosti o cvikoch';

  @override
  String get loadSuggestion => 'Návrh záťaže';

  @override
  String get applyToThisWorkout => 'Použiť na tento tréning';

  @override
  String get keepCurrentLoad => 'Ponechať aktuálnu záťaž';

  @override
  String get setLoadStep => 'Nastaviť krok záťaže';

  @override
  String get viewSupportingSets => 'Zobraziť podporné série';

  @override
  String get supportingSets => 'Podporné série';

  @override
  String get noRecordedSessionsYet => 'Zatiaľ žiadne zaznamenané tréningy.';

  @override
  String nameDemonstrationCue(Object name, Object cue) {
    return 'Ukážka cviku $name. $cue';
  }

  @override
  String get noScalesFoundStepOn2 =>
      'Nenašli sa žiadne váhy. Postavte sa na váhu a skúste to znova.';

  @override
  String get scalePaired => 'Váha spárovaná';

  @override
  String get ok => 'OK';

  @override
  String get pairedReadyToMeasure => '✓ Spárované – pripravené na meranie';

  @override
  String get chooseHiloCuff => 'Vybrať manžetu Hilo';

  @override
  String get noCuffFoundWakeYour =>
      'Nenašla sa žiadna manžeta. Zobuďte manžetu a skúste hľadať znova.';

  @override
  String get hiloCuffAktiiaC => 'Manžeta Hilo (AKTIIA C…)';

  @override
  String get onDemandBloodPressureVia => 'Krvný tlak na požiadanie cez BLE';

  @override
  String get selectHiloPodWristband => 'Vybrať Hilo Pod (náramok)';

  @override
  String get rescan => 'Hľadať znova';

  @override
  String get noDevicesFoundTapTo =>
      'Nenašli sa žiadne zariadenia. Ťuknutím na ↻ vyhľadáte znova.';

  @override
  String get polarH10SpotHrv => 'Polar H10 · Bodové HRV';

  @override
  String get aSeparateHrvReadingBefore =>
      'Samostatné meranie HRV pred tréningom alebo po ňom. Tieto merania nenahrádzajú nočné HRV z Garminu ani nemenia vaše skóre pripravenosti.';

  @override
  String get wearTheStrapWithMoist =>
      'Pás noste s navlhčenými elektródami. Zostaňte v pokoji a dýchajte normálne. Na porovnávanie používajte rovnakú polohu a dĺžku záznamu. Po tréningu si poznačte, ako dlho ste najprv odpočívali.';

  @override
  String get measurement => 'Meranie';

  @override
  String get posture => 'Poloha';

  @override
  String get recordingLengthPlus1Min => 'Dĺžka záznamu · plus 1 min ustálenia';

  @override
  String get t2Minutes => '2 minúty';

  @override
  String get t5Minutes => '5 minút';

  @override
  String get minutesSinceTrainingEndedOptional =>
      'Minúty od skončenia tréningu (voliteľné)';

  @override
  String get sessionOrNotesOptional => 'Tréning alebo poznámky (voliteľné)';

  @override
  String connectName(Object name) {
    return 'Pripojiť $name';
  }

  @override
  String get findPolarH10 => 'Nájsť Polar H10';

  @override
  String signalRssiDbm(Object rssi) {
    return 'Signál $rssi dBm';
  }

  @override
  String connectedName(Object name) {
    return 'Pripojené: $name';
  }

  @override
  String get waitingForHeartRateAnd =>
      'Čaká sa na tepovú frekvenciu a intervaly RR. Skontrolujte kontakt pásu.';

  @override
  String get startMeasurement => 'Spustiť meranie';

  @override
  String get cancelMeasurement => 'Zrušiť meranie';

  @override
  String get spotHrvRmssd => 'Bodové HRV · RMSSD';

  @override
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  ) {
    return '$accepted/$length použiteľných intervalov · $toStringAsFixed % pokrytie';
  }

  @override
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs) {
    return 'lnRMSSD: $lnRmssd · Surové RMSSD: $rawRmssdMs ms';
  }

  @override
  String get signalQualityIsTooLow =>
      'Kvalita signálu je príliš nízka na uloženie. Zopakujte meranie s dobrým kontaktom pásu. Vyžaduje sa aspoň 95 % použiteľných intervalov a 90 % pokrytie.';

  @override
  String get savedToSpotHrvHistory => 'Uložené do histórie bodového HRV.';

  @override
  String get newMeasurement => 'Nové meranie';

  @override
  String get signalScreeningExcludesPoorContact =>
      'Filtrovanie signálu vylučuje slabý kontakt, RR mimo 250–2500 ms a intervaly s odchýlkou viac než 25 % od lokálneho mediánu. Medzery sa nedopĺňajú. Nejde o lekársky test ani samostatné skóre pripravenosti.';

  @override
  String historyLabelLabel2DurationMin(
    Object label,
    Object label2,
    Object duration,
  ) {
    return 'História · $label · $label2 · $duration min';
  }

  @override
  String get onlyReadingsWithTheSame =>
      'Spolu sa zobrazujú iba merania s rovnakým kontextom, polohou a dĺžkou.';

  @override
  String get noMatchingMeasurementsYet =>
      'Zatiaľ žiadne zodpovedajúce merania.';

  @override
  String tostringasfixedMsRmssdTostringasfixed2Bpm(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return '$toStringAsFixed ms RMSSD · $toStringAsFixed2 bpm';
  }

  @override
  String get exportRrIntervalsCsv => 'Exportovať intervaly RR (CSV)';

  @override
  String get deleteMeasurement => 'Odstrániť meranie';

  @override
  String get remindMeToMeasureHrv => 'Pripomenúť mi meranie HRV po tréningu';

  @override
  String get appleHealthIsNoLonger => 'Apple Zdravie už nie je dostupné';

  @override
  String get later => 'Neskôr';

  @override
  String get reconnect => 'Pripojiť znova';

  @override
  String get gripStrength => 'Sila stisku';

  @override
  String get leftKg => 'Ľavá (kg)';

  @override
  String get rightKg => 'Pravá (kg)';

  @override
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg) {
    return 'Ľ $leftKg · P $rightKg kg';
  }

  @override
  String get notificationsAreOffYouCan =>
      'Upozornenia sú vypnuté. Stále môžete merať z tréningu.';

  @override
  String get noRemindersFrom2200 => 'Žiadne pripomienky od 22:00 do 07:00';

  @override
  String get aReminderThatWouldFall =>
      'Pripomienka, ktorá by pripadla na toto obdobie, sa preskočí a neposunie na ráno.';

  @override
  String get remindersArriveQuietlyInThe =>
      'Pripomienky prichádzajú ticho do zoznamu upozornení.';

  @override
  String get noForecastForThisDay => 'Žiadna predpoveď pre tento deň';

  @override
  String get fullscreen => 'Celá obrazovka';

  @override
  String source(Object source) {
    return '● $source';
  }

  @override
  String get shadedAreaProviderSpread =>
      'Tieňovaná oblasť: rozptyl medzi poskytovateľmi';

  @override
  String get temperatureC => '● Teplota °C';

  @override
  String get rainMm => '▥ Dážď mm';

  @override
  String get uvIndex => '— UV index';

  @override
  String get closeFullscreenWeatherChart =>
      'Zavrieť graf počasia na celú obrazovku';

  @override
  String get sleepStages => 'FÁZY SPÁNKU';

  @override
  String get noStageTimelineForThis =>
      'Pre túto noc nie je k dispozícii časová os fáz.';

  @override
  String round3(Object round) {
    return '$round%';
  }

  @override
  String get examplesOnlyCheckAndEnter =>
      'Iba príklady: skontrolujte a zadajte hodnoty z etikety produktu na porciu. Neznáme živiny nechajte prázdne; 0 zadajte, iba ak je hodnota známa.';

  @override
  String get nutritionStrategy => 'Výživová stratégia';

  @override
  String get noPreWorkoutNutritionStrategy =>
      'Nebola uložená žiadna výživová stratégia pred tréningom.';

  @override
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium) {
    return '$carbs g sacharidov/h · $fluid ml/h · $sodium mg sodíka/h';
  }

  @override
  String get forecastUpdatedReviewOrRecalculate =>
      'Predpoveď bola aktualizovaná – skontrolujte alebo prepočítajte uloženú stratégiu.';

  @override
  String strategySavedSavedat(Object savedAt) {
    return 'Stratégia uložená $savedAt';
  }

  @override
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  ) {
    return 'Spolu počas: $totalCarbs g sacharidov · $totalFluid ml · $totalSodium mg sodíka';
  }

  @override
  String every20MinAboutCarbs(Object carbs, Object fluid) {
    return 'Každých 20 min: približne $carbs g sacharidov a $fluid ml.';
  }

  @override
  String get packQuantitiesIncludeFullContainers =>
      'Množstvá na zbalenie zahŕňajú celé obaly; nie je nutné všetko skonzumovať.';

  @override
  String get workoutChangedReviewOrRecalculate =>
      'Tréning sa zmenil – skontrolujte alebo prepočítajte uloženú stratégiu.';

  @override
  String get conditionsAndFeedingPlan => 'Podmienky a plán príjmu stravy';

  @override
  String get editStrategy => 'Upraviť stratégiu';

  @override
  String get recalculate => 'Prepočítať';

  @override
  String get actualNutrition => 'Skutočná výživa';

  @override
  String get someProductValuesAreUnknown =>
      'Niektoré hodnoty produktov nie sú známe; súčty sú neúplné.';

  @override
  String get logFoodAndFluids => 'Zaznamenať jedlo a tekutiny';

  @override
  String get recordWhatYouActuallyHad =>
      'Zapíšte, čo ste skutočne skonzumovali. Plánovaný príjem sa do tohto záznamu nekopíruje.';

  @override
  String get elapsedMinutesIncludingStopsOptional =>
      'Uplynuté minúty vrátane zastavení (voliteľné)';

  @override
  String recordedDurationActivityMin(Object activity) {
    return 'Zaznamenané trvanie: $activity min';
  }

  @override
  String get compareWithSavedStrategy => 'Porovnať s uloženou stratégiou';

  @override
  String get useMatchedSessionIfAvailable =>
      'Použiť zodpovedajúci tréning, ak je k dispozícii';

  @override
  String get noPlanComparison => 'Bez porovnania s plánom';

  @override
  String titleDate(Object title, Object date) {
    return '$title · $date';
  }

  @override
  String get linkedStrategyUnavailable =>
      'Prepojená stratégia nie je k dispozícii';

  @override
  String quantityName(Object quantity, Object name) {
    return '$quantity × $name';
  }

  @override
  String get removeIntake => 'Odstrániť príjem';

  @override
  String get addFoodOrDrink => 'Pridať jedlo alebo nápoj';

  @override
  String get iHadNoIntake => 'Nič som neskonzumoval';

  @override
  String get giGutComfort => 'Tráviaci komfort';

  @override
  String get whatWorkedSymptomsAccessProblems =>
      'Čo fungovalo / príznaky / problémy s prístupom';

  @override
  String get saveDraft => 'Uložiť koncept';

  @override
  String get skipLoggingThisActivity =>
      'Preskočiť zaznamenávanie tejto aktivity';

  @override
  String get nutritionAndFluids => 'Výživa a tekutiny';

  @override
  String get productsToleranceAndMeasuredSweat =>
      'Produkty, tolerancia a namerané straty potu';

  @override
  String get postWorkoutIntakeReminder => 'Pripomienka príjmu po tréningu';

  @override
  String get onceAfterARecentEndurance =>
      'Raz po nedávnom vytrvalostnom tréningu; tiché hodiny 22:00–08:00.';

  @override
  String get addHiloBpReport => 'Pridať správu o tlaku Hilo';

  @override
  String get readingPdfReportsIsOnly =>
      'Čítanie správ vo formáte PDF je dostupné iba v iOS a macOS.';

  @override
  String get chooseAnotherReport => 'Vybrať inú správu';

  @override
  String get biologicalAge => 'Biologický vek';

  @override
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class) {
    return 'VO₂max $vo2max ml/kg/min · $vo2Class';
  }

  @override
  String get factorContributions => 'Príspevky faktorov';

  @override
  String estimatedRangeRoundRound2Years(Object round, Object round2) {
    return 'Odhadovaný rozsah $round–$round2 rokov. Ide o odhad modelu, nie lekársku diagnózu.';
  }

  @override
  String get noEnergyMeasurementsForThis =>
      'Pre tento deň nie sú žiadne merania energie';

  @override
  String get scanningStepOnTheScale =>
      'Vyhľadávam… keď budete pripravení, postavte sa na váhu.';

  @override
  String waistWaistCmUpdateMonthly(Object waist) {
    return 'Pás: $waist cm – aktualizujte mesačne v Profile';
  }

  @override
  String get measuring => 'Meriam…';

  @override
  String get tryAgain => 'Skúsiť znova';

  @override
  String get systolic => 'Systolický';

  @override
  String get diastolic => 'Diastolický';

  @override
  String get heartRate => 'Tepová frekvencia';

  @override
  String get weight => 'Hmotnosť';

  @override
  String get bodyFat => 'Telesný tuk';

  @override
  String get duration => 'Trvanie';

  @override
  String get deep => 'Hlboký';

  @override
  String get spo => 'SpO₂';

  @override
  String get activityName => 'Názov aktivity';

  @override
  String get sport => 'Šport';

  @override
  String get distance => 'Vzdialenosť';

  @override
  String get saved => 'Uložené';

  @override
  String get connectionFailedCheckYourInternet =>
      'Pripojenie zlyhalo. Skontrolujte internetové pripojenie.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Heslo';

  @override
  String get passwordTooShort => 'Heslo je príliš krátke';

  @override
  String get loginFailedCheckYourEmail =>
      'Prihlásenie zlyhalo. Skontrolujte e-mail a heslo.';

  @override
  String get connectionFailedCheckYourCredentials =>
      'Pripojenie zlyhalo. Skontrolujte prihlasovacie údaje a internetové pripojenie.';

  @override
  String get region => 'Región';

  @override
  String get hiloPod => 'Hilo Pod';

  @override
  String get hiloAccount => 'Účet Hilo';

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
  String get renphoAccount => 'Účet Renpho';

  @override
  String get garminConnectEmail => 'E-mail Garmin Connect';

  @override
  String get verifyMfaCode => 'Overiť kód MFA';

  @override
  String get verificationCode => 'Overovací kód';

  @override
  String errorE(Object e) {
    return 'Chyba: $e';
  }

  @override
  String get noHiloPodFoundMake =>
      'Nenašiel sa žiadny Hilo Pod. Uistite sa, že je nabitý a nablízku.';

  @override
  String scanFailedE(Object e) {
    return 'Vyhľadávanie zlyhalo: $e';
  }

  @override
  String get hiloPod2 => 'Hilo Pod';

  @override
  String get scanForPod => 'Vyhľadať pod';

  @override
  String get scanForPolarH10 => 'Vyhľadať Polar H10';

  @override
  String get couldNotReachPolarCheck =>
      'Polar sa nepodarilo kontaktovať. Skontrolujte pripojenie.';

  @override
  String get signInAndSendWorkout => 'Prihlásiť sa a odoslať tréning';

  @override
  String get scanForScale => 'Vyhľadať váhu';

  @override
  String get passwordRequired => 'Heslo je povinné';

  @override
  String get enterYourPhoneNumberWith =>
      'Zadajte telefónne číslo (s predvoľbou krajiny, napr. +421…) a e-mail Suunto.';

  @override
  String get enterThePinFromThe => 'Zadajte PIN z SMS.';

  @override
  String get incorrectPinPleaseTryAgain => 'Nesprávny PIN. Skúste to znova.';

  @override
  String get phoneNumber => 'Telefónne číslo';

  @override
  String get suuntoAccountEmail => 'E-mail účtu Suunto';

  @override
  String get enterPinFromSms => 'Zadať PIN z SMS';

  @override
  String get verifyConnect => 'Overiť a pripojiť';

  @override
  String get sendSmsCode => 'Odoslať SMS kód';

  @override
  String couldNotSavePreferencesE(Object e) {
    return 'Predvoľby sa nepodarilo uložiť: $e';
  }

  @override
  String get mon => 'Po';

  @override
  String get tue => 'Ut';

  @override
  String get wed => 'St';

  @override
  String get thu => 'Št';

  @override
  String get fri => 'Pi';

  @override
  String get sat => 'So';

  @override
  String get sun => 'Ne';

  @override
  String get male => 'Muž';

  @override
  String get female => 'Žena';

  @override
  String get other => 'Iné';

  @override
  String get running => 'Beh';

  @override
  String get trailRunning => 'Trailový beh';

  @override
  String get cycling => 'Cyklistika';

  @override
  String get swimming => 'Plávanie';

  @override
  String get triathlon => 'Triatlon';

  @override
  String get hiking => 'Turistika';

  @override
  String get rowing => 'Veslovanie';

  @override
  String get buildMyPlan => 'Vytvoriť môj plán';

  @override
  String get keepAConsistentBedtimeAnd =>
      'Dodržiavajte pravidelný čas ukladania a vstávania, aby ste podporili spánkovú rutinu.';

  @override
  String get thisWorkoutHasNoSets => 'Tento tréning nemá žiadne série.';

  @override
  String loadName(Object name) {
    return 'Záťaž ($name)';
  }

  @override
  String get setLabel => 'Séria';

  @override
  String get lowestReps => 'Najnižší počet opakovaní';

  @override
  String get highestReps => 'Najvyšší počet opakovaní';

  @override
  String get repsPerSide => 'Opakovania na stranu';

  @override
  String get fromReps => 'Od (opak.)';

  @override
  String get toReps => 'Do (opak.)';

  @override
  String get addedLoad => 'Pridaná záťaž';

  @override
  String get assistance => 'Asistencia';

  @override
  String get tempoOptional => 'Tempo (voliteľné)';

  @override
  String get notesOptional => 'Poznámky (voliteľné)';

  @override
  String get enterTheRepetitionsDone => 'Zadajte vykonané opakovania.';

  @override
  String plannedUnit(Object unit) {
    return 'Plánované $unit';
  }

  @override
  String get repsDone => 'Vykonané opakovania';

  @override
  String get resistance => 'Odpor';

  @override
  String get implementsLabel => 'Náradie';

  @override
  String get name => 'Názov';

  @override
  String get instructionsOptional => 'Pokyny (voliteľné)';

  @override
  String get remember => 'Zapamätať';

  @override
  String get notSavedYet => 'Zatiaľ neuložené';

  @override
  String get saving => 'Ukladám…';

  @override
  String get couldNotSave => 'Nepodarilo sa uložiť';

  @override
  String get plannedValuesAreHintsNot =>
      'Plánované hodnoty sú len orientačné, nie výsledky. Ťuknutím na sériu ju zaznamenáte.';

  @override
  String get completedAsPlanned => 'Dokončené podľa plánu';

  @override
  String get save => 'Uložiť';

  @override
  String get nameTheTemplate => 'Pomenujte šablónu.';

  @override
  String setN(Object n) {
    return 'Séria $n';
  }

  @override
  String get changesApplyToThisWorkout =>
      'Zmeny sa vzťahujú iba na tento tréning. Dokončené tréningy a ostatné tréningy zostanú nezmenené.';

  @override
  String get saveForThisWorkout => 'Uložiť pre tento tréning';

  @override
  String knownForKnownOfOf(Object known, Object of) {
    return 'Známe pre $known z $of sérií so záťažou';
  }

  @override
  String get sessionEstimate => 'Odhad tréningu';

  @override
  String get calculatedRange => 'Vypočítaný rozsah';

  @override
  String get timedWork => 'Časovaná práca';

  @override
  String get strengthTraining => 'Silový tréning';

  @override
  String get theExercisesCouldNotBe => 'Cviky sa nepodarilo načítať.';

  @override
  String get resumeWorkout => 'Pokračovať v tréningu';

  @override
  String get strengthWorkout => 'Silový tréning';

  @override
  String get untitledTemplate => 'Šablóna bez názvu';

  @override
  String get theRecordedExercisesCouldNot =>
      'Zaznamenané cviky sa nepodarilo načítať.';

  @override
  String get exercisesPerformed => 'Vykonané cviky';

  @override
  String get comparedWithThePlanAs =>
      'Porovnané s plánom v stave, v akom bol na začiatku zaznamenávania.';

  @override
  String topWorkingLoadName(Object name) {
    return 'Najvyššia pracovná záťaž ($name)';
  }

  @override
  String get estimated1rmMiddleOfRange => 'Odhadované 1RM, stred rozsahu';

  @override
  String get noLoggedSessionsYet => 'Zatiaľ žiadne zaznamenané tréningy.';

  @override
  String get noRadarFramesAvailable =>
      'Nie sú k dispozícii žiadne radarové snímky';

  @override
  String get playRadar => 'Prehrať radar';

  @override
  String get pauseRadar => 'Pozastaviť radar';

  @override
  String get high => 'Vysoký';

  @override
  String get clear => 'Jasno';

  @override
  String get bodyweight => 'Vlastná hmotnosť';

  @override
  String get resistance2 => 'Odpor —';

  @override
  String assistUnit(Object unit) {
    return 'Asistencia $unit';
  }

  @override
  String get reps2 => 'Opak. —';

  @override
  String get notRecorded => 'Nezaznamenané';

  @override
  String get skipped => 'Preskočené';

  @override
  String get health => 'Zdravie';

  @override
  String get manual => 'Ručne';

  @override
  String expandName(Object name) {
    return 'Rozbaliť $name';
  }

  @override
  String get open => 'Otvoriť';

  @override
  String get noScalePaired => 'Žiadna spárovaná váha';

  @override
  String get paired => 'Spárované';

  @override
  String get change => 'Zmeniť';

  @override
  String get noCuffPaired => 'Žiadna spárovaná manžeta';

  @override
  String get noPolarH10FoundWear =>
      'Nenašiel sa žiadny Polar H10. Nasaďte si pás, navlhčite elektródy a skontrolujte, či obe pripojenia Bluetooth nepoužíva iná aplikácia.';

  @override
  String get enterMinutesSinceTrainingEnded =>
      'Zadajte minúty od skončenia tréningu, od 0 do 1440.';

  @override
  String get timingFollowsYourWorkout =>
      'Načasovanie sa riadi vaším tréningom.';

  @override
  String get recordingStayStill => 'Záznam · zostaňte v pokoji';

  @override
  String get meanHrBpm => 'Priemerná TF · bpm';

  @override
  String get pairAPolarH10First => 'Najprv spárujte Polar H10.';

  @override
  String get around30MinutesAfterTraining =>
      'Približne 30 minút po tréningu, keď je tréning včas k dispozícii.';

  @override
  String get reminderDiagnostics => 'Diagnostika pripomienok';

  @override
  String get forecast => 'Predpoveď';

  @override
  String get enterAName => 'Zadajte názov';

  @override
  String get enterAValidAmount => 'Zadajte platné množstvo';

  @override
  String get enterAPositiveAmount => 'Zadajte kladné množstvo';

  @override
  String get maximum120GH => 'Maximum 120 g/h';

  @override
  String get carbohydrateTargetGH => 'Cieľ sacharidov g/h';

  @override
  String get fluidTargetMlH => 'Cieľ tekutín ml/h';

  @override
  String get sodiumTargetMgHNot => 'Cieľ sodíka mg/h (nie soli)';

  @override
  String get surfaceFeedingAccess => 'Povrch / prístup k občerstveniu';

  @override
  String get expectedAscentM => 'Očakávané prevýšenie m';

  @override
  String get expectedAltitudeM => 'Očakávaná nadmorská výška m';

  @override
  String get humidity => 'Vlhkosť %';

  @override
  String get windKmH => 'Vietor km/h';

  @override
  String get dayForecast => 'Predpoveď na deň';

  @override
  String get enteredConditions => 'Zadané podmienky';

  @override
  String get productFoodName => 'Názov produktu / potraviny';

  @override
  String get servingsQuantity => 'Porcie / množstvo';

  @override
  String get when => 'Kedy';

  @override
  String get carbohydrateGServing => 'Sacharidy g / porcia';

  @override
  String get fluidMlServing => 'Tekutiny ml / porcia';

  @override
  String get caffeineMgServing => 'Kofeín mg / porcia';

  @override
  String get proteinGServing => 'Bielkoviny g / porcia';

  @override
  String get gel => 'Gél';

  @override
  String get water => 'Voda';

  @override
  String get sportsDrink => 'Športový nápoj';

  @override
  String get bar => 'Tyčinka';

  @override
  String get finishIntakeLog => 'Dokončiť záznam príjmu';

  @override
  String get importing => 'Importujem…';

  @override
  String importNewreadings(Object newReadings) {
    return 'Importovať $newReadings';
  }

  @override
  String get reading => 'Čítam…';

  @override
  String get chooseReportPdf => 'Vybrať správu (PDF)';

  @override
  String get yourTrainingHistoryIsReady =>
      'Vaša tréningová história je pripravená';

  @override
  String get importingYourTrainingHistory =>
      'Importuje sa vaša tréningová história';

  @override
  String get stopImport => 'Zastaviť import';

  @override
  String get dismiss => 'Zavrieť';

  @override
  String get openai => 'OpenAI';

  @override
  String get appleIntelligence => 'Apple Intelligence';

  @override
  String get nonAiBriefing => 'Prehľad bez AI';

  @override
  String get noBriefing => 'Žiadny prehľad';

  @override
  String get ruleBasedSummaryFromYour =>
      'Súhrn založený na pravidlách z vašich zdravotných údajov – bez volaní API';

  @override
  String get hideTheBriefingCard => 'Skryť kartu prehľadu';

  @override
  String get flutter => 'Flutter';

  @override
  String get stateManagement => 'Správa stavu';

  @override
  String get bluetoothLe => 'Bluetooth LE';

  @override
  String get interactiveMaps => 'Interaktívne mapy';

  @override
  String get chartsGraphs => 'Grafy a diagramy';

  @override
  String get secureCredentialStorage =>
      'Bezpečné ukladanie prihlasovacích údajov';

  @override
  String get markdownRendering => 'Vykresľovanie Markdown';

  @override
  String get appleOnDeviceAi => 'AI od Apple v zariadení';

  @override
  String get cryptography => 'Kryptografia';

  @override
  String get appleHealthHealthConnect => 'Apple Zdravie a Health Connect';

  @override
  String get runtimePermissions => 'Povolenia za behu';

  @override
  String get shareExport => 'Zdieľanie a export';

  @override
  String get openUrls => 'Otváranie URL';

  @override
  String get internationalisation => 'Internacionalizácia';

  @override
  String get utilities => 'Pomocné nástroje';

  @override
  String get icons => 'Ikony';

  @override
  String get fjelia => 'Fjelia';

  @override
  String get fjeliaFeedback => 'Spätná väzba k Fjelia';

  @override
  String get couldNotSendTheReport =>
      'Hlásenie sa nepodarilo odoslať. Váš text tu stále je. Skúste to znova.';

  @override
  String get yourEmail => 'Váš e-mail';

  @override
  String get enterAValidEmailAddress => 'Zadajte platnú e-mailovú adresu.';

  @override
  String get subject => 'Predmet';

  @override
  String get sending => 'Odosielam…';

  @override
  String get sendReport => 'Odoslať hlásenie';

  @override
  String get sleepRecovery => 'Spánok a regenerácia';

  @override
  String get activitiesTraining => 'Aktivity a tréning';

  @override
  String get bodyWellness => 'Telo a pohoda';

  @override
  String get hilo => 'Hilo';

  @override
  String get hiloBle => 'Hilo BLE';

  @override
  String get garminApi => 'Garmin (API)';

  @override
  String get renphoScale => 'Váha Renpho';

  @override
  String get connected => 'Pripojené';

  @override
  String get notConnected => 'Nepripojené';

  @override
  String get manage => 'Spravovať';

  @override
  String get connect => 'Pripojiť';

  @override
  String get habits => 'Návyky';

  @override
  String get smokingAlcohol => 'Fajčenie, alkohol';

  @override
  String get clinicalLab => 'Laboratórne hodnoty';

  @override
  String get hba1cLipidsKidney => 'HbA1c, lipidy, obličky';

  @override
  String get sex => 'Pohlavie';

  @override
  String get smoking => 'Fajčenie';

  @override
  String get never => 'Nikdy';

  @override
  String get former => 'Bývalý';

  @override
  String get current => 'Súčasný';

  @override
  String get hba1c => 'HbA1c';

  @override
  String get diabetes => 'Cukrovka';

  @override
  String get prediabetes => 'Prediabetes';

  @override
  String get type1 => 'Typ 1';

  @override
  String get type2 => 'Typ 2';

  @override
  String get apob => 'ApoB';

  @override
  String get optionalPlansAndPaceGuides =>
      'Voliteľné. Využívajú ho plány a tempové odporúčania; tréning ovplyvňuje aj prevýšenie vyššie.';

  @override
  String get addRaceGoal2 => 'Pridať cieľ pretekov';

  @override
  String get editRaceGoal => 'Upraviť cieľ pretekov';

  @override
  String get trailRunning2 => 'Trailový beh';

  @override
  String get roadCycling => 'Cestná cyklistika';

  @override
  String get gravel => 'Gravel';

  @override
  String get indoorRowing => 'Veslovanie v interiéri';

  @override
  String get selectDate => 'Vybrať dátum';

  @override
  String get committed => 'Potvrdené';

  @override
  String get flexible => 'Flexibilné';

  @override
  String get notGoing => 'Nezúčastním sa';

  @override
  String get notSaid => 'Neuvedené';

  @override
  String get finish => 'Cieľový čas';

  @override
  String get saveGoal => 'Uložiť cieľ';

  @override
  String get exportAllRecordedWorkoutsAs =>
      'Exportovať všetky zaznamenané tréningy ako tabuľku.';

  @override
  String get backupsIncludeYourHealthData =>
      'Zálohy obsahujú vaše zdravotné údaje, tréningové plány a nastavenia profilu. Prihlasovacie údaje sú vylúčené. Obnova nahradí lokálne údaje.';

  @override
  String get trail => 'Trail';

  @override
  String get inlineSkating => 'Kolieskovanie';

  @override
  String get nordicClassic => 'Klasické bežecké lyžovanie';

  @override
  String get skateSkiing => 'Korčuľovanie na lyžiach';

  @override
  String get strength => 'Sila';

  @override
  String get walking => 'Chôdza';

  @override
  String get yoga => 'Joga';

  @override
  String get skiing => 'Lyžovanie';

  @override
  String get climbing => 'Lezenie';

  @override
  String get monday => 'Pondelok';

  @override
  String get sunday => 'Nedeľa';

  @override
  String get month => 'Mesiac';

  @override
  String get week => 'Týždeň';

  @override
  String get list => 'Zoznam';

  @override
  String get train => 'Tréning';

  @override
  String get restDay => 'Odpočinok';

  @override
  String get kilogramsKg => 'Kilogramy (kg)';

  @override
  String get poundsLb => 'Libry (lb)';

  @override
  String get regenerateWorkouts => 'Znovu vytvoriť tréningy';

  @override
  String get starting => 'Spúšťa sa';

  @override
  String get allPlannedWorkoutsDeleted =>
      'Všetky plánované tréningy boli odstránené.';

  @override
  String get searching => 'Hľadám…';

  @override
  String get searchCity => 'Hľadať mesto';

  @override
  String get fixedLocationSavedWeatherWill =>
      'Pevná poloha bola uložená. Počasie sa obnoví.';

  @override
  String get locationDisabledThePlanWeather =>
      'Poloha je vypnutá. Karta počasia v pláne je skrytá.';

  @override
  String locationSetToName(Object name) {
    return 'Poloha nastavená na $name';
  }

  @override
  String get notEnoughDaytimeAndNighttime =>
      'Nedostatok denných a nočných meraní';

  @override
  String get onlyTheWeightWasReceived =>
      'Prijatá bola iba hmotnosť. Pre telesný tuk, svaly a ďalšie hodnoty stojte naboso na kovových elektródach, kým váha neskončí.';

  @override
  String get addYourWaistInProfile =>
      'Pridajte obvod pásu v Profile pre viscerálny tuk.';

  @override
  String get manualActivity => 'Manuálna aktivita';

  @override
  String get theseCredentialsAreStoredEncrypted =>
      'Tieto prihlasovacie údaje sú uložené zašifrované vo vašom zariadení (kľúčenka iOS / Android Keystore). Nikdy sa neposielajú na iný server ako Hilo.';

  @override
  String get corosCredentialsAreStoredEncrypted =>
      'Prihlasovacie údaje Coros sú uložené zašifrované vo vašom zariadení. Fjelia číta údaje priamo z cloudového API Coros, rovnakého ako webová aplikácia Coros Training Hub.';

  @override
  String get connectAnyCombinationYouCan =>
      'Pripojte ľubovoľnú kombináciu – ďalšie môžete kedykoľvek pridať neskôr v Nastaveniach.';

  @override
  String get garminCredentialsAreStoredEncrypted =>
      'Prihlasovacie údaje Garmin sú uložené zašifrované vo vašom zariadení. Fjelia používa neoficiálne API Garmin Connect – rovnaký prístup ako mnohé komunitné aplikácie.';

  @override
  String get enterTheVerificationCode => 'Zadajte overovací kód';

  @override
  String get appleHealthDataAccess =>
      'Fjelia číta vaše zdravotné údaje z Apple Zdravie. S vaším povolením môže do Apple Zdravie aj zapisovať synchronizované údaje. Prístup spravujete v nastaveniach zariadenia.';

  @override
  String get scanAgain => 'Hľadať znova';

  @override
  String get wearTheHiloBandDuring =>
      'Noste Hilo pás počas spánku pre nepretržité zaznamenávanie krvného tlaku. Údaje sa synchronizujú automaticky každé ráno pri otvorení aplikácie.';

  @override
  String get noPolarH10FoundWear2 =>
      'Nenašiel sa žiadny Polar H10. Nasaďte si pás s navlhčenými elektródami a uistite sa, že k nemu nie je pripojená iná aplikácia (ani hodinky); potom hľadajte znova.';

  @override
  String get wearTheStrapWithMoist2 =>
      'Pred hľadaním si nasaďte pás s navlhčenými elektródami. Neskôr merajte cez + → Meranie HRV Polar H10; výsledky sa zobrazia vedľa nočného HRV.';

  @override
  String get signedInPlannedWorkoutsCan =>
      'Prihlásenie úspešné. Plánované tréningy sa teraz dajú odoslať do Polaru. Staršie tréningy sa importujú pri ďalšej úplnej synchronizácii histórie.';

  @override
  String get saveYourPolarFlowLogin =>
      'Uložte prihlásenie do Polar Flow, aby ste mohli odosielať plánované tréningy a importovať tréningy staršie ako 30 dní. Zostáva v kľúčenke tohto zariadenia a posiela sa iba do Polaru. Odošlite tréning z listu plánovača a potom synchronizujte Polar Flow s hodinkami. Skontrolujte, či sa zóny tepovej frekvencie v Polare zhodujú s Fjeliou.';

  @override
  String get signInToSendThis =>
      'Prihláste sa, aby ste mohli odoslať tento tréning do kalendára Polar Flow. Prihlásenie zostáva v kľúčenke tohto zariadenia a posiela sa iba do Polaru. Po odoslaní synchronizujte Polar Flow s hodinkami.';

  @override
  String get checkAndSave => 'Skontrolovať a uložiť';

  @override
  String get noScaleFoundStepOn =>
      'Nenašla sa žiadna váha. Postavte sa na váhu, aby sa prebudila, a hľadajte znova.';

  @override
  String get stepOnTheScaleBefore =>
      'Pred hľadaním sa postavte na váhu, aby sa prebudila. Neskôr merajte cez + → Váha RENPHO.';

  @override
  String get renphoCredentialsAreStoredEncrypted =>
      'Prihlasovacie údaje Renpho sú uložené zašifrované vo vašom zariadení. Fjelia komunikuje priamo s cloudovým API Renpho.';

  @override
  String get couldNotSendSmsCheck =>
      'SMS sa nepodarilo odoslať. Skontrolujte telefónne číslo a internetové pripojenie.';

  @override
  String get theEmailIsUsedFor =>
      'E-mail sa používa na bezpečné podpisovanie požiadaviek a neposiela sa na servery Suunto.';

  @override
  String get suuntoUsesSmsVerificationSame =>
      'Suunto používa overenie cez SMS (rovnako ako aplikácia Suunto). Na váš telefón sa pošle jednorazový PIN. Prihlasovacie údaje sú uložené zašifrované iba v zariadení.';

  @override
  String get tellUsAboutYourRace =>
      'Povedzte nám o svojich pretekoch a rozvrhu. Fjelia vytvorí plán hneď a vašu úroveň zistí z minulých aktivít (Garmin, Suunto, Polar, COROS, Apple Zdravie), keď sa stiahnu.';

  @override
  String get noAccountConnectedSoFjelia =>
      'Nie je pripojený žiadny účet, takže Fjelia nemá históriu, z ktorej by sa učila. Pripojte Garmin, Suunto, Polar, COROS alebo Apple Zdravie a rozhodne váš skutočný tréning.';

  @override
  String get yourPastActivitiesAreStill =>
      'Vaše minulé aktivity sa ešte importujú. Plán môžete vytvoriť hneď – po dokončení importu sa automaticky spresní.';

  @override
  String get buildingYourPlan => 'Vytváram váš plán…';

  @override
  String get saveContinue => 'Uložiť a pokračovať';

  @override
  String get addYourMainPriorityA =>
      'Pridajte svoje hlavné preteky (priorita A). Plán sa periodizuje smerom k nim: základ, budovanie, vrchol a zníženie záťaže. Bez cieľa pretekov sa zatiaľ plán nevytvorí.';

  @override
  String get noMeasurementsYet => 'Zatiaľ žiadne merania';

  @override
  String get date => 'Dátum';

  @override
  String deepSleepIsBelowOptimal(Object round) {
    return 'Hlboký spánok je pod optimom ($round %). Vyhnite sa alkoholu a ťažkým jedlám 3 h pred spaním.';
  }

  @override
  String get finishWithSetsOpen => 'Ukončiť s otvorenými sériami?';

  @override
  String get completeThePlannedWorkout => 'Dokončiť plánovaný tréning?';

  @override
  String get marksThePlannedSessionAs =>
      'Označí plánovaný tréning ako dokončený týmto tréningom.';

  @override
  String get discardThisWorkout => 'Zahodiť tento tréning?';

  @override
  String get removesTheWorkoutAndEvery =>
      'Odstráni tréning a každú v ňom zaznamenanú sériu.';

  @override
  String assistanceName(Object name) {
    return 'Asistencia ($name)';
  }

  @override
  String get enterSecondsOrMSs => 'Zadajte sekundy alebo m:ss.';

  @override
  String get enterTheLoadAsA => 'Zadajte záťaž ako číslo.';

  @override
  String get loadCannotBeNegative => 'Záťaž nemôže byť záporná.';

  @override
  String get enterTheEffortValue => 'Zadajte hodnotu námahy.';

  @override
  String get nameTheExercise => 'Pomenujte cvik.';

  @override
  String get atLeastOneImplement => 'Aspoň jedno náradie.';

  @override
  String get anIncrementMustBePositive => 'Prírastok musí byť kladný.';

  @override
  String get enterAPositiveStep => 'Zadajte kladný krok.';

  @override
  String get repsInReserve => 'Opakovania v rezerve';

  @override
  String get loadPerImplement => 'Záťaž na náradie';

  @override
  String get restAfterThisSet => 'Pauza po tejto sérii';

  @override
  String get enterHowLongTheSet => 'Zadajte, ako dlho séria trvala.';

  @override
  String get repsDonePerSide => 'Vykonané opakovania na stranu';

  @override
  String plannedRepminRepmax(Object repMin, Object repMax) {
    return 'Plánované $repMin–$repMax';
  }

  @override
  String get restTakenBeforeTheNext => 'Odpočinok pred ďalšou sériou';

  @override
  String get equipment => 'Vybavenie';

  @override
  String get implementsUsedTogether => 'Náradie používané spolu';

  @override
  String get smallestLoadStepOptional => 'Najmenší krok záťaže (voliteľné)';

  @override
  String get theSmallestChangeYourPlates =>
      'Najmenšia zmena, ktorú umožňujú vaše kotúče, jednoručky alebo stroj; zapamätá sa pre toto vybavenie.';

  @override
  String get loadStep => 'Krok záťaže';

  @override
  String get finishWithIncompleteData => 'Ukončiť s neúplnými údajmi?';

  @override
  String get leaveWithoutSaving => 'Odísť bez uloženia?';

  @override
  String get theLastChangeCouldNot => 'Poslednú zmenu sa nepodarilo uložiť.';

  @override
  String get comparedWithAPlanChosen =>
      'Porovnané s plánom zvoleným po tréningu. Plánované hodnoty sú orientačné, nie výsledky.';

  @override
  String get lastSet => 'Posledná séria';

  @override
  String get templateName => 'Názov šablóny';

  @override
  String get betweenExercises => 'Medzi cvikmi';

  @override
  String get betweenRounds => 'Medzi kolami';

  @override
  String get discardChanges => 'Zahodiť zmeny?';

  @override
  String get yourEditsToThisWorkout =>
      'Vaše úpravy tohto tréningu nie sú uložené.';

  @override
  String get estimatedDuration => 'Odhadované trvanie';

  @override
  String get workingSets => 'Pracovné série';

  @override
  String get estimatedExternalVolume => 'Odhadovaný vonkajší objem';

  @override
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion) {
    return 'Záťaž zvýšená z $unit na $unit2 po vašej kontrole (pravidlo v$ruleVersion).';
  }

  @override
  String get thePlannedWorkoutHasNo =>
      'Plánovaný tréning nemá žiadne cviky na zaznamenanie.';

  @override
  String get completedSets => 'Dokončené série';

  @override
  String get knownExternalVolume => 'Známy vonkajší objem';

  @override
  String get updateStrengthSessions2 => 'Aktualizovať silové tréningy?';

  @override
  String get upcomingSessionsArePlannedAgain =>
      'Nadchádzajúce tréningy sa naplánujú odznova od dnes: sila sleduje vaše ciele pretekov v každý silový deň s rôznorodými tréningmi. Dokončené a preskočené tréningy zostanú; cviky, ktoré ste zmenili v nadchádzajúcom silovom tréningu, sa nahradia.';

  @override
  String get thisSessionUsesAnEarlier =>
      'Tento tréning používa staršiu silovú šablónu. Aktualizované plány menia silu podľa fázy a cieľa pretekov a využívajú každý silový deň.';

  @override
  String get estimated1rmUsesEpleyAnd =>
      'Odhadované 1RM používa Epleyho a Brzyckého vzorec na dokončené pracovné série s 1–10 opakovaniami a známou záťažou a zobrazuje sa ako rozsah medzi nimi. Je to odhad, nie testované maximum.';

  @override
  String get localWeather => 'Miestne počasie';

  @override
  String get today => 'Dnes';

  @override
  String get low => 'Nízky';

  @override
  String get moderate => 'Mierny';

  @override
  String get overcast => 'Zamračené';

  @override
  String get partlyCloudy => 'Polooblačno';

  @override
  String collapseName(Object name) {
    return 'Zbaliť $name';
  }

  @override
  String get variableLoads => 'Premenlivé záťaže';

  @override
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  ) {
    return 'Pravidlo v$strengthProgressionRuleVersion: posledné $strengthProgressionMinSessions porovnateľné tréningy, každá séria na hornej hranici cieľa opakovaní, so zaznamenanou námahou a nie ťažšie, než bolo zamýšľané. $reason';
  }

  @override
  String get stepOnYourScaleBefore => 'Pred hľadaním sa postavte na váhu';

  @override
  String get scanning => 'Vyhľadávam…';

  @override
  String get pair => 'Spárovať';

  @override
  String get selectYourAktiiaPWristband =>
      'Vyberte svoj náramok AKTIIA P…. Ak nie je viditeľný, položte ho na nabíjačku, aby sa prebudil.';

  @override
  String get measurementInterruptedWhileTheApp =>
      'Meranie bolo prerušené, keď bola aplikácia na pozadí. Zopakujte ho.';

  @override
  String get noRecentRrDataWith =>
      'Žiadne nedávne údaje RR s dobrým kontaktom. Skontrolujte pás a zopakujte meranie.';

  @override
  String get settlingStayStill => 'Ustaľovanie · zostaňte v pokoji';

  @override
  String get deleteSpotHrvMeasurement => 'Odstrániť bodové meranie HRV?';

  @override
  String get thisRemovesTheRecordingAnd =>
      'Tým sa odstráni záznam a jeho surové intervaly RR.';

  @override
  String get appleHealthStoppedAnsweringSo =>
      'Apple Zdravie prestalo odpovedať, preto ho Fjelia odpojila a už nečíta ani nezapisuje zdravotné údaje.\n\nZnova povoľte Fjelia v Nastavenia → Zdravie → Prístup k údajom a zariadenia → Fjelia a potom znova pripojte Apple Zdravie.';

  @override
  String get thisRemovesTheSelectedGrip =>
      'Tým sa odstráni vybrané meranie sily stisku.';

  @override
  String get hideReminderDiagnostics => 'Skryť diagnostiku pripomienok';

  @override
  String get loading => 'Načítava sa…';

  @override
  String get touchTheChartForDetails =>
      'Ťuknutím na graf zobrazíte podrobnosti';

  @override
  String get indoor => 'Interiér';

  @override
  String get road => 'Cesta';

  @override
  String get technical => 'Technický';

  @override
  String get snow => 'Sneh';

  @override
  String get pool => 'Bazén';

  @override
  String get openWater => 'Otvorená voda';

  @override
  String get ambientTemperatureC => 'Okolitá teplota °C';

  @override
  String carryAboutGelsGelsGelcarbs(
    Object gels,
    Object gelCarbs,
    Object bottles,
    Object bottleMl,
    Object drinkCarbs,
  ) {
    return 'Vezmite približne $gels gélov ($gelCarbs g sacharidov každý) + $bottles × fľaše po $bottleMl ml. $drinkCarbs g sacharidov pochádza z nápojového prášku.';
  }

  @override
  String get intakeNotRecorded => 'Príjem nezaznamenaný';

  @override
  String get loggingDeclinedIntakeUnknown =>
      'Zaznamenávanie odmietnuté – príjem neznámy';

  @override
  String get confirmedNoIntake => 'Potvrdené: žiadny príjem';

  @override
  String get draft => 'Koncept · ';

  @override
  String get actualIntakePerServing => 'Skutočný príjem · na porciu';

  @override
  String get minuteIntoWorkoutDuringOnly =>
      'Minúta tréningu (iba počas, voliteľné)';

  @override
  String get sodiumMgServingNotSalt => 'Sodík mg / porcia (nie soľ)';

  @override
  String get comfortable => 'Komfortné';

  @override
  String get mildSymptoms => 'Mierne príznaky';

  @override
  String get moderateSymptoms => 'Stredné príznaky';

  @override
  String get severeSymptoms => 'Závažné príznaky';

  @override
  String get personalNutritionSettings => 'Osobné nastavenia výživy';

  @override
  String get practisedCarbohydrateToleranceGH =>
      'Natrénovaná tolerancia sacharidov g/h (do 120)';

  @override
  String get exportTheMonthlyReportAs =>
      'Exportujte mesačnú správu ako PDF v aplikácii Hilo a vyberte ju tu. Importujú sa iba merania; meno, e-mail a telesné údaje v správe sa ignorujú.';

  @override
  String get nothingNewAllReadingsWere =>
      'Nič nové: všetky merania už boli uložené.';

  @override
  String get historyImportIncomplete => 'Import histórie je neúplný';

  @override
  String get youCanKeepUsingFjelia =>
      'Fjeliu môžete ďalej používať, ale nechajte ju otvorenú: iOS pozastaví import, keď je aplikácia na pozadí, a pokračuje pri ďalšom otvorení. Váš plán sa kalibruje po dokončení importu.';

  @override
  String get addYourBirthYearIn =>
      'Pridajte rok narodenia v Nastavenia → Profil, aby ste videli svoj odhad.';

  @override
  String get fitnessAge => 'Vek kondície';

  @override
  String get estLifespan => 'Odh. dĺžka života';

  @override
  String get delta => 'Rozdiel';

  @override
  String couldNotOpenKey(Object key) {
    return 'Nepodarilo sa otvoriť $key';
  }

  @override
  String get appleIntelligenceIsNotAvailable =>
      'Apple Intelligence nie je na tomto zariadení dostupná. Použite Free AI alebo vyberte iného poskytovateľa.';

  @override
  String get personalisedMorningLunchAfternoonEvening =>
      'Personalizovaný prehľad na ráno/obed/popoludnie/večer';

  @override
  String get enterASubject => 'Zadajte predmet.';

  @override
  String get message => 'Správa';

  @override
  String get enterAMessageOfAt => 'Zadajte správu s aspoň 10 znakmi.';

  @override
  String get garminConnect => 'Garmin Connect';

  @override
  String get hiloBloodPressure => 'Hilo (krvný tlak)';

  @override
  String get renphoBodyScale => 'Renpho (osobná váha)';

  @override
  String get hiloPodCuff => 'Hilo Pod / manžeta';

  @override
  String disconnectLabel(Object label) {
    return 'Odpojiť $label?';
  }

  @override
  String get yourSavedMeasurementsWillRemain =>
      'Vaše uložené merania zostanú v tomto zariadení.';

  @override
  String get notEnoughRecentHeartRate =>
      'Nedostatok nedávnych údajov o tepovej frekvencii na úpravu zón.';

  @override
  String get aerobicBase => 'Aeróbna základňa';

  @override
  String get tempo => 'Tempo';

  @override
  String get lactateThreshold => 'Laktátový prah';

  @override
  String get birthYearHeightWaist => 'Rok narodenia, výška, pás';

  @override
  String get enterAValidValue => 'Zadajte platnú hodnotu';

  @override
  String get birthYear => 'Rok narodenia';

  @override
  String get height => 'Výška';

  @override
  String get waist => 'Pás';

  @override
  String get yearsSinceQuit => 'Roky od skončenia';

  @override
  String get cigarettesPerDay => 'Cigarety za deň';

  @override
  String get standardDrinksPerMonth => 'Štandardné nápoje za mesiac';

  @override
  String get enterAValidNumber => 'Zadajte platné číslo';

  @override
  String get enterARaceName => 'Zadajte názov pretekov';

  @override
  String get useHMmOrH =>
      'Použite h:mm alebo h:mm:ss, čas, ktorý by ste naozaj vedeli zabehnúť';

  @override
  String get flexibleThePlanMayDrop =>
      'Flexibilné: plán môže toto podujatie vynechať, ak koliduje s dôležitejším.';

  @override
  String get selectARaceDate => 'Vyberte dátum pretekov';

  @override
  String thatIsTenTimesOr(Object likely) {
    return 'Je to desaťnásobok (alebo desatina) obvyklých $likely km. Použiť namiesto toho $likely km?';
  }

  @override
  String get addGoal => 'Pridať cieľ';

  @override
  String get restoreFailed => 'Obnova zlyhala';

  @override
  String get replaceLocalData => 'Nahradiť lokálne údaje?';

  @override
  String get restoringThisBackupReplacesAll =>
      'Obnovením tejto zálohy sa nahradia všetky lokálne zdravotné a tréningové záznamy. Existujúce prihlasovacie údaje zostanú zachované.';

  @override
  String get openingBackupZip => 'Otvára sa ZIP so zálohou';

  @override
  String get addAFutureRaceGoal => 'Najprv pridajte budúci cieľ pretekov.';

  @override
  String get deleteAllWorkouts2 => 'Odstrániť všetky tréningy?';

  @override
  String get thisDeletesPlannedWorkoutsOn =>
      'Tým sa odstránia plánované tréningy v tomto telefóne a na pripojenej platforme hodiniek. Dokončené aktivity zostanú.';

  @override
  String get regenerateWorkouts2 => 'Znovu vytvoriť tréningy?';

  @override
  String get noRaceGoalsYetAdd =>
      'Zatiaľ žiadne ciele pretekov. Pridajte jeden alebo synchronizujte z Garminu.';

  @override
  String get deleteRaceGoal => 'Odstrániť cieľ pretekov?';

  @override
  String deletingFailedFailure(Object failure) {
    return 'Odstránenie zlyhalo: $failure';
  }

  @override
  String allPlannedWorkoutsDeletedRemoved(Object removed) {
    return 'Všetky plánované tréningy boli odstránené. Odstránené z vašich platforiem: $removed.';
  }

  @override
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return 'Používa sa aktuálna poloha: $toStringAsFixed, $toStringAsFixed2';
  }

  @override
  String get typeSleep => 'Spánok';

  @override
  String get typeBloodPressure => 'Krvný tlak';

  @override
  String get addHiloBpReportPdf => 'Pridať správu o tlaku Hilo (PDF)';

  @override
  String get hiloCuffBle => 'Manžeta Hilo (BLE)';

  @override
  String get typeSpo2 => 'SpO₂ / pulzný oxymeter';

  @override
  String get typeWeightScale => 'Osobná váha';

  @override
  String get polarH10HrvMeasurement => 'Meranie HRV Polar H10';

  @override
  String samplingWouldStartMinutes(Object minutes) {
    return 'Meranie by sa začalo približne $minutes min po skončení tréningu.';
  }

  @override
  String samplingStartedMinutes(Object minutes) {
    return 'Meranie sa začalo $minutes min po skončení tréningu.';
  }

  @override
  String get unknown => 'Neznáme';

  @override
  String get before => 'Pred';

  @override
  String get during => 'Počas';

  @override
  String get after => 'Po';

  @override
  String get enumWarmUp => 'Rozcvičenie';

  @override
  String get enumWorking => 'Pracovná';

  @override
  String get enumBackOff => 'Back-off';

  @override
  String get enumTechnique => 'Technika';

  @override
  String get enumExternalLoad => 'Vonkajšia záťaž';

  @override
  String get enumBandResistance => 'Guma / odpor';

  @override
  String get enumTotalLoad => 'Celková záťaž';

  @override
  String get enumPerImplement => 'Na náradie';

  @override
  String get enumOneImplement => 'Jedno náradie';

  @override
  String get enumBothSides => 'Obe strany';

  @override
  String get enumAlternatingTotalReps => 'Striedavo, celkový počet opakovaní';

  @override
  String get enumPartial => 'Čiastočne';

  @override
  String get enumFailed => 'Nepodarilo sa';

  @override
  String get enumStraightSets => 'Klasické série';

  @override
  String get enumSuperset => 'Superséria';

  @override
  String get enumCircuit => 'Okruh';

  @override
  String get enumRir => 'RIR';

  @override
  String get enumRpe110 => 'RPE 1–10';

  @override
  String get enumBeforeTraining => 'Pred tréningom';

  @override
  String get enumAfterTraining => 'Po tréningu';

  @override
  String get enumResting => 'V pokoji';

  @override
  String get enumSeated => 'Sediačky';

  @override
  String get enumLyingDown => 'Ležiačky';

  @override
  String get duringRoutineGelsAreNot =>
      'Počas: pravidelné géle nie sú pri tomto krátkom/ľahkom tréningu potrebné. Pite podľa smädu.';

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      'Počas: rozložte sacharidy a nápoje do malých, pravidelných dávok. Sacharidy z nápoja počítajte do rovnakého súčtu ako géle a jedlo.';

  @override
  String get fluidIsAnEditableStarting =>
      'Tekutiny sú upraviteľný východiskový odhad, nie kvóta. Riaďte sa smädom, zvyknutým príjmom a nameranými stratami potu; nenúťte sa piť viac vody.';

  @override
  String get afterHaveCarbohydrateAndA =>
      'Po: dajte si sacharidy a jedlo s bielkovinami. Uprednostnite doplnenie energie a tekutín, ak sa blíži ďalší tréning.';

  @override
  String get swimmingPlaceALabelledBottle =>
      'Plávanie: položte označenú fľašu na okraj bazéna a využite prestávky medzi sériami na dúšky alebo občerstvenie. Podmienky v bazéne sa môžu líšiť od vonkajšieho počasia.';

  @override
  String get runningCarryAccessibleGelsFlasks =>
      'Beh: noste so sebou ľahko dostupné géle/fľaše alebo plánujte občerstvenie na stanovištiach; pred pretekmi si vyskúšajte rovnaké produkty a načasovanie.';

  @override
  String get servingSizesAndToleranceMust =>
      'Veľkosti porcií a tolerancia musia byť kladné.';

  @override
  String get enterFiniteNonNegativeMeasurements =>
      'Zadajte konečné, nezáporné merania.';

  @override
  String get targetsMustBeFiniteAnd => 'Ciele musia byť konečné a nezáporné.';

  @override
  String get conditionsMustBeFiniteOr =>
      'Podmienky musia byť konečné alebo neznáme.';

  @override
  String get humidityMustBeBetween0 => 'Vlhkosť musí byť medzi 0 a 100 %.';

  @override
  String get noIntakeCannotIncludeFood =>
      '„Žiadny príjem“ nemôže zahŕňať jedlo ani nápoje.';

  @override
  String get addAnItemOrConfirm =>
      'Pridajte položku alebo potvrďte, že ste nič neskonzumovali.';

  @override
  String get eachIntakeNeedsAProduct =>
      'Každý príjem vyžaduje produkt a platné načasovanie.';

  @override
  String get quantityMustBePositive => 'Množstvo musí byť kladné.';

  @override
  String get thisActivityNoLongerExists => 'Táto aktivita už neexistuje.';

  @override
  String get practisedCarbohydrateToleranceMustNot =>
      'Natrénovaná tolerancia sacharidov nesmie presiahnuť 120 g/h.';

  @override
  String get measuredSweatRateMustBe =>
      'Nameraná rýchlosť potenia musí byť kladná alebo ponechaná neznáma.';

  @override
  String get increasePractisedToleranceInNutrition =>
      'Pred výberom vyššieho cieľa zvýšte natrénovanú toleranciu v nastaveniach výživy.';

  @override
  String get fluidTargetExceedsYourMeasured =>
      'Cieľ tekutín presahuje vašu nameranú rýchlosť potenia. Skontrolujte meranie alebo cieľ.';

  @override
  String get elapsedWorkoutTimeMustBe =>
      'Uplynutý čas tréningu musí byť kladný alebo prázdny.';

  @override
  String get intakeAmountsMustBeFinite =>
      'Množstvá príjmu musia byť konečné a nezáporné.';

  @override
  String get selectedStrategyUnavailableChooseAnother =>
      'Vybraná stratégia nie je k dispozícii. Vyberte inú stratégiu alebo žiadne porovnanie.';

  @override
  String get recordYourWorkoutNutrition => 'Zaznamenajte výživu z tréningu';

  @override
  String get addTheFoodAndFluids =>
      'Pridajte jedlo a tekutiny, ktoré ste skutočne skonzumovali, do histórie aktivity.';

  @override
  String get logIntake => 'Zaznamenať príjem';

  @override
  String get in30Minutes => 'Za 30 minút';

  @override
  String get loadSuggestionsCoverStraightSets =>
      'Návrhy záťaže pokrývajú iba klasické série s opakovaniami.';

  @override
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  ) {
    return 'Vyžaduje $strengthProgressionMinSessions zaznamenané tréningy tohto cviku.';
  }

  @override
  String get recentHistoryIsTooOld =>
      'Nedávna história je príliš stará na návrh.';

  @override
  String get theLastSessionDidNot =>
      'Posledný tréning nepoužil jednu známu záťaž.';

  @override
  String get theLoadChangedBetweenThe =>
      'Záťaž sa medzi nedávnymi tréningmi zmenila.';

  @override
  String get notEverySetReachedThe =>
      'Nie každá séria dosiahla horný limit cieľa opakovaní.';

  @override
  String get recordEffortRirOrRpe =>
      'Zaznamenajte námahu (RIR alebo RPE) v poslednej sérii, aby ste dostali návrhy.';

  @override
  String get recentSetsWereHarderThan =>
      'Nedávne série boli ťažšie, než sa zamýšľalo.';

  @override
  String get thisWorkoutAlreadyHasIts =>
      'Tento tréning už má vlastnú záťaž; zostáva podľa nastavenia.';

  @override
  String get yourRecentSetsMetThe =>
      'Vaše nedávne série splnili pravidlo progresie. Nastavte najmenší krok záťaže pre toto vybavenie a skontrolujte záťaž.';

  @override
  String get thisWorkoutNoLongerExists => 'Tento tréning už neexistuje.';

  @override
  String thisStrengthPlanCannotBe(Object message) {
    return 'Tento silový plán sa nedá prečítať ($message).';
  }

  @override
  String get thisStrengthPlanCannotBe2 => 'Tento silový plán sa nedá prečítať.';

  @override
  String get addAtLeastOneExercise => 'Pridajte aspoň jeden cvik.';

  @override
  String get thisWorkoutWasChangedElsewhere =>
      'Tento tréning bol zmenený inde. Vaše úpravy sú zachované; načítajte znova, aby ste videli novšiu verziu.';

  @override
  String get thePlanThisWorkoutIs =>
      'Plán, s ktorým sa tento tréning porovnáva, sa nedá prečítať.';

  @override
  String get thisLogWasChangedElsewhere =>
      'Tento záznam bol zmenený inde. Vaše záznamy sú zachované; načítajte znova, aby ste videli novšiu verziu.';

  @override
  String get thisZipIsNotA => 'Tento ZIP nie je podporovaná záloha Fjelia.';

  @override
  String get theBackupDatabaseIsDamaged => 'Databáza zálohy je poškodená.';

  @override
  String get invalidBackupData => 'Neplatné údaje zálohy.';

  @override
  String get backupTablesDoNotMatch => 'Tabuľky zálohy sa nezhodujú.';

  @override
  String get invalidBackupColumns => 'Neplatné stĺpce zálohy.';

  @override
  String get migratingOriginalAppBackup =>
      'Migruje sa záloha pôvodnej aplikácie';

  @override
  String get theOriginalBackupIsMissing =>
      'V pôvodnej zálohe chýbajú požadované tabuľky.';

  @override
  String get backupFormatOrDatabaseVersion =>
      'Formát zálohy alebo verzia databázy sa nezhoduje.';

  @override
  String get restoringRecords => 'Obnovujú sa záznamy';

  @override
  String get restoringSettings => 'Obnovujú sa nastavenia';

  @override
  String get restoreComplete => 'Obnova dokončená';

  @override
  String get effortMustBeANumber => 'Námaha musí byť číslo.';

  @override
  String get theDurationEstimateMustBe => 'Odhad trvania musí byť kladný.';

  @override
  String get restCannotBeNegative => 'Odpočinok nemôže byť záporný.';

  @override
  String get enterTheRepetitionsDoneThe =>
      'Zadajte vykonané opakovania; plán má rozsah.';

  @override
  String get enterTheLoadThePlan => 'Zadajte záťaž; plán žiadnu nemá.';

  @override
  String get enterTheResistanceThePlan => 'Zadajte odpor; plán žiadny nemá.';

  @override
  String get poorSensorContact => 'Slabý kontakt senzora';

  @override
  String get moreThan25FromLocal => 'Viac ako 25 % od lokálneho mediánu';

  @override
  String get workoutNutrition => 'Výživa pri tréningu';

  @override
  String get postWorkoutFoodAndFluid =>
      'Pripomienka záznamu jedla a tekutín po tréningu';

  @override
  String get postTrainingHrvMeasurementReminder =>
      'Pripomienka merania HRV po tréningu';

  @override
  String get rirRunsFrom0To => 'RIR sa pohybuje od 0 do 10+.';

  @override
  String get rpeRunsFrom1To => 'RPE sa pohybuje od 1 do 10.';

  @override
  String get repetitionsCannotBeNegative => 'Opakovania nemôžu byť záporné.';

  @override
  String get timedWorkMustBeLonger =>
      'Časovaná práca musí trvať dlhšie ako nula sekúnd.';

  @override
  String get chooseRepetitionsOrTimedWork =>
      'Vyberte opakovania alebo časovanú prácu, nie oboje.';

  @override
  String get loadMustBeAFinite => 'Záťaž musí byť konečné, nezáporné číslo.';

  @override
  String get durationCannotBeNegative => 'Trvanie nemôže byť záporné.';

  @override
  String get hrTimeline => 'Priebeh TF';

  @override
  String get dayTrainingLoad => 'Denná tréningová záťaž';

  @override
  String get weekdayComparison => 'Porovnanie dní v týždni';

  @override
  String get weeklyTrainingLoad => 'Týždenná tréningová záťaž';

  @override
  String get zonePolarization => 'Polarizácia zón';

  @override
  String get elevationOverview => 'Prehľad prevýšenia';

  @override
  String get trainingMonitor => 'Tréningový monitor';

  @override
  String get formAtlCtlTsb => 'Forma ATL / CTL / TSB';

  @override
  String get trainingPlanProgress => 'Postup tréningového plánu';

  @override
  String get rhrSleep => 'Pokojová TF v spánku';

  @override
  String get hrvSleep => 'HRV v spánku';

  @override
  String get spo2Sleep => 'SpO₂ v spánku';

  @override
  String get respRate => 'Dychová frekvencia';

  @override
  String get stress => 'Stres';

  @override
  String get skinTemp => 'Teplota pokožky';

  @override
  String get steps => 'Kroky';

  @override
  String get tonightsSleep => 'Dnešný spánok';

  @override
  String get activityLog => 'Záznam aktivít';

  @override
  String get activityLog2 => 'Záznam aktivít';

  @override
  String get history2 => 'HISTÓRIA';

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
  String get heatAcclimation2 => 'AKLIMATIZÁCIA NA TEPLO';

  @override
  String score(Object score) {
    return '$score%';
  }

  @override
  String get elevation => 'PREVÝŠENIE';

  @override
  String get t12WeekHistory => '12-TÝŽDŇOVÁ HISTÓRIA';

  @override
  String get zonePolarization2 => 'POLARIZÁCIA ZÓN';

  @override
  String get t5WeekHistory => '5-TÝŽDŇOVÁ HISTÓRIA';

  @override
  String get easy => 'ĽAHKÉ %';

  @override
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded) {
    return '$withZones z $recorded aktivít s údajmi o zónach TF';
  }

  @override
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples) {
    return '$fromSamples zrekonštruovaných zo zaznamenaných vzoriek TF';
  }

  @override
  String get easyZ12ModerateZ3 => 'Ľahké: Z1–2 · Mierne: Z3 · Ťažké: Z4–5';

  @override
  String get activitiesWithoutHrZoneData =>
      'Aktivity bez údajov o zónach TF sú z percent vylúčené.';

  @override
  String avgAverageUnit(Object average, Object unit) {
    return 'PRIEM $average $unit';
  }

  @override
  String get weekdayComparison2 => 'POROVNANIE DNÍ V TÝŽDNI';

  @override
  String get trainingPlanProgress2 => 'POSTUP TRÉNINGOVÉHO PLÁNU';

  @override
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  ) {
    return 'Týždeň $currentWeek / $durationInWeeks';
  }

  @override
  String get t30MinTimeTrialLt2 => '30-MINÚTOVÝ ČASOVKA – LT2';

  @override
  String get run30MinutesAtThe =>
      'Bežte 30 minút na najvyššej udržateľnej námahe – kontrolovane, nie šprintom. Do námahy sa nabiehajte; nezačínajte príliš rýchlo. Priemerné tempo a TF posledných 20 minút sú vaše LT2.';

  @override
  String get recordAsANormalOutdoor =>
      'Zaznamenajte ako bežný beh vonku. Spustite hodinky, poznačte si čas a bežte 30 min v pretekárskom úsilí.';

  @override
  String get t50MinTotalFlatCourse =>
      '~50 min celkom · rovinatá trať · nie po ťažkom tréningu';

  @override
  String get doNotStartTooFast =>
      'Nezačínajte príliš rýchlo. Snažte sa o rovnomerné medzičasy.';

  @override
  String get theAppAveragesHrAnd =>
      'Aplikácia spriemeruje TF a tempo za posledných 20 minút testu, po rozcvičke a prvých 10 minútach. Zaznamenanú aktivitu vyberte v časti Vypočítať.';

  @override
  String get lt2Pace => 'TEMPO LT2';

  @override
  String get activityRunningEnoughTimeFor =>
      'Aktivita (beh, dosť času na rozcvičku + 30 min, s TF)';

  @override
  String get selectTheTtActivity => 'Vyberte aktivitu testu';

  @override
  String nameStartdate(Object name, Object startDate) {
    return '$name · $startDate';
  }

  @override
  String get warmUpBeforeTt => 'Rozcvička pred testom';

  @override
  String roundMin(Object round) {
    return '$round min';
  }

  @override
  String get clearResults => 'Vymazať výsledky';

  @override
  String get heartRate2 => 'TEPOVÁ FREKVENCIA';

  @override
  String get paceSecKmLowerIs => 'Tempo (s/km – nižšie je rýchlejšie)';

  @override
  String get thresholdsFitnessTests => 'Prahy a testy kondície';

  @override
  String get lt1 => 'LT1';

  @override
  String get lt2 => 'LT2';

  @override
  String get voPace => 'Tempo VO₂';

  @override
  String get ftp => 'FTP';

  @override
  String get setFtpManually => 'Nastaviť FTP ručne';

  @override
  String get calculateFromAnActivity => 'Vypočítať z aktivity';

  @override
  String get setFtp => 'Nastaviť FTP';

  @override
  String get ftpWatts => 'FTP (watty)';

  @override
  String get ftpCyclingThresholdPower => 'FTP – PRAHOVÝ VÝKON V CYKLISTIKE';

  @override
  String get ftpHistory => 'HISTÓRIA FTP';

  @override
  String get updateFromActivity => 'AKTUALIZOVAŤ Z AKTIVITY';

  @override
  String get tapAnActivityFtpBest =>
      'Ťuknite na aktivitu – FTP = najlepší 20-min výkon × 0,95';

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
      'Žiadne jazdy s 20 minútami nepretržitých údajov o výkone.';

  @override
  String get enterFtpManually => 'Zadať FTP ručne';

  @override
  String get selectTheTestActivity => 'Vyberte aktivitu testu';

  @override
  String get formAtlCtlTsb2 => 'FORMA · ATL / CTL / TSB';

  @override
  String get closeTrainingFormFullscreen =>
      'Zavrieť formu tréningu na celú obrazovku';

  @override
  String get expandTrainingForm => 'Rozbaliť formu tréningu';

  @override
  String get calculatedFromTheFirstAvailable =>
      'Vypočítané od prvého dostupného záznamu záťaže. Dni bez zaznamenanej záťaže sa počítajú ako nula; skorší tréning nie je známy.';

  @override
  String get trainingMonitor2 => 'TRÉNINGOVÝ MONITOR';

  @override
  String get pfitzingerZones => 'ZÓNY PODĽA PFITZINGERA';

  @override
  String get cyclingPowerZones => 'VÝKONNOSTNÉ ZÓNY V CYKLISTIKE';

  @override
  String znumber(Object number) {
    return 'Z$number';
  }

  @override
  String paceHrDescription(Object pace, Object hr, Object description) {
    return '$pace · $hr\n$description';
  }

  @override
  String get weeklyTrainingLoad2 => 'TÝŽDENNÁ TRÉNINGOVÁ ZÁŤAŽ';

  @override
  String get prevWeek => 'MIN. TÝŽDEŇ';

  @override
  String get bySport => 'PODĽA ŠPORTU';

  @override
  String get noActivitiesThisWeek => 'Tento týždeň žiadne aktivity';

  @override
  String garminWorkoutScheduleddate(Object scheduledDate) {
    return 'Tréning Garmin · $scheduledDate';
  }

  @override
  String get yourNote => 'Vaša poznámka';

  @override
  String get askAiCoach => 'Opýtať sa AI trénera';

  @override
  String get aiSettings => 'Nastavenia AI';

  @override
  String get askYourCoach => 'Opýtajte sa trénera…';

  @override
  String get sendMessage => 'Odoslať správu';

  @override
  String get sendFeedbackOrReportA =>
      'Odoslať spätnú väzbu alebo nahlásiť chybu';

  @override
  String get addMeasurement2 => 'Pridať meranie';

  @override
  String get syncLabel2 => 'Synchronizovať';

  @override
  String get syncToday => 'Synchronizovať dnes';

  @override
  String get fullSync1Year => 'Úplná synchronizácia · 1 rok';

  @override
  String get fullSyncComplete => 'Úplná synchronizácia · Dokončená';

  @override
  String get syncingYourData => 'Synchronizujú sa vaše údaje…';

  @override
  String lLeftkgRRightkgKg2(Object leftKg, Object rightKg) {
    return 'Ľ $leftKg  P $rightKg kg';
  }

  @override
  String weightKgFatBodyfatMuscle(
    Object weight,
    Object bodyFat,
    Object muscleMass,
  ) {
    return '$weight kg · Tuk $bodyFat % · Svaly $muscleMass kg';
  }

  @override
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase) {
    return '$title, $sport, $toLowerCase';
  }

  @override
  String get weatherUnavailableTapToRetry =>
      'Počasie nedostupné · Ťuknutím skúsite znova';

  @override
  String get weatherSetYourLocation => 'Počasie · Nastavte svoju polohu';

  @override
  String get t7DayForecast => '7-DŇOVÁ PREDPOVEĎ';

  @override
  String get minMax => 'min/max';

  @override
  String get rainMm2 => 'dážď mm';

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
    return 'Ciele pretekov · $length';
  }

  @override
  String gWk(Object g) {
    return '$g týž.';
  }

  @override
  String weeks(Object weeks) {
    return '$weeks';
  }

  @override
  String get weeks2 => 'týždne';

  @override
  String get upcoming => 'NADCHÁDZAJÚCE';

  @override
  String lengthMoreDays(Object length) {
    return '+ ďalších $length dní';
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
      '○ Plánované   ● Dokončené   ✕ Preskočené';

  @override
  String get heartRate3 => 'Tepová frekvencia';

  @override
  String get watts => 'Watty';

  @override
  String theStepsAddUpTo(Object total, Object plannedDurationMin) {
    return 'Kroky dávajú dokopy $total; plán počíta $plannedDurationMin min.';
  }

  @override
  String get typicalSplitForThisKind =>
      'Typické rozdelenie pre tento druh tréningu; nie sú kroky, z ktorých by sa dalo vypočítať.';

  @override
  String labelGetsEachExerciseWith(Object label) {
    return '$label dostane každý cvik so sériami, opakovaniami a záťažou. Rozsahy opakovaní, námaha a tempo zostávajú vo Fjelii.';
  }

  @override
  String get markAsRest => 'Označiť ako odpočinok';

  @override
  String get restoreWorkout => 'Obnoviť tréning';

  @override
  String get skipThisWorkout => 'Preskočiť tento tréning?';

  @override
  String get previousWeek => 'Predchádzajúci týždeň';

  @override
  String get backToThisWeek => 'Späť na tento týždeň';

  @override
  String get thisWeek => 'Tento týždeň';

  @override
  String get nextWeek => 'Nasledujúci týždeň';

  @override
  String get today2 => 'DNES';

  @override
  String get route => 'TRASA';

  @override
  String get feedback => 'Spätná väzba';

  @override
  String get plannedWorkout => 'Plánovaný tréning';

  @override
  String get delete => 'Odstrániť';

  @override
  String get chatAi => 'AI chat';

  @override
  String get trainingLoad => 'Tréningová záťaž';

  @override
  String get dayTrainingLoad2 => 'DENNÁ TRÉNINGOVÁ ZÁŤAŽ';

  @override
  String get trimp => ' TRIMP';

  @override
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter) {
    return '$scoreBefore → $scoreAfter';
  }

  @override
  String get temperatureOverTime => 'TEPLOTA V ČASE';

  @override
  String roundh(Object round) {
    return '${round}h';
  }

  @override
  String get timeInHrZones => 'Čas v zónach TF';

  @override
  String get route2 => 'Trasa';

  @override
  String get start => 'Štart';

  @override
  String get gpx => 'GPX';

  @override
  String touppercasesubstringBriefing(Object toUpperCase, Object substring) {
    return 'Prehľad: $toUpperCase$substring';
  }

  @override
  String get chatWithAiAboutThis => 'Chatovať s AI o tomto prehľade';

  @override
  String get whyThisRecommendation => 'Prečo toto odporúčanie?';

  @override
  String titleDateLabel(Object title, Object date, Object label) {
    return '$title, $date, $label';
  }

  @override
  String get previousDay => 'Predchádzajúci deň';

  @override
  String get nextDay => 'Nasledujúci deň';

  @override
  String get updating => 'Aktualizuje sa';

  @override
  String get resting => 'V POKOJI';

  @override
  String get noTimedReadings => 'Žiadne časované merania';

  @override
  String get avg => 'PRIEM';

  @override
  String get peak => 'VRCHOL';

  @override
  String tolocalRoundmin(Object toLocal, Object round) {
    return '$toLocal · ${round}min';
  }

  @override
  String avgheartrateBpmAvg(Object avgHeartRate) {
    return '$avgHeartRate bpm priem.';
  }

  @override
  String get timeWeightedAverageOverRecorded =>
      'Časovo vážený priemer za zaznamenané obdobia. Medzery bez meraní sú vylúčené.';

  @override
  String get previousHeartRatePeriod =>
      'Predchádzajúce obdobie tepovej frekvencie';

  @override
  String get nextHeartRatePeriod => 'Nasledujúce obdobie tepovej frekvencie';

  @override
  String get avgHr => 'Priem. TF';

  @override
  String get restingHr => 'Pokojová TF';

  @override
  String get both => 'Obe';

  @override
  String averagelabelFixedMs(Object averageLabel, Object fixed) {
    return '$averageLabel $fixed ms';
  }

  @override
  String get measureWithPolarH10 => 'Merať s Polar H10';

  @override
  String get ms => 'ms';

  @override
  String get noWorkoutInThisPeriod =>
      'Žiadny tréning v tomto období nemá porovnateľný pár pred/po.';

  @override
  String textEachWorkoutCountsOnce(Object text) {
    return '$text. Každý tréning sa počíta raz; opisuje to vaše páry, nehodnotí ich.';
  }

  @override
  String get workoutFinished => 'Tréning skončil?';

  @override
  String get yourWorkoutIsNotIn =>
      'Váš tréning ešte nie je vo Fjelii. Ak skončil, uveďte kedy a pripomienka sa môže riadiť skutočným koncom. Inak sa zobrazí po synchronizácii hodiniek.';

  @override
  String get workoutFinished2 => 'Tréning skončil';

  @override
  String get theWorkoutMustStartAfter =>
      'Tréning musí začať po meraní a skončiť po svojom začiatku, nie v budúcnosti.';

  @override
  String daysDAvg(Object days) {
    return '$days D priem.';
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
  String get previousPeriod => 'Predchádzajúce obdobie';

  @override
  String get nextPeriod => 'Nasledujúce obdobie';

  @override
  String get overnightHrvReflectsRecoveryCompare =>
      'Nočné HRV odráža regeneráciu. Porovnávajte svoje hodnoty s vlastnou základnou v čase.';

  @override
  String get moveThisWorkout => 'PRESUNÚŤ TENTO TRÉNING';

  @override
  String get pickDate => 'Vybrať dátum';

  @override
  String movedFromMovedfrom(Object movedFrom) {
    return 'Presunuté z $movedFrom';
  }

  @override
  String get hrvAroundThisWorkout => 'HRV okolo tohto tréningu';

  @override
  String get measureAfterTraining => 'Merať po tréningu';

  @override
  String get measureAgain => 'Merať znova';

  @override
  String get explainWithAi => 'Vysvetliť pomocou AI';

  @override
  String beforeEndedPregapAheadOf(Object preGap) {
    return 'Pred skončilo $preGap pred začiatkom.';
  }

  @override
  String lengthFurtherMeasurementSAfter(Object length) {
    return '$length ďalších meraní po tomto tréningu sa ponecháva ako dodatočné pozorovania.';
  }

  @override
  String get noHrvMeasurementRecordedAround =>
      'Okolo tohto tréningu nebolo zaznamenané žiadne meranie HRV.';

  @override
  String get measureHrv => 'Merať HRV';

  @override
  String deltamsMs(Object deltaMs) {
    return '$deltaMs ms';
  }

  @override
  String deltapercent(Object deltaPercent) {
    return '$deltaPercent %';
  }

  @override
  String get aDescriptionOfThisPair => 'Opis tohto páru, nie skóre tréningu.';

  @override
  String notEnoughComparableWorkoutsYet(Object eligible, Object need) {
    return 'Zatiaľ nedostatok porovnateľných tréningov, $eligible z $need.';
  }

  @override
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need) {
    return 'Zatiaľ nedostatok porovnateľných tréningov ($eligible z $need).';
  }

  @override
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  ) {
    return 'Vaše $eligible podobné tréningy · $toLocal–$toLocal2';
  }

  @override
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  ) {
    return 'Stredná polovica $q1Ms až $q3Ms ms · medián $medianMs ms · tento tréning $delta ms';
  }

  @override
  String rpeI(Object i) {
    return 'RPE $i';
  }

  @override
  String get easy2 => 'ľahké';

  @override
  String get allOut => 'Naplno';

  @override
  String workoutProfileDescription(Object description) {
    return 'Profil tréningu: $description';
  }

  @override
  String get noActivitiesInThisPeriod => 'V tomto období žiadne aktivity';

  @override
  String get enableHeatAcclimationInTraining =>
      'Zapnite aklimatizáciu na teplo v nastaveniach tréningu.';

  @override
  String get noElevationThisWeek => 'Tento týždeň žiadne prevýšenie';

  @override
  String get noActivitiesSynced => 'Žiadne synchronizované aktivity';

  @override
  String get noHrZoneData => 'Žiadne údaje o zónach TF';

  @override
  String get easyJogGetHrElevated => 'Ľahký klus – zvýšte TF, uvoľnené nohy';

  @override
  String get fastestSustainablePaceLikeA =>
      'Najrýchlejšie udržateľné tempo – ako 30-minútové preteky';

  @override
  String get walkCardiacRecovery => 'Chôdza – srdcová regenerácia';

  @override
  String get selectTheTtActivityFirst => 'Najprv vyberte aktivitu testu.';

  @override
  String get calculating => 'Počíta sa…';

  @override
  String get calculateLt2 => 'Vypočítať LT2';

  @override
  String get enterFtpBetween30And => 'Zadajte FTP medzi 30 a 1000 W.';

  @override
  String get aerobicThreshold => 'Aeróbny prah';

  @override
  String get functionalThresholdPower => 'Funkčný prahový výkon';

  @override
  String get estimated => 'Odhadované';

  @override
  String get afterWarmingUpRunFive =>
      'Po rozcvičke bežte päť minút na najrýchlejšej udržateľnej námahe. Zaznamenajte beh s údajmi o rýchlosti alebo vzdialenosti.';

  @override
  String get recordAtLeast40Minutes =>
      'Zaznamenajte aspoň 40 minút rovnomerného behu pri stálej námahe. Test porovnáva tepovú frekvenciu v každej polovici na odhad aeróbneho driftu.';

  @override
  String get theFastestFiveMinuteWindow =>
      'Najrýchlejšie päťminútové okno poskytuje vaše tempo VO2max.';

  @override
  String get noResultYet => 'Zatiaľ žiadny výsledok';

  @override
  String get calculateVo2maxPace => 'Vypočítať tempo VO2max';

  @override
  String get calculateLt1 => 'Vypočítať LT1';

  @override
  String get loading2 => 'Načítava sa';

  @override
  String get unavailable => 'Nedostupné';

  @override
  String get noTrainingHistory => 'Žiadna tréningová história';

  @override
  String get fitnessCtl => 'Kondícia (CTL)';

  @override
  String get fatigueAtl => 'Únava (ATL)';

  @override
  String get formTsb => 'Forma (TSB)';

  @override
  String get noHistory => 'Žiadna história';

  @override
  String get fresh => 'Svieži';

  @override
  String get optimal => 'Optimálne';

  @override
  String get neutral => 'Neutrálne';

  @override
  String get tired => 'Unavený';

  @override
  String get veryFatigued => 'Veľmi unavený';

  @override
  String get garminRunningVo2max => 'Garmin VO2max beh';

  @override
  String get garminCyclingVo2max => 'Garmin VO2max cyklistika';

  @override
  String get aerobicThreshold2 => 'Aeróbny prah';

  @override
  String driftDriftAt(Object drift, Object at) {
    return 'Drift $drift % · $at';
  }

  @override
  String get activityHours => 'Hodiny aktivity';

  @override
  String get activityKm => 'Km aktivity';

  @override
  String get tap5MinuteMaxTest => 'Ťuknite · 5-min maximálny test';

  @override
  String get setFtpToCalculatePower =>
      'Nastavte FTP na výpočet výkonnostných zón';

  @override
  String get cyclingPowerZones2 => 'Výkonnostné zóny v cyklistike';

  @override
  String get pfitzingerZones2 => 'Zóny podľa Pfitzingera';

  @override
  String get completeAnLt2TestTo =>
      'Dokončite test LT2 na výpočet bežeckých zón.';

  @override
  String get setFtpToCalculatePower2 =>
      'Nastavte FTP na výpočet výkonnostných zón.';

  @override
  String get endurance => 'Vytrvalosť';

  @override
  String get threshold => 'Prah';

  @override
  String get anaerobic => 'Anaeróbne';

  @override
  String get whatExplainsThisRise => 'Čo vysvetľuje tento nárast?';

  @override
  String get whatExplainsThisDrop => 'Čo vysvetľuje tento pokles';

  @override
  String get whatExplainsThisRise2 => 'Čo vysvetľuje tento nárast';

  @override
  String get editsAreKeptInFjelia =>
      'Úpravy sa uchovávajú vo Fjelii ako lokálna kópia pre tento dátum. Tréning v Garmine sa nemení.';

  @override
  String get howDoIExecuteThis => 'Ako tento tréning vykonám?';

  @override
  String shareHealthContextWithName(Object name) {
    return 'Zdieľať zdravotný kontext s $name?';
  }

  @override
  String get yourMessageAndAHealth =>
      'Vaša správa a súhrn zdravia/tréningu sa odošlú tomuto cloudovému poskytovateľovi AI. Mená a GPS sú z vytvoreného súhrnu vylúčené.';

  @override
  String get couldNotGetAReply =>
      'Nepodarilo sa získať odpoveď. Skontrolujte nastavenia AI a skúste to znova.';

  @override
  String get askAboutYourRecoveryTraining =>
      'Opýtajte sa na regeneráciu, tréning alebo dnešný plán.';

  @override
  String get noSyncYet => 'Zatiaľ nesynchronizované';

  @override
  String lastSyncLastContext(Object last, Object context) {
    return 'Posledná synchronizácia: $last $context';
  }

  @override
  String get seasonWithTradeOffs => 'Sezóna: s kompromismi';

  @override
  String get seasonNeedsYourDecision => 'Sezóna: potrebuje vaše rozhodnutie';

  @override
  String get seasonCannotBeCombined => 'Sezóna: nedá sa skombinovať';

  @override
  String get seasonProvisional => 'Sezóna: predbežná';

  @override
  String get season => 'Sezóna';

  @override
  String get allGoalsFit => 'Všetky ciele sa zmestia.';

  @override
  String goalTargetfinishsecondsgoal(Object targetFinishSeconds, Object goal) {
    return 'Cieľ $targetFinishSeconds$goal';
  }

  @override
  String estEstimateestimate2(Object estimate, Object estimate2) {
    return 'Odh. $estimate$estimate2';
  }

  @override
  String doneDoneby(Object doneBy) {
    return 'Hotovo · $doneBy';
  }

  @override
  String garminWorkoutWorkout(Object workout) {
    return 'Tréning Garmin · $workout';
  }

  @override
  String get moveAnyway => 'Presunúť aj tak?';

  @override
  String get wattsNeedYourFtpSet =>
      'Watty vyžadujú vaše FTP: nastavte ho v Záťaž, Prahy.';

  @override
  String get mainTargetInWattsFrom =>
      'Hlavný cieľ vo wattoch z vašej FTP, tepová frekvencia ako vodidlo.';

  @override
  String get mainTargetHeartRateWatts =>
      'Hlavný cieľ: tepová frekvencia; watty nie sú na hodinkách nastavené.';

  @override
  String get taperPhase => 'Fáza znižovania záťaže';

  @override
  String get recoverySession => 'Regeneračný tréning';

  @override
  String get closeToYourEvent => 'Blízko vášho podujatia';

  @override
  String get noWorkoutStructureAvailable =>
      'Štruktúra tréningu nie je k dispozícii.';

  @override
  String get aerobic => 'Aeróbne';

  @override
  String get pushAgainToUpdateYour =>
      'Odošlite znova, aby sa aktualizoval kalendár hodiniek.';

  @override
  String workoutSentToLabel(Object label) {
    return 'Tréning odoslaný do $label';
  }

  @override
  String get updating2 => 'Aktualizuje sa…';

  @override
  String pushToLabel(Object label) {
    return 'Odoslať do $label';
  }

  @override
  String shareExerciseListForLabel(Object label) {
    return 'Zdieľať zoznam cvikov pre $label';
  }

  @override
  String shareWorkoutForLabel(Object label) {
    return 'Zdieľať tréning pre $label';
  }

  @override
  String get whyNothingIsAddedTo =>
      'Prečo? Nič sa nepridáva, aby sa to doplnilo.';

  @override
  String get workout => 'Tréning';

  @override
  String get recordedActivityLinkedToThis =>
      'Zaznamenaná aktivita prepojená s týmto tréningom';

  @override
  String get matchedToTheRecordedWorkout =>
      'Priradené k začiatku zaznamenaného tréningu';

  @override
  String get matchedByWorkoutNameSport =>
      'Priradené podľa názvu tréningu, športu a dátumu';

  @override
  String get matchedBySportDateAnd =>
      'Priradené podľa športu, dátumu a trvania';

  @override
  String planPlannedminutesMin(Object plannedMinutes) {
    return 'Plán $plannedMinutes min';
  }

  @override
  String get maxHr => 'Max. TF';

  @override
  String get trainingLoad2 => 'Tréningová záťaž';

  @override
  String get active => 'Aktívne';

  @override
  String get avgPace => 'Priem. tempo';

  @override
  String get avgSpeed => 'Priem. rýchlosť';

  @override
  String get avgPower => 'Priem. výkon';

  @override
  String get elevation2 => 'Prevýšenie';

  @override
  String get altitude => 'Nadmorská výška';

  @override
  String get explainMyHrvBeforeAnd =>
      'Vysvetli moje HRV pred týmto tréningom a po ňom. Čo je porovnateľné, čo nie a čo je stále neznáme?';

  @override
  String get deleteActivity => 'Odstrániť aktivitu?';

  @override
  String get removeThisActivityFromThe =>
      'Odstrániť túto aktivitu z lokálnej histórie? Neskoršia synchronizácia poskytovateľa ju môže znova importovať.';

  @override
  String get howDidThisSessionGo =>
      'Ako tento tréning dopadol a čo znamená pre moje najbližšie dni?';

  @override
  String currentFixedFixed2(Object fixed, Object fixed2) {
    return 'Aktuálne $fixed, $fixed2';
  }

  @override
  String get setUpInTrainingSettings => 'Nastavte v nastaveniach tréningu';

  @override
  String get couldNotLoadHeatData =>
      'Údaje o teple sa nepodarilo načítať – ťuknutím zobrazíte podrobnosti';

  @override
  String get loadingHeatHistory => 'Načítava sa história tepla…';

  @override
  String get noHeatDataYet => 'Zatiaľ žiadne údaje o teple';

  @override
  String optimalLowHigh(Object low, Object high) {
    return 'Optimum $low–$high';
  }

  @override
  String optimalLowHighTrimp(Object low, Object high) {
    return 'Optimum: $low–$high TRIMP';
  }

  @override
  String get targetUnavailableSyncTrainingHistory =>
      'Cieľ nie je k dispozícii – synchronizujte tréningovú históriu';

  @override
  String get workoutQualifiedForHeatAccumulation =>
      'Tréning sa započítal do akumulácie tepla.';

  @override
  String get workoutDidNotAddHeat => 'Tréning nepridal akumuláciu tepla.';

  @override
  String get performanceTime => 'Výkon / Čas';

  @override
  String get performanceDistance => 'Výkon / Vzdialenosť';

  @override
  String get noRecordedRoute => 'Žiadna zaznamenaná trasa';

  @override
  String get zoomIn => 'Priblížiť';

  @override
  String get zoomOut => 'Oddialiť';

  @override
  String get fitRoute => 'Prispôsobiť trasu';

  @override
  String get fullscreenMap => 'Mapa na celú obrazovku';

  @override
  String get openstreetmapContributors2 => 'prispievatelia OpenStreetMap';

  @override
  String get appleIntelligenceIsUnavailableShowing =>
      'Apple Intelligence nie je k dispozícii. Zobrazuje sa súhrn bez AI.';

  @override
  String get generateAiBriefing => 'Vytvoriť AI prehľad?';

  @override
  String get retryAiBriefing => 'Skúsiť AI prehľad znova';

  @override
  String get generateBriefing => 'Vytvoriť prehľad';

  @override
  String discussThisBriefingWithMe(Object text) {
    return 'Prediskutuj so mnou tento prehľad a navrhni ďalší najlepší krok.\n\n$text';
  }

  @override
  String whyThisRecommendationWhichOf(Object text) {
    return 'Prečo toto odporúčanie? Ktoré moje čísla a ktoré medzery v údajoch k nemu viedli a čo by ho zmenilo?\n\n$text';
  }

  @override
  String get avg2 => 'Priem.';

  @override
  String get peak2 => 'Vrchol';

  @override
  String get notEnoughContinuousReadingsFor =>
      'Nedostatok nepretržitých meraní na priemer.';

  @override
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  ) {
    return 'Zaznamenané pokrytie: $inHours h $inMinutes min · časovo vážený priemer';
  }

  @override
  String get lying => 'Ležiačky';

  @override
  String get noHrvReadingsInThis => 'V tomto období žiadne merania HRV';

  @override
  String get overnightHrvComesFromYour =>
      'Nočné HRV pochádza z vašich hodiniek, bodové merania z Polar H10 (RMSSD). Metódy sa líšia: porovnávajte trendy, nie jednotlivé hodnoty.';

  @override
  String get noReadings => 'Žiadne merania';

  @override
  String get whenDidTheWorkoutStart => 'Kedy tréning začal?';

  @override
  String get whenDidItEnd => 'Kedy skončil?';

  @override
  String get last3Months => 'Posledné 3 mesiace';

  @override
  String get lastYear => 'Posledný rok';

  @override
  String lastDaysDays(Object days) {
    return 'Posledných $days dní';
  }

  @override
  String nowOnCurrentTapA(Object current) {
    return 'Teraz na $current. Ťuknite na deň alebo naň potiahnite tréning. Kroky zostanú nezmenené.';
  }

  @override
  String get monthView => 'Mesačné zobrazenie';

  @override
  String get syncing => 'Synchronizuje sa';

  @override
  String get trendUnavailable => 'Trend nie je k dispozícii';

  @override
  String get stable => 'Stabilný';

  @override
  String get increasing => 'Rastúci';

  @override
  String get decreasing => 'Klesajúci';

  @override
  String get unclear => 'Nejasný';

  @override
  String get notComparable => 'Neporovnateľné';

  @override
  String get waitingForAfter => 'Čaká sa na meranie po';

  @override
  String get afterOnly => 'Iba po';

  @override
  String get waitingForTheActualWorkout =>
      'Čaká sa na skutočný koniec tréningu.';

  @override
  String reminderAroundTolocal(Object toLocal) {
    return 'Pripomienka okolo $toLocal';
  }

  @override
  String get reminderIsDueMeasureWhen =>
      'Pripomienka je aktuálna. Merajte, keď budete pripravení.';

  @override
  String get thisReminderIsNoLonger =>
      'Táto pripomienka už nie je aktuálna. Otvorte tréning a zobrazte svoje merania.';

  @override
  String beforeFixedMilliseconds(Object fixed) {
    return 'Pred $fixed milisekúnd. ';
  }

  @override
  String afterFixedMilliseconds(Object fixed) {
    return 'Po $fixed milisekúnd';
  }

  @override
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  ) {
    return 'Zmena $deltaMs milisekúnd, $deltaPercent percent.';
  }

  @override
  String get noPreTrainingMeasurementRecorded =>
      'Nezaznamenané žiadne meranie pred tréningom.';

  @override
  String get notMeasuredYet => 'Zatiaľ nezmerané';

  @override
  String leftOutOfTheComparison(Object excludedTotal, Object c) {
    return 'Vylúčené z porovnania: $excludedTotal tréningov ($c).';
  }

  @override
  String get notFromThisWorkout => 'Nie z tohto tréningu';

  @override
  String get useAsBefore => 'Použiť ako pred';

  @override
  String get useAsAfter => 'Použiť ako po';

  @override
  String get beforeNotMeasured => 'Pred · nezmerané';

  @override
  String beforeTolocal(Object toLocal) {
    return 'Pred · $toLocal';
  }

  @override
  String workoutWorkouttext(Object workoutText) {
    return 'Tréning · $workoutText';
  }

  @override
  String get afterNotMeasuredYet => 'Po · zatiaľ nezmerané';

  @override
  String afterTolocal(Object toLocal) {
    return 'Po · $toLocal';
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
    return 'Vaše podobné tréningy ($eligible, $toLocal–$toLocal2): medián $medianMs ms, stredná polovica $q1Ms až $q3Ms ms.';
  }

  @override
  String get howHardDidItFeel => 'Aké ťažké to bolo? (RPE)';

  @override
  String get loadMetric => 'Záťaž';

  @override
  String get clearAction => 'Vymazať';

  @override
  String get routeFinish => 'Cieľ';

  @override
  String get month2 => 'MESIAC';

  @override
  String get week2 => 'TÝŽDEŇ';

  @override
  String get quarter => 'ŠTVRŤROK';

  @override
  String get year => 'ROK';

  @override
  String get easy3 => 'ĽAHKÉ';

  @override
  String get mod => 'MIERNE';

  @override
  String get hard => 'ŤAŽKÉ';

  @override
  String get protocol => 'PROTOKOL';

  @override
  String get calculate => 'VYPOČÍTAŤ';

  @override
  String get warmUp => 'ROZCVIČKA';

  @override
  String get coolDown => 'SCHLADENIE';

  @override
  String get ftpCycling => 'FTP cyklistika';

  @override
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg) {
    return 'FTP $ftpWatts W · $wattsPerKg W/kg';
  }

  @override
  String get thisWeekSoFar => 'TENTO TÝŽDEŇ · DOTERAZ';

  @override
  String get duration2 => 'TRVANIE';

  @override
  String get distance2 => 'VZDIALENOSŤ';

  @override
  String get sport2 => 'ŠPORT';

  @override
  String get repeatSets => 'OPAKOVANÉ SÉRIE';

  @override
  String get aboutThisWorkout => 'O TOMTO TRÉNINGU';

  @override
  String get workoutStructure => 'ŠTRUKTÚRA TRÉNINGU';

  @override
  String get health2 => 'ZDRAVIE';

  @override
  String get high2 => 'VYSOKÝ';

  @override
  String get elevated => 'ZVÝŠENÝ';

  @override
  String get normal => 'NORMÁLNY';

  @override
  String get tomorrow => 'ZAJTRA';

  @override
  String get skipped2 => 'PRESKOČENÉ';

  @override
  String get weeklyPlan => 'TÝŽDENNÝ PLÁN';

  @override
  String get activityLog3 => 'ZÁZNAM AKTIVÍT';

  @override
  String skippedTouppercase(Object toUpperCase) {
    return 'PRESKOČENÉ · $toUpperCase';
  }

  @override
  String get primaryZone => 'HLAVNÁ ZÓNA';

  @override
  String get coachingCues => 'TRÉNERSKÉ POKYNY';

  @override
  String get targets => 'CIELE';

  @override
  String get adaptation => 'ADAPTÁCIA';

  @override
  String get done2 => 'HOTOVO';

  @override
  String get notRecorded2 => 'NEZAZNAMENANÉ';

  @override
  String get planned => 'PLÁNOVANÉ';

  @override
  String get extra => 'NAVYŠE';

  @override
  String get optimal2 => 'OPTIMÁLNE';

  @override
  String get qualified => 'KVALIFIKOVANÉ';

  @override
  String get temp => 'TEPLOTA';

  @override
  String get humidity2 => 'VLHKOSŤ';

  @override
  String get pressure => 'TLAK';

  @override
  String get wetBulb => 'MOKRÝ TEPLOMER';

  @override
  String get paceMinKm => 'Tempo (min/km)';

  @override
  String get speedKmH => 'Rýchlosť (km/h)';

  @override
  String get elevationM => 'Prevýšenie (m)';

  @override
  String get powerW => 'VÝKON (W)';

  @override
  String get performanceTime2 => 'VÝKON / ČAS';

  @override
  String get performanceDistance2 => 'VÝKON / VZDIALENOSŤ';

  @override
  String get load2 => 'ZÁŤAŽ';

  @override
  String get day2 => 'DEŇ';

  @override
  String get allTime => 'CELKOVO';

  @override
  String get hrvAroundThisWorkout2 => 'HRV okolo tohto tréningu. ';

  @override
  String get lowReserve => 'NÍZKA REZERVA';

  @override
  String get goodReserve => 'DOBRÁ REZERVA';

  @override
  String latestReadingAtTolocal(Object toLocal) {
    return 'Posledné meranie o $toLocal';
  }

  @override
  String get weeklyAvg => 'TÝŽDENNÝ PRIEMER';

  @override
  String get monthlyAvg => 'MESAČNÝ PRIEMER';

  @override
  String get systolic2 => 'SYSTOLICKÝ';

  @override
  String get diastolic2 => 'DIASTOLICKÝ';

  @override
  String get hourlyVariation => 'HODINOVÉ KOLÍSANIE';

  @override
  String get dailyVariation => 'DENNÉ KOLÍSANIE';

  @override
  String get sys2 => 'SYS';

  @override
  String get dia => 'DIA';

  @override
  String get bluetoothDevices => 'ZARIADENIA BLUETOOTH';

  @override
  String get accountsServices => 'ÚČTY A SLUŽBY';

  @override
  String get flowLoginOptional => 'PRIHLÁSENIE DO FLOW (VOLITEĽNÉ)';

  @override
  String get polarFlowLogin => 'PRIHLÁSENIE DO POLAR FLOW';

  @override
  String get raceGoal => 'CIEĽ PRETEKOV';

  @override
  String get experienceLevel => 'ÚROVEŇ SKÚSENOSTÍ';

  @override
  String get weeklySchedule2 => 'TÝŽDENNÝ ROZVRH';

  @override
  String get sessionsPerDay2 => 'TRÉNINGY ZA DEŇ';

  @override
  String get aboutYou => 'O VÁS';

  @override
  String get yourActivities2 => 'VAŠE AKTIVITY';

  @override
  String latestReadingAtTimestamp(Object timestamp) {
    return 'Posledné meranie o $timestamp';
  }

  @override
  String get poorSleep => 'SLABÝ SPÁNOK';

  @override
  String get fairSleep => 'PRIEMERNÝ SPÁNOK';

  @override
  String get goodSleep => 'DOBRÝ SPÁNOK';

  @override
  String get hoursOfSleep => 'HODINY SPÁNKU';

  @override
  String get sleepNeeded => 'POTREBNÝ SPÁNOK';

  @override
  String get deepSleep => 'HLBOKÝ SPÁNOK';

  @override
  String get exercises2 => 'CVIKY';

  @override
  String get strengthSummary => 'SÚHRN SILY';

  @override
  String get strengthDraft => 'SILA · KONCEPT';

  @override
  String get strengthFinishedWithGaps => 'SILA · DOKONČENÉ S MEDZERAMI';

  @override
  String get strength2 => 'SILA';

  @override
  String get wind => 'VIETOR';

  @override
  String get sun2 => 'SLNKO';

  @override
  String get cloud => 'OBLAKY';

  @override
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt) {
    return 'Údaje: $source · Aktualizované $fetchedAt';
  }

  @override
  String get coros2 => 'COROS';

  @override
  String get rmssdMs => 'RMSSD · ms';

  @override
  String get sdnnMs => 'SDNN · ms';

  @override
  String get now2 => 'TERAZ';

  @override
  String get awake => 'BDELÝ';

  @override
  String get light => 'ĽAHKÝ';

  @override
  String get deep2 => 'HLBOKÝ';

  @override
  String get sqliteOrm => 'SQLite ORM';

  @override
  String get httpClients => 'Klienti HTTP';

  @override
  String get gpsLocation => 'Poloha GPS';

  @override
  String get hdlCholesterol => 'HDL cholesterol';

  @override
  String get ldlCholesterol => 'LDL cholesterol';

  @override
  String get raceName => 'NÁZOV PRETEKOV';

  @override
  String get mtb => 'MTB';

  @override
  String get distanceKm => 'Vzdialenosť (km)';

  @override
  String get priority => 'PRIORITA';

  @override
  String get elevationGainM => 'Prevýšenie (m)';

  @override
  String get targetTime => 'CIEĽOVÝ ČAS';

  @override
  String get raceDate => 'DÁTUM PRETEKOV';

  @override
  String get participation => 'ÚČASŤ';

  @override
  String get whatIWantFromIt => 'ČO OD TOHO CHCEM';

  @override
  String periodTimeline(Object period) {
    return '$period · PRIEBEH';
  }

  @override
  String get tabPlan => 'PLÁN';

  @override
  String get tabLoad => 'ZÁŤAŽ';

  @override
  String get tabCoach => 'TRÉNER';

  @override
  String get hrDriftTestLt1 => 'TEST DRIFTU TF – LT1';

  @override
  String get asSentByGarmin => 'TAK, AKO HO POSLAL GARMIN';

  @override
  String get noData2 => 'ŽIADNE ÚDAJE';

  @override
  String get noTarget => 'ŽIADNY CIEĽ';

  @override
  String get noHeatLoad => 'ŽIADNA TEPELNÁ ZÁŤAŽ';

  @override
  String get hrBpm => 'TF (bpm)';

  @override
  String get aiBriefingUnavailableShowingA =>
      'AI prehľad nie je k dispozícii. Zobrazuje sa súhrn bez AI.';

  @override
  String get uvIndex2 => 'UV INDEX';

  @override
  String get aiBriefing => 'AI prehľad';

  @override
  String get uiFrameworkByGoogle => 'UI framework od Googlu';

  @override
  String get unableToLoadData => 'Údaje sa nepodarilo načítať';

  @override
  String briefingSummary(Object recovery, Object sleep, Object load) {
    return 'Regenerácia $recovery / 100. Spánok $sleep / 100. Dnešná tréningová záťaž je $load TRIMP.';
  }

  @override
  String get morningBriefing => 'Ranný prehľad';

  @override
  String get lunchBriefing => 'Obedný prehľad';

  @override
  String get afternoonBriefing => 'Popoludňajší prehľad';

  @override
  String get eveningBriefing => 'Večerný prehľad';

  @override
  String get appleUnusableAnswer =>
      'Apple Intelligence nedokázala vytvoriť použiteľnú odpoveď: opakovala sa alebo opakovala vaše údaje. Preformulujte otázku alebo vyberte v nastaveniach iného poskytovateľa AI.';

  @override
  String get appleCouldNotAnswer =>
      'Apple Intelligence nemohla odpovedať. Skúste to znova.';

  @override
  String get appleNotAvailableOnDevice =>
      'Apple Intelligence nie je v tomto zariadení k dispozícii.';

  @override
  String get appleLanguageRejected =>
      'Apple Intelligence odmietla jazyk požiadavky. Skúste krátku otázku v angličtine. Skontrolujte aj jazykové nastavenia iPhonu a Siri.';

  @override
  String get appleRequestTooLarge =>
      'Apple Intelligence nedokázala spracovať túto požiadavku. Skúste kratšiu otázku.';

  @override
  String get messageTooLongForApple =>
      'Táto správa je pre Apple Intelligence príliš dlhá. Skráťte ju a odošlite znova.';

  @override
  String get vo2maxRunning => 'VO₂max beh';

  @override
  String get vo2maxCycling => 'VO₂max cyklistika';

  @override
  String get vo2maxPaceLabel => 'Tempo VO₂max';

  @override
  String get lt1Threshold => 'Prah LT1';

  @override
  String get lt2Threshold => 'Prah LT2';

  @override
  String hoursPreviousWeek(Object value) {
    return '$value h minulý týždeň';
  }

  @override
  String kmPreviousWeek(Object value) {
    return '$value km minulý týždeň';
  }

  @override
  String get thirtyMinuteTimeTrial => '30-minútová časovka';

  @override
  String thirtyMinTtDate(Object date) {
    return '30-min TT · $date';
  }

  @override
  String get yesterday2 => 'VČERA';

  @override
  String get briefHeadGreen => 'Ste dobre zregenerovaní.';

  @override
  String get briefHeadYellow => 'Máte určitú záťaž.';

  @override
  String get briefHeadRed => 'Ste výrazne zaťažení.';

  @override
  String briefMain(Object reasons) {
    return 'Hlavné dôvody: $reasons.';
  }

  @override
  String get briefAllClear =>
      'Žiadna z vašich hodnôt nevykazuje varovný signál.';

  @override
  String get briefAdviceGreen => 'Trénujte podľa plánu.';

  @override
  String get briefAdviceYellow => 'Držte sa plánu, ale nepridávajte intenzitu.';

  @override
  String get briefAdviceRed => 'Najprv regenerácia: ľahký deň alebo odpočinok.';

  @override
  String get briefReasonHrvLow => 'nízke HRV v spánku';

  @override
  String get briefReasonHrvHigh => 'vysoké HRV v spánku';

  @override
  String get briefReasonRhrUp => 'zvýšená pokojová TF';

  @override
  String get briefReasonRhrDown => 'nízka pokojová TF';

  @override
  String get briefReasonSleepShort => 'málo spánku';

  @override
  String get briefReasonSleepGood => 'potreba spánku splnená';

  @override
  String get briefReasonEnergyLow => 'málo energie';

  @override
  String get briefReasonEnergyHigh => 'dobrá energia';

  @override
  String get briefReasonStressHigh => 'vysoký stres';

  @override
  String get briefReasonRespHigh => 'zvýšená dychová frekvencia';

  @override
  String get briefReasonSpo2Low => 'nízky kyslík v krvi';

  @override
  String get briefReasonSkinTempOff => 'nezvyčajná teplota pokožky';

  @override
  String get briefReasonFormTired => 'nahromadená tréningová únava';

  @override
  String get briefReasonFormVeryTired => 'veľmi vysoká tréningová únava';

  @override
  String get briefReasonFormFresh => 'svieži a oddýchnutí';

  @override
  String get briefTrainingHrvUp =>
      'Vaše HRV po tréningu vzrástlo, čo je dobré znamenie.';

  @override
  String get briefTrainingHrvDown =>
      'Vaše HRV po tréningu kleslo, čo je menej dobré znamenie.';

  @override
  String get reminderNeedsNotifications =>
      'Pripomienka potrebuje upozornenia. Povoľte ich pre Fjelia v nastaveniach systému a znova ju zapnite.';

  @override
  String get whatDidYouHave => 'Čo ste skonzumovali?';

  @override
  String get intakeSomething => 'Niečo som skonzumoval';

  @override
  String get intakeNothing => 'Nič';

  @override
  String get totalIntake => 'Celkový príjem';

  @override
  String get carbsLabel => 'Sacharidy';

  @override
  String get fluidLabel => 'Tekutiny';

  @override
  String get sodiumLabel => 'Sodík';

  @override
  String get caffeineLabel => 'Kofeín';

  @override
  String get detailsOptional => 'Podrobnosti (voliteľné)';

  @override
  String atMinute(Object minute) {
    return 'minúta $minute';
  }

  @override
  String get nothingAddedYet =>
      'Zatiaľ nič nepridané. Pridajte, čo ste jedli alebo pili, alebo vyberte „Nič“.';

  @override
  String get followFocusWeek => 'Na čo sa mám tento týždeň zamerať?';

  @override
  String get followRecoveryTrend => 'Ako sa vyvíja moja regenerácia?';

  @override
  String get followLoadTooHigh => 'Je moja tréningová záťaž príliš vysoká?';

  @override
  String get followImproveSleep => 'Čo by zlepšilo môj spánok?';

  @override
  String get followIntervalsFeel => 'Aké by sa mali cítiť intervaly?';

  @override
  String get followTiredToday => 'Čo ak sa dnes cítim unavený?';

  @override
  String get followEatBefore => 'Čo by som mal pred tým jesť?';

  @override
  String get followAdjustToday => 'Mám to dnes upraviť?';

  @override
  String get followNextDays => 'Čo to znamená pre moje najbližšie dni?';

  @override
  String get followCompareSimilar =>
      'Ako to vychádza v porovnaní s podobnými tréningmi?';

  @override
  String get followRecover => 'Čo mám robiť, aby som sa zregeneroval?';

  @override
  String get followIntensityRight => 'Bola intenzita správna?';

  @override
  String get statusPlanned => 'Plánované';

  @override
  String get statusAdapted => 'Upravené';

  @override
  String get statusCompleted => 'Dokončené';

  @override
  String get statusRest => 'Odpočinok';

  @override
  String loadValue(Object value) {
    return 'Záťaž $value';
  }

  @override
  String get actIntensityEasy => 'Bol to ľahký aeróbny tréning.';

  @override
  String get actIntensityModerate => 'Bol to stredne náročný tréning.';

  @override
  String get actIntensityHard => 'Bol to náročný tréning.';

  @override
  String get actIntensityUnknown => 'Tréning je zaznamenaný.';

  @override
  String get actLenLonger => 'Bola dlhšia než vaše podobné tréningy.';

  @override
  String get actLenShorter => 'Bola kratšia než vaše podobné tréningy.';

  @override
  String get actLoadHigher => 'Záťaž bola vyššia než zvyčajne.';

  @override
  String get actLoadLower => 'Záťaž bola nižšia než zvyčajne.';

  @override
  String get actLoadSame => 'Záťaž bola približne obvyklá.';

  @override
  String get actHrLower => 'Vaša TF bola nižšia než zvyčajne, bolo to ľahšie.';

  @override
  String get actHrHigher => 'Vaša TF bola vyššia než zvyčajne, bolo to ťažšie.';

  @override
  String get actAdviceUnknown =>
      'Nasledujúce dni plánujte podľa toho, ako sa cítite.';

  @override
  String briefOutlookRest(Object days) {
    return 'Približne po $days ľahkých dňoch bude vaša forma späť v optimálnom rozsahu.';
  }

  @override
  String get briefOutlookLongRest =>
      'Vaša forma potrebuje na zotavenie viac než pár ľahkých dní.';

  @override
  String get briefOutlookPlanTired =>
      'Ak budete dodržiavať plán, vaša forma zostane nízka aj v najbližších dňoch.';

  @override
  String get localQwen => 'Qwen3.5 · lokálne';

  @override
  String get localModelDescription =>
      'Voliteľný Qwen3.5, 4-bitový MLX. Stiahnite ho raz a používajte chat a súhrny v tomto zariadení bez kľúča API. Vaše zdravotné údaje zostávajú v tomto zariadení.';

  @override
  String localModelSizeMb(Object megabytes) {
    return 'Stiahnutie $megabytes MB · počas používania je potrebná ďalšia pamäť.';
  }

  @override
  String get localModelDownload => 'Stiahnuť model';

  @override
  String get localModelResumeDownload => 'Pokračovať v sťahovaní';

  @override
  String localModelDownloading(Object downloaded, Object total) {
    return '$downloaded / $total MB';
  }

  @override
  String get localModelInstalled => 'Stiahnuté · dostupné offline';

  @override
  String get localModelRemove => 'Odstrániť model';

  @override
  String get localModelUnsupported =>
      'Tento model MLX vyžaduje iPhone s iOS 17 alebo novším a čipom A14 alebo novším. Staršie zariadenia nie sú podporované.';

  @override
  String get localModelMemoryUnsupported =>
      'Toto zariadenie nemá dostatok pamäte na spustenie lokálneho modelu.';

  @override
  String get localModelDownloadFailed =>
      'Sťahovanie zlyhalo. Skúste to znova; úplné súbory sa zachovajú.';

  @override
  String get localModelDownloadFirst =>
      'Najprv stiahnite Qwen v Nastavenia → AI a ďalšie.';

  @override
  String get localModelContextTooLong =>
      'Táto konverzácia je pre lokálny model príliš dlhá. Začnite nový chat alebo skráťte otázku.';

  @override
  String get localModelBusy =>
      'Lokálny model odpovedá na inú požiadavku. Skúste to znova o chvíľu.';

  @override
  String get localModelInterrupted =>
      'Lokálne generovanie bolo prerušené. Nechajte Fjelia otvorenú a skúste to znova.';

  @override
  String get localModelCouldNotAnswer =>
      'Lokálny model nedokázal odpovedať. Skontrolujte model v Nastavenia → AI a ďalšie a skúste to znova.';

  @override
  String get localModelBriefingUnavailable =>
      'Lokálny súhrn AI nie je dostupný. Zobrazuje sa súhrn aplikácie.';

  @override
  String get localModelInfo => 'Podrobnosti modelu a licencia';

  @override
  String localModelRamGb(int gigabytes) {
    return 'Vyžaduje aspoň $gigabytes GB operačnej pamäte.';
  }

  @override
  String get localModelIPhone18 =>
      'Model 4B je dostupný na iPhone 18 a novšom.';

  @override
  String briefPlannedTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Na dnes je naplánovaných $count tréningov.',
      few: 'Na dnes sú naplánované $count tréningy.',
      one: 'Na dnes je naplánovaný 1 tréning.',
    );
    return '$_temp0';
  }

  @override
  String get coachDataFallback =>
      'Odpoveď modelu je v rozpore s údajmi. Tu je súhrn od Fjelie:';

  @override
  String get coachSevenDayAverage => '7-dňový priemer';

  @override
  String coachSleepNeedAndShortfall(String need, String shortfall) {
    return 'Potreba spánku: $need h; deficit: $shortfall h.';
  }

  @override
  String coachCurrentForm(String value) {
    return 'Aktuálna forma (TSB): $value bodov.';
  }

  @override
  String get aiOnboardingStep => 'Krok 2 z 3';

  @override
  String get aiOnboardingTitle => 'Tvoj tréner.\nTvoja cesta.';

  @override
  String get aiOnboardingSubtitle =>
      'Premeň svoje zdravotné údaje na tipy pre lepší tréning a regeneráciu.';

  @override
  String get aiOnboardingChoose => 'VYBER SI AI TRÉNERA';

  @override
  String get aiOnboardingFreeDetail => 'Zadarmo · Bez účtu AI';

  @override
  String get aiOnboardingFreeBody => 'Cloudová AI pre tréning a regeneráciu.';

  @override
  String get aiOnboardingRecommended => 'Odporúčané';

  @override
  String get aiOnboardingOnDevice => 'Na tvojom zariadení';

  @override
  String get aiOnboardingLocalBody =>
      'Tvoje AI požiadavky zostávajú v tomto zariadení.';

  @override
  String get aiOnboardingUnavailable => 'Momentálne nedostupné';

  @override
  String get aiOnboardingMore => 'Ďalšie AI modely';

  @override
  String get aiOnboardingMoreBody =>
      'Lokálny Qwen alebo vlastný cloudový poskytovateľ';

  @override
  String get aiOnboardingConsent =>
      'Cloudové požiadavky až po tvojom potvrdení.';

  @override
  String get aiOnboardingError =>
      'Výber AI sa nepodarilo uložiť alebo načítať. Skús to znova.';

  @override
  String get aiOnboardingWithout => 'Pokračovať bez AI';

  @override
  String get aiOnboardingConfigure => 'Nastaviť model';

  @override
  String aiOnboardingContinue(String provider) {
    return 'Pokračovať s $provider';
  }

  @override
  String get aiOnboardingChangeLater =>
      'Voľbu môžeš kedykoľvek zmeniť v nastaveniach.';

  @override
  String get creditsAndLicenses => 'Licencie a poďakovania';

  @override
  String get bioAgeActivity => 'Pohyb';

  @override
  String get bioAgeActivityBasis => 'Údaje o pohybe · posledných 7 dní';

  @override
  String bioAgeActivityReported(String minutes) {
    return '$minutes zaznamenaných minút strednej intenzity';
  }

  @override
  String bioAgeActivitySteps(String minutes) {
    return '≈ $minutes minút chôdze odhadnutých z krokov';
  }

  @override
  String bioAgeActivityCoverage(int days) {
    return 'Údaje za $days zo 7 dní';
  }

  @override
  String get bioAgeActivityEstimateNotice =>
      'Predpoklad: 100 krokov ≈ 1 minúta chôdze. Denný počet krokov neukazuje tempo ani intenzitu. Zaznamenané minúty majú každý deň prednosť; kroky z toho istého dňa sa už nepripočítavajú.';

  @override
  String get bioAgeActivityIncomplete =>
      'Chýbajú údaje o pohybe. Príspevok pohybu v rokoch sa vypočíta až vtedy, keď sú dostupné údaje za všetkých 7 dní.';

  @override
  String get bioAgeActivityEstimatedLabel =>
      'Pohyb zahŕňa odhadovaný čas chôdze.';

  @override
  String get bioAgeActivityUnknownLabel => 'Údaje o pohybe sú neúplné';
}
