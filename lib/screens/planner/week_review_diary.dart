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
    return SectionCard(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      onTap: () => setState(() => open = !open),
      child: AnimatedSize(
        duration: Duration(milliseconds: animate ? 260 : 0),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GradientTitle(
                    '${l.weekDiaryWeek(week)} · $range'.toUpperCase(),
                    colors: accent,
                  ),
                  const SizedBox(height: 12),
                  if (media.isNotEmpty) ...[
                    _WeekMedia(items: media),
                    const SizedBox(height: 12),
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
                  if (open) ...[
                    MarkdownBody(data: widget.report.body, selectable: true),
                    const SizedBox(height: 8),
                    Text(
                      l.proAnalysisFrom(
                        DateFormat.MMMd(
                          locale,
                        ).add_Hm().format(widget.report.createdAt),
                      ),
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ] else
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
            AnimatedRotation(
              turns: open ? .5 : 0,
              duration: Duration(milliseconds: animate ? 220 : 0),
              child: Icon(Icons.expand_more, size: 28, color: fjInk),
            ),
          ],
        ),
      ),
    );
  }
}

/// The week's pictures like a post: the first one wide, up to four more in
/// a row below. A tap opens them full screen.
class _WeekMedia extends StatelessWidget {
  const _WeekMedia({required this.items});
  final List<MediaItem> items;

  void _open(BuildContext context, int index) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => MediaViewer(items: items, initialIndex: index),
    ),
  );

  Widget _tile(BuildContext context, int index, {bool large = false}) {
    final item = items[index];
    final seconds = (item.durationMs ?? 0) ~/ 1000;
    return GestureDetector(
      onTap: () => _open(context, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaThumb(item: item, large: large),
            if (item.kind == 'video')
              Positioned(
                left: 8,
                bottom: 6,
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_fill_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    if (seconds > 0 && large) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AspectRatio(
        aspectRatio: items.length == 1 ? 4 / 3 : 16 / 10,
        child: _tile(context, 0, large: true),
      ),
      if (items.length > 1) ...[
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 1; i < 5; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: i < items.length
                      ? _tile(context, i)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ],
    ],
  );
}
