import '../../l10n/formats.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../config/free_ai.dart' show planningTimeout;
import '../../l10n/l10n_ext.dart';
import '../../providers/ai_coach_provider.dart';
import '../../providers/heat_acclimation_provider.dart';
import '../../providers/missed_workout_provider.dart';
import '../../providers/plan_week_provider.dart';
import '../../providers/planner_providers.dart';
import '../../providers/sync_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/ai_coach_client.dart' show AiConsentToken;
import '../../services/ai_coach_settings.dart';
import '../../services/coach_language.dart';
import '../../services/missed_workout_planner.dart';
import '../../services/missed_workout_reminder_service.dart';
import '../../services/open_meteo_client.dart' show OpenMeteoPoint;
import '../../services/plan_rebalance.dart';
import '../../services/plan_session_actions.dart' show skipReasons;
import '../../theme/activity_colors.dart';
import '../../utils/log.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/rain_nowcast_line.dart';

enum _Coach { idle, asking, done, failed }

/// Opened from the evening reminder. One proposal for the missed workout,
/// shown as the next days before and after, and one button to apply it.
/// Other choices are small links underneath.
class MissedWorkoutSheet extends ConsumerStatefulWidget {
  const MissedWorkoutSheet({
    super.key,
    required this.day,
    this.intent = MissedWorkoutActionKind.open,
    this.syncFirst = true,
  });
  final DateTime day;
  final MissedWorkoutActionKind intent;

  /// Off in widget tests, which have no accounts to sync.
  final bool syncFirst;

  @override
  ConsumerState<MissedWorkoutSheet> createState() => _MissedWorkoutSheetState();
}

class _MissedWorkoutSheetState extends ConsumerState<MissedWorkoutSheet> {
  List<PlanWeekItem>? _items;

  /// What the athlete picked over the coach or rules proposal.
  RebalanceProposal? _own;
  RebalanceProposal? _coachProposal;
  _Coach _coach = _Coach.idle;
  bool _picking = false, _busy = false;
  late bool _skipping = widget.intent == MissedWorkoutActionKind.skip;
  String? _skipReason;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Syncs first when the last sync is a few minutes old: the reminder may be
  /// about a workout that is done but not imported yet.
  Future<void> _load() async {
    final sync = ref.read(syncProvider);
    final last = sync.lastSync;
    if (widget.syncFirst &&
        sync.status != SyncStatus.syncing &&
        (last == null ||
            DateTime.now().difference(last) > const Duration(minutes: 3))) {
      try {
        await ref
            .read(syncProvider.notifier)
            .sync()
            .timeout(const Duration(seconds: 25));
      } catch (e) {
        log('[MissedWorkout] sync before sheet: $e');
      }
    }
    final items = await ref
        .read(missedWorkoutReminderProvider)
        .openItems(widget.day);
    if (mounted) setState(() => _items = items);
  }

  TrainingSession? get _missed {
    final sessions = [
      for (final i in _items ?? const <PlanWeekItem>[])
        if (i.session != null) i.session!,
    ];
    if (sessions.isEmpty) return null;
    // The hardest one decides; a second easy one rarely matters.
    sessions.sort((a, b) {
      final w = weightOf(b).index.compareTo(weightOf(a).index);
      return w != 0 ? w : b.plannedDurationMin.compareTo(a.plannedDurationMin);
    });
    return sessions.first;
  }

