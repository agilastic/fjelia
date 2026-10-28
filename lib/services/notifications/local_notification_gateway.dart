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

enum NotificationFeature { hrv, nutrition }

class NutritionNotificationPayload {
  const NutritionNotificationPayload(this.activityId, this.token);
  final String activityId, token;
  String encode() => jsonEncode({
    'v': 1,
    'feature': 'nutrition',
    'activity': activityId,
    'token': token,
  });
  static NutritionNotificationPayload? decode(String? raw) {
    if (raw == null || raw.length > 600) return null;
    try {
      final j = jsonDecode(raw);
      if (j is! Map ||
          j['v'] != 1 ||
          j['feature'] != 'nutrition' ||
          j['activity'] is! String ||
          j['token'] is! String ||
          (j['activity'] as String).isEmpty ||
          (j['token'] as String).isEmpty) {
        return null;
      }
      return NutritionNotificationPayload(
        j['activity'] as String,
        j['token'] as String,
      );
    } catch (_) {
      return null;
    }
  }
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
    this.feature = NotificationFeature.hrv,
  });
  final int id;
  final DateTime at;
  final String payload;
  final String title, body;
  final NotificationFeature feature;

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
  static const french = HrvReminderTexts._(
    'C\'est l\'heure de ta mesure de VFC après l\'entraînement',
    'Repose-toi un instant, puis mesure dans la même position qu\'avant l\'entraînement.',
    'Mesurer maintenant',
    'Dans 10 minutes',
    'Ignorer ce rappel',
  );
  static const italian = HrvReminderTexts._(
    'È ora della misurazione HRV post-allenamento',
    'Riposa un attimo, poi misura nella stessa posizione di prima dell\'allenamento.',
    'Misura ora',
    'Tra 10 minuti',
    'Salta questo promemoria',
  );
  static const spanish = HrvReminderTexts._(
    'Es hora de tu medición de VFC tras el entrenamiento',
    'Descansa un momento y mide en la misma posición que antes de entrenar.',
    'Medir ahora',
    'En 10 minutos',
    'Omitir este recordatorio',
  );
  static const catalan = HrvReminderTexts._(
    'És l\'hora de la mesura de VFC després de l\'entrenament',
    'Descansa un moment i mesura en la mateixa posició que abans d\'entrenar.',
    'Mesura ara',
    'D\'aquí a 10 minuts',
    'Omet aquest recordatori',
  );
  static const norwegian = HrvReminderTexts._(
    'På tide med HRV-målingen etter treningen',
    'Hvil et øyeblikk, og mål i samme kroppsposisjon som før treningen.',
    'Mål nå',
    'Om 10 minutter',
    'Hopp over denne påminnelsen',
  );
  static const slovak = HrvReminderTexts._(
    'Čas na meranie HRV po tréningu',
    'Chvíľu si oddýchni a potom meraj v rovnakej polohe ako pred tréningom.',
    'Merať teraz',
    'Za 10 minút',
    'Preskočiť túto pripomienku',
  );
  static const finnish = HrvReminderTexts._(
    'Aika tehdä harjoituksen jälkeinen HRV-mittaus',
    'Rauhoitu hetkeksi ja mittaa samassa asennossa kuin ennen harjoitusta.',
    'Mittaa nyt',
    '10 minuutin päästä',
    'Ohita tämä muistutus',
  );
  static const danish = HrvReminderTexts._(
    'Tid til din HRV-måling efter træning',
    'Hvil et øjeblik, og mål i samme kropsposition som før træningen.',
    'Mål nu',
    'Om 10 minutter',
    'Spring denne påmindelse over',
  );

  static HrvReminderTexts forLanguage(String code) =>
      switch (code.toLowerCase().split(RegExp('[-_]')).first) {
        'de' => german,
        'fr' => french,
        'it' => italian,
        'es' => spanish,
        'ca' => catalan,
        'nb' || 'no' || 'nn' => norwegian,
        'sk' => slovak,
        'fi' => finnish,
        'da' => danish,
        _ => english,
      };

  Map<String, String> get actionLabels => {
    'measure': measure,
    'snooze': snooze,
    'skip': skip,
  };
}
