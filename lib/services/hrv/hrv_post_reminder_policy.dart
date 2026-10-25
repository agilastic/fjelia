import '../../models/hrv_training_episode.dart';
import 'hrv_timing_policy.dart';

enum ReminderState {
  waitingForWorkout,
  eligible,
  scheduled,
  awaitingAction,
  snoozed,
  completed,
  skipped,
  suppressed,
  cancelled,
  expired;

  static ReminderState parse(String? name) => values.firstWhere(
    (s) => s.name == name,
    orElse: () => ReminderState.suppressed,
  );

  /// No transition leaves these on its own: a sync cannot resurrect them.
  bool get terminal =>
      this == completed ||
      this == skipped ||
      this == expired ||
      this == cancelled;

  bool get active =>
      this == eligible ||
      this == scheduled ||
      this == awaitingAction ||
      this == snoozed;
}

enum ReminderReason {
  none,
  notOptedIn,
  noSensor,
  noPre,
  endUnknown,
  enabledAfterEnd,
  postExists,
  interveningWorkout,
  permissionBlocked,
  lateDiscovery,
  quietHours,
  capacity,
  ambiguous,
  clockUncertain,
  historicalImport,
  expired,
  skippedByUser,
  featureOff,
  workoutDeleted,
}

enum ReminderAction { none, schedule, cancel }

/// App quiet hours as minutes of the local day. Disabled unless configured.
class QuietHours {
  const QuietHours(this.startMinute, this.endMinute, {this.offsetAt});
  final int startMinute, endMinute;

  /// Local offset at an instant, so a DST change moves the window correctly.
  final Duration Function(DateTime utc)? offsetAt;

  Duration _offset(DateTime utc) =>
      offsetAt?.call(utc) ?? utc.toLocal().timeZoneOffset;

  bool _inside(int minute) => startMinute <= endMinute
      ? minute >= startMinute && minute < endMinute
      : minute >= startMinute || minute < endMinute;

  /// The instant itself when it is allowed, else when quiet hours end.
  DateTime nextAllowed(DateTime utc) {
    final at = utc.toUtc();
    var step = at;
    for (var i = 0; i < 24 * 60; i++) {
      final local = step.add(_offset(step));
      if (!_inside(local.hour * 60 + local.minute)) {
        return step == at ? utc : step;
      }
      step = step.add(const Duration(minutes: 1));
    }
    return utc;
  }
}

/// What the reducer needs, all read from committed facts.
class ReminderInputs {
  const ReminderInputs({
    required this.now,
    required this.optedIn,
    required this.sensorReady,
    required this.permissionGranted,
    this.enabledSince,
    this.interval,
    this.hasUsablePre = false,
    this.hasUsablePost = false,
    this.ambiguous = false,
    this.intervening = false,
    this.deleted = false,
    this.historicalImport = false,
    this.capacityFree = true,
    this.quietHours,
    this.postponeInQuietHours = false,
    this.previous,
    this.skipRequested = false,
  });
  final DateTime now;
  final bool optedIn, sensorReady, permissionGranted;
  final DateTime? enabledSince;
  final ActualInterval? interval;
  final bool hasUsablePre, hasUsablePost;
  final bool ambiguous, intervening, deleted, historicalImport, capacityFree;
  final QuietHours? quietHours;
  final bool postponeInQuietHours;
  final ReminderRecord? previous;
  final bool skipRequested;
}

/// The stored side of a reminder chain.
class ReminderRecord {
  const ReminderRecord({
    required this.state,
    required this.originalDue,
    required this.nextDue,
    required this.expires,
    this.snoozeCount = 0,
    this.accepted = false,
    this.reason = ReminderReason.none,
  });
  final ReminderState state;
  final DateTime originalDue, nextDue, expires;
  final int snoozeCount;

  /// The OS accepted a request at some point. Not proof it was displayed.
  final bool accepted;
  final ReminderReason reason;
}

class ReminderDecision {
  const ReminderDecision({
    required this.state,
    required this.action,
    this.reason = ReminderReason.none,
    this.originalDue,
    this.nextDue,
    this.expires,
    this.snoozeCount = 0,
  });
  final ReminderState state;
  final ReminderAction action;
  final ReminderReason reason;
  final DateTime? originalDue, nextDue, expires;
  final int snoozeCount;
}

/// Pure eligibility and transition decisions for the post-training reminder.
/// No plugin, database or clock access.
class HrvPostReminderPolicy {
  const HrvPostReminderPolicy({this.policy = HrvTimingPolicy.standard});
  final HrvTimingPolicy policy;

