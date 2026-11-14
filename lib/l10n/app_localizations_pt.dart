// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get freeAi => 'Free AI';

  @override
  String get freeAiUsageTracking =>
      'Para manter o Free AI disponível de forma fiável para todos, enviamos um ID de instalação aleatório. Ajuda-nos a identificar utilização invulgar e a bloquear pedidos abusivos. O ID não contém o teu nome nem dados da conta.';

  @override
  String freeAiDescription(String host) {
    return 'O Free AI oferece chat na nuvem e resumos gratuitos através de $host. Não precisas de conta própria nem de chave de API. As mensagens e um resumo da tua saúde e treino são enviados para este serviço depois da tua confirmação.';
  }

  @override
  String get freeAiUnavailable =>
      'O Free AI não está disponível nesta versão. Escolhe outro fornecedor.';

  @override
  String shareBriefingContextWithName(String name) {
    return 'Será enviado a $name um resumo dos teus dados de saúde e treino. Esta autorização única cobre também os fornecedores de IA na nuvem que escolheres no futuro para os resumos.';
  }

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predefinição do sistema';

  @override
  String get settings => 'Definições';

  @override
  String get profile => 'Perfil';

  @override
  String get training => 'Treino';

  @override
  String get weatherLocation => 'Meteorologia e localização';

  @override
  String get display => 'Ecrã';

  @override
  String get connections => 'Ligações';

  @override
  String get aiAndMore => 'IA e mais';

  @override
  String get system => 'Sistema';

  @override
  String get runSetupAgain => 'Repetir a configuração';

  @override
  String get runSetupAgainSubtitle =>
      'Contas, objetivo de prova e plano de treino';

  @override
  String get back => 'Voltar';

  @override
  String get close => 'Fechar';

  @override
  String get dataExport => 'Exportação de dados';

  @override
  String get dataExportSubtitle =>
      'Exportação CSV, cópia de segurança e restauro';

  @override
  String get developer => 'Programador';

  @override
  String get developerSubtitle => 'Modo de depuração, diagnóstico';

  @override
  String get debug => 'Depuração';

  @override
  String get debugMode => 'Modo de depuração';

  @override
  String get debugModeSubtitle => 'Mostra o separador DEBUG';

  @override
  String get support => 'Suporte';

  @override
  String get reportBug => 'Comunicar um erro';

  @override
  String get aiCoach => 'Treinador IA';

  @override
  String get enableAiCoach => 'Ativar treinador IA';

  @override
  String get onDeviceAiOrCloud => 'IA no dispositivo ou fornecedor na nuvem';

  @override
  String get provider => 'Fornecedor';

  @override
  String get model => 'Modelo';

  @override
  String get chatAndAiBriefingsUse =>
      'O chat e os resumos de IA usam o Apple Intelligence neste dispositivo. Não é necessária chave de API. Se o modelo não estiver disponível, os resumos mostram uma síntese sem IA.';

  @override
  String get briefing => 'Resumo';

  @override
  String get useAppleIntelligenceForBriefings =>
      'Usar o Apple Intelligence nos resumos';

  @override
  String get useOnDeviceAiFor =>
      'Usar IA no dispositivo para os resumos e manter o fornecedor escolhido para o chat.';

  @override
  String get healthDataSharing => 'Partilha de dados de saúde';

  @override
  String get askOncePerChatSession => 'Perguntar uma vez por sessão de chat';

  @override
  String get otherwiseAskBeforeEveryCloud =>
      'Caso contrário, perguntar antes de cada mensagem para a nuvem';

  @override
  String get reportABug => 'Comunicar um erro';

  @override
  String get weatherData => 'Dados meteorológicos';

  @override
  String get openSourceLibraries => 'Bibliotecas de código aberto';

  @override
  String get license => 'Licença';

  @override
  String get licenses => 'Licenças';

  @override
  String get apiKey => 'Chave de API';

  @override
  String get saveApiKey => 'Guardar chave de API';

  @override
  String get feedbackBugReport => 'Comentários e comunicação de erros';

  @override
  String get reportSentThankYou => 'Relatório enviado. Obrigado!';

  @override
  String get weReadEveryMessageIf =>
      'Lemos todas as mensagens. Se deixaste o teu e-mail, poderás receber uma resposta.';

  @override
  String get done => 'Concluído';

  @override
  String get shareAnIdeaSuggestAn =>
      'Partilha uma ideia, sugere uma melhoria ou conta o que aconteceu e o que esperavas.';

  @override
  String get whatHappenedAndWhatDid => 'O que aconteceu e o que esperavas?';

  @override
  String get pleaseLeaveOutPasswordsApi =>
      'Não incluas palavras-passe, chaves de API nem medições pessoais de saúde.';

  @override
  String get includeDiagnostics => 'Incluir diagnóstico';

  @override
  String get optionalLogsMayContainAccount =>
      'Opcional. Os registos podem conter dados da conta ou de saúde. Revê-os abaixo antes de enviar.';

  @override
  String get diagnosticsPreview => 'PRÉ-VISUALIZAÇÃO DO DIAGNÓSTICO';

  @override
  String get sendingSharesYourEmailSubject =>
      'Ao enviar, partilhas o teu e-mail, assunto, mensagem e o diagnóstico selecionado com o suporte da Fjelia em www.fjelia.com.';

  @override
  String get copyReport => 'Copiar relatório';

  @override
  String get shareReport => 'Partilhar relatório';

  @override
  String get appleHealth => 'Apple Saúde';

  @override
  String get connectedServices => 'Serviços ligados';

  @override
  String get hiloBloodPressureBle => 'Tensão arterial Hilo BLE';

  @override
  String get writeHeartDataToApple => 'Escrever dados cardíacos no Apple Saúde';

  @override
  String get writeWeightDataToApple => 'Escrever dados de peso no Apple Saúde';

  @override
  String get renphoScaleBle => 'Balança Renpho (BLE)';

  @override
  String get polarH10HrvStrapBle => 'Polar H10 (cinta HRV, BLE)';

  @override
  String get dataSourcePriority => 'Prioridade das fontes de dados';

  @override
  String get whenMultipleSourcesProvideThe =>
      'Quando várias fontes fornecem a mesma métrica, ganha a fonte mais acima. Arrasta para reordenar.';

  @override
  String get resetToDefault => 'Repor predefinição';

  @override
  String get disconnect => 'Desligar';

  @override
  String get healthPage => 'Página de saúde';

  @override
  String get loadPage => 'Página de carga';

  @override
  String get healthMonitor => 'Monitor de saúde';

  @override
  String get hrZones => 'Zonas de FC';

  @override
  String get t30MinTtAvailableSync =>
      'Contrarrelógio de 30 min disponível — sincronizar zonas de FC';

  @override
  String lt2Lt2BpmAt(Object lt2, Object at) {
    return 'LT2 $lt2 bpm · $at';
  }

  @override
  String get syncLabel => 'SINC';

  @override
  String get autoadjust => 'AUTOAJUSTE';

  @override
  String zoneI(Object i) {
    return 'Zona $i';
  }

  @override
  String get hrZones2 => 'ZONAS DE FC';

  @override
  String ageRound(Object round) {
    return 'idade $round';
  }

  @override
  String get basics => 'Básico';

  @override
  String get updateWaistMonthlyUsedFor =>
      'ⓘ Atualiza a cintura todos os meses — usada para estimar a gordura visceral.';

  @override
  String get alcohol => 'Álcool';

  @override
  String get t1Drink033L =>
      '1 bebida ≈ 0,33 l de cerveja / 0,2 l de vinho / 4 cl de bebidas destiladas';

  @override
  String get clinicalLabsOptional => 'Análises clínicas (opcional)';

  @override
  String get glycemic => 'Glicemia';

  @override
  String get optimalForLongevity48 =>
      'Ideal para a longevidade: 4,8–5,4% · Pré-diabetes: 5,7–6,4%';

  @override
  String get lipids => 'Lípidos';

  @override
  String get apobReplacesLdlWhenBoth =>
      'A ApoB substitui o LDL quando ambos são introduzidos.';

  @override
  String get inflammationKidney => 'Inflamação e rim';

  @override
  String get changesAreSavedAutomatically =>
      'As alterações são guardadas automaticamente';

  @override
  String get optionalTotalClimbingForThis =>
      'Opcional: desnível positivo total desta prova.';

  @override
  String get moreAboutThisEvent => 'Mais sobre este evento';

  @override
  String distanceOfDistancekmKm(Object distanceKm) {
    return 'Distância de $distanceKm km?';
  }

  @override
  String keepDistancekmKm(Object distanceKm) {
    return 'Manter $distanceKm km';
  }

  @override
  String useLikelyKm(Object likely) {
    return 'Usar $likely km';
  }

  @override
  String get thisBackupContainsNoCalendar =>
      'Esta cópia de segurança não contém atividades do calendário.';

  @override
  String get activities => 'Atividades';

  @override
  String get exportActivitiesCsv => 'Exportar atividades em CSV';

  @override
  String get backupRestore => 'Cópia de segurança e restauro';

  @override
  String get backup => 'Cópia de segurança';

  @override
  String get restoreFromBackup => 'Restaurar a partir da cópia de segurança';

  @override
  String get backupRestoredRestartTheApp =>
      'Cópia de segurança restaurada. Reinicia a app para carregar todas as definições.';

  @override
  String get raceGoals => 'Objetivos de prova';

  @override
  String get yourActivities => 'As tuas atividades';

  @override
  String get usedByAiCoachAnd =>
      'Usado pelo treinador IA e pelo plano de treino. Desportos do plano marcados com ✦.';

  @override
  String get calendarWeekStart => 'Início da semana no calendário';

  @override
  String get planDefaultView => 'Vista predefinida do plano';

  @override
  String get weeklySchedule => 'Horário semanal';

  @override
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek) {
    String _temp0 = intl.Intl.pluralLogic(
      trainingDaysPerWeek,
      locale: localeName,
      other: '$trainingDaysPerWeek dias de treino',
      one: '$trainingDaysPerWeek dia de treino',
    );
    return '$_temp0 · toca para alternar treino / descanso / força';
  }

  @override
  String get updatePlanToThisSchedule => 'Ajustar o plano a este horário';

  @override
  String get updateStrengthSessions => 'Atualizar treinos de força';

  @override
  String get sessionsPerDay => 'Treinos por dia';

  @override
  String get canYouFitTwoWorkouts =>
      'Consegues fazer dois treinos no mesmo dia?';

  @override
  String get strengthLoadUnit => 'Unidade de carga de força';

  @override
  String get weightsThemselvesAreSetIn =>
      'Os pesos definem-se em cada treino e são lembrados a partir do teu histórico.';

  @override
  String get hoursAvailableWeek => 'Horas disponíveis / semana';

  @override
  String hoursperweekHWeek(Object hoursPerWeek) {
    return '$hoursPerWeek h / semana';
  }

  @override
  String hoursperweekH(Object hoursPerWeek) {
    return '$hoursPerWeek h';
  }

  @override
  String get heatAcclimation => 'Aclimatação ao calor';

  @override
  String get showHeatAcclimation => 'Mostrar aclimatação ao calor';

  @override
  String get weatherEvaluatedAgainstAConfigurable =>
      'A meteorologia é avaliada para uma localização configurável.';

  @override
  String get trainingPlan => 'Plano de treino';

  @override
  String get regenerateReplacesFutureSessionsAnd =>
      'Gerar de novo substitui os treinos futuros e reconstrói o plano a partir de hoje com as definições atuais.';

  @override
  String valueUpcomingWorkoutsGenerated(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value treinos futuros criados',
      one: '$value treino futuro criado',
    );
    return '$_temp0';
  }

  @override
  String get generationFailedCheckYourRace =>
      'A geração falhou. Verifica o objetivo de prova e tenta novamente.';

  @override
  String get deleteAllWorkouts => 'Eliminar todos os treinos';

  @override
  String get changesAreSavedAutomatically2 =>
      '✓ As alterações são guardadas automaticamente';

  @override
  String countUpcomingWorkoutsGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count treinos futuros criados',
      one: '$count treino futuro criado',
    );
    return '$_temp0';
  }

  @override
  String get importRaceGoalsFromGarmin =>
      'Importar objetivos de prova da Garmin';

  @override
  String get addRaceGoal => 'Adicionar objetivo de prova';

  @override
  String priorityTouppercase(Object toUpperCase) {
    return 'Prioridade $toUpperCase';
  }

  @override
  String get goalsAreSharedWithAi =>
      'Os objetivos são partilhados com o treinador IA. As prioridades A, B e C definem como o plano pondera as tuas provas entre si.';

  @override
  String get deletingWorkouts => 'A eliminar treinos';

  @override
  String get cityOrTown => 'Cidade ou localidade';

  @override
  String get eGHannoverOrPalma => 'p. ex. Hanôver ou Palma';

  @override
  String get noCitiesFoundTryA =>
      'Nenhuma cidade encontrada. Experimenta uma localidade próxima.';

  @override
  String get chooseTheLocationForThe =>
      'Escolhe a localização para a previsão do plano, o radar e a aclimatação ao calor. A meteorologia funciona mesmo com a aclimatação ao calor desligada.';

  @override
  String get none => 'Nenhuma';

  @override
  String get disableLocalWeatherAndLocation =>
      'Desativar meteorologia local e pedidos de localização';

  @override
  String get currentLocation => 'Localização atual';

  @override
  String get followYourDeviceLocation => 'Seguir a localização do dispositivo';

  @override
  String get fixedLocation => 'Localização fixa';

  @override
  String get chooseACityOrEnter => 'Escolhe uma cidade ou introduz coordenadas';

  @override
  String get chooseCity => 'Escolher cidade';

  @override
  String get coordinates => 'Coordenadas';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get saveLocation => 'Guardar localização';

  @override
  String get refreshCurrentLocation => 'Atualizar localização atual';

  @override
  String get citySearchOpenMeteoGeonames =>
      'Pesquisa de cidades: Open-Meteo / GeoNames';

  @override
  String get cityNamesOpenstreetmap => 'Nomes de localidades: © OpenStreetMap';

  @override
  String get energy => 'ENERGIA';

  @override
  String get currentEnergy => 'ENERGIA ATUAL';

  @override
  String get dailyTimeline => 'EVOLUÇÃO DIÁRIA';

  @override
  String valueValue2(Object value, Object value2) {
    return '$value → $value2';
  }

  @override
  String get energy2 => 'Energia';

  @override
  String get noData => 'Sem dados';

  @override
  String get bloodPressureInsights => 'ANÁLISE DA TENSÃO ARTERIAL';

  @override
  String get sys => ' Sis';

  @override
  String get diaMmhg => ' Dia · mmHg';

  @override
  String get previousBloodPressurePeriod => 'Período de tensão anterior';

  @override
  String get nextBloodPressurePeriod => 'Período de tensão seguinte';

  @override
  String get nightDipping => 'Descida noturna';

  @override
  String get noMeasurementsInThisPeriod => 'Sem medições neste período';

  @override
  String get fullscreenBloodPressureChart =>
      'Gráfico da tensão em ecrã inteiro';

  @override
  String get barsMinMaxLineDots =>
      'Barras: mín.–máx. · linha/pontos: média · toca ou arrasta para ver';

  @override
  String get noMeasurements => 'Sem medições';

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
      other: '$length medições',
      one: '$length medição',
      zero: '$length medições',
    );
    return '$_temp0 · média / mín.–máx.';
  }

  @override
  String bloodPressureTouppercaseMmhg(Object toUpperCase) {
    return 'TENSÃO ARTERIAL · $toUpperCase · mmHg';
  }

  @override
  String get closeFullscreenBloodPressureChart =>
      'Fechar gráfico da tensão em ecrã inteiro';

  @override
  String get chooseScale => 'Escolher balança';

  @override
  String get noScalesFoundStepOn =>
      'Nenhuma balança encontrada. Sobe para a balança e tenta novamente.';

  @override
  String nameRssiDbm(Object name, Object rssi) {
    return '$name · $rssi dBm';
  }

  @override
  String get renphoSaved => 'RENPHO guardado:';

  @override
  String get renphoScaleBle2 => 'Balança RENPHO (BLE)';

  @override
  String get changeMeasurementType => 'Mudar tipo de medição';

  @override
  String get addMeasurement => 'Adicionar medição';

  @override
  String get whatAreYouMeasuring => 'O que estás a medir?';

  @override
  String get chooseAnotherMeasurement => 'Escolher outra medição';

  @override
  String get saveMeasurement => 'Guardar medição';

  @override
  String get skip => 'Saltar';

  @override
  String get connectHiloService => 'Ligar o serviço Hilo';

  @override
  String get connectHilo => 'Ligar Hilo';

  @override
  String get connectCoros => 'Ligar Coros';

  @override
  String get europe => 'Europa';

  @override
  String get unitedStates => 'Estados Unidos';

  @override
  String get asia => 'Ásia';

  @override
  String get bluetoothBloodPressure => 'Bluetooth · tensão arterial';

  @override
  String get cloudCuffData => 'Nuvem · dados da braçadeira';

  @override
  String get apiSync => 'Sincronização por API';

  @override
  String get bluetoothHrvStrap => 'Bluetooth · cinta HRV';

  @override
  String get accesslinkApi => 'AccessLink API';

  @override
  String get systemHealthData => 'Dados de saúde do sistema';

  @override
  String get cloudScaleHistory => 'Nuvem · histórico da balança';

  @override
  String get bluetoothWeightBody => 'Bluetooth · peso e corpo';

  @override
  String get connectYourDevices => 'Liga os teus dispositivos';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get connectGarmin => 'Ligar Garmin';

  @override
  String get connectAppleHealth => 'Ligar Apple Saúde';

  @override
  String get dataSynced => 'DADOS SINCRONIZADOS';

  @override
  String get pairHiloPod => 'Emparelhar Hilo Pod';

  @override
  String get chooseStrap => 'Escolher cinta';

  @override
  String namePaired(Object name) {
    return '$name emparelhado.';
  }

  @override
  String get pairPolarH10 => 'Emparelhar Polar H10';

  @override
  String get forget => 'Esquecer';

  @override
  String get sendWorkoutToPolar => 'Enviar treino para a Polar';

  @override
  String get connectPolar => 'Ligar Polar';

  @override
  String get signInWithPolarFlow => 'Iniciar sessão com o Polar Flow';

  @override
  String get syncsSleepStagesHrvResting =>
      'Sincroniza fases do sono · HRV · FC em repouso · treinos · passos';

  @override
  String savedForV(Object v) {
    return 'Guardado para $v';
  }

  @override
  String get remove => 'Remover';

  @override
  String get polarEMail => 'E-mail da Polar';

  @override
  String get polarPassword => 'Palavra-passe da Polar';

  @override
  String get pairRenphoScale => 'Emparelhar balança RENPHO';

  @override
  String get connectRenpho => 'Ligar Renpho';

  @override
  String get connectSuunto => 'Ligar Suunto';

  @override
  String smsSentToTrim(Object trim) {
    return 'SMS enviado para $trim';
  }

  @override
  String get resendSms => 'Reenviar SMS';

  @override
  String get retryLoadingPreferences => 'Voltar a carregar preferências';

  @override
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed) {
    return 'TEMPO DE TREINO SEMANAL · $toStringAsFixed h';
  }

  @override
  String get tapADayToCycle =>
      'Toca num dia para alternar treino / descanso / força.';

  @override
  String get doubleDayOk => 'Dia duplo ok';

  @override
  String get birthYearOptional => 'Ano de nascimento (opcional)';

  @override
  String get addAnother => 'Adicionar outro';

  @override
  String get knowYourBodyTrainSmarter =>
      'Conhece o teu corpo.\nTreina de forma mais inteligente.';

  @override
  String get allYourHealthDevicesOne =>
      'Todos os teus dispositivos de saúde. Uma vista inteligente.';

  @override
  String get areYouReadyToTrain => 'Estás pronto para treinar hoje?';

  @override
  String get hrvRecoveryScoreRestingHr =>
      'HRV · Pontuação de recuperação · FC em repouso';

  @override
  String get didYouActuallyRecoverLast => 'Recuperaste mesmo esta noite?';

  @override
  String get sleepStagesDeepSleepSpo => 'Fases do sono · Sono profundo · SpO₂';

  @override
  String get isYourBloodPressureUnder =>
      'A tua tensão arterial está controlada?';

  @override
  String get continuousBpNightDippingTrends =>
      'Tensão contínua · Descida noturna · Tendências';

  @override
  String get howHardDidYouPush => 'Quanto te esforçaste esta semana?';

  @override
  String get trainingLoadTrimpStrainScore =>
      'Carga de treino · TRIMP · Strain Score';

  @override
  String get isYourBodyCompositionImproving =>
      'A tua composição corporal está a melhorar?';

  @override
  String get weightBodyFatMuscleMass =>
      'Peso · Gordura corporal · Massa muscular';

  @override
  String get getStarted => 'Começar';

  @override
  String get yourDataStaysOnYour =>
      'Os teus dados. Tu escolhes o que partilhas.';

  @override
  String get bodyScale => 'Balança';

  @override
  String get bodyComposition => 'Composição corporal';

  @override
  String get sleep => 'SONO';

  @override
  String get sleepPerformance => 'DESEMPENHO DO SONO';

  @override
  String get sleepHistory => 'Histórico do sono';

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
    return 'Mais $label';
  }

  @override
  String get gymMode => 'Modo ginásio';

  @override
  String get finishWorkout => 'Terminar treino';

  @override
  String get workoutActions => 'Ações do treino';

  @override
  String get discardWorkout => 'Descartar treino';

  @override
  String get allSetsRecorded => 'Todas as séries registadas';

  @override
  String get reviewSets => 'Rever séries';

  @override
  String get rest => 'DESCANSO';

  @override
  String plannedResttarget(Object restTarget) {
    return 'Previsto $restTarget';
  }

  @override
  String get startSet => 'Iniciar série';

  @override
  String get seconds => 'Segundos';

  @override
  String get previousSet => 'Série anterior';

  @override
  String get allSets => 'Todas as séries';

  @override
  String get nextSet => 'Série seguinte';

  @override
  String get everySetIsSavedAs =>
      'Cada série é guardada à medida que avanças. Fecha este ecrã quando quiseres e retoma a partir do treino planeado.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get apply => 'Aplicar';

  @override
  String get effortScale => 'Escala de esforço';

  @override
  String get setType => 'Tipo de série';

  @override
  String get reps => 'Reps';

  @override
  String get range => 'Intervalo';

  @override
  String get time => 'Tempo';

  @override
  String get t45Or100 => '45 ou 1:00';

  @override
  String get blankWhenNotSet => 'Vazio se não definido';

  @override
  String get redBand => 'Elástico vermelho';

  @override
  String get t90Or130 => '90 ou 1:30';

  @override
  String get blankWhenUnknown => 'Vazio se desconhecido';

  @override
  String get usePlannedLoad => 'Usar carga planeada';

  @override
  String get blankWhenNotMeasured => 'Vazio se não medido';

  @override
  String get exercise => 'Exercício';

  @override
  String get changingTheLoadConventionStarts =>
      'Mudar a forma de registar a carga inicia um histórico separado para este exercício.';

  @override
  String get barbellMachine => 'Barra, máquina…';

  @override
  String get load => 'Carga';

  @override
  String get loadRefersTo => 'A carga refere-se a';

  @override
  String get t2ForAPair => '2 para um par';

  @override
  String get repetitions => 'Repetições';

  @override
  String get availablePlatesOrDumbbells => 'Discos ou halteres disponíveis';

  @override
  String get rememberForThisEquipment => 'Lembrar para este equipamento';

  @override
  String get findOrNameAnExercise => 'Procura ou dá nome a um exercício';

  @override
  String createTrim(Object trim) {
    return 'Criar “$trim”';
  }

  @override
  String get customExercise => 'Exercício personalizado';

  @override
  String get smallestLoadStep => 'Menor incremento de carga';

  @override
  String whatRemoved(Object what) {
    return '$what removido';
  }

  @override
  String get undo => 'Anular';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get performance => 'Desempenho';

  @override
  String get addExercise => 'Adicionar exercício';

  @override
  String get finishLog => 'Terminar registo';

  @override
  String get keepAsDraft => 'Manter como rascunho';

  @override
  String actionsForName(Object name) {
    return 'Ações para $name';
  }

  @override
  String get editExercise => 'Editar exercício';

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Descer';

  @override
  String get addSet => 'Adicionar série';

  @override
  String get removeLastSet => 'Remover última série';

  @override
  String get saveAsTemplate => 'Guardar como modelo';

  @override
  String savedTitleAsATemplate(Object title) {
    return '“$title” guardado como modelo. Este treino só muda quando o guardares.';
  }

  @override
  String nameSetN(Object name, Object n) {
    return '$name · Série $n';
  }

  @override
  String nameAllWorkingSets(Object name) {
    return '$name · Todas as séries de trabalho';
  }

  @override
  String labelRest(Object label) {
    return '$label descanso';
  }

  @override
  String get secondsOrMSs => 'Segundos ou m:ss';

  @override
  String get applyToAllSets => 'Aplicar a todas as séries';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get supersetWithNext => 'Supersérie com o seguinte';

  @override
  String get circuitWithNext => 'Circuito com o seguinte';

  @override
  String actionsForSetN(Object n) {
    return 'Ações para a série $n';
  }

  @override
  String get editSet => 'Editar série';

  @override
  String get duplicateSet => 'Duplicar série';

  @override
  String get removeSet => 'Remover série';

  @override
  String labelActions(Object label) {
    return 'Ações de $label';
  }

  @override
  String get editRests => 'Editar descansos';

  @override
  String get ungroup => 'Desagrupar';

  @override
  String get editExercises => 'Editar exercícios';

  @override
  String get unsavedChanges => 'Alterações não guardadas';

  @override
  String couldNotSaveError(Object error) {
    return 'Não foi possível guardar: $error';
  }

  @override
  String get history => 'Histórico';

  @override
  String get exercises => 'Exercícios';

  @override
  String get noExercisesArePlannedFor =>
      'Ainda não há exercícios planeados para este treino. As notas acima descrevem-no.';

  @override
  String get addExercises => 'Adicionar exercícios';

  @override
  String get fromTheBuiltInTemplate =>
      'Do modelo integrado. As cargas defines tu; o histórico aparece quando registares um treino.';

  @override
  String get shareExerciseList => 'Partilhar lista de exercícios';

  @override
  String get noSavedStrengthTemplatesYet =>
      'Ainda não há modelos de força guardados. Guarda primeiro um a partir de um treino planeado.';

  @override
  String get compareWith => 'Comparar com';

  @override
  String estimated1rmUnit(Object unit) {
    return '1RM estimado $unit';
  }

  @override
  String get plannedNotRecorded => 'Planeado, não registado';

  @override
  String get notes => 'Notas';

  @override
  String get editPerformance => 'Editar desempenho';

  @override
  String get compareWithASavedWorkout => 'Comparar com um treino guardado';

  @override
  String get sessions => 'Treinos';

  @override
  String get radarUnavailableRetry => 'Radar indisponível · Tentar novamente';

  @override
  String get radar => 'Radar';

  @override
  String get weatherDataByRainviewer => 'Dados meteorológicos da RainViewer';

  @override
  String get openstreetmapContributors => '© Colaboradores do OpenStreetMap';

  @override
  String get weather => 'Meteorologia';

  @override
  String get weatherUnavailableRetry =>
      'Meteorologia indisponível · Tentar novamente';

  @override
  String get chooseAFixedLocationIn =>
      'Escolhe uma localização fixa nas definições de Meteorologia e localização ou permite o acesso à localização para a meteorologia local.';

  @override
  String get locationSettings => 'Definições de localização';

  @override
  String get retryLocation => 'Tentar localização novamente';

  @override
  String round2(Object round) {
    return '$round°';
  }

  @override
  String roundRhRound2Hpa(Object round, Object round2) {
    return '$round% HR · $round2 hPa';
  }

  @override
  String wetBulbTostringasfixedC(Object toStringAsFixed) {
    return 'Bolbo húmido $toStringAsFixed°C';
  }

  @override
  String get previousForecastDay => 'Dia de previsão anterior';

  @override
  String get nextForecastDay => 'Dia de previsão seguinte';

  @override
  String daysDayForecast(Object days) {
    return 'Previsão a $days dias';
  }

  @override
  String thisProviderCurrentlySuppliesDays(Object days, Object days2) {
    return 'Este fornecedor indica atualmente $days de $days2 dias de previsão.';
  }

  @override
  String get now => 'Agora';

  @override
  String get sunriseSunset => 'Nascer / pôr do sol';

  @override
  String keyKey2(Object key, Object key2) {
    return '☀ $key   ☾ $key2';
  }

  @override
  String get use => 'Usar';

  @override
  String get exerciseDetailsWereNotProvided =>
      'Esta fonte de atividade não forneceu detalhes dos exercícios.';

  @override
  String get logFromPlan => 'Registar a partir do plano';

  @override
  String get addExerciseDetails => 'Adicionar detalhes dos exercícios';

  @override
  String get loadSuggestion => 'Sugestão de carga';

  @override
  String get applyToThisWorkout => 'Aplicar a este treino';

  @override
  String get keepCurrentLoad => 'Manter carga atual';

  @override
  String get setLoadStep => 'Definir incremento de carga';

  @override
  String get viewSupportingSets => 'Ver séries de apoio';

  @override
  String get supportingSets => 'Séries de apoio';

  @override
  String get noRecordedSessionsYet => 'Ainda não há treinos registados.';

  @override
  String nameDemonstrationCue(Object name, Object cue) {
    return 'Demonstração de $name. $cue';
  }

  @override
  String get noScalesFoundStepOn2 =>
      'Nenhuma balança encontrada. Sobe para a balança e tenta novamente.';

  @override
  String get scalePaired => 'Balança emparelhada';

  @override
  String get ok => 'OK';

  @override
  String get pairedReadyToMeasure => '✓ Emparelhado — pronto para medir';

  @override
  String get chooseHiloCuff => 'Escolher braçadeira Hilo';

  @override
  String get noCuffFoundWakeYour =>
      'Nenhuma braçadeira encontrada. Ativa a braçadeira e procura novamente.';

  @override
  String get hiloCuffAktiiaC => 'Braçadeira Hilo (AKTIIA C…)';

  @override
  String get onDemandBloodPressureVia => 'Tensão arterial a pedido por BLE';

  @override
  String get selectHiloPodWristband => 'Selecionar Hilo Pod (pulseira)';

  @override
  String get rescan => 'Procurar novamente';

  @override
  String get noDevicesFoundTapTo =>
      'Nenhum dispositivo encontrado. Toca em ↻ para procurar novamente.';

  @override
  String get polarH10SpotHrv => 'Polar H10 · HRV pontual';

  @override
  String get aSeparateHrvReadingBefore =>
      'Uma medição de HRV separada antes ou depois do treino. Estas medições não substituem a HRV noturna da Garmin nem alteram a tua pontuação de prontidão.';

  @override
  String get wearTheStrapWithMoist =>
      'Usa a cinta com os elétrodos humedecidos. Fica quieto e respira normalmente. Para comparações, usa a mesma posição e a mesma duração. Depois do treino, regista quanto tempo descansaste primeiro.';

  @override
  String get measurement => 'Medição';

  @override
  String get posture => 'Posição';

  @override
  String get recordingLengthPlus1Min =>
      'Duração da medição · mais 1 min para estabilizar';

  @override
  String get t2Minutes => '2 minutos';

  @override
  String get t5Minutes => '5 minutos';

  @override
  String get minutesSinceTrainingEndedOptional =>
      'Minutos desde o fim do treino (opcional)';

  @override
  String get sessionOrNotesOptional => 'Treino ou notas (opcional)';

  @override
  String connectName(Object name) {
    return 'Ligar $name';
  }

  @override
  String get findPolarH10 => 'Procurar Polar H10';

  @override
  String signalRssiDbm(Object rssi) {
    return 'Sinal $rssi dBm';
  }

  @override
  String connectedName(Object name) {
    return 'Ligado: $name';
  }

  @override
  String get waitingForHeartRateAnd =>
      'A aguardar frequência cardíaca e intervalos RR. Verifica o contacto da cinta.';

  @override
  String get startMeasurement => 'Iniciar medição';

  @override
  String get cancelMeasurement => 'Cancelar medição';

  @override
  String get spotHrvRmssd => 'HRV pontual · RMSSD';

  @override
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  ) {
    return '$accepted/$length intervalos utilizáveis · $toStringAsFixed% de cobertura';
  }

  @override
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs) {
    return 'lnRMSSD: $lnRmssd · RMSSD bruto: $rawRmssdMs ms';
  }

  @override
  String get signalQualityIsTooLow =>
      'A qualidade do sinal é demasiado baixa para guardar. Repete a medição com bom contacto da cinta. São necessários pelo menos 95% de intervalos utilizáveis e 90% de cobertura.';

  @override
  String get savedToSpotHrvHistory => 'Guardado no histórico de HRV pontual.';

  @override
  String get newMeasurement => 'Nova medição';

  @override
  String get signalScreeningExcludesPoorContact =>
      'A verificação do sinal exclui mau contacto, RR fora de 250–2500 ms e intervalos que se afastam mais de 25% da mediana local. As falhas não são preenchidas. Não é um exame médico nem uma pontuação de prontidão isolada.';

  @override
  String historyLabelLabel2DurationMin(
    Object label,
    Object label2,
    Object duration,
  ) {
    return 'Histórico · $label · $label2 · $duration min';
  }

  @override
  String get onlyReadingsWithTheSame =>
      'Só são mostradas juntas medições com o mesmo contexto, posição e duração.';

  @override
  String get noMatchingMeasurementsYet =>
      'Ainda não há medições correspondentes.';

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
  String get deleteMeasurement => 'Eliminar medição';

  @override
  String get remindMeToMeasureHrv =>
      'Lembrar-me de medir a HRV depois do treino';

  @override
  String get appleHealthIsNoLonger => 'O Apple Saúde já não está disponível';

  @override
  String get later => 'Mais tarde';

  @override
  String get reconnect => 'Voltar a ligar';

  @override
  String get gripStrength => 'Força de preensão';

  @override
  String get leftKg => 'Esquerda (kg)';

  @override
  String get rightKg => 'Direita (kg)';

  @override
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg) {
    return 'E $leftKg · D $rightKg kg';
  }

  @override
  String get notificationsAreOffYouCan =>
      'As notificações estão desativadas. Podes continuar a medir a partir do treino.';

  @override
  String get noRemindersFrom2200 => 'Sem lembretes das 22:00 às 07:00';

  @override
  String get aReminderThatWouldFall =>
      'Um lembrete que calhe neste período é ignorado, não passa para a manhã.';

  @override
  String get remindersArriveQuietlyInThe =>
      'Os lembretes chegam em silêncio à lista de notificações.';

  @override
  String get noForecastForThisDay => 'Sem previsão para este dia';

  @override
  String get fullscreen => 'Ecrã inteiro';

  @override
  String source(Object source) {
    return '● $source';
  }

  @override
  String get temperatureC => '● Temperatura °C';

  @override
  String get rainMm => '▥ Chuva mm';

  @override
  String get uvIndex => '— Índice UV';

  @override
  String get closeFullscreenWeatherChart =>
      'Fechar gráfico meteorológico em ecrã inteiro';

  @override
  String get sleepStages => 'FASES DO SONO';

  @override
  String get noStageTimelineForThis =>
      'Sem evolução das fases para esta noite.';

  @override
  String round3(Object round) {
    return '$round%';
  }

  @override
  String get examplesOnlyCheckAndEnter =>
      'Apenas exemplos: verifica e introduz os valores do rótulo do produto por dose. Deixa em branco os nutrientes desconhecidos; introduz 0 só quando souberes.';

  @override
  String get nutritionStrategy => 'Estratégia de nutrição';

  @override
  String get noPreWorkoutNutritionStrategy =>
      'Não foi guardada nenhuma estratégia de nutrição pré-treino.';

  @override
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium) {
    return '$carbs g hidratos/h · $fluid ml/h · $sodium mg sódio/h';
  }

  @override
  String get forecastUpdatedReviewOrRecalculate =>
      'Previsão atualizada — revê ou recalcula a estratégia guardada.';

  @override
  String strategySavedSavedat(Object savedAt) {
    return 'Estratégia guardada $savedAt';
  }

  @override
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  ) {
    return 'Total durante: $totalCarbs g hidratos · $totalFluid ml · $totalSodium mg sódio';
  }

  @override
  String every20MinAboutCarbs(Object carbs, Object fluid) {
    return 'A cada 20 min: cerca de $carbs g de hidratos e $fluid ml.';
  }

  @override
  String get packQuantitiesIncludeFullContainers =>
      'As quantidades a levar incluem embalagens completas; não tens de consumir tudo.';

  @override
  String get workoutChangedReviewOrRecalculate =>
      'O treino mudou — revê ou recalcula esta estratégia guardada.';

  @override
  String get conditionsAndFeedingPlan => 'Condições e plano de alimentação';

  @override
  String get editStrategy => 'Editar estratégia';

  @override
  String get recalculate => 'Recalcular';

  @override
  String get actualNutrition => 'Nutrição real';

  @override
  String get someProductValuesAreUnknown =>
      'Alguns valores de produtos são desconhecidos; os totais estão incompletos.';

  @override
  String get logFoodAndFluids => 'Registar comida e líquidos';

  @override
  String get recordWhatYouActuallyHad =>
      'Regista o que realmente consumiste. A ingestão planeada não é copiada para este registo.';

  @override
  String get elapsedMinutesIncludingStopsOptional =>
      'Minutos decorridos incluindo paragens (opcional)';

  @override
  String recordedDurationActivityMin(Object activity) {
    return 'Duração registada: $activity min';
  }

  @override
  String get compareWithSavedStrategy => 'Comparar com a estratégia guardada';

  @override
  String get useMatchedSessionIfAvailable =>
      'Usar o treino associado, se disponível';

  @override
  String get noPlanComparison => 'Sem comparação com o plano';

  @override
  String titleDate(Object title, Object date) {
    return '$title · $date';
  }

  @override
  String get linkedStrategyUnavailable => 'Estratégia associada indisponível';

  @override
  String quantityName(Object quantity, Object name) {
    return '$quantity × $name';
  }

  @override
  String get removeIntake => 'Remover ingestão';

  @override
  String get addFoodOrDrink => 'Adicionar comida ou bebida';

  @override
  String get iHadNoIntake => 'Não consumi nada';

  @override
  String get giGutComfort => 'Conforto gastrointestinal';

  @override
  String get whatWorkedSymptomsAccessProblems =>
      'O que funcionou / sintomas / problemas de acesso';

  @override
  String get saveDraft => 'Guardar rascunho';

  @override
  String get skipLoggingThisActivity => 'Não registar esta atividade';

  @override
  String get nutritionAndFluids => 'Nutrição e líquidos';

  @override
  String get productsToleranceAndMeasuredSweat =>
      'Produtos, tolerância e perdas de suor medidas';

  @override
  String get postWorkoutIntakeReminder => 'Lembrete de ingestão pós-treino';

  @override
  String get onceAfterARecentEndurance =>
      'Uma vez depois de um treino de resistência recente; horas de silêncio 22:00–08:00.';

  @override
  String get addHiloBpReport => 'Adicionar relatório de tensão Hilo';

  @override
  String get readingPdfReportsIsOnly =>
      'A leitura de relatórios PDF só está disponível no iOS e no macOS.';

  @override
  String get chooseAnotherReport => 'Escolher outro relatório';

  @override
  String get biologicalAge => 'Idade biológica';

  @override
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class) {
    return 'VO₂máx $vo2max ml/kg/min · $vo2Class';
  }

  @override
  String get factorContributions => 'Contribuição dos fatores';

  @override
  String estimatedRangeRoundRound2Years(Object round, Object round2) {
    return 'Intervalo estimado $round–$round2 anos. Uma estimativa do modelo, não um diagnóstico médico.';
  }

  @override
  String get noEnergyMeasurementsForThis =>
      'Sem medições de energia para este dia';

  @override
  String get scanningStepOnTheScale =>
      'A procurar… sobe para a balança quando estiveres pronto.';

  @override
  String waistWaistCmUpdateMonthly(Object waist) {
    return 'Cintura: $waist cm — atualiza todos os meses no Perfil';
  }

  @override
  String get measuring => 'A medir…';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get systolic => 'Sistólica';

  @override
  String get diastolic => 'Diastólica';

  @override
  String get heartRate => 'Frequência cardíaca';

  @override
  String get weight => 'Peso';

  @override
  String get bodyFat => 'Gordura corporal';

  @override
  String get duration => 'Duração';

  @override
  String get deep => 'Profundo';

  @override
  String get spo => 'SpO₂';

  @override
  String get activityName => 'Nome da atividade';

  @override
  String get sport => 'Desporto';

  @override
  String get distance => 'Distância';

  @override
  String get saved => 'Guardado';

  @override
  String get connectionFailedCheckYourInternet =>
      'A ligação falhou. Verifica a tua ligação à internet.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Palavra-passe';

  @override
  String get passwordTooShort => 'Palavra-passe demasiado curta';

  @override
  String get loginFailedCheckYourEmail =>
      'O início de sessão falhou. Verifica o e-mail e a palavra-passe.';

  @override
  String get connectionFailedCheckYourCredentials =>
      'A ligação falhou. Verifica as credenciais e a ligação à internet.';

  @override
  String get region => 'Região';

  @override
  String get hiloPod => 'Hilo pod';

  @override
  String get hiloAccount => 'Conta Hilo';

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
  String get renphoAccount => 'Conta Renpho';

  @override
  String get garminConnectEmail => 'E-mail do Garmin Connect';

  @override
  String get verifyMfaCode => 'Verificar código MFA';

  @override
  String get verificationCode => 'Código de verificação';

  @override
  String errorE(Object e) {
    return 'Erro: $e';
  }

  @override
  String get noHiloPodFoundMake =>
      'Nenhum Hilo pod encontrado. Confirma que está carregado e por perto.';

  @override
  String scanFailedE(Object e) {
    return 'A procura falhou: $e';
  }

  @override
  String get hiloPod2 => 'Hilo Pod';

  @override
  String get scanForPod => 'Procurar pod';

  @override
  String get scanForPolarH10 => 'Procurar Polar H10';

  @override
  String get couldNotReachPolarCheck =>
      'Não foi possível contactar a Polar. Verifica a ligação.';

  @override
  String get signInAndSendWorkout => 'Iniciar sessão e enviar treino';

  @override
  String get scanForScale => 'Procurar balança';

  @override
  String get passwordRequired => 'Palavra-passe obrigatória';

  @override
  String get enterYourPhoneNumberWith =>
      'Introduz o teu número de telefone (com indicativo, p. ex. +351…) e o e-mail da Suunto.';

  @override
  String get enterThePinFromThe => 'Introduz o PIN do SMS.';

  @override
  String get incorrectPinPleaseTryAgain => 'PIN incorreto. Tenta novamente.';

  @override
  String get phoneNumber => 'Número de telefone';

  @override
  String get suuntoAccountEmail => 'E-mail da conta Suunto';

  @override
  String get enterPinFromSms => 'Introduzir PIN do SMS';

  @override
  String get verifyConnect => 'Verificar e ligar';

  @override
  String get sendSmsCode => 'Enviar código por SMS';

  @override
  String couldNotSavePreferencesE(Object e) {
    return 'Não foi possível guardar as preferências: $e';
  }

  @override
  String get mon => 'Seg';

  @override
  String get tue => 'Ter';

  @override
  String get wed => 'Qua';

  @override
  String get thu => 'Qui';

  @override
  String get fri => 'Sex';

  @override
  String get sat => 'Sáb';

  @override
  String get sun => 'Dom';

  @override
  String get male => 'Masculino';

  @override
  String get female => 'Feminino';

  @override
  String get other => 'Outro';

  @override
  String get running => 'Corrida';

  @override
  String get trailRunning => 'Trail';

  @override
  String get cycling => 'Ciclismo';

  @override
  String get swimming => 'Natação';

  @override
  String get triathlon => 'Triatlo';

  @override
  String get hiking => 'Caminhada';

  @override
  String get rowing => 'Remo';

  @override
  String get buildMyPlan => 'Criar o meu plano';

  @override
  String get keepAConsistentBedtimeAnd =>
      'Mantém horários regulares de deitar e acordar para apoiar a tua rotina de sono.';

  @override
  String get thisWorkoutHasNoSets => 'Este treino não tem séries.';

  @override
  String loadName(Object name) {
    return 'Carga ($name)';
  }

  @override
  String get setLabel => 'Série';

  @override
  String get lowestReps => 'Menos reps';

  @override
  String get highestReps => 'Mais reps';

  @override
  String get repsPerSide => 'Reps por lado';

  @override
  String get fromReps => 'De reps';

  @override
  String get toReps => 'Até reps';

  @override
  String get addedLoad => 'Carga adicional';

  @override
  String get assistance => 'Assistência';

  @override
  String get tempoOptional => 'Cadência (opcional)';

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get enterTheRepetitionsDone => 'Introduz as repetições feitas.';

  @override
  String plannedUnit(Object unit) {
    return 'Planeado $unit';
  }

  @override
  String get repsDone => 'Reps feitas';

  @override
  String get resistance => 'Resistência';

  @override
  String get implementsLabel => 'Acessórios';

  @override
  String get name => 'Nome';

  @override
  String get instructionsOptional => 'Instruções (opcional)';

  @override
  String get remember => 'Lembrar';

  @override
  String get notSavedYet => 'Ainda não guardado';

  @override
  String get saving => 'A guardar…';

  @override
  String get couldNotSave => 'Não foi possível guardar';

  @override
  String get plannedValuesAreHintsNot =>
      'Os valores planeados são sugestões, não resultados. Toca numa série para a registar.';

  @override
  String get completedAsPlanned => 'Concluído conforme planeado';

  @override
  String get save => 'Guardar';

  @override
  String get nameTheTemplate => 'Dá um nome ao modelo.';

  @override
  String setN(Object n) {
    return 'Série $n';
  }

  @override
  String get changesApplyToThisWorkout =>
      'As alterações aplicam-se só a este treino. Os treinos concluídos e as outras sessões ficam como estão.';

  @override
  String get saveForThisWorkout => 'Guardar para este treino';

  @override
  String knownForKnownOfOf(Object known, Object of) {
    return 'Conhecido para $known de $of séries com carga';
  }

  @override
  String get sessionEstimate => 'Estimativa do treino';

  @override
  String get calculatedRange => 'Intervalo calculado';

  @override
  String get timedWork => 'Trabalho por tempo';

  @override
  String get strengthTraining => 'Treino de força';

  @override
  String get theExercisesCouldNotBe =>
      'Não foi possível carregar os exercícios.';

  @override
  String get resumeWorkout => 'Retomar treino';

  @override
  String get strengthWorkout => 'Treino de força';

  @override
  String get untitledTemplate => 'Modelo sem título';

  @override
  String get theRecordedExercisesCouldNot =>
      'Não foi possível carregar os exercícios registados.';

  @override
  String get exercisesPerformed => 'Exercícios realizados';

  @override
  String get comparedWithThePlanAs =>
      'Comparado com o plano tal como estava quando o registo começou.';

  @override
  String topWorkingLoadName(Object name) {
    return 'Carga de trabalho máxima ($name)';
  }

  @override
  String get estimated1rmMiddleOfRange => '1RM estimado, meio do intervalo';

  @override
  String get noLoggedSessionsYet => 'Ainda não há treinos registados.';

  @override
  String get noRadarFramesAvailable => 'Sem imagens de radar disponíveis';

  @override
  String get playRadar => 'Reproduzir radar';

  @override
  String get pauseRadar => 'Pausar radar';

  @override
  String get high => 'Alto';

  @override
  String get clear => 'Limpo';

  @override
  String get bodyweight => 'Peso corporal';

  @override
  String get resistance2 => 'Resistência —';

  @override
  String assistUnit(Object unit) {
    return 'Assistência $unit';
  }

  @override
  String get reps2 => 'Reps —';

  @override
  String get notRecorded => 'Não registado';

  @override
  String get skipped => 'Saltado';

  @override
  String get health => 'Saúde';

  @override
  String get manual => 'Manual';

  @override
  String expandName(Object name) {
    return 'Expandir $name';
  }

  @override
  String get open => 'Abrir';

  @override
  String get noScalePaired => 'Nenhuma balança emparelhada';

  @override
  String get paired => 'Emparelhado';

  @override
  String get change => 'Alterar';

  @override
  String get noCuffPaired => 'Nenhuma braçadeira emparelhada';

  @override
  String get noPolarH10FoundWear =>
      'Nenhum Polar H10 encontrado. Coloca a cinta, molha os elétrodos e verifica se outra app não está a usar as duas ligações Bluetooth.';

  @override
  String get enterMinutesSinceTrainingEnded =>
      'Introduz os minutos desde o fim do treino, de 0 a 1440.';

  @override
  String get timingFollowsYourWorkout => 'A hora acompanha o teu treino.';

  @override
  String get recordingStayStill => 'A gravar · fica quieto';

  @override
  String get meanHrBpm => 'FC média · bpm';

  @override
  String get pairAPolarH10First => 'Emparelha primeiro um Polar H10.';

  @override
  String get around30MinutesAfterTraining =>
      'Cerca de 30 minutos depois do treino, quando o treino estiver disponível a tempo.';

  @override
  String get reminderDiagnostics => 'Diagnóstico dos lembretes';

  @override
  String get forecast => 'Previsão';

  @override
  String forecastRange(int count) {
    return 'Sombreado: intervalo de $count previsões';
  }

  @override
  String get enterAName => 'Introduz um nome';

  @override
  String get enterAValidAmount => 'Introduz uma quantidade válida';

  @override
  String get enterAPositiveAmount => 'Introduz uma quantidade positiva';

  @override
  String get maximum120GH => 'Máximo 120 g/h';

  @override
  String get carbohydrateTargetGH => 'Objetivo de hidratos g/h';

  @override
  String get fluidTargetMlH => 'Objetivo de líquidos ml/h';

  @override
  String get sodiumTargetMgHNot => 'Objetivo de sódio mg/h (não sal)';

  @override
  String get surfaceFeedingAccess => 'Piso / acesso à alimentação';

  @override
  String get expectedAscentM => 'Subida prevista m';

  @override
  String get expectedAltitudeM => 'Altitude prevista m';

  @override
  String get humidity => 'Humidade %';

  @override
  String get windKmH => 'Vento km/h';

  @override
  String get dayForecast => 'Previsão do dia';

  @override
  String get enteredConditions => 'Condições introduzidas';

  @override
  String get productFoodName => 'Produto / nome do alimento';

  @override
  String get servingsQuantity => 'Doses / quantidade';

  @override
  String get when => 'Quando';

  @override
  String get carbohydrateGServing => 'Hidratos g / dose';

  @override
  String get fluidMlServing => 'Líquido ml / dose';

  @override
  String get caffeineMgServing => 'Cafeína mg / dose';

  @override
  String get proteinGServing => 'Proteína g / dose';

  @override
  String get gel => 'Gel';

  @override
  String get water => 'Água';

  @override
  String get sportsDrink => 'Bebida desportiva';

  @override
  String get bar => 'Barra';

  @override
  String get finishIntakeLog => 'Terminar registo de ingestão';

  @override
  String get importing => 'A importar…';

  @override
  String importNewreadings(Object newReadings) {
    return 'Importar $newReadings';
  }

  @override
  String get reading => 'A ler…';

  @override
  String get chooseReportPdf => 'Escolher relatório (PDF)';

  @override
  String get yourTrainingHistoryIsReady =>
      'O teu histórico de treino está pronto';

  @override
  String get importingYourTrainingHistory =>
      'A importar o teu histórico de treino';

  @override
  String get stopImport => 'Parar importação';

  @override
  String get dismiss => 'Fechar';

  @override
  String get openai => 'OpenAI';

  @override
  String get appleIntelligence => 'Apple Intelligence';

  @override
  String get nonAiBriefing => 'Resumo sem IA';

  @override
  String get noBriefing => 'Sem resumo';

  @override
  String get ruleBasedSummaryFromYour =>
      'Resumo baseado em regras a partir dos teus dados de saúde — sem chamadas de API';

  @override
  String get hideTheBriefingCard => 'Ocultar o cartão de resumo';

  @override
  String get flutter => 'Flutter';

  @override
  String get stateManagement => 'Gestão de estado';

  @override
  String get bluetoothLe => 'Bluetooth LE';

  @override
  String get interactiveMaps => 'Mapas interativos';

  @override
  String get chartsGraphs => 'Gráficos';

  @override
  String get secureCredentialStorage => 'Armazenamento seguro de credenciais';

  @override
  String get markdownRendering => 'Apresentação de Markdown';

  @override
  String get appleOnDeviceAi => 'IA da Apple no dispositivo';

  @override
  String get cryptography => 'Criptografia';

  @override
  String get appleHealthHealthConnect => 'Apple Saúde e Health Connect';

  @override
  String get runtimePermissions => 'Permissões em execução';

  @override
  String get shareExport => 'Partilhar e exportar';

  @override
  String get openUrls => 'Abrir URLs';

  @override
  String get internationalisation => 'Internacionalização';

  @override
  String get utilities => 'Utilitários';

  @override
  String get icons => 'Ícones';

  @override
  String get fjelia => 'Fjelia';

  @override
  String get fjeliaFeedback => 'Comentários sobre a Fjelia';

  @override
  String get couldNotSendTheReport =>
      'Não foi possível enviar o relatório. O teu texto continua aqui. Tenta novamente.';

  @override
  String get yourEmail => 'O teu e-mail';

  @override
  String get enterAValidEmailAddress =>
      'Introduz um endereço de e-mail válido.';

  @override
  String get subject => 'Assunto';

  @override
  String get sending => 'A enviar…';

  @override
  String get sendReport => 'Enviar relatório';

  @override
  String get sleepRecovery => 'Sono e recuperação';

  @override
  String get activitiesTraining => 'Atividades e treino';

  @override
  String get bodyWellness => 'Corpo e bem-estar';

  @override
  String get hilo => 'Hilo';

  @override
  String get hiloBle => 'Hilo BLE';

  @override
  String get garminApi => 'Garmin (API)';

  @override
  String get renphoScale => 'Balança Renpho';

  @override
  String get connected => 'Ligado';

  @override
  String get notConnected => 'Não ligado';

  @override
  String get manage => 'Gerir';

  @override
  String get connect => 'Ligar';

  @override
  String get habits => 'Hábitos';

  @override
  String get smokingAlcohol => 'Tabaco, álcool';

  @override
  String get clinicalLab => 'Análises clínicas';

  @override
  String get hba1cLipidsKidney => 'HbA1c, lípidos, rim';

  @override
  String get sex => 'Sexo';

  @override
  String get smoking => 'Tabaco';

  @override
  String get never => 'Nunca';

  @override
  String get former => 'Antigo';

  @override
  String get current => 'Atual';

  @override
  String get hba1c => 'HbA1c';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get prediabetes => 'Pré-diabetes';

  @override
  String get type1 => 'Tipo 1';

  @override
  String get type2 => 'Tipo 2';

  @override
  String get apob => 'ApoB';

  @override
  String get optionalPlansAndPaceGuides =>
      'Opcional. Os planos e guias de ritmo usam-no; o desnível acima também molda o treino.';

  @override
  String get addRaceGoal2 => 'Adicionar objetivo de prova';

  @override
  String get editRaceGoal => 'Editar objetivo de prova';

  @override
  String get trailRunning2 => 'Trail';

  @override
  String get roadCycling => 'Ciclismo de estrada';

  @override
  String get gravel => 'Gravel';

  @override
  String get indoorRowing => 'Remo indoor';

  @override
  String get selectDate => 'Selecionar data';

  @override
  String get committed => 'Confirmado';

  @override
  String get flexible => 'Flexível';

  @override
  String get notGoing => 'Não vou';

  @override
  String get notSaid => 'Não indicado';

  @override
  String get finish => 'Terminar';

  @override
  String get saveGoal => 'Guardar objetivo';

  @override
  String get exportAllRecordedWorkoutsAs =>
      'Exportar todos os treinos registados como folha de cálculo.';

  @override
  String get backupsIncludeYourHealthData =>
      'As cópias de segurança incluem os teus dados de saúde, planos de treino e definições do perfil. As credenciais de início de sessão ficam de fora. Restaurar substitui os dados locais.';

  @override
  String get trail => 'Trilho';

  @override
  String get inlineSkating => 'Patinagem em linha';

  @override
  String get nordicClassic => 'Esqui de fundo clássico';

  @override
  String get skateSkiing => 'Esqui de fundo skating';

  @override
  String get strength => 'Força';

  @override
  String get walking => 'Caminhada';

  @override
  String get yoga => 'Ioga';

  @override
  String get skiing => 'Esqui';

  @override
  String get climbing => 'Escalada';

  @override
  String get monday => 'Segunda-feira';

  @override
  String get sunday => 'Domingo';

  @override
  String get month => 'Mês';

  @override
  String get week => 'Semana';

  @override
  String get list => 'Lista';

  @override
  String get train => 'Treino';

  @override
  String get restDay => 'Descanso';

  @override
  String get kilogramsKg => 'Quilogramas (kg)';

  @override
  String get poundsLb => 'Libras (lb)';

  @override
  String get regenerateWorkouts => 'Gerar treinos novamente';

  @override
  String get starting => 'A iniciar';

  @override
  String get allPlannedWorkoutsDeleted =>
      'Todos os treinos planeados foram eliminados.';

  @override
  String get searching => 'A procurar…';

  @override
  String get searchCity => 'Procurar cidade';

  @override
  String get fixedLocationSavedWeatherWill =>
      'Localização fixa guardada. A meteorologia vai ser atualizada.';

  @override
  String get locationDisabledThePlanWeather =>
      'Localização desativada. O cartão meteorológico do plano está oculto.';

  @override
  String locationSetToName(Object name) {
    return 'Localização definida para $name';
  }

  @override
  String get notEnoughDaytimeAndNighttime =>
      'Medições diurnas e noturnas insuficientes';

  @override
  String get onlyTheWeightWasReceived =>
      'Só foi recebido o peso. Para gordura corporal, músculo e os outros valores, sobe descalço para os elétrodos metálicos e fica até a balança terminar.';

  @override
  String get addYourWaistInProfile =>
      'Adiciona a cintura no Perfil para a gordura visceral.';

  @override
  String get manualActivity => 'Atividade manual';

  @override
  String get theseCredentialsAreStoredEncrypted =>
      'Estas credenciais são guardadas encriptadas no teu dispositivo (Porta-chaves do iOS / Android Keystore). Nunca são enviadas para nenhum servidor além do da Hilo.';

  @override
  String get corosCredentialsAreStoredEncrypted =>
      'As credenciais da Coros são guardadas encriptadas no teu dispositivo. A Fjelia lê os dados diretamente da API na nuvem da Coros. É a mesma API usada pela app web Coros Training Hub.';

  @override
  String get connectAnyCombinationYouCan =>
      'Liga qualquer combinação — podes sempre adicionar mais tarde nas Definições.';

  @override
  String get garminCredentialsAreStoredEncrypted =>
      'As credenciais da Garmin são guardadas encriptadas no teu dispositivo. A Fjelia usa a API não oficial do Garmin Connect – a mesma abordagem de muitas apps da comunidade.';

  @override
  String get enterTheVerificationCode => 'Introduz o código de verificação';

  @override
  String get appleHealthDataAccess =>
      'A Fjelia lê os teus dados de saúde do Apple Saúde. Com a tua autorização, também pode escrever lá os dados sincronizados. Gere o acesso nas definições do dispositivo.';

  @override
  String get scanAgain => 'Procurar novamente';

  @override
  String get wearTheHiloBandDuring =>
      'Usa a pulseira Hilo durante o sono para registar continuamente a tensão arterial. Os dados sincronizam automaticamente todas as manhãs quando abres a app.';

  @override
  String get noPolarH10FoundWear2 =>
      'Nenhum Polar H10 encontrado. Coloca a cinta com os elétrodos humedecidos, confirma que nenhuma outra app (ou relógio) está ligada a ela e procura novamente.';

  @override
  String get wearTheStrapWithMoist2 =>
      'Coloca a cinta com os elétrodos humedecidos antes de procurar. Depois mede com + → Medição de HRV Polar H10; os resultados aparecem junto da tua HRV noturna.';

  @override
  String get signedInPlannedWorkoutsCan =>
      'Sessão iniciada. Já podes enviar treinos planeados para a Polar. Os treinos mais antigos são importados na próxima sincronização completa do histórico.';

  @override
  String get saveYourPolarFlowLogin =>
      'Guarda o teu início de sessão do Polar Flow para enviar treinos planeados e importar treinos com mais de 30 dias. Fica no porta-chaves deste dispositivo e só é enviado para a Polar. Envia um treino a partir da sua ficha no plano e depois sincroniza o Polar Flow com o relógio. Confirma que as zonas de FC da Polar coincidem com as da Fjelia.';

  @override
  String get signInToSendThis =>
      'Inicia sessão para enviar este treino para o calendário do Polar Flow. O teu início de sessão fica no porta-chaves deste dispositivo e só é enviado para a Polar. Depois de enviar, sincroniza o Polar Flow com o relógio.';

  @override
  String get checkAndSave => 'Verificar e guardar';

  @override
  String get noScaleFoundStepOn =>
      'Nenhuma balança encontrada. Sobe para a balança para a ativar e procura novamente.';

  @override
  String get stepOnTheScaleBefore =>
      'Sobe para a balança antes de procurar, para que se ative. Depois mede com + → Balança RENPHO.';

  @override
  String get renphoCredentialsAreStoredEncrypted =>
      'As credenciais da Renpho são guardadas encriptadas no teu dispositivo. A Fjelia comunica diretamente com a API na nuvem da Renpho.';

  @override
  String get couldNotSendSmsCheck =>
      'Não foi possível enviar o SMS. Verifica o número de telefone e a ligação à internet.';

  @override
  String get theEmailIsUsedFor =>
      'O e-mail é usado para assinar pedidos com segurança e não é enviado para os servidores da Suunto.';

  @override
  String get suuntoUsesSmsVerificationSame =>
      'A Suunto usa verificação por SMS (como a app Suunto). Será enviado um PIN único para o teu telemóvel. As credenciais são guardadas encriptadas apenas no dispositivo.';

  @override
  String get tellUsAboutYourRace =>
      'Fala-nos da tua prova e do teu horário. A Fjelia cria o teu plano já e calcula o teu nível a partir das atividades anteriores (Garmin, Suunto, Polar, COROS, Apple Saúde) quando forem descarregadas.';

  @override
  String get noAccountConnectedSoFjelia =>
      'Nenhuma conta ligada, por isso a Fjelia não tem histórico com que aprender. Liga a Garmin, Suunto, Polar, COROS ou o Apple Saúde e o teu treino real passa a decidir.';

  @override
  String get yourPastActivitiesAreStill =>
      'As tuas atividades anteriores ainda estão a ser importadas. Podes criar já o plano — é afinado automaticamente quando a importação terminar.';

  @override
  String get buildingYourPlan => 'A criar o teu plano…';

  @override
  String get saveContinue => 'Guardar e continuar';

  @override
  String get addYourMainPriorityA =>
      'Adiciona a tua prova principal (prioridade A). O plano é periodizado para ela: base, construção, pico e afinação. Sem objetivo de prova ainda não é gerado nenhum plano.';

  @override
  String get noMeasurementsYet => 'Ainda sem medições';

  @override
  String get date => 'Data';

  @override
  String deepSleepIsBelowOptimal(Object round) {
    return 'O sono profundo está abaixo do ideal ($round%). Evita álcool e refeições pesadas 3 h antes de deitar.';
  }

  @override
  String get finishWithSetsOpen => 'Terminar com séries em aberto?';

  @override
  String get completeThePlannedWorkout => 'Concluir o treino planeado?';

  @override
  String get marksThePlannedSessionAs =>
      'Marca o treino planeado como feito com este treino.';

  @override
  String get discardThisWorkout => 'Descartar este treino?';

  @override
  String get removesTheWorkoutAndEvery =>
      'Remove o treino e todas as séries registadas nele.';

  @override
  String assistanceName(Object name) {
    return 'Assistência ($name)';
  }

  @override
  String get enterSecondsOrMSs => 'Introduz segundos ou m:ss.';

  @override
  String get enterTheLoadAsA => 'Introduz a carga como número.';

  @override
  String get loadCannotBeNegative => 'A carga não pode ser negativa.';

  @override
  String get enterTheEffortValue => 'Introduz o valor de esforço.';

  @override
  String get nameTheExercise => 'Dá um nome ao exercício.';

  @override
  String get atLeastOneImplement => 'Pelo menos um acessório.';

  @override
  String get anIncrementMustBePositive => 'O incremento tem de ser positivo.';

  @override
  String get enterAPositiveStep => 'Introduz um incremento positivo.';

  @override
  String get repsInReserve => 'Reps em reserva';

  @override
  String get loadPerImplement => 'Carga por acessório';

  @override
  String get restAfterThisSet => 'Descanso depois desta série';

  @override
  String get enterHowLongTheSet => 'Introduz quanto tempo durou a série.';

  @override
  String get repsDonePerSide => 'Reps feitas por lado';

  @override
  String plannedRepminRepmax(Object repMin, Object repMax) {
    return 'Planeado $repMin–$repMax';
  }

  @override
  String get restTakenBeforeTheNext => 'Descanso antes da série seguinte';

  @override
  String get equipment => 'Equipamento';

  @override
  String get implementsUsedTogether => 'Acessórios usados em conjunto';

  @override
  String get smallestLoadStepOptional => 'Menor incremento de carga (opcional)';

  @override
  String get theSmallestChangeYourPlates =>
      'A menor alteração que os teus discos, halteres ou máquina permitem, lembrada para este equipamento.';

  @override
  String get loadStep => 'Incremento de carga';

  @override
  String get finishWithIncompleteData => 'Terminar com dados incompletos?';

  @override
  String get leaveWithoutSaving => 'Sair sem guardar?';

  @override
  String get theLastChangeCouldNot =>
      'Não foi possível guardar a última alteração.';

  @override
  String get comparedWithAPlanChosen =>
      'Comparado com um plano escolhido depois do treino. Os valores planeados são sugestões, não resultados.';

  @override
  String get lastSet => 'Última série';

  @override
  String get templateName => 'Nome do modelo';

  @override
  String get betweenExercises => 'Entre exercícios';

  @override
  String get betweenRounds => 'Entre voltas';

  @override
  String get discardChanges => 'Descartar alterações?';

  @override
  String get yourEditsToThisWorkout =>
      'As tuas alterações a este treino não foram guardadas.';

  @override
  String get estimatedDuration => 'Duração estimada';

  @override
  String get workingSets => 'Séries de trabalho';

  @override
  String get estimatedExternalVolume => 'Volume externo estimado';

  @override
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion) {
    return 'Carga aumentada de $unit para $unit2 depois da tua avaliação (regra v$ruleVersion).';
  }

  @override
  String get thePlannedWorkoutHasNo =>
      'O treino planeado não tem exercícios para registar.';

  @override
  String get completedSets => 'Séries concluídas';

  @override
  String get knownExternalVolume => 'Volume externo conhecido';

  @override
  String get updateStrengthSessions2 => 'Atualizar treinos de força?';

  @override
  String get upcomingSessionsArePlannedAgain =>
      'Os próximos treinos são planeados de novo a partir de hoje: a força segue os teus objetivos de prova em cada dia de força, com treinos variados. Os treinos concluídos e saltados mantêm-se; os exercícios que alteraste num próximo treino de força são substituídos.';

  @override
  String get thisSessionUsesAnEarlier =>
      'Este treino usa um modelo de força anterior. Os planos atualizados variam a força por fase e objetivo de prova e usam todos os dias de força.';

  @override
  String get estimated1rmUsesEpleyAnd =>
      'O 1RM estimado usa Epley e Brzycki em séries de trabalho concluídas de 1–10 reps com carga conhecida, mostrado como o intervalo entre ambos. É uma estimativa, não um máximo testado.';

  @override
  String get localWeather => 'Meteorologia local';

  @override
  String get today => 'Hoje';

  @override
  String get low => 'Baixo';

  @override
  String get moderate => 'Moderado';

  @override
  String get overcast => 'Encoberto';

  @override
  String get partlyCloudy => 'Parcialmente nublado';

  @override
  String collapseName(Object name) {
    return 'Recolher $name';
  }

  @override
  String get variableLoads => 'Cargas variáveis';

  @override
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  ) {
    return 'Regra v$strengthProgressionRuleVersion: os últimos $strengthProgressionMinSessions treinos comparáveis, com cada série feita no topo do objetivo de repetições, com esforço registado e não mais duro do que o previsto. $reason';
  }

  @override
  String get stepOnYourScaleBefore => 'Sobe para a balança antes de procurar';

  @override
  String get scanning => 'A procurar…';

  @override
  String get pair => 'Emparelhar';

  @override
  String get selectYourAktiiaPWristband =>
      'Seleciona a tua pulseira AKTIIA P…. Coloca-a no carregador para a ativar se não aparecer.';

  @override
  String get measurementInterruptedWhileTheApp =>
      'A medição foi interrompida enquanto a app estava em segundo plano. Repete-a.';

  @override
  String get noRecentRrDataWith =>
      'Sem dados RR recentes com bom contacto. Verifica a cinta e repete a medição.';

  @override
  String get settlingStayStill => 'A estabilizar · fica quieto';

  @override
  String get deleteSpotHrvMeasurement => 'Eliminar medição de HRV pontual?';

  @override
  String get thisRemovesTheRecordingAnd =>
      'Isto remove a gravação e os intervalos RR em bruto.';

  @override
  String get appleHealthStoppedAnsweringSo =>
      'O Apple Saúde deixou de responder, por isso a Fjelia desligou-o e já não lê nem escreve dados de saúde.\n\nVolta a autorizar a Fjelia em Definições → Saúde → Acesso a dados e dispositivos → Fjelia e depois volta a ligar o Apple Saúde.';

  @override
  String get thisRemovesTheSelectedGrip =>
      'Isto remove a medição de preensão selecionada.';

  @override
  String get hideReminderDiagnostics => 'Ocultar diagnóstico dos lembretes';

  @override
  String get loading => 'A carregar…';

  @override
  String get touchTheChartForDetails => 'Toca no gráfico para ver detalhes';

  @override
  String get indoor => 'Interior';

  @override
  String get road => 'Estrada';

  @override
  String get technical => 'Técnico';

  @override
  String get snow => 'Neve';

  @override
  String get pool => 'Piscina';

  @override
  String get openWater => 'Águas abertas';

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
    return 'Leva cerca de $gels géis ($gelCarbs g de hidratos cada) + $bottles × garrafas de $bottleMl ml. $drinkCarbs g de hidratos vêm da bebida.';
  }

  @override
  String get intakeNotRecorded => 'Ingestão não registada';

  @override
  String get loggingDeclinedIntakeUnknown =>
      'Registo recusado — ingestão desconhecida';

  @override
  String get confirmedNoIntake => 'Confirmado: sem ingestão';

  @override
  String get draft => 'Rascunho · ';

  @override
  String get actualIntakePerServing => 'Ingestão real · por dose';

  @override
  String get minuteIntoWorkoutDuringOnly =>
      'Minuto do treino (só durante, opcional)';

  @override
  String get sodiumMgServingNotSalt => 'Sódio mg / dose (não sal)';

  @override
  String get comfortable => 'Confortável';

  @override
  String get mildSymptoms => 'Sintomas ligeiros';

  @override
  String get moderateSymptoms => 'Sintomas moderados';

  @override
  String get severeSymptoms => 'Sintomas graves';

  @override
  String get personalNutritionSettings => 'Definições pessoais de nutrição';

  @override
  String get practisedCarbohydrateToleranceGH =>
      'Tolerância treinada a hidratos g/h (até 120)';

  @override
  String get exportTheMonthlyReportAs =>
      'Exporta o relatório mensal em PDF na app Hilo e escolhe-o aqui. Só as medições são importadas; o nome, o e-mail e os dados corporais do relatório são ignorados.';

  @override
  String get nothingNewAllReadingsWere =>
      'Nada de novo: todas as medições já estavam guardadas.';

  @override
  String get historyImportIncomplete => 'Importação do histórico incompleta';

  @override
  String get youCanKeepUsingFjelia =>
      'Podes continuar a usar a Fjelia, mas mantém-na aberta: o iOS pausa a importação quando a app está em segundo plano e retoma-a da próxima vez que abrires a Fjelia. O teu plano é calibrado quando a importação terminar.';

  @override
  String get addYourBirthYearIn =>
      'Adiciona o teu ano de nascimento em Definições → Perfil para veres a estimativa.';

  @override
  String get fitnessAge => 'Idade física';

  @override
  String get estLifespan => 'Esperança de vida est.';

  @override
  String get delta => 'Diferença';

  @override
  String couldNotOpenKey(Object key) {
    return 'Não foi possível abrir $key';
  }

  @override
  String get appleIntelligenceIsNotAvailable =>
      'O Apple Intelligence não está disponível neste dispositivo. Usa o Free AI ou escolhe outro fornecedor.';

  @override
  String get personalisedMorningLunchAfternoonEvening =>
      'Resumo personalizado de manhã/almoço/tarde/noite';

  @override
  String get enterASubject => 'Introduz um assunto.';

  @override
  String get message => 'Mensagem';

  @override
  String get enterAMessageOfAt =>
      'Introduz uma mensagem com pelo menos 10 carateres.';

  @override
  String get garminConnect => 'Garmin Connect';

  @override
  String get hiloBloodPressure => 'Hilo (tensão arterial)';

  @override
  String get renphoBodyScale => 'Renpho (balança)';

  @override
  String get hiloPodCuff => 'Hilo pod / braçadeira';

  @override
  String disconnectLabel(Object label) {
    return 'Desligar $label?';
  }

  @override
  String get yourSavedMeasurementsWillRemain =>
      'As tuas medições guardadas ficam neste dispositivo.';

  @override
  String get notEnoughRecentHeartRate =>
      'Dados recentes de frequência cardíaca insuficientes para ajustar as zonas.';

  @override
  String get aerobicBase => 'Base aeróbia';

  @override
  String get tempo => 'Ritmo';

  @override
  String get lactateThreshold => 'Limiar de lactato';

  @override
  String get birthYearHeightWaist => 'Ano de nascimento, altura, cintura';

  @override
  String get enterAValidValue => 'Introduz um valor válido';

  @override
  String get birthYear => 'Ano de nascimento';

  @override
  String get height => 'Altura';

  @override
  String get waist => 'Cintura';

  @override
  String get yearsSinceQuit => 'Anos desde que deixou';

  @override
  String get cigarettesPerDay => 'Cigarros por dia';

  @override
  String get standardDrinksPerMonth => 'Bebidas padrão por mês';

  @override
  String get enterAValidNumber => 'Introduz um número válido';

  @override
  String get enterARaceName => 'Introduz o nome da prova';

  @override
  String get useHMmOrH =>
      'Usa h:mm ou h:mm:ss, um tempo que consigas mesmo fazer';

  @override
  String get flexibleThePlanMayDrop =>
      'Flexível: o plano pode retirar este evento se coincidir com um mais importante.';

  @override
  String get selectARaceDate => 'Seleciona a data da prova';

  @override
  String thatIsTenTimesOr(Object likely) {
    return 'Isso é dez vezes (ou um décimo) dos habituais $likely km. Usar $likely km?';
  }

  @override
  String get addGoal => 'Adicionar objetivo';

  @override
  String get restoreFailed => 'O restauro falhou';

  @override
  String get replaceLocalData => 'Substituir os dados locais?';

  @override
  String get restoringThisBackupReplacesAll =>
      'Restaurar esta cópia substitui todos os registos locais de saúde e treino. As credenciais de início de sessão existentes mantêm-se.';

  @override
  String get openingBackupZip => 'A abrir ZIP da cópia de segurança';

  @override
  String get addAFutureRaceGoal =>
      'Adiciona primeiro um objetivo de prova futuro.';

  @override
  String get deleteAllWorkouts2 => 'Eliminar todos os treinos?';

  @override
  String get thisDeletesPlannedWorkoutsOn =>
      'Isto elimina os treinos planeados neste telemóvel e na plataforma do relógio ligada. As atividades concluídas mantêm-se.';

  @override
  String get regenerateWorkouts2 => 'Gerar treinos novamente?';

  @override
  String get noRaceGoalsYetAdd =>
      'Ainda sem objetivos de prova. Adiciona um ou sincroniza a partir da Garmin.';

  @override
  String get deleteRaceGoal => 'Eliminar objetivo de prova?';

  @override
  String deletingFailedFailure(Object failure) {
    return 'A eliminação falhou: $failure';
  }

  @override
  String allPlannedWorkoutsDeletedRemoved(Object removed) {
    return 'Todos os treinos planeados foram eliminados. Removidos das tuas plataformas: $removed.';
  }

  @override
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  ) {
    return 'A usar a localização atual: $toStringAsFixed, $toStringAsFixed2';
  }

  @override
  String get typeSleep => 'Sono';

  @override
  String get typeBloodPressure => 'Tensão arterial';

  @override
  String get addHiloBpReportPdf => 'Adicionar relatório de tensão Hilo (PDF)';

  @override
  String get hiloCuffBle => 'Braçadeira Hilo (BLE)';

  @override
  String get typeSpo2 => 'SpO₂ / oxímetro';

  @override
  String get typeWeightScale => 'Balança';

  @override
  String get polarH10HrvMeasurement => 'Medição de HRV Polar H10';

  @override
  String samplingWouldStartMinutes(Object minutes) {
    return 'A medição começaria cerca de $minutes min depois do fim do treino.';
  }

  @override
  String samplingStartedMinutes(Object minutes) {
    return 'A medição começou $minutes min depois do fim do treino.';
  }

  @override
  String get unknown => 'Desconhecido';

  @override
  String get before => 'Antes';

  @override
  String get during => 'Durante';

  @override
  String get after => 'Depois';

  @override
  String get enumWarmUp => 'Aquecimento';

  @override
  String get enumWorking => 'Trabalho';

  @override
  String get enumBackOff => 'Back-off';

  @override
  String get enumTechnique => 'Técnica';

  @override
  String get enumExternalLoad => 'Carga externa';

  @override
  String get enumBandResistance => 'Elástico / resistência';

  @override
  String get enumTotalLoad => 'Carga total';

  @override
  String get enumPerImplement => 'Por acessório';

  @override
  String get enumOneImplement => 'Um acessório';

  @override
  String get enumBothSides => 'Ambos os lados';

  @override
  String get enumAlternatingTotalReps => 'Alternado, reps totais';

  @override
  String get enumPartial => 'Parcial';

  @override
  String get enumFailed => 'Falhada';

  @override
  String get enumStraightSets => 'Séries simples';

  @override
  String get enumSuperset => 'Supersérie';

  @override
  String get enumCircuit => 'Circuito';

  @override
  String get enumRir => 'RIR';

  @override
  String get enumRpe110 => 'RPE 1–10';

  @override
  String get enumBeforeTraining => 'Antes do treino';

  @override
  String get enumAfterTraining => 'Depois do treino';

  @override
  String get enumResting => 'Em repouso';

  @override
  String get enumSeated => 'Sentado';

  @override
  String get enumLyingDown => 'Deitado';

  @override
  String get duringRoutineGelsAreNot =>
      'Durante: neste treino curto/leve não são precisos géis. Bebe conforme a sede.';

  @override
  String get duringSpreadCarbohydrateAndDrinks =>
      'Durante: distribui os hidratos e a bebida por tomas pequenas e regulares. Conta os hidratos da bebida no mesmo total que os géis e a comida.';

  @override
  String get fluidIsAnEditableStarting =>
      'O líquido é uma estimativa inicial editável, não uma quota. Guia-te pela sede, pela ingestão treinada e pelas perdas de suor medidas; não forces água a mais.';

  @override
  String get afterHaveCarbohydrateAndA =>
      'Depois: come hidratos e uma refeição com proteína. Dá prioridade a reabastecer e reidratar quando houver outro treino em breve.';

  @override
  String get swimmingPlaceALabelledBottle =>
      'Natação: deixa uma garrafa identificada no cais da piscina e usa as pausas entre séries para beber ou comer. As condições da piscina podem diferir da meteorologia exterior.';

  @override
  String get runningCarryAccessibleGelsFlasks =>
      'Corrida: leva géis/frascos à mão ou planeia comer nos abastecimentos; treina os mesmos produtos e horários antes da prova.';

  @override
  String get servingSizesAndToleranceMust =>
      'As doses e a tolerância têm de ser positivas.';

  @override
  String get enterFiniteNonNegativeMeasurements =>
      'Introduz medições finitas e não negativas.';

  @override
  String get targetsMustBeFiniteAnd =>
      'Os objetivos têm de ser finitos e não negativos.';

  @override
  String get conditionsMustBeFiniteOr =>
      'As condições têm de ser finitas ou desconhecidas.';

  @override
  String get humidityMustBeBetween0 =>
      'A humidade tem de estar entre 0 e 100%.';

  @override
  String get noIntakeCannotIncludeFood =>
      '“Sem ingestão” não pode incluir comida nem bebidas.';

  @override
  String get addAnItemOrConfirm =>
      'Adiciona um item ou confirma que não consumiste nada.';

  @override
  String get eachIntakeNeedsAProduct =>
      'Cada ingestão precisa de um produto e de um momento válido.';

  @override
  String get quantityMustBePositive => 'A quantidade tem de ser positiva.';

  @override
  String get thisActivityNoLongerExists => 'Esta atividade já não existe.';

  @override
  String get practisedCarbohydrateToleranceMustNot =>
      'A tolerância treinada a hidratos não pode exceder 120 g/h.';

  @override
  String get measuredSweatRateMustBe =>
      'A taxa de suor medida tem de ser positiva ou ficar desconhecida.';

  @override
  String get increasePractisedToleranceInNutrition =>
      'Aumenta a tolerância treinada nas definições de nutrição antes de escolheres um objetivo mais alto.';

  @override
  String get fluidTargetExceedsYourMeasured =>
      'O objetivo de líquidos excede a tua taxa de suor medida. Revê a medição ou o objetivo.';

  @override
  String get elapsedWorkoutTimeMustBe =>
      'O tempo decorrido do treino tem de ser positivo ou ficar em branco.';

  @override
  String get intakeAmountsMustBeFinite =>
      'As quantidades ingeridas têm de ser finitas e não negativas.';

  @override
  String get selectedStrategyUnavailableChooseAnother =>
      'Estratégia selecionada indisponível. Escolhe outra estratégia ou nenhuma comparação.';

  @override
  String get recordYourWorkoutNutrition => 'Regista a nutrição do treino';

  @override
  String get addTheFoodAndFluids =>
      'Adiciona ao histórico de atividades a comida e os líquidos que realmente consumiste.';

  @override
  String get logIntake => 'Registar ingestão';

  @override
  String nutritionReminderTitle(String name) {
    return 'Nova atividade: $name';
  }

  @override
  String get nutritionReminderBody => 'Adiciona o que comeste e bebeste.';

  @override
  String get nutritionReminderHrvHint =>
      'A tua HRV pós-treino ainda não foi medida.';

  @override
  String get in30Minutes => 'Daqui a 30 minutos';

  @override
  String get loadSuggestionsCoverStraightSets =>
      'As sugestões de carga só abrangem séries simples com repetições.';

  @override
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  ) {
    return 'São necessários $strengthProgressionMinSessions treinos registados deste exercício.';
  }

  @override
  String get recentHistoryIsTooOld =>
      'O histórico recente é demasiado antigo para uma sugestão.';

  @override
  String get theLastSessionDidNot =>
      'O último treino não usou uma única carga conhecida.';

  @override
  String get theLoadChangedBetweenThe =>
      'A carga mudou entre os treinos recentes.';

  @override
  String get notEverySetReachedThe =>
      'Nem todas as séries chegaram ao topo do objetivo de repetições.';

  @override
  String get recordEffortRirOrRpe =>
      'Regista o esforço (RIR ou RPE) na última série para receberes sugestões.';

  @override
  String get recentSetsWereHarderThan =>
      'As séries recentes foram mais duras do que o previsto.';

  @override
  String get thisWorkoutAlreadyHasIts =>
      'Este treino já tem a sua própria carga; mantém-se como definida.';

  @override
  String get yourRecentSetsMetThe =>
      'As tuas séries recentes cumpriram a regra de progressão. Define o menor incremento de carga para este equipamento para avaliar uma carga.';

  @override
  String get thisWorkoutNoLongerExists => 'Este treino já não existe.';

  @override
  String thisStrengthPlanCannotBe(Object message) {
    return 'Não é possível ler este plano de força ($message).';
  }

  @override
  String get thisStrengthPlanCannotBe2 =>
      'Não é possível ler este plano de força.';

  @override
  String get addAtLeastOneExercise => 'Adiciona pelo menos um exercício.';

  @override
  String get thisWorkoutWasChangedElsewhere =>
      'Este treino foi alterado noutro sítio. As tuas alterações mantêm-se; volta a carregar para veres a versão mais recente.';

  @override
  String get thePlanThisWorkoutIs =>
      'Não é possível ler o plano com que este treino é comparado.';

  @override
  String get thisLogWasChangedElsewhere =>
      'Este registo foi alterado noutro sítio. As tuas entradas mantêm-se; volta a carregar para veres a versão mais recente.';

  @override
  String get thisZipIsNotA =>
      'Este ZIP não é uma cópia de segurança da Fjelia suportada.';

  @override
  String get theBackupDatabaseIsDamaged =>
      'A base de dados da cópia de segurança está danificada.';

  @override
  String get invalidBackupData => 'Dados da cópia de segurança inválidos.';

  @override
  String get backupTablesDoNotMatch =>
      'As tabelas da cópia de segurança não coincidem.';

  @override
  String get invalidBackupColumns => 'Colunas da cópia de segurança inválidas.';

  @override
  String get migratingOriginalAppBackup =>
      'A migrar a cópia de segurança da app original';

  @override
  String get theOriginalBackupIsMissing =>
      'Faltam tabelas obrigatórias na cópia de segurança original.';

  @override
  String get backupFormatOrDatabaseVersion =>
      'O formato da cópia ou a versão da base de dados não coincide.';

  @override
  String get restoringRecords => 'A restaurar registos';

  @override
  String get restoringSettings => 'A restaurar definições';

  @override
  String get restoreComplete => 'Restauro concluído';

  @override
  String get effortMustBeANumber => 'O esforço tem de ser um número.';

  @override
  String get theDurationEstimateMustBe =>
      'A duração estimada tem de ser positiva.';

  @override
  String get restCannotBeNegative => 'O descanso não pode ser negativo.';

  @override
  String get enterTheRepetitionsDoneThe =>
      'Introduz as repetições feitas; o plano tem um intervalo.';

  @override
  String get enterTheLoadThePlan =>
      'Introduz a carga; o plano não tem nenhuma.';

  @override
  String get enterTheResistanceThePlan =>
      'Introduz a resistência; o plano não tem nenhuma.';

  @override
  String get poorSensorContact => 'Mau contacto do sensor';

  @override
  String get moreThan25FromLocal => 'Mais de 25% da mediana local';

  @override
  String get workoutNutrition => 'Nutrição do treino';

  @override
  String get postWorkoutFoodAndFluid =>
      'Lembrete de registo de comida e líquidos pós-treino';

  @override
  String get postTrainingHrvMeasurementReminder =>
      'Lembrete de medição de HRV pós-treino';

  @override
  String get rirRunsFrom0To => 'O RIR vai de 0 a 10+.';

  @override
  String get rpeRunsFrom1To => 'O RPE vai de 1 a 10.';

  @override
  String get repetitionsCannotBeNegative =>
      'As repetições não podem ser negativas.';

  @override
  String get timedWorkMustBeLonger =>
      'O trabalho por tempo tem de durar mais de zero segundos.';

  @override
  String get chooseRepetitionsOrTimedWork =>
      'Escolhe repetições ou trabalho por tempo, não ambos.';

  @override
  String get loadMustBeAFinite =>
      'A carga tem de ser um número finito e não negativo.';

  @override
  String get durationCannotBeNegative => 'A duração não pode ser negativa.';

  @override
  String get hrTimeline => 'Evolução da FC';

  @override
  String get dayTrainingLoad => 'Carga de treino do dia';

  @override
  String get weekdayComparison => 'Comparação por dia da semana';

  @override
  String get weeklyTrainingLoad => 'Carga de treino semanal';

  @override
  String get zonePolarization => 'Polarização das zonas';

  @override
  String get elevationOverview => 'Resumo do desnível';

  @override
  String get trainingMonitor => 'Monitor de treino';

  @override
  String get formAtlCtlTsb => 'Forma ATL / CTL / TSB';

  @override
  String get trainingPlanProgress => 'Progresso do plano de treino';

  @override
  String get rhrSleep => 'FC em repouso no sono';

  @override
  String get hrvSleep => 'HRV no sono';

  @override
  String get spo2Sleep => 'SpO₂ no sono';

  @override
  String get respRate => 'Freq. respiratória';

  @override
  String get stress => 'Stress';

  @override
  String get skinTemp => 'Temp. da pele';

  @override
  String get steps => 'Passos';

  @override
  String get tonightsSleep => 'Sono desta noite';

  @override
  String get activityLog => 'Registo de atividades';

  @override
  String get activityLog2 => 'Registo de atividades';

  @override
  String get history2 => 'HISTÓRICO';

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
  String get heatAcclimation2 => 'ACLIMATAÇÃO AO CALOR';

  @override
  String score(Object score) {
    return '$score%';
  }

  @override
  String get elevation => 'DESNÍVEL';

  @override
  String get t12WeekHistory => 'HISTÓRICO DE 12 SEMANAS';

  @override
  String get zonePolarization2 => 'POLARIZAÇÃO DAS ZONAS';

  @override
  String get t5WeekHistory => 'HISTÓRICO DE 5 SEMANAS';

  @override
  String get easy => 'LEVE %';

  @override
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded) {
    return '$withZones de $recorded atividades com dados de zonas de FC';
  }

  @override
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples) {
    return '$fromSamples reconstruídas a partir de amostras de FC registadas';
  }

  @override
  String get easyZ12ModerateZ3 => 'Leve: Z1–2 · Moderado: Z3 · Intenso: Z4–5';

  @override
  String get activitiesWithoutHrZoneData =>
      'As atividades sem dados de zonas de FC ficam de fora das percentagens.';

  @override
  String avgAverageUnit(Object average, Object unit) {
    return 'MÉD.  $average $unit';
  }

  @override
  String get weekdayComparison2 => 'COMPARAÇÃO POR DIA DA SEMANA';

  @override
  String get trainingPlanProgress2 => 'PROGRESSO DO PLANO DE TREINO';

  @override
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  ) {
    return 'Semana $currentWeek / $durationInWeeks';
  }

  @override
  String get t30MinTimeTrialLt2 => 'CONTRARRELÓGIO DE 30 MIN — LT2';

  @override
  String get run30MinutesAtThe =>
      'Corre 30 minutos ao esforço mais alto que consegues manter — controlado, sem sprintar. Entra no esforço aos poucos; não comeces demasiado rápido. O ritmo e a FC médios dos últimos 20 minutos são o teu LT2.';

  @override
  String get recordAsANormalOutdoor =>
      'Regista como uma corrida normal ao ar livre. Inicia o relógio, anota a hora e corre 30 min ao esforço de prova.';

  @override
  String get t50MinTotalFlatCourse =>
      '~50 min no total · percurso plano · não depois de treino duro';

  @override
  String get doNotStartTooFast =>
      'Não comeces demasiado rápido. Procura parciais iguais.';

  @override
  String get theAppAveragesHrAnd =>
      'A app faz a média da FC e do ritmo nos últimos 20 minutos do contrarrelógio, depois do aquecimento e dos primeiros 10 minutos. Seleciona a atividade registada em Calcular.';

  @override
  String get lt2Pace => 'RITMO LT2';

  @override
  String get activityRunningEnoughTimeFor =>
      'Atividade (corrida, tempo suficiente para aquecimento + 30 min, com FC)';

  @override
  String get selectTheTtActivity => 'Seleciona a atividade do contrarrelógio';

  @override
  String nameStartdate(Object name, Object startDate) {
    return '$name · $startDate';
  }

  @override
  String get warmUpBeforeTt => 'Aquecimento antes do contrarrelógio';

  @override
  String roundMin(Object round) {
    return '$round min';
  }

  @override
  String get clearResults => 'Limpar resultados';

  @override
  String get heartRate2 => 'FREQUÊNCIA CARDÍACA';

  @override
  String get paceSecKmLowerIs => 'RITMO (s/km — menos é mais rápido)';

  @override
  String get thresholdsFitnessTests => 'Limiares e testes de condição física';

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
  String get calculateFromAnActivity => 'Calcular a partir de uma atividade';

  @override
  String get setFtp => 'Definir FTP';

  @override
  String get ftpWatts => 'FTP (watts)';

  @override
  String get ftpCyclingThresholdPower => 'FTP — POTÊNCIA DE LIMIAR NO CICLISMO';

  @override
  String get ftpHistory => 'HISTÓRICO DE FTP';

  @override
  String get updateFromActivity => 'ATUALIZAR A PARTIR DE ATIVIDADE';

  @override
  String get tapAnActivityFtpBest =>
      'Toca numa atividade — FTP = melhor potência de 20 min × 0,95';

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
      'Sem saídas com 20 minutos de dados de potência contínuos.';

  @override
  String get enterFtpManually => 'Introduzir FTP manualmente';

  @override
  String get selectTheTestActivity => 'Seleciona a atividade de teste';

  @override
  String get formAtlCtlTsb2 => 'FORMA · ATL / CTL / TSB';

  @override
  String get closeTrainingFormFullscreen =>
      'Fechar forma de treino em ecrã inteiro';

  @override
  String get expandTrainingForm => 'Expandir forma de treino';

  @override
  String get calculatedFromTheFirstAvailable =>
      'Calculado a partir do primeiro registo de carga disponível. Os dias sem carga registada contam como zero; o treino anterior é desconhecido.';

  @override
  String get trainingMonitor2 => 'MONITOR DE TREINO';

  @override
  String get pfitzingerZones => 'ZONAS PFITZINGER';

  @override
  String get cyclingPowerZones => 'ZONAS DE POTÊNCIA NO CICLISMO';

  @override
  String znumber(Object number) {
    return 'Z$number';
  }

  @override
  String paceHrDescription(Object pace, Object hr, Object description) {
    return '$pace · $hr\n$description';
  }

  @override
  String get weeklyTrainingLoad2 => 'CARGA DE TREINO SEMANAL';

  @override
  String get prevWeek => 'SEMANA ANT.';

  @override
  String get bySport => 'POR DESPORTO';

  @override
  String get noActivitiesThisWeek => 'Sem atividades esta semana';

  @override
  String garminWorkoutScheduleddate(Object scheduledDate) {
    return 'Treino Garmin · $scheduledDate';
  }

  @override
  String get yourNote => 'A tua nota';

  @override
  String get askAiCoach => 'Perguntar ao treinador IA';

  @override
  String get aiSettings => 'Definições de IA';

  @override
  String get askYourCoach => 'Pergunta ao teu treinador…';

  @override
  String get sendMessage => 'Enviar mensagem';

  @override
  String get sendFeedbackOrReportA => 'Enviar comentários ou comunicar um erro';

  @override
  String get addMeasurement2 => 'Adicionar medição';

  @override
  String get syncLabel2 => 'Sincronizar';

  @override
  String get syncToday => 'Sincronizar hoje';

  @override
  String get fullSync1Year => 'Sincronização completa · 1 ano';

  @override
  String get fullSyncComplete => 'Sincronização completa · concluída';

  @override
  String get syncingYourData => 'A sincronizar os teus dados…';

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
    return '$weight kg · Gordura $bodyFat% · Músculo $muscleMass kg';
  }

  @override
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase) {
    return '$title, $sport, $toLowerCase';
  }

  @override
  String get weatherUnavailableTapToRetry =>
      'Meteorologia indisponível · Toca para tentar novamente';

  @override
  String get weatherSetYourLocation =>
      'Meteorologia · Define a tua localização';

  @override
  String get t7DayForecast => 'PREVISÃO A 7 DIAS';

  @override
  String get minMax => 'mín/máx';

  @override
  String get rainMm2 => 'chuva mm';

  @override
  String get uvMax => 'UV máx';

  @override
  String get kmH => 'km/h';

  @override
  String alt(Object alt) {
    return '→ $alt';
  }

  @override
  String raceGoalsLength(Object length) {
    return 'Objetivos de prova · $length';
  }

  @override
  String gWk(Object g) {
    return '$g sem';
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
    return '+ mais $length dias';
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
  String get plannedCompletedSkipped => '○ Planeado   ● Concluído   ✕ Saltado';

  @override
  String get heartRate3 => 'Frequência cardíaca';

  @override
  String get watts => 'Watts';

  @override
  String theStepsAddUpTo(Object total, Object plannedDurationMin) {
    return 'Os passos somam $total; o plano conta $plannedDurationMin min.';
  }

  @override
  String get typicalSplitForThisKind =>
      'Divisão típica para este tipo de treino; não há passos para a calcular.';

  @override
  String labelGetsEachExerciseWith(Object label) {
    return '$label recebe cada exercício com as suas séries, reps e cargas. Os intervalos de reps, o esforço e a cadência ficam na Fjelia.';
  }

  @override
  String get markAsRest => 'Marcar como descanso';

  @override
  String get changeSport => 'Mudar de desporto';

  @override
  String get replacementSport => 'Desporto de substituição';

  @override
  String get replacementLoadNote =>
      'A duração, as zonas de frequência cardíaca previstas e o objetivo de carga mantêm-se. Os objetivos de ritmo e potência são adaptados ao novo desporto.';

  @override
  String replacementCalendarNote(String platforms) {
    return 'O treino original será removido destes calendários de treino: $platforms.';
  }

  @override
  String get applySportChange => 'Planear treino de substituição';

  @override
  String get restoreWorkout => 'Restaurar treino';

  @override
  String get skipThisWorkout => 'Saltar este treino?';

  @override
  String get previousWeek => 'Semana anterior';

  @override
  String get backToThisWeek => 'Voltar a esta semana';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get nextWeek => 'Semana seguinte';

  @override
  String get today2 => 'HOJE';

  @override
  String get route => 'PERCURSO';

  @override
  String get feedback => 'Comentários';

  @override
  String get plannedWorkout => 'Treino planeado';

  @override
  String get delete => 'Eliminar';

  @override
  String get chatAi => 'Chat IA';

  @override
  String get trainingLoad => 'Carga de treino';

  @override
  String get dayTrainingLoad2 => 'CARGA DE TREINO DO DIA';

  @override
  String get trimp => ' TRIMP';

  @override
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter) {
    return '$scoreBefore → $scoreAfter';
  }

  @override
  String get temperatureOverTime => 'EVOLUÇÃO DA TEMPERATURA';

  @override
  String roundh(Object round) {
    return '$round h';
  }

  @override
  String get timeInHrZones => 'Tempo nas zonas de FC';

  @override
  String get route2 => 'Percurso';

  @override
  String get start => 'Início';

  @override
  String get gpx => 'GPX';

  @override
  String touppercasesubstringBriefing(Object toUpperCase, Object substring) {
    return 'Resumo $toUpperCase$substring';
  }

  @override
  String get chatWithAiAboutThis => 'Falar com a IA sobre este resumo';

  @override
  String get whyThisRecommendation => 'Porquê esta recomendação?';

  @override
  String titleDateLabel(Object title, Object date, Object label) {
    return '$title, $date, $label';
  }

  @override
  String get previousDay => 'Dia anterior';

  @override
  String get nextDay => 'Dia seguinte';

  @override
  String get updating => 'A atualizar';

  @override
  String get resting => 'EM REPOUSO';

  @override
  String get noTimedReadings => 'Sem medições com hora';

  @override
  String get avg => 'MÉD.';

  @override
  String get peak => 'PICO';

  @override
  String tolocalRoundmin(Object toLocal, Object round) {
    return '$toLocal · $round min';
  }

  @override
  String avgheartrateBpmAvg(Object avgHeartRate) {
    return '$avgHeartRate bpm méd.';
  }

  @override
  String get timeWeightedAverageOverRecorded =>
      'Média ponderada pelo tempo nos períodos registados. As falhas sem medições ficam de fora.';

  @override
  String get previousHeartRatePeriod => 'Período de FC anterior';

  @override
  String get nextHeartRatePeriod => 'Período de FC seguinte';

  @override
  String get avgHr => 'FC média';

  @override
  String get restingHr => 'FC em repouso';

  @override
  String get both => 'Ambos';

  @override
  String averagelabelFixedMs(Object averageLabel, Object fixed) {
    return '$averageLabel $fixed ms';
  }

  @override
  String get measureWithPolarH10 => 'Medir com o Polar H10';

  @override
  String get ms => 'ms';

  @override
  String get noWorkoutInThisPeriod =>
      'Nenhum treino deste período tem um par comparável antes e depois.';

  @override
  String textEachWorkoutCountsOnce(Object text) {
    return '$text. Cada treino conta uma vez; isto descreve os teus pares, não os classifica.';
  }

  @override
  String get workoutFinished => 'Treino terminado?';

  @override
  String get yourWorkoutIsNotIn =>
      'O teu treino ainda não está na Fjelia. Se já terminou, diz quando, para o lembrete acompanhar o fim real. Caso contrário, aparece quando o relógio sincronizar.';

  @override
  String get workoutFinished2 => 'Treino terminado';

  @override
  String get theWorkoutMustStartAfter =>
      'O treino tem de começar depois da medição e terminar depois de ter começado, não no futuro.';

  @override
  String daysDAvg(Object days) {
    return 'MÉD. $days D';
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
  String get previousPeriod => 'Período anterior';

  @override
  String get nextPeriod => 'Período seguinte';

  @override
  String get overnightHrvReflectsRecoveryCompare =>
      'A HRV noturna reflete a recuperação. Compara as tuas medições com a tua própria referência ao longo do tempo.';

  @override
  String get moveThisWorkout => 'MOVER ESTE TREINO';

  @override
  String get pickDate => 'Escolher data';

  @override
  String movedFromMovedfrom(Object movedFrom) {
    return 'Movido de $movedFrom';
  }

  @override
  String get hrvAroundThisWorkout => 'HRV em torno deste treino';

  @override
  String get measureAfterTraining => 'Medir depois do treino';

  @override
  String get measureAgain => 'Medir novamente';

  @override
  String get explainWithAi => 'Explicar com IA';

  @override
  String beforeEndedPregapAheadOf(Object preGap) {
    return 'A medição antes terminou $preGap antes do início.';
  }

  @override
  String lengthFurtherMeasurementSAfter(Object length) {
    return '$length medição(ões) adicional(is) depois deste treino ficam guardadas como observações extra.';
  }

  @override
  String get noHrvMeasurementRecordedAround =>
      'Nenhuma medição de HRV registada em torno deste treino.';

  @override
  String get measureHrv => 'Medir HRV';

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
      'Uma descrição deste par, não uma pontuação do treino.';

  @override
  String notEnoughComparableWorkoutsYet(Object eligible, Object need) {
    return 'Ainda não há treinos comparáveis suficientes, $eligible de $need.';
  }

  @override
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need) {
    return 'Ainda não há treinos comparáveis suficientes ($eligible de $need).';
  }

  @override
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  ) {
    return 'Os teus $eligible treinos semelhantes · $toLocal–$toLocal2';
  }

  @override
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  ) {
    return 'Metade central $q1Ms a $q3Ms ms · mediana $medianMs ms · este treino $delta ms';
  }

  @override
  String rpeI(Object i) {
    return 'RPE $i';
  }

  @override
  String get easy2 => 'fácil';

  @override
  String get allOut => 'no máximo';

  @override
  String workoutProfileDescription(Object description) {
    return 'Perfil do treino: $description';
  }

  @override
  String get noActivitiesInThisPeriod => 'Sem atividades neste período';

  @override
  String get enableHeatAcclimationInTraining =>
      'Ativa a aclimatação ao calor nas definições de treino.';

  @override
  String get noElevationThisWeek => 'Sem desnível esta semana';

  @override
  String get noActivitiesSynced => 'Nenhuma atividade sincronizada';

  @override
  String get noHrZoneData => 'Sem dados de zonas de FC';

  @override
  String get easyJogGetHrElevated =>
      'Trote leve — subir a FC, soltar as pernas';

  @override
  String get fastestSustainablePaceLikeA =>
      'Ritmo mais rápido sustentável — como numa prova de 30 min';

  @override
  String get walkCardiacRecovery => 'Caminhar — recuperação cardíaca';

  @override
  String get selectTheTtActivityFirst =>
      'Seleciona primeiro a atividade do contrarrelógio.';

  @override
  String get calculating => 'A calcular…';

  @override
  String get calculateLt2 => 'Calcular LT2';

  @override
  String get enterFtpBetween30And => 'Introduz um FTP entre 30 e 1000 W.';

  @override
  String get aerobicThreshold => 'Limiar aeróbio';

  @override
  String get functionalThresholdPower => 'Potência funcional de limiar';

  @override
  String get estimated => 'Estimado';

  @override
  String get afterWarmingUpRunFive =>
      'Depois de aquecer, corre cinco minutos ao esforço mais rápido que consegues manter. Regista a corrida com dados de velocidade ou distância.';

  @override
  String get recordAtLeast40Minutes =>
      'Regista pelo menos 40 minutos de corrida regular a esforço constante. O teste compara a FC em cada metade para estimar a deriva aeróbia.';

  @override
  String get theFastestFiveMinuteWindow =>
      'A janela de cinco minutos mais rápida dá o teu ritmo VO2máx.';

  @override
  String get noResultYet => 'Ainda sem resultado';

  @override
  String get calculateVo2maxPace => 'Calcular ritmo VO2máx';

  @override
  String get calculateLt1 => 'Calcular LT1';

  @override
  String get loading2 => 'A carregar';

  @override
  String get unavailable => 'Indisponível';

  @override
  String get noTrainingHistory => 'Sem histórico de treino';

  @override
  String get fitnessCtl => 'Condição (CTL)';

  @override
  String get fatigueAtl => 'Fadiga (ATL)';

  @override
  String get formTsb => 'Forma (TSB)';

  @override
  String get noHistory => 'Sem histórico';

  @override
  String get fresh => 'Fresco';

  @override
  String get optimal => 'Ideal';

  @override
  String get neutral => 'Neutro';

  @override
  String get tired => 'Cansado';

  @override
  String get veryFatigued => 'Muito cansado';

  @override
  String get garminRunningVo2max => 'VO2máx de corrida Garmin';

  @override
  String get garminCyclingVo2max => 'VO2máx de ciclismo Garmin';

  @override
  String get aerobicThreshold2 => 'Limiar aeróbio';

  @override
  String driftDriftAt(Object drift, Object at) {
    return 'Deriva $drift% · $at';
  }

  @override
  String get activityHours => 'Horas de atividade';

  @override
  String get activityKm => 'Km de atividade';

  @override
  String get tap5MinuteMaxTest => 'Toca · teste máximo de 5 minutos';

  @override
  String get setFtpToCalculatePower =>
      'Define o FTP para calcular as zonas de potência';

  @override
  String get cyclingPowerZones2 => 'Zonas de potência no ciclismo';

  @override
  String get pfitzingerZones2 => 'Zonas Pfitzinger';

  @override
  String get completeAnLt2TestTo =>
      'Faz um teste LT2 para calcular as zonas de corrida.';

  @override
  String get setFtpToCalculatePower2 =>
      'Define o FTP para calcular as zonas de potência.';

  @override
  String get endurance => 'Resistência';

  @override
  String get threshold => 'Limiar';

  @override
  String get anaerobic => 'Anaeróbio';

  @override
  String get whatExplainsThisRise => 'O que explica esta subida?';

  @override
  String get whatExplainsThisDrop => 'O que explica esta descida';

  @override
  String get whatExplainsThisRise2 => 'O que explica esta subida';

  @override
  String get editsAreKeptInFjelia =>
      'As alterações ficam guardadas na Fjelia como cópia local para esta data. O treino na Garmin não é alterado.';

  @override
  String get howDoIExecuteThis => 'Como faço este treino?';

  @override
  String shareHealthContextWithName(Object name) {
    return 'Partilhar o contexto de saúde com $name?';
  }

  @override
  String get yourMessageAndAHealth =>
      'A tua mensagem e um resumo de saúde e treino serão enviados para este fornecedor de IA na nuvem. Os nomes e o GPS ficam fora do resumo.';

  @override
  String get couldNotGetAReply =>
      'Não foi possível obter resposta. Verifica as definições de IA e tenta novamente.';

  @override
  String get askAboutYourRecoveryTraining =>
      'Pergunta sobre a tua recuperação, treino ou o plano de hoje.';

  @override
  String get noSyncYet => 'Ainda sem sincronização';

  @override
  String lastSyncLastContext(Object last, Object context) {
    return 'Última sincronização: $last $context';
  }

  @override
  String get seasonWithTradeOffs => 'Época: com compromissos';

  @override
  String get seasonNeedsYourDecision => 'Época: precisa da tua decisão';

  @override
  String get seasonCannotBeCombined => 'Época: não é possível combinar';

  @override
  String get seasonProvisional => 'Época: provisória';

  @override
  String get season => 'Época';

  @override
  String get allGoalsFit => 'Todos os objetivos cabem.';

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
    return 'Feito · $doneBy';
  }

  @override
  String garminWorkoutWorkout(Object workout) {
    return 'Treino Garmin · $workout';
  }

  @override
  String get moveAnyway => 'Mover mesmo assim?';

  @override
  String get wattsNeedYourFtpSet =>
      'Os watts precisam do teu FTP: define-o em Carga, Limiares.';

  @override
  String get mainTargetInWattsFrom =>
      'Objetivo principal em watts a partir do teu FTP, com a FC como guia.';

  @override
  String get mainTargetHeartRateWatts =>
      'Objetivo principal na FC; os watts não são definidos no relógio.';

  @override
  String get taperPhase => 'Fase de afinação';

  @override
  String get recoverySession => 'Treino de recuperação';

  @override
  String get closeToYourEvent => 'Perto do teu evento';

  @override
  String get noWorkoutStructureAvailable =>
      'Sem estrutura de treino disponível.';

  @override
  String get aerobic => 'Aeróbio';

  @override
  String get pushAgainToUpdateYour =>
      'Envia novamente para atualizar o calendário do relógio.';

  @override
  String workoutSentToLabel(Object label) {
    return 'Treino enviado para $label';
  }

  @override
  String get updating2 => 'A atualizar…';

  @override
  String pushToLabel(Object label) {
    return 'Enviar para $label';
  }

  @override
  String shareExerciseListForLabel(Object label) {
    return 'Partilhar lista de exercícios para $label';
  }

  @override
  String shareWorkoutForLabel(Object label) {
    return 'Partilhar treino para $label';
  }

  @override
  String get whyNothingIsAddedTo =>
      'Porquê? Nada é acrescentado para compensar.';

  @override
  String get workout => 'Treino';

  @override
  String get recordedActivityLinkedToThis =>
      'Atividade registada associada a este treino';

  @override
  String get matchedToTheRecordedWorkout =>
      'Associado ao início do treino registado';

  @override
  String get matchedByWorkoutNameSport =>
      'Associado por nome do treino, desporto e data';

  @override
  String get matchedBySportDateAnd => 'Associado por desporto, data e duração';

  @override
  String planPlannedminutesMin(Object plannedMinutes) {
    return 'Plano $plannedMinutes min';
  }

  @override
  String get maxHr => 'FC máx.';

  @override
  String get trainingLoad2 => 'Carga de treino';

  @override
  String get active => 'Ativo';

  @override
  String get avgPace => 'Ritmo médio';

  @override
  String get avgSpeed => 'Velocidade média';

  @override
  String get avgPower => 'Potência média';

  @override
  String get elevation2 => 'Desnível';

  @override
  String get altitude => 'Altitude';

  @override
  String get explainMyHrvBeforeAnd =>
      'Explica a minha HRV antes e depois deste treino. O que é comparável, o que não é e o que ainda é desconhecido?';

  @override
  String get deleteActivity => 'Eliminar atividade?';

  @override
  String get removeThisActivityFromThe =>
      'Eliminar esta atividade? Fica eliminada, mesmo depois de os teus dispositivos voltarem a sincronizar. Podes restaurá-la nas Definições em Eliminados recentemente.';

  @override
  String get howDidThisSessionGo =>
      'Como correu este treino e o que significa para os meus próximos dias?';

  @override
  String currentFixedFixed2(Object fixed, Object fixed2) {
    return 'Atual $fixed, $fixed2';
  }

  @override
  String get setUpInTrainingSettings => 'Configurar nas definições de treino';

  @override
  String get couldNotLoadHeatData =>
      'Não foi possível carregar os dados de calor — toca para ver detalhes';

  @override
  String get loadingHeatHistory => 'A carregar histórico de calor…';

  @override
  String get noHeatDataYet => 'Ainda sem dados de calor';

  @override
  String optimalLowHigh(Object low, Object high) {
    return 'Ideal $low–$high';
  }

  @override
  String optimalLowHighTrimp(Object low, Object high) {
    return 'Ideal: $low–$high TRIMP';
  }

  @override
  String get targetUnavailableSyncTrainingHistory =>
      'Objetivo indisponível — sincroniza o histórico de treino';

  @override
  String get workoutQualifiedForHeatAccumulation =>
      'O treino contou para a acumulação de calor.';

  @override
  String get workoutDidNotAddHeat =>
      'O treino não contou para a acumulação de calor.';

  @override
  String get performanceTime => 'Desempenho / tempo';

  @override
  String get performanceDistance => 'Desempenho / distância';

  @override
  String get noRecordedRoute => 'Sem percurso registado';

  @override
  String get zoomIn => 'Aproximar';

  @override
  String get zoomOut => 'Afastar';

  @override
  String get fitRoute => 'Ajustar ao percurso';

  @override
  String get fullscreenMap => 'Mapa em ecrã inteiro';

  @override
  String get openstreetmapContributors2 => 'Colaboradores do OpenStreetMap';

  @override
  String get appleIntelligenceIsUnavailableShowing =>
      'O Apple Intelligence não está disponível. A mostrar um resumo sem IA.';

  @override
  String get generateAiBriefing => 'Gerar resumo de IA?';

  @override
  String get retryAiBriefing => 'Tentar resumo de IA novamente';

  @override
  String get generateBriefing => 'Gerar resumo';

  @override
  String discussThisBriefingWithMe(Object text) {
    return 'Discute comigo este resumo e sugere a melhor ação seguinte.\n\n$text';
  }

  @override
  String whyThisRecommendationWhichOf(Object text) {
    return 'Porquê esta recomendação? Que valores meus e que falhas nos dados levaram a ela, e o que a mudaria?\n\n$text';
  }

  @override
  String get avg2 => 'Méd.';

  @override
  String get peak2 => 'Pico';

  @override
  String get notEnoughContinuousReadingsFor =>
      'Medições contínuas insuficientes para uma média.';

  @override
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  ) {
    return 'Cobertura registada: $inHours h $inMinutes min · média ponderada pelo tempo';
  }

  @override
  String get lying => 'Deitado';

  @override
  String get noHrvReadingsInThis => 'Sem medições de HRV neste período';

  @override
  String get overnightHrvComesFromYour =>
      'A HRV noturna vem do teu relógio, as medições pontuais do Polar H10 (RMSSD). Os métodos diferem: compara tendências, não valores isolados.';

  @override
  String get noReadings => 'Sem medições';

  @override
  String get whenDidTheWorkoutStart => 'Quando começou o treino?';

  @override
  String get whenDidItEnd => 'Quando terminou?';

  @override
  String get last3Months => 'Últimos 3 meses';

  @override
  String get lastYear => 'Último ano';

  @override
  String lastDaysDays(Object days) {
    return 'Últimos $days dias';
  }

  @override
  String nowOnCurrentTapA(Object current) {
    return 'Agora em $current. Toca num dia ou arrasta o treino para lá. Os passos ficam como estão.';
  }

  @override
  String get monthView => 'Vista mensal';

  @override
  String get syncing => 'A sincronizar';

  @override
  String get trendUnavailable => 'Tendência indisponível';

  @override
  String get stable => 'Estável';

  @override
  String get increasing => 'A subir';

  @override
  String get decreasing => 'A descer';

  @override
  String get unclear => 'Pouco claro';

  @override
  String get notComparable => 'Não comparável';

  @override
  String get waitingForAfter => 'A aguardar o depois';

  @override
  String get afterOnly => 'Só depois';

  @override
  String get waitingForTheActualWorkout => 'A aguardar o fim real do treino.';

  @override
  String reminderAroundTolocal(Object toLocal) {
    return 'Lembrete por volta das $toLocal';
  }

  @override
  String get reminderIsDueMeasureWhen =>
      'O lembrete está ativo. Mede quando estiveres pronto.';

  @override
  String get thisReminderIsNoLonger =>
      'Este lembrete já não está atual. Abre o treino para veres as tuas medições.';

  @override
  String beforeFixedMilliseconds(Object fixed) {
    return 'Antes $fixed milissegundos. ';
  }

  @override
  String afterFixedMilliseconds(Object fixed) {
    return 'Depois $fixed milissegundos';
  }

  @override
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  ) {
    return 'Variação de $deltaMs milissegundos, $deltaPercent por cento.';
  }

  @override
  String get noPreTrainingMeasurementRecorded =>
      'Nenhuma medição pré-treino registada.';

  @override
  String get notMeasuredYet => 'Ainda não medido';

  @override
  String leftOutOfTheComparison(Object excludedTotal, Object c) {
    return 'Fora da comparação: $excludedTotal treinos ($c).';
  }

  @override
  String get notFromThisWorkout => 'Não é deste treino';

  @override
  String get useAsBefore => 'Usar como antes';

  @override
  String get useAsAfter => 'Usar como depois';

  @override
  String get beforeNotMeasured => 'Antes · não medido';

  @override
  String beforeTolocal(Object toLocal) {
    return 'Antes · $toLocal';
  }

  @override
  String workoutWorkouttext(Object workoutText) {
    return 'Treino · $workoutText';
  }

  @override
  String get afterNotMeasuredYet => 'Depois · ainda não medido';

  @override
  String afterTolocal(Object toLocal) {
    return 'Depois · $toLocal';
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
    return 'Os teus treinos semelhantes ($eligible, $toLocal–$toLocal2): mediana $medianMs ms, metade central $q1Ms a $q3Ms ms.';
  }

  @override
  String get howHardDidItFeel => 'Quão duro foi? (RPE)';

  @override
  String get loadMetric => 'Carga';

  @override
  String get clearAction => 'Limpar';

  @override
  String get routeFinish => 'Meta';

  @override
  String get month2 => 'MÊS';

  @override
  String get week2 => 'SEMANA';

  @override
  String get quarter => 'TRIMESTRE';

  @override
  String get year => 'ANO';

  @override
  String get easy3 => 'LEVE';

  @override
  String get mod => 'MOD.';

  @override
  String get hard => 'INTENSO';

  @override
  String get protocol => 'PROTOCOLO';

  @override
  String get calculate => 'CALCULAR';

  @override
  String get warmUp => 'AQUECIMENTO';

  @override
  String get coolDown => 'RETORNO À CALMA';

  @override
  String get ftpCycling => 'FTP ciclismo';

  @override
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg) {
    return 'FTP $ftpWatts W · $wattsPerKg W/kg';
  }

  @override
  String get thisWeekSoFar => 'ESTA SEMANA · ATÉ AGORA';

  @override
  String get duration2 => 'DURAÇÃO';

  @override
  String get distance2 => 'DISTÂNCIA';

  @override
  String get sport2 => 'DESPORTO';

  @override
  String get repeatSets => 'SÉRIES REPETIDAS';

  @override
  String get aboutThisWorkout => 'SOBRE ESTE TREINO';

  @override
  String get workoutStructure => 'ESTRUTURA DO TREINO';

  @override
  String get health2 => 'SAÚDE';

  @override
  String get high2 => 'ALTA';

  @override
  String get elevated => 'ELEVADA';

  @override
  String get normal => 'NORMAL';

  @override
  String get tomorrow => 'AMANHÃ';

  @override
  String get skipped2 => 'SALTADO';

  @override
  String get weeklyPlan => 'PLANO SEMANAL';

  @override
  String get activityLog3 => 'REGISTO DE ATIVIDADES';

  @override
  String skippedTouppercase(Object toUpperCase) {
    return 'SALTADO · $toUpperCase';
  }

  @override
  String get primaryZone => 'ZONA PRINCIPAL';

  @override
  String get coachingCues => 'DICAS DO TREINADOR';

  @override
  String get targets => 'OBJETIVOS';

  @override
  String get adaptation => 'ADAPTAÇÃO';

  @override
  String get done2 => 'FEITO';

  @override
  String get notRecorded2 => 'NÃO REGISTADO';

  @override
  String get planned => 'PLANEADO';

  @override
  String get extra => 'EXTRA';

  @override
  String get optimal2 => 'IDEAL';

  @override
  String get qualified => 'CONTOU';

  @override
  String get temp => 'TEMP';

  @override
  String get humidity2 => 'HUMIDADE';

  @override
  String get pressure => 'PRESSÃO';

  @override
  String get wetBulb => 'BOLBO HÚMIDO';

  @override
  String get paceMinKm => 'RITMO (min/km)';

  @override
  String get speedKmH => 'VELOCIDADE (km/h)';

  @override
  String get elevationM => 'ALTITUDE (m)';

  @override
  String get powerW => 'POTÊNCIA (W)';

  @override
  String get performanceTime2 => 'DESEMPENHO / TEMPO';

  @override
  String get performanceDistance2 => 'DESEMPENHO / DISTÂNCIA';

  @override
  String get load2 => 'CARGA';

  @override
  String get day2 => 'DIA';

  @override
  String get allTime => 'DESDE SEMPRE';

  @override
  String get hrvAroundThisWorkout2 => 'HRV em torno deste treino. ';

  @override
  String get lowReserve => 'RESERVA BAIXA';

  @override
  String get goodReserve => 'BOA RESERVA';

  @override
  String latestReadingAtTolocal(Object toLocal) {
    return 'Última medição às $toLocal';
  }

  @override
  String get weeklyAvg => 'MÉDIA SEMANAL';

  @override
  String get monthlyAvg => 'MÉDIA MENSAL';

  @override
  String get systolic2 => 'SISTÓLICA';

  @override
  String get diastolic2 => 'DIASTÓLICA';

  @override
  String get hourlyVariation => 'VARIAÇÃO HORÁRIA';

  @override
  String get dailyVariation => 'VARIAÇÃO DIÁRIA';

  @override
  String get sys2 => 'SIS';

  @override
  String get dia => 'DIA';

  @override
  String get bluetoothDevices => 'DISPOSITIVOS BLUETOOTH';

  @override
  String get accountsServices => 'CONTAS E SERVIÇOS';

  @override
  String get flowLoginOptional => 'INÍCIO DE SESSÃO FLOW (OPCIONAL)';

  @override
  String get polarFlowLogin => 'INÍCIO DE SESSÃO POLAR FLOW';

  @override
  String get raceGoal => 'OBJETIVO DE PROVA';

  @override
  String get experienceLevel => 'NÍVEL DE EXPERIÊNCIA';

  @override
  String get weeklySchedule2 => 'HORÁRIO SEMANAL';

  @override
  String get sessionsPerDay2 => 'TREINOS POR DIA';

  @override
  String get aboutYou => 'SOBRE TI';

  @override
  String get yourActivities2 => 'AS TUAS ATIVIDADES';

  @override
  String latestReadingAtTimestamp(Object timestamp) {
    return 'Última medição às $timestamp';
  }

  @override
  String get poorSleep => 'SONO FRACO';

  @override
  String get fairSleep => 'SONO RAZOÁVEL';

  @override
  String get goodSleep => 'SONO BOM';

  @override
  String get hoursOfSleep => 'HORAS DE SONO';

  @override
  String get sleepNeeded => 'SONO NECESSÁRIO';

  @override
  String get deepSleep => 'SONO PROFUNDO';

  @override
  String get exercises2 => 'EXERCÍCIOS';

  @override
  String get strengthSummary => 'RESUMO DE FORÇA';

  @override
  String get strengthDraft => 'FORÇA · RASCUNHO';

  @override
  String get strengthFinishedWithGaps => 'FORÇA · TERMINADO COM FALHAS';

  @override
  String get strength2 => 'FORÇA';

  @override
  String get wind => 'VENTO';

  @override
  String get sun2 => 'SOL';

  @override
  String get cloud => 'NUVENS';

  @override
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt) {
    return 'Dados: $source · Atualizado $fetchedAt';
  }

  @override
  String get coros2 => 'COROS';

  @override
  String get rmssdMs => 'RMSSD · ms';

  @override
  String get sdnnMs => 'SDNN · ms';

  @override
  String get now2 => 'AGORA';

  @override
  String get awake => 'ACORDADO';

  @override
  String get light => 'LEVE';

  @override
  String get deep2 => 'PROFUNDO';

  @override
  String get sqliteOrm => 'ORM SQLite';

  @override
  String get httpClients => 'Clientes HTTP';

  @override
  String get gpsLocation => 'Localização GPS';

  @override
  String get hdlCholesterol => 'Colesterol HDL';

  @override
  String get ldlCholesterol => 'Colesterol LDL';

  @override
  String get raceName => 'NOME DA PROVA';

  @override
  String get mtb => 'BTT';

  @override
  String get distanceKm => 'DISTÂNCIA (km)';

  @override
  String get priority => 'PRIORIDADE';

  @override
  String get elevationGainM => 'DESNÍVEL POSITIVO (m)';

  @override
  String get targetTime => 'TEMPO-OBJETIVO';

  @override
  String get raceDate => 'DATA DA PROVA';

  @override
  String get participation => 'PARTICIPAÇÃO';

  @override
  String get whatIWantFromIt => 'O QUE QUERO DISTO';

  @override
  String periodTimeline(Object period) {
    return 'EVOLUÇÃO $period';
  }

  @override
  String get tabPlan => 'PLANO';

  @override
  String get tabLoad => 'CARGA';

  @override
  String get tabCoach => 'COACH';

  @override
  String get hrDriftTestLt1 => 'TESTE DE DERIVA DA FC — LT1';

  @override
  String get asSentByGarmin => 'TAL COMO ENVIADO PELA GARMIN';

  @override
  String get noData2 => 'SEM DADOS';

  @override
  String get noTarget => 'SEM OBJETIVO';

  @override
  String get noHeatLoad => 'SEM CARGA DE CALOR';

  @override
  String get hrBpm => 'FC (bpm)';

  @override
  String get aiBriefingUnavailableShowingA =>
      'Resumo de IA indisponível. A mostrar um resumo sem IA.';

  @override
  String get uvIndex2 => 'ÍNDICE UV';

  @override
  String get aiBriefing => 'Resumo de IA';

  @override
  String get uiFrameworkByGoogle => 'Framework de UI da Google';

  @override
  String get unableToLoadData => 'Não foi possível carregar os dados';

  @override
  String briefingSummary(Object recovery, Object sleep, Object load) {
    return 'Recuperação $recovery / 100. Sono $sleep / 100. A carga de treino de hoje é $load TRIMP.';
  }

  @override
  String get morningBriefing => 'Resumo da manhã';

  @override
  String get lunchBriefing => 'Resumo do almoço';

  @override
  String get afternoonBriefing => 'Resumo da tarde';

  @override
  String get eveningBriefing => 'Resumo da noite';

  @override
  String get appleUnusableAnswer =>
      'O Apple Intelligence não conseguiu dar uma resposta útil: repetiu-se ou repetiu os teus dados. Reformula a pergunta ou escolhe outro fornecedor de IA nas definições.';

  @override
  String get appleCouldNotAnswer =>
      'O Apple Intelligence não conseguiu responder. Tenta novamente.';

  @override
  String get appleNotAvailableOnDevice =>
      'O Apple Intelligence não está disponível neste dispositivo.';

  @override
  String get appleLanguageRejected =>
      'O Apple Intelligence rejeitou o idioma do pedido. Experimenta uma pergunta curta em inglês. Verifica também as definições de idioma do iPhone e da Siri.';

  @override
  String get appleRequestTooLarge =>
      'Este pedido é demasiado grande para o Apple Intelligence. Experimenta uma pergunta mais curta.';

  @override
  String get messageTooLongForApple =>
      'Esta mensagem é demasiado longa para o Apple Intelligence. Encurta-a e envia novamente.';

  @override
  String get vo2maxRunning => 'VO₂máx corrida';

  @override
  String get vo2maxCycling => 'VO₂máx ciclismo';

  @override
  String get vo2maxPaceLabel => 'Ritmo VO₂máx';

  @override
  String get lt1Threshold => 'Limiar LT1';

  @override
  String get lt2Threshold => 'Limiar LT2';

  @override
  String hoursPreviousWeek(Object value) {
    return '$value h na semana anterior';
  }

  @override
  String kmPreviousWeek(Object value) {
    return '$value km na semana anterior';
  }

  @override
  String get thirtyMinuteTimeTrial => 'Contrarrelógio de 30 minutos';

  @override
  String thirtyMinTtDate(Object date) {
    return 'Contrarrelógio 30 min · $date';
  }

  @override
  String get yesterday2 => 'ONTEM';

  @override
  String get briefHeadGreen => 'Estás bem recuperado.';

  @override
  String get briefHeadYellow => 'Tens alguma carga acumulada.';

  @override
  String get briefHeadRed => 'Estás claramente sob carga.';

  @override
  String briefMain(Object reasons) {
    return 'Razões principais: $reasons.';
  }

  @override
  String get briefAllClear => 'Nenhum dos teus valores dá sinal de alerta.';

  @override
  String get briefAdviceGreen => 'Treina conforme planeado.';

  @override
  String get briefAdviceYellow =>
      'Mantém o plano, mas não acrescentes intensidade.';

  @override
  String get briefAdviceRed =>
      'A recuperação vem primeiro: faz um dia leve ou descansa.';

  @override
  String get briefReasonHrvLow => 'HRV do sono baixa';

  @override
  String get briefReasonHrvHigh => 'HRV do sono alta';

  @override
  String get briefReasonRhrUp => 'FC em repouso elevada';

  @override
  String get briefReasonRhrDown => 'FC em repouso baixa';

  @override
  String get briefReasonSleepShort => 'pouco sono';

  @override
  String get briefReasonSleepGood => 'necessidade de sono cumprida';

  @override
  String get briefReasonEnergyLow => 'pouca energia';

  @override
  String get briefReasonEnergyHigh => 'boa energia';

  @override
  String get briefReasonStressHigh => 'stress elevado';

  @override
  String get briefReasonRespHigh => 'frequência respiratória elevada';

  @override
  String get briefReasonSpo2Low => 'oxigénio no sangue baixo';

  @override
  String get briefReasonSkinTempOff => 'temperatura da pele invulgar';

  @override
  String get briefReasonFormTired => 'fadiga de treino acumulada';

  @override
  String get briefReasonFormVeryTired => 'fadiga de treino muito elevada';

  @override
  String get briefReasonFormFresh => 'fresco e descansado';

  @override
  String get briefTrainingHrvUp =>
      'A tua HRV subiu depois do treino, um bom sinal.';

  @override
  String get briefTrainingHrvDown =>
      'A tua HRV desceu depois do treino, um sinal menos bom.';

  @override
  String get reminderNeedsNotifications =>
      'O lembrete precisa de notificações. Permite-as para a Fjelia nas definições do sistema e volta a ativá-lo.';

  @override
  String get whatDidYouHave => 'O que consumiste?';

  @override
  String get intakeSomething => 'Consumi algo';

  @override
  String get intakeNothing => 'Nada';

  @override
  String get totalIntake => 'Ingestão total';

  @override
  String get carbsLabel => 'Hidratos';

  @override
  String get fluidLabel => 'Líquidos';

  @override
  String get sodiumLabel => 'Sódio';

  @override
  String get caffeineLabel => 'Cafeína';

  @override
  String get detailsOptional => 'Detalhes (opcional)';

  @override
  String atMinute(Object minute) {
    return 'minuto $minute';
  }

  @override
  String get nothingAddedYet =>
      'Ainda nada adicionado. Adiciona o que comeste ou bebeste, ou escolhe “Nada”.';

  @override
  String get followFocusWeek => 'Em que me devo concentrar esta semana?';

  @override
  String get followRecoveryTrend => 'Como está a evoluir a minha recuperação?';

  @override
  String get followLoadTooHigh => 'A minha carga de treino é demasiado alta?';

  @override
  String get followImproveSleep => 'O que melhoraria o meu sono?';

  @override
  String get followIntervalsFeel => 'Como devem ser sentidos os intervalos?';

  @override
  String get followTiredToday => 'E se hoje me sentir cansado?';

  @override
  String get followEatBefore => 'O que devo comer antes?';

  @override
  String get followAdjustToday => 'Devo ajustá-lo hoje?';

  @override
  String get followNextDays => 'O que significa para os meus próximos dias?';

  @override
  String get followCompareSimilar => 'Como se compara com treinos semelhantes?';

  @override
  String get followRecover => 'O que devo fazer para recuperar?';

  @override
  String get followIntensityRight => 'A intensidade foi a certa?';

  @override
  String get statusPlanned => 'Planeado';

  @override
  String get statusAdapted => 'Adaptado';

  @override
  String get statusCompleted => 'Concluído';

  @override
  String get statusRest => 'Descanso';

  @override
  String loadValue(Object value) {
    return 'Carga $value';
  }

  @override
  String get actIntensityEasy => 'Foi um treino aeróbio leve.';

  @override
  String get actIntensityModerate => 'Foi um treino moderado.';

  @override
  String get actIntensityHard => 'Foi um treino intenso.';

  @override
  String get actIntensityUnknown => 'Esse treino está registado.';

  @override
  String get actLenLonger =>
      'Foi mais longo do que os teus treinos semelhantes.';

  @override
  String get actLenShorter =>
      'Foi mais curto do que os teus treinos semelhantes.';

  @override
  String get actLoadHigher => 'A carga foi mais alta do que o habitual.';

  @override
  String get actLoadLower => 'A carga foi mais baixa do que o habitual.';

  @override
  String get actLoadSame => 'A carga foi mais ou menos a habitual.';

  @override
  String get actHrLower =>
      'A tua FC foi mais baixa do que o habitual, por isso pareceu mais fácil.';

  @override
  String get actHrHigher =>
      'A tua FC foi mais alta do que o habitual, por isso pareceu mais duro.';

  @override
  String get actAdviceUnknown =>
      'Planeia os próximos dias conforme te sentires.';

  @override
  String briefOutlookRest(Object days) {
    return 'Com cerca de $days dias leves, a tua forma volta ao intervalo ideal.';
  }

  @override
  String get briefOutlookLongRest =>
      'A tua forma precisa de mais do que alguns dias leves para recuperar.';

  @override
  String get briefOutlookPlanTired =>
      'Seguir o plano mantém a tua forma baixa nos próximos dias.';

  @override
  String get localQwen => 'Qwen3.5 · local';

  @override
  String get localModelDescription =>
      'Qwen3.5 opcional, MLX de 4 bits. Descarrega uma vez e depois usa o chat e os resumos neste dispositivo sem chave de API. Os teus dados de saúde ficam neste dispositivo.';

  @override
  String localModelSizeMb(Object megabytes) {
    return 'Transferência de $megabytes MB · é precisa memória adicional durante a execução.';
  }

  @override
  String get localModelDownload => 'Descarregar modelo';

  @override
  String get localModelResumeDownload => 'Retomar transferência';

  @override
  String localModelDownloading(Object downloaded, Object total) {
    return '$downloaded / $total MB';
  }

  @override
  String get localModelInstalled => 'Descarregado · disponível offline';

  @override
  String get localModelRemove => 'Eliminar modelo';

  @override
  String get localModelUnsupported =>
      'Este modelo MLX precisa de um iPhone com iOS 17 ou posterior e um chip A14 ou mais recente. Os dispositivos mais antigos não são suportados.';

  @override
  String get localModelMemoryUnsupported =>
      'Este dispositivo não tem memória suficiente para executar o modelo local.';

  @override
  String get localModelDownloadFailed =>
      'A transferência falhou. Tenta novamente; os ficheiros concluídos mantêm-se.';

  @override
  String get localModelDownloadFirst =>
      'Descarrega primeiro o Qwen em Definições → IA e mais.';

  @override
  String get localModelContextTooLong =>
      'Esta conversa é demasiado longa para o modelo local. Começa um novo chat ou encurta a pergunta.';

  @override
  String get localModelBusy =>
      'O modelo local está a responder a outro pedido. Tenta novamente daqui a pouco.';

  @override
  String get localModelInterrupted =>
      'A geração local foi interrompida. Mantém a Fjelia aberta e tenta novamente.';

  @override
  String get localModelCouldNotAnswer =>
      'O modelo local não conseguiu responder. Verifica o modelo em Definições → IA e mais e tenta novamente.';

  @override
  String get localModelBriefingUnavailable =>
      'Resumo de IA local indisponível. A mostrar o resumo da app.';

  @override
  String get localModelInfo => 'Detalhes do modelo e licença';

  @override
  String localModelRamGb(int gigabytes) {
    return 'Requer pelo menos $gigabytes GB de memória do dispositivo.';
  }

  @override
  String get localModelIPhone18 =>
      'O 4B está disponível no iPhone 18 e posteriores.';

  @override
  String briefPlannedTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Há $count treinos planeados para hoje.',
      one: 'Há $count treino planeado para hoje.',
    );
    return '$_temp0';
  }

  @override
  String get coachDataFallback =>
      'A resposta do modelo contradiz os dados. Aqui está o resumo da Fjelia:';

  @override
  String get coachSevenDayAverage => 'Média de 7 dias';

  @override
  String coachSleepNeedAndShortfall(String need, String shortfall) {
    return 'Necessidade de sono: $need h; défice: $shortfall h.';
  }

  @override
  String coachCurrentForm(String value) {
    return 'Forma atual (TSB): $value pontos.';
  }

  @override
  String get aiOnboardingStep => 'Passo 2 de 3';

  @override
  String get aiOnboardingTitle => 'O teu treinador.\nÀ tua maneira.';

  @override
  String get aiOnboardingSubtitle =>
      'Transforma os teus dados de saúde em conclusões para treinar e recuperar melhor.';

  @override
  String get aiOnboardingChoose => 'ESCOLHE O TEU TREINADOR IA';

  @override
  String get aiOnboardingFreeDetail => 'Grátis · sem conta de IA';

  @override
  String get aiOnboardingFreeBody => 'IA na nuvem para treino e recuperação.';

  @override
  String get aiOnboardingRecommended => 'Recomendado';

  @override
  String get aiOnboardingOnDevice => 'No teu dispositivo';

  @override
  String get aiOnboardingLocalBody =>
      'Os teus pedidos de IA ficam neste dispositivo.';

  @override
  String get aiOnboardingUnavailable => 'Indisponível de momento';

  @override
  String get aiOnboardingMore => 'Mais modelos de IA';

  @override
  String get aiOnboardingMoreBody =>
      'Qwen local ou o teu próprio fornecedor na nuvem';

  @override
  String get aiOnboardingConsent =>
      'Pedidos à nuvem só depois da tua confirmação.';

  @override
  String get aiOnboardingError =>
      'Não foi possível guardar ou carregar a tua escolha de IA. Tenta novamente.';

  @override
  String get aiOnboardingWithout => 'Continuar sem IA';

  @override
  String get aiOnboardingConfigure => 'Configurar modelo';

  @override
  String aiOnboardingContinue(String provider) {
    return 'Continuar com $provider';
  }

  @override
  String get aiOnboardingChangeLater =>
      'Podes mudar isto a qualquer momento nas Definições.';

  @override
  String get creditsAndLicenses => 'Créditos e licenças';

  @override
  String get bioAgeActivity => 'Atividade';

  @override
  String get bioAgeActivityBasis => 'Dados de atividade · últimos 7 dias';

  @override
  String bioAgeActivityReported(String minutes) {
    return '$minutes minutos moderados registados';
  }

  @override
  String bioAgeActivitySteps(String minutes) {
    return '≈ $minutes minutos de caminhada estimados a partir dos passos';
  }

  @override
  String bioAgeActivityCoverage(int days) {
    return 'Dados de $days de 7 dias';
  }

  @override
  String get bioAgeActivityEstimateNotice =>
      'Pressuposto: 100 passos ≈ 1 minuto de caminhada. Os totais diários de passos não revelam ritmo nem intensidade. Os minutos registados têm prioridade em cada dia; os passos desse dia não voltam a contar.';

  @override
  String get bioAgeActivityIncomplete =>
      'Faltam dados de atividade. A contribuição da atividade em anos só é calculada quando os 7 dias têm dados.';

  @override
  String get bioAgeActivityEstimatedLabel =>
      'A atividade inclui tempo de caminhada estimado.';

  @override
  String get bioAgeActivityUnknownLabel =>
      'Os dados de atividade estão incompletos';

  @override
  String get mixTitle => 'Preparar bebida';

  @override
  String get mixMyBottle => 'Preparar a minha garrafa';

  @override
  String get mixRecipes => 'Receitas';

  @override
  String get mixIngredients => 'Ingredientes';

  @override
  String get mixAddIngredient => 'Adicionar ingrediente';

  @override
  String get mixBottle => 'Garrafa';

  @override
  String get mixFilledWithWater => 'completada com água';

  @override
  String mixPerBottle(String ml) {
    return 'por garrafa de $ml ml';
  }

  @override
  String get mixStrength => 'Concentração';

  @override
  String get mixRatio => 'Glicose : frutose';

  @override
  String get mixGlucose => 'Glicose';

  @override
  String get mixFructose => 'Frutose';

  @override
  String get mixGlucoseOnly => 'Só glicose';

  @override
  String get mixGentle => 'Suave para o estômago – até 8 %.';

  @override
  String get mixStrong => 'Concentrada – só com o intestino treinado.';

  @override
  String get mixTooStrong => 'Muito concentrada – junta água.';

  @override
  String get mixNoFructoseHint =>
      'Só glicose: acima de cerca de 60 g de hidratos por hora, junta frutose (açúcar) – cerca de 2:1 é melhor absorvido.';

  @override
  String get mixFructoseHeavyHint =>
      'Mais frutose do que glicose pode incomodar o estômago – junta maltodextrina ou dextrose.';

  @override
  String get mixSpoonNote =>
      'O tamanho das colheres varia. Pesa a tua colher uma vez ou usa gramas para valores exatos.';

  @override
  String get mixTooMuchLiquid =>
      'Só o sumo e a cola já são mais do que cabe na garrafa – aumenta a garrafa.';

  @override
  String get mixAddToIntake => 'Adicionar à ingestão';

  @override
  String get mixUseAsBottle => 'Usar como a minha garrafa';

  @override
  String get mixDefaultName => 'Mistura de bebida';

  @override
  String get mixEmpty => 'Escolhe uma receita ou adiciona um ingrediente.';

  @override
  String get mixRemove => 'Remover';

  @override
  String mixRowGrams(String grams) {
    return '≈ $grams g';
  }

  @override
  String mixBottleSaved(String carbs, String ml) {
    return 'Guardado como a tua garrafa: $carbs g de hidratos por $ml ml.';
  }

  @override
  String get mixMaltodextrin => 'Maltodextrina';

  @override
  String get mixSugar => 'Açúcar';

  @override
  String get mixDextrose => 'Dextrose';

  @override
  String get mixHoney => 'Mel';

  @override
  String get mixSalt => 'Sal';

  @override
  String get mixOrangeJuice => 'Sumo de laranja';

  @override
  String get mixAppleJuice => 'Sumo de maçã';

  @override
  String get mixCola => 'Cola';

  @override
  String get unitTspLevel => 'colher de chá rasa';

  @override
  String get unitTspHeaped => 'colher de chá cheia';

  @override
  String get unitTbspLevel => 'colher de sopa rasa';

  @override
  String get unitTbspHeaped => 'colher de sopa cheia';

  @override
  String get unitPinch => 'pitada';

  @override
  String get unitTsp => 'c. chá';

  @override
  String get unitTbsp => 'c. sopa';

  @override
  String get mixRecipeMaltoSugar => 'Malto + açúcar 2:1';

  @override
  String get mixRecipeJuice => 'Sumo com água com gás';

  @override
  String get mixRecipeJuicePlus => 'Sumo com água com gás + malto';

  @override
  String get mixRecipeCola => 'Cola com água com gás';

  @override
  String get missedWorkoutTitle => 'Ainda no teu plano de hoje';

  @override
  String missedWorkoutBody(String workouts) {
    return '$workouts. Ainda hoje, mover ou saltar?';
  }

  @override
  String get stillToday => 'Ainda hoje';

  @override
  String get moveWorkoutAction => 'Mover…';

  @override
  String get missedWorkoutChannel => 'Treinos perdidos';

  @override
  String get missedWorkoutChannelDescription =>
      'Lembrete ao fim do dia de treinos planeados ainda em aberto nesse dia';

  @override
  String get missedWorkoutReminder => 'Lembrete de treino perdido';

  @override
  String get missedWorkoutReminderSubtitle =>
      'Ao fim do dia, se um treino planeado ainda estiver em aberto';

  @override
  String get moveWithinDays => 'Mover dentro de';

  @override
  String daysN(int count) {
    return '$count dias';
  }

  @override
  String get notificationsAreOff =>
      'As notificações da Fjelia estão desativadas. Permite-as para receberes este lembrete.';

  @override
  String get allowNotifications => 'Permitir notificações';

  @override
  String get openWorkoutToday => 'Ainda em aberto hoje';

  @override
  String get checkingForWorkout => 'A procurar o teu treino…';

  @override
  String get alreadyDone => 'Já feito ✓';

  @override
  String get alreadyDoneBody =>
      'O teu treino foi registado. Não há mais nada para hoje.';

  @override
  String get dropIt => 'Deixar cair';

  @override
  String askCoachSends(String provider) {
    return 'Envia o teu resumo de treino para $provider.';
  }

  @override
  String get coachThinking => 'O treinador está a pensar…';

  @override
  String get coachCouldNotAnswer =>
      'O treinador não conseguiu responder. A sugestão acima mantém-se.';

  @override
  String get whySkip => 'Porquê saltar?';

  @override
  String get skipReasonIllness => 'Doença';

  @override
  String get skipReasonInjury => 'Lesão ou dor';

  @override
  String get skipReasonFatigue => 'Cansaço';

  @override
  String get skipReasonNoTime => 'Sem tempo';

  @override
  String get skipReasonTravel => 'Viagem';

  @override
  String get skipReasonConditions => 'Condições';

  @override
  String get skipReasonMyChoice => 'Escolha minha';

  @override
  String get onbReminderTitle => 'Mantém o rumo';

  @override
  String get onbReminderSubtitle =>
      'Se um treino planeado ainda estiver em aberto ao fim do dia, a Fjelia lembra-te uma vez, para que ainda o possas fazer, mover ou saltar.';

  @override
  String get onbExampleWorkout => 'Corrida leve (45 min)';

  @override
  String get onbReminderToggle => 'Lembrete ao fim do dia';

  @override
  String get onbReminderTime => 'Lembrar-me às';

  @override
  String get onbReminderFootnote =>
      'Podes mudar isto a qualquer momento em Definições → Treino.';

  @override
  String get nowLabel => 'agora';

  @override
  String get coachSuggests => 'O treinador sugere';

  @override
  String get suggestionLabel => 'Sugestão';

  @override
  String get askCoachShort => 'Perguntar ao treinador';

  @override
  String get otherDay => 'Outro dia';

  @override
  String get skipEllipsis => 'Saltar…';

  @override
  String get pickADay => 'Toca num dia acima';

  @override
  String get dayDoesNotFit => 'Esse dia não encaixa no plano.';

  @override
  String get planUpdated => 'Plano atualizado';

  @override
  String get missedTodayTag => 'perdido hoje';

  @override
  String summaryMove(String day) {
    return 'Move-o para $day.';
  }

  @override
  String summaryMoveIndoor(String day) {
    return 'Move-o para $day, em interior – prevê-se chuva.';
  }

  @override
  String get summaryDropEasy =>
      'Deixa cair – um treino leve não vale a pena compensar.';

  @override
  String summaryDropNoDay(int days) {
    return 'Deixa cair – nenhum dia encaixa nos próximos $days dias.';
  }

  @override
  String get tagIndoor => 'interior';

  @override
  String get tagEasier => 'mais leve';

  @override
  String get tagRecovery => 'recuperação';

  @override
  String summaryMoveEasier(String day) {
    return 'Move-o para $day, um pouco mais leve – fica ao lado de um dia duro.';
  }

  @override
  String get briefRestDayToday => 'Hoje é um dia de descanso planeado.';

  @override
  String get restDayPlannedNote => 'A recuperação faz parte do teu plano.';

  @override
  String get restDayTitle => 'Dia de descanso';

  @override
  String get importActivityFile => 'Importar ficheiro de atividade';

  @override
  String get activityFileImportHint =>
      'Ficheiros FIT, GPX ou TCX (também comprimidos, como o Garmin Connect os exporta) de um ciclocomputador, Zwift, Strava ou outra app. Também podes partilhar um ficheiro com a Fjelia a partir da app Ficheiros ou do menu de partilha.';

  @override
  String get chooseActivityFiles => 'Escolher ficheiros';

  @override
  String get chooseOtherFiles => 'Escolher outros ficheiros';

  @override
  String get activityFileUnreadable => 'Não é um ficheiro de atividade legível';

  @override
  String get activityFileAlreadyImported => 'Já importado';

  @override
  String activityFileAlreadyFrom(String source) {
    return 'Já está na Fjelia a partir de $source';
  }

  @override
  String importActivities(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count atividades',
      one: 'Importar $count atividade',
    );
    return '$_temp0';
  }

  @override
  String activitiesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atividades importadas.',
      one: '$count atividade importada.',
    );
    return '$_temp0';
  }

  @override
  String get activityFileSource => 'Ficheiro';

  @override
  String get dfaAlpha1Title => 'Limiar aeróbio (DFA α1)';

  @override
  String get dfaHrvt1 => 'Limiar aeróbio (HRVT1)';

  @override
  String get dfaHrvt2 => 'Limiar anaeróbio (HRVT2)';

  @override
  String dfaEasyShare(String percent) {
    return '$percent % do treino abaixo do teu limiar aeróbio (α1 ≥ 0,75).';
  }

  @override
  String get dfaNoThreshold =>
      'O treino não ultrapassou claramente um limiar. Um teste em rampa, ou um treino que vai de leve a duro, dá uma estimativa.';

  @override
  String dfaBeats(int beats, String artifacts) {
    return '$beats batimentos · $artifacts % de artefactos';
  }

  @override
  String get dfaArtifactsHigh =>
      'Muitos artefactos: verifica se a cinta peitoral está bem ajustada e os elétrodos humedecidos.';

  @override
  String get dfaExplainer =>
      'A partir dos dados batimento a batimento de uma cinta peitoral. α1 perto de 1 é leve, 0,75 marca o limiar aeróbio e 0,5 o anaeróbio. Uma estimativa, não um teste de laboratório.';

  @override
  String get thresholdOrderNote =>
      'A Fjelia compara todas as fontes. Sugere primeiro os testes da própria app, depois o teu relógio, depois o DFA α1 de vários treinos e por fim o perfil Polar e as fórmulas. Nada muda até o aplicares.';

  @override
  String thresholdInUse(String value) {
    return 'Em uso: $value';
  }

  @override
  String thresholdProposal(String value, String source) {
    return 'Sugerido: $value de $source';
  }

  @override
  String get keepCurrent => 'Manter atual';

  @override
  String get lt2Cycling => 'LT2 · Ciclismo';

  @override
  String get thresholdSourceTt => 'Contrarrelógio de 30 minutos';

  @override
  String get thresholdSourceDrift => 'Teste de deriva da FC';

  @override
  String thresholdSourceDfa(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DFA α1, $count treinos',
      one: 'DFA α1, $count treino',
    );
    return '$_temp0';
  }

  @override
  String get thresholdSourceEftp => 'eFTP a partir de saídas';

  @override
  String get thresholdSourcePolarProfile => 'Perfil Polar';

  @override
  String get thresholdFormulaLt2 => 'LT2 − 30 bpm';

  @override
  String get thresholdFormulaMaxHr => '77 % da FC máx.';

  @override
  String get thresholdStale => 'com mais de 6 meses';

  @override
  String get thresholdsCoachLocked =>
      'O teu treinador gere os teus limiares, por isso não podem ser alterados aqui.';

  @override
  String get mediaTitle => 'Fotos e vídeos';

  @override
  String get mediaAdd => 'Adicionar';

  @override
  String get mediaFromLibrary => 'Escolher da biblioteca';

  @override
  String get mediaTakePhoto => 'Tirar foto';

  @override
  String get mediaRecordVideo => 'Gravar vídeo';

  @override
  String mediaAdding(int done, int total) {
    return 'A adicionar $done de $total…';
  }

  @override
  String get mediaMoveEarlier => 'Mover para antes';

  @override
  String get mediaMoveLater => 'Mover para depois';

  @override
  String get mediaDeleteTitle => 'Eliminar da Fjelia?';

  @override
  String get mediaDeleteMessage =>
      'Isto remove a foto ou o vídeo da Fjelia. O original na tua biblioteca de fotos mantém-se.';

  @override
  String get mediaAddFailed => 'Não foi possível adicionar alguns ficheiros.';

  @override
  String get mediaHint =>
      'Toca para ver, mantém premido para mover ou eliminar.';

  @override
  String get backupVideosTitle => 'Incluir vídeos?';

  @override
  String backupVideosMessage(String size) {
    return 'Os teus vídeos ocupam $size. Sem eles a cópia é muito mais pequena; as fotos são sempre incluídas.';
  }

  @override
  String get backupWithVideos => 'Com vídeos';

  @override
  String get backupWithoutVideos => 'Sem vídeos';

  @override
  String get mediaShareCard => 'Partilhar como cartão';

  @override
  String get mediaShareCardHint =>
      'Arrasta o painel ou o percurso para os mover. Afasta os dedos e arrasta a foto para a enquadrar; dois toques repõem-na.';

  @override
  String get shareGymPhoto => 'Foto do ginásio';

  @override
  String get shareWithoutPhoto => 'Sem foto';

  @override
  String get shareStyleGlass => 'Vidro';

  @override
  String get shareStylePoster => 'Cartaz';

  @override
  String get shareStyleMinimal => 'Minimalista';

  @override
  String get shareStyleNeon => 'Néon';

  @override
  String get shareStyleSticker => 'Autocolante';

  @override
  String get shareStyleReceipt => 'Talão';

  @override
  String get shareStyleKpop => 'K-pop';

  @override
  String get shareStylePixel => 'Píxel';

  @override
  String get shareStyleRobot => 'Robô';

  @override
  String get shareStyleScifi => 'Ficção científica';

  @override
  String get shareStyleCard => 'Cromo';

  @override
  String get shareStyleComic => 'Banda desenhada';

  @override
  String get shareStyleOutdoor => 'Outdoor';

  @override
  String get shareStyleHolo => 'Cartão holográfico';

  @override
  String get shareStyleHoloFull => 'Cartão de arte integral';

  @override
  String nowcastRainSoon(int minutes) {
    return 'Chuva dentro de cerca de $minutes min';
  }

  @override
  String nowcastRainingStops(int minutes) {
    return 'A chover agora · seco dentro de cerca de $minutes min';
  }

  @override
  String nowcastRainingOn(int minutes) {
    return 'A chover agora, durante pelo menos $minutes min';
  }

  @override
  String nowcastDry(int minutes) {
    return 'Seco nos próximos $minutes min';
  }

  @override
  String get sunAndMoon => 'Sol e lua';

  @override
  String get moonNew => 'Lua nova';

  @override
  String get moonWaxingCrescent => 'Lua crescente';

  @override
  String get moonFirstQuarter => 'Quarto crescente';

  @override
  String get moonWaxingGibbous => 'Crescente gibosa';

  @override
  String get moonFull => 'Lua cheia';

  @override
  String get moonWaningGibbous => 'Minguante gibosa';

  @override
  String get moonLastQuarter => 'Quarto minguante';

  @override
  String get moonWaningCrescent => 'Lua minguante';

  @override
  String moonLit(int percent) {
    return '$percent % iluminada';
  }

  @override
  String daylightLength(int hours, int minutes) {
    return '$hours h $minutes min de luz do dia';
  }

  @override
  String h10Battery(int level) {
    return 'Bateria $level %';
  }

  @override
  String get h10BatteryUnknown => 'Bateria ainda não lida';

  @override
  String h10BatteryChecked(String date) {
    return 'Verificada $date';
  }

  @override
  String get h10BatteryLowHint => 'Fraca: substitui em breve a pilha CR2025.';

  @override
  String get h10BatteryCheck => 'Verificar bateria';

  @override
  String get h10BatteryUnreachable =>
      'O H10 não respondeu. Coloca-o (ou humedece os contactos) e tenta novamente.';

  @override
  String get shareRaceCalendar => 'Partilhar calendário de provas';

  @override
  String get raceSeasonTitle => 'A minha época de provas';

  @override
  String get raceShareStylePoster => 'Cartaz';

  @override
  String get raceShareStyleTickets => 'Bilhetes';

  @override
  String get raceShareStyleTimeline => 'Cronologia néon';

  @override
  String get raceShareStyleMagazine => 'Revista';

  @override
  String get raceShareShowTarget => 'Mostrar tempos-objetivo';

  @override
  String get bpOptimal => 'IDEAL';

  @override
  String get bpHighNormal => 'NORMAL-ALTA';

  @override
  String get bpLow => 'BAIXA';

  @override
  String get bpLowHint =>
      'Tensão baixa: só preocupa se te sentires tonto ou com a cabeça leve.';

  @override
  String get waistCircumference => 'Perímetro da cintura';

  @override
  String get hipOptional => 'Anca (opcional)';

  @override
  String get waistToHeightRatio => 'Relação cintura-altura';

  @override
  String get waistToHipRatio => 'Relação cintura-anca';

  @override
  String get waistRiskLow => 'Muito magro';

  @override
  String get waistRiskHealthy => 'Saudável';

  @override
  String get waistRiskIncreased => 'Risco aumentado';

  @override
  String get waistRiskHigh => 'Risco alto';

  @override
  String get waistHowToMeasure =>
      'Mede de manhã, de pé, depois de expirar: a cintura a meio entre a última costela e o topo do osso da anca, a anca no ponto mais largo.';

  @override
  String get waistNeedsHeight =>
      'Adiciona a tua altura em Definições → Perfil.';

  @override
  String get waistNeedsHip => 'Mede a anca uma vez para o WHR.';

  @override
  String get waistSyncsProfile =>
      'A medição mais recente é também a tua cintura nas Definições.';

  @override
  String get waistChange30d => '30 dias';

  @override
  String get waistChange90d => '90 dias';

  @override
  String get waistChange1y => '1 ano';

  @override
  String get waistDeleteText => 'Isto remove a medição da cintura selecionada.';

  @override
  String waistAndHip(String waist, String hip) {
    return '$waist cm · anca $hip cm';
  }

  @override
  String hipValue(String hip) {
    return 'Anca $hip cm';
  }

  @override
  String get whtrTargetHint =>
      'Mantém a cintura abaixo de metade da tua altura.';

  @override
  String get noWaistYet => 'Ainda não mediste a cintura.';

  @override
  String get enterValidWaist =>
      'Introduz uma cintura e uma anca entre 20 e 300 cm.';

  @override
  String get waistFromProfile => 'Do teu perfil, sem data';

  @override
  String get phaseBase => 'BASE';

  @override
  String get phaseBuild => 'CONSTRUÇÃO';

  @override
  String get phasePeak => 'PICO';

  @override
  String get phaseTaper => 'AFINAÇÃO';

  @override
  String get phaseRecovery => 'RECUPERAÇÃO';

  @override
  String get phaseRace => 'PROVA';

  @override
  String get sessionTypeKey => 'CHAVE';

  @override
  String get sessionTypeLong => 'LONGO';

  @override
  String get sessionTypeRecovery => 'RECUPERAÇÃO';

  @override
  String get sessionTypeAssessment => 'TESTE';

  @override
  String get sessionTypeEndurance => 'RESISTÊNCIA';

  @override
  String get sessionTypeStrength => 'FORÇA';

  @override
  String get sessionTypeYoga => 'IOGA';

  @override
  String get sessionStatusCompleted => 'CONCLUÍDO';

  @override
  String get sessionStatusAdapted => 'ADAPTADO';

  @override
  String get stepWarmUp => 'Aquecimento';

  @override
  String get stepCoolDown => 'Retorno à calma';

  @override
  String get stepRecovery => 'Recuperação';

  @override
  String get stepRest => 'Descanso';

  @override
  String get stepInterval => 'Intervalo';

  @override
  String get stepWorkout => 'Treino';

  @override
  String stepRepeat(int n) {
    return 'Repetir $n×';
  }

  @override
  String get stepOpenEnded => 'Sem fim definido';

  @override
  String stepSeconds(int n) {
    return '$n s';
  }

  @override
  String get objectiveOptionalVariety =>
      'Variedade opcional que escolheste nas definições';

  @override
  String get objectiveStrengthSupport => 'Força para apoiar o teu treino';

  @override
  String objectiveIntervals(String goal) {
    return 'Intervalos para $goal';
  }

  @override
  String objectiveSteady(String sport, String goal) {
    return 'Qualidade contínua de $sport para $goal';
  }

  @override
  String objectiveEasyRecovery(String sport, String goal) {
    return '$sport leve: recuperação em torno de $goal';
  }

  @override
  String objectiveEasyEndurance(String sport, String goal) {
    return 'Resistência leve de $sport para $goal';
  }

  @override
  String objectiveLong(String sport, String goal) {
    return '$sport longo para $goal';
  }

  @override
  String unmetWeekMinutes(int minutes, String sport, String goal) {
    return 'A semana tem $minutes min, pouco para um $sport longo para $goal.';
  }

  @override
  String unmetWeekHours(String hours, String what) {
    return 'A semana tem $hours h, pouco para $what.';
  }

  @override
  String unmetTrainingDays(String what) {
    return 'Dias de treino insuficientes para $what.';
  }

  @override
  String get altMoveOneEvent => 'Mover um dos eventos';

  @override
  String get altMarkOneCancelled => 'Marcar um como cancelado';

  @override
  String altMakePriorityB(String goal) {
    return 'Dar prioridade B a $goal';
  }

  @override
  String altSkipGoal(String goal) {
    return 'Saltar $goal';
  }

  @override
  String altTreatAsTraining(String goal) {
    return 'Tratar $goal como evento de treino';
  }

  @override
  String altControlledEffort(String goal) {
    return 'Fazer $goal como esforço controlado';
  }

  @override
  String conflictSameDay(String a, String b) {
    return '$a e $b são no mesmo dia. Só é possível competir num.';
  }

  @override
  String conflictBothPriorityA(String a, String b, int gap, int more) {
    return '$a e $b são ambos prioridade A, com $gap dias de intervalo. A recuperação depois do primeiro e a afinação para o segundo precisam de mais $more dias do que isso.';
  }

  @override
  String conflictFlexibleOverlap(
    String a,
    String b,
    int gap,
    int overlap,
    String skip,
  ) {
    return '$a e $b estão a $gap dias de distância e sobrepõem-se $overlap dias. $skip está marcado como flexível: retirá-lo libertaria as semanas antes do outro evento.';
  }

  @override
  String conflictRecoveryOverlap(String a, String b, int gap, int overlap) {
    return '$a e $b estão a $gap dias de distância: a recuperação depois do primeiro sobrepõe-se $overlap dias à afinação para o segundo. A preparação de menor prioridade é limitada para proteger a outra.';
  }

  @override
  String conflictTightSpacing(String a, String b, int gap, int spare) {
    return '$a e $b estão a $gap dias de distância. A recuperação e a afinação cabem com $spare dias de margem, por isso qualquer contratempo não deixa espaço.';
  }

  @override
  String seasonShortened(int n, int of) {
    return 'Em $n de $of semanas o tempo semanal não comporta os treinos longos completos de todos os objetivos, por isso são encurtados em conjunto.';
  }

  @override
  String seasonAlternating(int n) {
    return 'Em $n semanas a semana não comporta todos os treinos longos; os desportos alternam.';
  }

  @override
  String seasonLongAway(int n) {
    return 'Em $n semanas um treino longo de mais de duas horas e meia fica fora do dia habitual, por causa dos teus dias de descanso e dos outros treinos.';
  }

  @override
  String seasonMovedOntoEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n treinos que moveste ficam num dia de evento ou no dia de descanso anterior. O plano mantém-nos onde os puseste.',
      one:
          '$n treino que moveste fica num dia de evento ou no dia de descanso anterior. O plano mantém-no onde o puseste.',
    );
    return '$_temp0';
  }

  @override
  String seasonNoRoom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n treinos ficaram de fora porque os exercícios escolhidos para eles eram mais longos do que o tempo que restava na semana.',
      one:
          '$n treino ficou de fora porque os exercícios escolhidos para ele eram mais longos do que o tempo que restava na semana.',
    );
    return '$_temp0';
  }

  @override
  String seasonMovedHardNearEvent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n treinos duros que moveste ficam nos dias leves depois de um evento. O plano mantém-nos onde os puseste.',
      one:
          '$n treino duro que moveste fica nos dias leves depois de um evento. O plano mantém-no onde o puseste.',
    );
    return '$_temp0';
  }

  @override
  String get seasonEventWeeks =>
      'Nas semanas com evento, o evento conta como treino, por isso o resto da semana é mais leve.';

  @override
  String seasonUnmet(int n, String detail) {
    return 'Em $n semanas os dias de treino não comportam todos os treinos protegidos: $detail';
  }

  @override
  String seasonNoHistory(String sport, String priority) {
    return 'Não há $sport recente no teu histórico, por isso o plano para o objetivo $priority é provisório.';
  }

  @override
  String get zoneRecovery => 'Recuperação';

  @override
  String workoutSentKeptInFjelia(String provider, String items) {
    return 'Enviado para $provider. Mantido só na Fjelia: $items.';
  }

  @override
  String paceGuideRange(String low, String high) {
    return 'Guia de ritmo $low a $high';
  }

  @override
  String get paceGuideFromGoal => ', estimado a partir do teu objetivo';

  @override
  String paceGuideGoalFlat(String pace) {
    return ' · ritmo-objetivo em plano $pace';
  }

  @override
  String get paceGuideHeartRateDecides => 'A FC decide.';

  @override
  String get moveKeyRestDay => 'dia de descanso';

  @override
  String get moveKeyEvent => 'evento';

  @override
  String get moveKeyEasyOnly => 'só leve';

  @override
  String get moveKeyHasSession => 'tem um treino';

  @override
  String get calendarCompleted => 'Concluído';

  @override
  String get calendarPlanned => 'Planeado';

  @override
  String get recentlyDeleted => 'Eliminados recentemente';

  @override
  String get recentlyDeletedExplain =>
      'As atividades eliminadas ficam eliminadas, mesmo quando os teus dispositivos voltam a sincronizar. Restaura uma para a recuperares; a fonte volta a enviar o percurso e as curvas, se ainda os tiver.';

  @override
  String get noDeletedActivities => 'Sem atividades eliminadas.';

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
    return '$name restaurada com os totais; a fonte já não envia percurso nem curvas.';
  }

  @override
  String deletedOn(String date) {
    return 'eliminada $date';
  }

  @override
  String get restore => 'Restaurar';

  @override
  String get coachWhyThisToday => 'Porquê este treino hoje?';

  @override
  String get coachHowDidItGo => 'Como correu este treino?';

  @override
  String get coachWhyRestDay => 'Porque é que este é um dia de descanso?';

  @override
  String get coachWhatInstead => 'O que devo fazer em vez disso?';

  @override
  String get newChat => 'Novo chat';

  @override
  String weekOfPlanned(String duration) {
    return 'de $duration planeados';
  }

  @override
  String get weekDoneNothingPlanned => 'concluído · sem treinos planeados';

  @override
  String sessionDropped(String reason, String duration) {
    return '$reason · $duration retirados';
  }

  @override
  String get importTitle => 'Importar';

  @override
  String get stravaArchive => 'Arquivo Strava';

  @override
  String get stravaArchiveZip => 'Arquivo Strava (ZIP)';

  @override
  String get stravaArchiveSubtitle =>
      'Todo o teu histórico da Strava com percursos e fotos';

  @override
  String get stravaIntro =>
      'Traz todo o teu histórico da Strava para a Fjelia: atividades com percurso, FC e potência, e as respetivas fotos.';

  @override
  String get stravaHowTo =>
      'Em strava.com: Definições → A minha conta → Transferir ou eliminar a tua conta → Pedir o teu arquivo. A Strava envia-te um ZIP por e-mail; escolhe-o aqui tal como está, sem o descomprimir.';

  @override
  String get stravaChooseZip => 'Escolher ZIP';

  @override
  String get stravaReading => 'A ler o arquivo…';

  @override
  String get stravaNotArchive =>
      'Este ZIP não é um arquivo de conta Strava: falta activities.csv.';

  @override
  String stravaFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atividades encontradas',
      one: '$count atividade encontrada',
    );
    return '$_temp0';
  }

  @override
  String stravaWithFiles(int count) {
    return '$count com gravação (percurso e curvas)';
  }

  @override
  String stravaPhotos(int photos, int videos) {
    return '$photos fotos, $videos vídeos';
  }

  @override
  String stravaAlready(int count) {
    return '$count duplicados, já na Fjelia ou duas vezes na Strava: só são adicionadas as fotos em falta';
  }

  @override
  String stravaDeletedSkip(int count) {
    return '$count eliminados antes, ignorados';
  }

  @override
  String stravaNew(int count) {
    return '$count novos';
  }

  @override
  String stravaStorage(int mb) {
    return 'cerca de $mb MB para fotos e vídeos';
  }

  @override
  String get stravaPrivacy =>
      'Tudo é lido neste dispositivo. Nada é carregado e não é preciso iniciar sessão na Strava.';

  @override
  String stravaImportButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count atividades',
      one: 'Importar $count atividade',
    );
    return '$_temp0';
  }

  @override
  String get stravaImporting => 'A importar arquivo Strava';

  @override
  String stravaProgressActivities(String done, String total) {
    return 'Atividades: $done / $total';
  }

  @override
  String stravaImportedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atividades importadas',
      one: '$count atividade importada',
    );
    return '$_temp0';
  }

  @override
  String stravaProgressPhotos(int count) {
    return 'Fotos: $count importadas';
  }

  @override
  String stravaProgressDuplicates(int count) {
    return 'Duplicados: $count ignorados';
  }

  @override
  String stravaProgressDeleted(int count) {
    return 'Eliminados antes: $count ignorados';
  }

  @override
  String stravaProgressErrors(int count) {
    return 'Erros: $count';
  }

  @override
  String get stravaKeepOpen =>
      'Podes usar a app entretanto. Mantém a Fjelia aberta até a importação terminar.';

  @override
  String get stravaComplete => 'Importação da Strava concluída';

  @override
  String get stravaPartial => 'Importação da Strava incompleta';

  @override
  String get stravaCancelled => 'Importação da Strava cancelada';

  @override
  String get stravaShowErrors => 'Mostrar erros';

  @override
  String get stravaAgainHint =>
      'Importar o mesmo arquivo novamente só acrescenta o que ainda falta.';

  @override
  String get renameActivity => 'Mudar o nome da atividade';

  @override
  String get activityTitleLabel => 'Título';

  @override
  String get activityTitleKept =>
      'O teu título mantém-se quando a atividade voltar a sincronizar. Só muda na Fjelia, não na plataforma de origem.';

  @override
  String originalTitle(String name) {
    return 'Original: $name';
  }

  @override
  String get useOriginalTitle => 'Usar título original';

  @override
  String get loadOlderActivities => 'Carregar atividades mais antigas';

  @override
  String get noOlderActivities => 'Sem atividades mais antigas';

  @override
  String get maxSpeed => 'Velocidade máx.';

  @override
  String get caloriesLabel => 'Calorias';

  @override
  String get activityDescription => 'Descrição';

  @override
  String get nightCurves => 'Curvas noturnas';

  @override
  String get noPhaseTimeline =>
      'Este relógio não indica quando ocorreu cada fase do sono, apenas os totais acima. Estas são a HRV e o stress que mediu durante a noite.';

  @override
  String get stagesEstimated =>
      'Estimado pela Fjelia a partir da HRV e do stress que o teu relógio COROS mediu durante a noite. Os totais por fase são os da COROS; o momento de cada fase é uma aproximação.';

  @override
  String get nightCurvesBasis =>
      'A HRV e o stress medidos durante a noite. A estimativa das fases acima baseia-se neles.';

  @override
  String get swimShort =>
      'A água costuma bastar. Não são precisos géis: uma refeição normal antes e depois cobre esta natação.';

  @override
  String get swimPoolLong =>
      'Considera uma bebida com hidratos nas pausas mais longas entre séries, sobretudo se o treino for intenso. Na piscina não são precisos géis.';

  @override
  String get swimOpenFeeds =>
      'Planeia hidratos e líquidos em torno das oportunidades de abastecimento (barco, caiaque, margem). Não contes com alimentação que não consigas alcançar em segurança durante a natação.';

  @override
  String get swimOpenUnsupported =>
      'Sem abastecimentos numa natação sem apoio: come bem antes, mantém a natação dentro do que isso cobre e reabastece logo a seguir.';

  @override
  String get swimOpenFeedsUnknown =>
      'Águas abertas: indica em Editar estratégia se é possível abastecer (com ou sem apoio).';

  @override
  String get swimFluidPool =>
      'A hidratação também conta na piscina: na água transpiras menos do que em terra, mas não nada. Deixa uma garrafa identificada no cais e bebe nas pausas.';

  @override
  String get swimFluidOpen =>
      'As previsões do ar não dão a temperatura da água, e a água fria tira a sede: bebe antes da partida, em cada abastecimento e logo a seguir.';

  @override
  String get swimBeforeAfter =>
      'Antes: uma refeição de hidratos habitual 1–4 h antes. Depois: cerca de 1 g de hidratos por kg com 20–25 g de proteína; se te pesaste, bebe cerca de 1,5 l por kg perdido, com algum sódio.';

  @override
  String get swimNoDuration =>
      'Sem duração planeada: água à beira da piscina basta para a maioria das natações; junta uma bebida com hidratos só em natações com mais de 90 minutos.';

  @override
  String swimCarryPool(String bottles, String bottleMl, String drinkCarbs) {
    return 'Sem géis. Garrafa à beira da piscina: $bottles × $bottleMl ml; $drinkCarbs g de hidratos vêm da bebida.';
  }

  @override
  String swimCarryOpen(String bottles, String bottleMl, String drinkCarbs) {
    return 'Sem géis durante a natação. Nos abastecimentos: $bottles × $bottleMl ml; $drinkCarbs g de hidratos vêm da bebida.';
  }

  @override
  String swimPerBreak(String carbs, String fluid) {
    return 'Por cada 20 minutos, numa pausa ou abastecimento: cerca de $carbs g de hidratos e $fluid ml.';
  }

  @override
  String get feedsLabel => 'Abastecimentos (águas abertas)';

  @override
  String get feedsSupported => 'Com apoio (barco, caiaque, margem)';

  @override
  String get feedsUnsupported => 'Sem apoio';

  @override
  String get feedsUnknown => 'Desconhecido';

  @override
  String get ecgTitle => 'ECG';

  @override
  String get ecgChooseDevice => 'Escolher Polar H10';

  @override
  String get ecgStart => 'Gravar ECG';

  @override
  String get ecgStopSave => 'Parar e guardar';

  @override
  String get ecgImport => 'Importar ficheiro de ECG';

  @override
  String get ecgHistory => 'Histórico de ECG';

  @override
  String get ecgWaveform => 'Traçado';

  @override
  String get ecgReport => 'Relatório';

  @override
  String get ecgExportCsv => 'Exportar traçado (CSV)';

  @override
  String get ecgExportMetadata => 'Exportar metadados do ECG';

  @override
  String get ecgExportOriginal => 'Partilhar ficheiro original';

  @override
  String get ecgRecording => 'A gravar ECG';

  @override
  String get ecgRecordingDate => 'Data e hora da gravação';

  @override
  String get ecgLinkedWorkout => 'Treino associado';

  @override
  String get ecgIndependent => 'Sem treino associado';

  @override
  String get ecgNoRecordings => 'Ainda não há gravações de ECG.';

  @override
  String ecgSamples(int count) {
    return '$count amostras';
  }

  @override
  String ecgSignalGaps(int count) {
    return '$count falhas de sinal';
  }

  @override
  String get ecgDeleteConfirm =>
      'Eliminar definitivamente esta gravação e o ficheiro original?';

  @override
  String get ecgDescription =>
      'Grava com o Polar H10, importa traçados CSV ou guarda relatórios PDF.';

  @override
  String get ecgPrivacy =>
      'Guardado neste dispositivo e incluído nas cópias de segurança. Os sinais em bruto não são enviados ao treinador.';

  @override
  String get ecgLimitations =>
      'Para gravação e revisão pessoais. A HRV derivada do ECG e a qualidade do sinal não são validadas aqui; não é calculado nenhum diagnóstico nem pontuação de recuperação.';

  @override
  String get ecgImportLimitations =>
      'As exportações PDF da Garmin e do Apple Watch são relatórios. Os traçados exigem as colunas CSV time_seconds (ou time_ms) e ecg_uv (ou ecg_mv).';

  @override
  String get ecgReportOnly =>
      'Apenas relatório. Não há amostras do traçado em bruto. Partilha o ficheiro original para ver o relatório.';

  @override
  String get indoorTitle => 'Treino indoor';

  @override
  String get indoorEquipment => 'Equipamento de fitness';

  @override
  String get indoorChooseEquipment => 'Escolher equipamento';

  @override
  String get indoorChooseHeartRate => 'Escolher sensor de FC';

  @override
  String get indoorStart => 'Iniciar gravação';

  @override
  String get indoorPause => 'Pausar gravação';

  @override
  String get indoorFinish => 'Terminar e guardar';

  @override
  String get indoorSaved => 'Guardado no histórico de atividades';

  @override
  String get indoorExportFit => 'Partilhar atividade FIT';

  @override
  String get indoorUnfinished => 'Gravações por terminar';

  @override
  String get indoorReviewResume => 'Rever ou retomar';

  @override
  String get indoorDiscard => 'Descartar gravação';

  @override
  String get indoorDiscardConfirm =>
      'Descartar definitivamente esta gravação por terminar?';

  @override
  String get indoorExternalHeartRate => 'Usar sensor de FC externo';

  @override
  String get indoorEquipmentHeartRate => 'Desligado: usar a FC do equipamento';

  @override
  String get indoorCurrentInterval => 'Intervalo atual';

  @override
  String get indoorNextInterval => 'Intervalo seguinte';

  @override
  String get indoorPlanComplete => 'Intervalos planeados concluídos';

  @override
  String get indoorAuthorizeControl => 'Permitir controlo do equipamento';

  @override
  String get indoorManualOverride => 'Usar controlo manual';

  @override
  String get indoorAutoPower =>
      'Seguir automaticamente a potência do intervalo';

  @override
  String get indoorApplyTarget => 'Aplicar objetivo';

  @override
  String get indoorDescription =>
      'Liga equipamento Bluetooth FTMS e grava um treino indoor.';

  @override
  String get indoorKeepOpen =>
      'A gravação continua quando mudas de app ou bloqueias o ecrã. A pausa para o registo de métricas; usa os comandos do equipamento para pausar a máquina.';

  @override
  String get indoorFitHint =>
      'Guarda o ficheiro FIT ou abre-o numa app de treino compatível através do menu de partilha.';

  @override
  String get indoorNoEquipment =>
      'Nenhum equipamento FTMS encontrado. Ativa a máquina e liga o Bluetooth dela.';

  @override
  String get indoorControlPrompt =>
      'Permitir que a Fjelia altere os objetivos neste treino? Fica perto dos comandos da máquina. Podes mudar para controlo manual a qualquer momento.';

  @override
  String get indoorTreadmillSafety =>
      'Coloca a chave de segurança e fica perto dos comandos. Confirma só pequenas alterações, até 0,5 km/h ou 1% de inclinação. Usa os comandos da máquina para alterações maiores.';

  @override
  String get recordingTime => 'Tempo de gravação';

  @override
  String get recordingSpeed => 'Velocidade';

  @override
  String get recordingPower => 'Potência';

  @override
  String get recordingCadence => 'Cadência / ritmo de remada';

  @override
  String get recordingIncline => 'Inclinação';

  @override
  String get recordingResistance => 'Resistência';

  @override
  String get recordingSource => 'Fonte';

  @override
  String get recordingNext => 'Passo seguinte';

  @override
  String get recordingConnecting => 'A ligar';

  @override
  String get recordingReconnecting => 'A voltar a ligar';

  @override
  String get recordingInterrupted => 'Interrompido';

  @override
  String get recordingPaused => 'Em pausa';

  @override
  String get indoorMatrixReadOnly =>
      'Apenas gravação da passadeira Matrix. Usa a consola para a velocidade e a inclinação; o controlo remoto não foi verificado neste modelo.';

  @override
  String ecgCoverage(String value) {
    return '$value% de cobertura de amostras';
  }

  @override
  String get recordingBeforeRestore =>
      'Termina a gravação do dispositivo antes de restaurar uma cópia de segurança.';

  @override
  String get gymTitle => 'Passadeiras de ginásio';

  @override
  String get gymDescription =>
      'Grava com o telemóvel, importa treinos xID ou digitaliza o resumo da consola.';

  @override
  String get gymDirectConnection => 'Ligação direta';

  @override
  String get gymConsoleSupport =>
      'As opções de ligação dependem da consola. Uma consola Matrix mais antiga pode suportar xID em vez de dados Bluetooth em direto.';

  @override
  String get gymFindEquipment => 'Procurar equipamento do ginásio';

  @override
  String get gymLiveAvailable =>
      'Esta consola pode enviar dados de treino diretamente para a Fjelia.';

  @override
  String get gymLiveUnavailable =>
      'Não foram encontrados dados de treino em direto suportados. Importa treinos xID ou guarda um resumo da consola.';

  @override
  String get gymSpeedOnly =>
      'Estão disponíveis a velocidade e a cadência. Esta ligação não fornece inclinação nem controlo remoto.';

  @override
  String get gymUseMachine => 'Usar esta máquina';

  @override
  String get gymConnectionReport => 'Relatório de ligação';

  @override
  String get gymShareReport => 'Partilhar relatório de ligação';

  @override
  String get gymXid => 'Matrix xID';

  @override
  String get gymXidDescription =>
      'Importa treinos de passadeira guardados pela rede xID do teu ginásio.';

  @override
  String get gymPortal => 'Portal Netpulse do ginásio';

  @override
  String get gymPortalHelp =>
      'Introduz o endereço do portal Netpulse fornecido pelo teu ginásio.';

  @override
  String get gymPasscode => 'Código xID';

  @override
  String get gymSessionHelp =>
      'A tua sessão é guardada em segurança. O código não é guardado.';

  @override
  String get gymAutoSync => 'Sincronizar treinos xID automaticamente';

  @override
  String gymLastDays(int days) {
    return 'Últimos $days dias';
  }

  @override
  String get gymLoadWorkouts => 'Carregar treinos';

  @override
  String get gymNoWorkouts =>
      'Não foram encontrados treinos de passadeira neste período.';

  @override
  String gymSkipped(int count) {
    return '$count treinos ilegíveis ignorados.';
  }

  @override
  String gymImported(int count, int duplicates) {
    return '$count treinos importados; $duplicates duplicados ignorados.';
  }

  @override
  String get gymSummary => 'Resumo da passadeira';

  @override
  String get gymSummaryDescription =>
      'Fotografa o ecrã final da consola e revê os valores antes de guardar.';

  @override
  String get gymTakePhoto => 'Tirar foto';

  @override
  String get gymChoosePhoto => 'Escolher foto';

  @override
  String get gymReview =>
      'Verifica as unidades, a hora de início e os valores. As fotos são lidas no teu telemóvel. Só o resumo do treino é guardado.';

  @override
  String get gymStartTime => 'Início do treino';

  @override
  String get gymDurationHelp =>
      'Introduz mm:ss ou hh:mm:ss, por exemplo 30:00.';

  @override
  String get gymDistanceUnit => 'Unidade de distância';

  @override
  String get gymCalories => 'Calorias';

  @override
  String get manualRecordTitle => 'Gravar atividade';

  @override
  String get manualRecordDescription =>
      'Grava uma atividade com GPS, ECG e FC opcionais. A gravação continua quando mudas de app ou bloqueias o ecrã, até premires Pausa ou Parar.';

  @override
  String get manualTreadmill => 'Corrida na passadeira';

  @override
  String get manualChooseH10 => 'Escolher Polar H10';

  @override
  String get manualRecordEcg => 'Gravar ECG com o Polar H10';

  @override
  String get manualChooseHelp => 'Escolhe um Polar H10 para gravar ECG e FC.';

  @override
  String manualEcgSegments(int count) {
    return 'Segmentos de ECG associados: $count';
  }

  @override
  String get manualEcgInterrupted =>
      'O ECG parou. O cronómetro da atividade continua.';

  @override
  String get manualRestartEcg => 'Reiniciar gravação de ECG';

  @override
  String get manualFinalDistance => 'Distância final (opcional)';

  @override
  String get manualDiscardNote =>
      'Descartar esta atividade? As gravações de ECG ficam no histórico de ECG.';

  @override
  String get manualRecordHeartRate => 'Gravar FC';

  @override
  String get manualChooseHr => 'Escolhe um sensor de FC';

  @override
  String get manualHrWithEcg => 'Usa a mesma ligação ao H10 que o ECG.';

  @override
  String get manualRecordGps => 'Gravar percurso e distância por GPS';

  @override
  String get manualGpsHelp =>
      'Para atividades ao ar livre. Permite a localização exata para gravar o percurso com o ecrã desligado.';

  @override
  String get manualGpsWaiting => 'A aguardar uma posição GPS precisa';

  @override
  String manualGpsAccuracy(int meters) {
    return 'Precisão do GPS: $meters m';
  }

  @override
  String get manualRecordBp => 'Incluir medições de tensão arterial';

  @override
  String get manualBpHelp =>
      'Mostra as medições da Hilo, Aktiia e Saúde feitas durante esta gravação, incluindo depois de sincronizações posteriores.';

  @override
  String get manualBpUnavailable =>
      'Não foi possível carregar as medições de tensão.';

  @override
  String get manualBpEmpty => 'Sem medições de tensão durante esta gravação.';

  @override
  String get manualHrDisconnected => 'Sensor de FC desligado.';

  @override
  String get manualReconnectHr => 'Voltar a ligar sensor de FC';

  @override
  String get manualBackgroundNotification =>
      'A gravação continua com o ecrã desligado';

  @override
  String get ecgAskCoach => 'Falar com o treinador IA';

  @override
  String get ecgCoachWarningTitle => 'Não é aconselhamento médico';

  @override
  String get ecgCoachWarningBody =>
      'O treinador IA não é médico e não pode fazer diagnósticos. Um ECG de cinta peitoral tem apenas uma derivação: não exclui um ataque cardíaco nem outra doença cardíaca, e a análise pode estar errada.\n\nDor ou aperto no peito, falta de ar, dor no braço, maxilar ou costas, suores frios ou desmaio: liga já para o 112. Não esperes por uma resposta da IA.\n\nOs valores analisados e 10 segundos do sinal em bruto vão para o modelo de IA escolhido nas definições de IA.';

  @override
  String get ecgCoachUnderstood => 'Compreendo';

  @override
  String get ecgCoachBanner =>
      'Não é aconselhamento médico. A IA não é médica e não exclui um ataque cardíaco. Emergência: liga 112.';

  @override
  String get ecgCoachCardTitle => 'Pré-análise do ECG';

  @override
  String get statusMeasured => 'Medido';

  @override
  String get ecgQuestionOverview => 'O que mostra o meu ECG?';

  @override
  String get ecgQuestionRhythm => 'O meu ritmo cardíaco é regular?';

  @override
  String get ecgQuestionDoctor => 'Um médico devia ver isto?';

  @override
  String get ecgFollowSymptoms =>
      'Que sintomas significam que devo ir ao médico?';

  @override
  String get ecgFollowRiskFactors =>
      'Como é que os meus fatores de risco mudam isto?';

  @override
  String get ecgFollowTraining => 'Posso treinar normalmente?';

  @override
  String get ecgFollowBetterRecording => 'Como gravo um ECG melhor?';

  @override
  String get manualTreadmillConnect => 'Ligar passadeira (Bluetooth, opcional)';

  @override
  String get manualTreadmillHelp =>
      'A velocidade, a distância e a inclinação vêm então da passadeira. Sem ligação, introduz a distância no fim.';

  @override
  String get sportIndoorCycling => 'Ciclismo indoor';

  @override
  String get sportElliptical => 'Elíptica';

  @override
  String get sportStairClimber => 'Simulador de escadas';

  @override
  String get manualWrongMachine =>
      'Este equipamento não corresponde ao desporto escolhido.';

  @override
  String get manualEquipmentHelp =>
      'Liga equipamento Bluetooth (FTMS). A velocidade, a potência, a cadência e a distância vêm da máquina.';

  @override
  String get plusTitle => 'Registar';

  @override
  String get plusStartWorkout => 'Iniciar treino';

  @override
  String get plusStartWorkoutHint =>
      'Em direto com GPS, passadeira ou bicicleta indoor · ECG e FC';

  @override
  String get plusGroupTraining => 'Treino';

  @override
  String get plusGroupHeart => 'Coração e circulação';

  @override
  String get plusGroupBody => 'Corpo';

  @override
  String get plusGroupRecovery => 'Recuperação';

  @override
  String get plusLogWorkout => 'Registar um treino';

  @override
  String get plusLogWorkoutHint => 'Adiciona um treino passado à mão';

  @override
  String get plusImport => 'Importar';

  @override
  String get plusImportHint => 'Strava, FIT, GPX, passadeira do ginásio';

  @override
  String get plusEcg => 'Gravar ECG';

  @override
  String get plusEcgHint => 'Polar H10 ou ficheiro de ECG';

  @override
  String get plusHrv => 'Verificação de HRV';

  @override
  String get plusHrvHint => 'Medição curta com o Polar H10';

  @override
  String get plusBpMeasure => 'Medir com a braçadeira Hilo';

  @override
  String get plusBpMeasureHint => 'Emparelhe a braçadeira Hilo por Bluetooth';

  @override
  String get plusBpLog => 'Registar tensão';

  @override
  String get plusBpLogHint => 'Introduz uma medição';

  @override
  String get plusBpReport => 'Relatório Hilo';

  @override
  String get plusBpReportHint => 'Importa o PDF';

  @override
  String get plusSpo2 => 'SpO₂ e pulso';

  @override
  String get plusSpo2Hint => 'De um oxímetro';

  @override
  String get plusWeigh => 'Pesar';

  @override
  String get plusWeighHint => 'Balança RENPHO por Bluetooth';

  @override
  String get plusWeightLog => 'Registar peso';

  @override
  String get plusWeightLogHint => 'Peso, gordura corporal, IMC';

  @override
  String get plusWaist => 'Cintura';

  @override
  String get plusWaistHint => 'Perímetro e relações';

  @override
  String get plusGrip => 'Força de preensão';

  @override
  String get plusGripHint => 'Medição com dinamómetro';

  @override
  String get plusSleep => 'Registar sono';

  @override
  String get plusSleepHint => 'Duração, profundo e REM';

  @override
  String get recPace => 'Ritmo (/km)';

  @override
  String get recAvgPace => 'Ritmo médio';

  @override
  String get recPace500 => 'Ritmo (/500 m)';

  @override
  String get recSpeedKmh => 'Velocidade (km/h)';

  @override
  String get recPowerW => 'Potência (W)';

  @override
  String get recDistanceKm => 'Distância (km)';

  @override
  String get recHeartRate => 'Frequência cardíaca';

  @override
  String get recMap => 'Mapa';

  @override
  String get recStart => 'Iniciar';

  @override
  String get recResume => 'Retomar';

  @override
  String get recFinish => 'Terminar';

  @override
  String get recDiscard => 'Descartar';

  @override
  String get recLive => 'A gravar';

  @override
  String get recNew => 'Nova atividade';

  @override
  String get recCadence => 'Cadência';

  @override
  String get recMachine => 'Equipamento';

  @override
  String get recGps => 'GPS';

  @override
  String get recEcg => 'ECG';

  @override
  String get recBloodPressure => 'Tensão arterial';

  @override
  String get recBannerOpen => 'Toca para abrir';

  @override
  String get bpActivityHint =>
      'As braçadeiras muitas vezes não conseguem medir enquanto te mexes. As medições de antes ou depois da atividade não aparecem aqui.';

  @override
  String objectiveKeyLong(String sport, String goal) {
    return '$sport longo-chave para $goal';
  }

  @override
  String seasonKeyRides(int n) {
    return 'Em $n semanas um treino longo-chave sobe até metade do evento, uma vez por bloco e nunca junto de outro evento.';
  }

  @override
  String seasonEventAsLong(int n) {
    return 'Em $n semanas outro evento é o treino longo para um objetivo maior.';
  }

  @override
  String objectiveThreshold(String sport, String goal) {
    return '$sport de limiar para $goal';
  }

  @override
  String objectiveHills(String sport, String goal) {
    return '$sport em subidas para $goal';
  }

  @override
  String objectiveOpeners(String goal) {
    return 'Ativação para $goal';
  }

  @override
  String get planAdjustedTitle => 'Plano ajustado automaticamente';

  @override
  String planAdjSwap(String session, String day, String from) {
    return '$session: feito em $day em vez de $from.';
  }

  @override
  String planAdjSubstitute(String activity, String session, String from) {
    return '$activity conta como $session de $from.';
  }

  @override
  String planAdjStrengthCredit(String activity, String session) {
    return '$activity cobre a força de pernas de $session.';
  }

  @override
  String planAdjMoved(String session, String day) {
    return '$session passa para $day, que ficou livre.';
  }

  @override
  String planAdjMovedEasy(String session, String day, String activity) {
    return '$session passa para $day, mais leve: as tuas pernas recuperam de $activity.';
  }

  @override
  String get planAdjUndone => 'Alteração anulada.';

  @override
  String get shortSessionTitle => 'Mais curto do que o planeado – porquê?';

  @override
  String shortSessionLine(String session, int done, int planned) {
    return '$session: $done de $planned min';
  }

  @override
  String get shortReasonTime => 'Sem tempo';

  @override
  String get shortReasonWeather => 'Meteorologia';

  @override
  String get shortReasonFatigue => 'Cansado';

  @override
  String get shortReasonPain => 'Dor';

  @override
  String get shortReasonOther => 'Outro';

  @override
  String get styleTitle => 'Estilo';

  @override
  String get styleAuto => 'Automático';

  @override
  String get styleAutoHint =>
      'Segue o teu telemóvel: LightFjelia de dia, DarkFjelia à noite.';

  @override
  String get connectMyWhoosh => 'Ligar MyWhoosh';

  @override
  String get myWhooshSubtitle =>
      'Inicia sessão com a tua conta MyWhoosh para trazer as saídas indoor com potência, cadência e FC.';

  @override
  String get myWhooshCredentialsInfo =>
      'As credenciais da MyWhoosh são guardadas encriptadas no teu dispositivo. A Fjelia lê as tuas saídas diretamente da MyWhoosh, através da interface da app MyWhoosh. A Fjelia não tem ligação à MyWhoosh.';

  @override
  String get myWhooshTile => 'Saídas indoor';

  @override
  String get myWhooshSignedInElsewhere =>
      'A MyWhoosh permite uma sessão por conta e tens sessão iniciada noutro dispositivo. Fecha lá a MyWhoosh (termina sessão se for preciso) e tenta novamente.';

  @override
  String get shareWorkout => 'Partilhar treino';

  @override
  String get shareFitFile => 'Partilhar como ficheiro FIT';

  @override
  String get shareFitFileHint =>
      'Para Strava, COROS, TrainingPeaks e outras apps';

  @override
  String get sendToGarmin => 'Enviar para o Garmin Connect';

  @override
  String get sendToGarminHint => 'Carrega o treino na tua conta Garmin';

  @override
  String get sentToGarmin => 'Enviado para o Garmin Connect';

  @override
  String get alreadyOnGarmin => 'Este treino já está no Garmin Connect';

  @override
  String get missedWorkoutPastTitle => 'Treino perdido';

  @override
  String get leaveIt => 'Deixar estar';

  @override
  String get reviewChange => 'Rever';

  @override
  String get keepPlan => 'Manter plano';

  @override
  String get missedYesterdayTitle => 'Perdido ontem';

  @override
  String get proposalReplanTitle => 'Reconstruir o teu plano?';

  @override
  String get proposalRestTitle => 'Dia de descanso hoje?';

  @override
  String get proposalRecoveryTitle => 'Só leve hoje?';

  @override
  String get proposalEasierTitle => 'Um pouco mais leve hoje?';

  @override
  String get proposalReplanBody =>
      'A carga ou a HRV apontam para um plano reconstruído.';

  @override
  String get proposalCardTitle => 'Sugestão para hoje';

  @override
  String get replanMissed => 'Reagendar';

  @override
  String get askBeforePlanChanges => 'Perguntar antes de alterar o plano';

  @override
  String get askBeforePlanChangesHint =>
      'A prontidão e as tendências sugerem alterações, tu decides. Desligado: a Fjelia ajusta o plano sozinha.';

  @override
  String missedOnDayTitle(String day) {
    return 'Perdido em $day';
  }

  @override
  String missedPastBody(String names) {
    return '$names. Mover ou saltar?';
  }

  @override
  String proposalDropsLine(String title) {
    return '$title é retirado';
  }

  @override
  String proposalChangeLine(String from, String to) {
    return '$from → $to';
  }

  @override
  String get proposalAnswered => 'Já respondido, não há nada para decidir.';

  @override
  String get ecgTrainingWarningTitle => 'Apenas para treino';

  @override
  String get ecgTrainingWarningBody =>
      'A Fjelia não lê ECGs do ponto de vista médico. O treinador explica a FC, a HRV e a qualidade do sinal apenas para o teu treino. Não diz nada sobre doenças cardíacas ou alterações do ritmo: para isso, exporta a gravação e mostra-a a um médico.\n\nDor ou aperto no peito, falta de ar, dor no braço, maxilar ou costas, suores frios ou desmaio: liga já para o 112.\n\nA FC, a HRV e a qualidade do sinal vão para o modelo de IA escolhido nas definições de IA.';

  @override
  String get ecgQuestionTraining => 'O que diz o meu ECG sobre o treino?';

  @override
  String get ecgFollowHrv => 'O que diz a HRV sobre a minha recuperação?';

  @override
  String get ecgFollowHeartRate => 'Como evoluiu a minha FC?';

  @override
  String get bioLeanMuchYounger => 'Muito mais jovem na estrada';

  @override
  String get bioLeanYounger => 'Mais jovem na estrada';

  @override
  String get bioLeanEven => 'Mesmo no caminho certo';

  @override
  String get bioLeanOlder => 'Algum espaço para crescer';

  @override
  String get bioLeanMuchOlder => 'Muito espaço para crescer';

  @override
  String get fitnessSameAsAge => 'Em forma para a tua idade';

  @override
  String get lifespanBandTitle => 'A tua esperança de vida';

  @override
  String get lifespanBandNote =>
      'Um intervalo de estatísticas para pessoas com valores semelhantes, não uma previsão para ti.';

  @override
  String get factorHelps => 'Ajuda-te';

  @override
  String get factorSlows => 'Trava-te';

  @override
  String get bioFactorBloodPressure => 'Tensão arterial';

  @override
  String get bioFactorVisceralFat => 'Gordura visceral';

  @override
  String get bioFactorLipids => 'Lípidos no sangue';

  @override
  String get bioFactorInflammation => 'Inflamação (PCR)';

  @override
  String get bioFactorKidney => 'Função renal';

  @override
  String get bioAgeModelNote =>
      'A idade física compara o teu VO₂máx com normas por idade. A esperança de vida vem de um modelo baseado em valores de estudos: não é uma afirmação médica nem uma previsão pessoal.';

  @override
  String fitnessYoungerBy(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anos mais novo do que a tua idade',
      one: '$years ano mais novo do que a tua idade',
    );
    return '$_temp0';
  }

  @override
  String fitnessOlderBy(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anos acima da tua idade',
      one: '$years ano acima da tua idade',
    );
    return '$_temp0';
  }

  @override
  String lifespanBandYears(int low, int high) {
    return '$low–$high';
  }

  @override
  String todayAge(int age) {
    return 'Hoje $age';
  }

  @override
  String get vo2ClassBelowAvg => 'abaixo da média';

  @override
  String get vo2ClassAverage => 'média';

  @override
  String get vo2ClassAboveAvg => 'acima da média';

  @override
  String get vo2ClassGood => 'bom';

  @override
  String get vo2ClassExcellent => 'excelente';

  @override
  String get vo2ClassElite => 'elite';

  @override
  String get fjeliaProHint =>
      'O FjeliaPro dá-te informação e análises mais detalhadas.';

  @override
  String get rowingStrokeRate => 'Remadas / min';

  @override
  String rowingStrokeAverage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ø $count remadas',
      one: 'Ø 1 remada',
    );
    return '$_temp0';
  }

  @override
  String get rowingTapToSwitch => 'Toca para alternar';

  @override
  String get copyAnswer => 'Copiar resposta';

  @override
  String get answerCopied => 'Copiado ✨';

  @override
  String get coachMemories => 'Memory Cards';

  @override
  String get coachMemoriesIntro =>
      'Diz ao teu treinador o que deve saber sempre. Os teus cartões vão com cada chat.';

  @override
  String get coachMemoryNew => 'Novo cartão';

  @override
  String get coachMemoryTitle => 'Título';

  @override
  String get coachMemoryTitleHint => 'p. ex. Joelho esquerdo';

  @override
  String get coachMemoryBody => 'O que deve saber o teu treinador?';

  @override
  String get coachMemoryBodyHint =>
      'p. ex. Correr a descer dói desde a primavera. As subidas estão bem.';

  @override
  String get coachMemoryEmpty => 'Ainda sem cartões. Cria o primeiro 🔥';

  @override
  String get coachMemoryDeleteQuestion => 'Eliminar este cartão?';

  @override
  String coachMemoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartões na cabeça do treinador',
      one: '1 cartão na cabeça do treinador',
      zero: 'Sem cartões',
    );
    return '$_temp0';
  }

  @override
  String get sportSkiErg => 'SkiErg (esqui de fundo indoor)';

  @override
  String get weatherRain => 'CHUVA';

  @override
  String weatherLowHigh(int low, int high) {
    return 'Mín. $low° · Máx. $high°';
  }

  @override
  String get weatherDayPeak => 'Pico do dia';

  @override
  String get weatherDayTotal => 'Total do dia';

  @override
  String get proTagline => 'O teu treinador. A nível pro.';

  @override
  String get proBenefitCoach =>
      'Treinador IA com o modelo Pro: mais rápido, mais completo, com orçamento próprio';

  @override
  String get proBenefitMemory =>
      'Memory Cards: o que o teu treinador deve saber sempre';

  @override
  String get proBenefitEcg => 'Análise detalhada do ECG';

  @override
  String get proBenefitCopy => 'Copiar respostas com um toque';

  @override
  String get proMonthly => 'Mensal';

  @override
  String get proYearly => 'Anual';

  @override
  String proPerMonth(String price) {
    return '$price / mês';
  }

  @override
  String proPerYear(String price) {
    return '$price / ano';
  }

  @override
  String get proBestValue => 'MELHOR VALOR';

  @override
  String get proSubscribe => 'Obter FjeliaPro';

  @override
  String get proRestore => 'Restaurar compras';

  @override
  String get proManage => 'Gerir subscrição';

  @override
  String proActiveUntil(String date) {
    return 'O Pro está ativo até $date';
  }

  @override
  String get proAutoRenew =>
      'A subscrição renova-se automaticamente, a menos que a canceles pelo menos 24 horas antes do fim do período nas definições da tua conta Apple. O pagamento é cobrado na tua conta Apple.';

  @override
  String get proTerms => 'Termos de utilização';

  @override
  String get proPrivacy => 'Privacidade';

  @override
  String get proProblemStore => 'A App Store não concluiu a compra.';

  @override
  String get proProblemService =>
      'A tua compra existe, mas ainda não foi possível verificá-la. A Fjelia tenta novamente no próximo arranque.';

  @override
  String get proProblemNothing =>
      'Não há nenhuma subscrição FjeliaPro para restaurar.';

  @override
  String get proProblemNotActive => 'Esta subscrição terminou.';

  @override
  String get proUnavailable =>
      'Não é possível carregar as subscrições neste momento. Tenta novamente mais tarde.';

  @override
  String get proWelcome => 'Bem-vindo ao FjeliaPro 🔥';

  @override
  String get proUsesFjeliaAi =>
      'O modelo Pro responde quando \"Fjelia AI\" está escolhido nas definições de IA.';

  @override
  String get proToolsTitle => 'Análises Pro';

  @override
  String get proPlanCheck => 'Verificação do plano de hoje';

  @override
  String get proPlanCheckHint => 'O plano de hoje encaixa na tua recuperação?';

  @override
  String get proWeekReview => 'Revisão semanal';

  @override
  String get proWeekReviewHint =>
      'O que funcionou, o que mudar na próxima semana';

  @override
  String get proRacePlan => 'Plano de prova';

  @override
  String proRacePlanHint(String race) {
    return '$race: afinação, ritmo, alimentação';
  }

  @override
  String get proSeason => 'Análise da época';

  @override
  String get proSeasonHint => 'Objetivos, fases e riscos da tua época';

  @override
  String get proAnalysisCreate => 'Criar análise';

  @override
  String get proAnalysisRedo => 'Criar novamente';

  @override
  String proAnalysisFrom(String time) {
    return 'Criada $time';
  }

  @override
  String get proAnalysisWorking => 'O modelo grande está a analisar…';

  @override
  String get proAnalysisFailed => 'A análise não funcionou. Tenta novamente.';

  @override
  String get proBenefitPlanCheck =>
      'Proposta da manhã e verificação do plano: o treinador ajusta o treino do dia';

  @override
  String get proBenefitReview => 'Revisão semanal e análise da época';

  @override
  String get proBenefitRacePlan =>
      'Plano de prova: afinação, ritmo, alimentação';

  @override
  String get statsTitle => 'Estatísticas';

  @override
  String get statsLast4Weeks => 'Últimas 4 semanas · por semana';

  @override
  String get statsElevation => 'Desnível';

  @override
  String get statsAllTimeTotals => 'Desde sempre';

  @override
  String get statsBestEfforts => 'Melhores marcas';

  @override
  String get statsLongest => 'Mais longo';

  @override
  String get statsMostElevation => 'Mais desnível';

  @override
  String get statsNone => 'Ainda sem atividades.';

  @override
  String get proBenefitStats =>
      'Estatísticas: melhores marcas, este ano e as últimas 4 semanas';

  @override
  String get statsFourWeeks => '4 semanas';

  @override
  String get statsTickerWeek => 'por semana, últimas 4 semanas';

  @override
  String statsTickerYear(String year) {
    return 'em $year';
  }

  @override
  String statsTickerBest(String distance) {
    return 'Melhor $distance';
  }

  @override
  String get statsPerWeekShort => '/ semana';

  @override
  String get gripLeft => 'Esquerda';

  @override
  String get gripRight => 'Direita';

  @override
  String get muscleShort => 'Músculo';

  @override
  String vsYesterday(String arrow) {
    return '$arrow vs. ontem';
  }

  @override
  String get proposalProCoach => 'O treinador escreve a notificação da manhã';

  @override
  String get proposalProCoachHint =>
      'FjeliaPro: a prontidão, o plano e o contexto de saúde de hoje vão para o Fjelia AI Pro, que redige a proposta pouco depois da sincronização da manhã.';

  @override
  String get heatShort => 'Calor';

  @override
  String get coachRevisionLabel => 'Proposta do treinador';

  @override
  String get revisionBefore => 'Antes';

  @override
  String get revisionAfter => 'Depois';

  @override
  String get revisionSwapped => 'Trocado';

  @override
  String get revisionRestDay => 'Dia de descanso em vez disso';

  @override
  String get revisionDropped => 'retirado';

  @override
  String get revisionAccept => 'Aceitar';

  @override
  String revisionSets(String sets, String reps) {
    return '$sets × $reps';
  }

  @override
  String get testMorningProposal => 'Testar proposta da manhã';

  @override
  String get testMorningProposalHint =>
      'Faz agora a verificação da manhã com a prontidão em amarelo; a notificação chega em 5 segundos.';

  @override
  String get proposalRulesEasier =>
      'A recuperação ainda não está completa: os treinos de hoje ficam mais curtos e leves, o objetivo mantém-se.';

  @override
  String get proposalRulesRecovery =>
      'Sinais claros de cansaço: hoje só leve, ou descanso.';

  @override
  String get proposalCoachUnavailable =>
      'Não foi possível contactar o treinador agora; esta é a proposta segundo as regras.';

  @override
  String get revisionKeep => 'Fica como planeado';

  @override
  String get revisionAlternative => 'Alternativa';

  @override
  String get revisionTakeAlternative => 'Escolher esta em vez disso';

  @override
  String proposalForDay(String day) {
    return 'Proposta para $day';
  }

  @override
  String get proposalDayTomorrow => 'amanhã';

  @override
  String get feelingQuestion => 'Como te sentes hoje?';

  @override
  String get feelingGood => 'Bem';

  @override
  String get feelingTired => 'Cansado';

  @override
  String get feelingSore => 'Dorido';

  @override
  String get feelingIll => 'Doente';

  @override
  String get feelingShort => 'Pouco tempo';

  @override
  String get feelingAsking => 'O treinador está a pensar de novo…';

  @override
  String get proSwitchTitle => 'Usar ProAI?';

  @override
  String proSwitchBody(String provider) {
    return 'A tua subscrição FjeliaPro está ativa. O treinador deve passar a usar o ProAI em vez de $provider?';
  }

  @override
  String get proAiRouting =>
      'O FjeliaPro usa uma IA mais potente para planos de prova e de época. O teu treinador e as sugestões diárias de treino usam o modelo Pro normal.';

  @override
  String proActiveUntilShort(String date) {
    return 'Ativo até $date';
  }

  @override
  String shortSessionNote(int done, int planned) {
    return 'Mais curto do que o planeado ($done de $planned min)';
  }

  @override
  String get noteForCoach => 'Nota para o treinador (opcional)';

  @override
  String get activityNote => 'Nota';

  @override
  String get activityNoteAdd => 'Adicionar uma nota para o treinador';

  @override
  String get plusOmronBle => 'Procurar medidores de tensão BLE';

  @override
  String get plusOmronBleHint =>
      'Procure dispositivos Bluetooth padrão para medir a tensão e perfis Omron compatíveis.';

  @override
  String get sleepEcgTitle => 'Gravar sono';

  @override
  String get sleepEcgHint => 'ECG e movimento com o Polar H10';

  @override
  String get sleepEcgDescription =>
      'Regista simultaneamente o ECG a 130 Hz e o movimento em três eixos a 25 Hz. Usa o Polar H10 e mantém o iPhone dentro do alcance do Bluetooth. A estimativa das fases do sono é opcional e executada separadamente; não são calculadas a frequência respiratória nem conclusões médicas.';

  @override
  String get sleepEcgStart => 'Iniciar gravação noturna';

  @override
  String sleepEcgMotionSamples(int count) {
    return 'Amostras de movimento: $count';
  }

  @override
  String get sleepEcgKeepOpenHint =>
      'Podes sair deste ecrã enquanto a gravação continua. Mantém a Fjelia aberta no seletor de apps e o iPhone perto do H10. Forçar o fecho da app interrompe a gravação.';

  @override
  String get sleepEcgRawNote =>
      'Dados brutos do ECG e do movimento registados durante a noite. Podes iniciar separadamente uma estimativa experimental das fases do sono. Não são calculadas a frequência respiratória nem conclusões médicas.';

  @override
  String get sleepEcgExportRaw => 'Exportar CSV em bruto de ECG + movimento';

  @override
  String get sleepEcgStagesTitle => 'Fases do sono estimadas';

  @override
  String get sleepEcgStagesButton => 'Estimar fases do sono';

  @override
  String get sleepEcgStagesAgain => 'Estimar novamente';

  @override
  String get sleepEcgStagesDisclaimer =>
      'Estimativa experimental com base no ECG Polar H10, usando um modelo de investigação apenas com ECG. N1 e N2 são agrupados como sono leve. Não é uma polissonografia nem uma medição médica.';

  @override
  String get sleepEcgStagesWorking => 'A estimar fases do sono…';

  @override
  String get sleepEcgStagesFailed =>
      'Não foi possível estimar as fases do sono. Confirme se a gravação está completa e tente novamente.';

  @override
  String get replacementPreviewTitle => 'Rever treino de substituição';

  @override
  String replacementGoalLoad(String objective, int load) {
    return 'Objetivo: $objective · carga prevista $load';
  }

  @override
  String get replacementHistoryEstimate =>
      'Duração estimada a partir do teu treino recente neste desporto.';

  @override
  String get replacementFallbackEstimate =>
      'Não há dados de treino recentes suficientes para este desporto. A duração é uma estimativa prudente.';

  @override
  String get replacementRestSuggestion =>
      'Descansar pode ser a melhor opção para o teu plano de treino atual.';

  @override
  String get replacementObjectiveRecovery => 'Recuperação';

  @override
  String get replacementObjectiveBase => 'Resistência de base';

  @override
  String get replacementObjectiveTempo => 'Tempo';

  @override
  String get replacementObjectiveThreshold => 'Limiar';

  @override
  String get replacementObjectiveVo2 => 'VO₂máx';

  @override
  String get replacementObjectiveLong => 'Resistência longa';

  @override
  String get replacementWarningNoHistory =>
      'Não há histórico de carga recente suficiente para este desporto.';

  @override
  String get replacementWarningRunningCap =>
      'O volume de corrida foi limitado por prudência para reduzir o stress mecânico.';

  @override
  String get replacementWarningLong =>
      'Treinos longos ou específicos de competição não são totalmente substituíveis. Revê a corrida mais curta.';

  @override
  String get replacementWarningRace =>
      'Este treino tem prioridade de competição; o benefício específico do desporto pode não se manter.';

  @override
  String get replacementWarningSwim =>
      'Parte do estímulo aeróbio mantém-se, mas não a técnica de natação nem as exigências musculares específicas.';

  @override
  String get replacementWarningStrength =>
      'Treinos de força e de resistência não são equivalentes e não podem manter o mesmo efeito de treino.';

  @override
  String get replacementWarningNearby =>
      'Há outro treino intenso dentro de 72 horas. Verifica a recuperação e o espaçamento entre treinos.';

  @override
  String get replacementWarningWeekly =>
      'Este treino é uma grande parte da restante carga de treino prevista para esta semana.';

  @override
  String get replacementWarningLowRecovery =>
      'A tua última pontuação de recuperação guardada é baixa. Considera reduzir a intensidade ou descansar.';

  @override
  String get replacementWarningRecentVolume =>
      'A tua carga de treino dos últimos sete dias é claramente superior à dos sete dias anteriores.';

  @override
  String get replacementTrainingGoal => 'OBJETIVO DE TREINO';

  @override
  String get replacementPreviewWarnings => 'NOTAS DO PLANO';
}
