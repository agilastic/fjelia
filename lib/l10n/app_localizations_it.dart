// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get freeAi => 'Free AI';

  @override
  String get freeAiUsageTracking =>
      'Per mantenere Free AI affidabile e disponibile per tutti, inviamo un identificativo casuale dell\'installazione. Ci aiuta a riconoscere utilizzi insoliti e a bloccare richieste abusive. L\'identificativo non contiene il tuo nome né dati del tuo account.';

  @override
  String freeAiDescription(String host) {
    return 'IA gratuita nel cloud per chat e riepiloghi tramite $host. Non servono un account o una chiave API personali. Dopo la tua conferma, i messaggi e un riepilogo di salute e allenamento vengono inviati al servizio.';
  }

  @override
  String get freeAiUnavailable =>
      'Free AI non è disponibile in questa versione. Scegli un altro fornitore.';

  @override
  String shareBriefingContextWithName(String name) {
    return 'Un riepilogo dei tuoi dati di salute e allenamento sarà inviato a $name.';
  }

  @override
  String get language => 'Lingua';

  @override
  String get languageSystem => 'Predefinita di sistema';

  @override
  String get settings => 'Impostazioni';

  @override
  String get profile => 'Profilo';

  @override
  String get training => 'Allenamento';

  @override
  String get weatherLocation => 'Meteo e posizione';

  @override
  String get display => 'Visualizzazione';

  @override
  String get connections => 'Connessioni';

  @override
  String get aiAndMore => 'IA e altro';

  @override
  String get system => 'Sistema';

  @override
  String get runSetupAgain => 'Ripeti la configurazione';

  @override
  String get runSetupAgainSubtitle =>
      'Account, obiettivo di gara e piano di allenamento';

  @override
  String get back => 'Indietro';

  @override
  String get close => 'Chiudi';

  @override
  String get dataExport => 'Esportazione dati';

  @override
  String get dataExportSubtitle => 'Esportazione CSV, backup e ripristino';

  @override
  String get developer => 'Sviluppatore';

  @override
  String get developerSubtitle => 'Modalità debug, diagnostica';

  @override
  String get debug => 'Debug';

  @override
  String get debugMode => 'Modalità debug';

  @override
  String get debugModeSubtitle => 'Mostra la scheda DEBUG';

  @override
  String get support => 'Supporto';

  @override
  String get reportBug => 'Segnala un bug';

  @override
  String get aiCoach => 'Coach IA';

  @override
  String get enableAiCoach => 'Attiva il coach IA';

  @override
  String get onDeviceAiOrCloud => 'IA sul dispositivo o provider cloud';

  @override
  String get provider => 'Provider';

  @override
  String get model => 'Modello';

  @override
  String get chatAndAiBriefingsUse =>
      'Chat e briefing IA usano Apple Intelligence su questo dispositivo. Nessuna chiave API necessaria. Se il modello non è disponibile, i briefing mostrano un riepilogo senza IA.';

  @override
  String get briefing => 'Briefing';

  @override
  String get useAppleIntelligenceForBriefings =>
      'Usa Apple Intelligence per i briefing';

  @override
  String get useOnDeviceAiFor =>
      'Usa l\'IA sul dispositivo per i briefing mantenendo il provider scelto per la chat.';

  @override
  String get healthDataSharing => 'Condivisione dei dati sanitari';

  @override
  String get askOncePerChatSession => 'Chiedi una volta per sessione di chat';

  @override
  String get otherwiseAskBeforeEveryCloud =>
      'Altrimenti chiedi prima di ogni messaggio cloud';

  @override
  String get reportABug => 'Segnala un bug';

  @override
  String get weatherData => 'Dati meteo';

  @override
  String get openSourceLibraries => 'Librerie open source';

  @override
  String get license => 'Licenza';

  @override
  String get licenses => 'Licenze';

  @override
  String get apiKey => 'Chiave API';

  @override
  String get saveApiKey => 'Salva chiave API';

  @override
  String get feedbackBugReport => 'Feedback e segnalazione bug';

  @override
  String get reportSentThankYou => 'Segnalazione inviata. Grazie!';

  @override
  String get weReadEveryMessageIf =>
      'Leggiamo ogni messaggio. Se hai lasciato la tua e-mail, potresti ricevere una risposta.';

  @override
  String get done => 'Fatto';

  @override
  String get shareAnIdeaSuggestAn =>
      'Condividi un\'idea, suggerisci un miglioramento o raccontaci cosa è successo e cosa ti aspettavi.';

  @override
  String get whatHappenedAndWhatDid => 'Cos\'è successo e cosa ti aspettavi?';

  @override
  String get pleaseLeaveOutPasswordsApi =>
      'Non inserire password, chiavi API o dati sanitari personali.';

  @override
  String get includeDiagnostics => 'Includi diagnostica';

  @override
  String get optionalLogsMayContainAccount =>
      'Facoltativo. I log possono contenere dettagli dell\'account o sanitari. Controllali qui sotto prima di inviare.';

  @override
  String get diagnosticsPreview => 'ANTEPRIMA DIAGNOSTICA';

  @override
  String get sendingSharesYourEmailSubject =>
      'L\'invio condivide la tua e-mail, l\'oggetto, il messaggio e la diagnostica selezionata con il supporto Fjelia su www.fjelia.com.';

  @override
  String get copyReport => 'Copia segnalazione';

  @override
  String get shareReport => 'Condividi segnalazione';

  @override
  String get appleHealth => 'Apple Salute';

  @override
  String get connectedServices => 'Servizi collegati';

  @override
  String get hiloBloodPressureBle => 'Hilo pressione sanguigna (BLE)';

  @override
  String get writeHeartDataToApple => 'Scrivi i dati cardiaci in Apple Salute';

  @override
  String get writeWeightDataToApple => 'Scrivi i dati del peso in Apple Salute';

  @override
  String get renphoScaleBle => 'Bilancia Renpho (BLE)';

  @override
  String get polarH10HrvStrapBle => 'Polar H10 (fascia HRV, BLE)';

  @override
  String get dataSourcePriority => 'Priorità delle fonti dati';

  @override
  String get whenMultipleSourcesProvideThe =>
      'Quando più fonti forniscono la stessa metrica, vince quella più in alto. Trascina per riordinare.';

  @override
  String get resetToDefault => 'Ripristina predefiniti';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get healthPage => 'Pagina Salute';

  @override
  String get loadPage => 'Pagina Carico';

  @override
  String get healthMonitor => 'Monitor della salute';

  @override
  String get hrZones => 'Zone FC';

  @override
  String get t30MinTtAvailableSync =>
      'TT di 30 min disponibile: sincronizza le zone FC';

  @override
  String lt2Lt2BpmAt(Object lt2, Object at) {
    return 'LT2 $lt2 bpm · $at';
  }

  @override
  String get syncLabel => 'SINCRO';

  @override
  String get autoadjust => 'ADATTAMENTO AUTO';

  @override
  String zoneI(Object i) {
    return 'Zona $i';
  }

  @override
  String get hrZones2 => 'ZONE FC';

  @override
  String ageRound(Object round) {
    return 'età $round';
  }

  @override
  String get basics => 'Dati di base';

  @override
  String get updateWaistMonthlyUsedFor =>
      'ⓘ Aggiorna il girovita ogni mese: serve per stimare il grasso viscerale.';

  @override
  String get alcohol => 'Alcol';

  @override
  String get t1Drink033L =>
      '1 drink ≈ 0,33 l di birra / 0,2 l di vino / 4 cl di superalcolico';

  @override
  String get clinicalLabsOptional => 'Analisi di laboratorio (facoltativo)';

  @override
  String get glycemic => 'Glicemia';

  @override
  String get optimalForLongevity48 =>
      'Ottimale per la longevità: 4,8–5,4% · Prediabete: 5,7–6,4%';

  @override
  String get lipids => 'Lipidi';

  @override
  String get apobReplacesLdlWhenBoth =>
      'L\'ApoB sostituisce l\'LDL quando sono inseriti entrambi.';

  @override
  String get inflammationKidney => 'Infiammazione e reni';

  @override
  String get changesAreSavedAutomatically =>
      'Le modifiche vengono salvate automaticamente';

  @override
  String get optionalTotalClimbingForThis =>
      'Dislivello totale facoltativo per questa gara.';

  @override
  String get moreAboutThisEvent => 'Altre informazioni su questo evento';

  @override
  String distanceOfDistancekmKm(Object distanceKm) {
    return 'Distanza di $distanceKm km?';
  }

  @override
  String keepDistancekmKm(Object distanceKm) {
    return 'Mantieni $distanceKm km';
  }

  @override
  String useLikelyKm(Object likely) {
    return 'Usa $likely km';
  }

  @override
  String get thisBackupContainsNoCalendar =>
      'Questo backup non contiene attività del calendario.';

  @override
  String get activities => 'Attività';

  @override
  String get exportActivitiesCsv => 'Esporta attività in CSV';

  @override
  String get backupRestore => 'Backup e ripristino';

  @override
  String get backup => 'Backup';

  @override
  String get restoreFromBackup => 'Ripristina da backup';

  @override
  String get backupRestoredRestartTheApp =>
      'Backup ripristinato. Riavvia l\'app per ricaricare tutte le impostazioni.';

  @override
  String get raceGoals => 'Obiettivi di gara';

  @override
  String get yourActivities => 'Le tue attività';

  @override
  String get usedByAiCoachAnd =>
      'Usato dal coach IA e dal piano di allenamento. Gli sport del piano sono contrassegnati con ✦.';

  @override
  String get calendarWeekStart => 'Inizio settimana del calendario';

  @override
  String get planDefaultView => 'Vista predefinita del piano';

  @override
  String get weeklySchedule => 'Programma settimanale';

  @override
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      trainingDaysPerWeek,
      locale: localeName,
      other: '$trainingDaysPerWeek giorni di allenamento',
      one: '$trainingDaysPerWeek giorno di allenamento',
    );
    return '$_temp0 · tocca per alternare Allenamento / Riposo / Forza';
  }

  @override
  String get updatePlanToThisSchedule => 'Aggiorna il piano a questo programma';

  @override
  String get updateStrengthSessions => 'Aggiorna le sessioni di forza';

  @override
  String get sessionsPerDay => 'Sessioni al giorno';

  @override
  String get canYouFitTwoWorkouts =>
      'Riesci a fare due allenamenti nello stesso giorno?';

  @override
  String get strengthLoadUnit => 'Unità di carico forza';

  @override
  String get weightsThemselvesAreSetIn =>
      'I pesi si impostano in ogni allenamento e vengono ricordati dalla tua cronologia.';

  @override
  String get hoursAvailableWeek => 'Ore disponibili / settimana';

  @override
  String hoursperweekHWeek(Object hoursPerWeek) {
    return '$hoursPerWeek h / settimana';
  }

  @override
  String hoursperweekH(Object hoursPerWeek) {
    return '$hoursPerWeek h';
  }

  @override
  String get heatAcclimation => 'Acclimatazione al caldo';

  @override
  String get showHeatAcclimation => 'Mostra acclimatazione al caldo';

  @override
  String get weatherEvaluatedAgainstAConfigurable =>
      'Il meteo viene valutato per una posizione configurabile.';

  @override
  String get trainingPlan => 'Piano di allenamento';

  @override
  String get regenerateReplacesFutureSessionsAnd =>
      'Rigenera sostituisce le sessioni future e ricostruisce il piano da oggi con le impostazioni attuali.';

  @override
  String valueUpcomingWorkoutsGenerated(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value allenamenti futuri generati',
      one: '$value allenamento futuro generato',
    );
    return '$_temp0';
  }

  @override
  String get generationFailedCheckYourRace =>
      'Generazione non riuscita. Controlla il tuo obiettivo di gara e riprova.';

  @override
  String get deleteAllWorkouts => 'Elimina tutti gli allenamenti';

  @override
  String get changesAreSavedAutomatically2 =>
      '✓ Le modifiche vengono salvate automaticamente';

  @override
  String countUpcomingWorkoutsGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allenamenti futuri generati',
      one: '$count allenamento futuro generato',
    );
    return '$_temp0';
  }

  @override
  String get importRaceGoalsFromGarmin => 'Importa obiettivi di gara da Garmin';

  @override
  String get addRaceGoal => 'Aggiungi obiettivo di gara';

  @override
  String priorityTouppercase(Object toUpperCase) {
    return 'Priorità $toUpperCase';
  }

  @override
  String get goalsAreSharedWithAi =>
      'Gli obiettivi sono condivisi con il coach IA. La priorità A, B o C decide come il piano pesa le gare tra loro.';

  @override
  String get deletingWorkouts => 'Eliminazione degli allenamenti';

  @override
  String get cityOrTown => 'Città o paese';

  @override
  String get eGHannoverOrPalma => 'ad es. Hannover o Palma';

  @override
  String get noCitiesFoundTryA =>
      'Nessuna città trovata. Prova con un paese vicino.';

  @override
  String get chooseTheLocationForThe =>
      'Scegli la posizione per le previsioni del piano, il radar e l\'acclimatazione al caldo. Il meteo funziona anche con l\'acclimatazione disattivata.';

  @override
  String get none => 'Nessuna';

  @override
  String get disableLocalWeatherAndLocation =>
      'Disattiva meteo locale e richieste di posizione';

  @override
  String get currentLocation => 'Posizione attuale';

  @override
  String get followYourDeviceLocation => 'Segui la posizione del dispositivo';

  @override
  String get fixedLocation => 'Posizione fissa';

  @override
  String get chooseACityOrEnter => 'Scegli una città o inserisci le coordinate';

  @override
  String get chooseCity => 'Scegli città';

  @override
  String get coordinates => 'Coordinate';

  @override
  String get latitude => 'Latitudine';

  @override
  String get longitude => 'Longitudine';

  @override
  String get saveLocation => 'Salva posizione';

  @override
  String get refreshCurrentLocation => 'Aggiorna posizione attuale';

  @override
  String get citySearchOpenMeteoGeonames =>
      'Ricerca città: Open-Meteo / GeoNames';

  @override
  String get cityNamesOpenstreetmap => 'Nomi delle città: © OpenStreetMap';

  @override
  String get energy => 'ENERGIA';

  @override
  String get currentEnergy => 'ENERGIA ATTUALE';

  @override
  String get dailyTimeline => 'ANDAMENTO GIORNALIERO';

  @override
  String valueValue2(Object value, Object value2) {
    return '$value → $value2';
  }

  @override
  String get energy2 => 'Energia';

  @override
  String get noData => 'Nessun dato';

  @override
  String get bloodPressureInsights => 'ANALISI PRESSIONE';

  @override
  String get sys => ' Sis';

  @override
  String get diaMmhg => ' Dia · mmHg';

  @override
  String get previousBloodPressurePeriod => 'Periodo pressione precedente';

  @override
  String get nextBloodPressurePeriod => 'Periodo pressione successivo';

  @override
  String get nightDipping => 'Calo notturno';

  @override
  String get noMeasurementsInThisPeriod =>
      'Nessuna misurazione in questo periodo';

  @override
  String get fullscreenBloodPressureChart =>
      'Grafico pressione a schermo intero';

  @override
  String get barsMinMaxLineDots =>
      'Barre: min–max · linea/punti: media · tocca o trascina per esaminare';

  @override
  String get noMeasurements => 'Nessuna misurazione';

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
      other: '$length misurazioni',
      one: '$length misurazione',
    );
    return '$_temp0 · media / min–max';
  }

  @override
  String bloodPressureTouppercaseMmhg(Object toUpperCase) {
    return 'PRESSIONE · $toUpperCase · mmHg';
  }

  @override
  String get closeFullscreenBloodPressureChart =>
      'Chiudi il grafico pressione a schermo intero';

  @override
  String get chooseScale => 'Scegli bilancia';

  @override
  String get noScalesFoundStepOn =>
      'Nessuna bilancia trovata. Sali sulla bilancia e riprova.';

  @override
  String nameRssiDbm(Object name, Object rssi) {
    return '$name · $rssi dBm';
  }

  @override
  String get renphoSaved => 'RENPHO salvata:';

  @override
  String get renphoScaleBle2 => 'Bilancia RENPHO (BLE)';

  @override
  String get changeMeasurementType => 'Cambia tipo di misurazione';

  @override
  String get addMeasurement => 'Aggiungi misurazione';

  @override
  String get whatAreYouMeasuring => 'Cosa stai misurando?';

  @override
  String get chooseAnotherMeasurement => 'Scegli un\'altra misurazione';

  @override
  String get saveMeasurement => 'Salva misurazione';

  @override
  String get skip => 'Salta';

  @override
  String get connectHiloService => 'Collega il servizio Hilo';

  @override
  String get connectHilo => 'Collega Hilo';

  @override
  String get connectCoros => 'Collega Coros';

  @override
  String get europe => 'Europa';

  @override
  String get unitedStates => 'Stati Uniti';

  @override
  String get asia => 'Asia';

  @override
  String get bluetoothBloodPressure => 'Bluetooth · pressione sanguigna';

  @override
  String get cloudCuffData => 'Cloud · dati del bracciale';

  @override
  String get apiSync => 'Sincronizzazione API';

  @override
  String get bluetoothHrvStrap => 'Bluetooth · fascia HRV';

  @override
  String get accesslinkApi => 'AccessLink API';

  @override
  String get systemHealthData => 'Dati sanitari di sistema';

  @override
  String get cloudScaleHistory => 'Cloud · storico della bilancia';

  @override
  String get bluetoothWeightBody => 'Bluetooth · peso e corpo';

  @override
  String get connectYourDevices => 'Collega i tuoi dispositivi';

  @override
  String get continueLabel => 'Continua';

  @override
  String get connectGarmin => 'Collega Garmin';

  @override
  String get connectAppleHealth => 'Collega Apple Salute';

  @override
  String get dataSynced => 'DATI SINCRONIZZATI';

  @override
  String get pairHiloPod => 'Associa Hilo Pod';

  @override
  String get chooseStrap => 'Scegli la fascia';

  @override
  String namePaired(Object name) {
    return '$name associato.';
  }

  @override
  String get pairPolarH10 => 'Associa Polar H10';

  @override
  String get forget => 'Dimentica';

  @override
  String get sendWorkoutToPolar => 'Invia l\'allenamento a Polar';

  @override
  String get connectPolar => 'Collega Polar';

  @override
  String get signInWithPolarFlow => 'Accedi con Polar Flow';

  @override
  String get syncsSleepStagesHrvResting =>
      'Sincronizza fasi del sonno · HRV · FC a riposo · allenamenti · passi';

  @override
  String savedForV(Object v) {
    return 'Salvato per $v';
  }

  @override
  String get remove => 'Rimuovi';

  @override
  String get polarEMail => 'E-mail Polar';

  @override
  String get polarPassword => 'Password Polar';

  @override
  String get pairRenphoScale => 'Associa la bilancia RENPHO';

  @override
  String get connectRenpho => 'Collega Renpho';

  @override
  String get connectSuunto => 'Collega Suunto';

  @override
  String smsSentToTrim(Object trim) {
    return 'SMS inviato a $trim';
  }

  @override
  String get resendSms => 'Invia di nuovo l\'SMS';

  @override
  String get retryLoadingPreferences => 'Riprova a caricare le preferenze';

  @override
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed) {
    return 'TEMPO DI ALLENAMENTO SETTIMANALE · $toStringAsFixed h';
  }

  @override
  String get tapADayToCycle =>
      'Tocca un giorno per alternare Allenamento / Riposo / Forza.';

  @override
  String get doubleDayOk => 'Doppio allenamento ok';

  @override
  String get birthYearOptional => 'Anno di nascita (facoltativo)';

  @override
  String get addAnother => 'Aggiungi un altro';

  @override
  String get knowYourBodyTrainSmarter =>
      'Conosci il tuo corpo.\nAllenati meglio.';

  @override
  String get allYourHealthDevicesOne =>
      'Tutti i tuoi dispositivi per la salute. Un\'unica vista intelligente.';

  @override
  String get areYouReadyToTrain => 'Sei pronto ad allenarti oggi?';

  @override
  String get hrvRecoveryScoreRestingHr =>
      'HRV · Punteggio di recupero · FC a riposo';

  @override
  String get didYouActuallyRecoverLast => 'Hai davvero recuperato stanotte?';

  @override
  String get sleepStagesDeepSleepSpo =>
      'Fasi del sonno · Sonno profondo · SpO₂';

  @override
  String get isYourBloodPressureUnder => 'La tua pressione è sotto controllo?';

  @override
  String get continuousBpNightDippingTrends =>
      'Pressione continua · Calo notturno · Tendenze';

  @override
  String get howHardDidYouPush => 'Quanto ti sei spinto questa settimana?';

  @override
  String get trainingLoadTrimpStrainScore =>
      'Carico di allenamento · TRIMP · Punteggio di sforzo';

  @override
  String get isYourBodyCompositionImproving =>
      'La tua composizione corporea sta migliorando?';

  @override
  String get weightBodyFatMuscleMass =>
      'Peso · Grasso corporeo · Massa muscolare';

  @override
  String get getStarted => 'Inizia';

  @override
  String get yourDataStaysOnYour => 'I tuoi dati. Scegli tu cosa condividere.';

  @override
  String get bodyScale => 'Bilancia pesapersone';

  @override
  String get bodyComposition => 'Composizione corporea';

  @override
  String get sleep => 'SONNO';

  @override
  String get sleepPerformance => 'QUALITÀ DEL SONNO';

  @override
  String get sleepHistory => 'Cronologia del sonno';

  @override
  String labelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String lessLabel(Object label) {
    return 'Meno $label';
  }

  @override
  String moreLabel(Object label) {
    return 'Più $label';
  }

  @override
  String get gymMode => 'Modalità palestra';

  @override
  String get finishWorkout => 'Termina allenamento';

  @override
  String get workoutActions => 'Azioni allenamento';

  @override
  String get discardWorkout => 'Scarta allenamento';

  @override
  String get allSetsRecorded => 'Tutte le serie registrate';

  @override
  String get reviewSets => 'Rivedi le serie';

  @override
  String get rest => 'RECUPERO';

  @override
  String plannedResttarget(Object restTarget) {
    return 'Previsto $restTarget';
  }

  @override
  String get startSet => 'Inizia serie';

  @override
  String get seconds => 'Secondi';

  @override
  String get previousSet => 'Serie precedente';

  @override
  String get allSets => 'Tutte le serie';

  @override
  String get nextSet => 'Serie successiva';

  @override
  String get everySetIsSavedAs =>
      'Ogni serie viene salvata man mano. Puoi chiudere questa schermata in qualsiasi momento e riprendere dall\'allenamento pianificato.';

  @override
  String get cancel => 'Annulla';

  @override
  String get apply => 'Applica';

  @override
  String get effortScale => 'Scala dello sforzo';

  @override
  String get setType => 'Tipo di serie';

  @override
  String get reps => 'Ripetizioni';

  @override
  String get range => 'Intervallo';

  @override
  String get time => 'Tempo';

  @override
  String get t45Or100 => '45 o 1:00';

  @override
  String get blankWhenNotSet => 'Vuoto se non impostato';

  @override
  String get redBand => 'Fascia rossa';

  @override
  String get t90Or130 => '90 o 1:30';

  @override
  String get blankWhenUnknown => 'Vuoto se sconosciuto';

  @override
  String get usePlannedLoad => 'Usa il carico pianificato';

  @override
  String get blankWhenNotMeasured => 'Vuoto se non misurato';

  @override
  String get exercise => 'Esercizio';

  @override
  String get changingTheLoadConventionStarts =>
      'Cambiare la convenzione di carico avvia uno storico separato per questo esercizio.';

  @override
  String get barbellMachine => 'Bilanciere, macchina…';

  @override
  String get load => 'Carico';

  @override
  String get loadRefersTo => 'Il carico si riferisce a';

  @override
  String get t2ForAPair => '2 per una coppia';

  @override
  String get repetitions => 'Ripetizioni';

  @override
  String get availablePlatesOrDumbbells => 'Dischi o manubri disponibili';

  @override
  String get rememberForThisEquipment => 'Ricorda per questa attrezzatura';

  @override
  String get findOrNameAnExercise => 'Cerca o assegna un nome a un esercizio';

  @override
  String createTrim(Object trim) {
    return 'Crea “$trim”';
  }

  @override
  String get customExercise => 'Esercizio personalizzato';

  @override
  String get smallestLoadStep => 'Incremento di carico minimo';

  @override
  String whatRemoved(Object what) {
    return '$what rimosso';
  }

  @override
  String get undo => 'Annulla';

  @override
  String get retry => 'Riprova';

  @override
  String get performance => 'Prestazione';

  @override
  String get addExercise => 'Aggiungi esercizio';

  @override
  String get finishLog => 'Termina registro';

  @override
  String get keepAsDraft => 'Mantieni come bozza';

  @override
  String actionsForName(Object name) {
    return 'Azioni per $name';
  }

  @override
  String get editExercise => 'Modifica esercizio';

  @override
  String get moveUp => 'Sposta su';

  @override
  String get moveDown => 'Sposta giù';

  @override
  String get addSet => 'Aggiungi serie';

  @override
  String get removeLastSet => 'Rimuovi l\'ultima serie';

  @override
  String get saveAsTemplate => 'Salva come modello';

  @override
  String savedTitleAsATemplate(Object title) {
    return '“$title” salvato come modello. Questo allenamento resta invariato finché non lo salvi.';
  }

  @override
  String nameSetN(Object name, Object n) {
    return '$name · Serie $n';
  }

  @override
  String nameAllWorkingSets(Object name) {
    return '$name · Tutte le serie di lavoro';
  }

  @override
  String labelRest(Object label) {
    return 'Recupero $label';
  }

  @override
  String get secondsOrMSs => 'Secondi o m:ss';

  @override
  String get applyToAllSets => 'Applica a tutte le serie';

  @override
  String get duplicate => 'Duplica';

  @override
  String get supersetWithNext => 'Superset con la successiva';

  @override
  String get circuitWithNext => 'Circuito con la successiva';

  @override
  String actionsForSetN(Object n) {
    return 'Azioni per la serie $n';
  }

  @override
  String get editSet => 'Modifica serie';

  @override
  String get duplicateSet => 'Duplica serie';

  @override
  String get removeSet => 'Rimuovi serie';

  @override
  String labelActions(Object label) {
    return 'Azioni $label';
  }

  @override
  String get editRests => 'Modifica i recuperi';

  @override
  String get ungroup => 'Separa';

  @override
  String get editExercises => 'Modifica esercizi';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String couldNotSaveError(Object error) {
    return 'Impossibile salvare: $error';
  }

  @override
  String get history => 'Cronologia';

  @override
  String get exercises => 'Esercizi';

  @override
  String get noExercisesArePlannedFor =>
      'Non ci sono ancora esercizi pianificati per questo allenamento. Le note sopra lo descrivono.';

  @override
  String get addExercises => 'Aggiungi esercizi';

  @override
  String get fromTheBuiltInTemplate =>
      'Dal modello integrato. I carichi li imposti tu; lo storico compare dopo aver registrato un allenamento.';

  @override
  String get shareExerciseList => 'Condividi elenco esercizi';

  @override
  String get noSavedStrengthTemplatesYet =>
      'Nessun modello di forza salvato. Salvane prima uno da un allenamento pianificato.';

  @override
  String get compareWith => 'Confronta con';

  @override
  String estimated1rmUnit(Object unit) {
    return '1RM stimato $unit';
  }

  @override
  String get plannedNotRecorded => 'Pianificato, non registrato';

  @override
  String get notes => 'Note';

  @override
  String get editPerformance => 'Modifica prestazione';

  @override
  String get compareWithASavedWorkout => 'Confronta con un allenamento salvato';

  @override
  String get sessions => 'Sessioni';

  @override
  String get radarUnavailableRetry => 'Radar non disponibile · Riprova';

  @override
  String get radar => 'Radar';

  @override
  String get weatherDataByRainviewer => 'Dati meteo di RainViewer';

  @override
  String get openstreetmapContributors => '© collaboratori di OpenStreetMap';

  @override
  String get weather => 'Meteo';

  @override
  String get weatherUnavailableRetry => 'Meteo non disponibile · Riprova';

  @override
  String get chooseAFixedLocationIn =>
      'Scegli una posizione fissa in Impostazioni > Meteo e posizione, oppure consenti l\'accesso alla posizione per il meteo locale.';

  @override
  String get locationSettings => 'Impostazioni posizione';

  @override
  String get retryLocation => 'Riprova posizione';

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
    return 'Bulbo umido $toStringAsFixed°C';
  }

  @override
  String get previousForecastDay => 'Giorno di previsione precedente';

  @override
  String get nextForecastDay => 'Giorno di previsione successivo';

  @override
  String daysDayForecast(Object days) {
    return 'Previsioni a $days giorni';
  }

  @override
  String thisProviderCurrentlySuppliesDays(Object days, Object days2) {
    return 'Questo provider fornisce attualmente $days giorni di previsione su $days2.';
  }

  @override
  String get now => 'Ora';

  @override
  String get sunriseSunset => 'Alba / tramonto';

  @override
  String keyKey2(Object key, Object key2) {
    return '☀ $key   ☾ $key2';
  }

  @override
  String get use => 'Usa';

  @override
  String get exerciseDetailsWereNotProvided =>
      'I dettagli degli esercizi non sono stati forniti da questa fonte di attività.';

  @override
  String get logFromPlan => 'Registra dal piano';

  @override
  String get addExerciseDetails => 'Aggiungi dettagli esercizi';

  @override
  String get loadSuggestion => 'Suggerimento di carico';

  @override
  String get applyToThisWorkout => 'Applica a questo allenamento';

  @override
  String get keepCurrentLoad => 'Mantieni il carico attuale';

  @override
  String get setLoadStep => 'Imposta incremento di carico';

  @override
  String get viewSupportingSets => 'Vedi le serie di supporto';

  @override
  String get supportingSets => 'Serie di supporto';

  @override
  String get noRecordedSessionsYet => 'Nessuna sessione registrata.';

  @override
  String nameDemonstrationCue(Object name, Object cue) {
    return 'Dimostrazione di $name. $cue';
  }

  @override
  String get noScalesFoundStepOn2 =>
      'Nessuna bilancia trovata. Sali sulla bilancia e riprova.';

  @override
  String get scalePaired => 'Bilancia associata';

  @override
  String get ok => 'OK';

  @override
  String get pairedReadyToMeasure => '✓ Associato – pronto per la misurazione';

  @override
  String get chooseHiloCuff => 'Scegli il bracciale Hilo';

  @override
  String get noCuffFoundWakeYour =>
      'Nessun bracciale trovato. Riattiva il bracciale e riprova la ricerca.';

  @override
  String get hiloCuffAktiiaC => 'Bracciale Hilo (AKTIIA C…)';

  @override
  String get onDemandBloodPressureVia => 'Pressione a richiesta via BLE';

  @override
  String get selectHiloPodWristband => 'Seleziona Hilo Pod (braccialetto)';

  @override
  String get rescan => 'Cerca di nuovo';

  @override
  String get noDevicesFoundTapTo =>
      'Nessun dispositivo trovato. Tocca ↻ per cercare di nuovo.';

  @override
  String get polarH10SpotHrv => 'Polar H10 · HRV puntuale';

  @override
  String get aSeparateHrvReadingBefore =>
      'Una misurazione HRV separata prima o dopo l\'allenamento. Queste misurazioni non sostituiscono l\'HRV notturna di Garmin né modificano il tuo punteggio di prontezza.';

  @override
  String get wearTheStrapWithMoist =>
      'Indossa la fascia con gli elettrodi inumiditi. Resta fermo e respira normalmente. Usa la stessa postura e la stessa durata per i confronti. Dopo l\'allenamento, annota quanto hai riposato prima.';

  @override
  String get measurement => 'Misurazione';

  @override
  String get posture => 'Postura';

  @override
  String get recordingLengthPlus1Min =>
      'Durata della registrazione · più 1 min di assestamento';

  @override
  String get t2Minutes => '2 minuti';

  @override
  String get t5Minutes => '5 minuti';

  @override
  String get minutesSinceTrainingEndedOptional =>
      'Minuti dalla fine dell\'allenamento (facoltativo)';

  @override
  String get sessionOrNotesOptional => 'Sessione o note (facoltativo)';

  @override
  String connectName(Object name) {
    return 'Collega $name';
  }

  @override
  String get findPolarH10 => 'Cerca Polar H10';

  @override
  String signalRssiDbm(Object rssi) {
    return 'Segnale $rssi dBm';
  }

  @override
  String connectedName(Object name) {
    return 'Collegato: $name';
  }

  @override
  String get waitingForHeartRateAnd =>
      'In attesa di frequenza cardiaca e intervalli RR. Controlla il contatto della fascia.';

  @override
  String get startMeasurement => 'Avvia misurazione';

  @override
  String get cancelMeasurement => 'Annulla misurazione';

  @override
  String get spotHrvRmssd => 'HRV puntuale · RMSSD';

  @override
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  ) {
    return '$accepted/$length intervalli utilizzabili · $toStringAsFixed% di copertura';
  }

  @override
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs) {
    return 'lnRMSSD: $lnRmssd · RMSSD grezzo: $rawRmssdMs ms';
  }

  @override
  String get signalQualityIsTooLow =>
      'La qualità del segnale è troppo bassa per salvare. Ripeti la misurazione con un buon contatto della fascia. Servono almeno il 95% di intervalli utilizzabili e il 90% di copertura.';

  @override
  String get savedToSpotHrvHistory => 'Salvato nella cronologia HRV puntuale.';

  @override
  String get newMeasurement => 'Nuova misurazione';

  @override
  String get signalScreeningExcludesPoorContact =>
      'Il filtro del segnale esclude contatto scarso, RR fuori da 250–2500 ms e intervalli oltre il 25% dalla mediana locale. Le lacune non vengono colmate. Non è un test medico né un punteggio di prontezza autonomo.';

  @override
  String historyLabelLabel2DurationMin(
    Object label,
    Object label2,
    Object duration,
  ) {
    return 'Cronologia · $label · $label2 · $duration min';
  }

  @override
  String get onlyReadingsWithTheSame =>
      'Vengono mostrate insieme solo le misurazioni con lo stesso contesto, postura e durata.';

  @override
  String get noMatchingMeasurementsYet => 'Nessuna misurazione corrispondente.';

  @override
  String tostringasfixedMsRmssdTostringasfixed2Bpm(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return '$toStringAsFixed ms RMSSD · $toStringAsFixed2 bpm';
  }

  @override
  String get exportRrIntervalsCsv => 'Esporta intervalli RR (CSV)';

  @override
  String get deleteMeasurement => 'Elimina misurazione';

  @override
  String get remindMeToMeasureHrv =>
      'Ricordami di misurare l\'HRV dopo l\'allenamento';

  @override
  String get appleHealthIsNoLonger => 'Apple Salute non è più disponibile';

  @override
  String get later => 'Più tardi';

  @override
  String get reconnect => 'Ricollega';

  @override
  String get gripStrength => 'Forza di presa';

  @override
  String get leftKg => 'Sinistra (kg)';

  @override
  String get rightKg => 'Destra (kg)';

  @override
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg) {
    return 'S $leftKg · D $rightKg kg';
  }

  @override
  String get notificationsAreOffYouCan =>
      'Le notifiche sono disattivate. Puoi comunque misurare dal tuo allenamento.';

  @override
  String get noRemindersFrom2200 => 'Nessun promemoria dalle 22:00 alle 07:00';

  @override
  String get aReminderThatWouldFall =>
      'Un promemoria che cadrebbe in questa fascia viene saltato, non spostato al mattino.';

  @override
  String get remindersArriveQuietlyInThe =>
      'I promemoria arrivano in modo silenzioso nell\'elenco delle notifiche.';

  @override
  String get noForecastForThisDay => 'Nessuna previsione per questo giorno';

  @override
  String get fullscreen => 'Schermo intero';

  @override
  String source(Object source) {
    return '● $source';
  }

  @override
  String get temperatureC => '● Temperatura °C';

  @override
  String get rainMm => '▥ Pioggia mm';

  @override
  String get uvIndex => '— Indice UV';

  @override
  String get closeFullscreenWeatherChart =>
      'Chiudi il grafico meteo a schermo intero';

  @override
  String get sleepStages => 'FASI DEL SONNO';

  @override
  String get noStageTimelineForThis =>
      'Nessuna cronologia delle fasi per questa notte.';

  @override
  String round3(Object round) {
    return '$round%';
  }

  @override
  String get examplesOnlyCheckAndEnter =>
      'Solo esempi: controlla e inserisci i valori dell\'etichetta del prodotto per porzione. Lascia vuoti i nutrienti sconosciuti; inserisci 0 solo se il valore è noto.';

  @override
  String get nutritionStrategy => 'Strategia nutrizionale';

  @override
  String get noPreWorkoutNutritionStrategy =>
      'Non è stata salvata alcuna strategia nutrizionale pre-allenamento.';

  @override
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium) {
    return '$carbs g di carboidrati/h · $fluid ml/h · $sodium mg di sodio/h';
  }

  @override
  String get forecastUpdatedReviewOrRecalculate =>
      'Previsioni aggiornate: rivedi o ricalcola la strategia salvata.';

  @override
  String strategySavedSavedat(Object savedAt) {
    return 'Strategia salvata $savedAt';
  }

  @override
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  ) {
    return 'Totale durante: $totalCarbs g di carboidrati · $totalFluid ml · $totalSodium mg di sodio';
  }

  @override
  String every20MinAboutCarbs(Object carbs, Object fluid) {
    return 'Ogni 20 min: circa $carbs g di carboidrati e $fluid ml.';
  }

  @override
  String get packQuantitiesIncludeFullContainers =>
      'Le quantità da portare includono confezioni intere; non è necessario consumare tutto.';

  @override
  String get workoutChangedReviewOrRecalculate =>
      'Allenamento modificato: rivedi o ricalcola la strategia salvata.';

  @override
  String get conditionsAndFeedingPlan => 'Condizioni e piano di alimentazione';

  @override
  String get editStrategy => 'Modifica strategia';

  @override
  String get recalculate => 'Ricalcola';

  @override
  String get actualNutrition => 'Alimentazione effettiva';

  @override
  String get someProductValuesAreUnknown =>
      'Alcuni valori dei prodotti sono sconosciuti; i totali sono incompleti.';

  @override
  String get logFoodAndFluids => 'Registra cibo e liquidi';

  @override
  String get recordWhatYouActuallyHad =>
      'Registra ciò che hai effettivamente assunto. L\'apporto pianificato non viene copiato in questo registro.';

  @override
  String get elapsedMinutesIncludingStopsOptional =>
      'Minuti trascorsi, soste incluse (facoltativo)';

  @override
  String recordedDurationActivityMin(Object activity) {
    return 'Durata registrata: $activity min';
  }

  @override
  String get compareWithSavedStrategy => 'Confronta con la strategia salvata';

  @override
  String get useMatchedSessionIfAvailable =>
      'Usa la sessione corrispondente se disponibile';

  @override
  String get noPlanComparison => 'Nessun confronto con il piano';

  @override
  String titleDate(Object title, Object date) {
    return '$title · $date';
  }

  @override
  String get linkedStrategyUnavailable => 'Strategia collegata non disponibile';

  @override
  String quantityName(Object quantity, Object name) {
    return '$quantity × $name';
  }

  @override
  String get removeIntake => 'Rimuovi assunzione';

  @override
  String get addFoodOrDrink => 'Aggiungi cibo o bevanda';

  @override
  String get iHadNoIntake => 'Non ho assunto nulla';

  @override
  String get giGutComfort => 'Comfort gastrointestinale';

  @override
  String get whatWorkedSymptomsAccessProblems =>
      'Cosa ha funzionato / sintomi / problemi di accesso';

  @override
  String get saveDraft => 'Salva bozza';

  @override
  String get skipLoggingThisActivity =>
      'Salta la registrazione di questa attività';

  @override
  String get nutritionAndFluids => 'Alimentazione e liquidi';

  @override
  String get productsToleranceAndMeasuredSweat =>
      'Prodotti, tolleranza e perdite di sudore misurate';

  @override
  String get postWorkoutIntakeReminder =>
      'Promemoria di assunzione post-allenamento';

  @override
  String get onceAfterARecentEndurance =>
      'Una volta dopo un recente allenamento di resistenza; ore di silenzio 22:00–08:00.';

  @override
  String get addHiloBpReport => 'Aggiungi report pressione Hilo';

  @override
  String get readingPdfReportsIsOnly =>
      'La lettura dei report PDF è disponibile solo su iOS e macOS.';

  @override
  String get chooseAnotherReport => 'Scegli un altro report';

  @override
  String get biologicalAge => 'Età biologica';

  @override
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class) {
    return 'VO₂max $vo2max ml/kg/min · $vo2Class';
  }

  @override
  String get factorContributions => 'Contributo dei fattori';

  @override
  String estimatedRangeRoundRound2Years(Object round, Object round2) {
    return 'Intervallo stimato: $round–$round2 anni. Una stima del modello, non una diagnosi medica.';
  }

  @override
  String get noEnergyMeasurementsForThis =>
      'Nessuna misurazione di energia per questo giorno';

  @override
  String get scanningStepOnTheScale =>
      'Ricerca in corso… sali sulla bilancia quando sei pronto.';

  @override
  String waistWaistCmUpdateMonthly(Object waist) {
    return 'Girovita: $waist cm – aggiorna ogni mese in Profilo';
  }

  @override
  String get measuring => 'Misurazione…';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get systolic => 'Sistolica';

  @override
  String get diastolic => 'Diastolica';

  @override
  String get heartRate => 'Frequenza cardiaca';

  @override
  String get weight => 'Peso';

  @override
  String get bodyFat => 'Grasso corporeo';

  @override
  String get duration => 'Durata';

  @override
  String get deep => 'Profondo';

  @override
  String get spo => 'SpO₂';

  @override
  String get activityName => 'Nome attività';

  @override
  String get sport => 'Sport';

  @override
  String get distance => 'Distanza';

  @override
  String get saved => 'Salvato';

  @override
  String get connectionFailedCheckYourInternet =>
      'Connessione non riuscita. Controlla la connessione a internet.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Password';

  @override
  String get passwordTooShort => 'Password troppo corta';

  @override
  String get loginFailedCheckYourEmail =>
      'Accesso non riuscito. Controlla e-mail e password.';

  @override
  String get connectionFailedCheckYourCredentials =>
      'Connessione non riuscita. Controlla le credenziali e la connessione a internet.';

  @override
  String get region => 'Regione';

  @override
  String get hiloPod => 'Hilo Pod';

  @override
  String get hiloAccount => 'Account Hilo';

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
  String get renphoAccount => 'Account Renpho';

  @override
  String get garminConnectEmail => 'E-mail di Garmin Connect';

  @override
  String get verifyMfaCode => 'Verifica il codice MFA';

  @override
  String get verificationCode => 'Codice di verifica';

  @override
  String errorE(Object e) {
    return 'Errore: $e';
  }

  @override
  String get noHiloPodFoundMake =>
      'Nessun Hilo Pod trovato. Assicurati che sia carico e vicino.';

  @override
  String scanFailedE(Object e) {
    return 'Ricerca non riuscita: $e';
  }

  @override
  String get hiloPod2 => 'Hilo Pod';

  @override
  String get scanForPod => 'Cerca il pod';

  @override
  String get scanForPolarH10 => 'Cerca Polar H10';

  @override
  String get couldNotReachPolarCheck =>
      'Impossibile raggiungere Polar. Controlla la connessione.';

  @override
  String get signInAndSendWorkout => 'Accedi e invia l\'allenamento';

  @override
  String get scanForScale => 'Cerca la bilancia';

  @override
  String get passwordRequired => 'Password obbligatoria';

  @override
  String get enterYourPhoneNumberWith =>
      'Inserisci il numero di telefono (con prefisso internazionale, ad es. +39…) e l\'e-mail Suunto.';

  @override
  String get enterThePinFromThe => 'Inserisci il PIN ricevuto via SMS.';

  @override
  String get incorrectPinPleaseTryAgain => 'PIN errato. Riprova.';

  @override
  String get phoneNumber => 'Numero di telefono';

  @override
  String get suuntoAccountEmail => 'E-mail dell\'account Suunto';

  @override
  String get enterPinFromSms => 'Inserisci il PIN dell\'SMS';

  @override
  String get verifyConnect => 'Verifica e collega';

  @override
  String get sendSmsCode => 'Invia codice SMS';

  @override
  String couldNotSavePreferencesE(Object e) {
    return 'Impossibile salvare le preferenze: $e';
  }

  @override
  String get mon => 'Lun';

  @override
  String get tue => 'Mar';

  @override
  String get wed => 'Mer';

  @override
  String get thu => 'Gio';

  @override
  String get fri => 'Ven';

  @override
  String get sat => 'Sab';

  @override
  String get sun => 'Dom';

  @override
  String get male => 'Maschio';

  @override
  String get female => 'Femmina';

  @override
  String get other => 'Altro';

  @override
  String get running => 'Corsa';

  @override
  String get trailRunning => 'Trail running';

  @override
  String get cycling => 'Ciclismo';

  @override
  String get swimming => 'Nuoto';

  @override
  String get triathlon => 'Triathlon';

  @override
  String get hiking => 'Escursionismo';

  @override
  String get rowing => 'Canottaggio';

  @override
  String get buildMyPlan => 'Crea il mio piano';

  @override
  String get keepAConsistentBedtimeAnd =>
      'Mantieni orari regolari per andare a letto e svegliarti per sostenere la tua routine del sonno.';

  @override
  String get thisWorkoutHasNoSets => 'Questo allenamento non ha serie.';

  @override
  String loadName(Object name) {
    return 'Carico ($name)';
  }

  @override
  String get setLabel => 'Serie';

  @override
  String get lowestReps => 'Ripetizioni minime';

  @override
  String get highestReps => 'Ripetizioni massime';

  @override
  String get repsPerSide => 'Ripetizioni per lato';

  @override
  String get fromReps => 'Da (rip.)';

  @override
  String get toReps => 'A (rip.)';

  @override
  String get addedLoad => 'Carico aggiunto';

  @override
  String get assistance => 'Assistenza';

  @override
  String get tempoOptional => 'Tempo (facoltativo)';

  @override
  String get notesOptional => 'Note (facoltativo)';

  @override
  String get enterTheRepetitionsDone => 'Inserisci le ripetizioni eseguite.';

  @override
  String plannedUnit(Object unit) {
    return 'Previsto $unit';
  }

  @override
  String get repsDone => 'Ripetizioni eseguite';

  @override
  String get resistance => 'Resistenza';

  @override
  String get implementsLabel => 'Attrezzi';

  @override
  String get name => 'Nome';

  @override
  String get instructionsOptional => 'Istruzioni (facoltativo)';

  @override
  String get remember => 'Ricorda';

  @override
  String get notSavedYet => 'Non ancora salvato';

  @override
  String get saving => 'Salvataggio…';

  @override
  String get couldNotSave => 'Impossibile salvare';

  @override
  String get plannedValuesAreHintsNot =>
      'I valori pianificati sono indicazioni, non risultati. Tocca una serie per registrarla.';

  @override
  String get completedAsPlanned => 'Completato come pianificato';

  @override
  String get save => 'Salva';

  @override
  String get nameTheTemplate => 'Dai un nome al modello.';

  @override
  String setN(Object n) {
    return 'Serie $n';
  }

  @override
  String get changesApplyToThisWorkout =>
      'Le modifiche valgono solo per questo allenamento. Gli allenamenti completati e le altre sessioni restano invariati.';

  @override
  String get saveForThisWorkout => 'Salva per questo allenamento';

  @override
  String knownForKnownOfOf(Object known, Object of) {
    return 'Noto per $known serie con carico su $of';
  }

  @override
  String get sessionEstimate => 'Stima della sessione';

  @override
  String get calculatedRange => 'Intervallo calcolato';

  @override
  String get timedWork => 'Lavoro a tempo';

  @override
  String get strengthTraining => 'Allenamento di forza';

  @override
  String get theExercisesCouldNotBe => 'Impossibile caricare gli esercizi.';

  @override
  String get resumeWorkout => 'Riprendi allenamento';

  @override
  String get strengthWorkout => 'Allenamento di forza';

  @override
  String get untitledTemplate => 'Modello senza titolo';

  @override
  String get theRecordedExercisesCouldNot =>
      'Impossibile caricare gli esercizi registrati.';

  @override
  String get exercisesPerformed => 'Esercizi eseguiti';

  @override
  String get comparedWithThePlanAs =>
      'Confrontato con il piano com\'era all\'inizio della registrazione.';

  @override
  String topWorkingLoadName(Object name) {
    return 'Carico di lavoro massimo ($name)';
  }

  @override
  String get estimated1rmMiddleOfRange =>
      '1RM stimato, centro dell\'intervallo';

  @override
  String get noLoggedSessionsYet => 'Nessuna sessione registrata.';

  @override
  String get noRadarFramesAvailable => 'Nessun fotogramma radar disponibile';

  @override
  String get playRadar => 'Riproduci radar';

  @override
  String get pauseRadar => 'Metti in pausa il radar';

  @override
  String get high => 'Alto';

  @override
  String get clear => 'Sereno';

  @override
  String get bodyweight => 'Peso corporeo';

  @override
  String get resistance2 => 'Resistenza —';

  @override
  String assistUnit(Object unit) {
    return 'Assistenza $unit';
  }

  @override
  String get reps2 => 'Rip. —';

  @override
  String get notRecorded => 'Non registrato';

  @override
  String get skipped => 'Saltato';

  @override
  String get health => 'Salute';

  @override
  String get manual => 'Manuale';

  @override
  String expandName(Object name) {
    return 'Espandi $name';
  }

  @override
  String get open => 'Apri';

  @override
  String get noScalePaired => 'Nessuna bilancia associata';

  @override
  String get paired => 'Associato';

  @override
  String get change => 'Cambia';

  @override
  String get noCuffPaired => 'Nessun bracciale associato';

  @override
  String get noPolarH10FoundWear =>
      'Nessun Polar H10 trovato. Indossa la fascia, inumidisci gli elettrodi e verifica che nessun\'altra app stia usando entrambe le connessioni Bluetooth.';

  @override
  String get enterMinutesSinceTrainingEnded =>
      'Inserisci i minuti dalla fine dell\'allenamento, da 0 a 1440.';

  @override
  String get timingFollowsYourWorkout => 'I tempi seguono il tuo allenamento.';

  @override
  String get recordingStayStill => 'Registrazione · resta fermo';

  @override
  String get meanHrBpm => 'FC media · bpm';

  @override
  String get pairAPolarH10First => 'Associa prima un Polar H10.';

  @override
  String get around30MinutesAfterTraining =>
      'Circa 30 minuti dopo l\'allenamento, quando l\'allenamento è disponibile in tempo.';

  @override
  String get reminderDiagnostics => 'Diagnostica promemoria';

  @override
  String get forecast => 'Previsioni';

  @override
  String forecastRange(int count) {
    return 'Area ombreggiata: intervallo di $count previsioni';
  }

  @override
  String get enterAName => 'Inserisci un nome';

  @override
  String get enterAValidAmount => 'Inserisci una quantità valida';

  @override
  String get enterAPositiveAmount => 'Inserisci una quantità positiva';

  @override
  String get maximum120GH => 'Massimo 120 g/h';

  @override
  String get carbohydrateTargetGH => 'Obiettivo carboidrati g/h';

  @override
  String get fluidTargetMlH => 'Obiettivo liquidi ml/h';

  @override
  String get sodiumTargetMgHNot => 'Obiettivo sodio mg/h (non sale)';

  @override
  String get surfaceFeedingAccess => 'Superficie / accesso al rifornimento';

  @override
  String get expectedAscentM => 'Dislivello previsto m';

  @override
  String get expectedAltitudeM => 'Altitudine prevista m';

  @override
  String get humidity => 'Umidità %';

  @override
  String get windKmH => 'Vento km/h';

  @override
  String get dayForecast => 'Previsioni del giorno';

  @override
  String get enteredConditions => 'Condizioni inserite';

  @override
  String get productFoodName => 'Nome prodotto / alimento';

  @override
  String get servingsQuantity => 'Porzioni / quantità';

  @override
  String get when => 'Quando';

  @override
  String get carbohydrateGServing => 'Carboidrati g / porzione';

  @override
  String get fluidMlServing => 'Liquidi ml / porzione';

  @override
  String get caffeineMgServing => 'Caffeina mg / porzione';

  @override
  String get proteinGServing => 'Proteine g / porzione';

  @override
  String get gel => 'Gel';

  @override
  String get water => 'Acqua';

  @override
  String get sportsDrink => 'Bevanda sportiva';

  @override
  String get bar => 'Barretta';

  @override
  String get finishIntakeLog => 'Termina registro assunzione';

  @override
  String get importing => 'Importazione…';

  @override
  String importNewreadings(Object newReadings) {
    return 'Importa $newReadings';
  }

  @override
  String get reading => 'Lettura…';

  @override
  String get chooseReportPdf => 'Scegli report (PDF)';

  @override
  String get yourTrainingHistoryIsReady =>
      'La cronologia degli allenamenti è pronta';

  @override
  String get importingYourTrainingHistory =>
      'Importazione della cronologia degli allenamenti';

  @override
  String get stopImport => 'Interrompi importazione';

  @override
  String get dismiss => 'Ignora';

  @override
  String get openai => 'OpenAI';

  @override
  String get appleIntelligence => 'Apple Intelligence';

  @override
  String get nonAiBriefing => 'Briefing senza IA';

  @override
  String get noBriefing => 'Nessun briefing';

  @override
  String get ruleBasedSummaryFromYour =>
      'Riepilogo basato su regole dai tuoi dati sanitari – nessuna chiamata API';

  @override
  String get hideTheBriefingCard => 'Nascondi la scheda del briefing';

  @override
  String get flutter => 'Flutter';

  @override
  String get stateManagement => 'Gestione dello stato';

  @override
  String get bluetoothLe => 'Bluetooth LE';

  @override
  String get interactiveMaps => 'Mappe interattive';

  @override
  String get chartsGraphs => 'Grafici e diagrammi';

  @override
  String get secureCredentialStorage =>
      'Archiviazione sicura delle credenziali';

  @override
  String get markdownRendering => 'Rendering Markdown';

  @override
  String get appleOnDeviceAi => 'IA Apple sul dispositivo';

  @override
  String get cryptography => 'Crittografia';

  @override
  String get appleHealthHealthConnect => 'Apple Salute e Health Connect';

  @override
  String get runtimePermissions => 'Permessi di runtime';

  @override
  String get shareExport => 'Condivisione ed esportazione';

  @override
  String get openUrls => 'Apertura URL';

  @override
  String get internationalisation => 'Internazionalizzazione';

  @override
  String get utilities => 'Utilità';

  @override
  String get icons => 'Icone';

  @override
  String get fjelia => 'Fjelia';

  @override
  String get fjeliaFeedback => 'Feedback su Fjelia';

  @override
  String get couldNotSendTheReport =>
      'Impossibile inviare la segnalazione. Il testo è ancora qui. Riprova.';

  @override
  String get yourEmail => 'La tua e-mail';

  @override
  String get enterAValidEmailAddress => 'Inserisci un indirizzo e-mail valido.';

  @override
  String get subject => 'Oggetto';

  @override
  String get sending => 'Invio…';

  @override
  String get sendReport => 'Invia segnalazione';

  @override
  String get sleepRecovery => 'Sonno e recupero';

  @override
  String get activitiesTraining => 'Attività e allenamento';

  @override
  String get bodyWellness => 'Corpo e benessere';

  @override
  String get hilo => 'Hilo';

  @override
  String get hiloBle => 'Hilo BLE';

  @override
  String get garminApi => 'Garmin (API)';

  @override
  String get renphoScale => 'Bilancia Renpho';

  @override
  String get connected => 'Collegato';

  @override
  String get notConnected => 'Non collegato';

  @override
  String get manage => 'Gestisci';

  @override
  String get connect => 'Collega';

  @override
  String get habits => 'Abitudini';

  @override
  String get smokingAlcohol => 'Fumo, alcol';

  @override
  String get clinicalLab => 'Analisi cliniche';

  @override
  String get hba1cLipidsKidney => 'HbA1c, lipidi, reni';

  @override
  String get sex => 'Sesso';

  @override
  String get smoking => 'Fumo';

  @override
  String get never => 'Mai';

  @override
  String get former => 'Ex';

  @override
  String get current => 'Attuale';

  @override
  String get hba1c => 'HbA1c';

  @override
  String get diabetes => 'Diabete';

  @override
  String get prediabetes => 'Prediabete';

  @override
  String get type1 => 'Tipo 1';

  @override
  String get type2 => 'Tipo 2';

  @override
  String get apob => 'ApoB';

  @override
  String get optionalPlansAndPaceGuides =>
      'Facoltativo. Piani e indicazioni di ritmo lo usano; anche il dislivello sopra influenza l\'allenamento.';

  @override
  String get addRaceGoal2 => 'Aggiungi obiettivo di gara';

  @override
  String get editRaceGoal => 'Modifica obiettivo di gara';

  @override
  String get trailRunning2 => 'Trail running';

  @override
  String get roadCycling => 'Ciclismo su strada';

  @override
  String get gravel => 'Gravel';

  @override
  String get indoorRowing => 'Canottaggio indoor';

  @override
  String get selectDate => 'Seleziona data';

  @override
  String get committed => 'Confermato';

  @override
  String get flexible => 'Flessibile';

  @override
  String get notGoing => 'Non partecipo';

  @override
  String get notSaid => 'Non indicato';

  @override
  String get finish => 'Tempo finale';

  @override
  String get saveGoal => 'Salva obiettivo';

  @override
  String get exportAllRecordedWorkoutsAs =>
      'Esporta tutti gli allenamenti registrati come foglio di calcolo.';

  @override
  String get backupsIncludeYourHealthData =>
      'I backup includono i dati sanitari, i piani di allenamento e le impostazioni del profilo. Le credenziali di accesso sono escluse. Il ripristino sostituisce i dati locali.';

  @override
  String get trail => 'Trail';

  @override
  String get inlineSkating => 'Pattinaggio inline';

  @override
  String get nordicClassic => 'Sci nordico classico';

  @override
  String get skateSkiing => 'Sci di fondo skating';

  @override
  String get strength => 'Forza';

  @override
  String get walking => 'Camminata';

  @override
  String get yoga => 'Yoga';

  @override
  String get skiing => 'Sci';

  @override
  String get climbing => 'Arrampicata';

  @override
  String get monday => 'Lunedì';

  @override
  String get sunday => 'Domenica';

  @override
  String get month => 'Mese';

  @override
  String get week => 'Settimana';

  @override
  String get list => 'Elenco';

  @override
  String get train => 'Allenamento';

  @override
  String get restDay => 'Riposo';

  @override
  String get kilogramsKg => 'Chilogrammi (kg)';

  @override
  String get poundsLb => 'Libbre (lb)';

  @override
  String get regenerateWorkouts => 'Rigenera allenamenti';

  @override
  String get starting => 'Avvio';

  @override
  String get allPlannedWorkoutsDeleted =>
      'Tutti gli allenamenti pianificati sono stati eliminati.';

  @override
  String get searching => 'Ricerca…';

  @override
  String get searchCity => 'Cerca città';

  @override
  String get fixedLocationSavedWeatherWill =>
      'Posizione fissa salvata. Il meteo verrà aggiornato.';

  @override
  String get locationDisabledThePlanWeather =>
      'Posizione disattivata. La scheda meteo del piano è nascosta.';

  @override
  String locationSetToName(Object name) {
    return 'Posizione impostata su $name';
  }

  @override
  String get notEnoughDaytimeAndNighttime =>
      'Misurazioni diurne e notturne insufficienti';

  @override
  String get onlyTheWeightWasReceived =>
      'È stato ricevuto solo il peso. Per grasso corporeo, muscoli e gli altri valori resta a piedi nudi sugli elettrodi metallici finché la bilancia non ha finito.';

  @override
  String get addYourWaistInProfile =>
      'Aggiungi il girovita in Profilo per il grasso viscerale.';

  @override
  String get manualActivity => 'Attività manuale';

  @override
  String get theseCredentialsAreStoredEncrypted =>
      'Queste credenziali sono archiviate cifrate sul dispositivo (Keychain iOS / Android Keystore). Non vengono mai inviate a server diversi da Hilo.';

  @override
  String get corosCredentialsAreStoredEncrypted =>
      'Le credenziali Coros sono archiviate cifrate sul dispositivo. Fjelia legge i dati direttamente dall\'API cloud di Coros, la stessa dell\'app web Coros Training Hub.';

  @override
  String get connectAnyCombinationYouCan =>
      'Collega qualsiasi combinazione: potrai sempre aggiungerne altre in seguito nelle Impostazioni.';

  @override
  String get garminCredentialsAreStoredEncrypted =>
      'Le credenziali Garmin sono archiviate cifrate sul dispositivo. Fjelia usa l\'API non ufficiale di Garmin Connect, lo stesso approccio di molte app della community.';

  @override
  String get enterTheVerificationCode => 'Inserisci il codice di verifica';

  @override
  String get appleHealthDataAccess =>
      'Fjelia legge i tuoi dati sanitari da Apple Salute. Con il tuo consenso, può anche scrivere i dati sincronizzati in Apple Salute. Gestisci gli accessi nelle impostazioni del dispositivo.';

  @override
  String get scanAgain => 'Cerca di nuovo';

  @override
  String get wearTheHiloBandDuring =>
      'Indossa il bracciale Hilo durante il sonno per la registrazione continua della pressione. I dati si sincronizzano automaticamente ogni mattina all\'apertura dell\'app.';

  @override
  String get noPolarH10FoundWear2 =>
      'Nessun Polar H10 trovato. Indossa la fascia con gli elettrodi inumiditi e assicurati che nessun\'altra app (o orologio) sia collegata, poi cerca di nuovo.';

  @override
  String get wearTheStrapWithMoist2 =>
      'Indossa la fascia con gli elettrodi inumiditi prima della ricerca. Misura poi con + → Misurazione HRV Polar H10; i risultati compaiono accanto all\'HRV notturna.';

  @override
  String get signedInPlannedWorkoutsCan =>
      'Accesso effettuato. Ora puoi inviare gli allenamenti pianificati a Polar. Le sessioni più vecchie vengono importate con la prossima sincronizzazione completa della cronologia.';

  @override
  String get saveYourPolarFlowLogin =>
      'Salva il login di Polar Flow per inviare gli allenamenti pianificati e importare le sessioni più vecchie di 30 giorni. Resta nel Keychain di questo dispositivo e viene inviato solo a Polar. Invia un allenamento dalla scheda del planner, poi sincronizza Polar Flow con l\'orologio. Verifica che le zone di frequenza cardiaca Polar corrispondano a quelle di Fjelia.';

  @override
  String get signInToSendThis =>
      'Accedi per inviare questo allenamento al calendario di Polar Flow. Il login resta nel Keychain di questo dispositivo e viene inviato solo a Polar. Dopo l\'invio, sincronizza Polar Flow con l\'orologio.';

  @override
  String get checkAndSave => 'Controlla e salva';

  @override
  String get noScaleFoundStepOn =>
      'Nessuna bilancia trovata. Sali sulla bilancia per attivarla, poi cerca di nuovo.';

  @override
  String get stepOnTheScaleBefore =>
      'Sali sulla bilancia prima della ricerca per attivarla. In seguito usa + → Bilancia RENPHO per misurare.';

  @override
  String get renphoCredentialsAreStoredEncrypted =>
      'Le credenziali Renpho sono archiviate cifrate sul dispositivo. Fjelia comunica direttamente con l\'API cloud di Renpho.';

  @override
  String get couldNotSendSmsCheck =>
      'Impossibile inviare l\'SMS. Controlla il numero di telefono e la connessione a internet.';

  @override
  String get theEmailIsUsedFor =>
      'L\'e-mail serve per firmare in modo sicuro le richieste e non viene inviata ai server Suunto.';

  @override
  String get suuntoUsesSmsVerificationSame =>
      'Suunto usa la verifica via SMS (come l\'app Suunto). Un PIN monouso verrà inviato al telefono. Le credenziali sono archiviate cifrate solo sul dispositivo.';

  @override
  String get tellUsAboutYourRace =>
      'Parlaci della tua gara e del tuo programma. Fjelia crea subito il piano e ricava il tuo livello dalle attività passate (Garmin, Suunto, Polar, COROS, Apple Salute) appena scaricate.';

  @override
  String get noAccountConnectedSoFjelia =>
      'Nessun account collegato, quindi Fjelia non ha uno storico da cui imparare. Collega Garmin, Suunto, Polar, COROS o Apple Salute e deciderà il tuo allenamento reale.';

  @override
  String get yourPastActivitiesAreStill =>
      'Le tue attività passate sono ancora in fase di importazione. Puoi già creare il piano: verrà affinato automaticamente al termine dell\'importazione.';

  @override
  String get buildingYourPlan => 'Creazione del piano…';

  @override
  String get saveContinue => 'Salva e continua';

  @override
  String get addYourMainPriorityA =>
      'Aggiungi la tua gara principale (priorità A). Il piano viene periodizzato verso di essa: base, sviluppo, picco e scarico. Senza un obiettivo di gara non viene ancora generato alcun piano.';

  @override
  String get noMeasurementsYet => 'Nessuna misurazione';

  @override
  String get date => 'Data';

  @override
  String deepSleepIsBelowOptimal(Object round) {
    return 'Il sonno profondo è sotto l\'ottimale ($round%). Evita alcol e pasti abbondanti 3 ore prima di dormire.';
  }

  @override
  String get finishWithSetsOpen => 'Terminare con serie aperte?';

  @override
  String get completeThePlannedWorkout =>
      'Completare l\'allenamento pianificato?';

  @override
  String get marksThePlannedSessionAs =>
      'Segna la sessione pianificata come completata con questo allenamento.';

  @override
  String get discardThisWorkout => 'Scartare questo allenamento?';

  @override
  String get removesTheWorkoutAndEvery =>
      'Rimuove l\'allenamento e ogni serie registrata al suo interno.';

  @override
  String assistanceName(Object name) {
    return 'Assistenza ($name)';
  }

  @override
  String get enterSecondsOrMSs => 'Inserisci secondi o m:ss.';

  @override
  String get enterTheLoadAsA => 'Inserisci il carico come numero.';

  @override
  String get loadCannotBeNegative => 'Il carico non può essere negativo.';

  @override
  String get enterTheEffortValue => 'Inserisci il valore dello sforzo.';

  @override
  String get nameTheExercise => 'Dai un nome all\'esercizio.';

  @override
  String get atLeastOneImplement => 'Almeno un attrezzo.';

  @override
  String get anIncrementMustBePositive => 'Un incremento deve essere positivo.';

  @override
  String get enterAPositiveStep => 'Inserisci un incremento positivo.';

  @override
  String get repsInReserve => 'Ripetizioni in riserva';

  @override
  String get loadPerImplement => 'Carico per attrezzo';

  @override
  String get restAfterThisSet => 'Recupero dopo questa serie';

  @override
  String get enterHowLongTheSet => 'Inserisci quanto è durata la serie.';

  @override
  String get repsDonePerSide => 'Ripetizioni eseguite per lato';

  @override
  String plannedRepminRepmax(Object repMin, Object repMax) {
    return 'Previsto $repMin–$repMax';
  }

  @override
  String get restTakenBeforeTheNext =>
      'Recupero preso prima della serie successiva';

  @override
  String get equipment => 'Attrezzatura';

  @override
  String get implementsUsedTogether => 'Attrezzi usati insieme';

  @override
  String get smallestLoadStepOptional =>
      'Incremento di carico minimo (facoltativo)';

  @override
  String get theSmallestChangeYourPlates =>
      'La più piccola variazione consentita da dischi, manubri o macchina, ricordata per questa attrezzatura.';

  @override
  String get loadStep => 'Incremento di carico';

  @override
  String get finishWithIncompleteData => 'Terminare con dati incompleti?';

  @override
  String get leaveWithoutSaving => 'Uscire senza salvare?';

  @override
  String get theLastChangeCouldNot =>
      'Non è stato possibile salvare l\'ultima modifica.';

  @override
  String get comparedWithAPlanChosen =>
      'Confrontato con un piano scelto dopo l\'allenamento. I valori pianificati sono indicazioni, non risultati.';

  @override
  String get lastSet => 'Ultima serie';

  @override
  String get templateName => 'Nome del modello';

  @override
  String get betweenExercises => 'Tra gli esercizi';

  @override
  String get betweenRounds => 'Tra i giri';

  @override
  String get discardChanges => 'Scartare le modifiche?';

  @override
  String get yourEditsToThisWorkout =>
      'Le modifiche a questo allenamento non sono salvate.';

  @override
  String get estimatedDuration => 'Durata stimata';

  @override
  String get workingSets => 'Serie di lavoro';

  @override
  String get estimatedExternalVolume => 'Volume esterno stimato';

  @override
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion) {
    return 'Carico aumentato da $unit a $unit2 dopo la tua revisione (regola v$ruleVersion).';
  }

  @override
  String get thePlannedWorkoutHasNo =>
      'L\'allenamento pianificato non ha esercizi da registrare.';

  @override
  String get completedSets => 'Serie completate';

  @override
  String get knownExternalVolume => 'Volume esterno noto';

  @override
  String get updateStrengthSessions2 => 'Aggiornare le sessioni di forza?';

  @override
  String get upcomingSessionsArePlannedAgain =>
      'Le prossime sessioni vengono pianificate di nuovo da oggi: la forza segue i tuoi obiettivi di gara in ogni giorno di forza, con sessioni varie. Gli allenamenti completati e saltati restano; gli esercizi modificati in una prossima sessione di forza vengono sostituiti.';

  @override
  String get thisSessionUsesAnEarlier =>
      'Questa sessione usa un modello di forza precedente. I piani aggiornati variano la forza in base a fase e obiettivo di gara e usano ogni giorno di forza.';

  @override
  String get estimated1rmUsesEpleyAnd =>
      'Il 1RM stimato usa Epley e Brzycki sulle serie di lavoro completate da 1–10 ripetizioni con carico noto, mostrato come intervallo tra i due. È una stima, non un massimale testato.';

  @override
  String get localWeather => 'Meteo locale';

  @override
  String get today => 'Oggi';

  @override
  String get low => 'Basso';

  @override
  String get moderate => 'Moderato';

  @override
  String get overcast => 'Coperto';

  @override
  String get partlyCloudy => 'Parzialmente nuvoloso';

  @override
  String collapseName(Object name) {
    return 'Comprimi $name';
  }

  @override
  String get variableLoads => 'Carichi variabili';

  @override
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  ) {
    return 'Regola v$strengthProgressionRuleVersion: le ultime $strengthProgressionMinSessions sessioni comparabili, ogni serie al massimo del suo obiettivo di ripetizioni, con sforzo registrato e non più duro del previsto. $reason';
  }

  @override
  String get stepOnYourScaleBefore => 'Sali sulla bilancia prima della ricerca';

  @override
  String get scanning => 'Ricerca in corso…';

  @override
  String get pair => 'Associa';

  @override
  String get selectYourAktiiaPWristband =>
      'Seleziona il tuo braccialetto AKTIIA P…. Mettilo sul caricatore per attivarlo se non è visibile.';

  @override
  String get measurementInterruptedWhileTheApp =>
      'Misurazione interrotta mentre l\'app era in background. Ripetila.';

  @override
  String get noRecentRrDataWith =>
      'Nessun dato RR recente con buon contatto. Controlla la fascia e ripeti la misurazione.';

  @override
  String get settlingStayStill => 'Assestamento · resta fermo';

  @override
  String get deleteSpotHrvMeasurement =>
      'Eliminare la misurazione HRV puntuale?';

  @override
  String get thisRemovesTheRecordingAnd =>
      'Questo rimuove la registrazione e i relativi intervalli RR grezzi.';

  @override
  String get appleHealthStoppedAnsweringSo =>
      'Apple Salute ha smesso di rispondere, quindi Fjelia l\'ha scollegato e non legge né scrive più dati sanitari.\n\nConsenti di nuovo Fjelia in Impostazioni → Salute → Accesso ai dati e dispositivi → Fjelia, poi ricollega Apple Salute.';

  @override
  String get thisRemovesTheSelectedGrip =>
      'Questo rimuove la misurazione della forza di presa selezionata.';

  @override
  String get hideReminderDiagnostics => 'Nascondi diagnostica promemoria';

  @override
  String get loading => 'Caricamento…';

  @override
  String get touchTheChartForDetails => 'Tocca il grafico per i dettagli';

  @override
  String get indoor => 'Indoor';

  @override
  String get road => 'Strada';

  @override
  String get technical => 'Tecnico';

  @override
  String get snow => 'Neve';

  @override
  String get pool => 'Piscina';

  @override
  String get openWater => 'Acque libere';

  @override
  String get ambientTemperatureC => 'Temperatura ambiente °C';

  @override
  String carryAboutGelsGelsGelcarbs(
    Object gels,
    Object gelCarbs,
    Object bottles,
    Object bottleMl,
    Object drinkCarbs,
  ) {
    return 'Porta circa $gels gel ($gelCarbs g di carboidrati ciascuno) + $bottles × borracce da $bottleMl ml. $drinkCarbs g di carboidrati provengono dalla polvere per bevanda.';
  }

  @override
  String get intakeNotRecorded => 'Assunzione non registrata';

  @override
  String get loggingDeclinedIntakeUnknown =>
      'Registrazione rifiutata – assunzione sconosciuta';

  @override
  String get confirmedNoIntake => 'Confermato: nessuna assunzione';

  @override
  String get draft => 'Bozza · ';

  @override
  String get actualIntakePerServing => 'Assunzione effettiva · per porzione';

  @override
  String get minuteIntoWorkoutDuringOnly =>
      'Minuto dell\'allenamento (solo durante, facoltativo)';

  @override
  String get sodiumMgServingNotSalt => 'Sodio mg / porzione (non sale)';

  @override
  String get comfortable => 'Confortevole';

  @override
  String get mildSymptoms => 'Sintomi lievi';

  @override
  String get moderateSymptoms => 'Sintomi moderati';

  @override
  String get severeSymptoms => 'Sintomi gravi';

  @override
  String get personalNutritionSettings => 'Impostazioni nutrizionali personali';

  @override
  String get practisedCarbohydrateToleranceGH =>
      'Tolleranza ai carboidrati allenata g/h (fino a 120)';

  @override
  String get exportTheMonthlyReportAs =>
      'Esporta il report mensile in PDF nell\'app Hilo, poi sceglilo qui. Vengono importate solo le misurazioni; nome, e-mail e dati corporei del report vengono ignorati.';

  @override
  String get nothingNewAllReadingsWere =>
      'Nessuna novità: tutte le misurazioni erano già salvate.';

  @override
  String get historyImportIncomplete =>
      'Importazione della cronologia incompleta';

  @override
  String get youCanKeepUsingFjelia =>
      'Puoi continuare a usare Fjelia, ma tienila aperta: iOS mette in pausa l\'importazione quando l\'app è in background e riprende alla prossima apertura. Il piano viene calibrato al termine dell\'importazione.';

  @override
  String get addYourBirthYearIn =>
      'Aggiungi l\'anno di nascita in Impostazioni → Profilo per vedere la stima.';

  @override
  String get fitnessAge => 'Età di forma';

  @override
  String get estLifespan => 'Aspettativa di vita stim.';

  @override
  String get delta => 'Differenza';

  @override
  String couldNotOpenKey(Object key) {
    return 'Impossibile aprire $key';
  }

  @override
  String get appleIntelligenceIsNotAvailable =>
      'Apple Intelligence non è disponibile su questo dispositivo. Usa Free AI o scegli un altro fornitore.';

  @override
  String get personalisedMorningLunchAfternoonEvening =>
      'Riepilogo personalizzato di mattina/pranzo/pomeriggio/sera';

  @override
  String get enterASubject => 'Inserisci un oggetto.';

  @override
  String get message => 'Messaggio';

  @override
  String get enterAMessageOfAt =>
      'Inserisci un messaggio di almeno 10 caratteri.';

  @override
  String get garminConnect => 'Garmin Connect';

  @override
  String get hiloBloodPressure => 'Hilo (pressione sanguigna)';

  @override
  String get renphoBodyScale => 'Renpho (bilancia pesapersone)';

  @override
  String get hiloPodCuff => 'Hilo Pod / bracciale';

  @override
  String disconnectLabel(Object label) {
    return 'Disconnettere $label?';
  }

  @override
  String get yourSavedMeasurementsWillRemain =>
      'Le misurazioni salvate resteranno su questo dispositivo.';

  @override
  String get notEnoughRecentHeartRate =>
      'Dati recenti di frequenza cardiaca insufficienti per regolare le zone.';

  @override
  String get aerobicBase => 'Base aerobica';

  @override
  String get tempo => 'Tempo';

  @override
  String get lactateThreshold => 'Soglia del lattato';

  @override
  String get birthYearHeightWaist => 'Anno di nascita, altezza, girovita';

  @override
  String get enterAValidValue => 'Inserisci un valore valido';

  @override
  String get birthYear => 'Anno di nascita';

  @override
  String get height => 'Altezza';

  @override
  String get waist => 'Girovita';

  @override
  String get yearsSinceQuit => 'Anni dallo smettere';

  @override
  String get cigarettesPerDay => 'Sigarette al giorno';

  @override
  String get standardDrinksPerMonth => 'Drink standard al mese';

  @override
  String get enterAValidNumber => 'Inserisci un numero valido';

  @override
  String get enterARaceName => 'Inserisci il nome della gara';

  @override
  String get useHMmOrH =>
      'Usa h:mm o h:mm:ss, un tempo che potresti davvero correre';

  @override
  String get flexibleThePlanMayDrop =>
      'Flessibile: il piano può eliminare questo evento se è in conflitto con uno più importante.';

  @override
  String get selectARaceDate => 'Seleziona la data della gara';

  @override
  String thatIsTenTimesOr(Object likely) {
    return 'È dieci volte (o un decimo) la distanza abituale di $likely km. Usare invece $likely km?';
  }

  @override
  String get addGoal => 'Aggiungi obiettivo';

  @override
  String get restoreFailed => 'Ripristino non riuscito';

  @override
  String get replaceLocalData => 'Sostituire i dati locali?';

  @override
  String get restoringThisBackupReplacesAll =>
      'Il ripristino di questo backup sostituisce tutti i dati locali di salute e allenamento. Le credenziali di accesso esistenti vengono mantenute.';

  @override
  String get openingBackupZip => 'Apertura dello ZIP del backup';

  @override
  String get addAFutureRaceGoal =>
      'Aggiungi prima un obiettivo di gara futuro.';

  @override
  String get deleteAllWorkouts2 => 'Eliminare tutti gli allenamenti?';

  @override
  String get thisDeletesPlannedWorkoutsOn =>
      'Questo elimina gli allenamenti pianificati su questo telefono e sulla piattaforma dell\'orologio collegata. Le attività completate vengono mantenute.';

  @override
  String get regenerateWorkouts2 => 'Rigenerare gli allenamenti?';

  @override
  String get noRaceGoalsYetAdd =>
      'Nessun obiettivo di gara. Aggiungine uno o sincronizza da Garmin.';

  @override
  String get deleteRaceGoal => 'Eliminare l\'obiettivo di gara?';

  @override
  String deletingFailedFailure(Object failure) {
    return 'Eliminazione non riuscita: $failure';
  }

  @override
  String allPlannedWorkoutsDeletedRemoved(Object removed) {
    return 'Tutti gli allenamenti pianificati sono stati eliminati. Rimossi dalle tue piattaforme: $removed.';
  }

  @override
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return 'Uso della posizione attuale: $toStringAsFixed, $toStringAsFixed2';
  }

  @override
  String get typeSleep => 'Sonno';

  @override
  String get typeBloodPressure => 'Pressione sanguigna';

  @override
  String get addHiloBpReportPdf => 'Aggiungi report pressione Hilo (PDF)';

  @override
  String get hiloCuffBle => 'Bracciale Hilo (BLE)';

  @override
  String get typeSpo2 => 'SpO₂ / pulsossimetro';

  @override
  String get typeWeightScale => 'Bilancia pesapersone';

  @override
  String get polarH10HrvMeasurement => 'Misurazione HRV Polar H10';

  @override
  String samplingWouldStartMinutes(Object minutes) {
    return 'Il campionamento inizierebbe circa $minutes min dopo la fine dell\'allenamento.';
  }

  @override
  String samplingStartedMinutes(Object minutes) {
    return 'Il campionamento è iniziato $minutes min dopo la fine dell\'allenamento.';
  }

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get before => 'Prima';

  @override
  String get during => 'Durante';

  @override
  String get after => 'Dopo';

  @override
  String get enumWarmUp => 'Riscaldamento';

  @override
  String get enumWorking => 'Di lavoro';

  @override
  String get enumBackOff => 'Back-off';

  @override
  String get enumTechnique => 'Tecnica';

  @override
  String get enumExternalLoad => 'Carico esterno';

  @override
  String get enumBandResistance => 'Fascia / resistenza';

  @override
  String get enumTotalLoad => 'Carico totale';

  @override
  String get enumPerImplement => 'Per attrezzo';

  @override
  String get enumOneImplement => 'Un attrezzo';

  @override
  String get enumBothSides => 'Entrambi i lati';

  @override
  String get enumAlternatingTotalReps => 'Alternato, ripetizioni totali';

  @override
  String get enumPartial => 'Parziale';

  @override
  String get enumFailed => 'Fallita';

  @override
  String get enumStraightSets => 'Serie standard';

  @override
  String get enumSuperset => 'Superserie';

  @override
  String get enumCircuit => 'Circuito';

  @override
  String get enumRir => 'RIR';

  @override
  String get enumRpe110 => 'RPE 1–10';

  @override
  String get enumBeforeTraining => 'Prima dell\'allenamento';

  @override
  String get enumAfterTraining => 'Dopo l\'allenamento';

  @override
  String get enumResting => 'A riposo';

  @override
  String get enumSeated => 'Seduto';

  @override
  String get enumLyingDown => 'Sdraiato';

  @override
  String get duringRoutineGelsAreNot =>
      'Durante: i gel di routine non servono per questa sessione breve/facile. Bevi secondo la sete.';

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      'Durante: distribuisci carboidrati e bevande in piccole assunzioni regolari. Conta i carboidrati delle bevande nello stesso totale di gel e cibo.';

  @override
  String get fluidIsAnEditableStarting =>
      'I liquidi sono una stima iniziale modificabile, non una quota. Usa sete, assunzione abituale e perdite di sudore misurate; non forzare altra acqua.';

  @override
  String get afterHaveCarbohydrateAndA =>
      'Dopo: assumi carboidrati e un pasto con proteine. Dai priorità a rifornimento e reidratazione se un\'altra sessione è vicina.';

  @override
  String get swimmingPlaceALabelledBottle =>
      'Nuoto: posiziona una borraccia etichettata a bordo vasca e usa le pause tra le serie per sorsi o rifornimenti. Le condizioni della piscina possono differire dal meteo esterno.';

  @override
  String get runningCarryAccessibleGelsFlasks =>
      'Corsa: porta gel/flask facilmente accessibili o pianifica i rifornimenti ai ristori; esercitati con gli stessi prodotti e tempi prima della gara.';

  @override
  String get servingSizesAndToleranceMust =>
      'Dimensioni delle porzioni e tolleranza devono essere positive.';

  @override
  String get enterFiniteNonNegativeMeasurements =>
      'Inserisci misurazioni finite e non negative.';

  @override
  String get targetsMustBeFiniteAnd =>
      'Gli obiettivi devono essere finiti e non negativi.';

  @override
  String get conditionsMustBeFiniteOr =>
      'Le condizioni devono essere finite o sconosciute.';

  @override
  String get humidityMustBeBetween0 =>
      'L\'umidità deve essere compresa tra 0 e 100%.';

  @override
  String get noIntakeCannotIncludeFood =>
      '«Nessuna assunzione» non può includere cibo o bevande.';

  @override
  String get addAnItemOrConfirm =>
      'Aggiungi un elemento o conferma di non aver assunto nulla.';

  @override
  String get eachIntakeNeedsAProduct =>
      'Ogni assunzione richiede un prodotto e un momento valido.';

  @override
  String get quantityMustBePositive => 'La quantità deve essere positiva.';

  @override
  String get thisActivityNoLongerExists => 'Questa attività non esiste più.';

  @override
  String get practisedCarbohydrateToleranceMustNot =>
      'La tolleranza ai carboidrati allenata non deve superare 120 g/h.';

  @override
  String get measuredSweatRateMustBe =>
      'Il tasso di sudorazione misurato deve essere positivo o lasciato sconosciuto.';

  @override
  String get increasePractisedToleranceInNutrition =>
      'Aumenta la tolleranza allenata nelle impostazioni di nutrizione prima di scegliere un obiettivo più alto.';

  @override
  String get fluidTargetExceedsYourMeasured =>
      'L\'obiettivo di liquidi supera il tasso di sudorazione misurato. Controlla la misurazione o l\'obiettivo.';

  @override
  String get elapsedWorkoutTimeMustBe =>
      'Il tempo di allenamento trascorso deve essere positivo o lasciato vuoto.';

  @override
  String get intakeAmountsMustBeFinite =>
      'Le quantità assunte devono essere finite e non negative.';

  @override
  String get selectedStrategyUnavailableChooseAnother =>
      'La strategia selezionata non è disponibile. Scegli un\'altra strategia o nessun confronto.';

  @override
  String get recordYourWorkoutNutrition =>
      'Registra l\'alimentazione dell\'allenamento';

  @override
  String get addTheFoodAndFluids =>
      'Aggiungi cibo e liquidi che hai realmente assunto nella cronologia dell\'attività.';

  @override
  String get logIntake => 'Registra assunzione';

  @override
  String nutritionReminderTitle(String name) {
    return 'Nuova attività: $name';
  }

  @override
  String get nutritionReminderBody => 'Aggiungi cosa hai mangiato e bevuto.';

  @override
  String get nutritionReminderHrvHint =>
      'La tua HRV post-allenamento non è ancora stata misurata.';

  @override
  String get in30Minutes => 'Tra 30 minuti';

  @override
  String get loadSuggestionsCoverStraightSets =>
      'I suggerimenti di carico valgono solo per serie standard con ripetizioni.';

  @override
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  ) {
    return 'Servono $strengthProgressionMinSessions sessioni registrate di questo esercizio.';
  }

  @override
  String get recentHistoryIsTooOld =>
      'La cronologia recente è troppo vecchia per un suggerimento.';

  @override
  String get theLastSessionDidNot =>
      'L\'ultima sessione non ha usato un unico carico noto.';

  @override
  String get theLoadChangedBetweenThe =>
      'Il carico è cambiato tra le sessioni recenti.';

  @override
  String get notEverySetReachedThe =>
      'Non tutte le serie hanno raggiunto il massimo del loro obiettivo di ripetizioni.';

  @override
  String get recordEffortRirOrRpe =>
      'Registra lo sforzo (RIR o RPE) nell\'ultima serie per ottenere suggerimenti.';

  @override
  String get recentSetsWereHarderThan =>
      'Le serie recenti sono state più dure del previsto.';

  @override
  String get thisWorkoutAlreadyHasIts =>
      'Questo allenamento ha già il proprio carico; resta come impostato.';

  @override
  String get yourRecentSetsMetThe =>
      'Le tue serie recenti rispettano la regola di progressione. Imposta il minimo incremento di carico per questa attrezzatura per rivedere un carico.';

  @override
  String get thisWorkoutNoLongerExists => 'Questo allenamento non esiste più.';

  @override
  String thisStrengthPlanCannotBe(Object message) {
    return 'Questo piano di forza non può essere letto ($message).';
  }

  @override
  String get thisStrengthPlanCannotBe2 =>
      'Questo piano di forza non può essere letto.';

  @override
  String get addAtLeastOneExercise => 'Aggiungi almeno un esercizio.';

  @override
  String get thisWorkoutWasChangedElsewhere =>
      'Questo allenamento è stato modificato altrove. Le tue modifiche sono conservate; ricarica per vedere la versione più recente.';

  @override
  String get thePlanThisWorkoutIs =>
      'Il piano con cui questo allenamento viene confrontato non può essere letto.';

  @override
  String get thisLogWasChangedElsewhere =>
      'Questo registro è stato modificato altrove. Le tue voci sono conservate; ricarica per vedere la versione più recente.';

  @override
  String get thisZipIsNotA => 'Questo ZIP non è un backup Fjelia supportato.';

  @override
  String get theBackupDatabaseIsDamaged =>
      'Il database del backup è danneggiato.';

  @override
  String get invalidBackupData => 'Dati di backup non validi.';

  @override
  String get backupTablesDoNotMatch =>
      'Le tabelle del backup non corrispondono.';

  @override
  String get invalidBackupColumns => 'Colonne del backup non valide.';

  @override
  String get migratingOriginalAppBackup =>
      'Migrazione del backup dell\'app originale';

  @override
  String get theOriginalBackupIsMissing =>
      'Nel backup originale mancano tabelle richieste.';

  @override
  String get backupFormatOrDatabaseVersion =>
      'Il formato del backup o la versione del database non corrisponde.';

  @override
  String get restoringRecords => 'Ripristino dei record';

  @override
  String get restoringSettings => 'Ripristino delle impostazioni';

  @override
  String get restoreComplete => 'Ripristino completato';

  @override
  String get effortMustBeANumber => 'Lo sforzo deve essere un numero.';

  @override
  String get theDurationEstimateMustBe =>
      'La stima della durata deve essere positiva.';

  @override
  String get restCannotBeNegative => 'Il recupero non può essere negativo.';

  @override
  String get enterTheRepetitionsDoneThe =>
      'Inserisci le ripetizioni eseguite; il piano ha un intervallo.';

  @override
  String get enterTheLoadThePlan => 'Inserisci il carico; il piano non ne ha.';

  @override
  String get enterTheResistanceThePlan =>
      'Inserisci la resistenza; il piano non ne ha.';

  @override
  String get poorSensorContact => 'Contatto del sensore scarso';

  @override
  String get moreThan25FromLocal => 'Oltre il 25% dalla mediana locale';

  @override
  String get workoutNutrition => 'Alimentazione dell\'allenamento';

  @override
  String get postWorkoutFoodAndFluid =>
      'Promemoria del registro di cibo e liquidi dopo l\'allenamento';

  @override
  String get postTrainingHrvMeasurementReminder =>
      'Promemoria della misurazione HRV post-allenamento';

  @override
  String get rirRunsFrom0To => 'RIR va da 0 a 10+.';

  @override
  String get rpeRunsFrom1To => 'RPE va da 1 a 10.';

  @override
  String get repetitionsCannotBeNegative =>
      'Le ripetizioni non possono essere negative.';

  @override
  String get timedWorkMustBeLonger =>
      'Il lavoro a tempo deve durare più di zero secondi.';

  @override
  String get chooseRepetitionsOrTimedWork =>
      'Scegli ripetizioni o lavoro a tempo, non entrambi.';

  @override
  String get loadMustBeAFinite =>
      'Il carico deve essere un numero finito e non negativo.';

  @override
  String get durationCannotBeNegative => 'La durata non può essere negativa.';

  @override
  String get hrTimeline => 'Cronologia FC';

  @override
  String get dayTrainingLoad => 'Carico di allenamento giornaliero';

  @override
  String get weekdayComparison => 'Confronto per giorno della settimana';

  @override
  String get weeklyTrainingLoad => 'Carico di allenamento settimanale';

  @override
  String get zonePolarization => 'Polarizzazione delle zone';

  @override
  String get elevationOverview => 'Panoramica dislivello';

  @override
  String get trainingMonitor => 'Monitor di allenamento';

  @override
  String get formAtlCtlTsb => 'Forma ATL / CTL / TSB';

  @override
  String get trainingPlanProgress => 'Avanzamento del piano di allenamento';

  @override
  String get rhrSleep => 'FC a riposo nel sonno';

  @override
  String get hrvSleep => 'HRV nel sonno';

  @override
  String get spo2Sleep => 'SpO₂ nel sonno';

  @override
  String get respRate => 'Frequenza respiratoria';

  @override
  String get stress => 'Stress';

  @override
  String get skinTemp => 'Temperatura cutanea';

  @override
  String get steps => 'Passi';

  @override
  String get tonightsSleep => 'Sonno di stanotte';

  @override
  String get activityLog => 'Registro attività';

  @override
  String get activityLog2 => 'Registro attività';

  @override
  String get history2 => 'CRONOLOGIA';

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
  String get heatAcclimation2 => 'ACCLIMATAZIONE AL CALDO';

  @override
  String score(Object score) {
    return '$score%';
  }

  @override
  String get elevation => 'DISLIVELLO';

  @override
  String get t12WeekHistory => 'CRONOLOGIA DI 12 SETTIMANE';

  @override
  String get zonePolarization2 => 'POLARIZZAZIONE DELLE ZONE';

  @override
  String get t5WeekHistory => 'CRONOLOGIA DI 5 SETTIMANE';

  @override
  String get easy => 'FACILE %';

  @override
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded) {
    return '$withZones attività su $recorded con dati delle zone FC';
  }

  @override
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples) {
    return '$fromSamples ricostruite dai campioni FC registrati';
  }

  @override
  String get easyZ12ModerateZ3 => 'Facile: Z1–2 · Moderato: Z3 · Intenso: Z4–5';

  @override
  String get activitiesWithoutHrZoneData =>
      'Le attività senza dati delle zone FC sono escluse dalle percentuali.';

  @override
  String avgAverageUnit(Object average, Object unit) {
    return 'MED $average $unit';
  }

  @override
  String get weekdayComparison2 => 'CONFRONTO PER GIORNO DELLA SETTIMANA';

  @override
  String get trainingPlanProgress2 => 'AVANZAMENTO DEL PIANO DI ALLENAMENTO';

  @override
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  ) {
    return 'Settimana $currentWeek / $durationInWeeks';
  }

  @override
  String get t30MinTimeTrialLt2 => 'PROVA A TEMPO DI 30 MIN – LT2';

  @override
  String get run30MinutesAtThe =>
      'Corri per 30 minuti al massimo sforzo sostenibile: controllato, senza scattare. Entra gradualmente nello sforzo; non partire troppo forte. Passo e FC medi degli ultimi 20 minuti sono la tua LT2.';

  @override
  String get recordAsANormalOutdoor =>
      'Registralo come una normale corsa all\'aperto. Avvia l\'orologio, annota l\'ora e corri 30 min a ritmo gara.';

  @override
  String get t50MinTotalFlatCourse =>
      '~50 min in totale · percorso piatto · non dopo allenamento intenso';

  @override
  String get doNotStartTooFast =>
      'Non partire troppo forte. Punta a parziali regolari.';

  @override
  String get theAppAveragesHrAnd =>
      'L\'app fa la media di FC e passo sugli ultimi 20 minuti della prova, dopo il riscaldamento e i primi 10 minuti. Seleziona l\'attività registrata in Calcola.';

  @override
  String get lt2Pace => 'PASSO LT2';

  @override
  String get activityRunningEnoughTimeFor =>
      'Attività (corsa, tempo sufficiente per riscaldamento + 30 min, con FC)';

  @override
  String get selectTheTtActivity => 'Seleziona l\'attività della prova';

  @override
  String nameStartdate(Object name, Object startDate) {
    return '$name · $startDate';
  }

  @override
  String get warmUpBeforeTt => 'Riscaldamento prima della prova';

  @override
  String roundMin(Object round) {
    return '$round min';
  }

  @override
  String get clearResults => 'Cancella risultati';

  @override
  String get heartRate2 => 'FREQUENZA CARDIACA';

  @override
  String get paceSecKmLowerIs => 'Passo (sec/km – più basso è più veloce)';

  @override
  String get thresholdsFitnessTests => 'Soglie e test di fitness';

  @override
  String get lt1 => 'LT1';

  @override
  String get lt2 => 'LT2';

  @override
  String get voPace => 'Passo VO₂';

  @override
  String get ftp => 'FTP';

  @override
  String get setFtpManually => 'Imposta FTP manualmente';

  @override
  String get calculateFromAnActivity => 'Calcola da un\'attività';

  @override
  String get setFtp => 'Imposta FTP';

  @override
  String get ftpWatts => 'FTP (watt)';

  @override
  String get ftpCyclingThresholdPower => 'FTP – POTENZA DI SOGLIA NEL CICLISMO';

  @override
  String get ftpHistory => 'CRONOLOGIA FTP';

  @override
  String get updateFromActivity => 'AGGIORNA DA ATTIVITÀ';

  @override
  String get tapAnActivityFtpBest =>
      'Tocca un\'attività – FTP = miglior potenza sui 20 min × 0,95';

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
      'Nessuna uscita con 20 minuti di campioni di potenza continui.';

  @override
  String get enterFtpManually => 'Inserisci FTP manualmente';

  @override
  String get selectTheTestActivity => 'Seleziona l\'attività del test';

  @override
  String get formAtlCtlTsb2 => 'FORMA · ATL / CTL / TSB';

  @override
  String get closeTrainingFormFullscreen =>
      'Chiudi la forma di allenamento a schermo intero';

  @override
  String get expandTrainingForm => 'Espandi la forma di allenamento';

  @override
  String get calculatedFromTheFirstAvailable =>
      'Calcolato dal primo record di carico disponibile. I giorni senza carico registrato contano come zero; l\'allenamento precedente è sconosciuto.';

  @override
  String get trainingMonitor2 => 'MONITOR DI ALLENAMENTO';

  @override
  String get pfitzingerZones => 'ZONE DI PFITZINGER';

  @override
  String get cyclingPowerZones => 'ZONE DI POTENZA NEL CICLISMO';

  @override
  String znumber(Object number) {
    return 'Z$number';
  }

  @override
  String paceHrDescription(Object pace, Object hr, Object description) {
    return '$pace · $hr\n$description';
  }

  @override
  String get weeklyTrainingLoad2 => 'CARICO DI ALLENAMENTO SETTIMANALE';

  @override
  String get prevWeek => 'SETT. PREC.';

  @override
  String get bySport => 'PER SPORT';

  @override
  String get noActivitiesThisWeek => 'Nessuna attività questa settimana';

  @override
  String garminWorkoutScheduleddate(Object scheduledDate) {
    return 'Allenamento Garmin · $scheduledDate';
  }

  @override
  String get yourNote => 'La tua nota';

  @override
  String get askAiCoach => 'Chiedi al coach IA';

  @override
  String get aiSettings => 'Impostazioni IA';

  @override
  String get askYourCoach => 'Chiedi al tuo coach…';

  @override
  String get sendMessage => 'Invia messaggio';

  @override
  String get sendFeedbackOrReportA => 'Invia feedback o segnala un bug';

  @override
  String get addMeasurement2 => 'Aggiungi misurazione';

  @override
  String get syncLabel2 => 'Sincronizza';

  @override
  String get syncToday => 'Sincronizza oggi';

  @override
  String get fullSync1Year => 'Sincronizzazione completa · 1 anno';

  @override
  String get fullSyncComplete => 'Sincronizzazione completa · Completata';

  @override
  String get syncingYourData => 'Sincronizzazione dei dati…';

  @override
  String lLeftkgRRightkgKg2(Object leftKg, Object rightKg) {
    return 'S $leftKg  D $rightKg kg';
  }

  @override
  String weightKgFatBodyfatMuscle(
    Object weight,
    Object bodyFat,
    Object muscleMass,
  ) {
    return '$weight kg · Grasso $bodyFat% · Muscoli $muscleMass kg';
  }

  @override
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase) {
    return '$title, $sport, $toLowerCase';
  }

  @override
  String get weatherUnavailableTapToRetry =>
      'Meteo non disponibile · Tocca per riprovare';

  @override
  String get weatherSetYourLocation => 'Meteo · Imposta la posizione';

  @override
  String get t7DayForecast => 'PREVISIONI A 7 GIORNI';

  @override
  String get minMax => 'min/max';

  @override
  String get rainMm2 => 'pioggia mm';

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
    return 'Obiettivi di gara · $length';
  }

  @override
  String gWk(Object g) {
    return '$g sett.';
  }

  @override
  String weeks(Object weeks) {
    return '$weeks';
  }

  @override
  String get weeks2 => 'settimane';

  @override
  String get upcoming => 'IN ARRIVO';

  @override
  String lengthMoreDays(Object length) {
    return '+ altri $length giorni';
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
      '○ Pianificato   ● Completato   ✕ Saltato';

  @override
  String get heartRate3 => 'Frequenza cardiaca';

  @override
  String get watts => 'Watt';

  @override
  String theStepsAddUpTo(Object total, Object plannedDurationMin) {
    return 'I passaggi sommano $total; il piano conta $plannedDurationMin min.';
  }

  @override
  String get typicalSplitForThisKind =>
      'Ripartizione tipica per questo tipo di sessione; nessun passaggio da cui calcolarla.';

  @override
  String labelGetsEachExerciseWith(Object label) {
    return '$label riceve ogni esercizio con serie, ripetizioni e carichi. Intervalli di ripetizioni, sforzo e tempo restano in Fjelia.';
  }

  @override
  String get markAsRest => 'Segna come riposo';

  @override
  String get restoreWorkout => 'Ripristina allenamento';

  @override
  String get skipThisWorkout => 'Saltare questo allenamento?';

  @override
  String get previousWeek => 'Settimana precedente';

  @override
  String get backToThisWeek => 'Torna a questa settimana';

  @override
  String get thisWeek => 'Questa settimana';

  @override
  String get nextWeek => 'Settimana successiva';

  @override
  String get today2 => 'OGGI';

  @override
  String get route => 'PERCORSO';

  @override
  String get feedback => 'Feedback';

  @override
  String get plannedWorkout => 'Allenamento pianificato';

  @override
  String get delete => 'Elimina';

  @override
  String get chatAi => 'Chat IA';

  @override
  String get trainingLoad => 'Carico di allenamento';

  @override
  String get dayTrainingLoad2 => 'CARICO DI ALLENAMENTO GIORNALIERO';

  @override
  String get trimp => ' TRIMP';

  @override
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter) {
    return '$scoreBefore → $scoreAfter';
  }

  @override
  String get temperatureOverTime => 'TEMPERATURA NEL TEMPO';

  @override
  String roundh(Object round) {
    return '${round}h';
  }

  @override
  String get timeInHrZones => 'Tempo nelle zone FC';

  @override
  String get route2 => 'Percorso';

  @override
  String get start => 'Partenza';

  @override
  String get gpx => 'GPX';

  @override
  String touppercasesubstringBriefing(Object toUpperCase, Object substring) {
    return 'Briefing $toUpperCase$substring';
  }

  @override
  String get chatWithAiAboutThis => 'Chatta con l\'IA su questo briefing';

  @override
  String get whyThisRecommendation => 'Perché questo consiglio?';

  @override
  String titleDateLabel(Object title, Object date, Object label) {
    return '$title, $date, $label';
  }

  @override
  String get previousDay => 'Giorno precedente';

  @override
  String get nextDay => 'Giorno successivo';

  @override
  String get updating => 'Aggiornamento';

  @override
  String get resting => 'A RIPOSO';

  @override
  String get noTimedReadings => 'Nessuna lettura con orario';

  @override
  String get avg => 'MED';

  @override
  String get peak => 'PICCO';

  @override
  String tolocalRoundmin(Object toLocal, Object round) {
    return '$toLocal · ${round}min';
  }

  @override
  String avgheartrateBpmAvg(Object avgHeartRate) {
    return '$avgHeartRate bpm media';
  }

  @override
  String get timeWeightedAverageOverRecorded =>
      'Media pesata nel tempo sui periodi registrati. Le lacune senza letture sono escluse.';

  @override
  String get previousHeartRatePeriod =>
      'Periodo di frequenza cardiaca precedente';

  @override
  String get nextHeartRatePeriod => 'Periodo di frequenza cardiaca successivo';

  @override
  String get avgHr => 'FC media';

  @override
  String get restingHr => 'FC a riposo';

  @override
  String get both => 'Entrambi';

  @override
  String averagelabelFixedMs(Object averageLabel, Object fixed) {
    return '$averageLabel $fixed ms';
  }

  @override
  String get measureWithPolarH10 => 'Misura con Polar H10';

  @override
  String get ms => 'ms';

  @override
  String get noWorkoutInThisPeriod =>
      'Nessun allenamento in questo periodo ha una coppia prima/dopo confrontabile.';

  @override
  String textEachWorkoutCountsOnce(Object text) {
    return '$text. Ogni allenamento conta una volta; descrive le tue coppie, non le valuta.';
  }

  @override
  String get workoutFinished => 'Allenamento finito?';

  @override
  String get yourWorkoutIsNotIn =>
      'L\'allenamento non è ancora in Fjelia. Se è finito, indica quando, e il promemoria potrà seguire la fine reale. Altrimenti comparirà alla sincronizzazione dell\'orologio.';

  @override
  String get workoutFinished2 => 'Allenamento finito';

  @override
  String get theWorkoutMustStartAfter =>
      'L\'allenamento deve iniziare dopo la misurazione e finire dopo il suo inizio, non nel futuro.';

  @override
  String daysDAvg(Object days) {
    return '$days G media';
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
  String get previousPeriod => 'Periodo precedente';

  @override
  String get nextPeriod => 'Periodo successivo';

  @override
  String get overnightHrvReflectsRecoveryCompare =>
      'L\'HRV notturna riflette il recupero. Confronta le tue letture con la tua baseline nel tempo.';

  @override
  String get moveThisWorkout => 'SPOSTA QUESTO ALLENAMENTO';

  @override
  String get pickDate => 'Scegli la data';

  @override
  String movedFromMovedfrom(Object movedFrom) {
    return 'Spostato da $movedFrom';
  }

  @override
  String get hrvAroundThisWorkout => 'HRV intorno a questo allenamento';

  @override
  String get measureAfterTraining => 'Misura dopo l\'allenamento';

  @override
  String get measureAgain => 'Misura di nuovo';

  @override
  String get explainWithAi => 'Spiega con l\'IA';

  @override
  String beforeEndedPregapAheadOf(Object preGap) {
    return 'Il prima è terminato $preGap prima dell\'inizio.';
  }

  @override
  String lengthFurtherMeasurementSAfter(Object length) {
    return '$length ulteriori misurazioni dopo questo allenamento vengono conservate come osservazioni aggiuntive.';
  }

  @override
  String get noHrvMeasurementRecordedAround =>
      'Nessuna misurazione HRV registrata intorno a questo allenamento.';

  @override
  String get measureHrv => 'Misura HRV';

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
      'Una descrizione di questa coppia, non un punteggio per l\'allenamento.';

  @override
  String notEnoughComparableWorkoutsYet(Object eligible, Object need) {
    return 'Non ci sono ancora abbastanza allenamenti confrontabili, $eligible su $need.';
  }

  @override
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need) {
    return 'Non ci sono ancora abbastanza allenamenti confrontabili ($eligible su $need).';
  }

  @override
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  ) {
    return 'I tuoi $eligible allenamenti simili · $toLocal–$toLocal2';
  }

  @override
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  ) {
    return 'Metà centrale da $q1Ms a $q3Ms ms · mediana $medianMs ms · questo allenamento $delta ms';
  }

  @override
  String rpeI(Object i) {
    return 'RPE $i';
  }

  @override
  String get easy2 => 'facile';

  @override
  String get allOut => 'Al massimo';

  @override
  String workoutProfileDescription(Object description) {
    return 'Profilo dell\'allenamento: $description';
  }

  @override
  String get noActivitiesInThisPeriod => 'Nessuna attività in questo periodo';

  @override
  String get enableHeatAcclimationInTraining =>
      'Attiva l\'acclimatazione al caldo nelle impostazioni di allenamento.';

  @override
  String get noElevationThisWeek => 'Nessun dislivello questa settimana';

  @override
  String get noActivitiesSynced => 'Nessuna attività sincronizzata';

  @override
  String get noHrZoneData => 'Nessun dato delle zone FC';

  @override
  String get easyJogGetHrElevated =>
      'Corsetta facile: porta su la FC, gambe sciolte';

  @override
  String get fastestSustainablePaceLikeA =>
      'Passo sostenibile più veloce: come una gara di 30 min';

  @override
  String get walkCardiacRecovery => 'Camminata: recupero cardiaco';

  @override
  String get selectTheTtActivityFirst =>
      'Seleziona prima l\'attività della prova.';

  @override
  String get calculating => 'Calcolo…';

  @override
  String get calculateLt2 => 'Calcola LT2';

  @override
  String get enterFtpBetween30And => 'Inserisci una FTP tra 30 e 1000 W.';

  @override
  String get aerobicThreshold => 'Soglia aerobica';

  @override
  String get functionalThresholdPower => 'Potenza di soglia funzionale';

  @override
  String get estimated => 'Stimato';

  @override
  String get afterWarmingUpRunFive =>
      'Dopo il riscaldamento, corri cinque minuti al tuo massimo sforzo sostenibile. Registra la corsa con dati di velocità o distanza.';

  @override
  String get recordAtLeast40Minutes =>
      'Registra almeno 40 minuti di corsa costante a sforzo costante. Il test confronta la frequenza cardiaca in ogni metà per stimare la deriva aerobica.';

  @override
  String get theFastestFiveMinuteWindow =>
      'La finestra di cinque minuti più veloce fornisce il tuo passo VO2max.';

  @override
  String get noResultYet => 'Nessun risultato';

  @override
  String get calculateVo2maxPace => 'Calcola il passo VO2max';

  @override
  String get calculateLt1 => 'Calcola LT1';

  @override
  String get loading2 => 'Caricamento';

  @override
  String get unavailable => 'Non disponibile';

  @override
  String get noTrainingHistory => 'Nessuna cronologia di allenamento';

  @override
  String get fitnessCtl => 'Fitness (CTL)';

  @override
  String get fatigueAtl => 'Affaticamento (ATL)';

  @override
  String get formTsb => 'Forma (TSB)';

  @override
  String get noHistory => 'Nessuna cronologia';

  @override
  String get fresh => 'Fresco';

  @override
  String get optimal => 'Ottimale';

  @override
  String get neutral => 'Neutro';

  @override
  String get tired => 'Stanco';

  @override
  String get veryFatigued => 'Molto affaticato';

  @override
  String get garminRunningVo2max => 'VO2max corsa Garmin';

  @override
  String get garminCyclingVo2max => 'VO2max ciclismo Garmin';

  @override
  String get aerobicThreshold2 => 'Soglia aerobica';

  @override
  String driftDriftAt(Object drift, Object at) {
    return 'Deriva $drift% · $at';
  }

  @override
  String get activityHours => 'Ore di attività';

  @override
  String get activityKm => 'Km di attività';

  @override
  String get tap5MinuteMaxTest => 'Tocca · test massimale di 5 min';

  @override
  String get setFtpToCalculatePower =>
      'Imposta la FTP per calcolare le zone di potenza';

  @override
  String get cyclingPowerZones2 => 'Zone di potenza nel ciclismo';

  @override
  String get pfitzingerZones2 => 'Zone di Pfitzinger';

  @override
  String get completeAnLt2TestTo =>
      'Completa un test LT2 per calcolare le zone di corsa.';

  @override
  String get setFtpToCalculatePower2 =>
      'Imposta la FTP per calcolare le zone di potenza.';

  @override
  String get endurance => 'Resistenza';

  @override
  String get threshold => 'Soglia';

  @override
  String get anaerobic => 'Anaerobico';

  @override
  String get whatExplainsThisRise => 'Cosa spiega questo aumento?';

  @override
  String get whatExplainsThisDrop => 'Cosa spiega questo calo';

  @override
  String get whatExplainsThisRise2 => 'Cosa spiega questo aumento';

  @override
  String get editsAreKeptInFjelia =>
      'Le modifiche restano in Fjelia come copia locale per questa data. L\'allenamento su Garmin non cambia.';

  @override
  String get howDoIExecuteThis => 'Come eseguo questo allenamento?';

  @override
  String shareHealthContextWithName(Object name) {
    return 'Condividere il contesto sanitario con $name?';
  }

  @override
  String get yourMessageAndAHealth =>
      'Il tuo messaggio e un riepilogo salute/allenamento verranno inviati a questo provider IA cloud. Nomi e GPS sono esclusi dal riepilogo generato.';

  @override
  String get couldNotGetAReply =>
      'Impossibile ottenere una risposta. Controlla le impostazioni IA e riprova.';

  @override
  String get askAboutYourRecoveryTraining =>
      'Chiedi della tua forma di recupero, dell\'allenamento o del piano di oggi.';

  @override
  String get noSyncYet => 'Nessuna sincronizzazione';

  @override
  String lastSyncLastContext(Object last, Object context) {
    return 'Ultima sincronizzazione: $last $context';
  }

  @override
  String get seasonWithTradeOffs => 'Stagione: con compromessi';

  @override
  String get seasonNeedsYourDecision => 'Stagione: serve una tua decisione';

  @override
  String get seasonCannotBeCombined => 'Stagione: non combinabile';

  @override
  String get seasonProvisional => 'Stagione: provvisoria';

  @override
  String get season => 'Stagione';

  @override
  String get allGoalsFit => 'Tutti gli obiettivi sono compatibili.';

  @override
  String goalTargetfinishsecondsgoal(Object targetFinishSeconds, Object goal) {
    return 'Obiettivo $targetFinishSeconds$goal';
  }

  @override
  String estEstimateestimate2(Object estimate, Object estimate2) {
    return 'Stim. $estimate$estimate2';
  }

  @override
  String doneDoneby(Object doneBy) {
    return 'Fatto · $doneBy';
  }

  @override
  String garminWorkoutWorkout(Object workout) {
    return 'Allenamento Garmin · $workout';
  }

  @override
  String get moveAnyway => 'Spostare comunque?';

  @override
  String get wattsNeedYourFtpSet =>
      'I watt richiedono la tua FTP: impostala in Carico, Soglie.';

  @override
  String get mainTargetInWattsFrom =>
      'Obiettivo principale in watt dalla tua FTP, la frequenza cardiaca come guida.';

  @override
  String get mainTargetHeartRateWatts =>
      'Obiettivo principale: frequenza cardiaca; i watt non sono impostati sull\'orologio.';

  @override
  String get taperPhase => 'Fase di scarico';

  @override
  String get recoverySession => 'Sessione di recupero';

  @override
  String get closeToYourEvent => 'Vicino al tuo evento';

  @override
  String get noWorkoutStructureAvailable =>
      'Nessuna struttura dell\'allenamento disponibile.';

  @override
  String get aerobic => 'Aerobico';

  @override
  String get pushAgainToUpdateYour =>
      'Invia di nuovo per aggiornare il calendario dell\'orologio.';

  @override
  String workoutSentToLabel(Object label) {
    return 'Allenamento inviato a $label';
  }

  @override
  String get updating2 => 'Aggiornamento…';

  @override
  String pushToLabel(Object label) {
    return 'Invia a $label';
  }

  @override
  String shareExerciseListForLabel(Object label) {
    return 'Condividi elenco esercizi per $label';
  }

  @override
  String shareWorkoutForLabel(Object label) {
    return 'Condividi l\'allenamento per $label';
  }

  @override
  String get whyNothingIsAddedTo =>
      'Perché? Non viene aggiunto nulla per completarlo.';

  @override
  String get workout => 'Allenamento';

  @override
  String get recordedActivityLinkedToThis =>
      'Attività registrata collegata a questo allenamento';

  @override
  String get matchedToTheRecordedWorkout =>
      'Abbinato all\'inizio dell\'allenamento registrato';

  @override
  String get matchedByWorkoutNameSport =>
      'Abbinato per nome allenamento, sport e data';

  @override
  String get matchedBySportDateAnd => 'Abbinato per sport, data e durata';

  @override
  String planPlannedminutesMin(Object plannedMinutes) {
    return 'Piano $plannedMinutes min';
  }

  @override
  String get maxHr => 'FC max';

  @override
  String get trainingLoad2 => 'Carico di allenamento';

  @override
  String get active => 'Attivo';

  @override
  String get avgPace => 'Passo medio';

  @override
  String get avgSpeed => 'Velocità media';

  @override
  String get avgPower => 'Potenza media';

  @override
  String get elevation2 => 'Dislivello';

  @override
  String get altitude => 'Altitudine';

  @override
  String get explainMyHrvBeforeAnd =>
      'Spiega la mia HRV prima e dopo questo allenamento. Cosa è confrontabile, cosa no e cosa è ancora sconosciuto?';

  @override
  String get deleteActivity => 'Eliminare l\'attività?';

  @override
  String get removeThisActivityFromThe =>
      'Eliminare questa attività? Resta eliminata anche dopo una nuova sincronizzazione dei dispositivi. Puoi ripristinarla nelle Impostazioni, in Eliminate di recente.';

  @override
  String get howDidThisSessionGo =>
      'Com\'è andata questa sessione e cosa significa per i miei prossimi giorni?';

  @override
  String currentFixedFixed2(Object fixed, Object fixed2) {
    return 'Attuale $fixed, $fixed2';
  }

  @override
  String get setUpInTrainingSettings =>
      'Da configurare nelle impostazioni di allenamento';

  @override
  String get couldNotLoadHeatData =>
      'Impossibile caricare i dati sul caldo – tocca per i dettagli';

  @override
  String get loadingHeatHistory => 'Caricamento cronologia del caldo…';

  @override
  String get noHeatDataYet => 'Nessun dato sul caldo';

  @override
  String optimalLowHigh(Object low, Object high) {
    return 'Ottimale $low–$high';
  }

  @override
  String optimalLowHighTrimp(Object low, Object high) {
    return 'Ottimale: $low–$high TRIMP';
  }

  @override
  String get targetUnavailableSyncTrainingHistory =>
      'Obiettivo non disponibile – sincronizza la cronologia di allenamento';

  @override
  String get workoutQualifiedForHeatAccumulation =>
      'L\'allenamento ha contribuito all\'accumulo di caldo.';

  @override
  String get workoutDidNotAddHeat =>
      'L\'allenamento non ha aggiunto accumulo di caldo.';

  @override
  String get performanceTime => 'Prestazione / Tempo';

  @override
  String get performanceDistance => 'Prestazione / Distanza';

  @override
  String get noRecordedRoute => 'Nessun percorso registrato';

  @override
  String get zoomIn => 'Ingrandisci';

  @override
  String get zoomOut => 'Riduci';

  @override
  String get fitRoute => 'Adatta il percorso';

  @override
  String get fullscreenMap => 'Mappa a schermo intero';

  @override
  String get openstreetmapContributors2 => 'collaboratori di OpenStreetMap';

  @override
  String get appleIntelligenceIsUnavailableShowing =>
      'Apple Intelligence non è disponibile. Viene mostrato un riepilogo senza IA.';

  @override
  String get generateAiBriefing => 'Generare il briefing IA?';

  @override
  String get retryAiBriefing => 'Riprova il briefing IA';

  @override
  String get generateBriefing => 'Genera briefing';

  @override
  String discussThisBriefingWithMe(Object text) {
    return 'Discuti con me questo briefing e suggerisci la prossima azione migliore.\n\n$text';
  }

  @override
  String whyThisRecommendationWhichOf(Object text) {
    return 'Perché questo consiglio? Quali miei dati e quali lacune nei dati l\'hanno determinato, e cosa lo cambierebbe?\n\n$text';
  }

  @override
  String get avg2 => 'Media';

  @override
  String get peak2 => 'Picco';

  @override
  String get notEnoughContinuousReadingsFor =>
      'Letture continue insufficienti per una media.';

  @override
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  ) {
    return 'Copertura registrata: $inHours h $inMinutes min · media pesata nel tempo';
  }

  @override
  String get lying => 'Sdraiato';

  @override
  String get noHrvReadingsInThis => 'Nessuna lettura HRV in questo periodo';

  @override
  String get overnightHrvComesFromYour =>
      'L\'HRV notturna proviene dall\'orologio, le misurazioni puntuali dal Polar H10 (RMSSD). I metodi differiscono: confronta le tendenze, non i singoli valori.';

  @override
  String get noReadings => 'Nessuna lettura';

  @override
  String get whenDidTheWorkoutStart => 'Quando è iniziato l\'allenamento?';

  @override
  String get whenDidItEnd => 'Quando è finito?';

  @override
  String get last3Months => 'Ultimi 3 mesi';

  @override
  String get lastYear => 'Ultimo anno';

  @override
  String lastDaysDays(Object days) {
    return 'Ultimi $days giorni';
  }

  @override
  String nowOnCurrentTapA(Object current) {
    return 'Ora il $current. Tocca un giorno o trascina l\'allenamento su uno. I passaggi restano invariati.';
  }

  @override
  String get monthView => 'Vista mensile';

  @override
  String get syncing => 'Sincronizzazione';

  @override
  String get trendUnavailable => 'Tendenza non disponibile';

  @override
  String get stable => 'Stabile';

  @override
  String get increasing => 'In aumento';

  @override
  String get decreasing => 'In diminuzione';

  @override
  String get unclear => 'Poco chiaro';

  @override
  String get notComparable => 'Non confrontabile';

  @override
  String get waitingForAfter => 'In attesa del dopo';

  @override
  String get afterOnly => 'Solo dopo';

  @override
  String get waitingForTheActualWorkout =>
      'In attesa della fine effettiva dell\'allenamento.';

  @override
  String reminderAroundTolocal(Object toLocal) {
    return 'Promemoria verso le $toLocal';
  }

  @override
  String get reminderIsDueMeasureWhen =>
      'Il promemoria è in scadenza. Misura quando sei pronto.';

  @override
  String get thisReminderIsNoLonger =>
      'Questo promemoria non è più attuale. Apri l\'allenamento per vedere le misurazioni.';

  @override
  String beforeFixedMilliseconds(Object fixed) {
    return 'Prima $fixed millisecondi. ';
  }

  @override
  String afterFixedMilliseconds(Object fixed) {
    return 'Dopo $fixed millisecondi';
  }

  @override
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  ) {
    return 'Variazione di $deltaMs millisecondi, $deltaPercent per cento.';
  }

  @override
  String get noPreTrainingMeasurementRecorded =>
      'Nessuna misurazione pre-allenamento registrata.';

  @override
  String get notMeasuredYet => 'Non ancora misurato';

  @override
  String leftOutOfTheComparison(Object excludedTotal, Object c) {
    return 'Escluso dal confronto: $excludedTotal allenamenti ($c).';
  }

  @override
  String get notFromThisWorkout => 'Non da questo allenamento';

  @override
  String get useAsBefore => 'Usa come prima';

  @override
  String get useAsAfter => 'Usa come dopo';

  @override
  String get beforeNotMeasured => 'Prima · non misurato';

  @override
  String beforeTolocal(Object toLocal) {
    return 'Prima · $toLocal';
  }

  @override
  String workoutWorkouttext(Object workoutText) {
    return 'Allenamento · $workoutText';
  }

  @override
  String get afterNotMeasuredYet => 'Dopo · non ancora misurato';

  @override
  String afterTolocal(Object toLocal) {
    return 'Dopo · $toLocal';
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
    return 'I tuoi allenamenti simili ($eligible, $toLocal–$toLocal2): mediana $medianMs ms, metà centrale da $q1Ms a $q3Ms ms.';
  }

  @override
  String get howHardDidItFeel => 'Quanto è stato duro? (RPE)';

  @override
  String get loadMetric => 'Carico';

  @override
  String get clearAction => 'Cancella';

  @override
  String get routeFinish => 'Arrivo';

  @override
  String get month2 => 'MESE';

  @override
  String get week2 => 'SETTIMANA';

  @override
  String get quarter => 'TRIMESTRE';

  @override
  String get year => 'ANNO';

  @override
  String get easy3 => 'FACILE';

  @override
  String get mod => 'MOD.';

  @override
  String get hard => 'INTENSO';

  @override
  String get protocol => 'PROTOCOLLO';

  @override
  String get calculate => 'CALCOLA';

  @override
  String get warmUp => 'RISCALDAMENTO';

  @override
  String get coolDown => 'DEFATICAMENTO';

  @override
  String get ftpCycling => 'FTP ciclismo';

  @override
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg) {
    return 'FTP $ftpWatts W · $wattsPerKg W/kg';
  }

  @override
  String get thisWeekSoFar => 'QUESTA SETTIMANA · FINORA';

  @override
  String get duration2 => 'DURATA';

  @override
  String get distance2 => 'DISTANZA';

  @override
  String get sport2 => 'SPORT';

  @override
  String get repeatSets => 'SERIE RIPETUTE';

  @override
  String get aboutThisWorkout => 'INFORMAZIONI SU QUESTO ALLENAMENTO';

  @override
  String get workoutStructure => 'STRUTTURA DELL\'ALLENAMENTO';

  @override
  String get health2 => 'SALUTE';

  @override
  String get high2 => 'ALTO';

  @override
  String get elevated => 'ELEVATO';

  @override
  String get normal => 'NORMALE';

  @override
  String get tomorrow => 'DOMANI';

  @override
  String get skipped2 => 'SALTATO';

  @override
  String get weeklyPlan => 'PIANO SETTIMANALE';

  @override
  String get activityLog3 => 'REGISTRO ATTIVITÀ';

  @override
  String skippedTouppercase(Object toUpperCase) {
    return 'SALTATO · $toUpperCase';
  }

  @override
  String get primaryZone => 'ZONA PRINCIPALE';

  @override
  String get coachingCues => 'INDICAZIONI DEL COACH';

  @override
  String get targets => 'OBIETTIVI';

  @override
  String get adaptation => 'ADATTAMENTO';

  @override
  String get done2 => 'FATTO';

  @override
  String get notRecorded2 => 'NON REGISTRATO';

  @override
  String get planned => 'PIANIFICATO';

  @override
  String get extra => 'EXTRA';

  @override
  String get optimal2 => 'OTTIMALE';

  @override
  String get qualified => 'QUALIFICATO';

  @override
  String get temp => 'TEMP.';

  @override
  String get humidity2 => 'UMIDITÀ';

  @override
  String get pressure => 'PRESSIONE';

  @override
  String get wetBulb => 'BULBO UMIDO';

  @override
  String get paceMinKm => 'Passo (min/km)';

  @override
  String get speedKmH => 'Velocità (km/h)';

  @override
  String get elevationM => 'Dislivello (m)';

  @override
  String get powerW => 'POTENZA (W)';

  @override
  String get performanceTime2 => 'PRESTAZIONE / TEMPO';

  @override
  String get performanceDistance2 => 'PRESTAZIONE / DISTANZA';

  @override
  String get load2 => 'CARICO';

  @override
  String get day2 => 'GIORNO';

  @override
  String get allTime => 'SEMPRE';

  @override
  String get hrvAroundThisWorkout2 => 'HRV intorno a questo allenamento. ';

  @override
  String get lowReserve => 'RISERVA BASSA';

  @override
  String get goodReserve => 'BUONA RISERVA';

  @override
  String latestReadingAtTolocal(Object toLocal) {
    return 'Ultima lettura alle $toLocal';
  }

  @override
  String get weeklyAvg => 'MEDIA SETTIMANALE';

  @override
  String get monthlyAvg => 'MEDIA MENSILE';

  @override
  String get systolic2 => 'SISTOLICA';

  @override
  String get diastolic2 => 'DIASTOLICA';

  @override
  String get hourlyVariation => 'VARIAZIONE ORARIA';

  @override
  String get dailyVariation => 'VARIAZIONE GIORNALIERA';

  @override
  String get sys2 => 'SIS';

  @override
  String get dia => 'DIA';

  @override
  String get bluetoothDevices => 'DISPOSITIVI BLUETOOTH';

  @override
  String get accountsServices => 'ACCOUNT E SERVIZI';

  @override
  String get flowLoginOptional => 'LOGIN FLOW (FACOLTATIVO)';

  @override
  String get polarFlowLogin => 'LOGIN POLAR FLOW';

  @override
  String get raceGoal => 'OBIETTIVO DI GARA';

  @override
  String get experienceLevel => 'LIVELLO DI ESPERIENZA';

  @override
  String get weeklySchedule2 => 'PROGRAMMA SETTIMANALE';

  @override
  String get sessionsPerDay2 => 'SESSIONI AL GIORNO';

  @override
  String get aboutYou => 'SU DI TE';

  @override
  String get yourActivities2 => 'LE TUE ATTIVITÀ';

  @override
  String latestReadingAtTimestamp(Object timestamp) {
    return 'Ultima lettura alle $timestamp';
  }

  @override
  String get poorSleep => 'SONNO SCARSO';

  @override
  String get fairSleep => 'SONNO DISCRETO';

  @override
  String get goodSleep => 'SONNO BUONO';

  @override
  String get hoursOfSleep => 'ORE DI SONNO';

  @override
  String get sleepNeeded => 'SONNO NECESSARIO';

  @override
  String get deepSleep => 'SONNO PROFONDO';

  @override
  String get exercises2 => 'ESERCIZI';

  @override
  String get strengthSummary => 'RIEPILOGO FORZA';

  @override
  String get strengthDraft => 'FORZA · BOZZA';

  @override
  String get strengthFinishedWithGaps => 'FORZA · CONCLUSO CON LACUNE';

  @override
  String get strength2 => 'FORZA';

  @override
  String get wind => 'VENTO';

  @override
  String get sun2 => 'SOLE';

  @override
  String get cloud => 'NUVOLE';

  @override
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt) {
    return 'Dati: $source · Aggiornato $fetchedAt';
  }

  @override
  String get coros2 => 'COROS';

  @override
  String get rmssdMs => 'RMSSD · ms';

  @override
  String get sdnnMs => 'SDNN · ms';

  @override
  String get now2 => 'ORA';

  @override
  String get awake => 'SVEGLIO';

  @override
  String get light => 'LEGGERO';

  @override
  String get deep2 => 'PROFONDO';

  @override
  String get sqliteOrm => 'SQLite ORM';

  @override
  String get httpClients => 'Client HTTP';

  @override
  String get gpsLocation => 'Posizione GPS';

  @override
  String get hdlCholesterol => 'Colesterolo HDL';

  @override
  String get ldlCholesterol => 'Colesterolo LDL';

  @override
  String get raceName => 'NOME DELLA GARA';

  @override
  String get mtb => 'MTB';

  @override
  String get distanceKm => 'Distanza (km)';

  @override
  String get priority => 'PRIORITÀ';

  @override
  String get elevationGainM => 'Dislivello positivo (m)';

  @override
  String get targetTime => 'TEMPO OBIETTIVO';

  @override
  String get raceDate => 'DATA DELLA GARA';

  @override
  String get participation => 'PARTECIPAZIONE';

  @override
  String get whatIWantFromIt => 'COSA VOGLIO OTTENERE';

  @override
  String periodTimeline(Object period) {
    return '$period · ANDAMENTO';
  }

  @override
  String get tabPlan => 'PIANO';

  @override
  String get tabLoad => 'CARICO';

  @override
  String get tabCoach => 'COACH';

  @override
  String get hrDriftTestLt1 => 'TEST DI DERIVA FC – LT1';

  @override
  String get asSentByGarmin => 'COME INVIATO DA GARMIN';

  @override
  String get noData2 => 'NESSUN DATO';

  @override
  String get noTarget => 'NESSUN OBIETTIVO';

  @override
  String get noHeatLoad => 'NESSUN CARICO DI CALDO';

  @override
  String get hrBpm => 'FC (bpm)';

  @override
  String get aiBriefingUnavailableShowingA =>
      'Briefing IA non disponibile. Viene mostrato un riepilogo senza IA.';

  @override
  String get uvIndex2 => 'INDICE UV';

  @override
  String get aiBriefing => 'Briefing IA';

  @override
  String get uiFrameworkByGoogle => 'Framework UI di Google';

  @override
  String get unableToLoadData => 'Impossibile caricare i dati';

  @override
  String briefingSummary(Object recovery, Object sleep, Object load) {
    return 'Recupero $recovery / 100. Sonno $sleep / 100. Il carico di allenamento di oggi è $load TRIMP.';
  }

  @override
  String get morningBriefing => 'Briefing del mattino';

  @override
  String get lunchBriefing => 'Briefing di pranzo';

  @override
  String get afternoonBriefing => 'Briefing del pomeriggio';

  @override
  String get eveningBriefing => 'Briefing della sera';

  @override
  String get appleUnusableAnswer =>
      'Apple Intelligence non ha prodotto una risposta utilizzabile: ha ripetuto sé stessa o i tuoi dati. Riformula la domanda o scegli un altro provider IA nelle impostazioni.';

  @override
  String get appleCouldNotAnswer =>
      'Apple Intelligence non ha potuto rispondere. Riprova.';

  @override
  String get appleNotAvailableOnDevice =>
      'Apple Intelligence non è disponibile su questo dispositivo.';

  @override
  String get appleLanguageRejected =>
      'Apple Intelligence ha rifiutato la lingua della richiesta. Prova con una domanda breve in inglese. Controlla anche le impostazioni della lingua di iPhone e Siri.';

  @override
  String get appleRequestTooLarge =>
      'Apple Intelligence non è riuscita a elaborare questa richiesta. Prova con una domanda più breve.';

  @override
  String get messageTooLongForApple =>
      'Questo messaggio è troppo lungo per Apple Intelligence. Accorcialo e invialo di nuovo.';

  @override
  String get vo2maxRunning => 'VO₂max corsa';

  @override
  String get vo2maxCycling => 'VO₂max ciclismo';

  @override
  String get vo2maxPaceLabel => 'Passo VO₂max';

  @override
  String get lt1Threshold => 'Soglia LT1';

  @override
  String get lt2Threshold => 'Soglia LT2';

  @override
  String hoursPreviousWeek(Object value) {
    return '$value h la settimana scorsa';
  }

  @override
  String kmPreviousWeek(Object value) {
    return '$value km la settimana scorsa';
  }

  @override
  String get thirtyMinuteTimeTrial => 'Prova a tempo di 30 minuti';

  @override
  String thirtyMinTtDate(Object date) {
    return 'TT 30 min · $date';
  }

  @override
  String get yesterday2 => 'IERI';

  @override
  String get briefHeadGreen => 'Sei ben recuperato.';

  @override
  String get briefHeadYellow => 'Hai un po\' di affaticamento.';

  @override
  String get briefHeadRed => 'Sei chiaramente affaticato.';

  @override
  String briefMain(Object reasons) {
    return 'Motivi principali: $reasons.';
  }

  @override
  String get briefAllClear =>
      'Nessuno dei tuoi valori mostra segnali di allarme.';

  @override
  String get briefAdviceGreen => 'Allenati come previsto.';

  @override
  String get briefAdviceYellow =>
      'Mantieni il piano ma senza intensità aggiuntiva.';

  @override
  String get briefAdviceRed => 'Prima il recupero: giornata leggera o riposo.';

  @override
  String get briefReasonHrvLow => 'HRV del sonno bassa';

  @override
  String get briefReasonHrvHigh => 'HRV del sonno alta';

  @override
  String get briefReasonRhrUp => 'FC a riposo elevata';

  @override
  String get briefReasonRhrDown => 'FC a riposo bassa';

  @override
  String get briefReasonSleepShort => 'poco sonno';

  @override
  String get briefReasonSleepGood => 'fabbisogno di sonno coperto';

  @override
  String get briefReasonEnergyLow => 'poca energia';

  @override
  String get briefReasonEnergyHigh => 'buona energia';

  @override
  String get briefReasonStressHigh => 'stress elevato';

  @override
  String get briefReasonRespHigh => 'frequenza respiratoria elevata';

  @override
  String get briefReasonSpo2Low => 'ossigeno nel sangue basso';

  @override
  String get briefReasonSkinTempOff => 'temperatura cutanea insolita';

  @override
  String get briefReasonFormTired => 'affaticamento da allenamento accumulato';

  @override
  String get briefReasonFormVeryTired =>
      'affaticamento da allenamento molto alto';

  @override
  String get briefReasonFormFresh => 'fresco e riposato';

  @override
  String get briefTrainingHrvUp =>
      'La tua HRV è salita dopo l\'allenamento, un buon segno.';

  @override
  String get briefTrainingHrvDown =>
      'La tua HRV è scesa dopo l\'allenamento, un segno meno buono.';

  @override
  String get reminderNeedsNotifications =>
      'Il promemoria richiede le notifiche. Consentile per Fjelia nelle impostazioni di sistema, poi riattivalo.';

  @override
  String get whatDidYouHave => 'Cosa hai assunto?';

  @override
  String get intakeSomething => 'Ho assunto qualcosa';

  @override
  String get intakeNothing => 'Niente';

  @override
  String get totalIntake => 'Assunzione totale';

  @override
  String get carbsLabel => 'Carboidrati';

  @override
  String get fluidLabel => 'Liquidi';

  @override
  String get sodiumLabel => 'Sodio';

  @override
  String get caffeineLabel => 'Caffeina';

  @override
  String get detailsOptional => 'Dettagli (facoltativo)';

  @override
  String atMinute(Object minute) {
    return 'minuto $minute';
  }

  @override
  String get nothingAddedYet =>
      'Ancora nulla aggiunto. Aggiungi ciò che hai mangiato o bevuto, oppure scegli «Niente».';

  @override
  String get followFocusWeek => 'Su cosa dovrei concentrarmi questa settimana?';

  @override
  String get followRecoveryTrend => 'Come sta andando il mio recupero?';

  @override
  String get followLoadTooHigh => 'Il mio carico di allenamento è troppo alto?';

  @override
  String get followImproveSleep => 'Cosa migliorerebbe il mio sonno?';

  @override
  String get followIntervalsFeel => 'Come dovrebbero sentirsi gli intervalli?';

  @override
  String get followTiredToday => 'E se oggi mi sento stanco?';

  @override
  String get followEatBefore => 'Cosa dovrei mangiare prima?';

  @override
  String get followAdjustToday => 'Dovrei adattarlo oggi?';

  @override
  String get followNextDays => 'Cosa significa per i miei prossimi giorni?';

  @override
  String get followCompareSimilar => 'Come si confronta con sessioni simili?';

  @override
  String get followRecover => 'Cosa dovrei fare per recuperare?';

  @override
  String get followIntensityRight => 'L\'intensità era giusta?';

  @override
  String get statusPlanned => 'Pianificato';

  @override
  String get statusAdapted => 'Adattato';

  @override
  String get statusCompleted => 'Completato';

  @override
  String get statusRest => 'Riposo';

  @override
  String loadValue(Object value) {
    return 'Carico $value';
  }

  @override
  String get actIntensityEasy => 'È stata una sessione aerobica facile.';

  @override
  String get actIntensityModerate => 'È stata una sessione moderata.';

  @override
  String get actIntensityHard => 'È stata una sessione intensa.';

  @override
  String get actIntensityUnknown => 'La sessione è registrata.';

  @override
  String get actLenLonger => 'È stata più lunga delle tue sessioni simili.';

  @override
  String get actLenShorter => 'È stata più breve delle tue sessioni simili.';

  @override
  String get actLoadHigher => 'Il carico è stato più alto del solito.';

  @override
  String get actLoadLower => 'Il carico è stato più basso del solito.';

  @override
  String get actLoadSame => 'Il carico è stato più o meno quello abituale.';

  @override
  String get actHrLower =>
      'La tua FC era più bassa del solito, è sembrato più facile.';

  @override
  String get actHrHigher =>
      'La tua FC era più alta del solito, è sembrato più duro.';

  @override
  String get actAdviceUnknown =>
      'Pianifica i prossimi giorni in base a come ti senti.';

  @override
  String briefOutlookRest(Object days) {
    return 'Con circa $days giorni leggeri la tua forma torna nell\'intervallo ottimale.';
  }

  @override
  String get briefOutlookLongRest =>
      'La tua forma ha bisogno di più di qualche giorno leggero per recuperare.';

  @override
  String get briefOutlookPlanTired =>
      'Seguendo il piano la tua forma resta bassa nei prossimi giorni.';

  @override
  String get localQwen => 'Qwen3.5 · locale';

  @override
  String get localModelDescription =>
      'Qwen3.5 facoltativo, MLX a 4 bit. Scaricalo una volta, poi usa chat e riepiloghi su questo dispositivo senza chiave API. I tuoi dati sanitari restano su questo dispositivo.';

  @override
  String localModelSizeMb(Object megabytes) {
    return 'Download di $megabytes MB · durante l\'uso serve memoria aggiuntiva.';
  }

  @override
  String get localModelDownload => 'Scarica modello';

  @override
  String get localModelResumeDownload => 'Riprendi download';

  @override
  String localModelDownloading(Object downloaded, Object total) {
    return '$downloaded / $total MB';
  }

  @override
  String get localModelInstalled => 'Scaricato · disponibile offline';

  @override
  String get localModelRemove => 'Elimina modello';

  @override
  String get localModelUnsupported =>
      'Questo modello MLX richiede un iPhone con iOS 17 o successivo e un chip A14 o più recente. I dispositivi precedenti non sono supportati.';

  @override
  String get localModelMemoryUnsupported =>
      'Questo dispositivo non ha memoria sufficiente per eseguire il modello locale.';

  @override
  String get localModelDownloadFailed =>
      'Download non riuscito. Riprova; i file completi vengono conservati.';

  @override
  String get localModelDownloadFirst =>
      'Scarica prima Qwen in Impostazioni → IA e altro.';

  @override
  String get localModelContextTooLong =>
      'Questa conversazione è troppo lunga per il modello locale. Inizia una nuova chat o accorcia la domanda.';

  @override
  String get localModelBusy =>
      'Il modello locale sta rispondendo a un\'altra richiesta. Riprova tra poco.';

  @override
  String get localModelInterrupted =>
      'La generazione locale è stata interrotta. Tieni Fjelia aperta e riprova.';

  @override
  String get localModelCouldNotAnswer =>
      'Il modello locale non ha potuto rispondere. Controlla il modello in Impostazioni → IA e altro e riprova.';

  @override
  String get localModelBriefingUnavailable =>
      'Riepilogo IA locale non disponibile. Viene mostrato il riepilogo dell\'app.';

  @override
  String get localModelInfo => 'Dettagli del modello e licenza';

  @override
  String localModelRamGb(int gigabytes) {
    return 'Richiede almeno $gigabytes GB di RAM.';
  }

  @override
  String get localModelIPhone18 =>
      'Il modello 4B è disponibile su iPhone 18 e successivi.';

  @override
  String briefPlannedTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Per oggi sono previsti $count allenamenti.',
      one: 'Per oggi è previsto 1 allenamento.',
    );
    return '$_temp0';
  }

  @override
  String get coachDataFallback =>
      'La risposta del modello contraddice i dati. Ecco il riepilogo di Fjelia:';

  @override
  String get coachSevenDayAverage => 'media di 7 giorni';

  @override
  String coachSleepNeedAndShortfall(String need, String shortfall) {
    return 'Fabbisogno di sonno: $need h; deficit: $shortfall h.';
  }

  @override
  String coachCurrentForm(String value) {
    return 'Forma attuale (TSB): $value punti.';
  }

  @override
  String get aiOnboardingStep => 'Passaggio 2 di 3';

  @override
  String get aiOnboardingTitle => 'Il tuo coach.\nA modo tuo.';

  @override
  String get aiOnboardingSubtitle =>
      'Trasforma i tuoi dati sulla salute in consigli per allenarti e recuperare meglio.';

  @override
  String get aiOnboardingChoose => 'SCEGLI IL TUO COACH IA';

  @override
  String get aiOnboardingFreeDetail => 'Gratis · Nessun account IA richiesto';

  @override
  String get aiOnboardingFreeBody => 'IA nel cloud per allenamento e recupero.';

  @override
  String get aiOnboardingRecommended => 'Consigliato';

  @override
  String get aiOnboardingOnDevice => 'Sul tuo dispositivo';

  @override
  String get aiOnboardingLocalBody =>
      'Le tue richieste IA restano su questo dispositivo.';

  @override
  String get aiOnboardingUnavailable => 'Al momento non disponibile';

  @override
  String get aiOnboardingMore => 'Altri modelli IA';

  @override
  String get aiOnboardingMoreBody => 'Qwen locale o il tuo provider cloud';

  @override
  String get aiOnboardingConsent =>
      'Richieste cloud solo dopo la tua conferma.';

  @override
  String get aiOnboardingError =>
      'Impossibile salvare o caricare la scelta dell’IA. Riprova.';

  @override
  String get aiOnboardingWithout => 'Continua senza IA';

  @override
  String get aiOnboardingConfigure => 'Configura il modello';

  @override
  String aiOnboardingContinue(String provider) {
    return 'Continua con $provider';
  }

  @override
  String get aiOnboardingChangeLater =>
      'Puoi cambiare scelta in qualsiasi momento nelle impostazioni.';

  @override
  String get creditsAndLicenses => 'Licenze e ringraziamenti';

  @override
  String get bioAgeActivity => 'Attività';

  @override
  String get bioAgeActivityBasis => 'Dati di attività · ultimi 7 giorni';

  @override
  String bioAgeActivityReported(String minutes) {
    return '$minutes minuti moderati riportati';
  }

  @override
  String bioAgeActivitySteps(String minutes) {
    return '≈ $minutes minuti di cammino stimati dai passi';
  }

  @override
  String bioAgeActivityCoverage(int days) {
    return 'Dati per $days giorni su 7';
  }

  @override
  String get bioAgeActivityEstimateNotice =>
      'Ipotesi: 100 passi ≈ 1 minuto di cammino. Il totale giornaliero dei passi non indica ritmo o intensità. I minuti riportati hanno la precedenza ogni giorno; i passi dello stesso giorno non vengono conteggiati di nuovo.';

  @override
  String get bioAgeActivityIncomplete =>
      'Mancano dati di attività. Il contributo dell’attività in anni viene calcolato solo quando sono disponibili dati per tutti i 7 giorni.';

  @override
  String get bioAgeActivityEstimatedLabel =>
      'L’attività include un tempo di cammino stimato.';

  @override
  String get bioAgeActivityUnknownLabel => 'Dati di attività incompleti';

  @override
  String get mixTitle => 'Prepara una bevanda';

  @override
  String get mixMyBottle => 'Prepara la mia borraccia';

  @override
  String get mixRecipes => 'Ricette';

  @override
  String get mixIngredients => 'Ingredienti';

  @override
  String get mixAddIngredient => 'Aggiungi ingrediente';

  @override
  String get mixBottle => 'Borraccia';

  @override
  String get mixFilledWithWater => 'riempita con acqua';

  @override
  String mixPerBottle(String ml) {
    return 'per borraccia da $ml ml';
  }

  @override
  String get mixStrength => 'Concentrazione';

  @override
  String get mixRatio => 'Glucosio : fruttosio';

  @override
  String get mixGlucose => 'Glucosio';

  @override
  String get mixFructose => 'Fruttosio';

  @override
  String get mixGlucoseOnly => 'Solo glucosio';

  @override
  String get mixGentle => 'Leggera per lo stomaco – fino all\'8 %.';

  @override
  String get mixStrong => 'Concentrata – solo con un intestino allenato.';

  @override
  String get mixTooStrong => 'Molto concentrata – aggiungi acqua.';

  @override
  String get mixNoFructoseHint =>
      'Solo glucosio: oltre circa 60 g di carboidrati all\'ora aggiungi fruttosio (zucchero) – circa 2:1 viene assorbito meglio.';

  @override
  String get mixFructoseHeavyHint =>
      'Più fruttosio che glucosio può disturbare lo stomaco – aggiungi maltodestrina o destrosio.';

  @override
  String get mixSpoonNote =>
      'I cucchiai sono diversi. Pesa il tuo cucchiaio una volta o usa i grammi per valori esatti.';

  @override
  String get mixTooMuchLiquid =>
      'Succo e cola da soli superano già la borraccia – aumenta la dimensione della borraccia.';

  @override
  String get mixAddToIntake => 'Aggiungi all\'assunzione';

  @override
  String get mixUseAsBottle => 'Usa come mia borraccia';

  @override
  String get mixDefaultName => 'Mix di bevanda';

  @override
  String get mixEmpty => 'Scegli una ricetta o aggiungi un ingrediente.';

  @override
  String get mixRemove => 'Rimuovi';

  @override
  String mixRowGrams(String grams) {
    return '≈ $grams g';
  }

  @override
  String mixBottleSaved(String carbs, String ml) {
    return 'Salvata come tua borraccia: $carbs g di carboidrati per $ml ml.';
  }

  @override
  String get mixMaltodextrin => 'Maltodestrina';

  @override
  String get mixSugar => 'Zucchero';

  @override
  String get mixDextrose => 'Destrosio';

  @override
  String get mixHoney => 'Miele';

  @override
  String get mixSalt => 'Sale';

  @override
  String get mixOrangeJuice => 'Succo d\'arancia';

  @override
  String get mixAppleJuice => 'Succo di mela';

  @override
  String get mixCola => 'Cola';

  @override
  String get unitTspLevel => 'cucchiaino raso';

  @override
  String get unitTspHeaped => 'cucchiaino colmo';

  @override
  String get unitTbspLevel => 'cucchiaio raso';

  @override
  String get unitTbspHeaped => 'cucchiaio colmo';

  @override
  String get unitPinch => 'pizzico';

  @override
  String get unitTsp => 'cucchiaino';

  @override
  String get unitTbsp => 'cucchiaio';

  @override
  String get mixRecipeMaltoSugar => 'Malto + zucchero 2:1';

  @override
  String get mixRecipeJuice => 'Succo diluito';

  @override
  String get mixRecipeJuicePlus => 'Succo diluito + malto';

  @override
  String get mixRecipeCola => 'Cola diluita';

  @override
  String get missedWorkoutTitle => 'Ancora in programma oggi';

  @override
  String missedWorkoutBody(String workouts) {
    return '$workouts. Ancora oggi, spostarlo o saltarlo?';
  }

  @override
  String get stillToday => 'Ancora oggi';

  @override
  String get moveWorkoutAction => 'Sposta…';

  @override
  String get missedWorkoutChannel => 'Allenamenti mancati';

  @override
  String get missedWorkoutChannelDescription =>
      'Promemoria serale per gli allenamenti previsti ancora da fare';

  @override
  String get missedWorkoutReminder => 'Promemoria allenamento mancato';

  @override
  String get missedWorkoutReminderSubtitle =>
      'La sera, se un allenamento previsto è ancora da fare';

  @override
  String get moveWithinDays => 'Sposta entro';

  @override
  String daysN(int count) {
    return '$count giorni';
  }

  @override
  String get notificationsAreOff =>
      'Le notifiche di Fjelia sono disattivate. Consentile per ricevere questo promemoria.';

  @override
  String get allowNotifications => 'Consenti notifiche';

  @override
  String get openWorkoutToday => 'Ancora da fare oggi';

  @override
  String get checkingForWorkout => 'Cerco il tuo allenamento…';

  @override
  String get alreadyDone => 'Già fatto ✓';

  @override
  String get alreadyDoneBody =>
      'Il tuo allenamento è stato registrato. Oggi non resta nulla da fare.';

  @override
  String get dropIt => 'Saltalo';

  @override
  String askCoachSends(String provider) {
    return 'Invia il riepilogo dei tuoi allenamenti a $provider.';
  }

  @override
  String get coachThinking => 'Il coach sta pensando…';

  @override
  String get coachCouldNotAnswer =>
      'Il coach non ha potuto rispondere. Il suggerimento sopra resta valido.';

  @override
  String get whySkip => 'Perché saltarlo?';

  @override
  String get skipReasonIllness => 'Malattia';

  @override
  String get skipReasonInjury => 'Infortunio o dolore';

  @override
  String get skipReasonFatigue => 'Stanchezza';

  @override
  String get skipReasonNoTime => 'Niente tempo';

  @override
  String get skipReasonTravel => 'Viaggio';

  @override
  String get skipReasonConditions => 'Condizioni';

  @override
  String get skipReasonMyChoice => 'Una mia scelta';

  @override
  String get onbReminderTitle => 'Resta in carreggiata';

  @override
  String get onbReminderSubtitle =>
      'Se la sera un allenamento previsto è ancora da fare, Fjelia te lo ricorda una volta, così puoi ancora farlo, spostarlo o saltarlo.';

  @override
  String get onbExampleWorkout => 'Corsa facile (45 min)';

  @override
  String get onbReminderToggle => 'Promemoria serale';

  @override
  String get onbReminderTime => 'Ricordamelo alle';

  @override
  String get onbReminderFootnote =>
      'Puoi cambiarlo in qualsiasi momento in Impostazioni → Allenamento.';

  @override
  String get nowLabel => 'ora';

  @override
  String get coachSuggests => 'Il coach propone';

  @override
  String get suggestionLabel => 'Suggerimento';

  @override
  String get askCoachShort => 'Chiedi al coach';

  @override
  String get otherDay => 'Altro giorno';

  @override
  String get skipEllipsis => 'Salta…';

  @override
  String get pickADay => 'Tocca un giorno qui sopra';

  @override
  String get dayDoesNotFit => 'Quel giorno non si adatta al piano.';

  @override
  String get planUpdated => 'Piano aggiornato';

  @override
  String get missedTodayTag => 'saltato oggi';

  @override
  String summaryMove(String day) {
    return 'Spostalo a $day.';
  }

  @override
  String summaryMoveIndoor(String day) {
    return 'Spostalo a $day, al chiuso: è prevista pioggia.';
  }

  @override
  String get summaryDropEasy =>
      'Saltalo: una seduta leggera non vale la pena di recuperarla.';

  @override
  String summaryDropNoDay(int days) {
    return 'Saltalo: nessun giorno adatto nei prossimi $days giorni.';
  }

  @override
  String get tagIndoor => 'al chiuso';

  @override
  String get tagEasier => 'più facile';

  @override
  String get tagRecovery => 'recupero';

  @override
  String summaryMoveEasier(String day) {
    return 'Spostalo a $day, un po’ più facile: è vicino a un giorno duro.';
  }

  @override
  String get briefRestDayToday => 'Oggi è un giorno di riposo previsto.';

  @override
  String get restDayPlannedNote => 'Il recupero fa parte del tuo piano.';

  @override
  String get restDayTitle => 'Giorno di riposo';

  @override
  String get importActivityFile => 'Importa file attività';

  @override
  String get activityFileImportHint =>
      'File FIT, GPX o TCX (anche in ZIP, come li esporta Garmin Connect) da un ciclocomputer, Zwift, Strava o un’altra app. Puoi anche condividere un file con Fjelia dall’app File o dal menu Condividi.';

  @override
  String get chooseActivityFiles => 'Scegli file';

  @override
  String get chooseOtherFiles => 'Scegli altri file';

  @override
  String get activityFileUnreadable => 'File attività non leggibile';

  @override
  String get activityFileAlreadyImported => 'Già importato';

  @override
  String activityFileAlreadyFrom(String source) {
    return 'Già in Fjelia da $source';
  }

  @override
  String importActivities(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importa $count attività',
      one: 'Importa $count attività',
    );
    return '$_temp0';
  }

  @override
  String activitiesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attività importate.',
      one: '$count attività importata.',
    );
    return '$_temp0';
  }

  @override
  String get activityFileSource => 'File';

  @override
  String get dfaAlpha1Title => 'Soglia aerobica (DFA α1)';

  @override
  String get dfaHrvt1 => 'Soglia aerobica (HRVT1)';

  @override
  String get dfaHrvt2 => 'Soglia anaerobica (HRVT2)';

  @override
  String dfaEasyShare(String percent) {
    return '$percent % della sessione sotto la tua soglia aerobica (α1 ≥ 0,75).';
  }

  @override
  String get dfaNoThreshold =>
      'La sessione non ha superato chiaramente una soglia. Un test incrementale, o una sessione che sale da facile a dura, fornisce una stima.';

  @override
  String dfaBeats(int beats, String artifacts) {
    return '$beats battiti · $artifacts % di artefatti';
  }

  @override
  String get dfaArtifactsHigh =>
      'Molti artefatti: controlla che la fascia cardio sia ben stretta e gli elettrodi umidi.';

  @override
  String get dfaExplainer =>
      'Dai dati battito per battito di una fascia cardio. α1 vicino a 1 è facile, 0,75 indica la soglia aerobica, 0,5 quella anaerobica. Una stima, non un test di laboratorio.';

  @override
  String get thresholdOrderNote =>
      'Fjelia confronta tutte le fonti. Propone prima i test dell’app, poi il tuo orologio, poi DFA α1 su più sessioni, poi il profilo Polar e le formule. Nulla cambia finché non lo applichi.';

  @override
  String thresholdInUse(String value) {
    return 'In uso: $value';
  }

  @override
  String thresholdProposal(String value, String source) {
    return 'Proposta: $value da $source';
  }

  @override
  String get keepCurrent => 'Mantieni';

  @override
  String get lt2Cycling => 'LT2 · Ciclismo';

  @override
  String get thresholdSourceTt => 'Cronometro di 30 minuti';

  @override
  String get thresholdSourceDrift => 'Test di deriva della FC';

  @override
  String thresholdSourceDfa(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DFA α1, $count sessioni',
      one: 'DFA α1, $count sessione',
    );
    return '$_temp0';
  }

  @override
  String get thresholdSourceEftp => 'eFTP dalle uscite in bici';

  @override
  String get thresholdSourcePolarProfile => 'Profilo Polar';

  @override
  String get thresholdFormulaLt2 => 'LT2 − 30 bpm';

  @override
  String get thresholdFormulaMaxHr => '77 % della FC max';

  @override
  String get thresholdStale => 'più vecchio di 6 mesi';

  @override
  String get thresholdsCoachLocked =>
      'Le tue soglie sono gestite dal tuo coach, quindi non puoi modificarle qui.';

  @override
  String get mediaTitle => 'Foto e video';

  @override
  String get mediaAdd => 'Aggiungi';

  @override
  String get mediaFromLibrary => 'Scegli dalla libreria';

  @override
  String get mediaTakePhoto => 'Scatta foto';

  @override
  String get mediaRecordVideo => 'Registra video';

  @override
  String mediaAdding(int done, int total) {
    return 'Aggiunta di $done di $total…';
  }

  @override
  String get mediaMoveEarlier => 'Sposta prima';

  @override
  String get mediaMoveLater => 'Sposta dopo';

  @override
  String get mediaDeleteTitle => 'Eliminare da Fjelia?';

  @override
  String get mediaDeleteMessage =>
      'La foto o il video viene rimosso da Fjelia. L’originale nella tua libreria resta.';

  @override
  String get mediaAddFailed => 'Alcuni file non sono stati aggiunti.';

  @override
  String get mediaHint =>
      'Tocca per vedere, tieni premuto per spostare o eliminare.';

  @override
  String get backupVideosTitle => 'Includere i video?';

  @override
  String backupVideosMessage(String size) {
    return 'I tuoi video occupano $size. Senza di essi il backup è molto più piccolo; le foto sono sempre incluse.';
  }

  @override
  String get backupWithVideos => 'Con i video';

  @override
  String get backupWithoutVideos => 'Senza video';

  @override
  String get mediaShareCard => 'Condividi come scheda';

  @override
  String get mediaShareCardHint =>
      'Trascina il riquadro o il percorso per spostarli. Pizzica e trascina la foto per inquadrarla; doppio tocco per ripristinarla.';

  @override
  String get shareStyleGlass => 'Vetro';

  @override
  String get shareStylePoster => 'Poster';

  @override
  String get shareStyleMinimal => 'Minimal';

  @override
  String get shareStyleNeon => 'Neon';

  @override
  String get shareStyleSticker => 'Sticker';

  @override
  String get shareStyleReceipt => 'Scontrino';

  @override
  String get shareStyleKpop => 'K-pop';

  @override
  String get shareStylePixel => 'Pixel';

  @override
  String get shareStyleRobot => 'Robot';

  @override
  String get shareStyleScifi => 'Fantascienza';

  @override
  String get shareStyleCard => 'Carta collezionabile';

  @override
  String get shareStyleComic => 'Fumetto';

  @override
  String get shareStyleOutdoor => 'Outdoor';

  @override
  String get shareStyleHolo => 'Carta olografica';

  @override
  String get shareStyleHoloFull => 'Carta full art';

  @override
  String nowcastRainSoon(int minutes) {
    return 'Pioggia tra circa $minutes min';
  }

  @override
  String nowcastRainingStops(int minutes) {
    return 'Piove · asciutto tra circa $minutes min';
  }

  @override
  String nowcastRainingOn(int minutes) {
    return 'Piove, ancora per almeno $minutes min';
  }

  @override
  String nowcastDry(int minutes) {
    return 'Asciutto per i prossimi $minutes min';
  }

  @override
  String get sunAndMoon => 'Sole e luna';

  @override
  String get moonNew => 'Luna nuova';

  @override
  String get moonWaxingCrescent => 'Luna crescente';

  @override
  String get moonFirstQuarter => 'Primo quarto';

  @override
  String get moonWaxingGibbous => 'Gibbosa crescente';

  @override
  String get moonFull => 'Luna piena';

  @override
  String get moonWaningGibbous => 'Gibbosa calante';

  @override
  String get moonLastQuarter => 'Ultimo quarto';

  @override
  String get moonWaningCrescent => 'Luna calante';

  @override
  String moonLit(int percent) {
    return '$percent % illuminata';
  }

  @override
  String daylightLength(int hours, int minutes) {
    return '$hours h $minutes min di luce';
  }

  @override
  String h10Battery(int level) {
    return 'Batteria $level %';
  }

  @override
  String get h10BatteryUnknown => 'Batteria non ancora letta';

  @override
  String h10BatteryChecked(String date) {
    return 'Controllata $date';
  }

  @override
  String get h10BatteryLowHint => 'Bassa: sostituisci presto la pila CR2025.';

  @override
  String get h10BatteryCheck => 'Controlla batteria';

  @override
  String get h10BatteryUnreachable =>
      'L’H10 non ha risposto. Indossalo (o inumidisci i contatti) e riprova.';

  @override
  String get shareRaceCalendar => 'Condividi calendario gare';

  @override
  String get raceSeasonTitle => 'La mia stagione di gare';

  @override
  String get raceShareStylePoster => 'Poster';

  @override
  String get raceShareStyleTickets => 'Biglietti';

  @override
  String get raceShareStyleTimeline => 'Timeline neon';

  @override
  String get raceShareStyleMagazine => 'Rivista';

  @override
  String get raceShareShowTarget => 'Mostra tempi obiettivo';

  @override
  String get bpOptimal => 'OTTIMALE';

  @override
  String get bpHighNormal => 'NORMALE-ALTA';

  @override
  String get bpLow => 'BASSA';

  @override
  String get bpLowHint => 'Pressione bassa: conta solo se hai capogiri.';

  @override
  String get waistCircumference => 'Circonferenza vita';

  @override
  String get hipOptional => 'Fianchi (facoltativo)';

  @override
  String get waistToHeightRatio => 'Rapporto vita-altezza';

  @override
  String get waistToHipRatio => 'Rapporto vita-fianchi';

  @override
  String get waistRiskLow => 'Molto magro';

  @override
  String get waistRiskHealthy => 'Sano';

  @override
  String get waistRiskIncreased => 'Rischio aumentato';

  @override
  String get waistRiskHigh => 'Rischio elevato';

  @override
  String get waistHowToMeasure =>
      'Misura al mattino, in piedi, dopo aver espirato: la vita a metà tra l’ultima costola e la cresta iliaca, i fianchi nel punto più largo.';

  @override
  String get waistNeedsHeight =>
      'Aggiungi la tua altezza in Impostazioni → Profilo.';

  @override
  String get waistNeedsHip => 'Misura una volta i fianchi per il WHR.';

  @override
  String get waistSyncsProfile =>
      'La misura più recente è anche la tua vita nelle impostazioni.';

  @override
  String get waistChange30d => '30 giorni';

  @override
  String get waistChange90d => '90 giorni';

  @override
  String get waistChange1y => '1 anno';

  @override
  String get waistDeleteText => 'Elimina la misura della vita selezionata.';

  @override
  String waistAndHip(String waist, String hip) {
    return '$waist cm · fianchi $hip cm';
  }

  @override
  String hipValue(String hip) {
    return 'Fianchi $hip cm';
  }

  @override
  String get whtrTargetHint => 'Tieni la vita sotto la metà della tua altezza.';

  @override
  String get noWaistYet => 'Nessuna circonferenza vita misurata.';

  @override
  String get enterValidWaist => 'Inserisci vita e fianchi tra 20 e 300 cm.';

  @override
  String get waistFromProfile => 'Dal tuo profilo, senza data';

  @override
  String get phaseBase => 'BASE';

  @override
  String get phaseBuild => 'SVILUPPO';

  @override
  String get phasePeak => 'PICCO';

  @override
  String get phaseTaper => 'SCARICO';

  @override
  String get phaseRecovery => 'RECUPERO';

  @override
  String get phaseRace => 'GARA';

  @override
  String get sessionTypeKey => 'CHIAVE';

  @override
  String get sessionTypeLong => 'LUNGO';

  @override
  String get sessionTypeRecovery => 'RECUPERO';

  @override
  String get sessionTypeAssessment => 'TEST';

  @override
  String get sessionTypeEndurance => 'RESISTENZA';

  @override
  String get sessionTypeStrength => 'FORZA';

  @override
  String get sessionTypeYoga => 'YOGA';

  @override
  String get sessionStatusCompleted => 'COMPLETATO';

  @override
  String get sessionStatusAdapted => 'ADATTATO';

  @override
  String get stepWarmUp => 'Riscaldamento';

  @override
  String get stepCoolDown => 'Defaticamento';

  @override
  String get stepRecovery => 'Recupero';

  @override
  String get stepRest => 'Riposo';

  @override
  String get stepInterval => 'Intervallo';

  @override
  String get stepWorkout => 'Allenamento';

  @override
  String stepRepeat(int n) {
    return '$n× ripeti';
  }

  @override
  String get stepOpenEnded => 'Senza limite';

  @override
  String stepSeconds(int n) {
    return '$n s';
  }

  @override
  String get objectiveOptionalVariety =>
      'Varietà facoltativa scelta nelle impostazioni';

  @override
  String get objectiveStrengthSupport => 'Forza a supporto del tuo allenamento';

  @override
  String objectiveIntervals(String goal) {
    return 'Intervalli per $goal';
  }

  @override
  String objectiveSteady(String sport, String goal) {
    return '$sport: seduta di qualità costante per $goal';
  }

  @override
  String objectiveEasyRecovery(String sport, String goal) {
    return '$sport facile: recupero intorno a $goal';
  }

  @override
  String objectiveEasyEndurance(String sport, String goal) {
    return '$sport: resistenza facile per $goal';
  }

  @override
  String objectiveLong(String sport, String goal) {
    return '$sport: seduta lunga per $goal';
  }

  @override
  String unmetWeekMinutes(int minutes, String sport, String goal) {
    return 'La settimana ha $minutes min, troppo pochi per una seduta lunga ($sport) per $goal.';
  }

  @override
  String unmetWeekHours(String hours, String what) {
    return 'La settimana ha $hours h, troppo poche per: $what.';
  }

  @override
  String unmetTrainingDays(String what) {
    return 'Non ci sono abbastanza giorni di allenamento per: $what.';
  }

  @override
  String get altMoveOneEvent => 'Spostare uno degli eventi';

  @override
  String get altMarkOneCancelled => 'Segnarne uno come annullato';

  @override
  String altMakePriorityB(String goal) {
    return 'Mettere $goal a priorità B';
  }

  @override
  String altSkipGoal(String goal) {
    return 'Saltare $goal';
  }

  @override
  String altTreatAsTraining(String goal) {
    return 'Usare $goal come gara di allenamento';
  }

  @override
  String altControlledEffort(String goal) {
    return 'Affrontare $goal con uno sforzo controllato';
  }

  @override
  String conflictSameDay(String a, String b) {
    return '$a e $b sono nello stesso giorno. Se ne può correre solo una.';
  }

  @override
  String conflictBothPriorityA(String a, String b, int gap, int more) {
    return '$a e $b sono entrambi a priorità A, a $gap giorni di distanza. Il recupero dopo il primo e la rifinitura per il secondo richiedono $more giorni in più.';
  }

  @override
  String conflictFlexibleOverlap(
    String a,
    String b,
    int gap,
    int overlap,
    String skip,
  ) {
    return '$a e $b sono a $gap giorni di distanza e si sovrappongono di $overlap giorni. $skip è segnato come flessibile: rinunciarvi libererebbe le settimane prima dell’altro evento.';
  }

  @override
  String conflictRecoveryOverlap(String a, String b, int gap, int overlap) {
    return '$a e $b sono a $gap giorni di distanza: il recupero dopo il primo si sovrappone di $overlap giorni alla rifinitura per il secondo. La preparazione a priorità minore viene limitata per proteggere l’altra.';
  }

  @override
  String conflictTightSpacing(String a, String b, int gap, int spare) {
    return '$a e $b sono a $gap giorni di distanza. Recupero e rifinitura ci stanno con $spare giorni di margine: qualsiasi intoppo non lascia spazio.';
  }

  @override
  String seasonShortened(int n, int of) {
    return 'In $n settimane su $of il tempo settimanale non basta per tutte le sedute lunghe di ogni obiettivo, quindi vengono accorciate insieme.';
  }

  @override
  String seasonAlternating(int n) {
    return 'In $n settimane non ci stanno tutte le sedute lunghe; gli sport si alternano.';
  }

  @override
  String seasonLongAway(int n) {
    return 'In $n settimane una seduta lunga di oltre due ore e mezza non cade nel suo giorno abituale, a causa dei giorni di riposo e delle altre sedute.';
  }

  @override
  String seasonMovedOntoEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n sedute che hai spostato cadono in un giorno di gara o nel giorno di riposo precedente. Il piano le lascia dove le hai messe.',
      one: '1 seduta che hai spostato cade in un giorno di gara o nel giorno di riposo precedente. Il piano la lascia dove l’hai messa.',
    );
    return '$_temp0';
  }

  @override
  String seasonNoRoom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n sedute sono state tolte perché gli allenamenti scelti duravano più del tempo rimasto nella settimana.',
      one: '1 seduta è stata tolta perché l’allenamento scelto durava più del tempo rimasto nella settimana.',
    );
    return '$_temp0';
  }

  @override
  String seasonMovedHardNearEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n sedute intense che hai spostato cadono nei giorni facili dopo un evento. Il piano le lascia dove le hai messe.',
      one: '1 seduta intensa che hai spostato cade nei giorni facili dopo un evento. Il piano la lascia dove l’hai messa.',
    );
    return '$_temp0';
  }

  @override
  String get seasonEventWeeks =>
      'Nelle settimane di gara l’evento conta come allenamento, quindi il resto della settimana è più leggero.';

  @override
  String seasonUnmet(int n, String detail) {
    return 'In $n settimane i giorni di allenamento non contengono tutte le sedute protette: $detail';
  }

  @override
  String seasonNoHistory(String sport, String priority) {
    return 'Nella tua cronologia non c’è allenamento recente ($sport), quindi il piano per l’obiettivo $priority è provvisorio.';
  }

  @override
  String get zoneRecovery => 'Recupero';

  @override
  String workoutSentKeptInFjelia(String provider, String items) {
    return 'Inviato a $provider. Solo in Fjelia: $items.';
  }

  @override
  String paceGuideRange(String low, String high) {
    return 'Riferimento di passo da $low a $high';
  }

  @override
  String get paceGuideFromGoal => ', stimato dal tuo obiettivo';

  @override
  String paceGuideGoalFlat(String pace) {
    return ' · passo obiettivo in piano $pace';
  }

  @override
  String get paceGuideHeartRateDecides => 'Decide la frequenza cardiaca.';

  @override
  String get moveKeyRestDay => 'giorno di riposo';

  @override
  String get moveKeyEvent => 'evento';

  @override
  String get moveKeyEasyOnly => 'solo facile';

  @override
  String get moveKeyHasSession => 'ha una seduta';

  @override
  String get calendarCompleted => 'Completato';

  @override
  String get calendarPlanned => 'Pianificato';

  @override
  String get recentlyDeleted => 'Eliminate di recente';

  @override
  String get recentlyDeletedExplain =>
      'Le attività eliminate restano eliminate, anche quando i dispositivi si sincronizzano di nuovo. Ripristinane una per recuperarla; la sua fonte invia di nuovo percorso e curve, se li ha ancora.';

  @override
  String get noDeletedActivities => 'Nessuna attività eliminata.';

  @override
  String activityDeleted(String name) {
    return '$name eliminata';
  }

  @override
  String activityRestored(String name) {
    return '$name ripristinata';
  }

  @override
  String activityRestoredSummaryOnly(String name) {
    return '$name ripristinata con i totali; la sua fonte non invia più percorso e curve.';
  }

  @override
  String deletedOn(String date) {
    return 'eliminata il $date';
  }

  @override
  String get restore => 'Ripristina';

  @override
  String get coachWhyThisToday => 'Perché questo allenamento oggi?';

  @override
  String get coachHowDidItGo => 'Com’è andata questa seduta?';

  @override
  String get coachWhyRestDay => 'Perché è un giorno di riposo?';

  @override
  String get coachWhatInstead => 'Cosa dovrei fare invece?';

  @override
  String get newChat => 'Nuova chat';

  @override
  String weekOfPlanned(String duration) {
    return 'di $duration pianificate';
  }

  @override
  String get weekDoneNothingPlanned =>
      'completato · nessun allenamento pianificato';

  @override
  String sessionDropped(String reason, String duration) {
    return '$reason · $duration saltate';
  }

  @override
  String get importTitle => 'Importa';

  @override
  String get stravaArchive => 'Archivio Strava';

  @override
  String get stravaArchiveZip => 'Archivio Strava (ZIP)';

  @override
  String get stravaArchiveSubtitle =>
      'Tutta la tua cronologia Strava con percorsi e foto';

  @override
  String get stravaIntro =>
      'Porta tutta la tua cronologia Strava in Fjelia: attività con percorso, frequenza cardiaca e potenza, e le loro foto.';

  @override
  String get stravaHowTo =>
      'Su strava.com: Impostazioni → Il mio account → Scarica o elimina il tuo account → Richiedi l’archivio. Strava ti invia uno ZIP via email; sceglilo qui così com’è, senza decomprimerlo.';

  @override
  String get stravaChooseZip => 'Scegli lo ZIP';

  @override
  String get stravaReading => 'Lettura dell’archivio…';

  @override
  String get stravaNotArchive =>
      'Questo ZIP non è un archivio dell’account Strava: manca activities.csv.';

  @override
  String stravaFound(int count) {
    return '$count attività trovate';
  }

  @override
  String stravaWithFiles(int count) {
    return '$count con registrazione (percorso e curve)';
  }

  @override
  String stravaPhotos(int photos, int videos) {
    return '$photos foto, $videos video';
  }

  @override
  String stravaAlready(int count) {
    return '$count duplicati, già in Fjelia o doppi su Strava: si aggiungono solo le foto mancanti';
  }

  @override
  String stravaDeletedSkip(int count) {
    return '$count eliminate in precedenza, saltate';
  }

  @override
  String stravaNew(int count) {
    return '$count nuove';
  }

  @override
  String stravaStorage(int mb) {
    return 'circa $mb MB per foto e video';
  }

  @override
  String get stravaPrivacy =>
      'Tutto viene letto su questo dispositivo. Nulla viene caricato e non serve l’accesso a Strava.';

  @override
  String stravaImportButton(int count) {
    return 'Importa $count attività';
  }

  @override
  String get stravaImporting => 'Importazione dell’archivio Strava';

  @override
  String stravaProgressActivities(String done, String total) {
    return 'Attività: $done / $total';
  }

  @override
  String stravaImportedCount(int count) {
    return '$count attività importate';
  }

  @override
  String stravaProgressPhotos(int count) {
    return 'Foto: $count importate';
  }

  @override
  String stravaProgressDuplicates(int count) {
    return 'Duplicati: $count saltati';
  }

  @override
  String stravaProgressDeleted(int count) {
    return 'Eliminate in precedenza: $count saltate';
  }

  @override
  String stravaProgressErrors(int count) {
    return 'Errori: $count';
  }

  @override
  String get stravaKeepOpen =>
      'Puoi usare l’app nel frattempo. Tieni Fjelia aperta finché l’importazione non è finita.';

  @override
  String get stravaComplete => 'Importazione Strava completata';

  @override
  String get stravaPartial => 'Importazione Strava incompleta';

  @override
  String get stravaCancelled => 'Importazione Strava annullata';

  @override
  String get stravaShowErrors => 'Mostra errori';

  @override
  String get stravaAgainHint =>
      'Importare di nuovo lo stesso archivio aggiunge solo ciò che manca.';

  @override
  String get renameActivity => 'Rinomina attività';

  @override
  String get activityTitleLabel => 'Titolo';

  @override
  String get activityTitleKept =>
      'Il tuo titolo resta quando l’attività si sincronizza di nuovo. Cambia solo in Fjelia, non sulla piattaforma di origine.';

  @override
  String originalTitle(String name) {
    return 'Originale: $name';
  }

  @override
  String get useOriginalTitle => 'Usa il titolo originale';

  @override
  String get loadOlderActivities => 'Carica attività meno recenti';

  @override
  String get noOlderActivities => 'Nessuna attività meno recente';

  @override
  String get maxSpeed => 'Velocità max';

  @override
  String get caloriesLabel => 'Calorie';

  @override
  String get activityDescription => 'Descrizione';

  @override
  String get nightCurves => 'Andamento notturno';

  @override
  String get noPhaseTimeline =>
      'Questo orologio non indica quando si è verificata ogni fase del sonno, solo i totali sopra. Ecco HRV e stress misurati durante la notte.';

  @override
  String get stagesEstimated =>
      'Stimato da Fjelia dall’HRV e dallo stress misurati di notte dal tuo orologio COROS. I totali delle fasi sono quelli di COROS; il momento di ogni fase è un’approssimazione.';

  @override
  String get nightCurvesBasis =>
      'HRV e stress misurati durante la notte. La stima delle fasi qui sopra si basa su di essi.';

  @override
  String get swimShort =>
      'In genere basta l’acqua. Nessun gel necessario: un pasto normale prima e dopo copre questa nuotata.';

  @override
  String get swimPoolLong =>
      'Valuta una bevanda con carboidrati nelle pause più lunghe tra le serie, soprattutto se la seduta è intensa. In piscina non servono gel.';

  @override
  String get swimOpenFeeds =>
      'Pianifica carboidrati e liquidi attorno alle occasioni di rifornimento (barca, kayak, riva). Non contare su ciò che non puoi raggiungere in sicurezza nuotando.';

  @override
  String get swimOpenUnsupported =>
      'Senza assistenza non ci sono rifornimenti: mangia bene prima, adatta la nuotata a quanto basta e reintegra subito dopo.';

  @override
  String get swimOpenFeedsUnknown =>
      'Acque libere: indica in «Modifica strategia» se sono possibili rifornimenti (con o senza assistenza).';

  @override
  String get swimFluidPool =>
      'Bere conta anche in piscina: in acqua si suda meno che a terra, ma non zero. Tieni una borraccia con il nome a bordo vasca e bevi nelle pause.';

  @override
  String get swimFluidOpen =>
      'Le previsioni non danno la temperatura dell’acqua e l’acqua fredda attenua la sete: bevi prima della partenza, a ogni rifornimento e subito dopo.';

  @override
  String get swimBeforeAfter =>
      'Prima: un pasto abituale ricco di carboidrati 1–4 h prima. Dopo: circa 1 g di carboidrati per kg con 20–25 g di proteine; se ti sei pesato, bevi circa 1,5 l per kg perso, con un po’ di sodio.';

  @override
  String get swimNoDuration =>
      'Nessuna durata prevista: l’acqua a bordo vasca basta per la maggior parte delle nuotate; una bevanda con carboidrati solo oltre i 90 minuti.';

  @override
  String swimCarryPool(String bottles, String bottleMl, String drinkCarbs) {
    return 'Niente gel. Borraccia a bordo vasca: $bottles × $bottleMl ml; $drinkCarbs g di carboidrati vengono dalla bevanda.';
  }

  @override
  String swimCarryOpen(String bottles, String bottleMl, String drinkCarbs) {
    return 'Niente gel mentre nuoti. Ai rifornimenti: $bottles × $bottleMl ml; $drinkCarbs g di carboidrati vengono dalla bevanda.';
  }

  @override
  String swimPerBreak(String carbs, String fluid) {
    return 'Ogni 20 minuti, in una pausa o a un rifornimento: circa $carbs g di carboidrati e $fluid ml.';
  }

  @override
  String get feedsLabel => 'Rifornimenti (acque libere)';

  @override
  String get feedsSupported => 'Con assistenza (barca, kayak, riva)';

  @override
  String get feedsUnsupported => 'Senza assistenza';

  @override
  String get feedsUnknown => 'Non noto';

  @override
  String get ecgTitle => 'ECG';

  @override
  String get ecgChooseDevice => 'Scegli Polar H10';

  @override
  String get ecgStart => 'Registra ECG';

  @override
  String get ecgStopSave => 'Interrompi e salva';

  @override
  String get ecgImport => 'Importa file ECG';

  @override
  String get ecgHistory => 'Cronologia ECG';

  @override
  String get ecgWaveform => 'Tracciato';

  @override
  String get ecgReport => 'Referto';

  @override
  String get ecgExportCsv => 'Esporta tracciato (CSV)';

  @override
  String get ecgExportMetadata => 'Esporta metadati ECG';

  @override
  String get ecgExportOriginal => 'Condividi file originale';

  @override
  String get ecgRecording => 'Registrazione ECG';

  @override
  String get ecgRecordingDate => 'Data e ora della registrazione';

  @override
  String get ecgLinkedWorkout => 'Allenamento collegato';

  @override
  String get ecgIndependent => 'Nessun allenamento collegato';

  @override
  String get ecgNoRecordings => 'Nessuna registrazione ECG.';

  @override
  String ecgSamples(int count) {
    return '$count campioni';
  }

  @override
  String ecgSignalGaps(int count) {
    return '$count interruzioni del segnale';
  }

  @override
  String get ecgDeleteConfirm =>
      'Eliminare definitivamente questa registrazione e il file originale?';

  @override
  String get ecgDescription =>
      'Registra con Polar H10, importa tracciati CSV o conserva referti PDF.';

  @override
  String get ecgPrivacy =>
      'Memorizzato su questo dispositivo e incluso nei backup. I segnali grezzi non vengono inviati al coach.';

  @override
  String get ecgLimitations =>
      'Per registrazione e consultazione personali. HRV da ECG e qualità del segnale non sono validate qui; non vengono calcolati diagnosi o punteggi di recupero.';

  @override
  String get ecgImportLimitations =>
      'I PDF Garmin e Apple Watch sono referti. I tracciati richiedono le colonne CSV time_seconds (o time_ms) ed ecg_uv (o ecg_mv).';

  @override
  String get ecgReportOnly =>
      'Solo referto. Nessun campione grezzo disponibile. Condividi il file originale per visualizzarlo.';

  @override
  String get indoorTitle => 'Allenamento indoor';

  @override
  String get indoorEquipment => 'Attrezzo fitness';

  @override
  String get indoorChooseEquipment => 'Scegli attrezzo';

  @override
  String get indoorChooseHeartRate => 'Scegli sensore cardiaco';

  @override
  String get indoorStart => 'Avvia registrazione';

  @override
  String get indoorPause => 'Pausa registrazione';

  @override
  String get indoorFinish => 'Termina e salva';

  @override
  String get indoorSaved => 'Salvato nella cronologia attività';

  @override
  String get indoorExportFit => 'Condividi attività FIT';

  @override
  String get indoorUnfinished => 'Registrazioni incomplete';

  @override
  String get indoorReviewResume => 'Rivedi o riprendi';

  @override
  String get indoorDiscard => 'Elimina registrazione';

  @override
  String get indoorDiscardConfirm =>
      'Eliminare definitivamente questa registrazione incompleta?';

  @override
  String get indoorExternalHeartRate => 'Usa sensore cardiaco esterno';

  @override
  String get indoorEquipmentHeartRate =>
      'Disattivato: usa il battito dell’attrezzo';

  @override
  String get indoorCurrentInterval => 'Intervallo attuale';

  @override
  String get indoorNextInterval => 'Intervallo successivo';

  @override
  String get indoorPlanComplete => 'Intervalli pianificati completati';

  @override
  String get indoorAuthorizeControl => 'Consenti controllo attrezzo';

  @override
  String get indoorManualOverride => 'Usa controllo manuale';

  @override
  String get indoorAutoPower =>
      'Segui automaticamente la potenza degli intervalli';

  @override
  String get indoorApplyTarget => 'Applica obiettivo';

  @override
  String get indoorDescription =>
      'Collega un attrezzo Bluetooth FTMS e registra un allenamento indoor.';

  @override
  String get indoorKeepOpen =>
      'La registrazione continua in un’altra app o a schermo bloccato. Pausa interrompe i dati; usa i comandi della macchina per metterla in pausa.';

  @override
  String get indoorFitHint =>
      'Salva il file FIT o aprilo in un’app compatibile tramite il menu di condivisione.';

  @override
  String get indoorNoEquipment =>
      'Nessun attrezzo FTMS trovato. Accendilo e abilita la connessione Bluetooth.';

  @override
  String get indoorControlPrompt =>
      'Consenti a Fjelia di cambiare gli obiettivi per questa sessione? Resta vicino ai comandi. Puoi tornare al controllo manuale in qualsiasi momento.';

  @override
  String get indoorTreadmillSafety =>
      'Collega la chiave di sicurezza e resta vicino ai comandi. Conferma solo piccole variazioni, fino a 0,5 km/h o 1% di pendenza. Usa l’attrezzo per variazioni maggiori.';

  @override
  String get recordingTime => 'Tempo di registrazione';

  @override
  String get recordingSpeed => 'Velocità';

  @override
  String get recordingPower => 'Potenza';

  @override
  String get recordingCadence => 'Cadenza / frequenza colpi';

  @override
  String get recordingIncline => 'Pendenza';

  @override
  String get recordingResistance => 'Resistenza';

  @override
  String get recordingSource => 'Fonte';

  @override
  String get recordingNext => 'Passaggio successivo';

  @override
  String get recordingConnecting => 'Connessione in corso';

  @override
  String get recordingReconnecting => 'Riconnessione in corso';

  @override
  String get recordingInterrupted => 'Interrotta';

  @override
  String get recordingPaused => 'In pausa';

  @override
  String get indoorMatrixReadOnly =>
      'Solo registrazione sui tapis roulant Matrix. Regola velocità e pendenza dalla console; il controllo remoto non è verificato per questo modello.';

  @override
  String ecgCoverage(String value) {
    return '$value% dei campioni acquisiti';
  }

  @override
  String get recordingBeforeRestore =>
      'Termina la registrazione prima di ripristinare un backup.';

  @override
  String get gymTitle => 'Tapis roulant in palestra';

  @override
  String get gymDescription =>
      'Registra con il telefono, importa allenamenti xID o scansiona il riepilogo della console.';

  @override
  String get gymDirectConnection => 'Connessione diretta';

  @override
  String get gymConsoleSupport =>
      'Le connessioni dipendono dalla console. Le console Matrix meno recenti possono offrire xID invece dei dati Bluetooth in tempo reale.';

  @override
  String get gymFindEquipment => 'Cerca attrezzature';

  @override
  String get gymLiveAvailable =>
      'Questa console può inviare i dati direttamente a Fjelia.';

  @override
  String get gymLiveUnavailable =>
      'Nessun dato in tempo reale compatibile. Importa allenamenti xID o salva un riepilogo della console.';

  @override
  String get gymSpeedOnly =>
      'Velocità e cadenza disponibili. Questa connessione non offre inclinazione o controllo remoto.';

  @override
  String get gymUseMachine => 'Usa questa attrezzatura';

  @override
  String get gymConnectionReport => 'Rapporto di connessione';

  @override
  String get gymShareReport => 'Condividi rapporto di connessione';

  @override
  String get gymXid => 'Matrix xID';

  @override
  String get gymXidDescription =>
      'Importa gli allenamenti sul tapis roulant salvati dalla rete xID della palestra.';

  @override
  String get gymPortal => 'Portale Netpulse della palestra';

  @override
  String get gymPortalHelp =>
      'Inserisci l’indirizzo del portale Netpulse fornito dalla palestra.';

  @override
  String get gymPasscode => 'Codice xID';

  @override
  String get gymSessionHelp =>
      'La sessione viene salvata in modo sicuro. Il codice non viene salvato.';

  @override
  String get gymAutoSync => 'Sincronizza automaticamente gli allenamenti xID';

  @override
  String gymLastDays(int days) {
    return 'Ultimi $days giorni';
  }

  @override
  String get gymLoadWorkouts => 'Carica allenamenti';

  @override
  String get gymNoWorkouts =>
      'Nessun allenamento sul tapis roulant in questo periodo.';

  @override
  String gymSkipped(int count) {
    return '$count allenamenti illeggibili ignorati.';
  }

  @override
  String gymImported(int count, int duplicates) {
    return '$count allenamenti importati; $duplicates duplicati ignorati.';
  }

  @override
  String get gymSummary => 'Riepilogo del tapis roulant';

  @override
  String get gymSummaryDescription =>
      'Fotografa la schermata finale della console e verifica i valori prima di salvare.';

  @override
  String get gymTakePhoto => 'Scatta foto';

  @override
  String get gymChoosePhoto => 'Scegli foto';

  @override
  String get gymReview =>
      'Verifica unità, ora di inizio e valori. Le foto vengono lette sul telefono. Viene salvato solo il riepilogo.';

  @override
  String get gymStartTime => 'Inizio allenamento';

  @override
  String get gymDurationHelp => 'Inserisci mm:ss o hh:mm:ss, ad esempio 30:00.';

  @override
  String get gymDistanceUnit => 'Unità di distanza';

  @override
  String get gymCalories => 'Calorie';

  @override
  String get manualRecordTitle => 'Registra attività';

  @override
  String get manualRecordDescription =>
      'Registra un’attività con GPS, ECG e frequenza cardiaca opzionali. La registrazione continua cambiando app o bloccando lo schermo, finché premi Pausa o Stop.';

  @override
  String get manualTreadmill => 'Corsa sul tapis roulant';

  @override
  String get manualChooseH10 => 'Scegli Polar H10';

  @override
  String get manualRecordEcg => 'Registra ECG con Polar H10';

  @override
  String get manualChooseHelp =>
      'Scegli un Polar H10 per registrare ECG e frequenza cardiaca.';

  @override
  String manualEcgSegments(int count) {
    return 'Segmenti ECG collegati: $count';
  }

  @override
  String get manualEcgInterrupted =>
      'ECG interrotto. Il timer dell’attività continua.';

  @override
  String get manualRestartEcg => 'Riavvia registrazione ECG';

  @override
  String get manualFinalDistance => 'Distanza finale (facoltativa)';

  @override
  String get manualDiscardNote =>
      'Scartare questa attività? Le registrazioni ECG rimangono nella cronologia ECG.';

  @override
  String get manualRecordHeartRate => 'Registra la frequenza cardiaca';

  @override
  String get manualChooseHr => 'Scegli un sensore cardiaco';

  @override
  String get manualHrWithEcg => 'Usa la stessa connessione H10 dell’ECG.';

  @override
  String get manualRecordGps => 'Registra percorso GPS e distanza';

  @override
  String get manualGpsHelp =>
      'Per attività all’aperto. Consenti la posizione precisa per registrare a schermo spento.';

  @override
  String get manualGpsWaiting => 'In attesa di una posizione GPS precisa';

  @override
  String manualGpsAccuracy(int meters) {
    return 'Precisione GPS: $meters m';
  }

  @override
  String get manualRecordBp => 'Includi le misurazioni della pressione';

  @override
  String get manualBpHelp =>
      'Mostra le misurazioni Hilo, Aktiia e Health effettuate durante la registrazione, anche dopo sincronizzazioni successive.';

  @override
  String get manualBpUnavailable =>
      'Impossibile caricare le misurazioni della pressione.';

  @override
  String get manualBpEmpty =>
      'Nessuna misurazione della pressione durante questa registrazione.';

  @override
  String get manualHrDisconnected => 'Sensore cardiaco disconnesso.';

  @override
  String get manualReconnectHr => 'Riconnetti il sensore cardiaco';

  @override
  String get manualBackgroundNotification =>
      'La registrazione continua a schermo spento';

  @override
  String get ecgAskCoach => 'Parlane con il coach IA';

  @override
  String get ecgCoachWarningTitle => 'Non è un consiglio medico';

  @override
  String get ecgCoachWarningBody =>
      'Il coach IA non è un medico e non può fare diagnosi. Un ECG da fascia toracica ha una sola derivazione: non può escludere un infarto o altre malattie cardiache, e l\'analisi può essere sbagliata.\n\nDolore o oppressione al petto, fiato corto, dolore al braccio, alla mandibola o alla schiena, sudore freddo o svenimento: chiama subito il 112. Non aspettare la risposta dell\'IA.\n\nI valori analizzati e 10 secondi del segnale grezzo vanno al modello IA scelto nelle impostazioni IA.';

  @override
  String get ecgCoachUnderstood => 'Ho capito';

  @override
  String get ecgCoachBanner =>
      'Non è un consiglio medico. L\'IA non è un medico e non può escludere un infarto. Emergenza: chiama il 112.';

  @override
  String get ecgCoachCardTitle => 'Pre-analisi ECG';

  @override
  String get statusMeasured => 'Misurato';

  @override
  String get ecgQuestionOverview => 'Cosa mostra il mio ECG?';

  @override
  String get ecgQuestionRhythm => 'Il mio ritmo cardiaco è regolare?';

  @override
  String get ecgQuestionDoctor => 'Dovrebbe vederlo un medico?';

  @override
  String get ecgFollowSymptoms => 'Con quali sintomi dovrei andare dal medico?';

  @override
  String get ecgFollowRiskFactors => 'Cosa cambiano i miei fattori di rischio?';

  @override
  String get ecgFollowTraining => 'Posso allenarmi normalmente?';

  @override
  String get ecgFollowBetterRecording => 'Come registro un ECG migliore?';

  @override
  String get manualTreadmillConnect =>
      'Collega il tapis roulant (Bluetooth, facoltativo)';

  @override
  String get manualTreadmillHelp =>
      'Velocità, distanza e pendenza arrivano allora dal tapis roulant. Senza connessione, inserisci la distanza alla fine.';

  @override
  String get sportIndoorCycling => 'Ciclismo indoor';

  @override
  String get sportElliptical => 'Ellittica';

  @override
  String get sportStairClimber => 'Stepper';

  @override
  String get manualWrongMachine =>
      'Questo attrezzo non corrisponde allo sport scelto.';

  @override
  String get manualEquipmentHelp =>
      'Collega un attrezzo Bluetooth (FTMS). Velocità, potenza, cadenza e distanza arrivano dall’attrezzo.';

  @override
  String get plusTitle => 'Registra';

  @override
  String get plusStartWorkout => 'Inizia allenamento';

  @override
  String get plusStartWorkoutHint =>
      'Live con GPS, tapis roulant o bici indoor · ECG & battito';

  @override
  String get plusGroupTraining => 'Allenamento';

  @override
  String get plusGroupHeart => 'Cuore & circolazione';

  @override
  String get plusGroupBody => 'Corpo';

  @override
  String get plusGroupRecovery => 'Recupero';

  @override
  String get plusLogWorkout => 'Aggiungi allenamento';

  @override
  String get plusLogWorkoutHint => 'Una sessione passata, a mano';

  @override
  String get plusImport => 'Importa';

  @override
  String get plusImportHint => 'Strava, FIT, GPX, tapis della palestra';

  @override
  String get plusEcg => 'Registra ECG';

  @override
  String get plusEcgHint => 'Polar H10 o file ECG';

  @override
  String get plusHrv => 'Check HRV';

  @override
  String get plusHrvHint => 'Misura breve con Polar H10';

  @override
  String get plusBpMeasure => 'Misura la pressione';

  @override
  String get plusBpMeasureHint => 'Bracciale Hilo via Bluetooth';

  @override
  String get plusBpLog => 'Inserisci pressione';

  @override
  String get plusBpLogHint => 'Scrivi un valore';

  @override
  String get plusBpReport => 'Report Hilo';

  @override
  String get plusBpReportHint => 'Importa il PDF';

  @override
  String get plusSpo2 => 'SpO₂ & battito';

  @override
  String get plusSpo2Hint => 'Dal saturimetro';

  @override
  String get plusWeigh => 'Pesati';

  @override
  String get plusWeighHint => 'Bilancia RENPHO via Bluetooth';

  @override
  String get plusWeightLog => 'Inserisci peso';

  @override
  String get plusWeightLogHint => 'Peso, grasso, BMI';

  @override
  String get plusWaist => 'Vita';

  @override
  String get plusWaistHint => 'Circonferenza & rapporti';

  @override
  String get plusGrip => 'Forza di presa';

  @override
  String get plusGripHint => 'Valore del dinamometro';

  @override
  String get plusSleep => 'Inserisci sonno';

  @override
  String get plusSleepHint => 'Durata, profondo e REM';

  @override
  String get recPace => 'Passo (/km)';

  @override
  String get recAvgPace => 'Passo medio';

  @override
  String get recPace500 => 'Passo (/500 m)';

  @override
  String get recSpeedKmh => 'Velocità (km/h)';

  @override
  String get recPowerW => 'Potenza (W)';

  @override
  String get recDistanceKm => 'Distanza (km)';

  @override
  String get recHeartRate => 'Battito';

  @override
  String get recMap => 'Mappa';

  @override
  String get recStart => 'Avvia';

  @override
  String get recResume => 'Riprendi';

  @override
  String get recFinish => 'Fine';

  @override
  String get recDiscard => 'Scarta';

  @override
  String get recLive => 'Registrazione';

  @override
  String get recNew => 'Nuova attività';

  @override
  String get recCadence => 'Cadenza';

  @override
  String get recMachine => 'Attrezzo';

  @override
  String get recGps => 'GPS';

  @override
  String get recEcg => 'ECG';

  @override
  String get recBloodPressure => 'Pressione';

  @override
  String get recBannerOpen => 'Tocca per aprire';

  @override
  String get bpActivityHint =>
      'I bracciali spesso non misurano mentre ti muovi. Le misure prima o dopo l’attività non compaiono qui.';

  @override
  String objectiveKeyLong(String sport, String goal) {
    return '$sport: seduta lunga chiave per $goal';
  }

  @override
  String seasonKeyRides(int n) {
    return 'In $n settimane una seduta lunga chiave sale verso metà della gara, una volta per blocco e mai vicino a un\'altra gara.';
  }

  @override
  String seasonEventAsLong(int n) {
    return 'In $n settimane un\'altra gara è la seduta lunga per un obiettivo più grande.';
  }

  @override
  String objectiveThreshold(String sport, String goal) {
    return '$sport alla soglia per $goal';
  }

  @override
  String objectiveHills(String sport, String goal) {
    return '$sport in salita per $goal';
  }

  @override
  String objectiveOpeners(String goal) {
    return 'Attivazione breve per $goal';
  }

  @override
  String get planAdjustedTitle => 'Piano adattato automaticamente';

  @override
  String planAdjSwap(String session, String day, String from) {
    return '$session: fatta $day invece di $from.';
  }

  @override
  String planAdjSubstitute(String activity, String session, String from) {
    return '$activity conta come $session di $from.';
  }

  @override
  String planAdjStrengthCredit(String activity, String session) {
    return '$activity copre la forza gambe di $session.';
  }

  @override
  String planAdjMoved(String session, String day) {
    return '$session passa a $day, che si è liberato.';
  }

  @override
  String planAdjMovedEasy(String session, String day, String activity) {
    return '$session passa a $day, più facile: le gambe recuperano da $activity.';
  }

  @override
  String get planAdjUndone => 'Modifica annullata.';

  @override
  String get shortSessionTitle => 'Più breve del previsto – perché?';

  @override
  String shortSessionLine(String session, int done, int planned) {
    return '$session: $done di $planned min';
  }

  @override
  String get shortReasonTime => 'Niente tempo';

  @override
  String get shortReasonWeather => 'Meteo';

  @override
  String get shortReasonFatigue => 'Stanco';

  @override
  String get shortReasonPain => 'Dolore';

  @override
  String get shortReasonOther => 'Altro';

  @override
  String get styleTitle => 'Stile';

  @override
  String get styleAuto => 'Auto';

  @override
  String get styleAutoHint =>
      'Segue il telefono: LightFjelia di giorno, DarkFjelia di notte.';

  @override
  String get connectMyWhoosh => 'Collega MyWhoosh';

  @override
  String get myWhooshSubtitle =>
      'Accedi con il tuo account MyWhoosh per importare le uscite indoor con potenza, cadenza e frequenza cardiaca.';

  @override
  String get myWhooshCredentialsInfo =>
      'Le credenziali MyWhoosh sono salvate cifrate sul tuo dispositivo. Fjelia legge le uscite direttamente da MyWhoosh, tramite l\'interfaccia dell\'app MyWhoosh. Fjelia non è affiliata a MyWhoosh.';

  @override
  String get myWhooshTile => 'Uscite indoor';

  @override
  String get myWhooshSignedInElsewhere =>
      'MyWhoosh consente una sola sessione per account e hai già effettuato l\'accesso su un altro dispositivo. Chiudi MyWhoosh lì (esci se serve) e riprova.';

  @override
  String get shareWorkout => 'Condividi allenamento';

  @override
  String get shareFitFile => 'Condividi come file FIT';

  @override
  String get shareFitFileHint => 'Per Strava, COROS, TrainingPeaks e altre app';

  @override
  String get sendToGarmin => 'Invia a Garmin Connect';

  @override
  String get sendToGarminHint => 'Carica l\'allenamento nel tuo account Garmin';

  @override
  String get sentToGarmin => 'Inviato a Garmin Connect';

  @override
  String get alreadyOnGarmin => 'Questo allenamento è già in Garmin Connect';
}
