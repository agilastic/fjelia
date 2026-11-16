import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart' show MediaItem, ProReport;

import '../../l10n/l10n_ext.dart';
import '../../providers/pro_analysis_provider.dart';
import '../../providers/week_start_provider.dart';
import '../../services/pro_analysis.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/media_gallery.dart' show MediaThumb, MediaViewer;
import '../../widgets/plan_timeline.dart' show doneGradient;
import '../ai_coach/ai_coach_screen.dart' show coachGradient;

/// The earlier week reviews right below the one shown, folded: the diary
/// without a separate page.
class WeekReviewList extends ConsumerWidget {
  const WeekReviewList({super.key, required this.exclude});

  /// The review shown above, left out here.
  final String exclude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = [
      for (final r in ref.watch(weekReviewsProvider).valueOrNull ?? const [])
        if (r.id != exclude &&
            r.body.trim().isNotEmpty &&
            ProAnalysisRef.weekReviewMonday(r.refKey) != null)
          r,
    ];
    if (reviews.isEmpty) return const SizedBox.shrink();
    final mondayFirst = ref.watch(weekStartsOnMondayProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        GradientTitle(context.l10n.weekDiaryOpen, colors: coachGradient),
        const SizedBox(height: 12),
        for (final r in reviews)
          WeekReviewEntry(
            key: ValueKey(r.id),
            report: r,
            mondayFirst: mondayFirst,
            newest: false,
          ),
      ],
    );
  }
}

/// One week: its title, pictures, figures and the review, folded or open.
class WeekReviewEntry extends ConsumerStatefulWidget {
  const WeekReviewEntry({
    super.key,
    required this.report,
    required this.mondayFirst,
    required this.newest,
  });
  final ProReport report;
  final bool mondayFirst, newest;

  @override
  ConsumerState<WeekReviewEntry> createState() => WeekReviewEntryState();
}

class WeekReviewEntryState extends ConsumerState<WeekReviewEntry> {
  late bool open = widget.newest;

