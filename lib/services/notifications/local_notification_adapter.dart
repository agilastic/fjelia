import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'local_notification_gateway.dart';

const _channelId = 'hrv_post_reminder';
const _category = 'hrv_post';
const _askedKey = 'hrv_notification_permission_asked_v1';
const _inboxKey = 'hrv_notification_action_inbox_v1';

/// Actions that arrive while only the background isolate is running. The
/// handler there has no database and no navigator, so it only writes a line
/// here; the foreground app reads it back and validates every entry.
class HrvActionInbox {
  static Future<void> append(HrvInboxEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_inboxKey) ?? <String>[];
    list.add(jsonEncode(entry.toJson()));
    // Bounded: a flood of callbacks cannot grow the store without end.
    await prefs.setStringList(
      _inboxKey,
      list.length > 20 ? list.sublist(list.length - 20) : list,
    );
  }

  static Future<List<HrvInboxEntry>> take() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getStringList(_inboxKey) ?? const <String>[];
    if (raw.isEmpty) return const [];
    await prefs.remove(_inboxKey);
    final entries = <HrvInboxEntry>[];
    for (final line in raw) {
      try {
        final e = HrvInboxEntry.fromJson(jsonDecode(line) as Map);
        if (e != null) entries.add(e);
      } catch (_) {}
    }
    return entries;
  }
}

class HrvInboxEntry {
  const HrvInboxEntry(this.actionId, this.payload, this.receivedAt);
  final String actionId;
  final String? payload;
  final DateTime receivedAt;

  Map<String, Object?> toJson() => {
    'a': actionId,
    'p': payload,
    't': receivedAt.toUtc().millisecondsSinceEpoch,
  };

  static HrvInboxEntry? fromJson(Map j) {
    final a = j['a'], p = j['p'], t = j['t'];
    if (a is! String || t is! int) return null;
    return HrvInboxEntry(
      a,
      p is String ? p : null,
      DateTime.fromMillisecondsSinceEpoch(t, isUtc: true),
    );
  }
}

/// Entry point for actions taken while the app is not running in the
/// foreground. It must stay a top-level function and survive tree shaking.
@pragma('vm:entry-point')
void hrvNotificationBackgroundHandler(fln.NotificationResponse response) {
  final payload = HrvNotificationPayload.decode(response.payload);
  if (payload == null &&
      NutritionNotificationPayload.decode(response.payload) == null) {
    return;
  }
  unawaited(
    HrvActionInbox.append(
      HrvInboxEntry(
        response.actionId ?? 'open',
        response.payload,
        DateTime.now(),
      ),
    ),
  );
}

/// The real gateway, on `flutter_local_notifications`. iOS and Android share
/// it; what differs is read from [capabilities], not assumed.
class FlutterLocalNotificationGateway implements LocalNotificationGateway {
  FlutterLocalNotificationGateway({
    fln.FlutterLocalNotificationsPlugin? plugin,
    this.language = 'en',
  }) : _plugin = plugin ?? fln.FlutterLocalNotificationsPlugin();

  final fln.FlutterLocalNotificationsPlugin _plugin;
  final String language;
  final _responses = StreamController<NotificationResponse>.broadcast();
  bool _ready = false;

  @override
  NotificationCapabilities get capabilities => const NotificationCapabilities(
    pendingQuery: true,
    deliveredQuery: true,
    // Neither platform can validate a local notification at display time.
    displayExpiry: false,
  );

