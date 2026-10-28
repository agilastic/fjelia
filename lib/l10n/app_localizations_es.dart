// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get settings => 'Ajustes';

  @override
  String get profile => 'Perfil';

  @override
  String get training => 'Entrenamiento';

  @override
  String get weatherLocation => 'Tiempo y ubicación';

  @override
  String get display => 'Pantalla';

  @override
  String get connections => 'Conexiones';

  @override
  String get aiAndMore => 'IA y más';

  @override
  String get system => 'Sistema';

  @override
  String get runSetupAgain => 'Repetir la configuración';

  @override
  String get runSetupAgainSubtitle =>
      'Cuentas, objetivo de carrera y plan de entrenamiento';

  @override
  String get back => 'Atrás';

  @override
  String get close => 'Cerrar';

  @override
  String get dataExport => 'Exportar datos';

  @override
  String get dataExportSubtitle =>
      'Exportación CSV, copia de seguridad y restauración';

  @override
  String get developer => 'Desarrollador';

  @override
  String get developerSubtitle => 'Modo de depuración, diagnóstico';

  @override
  String get debug => 'Depuración';

  @override
  String get debugMode => 'Modo de depuración';

  @override
  String get debugModeSubtitle => 'Muestra la pestaña DEBUG';

  @override
  String get support => 'Soporte';

  @override
  String get reportBug => 'Informar de un error';

  @override
  String get aiCoach => 'Entrenador IA';

  @override
  String get enableAiCoach => 'Activar el entrenador IA';

  @override
  String get onDeviceAiOrCloud => 'IA en el dispositivo o proveedor en la nube';

  @override
  String get provider => 'Proveedor';

  @override
  String get model => 'Modelo';

  @override
  String get chatAndAiBriefingsUse =>
      'El chat y los resúmenes con IA usan Apple Intelligence en este dispositivo. No hace falta clave API. Si el modelo no está disponible, los resúmenes muestran un texto sin IA.';

  @override
  String get briefing => 'Resumen';

  @override
  String get useAppleIntelligenceForBriefings =>
      'Usar Apple Intelligence para los resúmenes';

  @override
  String get useOnDeviceAiFor =>
      'Usar la IA del dispositivo para los resúmenes y mantener el proveedor elegido para el chat.';

  @override
  String get healthDataSharing => 'Compartir datos de salud';

  @override
  String get askOncePerChatSession => 'Preguntar una vez por sesión de chat';

  @override
  String get otherwiseAskBeforeEveryCloud =>
      'Si no, preguntar antes de cada mensaje a la nube';

  @override
  String get reportABug => 'Informar de un error';

  @override
  String get weatherData => 'Datos meteorológicos';

  @override
  String get openSourceLibraries => 'Bibliotecas de código abierto';

  @override
  String get license => 'Licencia';

  @override
  String get licenses => 'Licencias';

  @override
  String get apiKey => 'Clave API';

  @override
  String get saveApiKey => 'Guardar clave API';

  @override
  String get feedbackBugReport => 'Comentarios e informe de error';

  @override
  String get reportSentThankYou => 'Informe enviado. ¡Gracias!';

  @override
  String get weReadEveryMessageIf =>
      'Leemos todos los mensajes. Si dejaste tu correo, es posible que recibas una respuesta.';

  @override
  String get done => 'Hecho';

  @override
  String get shareAnIdeaSuggestAn =>
      'Comparte una idea, sugiere una mejora o cuéntanos qué pasó y qué esperabas.';

  @override
  String get whatHappenedAndWhatDid => '¿Qué pasó y qué esperabas?';

  @override
  String get pleaseLeaveOutPasswordsApi =>
      'Por favor, no incluyas contraseñas, claves API ni datos de salud personales.';

  @override
  String get includeDiagnostics => 'Incluir diagnósticos';

  @override
  String get optionalLogsMayContainAccount =>
      'Opcional. Los registros pueden contener datos de la cuenta o de salud. Revísalos abajo antes de enviar.';

  @override
  String get diagnosticsPreview => 'VISTA PREVIA DE DIAGNÓSTICOS';

  @override
  String get sendingSharesYourEmailSubject =>
      'Al enviar se comparten tu correo, el asunto, el mensaje y los diagnósticos seleccionados con el soporte de Fjelia en cloud.ebeling-hoppe.de.';

  @override
  String get copyReport => 'Copiar informe';

  @override
  String get shareReport => 'Compartir informe';

  @override
  String get appleHealth => 'Apple Salud';

  @override
  String get connectedServices => 'Servicios conectados';

  @override
  String get hiloBloodPressureBle => 'Hilo presión arterial (BLE)';

  @override
  String get writeHeartDataToApple => 'Escribir datos cardíacos en Apple Salud';

  @override
  String get writeWeightDataToApple => 'Escribir datos de peso en Apple Salud';

  @override
  String get renphoScaleBle => 'Báscula Renpho (BLE)';

  @override
  String get polarH10HrvStrapBle => 'Polar H10 (banda VFC, BLE)';

  @override
  String get dataSourcePriority => 'Prioridad de las fuentes de datos';

  @override
  String get whenMultipleSourcesProvideThe =>
      'Cuando varias fuentes aportan la misma métrica, gana la que está más arriba. Arrastra para reordenar.';

  @override
  String get resetToDefault => 'Restablecer valores predeterminados';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get healthPage => 'Página de salud';

  @override
  String get loadPage => 'Página de carga';

  @override
  String get healthMonitor => 'Monitor de salud';

  @override
  String get hrZones => 'Zonas de FC';

  @override
  String get t30MinTtAvailableSync =>
      'TT de 30 min disponible: sincroniza las zonas de FC';

  @override
  String lt2Lt2BpmAt(Object lt2, Object at) {
    return 'LT2 $lt2 bpm · $at';
  }

  @override
  String get syncLabel => 'SINCRONIZAR';

  @override
  String get autoadjust => 'AJUSTE AUTOMÁTICO';

  @override
  String zoneI(Object i) {
    return 'Zona $i';
  }

  @override
  String get hrZones2 => 'ZONAS DE FC';

  @override
  String ageRound(Object round) {
    return 'edad $round';
  }

  @override
  String get basics => 'Datos básicos';

  @override
  String get updateWaistMonthlyUsedFor =>
      'ⓘ Actualiza la cintura cada mes: se usa para estimar la grasa visceral.';

  @override
  String get alcohol => 'Alcohol';

  @override
  String get t1Drink033L =>
      '1 bebida ≈ 0,33 l de cerveza / 0,2 l de vino / 4 cl de licor';

  @override
  String get clinicalLabsOptional => 'Análisis clínicos (opcional)';

  @override
  String get glycemic => 'Glucemia';

  @override
  String get optimalForLongevity48 =>
      'Óptimo para la longevidad: 4,8–5,4 % · Prediabetes: 5,7–6,4 %';

  @override
  String get lipids => 'Lípidos';

  @override
  String get apobReplacesLdlWhenBoth =>
      'La ApoB sustituye al LDL cuando se introducen ambos.';

  @override
  String get inflammationKidney => 'Inflamación y riñón';

  @override
  String get changesAreSavedAutomatically =>
      'Los cambios se guardan automáticamente';

  @override
  String get optionalTotalClimbingForThis =>
      'Desnivel total opcional para esta carrera.';

  @override
  String get moreAboutThisEvent => 'Más información sobre este evento';

  @override
  String distanceOfDistancekmKm(Object distanceKm) {
    return '¿Distancia de $distanceKm km?';
  }

  @override
  String keepDistancekmKm(Object distanceKm) {
    return 'Mantener $distanceKm km';
  }

  @override
  String useLikelyKm(Object likely) {
    return 'Usar $likely km';
  }

  @override
  String get thisBackupContainsNoCalendar =>
      'Esta copia de seguridad no contiene actividades del calendario.';

  @override
  String get activities => 'Actividades';

  @override
  String get exportActivitiesCsv => 'Exportar actividades a CSV';

  @override
  String get backupRestore => 'Copia de seguridad y restauración';

  @override
  String get backup => 'Copia de seguridad';

  @override
  String get restoreFromBackup => 'Restaurar desde copia de seguridad';

  @override
  String get backupRestoredRestartTheApp =>
      'Copia restaurada. Reinicia la app para recargar todos los ajustes.';

  @override
  String get raceGoals => 'Objetivos de carrera';

  @override
  String get yourActivities => 'Tus actividades';

  @override
  String get usedByAiCoachAnd =>
      'Lo usan el entrenador IA y el plan de entrenamiento. Los deportes del plan se marcan con ✦.';

  @override
  String get calendarWeekStart => 'Inicio de semana del calendario';

  @override
  String get planDefaultView => 'Vista predeterminada del plan';

  @override
  String get weeklySchedule => 'Horario semanal';

  @override
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      trainingDaysPerWeek,
      locale: localeName,
      other: '$trainingDaysPerWeek días de entrenamiento',
      one: '$trainingDaysPerWeek día de entrenamiento',
    );
    return '$_temp0 · toca para alternar Entrenamiento / Descanso / Fuerza';
  }

  @override
  String get updatePlanToThisSchedule => 'Actualizar el plan a este horario';

  @override
  String get updateStrengthSessions => 'Actualizar las sesiones de fuerza';

  @override
  String get sessionsPerDay => 'Sesiones por día';

  @override
  String get canYouFitTwoWorkouts =>
      '¿Puedes hacer dos entrenamientos en un día?';

  @override
  String get strengthLoadUnit => 'Unidad de carga de fuerza';

  @override
  String get weightsThemselvesAreSetIn =>
      'Los pesos se fijan en cada entrenamiento y se recuerdan a partir de tu historial.';

  @override
  String get hoursAvailableWeek => 'Horas disponibles / semana';

  @override
  String hoursperweekHWeek(Object hoursPerWeek) {
    return '$hoursPerWeek h / semana';
  }

  @override
  String hoursperweekH(Object hoursPerWeek) {
    return '$hoursPerWeek h';
  }

  @override
  String get heatAcclimation => 'Aclimatación al calor';

  @override
  String get showHeatAcclimation => 'Mostrar aclimatación al calor';

  @override
  String get weatherEvaluatedAgainstAConfigurable =>
      'El tiempo se evalúa para una ubicación configurable.';

  @override
  String get trainingPlan => 'Plan de entrenamiento';

  @override
  String get regenerateReplacesFutureSessionsAnd =>
      'Regenerar sustituye las sesiones futuras y reconstruye el plan desde hoy con los ajustes actuales.';

  @override
  String valueUpcomingWorkoutsGenerated(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value entrenamientos próximos generados',
      one: '$value entrenamiento próximo generado',
    );
    return '$_temp0';
  }

  @override
  String get generationFailedCheckYourRace =>
      'Error al generar. Revisa tu objetivo de carrera e inténtalo de nuevo.';

  @override
  String get deleteAllWorkouts => 'Eliminar todos los entrenamientos';

  @override
  String get changesAreSavedAutomatically2 =>
      '✓ Los cambios se guardan automáticamente';

  @override
  String countUpcomingWorkoutsGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrenamientos próximos generados',
      one: '$count entrenamiento próximo generado',
    );
    return '$_temp0';
  }

  @override
  String get importRaceGoalsFromGarmin =>
      'Importar objetivos de carrera desde Garmin';

  @override
  String get addRaceGoal => 'Añadir objetivo de carrera';

  @override
  String priorityTouppercase(Object toUpperCase) {
    return 'Prioridad $toUpperCase';
  }

  @override
  String get goalsAreSharedWithAi =>
      'Los objetivos se comparten con el entrenador IA. La prioridad A, B o C decide cómo pondera el plan tus carreras entre sí.';

  @override
  String get deletingWorkouts => 'Eliminando entrenamientos';

  @override
  String get cityOrTown => 'Ciudad o pueblo';

  @override
  String get eGHannoverOrPalma => 'p. ej. Hannover o Palma';

  @override
  String get noCitiesFoundTryA =>
      'No se encontraron ciudades. Prueba con un pueblo cercano.';

  @override
  String get chooseTheLocationForThe =>
      'Elige la ubicación para la previsión del plan, el radar y la aclimatación al calor. El tiempo funciona aunque la aclimatación esté desactivada.';

  @override
  String get none => 'Ninguna';

  @override
  String get disableLocalWeatherAndLocation =>
      'Desactivar el tiempo local y las solicitudes de ubicación';

  @override
  String get currentLocation => 'Ubicación actual';

  @override
  String get followYourDeviceLocation => 'Seguir la ubicación del dispositivo';

  @override
  String get fixedLocation => 'Ubicación fija';

  @override
  String get chooseACityOrEnter => 'Elige una ciudad o introduce coordenadas';

  @override
  String get chooseCity => 'Elegir ciudad';

  @override
  String get coordinates => 'Coordenadas';

  @override
  String get latitude => 'Latitud';

  @override
  String get longitude => 'Longitud';

  @override
  String get saveLocation => 'Guardar ubicación';

  @override
  String get refreshCurrentLocation => 'Actualizar ubicación actual';

  @override
  String get citySearchOpenMeteoGeonames =>
      'Búsqueda de ciudades: Open-Meteo / GeoNames';

  @override
  String get cityNamesOpenstreetmap => 'Nombres de ciudades: © OpenStreetMap';

  @override
  String get energy => 'ENERGÍA';

  @override
  String get currentEnergy => 'ENERGÍA ACTUAL';

  @override
  String get dailyTimeline => 'LÍNEA DE TIEMPO DIARIA';

  @override
  String valueValue2(Object value, Object value2) {
    return '$value → $value2';
  }

  @override
  String get energy2 => 'Energía';

  @override
  String get noData => 'Sin datos';

  @override
  String get bloodPressureInsights => 'ANÁLISIS DE PRESIÓN ARTERIAL';

  @override
  String get sys => ' Sis';

  @override
  String get diaMmhg => ' Dia · mmHg';

  @override
  String get previousBloodPressurePeriod =>
      'Periodo de presión arterial anterior';

  @override
  String get nextBloodPressurePeriod => 'Periodo de presión arterial siguiente';

  @override
  String get nightDipping => 'Descenso nocturno';

  @override
  String get noMeasurementsInThisPeriod => 'Sin mediciones en este periodo';

  @override
  String get fullscreenBloodPressureChart =>
      'Gráfico de presión arterial a pantalla completa';

  @override
  String get barsMinMaxLineDots =>
      'Barras: mín–máx · línea/puntos: media · toca o arrastra para inspeccionar';

  @override
  String get noMeasurements => 'Sin mediciones';

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
      other: '$length mediciones',
      one: '$length medición',
    );
    return '$_temp0 · media / mín–máx';
  }

  @override
  String bloodPressureTouppercaseMmhg(Object toUpperCase) {
    return 'PRESIÓN ARTERIAL · $toUpperCase · mmHg';
  }

  @override
  String get closeFullscreenBloodPressureChart =>
      'Cerrar el gráfico de presión arterial a pantalla completa';

  @override
  String get chooseScale => 'Elegir báscula';

  @override
  String get noScalesFoundStepOn =>
      'No se encontró ninguna báscula. Súbete a la báscula e inténtalo de nuevo.';

  @override
  String nameRssiDbm(Object name, Object rssi) {
    return '$name · $rssi dBm';
  }

  @override
  String get renphoSaved => 'RENPHO guardada:';

  @override
  String get renphoScaleBle2 => 'Báscula RENPHO (BLE)';

  @override
  String get changeMeasurementType => 'Cambiar tipo de medición';

  @override
  String get addMeasurement => 'Añadir medición';

  @override
  String get whatAreYouMeasuring => '¿Qué estás midiendo?';

  @override
  String get chooseAnotherMeasurement => 'Elegir otra medición';

  @override
  String get saveMeasurement => 'Guardar medición';

  @override
  String get skip => 'Omitir';

  @override
  String get connectHiloService => 'Conectar el servicio Hilo';

  @override
  String get connectHilo => 'Conectar Hilo';

  @override
  String get connectCoros => 'Conectar Coros';

  @override
  String get europe => 'Europa';

  @override
  String get unitedStates => 'Estados Unidos';

  @override
  String get asia => 'Asia';

  @override
  String get bluetoothBloodPressure => 'Bluetooth · presión arterial';

  @override
  String get cloudCuffData => 'Nube · datos del brazalete';

  @override
  String get apiSync => 'Sincronización por API';

  @override
  String get bluetoothHrvStrap => 'Bluetooth · banda VFC';

  @override
  String get accesslinkApi => 'AccessLink API';

  @override
  String get systemHealthData => 'Datos de salud del sistema';

  @override
  String get cloudScaleHistory => 'Nube · historial de la báscula';

  @override
  String get bluetoothWeightBody => 'Bluetooth · peso y cuerpo';

  @override
  String get connectYourDevices => 'Conecta tus dispositivos';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get connectGarmin => 'Conectar Garmin';

  @override
  String get connectAppleHealth => 'Conectar Apple Salud';

  @override
  String get dataSynced => 'DATOS SINCRONIZADOS';

  @override
  String get pairHiloPod => 'Vincular Hilo Pod';

  @override
  String get chooseStrap => 'Elegir la banda';

  @override
  String namePaired(Object name) {
    return '$name vinculado.';
  }

  @override
  String get pairPolarH10 => 'Vincular Polar H10';

  @override
  String get forget => 'Olvidar';

  @override
  String get sendWorkoutToPolar => 'Enviar entrenamiento a Polar';

  @override
  String get connectPolar => 'Conectar Polar';

  @override
  String get signInWithPolarFlow => 'Iniciar sesión con Polar Flow';

  @override
  String get syncsSleepStagesHrvResting =>
      'Sincroniza fases del sueño · VFC · FC en reposo · entrenamientos · pasos';

  @override
  String savedForV(Object v) {
    return 'Guardado para $v';
  }

  @override
  String get remove => 'Quitar';

  @override
  String get polarEMail => 'Correo de Polar';

  @override
  String get polarPassword => 'Contraseña de Polar';

  @override
  String get pairRenphoScale => 'Vincular báscula RENPHO';

  @override
  String get connectRenpho => 'Conectar Renpho';

  @override
  String get connectSuunto => 'Conectar Suunto';

  @override
  String smsSentToTrim(Object trim) {
    return 'SMS enviado a $trim';
  }

  @override
  String get resendSms => 'Reenviar SMS';

  @override
  String get retryLoadingPreferences => 'Reintentar cargar las preferencias';

  @override
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed) {
    return 'TIEMPO DE ENTRENAMIENTO SEMANAL · $toStringAsFixed h';
  }

  @override
  String get tapADayToCycle =>
      'Toca un día para alternar Entrenamiento / Descanso / Fuerza.';

  @override
  String get doubleDayOk => 'Día doble ok';

  @override
  String get birthYearOptional => 'Año de nacimiento (opcional)';

  @override
  String get addAnother => 'Añadir otro';

  @override
  String get knowYourBodyTrainSmarter => 'Conoce tu cuerpo.\nEntrena mejor.';

  @override
  String get allYourHealthDevicesOne =>
      'Todos tus dispositivos de salud. Una sola vista inteligente.';

  @override
  String get areYouReadyToTrain => '¿Estás listo para entrenar hoy?';

  @override
  String get hrvRecoveryScoreRestingHr =>
      'VFC · Puntuación de recuperación · FC en reposo';

  @override
  String get didYouActuallyRecoverLast => '¿Te recuperaste de verdad anoche?';

  @override
  String get sleepStagesDeepSleepSpo =>
      'Fases del sueño · Sueño profundo · SpO₂';

  @override
  String get isYourBloodPressureUnder =>
      '¿Tu presión arterial está bajo control?';

  @override
  String get continuousBpNightDippingTrends =>
      'Presión continua · Descenso nocturno · Tendencias';

  @override
  String get howHardDidYouPush => '¿Cuánto te has exigido esta semana?';

  @override
  String get trainingLoadTrimpStrainScore =>
      'Carga de entrenamiento · TRIMP · Puntuación de esfuerzo';

  @override
  String get isYourBodyCompositionImproving =>
      '¿Mejora tu composición corporal?';

  @override
  String get weightBodyFatMuscleMass => 'Peso · Grasa corporal · Masa muscular';

  @override
  String get getStarted => 'Empezar';

  @override
  String get yourDataStaysOnYour =>
      'Tus datos se quedan en tu dispositivo. Siempre privados.';

  @override
  String get bodyScale => 'Báscula corporal';

  @override
  String get bodyComposition => 'Composición corporal';

  @override
  String get sleep => 'SUEÑO';

  @override
  String get sleepPerformance => 'RENDIMIENTO DEL SUEÑO';

  @override
  String get sleepHistory => 'Historial de sueño';

  @override
  String labelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String lessLabel(Object label) {
    return 'Menos $label';
  }

  @override
  String moreLabel(Object label) {
    return 'Más $label';
  }

  @override
  String get gymMode => 'Modo gimnasio';

  @override
  String get finishWorkout => 'Terminar entrenamiento';

  @override
  String get workoutActions => 'Acciones del entrenamiento';

  @override
  String get discardWorkout => 'Descartar entrenamiento';

  @override
  String get allSetsRecorded => 'Todas las series registradas';

  @override
  String get reviewSets => 'Revisar series';

  @override
  String get rest => 'DESCANSO';

  @override
  String plannedResttarget(Object restTarget) {
    return 'Previsto $restTarget';
  }

  @override
  String get startSet => 'Empezar serie';

  @override
  String get seconds => 'Segundos';

  @override
  String get previousSet => 'Serie anterior';

  @override
  String get allSets => 'Todas las series';

  @override
  String get nextSet => 'Serie siguiente';

  @override
  String get everySetIsSavedAs =>
      'Cada serie se guarda sobre la marcha. Puedes cerrar esta pantalla cuando quieras y retomar desde el entrenamiento planificado.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get apply => 'Aplicar';

  @override
  String get effortScale => 'Escala de esfuerzo';

  @override
  String get setType => 'Tipo de serie';

  @override
  String get reps => 'Repeticiones';

  @override
  String get range => 'Rango';

  @override
  String get time => 'Tiempo';

  @override
  String get t45Or100 => '45 o 1:00';

  @override
  String get blankWhenNotSet => 'En blanco si no se define';

  @override
  String get redBand => 'Banda roja';

  @override
  String get t90Or130 => '90 o 1:30';

  @override
  String get blankWhenUnknown => 'En blanco si se desconoce';

  @override
  String get usePlannedLoad => 'Usar la carga planificada';

  @override
  String get blankWhenNotMeasured => 'En blanco si no se mide';

  @override
  String get exercise => 'Ejercicio';

  @override
  String get changingTheLoadConventionStarts =>
      'Cambiar la convención de carga inicia un historial separado para este ejercicio.';

  @override
  String get barbellMachine => 'Barra, máquina…';

  @override
  String get load => 'Carga';

  @override
  String get loadRefersTo => 'La carga se refiere a';

  @override
  String get t2ForAPair => '2 para un par';

  @override
  String get repetitions => 'Repeticiones';

  @override
  String get availablePlatesOrDumbbells => 'Discos o mancuernas disponibles';

  @override
  String get rememberForThisEquipment => 'Recordar para este equipo';

  @override
  String get findOrNameAnExercise => 'Busca o nombra un ejercicio';

  @override
  String createTrim(Object trim) {
    return 'Crear «$trim»';
  }

  @override
  String get customExercise => 'Ejercicio personalizado';

  @override
  String get smallestLoadStep => 'Incremento de carga mínimo';

  @override
  String whatRemoved(Object what) {
    return '$what eliminado';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get retry => 'Reintentar';

  @override
  String get performance => 'Rendimiento';

  @override
  String get addExercise => 'Añadir ejercicio';

  @override
  String get finishLog => 'Finalizar registro';

  @override
  String get keepAsDraft => 'Mantener como borrador';

  @override
  String actionsForName(Object name) {
    return 'Acciones para $name';
  }

  @override
  String get editExercise => 'Editar ejercicio';

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Bajar';

  @override
  String get addSet => 'Añadir serie';

  @override
  String get removeLastSet => 'Quitar la última serie';

  @override
  String get saveAsTemplate => 'Guardar como plantilla';

  @override
  String savedTitleAsATemplate(Object title) {
    return '«$title» guardado como plantilla. Este entrenamiento no cambia hasta que lo guardes.';
  }

  @override
  String nameSetN(Object name, Object n) {
    return '$name · Serie $n';
  }

  @override
  String nameAllWorkingSets(Object name) {
    return '$name · Todas las series de trabajo';
  }

  @override
  String labelRest(Object label) {
    return 'Descanso $label';
  }

  @override
  String get secondsOrMSs => 'Segundos o m:ss';

  @override
  String get applyToAllSets => 'Aplicar a todas las series';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get supersetWithNext => 'Superserie con la siguiente';

  @override
  String get circuitWithNext => 'Circuito con la siguiente';

  @override
  String actionsForSetN(Object n) {
    return 'Acciones para la serie $n';
  }

  @override
  String get editSet => 'Editar serie';

  @override
  String get duplicateSet => 'Duplicar serie';

  @override
  String get removeSet => 'Quitar serie';

  @override
  String labelActions(Object label) {
    return 'Acciones de $label';
  }

  @override
  String get editRests => 'Editar descansos';

  @override
  String get ungroup => 'Desagrupar';

  @override
  String get editExercises => 'Editar ejercicios';

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String couldNotSaveError(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get history => 'Historial';

  @override
  String get exercises => 'Ejercicios';

  @override
  String get noExercisesArePlannedFor =>
      'Aún no hay ejercicios planificados para este entrenamiento. Las notas de arriba lo describen.';

  @override
  String get addExercises => 'Añadir ejercicios';

  @override
  String get fromTheBuiltInTemplate =>
      'De la plantilla integrada. Las cargas las fijas tú; el historial aparece cuando registres un entrenamiento.';

  @override
  String get shareExerciseList => 'Compartir lista de ejercicios';

  @override
  String get noSavedStrengthTemplatesYet =>
      'Aún no hay plantillas de fuerza guardadas. Guarda una desde un entrenamiento planificado.';

  @override
  String get compareWith => 'Comparar con';

  @override
  String estimated1rmUnit(Object unit) {
    return '1RM estimado $unit';
  }

  @override
  String get plannedNotRecorded => 'Planificado, no registrado';

  @override
  String get notes => 'Notas';

  @override
  String get editPerformance => 'Editar rendimiento';

  @override
  String get compareWithASavedWorkout =>
      'Comparar con un entrenamiento guardado';

  @override
  String get sessions => 'Sesiones';

  @override
  String get radarUnavailableRetry => 'Radar no disponible · Reintentar';

  @override
  String get radar => 'Radar';

  @override
  String get weatherDataByRainviewer => 'Datos meteorológicos de RainViewer';

  @override
  String get openstreetmapContributors => '© colaboradores de OpenStreetMap';

  @override
  String get weather => 'Tiempo';

  @override
  String get weatherUnavailableRetry => 'Tiempo no disponible · Reintentar';

  @override
  String get chooseAFixedLocationIn =>
      'Elige una ubicación fija en los ajustes de Tiempo y ubicación, o permite el acceso a la ubicación para el tiempo local.';

  @override
  String get locationSettings => 'Ajustes de ubicación';

  @override
  String get retryLocation => 'Reintentar ubicación';

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
    return 'Bulbo húmedo $toStringAsFixed°C';
  }

  @override
  String get previousForecastDay => 'Día de previsión anterior';

  @override
  String get nextForecastDay => 'Día de previsión siguiente';

  @override
  String daysDayForecast(Object days) {
    return 'Previsión a $days días';
  }

  @override
  String thisProviderCurrentlySuppliesDays(Object days, Object days2) {
    return 'Este proveedor ofrece actualmente $days de $days2 días de previsión.';
  }

  @override
  String get now => 'Ahora';

  @override
  String get sunriseSunset => 'Amanecer / atardecer';

  @override
  String keyKey2(Object key, Object key2) {
    return '☀ $key   ☾ $key2';
  }

  @override
  String get use => 'Usar';

  @override
  String get exerciseDetailsWereNotProvided =>
      'Esta fuente de actividad no proporcionó detalles de los ejercicios.';

  @override
  String get logFromPlan => 'Registrar desde el plan';

  @override
  String get addExerciseDetails => 'Añadir detalles de ejercicios';

  @override
  String get loadSuggestion => 'Sugerencia de carga';

  @override
  String get applyToThisWorkout => 'Aplicar a este entrenamiento';

  @override
  String get keepCurrentLoad => 'Mantener la carga actual';

  @override
  String get setLoadStep => 'Definir incremento de carga';

  @override
  String get viewSupportingSets => 'Ver series de apoyo';

  @override
  String get supportingSets => 'Series de apoyo';

  @override
  String get noRecordedSessionsYet => 'Aún no hay sesiones registradas.';

  @override
  String nameDemonstrationCue(Object name, Object cue) {
    return 'Demostración de $name. $cue';
  }

  @override
  String get noScalesFoundStepOn2 =>
      'No se encontró ninguna báscula. Súbete a la báscula e inténtalo de nuevo.';

  @override
  String get scalePaired => 'Báscula vinculada';

  @override
  String get ok => 'OK';

  @override
  String get pairedReadyToMeasure => '✓ Vinculado: listo para medir';

  @override
  String get chooseHiloCuff => 'Elegir el brazalete Hilo';

  @override
  String get noCuffFoundWakeYour =>
      'No se encontró ningún brazalete. Activa tu brazalete y vuelve a buscar.';

  @override
  String get hiloCuffAktiiaC => 'Brazalete Hilo (AKTIIA C…)';

  @override
  String get onDemandBloodPressureVia =>
      'Presión arterial bajo demanda por BLE';

  @override
  String get selectHiloPodWristband => 'Seleccionar Hilo Pod (pulsera)';

  @override
  String get rescan => 'Buscar de nuevo';

  @override
  String get noDevicesFoundTapTo =>
      'No se encontraron dispositivos. Toca ↻ para buscar de nuevo.';

  @override
  String get polarH10SpotHrv => 'Polar H10 · VFC puntual';

  @override
  String get aSeparateHrvReadingBefore =>
      'Una medición de VFC aparte antes o después de entrenar. Estas mediciones no sustituyen la VFC nocturna de Garmin ni cambian tu puntuación de preparación.';

  @override
  String get wearTheStrapWithMoist =>
      'Colócate la banda con los electrodos humedecidos. Quédate quieto y respira con normalidad. Usa la misma postura y duración para comparar. Tras entrenar, anota cuánto descansaste antes.';

  @override
  String get measurement => 'Medición';

  @override
  String get posture => 'Postura';

  @override
  String get recordingLengthPlus1Min =>
      'Duración de la grabación · más 1 min de estabilización';

  @override
  String get t2Minutes => '2 minutos';

  @override
  String get t5Minutes => '5 minutos';

  @override
  String get minutesSinceTrainingEndedOptional =>
      'Minutos desde que terminó el entrenamiento (opcional)';

  @override
  String get sessionOrNotesOptional => 'Sesión o notas (opcional)';

  @override
  String connectName(Object name) {
    return 'Conectar $name';
  }

  @override
  String get findPolarH10 => 'Buscar Polar H10';

  @override
  String signalRssiDbm(Object rssi) {
    return 'Señal $rssi dBm';
  }

  @override
  String connectedName(Object name) {
    return 'Conectado: $name';
  }

  @override
  String get waitingForHeartRateAnd =>
      'Esperando frecuencia cardíaca e intervalos RR. Comprueba el contacto de la banda.';

  @override
  String get startMeasurement => 'Iniciar medición';

  @override
  String get cancelMeasurement => 'Cancelar medición';

  @override
  String get spotHrvRmssd => 'VFC puntual · RMSSD';

  @override
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  ) {
    return '$accepted/$length intervalos utilizables · $toStringAsFixed % de cobertura';
  }

  @override
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs) {
    return 'lnRMSSD: $lnRmssd · RMSSD sin procesar: $rawRmssdMs ms';
  }

  @override
  String get signalQualityIsTooLow =>
      'La calidad de la señal es demasiado baja para guardar. Repite la medición con buen contacto de la banda. Se requiere al menos un 95 % de intervalos utilizables y un 90 % de cobertura.';

  @override
  String get savedToSpotHrvHistory =>
      'Guardado en el historial de VFC puntual.';

  @override
  String get newMeasurement => 'Nueva medición';

  @override
  String get signalScreeningExcludesPoorContact =>
      'El filtrado de señal excluye mal contacto, RR fuera de 250–2500 ms e intervalos a más del 25 % de la mediana local. Los huecos no se rellenan. No es una prueba médica ni una puntuación de preparación independiente.';

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
      'Solo se muestran juntas las mediciones con el mismo contexto, postura y duración.';

  @override
  String get noMatchingMeasurementsYet => 'Aún no hay mediciones coincidentes.';

  @override
  String tostringasfixedMsRmssdTostringasfixed2Bpm(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return '$toStringAsFixed ms RMSSD · $toStringAsFixed2 bpm';
  }

  @override
  String get exportRrIntervalsCsv => 'Exportar intervalos RR (CSV)';

  @override
  String get deleteMeasurement => 'Eliminar medición';

  @override
  String get remindMeToMeasureHrv =>
      'Recordarme medir la VFC después de entrenar';

  @override
  String get appleHealthIsNoLonger => 'Apple Salud ya no está disponible';

  @override
  String get later => 'Más tarde';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get gripStrength => 'Fuerza de agarre';

  @override
  String get leftKg => 'Izquierda (kg)';

  @override
  String get rightKg => 'Derecha (kg)';

  @override
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg) {
    return 'I $leftKg · D $rightKg kg';
  }

  @override
  String get notificationsAreOffYouCan =>
      'Las notificaciones están desactivadas. Aun así puedes medir desde tu entrenamiento.';

  @override
  String get noRemindersFrom2200 => 'Sin recordatorios de 22:00 a 07:00';

  @override
  String get aReminderThatWouldFall =>
      'Un recordatorio que cayera en este horario se omite, no se pasa a la mañana.';

  @override
  String get remindersArriveQuietlyInThe =>
      'Los recordatorios llegan en silencio a la lista de notificaciones.';

  @override
  String get noForecastForThisDay => 'Sin previsión para este día';

  @override
  String get fullscreen => 'Pantalla completa';

  @override
  String source(Object source) {
    return '● $source';
  }

  @override
  String get shadedAreaProviderSpread =>
      'Área sombreada: dispersión entre proveedores';

  @override
  String get temperatureC => '● Temperatura °C';

  @override
  String get rainMm => '▥ Lluvia mm';

  @override
  String get uvIndex => '— Índice UV';

  @override
  String get closeFullscreenWeatherChart =>
      'Cerrar el gráfico del tiempo a pantalla completa';

  @override
  String get sleepStages => 'FASES DEL SUEÑO';

  @override
  String get noStageTimelineForThis =>
      'Sin línea de tiempo de fases para esta noche.';

  @override
  String round3(Object round) {
    return '$round%';
  }

  @override
  String get examplesOnlyCheckAndEnter =>
      'Solo ejemplos: comprueba e introduce los valores de la etiqueta del producto por ración. Deja en blanco los nutrientes desconocidos; introduce 0 solo si el valor es conocido.';

  @override
  String get nutritionStrategy => 'Estrategia de nutrición';

  @override
  String get noPreWorkoutNutritionStrategy =>
      'No se guardó ninguna estrategia de nutrición previa al entrenamiento.';

  @override
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium) {
    return '$carbs g de carbohidratos/h · $fluid ml/h · $sodium mg de sodio/h';
  }

  @override
  String get forecastUpdatedReviewOrRecalculate =>
      'Previsión actualizada: revisa o recalcula la estrategia guardada.';

  @override
  String strategySavedSavedat(Object savedAt) {
    return 'Estrategia guardada $savedAt';
  }

  @override
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  ) {
    return 'Total durante: $totalCarbs g de carbohidratos · $totalFluid ml · $totalSodium mg de sodio';
  }

  @override
  String every20MinAboutCarbs(Object carbs, Object fluid) {
    return 'Cada 20 min: unos $carbs g de carbohidratos y $fluid ml.';
  }

  @override
  String get packQuantitiesIncludeFullContainers =>
      'Las cantidades a llevar incluyen envases completos; no es necesario consumirlo todo.';

  @override
  String get workoutChangedReviewOrRecalculate =>
      'Entrenamiento modificado: revisa o recalcula la estrategia guardada.';

  @override
  String get conditionsAndFeedingPlan => 'Condiciones y plan de alimentación';

  @override
  String get editStrategy => 'Editar estrategia';

  @override
  String get recalculate => 'Recalcular';

  @override
  String get actualNutrition => 'Nutrición real';

  @override
  String get someProductValuesAreUnknown =>
      'Algunos valores de productos se desconocen; los totales están incompletos.';

  @override
  String get logFoodAndFluids => 'Registrar comida y líquidos';

  @override
  String get recordWhatYouActuallyHad =>
      'Anota lo que realmente tomaste. La ingesta planificada no se copia a este registro.';

  @override
  String get elapsedMinutesIncludingStopsOptional =>
      'Minutos transcurridos, incluidas las paradas (opcional)';

  @override
  String recordedDurationActivityMin(Object activity) {
    return 'Duración registrada: $activity min';
  }

  @override
  String get compareWithSavedStrategy => 'Comparar con la estrategia guardada';

  @override
  String get useMatchedSessionIfAvailable =>
      'Usar la sesión coincidente si está disponible';

  @override
  String get noPlanComparison => 'Sin comparación con el plan';

  @override
  String titleDate(Object title, Object date) {
    return '$title · $date';
  }

  @override
  String get linkedStrategyUnavailable => 'Estrategia vinculada no disponible';

  @override
  String quantityName(Object quantity, Object name) {
    return '$quantity × $name';
  }

  @override
  String get removeIntake => 'Quitar ingesta';

  @override
  String get addFoodOrDrink => 'Añadir comida o bebida';

  @override
  String get iHadNoIntake => 'No tomé nada';

  @override
  String get giGutComfort => 'Comodidad digestiva';

  @override
  String get whatWorkedSymptomsAccessProblems =>
      'Qué funcionó / síntomas / problemas de acceso';

  @override
  String get saveDraft => 'Guardar borrador';

  @override
  String get skipLoggingThisActivity => 'Omitir el registro de esta actividad';

  @override
  String get nutritionAndFluids => 'Nutrición e hidratación';

  @override
  String get productsToleranceAndMeasuredSweat =>
      'Productos, tolerancia y pérdidas de sudor medidas';

  @override
  String get postWorkoutIntakeReminder =>
      'Recordatorio de ingesta tras el entrenamiento';

  @override
  String get onceAfterARecentEndurance =>
      'Una vez tras un entrenamiento de resistencia reciente; horas de silencio 22:00–08:00.';

  @override
  String get enableWorkoutNotifications =>
      'Activar notificaciones de entrenamiento';

  @override
  String get addHiloBpReport => 'Añadir informe de presión Hilo';

  @override
  String get readingPdfReportsIsOnly =>
      'La lectura de informes PDF solo está disponible en iOS y macOS.';

  @override
  String get chooseAnotherReport => 'Elegir otro informe';

  @override
  String get biologicalAge => 'Edad biológica';

  @override
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class) {
    return 'VO₂max $vo2max ml/kg/min · $vo2Class';
  }

  @override
  String get factorContributions => 'Contribución de los factores';

  @override
  String estimatedRangeRoundRound2Years(Object round, Object round2) {
    return 'Rango estimado: $round–$round2 años. Una estimación del modelo, no un diagnóstico médico.';
  }

  @override
  String get noEnergyMeasurementsForThis =>
      'Sin mediciones de energía para este día';

  @override
  String get scanningStepOnTheScale =>
      'Buscando… súbete a la báscula cuando estés listo.';

  @override
  String waistWaistCmUpdateMonthly(Object waist) {
    return 'Cintura: $waist cm – actualiza cada mes en Perfil';
  }

  @override
  String get measuring => 'Midiendo…';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get systolic => 'Sistólica';

  @override
  String get diastolic => 'Diastólica';

  @override
  String get heartRate => 'Frecuencia cardíaca';

  @override
  String get weight => 'Peso';

  @override
  String get bodyFat => 'Grasa corporal';

  @override
  String get duration => 'Duración';

  @override
  String get deep => 'Profundo';

  @override
  String get spo => 'SpO₂';

  @override
  String get activityName => 'Nombre de la actividad';

  @override
  String get sport => 'Deporte';

  @override
  String get distance => 'Distancia';

  @override
  String get saved => 'Guardado';

  @override
  String get connectionFailedCheckYourInternet =>
      'Error de conexión. Revisa tu conexión a internet.';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordTooShort => 'Contraseña demasiado corta';

  @override
  String get loginFailedCheckYourEmail =>
      'Error al iniciar sesión. Revisa tu correo y contraseña.';

  @override
  String get connectionFailedCheckYourCredentials =>
      'Error de conexión. Revisa tus credenciales y tu conexión a internet.';

  @override
  String get region => 'Región';

  @override
  String get hiloPod => 'Hilo Pod';

  @override
  String get hiloAccount => 'Cuenta de Hilo';

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
  String get renphoAccount => 'Cuenta de Renpho';

  @override
  String get garminConnectEmail => 'Correo de Garmin Connect';

  @override
  String get verifyMfaCode => 'Verificar código MFA';

  @override
  String get verificationCode => 'Código de verificación';

  @override
  String errorE(Object e) {
    return 'Error: $e';
  }

  @override
  String get noHiloPodFoundMake =>
      'No se encontró ningún Hilo Pod. Asegúrate de que esté cargado y cerca.';

  @override
  String scanFailedE(Object e) {
    return 'Error en la búsqueda: $e';
  }

  @override
  String get hiloPod2 => 'Hilo Pod';

  @override
  String get scanForPod => 'Buscar el pod';

  @override
  String get scanForPolarH10 => 'Buscar Polar H10';

  @override
  String get couldNotReachPolarCheck =>
      'No se pudo conectar con Polar. Revisa tu conexión.';

  @override
  String get signInAndSendWorkout => 'Iniciar sesión y enviar entrenamiento';

  @override
  String get scanForScale => 'Buscar la báscula';

  @override
  String get passwordRequired => 'Contraseña obligatoria';

  @override
  String get enterYourPhoneNumberWith =>
      'Introduce tu número de teléfono (con prefijo del país, p. ej. +34…) y tu correo de Suunto.';

  @override
  String get enterThePinFromThe => 'Introduce el PIN del SMS.';

  @override
  String get incorrectPinPleaseTryAgain =>
      'PIN incorrecto. Inténtalo de nuevo.';

  @override
  String get phoneNumber => 'Número de teléfono';

  @override
  String get suuntoAccountEmail => 'Correo de la cuenta de Suunto';

  @override
  String get enterPinFromSms => 'Introducir el PIN del SMS';

  @override
  String get verifyConnect => 'Verificar y conectar';

  @override
  String get sendSmsCode => 'Enviar código por SMS';

  @override
  String couldNotSavePreferencesE(Object e) {
    return 'No se pudieron guardar las preferencias: $e';
  }

  @override
  String get mon => 'Lun';

  @override
  String get tue => 'Mar';

  @override
  String get wed => 'Mié';

  @override
  String get thu => 'Jue';

  @override
  String get fri => 'Vie';

  @override
  String get sat => 'Sáb';

  @override
  String get sun => 'Dom';

  @override
  String get male => 'Hombre';

  @override
  String get female => 'Mujer';

  @override
  String get other => 'Otro';

  @override
  String get running => 'Carrera';

  @override
  String get trailRunning => 'Trail running';

  @override
  String get cycling => 'Ciclismo';

  @override
  String get swimming => 'Natación';

  @override
  String get triathlon => 'Triatlón';

  @override
  String get hiking => 'Senderismo';

  @override
  String get rowing => 'Remo';

  @override
  String get buildMyPlan => 'Crear mi plan';

  @override
  String get keepAConsistentBedtimeAnd =>
      'Mantén horarios constantes para acostarte y despertarte y apoyar tu rutina de sueño.';

  @override
  String get thisWorkoutHasNoSets => 'Este entrenamiento no tiene series.';

  @override
  String loadName(Object name) {
    return 'Carga ($name)';
  }

  @override
  String get setLabel => 'Serie';

  @override
  String get lowestReps => 'Repeticiones mínimas';

  @override
  String get highestReps => 'Repeticiones máximas';

  @override
  String get repsPerSide => 'Repeticiones por lado';

  @override
  String get fromReps => 'Desde (rep.)';

  @override
  String get toReps => 'Hasta (rep.)';

  @override
  String get addedLoad => 'Carga añadida';

  @override
  String get assistance => 'Asistencia';

  @override
  String get tempoOptional => 'Ritmo (opcional)';

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get enterTheRepetitionsDone =>
      'Introduce las repeticiones realizadas.';

  @override
  String plannedUnit(Object unit) {
    return 'Previsto $unit';
  }

  @override
  String get repsDone => 'Repeticiones realizadas';

  @override
  String get resistance => 'Resistencia';

  @override
  String get implementsLabel => 'Implementos';

  @override
  String get name => 'Nombre';

  @override
  String get instructionsOptional => 'Instrucciones (opcional)';

  @override
  String get remember => 'Recordar';

  @override
  String get notSavedYet => 'Aún sin guardar';

  @override
  String get saving => 'Guardando…';

  @override
  String get couldNotSave => 'No se pudo guardar';

  @override
  String get plannedValuesAreHintsNot =>
      'Los valores planificados son orientativos, no resultados. Toca una serie para registrarla.';

  @override
  String get completedAsPlanned => 'Completado según lo planificado';

  @override
  String get save => 'Guardar';

  @override
  String get nameTheTemplate => 'Pon nombre a la plantilla.';

  @override
  String setN(Object n) {
    return 'Serie $n';
  }

  @override
  String get changesApplyToThisWorkout =>
      'Los cambios se aplican solo a este entrenamiento. Los entrenamientos completados y otras sesiones no cambian.';

  @override
  String get saveForThisWorkout => 'Guardar para este entrenamiento';

  @override
  String knownForKnownOfOf(Object known, Object of) {
    return 'Conocido en $known de $of series con carga';
  }

  @override
  String get sessionEstimate => 'Estimación de la sesión';

  @override
  String get calculatedRange => 'Rango calculado';

  @override
  String get timedWork => 'Trabajo cronometrado';

  @override
  String get strengthTraining => 'Entrenamiento de fuerza';

  @override
  String get theExercisesCouldNotBe => 'No se pudieron cargar los ejercicios.';

  @override
  String get resumeWorkout => 'Reanudar entrenamiento';

  @override
  String get strengthWorkout => 'Entrenamiento de fuerza';

  @override
  String get untitledTemplate => 'Plantilla sin título';

  @override
  String get theRecordedExercisesCouldNot =>
      'No se pudieron cargar los ejercicios registrados.';

  @override
  String get exercisesPerformed => 'Ejercicios realizados';

  @override
  String get comparedWithThePlanAs =>
      'Comparado con el plan tal como estaba al empezar el registro.';

  @override
  String topWorkingLoadName(Object name) {
    return 'Carga de trabajo máxima ($name)';
  }

  @override
  String get estimated1rmMiddleOfRange => '1RM estimado, mitad del rango';

  @override
  String get noLoggedSessionsYet => 'Aún no hay sesiones registradas.';

  @override
  String get noRadarFramesAvailable => 'No hay imágenes de radar disponibles';

  @override
  String get playRadar => 'Reproducir radar';

  @override
  String get pauseRadar => 'Pausar radar';

  @override
  String get high => 'Alto';

  @override
  String get clear => 'Despejado';

  @override
  String get bodyweight => 'Peso corporal';

  @override
  String get resistance2 => 'Resistencia —';

  @override
  String assistUnit(Object unit) {
    return 'Asistencia $unit';
  }

  @override
  String get reps2 => 'Rep. —';

  @override
  String get notRecorded => 'No registrado';

  @override
  String get skipped => 'Omitido';

  @override
  String get health => 'Salud';

  @override
  String get manual => 'Manual';

  @override
  String expandName(Object name) {
    return 'Expandir $name';
  }

  @override
  String get open => 'Abrir';

  @override
  String get noScalePaired => 'Ninguna báscula vinculada';

  @override
  String get paired => 'Vinculado';

  @override
  String get change => 'Cambiar';

  @override
  String get noCuffPaired => 'Ningún brazalete vinculado';

  @override
  String get noPolarH10FoundWear =>
      'No se encontró ningún Polar H10. Colócate la banda, humedece los electrodos y comprueba que otra app no esté usando ambas conexiones Bluetooth.';

  @override
  String get enterMinutesSinceTrainingEnded =>
      'Introduce los minutos desde que terminó el entrenamiento, de 0 a 1440.';

  @override
  String get timingFollowsYourWorkout => 'El momento sigue a tu entrenamiento.';

  @override
  String get recordingStayStill => 'Grabando · quédate quieto';

  @override
  String get meanHrBpm => 'FC media · bpm';

  @override
  String get pairAPolarH10First => 'Vincula primero un Polar H10.';

  @override
  String get around30MinutesAfterTraining =>
      'Unos 30 minutos después de entrenar, cuando el entrenamiento está disponible a tiempo.';

  @override
  String get reminderDiagnostics => 'Diagnóstico de recordatorios';

  @override
  String get forecast => 'Previsión';

  @override
  String get enterAName => 'Introduce un nombre';

  @override
  String get enterAValidAmount => 'Introduce una cantidad válida';

  @override
  String get enterAPositiveAmount => 'Introduce una cantidad positiva';

  @override
  String get maximum120GH => 'Máximo 120 g/h';

  @override
  String get carbohydrateTargetGH => 'Objetivo de carbohidratos g/h';

  @override
  String get fluidTargetMlH => 'Objetivo de líquidos ml/h';

  @override
  String get sodiumTargetMgHNot => 'Objetivo de sodio mg/h (no sal)';

  @override
  String get surfaceFeedingAccess => 'Superficie / acceso a avituallamiento';

  @override
  String get expectedAscentM => 'Desnivel previsto m';

  @override
  String get expectedAltitudeM => 'Altitud prevista m';

  @override
  String get humidity => 'Humedad %';

  @override
  String get windKmH => 'Viento km/h';

  @override
  String get dayForecast => 'Previsión del día';

  @override
  String get enteredConditions => 'Condiciones introducidas';

  @override
  String get productFoodName => 'Nombre del producto / alimento';

  @override
  String get servingsQuantity => 'Raciones / cantidad';

  @override
  String get when => 'Cuándo';

  @override
  String get carbohydrateGServing => 'Carbohidratos g / ración';

  @override
  String get fluidMlServing => 'Líquido ml / ración';

  @override
  String get caffeineMgServing => 'Cafeína mg / ración';

  @override
  String get proteinGServing => 'Proteínas g / ración';

  @override
  String get gel => 'Gel';

  @override
  String get water => 'Agua';

  @override
  String get sportsDrink => 'Bebida deportiva';

  @override
  String get bar => 'Barrita';

  @override
  String get finishIntakeLog => 'Finalizar registro de ingesta';

  @override
  String get allowNotificationsInSystemSettings =>
      'Permitir notificaciones en los ajustes del sistema';

  @override
  String get importing => 'Importando…';

  @override
  String importNewreadings(Object newReadings) {
    return 'Importar $newReadings';
  }

  @override
  String get reading => 'Leyendo…';

  @override
  String get chooseReportPdf => 'Elegir informe (PDF)';

  @override
  String get yourTrainingHistoryIsReady =>
      'Tu historial de entrenamiento está listo';

  @override
  String get importingYourTrainingHistory =>
      'Importando tu historial de entrenamiento';

  @override
  String get stopImport => 'Detener importación';

  @override
  String get dismiss => 'Descartar';

  @override
  String get openai => 'OpenAI';

  @override
  String get appleIntelligence => 'Apple Intelligence';

  @override
  String get nonAiBriefing => 'Resumen sin IA';

  @override
  String get noBriefing => 'Sin resumen';

  @override
  String get ruleBasedSummaryFromYour =>
      'Resumen basado en reglas con tus datos de salud, sin llamadas a API';

  @override
  String get hideTheBriefingCard => 'Ocultar la tarjeta de resumen';

  @override
  String get flutter => 'Flutter';

  @override
  String get stateManagement => 'Gestión de estado';

  @override
  String get bluetoothLe => 'Bluetooth LE';

  @override
  String get interactiveMaps => 'Mapas interactivos';

  @override
  String get chartsGraphs => 'Gráficos y diagramas';

  @override
  String get secureCredentialStorage => 'Almacenamiento seguro de credenciales';

  @override
  String get markdownRendering => 'Renderizado de Markdown';

  @override
  String get appleOnDeviceAi => 'IA de Apple en el dispositivo';

  @override
  String get cryptography => 'Criptografía';

  @override
  String get appleHealthHealthConnect => 'Apple Salud y Health Connect';

  @override
  String get runtimePermissions => 'Permisos en tiempo de ejecución';

  @override
  String get shareExport => 'Compartir y exportar';

  @override
  String get openUrls => 'Abrir URL';

  @override
  String get internationalisation => 'Internacionalización';

  @override
  String get utilities => 'Utilidades';

  @override
  String get icons => 'Iconos';

  @override
  String get fjelia => 'Fjelia';

  @override
  String get fjeliaFeedback => 'Comentarios sobre Fjelia';

  @override
  String get couldNotSendTheReport =>
      'No se pudo enviar el informe. Tu texto sigue aquí. Inténtalo de nuevo.';

  @override
  String get yourEmail => 'Tu correo electrónico';

  @override
  String get enterAValidEmailAddress =>
      'Introduce una dirección de correo válida.';

  @override
  String get subject => 'Asunto';

  @override
  String get sending => 'Enviando…';

  @override
  String get sendReport => 'Enviar informe';

  @override
  String get sleepRecovery => 'Sueño y recuperación';

  @override
  String get activitiesTraining => 'Actividades y entrenamiento';

  @override
  String get bodyWellness => 'Cuerpo y bienestar';

  @override
  String get hilo => 'Hilo';

  @override
  String get hiloBle => 'Hilo BLE';

  @override
  String get garminApi => 'Garmin (API)';

  @override
  String get renphoScale => 'Báscula Renpho';

  @override
  String get connected => 'Conectado';

  @override
  String get notConnected => 'No conectado';

  @override
  String get manage => 'Gestionar';

  @override
  String get connect => 'Conectar';

  @override
  String get habits => 'Hábitos';

  @override
  String get smokingAlcohol => 'Tabaco, alcohol';

  @override
  String get clinicalLab => 'Análisis clínicos';

  @override
  String get hba1cLipidsKidney => 'HbA1c, lípidos, riñón';

  @override
  String get sex => 'Sexo';

  @override
  String get smoking => 'Tabaquismo';

  @override
  String get never => 'Nunca';

  @override
  String get former => 'Anterior';

  @override
  String get current => 'Actual';

  @override
  String get hba1c => 'HbA1c';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get prediabetes => 'Prediabetes';

  @override
  String get type1 => 'Tipo 1';

  @override
  String get type2 => 'Tipo 2';

  @override
  String get apob => 'ApoB';

  @override
  String get optionalPlansAndPaceGuides =>
      'Opcional. Los planes y las guías de ritmo lo usan; el desnivel de arriba también influye en el entrenamiento.';

  @override
  String get addRaceGoal2 => 'Añadir objetivo de carrera';

  @override
  String get editRaceGoal => 'Editar objetivo de carrera';

  @override
  String get trailRunning2 => 'Trail running';

  @override
  String get roadCycling => 'Ciclismo de carretera';

  @override
  String get gravel => 'Gravel';

  @override
  String get indoorRowing => 'Remo indoor';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get committed => 'Confirmado';

  @override
  String get flexible => 'Flexible';

  @override
  String get notGoing => 'No voy';

  @override
  String get notSaid => 'Sin indicar';

  @override
  String get finish => 'Tiempo final';

  @override
  String get saveGoal => 'Guardar objetivo';

  @override
  String get exportAllRecordedWorkoutsAs =>
      'Exportar todos los entrenamientos registrados como hoja de cálculo.';

  @override
  String get backupsIncludeYourHealthData =>
      'Las copias de seguridad incluyen tus datos de salud, planes de entrenamiento y ajustes del perfil. Las credenciales de acceso se excluyen. Restaurar sustituye los datos locales.';

  @override
  String get trail => 'Trail';

  @override
  String get inlineSkating => 'Patinaje en línea';

  @override
  String get nordicClassic => 'Esquí nórdico clásico';

  @override
  String get skateSkiing => 'Esquí de skating';

  @override
  String get strength => 'Fuerza';

  @override
  String get walking => 'Caminar';

  @override
  String get yoga => 'Yoga';

  @override
  String get skiing => 'Esquí';

  @override
  String get climbing => 'Escalada';

  @override
  String get monday => 'Lunes';

  @override
  String get sunday => 'Domingo';

  @override
  String get month => 'Mes';

  @override
  String get week => 'Semana';

  @override
  String get list => 'Lista';

  @override
  String get train => 'Entrenar';

  @override
  String get restDay => 'Descanso';

  @override
  String get kilogramsKg => 'Kilogramos (kg)';

  @override
  String get poundsLb => 'Libras (lb)';

  @override
  String get regenerateWorkouts => 'Regenerar entrenamientos';

  @override
  String get starting => 'Iniciando';

  @override
  String get allPlannedWorkoutsDeleted =>
      'Se eliminaron todos los entrenamientos planificados.';

  @override
  String get searching => 'Buscando…';

  @override
  String get searchCity => 'Buscar ciudad';

  @override
  String get fixedLocationSavedWeatherWill =>
      'Ubicación fija guardada. El tiempo se actualizará.';

  @override
  String get locationDisabledThePlanWeather =>
      'Ubicación desactivada. La tarjeta del tiempo del plan está oculta.';

  @override
  String locationSetToName(Object name) {
    return 'Ubicación establecida en $name';
  }

  @override
  String get notEnoughDaytimeAndNighttime =>
      'No hay suficientes mediciones diurnas y nocturnas';

  @override
  String get onlyTheWeightWasReceived =>
      'Solo se recibió el peso. Para la grasa corporal, el músculo y el resto de valores, quédate descalzo sobre los electrodos metálicos hasta que la báscula termine.';

  @override
  String get addYourWaistInProfile =>
      'Añade tu cintura en Perfil para la grasa visceral.';

  @override
  String get manualActivity => 'Actividad manual';

  @override
  String get theseCredentialsAreStoredEncrypted =>
      'Estas credenciales se guardan cifradas en tu dispositivo (llavero de iOS / Android Keystore). Nunca se envían a ningún servidor que no sea Hilo.';

  @override
  String get corosCredentialsAreStoredEncrypted =>
      'Las credenciales de Coros se guardan cifradas en tu dispositivo. Fjelia lee los datos directamente de la API en la nube de Coros, la misma que usa la app web Coros Training Hub.';

  @override
  String get connectAnyCombinationYouCan =>
      'Conecta cualquier combinación: siempre podrás añadir más después en Ajustes.';

  @override
  String get garminCredentialsAreStoredEncrypted =>
      'Las credenciales de Garmin se guardan cifradas en tu dispositivo. Fjelia usa la API no oficial de Garmin Connect, el mismo enfoque que muchas apps de la comunidad.';

  @override
  String get enterTheVerificationCode => 'Introduce el código de verificación';

  @override
  String get appleHealthDataAccess =>
      'Fjelia lee tus datos de salud de Apple Salud. Con tu permiso, también puede escribir datos sincronizados en Apple Salud. Gestiona el acceso en los ajustes de tu dispositivo.';

  @override
  String get scanAgain => 'Buscar de nuevo';

  @override
  String get wearTheHiloBandDuring =>
      'Lleva la pulsera Hilo durante el sueño para un registro continuo de la presión arterial. Los datos se sincronizan automáticamente cada mañana al abrir la app.';

  @override
  String get noPolarH10FoundWear2 =>
      'No se encontró ningún Polar H10. Colócate la banda con los electrodos húmedos y asegúrate de que ninguna otra app (o reloj) esté conectada; luego busca de nuevo.';

  @override
  String get wearTheStrapWithMoist2 =>
      'Colócate la banda con los electrodos húmedos antes de buscar. Mide después con + → Medición de VFC con Polar H10; los resultados aparecen junto a tu VFC nocturna.';

  @override
  String get signedInPlannedWorkoutsCan =>
      'Sesión iniciada. Ya se pueden enviar entrenamientos planificados a Polar. Las sesiones anteriores se importan con la próxima sincronización completa del historial.';

  @override
  String get saveYourPolarFlowLogin =>
      'Guarda tu inicio de sesión de Polar Flow para enviar entrenamientos planificados e importar sesiones de más de 30 días. Se queda en el llavero de este dispositivo y solo se envía a Polar. Envía un entrenamiento desde su hoja del planificador y luego sincroniza Polar Flow con tu reloj. Comprueba que tus zonas de frecuencia cardíaca de Polar coincidan con las de Fjelia.';

  @override
  String get signInToSendThis =>
      'Inicia sesión para enviar este entrenamiento a tu calendario de Polar Flow. Tu inicio de sesión se queda en el llavero de este dispositivo y solo se envía a Polar. Tras enviarlo, sincroniza Polar Flow con tu reloj.';

  @override
  String get checkAndSave => 'Comprobar y guardar';

  @override
  String get noScaleFoundStepOn =>
      'No se encontró ninguna báscula. Súbete a la báscula para despertarla y vuelve a buscar.';

  @override
  String get stepOnTheScaleBefore =>
      'Súbete a la báscula antes de buscar para despertarla. Después usa + → Báscula RENPHO para medir.';

  @override
  String get renphoCredentialsAreStoredEncrypted =>
      'Las credenciales de Renpho se guardan cifradas en tu dispositivo. Fjelia se comunica directamente con la API en la nube de Renpho.';

  @override
  String get couldNotSendSmsCheck =>
      'No se pudo enviar el SMS. Revisa tu número de teléfono y tu conexión a internet.';

  @override
  String get theEmailIsUsedFor =>
      'El correo se usa para firmar las solicitudes de forma segura y no se envía a los servidores de Suunto.';

  @override
  String get suuntoUsesSmsVerificationSame =>
      'Suunto usa verificación por SMS (igual que la app de Suunto). Se enviará un PIN de un solo uso a tu teléfono. Tus credenciales se guardan cifradas solo en el dispositivo.';

  @override
  String get tellUsAboutYourRace =>
      'Cuéntanos sobre tu carrera y tu horario. Fjelia crea tu plan ahora y deduce tu nivel de tus actividades pasadas (Garmin, Suunto, Polar, COROS, Apple Salud) cuando se descarguen.';

  @override
  String get noAccountConnectedSoFjelia =>
      'No hay ninguna cuenta conectada, así que Fjelia no tiene historial del que aprender. Conecta Garmin, Suunto, Polar, COROS o Apple Salud y decidirá tu entrenamiento real.';

  @override
  String get yourPastActivitiesAreStill =>
      'Tus actividades pasadas aún se están importando. Puedes crear tu plan ahora: se afinará automáticamente cuando termine la importación.';

  @override
  String get buildingYourPlan => 'Creando tu plan…';

  @override
  String get saveContinue => 'Guardar y continuar';

  @override
  String get addYourMainPriorityA =>
      'Añade tu carrera principal (prioridad A). El plan se periodiza hacia ella: base, desarrollo, pico y puesta a punto. Sin objetivo de carrera aún no se genera ningún plan.';

  @override
  String get noMeasurementsYet => 'Aún no hay mediciones';

  @override
  String get date => 'Fecha';

  @override
  String deepSleepIsBelowOptimal(Object round) {
    return 'El sueño profundo está por debajo del óptimo ($round %). Evita el alcohol y las comidas copiosas 3 h antes de acostarte.';
  }

  @override
  String get finishWithSetsOpen => '¿Terminar con series abiertas?';

  @override
  String get completeThePlannedWorkout =>
      '¿Completar el entrenamiento planificado?';

  @override
  String get marksThePlannedSessionAs =>
      'Marca la sesión planificada como hecha con este entrenamiento.';

  @override
  String get discardThisWorkout => '¿Descartar este entrenamiento?';

  @override
  String get removesTheWorkoutAndEvery =>
      'Elimina el entrenamiento y cada serie registrada en él.';

  @override
  String assistanceName(Object name) {
    return 'Asistencia ($name)';
  }

  @override
  String get enterSecondsOrMSs => 'Introduce segundos o m:ss.';

  @override
  String get enterTheLoadAsA => 'Introduce la carga como número.';

  @override
  String get loadCannotBeNegative => 'La carga no puede ser negativa.';

  @override
  String get enterTheEffortValue => 'Introduce el valor de esfuerzo.';

  @override
  String get nameTheExercise => 'Pon nombre al ejercicio.';

  @override
  String get atLeastOneImplement => 'Al menos un implemento.';

  @override
  String get anIncrementMustBePositive => 'Un incremento debe ser positivo.';

  @override
  String get enterAPositiveStep => 'Introduce un incremento positivo.';

  @override
  String get repsInReserve => 'Repeticiones en reserva';

  @override
  String get loadPerImplement => 'Carga por implemento';

  @override
  String get restAfterThisSet => 'Descanso tras esta serie';

  @override
  String get enterHowLongTheSet => 'Introduce cuánto duró la serie.';

  @override
  String get repsDonePerSide => 'Repeticiones hechas por lado';

  @override
  String plannedRepminRepmax(Object repMin, Object repMax) {
    return 'Previsto $repMin–$repMax';
  }

  @override
  String get restTakenBeforeTheNext =>
      'Descanso tomado antes de la siguiente serie';

  @override
  String get equipment => 'Equipo';

  @override
  String get implementsUsedTogether => 'Implementos usados juntos';

  @override
  String get smallestLoadStepOptional =>
      'Incremento de carga mínimo (opcional)';

  @override
  String get theSmallestChangeYourPlates =>
      'El cambio más pequeño que permiten tus discos, mancuernas o máquina, recordado para este equipo.';

  @override
  String get loadStep => 'Incremento de carga';

  @override
  String get finishWithIncompleteData => '¿Terminar con datos incompletos?';

  @override
  String get leaveWithoutSaving => '¿Salir sin guardar?';

  @override
  String get theLastChangeCouldNot => 'No se pudo guardar el último cambio.';

  @override
  String get comparedWithAPlanChosen =>
      'Comparado con un plan elegido después del entrenamiento. Los valores planificados son orientativos, no resultados.';

  @override
  String get lastSet => 'Última serie';

  @override
  String get templateName => 'Nombre de la plantilla';

  @override
  String get betweenExercises => 'Entre ejercicios';

  @override
  String get betweenRounds => 'Entre rondas';

  @override
  String get discardChanges => '¿Descartar los cambios?';

  @override
  String get yourEditsToThisWorkout =>
      'Tus cambios en este entrenamiento no están guardados.';

  @override
  String get estimatedDuration => 'Duración estimada';

  @override
  String get workingSets => 'Series de trabajo';

  @override
  String get estimatedExternalVolume => 'Volumen externo estimado';

  @override
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion) {
    return 'Carga aumentada de $unit a $unit2 tras tu revisión (regla v$ruleVersion).';
  }

  @override
  String get thePlannedWorkoutHasNo =>
      'El entrenamiento planificado no tiene ejercicios que registrar.';

  @override
  String get completedSets => 'Series completadas';

  @override
  String get knownExternalVolume => 'Volumen externo conocido';

  @override
  String get updateStrengthSessions2 => '¿Actualizar las sesiones de fuerza?';

  @override
  String get upcomingSessionsArePlannedAgain =>
      'Las próximas sesiones se planifican de nuevo desde hoy: la fuerza sigue tus objetivos de carrera cada día de fuerza, con sesiones variadas. Los entrenamientos completados y omitidos se conservan; los ejercicios que cambiaste en una próxima sesión de fuerza se sustituyen.';

  @override
  String get thisSessionUsesAnEarlier =>
      'Esta sesión usa una plantilla de fuerza anterior. Los planes actualizados varían la fuerza según la fase y el objetivo de carrera y usan cada día de fuerza.';

  @override
  String get estimated1rmUsesEpleyAnd =>
      'El 1RM estimado usa Epley y Brzycki en series de trabajo completadas de 1–10 repeticiones con carga conocida y se muestra como el rango entre ambos. Es una estimación, no un máximo comprobado.';

  @override
  String get localWeather => 'Tiempo local';

  @override
  String get today => 'Hoy';

  @override
  String get low => 'Bajo';

  @override
  String get moderate => 'Moderado';

  @override
  String get overcast => 'Nublado';

  @override
  String get partlyCloudy => 'Parcialmente nublado';

  @override
  String collapseName(Object name) {
    return 'Contraer $name';
  }

  @override
  String get variableLoads => 'Cargas variables';

  @override
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  ) {
    return 'Regla v$strengthProgressionRuleVersion: las últimas $strengthProgressionMinSessions sesiones comparables, cada serie en el tope de su objetivo de repeticiones, con esfuerzo registrado y no más duro de lo previsto. $reason';
  }

  @override
  String get stepOnYourScaleBefore => 'Súbete a la báscula antes de buscar';

  @override
  String get scanning => 'Buscando…';

  @override
  String get pair => 'Vincular';

  @override
  String get selectYourAktiiaPWristband =>
      'Selecciona tu pulsera AKTIIA P…. Colócala en el cargador para despertarla si no aparece.';

  @override
  String get measurementInterruptedWhileTheApp =>
      'Medición interrumpida mientras la app estaba en segundo plano. Repítela.';

  @override
  String get noRecentRrDataWith =>
      'Sin datos RR recientes con buen contacto. Revisa la banda y repite la medición.';

  @override
  String get settlingStayStill => 'Estabilizando · quédate quieto';

  @override
  String get deleteSpotHrvMeasurement =>
      '¿Eliminar la medición de VFC puntual?';

  @override
  String get thisRemovesTheRecordingAnd =>
      'Esto elimina la grabación y sus intervalos RR sin procesar.';

  @override
  String get appleHealthStoppedAnsweringSo =>
      'Apple Salud dejó de responder, así que Fjelia lo desconectó y ya no lee ni escribe datos de salud.\n\nPermite de nuevo a Fjelia en Ajustes → Salud → Acceso a datos y dispositivos → Fjelia y vuelve a conectar Apple Salud.';

  @override
  String get thisRemovesTheSelectedGrip =>
      'Esto elimina la medición de fuerza de agarre seleccionada.';

  @override
  String get hideReminderDiagnostics => 'Ocultar diagnóstico de recordatorios';

  @override
  String get loading => 'Cargando…';

  @override
  String get touchTheChartForDetails => 'Toca el gráfico para ver detalles';

  @override
  String get indoor => 'Interior';

  @override
  String get road => 'Carretera';

  @override
  String get technical => 'Técnico';

  @override
  String get snow => 'Nieve';

  @override
  String get pool => 'Piscina';

  @override
  String get openWater => 'Aguas abiertas';

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
    return 'Lleva unos $gels geles ($gelCarbs g de carbohidratos cada uno) + $bottles × botellas de $bottleMl ml. $drinkCarbs g de carbohidratos proceden del polvo de bebida.';
  }

  @override
  String get intakeNotRecorded => 'Ingesta no registrada';

  @override
  String get loggingDeclinedIntakeUnknown =>
      'Registro rechazado: ingesta desconocida';

  @override
  String get confirmedNoIntake => 'Confirmado: sin ingesta';

  @override
  String get draft => 'Borrador · ';

  @override
  String get actualIntakePerServing => 'Ingesta real · por ración';

  @override
  String get minuteIntoWorkoutDuringOnly =>
      'Minuto del entrenamiento (solo durante, opcional)';

  @override
  String get sodiumMgServingNotSalt => 'Sodio mg / ración (no sal)';

  @override
  String get comfortable => 'Cómodo';

  @override
  String get mildSymptoms => 'Síntomas leves';

  @override
  String get moderateSymptoms => 'Síntomas moderados';

  @override
  String get severeSymptoms => 'Síntomas graves';

  @override
  String get personalNutritionSettings => 'Ajustes personales de nutrición';

  @override
  String get practisedCarbohydrateToleranceGH =>
      'Tolerancia a carbohidratos entrenada g/h (hasta 120)';

  @override
  String get workoutNotificationsEnabled =>
      'Notificaciones de entrenamiento activadas';

  @override
  String get exportTheMonthlyReportAs =>
      'Exporta el informe mensual como PDF en la app de Hilo y elígelo aquí. Solo se importan las mediciones; el nombre, el correo y los datos corporales del informe se ignoran.';

  @override
  String get nothingNewAllReadingsWere =>
      'Nada nuevo: todas las mediciones ya estaban guardadas.';

  @override
  String get historyImportIncomplete => 'Importación del historial incompleta';

  @override
  String get youCanKeepUsingFjelia =>
      'Puedes seguir usando Fjelia, pero mantenla abierta: iOS pausa la importación cuando la app está en segundo plano y continúa la próxima vez que la abras. Tu plan se calibra al terminar la importación.';

  @override
  String get addYourBirthYearIn =>
      'Añade tu año de nacimiento en Ajustes → Perfil para ver tu estimación.';

  @override
  String get fitnessAge => 'Edad de forma';

  @override
  String get estLifespan => 'Esperanza de vida est.';

  @override
  String get delta => 'Diferencia';

  @override
  String couldNotOpenKey(Object key) {
    return 'No se pudo abrir $key';
  }

  @override
  String get appleIntelligenceIsNotAvailable =>
      'Apple Intelligence no está disponible en este dispositivo (requiere un iPhone o Mac compatible con iOS/macOS 26 o posterior y Apple Intelligence activado en Ajustes). Elige otro proveedor y añade tu propia clave API para usar el entrenador.';

  @override
  String get personalisedMorningLunchAfternoonEvening =>
      'Resumen personalizado de mañana, mediodía, tarde y noche';

  @override
  String get enterASubject => 'Introduce un asunto.';

  @override
  String get message => 'Mensaje';

  @override
  String get enterAMessageOfAt =>
      'Introduce un mensaje de al menos 10 caracteres.';

  @override
  String get garminConnect => 'Garmin Connect';

  @override
  String get hiloBloodPressure => 'Hilo (presión arterial)';

  @override
  String get renphoBodyScale => 'Renpho (báscula corporal)';

  @override
  String get hiloPodCuff => 'Hilo Pod / brazalete';

  @override
  String disconnectLabel(Object label) {
    return '¿Desconectar $label?';
  }

  @override
  String get yourSavedMeasurementsWillRemain =>
      'Tus mediciones guardadas permanecerán en este dispositivo.';

  @override
  String get notEnoughRecentHeartRate =>
      'No hay suficientes datos recientes de frecuencia cardíaca para ajustar las zonas.';

  @override
  String get aerobicBase => 'Base aeróbica';

  @override
  String get tempo => 'Tempo';

  @override
  String get lactateThreshold => 'Umbral de lactato';

  @override
  String get birthYearHeightWaist => 'Año de nacimiento, altura, cintura';

  @override
  String get enterAValidValue => 'Introduce un valor válido';

  @override
  String get birthYear => 'Año de nacimiento';

  @override
  String get height => 'Altura';

  @override
  String get waist => 'Cintura';

  @override
  String get yearsSinceQuit => 'Años desde que lo dejaste';

  @override
  String get cigarettesPerDay => 'Cigarrillos al día';

  @override
  String get standardDrinksPerMonth => 'Bebidas estándar al mes';

  @override
  String get enterAValidNumber => 'Introduce un número válido';

  @override
  String get enterARaceName => 'Introduce el nombre de la carrera';

  @override
  String get useHMmOrH =>
      'Usa h:mm o h:mm:ss, un tiempo que realmente podrías correr';

  @override
  String get flexibleThePlanMayDrop =>
      'Flexible: el plan puede descartar este evento si choca con uno más importante.';

  @override
  String get selectARaceDate => 'Selecciona una fecha de carrera';

  @override
  String thatIsTenTimesOr(Object likely) {
    return 'Es diez veces (o una décima parte de) los $likely km habituales. ¿Usar $likely km en su lugar?';
  }

  @override
  String get addGoal => 'Añadir objetivo';

  @override
  String get restoreFailed => 'Error al restaurar';

  @override
  String get replaceLocalData => '¿Reemplazar los datos locales?';

  @override
  String get restoringThisBackupReplacesAll =>
      'Restaurar esta copia de seguridad sustituye todos los registros locales de salud y entrenamiento. Se conservan las credenciales de acceso existentes.';

  @override
  String get openingBackupZip => 'Abriendo el ZIP de la copia de seguridad';

  @override
  String get addAFutureRaceGoal =>
      'Añade primero un objetivo de carrera futuro.';

  @override
  String get deleteAllWorkouts2 => '¿Eliminar todos los entrenamientos?';

  @override
  String get thisDeletesPlannedWorkoutsOn =>
      'Esto elimina los entrenamientos planificados en este teléfono y en la plataforma de tu reloj conectado. Las actividades completadas se conservan.';

  @override
  String get regenerateWorkouts2 => '¿Regenerar los entrenamientos?';

  @override
  String get noRaceGoalsYetAdd =>
      'Aún no hay objetivos de carrera. Añade uno o sincroniza desde Garmin.';

  @override
  String get deleteRaceGoal => '¿Eliminar el objetivo de carrera?';

  @override
  String deletingFailedFailure(Object failure) {
    return 'Error al eliminar: $failure';
  }

  @override
  String allPlannedWorkoutsDeletedRemoved(Object removed) {
    return 'Se eliminaron todos los entrenamientos planificados. Eliminados de tus plataformas: $removed.';
  }

  @override
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return 'Usando la ubicación actual: $toStringAsFixed, $toStringAsFixed2';
  }

  @override
  String get typeSleep => 'Sueño';

  @override
  String get typeBloodPressure => 'Presión arterial';

  @override
  String get addHiloBpReportPdf => 'Añadir informe de presión Hilo (PDF)';

  @override
  String get hiloCuffBle => 'Brazalete Hilo (BLE)';

  @override
  String get typeSpo2 => 'SpO₂ / pulsioxímetro';

  @override
  String get typeWeightScale => 'Báscula de peso';

  @override
  String get polarH10HrvMeasurement => 'Medición de VFC con Polar H10';

  @override
  String samplingWouldStartMinutes(Object minutes) {
    return 'El muestreo empezaría unos $minutes min después de terminar el entrenamiento.';
  }

  @override
  String samplingStartedMinutes(Object minutes) {
    return 'El muestreo empezó $minutes min después de terminar el entrenamiento.';
  }

  @override
  String get unknown => 'Desconocido';

  @override
  String get before => 'Antes';

  @override
  String get during => 'Durante';

  @override
  String get after => 'Después';

  @override
  String get enumWarmUp => 'Calentamiento';

  @override
  String get enumWorking => 'De trabajo';

  @override
  String get enumBackOff => 'Back-off';

  @override
  String get enumTechnique => 'Técnica';

  @override
  String get enumExternalLoad => 'Carga externa';

  @override
  String get enumBandResistance => 'Banda / resistencia';

  @override
  String get enumTotalLoad => 'Carga total';

  @override
  String get enumPerImplement => 'Por implemento';

  @override
  String get enumOneImplement => 'Un implemento';

  @override
  String get enumBothSides => 'Ambos lados';

  @override
  String get enumAlternatingTotalReps => 'Alterno, repeticiones totales';

  @override
  String get enumPartial => 'Parcial';

  @override
  String get enumFailed => 'Fallida';

  @override
  String get enumStraightSets => 'Series tradicionales';

  @override
  String get enumSuperset => 'Superserie';

  @override
  String get enumCircuit => 'Circuito';

  @override
  String get enumRir => 'RIR';

  @override
  String get enumRpe110 => 'RPE 1–10';

  @override
  String get enumBeforeTraining => 'Antes del entrenamiento';

  @override
  String get enumAfterTraining => 'Después del entrenamiento';

  @override
  String get enumResting => 'En reposo';

  @override
  String get enumSeated => 'Sentado';

  @override
  String get enumLyingDown => 'Tumbado';

  @override
  String get duringRoutineGelsAreNot =>
      'Durante: no hacen falta geles de rutina en esta sesión corta/fácil. Bebe según la sed.';

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      'Durante: reparte los carbohidratos y las bebidas en tomas pequeñas y regulares. Cuenta los carbohidratos de la bebida en el mismo total que geles y comida.';

  @override
  String get fluidIsAnEditableStarting =>
      'Los líquidos son una estimación inicial editable, no una cuota. Guíate por la sed, la ingesta habitual y las pérdidas de sudor medidas; no fuerces más agua.';

  @override
  String get afterHaveCarbohydrateAndA =>
      'Después: toma carbohidratos y una comida con proteínas. Prioriza la recuperación y la rehidratación si hay otra sesión pronto.';

  @override
  String get swimmingPlaceALabelledBottle =>
      'Natación: deja una botella etiquetada en el borde de la piscina y aprovecha las pausas entre series para beber o alimentarte. Las condiciones de la piscina pueden diferir del tiempo exterior.';

  @override
  String get runningCarryAccessibleGelsFlasks =>
      'Carrera: lleva geles/flasks accesibles o planifica el avituallamiento en los puestos; practica los mismos productos y tiempos antes de competir.';

  @override
  String get servingSizesAndToleranceMust =>
      'Los tamaños de ración y la tolerancia deben ser positivos.';

  @override
  String get enterFiniteNonNegativeMeasurements =>
      'Introduce mediciones finitas y no negativas.';

  @override
  String get targetsMustBeFiniteAnd =>
      'Los objetivos deben ser finitos y no negativos.';

  @override
  String get conditionsMustBeFiniteOr =>
      'Las condiciones deben ser finitas o desconocidas.';

  @override
  String get humidityMustBeBetween0 => 'La humedad debe estar entre 0 y 100 %.';

  @override
  String get noIntakeCannotIncludeFood =>
      '«Sin ingesta» no puede incluir comida ni bebidas.';

  @override
  String get addAnItemOrConfirm =>
      'Añade un elemento o confirma que no tomaste nada.';

  @override
  String get eachIntakeNeedsAProduct =>
      'Cada ingesta necesita un producto y un momento válido.';

  @override
  String get quantityMustBePositive => 'La cantidad debe ser positiva.';

  @override
  String get thisActivityNoLongerExists => 'Esta actividad ya no existe.';

  @override
  String get practisedCarbohydrateToleranceMustNot =>
      'La tolerancia a carbohidratos entrenada no debe superar 120 g/h.';

  @override
  String get measuredSweatRateMustBe =>
      'La tasa de sudoración medida debe ser positiva o dejarse desconocida.';

  @override
  String get increasePractisedToleranceInNutrition =>
      'Aumenta la tolerancia entrenada en los ajustes de nutrición antes de elegir un objetivo mayor.';

  @override
  String get fluidTargetExceedsYourMeasured =>
      'El objetivo de líquidos supera tu tasa de sudoración medida. Revisa la medición o el objetivo.';

  @override
  String get elapsedWorkoutTimeMustBe =>
      'El tiempo de entrenamiento transcurrido debe ser positivo o dejarse en blanco.';

  @override
  String get intakeAmountsMustBeFinite =>
      'Las cantidades de ingesta deben ser finitas y no negativas.';

  @override
  String get selectedStrategyUnavailableChooseAnother =>
      'La estrategia seleccionada no está disponible. Elige otra estrategia o ninguna comparación.';

  @override
  String get recordYourWorkoutNutrition =>
      'Registra tu nutrición del entrenamiento';

  @override
  String get addTheFoodAndFluids =>
      'Añade la comida y los líquidos que realmente tomaste en el historial de la actividad.';

  @override
  String get logIntake => 'Registrar ingesta';

  @override
  String get in30Minutes => 'En 30 minutos';

  @override
  String get loadSuggestionsCoverStraightSets =>
      'Las sugerencias de carga solo se aplican a series tradicionales con repeticiones.';

  @override
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  ) {
    return 'Necesita $strengthProgressionMinSessions sesiones registradas de este ejercicio.';
  }

  @override
  String get recentHistoryIsTooOld =>
      'El historial reciente es demasiado antiguo para una sugerencia.';

  @override
  String get theLastSessionDidNot =>
      'La última sesión no usó una única carga conocida.';

  @override
  String get theLoadChangedBetweenThe =>
      'La carga cambió entre las sesiones recientes.';

  @override
  String get notEverySetReachedThe =>
      'No todas las series alcanzaron el tope de su objetivo de repeticiones.';

  @override
  String get recordEffortRirOrRpe =>
      'Registra el esfuerzo (RIR o RPE) en la última serie para recibir sugerencias.';

  @override
  String get recentSetsWereHarderThan =>
      'Las series recientes fueron más duras de lo previsto.';

  @override
  String get thisWorkoutAlreadyHasIts =>
      'Este entrenamiento ya tiene su propia carga; se queda como está.';

  @override
  String get yourRecentSetsMetThe =>
      'Tus series recientes cumplieron la regla de progresión. Define el incremento de carga más pequeño de este equipo para revisar una carga.';

  @override
  String get thisWorkoutNoLongerExists => 'Este entrenamiento ya no existe.';

  @override
  String thisStrengthPlanCannotBe(Object message) {
    return 'Este plan de fuerza no se puede leer ($message).';
  }

  @override
  String get thisStrengthPlanCannotBe2 =>
      'Este plan de fuerza no se puede leer.';

  @override
  String get addAtLeastOneExercise => 'Añade al menos un ejercicio.';

  @override
  String get thisWorkoutWasChangedElsewhere =>
      'Este entrenamiento se cambió en otro lugar. Tus cambios se conservan; recarga para ver la versión más reciente.';

  @override
  String get thePlanThisWorkoutIs =>
      'El plan con el que se compara este entrenamiento no se puede leer.';

  @override
  String get thisLogWasChangedElsewhere =>
      'Este registro se cambió en otro lugar. Tus entradas se conservan; recarga para ver la versión más reciente.';

  @override
  String get thisZipIsNotA =>
      'Este ZIP no es una copia de seguridad de Fjelia compatible.';

  @override
  String get theBackupDatabaseIsDamaged =>
      'La base de datos de la copia de seguridad está dañada.';

  @override
  String get invalidBackupData => 'Datos de copia de seguridad no válidos.';

  @override
  String get backupTablesDoNotMatch =>
      'Las tablas de la copia de seguridad no coinciden.';

  @override
  String get invalidBackupColumns =>
      'Columnas de copia de seguridad no válidas.';

  @override
  String get migratingOriginalAppBackup =>
      'Migrando la copia de seguridad de la app original';

  @override
  String get theOriginalBackupIsMissing =>
      'Faltan tablas necesarias en la copia de seguridad original.';

  @override
  String get backupFormatOrDatabaseVersion =>
      'El formato de la copia de seguridad o la versión de la base de datos no coincide.';

  @override
  String get restoringRecords => 'Restaurando registros';

  @override
  String get restoringSettings => 'Restaurando ajustes';

  @override
  String get restoreComplete => 'Restauración completada';

  @override
  String get effortMustBeANumber => 'El esfuerzo debe ser un número.';

  @override
  String get theDurationEstimateMustBe =>
      'La estimación de duración debe ser positiva.';

  @override
  String get restCannotBeNegative => 'El descanso no puede ser negativo.';

  @override
  String get enterTheRepetitionsDoneThe =>
      'Introduce las repeticiones realizadas; el plan tiene un rango.';

  @override
  String get enterTheLoadThePlan =>
      'Introduce la carga; el plan no tiene ninguna.';

  @override
  String get enterTheResistanceThePlan =>
      'Introduce la resistencia; el plan no tiene ninguna.';

  @override
  String get poorSensorContact => 'Mal contacto del sensor';

  @override
  String get moreThan25FromLocal => 'A más del 25 % de la mediana local';

  @override
  String get workoutNutrition => 'Nutrición del entrenamiento';

  @override
  String get postWorkoutFoodAndFluid =>
      'Recordatorio del registro de comida y líquidos tras el entrenamiento';

  @override
  String get postTrainingHrvMeasurementReminder =>
      'Recordatorio de medición de VFC tras el entrenamiento';

  @override
  String get rirRunsFrom0To => 'RIR va de 0 a 10+.';

  @override
  String get rpeRunsFrom1To => 'RPE va de 1 a 10.';

  @override
  String get repetitionsCannotBeNegative =>
      'Las repeticiones no pueden ser negativas.';

  @override
  String get timedWorkMustBeLonger =>
      'El trabajo cronometrado debe durar más de cero segundos.';

  @override
  String get chooseRepetitionsOrTimedWork =>
      'Elige repeticiones o trabajo cronometrado, no ambos.';

  @override
  String get loadMustBeAFinite =>
      'La carga debe ser un número finito y no negativo.';

  @override
  String get durationCannotBeNegative => 'La duración no puede ser negativa.';

  @override
  String get hrTimeline => 'Línea de tiempo de FC';

  @override
  String get dayTrainingLoad => 'Carga de entrenamiento diaria';

  @override
  String get weekdayComparison => 'Comparación por día de la semana';

  @override
  String get weeklyTrainingLoad => 'Carga de entrenamiento semanal';

  @override
  String get zonePolarization => 'Polarización de zonas';

  @override
  String get elevationOverview => 'Resumen de desnivel';

  @override
  String get trainingMonitor => 'Monitor de entrenamiento';

  @override
  String get formAtlCtlTsb => 'Forma ATL / CTL / TSB';

  @override
  String get trainingPlanProgress => 'Progreso del plan de entrenamiento';

  @override
  String get rhrSleep => 'FC en reposo (sueño)';

  @override
  String get hrvSleep => 'VFC (sueño)';

  @override
  String get spo2Sleep => 'SpO₂ (sueño)';

  @override
  String get respRate => 'Frecuencia respiratoria';

  @override
  String get stress => 'Estrés';

  @override
  String get skinTemp => 'Temperatura de la piel';

  @override
  String get steps => 'Pasos';

  @override
  String get tonightsSleep => 'Sueño de esta noche';

  @override
  String get activityLog => 'Registro de actividad';

  @override
  String get activityLog2 => 'Registro de actividad';

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
  String get heatAcclimation2 => 'ACLIMATACIÓN AL CALOR';

  @override
  String score(Object score) {
    return '$score%';
  }

  @override
  String get elevation => 'DESNIVEL';

  @override
  String get t12WeekHistory => 'HISTORIAL DE 12 SEMANAS';

  @override
  String get zonePolarization2 => 'POLARIZACIÓN DE ZONAS';

  @override
  String get t5WeekHistory => 'HISTORIAL DE 5 SEMANAS';

  @override
  String get easy => 'FÁCIL %';

  @override
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded) {
    return '$withZones de $recorded actividades con datos de zonas de FC';
  }

  @override
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples) {
    return '$fromSamples reconstruidas a partir de las muestras de FC registradas';
  }

  @override
  String get easyZ12ModerateZ3 => 'Fácil: Z1–2 · Moderado: Z3 · Duro: Z4–5';

  @override
  String get activitiesWithoutHrZoneData =>
      'Las actividades sin datos de zonas de FC se excluyen de los porcentajes.';

  @override
  String avgAverageUnit(Object average, Object unit) {
    return 'PROM $average $unit';
  }

  @override
  String get weekdayComparison2 => 'COMPARACIÓN POR DÍA DE LA SEMANA';

  @override
  String get trainingPlanProgress2 => 'PROGRESO DEL PLAN DE ENTRENAMIENTO';

  @override
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  ) {
    return 'Semana $currentWeek / $durationInWeeks';
  }

  @override
  String get t30MinTimeTrialLt2 => 'CONTRARRELOJ DE 30 MIN – LT2';

  @override
  String get run30MinutesAtThe =>
      'Corre 30 minutos al máximo esfuerzo que puedas sostener: controlado, sin esprintar. Entra progresivamente en el esfuerzo; no salgas demasiado rápido. El ritmo y la FC medios de los últimos 20 minutos son tu LT2.';

  @override
  String get recordAsANormalOutdoor =>
      'Regístralo como una carrera normal al aire libre. Inicia tu reloj, anota la hora y corre 30 min a ritmo de competición.';

  @override
  String get t50MinTotalFlatCourse =>
      '~50 min en total · recorrido llano · no después de un entrenamiento duro';

  @override
  String get doNotStartTooFast =>
      'No salgas demasiado rápido. Busca parciales regulares.';

  @override
  String get theAppAveragesHrAnd =>
      'La app promedia la FC y el ritmo de los últimos 20 minutos de la prueba, tras el calentamiento y los primeros 10 minutos. Selecciona la actividad registrada en Calcular.';

  @override
  String get lt2Pace => 'RITMO LT2';

  @override
  String get activityRunningEnoughTimeFor =>
      'Actividad (carrera, tiempo suficiente para calentamiento + 30 min, con FC)';

  @override
  String get selectTheTtActivity => 'Selecciona la actividad de la prueba';

  @override
  String nameStartdate(Object name, Object startDate) {
    return '$name · $startDate';
  }

  @override
  String get warmUpBeforeTt => 'Calentamiento antes de la prueba';

  @override
  String roundMin(Object round) {
    return '$round min';
  }

  @override
  String get clearResults => 'Borrar resultados';

  @override
  String get heartRate2 => 'FRECUENCIA CARDÍACA';

  @override
  String get paceSecKmLowerIs => 'Ritmo (s/km – menor es más rápido)';

  @override
  String get thresholdsFitnessTests => 'Umbrales y pruebas de forma';

  @override
  String get lt1 => 'LT1';

  @override
  String get lt2 => 'LT2';

  @override
  String get voPace => 'Ritmo VO₂';

  @override
  String get ftp => 'FTP';

  @override
  String get setFtpManually => 'Definir FTP manualmente';

  @override
  String get calculateFromAnActivity => 'Calcular a partir de una actividad';

  @override
  String get setFtp => 'Definir FTP';

  @override
  String get ftpWatts => 'FTP (vatios)';

  @override
  String get ftpCyclingThresholdPower => 'FTP – POTENCIA UMBRAL EN CICLISMO';

  @override
  String get ftpHistory => 'HISTORIAL DE FTP';

  @override
  String get updateFromActivity => 'ACTUALIZAR DESDE ACTIVIDAD';

  @override
  String get tapAnActivityFtpBest =>
      'Toca una actividad – FTP = mejor potencia de 20 min × 0,95';

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
      'Ninguna salida con 20 minutos de muestras de potencia continuas.';

  @override
  String get enterFtpManually => 'Introducir FTP manualmente';

  @override
  String get selectTheTestActivity => 'Selecciona la actividad de la prueba';

  @override
  String get formAtlCtlTsb2 => 'FORMA · ATL / CTL / TSB';

  @override
  String get closeTrainingFormFullscreen =>
      'Cerrar la forma de entrenamiento a pantalla completa';

  @override
  String get expandTrainingForm => 'Ampliar la forma de entrenamiento';

  @override
  String get calculatedFromTheFirstAvailable =>
      'Calculado desde el primer registro de carga disponible. Los días sin carga registrada cuentan como cero; el entrenamiento anterior se desconoce.';

  @override
  String get trainingMonitor2 => 'MONITOR DE ENTRENAMIENTO';

  @override
  String get pfitzingerZones => 'ZONAS DE PFITZINGER';

  @override
  String get cyclingPowerZones => 'ZONAS DE POTENCIA EN CICLISMO';

  @override
  String znumber(Object number) {
    return 'Z$number';
  }

  @override
  String paceHrDescription(Object pace, Object hr, Object description) {
    return '$pace · $hr\n$description';
  }

  @override
  String get weeklyTrainingLoad2 => 'CARGA DE ENTRENAMIENTO SEMANAL';

  @override
  String get prevWeek => 'SEM. ANT.';

  @override
  String get bySport => 'POR DEPORTE';

  @override
  String get noActivitiesThisWeek => 'Sin actividades esta semana';

  @override
  String garminWorkoutScheduleddate(Object scheduledDate) {
    return 'Entrenamiento Garmin · $scheduledDate';
  }

  @override
  String get yourNote => 'Tu nota';

  @override
  String get askAiCoach => 'Preguntar al entrenador IA';

  @override
  String get aiSettings => 'Ajustes de IA';

  @override
  String get askYourCoach => 'Pregunta a tu entrenador…';

  @override
  String get sendMessage => 'Enviar mensaje';

  @override
  String get sendFeedbackOrReportA =>
      'Enviar comentarios o informar de un error';

  @override
  String get addMeasurement2 => 'Añadir medición';

  @override
  String get syncLabel2 => 'Sincronizar';

  @override
  String get syncToday => 'Sincronizar hoy';

  @override
  String get fullSync1Year => 'Sincronización completa · 1 año';

  @override
  String get fullSyncComplete => 'Sincronización completa · Completada';

  @override
  String get syncingYourData => 'Sincronizando tus datos…';

  @override
  String lLeftkgRRightkgKg2(Object leftKg, Object rightKg) {
    return 'I $leftKg  D $rightKg kg';
  }

  @override
  String weightKgFatBodyfatMuscle(
    Object weight,
    Object bodyFat,
    Object muscleMass,
  ) {
    return '$weight kg · Grasa $bodyFat % · Músculo $muscleMass kg';
  }

  @override
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase) {
    return '$title, $sport, $toLowerCase';
  }

  @override
  String get weatherUnavailableTapToRetry =>
      'Tiempo no disponible · Toca para reintentar';

  @override
  String get weatherSetYourLocation => 'Tiempo · Define tu ubicación';

  @override
  String get t7DayForecast => 'PREVISIÓN A 7 DÍAS';

  @override
  String get minMax => 'mín/máx';

  @override
  String get rainMm2 => 'lluvia mm';

  @override
  String get uvMax => 'UV máx.';

  @override
  String get kmH => 'km/h';

  @override
  String alt(Object alt) {
    return '→ $alt';
  }

  @override
  String raceGoalsLength(Object length) {
    return 'Objetivos de carrera · $length';
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
  String get weeks2 => 'semanas';

  @override
  String get upcoming => 'PRÓXIMOS';

  @override
  String lengthMoreDays(Object length) {
    return '+ $length días más';
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
      '○ Planificado   ● Completado   ✕ Omitido';

  @override
  String get heartRate3 => 'Frecuencia cardíaca';

  @override
  String get watts => 'Vatios';

  @override
  String theStepsAddUpTo(Object total, Object plannedDurationMin) {
    return 'Los pasos suman $total; el plan cuenta $plannedDurationMin min.';
  }

  @override
  String get typicalSplitForThisKind =>
      'Reparto típico para este tipo de sesión; no hay pasos para calcularlo.';

  @override
  String labelGetsEachExerciseWith(Object label) {
    return '$label recibe cada ejercicio con sus series, repeticiones y cargas. Los rangos de repeticiones, el esfuerzo y el tempo se quedan en Fjelia.';
  }

  @override
  String get markAsRest => 'Marcar como descanso';

  @override
  String get restoreWorkout => 'Restaurar entrenamiento';

  @override
  String get skipThisWorkout => '¿Omitir este entrenamiento?';

  @override
  String get previousWeek => 'Semana anterior';

  @override
  String get backToThisWeek => 'Volver a esta semana';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get nextWeek => 'Semana siguiente';

  @override
  String get today2 => 'HOY';

  @override
  String get route => 'RUTA';

  @override
  String get feedback => 'Comentarios';

  @override
  String get plannedWorkout => 'Entrenamiento planificado';

  @override
  String get delete => 'Eliminar';

  @override
  String get chatAi => 'Chat con IA';

  @override
  String get trainingLoad => 'Carga de entrenamiento';

  @override
  String get dayTrainingLoad2 => 'CARGA DE ENTRENAMIENTO DIARIA';

  @override
  String get trimp => ' TRIMP';

  @override
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter) {
    return '$scoreBefore → $scoreAfter';
  }

  @override
  String get temperatureOverTime => 'TEMPERATURA A LO LARGO DEL TIEMPO';

  @override
  String roundh(Object round) {
    return '${round}h';
  }

  @override
  String get timeInHrZones => 'Tiempo en zonas de FC';

  @override
  String get route2 => 'Ruta';

  @override
  String get start => 'Salida';

  @override
  String get gpx => 'GPX';

  @override
  String touppercasesubstringBriefing(Object toUpperCase, Object substring) {
    return 'Resumen de $toUpperCase$substring';
  }

  @override
  String get chatWithAiAboutThis => 'Chatear con la IA sobre este resumen';

  @override
  String get whyThisRecommendation => '¿Por qué esta recomendación?';

  @override
  String titleDateLabel(Object title, Object date, Object label) {
    return '$title, $date, $label';
  }

  @override
  String get previousDay => 'Día anterior';

  @override
  String get nextDay => 'Día siguiente';

  @override
  String get updating => 'Actualizando';

  @override
  String get resting => 'EN REPOSO';

  @override
  String get noTimedReadings => 'Sin lecturas con hora';

  @override
  String get avg => 'PROM';

  @override
  String get peak => 'PICO';

  @override
  String tolocalRoundmin(Object toLocal, Object round) {
    return '$toLocal · ${round}min';
  }

  @override
  String avgheartrateBpmAvg(Object avgHeartRate) {
    return '$avgHeartRate bpm prom.';
  }

  @override
  String get timeWeightedAverageOverRecorded =>
      'Promedio ponderado por tiempo de los periodos registrados. Los huecos sin lecturas se excluyen.';

  @override
  String get previousHeartRatePeriod =>
      'Periodo de frecuencia cardíaca anterior';

  @override
  String get nextHeartRatePeriod => 'Periodo de frecuencia cardíaca siguiente';

  @override
  String get avgHr => 'FC prom.';

  @override
  String get restingHr => 'FC en reposo';

  @override
  String get both => 'Ambos';

  @override
  String averagelabelFixedMs(Object averageLabel, Object fixed) {
    return '$averageLabel $fixed ms';
  }

  @override
  String get measureWithPolarH10 => 'Medir con Polar H10';

  @override
  String get ms => 'ms';

  @override
  String get noWorkoutInThisPeriod =>
      'Ningún entrenamiento de este periodo tiene un par antes/después comparable.';

  @override
  String textEachWorkoutCountsOnce(Object text) {
    return '$text. Cada entrenamiento cuenta una vez; esto describe tus pares, no los puntúa.';
  }

  @override
  String get workoutFinished => '¿Entrenamiento terminado?';

  @override
  String get yourWorkoutIsNotIn =>
      'Tu entrenamiento aún no está en Fjelia. Si terminó, indica cuándo y el recordatorio podrá seguir su final real. Si no, aparecerá cuando tu reloj se sincronice.';

  @override
  String get workoutFinished2 => 'Entrenamiento terminado';

  @override
  String get theWorkoutMustStartAfter =>
      'El entrenamiento debe empezar después de la medición y terminar después de su inicio, no en el futuro.';

  @override
  String daysDAvg(Object days) {
    return '$days D prom.';
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
  String get previousPeriod => 'Periodo anterior';

  @override
  String get nextPeriod => 'Periodo siguiente';

  @override
  String get overnightHrvReflectsRecoveryCompare =>
      'La VFC nocturna refleja la recuperación. Compara tus lecturas con tu propia línea base a lo largo del tiempo.';

  @override
  String get moveThisWorkout => 'MOVER ESTE ENTRENAMIENTO';

  @override
  String get pickDate => 'Elegir fecha';

  @override
  String movedFromMovedfrom(Object movedFrom) {
    return 'Movido desde $movedFrom';
  }

  @override
  String get hrvAroundThisWorkout => 'VFC en torno a este entrenamiento';

  @override
  String get measureAfterTraining => 'Medir después del entrenamiento';

  @override
  String get measureAgain => 'Medir de nuevo';

  @override
  String get explainWithAi => 'Explicar con IA';

  @override
  String beforeEndedPregapAheadOf(Object preGap) {
    return 'Antes terminó $preGap antes del inicio.';
  }

  @override
  String lengthFurtherMeasurementSAfter(Object length) {
    return '$length medición(es) adicional(es) tras este entrenamiento se conservan como observaciones extra.';
  }

  @override
  String get noHrvMeasurementRecordedAround =>
      'Sin medición de VFC registrada en torno a este entrenamiento.';

  @override
  String get measureHrv => 'Medir VFC';

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
      'Una descripción de este par, no una puntuación del entrenamiento.';

  @override
  String notEnoughComparableWorkoutsYet(Object eligible, Object need) {
    return 'Aún no hay suficientes entrenamientos comparables, $eligible de $need.';
  }

  @override
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need) {
    return 'Aún no hay suficientes entrenamientos comparables ($eligible de $need).';
  }

  @override
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  ) {
    return 'Tus $eligible entrenamientos similares · $toLocal–$toLocal2';
  }

  @override
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  ) {
    return 'Mitad central de $q1Ms a $q3Ms ms · mediana $medianMs ms · este entrenamiento $delta ms';
  }

  @override
  String rpeI(Object i) {
    return 'RPE $i';
  }

  @override
  String get easy2 => 'fácil';

  @override
  String get allOut => 'A tope';

  @override
  String workoutProfileDescription(Object description) {
    return 'Perfil del entrenamiento: $description';
  }

  @override
  String get noActivitiesInThisPeriod => 'Sin actividades en este periodo';

  @override
  String get enableHeatAcclimationInTraining =>
      'Activa la aclimatación al calor en los ajustes de entrenamiento.';

  @override
  String get noElevationThisWeek => 'Sin desnivel esta semana';

  @override
  String get noActivitiesSynced => 'Sin actividades sincronizadas';

  @override
  String get noHrZoneData => 'Sin datos de zonas de FC';

  @override
  String get easyJogGetHrElevated => 'Trote suave: sube la FC, piernas sueltas';

  @override
  String get fastestSustainablePaceLikeA =>
      'Ritmo sostenible más rápido: como una carrera de 30 min';

  @override
  String get walkCardiacRecovery => 'Caminar: recuperación cardíaca';

  @override
  String get selectTheTtActivityFirst =>
      'Selecciona primero la actividad de la prueba.';

  @override
  String get calculating => 'Calculando…';

  @override
  String get calculateLt2 => 'Calcular LT2';

  @override
  String get enterFtpBetween30And => 'Introduce una FTP entre 30 y 1000 W.';

  @override
  String get aerobicThreshold => 'Umbral aeróbico';

  @override
  String get functionalThresholdPower => 'Potencia umbral funcional';

  @override
  String get estimated => 'Estimado';

  @override
  String get afterWarmingUpRunFive =>
      'Tras calentar, corre cinco minutos a tu máximo esfuerzo sostenible. Registra la carrera con datos de velocidad o distancia.';

  @override
  String get recordAtLeast40Minutes =>
      'Registra al menos 40 minutos de carrera constante a esfuerzo constante. La prueba compara la frecuencia cardíaca en cada mitad para estimar la deriva aeróbica.';

  @override
  String get theFastestFiveMinuteWindow =>
      'La ventana de cinco minutos más rápida da tu ritmo de VO2max.';

  @override
  String get noResultYet => 'Aún sin resultado';

  @override
  String get calculateVo2maxPace => 'Calcular ritmo de VO2max';

  @override
  String get calculateLt1 => 'Calcular LT1';

  @override
  String get loading2 => 'Cargando';

  @override
  String get unavailable => 'No disponible';

  @override
  String get noTrainingHistory => 'Sin historial de entrenamiento';

  @override
  String get fitnessCtl => 'Forma física (CTL)';

  @override
  String get fatigueAtl => 'Fatiga (ATL)';

  @override
  String get formTsb => 'Frescura (TSB)';

  @override
  String get noHistory => 'Sin historial';

  @override
  String get fresh => 'Fresco';

  @override
  String get optimal => 'Óptimo';

  @override
  String get neutral => 'Neutral';

  @override
  String get tired => 'Cansado';

  @override
  String get veryFatigued => 'Muy fatigado';

  @override
  String get garminRunningVo2max => 'VO2max carrera Garmin';

  @override
  String get garminCyclingVo2max => 'VO2max ciclismo Garmin';

  @override
  String get aerobicThreshold2 => 'Umbral aeróbico';

  @override
  String driftDriftAt(Object drift, Object at) {
    return 'Deriva $drift % · $at';
  }

  @override
  String get activityHours => 'Horas de actividad';

  @override
  String get activityKm => 'Km de actividad';

  @override
  String get tap5MinuteMaxTest => 'Toca · prueba máxima de 5 min';

  @override
  String get setFtpToCalculatePower =>
      'Define la FTP para calcular las zonas de potencia';

  @override
  String get cyclingPowerZones2 => 'Zonas de potencia en ciclismo';

  @override
  String get pfitzingerZones2 => 'Zonas de Pfitzinger';

  @override
  String get completeAnLt2TestTo =>
      'Completa una prueba de LT2 para calcular las zonas de carrera.';

  @override
  String get setFtpToCalculatePower2 =>
      'Define la FTP para calcular las zonas de potencia.';

  @override
  String get endurance => 'Resistencia';

  @override
  String get threshold => 'Umbral';

  @override
  String get anaerobic => 'Anaeróbico';

  @override
  String get whatExplainsThisRise => '¿Qué explica este aumento?';

  @override
  String get whatExplainsThisDrop => 'Qué explica esta bajada';

  @override
  String get whatExplainsThisRise2 => 'Qué explica este aumento';

  @override
  String get editsAreKeptInFjelia =>
      'Los cambios se guardan en Fjelia como copia local para esta fecha. El entrenamiento en Garmin no cambia.';

  @override
  String get howDoIExecuteThis => '¿Cómo ejecuto este entrenamiento?';

  @override
  String shareHealthContextWithName(Object name) {
    return '¿Compartir el contexto de salud con $name?';
  }

  @override
  String get yourMessageAndAHealth =>
      'Tu mensaje y un resumen de salud/entrenamiento se enviarán a este proveedor de IA en la nube. Los nombres y el GPS se excluyen del resumen generado.';

  @override
  String get couldNotGetAReply =>
      'No se pudo obtener una respuesta. Revisa tus ajustes de IA e inténtalo de nuevo.';

  @override
  String get askAboutYourRecoveryTraining =>
      'Pregunta sobre tu recuperación, tu entrenamiento o el plan de hoy.';

  @override
  String get noSyncYet => 'Aún sin sincronizar';

  @override
  String lastSyncLastContext(Object last, Object context) {
    return 'Última sincronización: $last $context';
  }

  @override
  String get seasonWithTradeOffs => 'Temporada: con concesiones';

  @override
  String get seasonNeedsYourDecision => 'Temporada: necesita tu decisión';

  @override
  String get seasonCannotBeCombined => 'Temporada: no se puede combinar';

  @override
  String get seasonProvisional => 'Temporada: provisional';

  @override
  String get season => 'Temporada';

  @override
  String get allGoalsFit => 'Todos los objetivos encajan.';

  @override
  String goalTargetfinishsecondsgoal(Object targetFinishSeconds, Object goal) {
    return 'Objetivo $targetFinishSeconds$goal';
  }

  @override
  String estEstimateestimate2(Object estimate, Object estimate2) {
    return 'Est. $estimate$estimate2';
  }

  @override
  String doneDoneby(Object doneBy) {
    return 'Hecho · $doneBy';
  }

  @override
  String garminWorkoutWorkout(Object workout) {
    return 'Entrenamiento Garmin · $workout';
  }

  @override
  String get moveAnyway => '¿Mover de todos modos?';

  @override
  String get wattsNeedYourFtpSet =>
      'Los vatios necesitan tu FTP: defínela en Carga, Umbrales.';

  @override
  String get mainTargetInWattsFrom =>
      'Objetivo principal en vatios según tu FTP, la frecuencia cardíaca como guía.';

  @override
  String get mainTargetHeartRateWatts =>
      'Objetivo principal: frecuencia cardíaca; los vatios no están definidos en el reloj.';

  @override
  String get taperPhase => 'Fase de puesta a punto';

  @override
  String get recoverySession => 'Sesión de recuperación';

  @override
  String get closeToYourEvent => 'Cerca de tu evento';

  @override
  String get noWorkoutStructureAvailable =>
      'No hay estructura de entrenamiento disponible.';

  @override
  String get aerobic => 'Aeróbico';

  @override
  String get pushAgainToUpdateYour =>
      'Envía de nuevo para actualizar el calendario de tu reloj.';

  @override
  String workoutSentToLabel(Object label) {
    return 'Entrenamiento enviado a $label';
  }

  @override
  String get updating2 => 'Actualizando…';

  @override
  String pushToLabel(Object label) {
    return 'Enviar a $label';
  }

  @override
  String shareExerciseListForLabel(Object label) {
    return 'Compartir lista de ejercicios para $label';
  }

  @override
  String shareWorkoutForLabel(Object label) {
    return 'Compartir entrenamiento para $label';
  }

  @override
  String get whyNothingIsAddedTo =>
      '¿Por qué? No se añade nada para completarlo.';

  @override
  String get workout => 'Entrenamiento';

  @override
  String get recordedActivityLinkedToThis =>
      'Actividad registrada vinculada a este entrenamiento';

  @override
  String get matchedToTheRecordedWorkout =>
      'Emparejado con el inicio del entrenamiento registrado';

  @override
  String get matchedByWorkoutNameSport =>
      'Emparejado por nombre del entrenamiento, deporte y fecha';

  @override
  String get matchedBySportDateAnd =>
      'Emparejado por deporte, fecha y duración';

  @override
  String planPlannedminutesMin(Object plannedMinutes) {
    return 'Plan $plannedMinutes min';
  }

  @override
  String get maxHr => 'FC máx.';

  @override
  String get trainingLoad2 => 'Carga de entrenamiento';

  @override
  String get active => 'Activo';

  @override
  String get avgPace => 'Ritmo medio';

  @override
  String get avgSpeed => 'Velocidad media';

  @override
  String get avgPower => 'Potencia media';

  @override
  String get elevation2 => 'Desnivel';

  @override
  String get altitude => 'Altitud';

  @override
  String get explainMyHrvBeforeAnd =>
      'Explica mi VFC antes y después de este entrenamiento. ¿Qué es comparable, qué no y qué sigue siendo desconocido?';

  @override
  String get deleteActivity => '¿Eliminar la actividad?';

  @override
  String get removeThisActivityFromThe =>
      '¿Quitar esta actividad del historial local? Una sincronización posterior del proveedor puede importarla de nuevo.';

  @override
  String get howDidThisSessionGo =>
      '¿Cómo fue esta sesión y qué significa para mis próximos días?';

  @override
  String currentFixedFixed2(Object fixed, Object fixed2) {
    return 'Actual $fixed, $fixed2';
  }

  @override
  String get setUpInTrainingSettings =>
      'Configúralo en los ajustes de entrenamiento';

  @override
  String get couldNotLoadHeatData =>
      'No se pudieron cargar los datos de calor – toca para ver detalles';

  @override
  String get loadingHeatHistory => 'Cargando historial de calor…';

  @override
  String get noHeatDataYet => 'Aún sin datos de calor';

  @override
  String optimalLowHigh(Object low, Object high) {
    return 'Óptimo $low–$high';
  }

  @override
  String optimalLowHighTrimp(Object low, Object high) {
    return 'Óptimo: $low–$high TRIMP';
  }

  @override
  String get targetUnavailableSyncTrainingHistory =>
      'Objetivo no disponible: sincroniza el historial de entrenamiento';

  @override
  String get workoutQualifiedForHeatAccumulation =>
      'El entrenamiento contó para la acumulación de calor.';

  @override
  String get workoutDidNotAddHeat =>
      'El entrenamiento no añadió acumulación de calor.';

  @override
  String get performanceTime => 'Rendimiento / Tiempo';

  @override
  String get performanceDistance => 'Rendimiento / Distancia';

  @override
  String get noRecordedRoute => 'Sin ruta registrada';

  @override
  String get zoomIn => 'Acercar';

  @override
  String get zoomOut => 'Alejar';

  @override
  String get fitRoute => 'Ajustar la ruta';

  @override
  String get fullscreenMap => 'Mapa a pantalla completa';

  @override
  String get openstreetmapContributors2 => 'colaboradores de OpenStreetMap';

  @override
  String get appleIntelligenceIsUnavailableShowing =>
      'Apple Intelligence no está disponible. Se muestra un resumen sin IA.';

  @override
  String get generateAiBriefing => '¿Generar el resumen con IA?';

  @override
  String get retryAiBriefing => 'Reintentar resumen con IA';

  @override
  String get generateBriefing => 'Generar resumen';

  @override
  String discussThisBriefingWithMe(Object text) {
    return 'Comenta este resumen conmigo y sugiere la mejor siguiente acción.\n\n$text';
  }

  @override
  String whyThisRecommendationWhichOf(Object text) {
    return '¿Por qué esta recomendación? ¿Qué cifras mías y qué lagunas en los datos la motivaron y qué la cambiaría?\n\n$text';
  }

  @override
  String get avg2 => 'Prom.';

  @override
  String get peak2 => 'Pico';

  @override
  String get notEnoughContinuousReadingsFor =>
      'No hay suficientes lecturas continuas para un promedio.';

  @override
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  ) {
    return 'Cobertura registrada: $inHours h $inMinutes min · promedio ponderado por tiempo';
  }

  @override
  String get lying => 'Tumbado';

  @override
  String get noHrvReadingsInThis => 'Sin lecturas de VFC en este periodo';

  @override
  String get overnightHrvComesFromYour =>
      'La VFC nocturna viene de tu reloj y las lecturas puntuales del Polar H10 (RMSSD). Los métodos difieren: compara tendencias, no valores aislados.';

  @override
  String get noReadings => 'Sin lecturas';

  @override
  String get whenDidTheWorkoutStart => '¿Cuándo empezó el entrenamiento?';

  @override
  String get whenDidItEnd => '¿Cuándo terminó?';

  @override
  String get last3Months => 'Últimos 3 meses';

  @override
  String get lastYear => 'Último año';

  @override
  String lastDaysDays(Object days) {
    return 'Últimos $days días';
  }

  @override
  String nowOnCurrentTapA(Object current) {
    return 'Ahora el $current. Toca un día o arrastra el entrenamiento a uno. Los pasos se mantienen.';
  }

  @override
  String get monthView => 'Vista mensual';

  @override
  String get syncing => 'Sincronizando';

  @override
  String get trendUnavailable => 'Tendencia no disponible';

  @override
  String get stable => 'Estable';

  @override
  String get increasing => 'En aumento';

  @override
  String get decreasing => 'En descenso';

  @override
  String get unclear => 'Poco claro';

  @override
  String get notComparable => 'No comparable';

  @override
  String get waitingForAfter => 'Esperando el después';

  @override
  String get afterOnly => 'Solo después';

  @override
  String get waitingForTheActualWorkout =>
      'Esperando el final real del entrenamiento.';

  @override
  String reminderAroundTolocal(Object toLocal) {
    return 'Recordatorio hacia las $toLocal';
  }

  @override
  String get reminderIsDueMeasureWhen =>
      'El recordatorio ha llegado. Mide cuando estés listo.';

  @override
  String get thisReminderIsNoLonger =>
      'Este recordatorio ya no está vigente. Abre el entrenamiento para ver tus mediciones.';

  @override
  String beforeFixedMilliseconds(Object fixed) {
    return 'Antes $fixed milisegundos. ';
  }

  @override
  String afterFixedMilliseconds(Object fixed) {
    return 'Después $fixed milisegundos';
  }

  @override
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  ) {
    return 'Cambio de $deltaMs milisegundos, $deltaPercent por ciento.';
  }

  @override
  String get noPreTrainingMeasurementRecorded =>
      'Sin medición previa al entrenamiento registrada.';

  @override
  String get notMeasuredYet => 'Aún sin medir';

  @override
  String leftOutOfTheComparison(Object excludedTotal, Object c) {
    return 'Excluidos de la comparación: $excludedTotal entrenamientos ($c).';
  }

  @override
  String get notFromThisWorkout => 'No de este entrenamiento';

  @override
  String get useAsBefore => 'Usar como antes';

  @override
  String get useAsAfter => 'Usar como después';

  @override
  String get beforeNotMeasured => 'Antes · sin medir';

  @override
  String beforeTolocal(Object toLocal) {
    return 'Antes · $toLocal';
  }

  @override
  String workoutWorkouttext(Object workoutText) {
    return 'Entrenamiento · $workoutText';
  }

  @override
  String get afterNotMeasuredYet => 'Después · aún sin medir';

  @override
  String afterTolocal(Object toLocal) {
    return 'Después · $toLocal';
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
    return 'Tus entrenamientos similares ($eligible, $toLocal–$toLocal2): mediana $medianMs ms, mitad central de $q1Ms a $q3Ms ms.';
  }

  @override
  String get howHardDidItFeel => '¿Cómo de duro fue? (RPE)';

  @override
  String get loadMetric => 'Carga';

  @override
  String get clearAction => 'Borrar';

  @override
  String get routeFinish => 'Meta';

  @override
  String get month2 => 'MES';

  @override
  String get week2 => 'SEMANA';

  @override
  String get quarter => 'TRIMESTRE';

  @override
  String get year => 'AÑO';

  @override
  String get easy3 => 'FÁCIL';

  @override
  String get mod => 'MOD.';

  @override
  String get hard => 'DURO';

  @override
  String get protocol => 'PROTOCOLO';

  @override
  String get calculate => 'CALCULAR';

  @override
  String get warmUp => 'CALENTAMIENTO';

  @override
  String get coolDown => 'VUELTA A LA CALMA';

  @override
  String get ftpCycling => 'FTP ciclismo';

  @override
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg) {
    return 'FTP $ftpWatts W · $wattsPerKg W/kg';
  }

  @override
  String get thisWeekSoFar => 'ESTA SEMANA · HASTA AHORA';

  @override
  String get duration2 => 'DURACIÓN';

  @override
  String get distance2 => 'DISTANCIA';

  @override
  String get sport2 => 'DEPORTE';

  @override
  String get repeatSets => 'SERIES REPETIDAS';

  @override
  String get aboutThisWorkout => 'ACERCA DE ESTE ENTRENAMIENTO';

  @override
  String get workoutStructure => 'ESTRUCTURA DEL ENTRENAMIENTO';

  @override
  String get health2 => 'SALUD';

  @override
  String get high2 => 'ALTO';

  @override
  String get elevated => 'ELEVADO';

  @override
  String get normal => 'NORMAL';

  @override
  String get tomorrow => 'MAÑANA';

  @override
  String get skipped2 => 'OMITIDO';

  @override
  String get weeklyPlan => 'PLAN SEMANAL';

  @override
  String get activityLog3 => 'REGISTRO DE ACTIVIDAD';

  @override
  String skippedTouppercase(Object toUpperCase) {
    return 'OMITIDO · $toUpperCase';
  }

  @override
  String get primaryZone => 'ZONA PRINCIPAL';

  @override
  String get coachingCues => 'CONSEJOS DEL ENTRENADOR';

  @override
  String get targets => 'OBJETIVOS';

  @override
  String get adaptation => 'ADAPTACIÓN';

  @override
  String get done2 => 'HECHO';

  @override
  String get notRecorded2 => 'NO REGISTRADO';

  @override
  String get planned => 'PLANIFICADO';

  @override
  String get extra => 'EXTRA';

  @override
  String get optimal2 => 'ÓPTIMO';

  @override
  String get qualified => 'CALIFICADO';

  @override
  String get temp => 'TEMP.';

  @override
  String get humidity2 => 'HUMEDAD';

  @override
  String get pressure => 'PRESIÓN';

  @override
  String get wetBulb => 'BULBO HÚMEDO';

  @override
  String get paceMinKm => 'Ritmo (min/km)';

  @override
  String get speedKmH => 'Velocidad (km/h)';

  @override
  String get elevationM => 'Desnivel (m)';

  @override
  String get powerW => 'POTENCIA (W)';

  @override
  String get performanceTime2 => 'RENDIMIENTO / TIEMPO';

  @override
  String get performanceDistance2 => 'RENDIMIENTO / DISTANCIA';

  @override
  String get load2 => 'CARGA';

  @override
  String get day2 => 'DÍA';

  @override
  String get allTime => 'TODO EL TIEMPO';

  @override
  String get hrvAroundThisWorkout2 => 'VFC en torno a este entrenamiento. ';

  @override
  String get lowReserve => 'RESERVA BAJA';

  @override
  String get goodReserve => 'BUENA RESERVA';

  @override
  String latestReadingAtTolocal(Object toLocal) {
    return 'Última lectura a las $toLocal';
  }

  @override
  String get weeklyAvg => 'PROM. SEMANAL';

  @override
  String get monthlyAvg => 'PROM. MENSUAL';

  @override
  String get systolic2 => 'SISTÓLICA';

  @override
  String get diastolic2 => 'DIASTÓLICA';

  @override
  String get hourlyVariation => 'VARIACIÓN HORARIA';

  @override
  String get dailyVariation => 'VARIACIÓN DIARIA';

  @override
  String get sys2 => 'SIS';

  @override
  String get dia => 'DIA';

  @override
  String get bluetoothDevices => 'DISPOSITIVOS BLUETOOTH';

  @override
  String get accountsServices => 'CUENTAS Y SERVICIOS';

  @override
  String get flowLoginOptional => 'INICIO DE SESIÓN DE FLOW (OPCIONAL)';

  @override
  String get polarFlowLogin => 'INICIO DE SESIÓN DE POLAR FLOW';

  @override
  String get raceGoal => 'OBJETIVO DE CARRERA';

  @override
  String get experienceLevel => 'NIVEL DE EXPERIENCIA';

  @override
  String get weeklySchedule2 => 'HORARIO SEMANAL';

  @override
  String get sessionsPerDay2 => 'SESIONES POR DÍA';

  @override
  String get aboutYou => 'SOBRE TI';

  @override
  String get yourActivities2 => 'TUS ACTIVIDADES';

  @override
  String latestReadingAtTimestamp(Object timestamp) {
    return 'Última lectura a las $timestamp';
  }

  @override
  String get poorSleep => 'SUEÑO DEFICIENTE';

  @override
  String get fairSleep => 'SUEÑO REGULAR';

  @override
  String get goodSleep => 'BUEN SUEÑO';

  @override
  String get hoursOfSleep => 'HORAS DE SUEÑO';

  @override
  String get sleepNeeded => 'SUEÑO NECESARIO';

  @override
  String get deepSleep => 'SUEÑO PROFUNDO';

  @override
  String get exercises2 => 'EJERCICIOS';

  @override
  String get strengthSummary => 'RESUMEN DE FUERZA';

  @override
  String get strengthDraft => 'FUERZA · BORRADOR';

  @override
  String get strengthFinishedWithGaps => 'FUERZA · TERMINADO CON HUECOS';

  @override
  String get strength2 => 'FUERZA';

  @override
  String get wind => 'VIENTO';

  @override
  String get sun2 => 'SOL';

  @override
  String get cloud => 'NUBES';

  @override
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt) {
    return 'Datos: $source · Actualizado $fetchedAt';
  }

  @override
  String get coros2 => 'COROS';

  @override
  String get rmssdMs => 'RMSSD · ms';

  @override
  String get sdnnMs => 'SDNN · ms';

  @override
  String get now2 => 'AHORA';

  @override
  String get awake => 'DESPIERTO';

  @override
  String get light => 'LIGERO';

  @override
  String get deep2 => 'PROFUNDO';

  @override
  String get sqliteOrm => 'SQLite ORM';

  @override
  String get httpClients => 'Clientes HTTP';

  @override
  String get gpsLocation => 'Ubicación GPS';

  @override
  String get hdlCholesterol => 'Colesterol HDL';

  @override
  String get ldlCholesterol => 'Colesterol LDL';

  @override
  String get raceName => 'NOMBRE DE LA CARRERA';

  @override
  String get mtb => 'MTB';

  @override
  String get distanceKm => 'Distancia (km)';

  @override
  String get priority => 'PRIORIDAD';

  @override
  String get elevationGainM => 'Desnivel positivo (m)';

  @override
  String get targetTime => 'TIEMPO OBJETIVO';

  @override
  String get raceDate => 'FECHA DE LA CARRERA';

  @override
  String get participation => 'PARTICIPACIÓN';

  @override
  String get whatIWantFromIt => 'LO QUE QUIERO CONSEGUIR';

  @override
  String periodTimeline(Object period) {
    return '$period · EVOLUCIÓN';
  }

  @override
  String get tabPlan => 'PLAN';

  @override
  String get tabLoad => 'CARGA';

  @override
  String get tabCoach => 'ENTRENADOR';

  @override
  String get hrDriftTestLt1 => 'PRUEBA DE DERIVA DE FC – LT1';

  @override
  String get asSentByGarmin => 'TAL COMO LO ENVIÓ GARMIN';

  @override
  String get noData2 => 'SIN DATOS';

  @override
  String get noTarget => 'SIN OBJETIVO';

  @override
  String get noHeatLoad => 'SIN CARGA DE CALOR';

  @override
  String get hrBpm => 'FC (ppm)';

  @override
  String get aiBriefingUnavailableShowingA =>
      'Resumen con IA no disponible. Se muestra un resumen sin IA.';

  @override
  String get uvIndex2 => 'ÍNDICE UV';

  @override
  String get aiBriefing => 'Resumen con IA';

  @override
  String get uiFrameworkByGoogle => 'Framework de interfaz de Google';

  @override
  String get unableToLoadData => 'No se pudieron cargar los datos';

  @override
  String briefingSummary(Object recovery, Object sleep, Object load) {
    return 'Recuperación $recovery / 100. Sueño $sleep / 100. La carga de entrenamiento de hoy es de $load TRIMP.';
  }

  @override
  String get morningBriefing => 'Resumen de la mañana';

  @override
  String get lunchBriefing => 'Resumen del mediodía';

  @override
  String get afternoonBriefing => 'Resumen de la tarde';

  @override
  String get eveningBriefing => 'Resumen de la noche';

  @override
  String get appleUnusableAnswer =>
      'Apple Intelligence no pudo dar una respuesta utilizable: se repitió o repitió tus datos. Reformula la pregunta o elige otro proveedor de IA en los ajustes.';

  @override
  String get appleCouldNotAnswer =>
      'Apple Intelligence no pudo responder. Inténtalo de nuevo.';

  @override
  String get appleNotAvailableOnDevice =>
      'Apple Intelligence no está disponible en este dispositivo.';

  @override
  String get appleLanguageRejected =>
      'Apple Intelligence rechazó el idioma de la solicitud. Prueba con una pregunta corta en inglés. Revisa también los ajustes de idioma del iPhone y de Siri.';

  @override
  String get appleRequestTooLarge =>
      'Apple Intelligence no pudo procesar esta solicitud. Prueba con una pregunta más corta.';

  @override
  String get messageTooLongForApple =>
      'Este mensaje es demasiado largo para Apple Intelligence. Acórtalo y envíalo de nuevo.';

  @override
  String get vo2maxRunning => 'VO₂max carrera';

  @override
  String get vo2maxCycling => 'VO₂max ciclismo';

  @override
  String get vo2maxPaceLabel => 'Ritmo VO₂max';

  @override
  String get lt1Threshold => 'Umbral LT1';

  @override
  String get lt2Threshold => 'Umbral LT2';

  @override
  String hoursPreviousWeek(Object value) {
    return '$value h la semana anterior';
  }

  @override
  String kmPreviousWeek(Object value) {
    return '$value km la semana anterior';
  }

  @override
  String get thirtyMinuteTimeTrial => 'Contrarreloj de 30 minutos';

  @override
  String thirtyMinTtDate(Object date) {
    return 'TT 30 min · $date';
  }

  @override
  String get yesterday2 => 'AYER';

  @override
  String get briefHeadGreen => 'Estás bien recuperado.';

  @override
  String get briefHeadYellow => 'Llevas algo de carga encima.';

  @override
  String get briefHeadRed => 'Estás claramente sobrecargado.';

  @override
  String briefMain(Object reasons) {
    return 'Motivos principales: $reasons.';
  }

  @override
  String get briefAllClear =>
      'Ninguno de tus valores muestra señales de alerta.';

  @override
  String get briefAdviceGreen => 'Entrena como estaba previsto.';

  @override
  String get briefAdviceYellow => 'Mantén tu plan pero sin añadir intensidad.';

  @override
  String get briefAdviceRed => 'Primero la recuperación: día suave o descanso.';

  @override
  String get briefReasonHrvLow => 'VFC del sueño baja';

  @override
  String get briefReasonHrvHigh => 'VFC del sueño alta';

  @override
  String get briefReasonRhrUp => 'FC en reposo elevada';

  @override
  String get briefReasonRhrDown => 'FC en reposo baja';

  @override
  String get briefReasonSleepShort => 'poco sueño';

  @override
  String get briefReasonSleepGood => 'necesidad de sueño cubierta';

  @override
  String get briefReasonEnergyLow => 'poca energía';

  @override
  String get briefReasonEnergyHigh => 'buena energía';

  @override
  String get briefReasonStressHigh => 'estrés alto';

  @override
  String get briefReasonRespHigh => 'frecuencia respiratoria elevada';

  @override
  String get briefReasonSpo2Low => 'oxígeno en sangre bajo';

  @override
  String get briefReasonSkinTempOff => 'temperatura de la piel inusual';

  @override
  String get briefReasonFormTired => 'fatiga de entrenamiento acumulada';

  @override
  String get briefReasonFormVeryTired => 'fatiga de entrenamiento muy alta';

  @override
  String get briefReasonFormFresh => 'fresco y descansado';

  @override
  String get briefTrainingHrvUp =>
      'Tu VFC subió tras el entrenamiento, buena señal.';

  @override
  String get briefTrainingHrvDown =>
      'Tu VFC bajó tras el entrenamiento, señal menos buena.';
}