  RebalanceContext _context(TrainingSession missed) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final goals = ref.watch(goalSetProvider).valueOrNull;
    final race = ref.watch(primaryRaceGoalProvider).valueOrNull;
    final weather = ref.watch(heatHourlyWeatherProvider).valueOrNull;
    final settings =
        ref.watch(missedWorkoutSettingsProvider).valueOrNull ??
        const MissedWorkoutSettings();
    final hours = <({DateTime time, double mm, int? probability})>[
      for (final p in weather?.points ?? const <OpenMeteoPoint>[])
        (
          time: p.time,
          mm: p.precipitationMm,
          probability: p.precipitationProbability,
        ),
    ];
    return RebalanceContext(
      missed: missed,
      upcoming:
          ref.watch(upcomingSessionsProvider).valueOrNull ??
          const <TrainingSession>[],
      today: widget.day,
      daysAhead: settings.daysAhead,
      maxPerDay: profile?.maxSessionsPerDay ?? 1,
      restWeekdays: profile?.restDays ?? const [],
      dayLoad: goals?.loadOn,
      rainyOn: hours.isEmpty ? null : (d) => isRainyDay(hours, d),
      raceName: race?.name,
      raceDate: race?.raceDate,
    );
  }

  Future<void> _askCoach(RebalanceContext c) async {
    final settings = ref.read(aiCoachSettingsProvider).valueOrNull;
    if (settings == null || !settings.ready || _coach == _Coach.asking) return;
    setState(() => _coach = _Coach.asking);
    RebalanceProposal? valid;
    try {
      final profile = await ref.read(userProfileProvider.future);
      final toon = await ref
          .read(toonCacheProvider.notifier)
          .getOrBuild(null, profile.raceGoals ?? '', null);
      final reply = await ref
          .read(aiCoachClientProvider)
          .sendPlanning(
            settings,
            rebalanceInstructions(coachLanguageName()),
            rebalanceInputJson(c),
            toon,
            // The tap on "Ask coach" under the provider's name is the
            // consent for this one request.
            AiConsentToken.confirmed(),
          )
          .timeout(planningTimeout);
      final p = parseRebalance(reply);
      final problem = p == null ? 'not JSON' : rebalanceProblem(p, c);
      log('[MissedWorkout] coach proposal ${problem ?? 'ok'}');
      if (problem != null) {
        // The start of the reply says what went wrong; no health data in it.
        log(
          '[MissedWorkout] coach reply: '
          '${reply.length > 300 ? '${reply.substring(0, 300)}…' : reply}',
        );
      }
      if (problem == null) valid = p;
    } catch (e) {
      log('[MissedWorkout] coach: $e');
    }
    if (!mounted) return;
    setState(() {
      _coachProposal = valid;
      _coach = valid == null ? _Coach.failed : _Coach.done;
      if (valid != null) _own = null;
    });
  }

  Future<void> _apply(RebalanceProposal p, TrainingSession missed) async {
    final applier = ref.read(planRebalanceApplierProvider);
    final service = ref.read(missedWorkoutReminderProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final undo = await applier.apply(
        p,
        missedId: missed.id,
        dropReason: _skipReason ?? 'My choice',
      );
      void refresh() {
        ref.invalidate(upcomingSessionsProvider);
        unawaited(service.reconcile());
      }

      refresh();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.planUpdated),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () async {
              await applier.undo(undo);
              refresh();
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _stillToday() async {
    await ref.read(missedWorkoutReminderProvider).acknowledge(widget.day);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = _items;
    return SheetPage(
      title: l10n.openWorkoutToday,
      child: items == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: mint),
                  const SizedBox(height: 14),
                  Text(
                    l10n.checkingForWorkout,
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            )
          : items.isEmpty
          ? _AlreadyDone(onClose: () => Navigator.of(context).pop())
          : _content(context, items),
    );
  }

  Widget _content(BuildContext context, List<PlanWeekItem> items) {
    final l10n = context.l10n;
    final missed = _missed;
    if (missed == null) {
      // Only watch workouts: they cannot be moved from here.
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final i in items) _Hero(item: i),
          // Whether going out now means getting wet.
          const RainNowcastLine(padding: EdgeInsets.only(top: 10)),
          const SizedBox(height: 20),
          _PrimaryButton(label: l10n.stillToday, onPressed: _stillToday),
        ],
      );
    }
    final c = _context(missed);
    final settings = ref.watch(aiCoachSettingsProvider).valueOrNull;
    final coachReady = settings != null && settings.ready;
    final local = coachReady && settings.provider.isLocal;
    // On the device nothing leaves the phone: the coach is asked right away.
    if (local && _coach == _Coach.idle && !_skipping) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_askCoach(c)),
      );
    }
    final proposal = _own ?? _coachProposal ?? rulesRebalance(c);
    final fromCoach = _own == null && _coachProposal != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _Hero(item: items.firstWhere((i) => i.session?.id == missed.id)),
        const RainNowcastLine(padding: EdgeInsets.only(top: 10)),
        const SizedBox(height: 14),
        if (_skipping)
          _SkipCard(
            selected: _skipReason,
            label: (r) => _reasonLabel(context, r),
            onSelect: (r) => setState(() => _skipReason = r),
          )
        else
          _ProposalCard(
            title: fromCoach ? l10n.coachSuggests : l10n.suggestionLabel,
            sparkle: fromCoach,
            summary: fromCoach
                ? proposal.summary ?? _summary(context, proposal, c)
                : _summary(context, proposal, c),
            days: previewRebalance(proposal, c),
            picking: _picking,
            onPickDay: (d) {
              final p = fittingMove(c, d);
              if (p == null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.dayDoesNotFit)));
                return;
              }
              setState(() {
                _own = p;
                _picking = false;
              });
            },
            coach: !coachReady
                ? null
                : _CoachLine(
                    state: _coach,
                    local: local,
                    provider: _providerName(settings.provider),
                    onAsk: () => _askCoach(c),
                  ),
          ),
        if (_picking)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.pickADay,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: mint),
            ),
          ),
        const SizedBox(height: 18),
        _PrimaryButton(
          label: _skipping ? l10n.skip : l10n.apply,
          busy: _busy,
          onPressed: _busy || (_skipping && _skipReason == null)
              ? null
              : () => _apply(_skipping ? dropMissed(c) : proposal, missed),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Action(
              icon: Icons.bolt_rounded,
              label: l10n.stillToday,
              onTap: _busy ? null : _stillToday,
            ),
            if (!_skipping) ...[
              _Action(
                icon: Icons.calendar_month_outlined,
                label: l10n.otherDay,
                active: _picking,
                onTap: _busy
                    ? null
                    : () => setState(() => _picking = !_picking),
              ),
              _Action(
                icon: Icons.remove_circle_outline,
                label: l10n.dropIt,
                onTap: _busy
                    ? null
                    : () => setState(() => _own = dropMissed(c)),
              ),
            ],
            _Action(
              icon: _skipping
                  ? Icons.lightbulb_outline
                  : Icons.bedtime_outlined,
              label: _skipping ? l10n.suggestionLabel : l10n.skipEllipsis,
              onTap: _busy
                  ? null
                  : () => setState(() {
                      _skipping = !_skipping;
                      _picking = false;
                    }),
            ),
          ],
        ),
      ],
    );
  }

  String _summary(
    BuildContext context,
    RebalanceProposal p,
    RebalanceContext c,
  ) {
    final l10n = context.l10n;
    final x = p.changeFor(c.missed.id);
    if (x == null || x.op == RebalanceOp.drop) {
      return weightOf(c.missed) == SessionWeight.easy
          ? l10n.summaryDropEasy
          : l10n.summaryDropNoDay(c.daysAhead);
    }
    final day = DateFormat.EEEE().format(x.to!);
    if (x.intensity != RebalanceIntensity.keep) {
      return l10n.summaryMoveEasier(day);
    }
    return (x.indoor ?? false)
        ? l10n.summaryMoveIndoor(day)
        : l10n.summaryMove(day);
  }

  String _reasonLabel(BuildContext context, String reason) => switch (reason) {
    'Illness' => context.l10n.skipReasonIllness,
    'Injury or pain' => context.l10n.skipReasonInjury,
    'Fatigue' => context.l10n.skipReasonFatigue,
    'No time' => context.l10n.skipReasonNoTime,
    'Travel' => context.l10n.skipReasonTravel,
    'Conditions' => context.l10n.skipReasonConditions,
    'My choice' => context.l10n.skipReasonMyChoice,
    _ => reason,
  };

  static String _providerName(AiProvider p) => switch (p) {
    AiProvider.mistral => 'Mistral',
    AiProvider.openai => 'OpenAI',
    AiProvider.anthropic => 'Anthropic',
    AiProvider.gemini => 'Gemini',
    AiProvider.deepseek => 'DeepSeek',
    AiProvider.appleIntelligence => 'Apple Intelligence',
    AiProvider.localQwen => 'Qwen',
    AiProvider.freeAi => 'Free AI',
  };
}

