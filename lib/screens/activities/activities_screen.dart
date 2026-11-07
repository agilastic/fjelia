import '../ai_coach/ai_coach_screen.dart' show openCoachTab;
import '../../services/activity_decoder.dart';
import '../../models/coach_context_card.dart';
import '../../widgets/recently_deleted_sheet.dart';
import '../../widgets/swipe_action_tile.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_ext.dart';
import '../../theme/activity_colors.dart'
    show completedActivityColor, activitySportIcon;
import '../../providers/activity_history_provider.dart';
import '../../providers/ecg_provider.dart';
import '../../widgets/ecg_sheet.dart' show EcgHistoryTile;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../providers/training_load_provider.dart';
import '../../providers/day_data_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/plan_timeline.dart';
import '../strain/activity_detail_sheet.dart';
import '../../utils/week.dart';
import '../../providers/week_start_provider.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SheetPage(
    title: context.l10n.activityLog,
    child: SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: ActivityHistory(),
    ),
  );
}

class ActivityHistory extends ConsumerStatefulWidget {
  const ActivityHistory({
    super.key,
    this.showHeader = true,
    this.monthMode,
    this.selectedDayOnly = false,
    this.rollingDays,
  });
  final bool showHeader;
  final bool selectedDayOnly;
  final bool? monthMode;

  /// Shows the last [rollingDays] days up to and including the selected day
  /// instead of a calendar month or week, so the list never empties out on
  /// the 1st of a month.
  final int? rollingDays;
  @override
  ConsumerState<ActivityHistory> createState() => _HistoryState();
}

class _HistoryState extends ConsumerState<ActivityHistory> {
  bool month = true;

  /// The rows last shown, kept while older ones load, so the list stays.
  List<ActivityRecord>? _last;

  /// The first card wiggles once ever, to show that cards can be swiped.
  bool _peek = false;
  static const _peekKey = 'history_swipe_hint_v1';

  @override
  void initState() {
    super.initState();
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool(_peekKey) ?? false) return;
        await prefs.setBool(_peekKey, true);
        if (mounted) setState(() => _peek = true);
      } catch (_) {}
    }();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final monthFilter = widget.monthMode ?? month;
    final rolling = widget.rollingDays;
    // The Plan list grows into the past as it is scrolled.
    final int extra = rolling == null ? 0 : ref.watch(historyExtraDaysProvider);
    final start = rolling != null
        ? DateTime(
            selected.year,
            selected.month,
            selected.day - rolling - extra + 1,
          )
        : monthFilter
        ? DateTime(selected.year, selected.month)
        : weekStartOf(
            selected,
            mondayFirst: ref.watch(weekStartsOnMondayProvider),
          );
    final end = rolling != null
        ? DateTime(selected.year, selected.month, selected.day + 1)
        : monthFilter
        ? DateTime(selected.year, selected.month + 1)
        : start.add(const Duration(days: 7));
    if (rolling != null && ref.read(historyWindowStartProvider) != start) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(historyWindowStartProvider.notifier).state = start;
        }
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          Row(
            children: [
              Expanded(child: SectionLabel(context.l10n.activityLog2)),
              TextButton(
                onPressed: () => setState(() => month = !month),
                child: Text(month ? context.l10n.month2 : context.l10n.week2),
              ),
            ],
          ),
        _source(rolling, selected).when(
          loading: () => _last == null
              ? const LinearProgressIndicator()
              : _list(context, _last!, start, end, selected, loading: true),
          error: (e, _) =>
              DataError(e, retry: () => ref.invalidate(loadActivitiesProvider)),
          data: (rows) {
            if (rolling != null) _last = rows;
            return _list(context, rows, start, end, selected);
          },
        ),
      ],
    );
  }

  /// The rolling list (Plan) reads as far back as it was scrolled; the
  /// other views stay within the year the rest of the app loads.
  AsyncValue<List<ActivityRecord>> _source(int? rolling, DateTime selected) {
    if (rolling == null) return ref.watch(loadActivitiesProvider);
    final int back = DateTime.now()
        .difference(selected)
        .inDays
        .clamp(0, 36500)
        .toInt();
    final int extra = ref.watch(historyExtraDaysProvider);
    return ref.watch(historyActivitiesProvider(rolling + extra + back + 1));
  }

  Widget _list(
    BuildContext context,
    List<ActivityRecord> rows,
    DateTime start,
    DateTime end,
    DateTime selected, {
    bool loading = false,
  }) {
    {
      {
        bool inView(DateTime at) => widget.selectedDayOnly
            ? DateUtils.isSameDay(at, selected)
            : !at.isBefore(start) && at.isBefore(end);
        // Recordings of their own sit between the activities; those taken
        // during an activity show in its details instead.
        final deleting = ref.watch(pendingEcgDeletesProvider);
        final filtered = <(DateTime, Object)>[
          for (final a in rows)
            if (inView(a.startDate)) (a.startDate, a),
          for (final e
              in ref.watch(ecgHistoryProvider).valueOrNull ??
                  const <EcgRecording>[])
            if (e.activityId == null &&
                e.status != 'recording' &&
                !deleting.contains(e.recordingId) &&
                inView(e.recordedAt.toLocal()))
              (e.recordedAt.toLocal(), e),
        ]..sort((a, b) => b.$1.compareTo(a.$1));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: TimelineSectionHeader(
                label: context.l10n.history2,
                icon: Icons.bolt_rounded,
                colors: doneGradient,
              ),
            ),
            if (filtered.isEmpty)
              EmptyState(context.l10n.noActivitiesInThisPeriod),
            for (var i = 0; i < filtered.length; i++) ...[
              if (i == 0 ||
                  !DateUtils.isSameDay(filtered[i].$1, filtered[i - 1].$1))
                TimelineDayLabel(
                  dayHeading(context, filtered[i].$1),
                  future: false,
                ),
              switch (filtered[i].$2) {
                final ActivityRecord a => _ActivityHistoryTile(
                  key: ValueKey(a.activityId),
                  activity: a,
                  peek: i == 0 && _peek,
                ),
                final EcgRecording e => EcgHistoryTile(
                  key: ValueKey(e.recordingId),
                  recording: e,
                ),
                _ => const SizedBox.shrink(),
              },
            ],
            if (widget.rollingDays != null)
              _OlderActivities(start: start, loading: loading),
          ],
        );
      }
    }
  }
}

