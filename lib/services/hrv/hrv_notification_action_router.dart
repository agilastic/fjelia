import 'dart:async';

import '../notifications/local_notification_adapter.dart';
import '../notifications/local_notification_gateway.dart';
import 'hrv_post_reminder_coordinator.dart';

/// Brings notification actions into the app in a safe order.
///
/// Responses that arrive before the database, the athlete's settings and the
/// navigator are ready wait in a queue. A cold-launch response and actions
/// left by the background handler are read once, then every one of them goes
/// through the coordinator's validation before anything opens.
class HrvNotificationActionRouter {
  HrvNotificationActionRouter({
    required this.coordinator,
    required this.gateway,
    this.inbox = HrvActionInbox.take,
  });

  final HrvPostReminderCoordinator coordinator;
  final LocalNotificationGateway gateway;
  final Future<List<HrvInboxEntry>> Function() inbox;

  /// What to do with a validated action. Set by the app shell, which owns
  /// the navigator.
  Future<void> Function(ActionResult result)? onResult;

  final _queue = <(NotificationResponse, DateTime?)>[];
  StreamSubscription<NotificationResponse>? _sub;
  bool _ready = false;
  bool _launchTaken = false;

  /// Starts listening. Responses are held until [markReady].
  void attach() {
    _sub ??= gateway.responses.listen((r) => _arrived(r, null));
  }

  void _arrived(NotificationResponse r, DateTime? at) {
    if (_ready) {
      unawaited(_process(r, at));
    } else {
      _queue.add((r, at));
    }
  }

  /// Call once the database and the navigator can be used, and again after
  /// the app resumed: it picks up actions the background handler stored.
  Future<void> markReady() async {
    _ready = true;
    if (!_launchTaken) {
      _launchTaken = true;
      final launch = await gateway.takeLaunchResponse();
      if (launch != null) _queue.add((launch, null));
    }
    for (final e in await inbox()) {
      _queue.add((
        NotificationResponse(actionId: e.actionId, payload: e.payload),
        e.receivedAt,
      ));
    }
    final pending = [..._queue];
    _queue.clear();
    for (final (r, at) in pending) {
      await _process(r, at);
    }
  }

  Future<void> _process(NotificationResponse r, DateTime? at) async {
    final result = await coordinator.handle(r, at: at);
    if (result.kind == ActionKind.ignored ||
        result.kind == ActionKind.duplicate) {
      return;
    }
    await onResult?.call(result);
  }

  void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
  }
}
