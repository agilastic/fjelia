import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/strength_workout.dart';
import '../../providers/plan_proposal_provider.dart';
import '../../providers/readiness_provider.dart';
import '../../services/daily_readiness_service.dart' show ReadinessLevel;
import '../../services/morning_revision.dart';
import '../../services/workout_semantics.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';

const _coach = [Color(0xFF9D7BFF), Color(0xFF3EE0FF)];
const _zoneColors = [
  Color(0xFF6FA8FF),
  mint,
  Color(0xFFFFE066),
  Color(0xFFFFB13D),
  Color(0xFFFF4D8D),
];

/// The coach's morning revision, opened from its push: what it changes and
/// why, before and after, and the athlete's answer. Nothing goes to a watch.
class CoachRevisionView extends ConsumerStatefulWidget {
  const CoachRevisionView({
    super.key,
    required this.revision,
    required this.context,
    this.onDone,
  });
  final MorningRevision revision;
  final RevisionContext context;
  final VoidCallback? onDone;

  @override
  ConsumerState<CoachRevisionView> createState() => _CoachRevisionViewState();
}

class _CoachRevisionViewState extends ConsumerState<CoachRevisionView> {
  bool _busy = false;

  Future<void> _answer(bool accept, {bool alternative = false}) async {
    setState(() => _busy = true);
    final day = widget.context.day;
    await runUiAction(context, () async {
      final lifecycle = ref.read(planProposalLifecycleProvider);
      accept
          ? await lifecycle.acceptRevision(day, alternative: alternative)
          : await lifecycle.answerReadiness(accept: false);
    });
    if (mounted) setState(() => _busy = false);
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = widget.revision, c = widget.context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          title: r.title,
          body: r.body,
          level: c.readinessLevel,
          label: _sameDay(c.day, c.realToday)
              ? null
              : '${l.coachRevisionLabel} · ${dayName(context, c.day, c.realToday)}',
        ),
        const SizedBox(height: 16),
        // Every session of the day and the next, changed or not, with the
        // coach's reason, under its day.
        for (final (d, sessions) in [(c.day, c.today), (c.nextDay, c.next)])
          if (sessions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: FigureLabel(
                _sameDay(d, c.realToday)
                    ? l.today
                    : dayName(context, d, c.realToday),
              ),
            ),
            for (final (i, s) in sessions.indexed)
              _Enter(
                index: i,
                child: switch (r.changes
                    .where((x) => x.sessionId == s.id)
                    .firstOrNull) {
                  final x? when x.op == RevisionOp.revise => _ReviseCard(
                    change: x,
                    context: c,
                  ),
                  final x? when x.op == RevisionOp.swap => _SwapCard(
                    change: x,
                    context: c,
                  ),
                  final x? when x.op == RevisionOp.rest => _RestCard(
                    session: s,
                    why: x.why,
                  ),
                  final x => _KeepCard(session: s, why: x?.why),
                },
              ),
          ],
        if (r.alternative case final alt?)
          _Enter(
            index: c.focus.length,
            child: _AlternativeCard(
              alternative: alt,
              context: c,
              busy: _busy,
              onTake: () => _answer(true, alternative: true),
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const ValueKey('revision-accept'),
                onPressed: _busy ? null : () => _answer(true),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.revisionAccept),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('revision-keep'),
                onPressed: _busy ? null : () => _answer(false),
                child: Text(l.keepPlan),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The orb, the coach's title and why.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.title,
    required this.body,
    required this.level,
    this.label,
    this.icon = Icons.auto_awesome,
    this.pair = _coach,
    this.note,
  });
  final String title, body, level;
  final String? label, note;
  final IconData icon;
  final List<Color> pair;

  @override
  Widget build(BuildContext context) {
    final tint = level == 'red'
        ? const Color(0xFFFF4D8D)
        : const Color(0xFFFFB13D);
    return SectionCard(
      accent: pair,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: .6, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, t, child) =>
                    Transform.scale(scale: t, child: child),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: pair,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: pair.first.withValues(alpha: .45),
                        blurRadius: 18,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientTitle(
                  label ?? context.l10n.coachRevisionLabel,
                  colors: pair,
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint,
                  boxShadow: [
                    BoxShadow(color: tint.withValues(alpha: .6), blurRadius: 8),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
              color: fjInk,
              height: 1.15,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(fontSize: 14, color: fjInk70, height: 1.4),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_off_outlined, size: 14, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note!,
                    style: TextStyle(fontSize: 12, color: muted, height: 1.35),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Each card slides in after the one before.
class _Enter extends StatelessWidget {
  const _Enter({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 420 + 120 * index),
    curve: Curves.easeOutCubic,
    builder: (context, t, child) => Transform.translate(
      offset: Offset(0, (1 - t) * 24),
      child: Transform.scale(scale: .97 + .03 * t, child: child),
    ),
    child: child,
  );
}

String _day(DateTime d) => DateFormat('EEE d. MMM').format(d);

class _ReviseCard extends StatelessWidget {
  const _ReviseCard({required this.change, required this.context});
  final RevisionChange change;
  final RevisionContext context;

  @override
  Widget build(BuildContext ctx) {
    final s = context.byId(change.sessionId)!;
    if (change.exercises != null) {
      return _StrengthRevision(
        session: s,
        plan: context.strengthPlans[s.id]?.plan,
        changes: change.exercises!,
        why: change.why,
      );
    }
    final before = WorkoutSemantics.of(s.stepsJson, sport: s.sport);
    final afterJson = revisionStepsJson(change.steps!);
    final after = WorkoutSemantics.of(afterJson, sport: s.sport);
    final l = ctx.l10n;
    return SectionCard(
      title: s.title,
      accent: const [Color(0xFFFFB13D), Color(0xFFFF4D8D)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StatPair(
                  l.revisionBefore,
                  '${before.isEmpty ? s.plannedDurationMin : before.totalMinutes}',
                  unit: 'min',
                  color: fjInk54,
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: muted),
              const SizedBox(width: 16),
              Expanded(
                child: StatPair(
                  l.revisionAfter,
                  '${after.totalMinutes}',
                  unit: 'min',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (s.stepsJson != null) ...[
            _StepBar(stepsJson: s.stepsJson!, sport: s.sport, faded: true),
            const SizedBox(height: 8),
          ],
          _StepBar(stepsJson: afterJson, sport: s.sport),
          _Why(change.why),
        ],
      ),
    );
  }
}

/// A session's steps as one bar: each step as wide as it is long, in its
/// zone's colour.
class _StepBar extends StatelessWidget {
  const _StepBar({
    required this.stepsJson,
    required this.sport,
    this.faded = false,
  });
  final String stepsJson, sport;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final steps = flatSteps(stepsJson);
    if (steps.isEmpty) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: faded ? 10 : 16,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: t,
              child: Row(
                children: [
                  for (final (seconds, zone) in steps)
                    Expanded(
                      flex: seconds.round().clamp(1, 100000),
                      child: Container(
                        margin: const EdgeInsets.only(right: 1),
                        color: _zoneColors[(zone - 1).clamp(0, 4)].withValues(
                          alpha: faded ? .35 : 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The steps one after the other, repeats unrolled: seconds and zone.
List<(double, int)> flatSteps(String stepsJson) {
  final out = <(double, int)>[];
  void walk(List items) {
    for (final i in items) {
      if (i is! Map) continue;
      if (i['workoutSteps'] is List) {
        final n = (i['numberOfIterations'] as num?)?.round() ?? 1;
        for (var k = 0; k < n.clamp(1, 30); k++) {
          walk(i['workoutSteps'] as List);
        }
        continue;
      }
      final seconds = (i['endConditionValue'] as num?)?.toDouble();
      if (seconds == null || seconds <= 0) continue;
      out.add((seconds, (i['zoneNumber'] as num?)?.round() ?? 2));
    }
  }

  Object? decoded;
  try {
    decoded = jsonDecode(stepsJson);
  } on FormatException {
    return out;
  }
  final steps = decoded is Map
      ? decoded['workoutSteps'] ?? decoded['steps']
      : decoded;
  if (steps is List) walk(steps);
  return out;
}

class _StrengthRevision extends StatelessWidget {
  const _StrengthRevision({
    required this.session,
    required this.plan,
    required this.changes,
    this.why,
  });
  final String? why;
  final TrainingSession session;
  final StrengthWorkoutPlan? plan;
  final List<RevisionExercise> changes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final byId = {for (final c in changes) c.id: c};
    final revised = plan == null ? null : reviseStrengthPlan(plan!, changes);
    final after = {
      for (final b in revised?.blocks ?? const <StrengthBlock>[])
        for (final e in b.exercises) e.id: e,
    };
    String sets(StrengthPlannedExercise e) {
      final working = [
        for (final s in e.sets)
          if (s.kind != StrengthSetKind.warmup) s,
      ];
      if (working.isEmpty) return '—';
      final first = working.first;
      final reps = first.reps ?? first.repMax;
      final kg = first.load?.kg;
      final per = reps != null
          ? '$reps'
          : first.durationSeconds != null
          ? '${first.durationSeconds} s'
          : '—';
      return [
        l.revisionSets('${working.length}', per),
        if (kg != null) '${valueText(kg)} kg',
      ].join(' · ');
    }

    return SectionCard(
      title: session.title,
      accent: const [Color(0xFFFF7AD9), Color(0xFF9D7BFF)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in plan?.blocks ?? const <StrengthBlock>[])
            for (final e in b.exercises)
              if (byId.containsKey(e.id))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: fjInk,
                                decoration: byId[e.id]!.drop
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FigureLabel(e.equipment),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            sets(e),
                            style: TextStyle(
                              fontSize: 12,
                              color: muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            byId[e.id]!.drop
                                ? l.revisionDropped
                                : sets(after[e.id] ?? e),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: byId[e.id]!.drop
                                  ? fjAccent(const Color(0xFFFF4D8D))
                                  : fjInk,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          _Why(why),
        ],
      ),
    );
  }
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.change, required this.context});
  final RevisionChange change;
  final RevisionContext context;

  @override
  Widget build(BuildContext ctx) => SectionCard(
    title: ctx.l10n.revisionSwapped,
    accent: const [Color(0xFF6FA8FF), Color(0xFF3EE0FF)],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SwapRow(change: change, context: context),
        _Why(change.why),
      ],
    ),
  );
}

/// The two sessions of a swap on their new days.
class _SwapRow extends StatelessWidget {
  const _SwapRow({required this.change, required this.context});
  final RevisionChange change;
  final RevisionContext context;

  @override
  Widget build(BuildContext ctx) {
    final a = context.byId(change.sessionId)!;
    final b = context.byId(change.withId!)!;
    Widget day(TrainingSession s, DateTime to) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigureLabel(_day(to)),
          const SizedBox(height: 4),
          Text(
            s.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: fjInk,
            ),
          ),
          Text(
            '${s.plannedDurationMin} min',
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
    return Row(
      children: [
        day(b, a.sessionDate),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.swap_horiz_rounded,
            size: 28,
            color: fjAccent(const Color(0xFF3EE0FF)),
          ),
        ),
        day(a, b.sessionDate),
      ],
    );
  }
}

class _RestCard extends StatelessWidget {
  const _RestCard({required this.session, this.why});
  final TrainingSession session;
  final String? why;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: context.l10n.revisionRestDay,
    accent: const [mint, Color(0xFFC6FF4D)],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.nightlight_round, color: fjAccent(mint)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                session.title,
                style: TextStyle(
                  fontSize: 14,
                  color: muted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
          ],
        ),
        _Why(why),
      ],
    ),
  );
}

