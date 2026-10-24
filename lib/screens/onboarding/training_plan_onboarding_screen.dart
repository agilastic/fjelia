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
          _error = 'Could not save preferences: $e';
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
        title: const Text('Training Plan'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _finish(save: false),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(userProfileProvider),
            child: const Text('Retry loading preferences'),
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
              const Text(
                'Tell us about your race and schedule. Fjelia builds your plan now and '
                'works out your level from your past activities (Garmin, Suunto, '
                'Polar, COROS, Apple Health) once they are downloaded.',
              ),
              const SizedBox(height: 24),
              if (_error != null) OnboardingErrorBanner(_error!),
              const HistorySyncCard(),
              const OnboardingInputLabel('RACE GOAL'),
              _RaceGoalStep(enabled: !_saving),
              const SizedBox(height: 24),
              if (!hasHistory) ...[
                const OnboardingInputLabel('EXPERIENCE LEVEL'),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No account connected, so Fjelia has no history to learn '
                    'from. Connect Garmin, Suunto, Polar, COROS or Apple '
                    'Health and your real training decides instead.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final level in ['beginner', 'intermediate', 'advanced'])
                      ChoiceChip(
                        label: Text(level),
                        selected: p.experienceLevel == level,
                        onSelected: _saving
                            ? null
                            : (_) => update(p.copyWith(experienceLevel: level)),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'WEEKLY TRAINING TIME · ${p.hoursPerWeek.toStringAsFixed(1)} h',
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
              const SizedBox(height: 16),
              const OnboardingInputLabel('WEEKLY SCHEDULE'),
              const Text('Tap a day to cycle Training / Rest / Strength.'),
              Wrap(
                spacing: 6,
                children: [
                  for (final day in p.weekStartsOnMonday
                    ? const [1, 2, 3, 4, 5, 6, 7]
                    : const [7, 1, 2, 3, 4, 5, 6])
                    ActionChip(
                      label: Text(
                        '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1]} '
                        '${p.restDays.contains(day)
                            ? 'Rest'
                            : p.preferredStrengthDays.contains(day)
                            ? 'Strength'
                            : 'Training'}',
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
              const OnboardingInputLabel('SESSIONS PER DAY'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Double day ok'),
                value: p.maxSessionsPerDay == 2,
                onChanged: _saving
                    ? null
                    : (v) => update(p.copyWith(maxSessionsPerDay: v ? 2 : 1)),
              ),
              const SizedBox(height: 16),
              const OnboardingInputLabel('ABOUT YOU'),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in {
                    'm': 'Male',
                    'f': 'Female',
                    'x': 'Other',
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
                decoration: const InputDecoration(
                  labelText: 'Birth year (optional)',
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
              const OnboardingInputLabel('YOUR ACTIVITIES'),
              Wrap(
                spacing: 8,
                children: [
                  for (final sport in {
                    'running': 'Running',
                    'trail_running': 'Trail running',
                    'cycling_road': 'Cycling',
                    'swimming': 'Swimming',
                    'triathlon': 'Triathlon',
                    'hiking': 'Hiking',
                    'indoor_rowing': 'Rowing',
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
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Your past activities are still being imported. You can '
                    'build your plan now — it is refined automatically when '
                    'the import finishes.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              FilledButton(
                onPressed: _saving ? null : () => _finish(),
                child: Text(
                  _saving
                      ? 'Building your plan…'
                      : ref.watch(primaryRaceGoalProvider).valueOrNull == null
                      ? 'Save & Continue'
                      : 'Build My Plan',
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
          const Text(
            'Add your main (priority A) race. The plan is periodised towards '
            'it: base, build, peak and taper. Without a race goal no plan is '
            'generated yet.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: enabled ? () => showRaceGoalEditor(context) : null,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Add race goal'),
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
        '${DateFormat('d MMM yyyy').format(goal.raceDate)} · '
        '${goal.primarySport.replaceAll('_', ' ')} · '
        '${km.toStringAsFixed(km < 10 ? 1 : 0)} km',
      ),
      trailing: TextButton(
        onPressed: enabled ? () => showRaceGoalEditor(context) : null,
        child: const Text('Add another'),
      ),
    );
  }
}
