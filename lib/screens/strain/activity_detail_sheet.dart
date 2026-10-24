import '../../providers/activity_history_provider.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../db/database.dart';
import '../../services/activity_decoder.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/activity_performance_chart.dart';
import '../../widgets/activity_route_map.dart';
import '../../widgets/activity_heat_card.dart';
import '../planner/plan_overview_cards.dart';
import '../activities/activities_screen.dart';
import '../ai_coach/ai_coach_screen.dart';

class ActivityDetailSheet extends ConsumerWidget {
  const ActivityDetailSheet({super.key, required this.activity});
  final ActivityRecord activity;
  String duration(Duration? d) => d == null
      ? '—'
      : d.inHours > 0
      ? '${d.inHours}h ${d.inMinutes % 60}m'
      : '${d.inMinutes}m ${d.inSeconds % 60}s';
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = decodeActivityRecord(activity);
    final running = a.type.toLowerCase().contains('run');
    final km = (a.distanceMeters ?? 0) / 1000;
    final pace = km > 0 ? a.duration.inSeconds / km : null;
    final cells = <(String, String)>[
      ('Duration', duration(a.duration)),
      ('Active', duration(a.movingDuration)),
      ('Distance', '${valueText(a.distanceMeters == null ? null : km, 2)} km'),
      (
        running ? 'Avg pace' : 'Avg speed',
        running
            ? pace == null
                  ? '—'
                  : '${pace ~/ 60}:${(pace % 60).floor().toString().padLeft(2, '0')} /km'
            : '${valueText(a.duration.inSeconds > 0 && km > 0 ? km * 3600 / a.duration.inSeconds : null, 1)} km/h',
      ),
      ('Avg HR', '${valueText(a.avgHeartRate)} bpm'),
      ('Max HR', '${valueText(a.maxHeartRate)} bpm'),
      ('Training load', valueText(activityLoad(activity), 1)),
      if (a.avgPower != null) ('Avg power', '${valueText(a.avgPower)} W'),
      ('Elevation', '${valueText(a.elevationGain)} m'),
      if (a.samples.any((s) => s.elevation != null))
        (
          'Altitude',
          '${valueText(a.samples.map((s) => s.elevation).whereType<double>().reduce((a, b) => a < b ? a : b))}–${valueText(a.samples.map((s) => s.elevation).whereType<double>().reduce((a, b) => a > b ? a : b))} m',
        ),
    ];
    final route = [for (final p in a.route) geo.LatLng(p.lat, p.lng)];
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
                      '${a.type.replaceAll('_', ' ')} · ${DateFormat('d MMM · HH:mm').format(a.startTime)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
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
                        switch (c.$1) {
                          'Duration' => Icons.timer_outlined,
                          'Active' => Icons.directions_run,
                          'Distance' => Icons.straighten,
                          'Avg HR' => Icons.favorite_border,
                          'Max HR' => Icons.favorite,
                          'Training load' || 'Avg power' => Icons.bolt,
                          'Elevation' => Icons.terrain,
                          'Altitude' => Icons.height,
                          _ => Icons.speed,
                        },
                        size: 18,
                        color: c.$1.contains('HR')
                            ? Colors.redAccent
                            : c.$1 == 'Elevation' || c.$1 == 'Altitude'
                            ? mint
                            : c.$1 == 'Training load'
                            ? const Color(0xFF4FC3F7)
                            : Colors.white70,
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
          ActivityHeatCard(activityId: a.id),
          if (route.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: Text(
                'ROUTE',
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
          if (a.samples.isNotEmpty) ActivityPerformanceChart(activity: a),
          if (a.hrZoneSeconds.isNotEmpty) ActivityZoneChart(activity: a),
          if (a.activityFeedbackPhrase != null)
            SectionCard(
              title: 'Feedback',
              child: Text(a.activityFeedbackPhrase!),
            ),
          if (a.plannedWorkoutName != null)
            SectionCard(
              title: 'Planned Workout',
              child: Text(a.plannedWorkoutName!),
            ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: BorderSide(color: Colors.redAccent.withValues(alpha: .5)),
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete activity'),
            onPressed: () async {
              if (!await confirmAction(
                context,
                'Delete activity?',
                'Remove this activity from the local history? A later provider sync may import it again.',
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
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: mint,
              side: const BorderSide(color: mint),
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Chat with AI about this activity'),
            onPressed: () {
              final prompt = [
                'Coach me on this activity: intensity, pacing and recovery needs, and how it fits my last 30 days and this year\'s progression. What should I improve?',
                '',
                'Activity: ${a.name}',
                'Sport: ${a.type.replaceAll('_', ' ')}',
                'Started: ${DateFormat('yyyy-MM-dd HH:mm').format(a.startTime)}',
                for (final cell in cells) '${cell.$1}: ${cell.$2}',
                if (a.hrZoneSeconds.isNotEmpty)
                  'HR zone percentages: ${a.hrZoneSeconds.entries.map((e) => '${e.key}: ${valueText(e.value, 1)}%').join(', ')}',
              ].join('\n');
              showCoachSheet(
                context,
                title: 'Activity Coach',
                prompt: prompt,
                activity: activity,
              );
            },
          ),
        ],
      ),
    );
  }
}
