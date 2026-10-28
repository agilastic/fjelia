import '../../l10n/l10n_ext.dart';
import '../../providers/activity_history_provider.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../db/database.dart';
import '../../models/strength_workout.dart';
import '../../services/activity_decoder.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/activity_performance_chart.dart';
import '../../widgets/activity_route_map.dart';
import '../../widgets/activity_heat_card.dart';
import '../../widgets/workout_hrv_card.dart';
import '../../widgets/nutrition_widgets.dart';
import '../planner/plan_overview_cards.dart';
import '../strength/strength_sections.dart';
import '../activities/activities_screen.dart';
import '../../models/coach_context_card.dart';
import '../ai_coach/ai_coach_screen.dart';

class ActivityDetailSheet extends ConsumerWidget {
  const ActivityDetailSheet({super.key, required this.activity});
  final ActivityRecord activity;
  String duration(Duration? d) => d == null
      ? '—'
      : d.inHours > 0
      ? '${d.inHours}h ${d.inMinutes % 60}m${d.inSeconds % 60 == 0 ? '' : ' ${d.inSeconds % 60}s'}'
      : '${d.inMinutes}m ${d.inSeconds % 60}s';
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = decodeActivityRecord(activity);
    // Strength is chosen before any endurance metric is built: no distance,
    // pace, elevation or route for a lifting session.
    final strength = isStrengthSport(a.type);
    final running = a.type.toLowerCase().contains('run');
    final km = (a.distanceMeters ?? 0) / 1000;
    final pace = km > 0 ? a.duration.inSeconds / km : null;
    final cells = <(String, String)>[
      if (strength) ...[
        (context.l10n.duration, duration(a.duration)),
        if (a.avgHeartRate != null)
          (context.l10n.avgHr, '${valueText(a.avgHeartRate)} bpm'),
        if (a.maxHeartRate != null)
          (context.l10n.maxHr, '${valueText(a.maxHeartRate)} bpm'),
        (context.l10n.trainingLoad2, valueText(activityLoad(activity), 1)),
      ] else ...[
        (context.l10n.duration, duration(a.duration)),
        (
          context.l10n.active,
          '${a.movingDuration != null && activity.movingDurationSeconds == null ? '~' : ''}${duration(a.movingDuration)}',
        ),
        (
          context.l10n.distance,
          '${valueText(a.distanceMeters == null ? null : km, 2)} km',
        ),
        (
          running ? context.l10n.avgPace : context.l10n.avgSpeed,
          running
              ? pace == null
                    ? '—'
                    : '${pace.round() ~/ 60}:${(pace.round() % 60).toString().padLeft(2, '0')} /km'
              : '${valueText(a.duration.inSeconds > 0 && km > 0 ? km * 3600 / a.duration.inSeconds : null, 1)} km/h',
        ),
        (context.l10n.avgHr, '${valueText(a.avgHeartRate)} bpm'),
        (context.l10n.maxHr, '${valueText(a.maxHeartRate)} bpm'),
        (context.l10n.trainingLoad2, valueText(activityLoad(activity), 1)),
        if (a.avgPower != null)
          (context.l10n.avgPower, '${valueText(a.avgPower)} W'),
        (context.l10n.elevation2, '${valueText(a.elevationGain)} m'),
        if (a.samples.any((s) => s.elevation != null))
          (
            context.l10n.altitude,
            '${valueText(a.samples.map((s) => s.elevation).whereType<double>().reduce((a, b) => a < b ? a : b))}–${valueText(a.samples.map((s) => s.elevation).whereType<double>().reduce((a, b) => a > b ? a : b))} m',
          ),
      ],
    ];
    final route = strength
        ? const <geo.LatLng>[]
        : [for (final p in a.route) geo.LatLng(p.lat, p.lng)];
    return SheetPage(
      title: a.name,
      showHeader: false,
      backgroundColor: panel,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7).withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  workoutSportIcon(a.type),
                  color: const Color(0xFF4FC3F7),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${a.type.replaceAll('_', ' ')} · ${DateFormat.MMMd().add_Hm().format(a.startTime)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.close,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white70, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final c in cells)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _cellIcon(context, c.$1),
                        size: 18,
                        color: _cellColor(context, c.$1),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: StatPair(c.$1, c.$2),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (strength) CompletedStrengthSection(activity: activity),
          ActivityNutritionCard(activity: activity),
          ActivityHeatCard(activityId: a.id),
          if (route.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: Text(
                context.l10n.route,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
            ActivityRouteMap(
              route: route,
              exportGpx: (buttonContext) async {
                final file = File(
                  '${(await getTemporaryDirectory()).path}/activity-${a.startTime.millisecondsSinceEpoch}.gpx',
                );
                await file.writeAsString(
                  '<?xml version="1.0" encoding="UTF-8"?><gpx version="1.1" creator="Fjelia" xmlns="http://www.topografix.com/GPX/1/1"><trk><trkseg>${a.route.map((p) => '<trkpt lat="${p.lat}" lon="${p.lng}"/>').join()}</trkseg></trk></gpx>',
                );
                if (!buttonContext.mounted) return;
                final box = buttonContext.findRenderObject() as RenderBox?;
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(file.path)],
                    sharePositionOrigin: box == null
                        ? null
                        : box.localToGlobal(Offset.zero) & box.size,
                  ),
                );
              },
            ),
          ],
          if (a.samples.isNotEmpty && !strength)
            ActivityPerformanceChart(activity: a),
          if (a.hrZoneSeconds.isNotEmpty) ActivityZoneChart(activity: a),
          WorkoutHrvCard(
            activityId: activity.activityId,
            onExplain: () => openCoachTab(
              context,
              prompt: context.l10n.explainMyHrvBeforeAnd,
              activity: activity,
              card: CoachContextCard.completed(a),
            ),
          ),
          if (a.activityFeedbackPhrase != null)
            SectionCard(
              title: context.l10n.feedback,
              child: Text(a.activityFeedbackPhrase!),
            ),
          if (a.plannedWorkoutName != null)
            SectionCard(
              title: context.l10n.plannedWorkout,
              child: Text(a.plannedWorkoutName!),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: .5),
                    ),
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(context.l10n.delete),
                  onPressed: () async {
                    if (!await confirmAction(
                      context,
                      context.l10n.deleteActivity,
                      context.l10n.removeThisActivityFromThe,
                    )) {
                      return;
                    }
                    if (!context.mounted) return;
                    await runUiAction(context, () async {
                      await ref.read(deleteActivityProvider)(a.id);
                      if (context.mounted) Navigator.pop(context);
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mint,
                    side: const BorderSide(color: mint),
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(context.l10n.chatAi),
                  onPressed: () => openCoachTab(
                    context,
                    prompt: context.l10n.howDidThisSessionGo,
                    activity: activity,
                    card: CoachContextCard.completed(a),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// The cell labels are translated, so the icons and colours are matched
// against the translated text rather than English literals.
IconData _cellIcon(BuildContext context, String label) {
  final l = context.l10n;
  if (label == l.duration) return Icons.timer_outlined;
  if (label == l.active) return Icons.directions_run;
  if (label == l.distance) return Icons.straighten;
  if (label == l.avgHr) return Icons.favorite_border;
  if (label == l.maxHr) return Icons.favorite;
  if (label == l.trainingLoad2 || label == l.avgPower) return Icons.bolt;
  if (label == l.elevation2) return Icons.terrain;
  if (label == l.altitude) return Icons.height;
  return Icons.speed;
}

Color _cellColor(BuildContext context, String label) {
  final l = context.l10n;
  if (label == l.avgHr || label == l.maxHr) return Colors.redAccent;
  if (label == l.elevation2 || label == l.altitude) return mint;
  if (label == l.trainingLoad2) return const Color(0xFF4FC3F7);
  return Colors.white70;
}
