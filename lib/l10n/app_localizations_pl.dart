// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get freeAi => 'Free AI';

  @override
  String get freeAiUsageTracking =>
      'Aby Free AI było niezawodnie dostępne dla wszystkich, wysyłamy losowy identyfikator instalacji. Pomaga nam wykrywać nietypowe użycie i blokować nadużycia. Identyfikator nie zawiera Twojego imienia ani danych konta.';

  @override
  String freeAiDescription(String host) {
    return 'Free AI zapewnia bezpłatny czat w chmurze i podsumowania przez $host. Nie potrzebujesz osobnego konta ani klucza API. Wiadomości i podsumowanie zdrowia i treningów są wysyłane do tej usługi po Twoim potwierdzeniu.';
  }

  @override
  String get freeAiUnavailable =>
      'Free AI nie jest dostępne w tej wersji. Wybierz innego dostawcę.';

  @override
  String shareBriefingContextWithName(String name) {
    return 'Podsumowanie Twoich danych o zdrowiu i treningach zostanie wysłane do $name. Ta jednorazowa zgoda obejmuje też dostawców AI w chmurze, których wybierzesz później do podsumowań.';
  }

  @override
  String get language => 'Język';

  @override
  String get languageSystem => 'Domyślny język systemu';

  @override
  String get settings => 'Ustawienia';

  @override
  String get profile => 'Profil';

  @override
  String get training => 'Trening';

  @override
  String get weatherLocation => 'Pogoda i lokalizacja';

  @override
  String get display => 'Wygląd';

  @override
  String get connections => 'Połączenia';

  @override
  String get aiAndMore => 'AI i więcej';

  @override
  String get system => 'System';

  @override
  String get runSetupAgain => 'Uruchom konfigurację ponownie';

  @override
  String get runSetupAgainSubtitle => 'Konta, cel startowy i plan treningowy';

  @override
  String get back => 'Wstecz';

  @override
  String get close => 'Zamknij';

  @override
  String get dataExport => 'Eksport danych';

  @override
  String get dataExportSubtitle => 'Eksport CSV, kopia zapasowa i przywracanie';

  @override
  String get developer => 'Deweloper';

  @override
  String get developerSubtitle => 'Tryb debugowania, diagnostyka';

  @override
  String get debug => 'Debug';

  @override
  String get debugMode => 'Tryb debugowania';

  @override
  String get debugModeSubtitle => 'Pokazuje kartę DEBUG';

  @override
  String get support => 'Pomoc';

  @override
  String get reportBug => 'Zgłoś błąd';

  @override
  String get aiCoach => 'Trener AI';

  @override
  String get enableAiCoach => 'Włącz trenera AI';

  @override
  String get onDeviceAiOrCloud => 'AI na urządzeniu lub dostawca w chmurze';

  @override
  String get provider => 'Dostawca';

  @override
  String get model => 'Model';

  @override
  String get chatAndAiBriefingsUse =>
      'Czat i podsumowania AI korzystają z Apple Intelligence na tym urządzeniu. Klucz API nie jest potrzebny. Jeśli model jest niedostępny, podsumowania pokazują zestawienie bez AI.';

  @override
  String get briefing => 'Podsumowanie';

  @override
  String get useAppleIntelligenceForBriefings =>
      'Używaj Apple Intelligence do podsumowań';

  @override
  String get useOnDeviceAiFor =>
      'Używaj AI na urządzeniu do podsumowań, a wybranego dostawcy do czatu.';

  @override
  String get healthDataSharing => 'Udostępnianie danych o zdrowiu';

  @override
  String get askOncePerChatSession => 'Pytaj raz na sesję czatu';

  @override
  String get otherwiseAskBeforeEveryCloud =>
      'W przeciwnym razie pytaj przed każdą wiadomością do chmury';

  @override
  String get reportABug => 'Zgłoś błąd';

  @override
  String get weatherData => 'Dane pogodowe';

  @override
  String get openSourceLibraries => 'Biblioteki open source';

  @override
  String get license => 'Licencja';

  @override
  String get licenses => 'Licencje';

  @override
  String get apiKey => 'Klucz API';

  @override
  String get saveApiKey => 'Zapisz klucz API';

  @override
  String get feedbackBugReport => 'Opinia i zgłoszenie błędu';

  @override
  String get reportSentThankYou => 'Zgłoszenie wysłane. Dziękujemy!';

  @override
  String get weReadEveryMessageIf =>
      'Czytamy każdą wiadomość. Jeśli podasz e-mail, możesz otrzymać odpowiedź.';

  @override
  String get done => 'Gotowe';

  @override
  String get shareAnIdeaSuggestAn =>
      'Podziel się pomysłem, zaproponuj ulepszenie albo opisz, co się stało i czego się spodziewałeś.';

  @override
  String get whatHappenedAndWhatDid => 'Co się stało i czego się spodziewałeś?';

  @override
  String get pleaseLeaveOutPasswordsApi =>
      'Nie podawaj haseł, kluczy API ani osobistych pomiarów zdrowia.';

  @override
  String get includeDiagnostics => 'Dołącz diagnostykę';

  @override
  String get optionalLogsMayContainAccount =>
      'Opcjonalnie. Logi mogą zawierać dane konta lub zdrowia. Sprawdź je poniżej przed wysłaniem.';

  @override
  String get diagnosticsPreview => 'PODGLĄD DIAGNOSTYKI';

  @override
  String get sendingSharesYourEmailSubject =>
      'Wysłanie udostępnia Twój e-mail, temat, wiadomość i wybraną diagnostykę pomocy technicznej Fjelia pod adresem www.fjelia.com.';

  @override
  String get copyReport => 'Kopiuj zgłoszenie';

  @override
  String get shareReport => 'Udostępnij zgłoszenie';

  @override
  String get appleHealth => 'Apple Zdrowie';

  @override
  String get connectedServices => 'Połączone usługi';

  @override
  String get hiloBloodPressureBle => 'Ciśnienie krwi Hilo BLE';

  @override
  String get writeHeartDataToApple => 'Zapisuj dane serca w Apple Zdrowie';

  @override
  String get writeWeightDataToApple => 'Zapisuj dane wagi w Apple Zdrowie';

  @override
  String get renphoScaleBle => 'Waga Renpho (BLE)';

  @override
  String get polarH10HrvStrapBle => 'Polar H10 (pas HRV, BLE)';

  @override
  String get dataSourcePriority => 'Priorytet źródeł danych';

  @override
  String get whenMultipleSourcesProvideThe =>
      'Gdy kilka źródeł podaje ten sam pomiar, wygrywa źródło wyżej na liście. Przeciągnij, aby zmienić kolejność.';

  @override
  String get resetToDefault => 'Przywróć domyślne';

  @override
  String get disconnect => 'Rozłącz';

  @override
  String get healthPage => 'Strona zdrowia';

  @override
  String get loadPage => 'Strona obciążenia';

  @override
  String get healthMonitor => 'Monitor zdrowia';

  @override
  String get hrZones => 'Strefy tętna';

  @override
  String get t30MinTtAvailableSync =>
      'Dostępna 30-minutowa jazda na czas — zsynchronizuj strefy tętna';

  @override
  String lt2Lt2BpmAt(Object lt2, Object at) {
    return 'LT2 $lt2 bpm · $at';
  }

  @override
  String get syncLabel => 'SYNC';

  @override
  String get autoadjust => 'AUTOMATYCZNIE';

  @override
  String zoneI(Object i) {
    return 'Strefa $i';
  }

  @override
  String get hrZones2 => 'STREFY TĘTNA';

  @override
  String ageRound(Object round) {
    return 'wiek $round';
  }

  @override
  String get basics => 'Podstawy';

  @override
  String get updateWaistMonthlyUsedFor =>
      'ⓘ Aktualizuj obwód talii co miesiąc — służy do oszacowania tłuszczu trzewnego.';

  @override
  String get alcohol => 'Alkohol';

  @override
  String get t1Drink033L =>
      '1 drink ≈ 0,33 l piwa / 0,2 l wina / 4 cl mocnego alkoholu';

  @override
  String get clinicalLabsOptional =>
      'Wyniki badań laboratoryjnych (opcjonalnie)';

  @override
  String get glycemic => 'Glikemia';

  @override
  String get optimalForLongevity48 =>
      'Optymalnie dla długowieczności: 4,8–5,4% · Stan przedcukrzycowy: 5,7–6,4%';

  @override
  String get lipids => 'Lipidy';

  @override
  String get apobReplacesLdlWhenBoth => 'ApoB zastępuje LDL, gdy podano oba.';

  @override
  String get inflammationKidney => 'Stan zapalny i nerki';

  @override
  String get changesAreSavedAutomatically =>
      'Zmiany są zapisywane automatycznie';

  @override
  String get optionalTotalClimbingForThis =>
      'Opcjonalnie: łączne przewyższenie tego startu.';

  @override
  String get moreAboutThisEvent => 'Więcej o tym wydarzeniu';

  @override
  String distanceOfDistancekmKm(Object distanceKm) {
    return 'Dystans $distanceKm km?';
  }

  @override
  String keepDistancekmKm(Object distanceKm) {
    return 'Zachowaj $distanceKm km';
  }

  @override
  String useLikelyKm(Object likely) {
    return 'Użyj $likely km';
  }

  @override
  String get thisBackupContainsNoCalendar =>
      'Ta kopia zapasowa nie zawiera aktywności z kalendarza.';

  @override
  String get activities => 'Aktywności';

  @override
  String get exportActivitiesCsv => 'Eksportuj aktywności do CSV';

  @override
  String get backupRestore => 'Kopia zapasowa i przywracanie';

  @override
  String get backup => 'Kopia zapasowa';

  @override
  String get restoreFromBackup => 'Przywróć z kopii zapasowej';

  @override
  String get backupRestoredRestartTheApp =>
      'Kopia zapasowa przywrócona. Uruchom aplikację ponownie, aby wczytać wszystkie ustawienia.';

  @override
  String get raceGoals => 'Cele startowe';

  @override
  String get yourActivities => 'Twoje aktywności';

  @override
  String get usedByAiCoachAnd =>
      'Używane przez trenera AI i plan treningowy. Sporty z planu są oznaczone ✦.';

  @override
  String get calendarWeekStart => 'Początek tygodnia w kalendarzu';

  @override
  String get planDefaultView => 'Domyślny widok planu';

  @override
  String get weeklySchedule => 'Harmonogram tygodnia';

  @override
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      trainingDaysPerWeek,
      locale: localeName,
      other: '$trainingDaysPerWeek dnia treningowego',
      many: '$trainingDaysPerWeek dni treningowych',
      few: '$trainingDaysPerWeek dni treningowe',
      one: '$trainingDaysPerWeek dzień treningowy',
    );
    return '$_temp0 · dotknij, aby przełączać trening / odpoczynek / siła';
  }

  @override
  String get updatePlanToThisSchedule => 'Dostosuj plan do tego harmonogramu';

  @override
  String get updateStrengthSessions => 'Zaktualizuj treningi siłowe';

  @override
  String get sessionsPerDay => 'Treningi dziennie';

  @override
  String get canYouFitTwoWorkouts =>
      'Czy zmieścisz dwa treningi w jednym dniu?';

  @override
  String get strengthLoadUnit => 'Jednostka obciążenia siłowego';

  @override
  String get weightsThemselvesAreSetIn =>
      'Same ciężary ustawiasz w każdym treningu; są zapamiętywane z Twojej historii.';

  @override
  String get hoursAvailableWeek => 'Dostępne godziny / tydzień';

  @override
  String hoursperweekHWeek(Object hoursPerWeek) {
    return '$hoursPerWeek h / tydzień';
  }

  @override
  String hoursperweekH(Object hoursPerWeek) {
    return '$hoursPerWeek h';
  }

  @override
  String get heatAcclimation => 'Aklimatyzacja do upału';

  @override
  String get showHeatAcclimation => 'Pokaż aklimatyzację do upału';

  @override
  String get weatherEvaluatedAgainstAConfigurable =>
      'Pogoda jest oceniana dla wybranej lokalizacji.';

  @override
  String get trainingPlan => 'Plan treningowy';

  @override
  String get regenerateReplacesFutureSessionsAnd =>
      'Ponowne generowanie zastępuje przyszłe treningi i odbudowuje plan od dziś według bieżących ustawień.';

  @override
  String valueUpcomingWorkoutsGenerated(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value nadchodzącego treningu wygenerowano',
      many: '$value nadchodzących treningów wygenerowanych',
      few: '$value nadchodzące treningi wygenerowane',
      one: '$value nadchodzący trening wygenerowany',
    );
    return '$_temp0';
  }

  @override
  String get generationFailedCheckYourRace =>
      'Generowanie nie powiodło się. Sprawdź cel startowy i spróbuj ponownie.';

  @override
  String get deleteAllWorkouts => 'Usuń wszystkie treningi';

  @override
  String get changesAreSavedAutomatically2 =>
      '✓ Zmiany są zapisywane automatycznie';

  @override
  String countUpcomingWorkoutsGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nadchodzącego treningu wygenerowano',
      many: '$count nadchodzących treningów wygenerowanych',
      few: '$count nadchodzące treningi wygenerowane',
      one: '$count nadchodzący trening wygenerowany',
    );
    return '$_temp0';
  }

  @override
  String get importRaceGoalsFromGarmin => 'Importuj cele startowe z Garmin';

  @override
  String get addRaceGoal => 'Dodaj cel startowy';

  @override
  String priorityTouppercase(Object toUpperCase) {
    return 'Priorytet $toUpperCase';
  }

  @override
  String get goalsAreSharedWithAi =>
      'Cele są udostępniane trenerowi AI. Priorytety A, B i C decydują, jak plan waży Twoje starty względem siebie.';

  @override
  String get deletingWorkouts => 'Usuwanie treningów';

  @override
  String get cityOrTown => 'Miasto lub miejscowość';

  @override
  String get eGHannoverOrPalma => 'np. Hanower lub Palma';

  @override
  String get noCitiesFoundTryA =>
      'Nie znaleziono miast. Spróbuj pobliskiej miejscowości.';

  @override
  String get chooseTheLocationForThe =>
      'Wybierz lokalizację dla prognozy w planie, radaru i aklimatyzacji do upału. Pogoda działa także przy wyłączonej aklimatyzacji.';

  @override
  String get none => 'Brak';

  @override
  String get disableLocalWeatherAndLocation =>
      'Wyłącz lokalną pogodę i zapytania o lokalizację';

  @override
  String get currentLocation => 'Bieżąca lokalizacja';

  @override
  String get followYourDeviceLocation => 'Śledź lokalizację urządzenia';

  @override
  String get fixedLocation => 'Stała lokalizacja';

  @override
  String get chooseACityOrEnter => 'Wybierz miasto lub wpisz współrzędne';

  @override
  String get chooseCity => 'Wybierz miasto';

  @override
  String get coordinates => 'Współrzędne';

  @override
  String get latitude => 'Szerokość geograficzna';

  @override
  String get longitude => 'Długość geograficzna';

  @override
  String get saveLocation => 'Zapisz lokalizację';

  @override
  String get refreshCurrentLocation => 'Odśwież bieżącą lokalizację';

  @override
  String get citySearchOpenMeteoGeonames =>
      'Wyszukiwanie miast: Open-Meteo / GeoNames';

  @override
  String get cityNamesOpenstreetmap => 'Nazwy miejscowości: © OpenStreetMap';

  @override
  String get energy => 'ENERGIA';

  @override
  String get currentEnergy => 'BIEŻĄCA ENERGIA';

  @override
  String get dailyTimeline => 'PRZEBIEG DNIA';

  @override
  String valueValue2(Object value, Object value2) {
    return '$value → $value2';
  }

  @override
  String get energy2 => 'Energia';

  @override
  String get noData => 'Brak danych';

  @override
  String get bloodPressureInsights => 'ANALIZA CIŚNIENIA KRWI';

  @override
  String get sys => ' Sys';

  @override
  String get diaMmhg => ' Dia · mmHg';

  @override
  String get previousBloodPressurePeriod => 'Poprzedni okres ciśnienia';

  @override
  String get nextBloodPressurePeriod => 'Następny okres ciśnienia';

  @override
  String get nightDipping => 'Nocny spadek';

  @override
  String get noMeasurementsInThisPeriod => 'Brak pomiarów w tym okresie';

  @override
  String get fullscreenBloodPressureChart =>
      'Wykres ciśnienia na pełnym ekranie';

  @override
  String get barsMinMaxLineDots =>
      'Słupki: min–maks · linia/punkty: średnia · dotknij lub przeciągnij, aby sprawdzić';

  @override
  String get noMeasurements => 'Brak pomiarów';

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
      other: '$length pomiarów',
      many: '$length pomiarów',
      few: '$length pomiary',
      one: '$length pomiar',
    );
    return '$_temp0 · średnia / min–maks';
  }

  @override
  String bloodPressureTouppercaseMmhg(Object toUpperCase) {
    return 'CIŚNIENIE KRWI · $toUpperCase · mmHg';
  }

  @override
  String get closeFullscreenBloodPressureChart =>
      'Zamknij wykres ciśnienia na pełnym ekranie';

  @override
  String get chooseScale => 'Wybierz wagę';

  @override
  String get noScalesFoundStepOn =>
      'Nie znaleziono wagi. Stań na wadze i spróbuj ponownie.';

  @override
  String nameRssiDbm(Object name, Object rssi) {
    return '$name · $rssi dBm';
  }

  @override
  String get renphoSaved => 'RENPHO zapisano:';

  @override
  String get renphoScaleBle2 => 'Waga RENPHO (BLE)';

  @override
  String get changeMeasurementType => 'Zmień rodzaj pomiaru';

  @override
  String get addMeasurement => 'Dodaj pomiar';

  @override
  String get whatAreYouMeasuring => 'Co mierzysz?';

  @override
  String get chooseAnotherMeasurement => 'Wybierz inny pomiar';

  @override
  String get saveMeasurement => 'Zapisz pomiar';

  @override
  String get skip => 'Pomiń';

  @override
  String get connectHiloService => 'Połącz usługę Hilo';

  @override
  String get connectHilo => 'Połącz Hilo';

  @override
  String get connectCoros => 'Połącz Coros';

  @override
  String get europe => 'Europa';

  @override
  String get unitedStates => 'Stany Zjednoczone';

  @override
  String get asia => 'Azja';

  @override
  String get bluetoothBloodPressure => 'Bluetooth · ciśnienie krwi';

  @override
  String get cloudCuffData => 'Chmura · dane z mankietu';

  @override
  String get apiSync => 'Synchronizacja API';

  @override
  String get bluetoothHrvStrap => 'Bluetooth · pas HRV';

  @override
  String get accesslinkApi => 'AccessLink API';

  @override
  String get systemHealthData => 'Systemowe dane o zdrowiu';

  @override
  String get cloudScaleHistory => 'Chmura · historia ważenia';

  @override
  String get bluetoothWeightBody => 'Bluetooth · waga i ciało';

  @override
  String get connectYourDevices => 'Połącz swoje urządzenia';

  @override
  String get continueLabel => 'Dalej';

  @override
  String get connectGarmin => 'Połącz Garmin';

  @override
  String get connectAppleHealth => 'Połącz Apple Zdrowie';

  @override
  String get dataSynced => 'DANE ZSYNCHRONIZOWANE';

  @override
  String get pairHiloPod => 'Sparuj Hilo Pod';

  @override
  String get chooseStrap => 'Wybierz pas';

  @override
  String namePaired(Object name) {
    return 'Sparowano $name.';
  }

  @override
  String get pairPolarH10 => 'Sparuj Polar H10';

  @override
  String get forget => 'Zapomnij';

  @override
  String get sendWorkoutToPolar => 'Wyślij trening do Polar';

  @override
  String get connectPolar => 'Połącz Polar';

  @override
  String get signInWithPolarFlow => 'Zaloguj się przez Polar Flow';

  @override
  String get syncsSleepStagesHrvResting =>
      'Synchronizuje fazy snu · HRV · tętno spoczynkowe · treningi · kroki';

  @override
  String savedForV(Object v) {
    return 'Zapisano dla $v';
  }

  @override
  String get remove => 'Usuń';

  @override
  String get polarEMail => 'E-mail Polar';

  @override
  String get polarPassword => 'Hasło Polar';

  @override
  String get pairRenphoScale => 'Sparuj wagę RENPHO';

  @override
  String get connectRenpho => 'Połącz Renpho';

  @override
  String get connectSuunto => 'Połącz Suunto';

  @override
  String smsSentToTrim(Object trim) {
    return 'SMS wysłany na $trim';
  }

  @override
  String get resendSms => 'Wyślij SMS ponownie';

  @override
  String get retryLoadingPreferences => 'Ponów wczytywanie preferencji';

  @override
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed) {
    return 'TYGODNIOWY CZAS TRENINGU · $toStringAsFixed h';
  }

  @override
  String get tapADayToCycle =>
      'Dotknij dnia, aby przełączać trening / odpoczynek / siła.';

  @override
  String get doubleDayOk => 'Podwójny dzień OK';

  @override
  String get birthYearOptional => 'Rok urodzenia (opcjonalnie)';

  @override
  String get addAnother => 'Dodaj kolejny';

  @override
  String get knowYourBodyTrainSmarter => 'Poznaj swoje ciało.\nTrenuj mądrzej.';

  @override
  String get allYourHealthDevicesOne =>
      'Wszystkie Twoje urządzenia zdrowotne. Jeden inteligentny widok.';

  @override
  String get areYouReadyToTrain => 'Czy jesteś gotowy na dzisiejszy trening?';

  @override
  String get hrvRecoveryScoreRestingHr =>
      'HRV · Wynik regeneracji · Tętno spoczynkowe';

  @override
  String get didYouActuallyRecoverLast =>
      'Czy naprawdę zregenerowałeś się tej nocy?';

  @override
  String get sleepStagesDeepSleepSpo => 'Fazy snu · Sen głęboki · SpO₂';

  @override
  String get isYourBloodPressureUnder =>
      'Czy Twoje ciśnienie jest pod kontrolą?';

  @override
  String get continuousBpNightDippingTrends =>
      'Ciągły pomiar ciśnienia · Nocny spadek · Trendy';

  @override
  String get howHardDidYouPush => 'Jak mocno trenowałeś w tym tygodniu?';

  @override
  String get trainingLoadTrimpStrainScore =>
      'Obciążenie treningowe · TRIMP · Strain Score';

  @override
  String get isYourBodyCompositionImproving =>
      'Czy skład Twojego ciała się poprawia?';

  @override
  String get weightBodyFatMuscleMass =>
      'Waga · Tkanka tłuszczowa · Masa mięśniowa';

  @override
  String get getStarted => 'Zaczynamy';

  @override
  String get yourDataStaysOnYour =>
      'Twoje dane. Ty decydujesz, co udostępniasz.';

  @override
  String get bodyScale => 'Waga';

  @override
  String get bodyComposition => 'Skład ciała';

  @override
  String get sleep => 'SEN';

  @override
  String get sleepPerformance => 'JAKOŚĆ SNU';

  @override
  String get sleepHistory => 'Historia snu';

  @override
  String labelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String lessLabel(Object label) {
    return 'Mniej: $label';
  }

  @override
  String moreLabel(Object label) {
    return 'Więcej: $label';
  }

  @override
  String get gymMode => 'Tryb siłowni';

  @override
  String get finishWorkout => 'Zakończ trening';

  @override
  String get workoutActions => 'Działania treningu';

  @override
  String get discardWorkout => 'Odrzuć trening';

  @override
  String get allSetsRecorded => 'Wszystkie serie zapisane';

  @override
  String get reviewSets => 'Przejrzyj serie';

  @override
  String get rest => 'PRZERWA';

  @override
  String plannedResttarget(Object restTarget) {
    return 'Planowo $restTarget';
  }

  @override
  String get startSet => 'Rozpocznij serię';

  @override
  String get seconds => 'Sekundy';

  @override
  String get previousSet => 'Poprzednia seria';

  @override
  String get allSets => 'Wszystkie serie';

  @override
  String get nextSet => 'Następna seria';

  @override
  String get everySetIsSavedAs =>
      'Każda seria jest zapisywana na bieżąco. Zamknij ten ekran w dowolnej chwili i wróć z zaplanowanego treningu.';

  @override
  String get cancel => 'Anuluj';

  @override
  String get apply => 'Zastosuj';

  @override
  String get effortScale => 'Skala wysiłku';

  @override
  String get setType => 'Rodzaj serii';

  @override
  String get reps => 'Powtórzenia';

  @override
  String get range => 'Zakres';

  @override
  String get time => 'Czas';

  @override
  String get t45Or100 => '45 lub 1:00';

  @override
  String get blankWhenNotSet => 'Puste, gdy nie ustawiono';

  @override
  String get redBand => 'Czerwona guma';

  @override
  String get t90Or130 => '90 lub 1:30';

  @override
  String get blankWhenUnknown => 'Puste, gdy nieznane';

  @override
  String get usePlannedLoad => 'Użyj planowanego obciążenia';

  @override
  String get blankWhenNotMeasured => 'Puste, gdy nie zmierzono';

  @override
  String get exercise => 'Ćwiczenie';

  @override
  String get changingTheLoadConventionStarts =>
      'Zmiana sposobu zapisu obciążenia rozpoczyna osobną historię tego ćwiczenia.';

  @override
  String get barbellMachine => 'Sztanga, maszyna…';

  @override
  String get load => 'Obciążenie';

  @override
  String get loadRefersTo => 'Obciążenie dotyczy';

  @override
  String get t2ForAPair => '2 dla pary';

  @override
  String get repetitions => 'Powtórzenia';

  @override
  String get availablePlatesOrDumbbells => 'Dostępne talerze lub hantle';

  @override
  String get rememberForThisEquipment => 'Zapamiętaj dla tego sprzętu';

  @override
  String get findOrNameAnExercise => 'Znajdź lub nazwij ćwiczenie';

  @override
  String createTrim(Object trim) {
    return 'Utwórz „$trim”';
  }

  @override
  String get customExercise => 'Własne ćwiczenie';

  @override
  String get smallestLoadStep => 'Najmniejszy krok obciążenia';

  @override
  String whatRemoved(Object what) {
    return 'Usunięto: $what';
  }

  @override
  String get undo => 'Cofnij';

  @override
  String get retry => 'Ponów';

  @override
  String get performance => 'Wynik';

  @override
  String get addExercise => 'Dodaj ćwiczenie';

  @override
  String get finishLog => 'Zakończ zapis';

  @override
  String get keepAsDraft => 'Zachowaj jako szkic';

  @override
  String actionsForName(Object name) {
    return 'Działania dla $name';
  }

  @override
  String get editExercise => 'Edytuj ćwiczenie';

  @override
  String get moveUp => 'Przenieś wyżej';

  @override
  String get moveDown => 'Przenieś niżej';

  @override
  String get addSet => 'Dodaj serię';

  @override
  String get removeLastSet => 'Usuń ostatnią serię';

  @override
  String get saveAsTemplate => 'Zapisz jako szablon';

  @override
  String savedTitleAsATemplate(Object title) {
    return 'Zapisano „$title” jako szablon. Ten trening pozostaje bez zmian, dopóki go nie zapiszesz.';
  }

  @override
  String nameSetN(Object name, Object n) {
    return '$name · Seria $n';
  }

  @override
  String nameAllWorkingSets(Object name) {
    return '$name · Wszystkie serie robocze';
  }

  @override
  String labelRest(Object label) {
    return '$label przerwa';
  }

  @override
  String get secondsOrMSs => 'Sekundy lub m:ss';

  @override
  String get applyToAllSets => 'Zastosuj do wszystkich serii';

  @override
  String get duplicate => 'Duplikuj';

  @override
  String get supersetWithNext => 'Superseria z następnym';

  @override
  String get circuitWithNext => 'Obwód z następnym';

  @override
  String actionsForSetN(Object n) {
    return 'Działania dla serii $n';
  }

  @override
  String get editSet => 'Edytuj serię';

  @override
  String get duplicateSet => 'Duplikuj serię';

  @override
  String get removeSet => 'Usuń serię';

  @override
  String labelActions(Object label) {
    return 'Działania: $label';
  }

  @override
  String get editRests => 'Edytuj przerwy';

  @override
  String get ungroup => 'Rozgrupuj';

  @override
  String get editExercises => 'Edytuj ćwiczenia';

  @override
  String get unsavedChanges => 'Niezapisane zmiany';

  @override
  String couldNotSaveError(Object error) {
    return 'Nie udało się zapisać: $error';
  }

  @override
  String get history => 'Historia';

  @override
  String get exercises => 'Ćwiczenia';

  @override
  String get noExercisesArePlannedFor =>
      'Dla tego treningu nie zaplanowano jeszcze ćwiczeń. Opisują go notatki powyżej.';

  @override
  String get addExercises => 'Dodaj ćwiczenia';

  @override
  String get fromTheBuiltInTemplate =>
      'Z wbudowanego szablonu. Obciążenia ustawiasz sam; historia pojawi się po zapisaniu treningu.';

  @override
  String get shareExerciseList => 'Udostępnij listę ćwiczeń';

  @override
  String get noSavedStrengthTemplatesYet =>
      'Brak zapisanych szablonów siłowych. Najpierw zapisz szablon z zaplanowanego treningu.';

  @override
  String get compareWith => 'Porównaj z';

  @override
  String estimated1rmUnit(Object unit) {
    return 'Szacowane 1RM $unit';
  }

  @override
  String get plannedNotRecorded => 'Zaplanowane, niezapisane';

  @override
  String get notes => 'Notatki';

  @override
  String get editPerformance => 'Edytuj wynik';

  @override
  String get compareWithASavedWorkout => 'Porównaj z zapisanym treningiem';

  @override
  String get sessions => 'Treningi';

  @override
  String get radarUnavailableRetry => 'Radar niedostępny · Ponów';

  @override
  String get radar => 'Radar';

  @override
  String get weatherDataByRainviewer => 'Dane pogodowe: RainViewer';

  @override
  String get openstreetmapContributors => '© współtwórcy OpenStreetMap';

  @override
  String get weather => 'Pogoda';

  @override
  String get weatherUnavailableRetry => 'Pogoda niedostępna · Ponów';

  @override
  String get chooseAFixedLocationIn =>
      'Wybierz stałą lokalizację w ustawieniach Pogoda i lokalizacja albo zezwól na dostęp do lokalizacji, aby widzieć lokalną pogodę.';

  @override
  String get locationSettings => 'Ustawienia lokalizacji';

  @override
  String get retryLocation => 'Ponów lokalizację';

  @override
  String round2(Object round) {
    return '$round°';
  }

  @override
  String roundRhRound2Hpa(Object round, Object round2) {
    return '$round% wilg. · $round2 hPa';
  }

  @override
  String wetBulbTostringasfixedC(Object toStringAsFixed) {
    return 'Temperatura termometru mokrego $toStringAsFixed°C';
  }

  @override
  String get previousForecastDay => 'Poprzedni dzień prognozy';

  @override
  String get nextForecastDay => 'Następny dzień prognozy';

  @override
  String daysDayForecast(Object days) {
    return 'Prognoza na $days dni';
  }

  @override
  String thisProviderCurrentlySuppliesDays(Object days, Object days2) {
    return 'Ten dostawca podaje obecnie $days z $days2 dni prognozy.';
  }

  @override
  String get now => 'Teraz';

  @override
  String get sunriseSunset => 'Wschód / zachód słońca';

  @override
  String keyKey2(Object key, Object key2) {
    return '☀ $key   ☾ $key2';
  }

  @override
  String get use => 'Użyj';

  @override
  String get exerciseDetailsWereNotProvided =>
      'To źródło aktywności nie podało szczegółów ćwiczeń.';

  @override
  String get logFromPlan => 'Zapisz z planu';

  @override
  String get addExerciseDetails => 'Dodaj szczegóły ćwiczeń';

  @override
  String get loadSuggestion => 'Sugerowane obciążenie';

  @override
  String get applyToThisWorkout => 'Zastosuj do tego treningu';

  @override
  String get keepCurrentLoad => 'Zachowaj obecne obciążenie';

  @override
  String get setLoadStep => 'Ustaw krok obciążenia';

  @override
  String get viewSupportingSets => 'Pokaż serie bazowe';

  @override
  String get supportingSets => 'Serie bazowe';

  @override
  String get noRecordedSessionsYet => 'Brak zapisanych treningów.';

  @override
  String nameDemonstrationCue(Object name, Object cue) {
    return 'Demonstracja: $name. $cue';
  }

  @override
  String get noScalesFoundStepOn2 =>
      'Nie znaleziono wagi. Stań na wadze i spróbuj ponownie.';

  @override
  String get scalePaired => 'Waga sparowana';

  @override
  String get ok => 'OK';

  @override
  String get pairedReadyToMeasure => '✓ Sparowano — gotowe do pomiaru';

  @override
  String get chooseHiloCuff => 'Wybierz mankiet Hilo';

  @override
  String get noCuffFoundWakeYour =>
      'Nie znaleziono mankietu. Wybudź mankiet i wyszukaj ponownie.';

  @override
  String get hiloCuffAktiiaC => 'Mankiet Hilo (AKTIIA C…)';

  @override
  String get onDemandBloodPressureVia =>
      'Pomiar ciśnienia na żądanie przez BLE';

  @override
  String get selectHiloPodWristband => 'Wybierz Hilo Pod (opaskę)';

  @override
  String get rescan => 'Szukaj ponownie';

  @override
  String get noDevicesFoundTapTo =>
      'Nie znaleziono urządzeń. Dotknij ↻, aby wyszukać ponownie.';

  @override
  String get polarH10SpotHrv => 'Polar H10 · Punktowy pomiar HRV';

  @override
  String get aSeparateHrvReadingBefore =>
      'Osobny pomiar HRV przed treningiem lub po nim. Te pomiary nie zastępują nocnego HRV z Garmin i nie zmieniają Twojego wyniku gotowości.';

  @override
  String get wearTheStrapWithMoist =>
      'Załóż pas z wilgotnymi elektrodami. Nie ruszaj się i oddychaj normalnie. Do porównań używaj tej samej pozycji i długości pomiaru. Po treningu zanotuj, jak długo najpierw odpoczywałeś.';

  @override
  String get measurement => 'Pomiar';

  @override
  String get posture => 'Pozycja';

  @override
  String get recordingLengthPlus1Min =>
      'Długość pomiaru · plus 1 min na uspokojenie';

  @override
  String get t2Minutes => '2 minuty';

  @override
  String get t5Minutes => '5 minut';

  @override
  String get minutesSinceTrainingEndedOptional =>
      'Minuty od końca treningu (opcjonalnie)';

  @override
  String get sessionOrNotesOptional => 'Trening lub notatki (opcjonalnie)';

  @override
  String connectName(Object name) {
    return 'Połącz $name';
  }

  @override
  String get findPolarH10 => 'Znajdź Polar H10';

  @override
  String signalRssiDbm(Object rssi) {
    return 'Sygnał $rssi dBm';
  }

  @override
  String connectedName(Object name) {
    return 'Połączono: $name';
  }

  @override
  String get waitingForHeartRateAnd =>
      'Oczekiwanie na tętno i odstępy RR. Sprawdź kontakt pasa.';

  @override
  String get startMeasurement => 'Rozpocznij pomiar';

  @override
  String get cancelMeasurement => 'Anuluj pomiar';

  @override
  String get spotHrvRmssd => 'Punktowe HRV · RMSSD';

  @override
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  ) {
    return '$accepted/$length użytecznych odstępów · $toStringAsFixed% pokrycia';
  }

  @override
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs) {
    return 'lnRMSSD: $lnRmssd · Surowe RMSSD: $rawRmssdMs ms';
  }

  @override
  String get signalQualityIsTooLow =>
      'Jakość sygnału jest za niska, aby zapisać pomiar. Powtórz go przy dobrym kontakcie pasa. Wymagane jest co najmniej 95% użytecznych odstępów i 90% pokrycia.';

  @override
  String get savedToSpotHrvHistory => 'Zapisano w historii punktowego HRV.';

  @override
  String get newMeasurement => 'Nowy pomiar';

  @override
  String get signalScreeningExcludesPoorContact =>
      'Kontrola sygnału odrzuca słaby kontakt, RR poza zakresem 250–2500 ms i odstępy różniące się o ponad 25% od lokalnej mediany. Luki nie są uzupełniane. To nie jest badanie medyczne ani samodzielny wynik gotowości.';

  @override
  String historyLabelLabel2DurationMin(
    Object label,
    Object label2,
    Object duration,
  ) {
    return 'Historia · $label · $label2 · $duration min';
  }

  @override
  String get onlyReadingsWithTheSame =>
      'Razem pokazywane są tylko pomiary o tym samym kontekście, pozycji i długości.';

  @override
  String get noMatchingMeasurementsYet => 'Brak pasujących pomiarów.';

  @override
  String tostringasfixedMsRmssdTostringasfixed2Bpm(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return '$toStringAsFixed ms RMSSD · $toStringAsFixed2 bpm';
  }

  @override
  String get exportRrIntervalsCsv => 'Eksportuj odstępy RR (CSV)';

  @override
  String get deleteMeasurement => 'Usuń pomiar';

  @override
  String get remindMeToMeasureHrv =>
      'Przypominaj mi o pomiarze HRV po treningu';

  @override
  String get appleHealthIsNoLonger => 'Apple Zdrowie nie jest już dostępne';

  @override
  String get later => 'Później';

  @override
  String get reconnect => 'Połącz ponownie';

  @override
  String get gripStrength => 'Siła chwytu';

  @override
  String get leftKg => 'Lewa (kg)';

  @override
  String get rightKg => 'Prawa (kg)';

  @override
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg) {
    return 'L $leftKg · P $rightKg kg';
  }

  @override
  String get notificationsAreOffYouCan =>
      'Powiadomienia są wyłączone. Nadal możesz mierzyć z poziomu treningu.';

  @override
  String get noRemindersFrom2200 => 'Brak przypomnień od 22:00 do 07:00';

  @override
  String get aReminderThatWouldFall =>
      'Przypomnienie przypadające w tym czasie jest pomijane, a nie przenoszone na rano.';

  @override
  String get remindersArriveQuietlyInThe =>
      'Przypomnienia pojawiają się po cichu na liście powiadomień.';

  @override
  String get noForecastForThisDay => 'Brak prognozy na ten dzień';

  @override
  String get fullscreen => 'Pełny ekran';

  @override
  String source(Object source) {
    return '● $source';
  }

  @override
  String get temperatureC => '● Temperatura °C';

  @override
  String get rainMm => '▥ Deszcz mm';

  @override
  String get uvIndex => '— Indeks UV';

  @override
  String get closeFullscreenWeatherChart =>
      'Zamknij wykres pogody na pełnym ekranie';

  @override
  String get sleepStages => 'FAZY SNU';

  @override
  String get noStageTimelineForThis => 'Brak przebiegu faz snu dla tej nocy.';

  @override
  String round3(Object round) {
    return '$round%';
  }

  @override
  String get examplesOnlyCheckAndEnter =>
      'To tylko przykłady: sprawdź i wpisz wartości z etykiety produktu na porcję. Nieznane składniki zostaw puste; wpisz 0 tylko wtedy, gdy wiesz to na pewno.';

  @override
  String get nutritionStrategy => 'Strategia żywieniowa';

  @override
  String get noPreWorkoutNutritionStrategy =>
      'Nie zapisano strategii żywieniowej przed treningiem.';

  @override
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium) {
    return '$carbs g węglowodanów/h · $fluid ml/h · $sodium mg sodu/h';
  }

  @override
  String get forecastUpdatedReviewOrRecalculate =>
      'Prognoza zaktualizowana — sprawdź lub przelicz zapisaną strategię.';

  @override
  String strategySavedSavedat(Object savedAt) {
    return 'Strategia zapisana $savedAt';
  }

  @override
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  ) {
    return 'Łącznie w trakcie: $totalCarbs g węglowodanów · $totalFluid ml · $totalSodium mg sodu';
  }

  @override
  String every20MinAboutCarbs(Object carbs, Object fluid) {
    return 'Co 20 min: około $carbs g węglowodanów i $fluid ml.';
  }

  @override
  String get packQuantitiesIncludeFullContainers =>
      'Ilości do spakowania obejmują pełne opakowania; nie musisz zużyć wszystkiego.';

  @override
  String get workoutChangedReviewOrRecalculate =>
      'Trening się zmienił — sprawdź lub przelicz tę zapisaną strategię.';

  @override
  String get conditionsAndFeedingPlan => 'Warunki i plan żywienia';

  @override
  String get editStrategy => 'Edytuj strategię';

  @override
  String get recalculate => 'Przelicz';

  @override
  String get actualNutrition => 'Faktyczne żywienie';

  @override
  String get someProductValuesAreUnknown =>
      'Niektóre wartości produktów są nieznane; sumy są niepełne.';

  @override
  String get logFoodAndFluids => 'Zapisz jedzenie i płyny';

  @override
  String get recordWhatYouActuallyHad =>
      'Zapisz, co faktycznie spożyłeś. Planowane spożycie nie jest kopiowane do tego zapisu.';

  @override
  String get elapsedMinutesIncludingStopsOptional =>
      'Upływ minut z postojami (opcjonalnie)';

  @override
  String recordedDurationActivityMin(Object activity) {
    return 'Zarejestrowany czas: $activity min';
  }

  @override
  String get compareWithSavedStrategy => 'Porównaj z zapisaną strategią';

  @override
  String get useMatchedSessionIfAvailable =>
      'Użyj dopasowanego treningu, jeśli jest dostępny';

  @override
  String get noPlanComparison => 'Bez porównania z planem';

  @override
  String titleDate(Object title, Object date) {
    return '$title · $date';
  }

  @override
  String get linkedStrategyUnavailable => 'Powiązana strategia niedostępna';

  @override
  String quantityName(Object quantity, Object name) {
    return '$quantity × $name';
  }

  @override
  String get removeIntake => 'Usuń spożycie';

  @override
  String get addFoodOrDrink => 'Dodaj jedzenie lub napój';

  @override
  String get iHadNoIntake => 'Nic nie spożyłem';

  @override
  String get giGutComfort => 'Komfort żołądkowo-jelitowy';

  @override
  String get whatWorkedSymptomsAccessProblems =>
      'Co zadziałało / objawy / problemy z dostępem';

  @override
  String get saveDraft => 'Zapisz szkic';

  @override
  String get skipLoggingThisActivity => 'Nie zapisuj tej aktywności';

  @override
  String get nutritionAndFluids => 'Żywienie i płyny';

  @override
  String get productsToleranceAndMeasuredSweat =>
      'Produkty, tolerancja i zmierzona utrata potu';

  @override
  String get postWorkoutIntakeReminder => 'Przypomnienie o posiłku po treningu';

  @override
  String get onceAfterARecentEndurance =>
      'Raz po niedawnym treningu wytrzymałościowym; cisza nocna 22:00–08:00.';

  @override
  String get addHiloBpReport => 'Dodaj raport ciśnienia Hilo';

  @override
  String get readingPdfReportsIsOnly =>
      'Odczyt raportów PDF jest dostępny tylko w iOS i macOS.';

  @override
  String get chooseAnotherReport => 'Wybierz inny raport';

  @override
  String get biologicalAge => 'Wiek biologiczny';

  @override
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class) {
    return 'VO₂max $vo2max ml/kg/min · $vo2Class';
  }

  @override
  String get factorContributions => 'Udział czynników';

  @override
  String estimatedRangeRoundRound2Years(Object round, Object round2) {
    return 'Szacowany zakres $round–$round2 lat. To szacunek modelu, nie diagnoza medyczna.';
  }

  @override
  String get noEnergyMeasurementsForThis =>
      'Brak pomiarów energii dla tego dnia';

  @override
  String get scanningStepOnTheScale =>
      'Wyszukiwanie… stań na wadze, gdy będziesz gotowy.';

  @override
  String waistWaistCmUpdateMonthly(Object waist) {
    return 'Talia: $waist cm — aktualizuj co miesiąc w profilu';
  }

  @override
  String get measuring => 'Pomiar…';

  @override
  String get tryAgain => 'Spróbuj ponownie';

  @override
  String get systolic => 'Skurczowe';

  @override
  String get diastolic => 'Rozkurczowe';

  @override
  String get heartRate => 'Tętno';

  @override
  String get weight => 'Waga';

  @override
  String get bodyFat => 'Tkanka tłuszczowa';

  @override
  String get duration => 'Czas trwania';

  @override
  String get deep => 'Głęboki';

  @override
  String get spo => 'SpO₂';

  @override
  String get activityName => 'Nazwa aktywności';

  @override
  String get sport => 'Sport';

  @override
  String get distance => 'Dystans';

  @override
  String get saved => 'Zapisano';

  @override
  String get connectionFailedCheckYourInternet =>
      'Połączenie nie powiodło się. Sprawdź połączenie z internetem.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Hasło';

  @override
  String get passwordTooShort => 'Hasło jest za krótkie';

  @override
  String get loginFailedCheckYourEmail =>
      'Logowanie nie powiodło się. Sprawdź e-mail i hasło.';

  @override
  String get connectionFailedCheckYourCredentials =>
      'Połączenie nie powiodło się. Sprawdź dane logowania i połączenie z internetem.';

  @override
  String get region => 'Region';

  @override
  String get hiloPod => 'Hilo pod';

  @override
  String get hiloAccount => 'Konto Hilo';

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
  String get renphoAccount => 'Konto Renpho';

  @override
  String get garminConnectEmail => 'E-mail Garmin Connect';

  @override
  String get verifyMfaCode => 'Zweryfikuj kod MFA';

  @override
  String get verificationCode => 'Kod weryfikacyjny';

  @override
  String errorE(Object e) {
    return 'Błąd: $e';
  }

  @override
  String get noHiloPodFoundMake =>
      'Nie znaleziono Hilo pod. Upewnij się, że jest naładowany i w pobliżu.';

  @override
  String scanFailedE(Object e) {
    return 'Wyszukiwanie nie powiodło się: $e';
  }

  @override
  String get hiloPod2 => 'Hilo Pod';

  @override
  String get scanForPod => 'Szukaj poda';

  @override
  String get scanForPolarH10 => 'Szukaj Polar H10';

  @override
  String get couldNotReachPolarCheck =>
      'Nie można połączyć się z Polar. Sprawdź połączenie.';

  @override
  String get signInAndSendWorkout => 'Zaloguj się i wyślij trening';

  @override
  String get scanForScale => 'Szukaj wagi';

  @override
  String get passwordRequired => 'Hasło jest wymagane';

  @override
  String get enterYourPhoneNumberWith =>
      'Wpisz numer telefonu (z kierunkowym kraju, np. +48…) i e-mail Suunto.';

  @override
  String get enterThePinFromThe => 'Wpisz PIN z SMS-a.';

  @override
  String get incorrectPinPleaseTryAgain =>
      'Nieprawidłowy PIN. Spróbuj ponownie.';

  @override
  String get phoneNumber => 'Numer telefonu';

  @override
  String get suuntoAccountEmail => 'E-mail konta Suunto';

  @override
  String get enterPinFromSms => 'Wpisz PIN z SMS-a';

  @override
  String get verifyConnect => 'Zweryfikuj i połącz';

  @override
  String get sendSmsCode => 'Wyślij kod SMS';

  @override
  String couldNotSavePreferencesE(Object e) {
    return 'Nie udało się zapisać preferencji: $e';
  }

  @override
  String get mon => 'Pn';

  @override
  String get tue => 'Wt';

  @override
  String get wed => 'Śr';

  @override
  String get thu => 'Cz';

  @override
  String get fri => 'Pt';

  @override
  String get sat => 'So';

  @override
  String get sun => 'Nd';

  @override
  String get male => 'Mężczyzna';

  @override
  String get female => 'Kobieta';

  @override
  String get other => 'Inne';

  @override
  String get running => 'Bieganie';

  @override
  String get trailRunning => 'Bieganie w terenie';

  @override
  String get cycling => 'Kolarstwo';

  @override
  String get swimming => 'Pływanie';

  @override
  String get triathlon => 'Triathlon';

  @override
  String get hiking => 'Wędrówki';

  @override
  String get rowing => 'Wioślarstwo';

  @override
  String get buildMyPlan => 'Utwórz mój plan';

  @override
  String get keepAConsistentBedtimeAnd =>
      'Kładź się spać i wstawaj o stałych porach, aby wspierać rytm snu.';

  @override
  String get thisWorkoutHasNoSets => 'Ten trening nie ma serii.';

  @override
  String loadName(Object name) {
    return 'Obciążenie ($name)';
  }

  @override
  String get setLabel => 'Seria';

  @override
  String get lowestReps => 'Najmniej powtórzeń';

  @override
  String get highestReps => 'Najwięcej powtórzeń';

  @override
  String get repsPerSide => 'Powtórzenia na stronę';

  @override
  String get fromReps => 'Od powtórzeń';

  @override
  String get toReps => 'Do powtórzeń';

  @override
  String get addedLoad => 'Dodatkowe obciążenie';

  @override
  String get assistance => 'Wspomaganie';

  @override
  String get tempoOptional => 'Tempo (opcjonalnie)';

  @override
  String get notesOptional => 'Notatki (opcjonalnie)';

  @override
  String get enterTheRepetitionsDone => 'Wpisz liczbę wykonanych powtórzeń.';

  @override
  String plannedUnit(Object unit) {
    return 'Planowo $unit';
  }

  @override
  String get repsDone => 'Wykonane powtórzenia';

  @override
  String get resistance => 'Opór';

  @override
  String get implementsLabel => 'Przybory';

  @override
  String get name => 'Nazwa';

  @override
  String get instructionsOptional => 'Instrukcje (opcjonalnie)';

  @override
  String get remember => 'Zapamiętaj';

  @override
  String get notSavedYet => 'Jeszcze nie zapisano';

  @override
  String get saving => 'Zapisywanie…';

  @override
  String get couldNotSave => 'Nie udało się zapisać';

  @override
  String get plannedValuesAreHintsNot =>
      'Planowane wartości to wskazówki, nie wyniki. Dotknij serii, aby ją zapisać.';

  @override
  String get completedAsPlanned => 'Wykonano zgodnie z planem';

  @override
  String get save => 'Zapisz';

  @override
  String get nameTheTemplate => 'Nazwij szablon.';

  @override
  String setN(Object n) {
    return 'Seria $n';
  }

  @override
  String get changesApplyToThisWorkout =>
      'Zmiany dotyczą tylko tego treningu. Ukończone treningi i inne sesje pozostają bez zmian.';

  @override
  String get saveForThisWorkout => 'Zapisz dla tego treningu';

  @override
  String knownForKnownOfOf(Object known, Object of) {
    return 'Znane dla $known z $of serii z obciążeniem';
  }

  @override
  String get sessionEstimate => 'Szacunek dla treningu';

  @override
  String get calculatedRange => 'Obliczony zakres';

  @override
  String get timedWork => 'Praca na czas';

  @override
  String get strengthTraining => 'Trening siłowy';

  @override
  String get theExercisesCouldNotBe => 'Nie udało się wczytać ćwiczeń.';

  @override
  String get resumeWorkout => 'Wznów trening';

  @override
  String get strengthWorkout => 'Trening siłowy';

  @override
  String get untitledTemplate => 'Szablon bez nazwy';

  @override
  String get theRecordedExercisesCouldNot =>
      'Nie udało się wczytać zapisanych ćwiczeń.';

  @override
  String get exercisesPerformed => 'Wykonane ćwiczenia';

  @override
  String get comparedWithThePlanAs =>
      'W porównaniu z planem w chwili rozpoczęcia zapisu.';

  @override
  String topWorkingLoadName(Object name) {
    return 'Najwyższe obciążenie robocze ($name)';
  }

  @override
  String get estimated1rmMiddleOfRange => 'Szacowane 1RM, środek zakresu';

  @override
  String get noLoggedSessionsYet => 'Brak zapisanych treningów.';

  @override
  String get noRadarFramesAvailable => 'Brak obrazów radarowych';

  @override
  String get playRadar => 'Odtwórz radar';

  @override
  String get pauseRadar => 'Wstrzymaj radar';

  @override
  String get high => 'Wysoki';

  @override
  String get clear => 'Bezchmurnie';

  @override
  String get bodyweight => 'Masa ciała';

  @override
  String get resistance2 => 'Opór —';

  @override
  String assistUnit(Object unit) {
    return 'Wspomaganie $unit';
  }

  @override
  String get reps2 => 'Powtórzenia —';

  @override
  String get notRecorded => 'Nie zapisano';

  @override
  String get skipped => 'Pominięto';

  @override
  String get health => 'Zdrowie';

  @override
  String get manual => 'Ręcznie';

  @override
  String expandName(Object name) {
    return 'Rozwiń $name';
  }

  @override
  String get open => 'Otwórz';

  @override
  String get noScalePaired => 'Brak sparowanej wagi';

  @override
  String get paired => 'Sparowano';

  @override
  String get change => 'Zmień';

  @override
  String get noCuffPaired => 'Brak sparowanego mankietu';

  @override
  String get noPolarH10FoundWear =>
      'Nie znaleziono Polar H10. Załóż pas, zwilż elektrody i sprawdź, czy inna aplikacja nie używa obu połączeń Bluetooth.';

  @override
  String get enterMinutesSinceTrainingEnded =>
      'Wpisz minuty od końca treningu, od 0 do 1440.';

  @override
  String get timingFollowsYourWorkout => 'Pora zależy od Twojego treningu.';

  @override
  String get recordingStayStill => 'Nagrywanie · nie ruszaj się';

  @override
  String get meanHrBpm => 'Średnie tętno · bpm';

  @override
  String get pairAPolarH10First => 'Najpierw sparuj Polar H10.';

  @override
  String get around30MinutesAfterTraining =>
      'Około 30 minut po treningu, jeśli trening jest dostępny na czas.';

  @override
  String get reminderDiagnostics => 'Diagnostyka przypomnień';

  @override
  String get forecast => 'Prognoza';

  @override
  String forecastRange(int count) {
    return 'Zacieniowane: zakres $count prognoz';
  }

  @override
  String get enterAName => 'Wpisz nazwę';

  @override
  String get enterAValidAmount => 'Wpisz prawidłową ilość';

  @override
  String get enterAPositiveAmount => 'Wpisz dodatnią ilość';

  @override
  String get maximum120GH => 'Maksymalnie 120 g/h';

  @override
  String get carbohydrateTargetGH => 'Cel węglowodanów g/h';

  @override
  String get fluidTargetMlH => 'Cel płynów ml/h';

  @override
  String get sodiumTargetMgHNot => 'Cel sodu mg/h (nie soli)';

  @override
  String get surfaceFeedingAccess => 'Nawierzchnia / dostęp do jedzenia';

  @override
  String get expectedAscentM => 'Oczekiwane przewyższenie m';

  @override
  String get expectedAltitudeM => 'Oczekiwana wysokość m';

  @override
  String get humidity => 'Wilgotność %';

  @override
  String get windKmH => 'Wiatr km/h';

  @override
  String get dayForecast => 'Prognoza dnia';

  @override
  String get enteredConditions => 'Wpisane warunki';

  @override
  String get productFoodName => 'Produkt / nazwa jedzenia';

  @override
  String get servingsQuantity => 'Porcje / ilość';

  @override
  String get when => 'Kiedy';

  @override
  String get carbohydrateGServing => 'Węglowodany g / porcja';

  @override
  String get fluidMlServing => 'Płyn ml / porcja';

  @override
  String get caffeineMgServing => 'Kofeina mg / porcja';

  @override
  String get proteinGServing => 'Białko g / porcja';

  @override
  String get gel => 'Żel';

  @override
  String get water => 'Woda';

  @override
  String get sportsDrink => 'Napój izotoniczny';

  @override
  String get bar => 'Baton';

  @override
  String get finishIntakeLog => 'Zakończ zapis spożycia';

  @override
  String get importing => 'Importowanie…';

  @override
  String importNewreadings(Object newReadings) {
    return 'Importuj $newReadings';
  }

  @override
  String get reading => 'Odczyt…';

  @override
  String get chooseReportPdf => 'Wybierz raport (PDF)';

  @override
  String get yourTrainingHistoryIsReady =>
      'Twoja historia treningów jest gotowa';

  @override
  String get importingYourTrainingHistory => 'Importowanie historii treningów';

  @override
  String get stopImport => 'Zatrzymaj import';

  @override
  String get dismiss => 'Zamknij';

  @override
  String get openai => 'OpenAI';

  @override
  String get appleIntelligence => 'Apple Intelligence';

  @override
  String get nonAiBriefing => 'Podsumowanie bez AI';

  @override
  String get noBriefing => 'Bez podsumowania';

  @override
  String get ruleBasedSummaryFromYour =>
      'Podsumowanie oparte na regułach z Twoich danych o zdrowiu — bez wywołań API';

  @override
  String get hideTheBriefingCard => 'Ukryj kartę podsumowania';

  @override
  String get flutter => 'Flutter';

  @override
  String get stateManagement => 'Zarządzanie stanem';

  @override
  String get bluetoothLe => 'Bluetooth LE';

  @override
  String get interactiveMaps => 'Interaktywne mapy';

  @override
  String get chartsGraphs => 'Wykresy';

  @override
  String get secureCredentialStorage =>
      'Bezpieczne przechowywanie danych logowania';

  @override
  String get markdownRendering => 'Wyświetlanie Markdown';

  @override
  String get appleOnDeviceAi => 'AI Apple na urządzeniu';

  @override
  String get cryptography => 'Kryptografia';

  @override
  String get appleHealthHealthConnect => 'Apple Zdrowie i Health Connect';

  @override
  String get runtimePermissions => 'Uprawnienia w czasie działania';

  @override
  String get shareExport => 'Udostępnianie i eksport';

  @override
  String get openUrls => 'Otwieranie adresów URL';

  @override
  String get internationalisation => 'Internacjonalizacja';

  @override
  String get utilities => 'Narzędzia';

  @override
  String get icons => 'Ikony';

  @override
  String get fjelia => 'Fjelia';

  @override
  String get fjeliaFeedback => 'Opinia o Fjelia';

  @override
  String get couldNotSendTheReport =>
      'Nie udało się wysłać zgłoszenia. Twój tekst nadal tu jest. Spróbuj ponownie.';

  @override
  String get yourEmail => 'Twój e-mail';

  @override
  String get enterAValidEmailAddress => 'Wpisz prawidłowy adres e-mail.';

  @override
  String get subject => 'Temat';

  @override
  String get sending => 'Wysyłanie…';

  @override
  String get sendReport => 'Wyślij zgłoszenie';

  @override
  String get sleepRecovery => 'Sen i regeneracja';

  @override
  String get activitiesTraining => 'Aktywności i trening';

  @override
  String get bodyWellness => 'Ciało i samopoczucie';

  @override
  String get hilo => 'Hilo';

  @override
  String get hiloBle => 'Hilo BLE';

  @override
  String get garminApi => 'Garmin (API)';

  @override
  String get renphoScale => 'Waga Renpho';

  @override
  String get connected => 'Połączono';

  @override
  String get notConnected => 'Niepołączono';

  @override
  String get manage => 'Zarządzaj';

  @override
  String get connect => 'Połącz';

  @override
  String get habits => 'Nawyki';

  @override
  String get smokingAlcohol => 'Palenie, alkohol';

  @override
  String get clinicalLab => 'Badania laboratoryjne';

  @override
  String get hba1cLipidsKidney => 'HbA1c, lipidy, nerki';

  @override
  String get sex => 'Płeć';

  @override
  String get smoking => 'Palenie';

  @override
  String get never => 'Nigdy';

  @override
  String get former => 'W przeszłości';

  @override
  String get current => 'Obecnie';

  @override
  String get hba1c => 'HbA1c';

  @override
  String get diabetes => 'Cukrzyca';

  @override
  String get prediabetes => 'Stan przedcukrzycowy';

  @override
  String get type1 => 'Typ 1';

  @override
  String get type2 => 'Typ 2';

  @override
  String get apob => 'ApoB';

  @override
  String get optionalPlansAndPaceGuides =>
      'Opcjonalnie. Korzystają z tego plany i wskazówki tempa; przewyższenie powyżej także kształtuje trening.';

  @override
  String get addRaceGoal2 => 'Dodaj cel startowy';

  @override
  String get editRaceGoal => 'Edytuj cel startowy';

  @override
  String get trailRunning2 => 'Bieganie w terenie';

  @override
  String get roadCycling => 'Kolarstwo szosowe';

  @override
  String get gravel => 'Gravel';

  @override
  String get indoorRowing => 'Wioślarstwo halowe';

  @override
  String get selectDate => 'Wybierz datę';

  @override
  String get committed => 'Pewny';

  @override
  String get flexible => 'Elastyczny';

  @override
  String get notGoing => 'Nie startuję';

  @override
  String get notSaid => 'Nie podano';

  @override
  String get finish => 'Ukończyć';

  @override
  String get saveGoal => 'Zapisz cel';

  @override
  String get exportAllRecordedWorkoutsAs =>
      'Eksportuj wszystkie zapisane treningi jako arkusz kalkulacyjny.';

  @override
  String get backupsIncludeYourHealthData =>
      'Kopie zapasowe obejmują dane o zdrowiu, plany treningowe i ustawienia profilu. Dane logowania są pomijane. Przywrócenie zastępuje dane lokalne.';

  @override
  String get trail => 'Teren';

  @override
  String get inlineSkating => 'Jazda na rolkach';

  @override
  String get nordicClassic => 'Narciarstwo biegowe klasyczne';

  @override
  String get skateSkiing => 'Narciarstwo biegowe łyżwowe';

  @override
  String get strength => 'Siła';

  @override
  String get walking => 'Chodzenie';

  @override
  String get yoga => 'Joga';

  @override
  String get skiing => 'Narciarstwo';

  @override
  String get climbing => 'Wspinaczka';

  @override
  String get monday => 'Poniedziałek';

  @override
  String get sunday => 'Niedziela';

  @override
  String get month => 'Miesiąc';

  @override
  String get week => 'Tydzień';

  @override
  String get list => 'Lista';

  @override
  String get train => 'Trening';

  @override
  String get restDay => 'Odpoczynek';

  @override
  String get kilogramsKg => 'Kilogramy (kg)';

  @override
  String get poundsLb => 'Funty (lb)';

  @override
  String get regenerateWorkouts => 'Wygeneruj treningi ponownie';

  @override
  String get starting => 'Uruchamianie';

  @override
  String get allPlannedWorkoutsDeleted =>
      'Usunięto wszystkie zaplanowane treningi.';

  @override
  String get searching => 'Wyszukiwanie…';

  @override
  String get searchCity => 'Szukaj miasta';

  @override
  String get fixedLocationSavedWeatherWill =>
      'Zapisano stałą lokalizację. Pogoda zostanie odświeżona.';

  @override
  String get locationDisabledThePlanWeather =>
      'Lokalizacja wyłączona. Karta pogody w planie jest ukryta.';

  @override
  String locationSetToName(Object name) {
    return 'Ustawiono lokalizację: $name';
  }

  @override
  String get notEnoughDaytimeAndNighttime =>
      'Za mało pomiarów dziennych i nocnych';

  @override
  String get onlyTheWeightWasReceived =>
      'Odebrano tylko wagę. Aby zmierzyć tkankę tłuszczową, mięśnie i inne wartości, stań boso na metalowych elektrodach i zejdź dopiero, gdy waga skończy.';

  @override
  String get addYourWaistInProfile =>
      'Dodaj obwód talii w profilu, aby oszacować tłuszcz trzewny.';

  @override
  String get manualActivity => 'Aktywność ręczna';

  @override
  String get theseCredentialsAreStoredEncrypted =>
      'Te dane logowania są przechowywane w postaci zaszyfrowanej na Twoim urządzeniu (pęk kluczy iOS / Android Keystore). Nigdy nie są wysyłane na serwery inne niż Hilo.';

  @override
  String get corosCredentialsAreStoredEncrypted =>
      'Dane logowania Coros są przechowywane w postaci zaszyfrowanej na Twoim urządzeniu. Fjelia odczytuje dane bezpośrednio z chmurowego API Coros. To samo API wykorzystuje aplikacja internetowa Coros Training Hub.';

  @override
  String get connectAnyCombinationYouCan =>
      'Połącz dowolny zestaw — zawsze możesz dodać więcej później w Ustawieniach.';

  @override
  String get garminCredentialsAreStoredEncrypted =>
      'Dane logowania Garmin są przechowywane w postaci zaszyfrowanej na Twoim urządzeniu. Fjelia korzysta z nieoficjalnego API Garmin Connect – tak samo jak wiele aplikacji społeczności.';

  @override
  String get enterTheVerificationCode => 'Wpisz kod weryfikacyjny';

  @override
  String get appleHealthDataAccess =>
      'Fjelia odczytuje Twoje dane o zdrowiu z Apple Zdrowie. Za Twoją zgodą może też zapisywać tam zsynchronizowane dane. Dostępem zarządzasz w ustawieniach urządzenia.';

  @override
  String get scanAgain => 'Szukaj ponownie';

  @override
  String get wearTheHiloBandDuring =>
      'Noś opaskę Hilo podczas snu, aby stale rejestrować ciśnienie. Dane synchronizują się automatycznie każdego ranka po otwarciu aplikacji.';

  @override
  String get noPolarH10FoundWear2 =>
      'Nie znaleziono Polar H10. Załóż pas z wilgotnymi elektrodami, upewnij się, że nie jest połączony z inną aplikacją (ani zegarkiem), i wyszukaj ponownie.';

  @override
  String get wearTheStrapWithMoist2 =>
      'Przed wyszukiwaniem załóż pas z wilgotnymi elektrodami. Później mierz przez + → Pomiar HRV Polar H10; wyniki pojawią się obok nocnego HRV.';

  @override
  String get signedInPlannedWorkoutsCan =>
      'Zalogowano. Zaplanowane treningi można teraz wysyłać do Polar. Starsze treningi zostaną zaimportowane przy następnej pełnej synchronizacji historii.';

  @override
  String get saveYourPolarFlowLogin =>
      'Zapisz login Polar Flow, aby wysyłać zaplanowane treningi i importować treningi starsze niż 30 dni. Pozostaje w pęku kluczy tego urządzenia i jest wysyłany tylko do Polar. Wyślij trening z jego karty w planie, a następnie zsynchronizuj Polar Flow z zegarkiem. Sprawdź, czy strefy tętna w Polar zgadzają się z Fjelia.';

  @override
  String get signInToSendThis =>
      'Zaloguj się, aby wysłać ten trening do kalendarza Polar Flow. Twój login pozostaje w pęku kluczy tego urządzenia i jest wysyłany tylko do Polar. Po wysłaniu zsynchronizuj Polar Flow z zegarkiem.';

  @override
  String get checkAndSave => 'Sprawdź i zapisz';

  @override
  String get noScaleFoundStepOn =>
      'Nie znaleziono wagi. Stań na wadze, aby się wybudziła, i wyszukaj ponownie.';

  @override
  String get stepOnTheScaleBefore =>
      'Przed wyszukiwaniem stań na wadze, aby się wybudziła. Później mierz przez + → Waga RENPHO.';

  @override
  String get renphoCredentialsAreStoredEncrypted =>
      'Dane logowania Renpho są przechowywane w postaci zaszyfrowanej na Twoim urządzeniu. Fjelia łączy się bezpośrednio z chmurowym API Renpho.';

  @override
  String get couldNotSendSmsCheck =>
      'Nie udało się wysłać SMS-a. Sprawdź numer telefonu i połączenie z internetem.';

  @override
  String get theEmailIsUsedFor =>
      'E-mail służy do bezpiecznego podpisywania żądań i nie jest wysyłany na serwery Suunto.';

  @override
  String get suuntoUsesSmsVerificationSame =>
      'Suunto używa weryfikacji SMS (tak jak aplikacja Suunto). Na Twój telefon zostanie wysłany jednorazowy PIN. Dane logowania są przechowywane w postaci zaszyfrowanej wyłącznie na urządzeniu.';

  @override
  String get tellUsAboutYourRace =>
      'Opowiedz nam o swoim starcie i harmonogramie. Fjelia tworzy plan od razu i ustala Twój poziom na podstawie wcześniejszych aktywności (Garmin, Suunto, Polar, COROS, Apple Zdrowie), gdy zostaną pobrane.';

  @override
  String get noAccountConnectedSoFjelia =>
      'Nie połączono żadnego konta, więc Fjelia nie ma historii, z której mogłaby się uczyć. Połącz Garmin, Suunto, Polar, COROS lub Apple Zdrowie, a o poziomie zdecyduje Twój prawdziwy trening.';

  @override
  String get yourPastActivitiesAreStill =>
      'Twoje wcześniejsze aktywności są nadal importowane. Możesz już utworzyć plan — zostanie automatycznie dopracowany po zakończeniu importu.';

  @override
  String get buildingYourPlan => 'Tworzenie planu…';

  @override
  String get saveContinue => 'Zapisz i kontynuuj';

  @override
  String get addYourMainPriorityA =>
      'Dodaj swój główny start (priorytet A). Plan jest do niego okresowany: baza, budowanie, szczyt i taper. Bez celu startowego plan nie zostanie jeszcze utworzony.';

  @override
  String get noMeasurementsYet => 'Brak pomiarów';

  @override
  String get date => 'Data';

  @override
  String deepSleepIsBelowOptimal(Object round) {
    return 'Sen głęboki jest poniżej optimum ($round%). Unikaj alkoholu i ciężkich posiłków na 3 h przed snem.';
  }

  @override
  String get finishWithSetsOpen => 'Zakończyć z otwartymi seriami?';

  @override
  String get completeThePlannedWorkout => 'Ukończyć zaplanowany trening?';

  @override
  String get marksThePlannedSessionAs =>
      'Oznacza zaplanowany trening jako wykonany tym treningiem.';

  @override
  String get discardThisWorkout => 'Odrzucić ten trening?';

  @override
  String get removesTheWorkoutAndEvery =>
      'Usuwa trening i wszystkie zapisane w nim serie.';

  @override
  String assistanceName(Object name) {
    return 'Wspomaganie ($name)';
  }

  @override
  String get enterSecondsOrMSs => 'Wpisz sekundy lub m:ss.';

  @override
  String get enterTheLoadAsA => 'Wpisz obciążenie jako liczbę.';

  @override
  String get loadCannotBeNegative => 'Obciążenie nie może być ujemne.';

  @override
  String get enterTheEffortValue => 'Wpisz wartość wysiłku.';

  @override
  String get nameTheExercise => 'Nazwij ćwiczenie.';

  @override
  String get atLeastOneImplement => 'Co najmniej jeden przybór.';

  @override
  String get anIncrementMustBePositive => 'Krok musi być dodatni.';

  @override
  String get enterAPositiveStep => 'Wpisz dodatni krok.';

  @override
  String get repsInReserve => 'Powtórzenia w zapasie';

  @override
  String get loadPerImplement => 'Obciążenie na przybór';

  @override
  String get restAfterThisSet => 'Przerwa po tej serii';

  @override
  String get enterHowLongTheSet => 'Wpisz, jak długo trwała seria.';

  @override
  String get repsDonePerSide => 'Wykonane powtórzenia na stronę';

  @override
  String plannedRepminRepmax(Object repMin, Object repMax) {
    return 'Planowo $repMin–$repMax';
  }

  @override
  String get restTakenBeforeTheNext => 'Przerwa przed następną serią';

  @override
  String get equipment => 'Sprzęt';

  @override
  String get implementsUsedTogether => 'Przybory używane razem';

  @override
  String get smallestLoadStepOptional =>
      'Najmniejszy krok obciążenia (opcjonalnie)';

  @override
  String get theSmallestChangeYourPlates =>
      'Najmniejsza zmiana, na jaką pozwalają Twoje talerze, hantle lub maszyna, zapamiętana dla tego sprzętu.';

  @override
  String get loadStep => 'Krok obciążenia';

  @override
  String get finishWithIncompleteData => 'Zakończyć z niepełnymi danymi?';

  @override
  String get leaveWithoutSaving => 'Wyjść bez zapisywania?';

  @override
  String get theLastChangeCouldNot => 'Nie udało się zapisać ostatniej zmiany.';

  @override
  String get comparedWithAPlanChosen =>
      'W porównaniu z planem wybranym po treningu. Planowane wartości to wskazówki, nie wyniki.';

  @override
  String get lastSet => 'Ostatnia seria';

  @override
  String get templateName => 'Nazwa szablonu';

  @override
  String get betweenExercises => 'Między ćwiczeniami';

  @override
  String get betweenRounds => 'Między rundami';

  @override
  String get discardChanges => 'Odrzucić zmiany?';

  @override
  String get yourEditsToThisWorkout =>
      'Twoje zmiany w tym treningu nie zostały zapisane.';

  @override
  String get estimatedDuration => 'Szacowany czas';

  @override
  String get workingSets => 'Serie robocze';

  @override
  String get estimatedExternalVolume => 'Szacowana objętość zewnętrzna';

  @override
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion) {
    return 'Obciążenie zwiększone z $unit do $unit2 po Twojej ocenie (reguła v$ruleVersion).';
  }

  @override
  String get thePlannedWorkoutHasNo =>
      'Zaplanowany trening nie ma ćwiczeń do zapisania.';

  @override
  String get completedSets => 'Ukończone serie';

  @override
  String get knownExternalVolume => 'Znana objętość zewnętrzna';

  @override
  String get updateStrengthSessions2 => 'Zaktualizować treningi siłowe?';

  @override
  String get upcomingSessionsArePlannedAgain =>
      'Nadchodzące treningi są planowane od dziś na nowo: trening siłowy w każdym dniu siłowym odpowiada Twoim celom startowym i jest zróżnicowany. Ukończone i pominięte treningi zostają; ćwiczenia zmienione w nadchodzącym treningu siłowym zostaną zastąpione.';

  @override
  String get thisSessionUsesAnEarlier =>
      'Ten trening korzysta ze starszego szablonu siłowego. Zaktualizowane plany różnicują siłę według fazy i celu startowego i wykorzystują każdy dzień siłowy.';

  @override
  String get estimated1rmUsesEpleyAnd =>
      'Szacowane 1RM korzysta ze wzorów Epleya i Brzyckiego dla ukończonych serii roboczych 1–10 powtórzeń ze znanym obciążeniem i jest pokazywane jako zakres między nimi. To szacunek, a nie zmierzone maksimum.';

  @override
  String get localWeather => 'Lokalna pogoda';

  @override
  String get today => 'Dziś';

  @override
  String get low => 'Niski';

  @override
  String get moderate => 'Umiarkowany';

  @override
  String get overcast => 'Pochmurno';

  @override
  String get partlyCloudy => 'Częściowe zachmurzenie';

  @override
  String collapseName(Object name) {
    return 'Zwiń $name';
  }

  @override
  String get variableLoads => 'Zmienne obciążenia';

  @override
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  ) {
    return 'Reguła v$strengthProgressionRuleVersion: ostatnie $strengthProgressionMinSessions porównywalnych treningów, każda seria wykonana na górnej granicy docelowych powtórzeń, z zapisanym wysiłkiem i nie ciężej, niż zakładano. $reason';
  }

  @override
  String get stepOnYourScaleBefore => 'Stań na wadze przed wyszukiwaniem';

  @override
  String get scanning => 'Wyszukiwanie…';

  @override
  String get pair => 'Sparuj';

  @override
  String get selectYourAktiiaPWristband =>
      'Wybierz opaskę AKTIIA P…. Jeśli jej nie widać, połóż ją na ładowarce, aby się wybudziła.';

  @override
  String get measurementInterruptedWhileTheApp =>
      'Pomiar przerwano, gdy aplikacja działała w tle. Powtórz go.';

  @override
  String get noRecentRrDataWith =>
      'Brak świeżych danych RR z dobrym kontaktem. Sprawdź pas i powtórz pomiar.';

  @override
  String get settlingStayStill => 'Uspokajanie · nie ruszaj się';

  @override
  String get deleteSpotHrvMeasurement => 'Usunąć punktowy pomiar HRV?';

  @override
  String get thisRemovesTheRecordingAnd =>
      'Usuwa nagranie i jego surowe odstępy RR.';

  @override
  String get appleHealthStoppedAnsweringSo =>
      'Apple Zdrowie przestało odpowiadać, więc Fjelia je rozłączyła i nie odczytuje ani nie zapisuje już danych zdrowotnych.\n\nPonownie zezwól Fjelia w Ustawienia → Zdrowie → Dostęp do danych i urządzenia → Fjelia, a następnie ponownie połącz Apple Zdrowie.';

  @override
  String get thisRemovesTheSelectedGrip => 'Usuwa wybrany pomiar siły chwytu.';

  @override
  String get hideReminderDiagnostics => 'Ukryj diagnostykę przypomnień';

  @override
  String get loading => 'Wczytywanie…';

  @override
  String get touchTheChartForDetails =>
      'Dotknij wykresu, aby zobaczyć szczegóły';

  @override
  String get indoor => 'W pomieszczeniu';

  @override
  String get road => 'Szosa';

  @override
  String get technical => 'Techniczny';

  @override
  String get snow => 'Śnieg';

  @override
  String get pool => 'Basen';

  @override
  String get openWater => 'Wody otwarte';

  @override
  String get ambientTemperatureC => 'Temperatura otoczenia °C';

  @override
  String carryAboutGelsGelsGelcarbs(
    Object gels,
    Object gelCarbs,
    Object bottles,
    Object bottleMl,
    Object drinkCarbs,
  ) {
    return 'Zabierz około $gels żeli (po $gelCarbs g węglowodanów) + $bottles × bidony $bottleMl ml. $drinkCarbs g węglowodanów pochodzi z napoju.';
  }

  @override
  String get intakeNotRecorded => 'Spożycie niezapisane';

  @override
  String get loggingDeclinedIntakeUnknown =>
      'Odmówiono zapisu — spożycie nieznane';

  @override
  String get confirmedNoIntake => 'Potwierdzono: brak spożycia';

  @override
  String get draft => 'Szkic · ';

  @override
  String get actualIntakePerServing => 'Faktyczne spożycie · na porcję';

  @override
  String get minuteIntoWorkoutDuringOnly =>
      'Minuta treningu (tylko w trakcie, opcjonalnie)';

  @override
  String get sodiumMgServingNotSalt => 'Sód mg / porcja (nie sól)';

  @override
  String get comfortable => 'Komfortowo';

  @override
  String get mildSymptoms => 'Łagodne objawy';

  @override
  String get moderateSymptoms => 'Umiarkowane objawy';

  @override
  String get severeSymptoms => 'Silne objawy';

  @override
  String get personalNutritionSettings => 'Osobiste ustawienia żywienia';

  @override
  String get practisedCarbohydrateToleranceGH =>
      'Wytrenowana tolerancja węglowodanów g/h (do 120)';

  @override
  String get exportTheMonthlyReportAs =>
      'Wyeksportuj miesięczny raport jako PDF w aplikacji Hilo i wybierz go tutaj. Importowane są tylko pomiary; imię, e-mail i dane ciała w raporcie są ignorowane.';

  @override
  String get nothingNewAllReadingsWere =>
      'Nic nowego: wszystkie pomiary były już zapisane.';

  @override
  String get historyImportIncomplete => 'Import historii niekompletny';

  @override
  String get youCanKeepUsingFjelia =>
      'Możesz dalej korzystać z Fjelia, ale nie zamykaj jej: iOS wstrzymuje import, gdy aplikacja działa w tle, i wznawia go przy następnym otwarciu Fjelia. Plan zostanie skalibrowany po zakończeniu importu.';

  @override
  String get addYourBirthYearIn =>
      'Dodaj rok urodzenia w Ustawienia → Profil, aby zobaczyć swój szacunek.';

  @override
  String get fitnessAge => 'Wiek sprawności';

  @override
  String get estLifespan => 'Szac. długość życia';

  @override
  String get delta => 'Różnica';

  @override
  String couldNotOpenKey(Object key) {
    return 'Nie udało się otworzyć $key';
  }

  @override
  String get appleIntelligenceIsNotAvailable =>
      'Apple Intelligence nie jest dostępne na tym urządzeniu. Użyj Free AI lub wybierz innego dostawcę.';

  @override
  String get personalisedMorningLunchAfternoonEvening =>
      'Spersonalizowane podsumowanie poranne/południowe/popołudniowe/wieczorne';

  @override
  String get enterASubject => 'Wpisz temat.';

  @override
  String get message => 'Wiadomość';

  @override
  String get enterAMessageOfAt =>
      'Wpisz wiadomość o długości co najmniej 10 znaków.';

  @override
  String get garminConnect => 'Garmin Connect';

  @override
  String get hiloBloodPressure => 'Hilo (ciśnienie krwi)';

  @override
  String get renphoBodyScale => 'Renpho (waga)';

  @override
  String get hiloPodCuff => 'Hilo pod / mankiet';

  @override
  String disconnectLabel(Object label) {
    return 'Rozłączyć $label?';
  }

  @override
  String get yourSavedMeasurementsWillRemain =>
      'Twoje zapisane pomiary pozostaną na tym urządzeniu.';

  @override
  String get notEnoughRecentHeartRate =>
      'Za mało świeżych danych tętna, aby dostosować strefy.';

  @override
  String get aerobicBase => 'Baza tlenowa';

  @override
  String get tempo => 'Tempo';

  @override
  String get lactateThreshold => 'Próg mleczanowy';

  @override
  String get birthYearHeightWaist => 'Rok urodzenia, wzrost, talia';

  @override
  String get enterAValidValue => 'Wpisz prawidłową wartość';

  @override
  String get birthYear => 'Rok urodzenia';

  @override
  String get height => 'Wzrost';

  @override
  String get waist => 'Talia';

  @override
  String get yearsSinceQuit => 'Lata od rzucenia';

  @override
  String get cigarettesPerDay => 'Papierosy dziennie';

  @override
  String get standardDrinksPerMonth => 'Standardowe drinki miesięcznie';

  @override
  String get enterAValidNumber => 'Wpisz prawidłową liczbę';

  @override
  String get enterARaceName => 'Wpisz nazwę startu';

  @override
  String get useHMmOrH =>
      'Użyj h:mm lub h:mm:ss, czasu, który naprawdę możesz uzyskać';

  @override
  String get flexibleThePlanMayDrop =>
      'Elastyczny: plan może pominąć to wydarzenie, jeśli koliduje z ważniejszym.';

  @override
  String get selectARaceDate => 'Wybierz datę startu';

  @override
  String thatIsTenTimesOr(Object likely) {
    return 'To dziesięć razy więcej (lub dziesięć razy mniej) niż zwykłe $likely km. Użyć $likely km?';
  }

  @override
  String get addGoal => 'Dodaj cel';

  @override
  String get restoreFailed => 'Przywracanie nie powiodło się';

  @override
  String get replaceLocalData => 'Zastąpić dane lokalne?';

  @override
  String get restoringThisBackupReplacesAll =>
      'Przywrócenie tej kopii zastępuje wszystkie lokalne dane o zdrowiu i treningach. Istniejące dane logowania zostają zachowane.';

  @override
  String get openingBackupZip => 'Otwieranie pliku ZIP kopii';

  @override
  String get addAFutureRaceGoal => 'Najpierw dodaj przyszły cel startowy.';

  @override
  String get deleteAllWorkouts2 => 'Usunąć wszystkie treningi?';

  @override
  String get thisDeletesPlannedWorkoutsOn =>
      'Usuwa zaplanowane treningi z tego telefonu i z połączonej platformy zegarka. Ukończone aktywności zostają zachowane.';

  @override
  String get regenerateWorkouts2 => 'Wygenerować treningi ponownie?';

  @override
  String get noRaceGoalsYetAdd =>
      'Brak celów startowych. Dodaj cel lub zsynchronizuj z Garmin.';

  @override
  String get deleteRaceGoal => 'Usunąć cel startowy?';

  @override
  String deletingFailedFailure(Object failure) {
    return 'Usuwanie nie powiodło się: $failure';
  }

  @override
  String allPlannedWorkoutsDeletedRemoved(Object removed) {
    return 'Usunięto wszystkie zaplanowane treningi. Usunięto z platform: $removed.';
  }

  @override
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return 'Używana bieżąca lokalizacja: $toStringAsFixed, $toStringAsFixed2';
  }

  @override
  String get typeSleep => 'Sen';

  @override
  String get typeBloodPressure => 'Ciśnienie krwi';

  @override
  String get addHiloBpReportPdf => 'Dodaj raport ciśnienia Hilo (PDF)';

  @override
  String get hiloCuffBle => 'Mankiet Hilo (BLE)';

  @override
  String get typeSpo2 => 'SpO₂ / pulsoksymetr';

  @override
  String get typeWeightScale => 'Waga';

  @override
  String get polarH10HrvMeasurement => 'Pomiar HRV Polar H10';

  @override
  String samplingWouldStartMinutes(Object minutes) {
    return 'Pomiar zacząłby się około $minutes min po zakończeniu treningu.';
  }

  @override
  String samplingStartedMinutes(Object minutes) {
    return 'Pomiar zaczął się $minutes min po zakończeniu treningu.';
  }

  @override
  String get unknown => 'Nieznane';

  @override
  String get before => 'Przed';

  @override
  String get during => 'W trakcie';

  @override
  String get after => 'Po';

  @override
  String get enumWarmUp => 'Rozgrzewka';

  @override
  String get enumWorking => 'Robocza';

  @override
  String get enumBackOff => 'Odciążenie';

  @override
  String get enumTechnique => 'Technika';

  @override
  String get enumExternalLoad => 'Obciążenie zewnętrzne';

  @override
  String get enumBandResistance => 'Guma / opór';

  @override
  String get enumTotalLoad => 'Obciążenie łączne';

  @override
  String get enumPerImplement => 'Na przybór';

  @override
  String get enumOneImplement => 'Jeden przybór';

  @override
  String get enumBothSides => 'Obie strony';

  @override
  String get enumAlternatingTotalReps => 'Naprzemiennie, łączne powtórzenia';

  @override
  String get enumPartial => 'Częściowa';

  @override
  String get enumFailed => 'Nieudana';

  @override
  String get enumStraightSets => 'Serie proste';

  @override
  String get enumSuperset => 'Superseria';

  @override
  String get enumCircuit => 'Obwód';

  @override
  String get enumRir => 'RIR';

  @override
  String get enumRpe110 => 'RPE 1–10';

  @override
  String get enumBeforeTraining => 'Przed treningiem';

  @override
  String get enumAfterTraining => 'Po treningu';

  @override
  String get enumResting => 'W spoczynku';

  @override
  String get enumSeated => 'Siedząc';

  @override
  String get enumLyingDown => 'Leżąc';

  @override
  String get duringRoutineGelsAreNot =>
      'W trakcie: przy tym krótkim/lekkim treningu żele nie są potrzebne. Pij według pragnienia.';

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      'W trakcie: rozłóż węglowodany i picie na małe, regularne porcje. Wliczaj węglowodany z napoju do tej samej sumy co żele i jedzenie.';

  @override
  String get fluidIsAnEditableStarting =>
      'Płyny to edytowalny szacunek początkowy, nie norma. Kieruj się pragnieniem, wytrenowanym spożyciem i zmierzoną utratą potu; nie zmuszaj się do dodatkowej wody.';

  @override
  String get afterHaveCarbohydrateAndA =>
      'Po: zjedz węglowodany i posiłek z białkiem. Gdy wkrótce czeka Cię kolejny trening, postaw na uzupełnienie energii i nawodnienie.';

  @override
  String get swimmingPlaceALabelledBottle =>
      'Pływanie: postaw podpisany bidon na brzegu basenu i pij lub jedz w przerwach między seriami. Warunki na basenie mogą się różnić od pogody na zewnątrz.';

  @override
  String get runningCarryAccessibleGelsFlasks =>
      'Bieganie: miej pod ręką żele/bidony lub zaplanuj jedzenie na punktach odżywczych; przećwicz te same produkty i porę przed startem.';

  @override
  String get servingSizesAndToleranceMust =>
      'Wielkość porcji i tolerancja muszą być dodatnie.';

  @override
  String get enterFiniteNonNegativeMeasurements =>
      'Wpisz skończone, nieujemne wartości.';

  @override
  String get targetsMustBeFiniteAnd => 'Cele muszą być skończone i nieujemne.';

  @override
  String get conditionsMustBeFiniteOr =>
      'Warunki muszą być skończone lub nieznane.';

  @override
  String get humidityMustBeBetween0 => 'Wilgotność musi wynosić od 0 do 100%.';

  @override
  String get noIntakeCannotIncludeFood =>
      '„Brak spożycia” nie może zawierać jedzenia ani napojów.';

  @override
  String get addAnItemOrConfirm =>
      'Dodaj pozycję lub potwierdź, że nic nie spożyłeś.';

  @override
  String get eachIntakeNeedsAProduct =>
      'Każde spożycie wymaga produktu i prawidłowej pory.';

  @override
  String get quantityMustBePositive => 'Ilość musi być dodatnia.';

  @override
  String get thisActivityNoLongerExists => 'Ta aktywność już nie istnieje.';

  @override
  String get practisedCarbohydrateToleranceMustNot =>
      'Wytrenowana tolerancja węglowodanów nie może przekraczać 120 g/h.';

  @override
  String get measuredSweatRateMustBe =>
      'Zmierzona utrata potu musi być dodatnia lub pozostać nieznana.';

  @override
  String get increasePractisedToleranceInNutrition =>
      'Zanim wybierzesz wyższy cel, zwiększ wytrenowaną tolerancję w ustawieniach żywienia.';

  @override
  String get fluidTargetExceedsYourMeasured =>
      'Cel płynów przekracza zmierzoną utratę potu. Sprawdź pomiar lub cel.';

  @override
  String get elapsedWorkoutTimeMustBe =>
      'Czas treningu musi być dodatni lub pozostać pusty.';

  @override
  String get intakeAmountsMustBeFinite =>
      'Ilości spożycia muszą być skończone i nieujemne.';

  @override
  String get selectedStrategyUnavailableChooseAnother =>
      'Wybrana strategia jest niedostępna. Wybierz inną strategię lub brak porównania.';

  @override
  String get recordYourWorkoutNutrition => 'Zapisz żywienie podczas treningu';

  @override
  String get addTheFoodAndFluids =>
      'Dodaj do historii aktywności jedzenie i płyny, które faktycznie spożyłeś.';

  @override
  String get logIntake => 'Zapisz spożycie';

  @override
  String nutritionReminderTitle(String name) {
    return 'Nowa aktywność: $name';
  }

  @override
  String get nutritionReminderBody => 'Dodaj, co zjadłeś i wypiłeś.';

  @override
  String get nutritionReminderHrvHint =>
      'Twoje HRV po treningu nie zostało jeszcze zmierzone.';

  @override
  String get in30Minutes => 'Za 30 minut';

  @override
  String get loadSuggestionsCoverStraightSets =>
      'Sugestie obciążenia dotyczą tylko serii prostych z powtórzeniami.';

  @override
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  ) {
    return 'Wymaga $strengthProgressionMinSessions zapisanych treningów tego ćwiczenia.';
  }

  @override
  String get recentHistoryIsTooOld =>
      'Ostatnia historia jest za stara na sugestię.';

  @override
  String get theLastSessionDidNot =>
      'Ostatni trening nie miał jednego znanego obciążenia.';

  @override
  String get theLoadChangedBetweenThe =>
      'Obciążenie zmieniało się między ostatnimi treningami.';

  @override
  String get notEverySetReachedThe =>
      'Nie każda seria osiągnęła górną granicę docelowych powtórzeń.';

  @override
  String get recordEffortRirOrRpe =>
      'Zapisz wysiłek (RIR lub RPE) w ostatniej serii, aby otrzymywać sugestie.';

  @override
  String get recentSetsWereHarderThan =>
      'Ostatnie serie były cięższe, niż zakładano.';

  @override
  String get thisWorkoutAlreadyHasIts =>
      'Ten trening ma już własne obciążenie; pozostaje bez zmian.';

  @override
  String get yourRecentSetsMetThe =>
      'Twoje ostatnie serie spełniły regułę progresji. Ustaw najmniejszy krok obciążenia dla tego sprzętu, aby ocenić obciążenie.';

  @override
  String get thisWorkoutNoLongerExists => 'Ten trening już nie istnieje.';

  @override
  String thisStrengthPlanCannotBe(Object message) {
    return 'Nie można odczytać tego planu siłowego ($message).';
  }

  @override
  String get thisStrengthPlanCannotBe2 =>
      'Nie można odczytać tego planu siłowego.';

  @override
  String get addAtLeastOneExercise => 'Dodaj co najmniej jedno ćwiczenie.';

  @override
  String get thisWorkoutWasChangedElsewhere =>
      'Ten trening został zmieniony gdzie indziej. Twoje zmiany zostają zachowane; wczytaj ponownie, aby zobaczyć nowszą wersję.';

  @override
  String get thePlanThisWorkoutIs =>
      'Nie można odczytać planu, z którym porównywany jest ten trening.';

  @override
  String get thisLogWasChangedElsewhere =>
      'Ten zapis został zmieniony gdzie indziej. Twoje wpisy zostają zachowane; wczytaj ponownie, aby zobaczyć nowszą wersję.';

  @override
  String get thisZipIsNotA =>
      'Ten plik ZIP nie jest obsługiwaną kopią zapasową Fjelia.';

  @override
  String get theBackupDatabaseIsDamaged =>
      'Baza danych kopii zapasowej jest uszkodzona.';

  @override
  String get invalidBackupData => 'Nieprawidłowe dane kopii zapasowej.';

  @override
  String get backupTablesDoNotMatch =>
      'Tabele kopii zapasowej się nie zgadzają.';

  @override
  String get invalidBackupColumns => 'Nieprawidłowe kolumny kopii zapasowej.';

  @override
  String get migratingOriginalAppBackup =>
      'Przenoszenie kopii zapasowej z oryginalnej aplikacji';

  @override
  String get theOriginalBackupIsMissing =>
      'W oryginalnej kopii zapasowej brakuje wymaganych tabel.';

  @override
  String get backupFormatOrDatabaseVersion =>
      'Format kopii zapasowej lub wersja bazy danych się nie zgadza.';

  @override
  String get restoringRecords => 'Przywracanie danych';

  @override
  String get restoringSettings => 'Przywracanie ustawień';

  @override
  String get restoreComplete => 'Przywracanie zakończone';

  @override
  String get effortMustBeANumber => 'Wysiłek musi być liczbą.';

  @override
  String get theDurationEstimateMustBe => 'Szacowany czas musi być dodatni.';

  @override
  String get restCannotBeNegative => 'Przerwa nie może być ujemna.';

  @override
  String get enterTheRepetitionsDoneThe =>
      'Wpisz wykonane powtórzenia; plan podaje zakres.';

  @override
  String get enterTheLoadThePlan => 'Wpisz obciążenie; plan go nie podaje.';

  @override
  String get enterTheResistanceThePlan => 'Wpisz opór; plan go nie podaje.';

  @override
  String get poorSensorContact => 'Słaby kontakt czujnika';

  @override
  String get moreThan25FromLocal => 'Ponad 25% od lokalnej mediany';

  @override
  String get workoutNutrition => 'Żywienie treningowe';

  @override
  String get postWorkoutFoodAndFluid =>
      'Przypomnienie o zapisie jedzenia i płynów po treningu';

  @override
  String get postTrainingHrvMeasurementReminder =>
      'Przypomnienie o pomiarze HRV po treningu';

  @override
  String get rirRunsFrom0To => 'RIR wynosi od 0 do 10+.';

  @override
  String get rpeRunsFrom1To => 'RPE wynosi od 1 do 10.';

  @override
  String get repetitionsCannotBeNegative => 'Powtórzenia nie mogą być ujemne.';

  @override
  String get timedWorkMustBeLonger =>
      'Praca na czas musi trwać dłużej niż zero sekund.';

  @override
  String get chooseRepetitionsOrTimedWork =>
      'Wybierz powtórzenia lub pracę na czas, nie oba.';

  @override
  String get loadMustBeAFinite =>
      'Obciążenie musi być skończoną, nieujemną liczbą.';

  @override
  String get durationCannotBeNegative => 'Czas trwania nie może być ujemny.';

  @override
  String get hrTimeline => 'Przebieg tętna';

  @override
  String get dayTrainingLoad => 'Obciążenie treningowe dnia';

  @override
  String get weekdayComparison => 'Porównanie dni tygodnia';

  @override
  String get weeklyTrainingLoad => 'Tygodniowe obciążenie treningowe';

  @override
  String get zonePolarization => 'Polaryzacja stref';

  @override
  String get elevationOverview => 'Przegląd przewyższeń';

  @override
  String get trainingMonitor => 'Monitor treningu';

  @override
  String get formAtlCtlTsb => 'Forma ATL / CTL / TSB';

  @override
  String get trainingPlanProgress => 'Postęp planu treningowego';

  @override
  String get rhrSleep => 'Tętno spoczynkowe we śnie';

  @override
  String get hrvSleep => 'HRV we śnie';

  @override
  String get spo2Sleep => 'SpO₂ we śnie';

  @override
  String get respRate => 'Częstość oddechu';

  @override
  String get stress => 'Stres';

  @override
  String get skinTemp => 'Temperatura skóry';

  @override
  String get steps => 'Kroki';

  @override
  String get tonightsSleep => 'Sen tej nocy';

  @override
  String get activityLog => 'Dziennik aktywności';

  @override
  String get activityLog2 => 'Dziennik aktywności';

  @override
  String get history2 => 'HISTORIA';

  @override
  String durationsecondshDurationseconds2mDistancemetersKmAvgheartrate(
    Object durationSeconds,
    Object durationSeconds2,
    Object distanceMeters,
    Object avgHeartRate,
    Object totalElevation,
  ) {
    return '$durationSeconds h $durationSeconds2 min · $distanceMeters km · $avgHeartRate bpm · ↑$totalElevation m';
  }

  @override
  String get heatAcclimation2 => 'AKLIMATYZACJA DO UPAŁU';

  @override
  String score(Object score) {
    return '$score%';
  }

  @override
  String get elevation => 'PRZEWYŻSZENIE';

  @override
  String get t12WeekHistory => 'HISTORIA 12 TYGODNI';

  @override
  String get zonePolarization2 => 'POLARYZACJA STREF';

  @override
  String get t5WeekHistory => 'HISTORIA 5 TYGODNI';

  @override
  String get easy => 'LEKKO %';

  @override
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded) {
    return '$withZones z $recorded aktywności z danymi stref tętna';
  }

  @override
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples) {
    return '$fromSamples odtworzono z zapisanych próbek tętna';
  }

  @override
  String get easyZ12ModerateZ3 =>
      'Lekko: Z1–2 · Umiarkowanie: Z3 · Ciężko: Z4–5';

  @override
  String get activitiesWithoutHrZoneData =>
      'Aktywności bez danych stref tętna nie są wliczane do procentów.';

  @override
  String avgAverageUnit(Object average, Object unit) {
    return 'ŚR.  $average $unit';
  }

  @override
  String get weekdayComparison2 => 'PORÓWNANIE DNI TYGODNIA';

  @override
  String get trainingPlanProgress2 => 'POSTĘP PLANU TRENINGOWEGO';

  @override
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  ) {
    return 'Tydzień $currentWeek / $durationInWeeks';
  }

  @override
  String get t30MinTimeTrialLt2 => '30-MINUTOWA PRÓBA CZASOWA — LT2';

  @override
  String get run30MinutesAtThe =>
      'Biegnij 30 minut z największym wysiłkiem, jaki możesz utrzymać — kontrolowanie, bez sprintu. Wchodź w wysiłek stopniowo; nie zaczynaj za szybko. Średnie tempo i tętno z ostatnich 20 minut to Twój LT2.';

  @override
  String get recordAsANormalOutdoor =>
      'Zapisz jako zwykły bieg na zewnątrz. Włącz zegarek, zanotuj godzinę i biegnij 30 min w tempie startowym.';

  @override
  String get t50MinTotalFlatCourse =>
      '~50 min łącznie · płaska trasa · nie po ciężkim treningu';

  @override
  String get doNotStartTooFast =>
      'Nie zaczynaj za szybko. Celuj w równe międzyczasy.';

  @override
  String get theAppAveragesHrAnd =>
      'Aplikacja uśrednia tętno i tempo z ostatnich 20 minut próby, po rozgrzewce i pierwszych 10 minutach. Wybierz zapisaną aktywność w Oblicz.';

  @override
  String get lt2Pace => 'TEMPO LT2';

  @override
  String get activityRunningEnoughTimeFor =>
      'Aktywność (bieg, wystarczająco długi na rozgrzewkę + 30 min, z tętnem)';

  @override
  String get selectTheTtActivity => 'Wybierz aktywność z próbą';

  @override
  String nameStartdate(Object name, Object startDate) {
    return '$name · $startDate';
  }

  @override
  String get warmUpBeforeTt => 'Rozgrzewka przed próbą';

  @override
  String roundMin(Object round) {
    return '$round min';
  }

  @override
  String get clearResults => 'Wyczyść wyniki';

  @override
  String get heartRate2 => 'TĘTNO';

  @override
  String get paceSecKmLowerIs => 'TEMPO (s/km — mniej znaczy szybciej)';

  @override
  String get thresholdsFitnessTests => 'Progi i testy sprawności';

  @override
  String get lt1 => 'LT1';

  @override
  String get lt2 => 'LT2';

  @override
  String get voPace => 'Tempo VO₂';

  @override
  String get ftp => 'FTP';

  @override
  String get setFtpManually => 'Ustaw FTP ręcznie';

  @override
  String get calculateFromAnActivity => 'Oblicz z aktywności';

  @override
  String get setFtp => 'Ustaw FTP';

  @override
  String get ftpWatts => 'FTP (waty)';

  @override
  String get ftpCyclingThresholdPower => 'FTP — PROGOWA MOC W KOLARSTWIE';

  @override
  String get ftpHistory => 'HISTORIA FTP';

  @override
  String get updateFromActivity => 'AKTUALIZUJ Z AKTYWNOŚCI';

  @override
  String get tapAnActivityFtpBest =>
      'Dotknij aktywności — FTP = najlepsza moc z 20 min × 0,95';

  @override
  String ridew(Object ride) {
    return '$ride W';
  }

  @override
  String ftpRoundw(Object round) {
    return '→ FTP $round W';
  }

  @override
  String get noRidesWith20Minutes =>
      'Brak jazd z 20 minutami ciągłych danych mocy.';

  @override
  String get enterFtpManually => 'Wpisz FTP ręcznie';

  @override
  String get selectTheTestActivity => 'Wybierz aktywność testową';

  @override
  String get formAtlCtlTsb2 => 'FORMA · ATL / CTL / TSB';

  @override
  String get closeTrainingFormFullscreen =>
      'Zamknij formę treningową na pełnym ekranie';

  @override
  String get expandTrainingForm => 'Rozwiń formę treningową';

  @override
  String get calculatedFromTheFirstAvailable =>
      'Obliczono od pierwszego dostępnego zapisu obciążenia. Dni bez zapisanego obciążenia liczą się jako zero; wcześniejszy trening jest nieznany.';

  @override
  String get trainingMonitor2 => 'MONITOR TRENINGU';

  @override
  String get pfitzingerZones => 'STREFY PFITZINGERA';

  @override
  String get cyclingPowerZones => 'STREFY MOCY W KOLARSTWIE';

  @override
  String znumber(Object number) {
    return 'Z$number';
  }

  @override
  String paceHrDescription(Object pace, Object hr, Object description) {
    return '$pace · $hr\n$description';
  }

  @override
  String get weeklyTrainingLoad2 => 'TYGODNIOWE OBCIĄŻENIE TRENINGOWE';

  @override
  String get prevWeek => 'POPRZ. TYDZIEŃ';

  @override
  String get bySport => 'WG SPORTU';

  @override
  String get noActivitiesThisWeek => 'Brak aktywności w tym tygodniu';

  @override
  String garminWorkoutScheduleddate(Object scheduledDate) {
    return 'Trening Garmin · $scheduledDate';
  }

  @override
  String get yourNote => 'Twoja notatka';

  @override
  String get askAiCoach => 'Zapytaj trenera AI';

  @override
  String get aiSettings => 'Ustawienia AI';

  @override
  String get askYourCoach => 'Zapytaj trenera…';

  @override
  String get sendMessage => 'Wyślij wiadomość';

  @override
  String get sendFeedbackOrReportA => 'Wyślij opinię lub zgłoś błąd';

  @override
  String get addMeasurement2 => 'Dodaj pomiar';

  @override
  String get syncLabel2 => 'Synchronizuj';

  @override
  String get syncToday => 'Synchronizuj dziś';

  @override
  String get fullSync1Year => 'Pełna synchronizacja · 1 rok';

  @override
  String get fullSyncComplete => 'Pełna synchronizacja · zakończona';

  @override
  String get syncingYourData => 'Synchronizowanie danych…';

  @override
  String lLeftkgRRightkgKg2(Object leftKg, Object rightKg) {
    return 'L $leftKg  P $rightKg kg';
  }

  @override
  String weightKgFatBodyfatMuscle(
    Object weight,
    Object bodyFat,
    Object muscleMass,
  ) {
    return '$weight kg · Tłuszcz $bodyFat% · Mięśnie $muscleMass kg';
  }

  @override
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase) {
    return '$title, $sport, $toLowerCase';
  }

  @override
  String get weatherUnavailableTapToRetry =>
      'Pogoda niedostępna · Dotknij, aby ponowić';

  @override
  String get weatherSetYourLocation => 'Pogoda · Ustaw lokalizację';

  @override
  String get t7DayForecast => 'PROGNOZA NA 7 DNI';

  @override
  String get minMax => 'min/maks';

  @override
  String get rainMm2 => 'deszcz mm';

  @override
  String get uvMax => 'UV maks';

  @override
  String get kmH => 'km/h';

  @override
  String alt(Object alt) {
    return '→ $alt';
  }

  @override
  String raceGoalsLength(Object length) {
    return 'Cele startowe · $length';
  }

  @override
  String gWk(Object g) {
    return '$g tydz.';
  }

  @override
  String weeks(Object weeks) {
    return '$weeks';
  }

  @override
  String get weeks2 => 'tygodnie';

  @override
  String get upcoming => 'NADCHODZĄCE';

  @override
  String lengthMoreDays(Object length) {
    return '+ jeszcze $length dni';
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
      '○ Zaplanowane   ● Ukończone   ✕ Pominięte';

  @override
  String get heartRate3 => 'Tętno';

  @override
  String get watts => 'Waty';

  @override
  String theStepsAddUpTo(Object total, Object plannedDurationMin) {
    return 'Kroki sumują się do $total; plan liczy $plannedDurationMin min.';
  }

  @override
  String get typicalSplitForThisKind =>
      'Typowy podział dla tego rodzaju treningu; brak kroków, z których można by go obliczyć.';

  @override
  String labelGetsEachExerciseWith(Object label) {
    return '$label otrzymuje każde ćwiczenie z seriami, powtórzeniami i obciążeniami. Zakresy powtórzeń, wysiłek i tempo zostają w Fjelia.';
  }

  @override
  String get markAsRest => 'Oznacz jako odpoczynek';

  @override
  String get changeSport => 'Zmień sport';

  @override
  String get replacementSport => 'Sport zastępczy';

  @override
  String get replacementLoadNote =>
      'Czas trwania, planowane strefy tętna i cel obciążenia zostają zachowane. Cele tempa i mocy są dostosowywane do nowego sportu.';

  @override
  String replacementCalendarNote(String platforms) {
    return 'Pierwotny trening zostanie usunięty z tych kalendarzy treningowych: $platforms.';
  }

  @override
  String get applySportChange => 'Zaplanuj trening zastępczy';

  @override
  String get restoreWorkout => 'Przywróć trening';

  @override
  String get skipThisWorkout => 'Pominąć ten trening?';

  @override
  String get previousWeek => 'Poprzedni tydzień';

  @override
  String get backToThisWeek => 'Wróć do tego tygodnia';

  @override
  String get thisWeek => 'Ten tydzień';

  @override
  String get nextWeek => 'Następny tydzień';

  @override
  String get today2 => 'DZIŚ';

  @override
  String get route => 'TRASA';

  @override
  String get feedback => 'Opinia';

  @override
  String get plannedWorkout => 'Zaplanowany trening';

  @override
  String get delete => 'Usuń';

  @override
  String get chatAi => 'Czat AI';

  @override
  String get trainingLoad => 'Obciążenie treningowe';

  @override
  String get dayTrainingLoad2 => 'OBCIĄŻENIE TRENINGOWE DNIA';

  @override
  String get trimp => ' TRIMP';

  @override
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter) {
    return '$scoreBefore → $scoreAfter';
  }

  @override
  String get temperatureOverTime => 'PRZEBIEG TEMPERATURY';

  @override
  String roundh(Object round) {
    return '$round h';
  }

  @override
  String get timeInHrZones => 'Czas w strefach tętna';

  @override
  String get route2 => 'Trasa';

  @override
  String get start => 'Start';

  @override
  String get gpx => 'GPX';

  @override
  String touppercasesubstringBriefing(Object toUpperCase, Object substring) {
    return 'Podsumowanie: $toUpperCase$substring';
  }

  @override
  String get chatWithAiAboutThis => 'Porozmawiaj z AI o tym podsumowaniu';

  @override
  String get whyThisRecommendation => 'Dlaczego ta rekomendacja?';

  @override
  String titleDateLabel(Object title, Object date, Object label) {
    return '$title, $date, $label';
  }

  @override
  String get previousDay => 'Poprzedni dzień';

  @override
  String get nextDay => 'Następny dzień';

  @override
  String get updating => 'Aktualizowanie';

  @override
  String get resting => 'SPOCZYNEK';

  @override
  String get noTimedReadings => 'Brak pomiarów z godziną';

  @override
  String get avg => 'ŚR.';

  @override
  String get peak => 'SZCZYT';

  @override
  String tolocalRoundmin(Object toLocal, Object round) {
    return '$toLocal · $round min';
  }

  @override
  String avgheartrateBpmAvg(Object avgHeartRate) {
    return '$avgHeartRate bpm śr.';
  }

  @override
  String get timeWeightedAverageOverRecorded =>
      'Średnia ważona czasem z zapisanych okresów. Luki bez pomiarów są pomijane.';

  @override
  String get previousHeartRatePeriod => 'Poprzedni okres tętna';

  @override
  String get nextHeartRatePeriod => 'Następny okres tętna';

  @override
  String get avgHr => 'Śr. tętno';

  @override
  String get restingHr => 'Tętno spoczynkowe';

  @override
  String get both => 'Oba';

  @override
  String averagelabelFixedMs(Object averageLabel, Object fixed) {
    return '$averageLabel $fixed ms';
  }

  @override
  String get measureWithPolarH10 => 'Mierz z Polar H10';

  @override
  String get ms => 'ms';

  @override
  String get noWorkoutInThisPeriod =>
      'Żaden trening w tym okresie nie ma porównywalnej pary przed i po.';

  @override
  String textEachWorkoutCountsOnce(Object text) {
    return '$text. Każdy trening liczy się raz; to opis Twoich par, a nie ich ocena.';
  }

  @override
  String get workoutFinished => 'Trening zakończony?';

  @override
  String get yourWorkoutIsNotIn =>
      'Twojego treningu nie ma jeszcze w Fjelia. Jeśli się skończył, podaj kiedy, a przypomnienie dostosuje się do faktycznego końca. W przeciwnym razie pojawi się po synchronizacji zegarka.';

  @override
  String get workoutFinished2 => 'Trening zakończony';

  @override
  String get theWorkoutMustStartAfter =>
      'Trening musi zacząć się po pomiarze i skończyć po swoim początku, nie w przyszłości.';

  @override
  String daysDAvg(Object days) {
    return 'ŚR. $days DNI';
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
  String get previousPeriod => 'Poprzedni okres';

  @override
  String get nextPeriod => 'Następny okres';

  @override
  String get overnightHrvReflectsRecoveryCompare =>
      'Nocne HRV odzwierciedla regenerację. Porównuj swoje pomiary z własną linią bazową w czasie.';

  @override
  String get moveThisWorkout => 'PRZENIEŚ TEN TRENING';

  @override
  String get pickDate => 'Wybierz datę';

  @override
  String movedFromMovedfrom(Object movedFrom) {
    return 'Przeniesiono z $movedFrom';
  }

  @override
  String get hrvAroundThisWorkout => 'HRV wokół tego treningu';

  @override
  String get measureAfterTraining => 'Zmierz po treningu';

  @override
  String get measureAgain => 'Zmierz ponownie';

  @override
  String get explainWithAi => 'Wyjaśnij z AI';

  @override
  String beforeEndedPregapAheadOf(Object preGap) {
    return 'Pomiar przed zakończył się $preGap przed startem.';
  }

  @override
  String lengthFurtherMeasurementSAfter(Object length) {
    return '$length dodatkowych pomiarów po tym treningu zachowano jako dodatkowe obserwacje.';
  }

  @override
  String get noHrvMeasurementRecordedAround =>
      'Brak zapisanego pomiaru HRV wokół tego treningu.';

  @override
  String get measureHrv => 'Zmierz HRV';

  @override
  String deltamsMs(Object deltaMs) {
    return '$deltaMs ms';
  }

  @override
  String deltapercent(Object deltaPercent) {
    return '$deltaPercent %';
  }

  @override
  String get aDescriptionOfThisPair => 'Opis tej pary, a nie ocena treningu.';

  @override
  String notEnoughComparableWorkoutsYet(Object eligible, Object need) {
    return 'Za mało porównywalnych treningów, $eligible z $need.';
  }

  @override
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need) {
    return 'Za mało porównywalnych treningów ($eligible z $need).';
  }

  @override
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  ) {
    return 'Twoje podobne treningi: $eligible · $toLocal–$toLocal2';
  }

  @override
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  ) {
    return 'Środkowa połowa $q1Ms–$q3Ms ms · mediana $medianMs ms · ten trening $delta ms';
  }

  @override
  String rpeI(Object i) {
    return 'RPE $i';
  }

  @override
  String get easy2 => 'lekko';

  @override
  String get allOut => 'na maksa';

  @override
  String workoutProfileDescription(Object description) {
    return 'Profil treningu: $description';
  }

  @override
  String get noActivitiesInThisPeriod => 'Brak aktywności w tym okresie';

  @override
  String get enableHeatAcclimationInTraining =>
      'Włącz aklimatyzację do upału w ustawieniach treningu.';

  @override
  String get noElevationThisWeek => 'Brak przewyższeń w tym tygodniu';

  @override
  String get noActivitiesSynced => 'Brak zsynchronizowanych aktywności';

  @override
  String get noHrZoneData => 'Brak danych stref tętna';

  @override
  String get easyJogGetHrElevated =>
      'Lekki trucht — podnieś tętno, rozluźnij nogi';

  @override
  String get fastestSustainablePaceLikeA =>
      'Najszybsze utrzymywalne tempo — jak w 30-minutowym starcie';

  @override
  String get walkCardiacRecovery => 'Marsz — uspokojenie tętna';

  @override
  String get selectTheTtActivityFirst => 'Najpierw wybierz aktywność z próbą.';

  @override
  String get calculating => 'Obliczanie…';

  @override
  String get calculateLt2 => 'Oblicz LT2';

  @override
  String get enterFtpBetween30And => 'Wpisz FTP od 30 do 1000 W.';

  @override
  String get aerobicThreshold => 'Próg tlenowy';

  @override
  String get functionalThresholdPower => 'Funkcjonalna moc progowa';

  @override
  String get estimated => 'Szacowane';

  @override
  String get afterWarmingUpRunFive =>
      'Po rozgrzewce biegnij pięć minut z najszybszym wysiłkiem, jaki możesz utrzymać. Zapisz bieg z danymi prędkości lub dystansu.';

  @override
  String get recordAtLeast40Minutes =>
      'Zapisz co najmniej 40 minut równego biegu ze stałym wysiłkiem. Test porównuje tętno w obu połowach, aby oszacować dryf tlenowy.';

  @override
  String get theFastestFiveMinuteWindow =>
      'Najszybsze pięciominutowe okno wyznacza Twoje tempo VO2max.';

  @override
  String get noResultYet => 'Brak wyniku';

  @override
  String get calculateVo2maxPace => 'Oblicz tempo VO2max';

  @override
  String get calculateLt1 => 'Oblicz LT1';

  @override
  String get loading2 => 'Wczytywanie';

  @override
  String get unavailable => 'Niedostępne';

  @override
  String get noTrainingHistory => 'Brak historii treningów';

  @override
  String get fitnessCtl => 'Sprawność (CTL)';

  @override
  String get fatigueAtl => 'Zmęczenie (ATL)';

  @override
  String get formTsb => 'Forma (TSB)';

  @override
  String get noHistory => 'Brak historii';

  @override
  String get fresh => 'Wypoczęty';

  @override
  String get optimal => 'Optymalnie';

  @override
  String get neutral => 'Neutralnie';

  @override
  String get tired => 'Zmęczony';

  @override
  String get veryFatigued => 'Bardzo zmęczony';

  @override
  String get garminRunningVo2max => 'Garmin VO2max biegowe';

  @override
  String get garminCyclingVo2max => 'Garmin VO2max kolarskie';

  @override
  String get aerobicThreshold2 => 'Próg tlenowy';

  @override
  String driftDriftAt(Object drift, Object at) {
    return 'Dryf $drift% · $at';
  }

  @override
  String get activityHours => 'Godziny aktywności';

  @override
  String get activityKm => 'Kilometry aktywności';

  @override
  String get tap5MinuteMaxTest => 'Dotknij · 5-minutowy test maksymalny';

  @override
  String get setFtpToCalculatePower => 'Ustaw FTP, aby obliczyć strefy mocy';

  @override
  String get cyclingPowerZones2 => 'Strefy mocy w kolarstwie';

  @override
  String get pfitzingerZones2 => 'Strefy Pfitzingera';

  @override
  String get completeAnLt2TestTo =>
      'Wykonaj test LT2, aby obliczyć strefy biegowe.';

  @override
  String get setFtpToCalculatePower2 => 'Ustaw FTP, aby obliczyć strefy mocy.';

  @override
  String get endurance => 'Wytrzymałość';

  @override
  String get threshold => 'Próg';

  @override
  String get anaerobic => 'Beztlenowo';

  @override
  String get whatExplainsThisRise => 'Co wyjaśnia ten wzrost?';

  @override
  String get whatExplainsThisDrop => 'Co wyjaśnia ten spadek';

  @override
  String get whatExplainsThisRise2 => 'Co wyjaśnia ten wzrost';

  @override
  String get editsAreKeptInFjelia =>
      'Zmiany są przechowywane w Fjelia jako lokalna kopia dla tej daty. Trening w Garmin nie jest zmieniany.';

  @override
  String get howDoIExecuteThis => 'Jak wykonać ten trening?';

  @override
  String shareHealthContextWithName(Object name) {
    return 'Udostępnić kontekst zdrowotny $name?';
  }

  @override
  String get yourMessageAndAHealth =>
      'Twoja wiadomość i podsumowanie zdrowia i treningów zostaną wysłane do tego dostawcy AI w chmurze. Imiona i GPS nie trafiają do podsumowania.';

  @override
  String get couldNotGetAReply =>
      'Nie udało się uzyskać odpowiedzi. Sprawdź ustawienia AI i spróbuj ponownie.';

  @override
  String get askAboutYourRecoveryTraining =>
      'Zapytaj o regenerację, trening lub dzisiejszy plan.';

  @override
  String get noSyncYet => 'Jeszcze nie synchronizowano';

  @override
  String lastSyncLastContext(Object last, Object context) {
    return 'Ostatnia synchronizacja: $last $context';
  }

  @override
  String get seasonWithTradeOffs => 'Sezon: z kompromisami';

  @override
  String get seasonNeedsYourDecision => 'Sezon: wymaga Twojej decyzji';

  @override
  String get seasonCannotBeCombined => 'Sezon: nie da się połączyć';

  @override
  String get seasonProvisional => 'Sezon: wstępny';

  @override
  String get season => 'Sezon';

  @override
  String get allGoalsFit => 'Wszystkie cele się mieszczą.';

  @override
  String goalTargetfinishsecondsgoal(Object targetFinishSeconds, Object goal) {
    return 'Cel $targetFinishSeconds$goal';
  }

  @override
  String estEstimateestimate2(Object estimate, Object estimate2) {
    return 'Szac. $estimate$estimate2';
  }

  @override
  String doneDoneby(Object doneBy) {
    return 'Wykonano · $doneBy';
  }

  @override
  String garminWorkoutWorkout(Object workout) {
    return 'Trening Garmin · $workout';
  }

  @override
  String get moveAnyway => 'Przenieść mimo to?';

  @override
  String get wattsNeedYourFtpSet =>
      'Waty wymagają FTP: ustaw je w Obciążenie, Progi.';

  @override
  String get mainTargetInWattsFrom =>
      'Główny cel w watach z Twojego FTP, tętno jako wskazówka.';

  @override
  String get mainTargetHeartRateWatts =>
      'Głównym celem jest tętno; waty nie są ustawiane w zegarku.';

  @override
  String get taperPhase => 'Faza taperingu';

  @override
  String get recoverySession => 'Trening regeneracyjny';

  @override
  String get closeToYourEvent => 'Tuż przed wydarzeniem';

  @override
  String get noWorkoutStructureAvailable => 'Brak struktury treningu.';

  @override
  String get aerobic => 'Tlenowo';

  @override
  String get pushAgainToUpdateYour =>
      'Wyślij ponownie, aby zaktualizować kalendarz zegarka.';

  @override
  String workoutSentToLabel(Object label) {
    return 'Trening wysłany do $label';
  }

  @override
  String get updating2 => 'Aktualizowanie…';

  @override
  String pushToLabel(Object label) {
    return 'Wyślij do $label';
  }

  @override
  String shareExerciseListForLabel(Object label) {
    return 'Udostępnij listę ćwiczeń dla $label';
  }

  @override
  String shareWorkoutForLabel(Object label) {
    return 'Udostępnij trening dla $label';
  }

  @override
  String get whyNothingIsAddedTo =>
      'Dlaczego? Nic nie jest dodawane, by to nadrobić.';

  @override
  String get workout => 'Trening';

  @override
  String get recordedActivityLinkedToThis =>
      'Zapisana aktywność powiązana z tym treningiem';

  @override
  String get matchedToTheRecordedWorkout =>
      'Dopasowano do startu zapisanego treningu';

  @override
  String get matchedByWorkoutNameSport =>
      'Dopasowano po nazwie treningu, sporcie i dacie';

  @override
  String get matchedBySportDateAnd =>
      'Dopasowano po sporcie, dacie i czasie trwania';

  @override
  String planPlannedminutesMin(Object plannedMinutes) {
    return 'Plan $plannedMinutes min';
  }

  @override
  String get maxHr => 'Maks. tętno';

  @override
  String get trainingLoad2 => 'Obciążenie treningowe';

  @override
  String get active => 'Aktywnie';

  @override
  String get avgPace => 'Śr. tempo';

  @override
  String get avgSpeed => 'Śr. prędkość';

  @override
  String get avgPower => 'Śr. moc';

  @override
  String get elevation2 => 'Przewyższenie';

  @override
  String get altitude => 'Wysokość';

  @override
  String get explainMyHrvBeforeAnd =>
      'Wyjaśnij moje HRV przed tym treningiem i po nim. Co jest porównywalne, co nie i co jest jeszcze nieznane?';

  @override
  String get deleteActivity => 'Usunąć aktywność?';

  @override
  String get removeThisActivityFromThe =>
      'Usunąć tę aktywność? Pozostanie usunięta także po ponownej synchronizacji urządzeń. Możesz ją przywrócić w Ustawieniach w sekcji Ostatnio usunięte.';

  @override
  String get howDidThisSessionGo =>
      'Jak poszedł ten trening i co to oznacza dla moich kolejnych dni?';

  @override
  String currentFixedFixed2(Object fixed, Object fixed2) {
    return 'Obecnie $fixed, $fixed2';
  }

  @override
  String get setUpInTrainingSettings => 'Skonfiguruj w ustawieniach treningu';

  @override
  String get couldNotLoadHeatData =>
      'Nie udało się wczytać danych o upale — dotknij, aby zobaczyć szczegóły';

  @override
  String get loadingHeatHistory => 'Wczytywanie historii upałów…';

  @override
  String get noHeatDataYet => 'Brak danych o upale';

  @override
  String optimalLowHigh(Object low, Object high) {
    return 'Optymalnie $low–$high';
  }

  @override
  String optimalLowHighTrimp(Object low, Object high) {
    return 'Optymalnie: $low–$high TRIMP';
  }

  @override
  String get targetUnavailableSyncTrainingHistory =>
      'Cel niedostępny — zsynchronizuj historię treningów';

  @override
  String get workoutQualifiedForHeatAccumulation =>
      'Trening został zaliczony do aklimatyzacji do upału.';

  @override
  String get workoutDidNotAddHeat =>
      'Trening nie został zaliczony do aklimatyzacji do upału.';

  @override
  String get performanceTime => 'Wynik / czas';

  @override
  String get performanceDistance => 'Wynik / dystans';

  @override
  String get noRecordedRoute => 'Brak zapisanej trasy';

  @override
  String get zoomIn => 'Powiększ';

  @override
  String get zoomOut => 'Pomniejsz';

  @override
  String get fitRoute => 'Dopasuj trasę';

  @override
  String get fullscreenMap => 'Mapa na pełnym ekranie';

  @override
  String get openstreetmapContributors2 => 'Współtwórcy OpenStreetMap';

  @override
  String get appleIntelligenceIsUnavailableShowing =>
      'Apple Intelligence jest niedostępne. Wyświetlane jest podsumowanie bez AI.';

  @override
  String get generateAiBriefing => 'Utworzyć podsumowanie AI?';

  @override
  String get retryAiBriefing => 'Ponów podsumowanie AI';

  @override
  String get generateBriefing => 'Utwórz podsumowanie';

  @override
  String discussThisBriefingWithMe(Object text) {
    return 'Omów ze mną to podsumowanie i zaproponuj najlepszy następny krok.\n\n$text';
  }

  @override
  String whyThisRecommendationWhichOf(Object text) {
    return 'Dlaczego ta rekomendacja? Które moje wartości i które luki w danych do niej doprowadziły i co by ją zmieniło?\n\n$text';
  }

  @override
  String get avg2 => 'Śr.';

  @override
  String get peak2 => 'Szczyt';

  @override
  String get notEnoughContinuousReadingsFor =>
      'Za mało ciągłych pomiarów na średnią.';

  @override
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  ) {
    return 'Zapisane pokrycie: $inHours h $inMinutes min · średnia ważona czasem';
  }

  @override
  String get lying => 'Leżąc';

  @override
  String get noHrvReadingsInThis => 'Brak pomiarów HRV w tym okresie';

  @override
  String get overnightHrvComesFromYour =>
      'Nocne HRV pochodzi z zegarka, pomiary punktowe z Polar H10 (RMSSD). Metody się różnią: porównuj trendy, nie pojedyncze wartości.';

  @override
  String get noReadings => 'Brak pomiarów';

  @override
  String get whenDidTheWorkoutStart => 'Kiedy zaczął się trening?';

  @override
  String get whenDidItEnd => 'Kiedy się skończył?';

  @override
  String get last3Months => 'Ostatnie 3 miesiące';

  @override
  String get lastYear => 'Ostatni rok';

  @override
  String lastDaysDays(Object days) {
    return 'Ostatnie $days dni';
  }

  @override
  String nowOnCurrentTapA(Object current) {
    return 'Obecnie: $current. Dotknij dnia lub przeciągnij na niego trening. Kroki pozostają bez zmian.';
  }

  @override
  String get monthView => 'Widok miesiąca';

  @override
  String get syncing => 'Synchronizacja';

  @override
  String get trendUnavailable => 'Trend niedostępny';

  @override
  String get stable => 'Stabilnie';

  @override
  String get increasing => 'Rośnie';

  @override
  String get decreasing => 'Spada';

  @override
  String get unclear => 'Niejasno';

  @override
  String get notComparable => 'Nieporównywalne';

  @override
  String get waitingForAfter => 'Oczekiwanie na pomiar po';

  @override
  String get afterOnly => 'Tylko po';

  @override
  String get waitingForTheActualWorkout =>
      'Oczekiwanie na faktyczny koniec treningu.';

  @override
  String reminderAroundTolocal(Object toLocal) {
    return 'Przypomnienie około $toLocal';
  }

  @override
  String get reminderIsDueMeasureWhen =>
      'Czas na przypomnienie. Zmierz, gdy będziesz gotowy.';

  @override
  String get thisReminderIsNoLonger =>
      'To przypomnienie jest już nieaktualne. Otwórz trening, aby zobaczyć pomiary.';

  @override
  String beforeFixedMilliseconds(Object fixed) {
    return 'Przed $fixed milisekund. ';
  }

  @override
  String afterFixedMilliseconds(Object fixed) {
    return 'Po $fixed milisekund';
  }

  @override
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  ) {
    return 'Zmiana $deltaMs milisekund, $deltaPercent procent.';
  }

  @override
  String get noPreTrainingMeasurementRecorded =>
      'Brak zapisanego pomiaru przed treningiem.';

  @override
  String get notMeasuredYet => 'Jeszcze nie zmierzono';

  @override
  String leftOutOfTheComparison(Object excludedTotal, Object c) {
    return 'Pominięto w porównaniu: $excludedTotal treningów ($c).';
  }

  @override
  String get notFromThisWorkout => 'Nie z tego treningu';

  @override
  String get useAsBefore => 'Użyj jako przed';

  @override
  String get useAsAfter => 'Użyj jako po';

  @override
  String get beforeNotMeasured => 'Przed · nie zmierzono';

  @override
  String beforeTolocal(Object toLocal) {
    return 'Przed · $toLocal';
  }

  @override
  String workoutWorkouttext(Object workoutText) {
    return 'Trening · $workoutText';
  }

  @override
  String get afterNotMeasuredYet => 'Po · jeszcze nie zmierzono';

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
    return 'Twoje podobne treningi ($eligible, $toLocal–$toLocal2): mediana $medianMs ms, środkowa połowa $q1Ms–$q3Ms ms.';
  }

  @override
  String get howHardDidItFeel => 'Jak ciężko było? (RPE)';

  @override
  String get loadMetric => 'Obciążenie';

  @override
  String get clearAction => 'Wyczyść';

  @override
  String get routeFinish => 'Meta';

  @override
  String get month2 => 'MIESIĄC';

  @override
  String get week2 => 'TYDZIEŃ';

  @override
  String get quarter => 'KWARTAŁ';

  @override
  String get year => 'ROK';

  @override
  String get easy3 => 'LEKKO';

  @override
  String get mod => 'UMIARK.';

  @override
  String get hard => 'CIĘŻKO';

  @override
  String get protocol => 'PROTOKÓŁ';

  @override
  String get calculate => 'OBLICZ';

  @override
  String get warmUp => 'ROZGRZEWKA';

  @override
  String get coolDown => 'SCHŁODZENIE';

  @override
  String get ftpCycling => 'FTP kolarstwo';

  @override
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg) {
    return 'FTP $ftpWatts W · $wattsPerKg W/kg';
  }

  @override
  String get thisWeekSoFar => 'TEN TYDZIEŃ · DO TERAZ';

  @override
  String get duration2 => 'CZAS';

  @override
  String get distance2 => 'DYSTANS';

  @override
  String get sport2 => 'SPORT';

  @override
  String get repeatSets => 'POWTARZANE SERIE';

  @override
  String get aboutThisWorkout => 'O TYM TRENINGU';

  @override
  String get workoutStructure => 'STRUKTURA TRENINGU';

  @override
  String get health2 => 'ZDROWIE';

  @override
  String get high2 => 'WYSOKIE';

  @override
  String get elevated => 'PODWYŻSZONE';

  @override
  String get normal => 'PRAWIDŁOWE';

  @override
  String get tomorrow => 'JUTRO';

  @override
  String get skipped2 => 'POMINIĘTO';

  @override
  String get weeklyPlan => 'PLAN TYGODNIA';

  @override
  String get activityLog3 => 'DZIENNIK AKTYWNOŚCI';

  @override
  String skippedTouppercase(Object toUpperCase) {
    return 'POMINIĘTO · $toUpperCase';
  }

  @override
  String get primaryZone => 'GŁÓWNA STREFA';

  @override
  String get coachingCues => 'WSKAZÓWKI TRENERA';

  @override
  String get targets => 'CELE';

  @override
  String get adaptation => 'DOSTOSOWANIE';

  @override
  String get done2 => 'WYKONANO';

  @override
  String get notRecorded2 => 'NIEZAPISANE';

  @override
  String get planned => 'ZAPLANOWANE';

  @override
  String get extra => 'DODATKOWE';

  @override
  String get optimal2 => 'OPTYMALNIE';

  @override
  String get qualified => 'ZALICZONO';

  @override
  String get temp => 'TEMP.';

  @override
  String get humidity2 => 'WILGOTNOŚĆ';

  @override
  String get pressure => 'CIŚNIENIE';

  @override
  String get wetBulb => 'TERM. MOKRY';

  @override
  String get paceMinKm => 'TEMPO (min/km)';

  @override
  String get speedKmH => 'PRĘDKOŚĆ (km/h)';

  @override
  String get elevationM => 'WYSOKOŚĆ (m)';

  @override
  String get powerW => 'MOC (W)';

  @override
  String get performanceTime2 => 'WYNIK / CZAS';

  @override
  String get performanceDistance2 => 'WYNIK / DYSTANS';

  @override
  String get load2 => 'OBCIĄŻENIE';

  @override
  String get day2 => 'DZIEŃ';

  @override
  String get allTime => 'OD POCZĄTKU';

  @override
  String get hrvAroundThisWorkout2 => 'HRV wokół tego treningu. ';

  @override
  String get lowReserve => 'NISKA REZERWA';

  @override
  String get goodReserve => 'DOBRA REZERWA';

  @override
  String latestReadingAtTolocal(Object toLocal) {
    return 'Ostatni pomiar o $toLocal';
  }

  @override
  String get weeklyAvg => 'ŚREDNIA TYG.';

  @override
  String get monthlyAvg => 'ŚREDNIA MIES.';

  @override
  String get systolic2 => 'SKURCZOWE';

  @override
  String get diastolic2 => 'ROZKURCZOWE';

  @override
  String get hourlyVariation => 'ZMIENNOŚĆ GODZINOWA';

  @override
  String get dailyVariation => 'ZMIENNOŚĆ DZIENNA';

  @override
  String get sys2 => 'SYS';

  @override
  String get dia => 'DIA';

  @override
  String get bluetoothDevices => 'URZĄDZENIA BLUETOOTH';

  @override
  String get accountsServices => 'KONTA I USŁUGI';

  @override
  String get flowLoginOptional => 'LOGIN FLOW (OPCJONALNIE)';

  @override
  String get polarFlowLogin => 'LOGIN POLAR FLOW';

  @override
  String get raceGoal => 'CEL STARTOWY';

  @override
  String get experienceLevel => 'POZIOM DOŚWIADCZENIA';

  @override
  String get weeklySchedule2 => 'HARMONOGRAM TYGODNIA';

  @override
  String get sessionsPerDay2 => 'TRENINGI DZIENNIE';

  @override
  String get aboutYou => 'O TOBIE';

  @override
  String get yourActivities2 => 'TWOJE AKTYWNOŚCI';

  @override
  String latestReadingAtTimestamp(Object timestamp) {
    return 'Ostatni pomiar o $timestamp';
  }

  @override
  String get poorSleep => 'SŁABY SEN';

  @override
  String get fairSleep => 'PRZECIĘTNY SEN';

  @override
  String get goodSleep => 'DOBRY SEN';

  @override
  String get hoursOfSleep => 'GODZINY SNU';

  @override
  String get sleepNeeded => 'POTRZEBA SNU';

  @override
  String get deepSleep => 'SEN GŁĘBOKI';

  @override
  String get exercises2 => 'ĆWICZENIA';

  @override
  String get strengthSummary => 'PODSUMOWANIE SIŁY';

  @override
  String get strengthDraft => 'SIŁA · SZKIC';

  @override
  String get strengthFinishedWithGaps => 'SIŁA · ZAKOŃCZONO Z LUKAMI';

  @override
  String get strength2 => 'SIŁA';

  @override
  String get wind => 'WIATR';

  @override
  String get sun2 => 'SŁOŃCE';

  @override
  String get cloud => 'ZACHMURZENIE';

  @override
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt) {
    return 'Dane: $source · Aktualizacja $fetchedAt';
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
  String get awake => 'CZUWANIE';

  @override
  String get light => 'PŁYTKI';

  @override
  String get deep2 => 'GŁĘBOKI';

  @override
  String get sqliteOrm => 'ORM SQLite';

  @override
  String get httpClients => 'Klienty HTTP';

  @override
  String get gpsLocation => 'Lokalizacja GPS';

  @override
  String get hdlCholesterol => 'Cholesterol HDL';

  @override
  String get ldlCholesterol => 'Cholesterol LDL';

  @override
  String get raceName => 'NAZWA STARTU';

  @override
  String get mtb => 'MTB';

  @override
  String get distanceKm => 'DYSTANS (km)';

  @override
  String get priority => 'PRIORYTET';

  @override
  String get elevationGainM => 'PRZEWYŻSZENIE (m)';

  @override
  String get targetTime => 'CZAS DOCELOWY';

  @override
  String get raceDate => 'DATA STARTU';

  @override
  String get participation => 'UDZIAŁ';

  @override
  String get whatIWantFromIt => 'CZEGO OCZEKUJĘ';

  @override
  String periodTimeline(Object period) {
    return 'PRZEBIEG: $period';
  }

  @override
  String get tabPlan => 'PLAN';

  @override
  String get tabLoad => 'LOAD';

  @override
  String get tabCoach => 'TRENER';

  @override
  String get hrDriftTestLt1 => 'TEST DRYFU TĘTNA — LT1';

  @override
  String get asSentByGarmin => 'TAK JAK WYSŁAŁ GARMIN';

  @override
  String get noData2 => 'BRAK DANYCH';

  @override
  String get noTarget => 'BRAK CELU';

  @override
  String get noHeatLoad => 'BRAK OBCIĄŻENIA UPAŁEM';

  @override
  String get hrBpm => 'TĘTNO (bpm)';

  @override
  String get aiBriefingUnavailableShowingA =>
      'Podsumowanie AI niedostępne. Wyświetlane jest podsumowanie bez AI.';

  @override
  String get uvIndex2 => 'INDEKS UV';

  @override
  String get aiBriefing => 'Podsumowanie AI';

  @override
  String get uiFrameworkByGoogle => 'Framework UI od Google';

  @override
  String get unableToLoadData => 'Nie udało się wczytać danych';

  @override
  String briefingSummary(Object recovery, Object sleep, Object load) {
    return 'Regeneracja $recovery / 100. Sen $sleep / 100. Dzisiejsze obciążenie treningowe to $load TRIMP.';
  }

  @override
  String get morningBriefing => 'Podsumowanie poranne';

  @override
  String get lunchBriefing => 'Podsumowanie południowe';

  @override
  String get afternoonBriefing => 'Podsumowanie popołudniowe';

  @override
  String get eveningBriefing => 'Podsumowanie wieczorne';

  @override
  String get appleUnusableAnswer =>
      'Apple Intelligence nie udzieliło użytecznej odpowiedzi: powtarzało siebie lub Twoje dane. Spróbuj inaczej sformułować pytanie lub wybierz innego dostawcę AI w ustawieniach.';

  @override
  String get appleCouldNotAnswer =>
      'Apple Intelligence nie mogło odpowiedzieć. Spróbuj ponownie.';

  @override
  String get appleNotAvailableOnDevice =>
      'Apple Intelligence nie jest dostępne na tym urządzeniu.';

  @override
  String get appleLanguageRejected =>
      'Apple Intelligence odrzuciło język zapytania. Spróbuj krótkiego pytania po angielsku. Sprawdź też ustawienia języka iPhone’a i Siri.';

  @override
  String get appleRequestTooLarge =>
      'To zapytanie jest za duże dla Apple Intelligence. Spróbuj krótszego pytania.';

  @override
  String get messageTooLongForApple =>
      'Ta wiadomość jest za długa dla Apple Intelligence. Skróć ją i wyślij ponownie.';

  @override
  String get vo2maxRunning => 'VO₂max bieganie';

  @override
  String get vo2maxCycling => 'VO₂max kolarstwo';

  @override
  String get vo2maxPaceLabel => 'Tempo VO₂max';

  @override
  String get lt1Threshold => 'Próg LT1';

  @override
  String get lt2Threshold => 'Próg LT2';

  @override
  String hoursPreviousWeek(Object value) {
    return '$value h w poprzednim tygodniu';
  }

  @override
  String kmPreviousWeek(Object value) {
    return '$value km w poprzednim tygodniu';
  }

  @override
  String get thirtyMinuteTimeTrial => '30-minutowa próba czasowa';

  @override
  String thirtyMinTtDate(Object date) {
    return 'Próba 30 min · $date';
  }

  @override
  String get yesterday2 => 'WCZORAJ';

  @override
  String get briefHeadGreen => 'Jesteś dobrze zregenerowany.';

  @override
  String get briefHeadYellow => 'Odczuwasz pewne obciążenie.';

  @override
  String get briefHeadRed => 'Jesteś wyraźnie obciążony.';

  @override
  String briefMain(Object reasons) {
    return 'Główne powody: $reasons.';
  }

  @override
  String get briefAllClear =>
      'Żadna z Twoich wartości nie daje sygnału ostrzegawczego.';

  @override
  String get briefAdviceGreen => 'Trenuj zgodnie z planem.';

  @override
  String get briefAdviceYellow =>
      'Trzymaj się planu, ale nie dodawaj intensywności.';

  @override
  String get briefAdviceRed =>
      'Najpierw regeneracja: zrób lekki dzień lub odpocznij.';

  @override
  String get briefReasonHrvLow => 'niskie HRV we śnie';

  @override
  String get briefReasonHrvHigh => 'wysokie HRV we śnie';

  @override
  String get briefReasonRhrUp => 'podwyższone tętno spoczynkowe';

  @override
  String get briefReasonRhrDown => 'niskie tętno spoczynkowe';

  @override
  String get briefReasonSleepShort => 'za mało snu';

  @override
  String get briefReasonSleepGood => 'zaspokojona potrzeba snu';

  @override
  String get briefReasonEnergyLow => 'niska energia';

  @override
  String get briefReasonEnergyHigh => 'dobra energia';

  @override
  String get briefReasonStressHigh => 'wysoki stres';

  @override
  String get briefReasonRespHigh => 'podwyższona częstość oddechu';

  @override
  String get briefReasonSpo2Low => 'niskie natlenienie krwi';

  @override
  String get briefReasonSkinTempOff => 'nietypowa temperatura skóry';

  @override
  String get briefReasonFormTired => 'nagromadzone zmęczenie treningowe';

  @override
  String get briefReasonFormVeryTired => 'bardzo duże zmęczenie treningowe';

  @override
  String get briefReasonFormFresh => 'świeżość i wypoczęcie';

  @override
  String get briefTrainingHrvUp =>
      'Twoje HRV wzrosło po treningu, to dobry znak.';

  @override
  String get briefTrainingHrvDown =>
      'Twoje HRV spadło po treningu, to gorszy znak.';

  @override
  String get reminderNeedsNotifications =>
      'Przypomnienie wymaga powiadomień. Zezwól na nie dla Fjelia w ustawieniach systemu, a następnie włącz je ponownie.';

  @override
  String get whatDidYouHave => 'Co spożyłeś?';

  @override
  String get intakeSomething => 'Coś spożyłem';

  @override
  String get intakeNothing => 'Nic';

  @override
  String get totalIntake => 'Łączne spożycie';

  @override
  String get carbsLabel => 'Węglowodany';

  @override
  String get fluidLabel => 'Płyny';

  @override
  String get sodiumLabel => 'Sód';

  @override
  String get caffeineLabel => 'Kofeina';

  @override
  String get detailsOptional => 'Szczegóły (opcjonalnie)';

  @override
  String atMinute(Object minute) {
    return 'minuta $minute';
  }

  @override
  String get nothingAddedYet =>
      'Nic jeszcze nie dodano. Dodaj, co zjadłeś lub wypiłeś, albo wybierz „Nic”.';

  @override
  String get followFocusWeek => 'Na czym powinienem się skupić w tym tygodniu?';

  @override
  String get followRecoveryTrend => 'Jak zmienia się moja regeneracja?';

  @override
  String get followLoadTooHigh =>
      'Czy moje obciążenie treningowe jest za wysokie?';

  @override
  String get followImproveSleep => 'Co poprawiłoby mój sen?';

  @override
  String get followIntervalsFeel =>
      'Jak powinny wyglądać odczucia w interwałach?';

  @override
  String get followTiredToday => 'Co jeśli dziś czuję się zmęczony?';

  @override
  String get followEatBefore => 'Co zjeść przed treningiem?';

  @override
  String get followAdjustToday => 'Czy powinienem go dziś zmienić?';

  @override
  String get followNextDays => 'Co to oznacza dla moich kolejnych dni?';

  @override
  String get followCompareSimilar => 'Jak wypada na tle podobnych treningów?';

  @override
  String get followRecover => 'Co zrobić, żeby się zregenerować?';

  @override
  String get followIntensityRight => 'Czy intensywność była odpowiednia?';

  @override
  String get statusPlanned => 'Zaplanowane';

  @override
  String get statusAdapted => 'Dostosowane';

  @override
  String get statusCompleted => 'Ukończone';

  @override
  String get statusRest => 'Odpoczynek';

  @override
  String loadValue(Object value) {
    return 'Obciążenie $value';
  }

  @override
  String get actIntensityEasy => 'To był lekki trening tlenowy.';

  @override
  String get actIntensityModerate => 'To był umiarkowany trening.';

  @override
  String get actIntensityHard => 'To był ciężki trening.';

  @override
  String get actIntensityUnknown => 'Ten trening jest zapisany.';

  @override
  String get actLenLonger => 'Był dłuższy niż Twoje podobne treningi.';

  @override
  String get actLenShorter => 'Był krótszy niż Twoje podobne treningi.';

  @override
  String get actLoadHigher => 'Obciążenie było wyższe niż zwykle.';

  @override
  String get actLoadLower => 'Obciążenie było niższe niż zwykle.';

  @override
  String get actLoadSame => 'Obciążenie było mniej więcej takie jak zwykle.';

  @override
  String get actHrLower =>
      'Twoje tętno było niższe niż zwykle, więc było lżej.';

  @override
  String get actHrHigher =>
      'Twoje tętno było wyższe niż zwykle, więc było ciężej.';

  @override
  String get actAdviceUnknown => 'Planuj kolejne dni według samopoczucia.';

  @override
  String briefOutlookRest(Object days) {
    return 'Po około $days lekkich dniach Twoja forma wróci do optymalnego zakresu.';
  }

  @override
  String get briefOutlookLongRest =>
      'Twoja forma potrzebuje więcej niż kilku lekkich dni, by wrócić.';

  @override
  String get briefOutlookPlanTired =>
      'Trzymanie się planu utrzyma niską formę przez kolejne dni.';

  @override
  String get localQwen => 'Qwen3.5 · lokalnie';

  @override
  String get localModelDescription =>
      'Opcjonalny Qwen3.5, 4-bitowy MLX. Pobierz raz, a potem korzystaj z czatu i podsumowań na tym urządzeniu bez klucza API. Twoje dane o zdrowiu zostają na tym urządzeniu.';

  @override
  String localModelSizeMb(Object megabytes) {
    return 'Pobranie $megabytes MB · podczas działania potrzebna jest dodatkowa pamięć.';
  }

  @override
  String get localModelDownload => 'Pobierz model';

  @override
  String get localModelResumeDownload => 'Wznów pobieranie';

  @override
  String localModelDownloading(Object downloaded, Object total) {
    return '$downloaded / $total MB';
  }

  @override
  String get localModelInstalled => 'Pobrano · dostępny offline';

  @override
  String get localModelRemove => 'Usuń model';

  @override
  String get localModelUnsupported =>
      'Ten model MLX wymaga iPhone’a z iOS 17 lub nowszym i chipem A14 lub nowszym. Starsze urządzenia nie są obsługiwane.';

  @override
  String get localModelMemoryUnsupported =>
      'To urządzenie ma za mało pamięci, aby uruchomić lokalny model.';

  @override
  String get localModelDownloadFailed =>
      'Pobieranie nie powiodło się. Spróbuj ponownie; ukończone pliki zostają zachowane.';

  @override
  String get localModelDownloadFirst =>
      'Najpierw pobierz Qwen w Ustawienia → AI i więcej.';

  @override
  String get localModelContextTooLong =>
      'Ta rozmowa jest za długa dla lokalnego modelu. Rozpocznij nowy czat lub skróć pytanie.';

  @override
  String get localModelBusy =>
      'Lokalny model odpowiada na inne zapytanie. Spróbuj za chwilę.';

  @override
  String get localModelInterrupted =>
      'Lokalne generowanie zostało przerwane. Nie zamykaj Fjelia i spróbuj ponownie.';

  @override
  String get localModelCouldNotAnswer =>
      'Lokalny model nie mógł odpowiedzieć. Sprawdź model w Ustawienia → AI i więcej i spróbuj ponownie.';

  @override
  String get localModelBriefingUnavailable =>
      'Lokalne podsumowanie AI niedostępne. Wyświetlane jest podsumowanie aplikacji.';

  @override
  String get localModelInfo => 'Szczegóły modelu i licencja';

  @override
  String localModelRamGb(int gigabytes) {
    return 'Wymaga co najmniej $gigabytes GB pamięci urządzenia.';
  }

  @override
  String get localModelIPhone18 => '4B jest dostępny na iPhonie 18 i nowszych.';

  @override
  String briefPlannedTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Na dziś zaplanowano $count treningu.',
      many: 'Na dziś zaplanowano $count treningów.',
      few: 'Na dziś zaplanowano $count treningi.',
      one: 'Na dziś zaplanowano $count trening.',
    );
    return '$_temp0';
  }

  @override
  String get coachDataFallback =>
      'Odpowiedź modelu jest sprzeczna z danymi. Oto podsumowanie Fjelia:';

  @override
  String get coachSevenDayAverage => 'Średnia z 7 dni';

  @override
  String coachSleepNeedAndShortfall(String need, String shortfall) {
    return 'Potrzeba snu: $need h; niedobór: $shortfall h.';
  }

  @override
  String coachCurrentForm(String value) {
    return 'Obecna forma (TSB): $value pkt.';
  }

  @override
  String get aiOnboardingStep => 'Krok 2 z 3';

  @override
  String get aiOnboardingTitle => 'Twój trener.\nPo Twojemu.';

  @override
  String get aiOnboardingSubtitle =>
      'Zamień dane o zdrowiu we wnioski dla lepszego treningu i regeneracji.';

  @override
  String get aiOnboardingChoose => 'WYBIERZ TRENERA AI';

  @override
  String get aiOnboardingFreeDetail => 'Bezpłatnie · bez konta AI';

  @override
  String get aiOnboardingFreeBody => 'AI w chmurze do treningu i regeneracji.';

  @override
  String get aiOnboardingRecommended => 'Polecane';

  @override
  String get aiOnboardingOnDevice => 'Na Twoim urządzeniu';

  @override
  String get aiOnboardingLocalBody =>
      'Twoje zapytania AI zostają na tym urządzeniu.';

  @override
  String get aiOnboardingUnavailable => 'Obecnie niedostępne';

  @override
  String get aiOnboardingMore => 'Więcej modeli AI';

  @override
  String get aiOnboardingMoreBody =>
      'Lokalny Qwen lub własny dostawca w chmurze';

  @override
  String get aiOnboardingConsent =>
      'Zapytania do chmury tylko po Twoim potwierdzeniu.';

  @override
  String get aiOnboardingError =>
      'Nie udało się zapisać ani wczytać Twojego wyboru AI. Spróbuj ponownie.';

  @override
  String get aiOnboardingWithout => 'Kontynuuj bez AI';

  @override
  String get aiOnboardingConfigure => 'Skonfiguruj model';

  @override
  String aiOnboardingContinue(String provider) {
    return 'Kontynuuj z $provider';
  }

  @override
  String get aiOnboardingChangeLater =>
      'Możesz to zmienić w każdej chwili w Ustawieniach.';

  @override
  String get creditsAndLicenses => 'Autorzy i licencje';

  @override
  String get bioAgeActivity => 'Aktywność';

  @override
  String get bioAgeActivityBasis => 'Dane aktywności · ostatnie 7 dni';

  @override
  String bioAgeActivityReported(String minutes) {
    return '$minutes zgłoszonych minut umiarkowanej aktywności';
  }

  @override
  String bioAgeActivitySteps(String minutes) {
    return '≈ $minutes minut marszu oszacowanych z kroków';
  }

  @override
  String bioAgeActivityCoverage(int days) {
    return 'Dane z $days z 7 dni';
  }

  @override
  String get bioAgeActivityEstimateNotice =>
      'Założenie: 100 kroków ≈ 1 minuta marszu. Dzienne sumy kroków nie mówią nic o tempie ani intensywności. Zgłoszone minuty mają pierwszeństwo każdego dnia; kroki z tego dnia nie są liczone ponownie.';

  @override
  String get bioAgeActivityIncomplete =>
      'Brakuje danych aktywności. Wkład aktywności w latach jest obliczany tylko wtedy, gdy wszystkie 7 dni ma dane.';

  @override
  String get bioAgeActivityEstimatedLabel =>
      'Aktywność obejmuje szacowany czas marszu.';

  @override
  String get bioAgeActivityUnknownLabel => 'Dane aktywności są niepełne';

  @override
  String get mixTitle => 'Przygotuj napój';

  @override
  String get mixMyBottle => 'Przygotuj mój bidon';

  @override
  String get mixRecipes => 'Przepisy';

  @override
  String get mixIngredients => 'Składniki';

  @override
  String get mixAddIngredient => 'Dodaj składnik';

  @override
  String get mixBottle => 'Bidon';

  @override
  String get mixFilledWithWater => 'uzupełniony wodą';

  @override
  String mixPerBottle(String ml) {
    return 'na bidon $ml ml';
  }

  @override
  String get mixStrength => 'Stężenie';

  @override
  String get mixRatio => 'Glukoza : fruktoza';

  @override
  String get mixGlucose => 'Glukoza';

  @override
  String get mixFructose => 'Fruktoza';

  @override
  String get mixGlucoseOnly => 'Tylko glukoza';

  @override
  String get mixGentle => 'Łagodny dla żołądka – do 8 %.';

  @override
  String get mixStrong => 'Stężony – tylko przy wytrenowanym żołądku.';

  @override
  String get mixTooStrong => 'Bardzo stężony – dodaj wody.';

  @override
  String get mixNoFructoseHint =>
      'Tylko glukoza: powyżej około 60 g węglowodanów na godzinę dodaj fruktozę (cukier) – proporcja około 2:1 wchłania się lepiej.';

  @override
  String get mixFructoseHeavyHint =>
      'Więcej fruktozy niż glukozy może podrażnić żołądek – dodaj maltodekstrynę lub dekstrozę.';

  @override
  String get mixSpoonNote =>
      'Łyżki mają różną wielkość. Zważ swoją łyżkę raz albo używaj gramów, aby mieć dokładne wartości.';

  @override
  String get mixTooMuchLiquid =>
      'Sam sok i cola to więcej, niż mieści bidon – zwiększ bidon.';

  @override
  String get mixAddToIntake => 'Dodaj do spożycia';

  @override
  String get mixUseAsBottle => 'Użyj jako mój bidon';

  @override
  String get mixDefaultName => 'Mieszanka napoju';

  @override
  String get mixEmpty => 'Wybierz przepis lub dodaj składnik.';

  @override
  String get mixRemove => 'Usuń';

  @override
  String mixRowGrams(String grams) {
    return '≈ $grams g';
  }

  @override
  String mixBottleSaved(String carbs, String ml) {
    return 'Zapisano jako Twój bidon: $carbs g węglowodanów na $ml ml.';
  }

  @override
  String get mixMaltodextrin => 'Maltodekstryna';

  @override
  String get mixSugar => 'Cukier';

  @override
  String get mixDextrose => 'Dekstroza';

  @override
  String get mixHoney => 'Miód';

  @override
  String get mixSalt => 'Sól';

  @override
  String get mixOrangeJuice => 'Sok pomarańczowy';

  @override
  String get mixAppleJuice => 'Sok jabłkowy';

  @override
  String get mixCola => 'Cola';

  @override
  String get unitTspLevel => 'płaska łyżeczka';

  @override
  String get unitTspHeaped => 'czubata łyżeczka';

  @override
  String get unitTbspLevel => 'płaska łyżka';

  @override
  String get unitTbspHeaped => 'czubata łyżka';

  @override
  String get unitPinch => 'szczypta';

  @override
  String get unitTsp => 'łyżeczka';

  @override
  String get unitTbsp => 'łyżka';

  @override
  String get mixRecipeMaltoSugar => 'Malto + cukier 2:1';

  @override
  String get mixRecipeJuice => 'Sok z wodą gazowaną';

  @override
  String get mixRecipeJuicePlus => 'Sok z wodą gazowaną + malto';

  @override
  String get mixRecipeCola => 'Cola z wodą gazowaną';

  @override
  String get missedWorkoutTitle => 'Nadal w Twoim planie na dziś';

  @override
  String missedWorkoutBody(String workouts) {
    return '$workouts. Jeszcze dziś, przenieść czy pominąć?';
  }

  @override
  String get stillToday => 'Jeszcze dziś';

  @override
  String get moveWorkoutAction => 'Przenieś…';

  @override
  String get missedWorkoutChannel => 'Pominięte treningi';

  @override
  String get missedWorkoutChannelDescription =>
      'Wieczorne przypomnienie o zaplanowanych treningach, które tego dnia są nadal otwarte';

  @override
  String get missedWorkoutReminder => 'Przypomnienie o pominiętym treningu';

  @override
  String get missedWorkoutReminderSubtitle =>
      'Wieczorem, jeśli zaplanowany trening jest nadal otwarty';

  @override
  String get moveWithinDays => 'Przenieś w ciągu';

  @override
  String daysN(int count) {
    return '$count dni';
  }

  @override
  String get notificationsAreOff =>
      'Powiadomienia dla Fjelia są wyłączone. Zezwól na nie, aby otrzymywać to przypomnienie.';

  @override
  String get allowNotifications => 'Zezwól na powiadomienia';

  @override
  String get openWorkoutToday => 'Nadal otwarty dziś';

  @override
  String get checkingForWorkout => 'Szukanie treningu…';

  @override
  String get alreadyDone => 'Już wykonano ✓';

  @override
  String get alreadyDoneBody =>
      'Twój trening został zapisany. Na dziś nic więcej do zrobienia.';

  @override
  String get dropIt => 'Odpuść';

  @override
  String askCoachSends(String provider) {
    return 'Wysyła podsumowanie treningów do $provider.';
  }

  @override
  String get coachThinking => 'Trener myśli…';

  @override
  String get coachCouldNotAnswer =>
      'Trener nie mógł odpowiedzieć. Sugestia powyżej nadal obowiązuje.';

  @override
  String get whySkip => 'Dlaczego pominąć?';

  @override
  String get skipReasonIllness => 'Choroba';

  @override
  String get skipReasonInjury => 'Kontuzja lub ból';

  @override
  String get skipReasonFatigue => 'Zmęczenie';

  @override
  String get skipReasonNoTime => 'Brak czasu';

  @override
  String get skipReasonTravel => 'Podróż';

  @override
  String get skipReasonConditions => 'Warunki';

  @override
  String get skipReasonMyChoice => 'Mój wybór';

  @override
  String get onbReminderTitle => 'Trzymaj kurs';

  @override
  String get onbReminderSubtitle =>
      'Jeśli wieczorem zaplanowany trening jest nadal otwarty, Fjelia przypomni Ci o nim raz, abyś mógł go jeszcze wykonać, przenieść lub pominąć.';

  @override
  String get onbExampleWorkout => 'Lekki bieg (45 min)';

  @override
  String get onbReminderToggle => 'Wieczorne przypomnienie';

  @override
  String get onbReminderTime => 'Przypomnij mi o';

  @override
  String get onbReminderFootnote =>
      'Możesz to zmienić w każdej chwili w Ustawienia → Trening.';

  @override
  String get nowLabel => 'teraz';

  @override
  String get coachSuggests => 'Trener sugeruje';

  @override
  String get suggestionLabel => 'Sugestia';

  @override
  String get askCoachShort => 'Zapytaj trenera';

  @override
  String get otherDay => 'Inny dzień';

  @override
  String get skipEllipsis => 'Pomiń…';

  @override
  String get pickADay => 'Dotknij dnia powyżej';

  @override
  String get dayDoesNotFit => 'Ten dzień nie pasuje do planu.';

  @override
  String get planUpdated => 'Plan zaktualizowany';

  @override
  String get missedTodayTag => 'pominięty dziś';

  @override
  String summaryMove(String day) {
    return 'Przenieś na $day.';
  }

  @override
  String summaryMoveIndoor(String day) {
    return 'Przenieś na $day, w pomieszczeniu – prognozowany jest deszcz.';
  }

  @override
  String get summaryDropEasy =>
      'Odpuść – lekkiego treningu nie warto nadrabiać.';

  @override
  String summaryDropNoDay(int days) {
    return 'Odpuść – żaden dzień w ciągu najbliższych $days dni nie pasuje.';
  }

  @override
  String get tagIndoor => 'w pomieszczeniu';

  @override
  String get tagEasier => 'lżej';

  @override
  String get tagRecovery => 'regeneracja';

  @override
  String summaryMoveEasier(String day) {
    return 'Przenieś na $day, nieco lżej – sąsiaduje z ciężkim dniem.';
  }

  @override
  String get briefRestDayToday => 'Dziś jest zaplanowany dzień odpoczynku.';

  @override
  String get restDayPlannedNote => 'Regeneracja jest częścią Twojego planu.';

  @override
  String get restDayTitle => 'Dzień odpoczynku';

  @override
  String get importActivityFile => 'Importuj plik aktywności';

  @override
  String get activityFileImportHint =>
      'Pliki FIT, GPX lub TCX (także spakowane, tak jak eksportuje je Garmin Connect) z licznika rowerowego, Zwift, Strava lub innej aplikacji. Możesz też udostępnić plik do Fjelia z aplikacji Pliki lub menu udostępniania.';

  @override
  String get chooseActivityFiles => 'Wybierz pliki';

  @override
  String get chooseOtherFiles => 'Wybierz inne pliki';

  @override
  String get activityFileUnreadable => 'To nie jest czytelny plik aktywności';

  @override
  String get activityFileAlreadyImported => 'Już zaimportowano';

  @override
  String activityFileAlreadyFrom(String source) {
    return 'Już w Fjelia z $source';
  }

  @override
  String importActivities(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importuj $count aktywności',
      many: 'Importuj $count aktywności',
      few: 'Importuj $count aktywności',
      one: 'Importuj $count aktywność',
    );
    return '$_temp0';
  }

  @override
  String activitiesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zaimportowano $count aktywności.',
      many: 'Zaimportowano $count aktywności.',
      few: 'Zaimportowano $count aktywności.',
      one: 'Zaimportowano $count aktywność.',
    );
    return '$_temp0';
  }

  @override
  String get activityFileSource => 'Plik';

  @override
  String get dfaAlpha1Title => 'Próg tlenowy (DFA α1)';

  @override
  String get dfaHrvt1 => 'Próg tlenowy (HRVT1)';

  @override
  String get dfaHrvt2 => 'Próg beztlenowy (HRVT2)';

  @override
  String dfaEasyShare(String percent) {
    return '$percent % treningu poniżej progu tlenowego (α1 ≥ 0,75).';
  }

  @override
  String get dfaNoThreshold =>
      'Trening nie przekroczył wyraźnie progu. Szacunek da test narastający lub trening przechodzący od lekkiego do ciężkiego.';

  @override
  String dfaBeats(int beats, String artifacts) {
    return '$beats uderzeń · $artifacts % artefaktów';
  }

  @override
  String get dfaArtifactsHigh =>
      'Dużo artefaktów: sprawdź, czy pas piersiowy dobrze przylega, a elektrody są wilgotne.';

  @override
  String get dfaExplainer =>
      'Z danych uderzenie po uderzeniu z pasa piersiowego. α1 bliskie 1 oznacza lekko, 0,75 wyznacza próg tlenowy, a 0,5 beztlenowy. To szacunek, nie badanie laboratoryjne.';

  @override
  String get thresholdOrderNote =>
      'Fjelia porównuje wszystkie źródła. Najpierw proponuje własne testy aplikacji, potem zegarek, potem DFA α1 z kilku treningów, a na końcu profil Polar i wzory. Nic się nie zmienia, dopóki tego nie zastosujesz.';

  @override
  String thresholdInUse(String value) {
    return 'W użyciu: $value';
  }

  @override
  String thresholdProposal(String value, String source) {
    return 'Propozycja: $value z $source';
  }

  @override
  String get keepCurrent => 'Zachowaj obecne';

  @override
  String get lt2Cycling => 'LT2 · Kolarstwo';

  @override
  String get thresholdSourceTt => '30-minutowa próba czasowa';

  @override
  String get thresholdSourceDrift => 'Test dryfu tętna';

  @override
  String thresholdSourceDfa(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DFA α1, $count treningu',
      many: 'DFA α1, $count treningów',
      few: 'DFA α1, $count treningi',
      one: 'DFA α1, $count trening',
    );
    return '$_temp0';
  }

  @override
  String get thresholdSourceEftp => 'eFTP z jazd';

  @override
  String get thresholdSourcePolarProfile => 'Profil Polar';

  @override
  String get thresholdFormulaLt2 => 'LT2 − 30 bpm';

  @override
  String get thresholdFormulaMaxHr => '77 % maks. tętna';

  @override
  String get thresholdStale => 'starsze niż 6 miesięcy';

  @override
  String get thresholdsCoachLocked =>
      'Twoimi progami zarządza trener, więc nie można ich tu zmienić.';

  @override
  String get mediaTitle => 'Zdjęcia i filmy';

  @override
  String get mediaAdd => 'Dodaj';

  @override
  String get mediaFromLibrary => 'Wybierz z biblioteki';

  @override
  String get mediaTakePhoto => 'Zrób zdjęcie';

  @override
  String get mediaRecordVideo => 'Nagraj film';

  @override
  String mediaAdding(int done, int total) {
    return 'Dodawanie $done z $total…';
  }

  @override
  String get mediaMoveEarlier => 'Przesuń wcześniej';

  @override
  String get mediaMoveLater => 'Przesuń później';

  @override
  String get mediaDeleteTitle => 'Usunąć z Fjelia?';

  @override
  String get mediaDeleteMessage =>
      'Usuwa zdjęcie lub film z Fjelia. Oryginał w bibliotece zdjęć pozostaje.';

  @override
  String get mediaAddFailed => 'Nie udało się dodać niektórych plików.';

  @override
  String get mediaHint =>
      'Dotknij, aby wyświetlić, przytrzymaj, aby przenieść lub usunąć.';

  @override
  String get backupVideosTitle => 'Dołączyć filmy?';

  @override
  String backupVideosMessage(String size) {
    return 'Twoje filmy zajmują $size. Bez nich kopia jest znacznie mniejsza; zdjęcia są zawsze dołączane.';
  }

  @override
  String get backupWithVideos => 'Z filmami';

  @override
  String get backupWithoutVideos => 'Bez filmów';

  @override
  String get mediaShareCard => 'Udostępnij jako kartę';

  @override
  String get mediaShareCardHint =>
      'Przeciągnij panel lub trasę, aby je przesunąć. Szczypnij i przeciągnij zdjęcie, aby je wykadrować; dwukrotne dotknięcie przywraca je.';

  @override
  String get shareGymPhoto => 'Zdjęcie z siłowni';

  @override
  String get shareWithoutPhoto => 'Bez zdjęcia';

  @override
  String get shareStyleGlass => 'Szkło';

  @override
  String get shareStylePoster => 'Plakat';

  @override
  String get shareStyleMinimal => 'Minimalny';

  @override
  String get shareStyleNeon => 'Neon';

  @override
  String get shareStyleSticker => 'Naklejka';

  @override
  String get shareStyleReceipt => 'Paragon';

  @override
  String get shareStyleKpop => 'K-pop';

  @override
  String get shareStylePixel => 'Piksel';

  @override
  String get shareStyleRobot => 'Robot';

  @override
  String get shareStyleScifi => 'Sci-fi';

  @override
  String get shareStyleCard => 'Karta kolekcjonerska';

  @override
  String get shareStyleComic => 'Komiks';

  @override
  String get shareStyleOutdoor => 'Outdoor';

  @override
  String get shareStyleHolo => 'Karta holo';

  @override
  String get shareStyleHoloFull => 'Karta pełnoekranowa';

  @override
  String nowcastRainSoon(int minutes) {
    return 'Deszcz za około $minutes min';
  }

  @override
  String nowcastRainingStops(int minutes) {
    return 'Teraz pada · sucho za około $minutes min';
  }

  @override
  String nowcastRainingOn(int minutes) {
    return 'Teraz pada, jeszcze co najmniej $minutes min';
  }

  @override
  String nowcastDry(int minutes) {
    return 'Sucho przez najbliższe $minutes min';
  }

  @override
  String get sunAndMoon => 'Słońce i księżyc';

  @override
  String get moonNew => 'Nów';

  @override
  String get moonWaxingCrescent => 'Przybywający sierp';

  @override
  String get moonFirstQuarter => 'Pierwsza kwadra';

  @override
  String get moonWaxingGibbous => 'Przybywający garb';

  @override
  String get moonFull => 'Pełnia';

  @override
  String get moonWaningGibbous => 'Ubywający garb';

  @override
  String get moonLastQuarter => 'Ostatnia kwadra';

  @override
  String get moonWaningCrescent => 'Ubywający sierp';

  @override
  String moonLit(int percent) {
    return 'Oświetlenie $percent %';
  }

  @override
  String daylightLength(int hours, int minutes) {
    return '$hours h $minutes min dnia';
  }

  @override
  String h10Battery(int level) {
    return 'Bateria $level %';
  }

  @override
  String get h10BatteryUnknown => 'Bateria jeszcze nieodczytana';

  @override
  String h10BatteryChecked(String date) {
    return 'Sprawdzono $date';
  }

  @override
  String get h10BatteryLowHint =>
      'Niski poziom: wkrótce wymień baterię CR2025.';

  @override
  String get h10BatteryCheck => 'Sprawdź baterię';

  @override
  String get h10BatteryUnreachable =>
      'H10 nie odpowiedział. Załóż go (lub zwilż styki) i spróbuj ponownie.';

  @override
  String get shareRaceCalendar => 'Udostępnij kalendarz startów';

  @override
  String get raceSeasonTitle => 'Mój sezon startowy';

  @override
  String get raceShareStylePoster => 'Plakat';

  @override
  String get raceShareStyleTickets => 'Bilety';

  @override
  String get raceShareStyleTimeline => 'Neonowa oś czasu';

  @override
  String get raceShareStyleMagazine => 'Magazyn';

  @override
  String get raceShareShowTarget => 'Pokaż czasy docelowe';

  @override
  String get bpOptimal => 'OPTYMALNE';

  @override
  String get bpHighNormal => 'WYSOKIE PRAWIDŁOWE';

  @override
  String get bpLow => 'NISKIE';

  @override
  String get bpLowHint =>
      'Niskie ciśnienie: powód do niepokoju tylko wtedy, gdy masz zawroty głowy lub czujesz się słabo.';

  @override
  String get waistCircumference => 'Obwód talii';

  @override
  String get hipOptional => 'Biodra (opcjonalnie)';

  @override
  String get waistToHeightRatio => 'Stosunek talii do wzrostu';

  @override
  String get waistToHipRatio => 'Stosunek talii do bioder';

  @override
  String get waistRiskLow => 'Bardzo szczupła';

  @override
  String get waistRiskHealthy => 'Zdrowa';

  @override
  String get waistRiskIncreased => 'Podwyższone ryzyko';

  @override
  String get waistRiskHigh => 'Wysokie ryzyko';

  @override
  String get waistHowToMeasure =>
      'Mierz rano, na stojąco, po wydechu: talię w połowie między najniższym żebrem a górną krawędzią kości biodrowej, biodra w najszerszym miejscu.';

  @override
  String get waistNeedsHeight => 'Dodaj wzrost w Ustawienia → Profil.';

  @override
  String get waistNeedsHip => 'Zmierz raz biodra, aby obliczyć WHR.';

  @override
  String get waistSyncsProfile =>
      'Najnowszy pomiar jest też Twoją talią w Ustawieniach.';

  @override
  String get waistChange30d => '30 dni';

  @override
  String get waistChange90d => '90 dni';

  @override
  String get waistChange1y => '1 rok';

  @override
  String get waistDeleteText => 'Usuwa wybrany pomiar talii.';

  @override
  String waistAndHip(String waist, String hip) {
    return '$waist cm · biodra $hip cm';
  }

  @override
  String hipValue(String hip) {
    return 'Biodra $hip cm';
  }

  @override
  String get whtrTargetHint => 'Utrzymuj talię poniżej połowy wzrostu.';

  @override
  String get noWaistYet => 'Nie zmierzono jeszcze talii.';

  @override
  String get enterValidWaist => 'Wpisz talię i biodra od 20 do 300 cm.';

  @override
  String get waistFromProfile => 'Z profilu, bez daty';

  @override
  String get phaseBase => 'BAZA';

  @override
  String get phaseBuild => 'BUDOWANIE';

  @override
  String get phasePeak => 'SZCZYT';

  @override
  String get phaseTaper => 'TAPER';

  @override
  String get phaseRecovery => 'REGENERACJA';

  @override
  String get phaseRace => 'START';

  @override
  String get sessionTypeKey => 'KLUCZOWY';

  @override
  String get sessionTypeLong => 'DŁUGI';

  @override
  String get sessionTypeRecovery => 'REGENERACJA';

  @override
  String get sessionTypeAssessment => 'TEST';

  @override
  String get sessionTypeEndurance => 'WYTRZYMAŁOŚĆ';

  @override
  String get sessionTypeStrength => 'SIŁA';

  @override
  String get sessionTypeYoga => 'JOGA';

  @override
  String get sessionStatusCompleted => 'UKOŃCZONE';

  @override
  String get sessionStatusAdapted => 'DOSTOSOWANE';

  @override
  String get stepWarmUp => 'Rozgrzewka';

  @override
  String get stepCoolDown => 'Schłodzenie';

  @override
  String get stepRecovery => 'Regeneracja';

  @override
  String get stepRest => 'Odpoczynek';

  @override
  String get stepInterval => 'Interwał';

  @override
  String get stepWorkout => 'Trening';

  @override
  String stepRepeat(int n) {
    return 'Powtórz $n×';
  }

  @override
  String get stepOpenEnded => 'Bez limitu';

  @override
  String stepSeconds(int n) {
    return '$n s';
  }

  @override
  String get objectiveOptionalVariety =>
      'Opcjonalna różnorodność wybrana w ustawieniach';

  @override
  String get objectiveStrengthSupport => 'Siła wspierająca Twój trening';

  @override
  String objectiveIntervals(String goal) {
    return 'Interwały pod $goal';
  }

  @override
  String objectiveSteady(String sport, String goal) {
    return 'Równy trening jakościowy ($sport) pod $goal';
  }

  @override
  String objectiveEasyRecovery(String sport, String goal) {
    return 'Lekko ($sport): regeneracja wokół $goal';
  }

  @override
  String objectiveEasyEndurance(String sport, String goal) {
    return 'Lekka wytrzymałość ($sport) pod $goal';
  }

  @override
  String objectiveLong(String sport, String goal) {
    return 'Długi trening ($sport) pod $goal';
  }

  @override
  String unmetWeekMinutes(int minutes, String sport, String goal) {
    return 'Tydzień ma $minutes min, za mało na długi trening ($sport) pod $goal.';
  }

  @override
  String unmetWeekHours(String hours, String what) {
    return 'Tydzień ma $hours h, za mało na: $what.';
  }

  @override
  String unmetTrainingDays(String what) {
    return 'Za mało dni treningowych na: $what.';
  }

  @override
  String get altMoveOneEvent => 'Przenieś jedno z wydarzeń';

  @override
  String get altMarkOneCancelled => 'Oznacz jedno jako odwołane';

  @override
  String altMakePriorityB(String goal) {
    return 'Nadaj $goal priorytet B';
  }

  @override
  String altSkipGoal(String goal) {
    return 'Pomiń $goal';
  }

  @override
  String altTreatAsTraining(String goal) {
    return 'Potraktuj $goal jako wydarzenie treningowe';
  }

  @override
  String altControlledEffort(String goal) {
    return 'Przejedź $goal z kontrolowanym wysiłkiem';
  }

  @override
  String conflictSameDay(String a, String b) {
    return '$a i $b wypadają tego samego dnia. Tylko w jednym można się ścigać.';
  }

  @override
  String conflictBothPriorityA(String a, String b, int gap, int more) {
    return '$a i $b mają oba priorytet A i dzieli je $gap dni. Regeneracja po pierwszym i szlifowanie formy przed drugim wymagają o $more dni więcej.';
  }

  @override
  String conflictFlexibleOverlap(
    String a,
    String b,
    int gap,
    int overlap,
    String skip,
  ) {
    return '$a i $b dzieli $gap dni i nakładają się na $overlap dni. $skip jest oznaczone jako elastyczne: rezygnacja z niego zwolniłaby tygodnie przed drugim wydarzeniem.';
  }

  @override
  String conflictRecoveryOverlap(String a, String b, int gap, int overlap) {
    return '$a i $b dzieli $gap dni: regeneracja po pierwszym nakłada się na szlifowanie formy przed drugim o $overlap dni. Przygotowanie o niższym priorytecie jest ograniczane, by chronić drugie.';
  }

  @override
  String conflictTightSpacing(String a, String b, int gap, int spare) {
    return '$a i $b dzieli $gap dni. Regeneracja i szlifowanie formy mieszczą się z zapasem $spare dni, więc każde potknięcie nie zostawia miejsca.';
  }

  @override
  String seasonShortened(int n, int of) {
    return 'W $n z $of tygodni czas w tygodniu nie mieści pełnych długich treningów każdego celu, więc są skracane razem.';
  }

  @override
  String seasonAlternating(int n) {
    return 'W $n tygodniach tydzień nie mieści wszystkich długich treningów; sporty się zmieniają.';
  }

  @override
  String seasonLongAway(int n) {
    return 'W $n tygodniach długi trening ponad dwóch i pół godziny wypada poza zwykłym dniem z powodu dni odpoczynku i innych treningów.';
  }

  @override
  String seasonMovedOntoEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n przeniesionego treningu wypada w dniu wydarzenia lub w dniu odpoczynku przed nim. Plan zostawia je tam, gdzie je umieściłeś.',
      many:
          '$n przeniesionych treningów wypada w dniu wydarzenia lub w dniu odpoczynku przed nim. Plan zostawia je tam, gdzie je umieściłeś.',
      few:
          '$n przeniesione treningi wypadają w dniu wydarzenia lub w dniu odpoczynku przed nim. Plan zostawia je tam, gdzie je umieściłeś.',
      one:
          '$n przeniesiony trening wypada w dniu wydarzenia lub w dniu odpoczynku przed nim. Plan zostawia go tam, gdzie go umieściłeś.',
    );
    return '$_temp0';
  }

  @override
  String seasonNoRoom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n treningu pominięto, bo wybrane dla nich ćwiczenia trwały dłużej niż czas pozostały w tygodniu.',
      many:
          '$n treningów pominięto, bo wybrane dla nich ćwiczenia trwały dłużej niż czas pozostały w tygodniu.',
      few:
          '$n treningi pominięto, bo wybrane dla nich ćwiczenia trwały dłużej niż czas pozostały w tygodniu.',
      one:
          '$n trening pominięto, bo wybrane dla niego ćwiczenia trwały dłużej niż czas pozostały w tygodniu.',
    );
    return '$_temp0';
  }

  @override
  String seasonMovedHardNearEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n przeniesionego ciężkiego treningu wypada w lekkich dniach po wydarzeniu. Plan zostawia je tam, gdzie je umieściłeś.',
      many:
          '$n przeniesionych ciężkich treningów wypada w lekkich dniach po wydarzeniu. Plan zostawia je tam, gdzie je umieściłeś.',
      few:
          '$n przeniesione ciężkie treningi wypadają w lekkich dniach po wydarzeniu. Plan zostawia je tam, gdzie je umieściłeś.',
      one:
          '$n przeniesiony ciężki trening wypada w lekkich dniach po wydarzeniu. Plan zostawia go tam, gdzie go umieściłeś.',
    );
    return '$_temp0';
  }

  @override
  String get seasonEventWeeks =>
      'W tygodniach z wydarzeniem liczy się ono jako trening, więc reszta tygodnia jest lżejsza.';

  @override
  String seasonUnmet(int n, String detail) {
    return 'W $n tygodniach dni treningowe nie mieszczą każdego chronionego treningu: $detail';
  }

  @override
  String seasonNoHistory(String sport, String priority) {
    return 'W Twojej historii nie ma ostatnio dyscypliny $sport, więc plan dla celu o priorytecie $priority jest wstępny.';
  }

  @override
  String get zoneRecovery => 'Regeneracja';

  @override
  String workoutSentKeptInFjelia(String provider, String items) {
    return 'Wysłano do $provider. Tylko w Fjelia: $items.';
  }

  @override
  String paceGuideRange(String low, String high) {
    return 'Wskazówka tempa $low–$high';
  }

  @override
  String get paceGuideFromGoal => ', oszacowana z Twojego celu';

  @override
  String paceGuideGoalFlat(String pace) {
    return ' · tempo docelowe na płaskim $pace';
  }

  @override
  String get paceGuideHeartRateDecides => 'Decyduje tętno.';

  @override
  String get moveKeyRestDay => 'dzień odpoczynku';

  @override
  String get moveKeyEvent => 'wydarzenie';

  @override
  String get moveKeyEasyOnly => 'tylko lekko';

  @override
  String get moveKeyHasSession => 'ma trening';

  @override
  String get calendarCompleted => 'Ukończone';

  @override
  String get calendarPlanned => 'Zaplanowane';

  @override
  String get recentlyDeleted => 'Ostatnio usunięte';

  @override
  String get recentlyDeletedExplain =>
      'Usunięte aktywności pozostają usunięte, także po ponownej synchronizacji urządzeń. Przywróć jedną, aby ją odzyskać; jej źródło ponownie wyśle trasę i krzywe, jeśli nadal je ma.';

  @override
  String get noDeletedActivities => 'Brak usuniętych aktywności.';

  @override
  String activityDeleted(String name) {
    return 'Usunięto: $name';
  }

  @override
  String activityRestored(String name) {
    return 'Przywrócono: $name';
  }

  @override
  String activityRestoredSummaryOnly(String name) {
    return 'Przywrócono $name z sumami; jego źródło nie wysyła już trasy ani krzywych.';
  }

  @override
  String deletedOn(String date) {
    return 'usunięto $date';
  }

  @override
  String get restore => 'Przywróć';

  @override
  String get coachWhyThisToday => 'Dlaczego dziś ten trening?';

  @override
  String get coachHowDidItGo => 'Jak poszedł ten trening?';

  @override
  String get coachWhyRestDay => 'Dlaczego to dzień odpoczynku?';

  @override
  String get coachWhatInstead => 'Co zrobić zamiast tego?';

  @override
  String get newChat => 'Nowy czat';

  @override
  String weekOfPlanned(String duration) {
    return 'z $duration zaplanowanych';
  }

  @override
  String get weekDoneNothingPlanned =>
      'ukończono · brak zaplanowanych treningów';

  @override
  String sessionDropped(String reason, String duration) {
    return '$reason · $duration pominięto';
  }

  @override
  String get importTitle => 'Import';

  @override
  String get stravaArchive => 'Archiwum Strava';

  @override
  String get stravaArchiveZip => 'Archiwum Strava (ZIP)';

  @override
  String get stravaArchiveSubtitle =>
      'Cała Twoja historia Strava z trasami i zdjęciami';

  @override
  String get stravaIntro =>
      'Przenieś całą historię Strava do Fjelia: aktywności z trasą, tętnem i mocą oraz ich zdjęcia.';

  @override
  String get stravaHowTo =>
      'Na strava.com: Ustawienia → Moje konto → Pobierz lub usuń konto → Poproś o archiwum. Strava wyśle Ci plik ZIP e-mailem; wybierz go tutaj bez rozpakowywania.';

  @override
  String get stravaChooseZip => 'Wybierz ZIP';

  @override
  String get stravaReading => 'Odczytywanie archiwum…';

  @override
  String get stravaNotArchive =>
      'Ten ZIP nie jest archiwum konta Strava: brakuje activities.csv.';

  @override
  String stravaFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Znaleziono $count aktywności',
      many: 'Znaleziono $count aktywności',
      few: 'Znaleziono $count aktywności',
      one: 'Znaleziono $count aktywność',
    );
    return '$_temp0';
  }

  @override
  String stravaWithFiles(int count) {
    return '$count z zapisem (trasa i krzywe)';
  }

  @override
  String stravaPhotos(int photos, int videos) {
    return 'Zdjęcia: $photos, filmy: $videos';
  }

  @override
  String stravaAlready(int count) {
    return 'Duplikaty: $count, już w Fjelia lub dwa razy w Strava: dodawane są tylko brakujące zdjęcia';
  }

  @override
  String stravaDeletedSkip(int count) {
    return 'Wcześniej usunięte: $count, pominięto';
  }

  @override
  String stravaNew(int count) {
    return 'Nowe: $count';
  }

  @override
  String stravaStorage(int mb) {
    return 'około $mb MB na zdjęcia i filmy';
  }

  @override
  String get stravaPrivacy =>
      'Wszystko jest odczytywane na tym urządzeniu. Nic nie jest wysyłane i nie potrzeba logowania do Strava.';

  @override
  String stravaImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importuj $count aktywności',
      many: 'Importuj $count aktywności',
      few: 'Importuj $count aktywności',
      one: 'Importuj $count aktywność',
    );
    return '$_temp0';
  }

  @override
  String get stravaImporting => 'Importowanie archiwum Strava';

  @override
  String stravaProgressActivities(String done, String total) {
    return 'Aktywności: $done / $total';
  }

  @override
  String stravaImportedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zaimportowano $count aktywności',
      many: 'Zaimportowano $count aktywności',
      few: 'Zaimportowano $count aktywności',
      one: 'Zaimportowano $count aktywność',
    );
    return '$_temp0';
  }

  @override
  String stravaProgressPhotos(int count) {
    return 'Zdjęcia: zaimportowano $count';
  }

  @override
  String stravaProgressDuplicates(int count) {
    return 'Duplikaty: pominięto $count';
  }

  @override
  String stravaProgressDeleted(int count) {
    return 'Wcześniej usunięte: pominięto $count';
  }

  @override
  String stravaProgressErrors(int count) {
    return 'Błędy: $count';
  }

  @override
  String get stravaKeepOpen =>
      'W tym czasie możesz korzystać z aplikacji. Nie zamykaj Fjelia, dopóki import się nie zakończy.';

  @override
  String get stravaComplete => 'Import Strava zakończony';

  @override
  String get stravaPartial => 'Import Strava niekompletny';

  @override
  String get stravaCancelled => 'Import Strava anulowany';

  @override
  String get stravaShowErrors => 'Pokaż błędy';

  @override
  String get stravaAgainHint =>
      'Ponowny import tego samego archiwum doda tylko to, czego nadal brakuje.';

  @override
  String get renameActivity => 'Zmień nazwę aktywności';

  @override
  String get activityTitleLabel => 'Tytuł';

  @override
  String get activityTitleKept =>
      'Twój tytuł zostaje po ponownej synchronizacji aktywności. Zmienia się tylko w Fjelia, nie na platformie, z której pochodzi.';

  @override
  String originalTitle(String name) {
    return 'Oryginał: $name';
  }

  @override
  String get useOriginalTitle => 'Użyj oryginalnego tytułu';

  @override
  String get loadOlderActivities => 'Wczytaj starsze aktywności';

  @override
  String get noOlderActivities => 'Brak starszych aktywności';

  @override
  String get maxSpeed => 'Maks. prędkość';

  @override
  String get caloriesLabel => 'Kalorie';

  @override
  String get activityDescription => 'Opis';

  @override
  String get nightCurves => 'Krzywe nocne';

  @override
  String get noPhaseTimeline =>
      'Ten zegarek nie podaje, kiedy wystąpiła każda faza snu, tylko sumy powyżej. To HRV i stres zmierzone w nocy.';

  @override
  String get stagesEstimated =>
      'Oszacowane przez Fjelia na podstawie HRV i stresu zmierzonych w nocy przez zegarek COROS. Sumy faz pochodzą od COROS; to, kiedy wystąpiła każda faza, jest przybliżeniem.';

  @override
  String get nightCurvesBasis =>
      'HRV i stres zmierzone w nocy. Na ich podstawie powstało oszacowanie faz powyżej.';

  @override
  String get swimShort =>
      'Zwykle wystarczy woda. Żele energetyczne nie są potrzebne: zwykły posiłek przed i po wystarczy na ten trening pływacki.';

  @override
  String get swimPoolLong =>
      'Rozważ napój z węglowodanami w dłuższych przerwach między seriami, zwłaszcza przy intensywnym treningu. Żele na basenie nie są potrzebne.';

  @override
  String get swimOpenFeeds =>
      'Zaplanuj węglowodany i płyny wokół dostępnych okazji do jedzenia (łódź, kajak, brzeg). Nie polegaj na jedzeniu, którego nie da się bezpiecznie dosięgnąć podczas pływania.';

  @override
  String get swimOpenUnsupported =>
      'Bez jedzenia podczas pływania bez asysty: dobrze się posil wcześniej, nie wychodź poza to, co to pokrywa, i uzupełnij zaraz po.';

  @override
  String get swimOpenFeedsUnknown =>
      'Wody otwarte: ustaw w Edytuj strategię, czy jedzenie jest możliwe (z asystą lub bez).';

  @override
  String get swimFluidPool =>
      'Nawodnienie liczy się też na basenie: w wodzie pocisz się mniej niż na lądzie, ale nie wcale. Postaw podpisany bidon na brzegu i pij w przerwach.';

  @override
  String get swimFluidOpen =>
      'Prognozy dla powietrza nie podają temperatury wody, a zimna woda tłumi pragnienie: pij przed startem, przy każdym jedzeniu i zaraz po.';

  @override
  String get swimBeforeAfter =>
      'Przed: znany posiłek z węglowodanami 1–4 h wcześniej. Po: około 1 g węglowodanów na kg i 20–25 g białka; jeśli się ważyłeś, wypij około 1,5 l na każdy utracony kg, z odrobiną sodu.';

  @override
  String get swimNoDuration =>
      'Bez planowanego czasu: przy większości treningów wystarczy woda przy brzegu basenu; napój z węglowodanami dodaj tylko przy pływaniu dłuższym niż 90 minut.';

  @override
  String swimCarryPool(String bottles, String bottleMl, String drinkCarbs) {
    return 'Bez żeli. Bidon przy brzegu basenu: $bottles × $bottleMl ml; $drinkCarbs g węglowodanów pochodzi z napoju.';
  }

  @override
  String swimCarryOpen(String bottles, String bottleMl, String drinkCarbs) {
    return 'Bez żeli podczas pływania. Przy jedzeniu: $bottles × $bottleMl ml; $drinkCarbs g węglowodanów pochodzi z napoju.';
  }

  @override
  String swimPerBreak(String carbs, String fluid) {
    return 'Na każde 20 minut, w przerwie lub przy jedzeniu: około $carbs g węglowodanów i $fluid ml.';
  }

  @override
  String get feedsLabel => 'Jedzenie (wody otwarte)';

  @override
  String get feedsSupported => 'Z asystą (łódź, kajak, brzeg)';

  @override
  String get feedsUnsupported => 'Bez asysty';

  @override
  String get feedsUnknown => 'Nieznane';

  @override
  String get ecgTitle => 'EKG';

  @override
  String get ecgChooseDevice => 'Wybierz Polar H10';

  @override
  String get ecgStart => 'Nagraj EKG';

  @override
  String get ecgStopSave => 'Zatrzymaj i zapisz';

  @override
  String get ecgImport => 'Importuj plik EKG';

  @override
  String get ecgHistory => 'Historia EKG';

  @override
  String get ecgWaveform => 'Przebieg';

  @override
  String get ecgReport => 'Raport';

  @override
  String get ecgExportCsv => 'Eksportuj przebieg (CSV)';

  @override
  String get ecgExportMetadata => 'Eksportuj metadane EKG';

  @override
  String get ecgExportOriginal => 'Udostępnij oryginalny plik';

  @override
  String get ecgRecording => 'Nagrywanie EKG';

  @override
  String get ecgRecordingDate => 'Data i godzina nagrania';

  @override
  String get ecgLinkedWorkout => 'Powiązany trening';

  @override
  String get ecgIndependent => 'Brak powiązanego treningu';

  @override
  String get ecgNoRecordings => 'Brak nagrań EKG.';

  @override
  String ecgSamples(int count) {
    return 'Próbki: $count';
  }

  @override
  String ecgSignalGaps(int count) {
    return 'Przerwy w sygnale: $count';
  }

  @override
  String get ecgDeleteConfirm =>
      'Trwale usunąć to nagranie i jego oryginalny plik?';

  @override
  String get ecgDescription =>
      'Nagrywaj z Polar H10, importuj przebiegi CSV lub przechowuj raporty PDF.';

  @override
  String get ecgPrivacy =>
      'Przechowywane na tym urządzeniu i uwzględniane w kopiach zapasowych. Surowe sygnały nie są wysyłane do trenera.';

  @override
  String get ecgLimitations =>
      'Do osobistego nagrywania i przeglądania. HRV z EKG i jakość sygnału nie są tu walidowane; nie jest obliczana żadna diagnoza ani wynik regeneracji.';

  @override
  String get ecgImportLimitations =>
      'Eksporty PDF z Garmin i Apple Watch to raporty. Przebiegi wymagają kolumn CSV time_seconds (lub time_ms) i ecg_uv (lub ecg_mv).';

  @override
  String get ecgReportOnly =>
      'Tylko raport. Brak surowych próbek przebiegu. Udostępnij oryginalny plik, aby wyświetlić raport.';

  @override
  String get indoorTitle => 'Trening w pomieszczeniu';

  @override
  String get indoorEquipment => 'Sprzęt fitness';

  @override
  String get indoorChooseEquipment => 'Wybierz sprzęt';

  @override
  String get indoorChooseHeartRate => 'Wybierz czujnik tętna';

  @override
  String get indoorStart => 'Rozpocznij nagrywanie';

  @override
  String get indoorPause => 'Wstrzymaj nagrywanie';

  @override
  String get indoorFinish => 'Zakończ i zapisz';

  @override
  String get indoorSaved => 'Zapisano w historii aktywności';

  @override
  String get indoorExportFit => 'Udostępnij aktywność FIT';

  @override
  String get indoorUnfinished => 'Niedokończone nagrania';

  @override
  String get indoorReviewResume => 'Przejrzyj lub wznów';

  @override
  String get indoorDiscard => 'Odrzuć nagranie';

  @override
  String get indoorDiscardConfirm =>
      'Trwale odrzucić to niedokończone nagranie?';

  @override
  String get indoorExternalHeartRate => 'Użyj zewnętrznego czujnika tętna';

  @override
  String get indoorEquipmentHeartRate => 'Wyłączone: użyj tętna ze sprzętu';

  @override
  String get indoorCurrentInterval => 'Bieżący interwał';

  @override
  String get indoorNextInterval => 'Następny interwał';

  @override
  String get indoorPlanComplete => 'Zaplanowane interwały ukończone';

  @override
  String get indoorAuthorizeControl => 'Zezwól na sterowanie sprzętem';

  @override
  String get indoorManualOverride => 'Użyj sterowania ręcznego';

  @override
  String get indoorAutoPower => 'Automatycznie podążaj za mocą interwału';

  @override
  String get indoorApplyTarget => 'Zastosuj cel';

  @override
  String get indoorDescription =>
      'Połącz sprzęt Bluetooth FTMS i nagraj trening w pomieszczeniu.';

  @override
  String get indoorKeepOpen =>
      'Nagrywanie trwa po przełączeniu aplikacji lub zablokowaniu ekranu. Wstrzymanie zatrzymuje zapis danych; aby zatrzymać maszynę, użyj jej przycisków.';

  @override
  String get indoorFitHint =>
      'Zapisz plik FIT lub otwórz go w zgodnej aplikacji treningowej przez menu udostępniania.';

  @override
  String get indoorNoEquipment =>
      'Nie znaleziono sprzętu FTMS. Wybudź maszynę i włącz jej połączenie Bluetooth.';

  @override
  String get indoorControlPrompt =>
      'Pozwolić Fjelia zmieniać cele w tym treningu? Pozostań w pobliżu przycisków maszyny. W każdej chwili możesz przejść na sterowanie ręczne.';

  @override
  String get indoorTreadmillSafety =>
      'Przypnij klucz bezpieczeństwa i pozostań w pobliżu przycisków. Potwierdzaj tylko małe zmiany, do 0,5 km/h lub 1% nachylenia. Większe zmiany wprowadzaj przyciskami maszyny.';

  @override
  String get recordingTime => 'Czas nagrania';

  @override
  String get recordingSpeed => 'Prędkość';

  @override
  String get recordingPower => 'Moc';

  @override
  String get recordingCadence => 'Kadencja / tempo wiosłowania';

  @override
  String get recordingIncline => 'Nachylenie';

  @override
  String get recordingResistance => 'Opór';

  @override
  String get recordingSource => 'Źródło';

  @override
  String get recordingNext => 'Następny krok';

  @override
  String get recordingConnecting => 'Łączenie';

  @override
  String get recordingReconnecting => 'Ponowne łączenie';

  @override
  String get recordingInterrupted => 'Przerwano';

  @override
  String get recordingPaused => 'Wstrzymano';

  @override
  String get indoorMatrixReadOnly =>
      'Tylko nagrywanie bieżni Matrix. Prędkość i nachylenie ustawiaj na konsoli; zdalne sterowanie nie zostało sprawdzone dla tego modelu.';

  @override
  String ecgCoverage(String value) {
    return 'Pokrycie próbek: $value%';
  }

  @override
  String get recordingBeforeRestore =>
      'Zakończ nagrywanie z urządzenia przed przywróceniem kopii zapasowej.';

  @override
  String get gymTitle => 'Bieżnie na siłowni';

  @override
  String get gymDescription =>
      'Nagrywaj telefonem, importuj treningi xID lub zeskanuj podsumowanie z konsoli.';

  @override
  String get gymDirectConnection => 'Połączenie bezpośrednie';

  @override
  String get gymConsoleSupport =>
      'Możliwości połączenia zależą od konsoli. Starsza konsola Matrix może obsługiwać xID zamiast danych Bluetooth na żywo.';

  @override
  String get gymFindEquipment => 'Znajdź sprzęt na siłowni';

  @override
  String get gymLiveAvailable =>
      'Ta konsola może wysyłać dane treningowe bezpośrednio do Fjelia.';

  @override
  String get gymLiveUnavailable =>
      'Nie znaleziono obsługiwanych danych na żywo. Zaimportuj treningi xID lub zapisz podsumowanie z konsoli.';

  @override
  String get gymSpeedOnly =>
      'Dostępne są prędkość i kadencja. To połączenie nie podaje nachylenia ani nie pozwala na zdalne sterowanie.';

  @override
  String get gymUseMachine => 'Użyj tej maszyny';

  @override
  String get gymConnectionReport => 'Raport połączenia';

  @override
  String get gymShareReport => 'Udostępnij raport połączenia';

  @override
  String get gymXid => 'Matrix xID';

  @override
  String get gymXidDescription =>
      'Importuj treningi na bieżni zapisane przez sieć xID Twojej siłowni.';

  @override
  String get gymPortal => 'Portal Netpulse siłowni';

  @override
  String get gymPortalHelp =>
      'Wpisz adres portalu Netpulse podany przez siłownię.';

  @override
  String get gymPasscode => 'Kod xID';

  @override
  String get gymSessionHelp =>
      'Twoja sesja jest bezpiecznie przechowywana. Kod nie jest zapisywany.';

  @override
  String get gymAutoSync => 'Synchronizuj treningi xID automatycznie';

  @override
  String gymLastDays(int days) {
    return 'Ostatnie $days dni';
  }

  @override
  String get gymLoadWorkouts => 'Wczytaj treningi';

  @override
  String get gymNoWorkouts =>
      'Nie znaleziono treningów na bieżni w tym okresie.';

  @override
  String gymSkipped(int count) {
    return 'Pominięto nieczytelne treningi: $count.';
  }

  @override
  String gymImported(int count, int duplicates) {
    return 'Zaimportowano treningi: $count; pominięto duplikaty: $duplicates.';
  }

  @override
  String get gymSummary => 'Podsumowanie z bieżni';

  @override
  String get gymSummaryDescription =>
      'Zrób zdjęcie ekranu końcowego konsoli, a następnie sprawdź wartości przed zapisaniem.';

  @override
  String get gymTakePhoto => 'Zrób zdjęcie';

  @override
  String get gymChoosePhoto => 'Wybierz zdjęcie';

  @override
  String get gymReview =>
      'Sprawdź jednostki, godzinę startu i wartości. Zdjęcia są odczytywane w telefonie. Zapisywane jest tylko podsumowanie treningu.';

  @override
  String get gymStartTime => 'Start treningu';

  @override
  String get gymDurationHelp => 'Wpisz mm:ss lub hh:mm:ss, np. 30:00.';

  @override
  String get gymDistanceUnit => 'Jednostka dystansu';

  @override
  String get gymCalories => 'Kalorie';

  @override
  String get manualRecordTitle => 'Nagraj aktywność';

  @override
  String get manualRecordDescription =>
      'Nagraj aktywność z opcjonalnym GPS, EKG i tętnem. Nagrywanie trwa po przełączeniu aplikacji lub zablokowaniu ekranu, dopóki nie naciśniesz Wstrzymaj lub Stop.';

  @override
  String get manualTreadmill => 'Bieg na bieżni';

  @override
  String get manualChooseH10 => 'Wybierz Polar H10';

  @override
  String get manualRecordEcg => 'Nagraj EKG z Polar H10';

  @override
  String get manualChooseHelp => 'Wybierz Polar H10, aby nagrać EKG i tętno.';

  @override
  String manualEcgSegments(int count) {
    return 'Powiązane odcinki EKG: $count';
  }

  @override
  String get manualEcgInterrupted =>
      'EKG zatrzymane. Licznik aktywności nadal działa.';

  @override
  String get manualRestartEcg => 'Uruchom ponownie nagrywanie EKG';

  @override
  String get manualFinalDistance => 'Dystans końcowy (opcjonalnie)';

  @override
  String get manualDiscardNote =>
      'Odrzucić tę aktywność? Nagrania EKG pozostaną w historii EKG.';

  @override
  String get manualRecordHeartRate => 'Nagrywaj tętno';

  @override
  String get manualChooseHr => 'Wybierz czujnik tętna';

  @override
  String get manualHrWithEcg => 'Używa tego samego połączenia z H10 co EKG.';

  @override
  String get manualRecordGps => 'Nagrywaj trasę GPS i dystans';

  @override
  String get manualGpsHelp =>
      'Dla aktywności na zewnątrz. Zezwól na dokładną lokalizację, aby nagrywać trasę przy wyłączonym ekranie.';

  @override
  String get manualGpsWaiting => 'Oczekiwanie na dokładną pozycję GPS';

  @override
  String manualGpsAccuracy(int meters) {
    return 'Dokładność GPS: $meters m';
  }

  @override
  String get manualRecordBp => 'Uwzględnij pomiary ciśnienia';

  @override
  String get manualBpHelp =>
      'Pokazuje pomiary z Hilo, Aktiia i Zdrowia wykonane podczas tego nagrania, także po późniejszych synchronizacjach.';

  @override
  String get manualBpUnavailable => 'Nie udało się wczytać pomiarów ciśnienia.';

  @override
  String get manualBpEmpty => 'Brak pomiarów ciśnienia podczas tego nagrania.';

  @override
  String get manualHrDisconnected => 'Czujnik tętna rozłączony.';

  @override
  String get manualReconnectHr => 'Połącz ponownie czujnik tętna';

  @override
  String get manualBackgroundNotification =>
      'Nagrywanie trwa przy wyłączonym ekranie';

  @override
  String get ecgAskCoach => 'Omów z trenerem AI';

  @override
  String get ecgCoachWarningTitle => 'To nie jest porada medyczna';

  @override
  String get ecgCoachWarningBody =>
      'Trener AI nie jest lekarzem i nie może postawić diagnozy. EKG z pasa piersiowego ma tylko jedno odprowadzenie: nie wyklucza zawału ani innej choroby serca, a analiza może być błędna.\n\nBól lub ucisk w klatce piersiowej, duszność, ból ręki, żuchwy lub pleców, zimny pot albo omdlenie: zadzwoń teraz pod 112 lub 999. Nie czekaj na odpowiedź AI.\n\nPrzeanalizowane wartości i 10 sekund surowego sygnału trafiają do modelu AI wybranego w ustawieniach AI.';

  @override
  String get ecgCoachUnderstood => 'Rozumiem';

  @override
  String get ecgCoachBanner =>
      'To nie jest porada medyczna. AI nie jest lekarzem i nie wykluczy zawału. W nagłym przypadku zadzwoń pod 112 lub 999.';

  @override
  String get ecgCoachCardTitle => 'Wstępna analiza EKG';

  @override
  String get statusMeasured => 'Zmierzono';

  @override
  String get ecgQuestionOverview => 'Co pokazuje moje EKG?';

  @override
  String get ecgQuestionRhythm => 'Czy mój rytm serca jest regularny?';

  @override
  String get ecgQuestionDoctor => 'Czy lekarz powinien to obejrzeć?';

  @override
  String get ecgFollowSymptoms =>
      'Przy jakich objawach powinienem iść do lekarza?';

  @override
  String get ecgFollowRiskFactors => 'Jak moje czynniki ryzyka to zmieniają?';

  @override
  String get ecgFollowTraining => 'Czy mogę normalnie trenować?';

  @override
  String get ecgFollowBetterRecording => 'Jak nagrać lepsze EKG?';

  @override
  String get manualTreadmillConnect =>
      'Połącz bieżnię (Bluetooth, opcjonalnie)';

  @override
  String get manualTreadmillHelp =>
      'Prędkość, dystans i nachylenie pochodzą wtedy z bieżni. Bez połączenia wpisz dystans na końcu.';

  @override
  String get sportIndoorCycling => 'Rower stacjonarny';

  @override
  String get sportElliptical => 'Orbitrek';

  @override
  String get sportStairClimber => 'Stepper schodowy';

  @override
  String get manualWrongMachine => 'Ten sprzęt nie pasuje do wybranego sportu.';

  @override
  String get manualEquipmentHelp =>
      'Połącz sprzęt Bluetooth (FTMS). Prędkość, moc, kadencja i dystans pochodzą z maszyny.';

  @override
  String get plusTitle => 'Zapisz';

  @override
  String get plusStartWorkout => 'Rozpocznij trening';

  @override
  String get plusStartWorkoutHint =>
      'Na żywo z GPS, bieżnią lub rowerem stacjonarnym · EKG i tętno';

  @override
  String get plusGroupTraining => 'Trening';

  @override
  String get plusGroupHeart => 'Serce i krążenie';

  @override
  String get plusGroupBody => 'Ciało';

  @override
  String get plusGroupRecovery => 'Regeneracja';

  @override
  String get plusLogWorkout => 'Zapisz trening';

  @override
  String get plusLogWorkoutHint => 'Dodaj wcześniejszy trening ręcznie';

  @override
  String get plusImport => 'Import';

  @override
  String get plusImportHint => 'Strava, FIT, GPX, bieżnia na siłowni';

  @override
  String get plusEcg => 'Nagraj EKG';

  @override
  String get plusEcgHint => 'Polar H10 lub plik EKG';

  @override
  String get plusHrv => 'Pomiar HRV';

  @override
  String get plusHrvHint => 'Krótki pomiar z Polar H10';

  @override
  String get plusBpMeasure => 'Mierz mankietem Hilo';

  @override
  String get plusBpMeasureHint => 'Sparuj mankiet Hilo przez Bluetooth';

  @override
  String get plusBpLog => 'Zapisz ciśnienie';

  @override
  String get plusBpLogHint => 'Wpisz pomiar';

  @override
  String get plusBpReport => 'Raport Hilo';

  @override
  String get plusBpReportHint => 'Zaimportuj PDF';

  @override
  String get plusSpo2 => 'SpO₂ i tętno';

  @override
  String get plusSpo2Hint => 'Z pulsoksymetru';

  @override
  String get plusWeigh => 'Ważenie';

  @override
  String get plusWeighHint => 'Waga RENPHO przez Bluetooth';

  @override
  String get plusWeightLog => 'Zapisz wagę';

  @override
  String get plusWeightLogHint => 'Waga, tkanka tłuszczowa, BMI';

  @override
  String get plusWaist => 'Talia';

  @override
  String get plusWaistHint => 'Obwód i wskaźniki';

  @override
  String get plusGrip => 'Siła chwytu';

  @override
  String get plusGripHint => 'Pomiar dynamometrem';

  @override
  String get plusSleep => 'Zapisz sen';

  @override
  String get plusSleepHint => 'Czas, sen głęboki i REM';

  @override
  String get recPace => 'Tempo (/km)';

  @override
  String get recAvgPace => 'Śr. tempo';

  @override
  String get recPace500 => 'Tempo (/500 m)';

  @override
  String get recSpeedKmh => 'Prędkość (km/h)';

  @override
  String get recPowerW => 'Moc (W)';

  @override
  String get recDistanceKm => 'Dystans (km)';

  @override
  String get recHeartRate => 'Tętno';

  @override
  String get recMap => 'Mapa';

  @override
  String get recStart => 'Start';

  @override
  String get recResume => 'Wznów';

  @override
  String get recFinish => 'Zakończ';

  @override
  String get recDiscard => 'Odrzuć';

  @override
  String get recLive => 'Nagrywanie';

  @override
  String get recNew => 'Nowa aktywność';

  @override
  String get recCadence => 'Kadencja';

  @override
  String get recMachine => 'Sprzęt';

  @override
  String get recGps => 'GPS';

  @override
  String get recEcg => 'EKG';

  @override
  String get recBloodPressure => 'Ciśnienie krwi';

  @override
  String get recBannerOpen => 'Dotknij, aby otworzyć';

  @override
  String get bpActivityHint =>
      'Mankiety często nie mierzą w ruchu. Pomiary sprzed aktywności lub po niej nie są tu pokazywane.';

  @override
  String objectiveKeyLong(String sport, String goal) {
    return 'Kluczowy długi trening ($sport) pod $goal';
  }

  @override
  String seasonKeyRides(int n) {
    return 'W $n tygodniach kluczowy długi trening rośnie do połowy wydarzenia, raz na blok i nigdy obok innego wydarzenia.';
  }

  @override
  String seasonEventAsLong(int n) {
    return 'W $n tygodniach inne wydarzenie jest długim treningiem dla większego celu.';
  }

  @override
  String objectiveThreshold(String sport, String goal) {
    return 'Progowy trening ($sport) pod $goal';
  }

  @override
  String objectiveHills(String sport, String goal) {
    return 'Podbiegi ($sport) pod $goal';
  }

  @override
  String objectiveOpeners(String goal) {
    return 'Otwarcie przed $goal';
  }

  @override
  String get planAdjustedTitle => 'Plan dostosowany automatycznie';

  @override
  String planAdjSwap(String session, String day, String from) {
    return '$session: wykonano w $day zamiast w $from.';
  }

  @override
  String planAdjSubstitute(String activity, String session, String from) {
    return '$activity liczy się jako $session z $from.';
  }

  @override
  String planAdjStrengthCredit(String activity, String session) {
    return '$activity pokrywa siłę nóg z $session.';
  }

  @override
  String planAdjMoved(String session, String day) {
    return '$session przechodzi na $day, który się zwolnił.';
  }

  @override
  String planAdjMovedEasy(String session, String day, String activity) {
    return '$session przechodzi na $day, lżej: nogi regenerują się po $activity.';
  }

  @override
  String get planAdjUndone => 'Zmianę cofnięto.';

  @override
  String get shortSessionTitle => 'Krócej niż w planie – dlaczego?';

  @override
  String shortSessionLine(String session, int done, int planned) {
    return '$session: $done z $planned min';
  }

  @override
  String get shortReasonTime => 'Brak czasu';

  @override
  String get shortReasonWeather => 'Pogoda';

  @override
  String get shortReasonFatigue => 'Zmęczenie';

  @override
  String get shortReasonPain => 'Ból';

  @override
  String get shortReasonOther => 'Inne';

  @override
  String get styleTitle => 'Styl';

  @override
  String get styleAuto => 'Automatycznie';

  @override
  String get styleAutoHint =>
      'Zgodnie z telefonem: LightFjelia w dzień, DarkFjelia w nocy.';

  @override
  String get connectMyWhoosh => 'Połącz MyWhoosh';

  @override
  String get myWhooshSubtitle =>
      'Zaloguj się kontem MyWhoosh, aby pobrać jazdy w pomieszczeniu z mocą, kadencją i tętnem.';

  @override
  String get myWhooshCredentialsInfo =>
      'Dane logowania MyWhoosh są przechowywane w postaci zaszyfrowanej na Twoim urządzeniu. Fjelia odczytuje jazdy bezpośrednio z MyWhoosh przez interfejs aplikacji MyWhoosh. Fjelia nie jest powiązana z MyWhoosh.';

  @override
  String get myWhooshTile => 'Jazdy w pomieszczeniu';

  @override
  String get myWhooshSignedInElsewhere =>
      'MyWhoosh pozwala na jedną sesję na konto, a Ty jesteś zalogowany na innym urządzeniu. Zamknij tam MyWhoosh (w razie potrzeby się wyloguj) i spróbuj ponownie.';

  @override
  String get shareWorkout => 'Udostępnij trening';

  @override
  String get shareFitFile => 'Udostępnij jako plik FIT';

  @override
  String get shareFitFileHint =>
      'Dla Strava, COROS, TrainingPeaks i innych aplikacji';

  @override
  String get sendToGarmin => 'Wyślij do Garmin Connect';

  @override
  String get sendToGarminHint => 'Przesyła trening na Twoje konto Garmin';

  @override
  String get sentToGarmin => 'Wysłano do Garmin Connect';

  @override
  String get alreadyOnGarmin => 'Ten trening jest już w Garmin Connect';

  @override
  String get missedWorkoutPastTitle => 'Pominięty trening';

  @override
  String get leaveIt => 'Zostaw';

  @override
  String get reviewChange => 'Sprawdź';

  @override
  String get keepPlan => 'Zachowaj plan';

  @override
  String get missedYesterdayTitle => 'Pominięty wczoraj';

  @override
  String get proposalReplanTitle => 'Przebudować plan?';

  @override
  String get proposalRestTitle => 'Dziś dzień odpoczynku?';

  @override
  String get proposalRecoveryTitle => 'Dziś tylko lekko?';

  @override
  String get proposalEasierTitle => 'Dziś nieco lżej?';

  @override
  String get proposalReplanBody =>
      'Obciążenie lub HRV wskazują na przebudowę planu.';

  @override
  String get proposalCardTitle => 'Sugestia na dziś';

  @override
  String get replanMissed => 'Zaplanuj ponownie';

  @override
  String get askBeforePlanChanges => 'Pytaj przed zmianami planu';

  @override
  String get askBeforePlanChangesHint =>
      'Gotowość i trendy podsuwają zmiany, a decyzja należy do Ciebie. Wyłączone: Fjelia sama dostosowuje plan.';

  @override
  String missedOnDayTitle(String day) {
    return 'Pominięto w $day';
  }

  @override
  String missedPastBody(String names) {
    return '$names. Przenieść czy pominąć?';
  }

  @override
  String proposalDropsLine(String title) {
    return '$title wypada';
  }

  @override
  String proposalChangeLine(String from, String to) {
    return '$from → $to';
  }

  @override
  String get proposalAnswered =>
      'Już odpowiedziano, nie ma nic do zdecydowania.';

  @override
  String get ecgTrainingWarningTitle => 'Tylko do treningu';

  @override
  String get ecgTrainingWarningBody =>
      'Fjelia nie odczytuje EKG w sensie medycznym. Trener wyjaśnia tętno, HRV i jakość sygnału wyłącznie na potrzeby treningu. Nie mówi nic o chorobach serca ani zaburzeniach rytmu: w tym celu wyeksportuj nagranie i pokaż je lekarzowi.\n\nBól lub ucisk w klatce piersiowej, duszność, ból ręki, żuchwy lub pleców, zimny pot albo omdlenie: zadzwoń teraz pod 112 lub 999.\n\nTętno, HRV i jakość sygnału trafiają do modelu AI wybranego w ustawieniach AI.';

  @override
  String get ecgQuestionTraining => 'Co moje EKG mówi o treningu?';

  @override
  String get ecgFollowHrv => 'Co HRV mówi o mojej regeneracji?';

  @override
  String get ecgFollowHeartRate => 'Jak zmieniało się moje tętno?';

  @override
  String get bioLeanMuchYounger => 'Dużo młodszy w formie';

  @override
  String get bioLeanYounger => 'Młodszy w formie';

  @override
  String get bioLeanEven => 'Dokładnie według wieku';

  @override
  String get bioLeanOlder => 'Trochę miejsca na poprawę';

  @override
  String get bioLeanMuchOlder => 'Dużo miejsca na poprawę';

  @override
  String get fitnessSameAsAge => 'Sprawność na swój wiek';

  @override
  String get lifespanBandTitle => 'Twoja długość życia';

  @override
  String get lifespanBandNote =>
      'Przedział ze statystyk dla osób o podobnych wartościach, a nie prognoza dla Ciebie.';

  @override
  String get factorHelps => 'Pomaga';

  @override
  String get factorSlows => 'Hamuje';

  @override
  String get bioFactorBloodPressure => 'Ciśnienie krwi';

  @override
  String get bioFactorVisceralFat => 'Tłuszcz trzewny';

  @override
  String get bioFactorLipids => 'Lipidy we krwi';

  @override
  String get bioFactorInflammation => 'Stan zapalny (CRP)';

  @override
  String get bioFactorKidney => 'Czynność nerek';

  @override
  String get bioAgeModelNote =>
      'Wiek sprawności porównuje Twoje VO₂max z normami dla wieku. Długość życia pochodzi z modelu opartego na danych z badań: to nie jest stwierdzenie medyczne ani osobista prognoza.';

  @override
  String fitnessYoungerBy(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years roku młodziej niż Twój wiek',
      many: '$years lat młodziej niż Twój wiek',
      few: '$years lata młodziej niż Twój wiek',
      one: '$years rok młodziej niż Twój wiek',
    );
    return '$_temp0';
  }

  @override
  String fitnessOlderBy(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years roku powyżej Twojego wieku',
      many: '$years lat powyżej Twojego wieku',
      few: '$years lata powyżej Twojego wieku',
      one: '$years rok powyżej Twojego wieku',
    );
    return '$_temp0';
  }

  @override
  String lifespanBandYears(int low, int high) {
    return '$low–$high';
  }

  @override
  String todayAge(int age) {
    return 'Dziś $age';
  }

  @override
  String get vo2ClassBelowAvg => 'poniżej średniej';

  @override
  String get vo2ClassAverage => 'przeciętnie';

  @override
  String get vo2ClassAboveAvg => 'powyżej średniej';

  @override
  String get vo2ClassGood => 'dobrze';

  @override
  String get vo2ClassExcellent => 'doskonale';

  @override
  String get vo2ClassElite => 'elita';

  @override
  String get fjeliaProHint =>
      'FjeliaPro daje Ci bardziej szczegółowe informacje i analizy.';

  @override
  String get rowingStrokeRate => 'Pociągnięcia / min';

  @override
  String rowingStrokeAverage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ø $count pociągnięcia',
      many: 'Ø $count pociągnięć',
      few: 'Ø $count pociągnięcia',
      one: 'Ø 1 pociągnięcie',
    );
    return '$_temp0';
  }

  @override
  String get rowingTapToSwitch => 'Dotknij, aby przełączyć';

  @override
  String get copyAnswer => 'Kopiuj odpowiedź';

  @override
  String get answerCopied => 'Skopiowano ✨';

  @override
  String get coachMemories => 'Memory Cards';

  @override
  String get coachMemoriesIntro =>
      'Powiedz trenerowi, co zawsze powinien wiedzieć. Twoje karty trafiają do każdego czatu.';

  @override
  String get coachMemoryNew => 'Nowa karta';

  @override
  String get coachMemoryTitle => 'Tytuł';

  @override
  String get coachMemoryTitleHint => 'np. Lewe kolano';

  @override
  String get coachMemoryBody => 'Co powinien wiedzieć Twój trener?';

  @override
  String get coachMemoryBodyHint =>
      'np. Zbiegi bolą od wiosny. Podbiegi są w porządku.';

  @override
  String get coachMemoryEmpty => 'Brak kart. Dodaj pierwszą 🔥';

  @override
  String get coachMemoryDeleteQuestion => 'Usunąć tę kartę?';

  @override
  String coachMemoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count karty w głowie trenera',
      many: '$count kart w głowie trenera',
      few: '$count karty w głowie trenera',
      one: '1 karta w głowie trenera',
      zero: 'Brak kart',
    );
    return '$_temp0';
  }

  @override
  String get sportSkiErg => 'SkiErg (narciarstwo biegowe w pomieszczeniu)';

  @override
  String get weatherRain => 'DESZCZ';

  @override
  String weatherLowHigh(int low, int high) {
    return 'Min. $low° · Maks. $high°';
  }

  @override
  String get weatherDayPeak => 'Szczyt dnia';

  @override
  String get weatherDayTotal => 'Suma dnia';

  @override
  String get proTagline => 'Twój trener. Na poziomie pro.';

  @override
  String get proBenefitCoach =>
      'Trener AI z modelem Pro: szybszy, dokładniejszy, z własnym budżetem';

  @override
  String get proBenefitMemory =>
      'Memory Cards: co Twój trener zawsze powinien wiedzieć';

  @override
  String get proBenefitEcg => 'Szczegółowa analiza EKG';

  @override
  String get proBenefitCopy => 'Kopiowanie odpowiedzi jednym dotknięciem';

  @override
  String get proMonthly => 'Miesięcznie';

  @override
  String get proYearly => 'Rocznie';

  @override
  String proPerMonth(String price) {
    return '$price / miesiąc';
  }

  @override
  String proPerYear(String price) {
    return '$price / rok';
  }

  @override
  String get proBestValue => 'NAJLEPSZA CENA';

  @override
  String get proSubscribe => 'Kup FjeliaPro';

  @override
  String get proRestore => 'Przywróć zakupy';

  @override
  String get proManage => 'Zarządzaj subskrypcją';

  @override
  String proActiveUntil(String date) {
    return 'Pro jest aktywne do $date';
  }

  @override
  String get proAutoRenew =>
      'Subskrypcja odnawia się automatycznie, chyba że anulujesz ją co najmniej 24 godziny przed końcem okresu w ustawieniach konta Apple. Płatność jest pobierana z Twojego konta Apple.';

  @override
  String get proTerms => 'Warunki korzystania';

  @override
  String get proPrivacy => 'Prywatność';

  @override
  String get proProblemStore => 'App Store nie dokończył zakupu.';

  @override
  String get proProblemService =>
      'Twój zakup jest, ale nie udało się go jeszcze sprawdzić. Fjelia spróbuje ponownie przy następnym uruchomieniu.';

  @override
  String get proProblemNothing => 'Brak subskrypcji FjeliaPro do przywrócenia.';

  @override
  String get proProblemNotActive => 'Ta subskrypcja się zakończyła.';

  @override
  String get proUnavailable =>
      'Nie można teraz wczytać subskrypcji. Spróbuj ponownie później.';

  @override
  String get proWelcome => 'Witaj w FjeliaPro 🔥';

  @override
  String get proUsesFjeliaAi =>
      'Model Pro odpowiada, gdy w ustawieniach AI wybrano „Fjelia AI”.';

  @override
  String get proToolsTitle => 'Analizy Pro';

  @override
  String get proPlanCheck => 'Sprawdzenie dzisiejszego planu';

  @override
  String get proPlanCheckHint =>
      'Czy dzisiejszy plan pasuje do Twojej regeneracji?';

  @override
  String get proWeekReview => 'Przegląd tygodnia';

  @override
  String get proWeekReviewHint =>
      'Co zadziałało, co zmienić w przyszłym tygodniu';

  @override
  String get proRacePlan => 'Plan startu';

  @override
  String proRacePlanHint(String race) {
    return '$race: tapering, tempo, żywienie';
  }

  @override
  String get proSeason => 'Analiza sezonu';

  @override
  String get proSeasonHint => 'Cele, fazy i ryzyka Twojego sezonu';

  @override
  String get proAnalysisCreate => 'Utwórz analizę';

  @override
  String get proAnalysisRedo => 'Utwórz ponownie';

  @override
  String proAnalysisFrom(String time) {
    return 'Utworzono $time';
  }

  @override
  String get proAnalysisWorking => 'Duży model analizuje…';

  @override
  String get proAnalysisFailed => 'Analiza się nie powiodła. Spróbuj ponownie.';

  @override
  String get proBenefitPlanCheck =>
      'Poranna propozycja i sprawdzenie planu: trener dopracowuje trening dnia';

  @override
  String get proBenefitReview => 'Przegląd tygodnia i analiza sezonu';

  @override
  String get proBenefitRacePlan => 'Plan startu: tapering, tempo, żywienie';

  @override
  String get statsTitle => 'Statystyki';

  @override
  String get statsLast4Weeks => 'Ostatnie 4 tygodnie · na tydzień';

  @override
  String get statsElevation => 'Przewyższenie';

  @override
  String get statsAllTimeTotals => 'Od początku';

  @override
  String get statsBestEfforts => 'Najlepsze wyniki';

  @override
  String get statsLongest => 'Najdłuższe';

  @override
  String get statsMostElevation => 'Największe przewyższenie';

  @override
  String get statsNone => 'Brak aktywności.';

  @override
  String get proBenefitStats =>
      'Statystyki: najlepsze wyniki, ten rok i ostatnie 4 tygodnie';

  @override
  String get statsFourWeeks => '4 tygodnie';

  @override
  String get statsTickerWeek => 'na tydzień, ostatnie 4 tygodnie';

  @override
  String statsTickerYear(String year) {
    return 'w $year';
  }

  @override
  String statsTickerBest(String distance) {
    return 'Najlepsze $distance';
  }

  @override
  String get statsPerWeekShort => '/ tydzień';

  @override
  String get gripLeft => 'Lewa';

  @override
  String get gripRight => 'Prawa';

  @override
  String get muscleShort => 'Mięśnie';

  @override
  String vsYesterday(String arrow) {
    return '$arrow wobec wczoraj';
  }

  @override
  String get proposalProCoach => 'Trener pisze poranne powiadomienie';

  @override
  String get proposalProCoachHint =>
      'FjeliaPro: dzisiejsza gotowość, plan i kontekst zdrowotny trafiają do Fjelia AI Pro, które formułuje propozycję wkrótce po porannej synchronizacji.';

  @override
  String get heatShort => 'Upał';

  @override
  String get coachRevisionLabel => 'Propozycja trenera';

  @override
  String get revisionBefore => 'Przed';

  @override
  String get revisionAfter => 'Po';

  @override
  String get revisionSwapped => 'Zamieniono';

  @override
  String get revisionRestDay => 'Zamiast tego dzień odpoczynku';

  @override
  String get revisionDropped => 'pominięto';

  @override
  String get revisionAccept => 'Przyjmij';

  @override
  String revisionSets(String sets, String reps) {
    return '$sets × $reps';
  }

  @override
  String get testMorningProposal => 'Testuj poranną propozycję';

  @override
  String get testMorningProposalHint =>
      'Uruchamia teraz poranne sprawdzenie z gotowością na żółto; powiadomienie przyjdzie za 5 sekund.';

  @override
  String get proposalRulesEasier =>
      'Regeneracja nie jest jeszcze pełna: dzisiejsze treningi będą krótsze i lżejsze, ich cel zostaje.';

  @override
  String get proposalRulesRecovery =>
      'Wyraźne oznaki zmęczenia: dziś tylko lekko albo odpoczynek.';

  @override
  String get proposalCoachUnavailable =>
      'Nie udało się teraz połączyć z trenerem; to propozycja według reguł.';

  @override
  String get revisionKeep => 'Zostaje zgodnie z planem';

  @override
  String get revisionAlternative => 'Alternatywa';

  @override
  String get revisionTakeAlternative => 'Weź to zamiast tego';

  @override
  String proposalForDay(String day) {
    return 'Propozycja na $day';
  }

  @override
  String get proposalDayTomorrow => 'jutro';

  @override
  String get feelingQuestion => 'Jak się dziś czujesz?';

  @override
  String get feelingGood => 'Dobrze';

  @override
  String get feelingTired => 'Zmęczony';

  @override
  String get feelingSore => 'Zakwasy';

  @override
  String get feelingIll => 'Chory';

  @override
  String get feelingShort => 'Mało czasu';

  @override
  String get feelingAsking => 'Trener znowu myśli…';

  @override
  String get proSwitchTitle => 'Używać ProAI?';

  @override
  String proSwitchBody(String provider) {
    return 'Twoja subskrypcja FjeliaPro jest aktywna. Czy trener ma od teraz używać ProAI zamiast $provider?';
  }

  @override
  String get proAiRouting =>
      'FjeliaPro korzysta z mocniejszej AI do planów startów i sezonu. Twój trener i codzienne sugestie treningowe używają zwykłego modelu Pro.';

  @override
  String proActiveUntilShort(String date) {
    return 'Aktywne do $date';
  }

  @override
  String shortSessionNote(int done, int planned) {
    return 'Krócej niż w planie ($done z $planned min)';
  }

  @override
  String get noteForCoach => 'Notatka dla trenera (opcjonalnie)';

  @override
  String get activityNote => 'Notatka';

  @override
  String get activityNoteAdd => 'Dodaj notatkę dla trenera';

  @override
  String get plusOmronBle => 'Szukaj ciśnieniomierzy BLE';

  @override
  String get plusOmronBleHint =>
      'Szukaj standardowych ciśnieniomierzy Bluetooth i obsługiwanych profili Omron.';

  @override
  String get sleepEcgTitle => 'Nagraj sen';

  @override
  String get sleepEcgHint => 'EKG i ruch z Polar H10';

  @override
  String get sleepEcgDescription =>
      'Jednocześnie rejestruje EKG z częstotliwością 130 Hz i ruch w trzech osiach z częstotliwością 25 Hz. Załóż Polar H10 i trzymaj iPhone’a w zasięgu Bluetooth. Szacowanie faz snu jest opcjonalne i uruchamiane osobno; częstość oddechów ani wyniki medyczne nie są obliczane.';

  @override
  String get sleepEcgStart => 'Rozpocznij nocne nagrywanie';

  @override
  String sleepEcgMotionSamples(int count) {
    return 'Próbki ruchu: $count';
  }

  @override
  String get sleepEcgKeepOpenHint =>
      'Możesz opuścić ten ekran, a nagrywanie będzie trwać. Nie zamykaj Fjelia w przełączniku aplikacji i trzymaj iPhone’a w pobliżu H10. Wymuszone zamknięcie aplikacji przerywa nagrywanie.';

  @override
  String get sleepEcgRawNote =>
      'Surowe dane z nocnego zapisu EKG i ruchu. Możesz osobno uruchomić eksperymentalne szacowanie faz snu. Częstość oddechów ani wyniki medyczne nie są obliczane.';

  @override
  String get sleepEcgExportRaw => 'Eksportuj surowe pliki CSV z EKG i ruchem';

  @override
  String get sleepEcgStagesTitle => 'Szacowane fazy snu';

  @override
  String get sleepEcgStagesButton => 'Oszacuj fazy snu';

  @override
  String get sleepEcgStagesAgain => 'Oszacuj ponownie';

  @override
  String get sleepEcgStagesDisclaimer =>
      'Eksperymentalne oszacowanie na podstawie EKG Polar H10 przy użyciu modelu badawczego wykorzystującego wyłącznie EKG. N1 i N2 są łączone jako sen płytki. To nie jest badanie PSG ani pomiar medyczny.';

  @override
  String get sleepEcgStagesWorking => 'Szacowanie faz snu…';

  @override
  String get sleepEcgStagesFailed =>
      'Nie udało się oszacować faz snu. Sprawdź, czy nagranie jest kompletne, i spróbuj ponownie.';

  @override
  String get replacementPreviewTitle => 'Sprawdź trening zastępczy';

  @override
  String replacementGoalLoad(String objective, int load) {
    return 'Cel: $objective · planowane obciążenie $load';
  }

  @override
  String get replacementHistoryEstimate =>
      'Czas trwania oszacowany na podstawie Twoich ostatnich treningów w tym sporcie.';

  @override
  String get replacementFallbackEstimate =>
      'Brak wystarczających danych z ostatnich treningów w tym sporcie. Czas trwania to ostrożne oszacowanie.';

  @override
  String get replacementRestSuggestion =>
      'Odpoczynek może być lepszym wyborem przy Twoim obecnym planie treningowym.';

  @override
  String get replacementObjectiveRecovery => 'Regeneracja';

  @override
  String get replacementObjectiveBase => 'Wytrzymałość podstawowa';

  @override
  String get replacementObjectiveTempo => 'Tempo';

  @override
  String get replacementObjectiveThreshold => 'Próg';

  @override
  String get replacementObjectiveVo2 => 'VO₂max';

  @override
  String get replacementObjectiveLong => 'Długa wytrzymałość';

  @override
  String get replacementWarningNoHistory =>
      'Brak wystarczającej historii obciążeń z ostatniego czasu dla tego sportu.';

  @override
  String get replacementWarningRunningCap =>
      'Objętość biegania została ostrożnie ograniczona, aby zmniejszyć obciążenie mechaniczne.';

  @override
  String get replacementWarningLong =>
      'Długich lub startowo specyficznych treningów nie da się w pełni zastąpić. Sprawdź krótszy bieg.';

  @override
  String get replacementWarningRace =>
      'Ten trening ma priorytet startowy; jego korzyść specyficzna dla sportu może nie zostać zachowana.';

  @override
  String get replacementWarningSwim =>
      'Część bodźca tlenowego zostaje zachowana, ale nie technika pływania ani specyficzne obciążenie mięśni.';

  @override
  String get replacementWarningStrength =>
      'Treningi siłowe i wytrzymałościowe nie są równoważne i nie mogą zachować tego samego efektu treningowego.';

  @override
  String get replacementWarningNearby =>
      'W ciągu 72 godzin jest inny ciężki trening. Sprawdź regenerację i odstęp między treningami.';

  @override
  String get replacementWarningWeekly =>
      'Ten trening stanowi dużą część pozostałego planowanego obciążenia w tym tygodniu.';

  @override
  String get replacementWarningLowRecovery =>
      'Twój ostatnio zapisany wynik regeneracji jest niski. Rozważ zmniejszenie intensywności lub odpoczynek.';

  @override
  String get replacementWarningRecentVolume =>
      'Twoje obciążenie treningowe z ostatnich siedmiu dni jest wyraźnie wyższe niż w poprzednich siedmiu dniach.';

  @override
  String get replacementTrainingGoal => 'CEL TRENINGOWY';

  @override
  String get replacementPreviewWarnings => 'UWAGI DO PLANU';
}
