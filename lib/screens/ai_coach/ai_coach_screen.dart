import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../db/database.dart';
import '../../providers/ai_coach_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/ai_coach_client.dart';
import '../../services/ai_coach_settings.dart';
import '../../widgets/app_widgets.dart';
import '../../utils/log.dart';
import '../settings/ai_settings_tab.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key, this.initialPrompt, this.activity});
  final String? initialPrompt;

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
              'Share health context with ${settings.provider.name}?',
              'Your message and a health/training summary will be sent to this cloud AI provider. Names and GPS are excluded from the generated summary.',
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
          .send(settings, List.of(messages), toon, consent);
      if (mounted) {
        setState(() => messages.add(ChatMessage(text: reply, isUser: false)));
      }
    } catch (e) {
      log('[AiCoach] send failed: $e');
      if (mounted) {
        setState(
          () => error = e is AiCoachException
              ? e.message
              : 'Could not get a reply. Check your AI settings and try again.',
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

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'AI Coach',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'AI settings',
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
                children: const [
                  EmptyState(
                    'Ask about your recovery, training, or today’s plan.',
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: scroll,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (error == null ? 0 : 1),
                itemBuilder: (c, i) {
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
                                child: const Text('Retry'),
                              ),
                              TextButton(
                                onPressed: () => setState(() => error = null),
                                child: const Text('Dismiss'),
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
                decoration: const InputDecoration(hintText: 'Ask your coach…'),
                onSubmitted: (_) => send(),
              ),
            ),
            IconButton(
              tooltip: 'Send message',
              onPressed: sending ? null : send,
              icon: const Icon(Icons.arrow_upward, color: mint),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Opens the coach chat in a sheet with an editable [prompt] draft.
void showCoachSheet(
  BuildContext context, {
  required String title,
  required String prompt,
  ActivityRecord? activity,
}) {
  showAppSheet(
    context,
    Builder(
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SheetPage(
          title: title,
          child: AiCoachScreen(initialPrompt: prompt, activity: activity),
        ),
      ),
    ),
  );
}
