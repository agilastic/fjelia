import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/hrv_pair_assessment.dart';
import '../models/hrv_training_episode.dart';
import '../providers/hrv_training_provider.dart';
import '../services/hrv/hrv_comparison_service.dart';
import '../services/hrv/hrv_post_reminder_policy.dart';
import '../services/hrv/hrv_texts.dart';
import '../theme/activity_colors.dart';
import '../theme/hrv_colors.dart';
import 'app_widgets.dart';
import 'polar_h10_hrv_sheet.dart';

const _surface = Color(0xFF282828);
const _line = Color(0x1FFFFFFF);

/// "HRV around this workout": the readings taken before and after one
/// completed workout on a timeline of real points, the paired change only when
/// the two are comparable, and the athlete's own history next to it. Reads the
/// same assessment as the chart and the AI, so the three never disagree.
class WorkoutHrvCard extends ConsumerWidget {
  const WorkoutHrvCard({super.key, required this.activityId, this.onExplain});
  final String activityId;

  /// Opens the AI explanation. Null hides the button.
  final VoidCallback? onExplain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(workoutHrvProvider(activityId)).valueOrNull;
    if (view == null) return const SizedBox.shrink();
    return _Body(view: view, onExplain: onExplain);
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.view, this.onExplain});
  final WorkoutHrvView view;
  final VoidCallback? onExplain;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool details = false;
  static final _time = DateFormat('HH:mm');

  WorkoutHrvView get v => widget.view;
  HrvPairAssessment get a => v.assessment;

  HrvLaunchContext _launch() {
    final pre = a.pre;
    return HrvLaunchContext(
      episodeId: v.episode.id,
      role: HrvRole.post,
      posture: pre?.posture,
      durationSeconds: pre?.durationSeconds,
      workoutEnd: v.episode.interval.endKnown ? v.episode.end : null,
    );
  }

  Future<void> _measure() =>
      showAppSheet(context, PolarH10HrvSheet(launch: _launch()));

  /// One short word for the state of the pair, shown as a chip.
  (String, Color, IconData) _status() {
    if (a.association == Association.ambiguous) {
      return ('Unclear', hrvNoticeColor, Icons.help_outline_rounded);
    }
    if (a.comparable) return ('Paired', mint, Icons.link_rounded);
    if (a.hasPair) {
      return ('Not comparable', hrvNoticeColor, Icons.link_off_rounded);
    }
    if (a.hasPre) return ('Waiting for after', muted, Icons.schedule_rounded);
    if (a.hasPost) return ('After only', muted, Icons.remove_rounded);
    return ('No readings', muted, Icons.remove_rounded);
  }

  String? _reminderLine() {
    final r = v.reminder;
    if (r == null || a.hasPost) return null;
    return switch (ReminderState.parse(r.desiredState)) {
      ReminderState.waitingForWorkout => 'Waiting for the actual workout end.',
      ReminderState.scheduled || ReminderState.snoozed =>
        'Reminder around ${_time.format(r.nextDueAtUtc.toLocal())}',
      ReminderState.awaitingAction =>
        'Reminder is due. Measure when you are ready.',
      ReminderState.suppressed when r.reason == 'permissionBlocked' =>
        'Notifications are off. You can still measure from your workout.',
      ReminderState.expired =>
        'This reminder is no longer current. Open the workout to view your measurements.',
      _ => null,
    };
  }

  Set<String> _mismatch() => {
    if (a.reasons.contains(HrvReason.postureMismatch)) 'posture',
    if (a.reasons.contains(HrvReason.durationMismatch)) 'duration',
  };

  String _semantics() {
    final b = StringBuffer('HRV around this workout. ');
    if (a.pre != null) {
      b.write('Before ${a.pre!.rmssdMs.toStringAsFixed(1)} milliseconds. ');
    }
    if (a.post != null) {
      b.write('After ${a.post!.rmssdMs.toStringAsFixed(1)} milliseconds');
      if (a.postDelay != null) {
        b.write(', ${a.postDelay!.inMinutes} minutes after the workout ended');
      }
      b.write('. ');
    }
    if (a.comparable) {
      b.write(
        'Change ${hrvSigned(a.deltaMs!)} milliseconds, '
        '${hrvSigned(a.deltaPercent!)} percent.',
      );
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final noReadings = !a.hasPre && !a.hasPost;
    final reminder = _reminderLine();
    final interval = a.interval;
    final (label, color, icon) = _status();
    final reasons = [
      for (final r in hrvVisibleReasons(a))
        if (r != HrvReason.legacyQualityUnknown || details) r,
    ];

    return Semantics(
      container: true,
      label: _semantics(),
      child: SectionCard(
        title: 'HRV around this workout',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!noReadings || a.association == Association.ambiguous) ...[
              _StatusChip(label: label, color: color, icon: icon),
              const SizedBox(height: 14),
            ],
            if (noReadings) ...[
              _EmptyState(onMeasure: _measure),
            ] else ...[
              ExcludeSemantics(
                child: _Timeline(
                  pre: a.pre,
                  post: a.post,
                  preGap: a.preGap,
                  postDelay: a.postDelay,
                  sport: v.episode.sport,
                  start: interval?.start,
                  end: interval != null && interval.endKnown
                      ? interval.end
                      : null,
                  userReported: interval?.basis == IntervalBasis.userReported,
                ),
              ),
              const SizedBox(height: 14),
              ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final before = _ReadingTile(
                      label: 'Before',
                      color: hrvBeforeColor,
                      reading: a.pre,
                      missing: 'No pre-training measurement recorded.',
                      mismatch: _mismatch(),
                    );
                    final after = _ReadingTile(
                      label: 'After',
                      color: hrvAfterColor,
                      reading: a.post,
                      delay: a.postDelay,
                      missing: 'Not measured yet',
                      mismatch: _mismatch(),
                    );
                    // Side by side normally; one above the other on a narrow
                    // screen or with large text.
                    final stacked =
                        box.maxWidth < 300 ||
                        MediaQuery.textScalerOf(context).scale(10) > 13;
                    return stacked
                        ? Column(
                            children: [
                              before,
                              const SizedBox(height: 10),
                              after,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: before),
                              const SizedBox(width: 10),
                              Expanded(child: after),
                            ],
                          );
                  },
                ),
              ),
              if (a.comparable) ...[
                const SizedBox(height: 12),
                ExcludeSemantics(child: _ChangePill(a: a)),
                const SizedBox(height: 12),
                _History(cohort: v.cohort, delta: a.deltaMs!),
              ],
            ],
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final r in reasons) _Notice(text: hrvReasonLabel(r)),
            ],
            if (reminder != null) ...[
              const SizedBox(height: 10),
              _ReminderPill(text: reminder),
            ],
            if (!noReadings) ...[
              const SizedBox(height: 16),
              _Rpe(
                feedback: v.feedback,
                onSelect: (rpe) => ref
                    .read(hrvTrainingActionsProvider)
                    .recordFeedback(v.episode.id, rpe: rpe),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (a.hasPre && !a.hasPost && interval?.endKnown == true)
                  FilledButton.tonalIcon(
                    onPressed: _measure,
                    icon: const Icon(Icons.favorite_rounded, size: 18),
                    label: const Text('Measure after training'),
                  ),
                if (a.hasPost)
                  OutlinedButton.icon(
                    onPressed: _measure,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Measure again'),
                  ),
                if (widget.onExplain != null && a.hasPair)
                  OutlinedButton.icon(
                    onPressed: widget.onExplain,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Explain with AI'),
                  ),
                if (!noReadings || a.association == Association.ambiguous)
                  TextButton.icon(
                    onPressed: () => setState(() => details = !details),
                    icon: Icon(
                      details
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                    ),
                    label: Text(details ? 'Hide details' : 'Details'),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: details
                  ? _details()
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details() {
    final snapshot = ref.watch(hrvSnapshotProvider).valueOrNull;
    final c = v.cohort;
    final linked = <MeasurementFact>[?a.pre, ?a.post, ...a.additionalPosts];
    // Readings near the workout that belong to no workout yet.
    final loose = snapshot == null
        ? const <MeasurementFact>[]
        : [
            for (final m in snapshot.measurements)
              if (snapshot.episodeOfMeasurement(m.uid) == null &&
                  m.context != 'resting' &&
                  m.startedAt.difference(v.episode.start).abs() <
                      const Duration(hours: 6))
                m,
          ];
    TextStyle small([Color color = muted]) =>
        TextStyle(fontSize: 12, color: color, height: 1.4);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Association: ${switch (a.association) {
              Association.unambiguous => 'found automatically',
              Association.corrected => 'set by you',
              Association.partial => 'one side only',
              Association.ambiguous => 'unclear (overlapping workouts)',
              Association.none => 'none',
            }}',
            style: small(),
          ),
          if (a.preGap != null)
            Text(
              'Before ended ${hrvMinutes(a.preGap!)} ahead of the start.',
              style: small(),
            ),
          if (c.excludedTotal > 0)
            Text(
              'Left out of the comparison: ${c.excludedTotal} workouts '
              '(${_exclusions(c)}).',
              style: small(),
            ),
          if (a.additionalPosts.isNotEmpty)
            Text(
              '${a.additionalPosts.length} further measurement(s) after this workout are kept as extra observations.',
              style: small(),
            ),
          for (final m in linked)
            _DetailRow(
              text:
                  '${m.isPre ? 'Before' : 'After'} · ${_time.format(m.startedAt.toLocal())}',
              action: 'Not from this workout',
              onTap: () => ref.read(hrvTrainingActionsProvider).unlink(m.uid),
            ),
          for (final m in loose)
            _DetailRow(
              text:
                  '${m.isPre ? 'Before' : 'After'}-reading ${_time.format(m.startedAt.toLocal())}, not assigned',
              action: m.isPre ? 'Use as before' : 'Use as after',
              onTap: () => ref
                  .read(hrvTrainingActionsProvider)
                  .correct(
                    m.uid,
                    v.episode.id,
                    m.isPre ? HrvRole.pre : HrvRole.post,
                  ),
            ),
        ],
      ),
    );
  }

  String _exclusions(HrvCohort c) => [
    for (final e in c.excluded.entries)
      '${e.value} ${switch (e.key) {
        CohortExclusion.notComparable => 'not comparable',
        CohortExclusion.sport => 'other sport',
        CohortExclusion.workoutLength => 'other length',
        CohortExclusion.posture => 'other position',
        CohortExclusion.protocol => 'other protocol',
        CohortExclusion.sensor => 'other sensor',
        CohortExclusion.timing => 'other timing',
        CohortExclusion.tooOld => 'too old',
        CohortExclusion.notEarlier => 'later',
      }}',
  ].join(', ');
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onMeasure});
  final VoidCallback onMeasure;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hrvAfterColor.withValues(alpha: .12),
        ),
        child: const Icon(Icons.monitor_heart_outlined, color: hrvAfterColor),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No HRV measurement recorded around this workout.',
              style: TextStyle(color: muted, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 6),
            FilledButton.tonalIcon(
              onPressed: onMeasure,
              icon: const Icon(Icons.favorite_rounded, size: 18),
              label: const Text('Measure HRV'),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Pre reading, the workout, post reading: real points only. The connectors
/// carry the measured gaps; nothing is drawn between the readings that would
/// look like a measured recovery curve.
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.pre,
    required this.post,
    required this.preGap,
    required this.postDelay,
    required this.sport,
    required this.start,
    required this.end,
    required this.userReported,
  });
  final MeasurementFact? pre, post;
  final Duration? preGap, postDelay;
  final String sport;
  final DateTime? start, end;
  final bool userReported;

  static final _time = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final sportColor = completedActivityColor(sport);
    String gap(Duration? d) => d == null ? '' : hrvMinutes(d);
    final workoutText = start == null
        ? 'Workout'
        : end == null
        ? '${_time.format(start!.toLocal())}–?'
        : '${_time.format(start!.toLocal())}–${_time.format(end!.toLocal())}'
              '${userReported ? ' · by you' : ''}';
    // With large text or a narrow screen the timeline runs top to bottom, so
    // no label is squeezed.
    if (MediaQuery.textScalerOf(context).scale(10) > 13) {
      Widget row(Widget lead, String text, {Color color = muted}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(width: 28, child: Center(child: lead)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: TextStyle(fontSize: 13, color: color)),
            ),
          ],
        ),
      );
      Widget dot(Color c, bool filled) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? c : Colors.transparent,
          border: Border.all(color: c, width: 2),
        ),
      );
      final stem = Container(width: 2, height: 14, color: _line);
      return Column(
        children: [
          row(
            dot(hrvBeforeColor, pre != null),
            pre == null
                ? 'Before · not measured'
                : 'Before · ${_time.format(pre!.startedAt.toLocal())}',
            color: Colors.white,
          ),
          if (preGap != null) row(stem, gap(preGap)),
          row(
            Icon(activitySportIcon(sport), size: 18, color: sportColor),
            'Workout · $workoutText',
            color: Colors.white,
          ),
          if (postDelay != null) row(stem, gap(postDelay)),
          row(
            dot(hrvAfterColor, post != null),
            post == null
                ? 'After · not measured yet'
                : 'After · ${_time.format(post!.startedAt.toLocal())}',
            color: Colors.white,
          ),
        ],
      );
    }
    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Point(
            color: hrvBeforeColor,
            filled: pre != null,
            time: pre == null ? '—' : _time.format(pre!.startedAt.toLocal()),
          ),
          Expanded(child: _Connector(label: gap(preGap))),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Container(
                  height: 28,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        sportColor.withValues(alpha: .35),
                        sportColor.withValues(alpha: .18),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sportColor.withValues(alpha: .6)),
                  ),
                  child: Icon(
                    activitySportIcon(sport),
                    size: 16,
                    color: sportColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  workoutText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          Expanded(child: _Connector(label: gap(postDelay))),
          _Point(
            color: hrvAfterColor,
            filled: post != null,
            time: post == null ? '—' : _time.format(post!.startedAt.toLocal()),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.color, required this.filled, required this.time});
  final Color color;
  final bool filled;
  final String time;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    child: Column(
      children: [
        const SizedBox(height: 5),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(
              color: filled ? color : color.withValues(alpha: .45),
              width: 2,
            ),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .45),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 11),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            time,
            maxLines: 1,
            style: const TextStyle(fontSize: 11, color: muted),
          ),
        ),
      ],
    ),
  );
}

