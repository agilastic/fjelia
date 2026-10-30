// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get freeAi => 'Free AI';

  @override
  String get freeAiUsageTracking =>
      'Pour que Free AI reste fiable et accessible à tous, nous envoyons un identifiant d\'installation aléatoire. Il nous aide à repérer une utilisation inhabituelle et à bloquer les requêtes abusives. Cet identifiant ne contient ni votre nom ni les informations de votre compte.';

  @override
  String freeAiDescription(String host) {
    return 'IA gratuite dans le cloud pour le chat et les résumés via $host. Aucun compte ni clé API personnels nécessaires. Après votre confirmation, les messages et un résumé de santé et d\'entraînement sont envoyés à ce service.';
  }

  @override
  String get freeAiUnavailable =>
      'Free AI n\'est pas disponible dans cette version. Choisissez un autre fournisseur.';

  @override
  String shareBriefingContextWithName(String name) {
    return 'Un résumé de vos données de santé et d\'entraînement sera envoyé à $name.';
  }

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get settings => 'Réglages';

  @override
  String get profile => 'Profil';

  @override
  String get training => 'Entraînement';

  @override
  String get weatherLocation => 'Météo et position';

  @override
  String get display => 'Affichage';

  @override
  String get connections => 'Connexions';

  @override
  String get aiAndMore => 'IA et plus';

  @override
  String get system => 'Système';

  @override
  String get runSetupAgain => 'Relancer la configuration';

  @override
  String get runSetupAgainSubtitle =>
      'Comptes, objectif de course et plan d\'entraînement';

  @override
  String get back => 'Retour';

  @override
  String get close => 'Fermer';

  @override
  String get dataExport => 'Export des données';

  @override
  String get dataExportSubtitle => 'Export CSV, sauvegarde et restauration';

  @override
  String get developer => 'Développeur';

  @override
  String get developerSubtitle => 'Mode débogage, diagnostic';

  @override
  String get debug => 'Débogage';

  @override
  String get debugMode => 'Mode débogage';

  @override
  String get debugModeSubtitle => 'Affiche l\'onglet DEBUG';

  @override
  String get support => 'Assistance';

  @override
  String get reportBug => 'Signaler un bogue';

  @override
  String get aiCoach => 'Coach IA';

  @override
  String get enableAiCoach => 'Activer le coach IA';

  @override
  String get onDeviceAiOrCloud => 'IA sur l\'appareil ou fournisseur cloud';

  @override
  String get provider => 'Fournisseur';

  @override
  String get model => 'Modèle';

  @override
  String get chatAndAiBriefingsUse =>
      'Le chat et les briefings IA utilisent Apple Intelligence sur cet appareil. Aucune clé API requise. Si le modèle n\'est pas disponible, les briefings affichent un résumé sans IA.';

  @override
  String get briefing => 'Briefing';

  @override
  String get useAppleIntelligenceForBriefings =>
      'Utiliser Apple Intelligence pour les briefings';

  @override
  String get useOnDeviceAiFor =>
      'Utiliser l\'IA sur l\'appareil pour les briefings tout en gardant le fournisseur choisi pour le chat.';

  @override
  String get healthDataSharing => 'Partage des données de santé';

  @override
  String get askOncePerChatSession => 'Demander une fois par session de chat';

  @override
  String get otherwiseAskBeforeEveryCloud =>
      'Sinon, demander avant chaque message cloud';

  @override
  String get reportABug => 'Signaler un bogue';

  @override
  String get weatherData => 'Données météo';

  @override
  String get openSourceLibraries => 'Bibliothèques open source';

  @override
  String get license => 'Licence';

  @override
  String get licenses => 'Licences';

  @override
  String get apiKey => 'Clé API';

  @override
  String get saveApiKey => 'Enregistrer la clé API';

  @override
  String get feedbackBugReport => 'Retour et rapport de bogue';

  @override
  String get reportSentThankYou => 'Rapport envoyé. Merci !';

  @override
  String get weReadEveryMessageIf =>
      'Nous lisons chaque message. Si tu as indiqué ton e-mail, tu recevras peut-être une réponse.';

  @override
  String get done => 'Terminé';

  @override
  String get shareAnIdeaSuggestAn =>
      'Partage une idée, propose une amélioration ou dis-nous ce qui s\'est passé et ce que tu attendais.';

  @override
  String get whatHappenedAndWhatDid =>
      'Que s\'est-il passé et qu\'attendais-tu ?';

  @override
  String get pleaseLeaveOutPasswordsApi =>
      'Merci de ne pas indiquer de mots de passe, de clés API ni de mesures de santé personnelles.';

  @override
  String get includeDiagnostics => 'Inclure les diagnostics';

  @override
  String get optionalLogsMayContainAccount =>
      'Facultatif. Les journaux peuvent contenir des informations de compte ou de santé. Vérifie-les ci-dessous avant l\'envoi.';

  @override
  String get diagnosticsPreview => 'APERÇU DES DIAGNOSTICS';

  @override
  String get sendingSharesYourEmailSubject =>
      'L\'envoi partage ton e-mail, l\'objet, le message et les diagnostics sélectionnés avec l\'assistance Fjelia à cloud.ebeling-hoppe.de.';

  @override
  String get copyReport => 'Copier le rapport';

  @override
  String get shareReport => 'Partager le rapport';

  @override
  String get appleHealth => 'Apple Santé';

  @override
  String get connectedServices => 'Services connectés';

  @override
  String get hiloBloodPressureBle => 'Hilo tension artérielle (BLE)';

  @override
  String get writeHeartDataToApple =>
      'Écrire les données cardiaques dans Apple Santé';

  @override
  String get writeWeightDataToApple =>
      'Écrire les données de poids dans Apple Santé';

  @override
  String get renphoScaleBle => 'Balance Renpho (BLE)';

  @override
  String get polarH10HrvStrapBle => 'Polar H10 (ceinture VFC, BLE)';

  @override
  String get dataSourcePriority => 'Priorité des sources de données';

  @override
  String get whenMultipleSourcesProvideThe =>
      'Quand plusieurs sources fournissent la même mesure, la source la plus haute l\'emporte. Fais glisser pour réorganiser.';

  @override
  String get resetToDefault => 'Rétablir les valeurs par défaut';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get healthPage => 'Page Santé';

  @override
  String get loadPage => 'Page Charge';

  @override
  String get healthMonitor => 'Suivi de santé';

  @override
  String get hrZones => 'Zones de FC';

  @override
  String get t30MinTtAvailableSync =>
      'TT de 30 min disponible : synchroniser les zones de FC';

  @override
  String lt2Lt2BpmAt(Object lt2, Object at) {
    return 'LT2 $lt2 bpm · $at';
  }

  @override
  String get syncLabel => 'SYNCHRO';

  @override
  String get autoadjust => 'AJUSTEMENT AUTO';

  @override
  String zoneI(Object i) {
    return 'Zone $i';
  }

  @override
  String get hrZones2 => 'ZONES DE FC';

  @override
  String ageRound(Object round) {
    return 'âge $round';
  }

  @override
  String get basics => 'Informations de base';

  @override
  String get updateWaistMonthlyUsedFor =>
      'ⓘ Mets à jour ton tour de taille chaque mois – utilisé pour estimer la graisse viscérale.';

  @override
  String get alcohol => 'Alcool';

  @override
  String get t1Drink033L =>
      '1 verre ≈ 0,33 l de bière / 0,2 l de vin / 4 cl d\'alcool fort';

  @override
  String get clinicalLabsOptional => 'Analyses biologiques (facultatif)';

  @override
  String get glycemic => 'Glycémie';

  @override
  String get optimalForLongevity48 =>
      'Optimal pour la longévité : 4,8–5,4 % · Prédiabète : 5,7–6,4 %';

  @override
  String get lipids => 'Lipides';

  @override
  String get apobReplacesLdlWhenBoth =>
      'L\'ApoB remplace le LDL lorsque les deux sont saisis.';

  @override
  String get inflammationKidney => 'Inflammation et reins';

  @override
  String get changesAreSavedAutomatically =>
      'Les modifications sont enregistrées automatiquement';

  @override
  String get optionalTotalClimbingForThis =>
      'Dénivelé positif total facultatif pour cette course.';

  @override
  String get moreAboutThisEvent => 'Plus d\'infos sur cet événement';

  @override
  String distanceOfDistancekmKm(Object distanceKm) {
    return 'Distance de $distanceKm km ?';
  }

  @override
  String keepDistancekmKm(Object distanceKm) {
    return 'Garder $distanceKm km';
  }

  @override
  String useLikelyKm(Object likely) {
    return 'Utiliser $likely km';
  }

  @override
  String get thisBackupContainsNoCalendar =>
      'Cette sauvegarde ne contient aucune activité de calendrier.';

  @override
  String get activities => 'Activités';

  @override
  String get exportActivitiesCsv => 'Exporter les activités en CSV';

  @override
  String get backupRestore => 'Sauvegarde et restauration';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get restoreFromBackup => 'Restaurer depuis une sauvegarde';

  @override
  String get backupRestoredRestartTheApp =>
      'Sauvegarde restaurée. Redémarre l\'app pour recharger tous les réglages.';

  @override
  String get raceGoals => 'Objectifs de course';

  @override
  String get yourActivities => 'Tes activités';

  @override
  String get usedByAiCoachAnd =>
      'Utilisé par le coach IA et le plan d\'entraînement. Les sports du plan sont marqués d\'un ✦.';

  @override
  String get calendarWeekStart => 'Début de semaine du calendrier';

  @override
  String get planDefaultView => 'Vue par défaut du plan';

  @override
  String get weeklySchedule => 'Planning hebdomadaire';

  @override
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      trainingDaysPerWeek,
      locale: localeName,
      other: '$trainingDaysPerWeek jours d\'entraînement',
      one: '$trainingDaysPerWeek jour d\'entraînement',
    );
    return '$_temp0 · touche pour alterner Entraînement / Repos / Renforcement';
  }

  @override
  String get updatePlanToThisSchedule =>
      'Mettre le plan à jour selon ce planning';

  @override
  String get updateStrengthSessions =>
      'Mettre à jour les séances de renforcement';

  @override
  String get sessionsPerDay => 'Séances par jour';

  @override
  String get canYouFitTwoWorkouts =>
      'Peux-tu caser deux séances dans la même journée ?';

  @override
  String get strengthLoadUnit => 'Unité de charge en musculation';

  @override
  String get weightsThemselvesAreSetIn =>
      'Les charges se règlent dans chaque séance et sont mémorisées d\'après ton historique.';

  @override
  String get hoursAvailableWeek => 'Heures disponibles / semaine';

  @override
  String hoursperweekHWeek(Object hoursPerWeek) {
    return '$hoursPerWeek h / semaine';
  }

  @override
  String hoursperweekH(Object hoursPerWeek) {
    return '$hoursPerWeek h';
  }

  @override
  String get heatAcclimation => 'Acclimatation à la chaleur';

  @override
  String get showHeatAcclimation => 'Afficher l\'acclimatation à la chaleur';

  @override
  String get weatherEvaluatedAgainstAConfigurable =>
      'La météo est évaluée pour un lieu configurable.';

  @override
  String get trainingPlan => 'Plan d\'entraînement';

  @override
  String get regenerateReplacesFutureSessionsAnd =>
      'Régénérer remplace les séances à venir et reconstruit le plan dès aujourd\'hui avec les réglages actuels.';

  @override
  String valueUpcomingWorkoutsGenerated(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value séances à venir générées',
      one: '$value séance à venir générée',
    );
    return '$_temp0';
  }

  @override
  String get generationFailedCheckYourRace =>
      'Échec de la génération. Vérifie ton objectif de course et réessaie.';

  @override
  String get deleteAllWorkouts => 'Supprimer toutes les séances';

  @override
  String get changesAreSavedAutomatically2 =>
      '✓ Les modifications sont enregistrées automatiquement';

  @override
  String countUpcomingWorkoutsGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séances à venir générées',
      one: '$count séance à venir générée',
    );
    return '$_temp0';
  }

  @override
  String get importRaceGoalsFromGarmin =>
      'Importer les objectifs de course depuis Garmin';

  @override
  String get addRaceGoal => 'Ajouter un objectif de course';

  @override
  String priorityTouppercase(Object toUpperCase) {
    return 'Priorité $toUpperCase';
  }

  @override
  String get goalsAreSharedWithAi =>
      'Les objectifs sont partagés avec le coach IA. La priorité A, B ou C détermine le poids de chaque course dans le plan.';

  @override
  String get deletingWorkouts => 'Suppression des séances';

  @override
  String get cityOrTown => 'Ville ou commune';

  @override
  String get eGHannoverOrPalma => 'p. ex. Hanovre ou Palma';

  @override
  String get noCitiesFoundTryA =>
      'Aucune ville trouvée. Essaie une commune voisine.';

  @override
  String get chooseTheLocationForThe =>
      'Choisis le lieu pour les prévisions du plan, le radar et l\'acclimatation à la chaleur. La météo fonctionne même si l\'acclimatation est désactivée.';

  @override
  String get none => 'Aucune';

  @override
  String get disableLocalWeatherAndLocation =>
      'Désactiver la météo locale et les demandes de position';

  @override
  String get currentLocation => 'Position actuelle';

  @override
  String get followYourDeviceLocation => 'Suivre la position de ton appareil';

  @override
  String get fixedLocation => 'Position fixe';

  @override
  String get chooseACityOrEnter =>
      'Choisis une ville ou saisis des coordonnées';

  @override
  String get chooseCity => 'Choisir une ville';

  @override
  String get coordinates => 'Coordonnées';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get saveLocation => 'Enregistrer la position';

  @override
  String get refreshCurrentLocation => 'Actualiser la position actuelle';

  @override
  String get citySearchOpenMeteoGeonames =>
      'Recherche de villes : Open-Meteo / GeoNames';

  @override
  String get cityNamesOpenstreetmap => 'Noms de villes : © OpenStreetMap';

  @override
  String get energy => 'ÉNERGIE';

  @override
  String get currentEnergy => 'ÉNERGIE ACTUELLE';

  @override
  String get dailyTimeline => 'CHRONOLOGIE DU JOUR';

  @override
  String valueValue2(Object value, Object value2) {
    return '$value → $value2';
  }

  @override
  String get energy2 => 'Énergie';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get bloodPressureInsights => 'ANALYSE DE LA TENSION';

  @override
  String get sys => ' Sys';

  @override
  String get diaMmhg => ' Dia · mmHg';

  @override
  String get previousBloodPressurePeriod => 'Période de tension précédente';

  @override
  String get nextBloodPressurePeriod => 'Période de tension suivante';

  @override
  String get nightDipping => 'Baisse nocturne';

  @override
  String get noMeasurementsInThisPeriod => 'Aucune mesure sur cette période';

  @override
  String get fullscreenBloodPressureChart =>
      'Graphique de tension en plein écran';

  @override
  String get barsMinMaxLineDots =>
      'Barres : min–max · ligne/points : moyenne · touche ou fais glisser pour inspecter';

  @override
  String get noMeasurements => 'Aucune mesure';

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
      other: '$length mesures',
      one: '$length mesure',
    );
    return '$_temp0 · moyenne / min–max';
  }

  @override
  String bloodPressureTouppercaseMmhg(Object toUpperCase) {
    return 'TENSION · $toUpperCase · mmHg';
  }

  @override
  String get closeFullscreenBloodPressureChart =>
      'Fermer le graphique de tension en plein écran';

  @override
  String get chooseScale => 'Choisir une balance';

  @override
  String get noScalesFoundStepOn =>
      'Aucune balance trouvée. Monte sur ta balance et réessaie.';

  @override
  String nameRssiDbm(Object name, Object rssi) {
    return '$name · $rssi dBm';
  }

  @override
  String get renphoSaved => 'RENPHO enregistrée :';

  @override
  String get renphoScaleBle2 => 'Balance RENPHO (BLE)';

  @override
  String get changeMeasurementType => 'Changer le type de mesure';

  @override
  String get addMeasurement => 'Ajouter une mesure';

  @override
  String get whatAreYouMeasuring => 'Que mesures-tu ?';

  @override
  String get chooseAnotherMeasurement => 'Choisir une autre mesure';

  @override
  String get saveMeasurement => 'Enregistrer la mesure';

  @override
  String get skip => 'Passer';

  @override
  String get connectHiloService => 'Connecter le service Hilo';

  @override
  String get connectHilo => 'Connecter Hilo';

  @override
  String get connectCoros => 'Connecter Coros';

  @override
  String get europe => 'Europe';

  @override
  String get unitedStates => 'États-Unis';

  @override
  String get asia => 'Asie';

  @override
  String get bluetoothBloodPressure => 'Bluetooth · tension artérielle';

  @override
  String get cloudCuffData => 'Cloud · données du brassard';

  @override
  String get apiSync => 'Synchro API';

  @override
  String get bluetoothHrvStrap => 'Bluetooth · ceinture VFC';

  @override
  String get accesslinkApi => 'AccessLink API';

  @override
  String get systemHealthData => 'Données de santé du système';

  @override
  String get cloudScaleHistory => 'Cloud · historique de la balance';

  @override
  String get bluetoothWeightBody => 'Bluetooth · poids et corps';

  @override
  String get connectYourDevices => 'Connecte tes appareils';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get connectGarmin => 'Connecter Garmin';

  @override
  String get connectAppleHealth => 'Connecter Apple Santé';

  @override
  String get dataSynced => 'DONNÉES SYNCHRONISÉES';

  @override
  String get pairHiloPod => 'Associer le Hilo Pod';

  @override
  String get chooseStrap => 'Choisir la ceinture';

  @override
  String namePaired(Object name) {
    return '$name associé.';
  }

  @override
  String get pairPolarH10 => 'Associer le Polar H10';

  @override
  String get forget => 'Oublier';

  @override
  String get sendWorkoutToPolar => 'Envoyer la séance à Polar';

  @override
  String get connectPolar => 'Connecter Polar';

  @override
  String get signInWithPolarFlow => 'Se connecter avec Polar Flow';

  @override
  String get syncsSleepStagesHrvResting =>
      'Synchronise phases de sommeil · VFC · FC au repos · séances · pas';

  @override
  String savedForV(Object v) {
    return 'Enregistré pour $v';
  }

  @override
  String get remove => 'Supprimer';

  @override
  String get polarEMail => 'E-mail Polar';

  @override
  String get polarPassword => 'Mot de passe Polar';

  @override
  String get pairRenphoScale => 'Associer la balance RENPHO';

  @override
  String get connectRenpho => 'Connecter Renpho';

  @override
  String get connectSuunto => 'Connecter Suunto';

  @override
  String smsSentToTrim(Object trim) {
    return 'SMS envoyé à $trim';
  }

  @override
  String get resendSms => 'Renvoyer le SMS';

  @override
  String get retryLoadingPreferences => 'Réessayer de charger les préférences';

  @override
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed) {
    return 'TEMPS D\'ENTRAÎNEMENT HEBDOMADAIRE · $toStringAsFixed h';
  }

  @override
  String get tapADayToCycle =>
      'Touche un jour pour alterner Entraînement / Repos / Renforcement.';

  @override
  String get doubleDayOk => 'Double séance OK';

  @override
  String get birthYearOptional => 'Année de naissance (facultatif)';

  @override
  String get addAnother => 'Ajouter un autre';

  @override
  String get knowYourBodyTrainSmarter =>
      'Connais ton corps.\nEntraîne-toi mieux.';

  @override
  String get allYourHealthDevicesOne =>
      'Tous tes appareils de santé. Une seule vue intelligente.';

  @override
  String get areYouReadyToTrain => 'Es-tu prêt à t\'entraîner aujourd\'hui ?';

  @override
  String get hrvRecoveryScoreRestingHr =>
      'VFC · Score de récupération · FC au repos';

  @override
  String get didYouActuallyRecoverLast =>
      'As-tu vraiment récupéré cette nuit ?';

  @override
  String get sleepStagesDeepSleepSpo =>
      'Phases de sommeil · Sommeil profond · SpO₂';

  @override
  String get isYourBloodPressureUnder => 'Ta tension est-elle sous contrôle ?';

  @override
  String get continuousBpNightDippingTrends =>
      'Tension continue · Baisse nocturne · Tendances';

  @override
  String get howHardDidYouPush => 'À quel point as-tu forcé cette semaine ?';

  @override
  String get trainingLoadTrimpStrainScore =>
      'Charge d\'entraînement · TRIMP · Score de contrainte';

  @override
  String get isYourBodyCompositionImproving =>
      'Ta composition corporelle s\'améliore-t-elle ?';

  @override
  String get weightBodyFatMuscleMass =>
      'Poids · Masse grasse · Masse musculaire';

  @override
  String get getStarted => 'Commencer';

  @override
  String get yourDataStaysOnYour =>
      'Vos données. Vous choisissez ce que vous partagez.';

  @override
  String get bodyScale => 'Pèse-personne';

  @override
  String get bodyComposition => 'Composition corporelle';

  @override
  String get sleep => 'SOMMEIL';

  @override
  String get sleepPerformance => 'PERFORMANCE DU SOMMEIL';

  @override
  String get sleepHistory => 'Historique du sommeil';

  @override
  String labelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String lessLabel(Object label) {
    return 'Moins de $label';
  }

  @override
  String moreLabel(Object label) {
    return 'Plus de $label';
  }

  @override
  String get gymMode => 'Mode salle';

  @override
  String get finishWorkout => 'Terminer la séance';

  @override
  String get workoutActions => 'Actions de la séance';

  @override
  String get discardWorkout => 'Abandonner la séance';

  @override
  String get allSetsRecorded => 'Toutes les séries enregistrées';

  @override
  String get reviewSets => 'Revoir les séries';

  @override
  String get rest => 'REPOS';

  @override
  String plannedResttarget(Object restTarget) {
    return 'Prévu $restTarget';
  }

  @override
  String get startSet => 'Démarrer la série';

  @override
  String get seconds => 'Secondes';

  @override
  String get previousSet => 'Série précédente';

  @override
  String get allSets => 'Toutes les séries';

  @override
  String get nextSet => 'Série suivante';

  @override
  String get everySetIsSavedAs =>
      'Chaque série est enregistrée au fur et à mesure. Ferme cet écran quand tu veux et reprends depuis la séance prévue.';

  @override
  String get cancel => 'Annuler';

  @override
  String get apply => 'Appliquer';

  @override
  String get effortScale => 'Échelle d\'effort';

  @override
  String get setType => 'Type de série';

  @override
  String get reps => 'Répétitions';

  @override
  String get range => 'Plage';

  @override
  String get time => 'Durée';

  @override
  String get t45Or100 => '45 ou 1:00';

  @override
  String get blankWhenNotSet => 'Vide si non défini';

  @override
  String get redBand => 'Bande rouge';

  @override
  String get t90Or130 => '90 ou 1:30';

  @override
  String get blankWhenUnknown => 'Vide si inconnu';

  @override
  String get usePlannedLoad => 'Utiliser la charge prévue';

  @override
  String get blankWhenNotMeasured => 'Vide si non mesuré';

  @override
  String get exercise => 'Exercice';

  @override
  String get changingTheLoadConventionStarts =>
      'Changer la convention de charge crée un historique séparé pour cet exercice.';

  @override
  String get barbellMachine => 'Barre, machine…';

  @override
  String get load => 'Charge';

  @override
  String get loadRefersTo => 'La charge se rapporte à';

  @override
  String get t2ForAPair => '2 pour une paire';

  @override
  String get repetitions => 'Répétitions';

  @override
  String get availablePlatesOrDumbbells => 'Disques ou haltères disponibles';

  @override
  String get rememberForThisEquipment => 'Mémoriser pour cet équipement';

  @override
  String get findOrNameAnExercise => 'Trouver ou nommer un exercice';

  @override
  String createTrim(Object trim) {
    return 'Créer « $trim »';
  }

  @override
  String get customExercise => 'Exercice personnalisé';

  @override
  String get smallestLoadStep => 'Plus petit pas de charge';

  @override
  String whatRemoved(Object what) {
    return '$what supprimé';
  }

  @override
  String get undo => 'Annuler';

  @override
  String get retry => 'Réessayer';

  @override
  String get performance => 'Performance';

  @override
  String get addExercise => 'Ajouter un exercice';

  @override
  String get finishLog => 'Terminer le journal';

  @override
  String get keepAsDraft => 'Garder comme brouillon';

  @override
  String actionsForName(Object name) {
    return 'Actions pour $name';
  }

  @override
  String get editExercise => 'Modifier l\'exercice';

  @override
  String get moveUp => 'Monter';

  @override
  String get moveDown => 'Descendre';

  @override
  String get addSet => 'Ajouter une série';

  @override
  String get removeLastSet => 'Supprimer la dernière série';

  @override
  String get saveAsTemplate => 'Enregistrer comme modèle';

  @override
  String savedTitleAsATemplate(Object title) {
    return '« $title » enregistré comme modèle. Cette séance reste inchangée tant que tu ne l\'enregistres pas.';
  }

  @override
  String nameSetN(Object name, Object n) {
    return '$name · Série $n';
  }

  @override
  String nameAllWorkingSets(Object name) {
    return '$name · Toutes les séries de travail';
  }

  @override
  String labelRest(Object label) {
    return 'Repos $label';
  }

  @override
  String get secondsOrMSs => 'Secondes ou m:ss';

  @override
  String get applyToAllSets => 'Appliquer à toutes les séries';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get supersetWithNext => 'Superset avec la suivante';

  @override
  String get circuitWithNext => 'Circuit avec la suivante';

  @override
  String actionsForSetN(Object n) {
    return 'Actions pour la série $n';
  }

  @override
  String get editSet => 'Modifier la série';

  @override
  String get duplicateSet => 'Dupliquer la série';

  @override
  String get removeSet => 'Supprimer la série';

  @override
  String labelActions(Object label) {
    return 'Actions $label';
  }

  @override
  String get editRests => 'Modifier les repos';

  @override
  String get ungroup => 'Dissocier';

  @override
  String get editExercises => 'Modifier les exercices';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String couldNotSaveError(Object error) {
    return 'Impossible d\'enregistrer : $error';
  }

  @override
  String get history => 'Historique';

  @override
  String get exercises => 'Exercices';

  @override
  String get noExercisesArePlannedFor =>
      'Aucun exercice n\'est encore prévu pour cette séance. Les notes ci-dessus la décrivent.';

  @override
  String get addExercises => 'Ajouter des exercices';

  @override
  String get fromTheBuiltInTemplate =>
      'Issu du modèle intégré. Les charges sont à toi ; l\'historique apparaît après ta première séance enregistrée.';

  @override
  String get shareExerciseList => 'Partager la liste d\'exercices';

  @override
  String get noSavedStrengthTemplatesYet =>
      'Aucun modèle de force enregistré pour l\'instant. Enregistres-en un depuis une séance prévue.';

  @override
  String get compareWith => 'Comparer avec';

  @override
  String estimated1rmUnit(Object unit) {
    return '1RM estimé $unit';
  }

  @override
  String get plannedNotRecorded => 'Prévu, non enregistré';

  @override
  String get notes => 'Notes';

  @override
  String get editPerformance => 'Modifier la performance';

  @override
  String get compareWithASavedWorkout => 'Comparer avec une séance enregistrée';

  @override
  String get sessions => 'Séances';

  @override
  String get radarUnavailableRetry => 'Radar indisponible · Réessayer';

  @override
  String get radar => 'Radar';

  @override
  String get weatherDataByRainviewer => 'Données météo par RainViewer';

  @override
  String get openstreetmapContributors => '© contributeurs d\'OpenStreetMap';

  @override
  String get weather => 'Météo';

  @override
  String get weatherUnavailableRetry => 'Météo indisponible · Réessayer';

  @override
  String get chooseAFixedLocationIn =>
      'Choisis un lieu fixe dans les réglages Météo et position, ou autorise l\'accès à la position pour la météo locale.';

  @override
  String get locationSettings => 'Réglages de position';

  @override
  String get retryLocation => 'Réessayer la position';

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
    return 'Bulbe humide $toStringAsFixed°C';
  }

  @override
  String get previousForecastDay => 'Jour de prévision précédent';

  @override
  String get nextForecastDay => 'Jour de prévision suivant';

  @override
  String daysDayForecast(Object days) {
    return 'Prévisions sur $days jours';
  }

  @override
  String thisProviderCurrentlySuppliesDays(Object days, Object days2) {
    return 'Ce fournisseur fournit actuellement $days jours de prévision sur $days2.';
  }

  @override
  String get now => 'Maintenant';

  @override
  String get sunriseSunset => 'Lever / coucher du soleil';

  @override
  String keyKey2(Object key, Object key2) {
    return '☀ $key   ☾ $key2';
  }

  @override
  String get use => 'Utiliser';

  @override
  String get exerciseDetailsWereNotProvided =>
      'Les détails des exercices n\'ont pas été fournis par cette source d\'activité.';

  @override
  String get logFromPlan => 'Enregistrer depuis le plan';

  @override
  String get addExerciseDetails => 'Ajouter les détails des exercices';

  @override
  String get loadSuggestion => 'Suggestion de charge';

  @override
  String get applyToThisWorkout => 'Appliquer à cette séance';

  @override
  String get keepCurrentLoad => 'Garder la charge actuelle';

  @override
  String get setLoadStep => 'Définir le pas de charge';

  @override
  String get viewSupportingSets => 'Voir les séries concernées';

  @override
  String get supportingSets => 'Séries concernées';

  @override
  String get noRecordedSessionsYet =>
      'Aucune séance enregistrée pour l\'instant.';

  @override
  String nameDemonstrationCue(Object name, Object cue) {
    return 'Démonstration de $name. $cue';
  }

  @override
  String get noScalesFoundStepOn2 =>
      'Aucune balance trouvée. Monte sur la balance et réessaie.';

  @override
  String get scalePaired => 'Balance associée';

  @override
  String get ok => 'OK';

  @override
  String get pairedReadyToMeasure => '✓ Associé – prêt à mesurer';

  @override
  String get chooseHiloCuff => 'Choisir le brassard Hilo';

  @override
  String get noCuffFoundWakeYour =>
      'Aucun brassard trouvé. Réveille ton brassard et relance la recherche.';

  @override
  String get hiloCuffAktiiaC => 'Brassard Hilo (AKTIIA C…)';

  @override
  String get onDemandBloodPressureVia => 'Tension à la demande via BLE';

  @override
  String get selectHiloPodWristband => 'Sélectionner le Hilo Pod (bracelet)';

  @override
  String get rescan => 'Relancer la recherche';

  @override
  String get noDevicesFoundTapTo =>
      'Aucun appareil trouvé. Touche ↻ pour relancer la recherche.';

  @override
  String get polarH10SpotHrv => 'Polar H10 · VFC ponctuelle';

  @override
  String get aSeparateHrvReadingBefore =>
      'Une mesure de VFC distincte avant ou après l\'entraînement. Ces mesures ne remplacent pas la VFC nocturne de Garmin et ne modifient pas ton score de préparation.';

  @override
  String get wearTheStrapWithMoist =>
      'Porte la ceinture avec les électrodes humidifiées. Reste immobile et respire normalement. Utilise la même posture et la même durée pour comparer. Après l\'entraînement, note combien de temps tu t\'es reposé d\'abord.';

  @override
  String get measurement => 'Mesure';

  @override
  String get posture => 'Posture';

  @override
  String get recordingLengthPlus1Min =>
      'Durée d\'enregistrement · plus 1 min de stabilisation';

  @override
  String get t2Minutes => '2 minutes';

  @override
  String get t5Minutes => '5 minutes';

  @override
  String get minutesSinceTrainingEndedOptional =>
      'Minutes depuis la fin de l\'entraînement (facultatif)';

  @override
  String get sessionOrNotesOptional => 'Séance ou notes (facultatif)';

  @override
  String connectName(Object name) {
    return 'Connecter $name';
  }

  @override
  String get findPolarH10 => 'Rechercher le Polar H10';

  @override
  String signalRssiDbm(Object rssi) {
    return 'Signal $rssi dBm';
  }

  @override
  String connectedName(Object name) {
    return 'Connecté : $name';
  }

  @override
  String get waitingForHeartRateAnd =>
      'En attente de la fréquence cardiaque et des intervalles RR. Vérifie le contact de la ceinture.';

  @override
  String get startMeasurement => 'Démarrer la mesure';

  @override
  String get cancelMeasurement => 'Annuler la mesure';

  @override
  String get spotHrvRmssd => 'VFC ponctuelle · RMSSD';

  @override
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  ) {
    return '$accepted/$length intervalles exploitables · $toStringAsFixed % de couverture';
  }

  @override
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs) {
    return 'lnRMSSD : $lnRmssd · RMSSD brut : $rawRmssdMs ms';
  }

  @override
  String get signalQualityIsTooLow =>
      'La qualité du signal est trop faible pour enregistrer. Refais la mesure avec un bon contact de la ceinture. Il faut au moins 95 % d\'intervalles exploitables et 90 % de couverture.';

  @override
  String get savedToSpotHrvHistory =>
      'Enregistré dans l\'historique de VFC ponctuelle.';

  @override
  String get newMeasurement => 'Nouvelle mesure';

  @override
  String get signalScreeningExcludesPoorContact =>
      'Le filtrage du signal exclut les mauvais contacts, les RR hors de 250–2500 ms et les intervalles à plus de 25 % de la médiane locale. Les lacunes ne sont pas comblées. Ce n\'est ni un test médical ni un score de préparation autonome.';

  @override
  String historyLabelLabel2DurationMin(
    Object label,
    Object label2,
    Object duration,
  ) {
    return 'Historique · $label · $label2 · $duration min';
  }

  @override
  String get onlyReadingsWithTheSame =>
      'Seules les mesures de même contexte, posture et durée sont affichées ensemble.';

  @override
  String get noMatchingMeasurementsYet =>
      'Aucune mesure correspondante pour l\'instant.';

  @override
  String tostringasfixedMsRmssdTostringasfixed2Bpm(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return '$toStringAsFixed ms RMSSD · $toStringAsFixed2 bpm';
  }

  @override
  String get exportRrIntervalsCsv => 'Exporter les intervalles RR (CSV)';

  @override
  String get deleteMeasurement => 'Supprimer la mesure';

  @override
  String get remindMeToMeasureHrv =>
      'Me rappeler de mesurer la VFC après l\'entraînement';

  @override
  String get appleHealthIsNoLonger => 'Apple Santé n\'est plus disponible';

  @override
  String get later => 'Plus tard';

  @override
  String get reconnect => 'Reconnecter';

  @override
  String get gripStrength => 'Force de préhension';

  @override
  String get leftKg => 'Gauche (kg)';

  @override
  String get rightKg => 'Droite (kg)';

  @override
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg) {
    return 'G $leftKg · D $rightKg kg';
  }

  @override
  String get notificationsAreOffYouCan =>
      'Les notifications sont désactivées. Tu peux toujours mesurer depuis ta séance.';

  @override
  String get noRemindersFrom2200 => 'Aucun rappel de 22:00 à 07:00';

  @override
  String get aReminderThatWouldFall =>
      'Un rappel qui tomberait dans cette plage est ignoré, pas reporté au matin.';

  @override
  String get remindersArriveQuietlyInThe =>
      'Les rappels arrivent discrètement dans la liste des notifications.';

  @override
  String get noForecastForThisDay => 'Aucune prévision pour ce jour';

  @override
  String get fullscreen => 'Plein écran';

  @override
  String source(Object source) {
    return '● $source';
  }

  @override
  String get shadedAreaProviderSpread =>
      'Zone ombrée : écart entre fournisseurs';

  @override
  String get temperatureC => '● Température °C';

  @override
  String get rainMm => '▥ Pluie mm';

  @override
  String get uvIndex => '— Indice UV';

  @override
  String get closeFullscreenWeatherChart =>
      'Fermer le graphique météo en plein écran';

  @override
  String get sleepStages => 'PHASES DE SOMMEIL';

  @override
  String get noStageTimelineForThis =>
      'Aucune chronologie des phases pour cette nuit.';

  @override
  String round3(Object round) {
    return '$round%';
  }

  @override
  String get examplesOnlyCheckAndEnter =>
      'Exemples uniquement : vérifie et saisis les valeurs de l\'étiquette de ton produit par portion. Laisse vides les nutriments inconnus ; saisis 0 seulement si la valeur est connue.';

  @override
  String get nutritionStrategy => 'Stratégie nutritionnelle';

  @override
  String get noPreWorkoutNutritionStrategy =>
      'Aucune stratégie nutritionnelle d\'avant-séance n\'a été enregistrée.';

  @override
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium) {
    return '$carbs g de glucides/h · $fluid ml/h · $sodium mg de sodium/h';
  }

  @override
  String get forecastUpdatedReviewOrRecalculate =>
      'Prévisions mises à jour : vérifie ou recalcule la stratégie enregistrée.';

  @override
  String strategySavedSavedat(Object savedAt) {
    return 'Stratégie enregistrée $savedAt';
  }

  @override
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  ) {
    return 'Total pendant l\'effort : $totalCarbs g de glucides · $totalFluid ml · $totalSodium mg de sodium';
  }

  @override
  String every20MinAboutCarbs(Object carbs, Object fluid) {
    return 'Toutes les 20 min : environ $carbs g de glucides et $fluid ml.';
  }

  @override
  String get packQuantitiesIncludeFullContainers =>
      'Les quantités à emporter comptent des contenants entiers ; il n\'est pas obligatoire de tout consommer.';

  @override
  String get workoutChangedReviewOrRecalculate =>
      'Séance modifiée : vérifie ou recalcule la stratégie enregistrée.';

  @override
  String get conditionsAndFeedingPlan => 'Conditions et plan d\'alimentation';

  @override
  String get editStrategy => 'Modifier la stratégie';

  @override
  String get recalculate => 'Recalculer';

  @override
  String get actualNutrition => 'Nutrition réelle';

  @override
  String get someProductValuesAreUnknown =>
      'Certaines valeurs de produits sont inconnues ; les totaux sont incomplets.';

  @override
  String get logFoodAndFluids => 'Enregistrer aliments et liquides';

  @override
  String get recordWhatYouActuallyHad =>
      'Note ce que tu as réellement consommé. L\'apport prévu n\'est pas copié dans ce journal.';

  @override
  String get elapsedMinutesIncludingStopsOptional =>
      'Minutes écoulées, arrêts compris (facultatif)';

  @override
  String recordedDurationActivityMin(Object activity) {
    return 'Durée enregistrée : $activity min';
  }

  @override
  String get compareWithSavedStrategy =>
      'Comparer avec la stratégie enregistrée';

  @override
  String get useMatchedSessionIfAvailable =>
      'Utiliser la séance correspondante si disponible';

  @override
  String get noPlanComparison => 'Aucune comparaison avec le plan';

  @override
  String titleDate(Object title, Object date) {
    return '$title · $date';
  }

  @override
  String get linkedStrategyUnavailable => 'Stratégie liée indisponible';

  @override
  String quantityName(Object quantity, Object name) {
    return '$quantity × $name';
  }

  @override
  String get removeIntake => 'Supprimer l\'apport';

  @override
  String get addFoodOrDrink => 'Ajouter un aliment ou une boisson';

  @override
  String get iHadNoIntake => 'Je n\'ai rien consommé';

  @override
  String get giGutComfort => 'Confort digestif';

  @override
  String get whatWorkedSymptomsAccessProblems =>
      'Ce qui a marché / symptômes / problèmes d\'accès';

  @override
  String get saveDraft => 'Enregistrer le brouillon';

  @override
  String get skipLoggingThisActivity => 'Ne pas enregistrer cette activité';

  @override
  String get nutritionAndFluids => 'Nutrition et hydratation';

  @override
  String get productsToleranceAndMeasuredSweat =>
      'Produits, tolérance et pertes de sueur mesurées';

  @override
  String get postWorkoutIntakeReminder =>
      'Rappel d\'apport après l\'entraînement';

  @override
  String get onceAfterARecentEndurance =>
      'Une fois après une séance d\'endurance récente ; heures calmes 22:00–08:00.';

  @override
  String get addHiloBpReport => 'Ajouter un rapport de tension Hilo';

  @override
  String get readingPdfReportsIsOnly =>
      'La lecture des rapports PDF n\'est disponible que sur iOS et macOS.';

  @override
  String get chooseAnotherReport => 'Choisir un autre rapport';

  @override
  String get biologicalAge => 'Âge biologique';

  @override
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class) {
    return 'VO₂max $vo2max ml/kg/min · $vo2Class';
  }

  @override
  String get factorContributions => 'Contribution des facteurs';

  @override
  String estimatedRangeRoundRound2Years(Object round, Object round2) {
    return 'Plage estimée : $round–$round2 ans. Estimation d\'un modèle, pas un diagnostic médical.';
  }

  @override
  String get noEnergyMeasurementsForThis =>
      'Aucune mesure d\'énergie pour ce jour';

  @override
  String get scanningStepOnTheScale =>
      'Recherche… monte sur la balance quand tu es prêt.';

  @override
  String waistWaistCmUpdateMonthly(Object waist) {
    return 'Tour de taille : $waist cm – à mettre à jour chaque mois dans Profil';
  }

  @override
  String get measuring => 'Mesure…';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get systolic => 'Systolique';

  @override
  String get diastolic => 'Diastolique';

  @override
  String get heartRate => 'Fréquence cardiaque';

  @override
  String get weight => 'Poids';

  @override
  String get bodyFat => 'Masse grasse';

  @override
  String get duration => 'Durée';

  @override
  String get deep => 'Profond';

  @override
  String get spo => 'SpO₂';

  @override
  String get activityName => 'Nom de l\'activité';

  @override
  String get sport => 'Sport';

  @override
  String get distance => 'Distance';

  @override
  String get saved => 'Enregistré';

  @override
  String get connectionFailedCheckYourInternet =>
      'Échec de la connexion. Vérifie ta connexion internet.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordTooShort => 'Mot de passe trop court';

  @override
  String get loginFailedCheckYourEmail =>
      'Échec de la connexion. Vérifie ton e-mail et ton mot de passe.';

  @override
  String get connectionFailedCheckYourCredentials =>
      'Échec de la connexion. Vérifie tes identifiants et ta connexion internet.';

  @override
  String get region => 'Région';

  @override
  String get hiloPod => 'Hilo Pod';

  @override
  String get hiloAccount => 'Compte Hilo';

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
  String get renphoAccount => 'Compte Renpho';

  @override
  String get garminConnectEmail => 'E-mail Garmin Connect';

  @override
  String get verifyMfaCode => 'Vérifier le code MFA';

  @override
  String get verificationCode => 'Code de vérification';

  @override
  String errorE(Object e) {
    return 'Erreur : $e';
  }

  @override
  String get noHiloPodFoundMake =>
      'Aucun Hilo Pod trouvé. Vérifie qu\'il est chargé et à proximité.';

  @override
  String scanFailedE(Object e) {
    return 'Échec de la recherche : $e';
  }

  @override
  String get hiloPod2 => 'Hilo Pod';

  @override
  String get scanForPod => 'Rechercher le pod';

  @override
  String get scanForPolarH10 => 'Rechercher le Polar H10';

  @override
  String get couldNotReachPolarCheck =>
      'Impossible de joindre Polar. Vérifie ta connexion.';

  @override
  String get signInAndSendWorkout => 'Se connecter et envoyer la séance';

  @override
  String get scanForScale => 'Rechercher la balance';

  @override
  String get passwordRequired => 'Mot de passe requis';

  @override
  String get enterYourPhoneNumberWith =>
      'Saisis ton numéro de téléphone (avec l\'indicatif du pays, p. ex. +33…) et ton e-mail Suunto.';

  @override
  String get enterThePinFromThe => 'Saisis le code PIN reçu par SMS.';

  @override
  String get incorrectPinPleaseTryAgain => 'PIN incorrect. Réessaie.';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get suuntoAccountEmail => 'E-mail du compte Suunto';

  @override
  String get enterPinFromSms => 'Saisir le PIN reçu par SMS';

  @override
  String get verifyConnect => 'Vérifier et connecter';

  @override
  String get sendSmsCode => 'Envoyer le code par SMS';

  @override
  String couldNotSavePreferencesE(Object e) {
    return 'Impossible d\'enregistrer les préférences : $e';
  }

  @override
  String get mon => 'Lun';

  @override
  String get tue => 'Mar';

  @override
  String get wed => 'Mer';

  @override
  String get thu => 'Jeu';

  @override
  String get fri => 'Ven';

  @override
  String get sat => 'Sam';

  @override
  String get sun => 'Dim';

  @override
  String get male => 'Homme';

  @override
  String get female => 'Femme';

  @override
  String get other => 'Autre';

  @override
  String get running => 'Course à pied';

  @override
  String get trailRunning => 'Course en sentier';

  @override
  String get cycling => 'Cyclisme';

  @override
  String get swimming => 'Natation';

  @override
  String get triathlon => 'Triathlon';

  @override
  String get hiking => 'Randonnée';

  @override
  String get rowing => 'Aviron';

  @override
  String get buildMyPlan => 'Créer mon plan';

  @override
  String get keepAConsistentBedtimeAnd =>
      'Garde des heures de coucher et de lever régulières pour soutenir ta routine de sommeil.';

  @override
  String get thisWorkoutHasNoSets => 'Cette séance n\'a aucune série.';

  @override
  String loadName(Object name) {
    return 'Charge ($name)';
  }

  @override
  String get setLabel => 'Série';

  @override
  String get lowestReps => 'Répétitions minimales';

  @override
  String get highestReps => 'Répétitions maximales';

  @override
  String get repsPerSide => 'Répétitions par côté';

  @override
  String get fromReps => 'De (rép.)';

  @override
  String get toReps => 'À (rép.)';

  @override
  String get addedLoad => 'Charge ajoutée';

  @override
  String get assistance => 'Assistance';

  @override
  String get tempoOptional => 'Tempo (facultatif)';

  @override
  String get notesOptional => 'Notes (facultatif)';

  @override
  String get enterTheRepetitionsDone => 'Saisis les répétitions effectuées.';

  @override
  String plannedUnit(Object unit) {
    return 'Prévu $unit';
  }

  @override
  String get repsDone => 'Répétitions effectuées';

  @override
  String get resistance => 'Résistance';

  @override
  String get implementsLabel => 'Accessoires';

  @override
  String get name => 'Nom';

  @override
  String get instructionsOptional => 'Instructions (facultatif)';

  @override
  String get remember => 'Mémoriser';

  @override
  String get notSavedYet => 'Pas encore enregistré';

  @override
  String get saving => 'Enregistrement…';

  @override
  String get couldNotSave => 'Impossible d\'enregistrer';

  @override
  String get plannedValuesAreHintsNot =>
      'Les valeurs prévues sont des indications, pas des résultats. Touche une série pour l\'enregistrer.';

  @override
  String get completedAsPlanned => 'Terminé comme prévu';

  @override
  String get save => 'Enregistrer';

  @override
  String get nameTheTemplate => 'Nomme le modèle.';

  @override
  String setN(Object n) {
    return 'Série $n';
  }

  @override
  String get changesApplyToThisWorkout =>
      'Les modifications ne s\'appliquent qu\'à cette séance. Les séances terminées et les autres restent inchangées.';

  @override
  String get saveForThisWorkout => 'Enregistrer pour cette séance';

  @override
  String knownForKnownOfOf(Object known, Object of) {
    return 'Connu pour $known séries chargées sur $of';
  }

  @override
  String get sessionEstimate => 'Estimation de la séance';

  @override
  String get calculatedRange => 'Plage calculée';

  @override
  String get timedWork => 'Travail chronométré';

  @override
  String get strengthTraining => 'Renforcement musculaire';

  @override
  String get theExercisesCouldNotBe => 'Impossible de charger les exercices.';

  @override
  String get resumeWorkout => 'Reprendre la séance';

  @override
  String get strengthWorkout => 'Séance de renforcement';

  @override
  String get untitledTemplate => 'Modèle sans titre';

  @override
  String get theRecordedExercisesCouldNot =>
      'Impossible de charger les exercices enregistrés.';

  @override
  String get exercisesPerformed => 'Exercices effectués';

  @override
  String get comparedWithThePlanAs =>
      'Comparé au plan tel qu\'il était au début de l\'enregistrement.';

  @override
  String topWorkingLoadName(Object name) {
    return 'Charge de travail maximale ($name)';
  }

  @override
  String get estimated1rmMiddleOfRange => '1RM estimé, milieu de la plage';

  @override
  String get noLoggedSessionsYet =>
      'Aucune séance enregistrée pour l\'instant.';

  @override
  String get noRadarFramesAvailable => 'Aucune image radar disponible';

  @override
  String get playRadar => 'Lire le radar';

  @override
  String get pauseRadar => 'Mettre le radar en pause';

  @override
  String get high => 'Élevé';

  @override
  String get clear => 'Dégagé';

  @override
  String get bodyweight => 'Poids du corps';

  @override
  String get resistance2 => 'Résistance —';

  @override
  String assistUnit(Object unit) {
    return 'Assistance $unit';
  }

  @override
  String get reps2 => 'Rép. —';

  @override
  String get notRecorded => 'Non enregistré';

  @override
  String get skipped => 'Ignoré';

  @override
  String get health => 'Santé';

  @override
  String get manual => 'Manuel';

  @override
  String expandName(Object name) {
    return 'Développer $name';
  }

  @override
  String get open => 'Ouvrir';

  @override
  String get noScalePaired => 'Aucune balance associée';

  @override
  String get paired => 'Associé';

  @override
  String get change => 'Modifier';

  @override
  String get noCuffPaired => 'Aucun brassard associé';

  @override
  String get noPolarH10FoundWear =>
      'Aucun Polar H10 trouvé. Porte la ceinture, humidifie les électrodes et vérifie qu\'aucune autre app n\'utilise les deux connexions Bluetooth.';

  @override
  String get enterMinutesSinceTrainingEnded =>
      'Saisis les minutes écoulées depuis la fin de l\'entraînement, de 0 à 1440.';

  @override
  String get timingFollowsYourWorkout => 'Le moment suit ta séance.';

  @override
  String get recordingStayStill => 'Enregistrement · reste immobile';

  @override
  String get meanHrBpm => 'FC moyenne · bpm';

  @override
  String get pairAPolarH10First => 'Associe d\'abord un Polar H10.';

  @override
  String get around30MinutesAfterTraining =>
      'Environ 30 minutes après l\'entraînement, lorsque la séance est disponible à temps.';

  @override
  String get reminderDiagnostics => 'Diagnostic des rappels';

  @override
  String get forecast => 'Prévisions';

  @override
  String get enterAName => 'Saisis un nom';

  @override
  String get enterAValidAmount => 'Saisis une quantité valide';

  @override
  String get enterAPositiveAmount => 'Saisis une quantité positive';

  @override
  String get maximum120GH => 'Maximum 120 g/h';

  @override
  String get carbohydrateTargetGH => 'Objectif glucides g/h';

  @override
  String get fluidTargetMlH => 'Objectif liquides ml/h';

  @override
  String get sodiumTargetMgHNot => 'Objectif sodium mg/h (pas le sel)';

  @override
  String get surfaceFeedingAccess => 'Surface / accès au ravitaillement';

  @override
  String get expectedAscentM => 'Dénivelé positif prévu m';

  @override
  String get expectedAltitudeM => 'Altitude prévue m';

  @override
  String get humidity => 'Humidité %';

  @override
  String get windKmH => 'Vent km/h';

  @override
  String get dayForecast => 'Prévisions du jour';

  @override
  String get enteredConditions => 'Conditions saisies';

  @override
  String get productFoodName => 'Nom du produit / aliment';

  @override
  String get servingsQuantity => 'Portions / quantité';

  @override
  String get when => 'Quand';

  @override
  String get carbohydrateGServing => 'Glucides g / portion';

  @override
  String get fluidMlServing => 'Liquide ml / portion';

  @override
  String get caffeineMgServing => 'Caféine mg / portion';

  @override
  String get proteinGServing => 'Protéines g / portion';

  @override
  String get gel => 'Gel';

  @override
  String get water => 'Eau';

  @override
  String get sportsDrink => 'Boisson sportive';

  @override
  String get bar => 'Barre';

  @override
  String get finishIntakeLog => 'Terminer le journal d\'apport';

  @override
  String get importing => 'Importation…';

  @override
  String importNewreadings(Object newReadings) {
    return 'Importer $newReadings';
  }

  @override
  String get reading => 'Lecture…';

  @override
  String get chooseReportPdf => 'Choisir un rapport (PDF)';

  @override
  String get yourTrainingHistoryIsReady =>
      'Ton historique d\'entraînement est prêt';

  @override
  String get importingYourTrainingHistory =>
      'Importation de ton historique d\'entraînement';

  @override
  String get stopImport => 'Arrêter l\'importation';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get openai => 'OpenAI';

  @override
  String get appleIntelligence => 'Apple Intelligence';

  @override
  String get nonAiBriefing => 'Briefing sans IA';

  @override
  String get noBriefing => 'Aucun briefing';

  @override
  String get ruleBasedSummaryFromYour =>
      'Résumé basé sur des règles à partir de tes données de santé – aucun appel d\'API';

  @override
  String get hideTheBriefingCard => 'Masquer la carte de briefing';

  @override
  String get flutter => 'Flutter';

  @override
  String get stateManagement => 'Gestion d\'état';

  @override
  String get bluetoothLe => 'Bluetooth LE';

  @override
  String get interactiveMaps => 'Cartes interactives';

  @override
  String get chartsGraphs => 'Graphiques et diagrammes';

  @override
  String get secureCredentialStorage => 'Stockage sécurisé des identifiants';

  @override
  String get markdownRendering => 'Rendu Markdown';

  @override
  String get appleOnDeviceAi => 'IA Apple sur l\'appareil';

  @override
  String get cryptography => 'Cryptographie';

  @override
  String get appleHealthHealthConnect => 'Apple Santé et Health Connect';

  @override
  String get runtimePermissions => 'Autorisations d\'exécution';

  @override
  String get shareExport => 'Partage et export';

  @override
  String get openUrls => 'Ouvrir des URL';

  @override
  String get internationalisation => 'Internationalisation';

  @override
  String get utilities => 'Utilitaires';

  @override
  String get icons => 'Icônes';

  @override
  String get fjelia => 'Fjelia';

  @override
  String get fjeliaFeedback => 'Retour sur Fjelia';

  @override
  String get couldNotSendTheReport =>
      'Impossible d\'envoyer le rapport. Ton texte est toujours là. Réessaie.';

  @override
  String get yourEmail => 'Ton e-mail';

  @override
  String get enterAValidEmailAddress => 'Saisis une adresse e-mail valide.';

  @override
  String get subject => 'Objet';

  @override
  String get sending => 'Envoi…';

  @override
  String get sendReport => 'Envoyer le rapport';

  @override
  String get sleepRecovery => 'Sommeil et récupération';

  @override
  String get activitiesTraining => 'Activités et entraînement';

  @override
  String get bodyWellness => 'Corps et bien-être';

  @override
  String get hilo => 'Hilo';

  @override
  String get hiloBle => 'Hilo BLE';

  @override
  String get garminApi => 'Garmin (API)';

  @override
  String get renphoScale => 'Balance Renpho';

  @override
  String get connected => 'Connecté';

  @override
  String get notConnected => 'Non connecté';

  @override
  String get manage => 'Gérer';

  @override
  String get connect => 'Connecter';

  @override
  String get habits => 'Habitudes';

  @override
  String get smokingAlcohol => 'Tabac, alcool';

  @override
  String get clinicalLab => 'Analyses';

  @override
  String get hba1cLipidsKidney => 'HbA1c, lipides, reins';

  @override
  String get sex => 'Sexe';

  @override
  String get smoking => 'Tabagisme';

  @override
  String get never => 'Jamais';

  @override
  String get former => 'Ancien';

  @override
  String get current => 'Actuel';

  @override
  String get hba1c => 'HbA1c';

  @override
  String get diabetes => 'Diabète';

  @override
  String get prediabetes => 'Prédiabète';

  @override
  String get type1 => 'Type 1';

  @override
  String get type2 => 'Type 2';

  @override
  String get apob => 'ApoB';

  @override
  String get optionalPlansAndPaceGuides =>
      'Facultatif. Les plans et les repères d\'allure l\'utilisent ; le dénivelé ci-dessus influence aussi l\'entraînement.';

  @override
  String get addRaceGoal2 => 'Ajouter un objectif de course';

  @override
  String get editRaceGoal => 'Modifier l\'objectif de course';

  @override
  String get trailRunning2 => 'Course en sentier';

  @override
  String get roadCycling => 'Cyclisme sur route';

  @override
  String get gravel => 'Gravel';

  @override
  String get indoorRowing => 'Aviron en salle';

  @override
  String get selectDate => 'Choisir la date';

  @override
  String get committed => 'Engagé';

  @override
  String get flexible => 'Flexible';

  @override
  String get notGoing => 'Pas de participation';

  @override
  String get notSaid => 'Non précisé';

  @override
  String get finish => 'Temps d\'arrivée';

  @override
  String get saveGoal => 'Enregistrer l\'objectif';

  @override
  String get exportAllRecordedWorkoutsAs =>
      'Exporter toutes les séances enregistrées sous forme de tableur.';

  @override
  String get backupsIncludeYourHealthData =>
      'Les sauvegardes incluent tes données de santé, tes plans d\'entraînement et les réglages du profil. Les identifiants de connexion sont exclus. La restauration remplace les données locales.';

  @override
  String get trail => 'Sentier';

  @override
  String get inlineSkating => 'Roller en ligne';

  @override
  String get nordicClassic => 'Ski nordique classique';

  @override
  String get skateSkiing => 'Ski de skating';

  @override
  String get strength => 'Renforcement';

  @override
  String get walking => 'Marche';

  @override
  String get yoga => 'Yoga';

  @override
  String get skiing => 'Ski';

  @override
  String get climbing => 'Escalade';

  @override
  String get monday => 'Lundi';

  @override
  String get sunday => 'Dimanche';

  @override
  String get month => 'Mois';

  @override
  String get week => 'Semaine';

  @override
  String get list => 'Liste';

  @override
  String get train => 'Entraînement';

  @override
  String get restDay => 'Repos';

  @override
  String get kilogramsKg => 'Kilogrammes (kg)';

  @override
  String get poundsLb => 'Livres (lb)';

  @override
  String get regenerateWorkouts => 'Régénérer les séances';

  @override
  String get starting => 'Démarrage';

  @override
  String get allPlannedWorkoutsDeleted =>
      'Toutes les séances prévues ont été supprimées.';

  @override
  String get searching => 'Recherche…';

  @override
  String get searchCity => 'Rechercher une ville';

  @override
  String get fixedLocationSavedWeatherWill =>
      'Position fixe enregistrée. La météo va s\'actualiser.';

  @override
  String get locationDisabledThePlanWeather =>
      'Position désactivée. La carte météo du plan est masquée.';

  @override
  String locationSetToName(Object name) {
    return 'Position définie sur $name';
  }

  @override
  String get notEnoughDaytimeAndNighttime =>
      'Pas assez de mesures de jour et de nuit';

  @override
  String get onlyTheWeightWasReceived =>
      'Seul le poids a été reçu. Pour la masse grasse, les muscles et les autres valeurs, reste pieds nus sur les électrodes métalliques jusqu\'à la fin de la mesure.';

  @override
  String get addYourWaistInProfile =>
      'Ajoute ton tour de taille dans Profil pour la graisse viscérale.';

  @override
  String get manualActivity => 'Activité manuelle';

  @override
  String get theseCredentialsAreStoredEncrypted =>
      'Ces identifiants sont stockés chiffrés sur ton appareil (trousseau iOS / Android Keystore). Ils ne sont jamais envoyés à un autre serveur que Hilo.';

  @override
  String get corosCredentialsAreStoredEncrypted =>
      'Les identifiants Coros sont stockés chiffrés sur ton appareil. Fjelia lit les données directement via l\'API cloud de Coros, la même que l\'application web Coros Training Hub.';

  @override
  String get connectAnyCombinationYouCan =>
      'Connecte la combinaison de ton choix – tu pourras toujours en ajouter plus tard dans les réglages.';

  @override
  String get garminCredentialsAreStoredEncrypted =>
      'Les identifiants Garmin sont stockés chiffrés sur ton appareil. Fjelia utilise l\'API Garmin Connect non officielle, la même approche que de nombreuses apps communautaires.';

  @override
  String get enterTheVerificationCode => 'Saisir le code de vérification';

  @override
  String get appleHealthDataAccess =>
      'Fjelia lit tes données de santé depuis Apple Santé. Avec ton autorisation, elle peut aussi y écrire des données synchronisées. Gère les accès dans les réglages de ton appareil.';

  @override
  String get scanAgain => 'Rechercher à nouveau';

  @override
  String get wearTheHiloBandDuring =>
      'Porte le bracelet Hilo pendant le sommeil pour un suivi continu de la tension. Les données se synchronisent automatiquement chaque matin à l\'ouverture de l\'app.';

  @override
  String get noPolarH10FoundWear2 =>
      'Aucun Polar H10 trouvé. Porte la ceinture avec les électrodes humides et vérifie qu\'aucune autre app (ou montre) n\'y est connectée, puis relance la recherche.';

  @override
  String get wearTheStrapWithMoist2 =>
      'Porte la ceinture avec les électrodes humides avant la recherche. Mesure ensuite via + → Mesure VFC Polar H10 ; les résultats apparaissent à côté de ta VFC nocturne.';

  @override
  String get signedInPlannedWorkoutsCan =>
      'Connecté. Les séances prévues peuvent maintenant être envoyées à Polar. Les séances plus anciennes sont importées lors de la prochaine synchronisation complète de l\'historique.';

  @override
  String get saveYourPolarFlowLogin =>
      'Enregistre ta connexion Polar Flow pour envoyer des séances prévues et importer des séances de plus de 30 jours. Elle reste dans le trousseau de cet appareil et n\'est envoyée qu\'à Polar. Envoie une séance depuis sa fiche du planning, puis synchronise Polar Flow avec ta montre. Vérifie que tes zones de fréquence cardiaque Polar correspondent à celles de Fjelia.';

  @override
  String get signInToSendThis =>
      'Connecte-toi pour envoyer cette séance à ton calendrier Polar Flow. Ta connexion reste dans le trousseau de cet appareil et n\'est envoyée qu\'à Polar. Après l\'envoi, synchronise Polar Flow avec ta montre.';

  @override
  String get checkAndSave => 'Vérifier et enregistrer';

  @override
  String get noScaleFoundStepOn =>
      'Aucune balance trouvée. Monte sur la balance pour la réveiller, puis relance la recherche.';

  @override
  String get stepOnTheScaleBefore =>
      'Monte sur la balance avant la recherche pour la réveiller. Plus tard, utilise + → Balance RENPHO pour mesurer.';

  @override
  String get renphoCredentialsAreStoredEncrypted =>
      'Les identifiants Renpho sont stockés chiffrés sur ton appareil. Fjelia communique directement avec l\'API cloud de Renpho.';

  @override
  String get couldNotSendSmsCheck =>
      'Impossible d\'envoyer le SMS. Vérifie ton numéro de téléphone et ta connexion internet.';

  @override
  String get theEmailIsUsedFor =>
      'L\'e-mail sert à signer les requêtes de façon sécurisée et n\'est pas envoyé aux serveurs Suunto.';

  @override
  String get suuntoUsesSmsVerificationSame =>
      'Suunto utilise la vérification par SMS (comme l\'app Suunto). Un code PIN à usage unique sera envoyé sur ton téléphone. Tes identifiants sont stockés chiffrés uniquement sur l\'appareil.';

  @override
  String get tellUsAboutYourRace =>
      'Parle-nous de ta course et de ton emploi du temps. Fjelia construit ton plan maintenant et détermine ton niveau à partir de tes activités passées (Garmin, Suunto, Polar, COROS, Apple Santé) une fois téléchargées.';

  @override
  String get noAccountConnectedSoFjelia =>
      'Aucun compte connecté, donc Fjelia n\'a pas d\'historique pour apprendre. Connecte Garmin, Suunto, Polar, COROS ou Apple Santé et ton entraînement réel décidera.';

  @override
  String get yourPastActivitiesAreStill =>
      'Tes activités passées sont encore en cours d\'importation. Tu peux déjà créer ton plan – il sera affiné automatiquement à la fin de l\'importation.';

  @override
  String get buildingYourPlan => 'Création de ton plan…';

  @override
  String get saveContinue => 'Enregistrer et continuer';

  @override
  String get addYourMainPriorityA =>
      'Ajoute ta course principale (priorité A). Le plan est périodisé en fonction : base, développement, pic et affûtage. Sans objectif de course, aucun plan n\'est encore généré.';

  @override
  String get noMeasurementsYet => 'Aucune mesure pour l\'instant';

  @override
  String get date => 'Date';

  @override
  String deepSleepIsBelowOptimal(Object round) {
    return 'Le sommeil profond est inférieur à l\'optimum ($round %). Évite l\'alcool et les repas copieux 3 h avant le coucher.';
  }

  @override
  String get finishWithSetsOpen => 'Terminer avec des séries ouvertes ?';

  @override
  String get completeThePlannedWorkout => 'Terminer la séance prévue ?';

  @override
  String get marksThePlannedSessionAs =>
      'Marque la séance prévue comme terminée avec cette séance.';

  @override
  String get discardThisWorkout => 'Abandonner cette séance ?';

  @override
  String get removesTheWorkoutAndEvery =>
      'Supprime la séance et chaque série enregistrée.';

  @override
  String assistanceName(Object name) {
    return 'Assistance ($name)';
  }

  @override
  String get enterSecondsOrMSs => 'Saisis des secondes ou m:ss.';

  @override
  String get enterTheLoadAsA => 'Saisis la charge sous forme de nombre.';

  @override
  String get loadCannotBeNegative => 'La charge ne peut pas être négative.';

  @override
  String get enterTheEffortValue => 'Saisis la valeur d\'effort.';

  @override
  String get nameTheExercise => 'Nomme l\'exercice.';

  @override
  String get atLeastOneImplement => 'Au moins un accessoire.';

  @override
  String get anIncrementMustBePositive => 'Un incrément doit être positif.';

  @override
  String get enterAPositiveStep => 'Saisis un pas positif.';

  @override
  String get repsInReserve => 'Répétitions en réserve';

  @override
  String get loadPerImplement => 'Charge par accessoire';

  @override
  String get restAfterThisSet => 'Repos après cette série';

  @override
  String get enterHowLongTheSet => 'Saisis la durée de la série.';

  @override
  String get repsDonePerSide => 'Répétitions effectuées par côté';

  @override
  String plannedRepminRepmax(Object repMin, Object repMax) {
    return 'Prévu $repMin–$repMax';
  }

  @override
  String get restTakenBeforeTheNext => 'Repos pris avant la série suivante';

  @override
  String get equipment => 'Équipement';

  @override
  String get implementsUsedTogether => 'Accessoires utilisés ensemble';

  @override
  String get smallestLoadStepOptional =>
      'Plus petit pas de charge (facultatif)';

  @override
  String get theSmallestChangeYourPlates =>
      'La plus petite variation permise par tes disques, haltères ou machine, mémorisée pour cet équipement.';

  @override
  String get loadStep => 'Pas de charge';

  @override
  String get finishWithIncompleteData =>
      'Terminer avec des données incomplètes ?';

  @override
  String get leaveWithoutSaving => 'Quitter sans enregistrer ?';

  @override
  String get theLastChangeCouldNot =>
      'La dernière modification n\'a pas pu être enregistrée.';

  @override
  String get comparedWithAPlanChosen =>
      'Comparé à un plan choisi après la séance. Les valeurs prévues sont des indications, pas des résultats.';

  @override
  String get lastSet => 'Dernière série';

  @override
  String get templateName => 'Nom du modèle';

  @override
  String get betweenExercises => 'Entre les exercices';

  @override
  String get betweenRounds => 'Entre les tours';

  @override
  String get discardChanges => 'Abandonner les modifications ?';

  @override
  String get yourEditsToThisWorkout =>
      'Tes modifications de cette séance ne sont pas enregistrées.';

  @override
  String get estimatedDuration => 'Durée estimée';

  @override
  String get workingSets => 'Séries de travail';

  @override
  String get estimatedExternalVolume => 'Volume externe estimé';

  @override
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion) {
    return 'Charge passée de $unit à $unit2 après ta revue (règle v$ruleVersion).';
  }

  @override
  String get thePlannedWorkoutHasNo =>
      'La séance prévue ne contient aucun exercice à enregistrer.';

  @override
  String get completedSets => 'Séries terminées';

  @override
  String get knownExternalVolume => 'Volume externe connu';

  @override
  String get updateStrengthSessions2 =>
      'Mettre à jour les séances de renforcement ?';

  @override
  String get upcomingSessionsArePlannedAgain =>
      'Les séances à venir sont replanifiées à partir d\'aujourd\'hui : le renforcement suit tes objectifs de course à chaque jour de renforcement, avec des séances variées. Les séances terminées et ignorées sont conservées ; les exercices que tu as modifiés dans une prochaine séance de renforcement sont remplacés.';

  @override
  String get thisSessionUsesAnEarlier =>
      'Cette séance utilise un ancien modèle de renforcement. Les plans mis à jour varient le renforcement selon la phase et l\'objectif de course et utilisent chaque jour de renforcement.';

  @override
  String get estimated1rmUsesEpleyAnd =>
      'Le 1RM estimé utilise Epley et Brzycki sur les séries de travail terminées de 1 à 10 répétitions avec une charge connue, affiché comme la plage entre les deux. C\'est une estimation, pas un maximum testé.';

  @override
  String get localWeather => 'Météo locale';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get low => 'Faible';

  @override
  String get moderate => 'Modéré';

  @override
  String get overcast => 'Couvert';

  @override
  String get partlyCloudy => 'Partiellement nuageux';

  @override
  String collapseName(Object name) {
    return 'Réduire $name';
  }

  @override
  String get variableLoads => 'Charges variables';

  @override
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  ) {
    return 'Règle v$strengthProgressionRuleVersion : les $strengthProgressionMinSessions dernières séances comparables, chaque série au sommet de sa cible de répétitions, avec effort enregistré et pas plus dur que prévu. $reason';
  }

  @override
  String get stepOnYourScaleBefore => 'Monte sur ta balance avant la recherche';

  @override
  String get scanning => 'Recherche…';

  @override
  String get pair => 'Associer';

  @override
  String get selectYourAktiiaPWristband =>
      'Sélectionne ton bracelet AKTIIA P…. Pose-le sur le chargeur pour le réveiller s\'il n\'apparaît pas.';

  @override
  String get measurementInterruptedWhileTheApp =>
      'Mesure interrompue pendant que l\'app était en arrière-plan. Refais-la.';

  @override
  String get noRecentRrDataWith =>
      'Aucune donnée RR récente avec un bon contact. Vérifie la ceinture et refais la mesure.';

  @override
  String get settlingStayStill => 'Stabilisation · reste immobile';

  @override
  String get deleteSpotHrvMeasurement =>
      'Supprimer la mesure de VFC ponctuelle ?';

  @override
  String get thisRemovesTheRecordingAnd =>
      'Cela supprime l\'enregistrement et ses intervalles RR bruts.';

  @override
  String get appleHealthStoppedAnsweringSo =>
      'Apple Santé ne répond plus, Fjelia l\'a donc déconnecté et ne lit ni n\'écrit plus de données de santé.\n\nAutorise à nouveau Fjelia dans Réglages → Santé → Accès aux données et appareils → Fjelia, puis reconnecte Apple Santé.';

  @override
  String get thisRemovesTheSelectedGrip =>
      'Cela supprime la mesure de force de préhension sélectionnée.';

  @override
  String get hideReminderDiagnostics => 'Masquer le diagnostic des rappels';

  @override
  String get loading => 'Chargement…';

  @override
  String get touchTheChartForDetails => 'Touche le graphique pour les détails';

  @override
  String get indoor => 'Intérieur';

  @override
  String get road => 'Route';

  @override
  String get technical => 'Technique';

  @override
  String get snow => 'Neige';

  @override
  String get pool => 'Piscine';

  @override
  String get openWater => 'Eau libre';

  @override
  String get ambientTemperatureC => 'Température ambiante °C';

  @override
  String carryAboutGelsGelsGelcarbs(
    Object gels,
    Object gelCarbs,
    Object bottles,
    Object bottleMl,
    Object drinkCarbs,
  ) {
    return 'Emporte environ $gels gels ($gelCarbs g de glucides chacun) + $bottles × bidons de $bottleMl ml. $drinkCarbs g de glucides proviennent de la poudre de boisson.';
  }

  @override
  String get intakeNotRecorded => 'Apport non enregistré';

  @override
  String get loggingDeclinedIntakeUnknown =>
      'Enregistrement refusé – apport inconnu';

  @override
  String get confirmedNoIntake => 'Confirmé : aucun apport';

  @override
  String get draft => 'Brouillon · ';

  @override
  String get actualIntakePerServing => 'Apport réel · par portion';

  @override
  String get minuteIntoWorkoutDuringOnly =>
      'Minute de la séance (pendant seulement, facultatif)';

  @override
  String get sodiumMgServingNotSalt => 'Sodium mg / portion (pas le sel)';

  @override
  String get comfortable => 'Confortable';

  @override
  String get mildSymptoms => 'Symptômes légers';

  @override
  String get moderateSymptoms => 'Symptômes modérés';

  @override
  String get severeSymptoms => 'Symptômes sévères';

  @override
  String get personalNutritionSettings => 'Réglages nutritionnels personnels';

  @override
  String get practisedCarbohydrateToleranceGH =>
      'Tolérance aux glucides entraînée g/h (jusqu\'à 120)';

  @override
  String get exportTheMonthlyReportAs =>
      'Exporte le rapport mensuel en PDF dans l\'app Hilo, puis choisis-le ici. Seules les mesures sont importées ; le nom, l\'e-mail et les données corporelles du rapport sont ignorés.';

  @override
  String get nothingNewAllReadingsWere =>
      'Rien de nouveau : toutes les mesures étaient déjà enregistrées.';

  @override
  String get historyImportIncomplete =>
      'Importation de l\'historique incomplète';

  @override
  String get youCanKeepUsingFjelia =>
      'Tu peux continuer à utiliser Fjelia, mais garde-la ouverte : iOS met l\'importation en pause quand l\'app est en arrière-plan et la reprend à la prochaine ouverture. Ton plan est calibré à la fin de l\'importation.';

  @override
  String get addYourBirthYearIn =>
      'Ajoute ton année de naissance dans Réglages → Profil pour voir ton estimation.';

  @override
  String get fitnessAge => 'Âge de forme';

  @override
  String get estLifespan => 'Espérance de vie est.';

  @override
  String get delta => 'Écart';

  @override
  String couldNotOpenKey(Object key) {
    return 'Impossible d\'ouvrir $key';
  }

  @override
  String get appleIntelligenceIsNotAvailable =>
      'Apple Intelligence n\'est pas disponible sur cet appareil. Utilisez Free AI ou choisissez un autre fournisseur.';

  @override
  String get personalisedMorningLunchAfternoonEvening =>
      'Résumé personnalisé du matin, midi, après-midi et soir';

  @override
  String get enterASubject => 'Saisis un objet.';

  @override
  String get message => 'Message';

  @override
  String get enterAMessageOfAt =>
      'Saisis un message d\'au moins 10 caractères.';

  @override
  String get garminConnect => 'Garmin Connect';

  @override
  String get hiloBloodPressure => 'Hilo (tension artérielle)';

  @override
  String get renphoBodyScale => 'Renpho (pèse-personne)';

  @override
  String get hiloPodCuff => 'Hilo Pod / brassard';

  @override
  String disconnectLabel(Object label) {
    return 'Déconnecter $label ?';
  }

  @override
  String get yourSavedMeasurementsWillRemain =>
      'Tes mesures enregistrées restent sur cet appareil.';

  @override
  String get notEnoughRecentHeartRate =>
      'Pas assez de données récentes de fréquence cardiaque pour ajuster les zones.';

  @override
  String get aerobicBase => 'Base aérobie';

  @override
  String get tempo => 'Tempo';

  @override
  String get lactateThreshold => 'Seuil lactique';

  @override
  String get birthYearHeightWaist =>
      'Année de naissance, taille, tour de taille';

  @override
  String get enterAValidValue => 'Saisis une valeur valide';

  @override
  String get birthYear => 'Année de naissance';

  @override
  String get height => 'Taille';

  @override
  String get waist => 'Tour de taille';

  @override
  String get yearsSinceQuit => 'Années depuis l\'arrêt';

  @override
  String get cigarettesPerDay => 'Cigarettes par jour';

  @override
  String get standardDrinksPerMonth => 'Verres standard par mois';

  @override
  String get enterAValidNumber => 'Saisis un nombre valide';

  @override
  String get enterARaceName => 'Saisis un nom de course';

  @override
  String get useHMmOrH =>
      'Utilise h:mm ou h:mm:ss, un temps que tu pourrais vraiment courir';

  @override
  String get flexibleThePlanMayDrop =>
      'Flexible : le plan peut abandonner cet événement s\'il entre en conflit avec un plus important.';

  @override
  String get selectARaceDate => 'Choisis une date de course';

  @override
  String thatIsTenTimesOr(Object likely) {
    return 'C\'est dix fois (ou un dixième de) la distance habituelle de $likely km. Utiliser $likely km à la place ?';
  }

  @override
  String get addGoal => 'Ajouter l\'objectif';

  @override
  String get restoreFailed => 'Échec de la restauration';

  @override
  String get replaceLocalData => 'Remplacer les données locales ?';

  @override
  String get restoringThisBackupReplacesAll =>
      'Restaurer cette sauvegarde remplace tous les enregistrements locaux de santé et d\'entraînement. Les identifiants de connexion existants sont conservés.';

  @override
  String get openingBackupZip => 'Ouverture du ZIP de sauvegarde';

  @override
  String get addAFutureRaceGoal =>
      'Ajoute d\'abord un objectif de course à venir.';

  @override
  String get deleteAllWorkouts2 => 'Supprimer toutes les séances ?';

  @override
  String get thisDeletesPlannedWorkoutsOn =>
      'Cela supprime les séances prévues sur ce téléphone et sur ta plateforme de montre connectée. Les activités terminées sont conservées.';

  @override
  String get regenerateWorkouts2 => 'Régénérer les séances ?';

  @override
  String get noRaceGoalsYetAdd =>
      'Aucun objectif de course pour l\'instant. Ajoutes-en un ou synchronise depuis Garmin.';

  @override
  String get deleteRaceGoal => 'Supprimer l\'objectif de course ?';

  @override
  String deletingFailedFailure(Object failure) {
    return 'Échec de la suppression : $failure';
  }

  @override
  String allPlannedWorkoutsDeletedRemoved(Object removed) {
    return 'Toutes les séances prévues ont été supprimées. Supprimées de tes plateformes : $removed.';
  }

  @override
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return 'Utilisation de la position actuelle : $toStringAsFixed, $toStringAsFixed2';
  }

  @override
  String get typeSleep => 'Sommeil';

  @override
  String get typeBloodPressure => 'Tension artérielle';

  @override
  String get addHiloBpReportPdf => 'Ajouter un rapport de tension Hilo (PDF)';

  @override
  String get hiloCuffBle => 'Brassard Hilo (BLE)';

  @override
  String get typeSpo2 => 'SpO₂ / oxymètre de pouls';

  @override
  String get typeWeightScale => 'Pèse-personne';

  @override
  String get polarH10HrvMeasurement => 'Mesure VFC Polar H10';

  @override
  String samplingWouldStartMinutes(Object minutes) {
    return 'L\'échantillonnage commencerait environ $minutes min après la fin de ta séance.';
  }

  @override
  String samplingStartedMinutes(Object minutes) {
    return 'L\'échantillonnage a démarré $minutes min après la fin de ta séance.';
  }

  @override
  String get unknown => 'Inconnu';

  @override
  String get before => 'Avant';

  @override
  String get during => 'Pendant';

  @override
  String get after => 'Après';

  @override
  String get enumWarmUp => 'Échauffement';

  @override
  String get enumWorking => 'Travail';

  @override
  String get enumBackOff => 'Back-off';

  @override
  String get enumTechnique => 'Technique';

  @override
  String get enumExternalLoad => 'Charge externe';

  @override
  String get enumBandResistance => 'Bande / résistance';

  @override
  String get enumTotalLoad => 'Charge totale';

  @override
  String get enumPerImplement => 'Par accessoire';

  @override
  String get enumOneImplement => 'Un accessoire';

  @override
  String get enumBothSides => 'Les deux côtés';

  @override
  String get enumAlternatingTotalReps => 'Alterné, total des répétitions';

  @override
  String get enumPartial => 'Partiel';

  @override
  String get enumFailed => 'Échec';

  @override
  String get enumStraightSets => 'Séries classiques';

  @override
  String get enumSuperset => 'Superset';

  @override
  String get enumCircuit => 'Circuit';

  @override
  String get enumRir => 'RIR';

  @override
  String get enumRpe110 => 'RPE 1–10';

  @override
  String get enumBeforeTraining => 'Avant l\'entraînement';

  @override
  String get enumAfterTraining => 'Après l\'entraînement';

  @override
  String get enumResting => 'Au repos';

  @override
  String get enumSeated => 'Assis';

  @override
  String get enumLyingDown => 'Allongé';

  @override
  String get duringRoutineGelsAreNot =>
      'Pendant : les gels réguliers ne sont pas nécessaires pour cette séance courte/facile. Bois selon ta soif.';

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      'Pendant : répartis glucides et boissons en petites prises régulières. Compte les glucides des boissons dans le même total que les gels et la nourriture.';

  @override
  String get fluidIsAnEditableStarting =>
      'Les liquides sont une estimation de départ modifiable, pas un quota. Appuie-toi sur la soif, l\'apport habituel et les pertes de sueur mesurées ; ne force pas à boire plus.';

  @override
  String get afterHaveCarbohydrateAndA =>
      'Après : prends des glucides et un repas contenant des protéines. Privilégie le réapprovisionnement et la réhydratation si une autre séance approche.';

  @override
  String get swimmingPlaceALabelledBottle =>
      'Natation : place une bouteille étiquetée au bord du bassin et profite des pauses entre les séries pour boire ou t\'alimenter. Les conditions de la piscine peuvent différer de la météo extérieure.';

  @override
  String get runningCarryAccessibleGelsFlasks =>
      'Course à pied : emporte des gels/flasques accessibles ou prévois le ravitaillement aux postes ; entraîne-toi avec les mêmes produits et le même timing avant la course.';

  @override
  String get servingSizesAndToleranceMust =>
      'Les tailles de portion et la tolérance doivent être positives.';

  @override
  String get enterFiniteNonNegativeMeasurements =>
      'Saisis des mesures finies et non négatives.';

  @override
  String get targetsMustBeFiniteAnd =>
      'Les objectifs doivent être finis et non négatifs.';

  @override
  String get conditionsMustBeFiniteOr =>
      'Les conditions doivent être finies ou inconnues.';

  @override
  String get humidityMustBeBetween0 =>
      'L\'humidité doit être comprise entre 0 et 100 %.';

  @override
  String get noIntakeCannotIncludeFood =>
      '« Aucun apport » ne peut pas inclure d\'aliments ni de boissons.';

  @override
  String get addAnItemOrConfirm =>
      'Ajoute un élément ou confirme que tu n\'as rien consommé.';

  @override
  String get eachIntakeNeedsAProduct =>
      'Chaque apport nécessite un produit et un moment valide.';

  @override
  String get quantityMustBePositive => 'La quantité doit être positive.';

  @override
  String get thisActivityNoLongerExists => 'Cette activité n\'existe plus.';

  @override
  String get practisedCarbohydrateToleranceMustNot =>
      'La tolérance aux glucides entraînée ne doit pas dépasser 120 g/h.';

  @override
  String get measuredSweatRateMustBe =>
      'Le taux de sudation mesuré doit être positif ou laissé inconnu.';

  @override
  String get increasePractisedToleranceInNutrition =>
      'Augmente la tolérance entraînée dans les réglages de nutrition avant de choisir un objectif plus élevé.';

  @override
  String get fluidTargetExceedsYourMeasured =>
      'L\'objectif de liquides dépasse ton taux de sudation mesuré. Vérifie la mesure ou l\'objectif.';

  @override
  String get elapsedWorkoutTimeMustBe =>
      'Le temps de séance écoulé doit être positif ou laissé vide.';

  @override
  String get intakeAmountsMustBeFinite =>
      'Les quantités d\'apport doivent être finies et non négatives.';

  @override
  String get selectedStrategyUnavailableChooseAnother =>
      'La stratégie sélectionnée est indisponible. Choisis une autre stratégie ou aucune comparaison.';

  @override
  String get recordYourWorkoutNutrition =>
      'Enregistre ta nutrition d\'entraînement';

  @override
  String get addTheFoodAndFluids =>
      'Ajoute les aliments et liquides que tu as réellement consommés dans l\'historique de ton activité.';

  @override
  String get logIntake => 'Enregistrer l\'apport';

  @override
  String get in30Minutes => 'Dans 30 minutes';

  @override
  String get loadSuggestionsCoverStraightSets =>
      'Les suggestions de charge ne couvrent que les séries classiques avec répétitions.';

  @override
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  ) {
    return 'Nécessite $strengthProgressionMinSessions séances enregistrées de cet exercice.';
  }

  @override
  String get recentHistoryIsTooOld =>
      'L\'historique récent est trop ancien pour une suggestion.';

  @override
  String get theLastSessionDidNot =>
      'La dernière séance n\'utilisait pas une charge connue unique.';

  @override
  String get theLoadChangedBetweenThe =>
      'La charge a changé entre les séances récentes.';

  @override
  String get notEverySetReachedThe =>
      'Toutes les séries n\'ont pas atteint le haut de leur objectif de répétitions.';

  @override
  String get recordEffortRirOrRpe =>
      'Enregistre l\'effort (RIR ou RPE) sur la dernière série pour obtenir des suggestions.';

  @override
  String get recentSetsWereHarderThan =>
      'Les séries récentes étaient plus dures que prévu.';

  @override
  String get thisWorkoutAlreadyHasIts =>
      'Cette séance a déjà sa propre charge ; elle reste telle que définie.';

  @override
  String get yourRecentSetsMetThe =>
      'Tes séries récentes respectent la règle de progression. Définis le plus petit pas de charge de cet équipement pour examiner une charge.';

  @override
  String get thisWorkoutNoLongerExists => 'Cette séance n\'existe plus.';

  @override
  String thisStrengthPlanCannotBe(Object message) {
    return 'Ce plan de renforcement est illisible ($message).';
  }

  @override
  String get thisStrengthPlanCannotBe2 =>
      'Ce plan de renforcement est illisible.';

  @override
  String get addAtLeastOneExercise => 'Ajoute au moins un exercice.';

  @override
  String get thisWorkoutWasChangedElsewhere =>
      'Cette séance a été modifiée ailleurs. Tes modifications sont conservées ; recharge pour voir la version plus récente.';

  @override
  String get thePlanThisWorkoutIs =>
      'Le plan auquel cette séance est comparée est illisible.';

  @override
  String get thisLogWasChangedElsewhere =>
      'Ce journal a été modifié ailleurs. Tes saisies sont conservées ; recharge pour voir la version plus récente.';

  @override
  String get thisZipIsNotA =>
      'Ce ZIP n\'est pas une sauvegarde Fjelia prise en charge.';

  @override
  String get theBackupDatabaseIsDamaged =>
      'La base de données de la sauvegarde est endommagée.';

  @override
  String get invalidBackupData => 'Données de sauvegarde invalides.';

  @override
  String get backupTablesDoNotMatch =>
      'Les tables de la sauvegarde ne correspondent pas.';

  @override
  String get invalidBackupColumns => 'Colonnes de sauvegarde invalides.';

  @override
  String get migratingOriginalAppBackup =>
      'Migration de la sauvegarde de l\'app d\'origine';

  @override
  String get theOriginalBackupIsMissing =>
      'Il manque des tables requises dans la sauvegarde d\'origine.';

  @override
  String get backupFormatOrDatabaseVersion =>
      'Le format de sauvegarde ou la version de la base de données ne correspond pas.';

  @override
  String get restoringRecords => 'Restauration des enregistrements';

  @override
  String get restoringSettings => 'Restauration des réglages';

  @override
  String get restoreComplete => 'Restauration terminée';

  @override
  String get effortMustBeANumber => 'L\'effort doit être un nombre.';

  @override
  String get theDurationEstimateMustBe =>
      'L\'estimation de durée doit être positive.';

  @override
  String get restCannotBeNegative => 'Le repos ne peut pas être négatif.';

  @override
  String get enterTheRepetitionsDoneThe =>
      'Saisis les répétitions effectuées ; le plan prévoit une plage.';

  @override
  String get enterTheLoadThePlan =>
      'Saisis la charge ; le plan n\'en prévoit aucune.';

  @override
  String get enterTheResistanceThePlan =>
      'Saisis la résistance ; le plan n\'en prévoit aucune.';

  @override
  String get poorSensorContact => 'Mauvais contact du capteur';

  @override
  String get moreThan25FromLocal => 'À plus de 25 % de la médiane locale';

  @override
  String get workoutNutrition => 'Nutrition d\'entraînement';

  @override
  String get postWorkoutFoodAndFluid =>
      'Rappel du journal d\'aliments et de liquides après l\'entraînement';

  @override
  String get postTrainingHrvMeasurementReminder =>
      'Rappel de mesure de VFC après l\'entraînement';

  @override
  String get rirRunsFrom0To => 'RIR va de 0 à 10+.';

  @override
  String get rpeRunsFrom1To => 'RPE va de 1 à 10.';

  @override
  String get repetitionsCannotBeNegative =>
      'Les répétitions ne peuvent pas être négatives.';

  @override
  String get timedWorkMustBeLonger =>
      'Le travail chronométré doit durer plus de zéro seconde.';

  @override
  String get chooseRepetitionsOrTimedWork =>
      'Choisis des répétitions ou un travail chronométré, pas les deux.';

  @override
  String get loadMustBeAFinite =>
      'La charge doit être un nombre fini et non négatif.';

  @override
  String get durationCannotBeNegative => 'La durée ne peut pas être négative.';

  @override
  String get hrTimeline => 'Chronologie de FC';

  @override
  String get dayTrainingLoad => 'Charge d\'entraînement du jour';

  @override
  String get weekdayComparison => 'Comparaison par jour de la semaine';

  @override
  String get weeklyTrainingLoad => 'Charge d\'entraînement hebdomadaire';

  @override
  String get zonePolarization => 'Polarisation des zones';

  @override
  String get elevationOverview => 'Aperçu du dénivelé';

  @override
  String get trainingMonitor => 'Suivi d\'entraînement';

  @override
  String get formAtlCtlTsb => 'Forme ATL / CTL / TSB';

  @override
  String get trainingPlanProgress => 'Progression du plan d\'entraînement';

  @override
  String get rhrSleep => 'FC au repos (sommeil)';

  @override
  String get hrvSleep => 'VFC (sommeil)';

  @override
  String get spo2Sleep => 'SpO₂ (sommeil)';

  @override
  String get respRate => 'Fréquence respiratoire';

  @override
  String get stress => 'Stress';

  @override
  String get skinTemp => 'Température cutanée';

  @override
  String get steps => 'Pas';

  @override
  String get tonightsSleep => 'Sommeil de cette nuit';

  @override
  String get activityLog => 'Journal d\'activité';

  @override
  String get activityLog2 => 'Journal d\'activité';

  @override
  String get history2 => 'HISTORIQUE';

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
  String get heatAcclimation2 => 'ACCLIMATATION À LA CHALEUR';

  @override
  String score(Object score) {
    return '$score%';
  }

  @override
  String get elevation => 'DÉNIVELÉ';

  @override
  String get t12WeekHistory => 'HISTORIQUE SUR 12 SEMAINES';

  @override
  String get zonePolarization2 => 'POLARISATION DES ZONES';

  @override
  String get t5WeekHistory => 'HISTORIQUE SUR 5 SEMAINES';

  @override
  String get easy => 'FACILE %';

  @override
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded) {
    return '$withZones activités sur $recorded avec données de zones de FC';
  }

  @override
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples) {
    return '$fromSamples reconstituées à partir des échantillons de FC enregistrés';
  }

  @override
  String get easyZ12ModerateZ3 =>
      'Facile : Z1–2 · Modéré : Z3 · Intense : Z4–5';

  @override
  String get activitiesWithoutHrZoneData =>
      'Les activités sans données de zones de FC sont exclues des pourcentages.';

  @override
  String avgAverageUnit(Object average, Object unit) {
    return 'MOY $average $unit';
  }

  @override
  String get weekdayComparison2 => 'COMPARAISON PAR JOUR DE LA SEMAINE';

  @override
  String get trainingPlanProgress2 => 'PROGRESSION DU PLAN D\'ENTRAÎNEMENT';

  @override
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  ) {
    return 'Semaine $currentWeek / $durationInWeeks';
  }

  @override
  String get t30MinTimeTrialLt2 => 'CONTRE-LA-MONTRE DE 30 MIN – LT2';

  @override
  String get run30MinutesAtThe =>
      'Cours 30 minutes à l\'effort le plus soutenu que tu peux tenir – contrôlé, sans sprinter. Monte progressivement dans l\'effort ; ne pars pas trop vite. L\'allure et la FC moyennes des 20 dernières minutes sont ta LT2.';

  @override
  String get recordAsANormalOutdoor =>
      'Enregistre-le comme une sortie normale en extérieur. Lance ta montre, note l\'heure et cours 30 min à intensité de course.';

  @override
  String get t50MinTotalFlatCourse =>
      '~50 min au total · parcours plat · pas après un entraînement dur';

  @override
  String get doNotStartTooFast =>
      'Ne pars pas trop vite. Vise des intermédiaires réguliers.';

  @override
  String get theAppAveragesHrAnd =>
      'L\'app calcule la moyenne de la FC et de l\'allure sur les 20 dernières minutes du test, après l\'échauffement et les 10 premières minutes. Sélectionne l\'activité enregistrée dans Calculer.';

  @override
  String get lt2Pace => 'ALLURE LT2';

  @override
  String get activityRunningEnoughTimeFor =>
      'Activité (course, assez de temps pour échauffement + 30 min, avec FC)';

  @override
  String get selectTheTtActivity => 'Sélectionne l\'activité du test';

  @override
  String nameStartdate(Object name, Object startDate) {
    return '$name · $startDate';
  }

  @override
  String get warmUpBeforeTt => 'Échauffement avant le test';

  @override
  String roundMin(Object round) {
    return '$round min';
  }

  @override
  String get clearResults => 'Effacer les résultats';

  @override
  String get heartRate2 => 'FRÉQUENCE CARDIAQUE';

  @override
  String get paceSecKmLowerIs => 'Allure (s/km – plus bas = plus rapide)';

  @override
  String get thresholdsFitnessTests => 'Seuils et tests de forme';

  @override
  String get lt1 => 'LT1';

  @override
  String get lt2 => 'LT2';

  @override
  String get voPace => 'Allure VO₂';

  @override
  String get ftp => 'FTP';

  @override
  String get setFtpManually => 'Définir la FTP manuellement';

  @override
  String get calculateFromAnActivity => 'Calculer à partir d\'une activité';

  @override
  String get setFtp => 'Définir la FTP';

  @override
  String get ftpWatts => 'FTP (watts)';

  @override
  String get ftpCyclingThresholdPower => 'FTP – PUISSANCE SEUIL EN CYCLISME';

  @override
  String get ftpHistory => 'HISTORIQUE FTP';

  @override
  String get updateFromActivity => 'METTRE À JOUR DEPUIS UNE ACTIVITÉ';

  @override
  String get tapAnActivityFtpBest =>
      'Touche une activité – FTP = meilleure puissance sur 20 min × 0,95';

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
      'Aucune sortie avec 20 minutes d\'échantillons de puissance continus.';

  @override
  String get enterFtpManually => 'Saisir la FTP manuellement';

  @override
  String get selectTheTestActivity => 'Sélectionne l\'activité du test';

  @override
  String get formAtlCtlTsb2 => 'FORME · ATL / CTL / TSB';

  @override
  String get closeTrainingFormFullscreen =>
      'Fermer la forme d\'entraînement en plein écran';

  @override
  String get expandTrainingForm => 'Agrandir la forme d\'entraînement';

  @override
  String get calculatedFromTheFirstAvailable =>
      'Calculé à partir du premier enregistrement de charge disponible. Les jours sans charge enregistrée comptent pour zéro ; l\'entraînement antérieur est inconnu.';

  @override
  String get trainingMonitor2 => 'SUIVI D\'ENTRAÎNEMENT';

  @override
  String get pfitzingerZones => 'ZONES DE PFITZINGER';

  @override
  String get cyclingPowerZones => 'ZONES DE PUISSANCE EN CYCLISME';

  @override
  String znumber(Object number) {
    return 'Z$number';
  }

  @override
  String paceHrDescription(Object pace, Object hr, Object description) {
    return '$pace · $hr\n$description';
  }

  @override
  String get weeklyTrainingLoad2 => 'CHARGE D\'ENTRAÎNEMENT HEBDOMADAIRE';

  @override
  String get prevWeek => 'SEM. PRÉC.';

  @override
  String get bySport => 'PAR SPORT';

  @override
  String get noActivitiesThisWeek => 'Aucune activité cette semaine';

  @override
  String garminWorkoutScheduleddate(Object scheduledDate) {
    return 'Séance Garmin · $scheduledDate';
  }

  @override
  String get yourNote => 'Ta note';

  @override
  String get askAiCoach => 'Demander au coach IA';

  @override
  String get aiSettings => 'Réglages IA';

  @override
  String get askYourCoach => 'Pose ta question à ton coach…';

  @override
  String get sendMessage => 'Envoyer le message';

  @override
  String get sendFeedbackOrReportA => 'Envoyer un retour ou signaler un bogue';

  @override
  String get addMeasurement2 => 'Ajouter une mesure';

  @override
  String get syncLabel2 => 'Synchroniser';

  @override
  String get syncToday => 'Synchroniser aujourd\'hui';

  @override
  String get fullSync1Year => 'Synchro complète · 1 an';

  @override
  String get fullSyncComplete => 'Synchro complète · Terminée';

  @override
  String get syncingYourData => 'Synchronisation de tes données…';

  @override
  String lLeftkgRRightkgKg2(Object leftKg, Object rightKg) {
    return 'G $leftKg  D $rightKg kg';
  }

  @override
  String weightKgFatBodyfatMuscle(
    Object weight,
    Object bodyFat,
    Object muscleMass,
  ) {
    return '$weight kg · Gras $bodyFat % · Muscle $muscleMass kg';
  }

  @override
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase) {
    return '$title, $sport, $toLowerCase';
  }

  @override
  String get weatherUnavailableTapToRetry =>
      'Météo indisponible · Touche pour réessayer';

  @override
  String get weatherSetYourLocation => 'Météo · Définis ta position';

  @override
  String get t7DayForecast => 'PRÉVISIONS SUR 7 JOURS';

  @override
  String get minMax => 'min/max';

  @override
  String get rainMm2 => 'pluie mm';

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
    return 'Objectifs de course · $length';
  }

  @override
  String gWk(Object g) {
    return '$g sem.';
  }

  @override
  String weeks(Object weeks) {
    return '$weeks';
  }

  @override
  String get weeks2 => 'semaines';

  @override
  String get upcoming => 'À VENIR';

  @override
  String lengthMoreDays(Object length) {
    return '+ $length jours de plus';
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
  String get plannedCompletedSkipped => '○ Prévu   ● Terminé   ✕ Ignoré';

  @override
  String get heartRate3 => 'Fréquence cardiaque';

  @override
  String get watts => 'Watts';

  @override
  String theStepsAddUpTo(Object total, Object plannedDurationMin) {
    return 'Les étapes totalisent $total ; le plan compte $plannedDurationMin min.';
  }

  @override
  String get typicalSplitForThisKind =>
      'Répartition typique pour ce type de séance ; aucune étape pour la calculer.';

  @override
  String labelGetsEachExerciseWith(Object label) {
    return '$label reçoit chaque exercice avec ses séries, répétitions et charges. Les plages de répétitions, l\'effort et le tempo restent dans Fjelia.';
  }

  @override
  String get markAsRest => 'Marquer comme repos';

  @override
  String get restoreWorkout => 'Restaurer la séance';

  @override
  String get skipThisWorkout => 'Ignorer cette séance ?';

  @override
  String get previousWeek => 'Semaine précédente';

  @override
  String get backToThisWeek => 'Retour à cette semaine';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get nextWeek => 'Semaine suivante';

  @override
  String get today2 => 'AUJOURD\'HUI';

  @override
  String get route => 'PARCOURS';

  @override
  String get feedback => 'Retour';

  @override
  String get plannedWorkout => 'Séance prévue';

  @override
  String get delete => 'Supprimer';

  @override
  String get chatAi => 'Chat IA';

  @override
  String get trainingLoad => 'Charge d\'entraînement';

  @override
  String get dayTrainingLoad2 => 'CHARGE D\'ENTRAÎNEMENT DU JOUR';

  @override
  String get trimp => ' TRIMP';

  @override
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter) {
    return '$scoreBefore → $scoreAfter';
  }

  @override
  String get temperatureOverTime => 'TEMPÉRATURE AU FIL DU TEMPS';

  @override
  String roundh(Object round) {
    return '${round}h';
  }

  @override
  String get timeInHrZones => 'Temps dans les zones de FC';

  @override
  String get route2 => 'Parcours';

  @override
  String get start => 'Départ';

  @override
  String get gpx => 'GPX';

  @override
  String touppercasesubstringBriefing(Object toUpperCase, Object substring) {
    return 'Briefing $toUpperCase$substring';
  }

  @override
  String get chatWithAiAboutThis => 'Discuter de ce briefing avec l\'IA';

  @override
  String get whyThisRecommendation => 'Pourquoi cette recommandation ?';

  @override
  String titleDateLabel(Object title, Object date, Object label) {
    return '$title, $date, $label';
  }

  @override
  String get previousDay => 'Jour précédent';

  @override
  String get nextDay => 'Jour suivant';

  @override
  String get updating => 'Mise à jour';

  @override
  String get resting => 'AU REPOS';

  @override
  String get noTimedReadings => 'Aucune mesure horodatée';

  @override
  String get avg => 'MOY';

  @override
  String get peak => 'PIC';

  @override
  String tolocalRoundmin(Object toLocal, Object round) {
    return '$toLocal · ${round}min';
  }

  @override
  String avgheartrateBpmAvg(Object avgHeartRate) {
    return '$avgHeartRate bpm moy.';
  }

  @override
  String get timeWeightedAverageOverRecorded =>
      'Moyenne pondérée dans le temps sur les périodes enregistrées. Les trous sans mesures sont exclus.';

  @override
  String get previousHeartRatePeriod =>
      'Période de fréquence cardiaque précédente';

  @override
  String get nextHeartRatePeriod => 'Période de fréquence cardiaque suivante';

  @override
  String get avgHr => 'FC moy.';

  @override
  String get restingHr => 'FC au repos';

  @override
  String get both => 'Les deux';

  @override
  String averagelabelFixedMs(Object averageLabel, Object fixed) {
    return '$averageLabel $fixed ms';
  }

  @override
  String get measureWithPolarH10 => 'Mesurer avec le Polar H10';

  @override
  String get ms => 'ms';

  @override
  String get noWorkoutInThisPeriod =>
      'Aucune séance de cette période n\'a de paire avant/après comparable.';

  @override
  String textEachWorkoutCountsOnce(Object text) {
    return '$text. Chaque séance compte une fois ; cela décrit tes paires, sans les noter.';
  }

  @override
  String get workoutFinished => 'Séance terminée ?';

  @override
  String get yourWorkoutIsNotIn =>
      'Ta séance n\'est pas encore dans Fjelia. Si elle est terminée, indique quand, et le rappel pourra suivre sa vraie fin. Sinon elle apparaîtra à la synchronisation de ta montre.';

  @override
  String get workoutFinished2 => 'Séance terminée';

  @override
  String get theWorkoutMustStartAfter =>
      'La séance doit commencer après la mesure et finir après son début, pas dans le futur.';

  @override
  String daysDAvg(Object days) {
    return '$days J moy.';
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
  String get previousPeriod => 'Période précédente';

  @override
  String get nextPeriod => 'Période suivante';

  @override
  String get overnightHrvReflectsRecoveryCompare =>
      'La VFC nocturne reflète la récupération. Compare tes mesures à ta propre référence au fil du temps.';

  @override
  String get moveThisWorkout => 'DÉPLACER CETTE SÉANCE';

  @override
  String get pickDate => 'Choisir une date';

  @override
  String movedFromMovedfrom(Object movedFrom) {
    return 'Déplacée depuis $movedFrom';
  }

  @override
  String get hrvAroundThisWorkout => 'VFC autour de cette séance';

  @override
  String get measureAfterTraining => 'Mesurer après l\'entraînement';

  @override
  String get measureAgain => 'Mesurer à nouveau';

  @override
  String get explainWithAi => 'Expliquer avec l\'IA';

  @override
  String beforeEndedPregapAheadOf(Object preGap) {
    return 'Avant s\'est terminé $preGap avant le début.';
  }

  @override
  String lengthFurtherMeasurementSAfter(Object length) {
    return '$length autre(s) mesure(s) après cette séance sont conservées comme observations supplémentaires.';
  }

  @override
  String get noHrvMeasurementRecordedAround =>
      'Aucune mesure de VFC enregistrée autour de cette séance.';

  @override
  String get measureHrv => 'Mesurer la VFC';

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
      'Une description de cette paire, pas une note pour la séance.';

  @override
  String notEnoughComparableWorkoutsYet(Object eligible, Object need) {
    return 'Pas encore assez de séances comparables, $eligible sur $need.';
  }

  @override
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need) {
    return 'Pas encore assez de séances comparables ($eligible sur $need).';
  }

  @override
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  ) {
    return 'Tes $eligible séances similaires · $toLocal–$toLocal2';
  }

  @override
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  ) {
    return 'Moitié centrale $q1Ms à $q3Ms ms · médiane $medianMs ms · cette séance $delta ms';
  }

  @override
  String rpeI(Object i) {
    return 'RPE $i';
  }

  @override
  String get easy2 => 'facile';

  @override
  String get allOut => 'À fond';

  @override
  String workoutProfileDescription(Object description) {
    return 'Profil de la séance : $description';
  }

  @override
  String get noActivitiesInThisPeriod => 'Aucune activité sur cette période';

  @override
  String get enableHeatAcclimationInTraining =>
      'Active l\'acclimatation à la chaleur dans les réglages d\'entraînement.';

  @override
  String get noElevationThisWeek => 'Aucun dénivelé cette semaine';

  @override
  String get noActivitiesSynced => 'Aucune activité synchronisée';

  @override
  String get noHrZoneData => 'Aucune donnée de zones de FC';

  @override
  String get easyJogGetHrElevated =>
      'Footing facile – monte la FC, jambes déliées';

  @override
  String get fastestSustainablePaceLikeA =>
      'Allure soutenable la plus rapide – comme une course de 30 min';

  @override
  String get walkCardiacRecovery => 'Marche – récupération cardiaque';

  @override
  String get selectTheTtActivityFirst =>
      'Sélectionne d\'abord l\'activité du test.';

  @override
  String get calculating => 'Calcul…';

  @override
  String get calculateLt2 => 'Calculer la LT2';

  @override
  String get enterFtpBetween30And => 'Saisis une FTP entre 30 et 1000 W.';

  @override
  String get aerobicThreshold => 'Seuil aérobie';

  @override
  String get functionalThresholdPower => 'Puissance au seuil fonctionnel';

  @override
  String get estimated => 'Estimé';

  @override
  String get afterWarmingUpRunFive =>
      'Après l\'échauffement, cours cinq minutes à ton effort soutenable le plus rapide. Enregistre la sortie avec des données de vitesse ou de distance.';

  @override
  String get recordAtLeast40Minutes =>
      'Enregistre au moins 40 minutes de course régulière à effort constant. Le test compare la fréquence cardiaque dans chaque moitié pour estimer la dérive aérobie.';

  @override
  String get theFastestFiveMinuteWindow =>
      'La fenêtre de cinq minutes la plus rapide donne ton allure VO2max.';

  @override
  String get noResultYet => 'Pas encore de résultat';

  @override
  String get calculateVo2maxPace => 'Calculer l\'allure VO2max';

  @override
  String get calculateLt1 => 'Calculer la LT1';

  @override
  String get loading2 => 'Chargement';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get noTrainingHistory => 'Aucun historique d\'entraînement';

  @override
  String get fitnessCtl => 'Forme physique (CTL)';

  @override
  String get fatigueAtl => 'Fatigue (ATL)';

  @override
  String get formTsb => 'Fraîcheur (TSB)';

  @override
  String get noHistory => 'Aucun historique';

  @override
  String get fresh => 'Frais';

  @override
  String get optimal => 'Optimal';

  @override
  String get neutral => 'Neutre';

  @override
  String get tired => 'Fatigué';

  @override
  String get veryFatigued => 'Très fatigué';

  @override
  String get garminRunningVo2max => 'VO2max course Garmin';

  @override
  String get garminCyclingVo2max => 'VO2max cyclisme Garmin';

  @override
  String get aerobicThreshold2 => 'Seuil aérobie';

  @override
  String driftDriftAt(Object drift, Object at) {
    return 'Dérive $drift % · $at';
  }

  @override
  String get activityHours => 'Heures d\'activité';

  @override
  String get activityKm => 'Km d\'activité';

  @override
  String get tap5MinuteMaxTest => 'Touche · test max de 5 min';

  @override
  String get setFtpToCalculatePower =>
      'Définis la FTP pour calculer les zones de puissance';

  @override
  String get cyclingPowerZones2 => 'Zones de puissance en cyclisme';

  @override
  String get pfitzingerZones2 => 'Zones de Pfitzinger';

  @override
  String get completeAnLt2TestTo =>
      'Effectue un test LT2 pour calculer les zones de course.';

  @override
  String get setFtpToCalculatePower2 =>
      'Définis la FTP pour calculer les zones de puissance.';

  @override
  String get endurance => 'Endurance';

  @override
  String get threshold => 'Seuil';

  @override
  String get anaerobic => 'Anaérobie';

  @override
  String get whatExplainsThisRise => 'Qu\'est-ce qui explique cette hausse ?';

  @override
  String get whatExplainsThisDrop => 'Qu\'est-ce qui explique cette baisse';

  @override
  String get whatExplainsThisRise2 => 'Qu\'est-ce qui explique cette hausse';

  @override
  String get editsAreKeptInFjelia =>
      'Les modifications sont conservées dans Fjelia comme copie locale pour cette date. La séance sur Garmin n\'est pas modifiée.';

  @override
  String get howDoIExecuteThis => 'Comment exécuter cette séance ?';

  @override
  String shareHealthContextWithName(Object name) {
    return 'Partager le contexte de santé avec $name ?';
  }

  @override
  String get yourMessageAndAHealth =>
      'Ton message et un résumé santé/entraînement seront envoyés à ce fournisseur d\'IA cloud. Les noms et le GPS sont exclus du résumé généré.';

  @override
  String get couldNotGetAReply =>
      'Impossible d\'obtenir une réponse. Vérifie tes réglages IA et réessaie.';

  @override
  String get askAboutYourRecoveryTraining =>
      'Pose des questions sur ta récupération, ton entraînement ou le plan du jour.';

  @override
  String get noSyncYet => 'Pas encore synchronisé';

  @override
  String lastSyncLastContext(Object last, Object context) {
    return 'Dernière synchro : $last $context';
  }

  @override
  String get seasonWithTradeOffs => 'Saison : avec compromis';

  @override
  String get seasonNeedsYourDecision => 'Saison : nécessite ta décision';

  @override
  String get seasonCannotBeCombined => 'Saison : impossible à combiner';

  @override
  String get seasonProvisional => 'Saison : provisoire';

  @override
  String get season => 'Saison';

  @override
  String get allGoalsFit => 'Tous les objectifs sont compatibles.';

  @override
  String goalTargetfinishsecondsgoal(Object targetFinishSeconds, Object goal) {
    return 'Objectif $targetFinishSeconds$goal';
  }

  @override
  String estEstimateestimate2(Object estimate, Object estimate2) {
    return 'Est. $estimate$estimate2';
  }

  @override
  String doneDoneby(Object doneBy) {
    return 'Terminé · $doneBy';
  }

  @override
  String garminWorkoutWorkout(Object workout) {
    return 'Séance Garmin · $workout';
  }

  @override
  String get moveAnyway => 'Déplacer quand même ?';

  @override
  String get wattsNeedYourFtpSet =>
      'Les watts nécessitent ta FTP : définis-la dans Charge, Seuils.';

  @override
  String get mainTargetInWattsFrom =>
      'Objectif principal en watts d\'après ta FTP, la fréquence cardiaque sert de repère.';

  @override
  String get mainTargetHeartRateWatts =>
      'Objectif principal : fréquence cardiaque ; les watts ne sont pas définis sur la montre.';

  @override
  String get taperPhase => 'Phase d\'affûtage';

  @override
  String get recoverySession => 'Séance de récupération';

  @override
  String get closeToYourEvent => 'Proche de ton événement';

  @override
  String get noWorkoutStructureAvailable =>
      'Aucune structure de séance disponible.';

  @override
  String get aerobic => 'Aérobie';

  @override
  String get pushAgainToUpdateYour =>
      'Renvoie pour mettre à jour le calendrier de ta montre.';

  @override
  String workoutSentToLabel(Object label) {
    return 'Séance envoyée à $label';
  }

  @override
  String get updating2 => 'Mise à jour…';

  @override
  String pushToLabel(Object label) {
    return 'Envoyer à $label';
  }

  @override
  String shareExerciseListForLabel(Object label) {
    return 'Partager la liste d\'exercices pour $label';
  }

  @override
  String shareWorkoutForLabel(Object label) {
    return 'Partager la séance pour $label';
  }

  @override
  String get whyNothingIsAddedTo =>
      'Pourquoi ? Rien n\'est ajouté pour le compléter.';

  @override
  String get workout => 'Séance';

  @override
  String get recordedActivityLinkedToThis =>
      'Activité enregistrée liée à cette séance';

  @override
  String get matchedToTheRecordedWorkout =>
      'Associé au début de la séance enregistrée';

  @override
  String get matchedByWorkoutNameSport =>
      'Associé par nom de séance, sport et date';

  @override
  String get matchedBySportDateAnd => 'Associé par sport, date et durée';

  @override
  String planPlannedminutesMin(Object plannedMinutes) {
    return 'Plan $plannedMinutes min';
  }

  @override
  String get maxHr => 'FC max';

  @override
  String get trainingLoad2 => 'Charge d\'entraînement';

  @override
  String get active => 'Actif';

  @override
  String get avgPace => 'Allure moy.';

  @override
  String get avgSpeed => 'Vitesse moy.';

  @override
  String get avgPower => 'Puissance moy.';

  @override
  String get elevation2 => 'Dénivelé';

  @override
  String get altitude => 'Altitude';

  @override
  String get explainMyHrvBeforeAnd =>
      'Explique ma VFC avant et après cette séance. Qu\'est-ce qui est comparable, qu\'est-ce qui ne l\'est pas et qu\'est-ce qui reste inconnu ?';

  @override
  String get deleteActivity => 'Supprimer l\'activité ?';

  @override
  String get removeThisActivityFromThe =>
      'Retirer cette activité de l\'historique local ? Une synchronisation ultérieure du fournisseur peut la réimporter.';

  @override
  String get howDidThisSessionGo =>
      'Comment s\'est passée cette séance et qu\'est-ce que cela signifie pour mes prochains jours ?';

  @override
  String currentFixedFixed2(Object fixed, Object fixed2) {
    return 'Actuel $fixed, $fixed2';
  }

  @override
  String get setUpInTrainingSettings =>
      'À configurer dans les réglages d\'entraînement';

  @override
  String get couldNotLoadHeatData =>
      'Impossible de charger les données de chaleur – touche pour les détails';

  @override
  String get loadingHeatHistory => 'Chargement de l\'historique de chaleur…';

  @override
  String get noHeatDataYet => 'Pas encore de données de chaleur';

  @override
  String optimalLowHigh(Object low, Object high) {
    return 'Optimal $low–$high';
  }

  @override
  String optimalLowHighTrimp(Object low, Object high) {
    return 'Optimal : $low–$high TRIMP';
  }

  @override
  String get targetUnavailableSyncTrainingHistory =>
      'Objectif indisponible – synchronise l\'historique d\'entraînement';

  @override
  String get workoutQualifiedForHeatAccumulation =>
      'La séance a compté pour l\'accumulation de chaleur.';

  @override
  String get workoutDidNotAddHeat =>
      'La séance n\'a pas ajouté d\'accumulation de chaleur.';

  @override
  String get performanceTime => 'Performance / Temps';

  @override
  String get performanceDistance => 'Performance / Distance';

  @override
  String get noRecordedRoute => 'Aucun parcours enregistré';

  @override
  String get zoomIn => 'Zoom avant';

  @override
  String get zoomOut => 'Zoom arrière';

  @override
  String get fitRoute => 'Ajuster le parcours';

  @override
  String get fullscreenMap => 'Carte en plein écran';

  @override
  String get openstreetmapContributors2 => 'contributeurs d\'OpenStreetMap';

  @override
  String get appleIntelligenceIsUnavailableShowing =>
      'Apple Intelligence est indisponible. Affichage d\'un résumé sans IA.';

  @override
  String get generateAiBriefing => 'Générer le briefing IA ?';

  @override
  String get retryAiBriefing => 'Réessayer le briefing IA';

  @override
  String get generateBriefing => 'Générer le briefing';

  @override
  String discussThisBriefingWithMe(Object text) {
    return 'Discute de ce briefing avec moi et propose la meilleure prochaine action.\n\n$text';
  }

  @override
  String whyThisRecommendationWhichOf(Object text) {
    return 'Pourquoi cette recommandation ? Quels chiffres et quelles lacunes de données y ont mené, et qu\'est-ce qui la changerait ?\n\n$text';
  }

  @override
  String get avg2 => 'Moy.';

  @override
  String get peak2 => 'Pic';

  @override
  String get notEnoughContinuousReadingsFor =>
      'Pas assez de mesures continues pour une moyenne.';

  @override
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  ) {
    return 'Couverture enregistrée : $inHours h $inMinutes min · moyenne pondérée dans le temps';
  }

  @override
  String get lying => 'Allongé';

  @override
  String get noHrvReadingsInThis => 'Aucune mesure de VFC sur cette période';

  @override
  String get overnightHrvComesFromYour =>
      'La VFC nocturne vient de ta montre, les mesures ponctuelles du Polar H10 (RMSSD). Les méthodes diffèrent : compare les tendances, pas les valeurs isolées.';

  @override
  String get noReadings => 'Aucune mesure';

  @override
  String get whenDidTheWorkoutStart => 'Quand la séance a-t-elle commencé ?';

  @override
  String get whenDidItEnd => 'Quand s\'est-elle terminée ?';

  @override
  String get last3Months => '3 derniers mois';

  @override
  String get lastYear => 'Dernière année';

  @override
  String lastDaysDays(Object days) {
    return '$days derniers jours';
  }

  @override
  String nowOnCurrentTapA(Object current) {
    return 'Actuellement le $current. Touche un jour ou fais glisser la séance dessus. Les étapes restent inchangées.';
  }

  @override
  String get monthView => 'Vue mensuelle';

  @override
  String get syncing => 'Synchronisation';

  @override
  String get trendUnavailable => 'Tendance indisponible';

  @override
  String get stable => 'Stable';

  @override
  String get increasing => 'En hausse';

  @override
  String get decreasing => 'En baisse';

  @override
  String get unclear => 'Incertain';

  @override
  String get notComparable => 'Non comparable';

  @override
  String get waitingForAfter => 'En attente de l\'après';

  @override
  String get afterOnly => 'Après seulement';

  @override
  String get waitingForTheActualWorkout =>
      'En attente de la fin réelle de la séance.';

  @override
  String reminderAroundTolocal(Object toLocal) {
    return 'Rappel vers $toLocal';
  }

  @override
  String get reminderIsDueMeasureWhen =>
      'Le rappel est dû. Mesure quand tu es prêt.';

  @override
  String get thisReminderIsNoLonger =>
      'Ce rappel n\'est plus d\'actualité. Ouvre la séance pour voir tes mesures.';

  @override
  String beforeFixedMilliseconds(Object fixed) {
    return 'Avant $fixed millisecondes. ';
  }

  @override
  String afterFixedMilliseconds(Object fixed) {
    return 'Après $fixed millisecondes';
  }

  @override
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  ) {
    return 'Variation de $deltaMs millisecondes, $deltaPercent pour cent.';
  }

  @override
  String get noPreTrainingMeasurementRecorded =>
      'Aucune mesure avant l\'entraînement enregistrée.';

  @override
  String get notMeasuredYet => 'Pas encore mesuré';

  @override
  String leftOutOfTheComparison(Object excludedTotal, Object c) {
    return 'Exclues de la comparaison : $excludedTotal séances ($c).';
  }

  @override
  String get notFromThisWorkout => 'Pas de cette séance';

  @override
  String get useAsBefore => 'Utiliser comme avant';

  @override
  String get useAsAfter => 'Utiliser comme après';

  @override
  String get beforeNotMeasured => 'Avant · non mesuré';

  @override
  String beforeTolocal(Object toLocal) {
    return 'Avant · $toLocal';
  }

  @override
  String workoutWorkouttext(Object workoutText) {
    return 'Séance · $workoutText';
  }

  @override
  String get afterNotMeasuredYet => 'Après · pas encore mesuré';

  @override
  String afterTolocal(Object toLocal) {
    return 'Après · $toLocal';
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
    return 'Tes séances similaires ($eligible, $toLocal–$toLocal2) : médiane $medianMs ms, moitié centrale $q1Ms à $q3Ms ms.';
  }

  @override
  String get howHardDidItFeel => 'À quel point était-ce dur ? (RPE)';

  @override
  String get loadMetric => 'Charge';

  @override
  String get clearAction => 'Effacer';

  @override
  String get routeFinish => 'Arrivée';

  @override
  String get month2 => 'MOIS';

  @override
  String get week2 => 'SEMAINE';

  @override
  String get quarter => 'TRIMESTRE';

  @override
  String get year => 'ANNÉE';

  @override
  String get easy3 => 'FACILE';

  @override
  String get mod => 'MOD.';

  @override
  String get hard => 'INTENSE';

  @override
  String get protocol => 'PROTOCOLE';

  @override
  String get calculate => 'CALCULER';

  @override
  String get warmUp => 'ÉCHAUFFEMENT';

  @override
  String get coolDown => 'RETOUR AU CALME';

  @override
  String get ftpCycling => 'FTP cyclisme';

  @override
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg) {
    return 'FTP $ftpWatts W · $wattsPerKg W/kg';
  }

  @override
  String get thisWeekSoFar => 'CETTE SEMAINE · JUSQU\'ICI';

  @override
  String get duration2 => 'DURÉE';

  @override
  String get distance2 => 'DISTANCE';

  @override
  String get sport2 => 'SPORT';

  @override
  String get repeatSets => 'SÉRIES RÉPÉTÉES';

  @override
  String get aboutThisWorkout => 'À PROPOS DE CETTE SÉANCE';

  @override
  String get workoutStructure => 'STRUCTURE DE LA SÉANCE';

  @override
  String get health2 => 'SANTÉ';

  @override
  String get high2 => 'ÉLEVÉ';

  @override
  String get elevated => 'ÉLEVÉ';

  @override
  String get normal => 'NORMAL';

  @override
  String get tomorrow => 'DEMAIN';

  @override
  String get skipped2 => 'IGNORÉ';

  @override
  String get weeklyPlan => 'PLAN HEBDOMADAIRE';

  @override
  String get activityLog3 => 'JOURNAL D\'ACTIVITÉ';

  @override
  String skippedTouppercase(Object toUpperCase) {
    return 'IGNORÉ · $toUpperCase';
  }

  @override
  String get primaryZone => 'ZONE PRINCIPALE';

  @override
  String get coachingCues => 'CONSEILS DU COACH';

  @override
  String get targets => 'OBJECTIFS';

  @override
  String get adaptation => 'ADAPTATION';

  @override
  String get done2 => 'TERMINÉ';

  @override
  String get notRecorded2 => 'NON ENREGISTRÉ';

  @override
  String get planned => 'PRÉVU';

  @override
  String get extra => 'SUPPLÉMENTAIRE';

  @override
  String get optimal2 => 'OPTIMAL';

  @override
  String get qualified => 'QUALIFIÉE';

  @override
  String get temp => 'TEMP.';

  @override
  String get humidity2 => 'HUMIDITÉ';

  @override
  String get pressure => 'PRESSION';

  @override
  String get wetBulb => 'BULBE HUMIDE';

  @override
  String get paceMinKm => 'Allure (min/km)';

  @override
  String get speedKmH => 'Vitesse (km/h)';

  @override
  String get elevationM => 'Dénivelé (m)';

  @override
  String get powerW => 'PUISSANCE (W)';

  @override
  String get performanceTime2 => 'PERFORMANCE / TEMPS';

  @override
  String get performanceDistance2 => 'PERFORMANCE / DISTANCE';

  @override
  String get load2 => 'CHARGE';

  @override
  String get day2 => 'JOUR';

  @override
  String get allTime => 'DEPUIS TOUJOURS';

  @override
  String get hrvAroundThisWorkout2 => 'VFC autour de cette séance. ';

  @override
  String get lowReserve => 'RÉSERVE FAIBLE';

  @override
  String get goodReserve => 'BONNE RÉSERVE';

  @override
  String latestReadingAtTolocal(Object toLocal) {
    return 'Dernière mesure à $toLocal';
  }

  @override
  String get weeklyAvg => 'MOY. HEBDO';

  @override
  String get monthlyAvg => 'MOY. MENSUELLE';

  @override
  String get systolic2 => 'SYSTOLIQUE';

  @override
  String get diastolic2 => 'DIASTOLIQUE';

  @override
  String get hourlyVariation => 'VARIATION HORAIRE';

  @override
  String get dailyVariation => 'VARIATION QUOTIDIENNE';

  @override
  String get sys2 => 'SYS';

  @override
  String get dia => 'DIA';

  @override
  String get bluetoothDevices => 'APPAREILS BLUETOOTH';

  @override
  String get accountsServices => 'COMPTES ET SERVICES';

  @override
  String get flowLoginOptional => 'CONNEXION FLOW (FACULTATIF)';

  @override
  String get polarFlowLogin => 'CONNEXION POLAR FLOW';

  @override
  String get raceGoal => 'OBJECTIF DE COURSE';

  @override
  String get experienceLevel => 'NIVEAU D\'EXPÉRIENCE';

  @override
  String get weeklySchedule2 => 'PLANNING HEBDOMADAIRE';

  @override
  String get sessionsPerDay2 => 'SÉANCES PAR JOUR';

  @override
  String get aboutYou => 'À PROPOS DE TOI';

  @override
  String get yourActivities2 => 'TES ACTIVITÉS';

  @override
  String latestReadingAtTimestamp(Object timestamp) {
    return 'Dernière mesure à $timestamp';
  }

  @override
  String get poorSleep => 'MAUVAIS SOMMEIL';

  @override
  String get fairSleep => 'SOMMEIL MOYEN';

  @override
  String get goodSleep => 'BON SOMMEIL';

  @override
  String get hoursOfSleep => 'HEURES DE SOMMEIL';

  @override
  String get sleepNeeded => 'SOMMEIL NÉCESSAIRE';

  @override
  String get deepSleep => 'SOMMEIL PROFOND';

  @override
  String get exercises2 => 'EXERCICES';

  @override
  String get strengthSummary => 'RÉSUMÉ DU RENFORCEMENT';

  @override
  String get strengthDraft => 'RENFORCEMENT · BROUILLON';

  @override
  String get strengthFinishedWithGaps =>
      'RENFORCEMENT · TERMINÉ AVEC DES LACUNES';

  @override
  String get strength2 => 'RENFORCEMENT';

  @override
  String get wind => 'VENT';

  @override
  String get sun2 => 'SOLEIL';

  @override
  String get cloud => 'NUAGES';

  @override
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt) {
    return 'Données : $source · Mis à jour $fetchedAt';
  }

  @override
  String get coros2 => 'COROS';

  @override
  String get rmssdMs => 'RMSSD · ms';

  @override
  String get sdnnMs => 'SDNN · ms';

  @override
  String get now2 => 'MAINTENANT';

  @override
  String get awake => 'ÉVEILLÉ';

  @override
  String get light => 'LÉGER';

  @override
  String get deep2 => 'PROFOND';

  @override
  String get sqliteOrm => 'SQLite ORM';

  @override
  String get httpClients => 'Clients HTTP';

  @override
  String get gpsLocation => 'Position GPS';

  @override
  String get hdlCholesterol => 'Cholestérol HDL';

  @override
  String get ldlCholesterol => 'Cholestérol LDL';

  @override
  String get raceName => 'NOM DE LA COURSE';

  @override
  String get mtb => 'VTT';

  @override
  String get distanceKm => 'Distance (km)';

  @override
  String get priority => 'PRIORITÉ';

  @override
  String get elevationGainM => 'Dénivelé positif (m)';

  @override
  String get targetTime => 'TEMPS VISÉ';

  @override
  String get raceDate => 'DATE DE LA COURSE';

  @override
  String get participation => 'PARTICIPATION';

  @override
  String get whatIWantFromIt => 'CE QUE J\'EN ATTENDS';

  @override
  String periodTimeline(Object period) {
    return '$period · ÉVOLUTION';
  }

  @override
  String get tabPlan => 'PLAN';

  @override
  String get tabLoad => 'CHARGE';

  @override
  String get tabCoach => 'COACH';

  @override
  String get hrDriftTestLt1 => 'TEST DE DÉRIVE DE FC – LT1';

  @override
  String get asSentByGarmin => 'TEL QU\'ENVOYÉ PAR GARMIN';

  @override
  String get noData2 => 'AUCUNE DONNÉE';

  @override
  String get noTarget => 'AUCUN OBJECTIF';

  @override
  String get noHeatLoad => 'AUCUNE CHARGE THERMIQUE';

  @override
  String get hrBpm => 'FC (bpm)';

  @override
  String get aiBriefingUnavailableShowingA =>
      'Briefing IA indisponible. Affichage d\'un résumé sans IA.';

  @override
  String get uvIndex2 => 'INDICE UV';

  @override
  String get aiBriefing => 'Briefing IA';

  @override
  String get uiFrameworkByGoogle => 'Framework d\'interface de Google';

  @override
  String get unableToLoadData => 'Impossible de charger les données';

  @override
  String briefingSummary(Object recovery, Object sleep, Object load) {
    return 'Récupération $recovery / 100. Sommeil $sleep / 100. La charge d\'entraînement du jour est de $load TRIMP.';
  }

  @override
  String get morningBriefing => 'Briefing du matin';

  @override
  String get lunchBriefing => 'Briefing du midi';

  @override
  String get afternoonBriefing => 'Briefing de l\'après-midi';

  @override
  String get eveningBriefing => 'Briefing du soir';

  @override
  String get appleUnusableAnswer =>
      'Apple Intelligence n\'a pas pu produire de réponse exploitable : elle s\'est répétée ou a répété tes données. Reformule la question ou choisis un autre fournisseur d\'IA dans les réglages.';

  @override
  String get appleCouldNotAnswer =>
      'Apple Intelligence n\'a pas pu répondre. Réessaie.';

  @override
  String get appleNotAvailableOnDevice =>
      'Apple Intelligence n\'est pas disponible sur cet appareil.';

  @override
  String get appleLanguageRejected =>
      'Apple Intelligence a refusé la langue de la requête. Essaie une question courte en anglais. Vérifie aussi les réglages de langue de l\'iPhone et de Siri.';

  @override
  String get appleRequestTooLarge =>
      'Apple Intelligence n\'a pas pu traiter cette requête. Essaie une question plus courte.';

  @override
  String get messageTooLongForApple =>
      'Ce message est trop long pour Apple Intelligence. Raccourcis-le et renvoie-le.';

  @override
  String get vo2maxRunning => 'VO₂max course';

  @override
  String get vo2maxCycling => 'VO₂max cyclisme';

  @override
  String get vo2maxPaceLabel => 'Allure VO₂max';

  @override
  String get lt1Threshold => 'Seuil LT1';

  @override
  String get lt2Threshold => 'Seuil LT2';

  @override
  String hoursPreviousWeek(Object value) {
    return '$value h la semaine précédente';
  }

  @override
  String kmPreviousWeek(Object value) {
    return '$value km la semaine précédente';
  }

  @override
  String get thirtyMinuteTimeTrial => 'Contre-la-montre de 30 minutes';

  @override
  String thirtyMinTtDate(Object date) {
    return 'TT 30 min · $date';
  }

  @override
  String get yesterday2 => 'HIER';

  @override
  String get briefHeadGreen => 'Tu es bien récupéré.';

  @override
  String get briefHeadYellow => 'Tu portes une certaine fatigue.';

  @override
  String get briefHeadRed => 'Tu es nettement fatigué.';

  @override
  String briefMain(Object reasons) {
    return 'Principales raisons : $reasons.';
  }

  @override
  String get briefAllClear =>
      'Aucune de tes valeurs ne montre de signal d\'alerte.';

  @override
  String get briefAdviceGreen => 'Entraîne-toi comme prévu.';

  @override
  String get briefAdviceYellow =>
      'Garde ton plan, mais n\'ajoute pas d\'intensité.';

  @override
  String get briefAdviceRed =>
      'La récupération d\'abord : journée facile ou repos.';

  @override
  String get briefReasonHrvLow => 'VFC du sommeil basse';

  @override
  String get briefReasonHrvHigh => 'VFC du sommeil élevée';

  @override
  String get briefReasonRhrUp => 'FC au repos élevée';

  @override
  String get briefReasonRhrDown => 'FC au repos basse';

  @override
  String get briefReasonSleepShort => 'manque de sommeil';

  @override
  String get briefReasonSleepGood => 'besoin de sommeil couvert';

  @override
  String get briefReasonEnergyLow => 'énergie faible';

  @override
  String get briefReasonEnergyHigh => 'bonne énergie';

  @override
  String get briefReasonStressHigh => 'stress élevé';

  @override
  String get briefReasonRespHigh => 'fréquence respiratoire élevée';

  @override
  String get briefReasonSpo2Low => 'oxygène sanguin bas';

  @override
  String get briefReasonSkinTempOff => 'température cutanée inhabituelle';

  @override
  String get briefReasonFormTired => 'fatigue d\'entraînement accumulée';

  @override
  String get briefReasonFormVeryTired => 'fatigue d\'entraînement très élevée';

  @override
  String get briefReasonFormFresh => 'frais et reposé';

  @override
  String get briefTrainingHrvUp =>
      'Ta VFC a augmenté après l\'entraînement, bon signe.';

  @override
  String get briefTrainingHrvDown =>
      'Ta VFC a baissé après l\'entraînement, signe moins favorable.';

  @override
  String get reminderNeedsNotifications =>
      'Le rappel a besoin des notifications. Autorise-les pour Fjelia dans les réglages système, puis réactive-le.';

  @override
  String get whatDidYouHave => 'Qu\'as-tu consommé ?';

  @override
  String get intakeSomething => 'J\'ai consommé quelque chose';

  @override
  String get intakeNothing => 'Rien';

  @override
  String get totalIntake => 'Apport total';

  @override
  String get carbsLabel => 'Glucides';

  @override
  String get fluidLabel => 'Liquide';

  @override
  String get sodiumLabel => 'Sodium';

  @override
  String get caffeineLabel => 'Caféine';

  @override
  String get detailsOptional => 'Détails (facultatif)';

  @override
  String atMinute(Object minute) {
    return 'minute $minute';
  }

  @override
  String get nothingAddedYet =>
      'Rien d\'ajouté pour l\'instant. Ajoute ce que tu as mangé ou bu, ou choisis « Rien ».';

  @override
  String get followFocusWeek => 'Sur quoi me concentrer cette semaine ?';

  @override
  String get followRecoveryTrend => 'Comment évolue ma récupération ?';

  @override
  String get followLoadTooHigh =>
      'Ma charge d\'entraînement est-elle trop élevée ?';

  @override
  String get followImproveSleep => 'Qu\'est-ce qui améliorerait mon sommeil ?';

  @override
  String get followIntervalsFeel =>
      'Quelle sensation doivent donner les intervalles ?';

  @override
  String get followTiredToday => 'Et si je me sens fatigué aujourd\'hui ?';

  @override
  String get followEatBefore => 'Que dois-je manger avant ?';

  @override
  String get followAdjustToday => 'Dois-je l\'adapter aujourd\'hui ?';

  @override
  String get followNextDays =>
      'Qu\'est-ce que cela signifie pour mes prochains jours ?';

  @override
  String get followCompareSimilar =>
      'Comment cela se compare-t-il à des séances similaires ?';

  @override
  String get followRecover => 'Que dois-je faire pour récupérer ?';

  @override
  String get followIntensityRight => 'L\'intensité était-elle la bonne ?';

  @override
  String get statusPlanned => 'Prévu';

  @override
  String get statusAdapted => 'Adapté';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get statusRest => 'Repos';

  @override
  String loadValue(Object value) {
    return 'Charge $value';
  }

  @override
  String get actIntensityEasy => 'C\'était une séance aérobie facile.';

  @override
  String get actIntensityModerate => 'C\'était une séance modérée.';

  @override
  String get actIntensityHard => 'C\'était une séance intense.';

  @override
  String get actIntensityUnknown => 'La séance est enregistrée.';

  @override
  String get actLenLonger =>
      'Elle était plus longue que tes séances similaires.';

  @override
  String get actLenShorter =>
      'Elle était plus courte que tes séances similaires.';

  @override
  String get actLoadHigher => 'La charge était plus élevée que d\'habitude.';

  @override
  String get actLoadLower => 'La charge était plus faible que d\'habitude.';

  @override
  String get actLoadSame => 'La charge était à peu près habituelle.';

  @override
  String get actHrLower =>
      'Ta FC était plus basse que d\'habitude, c\'était plus facile.';

  @override
  String get actHrHigher =>
      'Ta FC était plus haute que d\'habitude, c\'était plus dur.';

  @override
  String get actAdviceUnknown =>
      'Organise tes prochains jours selon ton ressenti.';

  @override
  String briefOutlookRest(Object days) {
    return 'Avec environ $days jours faciles, ta forme revient dans la plage optimale.';
  }

  @override
  String get briefOutlookLongRest =>
      'Ta forme a besoin de plus de quelques jours faciles pour récupérer.';

  @override
  String get briefOutlookPlanTired =>
      'Si tu suis le plan, ta forme reste basse les prochains jours.';

  @override
  String get localQwen => 'Qwen3.5 · local';

  @override
  String get localModelDescription =>
      'Qwen3.5 en option, MLX 4 bits. Télécharge-le une fois, puis utilise le chat et les briefings sur cet appareil sans clé API. Tes données de santé restent sur cet appareil.';

  @override
  String localModelSizeMb(Object megabytes) {
    return 'Téléchargement de $megabytes Mo · de la mémoire supplémentaire est nécessaire pendant l\'utilisation.';
  }

  @override
  String get localModelDownload => 'Télécharger le modèle';

  @override
  String get localModelResumeDownload => 'Reprendre le téléchargement';

  @override
  String localModelDownloading(Object downloaded, Object total) {
    return '$downloaded / $total Mo';
  }

  @override
  String get localModelInstalled => 'Téléchargé · disponible hors ligne';

  @override
  String get localModelRemove => 'Supprimer le modèle';

  @override
  String get localModelUnsupported =>
      'Ce modèle MLX nécessite un iPhone avec iOS 17 ou ultérieur et une puce A14 ou plus récente. Les appareils plus anciens ne sont pas pris en charge.';

  @override
  String get localModelMemoryUnsupported =>
      'Cet appareil n\'a pas assez de mémoire pour exécuter le modèle local.';

  @override
  String get localModelDownloadFailed =>
      'Échec du téléchargement. Réessaie ; les fichiers complets sont conservés.';

  @override
  String get localModelDownloadFirst =>
      'Télécharge d\'abord Qwen dans Réglages → IA et plus.';

  @override
  String get localModelContextTooLong =>
      'Cette conversation est trop longue pour le modèle local. Commence un nouveau chat ou raccourcis ta question.';

  @override
  String get localModelBusy =>
      'Le modèle local répond à une autre demande. Réessaie dans un instant.';

  @override
  String get localModelInterrupted =>
      'La génération locale a été interrompue. Garde Fjelia ouverte et réessaie.';

  @override
  String get localModelCouldNotAnswer =>
      'Le modèle local n\'a pas pu répondre. Vérifie le modèle dans Réglages → IA et plus, puis réessaie.';

  @override
  String get localModelBriefingUnavailable =>
      'Briefing IA local indisponible. Affichage du résumé de l\'app.';

  @override
  String get localModelInfo => 'Détails du modèle et licence';

  @override
  String localModelRamGb(int gigabytes) {
    return 'Nécessite au moins $gigabytes Go de mémoire vive.';
  }

  @override
  String get localModelIPhone18 =>
      'Le modèle 4B est disponible sur iPhone 18 et les modèles ultérieurs.';

  @override
  String briefPlannedTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aujourd’hui, $count séances sont prévues.',
      one: 'Aujourd’hui, 1 séance est prévue.',
    );
    return '$_temp0';
  }

  @override
  String get coachDataFallback =>
      'La réponse du modèle contredit les données. Voici le résumé de Fjelia :';

  @override
  String get coachSevenDayAverage => 'moyenne sur 7 jours';

  @override
  String coachSleepNeedAndShortfall(String need, String shortfall) {
    return 'Besoin de sommeil : $need h ; déficit : $shortfall h.';
  }

  @override
  String coachCurrentForm(String value) {
    return 'Forme actuelle (TSB) : $value points.';
  }

  @override
  String get aiOnboardingStep => 'Étape 2 sur 3';

  @override
  String get aiOnboardingTitle => 'Votre coach.\nÀ votre façon.';

  @override
  String get aiOnboardingSubtitle =>
      'Transformez vos données de santé en conseils pour mieux vous entraîner et récupérer.';

  @override
  String get aiOnboardingChoose => 'CHOISISSEZ VOTRE COACH IA';

  @override
  String get aiOnboardingFreeDetail => 'Gratuit · Sans compte IA';

  @override
  String get aiOnboardingFreeBody =>
      'Une IA dans le cloud pour l’entraînement et la récupération.';

  @override
  String get aiOnboardingRecommended => 'Recommandé';

  @override
  String get aiOnboardingOnDevice => 'Sur votre appareil';

  @override
  String get aiOnboardingLocalBody =>
      'Vos requêtes IA restent sur cet appareil.';

  @override
  String get aiOnboardingUnavailable => 'Indisponible pour le moment';

  @override
  String get aiOnboardingMore => 'Autres modèles IA';

  @override
  String get aiOnboardingMoreBody =>
      'Qwen en local ou votre propre fournisseur cloud';

  @override
  String get aiOnboardingConsent =>
      'Requêtes cloud uniquement après votre accord.';

  @override
  String get aiOnboardingError =>
      'Votre choix d’IA n’a pas pu être enregistré ou chargé. Veuillez réessayer.';

  @override
  String get aiOnboardingWithout => 'Continuer sans IA';

  @override
  String get aiOnboardingConfigure => 'Configurer le modèle';

  @override
  String aiOnboardingContinue(String provider) {
    return 'Continuer avec $provider';
  }

  @override
  String get aiOnboardingChangeLater =>
      'Modifiable à tout moment dans les réglages.';

  @override
  String get creditsAndLicenses => 'Licences et remerciements';

  @override
  String get bioAgeActivity => 'Activité';

  @override
  String get bioAgeActivityBasis => 'Données d’activité · 7 derniers jours';

  @override
  String bioAgeActivityReported(String minutes) {
    return '$minutes minutes modérées rapportées';
  }

  @override
  String bioAgeActivitySteps(String minutes) {
    return '≈ $minutes minutes de marche estimées à partir des pas';
  }

  @override
  String bioAgeActivityCoverage(int days) {
    return 'Données pour $days jours sur 7';
  }

  @override
  String get bioAgeActivityEstimateNotice =>
      'Hypothèse : 100 pas ≈ 1 minute de marche. Le total quotidien des pas ne révèle ni l’allure ni l’intensité. Les minutes rapportées sont prioritaires chaque jour ; les pas du même jour ne sont pas comptés en plus.';

  @override
  String get bioAgeActivityIncomplete =>
      'Des données d’activité manquent. La contribution de l’activité en années est calculée uniquement lorsque les 7 jours disposent de données.';

  @override
  String get bioAgeActivityEstimatedLabel =>
      'L’activité inclut une durée de marche estimée.';

  @override
  String get bioAgeActivityUnknownLabel => 'Données d’activité incomplètes';
}
