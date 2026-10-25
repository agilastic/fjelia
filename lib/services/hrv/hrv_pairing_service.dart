import '../../models/hrv_training_episode.dart';
import 'hrv_timing_policy.dart';

/// A link the athlete (or a launch from a workout) fixed on purpose.
class HrvPin {
  const HrvPin(
    this.measurementUid,
    this.episodeId,
    this.role, {
    this.method = AssociationMethod.userCorrection,
  });
  final String measurementUid, episodeId;
  final HrvRole role;
  final AssociationMethod method;
}

class HrvPairingResult {
  const HrvPairingResult(this.pairings, this.links);
  final Map<String, EpisodePairing> pairings;
  final List<HrvLink> links;

  EpisodePairing? of(String episodeId) => pairings[episodeId];
}

/// Deterministic temporal association of measurements and workouts.
///
/// The result depends only on the final set of facts, never on the order in
/// which they arrived. It never prefers a measurement because its HRV looks
/// better: ties are broken by time and then by the measurement id.
class HrvPairingService {
  const HrvPairingService({this.policy = HrvTimingPolicy.standard});
  final HrvTimingPolicy policy;

  HrvPairingResult resolve({
    required List<EpisodeFact> episodes,
    required List<MeasurementFact> measurements,
    List<HrvPin> pins = const [],
  }) {
    // Children of a reliable parent are part of the parent; episodes without
    // a known end cannot be paired but still count where they are known.
    final all =
        [
          for (final e in episodes)
            if (e.live && e.parentId == null) e,
        ]..sort((a, b) {
          final c = a.start.compareTo(b.start);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
    final byId = {for (final e in all) e.id: e};
    final known = [
      for (final e in all)
        if (e.end != null) e,
    ];

    // Overlapping distinct workouts are ambiguous unless a parent resolves it.
    final ambiguous = <String>{};
    for (var i = 0; i < known.length; i++) {
      for (var j = i + 1; j < known.length; j++) {
        if (known[j].start.isBefore(known[i].end!)) {
          ambiguous
            ..add(known[i].id)
            ..add(known[j].id);
        }
      }
    }

    final byUid = {for (final m in measurements) m.uid: m};
    final pinnedUids = {for (final p in pins) p.measurementUid};
    final taken = <String>{};
    final links = <HrvLink>[];
    final pairings = <String, EpisodePairing>{};
    final contradictions = <String, List<String>>{};
    final pinnedPre = <String, MeasurementFact>{};
    final pinnedPost = <String, List<MeasurementFact>>{};
    final pinMethod = <String, AssociationMethod>{};

    // Pins first: honoured when their timing is valid for the episode.
    for (final p in pins) {
      final m = byUid[p.measurementUid];
      final e = byId[p.episodeId];
      if (m == null || e == null || !m.usable) continue;
      final end = e.end;
      final ok = switch (p.role) {
        HrvRole.pre => !m.endedAt.isAfter(e.start),
        HrvRole.post => end != null && !m.startedAt.isBefore(end),
      };
      if (!ok) {
        (contradictions[e.id] ??= []).add(m.uid);
        continue;
      }
      if (!taken.add(m.uid)) continue;
      pinMethod[m.uid] = p.method;
      if (p.role == HrvRole.pre) {
        final current = pinnedPre[e.id];
        if (current == null || _later(m, current)) pinnedPre[e.id] = m;
      } else {
        (pinnedPost[e.id] ??= []).add(m);
      }
    }

    bool exercise(MeasurementFact m) => known.any(
      (e) => e.start.isBefore(m.endedAt) && e.end!.isAfter(m.startedAt),
    );

    for (final e in all) {
      final end = e.end;
      final isAmbiguous = ambiguous.contains(e.id);
      MeasurementFact? pre = pinnedPre[e.id];
      final posts = <MeasurementFact>[];
      final chosenPosts = [...?pinnedPost[e.id]]..sort(_earlierFirst);
      final corrected = pre != null || chosenPosts.isNotEmpty;

      if (!isAmbiguous) {
        // Pre: the latest eligible one before the start.
        if (pre == null) {
          final candidates = [
            for (final m in measurements)
              if (m.isPre &&
                  m.usable &&
                  !pinnedUids.contains(m.uid) &&
                  !taken.contains(m.uid) &&
                  !m.endedAt.isAfter(e.start) &&
                  e.start.difference(m.endedAt) <= policy.preWindow &&
                  !exercise(m))
                m,
          ]..sort(_laterFirst);
          // Skip a candidate when another workout sits between it and the start.
          for (final m in candidates) {
            final between = known.any(
              (o) =>
                  o.id != e.id &&
                  o.start.isBefore(e.start) &&
                  o.end!.isAfter(m.startedAt),
            );
            if (!between) {
              pre = m;
              break;
            }
          }
        }
        // Posts: eligible ones from the end on, earliest first.
        if (end != null) {
          final candidates = [
            for (final m in measurements)
              if (m.isPost &&
                  m.usable &&
                  !pinnedUids.contains(m.uid) &&
                  !taken.contains(m.uid) &&
                  !m.startedAt.isBefore(end) &&
                  m.startedAt.difference(end) <= policy.postWindow &&
                  !exercise(m) &&
                  !known.any(
                    (o) =>
                        o.id != e.id &&
                        o.start.isBefore(m.endedAt) &&
                        o.end!.isAfter(end),
                  ))
                m,
          ]..sort(_earlierFirst);
          posts.addAll(candidates);
        }
      }
      posts.sort(_earlierFirst);
      // A pinned post is the athlete's choice, so it stays primary.
      final ordered = [...chosenPosts, ...posts];
      final primary = ordered.isEmpty ? null : ordered.first;
      final extra = ordered.length > 1 ? ordered.sublist(1) : const [];

      if (pre != null) {
        taken.add(pre.uid);
        links.add(
          HrvLink(
            episodeId: e.id,
            measurementUid: pre.uid,
            role: HrvRole.pre,
            selection: LinkSelection.primary,
            method: pinMethod[pre.uid] ?? AssociationMethod.automaticTimeline,
          ),
        );
      }
      for (var i = 0; i < ordered.length; i++) {
        final m = ordered[i];
        taken.add(m.uid);
        links.add(
          HrvLink(
            episodeId: e.id,
            measurementUid: m.uid,
            role: HrvRole.post,
            selection: i == 0
                ? LinkSelection.primary
                : LinkSelection.additional,
            method: pinMethod[m.uid] ?? AssociationMethod.automaticTimeline,
          ),
        );
      }

      pairings[e.id] = EpisodePairing(
        episodeId: e.id,
        pre: pre,
        post: primary,
        additionalPosts: List.unmodifiable(extra),
        association: isAmbiguous
            ? Association.ambiguous
            : corrected
            ? Association.corrected
            : pre != null && primary != null
            ? Association.unambiguous
            : pre != null || primary != null
            ? Association.partial
            : Association.none,
        contradictions: List.unmodifiable(contradictions[e.id] ?? const []),
      );
    }
    return HrvPairingResult(pairings, links);
  }

  static bool _later(MeasurementFact a, MeasurementFact b) =>
      _laterFirst(a, b) < 0;

  static int _laterFirst(MeasurementFact a, MeasurementFact b) {
    var c = b.endedAt.compareTo(a.endedAt);
    if (c != 0) return c;
    c = b.startedAt.compareTo(a.startedAt);
    return c != 0 ? c : a.uid.compareTo(b.uid);
  }

  static int _earlierFirst(MeasurementFact a, MeasurementFact b) {
    var c = a.startedAt.compareTo(b.startedAt);
    if (c != 0) return c;
    c = a.endedAt.compareTo(b.endedAt);
    return c != 0 ? c : a.uid.compareTo(b.uid);
  }
}
