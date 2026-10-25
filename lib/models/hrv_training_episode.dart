/// How the end of an actual workout is known, best evidence first.
enum IntervalBasis {
  providerFinish,
  providerElapsed,
  userReported,
  unknown;

  static IntervalBasis parse(String? name) => values.firstWhere(
    (b) => b.name == name,
    orElse: () => IntervalBasis.unknown,
  );
}

/// The normalized actual interval of one physical workout. Both ends are
/// instants; [end] is null when it is not known, and then no end-based
/// reminder or post delay exists.
class ActualInterval {
  const ActualInterval({
    required this.start,
    this.end,
    this.basis = IntervalBasis.unknown,
    this.clockUncertain = false,
  });
  final DateTime start;
  final DateTime? end;
  final IntervalBasis basis;
  final bool clockUncertain;

  bool get endKnown => end != null && basis != IntervalBasis.unknown;
  Duration? get elapsed => end?.difference(start);
}

enum EpisodeState {
  provisional,
  actualCompleted,
  ambiguous,
  cancelled,
  deleted,
}

/// A physical workout as the pairing sees it.
class EpisodeFact {
  const EpisodeFact({
    required this.id,
    required this.interval,
    this.sport = 'other',
    this.state = EpisodeState.actualCompleted,
    this.parentId,
    this.detectedAt,
    this.plannedSessionId,
    this.activityId,
    this.intervalRevision = 0,
  });
  final String id;
  final ActualInterval interval;
  final String sport;
  final EpisodeState state;

  /// A reliable multisport parent. Children are never episodes of their own.
  final String? parentId;
  final DateTime? detectedAt;
  final int? plannedSessionId;
  final String? activityId;
  final int intervalRevision;

  DateTime get start => interval.start;
  DateTime? get end => interval.end;
  bool get live =>
      state != EpisodeState.cancelled && state != EpisodeState.deleted;
}

enum HrvRole { pre, post }

enum LinkSelection { primary, additional }

enum AssociationMethod { automaticTimeline, launchContext, userCorrection }

/// One measurement as the pairing sees it. [startedAt] is the start of the
/// sampling window after settling, [endedAt] its end.
class MeasurementFact {
  const MeasurementFact({
    required this.uid,
    required this.startedAt,
    required this.endedAt,
    required this.context,
    required this.posture,
    required this.durationSeconds,
    required this.settleSeconds,
    required this.rmssdMs,
    this.sdnnMs,
    this.deviceId = '',
    this.metricKind = 'rmssd',
    this.usable = true,
    this.legacyQualityUnknown = false,
    this.clockUncertain = false,
    this.reportedMinutesAfter,
    this.revision = 0,
  });
  final String uid;
  final DateTime startedAt, endedAt;

  /// `beforeTraining`, `afterTraining` or `resting`.
  final String context;
  final String posture;
  final int durationSeconds, settleSeconds;
  final double rmssdMs;
  final double? sdnnMs;
  final String deviceId, metricKind;
  final bool usable, legacyQualityUnknown;

  /// The wall clock jumped while this was recorded. The RR timing is intact,
  /// the absolute time is not trusted.
  final bool clockUncertain;
  final int? reportedMinutesAfter;
  final int revision;

  bool get isPre => context == 'beforeTraining';
  bool get isPost => context == 'afterTraining';
}

/// A resolved association between a measurement and an episode.
class HrvLink {
  const HrvLink({
    required this.episodeId,
    required this.measurementUid,
    required this.role,
    required this.selection,
    this.method = AssociationMethod.automaticTimeline,
  });
  final String episodeId, measurementUid;
  final HrvRole role;
  final LinkSelection selection;
  final AssociationMethod method;

  @override
  bool operator ==(Object other) =>
      other is HrvLink &&
      other.episodeId == episodeId &&
      other.measurementUid == measurementUid &&
      other.role == role &&
      other.selection == selection &&
      other.method == method;

  @override
  int get hashCode =>
      Object.hash(episodeId, measurementUid, role, selection, method);
}

enum Association { unambiguous, partial, ambiguous, corrected, none }

/// What the pairing decided for one episode.
class EpisodePairing {
  const EpisodePairing({
    required this.episodeId,
    this.pre,
    this.post,
    this.additionalPosts = const [],
    this.association = Association.none,
    this.contradictions = const [],
  });
  final String episodeId;
  final MeasurementFact? pre, post;
  final List<MeasurementFact> additionalPosts;
  final Association association;

  /// Pinned links whose timing contradicts the episode; they are not applied.
  final List<String> contradictions;
}

/// How the capture sheet is opened from a workout or a reminder: which
/// workout, which role, and the protocol of the matching pre measurement.
class HrvLaunchContext {
  const HrvLaunchContext({
    required this.episodeId,
    this.role = HrvRole.post,
    this.posture,
    this.durationSeconds,
    this.workoutEnd,
    this.reminderId,
  });
  final String episodeId;
  final HrvRole role;
  final String? posture;
  final int? durationSeconds;

  /// Actual end of the workout, to show the real delay while measuring.
  final DateTime? workoutEnd;
  final String? reminderId;
}
