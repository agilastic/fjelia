import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_sk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('da'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('it'),
    Locale('nb'),
    Locale('sk'),
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @weatherLocation.
  ///
  /// In en, this message translates to:
  /// **'Weather & Location'**
  String get weatherLocation;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @aiAndMore.
  ///
  /// In en, this message translates to:
  /// **'AI & More'**
  String get aiAndMore;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @runSetupAgain.
  ///
  /// In en, this message translates to:
  /// **'Run setup again'**
  String get runSetupAgain;

  /// No description provided for @runSetupAgainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts, race goal and training plan'**
  String get runSetupAgainSubtitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @dataExport.
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get dataExport;

  /// No description provided for @dataExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'CSV export, backup & restore'**
  String get dataExportSubtitle;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @developerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Debug mode, diagnostics'**
  String get developerSubtitle;

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// No description provided for @debugMode.
  ///
  /// In en, this message translates to:
  /// **'Debug mode'**
  String get debugMode;

  /// No description provided for @debugModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows the DEBUG tab'**
  String get debugModeSubtitle;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportBug;

  /// No description provided for @aiCoach.
  ///
  /// In en, this message translates to:
  /// **'AI Coach'**
  String get aiCoach;

  /// No description provided for @enableAiCoach.
  ///
  /// In en, this message translates to:
  /// **'Enable AI Coach'**
  String get enableAiCoach;

  /// No description provided for @onDeviceAiOrCloud.
  ///
  /// In en, this message translates to:
  /// **'On-device AI or cloud provider'**
  String get onDeviceAiOrCloud;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @chatAndAiBriefingsUse.
  ///
  /// In en, this message translates to:
  /// **'Chat and AI briefings use Apple Intelligence on this device. No API key required. If the model is unavailable, briefings show a non-AI summary.'**
  String get chatAndAiBriefingsUse;

  /// No description provided for @briefing.
  ///
  /// In en, this message translates to:
  /// **'Briefing'**
  String get briefing;

  /// No description provided for @useAppleIntelligenceForBriefings.
  ///
  /// In en, this message translates to:
  /// **'Use Apple Intelligence for briefings'**
  String get useAppleIntelligenceForBriefings;

  /// No description provided for @useOnDeviceAiFor.
  ///
  /// In en, this message translates to:
  /// **'Use on-device AI for briefings while keeping the selected provider for chat.'**
  String get useOnDeviceAiFor;

  /// No description provided for @healthDataSharing.
  ///
  /// In en, this message translates to:
  /// **'Health data sharing'**
  String get healthDataSharing;

  /// No description provided for @askOncePerChatSession.
  ///
  /// In en, this message translates to:
  /// **'Ask once per chat session'**
  String get askOncePerChatSession;

  /// No description provided for @otherwiseAskBeforeEveryCloud.
  ///
  /// In en, this message translates to:
  /// **'Otherwise ask before every cloud message'**
  String get otherwiseAskBeforeEveryCloud;

  /// No description provided for @reportABug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportABug;

  /// No description provided for @weatherData.
  ///
  /// In en, this message translates to:
  /// **'Weather data'**
  String get weatherData;

  /// No description provided for @openSourceLibraries.
  ///
  /// In en, this message translates to:
  /// **'Open source libraries'**
  String get openSourceLibraries;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKey;

  /// No description provided for @saveApiKey.
  ///
  /// In en, this message translates to:
  /// **'Save API key'**
  String get saveApiKey;

  /// No description provided for @feedbackBugReport.
  ///
  /// In en, this message translates to:
  /// **'Feedback & bug report'**
  String get feedbackBugReport;

  /// No description provided for @reportSentThankYou.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Thank you!'**
  String get reportSentThankYou;

  /// No description provided for @weReadEveryMessageIf.
  ///
  /// In en, this message translates to:
  /// **'We read every message. If you left your email, you may get a reply.'**
  String get weReadEveryMessageIf;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @shareAnIdeaSuggestAn.
  ///
  /// In en, this message translates to:
  /// **'Share an idea, suggest an improvement, or tell us what happened and what you expected.'**
  String get shareAnIdeaSuggestAn;

  /// No description provided for @whatHappenedAndWhatDid.
  ///
  /// In en, this message translates to:
  /// **'What happened, and what did you expect?'**
  String get whatHappenedAndWhatDid;

  /// No description provided for @pleaseLeaveOutPasswordsApi.
  ///
  /// In en, this message translates to:
  /// **'Please leave out passwords, API keys and personal health readings.'**
  String get pleaseLeaveOutPasswordsApi;

  /// No description provided for @includeDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Include diagnostics'**
  String get includeDiagnostics;

  /// No description provided for @optionalLogsMayContainAccount.
  ///
  /// In en, this message translates to:
  /// **'Optional. Logs may contain account or health details. Review them below before sending.'**
  String get optionalLogsMayContainAccount;

  /// No description provided for @diagnosticsPreview.
  ///
  /// In en, this message translates to:
  /// **'DIAGNOSTICS PREVIEW'**
  String get diagnosticsPreview;

  /// No description provided for @sendingSharesYourEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Sending shares your email, subject, message and any selected diagnostics with Fjelia support at cloud.ebeling-hoppe.de.'**
  String get sendingSharesYourEmailSubject;

  /// No description provided for @copyReport.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get copyReport;

  /// No description provided for @shareReport.
  ///
  /// In en, this message translates to:
  /// **'Share report'**
  String get shareReport;

  /// No description provided for @appleHealth.
  ///
  /// In en, this message translates to:
  /// **'Apple Health'**
  String get appleHealth;

  /// No description provided for @connectedServices.
  ///
  /// In en, this message translates to:
  /// **'Connected Services'**
  String get connectedServices;

  /// No description provided for @hiloBloodPressureBle.
  ///
  /// In en, this message translates to:
  /// **'Hilo Blood Pressure BLE'**
  String get hiloBloodPressureBle;

  /// No description provided for @writeHeartDataToApple.
  ///
  /// In en, this message translates to:
  /// **'Write Heart data to Apple Health'**
  String get writeHeartDataToApple;

  /// No description provided for @writeWeightDataToApple.
  ///
  /// In en, this message translates to:
  /// **'Write Weight data to Apple Health'**
  String get writeWeightDataToApple;

  /// No description provided for @renphoScaleBle.
  ///
  /// In en, this message translates to:
  /// **'Renpho Scale (BLE)'**
  String get renphoScaleBle;

  /// No description provided for @polarH10HrvStrapBle.
  ///
  /// In en, this message translates to:
  /// **'Polar H10 (HRV strap, BLE)'**
  String get polarH10HrvStrapBle;

  /// No description provided for @dataSourcePriority.
  ///
  /// In en, this message translates to:
  /// **'Data Source Priority'**
  String get dataSourcePriority;

  /// No description provided for @whenMultipleSourcesProvideThe.
  ///
  /// In en, this message translates to:
  /// **'When multiple sources provide the same metric, the higher source wins. Drag to reorder.'**
  String get whenMultipleSourcesProvideThe;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @healthPage.
  ///
  /// In en, this message translates to:
  /// **'Health Page'**
  String get healthPage;

  /// No description provided for @loadPage.
  ///
  /// In en, this message translates to:
  /// **'Load Page'**
  String get loadPage;

  /// No description provided for @healthMonitor.
  ///
  /// In en, this message translates to:
  /// **'Health Monitor'**
  String get healthMonitor;

  /// No description provided for @hrZones.
  ///
  /// In en, this message translates to:
  /// **'HR Zones'**
  String get hrZones;

  /// No description provided for @t30MinTtAvailableSync.
  ///
  /// In en, this message translates to:
  /// **'30-min TT available — sync HR zones'**
  String get t30MinTtAvailableSync;

  /// No description provided for @lt2Lt2BpmAt.
  ///
  /// In en, this message translates to:
  /// **'LT2 {lt2} bpm · {at}'**
  String lt2Lt2BpmAt(Object lt2, Object at);

  /// No description provided for @syncLabel.
  ///
  /// In en, this message translates to:
  /// **'SYNC'**
  String get syncLabel;

  /// No description provided for @autoadjust.
  ///
  /// In en, this message translates to:
  /// **'AUTOADJUST'**
  String get autoadjust;

  /// No description provided for @zoneI.
  ///
  /// In en, this message translates to:
  /// **'Zone {i}'**
  String zoneI(Object i);

  /// No description provided for @hrZones2.
  ///
  /// In en, this message translates to:
  /// **'HR ZONES'**
  String get hrZones2;

  /// No description provided for @ageRound.
  ///
  /// In en, this message translates to:
  /// **'age {round}'**
  String ageRound(Object round);

  /// No description provided for @basics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get basics;

  /// No description provided for @updateWaistMonthlyUsedFor.
  ///
  /// In en, this message translates to:
  /// **'ⓘ Update waist monthly — used for visceral fat estimate.'**
  String get updateWaistMonthlyUsedFor;

  /// No description provided for @alcohol.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get alcohol;

  /// No description provided for @t1Drink033L.
  ///
  /// In en, this message translates to:
  /// **'1 drink ≈ 0.33 L beer / 0.2 L wine / 4 cl spirits'**
  String get t1Drink033L;

  /// No description provided for @clinicalLabsOptional.
  ///
  /// In en, this message translates to:
  /// **'Clinical labs (optional)'**
  String get clinicalLabsOptional;

  /// No description provided for @glycemic.
  ///
  /// In en, this message translates to:
  /// **'Glycemic'**
  String get glycemic;

  /// No description provided for @optimalForLongevity48.
  ///
  /// In en, this message translates to:
  /// **'Optimal for longevity: 4.8–5.4% · Prediabetes: 5.7–6.4%'**
  String get optimalForLongevity48;

  /// No description provided for @lipids.
  ///
  /// In en, this message translates to:
  /// **'Lipids'**
  String get lipids;

  /// No description provided for @apobReplacesLdlWhenBoth.
  ///
  /// In en, this message translates to:
  /// **'ApoB replaces LDL when both are entered.'**
  String get apobReplacesLdlWhenBoth;

  /// No description provided for @inflammationKidney.
  ///
  /// In en, this message translates to:
  /// **'Inflammation & Kidney'**
  String get inflammationKidney;

  /// No description provided for @changesAreSavedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Changes are saved automatically'**
  String get changesAreSavedAutomatically;

  /// No description provided for @optionalTotalClimbingForThis.
  ///
  /// In en, this message translates to:
  /// **'Optional total climbing for this race.'**
  String get optionalTotalClimbingForThis;

  /// No description provided for @moreAboutThisEvent.
  ///
  /// In en, this message translates to:
  /// **'More about this event'**
  String get moreAboutThisEvent;

  /// No description provided for @distanceOfDistancekmKm.
  ///
  /// In en, this message translates to:
  /// **'Distance of {distanceKm} km?'**
  String distanceOfDistancekmKm(Object distanceKm);

  /// No description provided for @keepDistancekmKm.
  ///
  /// In en, this message translates to:
  /// **'Keep {distanceKm} km'**
  String keepDistancekmKm(Object distanceKm);

  /// No description provided for @useLikelyKm.
  ///
  /// In en, this message translates to:
  /// **'Use {likely} km'**
  String useLikelyKm(Object likely);

  /// No description provided for @thisBackupContainsNoCalendar.
  ///
  /// In en, this message translates to:
  /// **'This backup contains no calendar activities.'**
  String get thisBackupContainsNoCalendar;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// No description provided for @exportActivitiesCsv.
  ///
  /// In en, this message translates to:
  /// **'Export activities CSV'**
  String get exportActivitiesCsv;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupRestore;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreFromBackup;

  /// No description provided for @backupRestoredRestartTheApp.
  ///
  /// In en, this message translates to:
  /// **'Backup restored. Restart the app to reload all settings.'**
  String get backupRestoredRestartTheApp;

  /// No description provided for @raceGoals.
  ///
  /// In en, this message translates to:
  /// **'Race Goals'**
  String get raceGoals;

  /// No description provided for @yourActivities.
  ///
  /// In en, this message translates to:
  /// **'Your Activities'**
  String get yourActivities;

  /// No description provided for @usedByAiCoachAnd.
  ///
  /// In en, this message translates to:
  /// **'Used by AI Coach and training plan. Plan sports marked with ✦.'**
  String get usedByAiCoachAnd;

  /// No description provided for @calendarWeekStart.
  ///
  /// In en, this message translates to:
  /// **'Calendar week start'**
  String get calendarWeekStart;

  /// No description provided for @planDefaultView.
  ///
  /// In en, this message translates to:
  /// **'Plan Default View'**
  String get planDefaultView;

  /// No description provided for @weeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly Schedule'**
  String get weeklySchedule;

  /// No description provided for @trainingdaysperweekTrainingDaysTapTo.
  ///
  /// In en, this message translates to:
  /// **'{trainingDaysPerWeek, plural, one{{trainingDaysPerWeek} training day} other{{trainingDaysPerWeek} training days}} · tap to cycle Training / Rest / Strength'**
  String trainingdaysperweekTrainingDaysTapTo(int trainingDaysPerWeek);

  /// No description provided for @updatePlanToThisSchedule.
  ///
  /// In en, this message translates to:
  /// **'Update plan to this schedule'**
  String get updatePlanToThisSchedule;

  /// No description provided for @updateStrengthSessions.
  ///
  /// In en, this message translates to:
  /// **'Update strength sessions'**
  String get updateStrengthSessions;

  /// No description provided for @sessionsPerDay.
  ///
  /// In en, this message translates to:
  /// **'Sessions per day'**
  String get sessionsPerDay;

  /// No description provided for @canYouFitTwoWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Can you fit two workouts in one day?'**
  String get canYouFitTwoWorkouts;

  /// No description provided for @strengthLoadUnit.
  ///
  /// In en, this message translates to:
  /// **'Strength load unit'**
  String get strengthLoadUnit;

  /// No description provided for @weightsThemselvesAreSetIn.
  ///
  /// In en, this message translates to:
  /// **'Weights themselves are set in each workout and remembered from your history.'**
  String get weightsThemselvesAreSetIn;

  /// No description provided for @hoursAvailableWeek.
  ///
  /// In en, this message translates to:
  /// **'Hours available / week'**
  String get hoursAvailableWeek;

  /// No description provided for @hoursperweekHWeek.
  ///
  /// In en, this message translates to:
  /// **'{hoursPerWeek} h / week'**
  String hoursperweekHWeek(Object hoursPerWeek);

  /// No description provided for @hoursperweekH.
  ///
  /// In en, this message translates to:
  /// **'{hoursPerWeek} h'**
  String hoursperweekH(Object hoursPerWeek);

  /// No description provided for @heatAcclimation.
  ///
  /// In en, this message translates to:
  /// **'Heat Acclimation'**
  String get heatAcclimation;

  /// No description provided for @showHeatAcclimation.
  ///
  /// In en, this message translates to:
  /// **'Show Heat Acclimation'**
  String get showHeatAcclimation;

  /// No description provided for @weatherEvaluatedAgainstAConfigurable.
  ///
  /// In en, this message translates to:
  /// **'Weather evaluated against a configurable location.'**
  String get weatherEvaluatedAgainstAConfigurable;

  /// No description provided for @trainingPlan.
  ///
  /// In en, this message translates to:
  /// **'Training Plan'**
  String get trainingPlan;

  /// No description provided for @regenerateReplacesFutureSessionsAnd.
  ///
  /// In en, this message translates to:
  /// **'Regenerate replaces future sessions and rebuilds from today using current settings.'**
  String get regenerateReplacesFutureSessionsAnd;

  /// No description provided for @valueUpcomingWorkoutsGenerated.
  ///
  /// In en, this message translates to:
  /// **'{value, plural, one{{value} upcoming workout generated} other{{value} upcoming workouts generated}}'**
  String valueUpcomingWorkoutsGenerated(int value);

  /// No description provided for @generationFailedCheckYourRace.
  ///
  /// In en, this message translates to:
  /// **'Generation failed. Check your race goal and try again.'**
  String get generationFailedCheckYourRace;

  /// No description provided for @deleteAllWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Delete All Workouts'**
  String get deleteAllWorkouts;

  /// No description provided for @changesAreSavedAutomatically2.
  ///
  /// In en, this message translates to:
  /// **'✓ Changes are saved automatically'**
  String get changesAreSavedAutomatically2;

  /// No description provided for @countUpcomingWorkoutsGenerated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} upcoming workout generated} other{{count} upcoming workouts generated}}'**
  String countUpcomingWorkoutsGenerated(int count);

  /// No description provided for @importRaceGoalsFromGarmin.
  ///
  /// In en, this message translates to:
  /// **'Import race goals from Garmin'**
  String get importRaceGoalsFromGarmin;

  /// No description provided for @addRaceGoal.
  ///
  /// In en, this message translates to:
  /// **'Add race goal'**
  String get addRaceGoal;

  /// No description provided for @priorityTouppercase.
  ///
  /// In en, this message translates to:
  /// **'Priority {toUpperCase}'**
  String priorityTouppercase(Object toUpperCase);

  /// No description provided for @goalsAreSharedWithAi.
  ///
  /// In en, this message translates to:
  /// **'Goals are shared with AI Coach. Priority A, B and C decide how the plan weighs your races against each other.'**
  String get goalsAreSharedWithAi;

  /// No description provided for @deletingWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Deleting workouts'**
  String get deletingWorkouts;

  /// No description provided for @cityOrTown.
  ///
  /// In en, this message translates to:
  /// **'City or town'**
  String get cityOrTown;

  /// No description provided for @eGHannoverOrPalma.
  ///
  /// In en, this message translates to:
  /// **'e.g. Hannover or Palma'**
  String get eGHannoverOrPalma;

  /// No description provided for @noCitiesFoundTryA.
  ///
  /// In en, this message translates to:
  /// **'No cities found. Try a nearby town.'**
  String get noCitiesFoundTryA;

  /// No description provided for @chooseTheLocationForThe.
  ///
  /// In en, this message translates to:
  /// **'Choose the location for the Plan forecast, radar and heat acclimation. Weather works even when heat acclimation is off.'**
  String get chooseTheLocationForThe;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @disableLocalWeatherAndLocation.
  ///
  /// In en, this message translates to:
  /// **'Disable local weather and location requests'**
  String get disableLocalWeatherAndLocation;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @followYourDeviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Follow your device location'**
  String get followYourDeviceLocation;

  /// No description provided for @fixedLocation.
  ///
  /// In en, this message translates to:
  /// **'Fixed location'**
  String get fixedLocation;

  /// No description provided for @chooseACityOrEnter.
  ///
  /// In en, this message translates to:
  /// **'Choose a city or enter coordinates'**
  String get chooseACityOrEnter;

  /// No description provided for @chooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose city'**
  String get chooseCity;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get saveLocation;

  /// No description provided for @refreshCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Refresh current location'**
  String get refreshCurrentLocation;

  /// No description provided for @citySearchOpenMeteoGeonames.
  ///
  /// In en, this message translates to:
  /// **'City search: Open-Meteo / GeoNames'**
  String get citySearchOpenMeteoGeonames;

  /// No description provided for @cityNamesOpenstreetmap.
  ///
  /// In en, this message translates to:
  /// **'City names: © OpenStreetMap'**
  String get cityNamesOpenstreetmap;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'ENERGY'**
  String get energy;

  /// No description provided for @currentEnergy.
  ///
  /// In en, this message translates to:
  /// **'CURRENT ENERGY'**
  String get currentEnergy;

  /// No description provided for @dailyTimeline.
  ///
  /// In en, this message translates to:
  /// **'DAILY TIMELINE'**
  String get dailyTimeline;

  /// No description provided for @valueValue2.
  ///
  /// In en, this message translates to:
  /// **'{value} → {value2}'**
  String valueValue2(Object value, Object value2);

  /// No description provided for @energy2.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy2;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @bloodPressureInsights.
  ///
  /// In en, this message translates to:
  /// **'BLOOD PRESSURE INSIGHTS'**
  String get bloodPressureInsights;

  /// No description provided for @sys.
  ///
  /// In en, this message translates to:
  /// **' Sys'**
  String get sys;

  /// No description provided for @diaMmhg.
  ///
  /// In en, this message translates to:
  /// **' Dia · mmHg'**
  String get diaMmhg;

  /// No description provided for @previousBloodPressurePeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous blood-pressure period'**
  String get previousBloodPressurePeriod;

  /// No description provided for @nextBloodPressurePeriod.
  ///
  /// In en, this message translates to:
  /// **'Next blood-pressure period'**
  String get nextBloodPressurePeriod;

  /// No description provided for @nightDipping.
  ///
  /// In en, this message translates to:
  /// **'Night Dipping'**
  String get nightDipping;

  /// No description provided for @noMeasurementsInThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No measurements in this period'**
  String get noMeasurementsInThisPeriod;

  /// No description provided for @fullscreenBloodPressureChart.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen blood-pressure chart'**
  String get fullscreenBloodPressureChart;

  /// No description provided for @barsMinMaxLineDots.
  ///
  /// In en, this message translates to:
  /// **'Bars: min–max · line/dots: average · tap or drag to inspect'**
  String get barsMinMaxLineDots;

  /// No description provided for @noMeasurements.
  ///
  /// In en, this message translates to:
  /// **'No measurements'**
  String get noMeasurements;

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'{round}'**
  String round(Object round);

  /// No description provided for @sysSys2Mmhg.
  ///
  /// In en, this message translates to:
  /// **'{sys}–{sys2} mmHg'**
  String sysSys2Mmhg(Object sys, Object sys2);

  /// No description provided for @lengthReadingsAverageMinMax.
  ///
  /// In en, this message translates to:
  /// **'{length, plural, one{{length} reading} other{{length} readings}} · average / min–max'**
  String lengthReadingsAverageMinMax(int length);

  /// No description provided for @bloodPressureTouppercaseMmhg.
  ///
  /// In en, this message translates to:
  /// **'BLOOD PRESSURE · {toUpperCase} · mmHg'**
  String bloodPressureTouppercaseMmhg(Object toUpperCase);

  /// No description provided for @closeFullscreenBloodPressureChart.
  ///
  /// In en, this message translates to:
  /// **'Close fullscreen blood-pressure chart'**
  String get closeFullscreenBloodPressureChart;

  /// No description provided for @chooseScale.
  ///
  /// In en, this message translates to:
  /// **'Choose scale'**
  String get chooseScale;

  /// No description provided for @noScalesFoundStepOn.
  ///
  /// In en, this message translates to:
  /// **'No scales found. Step on your scale and try again.'**
  String get noScalesFoundStepOn;

  /// No description provided for @nameRssiDbm.
  ///
  /// In en, this message translates to:
  /// **'{name} · {rssi} dBm'**
  String nameRssiDbm(Object name, Object rssi);

  /// No description provided for @renphoSaved.
  ///
  /// In en, this message translates to:
  /// **'RENPHO saved:'**
  String get renphoSaved;

  /// No description provided for @renphoScaleBle2.
  ///
  /// In en, this message translates to:
  /// **'RENPHO Scale (BLE)'**
  String get renphoScaleBle2;

  /// No description provided for @changeMeasurementType.
  ///
  /// In en, this message translates to:
  /// **'Change measurement type'**
  String get changeMeasurementType;

  /// No description provided for @addMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Add Measurement'**
  String get addMeasurement;

  /// No description provided for @whatAreYouMeasuring.
  ///
  /// In en, this message translates to:
  /// **'What are you measuring?'**
  String get whatAreYouMeasuring;

  /// No description provided for @chooseAnotherMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Choose another measurement'**
  String get chooseAnotherMeasurement;

  /// No description provided for @saveMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Save measurement'**
  String get saveMeasurement;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @connectHiloService.
  ///
  /// In en, this message translates to:
  /// **'Connect Hilo Service'**
  String get connectHiloService;

  /// No description provided for @connectHilo.
  ///
  /// In en, this message translates to:
  /// **'Connect Hilo'**
  String get connectHilo;

  /// No description provided for @connectCoros.
  ///
  /// In en, this message translates to:
  /// **'Connect Coros'**
  String get connectCoros;

  /// No description provided for @europe.
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get europe;

  /// No description provided for @unitedStates.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get unitedStates;

  /// No description provided for @asia.
  ///
  /// In en, this message translates to:
  /// **'Asia'**
  String get asia;

  /// No description provided for @bluetoothBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth · blood pressure'**
  String get bluetoothBloodPressure;

  /// No description provided for @cloudCuffData.
  ///
  /// In en, this message translates to:
  /// **'Cloud · cuff data'**
  String get cloudCuffData;

  /// No description provided for @apiSync.
  ///
  /// In en, this message translates to:
  /// **'API sync'**
  String get apiSync;

  /// No description provided for @bluetoothHrvStrap.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth · HRV strap'**
  String get bluetoothHrvStrap;

  /// No description provided for @accesslinkApi.
  ///
  /// In en, this message translates to:
  /// **'AccessLink API'**
  String get accesslinkApi;

  /// No description provided for @systemHealthData.
  ///
  /// In en, this message translates to:
  /// **'System health data'**
  String get systemHealthData;

  /// No description provided for @cloudScaleHistory.
  ///
  /// In en, this message translates to:
  /// **'Cloud · scale history'**
  String get cloudScaleHistory;

  /// No description provided for @bluetoothWeightBody.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth · weight & body'**
  String get bluetoothWeightBody;

  /// No description provided for @connectYourDevices.
  ///
  /// In en, this message translates to:
  /// **'Connect your devices'**
  String get connectYourDevices;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @connectGarmin.
  ///
  /// In en, this message translates to:
  /// **'Connect Garmin'**
  String get connectGarmin;

  /// No description provided for @connectAppleHealth.
  ///
  /// In en, this message translates to:
  /// **'Connect Apple Health'**
  String get connectAppleHealth;

  /// No description provided for @dataSynced.
  ///
  /// In en, this message translates to:
  /// **'DATA SYNCED'**
  String get dataSynced;

  /// No description provided for @pairHiloPod.
  ///
  /// In en, this message translates to:
  /// **'Pair Hilo Pod'**
  String get pairHiloPod;

  /// No description provided for @chooseStrap.
  ///
  /// In en, this message translates to:
  /// **'Choose strap'**
  String get chooseStrap;

  /// No description provided for @namePaired.
  ///
  /// In en, this message translates to:
  /// **'{name} paired.'**
  String namePaired(Object name);

  /// No description provided for @pairPolarH10.
  ///
  /// In en, this message translates to:
  /// **'Pair Polar H10'**
  String get pairPolarH10;

  /// No description provided for @forget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forget;

  /// No description provided for @sendWorkoutToPolar.
  ///
  /// In en, this message translates to:
  /// **'Send workout to Polar'**
  String get sendWorkoutToPolar;

  /// No description provided for @connectPolar.
  ///
  /// In en, this message translates to:
  /// **'Connect Polar'**
  String get connectPolar;

  /// No description provided for @signInWithPolarFlow.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Polar Flow'**
  String get signInWithPolarFlow;

  /// No description provided for @syncsSleepStagesHrvResting.
  ///
  /// In en, this message translates to:
  /// **'Syncs sleep stages · HRV · resting HR · workouts · steps'**
  String get syncsSleepStagesHrvResting;

  /// No description provided for @savedForV.
  ///
  /// In en, this message translates to:
  /// **'Saved for {v}'**
  String savedForV(Object v);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @polarEMail.
  ///
  /// In en, this message translates to:
  /// **'Polar e-mail'**
  String get polarEMail;

  /// No description provided for @polarPassword.
  ///
  /// In en, this message translates to:
  /// **'Polar password'**
  String get polarPassword;

  /// No description provided for @pairRenphoScale.
  ///
  /// In en, this message translates to:
  /// **'Pair RENPHO Scale'**
  String get pairRenphoScale;

  /// No description provided for @connectRenpho.
  ///
  /// In en, this message translates to:
  /// **'Connect Renpho'**
  String get connectRenpho;

  /// No description provided for @connectSuunto.
  ///
  /// In en, this message translates to:
  /// **'Connect Suunto'**
  String get connectSuunto;

  /// No description provided for @smsSentToTrim.
  ///
  /// In en, this message translates to:
  /// **'SMS sent to {trim}'**
  String smsSentToTrim(Object trim);

  /// No description provided for @resendSms.
  ///
  /// In en, this message translates to:
  /// **'Resend SMS'**
  String get resendSms;

  /// No description provided for @retryLoadingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Retry loading preferences'**
  String get retryLoadingPreferences;

  /// No description provided for @weeklyTrainingTimeTostringasfixedH.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY TRAINING TIME · {toStringAsFixed} h'**
  String weeklyTrainingTimeTostringasfixedH(Object toStringAsFixed);

  /// No description provided for @tapADayToCycle.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to cycle Training / Rest / Strength.'**
  String get tapADayToCycle;

  /// No description provided for @doubleDayOk.
  ///
  /// In en, this message translates to:
  /// **'Double day ok'**
  String get doubleDayOk;

  /// No description provided for @birthYearOptional.
  ///
  /// In en, this message translates to:
  /// **'Birth year (optional)'**
  String get birthYearOptional;

  /// No description provided for @addAnother.
  ///
  /// In en, this message translates to:
  /// **'Add another'**
  String get addAnother;

  /// No description provided for @knowYourBodyTrainSmarter.
  ///
  /// In en, this message translates to:
  /// **'Know your body.\nTrain smarter.'**
  String get knowYourBodyTrainSmarter;

  /// No description provided for @allYourHealthDevicesOne.
  ///
  /// In en, this message translates to:
  /// **'All your health devices. One intelligent view.'**
  String get allYourHealthDevicesOne;

  /// No description provided for @areYouReadyToTrain.
  ///
  /// In en, this message translates to:
  /// **'Are you ready to train today?'**
  String get areYouReadyToTrain;

  /// No description provided for @hrvRecoveryScoreRestingHr.
  ///
  /// In en, this message translates to:
  /// **'HRV · Recovery Score · Resting HR'**
  String get hrvRecoveryScoreRestingHr;

  /// No description provided for @didYouActuallyRecoverLast.
  ///
  /// In en, this message translates to:
  /// **'Did you actually recover last night?'**
  String get didYouActuallyRecoverLast;

  /// No description provided for @sleepStagesDeepSleepSpo.
  ///
  /// In en, this message translates to:
  /// **'Sleep Stages · Deep Sleep · SpO₂'**
  String get sleepStagesDeepSleepSpo;

  /// No description provided for @isYourBloodPressureUnder.
  ///
  /// In en, this message translates to:
  /// **'Is your blood pressure under control?'**
  String get isYourBloodPressureUnder;

  /// No description provided for @continuousBpNightDippingTrends.
  ///
  /// In en, this message translates to:
  /// **'Continuous BP · Night Dipping · Trends'**
  String get continuousBpNightDippingTrends;

  /// No description provided for @howHardDidYouPush.
  ///
  /// In en, this message translates to:
  /// **'How hard did you push this week?'**
  String get howHardDidYouPush;

  /// No description provided for @trainingLoadTrimpStrainScore.
  ///
  /// In en, this message translates to:
  /// **'Training Load · TRIMP · Strain Score'**
  String get trainingLoadTrimpStrainScore;

  /// No description provided for @isYourBodyCompositionImproving.
  ///
  /// In en, this message translates to:
  /// **'Is your body composition improving?'**
  String get isYourBodyCompositionImproving;

  /// No description provided for @weightBodyFatMuscleMass.
  ///
  /// In en, this message translates to:
  /// **'Weight · Body Fat · Muscle Mass'**
  String get weightBodyFatMuscleMass;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @yourDataStaysOnYour.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on your device. Always private.'**
  String get yourDataStaysOnYour;

  /// No description provided for @bodyScale.
  ///
  /// In en, this message translates to:
  /// **'Body Scale'**
  String get bodyScale;

  /// No description provided for @bodyComposition.
  ///
  /// In en, this message translates to:
  /// **'Body Composition'**
  String get bodyComposition;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'SLEEP'**
  String get sleep;

  /// No description provided for @sleepPerformance.
  ///
  /// In en, this message translates to:
  /// **'SLEEP PERFORMANCE'**
  String get sleepPerformance;

  /// No description provided for @sleepHistory.
  ///
  /// In en, this message translates to:
  /// **'Sleep history'**
  String get sleepHistory;

  /// No description provided for @labelValue.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String labelValue(Object label, Object value);

  /// No description provided for @lessLabel.
  ///
  /// In en, this message translates to:
  /// **'Less {label}'**
  String lessLabel(Object label);

  /// No description provided for @moreLabel.
  ///
  /// In en, this message translates to:
  /// **'More {label}'**
  String moreLabel(Object label);

  /// No description provided for @gymMode.
  ///
  /// In en, this message translates to:
  /// **'Gym mode'**
  String get gymMode;

  /// No description provided for @finishWorkout.
  ///
  /// In en, this message translates to:
  /// **'Finish workout'**
  String get finishWorkout;

  /// No description provided for @workoutActions.
  ///
  /// In en, this message translates to:
  /// **'Workout actions'**
  String get workoutActions;

  /// No description provided for @discardWorkout.
  ///
  /// In en, this message translates to:
  /// **'Discard workout'**
  String get discardWorkout;

  /// No description provided for @allSetsRecorded.
  ///
  /// In en, this message translates to:
  /// **'All sets recorded'**
  String get allSetsRecorded;

  /// No description provided for @reviewSets.
  ///
  /// In en, this message translates to:
  /// **'Review sets'**
  String get reviewSets;

  /// No description provided for @rest.
  ///
  /// In en, this message translates to:
  /// **'REST'**
  String get rest;

  /// No description provided for @plannedResttarget.
  ///
  /// In en, this message translates to:
  /// **'Planned {restTarget}'**
  String plannedResttarget(Object restTarget);

  /// No description provided for @startSet.
  ///
  /// In en, this message translates to:
  /// **'Start set'**
  String get startSet;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get seconds;

  /// No description provided for @previousSet.
  ///
  /// In en, this message translates to:
  /// **'Previous set'**
  String get previousSet;

  /// No description provided for @allSets.
  ///
  /// In en, this message translates to:
  /// **'All sets'**
  String get allSets;

  /// No description provided for @nextSet.
  ///
  /// In en, this message translates to:
  /// **'Next set'**
  String get nextSet;

  /// No description provided for @everySetIsSavedAs.
  ///
  /// In en, this message translates to:
  /// **'Every set is saved as you go. Close this screen any time and resume from the planned workout.'**
  String get everySetIsSavedAs;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @effortScale.
  ///
  /// In en, this message translates to:
  /// **'Effort scale'**
  String get effortScale;

  /// No description provided for @setType.
  ///
  /// In en, this message translates to:
  /// **'Set type'**
  String get setType;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @range.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get range;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @t45Or100.
  ///
  /// In en, this message translates to:
  /// **'45 or 1:00'**
  String get t45Or100;

  /// No description provided for @blankWhenNotSet.
  ///
  /// In en, this message translates to:
  /// **'Blank when not set'**
  String get blankWhenNotSet;

  /// No description provided for @redBand.
  ///
  /// In en, this message translates to:
  /// **'Red band'**
  String get redBand;

  /// No description provided for @t90Or130.
  ///
  /// In en, this message translates to:
  /// **'90 or 1:30'**
  String get t90Or130;

  /// No description provided for @blankWhenUnknown.
  ///
  /// In en, this message translates to:
  /// **'Blank when unknown'**
  String get blankWhenUnknown;

  /// No description provided for @usePlannedLoad.
  ///
  /// In en, this message translates to:
  /// **'Use planned load'**
  String get usePlannedLoad;

  /// No description provided for @blankWhenNotMeasured.
  ///
  /// In en, this message translates to:
  /// **'Blank when not measured'**
  String get blankWhenNotMeasured;

  /// No description provided for @exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercise;

  /// No description provided for @changingTheLoadConventionStarts.
  ///
  /// In en, this message translates to:
  /// **'Changing the load convention starts a separate history for this exercise.'**
  String get changingTheLoadConventionStarts;

  /// No description provided for @barbellMachine.
  ///
  /// In en, this message translates to:
  /// **'Barbell, machine…'**
  String get barbellMachine;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @loadRefersTo.
  ///
  /// In en, this message translates to:
  /// **'Load refers to'**
  String get loadRefersTo;

  /// No description provided for @t2ForAPair.
  ///
  /// In en, this message translates to:
  /// **'2 for a pair'**
  String get t2ForAPair;

  /// No description provided for @repetitions.
  ///
  /// In en, this message translates to:
  /// **'Repetitions'**
  String get repetitions;

  /// No description provided for @availablePlatesOrDumbbells.
  ///
  /// In en, this message translates to:
  /// **'Available plates or dumbbells'**
  String get availablePlatesOrDumbbells;

  /// No description provided for @rememberForThisEquipment.
  ///
  /// In en, this message translates to:
  /// **'Remember for this equipment'**
  String get rememberForThisEquipment;

  /// No description provided for @findOrNameAnExercise.
  ///
  /// In en, this message translates to:
  /// **'Find or name an exercise'**
  String get findOrNameAnExercise;

  /// No description provided for @createTrim.
  ///
  /// In en, this message translates to:
  /// **'Create “{trim}”'**
  String createTrim(Object trim);

  /// No description provided for @customExercise.
  ///
  /// In en, this message translates to:
  /// **'Custom exercise'**
  String get customExercise;

  /// No description provided for @smallestLoadStep.
  ///
  /// In en, this message translates to:
  /// **'Smallest load step'**
  String get smallestLoadStep;

  /// No description provided for @whatRemoved.
  ///
  /// In en, this message translates to:
  /// **'{what} removed'**
  String whatRemoved(Object what);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExercise;

  /// No description provided for @finishLog.
  ///
  /// In en, this message translates to:
  /// **'Finish log'**
  String get finishLog;

  /// No description provided for @keepAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Keep as draft'**
  String get keepAsDraft;

  /// No description provided for @actionsForName.
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String actionsForName(Object name);

  /// No description provided for @editExercise.
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get editExercise;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get addSet;

  /// No description provided for @removeLastSet.
  ///
  /// In en, this message translates to:
  /// **'Remove last set'**
  String get removeLastSet;

  /// No description provided for @saveAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as template'**
  String get saveAsTemplate;

  /// No description provided for @savedTitleAsATemplate.
  ///
  /// In en, this message translates to:
  /// **'Saved “{title}” as a template. This workout is unchanged until you save it.'**
  String savedTitleAsATemplate(Object title);

  /// No description provided for @nameSetN.
  ///
  /// In en, this message translates to:
  /// **'{name} · Set {n}'**
  String nameSetN(Object name, Object n);

  /// No description provided for @nameAllWorkingSets.
  ///
  /// In en, this message translates to:
  /// **'{name} · All working sets'**
  String nameAllWorkingSets(Object name);

  /// No description provided for @labelRest.
  ///
  /// In en, this message translates to:
  /// **'{label} rest'**
  String labelRest(Object label);

  /// No description provided for @secondsOrMSs.
  ///
  /// In en, this message translates to:
  /// **'Seconds or m:ss'**
  String get secondsOrMSs;

  /// No description provided for @applyToAllSets.
  ///
  /// In en, this message translates to:
  /// **'Apply to all sets'**
  String get applyToAllSets;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @supersetWithNext.
  ///
  /// In en, this message translates to:
  /// **'Superset with next'**
  String get supersetWithNext;

  /// No description provided for @circuitWithNext.
  ///
  /// In en, this message translates to:
  /// **'Circuit with next'**
  String get circuitWithNext;

  /// No description provided for @actionsForSetN.
  ///
  /// In en, this message translates to:
  /// **'Actions for set {n}'**
  String actionsForSetN(Object n);

  /// No description provided for @editSet.
  ///
  /// In en, this message translates to:
  /// **'Edit set'**
  String get editSet;

  /// No description provided for @duplicateSet.
  ///
  /// In en, this message translates to:
  /// **'Duplicate set'**
  String get duplicateSet;

  /// No description provided for @removeSet.
  ///
  /// In en, this message translates to:
  /// **'Remove set'**
  String get removeSet;

  /// No description provided for @labelActions.
  ///
  /// In en, this message translates to:
  /// **'{label} actions'**
  String labelActions(Object label);

  /// No description provided for @editRests.
  ///
  /// In en, this message translates to:
  /// **'Edit rests'**
  String get editRests;

  /// No description provided for @ungroup.
  ///
  /// In en, this message translates to:
  /// **'Ungroup'**
  String get ungroup;

  /// No description provided for @editExercises.
  ///
  /// In en, this message translates to:
  /// **'Edit exercises'**
  String get editExercises;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @couldNotSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String couldNotSaveError(Object error);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// No description provided for @noExercisesArePlannedFor.
  ///
  /// In en, this message translates to:
  /// **'No exercises are planned for this workout yet. The notes above describe it.'**
  String get noExercisesArePlannedFor;

  /// No description provided for @addExercises.
  ///
  /// In en, this message translates to:
  /// **'Add exercises'**
  String get addExercises;

  /// No description provided for @fromTheBuiltInTemplate.
  ///
  /// In en, this message translates to:
  /// **'From the built-in template. Loads are yours to set; history appears once you log a workout.'**
  String get fromTheBuiltInTemplate;

  /// No description provided for @shareExerciseList.
  ///
  /// In en, this message translates to:
  /// **'Share exercise list'**
  String get shareExerciseList;

  /// No description provided for @noSavedStrengthTemplatesYet.
  ///
  /// In en, this message translates to:
  /// **'No saved strength templates yet. Save one from a planned workout first.'**
  String get noSavedStrengthTemplatesYet;

  /// No description provided for @compareWith.
  ///
  /// In en, this message translates to:
  /// **'Compare with'**
  String get compareWith;

  /// No description provided for @estimated1rmUnit.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM {unit}'**
  String estimated1rmUnit(Object unit);

  /// No description provided for @plannedNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Planned, not recorded'**
  String get plannedNotRecorded;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @editPerformance.
  ///
  /// In en, this message translates to:
  /// **'Edit performance'**
  String get editPerformance;

  /// No description provided for @compareWithASavedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Compare with a saved workout'**
  String get compareWithASavedWorkout;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @radarUnavailableRetry.
  ///
  /// In en, this message translates to:
  /// **'Radar unavailable · Retry'**
  String get radarUnavailableRetry;

  /// No description provided for @radar.
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get radar;

  /// No description provided for @weatherDataByRainviewer.
  ///
  /// In en, this message translates to:
  /// **'Weather data by RainViewer'**
  String get weatherDataByRainviewer;

  /// No description provided for @openstreetmapContributors.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get openstreetmapContributors;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @weatherUnavailableRetry.
  ///
  /// In en, this message translates to:
  /// **'Weather unavailable · Retry'**
  String get weatherUnavailableRetry;

  /// No description provided for @chooseAFixedLocationIn.
  ///
  /// In en, this message translates to:
  /// **'Choose a fixed location in Weather & Location settings, or allow location access for local weather.'**
  String get chooseAFixedLocationIn;

  /// No description provided for @locationSettings.
  ///
  /// In en, this message translates to:
  /// **'Location settings'**
  String get locationSettings;

  /// No description provided for @retryLocation.
  ///
  /// In en, this message translates to:
  /// **'Retry location'**
  String get retryLocation;

  /// No description provided for @round2.
  ///
  /// In en, this message translates to:
  /// **'{round}°'**
  String round2(Object round);

  /// No description provided for @roundRhRound2Hpa.
  ///
  /// In en, this message translates to:
  /// **'{round}% RH · {round2} hPa'**
  String roundRhRound2Hpa(Object round, Object round2);

  /// No description provided for @wetBulbTostringasfixedC.
  ///
  /// In en, this message translates to:
  /// **'Wet-bulb {toStringAsFixed}°C'**
  String wetBulbTostringasfixedC(Object toStringAsFixed);

  /// No description provided for @previousForecastDay.
  ///
  /// In en, this message translates to:
  /// **'Previous forecast day'**
  String get previousForecastDay;

  /// No description provided for @nextForecastDay.
  ///
  /// In en, this message translates to:
  /// **'Next forecast day'**
  String get nextForecastDay;

  /// No description provided for @daysDayForecast.
  ///
  /// In en, this message translates to:
  /// **'{days}-Day Forecast'**
  String daysDayForecast(Object days);

  /// No description provided for @thisProviderCurrentlySuppliesDays.
  ///
  /// In en, this message translates to:
  /// **'This provider currently supplies {days} of {days2} forecast days.'**
  String thisProviderCurrentlySuppliesDays(Object days, Object days2);

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @sunriseSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunrise / Sunset'**
  String get sunriseSunset;

  /// No description provided for @keyKey2.
  ///
  /// In en, this message translates to:
  /// **'☀ {key}   ☾ {key2}'**
  String keyKey2(Object key, Object key2);

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @exerciseDetailsWereNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Exercise details were not provided by this activity source.'**
  String get exerciseDetailsWereNotProvided;

  /// No description provided for @logFromPlan.
  ///
  /// In en, this message translates to:
  /// **'Log from plan'**
  String get logFromPlan;

  /// No description provided for @addExerciseDetails.
  ///
  /// In en, this message translates to:
  /// **'Add exercise details'**
  String get addExerciseDetails;

  /// No description provided for @loadSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Load suggestion'**
  String get loadSuggestion;

  /// No description provided for @applyToThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'Apply to this workout'**
  String get applyToThisWorkout;

  /// No description provided for @keepCurrentLoad.
  ///
  /// In en, this message translates to:
  /// **'Keep current load'**
  String get keepCurrentLoad;

  /// No description provided for @setLoadStep.
  ///
  /// In en, this message translates to:
  /// **'Set load step'**
  String get setLoadStep;

  /// No description provided for @viewSupportingSets.
  ///
  /// In en, this message translates to:
  /// **'View supporting sets'**
  String get viewSupportingSets;

  /// No description provided for @supportingSets.
  ///
  /// In en, this message translates to:
  /// **'Supporting sets'**
  String get supportingSets;

  /// No description provided for @noRecordedSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No recorded sessions yet.'**
  String get noRecordedSessionsYet;

  /// No description provided for @nameDemonstrationCue.
  ///
  /// In en, this message translates to:
  /// **'{name} demonstration. {cue}'**
  String nameDemonstrationCue(Object name, Object cue);

  /// No description provided for @noScalesFoundStepOn2.
  ///
  /// In en, this message translates to:
  /// **'No scales found. Step on the scale and try again.'**
  String get noScalesFoundStepOn2;

  /// No description provided for @scalePaired.
  ///
  /// In en, this message translates to:
  /// **'Scale paired'**
  String get scalePaired;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @pairedReadyToMeasure.
  ///
  /// In en, this message translates to:
  /// **'✓ Paired — ready to measure'**
  String get pairedReadyToMeasure;

  /// No description provided for @chooseHiloCuff.
  ///
  /// In en, this message translates to:
  /// **'Choose Hilo cuff'**
  String get chooseHiloCuff;

  /// No description provided for @noCuffFoundWakeYour.
  ///
  /// In en, this message translates to:
  /// **'No cuff found. Wake your cuff and try scanning again.'**
  String get noCuffFoundWakeYour;

  /// No description provided for @hiloCuffAktiiaC.
  ///
  /// In en, this message translates to:
  /// **'Hilo cuff (AKTIIA C…)'**
  String get hiloCuffAktiiaC;

  /// No description provided for @onDemandBloodPressureVia.
  ///
  /// In en, this message translates to:
  /// **'On-demand blood pressure via BLE'**
  String get onDemandBloodPressureVia;

  /// No description provided for @selectHiloPodWristband.
  ///
  /// In en, this message translates to:
  /// **'Select Hilo Pod (Wristband)'**
  String get selectHiloPodWristband;

  /// No description provided for @rescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get rescan;

  /// No description provided for @noDevicesFoundTapTo.
  ///
  /// In en, this message translates to:
  /// **'No devices found. Tap ↻ to scan again.'**
  String get noDevicesFoundTapTo;

  /// No description provided for @polarH10SpotHrv.
  ///
  /// In en, this message translates to:
  /// **'Polar H10 · Spot HRV'**
  String get polarH10SpotHrv;

  /// No description provided for @aSeparateHrvReadingBefore.
  ///
  /// In en, this message translates to:
  /// **'A separate HRV reading before or after training. These measurements do not replace Garmin overnight HRV or change your readiness score.'**
  String get aSeparateHrvReadingBefore;

  /// No description provided for @wearTheStrapWithMoist.
  ///
  /// In en, this message translates to:
  /// **'Wear the strap with moist electrodes. Keep still and breathe normally. Use the same posture and recording length for comparisons. After training, note how long you rested first.'**
  String get wearTheStrapWithMoist;

  /// No description provided for @measurement.
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get measurement;

  /// No description provided for @posture.
  ///
  /// In en, this message translates to:
  /// **'Posture'**
  String get posture;

  /// No description provided for @recordingLengthPlus1Min.
  ///
  /// In en, this message translates to:
  /// **'Recording length · plus 1 min settling'**
  String get recordingLengthPlus1Min;

  /// No description provided for @t2Minutes.
  ///
  /// In en, this message translates to:
  /// **'2 minutes'**
  String get t2Minutes;

  /// No description provided for @t5Minutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get t5Minutes;

  /// No description provided for @minutesSinceTrainingEndedOptional.
  ///
  /// In en, this message translates to:
  /// **'Minutes since training ended (optional)'**
  String get minutesSinceTrainingEndedOptional;

  /// No description provided for @sessionOrNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Session or notes (optional)'**
  String get sessionOrNotesOptional;

  /// No description provided for @connectName.
  ///
  /// In en, this message translates to:
  /// **'Connect {name}'**
  String connectName(Object name);

  /// No description provided for @findPolarH10.
  ///
  /// In en, this message translates to:
  /// **'Find Polar H10'**
  String get findPolarH10;

  /// No description provided for @signalRssiDbm.
  ///
  /// In en, this message translates to:
  /// **'Signal {rssi} dBm'**
  String signalRssiDbm(Object rssi);

  /// No description provided for @connectedName.
  ///
  /// In en, this message translates to:
  /// **'Connected: {name}'**
  String connectedName(Object name);

  /// No description provided for @waitingForHeartRateAnd.
  ///
  /// In en, this message translates to:
  /// **'Waiting for heart rate and RR intervals. Check the strap contact.'**
  String get waitingForHeartRateAnd;

  /// No description provided for @startMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Start measurement'**
  String get startMeasurement;

  /// No description provided for @cancelMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Cancel measurement'**
  String get cancelMeasurement;

  /// No description provided for @spotHrvRmssd.
  ///
  /// In en, this message translates to:
  /// **'Spot HRV · RMSSD'**
  String get spotHrvRmssd;

  /// No description provided for @acceptedLengthUsableIntervalsTostringasfixed.
  ///
  /// In en, this message translates to:
  /// **'{accepted}/{length} usable intervals · {toStringAsFixed}% coverage'**
  String acceptedLengthUsableIntervalsTostringasfixed(
    Object accepted,
    Object length,
    Object toStringAsFixed,
  );

  /// No description provided for @lnrmssdLnrmssdRawRmssdRawrmssdms.
  ///
  /// In en, this message translates to:
  /// **'lnRMSSD: {lnRmssd} · Raw RMSSD: {rawRmssdMs} ms'**
  String lnrmssdLnrmssdRawRmssdRawrmssdms(Object lnRmssd, Object rawRmssdMs);

  /// No description provided for @signalQualityIsTooLow.
  ///
  /// In en, this message translates to:
  /// **'Signal quality is too low to save. Repeat the measurement with good strap contact. At least 95% usable intervals and 90% coverage are required.'**
  String get signalQualityIsTooLow;

  /// No description provided for @savedToSpotHrvHistory.
  ///
  /// In en, this message translates to:
  /// **'Saved to spot HRV history.'**
  String get savedToSpotHrvHistory;

  /// No description provided for @newMeasurement.
  ///
  /// In en, this message translates to:
  /// **'New measurement'**
  String get newMeasurement;

  /// No description provided for @signalScreeningExcludesPoorContact.
  ///
  /// In en, this message translates to:
  /// **'Signal screening excludes poor contact, RR outside 250–2500 ms and intervals more than 25% from the local median. Gaps are not bridged. This is not a medical test or a standalone readiness score.'**
  String get signalScreeningExcludesPoorContact;

  /// No description provided for @historyLabelLabel2DurationMin.
  ///
  /// In en, this message translates to:
  /// **'History · {label} · {label2} · {duration} min'**
  String historyLabelLabel2DurationMin(
    Object label,
    Object label2,
    Object duration,
  );

  /// No description provided for @onlyReadingsWithTheSame.
  ///
  /// In en, this message translates to:
  /// **'Only readings with the same context, posture and duration are shown together.'**
  String get onlyReadingsWithTheSame;

  /// No description provided for @noMatchingMeasurementsYet.
  ///
  /// In en, this message translates to:
  /// **'No matching measurements yet.'**
  String get noMatchingMeasurementsYet;

  /// No description provided for @tostringasfixedMsRmssdTostringasfixed2Bpm.
  ///
  /// In en, this message translates to:
  /// **'{toStringAsFixed} ms RMSSD · {toStringAsFixed2} bpm'**
  String tostringasfixedMsRmssdTostringasfixed2Bpm(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  );

  /// No description provided for @exportRrIntervalsCsv.
  ///
  /// In en, this message translates to:
  /// **'Export RR intervals (CSV)'**
  String get exportRrIntervalsCsv;

  /// No description provided for @deleteMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Delete measurement'**
  String get deleteMeasurement;

  /// No description provided for @remindMeToMeasureHrv.
  ///
  /// In en, this message translates to:
  /// **'Remind me to measure HRV after training'**
  String get remindMeToMeasureHrv;

  /// No description provided for @appleHealthIsNoLonger.
  ///
  /// In en, this message translates to:
  /// **'Apple Health is no longer available'**
  String get appleHealthIsNoLonger;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @gripStrength.
  ///
  /// In en, this message translates to:
  /// **'Grip Strength'**
  String get gripStrength;

  /// No description provided for @leftKg.
  ///
  /// In en, this message translates to:
  /// **'Left (kg)'**
  String get leftKg;

  /// No description provided for @rightKg.
  ///
  /// In en, this message translates to:
  /// **'Right (kg)'**
  String get rightKg;

  /// No description provided for @lLeftkgRRightkgKg.
  ///
  /// In en, this message translates to:
  /// **'L {leftKg} · R {rightKg} kg'**
  String lLeftkgRRightkgKg(Object leftKg, Object rightKg);

  /// No description provided for @notificationsAreOffYouCan.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. You can still measure from your workout.'**
  String get notificationsAreOffYouCan;

  /// No description provided for @noRemindersFrom2200.
  ///
  /// In en, this message translates to:
  /// **'No reminders from 22:00 to 07:00'**
  String get noRemindersFrom2200;

  /// No description provided for @aReminderThatWouldFall.
  ///
  /// In en, this message translates to:
  /// **'A reminder that would fall in this time is skipped, not moved to the morning.'**
  String get aReminderThatWouldFall;

  /// No description provided for @remindersArriveQuietlyInThe.
  ///
  /// In en, this message translates to:
  /// **'Reminders arrive quietly in the notification list.'**
  String get remindersArriveQuietlyInThe;

  /// No description provided for @noForecastForThisDay.
  ///
  /// In en, this message translates to:
  /// **'No forecast for this day'**
  String get noForecastForThisDay;

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'● {source}'**
  String source(Object source);

  /// No description provided for @shadedAreaProviderSpread.
  ///
  /// In en, this message translates to:
  /// **'Shaded area: provider spread'**
  String get shadedAreaProviderSpread;

  /// No description provided for @temperatureC.
  ///
  /// In en, this message translates to:
  /// **'● Temperature °C'**
  String get temperatureC;

  /// No description provided for @rainMm.
  ///
  /// In en, this message translates to:
  /// **'▥ Rain mm'**
  String get rainMm;

  /// No description provided for @uvIndex.
  ///
  /// In en, this message translates to:
  /// **'— UV index'**
  String get uvIndex;

  /// No description provided for @closeFullscreenWeatherChart.
  ///
  /// In en, this message translates to:
  /// **'Close fullscreen weather chart'**
  String get closeFullscreenWeatherChart;

  /// No description provided for @sleepStages.
  ///
  /// In en, this message translates to:
  /// **'SLEEP STAGES'**
  String get sleepStages;

  /// No description provided for @noStageTimelineForThis.
  ///
  /// In en, this message translates to:
  /// **'No stage timeline for this night.'**
  String get noStageTimelineForThis;

  /// No description provided for @round3.
  ///
  /// In en, this message translates to:
  /// **'{round}%'**
  String round3(Object round);

  /// No description provided for @examplesOnlyCheckAndEnter.
  ///
  /// In en, this message translates to:
  /// **'Examples only: check and enter your product label values per serving. Leave unknown nutrients blank; enter 0 only when known.'**
  String get examplesOnlyCheckAndEnter;

  /// No description provided for @nutritionStrategy.
  ///
  /// In en, this message translates to:
  /// **'Nutrition strategy'**
  String get nutritionStrategy;

  /// No description provided for @noPreWorkoutNutritionStrategy.
  ///
  /// In en, this message translates to:
  /// **'No pre-workout nutrition strategy was saved.'**
  String get noPreWorkoutNutritionStrategy;

  /// No description provided for @carbsGCarbsHFluid.
  ///
  /// In en, this message translates to:
  /// **'{carbs} g carbs/h · {fluid} ml/h · {sodium} mg sodium/h'**
  String carbsGCarbsHFluid(Object carbs, Object fluid, Object sodium);

  /// No description provided for @forecastUpdatedReviewOrRecalculate.
  ///
  /// In en, this message translates to:
  /// **'Forecast updated — review or recalculate the saved strategy.'**
  String get forecastUpdatedReviewOrRecalculate;

  /// No description provided for @strategySavedSavedat.
  ///
  /// In en, this message translates to:
  /// **'Strategy saved {savedAt}'**
  String strategySavedSavedat(Object savedAt);

  /// No description provided for @duringTotalTotalcarbsGCarbs.
  ///
  /// In en, this message translates to:
  /// **'During total: {totalCarbs} g carbs · {totalFluid} ml · {totalSodium} mg sodium'**
  String duringTotalTotalcarbsGCarbs(
    Object totalCarbs,
    Object totalFluid,
    Object totalSodium,
  );

  /// No description provided for @every20MinAboutCarbs.
  ///
  /// In en, this message translates to:
  /// **'Every 20 min: about {carbs} g carbs and {fluid} ml.'**
  String every20MinAboutCarbs(Object carbs, Object fluid);

  /// No description provided for @packQuantitiesIncludeFullContainers.
  ///
  /// In en, this message translates to:
  /// **'Pack quantities include full containers; they are not a requirement to consume everything.'**
  String get packQuantitiesIncludeFullContainers;

  /// No description provided for @workoutChangedReviewOrRecalculate.
  ///
  /// In en, this message translates to:
  /// **'Workout changed — review or recalculate this saved strategy.'**
  String get workoutChangedReviewOrRecalculate;

  /// No description provided for @conditionsAndFeedingPlan.
  ///
  /// In en, this message translates to:
  /// **'Conditions and feeding plan'**
  String get conditionsAndFeedingPlan;

  /// No description provided for @editStrategy.
  ///
  /// In en, this message translates to:
  /// **'Edit strategy'**
  String get editStrategy;

  /// No description provided for @recalculate.
  ///
  /// In en, this message translates to:
  /// **'Recalculate'**
  String get recalculate;

  /// No description provided for @actualNutrition.
  ///
  /// In en, this message translates to:
  /// **'Actual nutrition'**
  String get actualNutrition;

  /// No description provided for @someProductValuesAreUnknown.
  ///
  /// In en, this message translates to:
  /// **'Some product values are unknown; totals are incomplete.'**
  String get someProductValuesAreUnknown;

  /// No description provided for @logFoodAndFluids.
  ///
  /// In en, this message translates to:
  /// **'Log food and fluids'**
  String get logFoodAndFluids;

  /// No description provided for @recordWhatYouActuallyHad.
  ///
  /// In en, this message translates to:
  /// **'Record what you actually had. Planned intake is not copied into this log.'**
  String get recordWhatYouActuallyHad;

  /// No description provided for @elapsedMinutesIncludingStopsOptional.
  ///
  /// In en, this message translates to:
  /// **'Elapsed minutes including stops (optional)'**
  String get elapsedMinutesIncludingStopsOptional;

  /// No description provided for @recordedDurationActivityMin.
  ///
  /// In en, this message translates to:
  /// **'Recorded duration: {activity} min'**
  String recordedDurationActivityMin(Object activity);

  /// No description provided for @compareWithSavedStrategy.
  ///
  /// In en, this message translates to:
  /// **'Compare with saved strategy'**
  String get compareWithSavedStrategy;

  /// No description provided for @useMatchedSessionIfAvailable.
  ///
  /// In en, this message translates to:
  /// **'Use matched session if available'**
  String get useMatchedSessionIfAvailable;

  /// No description provided for @noPlanComparison.
  ///
  /// In en, this message translates to:
  /// **'No plan comparison'**
  String get noPlanComparison;

  /// No description provided for @titleDate.
  ///
  /// In en, this message translates to:
  /// **'{title} · {date}'**
  String titleDate(Object title, Object date);

  /// No description provided for @linkedStrategyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Linked strategy unavailable'**
  String get linkedStrategyUnavailable;

  /// No description provided for @quantityName.
  ///
  /// In en, this message translates to:
  /// **'{quantity} × {name}'**
  String quantityName(Object quantity, Object name);

  /// No description provided for @removeIntake.
  ///
  /// In en, this message translates to:
  /// **'Remove intake'**
  String get removeIntake;

  /// No description provided for @addFoodOrDrink.
  ///
  /// In en, this message translates to:
  /// **'Add food or drink'**
  String get addFoodOrDrink;

  /// No description provided for @iHadNoIntake.
  ///
  /// In en, this message translates to:
  /// **'I had no intake'**
  String get iHadNoIntake;

  /// No description provided for @giGutComfort.
  ///
  /// In en, this message translates to:
  /// **'GI / gut comfort'**
  String get giGutComfort;

  /// No description provided for @whatWorkedSymptomsAccessProblems.
  ///
  /// In en, this message translates to:
  /// **'What worked / symptoms / access problems'**
  String get whatWorkedSymptomsAccessProblems;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @skipLoggingThisActivity.
  ///
  /// In en, this message translates to:
  /// **'Skip logging this activity'**
  String get skipLoggingThisActivity;

  /// No description provided for @nutritionAndFluids.
  ///
  /// In en, this message translates to:
  /// **'Nutrition and fluids'**
  String get nutritionAndFluids;

  /// No description provided for @productsToleranceAndMeasuredSweat.
  ///
  /// In en, this message translates to:
  /// **'Products, tolerance and measured sweat losses'**
  String get productsToleranceAndMeasuredSweat;

  /// No description provided for @postWorkoutIntakeReminder.
  ///
  /// In en, this message translates to:
  /// **'Post-workout intake reminder'**
  String get postWorkoutIntakeReminder;

  /// No description provided for @onceAfterARecentEndurance.
  ///
  /// In en, this message translates to:
  /// **'Once after a recent endurance workout; quiet hours 22:00–08:00.'**
  String get onceAfterARecentEndurance;

  /// No description provided for @enableWorkoutNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable workout notifications'**
  String get enableWorkoutNotifications;

  /// No description provided for @addHiloBpReport.
  ///
  /// In en, this message translates to:
  /// **'Add Hilo BP report'**
  String get addHiloBpReport;

  /// No description provided for @readingPdfReportsIsOnly.
  ///
  /// In en, this message translates to:
  /// **'Reading PDF reports is only available on iOS and macOS.'**
  String get readingPdfReportsIsOnly;

  /// No description provided for @chooseAnotherReport.
  ///
  /// In en, this message translates to:
  /// **'Choose another report'**
  String get chooseAnotherReport;

  /// No description provided for @biologicalAge.
  ///
  /// In en, this message translates to:
  /// **'Biological Age'**
  String get biologicalAge;

  /// No description provided for @voMaxVo2maxMlKg.
  ///
  /// In en, this message translates to:
  /// **'VO₂max {vo2max} ml/kg/min · {vo2Class}'**
  String voMaxVo2maxMlKg(Object vo2max, Object vo2Class);

  /// No description provided for @factorContributions.
  ///
  /// In en, this message translates to:
  /// **'Factor contributions'**
  String get factorContributions;

  /// No description provided for @estimatedRangeRoundRound2Years.
  ///
  /// In en, this message translates to:
  /// **'Estimated range {round}–{round2} years. A model estimate, not a medical diagnosis.'**
  String estimatedRangeRoundRound2Years(Object round, Object round2);

  /// No description provided for @noEnergyMeasurementsForThis.
  ///
  /// In en, this message translates to:
  /// **'No energy measurements for this day'**
  String get noEnergyMeasurementsForThis;

  /// No description provided for @scanningStepOnTheScale.
  ///
  /// In en, this message translates to:
  /// **'Scanning… step on the scale when ready.'**
  String get scanningStepOnTheScale;

  /// No description provided for @waistWaistCmUpdateMonthly.
  ///
  /// In en, this message translates to:
  /// **'Waist: {waist} cm — update monthly in Profile'**
  String waistWaistCmUpdateMonthly(Object waist);

  /// No description provided for @measuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring…'**
  String get measuring;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @systolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get systolic;

  /// No description provided for @diastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get diastolic;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRate;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @bodyFat.
  ///
  /// In en, this message translates to:
  /// **'Body Fat'**
  String get bodyFat;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @deep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get deep;

  /// No description provided for @spo.
  ///
  /// In en, this message translates to:
  /// **'SpO₂'**
  String get spo;

  /// No description provided for @activityName.
  ///
  /// In en, this message translates to:
  /// **'Activity name'**
  String get activityName;

  /// No description provided for @sport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get sport;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @connectionFailedCheckYourInternet.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check your internet connection.'**
  String get connectionFailedCheckYourInternet;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password too short'**
  String get passwordTooShort;

  /// No description provided for @loginFailedCheckYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Check your email and password.'**
  String get loginFailedCheckYourEmail;

  /// No description provided for @connectionFailedCheckYourCredentials.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check your credentials and internet connection.'**
  String get connectionFailedCheckYourCredentials;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @hiloPod.
  ///
  /// In en, this message translates to:
  /// **'Hilo pod'**
  String get hiloPod;

  /// No description provided for @hiloAccount.
  ///
  /// In en, this message translates to:
  /// **'Hilo account'**
  String get hiloAccount;

  /// No description provided for @garmin.
  ///
  /// In en, this message translates to:
  /// **'Garmin'**
  String get garmin;

  /// No description provided for @coros.
  ///
  /// In en, this message translates to:
  /// **'Coros'**
  String get coros;

  /// No description provided for @suunto.
  ///
  /// In en, this message translates to:
  /// **'Suunto'**
  String get suunto;

  /// No description provided for @polarH10.
  ///
  /// In en, this message translates to:
  /// **'Polar H10'**
  String get polarH10;

  /// No description provided for @polar.
  ///
  /// In en, this message translates to:
  /// **'Polar'**
  String get polar;

  /// No description provided for @renphoAccount.
  ///
  /// In en, this message translates to:
  /// **'Renpho account'**
  String get renphoAccount;

  /// No description provided for @garminConnectEmail.
  ///
  /// In en, this message translates to:
  /// **'Garmin Connect Email'**
  String get garminConnectEmail;

  /// No description provided for @verifyMfaCode.
  ///
  /// In en, this message translates to:
  /// **'Verify MFA Code'**
  String get verifyMfaCode;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @errorE.
  ///
  /// In en, this message translates to:
  /// **'Error: {e}'**
  String errorE(Object e);

  /// No description provided for @noHiloPodFoundMake.
  ///
  /// In en, this message translates to:
  /// **'No Hilo pod found. Make sure it is charged and nearby.'**
  String get noHiloPodFoundMake;

  /// No description provided for @scanFailedE.
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {e}'**
  String scanFailedE(Object e);

  /// No description provided for @hiloPod2.
  ///
  /// In en, this message translates to:
  /// **'Hilo Pod'**
  String get hiloPod2;

  /// No description provided for @scanForPod.
  ///
  /// In en, this message translates to:
  /// **'Scan for pod'**
  String get scanForPod;

  /// No description provided for @scanForPolarH10.
  ///
  /// In en, this message translates to:
  /// **'Scan for Polar H10'**
  String get scanForPolarH10;

  /// No description provided for @couldNotReachPolarCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Polar. Check your connection.'**
  String get couldNotReachPolarCheck;

  /// No description provided for @signInAndSendWorkout.
  ///
  /// In en, this message translates to:
  /// **'Sign in and send workout'**
  String get signInAndSendWorkout;

  /// No description provided for @scanForScale.
  ///
  /// In en, this message translates to:
  /// **'Scan for scale'**
  String get scanForScale;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get passwordRequired;

  /// No description provided for @enterYourPhoneNumberWith.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number (with country code, e.g. +49…) and Suunto email.'**
  String get enterYourPhoneNumberWith;

  /// No description provided for @enterThePinFromThe.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN from the SMS.'**
  String get enterThePinFromThe;

  /// No description provided for @incorrectPinPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Please try again.'**
  String get incorrectPinPleaseTryAgain;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @suuntoAccountEmail.
  ///
  /// In en, this message translates to:
  /// **'Suunto Account Email'**
  String get suuntoAccountEmail;

  /// No description provided for @enterPinFromSms.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN from SMS'**
  String get enterPinFromSms;

  /// No description provided for @verifyConnect.
  ///
  /// In en, this message translates to:
  /// **'Verify & Connect'**
  String get verifyConnect;

  /// No description provided for @sendSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Send SMS Code'**
  String get sendSmsCode;

  /// No description provided for @couldNotSavePreferencesE.
  ///
  /// In en, this message translates to:
  /// **'Could not save preferences: {e}'**
  String couldNotSavePreferencesE(Object e);

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @trailRunning.
  ///
  /// In en, this message translates to:
  /// **'Trail running'**
  String get trailRunning;

  /// No description provided for @cycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get cycling;

  /// No description provided for @swimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get swimming;

  /// No description provided for @triathlon.
  ///
  /// In en, this message translates to:
  /// **'Triathlon'**
  String get triathlon;

  /// No description provided for @hiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get hiking;

  /// No description provided for @rowing.
  ///
  /// In en, this message translates to:
  /// **'Rowing'**
  String get rowing;

  /// No description provided for @buildMyPlan.
  ///
  /// In en, this message translates to:
  /// **'Build My Plan'**
  String get buildMyPlan;

  /// No description provided for @keepAConsistentBedtimeAnd.
  ///
  /// In en, this message translates to:
  /// **'Keep a consistent bedtime and wake time to support your sleep routine.'**
  String get keepAConsistentBedtimeAnd;

  /// No description provided for @thisWorkoutHasNoSets.
  ///
  /// In en, this message translates to:
  /// **'This workout has no sets.'**
  String get thisWorkoutHasNoSets;

  /// No description provided for @loadName.
  ///
  /// In en, this message translates to:
  /// **'Load ({name})'**
  String loadName(Object name);

  /// No description provided for @setLabel.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setLabel;

  /// No description provided for @lowestReps.
  ///
  /// In en, this message translates to:
  /// **'Lowest reps'**
  String get lowestReps;

  /// No description provided for @highestReps.
  ///
  /// In en, this message translates to:
  /// **'Highest reps'**
  String get highestReps;

  /// No description provided for @repsPerSide.
  ///
  /// In en, this message translates to:
  /// **'Reps per side'**
  String get repsPerSide;

  /// No description provided for @fromReps.
  ///
  /// In en, this message translates to:
  /// **'From reps'**
  String get fromReps;

  /// No description provided for @toReps.
  ///
  /// In en, this message translates to:
  /// **'To reps'**
  String get toReps;

  /// No description provided for @addedLoad.
  ///
  /// In en, this message translates to:
  /// **'Added load'**
  String get addedLoad;

  /// No description provided for @assistance.
  ///
  /// In en, this message translates to:
  /// **'Assistance'**
  String get assistance;

  /// No description provided for @tempoOptional.
  ///
  /// In en, this message translates to:
  /// **'Tempo (optional)'**
  String get tempoOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @enterTheRepetitionsDone.
  ///
  /// In en, this message translates to:
  /// **'Enter the repetitions done.'**
  String get enterTheRepetitionsDone;

  /// No description provided for @plannedUnit.
  ///
  /// In en, this message translates to:
  /// **'Planned {unit}'**
  String plannedUnit(Object unit);

  /// No description provided for @repsDone.
  ///
  /// In en, this message translates to:
  /// **'Reps done'**
  String get repsDone;

  /// No description provided for @resistance.
  ///
  /// In en, this message translates to:
  /// **'Resistance'**
  String get resistance;

  /// No description provided for @implementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Implements'**
  String get implementsLabel;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @instructionsOptional.
  ///
  /// In en, this message translates to:
  /// **'Instructions (optional)'**
  String get instructionsOptional;

  /// No description provided for @remember.
  ///
  /// In en, this message translates to:
  /// **'Remember'**
  String get remember;

  /// No description provided for @notSavedYet.
  ///
  /// In en, this message translates to:
  /// **'Not saved yet'**
  String get notSavedYet;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save'**
  String get couldNotSave;

  /// No description provided for @plannedValuesAreHintsNot.
  ///
  /// In en, this message translates to:
  /// **'Planned values are hints, not results. Tap a set to record it.'**
  String get plannedValuesAreHintsNot;

  /// No description provided for @completedAsPlanned.
  ///
  /// In en, this message translates to:
  /// **'Completed as planned'**
  String get completedAsPlanned;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @nameTheTemplate.
  ///
  /// In en, this message translates to:
  /// **'Name the template.'**
  String get nameTheTemplate;

  /// No description provided for @setN.
  ///
  /// In en, this message translates to:
  /// **'Set {n}'**
  String setN(Object n);

  /// No description provided for @changesApplyToThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'Changes apply to this workout only. Completed workouts and other sessions stay as they are.'**
  String get changesApplyToThisWorkout;

  /// No description provided for @saveForThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'Save for this workout'**
  String get saveForThisWorkout;

  /// No description provided for @knownForKnownOfOf.
  ///
  /// In en, this message translates to:
  /// **'Known for {known} of {of} loaded sets'**
  String knownForKnownOfOf(Object known, Object of);

  /// No description provided for @sessionEstimate.
  ///
  /// In en, this message translates to:
  /// **'Session estimate'**
  String get sessionEstimate;

  /// No description provided for @calculatedRange.
  ///
  /// In en, this message translates to:
  /// **'Calculated range'**
  String get calculatedRange;

  /// No description provided for @timedWork.
  ///
  /// In en, this message translates to:
  /// **'Timed work'**
  String get timedWork;

  /// No description provided for @strengthTraining.
  ///
  /// In en, this message translates to:
  /// **'Strength training'**
  String get strengthTraining;

  /// No description provided for @theExercisesCouldNotBe.
  ///
  /// In en, this message translates to:
  /// **'The exercises could not be loaded.'**
  String get theExercisesCouldNotBe;

  /// No description provided for @resumeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Resume workout'**
  String get resumeWorkout;

  /// No description provided for @strengthWorkout.
  ///
  /// In en, this message translates to:
  /// **'Strength workout'**
  String get strengthWorkout;

  /// No description provided for @untitledTemplate.
  ///
  /// In en, this message translates to:
  /// **'Untitled template'**
  String get untitledTemplate;

  /// No description provided for @theRecordedExercisesCouldNot.
  ///
  /// In en, this message translates to:
  /// **'The recorded exercises could not be loaded.'**
  String get theRecordedExercisesCouldNot;

  /// No description provided for @exercisesPerformed.
  ///
  /// In en, this message translates to:
  /// **'Exercises performed'**
  String get exercisesPerformed;

  /// No description provided for @comparedWithThePlanAs.
  ///
  /// In en, this message translates to:
  /// **'Compared with the plan as it was when logging started.'**
  String get comparedWithThePlanAs;

  /// No description provided for @topWorkingLoadName.
  ///
  /// In en, this message translates to:
  /// **'Top working load ({name})'**
  String topWorkingLoadName(Object name);

  /// No description provided for @estimated1rmMiddleOfRange.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM, middle of range'**
  String get estimated1rmMiddleOfRange;

  /// No description provided for @noLoggedSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No logged sessions yet.'**
  String get noLoggedSessionsYet;

  /// No description provided for @noRadarFramesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No radar frames available'**
  String get noRadarFramesAvailable;

  /// No description provided for @playRadar.
  ///
  /// In en, this message translates to:
  /// **'Play radar'**
  String get playRadar;

  /// No description provided for @pauseRadar.
  ///
  /// In en, this message translates to:
  /// **'Pause radar'**
  String get pauseRadar;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @bodyweight.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get bodyweight;

  /// No description provided for @resistance2.
  ///
  /// In en, this message translates to:
  /// **'Resistance —'**
  String get resistance2;

  /// No description provided for @assistUnit.
  ///
  /// In en, this message translates to:
  /// **'Assist {unit}'**
  String assistUnit(Object unit);

  /// No description provided for @reps2.
  ///
  /// In en, this message translates to:
  /// **'Reps —'**
  String get reps2;

  /// No description provided for @notRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get notRecorded;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @expandName.
  ///
  /// In en, this message translates to:
  /// **'Expand {name}'**
  String expandName(Object name);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @noScalePaired.
  ///
  /// In en, this message translates to:
  /// **'No scale paired'**
  String get noScalePaired;

  /// No description provided for @paired.
  ///
  /// In en, this message translates to:
  /// **'Paired'**
  String get paired;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @noCuffPaired.
  ///
  /// In en, this message translates to:
  /// **'No cuff paired'**
  String get noCuffPaired;

  /// No description provided for @noPolarH10FoundWear.
  ///
  /// In en, this message translates to:
  /// **'No Polar H10 found. Wear the strap, wet its electrodes and check that another app is not using both Bluetooth connections.'**
  String get noPolarH10FoundWear;

  /// No description provided for @enterMinutesSinceTrainingEnded.
  ///
  /// In en, this message translates to:
  /// **'Enter minutes since training ended, from 0 to 1440.'**
  String get enterMinutesSinceTrainingEnded;

  /// No description provided for @timingFollowsYourWorkout.
  ///
  /// In en, this message translates to:
  /// **'Timing follows your workout.'**
  String get timingFollowsYourWorkout;

  /// No description provided for @recordingStayStill.
  ///
  /// In en, this message translates to:
  /// **'Recording · stay still'**
  String get recordingStayStill;

  /// No description provided for @meanHrBpm.
  ///
  /// In en, this message translates to:
  /// **'Mean HR · bpm'**
  String get meanHrBpm;

  /// No description provided for @pairAPolarH10First.
  ///
  /// In en, this message translates to:
  /// **'Pair a Polar H10 first.'**
  String get pairAPolarH10First;

  /// No description provided for @around30MinutesAfterTraining.
  ///
  /// In en, this message translates to:
  /// **'Around 30 minutes after training, when the workout is available in time.'**
  String get around30MinutesAfterTraining;

  /// No description provided for @reminderDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Reminder diagnostics'**
  String get reminderDiagnostics;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecast;

  /// No description provided for @enterAName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterAName;

  /// No description provided for @enterAValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterAValidAmount;

  /// No description provided for @enterAPositiveAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive amount'**
  String get enterAPositiveAmount;

  /// No description provided for @maximum120GH.
  ///
  /// In en, this message translates to:
  /// **'Maximum 120 g/h'**
  String get maximum120GH;

  /// No description provided for @carbohydrateTargetGH.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrate target g/h'**
  String get carbohydrateTargetGH;

  /// No description provided for @fluidTargetMlH.
  ///
  /// In en, this message translates to:
  /// **'Fluid target ml/h'**
  String get fluidTargetMlH;

  /// No description provided for @sodiumTargetMgHNot.
  ///
  /// In en, this message translates to:
  /// **'Sodium target mg/h (not salt)'**
  String get sodiumTargetMgHNot;

  /// No description provided for @surfaceFeedingAccess.
  ///
  /// In en, this message translates to:
  /// **'Surface / feeding access'**
  String get surfaceFeedingAccess;

  /// No description provided for @expectedAscentM.
  ///
  /// In en, this message translates to:
  /// **'Expected ascent m'**
  String get expectedAscentM;

  /// No description provided for @expectedAltitudeM.
  ///
  /// In en, this message translates to:
  /// **'Expected altitude m'**
  String get expectedAltitudeM;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity %'**
  String get humidity;

  /// No description provided for @windKmH.
  ///
  /// In en, this message translates to:
  /// **'Wind km/h'**
  String get windKmH;

  /// No description provided for @dayForecast.
  ///
  /// In en, this message translates to:
  /// **'Day forecast'**
  String get dayForecast;

  /// No description provided for @enteredConditions.
  ///
  /// In en, this message translates to:
  /// **'Entered conditions'**
  String get enteredConditions;

  /// No description provided for @productFoodName.
  ///
  /// In en, this message translates to:
  /// **'Product / food name'**
  String get productFoodName;

  /// No description provided for @servingsQuantity.
  ///
  /// In en, this message translates to:
  /// **'Servings / quantity'**
  String get servingsQuantity;

  /// No description provided for @when.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get when;

  /// No description provided for @carbohydrateGServing.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrate g / serving'**
  String get carbohydrateGServing;

  /// No description provided for @fluidMlServing.
  ///
  /// In en, this message translates to:
  /// **'Fluid ml / serving'**
  String get fluidMlServing;

  /// No description provided for @caffeineMgServing.
  ///
  /// In en, this message translates to:
  /// **'Caffeine mg / serving'**
  String get caffeineMgServing;

  /// No description provided for @proteinGServing.
  ///
  /// In en, this message translates to:
  /// **'Protein g / serving'**
  String get proteinGServing;

  /// No description provided for @gel.
  ///
  /// In en, this message translates to:
  /// **'Gel'**
  String get gel;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @sportsDrink.
  ///
  /// In en, this message translates to:
  /// **'Sports drink'**
  String get sportsDrink;

  /// No description provided for @bar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get bar;

  /// No description provided for @finishIntakeLog.
  ///
  /// In en, this message translates to:
  /// **'Finish intake log'**
  String get finishIntakeLog;

  /// No description provided for @allowNotificationsInSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in system settings'**
  String get allowNotificationsInSystemSettings;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importing;

  /// No description provided for @importNewreadings.
  ///
  /// In en, this message translates to:
  /// **'Import {newReadings}'**
  String importNewreadings(Object newReadings);

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get reading;

  /// No description provided for @chooseReportPdf.
  ///
  /// In en, this message translates to:
  /// **'Choose report (PDF)'**
  String get chooseReportPdf;

  /// No description provided for @yourTrainingHistoryIsReady.
  ///
  /// In en, this message translates to:
  /// **'Your training history is ready'**
  String get yourTrainingHistoryIsReady;

  /// No description provided for @importingYourTrainingHistory.
  ///
  /// In en, this message translates to:
  /// **'Importing your training history'**
  String get importingYourTrainingHistory;

  /// No description provided for @stopImport.
  ///
  /// In en, this message translates to:
  /// **'Stop import'**
  String get stopImport;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @openai.
  ///
  /// In en, this message translates to:
  /// **'OpenAI'**
  String get openai;

  /// No description provided for @appleIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence'**
  String get appleIntelligence;

  /// No description provided for @nonAiBriefing.
  ///
  /// In en, this message translates to:
  /// **'Non-AI Briefing'**
  String get nonAiBriefing;

  /// No description provided for @noBriefing.
  ///
  /// In en, this message translates to:
  /// **'No Briefing'**
  String get noBriefing;

  /// No description provided for @ruleBasedSummaryFromYour.
  ///
  /// In en, this message translates to:
  /// **'Rule-based summary from your health data — no API calls'**
  String get ruleBasedSummaryFromYour;

  /// No description provided for @hideTheBriefingCard.
  ///
  /// In en, this message translates to:
  /// **'Hide the briefing card'**
  String get hideTheBriefingCard;

  /// No description provided for @flutter.
  ///
  /// In en, this message translates to:
  /// **'Flutter'**
  String get flutter;

  /// No description provided for @stateManagement.
  ///
  /// In en, this message translates to:
  /// **'State management'**
  String get stateManagement;

  /// No description provided for @bluetoothLe.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth LE'**
  String get bluetoothLe;

  /// No description provided for @interactiveMaps.
  ///
  /// In en, this message translates to:
  /// **'Interactive maps'**
  String get interactiveMaps;

  /// No description provided for @chartsGraphs.
  ///
  /// In en, this message translates to:
  /// **'Charts & graphs'**
  String get chartsGraphs;

  /// No description provided for @secureCredentialStorage.
  ///
  /// In en, this message translates to:
  /// **'Secure credential storage'**
  String get secureCredentialStorage;

  /// No description provided for @markdownRendering.
  ///
  /// In en, this message translates to:
  /// **'Markdown rendering'**
  String get markdownRendering;

  /// No description provided for @appleOnDeviceAi.
  ///
  /// In en, this message translates to:
  /// **'Apple on-device AI'**
  String get appleOnDeviceAi;

  /// No description provided for @cryptography.
  ///
  /// In en, this message translates to:
  /// **'Cryptography'**
  String get cryptography;

  /// No description provided for @appleHealthHealthConnect.
  ///
  /// In en, this message translates to:
  /// **'Apple Health & Health Connect'**
  String get appleHealthHealthConnect;

  /// No description provided for @runtimePermissions.
  ///
  /// In en, this message translates to:
  /// **'Runtime permissions'**
  String get runtimePermissions;

  /// No description provided for @shareExport.
  ///
  /// In en, this message translates to:
  /// **'Share & export'**
  String get shareExport;

  /// No description provided for @openUrls.
  ///
  /// In en, this message translates to:
  /// **'Open URLs'**
  String get openUrls;

  /// No description provided for @internationalisation.
  ///
  /// In en, this message translates to:
  /// **'Internationalisation'**
  String get internationalisation;

  /// No description provided for @utilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get utilities;

  /// No description provided for @icons.
  ///
  /// In en, this message translates to:
  /// **'Icons'**
  String get icons;

  /// No description provided for @fjelia.
  ///
  /// In en, this message translates to:
  /// **'Fjelia'**
  String get fjelia;

  /// No description provided for @fjeliaFeedback.
  ///
  /// In en, this message translates to:
  /// **'Fjelia feedback'**
  String get fjeliaFeedback;

  /// No description provided for @couldNotSendTheReport.
  ///
  /// In en, this message translates to:
  /// **'Could not send the report. Your text is still here. Please try again.'**
  String get couldNotSendTheReport;

  /// No description provided for @yourEmail.
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get yourEmail;

  /// No description provided for @enterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get enterAValidEmailAddress;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReport;

  /// No description provided for @sleepRecovery.
  ///
  /// In en, this message translates to:
  /// **'Sleep & Recovery'**
  String get sleepRecovery;

  /// No description provided for @activitiesTraining.
  ///
  /// In en, this message translates to:
  /// **'Activities & Training'**
  String get activitiesTraining;

  /// No description provided for @bodyWellness.
  ///
  /// In en, this message translates to:
  /// **'Body & Wellness'**
  String get bodyWellness;

  /// No description provided for @hilo.
  ///
  /// In en, this message translates to:
  /// **'Hilo'**
  String get hilo;

  /// No description provided for @hiloBle.
  ///
  /// In en, this message translates to:
  /// **'Hilo BLE'**
  String get hiloBle;

  /// No description provided for @garminApi.
  ///
  /// In en, this message translates to:
  /// **'Garmin (API)'**
  String get garminApi;

  /// No description provided for @renphoScale.
  ///
  /// In en, this message translates to:
  /// **'Renpho Scale'**
  String get renphoScale;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habits;

  /// No description provided for @smokingAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Smoking, alcohol'**
  String get smokingAlcohol;

  /// No description provided for @clinicalLab.
  ///
  /// In en, this message translates to:
  /// **'Clinical Lab'**
  String get clinicalLab;

  /// No description provided for @hba1cLipidsKidney.
  ///
  /// In en, this message translates to:
  /// **'HbA1c, lipids, kidney'**
  String get hba1cLipidsKidney;

  /// No description provided for @sex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sex;

  /// No description provided for @smoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get smoking;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @former.
  ///
  /// In en, this message translates to:
  /// **'Former'**
  String get former;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @hba1c.
  ///
  /// In en, this message translates to:
  /// **'HbA1c'**
  String get hba1c;

  /// No description provided for @diabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get diabetes;

  /// No description provided for @prediabetes.
  ///
  /// In en, this message translates to:
  /// **'Prediabetes'**
  String get prediabetes;

  /// No description provided for @type1.
  ///
  /// In en, this message translates to:
  /// **'Type 1'**
  String get type1;

  /// No description provided for @type2.
  ///
  /// In en, this message translates to:
  /// **'Type 2'**
  String get type2;

  /// No description provided for @apob.
  ///
  /// In en, this message translates to:
  /// **'ApoB'**
  String get apob;

  /// No description provided for @optionalPlansAndPaceGuides.
  ///
  /// In en, this message translates to:
  /// **'Optional. Plans and pace guides use it; the climbing above shapes the training too.'**
  String get optionalPlansAndPaceGuides;

  /// No description provided for @addRaceGoal2.
  ///
  /// In en, this message translates to:
  /// **'Add Race Goal'**
  String get addRaceGoal2;

  /// No description provided for @editRaceGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Race Goal'**
  String get editRaceGoal;

  /// No description provided for @trailRunning2.
  ///
  /// In en, this message translates to:
  /// **'Trail Running'**
  String get trailRunning2;

  /// No description provided for @roadCycling.
  ///
  /// In en, this message translates to:
  /// **'Road Cycling'**
  String get roadCycling;

  /// No description provided for @gravel.
  ///
  /// In en, this message translates to:
  /// **'Gravel'**
  String get gravel;

  /// No description provided for @indoorRowing.
  ///
  /// In en, this message translates to:
  /// **'Indoor Rowing'**
  String get indoorRowing;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @committed.
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get committed;

  /// No description provided for @flexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get flexible;

  /// No description provided for @notGoing.
  ///
  /// In en, this message translates to:
  /// **'Not going'**
  String get notGoing;

  /// No description provided for @notSaid.
  ///
  /// In en, this message translates to:
  /// **'Not said'**
  String get notSaid;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @saveGoal.
  ///
  /// In en, this message translates to:
  /// **'Save Goal'**
  String get saveGoal;

  /// No description provided for @exportAllRecordedWorkoutsAs.
  ///
  /// In en, this message translates to:
  /// **'Export all recorded workouts as a spreadsheet.'**
  String get exportAllRecordedWorkoutsAs;

  /// No description provided for @backupsIncludeYourHealthData.
  ///
  /// In en, this message translates to:
  /// **'Backups include your health data, training plans and profile settings. Login credentials are excluded. Restoring replaces local data.'**
  String get backupsIncludeYourHealthData;

  /// No description provided for @trail.
  ///
  /// In en, this message translates to:
  /// **'Trail'**
  String get trail;

  /// No description provided for @inlineSkating.
  ///
  /// In en, this message translates to:
  /// **'Inline Skating'**
  String get inlineSkating;

  /// No description provided for @nordicClassic.
  ///
  /// In en, this message translates to:
  /// **'Nordic Classic'**
  String get nordicClassic;

  /// No description provided for @skateSkiing.
  ///
  /// In en, this message translates to:
  /// **'Skate Skiing'**
  String get skateSkiing;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get strength;

  /// No description provided for @walking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get walking;

  /// No description provided for @yoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get yoga;

  /// No description provided for @skiing.
  ///
  /// In en, this message translates to:
  /// **'Skiing'**
  String get skiing;

  /// No description provided for @climbing.
  ///
  /// In en, this message translates to:
  /// **'Climbing'**
  String get climbing;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @train.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get train;

  /// No description provided for @restDay.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restDay;

  /// No description provided for @kilogramsKg.
  ///
  /// In en, this message translates to:
  /// **'Kilograms (kg)'**
  String get kilogramsKg;

  /// No description provided for @poundsLb.
  ///
  /// In en, this message translates to:
  /// **'Pounds (lb)'**
  String get poundsLb;

  /// No description provided for @regenerateWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Workouts'**
  String get regenerateWorkouts;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get starting;

  /// No description provided for @allPlannedWorkoutsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All planned workouts deleted.'**
  String get allPlannedWorkoutsDeleted;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get searching;

  /// No description provided for @searchCity.
  ///
  /// In en, this message translates to:
  /// **'Search city'**
  String get searchCity;

  /// No description provided for @fixedLocationSavedWeatherWill.
  ///
  /// In en, this message translates to:
  /// **'Fixed location saved. Weather will refresh.'**
  String get fixedLocationSavedWeatherWill;

  /// No description provided for @locationDisabledThePlanWeather.
  ///
  /// In en, this message translates to:
  /// **'Location disabled. The Plan weather card is hidden.'**
  String get locationDisabledThePlanWeather;

  /// No description provided for @locationSetToName.
  ///
  /// In en, this message translates to:
  /// **'Location set to {name}'**
  String locationSetToName(Object name);

  /// No description provided for @notEnoughDaytimeAndNighttime.
  ///
  /// In en, this message translates to:
  /// **'Not enough daytime and nighttime readings'**
  String get notEnoughDaytimeAndNighttime;

  /// No description provided for @onlyTheWeightWasReceived.
  ///
  /// In en, this message translates to:
  /// **'Only the weight was received. For body fat, muscle and the other values stand barefoot on the metal electrodes and stay on until the scale finishes.'**
  String get onlyTheWeightWasReceived;

  /// No description provided for @addYourWaistInProfile.
  ///
  /// In en, this message translates to:
  /// **'Add your waist in Profile for visceral fat.'**
  String get addYourWaistInProfile;

  /// No description provided for @manualActivity.
  ///
  /// In en, this message translates to:
  /// **'Manual Activity'**
  String get manualActivity;

  /// No description provided for @theseCredentialsAreStoredEncrypted.
  ///
  /// In en, this message translates to:
  /// **'These credentials are stored encrypted on your device (iOS Keychain / Android Keystore). They are never sent to any server other than Hilo.'**
  String get theseCredentialsAreStoredEncrypted;

  /// No description provided for @corosCredentialsAreStoredEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Coros credentials are stored encrypted on your device. Fjelia reads data directly from the Coros cloud API. This uses the same API as the Coros Training Hub web app.'**
  String get corosCredentialsAreStoredEncrypted;

  /// No description provided for @connectAnyCombinationYouCan.
  ///
  /// In en, this message translates to:
  /// **'Connect any combination — you can always add more later in Settings.'**
  String get connectAnyCombinationYouCan;

  /// No description provided for @garminCredentialsAreStoredEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Garmin credentials are stored encrypted on your device. Fjelia uses the unofficial Garmin Connect API – the same approach used by many community apps.'**
  String get garminCredentialsAreStoredEncrypted;

  /// No description provided for @enterTheVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get enterTheVerificationCode;

  /// No description provided for @appleHealthDataAccess.
  ///
  /// In en, this message translates to:
  /// **'Fjelia reads your health data from Apple Health. With your permission, it can also write synced data to Apple Health. Manage access in your device settings.'**
  String get appleHealthDataAccess;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @wearTheHiloBandDuring.
  ///
  /// In en, this message translates to:
  /// **'Wear the Hilo band during sleep for continuous blood pressure recording. Data syncs automatically each morning when the app opens.'**
  String get wearTheHiloBandDuring;

  /// No description provided for @noPolarH10FoundWear2.
  ///
  /// In en, this message translates to:
  /// **'No Polar H10 found. Wear the strap with moist electrodes and make sure no other app (or watch) is connected to it, then scan again.'**
  String get noPolarH10FoundWear2;

  /// No description provided for @wearTheStrapWithMoist2.
  ///
  /// In en, this message translates to:
  /// **'Wear the strap with moist electrodes before scanning. Measure later with + → Polar H10 HRV measurement; results appear next to your overnight HRV.'**
  String get wearTheStrapWithMoist2;

  /// No description provided for @signedInPlannedWorkoutsCan.
  ///
  /// In en, this message translates to:
  /// **'Signed in. Planned workouts can now be sent to Polar. Older sessions are imported with the next full history sync.'**
  String get signedInPlannedWorkoutsCan;

  /// No description provided for @saveYourPolarFlowLogin.
  ///
  /// In en, this message translates to:
  /// **'Save your Polar Flow login to send planned workouts and import sessions older than 30 days. It stays in this device\'s keychain and is sent only to Polar. Send a workout from its planner sheet, then sync Polar Flow to your watch. Check that your Polar heart-rate zones match Fjelia.'**
  String get saveYourPolarFlowLogin;

  /// No description provided for @signInToSendThis.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send this workout to your Polar Flow calendar. Your login stays in this device\'s keychain and is sent only to Polar. After sending, sync Polar Flow to your watch.'**
  String get signInToSendThis;

  /// No description provided for @checkAndSave.
  ///
  /// In en, this message translates to:
  /// **'Check and save'**
  String get checkAndSave;

  /// No description provided for @noScaleFoundStepOn.
  ///
  /// In en, this message translates to:
  /// **'No scale found. Step on the scale so it wakes up, then scan again.'**
  String get noScaleFoundStepOn;

  /// No description provided for @stepOnTheScaleBefore.
  ///
  /// In en, this message translates to:
  /// **'Step on the scale before scanning so it wakes up. Later, use + → RENPHO Scale to take a measurement.'**
  String get stepOnTheScaleBefore;

  /// No description provided for @renphoCredentialsAreStoredEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Renpho credentials are stored encrypted on your device. Fjelia talks directly to the Renpho cloud API.'**
  String get renphoCredentialsAreStoredEncrypted;

  /// No description provided for @couldNotSendSmsCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not send SMS. Check your phone number and internet connection.'**
  String get couldNotSendSmsCheck;

  /// No description provided for @theEmailIsUsedFor.
  ///
  /// In en, this message translates to:
  /// **'The email is used for secure request signing and is not sent to Suunto servers.'**
  String get theEmailIsUsedFor;

  /// No description provided for @suuntoUsesSmsVerificationSame.
  ///
  /// In en, this message translates to:
  /// **'Suunto uses SMS verification (same as the Suunto app). A one-time PIN will be sent to your phone. Your credentials are stored encrypted on-device only.'**
  String get suuntoUsesSmsVerificationSame;

  /// No description provided for @tellUsAboutYourRace.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your race and schedule. Fjelia builds your plan now and works out your level from your past activities (Garmin, Suunto, Polar, COROS, Apple Health) once they are downloaded.'**
  String get tellUsAboutYourRace;

  /// No description provided for @noAccountConnectedSoFjelia.
  ///
  /// In en, this message translates to:
  /// **'No account connected, so Fjelia has no history to learn from. Connect Garmin, Suunto, Polar, COROS or Apple Health and your real training decides instead.'**
  String get noAccountConnectedSoFjelia;

  /// No description provided for @yourPastActivitiesAreStill.
  ///
  /// In en, this message translates to:
  /// **'Your past activities are still being imported. You can build your plan now — it is refined automatically when the import finishes.'**
  String get yourPastActivitiesAreStill;

  /// No description provided for @buildingYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Building your plan…'**
  String get buildingYourPlan;

  /// No description provided for @saveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveContinue;

  /// No description provided for @addYourMainPriorityA.
  ///
  /// In en, this message translates to:
  /// **'Add your main (priority A) race. The plan is periodised towards it: base, build, peak and taper. Without a race goal no plan is generated yet.'**
  String get addYourMainPriorityA;

  /// No description provided for @noMeasurementsYet.
  ///
  /// In en, this message translates to:
  /// **'No measurements yet'**
  String get noMeasurementsYet;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @deepSleepIsBelowOptimal.
  ///
  /// In en, this message translates to:
  /// **'Deep sleep is below optimal ({round}%). Avoid alcohol and heavy meals 3h before bed.'**
  String deepSleepIsBelowOptimal(Object round);

  /// No description provided for @finishWithSetsOpen.
  ///
  /// In en, this message translates to:
  /// **'Finish with sets open?'**
  String get finishWithSetsOpen;

  /// No description provided for @completeThePlannedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Complete the planned workout?'**
  String get completeThePlannedWorkout;

  /// No description provided for @marksThePlannedSessionAs.
  ///
  /// In en, this message translates to:
  /// **'Marks the planned session as done with this workout.'**
  String get marksThePlannedSessionAs;

  /// No description provided for @discardThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'Discard this workout?'**
  String get discardThisWorkout;

  /// No description provided for @removesTheWorkoutAndEvery.
  ///
  /// In en, this message translates to:
  /// **'Removes the workout and every set recorded in it.'**
  String get removesTheWorkoutAndEvery;

  /// No description provided for @assistanceName.
  ///
  /// In en, this message translates to:
  /// **'Assistance ({name})'**
  String assistanceName(Object name);

  /// No description provided for @enterSecondsOrMSs.
  ///
  /// In en, this message translates to:
  /// **'Enter seconds or m:ss.'**
  String get enterSecondsOrMSs;

  /// No description provided for @enterTheLoadAsA.
  ///
  /// In en, this message translates to:
  /// **'Enter the load as a number.'**
  String get enterTheLoadAsA;

  /// No description provided for @loadCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Load cannot be negative.'**
  String get loadCannotBeNegative;

  /// No description provided for @enterTheEffortValue.
  ///
  /// In en, this message translates to:
  /// **'Enter the effort value.'**
  String get enterTheEffortValue;

  /// No description provided for @nameTheExercise.
  ///
  /// In en, this message translates to:
  /// **'Name the exercise.'**
  String get nameTheExercise;

  /// No description provided for @atLeastOneImplement.
  ///
  /// In en, this message translates to:
  /// **'At least one implement.'**
  String get atLeastOneImplement;

  /// No description provided for @anIncrementMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'An increment must be positive.'**
  String get anIncrementMustBePositive;

  /// No description provided for @enterAPositiveStep.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive step.'**
  String get enterAPositiveStep;

  /// No description provided for @repsInReserve.
  ///
  /// In en, this message translates to:
  /// **'Reps in reserve'**
  String get repsInReserve;

  /// No description provided for @loadPerImplement.
  ///
  /// In en, this message translates to:
  /// **'Load per implement'**
  String get loadPerImplement;

  /// No description provided for @restAfterThisSet.
  ///
  /// In en, this message translates to:
  /// **'Rest after this set'**
  String get restAfterThisSet;

  /// No description provided for @enterHowLongTheSet.
  ///
  /// In en, this message translates to:
  /// **'Enter how long the set lasted.'**
  String get enterHowLongTheSet;

  /// No description provided for @repsDonePerSide.
  ///
  /// In en, this message translates to:
  /// **'Reps done per side'**
  String get repsDonePerSide;

  /// No description provided for @plannedRepminRepmax.
  ///
  /// In en, this message translates to:
  /// **'Planned {repMin}–{repMax}'**
  String plannedRepminRepmax(Object repMin, Object repMax);

  /// No description provided for @restTakenBeforeTheNext.
  ///
  /// In en, this message translates to:
  /// **'Rest taken before the next set'**
  String get restTakenBeforeTheNext;

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipment;

  /// No description provided for @implementsUsedTogether.
  ///
  /// In en, this message translates to:
  /// **'Implements used together'**
  String get implementsUsedTogether;

  /// No description provided for @smallestLoadStepOptional.
  ///
  /// In en, this message translates to:
  /// **'Smallest load step (optional)'**
  String get smallestLoadStepOptional;

  /// No description provided for @theSmallestChangeYourPlates.
  ///
  /// In en, this message translates to:
  /// **'The smallest change your plates, dumbbells or machine allow, remembered for this equipment.'**
  String get theSmallestChangeYourPlates;

  /// No description provided for @loadStep.
  ///
  /// In en, this message translates to:
  /// **'Load step'**
  String get loadStep;

  /// No description provided for @finishWithIncompleteData.
  ///
  /// In en, this message translates to:
  /// **'Finish with incomplete data?'**
  String get finishWithIncompleteData;

  /// No description provided for @leaveWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get leaveWithoutSaving;

  /// No description provided for @theLastChangeCouldNot.
  ///
  /// In en, this message translates to:
  /// **'The last change could not be saved.'**
  String get theLastChangeCouldNot;

  /// No description provided for @comparedWithAPlanChosen.
  ///
  /// In en, this message translates to:
  /// **'Compared with a plan chosen after the workout. Planned values are hints, not results.'**
  String get comparedWithAPlanChosen;

  /// No description provided for @lastSet.
  ///
  /// In en, this message translates to:
  /// **'Last set'**
  String get lastSet;

  /// No description provided for @templateName.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get templateName;

  /// No description provided for @betweenExercises.
  ///
  /// In en, this message translates to:
  /// **'Between exercises'**
  String get betweenExercises;

  /// No description provided for @betweenRounds.
  ///
  /// In en, this message translates to:
  /// **'Between rounds'**
  String get betweenRounds;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// No description provided for @yourEditsToThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'Your edits to this workout are not saved.'**
  String get yourEditsToThisWorkout;

  /// No description provided for @estimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration'**
  String get estimatedDuration;

  /// No description provided for @workingSets.
  ///
  /// In en, this message translates to:
  /// **'Working sets'**
  String get workingSets;

  /// No description provided for @estimatedExternalVolume.
  ///
  /// In en, this message translates to:
  /// **'Estimated external volume'**
  String get estimatedExternalVolume;

  /// No description provided for @loadRaisedFromUnitTo.
  ///
  /// In en, this message translates to:
  /// **'Load raised from {unit} to {unit2} after your review (rule v{ruleVersion}).'**
  String loadRaisedFromUnitTo(Object unit, Object unit2, Object ruleVersion);

  /// No description provided for @thePlannedWorkoutHasNo.
  ///
  /// In en, this message translates to:
  /// **'The planned workout has no exercises to log from.'**
  String get thePlannedWorkoutHasNo;

  /// No description provided for @completedSets.
  ///
  /// In en, this message translates to:
  /// **'Completed sets'**
  String get completedSets;

  /// No description provided for @knownExternalVolume.
  ///
  /// In en, this message translates to:
  /// **'Known external volume'**
  String get knownExternalVolume;

  /// No description provided for @updateStrengthSessions2.
  ///
  /// In en, this message translates to:
  /// **'Update strength sessions?'**
  String get updateStrengthSessions2;

  /// No description provided for @upcomingSessionsArePlannedAgain.
  ///
  /// In en, this message translates to:
  /// **'Upcoming sessions are planned again from today: strength follows your race goals on every strength day, with sessions that vary. Completed and skipped workouts stay; exercises you changed in an upcoming strength session are replaced.'**
  String get upcomingSessionsArePlannedAgain;

  /// No description provided for @thisSessionUsesAnEarlier.
  ///
  /// In en, this message translates to:
  /// **'This session uses an earlier strength template. Updated plans vary strength by phase and race goal and use every strength day.'**
  String get thisSessionUsesAnEarlier;

  /// No description provided for @estimated1rmUsesEpleyAnd.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM uses Epley and Brzycki on completed working sets of 1–10 reps with a known load, shown as the range between them. It is an estimate, not a tested maximum.'**
  String get estimated1rmUsesEpleyAnd;

  /// No description provided for @localWeather.
  ///
  /// In en, this message translates to:
  /// **'Local weather'**
  String get localWeather;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @overcast.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get overcast;

  /// No description provided for @partlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get partlyCloudy;

  /// No description provided for @collapseName.
  ///
  /// In en, this message translates to:
  /// **'Collapse {name}'**
  String collapseName(Object name);

  /// No description provided for @variableLoads.
  ///
  /// In en, this message translates to:
  /// **'Variable loads'**
  String get variableLoads;

  /// No description provided for @ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions.
  ///
  /// In en, this message translates to:
  /// **'Rule v{strengthProgressionRuleVersion}: the last {strengthProgressionMinSessions} comparable sessions, every set done at the top of its repetition target with effort recorded and not harder than intended. {reason}'**
  String
  ruleVstrengthprogressionruleversionTheLastStrengthprogressionminsessions(
    Object strengthProgressionRuleVersion,
    Object strengthProgressionMinSessions,
    Object reason,
  );

  /// No description provided for @stepOnYourScaleBefore.
  ///
  /// In en, this message translates to:
  /// **'Step on your scale before scanning'**
  String get stepOnYourScaleBefore;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pair;

  /// No description provided for @selectYourAktiiaPWristband.
  ///
  /// In en, this message translates to:
  /// **'Select your AKTIIA P… wristband. Place it on the charger to wake it up if not visible.'**
  String get selectYourAktiiaPWristband;

  /// No description provided for @measurementInterruptedWhileTheApp.
  ///
  /// In en, this message translates to:
  /// **'Measurement interrupted while the app was in the background. Please repeat it.'**
  String get measurementInterruptedWhileTheApp;

  /// No description provided for @noRecentRrDataWith.
  ///
  /// In en, this message translates to:
  /// **'No recent RR data with good contact. Check the strap and repeat the measurement.'**
  String get noRecentRrDataWith;

  /// No description provided for @settlingStayStill.
  ///
  /// In en, this message translates to:
  /// **'Settling · stay still'**
  String get settlingStayStill;

  /// No description provided for @deleteSpotHrvMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Delete spot HRV measurement?'**
  String get deleteSpotHrvMeasurement;

  /// No description provided for @thisRemovesTheRecordingAnd.
  ///
  /// In en, this message translates to:
  /// **'This removes the recording and its raw RR intervals.'**
  String get thisRemovesTheRecordingAnd;

  /// No description provided for @appleHealthStoppedAnsweringSo.
  ///
  /// In en, this message translates to:
  /// **'Apple Health stopped answering, so Fjelia disconnected it and no longer reads or writes Health data.\n\nAllow Fjelia again under Settings → Health → Data Access & Devices → Fjelia, then reconnect Apple Health.'**
  String get appleHealthStoppedAnsweringSo;

  /// No description provided for @thisRemovesTheSelectedGrip.
  ///
  /// In en, this message translates to:
  /// **'This removes the selected grip reading.'**
  String get thisRemovesTheSelectedGrip;

  /// No description provided for @hideReminderDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Hide reminder diagnostics'**
  String get hideReminderDiagnostics;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @touchTheChartForDetails.
  ///
  /// In en, this message translates to:
  /// **'Touch the chart for details'**
  String get touchTheChartForDetails;

  /// No description provided for @indoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get indoor;

  /// No description provided for @road.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get road;

  /// No description provided for @technical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get technical;

  /// No description provided for @snow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get snow;

  /// No description provided for @pool.
  ///
  /// In en, this message translates to:
  /// **'Pool'**
  String get pool;

  /// No description provided for @openWater.
  ///
  /// In en, this message translates to:
  /// **'Open water'**
  String get openWater;

  /// No description provided for @ambientTemperatureC.
  ///
  /// In en, this message translates to:
  /// **'Ambient temperature °C'**
  String get ambientTemperatureC;

  /// No description provided for @carryAboutGelsGelsGelcarbs.
  ///
  /// In en, this message translates to:
  /// **'Carry about {gels} gels ({gelCarbs} g carbs each) + {bottles} × {bottleMl} ml bottles. {drinkCarbs} g carbohydrate comes from the drink mix.'**
  String carryAboutGelsGelsGelcarbs(
    Object gels,
    Object gelCarbs,
    Object bottles,
    Object bottleMl,
    Object drinkCarbs,
  );

  /// No description provided for @intakeNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Intake not recorded'**
  String get intakeNotRecorded;

  /// No description provided for @loggingDeclinedIntakeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Logging declined — intake unknown'**
  String get loggingDeclinedIntakeUnknown;

  /// No description provided for @confirmedNoIntake.
  ///
  /// In en, this message translates to:
  /// **'Confirmed: no intake'**
  String get confirmedNoIntake;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft · '**
  String get draft;

  /// No description provided for @actualIntakePerServing.
  ///
  /// In en, this message translates to:
  /// **'Actual intake · per serving'**
  String get actualIntakePerServing;

  /// No description provided for @minuteIntoWorkoutDuringOnly.
  ///
  /// In en, this message translates to:
  /// **'Minute into workout (during only, optional)'**
  String get minuteIntoWorkoutDuringOnly;

  /// No description provided for @sodiumMgServingNotSalt.
  ///
  /// In en, this message translates to:
  /// **'Sodium mg / serving (not salt)'**
  String get sodiumMgServingNotSalt;

  /// No description provided for @comfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get comfortable;

  /// No description provided for @mildSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Mild symptoms'**
  String get mildSymptoms;

  /// No description provided for @moderateSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Moderate symptoms'**
  String get moderateSymptoms;

  /// No description provided for @severeSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Severe symptoms'**
  String get severeSymptoms;

  /// No description provided for @personalNutritionSettings.
  ///
  /// In en, this message translates to:
  /// **'Personal nutrition settings'**
  String get personalNutritionSettings;

  /// No description provided for @practisedCarbohydrateToleranceGH.
  ///
  /// In en, this message translates to:
  /// **'Practised carbohydrate tolerance g/h (up to 120)'**
  String get practisedCarbohydrateToleranceGH;

  /// No description provided for @workoutNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Workout notifications enabled'**
  String get workoutNotificationsEnabled;

  /// No description provided for @exportTheMonthlyReportAs.
  ///
  /// In en, this message translates to:
  /// **'Export the monthly report as PDF in the Hilo app, then choose it here. Only the readings are imported; name, e-mail and body data in the report are ignored.'**
  String get exportTheMonthlyReportAs;

  /// No description provided for @nothingNewAllReadingsWere.
  ///
  /// In en, this message translates to:
  /// **'Nothing new: all readings were already stored.'**
  String get nothingNewAllReadingsWere;

  /// No description provided for @historyImportIncomplete.
  ///
  /// In en, this message translates to:
  /// **'History import incomplete'**
  String get historyImportIncomplete;

  /// No description provided for @youCanKeepUsingFjelia.
  ///
  /// In en, this message translates to:
  /// **'You can keep using Fjelia, but keep it open: iOS pauses the import when the app is in the background and it continues the next time you open Fjelia. Your plan is calibrated when the import finishes.'**
  String get youCanKeepUsingFjelia;

  /// No description provided for @addYourBirthYearIn.
  ///
  /// In en, this message translates to:
  /// **'Add your birth year in Settings → Profile to see your estimate.'**
  String get addYourBirthYearIn;

  /// No description provided for @fitnessAge.
  ///
  /// In en, this message translates to:
  /// **'Fitness Age'**
  String get fitnessAge;

  /// No description provided for @estLifespan.
  ///
  /// In en, this message translates to:
  /// **'Est. Lifespan'**
  String get estLifespan;

  /// No description provided for @delta.
  ///
  /// In en, this message translates to:
  /// **'Delta'**
  String get delta;

  /// No description provided for @couldNotOpenKey.
  ///
  /// In en, this message translates to:
  /// **'Could not open {key}'**
  String couldNotOpenKey(Object key);

  /// No description provided for @appleIntelligenceIsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence is not available on this device (it needs a supported iPhone or Mac with iOS/macOS 26 or later and Apple Intelligence switched on in Settings). Choose another provider and add your own API key to use the coach.'**
  String get appleIntelligenceIsNotAvailable;

  /// No description provided for @personalisedMorningLunchAfternoonEvening.
  ///
  /// In en, this message translates to:
  /// **'Personalised morning/lunch/afternoon/evening summary'**
  String get personalisedMorningLunchAfternoonEvening;

  /// No description provided for @enterASubject.
  ///
  /// In en, this message translates to:
  /// **'Enter a subject.'**
  String get enterASubject;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @enterAMessageOfAt.
  ///
  /// In en, this message translates to:
  /// **'Enter a message of at least 10 characters.'**
  String get enterAMessageOfAt;

  /// No description provided for @garminConnect.
  ///
  /// In en, this message translates to:
  /// **'Garmin Connect'**
  String get garminConnect;

  /// No description provided for @hiloBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Hilo (Blood Pressure)'**
  String get hiloBloodPressure;

  /// No description provided for @renphoBodyScale.
  ///
  /// In en, this message translates to:
  /// **'Renpho (Body Scale)'**
  String get renphoBodyScale;

  /// No description provided for @hiloPodCuff.
  ///
  /// In en, this message translates to:
  /// **'Hilo pod / cuff'**
  String get hiloPodCuff;

  /// No description provided for @disconnectLabel.
  ///
  /// In en, this message translates to:
  /// **'Disconnect {label}?'**
  String disconnectLabel(Object label);

  /// No description provided for @yourSavedMeasurementsWillRemain.
  ///
  /// In en, this message translates to:
  /// **'Your saved measurements will remain on this device.'**
  String get yourSavedMeasurementsWillRemain;

  /// No description provided for @notEnoughRecentHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Not enough recent heart-rate data to adjust zones.'**
  String get notEnoughRecentHeartRate;

  /// No description provided for @aerobicBase.
  ///
  /// In en, this message translates to:
  /// **'Aerobic Base'**
  String get aerobicBase;

  /// No description provided for @tempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get tempo;

  /// No description provided for @lactateThreshold.
  ///
  /// In en, this message translates to:
  /// **'Lactate Threshold'**
  String get lactateThreshold;

  /// No description provided for @birthYearHeightWaist.
  ///
  /// In en, this message translates to:
  /// **'Birth year, height, waist'**
  String get birthYearHeightWaist;

  /// No description provided for @enterAValidValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value'**
  String get enterAValidValue;

  /// No description provided for @birthYear.
  ///
  /// In en, this message translates to:
  /// **'Birth year'**
  String get birthYear;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @waist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get waist;

  /// No description provided for @yearsSinceQuit.
  ///
  /// In en, this message translates to:
  /// **'Years since quit'**
  String get yearsSinceQuit;

  /// No description provided for @cigarettesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Cigarettes per day'**
  String get cigarettesPerDay;

  /// No description provided for @standardDrinksPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Standard drinks per month'**
  String get standardDrinksPerMonth;

  /// No description provided for @enterAValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterAValidNumber;

  /// No description provided for @enterARaceName.
  ///
  /// In en, this message translates to:
  /// **'Enter a race name'**
  String get enterARaceName;

  /// No description provided for @useHMmOrH.
  ///
  /// In en, this message translates to:
  /// **'Use h:mm or h:mm:ss, a time you could really run'**
  String get useHMmOrH;

  /// No description provided for @flexibleThePlanMayDrop.
  ///
  /// In en, this message translates to:
  /// **'Flexible: the plan may drop this event if it clashes with a more important one.'**
  String get flexibleThePlanMayDrop;

  /// No description provided for @selectARaceDate.
  ///
  /// In en, this message translates to:
  /// **'Select a race date'**
  String get selectARaceDate;

  /// No description provided for @thatIsTenTimesOr.
  ///
  /// In en, this message translates to:
  /// **'That is ten times (or a tenth of) the usual {likely} km. Use {likely} km instead?'**
  String thatIsTenTimesOr(Object likely);

  /// No description provided for @addGoal.
  ///
  /// In en, this message translates to:
  /// **'Add Goal'**
  String get addGoal;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get restoreFailed;

  /// No description provided for @replaceLocalData.
  ///
  /// In en, this message translates to:
  /// **'Replace local data?'**
  String get replaceLocalData;

  /// No description provided for @restoringThisBackupReplacesAll.
  ///
  /// In en, this message translates to:
  /// **'Restoring this backup replaces all local health and training records. Existing login credentials are kept.'**
  String get restoringThisBackupReplacesAll;

  /// No description provided for @openingBackupZip.
  ///
  /// In en, this message translates to:
  /// **'Opening backup ZIP'**
  String get openingBackupZip;

  /// No description provided for @addAFutureRaceGoal.
  ///
  /// In en, this message translates to:
  /// **'Add a future race goal first.'**
  String get addAFutureRaceGoal;

  /// No description provided for @deleteAllWorkouts2.
  ///
  /// In en, this message translates to:
  /// **'Delete all workouts?'**
  String get deleteAllWorkouts2;

  /// No description provided for @thisDeletesPlannedWorkoutsOn.
  ///
  /// In en, this message translates to:
  /// **'This deletes planned workouts on this phone and on your connected watch platform. Completed activities are kept.'**
  String get thisDeletesPlannedWorkoutsOn;

  /// No description provided for @regenerateWorkouts2.
  ///
  /// In en, this message translates to:
  /// **'Regenerate workouts?'**
  String get regenerateWorkouts2;

  /// No description provided for @noRaceGoalsYetAdd.
  ///
  /// In en, this message translates to:
  /// **'No race goals yet. Add one or sync from Garmin.'**
  String get noRaceGoalsYetAdd;

  /// No description provided for @deleteRaceGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete race goal?'**
  String get deleteRaceGoal;

  /// No description provided for @deletingFailedFailure.
  ///
  /// In en, this message translates to:
  /// **'Deleting failed: {failure}'**
  String deletingFailedFailure(Object failure);

  /// No description provided for @allPlannedWorkoutsDeletedRemoved.
  ///
  /// In en, this message translates to:
  /// **'All planned workouts deleted. Removed from your platforms: {removed}.'**
  String allPlannedWorkoutsDeletedRemoved(Object removed);

  /// No description provided for @usingCurrentLocationTostringasfixedTostringasfixed2.
  ///
  /// In en, this message translates to:
  /// **'Using current location: {toStringAsFixed}, {toStringAsFixed2}'**
  String usingCurrentLocationTostringasfixedTostringasfixed2(
    Object toStringAsFixed,
    Object toStringAsFixed2,
  );

  /// No description provided for @typeSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get typeSleep;

  /// No description provided for @typeBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get typeBloodPressure;

  /// No description provided for @addHiloBpReportPdf.
  ///
  /// In en, this message translates to:
  /// **'Add Hilo BP report (PDF)'**
  String get addHiloBpReportPdf;

  /// No description provided for @hiloCuffBle.
  ///
  /// In en, this message translates to:
  /// **'Hilo Cuff (BLE)'**
  String get hiloCuffBle;

  /// No description provided for @typeSpo2.
  ///
  /// In en, this message translates to:
  /// **'SpO₂ / Pulse Oximeter'**
  String get typeSpo2;

  /// No description provided for @typeWeightScale.
  ///
  /// In en, this message translates to:
  /// **'Weight Scale'**
  String get typeWeightScale;

  /// No description provided for @polarH10HrvMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Polar H10 HRV measurement'**
  String get polarH10HrvMeasurement;

  /// No description provided for @samplingWouldStartMinutes.
  ///
  /// In en, this message translates to:
  /// **'Sampling would start about {minutes} min after your workout ended.'**
  String samplingWouldStartMinutes(Object minutes);

  /// No description provided for @samplingStartedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Sampling started {minutes} min after your workout ended.'**
  String samplingStartedMinutes(Object minutes);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @before.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// No description provided for @during.
  ///
  /// In en, this message translates to:
  /// **'During'**
  String get during;

  /// No description provided for @after.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// No description provided for @enumWarmUp.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get enumWarmUp;

  /// No description provided for @enumWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get enumWorking;

  /// No description provided for @enumBackOff.
  ///
  /// In en, this message translates to:
  /// **'Back-off'**
  String get enumBackOff;

  /// No description provided for @enumTechnique.
  ///
  /// In en, this message translates to:
  /// **'Technique'**
  String get enumTechnique;

  /// No description provided for @enumExternalLoad.
  ///
  /// In en, this message translates to:
  /// **'External load'**
  String get enumExternalLoad;

  /// No description provided for @enumBandResistance.
  ///
  /// In en, this message translates to:
  /// **'Band / resistance'**
  String get enumBandResistance;

  /// No description provided for @enumTotalLoad.
  ///
  /// In en, this message translates to:
  /// **'Total load'**
  String get enumTotalLoad;

  /// No description provided for @enumPerImplement.
  ///
  /// In en, this message translates to:
  /// **'Per implement'**
  String get enumPerImplement;

  /// No description provided for @enumOneImplement.
  ///
  /// In en, this message translates to:
  /// **'One implement'**
  String get enumOneImplement;

  /// No description provided for @enumBothSides.
  ///
  /// In en, this message translates to:
  /// **'Both sides'**
  String get enumBothSides;

  /// No description provided for @enumAlternatingTotalReps.
  ///
  /// In en, this message translates to:
  /// **'Alternating, total reps'**
  String get enumAlternatingTotalReps;

  /// No description provided for @enumPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get enumPartial;

  /// No description provided for @enumFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get enumFailed;

  /// No description provided for @enumStraightSets.
  ///
  /// In en, this message translates to:
  /// **'Straight sets'**
  String get enumStraightSets;

  /// No description provided for @enumSuperset.
  ///
  /// In en, this message translates to:
  /// **'Superset'**
  String get enumSuperset;

  /// No description provided for @enumCircuit.
  ///
  /// In en, this message translates to:
  /// **'Circuit'**
  String get enumCircuit;

  /// No description provided for @enumRir.
  ///
  /// In en, this message translates to:
  /// **'RIR'**
  String get enumRir;

  /// No description provided for @enumRpe110.
  ///
  /// In en, this message translates to:
  /// **'RPE 1–10'**
  String get enumRpe110;

  /// No description provided for @enumBeforeTraining.
  ///
  /// In en, this message translates to:
  /// **'Before training'**
  String get enumBeforeTraining;

  /// No description provided for @enumAfterTraining.
  ///
  /// In en, this message translates to:
  /// **'After training'**
  String get enumAfterTraining;

  /// No description provided for @enumResting.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get enumResting;

  /// No description provided for @enumSeated.
  ///
  /// In en, this message translates to:
  /// **'Seated'**
  String get enumSeated;

  /// No description provided for @enumLyingDown.
  ///
  /// In en, this message translates to:
  /// **'Lying down'**
  String get enumLyingDown;

  /// No description provided for @duringRoutineGelsAreNot.
  ///
  /// In en, this message translates to:
  /// **'During: routine gels are not needed for this short/easy session. Drink to thirst.'**
  String get duringRoutineGelsAreNot;

  /// No description provided for @duringSpreadCarbohydrateAndDrinks.
  ///
  /// In en, this message translates to:
  /// **'During: spread carbohydrate and drinks over small, regular feeds. Count drink carbohydrate in the same total as gels and food.'**
  String get duringSpreadCarbohydrateAndDrinks;

  /// No description provided for @fluidIsAnEditableStarting.
  ///
  /// In en, this message translates to:
  /// **'Fluid is an editable starting estimate, not a quota. Use thirst, practised intake and measured sweat losses; do not force extra water.'**
  String get fluidIsAnEditableStarting;

  /// No description provided for @afterHaveCarbohydrateAndA.
  ///
  /// In en, this message translates to:
  /// **'After: have carbohydrate and a protein-containing meal. Prioritise refuelling and rehydration when another session is soon.'**
  String get afterHaveCarbohydrateAndA;

  /// No description provided for @swimmingPlaceALabelledBottle.
  ///
  /// In en, this message translates to:
  /// **'Swimming: place a labelled bottle on the pool deck and use set breaks for sips or feeds. Pool conditions may differ from outdoor weather.'**
  String get swimmingPlaceALabelledBottle;

  /// No description provided for @runningCarryAccessibleGelsFlasks.
  ///
  /// In en, this message translates to:
  /// **'Running: carry accessible gels/flasks or plan aid-station feeds; practise the same products and timing before racing.'**
  String get runningCarryAccessibleGelsFlasks;

  /// No description provided for @servingSizesAndToleranceMust.
  ///
  /// In en, this message translates to:
  /// **'Serving sizes and tolerance must be positive.'**
  String get servingSizesAndToleranceMust;

  /// No description provided for @enterFiniteNonNegativeMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Enter finite, non-negative measurements.'**
  String get enterFiniteNonNegativeMeasurements;

  /// No description provided for @targetsMustBeFiniteAnd.
  ///
  /// In en, this message translates to:
  /// **'Targets must be finite and non-negative.'**
  String get targetsMustBeFiniteAnd;

  /// No description provided for @conditionsMustBeFiniteOr.
  ///
  /// In en, this message translates to:
  /// **'Conditions must be finite or unknown.'**
  String get conditionsMustBeFiniteOr;

  /// No description provided for @humidityMustBeBetween0.
  ///
  /// In en, this message translates to:
  /// **'Humidity must be between 0 and 100%.'**
  String get humidityMustBeBetween0;

  /// No description provided for @noIntakeCannotIncludeFood.
  ///
  /// In en, this message translates to:
  /// **'“No intake” cannot include food or drinks.'**
  String get noIntakeCannotIncludeFood;

  /// No description provided for @addAnItemOrConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add an item or confirm that you had no intake.'**
  String get addAnItemOrConfirm;

  /// No description provided for @eachIntakeNeedsAProduct.
  ///
  /// In en, this message translates to:
  /// **'Each intake needs a product and a valid timing.'**
  String get eachIntakeNeedsAProduct;

  /// No description provided for @quantityMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be positive.'**
  String get quantityMustBePositive;

  /// No description provided for @thisActivityNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'This activity no longer exists.'**
  String get thisActivityNoLongerExists;

  /// No description provided for @practisedCarbohydrateToleranceMustNot.
  ///
  /// In en, this message translates to:
  /// **'Practised carbohydrate tolerance must not exceed 120 g/h.'**
  String get practisedCarbohydrateToleranceMustNot;

  /// No description provided for @measuredSweatRateMustBe.
  ///
  /// In en, this message translates to:
  /// **'Measured sweat rate must be positive or left unknown.'**
  String get measuredSweatRateMustBe;

  /// No description provided for @increasePractisedToleranceInNutrition.
  ///
  /// In en, this message translates to:
  /// **'Increase practised tolerance in Nutrition settings before choosing a higher target.'**
  String get increasePractisedToleranceInNutrition;

  /// No description provided for @fluidTargetExceedsYourMeasured.
  ///
  /// In en, this message translates to:
  /// **'Fluid target exceeds your measured sweat rate. Review the measurement or target.'**
  String get fluidTargetExceedsYourMeasured;

  /// No description provided for @elapsedWorkoutTimeMustBe.
  ///
  /// In en, this message translates to:
  /// **'Elapsed workout time must be positive or left blank.'**
  String get elapsedWorkoutTimeMustBe;

  /// No description provided for @intakeAmountsMustBeFinite.
  ///
  /// In en, this message translates to:
  /// **'Intake amounts must be finite and non-negative.'**
  String get intakeAmountsMustBeFinite;

  /// No description provided for @selectedStrategyUnavailableChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Selected strategy unavailable. Choose another strategy or no comparison.'**
  String get selectedStrategyUnavailableChooseAnother;

  /// No description provided for @recordYourWorkoutNutrition.
  ///
  /// In en, this message translates to:
  /// **'Record your workout nutrition'**
  String get recordYourWorkoutNutrition;

  /// No description provided for @addTheFoodAndFluids.
  ///
  /// In en, this message translates to:
  /// **'Add the food and fluids you actually consumed in your activity history.'**
  String get addTheFoodAndFluids;

  /// No description provided for @logIntake.
  ///
  /// In en, this message translates to:
  /// **'Log intake'**
  String get logIntake;

  /// No description provided for @in30Minutes.
  ///
  /// In en, this message translates to:
  /// **'In 30 minutes'**
  String get in30Minutes;

  /// No description provided for @loadSuggestionsCoverStraightSets.
  ///
  /// In en, this message translates to:
  /// **'Load suggestions cover straight sets with repetitions only.'**
  String get loadSuggestionsCoverStraightSets;

  /// No description provided for @needsStrengthprogressionminsessionsRecordedSessionsOf.
  ///
  /// In en, this message translates to:
  /// **'Needs {strengthProgressionMinSessions} recorded sessions of this exercise.'**
  String needsStrengthprogressionminsessionsRecordedSessionsOf(
    Object strengthProgressionMinSessions,
  );

  /// No description provided for @recentHistoryIsTooOld.
  ///
  /// In en, this message translates to:
  /// **'Recent history is too old for a suggestion.'**
  String get recentHistoryIsTooOld;

  /// No description provided for @theLastSessionDidNot.
  ///
  /// In en, this message translates to:
  /// **'The last session did not use one known load.'**
  String get theLastSessionDidNot;

  /// No description provided for @theLoadChangedBetweenThe.
  ///
  /// In en, this message translates to:
  /// **'The load changed between the recent sessions.'**
  String get theLoadChangedBetweenThe;

  /// No description provided for @notEverySetReachedThe.
  ///
  /// In en, this message translates to:
  /// **'Not every set reached the top of its repetition target.'**
  String get notEverySetReachedThe;

  /// No description provided for @recordEffortRirOrRpe.
  ///
  /// In en, this message translates to:
  /// **'Record effort (RIR or RPE) on the last set to get suggestions.'**
  String get recordEffortRirOrRpe;

  /// No description provided for @recentSetsWereHarderThan.
  ///
  /// In en, this message translates to:
  /// **'Recent sets were harder than intended.'**
  String get recentSetsWereHarderThan;

  /// No description provided for @thisWorkoutAlreadyHasIts.
  ///
  /// In en, this message translates to:
  /// **'This workout already has its own load; it stays as set.'**
  String get thisWorkoutAlreadyHasIts;

  /// No description provided for @yourRecentSetsMetThe.
  ///
  /// In en, this message translates to:
  /// **'Your recent sets met the progression rule. Set the smallest load step for this equipment to review a load.'**
  String get yourRecentSetsMetThe;

  /// No description provided for @thisWorkoutNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'This workout no longer exists.'**
  String get thisWorkoutNoLongerExists;

  /// No description provided for @thisStrengthPlanCannotBe.
  ///
  /// In en, this message translates to:
  /// **'This strength plan cannot be read ({message}).'**
  String thisStrengthPlanCannotBe(Object message);

  /// No description provided for @thisStrengthPlanCannotBe2.
  ///
  /// In en, this message translates to:
  /// **'This strength plan cannot be read.'**
  String get thisStrengthPlanCannotBe2;

  /// No description provided for @addAtLeastOneExercise.
  ///
  /// In en, this message translates to:
  /// **'Add at least one exercise.'**
  String get addAtLeastOneExercise;

  /// No description provided for @thisWorkoutWasChangedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'This workout was changed elsewhere. Your edits are kept; reload to see the newer version.'**
  String get thisWorkoutWasChangedElsewhere;

  /// No description provided for @thePlanThisWorkoutIs.
  ///
  /// In en, this message translates to:
  /// **'The plan this workout is compared with cannot be read.'**
  String get thePlanThisWorkoutIs;

  /// No description provided for @thisLogWasChangedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'This log was changed elsewhere. Your entries are kept; reload to see the newer version.'**
  String get thisLogWasChangedElsewhere;

  /// No description provided for @thisZipIsNotA.
  ///
  /// In en, this message translates to:
  /// **'This ZIP is not a supported Fjelia backup.'**
  String get thisZipIsNotA;

  /// No description provided for @theBackupDatabaseIsDamaged.
  ///
  /// In en, this message translates to:
  /// **'The backup database is damaged.'**
  String get theBackupDatabaseIsDamaged;

  /// No description provided for @invalidBackupData.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup data.'**
  String get invalidBackupData;

  /// No description provided for @backupTablesDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Backup tables do not match.'**
  String get backupTablesDoNotMatch;

  /// No description provided for @invalidBackupColumns.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup columns.'**
  String get invalidBackupColumns;

  /// No description provided for @migratingOriginalAppBackup.
  ///
  /// In en, this message translates to:
  /// **'Migrating original app backup'**
  String get migratingOriginalAppBackup;

  /// No description provided for @theOriginalBackupIsMissing.
  ///
  /// In en, this message translates to:
  /// **'The original backup is missing required tables.'**
  String get theOriginalBackupIsMissing;

  /// No description provided for @backupFormatOrDatabaseVersion.
  ///
  /// In en, this message translates to:
  /// **'Backup format or database version does not match.'**
  String get backupFormatOrDatabaseVersion;

  /// No description provided for @restoringRecords.
  ///
  /// In en, this message translates to:
  /// **'Restoring records'**
  String get restoringRecords;

  /// No description provided for @restoringSettings.
  ///
  /// In en, this message translates to:
  /// **'Restoring settings'**
  String get restoringSettings;

  /// No description provided for @restoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get restoreComplete;

  /// No description provided for @effortMustBeANumber.
  ///
  /// In en, this message translates to:
  /// **'Effort must be a number.'**
  String get effortMustBeANumber;

  /// No description provided for @theDurationEstimateMustBe.
  ///
  /// In en, this message translates to:
  /// **'The duration estimate must be positive.'**
  String get theDurationEstimateMustBe;

  /// No description provided for @restCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Rest cannot be negative.'**
  String get restCannotBeNegative;

  /// No description provided for @enterTheRepetitionsDoneThe.
  ///
  /// In en, this message translates to:
  /// **'Enter the repetitions done; the plan has a range.'**
  String get enterTheRepetitionsDoneThe;

  /// No description provided for @enterTheLoadThePlan.
  ///
  /// In en, this message translates to:
  /// **'Enter the load; the plan has none.'**
  String get enterTheLoadThePlan;

  /// No description provided for @enterTheResistanceThePlan.
  ///
  /// In en, this message translates to:
  /// **'Enter the resistance; the plan has none.'**
  String get enterTheResistanceThePlan;

  /// No description provided for @poorSensorContact.
  ///
  /// In en, this message translates to:
  /// **'Poor sensor contact'**
  String get poorSensorContact;

  /// No description provided for @moreThan25FromLocal.
  ///
  /// In en, this message translates to:
  /// **'More than 25% from local median'**
  String get moreThan25FromLocal;

  /// No description provided for @workoutNutrition.
  ///
  /// In en, this message translates to:
  /// **'Workout nutrition'**
  String get workoutNutrition;

  /// No description provided for @postWorkoutFoodAndFluid.
  ///
  /// In en, this message translates to:
  /// **'Post-workout food and fluid log reminder'**
  String get postWorkoutFoodAndFluid;

  /// No description provided for @postTrainingHrvMeasurementReminder.
  ///
  /// In en, this message translates to:
  /// **'Post-training HRV measurement reminder'**
  String get postTrainingHrvMeasurementReminder;

  /// No description provided for @rirRunsFrom0To.
  ///
  /// In en, this message translates to:
  /// **'RIR runs from 0 to 10+.'**
  String get rirRunsFrom0To;

  /// No description provided for @rpeRunsFrom1To.
  ///
  /// In en, this message translates to:
  /// **'RPE runs from 1 to 10.'**
  String get rpeRunsFrom1To;

  /// No description provided for @repetitionsCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Repetitions cannot be negative.'**
  String get repetitionsCannotBeNegative;

  /// No description provided for @timedWorkMustBeLonger.
  ///
  /// In en, this message translates to:
  /// **'Timed work must be longer than zero seconds.'**
  String get timedWorkMustBeLonger;

  /// No description provided for @chooseRepetitionsOrTimedWork.
  ///
  /// In en, this message translates to:
  /// **'Choose repetitions or timed work, not both.'**
  String get chooseRepetitionsOrTimedWork;

  /// No description provided for @loadMustBeAFinite.
  ///
  /// In en, this message translates to:
  /// **'Load must be a finite, non-negative number.'**
  String get loadMustBeAFinite;

  /// No description provided for @durationCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Duration cannot be negative.'**
  String get durationCannotBeNegative;

  /// No description provided for @hrTimeline.
  ///
  /// In en, this message translates to:
  /// **'HR Timeline'**
  String get hrTimeline;

  /// No description provided for @dayTrainingLoad.
  ///
  /// In en, this message translates to:
  /// **'Day Training Load'**
  String get dayTrainingLoad;

  /// No description provided for @weekdayComparison.
  ///
  /// In en, this message translates to:
  /// **'Weekday Comparison'**
  String get weekdayComparison;

  /// No description provided for @weeklyTrainingLoad.
  ///
  /// In en, this message translates to:
  /// **'Weekly Training Load'**
  String get weeklyTrainingLoad;

  /// No description provided for @zonePolarization.
  ///
  /// In en, this message translates to:
  /// **'Zone Polarization'**
  String get zonePolarization;

  /// No description provided for @elevationOverview.
  ///
  /// In en, this message translates to:
  /// **'Elevation Overview'**
  String get elevationOverview;

  /// No description provided for @trainingMonitor.
  ///
  /// In en, this message translates to:
  /// **'Training Monitor'**
  String get trainingMonitor;

  /// No description provided for @formAtlCtlTsb.
  ///
  /// In en, this message translates to:
  /// **'ATL / CTL / TSB Form'**
  String get formAtlCtlTsb;

  /// No description provided for @trainingPlanProgress.
  ///
  /// In en, this message translates to:
  /// **'Training Plan Progress'**
  String get trainingPlanProgress;

  /// No description provided for @rhrSleep.
  ///
  /// In en, this message translates to:
  /// **'RHR Sleep'**
  String get rhrSleep;

  /// No description provided for @hrvSleep.
  ///
  /// In en, this message translates to:
  /// **'HRV Sleep'**
  String get hrvSleep;

  /// No description provided for @spo2Sleep.
  ///
  /// In en, this message translates to:
  /// **'SpO₂ Sleep'**
  String get spo2Sleep;

  /// No description provided for @respRate.
  ///
  /// In en, this message translates to:
  /// **'Resp Rate'**
  String get respRate;

  /// No description provided for @stress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get stress;

  /// No description provided for @skinTemp.
  ///
  /// In en, this message translates to:
  /// **'Skin Temp'**
  String get skinTemp;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @tonightsSleep.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s Sleep'**
  String get tonightsSleep;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get activityLog;

  /// No description provided for @activityLog2.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get activityLog2;

  /// No description provided for @history2.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get history2;

  /// No description provided for @durationsecondshDurationseconds2mDistancemetersKmAvgheartrate.
  ///
  /// In en, this message translates to:
  /// **'{durationSeconds}h {durationSeconds2}m · {distanceMeters} km · {avgHeartRate} bpm · ↑{totalElevation} m'**
  String durationsecondshDurationseconds2mDistancemetersKmAvgheartrate(
    Object durationSeconds,
    Object durationSeconds2,
    Object distanceMeters,
    Object avgHeartRate,
    Object totalElevation,
  );

  /// No description provided for @heatAcclimation2.
  ///
  /// In en, this message translates to:
  /// **'HEAT ACCLIMATION'**
  String get heatAcclimation2;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'{score}%'**
  String score(Object score);

  /// No description provided for @elevation.
  ///
  /// In en, this message translates to:
  /// **'ELEVATION'**
  String get elevation;

  /// No description provided for @t12WeekHistory.
  ///
  /// In en, this message translates to:
  /// **'12-WEEK HISTORY'**
  String get t12WeekHistory;

  /// No description provided for @zonePolarization2.
  ///
  /// In en, this message translates to:
  /// **'ZONE POLARIZATION'**
  String get zonePolarization2;

  /// No description provided for @t5WeekHistory.
  ///
  /// In en, this message translates to:
  /// **'5-WEEK HISTORY'**
  String get t5WeekHistory;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'EASY %'**
  String get easy;

  /// No description provided for @withzonesOfRecordedActivitiesWith.
  ///
  /// In en, this message translates to:
  /// **'{withZones} of {recorded} activities with HR-zone data'**
  String withzonesOfRecordedActivitiesWith(Object withZones, Object recorded);

  /// No description provided for @fromsamplesReconstructedFromRecordedHr.
  ///
  /// In en, this message translates to:
  /// **'{fromSamples} reconstructed from recorded HR samples'**
  String fromsamplesReconstructedFromRecordedHr(Object fromSamples);

  /// No description provided for @easyZ12ModerateZ3.
  ///
  /// In en, this message translates to:
  /// **'Easy: Z1–2 · Moderate: Z3 · Hard: Z4–5'**
  String get easyZ12ModerateZ3;

  /// No description provided for @activitiesWithoutHrZoneData.
  ///
  /// In en, this message translates to:
  /// **'Activities without HR-zone data are excluded from percentages.'**
  String get activitiesWithoutHrZoneData;

  /// No description provided for @avgAverageUnit.
  ///
  /// In en, this message translates to:
  /// **'AVG  {average} {unit}'**
  String avgAverageUnit(Object average, Object unit);

  /// No description provided for @weekdayComparison2.
  ///
  /// In en, this message translates to:
  /// **'WEEKDAY COMPARISON'**
  String get weekdayComparison2;

  /// No description provided for @trainingPlanProgress2.
  ///
  /// In en, this message translates to:
  /// **'TRAINING PLAN PROGRESS'**
  String get trainingPlanProgress2;

  /// No description provided for @weekCurrentweekDurationinweeks.
  ///
  /// In en, this message translates to:
  /// **'Week {currentWeek} / {durationInWeeks}'**
  String weekCurrentweekDurationinweeks(
    Object currentWeek,
    Object durationInWeeks,
  );

  /// No description provided for @t30MinTimeTrialLt2.
  ///
  /// In en, this message translates to:
  /// **'30-MIN TIME TRIAL — LT2'**
  String get t30MinTimeTrialLt2;

  /// No description provided for @run30MinutesAtThe.
  ///
  /// In en, this message translates to:
  /// **'Run 30 minutes at the hardest effort you can sustain — controlled, not sprinting. Build into the effort; do not start too fast. The average pace and HR of the final 20 minutes are your LT2.'**
  String get run30MinutesAtThe;

  /// No description provided for @recordAsANormalOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Record as a normal outdoor run. Start your watch, note the time, run 30 min at race effort.'**
  String get recordAsANormalOutdoor;

  /// No description provided for @t50MinTotalFlatCourse.
  ///
  /// In en, this message translates to:
  /// **'~50 min total · flat course · not after hard training'**
  String get t50MinTotalFlatCourse;

  /// No description provided for @doNotStartTooFast.
  ///
  /// In en, this message translates to:
  /// **'Do not start too fast. Aim for even splits.'**
  String get doNotStartTooFast;

  /// No description provided for @theAppAveragesHrAnd.
  ///
  /// In en, this message translates to:
  /// **'The app averages HR and pace over the final 20 minutes of the TT, after the warm-up and first 10 minutes. Select the recorded activity in Calculate.'**
  String get theAppAveragesHrAnd;

  /// No description provided for @lt2Pace.
  ///
  /// In en, this message translates to:
  /// **'LT2 PACE'**
  String get lt2Pace;

  /// No description provided for @activityRunningEnoughTimeFor.
  ///
  /// In en, this message translates to:
  /// **'Activity (running, enough time for warm-up + 30 min, with HR)'**
  String get activityRunningEnoughTimeFor;

  /// No description provided for @selectTheTtActivity.
  ///
  /// In en, this message translates to:
  /// **'Select the TT activity'**
  String get selectTheTtActivity;

  /// No description provided for @nameStartdate.
  ///
  /// In en, this message translates to:
  /// **'{name} · {startDate}'**
  String nameStartdate(Object name, Object startDate);

  /// No description provided for @warmUpBeforeTt.
  ///
  /// In en, this message translates to:
  /// **'Warm-up before TT'**
  String get warmUpBeforeTt;

  /// No description provided for @roundMin.
  ///
  /// In en, this message translates to:
  /// **'{round} min'**
  String roundMin(Object round);

  /// No description provided for @clearResults.
  ///
  /// In en, this message translates to:
  /// **'Clear results'**
  String get clearResults;

  /// No description provided for @heartRate2.
  ///
  /// In en, this message translates to:
  /// **'HEART RATE'**
  String get heartRate2;

  /// No description provided for @paceSecKmLowerIs.
  ///
  /// In en, this message translates to:
  /// **'PACE (sec/km — lower is faster)'**
  String get paceSecKmLowerIs;

  /// No description provided for @thresholdsFitnessTests.
  ///
  /// In en, this message translates to:
  /// **'Thresholds & Fitness Tests'**
  String get thresholdsFitnessTests;

  /// No description provided for @lt1.
  ///
  /// In en, this message translates to:
  /// **'LT1'**
  String get lt1;

  /// No description provided for @lt2.
  ///
  /// In en, this message translates to:
  /// **'LT2'**
  String get lt2;

  /// No description provided for @voPace.
  ///
  /// In en, this message translates to:
  /// **'VO₂ Pace'**
  String get voPace;

  /// No description provided for @ftp.
  ///
  /// In en, this message translates to:
  /// **'FTP'**
  String get ftp;

  /// No description provided for @setFtpManually.
  ///
  /// In en, this message translates to:
  /// **'Set FTP manually'**
  String get setFtpManually;

  /// No description provided for @calculateFromAnActivity.
  ///
  /// In en, this message translates to:
  /// **'Calculate from an activity'**
  String get calculateFromAnActivity;

  /// No description provided for @setFtp.
  ///
  /// In en, this message translates to:
  /// **'Set FTP'**
  String get setFtp;

  /// No description provided for @ftpWatts.
  ///
  /// In en, this message translates to:
  /// **'FTP (watts)'**
  String get ftpWatts;

  /// No description provided for @ftpCyclingThresholdPower.
  ///
  /// In en, this message translates to:
  /// **'FTP — CYCLING THRESHOLD POWER'**
  String get ftpCyclingThresholdPower;

  /// No description provided for @ftpHistory.
  ///
  /// In en, this message translates to:
  /// **'FTP HISTORY'**
  String get ftpHistory;

  /// No description provided for @updateFromActivity.
  ///
  /// In en, this message translates to:
  /// **'UPDATE FROM ACTIVITY'**
  String get updateFromActivity;

  /// No description provided for @tapAnActivityFtpBest.
  ///
  /// In en, this message translates to:
  /// **'Tap an activity — FTP = best 20-min power × 0.95'**
  String get tapAnActivityFtpBest;

  /// No description provided for @ridew.
  ///
  /// In en, this message translates to:
  /// **'{ride}W'**
  String ridew(Object ride);

  /// No description provided for @ftpRoundw.
  ///
  /// In en, this message translates to:
  /// **'→ FTP {round}W'**
  String ftpRoundw(Object round);

  /// No description provided for @noRidesWith20Minutes.
  ///
  /// In en, this message translates to:
  /// **'No rides with 20 minutes of continuous power samples.'**
  String get noRidesWith20Minutes;

  /// No description provided for @enterFtpManually.
  ///
  /// In en, this message translates to:
  /// **'Enter FTP manually'**
  String get enterFtpManually;

  /// No description provided for @selectTheTestActivity.
  ///
  /// In en, this message translates to:
  /// **'Select the test activity'**
  String get selectTheTestActivity;

  /// No description provided for @formAtlCtlTsb2.
  ///
  /// In en, this message translates to:
  /// **'FORM · ATL / CTL / TSB'**
  String get formAtlCtlTsb2;

  /// No description provided for @closeTrainingFormFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Close training form fullscreen'**
  String get closeTrainingFormFullscreen;

  /// No description provided for @expandTrainingForm.
  ///
  /// In en, this message translates to:
  /// **'Expand training form'**
  String get expandTrainingForm;

  /// No description provided for @calculatedFromTheFirstAvailable.
  ///
  /// In en, this message translates to:
  /// **'Calculated from the first available load record. Days without recorded load count as zero; earlier training is unknown.'**
  String get calculatedFromTheFirstAvailable;

  /// No description provided for @trainingMonitor2.
  ///
  /// In en, this message translates to:
  /// **'TRAINING MONITOR'**
  String get trainingMonitor2;

  /// No description provided for @pfitzingerZones.
  ///
  /// In en, this message translates to:
  /// **'PFITZINGER ZONES'**
  String get pfitzingerZones;

  /// No description provided for @cyclingPowerZones.
  ///
  /// In en, this message translates to:
  /// **'CYCLING POWER ZONES'**
  String get cyclingPowerZones;

  /// No description provided for @znumber.
  ///
  /// In en, this message translates to:
  /// **'Z{number}'**
  String znumber(Object number);

  /// No description provided for @paceHrDescription.
  ///
  /// In en, this message translates to:
  /// **'{pace} · {hr}\n{description}'**
  String paceHrDescription(Object pace, Object hr, Object description);

  /// No description provided for @weeklyTrainingLoad2.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY TRAINING LOAD'**
  String get weeklyTrainingLoad2;

  /// No description provided for @prevWeek.
  ///
  /// In en, this message translates to:
  /// **'PREV WEEK'**
  String get prevWeek;

  /// No description provided for @bySport.
  ///
  /// In en, this message translates to:
  /// **'BY SPORT'**
  String get bySport;

  /// No description provided for @noActivitiesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No activities this week'**
  String get noActivitiesThisWeek;

  /// No description provided for @garminWorkoutScheduleddate.
  ///
  /// In en, this message translates to:
  /// **'Garmin Workout · {scheduledDate}'**
  String garminWorkoutScheduleddate(Object scheduledDate);

  /// No description provided for @yourNote.
  ///
  /// In en, this message translates to:
  /// **'Your note'**
  String get yourNote;

  /// No description provided for @askAiCoach.
  ///
  /// In en, this message translates to:
  /// **'Ask AI Coach'**
  String get askAiCoach;

  /// No description provided for @aiSettings.
  ///
  /// In en, this message translates to:
  /// **'AI settings'**
  String get aiSettings;

  /// No description provided for @askYourCoach.
  ///
  /// In en, this message translates to:
  /// **'Ask your coach…'**
  String get askYourCoach;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @sendFeedbackOrReportA.
  ///
  /// In en, this message translates to:
  /// **'Send feedback or report a bug'**
  String get sendFeedbackOrReportA;

  /// No description provided for @addMeasurement2.
  ///
  /// In en, this message translates to:
  /// **'Add measurement'**
  String get addMeasurement2;

  /// No description provided for @syncLabel2.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncLabel2;

  /// No description provided for @syncToday.
  ///
  /// In en, this message translates to:
  /// **'Sync Today'**
  String get syncToday;

  /// No description provided for @fullSync1Year.
  ///
  /// In en, this message translates to:
  /// **'Full Sync · 1 year'**
  String get fullSync1Year;

  /// No description provided for @fullSyncComplete.
  ///
  /// In en, this message translates to:
  /// **'Full Sync · Complete'**
  String get fullSyncComplete;

  /// No description provided for @syncingYourData.
  ///
  /// In en, this message translates to:
  /// **'Syncing your data…'**
  String get syncingYourData;

  /// No description provided for @lLeftkgRRightkgKg2.
  ///
  /// In en, this message translates to:
  /// **'L {leftKg}  R {rightKg} kg'**
  String lLeftkgRRightkgKg2(Object leftKg, Object rightKg);

  /// No description provided for @weightKgFatBodyfatMuscle.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg · Fat {bodyFat}% · Muscle {muscleMass} kg'**
  String weightKgFatBodyfatMuscle(
    Object weight,
    Object bodyFat,
    Object muscleMass,
  );

  /// No description provided for @titleSportTolowercase.
  ///
  /// In en, this message translates to:
  /// **'{title}, {sport}, {toLowerCase}'**
  String titleSportTolowercase(Object title, Object sport, Object toLowerCase);

  /// No description provided for @weatherUnavailableTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Weather unavailable · Tap to retry'**
  String get weatherUnavailableTapToRetry;

  /// No description provided for @weatherSetYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Weather · Set your location'**
  String get weatherSetYourLocation;

  /// No description provided for @t7DayForecast.
  ///
  /// In en, this message translates to:
  /// **'7-DAY FORECAST'**
  String get t7DayForecast;

  /// No description provided for @minMax.
  ///
  /// In en, this message translates to:
  /// **'min/max'**
  String get minMax;

  /// No description provided for @rainMm2.
  ///
  /// In en, this message translates to:
  /// **'rain mm'**
  String get rainMm2;

  /// No description provided for @uvMax.
  ///
  /// In en, this message translates to:
  /// **'UV max'**
  String get uvMax;

  /// No description provided for @kmH.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get kmH;

  /// No description provided for @alt.
  ///
  /// In en, this message translates to:
  /// **'→ {alt}'**
  String alt(Object alt);

  /// No description provided for @raceGoalsLength.
  ///
  /// In en, this message translates to:
  /// **'Race goals · {length}'**
  String raceGoalsLength(Object length);

  /// No description provided for @gWk.
  ///
  /// In en, this message translates to:
  /// **'{g} wk'**
  String gWk(Object g);

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'{weeks}'**
  String weeks(Object weeks);

  /// No description provided for @weeks2.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get weeks2;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get upcoming;

  /// No description provided for @lengthMoreDays.
  ///
  /// In en, this message translates to:
  /// **'+ {length} more days'**
  String lengthMoreDays(Object length);

  /// No description provided for @yearMonth.
  ///
  /// In en, this message translates to:
  /// **'{year} / {month}'**
  String yearMonth(Object year, Object month);

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'{day}'**
  String day(Object day);

  /// No description provided for @plannedCompletedSkipped.
  ///
  /// In en, this message translates to:
  /// **'○ Planned   ● Completed   ✕ Skipped'**
  String get plannedCompletedSkipped;

  /// No description provided for @heartRate3.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get heartRate3;

  /// No description provided for @watts.
  ///
  /// In en, this message translates to:
  /// **'Watts'**
  String get watts;

  /// No description provided for @theStepsAddUpTo.
  ///
  /// In en, this message translates to:
  /// **'The steps add up to {total}; the plan counts {plannedDurationMin} min.'**
  String theStepsAddUpTo(Object total, Object plannedDurationMin);

  /// No description provided for @typicalSplitForThisKind.
  ///
  /// In en, this message translates to:
  /// **'Typical split for this kind of session; no steps to calculate it from.'**
  String get typicalSplitForThisKind;

  /// No description provided for @labelGetsEachExerciseWith.
  ///
  /// In en, this message translates to:
  /// **'{label} gets each exercise with its sets, reps and loads. Rep ranges, effort and tempo stay in Fjelia.'**
  String labelGetsEachExerciseWith(Object label);

  /// No description provided for @markAsRest.
  ///
  /// In en, this message translates to:
  /// **'Mark as Rest'**
  String get markAsRest;

  /// No description provided for @restoreWorkout.
  ///
  /// In en, this message translates to:
  /// **'Restore workout'**
  String get restoreWorkout;

  /// No description provided for @skipThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'Skip this workout?'**
  String get skipThisWorkout;

  /// No description provided for @previousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get previousWeek;

  /// No description provided for @backToThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Back to this week'**
  String get backToThisWeek;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeek;

  /// No description provided for @today2.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get today2;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'ROUTE'**
  String get route;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @plannedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Planned Workout'**
  String get plannedWorkout;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @chatAi.
  ///
  /// In en, this message translates to:
  /// **'Chat AI'**
  String get chatAi;

  /// No description provided for @trainingLoad.
  ///
  /// In en, this message translates to:
  /// **'Training Load'**
  String get trainingLoad;

  /// No description provided for @dayTrainingLoad2.
  ///
  /// In en, this message translates to:
  /// **'DAY TRAINING LOAD'**
  String get dayTrainingLoad2;

  /// No description provided for @trimp.
  ///
  /// In en, this message translates to:
  /// **' TRIMP'**
  String get trimp;

  /// No description provided for @scorebeforeScoreafter.
  ///
  /// In en, this message translates to:
  /// **'{scoreBefore} → {scoreAfter}'**
  String scorebeforeScoreafter(Object scoreBefore, Object scoreAfter);

  /// No description provided for @temperatureOverTime.
  ///
  /// In en, this message translates to:
  /// **'TEMPERATURE OVER TIME'**
  String get temperatureOverTime;

  /// No description provided for @roundh.
  ///
  /// In en, this message translates to:
  /// **'{round}h'**
  String roundh(Object round);

  /// No description provided for @timeInHrZones.
  ///
  /// In en, this message translates to:
  /// **'Time in HR zones'**
  String get timeInHrZones;

  /// No description provided for @route2.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route2;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @gpx.
  ///
  /// In en, this message translates to:
  /// **'GPX'**
  String get gpx;

  /// No description provided for @touppercasesubstringBriefing.
  ///
  /// In en, this message translates to:
  /// **'{toUpperCase}{substring} Briefing'**
  String touppercasesubstringBriefing(Object toUpperCase, Object substring);

  /// No description provided for @chatWithAiAboutThis.
  ///
  /// In en, this message translates to:
  /// **'Chat with AI about this briefing'**
  String get chatWithAiAboutThis;

  /// No description provided for @whyThisRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Why this recommendation?'**
  String get whyThisRecommendation;

  /// No description provided for @titleDateLabel.
  ///
  /// In en, this message translates to:
  /// **'{title}, {date}, {label}'**
  String titleDateLabel(Object title, Object date, Object label);

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get updating;

  /// No description provided for @resting.
  ///
  /// In en, this message translates to:
  /// **'RESTING'**
  String get resting;

  /// No description provided for @noTimedReadings.
  ///
  /// In en, this message translates to:
  /// **'No timed readings'**
  String get noTimedReadings;

  /// No description provided for @avg.
  ///
  /// In en, this message translates to:
  /// **'AVG'**
  String get avg;

  /// No description provided for @peak.
  ///
  /// In en, this message translates to:
  /// **'PEAK'**
  String get peak;

  /// No description provided for @tolocalRoundmin.
  ///
  /// In en, this message translates to:
  /// **'{toLocal} · {round}min'**
  String tolocalRoundmin(Object toLocal, Object round);

  /// No description provided for @avgheartrateBpmAvg.
  ///
  /// In en, this message translates to:
  /// **'{avgHeartRate} bpm avg'**
  String avgheartrateBpmAvg(Object avgHeartRate);

  /// No description provided for @timeWeightedAverageOverRecorded.
  ///
  /// In en, this message translates to:
  /// **'Time-weighted average over recorded periods. Gaps without readings are excluded.'**
  String get timeWeightedAverageOverRecorded;

  /// No description provided for @previousHeartRatePeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous heart-rate period'**
  String get previousHeartRatePeriod;

  /// No description provided for @nextHeartRatePeriod.
  ///
  /// In en, this message translates to:
  /// **'Next heart-rate period'**
  String get nextHeartRatePeriod;

  /// No description provided for @avgHr.
  ///
  /// In en, this message translates to:
  /// **'Avg HR'**
  String get avgHr;

  /// No description provided for @restingHr.
  ///
  /// In en, this message translates to:
  /// **'Resting HR'**
  String get restingHr;

  /// No description provided for @both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get both;

  /// No description provided for @averagelabelFixedMs.
  ///
  /// In en, this message translates to:
  /// **'{averageLabel} {fixed} ms'**
  String averagelabelFixedMs(Object averageLabel, Object fixed);

  /// No description provided for @measureWithPolarH10.
  ///
  /// In en, this message translates to:
  /// **'Measure with Polar H10'**
  String get measureWithPolarH10;

  /// No description provided for @ms.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get ms;

  /// No description provided for @noWorkoutInThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No workout in this period has a comparable before and after pair.'**
  String get noWorkoutInThisPeriod;

  /// No description provided for @textEachWorkoutCountsOnce.
  ///
  /// In en, this message translates to:
  /// **'{text}. Each workout counts once; this describes your pairs, it does not score them.'**
  String textEachWorkoutCountsOnce(Object text);

  /// No description provided for @workoutFinished.
  ///
  /// In en, this message translates to:
  /// **'Workout finished?'**
  String get workoutFinished;

  /// No description provided for @yourWorkoutIsNotIn.
  ///
  /// In en, this message translates to:
  /// **'Your workout is not in Fjelia yet. If it ended, say when, and the reminder can follow its real end. Otherwise it appears once your watch syncs.'**
  String get yourWorkoutIsNotIn;

  /// No description provided for @workoutFinished2.
  ///
  /// In en, this message translates to:
  /// **'Workout finished'**
  String get workoutFinished2;

  /// No description provided for @theWorkoutMustStartAfter.
  ///
  /// In en, this message translates to:
  /// **'The workout must start after the measurement and end after it started, not in the future.'**
  String get theWorkoutMustStartAfter;

  /// No description provided for @daysDAvg.
  ///
  /// In en, this message translates to:
  /// **'{days} D AVG'**
  String daysDAvg(Object days);

  /// No description provided for @averageUnit.
  ///
  /// In en, this message translates to:
  /// **'{average} {unit}'**
  String averageUnit(Object average, Object unit);

  /// No description provided for @baselineUnit.
  ///
  /// In en, this message translates to:
  /// **'{baseline} {unit}'**
  String baselineUnit(Object baseline, Object unit);

  /// No description provided for @previousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get previousPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get nextPeriod;

  /// No description provided for @overnightHrvReflectsRecoveryCompare.
  ///
  /// In en, this message translates to:
  /// **'Overnight HRV reflects recovery. Compare your readings with your own baseline over time.'**
  String get overnightHrvReflectsRecoveryCompare;

  /// No description provided for @moveThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'MOVE THIS WORKOUT'**
  String get moveThisWorkout;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @movedFromMovedfrom.
  ///
  /// In en, this message translates to:
  /// **'Moved from {movedFrom}'**
  String movedFromMovedfrom(Object movedFrom);

  /// No description provided for @hrvAroundThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'HRV around this workout'**
  String get hrvAroundThisWorkout;

  /// No description provided for @measureAfterTraining.
  ///
  /// In en, this message translates to:
  /// **'Measure after training'**
  String get measureAfterTraining;

  /// No description provided for @measureAgain.
  ///
  /// In en, this message translates to:
  /// **'Measure again'**
  String get measureAgain;

  /// No description provided for @explainWithAi.
  ///
  /// In en, this message translates to:
  /// **'Explain with AI'**
  String get explainWithAi;

  /// No description provided for @beforeEndedPregapAheadOf.
  ///
  /// In en, this message translates to:
  /// **'Before ended {preGap} ahead of the start.'**
  String beforeEndedPregapAheadOf(Object preGap);

  /// No description provided for @lengthFurtherMeasurementSAfter.
  ///
  /// In en, this message translates to:
  /// **'{length} further measurement(s) after this workout are kept as extra observations.'**
  String lengthFurtherMeasurementSAfter(Object length);

  /// No description provided for @noHrvMeasurementRecordedAround.
  ///
  /// In en, this message translates to:
  /// **'No HRV measurement recorded around this workout.'**
  String get noHrvMeasurementRecordedAround;

  /// No description provided for @measureHrv.
  ///
  /// In en, this message translates to:
  /// **'Measure HRV'**
  String get measureHrv;

  /// No description provided for @deltamsMs.
  ///
  /// In en, this message translates to:
  /// **'{deltaMs} ms'**
  String deltamsMs(Object deltaMs);

  /// No description provided for @deltapercent.
  ///
  /// In en, this message translates to:
  /// **'{deltaPercent} %'**
  String deltapercent(Object deltaPercent);

  /// No description provided for @aDescriptionOfThisPair.
  ///
  /// In en, this message translates to:
  /// **'A description of this pair, not a score for the workout.'**
  String get aDescriptionOfThisPair;

  /// No description provided for @notEnoughComparableWorkoutsYet.
  ///
  /// In en, this message translates to:
  /// **'Not enough comparable workouts yet, {eligible} of {need}.'**
  String notEnoughComparableWorkoutsYet(Object eligible, Object need);

  /// No description provided for @notEnoughComparableWorkoutsYet2.
  ///
  /// In en, this message translates to:
  /// **'Not enough comparable workouts yet ({eligible} of {need}).'**
  String notEnoughComparableWorkoutsYet2(Object eligible, Object need);

  /// No description provided for @yourEligibleSimilarWorkoutsTolocal.
  ///
  /// In en, this message translates to:
  /// **'Your {eligible} similar workouts · {toLocal}–{toLocal2}'**
  String yourEligibleSimilarWorkoutsTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
  );

  /// No description provided for @middleHalfQ1msToQ3ms.
  ///
  /// In en, this message translates to:
  /// **'Middle half {q1Ms} to {q3Ms} ms · median {medianMs} ms · this workout {delta} ms'**
  String middleHalfQ1msToQ3ms(
    Object q1Ms,
    Object q3Ms,
    Object medianMs,
    Object delta,
  );

  /// No description provided for @rpeI.
  ///
  /// In en, this message translates to:
  /// **'RPE {i}'**
  String rpeI(Object i);

  /// No description provided for @easy2.
  ///
  /// In en, this message translates to:
  /// **'easy'**
  String get easy2;

  /// No description provided for @allOut.
  ///
  /// In en, this message translates to:
  /// **'all out'**
  String get allOut;

  /// No description provided for @workoutProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Workout profile: {description}'**
  String workoutProfileDescription(Object description);

  /// No description provided for @noActivitiesInThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No activities in this period'**
  String get noActivitiesInThisPeriod;

  /// No description provided for @enableHeatAcclimationInTraining.
  ///
  /// In en, this message translates to:
  /// **'Enable heat acclimation in Training settings.'**
  String get enableHeatAcclimationInTraining;

  /// No description provided for @noElevationThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No elevation this week'**
  String get noElevationThisWeek;

  /// No description provided for @noActivitiesSynced.
  ///
  /// In en, this message translates to:
  /// **'No activities synced'**
  String get noActivitiesSynced;

  /// No description provided for @noHrZoneData.
  ///
  /// In en, this message translates to:
  /// **'No HR-zone data'**
  String get noHrZoneData;

  /// No description provided for @easyJogGetHrElevated.
  ///
  /// In en, this message translates to:
  /// **'Easy jog — get HR elevated, legs loose'**
  String get easyJogGetHrElevated;

  /// No description provided for @fastestSustainablePaceLikeA.
  ///
  /// In en, this message translates to:
  /// **'Fastest sustainable pace — like a 30-min race'**
  String get fastestSustainablePaceLikeA;

  /// No description provided for @walkCardiacRecovery.
  ///
  /// In en, this message translates to:
  /// **'Walk — cardiac recovery'**
  String get walkCardiacRecovery;

  /// No description provided for @selectTheTtActivityFirst.
  ///
  /// In en, this message translates to:
  /// **'Select the TT activity first.'**
  String get selectTheTtActivityFirst;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get calculating;

  /// No description provided for @calculateLt2.
  ///
  /// In en, this message translates to:
  /// **'Calculate LT2'**
  String get calculateLt2;

  /// No description provided for @enterFtpBetween30And.
  ///
  /// In en, this message translates to:
  /// **'Enter FTP between 30 and 1000 W.'**
  String get enterFtpBetween30And;

  /// No description provided for @aerobicThreshold.
  ///
  /// In en, this message translates to:
  /// **'Aerobic Threshold'**
  String get aerobicThreshold;

  /// No description provided for @functionalThresholdPower.
  ///
  /// In en, this message translates to:
  /// **'Functional Threshold Power'**
  String get functionalThresholdPower;

  /// No description provided for @estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// No description provided for @afterWarmingUpRunFive.
  ///
  /// In en, this message translates to:
  /// **'After warming up, run five minutes at your fastest sustainable effort. Record the run with speed or distance data.'**
  String get afterWarmingUpRunFive;

  /// No description provided for @recordAtLeast40Minutes.
  ///
  /// In en, this message translates to:
  /// **'Record at least 40 minutes of steady running at a constant effort. The test compares heart rate in each half to estimate aerobic drift.'**
  String get recordAtLeast40Minutes;

  /// No description provided for @theFastestFiveMinuteWindow.
  ///
  /// In en, this message translates to:
  /// **'The fastest five-minute window provides your VO2max pace.'**
  String get theFastestFiveMinuteWindow;

  /// No description provided for @noResultYet.
  ///
  /// In en, this message translates to:
  /// **'No result yet'**
  String get noResultYet;

  /// No description provided for @calculateVo2maxPace.
  ///
  /// In en, this message translates to:
  /// **'Calculate VO2max pace'**
  String get calculateVo2maxPace;

  /// No description provided for @calculateLt1.
  ///
  /// In en, this message translates to:
  /// **'Calculate LT1'**
  String get calculateLt1;

  /// No description provided for @loading2.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading2;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @noTrainingHistory.
  ///
  /// In en, this message translates to:
  /// **'No training history'**
  String get noTrainingHistory;

  /// No description provided for @fitnessCtl.
  ///
  /// In en, this message translates to:
  /// **'Fitness (CTL)'**
  String get fitnessCtl;

  /// No description provided for @fatigueAtl.
  ///
  /// In en, this message translates to:
  /// **'Fatigue (ATL)'**
  String get fatigueAtl;

  /// No description provided for @formTsb.
  ///
  /// In en, this message translates to:
  /// **'Form (TSB)'**
  String get formTsb;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get noHistory;

  /// No description provided for @fresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get fresh;

  /// No description provided for @optimal.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get optimal;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @tired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get tired;

  /// No description provided for @veryFatigued.
  ///
  /// In en, this message translates to:
  /// **'Very Fatigued'**
  String get veryFatigued;

  /// No description provided for @garminRunningVo2max.
  ///
  /// In en, this message translates to:
  /// **'Garmin running VO2max'**
  String get garminRunningVo2max;

  /// No description provided for @garminCyclingVo2max.
  ///
  /// In en, this message translates to:
  /// **'Garmin cycling VO2max'**
  String get garminCyclingVo2max;

  /// No description provided for @aerobicThreshold2.
  ///
  /// In en, this message translates to:
  /// **'Aerobic threshold'**
  String get aerobicThreshold2;

  /// No description provided for @driftDriftAt.
  ///
  /// In en, this message translates to:
  /// **'Drift {drift}% · {at}'**
  String driftDriftAt(Object drift, Object at);

  /// No description provided for @activityHours.
  ///
  /// In en, this message translates to:
  /// **'Activity hours'**
  String get activityHours;

  /// No description provided for @activityKm.
  ///
  /// In en, this message translates to:
  /// **'Activity km'**
  String get activityKm;

  /// No description provided for @tap5MinuteMaxTest.
  ///
  /// In en, this message translates to:
  /// **'Tap · 5-minute max test'**
  String get tap5MinuteMaxTest;

  /// No description provided for @setFtpToCalculatePower.
  ///
  /// In en, this message translates to:
  /// **'Set FTP to calculate power zones'**
  String get setFtpToCalculatePower;

  /// No description provided for @cyclingPowerZones2.
  ///
  /// In en, this message translates to:
  /// **'Cycling power zones'**
  String get cyclingPowerZones2;

  /// No description provided for @pfitzingerZones2.
  ///
  /// In en, this message translates to:
  /// **'Pfitzinger zones'**
  String get pfitzingerZones2;

  /// No description provided for @completeAnLt2TestTo.
  ///
  /// In en, this message translates to:
  /// **'Complete an LT2 test to calculate running zones.'**
  String get completeAnLt2TestTo;

  /// No description provided for @setFtpToCalculatePower2.
  ///
  /// In en, this message translates to:
  /// **'Set FTP to calculate power zones.'**
  String get setFtpToCalculatePower2;

  /// No description provided for @endurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get endurance;

  /// No description provided for @threshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get threshold;

  /// No description provided for @anaerobic.
  ///
  /// In en, this message translates to:
  /// **'Anaerobic'**
  String get anaerobic;

  /// No description provided for @whatExplainsThisRise.
  ///
  /// In en, this message translates to:
  /// **'What explains this rise?'**
  String get whatExplainsThisRise;

  /// No description provided for @whatExplainsThisDrop.
  ///
  /// In en, this message translates to:
  /// **'What explains this drop'**
  String get whatExplainsThisDrop;

  /// No description provided for @whatExplainsThisRise2.
  ///
  /// In en, this message translates to:
  /// **'What explains this rise'**
  String get whatExplainsThisRise2;

  /// No description provided for @editsAreKeptInFjelia.
  ///
  /// In en, this message translates to:
  /// **'Edits are kept in Fjelia as a local copy for this date. The workout on Garmin is not changed.'**
  String get editsAreKeptInFjelia;

  /// No description provided for @howDoIExecuteThis.
  ///
  /// In en, this message translates to:
  /// **'How do I execute this workout?'**
  String get howDoIExecuteThis;

  /// No description provided for @shareHealthContextWithName.
  ///
  /// In en, this message translates to:
  /// **'Share health context with {name}?'**
  String shareHealthContextWithName(Object name);

  /// No description provided for @yourMessageAndAHealth.
  ///
  /// In en, this message translates to:
  /// **'Your message and a health/training summary will be sent to this cloud AI provider. Names and GPS are excluded from the generated summary.'**
  String get yourMessageAndAHealth;

  /// No description provided for @couldNotGetAReply.
  ///
  /// In en, this message translates to:
  /// **'Could not get a reply. Check your AI settings and try again.'**
  String get couldNotGetAReply;

  /// No description provided for @askAboutYourRecoveryTraining.
  ///
  /// In en, this message translates to:
  /// **'Ask about your recovery, training, or today’s plan.'**
  String get askAboutYourRecoveryTraining;

  /// No description provided for @noSyncYet.
  ///
  /// In en, this message translates to:
  /// **'No sync yet'**
  String get noSyncYet;

  /// No description provided for @lastSyncLastContext.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {last} {context}'**
  String lastSyncLastContext(Object last, Object context);

  /// No description provided for @seasonWithTradeOffs.
  ///
  /// In en, this message translates to:
  /// **'Season: with trade-offs'**
  String get seasonWithTradeOffs;

  /// No description provided for @seasonNeedsYourDecision.
  ///
  /// In en, this message translates to:
  /// **'Season: needs your decision'**
  String get seasonNeedsYourDecision;

  /// No description provided for @seasonCannotBeCombined.
  ///
  /// In en, this message translates to:
  /// **'Season: cannot be combined'**
  String get seasonCannotBeCombined;

  /// No description provided for @seasonProvisional.
  ///
  /// In en, this message translates to:
  /// **'Season: provisional'**
  String get seasonProvisional;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @allGoalsFit.
  ///
  /// In en, this message translates to:
  /// **'All goals fit.'**
  String get allGoalsFit;

  /// No description provided for @goalTargetfinishsecondsgoal.
  ///
  /// In en, this message translates to:
  /// **'Goal {targetFinishSeconds}{goal}'**
  String goalTargetfinishsecondsgoal(Object targetFinishSeconds, Object goal);

  /// No description provided for @estEstimateestimate2.
  ///
  /// In en, this message translates to:
  /// **'Est. {estimate}{estimate2}'**
  String estEstimateestimate2(Object estimate, Object estimate2);

  /// No description provided for @doneDoneby.
  ///
  /// In en, this message translates to:
  /// **'Done · {doneBy}'**
  String doneDoneby(Object doneBy);

  /// No description provided for @garminWorkoutWorkout.
  ///
  /// In en, this message translates to:
  /// **'Garmin Workout · {workout}'**
  String garminWorkoutWorkout(Object workout);

  /// No description provided for @moveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Move anyway?'**
  String get moveAnyway;

  /// No description provided for @wattsNeedYourFtpSet.
  ///
  /// In en, this message translates to:
  /// **'Watts need your FTP: set it under Load, Thresholds.'**
  String get wattsNeedYourFtpSet;

  /// No description provided for @mainTargetInWattsFrom.
  ///
  /// In en, this message translates to:
  /// **'Main target in watts from your FTP, heart rate as the guide.'**
  String get mainTargetInWattsFrom;

  /// No description provided for @mainTargetHeartRateWatts.
  ///
  /// In en, this message translates to:
  /// **'Main target heart rate, watts are not set on the watch.'**
  String get mainTargetHeartRateWatts;

  /// No description provided for @taperPhase.
  ///
  /// In en, this message translates to:
  /// **'Taper phase'**
  String get taperPhase;

  /// No description provided for @recoverySession.
  ///
  /// In en, this message translates to:
  /// **'Recovery session'**
  String get recoverySession;

  /// No description provided for @closeToYourEvent.
  ///
  /// In en, this message translates to:
  /// **'Close to your event'**
  String get closeToYourEvent;

  /// No description provided for @noWorkoutStructureAvailable.
  ///
  /// In en, this message translates to:
  /// **'No workout structure available.'**
  String get noWorkoutStructureAvailable;

  /// No description provided for @aerobic.
  ///
  /// In en, this message translates to:
  /// **'Aerobic'**
  String get aerobic;

  /// No description provided for @pushAgainToUpdateYour.
  ///
  /// In en, this message translates to:
  /// **'Push again to update your watch calendar.'**
  String get pushAgainToUpdateYour;

  /// No description provided for @workoutSentToLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout sent to {label}'**
  String workoutSentToLabel(Object label);

  /// No description provided for @updating2.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating2;

  /// No description provided for @pushToLabel.
  ///
  /// In en, this message translates to:
  /// **'Push to {label}'**
  String pushToLabel(Object label);

  /// No description provided for @shareExerciseListForLabel.
  ///
  /// In en, this message translates to:
  /// **'Share exercise list for {label}'**
  String shareExerciseListForLabel(Object label);

  /// No description provided for @shareWorkoutForLabel.
  ///
  /// In en, this message translates to:
  /// **'Share workout for {label}'**
  String shareWorkoutForLabel(Object label);

  /// No description provided for @whyNothingIsAddedTo.
  ///
  /// In en, this message translates to:
  /// **'Why? Nothing is added to make it up.'**
  String get whyNothingIsAddedTo;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @recordedActivityLinkedToThis.
  ///
  /// In en, this message translates to:
  /// **'Recorded activity linked to this workout'**
  String get recordedActivityLinkedToThis;

  /// No description provided for @matchedToTheRecordedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Matched to the recorded workout start'**
  String get matchedToTheRecordedWorkout;

  /// No description provided for @matchedByWorkoutNameSport.
  ///
  /// In en, this message translates to:
  /// **'Matched by workout name, sport and date'**
  String get matchedByWorkoutNameSport;

  /// No description provided for @matchedBySportDateAnd.
  ///
  /// In en, this message translates to:
  /// **'Matched by sport, date and duration'**
  String get matchedBySportDateAnd;

  /// No description provided for @planPlannedminutesMin.
  ///
  /// In en, this message translates to:
  /// **'Plan {plannedMinutes} min'**
  String planPlannedminutesMin(Object plannedMinutes);

  /// No description provided for @maxHr.
  ///
  /// In en, this message translates to:
  /// **'Max HR'**
  String get maxHr;

  /// No description provided for @trainingLoad2.
  ///
  /// In en, this message translates to:
  /// **'Training load'**
  String get trainingLoad2;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @avgPace.
  ///
  /// In en, this message translates to:
  /// **'Avg pace'**
  String get avgPace;

  /// No description provided for @avgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg speed'**
  String get avgSpeed;

  /// No description provided for @avgPower.
  ///
  /// In en, this message translates to:
  /// **'Avg power'**
  String get avgPower;

  /// No description provided for @elevation2.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get elevation2;

  /// No description provided for @altitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get altitude;

  /// No description provided for @explainMyHrvBeforeAnd.
  ///
  /// In en, this message translates to:
  /// **'Explain my HRV before and after this workout. What is comparable, what is not, and what is still unknown?'**
  String get explainMyHrvBeforeAnd;

  /// No description provided for @deleteActivity.
  ///
  /// In en, this message translates to:
  /// **'Delete activity?'**
  String get deleteActivity;

  /// No description provided for @removeThisActivityFromThe.
  ///
  /// In en, this message translates to:
  /// **'Remove this activity from the local history? A later provider sync may import it again.'**
  String get removeThisActivityFromThe;

  /// No description provided for @howDidThisSessionGo.
  ///
  /// In en, this message translates to:
  /// **'How did this session go, and what does it mean for my next days?'**
  String get howDidThisSessionGo;

  /// No description provided for @currentFixedFixed2.
  ///
  /// In en, this message translates to:
  /// **'Current {fixed}, {fixed2}'**
  String currentFixedFixed2(Object fixed, Object fixed2);

  /// No description provided for @setUpInTrainingSettings.
  ///
  /// In en, this message translates to:
  /// **'Set up in Training settings'**
  String get setUpInTrainingSettings;

  /// No description provided for @couldNotLoadHeatData.
  ///
  /// In en, this message translates to:
  /// **'Could not load heat data — tap for details'**
  String get couldNotLoadHeatData;

  /// No description provided for @loadingHeatHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading heat history…'**
  String get loadingHeatHistory;

  /// No description provided for @noHeatDataYet.
  ///
  /// In en, this message translates to:
  /// **'No heat data yet'**
  String get noHeatDataYet;

  /// No description provided for @optimalLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Optimal {low}–{high}'**
  String optimalLowHigh(Object low, Object high);

  /// No description provided for @optimalLowHighTrimp.
  ///
  /// In en, this message translates to:
  /// **'Optimal: {low}–{high} TRIMP'**
  String optimalLowHighTrimp(Object low, Object high);

  /// No description provided for @targetUnavailableSyncTrainingHistory.
  ///
  /// In en, this message translates to:
  /// **'Target unavailable — sync training history'**
  String get targetUnavailableSyncTrainingHistory;

  /// No description provided for @workoutQualifiedForHeatAccumulation.
  ///
  /// In en, this message translates to:
  /// **'Workout qualified for heat accumulation.'**
  String get workoutQualifiedForHeatAccumulation;

  /// No description provided for @workoutDidNotAddHeat.
  ///
  /// In en, this message translates to:
  /// **'Workout did not add heat accumulation.'**
  String get workoutDidNotAddHeat;

  /// No description provided for @performanceTime.
  ///
  /// In en, this message translates to:
  /// **'Performance / Time'**
  String get performanceTime;

  /// No description provided for @performanceDistance.
  ///
  /// In en, this message translates to:
  /// **'Performance / Distance'**
  String get performanceDistance;

  /// No description provided for @noRecordedRoute.
  ///
  /// In en, this message translates to:
  /// **'No recorded route'**
  String get noRecordedRoute;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @fitRoute.
  ///
  /// In en, this message translates to:
  /// **'Fit route'**
  String get fitRoute;

  /// No description provided for @fullscreenMap.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen map'**
  String get fullscreenMap;

  /// No description provided for @openstreetmapContributors2.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap contributors'**
  String get openstreetmapContributors2;

  /// No description provided for @appleIntelligenceIsUnavailableShowing.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence is unavailable. Showing a non-AI summary.'**
  String get appleIntelligenceIsUnavailableShowing;

  /// No description provided for @generateAiBriefing.
  ///
  /// In en, this message translates to:
  /// **'Generate AI briefing?'**
  String get generateAiBriefing;

  /// No description provided for @retryAiBriefing.
  ///
  /// In en, this message translates to:
  /// **'Retry AI briefing'**
  String get retryAiBriefing;

  /// No description provided for @generateBriefing.
  ///
  /// In en, this message translates to:
  /// **'Generate briefing'**
  String get generateBriefing;

  /// No description provided for @discussThisBriefingWithMe.
  ///
  /// In en, this message translates to:
  /// **'Discuss this briefing with me and suggest the next best action.\n\n{text}'**
  String discussThisBriefingWithMe(Object text);

  /// No description provided for @whyThisRecommendationWhichOf.
  ///
  /// In en, this message translates to:
  /// **'Why this recommendation? Which of my figures and which gaps in the data led to it, and what would change it?\n\n{text}'**
  String whyThisRecommendationWhichOf(Object text);

  /// No description provided for @avg2.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avg2;

  /// No description provided for @peak2.
  ///
  /// In en, this message translates to:
  /// **'Peak'**
  String get peak2;

  /// No description provided for @notEnoughContinuousReadingsFor.
  ///
  /// In en, this message translates to:
  /// **'Not enough continuous readings for an average.'**
  String get notEnoughContinuousReadingsFor;

  /// No description provided for @recordedCoverageInhourshInminutesminTime.
  ///
  /// In en, this message translates to:
  /// **'Recorded coverage: {inHours}h {inMinutes}min · Time-weighted average'**
  String recordedCoverageInhourshInminutesminTime(
    Object inHours,
    Object inMinutes,
  );

  /// No description provided for @lying.
  ///
  /// In en, this message translates to:
  /// **'Lying'**
  String get lying;

  /// No description provided for @noHrvReadingsInThis.
  ///
  /// In en, this message translates to:
  /// **'No HRV readings in this period'**
  String get noHrvReadingsInThis;

  /// No description provided for @overnightHrvComesFromYour.
  ///
  /// In en, this message translates to:
  /// **'Overnight HRV comes from your watch, spot readings from the Polar H10 (RMSSD). The methods differ: compare trends, not single values.'**
  String get overnightHrvComesFromYour;

  /// No description provided for @noReadings.
  ///
  /// In en, this message translates to:
  /// **'No readings'**
  String get noReadings;

  /// No description provided for @whenDidTheWorkoutStart.
  ///
  /// In en, this message translates to:
  /// **'When did the workout start?'**
  String get whenDidTheWorkoutStart;

  /// No description provided for @whenDidItEnd.
  ///
  /// In en, this message translates to:
  /// **'When did it end?'**
  String get whenDidItEnd;

  /// No description provided for @last3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get last3Months;

  /// No description provided for @lastYear.
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get lastYear;

  /// No description provided for @lastDaysDays.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String lastDaysDays(Object days);

  /// No description provided for @nowOnCurrentTapA.
  ///
  /// In en, this message translates to:
  /// **'Now on {current}. Tap a day, or drag the workout onto one. The steps stay as they are.'**
  String nowOnCurrentTapA(Object current);

  /// No description provided for @monthView.
  ///
  /// In en, this message translates to:
  /// **'Month view'**
  String get monthView;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncing;

  /// No description provided for @trendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Trend unavailable'**
  String get trendUnavailable;

  /// No description provided for @stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// No description provided for @increasing.
  ///
  /// In en, this message translates to:
  /// **'Increasing'**
  String get increasing;

  /// No description provided for @decreasing.
  ///
  /// In en, this message translates to:
  /// **'Decreasing'**
  String get decreasing;

  /// No description provided for @unclear.
  ///
  /// In en, this message translates to:
  /// **'Unclear'**
  String get unclear;

  /// No description provided for @notComparable.
  ///
  /// In en, this message translates to:
  /// **'Not comparable'**
  String get notComparable;

  /// No description provided for @waitingForAfter.
  ///
  /// In en, this message translates to:
  /// **'Waiting for after'**
  String get waitingForAfter;

  /// No description provided for @afterOnly.
  ///
  /// In en, this message translates to:
  /// **'After only'**
  String get afterOnly;

  /// No description provided for @waitingForTheActualWorkout.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the actual workout end.'**
  String get waitingForTheActualWorkout;

  /// No description provided for @reminderAroundTolocal.
  ///
  /// In en, this message translates to:
  /// **'Reminder around {toLocal}'**
  String reminderAroundTolocal(Object toLocal);

  /// No description provided for @reminderIsDueMeasureWhen.
  ///
  /// In en, this message translates to:
  /// **'Reminder is due. Measure when you are ready.'**
  String get reminderIsDueMeasureWhen;

  /// No description provided for @thisReminderIsNoLonger.
  ///
  /// In en, this message translates to:
  /// **'This reminder is no longer current. Open the workout to view your measurements.'**
  String get thisReminderIsNoLonger;

  /// No description provided for @beforeFixedMilliseconds.
  ///
  /// In en, this message translates to:
  /// **'Before {fixed} milliseconds. '**
  String beforeFixedMilliseconds(Object fixed);

  /// No description provided for @afterFixedMilliseconds.
  ///
  /// In en, this message translates to:
  /// **'After {fixed} milliseconds'**
  String afterFixedMilliseconds(Object fixed);

  /// No description provided for @changeDeltamsMillisecondsDeltapercentPercent.
  ///
  /// In en, this message translates to:
  /// **'Change {deltaMs} milliseconds, {deltaPercent} percent.'**
  String changeDeltamsMillisecondsDeltapercentPercent(
    Object deltaMs,
    Object deltaPercent,
  );

  /// No description provided for @noPreTrainingMeasurementRecorded.
  ///
  /// In en, this message translates to:
  /// **'No pre-training measurement recorded.'**
  String get noPreTrainingMeasurementRecorded;

  /// No description provided for @notMeasuredYet.
  ///
  /// In en, this message translates to:
  /// **'Not measured yet'**
  String get notMeasuredYet;

  /// No description provided for @leftOutOfTheComparison.
  ///
  /// In en, this message translates to:
  /// **'Left out of the comparison: {excludedTotal} workouts ({c}).'**
  String leftOutOfTheComparison(Object excludedTotal, Object c);

  /// No description provided for @notFromThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'Not from this workout'**
  String get notFromThisWorkout;

  /// No description provided for @useAsBefore.
  ///
  /// In en, this message translates to:
  /// **'Use as before'**
  String get useAsBefore;

  /// No description provided for @useAsAfter.
  ///
  /// In en, this message translates to:
  /// **'Use as after'**
  String get useAsAfter;

  /// No description provided for @beforeNotMeasured.
  ///
  /// In en, this message translates to:
  /// **'Before · not measured'**
  String get beforeNotMeasured;

  /// No description provided for @beforeTolocal.
  ///
  /// In en, this message translates to:
  /// **'Before · {toLocal}'**
  String beforeTolocal(Object toLocal);

  /// No description provided for @workoutWorkouttext.
  ///
  /// In en, this message translates to:
  /// **'Workout · {workoutText}'**
  String workoutWorkouttext(Object workoutText);

  /// No description provided for @afterNotMeasuredYet.
  ///
  /// In en, this message translates to:
  /// **'After · not measured yet'**
  String get afterNotMeasuredYet;

  /// No description provided for @afterTolocal.
  ///
  /// In en, this message translates to:
  /// **'After · {toLocal}'**
  String afterTolocal(Object toLocal);

  /// No description provided for @yourSimilarWorkoutsEligibleTolocal.
  ///
  /// In en, this message translates to:
  /// **'Your similar workouts ({eligible}, {toLocal}–{toLocal2}): median {medianMs} ms, middle half {q1Ms} to {q3Ms} ms.'**
  String yourSimilarWorkoutsEligibleTolocal(
    Object eligible,
    Object toLocal,
    Object toLocal2,
    Object medianMs,
    Object q1Ms,
    Object q3Ms,
  );

  /// No description provided for @howHardDidItFeel.
  ///
  /// In en, this message translates to:
  /// **'How hard did it feel? (RPE)'**
  String get howHardDidItFeel;

  /// No description provided for @loadMetric.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get loadMetric;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @routeFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get routeFinish;

  /// No description provided for @month2.
  ///
  /// In en, this message translates to:
  /// **'MONTH'**
  String get month2;

  /// No description provided for @week2.
  ///
  /// In en, this message translates to:
  /// **'WEEK'**
  String get week2;

  /// No description provided for @quarter.
  ///
  /// In en, this message translates to:
  /// **'QUARTER'**
  String get quarter;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'YEAR'**
  String get year;

  /// No description provided for @easy3.
  ///
  /// In en, this message translates to:
  /// **'EASY'**
  String get easy3;

  /// No description provided for @mod.
  ///
  /// In en, this message translates to:
  /// **'MOD'**
  String get mod;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'HARD'**
  String get hard;

  /// No description provided for @protocol.
  ///
  /// In en, this message translates to:
  /// **'PROTOCOL'**
  String get protocol;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE'**
  String get calculate;

  /// No description provided for @warmUp.
  ///
  /// In en, this message translates to:
  /// **'WARM-UP'**
  String get warmUp;

  /// No description provided for @coolDown.
  ///
  /// In en, this message translates to:
  /// **'COOL-DOWN'**
  String get coolDown;

  /// No description provided for @ftpCycling.
  ///
  /// In en, this message translates to:
  /// **'FTP cycling'**
  String get ftpCycling;

  /// No description provided for @ftpFtpwattsWWattsperkgW.
  ///
  /// In en, this message translates to:
  /// **'FTP {ftpWatts} W · {wattsPerKg} W/kg'**
  String ftpFtpwattsWWattsperkgW(Object ftpWatts, Object wattsPerKg);

  /// No description provided for @thisWeekSoFar.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK · SO FAR'**
  String get thisWeekSoFar;

  /// No description provided for @duration2.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get duration2;

  /// No description provided for @distance2.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get distance2;

  /// No description provided for @sport2.
  ///
  /// In en, this message translates to:
  /// **'SPORT'**
  String get sport2;

  /// No description provided for @repeatSets.
  ///
  /// In en, this message translates to:
  /// **'REPEAT SETS'**
  String get repeatSets;

  /// No description provided for @aboutThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT THIS WORKOUT'**
  String get aboutThisWorkout;

  /// No description provided for @workoutStructure.
  ///
  /// In en, this message translates to:
  /// **'WORKOUT STRUCTURE'**
  String get workoutStructure;

  /// No description provided for @health2.
  ///
  /// In en, this message translates to:
  /// **'HEALTH'**
  String get health2;

  /// No description provided for @high2.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get high2;

  /// No description provided for @elevated.
  ///
  /// In en, this message translates to:
  /// **'ELEVATED'**
  String get elevated;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get normal;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'TOMORROW'**
  String get tomorrow;

  /// No description provided for @skipped2.
  ///
  /// In en, this message translates to:
  /// **'SKIPPED'**
  String get skipped2;

  /// No description provided for @weeklyPlan.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY PLAN'**
  String get weeklyPlan;

  /// No description provided for @activityLog3.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY LOG'**
  String get activityLog3;

  /// No description provided for @skippedTouppercase.
  ///
  /// In en, this message translates to:
  /// **'SKIPPED · {toUpperCase}'**
  String skippedTouppercase(Object toUpperCase);

  /// No description provided for @primaryZone.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY ZONE'**
  String get primaryZone;

  /// No description provided for @coachingCues.
  ///
  /// In en, this message translates to:
  /// **'COACHING CUES'**
  String get coachingCues;

  /// No description provided for @targets.
  ///
  /// In en, this message translates to:
  /// **'TARGETS'**
  String get targets;

  /// No description provided for @adaptation.
  ///
  /// In en, this message translates to:
  /// **'ADAPTATION'**
  String get adaptation;

  /// No description provided for @done2.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get done2;

  /// No description provided for @notRecorded2.
  ///
  /// In en, this message translates to:
  /// **'NOT RECORDED'**
  String get notRecorded2;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'PLANNED'**
  String get planned;

  /// No description provided for @extra.
  ///
  /// In en, this message translates to:
  /// **'EXTRA'**
  String get extra;

  /// No description provided for @optimal2.
  ///
  /// In en, this message translates to:
  /// **'OPTIMAL'**
  String get optimal2;

  /// No description provided for @qualified.
  ///
  /// In en, this message translates to:
  /// **'QUALIFIED'**
  String get qualified;

  /// No description provided for @temp.
  ///
  /// In en, this message translates to:
  /// **'TEMP'**
  String get temp;

  /// No description provided for @humidity2.
  ///
  /// In en, this message translates to:
  /// **'HUMIDITY'**
  String get humidity2;

  /// No description provided for @pressure.
  ///
  /// In en, this message translates to:
  /// **'PRESSURE'**
  String get pressure;

  /// No description provided for @wetBulb.
  ///
  /// In en, this message translates to:
  /// **'WET BULB'**
  String get wetBulb;

  /// No description provided for @paceMinKm.
  ///
  /// In en, this message translates to:
  /// **'PACE (min/km)'**
  String get paceMinKm;

  /// No description provided for @speedKmH.
  ///
  /// In en, this message translates to:
  /// **'SPEED (km/h)'**
  String get speedKmH;

  /// No description provided for @elevationM.
  ///
  /// In en, this message translates to:
  /// **'ELEVATION (m)'**
  String get elevationM;

  /// No description provided for @powerW.
  ///
  /// In en, this message translates to:
  /// **'POWER (W)'**
  String get powerW;

  /// No description provided for @performanceTime2.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE / TIME'**
  String get performanceTime2;

  /// No description provided for @performanceDistance2.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE / DISTANCE'**
  String get performanceDistance2;

  /// No description provided for @load2.
  ///
  /// In en, this message translates to:
  /// **'LOAD'**
  String get load2;

  /// No description provided for @day2.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get day2;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'ALL-TIME'**
  String get allTime;

  /// No description provided for @hrvAroundThisWorkout2.
  ///
  /// In en, this message translates to:
  /// **'HRV around this workout. '**
  String get hrvAroundThisWorkout2;

  /// No description provided for @lowReserve.
  ///
  /// In en, this message translates to:
  /// **'LOW RESERVE'**
  String get lowReserve;

  /// No description provided for @goodReserve.
  ///
  /// In en, this message translates to:
  /// **'GOOD RESERVE'**
  String get goodReserve;

  /// No description provided for @latestReadingAtTolocal.
  ///
  /// In en, this message translates to:
  /// **'Latest reading at {toLocal}'**
  String latestReadingAtTolocal(Object toLocal);

  /// No description provided for @weeklyAvg.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY AVG'**
  String get weeklyAvg;

  /// No description provided for @monthlyAvg.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY AVG'**
  String get monthlyAvg;

  /// No description provided for @systolic2.
  ///
  /// In en, this message translates to:
  /// **'SYSTOLIC'**
  String get systolic2;

  /// No description provided for @diastolic2.
  ///
  /// In en, this message translates to:
  /// **'DIASTOLIC'**
  String get diastolic2;

  /// No description provided for @hourlyVariation.
  ///
  /// In en, this message translates to:
  /// **'HOURLY VARIATION'**
  String get hourlyVariation;

  /// No description provided for @dailyVariation.
  ///
  /// In en, this message translates to:
  /// **'DAILY VARIATION'**
  String get dailyVariation;

  /// No description provided for @sys2.
  ///
  /// In en, this message translates to:
  /// **'SYS'**
  String get sys2;

  /// No description provided for @dia.
  ///
  /// In en, this message translates to:
  /// **'DIA'**
  String get dia;

  /// No description provided for @bluetoothDevices.
  ///
  /// In en, this message translates to:
  /// **'BLUETOOTH DEVICES'**
  String get bluetoothDevices;

  /// No description provided for @accountsServices.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNTS & SERVICES'**
  String get accountsServices;

  /// No description provided for @flowLoginOptional.
  ///
  /// In en, this message translates to:
  /// **'FLOW LOGIN (OPTIONAL)'**
  String get flowLoginOptional;

  /// No description provided for @polarFlowLogin.
  ///
  /// In en, this message translates to:
  /// **'POLAR FLOW LOGIN'**
  String get polarFlowLogin;

  /// No description provided for @raceGoal.
  ///
  /// In en, this message translates to:
  /// **'RACE GOAL'**
  String get raceGoal;

  /// No description provided for @experienceLevel.
  ///
  /// In en, this message translates to:
  /// **'EXPERIENCE LEVEL'**
  String get experienceLevel;

  /// No description provided for @weeklySchedule2.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY SCHEDULE'**
  String get weeklySchedule2;

  /// No description provided for @sessionsPerDay2.
  ///
  /// In en, this message translates to:
  /// **'SESSIONS PER DAY'**
  String get sessionsPerDay2;

  /// No description provided for @aboutYou.
  ///
  /// In en, this message translates to:
  /// **'ABOUT YOU'**
  String get aboutYou;

  /// No description provided for @yourActivities2.
  ///
  /// In en, this message translates to:
  /// **'YOUR ACTIVITIES'**
  String get yourActivities2;

  /// No description provided for @latestReadingAtTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Latest reading at {timestamp}'**
  String latestReadingAtTimestamp(Object timestamp);

  /// No description provided for @poorSleep.
  ///
  /// In en, this message translates to:
  /// **'POOR SLEEP'**
  String get poorSleep;

  /// No description provided for @fairSleep.
  ///
  /// In en, this message translates to:
  /// **'FAIR SLEEP'**
  String get fairSleep;

  /// No description provided for @goodSleep.
  ///
  /// In en, this message translates to:
  /// **'GOOD SLEEP'**
  String get goodSleep;

  /// No description provided for @hoursOfSleep.
  ///
  /// In en, this message translates to:
  /// **'HOURS OF SLEEP'**
  String get hoursOfSleep;

  /// No description provided for @sleepNeeded.
  ///
  /// In en, this message translates to:
  /// **'SLEEP NEEDED'**
  String get sleepNeeded;

  /// No description provided for @deepSleep.
  ///
  /// In en, this message translates to:
  /// **'DEEP SLEEP'**
  String get deepSleep;

  /// No description provided for @exercises2.
  ///
  /// In en, this message translates to:
  /// **'EXERCISES'**
  String get exercises2;

  /// No description provided for @strengthSummary.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH SUMMARY'**
  String get strengthSummary;

  /// No description provided for @strengthDraft.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH · DRAFT'**
  String get strengthDraft;

  /// No description provided for @strengthFinishedWithGaps.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH · FINISHED WITH GAPS'**
  String get strengthFinishedWithGaps;

  /// No description provided for @strength2.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH'**
  String get strength2;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'WIND'**
  String get wind;

  /// No description provided for @sun2.
  ///
  /// In en, this message translates to:
  /// **'SUN'**
  String get sun2;

  /// No description provided for @cloud.
  ///
  /// In en, this message translates to:
  /// **'CLOUD'**
  String get cloud;

  /// No description provided for @dataSourceUpdatedFetchedat.
  ///
  /// In en, this message translates to:
  /// **'Data: {source} · Updated {fetchedAt}'**
  String dataSourceUpdatedFetchedat(Object source, Object fetchedAt);

  /// No description provided for @coros2.
  ///
  /// In en, this message translates to:
  /// **'COROS'**
  String get coros2;

  /// No description provided for @rmssdMs.
  ///
  /// In en, this message translates to:
  /// **'RMSSD · ms'**
  String get rmssdMs;

  /// No description provided for @sdnnMs.
  ///
  /// In en, this message translates to:
  /// **'SDNN · ms'**
  String get sdnnMs;

  /// No description provided for @now2.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get now2;

  /// No description provided for @awake.
  ///
  /// In en, this message translates to:
  /// **'AWAKE'**
  String get awake;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'LIGHT'**
  String get light;

  /// No description provided for @deep2.
  ///
  /// In en, this message translates to:
  /// **'DEEP'**
  String get deep2;

  /// No description provided for @sqliteOrm.
  ///
  /// In en, this message translates to:
  /// **'SQLite ORM'**
  String get sqliteOrm;

  /// No description provided for @httpClients.
  ///
  /// In en, this message translates to:
  /// **'HTTP clients'**
  String get httpClients;

  /// No description provided for @gpsLocation.
  ///
  /// In en, this message translates to:
  /// **'GPS location'**
  String get gpsLocation;

  /// No description provided for @hdlCholesterol.
  ///
  /// In en, this message translates to:
  /// **'HDL Cholesterol'**
  String get hdlCholesterol;

  /// No description provided for @ldlCholesterol.
  ///
  /// In en, this message translates to:
  /// **'LDL Cholesterol'**
  String get ldlCholesterol;

  /// No description provided for @raceName.
  ///
  /// In en, this message translates to:
  /// **'RACE NAME'**
  String get raceName;

  /// No description provided for @mtb.
  ///
  /// In en, this message translates to:
  /// **'MTB'**
  String get mtb;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE (km)'**
  String get distanceKm;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'PRIORITY'**
  String get priority;

  /// No description provided for @elevationGainM.
  ///
  /// In en, this message translates to:
  /// **'ELEVATION GAIN (m)'**
  String get elevationGainM;

  /// No description provided for @targetTime.
  ///
  /// In en, this message translates to:
  /// **'TARGET TIME'**
  String get targetTime;

  /// No description provided for @raceDate.
  ///
  /// In en, this message translates to:
  /// **'RACE DATE'**
  String get raceDate;

  /// No description provided for @participation.
  ///
  /// In en, this message translates to:
  /// **'PARTICIPATION'**
  String get participation;

  /// No description provided for @whatIWantFromIt.
  ///
  /// In en, this message translates to:
  /// **'WHAT I WANT FROM IT'**
  String get whatIWantFromIt;

  /// No description provided for @periodTimeline.
  ///
  /// In en, this message translates to:
  /// **'{period} TIMELINE'**
  String periodTimeline(Object period);

  /// No description provided for @tabPlan.
  ///
  /// In en, this message translates to:
  /// **'PLAN'**
  String get tabPlan;

  /// No description provided for @tabLoad.
  ///
  /// In en, this message translates to:
  /// **'LOAD'**
  String get tabLoad;

  /// No description provided for @tabCoach.
  ///
  /// In en, this message translates to:
  /// **'COACH'**
  String get tabCoach;

  /// No description provided for @hrDriftTestLt1.
  ///
  /// In en, this message translates to:
  /// **'HR DRIFT TEST — LT1'**
  String get hrDriftTestLt1;

  /// No description provided for @asSentByGarmin.
  ///
  /// In en, this message translates to:
  /// **'AS SENT BY GARMIN'**
  String get asSentByGarmin;

  /// No description provided for @noData2.
  ///
  /// In en, this message translates to:
  /// **'NO DATA'**
  String get noData2;

  /// No description provided for @noTarget.
  ///
  /// In en, this message translates to:
  /// **'NO TARGET'**
  String get noTarget;

  /// No description provided for @noHeatLoad.
  ///
  /// In en, this message translates to:
  /// **'NO HEAT LOAD'**
  String get noHeatLoad;

  /// No description provided for @hrBpm.
  ///
  /// In en, this message translates to:
  /// **'HR (bpm)'**
  String get hrBpm;

  /// No description provided for @aiBriefingUnavailableShowingA.
  ///
  /// In en, this message translates to:
  /// **'AI briefing unavailable. Showing a non-AI summary.'**
  String get aiBriefingUnavailableShowingA;

  /// No description provided for @uvIndex2.
  ///
  /// In en, this message translates to:
  /// **'UV INDEX'**
  String get uvIndex2;

  /// No description provided for @aiBriefing.
  ///
  /// In en, this message translates to:
  /// **'AI Briefing'**
  String get aiBriefing;

  /// No description provided for @uiFrameworkByGoogle.
  ///
  /// In en, this message translates to:
  /// **'UI framework by Google'**
  String get uiFrameworkByGoogle;

  /// No description provided for @unableToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data'**
  String get unableToLoadData;

  /// No description provided for @briefingSummary.
  ///
  /// In en, this message translates to:
  /// **'Recovery {recovery} / 100. Sleep {sleep} / 100. Today’s training load is {load} TRIMP.'**
  String briefingSummary(Object recovery, Object sleep, Object load);

  /// No description provided for @morningBriefing.
  ///
  /// In en, this message translates to:
  /// **'Morning briefing'**
  String get morningBriefing;

  /// No description provided for @lunchBriefing.
  ///
  /// In en, this message translates to:
  /// **'Lunch briefing'**
  String get lunchBriefing;

  /// No description provided for @afternoonBriefing.
  ///
  /// In en, this message translates to:
  /// **'Afternoon briefing'**
  String get afternoonBriefing;

  /// No description provided for @eveningBriefing.
  ///
  /// In en, this message translates to:
  /// **'Evening briefing'**
  String get eveningBriefing;

  /// No description provided for @appleUnusableAnswer.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence could not produce a usable answer: it repeated itself or your data. Try rephrasing the question, or choose another AI provider in the settings.'**
  String get appleUnusableAnswer;

  /// No description provided for @appleCouldNotAnswer.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence could not answer. Please try again.'**
  String get appleCouldNotAnswer;

  /// No description provided for @appleNotAvailableOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence is not available on this device.'**
  String get appleNotAvailableOnDevice;

  /// No description provided for @appleLanguageRejected.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence rejected the request’s language. Try a short question in English. Also check the language settings for iPhone and Siri.'**
  String get appleLanguageRejected;

  /// No description provided for @appleRequestTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence could not fit this request. Try a shorter question.'**
  String get appleRequestTooLarge;

  /// No description provided for @messageTooLongForApple.
  ///
  /// In en, this message translates to:
  /// **'This message is too long for Apple Intelligence. Shorten it and send again.'**
  String get messageTooLongForApple;

  /// No description provided for @vo2maxRunning.
  ///
  /// In en, this message translates to:
  /// **'VO₂max running'**
  String get vo2maxRunning;

  /// No description provided for @vo2maxCycling.
  ///
  /// In en, this message translates to:
  /// **'VO₂max cycling'**
  String get vo2maxCycling;

  /// No description provided for @vo2maxPaceLabel.
  ///
  /// In en, this message translates to:
  /// **'VO₂max pace'**
  String get vo2maxPaceLabel;

  /// No description provided for @lt1Threshold.
  ///
  /// In en, this message translates to:
  /// **'LT1 threshold'**
  String get lt1Threshold;

  /// No description provided for @lt2Threshold.
  ///
  /// In en, this message translates to:
  /// **'LT2 threshold'**
  String get lt2Threshold;

  /// No description provided for @hoursPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'{value} h previous week'**
  String hoursPreviousWeek(Object value);

  /// No description provided for @kmPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'{value} km previous week'**
  String kmPreviousWeek(Object value);

  /// No description provided for @thirtyMinuteTimeTrial.
  ///
  /// In en, this message translates to:
  /// **'30-minute time trial'**
  String get thirtyMinuteTimeTrial;

  /// No description provided for @thirtyMinTtDate.
  ///
  /// In en, this message translates to:
  /// **'30-min TT · {date}'**
  String thirtyMinTtDate(Object date);

  /// No description provided for @yesterday2.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get yesterday2;

  /// No description provided for @briefHeadGreen.
  ///
  /// In en, this message translates to:
  /// **'You are well recovered.'**
  String get briefHeadGreen;

  /// No description provided for @briefHeadYellow.
  ///
  /// In en, this message translates to:
  /// **'You are carrying some strain.'**
  String get briefHeadYellow;

  /// No description provided for @briefHeadRed.
  ///
  /// In en, this message translates to:
  /// **'You are clearly under strain.'**
  String get briefHeadRed;

  /// No description provided for @briefMain.
  ///
  /// In en, this message translates to:
  /// **'Main reasons: {reasons}.'**
  String briefMain(Object reasons);

  /// No description provided for @briefAllClear.
  ///
  /// In en, this message translates to:
  /// **'None of your values shows a warning sign.'**
  String get briefAllClear;

  /// No description provided for @briefAdviceGreen.
  ///
  /// In en, this message translates to:
  /// **'Train as planned.'**
  String get briefAdviceGreen;

  /// No description provided for @briefAdviceYellow.
  ///
  /// In en, this message translates to:
  /// **'Keep your plan but add no extra intensity.'**
  String get briefAdviceYellow;

  /// No description provided for @briefAdviceRed.
  ///
  /// In en, this message translates to:
  /// **'Recovery comes first: take an easy day or rest.'**
  String get briefAdviceRed;

  /// No description provided for @briefReasonHrvLow.
  ///
  /// In en, this message translates to:
  /// **'low sleep HRV'**
  String get briefReasonHrvLow;

  /// No description provided for @briefReasonHrvHigh.
  ///
  /// In en, this message translates to:
  /// **'high sleep HRV'**
  String get briefReasonHrvHigh;

  /// No description provided for @briefReasonRhrUp.
  ///
  /// In en, this message translates to:
  /// **'raised resting heart rate'**
  String get briefReasonRhrUp;

  /// No description provided for @briefReasonRhrDown.
  ///
  /// In en, this message translates to:
  /// **'low resting heart rate'**
  String get briefReasonRhrDown;

  /// No description provided for @briefReasonSleepShort.
  ///
  /// In en, this message translates to:
  /// **'too little sleep'**
  String get briefReasonSleepShort;

  /// No description provided for @briefReasonSleepGood.
  ///
  /// In en, this message translates to:
  /// **'sleep need met'**
  String get briefReasonSleepGood;

  /// No description provided for @briefReasonEnergyLow.
  ///
  /// In en, this message translates to:
  /// **'low energy'**
  String get briefReasonEnergyLow;

  /// No description provided for @briefReasonEnergyHigh.
  ///
  /// In en, this message translates to:
  /// **'good energy'**
  String get briefReasonEnergyHigh;

  /// No description provided for @briefReasonStressHigh.
  ///
  /// In en, this message translates to:
  /// **'high stress'**
  String get briefReasonStressHigh;

  /// No description provided for @briefReasonRespHigh.
  ///
  /// In en, this message translates to:
  /// **'raised breathing rate'**
  String get briefReasonRespHigh;

  /// No description provided for @briefReasonSpo2Low.
  ///
  /// In en, this message translates to:
  /// **'low blood oxygen'**
  String get briefReasonSpo2Low;

  /// No description provided for @briefReasonSkinTempOff.
  ///
  /// In en, this message translates to:
  /// **'unusual skin temperature'**
  String get briefReasonSkinTempOff;

  /// No description provided for @briefReasonFormTired.
  ///
  /// In en, this message translates to:
  /// **'accumulated training fatigue'**
  String get briefReasonFormTired;

  /// No description provided for @briefReasonFormVeryTired.
  ///
  /// In en, this message translates to:
  /// **'very high training fatigue'**
  String get briefReasonFormVeryTired;

  /// No description provided for @briefReasonFormFresh.
  ///
  /// In en, this message translates to:
  /// **'fresh and rested'**
  String get briefReasonFormFresh;

  /// No description provided for @briefTrainingHrvUp.
  ///
  /// In en, this message translates to:
  /// **'Your HRV rose after training, a good sign.'**
  String get briefTrainingHrvUp;

  /// No description provided for @briefTrainingHrvDown.
  ///
  /// In en, this message translates to:
  /// **'Your HRV fell after training, a less good sign.'**
  String get briefTrainingHrvDown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ca',
    'da',
    'de',
    'en',
    'es',
    'fi',
    'fr',
    'it',
    'nb',
    'sk',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'nb':
      return AppLocalizationsNb();
    case 'sk':
      return AppLocalizationsSk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
