import '../../theme/fjelia_style.dart';
import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'package:fjelia_core/models/strength_muscles.dart';
import '../../models/strength_workout.dart';
import '../../providers/strength_provider.dart';
import '../../theme/activity_colors.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/strength_demo.dart';
import 'strength_forms.dart';
import 'strength_trend_sheet.dart';

String muscleLabel(AppLocalizations l, StrengthMuscle m) => switch (m) {
  StrengthMuscle.quads => l.muscleQuads,
  StrengthMuscle.hamstrings => l.muscleHamstrings,
  StrengthMuscle.glutes => l.muscleGlutes,
  StrengthMuscle.calves => l.muscleCalves,
  StrengthMuscle.adductors => l.muscleAdductors,
  StrengthMuscle.core => l.muscleCore,
  StrengthMuscle.obliques => l.muscleObliques,
  StrengthMuscle.lowerBack => l.muscleLowerBack,
  StrengthMuscle.lats => l.muscleLats,
  StrengthMuscle.upperBack => l.muscleUpperBack,
  StrengthMuscle.chest => l.muscleChest,
  StrengthMuscle.shoulders => l.muscleShoulders,
  StrengthMuscle.triceps => l.muscleTriceps,
  StrengthMuscle.biceps => l.muscleBiceps,
  StrengthMuscle.forearms => l.muscleForearms,
};

/// The YouTube search for an exercise: only its name is sent, and only when
/// the athlete taps. Nothing is embedded or fetched by the app.
Uri youtubeSearchUri(String exerciseName) => Uri.https(
  'www.youtube.com',
  '/results',
  {'search_query': '$exerciseName exercise technique'},
);

/// Edits the pinned note of [variantId]. Returns whether it changed.
Future<bool> editPinnedNote(
  BuildContext context,
  WidgetRef ref, {
  required String variantId,
  required String exerciseName,
  String? current,
}) async {
  final controller = TextEditingController(text: current ?? '');
  final next = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(exerciseName),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: c.l10n.pinnedNote,
          helperText: c.l10n.pinnedNoteHint,
          helperMaxLines: 3,
        ),
      ),
      actions: [
        if ((current ?? '').isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(c, ''),
            child: Text(c.l10n.remove),
          ),
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: Text(c.l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(c, controller.text),
          child: Text(c.l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
  if (next == null || next.trim() == (current ?? '').trim()) return false;
  await ref.read(strengthRepositoryProvider).setExerciseNote(variantId, next);
  ref.invalidate(strengthExerciseNotesProvider);
  return true;
}

/// The athlete's pinned note on an exercise, as a line in its card.
class PinnedNoteLine extends ConsumerWidget {
  const PinnedNoteLine({super.key, required this.variantId});
  final String variantId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref
        .watch(strengthExerciseNotesProvider)
        .valueOrNull?[variantId];
    if (note == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.push_pin, size: 14, color: strengthColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              note,
              semanticsLabel: '${context.l10n.pinnedNote}: $note',
              style: TextStyle(fontSize: 12, color: fjInk70),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets the athlete pick a built-in or own exercise, creating an own one
/// from a typed name. Returns null when cancelled.
Future<StrengthExerciseVariant?> pickOrCreateStrengthVariant(
  BuildContext context,
  WidgetRef ref,
  MassUnit unit,
) async {
  final repo = ref.read(strengthRepositoryProvider);
  final custom = await ref.read(strengthCustomVariantsProvider.future);
  if (!context.mounted) return null;
  final picked = await showExercisePicker(context, custom: custom);
  if (picked == null || !context.mounted) return null;
  final v = picked.variant;
  if (v != null) return v;
  final d = await showExerciseForm(
    context,
    name: picked.customName!,
    equipment: '',
    convention: const StrengthConvention(),
    unit: unit,
  );
  if (d == null || !context.mounted) return null;
  final created = await repo.addCustomVariant(
    name: d.name,
    equipment: d.equipment,
    convention: d.convention,
  );
  ref.invalidate(strengthCustomVariantsProvider);
  return created;
}

/// One exercise: what it trains, how it looks, the athlete's pinned note
/// and a YouTube search (About), and its logged trend (History).
class StrengthExerciseSheet extends ConsumerWidget {
  const StrengthExerciseSheet({
    super.key,
    required this.variantId,
    required this.name,
    required this.equipment,
    required this.convention,
    required this.contextKey,
    this.initialTab = 0,
  });
  final String variantId, name, equipment, contextKey;
  final StrengthConvention convention;

  /// 0 About, 1 History.
  final int initialTab;

  Widget _muscleRow(String label, List<StrengthMuscle> muscles, bool primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 10, color: muted, letterSpacing: .8),
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (context) => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in muscles)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primary
                          ? strengthColor.withValues(alpha: .18)
                          : fjInk10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primary
                            ? strengthColor.withValues(alpha: .6)
                            : fjInk24,
                      ),
                    ),
                    child: Text(
                      muscleLabel(context.l10n, m),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: primary ? FontWeight.w700 : null,
                        color: primary ? fjInk : fjInk70,
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

  Widget _about(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final muscles = strengthMusclesOf(variantId);
    final instructions = builtInStrengthVariant(variantId)?.instructions;
    final note = ref
        .watch(strengthExerciseNotesProvider)
        .valueOrNull?[variantId];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (StrengthExerciseDemo.has(variantId))
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: StrengthExerciseDemo(
              variantId: variantId,
              name: name,
              height: 190,
            ),
          ),
        SectionCard(
          title: l.pinnedNote,
          accent: const [strengthColor, Color(0xFFFFD27A)],
          onTap: () => editPinnedNote(
            context,
            ref,
            variantId: variantId,
            exerciseName: name,
            current: note,
          ),
          child: Row(
            children: [
              Icon(
                note == null ? Icons.push_pin_outlined : Icons.push_pin,
                size: 18,
                color: strengthColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note ?? l.pinnedNoteHint,
                  style: TextStyle(
                    fontSize: 13,
                    color: note == null ? muted : fjInk,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l.exerciseMuscles,
          child: muscles == null
              ? Text(
                  l.exerciseNoMuscleData,
                  style: TextStyle(fontSize: 13, color: muted),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _muscleRow(l.musclePrimary, muscles.primary, true),
                    if (muscles.secondary.isNotEmpty)
                      _muscleRow(l.muscleSecondary, muscles.secondary, false),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l.equipment,
          child: Text(
            [if (equipment.isNotEmpty) equipment, convention.text].join(' · '),
            style: TextStyle(fontSize: 13, color: fjInk70),
          ),
        ),
        if (instructions != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            child: Text(
              instructions,
              style: TextStyle(fontSize: 13, color: fjInk70),
            ),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: fjAccent(strengthColor),
            side: BorderSide(color: strengthColor.withValues(alpha: .5)),
            minimumSize: const Size(0, 48),
          ),
          onPressed: () => launchUrl(
            youtubeSearchUri(name),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.play_circle_outline, size: 20),
          label: Text(l.searchYoutube),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            l.searchYoutubeHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    initialIndex: initialTab,
    child: SheetPage(
      title: name,
      child: Column(
        children: [
          TabBar(
            labelColor: strengthColor,
            indicatorColor: strengthColor,
            tabs: [
              Tab(text: context.l10n.exerciseAbout),
              Tab(text: context.l10n.history),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _about(context, ref),
                StrengthTrendView(
                  contextKey: contextKey,
                  convention: convention,
                  equipment: equipment,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
