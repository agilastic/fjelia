import 'dart:async';

import 'package:fjelia/services/notifications/local_notification_gateway.dart';

/// A gateway that records what it was asked to do and can be made to fail.
class FakeNotificationGateway implements LocalNotificationGateway {
  FakeNotificationGateway({
    this.state = NotificationPermission.granted,
    this.capabilities = const NotificationCapabilities(
      pendingQuery: true,
      deliveredQuery: true,
    ),
  });

  NotificationPermission state;
  @override
  NotificationCapabilities capabilities;

  final scheduled = <ScheduledNotification>[];
  final cancelled = <int>[];
  final pending = <int, ScheduledNotification>{};
  final delivered = <int>{};
  final permissionRequests = <NotificationPermission>[];
  int scheduleCalls = 0, cancelCalls = 0;
  Object? scheduleError, cancelError;

  /// Runs inside [schedule] before it returns, to model a change that lands
  /// while the platform call is in flight.
  Future<void> Function()? duringSchedule;
  Completer<void>? holdSchedule;
  final _responses = StreamController<NotificationResponse>.broadcast();
  NotificationResponse? launch;

  @override
  Future<NotificationPermission> permission() async => state;

  @override
  Future<NotificationPermission> requestPermission() async {
    permissionRequests.add(state);
    if (state == NotificationPermission.notDetermined) {
      state = NotificationPermission.granted;
    }
    return state;
  }

  @override
  Future<void> schedule(ScheduledNotification n) async {
    scheduleCalls++;
    if (scheduleError != null) throw scheduleError!;
    if (holdSchedule != null) await holdSchedule!.future;
    await duringSchedule?.call();
    scheduled.add(n);
    pending[n.id] = n;
  }

  @override
  Future<void> cancel(int id) async {
    cancelCalls++;
    if (cancelError != null) throw cancelError!;
    cancelled.add(id);
    pending.remove(id);
    delivered.remove(id);
  }

  @override
  Future<Set<int>> pendingIds() async => pending.keys.toSet();

  @override
  Future<Set<int>> deliveredIds() async => delivered.toSet();

  @override
  Stream<NotificationResponse> get responses => _responses.stream;

  void respond(NotificationResponse r) => _responses.add(r);

  @override
  Future<NotificationResponse?> takeLaunchResponse() async {
    final r = launch;
    launch = null;
    return r;
  }
}
