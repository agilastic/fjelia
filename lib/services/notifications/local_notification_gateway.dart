import 'dart:async';
import 'dart:convert';

enum NotificationPermission {
  granted,
  provisional,
  denied,
  notDetermined;

  /// A notification can be shown, possibly quietly.
  bool get allowed => this == granted || this == provisional;
}

/// What a platform can do. Application logic reads these instead of assuming
/// that two methods with the same name behave the same on iOS and Android.
class NotificationCapabilities {
  const NotificationCapabilities({
    this.pendingQuery = false,
    this.deliveredQuery = false,
    this.displayExpiry = false,
    this.actions = true,
  });
  final bool pendingQuery, deliveredQuery, displayExpiry, actions;
}

/// One local notification to show at [at].
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.at,
    required this.payload,
    required this.title,
    required this.body,
    this.actionLabels = const {},
  });
  final int id;
  final DateTime at;
  final String payload;
  final String title, body;

  /// Labels for `measure`, `snooze` and `skip`.
  final Map<String, String> actionLabels;
}

/// What the user did with a notification.
class NotificationResponse {
  const NotificationResponse({required this.actionId, this.payload});

  /// `open` for a tap on the body, else `measure`, `snooze` or `skip`.
  final String actionId;
  final String? payload;
}

/// Platform-neutral local notifications. Implementations hold the plugin;
/// everything above this line is plain Dart and testable.
abstract class LocalNotificationGateway {
  NotificationCapabilities get capabilities;
  Future<NotificationPermission> permission();

  /// Asks the user. Call it only after an explicit choice in the app.
  Future<NotificationPermission> requestPermission();

  /// Schedules a non-repeating request. The same id replaces a pending one.
  Future<void> schedule(ScheduledNotification notification);

  /// Cancels a pending request and removes a delivered one with this id.
  Future<void> cancel(int id);
  Future<Set<int>> pendingIds();
  Future<Set<int>> deliveredIds();
  Stream<NotificationResponse> get responses;

  /// The response that cold-started the app, once.
  Future<NotificationResponse?> takeLaunchResponse();
}

/// The only data a notification carries. No RR data, no health values.
class HrvNotificationPayload {
  const HrvNotificationPayload({
    required this.epoch,
    required this.reminderId,
    required this.generation,
    required this.episodeId,
    this.version = 1,
  });
  final int version;
  final String epoch, reminderId, episodeId;
  final int generation;

  String encode() => jsonEncode({
    'v': version,
    'e': epoch,
    'r': reminderId,
    'g': generation,
    'ep': episodeId,
  });

  /// Null for anything that is not a well-formed payload of this feature.
  static HrvNotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty || raw.length > 400) return null;
    try {
      final j = jsonDecode(raw);
      if (j is! Map) return null;
      final v = j['v'], e = j['e'], r = j['r'], g = j['g'], ep = j['ep'];
      if (v != 1 ||
          e is! String ||
          r is! String ||
          g is! int ||
          ep is! String ||
          e.isEmpty ||
          r.isEmpty ||
          ep.isEmpty ||
          e.length > 64 ||
          r.length > 64 ||
          ep.length > 64) {
        return null;
      }
      return HrvNotificationPayload(
        epoch: e,
        reminderId: r,
        generation: g,
        episodeId: ep,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Wording of the post-training reminder, in the user's language. Generic on
/// purpose: a banner can be late, so it never says how long ago anything was.
class HrvReminderTexts {
  const HrvReminderTexts._(
    this.title,
    this.body,
    this.measure,
    this.snooze,
    this.skip,
  );
  final String title, body, measure, snooze, skip;

  static const english = HrvReminderTexts._(
    'Time for your post-training HRV measurement',
    'Take a short rest, then measure in the same position as before training.',
    'Measure now',
    'In 10 minutes',
    'Skip this reminder',
  );
  static const german = HrvReminderTexts._(
    'Zeit für deine HRV-Nachmessung',
    'Komm kurz zur Ruhe und miss in derselben Körperposition wie vor dem Training.',
    'Jetzt messen',
    'In 10 Minuten',
    'Erinnerung auslassen',
  );

  static HrvReminderTexts forLanguage(String code) =>
      code.toLowerCase().startsWith('de') ? german : english;

  Map<String, String> get actionLabels => {
    'measure': measure,
    'snooze': snooze,
    'skip': skip,
  };
}
