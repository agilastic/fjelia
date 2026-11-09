import '../activities/sport_stats_card.dart';
import '../../theme/fjelia_style.dart';
import '../../l10n/l10n_ext.dart';
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
        // Heat and the day's load side by side, each a small card.
        Builder(
          builder: (context) {
            final cards = <Widget>[
              if (vis['heat_acclimation'] ?? true)
                SectionCard(
                  title: context.l10n.heatShort,
                  accent: const [Color(0xFFFF8A4D), Color(0xFFFF5A7A)],
                  padding: const EdgeInsets.all(14),
                  onTap: () => heatEnabled || heat != null
                      ? showLoadSheet(context, HeatWeatherSheet(), height: .82)
                      : showAppSheet(context, TrainingTab()),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KeyFigure(
                          heat == null ? '—' : valueText(heat.score * t),
                          unit: heat == null ? null : '%',
                          size: 30,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          !heatEnabled
                              ? context.l10n.setUpInTrainingSettings
                              : heatState.hasError
                              ? context.l10n.couldNotLoadHeatData
                              : heatState.isLoading
                              ? context.l10n.loadingHeatHistory
                              : heat == null
                              ? context.l10n.noHeatDataYet
                              : context.l10n.heatAcclimation,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: muted),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ((heat?.score ?? 0) / 100 * t).clamp(0, 1),
                            minHeight: 6,
                            color: fjAccent(const Color(0xFFFF8A4D)),
                            backgroundColor: fjInk10,
                          ),
                        ),
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
            ];
            if (cards.length < 2) return Column(children: cards);
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              ),
            );
          },
        ),
        if (vis['weekday_load'] ?? true) const WeekdayLoadCard(),
        if (vis['weekly_load'] ?? true) const WeeklyLoadCard(),
        if (vis['sport_stats'] ?? true) const SportStatsCard(),
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
    final tint = !hasTarget
        ? muted
        : value < low!
        ? const Color(0xFF6FA8FF)
        : value > high!
        ? const Color(0xFFFFB13D)
        : mint;
    return SectionCard(
      title: context.l10n.dayTrainingLoad2,
      accent: const [Color(0xFFFFB13D), Color(0xFFFF4D8D)],
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The figure counts up and the bar fills when the card appears.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyFigure(
                  load == null ? '—' : valueText(value * t),
                  unit: context.l10n.trimp,
                  size: 30,
                ),
                const SizedBox(height: 6),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: fjAccent(tint),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 6,
                  child: LayoutBuilder(
                    builder: (context, box) => ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(color: fjInk10),
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
                                            (low! / scale).clamp(0, 1) *
                                                box.maxWidth,
                                      ),
                              top: 0,
                              bottom: 0,
                              child: Container(
                                color: mint.withValues(alpha: .25),
                              ),
                            ),
                          FractionallySizedBox(
                            widthFactor: (value / scale * t).clamp(0, 1),
                            child: Container(color: tint),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasTarget
                ? context.l10n.optimalLowHigh(valueText(low), valueText(high))
                : context.l10n.noTarget,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: muted),
          ),
        ],
      ),
    );
  }
}