/// The rules' proposal in the same look: shown when there is no coach (not
/// Pro, switched off) or the coach could not answer.
class RulesProposalView extends ConsumerStatefulWidget {
  const RulesProposalView({
    super.key,
    required this.proposal,
    this.coachUnavailable = false,
    this.onDone,
  });
  final ReadinessProposal proposal;
  final bool coachUnavailable;
  final VoidCallback? onDone;

  @override
  ConsumerState<RulesProposalView> createState() => _RulesProposalViewState();
}

class _RulesProposalViewState extends ConsumerState<RulesProposalView> {
  bool _busy = false;

  Future<void> _answer(bool accept) async {
    setState(() => _busy = true);
    await runUiAction(
      context,
      () => ref
          .read(planProposalLifecycleProvider)
          .answerReadiness(accept: accept),
    );
    if (mounted) setState(() => _busy = false);
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.proposal;
    final text = readinessProposalText(p, l);
    final red = p.readiness.level == ReadinessLevel.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          title: text.title,
          body: red ? l.proposalRulesRecovery : l.proposalRulesEasier,
          level: p.readiness.level.name,
          label: _sameDay(p.day, DateTime.now())
              ? l.proposalCardTitle
              : l.proposalForDay(dayName(context, p.day, DateTime.now())),
          icon: Icons.battery_charging_full_rounded,
          pair: const [Color(0xFFFFB13D), Color(0xFFFF4D8D)],
          note: widget.coachUnavailable ? l.proposalCoachUnavailable : null,
        ),
        const SizedBox(height: 16),
        for (final (i, c) in p.changes.indexed)
          _Enter(
            index: i,
            child: c.rest
                ? _RestCard(session: c.session)
                : _MinutesCard(session: c.session, minutes: c.durationMin),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _answer(true),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.revisionAccept),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _answer(false),
                child: Text(l.keepPlan),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A session the rules shorten: minutes before and after, its steps as
/// planned.
class _MinutesCard extends StatelessWidget {
  const _MinutesCard({required this.session, required this.minutes});
  final TrainingSession session;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final strength = isStrengthSession(session);
    return SectionCard(
      title: session.title,
      accent: strength
          ? const [Color(0xFFFF7AD9), Color(0xFF9D7BFF)]
          : const [Color(0xFFFFB13D), Color(0xFFFF4D8D)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StatPair(
                  l.revisionBefore,
                  '${session.plannedDurationMin}',
                  unit: 'min',
                  color: fjInk54,
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: muted),
              const SizedBox(width: 16),
              Expanded(
                child: StatPair(l.revisionAfter, '$minutes', unit: 'min'),
              ),
            ],
          ),
          if (session.stepsJson != null && !strength) ...[
            const SizedBox(height: 14),
            _StepBar(stepsJson: session.stepsJson!, sport: session.sport),
          ],
        ],
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "tomorrow, Tue 10 Nov" or the weekday and date of a later day.
String dayName(BuildContext context, DateTime day, DateTime today) {
  final l = context.l10n;
  final date = DateFormat('EEE d. MMM').format(day);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  return _sameDay(day, tomorrow) ? '${l.proposalDayTomorrow}, $date' : date;
}

/// The coach's reason under a card.
class _Why extends StatelessWidget {
  const _Why(this.text);
  final String? text;
  @override
  Widget build(BuildContext context) => text == null || text!.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: fjAccent(const Color(0xFF9D7BFF)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text!,
                  style: TextStyle(fontSize: 13, color: fjInk70, height: 1.35),
                ),
              ),
            ],
          ),
        );
}

