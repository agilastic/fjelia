import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../db/database.dart';
import '../../models/coach_context_card.dart';
import '../../providers/ai_coach_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/ai_coach_client.dart';
import '../../services/ai_coach_settings.dart';
import '../../services/coach_tasks.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/coach_context_card.dart';
import '../../utils/log.dart';
import '../settings/ai_settings_tab.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({
    super.key,
    this.initialPrompt,
    this.activity,
    this.contextCard,
  });
  final String? initialPrompt;

  /// The session the chat is about, shown as a card above the conversation.
  final CoachContextCard? contextCard;

  /// When set, the chat is about this activity and its context is the
  /// activity plus the last 30 days and the year's progression.
  final ActivityRecord? activity;
  @override
  ConsumerState<AiCoachScreen> createState() => _CoachState();
}

class _CoachState extends ConsumerState<AiCoachScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final messages = <ChatMessage>[];
  bool sending = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = widget.initialPrompt ?? ref.read(pendingCoachPromptProvider);
      if (p != null) {
        input.text = p;
        if (widget.initialPrompt == null) {
          ref.read(pendingCoachPromptProvider.notifier).state = null;
        }
      }
    });
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send({bool retry = false}) async {
    final draft = retry && messages.isNotEmpty && messages.last.isUser
        ? messages.last.text
        : input.text.trim();
    if (sending || draft.isEmpty) return;
    final settings = await ref.read(aiCoachSettingsProvider.future);
    if (!settings.ready) {
      if (mounted) showAppSheet(context, const AiSettingsTab());
      return;
    }
    AiConsentToken? consent;
    if (settings.provider != AiProvider.appleIntelligence) {
      final session =
          settings.consentMode == AiConsentMode.session &&
          ref.read(aiCoachSessionConsentProvider);
      if (!session) {
        if (!mounted ||
            !await confirmAction(
              context,
              context.l10n.shareHealthContextWithName(settings.provider.name),
              context.l10n.yourMessageAndAHealth,
            )) {
          return;
        }
        if (settings.consentMode == AiConsentMode.session) {
          ref.read(aiCoachSessionConsentProvider.notifier).state = true;
        }
      }
      consent = AiConsentToken.confirmed();
    }
    if (!mounted) return;
    setState(() {
      sending = true;
      error = null;
      if (!retry) {
        messages.add(ChatMessage(text: draft, isUser: true));
        input.clear();
      }
    });
    try {
      final activity = widget.activity;
      final String toon;
      if (activity != null) {
        toon = await ref.read(activityCoachContextProvider(activity).future);
      } else {
        final profile = await ref.read(userProfileProvider.future);
        toon = await ref
            .read(toonCacheProvider.notifier)
            .getOrBuild(null, profile.raceGoals ?? '', null);
      }
      final reply = await ref
          .read(aiCoachClientProvider)
          .send(
            settings,
            List.of(messages),
            widget.contextCard?.withContext(toon) ?? toon,
            consent,
          );
      if (mounted) {
        setState(() => messages.add(ChatMessage(text: reply, isUser: false)));
      }
    } catch (e) {
      log('[AiCoach] send failed: $e');
      if (mounted) {
        setState(
          () => error = e is AiCoachException
              ? e.message
              : context.l10n.couldNotGetAReply,
        );
      }
    } finally {
      if (mounted) {
        setState(() => sending = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients) {
            scroll.animateTo(
              scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  CoachTask get _task {
    final line = widget.contextCard?.contextLine ?? '';
    return line.isEmpty && widget.activity != null
        ? CoachTask.evaluateActivity
        : coachTaskFor(line);
  }

  /// Follow-up questions under the last answer, up to three.
  List<String> get _followUps =>
      sending || error != null || messages.isEmpty || messages.last.isUser
      ? const []
      : followUpQuestions(
          _task,
          asked: [
            for (final m in messages)
              if (m.isUser) m.text,
            ...?widget.contextCard?.questions,
          ],
        );

  @override
  Widget build(BuildContext context) {
    final followUps = _followUps;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.aiCoach,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: context.l10n.aiSettings,
                onPressed: () => showAppSheet(context, const AiSettingsTab()),
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
        Expanded(
          child: messages.isEmpty && error == null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: widget.contextCard == null
                      ? null
                      : const EdgeInsets.all(16),
                  children: [
                    if (widget.contextCard case final card?) ...[
                      CoachContextCardView(card: card),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final q in card.questions)
                            ActionChip(
                              label: Text(
                                q,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: sending
                                  ? null
                                  : () {
                                      input.text = q;
                                      send();
                                    },
                            ),
                        ],
                      ),
                    ] else
                      EmptyState(context.l10n.askAboutYourRecoveryTraining),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      (widget.contextCard == null ? 0 : 1) +
                      messages.length +
                      (error != null || followUps.isNotEmpty ? 1 : 0),
                  itemBuilder: (c, index) {
                    final card = widget.contextCard;
                    if (card != null && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CoachContextCardView(card: card),
                      );
                    }
                    final i = index - (card == null ? 0 : 1);
                    if (i == messages.length && error == null) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final q in followUps)
                            ActionChip(
                              label: Text(
                                q,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () {
                                input.text = q;
                                send();
                              },
                            ),
                        ],
                      );
                    }
                    if (i == messages.length) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: panel,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              error!,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: sending
                                      ? null
                                      : () => send(retry: true),
                                  child: Text(context.l10n.retry),
                                ),
                                TextButton(
                                  onPressed: () => setState(() => error = null),
                                  child: Text(context.l10n.dismiss),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    final m = messages[i];
                    return Align(
                      alignment: m.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: m.isUser ? mint.withValues(alpha: .12) : panel,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: MarkdownBody(data: m.text, selectable: true),
                      ),
                    );
                  },
                ),
        ),
        if (sending) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: context.l10n.askYourCoach,
                  ),
                  onSubmitted: (_) => send(),
                ),
              ),
              IconButton(
                tooltip: context.l10n.sendMessage,
                onPressed: sending ? null : send,
                icon: const Icon(Icons.arrow_upward, color: mint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Opens the coach tab about a session: closes the sheets on top, then the
/// home screen shows the coach with [card] above the chat, [prompt] as the
/// draft question and, for an [activity], its training context.
void openCoachTab(
  BuildContext context, {
  required String prompt,
  ActivityRecord? activity,
  CoachContextCard? card,
}) {
  final container = ProviderScope.containerOf(context);
  container.read(coachRequestProvider.notifier).state = CoachRequest(
    prompt: prompt,
    activity: activity,
    card: card,
  );
  Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
}
