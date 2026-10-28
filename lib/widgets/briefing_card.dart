import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';

import '../services/briefing_text.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_coach_provider.dart';
import '../providers/day_data_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/ai_coach_settings.dart';
import 'app_widgets.dart';

class BriefingCard extends ConsumerStatefulWidget {
  const BriefingCard({super.key, required this.openCoach});
  final VoidCallback openCoach;
  @override
  ConsumerState<BriefingCard> createState() => _BriefingCardState();
}

class _BriefingCardState extends ConsumerState<BriefingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aiCoachSettingsProvider).valueOrNull;
    if (settings == null || settings.briefingMode == BriefingMode.none) {
      return const SizedBox.shrink();
    }
    final hour = DateTime.now().hour;
    final period = hour < 11
        ? AiBriefingPeriod.morning
        : hour < 14
        ? AiBriefingPeriod.lunch
        : hour < 18
        ? AiBriefingPeriod.afternoon
        : AiBriefingPeriod.evening;
    final briefing = ref.watch(aiBriefingProvider(period));
    final summary = ref.watch(
      briefingSummaryProvider(ref.watch(selectedDateProvider)),
    );
    final fallback =
        settings.briefingMode == BriefingMode.ai && briefing.hasError;
    final raw = settings.briefingMode == BriefingMode.static_ || fallback
        ? summary
        : briefing.valueOrNull;
    // Never markdown or line breaks, also for a briefing saved earlier.
    final text = raw == null ? null : flattenBriefing(raw);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(switch (period) {
            AiBriefingPeriod.morning => context.l10n.morningBriefing,
            AiBriefingPeriod.lunch => context.l10n.lunchBriefing,
            AiBriefingPeriod.afternoon => context.l10n.afternoonBriefing,
            AiBriefingPeriod.evening => context.l10n.eveningBriefing,
          }, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (text != null)
            Text(
              text,
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.55),
            ),
          if (briefing.isLoading) const LinearProgressIndicator(),
          if (briefing.hasError)
            Text(
              settings.usesOnDeviceBriefing
                  ? context.l10n.appleIntelligenceIsUnavailableShowing
                  : context.l10n.aiBriefingUnavailableShowingA,
              style: TextStyle(fontSize: 12, color: muted),
            ),
          if (settings.briefingMode == BriefingMode.ai &&
              (text == null || fallback) &&
              !briefing.isLoading)
            TextButton(
              onPressed: () => runUiAction(context, () async {
                if (!settings.usesOnDeviceBriefing) {
                  if (!await confirmAction(
                    context,
                    context.l10n.generateAiBriefing,
                    'A summary of your health and training data will be sent to ${settings.provider.name}.',
                  )) {
                    return;
                  }
                }
                final profile = await ref.read(userProfileProvider.future);
                await ref
                    .read(aiBriefingProvider(period).notifier)
                    .load(settings, raceGoals: profile.raceGoals ?? '');
              }),
              child: Text(
                fallback
                    ? context.l10n.retryAiBriefing
                    : context.l10n.generateBriefing,
              ),
            ),
          if (text != null &&
              settings.briefingMode == BriefingMode.ai &&
              !fallback)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: mint,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
                alignment: Alignment.centerLeft,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'show less' : 'read more'),
            ),
          if (_expanded &&
              text != null &&
              settings.briefingMode == BriefingMode.ai &&
              !fallback)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: mint,
                  side: const BorderSide(color: mint),
                  minimumSize: const Size(double.infinity, 44),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(context.l10n.chatWithAiAboutThis),
                onPressed: () {
                  ref.read(pendingCoachPromptProvider.notifier).state = context
                      .l10n
                      .discussThisBriefingWithMe(text);
                  widget.openCoach();
                },
              ),
            ),
          if (_expanded &&
              text != null &&
              settings.briefingMode == BriefingMode.ai &&
              !fallback)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: mint),
              icon: const Icon(Icons.help_outline, size: 18),
              label: Text(context.l10n.whyThisRecommendation),
              onPressed: () {
                ref.read(pendingCoachPromptProvider.notifier).state = context
                    .l10n
                    .whyThisRecommendationWhichOf(text);
                widget.openCoach();
              },
            ),
        ],
      ),
    );
  }
}