  /// The review's first lines without markdown, for the folded card.
  static String _preview(String body) => body
      .split('\n')
      .map((s) => s.replaceAll(RegExp(r'^[#>\-*\d.\s]+|[*_`#]'), '').trim())
      .where((s) => s.isNotEmpty)
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final monday = ProAnalysisRef.weekReviewMonday(widget.report.refKey)!;
    // A week that starts on Sunday holds this Monday as its second day.
    final start = widget.mondayFirst
        ? monday
        : DateTime(monday.year, monday.month, monday.day - 1);
    final end = DateTime(start.year, start.month, start.day + 6);
    final range =
        '${DateFormat.MMMd(locale).format(start)} – '
        '${DateFormat.MMMd(locale).format(end)}';
    final week = int.parse(widget.report.refKey.split('-W').last);
    final figures = ref.watch(weekFiguresProvider(start)).valueOrNull;
    final media =
        ref.watch(weekMediaProvider(start)).valueOrNull ?? const <MediaItem>[];
    final accent = widget.newest ? doneGradient : coachGradient;
    final animate = !MediaQuery.disableAnimationsOf(context);
    // The accordion of style.md: the title, the figures and the first
    // lines; the large chevron centred on the right; a tap anywhere unfolds.
    final chevron = AnimatedRotation(
      turns: open ? .5 : 0,
      duration: Duration(milliseconds: animate ? 220 : 0),
      child: Icon(Icons.expand_more, size: 28, color: fjInk),
    );
    final title = GradientTitle(
      '${l.weekDiaryWeek(week)} · $range'.toUpperCase(),
      colors: accent,
    );
    // The accordion of style.md. Folded: title, figures and first lines with
    // the chevron centred on the right. Open: the chevron moves up to the
    // title, so the pictures, figures and text use the card's full width.
    return SectionCard(
      accent: accent,
      onTap: () => setState(() => open = !open),
      child: AnimatedSize(
        duration: Duration(milliseconds: animate ? 260 : 0),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: open
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: title),
                      chevron,
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (media.isNotEmpty) ...[
                    _WeekMedia(items: media),
                    const SizedBox(height: 14),
                  ],
                  if (figures != null && figures.sessions > 0) ...[
                    FigureGrid([
                      FigureTile(
                        icon: Icons.schedule_rounded,
                        name: l.weekDiaryHours,
                        value:
                            '${figures.minutes ~/ 60}:'
                            '${(figures.minutes % 60).toString().padLeft(2, '0')}',
                        unit: 'h',
                        color: const Color(0xFF6FA8FF),
                      ),
                      FigureTile(
                        icon: Icons.check_circle_outline_rounded,
                        name: l.sessions,
                        value: '${figures.sessions}',
                        color: mint,
                      ),
                      FigureTile(
                        icon: Icons.route_rounded,
                        name: l.distance,
                        value: NumberFormat.decimalPattern(
                          locale,
                        ).format(figures.km.round()),
                        unit: 'km',
                        color: const Color(0xFF9D7BFF),
                      ),
                      FigureTile(
                        icon: Icons.local_fire_department_outlined,
                        name: l.load,
                        value: NumberFormat.decimalPattern(
                          locale,
                        ).format(figures.load.round()),
                        color: const Color(0xFFFFB13D),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ],
                  MarkdownBody(
                    data: widget.report.body,
                    selectable: true,
                    styleSheet: _reviewStyle(context),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.proAnalysisFrom(
                      DateFormat.MMMd(
                        locale,
                      ).add_Hm().format(widget.report.createdAt),
                    ),
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        title,
                        const SizedBox(height: 12),
                        if (figures != null && figures.sessions > 0) ...[
                          FigureGrid([
                            FigureTile(
                              icon: Icons.schedule_rounded,
                              name: l.weekDiaryHours,
                              value:
                                  '${figures.minutes ~/ 60}:'
                                  '${(figures.minutes % 60).toString().padLeft(2, '0')}',
                              unit: 'h',
                              color: const Color(0xFF6FA8FF),
                            ),
                            FigureTile(
                              icon: Icons.check_circle_outline_rounded,
                              name: l.sessions,
                              value: '${figures.sessions}',
                              color: mint,
                            ),
                            FigureTile(
                              icon: Icons.route_rounded,
                              name: l.distance,
                              value: NumberFormat.decimalPattern(
                                locale,
                              ).format(figures.km.round()),
                              unit: 'km',
                              color: const Color(0xFF9D7BFF),
                            ),
                            FigureTile(
                              icon: Icons.local_fire_department_outlined,
                              name: l.load,
                              value: NumberFormat.decimalPattern(
                                locale,
                              ).format(figures.load.round()),
                              color: const Color(0xFFFFB13D),
                            ),
                          ]),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          _preview(widget.report.body),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: fjInk70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  chevron,
                ],
              ),
      ),
    );
  }

  /// The review in the app's own type: section heads in the card's accent,
  /// calm body text, the figures it names in full ink.
  MarkdownStyleSheet _reviewStyle(BuildContext context) {
    final accent = widget.newest ? doneGradient : coachGradient;
    final head = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: .2,
      color: fjAccent(accent.first),
      height: 1.8,
    );
    final body = TextStyle(fontSize: 14, height: 1.55, color: fjInk70);
    return MarkdownStyleSheet(
      p: body,
      listBullet: body,
      strong: TextStyle(fontWeight: FontWeight.w700, color: fjInk),
      h1: head,
      h2: head,
      h3: head,
      h4: head,
      blockSpacing: 10,
      listIndent: 18,
    );
  }
}

/// The week's pictures as a slider: swipe through them, a tap opens them
/// full screen, where they can be swiped too.
class _WeekMedia extends StatefulWidget {
  const _WeekMedia({required this.items});
  final List<MediaItem> items;

  @override
  State<_WeekMedia> createState() => _WeekMediaState();
}

class _WeekMediaState extends State<_WeekMedia> {
  // A little of the next picture shows, so it is clear there are more.
  late final controller = PageController(
    viewportFraction: widget.items.length > 1 ? .88 : 1,
  );
  int page = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _open(int index) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => MediaViewer(items: widget.items, initialIndex: index),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: PageView.builder(
            key: const ValueKey('week-media-slider'),
            controller: controller,
            padEnds: false,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => page = i),
            itemBuilder: (context, i) {
              final item = items[i];
              final seconds = (item.durationMs ?? 0) ~/ 1000;
              return Padding(
                padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
                child: GestureDetector(
                  onTap: () => _open(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MediaThumb(item: item, large: true),
                        if (item.kind == 'video')
                          Positioned(
                            left: 10,
                            bottom: 8,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                                if (seconds > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      shadows: [Shadow(blurRadius: 4)],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 8),
          // Where in the week's pictures the slider is.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == page ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == page ? mint : fjInk24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