/// The missed workout, large, in its sport's colour.
class _Hero extends StatelessWidget {
  const _Hero({required this.item});
  final PlanWeekItem item;

  @override
  Widget build(BuildContext context) {
    final color = completedActivityColor(item.plannedSport);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: .22), color.withValues(alpha: .05)],
        ),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              activitySportIcon(item.plannedSport),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.plannedTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    // Plan titles often carry the minutes already.
                    if (item.plannedMinutes != null &&
                        !item.plannedTitle.contains('${item.plannedMinutes}'))
                      planDuration(item.plannedMinutes!),
                    context.l10n.missedTodayTag,
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.title,
    required this.sparkle,
    required this.summary,
    required this.days,
    required this.picking,
    required this.onPickDay,
    this.coach,
  });
  final String title, summary;
  final bool sparkle, picking;
  final List<PreviewDay> days;
  final ValueChanged<DateTime> onPickDay;
  final Widget? coach;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .04),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              sparkle ? Icons.auto_awesome : Icons.lightbulb_outline,
              size: 16,
              color: sparkle ? mint : muted,
            ),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: sparkle ? mint : muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            summary,
            key: ValueKey(summary),
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
        ),
        const SizedBox(height: 14),
        _WeekStrip(days: days, picking: picking, onPickDay: onPickDay),
        if (coach != null) ...[const SizedBox(height: 14), coach!],
      ],
    ),
  );
}

