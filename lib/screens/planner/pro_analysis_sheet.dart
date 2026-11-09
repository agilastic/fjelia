import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/ai_coach_provider.dart';
import '../../providers/fjelia_edition_provider.dart';
import '../../providers/planner_providers.dart';
import '../../providers/pro_analysis_provider.dart';
import '../../services/ai_coach_settings.dart';
import '../../services/pro_analysis.dart';
import '../../theme/fjelia_style.dart';
import '../../utils/log.dart';
import '../../widgets/app_widgets.dart';
import '../ai_coach/ai_coach_screen.dart' show coachGradient;
import '../settings/fjelia_pro_sheet.dart';

/// The FjeliaPro analyses on the plan: today's check, the week, the next
/// race and the season. Without Pro each row leads to the Pro sheet.
class ProToolsCard extends ConsumerWidget {
  const ProToolsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final edition = ref.watch(fjeliaEditionProvider);
    if (!edition.proOffered && !edition.isPro) return const SizedBox.shrink();
    final l = context.l10n;
    final now = DateTime.now();
    final race = ref
        .watch(upcomingRaceGoalsProvider)
        .valueOrNull
        ?.where((g) => g.participation != 'cancelled')
        .firstOrNull;
    final rows = [
      (
        Icons.today_rounded,
        l.proPlanCheck,
        l.proPlanCheckHint,
        ProAnalysisRef.planCheck(now),
      ),
      (
        Icons.insights_rounded,
        l.proWeekReview,
        l.proWeekReviewHint,
        ProAnalysisRef.weekReview(now),
      ),
      if (race != null)
        (
          Icons.flag_rounded,
          l.proRacePlan,
          l.proRacePlanHint(race.name),
          ProAnalysisRef.racePlan(race),
        ),
      (
        Icons.timeline_rounded,
        l.proSeason,
        l.proSeasonHint,
        ProAnalysisRef.season(now),
      ),
    ];
    return SectionCard(
      key: const ValueKey('pro-tools'),
      title: l.proToolsTitle,
      accent: coachGradient,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Column(
        children: [
          for (final (icon, title, hint, analysis) in rows)
            _ToolRow(
              key: ValueKey('pro-tool-${analysis.kind.name}'),
              icon: icon,
              title: title,
              hint: hint,
              locked: !edition.isPro,
              onTap: () => showAppSheet(
                context,
                edition.isPro
                    ? ProAnalysisSheet(analysis: analysis, title: title)
                    : const FjeliaProSheet(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.locked,
    required this.onTap,
  });
  final IconData icon;
  final String title, hint;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: LinearGradient(
              colors: [for (final c in coachGradient) fjAccent(c)],
            ).createShader,
            child: Icon(icon, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: fjInk),
                ),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          if (locked)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: GradientTitle('Pro', colors: coachGradient),
            ),
          Icon(Icons.chevron_right, color: muted),
        ],
      ),
    ),
  );
}

/// One analysis: the stored one, or a button to write it; written anew on
/// request. Sending the training context is consented to like in the chat.
class ProAnalysisSheet extends ConsumerStatefulWidget {
  const ProAnalysisSheet({
    super.key,
    required this.analysis,
    required this.title,
  });
  final ProAnalysisRef analysis;
  final String title;

  @override
  ConsumerState<ProAnalysisSheet> createState() => _ProAnalysisSheetState();
}

class _ProAnalysisSheetState extends ConsumerState<ProAnalysisSheet> {
  bool working = false, failed = false;

  Future<void> _create() async {
    final l = context.l10n;
    final settings = ref.read(aiCoachSettingsProvider).valueOrNull;
    final session =
        settings?.consentMode == AiConsentMode.session &&
        ref.read(aiCoachSessionConsentProvider);
    if (!session) {
      if (!await confirmAction(
        context,
        l.shareHealthContextWithName('Fjelia AI Pro'),
        l.yourMessageAndAHealth,
      )) {
        return;
      }
      if (settings?.consentMode == AiConsentMode.session) {
        ref.read(aiCoachSessionConsentProvider.notifier).state = true;
      }
    }
    setState(() {
      working = true;
      failed = false;
    });
    try {
      await ref.read(proAnalysisActionsProvider).generate(widget.analysis);
    } catch (e) {
      log('[FjeliaPro] analysis ${widget.analysis.id} failed: $e');
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final report = ref.watch(proReportProvider(widget.analysis.id)).valueOrNull;
    return SheetPage(
      title: widget.title,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GradientTitle(widget.title, colors: coachGradient, size: 18),
          ),
          if (working)
            SectionCard(
              accent: coachGradient,
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.proAnalysisWorking)),
                ],
              ),
            )
          else if (report != null)
            SectionCard(
              key: const ValueKey('pro-report'),
              accent: coachGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.proAnalysisFrom(
                      DateFormat.MMMd().add_Hm().format(report.createdAt),
                    ),
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                  const SizedBox(height: 8),
                  MarkdownBody(data: report.body, selectable: true),
                ],
              ),
            ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l.proAnalysisFailed,
                style: const TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ),
          FilledButton(
            key: const ValueKey('pro-analysis-create'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: working ? null : _create,
            child: Text(
              report == null ? l.proAnalysisCreate : l.proAnalysisRedo,
            ),
          ),
        ],
      ),
    );
  }
}
