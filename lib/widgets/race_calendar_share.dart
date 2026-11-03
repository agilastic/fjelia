import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../db/database.dart';
import '../l10n/formats.dart';
import '../l10n/l10n_ext.dart';
import 'app_widgets.dart';
import 'media_share_card.dart';

/// The looks of a shared race calendar.
enum RaceCalendarStyle { poster, tickets, timeline, magazine }

String raceCalendarStyleName(RaceCalendarStyle style) => switch (style) {
  RaceCalendarStyle.poster => tr.raceShareStylePoster,
  RaceCalendarStyle.tickets => tr.raceShareStyleTickets,
  RaceCalendarStyle.timeline => tr.raceShareStyleTimeline,
  RaceCalendarStyle.magazine => tr.raceShareStyleMagazine,
};

/// One race as the image shows it.
class _Race {
  _Race(RaceGoal g, DateTime today, {required bool withTarget})
    : name = g.name,
      date = g.raceDate,
      priority = g.priority.toUpperCase(),
      km = g.distanceM / 1000,
      climb = g.elevationM,
      target = withTarget ? g.targetFinishSeconds : null,
      weeks = (g.raceDate.difference(today).inDays / 7).ceil().clamp(0, 999),
      sport = g.primarySport.toLowerCase();

  final String name, priority, sport;
  final DateTime date;
  final double km;
  final double? climb;
  final int? target;
  final int weeks;

  String get distance =>
      '${km >= 100 ? km.round().toString() : km.fixed(km == km.roundToDouble() ? 0 : 1)} km';

  String? get targetText {
    final t = target;
    if (t == null) return null;
    final h = t ~/ 3600, m = (t % 3600) ~/ 60, s = t % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  IconData get icon => switch (sport) {
    final s when s.contains('cycl') || s.contains('bik') =>
      Icons.directions_bike,
    final s when s.contains('swim') => Icons.pool,
    final s when s.contains('tri') => Icons.emoji_events_outlined,
    final s when s.contains('hik') || s.contains('walk') => Icons.hiking,
    final s when s.contains('ski') => Icons.downhill_skiing,
    _ => Icons.directions_run,
  };

  Color get priorityColor => switch (priority) {
    'A' => const Color(0xFFFF8A3D),
    'B' => const Color(0xFF4FC3F7),
    _ => const Color(0xFFB0BEC5),
  };
}

/// Up to eight races, soonest first; target times only when shown.
List<_Race> _races(List<RaceGoal> goals, {required bool withTarget}) {
  final today = DateUtils.dateOnly(DateTime.now());
  return [
    for (final g in [
      ...goals,
    ]..sort((a, b) => a.raceDate.compareTo(b.raceDate)))
      _Race(g, today, withTarget: withTarget),
  ].take(8).toList();
}

String _years(List<_Race> races) {
  if (races.isEmpty) return '';
  final first = races.first.date.year, last = races.last.date.year;
  return first == last ? '$first' : '$first–$last';
}

/// Preview of the race calendar in four styles and a button to share it
/// as a 1080 × 1350 image.
class RaceCalendarSharePage extends StatefulWidget {
  const RaceCalendarSharePage({super.key, required this.goals});
  final List<RaceGoal> goals;

  @override
  State<RaceCalendarSharePage> createState() => _RaceCalendarSharePageState();
}

class _RaceCalendarSharePageState extends State<RaceCalendarSharePage> {
  final _card = GlobalKey();
  RaceCalendarStyle _style = RaceCalendarStyle.poster;