/// The end of the Plan list: older activities load when it comes into
/// view, or with the button; at the oldest one it says so.
class _OlderActivities extends ConsumerStatefulWidget {
  const _OlderActivities({required this.start, required this.loading});
  final DateTime start;
  final bool loading;
  @override
  ConsumerState<_OlderActivities> createState() => _OlderState();
}

class _OlderState extends ConsumerState<_OlderActivities> {
  bool get _complete {
    final oldest = ref.read(oldestActivityProvider).valueOrNull;
    return oldest == null || !oldest.isBefore(widget.start);
  }

  void _more() {
    if (widget.loading || _complete) return;
    requestOlderActivities(ref, scrolled: false);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(oldestActivityProvider);
    if (widget.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_complete) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            context.l10n.noOlderActivities,
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ),
      );
    }
    return Center(
      child: TextButton.icon(
        onPressed: _more,
        icon: const Icon(Icons.expand_more),
        label: Text(context.l10n.loadOlderActivities),
      ),
    );
  }
}

/// One past activity. Swiped left it is deleted (with undo), swiped right
/// the coach is asked about it.
class _ActivityHistoryTile extends StatelessWidget {
  const _ActivityHistoryTile({
    super.key,
    required this.activity,
    this.peek = false,
  });
  final ActivityRecord activity;
  final bool peek;
  @override
  Widget build(BuildContext context) {
    final a = activity;
    return SwipeActionTile(
      peek: peek,
      deleteLabel: context.l10n.delete,
      coachLabel: context.l10n.askCoachShort,
      onDelete: () => deleteActivityWithUndo(context, a),
      onCoach: () => openCoachTab(
        context,
        prompt: context.l10n.howDidThisSessionGo,
        activity: a,
        card: CoachContextCard.completed(decodeActivityRecord(a)),
      ),
      child: _card(context, a),
    );
  }

  /// Done is solid: a card washed in the sport's colour with a bar on its
  /// edge and a filled icon, unlike the dashed outline of what is planned.
  Widget _card(BuildContext context, ActivityRecord a) {
    final color = completedActivityColor(a.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .45)),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .22), panel, panel],
          stops: const [0, .55, 1],
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .12), blurRadius: 10),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(child: _tile(context, a, color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, ActivityRecord a, Color color) => ListTile(
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
    leading: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .5), blurRadius: 8),
        ],
      ),
      child: Icon(activitySportIcon(a.type), size: 19, color: Colors.black87),
    ),
    title: Text(
      a.name,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      context.l10n
          .durationsecondshDurationseconds2mDistancemetersKmAvgheartrate(
            a.durationSeconds ~/ 3600,
            a.durationSeconds ~/ 60 % 60,
            valueText(
              a.distanceMeters == null ? null : a.distanceMeters! / 1000,
              1,
            ),
            valueText(a.avgHeartRate),
            valueText(a.totalElevation),
          ),
      style: const TextStyle(fontSize: 10, color: Colors.white70),
    ),
    trailing: Icon(Icons.check_circle_rounded, size: 20, color: color),
    onTap: () => showAppSheet(context, ActivityDetailSheet(activity: a)),
  );
}

double activityLoad(ActivityRecord a) {
  try {
    return effectiveLoad(a);
  } on FormatException {
    return a.trainingLoad ?? 0;
  } on TypeError {
    return a.trainingLoad ?? 0;
  }
}