class _CoachLine extends StatefulWidget {
  const _CoachLine({
    required this.state,
    required this.local,
    required this.provider,
    required this.onAsk,
  });
  final _Coach state;
  final bool local;
  final String provider;
  final VoidCallback onAsk;

  @override
  State<_CoachLine> createState() => _CoachLineState();
}

/// A large "Ask coach" button; while the coach works, a running clock, since
/// an answer can take up to three minutes.
class _CoachLineState extends State<_CoachLine> {
  Timer? _tick;
  final _watch = Stopwatch();

  @override
  void didUpdateWidget(covariant _CoachLine old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    if (widget.state == _Coach.asking && _tick == null) {
      _watch
        ..reset()
        ..start();
      _tick = Timer.periodic(
        const Duration(seconds: 1),
        (_) => mounted ? setState(() {}) : null,
      );
    } else if (widget.state != _Coach.asking && _tick != null) {
      _tick!.cancel();
      _tick = null;
      _watch.stop();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.state == _Coach.done ||
        (widget.local && widget.state == _Coach.idle)) {
      return const SizedBox.shrink();
    }
    final asking = widget.state == _Coach.asking;
    final s = _watch.elapsed.inSeconds;
    final clock = '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: asking ? null : widget.onAsk,
            style: OutlinedButton.styleFrom(
              foregroundColor: mint,
              disabledForegroundColor: mint,
              backgroundColor: mint.withValues(alpha: .08),
              side: BorderSide(color: mint.withValues(alpha: .55)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (asking)
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: mint,
                    ),
                  )
                else
                  const Icon(Icons.auto_awesome, size: 20),
                const SizedBox(width: 10),
                Text(
                  asking ? '${l10n.coachThinking}  $clock' : l10n.askCoachShort,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.state == _Coach.failed
              ? l10n.coachCouldNotAnswer
              : l10n.askCoachSends(widget.provider),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: muted),
        ),
      ],
    );
  }
}

