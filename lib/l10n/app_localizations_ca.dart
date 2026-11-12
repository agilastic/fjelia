// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get freeAi => 'Free AI';

  @override
  String get freeAiUsageTracking =>
      'Perquè Free AI continuï disponible de manera fiable per a tothom, enviem un identificador aleatori de la instal·lació. Ens ajuda a detectar usos inusuals i a bloquejar sol·licituds abusives. L\'identificador no conté el teu nom ni dades del teu compte.';

  @override
  String freeAiDescription(String host) {
    return 'IA gratuïta al núvol per al xat i els resums a través de $host. No cal cap compte ni clau API propis. Amb la teva confirmació, els missatges i un resum de salut i entrenament s\'envien a aquest servei.';
  }

  @override
  String get freeAiUnavailable =>
      'Free AI no està disponible en aquesta versió. Tria un altre proveïdor.';

  @override
  String shareBriefingContextWithName(String name) {
    return 'S\'enviarà un resum de les teves dades de salut i entrenament a $name. Aquest consentiment únic també s\'aplica als futurs proveïdors d\'IA al núvol que triïs per als resums.';
  }

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminat del sistema';

  @override
  String get settings => 'Configuració';

  @override
  String get profile => 'Perfil';

  @override
  String get training => 'Entrenament';

  @override
  String get weatherLocation => 'Temps i ubicació';

  @override
  String get display => 'Pantalla';

  @override
  String get connections => 'Connexions';

  @override
  String get aiAndMore => 'IA i més';

  @override
  String get system => 'Sistema';

  @override
  String get runSetupAgain => 'Torna a executar la configuració';

  @override
  String get runSetupAgainSubtitle =>
      'Comptes, objectiu de cursa i pla d\'entrenament';

  @override
  String get back => 'Enrere';

  @override
  String get close => 'Tanca';

  @override
  String get dataExport => 'Exportació de dades';

  @override
  String get dataExportSubtitle =>
      'Exportació CSV, còpia de seguretat i restauració';

  @override
  String get developer => 'Desenvolupador';

  @override
  String get developerSubtitle => 'Mode de depuració, diagnòstic';

  @override
  String get debug => 'Depuració';

  @override
  String get debugMode => 'Mode de depuració';

  @override
  String get debugModeSubtitle => 'Mostra la pestanya DEBUG';

  @override
  String get support => 'Assistència';

  @override
  String get reportBug => 'Informa d\'un error';

  @override
  String get aiCoach => 'Entrenador IA';

  @override
  String get enableAiCoach => 'Activa l\'entrenador IA';

  @override
  String get onDeviceAiOrCloud => 'IA al dispositiu o proveïdor al núvol';

  @override
  String get provider => 'Proveïdor';

  @override
  String get model => 'Model';

  @override
  String get chatAndAiBriefingsUse =>
      'El xat i els resums amb IA fan servir Apple Intelligence en aquest dispositiu. No cal cap clau API. Si el model no està disponible, els resums mostren un text sense IA.';

  @override
  String get briefing => 'Resum';

  @override
  String get useAppleIntelligenceForBriefings =>
      'Fes servir Apple Intelligence per als resums';

  @override
  String get useOnDeviceAiFor =>
      'Fes servir la IA del dispositiu per als resums i mantén el proveïdor triat per al xat.';

  @override
  String get healthDataSharing => 'Compartició de dades de salut';

  @override
  String get askOncePerChatSession => 'Pregunta una vegada per sessió de xat';

  @override
  String get otherwiseAskBeforeEveryCloud =>
      'Si no, pregunta abans de cada missatge al núvol';

  @override
  String get reportABug => 'Informa d\'un error';

  @override
  String get weatherData => 'Dades meteorològiques';

  @override
  String get openSourceLibraries => 'Biblioteques de codi obert';

  @override
  String get license => 'Llicència';

  @override
  String get licenses => 'Llicències';

  @override
  String get apiKey => 'Clau API';

  @override
  String get saveApiKey => 'Desa la clau API';

  @override
  String get feedbackBugReport => 'Comentaris i informe d\'errors';

  @override
  String get reportSentThankYou => 'Informe enviat. Gràcies!';

  @override
  String get weReadEveryMessageIf =>
      'Llegim tots els missatges. Si has deixat el teu correu, és possible que rebis una resposta.';

  @override
  String get done => 'Fet';

  @override
  String get shareAnIdeaSuggestAn =>
      'Comparteix una idea, suggereix una millora o explica\'ns què ha passat i què esperaves.';

  @override
  String get whatHappenedAndWhatDid => 'Què ha passat i què esperaves?';

  @override
  String get pleaseLeaveOutPasswordsApi =>
      'Si us plau, no incloguis contrasenyes, claus API ni dades de salut personals.';

  @override
  String get includeDiagnostics => 'Inclou diagnòstics';

  @override
  String get optionalLogsMayContainAccount =>
      'Opcional. Els registres poden contenir dades del compte o de salut. Revisa\'ls a sota abans d\'enviar.';

  @override
  String get diagnosticsPreview => 'VISTA PRÈVIA DELS DIAGNÒSTICS';

  @override
  String get sendingSharesYourEmailSubject =>
      'En enviar es comparteixen el teu correu, l\'assumpte, el missatge i els diagnòstics seleccionats amb l\'assistència de Fjelia a www.fjelia.com.';

  @override
  String get copyReport => 'Copia l\'informe';

  @override
  String get shareReport => 'Comparteix l\'informe';

  @override
  String get appleHealth => 'Apple Salut';

  @override
  String get connectedServices => 'Serveis connectats';

  @override
  String get hiloBloodPressureBle => 'Hilo pressió arterial (BLE)';

  @override
  String get writeHeartDataToApple =>
      'Escriu les dades cardíaques a Apple Salut';

  @override
  String get writeWeightDataToApple => 'Escriu les dades de pes a Apple Salut';

  @override
  String get renphoScaleBle => 'Bàscula Renpho (BLE)';

  @override
  String get polarH10HrvStrapBle => 'Polar H10 (cinta VFC, BLE)';

  @override
  String get dataSourcePriority => 'Prioritat de les fonts de dades';

  @override
  String get whenMultipleSourcesProvideThe =>
      'Quan diverses fonts aporten la mateixa mètrica, guanya la que és més amunt. Arrossega per reordenar.';

  @override
  String get resetToDefault => 'Restableix els valors predeterminats';

  @override
  String get disconnect => 'Desconnecta';

  @override
  String get healthPage => 'Pàgina de salut';

  @override
  String get loadPage => 'Pàgina de càrrega';

  @override
  String get healthMonitor => 'Monitor de salut';

  @override
  String get hrZones => 'Zones de FC';

  @override
  String get t30MinTtAvailableSync =>
      'TT de 30 min disponible: sincronitza les zones de FC';

  @override
  String lt2Lt2BpmAt(Object lt2, Object at) {
    return 'LT2 $lt2 bpm · $at';
  }

  @override
  String get syncLabel => 'SINCRO';

  @override
  String get autoadjust => 'AJUST AUTOMÀTIC';

  @override
  String zoneI(Object i) {
    return 'Zona $i';
  }

  @override
  String get hrZones2 => 'ZONES DE FC';

  @override
  String ageRound(Object round) {
    return 'edat $round';
  }

  @override
  String get basics => 'Dades bàsiques';

  @override
  String get updateWaistMonthlyUsedFor =>
      'ⓘ Actualitza la cintura cada mes: serveix per estimar el greix visceral.';

  @override
  String get alcohol => 'Alcohol';

  @override
  String get t1Drink033L =>
      '1 beguda ≈ 0,33 l de cervesa / 0,2 l de vi / 4 cl de licor';

  @override
  String get clinicalLabsOptional => 'Anàlisis clíniques (opcional)';

  @override
  String get glycemic => 'Glucèmia';

  @override
  String get optimalForLongevity48 =>
      'Òptim per a la longevitat: 4,8–5,4 % · Prediabetis: 5,7–6,4 %';

  @override
  String get lipids => 'Lípids';

  @override
  String get apobReplacesLdlWhenBoth =>
      'L\'ApoB substitueix l\'LDL quan s\'introdueixen tots dos.';

  @override
  String get inflammationKidney => 'Inflamació i ronyó';

  @override
  String get changesAreSavedAutomatically =>
      'Els canvis es desen automàticament';

  @override
  String get optionalTotalClimbingForThis =>
      'Desnivell total opcional per a aquesta cursa.';

  @override
  String get moreAboutThisEvent => 'Més informació sobre aquest esdeveniment';

  @override
  String distanceOfDistancekmKm(Object distanceKm) {
    return 'Distància de $distanceKm km?';
  }

  @override
  String keepDistancekmKm(Object distanceKm) {
    return 'Mantén $distanceKm km';
  }

  @override
  String useLikelyKm(Object likely) {
    return 'Fes servir $likely km';
  }

  @override
  String get thisBackupContainsNoCalendar =>
      'Aquesta còpia de seguretat no conté activitats del calendari.';

  @override
  String get activities => 'Activitats';

  @override
  String get exportActivitiesCsv => 'Exporta les activitats a CSV';

  @override
  String get backupRestore => 'Còpia de seguretat i restauració';

  @override
  String get backup => 'Còpia de seguretat';

  @override
  String get restoreFromBackup => 'Restaura des d\'una còpia de seguretat';

  @override
  String get backupRestoredRestartTheApp =>
      'Còpia restaurada. Reinicia l\'aplicació per tornar a carregar tots els ajustos.';

  @override
  String get raceGoals => 'Objectius de cursa';

  @override
  String get yourActivities => 'Les teves activitats';

  @override
  String get usedByAiCoachAnd =>
      'L\'utilitzen l\'entrenador IA i el pla d\'entrenament. Els esports del pla es marquen amb ✦.';

  @override
  String get calendarWeekStart => 'Inici de setmana del calendari';

  @override
  String get planDefaultView => 'Vista predeterminada del pla';

  @override
  String get weeklySchedule => 'Horari setmanal';

  @override
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      trainingDaysPerWeek,
      locale: localeName,
      other: '$trainingDaysPerWeek dies d\'entrenament',
      one: '$trainingDaysPerWeek dia d\'entrenament',
    );
    return '$_temp0 · toca per alternar Entrenament / Descans / Força';
  }

  @override
  String get updatePlanToThisSchedule => 'Actualitza el pla a aquest horari';

  @override
  String get updateStrengthSessions => 'Actualitza les sessions de força';

  @override
  String get sessionsPerDay => 'Sessions per dia';

  @override
  String get canYouFitTwoWorkouts => 'Pots fer dos entrenaments en un dia?';

  @override
  String get strengthLoadUnit => 'Unitat de càrrega de força';

  @override
  String get weightsThemselvesAreSetIn =>
      'Els pesos es fixen en cada entrenament i es recorden a partir del teu historial.';

  @override
  String get hoursAvailableWeek => 'Hores disponibles / setmana';

  @override
  String hoursperweekHWeek(Object hoursPerWeek) {
    return '$hoursPerWeek h / setmana';
  }

  @override
  String hoursperweekH(Object hoursPerWeek) {
    return '$hoursPerWeek h';
  }

  @override
  String get heatAcclimation => 'Aclimatació a la calor';

  @override
  String get showHeatAcclimation => 'Mostra l\'aclimatació a la calor';

  @override
  String get weatherEvaluatedAgainstAConfigurable =>
      'El temps s\'avalua per a una ubicació configurable.';

  @override
  String get trainingPlan => 'Pla d\'entrenament';

  @override
  String get regenerateReplacesFutureSessionsAnd =>
      'Regenera substitueix les sessions futures i reconstrueix el pla des d\'avui amb els ajustos actuals.';

  @override
  String valueUpcomingWorkoutsGenerated(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value entrenaments propers generats',
      one: '$value entrenament proper generat',
    );
    return '$_temp0';
  }

  @override
  String get generationFailedCheckYourRace =>
      'No s\'ha pogut generar. Revisa el teu objectiu de cursa i torna-ho a provar.';

  @override
  String get deleteAllWorkouts => 'Elimina tots els entrenaments';

  @override
  String get changesAreSavedAutomatically2 =>
      '✓ Els canvis es desen automàticament';

  @override
  String countUpcomingWorkoutsGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrenaments propers generats',
      one: '$count entrenament proper generat',
    );
    return '$_temp0';
  }

  @override
  String get importRaceGoalsFromGarmin =>
      'Importa objectius de cursa des de Garmin';

  @override
  String get addRaceGoal => 'Afegeix un objectiu de cursa';

  @override
  String priorityTouppercase(Object toUpperCase) {
    return 'Prioritat $toUpperCase';
  }

  @override
  String get goalsAreSharedWithAi =>
      'Els objectius es comparteixen amb l\'entrenador IA. La prioritat A, B o C decideix com pondera el pla les teves curses.';

  @override
  String get deletingWorkouts => 'S\'estan eliminant els entrenaments';

  @override
  String get cityOrTown => 'Ciutat o poble';

  @override
  String get eGHannoverOrPalma => 'p. ex. Hannover o Palma';

  @override
  String get noCitiesFoundTryA =>
      'No s\'han trobat ciutats. Prova amb un poble proper.';

  @override
  String get chooseTheLocationForThe =>
      'Tria la ubicació per a la previsió del pla, el radar i l\'aclimatació a la calor. El temps funciona encara que l\'aclimatació estigui desactivada.';

  @override
  String get none => 'Cap';

  @override
  String get disableLocalWeatherAndLocation =>
      'Desactiva el temps local i les sol·licituds d\'ubicació';

  @override
  String get currentLocation => 'Ubicació actual';

  @override
  String get followYourDeviceLocation => 'Segueix la ubicació del dispositiu';

  @override
  String get fixedLocation => 'Ubicació fixa';

  @override
  String get chooseACityOrEnter => 'Tria una ciutat o introdueix coordenades';

  @override
  String get chooseCity => 'Tria una ciutat';

  @override
  String get coordinates => 'Coordenades';

  @override
  String get latitude => 'Latitud';

  @override
  String get longitude => 'Longitud';

  @override
  String get saveLocation => 'Desa la ubicació';

  @override
  String get refreshCurrentLocation => 'Actualitza la ubicació actual';

  @override
  String get citySearchOpenMeteoGeonames =>
      'Cerca de ciutats: Open-Meteo / GeoNames';

  @override
  String get cityNamesOpenstreetmap => 'Noms de ciutats: © OpenStreetMap';

  @override
  String get energy => 'ENERGIA';

  @override
  String get currentEnergy => 'ENERGIA ACTUAL';

  @override
  String get dailyTimeline => 'LÍNIA DE TEMPS DIÀRIA';

  @override
  String valueValue2(Object value, Object value2) {
    return '$value → $value2';
  }

  @override
  String get energy2 => 'Energia';

  @override
  String get noData => 'Sense dades';

  @override
  String get bloodPressureInsights => 'ANÀLISI DE PRESSIÓ ARTERIAL';

  @override
  String get sys => ' Sis';

  @override
  String get diaMmhg => ' Dia · mmHg';

  @override
  String get previousBloodPressurePeriod =>
      'Període de pressió arterial anterior';

  @override
  String get nextBloodPressurePeriod => 'Període de pressió arterial següent';

  @override
  String get nightDipping => 'Descens nocturn';

  @override
  String get noMeasurementsInThisPeriod =>
      'Sense mesuraments en aquest període';

  @override
  String get fullscreenBloodPressureChart =>
      'Gràfic de pressió arterial a pantalla completa';

  @override
  String get barsMinMaxLineDots =>
      'Barres: mín–màx · línia/punts: mitjana · toca o arrossega per inspeccionar';

  @override
  String get noMeasurements => 'Sense mesuraments';

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
      other: '$length mesuraments',
      one: '$length mesurament',
    );
    return '$_temp0 · mitjana / mín–màx';
  }

  @override
  String bloodPressureTouppercaseMmhg(Object toUpperCase) {
    return 'PRESSIÓ ARTERIAL · $toUpperCase · mmHg';
  }

  @override
  String get closeFullscreenBloodPressureChart =>
      'Tanca el gràfic de pressió arterial a pantalla completa';

  @override
  String get chooseScale => 'Tria una bàscula';

  @override
  String get noScalesFoundStepOn =>
      'No s\'ha trobat cap bàscula. Puja a la bàscula i torna-ho a provar.';

  @override
  String nameRssiDbm(Object name, Object rssi) {
    return '$name · $rssi dBm';
  }

  @override
  String get renphoSaved => 'RENPHO desada:';

  @override
  String get renphoScaleBle2 => 'Bàscula RENPHO (BLE)';

  @override
  String get changeMeasurementType => 'Canvia el tipus de mesurament';

  @override
  String get addMeasurement => 'Afegeix un mesurament';

  @override
  String get whatAreYouMeasuring => 'Què estàs mesurant?';

  @override
  String get chooseAnotherMeasurement => 'Tria un altre mesurament';

  @override
  String get saveMeasurement => 'Desa el mesurament';

  @override
  String get skip => 'Omet';

  @override
  String get connectHiloService => 'Connecta el servei Hilo';

  @override
  String get connectHilo => 'Connecta Hilo';

  @override
  String get connectCoros => 'Connecta Coros';

  @override
  String get europe => 'Europa';

  @override
  String get unitedStates => 'Estats Units';

  @override
  String get asia => 'Àsia';

  @override
  String get bluetoothBloodPressure => 'Bluetooth · pressió arterial';

  @override
  String get cloudCuffData => 'Núvol · dades del braçalet';

  @override
  String get apiSync => 'Sincronització per API';

  @override
  String get bluetoothHrvStrap => 'Bluetooth · cinta VFC';

  @override
  String get accesslinkApi => 'AccessLink API';

  @override
  String get systemHealthData => 'Dades de salut del sistema';

  @override
  String get cloudScaleHistory => 'Núvol · historial de la bàscula';

  @override
  String get bluetoothWeightBody => 'Bluetooth · pes i cos';

  @override
  String get connectYourDevices => 'Connecta els teus dispositius';

  @override
  String get continueLabel => 'Continua';

  @override
  String get connectGarmin => 'Connecta Garmin';

  @override
  String get connectAppleHealth => 'Connecta Apple Salut';

  @override
  String get dataSynced => 'DADES SINCRONITZADES';

  @override
  String get pairHiloPod => 'Vincula Hilo Pod';

  @override
  String get chooseStrap => 'Tria la cinta';

  @override
  String namePaired(Object name) {
    return '$name vinculat.';
  }

  @override
  String get pairPolarH10 => 'Vincula Polar H10';

  @override
  String get forget => 'Oblida';

  @override
  String get sendWorkoutToPolar => 'Envia l\'entrenament a Polar';

  @override
  String get connectPolar => 'Connecta Polar';

  @override
  String get signInWithPolarFlow => 'Inicia la sessió amb Polar Flow';

  @override
  String get syncsSleepStagesHrvResting =>
      'Sincronitza fases de la son · VFC · FC en repòs · entrenaments · passes';

  @override
  String savedForV(Object v) {
    return 'Desat per a $v';
  }

  @override
  String get remove => 'Elimina';

  @override
  String get polarEMail => 'Correu de Polar';

  @override
  String get polarPassword => 'Contrasenya de Polar';

  @override
  String get pairRenphoScale => 'Vincula la bàscula RENPHO';

  @override
  String get connectRenpho => 'Connecta Renpho';

  @override
  String get connectSuunto => 'Connecta Suunto';

  @override
  String smsSentToTrim(Object trim) {
    return 'SMS enviat a $trim';
  }

  @override
  String get resendSms => 'Torna a enviar l\'SMS';

  @override
  String get retryLoadingPreferences =>
      'Torna a provar de carregar les preferències';

  @override
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed) {
    return 'TEMPS D\'ENTRENAMENT SETMANAL · $toStringAsFixed h';
  }

  @override
  String get tapADayToCycle =>
      'Toca un dia per alternar Entrenament / Descans / Força.';

  @override
  String get doubleDayOk => 'Dia doble ok';

  @override
  String get birthYearOptional => 'Any de naixement (opcional)';

  @override
  String get addAnother => 'Afegeix-ne un altre';

  @override
  String get knowYourBodyTrainSmarter => 'Coneix el teu cos.\nEntrena millor.';

  @override
  String get allYourHealthDevicesOne =>
      'Tots els teus dispositius de salut. Una sola vista intel·ligent.';

  @override
  String get areYouReadyToTrain => 'Estàs a punt per entrenar avui?';

  @override
  String get hrvRecoveryScoreRestingHr =>
      'VFC · Puntuació de recuperació · FC en repòs';

  @override
  String get didYouActuallyRecoverLast =>
      'T\'has recuperat de debò aquesta nit?';

  @override
  String get sleepStagesDeepSleepSpo => 'Fases de la son · Son profund · SpO₂';

  @override
  String get isYourBloodPressureUnder =>
      'La teva pressió arterial està sota control?';

  @override
  String get continuousBpNightDippingTrends =>
      'Pressió contínua · Descens nocturn · Tendències';

  @override
  String get howHardDidYouPush => 'Quant t\'has exigit aquesta setmana?';

  @override
  String get trainingLoadTrimpStrainScore =>
      'Càrrega d\'entrenament · TRIMP · Puntuació d\'esforç';

  @override
  String get isYourBodyCompositionImproving =>
      'Millora la teva composició corporal?';

  @override
  String get weightBodyFatMuscleMass => 'Pes · Greix corporal · Massa muscular';

  @override
  String get getStarted => 'Comença';

  @override
  String get yourDataStaysOnYour =>
      'Les teves dades. Tu tries què comparteixes.';

  @override
  String get bodyScale => 'Bàscula corporal';

  @override
  String get bodyComposition => 'Composició corporal';

  @override
  String get sleep => 'SON';

  @override
  String get sleepPerformance => 'RENDIMENT DE LA SON';

  @override
  String get sleepHistory => 'Historial de la son';

  @override
  String labelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String lessLabel(Object label) {
    return 'Menys $label';
  }

  @override
  String moreLabel(Object label) {
    return 'Més $label';
  }

  @override
  String get gymMode => 'Mode gimnàs';

  @override
  String get finishWorkout => 'Acaba l\'entrenament';

  @override
  String get workoutActions => 'Accions de l\'entrenament';

  @override
  String get discardWorkout => 'Descarta l\'entrenament';

  @override
  String get allSetsRecorded => 'Totes les sèries registrades';

  @override
  String get reviewSets => 'Revisa les sèries';

  @override
  String get rest => 'DESCANS';

  @override
  String plannedResttarget(Object restTarget) {
    return 'Previst $restTarget';
  }

  @override
  String get startSet => 'Comença la sèrie';

  @override
  String get seconds => 'Segons';

  @override
  String get previousSet => 'Sèrie anterior';

  @override
  String get allSets => 'Totes les sèries';

  @override
  String get nextSet => 'Sèrie següent';

  @override
  String get everySetIsSavedAs =>
      'Cada sèrie es desa sobre la marxa. Pots tancar aquesta pantalla quan vulguis i reprendre des de l\'entrenament planificat.';

  @override
  String get cancel => 'Cancel·la';

  @override
  String get apply => 'Aplica';

  @override
  String get effortScale => 'Escala d\'esforç';

  @override
  String get setType => 'Tipus de sèrie';

  @override
  String get reps => 'Repeticions';

  @override
  String get range => 'Interval';

  @override
  String get time => 'Temps';

  @override
  String get t45Or100 => '45 o 1:00';

  @override
  String get blankWhenNotSet => 'En blanc si no es defineix';

  @override
  String get redBand => 'Banda vermella';

  @override
  String get t90Or130 => '90 o 1:30';

  @override
  String get blankWhenUnknown => 'En blanc si és desconegut';

  @override
  String get usePlannedLoad => 'Fes servir la càrrega planificada';

  @override
  String get blankWhenNotMeasured => 'En blanc si no es mesura';

  @override
  String get exercise => 'Exercici';

  @override
  String get changingTheLoadConventionStarts =>
      'Canviar la convenció de càrrega inicia un historial separat per a aquest exercici.';

  @override
  String get barbellMachine => 'Barra, màquina…';

  @override
  String get load => 'Càrrega';

  @override
  String get loadRefersTo => 'La càrrega fa referència a';

  @override
  String get t2ForAPair => '2 per a un parell';

  @override
  String get repetitions => 'Repeticions';

  @override
  String get availablePlatesOrDumbbells => 'Discos o manuelles disponibles';

  @override
  String get rememberForThisEquipment => 'Recorda per a aquest equipament';

  @override
  String get findOrNameAnExercise => 'Cerca o anomena un exercici';

  @override
  String createTrim(Object trim) {
    return 'Crea «$trim»';
  }

  @override
  String get customExercise => 'Exercici personalitzat';

  @override
  String get smallestLoadStep => 'Increment de càrrega mínim';

  @override
  String whatRemoved(Object what) {
    return '$what eliminat';
  }

  @override
  String get undo => 'Desfés';

  @override
  String get retry => 'Torna-ho a provar';

  @override
  String get performance => 'Rendiment';

  @override
  String get addExercise => 'Afegeix un exercici';

  @override
  String get finishLog => 'Acaba el registre';

  @override
  String get keepAsDraft => 'Mantén com a esborrany';

  @override
  String actionsForName(Object name) {
    return 'Accions per a $name';
  }

  @override
  String get editExercise => 'Edita l\'exercici';

  @override
  String get moveUp => 'Puja';

  @override
  String get moveDown => 'Baixa';

  @override
  String get addSet => 'Afegeix una sèrie';

  @override
  String get removeLastSet => 'Elimina l\'última sèrie';

  @override
  String get saveAsTemplate => 'Desa com a plantilla';

  @override
  String savedTitleAsATemplate(Object title) {
    return '«$title» desat com a plantilla. Aquest entrenament no canvia fins que el desis.';
  }

  @override
  String nameSetN(Object name, Object n) {
    return '$name · Sèrie $n';
  }

  @override
  String nameAllWorkingSets(Object name) {
    return '$name · Totes les sèries de treball';
  }

  @override
  String labelRest(Object label) {
    return 'Descans $label';
  }

  @override
  String get secondsOrMSs => 'Segons o m:ss';

  @override
  String get applyToAllSets => 'Aplica a totes les sèries';

  @override
  String get duplicate => 'Duplica';

  @override
  String get supersetWithNext => 'Superserie amb la següent';

  @override
  String get circuitWithNext => 'Circuit amb la següent';

  @override
  String actionsForSetN(Object n) {
    return 'Accions per a la sèrie $n';
  }

  @override
  String get editSet => 'Edita la sèrie';

  @override
  String get duplicateSet => 'Duplica la sèrie';

  @override
  String get removeSet => 'Elimina la sèrie';

  @override
  String labelActions(Object label) {
    return 'Accions de $label';
  }

  @override
  String get editRests => 'Edita els descansos';

  @override
  String get ungroup => 'Desagrupa';

  @override
  String get editExercises => 'Edita els exercicis';

  @override
  String get unsavedChanges => 'Canvis sense desar';

  @override
  String couldNotSaveError(Object error) {
    return 'No s\'ha pogut desar: $error';
  }

  @override
  String get history => 'Historial';

  @override
  String get exercises => 'Exercicis';

  @override
  String get noExercisesArePlannedFor =>
      'Encara no hi ha exercicis planificats per a aquest entrenament. Les notes de dalt el descriuen.';

  @override
  String get addExercises => 'Afegeix exercicis';

  @override
  String get fromTheBuiltInTemplate =>
      'De la plantilla integrada. Les càrregues les fixes tu; l\'historial apareix quan registris un entrenament.';

  @override
  String get shareExerciseList => 'Comparteix la llista d\'exercicis';

  @override
  String get noSavedStrengthTemplatesYet =>
      'Encara no hi ha plantilles de força desades. Desa\'n una des d\'un entrenament planificat.';

  @override
  String get compareWith => 'Compara amb';

  @override
  String estimated1rmUnit(Object unit) {
    return '1RM estimat $unit';
  }

  @override
  String get plannedNotRecorded => 'Planificat, no registrat';

  @override
  String get notes => 'Notes';

  @override
  String get editPerformance => 'Edita el rendiment';

  @override
  String get compareWithASavedWorkout => 'Compara amb un entrenament desat';

  @override
  String get sessions => 'Sessions';

  @override
  String get radarUnavailableRetry => 'Radar no disponible · Torna-ho a provar';

  @override
  String get radar => 'Radar';

  @override
  String get weatherDataByRainviewer => 'Dades meteorològiques de RainViewer';

  @override
  String get openstreetmapContributors => '© col·laboradors d\'OpenStreetMap';

  @override
  String get weather => 'Temps';

  @override
  String get weatherUnavailableRetry =>
      'Temps no disponible · Torna-ho a provar';

  @override
  String get chooseAFixedLocationIn =>
      'Tria una ubicació fixa a la configuració de Temps i ubicació, o permet l\'accés a la ubicació per al temps local.';

  @override
  String get locationSettings => 'Configuració d\'ubicació';

  @override
  String get retryLocation => 'Torna a provar la ubicació';

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
    return 'Bulb humit $toStringAsFixed°C';
  }

  @override
  String get previousForecastDay => 'Dia de previsió anterior';

  @override
  String get nextForecastDay => 'Dia de previsió següent';

  @override
  String daysDayForecast(Object days) {
    return 'Previsió a $days dies';
  }

  @override
  String thisProviderCurrentlySuppliesDays(Object days, Object days2) {
    return 'Aquest proveïdor ofereix actualment $days de $days2 dies de previsió.';
  }

  @override
  String get now => 'Ara';

  @override
  String get sunriseSunset => 'Sortida / posta de sol';

  @override
  String keyKey2(Object key, Object key2) {
    return '☀ $key   ☾ $key2';
  }

  @override
  String get use => 'Fes servir';

  @override
  String get exerciseDetailsWereNotProvided =>
      'Aquesta font d\'activitat no ha proporcionat detalls dels exercicis.';

  @override
  String get logFromPlan => 'Registra des del pla';

  @override
  String get addExerciseDetails => 'Afegeix detalls dels exercicis';

  @override
  String get loadSuggestion => 'Suggeriment de càrrega';

  @override
  String get applyToThisWorkout => 'Aplica a aquest entrenament';

  @override
  String get keepCurrentLoad => 'Mantén la càrrega actual';

  @override
  String get setLoadStep => 'Defineix l\'increment de càrrega';

  @override
  String get viewSupportingSets => 'Mostra les sèries de suport';

  @override
  String get supportingSets => 'Sèries de suport';

  @override
  String get noRecordedSessionsYet => 'Encara no hi ha sessions registrades.';

  @override
  String nameDemonstrationCue(Object name, Object cue) {
    return 'Demostració de $name. $cue';
  }

  @override
  String get noScalesFoundStepOn2 =>
      'No s\'ha trobat cap bàscula. Puja a la bàscula i torna-ho a provar.';

  @override
  String get scalePaired => 'Bàscula vinculada';

  @override
  String get ok => 'OK';

  @override
  String get pairedReadyToMeasure => '✓ Vinculat: a punt per mesurar';

  @override
  String get chooseHiloCuff => 'Tria el braçalet Hilo';

  @override
  String get noCuffFoundWakeYour =>
      'No s\'ha trobat cap braçalet. Desperta el braçalet i torna a cercar.';

  @override
  String get hiloCuffAktiiaC => 'Braçalet Hilo (AKTIIA C…)';

  @override
  String get onDemandBloodPressureVia =>
      'Pressió arterial sota demanda per BLE';

  @override
  String get selectHiloPodWristband => 'Selecciona Hilo Pod (polsera)';

  @override
  String get rescan => 'Torna a cercar';

  @override
  String get noDevicesFoundTapTo =>
      'No s\'han trobat dispositius. Toca ↻ per tornar a cercar.';

  @override
  String get polarH10SpotHrv => 'Polar H10 · VFC puntual';

  @override
  String get aSeparateHrvReadingBefore =>
      'Una mesura de VFC a part abans o després d\'entrenar. Aquestes mesures no substitueixen la VFC nocturna de Garmin ni canvien la teva puntuació de preparació.';

  @override
  String get wearTheStrapWithMoist =>
      'Posa\'t la cinta amb els elèctrodes humitejats. Queda\'t quiet i respira amb normalitat. Fes servir la mateixa postura i durada per comparar. Després d\'entrenar, anota quant has descansat abans.';

  @override
  String get measurement => 'Mesurament';

  @override
  String get posture => 'Postura';

  @override
  String get recordingLengthPlus1Min =>
      'Durada de l\'enregistrament · més 1 min d\'estabilització';

  @override
  String get t2Minutes => '2 minuts';

  @override
  String get t5Minutes => '5 minuts';

  @override
  String get minutesSinceTrainingEndedOptional =>
      'Minuts des que va acabar l\'entrenament (opcional)';

  @override
  String get sessionOrNotesOptional => 'Sessió o notes (opcional)';

  @override
  String connectName(Object name) {
    return 'Connecta $name';
  }

  @override
  String get findPolarH10 => 'Cerca Polar H10';

  @override
  String signalRssiDbm(Object rssi) {
    return 'Senyal $rssi dBm';
  }

  @override
  String connectedName(Object name) {
    return 'Connectat: $name';
  }

  @override
  String get waitingForHeartRateAnd =>
      'Esperant freqüència cardíaca i intervals RR. Comprova el contacte de la cinta.';

  @override
  String get startMeasurement => 'Inicia el mesurament';

  @override
  String get cancelMeasurement => 'Cancel·la el mesurament';

  @override
  String get spotHrvRmssd => 'VFC puntual · RMSSD';

  @override
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  ) {
    return '$accepted/$length intervals utilitzables · $toStringAsFixed % de cobertura';
  }

  @override
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs) {
    return 'lnRMSSD: $lnRmssd · RMSSD en brut: $rawRmssdMs ms';
  }

  @override
  String get signalQualityIsTooLow =>
      'La qualitat del senyal és massa baixa per desar. Repeteix el mesurament amb bon contacte de la cinta. Cal almenys un 95 % d\'intervals utilitzables i un 90 % de cobertura.';

  @override
  String get savedToSpotHrvHistory => 'Desat a l\'historial de VFC puntual.';

  @override
  String get newMeasurement => 'Nou mesurament';

  @override
  String get signalScreeningExcludesPoorContact =>
      'El filtratge del senyal exclou mal contacte, RR fora de 250–2500 ms i intervals a més del 25 % de la mediana local. Els buits no s\'omplen. No és una prova mèdica ni una puntuació de preparació independent.';

  @override
  String historyLabelLabel2DurationMin(
    Object label,
    Object label2,
    Object duration,
  ) {
    return 'Historial · $label · $label2 · $duration min';
  }

  @override
  String get onlyReadingsWithTheSame =>
      'Només es mostren juntes els mesuraments amb el mateix context, postura i durada.';

  @override
  String get noMatchingMeasurementsYet =>
      'Encara no hi ha mesuraments coincidents.';

  @override
  String tostringasfixedMsRmssdTostringasfixed2Bpm(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return '$toStringAsFixed ms RMSSD · $toStringAsFixed2 bpm';
  }

  @override
  String get exportRrIntervalsCsv => 'Exporta els intervals RR (CSV)';

  @override
  String get deleteMeasurement => 'Elimina el mesurament';

  @override
  String get remindMeToMeasureHrv =>
      'Recorda\'m mesurar la VFC després d\'entrenar';

  @override
  String get appleHealthIsNoLonger => 'Apple Salut ja no està disponible';

  @override
  String get later => 'Més tard';

  @override
  String get reconnect => 'Torna a connectar';

  @override
  String get gripStrength => 'Força de prensió';

  @override
  String get leftKg => 'Esquerra (kg)';

  @override
  String get rightKg => 'Dreta (kg)';

  @override
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg) {
    return 'E $leftKg · D $rightKg kg';
  }

  @override
  String get notificationsAreOffYouCan =>
      'Les notificacions estan desactivades. Encara pots mesurar des del teu entrenament.';

  @override
  String get noRemindersFrom2200 => 'Sense recordatoris de 22:00 a 07:00';

  @override
  String get aReminderThatWouldFall =>
      'Un recordatori que caigués en aquest horari s\'omet, no es passa al matí.';

  @override
  String get remindersArriveQuietlyInThe =>
      'Els recordatoris arriben en silenci a la llista de notificacions.';

  @override
  String get noForecastForThisDay => 'Sense previsió per a aquest dia';

  @override
  String get fullscreen => 'Pantalla completa';

  @override
  String source(Object source) {
    return '● $source';
  }

  @override
  String get temperatureC => '● Temperatura °C';

  @override
  String get rainMm => '▥ Pluja mm';

  @override
  String get uvIndex => '— Índex UV';

  @override
  String get closeFullscreenWeatherChart =>
      'Tanca el gràfic del temps a pantalla completa';

  @override
  String get sleepStages => 'FASES DE LA SON';

  @override
  String get noStageTimelineForThis =>
      'Sense línia de temps de fases per a aquesta nit.';

  @override
  String round3(Object round) {
    return '$round%';
  }

  @override
  String get examplesOnlyCheckAndEnter =>
      'Només exemples: comprova i introdueix els valors de l\'etiqueta del producte per ració. Deixa en blanc els nutrients desconeguts; introdueix 0 només si el valor és conegut.';

  @override
  String get nutritionStrategy => 'Estratègia de nutrició';

  @override
  String get noPreWorkoutNutritionStrategy =>
      'No s\'ha desat cap estratègia de nutrició prèvia a l\'entrenament.';

  @override
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium) {
    return '$carbs g de carbohidrats/h · $fluid ml/h · $sodium mg de sodi/h';
  }

  @override
  String get forecastUpdatedReviewOrRecalculate =>
      'Previsió actualitzada: revisa o recalcula l\'estratègia desada.';

  @override
  String strategySavedSavedat(Object savedAt) {
    return 'Estratègia desada $savedAt';
  }

  @override
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  ) {
    return 'Total durant: $totalCarbs g de carbohidrats · $totalFluid ml · $totalSodium mg de sodi';
  }

  @override
  String every20MinAboutCarbs(Object carbs, Object fluid) {
    return 'Cada 20 min: uns $carbs g de carbohidrats i $fluid ml.';
  }

  @override
  String get packQuantitiesIncludeFullContainers =>
      'Les quantitats a portar inclouen envasos complets; no cal consumir-ho tot.';

  @override
  String get workoutChangedReviewOrRecalculate =>
      'Entrenament modificat: revisa o recalcula l\'estratègia desada.';

  @override
  String get conditionsAndFeedingPlan => 'Condicions i pla d\'alimentació';

  @override
  String get editStrategy => 'Edita l\'estratègia';

  @override
  String get recalculate => 'Recalcula';

  @override
  String get actualNutrition => 'Nutrició real';

  @override
  String get someProductValuesAreUnknown =>
      'Alguns valors de productes es desconeixen; els totals són incomplets.';

  @override
  String get logFoodAndFluids => 'Registra menjar i líquids';

  @override
  String get recordWhatYouActuallyHad =>
      'Anota el que has pres realment. La ingesta planificada no es copia en aquest registre.';

  @override
  String get elapsedMinutesIncludingStopsOptional =>
      'Minuts transcorreguts, incloses les parades (opcional)';

  @override
  String recordedDurationActivityMin(Object activity) {
    return 'Durada registrada: $activity min';
  }

  @override
  String get compareWithSavedStrategy => 'Compara amb l\'estratègia desada';

  @override
  String get useMatchedSessionIfAvailable =>
      'Fes servir la sessió coincident si està disponible';

  @override
  String get noPlanComparison => 'Sense comparació amb el pla';

  @override
  String titleDate(Object title, Object date) {
    return '$title · $date';
  }

  @override
  String get linkedStrategyUnavailable => 'Estratègia vinculada no disponible';

  @override
  String quantityName(Object quantity, Object name) {
    return '$quantity × $name';
  }

  @override
  String get removeIntake => 'Elimina la ingesta';

  @override
  String get addFoodOrDrink => 'Afegeix menjar o beguda';

  @override
  String get iHadNoIntake => 'No he près res';

  @override
  String get giGutComfort => 'Comoditat digestiva';

  @override
  String get whatWorkedSymptomsAccessProblems =>
      'Què ha funcionat / símptomes / problemes d\'accés';

  @override
  String get saveDraft => 'Desa l\'esborrany';

  @override
  String get skipLoggingThisActivity => 'Omet el registre d\'aquesta activitat';

  @override
  String get nutritionAndFluids => 'Nutrició i hidratació';

  @override
  String get productsToleranceAndMeasuredSweat =>
      'Productes, tolerància i pèrdues de suor mesurades';

  @override
  String get postWorkoutIntakeReminder =>
      'Recordatori d\'ingesta després de l\'entrenament';

  @override
  String get onceAfterARecentEndurance =>
      'Una vegada després d\'un entrenament de resistència recent; hores de silenci 22:00–08:00.';

  @override
  String get addHiloBpReport => 'Afegeix un informe de pressió Hilo';

  @override
  String get readingPdfReportsIsOnly =>
      'La lectura d\'informes PDF només està disponible a iOS i macOS.';

  @override
  String get chooseAnotherReport => 'Tria un altre informe';

  @override
  String get biologicalAge => 'Edat biològica';

  @override
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class) {
    return 'VO₂max $vo2max ml/kg/min · $vo2Class';
  }

  @override
  String get factorContributions => 'Contribució dels factors';

  @override
  String estimatedRangeRoundRound2Years(Object round, Object round2) {
    return 'Interval estimat: $round–$round2 anys. Una estimació del model, no un diagnòstic mèdic.';
  }

  @override
  String get noEnergyMeasurementsForThis =>
      'Sense mesuraments d\'energia per a aquest dia';

  @override
  String get scanningStepOnTheScale =>
      'Cercant… puja a la bàscula quan estiguis a punt.';

  @override
  String waistWaistCmUpdateMonthly(Object waist) {
    return 'Cintura: $waist cm – actualitza cada mes a Perfil';
  }

  @override
  String get measuring => 'Mesurant…';

  @override
  String get tryAgain => 'Torna-ho a provar';

  @override
  String get systolic => 'Sistòlica';

  @override
  String get diastolic => 'Diastòlica';

  @override
  String get heartRate => 'Freqüència cardíaca';

  @override
  String get weight => 'Pes';

  @override
  String get bodyFat => 'Greix corporal';

  @override
  String get duration => 'Durada';

  @override
  String get deep => 'Profund';

  @override
  String get spo => 'SpO₂';

  @override
  String get activityName => 'Nom de l\'activitat';

  @override
  String get sport => 'Esport';

  @override
  String get distance => 'Distància';

  @override
  String get saved => 'Desat';

  @override
  String get connectionFailedCheckYourInternet =>
      'Error de connexió. Revisa la teva connexió a internet.';

  @override
  String get email => 'Correu electrònic';

  @override
  String get password => 'Contrasenya';

  @override
  String get passwordTooShort => 'Contrasenya massa curta';

  @override
  String get loginFailedCheckYourEmail =>
      'Error en iniciar la sessió. Revisa el teu correu i la contrasenya.';

  @override
  String get connectionFailedCheckYourCredentials =>
      'Error de connexió. Revisa les teves credencials i la connexió a internet.';

  @override
  String get region => 'Regió';

  @override
  String get hiloPod => 'Hilo Pod';

  @override
  String get hiloAccount => 'Compte de Hilo';

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
  String get renphoAccount => 'Compte de Renpho';

  @override
  String get garminConnectEmail => 'Correu de Garmin Connect';

  @override
  String get verifyMfaCode => 'Verifica el codi MFA';

  @override
  String get verificationCode => 'Codi de verificació';

  @override
  String errorE(Object e) {
    return 'Error: $e';
  }

  @override
  String get noHiloPodFoundMake =>
      'No s\'ha trobat cap Hilo Pod. Assegura\'t que estigui carregat i a prop.';

  @override
  String scanFailedE(Object e) {
    return 'Error en la cerca: $e';
  }

  @override
  String get hiloPod2 => 'Hilo Pod';

  @override
  String get scanForPod => 'Cerca el pod';

  @override
  String get scanForPolarH10 => 'Cerca Polar H10';

  @override
  String get couldNotReachPolarCheck =>
      'No s\'ha pogut connectar amb Polar. Revisa la connexió.';

  @override
  String get signInAndSendWorkout => 'Inicia la sessió i envia l\'entrenament';

  @override
  String get scanForScale => 'Cerca la bàscula';

  @override
  String get passwordRequired => 'Contrasenya obligatòria';

  @override
  String get enterYourPhoneNumberWith =>
      'Introdueix el teu número de telèfon (amb prefix del país, p. ex. +34…) i el correu de Suunto.';

  @override
  String get enterThePinFromThe => 'Introdueix el PIN de l\'SMS.';

  @override
  String get incorrectPinPleaseTryAgain => 'PIN incorrecte. Torna-ho a provar.';

  @override
  String get phoneNumber => 'Número de telèfon';

  @override
  String get suuntoAccountEmail => 'Correu del compte de Suunto';

  @override
  String get enterPinFromSms => 'Introdueix el PIN de l\'SMS';

  @override
  String get verifyConnect => 'Verifica i connecta';

  @override
  String get sendSmsCode => 'Envia el codi per SMS';

  @override
  String couldNotSavePreferencesE(Object e) {
    return 'No s\'han pogut desar les preferències: $e';
  }

  @override
  String get mon => 'Dl';

  @override
  String get tue => 'Dt';

  @override
  String get wed => 'Dc';

  @override
  String get thu => 'Dj';

  @override
  String get fri => 'Dv';

  @override
  String get sat => 'Ds';

  @override
  String get sun => 'Dg';

  @override
  String get male => 'Home';

  @override
  String get female => 'Dona';

  @override
  String get other => 'Altre';

  @override
  String get running => 'Cursa';

  @override
  String get trailRunning => 'Trail running';

  @override
  String get cycling => 'Ciclisme';

  @override
  String get swimming => 'Natació';

  @override
  String get triathlon => 'Triatló';

  @override
  String get hiking => 'Excursionisme';

  @override
  String get rowing => 'Rem';

  @override
  String get buildMyPlan => 'Crea el meu pla';

  @override
  String get keepAConsistentBedtimeAnd =>
      'Mantén horaris constants per anar a dormir i llevar-te per donar suport a la teva rutina de son.';

  @override
  String get thisWorkoutHasNoSets => 'Aquest entrenament no té sèries.';

  @override
  String loadName(Object name) {
    return 'Càrrega ($name)';
  }

  @override
  String get setLabel => 'Sèrie';

  @override
  String get lowestReps => 'Repeticions mínimes';

  @override
  String get highestReps => 'Repeticions màximes';

  @override
  String get repsPerSide => 'Repeticions per costat';

  @override
  String get fromReps => 'Des de (rep.)';

  @override
  String get toReps => 'Fins a (rep.)';

  @override
  String get addedLoad => 'Càrrega afegida';

  @override
  String get assistance => 'Assistència';

  @override
  String get tempoOptional => 'Ritme (opcional)';

  @override
  String get notesOptional => 'Notes (opcional)';

  @override
  String get enterTheRepetitionsDone => 'Introdueix les repeticions fetes.';

  @override
  String plannedUnit(Object unit) {
    return 'Previst $unit';
  }

  @override
  String get repsDone => 'Repeticions fetes';

  @override
  String get resistance => 'Resistència';

  @override
  String get implementsLabel => 'Implements';

  @override
  String get name => 'Nom';

  @override
  String get instructionsOptional => 'Instruccions (opcional)';

  @override
  String get remember => 'Recorda';

  @override
  String get notSavedYet => 'Encara sense desar';

  @override
  String get saving => 'Desant…';

  @override
  String get couldNotSave => 'No s\'ha pogut desar';

  @override
  String get plannedValuesAreHintsNot =>
      'Els valors planificats són orientatius, no resultats. Toca una sèrie per registrar-la.';

  @override
  String get completedAsPlanned => 'Completat tal com estava planificat';

  @override
  String get save => 'Desa';

  @override
  String get nameTheTemplate => 'Posa nom a la plantilla.';

  @override
  String setN(Object n) {
    return 'Sèrie $n';
  }

  @override
  String get changesApplyToThisWorkout =>
      'Els canvis s\'apliquen només a aquest entrenament. Els entrenaments completats i les altres sessions no canvien.';

  @override
  String get saveForThisWorkout => 'Desa per a aquest entrenament';

  @override
  String knownForKnownOfOf(Object known, Object of) {
    return 'Conegut en $known de $of sèries amb càrrega';
  }

  @override
  String get sessionEstimate => 'Estimació de la sessió';

  @override
  String get calculatedRange => 'Interval calculat';

  @override
  String get timedWork => 'Treball cronometrat';

  @override
  String get strengthTraining => 'Entrenament de força';

  @override
  String get theExercisesCouldNotBe =>
      'No s\'han pogut carregar els exercicis.';

  @override
  String get resumeWorkout => 'Reprèn l\'entrenament';

  @override
  String get strengthWorkout => 'Entrenament de força';

  @override
  String get untitledTemplate => 'Plantilla sense títol';

  @override
  String get theRecordedExercisesCouldNot =>
      'No s\'han pogut carregar els exercicis registrats.';

  @override
  String get exercisesPerformed => 'Exercicis fets';

  @override
  String get comparedWithThePlanAs =>
      'Comparat amb el pla tal com estava en començar el registre.';

  @override
  String topWorkingLoadName(Object name) {
    return 'Càrrega de treball màxima ($name)';
  }

  @override
  String get estimated1rmMiddleOfRange => '1RM estimat, mig de l\'interval';

  @override
  String get noLoggedSessionsYet => 'Encara no hi ha sessions registrades.';

  @override
  String get noRadarFramesAvailable => 'No hi ha imatges de radar disponibles';

  @override
  String get playRadar => 'Reprodueix el radar';

  @override
  String get pauseRadar => 'Posa el radar en pausa';

  @override
  String get high => 'Alt';

  @override
  String get clear => 'Serè';

  @override
  String get bodyweight => 'Pes corporal';

  @override
  String get resistance2 => 'Resistència —';

  @override
  String assistUnit(Object unit) {
    return 'Assistència $unit';
  }

  @override
  String get reps2 => 'Rep. —';

  @override
  String get notRecorded => 'No registrat';

  @override
  String get skipped => 'Omès';

  @override
  String get health => 'Salut';

  @override
  String get manual => 'Manual';

  @override
  String expandName(Object name) {
    return 'Amplia $name';
  }

  @override
  String get open => 'Obre';

  @override
  String get noScalePaired => 'Cap bàscula vinculada';

  @override
  String get paired => 'Vinculat';

  @override
  String get change => 'Canvia';

  @override
  String get noCuffPaired => 'Cap braçalet vinculat';

  @override
  String get noPolarH10FoundWear =>
      'No s\'ha trobat cap Polar H10. Posa\'t la cinta, humiteja els elèctrodes i comprova que cap altra aplicació no estigui fent servir les dues connexions Bluetooth.';

  @override
  String get enterMinutesSinceTrainingEnded =>
      'Introdueix els minuts des que va acabar l\'entrenament, de 0 a 1440.';

  @override
  String get timingFollowsYourWorkout =>
      'El moment segueix el teu entrenament.';

  @override
  String get recordingStayStill => 'Gravant · queda\'t quiet';

  @override
  String get meanHrBpm => 'FC mitjana · bpm';

  @override
  String get pairAPolarH10First => 'Vincula primer un Polar H10.';

  @override
  String get around30MinutesAfterTraining =>
      'Uns 30 minuts després d\'entrenar, quan l\'entrenament està disponible a temps.';

  @override
  String get reminderDiagnostics => 'Diagnòstic dels recordatoris';

  @override
  String get forecast => 'Previsió';

  @override
  String forecastRange(int count) {
    return 'Àrea ombrejada: rang de $count previsions';
  }

  @override
  String get enterAName => 'Introdueix un nom';

  @override
  String get enterAValidAmount => 'Introdueix una quantitat vàlida';

  @override
  String get enterAPositiveAmount => 'Introdueix una quantitat positiva';

  @override
  String get maximum120GH => 'Màxim 120 g/h';

  @override
  String get carbohydrateTargetGH => 'Objectiu de carbohidrats g/h';

  @override
  String get fluidTargetMlH => 'Objectiu de líquids ml/h';

  @override
  String get sodiumTargetMgHNot => 'Objectiu de sodi mg/h (no sal)';

  @override
  String get surfaceFeedingAccess => 'Superfície / accés a l\'avituallament';

  @override
  String get expectedAscentM => 'Desnivell previst m';

  @override
  String get expectedAltitudeM => 'Altitud prevista m';

  @override
  String get humidity => 'Humitat %';

  @override
  String get windKmH => 'Vent km/h';

  @override
  String get dayForecast => 'Previsió del dia';

  @override
  String get enteredConditions => 'Condicions introduïdes';

  @override
  String get productFoodName => 'Nom del producte / aliment';

  @override
  String get servingsQuantity => 'Racions / quantitat';

  @override
  String get when => 'Quan';

  @override
  String get carbohydrateGServing => 'Carbohidrats g / ració';

  @override
  String get fluidMlServing => 'Líquid ml / ració';

  @override
  String get caffeineMgServing => 'Cafeïna mg / ració';

  @override
  String get proteinGServing => 'Proteïnes g / ració';

  @override
  String get gel => 'Gel';

  @override
  String get water => 'Aigua';

  @override
  String get sportsDrink => 'Beguda esportiva';

  @override
  String get bar => 'Barreta';

  @override
  String get finishIntakeLog => 'Acaba el registre d\'ingesta';

  @override
  String get importing => 'Important…';

  @override
  String importNewreadings(Object newReadings) {
    return 'Importa $newReadings';
  }

  @override
  String get reading => 'Llegint…';

  @override
  String get chooseReportPdf => 'Tria un informe (PDF)';

  @override
  String get yourTrainingHistoryIsReady =>
      'El teu historial d\'entrenament està a punt';

  @override
  String get importingYourTrainingHistory =>
      'S\'està important el teu historial d\'entrenament';

  @override
  String get stopImport => 'Atura la importació';

  @override
  String get dismiss => 'Descarta';

  @override
  String get openai => 'OpenAI';

  @override
  String get appleIntelligence => 'Apple Intelligence';

  @override
  String get nonAiBriefing => 'Resum sense IA';

  @override
  String get noBriefing => 'Sense resum';

  @override
  String get ruleBasedSummaryFromYour =>
      'Resum basat en regles amb les teves dades de salut, sense crides a l\'API';

  @override
  String get hideTheBriefingCard => 'Amaga la targeta de resum';

  @override
  String get flutter => 'Flutter';

  @override
  String get stateManagement => 'Gestió d\'estat';

  @override
  String get bluetoothLe => 'Bluetooth LE';

  @override
  String get interactiveMaps => 'Mapes interactius';

  @override
  String get chartsGraphs => 'Gràfics i diagrames';

  @override
  String get secureCredentialStorage => 'Emmagatzematge segur de credencials';

  @override
  String get markdownRendering => 'Renderització de Markdown';

  @override
  String get appleOnDeviceAi => 'IA d\'Apple al dispositiu';

  @override
  String get cryptography => 'Criptografia';

  @override
  String get appleHealthHealthConnect => 'Apple Salut i Health Connect';

  @override
  String get runtimePermissions => 'Permisos en temps d\'execució';

  @override
  String get shareExport => 'Comparteix i exporta';

  @override
  String get openUrls => 'Obre URL';

  @override
  String get internationalisation => 'Internacionalització';

  @override
  String get utilities => 'Utilitats';

  @override
  String get icons => 'Icones';

  @override
  String get fjelia => 'Fjelia';

  @override
  String get fjeliaFeedback => 'Comentaris sobre Fjelia';

  @override
  String get couldNotSendTheReport =>
      'No s\'ha pogut enviar l\'informe. El teu text continua aquí. Torna-ho a provar.';

  @override
  String get yourEmail => 'El teu correu electrònic';

  @override
  String get enterAValidEmailAddress =>
      'Introdueix una adreça de correu vàlida.';

  @override
  String get subject => 'Assumpte';

  @override
  String get sending => 'Enviant…';

  @override
  String get sendReport => 'Envia l\'informe';

  @override
  String get sleepRecovery => 'Son i recuperació';

  @override
  String get activitiesTraining => 'Activitats i entrenament';

  @override
  String get bodyWellness => 'Cos i benestar';

  @override
  String get hilo => 'Hilo';

  @override
  String get hiloBle => 'Hilo BLE';

  @override
  String get garminApi => 'Garmin (API)';

  @override
  String get renphoScale => 'Bàscula Renpho';

  @override
  String get connected => 'Connectat';

  @override
  String get notConnected => 'No connectat';

  @override
  String get manage => 'Gestiona';

  @override
  String get connect => 'Connecta';

  @override
  String get habits => 'Hàbits';

  @override
  String get smokingAlcohol => 'Tabac, alcohol';

  @override
  String get clinicalLab => 'Anàlisis clíniques';

  @override
  String get hba1cLipidsKidney => 'HbA1c, lípids, ronyó';

  @override
  String get sex => 'Sexe';

  @override
  String get smoking => 'Tabaquisme';

  @override
  String get never => 'Mai';

  @override
  String get former => 'Anterior';

  @override
  String get current => 'Actual';

  @override
  String get hba1c => 'HbA1c';

  @override
  String get diabetes => 'Diabetis';

  @override
  String get prediabetes => 'Prediabetis';

  @override
  String get type1 => 'Tipus 1';

  @override
  String get type2 => 'Tipus 2';

  @override
  String get apob => 'ApoB';

  @override
  String get optionalPlansAndPaceGuides =>
      'Opcional. Els plans i les guies de ritme ho fan servir; el desnivell de dalt també influeix en l\'entrenament.';

  @override
  String get addRaceGoal2 => 'Afegeix un objectiu de cursa';

  @override
  String get editRaceGoal => 'Edita l\'objectiu de cursa';

  @override
  String get trailRunning2 => 'Trail running';

  @override
  String get roadCycling => 'Ciclisme de carretera';

  @override
  String get gravel => 'Gravel';

  @override
  String get indoorRowing => 'Rem indoor';

  @override
  String get selectDate => 'Selecciona la data';

  @override
  String get committed => 'Confirmat';

  @override
  String get flexible => 'Flexible';

  @override
  String get notGoing => 'No hi aniré';

  @override
  String get notSaid => 'No indicat';

  @override
  String get finish => 'Temps final';

  @override
  String get saveGoal => 'Desa l\'objectiu';

  @override
  String get exportAllRecordedWorkoutsAs =>
      'Exporta tots els entrenaments registrats com a full de càlcul.';

  @override
  String get backupsIncludeYourHealthData =>
      'Les còpies de seguretat inclouen les teves dades de salut, plans d\'entrenament i ajustos del perfil. Les credencials d\'accés s\'exclouen. Restaurar substitueix les dades locals.';

  @override
  String get trail => 'Trail';

  @override
  String get inlineSkating => 'Patinatge en línia';

  @override
  String get nordicClassic => 'Esquí nòrdic clàssic';

  @override
  String get skateSkiing => 'Esquí d\'skating';

  @override
  String get strength => 'Força';

  @override
  String get walking => 'Caminar';

  @override
  String get yoga => 'Ioga';

  @override
  String get skiing => 'Esquí';

  @override
  String get climbing => 'Escalada';

  @override
  String get monday => 'Dilluns';

  @override
  String get sunday => 'Diumenge';

  @override
  String get month => 'Mes';

  @override
  String get week => 'Setmana';

  @override
  String get list => 'Llista';

  @override
  String get train => 'Entrenar';

  @override
  String get restDay => 'Descans';

  @override
  String get kilogramsKg => 'Quilograms (kg)';

  @override
  String get poundsLb => 'Lliures (lb)';

  @override
  String get regenerateWorkouts => 'Regenera els entrenaments';

  @override
  String get starting => 'Iniciant';

  @override
  String get allPlannedWorkoutsDeleted =>
      'S\'han eliminat tots els entrenaments planificats.';

  @override
  String get searching => 'Cercant…';

  @override
  String get searchCity => 'Cerca una ciutat';

  @override
  String get fixedLocationSavedWeatherWill =>
      'Ubicació fixa desada. El temps s\'actualitzarà.';

  @override
  String get locationDisabledThePlanWeather =>
      'Ubicació desactivada. La targeta del temps del pla està amagada.';

  @override
  String locationSetToName(Object name) {
    return 'Ubicació establerta a $name';
  }

  @override
  String get notEnoughDaytimeAndNighttime =>
      'No hi ha prou mesuraments diürns i nocturns';

  @override
  String get onlyTheWeightWasReceived =>
      'Només s\'ha rebut el pes. Per al greix corporal, el múscul i la resta de valors, queda\'t descalç sobre els elèctrodes metàl·lics fins que la bàscula acabi.';

  @override
  String get addYourWaistInProfile =>
      'Afegeix la cintura a Perfil per al greix visceral.';

  @override
  String get manualActivity => 'Activitat manual';

  @override
  String get theseCredentialsAreStoredEncrypted =>
      'Aquestes credencials es desen xifrades al teu dispositiu (clauer d\'iOS / Android Keystore). Mai s\'envien a cap servidor que no sigui Hilo.';

  @override
  String get corosCredentialsAreStoredEncrypted =>
      'Les credencials de Coros es desen xifrades al teu dispositiu. Fjelia llegeix les dades directament de l\'API al núvol de Coros, la mateixa que fa servir l\'aplicació web Coros Training Hub.';

  @override
  String get connectAnyCombinationYouCan =>
      'Connecta qualsevol combinació: sempre podràs afegir-ne més després a Configuració.';

  @override
  String get garminCredentialsAreStoredEncrypted =>
      'Les credencials de Garmin es desen xifrades al teu dispositiu. Fjelia fa servir l\'API no oficial de Garmin Connect, el mateix enfocament que moltes aplicacions de la comunitat.';

  @override
  String get enterTheVerificationCode => 'Introdueix el codi de verificació';

  @override
  String get appleHealthDataAccess =>
      'Fjelia llegeix les teves dades de salut d\'Apple Salut. Amb el teu permís, també hi pot escriure dades sincronitzades. Gestiona l\'accés als ajustos del dispositiu.';

  @override
  String get scanAgain => 'Torna a cercar';

  @override
  String get wearTheHiloBandDuring =>
      'Porta la polsera Hilo durant la son per a un registre continu de la pressió arterial. Les dades se sincronitzen automàticament cada matí en obrir l\'aplicació.';

  @override
  String get noPolarH10FoundWear2 =>
      'No s\'ha trobat cap Polar H10. Posa\'t la cinta amb els elèctrodes humits i assegura\'t que cap altra aplicació (o rellotge) hi estigui connectada; després torna a cercar.';

  @override
  String get wearTheStrapWithMoist2 =>
      'Posa\'t la cinta amb els elèctrodes humits abans de cercar. Mesura després amb + → Mesurament de VFC amb Polar H10; els resultats apareixen al costat de la teva VFC nocturna.';

  @override
  String get signedInPlannedWorkoutsCan =>
      'Sessió iniciada. Ara es poden enviar entrenaments planificats a Polar. Les sessions anteriors s\'importen amb la propera sincronització completa de l\'historial.';

  @override
  String get saveYourPolarFlowLogin =>
      'Desa el teu inici de sessió de Polar Flow per enviar entrenaments planificats i importar sessions de més de 30 dies. Es queda al clauer d\'aquest dispositiu i només s\'envia a Polar. Envia un entrenament des del full del planificador i després sincronitza Polar Flow amb el teu rellotge. Comprova que les teves zones de freqüència cardíaca de Polar coincideixin amb les de Fjelia.';

  @override
  String get signInToSendThis =>
      'Inicia la sessió per enviar aquest entrenament al teu calendari de Polar Flow. El teu inici de sessió es queda al clauer d\'aquest dispositiu i només s\'envia a Polar. Després d\'enviar-lo, sincronitza Polar Flow amb el teu rellotge.';

  @override
  String get checkAndSave => 'Comprova i desa';

  @override
  String get noScaleFoundStepOn =>
      'No s\'ha trobat cap bàscula. Puja a la bàscula perquè es desperti i torna a cercar.';

  @override
  String get stepOnTheScaleBefore =>
      'Puja a la bàscula abans de cercar perquè es desperti. Després fes servir + → Bàscula RENPHO per mesurar.';

  @override
  String get renphoCredentialsAreStoredEncrypted =>
      'Les credencials de Renpho es desen xifrades al teu dispositiu. Fjelia es comunica directament amb l\'API al núvol de Renpho.';

  @override
  String get couldNotSendSmsCheck =>
      'No s\'ha pogut enviar l\'SMS. Revisa el teu número de telèfon i la connexió a internet.';

  @override
  String get theEmailIsUsedFor =>
      'El correu s\'utilitza per signar les sol·licituds de manera segura i no s\'envia als servidors de Suunto.';

  @override
  String get suuntoUsesSmsVerificationSame =>
      'Suunto fa servir verificació per SMS (igual que l\'aplicació de Suunto). S\'enviarà un PIN d\'un sol ús al teu telèfon. Les teves credencials es desen xifrades només al dispositiu.';

  @override
  String get tellUsAboutYourRace =>
      'Explica\'ns la teva cursa i el teu horari. Fjelia crea ara el teu pla i dedueix el teu nivell de les teves activitats passades (Garmin, Suunto, Polar, COROS, Apple Salut) quan es descarreguin.';

  @override
  String get noAccountConnectedSoFjelia =>
      'No hi ha cap compte connectat, així que Fjelia no té historial d\'on aprendre. Connecta Garmin, Suunto, Polar, COROS o Apple Salut i decidirà el teu entrenament real.';

  @override
  String get yourPastActivitiesAreStill =>
      'Les teves activitats passades encara s\'estan important. Pots crear el teu pla ara: es refinarà automàticament quan acabi la importació.';

  @override
  String get buildingYourPlan => 'Creant el teu pla…';

  @override
  String get saveContinue => 'Desa i continua';

  @override
  String get addYourMainPriorityA =>
      'Afegeix la teva cursa principal (prioritat A). El pla es periodifica cap a ella: base, desenvolupament, pic i afinament. Sense objectiu de cursa encara no es genera cap pla.';

  @override
  String get noMeasurementsYet => 'Encara no hi ha mesuraments';

  @override
  String get date => 'Data';

  @override
  String deepSleepIsBelowOptimal(Object round) {
    return 'La son profund està per sota de l\'òptim ($round %). Evita l\'alcohol i els àpats abundants 3 h abans d\'anar a dormir.';
  }

  @override
  String get finishWithSetsOpen => 'Acabar amb sèries obertes?';

  @override
  String get completeThePlannedWorkout =>
      'Completar l\'entrenament planificat?';

  @override
  String get marksThePlannedSessionAs =>
      'Marca la sessió planificada com a feta amb aquest entrenament.';

  @override
  String get discardThisWorkout => 'Descartar aquest entrenament?';

  @override
  String get removesTheWorkoutAndEvery =>
      'Elimina l\'entrenament i cada sèrie registrada.';

  @override
  String assistanceName(Object name) {
    return 'Assistència ($name)';
  }

  @override
  String get enterSecondsOrMSs => 'Introdueix segons o m:ss.';

  @override
  String get enterTheLoadAsA => 'Introdueix la càrrega com a número.';

  @override
  String get loadCannotBeNegative => 'La càrrega no pot ser negativa.';

  @override
  String get enterTheEffortValue => 'Introdueix el valor d\'esforç.';

  @override
  String get nameTheExercise => 'Posa nom a l\'exercici.';

  @override
  String get atLeastOneImplement => 'Almenys un implement.';

  @override
  String get anIncrementMustBePositive => 'Un increment ha de ser positiu.';

  @override
  String get enterAPositiveStep => 'Introdueix un increment positiu.';

  @override
  String get repsInReserve => 'Repeticions en reserva';

  @override
  String get loadPerImplement => 'Càrrega per implement';

  @override
  String get restAfterThisSet => 'Descans després d\'aquesta sèrie';

  @override
  String get enterHowLongTheSet => 'Introdueix quant va durar la sèrie.';

  @override
  String get repsDonePerSide => 'Repeticions fetes per costat';

  @override
  String plannedRepminRepmax(Object repMin, Object repMax) {
    return 'Previst $repMin–$repMax';
  }

  @override
  String get restTakenBeforeTheNext => 'Descans pres abans de la sèrie següent';

  @override
  String get equipment => 'Equipament';

  @override
  String get implementsUsedTogether => 'Implements utilitzats junts';

  @override
  String get smallestLoadStepOptional =>
      'Increment de càrrega mínim (opcional)';

  @override
  String get theSmallestChangeYourPlates =>
      'El canvi més petit que permeten els teus discos, manuelles o màquina, recordat per a aquest equipament.';

  @override
  String get loadStep => 'Increment de càrrega';

  @override
  String get finishWithIncompleteData => 'Acabar amb dades incompletes?';

  @override
  String get leaveWithoutSaving => 'Sortir sense desar?';

  @override
  String get theLastChangeCouldNot => 'No s\'ha pogut desar l\'últim canvi.';

  @override
  String get comparedWithAPlanChosen =>
      'Comparat amb un pla triat després de l\'entrenament. Els valors planificats són orientatius, no resultats.';

  @override
  String get lastSet => 'Última sèrie';

  @override
  String get templateName => 'Nom de la plantilla';

  @override
  String get betweenExercises => 'Entre exercicis';

  @override
  String get betweenRounds => 'Entre rondes';

  @override
  String get discardChanges => 'Descartar els canvis?';

  @override
  String get yourEditsToThisWorkout =>
      'Els teus canvis en aquest entrenament no estan desats.';

  @override
  String get estimatedDuration => 'Durada estimada';

  @override
  String get workingSets => 'Sèries de treball';

  @override
  String get estimatedExternalVolume => 'Volum extern estimat';

  @override
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion) {
    return 'Càrrega augmentada de $unit a $unit2 després de la teva revisió (regla v$ruleVersion).';
  }

  @override
  String get thePlannedWorkoutHasNo =>
      'L\'entrenament planificat no té exercicis per registrar.';

  @override
  String get completedSets => 'Sèries completades';

  @override
  String get knownExternalVolume => 'Volum extern conegut';

  @override
  String get updateStrengthSessions2 => 'Actualitzar les sessions de força?';

  @override
  String get upcomingSessionsArePlannedAgain =>
      'Les properes sessions es planifiquen de nou des d\'avui: la força segueix els teus objectius de cursa cada dia de força, amb sessions variades. Els entrenaments completats i omesos es mantenen; els exercicis que has canviat en una propera sessió de força se substitueixen.';

  @override
  String get thisSessionUsesAnEarlier =>
      'Aquesta sessió fa servir una plantilla de força anterior. Els plans actualitzats varien la força segons la fase i l\'objectiu de cursa i fan servir cada dia de força.';

  @override
  String get estimated1rmUsesEpleyAnd =>
      'L\'1RM estimat fa servir Epley i Brzycki en sèries de treball completades d\'1–10 repeticions amb càrrega coneguda i es mostra com l\'interval entre tots dos. És una estimació, no un màxim comprovat.';

  @override
  String get localWeather => 'Temps local';

  @override
  String get today => 'Avui';

  @override
  String get low => 'Baix';

  @override
  String get moderate => 'Moderat';

  @override
  String get overcast => 'Ennuvolat';

  @override
  String get partlyCloudy => 'Parcialment ennuvolat';

  @override
  String collapseName(Object name) {
    return 'Replega $name';
  }

  @override
  String get variableLoads => 'Càrregues variables';

  @override
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  ) {
    return 'Regla v$strengthProgressionRuleVersion: les últimes $strengthProgressionMinSessions sessions comparables, cada sèrie al màxim del seu objectiu de repeticions, amb esforç registrat i no més dur del previst. $reason';
  }

  @override
  String get stepOnYourScaleBefore => 'Puja a la bàscula abans de cercar';

  @override
  String get scanning => 'Cercant…';

  @override
  String get pair => 'Vincula';

  @override
  String get selectYourAktiiaPWristband =>
      'Selecciona la teva polsera AKTIIA P…. Posa-la al carregador per despertar-la si no apareix.';

  @override
  String get measurementInterruptedWhileTheApp =>
      'Mesurament interromput mentre l\'aplicació era en segon pla. Repeteix-lo.';

  @override
  String get noRecentRrDataWith =>
      'Sense dades RR recents amb bon contacte. Revisa la cinta i repeteix el mesurament.';

  @override
  String get settlingStayStill => 'Estabilitzant · queda\'t quiet';

  @override
  String get deleteSpotHrvMeasurement =>
      'Eliminar el mesurament de VFC puntual?';

  @override
  String get thisRemovesTheRecordingAnd =>
      'Això elimina l\'enregistrament i els seus intervals RR en brut.';

  @override
  String get appleHealthStoppedAnsweringSo =>
      'Apple Salut ha deixat de respondre, així que Fjelia l\'ha desconnectat i ja no llegeix ni escriu dades de salut.\n\nPermet de nou Fjelia a Configuració → Salut → Accés a dades i dispositius → Fjelia i torna a connectar Apple Salut.';

  @override
  String get thisRemovesTheSelectedGrip =>
      'Això elimina el mesurament de força de prensió seleccionat.';

  @override
  String get hideReminderDiagnostics => 'Amaga el diagnòstic dels recordatoris';

  @override
  String get loading => 'Carregant…';

  @override
  String get touchTheChartForDetails => 'Toca el gràfic per veure els detalls';

  @override
  String get indoor => 'Interior';

  @override
  String get road => 'Carretera';

  @override
  String get technical => 'Tècnic';

  @override
  String get snow => 'Neu';

  @override
  String get pool => 'Piscina';

  @override
  String get openWater => 'Aigües obertes';

  @override
  String get ambientTemperatureC => 'Temperatura ambient °C';

  @override
  String carryAboutGelsGelsGelcarbs(
    Object gels,
    Object gelCarbs,
    Object bottles,
    Object bottleMl,
    Object drinkCarbs,
  ) {
    return 'Porta uns $gels gels ($gelCarbs g de carbohidrats cadascun) + $bottles × ampolles de $bottleMl ml. $drinkCarbs g de carbohidrats provenen de la pols de beguda.';
  }

  @override
  String get intakeNotRecorded => 'Ingesta no registrada';

  @override
  String get loggingDeclinedIntakeUnknown =>
      'Registre rebutjat: ingesta desconeguda';

  @override
  String get confirmedNoIntake => 'Confirmat: sense ingesta';

  @override
  String get draft => 'Esborrany · ';

  @override
  String get actualIntakePerServing => 'Ingesta real · per ració';

  @override
  String get minuteIntoWorkoutDuringOnly =>
      'Minut de l\'entrenament (només durant, opcional)';

  @override
  String get sodiumMgServingNotSalt => 'Sodi mg / ració (no sal)';

  @override
  String get comfortable => 'Còmode';

  @override
  String get mildSymptoms => 'Símptomes lleus';

  @override
  String get moderateSymptoms => 'Símptomes moderats';

  @override
  String get severeSymptoms => 'Símptomes greus';

  @override
  String get personalNutritionSettings => 'Configuració personal de nutrició';

  @override
  String get practisedCarbohydrateToleranceGH =>
      'Tolerància als carbohidrats entrenada g/h (fins a 120)';

  @override
  String get exportTheMonthlyReportAs =>
      'Exporta l\'informe mensual com a PDF a l\'aplicació de Hilo i tria\'l aquí. Només s\'importen els mesuraments; el nom, el correu i les dades corporals de l\'informe s\'ignoren.';

  @override
  String get nothingNewAllReadingsWere =>
      'Res de nou: tots els mesuraments ja estaven desats.';

  @override
  String get historyImportIncomplete => 'Importació de l\'historial incompleta';

  @override
  String get youCanKeepUsingFjelia =>
      'Pots continuar fent servir Fjelia, però mantén-la oberta: iOS posa en pausa la importació quan l\'aplicació és en segon pla i continua la propera vegada que l\'obris. El teu pla es calibra en acabar la importació.';

  @override
  String get addYourBirthYearIn =>
      'Afegeix el teu any de naixement a Configuració → Perfil per veure la teva estimació.';

  @override
  String get fitnessAge => 'Edat de forma';

  @override
  String get estLifespan => 'Esperança de vida est.';

  @override
  String get delta => 'Diferència';

  @override
  String couldNotOpenKey(Object key) {
    return 'No s\'ha pogut obrir $key';
  }

  @override
  String get appleIntelligenceIsNotAvailable =>
      'Apple Intelligence no està disponible en aquest dispositiu. Fes servir Free AI o tria un altre proveïdor.';

  @override
  String get personalisedMorningLunchAfternoonEvening =>
      'Resum personalitzat de matí, migdia, tarda i vespre';

  @override
  String get enterASubject => 'Introdueix un assumpte.';

  @override
  String get message => 'Missatge';

  @override
  String get enterAMessageOfAt =>
      'Introdueix un missatge d\'almenys 10 caràcters.';

  @override
  String get garminConnect => 'Garmin Connect';

  @override
  String get hiloBloodPressure => 'Hilo (pressió arterial)';

  @override
  String get renphoBodyScale => 'Renpho (bàscula corporal)';

  @override
  String get hiloPodCuff => 'Hilo Pod / braçalet';

  @override
  String disconnectLabel(Object label) {
    return 'Desconnectar $label?';
  }

  @override
  String get yourSavedMeasurementsWillRemain =>
      'Els teus mesuraments desats romandran en aquest dispositiu.';

  @override
  String get notEnoughRecentHeartRate =>
      'No hi ha prou dades recents de freqüència cardíaca per ajustar les zones.';

  @override
  String get aerobicBase => 'Base aeròbica';

  @override
  String get tempo => 'Tempo';

  @override
  String get lactateThreshold => 'Llindar de lactat';

  @override
  String get birthYearHeightWaist => 'Any de naixement, alçada, cintura';

  @override
  String get enterAValidValue => 'Introdueix un valor vàlid';

  @override
  String get birthYear => 'Any de naixement';

  @override
  String get height => 'Alçada';

  @override
  String get waist => 'Cintura';

  @override
  String get yearsSinceQuit => 'Anys des que ho vas deixar';

  @override
  String get cigarettesPerDay => 'Cigarretes al dia';

  @override
  String get standardDrinksPerMonth => 'Begudes estàndard al mes';

  @override
  String get enterAValidNumber => 'Introdueix un número vàlid';

  @override
  String get enterARaceName => 'Introdueix el nom de la cursa';

  @override
  String get useHMmOrH =>
      'Fes servir h:mm o h:mm:ss, un temps que realment podries córrer';

  @override
  String get flexibleThePlanMayDrop =>
      'Flexible: el pla pot descartar aquest esdeveniment si xoca amb un de més important.';

  @override
  String get selectARaceDate => 'Selecciona una data de cursa';

  @override
  String thatIsTenTimesOr(Object likely) {
    return 'És deu vegades (o una desena part de) els $likely km habituals. Fer servir $likely km en el seu lloc?';
  }

  @override
  String get addGoal => 'Afegeix l\'objectiu';

  @override
  String get restoreFailed => 'Error en restaurar';

  @override
  String get replaceLocalData => 'Substituir les dades locals?';

  @override
  String get restoringThisBackupReplacesAll =>
      'Restaurar aquesta còpia de seguretat substitueix tots els registres locals de salut i entrenament. Es conserven les credencials d\'accés existents.';

  @override
  String get openingBackupZip =>
      'S\'està obrint el ZIP de la còpia de seguretat';

  @override
  String get addAFutureRaceGoal => 'Afegeix primer un objectiu de cursa futur.';

  @override
  String get deleteAllWorkouts2 => 'Eliminar tots els entrenaments?';

  @override
  String get thisDeletesPlannedWorkoutsOn =>
      'Això elimina els entrenaments planificats en aquest telèfon i a la plataforma del teu rellotge connectat. Les activitats completades es conserven.';

  @override
  String get regenerateWorkouts2 => 'Regenerar els entrenaments?';

  @override
  String get noRaceGoalsYetAdd =>
      'Encara no hi ha objectius de cursa. Afegeix-ne un o sincronitza des de Garmin.';

  @override
  String get deleteRaceGoal => 'Eliminar l\'objectiu de cursa?';

  @override
  String deletingFailedFailure(Object failure) {
    return 'Error en eliminar: $failure';
  }

  @override
  String allPlannedWorkoutsDeletedRemoved(Object removed) {
    return 'S\'han eliminat tots els entrenaments planificats. Eliminats de les teves plataformes: $removed.';
  }

  @override
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return 'Fent servir la ubicació actual: $toStringAsFixed, $toStringAsFixed2';
  }

  @override
  String get typeSleep => 'Son';

  @override
  String get typeBloodPressure => 'Pressió arterial';

  @override
  String get addHiloBpReportPdf => 'Afegeix un informe de pressió Hilo (PDF)';

  @override
  String get hiloCuffBle => 'Braçalet Hilo (BLE)';

  @override
  String get typeSpo2 => 'SpO₂ / pulsioxímetre';

  @override
  String get typeWeightScale => 'Bàscula de pes';

  @override
  String get polarH10HrvMeasurement => 'Mesurament de VFC amb Polar H10';

  @override
  String samplingWouldStartMinutes(Object minutes) {
    return 'El mostreig començaria uns $minutes min després d\'acabar l\'entrenament.';
  }

  @override
  String samplingStartedMinutes(Object minutes) {
    return 'El mostreig va començar $minutes min després d\'acabar l\'entrenament.';
  }

  @override
  String get unknown => 'Desconegut';

  @override
  String get before => 'Abans';

  @override
  String get during => 'Durant';

  @override
  String get after => 'Després';

  @override
  String get enumWarmUp => 'Escalfament';

  @override
  String get enumWorking => 'De treball';

  @override
  String get enumBackOff => 'Back-off';

  @override
  String get enumTechnique => 'Tècnica';

  @override
  String get enumExternalLoad => 'Càrrega externa';

  @override
  String get enumBandResistance => 'Banda / resistència';

  @override
  String get enumTotalLoad => 'Càrrega total';

  @override
  String get enumPerImplement => 'Per implement';

  @override
  String get enumOneImplement => 'Un implement';

  @override
  String get enumBothSides => 'Els dos costats';

  @override
  String get enumAlternatingTotalReps => 'Alternat, repeticions totals';

  @override
  String get enumPartial => 'Parcial';

  @override
  String get enumFailed => 'Fallida';

  @override
  String get enumStraightSets => 'Sèries convencionals';

  @override
  String get enumSuperset => 'Superserie';

  @override
  String get enumCircuit => 'Circuit';

  @override
  String get enumRir => 'RIR';

  @override
  String get enumRpe110 => 'RPE 1–10';

  @override
  String get enumBeforeTraining => 'Abans de l\'entrenament';

  @override
  String get enumAfterTraining => 'Després de l\'entrenament';

  @override
  String get enumResting => 'En repòs';

  @override
  String get enumSeated => 'Assegut';

  @override
  String get enumLyingDown => 'Estirat';

  @override
  String get duringRoutineGelsAreNot =>
      'Durant: no calen gels de rutina en aquesta sessió curta/fàcil. Beu segons la set.';

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      'Durant: reparteix els carbohidrats i les begudes en preses petites i regulars. Compta els carbohidrats de la beguda en el mateix total que gels i menjar.';

  @override
  String get fluidIsAnEditableStarting =>
      'Els líquids són una estimació inicial editable, no una quota. Guia\'t per la set, la ingesta habitual i les pèrdues de suor mesurades; no forcis més aigua.';

  @override
  String get afterHaveCarbohydrateAndA =>
      'Després: pren carbohidrats i un àpat amb proteïnes. Prioritza la recuperació i la rehidratació si hi ha una altra sessió aviat.';

  @override
  String get swimmingPlaceALabelledBottle =>
      'Natació: deixa una ampolla etiquetada a la vora de la piscina i aprofita les pauses entre sèries per beure o alimentar-te. Les condicions de la piscina poden diferir del temps exterior.';

  @override
  String get runningCarryAccessibleGelsFlasks =>
      'Cursa: porta gels/flasks accessibles o planifica l\'avituallament als punts; practica els mateixos productes i temps abans de competir.';

  @override
  String get servingSizesAndToleranceMust =>
      'Les mides de ració i la tolerància han de ser positives.';

  @override
  String get enterFiniteNonNegativeMeasurements =>
      'Introdueix mesuraments finits i no negatius.';

  @override
  String get targetsMustBeFiniteAnd =>
      'Els objectius han de ser finits i no negatius.';

  @override
  String get conditionsMustBeFiniteOr =>
      'Les condicions han de ser finites o desconegudes.';

  @override
  String get humidityMustBeBetween0 =>
      'La humitat ha d\'estar entre 0 i 100 %.';

  @override
  String get noIntakeCannotIncludeFood =>
      '«Sense ingesta» no pot incloure menjar ni begudes.';

  @override
  String get addAnItemOrConfirm =>
      'Afegeix un element o confirma que no has près res.';

  @override
  String get eachIntakeNeedsAProduct =>
      'Cada ingesta necessita un producte i un moment vàlid.';

  @override
  String get quantityMustBePositive => 'La quantitat ha de ser positiva.';

  @override
  String get thisActivityNoLongerExists => 'Aquesta activitat ja no existeix.';

  @override
  String get practisedCarbohydrateToleranceMustNot =>
      'La tolerància als carbohidrats entrenada no ha de superar 120 g/h.';

  @override
  String get measuredSweatRateMustBe =>
      'La taxa de sudoració mesurada ha de ser positiva o deixar-se desconeguda.';

  @override
  String get increasePractisedToleranceInNutrition =>
      'Augmenta la tolerància entrenada a la configuració de nutrició abans de triar un objectiu més alt.';

  @override
  String get fluidTargetExceedsYourMeasured =>
      'L\'objectiu de líquids supera la teva taxa de sudoració mesurada. Revisa el mesurament o l\'objectiu.';

  @override
  String get elapsedWorkoutTimeMustBe =>
      'El temps d\'entrenament transcorregut ha de ser positiu o deixar-se en blanc.';

  @override
  String get intakeAmountsMustBeFinite =>
      'Les quantitats d\'ingesta han de ser finites i no negatives.';

  @override
  String get selectedStrategyUnavailableChooseAnother =>
      'L\'estratègia seleccionada no està disponible. Tria una altra estratègia o cap comparació.';

  @override
  String get recordYourWorkoutNutrition =>
      'Registra la teva nutrició de l\'entrenament';

  @override
  String get addTheFoodAndFluids =>
      'Afegeix el menjar i els líquids que has près realment a l\'historial de l\'activitat.';

  @override
  String get logIntake => 'Registra la ingesta';

  @override
  String nutritionReminderTitle(String name) {
    return 'Nova activitat: $name';
  }

  @override
  String get nutritionReminderBody => 'Afegeix el que has menjat i begut.';

  @override
  String get nutritionReminderHrvHint =>
      'Encara no has mesurat la VFC després de l\'entrenament.';

  @override
  String get in30Minutes => 'D\'aquí a 30 minuts';

  @override
  String get loadSuggestionsCoverStraightSets =>
      'Els suggeriments de càrrega només s\'apliquen a sèries convencionals amb repeticions.';

  @override
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  ) {
    return 'Cal $strengthProgressionMinSessions sessions registrades d\'aquest exercici.';
  }

  @override
  String get recentHistoryIsTooOld =>
      'L\'historial recent és massa antic per a un suggeriment.';

  @override
  String get theLastSessionDidNot =>
      'L\'última sessió no va fer servir una única càrrega coneguda.';

  @override
  String get theLoadChangedBetweenThe =>
      'La càrrega ha canviat entre les sessions recents.';

  @override
  String get notEverySetReachedThe =>
      'No totes les sèries han arribat al màxim del seu objectiu de repeticions.';

  @override
  String get recordEffortRirOrRpe =>
      'Registra l\'esforç (RIR o RPE) a l\'última sèrie per obtenir suggeriments.';

  @override
  String get recentSetsWereHarderThan =>
      'Les sèries recents van ser més dures del previst.';

  @override
  String get thisWorkoutAlreadyHasIts =>
      'Aquest entrenament ja té la seva pròpia càrrega; es manté com està.';

  @override
  String get yourRecentSetsMetThe =>
      'Les teves sèries recents han complert la regla de progressió. Defineix el mínim increment de càrrega d\'aquest equipament per revisar una càrrega.';

  @override
  String get thisWorkoutNoLongerExists => 'Aquest entrenament ja no existeix.';

  @override
  String thisStrengthPlanCannotBe(Object message) {
    return 'Aquest pla de força no es pot llegir ($message).';
  }

  @override
  String get thisStrengthPlanCannotBe2 =>
      'Aquest pla de força no es pot llegir.';

  @override
  String get addAtLeastOneExercise => 'Afegeix almenys un exercici.';

  @override
  String get thisWorkoutWasChangedElsewhere =>
      'Aquest entrenament s\'ha canviat en un altre lloc. Els teus canvis es conserven; recarrega per veure la versió més recent.';

  @override
  String get thePlanThisWorkoutIs =>
      'El pla amb el qual es compara aquest entrenament no es pot llegir.';

  @override
  String get thisLogWasChangedElsewhere =>
      'Aquest registre s\'ha canviat en un altre lloc. Les teves entrades es conserven; recarrega per veure la versió més recent.';

  @override
  String get thisZipIsNotA =>
      'Aquest ZIP no és una còpia de seguretat de Fjelia compatible.';

  @override
  String get theBackupDatabaseIsDamaged =>
      'La base de dades de la còpia de seguretat està malmesa.';

  @override
  String get invalidBackupData => 'Dades de còpia de seguretat no vàlides.';

  @override
  String get backupTablesDoNotMatch =>
      'Les taules de la còpia de seguretat no coincideixen.';

  @override
  String get invalidBackupColumns =>
      'Columnes de còpia de seguretat no vàlides.';

  @override
  String get migratingOriginalAppBackup =>
      'S\'està migrant la còpia de seguretat de l\'aplicació original';

  @override
  String get theOriginalBackupIsMissing =>
      'Falten taules necessàries a la còpia de seguretat original.';

  @override
  String get backupFormatOrDatabaseVersion =>
      'El format de la còpia de seguretat o la versió de la base de dades no coincideix.';

  @override
  String get restoringRecords => 'Restaurant registres';

  @override
  String get restoringSettings => 'Restaurant ajustos';

  @override
  String get restoreComplete => 'Restauració completada';

  @override
  String get effortMustBeANumber => 'L\'esforç ha de ser un número.';

  @override
  String get theDurationEstimateMustBe =>
      'L\'estimació de durada ha de ser positiva.';

  @override
  String get restCannotBeNegative => 'El descans no pot ser negatiu.';

  @override
  String get enterTheRepetitionsDoneThe =>
      'Introdueix les repeticions fetes; el pla té un interval.';

  @override
  String get enterTheLoadThePlan =>
      'Introdueix la càrrega; el pla no en té cap.';

  @override
  String get enterTheResistanceThePlan =>
      'Introdueix la resistència; el pla no en té cap.';

  @override
  String get poorSensorContact => 'Mal contacte del sensor';

  @override
  String get moreThan25FromLocal => 'A més del 25 % de la mediana local';

  @override
  String get workoutNutrition => 'Nutrició de l\'entrenament';

  @override
  String get postWorkoutFoodAndFluid =>
      'Recordatori del registre de menjar i líquids després de l\'entrenament';

  @override
  String get postTrainingHrvMeasurementReminder =>
      'Recordatori de mesurament de VFC després de l\'entrenament';

  @override
  String get rirRunsFrom0To => 'RIR va de 0 a 10+.';

  @override
  String get rpeRunsFrom1To => 'RPE va d\'1 a 10.';

  @override
  String get repetitionsCannotBeNegative =>
      'Les repeticions no poden ser negatives.';

  @override
  String get timedWorkMustBeLonger =>
      'El treball cronometrat ha de durar més de zero segons.';

  @override
  String get chooseRepetitionsOrTimedWork =>
      'Tria repeticions o treball cronometrat, no tots dos.';

  @override
  String get loadMustBeAFinite =>
      'La càrrega ha de ser un nombre finit i no negatiu.';

  @override
  String get durationCannotBeNegative => 'La durada no pot ser negativa.';

  @override
  String get hrTimeline => 'Línia de temps de FC';

  @override
  String get dayTrainingLoad => 'Càrrega d\'entrenament diària';

  @override
  String get weekdayComparison => 'Comparació per dia de la setmana';

  @override
  String get weeklyTrainingLoad => 'Càrrega d\'entrenament setmanal';

  @override
  String get zonePolarization => 'Polarització de zones';

  @override
  String get elevationOverview => 'Resum de desnivell';

  @override
  String get trainingMonitor => 'Monitor d\'entrenament';

  @override
  String get formAtlCtlTsb => 'Forma ATL / CTL / TSB';

  @override
  String get trainingPlanProgress => 'Progrés del pla d\'entrenament';

  @override
  String get rhrSleep => 'FC en repòs (son)';

  @override
  String get hrvSleep => 'VFC (son)';

  @override
  String get spo2Sleep => 'SpO₂ (son)';

  @override
  String get respRate => 'Freqüència respiratòria';

  @override
  String get stress => 'Estrès';

  @override
  String get skinTemp => 'Temperatura de la pell';

  @override
  String get steps => 'Passes';

  @override
  String get tonightsSleep => 'Son d\'aquesta nit';

  @override
  String get activityLog => 'Registre d\'activitat';

  @override
  String get activityLog2 => 'Registre d\'activitat';

  @override
  String get history2 => 'HISTORIAL';

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
  String get heatAcclimation2 => 'ACLIMATACIÓ A LA CALOR';

  @override
  String score(Object score) {
    return '$score%';
  }

  @override
  String get elevation => 'DESNIVELL';

  @override
  String get t12WeekHistory => 'HISTORIAL DE 12 SETMANES';

  @override
  String get zonePolarization2 => 'POLARITZACIÓ DE ZONES';

  @override
  String get t5WeekHistory => 'HISTORIAL DE 5 SETMANES';

  @override
  String get easy => 'FÀCIL %';

  @override
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded) {
    return '$withZones de $recorded activitats amb dades de zones de FC';
  }

  @override
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples) {
    return '$fromSamples reconstruïdes a partir de les mostres de FC registrades';
  }

  @override
  String get easyZ12ModerateZ3 => 'Fàcil: Z1–2 · Moderat: Z3 · Dur: Z4–5';

  @override
  String get activitiesWithoutHrZoneData =>
      'Les activitats sense dades de zones de FC s\'exclouen dels percentatges.';

  @override
  String avgAverageUnit(Object average, Object unit) {
    return 'MIT $average $unit';
  }

  @override
  String get weekdayComparison2 => 'COMPARACIÓ PER DIA DE LA SETMANA';

  @override
  String get trainingPlanProgress2 => 'PROGRÉS DEL PLA D\'ENTRENAMENT';

  @override
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  ) {
    return 'Setmana $currentWeek / $durationInWeeks';
  }

  @override
  String get t30MinTimeTrialLt2 => 'CONTRARELLOTGE DE 30 MIN – LT2';

  @override
  String get run30MinutesAtThe =>
      'Corre 30 minuts al màxim esforç que puguis mantenir: controlat, sense esprintar. Entra progressivament en l\'esforç; no surtis massa ràpid. El ritme i la FC mitjans dels últims 20 minuts són la teva LT2.';

  @override
  String get recordAsANormalOutdoor =>
      'Registra-ho com una cursa normal a l\'aire lliure. Inicia el rellotge, anota l\'hora i corre 30 min a ritme de competició.';

  @override
  String get t50MinTotalFlatCourse =>
      '~50 min en total · recorregut pla · no després d\'un entrenament dur';

  @override
  String get doNotStartTooFast =>
      'No surtis massa ràpid. Busca parcials regulars.';

  @override
  String get theAppAveragesHrAnd =>
      'L\'aplicació fa la mitjana de la FC i el ritme dels últims 20 minuts de la prova, després de l\'escalfament i els primers 10 minuts. Selecciona l\'activitat registrada a Calcula.';

  @override
  String get lt2Pace => 'RITME LT2';

  @override
  String get activityRunningEnoughTimeFor =>
      'Activitat (cursa, temps suficient per a escalfament + 30 min, amb FC)';

  @override
  String get selectTheTtActivity => 'Selecciona l\'activitat de la prova';

  @override
  String nameStartdate(Object name, Object startDate) {
    return '$name · $startDate';
  }

  @override
  String get warmUpBeforeTt => 'Escalfament abans de la prova';

  @override
  String roundMin(Object round) {
    return '$round min';
  }

  @override
  String get clearResults => 'Esborra els resultats';

  @override
  String get heartRate2 => 'FREQÜÈNCIA CARDÍACA';

  @override
  String get paceSecKmLowerIs => 'Ritme (s/km – més baix és més ràpid)';

  @override
  String get thresholdsFitnessTests => 'Llindars i proves de forma';

  @override
  String get lt1 => 'LT1';

  @override
  String get lt2 => 'LT2';

  @override
  String get voPace => 'Ritme VO₂';

  @override
  String get ftp => 'FTP';

  @override
  String get setFtpManually => 'Defineix la FTP manualment';

  @override
  String get calculateFromAnActivity => 'Calcula a partir d\'una activitat';

  @override
  String get setFtp => 'Defineix la FTP';

  @override
  String get ftpWatts => 'FTP (watts)';

  @override
  String get ftpCyclingThresholdPower => 'FTP – POTÈNCIA LLINDAR EN CICLISME';

  @override
  String get ftpHistory => 'HISTORIAL DE FTP';

  @override
  String get updateFromActivity => 'ACTUALITZA DES D\'UNA ACTIVITAT';

  @override
  String get tapAnActivityFtpBest =>
      'Toca una activitat – FTP = millor potència de 20 min × 0,95';

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
      'Cap sortida amb 20 minuts de mostres de potència contínues.';

  @override
  String get enterFtpManually => 'Introdueix la FTP manualment';

  @override
  String get selectTheTestActivity => 'Selecciona l\'activitat de la prova';

  @override
  String get formAtlCtlTsb2 => 'FORMA · ATL / CTL / TSB';

  @override
  String get closeTrainingFormFullscreen =>
      'Tanca la forma d\'entrenament a pantalla completa';

  @override
  String get expandTrainingForm => 'Amplia la forma d\'entrenament';

  @override
  String get calculatedFromTheFirstAvailable =>
      'Calculat des del primer registre de càrrega disponible. Els dies sense càrrega registrada compten com a zero; l\'entrenament anterior es desconeix.';

  @override
  String get trainingMonitor2 => 'MONITOR D\'ENTRENAMENT';

  @override
  String get pfitzingerZones => 'ZONES DE PFITZINGER';

  @override
  String get cyclingPowerZones => 'ZONES DE POTÈNCIA EN CICLISME';

  @override
  String znumber(Object number) {
    return 'Z$number';
  }

  @override
  String paceHrDescription(Object pace, Object hr, Object description) {
    return '$pace · $hr\n$description';
  }

  @override
  String get weeklyTrainingLoad2 => 'CÀRREGA D\'ENTRENAMENT SETMANAL';

  @override
  String get prevWeek => 'SETM. ANT.';

  @override
  String get bySport => 'PER ESPORT';

  @override
  String get noActivitiesThisWeek => 'Cap activitat aquesta setmana';

  @override
  String garminWorkoutScheduleddate(Object scheduledDate) {
    return 'Entrenament Garmin · $scheduledDate';
  }

  @override
  String get yourNote => 'La teva nota';

  @override
  String get askAiCoach => 'Pregunta a l\'entrenador IA';

  @override
  String get aiSettings => 'Configuració d\'IA';

  @override
  String get askYourCoach => 'Pregunta al teu entrenador…';

  @override
  String get sendMessage => 'Envia el missatge';

  @override
  String get sendFeedbackOrReportA => 'Envia comentaris o informa d\'un error';

  @override
  String get addMeasurement2 => 'Afegeix un mesurament';

  @override
  String get syncLabel2 => 'Sincronitza';

  @override
  String get syncToday => 'Sincronitza avui';

  @override
  String get fullSync1Year => 'Sincronització completa · 1 any';

  @override
  String get fullSyncComplete => 'Sincronització completa · Completada';

  @override
  String get syncingYourData => 'Sincronitzant les teves dades…';

  @override
  String lLeftkgRRightkgKg2(Object leftKg, Object rightKg) {
    return 'E $leftKg  D $rightKg kg';
  }

  @override
  String weightKgFatBodyfatMuscle(
    Object weight,
    Object bodyFat,
    Object muscleMass,
  ) {
    return '$weight kg · Greix $bodyFat % · Múscul $muscleMass kg';
  }

  @override
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase) {
    return '$title, $sport, $toLowerCase';
  }

  @override
  String get weatherUnavailableTapToRetry =>
      'Temps no disponible · Toca per tornar-ho a provar';

  @override
  String get weatherSetYourLocation => 'Temps · Defineix la teva ubicació';

  @override
  String get t7DayForecast => 'PREVISIÓ A 7 DIES';

  @override
  String get minMax => 'mín/màx';

  @override
  String get rainMm2 => 'pluja mm';

  @override
  String get uvMax => 'UV màx.';

  @override
  String get kmH => 'km/h';

  @override
  String alt(Object alt) {
    return '→ $alt';
  }

  @override
  String raceGoalsLength(Object length) {
    return 'Objectius de cursa · $length';
  }

  @override
  String gWk(Object g) {
    return '$g setm.';
  }

  @override
  String weeks(Object weeks) {
    return '$weeks';
  }

  @override
  String get weeks2 => 'setmanes';

  @override
  String get upcoming => 'PROPERS';

  @override
  String lengthMoreDays(Object length) {
    return '+ $length dies més';
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
  String get plannedCompletedSkipped => '○ Planificat   ● Completat   ✕ Omès';

  @override
  String get heartRate3 => 'Freqüència cardíaca';

  @override
  String get watts => 'Watts';

  @override
  String theStepsAddUpTo(Object total, Object plannedDurationMin) {
    return 'Els passos sumen $total; el pla compta $plannedDurationMin min.';
  }

  @override
  String get typicalSplitForThisKind =>
      'Repartiment típic per a aquest tipus de sessió; no hi ha passos per calcular-lo.';

  @override
  String labelGetsEachExerciseWith(Object label) {
    return '$label rep cada exercici amb les seves sèries, repeticions i càrregues. Els rangs de repeticions, l\'esforç i el tempo es queden a Fjelia.';
  }

  @override
  String get markAsRest => 'Marca com a descans';

  @override
  String get restoreWorkout => 'Restaura l\'entrenament';

  @override
  String get skipThisWorkout => 'Ometre aquest entrenament?';

  @override
  String get previousWeek => 'Setmana anterior';

  @override
  String get backToThisWeek => 'Torna a aquesta setmana';

  @override
  String get thisWeek => 'Aquesta setmana';

  @override
  String get nextWeek => 'Setmana següent';

  @override
  String get today2 => 'AVUI';

  @override
  String get route => 'RUTA';

  @override
  String get feedback => 'Comentaris';

  @override
  String get plannedWorkout => 'Entrenament planificat';

  @override
  String get delete => 'Elimina';

  @override
  String get chatAi => 'Xat amb IA';

  @override
  String get trainingLoad => 'Càrrega d\'entrenament';

  @override
  String get dayTrainingLoad2 => 'CÀRREGA D\'ENTRENAMENT DIÀRIA';

  @override
  String get trimp => ' TRIMP';

  @override
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter) {
    return '$scoreBefore → $scoreAfter';
  }

  @override
  String get temperatureOverTime => 'TEMPERATURA AL LLARG DEL TEMPS';

  @override
  String roundh(Object round) {
    return '${round}h';
  }

  @override
  String get timeInHrZones => 'Temps en zones de FC';

  @override
  String get route2 => 'Ruta';

  @override
  String get start => 'Sortida';

  @override
  String get gpx => 'GPX';

  @override
  String touppercasesubstringBriefing(Object toUpperCase, Object substring) {
    return 'Resum de $toUpperCase$substring';
  }

  @override
  String get chatWithAiAboutThis => 'Xateja amb la IA sobre aquest resum';

  @override
  String get whyThisRecommendation => 'Per què aquesta recomanació?';

  @override
  String titleDateLabel(Object title, Object date, Object label) {
    return '$title, $date, $label';
  }

  @override
  String get previousDay => 'Dia anterior';

  @override
  String get nextDay => 'Dia següent';

  @override
  String get updating => 'Actualitzant';

  @override
  String get resting => 'EN REPÒS';

  @override
  String get noTimedReadings => 'Sense lectures amb hora';

  @override
  String get avg => 'MIT';

  @override
  String get peak => 'PIC';

  @override
  String tolocalRoundmin(Object toLocal, Object round) {
    return '$toLocal · ${round}min';
  }

  @override
  String avgheartrateBpmAvg(Object avgHeartRate) {
    return '$avgHeartRate bpm mitj.';
  }

  @override
  String get timeWeightedAverageOverRecorded =>
      'Mitjana ponderada pel temps dels períodes registrats. Els buits sense lectures s\'exclouen.';

  @override
  String get previousHeartRatePeriod =>
      'Període de freqüència cardíaca anterior';

  @override
  String get nextHeartRatePeriod => 'Període de freqüència cardíaca següent';

  @override
  String get avgHr => 'FC mitj.';

  @override
  String get restingHr => 'FC en repòs';

  @override
  String get both => 'Tots dos';

  @override
  String averagelabelFixedMs(Object averageLabel, Object fixed) {
    return '$averageLabel $fixed ms';
  }

  @override
  String get measureWithPolarH10 => 'Mesura amb Polar H10';

  @override
  String get ms => 'ms';

  @override
  String get noWorkoutInThisPeriod =>
      'Cap entrenament d\'aquest període té un parell abans/després comparable.';

  @override
  String textEachWorkoutCountsOnce(Object text) {
    return '$text. Cada entrenament compta una vegada; això descriu els teus parells, no els puntua.';
  }

  @override
  String get workoutFinished => 'Entrenament acabat?';

  @override
  String get yourWorkoutIsNotIn =>
      'El teu entrenament encara no és a Fjelia. Si ha acabat, indica quan i el recordatori podrà seguir el final real. Si no, apareixerà quan el rellotge se sincronitzi.';

  @override
  String get workoutFinished2 => 'Entrenament acabat';

  @override
  String get theWorkoutMustStartAfter =>
      'L\'entrenament ha de començar després del mesurament i acabar després del seu inici, no en el futur.';

  @override
  String daysDAvg(Object days) {
    return '$days D mitj.';
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
  String get previousPeriod => 'Període anterior';

  @override
  String get nextPeriod => 'Període següent';

  @override
  String get overnightHrvReflectsRecoveryCompare =>
      'La VFC nocturna reflecteix la recuperació. Compara les teves lectures amb la teva línia de base al llarg del temps.';

  @override
  String get moveThisWorkout => 'MOU AQUEST ENTRENAMENT';

  @override
  String get pickDate => 'Tria una data';

  @override
  String movedFromMovedfrom(Object movedFrom) {
    return 'Mogut des de $movedFrom';
  }

  @override
  String get hrvAroundThisWorkout => 'VFC al voltant d\'aquest entrenament';

  @override
  String get measureAfterTraining => 'Mesura després de l\'entrenament';

  @override
  String get measureAgain => 'Mesura de nou';

  @override
  String get explainWithAi => 'Explica amb IA';

  @override
  String beforeEndedPregapAheadOf(Object preGap) {
    return 'Abans va acabar $preGap abans de l\'inici.';
  }

  @override
  String lengthFurtherMeasurementSAfter(Object length) {
    return '$length mesurament(s) addicional(s) després d\'aquest entrenament es conserven com a observacions extra.';
  }

  @override
  String get noHrvMeasurementRecordedAround =>
      'Cap mesurament de VFC registrat al voltant d\'aquest entrenament.';

  @override
  String get measureHrv => 'Mesura la VFC';

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
      'Una descripció d\'aquest parell, no una puntuació de l\'entrenament.';

  @override
  String notEnoughComparableWorkoutsYet(Object eligible, Object need) {
    return 'Encara no hi ha prou entrenaments comparables, $eligible de $need.';
  }

  @override
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need) {
    return 'Encara no hi ha prou entrenaments comparables ($eligible de $need).';
  }

  @override
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  ) {
    return 'Els teus $eligible entrenaments similars · $toLocal–$toLocal2';
  }

  @override
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  ) {
    return 'Meitat central de $q1Ms a $q3Ms ms · mediana $medianMs ms · aquest entrenament $delta ms';
  }

  @override
  String rpeI(Object i) {
    return 'RPE $i';
  }

  @override
  String get easy2 => 'fàcil';

  @override
  String get allOut => 'A tot gas';

  @override
  String workoutProfileDescription(Object description) {
    return 'Perfil de l\'entrenament: $description';
  }

  @override
  String get noActivitiesInThisPeriod => 'Cap activitat en aquest període';

  @override
  String get enableHeatAcclimationInTraining =>
      'Activa l\'aclimatació a la calor a la configuració d\'entrenament.';

  @override
  String get noElevationThisWeek => 'Sense desnivell aquesta setmana';

  @override
  String get noActivitiesSynced => 'Cap activitat sincronitzada';

  @override
  String get noHrZoneData => 'Sense dades de zones de FC';

  @override
  String get easyJogGetHrElevated => 'Trot suau: puja la FC, cames soltes';

  @override
  String get fastestSustainablePaceLikeA =>
      'Ritme sostenible més ràpid: com una cursa de 30 min';

  @override
  String get walkCardiacRecovery => 'Caminar: recuperació cardíaca';

  @override
  String get selectTheTtActivityFirst =>
      'Selecciona primer l\'activitat de la prova.';

  @override
  String get calculating => 'Calculant…';

  @override
  String get calculateLt2 => 'Calcula la LT2';

  @override
  String get enterFtpBetween30And => 'Introdueix una FTP entre 30 i 1000 W.';

  @override
  String get aerobicThreshold => 'Llindar aeròbic';

  @override
  String get functionalThresholdPower => 'Potència llindar funcional';

  @override
  String get estimated => 'Estimat';

  @override
  String get afterWarmingUpRunFive =>
      'Després d\'escalfar, corre cinc minuts al teu màxim esforç sostenible. Registra la cursa amb dades de velocitat o distància.';

  @override
  String get recordAtLeast40Minutes =>
      'Registra almenys 40 minuts de cursa constant a esforç constant. La prova compara la freqüència cardíaca en cada meitat per estimar la deriva aeròbica.';

  @override
  String get theFastestFiveMinuteWindow =>
      'La finestra de cinc minuts més ràpida dona el teu ritme de VO2max.';

  @override
  String get noResultYet => 'Encara sense resultat';

  @override
  String get calculateVo2maxPace => 'Calcula el ritme de VO2max';

  @override
  String get calculateLt1 => 'Calcula la LT1';

  @override
  String get loading2 => 'Carregant';

  @override
  String get unavailable => 'No disponible';

  @override
  String get noTrainingHistory => 'Sense historial d\'entrenament';

  @override
  String get fitnessCtl => 'Forma física (CTL)';

  @override
  String get fatigueAtl => 'Fatiga (ATL)';

  @override
  String get formTsb => 'Frescor (TSB)';

  @override
  String get noHistory => 'Sense historial';

  @override
  String get fresh => 'Fresc';

  @override
  String get optimal => 'Òptim';

  @override
  String get neutral => 'Neutre';

  @override
  String get tired => 'Cansat';

  @override
  String get veryFatigued => 'Molt fatigat';

  @override
  String get garminRunningVo2max => 'VO2max cursa Garmin';

  @override
  String get garminCyclingVo2max => 'VO2max ciclisme Garmin';

  @override
  String get aerobicThreshold2 => 'Llindar aeròbic';

  @override
  String driftDriftAt(Object drift, Object at) {
    return 'Deriva $drift % · $at';
  }

  @override
  String get activityHours => 'Hores d\'activitat';

  @override
  String get activityKm => 'Km d\'activitat';

  @override
  String get tap5MinuteMaxTest => 'Toca · prova màxima de 5 min';

  @override
  String get setFtpToCalculatePower =>
      'Defineix la FTP per calcular les zones de potència';

  @override
  String get cyclingPowerZones2 => 'Zones de potència en ciclisme';

  @override
  String get pfitzingerZones2 => 'Zones de Pfitzinger';

  @override
  String get completeAnLt2TestTo =>
      'Completa una prova de LT2 per calcular les zones de cursa.';

  @override
  String get setFtpToCalculatePower2 =>
      'Defineix la FTP per calcular les zones de potència.';

  @override
  String get endurance => 'Resistència';

  @override
  String get threshold => 'Llindar';

  @override
  String get anaerobic => 'Anaeròbic';

  @override
  String get whatExplainsThisRise => 'Què explica aquest augment?';

  @override
  String get whatExplainsThisDrop => 'Què explica aquesta baixada';

  @override
  String get whatExplainsThisRise2 => 'Què explica aquest augment';

  @override
  String get editsAreKeptInFjelia =>
      'Els canvis es guarden a Fjelia com a còpia local per a aquesta data. L\'entrenament a Garmin no canvia.';

  @override
  String get howDoIExecuteThis => 'Com executo aquest entrenament?';

  @override
  String shareHealthContextWithName(Object name) {
    return 'Compartir el context de salut amb $name?';
  }

  @override
  String get yourMessageAndAHealth =>
      'El teu missatge i un resum de salut/entrenament s\'enviaran a aquest proveïdor d\'IA al núvol. Els noms i el GPS s\'exclouen del resum generat.';

  @override
  String get couldNotGetAReply =>
      'No s\'ha pogut obtenir una resposta. Revisa la configuració d\'IA i torna-ho a provar.';

  @override
  String get askAboutYourRecoveryTraining =>
      'Pregunta sobre la teva recuperació, el teu entrenament o el pla d\'avui.';

  @override
  String get noSyncYet => 'Encara sense sincronitzar';

  @override
  String lastSyncLastContext(Object last, Object context) {
    return 'Última sincronització: $last $context';
  }

  @override
  String get seasonWithTradeOffs => 'Temporada: amb concessions';

  @override
  String get seasonNeedsYourDecision => 'Temporada: necessita la teva decisió';

  @override
  String get seasonCannotBeCombined => 'Temporada: no es pot combinar';

  @override
  String get seasonProvisional => 'Temporada: provisional';

  @override
  String get season => 'Temporada';

  @override
  String get allGoalsFit => 'Tots els objectius encaixen.';

  @override
  String goalTargetfinishsecondsgoal(Object targetFinishSeconds, Object goal) {
    return 'Objectiu $targetFinishSeconds$goal';
  }

  @override
  String estEstimateestimate2(Object estimate, Object estimate2) {
    return 'Est. $estimate$estimate2';
  }

  @override
  String doneDoneby(Object doneBy) {
    return 'Fet · $doneBy';
  }

  @override
  String garminWorkoutWorkout(Object workout) {
    return 'Entrenament Garmin · $workout';
  }

  @override
  String get moveAnyway => 'Moure igualment?';

  @override
  String get wattsNeedYourFtpSet =>
      'Els watts necessiten la teva FTP: defineix-la a Càrrega, Llindars.';

  @override
  String get mainTargetInWattsFrom =>
      'Objectiu principal en watts segons la teva FTP, la freqüència cardíaca com a guia.';

  @override
  String get mainTargetHeartRateWatts =>
      'Objectiu principal: freqüència cardíaca; els watts no estan definits al rellotge.';

  @override
  String get taperPhase => 'Fase d\'afinament';

  @override
  String get recoverySession => 'Sessió de recuperació';

  @override
  String get closeToYourEvent => 'A prop del teu esdeveniment';

  @override
  String get noWorkoutStructureAvailable =>
      'No hi ha estructura d\'entrenament disponible.';

  @override
  String get aerobic => 'Aeròbic';

  @override
  String get pushAgainToUpdateYour =>
      'Envia de nou per actualitzar el calendari del rellotge.';

  @override
  String workoutSentToLabel(Object label) {
    return 'Entrenament enviat a $label';
  }

  @override
  String get updating2 => 'Actualitzant…';

  @override
  String pushToLabel(Object label) {
    return 'Envia a $label';
  }

  @override
  String shareExerciseListForLabel(Object label) {
    return 'Comparteix la llista d\'exercicis per a $label';
  }

  @override
  String shareWorkoutForLabel(Object label) {
    return 'Comparteix l\'entrenament per a $label';
  }

  @override
  String get whyNothingIsAddedTo =>
      'Per què? No s\'afegeix res per completar-ho.';

  @override
  String get workout => 'Entrenament';

  @override
  String get recordedActivityLinkedToThis =>
      'Activitat registrada vinculada a aquest entrenament';

  @override
  String get matchedToTheRecordedWorkout =>
      'Emparellat amb l\'inici de l\'entrenament registrat';

  @override
  String get matchedByWorkoutNameSport =>
      'Emparellat per nom d\'entrenament, esport i data';

  @override
  String get matchedBySportDateAnd => 'Emparellat per esport, data i durada';

  @override
  String planPlannedminutesMin(Object plannedMinutes) {
    return 'Pla $plannedMinutes min';
  }

  @override
  String get maxHr => 'FC màx.';

  @override
  String get trainingLoad2 => 'Càrrega d\'entrenament';

  @override
  String get active => 'Actiu';

  @override
  String get avgPace => 'Ritme mitjà';

  @override
  String get avgSpeed => 'Velocitat mitjana';

  @override
  String get avgPower => 'Potència mitjana';

  @override
  String get elevation2 => 'Desnivell';

  @override
  String get altitude => 'Altitud';

  @override
  String get explainMyHrvBeforeAnd =>
      'Explica la meva VFC abans i després d\'aquest entrenament. Què és comparable, què no i què continua sent desconegut?';

  @override
  String get deleteActivity => 'Eliminar l\'activitat?';

  @override
  String get removeThisActivityFromThe =>
      'Vols eliminar aquesta activitat? Continuarà eliminada encara que els dispositius tornin a sincronitzar. La pots restaurar a Configuració, a Eliminades recentment.';

  @override
  String get howDidThisSessionGo =>
      'Com ha anat aquesta sessió i què significa per als meus propers dies?';

  @override
  String currentFixedFixed2(Object fixed, Object fixed2) {
    return 'Actual $fixed, $fixed2';
  }

  @override
  String get setUpInTrainingSettings =>
      'Configura-ho a la configuració d\'entrenament';

  @override
  String get couldNotLoadHeatData =>
      'No s\'han pogut carregar les dades de calor – toca per veure els detalls';

  @override
  String get loadingHeatHistory => 'Carregant historial de calor…';

  @override
  String get noHeatDataYet => 'Encara sense dades de calor';

  @override
  String optimalLowHigh(Object low, Object high) {
    return 'Òptim $low–$high';
  }

  @override
  String optimalLowHighTrimp(Object low, Object high) {
    return 'Òptim: $low–$high TRIMP';
  }

  @override
  String get targetUnavailableSyncTrainingHistory =>
      'Objectiu no disponible: sincronitza l\'historial d\'entrenament';

  @override
  String get workoutQualifiedForHeatAccumulation =>
      'L\'entrenament ha comptat per a l\'acumulació de calor.';

  @override
  String get workoutDidNotAddHeat =>
      'L\'entrenament no ha afegit acumulació de calor.';

  @override
  String get performanceTime => 'Rendiment / Temps';

  @override
  String get performanceDistance => 'Rendiment / Distància';

  @override
  String get noRecordedRoute => 'Cap ruta registrada';

  @override
  String get zoomIn => 'Amplia';

  @override
  String get zoomOut => 'Redueix';

  @override
  String get fitRoute => 'Ajusta la ruta';

  @override
  String get fullscreenMap => 'Mapa a pantalla completa';

  @override
  String get openstreetmapContributors2 => 'col·laboradors d\'OpenStreetMap';

  @override
  String get appleIntelligenceIsUnavailableShowing =>
      'Apple Intelligence no està disponible. Es mostra un resum sense IA.';

  @override
  String get generateAiBriefing => 'Generar el resum amb IA?';

  @override
  String get retryAiBriefing => 'Torna a provar el resum amb IA';

  @override
  String get generateBriefing => 'Genera el resum';

  @override
  String discussThisBriefingWithMe(Object text) {
    return 'Comenta aquest resum amb mi i suggereix la millor propera acció.\n\n$text';
  }

  @override
  String whyThisRecommendationWhichOf(Object text) {
    return 'Per què aquesta recomanació? Quines xifres meves i quines llacunes en les dades hi han portat, i què la canviaria?\n\n$text';
  }

  @override
  String get avg2 => 'Mitj.';

  @override
  String get peak2 => 'Pic';

  @override
  String get notEnoughContinuousReadingsFor =>
      'No hi ha prou lectures contínues per a una mitjana.';

  @override
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  ) {
    return 'Cobertura registrada: $inHours h $inMinutes min · mitjana ponderada pel temps';
  }

  @override
  String get lying => 'Estirat';

  @override
  String get noHrvReadingsInThis => 'Sense lectures de VFC en aquest període';

  @override
  String get overnightHrvComesFromYour =>
      'La VFC nocturna ve del teu rellotge i les lectures puntuals del Polar H10 (RMSSD). Els mètodes difereixen: compara tendències, no valors aïllats.';

  @override
  String get noReadings => 'Sense lectures';

  @override
  String get whenDidTheWorkoutStart => 'Quan ha començat l\'entrenament?';

  @override
  String get whenDidItEnd => 'Quan ha acabat?';

  @override
  String get last3Months => 'Últims 3 mesos';

  @override
  String get lastYear => 'Últim any';

  @override
  String lastDaysDays(Object days) {
    return 'Últims $days dies';
  }

  @override
  String nowOnCurrentTapA(Object current) {
    return 'Ara el $current. Toca un dia o arrossega l\'entrenament a un. Els passos es mantenen.';
  }

  @override
  String get monthView => 'Vista mensual';

  @override
  String get syncing => 'Sincronitzant';

  @override
  String get trendUnavailable => 'Tendència no disponible';

  @override
  String get stable => 'Estable';

  @override
  String get increasing => 'En augment';

  @override
  String get decreasing => 'En descens';

  @override
  String get unclear => 'Poc clar';

  @override
  String get notComparable => 'No comparable';

  @override
  String get waitingForAfter => 'Esperant el després';

  @override
  String get afterOnly => 'Només després';

  @override
  String get waitingForTheActualWorkout =>
      'Esperant el final real de l\'entrenament.';

  @override
  String reminderAroundTolocal(Object toLocal) {
    return 'Recordatori cap a les $toLocal';
  }

  @override
  String get reminderIsDueMeasureWhen =>
      'El recordatori ha arribat. Mesura quan estiguis a punt.';

  @override
  String get thisReminderIsNoLonger =>
      'Aquest recordatori ja no és vigent. Obre l\'entrenament per veure els teus mesuraments.';

  @override
  String beforeFixedMilliseconds(Object fixed) {
    return 'Abans $fixed mil·lisegons. ';
  }

  @override
  String afterFixedMilliseconds(Object fixed) {
    return 'Després $fixed mil·lisegons';
  }

  @override
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  ) {
    return 'Canvi de $deltaMs mil·lisegons, $deltaPercent per cent.';
  }

  @override
  String get noPreTrainingMeasurementRecorded =>
      'Cap mesurament previ a l\'entrenament registrat.';

  @override
  String get notMeasuredYet => 'Encara sense mesurar';

  @override
  String leftOutOfTheComparison(Object excludedTotal, Object c) {
    return 'Exclosos de la comparació: $excludedTotal entrenaments ($c).';
  }

  @override
  String get notFromThisWorkout => 'No d\'aquest entrenament';

  @override
  String get useAsBefore => 'Fes servir com a abans';

  @override
  String get useAsAfter => 'Fes servir com a després';

  @override
  String get beforeNotMeasured => 'Abans · sense mesurar';

  @override
  String beforeTolocal(Object toLocal) {
    return 'Abans · $toLocal';
  }

  @override
  String workoutWorkouttext(Object workoutText) {
    return 'Entrenament · $workoutText';
  }

  @override
  String get afterNotMeasuredYet => 'Després · encara sense mesurar';

  @override
  String afterTolocal(Object toLocal) {
    return 'Després · $toLocal';
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
    return 'Els teus entrenaments similars ($eligible, $toLocal–$toLocal2): mediana $medianMs ms, meitat central de $q1Ms a $q3Ms ms.';
  }

  @override
  String get howHardDidItFeel => 'Com de dur ha estat? (RPE)';

  @override
  String get loadMetric => 'Càrrega';

  @override
  String get clearAction => 'Esborra';

  @override
  String get routeFinish => 'Meta';

  @override
  String get month2 => 'MES';

  @override
  String get week2 => 'SETMANA';

  @override
  String get quarter => 'TRIMESTRE';

  @override
  String get year => 'ANY';

  @override
  String get easy3 => 'FÀCIL';

  @override
  String get mod => 'MOD.';

  @override
  String get hard => 'DUR';

  @override
  String get protocol => 'PROTOCOL';

  @override
  String get calculate => 'CALCULA';

  @override
  String get warmUp => 'ESCALFAMENT';

  @override
  String get coolDown => 'TORNADA A LA CALMA';

  @override
  String get ftpCycling => 'FTP ciclisme';

  @override
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg) {
    return 'FTP $ftpWatts W · $wattsPerKg W/kg';
  }

  @override
  String get thisWeekSoFar => 'AQUESTA SETMANA · FINS ARA';

  @override
  String get duration2 => 'DURADA';

  @override
  String get distance2 => 'DISTÀNCIA';

  @override
  String get sport2 => 'ESPORT';

  @override
  String get repeatSets => 'SÈRIES REPETIDES';

  @override
  String get aboutThisWorkout => 'SOBRE AQUEST ENTRENAMENT';

  @override
  String get workoutStructure => 'ESTRUCTURA DE L\'ENTRENAMENT';

  @override
  String get health2 => 'SALUT';

  @override
  String get high2 => 'ALT';

  @override
  String get elevated => 'ELEVAT';

  @override
  String get normal => 'NORMAL';

  @override
  String get tomorrow => 'DEMÀ';

  @override
  String get skipped2 => 'OMÈS';

  @override
  String get weeklyPlan => 'PLA SETMANAL';

  @override
  String get activityLog3 => 'REGISTRE D\'ACTIVITAT';

  @override
  String skippedTouppercase(Object toUpperCase) {
    return 'OMÈS · $toUpperCase';
  }

  @override
  String get primaryZone => 'ZONA PRINCIPAL';

  @override
  String get coachingCues => 'CONSELLS DE L\'ENTRENADOR';

  @override
  String get targets => 'OBJECTIUS';

  @override
  String get adaptation => 'ADAPTACIÓ';

  @override
  String get done2 => 'FET';

  @override
  String get notRecorded2 => 'NO REGISTRAT';

  @override
  String get planned => 'PLANIFICAT';

  @override
  String get extra => 'EXTRA';

  @override
  String get optimal2 => 'ÒPTIM';

  @override
  String get qualified => 'QUALIFICAT';

  @override
  String get temp => 'TEMP.';

  @override
  String get humidity2 => 'HUMITAT';

  @override
  String get pressure => 'PRESSIÓ';

  @override
  String get wetBulb => 'BULB HUMIT';

  @override
  String get paceMinKm => 'Ritme (min/km)';

  @override
  String get speedKmH => 'Velocitat (km/h)';

  @override
  String get elevationM => 'Desnivell (m)';

  @override
  String get powerW => 'POTÈNCIA (W)';

  @override
  String get performanceTime2 => 'RENDIMENT / TEMPS';

  @override
  String get performanceDistance2 => 'RENDIMENT / DISTÀNCIA';

  @override
  String get load2 => 'CÀRREGA';

  @override
  String get day2 => 'DIA';

  @override
  String get allTime => 'TOT EL TEMPS';

  @override
  String get hrvAroundThisWorkout2 => 'VFC al voltant d\'aquest entrenament. ';

  @override
  String get lowReserve => 'RESERVA BAIXA';

  @override
  String get goodReserve => 'BONA RESERVA';

  @override
  String latestReadingAtTolocal(Object toLocal) {
    return 'Última lectura a les $toLocal';
  }

  @override
  String get weeklyAvg => 'MITJANA SETMANAL';

  @override
  String get monthlyAvg => 'MITJANA MENSUAL';

  @override
  String get systolic2 => 'SISTÒLICA';

  @override
  String get diastolic2 => 'DIASTÒLICA';

  @override
  String get hourlyVariation => 'VARIACIÓ HORÀRIA';

  @override
  String get dailyVariation => 'VARIACIÓ DIÀRIA';

  @override
  String get sys2 => 'SIS';

  @override
  String get dia => 'DIA';

  @override
  String get bluetoothDevices => 'DISPOSITIUS BLUETOOTH';

  @override
  String get accountsServices => 'COMPTES I SERVEIS';

  @override
  String get flowLoginOptional => 'INICI DE SESSIÓ DE FLOW (OPCIONAL)';

  @override
  String get polarFlowLogin => 'INICI DE SESSIÓ DE POLAR FLOW';

  @override
  String get raceGoal => 'OBJECTIU DE CURSA';

  @override
  String get experienceLevel => 'NIVELL D\'EXPERIÈNCIA';

  @override
  String get weeklySchedule2 => 'HORARI SETMANAL';

  @override
  String get sessionsPerDay2 => 'SESSIONS PER DIA';

  @override
  String get aboutYou => 'SOBRE TU';

  @override
  String get yourActivities2 => 'LES TEVES ACTIVITATS';

  @override
  String latestReadingAtTimestamp(Object timestamp) {
    return 'Última lectura a les $timestamp';
  }

  @override
  String get poorSleep => 'SON DEFICIENT';

  @override
  String get fairSleep => 'SON REGULAR';

  @override
  String get goodSleep => 'BON SON';

  @override
  String get hoursOfSleep => 'HORES DE SON';

  @override
  String get sleepNeeded => 'SON NECESSARI';

  @override
  String get deepSleep => 'SON PROFUND';

  @override
  String get exercises2 => 'EXERCICIS';

  @override
  String get strengthSummary => 'RESUM DE FORÇA';

  @override
  String get strengthDraft => 'FORÇA · ESBORRANY';

  @override
  String get strengthFinishedWithGaps => 'FORÇA · ACABAT AMB BUITS';

  @override
  String get strength2 => 'FORÇA';

  @override
  String get wind => 'VENT';

  @override
  String get sun2 => 'SOL';

  @override
  String get cloud => 'NÚVOLS';

  @override
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt) {
    return 'Dades: $source · Actualitzat $fetchedAt';
  }

  @override
  String get coros2 => 'COROS';

  @override
  String get rmssdMs => 'RMSSD · ms';

  @override
  String get sdnnMs => 'SDNN · ms';

  @override
  String get now2 => 'ARA';

  @override
  String get awake => 'DESPERT';

  @override
  String get light => 'LLEUGER';

  @override
  String get deep2 => 'PROFUND';

  @override
  String get sqliteOrm => 'SQLite ORM';

  @override
  String get httpClients => 'Clients HTTP';

  @override
  String get gpsLocation => 'Ubicació GPS';

  @override
  String get hdlCholesterol => 'Colesterol HDL';

  @override
  String get ldlCholesterol => 'Colesterol LDL';

  @override
  String get raceName => 'NOM DE LA CURSA';

  @override
  String get mtb => 'BTT';

  @override
  String get distanceKm => 'Distància (km)';

  @override
  String get priority => 'PRIORITAT';

  @override
  String get elevationGainM => 'Desnivell positiu (m)';

  @override
  String get targetTime => 'TEMPS OBJECTIU';

  @override
  String get raceDate => 'DATA DE LA CURSA';

  @override
  String get participation => 'PARTICIPACIÓ';

  @override
  String get whatIWantFromIt => 'EL QUE EN VULL OBTENIR';

  @override
  String periodTimeline(Object period) {
    return '$period · EVOLUCIÓ';
  }

  @override
  String get tabPlan => 'PLA';

  @override
  String get tabLoad => 'CÀRREGA';

  @override
  String get tabCoach => 'COACH';

  @override
  String get hrDriftTestLt1 => 'PROVA DE DERIVA DE FC – LT1';

  @override
  String get asSentByGarmin => 'TAL COM L\'HA ENVIAT GARMIN';

  @override
  String get noData2 => 'SENSE DADES';

  @override
  String get noTarget => 'SENSE OBJECTIU';

  @override
  String get noHeatLoad => 'SENSE CÀRREGA DE CALOR';

  @override
  String get hrBpm => 'FC (ppm)';

  @override
  String get aiBriefingUnavailableShowingA =>
      'Resum amb IA no disponible. Es mostra un resum sense IA.';

  @override
  String get uvIndex2 => 'ÍNDEX UV';

  @override
  String get aiBriefing => 'Resum amb IA';

  @override
  String get uiFrameworkByGoogle => 'Framework d\'interfície de Google';

  @override
  String get unableToLoadData => 'No s\'han pogut carregar les dades';

  @override
  String briefingSummary(Object recovery, Object sleep, Object load) {
    return 'Recuperació $recovery / 100. Son $sleep / 100. La càrrega d\'entrenament d\'avui és de $load TRIMP.';
  }

  @override
  String get morningBriefing => 'Resum del matí';

  @override
  String get lunchBriefing => 'Resum del migdia';

  @override
  String get afternoonBriefing => 'Resum de la tarda';

  @override
  String get eveningBriefing => 'Resum del vespre';

  @override
  String get appleUnusableAnswer =>
      'Apple Intelligence no ha pogut donar una resposta utilitzable: s\'ha repetit o ha repetit les teves dades. Reformula la pregunta o tria un altre proveïdor d\'IA a la configuració.';

  @override
  String get appleCouldNotAnswer =>
      'Apple Intelligence no ha pogut respondre. Torna-ho a provar.';

  @override
  String get appleNotAvailableOnDevice =>
      'Apple Intelligence no està disponible en aquest dispositiu.';

  @override
  String get appleLanguageRejected =>
      'Apple Intelligence ha rebutjat l\'idioma de la sol·licitud. Prova amb una pregunta curta en anglès. Revisa també la configuració d\'idioma de l\'iPhone i de Siri.';

  @override
  String get appleRequestTooLarge =>
      'Apple Intelligence no ha pogut processar aquesta sol·licitud. Prova amb una pregunta més curta.';

  @override
  String get messageTooLongForApple =>
      'Aquest missatge és massa llarg per a Apple Intelligence. Escurça\'l i torna a enviar-lo.';

  @override
  String get vo2maxRunning => 'VO₂max cursa';

  @override
  String get vo2maxCycling => 'VO₂max ciclisme';

  @override
  String get vo2maxPaceLabel => 'Ritme VO₂max';

  @override
  String get lt1Threshold => 'Llindar LT1';

  @override
  String get lt2Threshold => 'Llindar LT2';

  @override
  String hoursPreviousWeek(Object value) {
    return '$value h la setmana anterior';
  }

  @override
  String kmPreviousWeek(Object value) {
    return '$value km la setmana anterior';
  }

  @override
  String get thirtyMinuteTimeTrial => 'Contrarellotge de 30 minuts';

  @override
  String thirtyMinTtDate(Object date) {
    return 'TT 30 min · $date';
  }

  @override
  String get yesterday2 => 'AHIR';

  @override
  String get briefHeadGreen => 'Estàs ben recuperat.';

  @override
  String get briefHeadYellow => 'Portes una mica de càrrega.';

  @override
  String get briefHeadRed => 'Estàs clarament sobrecarregat.';

  @override
  String briefMain(Object reasons) {
    return 'Motius principals: $reasons.';
  }

  @override
  String get briefAllClear => 'Cap dels teus valors mostra senyals d\'alerta.';

  @override
  String get briefAdviceGreen => 'Entrena com estava previst.';

  @override
  String get briefAdviceYellow =>
      'Mantén el teu pla però sense afegir intensitat.';

  @override
  String get briefAdviceRed => 'Primer la recuperació: dia suau o descans.';

  @override
  String get briefReasonHrvLow => 'VFC de la son baixa';

  @override
  String get briefReasonHrvHigh => 'VFC de la son alta';

  @override
  String get briefReasonRhrUp => 'FC en repòs elevada';

  @override
  String get briefReasonRhrDown => 'FC en repòs baixa';

  @override
  String get briefReasonSleepShort => 'poc son';

  @override
  String get briefReasonSleepGood => 'necessitat de son coberta';

  @override
  String get briefReasonEnergyLow => 'poca energia';

  @override
  String get briefReasonEnergyHigh => 'bona energia';

  @override
  String get briefReasonStressHigh => 'estrès alt';

  @override
  String get briefReasonRespHigh => 'freqüència respiratòria elevada';

  @override
  String get briefReasonSpo2Low => 'oxigen en sang baix';

  @override
  String get briefReasonSkinTempOff => 'temperatura de la pell inusual';

  @override
  String get briefReasonFormTired => 'fatiga d\'entrenament acumulada';

  @override
  String get briefReasonFormVeryTired => 'fatiga d\'entrenament molt alta';

  @override
  String get briefReasonFormFresh => 'fresc i descansat';

  @override
  String get briefTrainingHrvUp =>
      'La teva VFC ha pujat després de l\'entrenament, bon senyal.';

  @override
  String get briefTrainingHrvDown =>
      'La teva VFC ha baixat després de l\'entrenament, senyal menys bo.';

  @override
  String get reminderNeedsNotifications =>
      'El recordatori necessita notificacions. Permet-les per a Fjelia a la configuració del sistema i torna a activar-lo.';

  @override
  String get whatDidYouHave => 'Què has près?';

  @override
  String get intakeSomething => 'He près alguna cosa';

  @override
  String get intakeNothing => 'Res';

  @override
  String get totalIntake => 'Ingesta total';

  @override
  String get carbsLabel => 'Carbohidrats';

  @override
  String get fluidLabel => 'Líquid';

  @override
  String get sodiumLabel => 'Sodi';

  @override
  String get caffeineLabel => 'Cafeïna';

  @override
  String get detailsOptional => 'Detalls (opcional)';

  @override
  String atMinute(Object minute) {
    return 'minut $minute';
  }

  @override
  String get nothingAddedYet =>
      'Encara no has afegit res. Afegeix el que has menjat o begut, o tria «Res».';

  @override
  String get followFocusWeek => 'En què m\'hauria de centrar aquesta setmana?';

  @override
  String get followRecoveryTrend => 'Com evoluciona la meva recuperació?';

  @override
  String get followLoadTooHigh =>
      'La meva càrrega d\'entrenament és massa alta?';

  @override
  String get followImproveSleep => 'Què milloraria el meu son?';

  @override
  String get followIntervalsFeel => 'Com haurien de sentir-se els intervals?';

  @override
  String get followTiredToday => 'I si avui em sento cansat?';

  @override
  String get followEatBefore => 'Què hauria de menjar abans?';

  @override
  String get followAdjustToday => 'L\'hauria d\'ajustar avui?';

  @override
  String get followNextDays => 'Què significa per als meus propers dies?';

  @override
  String get followCompareSimilar => 'Com es compara amb sessions similars?';

  @override
  String get followRecover => 'Què hauria de fer per recuperar-me?';

  @override
  String get followIntensityRight => 'Era correcta la intensitat?';

  @override
  String get statusPlanned => 'Planificat';

  @override
  String get statusAdapted => 'Adaptat';

  @override
  String get statusCompleted => 'Completat';

  @override
  String get statusRest => 'Descans';

  @override
  String loadValue(Object value) {
    return 'Càrrega $value';
  }

  @override
  String get actIntensityEasy => 'Ha estat una sessió aeròbica suau.';

  @override
  String get actIntensityModerate => 'Ha estat una sessió moderada.';

  @override
  String get actIntensityHard => 'Ha estat una sessió intensa.';

  @override
  String get actIntensityUnknown => 'La sessió està registrada.';

  @override
  String get actLenLonger =>
      'Ha estat més llarga que les teves sessions similars.';

  @override
  String get actLenShorter =>
      'Ha estat més curta que les teves sessions similars.';

  @override
  String get actLoadHigher => 'La càrrega ha estat més alta del normal.';

  @override
  String get actLoadLower => 'La càrrega ha estat més baixa del normal.';

  @override
  String get actLoadSame => 'La càrrega ha estat més o menys l\'habitual.';

  @override
  String get actHrLower =>
      'La teva FC va ser més baixa del normal, es va sentir més fàcil.';

  @override
  String get actHrHigher =>
      'La teva FC va ser més alta del normal, es va sentir més dur.';

  @override
  String get actAdviceUnknown =>
      'Planifica els propers dies segons com et sentis.';

  @override
  String briefOutlookRest(Object days) {
    return 'Amb uns $days dies suaus la teva forma torna al rang òptim.';
  }

  @override
  String get briefOutlookLongRest =>
      'La teva forma necessita més que uns quants dies suaus per recuperar-se.';

  @override
  String get briefOutlookPlanTired =>
      'Si segueixes el pla, la teva forma continuarà baixa els propers dies.';

  @override
  String get localQwen => 'Qwen3.5 · local';

  @override
  String get localModelDescription =>
      'Qwen3.5 opcional, MLX de 4 bits. Descarrega\'l una vegada i utilitza el xat i els resums en aquest dispositiu sense clau API. Les teves dades de salut es queden en aquest dispositiu.';

  @override
  String localModelSizeMb(Object megabytes) {
    return 'Descàrrega de $megabytes MB · cal memòria addicional durant l\'ús.';
  }

  @override
  String get localModelDownload => 'Descarrega el model';

  @override
  String get localModelResumeDownload => 'Reprèn la descàrrega';

  @override
  String localModelDownloading(Object downloaded, Object total) {
    return '$downloaded / $total MB';
  }

  @override
  String get localModelInstalled => 'Descarregat · disponible sense connexió';

  @override
  String get localModelRemove => 'Elimina el model';

  @override
  String get localModelUnsupported =>
      'Aquest model MLX requereix un iPhone amb iOS 17 o posterior i un xip A14 o més recent. Els dispositius anteriors no són compatibles.';

  @override
  String get localModelMemoryUnsupported =>
      'Aquest dispositiu no té prou memòria per executar el model local.';

  @override
  String get localModelDownloadFailed =>
      'La descàrrega ha fallat. Torna-ho a provar; es conserven els fitxers complets.';

  @override
  String get localModelDownloadFirst =>
      'Descarrega primer Qwen a Configuració → IA i més.';

  @override
  String get localModelContextTooLong =>
      'Aquesta conversa és massa llarga per al model local. Inicia un xat nou o escurça la pregunta.';

  @override
  String get localModelBusy =>
      'El model local està responent a una altra petició. Torna-ho a provar en un moment.';

  @override
  String get localModelInterrupted =>
      'La generació local s\'ha interromput. Mantén Fjelia oberta i torna-ho a provar.';

  @override
  String get localModelCouldNotAnswer =>
      'El model local no ha pogut respondre. Revisa el model a Configuració → IA i més i torna-ho a provar.';

  @override
  String get localModelBriefingUnavailable =>
      'El resum d\'IA local no està disponible. Es mostra el resum de l\'app.';

  @override
  String get localModelInfo => 'Detalls del model i llicència';

  @override
  String localModelRamGb(int gigabytes) {
    return 'Requereix com a mínim $gigabytes GB de RAM.';
  }

  @override
  String get localModelIPhone18 =>
      'El model 4B està disponible en iPhone 18 i posteriors.';

  @override
  String briefPlannedTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Avui hi ha $count sessions d’entrenament planificades.',
      one: 'Avui hi ha 1 sessió d’entrenament planificada.',
    );
    return '$_temp0';
  }

  @override
  String get coachDataFallback =>
      'La resposta del model contradiu les dades. Aquest és el resum de Fjelia:';

  @override
  String get coachSevenDayAverage => 'mitjana de 7 dies';

  @override
  String coachSleepNeedAndShortfall(String need, String shortfall) {
    return 'Son necessari: $need h; dèficit: $shortfall h.';
  }

  @override
  String coachCurrentForm(String value) {
    return 'Forma actual (TSB): $value punts.';
  }

  @override
  String get aiOnboardingStep => 'Pas 2 de 3';

  @override
  String get aiOnboardingTitle => 'El teu coach.\nA la teva manera.';

  @override
  String get aiOnboardingSubtitle =>
      'Converteix les teves dades de salut en consells per entrenar i recuperar-te millor.';

  @override
  String get aiOnboardingChoose => 'TRIA EL TEU COACH D’IA';

  @override
  String get aiOnboardingFreeDetail => 'Gratuït · Sense compte d’IA';

  @override
  String get aiOnboardingFreeBody =>
      'IA al núvol per a l’entrenament i la recuperació.';

  @override
  String get aiOnboardingRecommended => 'Recomanat';

  @override
  String get aiOnboardingOnDevice => 'Al teu dispositiu';

  @override
  String get aiOnboardingLocalBody =>
      'Les teves peticions d’IA es queden en aquest dispositiu.';

  @override
  String get aiOnboardingUnavailable => 'Ara no disponible';

  @override
  String get aiOnboardingMore => 'Més models d’IA';

  @override
  String get aiOnboardingMoreBody =>
      'Qwen local o el teu propi proveïdor al núvol';

  @override
  String get aiOnboardingConsent =>
      'Consultes al núvol només amb la teva confirmació.';

  @override
  String get aiOnboardingError =>
      'No s’ha pogut desar o carregar la teva tria d’IA. Torna-ho a provar.';

  @override
  String get aiOnboardingWithout => 'Continua sense IA';

  @override
  String get aiOnboardingConfigure => 'Configura el model';

  @override
  String aiOnboardingContinue(String provider) {
    return 'Continua amb $provider';
  }

  @override
  String get aiOnboardingChangeLater =>
      'Pots canviar-ho quan vulguis a la configuració.';

  @override
  String get creditsAndLicenses => 'Llicències i agraïments';

  @override
  String get bioAgeActivity => 'Activitat';

  @override
  String get bioAgeActivityBasis => 'Dades d’activitat · darrers 7 dies';

  @override
  String bioAgeActivityReported(String minutes) {
    return '$minutes minuts moderats registrats';
  }

  @override
  String bioAgeActivitySteps(String minutes) {
    return '≈ $minutes minuts de marxa estimats a partir dels passos';
  }

  @override
  String bioAgeActivityCoverage(int days) {
    return 'Dades de $days de 7 dies';
  }

  @override
  String get bioAgeActivityEstimateNotice =>
      'Supòsit: 100 passos ≈ 1 minut de marxa. El total diari de passos no revela el ritme ni la intensitat. Els minuts registrats tenen prioritat cada dia; els passos d’aquell dia no es tornen a comptar.';

  @override
  String get bioAgeActivityIncomplete =>
      'Falten dades d’activitat. La contribució de l’activitat en anys només es calcula quan hi ha dades dels 7 dies.';

  @override
  String get bioAgeActivityEstimatedLabel =>
      'L’activitat inclou temps de marxa estimat.';

  @override
  String get bioAgeActivityUnknownLabel => 'Dades d’activitat incompletes';

  @override
  String get mixTitle => 'Preparar una beguda';

  @override
  String get mixMyBottle => 'Preparar el meu bidó';

  @override
  String get mixRecipes => 'Receptes';

  @override
  String get mixIngredients => 'Ingredients';

  @override
  String get mixAddIngredient => 'Afegeix un ingredient';

  @override
  String get mixBottle => 'Bidó';

  @override
  String get mixFilledWithWater => 'omplert amb aigua';

  @override
  String mixPerBottle(String ml) {
    return 'per bidó de $ml ml';
  }

  @override
  String get mixStrength => 'Concentració';

  @override
  String get mixRatio => 'Glucosa : fructosa';

  @override
  String get mixGlucose => 'Glucosa';

  @override
  String get mixFructose => 'Fructosa';

  @override
  String get mixGlucoseOnly => 'Només glucosa';

  @override
  String get mixGentle => 'Suau per a l\'estómac – fins al 8 %.';

  @override
  String get mixStrong => 'Concentrada – només amb un intestí entrenat.';

  @override
  String get mixTooStrong => 'Molt concentrada – afegeix aigua.';

  @override
  String get mixNoFructoseHint =>
      'Només glucosa: per sobre d\'uns 60 g de carbohidrats per hora, afegeix fructosa (sucre) – al voltant de 2:1 s\'absorbeix millor.';

  @override
  String get mixFructoseHeavyHint =>
      'Més fructosa que glucosa pot fer mal a l\'estómac – afegeix maltodextrina o dextrosa.';

  @override
  String get mixSpoonNote =>
      'Les culleres varien. Pesa la teva cullera una vegada o fes servir grams per a valors exactes.';

  @override
  String get mixTooMuchLiquid =>
      'El suc i la cola ja superen el que hi cap al bidó – fes el bidó més gran.';

  @override
  String get mixAddToIntake => 'Afegeix a la ingesta';

  @override
  String get mixUseAsBottle => 'Fes-lo servir com el meu bidó';

  @override
  String get mixDefaultName => 'Barreja de beguda';

  @override
  String get mixEmpty => 'Tria una recepta o afegeix un ingredient.';

  @override
  String get mixRemove => 'Treu';

  @override
  String mixRowGrams(String grams) {
    return '≈ $grams g';
  }

  @override
  String mixBottleSaved(String carbs, String ml) {
    return 'Desat com el teu bidó: $carbs g de carbohidrats per $ml ml.';
  }

  @override
  String get mixMaltodextrin => 'Maltodextrina';

  @override
  String get mixSugar => 'Sucre';

  @override
  String get mixDextrose => 'Dextrosa';

  @override
  String get mixHoney => 'Mel';

  @override
  String get mixSalt => 'Sal';

  @override
  String get mixOrangeJuice => 'Suc de taronja';

  @override
  String get mixAppleJuice => 'Suc de poma';

  @override
  String get mixCola => 'Cola';

  @override
  String get unitTspLevel => 'culleradeta rasa';

  @override
  String get unitTspHeaped => 'culleradeta colmada';

  @override
  String get unitTbspLevel => 'cullerada rasa';

  @override
  String get unitTbspHeaped => 'cullerada colmada';

  @override
  String get unitPinch => 'pessic';

  @override
  String get unitTsp => 'culleradeta';

  @override
  String get unitTbsp => 'cullerada';

  @override
  String get mixRecipeMaltoSugar => 'Malto + sucre 2:1';

  @override
  String get mixRecipeJuice => 'Suc amb aigua';

  @override
  String get mixRecipeJuicePlus => 'Suc amb aigua + malto';

  @override
  String get mixRecipeCola => 'Cola amb aigua';

  @override
  String get missedWorkoutTitle => 'Encara al pla d’avui';

  @override
  String missedWorkoutBody(String workouts) {
    return '$workouts. Encara avui, moure’l o ometre’l?';
  }

  @override
  String get stillToday => 'Encara avui';

  @override
  String get moveWorkoutAction => 'Moure…';

  @override
  String get missedWorkoutChannel => 'Entrenaments perduts';

  @override
  String get missedWorkoutChannelDescription =>
      'Recordatori al vespre dels entrenaments previstos encara pendents';

  @override
  String get missedWorkoutReminder => 'Recordatori d’entrenament pendent';

  @override
  String get missedWorkoutReminderSubtitle =>
      'Al vespre, si un entrenament previst encara està pendent';

  @override
  String get moveWithinDays => 'Moure dins de';

  @override
  String daysN(int count) {
    return '$count dies';
  }

  @override
  String get notificationsAreOff =>
      'Les notificacions de Fjelia estan desactivades. Permet-les per rebre aquest recordatori.';

  @override
  String get allowNotifications => 'Permet les notificacions';

  @override
  String get openWorkoutToday => 'Pendent avui';

  @override
  String get checkingForWorkout => 'Cercant el teu entrenament…';

  @override
  String get alreadyDone => 'Ja fet ✓';

  @override
  String get alreadyDoneBody =>
      'El teu entrenament s’ha registrat. Avui no queda res pendent.';

  @override
  String get dropIt => 'Ometre’l';

  @override
  String askCoachSends(String provider) {
    return 'Envia el teu resum d’entrenament a $provider.';
  }

  @override
  String get coachThinking => 'El coach està pensant…';

  @override
  String get coachCouldNotAnswer =>
      'El coach no ha pogut respondre. El suggeriment de dalt continua sent vàlid.';

  @override
  String get whySkip => 'Per què ometre’l?';

  @override
  String get skipReasonIllness => 'Malaltia';

  @override
  String get skipReasonInjury => 'Lesió o dolor';

  @override
  String get skipReasonFatigue => 'Cansament';

  @override
  String get skipReasonNoTime => 'Sense temps';

  @override
  String get skipReasonTravel => 'Viatge';

  @override
  String get skipReasonConditions => 'Condicions';

  @override
  String get skipReasonMyChoice => 'Decisió meva';

  @override
  String get onbReminderTitle => 'Mantén el rumb';

  @override
  String get onbReminderSubtitle =>
      'Si al vespre un entrenament previst encara està pendent, Fjelia t’ho recorda una vegada, perquè encara el facis, el moguis o l’ometis.';

  @override
  String get onbExampleWorkout => 'Rodatge suau (45 min)';

  @override
  String get onbReminderToggle => 'Recordatori al vespre';

  @override
  String get onbReminderTime => 'Recorda-m’ho a les';

  @override
  String get onbReminderFootnote =>
      'Ho pots canviar quan vulguis a Configuració → Entrenament.';

  @override
  String get nowLabel => 'ara';

  @override
  String get coachSuggests => 'El coach proposa';

  @override
  String get suggestionLabel => 'Suggeriment';

  @override
  String get askCoachShort => 'Pregunta al coach';

  @override
  String get otherDay => 'Un altre dia';

  @override
  String get skipEllipsis => 'Ometre…';

  @override
  String get pickADay => 'Toca un dia a dalt';

  @override
  String get dayDoesNotFit => 'Aquest dia no encaixa al pla.';

  @override
  String get planUpdated => 'Pla actualitzat';

  @override
  String get missedTodayTag => 'perdut avui';

  @override
  String summaryMove(String day) {
    return 'Mou-lo al $day.';
  }

  @override
  String summaryMoveIndoor(String day) {
    return 'Mou-lo al $day, a cobert: es preveu pluja.';
  }

  @override
  String get summaryDropEasy =>
      'Omet-lo: no val la pena recuperar una sessió suau.';

  @override
  String summaryDropNoDay(int days) {
    return 'Omet-lo: cap dia encaixa en els propers $days dies.';
  }

  @override
  String get tagIndoor => 'a cobert';

  @override
  String get tagEasier => 'més suau';

  @override
  String get tagRecovery => 'recuperació';

  @override
  String summaryMoveEasier(String day) {
    return 'Mou-lo al $day, una mica més suau: és al costat d’un dia dur.';
  }

  @override
  String get briefRestDayToday => 'Avui és un dia de descans previst.';

  @override
  String get restDayPlannedNote => 'La recuperació forma part del teu pla.';

  @override
  String get restDayTitle => 'Dia de descans';

  @override
  String get importActivityFile => 'Importa un fitxer d’activitat';

  @override
  String get activityFileImportHint =>
      'Fitxers FIT, GPX o TCX (també en ZIP, com els exporta Garmin Connect) d’un ciclocomputador, Zwift, Strava o una altra app. També pots compartir un fitxer amb Fjelia des de l’app Fitxers o el menú Comparteix.';

  @override
  String get chooseActivityFiles => 'Tria fitxers';

  @override
  String get chooseOtherFiles => 'Tria altres fitxers';

  @override
  String get activityFileUnreadable => 'No és un fitxer d’activitat llegible';

  @override
  String get activityFileAlreadyImported => 'Ja importat';

  @override
  String activityFileAlreadyFrom(String source) {
    return 'Ja és a Fjelia des de $source';
  }

  @override
  String importActivities(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importa $count activitats',
      one: 'Importa $count activitat',
    );
    return '$_temp0';
  }

  @override
  String activitiesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activitats importades.',
      one: '$count activitat importada.',
    );
    return '$_temp0';
  }

  @override
  String get activityFileSource => 'Fitxer';

  @override
  String get dfaAlpha1Title => 'Llindar aeròbic (DFA α1)';

  @override
  String get dfaHrvt1 => 'Llindar aeròbic (HRVT1)';

  @override
  String get dfaHrvt2 => 'Llindar anaeròbic (HRVT2)';

  @override
  String dfaEasyShare(String percent) {
    return '$percent % de la sessió per sota del teu llindar aeròbic (α1 ≥ 0,75).';
  }

  @override
  String get dfaNoThreshold =>
      'La sessió no ha creuat clarament cap llindar. Una prova en rampa, o una sessió que progressa de suau a dur, en dona una estimació.';

  @override
  String dfaBeats(int beats, String artifacts) {
    return '$beats batecs · $artifacts % d’artefactes';
  }

  @override
  String get dfaArtifactsHigh =>
      'Molts artefactes: comprova que la banda de pit estigui ben ajustada i els elèctrodes humits.';

  @override
  String get dfaExplainer =>
      'A partir de les dades batec a batec d’una banda de pit. α1 a prop d’1 és suau, 0,75 marca el llindar aeròbic i 0,5 l’anaeròbic. Una estimació, no una prova de laboratori.';

  @override
  String get thresholdOrderNote =>
      'Fjelia compara totes les fonts. Primer proposa les proves de l’app, després el teu rellotge, després DFA α1 de diverses sessions, i després el perfil de Polar i les fórmules. No canvia res fins que ho apliquis.';

  @override
  String thresholdInUse(String value) {
    return 'En ús: $value';
  }

  @override
  String thresholdProposal(String value, String source) {
    return 'Proposta: $value de $source';
  }

  @override
  String get keepCurrent => 'Mantén';

  @override
  String get lt2Cycling => 'LT2 · Ciclisme';

  @override
  String get thresholdSourceTt => 'Contrarellotge de 30 minuts';

  @override
  String get thresholdSourceDrift => 'Prova de deriva de FC';

  @override
  String thresholdSourceDfa(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DFA α1, $count sessions',
      one: 'DFA α1, $count sessió',
    );
    return '$_temp0';
  }

  @override
  String get thresholdSourceEftp => 'eFTP de sortides en bici';

  @override
  String get thresholdSourcePolarProfile => 'Perfil de Polar';

  @override
  String get thresholdFormulaLt2 => 'LT2 − 30 ppm';

  @override
  String get thresholdFormulaMaxHr => '77 % de la FC màx.';

  @override
  String get thresholdStale => 'de fa més de 6 mesos';

  @override
  String get thresholdsCoachLocked =>
      'El teu entrenador gestiona els teus llindars, així que no es poden canviar aquí.';

  @override
  String get mediaTitle => 'Fotos i vídeos';

  @override
  String get mediaAdd => 'Afegeix';

  @override
  String get mediaFromLibrary => 'Tria de la fototeca';

  @override
  String get mediaTakePhoto => 'Fes una foto';

  @override
  String get mediaRecordVideo => 'Grava un vídeo';

  @override
  String mediaAdding(int done, int total) {
    return 'S’està afegint $done de $total…';
  }

  @override
  String get mediaMoveEarlier => 'Mou abans';

  @override
  String get mediaMoveLater => 'Mou després';

  @override
  String get mediaDeleteTitle => 'Vols eliminar-ho de Fjelia?';

  @override
  String get mediaDeleteMessage =>
      'La foto o el vídeo es treu de Fjelia. L’original es queda a la teva fototeca.';

  @override
  String get mediaAddFailed => 'No s’han pogut afegir alguns fitxers.';

  @override
  String get mediaHint => 'Toca per veure, mantén premut per moure o eliminar.';

  @override
  String get backupVideosTitle => 'Vols incloure els vídeos?';

  @override
  String backupVideosMessage(String size) {
    return 'Els teus vídeos ocupen $size. Sense ells la còpia és molt més petita; les fotos sempre s’hi inclouen.';
  }

  @override
  String get backupWithVideos => 'Amb vídeos';

  @override
  String get backupWithoutVideos => 'Sense vídeos';

  @override
  String get mediaShareCard => 'Comparteix com a targeta';

  @override
  String get mediaShareCardHint =>
      'Arrossega el quadre o la ruta per moure’ls. Pessiga i arrossega la foto per enquadrar-la; toca dues vegades per restablir-la.';

  @override
  String get shareGymPhoto => 'Foto del gimnàs';

  @override
  String get shareWithoutPhoto => 'Sense foto';

  @override
  String get shareStyleGlass => 'Vidre';

  @override
  String get shareStylePoster => 'Pòster';

  @override
  String get shareStyleMinimal => 'Minimal';

  @override
  String get shareStyleNeon => 'Neó';

  @override
  String get shareStyleSticker => 'Adhesiu';

  @override
  String get shareStyleReceipt => 'Tiquet';

  @override
  String get shareStyleKpop => 'K-pop';

  @override
  String get shareStylePixel => 'Píxel';

  @override
  String get shareStyleRobot => 'Robot';

  @override
  String get shareStyleScifi => 'Ciència-ficció';

  @override
  String get shareStyleCard => 'Carta col·leccionable';

  @override
  String get shareStyleComic => 'Còmic';

  @override
  String get shareStyleOutdoor => 'Outdoor';

  @override
  String get shareStyleHolo => 'Carta holo';

  @override
  String get shareStyleHoloFull => 'Carta full art';

  @override
  String nowcastRainSoon(int minutes) {
    return 'Pluja d’aquí a uns $minutes min';
  }

  @override
  String nowcastRainingStops(int minutes) {
    return 'Plou · sec d’aquí a uns $minutes min';
  }

  @override
  String nowcastRainingOn(int minutes) {
    return 'Plou, com a mínim $minutes min més';
  }

  @override
  String nowcastDry(int minutes) {
    return 'Sec durant els propers $minutes min';
  }

  @override
  String get sunAndMoon => 'Sol i lluna';

  @override
  String get moonNew => 'Lluna nova';

  @override
  String get moonWaxingCrescent => 'Lluna creixent';

  @override
  String get moonFirstQuarter => 'Quart creixent';

  @override
  String get moonWaxingGibbous => 'Gibosa creixent';

  @override
  String get moonFull => 'Lluna plena';

  @override
  String get moonWaningGibbous => 'Gibosa minvant';

  @override
  String get moonLastQuarter => 'Quart minvant';

  @override
  String get moonWaningCrescent => 'Lluna minvant';

  @override
  String moonLit(int percent) {
    return '$percent % il·luminada';
  }

  @override
  String daylightLength(int hours, int minutes) {
    return '$hours h $minutes min de llum';
  }

  @override
  String h10Battery(int level) {
    return 'Bateria $level %';
  }

  @override
  String get h10BatteryUnknown => 'Bateria encara no llegida';

  @override
  String h10BatteryChecked(String date) {
    return 'Comprovada $date';
  }

  @override
  String get h10BatteryLowHint => 'Baixa: canvia aviat la pila CR2025.';

  @override
  String get h10BatteryCheck => 'Comprova la bateria';

  @override
  String get h10BatteryUnreachable =>
      'L’H10 no ha respost. Posa-te’l (o humiteja els contactes) i torna-ho a provar.';

  @override
  String get shareRaceCalendar => 'Comparteix el calendari de curses';

  @override
  String get raceSeasonTitle => 'La meva temporada de curses';

  @override
  String get raceShareStylePoster => 'Pòster';

  @override
  String get raceShareStyleTickets => 'Entrades';

  @override
  String get raceShareStyleTimeline => 'Cronologia neó';

  @override
  String get raceShareStyleMagazine => 'Revista';

  @override
  String get raceShareShowTarget => 'Mostra els temps objectiu';

  @override
  String get bpOptimal => 'ÒPTIMA';

  @override
  String get bpHighNormal => 'NORMAL-ALTA';

  @override
  String get bpLow => 'BAIXA';

  @override
  String get bpLowHint => 'Tensió baixa: només importa si et mareges.';

  @override
  String get waistCircumference => 'Perímetre de cintura';

  @override
  String get hipOptional => 'Maluc (opcional)';

  @override
  String get waistToHeightRatio => 'Índex cintura-alçada';

  @override
  String get waistToHipRatio => 'Índex cintura-maluc';

  @override
  String get waistRiskLow => 'Molt prim';

  @override
  String get waistRiskHealthy => 'Saludable';

  @override
  String get waistRiskIncreased => 'Risc augmentat';

  @override
  String get waistRiskHigh => 'Risc alt';

  @override
  String get waistHowToMeasure =>
      'Mesura al matí, dret, després d’expirar: la cintura a mig camí entre l’última costella i la cresta ilíaca, el maluc al punt més ample.';

  @override
  String get waistNeedsHeight =>
      'Afegeix la teva alçada a Configuració → Perfil.';

  @override
  String get waistNeedsHip => 'Mesura el maluc un cop per al WHR.';

  @override
  String get waistSyncsProfile =>
      'La mesura més recent és també la teva cintura a la configuració.';

  @override
  String get waistChange30d => '30 dies';

  @override
  String get waistChange90d => '90 dies';

  @override
  String get waistChange1y => '1 any';

  @override
  String get waistDeleteText =>
      'Això elimina la mesura de cintura seleccionada.';

  @override
  String waistAndHip(String waist, String hip) {
    return '$waist cm · maluc $hip cm';
  }

  @override
  String hipValue(String hip) {
    return 'Maluc $hip cm';
  }

  @override
  String get whtrTargetHint =>
      'Mantén la cintura per sota de la meitat de la teva alçada.';

  @override
  String get noWaistYet => 'Encara no hi ha cap cintura mesurada.';

  @override
  String get enterValidWaist => 'Introdueix cintura i maluc entre 20 i 300 cm.';

  @override
  String get waistFromProfile => 'Del teu perfil, sense data';

  @override
  String get phaseBase => 'BASE';

  @override
  String get phaseBuild => 'DESENVOLUPAMENT';

  @override
  String get phasePeak => 'PIC';

  @override
  String get phaseTaper => 'AFINAMENT';

  @override
  String get phaseRecovery => 'RECUPERACIÓ';

  @override
  String get phaseRace => 'CURSA';

  @override
  String get sessionTypeKey => 'CLAU';

  @override
  String get sessionTypeLong => 'LLARG';

  @override
  String get sessionTypeRecovery => 'RECUPERACIÓ';

  @override
  String get sessionTypeAssessment => 'TEST';

  @override
  String get sessionTypeEndurance => 'RESISTÈNCIA';

  @override
  String get sessionTypeStrength => 'FORÇA';

  @override
  String get sessionTypeYoga => 'IOGA';

  @override
  String get sessionStatusCompleted => 'COMPLETAT';

  @override
  String get sessionStatusAdapted => 'ADAPTAT';

  @override
  String get stepWarmUp => 'Escalfament';

  @override
  String get stepCoolDown => 'Tornada a la calma';

  @override
  String get stepRecovery => 'Recuperació';

  @override
  String get stepRest => 'Descans';

  @override
  String get stepInterval => 'Interval';

  @override
  String get stepWorkout => 'Entrenament';

  @override
  String stepRepeat(int n) {
    return '$n× repetir';
  }

  @override
  String get stepOpenEnded => 'Sense final';

  @override
  String stepSeconds(int n) {
    return '$n s';
  }

  @override
  String get objectiveOptionalVariety =>
      'Varietat opcional triada a la configuració';

  @override
  String get objectiveStrengthSupport =>
      'Força per donar suport al teu entrenament';

  @override
  String objectiveIntervals(String goal) {
    return 'Intervals per a $goal';
  }

  @override
  String objectiveSteady(String sport, String goal) {
    return '$sport: sessió de qualitat constant per a $goal';
  }

  @override
  String objectiveEasyRecovery(String sport, String goal) {
    return '$sport suau: recuperació al voltant de $goal';
  }

  @override
  String objectiveEasyEndurance(String sport, String goal) {
    return '$sport: resistència suau per a $goal';
  }

  @override
  String objectiveLong(String sport, String goal) {
    return '$sport: sessió llarga per a $goal';
  }

  @override
  String unmetWeekMinutes(int minutes, String sport, String goal) {
    return 'La setmana té $minutes min, massa poc per a una sessió llarga ($sport) per a $goal.';
  }

  @override
  String unmetWeekHours(String hours, String what) {
    return 'La setmana té $hours h, massa poc per a: $what.';
  }

  @override
  String unmetTrainingDays(String what) {
    return 'No hi ha prou dies d’entrenament per a: $what.';
  }

  @override
  String get altMoveOneEvent => 'Moure un dels esdeveniments';

  @override
  String get altMarkOneCancelled => 'Marcar-ne un com a cancel·lat';

  @override
  String altMakePriorityB(String goal) {
    return 'Posar $goal amb prioritat B';
  }

  @override
  String altSkipGoal(String goal) {
    return 'Saltar $goal';
  }

  @override
  String altTreatAsTraining(String goal) {
    return 'Fer $goal com a cursa d’entrenament';
  }

  @override
  String altControlledEffort(String goal) {
    return 'Fer $goal amb un esforç controlat';
  }

  @override
  String conflictSameDay(String a, String b) {
    return '$a i $b són el mateix dia. Només se’n pot córrer una.';
  }

  @override
  String conflictBothPriorityA(String a, String b, int gap, int more) {
    return '$a i $b tenen tots dos prioritat A i estan a $gap dies. La recuperació després del primer i la posada a punt per al segon necessiten $more dies més.';
  }

  @override
  String conflictFlexibleOverlap(
    String a,
    String b,
    int gap,
    int overlap,
    String skip,
  ) {
    return '$a i $b estan a $gap dies i se solapen $overlap dies. $skip està marcat com a flexible: descartar-lo alliberaria les setmanes abans de l’altre esdeveniment.';
  }

  @override
  String conflictRecoveryOverlap(String a, String b, int gap, int overlap) {
    return '$a i $b estan a $gap dies: la recuperació després del primer se solapa $overlap dies amb la posada a punt per al segon. La preparació de menor prioritat es limita per protegir l’altra.';
  }

  @override
  String conflictTightSpacing(String a, String b, int gap, int spare) {
    return '$a i $b estan a $gap dies. Recuperació i posada a punt hi caben amb $spare dies de marge: qualsevol contratemps no deixa espai.';
  }

  @override
  String seasonShortened(int n, int of) {
    return 'En $n de $of setmanes el temps setmanal no arriba per a totes les sessions llargues de cada objectiu, així que s’escurcen juntes.';
  }

  @override
  String seasonAlternating(int n) {
    return 'En $n setmanes no hi caben totes les sessions llargues; els esports s’alternen.';
  }

  @override
  String seasonLongAway(int n) {
    return 'En $n setmanes una sessió llarga de més de dues hores i mitja no és al seu dia habitual, pels teus dies de descans i les altres sessions.';
  }

  @override
  String seasonMovedOntoEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n sessions que has mogut cauen en un dia d’esdeveniment o en el descans previ. El pla les deixa on les vas posar.',
      one: '1 sessió que has mogut cau en un dia d’esdeveniment o en el descans previ. El pla la deixa on la vas posar.',
    );
    return '$_temp0';
  }

  @override
  String seasonNoRoom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'S’han tret $n sessions perquè els entrenaments triats duraven més que el temps que quedava a la setmana.',
      one: 'S’ha tret 1 sessió perquè l’entrenament triat durava més que el temps que quedava a la setmana.',
    );
    return '$_temp0';
  }

  @override
  String seasonMovedHardNearEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n sessions dures que has mogut cauen en els dies suaus després d’un esdeveniment. El pla les deixa on les vas posar.',
      one: '1 sessió dura que has mogut cau en els dies suaus després d’un esdeveniment. El pla la deixa on la vas posar.',
    );
    return '$_temp0';
  }

  @override
  String get seasonEventWeeks =>
      'A les setmanes d’esdeveniment, l’esdeveniment compta com a entrenament, així que la resta de la setmana és més lleugera.';

  @override
  String seasonUnmet(int n, String detail) {
    return 'En $n setmanes els dies d’entrenament no contenen totes les sessions protegides: $detail';
  }

  @override
  String seasonNoHistory(String sport, String priority) {
    return 'No hi ha entrenament recent ($sport) al teu historial, així que el pla per a l’objectiu $priority és provisional.';
  }

  @override
  String get zoneRecovery => 'Recuperació';

  @override
  String workoutSentKeptInFjelia(String provider, String items) {
    return 'Enviat a $provider. Només a Fjelia: $items.';
  }

  @override
  String paceGuideRange(String low, String high) {
    return 'Guia de ritme de $low a $high';
  }

  @override
  String get paceGuideFromGoal => ', estimat a partir del teu objectiu';

  @override
  String paceGuideGoalFlat(String pace) {
    return ' · ritme objectiu en pla $pace';
  }

  @override
  String get paceGuideHeartRateDecides => 'Decideix la freqüència cardíaca.';

  @override
  String get moveKeyRestDay => 'dia de descans';

  @override
  String get moveKeyEvent => 'esdeveniment';

  @override
  String get moveKeyEasyOnly => 'només suau';

  @override
  String get moveKeyHasSession => 'té sessió';

  @override
  String get calendarCompleted => 'Completat';

  @override
  String get calendarPlanned => 'Planificat';

  @override
  String get recentlyDeleted => 'Eliminades recentment';

  @override
  String get recentlyDeletedExplain =>
      'Les activitats eliminades continuen eliminades, també quan els dispositius tornen a sincronitzar. Restaura-ne una per recuperar-la; la seva font torna a enviar la ruta i les corbes si encara les té.';

  @override
  String get noDeletedActivities => 'No hi ha activitats eliminades.';

  @override
  String activityDeleted(String name) {
    return '$name eliminada';
  }

  @override
  String activityRestored(String name) {
    return '$name restaurada';
  }

  @override
  String activityRestoredSummaryOnly(String name) {
    return '$name restaurada amb els totals; la seva font ja no envia la ruta ni les corbes.';
  }

  @override
  String deletedOn(String date) {
    return 'eliminada el $date';
  }

  @override
  String get restore => 'Restaura';

  @override
  String get coachWhyThisToday => 'Per què aquest entrenament avui?';

  @override
  String get coachHowDidItGo => 'Com ha anat aquesta sessió?';

  @override
  String get coachWhyRestDay => 'Per què és un dia de descans?';

  @override
  String get coachWhatInstead => 'Què hauria de fer en lloc d’això?';

  @override
  String get newChat => 'Xat nou';

  @override
  String weekOfPlanned(String duration) {
    return 'de $duration planificats';
  }

  @override
  String get weekDoneNothingPlanned => 'fet · cap entrenament planificat';

  @override
  String sessionDropped(String reason, String duration) {
    return '$reason · $duration descartats';
  }

  @override
  String get importTitle => 'Importa';

  @override
  String get stravaArchive => 'Arxiu de Strava';

  @override
  String get stravaArchiveZip => 'Arxiu de Strava (ZIP)';

  @override
  String get stravaArchiveSubtitle =>
      'Tot el teu historial de Strava amb rutes i fotos';

  @override
  String get stravaIntro =>
      'Porta tot el teu historial de Strava a Fjelia: activitats amb ruta, freqüència cardíaca i potència, i les seves fotos.';

  @override
  String get stravaHowTo =>
      'A strava.com: Configuració → El meu compte → Descarrega o elimina el compte → Sol·licita l’arxiu. Strava t’envia un ZIP per correu; tria’l aquí tal qual, sense descomprimir-lo.';

  @override
  String get stravaChooseZip => 'Tria el ZIP';

  @override
  String get stravaReading => 'Llegint l’arxiu…';

  @override
  String get stravaNotArchive =>
      'Aquest ZIP no és un arxiu de compte de Strava: hi falta activities.csv.';

  @override
  String stravaFound(int count) {
    return '$count activitats trobades';
  }

  @override
  String stravaWithFiles(int count) {
    return '$count amb enregistrament (ruta i corbes)';
  }

  @override
  String stravaPhotos(int photos, int videos) {
    return '$photos fotos, $videos vídeos';
  }

  @override
  String stravaAlready(int count) {
    return '$count duplicats, ja a Fjelia o dobles a Strava: només s’afegeixen les fotos que falten';
  }

  @override
  String stravaDeletedSkip(int count) {
    return '$count eliminades abans, omeses';
  }

  @override
  String stravaNew(int count) {
    return '$count noves';
  }

  @override
  String stravaStorage(int mb) {
    return 'uns $mb MB per a fotos i vídeos';
  }

  @override
  String get stravaPrivacy =>
      'Tot es llegeix en aquest dispositiu. No es puja res i no cal iniciar sessió a Strava.';

  @override
  String stravaImportButton(int count) {
    return 'Importa $count activitats';
  }

  @override
  String get stravaImporting => 'S’està important l’arxiu de Strava';

  @override
  String stravaProgressActivities(String done, String total) {
    return 'Activitats: $done / $total';
  }

  @override
  String stravaImportedCount(int count) {
    return '$count activitats importades';
  }

  @override
  String stravaProgressPhotos(int count) {
    return 'Fotos: $count importades';
  }

  @override
  String stravaProgressDuplicates(int count) {
    return 'Duplicats: $count omesos';
  }

  @override
  String stravaProgressDeleted(int count) {
    return 'Eliminades abans: $count omeses';
  }

  @override
  String stravaProgressErrors(int count) {
    return 'Errors: $count';
  }

  @override
  String get stravaKeepOpen =>
      'Pots fer servir l’app mentrestant. Mantén Fjelia oberta fins que acabi la importació.';

  @override
  String get stravaComplete => 'Importació de Strava completada';

  @override
  String get stravaPartial => 'Importació de Strava incompleta';

  @override
  String get stravaCancelled => 'Importació de Strava cancel·lada';

  @override
  String get stravaShowErrors => 'Mostra els errors';

  @override
  String get stravaAgainHint =>
      'Tornar a importar el mateix arxiu només afegeix el que encara falta.';

  @override
  String get renameActivity => 'Canvia el nom de l’activitat';

  @override
  String get activityTitleLabel => 'Títol';

  @override
  String get activityTitleKept =>
      'El teu títol es manté quan l’activitat es torna a sincronitzar. Només canvia a Fjelia, no a la plataforma d’origen.';

  @override
  String originalTitle(String name) {
    return 'Original: $name';
  }

  @override
  String get useOriginalTitle => 'Fes servir el títol original';

  @override
  String get loadOlderActivities => 'Carrega activitats anteriors';

  @override
  String get noOlderActivities => 'No hi ha activitats anteriors';

  @override
  String get maxSpeed => 'Velocitat màx.';

  @override
  String get caloriesLabel => 'Calories';

  @override
  String get activityDescription => 'Descripció';

  @override
  String get nightCurves => 'Corbes de la nit';

  @override
  String get noPhaseTimeline =>
      'Aquest rellotge no indica quan va passar cada fase del son, només els totals de dalt. Aquests són la VFC i l’estrès que va mesurar durant la nit.';

  @override
  String get stagesEstimated =>
      'Estimat per Fjelia a partir de la VFC i l’estrès que el teu rellotge COROS va mesurar durant la nit. Els totals de les fases són els de COROS; quan va passar cada fase és una aproximació.';

  @override
  String get nightCurvesBasis =>
      'La VFC i l’estrès mesurats durant la nit. L’estimació de fases de dalt es basa en ells.';

  @override
  String get swimShort =>
      'Normalment n’hi ha prou amb aigua. No calen gels: un àpat normal abans i després cobreix aquesta sessió.';

  @override
  String get swimPoolLong =>
      'Pren una beguda amb hidrats de carboni a les pauses llargues entre sèries, sobretot si la sessió és intensa. A la piscina no calen gels.';

  @override
  String get swimOpenFeeds =>
      'Planifica hidrats i líquids al voltant dels avituallaments disponibles (barca, caiac, riba). No depenguis del que no puguis abastar amb seguretat nedant.';

  @override
  String get swimOpenUnsupported =>
      'Sense assistència no hi ha avituallament: menja bé abans, ajusta la distància i recupera just després.';

  @override
  String get swimOpenFeedsUnknown =>
      'Aigües obertes: indica a «Edita l’estratègia» si hi ha avituallament (amb o sense assistència).';

  @override
  String get swimFluidPool =>
      'Hidratar-se també compta a la piscina: a l’aigua se sua menys que a terra, però no gens. Deixa una ampolla marcada a la vora i beu a les pauses.';

  @override
  String get swimFluidOpen =>
      'La previsió no dona la temperatura de l’aigua i l’aigua freda redueix la set: beu abans de sortir, a cada avituallament i just després.';

  @override
  String get swimBeforeAfter =>
      'Abans: un àpat habitual ric en hidrats 1–4 h abans. Després: uns 1 g d’hidrats per kg amb 20–25 g de proteïna; si t’has pesat, beu uns 1,5 l per kg perdut, amb una mica de sodi.';

  @override
  String get swimNoDuration =>
      'Sense durada prevista: aigua a la vora n’hi ha prou per a la majoria de sessions; beguda amb hidrats només a partir de 90 minuts.';

  @override
  String swimCarryPool(String bottles, String bottleMl, String drinkCarbs) {
    return 'Sense gels. Ampolla a la vora: $bottles × $bottleMl ml; $drinkCarbs g d’hidrats venen de la beguda.';
  }

  @override
  String swimCarryOpen(String bottles, String bottleMl, String drinkCarbs) {
    return 'Sense gels mentre nedes. Als avituallaments: $bottles × $bottleMl ml; $drinkCarbs g d’hidrats venen de la beguda.';
  }

  @override
  String swimPerBreak(String carbs, String fluid) {
    return 'Cada 20 minuts, en una pausa o avituallament: uns $carbs g d’hidrats i $fluid ml.';
  }

  @override
  String get feedsLabel => 'Avituallament (aigües obertes)';

  @override
  String get feedsSupported => 'Amb assistència (barca, caiac, riba)';

  @override
  String get feedsUnsupported => 'Sense assistència';

  @override
  String get feedsUnknown => 'Desconegut';

  @override
  String get ecgTitle => 'ECG';

  @override
  String get ecgChooseDevice => 'Tria Polar H10';

  @override
  String get ecgStart => 'Enregistra un ECG';

  @override
  String get ecgStopSave => 'Atura i desa';

  @override
  String get ecgImport => 'Importa un fitxer ECG';

  @override
  String get ecgHistory => 'Historial d’ECG';

  @override
  String get ecgWaveform => 'Senyal';

  @override
  String get ecgReport => 'Informe';

  @override
  String get ecgExportCsv => 'Exporta el senyal (CSV)';

  @override
  String get ecgExportMetadata => 'Exporta les metadades d’ECG';

  @override
  String get ecgExportOriginal => 'Comparteix el fitxer original';

  @override
  String get ecgRecording => 'Enregistrant ECG';

  @override
  String get ecgRecordingDate => 'Data i hora de l’enregistrament';

  @override
  String get ecgLinkedWorkout => 'Entrenament vinculat';

  @override
  String get ecgIndependent => 'Sense entrenament vinculat';

  @override
  String get ecgNoRecordings => 'Encara no hi ha enregistraments d’ECG.';

  @override
  String ecgSamples(int count) {
    return '$count mostres';
  }

  @override
  String ecgSignalGaps(int count) {
    return '$count interrupcions de senyal';
  }

  @override
  String get ecgDeleteConfirm =>
      'Vols eliminar definitivament aquest enregistrament i el fitxer original?';

  @override
  String get ecgDescription =>
      'Enregistra amb Polar H10, importa senyals CSV o desa informes PDF.';

  @override
  String get ecgPrivacy =>
      'Es desa en aquest dispositiu i s’inclou a les còpies de seguretat. Els senyals bruts no s’envien a l’entrenador.';

  @override
  String get ecgLimitations =>
      'Per a enregistrament i revisió personals. Aquí no s’han validat la VFC de l’ECG ni la qualitat del senyal; no es calculen diagnòstics ni puntuacions de recuperació.';

  @override
  String get ecgImportLimitations =>
      'Els PDF de Garmin i Apple Watch són informes. Els senyals requereixen les columnes CSV time_seconds (o time_ms) i ecg_uv (o ecg_mv).';

  @override
  String get ecgReportOnly =>
      'Només informe. No hi ha mostres de senyal disponibles. Comparteix el fitxer original per veure’l.';

  @override
  String get indoorTitle => 'Entrenament a l’interior';

  @override
  String get indoorEquipment => 'Equip d’entrenament';

  @override
  String get indoorChooseEquipment => 'Tria l’equip';

  @override
  String get indoorChooseHeartRate => 'Tria el sensor cardíac';

  @override
  String get indoorStart => 'Inicia l’enregistrament';

  @override
  String get indoorPause => 'Pausa l’enregistrament';

  @override
  String get indoorFinish => 'Finalitza i desa';

  @override
  String get indoorSaved => 'Desat a l’historial d’activitats';

  @override
  String get indoorExportFit => 'Comparteix l’activitat FIT';

  @override
  String get indoorUnfinished => 'Enregistraments inacabats';

  @override
  String get indoorReviewResume => 'Revisa o reprèn';

  @override
  String get indoorDiscard => 'Descarta l’enregistrament';

  @override
  String get indoorDiscardConfirm =>
      'Vols descartar definitivament aquest enregistrament inacabat?';

  @override
  String get indoorExternalHeartRate => 'Utilitza el sensor cardíac extern';

  @override
  String get indoorEquipmentHeartRate =>
      'Desactivat: utilitza el pols de l’equip';

  @override
  String get indoorCurrentInterval => 'Interval actual';

  @override
  String get indoorNextInterval => 'Interval següent';

  @override
  String get indoorPlanComplete => 'Intervals planificats completats';

  @override
  String get indoorAuthorizeControl => 'Permet el control de l’equip';

  @override
  String get indoorManualOverride => 'Utilitza el control manual';

  @override
  String get indoorAutoPower =>
      'Segueix automàticament la potència dels intervals';

  @override
  String get indoorApplyTarget => 'Aplica l’objectiu';

  @override
  String get indoorDescription =>
      'Connecta un equip Bluetooth FTMS i enregistra un entrenament a l’interior.';

  @override
  String get indoorKeepOpen =>
      'L’enregistrament continua en una altra app o amb la pantalla bloquejada. Pausa atura les dades; fes servir els controls de la màquina per posar-la en pausa.';

  @override
  String get indoorFitHint =>
      'Desa el fitxer FIT o obre’l en una aplicació compatible des del menú per compartir.';

  @override
  String get indoorNoEquipment =>
      'No s’ha trobat cap equip FTMS. Activa l’equip i la connexió Bluetooth.';

  @override
  String get indoorControlPrompt =>
      'Vols permetre que Fjelia canviï els objectius d’aquesta sessió? Mantén-te a prop dels controls. Pots tornar al control manual en qualsevol moment.';

  @override
  String get indoorTreadmillSafety =>
      'Col·loca la clau de seguretat i mantén-te a prop dels controls. Confirma només canvis petits, fins a 0,5 km/h o 1% de pendent. Utilitza l’equip per a canvis més grans.';

  @override
  String get recordingTime => 'Temps d’enregistrament';

  @override
  String get recordingSpeed => 'Velocitat';

  @override
  String get recordingPower => 'Potència';

  @override
  String get recordingCadence => 'Cadència / palades';

  @override
  String get recordingIncline => 'Pendent';

  @override
  String get recordingResistance => 'Resistència';

  @override
  String get recordingSource => 'Origen';

  @override
  String get recordingNext => 'Pas següent';

  @override
  String get recordingConnecting => 'S’està connectant';

  @override
  String get recordingReconnecting => 'S’està reconnectant';

  @override
  String get recordingInterrupted => 'Interromput';

  @override
  String get recordingPaused => 'En pausa';

  @override
  String get indoorMatrixReadOnly =>
      'Només enregistrament a les cintes Matrix. Ajusta la velocitat i el pendent a la consola; el control remot no està verificat per a aquest model.';

  @override
  String ecgCoverage(String value) {
    return '$value% de mostres capturades';
  }

  @override
  String get recordingBeforeRestore =>
      'Finalitza l’enregistrament abans de restaurar una còpia de seguretat.';

  @override
  String get gymTitle => 'Cintes del gimnàs';

  @override
  String get gymDescription =>
      'Enregistra amb el telèfon, importa sessions xID o escaneja el resum de la consola.';

  @override
  String get gymDirectConnection => 'Connexió directa';

  @override
  String get gymConsoleSupport =>
      'La connexió depèn de la consola. Les consoles Matrix antigues poden oferir xID en lloc de dades Bluetooth en directe.';

  @override
  String get gymFindEquipment => 'Cerca aparells';

  @override
  String get gymLiveAvailable =>
      'Aquesta consola pot enviar dades directament a Fjelia.';

  @override
  String get gymLiveUnavailable =>
      'No s’han trobat dades en directe compatibles. Importa sessions xID o desa un resum de la consola.';

  @override
  String get gymSpeedOnly =>
      'Hi ha velocitat i cadència disponibles. Aquesta connexió no ofereix inclinació ni control remot.';

  @override
  String get gymUseMachine => 'Utilitza aquest aparell';

  @override
  String get gymConnectionReport => 'Informe de connexió';

  @override
  String get gymShareReport => 'Comparteix l’informe de connexió';

  @override
  String get gymXid => 'Matrix xID';

  @override
  String get gymXidDescription =>
      'Importa sessions de cinta desades per la xarxa xID del gimnàs.';

  @override
  String get gymPortal => 'Portal Netpulse del gimnàs';

  @override
  String get gymPortalHelp =>
      'Introdueix l’adreça del portal Netpulse facilitada pel gimnàs.';

  @override
  String get gymPasscode => 'Codi xID';

  @override
  String get gymSessionHelp =>
      'La sessió es desa de manera segura. El codi no es desa.';

  @override
  String get gymAutoSync => 'Sincronitza sessions xID automàticament';

  @override
  String gymLastDays(int days) {
    return 'Últims $days dies';
  }

  @override
  String get gymLoadWorkouts => 'Carrega sessions';

  @override
  String get gymNoWorkouts =>
      'No s’han trobat sessions de cinta en aquest període.';

  @override
  String gymSkipped(int count) {
    return 'S’han omès $count sessions il·legibles.';
  }

  @override
  String gymImported(int count, int duplicates) {
    return '$count sessions importades; $duplicates duplicats omesos.';
  }

  @override
  String get gymSummary => 'Resum de la cinta';

  @override
  String get gymSummaryDescription =>
      'Fotografia la pantalla final de la consola i revisa els valors abans de desar.';

  @override
  String get gymTakePhoto => 'Fes una foto';

  @override
  String get gymChoosePhoto => 'Tria una foto';

  @override
  String get gymReview =>
      'Comprova unitats, hora d’inici i valors. Les fotos es llegeixen al telèfon. Només es desa el resum.';

  @override
  String get gymStartTime => 'Inici de la sessió';

  @override
  String get gymDurationHelp =>
      'Introdueix mm:ss o hh:mm:ss, per exemple 30:00.';

  @override
  String get gymDistanceUnit => 'Unitat de distància';

  @override
  String get gymCalories => 'Calories';

  @override
  String get manualRecordTitle => 'Enregistra una activitat';

  @override
  String get manualRecordDescription =>
      'Enregistra una activitat amb GPS, ECG i freqüència cardíaca opcionals. L’enregistrament continua en canviar d’app o bloquejar la pantalla, fins que premis Pausa o Atura.';

  @override
  String get manualTreadmill => 'Cursa en cinta';

  @override
  String get manualChooseH10 => 'Tria un Polar H10';

  @override
  String get manualRecordEcg => 'Enregistra ECG amb Polar H10';

  @override
  String get manualChooseHelp =>
      'Tria un Polar H10 per enregistrar ECG i freqüència cardíaca.';

  @override
  String manualEcgSegments(int count) {
    return 'Segments ECG vinculats: $count';
  }

  @override
  String get manualEcgInterrupted =>
      'ECG aturat. El cronòmetre de l’activitat continua.';

  @override
  String get manualRestartEcg => 'Reinicia l’enregistrament ECG';

  @override
  String get manualFinalDistance => 'Distància final (opcional)';

  @override
  String get manualDiscardNote =>
      'Vols descartar aquesta activitat? Els enregistraments ECG es conserven a l’historial ECG.';

  @override
  String get manualRecordHeartRate => 'Enregistra la freqüència cardíaca';

  @override
  String get manualChooseHr => 'Tria un sensor cardíac';

  @override
  String get manualHrWithEcg => 'Fa servir la mateixa connexió H10 que l’ECG.';

  @override
  String get manualRecordGps => 'Enregistra el recorregut GPS i la distància';

  @override
  String get manualGpsHelp =>
      'Per a activitats a l’aire lliure. Permet la ubicació precisa per enregistrar amb la pantalla apagada.';

  @override
  String get manualGpsWaiting => 'Esperant una posició GPS precisa';

  @override
  String manualGpsAccuracy(int meters) {
    return 'Precisió GPS: $meters m';
  }

  @override
  String get manualRecordBp => 'Inclou mesures de pressió arterial';

  @override
  String get manualBpHelp =>
      'Mostra les mesures de Hilo, Aktiia i Health preses durant l’enregistrament, també després de sincronitzacions posteriors.';

  @override
  String get manualBpUnavailable =>
      'No s’han pogut carregar les mesures de pressió arterial.';

  @override
  String get manualBpEmpty =>
      'Cap mesura de pressió arterial durant aquest enregistrament.';

  @override
  String get manualHrDisconnected => 'Sensor cardíac desconnectat.';

  @override
  String get manualReconnectHr => 'Torna a connectar el sensor cardíac';

  @override
  String get manualBackgroundNotification =>
      'L’enregistrament continua amb la pantalla apagada';

  @override
  String get ecgAskCoach => 'Parlar-ne amb l\'entrenador IA';

  @override
  String get ecgCoachWarningTitle => 'No és consell mèdic';

  @override
  String get ecgCoachWarningBody =>
      'L\'entrenador IA no és un metge i no pot fer cap diagnòstic. Un ECG de cinta pectoral només té una derivació: no pot descartar un infart ni altres malalties del cor, i l\'anàlisi pot ser errònia.\n\nDolor o pressió al pit, falta d\'aire, dolor al braç, la mandíbula o l\'esquena, suor freda o desmai: truca ara al 112. No esperis la resposta de la IA.\n\nEls valors analitzats i 10 segons del senyal en brut van al model d\'IA triat a la configuració d\'IA.';

  @override
  String get ecgCoachUnderstood => 'Entesos';

  @override
  String get ecgCoachBanner =>
      'No és consell mèdic. La IA no és un metge i no pot descartar un infart. Emergència: truca al 112.';

  @override
  String get ecgCoachCardTitle => 'Preanàlisi de l\'ECG';

  @override
  String get statusMeasured => 'Mesurat';

  @override
  String get ecgQuestionOverview => 'Què mostra el meu ECG?';

  @override
  String get ecgQuestionRhythm => 'El meu ritme cardíac és regular?';

  @override
  String get ecgQuestionDoctor => 'L\'hauria de mirar un metge?';

  @override
  String get ecgFollowSymptoms =>
      'Amb quins símptomes hauria d\'anar al metge?';

  @override
  String get ecgFollowRiskFactors => 'Què canvien els meus factors de risc?';

  @override
  String get ecgFollowTraining => 'Puc entrenar amb normalitat?';

  @override
  String get ecgFollowBetterRecording => 'Com enregistro un ECG millor?';

  @override
  String get manualTreadmillConnect =>
      'Connecta la cinta de córrer (Bluetooth, opcional)';

  @override
  String get manualTreadmillHelp =>
      'La velocitat, la distància i el pendent vénen llavors de la cinta. Sense connexió, introdueix la distància al final.';

  @override
  String get sportIndoorCycling => 'Ciclisme a l’interior';

  @override
  String get sportElliptical => 'El·líptica';

  @override
  String get sportStairClimber => 'Escaladora';

  @override
  String get manualWrongMachine =>
      'Aquest equip no correspon a l’esport triat.';

  @override
  String get manualEquipmentHelp =>
      'Connecta un equip Bluetooth (FTMS). La velocitat, la potència, la cadència i la distància vénen de l’equip.';

  @override
  String get plusTitle => 'Registra';

  @override
  String get plusStartWorkout => 'Comença l’entrenament';

  @override
  String get plusStartWorkoutHint =>
      'En directe amb GPS, cinta o bici indoor · ECG i pols';

  @override
  String get plusGroupTraining => 'Entrenament';

  @override
  String get plusGroupHeart => 'Cor i circulació';

  @override
  String get plusGroupBody => 'Cos';

  @override
  String get plusGroupRecovery => 'Recuperació';

  @override
  String get plusLogWorkout => 'Afegeix entrenament';

  @override
  String get plusLogWorkoutHint => 'Una sessió passada, a mà';

  @override
  String get plusImport => 'Importa';

  @override
  String get plusImportHint => 'Strava, FIT, GPX, cinta del gimnàs';

  @override
  String get plusEcg => 'Enregistra ECG';

  @override
  String get plusEcgHint => 'Polar H10 o fitxer ECG';

  @override
  String get plusHrv => 'Check de VFC';

  @override
  String get plusHrvHint => 'Mesura curta amb Polar H10';

  @override
  String get plusBpMeasure => 'Mesura amb el maneguet Hilo';

  @override
  String get plusBpMeasureHint => 'Vincula el maneguet Hilo per Bluetooth';

  @override
  String get plusBpLog => 'Anota la pressió';

  @override
  String get plusBpLogHint => 'Escriu una mesura';

  @override
  String get plusBpReport => 'Informe Hilo';

  @override
  String get plusBpReportHint => 'Importa el PDF';

  @override
  String get plusSpo2 => 'SpO₂ i pols';

  @override
  String get plusSpo2Hint => 'Des d’un pulsioxímetre';

  @override
  String get plusWeigh => 'Pesa’t';

  @override
  String get plusWeighHint => 'Bàscula RENPHO per Bluetooth';

  @override
  String get plusWeightLog => 'Anota el pes';

  @override
  String get plusWeightLogHint => 'Pes, greix, IMC';

  @override
  String get plusWaist => 'Cintura';

  @override
  String get plusWaistHint => 'Perímetre i ràtios';

  @override
  String get plusGrip => 'Força de prensió';

  @override
  String get plusGripHint => 'Valor del dinamòmetre';

  @override
  String get plusSleep => 'Anota el son';

  @override
  String get plusSleepHint => 'Durada, profund i REM';

  @override
  String get recPace => 'Ritme (/km)';

  @override
  String get recAvgPace => 'Ritme mitjà';

  @override
  String get recPace500 => 'Ritme (/500 m)';

  @override
  String get recSpeedKmh => 'Velocitat (km/h)';

  @override
  String get recPowerW => 'Potència (W)';

  @override
  String get recDistanceKm => 'Distància (km)';

  @override
  String get recHeartRate => 'Pols';

  @override
  String get recMap => 'Mapa';

  @override
  String get recStart => 'Inicia';

  @override
  String get recResume => 'Reprèn';

  @override
  String get recFinish => 'Acaba';

  @override
  String get recDiscard => 'Descarta';

  @override
  String get recLive => 'Enregistrant';

  @override
  String get recNew => 'Nova activitat';

  @override
  String get recCadence => 'Cadència';

  @override
  String get recMachine => 'Equip';

  @override
  String get recGps => 'GPS';

  @override
  String get recEcg => 'ECG';

  @override
  String get recBloodPressure => 'Pressió';

  @override
  String get recBannerOpen => 'Toca per obrir';

  @override
  String get bpActivityHint =>
      'Els maniguets sovint no mesuren en moviment. Les mesures d’abans o després de l’activitat no surten aquí.';

  @override
  String objectiveKeyLong(String sport, String goal) {
    return '$sport: sessió llarga clau per a $goal';
  }

  @override
  String seasonKeyRides(int n) {
    return 'En $n setmanes una sessió llarga clau avança cap a la meitat de la prova, un cop per bloc i mai al costat d\'una altra prova.';
  }

  @override
  String seasonEventAsLong(int n) {
    return 'En $n setmanes una altra prova és la sessió llarga per a un objectiu més gran.';
  }

  @override
  String objectiveThreshold(String sport, String goal) {
    return '$sport al llindar per a $goal';
  }

  @override
  String objectiveHills(String sport, String goal) {
    return '$sport en pujada per a $goal';
  }

  @override
  String objectiveOpeners(String goal) {
    return 'Activació curta per a $goal';
  }

  @override
  String get planAdjustedTitle => 'Pla ajustat automàticament';

  @override
  String planAdjSwap(String session, String day, String from) {
    return '$session: feta el $day en lloc del $from.';
  }

  @override
  String planAdjSubstitute(String activity, String session, String from) {
    return '$activity compta com a $session del $from.';
  }

  @override
  String planAdjStrengthCredit(String activity, String session) {
    return '$activity cobreix la força de cames de $session.';
  }

  @override
  String planAdjMoved(String session, String day) {
    return '$session passa al $day, que ha quedat lliure.';
  }

  @override
  String planAdjMovedEasy(String session, String day, String activity) {
    return '$session passa al $day, més suau: les cames es recuperen de $activity.';
  }

  @override
  String get planAdjUndone => 'Canvi desfet.';

  @override
  String get shortSessionTitle => 'Més curt del previst: per què?';

  @override
  String shortSessionLine(String session, int done, int planned) {
    return '$session: $done de $planned min';
  }

  @override
  String get shortReasonTime => 'Sense temps';

  @override
  String get shortReasonWeather => 'Temps';

  @override
  String get shortReasonFatigue => 'Cansat';

  @override
  String get shortReasonPain => 'Dolor';

  @override
  String get shortReasonOther => 'Altre';

  @override
  String get styleTitle => 'Estil';

  @override
  String get styleAuto => 'Automàtic';

  @override
  String get styleAutoHint =>
      'Segueix el telèfon: LightFjelia de dia, DarkFjelia de nit.';

  @override
  String get connectMyWhoosh => 'Connecta MyWhoosh';

  @override
  String get myWhooshSubtitle =>
      'Inicia sessió amb el teu compte de MyWhoosh per portar les teves sortides indoor amb potència, cadència i freqüència cardíaca.';

  @override
  String get myWhooshCredentialsInfo =>
      'Les credencials de MyWhoosh es desen xifrades al teu dispositiu. Fjelia llegeix les sortides directament de MyWhoosh, a través de la interfície de l\'app de MyWhoosh. Fjelia no està afiliada a MyWhoosh.';

  @override
  String get myWhooshTile => 'Sortides indoor';

  @override
  String get myWhooshSignedInElsewhere =>
      'MyWhoosh només permet una sessió per compte i has iniciat sessió en un altre dispositiu. Tanca MyWhoosh allà (tanca la sessió si cal) i torna-ho a provar.';

  @override
  String get shareWorkout => 'Comparteix l\'entrenament';

  @override
  String get shareFitFile => 'Comparteix com a fitxer FIT';

  @override
  String get shareFitFileHint =>
      'Per a Strava, COROS, TrainingPeaks i altres apps';

  @override
  String get sendToGarmin => 'Envia a Garmin Connect';

  @override
  String get sendToGarminHint => 'Puja l\'entrenament al teu compte de Garmin';

  @override
  String get sentToGarmin => 'Enviat a Garmin Connect';

  @override
  String get alreadyOnGarmin => 'Aquest entrenament ja és a Garmin Connect';

  @override
  String get missedWorkoutPastTitle => 'Entrenament perdut';

  @override
  String get leaveIt => 'Deixa-ho així';

  @override
  String get reviewChange => 'Mira';

  @override
  String get keepPlan => 'Mantén el pla';

  @override
  String get missedYesterdayTitle => 'Perdut ahir';

  @override
  String get proposalReplanTitle => 'Recalcular el pla?';

  @override
  String get proposalRestTitle => 'Avui millor descans?';

  @override
  String get proposalRecoveryTitle => 'Avui només suau?';

  @override
  String get proposalEasierTitle => 'Avui una mica més suau?';

  @override
  String get proposalReplanBody =>
      'La càrrega o la VFC apunten a un pla recalculat.';

  @override
  String get proposalCardTitle => 'Suggeriment per a avui';

  @override
  String get replanMissed => 'Reprograma';

  @override
  String get askBeforePlanChanges => 'Pregunta abans de canviar el pla';

  @override
  String get askBeforePlanChangesHint =>
      'La preparació i les tendències proposen canvis, tu decideixes. Desactivat: Fjelia ajusta el pla sola.';

  @override
  String missedOnDayTitle(String day) {
    return 'Perdut el $day';
  }

  @override
  String missedPastBody(String names) {
    return '$names. Moure o saltar?';
  }

  @override
  String proposalDropsLine(String title) {
    return '$title queda anul·lat';
  }

  @override
  String proposalChangeLine(String from, String to) {
    return '$from → $to';
  }

  @override
  String get proposalAnswered => 'Ja respost, no queda res per decidir.';

  @override
  String get ecgTrainingWarningTitle => 'Només per entrenar';

  @override
  String get ecgTrainingWarningBody =>
      'Fjelia no interpreta els ECG des del punt de vista mèdic. El coach només explica la freqüència cardíaca, la VFC i la qualitat del senyal per al teu entrenament. No diu res de malalties cardíaques ni de trastorns del ritme: per a això, exporta l\'enregistrament i ensenya\'l a un metge.\n\nDolor o pressió al pit, falta d\'aire, dolor al braç, la mandíbula o l\'esquena, suor freda o desmai: truca ara al 112.\n\nLa freqüència cardíaca, la VFC i la qualitat del senyal s\'envien al model d\'IA triat a la configuració d\'IA.';

  @override
  String get ecgQuestionTraining => 'Què diu el meu ECG per a l\'entrenament?';

  @override
  String get ecgFollowHrv => 'Què diu la VFC de la meva recuperació?';

  @override
  String get ecgFollowHeartRate =>
      'Com ha evolucionat la meva freqüència cardíaca?';

  @override
  String get bioLeanMuchYounger => 'Molt més jove';

  @override
  String get bioLeanYounger => 'Més jove';

  @override
  String get bioLeanEven => 'Just a la mitjana';

  @override
  String get bioLeanOlder => 'Una mica de marge';

  @override
  String get bioLeanMuchOlder => 'Molt de marge';

  @override
  String get fitnessSameAsAge => 'En forma com la teva edat';

  @override
  String get lifespanBandTitle => 'El teu horitzó de vida';

  @override
  String get lifespanBandNote =>
      'Un interval de l\'estadística per a persones amb valors semblants, no una predicció per a tu.';

  @override
  String get factorHelps => 'T\'ajuda';

  @override
  String get factorSlows => 'Et frena';

  @override
  String get bioFactorBloodPressure => 'Pressió arterial';

  @override
  String get bioFactorVisceralFat => 'Greix visceral';

  @override
  String get bioFactorLipids => 'Lípids en sang';

  @override
  String get bioFactorInflammation => 'Inflamació (PCR)';

  @override
  String get bioFactorKidney => 'Funció renal';

  @override
  String get bioAgeModelNote =>
      'L\'edat de forma compara el teu VO₂màx amb normes per edat. L\'horitzó de vida surt d\'un model basat en estudis: ni afirmació mèdica ni predicció personal.';

  @override
  String fitnessYoungerBy(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anys més jove que la teva edat',
      one: '1 any més jove que la teva edat',
    );
    return '$_temp0';
  }

  @override
  String fitnessOlderBy(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anys per sobre de la teva edat',
      one: '1 any per sobre de la teva edat',
    );
    return '$_temp0';
  }

  @override
  String lifespanBandYears(int low, int high) {
    return '$low–$high';
  }

  @override
  String todayAge(int age) {
    return 'Avui $age';
  }

  @override
  String get vo2ClassBelowAvg => 'per sota de la mitjana';

  @override
  String get vo2ClassAverage => 'a la mitjana';

  @override
  String get vo2ClassAboveAvg => 'per sobre de la mitjana';

  @override
  String get vo2ClassGood => 'bo';

  @override
  String get vo2ClassExcellent => 'excel·lent';

  @override
  String get vo2ClassElite => 'elit';

  @override
  String get fjeliaProHint =>
      'FjeliaPro t\'ofereix informació i anàlisis més detallades.';

  @override
  String get rowingStrokeRate => 'Palades / min';

  @override
  String rowingStrokeAverage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ø $count palades',
      one: 'Ø 1 palada',
    );
    return '$_temp0';
  }

  @override
  String get rowingTapToSwitch => 'Toca per canviar';

  @override
  String get copyAnswer => 'Copia la resposta';

  @override
  String get answerCopied => 'Copiat ✨';

  @override
  String get coachMemories => 'Targetes de memòria';

  @override
  String get coachMemoriesIntro =>
      'Explica al teu coach el que ha de saber sempre. Les teves targetes van amb cada xat.';

  @override
  String get coachMemoryNew => 'Targeta nova';

  @override
  String get coachMemoryTitle => 'Títol';

  @override
  String get coachMemoryTitleHint => 'p. ex. Genoll esquerre';

  @override
  String get coachMemoryBody => 'Què ha de saber el teu coach?';

  @override
  String get coachMemoryBodyHint =>
      'p. ex. Córrer baixada em fa mal des de la primavera. Pujada, bé.';

  @override
  String get coachMemoryEmpty => 'Encara no hi ha targetes. Crea la primera 🔥';

  @override
  String get coachMemoryDeleteQuestion => 'Vols eliminar aquesta targeta?';

  @override
  String coachMemoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count targetes al cap del teu coach',
      one: '1 targeta al cap del teu coach',
      zero: 'Cap targeta',
    );
    return '$_temp0';
  }

  @override
  String get sportSkiErg => 'SkiErg (esquí de fons indoor)';

  @override
  String get weatherRain => 'PLUJA';

  @override
  String weatherLowHigh(int low, int high) {
    return 'Mínima $low° · Màxima $high°';
  }

  @override
  String get weatherDayPeak => 'Màxim del dia';

  @override
  String get weatherDayTotal => 'Total del dia';

  @override
  String get proTagline => 'El teu coach. A nivell pro.';

  @override
  String get proBenefitCoach =>
      'Coach d\'IA amb el model Pro: més ràpid, més complet, quota pròpia';

  @override
  String get proBenefitMemory =>
      'Targetes de memòria: el que el teu coach ha de saber sempre';

  @override
  String get proBenefitEcg => 'Anàlisi detallada de l\'ECG';

  @override
  String get proBenefitCopy => 'Copia respostes amb un toc';

  @override
  String get proMonthly => 'Mensual';

  @override
  String get proYearly => 'Anual';

  @override
  String proPerMonth(String price) {
    return '$price / mes';
  }

  @override
  String proPerYear(String price) {
    return '$price / any';
  }

  @override
  String get proBestValue => 'MILLOR PREU';

  @override
  String get proSubscribe => 'Aconsegueix FjeliaPro';

  @override
  String get proRestore => 'Restaura les compres';

  @override
  String get proManage => 'Gestiona la subscripció';

  @override
  String proActiveUntil(String date) {
    return 'Pro actiu fins al $date';
  }

  @override
  String get proAutoRenew =>
      'La subscripció es renova automàticament si no la cancel·les com a mínim 24 hores abans del final del període a la configuració del teu compte d\'Apple. El pagament es carrega al teu compte d\'Apple.';

  @override
  String get proTerms => 'Condicions d\'ús';

  @override
  String get proPrivacy => 'Privadesa';

  @override
  String get proProblemStore => 'L\'App Store no ha completat la compra.';

  @override
  String get proProblemService =>
      'La compra hi és, però encara no s\'ha pogut verificar. Fjelia ho tornarà a provar en el proper inici.';

  @override
  String get proProblemNothing =>
      'No s\'ha trobat cap subscripció FjeliaPro per restaurar.';

  @override
  String get proProblemNotActive => 'Aquesta subscripció ha finalitzat.';

  @override
  String get proUnavailable =>
      'Ara no es poden carregar les subscripcions. Torna-ho a provar més tard.';

  @override
  String get proWelcome => 'Benvingut a FjeliaPro 🔥';

  @override
  String get proUsesFjeliaAi =>
      'El model Pro respon quan a la configuració d\'IA hi ha triat «Fjelia AI».';

  @override
  String get proToolsTitle => 'Anàlisis Pro';

  @override
  String get proPlanCheck => 'Revisió del pla d\'avui';

  @override
  String get proPlanCheckHint =>
      'El pla d\'avui encaixa amb la teva recuperació?';

  @override
  String get proWeekReview => 'Resum setmanal';

  @override
  String get proWeekReviewHint =>
      'Què ha funcionat i què canviar la setmana vinent';

  @override
  String get proRacePlan => 'Pla de cursa';

  @override
  String proRacePlanHint(String race) {
    return '$race: tapering, ritme, avituallament';
  }

  @override
  String get proSeason => 'Anàlisi de temporada';

  @override
  String get proSeasonHint => 'Objectius, fases i riscos de la teva temporada';

  @override
  String get proAnalysisCreate => 'Crea l\'anàlisi';

  @override
  String get proAnalysisRedo => 'Torna a crear';

  @override
  String proAnalysisFrom(String time) {
    return 'Creat $time';
  }

  @override
  String get proAnalysisWorking => 'El model gran està analitzant…';

  @override
  String get proAnalysisFailed =>
      'L\'anàlisi no ha funcionat. Torna-ho a provar.';

  @override
  String get proBenefitPlanCheck =>
      'Proposta del matí i revisió del pla: el coach adapta l\'entrenament del dia';

  @override
  String get proBenefitReview => 'Resum setmanal i anàlisi de temporada';

  @override
  String get proBenefitRacePlan =>
      'Pla de cursa: tapering, ritme, avituallament';

  @override
  String get statsTitle => 'Estadístiques';

  @override
  String get statsLast4Weeks => 'Últimes 4 setmanes · per setmana';

  @override
  String get statsElevation => 'Desnivell';

  @override
  String get statsAllTimeTotals => 'Total';

  @override
  String get statsBestEfforts => 'Millors marques';

  @override
  String get statsLongest => 'Més llarga';

  @override
  String get statsMostElevation => 'Més desnivell';

  @override
  String get statsNone => 'Encara no hi ha activitats.';

  @override
  String get proBenefitStats =>
      'Estadístiques: millors marques, aquest any i les últimes 4 setmanes';

  @override
  String get statsFourWeeks => '4 setmanes';

  @override
  String get statsTickerWeek => 'per setmana, últimes 4 setmanes';

  @override
  String statsTickerYear(String year) {
    return 'el $year';
  }

  @override
  String statsTickerBest(String distance) {
    return 'Millor $distance';
  }

  @override
  String get statsPerWeekShort => '/ setmana';

  @override
  String get gripLeft => 'Esquerra';

  @override
  String get gripRight => 'Dreta';

  @override
  String get muscleShort => 'Múscul';

  @override
  String vsYesterday(String arrow) {
    return '$arrow vs. ahir';
  }

  @override
  String get proposalProCoach => 'El coach escriu l\'avís del matí';

  @override
  String get proposalProCoachHint =>
      'FjeliaPro: la preparació, el pla i el context de salut d\'avui s\'envien a Fjelia AI Pro, que redacta la proposta poc després de la sincronització del matí.';

  @override
  String get heatShort => 'Calor';

  @override
  String get coachRevisionLabel => 'Proposta del coach';

  @override
  String get revisionBefore => 'Abans';

  @override
  String get revisionAfter => 'Després';

  @override
  String get revisionSwapped => 'Intercanviat';

  @override
  String get revisionRestDay => 'Dia de descans';

  @override
  String get revisionDropped => 'omès';

  @override
  String get revisionAccept => 'Acceptar';

  @override
  String revisionSets(String sets, String reps) {
    return '$sets × $reps';
  }

  @override
  String get testMorningProposal => 'Prova la proposta del matí';

  @override
  String get testMorningProposalHint =>
      'Executa ara la comprovació del matí amb preparació groga; l\'avís arriba en 5 segons.';

  @override
  String get proposalRulesEasier =>
      'La recuperació encara no és completa: les sessions d\'avui són més curtes i suaus, l\'objectiu es manté.';

  @override
  String get proposalRulesRecovery =>
      'Signes clars de fatiga: avui només suau o descans.';

  @override
  String get proposalCoachUnavailable =>
      'No s\'ha pogut contactar amb el coach; aquesta és la proposta segons les regles.';

  @override
  String get revisionKeep => 'Es manté com estava previst';

  @override
  String get revisionAlternative => 'Alternativa';

  @override
  String get revisionTakeAlternative => 'Acceptar això en lloc';

  @override
  String proposalForDay(String day) {
    return 'Proposta per a $day';
  }

  @override
  String get proposalDayTomorrow => 'demà';

  @override
  String get feelingQuestion => 'Com et trobes avui?';

  @override
  String get feelingGood => 'Bé';

  @override
  String get feelingTired => 'Cansat';

  @override
  String get feelingSore => 'Adolorit';

  @override
  String get feelingIll => 'Malalt';

  @override
  String get feelingShort => 'Poc temps';

  @override
  String get feelingAsking => 'El coach hi torna a pensar…';

  @override
  String get proSwitchTitle => 'Passar a ProAI?';

  @override
  String proSwitchBody(String provider) {
    return 'La teva subscripció FjeliaPro està activa. Vols que el coach faci servir ProAI a partir d\'ara en lloc de $provider?';
  }

  @override
  String get proAiRouting =>
      'El coach i les propostes diàries fan servir ProAI; el pla de cursa i l\'anàlisi de temporada fan servir ProAI-deep automàticament.';

  @override
  String proActiveUntilShort(String date) {
    return 'Activa fins al $date';
  }

  @override
  String shortSessionNote(int done, int planned) {
    return 'Més curt del previst ($done de $planned min)';
  }

  @override
  String get noteForCoach => 'Nota per al coach (opcional)';

  @override
  String get activityNote => 'Nota';

  @override
  String get activityNoteAdd => 'Afegeix una nota per al coach';

  @override
  String get plusOmronBle => 'Cerca tensiòmetres BLE';

  @override
  String get plusOmronBleHint =>
      'Cerca dispositius estàndard de pressió arterial i perfils Omron compatibles per Bluetooth.';
}
