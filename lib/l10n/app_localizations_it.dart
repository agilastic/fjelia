// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

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
      'L\'invio condivide la tua e-mail, l\'oggetto, il messaggio e la diagnostica selezionata con il supporto Fjelia su cloud.ebeling-hoppe.de.';

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
  String get yourDataStaysOnYour =>
      'I tuoi dati restano sul tuo dispositivo. Sempre privati.';

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
  String get shadedAreaProviderSpread =>
      'Area ombreggiata: dispersione tra provider';

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
  String get enableWorkoutNotifications =>
      'Attiva le notifiche degli allenamenti';

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
  String get allowNotificationsInSystemSettings =>
      'Consenti le notifiche nelle impostazioni di sistema';

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
  String get workoutNotificationsEnabled =>
      'Notifiche degli allenamenti attivate';

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
      'Apple Intelligence non è disponibile su questo dispositivo (servono un iPhone o un Mac supportato con iOS/macOS 26 o successivo e Apple Intelligence attivo in Impostazioni). Scegli un altro provider e aggiungi la tua chiave API per usare il coach.';

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
      'Rimuovere questa attività dalla cronologia locale? Una successiva sincronizzazione del provider può importarla di nuovo.';

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
}
