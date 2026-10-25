import 'package:fjelia/models/hrv_training_episode.dart';

final t0 = DateTime.utc(2026, 11, 2, 8);

DateTime at(int minutes) => t0.add(Duration(minutes: minutes));

/// A workout from [start] to [end], minutes after [t0].
EpisodeFact workout(
  String id,
  int start,
  int? end, {
  String sport = 'cycling',
  IntervalBasis basis = IntervalBasis.providerElapsed,
  bool clockUncertain = false,
  String? parentId,
  EpisodeState state = EpisodeState.actualCompleted,
}) => EpisodeFact(
  id: id,
  sport: sport,
  parentId: parentId,
  state: state,
  interval: ActualInterval(
    start: at(start),
    end: end == null ? null : at(end),
    basis: end == null ? IntervalBasis.unknown : basis,
    clockUncertain: clockUncertain,
  ),
);

/// A measurement whose sampling runs from [start] for [seconds].
MeasurementFact reading(
  String uid,
  int start,
  String context, {
  double rmssd = 50,
  String posture = 'seated',
  int seconds = 300,
  int settle = 60,
  bool usable = true,
  String metric = 'rmssd',
  String device = 'h10',
  bool legacy = false,
}) => MeasurementFact(
  uid: uid,
  startedAt: at(start),
  endedAt: at(start).add(Duration(seconds: seconds)),
  context: context,
  posture: posture,
  durationSeconds: seconds,
  settleSeconds: settle,
  rmssdMs: rmssd,
  usable: usable,
  metricKind: metric,
  deviceId: device,
  legacyQualityUnknown: legacy,
);

MeasurementFact pre(
  String uid,
  int start, {
  double rmssd = 60,
  int seconds = 300,
}) => reading(uid, start, 'beforeTraining', rmssd: rmssd, seconds: seconds);

MeasurementFact post(
  String uid,
  int start, {
  double rmssd = 45,
  int seconds = 300,
}) => reading(uid, start, 'afterTraining', rmssd: rmssd, seconds: seconds);
