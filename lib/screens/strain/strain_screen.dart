import '../../l10n/l10n_ext.dart';
import '../../l10n/formats.dart';
import '../../providers/activity_history_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/training_load_provider.dart';

import '../../providers/day_data_provider.dart';
import '../../providers/visibility_provider.dart';
import '../../providers/heat_acclimation_provider.dart';
import '../../widgets/app_widgets.dart';
import '../activities/weekly_load_card.dart';
import '../activities/training_monitor_card.dart';
import '../activities/training_form_card.dart';
import '../activities/load_history_cards.dart';
import '../activities/heat_weather_sheet.dart';
import '../activities/load_visuals.dart';
import '../activities/load_optional_cards.dart';
import '../settings/training_tab.dart';

class StrainScreen extends ConsumerWidget {
  const StrainScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(loadActivitiesProvider),
        vis = ref.watch(loadVisibilityProvider).valueOrNull ?? {};
    final date = ref.watch(selectedDateProvider);
    final monitor = ref.watch(trainingMonitorProvider(date)).valueOrNull;
    final heatState = ref.watch(heatTodayStateProvider);
    final heat = heatState.valueOrNull;
    final heatEnabled =
        ref.watch(heatAcclimationSettingsProvider).valueOrNull?.enabled ??
        false;
    final location = heat == null
        ? null
        : ref.watch(heatPreferredLocationProvider).valueOrNull;
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (rows.isLoading) const LinearProgressIndicator(),
        if (rows.hasError)
          DataError(
            rows.error!,
            retry: () => ref.invalidate(loadActivitiesProvider),
          ),
        if (vis['heat_acclimation'] ?? true)
          LoadCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: InkWell(
              onTap: () => heatEnabled || heat != null
                  ? showLoadSheet(context, HeatWeatherSheet(), height: .82)
                  : showAppSheet(context, TrainingTab()),
              child: Row(
                children: [
                  Text(
                    heat == null ? '—' : '${valueText(heat.score)}%',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.heatAcclimation2,
                          style: TextStyle(
                            fontSize: 11,
                            color: muted,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          location != null
                              ? context.l10n.currentFixedFixed2(
                                  location.latitude.fixed(4),
                                  location.longitude.fixed(4),
                                )
                              : !heatEnabled
                              ? context.l10n.setUpInTrainingSettings
                              : heatState.hasError
                              ? context.l10n.couldNotLoadHeatData
                              : heatState.isLoading
                              ? context.l10n.loadingHeatHistory
                              : context.l10n.noHeatDataYet,
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: muted, size: 20),
                ],
              ),
            ),
          ),
        if (vis['day_load'] ?? true)
          DayTrainingLoadCard(
            load: monitor?.dayLoad,
            low: monitor?.optimalLow,
            high: monitor?.optimalHigh,
          ),
        if ((vis['day_load'] ?? true) && (vis['weekly_load'] ?? true))
          SizedBox(height: 12),
        if (vis['weekday_load'] ?? true) const WeekdayLoadCard(),
        if (vis['weekly_load'] ?? true) const WeeklyLoadCard(),
        if (vis['zone_polarization'] ?? true)
          const LoadHistoryCards(polarization: true),
        if (vis['elevation'] ?? true)
          const LoadHistoryCards(polarization: false),
        if (vis['strain'] ?? true) const TrainingMonitorCard(),
        if (vis['form'] ?? true) const TrainingFormCard(),
        if (vis['plan_banner'] ?? true) const TrainingPlanProgressCard(),
      ],
    );
    return embedded
        ? content
        : SheetPage(title: context.l10n.trainingLoad, child: content);
  }
}

class DayTrainingLoadCard extends StatelessWidget {
  const DayTrainingLoadCard({super.key, this.load, this.low, this.high});
  final double? load, low, high;
  @override
  Widget build(BuildContext context) {
    final value = load ?? 0;
    final hasTarget =
        low != null &&
        high != null &&
        low!.isFinite &&
        high!.isFinite &&
        high! > low! &&
        high! >= 1;
    final scale = trainingLoadScale(value, hasTarget ? high : null);
    final status = !hasTarget
        ? context.l10n.noTarget
        : value < low!
        ? context.l10n.rest
        : value > high!
        ? context.l10n.high2
        : context.l10n.optimal2;
    final tint = status == 'OPTIMAL'
        ? mint
        : status == 'HIGH'
        ? Colors.orange
        : const Color(0xFFCCCCCC);
    return LoadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.dayTrainingLoad2,
                  style: TextStyle(
                    fontSize: 11,
                    color: muted,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: tint,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valueText(load),
                style: TextStyle(
                  fontSize: 32,
                  color: tint,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  context.l10n.trimp,
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ),
              const Spacer(),
              if (hasTarget)
                LoadBadge(
                  context.l10n.optimalLowHigh(valueText(low), valueText(high)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, box) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(color: Colors.white10),
                    if (hasTarget)
                      Positioned(
                        left: (low! / scale).clamp(0, 1) * box.maxWidth,
                        width:
                            ((high! - low!).clamp(0, scale) /
                                    scale *
                                    box.maxWidth)
                                .clamp(
                                  0,
                                  box.maxWidth -
                                      (low! / scale).clamp(0, 1) * box.maxWidth,
                                ),
                        top: 0,
                        bottom: 0,
                        child: Container(color: mint.withValues(alpha: .25)),
                      ),
                    FractionallySizedBox(
                      widthFactor: (value / scale).clamp(0, 1),
                      child: Container(color: tint),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 12, color: muted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  hasTarget
                      ? context.l10n.optimalLowHighTrimp(
                          valueText(low),
                          valueText(high),
                        )
                      : context.l10n.targetUnavailableSyncTrainingHistory,
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
