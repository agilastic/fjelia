import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/log.dart';
import 'health_connect_service.dart';
import 'nutrition_reminder_service.dart';

/// Talks to `HealthWorkoutObserver` in the iOS app delegate. Apple Health
/// wakes the app when a workout is added; the native side then asks the
/// running app (`workoutsChanged`) or starts a headless engine that calls
/// `done` when finished.
const healthBackgroundChannel = MethodChannel('fjelia/health_background');

/// How long one background check may take. iOS gives a woken app about 30
/// seconds; the native side stops waiting a little later.
const healthBackgroundBudget = Duration(seconds: 22);

/// Lets Apple Health wake the app for new workouts, or stops it.
Future<void> setHealthBackgroundDelivery(bool on) async {
  if (!Platform.isIOS) return;
  try {
    await healthBackgroundChannel.invokeMethod<void>('setEnabled', on);
  } catch (e) {
    log('[HealthBackground] setEnabled($on) failed: $e');
  }
}

/// A new workout reached Apple Health: import the recent workouts, then let
/// the reminders decide. Returns how many activities were added.
Future<int> checkNewWorkouts({
  required Future<bool> Function() healthConnected,
  required HealthConnectService health,
  required Future<void> Function() reconcileHrv,
  required NutritionReminderService nutrition,
}) async {
  if (!await healthConnected()) {
    log('[HealthBackground] Apple Health not connected — skipped');
    return 0;
  }
  var added = 0;
  try {
    added = await health.syncRecentWorkouts();
  } catch (e) {
    // Locked device or a slow Health: what is already stored still counts.
    log('[HealthBackground] workout import failed: $e');
  }
  try {
    await reconcileHrv();
  } catch (e) {
    log('[HealthBackground] HRV reminder: $e');
  }
  await nutrition.reconcile();
  log('[HealthBackground] done — added=$added');
  return added;
}