class _Connector extends StatelessWidget {
  const _Connector({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 28,
        child: CustomPaint(
          painter: _DashPainter(),
          child: const SizedBox.expand(),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: const TextStyle(fontSize: 10, color: Color(0x99FFFFFF)),
      ),
    ],
  );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _line
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (var x = 4.0; x < size.width - 4; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(x + 3, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}

const _flagged = TextStyle(color: hrvNoticeColor, fontWeight: FontWeight.w700);

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({
    required this.label,
    required this.color,
    required this.reading,
    required this.missing,
    this.delay,
    this.mismatch = const {},
  });
  final String label;
  final Color color;
  final MeasurementFact? reading;
  final Duration? delay;
  final String missing;

  /// Attributes that differ from the other reading: `posture`, `duration`.
  final Set<String> mismatch;

  @override
  Widget build(BuildContext context) {
    final m = reading;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: m == null ? _surface : color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: m == null ? _line : color.withValues(alpha: .35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (m == null)
            Text(missing, style: const TextStyle(color: muted, fontSize: 12))
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      m.rmssdMs.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Text('ms', style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  if (delay != null)
                    TextSpan(text: '+${hrvMinutes(delay!)} after · '),
                  TextSpan(
                    text: m.posture == 'supine' ? 'Lying' : 'Seated',
                    style: mismatch.contains('posture') ? _flagged : null,
                  ),
                  const TextSpan(text: ' · '),
                  TextSpan(
                    text: '${(m.durationSeconds / 60).round()} min',
                    style: mismatch.contains('duration') ? _flagged : null,
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 11, color: muted, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

/// The paired change in a neutral colour: lower is not worse, higher is not
/// better.
class _ChangePill extends StatelessWidget {
  const _ChangePill({required this.a});
  final HrvPairAssessment a;

  @override
  Widget build(BuildContext context) {
    final down = a.deltaMs! < 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x1FFFFFFF),
            ),
            child: Icon(
              down ? Icons.south_east_rounded : Icons.north_east_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 10,
                  children: [
                    Text(
                      '${hrvSigned(a.deltaMs!)} ms',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${hrvSigned(a.deltaPercent!)} %',
                        style: const TextStyle(fontSize: 15, color: muted),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'A description of this pair, not a score for the workout.',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The athlete's own comparable workouts: a range bar once there are enough,
/// a progress row until then.
class _History extends ConsumerWidget {
  const _History({required this.cohort, required this.delta});
  final HrvCohort cohort;
  final double delta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = cohort;
    final need = ref.watch(hrvCohortMinimumProvider);
    final day = DateFormat('d MMM');
    if (!c.sufficient) {
      return Semantics(
        label: 'Not enough comparable workouts yet, ${c.eligible} of $need.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Not enough comparable workouts yet (${c.eligible} of $need).',
              style: const TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < need; i++)
                    Expanded(
                      child: Container(
                        height: 5,
                        margin: EdgeInsets.only(right: i == need - 1 ? 0 : 4),
                        decoration: BoxDecoration(
                          color: i < c.eligible ? hrvBeforeColor : _surface,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final text =
        'Your similar workouts (${c.eligible}, ${day.format(c.first!.toLocal())}–${day.format(c.last!.toLocal())}): '
        'median ${hrvSigned(c.medianMs!)} ms, middle half ${hrvSigned(c.q1Ms!)} to ${hrvSigned(c.q3Ms!)} ms.';
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your ${c.eligible} similar workouts · ${day.format(c.first!.toLocal())}–${day.format(c.last!.toLocal())}',
              style: const TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 26,
              child: CustomPaint(
                painter: _RangePainter(
                  q1: c.q1Ms!,
                  median: c.medianMs!,
                  q3: c.q3Ms!,
                  value: delta,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Middle half ${hrvSigned(c.q1Ms!)} to ${hrvSigned(c.q3Ms!)} ms · median ${hrvSigned(c.medianMs!)} ms · this workout ${hrvSigned(delta)} ms',
              style: const TextStyle(fontSize: 11, color: muted, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

/// A descriptive range, not a norm: the middle half of the athlete's own
/// paired changes, the median, and this workout's change as a dot.
class _RangePainter extends CustomPainter {
  _RangePainter({
    required this.q1,
    required this.median,
    required this.q3,
    required this.value,
  });
  final double q1, median, q3, value;

  @override
  void paint(Canvas canvas, Size size) {
    final low = [q1, value].reduce((a, b) => a < b ? a : b);
    final high = [q3, value].reduce((a, b) => a > b ? a : b);
    final pad = ((high - low).abs() * .25).clamp(2, 1000).toDouble();
    final from = low - pad, to = high + pad;
    double x(double v) => 8 + (v - from) / (to - from) * (size.width - 16);
    final y = size.height / 2;
    final track = Paint()
      ..color = _surface
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), track);
    final band = Paint()
      ..color = hrvBeforeColor.withValues(alpha: .35)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x(q1), y), Offset(x(q3), y), band);
    canvas.drawLine(
      Offset(x(median), y - 8),
      Offset(x(median), y + 8),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset(x(value), y), 7, Paint()..color = hrvAfterColor);
    canvas.drawCircle(
      Offset(x(value), y),
      7,
      Paint()
        ..color = const Color(0xFF202020)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_RangePainter old) =>
      old.q1 != q1 ||
      old.q3 != q3 ||
      old.median != median ||
      old.value != value;
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: hrvNoticeColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFE6D3A3),
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReminderPill extends StatelessWidget {
  const _ReminderPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.notifications_none_rounded,
          size: 16,
          color: Colors.white70,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, height: 1.3)),
        ),
      ],
    ),
  );
}

/// How hard it felt, 1 to 10, on one row that fits any width.
class _Rpe extends StatelessWidget {
  const _Rpe({required this.feedback, required this.onSelect});
  final WorkoutFeedback feedback;
  final ValueChanged<int> onSelect;

  static Color _tone(int i) =>
      Color.lerp(hrvBeforeColor, hrvAfterColor, (i - 1) / 9)!;

  @override
  Widget build(BuildContext context) {
    final f = feedback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          f.rpe == null
              ? 'How hard did it feel? (RPE)'
              : 'RPE ${f.rpe}${f.fromSession ? ' · from your plan session' : ''}',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= 10; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 10 ? 0 : 4),
                  child: Semantics(
                    button: true,
                    selected: f.rpe == i,
                    label: 'RPE $i',
                    child: ExcludeSemantics(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onSelect(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: f.rpe == i
                                ? _tone(i)
                                : _tone(i).withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FittedBox(
                            child: Text(
                              '$i',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: f.rpe == i
                                    ? const Color(0xFF111111)
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('easy', style: TextStyle(fontSize: 10, color: muted)),
            Text('all out', style: TextStyle(fontSize: 10, color: muted)),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.text,
    required this.action,
    required this.onTap,
  });
  final String text, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}