  ReminderDecision decide(ReminderInputs i) {
    final prev = i.previous;
    ReminderDecision keep(ReminderState s, ReminderReason r) =>
        ReminderDecision(
          state: s,
          action: ReminderAction.none,
          reason: r,
          originalDue: prev?.originalDue,
          nextDue: prev?.nextDue,
          expires: prev?.expires,
          snoozeCount: prev?.snoozeCount ?? 0,
        );
    ReminderDecision cancel(ReminderState s, ReminderReason r) =>
        ReminderDecision(
          state: s,
          action: prev != null && prev.state.active
              ? ReminderAction.cancel
              : ReminderAction.none,
          reason: r,
          originalDue: prev?.originalDue,
          nextDue: prev?.nextDue,
          expires: prev?.expires,
          snoozeCount: prev?.snoozeCount ?? 0,
        );

    // Terminal states stay: repeated sync, restart or a deleted post cannot
    // resurrect them.
    if (prev != null && prev.state.terminal) {
      return keep(prev.state, prev.reason);
    }
    if (i.skipRequested) {
      return cancel(ReminderState.skipped, ReminderReason.skippedByUser);
    }
    if (i.deleted) {
      return cancel(ReminderState.cancelled, ReminderReason.workoutDeleted);
    }
    // A usable post completes the request, whatever its protocol.
    if (i.hasUsablePost) {
      return cancel(ReminderState.completed, ReminderReason.postExists);
    }
    // A chain that was running is cancelled for good; one that never started
    // is only held back, so enabling the feature later still works.
    final retire = prev != null && prev.state.active
        ? ReminderState.cancelled
        : ReminderState.suppressed;
    if (!i.optedIn) {
      return cancel(retire, ReminderReason.featureOff);
    }
    if (!i.sensorReady) {
      return cancel(retire, ReminderReason.noSensor);
    }
    if (!i.hasUsablePre) {
      return cancel(ReminderState.suppressed, ReminderReason.noPre);
    }
    final interval = i.interval;
    final end = interval?.end;
    if (interval == null || end == null || !interval.endKnown) {
      return cancel(ReminderState.waitingForWorkout, ReminderReason.endUnknown);
    }
    if (interval.clockUncertain) {
      return cancel(ReminderState.suppressed, ReminderReason.clockUncertain);
    }
    if (i.ambiguous) {
      return cancel(ReminderState.suppressed, ReminderReason.ambiguous);
    }
    if (i.intervening) {
      return cancel(
        ReminderState.suppressed,
        ReminderReason.interveningWorkout,
      );
    }
    final since = i.enabledSince;
    if (since == null || end.isBefore(since)) {
      return cancel(ReminderState.suppressed, ReminderReason.enabledAfterEnd);
    }

    // Times of a chain that is running are kept; a held-back one starts over
    // from the actual end.
    final chain = prev != null && prev.state.active ? prev : null;
    final originalDue = chain?.originalDue ?? end.add(policy.reminderOffset);
    final expires = chain?.expires ?? end.add(policy.expiry);
    if (!i.now.isBefore(expires)) {
      return ReminderDecision(
        state: ReminderState.expired,
        action: prev != null && prev.state.active
            ? ReminderAction.cancel
            : ReminderAction.none,
        reason: ReminderReason.expired,
        originalDue: originalDue,
        nextDue: prev?.nextDue ?? originalDue,
        expires: expires,
        snoozeCount: prev?.snoozeCount ?? 0,
      );
    }
    if (!i.permissionGranted) {
      return cancel(ReminderState.suppressed, ReminderReason.permissionBlocked);
    }

    // A chain already known keeps its state; the clock only moves it on.
    if (prev != null && prev.state.active) {
      if (!i.now.isBefore(prev.nextDue)) {
        return keep(ReminderState.awaitingAction, ReminderReason.none);
      }
      return keep(prev.state, ReminderReason.none);
    }

    // First time the facts are eligible.
    var due = originalDue;
    if (i.historicalImport) {
      return cancel(ReminderState.suppressed, ReminderReason.historicalImport);
    }
    if (i.now.isAfter(originalDue.add(policy.catchUp))) {
      return cancel(ReminderState.suppressed, ReminderReason.lateDiscovery);
    }
    if (!i.capacityFree) {
      return cancel(ReminderState.suppressed, ReminderReason.capacity);
    }
    if (i.now.isAfter(originalDue)) due = i.now; // one immediate catch-up
    final quiet = i.quietHours;
    if (quiet != null) {
      final allowed = quiet.nextAllowed(due);
      if (allowed != due) {
        if (!i.postponeInQuietHours || !allowed.isBefore(expires)) {
          return cancel(ReminderState.suppressed, ReminderReason.quietHours);
        }
        due = allowed;
      }
    }
    return ReminderDecision(
      state: ReminderState.scheduled,
      action: ReminderAction.schedule,
      originalDue: originalDue,
      nextDue: due,
      expires: expires,
    );
  }

  /// A snooze: once, ten minutes from [now], before expiry. Null when it is
  /// not allowed, and the caller leaves the chain as it is.
  ReminderDecision? snooze(ReminderRecord prev, DateTime now) {
    if (prev.state.terminal || prev.snoozeCount >= policy.maxSnoozes) {
      return null;
    }
    final due = now.add(policy.snooze);
    if (!now.isBefore(prev.expires) || !due.isBefore(prev.expires)) {
      return null;
    }
    return ReminderDecision(
      state: ReminderState.snoozed,
      action: ReminderAction.schedule,
      originalDue: prev.originalDue,
      nextDue: due,
      expires: prev.expires,
      snoozeCount: prev.snoozeCount + 1,
    );
  }
}