/// Today and the next days side by side, each with its sessions after the
/// proposal: what moves in, what gets shorter or easier, what goes.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.picking,
    required this.onPickDay,
  });
  final List<PreviewDay> days;
  final bool picking;
  final ValueChanged<DateTime> onPickDay;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, d) in days.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _DayColumn(
              day: d,
              isToday: i == 0,
              pickable: picking && i > 0,
              onTap: () => onPickDay(d.date),
            ),
          ),
        ],
      ],
    ),
  );
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.isToday,
    required this.pickable,
    required this.onTap,
  });
  final PreviewDay day;
  final bool isToday, pickable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changed = day.items.any(
      (i) => i.kind == PreviewKind.movedIn || i.kind == PreviewKind.adjusted,
    );
    return GestureDetector(
      onTap: pickable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        constraints: const BoxConstraints(minHeight: 96),
        decoration: BoxDecoration(
          color: changed
              ? mint.withValues(alpha: .08)
              : Colors.white.withValues(alpha: .025),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: pickable
                ? mint.withValues(alpha: .7)
                : changed
                ? mint.withValues(alpha: .4)
                : Colors.transparent,
            width: pickable ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              DateFormat.E().format(day.date),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isToday ? Colors.white54 : Colors.white,
              ),
            ),
            Text(
              '${day.date.day}',
              style: const TextStyle(fontSize: 10, color: muted),
            ),
            const SizedBox(height: 6),
            if (day.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('–', style: TextStyle(color: Colors.white24)),
              ),
            for (final item in day.items) _Chip(item: item),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.item});
  final PreviewItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gone =
        item.kind == PreviewKind.missed || item.kind == PreviewKind.dropped;
    final fresh = item.kind == PreviewKind.movedIn;
    final changed = item.kind == PreviewKind.adjusted;
    final color = gone
        ? Colors.white30
        : completedActivityColor(item.session.sport);
    final minutes = item.minutesBefore == null
        ? '${item.minutes}′'
        : '${item.minutesBefore}→${item.minutes}′';
    final tags = [
      if (item.indoor && (fresh || changed)) l10n.tagIndoor,
      if (item.intensity == RebalanceIntensity.easier) l10n.tagEasier,
      if (item.intensity == RebalanceIntensity.recovery) l10n.tagRecovery,
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        color: fresh
            ? mint.withValues(alpha: .18)
            : changed
            ? Colors.amber.withValues(alpha: .14)
            : Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            item.indoor && !gone
                ? Icons.home_outlined
                : activitySportIcon(item.session.sport),
            size: 15,
            color: fresh ? mint : color,
          ),
          Text(
            (fresh ? '+' : '') + minutes,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fresh
                  ? mint
                  : changed
                  ? Colors.amber
                  : gone
                  ? Colors.white30
                  : Colors.white70,
              decoration: gone ? TextDecoration.lineThrough : null,
              decorationColor: Colors.white30,
            ),
          ),
          for (final t in tags)
            Text(
              t,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: 8.5,
                color: fresh ? mint : Colors.amber,
              ),
            ),
        ],
      ),
    );
  }
}

class _SkipCard extends StatelessWidget {
  const _SkipCard({
    required this.selected,
    required this.label,
    required this.onSelect,
  });
  final String? selected;
  final String Function(String reason) label;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .04),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.whySkip,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final reason in skipReasons)
              ChoiceChip(
                label: Text(label(reason)),
                selected: selected == reason,
                showCheckmark: false,
                selectedColor: mint.withValues(alpha: .25),
                onSelected: (_) => onSelect(reason),
              ),
          ],
        ),
      ],
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: mint,
      foregroundColor: const Color(0xFF062A20),
      disabledBackgroundColor: mint.withValues(alpha: .3),
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
  );
}

/// A small secondary choice under the main button: icon above a label.
class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? mint : Colors.white70;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? mint.withValues(alpha: .16)
                      : Colors.white.withValues(alpha: .06),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: 11, color: color, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlreadyDone extends StatelessWidget {
  const _AlreadyDone({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mint.withValues(alpha: .14),
          ),
          child: const Icon(Icons.check_rounded, size: 40, color: mint),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.alreadyDone,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.alreadyDoneBody,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(label: context.l10n.done, onPressed: onClose),
      ],
    ),
  );
}
