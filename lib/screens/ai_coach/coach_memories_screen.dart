import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/coach_memory_provider.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';

/// The neon pairs the cards cycle through, so no two neighbours look alike.
const memoryGradients = [
  [Color(0xFFFF4FD8), Color(0xFFFF9A3C)],
  [Color(0xFF9D7BFF), Color(0xFF3EE0FF)],
  [Color(0xFFB6FF3C), Color(0xFF00D4A0)],
  [Color(0xFFFFE14F), Color(0xFFFF4F8B)],
  [Color(0xFF3EE0FF), Color(0xFF4F6BFF)],
];

/// FjeliaPro: the athlete's own memory cards for the AI coach. Every chat
/// sends them along as additional information.
class CoachMemoriesScreen extends ConsumerWidget {
  const CoachMemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(coachMemoriesProvider).value ?? const [];
    final l = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _Spark(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientTitle(
                          l.coachMemories,
                          colors: const [
                            Color(0xFFFF4FD8),
                            Color(0xFF9D7BFF),
                            Color(0xFF3EE0FF),
                          ],
                          size: 24,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.coachMemoriesIntro,
                    style: TextStyle(
                      color: fjInk70,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.coachMemoryCount(cards.length),
                    style: TextStyle(
                      color: fjAccent(const Color(0xFF3EE0FF)),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (cards.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Text(
                  l.coachMemoryEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fjInk60,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList.separated(
                itemCount: cards.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (c, i) => _MemoryCardView(
                  card: cards[i],
                  colors: memoryGradients[i % memoryGradients.length],
                  tilt: i.isEven ? -.006 : .006,
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _GlowPill(
        label: l.coachMemoryNew,
        icon: Icons.add_rounded,
        onTap: () => editCoachMemory(context, ref),
      ),
    );
  }
}

/// Opens the editor for a new card or for [card].
Future<void> editCoachMemory(
  BuildContext context,
  WidgetRef ref, [
  CoachMemory? card,
]) async {
  final saved = await showModalBottomSheet<(String, String)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: duo(0xFF111111, 0xFFF2F4F7),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _MemoryEditor(card: card),
  );
  if (saved == null) return;
  final (title, body) = saved;
  await ref.read(coachMemoryStoreProvider).save(title, body, card);
}

class _MemoryCardView extends ConsumerWidget {
  const _MemoryCardView({
    required this.card,
    required this.colors,
    required this.tilt,
  });
  final CoachMemory card;
  final List<Color> colors;
  final double tilt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Transform.rotate(
      angle: tilt,
      child: Container(
        // The gradient frame around the panel.
        padding: const EdgeInsets.all(1.6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: Fjelia.light ? .18 : .3),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: panel,
          borderRadius: BorderRadius.circular(24.4),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => editCoachMemory(context, ref, card),
            child: Ink(
              decoration: fjGlow(colors, strength: 1.6),
              padding: const EdgeInsets.fromLTRB(18, 14, 6, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: colors),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          card.title.isEmpty ? '✦' : card.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: fjInk,
                            letterSpacing: -.2,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l.delete,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: fjInk38,
                          size: 20,
                        ),
                        onPressed: () async {
                          if (await confirmAction(
                            context,
                            l.coachMemoryDeleteQuestion,
                            card.title,
                          )) {
                            await ref
                                .read(coachMemoryStoreProvider)
                                .delete(card.id);
                          }
                        },
                      ),
                    ],
                  ),
                  if (card.body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 12),
                      child: Text(
                        card.body,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fjInk70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
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
    InputDecoration field(String label, String hint) => InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: fjInk30),
      filled: true,
      fillColor: panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF9D7BFF), width: 1.6),
      ),
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientTitle(
            widget.card == null ? l.coachMemoryNew : l.coachMemories,
            colors: memoryGradients[0],
            size: 16,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: title,
            autofocus: widget.card == null,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            decoration: field(l.coachMemoryTitle, l.coachMemoryTitleHint),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: body,
            minLines: 4,
            maxLines: 10,
            maxLength: 1500,
            textCapitalization: TextCapitalization.sentences,
            decoration: field(l.coachMemoryBody, l.coachMemoryBodyHint),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Center(
            child: _GlowPill(
              label: l.save,
              icon: Icons.bolt_rounded,
              onTap: _ready
                  ? () => Navigator.pop(context, (
                      title.text.trim(),
                      body.text.trim(),
                    ))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// The loud gradient button of the memory screens.
class _GlowPill extends StatelessWidget {
  const _GlowPill({required this.label, required this.icon, this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFFFF4FD8), Color(0xFF9D7BFF), Color(0xFF3EE0FF)];
    final on = onTap != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          colors: [for (final c in colors) c.withValues(alpha: on ? 1 : .35)],
        ),
        boxShadow: [
          BoxShadow(
            color: colors[1].withValues(alpha: on ? .5 : 0),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.black87, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: .3,
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

/// A slowly turning gradient orb next to the title.
class _Spark extends StatefulWidget {
  const _Spark();

  @override
  State<_Spark> createState() => _SparkState();
}

class _SparkState extends State<_Spark> with SingleTickerProviderStateMixin {
  late final spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: spin,
    child: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFFFF4FD8),
            Color(0xFF9D7BFF),
            Color(0xFF3EE0FF),
            Color(0xFFB6FF3C),
            Color(0xFFFF4FD8),
          ],
        ),
      ),
      child: const Icon(Icons.psychology_alt_rounded, color: Colors.black87),
    ),
  );
}
