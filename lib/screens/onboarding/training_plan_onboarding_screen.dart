import '../../l10n/formats.dart';
import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/planner_providers.dart';
import '../../providers/sync_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/log.dart';
import '../../widgets/history_sync_card.dart';
import '../home/home_screen.dart';
import '../settings/race_goal_editor.dart';
import 'onboarding_widgets.dart';

/// Saves the training preferences consumed by automatic plan generation.
class TrainingPlanOnboardingScreen extends ConsumerStatefulWidget {
  const TrainingPlanOnboardingScreen({super.key});

  @override
  ConsumerState<TrainingPlanOnboardingScreen> createState() =>
      _TrainingPlanOnboardingScreenState();
}

class _TrainingPlanOnboardingScreenState
    extends ConsumerState<TrainingPlanOnboardingScreen> {
  UserProfile? _draft;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The accounts are connected by now: import the history in the
    // background while the questions are answered.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startImport());
  }

  void _startImport() {
    if (!mounted) return;
    ref.read(historyImportStarterProvider)().catchError((Object e) {
      log('[Onboarding] history import failed: $e');
    });
  }

  Future<void> _finish({bool save = true}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (save) {
        _startImport(); // no-op while the import is already running
        final saved = await ref.read(userProfileProvider.future);
        final profile = _draft ?? saved;
        await ref.read(userProfileProvider.notifier).save(profile);
        try {
          final sessions = await ref.read(buildPlanNowProvider)();
          log('[Onboarding] plan built: $sessions sessions');
        } catch (e) {
          // The plan is generated again after the next sync.
          log('[Onboarding] plan generation failed: $e');
        }
      }
      await ref.read(authProvider.notifier).skipGarmin();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = context.l10n.couldNotSavePreferencesE(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final hasHistory = ref.watch(hasHistorySourceProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.trainingPlan),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _finish(save: false),
            child: Text(context.l10n.skip),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(userProfileProvider),
            child: Text(context.l10n.retryLoadingPreferences),
          ),
        ),
        data: (saved) {
          final p = _draft ?? saved;
          void update(UserProfile value) => setState(() {
            _draft = value;
          });
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(context.l10n.tellUsAboutYourRace),
              const SizedBox(height: 24),
              if (_error != null) OnboardingErrorBanner(_error!),
              const HistorySyncCard(),
              OnboardingInputLabel(context.l10n.raceGoal),
              _RaceGoalStep(enabled: !_saving),
              const SizedBox(height: 24),
              if (!hasHistory) ...[
                OnboardingInputLabel(context.l10n.experienceLevel),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    context.l10n.noAccountConnectedSoFjelia,
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final level in [
                      'beginner',
                      'intermediate',
                      'advanced',
                    ])
                      ChoiceChip(
                        label: Text(level),
                        selected: p.experienceLevel == level,
                        onSelected: _saving
                            ? null
                            : (_) => update(p.copyWith(experienceLevel: level)),
                      ),
                  ],
                ),
                SizedBox(height: 24),
              ],
              Text(
                context.l10n.weeklyTrainingTimeTostringasfixedH(
                  p.hoursPerWeek.fixed(1),
                ),
              ),
              Slider(
                value: p.hoursPerWeek.clamp(2, 20),
                min: 2,
                max: 20,
                divisions: 36,
                onChanged: _saving
                    ? null
                    : (v) => update(p.copyWith(hoursPerWeek: v)),
              ),
              SizedBox(height: 16),
              OnboardingInputLabel(context.l10n.weeklySchedule2),
              Text(context.l10n.tapADayToCycle),
              Wrap(
                spacing: 6,
                children: [
                  for (final day
                      in p.weekStartsOnMonday
                          ? [1, 2, 3, 4, 5, 6, 7]
                          : [7, 1, 2, 3, 4, 5, 6])
                    ActionChip(
                      label: Text(
                        '${[context.l10n.mon, context.l10n.tue, context.l10n.wed, context.l10n.thu, context.l10n.fri, context.l10n.sat, context.l10n.sun][day - 1]} '
                        '${p.restDays.contains(day)
                            ? 'Rest'
                            : p.preferredStrengthDays.contains(day)
                            ? 'Strength'
                            : context.l10n.training}',
                      ),
                      onPressed: _saving
                          ? null
                          : () {
                              final rest = p.restDays.toSet();
                              final strength = p.preferredStrengthDays.toSet();
                              if (rest.remove(day)) {
                                strength.add(day);
                              } else if (!strength.remove(day)) {
                                // Keep at least one training day.
                                if (rest.length < 6) rest.add(day);
                              }
                              update(
                                p.copyWith(
                                  restDays: rest.toList()..sort(),
                                  preferredStrengthDays: strength.toList()
                                    ..sort(),
                                  trainingDaysPerWeek: 7 - rest.length,
                                ),
                              );
                            },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              OnboardingInputLabel(context.l10n.sessionsPerDay2),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.doubleDayOk),
                value: p.maxSessionsPerDay == 2,
                onChanged: _saving
                    ? null
                    : (v) => update(p.copyWith(maxSessionsPerDay: v ? 2 : 1)),
              ),
              const SizedBox(height: 16),
              OnboardingInputLabel(context.l10n.aboutYou),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in {
                    'm': context.l10n.male,
                    'f': context.l10n.female,
                    'x': context.l10n.other,
                  }.entries)
                    ChoiceChip(
                      label: Text(option.value),
                      selected: p.sex == option.key,
                      onSelected: _saving
                          ? null
                          : (_) => update(p.copyWith(sex: option.key)),
                    ),
                ],
              ),
              TextFormField(
                initialValue: p.birthYear?.toString(),
                decoration: InputDecoration(
                  labelText: context.l10n.birthYearOptional,
                ),
                keyboardType: TextInputType.number,
                enabled: !_saving,
                onChanged: (value) {
                  final year = int.tryParse(value);
                  if (year != null &&
                      year >= 1900 &&
                      year <= DateTime.now().year) {
                    update(p.copyWith(birthYear: year));
                  }
                },
              ),
              const SizedBox(height: 24),
              OnboardingInputLabel(context.l10n.yourActivities2),
              Wrap(
                spacing: 8,
                children: [
                  for (final sport in {
                    'running': context.l10n.running,
                    'trail_running': context.l10n.trailRunning,
                    'cycling_road': context.l10n.cycling,
                    'swimming': context.l10n.swimming,
                    'triathlon': context.l10n.triathlon,
                    'hiking': context.l10n.hiking,
                    'indoor_rowing': context.l10n.rowing,
                  }.entries)
                    FilterChip(
                      label: Text(sport.value),
                      selected: p.preferredSports.contains(sport.key),
                      onSelected: _saving
                          ? null
                          : (selected) {
                              final sports = p.preferredSports.toSet();
                              if (selected) {
                                sports.add(sport.key);
                              } else if (sports.length > 1) {
                                sports.remove(sport.key);
                              }
                              update(
                                p.copyWith(preferredSports: sports.toList()),
                              );
                            },
                    ),
                ],
              ),
              const SizedBox(height: 32),
              if (ref.watch(historicSyncProvider).running)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    context.l10n.yourPastActivitiesAreStill,
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              FilledButton(
                onPressed: _saving ? null : () => _finish(),
                child: Text(
                  _saving
                      ? context.l10n.buildingYourPlan
                      : ref.watch(primaryRaceGoalProvider).valueOrNull == null
                      ? context.l10n.saveContinue
                      : context.l10n.buildMyPlan,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shows the priority-A race the plan builds towards, or a button to add it.
class _RaceGoalStep extends ConsumerWidget {
  const _RaceGoalStep({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(primaryRaceGoalProvider).valueOrNull;
    if (goal == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.addYourMainPriorityA),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: enabled ? () => showRaceGoalEditor(context) : null,
            icon: const Icon(Icons.flag_outlined),
            label: Text(context.l10n.addRaceGoal),
          ),
        ],
      );
    }
    final km = goal.distanceM / 1000;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.flag),
      title: Text(goal.name),
      subtitle: Text(
        '${DateFormat.yMMMd().format(goal.raceDate)} · '
        '${goal.primarySport.replaceAll('_', ' ')} · '
        '${km.fixed(km < 10 ? 1 : 0)} km',
      ),
      trailing: TextButton(
        onPressed: enabled ? () => showRaceGoalEditor(context) : null,
        child: Text(context.l10n.addAnother),
      ),
    );
  }
}
