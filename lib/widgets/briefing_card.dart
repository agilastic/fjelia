import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';

import '../services/briefing_text.dart';
import '../config/free_ai.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_coach_provider.dart';
import '../providers/day_data_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/ai_coach_settings.dart';
import '../services/briefing_consent.dart';
import 'app_widgets.dart';

class BriefingCard extends ConsumerStatefulWidget {
  const BriefingCard({super.key, required this.openCoach});
  final VoidCallback openCoach;
  @override
  ConsumerState<BriefingCard> createState() => _BriefingCardState();
}

class _BriefingCardState extends ConsumerState<BriefingCard> {
  bool _expanded = false;
  bool _initialCloudConsentPromptStarted = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aiCoachSettingsProvider).valueOrNull;
    if (settings == null) {
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
    final source = ref.watch(aiBriefingSourceProvider(period));
    if (settings.readyForBriefing &&
        (!settings.onDeviceAvailable || briefing.hasError) &&
        !_initialCloudConsentPromptStarted) {
      _initialCloudConsentPromptStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        runUiAction(context, () => _requestCloudConsent(settings, period));
      });
    }
    final summary = ref.watch(
      briefingSummaryProvider(ref.watch(selectedDateProvider)),
    );
    final fallback = briefing.hasError;
    final raw = fallback ? summary : briefing.valueOrNull ?? summary;
    final canGenerate = briefing.valueOrNull == null || fallback;
    // Never markdown or line breaks, also for a briefing saved earlier.
    final text = flattenBriefing(raw);
    return SectionCard(
      title: switch (period) {
        AiBriefingPeriod.morning => context.l10n.morningBriefing,
        AiBriefingPeriod.lunch => context.l10n.lunchBriefing,
        AiBriefingPeriod.afternoon => context.l10n.afternoonBriefing,
        AiBriefingPeriod.evening => context.l10n.eveningBriefing,
      },
      accent: const [Color(0xFF9D7BFF), Color(0xFF3EE0FF)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, height: 1.55),
          ),
          if (source != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                source,
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (briefing.isLoading) const LinearProgressIndicator(),
          if (briefing.hasError)
            Text(
              settings.onDeviceAvailable
                  ? context.l10n.appleIntelligenceIsUnavailableShowing
                  : context.l10n.aiBriefingUnavailableShowingA,
              style: TextStyle(fontSize: 12, color: muted),
            ),
          if (settings.readyForBriefing &&
              canGenerate &&
              !briefing.isLoading)
            TextButton(
              onPressed: () => runUiAction(context, () async {
                var cloudConsent = await BriefingConsent.given(settings);
                // Apple is always attempted first. Ask for cloud use only if
                // Apple is unavailable or its on-device generation failed.
                if (!cloudConsent &&
                    (!settings.onDeviceAvailable || briefing.hasError)) {
                  if (!context.mounted) return;
                  final message = context.l10n.shareBriefingContextWithName(
                    '${context.l10n.freeAi} ($freeAiHost)',
                  );
                  if (!await confirmAction(
                    context,
                    context.l10n.generateAiBriefing,
                    message,
                  )) {
                    return;
                  }
                  await BriefingConsent.remember(settings);
                  cloudConsent = true;
                }
                final profile = await ref.read(userProfileProvider.future);
                await ref
                    .read(aiBriefingProvider(period).notifier)
                    .load(
                      settings,
                      raceGoals: profile.raceGoals ?? '',
                      cloudConsent: cloudConsent,
                    );
              }),
              child: Text(
                fallback
                    ? context.l10n.retryAiBriefing
                    : context.l10n.generateBriefing,
              ),
            ),
          if (!fallback)
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
          if (_expanded && !fallback)
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
          if (_expanded && !fallback)
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

  Future<void> _requestCloudConsent(
    AiCoachSettings settings,
    AiBriefingPeriod period,
  ) async {
    if (await BriefingConsent.given(settings)) return;
    if (!mounted) return;
    final message = context.l10n.shareBriefingContextWithName(
      '${context.l10n.freeAi} ($freeAiHost)',
    );
    if (!await confirmAction(
      context,
      context.l10n.generateAiBriefing,
      message,
    )) {
      return;
    }
    await BriefingConsent.remember(settings);
    final profile = await ref.read(userProfileProvider.future);
    await ref
        .read(aiBriefingProvider(period).notifier)
        .load(settings, raceGoals: profile.raceGoals ?? '', cloudConsent: true);
  }
}