  /// Registers the actions and the handlers. Does not ask for permission.
  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    final texts = HrvReminderTexts.forLanguage(language);
    await _plugin.initialize(
      settings: fln.InitializationSettings(
        android: const fln.AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: fln.DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            fln.DarwinNotificationCategory(
              'nutrition_post',
              actions: [
                fln.DarwinNotificationAction.plain(
                  'log',
                  'Log intake',
                  options: {fln.DarwinNotificationActionOption.foreground},
                ),
                fln.DarwinNotificationAction.plain('snooze', 'In 30 minutes'),
                fln.DarwinNotificationAction.plain('skip', 'Dismiss'),
              ],
            ),
            fln.DarwinNotificationCategory(
              _category,
              actions: [
                fln.DarwinNotificationAction.plain(
                  'measure',
                  texts.measure,
                  options: {fln.DarwinNotificationActionOption.foreground},
                ),
                fln.DarwinNotificationAction.plain('snooze', texts.snooze),
                fln.DarwinNotificationAction.plain(
                  'skip',
                  texts.skip,
                  options: {fln.DarwinNotificationActionOption.destructive},
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse:
          hrvNotificationBackgroundHandler,
    );
    _ready = true;
  }

  void _onResponse(fln.NotificationResponse r) {
    _responses.add(
      NotificationResponse(actionId: r.actionId ?? 'open', payload: r.payload),
    );
  }

  fln.AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        fln.AndroidFlutterLocalNotificationsPlugin
      >();

  fln.IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        fln.IOSFlutterLocalNotificationsPlugin
      >();

  Future<bool> _asked() async =>
      (await SharedPreferences.getInstance()).getBool(_askedKey) ?? false;

  @override
  Future<NotificationPermission> permission() async {
    await init();
    final asked = await _asked();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final o = await _ios?.checkPermissions();
      if (o == null) return NotificationPermission.notDetermined;
      if (o.isProvisionalEnabled) return NotificationPermission.provisional;
      if (o.isEnabled) return NotificationPermission.granted;
      return asked
          ? NotificationPermission.denied
          : NotificationPermission.notDetermined;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final on = await _android?.areNotificationsEnabled() ?? false;
      if (on) return NotificationPermission.granted;
      return asked
          ? NotificationPermission.denied
          : NotificationPermission.notDetermined;
    }
    return NotificationPermission.denied;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    await init();
    (await SharedPreferences.getInstance()).setBool(_askedKey, true);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _ios?.requestPermissions(alert: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _android?.requestNotificationsPermission();
    }
    return permission();
  }

  @override
  Future<void> schedule(ScheduledNotification n) async {
    await init();
    final labels = n.actionLabels;
    final nutrition = n.feature == NotificationFeature.nutrition;
    await _plugin.zonedSchedule(
      id: n.id,
      title: n.title,
      body: n.body,
      payload: n.payload,
      // An absolute instant: a time zone change does not move it.
      scheduledDate: tz.TZDateTime.from(n.at.toUtc(), tz.UTC),
      // Inexact on purpose: no special exact-alarm access for an optional
      // reminder, and the text never promises a minute.
      androidScheduleMode: fln.AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          nutrition ? 'nutrition_post_reminder' : _channelId,
          nutrition
              ? 'Workout nutrition'
              : labels['channel'] ?? 'HRV reminders',
          channelDescription: nutrition
              ? 'Post-workout food and fluid log reminder'
              : 'Post-training HRV measurement reminder',
          importance: fln.Importance.defaultImportance,
          priority: fln.Priority.defaultPriority,
          category: fln.AndroidNotificationCategory.reminder,
          actions: [
            fln.AndroidNotificationAction(
              nutrition ? 'log' : 'measure',
              nutrition
                  ? labels['log'] ?? 'Log intake'
                  : labels['measure'] ?? 'Measure now',
              showsUserInterface: true,
            ),
            fln.AndroidNotificationAction(
              'snooze',
              labels['snooze'] ?? 'In 10 minutes',
            ),
            fln.AndroidNotificationAction(
              'skip',
              labels['skip'] ?? 'Skip this reminder',
            ),
          ],
        ),
        iOS: fln.DarwinNotificationDetails(
          categoryIdentifier: nutrition ? 'nutrition_post' : _category,
          threadIdentifier: nutrition ? 'nutrition_post' : 'hrv_post',
          presentBadge: false,
        ),
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  @override
  Future<Set<int>> pendingIds() async {
    await init();
    return {for (final r in await _plugin.pendingNotificationRequests()) r.id};
  }

  @override
  Future<Set<int>> deliveredIds() async {
    await init();
    return {
      for (final a in await _plugin.getActiveNotifications())
        if (a.id != null) a.id!,
    };
  }

  @override
  Stream<NotificationResponse> get responses => _responses.stream;

  @override
  Future<NotificationResponse?> takeLaunchResponse() async {
    await init();
    final d = await _plugin.getNotificationAppLaunchDetails();
    if (d == null || !d.didNotificationLaunchApp) return null;
    final r = d.notificationResponse;
    if (r == null) return null;
    return NotificationResponse(
      actionId: r.actionId ?? 'open',
      payload: r.payload,
    );
  }
}

/// For platforms without local notifications and for tests that do not care.
class NoopNotificationGateway implements LocalNotificationGateway {
  @override
  NotificationCapabilities get capabilities =>
      const NotificationCapabilities(actions: false);
  @override
  Future<NotificationPermission> permission() async =>
      NotificationPermission.denied;
  @override
  Future<NotificationPermission> requestPermission() async =>
      NotificationPermission.denied;
  @override
  Future<void> schedule(ScheduledNotification notification) async {}
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<Set<int>> pendingIds() async => const {};
  @override
  Future<Set<int>> deliveredIds() async => const {};
  @override
  Stream<NotificationResponse> get responses => const Stream.empty();
  @override
  Future<NotificationResponse?> takeLaunchResponse() async => null;
}
