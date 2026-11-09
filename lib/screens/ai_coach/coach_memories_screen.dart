import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/coach_memory_provider.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';
import 'ai_coach_screen.dart' show coachGradient;

/// The accent pairs the cards take in turn (Fjelia Aurora: at most three
/// on a screen, one per card).
const memoryGradients = [
  coachGradient,
  [Color(0xFFFF7AD9), Color(0xFF9D7BFF)],
  [mint, Color(0xFFC6FF4D)],
];

/// FjeliaPro: the athlete's own memory cards for the AI coach. Every chat
/// sends them along as additional information.
class CoachMemoriesScreen extends ConsumerWidget {
  const CoachMemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(coachMemoriesProvider).value ?? const [];
    final l = context.l10n;
    return SheetPage(
      title: l.coachMemories,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _Hero(),
          Text(
            l.coachMemoriesIntro,
            textAlign: TextAlign.center,
            style: TextStyle(color: fjInk70, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            l.coachMemoryCount(cards.length),
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => editCoachMemory(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.coachMemoryNew),
          ),
          const SizedBox(height: 16),
          if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l.coachMemoryEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 14),
              ),
            )
          else
            for (final (i, card) in cards.indexed)
              _MemoryCardView(
                card: card,
                colors: memoryGradients[i % memoryGradients.length],
              ),
        ],
      ),
    );
  }
}

/// The coach's orb with the memory icon; it scales in once.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutBack,
        builder: (context, t, child) =>
            Transform.scale(scale: .6 + .4 * t, child: child),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: coachGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: coachGradient.first.withValues(alpha: .45),
                blurRadius: 24,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: coachGradient.last.withValues(alpha: .3),
                blurRadius: 36,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.psychology_alt_rounded,
            size: 34,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

/// Opens the editor for a new card or for [card].
Future<void> editCoachMemory(
  BuildContext context,
  WidgetRef ref, [
  CoachMemory? card,
]) async {
  final saved = await showAppSheet<(String, String)>(
    context,
    _MemoryEditor(card: card),
  );
  if (saved == null) return;
  final (title, body) = saved;
  await ref.read(coachMemoryStoreProvider).save(title, body, card);
}

/// One card: an accented section card with its title, its text and a
/// delete button; a tap edits it.
class _MemoryCardView extends ConsumerWidget {
  const _MemoryCardView({required this.card, required this.colors});
  final CoachMemory card;
  final List<Color> colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return SectionCard(
      accent: colors,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
      onTap: () => editCoachMemory(context, ref, card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.title.isEmpty ? '✦' : card.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: fjInk,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.delete,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.delete_outline, color: muted, size: 20),
                onPressed: () async {
                  if (await confirmAction(
                    context,
                    l.coachMemoryDeleteQuestion,
                    card.title,
                  )) {
                    await ref.read(coachMemoryStoreProvider).delete(card.id);
                  }
                },
              ),
            ],
          ),
          if (card.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                card.body,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fjInk70, fontSize: 14, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemoryEditor extends StatefulWidget {
  const _MemoryEditor({this.card});
  final CoachMemory? card;

  @override
  State<_MemoryEditor> createState() => _MemoryEditorState();
}

class _MemoryEditorState extends State<_MemoryEditor> {
  late final title = TextEditingController(text: widget.card?.title);
  late final body = TextEditingController(text: widget.card?.body);

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  bool get _ready =>
      title.text.trim().isNotEmpty || body.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SheetPage(
      title: widget.card == null ? l.coachMemoryNew : l.coachMemories,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          TextField(
            controller: title,
            autofocus: widget.card == null,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.coachMemoryTitle,
              hintText: l.coachMemoryTitleHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: body,
            minLines: 4,
            maxLines: 10,
            maxLength: 1500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.coachMemoryBody,
              hintText: l.coachMemoryBodyHint,
              alignLabelWithHint: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _ready
                ? () => Navigator.pop(context, (
                    title.text.trim(),
                    body.text.trim(),
                  ))
                : null,
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}
