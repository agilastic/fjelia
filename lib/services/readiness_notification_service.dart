import 'daily_readiness_service.dart';

class ReadinessNotification {
  const ReadinessNotification({required this.level, required this.body});

  final ReadinessLevel level;
  final String body;
}

/// Text for the morning readiness push.
class ReadinessNotificationService {
  const ReadinessNotificationService();

  ReadinessNotification buildMorning(
    ReadinessLevel level, {
    String? sessionTitle,
    int? adaptedDurationMin,
    String? planUpdate,
  }) {
    final suffix = planUpdate != null ? ' Plan updated ($planUpdate).' : '';
    switch (level) {
      case ReadinessLevel.green:
        final body = sessionTitle != null
            ? 'Today: $sessionTitle — you\'re in great shape for it.'
            : 'Your body is well recovered. Good day to push.';
        return ReadinessNotification(level: level, body: '$body$suffix');
      case ReadinessLevel.yellow:
        final minutes =
            adaptedDurationMin != null ? ' ($adaptedDurationMin min)' : '';
        final body = sessionTitle != null
            ? 'Today\'s $sessionTitle$minutes has been adjusted to match your current state.'
            : 'Today\'s session has been adjusted slightly — same intention, a touch easier.';
        return ReadinessNotification(level: level, body: '$body$suffix');
      case ReadinessLevel.red:
        final body = sessionTitle != null
            ? 'Today\'s $sessionTitle has been replaced with an easy session. Adapting is how champions are made.'
            : 'Today is a recovery day. Your next hard session will benefit from it.';
        return ReadinessNotification(level: level, body: '$body$suffix');
    }
  }
}