  /// Target times are personal: off until the athlete shows them.
  bool _targets = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      title: Text(context.l10n.shareRaceCalendar),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                child: RepaintBoundary(
                  key: _card,
                  child: RaceCalendarCard(
                    goals: widget.goals,
                    style: _style,
                    showTargets: _targets,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final style in RaceCalendarStyle.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(raceCalendarStyleName(style)),
                      selected: _style == style,
                      onSelected: (_) => setState(() => _style = style),
                      selectedColor: mint.withValues(alpha: .25),
                      side: BorderSide(
                        color: _style == style ? mint : Colors.white24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            dense: true,
            secondary: const Icon(Icons.timer_outlined),
            title: Text(context.l10n.raceShareShowTarget),
            value: _targets,
            onChanged: (on) => setState(() => _targets = on),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Builder(
              builder: (buttonContext) => FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => runUiAction(
                  context,
                  () => shareRepaintBoundary(
                    _card,
                    buttonContext,
                    name: 'fjelia-races',
                  ),
                ),
                icon: const Icon(Icons.ios_share),
                label: Text(context.l10n.shareRaceCalendar),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The race calendar itself, 360 × 450 logical pixels.
class RaceCalendarCard extends StatelessWidget {
  const RaceCalendarCard({
    super.key,
    required this.goals,
    required this.style,
    this.showTargets = false,
  });
  final List<RaceGoal> goals;
  final RaceCalendarStyle style;
  final bool showTargets;

  @override
  Widget build(BuildContext context) {
    final races = _races(goals, withTarget: showTargets);
    final l10n = context.l10n;
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white, height: 1.15),
        child: SizedBox(
          width: 360,
          height: 450,
          child: switch (style) {
            RaceCalendarStyle.poster => _Poster(races, l10n.raceSeasonTitle),
            RaceCalendarStyle.tickets => _Tickets(races, l10n.raceSeasonTitle),
            RaceCalendarStyle.timeline => _Timeline(
              races,
              l10n.raceSeasonTitle,
            ),
            RaceCalendarStyle.magazine => _Magazine(
              races,
              l10n.raceSeasonTitle,
            ),
          },
        ),
      ),
    );
  }
}

/// The list area: races scale down together when there are many.
Widget _fit(Widget list) => Expanded(child: _FitToHeight(child: list));

/// Lays [child] out at the full width; when it is taller than the space,
/// lays it out wider and scales it down, so it fills the width exactly and
/// still fits the height (instead of shrinking into a narrow column).
class _FitToHeight extends SingleChildRenderObjectWidget {
  const _FitToHeight({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFitToHeight();
}

class _RenderFitToHeight extends RenderProxyBox {
  double _scale = 1;

  @override
  void performLayout() {
    final width = constraints.maxWidth, height = constraints.maxHeight;
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;
    child.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
    _scale = 1;
    if (child.size.height > height) {
      // Wider by as much as it must shrink: after scaling it is full width.
      child.layout(
        BoxConstraints.tightFor(width: width * child.size.height / height),
        parentUsesSize: true,
      );
      _scale = [
        1.0,
        height / child.size.height,
        width / child.size.width,
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    context.pushTransform(
      needsCompositing,
      offset,
      Matrix4.diagonal3Values(_scale, _scale, 1),
      (context, offset) => context.paintChild(child, offset),
    );
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) =>
      transform.multiply(Matrix4.diagonal3Values(_scale, _scale, 1));

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      false;
}

// ── Poster: dark gradient, big date blocks ──────────────────────────────────
class _Poster extends StatelessWidget {
  const _Poster(this.races, this.title);
  final List<_Race> races;
  final String title;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A1405), Color(0xFF111418), Color(0xFF07131C)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFF8A3D),
          ),
        ),
        Text(
          _years(races),
          style: const TextStyle(
            fontSize: 44,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 14),
        _fit(
          Column(
            children: [
              for (final r in races)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: r.priorityColor.withValues(alpha: .4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: r.priorityColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${r.date.day}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              DateFormat.MMM().format(r.date).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(r.icon, size: 12, color: Colors.white60),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    [
                                      r.distance,
                                      if (r.climb != null && r.climb! > 0)
                                        '+${r.climb!.round()} m',
                                      ?r.targetText,
                                    ].join('  ·  '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Badge(r.priority, r.priorityColor),
                          const SizedBox(height: 3),
                          Text(
                            context.l10n.gWk(r.weeks),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const FjeliaSignature(),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color, {this.dark = false});
  final String text;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: dark ? 1 : .2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: dark ? Colors.white : color,
      ),
    ),
  );
}

// ── Tickets: one stub per race ──────────────────────────────────────────────
class _Tickets extends StatelessWidget {
  const _Tickets(this.races, this.title);
  final List<_Race> races;
  final String title;

  static const _mono = TextStyle(
    fontFamily: 'Courier',
    fontFamilyFallback: ['Menlo', 'Courier New', 'monospace'],
    color: Color(0xFF1C1C1C),
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
    color: const Color(0xFF16324F),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${title.toUpperCase()} ${_years(races)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _fit(
          Column(
            children: [
              for (final r in races)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipPath(
                    clipper: const _TicketClipper(),
                    child: Container(
                      height: 64,
                      color: const Color(0xFFFFF6E5),
                      child: Row(
                        children: [
                          Container(width: 8, color: r.priorityColor),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    r.name.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _mono.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      r.distance.toUpperCase(),
                                      if (r.climb != null && r.climb! > 0)
                                        '+${r.climb!.round()} M',
                                      ?r.targetText,
                                    ].join('  '),
                                    style: _mono.copyWith(fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // The perforated stub: date and priority.
                          const SizedBox(
                            width: 2,
                            height: 64,
                            child: CustomPaint(painter: _Perforation()),
                          ),
                          SizedBox(
                            width: 70,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('dd MMM')
                                      .format(r.date)
                                      .toUpperCase(),
                                  style: _mono.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${r.date.year}',
                                  style: _mono.copyWith(fontSize: 9.5),
                                ),
                                const SizedBox(height: 2),
                                _Badge(r.priority, r.priorityColor, dark: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const FjeliaSignature(),
      ],
    ),
  );
}

/// Half-circle notches at the stub line, top and bottom.
class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper();

  @override
  Path getClip(Size size) {
    final x = size.width - 72;
    return Path.combine(
      PathOperation.difference,
      Path()..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      ),
      Path()
        ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: 7))
        ..addOval(Rect.fromCircle(center: Offset(x, size.height), radius: 7)),
    );
  }

  @override
  bool shouldReclip(_TicketClipper old) => false;
}

class _Perforation extends CustomPainter {
  const _Perforation();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 1.2;
    for (var y = 9.0; y < size.height - 8; y += 6) {
      canvas.drawLine(Offset(1, y), Offset(1, y + 3), paint);
    }
  }

  @override
  bool shouldRepaint(_Perforation old) => false;
}

// ── Neon timeline: glowing nodes on a vertical line ─────────────────────────
class _Timeline extends StatelessWidget {
  const _Timeline(this.races, this.title);
  final List<_Race> races;
  final String title;

  static const _pink = Color(0xFFFF3EC8), _cyan = Color(0xFF3EF2FF);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(-.6, -.8),
        radius: 1.4,
        colors: [Color(0xFF2A0F4A), Color(0xFF07020F)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (rect) =>
              const LinearGradient(colors: [_cyan, _pink]).createShader(rect),
          child: Text(
            '${title.toUpperCase()}\n${_years(races)}',
            style: const TextStyle(
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              shadows: [Shadow(color: _pink, blurRadius: 16)],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _fit(
          Column(
            children: [
              for (final (i, r) in races.indexed)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 26,
                        child: CustomPaint(
                          painter: _NodePainter(
                            color: i.isEven ? _cyan : _pink,
                            first: i == 0,
                            last: i == races.length - 1,
                            big: r.priority == 'A',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateFormat.MMMd().format(r.date).toUpperCase()}  ·  ${context.l10n.gWk(r.weeks)}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w800,
                                  color: i.isEven ? _cyan : _pink,
                                ),
                              ),
                              Text(
                                r.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                [
                                  r.priority,
                                  r.distance,
                                  if (r.climb != null && r.climb! > 0)
                                    '+${r.climb!.round()} m',
                                  ?r.targetText,
                                ].join('  •  '),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFE2D4FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const FjeliaSignature(color: Color(0xFFFFD6F5)),
      ],
    ),
  );
}

class _NodePainter extends CustomPainter {
  _NodePainter({
    required this.color,
    required this.first,
    required this.last,
    required this.big,
  });
  final Color color;
  final bool first, last, big;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    const y = 12.0;
    final line = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 2;
    if (!first) canvas.drawLine(Offset(x, 0), Offset(x, y), line);
    if (!last) canvas.drawLine(Offset(x, y), Offset(x, size.height), line);
    final r = big ? 8.0 : 6.0;
    canvas
      ..drawCircle(
        Offset(x, y),
        r * 2,
        Paint()
          ..color = color.withValues(alpha: .5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawCircle(Offset(x, y), r, Paint()..color = color)
      ..drawCircle(Offset(x, y), r * .45, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_NodePainter old) => false;
}

// ── Magazine: light paper, serif, thin rules ────────────────────────────────
class _Magazine extends StatelessWidget {
  const _Magazine(this.races, this.title);
  final List<_Race> races;
  final String title;

  static const _ink = Color(0xFF1E1B18);
  static const _serif = TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: ['Times New Roman', 'serif'],
    color: _ink,
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
    color: const Color(0xFFF5F0E6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'N° ${_years(races)}',
          style: _serif.copyWith(
            fontSize: 11,
            letterSpacing: 2,
            color: const Color(0xFF8A7F72),
          ),
        ),
        Text(
          title,
          style: _serif.copyWith(
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, color: _ink),
        const SizedBox(height: 2),
        Container(height: .6, color: _ink),
        const SizedBox(height: 10),
        _fit(
          Column(
            children: [
              for (final (i, r) in races.indexed) ...[
                if (i > 0)
                  Container(height: .6, color: const Color(0x55000000)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 54,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r.date.day}',
                              style: _serif.copyWith(
                                fontSize: 26,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              DateFormat.MMM().format(r.date).toUpperCase(),
                              style: _serif.copyWith(
                                fontSize: 9,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _serif.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              [
                                r.distance,
                                if (r.climb != null && r.climb! > 0)
                                  '${r.climb!.round()} m',
                                ?r.targetText,
                              ].join(' — '),
                              style: _serif.copyWith(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFF5A524A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        r.priority,
                        style: _serif.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: r.priority == 'A'
                              ? const Color(0xFFC0392B)
                              : const Color(0xFF8A7F72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(height: .6, color: _ink),
        const SizedBox(height: 8),
        const FjeliaSignature(color: _ink),
      ],
    ),
  );
}
