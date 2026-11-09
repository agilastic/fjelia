import '../../theme/fjelia_style.dart';

import 'dart:async';

import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../db/database.dart';
import '../../config/free_ai.dart';
import '../../models/coach_context_card.dart';
import '../../providers/ai_coach_provider.dart';
import '../../providers/coach_memory_provider.dart';
import '../../providers/ecg_provider.dart';
import '../../providers/fjelia_edition_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/ai_coach_client.dart';
import '../../services/ai_coach_settings.dart';
import '../../services/coach_memory_context.dart';
import '../../services/coach_tasks.dart';
import '../../services/ecg_coach_context.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/coach_context_card.dart';
import '../../widgets/ecg_sheet.dart' show confirmEcgCoachWarning;
import '../../utils/log.dart';
import '../settings/ai_settings_tab.dart';
import 'coach_memories_screen.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({
    super.key,
    this.initialPrompt,
    this.activity,
    this.contextCard,
    this.onNewChat,
    this.autoSend = false,
    this.onAutoSent,
  });
  final String? initialPrompt;

  /// Sends [initialPrompt] right away, for a button that already asked the
  /// question (such as "Discuss this ECG").
  final bool autoSend;
  final VoidCallback? onAutoSent;

  /// Starts an empty chat without a session. Without it the conversation is
  /// only cleared.
  final VoidCallback? onNewChat;

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

  /// The ECG this conversation has loaded, once its warning was confirmed;
  /// follow-up questions keep its analysis in the context.
  String? _ecgId;
  bool _ecgWarned = false;

  /// The coach was told several ECGs fit and asked which one is meant.
  bool _ecgChoosing = false;

  /// Runs while a reply is on its way, for the clock in the waiting bubble.
  final _watch = Stopwatch();
  Timer? _tick;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = widget.initialPrompt ?? ref.read(pendingCoachPromptProvider);
      // A chat about a training or an activity starts with an empty field:
      // its context is loaded already and the card offers the questions.
      final aboutSession =
          widget.contextCard != null || widget.activity != null;
      if (p != null) {
        if (!aboutSession || widget.autoSend) input.text = p;
        if (widget.initialPrompt == null) {
          ref.read(pendingCoachPromptProvider.notifier).state = null;
        }
        if (widget.autoSend) {
          widget.onAutoSent?.call();
          send();
        }
      }
    });
  }

  void _newChat() {
    final start = widget.onNewChat;
    if (start != null) return start();
    setState(() {
      messages.clear();
      error = null;
      input.clear();
      _ecgId = null;
      _ecgWarned = false;
      _ecgChoosing = false;
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
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
    if (!settings.provider.isLocal) {
      final session =
          settings.consentMode == AiConsentMode.session &&
          ref.read(aiCoachSessionConsentProvider);
      if (!session) {
        if (!mounted ||
            !await confirmAction(
              context,
              context.l10n.shareHealthContextWithName(
                settings.provider == AiProvider.freeAi
                    ? '${context.l10n.freeAi} ($freeAiHost)'
                    : settings.provider.name,
              ),
              settings.provider == AiProvider.freeAi
                  ? '${context.l10n.yourMessageAndAHealth}\n\n${context.l10n.freeAiUsageTracking}'
                  : context.l10n.yourMessageAndAHealth,
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
    final ecgLines = await _ecgLinesFor(draft);
    if (!mounted) return;
    _watch
      ..reset()
      ..start();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
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
      // FjeliaPro: what the athlete asked the coach to always know.
      final memories = ref.read(fjeliaEditionProvider).isPro
          ? coachMemoryLines(await ref.read(coachMemoryStoreProvider).all())
          : const <String>[];
      final context = [...ecgLines, toon, ...memories].join('\n');
      final reply = await ref
          .read(aiCoachClientProvider)
          .send(
            settings,
            List.of(messages),
            widget.contextCard?.withContext(context) ?? context,
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
      _tick?.cancel();
      _watch.stop();
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

  /// The ECG lines for [question]: which recordings exist and, once the
  /// question is about one of them and the warning was confirmed, its full
  /// analysis. A chat opened from an ECG has its analysis already.
  Future<List<String>> _ecgLinesFor(String question) async {
    if (widget.contextCard?.contextLine.contains('[ECG:') ?? false) {
      return const [];
    }
    final coach = ref.read(ecgCoachProvider);
    final EcgCoachContext prep;
    try {
      prep = await coach.prepare(
        question: question,
        activity: widget.activity,
        current: _ecgId,
        choosing: _ecgChoosing,
      );
    } catch (e) {
      log('[AiCoach] ECG context failed: $e');
      return const [];
    }
    _ecgChoosing = prep.lines.any((l) => l.startsWith('[ECG:Choose'));
    final row = prep.detail;
    if (row == null) return prep.lines;
    if (!_ecgWarned) {
      if (!mounted || !await confirmEcgCoachWarning(context, ref)) {
        return [ecgAvailableLine(row), ecgDeclinedLine];
      }
      _ecgWarned = true;
    }
    try {
      final lines = await coach.detail(
        row,
        question,
        activity: widget.activity,
      );
      if (mounted) setState(() => _ecgId = row.recordingId);
      return lines;
    } catch (e) {
      log('[AiCoach] ECG analysis failed: $e');
      return [ecgAvailableLine(row), ecgFailedLine];
    }
  }

  CoachTask get _task {
    if (_ecgId != null) return CoachTask.ecg;
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
    final pro = ref.watch(fjeliaEditionProvider).isPro;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GradientTitle(
                    context.l10n.aiCoach,
                    colors: coachGradient,
                    size: 18,
                  ),
                ),
              ),
              // Shown once there is something to start over from.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child:
                    messages.isEmpty &&
                        widget.contextCard == null &&
                        widget.activity == null
                    ? const SizedBox(width: 48)
                    : IconButton(
                        key: const ValueKey('new-chat'),
                        tooltip: context.l10n.newChat,
                        onPressed: sending ? null : _newChat,
                        icon: const Icon(Icons.add_comment_outlined),
                      ),
              ),
              if (ref.watch(fjeliaEditionProvider).isPro)
                IconButton(
                  tooltip: context.l10n.coachMemories,
                  onPressed: () =>
                      showAppSheet(context, const CoachMemoriesScreen()),
                  icon: const Icon(Icons.psychology_alt_outlined),
                ),
              IconButton(
                tooltip: context.l10n.aiSettings,
                onPressed: () => showAppSheet(context, const AiSettingsTab()),
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
        // Stays on top while scrolling: the chat about a health measurement
        // never reads like a doctor's opinion.
        if ((widget.contextCard?.medicalWarning ?? false) || _ecgId != null)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: CoachMedicalWarning(),
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
                      _CoachOrb(
                        text: context.l10n.askAboutYourRecoveryTraining,
                      ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      (widget.contextCard == null ? 0 : 1) +
                      messages.length +
                      (sending || error != null || followUps.isNotEmpty
                          ? 1
                          : 0),
                  itemBuilder: (c, index) {
                    final card = widget.contextCard;
                    if (card != null && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CoachContextCardView(card: card),
                      );
                    }
                    final i = index - (card == null ? 0 : 1);
                    if (i == messages.length && sending) {
                      return _ThinkingBubble(seconds: _watch.elapsed.inSeconds);
                    }
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
                        decoration: m.isUser
                            // Yours in the coach's gradient, the coach's
                            // answer on a panel with its glow.
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    for (final c in coachGradient)
                                      c.withValues(alpha: .2),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                  bottomLeft: Radius.circular(18),
                                  bottomRight: Radius.circular(6),
                                ),
                                border: Border.all(
                                  color: coachGradient.last.withValues(
                                    alpha: .3,
                                  ),
                                ),
                              )
                            : BoxDecoration(
                                // The glow laid onto the panel, as a
                                // gradient replaces the colour.
                                gradient: RadialGradient(
                                  center: Alignment.topLeft,
                                  radius: 1.6,
                                  colors: [
                                    Color.alphaBlend(
                                      mint.withValues(alpha: .1),
                                      panel,
                                    ),
                                    panel,
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                  bottomLeft: Radius.circular(6),
                                  bottomRight: Radius.circular(18),
                                ),
                                border: Border.fromBorderSide(
                                  fjEdge(const [mint, Color(0xFF3EE0FF)]),
                                ),
                              ),
                        child: m.isUser || !pro
                            ? MarkdownBody(data: m.text, selectable: true)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MarkdownBody(data: m.text, selectable: true),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _CopyButton(text: m.text),
                                  ),
                                ],
                              ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: coachGradient.first.withValues(alpha: .35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: coachGradient.last.withValues(alpha: .8),
                        width: 1.4,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => send(),
                ),
              ),
              const SizedBox(width: 8),
              // Sending keeps the keyboard open for the next message.
              TextFieldTapRegion(
                // Dimmed by its colours while sending: an Opacity layer over
                // the blurred glow trips Impeller's validation.
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        for (final c in coachGradient)
                          c.withValues(alpha: sending ? .4 : 1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: coachGradient.last.withValues(
                          alpha: sending ? 0 : .45,
                        ),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: IconButton(
                    tooltip: context.l10n.sendMessage,
                    onPressed: sending ? null : send,
                    icon: Icon(
                      Icons.arrow_upward,
                      color: Colors.black87.withValues(
                        alpha: sending ? .35 : .87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// FjeliaPro: copies a coach answer, with a short flash of confirmation.
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});
  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = copied ? const [mint, Color(0xFFB6FF3C)] : coachGradient;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: copied ? null : _copy,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [for (final c in colors) c.withValues(alpha: .18)],
              ),
              border: Border.all(color: colors.last.withValues(alpha: .5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: Icon(
                    copied ? Icons.check_rounded : Icons.copy_rounded,
                    key: ValueKey(copied),
                    size: 15,
                    color: fjAccent(colors.last),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  copied ? context.l10n.answerCopied : context.l10n.copyAnswer,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: fjAccent(colors.last),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown in place of the answer while the coach works: a spinner and a
/// running clock, so a slow model does not look like a hung app.
class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final clock =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        label: context.l10n.coachThinking,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: mint),
              ),
              const SizedBox(width: 12),
              Text(
                '${context.l10n.coachThinking}  $clock',
                style: const TextStyle(
                  fontSize: 13,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
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
  bool autoSend = false,
}) {
  final container = ProviderScope.containerOf(context);
  container.read(coachRequestProvider.notifier).state = CoachRequest(
    prompt: prompt,
    activity: activity,
    card: card,
    autoSend: autoSend,
  );
  Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
}

/// The coach's colours: violet into cyan.
const coachGradient = [Color(0xFF9D7BFF), Color(0xFF3EE0FF)];

/// The empty chat: a glowing orb that grows in, and what to ask about.
class _CoachOrb extends StatelessWidget {
  const _CoachOrb({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 56, 32, 24),
    child: Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, t, child) =>
              Transform.scale(scale: .6 + .4 * t, child: child),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: coachGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: coachGradient.first.withValues(alpha: .5),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: coachGradient.last.withValues(alpha: .35),
                  blurRadius: 44,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 38,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: fjInk70, height: 1.4),
        ),
      ],
    ),
  );
}