/// A session the coach leaves as it is, and why.
class _KeepCard extends StatelessWidget {
  const _KeepCard({required this.session, this.why});
  final TrainingSession session;
  final String? why;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: session.title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, size: 18, color: fjAccent(mint)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.revisionKeep,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: fjInk,
                ),
              ),
            ),
            KeyFigure('${session.plannedDurationMin}', unit: 'min', size: 18),
          ],
        ),
        _Why(why),
      ],
    ),
  );
}

/// The coach's second way, usually a swap within the week, with its own
/// button.
class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.alternative,
    required this.context,
    required this.busy,
    required this.onTake,
  });
  final MorningRevision alternative;
  final RevisionContext context;
  final bool busy;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext ctx) {
    final l = ctx.l10n;
    return SectionCard(
      title: l.revisionAlternative,
      accent: const [Color(0xFF6FA8FF), Color(0xFF3EE0FF)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            alternative.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: fjInk,
            ),
          ),
          if (alternative.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              alternative.body,
              style: TextStyle(fontSize: 13, color: fjInk70, height: 1.35),
            ),
          ],
          for (final x in alternative.changes)
            if (x.op == RevisionOp.swap)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _SwapRow(change: x, context: context),
              ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('revision-alternative'),
            onPressed: busy ? null : onTake,
            child: Text(l.revisionTakeAlternative),
          ),
        ],
      ),
    );
  }
}
