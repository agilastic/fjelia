// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get freeAi => 'Free AI';

  @override
  String get freeAiUsageTracking =>
      'Jotta Free AI pysyy luotettavasti kaikkien saatavilla, lähetämme satunnaisen asennustunnisteen. Se auttaa tunnistamaan poikkeavaa käyttöä ja estämään väärinkäyttöön liittyviä pyyntöjä. Tunniste ei sisällä nimeäsi eikä käyttäjätilisi tietoja.';

  @override
  String freeAiDescription(String host) {
    return 'Maksuton tekoälychat ja yhteenvedot $host-palvelun kautta. Erillistä tiliä tai API-avainta ei tarvita. Vahvistuksesi jälkeen viestit sekä terveys- ja harjoitteluyhteenveto lähetetään palveluun.';
  }

  @override
  String get freeAiUnavailable =>
      'Free AI ei ole käytettävissä tässä versiossa. Valitse toinen palveluntarjoaja.';

  @override
  String shareBriefingContextWithName(String name) {
    return 'Yhteenveto terveys- ja harjoittelutiedoistasi lähetetään palveluun $name. Tämä kertaluonteinen suostumus koskee myös tulevia pilvipohjaisia tekoälypalveluja, jotka valitset katsauksia varten.';
  }

  @override
  String get language => 'Kieli';

  @override
  String get languageSystem => 'Järjestelmän oletus';

  @override
  String get settings => 'Asetukset';

  @override
  String get profile => 'Profiili';

  @override
  String get training => 'Harjoittelu';

  @override
  String get weatherLocation => 'Sää ja sijainti';

  @override
  String get display => 'Näyttö';

  @override
  String get connections => 'Yhteydet';

  @override
  String get aiAndMore => 'Tekoäly ja muuta';

  @override
  String get system => 'Järjestelmä';

  @override
  String get runSetupAgain => 'Suorita asennus uudelleen';

  @override
  String get runSetupAgainSubtitle =>
      'Tilit, kisatavoite ja harjoitussuunnitelma';

  @override
  String get back => 'Takaisin';

  @override
  String get close => 'Sulje';

  @override
  String get dataExport => 'Tietojen vienti';

  @override
  String get dataExportSubtitle => 'CSV-vienti, varmuuskopio ja palautus';

  @override
  String get developer => 'Kehittäjä';

  @override
  String get developerSubtitle => 'Virheenkorjaustila, diagnostiikka';

  @override
  String get debug => 'Virheenkorjaus';

  @override
  String get debugMode => 'Virheenkorjaustila';

  @override
  String get debugModeSubtitle => 'Näyttää DEBUG-välilehden';

  @override
  String get support => 'Tuki';

  @override
  String get reportBug => 'Ilmoita virheestä';

  @override
  String get aiCoach => 'Tekoälyvalmentaja';

  @override
  String get enableAiCoach => 'Ota tekoälyvalmentaja käyttöön';

  @override
  String get onDeviceAiOrCloud => 'Laitteen tekoäly tai pilvipalvelu';

  @override
  String get provider => 'Palveluntarjoaja';

  @override
  String get model => 'Malli';

  @override
  String get chatAndAiBriefingsUse =>
      'Chat ja tekoälykatsaukset käyttävät tämän laitteen Apple Intelligencea. API-avainta ei tarvita. Jos malli ei ole käytettävissä, katsaukset näyttävät yhteenvedon ilman tekoälyä.';

  @override
  String get briefing => 'Katsaus';

  @override
  String get useAppleIntelligenceForBriefings =>
      'Käytä Apple Intelligencea katsauksiin';

  @override
  String get useOnDeviceAiFor =>
      'Käytä laitteen tekoälyä katsauksiin ja pidä valittu palveluntarjoaja chatissa.';

  @override
  String get healthDataSharing => 'Terveystietojen jakaminen';

  @override
  String get askOncePerChatSession => 'Kysy kerran chat-istuntoa kohden';

  @override
  String get otherwiseAskBeforeEveryCloud =>
      'Muuten kysy ennen jokaista pilviviestiä';

  @override
  String get reportABug => 'Ilmoita virheestä';

  @override
  String get weatherData => 'Säätiedot';

  @override
  String get openSourceLibraries => 'Avoimen lähdekoodin kirjastot';

  @override
  String get license => 'Lisenssi';

  @override
  String get licenses => 'Lisenssit';

  @override
  String get apiKey => 'API-avain';

  @override
  String get saveApiKey => 'Tallenna API-avain';

  @override
  String get feedbackBugReport => 'Palaute ja virheraportti';

  @override
  String get reportSentThankYou => 'Raportti lähetetty. Kiitos!';

  @override
  String get weReadEveryMessageIf =>
      'Luemme kaikki viestit. Jos jätit sähköpostiosoitteesi, saatat saada vastauksen.';

  @override
  String get done => 'Valmis';

  @override
  String get shareAnIdeaSuggestAn =>
      'Jaa idea, ehdota parannusta tai kerro, mitä tapahtui ja mitä odotit.';

  @override
  String get whatHappenedAndWhatDid => 'Mitä tapahtui ja mitä odotit?';

  @override
  String get pleaseLeaveOutPasswordsApi =>
      'Älä kirjoita salasanoja, API-avaimia tai henkilökohtaisia terveysarvoja.';

  @override
  String get includeDiagnostics => 'Sisällytä diagnostiikka';

  @override
  String get optionalLogsMayContainAccount =>
      'Valinnainen. Lokit voivat sisältää tili- tai terveystietoja. Tarkista ne alta ennen lähettämistä.';

  @override
  String get diagnosticsPreview => 'DIAGNOSTIIKAN ESIKATSELU';

  @override
  String get sendingSharesYourEmailSubject =>
      'Lähettäminen jakaa sähköpostiosoitteesi, aiheen, viestin ja valitun diagnostiikan Fjelian tuen kanssa osoitteessa www.fjelia.com.';

  @override
  String get copyReport => 'Kopioi raportti';

  @override
  String get shareReport => 'Jaa raportti';

  @override
  String get appleHealth => 'Apple Terveys';

  @override
  String get connectedServices => 'Yhdistetyt palvelut';

  @override
  String get hiloBloodPressureBle => 'Hilo verenpaine (BLE)';

  @override
  String get writeHeartDataToApple => 'Kirjoita sydäntiedot Apple Terveyteen';

  @override
  String get writeWeightDataToApple => 'Kirjoita painotiedot Apple Terveyteen';

  @override
  String get renphoScaleBle => 'Renpho-vaaka (BLE)';

  @override
  String get polarH10HrvStrapBle => 'Polar H10 (HRV-rintakehähihna, BLE)';

  @override
  String get dataSourcePriority => 'Tietolähteiden prioriteetti';

  @override
  String get whenMultipleSourcesProvideThe =>
      'Kun useampi lähde antaa saman mittarin, ylempi lähde voittaa. Järjestä vetämällä.';

  @override
  String get resetToDefault => 'Palauta oletukset';

  @override
  String get disconnect => 'Katkaise yhteys';

  @override
  String get healthPage => 'Terveys-sivu';

  @override
  String get loadPage => 'Kuormitus-sivu';

  @override
  String get healthMonitor => 'Terveysseuranta';

  @override
  String get hrZones => 'Sykealueet';

  @override
  String get t30MinTtAvailableSync =>
      '30 min TT saatavilla – synkronoi sykealueet';

  @override
  String lt2Lt2BpmAt(Object lt2, Object at) {
    return 'LT2 $lt2 bpm · $at';
  }

  @override
  String get syncLabel => 'SYNKRONOI';

  @override
  String get autoadjust => 'AUTOMAATTINEN SÄÄTÖ';

  @override
  String zoneI(Object i) {
    return 'Alue $i';
  }

  @override
  String get hrZones2 => 'SYKEALUEET';

  @override
  String ageRound(Object round) {
    return 'ikä $round';
  }

  @override
  String get basics => 'Perustiedot';

  @override
  String get updateWaistMonthlyUsedFor =>
      'ⓘ Päivitä vyötärönympärys kuukausittain – käytetään viskeraalirasvan arviointiin.';

  @override
  String get alcohol => 'Alkoholi';

  @override
  String get t1Drink033L =>
      '1 annos ≈ 0,33 l olutta / 0,2 l viiniä / 4 cl väkevää';

  @override
  String get clinicalLabsOptional => 'Laboratorioarvot (valinnainen)';

  @override
  String get glycemic => 'Verensokeri';

  @override
  String get optimalForLongevity48 =>
      'Optimaalinen pitkäikäisyydelle: 4,8–5,4 % · Esidiabetes: 5,7–6,4 %';

  @override
  String get lipids => 'Rasva-arvot';

  @override
  String get apobReplacesLdlWhenBoth =>
      'ApoB korvaa LDL:n, kun molemmat on syötetty.';

  @override
  String get inflammationKidney => 'Tulehdus ja munuaiset';

  @override
  String get changesAreSavedAutomatically =>
      'Muutokset tallennetaan automaattisesti';

  @override
  String get optionalTotalClimbingForThis =>
      'Valinnainen kokonaisnousu tälle kilpailulle.';

  @override
  String get moreAboutThisEvent => 'Lisätietoja tästä tapahtumasta';

  @override
  String distanceOfDistancekmKm(Object distanceKm) {
    return 'Matka $distanceKm km?';
  }

  @override
  String keepDistancekmKm(Object distanceKm) {
    return 'Säilytä $distanceKm km';
  }

  @override
  String useLikelyKm(Object likely) {
    return 'Käytä $likely km';
  }

  @override
  String get thisBackupContainsNoCalendar =>
      'Tämä varmuuskopio ei sisällä kalenteriaktiviteetteja.';

  @override
  String get activities => 'Aktiviteetit';

  @override
  String get exportActivitiesCsv => 'Vie aktiviteetit CSV-tiedostoon';

  @override
  String get backupRestore => 'Varmuuskopio ja palautus';

  @override
  String get backup => 'Varmuuskopio';

  @override
  String get restoreFromBackup => 'Palauta varmuuskopiosta';

  @override
  String get backupRestoredRestartTheApp =>
      'Varmuuskopio palautettu. Käynnistä sovellus uudelleen ladataksesi kaikki asetukset.';

  @override
  String get raceGoals => 'Kisatavoitteet';

  @override
  String get yourActivities => 'Aktiviteettisi';

  @override
  String get usedByAiCoachAnd =>
      'Tekoälyvalmentaja ja harjoitussuunnitelma käyttävät tätä. Suunnitelman lajit on merkitty ✦:lla.';

  @override
  String get calendarWeekStart => 'Kalenterin viikon alku';

  @override
  String get planDefaultView => 'Suunnitelman oletusnäkymä';

  @override
  String get weeklySchedule => 'Viikkoaikataulu';

  @override
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      trainingDaysPerWeek,
      locale: localeName,
      other: '$trainingDaysPerWeek harjoituspäivää',
      one: '$trainingDaysPerWeek harjoituspäivä',
    );
    return '$_temp0 · napauta vaihtaaksesi Harjoitus / Lepo / Voima';
  }

  @override
  String get updatePlanToThisSchedule =>
      'Päivitä suunnitelma tähän aikatauluun';

  @override
  String get updateStrengthSessions => 'Päivitä voimaharjoitukset';

  @override
  String get sessionsPerDay => 'Harjoituksia päivässä';

  @override
  String get canYouFitTwoWorkouts =>
      'Voitko tehdä kaksi harjoitusta samana päivänä?';

  @override
  String get strengthLoadUnit => 'Voimaharjoittelun kuorman yksikkö';

  @override
  String get weightsThemselvesAreSetIn =>
      'Painot asetetaan jokaisessa harjoituksessa ja ne muistetaan historiastasi.';

  @override
  String get hoursAvailableWeek => 'Käytettävissä olevat tunnit / viikko';

  @override
  String hoursperweekHWeek(Object hoursPerWeek) {
    return '$hoursPerWeek h / viikko';
  }

  @override
  String hoursperweekH(Object hoursPerWeek) {
    return '$hoursPerWeek h';
  }

  @override
  String get heatAcclimation => 'Lämpöön sopeutuminen';

  @override
  String get showHeatAcclimation => 'Näytä lämpöön sopeutuminen';

  @override
  String get weatherEvaluatedAgainstAConfigurable =>
      'Sää arvioidaan valittavalle sijainnille.';

  @override
  String get trainingPlan => 'Harjoitussuunnitelma';

  @override
  String get regenerateReplacesFutureSessionsAnd =>
      'Uudelleenluonti korvaa tulevat harjoitukset ja rakentaa suunnitelman tästä päivästä alkaen nykyisillä asetuksilla.';

  @override
  String valueUpcomingWorkoutsGenerated(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value tulevaa harjoitusta luotu',
      one: '$value tuleva harjoitus luotu',
    );
    return '$_temp0';
  }

  @override
  String get generationFailedCheckYourRace =>
      'Luonti epäonnistui. Tarkista kisatavoitteesi ja yritä uudelleen.';

  @override
  String get deleteAllWorkouts => 'Poista kaikki harjoitukset';

  @override
  String get changesAreSavedAutomatically2 =>
      '✓ Muutokset tallennetaan automaattisesti';

  @override
  String countUpcomingWorkoutsGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tulevaa harjoitusta luotu',
      one: '$count tuleva harjoitus luotu',
    );
    return '$_temp0';
  }

  @override
  String get importRaceGoalsFromGarmin => 'Tuo kisatavoitteet Garminista';

  @override
  String get addRaceGoal => 'Lisää kisatavoite';

  @override
  String priorityTouppercase(Object toUpperCase) {
    return 'Prioriteetti $toUpperCase';
  }

  @override
  String get goalsAreSharedWithAi =>
      'Tavoitteet jaetaan tekoälyvalmentajalle. Prioriteetti A, B tai C ratkaisee, miten suunnitelma painottaa kilpailujasi.';

  @override
  String get deletingWorkouts => 'Poistetaan harjoituksia';

  @override
  String get cityOrTown => 'Kaupunki tai kunta';

  @override
  String get eGHannoverOrPalma => 'esim. Hannover tai Palma';

  @override
  String get noCitiesFoundTryA =>
      'Kaupunkeja ei löytynyt. Kokeile lähistön kuntaa.';

  @override
  String get chooseTheLocationForThe =>
      'Valitse sijainti suunnitelman sääennusteelle, tutkalle ja lämpöön sopeutumiselle. Sää toimii myös, kun lämpöön sopeutuminen on pois päältä.';

  @override
  String get none => 'Ei mitään';

  @override
  String get disableLocalWeatherAndLocation =>
      'Poista paikallinen sää ja sijaintipyynnöt käytöstä';

  @override
  String get currentLocation => 'Nykyinen sijainti';

  @override
  String get followYourDeviceLocation => 'Seuraa laitteen sijaintia';

  @override
  String get fixedLocation => 'Kiinteä sijainti';

  @override
  String get chooseACityOrEnter => 'Valitse kaupunki tai syötä koordinaatit';

  @override
  String get chooseCity => 'Valitse kaupunki';

  @override
  String get coordinates => 'Koordinaatit';

  @override
  String get latitude => 'Leveysaste';

  @override
  String get longitude => 'Pituusaste';

  @override
  String get saveLocation => 'Tallenna sijainti';

  @override
  String get refreshCurrentLocation => 'Päivitä nykyinen sijainti';

  @override
  String get citySearchOpenMeteoGeonames =>
      'Kaupunkihaku: Open-Meteo / GeoNames';

  @override
  String get cityNamesOpenstreetmap => 'Kaupunkien nimet: © OpenStreetMap';

  @override
  String get energy => 'ENERGIA';

  @override
  String get currentEnergy => 'NYKYINEN ENERGIA';

  @override
  String get dailyTimeline => 'PÄIVÄN KULKU';

  @override
  String valueValue2(Object value, Object value2) {
    return '$value → $value2';
  }

  @override
  String get energy2 => 'Energia';

  @override
  String get noData => 'Ei tietoja';

  @override
  String get bloodPressureInsights => 'VERENPAINEEN ANALYYSI';

  @override
  String get sys => ' Sys';

  @override
  String get diaMmhg => ' Dia · mmHg';

  @override
  String get previousBloodPressurePeriod => 'Edellinen verenpainejakso';

  @override
  String get nextBloodPressurePeriod => 'Seuraava verenpainejakso';

  @override
  String get nightDipping => 'Yöllinen lasku';

  @override
  String get noMeasurementsInThisPeriod => 'Ei mittauksia tällä jaksolla';

  @override
  String get fullscreenBloodPressureChart => 'Verenpainekaavio koko näytölle';

  @override
  String get barsMinMaxLineDots =>
      'Palkit: pienin–suurin · viiva/pisteet: keskiarvo · napauta tai vedä tarkastellaksesi';

  @override
  String get noMeasurements => 'Ei mittauksia';

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
      other: '$length mittausta',
      one: '$length mittaus',
    );
    return '$_temp0 · keskiarvo / pienin–suurin';
  }

  @override
  String bloodPressureTouppercaseMmhg(Object toUpperCase) {
    return 'VERENPAINE · $toUpperCase · mmHg';
  }

  @override
  String get closeFullscreenBloodPressureChart =>
      'Sulje koko näytön verenpainekaavio';

  @override
  String get chooseScale => 'Valitse vaaka';

  @override
  String get noScalesFoundStepOn =>
      'Vaakoja ei löytynyt. Astu vaa\'alle ja yritä uudelleen.';

  @override
  String nameRssiDbm(Object name, Object rssi) {
    return '$name · $rssi dBm';
  }

  @override
  String get renphoSaved => 'RENPHO tallennettu:';

  @override
  String get renphoScaleBle2 => 'RENPHO-vaaka (BLE)';

  @override
  String get changeMeasurementType => 'Vaihda mittaustyyppiä';

  @override
  String get addMeasurement => 'Lisää mittaus';

  @override
  String get whatAreYouMeasuring => 'Mitä mittaat?';

  @override
  String get chooseAnotherMeasurement => 'Valitse toinen mittaus';

  @override
  String get saveMeasurement => 'Tallenna mittaus';

  @override
  String get skip => 'Ohita';

  @override
  String get connectHiloService => 'Yhdistä Hilo-palvelu';

  @override
  String get connectHilo => 'Yhdistä Hilo';

  @override
  String get connectCoros => 'Yhdistä Coros';

  @override
  String get europe => 'Eurooppa';

  @override
  String get unitedStates => 'Yhdysvallat';

  @override
  String get asia => 'Aasia';

  @override
  String get bluetoothBloodPressure => 'Bluetooth · verenpaine';

  @override
  String get cloudCuffData => 'Pilvi · mansettitiedot';

  @override
  String get apiSync => 'API-synkronointi';

  @override
  String get bluetoothHrvStrap => 'Bluetooth · HRV-rintahihna';

  @override
  String get accesslinkApi => 'AccessLink API';

  @override
  String get systemHealthData => 'Järjestelmän terveystiedot';

  @override
  String get cloudScaleHistory => 'Pilvi · vaa\'an historia';

  @override
  String get bluetoothWeightBody => 'Bluetooth · paino ja keho';

  @override
  String get connectYourDevices => 'Yhdistä laitteesi';

  @override
  String get continueLabel => 'Jatka';

  @override
  String get connectGarmin => 'Yhdistä Garmin';

  @override
  String get connectAppleHealth => 'Yhdistä Apple Terveys';

  @override
  String get dataSynced => 'TIEDOT SYNKRONOITU';

  @override
  String get pairHiloPod => 'Yhdistä Hilo Pod';

  @override
  String get chooseStrap => 'Valitse hihna';

  @override
  String namePaired(Object name) {
    return '$name yhdistetty.';
  }

  @override
  String get pairPolarH10 => 'Yhdistä Polar H10';

  @override
  String get forget => 'Unohda';

  @override
  String get sendWorkoutToPolar => 'Lähetä harjoitus Polariin';

  @override
  String get connectPolar => 'Yhdistä Polar';

  @override
  String get signInWithPolarFlow => 'Kirjaudu Polar Flow\'lla';

  @override
  String get syncsSleepStagesHrvResting =>
      'Synkronoi unen vaiheet · HRV · leposyke · harjoitukset · askeleet';

  @override
  String savedForV(Object v) {
    return 'Tallennettu käyttäjälle $v';
  }

  @override
  String get remove => 'Poista';

  @override
  String get polarEMail => 'Polar-sähköposti';

  @override
  String get polarPassword => 'Polar-salasana';

  @override
  String get pairRenphoScale => 'Yhdistä RENPHO-vaaka';

  @override
  String get connectRenpho => 'Yhdistä Renpho';

  @override
  String get connectSuunto => 'Yhdistä Suunto';

  @override
  String smsSentToTrim(Object trim) {
    return 'Tekstiviesti lähetetty numeroon $trim';
  }

  @override
  String get resendSms => 'Lähetä tekstiviesti uudelleen';

  @override
  String get retryLoadingPreferences => 'Yritä ladata asetukset uudelleen';

  @override
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed) {
    return 'VIIKOITTAINEN HARJOITTELUAIKA · $toStringAsFixed h';
  }

  @override
  String get tapADayToCycle =>
      'Napauta päivää vaihtaaksesi Harjoitus / Lepo / Voima.';

  @override
  String get doubleDayOk => 'Tuplapäivä ok';

  @override
  String get birthYearOptional => 'Syntymävuosi (valinnainen)';

  @override
  String get addAnother => 'Lisää toinen';

  @override
  String get knowYourBodyTrainSmarter =>
      'Tunne kehosi.\nHarjoittele viisaammin.';

  @override
  String get allYourHealthDevicesOne =>
      'Kaikki terveyslaitteesi. Yksi älykäs näkymä.';

  @override
  String get areYouReadyToTrain => 'Oletko valmis harjoittelemaan tänään?';

  @override
  String get hrvRecoveryScoreRestingHr => 'HRV · Palautumispisteet · Leposyke';

  @override
  String get didYouActuallyRecoverLast => 'Palautuitko todella viime yönä?';

  @override
  String get sleepStagesDeepSleepSpo => 'Unen vaiheet · Syvä uni · SpO₂';

  @override
  String get isYourBloodPressureUnder => 'Onko verenpaineesi hallinnassa?';

  @override
  String get continuousBpNightDippingTrends =>
      'Jatkuva verenpaine · Yöllinen lasku · Trendit';

  @override
  String get howHardDidYouPush => 'Kuinka kovaa treenasit tällä viikolla?';

  @override
  String get trainingLoadTrimpStrainScore =>
      'Harjoituskuormitus · TRIMP · Rasituspisteet';

  @override
  String get isYourBodyCompositionImproving => 'Paraneeko kehonkoostumuksesi?';

  @override
  String get weightBodyFatMuscleMass => 'Paino · Kehon rasva · Lihasmassa';

  @override
  String get getStarted => 'Aloita';

  @override
  String get yourDataStaysOnYour => 'Sinun tietosi. Sinä päätät, mitä jaat.';

  @override
  String get bodyScale => 'Henkilövaaka';

  @override
  String get bodyComposition => 'Kehonkoostumus';

  @override
  String get sleep => 'UNI';

  @override
  String get sleepPerformance => 'UNEN SUORITUS';

  @override
  String get sleepHistory => 'Univerlauf';

  @override
  String labelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String lessLabel(Object label) {
    return 'Vähemmän $label';
  }

  @override
  String moreLabel(Object label) {
    return 'Enemmän $label';
  }

  @override
  String get gymMode => 'Salitila';

  @override
  String get finishWorkout => 'Lopeta harjoitus';

  @override
  String get workoutActions => 'Harjoituksen toiminnot';

  @override
  String get discardWorkout => 'Hylkää harjoitus';

  @override
  String get allSetsRecorded => 'Kaikki sarjat tallennettu';

  @override
  String get reviewSets => 'Tarkista sarjat';

  @override
  String get rest => 'LEPO';

  @override
  String plannedResttarget(Object restTarget) {
    return 'Suunniteltu $restTarget';
  }

  @override
  String get startSet => 'Aloita sarja';

  @override
  String get seconds => 'Sekuntia';

  @override
  String get previousSet => 'Edellinen sarja';

  @override
  String get allSets => 'Kaikki sarjat';

  @override
  String get nextSet => 'Seuraava sarja';

  @override
  String get everySetIsSavedAs =>
      'Jokainen sarja tallennetaan heti. Voit sulkea tämän näkymän milloin tahansa ja jatkaa suunnitellusta harjoituksesta.';

  @override
  String get cancel => 'Peruuta';

  @override
  String get apply => 'Käytä';

  @override
  String get effortScale => 'Rasitusasteikko';

  @override
  String get setType => 'Sarjan tyyppi';

  @override
  String get reps => 'Toistot';

  @override
  String get range => 'Vaihteluväli';

  @override
  String get time => 'Aika';

  @override
  String get t45Or100 => '45 tai 1:00';

  @override
  String get blankWhenNotSet => 'Tyhjä, jos ei asetettu';

  @override
  String get redBand => 'Punainen kuminauha';

  @override
  String get t90Or130 => '90 tai 1:30';

  @override
  String get blankWhenUnknown => 'Tyhjä, jos tuntematon';

  @override
  String get usePlannedLoad => 'Käytä suunniteltua kuormaa';

  @override
  String get blankWhenNotMeasured => 'Tyhjä, jos ei mitattu';

  @override
  String get exercise => 'Liike';

  @override
  String get changingTheLoadConventionStarts =>
      'Kuormakäytännön muuttaminen aloittaa tälle liikkeelle erillisen historian.';

  @override
  String get barbellMachine => 'Tanko, laite…';

  @override
  String get load => 'Kuorma';

  @override
  String get loadRefersTo => 'Kuorma tarkoittaa';

  @override
  String get t2ForAPair => '2 parille';

  @override
  String get repetitions => 'Toistot';

  @override
  String get availablePlatesOrDumbbells =>
      'Käytettävissä olevat levyt tai käsipainot';

  @override
  String get rememberForThisEquipment => 'Muista tälle välineelle';

  @override
  String get findOrNameAnExercise => 'Etsi tai nimeä liike';

  @override
  String createTrim(Object trim) {
    return 'Luo ”$trim”';
  }

  @override
  String get customExercise => 'Oma liike';

  @override
  String get smallestLoadStep => 'Pienin kuormanlisäys';

  @override
  String whatRemoved(Object what) {
    return '$what poistettu';
  }

  @override
  String get undo => 'Kumoa';

  @override
  String get retry => 'Yritä uudelleen';

  @override
  String get performance => 'Suoritus';

  @override
  String get addExercise => 'Lisää liike';

  @override
  String get finishLog => 'Viimeistele loki';

  @override
  String get keepAsDraft => 'Säilytä luonnoksena';

  @override
  String actionsForName(Object name) {
    return 'Toiminnot: $name';
  }

  @override
  String get editExercise => 'Muokkaa liikettä';

  @override
  String get moveUp => 'Siirrä ylös';

  @override
  String get moveDown => 'Siirrä alas';

  @override
  String get addSet => 'Lisää sarja';

  @override
  String get removeLastSet => 'Poista viimeinen sarja';

  @override
  String get saveAsTemplate => 'Tallenna mallina';

  @override
  String savedTitleAsATemplate(Object title) {
    return '”$title” tallennettu mallina. Tämä harjoitus pysyy ennallaan, kunnes tallennat sen.';
  }

  @override
  String nameSetN(Object name, Object n) {
    return '$name · Sarja $n';
  }

  @override
  String nameAllWorkingSets(Object name) {
    return '$name · Kaikki työsarjat';
  }

  @override
  String labelRest(Object label) {
    return '$label lepo';
  }

  @override
  String get secondsOrMSs => 'Sekunteja tai m:ss';

  @override
  String get applyToAllSets => 'Käytä kaikkiin sarjoihin';

  @override
  String get duplicate => 'Kopioi';

  @override
  String get supersetWithNext => 'Superseriaksi seuraavan kanssa';

  @override
  String get circuitWithNext => 'Kierroksi seuraavan kanssa';

  @override
  String actionsForSetN(Object n) {
    return 'Toiminnot: sarja $n';
  }

  @override
  String get editSet => 'Muokkaa sarjaa';

  @override
  String get duplicateSet => 'Kopioi sarja';

  @override
  String get removeSet => 'Poista sarja';

  @override
  String labelActions(Object label) {
    return '$label: toiminnot';
  }

  @override
  String get editRests => 'Muokkaa lepoja';

  @override
  String get ungroup => 'Pura ryhmä';

  @override
  String get editExercises => 'Muokkaa liikkeitä';

  @override
  String get unsavedChanges => 'Tallentamattomat muutokset';

  @override
  String couldNotSaveError(Object error) {
    return 'Tallennus epäonnistui: $error';
  }

  @override
  String get history => 'Historia';

  @override
  String get exercises => 'Liikkeet';

  @override
  String get noExercisesArePlannedFor =>
      'Tälle harjoitukselle ei ole vielä suunniteltu liikkeitä. Yllä olevat muistiinpanot kuvaavat sen.';

  @override
  String get addExercises => 'Lisää liikkeitä';

  @override
  String get fromTheBuiltInTemplate =>
      'Sisäänrakennetusta mallista. Kuormat asetat itse; historia näkyy, kun olet kirjannut harjoituksen.';

  @override
  String get shareExerciseList => 'Jaa liikelista';

  @override
  String get noSavedStrengthTemplatesYet =>
      'Ei vielä tallennettuja voimamalleja. Tallenna ensin yksi suunnitellusta harjoituksesta.';

  @override
  String get compareWith => 'Vertaa kohteeseen';

  @override
  String estimated1rmUnit(Object unit) {
    return 'Arvioitu 1RM $unit';
  }

  @override
  String get plannedNotRecorded => 'Suunniteltu, ei kirjattu';

  @override
  String get notes => 'Muistiinpanot';

  @override
  String get editPerformance => 'Muokkaa suoritusta';

  @override
  String get compareWithASavedWorkout => 'Vertaa tallennettuun harjoitukseen';

  @override
  String get sessions => 'Harjoitukset';

  @override
  String get radarUnavailableRetry =>
      'Tutka ei käytettävissä · Yritä uudelleen';

  @override
  String get radar => 'Tutka';

  @override
  String get weatherDataByRainviewer => 'Säätiedot: RainViewer';

  @override
  String get openstreetmapContributors => '© OpenStreetMapin tekijät';

  @override
  String get weather => 'Sää';

  @override
  String get weatherUnavailableRetry =>
      'Sää ei käytettävissä · Yritä uudelleen';

  @override
  String get chooseAFixedLocationIn =>
      'Valitse kiinteä sijainti Sää ja sijainti -asetuksista tai salli sijainnin käyttö paikallista säätä varten.';

  @override
  String get locationSettings => 'Sijaintiasetukset';

  @override
  String get retryLocation => 'Yritä sijaintia uudelleen';

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
    return 'Märkälämpötila $toStringAsFixed°C';
  }

  @override
  String get previousForecastDay => 'Edellinen ennustepäivä';

  @override
  String get nextForecastDay => 'Seuraava ennustepäivä';

  @override
  String daysDayForecast(Object days) {
    return '$days päivän ennuste';
  }

  @override
  String thisProviderCurrentlySuppliesDays(Object days, Object days2) {
    return 'Tämä palveluntarjoaja tarjoaa tällä hetkellä $days/$days2 ennustepäivää.';
  }

  @override
  String get now => 'Nyt';

  @override
  String get sunriseSunset => 'Auringonnousu / -lasku';

  @override
  String keyKey2(Object key, Object key2) {
    return '☀ $key   ☾ $key2';
  }

  @override
  String get use => 'Käytä';

  @override
  String get exerciseDetailsWereNotProvided =>
      'Tämä aktiviteettilähde ei antanut liikkeiden tietoja.';

  @override
  String get logFromPlan => 'Kirjaa suunnitelmasta';

  @override
  String get addExerciseDetails => 'Lisää liikkeiden tiedot';

  @override
  String get loadSuggestion => 'Kuormaehdotus';

  @override
  String get applyToThisWorkout => 'Käytä tähän harjoitukseen';

  @override
  String get keepCurrentLoad => 'Säilytä nykyinen kuorma';

  @override
  String get setLoadStep => 'Aseta kuormanlisäys';

  @override
  String get viewSupportingSets => 'Näytä tukevat sarjat';

  @override
  String get supportingSets => 'Tukevat sarjat';

  @override
  String get noRecordedSessionsYet => 'Ei vielä kirjattuja harjoituksia.';

  @override
  String nameDemonstrationCue(Object name, Object cue) {
    return '$name: esittely. $cue';
  }

  @override
  String get noScalesFoundStepOn2 =>
      'Vaakoja ei löytynyt. Astu vaa\'alle ja yritä uudelleen.';

  @override
  String get scalePaired => 'Vaaka yhdistetty';

  @override
  String get ok => 'OK';

  @override
  String get pairedReadyToMeasure => '✓ Yhdistetty – valmis mittaamaan';

  @override
  String get chooseHiloCuff => 'Valitse Hilo-mansetti';

  @override
  String get noCuffFoundWakeYour =>
      'Mansettia ei löytynyt. Herätä mansetti ja hae uudelleen.';

  @override
  String get hiloCuffAktiiaC => 'Hilo-mansetti (AKTIIA C…)';

  @override
  String get onDemandBloodPressureVia => 'Verenpaine tarvittaessa BLE:n kautta';

  @override
  String get selectHiloPodWristband => 'Valitse Hilo Pod (rannekoru)';

  @override
  String get rescan => 'Hae uudelleen';

  @override
  String get noDevicesFoundTapTo =>
      'Laitteita ei löytynyt. Napauta ↻ hakeaksesi uudelleen.';

  @override
  String get polarH10SpotHrv => 'Polar H10 · Hetki-HRV';

  @override
  String get aSeparateHrvReadingBefore =>
      'Erillinen HRV-mittaus ennen harjoitusta tai sen jälkeen. Nämä mittaukset eivät korvaa Garminin yöllistä HRV:tä eivätkä muuta valmiuspisteitäsi.';

  @override
  String get wearTheStrapWithMoist =>
      'Pidä hihna kosteilla elektrodeilla. Pysy paikallasi ja hengitä normaalisti. Käytä vertailuun samaa asentoa ja tallennuksen pituutta. Merkitse harjoituksen jälkeen, kuinka kauan lepäsit ensin.';

  @override
  String get measurement => 'Mittaus';

  @override
  String get posture => 'Asento';

  @override
  String get recordingLengthPlus1Min =>
      'Tallennuksen pituus · plus 1 min tasaantuminen';

  @override
  String get t2Minutes => '2 minuuttia';

  @override
  String get t5Minutes => '5 minuuttia';

  @override
  String get minutesSinceTrainingEndedOptional =>
      'Minuutteja harjoituksen päättymisestä (valinnainen)';

  @override
  String get sessionOrNotesOptional =>
      'Harjoitus tai muistiinpanot (valinnainen)';

  @override
  String connectName(Object name) {
    return 'Yhdistä $name';
  }

  @override
  String get findPolarH10 => 'Etsi Polar H10';

  @override
  String signalRssiDbm(Object rssi) {
    return 'Signaali $rssi dBm';
  }

  @override
  String connectedName(Object name) {
    return 'Yhdistetty: $name';
  }

  @override
  String get waitingForHeartRateAnd =>
      'Odotetaan sykettä ja RR-välejä. Tarkista hihnan kontakti.';

  @override
  String get startMeasurement => 'Aloita mittaus';

  @override
  String get cancelMeasurement => 'Peruuta mittaus';

  @override
  String get spotHrvRmssd => 'Hetki-HRV · RMSSD';

  @override
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  ) {
    return '$accepted/$length käyttökelpoista väliä · $toStringAsFixed % kattavuus';
  }

  @override
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs) {
    return 'lnRMSSD: $lnRmssd · Raaka RMSSD: $rawRmssdMs ms';
  }

  @override
  String get signalQualityIsTooLow =>
      'Signaalin laatu on liian heikko tallennettavaksi. Toista mittaus hyvällä hihnakontaktilla. Vaaditaan vähintään 95 % käyttökelpoisia välejä ja 90 % kattavuus.';

  @override
  String get savedToSpotHrvHistory => 'Tallennettu Hetki-HRV-historiaan.';

  @override
  String get newMeasurement => 'Uusi mittaus';

  @override
  String get signalScreeningExcludesPoorContact =>
      'Signaalin seulonta poissulkee huonon kontaktin, 250–2500 ms:n ulkopuoliset RR-arvot ja yli 25 % paikallisesta mediaanista poikkeavat välit. Aukkoja ei täytetä. Tämä ei ole lääketieteellinen testi eikä itsenäinen valmiuspistemäärä.';

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
      'Vain samassa tilanteessa, asennossa ja kestolla tehdyt mittaukset näytetään yhdessä.';

  @override
  String get noMatchingMeasurementsYet => 'Ei vielä vastaavia mittauksia.';

  @override
  String tostringasfixedMsRmssdTostringasfixed2Bpm(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return '$toStringAsFixed ms RMSSD · $toStringAsFixed2 bpm';
  }

  @override
  String get exportRrIntervalsCsv => 'Vie RR-välit (CSV)';

  @override
  String get deleteMeasurement => 'Poista mittaus';

  @override
  String get remindMeToMeasureHrv =>
      'Muistuta minua mittaamaan HRV harjoituksen jälkeen';

  @override
  String get appleHealthIsNoLonger => 'Apple Terveys ei ole enää käytettävissä';

  @override
  String get later => 'Myöhemmin';

  @override
  String get reconnect => 'Yhdistä uudelleen';

  @override
  String get gripStrength => 'Puristusvoima';

  @override
  String get leftKg => 'Vasen (kg)';

  @override
  String get rightKg => 'Oikea (kg)';

  @override
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg) {
    return 'V $leftKg · O $rightKg kg';
  }

  @override
  String get notificationsAreOffYouCan =>
      'Ilmoitukset ovat pois päältä. Voit silti mitata harjoituksestasi.';

  @override
  String get noRemindersFrom2200 => 'Ei muistutuksia klo 22:00–07:00';

  @override
  String get aReminderThatWouldFall =>
      'Tähän aikaan osuva muistutus ohitetaan, ei siirretä aamuun.';

  @override
  String get remindersArriveQuietlyInThe =>
      'Muistutukset saapuvat hiljaa ilmoituslistaan.';

  @override
  String get noForecastForThisDay => 'Ei ennustetta tälle päivälle';

  @override
  String get fullscreen => 'Koko näyttö';

  @override
  String source(Object source) {
    return '● $source';
  }

  @override
  String get temperatureC => '● Lämpötila °C';

  @override
  String get rainMm => '▥ Sade mm';

  @override
  String get uvIndex => '— UV-indeksi';

  @override
  String get closeFullscreenWeatherChart => 'Sulje koko näytön säädiagrammi';

  @override
  String get sleepStages => 'UNEN VAIHEET';

  @override
  String get noStageTimelineForThis => 'Tältä yöltä ei ole vaihekaaviota.';

  @override
  String round3(Object round) {
    return '$round%';
  }

  @override
  String get examplesOnlyCheckAndEnter =>
      'Vain esimerkkejä: tarkista ja syötä tuotteen pakkauksen arvot annosta kohden. Jätä tuntemattomat ravintoaineet tyhjiksi; syötä 0 vain, jos arvo tiedetään.';

  @override
  String get nutritionStrategy => 'Ravitsemusstrategia';

  @override
  String get noPreWorkoutNutritionStrategy =>
      'Harjoitusta edeltävää ravitsemusstrategiaa ei ole tallennettu.';

  @override
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium) {
    return '$carbs g hiilihydraatteja/h · $fluid ml/h · $sodium mg natriumia/h';
  }

  @override
  String get forecastUpdatedReviewOrRecalculate =>
      'Ennuste päivittyi – tarkista tai laske tallennettu strategia uudelleen.';

  @override
  String strategySavedSavedat(Object savedAt) {
    return 'Strategia tallennettu $savedAt';
  }

  @override
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  ) {
    return 'Yhteensä aikana: $totalCarbs g hiilihydraatteja · $totalFluid ml · $totalSodium mg natriumia';
  }

  @override
  String every20MinAboutCarbs(Object carbs, Object fluid) {
    return 'Joka 20. minuutti: noin $carbs g hiilihydraatteja ja $fluid ml.';
  }

  @override
  String get packQuantitiesIncludeFullContainers =>
      'Pakkausmäärät sisältävät kokonaisia pakkauksia; kaikkea ei tarvitse nauttia.';

  @override
  String get workoutChangedReviewOrRecalculate =>
      'Harjoitus muuttui – tarkista tai laske tallennettu strategia uudelleen.';

  @override
  String get conditionsAndFeedingPlan => 'Olosuhteet ja ravitsemussuunnitelma';

  @override
  String get editStrategy => 'Muokkaa strategiaa';

  @override
  String get recalculate => 'Laske uudelleen';

  @override
  String get actualNutrition => 'Todellinen ravinto';

  @override
  String get someProductValuesAreUnknown =>
      'Joidenkin tuotteiden arvot ovat tuntemattomia; summat ovat vajaat.';

  @override
  String get logFoodAndFluids => 'Kirjaa ruoka ja nesteet';

  @override
  String get recordWhatYouActuallyHad =>
      'Kirjaa, mitä todella nautit. Suunniteltua saantia ei kopioida tähän lokiin.';

  @override
  String get elapsedMinutesIncludingStopsOptional =>
      'Kulunut aika minuutteina taukoineen (valinnainen)';

  @override
  String recordedDurationActivityMin(Object activity) {
    return 'Tallennettu kesto: $activity min';
  }

  @override
  String get compareWithSavedStrategy => 'Vertaa tallennettuun strategiaan';

  @override
  String get useMatchedSessionIfAvailable =>
      'Käytä vastaavaa harjoitusta, jos saatavilla';

  @override
  String get noPlanComparison => 'Ei vertailua suunnitelmaan';

  @override
  String titleDate(Object title, Object date) {
    return '$title · $date';
  }

  @override
  String get linkedStrategyUnavailable =>
      'Linkitetty strategia ei ole käytettävissä';

  @override
  String quantityName(Object quantity, Object name) {
    return '$quantity × $name';
  }

  @override
  String get removeIntake => 'Poista nautittu';

  @override
  String get addFoodOrDrink => 'Lisää ruoka tai juoma';

  @override
  String get iHadNoIntake => 'En nauttinut mitään';

  @override
  String get giGutComfort => 'Vatsan mukavuus';

  @override
  String get whatWorkedSymptomsAccessProblems =>
      'Mikä toimi / oireet / saatavuusongelmat';

  @override
  String get saveDraft => 'Tallenna luonnos';

  @override
  String get skipLoggingThisActivity => 'Ohita tämän aktiviteetin kirjaus';

  @override
  String get nutritionAndFluids => 'Ravinto ja nesteet';

  @override
  String get productsToleranceAndMeasuredSweat =>
      'Tuotteet, siedettävyys ja mitatut hikihäviöt';

  @override
  String get postWorkoutIntakeReminder =>
      'Muistutus nauttimisesta harjoituksen jälkeen';

  @override
  String get onceAfterARecentEndurance =>
      'Kerran äskettäisen kestävyysharjoituksen jälkeen; hiljaiset tunnit 22:00–08:00.';

  @override
  String get addHiloBpReport => 'Lisää Hilo-verenpaineraportti';

  @override
  String get readingPdfReportsIsOnly =>
      'PDF-raporttien lukeminen on mahdollista vain iOS:llä ja macOS:llä.';

  @override
  String get chooseAnotherReport => 'Valitse toinen raportti';

  @override
  String get biologicalAge => 'Biologinen ikä';

  @override
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class) {
    return 'VO₂max $vo2max ml/kg/min · $vo2Class';
  }

  @override
  String get factorContributions => 'Tekijöiden vaikutus';

  @override
  String estimatedRangeRoundRound2Years(Object round, Object round2) {
    return 'Arvioitu vaihteluväli $round–$round2 vuotta. Mallin arvio, ei lääketieteellinen diagnoosi.';
  }

  @override
  String get noEnergyMeasurementsForThis =>
      'Ei energiamittauksia tälle päivälle';

  @override
  String get scanningStepOnTheScale =>
      'Haetaan… astu vaa\'alle, kun olet valmis.';

  @override
  String waistWaistCmUpdateMonthly(Object waist) {
    return 'Vyötärö: $waist cm – päivitä kuukausittain Profiilissa';
  }

  @override
  String get measuring => 'Mitataan…';

  @override
  String get tryAgain => 'Yritä uudelleen';

  @override
  String get systolic => 'Systolinen';

  @override
  String get diastolic => 'Diastolinen';

  @override
  String get heartRate => 'Syke';

  @override
  String get weight => 'Paino';

  @override
  String get bodyFat => 'Kehon rasva';

  @override
  String get duration => 'Kesto';

  @override
  String get deep => 'Syvä';

  @override
  String get spo => 'SpO₂';

  @override
  String get activityName => 'Aktiviteetin nimi';

  @override
  String get sport => 'Laji';

  @override
  String get distance => 'Matka';

  @override
  String get saved => 'Tallennettu';

  @override
  String get connectionFailedCheckYourInternet =>
      'Yhteys epäonnistui. Tarkista internetyhteytesi.';

  @override
  String get email => 'Sähköposti';

  @override
  String get password => 'Salasana';

  @override
  String get passwordTooShort => 'Salasana on liian lyhyt';

  @override
  String get loginFailedCheckYourEmail =>
      'Kirjautuminen epäonnistui. Tarkista sähköposti ja salasana.';

  @override
  String get connectionFailedCheckYourCredentials =>
      'Yhteys epäonnistui. Tarkista tunnuksesi ja internetyhteytesi.';

  @override
  String get region => 'Alue';

  @override
  String get hiloPod => 'Hilo Pod';

  @override
  String get hiloAccount => 'Hilo-tili';

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
  String get renphoAccount => 'Renpho-tili';

  @override
  String get garminConnectEmail => 'Garmin Connect -sähköposti';

  @override
  String get verifyMfaCode => 'Vahvista MFA-koodi';

  @override
  String get verificationCode => 'Vahvistuskoodi';

  @override
  String errorE(Object e) {
    return 'Virhe: $e';
  }

  @override
  String get noHiloPodFoundMake =>
      'Hilo Podia ei löytynyt. Varmista, että se on ladattu ja lähellä.';

  @override
  String scanFailedE(Object e) {
    return 'Haku epäonnistui: $e';
  }

  @override
  String get hiloPod2 => 'Hilo Pod';

  @override
  String get scanForPod => 'Etsi pod';

  @override
  String get scanForPolarH10 => 'Etsi Polar H10';

  @override
  String get couldNotReachPolarCheck =>
      'Polariin ei saatu yhteyttä. Tarkista yhteytesi.';

  @override
  String get signInAndSendWorkout => 'Kirjaudu ja lähetä harjoitus';

  @override
  String get scanForScale => 'Etsi vaaka';

  @override
  String get passwordRequired => 'Salasana vaaditaan';

  @override
  String get enterYourPhoneNumberWith =>
      'Syötä puhelinnumerosi (maatunnuksineen, esim. +358…) ja Suunto-sähköpostisi.';

  @override
  String get enterThePinFromThe => 'Syötä tekstiviestin PIN-koodi.';

  @override
  String get incorrectPinPleaseTryAgain => 'Väärä PIN-koodi. Yritä uudelleen.';

  @override
  String get phoneNumber => 'Puhelinnumero';

  @override
  String get suuntoAccountEmail => 'Suunto-tilin sähköposti';

  @override
  String get enterPinFromSms => 'Syötä PIN tekstiviestistä';

  @override
  String get verifyConnect => 'Vahvista ja yhdistä';

  @override
  String get sendSmsCode => 'Lähetä tekstiviestikoodi';

  @override
  String couldNotSavePreferencesE(Object e) {
    return 'Asetusten tallennus epäonnistui: $e';
  }

  @override
  String get mon => 'Ma';

  @override
  String get tue => 'Ti';

  @override
  String get wed => 'Ke';

  @override
  String get thu => 'To';

  @override
  String get fri => 'Pe';

  @override
  String get sat => 'La';

  @override
  String get sun => 'Su';

  @override
  String get male => 'Mies';

  @override
  String get female => 'Nainen';

  @override
  String get other => 'Muu';

  @override
  String get running => 'Juoksu';

  @override
  String get trailRunning => 'Polkujuoksu';

  @override
  String get cycling => 'Pyöräily';

  @override
  String get swimming => 'Uinti';

  @override
  String get triathlon => 'Triathlon';

  @override
  String get hiking => 'Vaellus';

  @override
  String get rowing => 'Soutu';

  @override
  String get buildMyPlan => 'Luo suunnitelmani';

  @override
  String get keepAConsistentBedtimeAnd =>
      'Pidä säännölliset nukkumaanmeno- ja heräämisajat tukeaksesi unirytmiäsi.';

  @override
  String get thisWorkoutHasNoSets => 'Tässä harjoituksessa ei ole sarjoja.';

  @override
  String loadName(Object name) {
    return 'Kuorma ($name)';
  }

  @override
  String get setLabel => 'Sarja';

  @override
  String get lowestReps => 'Vähiten toistoja';

  @override
  String get highestReps => 'Eniten toistoja';

  @override
  String get repsPerSide => 'Toistoja per puoli';

  @override
  String get fromReps => 'Alkaen (toistot)';

  @override
  String get toReps => 'Asti (toistot)';

  @override
  String get addedLoad => 'Lisäkuorma';

  @override
  String get assistance => 'Avustus';

  @override
  String get tempoOptional => 'Tempo (valinnainen)';

  @override
  String get notesOptional => 'Muistiinpanot (valinnainen)';

  @override
  String get enterTheRepetitionsDone => 'Syötä tehdyt toistot.';

  @override
  String plannedUnit(Object unit) {
    return 'Suunniteltu $unit';
  }

  @override
  String get repsDone => 'Tehdyt toistot';

  @override
  String get resistance => 'Vastus';

  @override
  String get implementsLabel => 'Välineet';

  @override
  String get name => 'Nimi';

  @override
  String get instructionsOptional => 'Ohjeet (valinnainen)';

  @override
  String get remember => 'Muista';

  @override
  String get notSavedYet => 'Ei vielä tallennettu';

  @override
  String get saving => 'Tallennetaan…';

  @override
  String get couldNotSave => 'Tallennus epäonnistui';

  @override
  String get plannedValuesAreHintsNot =>
      'Suunnitellut arvot ovat vihjeitä, eivät tuloksia. Napauta sarjaa kirjataksesi sen.';

  @override
  String get completedAsPlanned => 'Suoritettu suunnitellusti';

  @override
  String get save => 'Tallenna';

  @override
  String get nameTheTemplate => 'Anna mallille nimi.';

  @override
  String setN(Object n) {
    return 'Sarja $n';
  }

  @override
  String get changesApplyToThisWorkout =>
      'Muutokset koskevat vain tätä harjoitusta. Suoritetut ja muut harjoitukset pysyvät ennallaan.';

  @override
  String get saveForThisWorkout => 'Tallenna tälle harjoitukselle';

  @override
  String knownForKnownOfOf(Object known, Object of) {
    return 'Tiedossa $known/$of kuormitetusta sarjasta';
  }

  @override
  String get sessionEstimate => 'Harjoituksen arvio';

  @override
  String get calculatedRange => 'Laskettu vaihteluväli';

  @override
  String get timedWork => 'Aikaan perustuva työ';

  @override
  String get strengthTraining => 'Voimaharjoittelu';

  @override
  String get theExercisesCouldNotBe => 'Liikkeitä ei voitu ladata.';

  @override
  String get resumeWorkout => 'Jatka harjoitusta';

  @override
  String get strengthWorkout => 'Voimaharjoitus';

  @override
  String get untitledTemplate => 'Nimeämätön malli';

  @override
  String get theRecordedExercisesCouldNot =>
      'Kirjattuja liikkeitä ei voitu ladata.';

  @override
  String get exercisesPerformed => 'Tehdyt liikkeet';

  @override
  String get comparedWithThePlanAs =>
      'Verrattu suunnitelmaan sellaisena kuin se oli kirjauksen alkaessa.';

  @override
  String topWorkingLoadName(Object name) {
    return 'Suurin työkuorma ($name)';
  }

  @override
  String get estimated1rmMiddleOfRange =>
      'Arvioitu 1RM, vaihteluvälin keskikohta';

  @override
  String get noLoggedSessionsYet => 'Ei vielä kirjattuja harjoituksia.';

  @override
  String get noRadarFramesAvailable => 'Tutkakuvia ei ole saatavilla';

  @override
  String get playRadar => 'Toista tutka';

  @override
  String get pauseRadar => 'Keskeytä tutka';

  @override
  String get high => 'Korkea';

  @override
  String get clear => 'Selkeää';

  @override
  String get bodyweight => 'Kehonpaino';

  @override
  String get resistance2 => 'Vastus —';

  @override
  String assistUnit(Object unit) {
    return 'Avustus $unit';
  }

  @override
  String get reps2 => 'Toistot —';

  @override
  String get notRecorded => 'Ei kirjattu';

  @override
  String get skipped => 'Ohitettu';

  @override
  String get health => 'Terveys';

  @override
  String get manual => 'Manuaalinen';

  @override
  String expandName(Object name) {
    return 'Laajenna $name';
  }

  @override
  String get open => 'Avaa';

  @override
  String get noScalePaired => 'Ei yhdistettyä vaakaa';

  @override
  String get paired => 'Yhdistetty';

  @override
  String get change => 'Vaihda';

  @override
  String get noCuffPaired => 'Ei yhdistettyä mansettia';

  @override
  String get noPolarH10FoundWear =>
      'Polar H10:tä ei löytynyt. Pue hihna, kostuta elektrodit ja tarkista, ettei toinen sovellus käytä molempia Bluetooth-yhteyksiä.';

  @override
  String get enterMinutesSinceTrainingEnded =>
      'Syötä harjoituksen päättymisestä kuluneet minuutit, 0–1440.';

  @override
  String get timingFollowsYourWorkout => 'Ajoitus seuraa harjoitustasi.';

  @override
  String get recordingStayStill => 'Tallennus · pysy paikallasi';

  @override
  String get meanHrBpm => 'Keskisyke · bpm';

  @override
  String get pairAPolarH10First => 'Yhdistä ensin Polar H10.';

  @override
  String get around30MinutesAfterTraining =>
      'Noin 30 minuuttia harjoituksen jälkeen, kun harjoitus on ajoissa saatavilla.';

  @override
  String get reminderDiagnostics => 'Muistutusten diagnostiikka';

  @override
  String get forecast => 'Ennuste';

  @override
  String forecastRange(int count) {
    return 'Varjostettu: $count ennusteen vaihteluväli';
  }

  @override
  String get enterAName => 'Anna nimi';

  @override
  String get enterAValidAmount => 'Anna kelvollinen määrä';

  @override
  String get enterAPositiveAmount => 'Anna positiivinen määrä';

  @override
  String get maximum120GH => 'Enintään 120 g/h';

  @override
  String get carbohydrateTargetGH => 'Hiilihydraattitavoite g/h';

  @override
  String get fluidTargetMlH => 'Nestetavoite ml/h';

  @override
  String get sodiumTargetMgHNot => 'Natriumtavoite mg/h (ei suola)';

  @override
  String get surfaceFeedingAccess => 'Alusta / ravinnon saatavuus';

  @override
  String get expectedAscentM => 'Odotettu nousu m';

  @override
  String get expectedAltitudeM => 'Odotettu korkeus m';

  @override
  String get humidity => 'Ilmankosteus %';

  @override
  String get windKmH => 'Tuuli km/h';

  @override
  String get dayForecast => 'Päivän ennuste';

  @override
  String get enteredConditions => 'Syötetyt olosuhteet';

  @override
  String get productFoodName => 'Tuotteen / ruoan nimi';

  @override
  String get servingsQuantity => 'Annokset / määrä';

  @override
  String get when => 'Milloin';

  @override
  String get carbohydrateGServing => 'Hiilihydraatit g / annos';

  @override
  String get fluidMlServing => 'Neste ml / annos';

  @override
  String get caffeineMgServing => 'Kofeiini mg / annos';

  @override
  String get proteinGServing => 'Proteiini g / annos';

  @override
  String get gel => 'Geeli';

  @override
  String get water => 'Vesi';

  @override
  String get sportsDrink => 'Urheilujuoma';

  @override
  String get bar => 'Patukka';

  @override
  String get finishIntakeLog => 'Viimeistele nauttimisloki';

  @override
  String get importing => 'Tuodaan…';

  @override
  String importNewreadings(Object newReadings) {
    return 'Tuo $newReadings';
  }

  @override
  String get reading => 'Luetaan…';

  @override
  String get chooseReportPdf => 'Valitse raportti (PDF)';

  @override
  String get yourTrainingHistoryIsReady => 'Harjoitushistoriasi on valmis';

  @override
  String get importingYourTrainingHistory => 'Harjoitushistoriaasi tuodaan';

  @override
  String get stopImport => 'Pysäytä tuonti';

  @override
  String get dismiss => 'Hylkää';

  @override
  String get openai => 'OpenAI';

  @override
  String get appleIntelligence => 'Apple Intelligence';

  @override
  String get nonAiBriefing => 'Katsaus ilman tekoälyä';

  @override
  String get noBriefing => 'Ei katsausta';

  @override
  String get ruleBasedSummaryFromYour =>
      'Sääntöpohjainen yhteenveto terveystiedoistasi – ei API-kutsuja';

  @override
  String get hideTheBriefingCard => 'Piilota katsauskortti';

  @override
  String get flutter => 'Flutter';

  @override
  String get stateManagement => 'Tilanhallinta';

  @override
  String get bluetoothLe => 'Bluetooth LE';

  @override
  String get interactiveMaps => 'Interaktiiviset kartat';

  @override
  String get chartsGraphs => 'Kaaviot ja graafit';

  @override
  String get secureCredentialStorage => 'Tunnusten turvallinen tallennus';

  @override
  String get markdownRendering => 'Markdown-esitys';

  @override
  String get appleOnDeviceAi => 'Applen laitteen tekoäly';

  @override
  String get cryptography => 'Kryptografia';

  @override
  String get appleHealthHealthConnect => 'Apple Terveys ja Health Connect';

  @override
  String get runtimePermissions => 'Suoritusaikaiset käyttöoikeudet';

  @override
  String get shareExport => 'Jakaminen ja vienti';

  @override
  String get openUrls => 'Avaa URL-osoitteita';

  @override
  String get internationalisation => 'Kansainvälistäminen';

  @override
  String get utilities => 'Apuohjelmat';

  @override
  String get icons => 'Kuvakkeet';

  @override
  String get fjelia => 'Fjelia';

  @override
  String get fjeliaFeedback => 'Fjelia-palaute';

  @override
  String get couldNotSendTheReport =>
      'Raportin lähettäminen epäonnistui. Tekstisi on edelleen tallessa. Yritä uudelleen.';

  @override
  String get yourEmail => 'Sähköpostisi';

  @override
  String get enterAValidEmailAddress => 'Anna kelvollinen sähköpostiosoite.';

  @override
  String get subject => 'Aihe';

  @override
  String get sending => 'Lähetetään…';

  @override
  String get sendReport => 'Lähetä raportti';

  @override
  String get sleepRecovery => 'Uni ja palautuminen';

  @override
  String get activitiesTraining => 'Aktiviteetit ja harjoittelu';

  @override
  String get bodyWellness => 'Keho ja hyvinvointi';

  @override
  String get hilo => 'Hilo';

  @override
  String get hiloBle => 'Hilo BLE';

  @override
  String get garminApi => 'Garmin (API)';

  @override
  String get renphoScale => 'Renpho-vaaka';

  @override
  String get connected => 'Yhdistetty';

  @override
  String get notConnected => 'Ei yhdistetty';

  @override
  String get manage => 'Hallitse';

  @override
  String get connect => 'Yhdistä';

  @override
  String get habits => 'Tottumukset';

  @override
  String get smokingAlcohol => 'Tupakointi, alkoholi';

  @override
  String get clinicalLab => 'Laboratorioarvot';

  @override
  String get hba1cLipidsKidney => 'HbA1c, rasva-arvot, munuaiset';

  @override
  String get sex => 'Sukupuoli';

  @override
  String get smoking => 'Tupakointi';

  @override
  String get never => 'Ei koskaan';

  @override
  String get former => 'Entinen';

  @override
  String get current => 'Nykyinen';

  @override
  String get hba1c => 'HbA1c';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get prediabetes => 'Esidiabetes';

  @override
  String get type1 => 'Tyyppi 1';

  @override
  String get type2 => 'Tyyppi 2';

  @override
  String get apob => 'ApoB';

  @override
  String get optionalPlansAndPaceGuides =>
      'Valinnainen. Suunnitelmat ja vauhtiohjeet käyttävät sitä; myös yllä oleva nousu muokkaa harjoittelua.';

  @override
  String get addRaceGoal2 => 'Lisää kisatavoite';

  @override
  String get editRaceGoal => 'Muokkaa kisatavoitetta';

  @override
  String get trailRunning2 => 'Polkujuoksu';

  @override
  String get roadCycling => 'Maantiepyöräily';

  @override
  String get gravel => 'Gravel';

  @override
  String get indoorRowing => 'Sisärudo';

  @override
  String get selectDate => 'Valitse päivämäärä';

  @override
  String get committed => 'Sitoutunut';

  @override
  String get flexible => 'Joustava';

  @override
  String get notGoing => 'Ei osallistu';

  @override
  String get notSaid => 'Ei kerrottu';

  @override
  String get finish => 'Maaliaika';

  @override
  String get saveGoal => 'Tallenna tavoite';

  @override
  String get exportAllRecordedWorkoutsAs =>
      'Vie kaikki kirjatut harjoitukset taulukkona.';

  @override
  String get backupsIncludeYourHealthData =>
      'Varmuuskopiot sisältävät terveystietosi, harjoitussuunnitelmat ja profiiliasetukset. Kirjautumistunnukset eivät sisälly. Palautus korvaa paikalliset tiedot.';

  @override
  String get trail => 'Polku';

  @override
  String get inlineSkating => 'Rullaluistelu';

  @override
  String get nordicClassic => 'Perinteinen hiihto';

  @override
  String get skateSkiing => 'Luistelihiihto';

  @override
  String get strength => 'Voima';

  @override
  String get walking => 'Kävely';

  @override
  String get yoga => 'Jooga';

  @override
  String get skiing => 'Hiihto';

  @override
  String get climbing => 'Kiipeily';

  @override
  String get monday => 'Maanantai';

  @override
  String get sunday => 'Sunnuntai';

  @override
  String get month => 'Kuukausi';

  @override
  String get week => 'Viikko';

  @override
  String get list => 'Lista';

  @override
  String get train => 'Harjoitus';

  @override
  String get restDay => 'Lepo';

  @override
  String get kilogramsKg => 'Kilogrammat (kg)';

  @override
  String get poundsLb => 'Paunat (lb)';

  @override
  String get regenerateWorkouts => 'Luo harjoitukset uudelleen';

  @override
  String get starting => 'Käynnistetään';

  @override
  String get allPlannedWorkoutsDeleted =>
      'Kaikki suunnitellut harjoitukset poistettu.';

  @override
  String get searching => 'Haetaan…';

  @override
  String get searchCity => 'Hae kaupunkia';

  @override
  String get fixedLocationSavedWeatherWill =>
      'Kiinteä sijainti tallennettu. Sää päivittyy.';

  @override
  String get locationDisabledThePlanWeather =>
      'Sijainti poistettu käytöstä. Suunnitelman säänäkymä on piilotettu.';

  @override
  String locationSetToName(Object name) {
    return 'Sijainniksi asetettu $name';
  }

  @override
  String get notEnoughDaytimeAndNighttime =>
      'Päivä- ja yömittauksia ei ole tarpeeksi';

  @override
  String get onlyTheWeightWasReceived =>
      'Vain paino vastaanotettiin. Rasvaa, lihaksia ja muita arvoja varten seiso paljain jaloin metallielektrodeilla, kunnes vaaka on valmis.';

  @override
  String get addYourWaistInProfile =>
      'Lisää vyötärönympärys Profiiliin viskeraalirasvaa varten.';

  @override
  String get manualActivity => 'Manuaalinen aktiviteetti';

  @override
  String get theseCredentialsAreStoredEncrypted =>
      'Nämä tunnukset tallennetaan salattuina laitteellesi (iOS-avainnippu / Android Keystore). Niitä ei koskaan lähetetä muulle palvelimelle kuin Hilolle.';

  @override
  String get corosCredentialsAreStoredEncrypted =>
      'Coros-tunnukset tallennetaan salattuina laitteellesi. Fjelia lukee tiedot suoraan Coroksen pilvirajapinnasta, jota myös Coros Training Hub -verkkosovellus käyttää.';

  @override
  String get connectAnyCombinationYouCan =>
      'Yhdistä mikä tahansa yhdistelmä – voit aina lisätä lisää myöhemmin Asetuksissa.';

  @override
  String get garminCredentialsAreStoredEncrypted =>
      'Garmin-tunnukset tallennetaan salattuina laitteellesi. Fjelia käyttää epävirallista Garmin Connect -rajapintaa, kuten monet yhteisön sovellukset.';

  @override
  String get enterTheVerificationCode => 'Syötä vahvistuskoodi';

  @override
  String get appleHealthDataAccess =>
      'Fjelia lukee terveystietosi Apple Terveydestä. Luvallasi se voi myös kirjoittaa synkronoituja tietoja Apple Terveyteen. Hallitse käyttöoikeuksia laitteesi asetuksissa.';

  @override
  String get scanAgain => 'Hae uudelleen';

  @override
  String get wearTheHiloBandDuring =>
      'Pidä Hilo-rannekettä unen aikana jatkuvaa verenpaineen mittausta varten. Tiedot synkronoidaan automaattisesti joka aamu, kun avaat sovelluksen.';

  @override
  String get noPolarH10FoundWear2 =>
      'Polar H10:tä ei löytynyt. Pue hihna kosteilla elektrodeilla ja varmista, ettei siihen ole yhdistetty toista sovellusta (tai kelloa); hae sitten uudelleen.';

  @override
  String get wearTheStrapWithMoist2 =>
      'Pue hihna kosteilla elektrodeilla ennen hakua. Mittaa myöhemmin kohdasta + → Polar H10 HRV-mittaus; tulokset näkyvät yöllisen HRV:si vieressä.';

  @override
  String get signedInPlannedWorkoutsCan =>
      'Kirjauduttu. Suunnitellut harjoitukset voi nyt lähettää Polariin. Vanhemmat harjoitukset tuodaan seuraavassa täydessä historian synkronoinnissa.';

  @override
  String get saveYourPolarFlowLogin =>
      'Tallenna Polar Flow -kirjautumisesi, jotta voit lähettää suunniteltuja harjoituksia ja tuoda yli 30 päivää vanhoja harjoituksia. Se pysyy tämän laitteen avainnipussa ja lähetetään vain Polarille. Lähetä harjoitus suunnittelijan näkymästä ja synkronoi sitten Polar Flow kellollesi. Tarkista, että Polarin sykealueet vastaavat Fjeliaa.';

  @override
  String get signInToSendThis =>
      'Kirjaudu sisään lähettääksesi tämän harjoituksen Polar Flow -kalenteriisi. Kirjautumisesi pysyy tämän laitteen avainnipussa ja lähetetään vain Polarille. Synkronoi lähetyksen jälkeen Polar Flow kellollesi.';

  @override
  String get checkAndSave => 'Tarkista ja tallenna';

  @override
  String get noScaleFoundStepOn =>
      'Vaakaa ei löytynyt. Astu vaa\'alle, jotta se herää, ja hae uudelleen.';

  @override
  String get stepOnTheScaleBefore =>
      'Astu vaa\'alle ennen hakua, jotta se herää. Myöhemmin mittaa kohdasta + → RENPHO-vaaka.';

  @override
  String get renphoCredentialsAreStoredEncrypted =>
      'Renpho-tunnukset tallennetaan salattuina laitteellesi. Fjelia keskustelee suoraan Renphon pilvirajapinnan kanssa.';

  @override
  String get couldNotSendSmsCheck =>
      'Tekstiviestin lähetys epäonnistui. Tarkista puhelinnumerosi ja internetyhteytesi.';

  @override
  String get theEmailIsUsedFor =>
      'Sähköpostia käytetään pyyntöjen turvalliseen allekirjoitukseen, eikä sitä lähetetä Suunnon palvelimille.';

  @override
  String get suuntoUsesSmsVerificationSame =>
      'Suunto käyttää tekstiviestivahvistusta (kuten Suunto-sovellus). Puhelimeesi lähetetään kertakäyttöinen PIN-koodi. Tunnuksesi tallennetaan salattuina vain laitteelle.';

  @override
  String get tellUsAboutYourRace =>
      'Kerro kilpailustasi ja aikataulustasi. Fjelia rakentaa suunnitelmasi nyt ja päättelee tasosi aiemmista aktiviteeteistasi (Garmin, Suunto, Polar, COROS, Apple Terveys), kun ne on ladattu.';

  @override
  String get noAccountConnectedSoFjelia =>
      'Tiliä ei ole yhdistetty, joten Fjelialla ei ole historiaa, josta oppia. Yhdistä Garmin, Suunto, Polar, COROS tai Apple Terveys, niin todellinen harjoittelusi ratkaisee.';

  @override
  String get yourPastActivitiesAreStill =>
      'Aiempia aktiviteettejasi tuodaan vielä. Voit rakentaa suunnitelman nyt – se tarkentuu automaattisesti, kun tuonti on valmis.';

  @override
  String get buildingYourPlan => 'Rakennetaan suunnitelmaasi…';

  @override
  String get saveContinue => 'Tallenna ja jatka';

  @override
  String get addYourMainPriorityA =>
      'Lisää päätapahtumasi (prioriteetti A). Suunnitelma jaksotetaan sitä kohti: peruskunto, kehitys, huippu ja kevennys. Ilman kisatavoitetta suunnitelmaa ei vielä luoda.';

  @override
  String get noMeasurementsYet => 'Ei vielä mittauksia';

  @override
  String get date => 'Päivämäärä';

  @override
  String deepSleepIsBelowOptimal(Object round) {
    return 'Syvä uni on alle optimin ($round %). Vältä alkoholia ja raskaita aterioita 3 tuntia ennen nukkumaanmenoa.';
  }

  @override
  String get finishWithSetsOpen => 'Lopetetaanko avoimin sarjoin?';

  @override
  String get completeThePlannedWorkout =>
      'Merkitäänkö suunniteltu harjoitus tehdyksi?';

  @override
  String get marksThePlannedSessionAs =>
      'Merkitsee suunnitellun harjoituksen tehdyksi tällä harjoituksella.';

  @override
  String get discardThisWorkout => 'Hylätäänkö tämä harjoitus?';

  @override
  String get removesTheWorkoutAndEvery =>
      'Poistaa harjoituksen ja kaikki siihen kirjatut sarjat.';

  @override
  String assistanceName(Object name) {
    return 'Avustus ($name)';
  }

  @override
  String get enterSecondsOrMSs => 'Syötä sekunteja tai m:ss.';

  @override
  String get enterTheLoadAsA => 'Syötä kuorma numerona.';

  @override
  String get loadCannotBeNegative => 'Kuorma ei voi olla negatiivinen.';

  @override
  String get enterTheEffortValue => 'Syötä rasitusarvo.';

  @override
  String get nameTheExercise => 'Anna liikkeelle nimi.';

  @override
  String get atLeastOneImplement => 'Vähintään yksi väline.';

  @override
  String get anIncrementMustBePositive => 'Lisäyksen on oltava positiivinen.';

  @override
  String get enterAPositiveStep => 'Syötä positiivinen askel.';

  @override
  String get repsInReserve => 'Toistot varalla';

  @override
  String get loadPerImplement => 'Kuorma per väline';

  @override
  String get restAfterThisSet => 'Lepo tämän sarjan jälkeen';

  @override
  String get enterHowLongTheSet => 'Syötä sarjan kesto.';

  @override
  String get repsDonePerSide => 'Tehdyt toistot per puoli';

  @override
  String plannedRepminRepmax(Object repMin, Object repMax) {
    return 'Suunniteltu $repMin–$repMax';
  }

  @override
  String get restTakenBeforeTheNext => 'Lepo ennen seuraavaa sarjaa';

  @override
  String get equipment => 'Välineet';

  @override
  String get implementsUsedTogether => 'Yhdessä käytetyt välineet';

  @override
  String get smallestLoadStepOptional => 'Pienin kuormanlisäys (valinnainen)';

  @override
  String get theSmallestChangeYourPlates =>
      'Pienin muutos, jonka levysi, käsipainosi tai laitteesi sallivat; muistetaan tälle välineelle.';

  @override
  String get loadStep => 'Kuormanlisäys';

  @override
  String get finishWithIncompleteData => 'Lopetetaanko keskeneräisin tiedoin?';

  @override
  String get leaveWithoutSaving => 'Poistutaanko tallentamatta?';

  @override
  String get theLastChangeCouldNot =>
      'Viimeisintä muutosta ei voitu tallentaa.';

  @override
  String get comparedWithAPlanChosen =>
      'Verrattu harjoituksen jälkeen valittuun suunnitelmaan. Suunnitellut arvot ovat vihjeitä, eivät tuloksia.';

  @override
  String get lastSet => 'Viimeinen sarja';

  @override
  String get templateName => 'Mallin nimi';

  @override
  String get betweenExercises => 'Liikkeiden välillä';

  @override
  String get betweenRounds => 'Kierrosten välillä';

  @override
  String get discardChanges => 'Hylätäänkö muutokset?';

  @override
  String get yourEditsToThisWorkout =>
      'Tämän harjoituksen muutoksia ei ole tallennettu.';

  @override
  String get estimatedDuration => 'Arvioitu kesto';

  @override
  String get workingSets => 'Työsarjat';

  @override
  String get estimatedExternalVolume => 'Arvioitu ulkoinen volyymi';

  @override
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion) {
    return 'Kuormaa nostettu arvosta $unit arvoon $unit2 tarkistuksesi jälkeen (sääntö v$ruleVersion).';
  }

  @override
  String get thePlannedWorkoutHasNo =>
      'Suunnitellussa harjoituksessa ei ole kirjattavia liikkeitä.';

  @override
  String get completedSets => 'Suoritetut sarjat';

  @override
  String get knownExternalVolume => 'Tunnettu ulkoinen volyymi';

  @override
  String get updateStrengthSessions2 => 'Päivitetäänkö voimaharjoitukset?';

  @override
  String get upcomingSessionsArePlannedAgain =>
      'Tulevat harjoitukset suunnitellaan uudelleen tästä päivästä alkaen: voimaharjoittelu seuraa kisatavoitteitasi jokaisena voimapäivänä vaihtelevin harjoituksin. Suoritetut ja ohitetut harjoitukset säilyvät; tulevassa voimaharjoituksessa muuttamasi liikkeet korvataan.';

  @override
  String get thisSessionUsesAnEarlier =>
      'Tämä harjoitus käyttää aiempaa voimamallia. Päivitetyt suunnitelmat vaihtelevat voimaharjoittelua vaiheen ja kisatavoitteen mukaan ja käyttävät jokaisen voimapäivän.';

  @override
  String get estimated1rmUsesEpleyAnd =>
      'Arvioitu 1RM käyttää Epleyn ja Brzyckin kaavoja suoritetuille 1–10 toiston työsarjoille, joiden kuorma tunnetaan, ja näytetään niiden välisenä vaihteluvälinä. Se on arvio, ei testattu maksimi.';

  @override
  String get localWeather => 'Paikallinen sää';

  @override
  String get today => 'Tänään';

  @override
  String get low => 'Matala';

  @override
  String get moderate => 'Kohtalainen';

  @override
  String get overcast => 'Pilvistä';

  @override
  String get partlyCloudy => 'Puolipilvistä';

  @override
  String collapseName(Object name) {
    return 'Tiivistä $name';
  }

  @override
  String get variableLoads => 'Vaihtelevat kuormat';

  @override
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  ) {
    return 'Sääntö v$strengthProgressionRuleVersion: viimeiset $strengthProgressionMinSessions vertailukelpoista harjoitusta, jokainen sarja toistotavoitteen yläpäässä, rasitus kirjattuna eikä aiottua raskaampi. $reason';
  }

  @override
  String get stepOnYourScaleBefore => 'Astu vaa\'alle ennen hakua';

  @override
  String get scanning => 'Haetaan…';

  @override
  String get pair => 'Yhdistä';

  @override
  String get selectYourAktiiaPWristband =>
      'Valitse AKTIIA P… -rannekkeesi. Aseta se laturiin herättääksesi sen, jos se ei näy.';

  @override
  String get measurementInterruptedWhileTheApp =>
      'Mittaus keskeytyi, kun sovellus oli taustalla. Toista se.';

  @override
  String get noRecentRrDataWith =>
      'Ei tuoreita RR-tietoja hyvällä kontaktilla. Tarkista hihna ja toista mittaus.';

  @override
  String get settlingStayStill => 'Tasaantuminen · pysy paikallasi';

  @override
  String get deleteSpotHrvMeasurement => 'Poistetaanko Hetki-HRV-mittaus?';

  @override
  String get thisRemovesTheRecordingAnd =>
      'Tämä poistaa tallenteen ja sen raa\'at RR-välit.';

  @override
  String get appleHealthStoppedAnsweringSo =>
      'Apple Terveys lakkasi vastaamasta, joten Fjelia katkaisi yhteyden eikä enää lue tai kirjoita terveystietoja.\n\nSalli Fjelia uudelleen kohdassa Asetukset → Terveys → Tietojen käyttö ja laitteet → Fjelia ja yhdistä sitten Apple Terveys uudelleen.';

  @override
  String get thisRemovesTheSelectedGrip =>
      'Tämä poistaa valitun puristusvoimamittauksen.';

  @override
  String get hideReminderDiagnostics => 'Piilota muistutusten diagnostiikka';

  @override
  String get loading => 'Ladataan…';

  @override
  String get touchTheChartForDetails =>
      'Napauta kaaviota nähdäksesi lisätiedot';

  @override
  String get indoor => 'Sisällä';

  @override
  String get road => 'Maantie';

  @override
  String get technical => 'Tekninen';

  @override
  String get snow => 'Lumi';

  @override
  String get pool => 'Uima-allas';

  @override
  String get openWater => 'Avovesi';

  @override
  String get ambientTemperatureC => 'Ympäristön lämpötila °C';

  @override
  String carryAboutGelsGelsGelcarbs(
    Object gels,
    Object gelCarbs,
    Object bottles,
    Object bottleMl,
    Object drinkCarbs,
  ) {
    return 'Ota mukaan noin $gels geeliä ($gelCarbs g hiilihydraatteja kukin) + $bottles × $bottleMl ml pulloa. $drinkCarbs g hiilihydraatteja tulee juomajauheesta.';
  }

  @override
  String get intakeNotRecorded => 'Nauttimista ei kirjattu';

  @override
  String get loggingDeclinedIntakeUnknown =>
      'Kirjaus hylätty – nauttiminen tuntematon';

  @override
  String get confirmedNoIntake => 'Vahvistettu: ei nauttimista';

  @override
  String get draft => 'Luonnos · ';

  @override
  String get actualIntakePerServing =>
      'Todellinen nauttiminen · annosta kohden';

  @override
  String get minuteIntoWorkoutDuringOnly =>
      'Harjoituksen minuutti (vain aikana, valinnainen)';

  @override
  String get sodiumMgServingNotSalt => 'Natrium mg / annos (ei suola)';

  @override
  String get comfortable => 'Mukava';

  @override
  String get mildSymptoms => 'Lieviä oireita';

  @override
  String get moderateSymptoms => 'Kohtalaisia oireita';

  @override
  String get severeSymptoms => 'Vaikeita oireita';

  @override
  String get personalNutritionSettings =>
      'Henkilökohtaiset ravitsemusasetukset';

  @override
  String get practisedCarbohydrateToleranceGH =>
      'Harjoiteltu hiilihydraattien sieto g/h (enintään 120)';

  @override
  String get exportTheMonthlyReportAs =>
      'Vie kuukausiraportti PDF-tiedostona Hilo-sovelluksessa ja valitse se tästä. Vain mittaukset tuodaan; raportin nimi, sähköposti ja kehotiedot ohitetaan.';

  @override
  String get nothingNewAllReadingsWere =>
      'Ei uutta: kaikki mittaukset oli jo tallennettu.';

  @override
  String get historyImportIncomplete => 'Historian tuonti on kesken';

  @override
  String get youCanKeepUsingFjelia =>
      'Voit jatkaa Fjelian käyttöä, mutta pidä se auki: iOS keskeyttää tuonnin, kun sovellus on taustalla, ja se jatkuu seuraavalla avauskerralla. Suunnitelmasi kalibroidaan, kun tuonti on valmis.';

  @override
  String get addYourBirthYearIn =>
      'Lisää syntymävuotesi kohdassa Asetukset → Profiili nähdäksesi arviosi.';

  @override
  String get fitnessAge => 'Kuntoikä';

  @override
  String get estLifespan => 'Arv. elinikä';

  @override
  String get delta => 'Ero';

  @override
  String couldNotOpenKey(Object key) {
    return 'Kohdetta $key ei voitu avata';
  }

  @override
  String get appleIntelligenceIsNotAvailable =>
      'Apple Intelligence ei ole käytettävissä tällä laitteella. Käytä Free AI -palvelua tai valitse toinen palveluntarjoaja.';

  @override
  String get personalisedMorningLunchAfternoonEvening =>
      'Personoitu yhteenveto aamulle/lounaalle/iltapäivälle/illalle';

  @override
  String get enterASubject => 'Anna aihe.';

  @override
  String get message => 'Viesti';

  @override
  String get enterAMessageOfAt =>
      'Kirjoita viesti, jossa on vähintään 10 merkkiä.';

  @override
  String get garminConnect => 'Garmin Connect';

  @override
  String get hiloBloodPressure => 'Hilo (verenpaine)';

  @override
  String get renphoBodyScale => 'Renpho (henkilövaaka)';

  @override
  String get hiloPodCuff => 'Hilo Pod / mansetti';

  @override
  String disconnectLabel(Object label) {
    return 'Katkaistaanko yhteys: $label?';
  }

  @override
  String get yourSavedMeasurementsWillRemain =>
      'Tallennetut mittauksesi säilyvät tällä laitteella.';

  @override
  String get notEnoughRecentHeartRate =>
      'Tuoreita sykemittauksia ei ole tarpeeksi alueiden säätämiseen.';

  @override
  String get aerobicBase => 'Aerobinen perusta';

  @override
  String get tempo => 'Tempo';

  @override
  String get lactateThreshold => 'Laktaattikynnys';

  @override
  String get birthYearHeightWaist => 'Syntymävuosi, pituus, vyötärö';

  @override
  String get enterAValidValue => 'Anna kelvollinen arvo';

  @override
  String get birthYear => 'Syntymävuosi';

  @override
  String get height => 'Pituus';

  @override
  String get waist => 'Vyötärö';

  @override
  String get yearsSinceQuit => 'Vuotta lopettamisesta';

  @override
  String get cigarettesPerDay => 'Savukkeita päivässä';

  @override
  String get standardDrinksPerMonth => 'Annosta kuukaudessa';

  @override
  String get enterAValidNumber => 'Anna kelvollinen luku';

  @override
  String get enterARaceName => 'Anna kilpailun nimi';

  @override
  String get useHMmOrH =>
      'Käytä muotoa h:mm tai h:mm:ss, aikaa jonka voisit oikeasti juosta';

  @override
  String get flexibleThePlanMayDrop =>
      'Joustava: suunnitelma voi pudottaa tämän tapahtuman, jos se on ristiriidassa tärkeämmän kanssa.';

  @override
  String get selectARaceDate => 'Valitse kilpailupäivä';

  @override
  String thatIsTenTimesOr(Object likely) {
    return 'Tämä on kymmenkertainen (tai kymmenesosa) tavanomaisesta $likely km:stä. Käytetäänkö sen sijaan $likely km?';
  }

  @override
  String get addGoal => 'Lisää tavoite';

  @override
  String get restoreFailed => 'Palautus epäonnistui';

  @override
  String get replaceLocalData => 'Korvataanko paikalliset tiedot?';

  @override
  String get restoringThisBackupReplacesAll =>
      'Tämän varmuuskopion palauttaminen korvaa kaikki paikalliset terveys- ja harjoitustiedot. Olemassa olevat kirjautumistunnukset säilyvät.';

  @override
  String get openingBackupZip => 'Avataan varmuuskopion ZIP-tiedostoa';

  @override
  String get addAFutureRaceGoal => 'Lisää ensin tuleva kisatavoite.';

  @override
  String get deleteAllWorkouts2 => 'Poistetaanko kaikki harjoitukset?';

  @override
  String get thisDeletesPlannedWorkoutsOn =>
      'Tämä poistaa suunnitellut harjoitukset tästä puhelimesta ja yhdistetystä kelloalustasta. Suoritetut aktiviteetit säilyvät.';

  @override
  String get regenerateWorkouts2 => 'Luodaanko harjoitukset uudelleen?';

  @override
  String get noRaceGoalsYetAdd =>
      'Ei vielä kisatavoitteita. Lisää yksi tai synkronoi Garminista.';

  @override
  String get deleteRaceGoal => 'Poistetaanko kisatavoite?';

  @override
  String deletingFailedFailure(Object failure) {
    return 'Poisto epäonnistui: $failure';
  }

  @override
  String allPlannedWorkoutsDeletedRemoved(Object removed) {
    return 'Kaikki suunnitellut harjoitukset poistettu. Poistettu alustoiltasi: $removed.';
  }

  @override
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return 'Käytetään nykyistä sijaintia: $toStringAsFixed, $toStringAsFixed2';
  }

  @override
  String get typeSleep => 'Uni';

  @override
  String get typeBloodPressure => 'Verenpaine';

  @override
  String get addHiloBpReportPdf => 'Lisää Hilo-verenpaineraportti (PDF)';

  @override
  String get hiloCuffBle => 'Hilo-mansetti (BLE)';

  @override
  String get typeSpo2 => 'SpO₂ / pulssioksimetri';

  @override
  String get typeWeightScale => 'Henkilövaaka';

  @override
  String get polarH10HrvMeasurement => 'Polar H10 HRV-mittaus';

  @override
  String samplingWouldStartMinutes(Object minutes) {
    return 'Näytteenotto alkaisi noin $minutes min harjoituksen päättymisen jälkeen.';
  }

  @override
  String samplingStartedMinutes(Object minutes) {
    return 'Näytteenotto alkoi $minutes min harjoituksen päättymisen jälkeen.';
  }

  @override
  String get unknown => 'Tuntematon';

  @override
  String get before => 'Ennen';

  @override
  String get during => 'Aikana';

  @override
  String get after => 'Jälkeen';

  @override
  String get enumWarmUp => 'Alkulämmittely';

  @override
  String get enumWorking => 'Työsarja';

  @override
  String get enumBackOff => 'Back-off';

  @override
  String get enumTechnique => 'Tekniikka';

  @override
  String get enumExternalLoad => 'Ulkoinen kuorma';

  @override
  String get enumBandResistance => 'Kuminauha / vastus';

  @override
  String get enumTotalLoad => 'Kokonaiskuorma';

  @override
  String get enumPerImplement => 'Per väline';

  @override
  String get enumOneImplement => 'Yksi väline';

  @override
  String get enumBothSides => 'Molemmat puolet';

  @override
  String get enumAlternatingTotalReps => 'Vuorotellen, toistot yhteensä';

  @override
  String get enumPartial => 'Osittain';

  @override
  String get enumFailed => 'Epäonnistui';

  @override
  String get enumStraightSets => 'Tavalliset sarjat';

  @override
  String get enumSuperset => 'Superseria';

  @override
  String get enumCircuit => 'Kierto';

  @override
  String get enumRir => 'RIR';

  @override
  String get enumRpe110 => 'RPE 1–10';

  @override
  String get enumBeforeTraining => 'Ennen harjoitusta';

  @override
  String get enumAfterTraining => 'Harjoituksen jälkeen';

  @override
  String get enumResting => 'Levossa';

  @override
  String get enumSeated => 'Istuen';

  @override
  String get enumLyingDown => 'Makuulla';

  @override
  String get duringRoutineGelsAreNot =>
      'Aikana: säännölliset geelit eivät ole tarpeen tässä lyhyessä/kevyessä harjoituksessa. Juo janon mukaan.';

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      'Aikana: jaa hiilihydraatit ja juomat pieniin, säännöllisiin annoksiin. Laske juoman hiilihydraatit samaan summaan kuin geelit ja ruoka.';

  @override
  String get fluidIsAnEditableStarting =>
      'Neste on muokattava lähtöarvio, ei kiintiö. Käytä apuna janoa, harjoiteltua nauttimista ja mitattuja hikihäviöitä; älä pakota juomaan ylimääräistä vettä.';

  @override
  String get afterHaveCarbohydrateAndA =>
      'Jälkeen: nauti hiilihydraatteja ja proteiinipitoinen ateria. Priorisoi täydennys ja nesteytys, jos seuraava harjoitus on pian.';

  @override
  String get swimmingPlaceALabelledBottle =>
      'Uinti: aseta merkitty pullo altaan reunalle ja käytä sarjattaukoja kulauksiin tai ravintoon. Allasolosuhteet voivat poiketa ulkosäästä.';

  @override
  String get runningCarryAccessibleGelsFlasks =>
      'Juoksu: pidä geelit/pullot helposti saatavilla tai suunnittele ravinto huoltopisteille; harjoittele samat tuotteet ja ajoitus ennen kilpailua.';

  @override
  String get servingSizesAndToleranceMust =>
      'Annoskokojen ja siedon on oltava positiivisia.';

  @override
  String get enterFiniteNonNegativeMeasurements =>
      'Syötä äärellisiä, ei-negatiivisia mittauksia.';

  @override
  String get targetsMustBeFiniteAnd =>
      'Tavoitteiden on oltava äärellisiä ja ei-negatiivisia.';

  @override
  String get conditionsMustBeFiniteOr =>
      'Olosuhteiden on oltava äärellisiä tai tuntemattomia.';

  @override
  String get humidityMustBeBetween0 => 'Ilmankosteuden on oltava 0–100 %.';

  @override
  String get noIntakeCannotIncludeFood =>
      '”Ei nauttimista” ei voi sisältää ruokaa tai juomia.';

  @override
  String get addAnItemOrConfirm =>
      'Lisää kohde tai vahvista, ettet nauttinut mitään.';

  @override
  String get eachIntakeNeedsAProduct =>
      'Jokaiseen nauttimiseen tarvitaan tuote ja kelvollinen ajankohta.';

  @override
  String get quantityMustBePositive => 'Määrän on oltava positiivinen.';

  @override
  String get thisActivityNoLongerExists => 'Tätä aktiviteettia ei enää ole.';

  @override
  String get practisedCarbohydrateToleranceMustNot =>
      'Harjoitellun hiilihydraattisiedon ei tule ylittää 120 g/h.';

  @override
  String get measuredSweatRateMustBe =>
      'Mitatun hikoilun on oltava positiivinen tai jätettävä tuntemattomaksi.';

  @override
  String get increasePractisedToleranceInNutrition =>
      'Nosta harjoiteltua siettoa ravitsemusasetuksissa ennen korkeamman tavoitteen valitsemista.';

  @override
  String get fluidTargetExceedsYourMeasured =>
      'Nestetavoite ylittää mitatun hikoilunopeutesi. Tarkista mittaus tai tavoite.';

  @override
  String get elapsedWorkoutTimeMustBe =>
      'Kuluneen harjoitusajan on oltava positiivinen tai jätettävä tyhjäksi.';

  @override
  String get intakeAmountsMustBeFinite =>
      'Nautittujen määrien on oltava äärellisiä ja ei-negatiivisia.';

  @override
  String get selectedStrategyUnavailableChooseAnother =>
      'Valittu strategia ei ole käytettävissä. Valitse toinen strategia tai ei vertailua.';

  @override
  String get recordYourWorkoutNutrition => 'Kirjaa harjoituksen ravinto';

  @override
  String get addTheFoodAndFluids =>
      'Lisää aktiviteettihistoriaan ruoka ja nesteet, jotka todella nautit.';

  @override
  String get logIntake => 'Kirjaa nauttiminen';

  @override
  String nutritionReminderTitle(String name) {
    return 'Uusi aktiviteetti: $name';
  }

  @override
  String get nutritionReminderBody => 'Lisää, mitä söit ja joit.';

  @override
  String get nutritionReminderHrvHint =>
      'Harjoituksen jälkeistä HRV:tä ei ole vielä mitattu.';

  @override
  String get in30Minutes => '30 minuutin päästä';

  @override
  String get loadSuggestionsCoverStraightSets =>
      'Kuormaehdotukset kattavat vain tavalliset toistopohjaiset sarjat.';

  @override
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  ) {
    return 'Vaatii $strengthProgressionMinSessions kirjattua harjoitusta tästä liikkeestä.';
  }

  @override
  String get recentHistoryIsTooOld =>
      'Viimeaikainen historia on liian vanhaa ehdotukselle.';

  @override
  String get theLastSessionDidNot =>
      'Viimeisessä harjoituksessa ei käytetty yhtä tunnettua kuormaa.';

  @override
  String get theLoadChangedBetweenThe =>
      'Kuorma muuttui viimeaikaisten harjoitusten välillä.';

  @override
  String get notEverySetReachedThe =>
      'Kaikki sarjat eivät yltäneet toistotavoitteensa ylärajalle.';

  @override
  String get recordEffortRirOrRpe =>
      'Kirjaa rasitus (RIR tai RPE) viimeiselle sarjalle saadaksesi ehdotuksia.';

  @override
  String get recentSetsWereHarderThan =>
      'Viimeaikaiset sarjat olivat aiottua raskaampia.';

  @override
  String get thisWorkoutAlreadyHasIts =>
      'Tällä harjoituksella on jo oma kuormansa; se pysyy asetettuna.';

  @override
  String get yourRecentSetsMetThe =>
      'Viimeaikaiset sarjasi täyttivät progressiosäännön. Aseta tämän välineen pienin kuormanlisäys tarkistaaksesi kuorman.';

  @override
  String get thisWorkoutNoLongerExists => 'Tätä harjoitusta ei enää ole.';

  @override
  String thisStrengthPlanCannotBe(Object message) {
    return 'Tätä voimasuunnitelmaa ei voi lukea ($message).';
  }

  @override
  String get thisStrengthPlanCannotBe2 =>
      'Tätä voimasuunnitelmaa ei voi lukea.';

  @override
  String get addAtLeastOneExercise => 'Lisää vähintään yksi liike.';

  @override
  String get thisWorkoutWasChangedElsewhere =>
      'Tätä harjoitusta muutettiin muualla. Muutoksesi säilyvät; lataa uudelleen nähdäksesi uudemman version.';

  @override
  String get thePlanThisWorkoutIs =>
      'Suunnitelmaa, johon tätä harjoitusta verrataan, ei voi lukea.';

  @override
  String get thisLogWasChangedElsewhere =>
      'Tätä lokia muutettiin muualla. Merkintäsi säilyvät; lataa uudelleen nähdäksesi uudemman version.';

  @override
  String get thisZipIsNotA => 'Tämä ZIP ei ole tuettu Fjelia-varmuuskopio.';

  @override
  String get theBackupDatabaseIsDamaged =>
      'Varmuuskopion tietokanta on vioittunut.';

  @override
  String get invalidBackupData => 'Virheelliset varmuuskopiotiedot.';

  @override
  String get backupTablesDoNotMatch => 'Varmuuskopion taulut eivät täsmää.';

  @override
  String get invalidBackupColumns => 'Virheelliset varmuuskopion sarakkeet.';

  @override
  String get migratingOriginalAppBackup =>
      'Siirretään alkuperäisen sovelluksen varmuuskopiota';

  @override
  String get theOriginalBackupIsMissing =>
      'Alkuperäisestä varmuuskopiosta puuttuu tarvittavia tauluja.';

  @override
  String get backupFormatOrDatabaseVersion =>
      'Varmuuskopion muoto tai tietokantaversio ei täsmää.';

  @override
  String get restoringRecords => 'Palautetaan tietueita';

  @override
  String get restoringSettings => 'Palautetaan asetuksia';

  @override
  String get restoreComplete => 'Palautus valmis';

  @override
  String get effortMustBeANumber => 'Rasituksen on oltava luku.';

  @override
  String get theDurationEstimateMustBe =>
      'Keston arvion on oltava positiivinen.';

  @override
  String get restCannotBeNegative => 'Lepo ei voi olla negatiivinen.';

  @override
  String get enterTheRepetitionsDoneThe =>
      'Syötä tehdyt toistot; suunnitelmassa on vaihteluväli.';

  @override
  String get enterTheLoadThePlan => 'Syötä kuorma; suunnitelmassa ei ole sitä.';

  @override
  String get enterTheResistanceThePlan =>
      'Syötä vastus; suunnitelmassa ei ole sitä.';

  @override
  String get poorSensorContact => 'Huono anturin kontakti';

  @override
  String get moreThan25FromLocal => 'Yli 25 % paikallisesta mediaanista';

  @override
  String get workoutNutrition => 'Harjoitusravinto';

  @override
  String get postWorkoutFoodAndFluid =>
      'Muistutus ruoka- ja nestelokista harjoituksen jälkeen';

  @override
  String get postTrainingHrvMeasurementReminder =>
      'Muistutus HRV-mittauksesta harjoituksen jälkeen';

  @override
  String get rirRunsFrom0To => 'RIR on väliltä 0–10+.';

  @override
  String get rpeRunsFrom1To => 'RPE on väliltä 1–10.';

  @override
  String get repetitionsCannotBeNegative =>
      'Toistot eivät voi olla negatiivisia.';

  @override
  String get timedWorkMustBeLonger =>
      'Aikaan perustuvan työn on kestettävä yli nolla sekuntia.';

  @override
  String get chooseRepetitionsOrTimedWork =>
      'Valitse toistot tai aikaan perustuva työ, ei molempia.';

  @override
  String get loadMustBeAFinite =>
      'Kuorman on oltava äärellinen, ei-negatiivinen luku.';

  @override
  String get durationCannotBeNegative => 'Keston ei voi olla negatiivinen.';

  @override
  String get hrTimeline => 'Sykeaikajana';

  @override
  String get dayTrainingLoad => 'Päivän harjoituskuormitus';

  @override
  String get weekdayComparison => 'Viikonpäivien vertailu';

  @override
  String get weeklyTrainingLoad => 'Viikoittainen harjoituskuormitus';

  @override
  String get zonePolarization => 'Alueiden polarisaatio';

  @override
  String get elevationOverview => 'Korkeusyleiskatsaus';

  @override
  String get trainingMonitor => 'Harjoitusseuranta';

  @override
  String get formAtlCtlTsb => 'ATL / CTL / TSB -kunto';

  @override
  String get trainingPlanProgress => 'Harjoitussuunnitelman eteneminen';

  @override
  String get rhrSleep => 'Leposyke unessa';

  @override
  String get hrvSleep => 'HRV unessa';

  @override
  String get spo2Sleep => 'SpO₂ unessa';

  @override
  String get respRate => 'Hengitystiheys';

  @override
  String get stress => 'Stressi';

  @override
  String get skinTemp => 'Ihon lämpötila';

  @override
  String get steps => 'Askeleet';

  @override
  String get tonightsSleep => 'Tämän yön uni';

  @override
  String get activityLog => 'Aktiviteettiloki';

  @override
  String get activityLog2 => 'Aktiviteettiloki';

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
    return '${durationSeconds}h ${durationSeconds2}m · $distanceMeters km · $avgHeartRate bpm · ↑$totalElevation m';
  }

  @override
  String get heatAcclimation2 => 'LÄMPÖÖN SOPEUTUMINEN';

  @override
  String score(Object score) {
    return '$score%';
  }

  @override
  String get elevation => 'NOUSU';

  @override
  String get t12WeekHistory => '12 VIIKON HISTORIA';

  @override
  String get zonePolarization2 => 'ALUEIDEN POLARISAATIO';

  @override
  String get t5WeekHistory => '5 VIIKON HISTORIA';

  @override
  String get easy => 'KEVYT %';

  @override
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded) {
    return '$withZones/$recorded aktiviteetilla on sykealuetiedot';
  }

  @override
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples) {
    return '$fromSamples rekonstruoitu tallennetuista sykenäytteistä';
  }

  @override
  String get easyZ12ModerateZ3 =>
      'Kevyt: Z1–2 · Kohtalainen: Z3 · Raskas: Z4–5';

  @override
  String get activitiesWithoutHrZoneData =>
      'Aktiviteetit ilman sykealuetietoja jätetään prosenttiosuuksien ulkopuolelle.';

  @override
  String avgAverageUnit(Object average, Object unit) {
    return 'KESK $average $unit';
  }

  @override
  String get weekdayComparison2 => 'VIIKONPÄIVIEN VERTAILU';

  @override
  String get trainingPlanProgress2 => 'HARJOITUSSUUNNITELMAN ETENEMINEN';

  @override
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  ) {
    return 'Viikko $currentWeek / $durationInWeeks';
  }

  @override
  String get t30MinTimeTrialLt2 => '30 MINUUTIN AIKA-AJO – LT2';

  @override
  String get run30MinutesAtThe =>
      'Juokse 30 minuuttia kovimmalla kestämälläsi teholla – hallitusti, ei sprinttinä. Nosta teho vähitellen; älä aloita liian kovaa. Viimeisten 20 minuutin keskivauhti ja -syke ovat LT2:si.';

  @override
  String get recordAsANormalOutdoor =>
      'Tallenna tavallisena ulkojuoksuna. Käynnistä kello, merkitse aika ja juokse 30 min kisavauhtia.';

  @override
  String get t50MinTotalFlatCourse =>
      '~50 min yhteensä · tasainen reitti · ei kovan harjoituksen jälkeen';

  @override
  String get doNotStartTooFast =>
      'Älä aloita liian kovaa. Tähtää tasaisiin väliaikoihin.';

  @override
  String get theAppAveragesHrAnd =>
      'Sovellus laskee syken ja vauhdin keskiarvon testin viimeiseltä 20 minuutilta lämmittelyn ja ensimmäisten 10 minuutin jälkeen. Valitse tallennettu aktiviteetti kohdassa Laske.';

  @override
  String get lt2Pace => 'LT2-VAUHTI';

  @override
  String get activityRunningEnoughTimeFor =>
      'Aktiviteetti (juoksu, riittävästi aikaa lämmittelyyn + 30 min, sykkeen kanssa)';

  @override
  String get selectTheTtActivity => 'Valitse testiaktiviteetti';

  @override
  String nameStartdate(Object name, Object startDate) {
    return '$name · $startDate';
  }

  @override
  String get warmUpBeforeTt => 'Lämmittely ennen testiä';

  @override
  String roundMin(Object round) {
    return '$round min';
  }

  @override
  String get clearResults => 'Tyhjennä tulokset';

  @override
  String get heartRate2 => 'SYKE';

  @override
  String get paceSecKmLowerIs => 'Vauhti (s/km – pienempi on nopeampi)';

  @override
  String get thresholdsFitnessTests => 'Kynnykset ja kuntotestit';

  @override
  String get lt1 => 'LT1';

  @override
  String get lt2 => 'LT2';

  @override
  String get voPace => 'VO₂-vauhti';

  @override
  String get ftp => 'FTP';

  @override
  String get setFtpManually => 'Aseta FTP käsin';

  @override
  String get calculateFromAnActivity => 'Laske aktiviteetista';

  @override
  String get setFtp => 'Aseta FTP';

  @override
  String get ftpWatts => 'FTP (wattia)';

  @override
  String get ftpCyclingThresholdPower => 'FTP – PYÖRÄILYN KYNNYSTEHO';

  @override
  String get ftpHistory => 'FTP-HISTORIA';

  @override
  String get updateFromActivity => 'PÄIVITÄ AKTIVITEETISTA';

  @override
  String get tapAnActivityFtpBest =>
      'Napauta aktiviteettia – FTP = paras 20 min teho × 0,95';

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
      'Ei ajoja, joissa on 20 minuuttia yhtäjaksoisia tehonäytteitä.';

  @override
  String get enterFtpManually => 'Syötä FTP käsin';

  @override
  String get selectTheTestActivity => 'Valitse testiaktiviteetti';

  @override
  String get formAtlCtlTsb2 => 'KUNTO · ATL / CTL / TSB';

  @override
  String get closeTrainingFormFullscreen =>
      'Sulje harjoituskunto koko näytöltä';

  @override
  String get expandTrainingForm => 'Laajenna harjoituskunto';

  @override
  String get calculatedFromTheFirstAvailable =>
      'Laskettu ensimmäisestä saatavilla olevasta kuormitustiedosta. Päivät ilman kirjattua kuormitusta lasketaan nollaksi; aiempi harjoittelu on tuntematonta.';

  @override
  String get trainingMonitor2 => 'HARJOITUSSEURANTA';

  @override
  String get pfitzingerZones => 'PFITZINGER-ALUEET';

  @override
  String get cyclingPowerZones => 'PYÖRÄILYN TEHOALUEET';

  @override
  String znumber(Object number) {
    return 'Z$number';
  }

  @override
  String paceHrDescription(Object pace, Object hr, Object description) {
    return '$pace · $hr\n$description';
  }

  @override
  String get weeklyTrainingLoad2 => 'VIIKOITTAINEN HARJOITUSKUORMITUS';

  @override
  String get prevWeek => 'EDELL. VK';

  @override
  String get bySport => 'LAJEITTAIN';

  @override
  String get noActivitiesThisWeek => 'Ei aktiviteetteja tällä viikolla';

  @override
  String garminWorkoutScheduleddate(Object scheduledDate) {
    return 'Garmin-harjoitus · $scheduledDate';
  }

  @override
  String get yourNote => 'Muistiinpanosi';

  @override
  String get askAiCoach => 'Kysy tekoälyvalmentajalta';

  @override
  String get aiSettings => 'Tekoälyasetukset';

  @override
  String get askYourCoach => 'Kysy valmentajaltasi…';

  @override
  String get sendMessage => 'Lähetä viesti';

  @override
  String get sendFeedbackOrReportA => 'Lähetä palautetta tai ilmoita virheestä';

  @override
  String get addMeasurement2 => 'Lisää mittaus';

  @override
  String get syncLabel2 => 'Synkronoi';

  @override
  String get syncToday => 'Synkronoi tänään';

  @override
  String get fullSync1Year => 'Täysi synkronointi · 1 vuosi';

  @override
  String get fullSyncComplete => 'Täysi synkronointi · Valmis';

  @override
  String get syncingYourData => 'Synkronoidaan tietojasi…';

  @override
  String lLeftkgRRightkgKg2(Object leftKg, Object rightKg) {
    return 'V $leftKg  O $rightKg kg';
  }

  @override
  String weightKgFatBodyfatMuscle(
    Object weight,
    Object bodyFat,
    Object muscleMass,
  ) {
    return '$weight kg · Rasva $bodyFat % · Lihakset $muscleMass kg';
  }

  @override
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase) {
    return '$title, $sport, $toLowerCase';
  }

  @override
  String get weatherUnavailableTapToRetry =>
      'Sää ei käytettävissä · Yritä uudelleen napauttamalla';

  @override
  String get weatherSetYourLocation => 'Sää · Aseta sijaintisi';

  @override
  String get t7DayForecast => '7 PÄIVÄN ENNUSTE';

  @override
  String get minMax => 'pienin/suurin';

  @override
  String get rainMm2 => 'sade mm';

  @override
  String get uvMax => 'UV enint.';

  @override
  String get kmH => 'km/h';

  @override
  String alt(Object alt) {
    return '→ $alt';
  }

  @override
  String raceGoalsLength(Object length) {
    return 'Kisatavoitteet · $length';
  }

  @override
  String gWk(Object g) {
    return '$g vk';
  }

  @override
  String weeks(Object weeks) {
    return '$weeks';
  }

  @override
  String get weeks2 => 'viikkoa';

  @override
  String get upcoming => 'TULEVAT';

  @override
  String lengthMoreDays(Object length) {
    return '+ $length päivää lisää';
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
      '○ Suunniteltu   ● Suoritettu   ✕ Ohitettu';

  @override
  String get heartRate3 => 'Syke';

  @override
  String get watts => 'Wattia';

  @override
  String theStepsAddUpTo(Object total, Object plannedDurationMin) {
    return 'Vaiheet summautuvat $total; suunnitelma laskee $plannedDurationMin min.';
  }

  @override
  String get typicalSplitForThisKind =>
      'Tyypillinen jakauma tämäntyyppiselle harjoitukselle; ei vaiheita, joista se laskettaisiin.';

  @override
  String labelGetsEachExerciseWith(Object label) {
    return '$label saa jokaisen liikkeen sarjoineen, toistoineen ja kuormineen. Toistovälit, rasitus ja tempo jäävät Fjeliaan.';
  }

  @override
  String get markAsRest => 'Merkitse lepopäiväksi';

  @override
  String get restoreWorkout => 'Palauta harjoitus';

  @override
  String get skipThisWorkout => 'Ohitetaanko tämä harjoitus?';

  @override
  String get previousWeek => 'Edellinen viikko';

  @override
  String get backToThisWeek => 'Takaisin tähän viikkoon';

  @override
  String get thisWeek => 'Tämä viikko';

  @override
  String get nextWeek => 'Seuraava viikko';

  @override
  String get today2 => 'TÄNÄÄN';

  @override
  String get route => 'REITTI';

  @override
  String get feedback => 'Palaute';

  @override
  String get plannedWorkout => 'Suunniteltu harjoitus';

  @override
  String get delete => 'Poista';

  @override
  String get chatAi => 'Tekoälychat';

  @override
  String get trainingLoad => 'Harjoituskuormitus';

  @override
  String get dayTrainingLoad2 => 'PÄIVÄN HARJOITUSKUORMITUS';

  @override
  String get trimp => ' TRIMP';

  @override
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter) {
    return '$scoreBefore → $scoreAfter';
  }

  @override
  String get temperatureOverTime => 'LÄMPÖTILA AJAN YLI';

  @override
  String roundh(Object round) {
    return '${round}h';
  }

  @override
  String get timeInHrZones => 'Aika sykealueilla';

  @override
  String get route2 => 'Reitti';

  @override
  String get start => 'Lähtö';

  @override
  String get gpx => 'GPX';

  @override
  String touppercasesubstringBriefing(Object toUpperCase, Object substring) {
    return '$toUpperCase$substring-katsaus';
  }

  @override
  String get chatWithAiAboutThis =>
      'Keskustele tekoälyn kanssa tästä katsauksesta';

  @override
  String get whyThisRecommendation => 'Miksi tämä suositus?';

  @override
  String titleDateLabel(Object title, Object date, Object label) {
    return '$title, $date, $label';
  }

  @override
  String get previousDay => 'Edellinen päivä';

  @override
  String get nextDay => 'Seuraava päivä';

  @override
  String get updating => 'Päivitetään';

  @override
  String get resting => 'LEVOSSA';

  @override
  String get noTimedReadings => 'Ei ajoitettuja mittauksia';

  @override
  String get avg => 'KESK';

  @override
  String get peak => 'HUIPPU';

  @override
  String tolocalRoundmin(Object toLocal, Object round) {
    return '$toLocal · ${round}min';
  }

  @override
  String avgheartrateBpmAvg(Object avgHeartRate) {
    return '$avgHeartRate bpm keskim.';
  }

  @override
  String get timeWeightedAverageOverRecorded =>
      'Aikapainotettu keskiarvo tallennetuilta jaksoilta. Aukot ilman mittauksia jätetään pois.';

  @override
  String get previousHeartRatePeriod => 'Edellinen sykejakso';

  @override
  String get nextHeartRatePeriod => 'Seuraava sykejakso';

  @override
  String get avgHr => 'Keskisyke';

  @override
  String get restingHr => 'Leposyke';

  @override
  String get both => 'Molemmat';

  @override
  String averagelabelFixedMs(Object averageLabel, Object fixed) {
    return '$averageLabel $fixed ms';
  }

  @override
  String get measureWithPolarH10 => 'Mittaa Polar H10:llä';

  @override
  String get ms => 'ms';

  @override
  String get noWorkoutInThisPeriod =>
      'Yhdelläkään jakson harjoituksella ei ole vertailukelpoista ennen/jälkeen-paria.';

  @override
  String textEachWorkoutCountsOnce(Object text) {
    return '$text. Jokainen harjoitus lasketaan kerran; tämä kuvaa parejasi, ei pisteytä niitä.';
  }

  @override
  String get workoutFinished => 'Harjoitus päättynyt?';

  @override
  String get yourWorkoutIsNotIn =>
      'Harjoitustasi ei ole vielä Fjeliassa. Jos se on päättynyt, kerro milloin, niin muistutus voi seurata todellista loppua. Muuten se ilmestyy kellon synkronoinnin jälkeen.';

  @override
  String get workoutFinished2 => 'Harjoitus päättynyt';

  @override
  String get theWorkoutMustStartAfter =>
      'Harjoituksen on alettava mittauksen jälkeen ja päätyttävä alkamisensa jälkeen, ei tulevaisuudessa.';

  @override
  String daysDAvg(Object days) {
    return '$days pv keskim.';
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
  String get previousPeriod => 'Edellinen jakso';

  @override
  String get nextPeriod => 'Seuraava jakso';

  @override
  String get overnightHrvReflectsRecoveryCompare =>
      'Yöllinen HRV kuvastaa palautumista. Vertaa lukemiasi omaan perustasoosi ajan mittaan.';

  @override
  String get moveThisWorkout => 'SIIRRÄ TÄMÄ HARJOITUS';

  @override
  String get pickDate => 'Valitse päivä';

  @override
  String movedFromMovedfrom(Object movedFrom) {
    return 'Siirretty päivästä $movedFrom';
  }

  @override
  String get hrvAroundThisWorkout => 'HRV tämän harjoituksen ympärillä';

  @override
  String get measureAfterTraining => 'Mittaa harjoituksen jälkeen';

  @override
  String get measureAgain => 'Mittaa uudelleen';

  @override
  String get explainWithAi => 'Selitä tekoälyllä';

  @override
  String beforeEndedPregapAheadOf(Object preGap) {
    return 'Ennen päättyi $preGap ennen alkua.';
  }

  @override
  String lengthFurtherMeasurementSAfter(Object length) {
    return '$length lisämittausta tämän harjoituksen jälkeen säilytetään lisähavaintoina.';
  }

  @override
  String get noHrvMeasurementRecordedAround =>
      'Tämän harjoituksen ympärillä ei ole kirjattu HRV-mittausta.';

  @override
  String get measureHrv => 'Mittaa HRV';

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
      'Tämän parin kuvaus, ei harjoituksen pisteytys.';

  @override
  String notEnoughComparableWorkoutsYet(Object eligible, Object need) {
    return 'Vertailukelpoisia harjoituksia ei ole vielä tarpeeksi, $eligible/$need.';
  }

  @override
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need) {
    return 'Vertailukelpoisia harjoituksia ei ole vielä tarpeeksi ($eligible/$need).';
  }

  @override
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  ) {
    return 'Samankaltaiset $eligible harjoitustasi · $toLocal–$toLocal2';
  }

  @override
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  ) {
    return 'Keskimmäinen puolisko $q1Ms–$q3Ms ms · mediaani $medianMs ms · tämä harjoitus $delta ms';
  }

  @override
  String rpeI(Object i) {
    return 'RPE $i';
  }

  @override
  String get easy2 => 'kevyt';

  @override
  String get allOut => 'Täysillä';

  @override
  String workoutProfileDescription(Object description) {
    return 'Harjoitusprofiili: $description';
  }

  @override
  String get noActivitiesInThisPeriod => 'Ei aktiviteetteja tällä jaksolla';

  @override
  String get enableHeatAcclimationInTraining =>
      'Ota lämpöön sopeutuminen käyttöön harjoitusasetuksissa.';

  @override
  String get noElevationThisWeek => 'Ei nousua tällä viikolla';

  @override
  String get noActivitiesSynced => 'Ei synkronoituja aktiviteetteja';

  @override
  String get noHrZoneData => 'Ei sykealuetietoja';

  @override
  String get easyJogGetHrElevated =>
      'Kevyt hölkkä – nosta sykettä, jalat rennoiksi';

  @override
  String get fastestSustainablePaceLikeA =>
      'Nopein ylläpidettävä vauhti – kuin 30 minuutin kisa';

  @override
  String get walkCardiacRecovery => 'Kävely – sydämen palautuminen';

  @override
  String get selectTheTtActivityFirst => 'Valitse ensin testiaktiviteetti.';

  @override
  String get calculating => 'Lasketaan…';

  @override
  String get calculateLt2 => 'Laske LT2';

  @override
  String get enterFtpBetween30And => 'Syötä FTP väliltä 30–1000 W.';

  @override
  String get aerobicThreshold => 'Aerobinen kynnys';

  @override
  String get functionalThresholdPower => 'Toiminnallinen kynnysteho';

  @override
  String get estimated => 'Arvioitu';

  @override
  String get afterWarmingUpRunFive =>
      'Juokse lämmittelyn jälkeen viisi minuuttia nopeimmalla ylläpidettävällä teholla. Tallenna juoksu nopeus- tai matkatiedoilla.';

  @override
  String get recordAtLeast40Minutes =>
      'Tallenna vähintään 40 minuuttia tasaista juoksua vakioteholla. Testi vertaa sykettä kummassakin puoliskossa aerobisen ajautuman arvioimiseksi.';

  @override
  String get theFastestFiveMinuteWindow =>
      'Nopein viiden minuutin jakso antaa VO2max-vauhtisi.';

  @override
  String get noResultYet => 'Ei vielä tulosta';

  @override
  String get calculateVo2maxPace => 'Laske VO2max-vauhti';

  @override
  String get calculateLt1 => 'Laske LT1';

  @override
  String get loading2 => 'Ladataan';

  @override
  String get unavailable => 'Ei käytettävissä';

  @override
  String get noTrainingHistory => 'Ei harjoitushistoriaa';

  @override
  String get fitnessCtl => 'Kunto (CTL)';

  @override
  String get fatigueAtl => 'Väsymys (ATL)';

  @override
  String get formTsb => 'Päiväkunto (TSB)';

  @override
  String get noHistory => 'Ei historiaa';

  @override
  String get fresh => 'Virkeä';

  @override
  String get optimal => 'Optimaalinen';

  @override
  String get neutral => 'Neutraali';

  @override
  String get tired => 'Väsynyt';

  @override
  String get veryFatigued => 'Erittäin väsynyt';

  @override
  String get garminRunningVo2max => 'Garmin-juoksun VO2max';

  @override
  String get garminCyclingVo2max => 'Garmin-pyöräilyn VO2max';

  @override
  String get aerobicThreshold2 => 'Aerobinen kynnys';

  @override
  String driftDriftAt(Object drift, Object at) {
    return 'Ajautuma $drift % · $at';
  }

  @override
  String get activityHours => 'Aktiviteettitunnit';

  @override
  String get activityKm => 'Aktiviteettikilometrit';

  @override
  String get tap5MinuteMaxTest => 'Napauta · 5 min maksimitesti';

  @override
  String get setFtpToCalculatePower => 'Aseta FTP laskeaksesi tehoalueet';

  @override
  String get cyclingPowerZones2 => 'Pyöräilyn tehoalueet';

  @override
  String get pfitzingerZones2 => 'Pfitzinger-alueet';

  @override
  String get completeAnLt2TestTo => 'Tee LT2-testi laskeaksesi juoksualueet.';

  @override
  String get setFtpToCalculatePower2 => 'Aseta FTP laskeaksesi tehoalueet.';

  @override
  String get endurance => 'Kestävyys';

  @override
  String get threshold => 'Kynnys';

  @override
  String get anaerobic => 'Anaerobinen';

  @override
  String get whatExplainsThisRise => 'Mikä selittää tämän nousun?';

  @override
  String get whatExplainsThisDrop => 'Mikä selittää tämän laskun';

  @override
  String get whatExplainsThisRise2 => 'Mikä selittää tämän nousun';

  @override
  String get editsAreKeptInFjelia =>
      'Muutokset säilyvät Fjeliassa paikallisena kopiona tälle päivälle. Garminin harjoitusta ei muuteta.';

  @override
  String get howDoIExecuteThis => 'Miten suoritan tämän harjoituksen?';

  @override
  String shareHealthContextWithName(Object name) {
    return 'Jaetaanko terveyskonteksti palvelun $name kanssa?';
  }

  @override
  String get yourMessageAndAHealth =>
      'Viestisi ja terveys-/harjoitusyhteenveto lähetetään tälle pilvipohjaiselle tekoälypalvelulle. Nimet ja GPS jätetään luodusta yhteenvedosta pois.';

  @override
  String get couldNotGetAReply =>
      'Vastausta ei saatu. Tarkista tekoälyasetuksesi ja yritä uudelleen.';

  @override
  String get askAboutYourRecoveryTraining =>
      'Kysy palautumisestasi, harjoittelustasi tai tämän päivän suunnitelmasta.';

  @override
  String get noSyncYet => 'Ei vielä synkronoitu';

  @override
  String lastSyncLastContext(Object last, Object context) {
    return 'Viimeisin synkronointi: $last $context';
  }

  @override
  String get seasonWithTradeOffs => 'Kausi: kompromisseineen';

  @override
  String get seasonNeedsYourDecision => 'Kausi: tarvitsee päätöksesi';

  @override
  String get seasonCannotBeCombined => 'Kausi: ei yhdistettävissä';

  @override
  String get seasonProvisional => 'Kausi: alustava';

  @override
  String get season => 'Kausi';

  @override
  String get allGoalsFit => 'Kaikki tavoitteet mahtuvat mukaan.';

  @override
  String goalTargetfinishsecondsgoal(Object targetFinishSeconds, Object goal) {
    return 'Tavoite $targetFinishSeconds$goal';
  }

  @override
  String estEstimateestimate2(Object estimate, Object estimate2) {
    return 'Arv. $estimate$estimate2';
  }

  @override
  String doneDoneby(Object doneBy) {
    return 'Tehty · $doneBy';
  }

  @override
  String garminWorkoutWorkout(Object workout) {
    return 'Garmin-harjoitus · $workout';
  }

  @override
  String get moveAnyway => 'Siirretäänkö silti?';

  @override
  String get wattsNeedYourFtpSet =>
      'Wattit tarvitsevat FTP:si: aseta se kohdassa Kuormitus, Kynnykset.';

  @override
  String get mainTargetInWattsFrom =>
      'Päätavoite watteina FTP:stäsi, syke ohjeena.';

  @override
  String get mainTargetHeartRateWatts =>
      'Päätavoite syke; wattia ei ole asetettu kellossa.';

  @override
  String get taperPhase => 'Kevennysvaihe';

  @override
  String get recoverySession => 'Palauttava harjoitus';

  @override
  String get closeToYourEvent => 'Lähellä tapahtumaasi';

  @override
  String get noWorkoutStructureAvailable =>
      'Harjoitusrakennetta ei ole saatavilla.';

  @override
  String get aerobic => 'Aerobinen';

  @override
  String get pushAgainToUpdateYour =>
      'Lähetä uudelleen päivittääksesi kellosi kalenterin.';

  @override
  String workoutSentToLabel(Object label) {
    return 'Harjoitus lähetetty palveluun $label';
  }

  @override
  String get updating2 => 'Päivitetään…';

  @override
  String pushToLabel(Object label) {
    return 'Lähetä palveluun $label';
  }

  @override
  String shareExerciseListForLabel(Object label) {
    return 'Jaa liikelista palvelulle $label';
  }

  @override
  String shareWorkoutForLabel(Object label) {
    return 'Jaa harjoitus palvelulle $label';
  }

  @override
  String get whyNothingIsAddedTo => 'Miksi? Mitään ei lisätä täydennykseksi.';

  @override
  String get workout => 'Harjoitus';

  @override
  String get recordedActivityLinkedToThis =>
      'Tallennettu aktiviteetti linkitetty tähän harjoitukseen';

  @override
  String get matchedToTheRecordedWorkout =>
      'Yhdistetty tallennetun harjoituksen alkuun';

  @override
  String get matchedByWorkoutNameSport =>
      'Yhdistetty harjoituksen nimen, lajin ja päivämäärän perusteella';

  @override
  String get matchedBySportDateAnd =>
      'Yhdistetty lajin, päivämäärän ja keston perusteella';

  @override
  String planPlannedminutesMin(Object plannedMinutes) {
    return 'Suunnitelma $plannedMinutes min';
  }

  @override
  String get maxHr => 'Maksimisyke';

  @override
  String get trainingLoad2 => 'Harjoituskuormitus';

  @override
  String get active => 'Aktiivinen';

  @override
  String get avgPace => 'Keskivauhti';

  @override
  String get avgSpeed => 'Keskinopeus';

  @override
  String get avgPower => 'Keskiteho';

  @override
  String get elevation2 => 'Nousu';

  @override
  String get altitude => 'Korkeus';

  @override
  String get explainMyHrvBeforeAnd =>
      'Selitä HRV:ni ennen tätä harjoitusta ja sen jälkeen. Mikä on vertailukelpoista, mikä ei ja mikä on vielä tuntematonta?';

  @override
  String get deleteActivity => 'Poistetaanko aktiviteetti?';

  @override
  String get removeThisActivityFromThe =>
      'Poistetaanko tämä aktiviteetti? Se pysyy poistettuna, myös kun laitteesi synkronoivat uudelleen. Voit palauttaa sen asetuksista kohdasta Äskettäin poistetut.';

  @override
  String get howDidThisSessionGo =>
      'Miten tämä harjoitus meni ja mitä se tarkoittaa seuraaville päivilleni?';

  @override
  String currentFixedFixed2(Object fixed, Object fixed2) {
    return 'Nykyinen $fixed, $fixed2';
  }

  @override
  String get setUpInTrainingSettings => 'Määritä harjoitusasetuksissa';

  @override
  String get couldNotLoadHeatData =>
      'Lämpötietoja ei voitu ladata – napauta nähdäksesi lisätiedot';

  @override
  String get loadingHeatHistory => 'Ladataan lämpöhistoriaa…';

  @override
  String get noHeatDataYet => 'Ei vielä lämpötietoja';

  @override
  String optimalLowHigh(Object low, Object high) {
    return 'Optimaalinen $low–$high';
  }

  @override
  String optimalLowHighTrimp(Object low, Object high) {
    return 'Optimaalinen: $low–$high TRIMP';
  }

  @override
  String get targetUnavailableSyncTrainingHistory =>
      'Tavoite ei käytettävissä – synkronoi harjoitushistoria';

  @override
  String get workoutQualifiedForHeatAccumulation =>
      'Harjoitus kelpasi lämpökertymään.';

  @override
  String get workoutDidNotAddHeat => 'Harjoitus ei lisännyt lämpökertymää.';

  @override
  String get performanceTime => 'Suoritus / Aika';

  @override
  String get performanceDistance => 'Suoritus / Matka';

  @override
  String get noRecordedRoute => 'Ei tallennettua reittiä';

  @override
  String get zoomIn => 'Lähennä';

  @override
  String get zoomOut => 'Loitonna';

  @override
  String get fitRoute => 'Sovita reitti';

  @override
  String get fullscreenMap => 'Kartta koko näytölle';

  @override
  String get openstreetmapContributors2 => 'OpenStreetMapin tekijät';

  @override
  String get appleIntelligenceIsUnavailableShowing =>
      'Apple Intelligence ei ole käytettävissä. Näytetään yhteenveto ilman tekoälyä.';

  @override
  String get generateAiBriefing => 'Luodaanko tekoälykatsaus?';

  @override
  String get retryAiBriefing => 'Yritä tekoälykatsausta uudelleen';

  @override
  String get generateBriefing => 'Luo katsaus';

  @override
  String discussThisBriefingWithMe(Object text) {
    return 'Keskustele tästä katsauksesta kanssani ja ehdota paras seuraava toimenpide.\n\n$text';
  }

  @override
  String whyThisRecommendationWhichOf(Object text) {
    return 'Miksi tämä suositus? Mitkä lukuni ja tietoaukot johtivat siihen, ja mikä muuttaisi sen?\n\n$text';
  }

  @override
  String get avg2 => 'Keskim.';

  @override
  String get peak2 => 'Huippu';

  @override
  String get notEnoughContinuousReadingsFor =>
      'Ei tarpeeksi yhtäjaksoisia mittauksia keskiarvoon.';

  @override
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  ) {
    return 'Tallennettu kattavuus: $inHours h $inMinutes min · aikapainotettu keskiarvo';
  }

  @override
  String get lying => 'Makuulla';

  @override
  String get noHrvReadingsInThis => 'Ei HRV-mittauksia tällä jaksolla';

  @override
  String get overnightHrvComesFromYour =>
      'Yöllinen HRV tulee kellostasi, hetkimittaukset Polar H10:stä (RMSSD). Menetelmät eroavat: vertaa trendejä, ei yksittäisiä arvoja.';

  @override
  String get noReadings => 'Ei mittauksia';

  @override
  String get whenDidTheWorkoutStart => 'Milloin harjoitus alkoi?';

  @override
  String get whenDidItEnd => 'Milloin se päättyi?';

  @override
  String get last3Months => 'Viimeiset 3 kuukautta';

  @override
  String get lastYear => 'Viime vuosi';

  @override
  String lastDaysDays(Object days) {
    return 'Viimeiset $days päivää';
  }

  @override
  String nowOnCurrentTapA(Object current) {
    return 'Nyt $current. Napauta päivää tai vedä harjoitus sille. Vaiheet pysyvät ennallaan.';
  }

  @override
  String get monthView => 'Kuukausinäkymä';

  @override
  String get syncing => 'Synkronoidaan';

  @override
  String get trendUnavailable => 'Trendi ei käytettävissä';

  @override
  String get stable => 'Vakaa';

  @override
  String get increasing => 'Nouseva';

  @override
  String get decreasing => 'Laskeva';

  @override
  String get unclear => 'Epäselvä';

  @override
  String get notComparable => 'Ei vertailukelpoinen';

  @override
  String get waitingForAfter => 'Odotetaan jälkeen-mittausta';

  @override
  String get afterOnly => 'Vain jälkeen';

  @override
  String get waitingForTheActualWorkout =>
      'Odotetaan harjoituksen todellista päättymistä.';

  @override
  String reminderAroundTolocal(Object toLocal) {
    return 'Muistutus noin $toLocal';
  }

  @override
  String get reminderIsDueMeasureWhen =>
      'Muistutus on erääntynyt. Mittaa, kun olet valmis.';

  @override
  String get thisReminderIsNoLonger =>
      'Tämä muistutus ei ole enää ajankohtainen. Avaa harjoitus nähdäksesi mittauksesi.';

  @override
  String beforeFixedMilliseconds(Object fixed) {
    return 'Ennen $fixed millisekuntia. ';
  }

  @override
  String afterFixedMilliseconds(Object fixed) {
    return 'Jälkeen $fixed millisekuntia';
  }

  @override
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  ) {
    return 'Muutos $deltaMs millisekuntia, $deltaPercent prosenttia.';
  }

  @override
  String get noPreTrainingMeasurementRecorded =>
      'Harjoitusta edeltävää mittausta ei ole kirjattu.';

  @override
  String get notMeasuredYet => 'Ei vielä mitattu';

  @override
  String leftOutOfTheComparison(Object excludedTotal, Object c) {
    return 'Jätetty vertailun ulkopuolelle: $excludedTotal harjoitusta ($c).';
  }

  @override
  String get notFromThisWorkout => 'Ei tästä harjoituksesta';

  @override
  String get useAsBefore => 'Käytä ennen-arvona';

  @override
  String get useAsAfter => 'Käytä jälkeen-arvona';

  @override
  String get beforeNotMeasured => 'Ennen · ei mitattu';

  @override
  String beforeTolocal(Object toLocal) {
    return 'Ennen · $toLocal';
  }

  @override
  String workoutWorkouttext(Object workoutText) {
    return 'Harjoitus · $workoutText';
  }

  @override
  String get afterNotMeasuredYet => 'Jälkeen · ei vielä mitattu';

  @override
  String afterTolocal(Object toLocal) {
    return 'Jälkeen · $toLocal';
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
    return 'Samankaltaiset harjoituksesi ($eligible, $toLocal–$toLocal2): mediaani $medianMs ms, keskimmäinen puolisko $q1Ms–$q3Ms ms.';
  }

  @override
  String get howHardDidItFeel => 'Kuinka raskasta se tuntui? (RPE)';

  @override
  String get loadMetric => 'Kuormitus';

  @override
  String get clearAction => 'Tyhjennä';

  @override
  String get routeFinish => 'Maali';

  @override
  String get month2 => 'KUUKAUSI';

  @override
  String get week2 => 'VIIKKO';

  @override
  String get quarter => 'NELJÄNNES';

  @override
  String get year => 'VUOSI';

  @override
  String get easy3 => 'KEVYT';

  @override
  String get mod => 'KOHTAL.';

  @override
  String get hard => 'RASKAS';

  @override
  String get protocol => 'OHJEET';

  @override
  String get calculate => 'LASKE';

  @override
  String get warmUp => 'LÄMMITTELY';

  @override
  String get coolDown => 'LOPPUVERRYTTELY';

  @override
  String get ftpCycling => 'FTP pyöräily';

  @override
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg) {
    return 'FTP $ftpWatts W · $wattsPerKg W/kg';
  }

  @override
  String get thisWeekSoFar => 'TÄMÄ VIIKKO · TÄHÄN MENNESSÄ';

  @override
  String get duration2 => 'KESTO';

  @override
  String get distance2 => 'MATKA';

  @override
  String get sport2 => 'LAJI';

  @override
  String get repeatSets => 'TOISTOSARJAT';

  @override
  String get aboutThisWorkout => 'TIETOJA TÄSTÄ HARJOITUKSESTA';

  @override
  String get workoutStructure => 'HARJOITUKSEN RAKENNE';

  @override
  String get health2 => 'TERVEYS';

  @override
  String get high2 => 'KORKEA';

  @override
  String get elevated => 'KOHOLLA';

  @override
  String get normal => 'NORMAALI';

  @override
  String get tomorrow => 'HUOMENNA';

  @override
  String get skipped2 => 'OHITETTU';

  @override
  String get weeklyPlan => 'VIIKKOSUUNNITELMA';

  @override
  String get activityLog3 => 'AKTIVITEETTILOKI';

  @override
  String skippedTouppercase(Object toUpperCase) {
    return 'OHITETTU · $toUpperCase';
  }

  @override
  String get primaryZone => 'PÄÄALUE';

  @override
  String get coachingCues => 'VALMENNUSVINKIT';

  @override
  String get targets => 'TAVOITTEET';

  @override
  String get adaptation => 'MUKAUTUMINEN';

  @override
  String get done2 => 'TEHTY';

  @override
  String get notRecorded2 => 'EI KIRJATTU';

  @override
  String get planned => 'SUUNNITELTU';

  @override
  String get extra => 'YLIMÄÄRÄINEN';

  @override
  String get optimal2 => 'OPTIMAALINEN';

  @override
  String get qualified => 'KELPOINEN';

  @override
  String get temp => 'LÄMPÖ';

  @override
  String get humidity2 => 'ILMANKOSTEUS';

  @override
  String get pressure => 'ILMANPAINE';

  @override
  String get wetBulb => 'MÄRKÄLÄMPÖTILA';

  @override
  String get paceMinKm => 'Vauhti (min/km)';

  @override
  String get speedKmH => 'Nopeus (km/h)';

  @override
  String get elevationM => 'Nousu (m)';

  @override
  String get powerW => 'TEHO (W)';

  @override
  String get performanceTime2 => 'SUORITUS / AIKA';

  @override
  String get performanceDistance2 => 'SUORITUS / MATKA';

  @override
  String get load2 => 'KUORMITUS';

  @override
  String get day2 => 'PÄIVÄ';

  @override
  String get allTime => 'KOKO AIKA';

  @override
  String get hrvAroundThisWorkout2 => 'HRV tämän harjoituksen ympärillä. ';

  @override
  String get lowReserve => 'MATALA VARANTO';

  @override
  String get goodReserve => 'HYVÄ VARANTO';

  @override
  String latestReadingAtTolocal(Object toLocal) {
    return 'Viimeisin mittaus klo $toLocal';
  }

  @override
  String get weeklyAvg => 'VIIKKOKESKIARVO';

  @override
  String get monthlyAvg => 'KUUKAUSIKESKIARVO';

  @override
  String get systolic2 => 'SYSTOLINEN';

  @override
  String get diastolic2 => 'DIASTOLINEN';

  @override
  String get hourlyVariation => 'TUNTIVAIHTELU';

  @override
  String get dailyVariation => 'PÄIVÄVAIHTELU';

  @override
  String get sys2 => 'SYS';

  @override
  String get dia => 'DIA';

  @override
  String get bluetoothDevices => 'BLUETOOTH-LAITTEET';

  @override
  String get accountsServices => 'TILIT JA PALVELUT';

  @override
  String get flowLoginOptional => 'FLOW-KIRJAUTUMINEN (VALINNAINEN)';

  @override
  String get polarFlowLogin => 'POLAR FLOW -KIRJAUTUMINEN';

  @override
  String get raceGoal => 'KISATAVOITE';

  @override
  String get experienceLevel => 'KOKEMUSTASO';

  @override
  String get weeklySchedule2 => 'VIIKKOAIKATAULU';

  @override
  String get sessionsPerDay2 => 'HARJOITUKSIA PÄIVÄSSÄ';

  @override
  String get aboutYou => 'TIETOJA SINUSTA';

  @override
  String get yourActivities2 => 'AKTIVITEETTISI';

  @override
  String latestReadingAtTimestamp(Object timestamp) {
    return 'Viimeisin mittaus klo $timestamp';
  }

  @override
  String get poorSleep => 'HUONO UNI';

  @override
  String get fairSleep => 'KOHTALAINEN UNI';

  @override
  String get goodSleep => 'HYVÄ UNI';

  @override
  String get hoursOfSleep => 'UNITUNTIA';

  @override
  String get sleepNeeded => 'TARVITTAVA UNI';

  @override
  String get deepSleep => 'SYVÄ UNI';

  @override
  String get exercises2 => 'LIIKKEET';

  @override
  String get strengthSummary => 'VOIMAYHTEENVETO';

  @override
  String get strengthDraft => 'VOIMA · LUONNOS';

  @override
  String get strengthFinishedWithGaps => 'VOIMA · PÄÄTETTY AUKKOINEEN';

  @override
  String get strength2 => 'VOIMA';

  @override
  String get wind => 'TUULI';

  @override
  String get sun2 => 'AURINKO';

  @override
  String get cloud => 'PILVET';

  @override
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt) {
    return 'Tiedot: $source · Päivitetty $fetchedAt';
  }

  @override
  String get coros2 => 'COROS';

  @override
  String get rmssdMs => 'RMSSD · ms';

  @override
  String get sdnnMs => 'SDNN · ms';

  @override
  String get now2 => 'NYT';

  @override
  String get awake => 'HEREILLÄ';

  @override
  String get light => 'KEVYT';

  @override
  String get deep2 => 'SYVÄ';

  @override
  String get sqliteOrm => 'SQLite ORM';

  @override
  String get httpClients => 'HTTP-asiakkaat';

  @override
  String get gpsLocation => 'GPS-sijainti';

  @override
  String get hdlCholesterol => 'HDL-kolesteroli';

  @override
  String get ldlCholesterol => 'LDL-kolesteroli';

  @override
  String get raceName => 'KILPAILUN NIMI';

  @override
  String get mtb => 'MTB';

  @override
  String get distanceKm => 'Matka (km)';

  @override
  String get priority => 'PRIORITEETTI';

  @override
  String get elevationGainM => 'Nousu (m)';

  @override
  String get targetTime => 'TAVOITEAIKA';

  @override
  String get raceDate => 'KILPAILUPÄIVÄ';

  @override
  String get participation => 'OSALLISTUMINEN';

  @override
  String get whatIWantFromIt => 'MITÄ HALUAN SIITÄ';

  @override
  String periodTimeline(Object period) {
    return '$period · AIKAJANA';
  }

  @override
  String get tabPlan => 'OHJELMA';

  @override
  String get tabLoad => 'KUORMA';

  @override
  String get tabCoach => 'COACH';

  @override
  String get hrDriftTestLt1 => 'SYKKEEN AJAUTUMISTESTI – LT1';

  @override
  String get asSentByGarmin => 'GARMININ LÄHETTÄMÄNÄ';

  @override
  String get noData2 => 'EI TIETOJA';

  @override
  String get noTarget => 'EI TAVOITETTA';

  @override
  String get noHeatLoad => 'EI LÄMPÖKUORMAA';

  @override
  String get hrBpm => 'Syke (bpm)';

  @override
  String get aiBriefingUnavailableShowingA =>
      'Tekoälykatsaus ei ole käytettävissä. Näytetään yhteenveto ilman tekoälyä.';

  @override
  String get uvIndex2 => 'UV-INDEKSI';

  @override
  String get aiBriefing => 'Tekoälykatsaus';

  @override
  String get uiFrameworkByGoogle => 'Googlen käyttöliittymäkehys';

  @override
  String get unableToLoadData => 'Tietoja ei voitu ladata';

  @override
  String briefingSummary(Object recovery, Object sleep, Object load) {
    return 'Palautuminen $recovery / 100. Uni $sleep / 100. Tämän päivän harjoituskuormitus on $load TRIMP.';
  }

  @override
  String get morningBriefing => 'Aamukatsaus';

  @override
  String get lunchBriefing => 'Lounaskatsaus';

  @override
  String get afternoonBriefing => 'Iltapäiväkatsaus';

  @override
  String get eveningBriefing => 'Iltakatsaus';

  @override
  String get appleUnusableAnswer =>
      'Apple Intelligence ei pystynyt tuottamaan käyttökelpoista vastausta: se toisti itseään tai tietojasi. Muotoile kysymys uudelleen tai valitse asetuksista toinen tekoälypalvelu.';

  @override
  String get appleCouldNotAnswer =>
      'Apple Intelligence ei pystynyt vastaamaan. Yritä uudelleen.';

  @override
  String get appleNotAvailableOnDevice =>
      'Apple Intelligence ei ole käytettävissä tällä laitteella.';

  @override
  String get appleLanguageRejected =>
      'Apple Intelligence hylkäsi pyynnön kielen. Kokeile lyhyttä kysymystä englanniksi. Tarkista myös iPhonen ja Sirin kieliasetukset.';

  @override
  String get appleRequestTooLarge =>
      'Apple Intelligence ei pystynyt käsittelemään pyyntöä. Kokeile lyhyempää kysymystä.';

  @override
  String get messageTooLongForApple =>
      'Tämä viesti on liian pitkä Apple Intelligencelle. Lyhennä sitä ja lähetä uudelleen.';

  @override
  String get vo2maxRunning => 'VO₂max juoksu';

  @override
  String get vo2maxCycling => 'VO₂max pyöräily';

  @override
  String get vo2maxPaceLabel => 'VO₂max-vauhti';

  @override
  String get lt1Threshold => 'LT1-kynnys';

  @override
  String get lt2Threshold => 'LT2-kynnys';

  @override
  String hoursPreviousWeek(Object value) {
    return '$value h edellisellä viikolla';
  }

  @override
  String kmPreviousWeek(Object value) {
    return '$value km edellisellä viikolla';
  }

  @override
  String get thirtyMinuteTimeTrial => '30 minuutin aika-ajo';

  @override
  String thirtyMinTtDate(Object date) {
    return '30 min TT · $date';
  }

  @override
  String get yesterday2 => 'EILEN';

  @override
  String get briefHeadGreen => 'Olet hyvin palautunut.';

  @override
  String get briefHeadYellow => 'Kuormitus on hieman koholla.';

  @override
  String get briefHeadRed => 'Olet selvästi kuormittunut.';

  @override
  String briefMain(Object reasons) {
    return 'Pääsyyt: $reasons.';
  }

  @override
  String get briefAllClear => 'Mikään arvoistasi ei näytä varoitusmerkkiä.';

  @override
  String get briefAdviceGreen => 'Harjoittele suunnitelman mukaan.';

  @override
  String get briefAdviceYellow => 'Pidä suunnitelma, mutta älä lisää tehoa.';

  @override
  String get briefAdviceRed => 'Palautuminen ensin: kevyt päivä tai lepo.';

  @override
  String get briefReasonHrvLow => 'matala unen HRV';

  @override
  String get briefReasonHrvHigh => 'korkea unen HRV';

  @override
  String get briefReasonRhrUp => 'koholla oleva leposyke';

  @override
  String get briefReasonRhrDown => 'matala leposyke';

  @override
  String get briefReasonSleepShort => 'liian vähän unta';

  @override
  String get briefReasonSleepGood => 'unentarve täyttyi';

  @override
  String get briefReasonEnergyLow => 'vähän energiaa';

  @override
  String get briefReasonEnergyHigh => 'hyvä energia';

  @override
  String get briefReasonStressHigh => 'korkea stressi';

  @override
  String get briefReasonRespHigh => 'kohonnut hengitystiheys';

  @override
  String get briefReasonSpo2Low => 'matala veren happi';

  @override
  String get briefReasonSkinTempOff => 'epätavallinen ihon lämpötila';

  @override
  String get briefReasonFormTired => 'kertynyt harjoitusväsymys';

  @override
  String get briefReasonFormVeryTired => 'erittäin suuri harjoitusväsymys';

  @override
  String get briefReasonFormFresh => 'virkeä ja levännyt';

  @override
  String get briefTrainingHrvUp =>
      'HRV:si nousi harjoituksen jälkeen, hyvä merkki.';

  @override
  String get briefTrainingHrvDown =>
      'HRV:si laski harjoituksen jälkeen, ei niin hyvä merkki.';

  @override
  String get reminderNeedsNotifications =>
      'Muistutus tarvitsee ilmoitukset. Salli ne Fjelialle järjestelmäasetuksissa ja ota muistutus sitten uudelleen käyttöön.';

  @override
  String get whatDidYouHave => 'Mitä nautit?';

  @override
  String get intakeSomething => 'Nautin jotain';

  @override
  String get intakeNothing => 'Ei mitään';

  @override
  String get totalIntake => 'Nautittu yhteensä';

  @override
  String get carbsLabel => 'Hiilihydraatit';

  @override
  String get fluidLabel => 'Neste';

  @override
  String get sodiumLabel => 'Natrium';

  @override
  String get caffeineLabel => 'Kofeiini';

  @override
  String get detailsOptional => 'Lisätiedot (valinnainen)';

  @override
  String atMinute(Object minute) {
    return 'minuutti $minute';
  }

  @override
  String get nothingAddedYet =>
      'Ei vielä mitään lisätty. Lisää, mitä söit tai join, tai valitse ”Ei mitään”.';

  @override
  String get followFocusWeek => 'Mihin minun pitäisi keskittyä tällä viikolla?';

  @override
  String get followRecoveryTrend => 'Miten palautumiseni kehittyy?';

  @override
  String get followLoadTooHigh => 'Onko harjoituskuormitukseni liian korkea?';

  @override
  String get followImproveSleep => 'Mikä parantaisi untani?';

  @override
  String get followIntervalsFeel => 'Miltä intervallien pitäisi tuntua?';

  @override
  String get followTiredToday => 'Entä jos tunnen itseni väsyneeksi tänään?';

  @override
  String get followEatBefore => 'Mitä minun pitäisi syödä sitä ennen?';

  @override
  String get followAdjustToday => 'Pitäisikö minun muokata sitä tänään?';

  @override
  String get followNextDays => 'Mitä se tarkoittaa seuraaville päivilleni?';

  @override
  String get followCompareSimilar =>
      'Miten se vertautuu samankaltaisiin harjoituksiin?';

  @override
  String get followRecover => 'Mitä minun pitäisi tehdä palautuakseni?';

  @override
  String get followIntensityRight => 'Oliko teho oikea?';

  @override
  String get statusPlanned => 'Suunniteltu';

  @override
  String get statusAdapted => 'Mukautettu';

  @override
  String get statusCompleted => 'Suoritettu';

  @override
  String get statusRest => 'Lepo';

  @override
  String loadValue(Object value) {
    return 'Kuormitus $value';
  }

  @override
  String get actIntensityEasy => 'Se oli kevyt aerobinen harjoitus.';

  @override
  String get actIntensityModerate => 'Se oli kohtalainen harjoitus.';

  @override
  String get actIntensityHard => 'Se oli rankka harjoitus.';

  @override
  String get actIntensityUnknown => 'Harjoitus on tallennettu.';

  @override
  String get actLenLonger =>
      'Se oli pidempi kuin samankaltaiset harjoituksesi.';

  @override
  String get actLenShorter =>
      'Se oli lyhyempi kuin samankaltaiset harjoituksesi.';

  @override
  String get actLoadHigher => 'Kuormitus oli tavallista suurempi.';

  @override
  String get actLoadLower => 'Kuormitus oli tavallista pienempi.';

  @override
  String get actLoadSame => 'Kuormitus oli suunnilleen tavallinen.';

  @override
  String get actHrLower =>
      'Sykkeesi oli tavallista matalampi, se tuntui kevyemmältä.';

  @override
  String get actHrHigher =>
      'Sykkeesi oli tavallista korkeampi, se tuntui raskaammalta.';

  @override
  String get actAdviceUnknown =>
      'Suunnittele seuraavat päivät sen mukaan, miltä tuntuu.';

  @override
  String briefOutlookRest(Object days) {
    return 'Noin $days kevyen päivän jälkeen kuntosi on taas optimaalisella alueella.';
  }

  @override
  String get briefOutlookLongRest =>
      'Kuntosi tarvitsee palautuakseen enemmän kuin muutaman kevyen päivän.';

  @override
  String get briefOutlookPlanTired =>
      'Jos noudatat suunnitelmaa, kuntosi pysyy matalana tulevina päivinä.';

  @override
  String get localQwen => 'Qwen3.5 · paikallinen';

  @override
  String get localModelDescription =>
      'Valinnainen Qwen3.5, 4-bittinen MLX. Lataa kerran ja käytä sitten keskustelua ja yhteenvetoja tällä laitteella ilman API-avainta. Terveystietosi pysyvät tällä laitteella.';

  @override
  String localModelSizeMb(Object megabytes) {
    return '$megabytes Mt:n lataus · käytön aikana tarvitaan lisämuistia.';
  }

  @override
  String get localModelDownload => 'Lataa malli';

  @override
  String get localModelResumeDownload => 'Jatka latausta';

  @override
  String localModelDownloading(Object downloaded, Object total) {
    return '$downloaded / $total Mt';
  }

  @override
  String get localModelInstalled =>
      'Ladattu · käytettävissä ilman verkkoyhteyttä';

  @override
  String get localModelRemove => 'Poista malli';

  @override
  String get localModelUnsupported =>
      'Tämä MLX-malli vaatii iPhonen, jossa on iOS 17 tai uudempi ja A14-siru tai uudempi. Vanhempia laitteita ei tueta.';

  @override
  String get localModelMemoryUnsupported =>
      'Tässä laitteessa ei ole tarpeeksi muistia paikallisen mallin suorittamiseen.';

  @override
  String get localModelDownloadFailed =>
      'Lataus epäonnistui. Yritä uudelleen; valmiit tiedostot säilytetään.';

  @override
  String get localModelDownloadFirst =>
      'Lataa ensin Qwen kohdasta Asetukset → Tekoäly ja muuta.';

  @override
  String get localModelContextTooLong =>
      'Tämä keskustelu on liian pitkä paikalliselle mallille. Aloita uusi keskustelu tai lyhennä kysymystä.';

  @override
  String get localModelBusy =>
      'Paikallinen malli vastaa toiseen pyyntöön. Yritä hetken kuluttua uudelleen.';

  @override
  String get localModelInterrupted =>
      'Paikallinen generointi keskeytyi. Pidä Fjelia auki ja yritä uudelleen.';

  @override
  String get localModelCouldNotAnswer =>
      'Paikallinen malli ei pystynyt vastaamaan. Tarkista malli kohdasta Asetukset → Tekoäly ja muuta ja yritä uudelleen.';

  @override
  String get localModelBriefingUnavailable =>
      'Paikallinen tekoäly-yhteenveto ei ole käytettävissä. Näytetään sovelluksen yhteenveto.';

  @override
  String get localModelInfo => 'Mallin tiedot ja lisenssi';

  @override
  String localModelRamGb(int gigabytes) {
    return 'Vaatii vähintään $gigabytes Gt keskusmuistia.';
  }

  @override
  String get localModelIPhone18 =>
      '4B on saatavilla iPhone 18:ssa ja uudemmissa malleissa.';

  @override
  String briefPlannedTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tänään on suunniteltu $count harjoitusta.',
      one: 'Tänään on suunniteltu 1 harjoitus.',
    );
    return '$_temp0';
  }

  @override
  String get coachDataFallback =>
      'Mallin vastaus on ristiriidassa tietojen kanssa. Tässä on Fjelian yhteenveto:';

  @override
  String get coachSevenDayAverage => '7 päivän keskiarvo';

  @override
  String coachSleepNeedAndShortfall(String need, String shortfall) {
    return 'Unentarve: $need h; univaje: $shortfall h.';
  }

  @override
  String coachCurrentForm(String value) {
    return 'Nykyinen vire (TSB): $value pistettä.';
  }

  @override
  String get aiOnboardingStep => 'Vaihe 2/3';

  @override
  String get aiOnboardingTitle => 'Valmentajasi.\nSinun tavallasi.';

  @override
  String get aiOnboardingSubtitle =>
      'Muuta terveystietosi vinkeiksi parempaan harjoitteluun ja palautumiseen.';

  @override
  String get aiOnboardingChoose => 'VALITSE TEKOÄLYVALMENTAJASI';

  @override
  String get aiOnboardingFreeDetail => 'Maksuton · Ei tekoälytiliä';

  @override
  String get aiOnboardingFreeBody =>
      'Pilvitekoäly harjoitteluun ja palautumiseen.';

  @override
  String get aiOnboardingRecommended => 'Suositeltu';

  @override
  String get aiOnboardingOnDevice => 'Omalla laitteellasi';

  @override
  String get aiOnboardingLocalBody =>
      'Tekoälypyyntösi pysyvät tällä laitteella.';

  @override
  String get aiOnboardingUnavailable => 'Ei tällä hetkellä saatavilla';

  @override
  String get aiOnboardingMore => 'Muut tekoälymallit';

  @override
  String get aiOnboardingMoreBody => 'Paikallinen Qwen tai oma pilvipalvelusi';

  @override
  String get aiOnboardingConsent => 'Pilvipyynnöt vasta vahvistuksesi jälkeen.';

  @override
  String get aiOnboardingError =>
      'Tekoälyvalintaa ei voitu tallentaa tai ladata. Yritä uudelleen.';

  @override
  String get aiOnboardingWithout => 'Jatka ilman tekoälyä';

  @override
  String get aiOnboardingConfigure => 'Määritä malli';

  @override
  String aiOnboardingContinue(String provider) {
    return 'Jatka: $provider';
  }

  @override
  String get aiOnboardingChangeLater =>
      'Voit muuttaa valintaa milloin tahansa asetuksissa.';

  @override
  String get creditsAndLicenses => 'Lisenssit ja kiitokset';

  @override
  String get bioAgeActivity => 'Liikunta';

  @override
  String get bioAgeActivityBasis => 'Liikuntatiedot · viimeiset 7 päivää';

  @override
  String bioAgeActivityReported(String minutes) {
    return '$minutes kirjattua kohtuukuormitteista minuuttia';
  }

  @override
  String bioAgeActivitySteps(String minutes) {
    return '≈ $minutes askelista arvioitua kävelyminuuttia';
  }

  @override
  String bioAgeActivityCoverage(int days) {
    return 'Tiedot $days päivältä seitsemästä';
  }

  @override
  String get bioAgeActivityEstimateNotice =>
      'Oletus: 100 askelta ≈ 1 kävelyminuutti. Päivittäinen askelmäärä ei kerro vauhtia tai kuormittavuutta. Kirjatut minuutit ovat etusijalla joka päivä; saman päivän askelia ei lasketa lisäksi.';

  @override
  String get bioAgeActivityIncomplete =>
      'Liikuntatietoja puuttuu. Liikunnan vaikutus vuosina lasketaan vasta, kun kaikilta 7 päivältä on tietoja.';

  @override
  String get bioAgeActivityEstimatedLabel =>
      'Liikunta sisältää arvioitua kävelyaikaa.';

  @override
  String get bioAgeActivityUnknownLabel => 'Liikuntatiedot ovat puutteelliset';

  @override
  String get mixTitle => 'Sekoita juoma';

  @override
  String get mixMyBottle => 'Sekoita pulloni';

  @override
  String get mixRecipes => 'Reseptit';

  @override
  String get mixIngredients => 'Ainekset';

  @override
  String get mixAddIngredient => 'Lisää aines';

  @override
  String get mixBottle => 'Pullo';

  @override
  String get mixFilledWithWater => 'täytetty vedellä';

  @override
  String mixPerBottle(String ml) {
    return '$ml ml:n pulloa kohden';
  }

  @override
  String get mixStrength => 'Vahvuus';

  @override
  String get mixRatio => 'Glukoosi : fruktoosi';

  @override
  String get mixGlucose => 'Glukoosi';

  @override
  String get mixFructose => 'Fruktoosi';

  @override
  String get mixGlucoseOnly => 'Vain glukoosia';

  @override
  String get mixGentle => 'Hellävarainen vatsalle – enintään 8 %.';

  @override
  String get mixStrong => 'Väkevä – vain harjoitetulle vatsalle.';

  @override
  String get mixTooStrong => 'Hyvin väkevä – lisää vettä.';

  @override
  String get mixNoFructoseHint =>
      'Vain glukoosia: yli noin 60 g hiilihydraattia tunnissa lisää fruktoosia (sokeria) – noin 2:1 imeytyy paremmin.';

  @override
  String get mixFructoseHeavyHint =>
      'Enemmän fruktoosia kuin glukoosia voi ärsyttää vatsaa – lisää maltodekstriiniä tai rypälesokeria.';

  @override
  String get mixSpoonNote =>
      'Lusikat vaihtelevat. Punnitse lusikkasi kerran tai käytä grammoja tarkkoihin arvoihin.';

  @override
  String get mixTooMuchLiquid =>
      'Mehu ja kola yksinään ylittävät jo pullon koon – suurenna pulloa.';

  @override
  String get mixAddToIntake => 'Lisää nautittuihin';

  @override
  String get mixUseAsBottle => 'Käytä pullonani';

  @override
  String get mixDefaultName => 'Juomasekoitus';

  @override
  String get mixEmpty => 'Valitse resepti tai lisää aines.';

  @override
  String get mixRemove => 'Poista';

  @override
  String mixRowGrams(String grams) {
    return '≈ $grams g';
  }

  @override
  String mixBottleSaved(String carbs, String ml) {
    return 'Tallennettu pulloksesi: $carbs g hiilihydraattia / $ml ml.';
  }

  @override
  String get mixMaltodextrin => 'Maltodekstriini';

  @override
  String get mixSugar => 'Sokeri';

  @override
  String get mixDextrose => 'Rypälesokeri';

  @override
  String get mixHoney => 'Hunaja';

  @override
  String get mixSalt => 'Suola';

  @override
  String get mixOrangeJuice => 'Appelsiinimehu';

  @override
  String get mixAppleJuice => 'Omenamehu';

  @override
  String get mixCola => 'Kola';

  @override
  String get unitTspLevel => 'tasainen tl';

  @override
  String get unitTspHeaped => 'kukkurainen tl';

  @override
  String get unitTbspLevel => 'tasainen rkl';

  @override
  String get unitTbspHeaped => 'kukkurainen rkl';

  @override
  String get unitPinch => 'hyppysellinen';

  @override
  String get unitTsp => 'tl';

  @override
  String get unitTbsp => 'rkl';

  @override
  String get mixRecipeMaltoSugar => 'Malto + sokeri 2:1';

  @override
  String get mixRecipeJuice => 'Laimennettu mehu';

  @override
  String get mixRecipeJuicePlus => 'Laimennettu mehu + malto';

  @override
  String get mixRecipeCola => 'Laimennettu kola';

  @override
  String get missedWorkoutTitle => 'Vielä tämän päivän suunnitelmassa';

  @override
  String missedWorkoutBody(String workouts) {
    return '$workouts. Vielä tänään, siirretäänkö vai ohitetaanko?';
  }

  @override
  String get stillToday => 'Vielä tänään';

  @override
  String get moveWorkoutAction => 'Siirrä…';

  @override
  String get missedWorkoutChannel => 'Väliin jääneet harjoitukset';

  @override
  String get missedWorkoutChannelDescription =>
      'Iltamuistutus suunnitelluista harjoituksista, jotka ovat vielä tekemättä';

  @override
  String get missedWorkoutReminder =>
      'Muistutus väliin jääneestä harjoituksesta';

  @override
  String get missedWorkoutReminderSubtitle =>
      'Illalla, jos suunniteltu harjoitus on vielä tekemättä';

  @override
  String get moveWithinDays => 'Siirrä enintään';

  @override
  String daysN(int count) {
    return '$count päivää';
  }

  @override
  String get notificationsAreOff =>
      'Fjelian ilmoitukset ovat pois päältä. Salli ne saadaksesi tämän muistutuksen.';

  @override
  String get allowNotifications => 'Salli ilmoitukset';

  @override
  String get openWorkoutToday => 'Vielä tekemättä tänään';

  @override
  String get checkingForWorkout => 'Etsitään harjoitustasi…';

  @override
  String get alreadyDone => 'Jo tehty ✓';

  @override
  String get alreadyDoneBody =>
      'Harjoituksesi on tallennettu. Tänään ei ole enää mitään tehtävää.';

  @override
  String get dropIt => 'Jätä väliin';

  @override
  String askCoachSends(String provider) {
    return 'Lähettää harjoitusyhteenvetosi palveluun $provider.';
  }

  @override
  String get coachThinking => 'Valmentaja miettii…';

  @override
  String get coachCouldNotAnswer =>
      'Valmentaja ei voinut vastata. Yllä oleva ehdotus on yhä voimassa.';

  @override
  String get whySkip => 'Miksi ohitat?';

  @override
  String get skipReasonIllness => 'Sairaus';

  @override
  String get skipReasonInjury => 'Vamma tai kipu';

  @override
  String get skipReasonFatigue => 'Väsymys';

  @override
  String get skipReasonNoTime => 'Ei aikaa';

  @override
  String get skipReasonTravel => 'Matka';

  @override
  String get skipReasonConditions => 'Olosuhteet';

  @override
  String get skipReasonMyChoice => 'Oma valinta';

  @override
  String get onbReminderTitle => 'Pysy suunnitelmassa';

  @override
  String get onbReminderSubtitle =>
      'Jos suunniteltu harjoitus on illalla vielä tekemättä, Fjelia muistuttaa kerran, jotta voit vielä tehdä sen, siirtää sen tai ohittaa sen.';

  @override
  String get onbExampleWorkout => 'Kevyt lenkki (45 min)';

  @override
  String get onbReminderToggle => 'Iltamuistutus';

  @override
  String get onbReminderTime => 'Muistuta klo';

  @override
  String get onbReminderFootnote =>
      'Voit muuttaa tätä milloin tahansa kohdassa Asetukset → Harjoittelu.';

  @override
  String get nowLabel => 'nyt';

  @override
  String get coachSuggests => 'Valmentaja ehdottaa';

  @override
  String get suggestionLabel => 'Ehdotus';

  @override
  String get askCoachShort => 'Kysy valmentajalta';

  @override
  String get otherDay => 'Toinen päivä';

  @override
  String get skipEllipsis => 'Ohita…';

  @override
  String get pickADay => 'Napauta päivää yllä';

  @override
  String get dayDoesNotFit => 'Se päivä ei sovi suunnitelmaan.';

  @override
  String get planUpdated => 'Suunnitelma päivitetty';

  @override
  String get missedTodayTag => 'jäi tänään väliin';

  @override
  String summaryMove(String day) {
    return 'Siirrä se päivälle $day.';
  }

  @override
  String summaryMoveIndoor(String day) {
    return 'Siirrä se päivälle $day sisätiloihin – sadetta on luvassa.';
  }

  @override
  String get summaryDropEasy =>
      'Jätä väliin – kevyttä harjoitusta ei kannata korvata.';

  @override
  String summaryDropNoDay(int days) {
    return 'Jätä väliin – seuraavien $days päivän aikana mikään päivä ei sovi.';
  }

  @override
  String get tagIndoor => 'sisällä';

  @override
  String get tagEasier => 'kevyempi';

  @override
  String get tagRecovery => 'palautus';

  @override
  String summaryMoveEasier(String day) {
    return 'Siirrä se päivälle $day hieman kevyempänä – vieressä on kova päivä.';
  }

  @override
  String get briefRestDayToday => 'Tänään on suunniteltu lepopäivä.';

  @override
  String get restDayPlannedNote => 'Palautuminen kuuluu suunnitelmaasi.';

  @override
  String get restDayTitle => 'Lepopäivä';

  @override
  String get importActivityFile => 'Tuo aktiviteettitiedosto';

  @override
  String get activityFileImportHint =>
      'FIT-, GPX- tai TCX-tiedostot (myös ZIP-pakattuina, kuten Garmin Connect ne vie) pyörätietokoneesta, Zwiftistä, Stravasta tai muusta sovelluksesta. Voit myös jakaa tiedoston Fjeliaan Tiedostot-sovelluksesta tai jakovalikosta.';

  @override
  String get chooseActivityFiles => 'Valitse tiedostot';

  @override
  String get chooseOtherFiles => 'Valitse muut tiedostot';

  @override
  String get activityFileUnreadable => 'Ei luettava aktiviteettitiedosto';

  @override
  String get activityFileAlreadyImported => 'Tuotu jo';

  @override
  String activityFileAlreadyFrom(String source) {
    return 'Jo Fjeliassa lähteestä $source';
  }

  @override
  String importActivities(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tuo $count aktiviteettia',
      one: 'Tuo $count aktiviteetti',
    );
    return '$_temp0';
  }

  @override
  String activitiesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktiviteettia tuotu.',
      one: '$count aktiviteetti tuotu.',
    );
    return '$_temp0';
  }

  @override
  String get activityFileSource => 'Tiedosto';

  @override
  String get dfaAlpha1Title => 'Aerobinen kynnys (DFA α1)';

  @override
  String get dfaHrvt1 => 'Aerobinen kynnys (HRVT1)';

  @override
  String get dfaHrvt2 => 'Anaerobinen kynnys (HRVT2)';

  @override
  String dfaEasyShare(String percent) {
    return '$percent % harjoituksesta aerobisen kynnyksesi alapuolella (α1 ≥ 0,75).';
  }

  @override
  String get dfaNoThreshold =>
      'Harjoitus ei ylittänyt kynnystä selvästi. Portaittainen testi tai harjoitus, joka kiristyy kevyestä kovaan, antaa arvion.';

  @override
  String dfaBeats(int beats, String artifacts) {
    return '$beats lyöntiä · $artifacts % artefakteja';
  }

  @override
  String get dfaArtifactsHigh =>
      'Paljon artefakteja: tarkista, että sykevyö istuu tiukasti ja elektrodit ovat kosteat.';

  @override
  String get dfaExplainer =>
      'Sykevyön lyönti lyönniltä -datasta. α1 lähellä 1:tä on kevyttä, 0,75 merkitsee aerobista kynnystä ja 0,5 anaerobista. Arvio, ei laboratoriotesti.';

  @override
  String get thresholdOrderNote =>
      'Fjelia vertaa kaikkia lähteitä. Ensin se ehdottaa sovelluksen omia testejä, sitten kelloasi, sitten useamman harjoituksen DFA α1:tä ja lopuksi Polar-profiilia ja kaavoja. Mikään ei muutu ennen kuin otat sen käyttöön.';

  @override
  String thresholdInUse(String value) {
    return 'Käytössä: $value';
  }

  @override
  String thresholdProposal(String value, String source) {
    return 'Ehdotus: $value lähteestä $source';
  }

  @override
  String get keepCurrent => 'Pidä nykyinen';

  @override
  String get lt2Cycling => 'LT2 · Pyöräily';

  @override
  String get thresholdSourceTt => '30 minuutin aika-ajo';

  @override
  String get thresholdSourceDrift => 'Sykedriftitesti';

  @override
  String thresholdSourceDfa(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DFA α1, $count harjoitusta',
      one: 'DFA α1, $count harjoitus',
    );
    return '$_temp0';
  }

  @override
  String get thresholdSourceEftp => 'eFTP pyörälenkeistä';

  @override
  String get thresholdSourcePolarProfile => 'Polar-profiili';

  @override
  String get thresholdFormulaLt2 => 'LT2 − 30 bpm';

  @override
  String get thresholdFormulaMaxHr => '77 % maksimisykkeestä';

  @override
  String get thresholdStale => 'yli 6 kuukautta vanha';

  @override
  String get thresholdsCoachLocked =>
      'Valmentajasi hallitsee kynnyksiäsi, joten niitä ei voi muuttaa täällä.';

  @override
  String get mediaTitle => 'Kuvat ja videot';

  @override
  String get mediaAdd => 'Lisää';

  @override
  String get mediaFromLibrary => 'Valitse kirjastosta';

  @override
  String get mediaTakePhoto => 'Ota kuva';

  @override
  String get mediaRecordVideo => 'Kuvaa video';

  @override
  String mediaAdding(int done, int total) {
    return 'Lisätään $done/$total…';
  }

  @override
  String get mediaMoveEarlier => 'Siirrä aiemmaksi';

  @override
  String get mediaMoveLater => 'Siirrä myöhemmäksi';

  @override
  String get mediaDeleteTitle => 'Poistetaanko Fjeliasta?';

  @override
  String get mediaDeleteMessage =>
      'Kuva tai video poistetaan Fjeliasta. Alkuperäinen jää kuvakirjastoosi.';

  @override
  String get mediaAddFailed => 'Joitakin tiedostoja ei voitu lisätä.';

  @override
  String get mediaHint =>
      'Napauta katsoaksesi, pidä painettuna siirtääksesi tai poistaaksesi.';

  @override
  String get backupVideosTitle => 'Otetaanko videot mukaan?';

  @override
  String backupVideosMessage(String size) {
    return 'Videosi vievät $size. Ilman niitä varmuuskopio on paljon pienempi; kuvat ovat aina mukana.';
  }

  @override
  String get backupWithVideos => 'Videoiden kanssa';

  @override
  String get backupWithoutVideos => 'Ilman videoita';

  @override
  String get mediaShareCard => 'Jaa korttina';

  @override
  String get mediaShareCardHint =>
      'Siirrä paneelia tai reittiä vetämällä. Nipistä ja vedä kuvaa rajataksesi sen; kaksoisnapautus palauttaa.';

  @override
  String get shareGymPhoto => 'Kuntosalikuva';

  @override
  String get shareWithoutPhoto => 'Ilman kuvaa';

  @override
  String get shareStyleGlass => 'Lasi';

  @override
  String get shareStylePoster => 'Juliste';

  @override
  String get shareStyleMinimal => 'Minimal';

  @override
  String get shareStyleNeon => 'Neon';

  @override
  String get shareStyleSticker => 'Tarra';

  @override
  String get shareStyleReceipt => 'Kuitti';

  @override
  String get shareStyleKpop => 'K-pop';

  @override
  String get shareStylePixel => 'Pikseli';

  @override
  String get shareStyleRobot => 'Robotti';

  @override
  String get shareStyleScifi => 'Sci-fi';

  @override
  String get shareStyleCard => 'Keräilykortti';

  @override
  String get shareStyleComic => 'Sarjakuva';

  @override
  String get shareStyleOutdoor => 'Retkeily';

  @override
  String get shareStyleHolo => 'Holokortti';

  @override
  String get shareStyleHoloFull => 'Kokokuvakortti';

  @override
  String nowcastRainSoon(int minutes) {
    return 'Sadetta noin $minutes min päästä';
  }

  @override
  String nowcastRainingStops(int minutes) {
    return 'Sataa · poutaa noin $minutes min päästä';
  }

  @override
  String nowcastRainingOn(int minutes) {
    return 'Sataa, vielä vähintään $minutes min';
  }

  @override
  String nowcastDry(int minutes) {
    return 'Poutaa seuraavat $minutes min';
  }

  @override
  String get sunAndMoon => 'Aurinko ja kuu';

  @override
  String get moonNew => 'Uusikuu';

  @override
  String get moonWaxingCrescent => 'Kasvava sirppi';

  @override
  String get moonFirstQuarter => 'Ensimmäinen neljännes';

  @override
  String get moonWaxingGibbous => 'Kasvava kuu';

  @override
  String get moonFull => 'Täysikuu';

  @override
  String get moonWaningGibbous => 'Vähenevä kuu';

  @override
  String get moonLastQuarter => 'Viimeinen neljännes';

  @override
  String get moonWaningCrescent => 'Vähenevä sirppi';

  @override
  String moonLit(int percent) {
    return '$percent % valaistu';
  }

  @override
  String daylightLength(int hours, int minutes) {
    return '$hours h $minutes min päivänvaloa';
  }

  @override
  String h10Battery(int level) {
    return 'Akku $level %';
  }

  @override
  String get h10BatteryUnknown => 'Akkua ei ole vielä luettu';

  @override
  String h10BatteryChecked(String date) {
    return 'Tarkistettu $date';
  }

  @override
  String get h10BatteryLowHint => 'Heikko: vaihda CR2025-nappiparisto pian.';

  @override
  String get h10BatteryCheck => 'Tarkista akku';

  @override
  String get h10BatteryUnreachable =>
      'H10 ei vastannut. Pue se päälle (tai kostuta kontaktit) ja yritä uudelleen.';

  @override
  String get shareRaceCalendar => 'Jaa kilpailukalenteri';

  @override
  String get raceSeasonTitle => 'Kilpailukauteni';

  @override
  String get raceShareStylePoster => 'Juliste';

  @override
  String get raceShareStyleTickets => 'Liput';

  @override
  String get raceShareStyleTimeline => 'Neon-aikajana';

  @override
  String get raceShareStyleMagazine => 'Lehti';

  @override
  String get raceShareShowTarget => 'Näytä tavoiteajat';

  @override
  String get bpOptimal => 'OPTIMAALINEN';

  @override
  String get bpHighNormal => 'KOHONNUT NORMAALI';

  @override
  String get bpLow => 'MATALA';

  @override
  String get bpLowHint =>
      'Matala verenpaine: merkitsee vain, jos sinua huimaa.';

  @override
  String get waistCircumference => 'Vyötärönympärys';

  @override
  String get hipOptional => 'Lantio (valinnainen)';

  @override
  String get waistToHeightRatio => 'Vyötärö-pituussuhde';

  @override
  String get waistToHipRatio => 'Vyötärö-lantiosuhde';

  @override
  String get waistRiskLow => 'Hyvin hoikka';

  @override
  String get waistRiskHealthy => 'Terve';

  @override
  String get waistRiskIncreased => 'Kohonnut riski';

  @override
  String get waistRiskHigh => 'Korkea riski';

  @override
  String get waistHowToMeasure =>
      'Mittaa aamulla seisten uloshengityksen jälkeen: vyötärö alimman kylkiluun ja lonkkaluun yläreunan puolivälistä, lantio leveimmästä kohdasta.';

  @override
  String get waistNeedsHeight =>
      'Lisää pituutesi kohdassa Asetukset → Profiili.';

  @override
  String get waistNeedsHip => 'Mittaa lantiosi kerran WHR:ää varten.';

  @override
  String get waistSyncsProfile =>
      'Uusin mittaus on myös vyötärösi asetuksissa.';

  @override
  String get waistChange30d => '30 päivää';

  @override
  String get waistChange90d => '90 päivää';

  @override
  String get waistChange1y => '1 vuosi';

  @override
  String get waistDeleteText => 'Tämä poistaa valitun vyötärömittauksen.';

  @override
  String waistAndHip(String waist, String hip) {
    return '$waist cm · lantio $hip cm';
  }

  @override
  String hipValue(String hip) {
    return 'Lantio $hip cm';
  }

  @override
  String get whtrTargetHint => 'Pidä vyötärösi alle puolet pituudestasi.';

  @override
  String get noWaistYet => 'Vyötäröä ei ole vielä mitattu.';

  @override
  String get enterValidWaist => 'Anna vyötärö ja lantio väliltä 20–300 cm.';

  @override
  String get waistFromProfile => 'Profiilistasi, ilman päivämäärää';

  @override
  String get phaseBase => 'PERUSKAUSI';

  @override
  String get phaseBuild => 'NOUSU';

  @override
  String get phasePeak => 'HUIPPU';

  @override
  String get phaseTaper => 'KEVENNYS';

  @override
  String get phaseRecovery => 'PALAUTUMINEN';

  @override
  String get phaseRace => 'KILPAILU';

  @override
  String get sessionTypeKey => 'AVAIN';

  @override
  String get sessionTypeLong => 'PITKÄ';

  @override
  String get sessionTypeRecovery => 'PALAUTTAVA';

  @override
  String get sessionTypeAssessment => 'TESTI';

  @override
  String get sessionTypeEndurance => 'KESTÄVYYS';

  @override
  String get sessionTypeStrength => 'VOIMA';

  @override
  String get sessionTypeYoga => 'JOOGA';

  @override
  String get sessionStatusCompleted => 'TEHTY';

  @override
  String get sessionStatusAdapted => 'MUOKATTU';

  @override
  String get stepWarmUp => 'Lämmittely';

  @override
  String get stepCoolDown => 'Jäähdyttely';

  @override
  String get stepRecovery => 'Palautus';

  @override
  String get stepRest => 'Lepo';

  @override
  String get stepInterval => 'Intervalli';

  @override
  String get stepWorkout => 'Harjoitus';

  @override
  String stepRepeat(int n) {
    return '$n× toista';
  }

  @override
  String get stepOpenEnded => 'Avoin';

  @override
  String stepSeconds(int n) {
    return '$n s';
  }

  @override
  String get objectiveOptionalVariety => 'Valinnainen vaihtelu asetuksistasi';

  @override
  String get objectiveStrengthSupport => 'Voimaa harjoittelusi tueksi';

  @override
  String objectiveIntervals(String goal) {
    return 'Intervallit: $goal';
  }

  @override
  String objectiveSteady(String sport, String goal) {
    return '$sport: tasainen laatuharjoitus, $goal';
  }

  @override
  String objectiveEasyRecovery(String sport, String goal) {
    return 'Kevyt $sport: palautuminen, $goal';
  }

  @override
  String objectiveEasyEndurance(String sport, String goal) {
    return '$sport: kevyt kestävyys, $goal';
  }

  @override
  String objectiveLong(String sport, String goal) {
    return '$sport: pitkä harjoitus, $goal';
  }

  @override
  String unmetWeekMinutes(int minutes, String sport, String goal) {
    return 'Viikossa on $minutes min, liian vähän pitkään harjoitukseen ($sport), $goal.';
  }

  @override
  String unmetWeekHours(String hours, String what) {
    return 'Viikossa on $hours h, liian vähän: $what.';
  }

  @override
  String unmetTrainingDays(String what) {
    return 'Harjoituspäivät eivät riitä: $what.';
  }

  @override
  String get altMoveOneEvent => 'Siirrä toista tapahtumista';

  @override
  String get altMarkOneCancelled => 'Merkitse toinen perutuksi';

  @override
  String altMakePriorityB(String goal) {
    return 'Aseta $goal prioriteetiksi B';
  }

  @override
  String altSkipGoal(String goal) {
    return 'Jätä $goal väliin';
  }

  @override
  String altTreatAsTraining(String goal) {
    return 'Pidä $goal harjoituskilpailuna';
  }

  @override
  String altControlledEffort(String goal) {
    return 'Suorita $goal hallitulla teholla';
  }

  @override
  String conflictSameDay(String a, String b) {
    return '$a ja $b ovat samana päivänä. Vain toiseen voi osallistua.';
  }

  @override
  String conflictBothPriorityA(String a, String b, int gap, int more) {
    return '$a ja $b ovat molemmat prioriteettia A, $gap päivän välein. Palautuminen ensimmäisestä ja virittäytyminen toiseen vaativat $more päivää enemmän.';
  }

  @override
  String conflictFlexibleOverlap(
    String a,
    String b,
    int gap,
    int overlap,
    String skip,
  ) {
    return '$a ja $b ovat $gap päivän välein ja menevät päällekkäin $overlap päivää. $skip on merkitty joustavaksi: sen pois jättäminen vapauttaisi toista tapahtumaa edeltävät viikot.';
  }

  @override
  String conflictRecoveryOverlap(String a, String b, int gap, int overlap) {
    return '$a ja $b ovat $gap päivän välein: palautuminen ensimmäisestä menee $overlap päivää päällekkäin toiseen virittäytymisen kanssa. Matalamman prioriteetin valmistautumista rajoitetaan toisen suojaamiseksi.';
  }

  @override
  String conflictTightSpacing(String a, String b, int gap, int spare) {
    return '$a ja $b ovat $gap päivän välein. Palautuminen ja virittäytyminen mahtuvat $spare päivän varalla, joten takaisku ei jätä liikkumavaraa.';
  }

  @override
  String seasonShortened(int n, int of) {
    return '$n/$of viikolla viikon aika ei riitä jokaisen tavoitteen täysiin pitkiin harjoituksiin, joten niitä lyhennetään yhdessä.';
  }

  @override
  String seasonAlternating(int n) {
    return '$n viikolla kaikki pitkät harjoitukset eivät mahdu viikkoon; lajit vuorottelevat.';
  }

  @override
  String seasonLongAway(int n) {
    return '$n viikolla yli kahden ja puolen tunnin pitkä harjoitus on muuna kuin tavallisena päivänään lepopäiviesi ja muiden harjoitusten vuoksi.';
  }

  @override
  String seasonMovedOntoEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n siirtämääsi harjoitusta on tapahtumapäivänä tai sitä edeltävänä lepopäivänä. Suunnitelma jättää ne siihen, mihin ne laitoit.',
      one: '1 siirtämäsi harjoitus on tapahtumapäivänä tai sitä edeltävänä lepopäivänä. Suunnitelma jättää sen siihen, mihin sen laitoit.',
    );
    return '$_temp0';
  }

  @override
  String seasonNoRoom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n harjoitusta jätettiin pois, koska valitut harjoitukset olivat pidempiä kuin viikolle jäänyt aika.',
      one: '1 harjoitus jätettiin pois, koska valittu harjoitus oli pidempi kuin viikolle jäänyt aika.',
    );
    return '$_temp0';
  }

  @override
  String seasonMovedHardNearEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n siirtämääsi kovaa harjoitusta on tapahtuman jälkeisinä kevyinä päivinä. Suunnitelma jättää ne siihen, mihin ne laitoit.',
      one: '1 siirtämäsi kova harjoitus on tapahtuman jälkeisinä kevyinä päivinä. Suunnitelma jättää sen siihen, mihin sen laitoit.',
    );
    return '$_temp0';
  }

  @override
  String get seasonEventWeeks =>
      'Tapahtumaviikoilla tapahtuma lasketaan harjoitukseksi, joten muu viikko on kevyempi.';

  @override
  String seasonUnmet(int n, String detail) {
    return '$n viikolla harjoituspäiviin eivät mahdu kaikki suojatut harjoitukset: $detail';
  }

  @override
  String seasonNoHistory(String sport, String priority) {
    return 'Historiassasi ei ole viimeaikaista harjoittelua ($sport), joten $priority-tavoitteen suunnitelma on alustava.';
  }

  @override
  String get zoneRecovery => 'Palauttava';

  @override
  String workoutSentKeptInFjelia(String provider, String items) {
    return 'Lähetetty: $provider. Vain Fjeliassa: $items.';
  }

  @override
  String paceGuideRange(String low, String high) {
    return 'Vauhtiohje $low–$high';
  }

  @override
  String get paceGuideFromGoal => ', arvioitu tavoitteestasi';

  @override
  String paceGuideGoalFlat(String pace) {
    return ' · tavoitevauhti tasaisella $pace';
  }

  @override
  String get paceGuideHeartRateDecides => 'Syke ratkaisee.';

  @override
  String get moveKeyRestDay => 'lepopäivä';

  @override
  String get moveKeyEvent => 'tapahtuma';

  @override
  String get moveKeyEasyOnly => 'vain kevyt';

  @override
  String get moveKeyHasSession => 'harjoitus';

  @override
  String get calendarCompleted => 'Tehty';

  @override
  String get calendarPlanned => 'Suunniteltu';

  @override
  String get recentlyDeleted => 'Äskettäin poistetut';

  @override
  String get recentlyDeletedExplain =>
      'Poistetut aktiviteetit pysyvät poistettuina, myös kun laitteesi synkronoivat uudelleen. Palauta aktiviteetti saadaksesi sen takaisin; sen lähde lähettää reitin ja käyrät uudelleen, jos sillä on ne vielä.';

  @override
  String get noDeletedActivities => 'Ei poistettuja aktiviteetteja.';

  @override
  String activityDeleted(String name) {
    return '$name poistettu';
  }

  @override
  String activityRestored(String name) {
    return '$name palautettu';
  }

  @override
  String activityRestoredSummaryOnly(String name) {
    return '$name palautettu kokonaisarvoineen; lähde ei enää lähetä reittiä eikä käyriä.';
  }

  @override
  String deletedOn(String date) {
    return 'poistettu $date';
  }

  @override
  String get restore => 'Palauta';

  @override
  String get coachWhyThisToday => 'Miksi tämä harjoitus tänään?';

  @override
  String get coachHowDidItGo => 'Miten tämä harjoitus meni?';

  @override
  String get coachWhyRestDay => 'Miksi tämä on lepopäivä?';

  @override
  String get coachWhatInstead => 'Mitä minun pitäisi tehdä sen sijaan?';

  @override
  String get newChat => 'Uusi keskustelu';

  @override
  String weekOfPlanned(String duration) {
    return '/ $duration suunniteltu';
  }

  @override
  String get weekDoneNothingPlanned => 'tehty · ei suunniteltuja harjoituksia';

  @override
  String sessionDropped(String reason, String duration) {
    return '$reason · $duration jäi pois';
  }

  @override
  String get importTitle => 'Tuo';

  @override
  String get stravaArchive => 'Strava-arkisto';

  @override
  String get stravaArchiveZip => 'Strava-arkisto (ZIP)';

  @override
  String get stravaArchiveSubtitle =>
      'Koko Strava-historiasi reitteineen ja kuvineen';

  @override
  String get stravaIntro =>
      'Tuo koko Strava-historiasi Fjeliaan: aktiviteetit reitin, sykkeen ja tehon kera sekä niiden kuvat.';

  @override
  String get stravaHowTo =>
      'Strava.comissa: Asetukset → Oma tili → Lataa tai poista tilisi → Pyydä arkisto. Strava lähettää ZIP-tiedoston sähköpostilla; valitse se tässä sellaisenaan purkamatta.';

  @override
  String get stravaChooseZip => 'Valitse ZIP';

  @override
  String get stravaReading => 'Luetaan arkistoa…';

  @override
  String get stravaNotArchive =>
      'Tämä ZIP ei ole Strava-tilin arkisto: activities.csv puuttuu.';

  @override
  String stravaFound(int count) {
    return '$count aktiviteettia löytyi';
  }

  @override
  String stravaWithFiles(int count) {
    return '$count tallenteella (reitti ja käyrät)';
  }

  @override
  String stravaPhotos(int photos, int videos) {
    return '$photos kuvaa, $videos videota';
  }

  @override
  String stravaAlready(int count) {
    return '$count kaksoiskappaletta, jo Fjeliassa tai kahdesti Stravassa: vain puuttuvat kuvat lisätään';
  }

  @override
  String stravaDeletedSkip(int count) {
    return '$count poistettu aiemmin, ohitetaan';
  }

  @override
  String stravaNew(int count) {
    return '$count uutta';
  }

  @override
  String stravaStorage(int mb) {
    return 'noin $mb Mt kuville ja videoille';
  }

  @override
  String get stravaPrivacy =>
      'Kaikki luetaan tällä laitteella. Mitään ei ladata palvelimelle, eikä Strava-kirjautumista tarvita.';

  @override
  String stravaImportButton(int count) {
    return 'Tuo $count aktiviteettia';
  }

  @override
  String get stravaImporting => 'Tuodaan Strava-arkistoa';

  @override
  String stravaProgressActivities(String done, String total) {
    return 'Aktiviteetit: $done / $total';
  }

  @override
  String stravaImportedCount(int count) {
    return '$count aktiviteettia tuotu';
  }

  @override
  String stravaProgressPhotos(int count) {
    return 'Kuvat: $count tuotu';
  }

  @override
  String stravaProgressDuplicates(int count) {
    return 'Kaksoiskappaleet: $count ohitettu';
  }

  @override
  String stravaProgressDeleted(int count) {
    return 'Aiemmin poistetut: $count ohitettu';
  }

  @override
  String stravaProgressErrors(int count) {
    return 'Virheet: $count';
  }

  @override
  String get stravaKeepOpen =>
      'Voit käyttää sovellusta sillä välin. Pidä Fjelia auki, kunnes tuonti on valmis.';

  @override
  String get stravaComplete => 'Strava-tuonti valmis';

  @override
  String get stravaPartial => 'Strava-tuonti keskeneräinen';

  @override
  String get stravaCancelled => 'Strava-tuonti peruttu';

  @override
  String get stravaShowErrors => 'Näytä virheet';

  @override
  String get stravaAgainHint =>
      'Saman arkiston tuominen uudelleen lisää vain sen, mikä vielä puuttuu.';

  @override
  String get renameActivity => 'Nimeä aktiviteetti uudelleen';

  @override
  String get activityTitleLabel => 'Otsikko';

  @override
  String get activityTitleKept =>
      'Otsikkosi säilyy, kun aktiviteetti synkronoidaan uudelleen. Se muuttuu vain Fjeliassa, ei alkuperäisessä palvelussa.';

  @override
  String originalTitle(String name) {
    return 'Alkuperäinen: $name';
  }

  @override
  String get useOriginalTitle => 'Käytä alkuperäistä otsikkoa';

  @override
  String get loadOlderActivities => 'Lataa vanhempia aktiviteetteja';

  @override
  String get noOlderActivities => 'Ei vanhempia aktiviteetteja';

  @override
  String get maxSpeed => 'Huippunopeus';

  @override
  String get caloriesLabel => 'Kalorit';

  @override
  String get activityDescription => 'Kuvaus';

  @override
  String get nightCurves => 'Yön käyrät';

  @override
  String get noPhaseTimeline =>
      'Tämä kello ei kerro, milloin kukin univaihe oli, vain yllä olevat summat. Nämä ovat yön aikana mitatut HRV ja stressi.';

  @override
  String get stagesEstimated =>
      'Fjelian arvio COROS-kellosi yöllä mittaamasta HRV:stä ja stressistä. Vaiheiden summat ovat COROSin omat; milloin kukin vaihe oli, on likiarvo.';

  @override
  String get nightCurvesBasis =>
      'Yön aikana mitattu HRV ja stressi. Yllä oleva vaihearvio perustuu niihin.';

  @override
  String get swimShort =>
      'Vesi riittää yleensä. Geelejä ei tarvita: tavallinen ateria ennen ja jälkeen riittää tähän uintiin.';

  @override
  String get swimPoolLong =>
      'Ota hiilihydraattipitoista juomaa sarjojen pidemmillä tauoilla, varsinkin jos harjoitus on kova. Altaalla geelejä ei tarvita.';

  @override
  String get swimOpenFeeds =>
      'Suunnittele hiilihydraatit ja nesteet tankkausmahdollisuuksien mukaan (vene, kajakki, ranta). Älä luota ravintoon, jota et uidessa saa turvallisesti.';

  @override
  String get swimOpenUnsupported =>
      'Ilman huoltoa uinnin aikana ei tankata: syö hyvin etukäteen, mitoita uinti sen mukaan ja tankkaa heti perään.';

  @override
  String get swimOpenFeedsUnknown =>
      'Avovesi: valitse kohdassa ”Muokkaa strategiaa”, onko tankkaus mahdollista (huollettu vai ei).';

  @override
  String get swimFluidPool =>
      'Juominen on tärkeää myös altaalla: vedessä hikoilet vähemmän kuin maalla, mutta et olematta. Pidä nimetty pullo reunalla ja juo taukojen aikana.';

  @override
  String get swimFluidOpen =>
      'Sääennuste ei kerro veden lämpötilaa, ja kylmä vesi vaimentaa janoa: juo ennen lähtöä, joka tankkauksella ja heti perään.';

  @override
  String get swimBeforeAfter =>
      'Ennen: tuttu hiilihydraattipitoinen ateria 1–4 t ennen. Jälkeen: noin 1 g hiilihydraattia/kg ja 20–25 g proteiinia; jos punnitsit itsesi, juo noin 1,5 l jokaista menetettyä kiloa kohden, vähän natriumia mukana.';

  @override
  String get swimNoDuration =>
      'Ei suunniteltua kestoa: vesi reunalla riittää useimpiin uinteihin; hiilihydraattijuoma vasta yli 90 minuutin uintiin.';

  @override
  String swimCarryPool(String bottles, String bottleMl, String drinkCarbs) {
    return 'Ei geelejä. Pullo altaan reunalla: $bottles × $bottleMl ml; $drinkCarbs g hiilihydraattia tulee juomajauheesta.';
  }

  @override
  String swimCarryOpen(String bottles, String bottleMl, String drinkCarbs) {
    return 'Ei geelejä uidessa. Tankkauksilla: $bottles × $bottleMl ml; $drinkCarbs g hiilihydraattia tulee juomajauheesta.';
  }

  @override
  String swimPerBreak(String carbs, String fluid) {
    return '20 minuuttia kohden, tauolla tai tankkauksella: noin $carbs g hiilihydraattia ja $fluid ml.';
  }

  @override
  String get feedsLabel => 'Tankkaus (avovesi)';

  @override
  String get feedsSupported => 'Huollettu (vene, kajakki, ranta)';

  @override
  String get feedsUnsupported => 'Ilman huoltoa';

  @override
  String get feedsUnknown => 'Ei tiedossa';

  @override
  String get ecgTitle => 'EKG';

  @override
  String get ecgChooseDevice => 'Valitse Polar H10';

  @override
  String get ecgStart => 'Tallenna EKG';

  @override
  String get ecgStopSave => 'Lopeta ja tallenna';

  @override
  String get ecgImport => 'Tuo EKG-tiedosto';

  @override
  String get ecgHistory => 'EKG-historia';

  @override
  String get ecgWaveform => 'Käyrä';

  @override
  String get ecgReport => 'Raportti';

  @override
  String get ecgExportCsv => 'Vie käyrä (CSV)';

  @override
  String get ecgExportMetadata => 'Vie EKG-metatiedot';

  @override
  String get ecgExportOriginal => 'Jaa alkuperäinen tiedosto';

  @override
  String get ecgRecording => 'EKG-tallennus käynnissä';

  @override
  String get ecgRecordingDate => 'Tallennuksen päivämäärä ja aika';

  @override
  String get ecgLinkedWorkout => 'Liitetty harjoitus';

  @override
  String get ecgIndependent => 'Ei liitettyä harjoitusta';

  @override
  String get ecgNoRecordings => 'Ei vielä EKG-tallennuksia.';

  @override
  String ecgSamples(int count) {
    return '$count näytettä';
  }

  @override
  String ecgSignalGaps(int count) {
    return '$count signaalikatkoa';
  }

  @override
  String get ecgDeleteConfirm =>
      'Poistetaanko tämä tallennus ja sen alkuperäinen tiedosto pysyvästi?';

  @override
  String get ecgDescription =>
      'Tallenna Polar H10:llä, tuo CSV-käyriä tai säilytä PDF-raportteja.';

  @override
  String get ecgPrivacy =>
      'Tallennetaan tälle laitteelle ja sisällytetään varmuuskopioihin. Raakasignaaleja ei lähetetä valmentajalle.';

  @override
  String get ecgLimitations =>
      'Omaan tallennukseen ja tarkasteluun. EKG-pohjaista HRV:tä ja signaalin laatua ei ole validoitu tässä; diagnoosia tai palautumispisteitä ei lasketa.';

  @override
  String get ecgImportLimitations =>
      'Garminin ja Apple Watchin PDF-viennit ovat raportteja. Käyrät vaativat CSV-sarakkeet time_seconds (tai time_ms) ja ecg_uv (tai ecg_mv).';

  @override
  String get ecgReportOnly =>
      'Vain raportti. Raakasignaalin näytteitä ei ole saatavilla. Jaa alkuperäinen tiedosto nähdäksesi raportin.';

  @override
  String get indoorTitle => 'Sisäharjoittelu';

  @override
  String get indoorEquipment => 'Harjoittelulaite';

  @override
  String get indoorChooseEquipment => 'Valitse laite';

  @override
  String get indoorChooseHeartRate => 'Valitse sykeanturi';

  @override
  String get indoorStart => 'Aloita tallennus';

  @override
  String get indoorPause => 'Keskeytä tallennus';

  @override
  String get indoorFinish => 'Lopeta ja tallenna';

  @override
  String get indoorSaved => 'Tallennettu harjoitushistoriaan';

  @override
  String get indoorExportFit => 'Jaa FIT-harjoitus';

  @override
  String get indoorUnfinished => 'Keskeneräiset tallennukset';

  @override
  String get indoorReviewResume => 'Tarkastele tai jatka';

  @override
  String get indoorDiscard => 'Hylkää tallennus';

  @override
  String get indoorDiscardConfirm =>
      'Hylätäänkö tämä keskeneräinen tallennus pysyvästi?';

  @override
  String get indoorExternalHeartRate => 'Käytä ulkoista sykeanturia';

  @override
  String get indoorEquipmentHeartRate => 'Pois: käytä laitteen sykettä';

  @override
  String get indoorCurrentInterval => 'Nykyinen intervalli';

  @override
  String get indoorNextInterval => 'Seuraava intervalli';

  @override
  String get indoorPlanComplete => 'Suunnitellut intervallit suoritettu';

  @override
  String get indoorAuthorizeControl => 'Salli laitteen ohjaus';

  @override
  String get indoorManualOverride => 'Käytä käsiohjausta';

  @override
  String get indoorAutoPower => 'Seuraa intervallitehoa automaattisesti';

  @override
  String get indoorApplyTarget => 'Aseta tavoite';

  @override
  String get indoorDescription =>
      'Yhdistä Bluetooth FTMS -laite ja tallenna sisäharjoitus.';

  @override
  String get indoorKeepOpen =>
      'Tallennus jatkuu toisessa sovelluksessa tai näyttö lukittuna. Tauko keskeyttää mittaukset; pysäytä laite sen omilla painikkeilla.';

  @override
  String get indoorFitHint =>
      'Tallenna FIT-tiedosto tai avaa se yhteensopivassa harjoitussovelluksessa jakovalikon kautta.';

  @override
  String get indoorNoEquipment =>
      'FTMS-laitteita ei löytynyt. Käynnistä laite ja ota Bluetooth-yhteys käyttöön.';

  @override
  String get indoorControlPrompt =>
      'Saako Fjelia muuttaa tämän harjoituksen tavoitteita? Pysy laitteen säätimien lähellä. Voit vaihtaa käsiohjaukseen milloin tahansa.';

  @override
  String get indoorTreadmillSafety =>
      'Kiinnitä turva-avain ja pysy säätimien lähellä. Vahvista vain pienet muutokset, enintään 0,5 km/h tai 1% kaltevuutta. Tee suuremmat muutokset laitteen säätimillä.';

  @override
  String get recordingTime => 'Tallennusaika';

  @override
  String get recordingSpeed => 'Nopeus';

  @override
  String get recordingPower => 'Teho';

  @override
  String get recordingCadence => 'Kadenssi / vetotiheys';

  @override
  String get recordingIncline => 'Kaltevuus';

  @override
  String get recordingResistance => 'Vastus';

  @override
  String get recordingSource => 'Lähde';

  @override
  String get recordingNext => 'Seuraava vaihe';

  @override
  String get recordingConnecting => 'Yhdistetään';

  @override
  String get recordingReconnecting => 'Yhdistetään uudelleen';

  @override
  String get recordingInterrupted => 'Keskeytynyt';

  @override
  String get recordingPaused => 'Tauolla';

  @override
  String get indoorMatrixReadOnly =>
      'Matrix-juoksumatolla vain tallennus. Säädä nopeutta ja kaltevuutta konsolista; kauko-ohjausta ei ole varmistettu tälle mallille.';

  @override
  String ecgCoverage(String value) {
    return '$value% näytteistä tallennettu';
  }

  @override
  String get recordingBeforeRestore =>
      'Lopeta tallennus ennen varmuuskopion palauttamista.';

  @override
  String get gymTitle => 'Kuntosalin juoksumatot';

  @override
  String get gymDescription =>
      'Tallenna puhelimella, tuo xID-harjoituksia tai skannaa konsolin yhteenveto.';

  @override
  String get gymDirectConnection => 'Suora yhteys';

  @override
  String get gymConsoleSupport =>
      'Yhteys riippuu konsolista. Vanhemmat Matrix-konsolit voivat tukea xID:tä Bluetooth-reaaliaikatietojen sijaan.';

  @override
  String get gymFindEquipment => 'Etsi kuntolaitteita';

  @override
  String get gymLiveAvailable =>
      'Tämä konsoli voi lähettää harjoitustietoja suoraan Fjeliaan.';

  @override
  String get gymLiveUnavailable =>
      'Tuettuja reaaliaikatietoja ei löytynyt. Tuo xID-harjoituksia tai tallenna konsolin yhteenveto.';

  @override
  String get gymSpeedOnly =>
      'Nopeus ja askeltiheys ovat saatavilla. Tämä yhteys ei tarjoa kaltevuutta tai etäohjausta.';

  @override
  String get gymUseMachine => 'Käytä tätä laitetta';

  @override
  String get gymConnectionReport => 'Yhteysraportti';

  @override
  String get gymShareReport => 'Jaa yhteysraportti';

  @override
  String get gymXid => 'Matrix xID';

  @override
  String get gymXidDescription =>
      'Tuo kuntosalin xID-verkkoon tallennetut juoksumattoharjoitukset.';

  @override
  String get gymPortal => 'Kuntosalin Netpulse-portaali';

  @override
  String get gymPortalHelp =>
      'Syötä kuntosalisi antama Netpulse-portaalin osoite.';

  @override
  String get gymPasscode => 'xID-tunnusluku';

  @override
  String get gymSessionHelp =>
      'Istunto tallennetaan turvallisesti. Tunnuslukua ei tallenneta.';

  @override
  String get gymAutoSync => 'Synkronoi xID-harjoitukset automaattisesti';

  @override
  String gymLastDays(int days) {
    return 'Viimeiset $days päivää';
  }

  @override
  String get gymLoadWorkouts => 'Lataa harjoitukset';

  @override
  String get gymNoWorkouts =>
      'Tälle ajanjaksolle ei löytynyt juoksumattoharjoituksia.';

  @override
  String gymSkipped(int count) {
    return '$count lukukelvotonta harjoitusta ohitettu.';
  }

  @override
  String gymImported(int count, int duplicates) {
    return '$count harjoitusta tuotu; $duplicates kaksoiskappaletta ohitettu.';
  }

  @override
  String get gymSummary => 'Juoksumaton yhteenveto';

  @override
  String get gymSummaryDescription =>
      'Kuvaa konsolin loppunäkymä ja tarkista arvot ennen tallentamista.';

  @override
  String get gymTakePhoto => 'Ota kuva';

  @override
  String get gymChoosePhoto => 'Valitse kuva';

  @override
  String get gymReview =>
      'Tarkista yksiköt, aloitusaika ja arvot. Kuvat luetaan puhelimellasi. Vain harjoituksen yhteenveto tallennetaan.';

  @override
  String get gymStartTime => 'Harjoituksen alku';

  @override
  String get gymDurationHelp => 'Syötä mm:ss tai hh:mm:ss, esimerkiksi 30:00.';

  @override
  String get gymDistanceUnit => 'Matkan yksikkö';

  @override
  String get gymCalories => 'Kalorit';

  @override
  String get manualRecordTitle => 'Tallenna aktiviteetti';

  @override
  String get manualRecordDescription =>
      'Tallenna harjoitus valinnaisella GPS:llä, EKG:llä ja sykkeellä. Tallennus jatkuu sovellusta vaihtaessa ja näyttö lukittuna, kunnes painat Tauko tai Lopeta.';

  @override
  String get manualTreadmill => 'Juoksumattojuoksu';

  @override
  String get manualChooseH10 => 'Valitse Polar H10';

  @override
  String get manualRecordEcg => 'Tallenna EKG Polar H10:llä';

  @override
  String get manualChooseHelp =>
      'Valitse Polar H10 EKG:n ja sykkeen tallentamiseen.';

  @override
  String manualEcgSegments(int count) {
    return 'Liitetyt EKG-osuudet: $count';
  }

  @override
  String get manualEcgInterrupted =>
      'EKG pysähtyi. Aktiviteetin ajastin jatkuu.';

  @override
  String get manualRestartEcg => 'Käynnistä EKG-tallennus uudelleen';

  @override
  String get manualFinalDistance => 'Lopullinen matka (valinnainen)';

  @override
  String get manualDiscardNote =>
      'Hylätäänkö aktiviteetti? EKG-tallenteet säilyvät EKG-historiassa.';

  @override
  String get manualRecordHeartRate => 'Tallenna syke';

  @override
  String get manualChooseHr => 'Valitse sykeanturi';

  @override
  String get manualHrWithEcg => 'Käyttää samaa H10-yhteyttä kuin EKG.';

  @override
  String get manualRecordGps => 'Tallenna GPS-reitti ja matka';

  @override
  String get manualGpsHelp =>
      'Ulkoharjoitteluun. Salli tarkka sijainti, jotta reitti tallentuu näytön ollessa sammutettuna.';

  @override
  String get manualGpsWaiting => 'Odotetaan tarkkaa GPS-sijaintia';

  @override
  String manualGpsAccuracy(int meters) {
    return 'GPS-tarkkuus: $meters m';
  }

  @override
  String get manualRecordBp => 'Sisällytä verenpainemittaukset';

  @override
  String get manualBpHelp =>
      'Näyttää tallennuksen aikana tehdyt Hilo-, Aktiia- ja Health-mittaukset myös myöhemmän synkronoinnin jälkeen.';

  @override
  String get manualBpUnavailable => 'Verenpainemittauksia ei voitu ladata.';

  @override
  String get manualBpEmpty =>
      'Ei verenpainemittauksia tämän tallennuksen aikana.';

  @override
  String get manualHrDisconnected => 'Sykeanturin yhteys katkennut.';

  @override
  String get manualReconnectHr => 'Yhdistä sykeanturi uudelleen';

  @override
  String get manualBackgroundNotification =>
      'Tallennus jatkuu näytön ollessa sammutettuna';

  @override
  String get ecgAskCoach => 'Keskustele tekoälyvalmentajan kanssa';

  @override
  String get ecgCoachWarningTitle => 'Ei lääketieteellinen neuvo';

  @override
  String get ecgCoachWarningBody =>
      'Tekoälyvalmentaja ei ole lääkäri eikä voi tehdä diagnoosia. Rintavyön EKG:ssä on vain yksi kytkentä: se ei voi sulkea pois sydäninfarktia tai muuta sydänsairautta, ja analyysi voi olla väärä.\n\nRintakipu tai puristus rinnassa, hengenahdistus, kipu käsivarressa, leuassa tai selässä, kylmä hiki tai pyörtyminen: soita heti 112. Älä odota tekoälyn vastausta.\n\nAnalysoidut arvot ja 10 sekuntia raakasignaalia menevät tekoälyasetuksissa valittuun tekoälymalliin.';

  @override
  String get ecgCoachUnderstood => 'Ymmärrän';

  @override
  String get ecgCoachBanner =>
      'Ei lääketieteellinen neuvo. Tekoäly ei ole lääkäri eikä voi sulkea pois sydäninfarktia. Hätätilanteessa soita 112.';

  @override
  String get ecgCoachCardTitle => 'EKG:n esianalyysi';

  @override
  String get statusMeasured => 'Mitattu';

  @override
  String get ecgQuestionOverview => 'Mitä EKG:ni näyttää?';

  @override
  String get ecgQuestionRhythm => 'Onko sydämeni rytmi säännöllinen?';

  @override
  String get ecgQuestionDoctor => 'Pitäisikö lääkärin katsoa tämä?';

  @override
  String get ecgFollowSymptoms =>
      'Minkä oireiden kanssa minun pitäisi mennä lääkäriin?';

  @override
  String get ecgFollowRiskFactors => 'Miten riskitekijäni vaikuttavat tähän?';

  @override
  String get ecgFollowTraining => 'Voinko harjoitella normaalisti?';

  @override
  String get ecgFollowBetterRecording => 'Miten tallennan paremman EKG:n?';

  @override
  String get manualTreadmillConnect =>
      'Yhdistä juoksumatto (Bluetooth, valinnainen)';

  @override
  String get manualTreadmillHelp =>
      'Nopeus, matka ja kaltevuus tulevat silloin juoksumatolta. Ilman yhteyttä syötä matka lopuksi.';

  @override
  String get sportIndoorCycling => 'Sisäpyöräily';

  @override
  String get sportElliptical => 'Crosstrainer';

  @override
  String get sportStairClimber => 'Porraskone';

  @override
  String get manualWrongMachine => 'Tämä laite ei sovi valittuun lajiin.';

  @override
  String get manualEquipmentHelp =>
      'Yhdistä Bluetooth-laite (FTMS). Nopeus, teho, kadenssi ja matka tulevat laitteelta.';

  @override
  String get plusTitle => 'Kirjaa';

  @override
  String get plusStartWorkout => 'Aloita harjoitus';

  @override
  String get plusStartWorkoutHint =>
      'Livenä GPS:llä, matolla tai sisäpyörällä · EKG ja syke';

  @override
  String get plusGroupTraining => 'Harjoittelu';

  @override
  String get plusGroupHeart => 'Sydän ja verenkierto';

  @override
  String get plusGroupBody => 'Keho';

  @override
  String get plusGroupRecovery => 'Palautuminen';

  @override
  String get plusLogWorkout => 'Lisää harjoitus';

  @override
  String get plusLogWorkoutHint => 'Mennyt harjoitus käsin';

  @override
  String get plusImport => 'Tuo';

  @override
  String get plusImportHint => 'Strava, FIT, GPX, salin juoksumatto';

  @override
  String get plusEcg => 'Tallenna EKG';

  @override
  String get plusEcgHint => 'Polar H10 tai EKG-tiedosto';

  @override
  String get plusHrv => 'HRV-tarkistus';

  @override
  String get plusHrvHint => 'Lyhyt mittaus Polar H10:llä';

  @override
  String get plusBpMeasure => 'Mittaa Hilo-mansetilla';

  @override
  String get plusBpMeasureHint =>
      'Yhdistä Hilo-verenpainemansetti Bluetoothilla';

  @override
  String get plusBpLog => 'Kirjaa verenpaine';

  @override
  String get plusBpLogHint => 'Syötä lukema';

  @override
  String get plusBpReport => 'Hilo-raportti';

  @override
  String get plusBpReportHint => 'Tuo PDF';

  @override
  String get plusSpo2 => 'SpO₂ ja syke';

  @override
  String get plusSpo2Hint => 'Pulssioksimetrista';

  @override
  String get plusWeigh => 'Punnitse';

  @override
  String get plusWeighHint => 'RENPHO-vaaka Bluetoothilla';

  @override
  String get plusWeightLog => 'Kirjaa paino';

  @override
  String get plusWeightLogHint => 'Paino, rasva, BMI';

  @override
  String get plusWaist => 'Vyötärö';

  @override
  String get plusWaistHint => 'Ympärys ja suhteet';

  @override
  String get plusGrip => 'Puristusvoima';

  @override
  String get plusGripHint => 'Dynamometrin lukema';

  @override
  String get plusSleep => 'Kirjaa uni';

  @override
  String get plusSleepHint => 'Kesto, syvä ja REM';

  @override
  String get recPace => 'Vauhti (/km)';

  @override
  String get recAvgPace => 'Keskivauhti';

  @override
  String get recPace500 => 'Vauhti (/500 m)';

  @override
  String get recSpeedKmh => 'Nopeus (km/h)';

  @override
  String get recPowerW => 'Teho (W)';

  @override
  String get recDistanceKm => 'Matka (km)';

  @override
  String get recHeartRate => 'Syke';

  @override
  String get recMap => 'Kartta';

  @override
  String get recStart => 'Aloita';

  @override
  String get recResume => 'Jatka';

  @override
  String get recFinish => 'Valmis';

  @override
  String get recDiscard => 'Hylkää';

  @override
  String get recLive => 'Tallentaa';

  @override
  String get recNew => 'Uusi suoritus';

  @override
  String get recCadence => 'Kadenssi';

  @override
  String get recMachine => 'Laite';

  @override
  String get recGps => 'GPS';

  @override
  String get recEcg => 'EKG';

  @override
  String get recBloodPressure => 'Verenpaine';

  @override
  String get recBannerOpen => 'Avaa napauttamalla';

  @override
  String get bpActivityHint =>
      'Mansetit eivät usein mittaa liikkeessä. Ennen tai jälkeen suorituksen otetut mittaukset eivät näy tässä.';

  @override
  String objectiveKeyLong(String sport, String goal) {
    return '$sport: pitkä avainharjoitus, $goal';
  }

  @override
  String seasonKeyRides(int n) {
    return '$n viikolla pitkä avainharjoitus kasvaa kohti puolta tapahtumasta, kerran jaksossa eikä koskaan toisen tapahtuman vieressä.';
  }

  @override
  String seasonEventAsLong(int n) {
    return '$n viikolla toinen tapahtuma on pitkä harjoitus suurempaa tavoitetta varten.';
  }

  @override
  String objectiveThreshold(String sport, String goal) {
    return 'Kynnys: $sport – $goal';
  }

  @override
  String objectiveHills(String sport, String goal) {
    return 'Mäet: $sport – $goal';
  }

  @override
  String objectiveOpeners(String goal) {
    return 'Lyhyet herättelyt: $goal';
  }

  @override
  String get planAdjustedTitle => 'Suunnitelmaa muutettiin automaattisesti';

  @override
  String planAdjSwap(String session, String day, String from) {
    return '$session: tehty $day eikä $from.';
  }

  @override
  String planAdjSubstitute(String activity, String session, String from) {
    return '$activity lasketaan harjoitukseksi $session ($from).';
  }

  @override
  String planAdjStrengthCredit(String activity, String session) {
    return '$activity kattaa jalkavoiman harjoituksesta $session.';
  }

  @override
  String planAdjMoved(String session, String day) {
    return '$session siirtyy päivälle $day, joka vapautui.';
  }

  @override
  String planAdjMovedEasy(String session, String day, String activity) {
    return '$session siirtyy päivälle $day, kevyempänä: jalat palautuvat harjoituksesta $activity.';
  }

  @override
  String get planAdjUndone => 'Muutos peruttiin.';

  @override
  String get shortSessionTitle => 'Suunniteltua lyhyempi – miksi?';

  @override
  String shortSessionLine(String session, int done, int planned) {
    return '$session: $done/$planned min';
  }

  @override
  String get shortReasonTime => 'Ei aikaa';

  @override
  String get shortReasonWeather => 'Sää';

  @override
  String get shortReasonFatigue => 'Väsynyt';

  @override
  String get shortReasonPain => 'Kipu';

  @override
  String get shortReasonOther => 'Muu';

  @override
  String get styleTitle => 'Tyyli';

  @override
  String get styleAuto => 'Automaattinen';

  @override
  String get styleAutoHint =>
      'Seuraa puhelinta: päivällä LightFjelia, yöllä DarkFjelia.';

  @override
  String get connectMyWhoosh => 'Yhdistä MyWhoosh';

  @override
  String get myWhooshSubtitle =>
      'Kirjaudu MyWhoosh-tililläsi, niin sisäajosi tulevat tehon, kadenssin ja sykkeen kanssa.';

  @override
  String get myWhooshCredentialsInfo =>
      'MyWhoosh-tunnukset tallennetaan salattuina laitteellesi. Fjelia lukee ajosi suoraan MyWhooshista MyWhoosh-sovelluksen rajapinnan kautta. Fjelia ei ole MyWhooshin yhteistyökumppani.';

  @override
  String get myWhooshTile => 'Sisäajot';

  @override
  String get myWhooshSignedInElsewhere =>
      'MyWhoosh sallii vain yhden istunnon tiliä kohden, ja olet kirjautuneena toisella laitteella. Sulje MyWhoosh siellä (kirjaudu tarvittaessa ulos) ja yritä uudelleen.';

  @override
  String get shareWorkout => 'Jaa harjoitus';

  @override
  String get shareFitFile => 'Jaa FIT-tiedostona';

  @override
  String get shareFitFileHint =>
      'Stravaan, COROSiin, TrainingPeaksiin ja muihin sovelluksiin';

  @override
  String get sendToGarmin => 'Lähetä Garmin Connectiin';

  @override
  String get sendToGarminHint => 'Lataa harjoituksen Garmin-tilillesi';

  @override
  String get sentToGarmin => 'Lähetetty Garmin Connectiin';

  @override
  String get alreadyOnGarmin => 'Tämä harjoitus on jo Garmin Connectissa';

  @override
  String get missedWorkoutPastTitle => 'Väliin jäänyt harjoitus';

  @override
  String get leaveIt => 'Anna olla';

  @override
  String get reviewChange => 'Katso';

  @override
  String get keepPlan => 'Pidä suunnitelma';

  @override
  String get missedYesterdayTitle => 'Jäi eilen väliin';

  @override
  String get proposalReplanTitle => 'Laaditaanko suunnitelma uudelleen?';

  @override
  String get proposalRestTitle => 'Lepopäivä tänään?';

  @override
  String get proposalRecoveryTitle => 'Tänään vain kevyesti?';

  @override
  String get proposalEasierTitle => 'Vähän kevyemmin tänään?';

  @override
  String get proposalReplanBody =>
      'Kuormitus tai HRV puoltaa uutta suunnitelmaa.';

  @override
  String get proposalCardTitle => 'Ehdotus tälle päivälle';

  @override
  String get replanMissed => 'Ajoita uudelleen';

  @override
  String get askBeforePlanChanges => 'Kysy ennen suunnitelman muutoksia';

  @override
  String get askBeforePlanChangesHint =>
      'Valmius ja trendit ehdottavat muutoksia, sinä päätät. Pois: Fjelia muokkaa suunnitelmaa itse.';

  @override
  String missedOnDayTitle(String day) {
    return 'Jäi väliin: $day';
  }

  @override
  String missedPastBody(String names) {
    return '$names. Siirrä vai ohita?';
  }

  @override
  String proposalDropsLine(String title) {
    return '$title jää pois';
  }

  @override
  String proposalChangeLine(String from, String to) {
    return '$from → $to';
  }

  @override
  String get proposalAnswered => 'Jo vastattu, ei enää päätettävää.';

  @override
  String get ecgTrainingWarningTitle => 'Vain harjoitteluun';

  @override
  String get ecgTrainingWarningBody =>
      'Fjelia ei tulkitse EKG:tä lääketieteellisesti. Valmentaja selittää vain sykkeen, HRV:n ja signaalin laadun harjoittelua varten. Sydänsairauksista tai rytmihäiriöistä se ei sano mitään: vie tallenne ja näytä se lääkärille.\n\nRintakipu tai puristus, hengenahdistus, kipu käsivarressa, leuassa tai selässä, kylmä hiki tai pyörtyminen: soita heti 112.\n\nSyke, HRV ja signaalin laatu lähetetään tekoälyasetuksissa valitulle mallille.';

  @override
  String get ecgQuestionTraining => 'Mitä EKG:ni kertoo harjoittelusta?';

  @override
  String get ecgFollowHrv => 'Mitä HRV kertoo palautumisestani?';

  @override
  String get ecgFollowHeartRate => 'Miten sykkeeni kehittyi?';

  @override
  String get bioLeanMuchYounger => 'Selvästi nuorempi';

  @override
  String get bioLeanYounger => 'Nuorempi';

  @override
  String get bioLeanEven => 'Juuri keskitasolla';

  @override
  String get bioLeanOlder => 'Vähän kasvunvaraa';

  @override
  String get bioLeanMuchOlder => 'Paljon kasvunvaraa';

  @override
  String get fitnessSameAsAge => 'Ikäisesi kunnossa';

  @override
  String get lifespanBandTitle => 'Elinikäsi haarukka';

  @override
  String get lifespanBandNote =>
      'Tilastojen haarukka samankaltaisille arvoille, ei ennuste sinulle.';

  @override
  String get factorHelps => 'Auttaa sinua';

  @override
  String get factorSlows => 'Jarruttaa sinua';

  @override
  String get bioFactorBloodPressure => 'Verenpaine';

  @override
  String get bioFactorVisceralFat => 'Viskeraalirasva';

  @override
  String get bioFactorLipids => 'Veren rasvat';

  @override
  String get bioFactorInflammation => 'Tulehdus (CRP)';

  @override
  String get bioFactorKidney => 'Munuaisten toiminta';

  @override
  String get bioAgeModelNote =>
      'Kuntoikä vertaa VO₂maxiasi ikänormeihin. Elinikähaarukka tulee tutkimuksiin perustuvasta mallista: ei lääketieteellinen väite eikä henkilökohtainen ennuste.';

  @override
  String fitnessYoungerBy(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years vuotta ikääsi nuorempi',
      one: '1 vuoden ikääsi nuorempi',
    );
    return '$_temp0';
  }

  @override
  String fitnessOlderBy(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years vuotta ikäsi yli',
      one: '1 vuosi ikäsi yli',
    );
    return '$_temp0';
  }

  @override
  String lifespanBandYears(int low, int high) {
    return '$low–$high';
  }

  @override
  String todayAge(int age) {
    return 'Tänään $age';
  }

  @override
  String get vo2ClassBelowAvg => 'alle keskitason';

  @override
  String get vo2ClassAverage => 'keskitaso';

  @override
  String get vo2ClassAboveAvg => 'yli keskitason';

  @override
  String get vo2ClassGood => 'hyvä';

  @override
  String get vo2ClassExcellent => 'erinomainen';

  @override
  String get vo2ClassElite => 'huippuluokka';

  @override
  String get fjeliaProHint =>
      'FjeliaPro antaa sinulle tarkempaa tietoa ja analyyseja.';

  @override
  String get rowingStrokeRate => 'Vetoa / min';

  @override
  String rowingStrokeAverage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ø $count vetoa',
      one: 'Ø 1 veto',
    );
    return '$_temp0';
  }

  @override
  String get rowingTapToSwitch => 'Vaihda napauttamalla';

  @override
  String get copyAnswer => 'Kopioi vastaus';

  @override
  String get answerCopied => 'Kopioitu ✨';

  @override
  String get coachMemories => 'Muistikortit';

  @override
  String get coachMemoriesIntro =>
      'Kerro valmentajallesi, mitä sen pitää aina tietää. Korttisi kulkevat jokaisessa keskustelussa mukana.';

  @override
  String get coachMemoryNew => 'Uusi kortti';

  @override
  String get coachMemoryTitle => 'Otsikko';

  @override
  String get coachMemoryTitleHint => 'esim. Vasen polvi';

  @override
  String get coachMemoryBody => 'Mitä valmentajasi pitää tietää?';

  @override
  String get coachMemoryBodyHint =>
      'esim. Alamäkijuoksu on sattunut keväästä asti. Ylämäki on ok.';

  @override
  String get coachMemoryEmpty => 'Ei vielä kortteja. Tee ensimmäinen 🔥';

  @override
  String get coachMemoryDeleteQuestion => 'Poistetaanko tämä kortti?';

  @override
  String coachMemoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count korttia valmentajasi muistissa',
      one: '1 kortti valmentajasi muistissa',
      zero: 'Ei kortteja',
    );
    return '$_temp0';
  }

  @override
  String get sportSkiErg => 'SkiErg (hiihto sisällä)';

  @override
  String get weatherRain => 'SADE';

  @override
  String weatherLowHigh(int low, int high) {
    return 'Alin $low° · Ylin $high°';
  }

  @override
  String get weatherDayPeak => 'Päivän huippu';

  @override
  String get weatherDayTotal => 'Päivän yhteensä';

  @override
  String get proTagline => 'Valmentajasi. Pro-tasolla.';

  @override
  String get proBenefitCoach =>
      'AI-valmentaja Pro-mallilla: nopeampi, perusteellisempi, oma kiintiö';

  @override
  String get proBenefitMemory =>
      'Muistikortit: mitä valmentajasi pitää aina tietää';

  @override
  String get proBenefitEcg => 'Yksityiskohtainen EKG-analyysi';

  @override
  String get proBenefitCopy => 'Kopioi vastaukset yhdellä napautuksella';

  @override
  String get proMonthly => 'Kuukausittain';

  @override
  String get proYearly => 'Vuosittain';

  @override
  String proPerMonth(String price) {
    return '$price / kk';
  }

  @override
  String proPerYear(String price) {
    return '$price / vuosi';
  }

  @override
  String get proBestValue => 'PARAS DIILI';

  @override
  String get proSubscribe => 'Hanki FjeliaPro';

  @override
  String get proRestore => 'Palauta ostot';

  @override
  String get proManage => 'Hallitse tilausta';

  @override
  String proActiveUntil(String date) {
    return 'Pro on voimassa $date asti';
  }

  @override
  String get proAutoRenew =>
      'Tilaus uusiutuu automaattisesti, ellet peru sitä vähintään 24 tuntia ennen jakson päättymistä Apple-tilisi asetuksista. Maksu veloitetaan Apple-tililtäsi.';

  @override
  String get proTerms => 'Käyttöehdot';

  @override
  String get proPrivacy => 'Tietosuoja';

  @override
  String get proProblemStore => 'App Store ei viimeistellyt ostoa.';

  @override
  String get proProblemService =>
      'Ostosi on tehty, mutta sitä ei voitu vielä tarkistaa. Fjelia yrittää uudelleen seuraavalla käynnistyksellä.';

  @override
  String get proProblemNothing =>
      'Palautettavaa FjeliaPro-tilausta ei löytynyt.';

  @override
  String get proProblemNotActive => 'Tämä tilaus on päättynyt.';

  @override
  String get proUnavailable =>
      'Tilauksia ei voi ladata juuri nyt. Yritä myöhemmin uudelleen.';

  @override
  String get proWelcome => 'Tervetuloa FjeliaProhon 🔥';

  @override
  String get proUsesFjeliaAi =>
      'Pro-malli vastaa, kun AI-asetuksissa on valittuna \"Fjelia AI\".';

  @override
  String get proToolsTitle => 'Pro-analyysit';

  @override
  String get proPlanCheck => 'Päivän suunnitelmatarkistus';

  @override
  String get proPlanCheckHint => 'Sopiiko päivän suunnitelma palautumiseesi?';

  @override
  String get proWeekReview => 'Viikkokatsaus';

  @override
  String get proWeekReviewHint => 'Mikä toimi ja mitä muuttaa ensi viikolla';

  @override
  String get proRacePlan => 'Kisasuunnitelma';

  @override
  String proRacePlanHint(String race) {
    return '$race: keventäminen, vauhdinjako, tankkaus';
  }

  @override
  String get proSeason => 'Kausianalyysi';

  @override
  String get proSeasonHint => 'Kautesi tavoitteet, vaiheet ja riskit';

  @override
  String get proAnalysisCreate => 'Luo analyysi';

  @override
  String get proAnalysisRedo => 'Luo uudelleen';

  @override
  String proAnalysisFrom(String time) {
    return 'Luotu $time';
  }

  @override
  String get proAnalysisWorking => 'Iso malli analysoi…';

  @override
  String get proAnalysisFailed => 'Analyysi ei onnistunut. Yritä uudelleen.';

  @override
  String get proBenefitPlanCheck =>
      'Aamuehdotus ja suunnitelman tarkistus: valmentaja muokkaa päivän harjoituksen';

  @override
  String get proBenefitReview => 'Viikkokatsaus ja kausianalyysi';

  @override
  String get proBenefitRacePlan =>
      'Kisasuunnitelma: keventäminen, vauhdinjako, tankkaus';

  @override
  String get statsTitle => 'Tilastot';

  @override
  String get statsLast4Weeks => 'Viimeiset 4 viikkoa · viikossa';

  @override
  String get statsElevation => 'Nousu';

  @override
  String get statsAllTimeTotals => 'Kaikki';

  @override
  String get statsBestEfforts => 'Parhaat suoritukset';

  @override
  String get statsLongest => 'Pisin';

  @override
  String get statsMostElevation => 'Eniten nousua';

  @override
  String get statsNone => 'Ei vielä suorituksia.';

  @override
  String get proBenefitStats =>
      'Tilastot: parhaat suoritukset, tämä vuosi ja viimeiset 4 viikkoa';

  @override
  String get statsFourWeeks => '4 viikkoa';

  @override
  String get statsTickerWeek => 'viikossa, viimeiset 4 viikkoa';

  @override
  String statsTickerYear(String year) {
    return 'vuonna $year';
  }

  @override
  String statsTickerBest(String distance) {
    return 'Paras $distance';
  }

  @override
  String get statsPerWeekShort => '/ vko';

  @override
  String get gripLeft => 'Vasen';

  @override
  String get gripRight => 'Oikea';

  @override
  String get muscleShort => 'Lihas';

  @override
  String vsYesterday(String arrow) {
    return '$arrow vs. eilen';
  }

  @override
  String get proposalProCoach => 'Valmentaja kirjoittaa aamuilmoituksen';

  @override
  String get proposalProCoachHint =>
      'FjeliaPro: tämän päivän valmius, suunnitelma ja terveystiedot lähetetään Fjelia AI Prolle, joka muotoilee ehdotuksen pian aamun synkronoinnin jälkeen.';

  @override
  String get heatShort => 'Helle';

  @override
  String get coachRevisionLabel => 'Valmentajan ehdotus';

  @override
  String get revisionBefore => 'Ennen';

  @override
  String get revisionAfter => 'Jälkeen';

  @override
  String get revisionSwapped => 'Vaihdettu';

  @override
  String get revisionRestDay => 'Lepopäivä sen sijaan';

  @override
  String get revisionDropped => 'jätetty pois';

  @override
  String get revisionAccept => 'Ota käyttöön';

  @override
  String revisionSets(String sets, String reps) {
    return '$sets × $reps';
  }

  @override
  String get testMorningProposal => 'Testaa aamuehdotus';

  @override
  String get testMorningProposalHint =>
      'Ajaa aamutarkistuksen nyt keltaisella valmiudella; ilmoitus tulee 5 sekunnissa.';

  @override
  String get proposalRulesEasier =>
      'Palautuminen ei ole vielä täysi: tämän päivän harjoitukset lyhenevät ja kevenevät, tavoite säilyy.';

  @override
  String get proposalRulesRecovery =>
      'Selviä väsymyksen merkkejä: tänään vain kevyttä tai lepoa.';

  @override
  String get proposalCoachUnavailable =>
      'Valmentajaa ei juuri nyt tavoitettu; tämä on sääntöjen mukainen ehdotus.';

  @override
  String get revisionKeep => 'Pysyy suunnitellusti';

  @override
  String get revisionAlternative => 'Vaihtoehto';

  @override
  String get revisionTakeAlternative => 'Ota tämä sen sijaan';

  @override
  String proposalForDay(String day) {
    return 'Ehdotus: $day';
  }

  @override
  String get proposalDayTomorrow => 'huomenna';

  @override
  String get feelingQuestion => 'Miltä tänään tuntuu?';

  @override
  String get feelingGood => 'Hyvältä';

  @override
  String get feelingTired => 'Väsynyt';

  @override
  String get feelingSore => 'Lihaskipua';

  @override
  String get feelingIll => 'Sairas';

  @override
  String get feelingShort => 'Vähän aikaa';

  @override
  String get feelingAsking => 'Valmentaja miettii uudelleen…';

  @override
  String get proSwitchTitle => 'Vaihdetaanko ProAI:hin?';

  @override
  String proSwitchBody(String provider) {
    return 'FjeliaPro-tilauksesi on voimassa. Käyttääkö valmentaja tästä lähtien ProAI:ta palvelun $provider sijaan?';
  }

  @override
  String get proAiRouting =>
      'Valmentaja ja päivittäiset ehdotukset käyttävät ProAI:ta; kisasuunnitelma ja kausianalyysi käyttävät itsestään suurempaa ProAI-deepiä.';

  @override
  String proActiveUntilShort(String date) {
    return 'Voimassa $date asti';
  }

  @override
  String shortSessionNote(int done, int planned) {
    return 'Suunniteltua lyhyempi ($done/$planned min)';
  }

  @override
  String get noteForCoach => 'Huomio valmentajalle (valinnainen)';

  @override
  String get activityNote => 'Huomio';

  @override
  String get activityNoteAdd => 'Lisää huomio valmentajalle';

  @override
  String get plusOmronBle => 'Etsi BLE-verenpainemittareita';

  @override
  String get plusOmronBleHint =>
      'Etsi tavallisia Bluetooth-verenpainemittareita ja tuettuja Omron-profiileja.';
}
