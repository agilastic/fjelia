import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/formats.dart';
import '../l10n/l10n_ext.dart';
import '../screens/planner/plan_week_agenda.dart' show sportLabel;
import '../services/media_route.dart';
import 'app_widgets.dart';

/// The workout facts printed on a share card.
class ActivityShareInfo {
  const ActivityShareInfo({
    required this.title,
    required this.date,
    required this.duration,
    this.distanceMeters,
    this.paceSecPerKm,
    this.watts,
    this.ascentMeters,
    this.avgHeartRate,
    this.sport,
    this.route = const [],
  });

  final String title;

  /// Average heart rate, bpm.
  final double? avgHeartRate;

  /// The activity type, for the icon next to the date.
  final String? sport;
  final DateTime date;
  final Duration duration;
  final double? distanceMeters, ascentMeters, watts;
  final int? paceSecPerKm;
  final List<RoutePoint> route;
}

/// Renders [boundary] at 3× (360 × 450 becomes 1080 × 1350, the 4:5 feeds
/// expect) and opens the share sheet with it as a PNG.
Future<void> shareRepaintBoundary(
  GlobalKey boundary,
  BuildContext buttonContext, {
  String name = 'fjelia-card',
}) async {
  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await render.toImage(pixelRatio: 3);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (png == null) return;
  final file = File(
    '${(await getTemporaryDirectory()).path}/$name-${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(png.buffer.asUint8List());
  if (!buttonContext.mounted) return;
  final box = buttonContext.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

/// Preview of the card (photo, facts, route) and a button to share it as a
/// 1080 × 1350 image.
class MediaShareCardPage extends StatefulWidget {
  const MediaShareCardPage({
    super.key,
    required this.info,
    this.photos = const [],
    this.initialPhoto,
  });
  final ActivityShareInfo info;

  /// The activity's photos to choose from; without any, the card shows the
  /// route on a dark background.
  final List<File> photos;

  /// Index into [photos] to start with; null starts with the route.
  final int? initialPhoto;

  @override
  State<MediaShareCardPage> createState() => _MediaShareCardPageState();
}

class _MediaShareCardPageState extends State<MediaShareCardPage> {
  final _card = GlobalKey();
  bool _loaded = false;
  late int? _photo = widget.initialPhoto ?? (widget.photos.isEmpty ? null : 0);
  ShareCardStyle _style = ShareCardStyle.glass;
  static const _styleKey = 'share_card_style';

  @override
  void initState() {
    super.initState();
    // The look used last time comes back.
    SharedPreferences.getInstance()
        .then((prefs) {
          final saved = ShareCardStyle.values
              .where((s) => s.name == prefs.getString(_styleKey))
              .firstOrNull;
          if (saved != null && mounted) setState(() => _style = saved);
        })
        .catchError((Object _) {});
  }

  void _chooseStyle(ShareCardStyle style) {
    setState(() => _style = style);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_styleKey, style.name))
        .catchError((Object _) => false);
  }

  // Panel and route tile positions; the athlete drags them on the preview.
  final _panelKey = GlobalKey(), _tileKey = GlobalKey();
  double _panelY = 1;
  Alignment _tile = Alignment.topRight;
  String? _dragging;
  Offset? _last;

  /// How the photo is framed: zoom ≥ 1 and pan from -1 to 1 on each axis.
  double _zoom = 1;
  Offset _pan = Offset.zero;
  double _zoomAtStart = 1;

  RenderBox? _box(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  bool _hit(GlobalKey key, Offset global) {
    final box = _box(key);
    return box != null &&
        (Offset.zero & box.size).contains(box.globalToLocal(global));
  }

  void _gestureStart(ScaleStartDetails d) {
    // One finger on the tile or the panel moves it; anything else frames
    // the photo (pinch to zoom, drag to move it). The tile lies above the
    // panel where they overlap.
    _dragging = d.pointerCount == 1 && _hit(_tileKey, d.focalPoint)
        ? 'tile'
        : d.pointerCount == 1 && _hit(_panelKey, d.focalPoint)
        ? 'panel'
        : _photo != null
        ? 'photo'
        : null;
    _last = _box(_card)?.globalToLocal(d.focalPoint);
    _zoomAtStart = _zoom;
  }

  void _gestureUpdate(ScaleUpdateDetails d) {
    final card = _box(_card);
    if (_dragging == null || card == null || _last == null) return;
    // In card coordinates, so the preview's scaling doesn't matter.
    final now = card.globalToLocal(d.focalPoint);
    final delta = now - _last!;
    _last = now;
    setState(() {
      switch (_dragging) {
        case 'panel':
          final height = _box(_panelKey)?.size.height ?? 200;
          final travel = (card.size.height - 24 - height) / 2;
          if (travel > 0) {
            _panelY = (_panelY + delta.dy / travel).clamp(-1.0, 1.0);
          }
        case 'tile':
          final travelX = (card.size.width - 28 - 92) / 2;
          final travelY = (card.size.height - 28 - 92) / 2;
          _tile = Alignment(
            (_tile.x + delta.dx / travelX).clamp(-1.0, 1.0),
            (_tile.y + delta.dy / travelY).clamp(-1.0, 1.0),
          );
        case 'photo':
          _zoom = (_zoomAtStart * d.scale).clamp(1.0, 4.0);
          // A zoomed photo moves as far as it still covers the card.
          final reachX = (_zoom - 1) * card.size.width / 2;
          final reachY = (_zoom - 1) * card.size.height / 2;
          _pan = Offset(
            reachX > 0 ? (_pan.dx + delta.dx / reachX).clamp(-1.0, 1.0) : 0,
            reachY > 0 ? (_pan.dy + delta.dy / reachY).clamp(-1.0, 1.0) : 0,
          );
      }
    });
  }

  void _resetPhoto() => setState(() {
    _zoom = 1;
    _pan = Offset.zero;
  });

  void _choose(int? photo) {
    if (photo == _photo) return;
    setState(() {
      _photo = photo;
      _loaded = false;
    });
  }

  Future<void> _share(BuildContext buttonContext) =>
      shareRepaintBoundary(_card, buttonContext);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      title: Text(context.l10n.mediaShareCard),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                child: GestureDetector(
                  onScaleStart: _gestureStart,
                  onScaleUpdate: _gestureUpdate,
                  onScaleEnd: (_) => _dragging = null,
                  onDoubleTap: _resetPhoto,
                  child: RepaintBoundary(
                    key: _card,
                    child: ShareCard(
                      panelY: _panelY,
                      photoZoom: _zoom,
                      photoPan: _pan,
                      tileAlignment: _tile,
                      panelKey: _panelKey,
                      tileKey: _tileKey,
                      // A new card per choice, so loading is reported again.
                      key: ValueKey(_photo),
                      style: _style,
                      photo: _photo == null ? null : widget.photos[_photo!],
                      info: widget.info,
                      onLoaded: () {
                        if (mounted && !_loaded) setState(() => _loaded = true);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            context.l10n.mediaShareCardHint,
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final style in ShareCardStyle.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(shareCardStyleName(style)),
                      selected: _style == style,
                      onSelected: (_) => _chooseStyle(style),
                      selectedColor: mint.withValues(alpha: .25),
                      side: BorderSide(
                        color: _style == style ? mint : Colors.white24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (widget.photos.isNotEmpty)
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _Choice(
                    selected: _photo == null,
                    onTap: () => _choose(null),
                    child: const ColoredBox(
                      color: Color(0xFF0E2A2E),
                      child: Icon(Icons.route, color: mint),
                    ),
                  ),
                  for (final (i, file) in widget.photos.indexed)
                    _Choice(
                      selected: _photo == i,
                      onTap: () => _choose(i),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                        cacheWidth: 180,
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (buttonContext) => FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _loaded
                    ? () => runUiAction(context, () => _share(buttonContext))
                    : null,
                icon: const Icon(Icons.ios_share),
                label: Text(context.l10n.mediaShareCard),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? mint : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.expand(child: child),
        ),
      ),
    ),
  );
}

/// The looks a share card can have.
enum ShareCardStyle {
  glass,
  poster,
  minimal,
  neon,
  sticker,
  receipt,
  kpop,
  pixel,
  robot,
  scifi,
  card,
  comic,
  outdoor,
  holo,
  holoFull,
}

String shareCardStyleName(ShareCardStyle style) => switch (style) {
  ShareCardStyle.glass => tr.shareStyleGlass,
  ShareCardStyle.poster => tr.shareStylePoster,
  ShareCardStyle.minimal => tr.shareStyleMinimal,
  ShareCardStyle.neon => tr.shareStyleNeon,
  ShareCardStyle.sticker => tr.shareStyleSticker,
  ShareCardStyle.receipt => tr.shareStyleReceipt,
  ShareCardStyle.kpop => tr.shareStyleKpop,
  ShareCardStyle.pixel => tr.shareStylePixel,
  ShareCardStyle.robot => tr.shareStyleRobot,
  ShareCardStyle.scifi => tr.shareStyleScifi,
  ShareCardStyle.card => tr.shareStyleCard,
  ShareCardStyle.comic => tr.shareStyleComic,
  ShareCardStyle.outdoor => tr.shareStyleOutdoor,
  ShareCardStyle.holo => tr.shareStyleHolo,
  ShareCardStyle.holoFull => tr.shareStyleHoloFull,
};

/// The facts of an activity, formatted once for every style.
class _Facts {
  _Facts(this.info, BuildContext context) {
    final km = info.distanceMeters;
    final pace = info.paceSecPerKm;
    final l10n = context.l10n;
    if (km != null && km > 0) {
      distance = (km / 1000).fixed(km >= 100000 ? 1 : 2);
    }
    time = _clock(info.duration);
    if (info.watts != null) {
      effort = ('${info.watts!.round()}', 'W', l10n.avgPower);
    } else if (pace != null) {
      effort = (
        '${pace ~/ 60}:${(pace % 60).toString().padLeft(2, '0')}',
        '/km',
        l10n.avgPace,
      );
    }
    if (info.ascentMeters != null && info.ascentMeters! >= 1) {
      ascent = '${info.ascentMeters!.round()} m';
    }
    if (info.avgHeartRate != null && info.avgHeartRate! > 0) {
      heartRate = '${info.avgHeartRate!.round()} bpm';
    }
    date = DateFormat.yMMMEd().format(info.date.toLocal());
    labels = (
      distance: l10n.distance,
      time: l10n.duration,
      ascent: l10n.elevation2,
      heartRate: l10n.avgHr,
    );
  }

  final ActivityShareInfo info;
  String? distance, ascent, heartRate;
  late final String time, date;
  (String, String, String)? effort;
  late final ({String distance, String time, String ascent, String heartRate})
  labels;

  /// Value and unit of the headline numbers, best first.
  List<(String, String)> hero(String timeUnit) => [
    if (distance != null) (distance!, 'km'),
    (time, timeUnit),
    if (effort != null) (effort!.$1, effort!.$2),
  ];

  static String _clock(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  IconData get sportIcon => switch ((info.sport ?? '').toLowerCase()) {
    final s
        when s.contains('cycl') || s.contains('bik') || s.contains('ride') =>
      Icons.directions_bike,
    final s when s.contains('swim') => Icons.pool,
    final s when s.contains('hik') || s.contains('walk') => Icons.hiking,
    final s when s.contains('ski') => Icons.downhill_skiing,
    _ => Icons.directions_run,
  };
}

/// The card itself, 360 × 450 logical pixels: the photo (or the route) with
/// the workout's numbers on top in one of six styles, and the Fjelia mark.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.info,
    this.photo,
    this.onLoaded,
    this.style = ShareCardStyle.glass,
    this.panelY = 1,
    this.tileAlignment = Alignment.topRight,
    this.panelKey,
    this.tileKey,
    this.photoZoom = 1,
    this.photoPan = Offset.zero,
  });

  /// How the athlete framed the photo: zoom ≥ 1, pan -1…1 per axis.
  final double photoZoom;
  final Offset photoPan;

  /// Without a photo the route, drawn large, is the picture.
  final File? photo;
  final ActivityShareInfo info;
  final VoidCallback? onLoaded;
  final ShareCardStyle style;

  /// Where the panel sits: -1 top, 1 bottom (the athlete drags it).
  final double panelY;

  /// Where the route tile sits on a photo.
  final Alignment tileAlignment;

  /// Let the share screen find the panel and the tile under a finger.
  final Key? panelKey, tileKey;

  static const accent = Color(0xFF00D4A0);
  static const warm = Color(0xFFFFB347);

  @override
  Widget build(BuildContext context) {
    final facts = _Facts(info, context);
    final hasTile = photo != null && info.route.length > 1;
    final overlay = _Overlay(
      facts: facts,
      panelY: panelY,
      tileAlignment: tileAlignment,
      panelKey: panelKey,
      tileKey: tileKey,
      showTile: hasTile,
    );
    // The card brings its own text style and material, so the shared image
    // looks the same wherever it is drawn.
    if (style == ShareCardStyle.holo || style == ShareCardStyle.holoFull) {
      // The whole image is the card; the photo sits in its window.
      return Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white, height: 1.1),
          child: SizedBox(
            width: 360,
            height: 450,
            child: _HoloCard(
              facts: facts,
              photo: photo,
              onLoaded: onLoaded,
              panelKey: panelKey,
              zoom: photoZoom,
              pan: photoPan,
              fullArt: style == ShareCardStyle.holoFull,
              panelY: panelY,
              tileAlignment: tileAlignment,
              tileKey: tileKey,
            ),
          ),
        ),
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white, height: 1.1),
        child: SizedBox(
          width: 360,
          height: 450,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo case final photo?)
                _FramedPhoto(
                  file: photo,
                  zoom: photoZoom,
                  pan: photoPan,
                  onLoaded: onLoaded,
                )
              else
                _RouteBackdrop(
                  // The receipt and the trading card show the route themselves.
                  route:
                      style == ShareCardStyle.receipt ||
                          style == ShareCardStyle.card
                      ? const []
                      : info.route,
                  onLoaded: onLoaded,
                  panelY: panelY,
                  palette: _Palette.of(style),
                  plain:
                      style == ShareCardStyle.receipt ||
                      style == ShareCardStyle.card,
                  // Room the style's block takes, kept clear of the route.
                  reserve: switch (style) {
                    ShareCardStyle.poster => 300,
                    ShareCardStyle.sticker => 250,
                    ShareCardStyle.neon => 190,
                    ShareCardStyle.minimal => 130,
                    ShareCardStyle.comic => 270,
                    ShareCardStyle.robot || ShareCardStyle.outdoor => 245,
                    _ => 230,
                  },
                ),
              _scrim(style),
              ...switch (style) {
                ShareCardStyle.glass => overlay.glass(context),
                ShareCardStyle.poster => overlay.poster(context),
                ShareCardStyle.minimal => overlay.minimal(context),
                ShareCardStyle.neon => overlay.neon(context),
                ShareCardStyle.sticker => overlay.sticker(context),
                ShareCardStyle.receipt => overlay.receipt(context),
                ShareCardStyle.kpop => overlay.kpop(context),
                ShareCardStyle.pixel => overlay.pixel(context),
                ShareCardStyle.robot => overlay.robot(context),
                ShareCardStyle.scifi => overlay.scifi(context),
                ShareCardStyle.card => overlay.card(context),
                ShareCardStyle.comic => overlay.comic(context),
                ShareCardStyle.outdoor => overlay.outdoor(context),
                ShareCardStyle.holo || ShareCardStyle.holoFull => const [],
              },
            ],
          ),
        ),
      ),
    );
  }

  /// Shade over the picture, so each style's text reads on bright photos.
  static Widget _scrim(ShareCardStyle style) => switch (style) {
    ShareCardStyle.glass || ShareCardStyle.minimal => const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x33000000), Colors.transparent, Color(0x99000000)],
          stops: [0, .35, 1],
        ),
      ),
    ),
    ShareCardStyle.poster => const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x66000000), Color(0x11000000), Color(0xB3000000)],
          stops: [0, .45, 1],
        ),
      ),
    ),
    ShareCardStyle.neon => const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.0,
          colors: [Color(0x33140A2E), Color(0xCC0A0418)],
        ),
      ),
    ),
    ShareCardStyle.sticker ||
    ShareCardStyle.receipt ||
    ShareCardStyle.holo ||
    ShareCardStyle.holoFull ||
    ShareCardStyle.pixel ||
    ShareCardStyle.comic => const SizedBox(),
    ShareCardStyle.kpop => const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x22FF8AD8), Colors.transparent, Color(0x55B07CFF)],
        ),
      ),
    ),
    ShareCardStyle.scifi => const DecoratedBox(
      decoration: BoxDecoration(color: Color(0x5502101C)),
    ),
    ShareCardStyle.robot ||
    ShareCardStyle.card ||
    ShareCardStyle.outdoor => const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.transparent, Color(0x99000000)],
          stops: [0, .4, 1],
        ),
      ),
    ),
  };
}

/// Places [child] where the athlete moved it, inside the card's margin.
class _Placed extends StatelessWidget {
  const _Placed({
    required this.alignment,
    required this.child,
    this.margin = 12,
  });
  final Alignment alignment;
  final Widget child;
  final double margin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(margin),
    child: Align(alignment: alignment, child: child),
  );
}

/// App icon, name and address: the signature on every shared image.
class FjeliaSignature extends StatelessWidget {
  const FjeliaSignature({super.key, this.color = Colors.white, this.size = 1});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(5 * size),
        child: Image.asset(
          'assets/branding/app-icon-original.png',
          width: 18 * size,
          height: 18 * size,
        ),
      ),
      SizedBox(width: 6 * size),
      Text(
        'Fjelia',
        style: TextStyle(
          color: color,
          fontSize: 13 * size,
          fontWeight: FontWeight.w800,
          letterSpacing: .3,
        ),
      ),
      Text(
        '  ·  fjelia.com',
        style: TextStyle(
          color: color.withValues(alpha: .75),
          fontSize: 11 * size,
          letterSpacing: .4,
        ),
      ),
    ],
  );
}

/// The six looks. Each returns the layers above the picture; the main block
/// carries [panelKey] and the route tile [tileKey], so both can be moved.
class _Overlay {
  const _Overlay({
    required this.facts,
    required this.panelY,
    required this.tileAlignment,
    required this.panelKey,
    required this.tileKey,
    required this.showTile,
  });

  final _Facts facts;
  final double panelY;
  final Alignment tileAlignment;
  final Key? panelKey, tileKey;
  final bool showTile;

  ActivityShareInfo get info => facts.info;

  Widget _tile({
    required double size,
    required RouteOutlinePainter painter,
    BoxDecoration? decoration,
    double angle = 0,
    EdgeInsets padding = const EdgeInsets.all(10),
  }) => _Placed(
    alignment: tileAlignment,
    margin: 14,
    child: Transform.rotate(
      angle: angle,
      child: Container(
        key: tileKey,
        width: size,
        height: size,
        padding: padding,
        decoration: decoration,
        child: CustomPaint(painter: painter),
      ),
    ),
  );

  // ── Glass: frosted panel, glowing route tile ──────────────────────────────
  List<Widget> glass(BuildContext context) => [
    if (showTile)
      _Placed(
        alignment: tileAlignment,
        margin: 14,
        child: SizedBox(
          key: tileKey,
          width: 92,
          height: 92,
          child: _Glass(
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: CustomPaint(painter: RouteOutlinePainter(info.route)),
            ),
          ),
        ),
      ),
    _Placed(
      alignment: Alignment(0, panelY),
      child: _Glass(
        key: panelKey,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(facts.sportIcon, size: 13, color: ShareCard.accent),
                  const SizedBox(width: 5),
                  Text(
                    facts.date,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final (i, (value, unit))
                      in facts.hero(facts.labels.time).indexed) ...[
                    if (i > 0)
                      Container(
                        width: 1,
                        height: 34,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: Colors.white24,
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.8,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          Text(
                            unit.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9.5,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              color: ShareCard.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (facts.ascent != null || facts.heartRate != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (facts.ascent case final ascent?) ...[
                      const Icon(
                        Icons.north_east,
                        size: 13,
                        color: ShareCard.warm,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ascent,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    if (facts.heartRate case final hr?) ...[
                      const Icon(
                        Icons.favorite,
                        size: 13,
                        color: Color(0xFFFF6B6B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hr,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white12),
              const SizedBox(height: 9),
              const FjeliaSignature(),
            ],
          ),
        ),
      ),
    ),
  ];

  // ── Poster: huge stacked numbers, magazine cover ──────────────────────────
  List<Widget> poster(BuildContext context) {
    const shadow = [Shadow(blurRadius: 12, color: Color(0x99000000))];
    return [
      if (showTile)
        _tile(
          size: 104,
          padding: const EdgeInsets.all(4),
          painter: RouteOutlinePainter(
            info.route,
            startColor: Colors.white,
            endColor: Colors.white,
            glowColor: const Color(0x66000000),
          ),
        ),
      _Placed(
        alignment: Alignment(-1, panelY),
        margin: 20,
        child: Column(
          key: panelKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              info.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                shadows: shadow,
              ),
            ),
            const SizedBox(height: 6),
            for (final (value, unit) in facts.hero(facts.labels.time))
              // A long time or a long unit shrinks instead of running off.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 58,
                          height: .95,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2.5,
                          shadows: shadow,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        unit.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: ShareCard.accent,
                          shadows: shadow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              [facts.date, ?facts.ascent, ?facts.heartRate].join('  /  '),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: .8,
                color: Colors.white70,
                shadows: shadow,
              ),
            ),
            const SizedBox(height: 10),
            const FjeliaSignature(),
          ],
        ),
      ),
    ];
  }

  // ── Minimal: one fine line ────────────────────────────────────────────────
  List<Widget> minimal(BuildContext context) {
    final line = [
      if (facts.distance != null) '${facts.distance} km',
      facts.time,
      if (facts.effort case final e?) '${e.$1} ${e.$2}',
    ].join('   ·   ');
    return [
      if (showTile)
        _tile(
          size: 72,
          padding: const EdgeInsets.all(2),
          painter: RouteOutlinePainter(
            info.route,
            thickness: .7,
            startColor: Colors.white,
            endColor: Colors.white,
            glowColor: Colors.transparent,
            dots: false,
          ),
        ),
      _Placed(
        alignment: Alignment(0, panelY),
        margin: 22,
        child: Column(
          key: panelKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              info.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: .4,
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 28, height: 1, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              line,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: .6,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 12),
            const FjeliaSignature(size: .8),
          ],
        ),
      ),
    ];
  }

  // ── Neon: chrome numbers, magenta/cyan glow ───────────────────────────────
  List<Widget> neon(BuildContext context) {
    const pink = Color(0xFFFF3EC8), cyan = Color(0xFF3EF2FF);
    const glow = [
      Shadow(blurRadius: 18, color: pink),
      Shadow(blurRadius: 6, color: cyan),
    ];
    Widget chrome(Widget child) => ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFFFC2F0), cyan],
      ).createShader(rect),
      child: child,
    );
    return [
      if (showTile)
        _tile(
          size: 120,
          padding: const EdgeInsets.all(8),
          painter: RouteOutlinePainter(
            info.route,
            thickness: 1.3,
            startColor: cyan,
            endColor: pink,
            glowColor: pink,
          ),
        ),
      _Placed(
        alignment: Alignment(0, panelY),
        margin: 18,
        child: Column(
          key: panelKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              info.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: cyan,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                shadows: [Shadow(blurRadius: 10, color: cyan)],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final (value, unit) in facts.hero(facts.labels.time))
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        children: [
                          chrome(
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: -1.2,
                                shadows: glow,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          Text(
                            unit.toUpperCase(),
                            style: const TextStyle(
                              color: pink,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              shadows: [Shadow(blurRadius: 8, color: pink)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              [facts.date, ?facts.ascent, ?facts.heartRate].join('  •  '),
              style: const TextStyle(fontSize: 11, color: Color(0xFFE8D9FF)),
            ),
            const SizedBox(height: 10),
            const FjeliaSignature(color: Color(0xFFFFD6F5)),
          ],
        ),
      ),
    ];
  }

  // ── Sticker: colourful badges stuck on the photo ──────────────────────────
  List<Widget> sticker(BuildContext context) {
    Widget badge(
      String text,
      Color color, {
      double angle = 0,
      IconData? icon,
      Color ink = Colors.black,
      double size = 20,
    }) => Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 8,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: size * .8, color: ink),
              const SizedBox(width: 5),
            ],
            Text(
              text,
              style: TextStyle(
                color: ink,
                fontSize: size,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
          ],
        ),
      ),
    );
    final badges = <Widget>[
      badge(info.title, Colors.white, angle: -.04, size: 15),
      if (facts.distance != null)
        badge(
          '${facts.distance} km',
          const Color(0xFFC6FF3D),
          angle: .05,
          icon: facts.sportIcon,
          size: 26,
        ),
      badge(
        facts.time,
        const Color(0xFFFF8AD8),
        angle: -.06,
        icon: Icons.timer,
      ),
      if (facts.effort case final e?)
        badge(
          '${e.$1} ${e.$2}',
          const Color(0xFF8AD8FF),
          angle: .04,
          icon: Icons.bolt,
        ),
      if (facts.ascent case final ascent?)
        badge(
          ascent,
          const Color(0xFFFFE15A),
          angle: -.03,
          icon: Icons.terrain,
          size: 16,
        ),
      if (facts.heartRate case final hr?)
        badge(
          hr,
          const Color(0xFFFF6B6B),
          angle: .06,
          icon: Icons.favorite,
          ink: Colors.white,
          size: 16,
        ),
      Transform.rotate(
        angle: -.02,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const FjeliaSignature(size: .85),
        ),
      ),
    ];
    return [
      if (showTile)
        _tile(
          size: 100,
          angle: .08,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 8,
                offset: Offset(2, 3),
              ),
            ],
          ),
          painter: RouteOutlinePainter(
            info.route,
            startColor: const Color(0xFF111111),
            endColor: const Color(0xFFFF3EC8),
            glowColor: Colors.transparent,
          ),
        ),
      _Placed(
        alignment: Alignment(-1, panelY),
        margin: 18,
        child: SizedBox(
          width: 300,
          child: Wrap(
            key: panelKey,
            spacing: 6,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: badges,
          ),
        ),
      ),
    ];
  }

  // ── Receipt: a till slip for the workout ──────────────────────────────────
  List<Widget> receipt(BuildContext context) {
    const ink = Color(0xFF1C1C1C);
    const mono = TextStyle(
      color: ink,
      fontFamily: 'Courier',
      fontFamilyFallback: ['Menlo', 'Courier New', 'monospace'],
      fontSize: 11.5,
      height: 1.35,
    );
    Widget row(String label, String value) => Row(
      children: [
        Text(label.toUpperCase(), style: mono),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            '..............................................',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: mono,
          ),
        ),
        const SizedBox(width: 6),
        Text(value, style: mono.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
    final dashes = Text(
      '- ' * 30,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: mono.copyWith(color: const Color(0xFF8A8A8A)),
    );
    return [
      _Placed(
        alignment: Alignment(0, panelY),
        margin: 18,
        child: Transform.rotate(
          angle: -.025,
          child: ClipPath(
            key: panelKey,
            clipper: const _TornEdges(),
            child: Container(
              width: 236,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F6EF),
                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/branding/app-icon-original.png',
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'FJELIA',
                    style: mono.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    info.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: mono,
                  ),
                  Text(facts.date, style: mono),
                  dashes,
                  if (facts.distance != null)
                    row(facts.labels.distance, '${facts.distance} km'),
                  row(facts.labels.time, facts.time),
                  if (facts.effort case final e?) row(e.$3, '${e.$1} ${e.$2}'),
                  if (facts.ascent case final ascent?)
                    row(facts.labels.ascent, ascent),
                  if (facts.heartRate case final hr?)
                    row(facts.labels.heartRate, hr),
                  dashes,
                  if (info.route.length > 1)
                    SizedBox(
                      height: 64,
                      child: CustomPaint(
                        size: const Size(200, 64),
                        painter: RouteOutlinePainter(
                          info.route,
                          thickness: .8,
                          startColor: ink,
                          endColor: ink,
                          glowColor: Colors.transparent,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 30,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _BarcodePainter(
                        info.date.millisecondsSinceEpoch,
                        ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('fjelia.com', style: mono.copyWith(letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  /// The three headline numbers as (value, unit, label).
  List<(String, String, String)> get _rows => [
    if (facts.distance != null) (facts.distance!, 'km', facts.labels.distance),
    (facts.time, '', facts.labels.time),
    if (facts.effort case final e?) (e.$1, e.$2, e.$3),
  ];

  // ── K-Pop: pastel gradient, sparkles, glossy hearts ───────────────────────
  List<Widget> kpop(BuildContext context) {
    const pink = Color(0xFFFF4F9A), lilac = Color(0xFF8E7CFF);
    const pop = [Shadow(color: Color(0xAAFF4F9A), blurRadius: 10)];
    return [
      const Positioned.fill(child: CustomPaint(painter: _SparklePainter(7))),
      if (showTile)
        _tile(
          size: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xCCFFFFFF), Color(0x99FFD3EC)],
            ),
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: Colors.white, width: 2),
          ),
          padding: const EdgeInsets.all(18),
          painter: RouteOutlinePainter(
            info.route,
            startColor: pink,
            endColor: lilac,
            glowColor: const Color(0x55FF4F9A),
          ),
        ),
      _Placed(
        alignment: Alignment(0, panelY),
        margin: 16,
        child: Container(
          key: panelKey,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xEEFF9ACB), Color(0xEEC2A8FF), Color(0xEE9CD8FF)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0x66FF4F9A), blurRadius: 18),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      info.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        shadows: pop,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (value, unit) in facts.hero(''))
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          children: [
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.5,
                                shadows: pop,
                              ),
                            ),
                            if (unit.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  unit,
                                  style: const TextStyle(
                                    color: pink,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                [facts.date, ?facts.heartRate].join('  ·  '),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const FjeliaSignature(size: .85),
            ],
          ),
        ),
      ),
    ];
  }

  // ── Pixel: blocks, a grass-and-earth edge, hard shadows ───────────────────
  List<Widget> pixel(BuildContext context) {
    const mono = TextStyle(
      fontFamily: 'Courier',
      fontFamilyFallback: ['Menlo', 'Courier New', 'monospace'],
      fontWeight: FontWeight.w900,
      color: Colors.white,
      shadows: [Shadow(offset: Offset(2, 2), color: Color(0xFF2B2B2B))],
    );
    return [
      if (showTile)
        _tile(
          size: 100,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xCC1E1E1E),
            border: Border.all(color: const Color(0xFF5A5A5A), width: 4),
          ),
          painter: RouteOutlinePainter(
            info.route,
            startColor: const Color(0xFF7CDB46),
            endColor: const Color(0xFFFFD84A),
            glowColor: Colors.transparent,
            pixel: 5,
          ),
        ),
      _Placed(
        alignment: Alignment(0, panelY),
        margin: 14,
        child: Container(
          key: panelKey,
          decoration: const BoxDecoration(
            color: Color(0xFF7A5230),
            border: Border.fromBorderSide(
              BorderSide(color: Color(0xFF3B2614), width: 4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grass on top, pixel by pixel.
              const SizedBox(
                height: 14,
                width: double.infinity,
                child: CustomPaint(painter: _GrassPainter()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mono.copyWith(
                        fontSize: 15,
                        color: const Color(0xFFFFE15A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final (value, unit, label) in _rows)
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 8),
                            color: const Color(0xFF7CDB46),
                          ),
                          Expanded(
                            child: Text(
                              label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: mono.copyWith(fontSize: 12),
                            ),
                          ),
                          Text(
                            '$value $unit'.trim(),
                            style: mono.copyWith(fontSize: 20),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (var i = 0; i < 10; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Icon(
                              Icons.favorite,
                              size: 12,
                              color: i < 8
                                  ? const Color(0xFFE8231F)
                                  : const Color(0xFF3B2614),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          'fjelia.com',
                          style: mono.copyWith(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // ── Robot: metal plate, rivets, hazard stripes, LCD ───────────────────────
  List<Widget> robot(BuildContext context) {
    const lcd = Color(0xFF8CFF6B);
    const mono = TextStyle(
      fontFamily: 'Courier',
      fontFamilyFallback: ['Menlo', 'Courier New', 'monospace'],
      color: lcd,
      fontWeight: FontWeight.w700,
      shadows: [Shadow(color: Color(0x998CFF6B), blurRadius: 6)],
    );
    Widget rivet() => Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFFE6E9EC), Color(0xFF6B7178)],
        ),
      ),
    );
    return [
      if (showTile)
        _tile(
          size: 100,
          decoration: BoxDecoration(
            color: const Color(0xEE0A140A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF9AA3AD), width: 3),
          ),
          painter: RouteOutlinePainter(
            info.route,
            startColor: lcd,
            endColor: lcd,
            glowColor: const Color(0x668CFF6B),
          ),
        ),
      _Placed(
        alignment: Alignment(0, panelY),
        margin: 14,
        child: Container(
          key: panelKey,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB8C0C8), Color(0xFF7D868F), Color(0xFFA8B0B8)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF4A5057), width: 2),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 12,
                width: double.infinity,
                child: CustomPaint(painter: _HazardPainter()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        rivet(),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.smart_toy,
                          size: 16,
                          color: Color(0xFF2A2F35),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            info.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1E2227),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        rivet(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF071207),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF2A2F35),
                          width: 3,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (value, unit, label) in _rows)
                            Row(
                              children: [
                                Text('> ', style: mono.copyWith(fontSize: 13)),
                                Expanded(
                                  child: Text(
                                    label.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: mono.copyWith(fontSize: 11),
                                  ),
                                ),
                                Text(
                                  '$value $unit'.trim(),
                                  style: mono.copyWith(fontSize: 19),
                                ),
                              ],
                            ),
                          Text(
                            '[OK] ${[facts.date, ?facts.heartRate].join(' · ')}',
                            style: mono.copyWith(
                              fontSize: 10,
                              color: const Color(0xFF5FBF4A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        rivet(),
                        const Spacer(),
                        const FjeliaSignature(color: Color(0xFF1E2227), size: .85),
                        const Spacer(),
                        rivet(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // ── Sci-Fi: HUD lines, brackets, coordinates ──────────────────────────────
  List<Widget> scifi(BuildContext context) {
    const cyan = Color(0xFF3EF2FF);
    const mono = TextStyle(
      fontFamily: 'Courier',
      fontFamilyFallback: ['Menlo', 'Courier New', 'monospace'],
      color: cyan,
      fontWeight: FontWeight.w700,
      shadows: [Shadow(color: Color(0x993EF2FF), blurRadius: 8)],
    );
    final start = info.route.isEmpty ? null : info.route.first;
    String coord(double v, String pos, String neg) =>
        '${v.abs().toStringAsFixed(4)}°${v >= 0 ? pos : neg}';
    return [
      const Positioned.fill(child: CustomPaint(painter: _ScanGridPainter())),
      if (showTile)
        _tile(
          size: 110,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x5502101C),
            border: Border.all(color: cyan, width: 1.2),
          ),
          painter: RouteOutlinePainter(
            info.route,
            startColor: cyan,
            endColor: const Color(0xFF8A7CFF),
            glowColor: const Color(0xAA3EF2FF),
          ),
        ),
      _Placed(
        alignment: Alignment(0, panelY),
        margin: 16,
        child: CustomPaint(
          key: panelKey,
          painter: const _BracketPainter(cyan),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: const Color(0x8802101C),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '> ${info.title.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mono.copyWith(fontSize: 13, letterSpacing: 2),
                ),
                if (start != null)
                  Text(
                    '${coord(start.lat, 'N', 'S')}  ${coord(start.lng, 'E', 'W')}',
                    style: mono.copyWith(
                      fontSize: 9.5,
                      color: const Color(0xFF8AF8FF),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final (value, unit, label) in _rows)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: mono.copyWith(
                                fontSize: 8.5,
                                color: const Color(0xFF8AF8FF),
                                letterSpacing: 1,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$value$unit ',
                                style: mono.copyWith(
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: const Color(0x663EF2FF)),
                const SizedBox(height: 6),
                Text(
                  [facts.date, ?facts.ascent, ?facts.heartRate].join(' // '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mono.copyWith(fontSize: 9.5),
                ),
                const SizedBox(height: 6),
                const FjeliaSignature(color: Color(0xFFBFFBFF), size: .75),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  // ── Trading card: gold frame, HP, moves, rarity ───────────────────────────
  List<Widget> card(BuildContext context) {
    const ink = Color(0xFF1A1A1A);
    final hp = info.avgHeartRate?.round();
    Widget energy(Color color) => Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
    const colors = [Color(0xFFE8452C), Color(0xFF2F7DE1), Color(0xFF3BB54A)];
    return [
      _Placed(
        alignment: Alignment(0, panelY),
        margin: 16,
        child: Container(
          key: panelKey,
          width: 300,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFE680), Color(0xFFE5B23A), Color(0xFFFFF2B0)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF4DA), Color(0xFFF6D9A8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: ink),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          info.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (hp != null) ...[
                        const Text(
                          'HP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC0281C),
                          ),
                        ),
                        Text(
                          ' $hp',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC0281C),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8452C),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          facts.sportIcon,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (info.route.length > 1)
                    Container(
                      height: 74,
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2B3A67), Color(0xFF4C6BB3)],
                        ),
                        border: Border.all(
                          color: const Color(0xFFB8892A),
                          width: 2,
                        ),
                      ),
                      child: CustomPaint(
                        painter: RouteOutlinePainter(
                          info.route,
                          startColor: const Color(0xFFFFE680),
                          endColor: Colors.white,
                          glowColor: const Color(0x88FFE680),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  for (final (i, (value, unit, label)) in _rows.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          for (var e = 0; e <= i; e++)
                            energy(colors[(i + e) % colors.length]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '$value $unit'.trim(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 10, color: Color(0x55000000)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          [facts.date, ?facts.ascent].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9.5),
                        ),
                      ),
                      const Icon(
                        Icons.star,
                        size: 11,
                        color: Color(0xFFB8892A),
                      ),
                      const Text(
                        ' fjelia.com',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  // ── Comic: halftone, outlines, speech bubble, POW ─────────────────────────
  List<Widget> comic(BuildContext context) {
    const red = Color(0xFFE8231F), yellow = Color(0xFFFFE14D);
    Widget outlined(String text, double size, Color fill) => Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -.5,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size / 6
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -.5,
            color: fill,
          ),
        ),
      ],
    );
    return [
      const Positioned.fill(child: CustomPaint(painter: _HalftonePainter())),
      if (showTile)
        _Placed(
          alignment: tileAlignment,
          margin: 10,
          child: SizedBox(
            key: tileKey,
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: const _BurstPainter(yellow),
              child: Center(
                child: Transform.rotate(
                  angle: -.15,
                  child: outlined('POW!', 26, red),
                ),
              ),
            ),
          ),
        ),
      _Placed(
        alignment: Alignment(-1, panelY),
        margin: 14,
        child: Column(
          key: panelKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (facts.distance != null)
              CustomPaint(
                painter: const _BubblePainter(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  child: outlined('${facts.distance} KM!', 30, Colors.white),
                ),
              ),
            const SizedBox(height: 6),
            Container(
              width: 320,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: yellow,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(5, 5)),
                ],
              ),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.black),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      children: [
                        for (final (value, unit, _) in _rows.skip(
                          facts.distance == null ? 0 : 1,
                        ))
                          Text(
                            '$value $unit'.trim(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (facts.heartRate case final hr?)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite, size: 20, color: red),
                              const SizedBox(width: 3),
                              Text(
                                hr,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: red,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            facts.date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const FjeliaSignature(color: Colors.black, size: .8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // ── Outdoor: kraft badge, stitching, contour lines, compass ───────────────
  List<Widget> outdoor(BuildContext context) {
    const kraft = Color(0xFFD9C29A), forest = Color(0xFF2F4A2A);
    const serif = TextStyle(
      fontFamily: 'Georgia',
      fontFamilyFallback: ['Times New Roman', 'serif'],
      color: forest,
    );
    return [
      if (showTile)
        _tile(
          size: 104,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xEE2F4A2A),
            shape: BoxShape.circle,
            border: Border.all(color: kraft, width: 3),
          ),
          painter: RouteOutlinePainter(
            info.route,
            startColor: kraft,
            endColor: const Color(0xFFE8A04C),
            glowColor: Colors.transparent,
          ),
        ),
      _Placed(
        alignment: Alignment(0, panelY),
        margin: 14,
        child: Container(
          key: panelKey,
          decoration: BoxDecoration(
            color: kraft,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: const _TopoPainter(Color(0x332F4A2A)),
            foregroundPainter: const _StitchPainter(forest),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.explore, size: 16, color: forest),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          info.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: serif.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.landscape, size: 16, color: forest),
                    ],
                  ),
                  Text(
                    facts.date.toUpperCase(),
                    style: serif.copyWith(fontSize: 9.5, letterSpacing: 2),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final (value, unit, label) in _rows)
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              children: [
                                Text(
                                  value,
                                  style: serif.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  (unit.isEmpty ? label : unit).toUpperCase(),
                                  style: serif.copyWith(
                                    fontSize: 9,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (facts.ascent != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.terrain, size: 14, color: forest),
                        const SizedBox(width: 4),
                        Text(
                          facts.ascent!,
                          style: serif.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  const FjeliaSignature(color: forest, size: .85),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

/// Zigzag top and bottom, like paper torn off a till roll.
class _TornEdges extends CustomClipper<Path> {
  const _TornEdges();

  @override
  Path getClip(Size size) {
    const tooth = 6.0;
    final path = Path()..moveTo(0, tooth);
    for (var x = 0.0; x < size.width; x += tooth * 2) {
      path
        ..lineTo(x + tooth, 0)
        ..lineTo(math.min(x + tooth * 2, size.width), tooth);
    }
    path.lineTo(size.width, size.height - tooth);
    for (var x = size.width; x > 0; x -= tooth * 2) {
      path
        ..lineTo(x - tooth, size.height)
        ..lineTo(math.max(x - tooth * 2, 0), size.height - tooth);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_TornEdges old) => false;
}

/// Bars that look like a barcode, the same for the same workout.
class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.seed, this.color);
  final int seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()..color = color;
    var x = 0.0;
    while (x < size.width) {
      final bar = 1.0 + random.nextInt(3);
      canvas.drawRect(Rect.fromLTWH(x, 0, bar, size.height), paint);
      x += bar + 1 + random.nextInt(3);
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.seed != seed;
}

/// Four-point sparkles scattered over the card.
class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.seed);
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    for (var i = 0; i < 14; i++) {
      final c = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * .6,
      );
      final r = 4 + random.nextDouble() * 9;
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r);
      canvas
        ..drawPath(
          path,
          Paint()
            ..color = const Color(0x99FF8AD8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        )
        ..drawPath(path, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.seed != seed;
}

/// A strip of grass blocks: green pixels with a ragged lower edge.
class _GrassPainter extends CustomPainter {
  const _GrassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 7.0;
    final random = math.Random(7);
    const greens = [Color(0xFF5FA831), Color(0xFF6FBF3A), Color(0xFF4E9128)];
    for (var x = 0.0; x < size.width; x += cell) {
      final depth = 1 + random.nextInt(2);
      for (var y = 0; y < depth; y++) {
        canvas.drawRect(
          Rect.fromLTWH(x, y * cell, cell, cell),
          Paint()..color = greens[random.nextInt(greens.length)],
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GrassPainter old) => false;
}

/// Yellow and black warning stripes.
class _HazardPainter extends CustomPainter {
  const _HazardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..clipRect(Offset.zero & size)
      ..drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFC21A));
    final black = Paint()..color = const Color(0xFF1A1A1A);
    for (var x = -size.height; x < size.width; x += 16) {
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + size.height, 0)
          ..lineTo(x + size.height + 8, 0)
          ..lineTo(x + 8, size.height)
          ..close(),
        black,
      );
    }
  }

  @override
  bool shouldRepaint(_HazardPainter old) => false;
}

/// A faint HUD grid with a scan line.
class _ScanGridPainter extends CustomPainter {
  const _ScanGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x223EF2FF)
      ..strokeWidth = .6;
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final scan = size.height * .38;
    canvas.drawRect(
      Rect.fromLTWH(0, scan - 10, size.width, 20),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, scan - 10),
          Offset(0, scan + 10),
          const [Color(0x003EF2FF), Color(0x333EF2FF), Color(0x003EF2FF)],
          const [0, .5, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_ScanGridPainter old) => false;
}

/// Corner brackets around a HUD panel.
class _BracketPainter extends CustomPainter {
  const _BracketPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const l = 16.0;
    final w = size.width, h = size.height;
    for (final (o, dx, dy) in [
      (Offset.zero, 1.0, 1.0),
      (Offset(w, 0), -1.0, 1.0),
      (Offset(0, h), 1.0, -1.0),
      (Offset(w, h), -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx + l * dx, o.dy)
          ..lineTo(o.dx, o.dy)
          ..lineTo(o.dx, o.dy + l * dy),
        paint,
      );
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = color.withValues(alpha: .25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.color != color;
}

/// Comic-print dots, larger towards the bottom.
class _HalftonePainter extends CustomPainter {
  const _HalftonePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x33000000);
    const step = 9.0;
    for (var y = 0.0; y < size.height; y += step) {
      final r = 0.6 + 2.2 * (y / size.height);
      for (
        var x = (y ~/ step).isEven ? 0.0 : step / 2;
        x < size.width;
        x += step
      ) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HalftonePainter old) => false;
}

/// A jagged starburst with a black outline.
class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2, inner = outer * .62;
    final path = Path();
    for (var i = 0; i < 24; i++) {
      final r = i.isEven ? outer : inner;
      final a = i * math.pi / 12;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas
      ..drawPath(path.shift(const Offset(4, 4)), Paint()..color = Colors.black)
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.color != color;
}

/// A white speech bubble with a tail, outlined in black.
class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - 10),
      const Radius.circular(22),
    );
    final path = Path()
      ..addRRect(body)
      ..moveTo(28, size.height - 12)
      ..lineTo(22, size.height)
      ..lineTo(48, size.height - 12)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = const Color(0xFF2F7DE1))
      ..drawPath(
        path,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}

/// Contour lines like on a hiking map.
class _TopoPainter extends CustomPainter {
  const _TopoPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final c = Offset(size.width * .78, size.height * .3);
    for (var i = 1; i <= 9; i++) {
      final r = i * 16.0;
      final path = Path();
      for (var a = 0; a <= 72; a++) {
        final t = a / 72 * 2 * math.pi;
        final wobble = 1 + .12 * math.sin(t * 3 + i) + .06 * math.cos(t * 5);
        final p =
            c +
            Offset(math.cos(t) * r * 1.4 * wobble, math.sin(t) * r * wobble);
        a == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TopoPainter old) => old.color != color;
}

/// A dashed seam just inside the edge, like a sewn-on patch.
class _StitchPainter extends CustomPainter {
  const _StitchPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(6),
      const Radius.circular(11),
    );
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StitchPainter old) => old.color != color;
}

/// The card's picture when there is no photo: the route large and glowing
/// on a dark gradient, or the Fjelia artwork when there is no route either.
/// Colours of a style's card without a photo: the background and the route.
class _Palette {
  const _Palette(
    this.inner,
    this.outer, {
    this.start = const Color(0xFF00D4A0),
    this.end = const Color(0xFFFFB347),
    this.glow = const Color(0x8000D4A0),
    this.pixel = 0,
  });

  final Color inner, outer, start, end, glow;

  /// Cell size of a pixelated route; 0 draws a line.
  final double pixel;

  static _Palette of(ShareCardStyle style) => switch (style) {
    ShareCardStyle.neon => const _Palette(
      Color(0xFF2A0F4A),
      Color(0xFF07020F),
      start: Color(0xFF3EF2FF),
      end: Color(0xFFFF3EC8),
      glow: Color(0xFFFF3EC8),
    ),
    ShareCardStyle.kpop => const _Palette(
      Color(0xFFFFD3EC),
      Color(0xFFA996FF),
      start: Color(0xFFFF4F9A),
      end: Color(0xFF6F5BFF),
      glow: Color(0xAAFFFFFF),
    ),
    ShareCardStyle.pixel => const _Palette(
      Color(0xFF8FD3FF),
      Color(0xFF3F8EDB),
      start: Color(0xFF6BC23A),
      end: Color(0xFF3E7D1E),
      glow: Colors.transparent,
      pixel: 9,
    ),
    ShareCardStyle.robot => const _Palette(
      Color(0xFF424A54),
      Color(0xFF15181C),
      start: Color(0xFF8CFF6B),
      end: Color(0xFF8CFF6B),
      glow: Color(0x668CFF6B),
    ),
    ShareCardStyle.scifi => const _Palette(
      Color(0xFF0C2C3E),
      Color(0xFF02070C),
      start: Color(0xFF3EF2FF),
      end: Color(0xFF8A7CFF),
      glow: Color(0xAA3EF2FF),
    ),
    ShareCardStyle.card => const _Palette(Color(0xFF2B3A67), Color(0xFF111833)),
    ShareCardStyle.comic => const _Palette(
      Color(0xFFFFE85C),
      Color(0xFFFFB300),
      start: Color(0xFF111111),
      end: Color(0xFFE8231F),
      glow: Colors.transparent,
    ),
    ShareCardStyle.outdoor => const _Palette(
      Color(0xFF41603C),
      Color(0xFF1B2A19),
      start: Color(0xFFF2E3C2),
      end: Color(0xFFE8A04C),
      glow: Color(0x55F2E3C2),
    ),
    _ => const _Palette(Color(0xFF14363A), Color(0xFF0A1418)),
  };
}

class _RouteBackdrop extends StatelessWidget {
  const _RouteBackdrop({
    required this.route,
    required this.palette,
    this.onLoaded,
    this.panelY = 1,
    this.plain = false,
    this.reserve = 220,
  });

  final _Palette palette;

  /// Just the dark gradient, without the route or the artwork.
  final bool plain;

  /// Height kept free for the style's block, on the panel's side.
  final double reserve;
  final List<RoutePoint> route;
  final VoidCallback? onLoaded;

  /// Where the panel is; the route takes the other half.
  final double panelY;

  @override
  Widget build(BuildContext context) {
    if (plain) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded?.call());
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 1.1,
            colors: [palette.inner, palette.outer],
          ),
        ),
      );
    }
    if (route.length < 2) {
      return Image.asset(
        'assets/splash/fjelia-splash.png',
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, sync) {
          if (frame != null || sync) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => onLoaded?.call(),
            );
          }
          return child;
        },
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded?.call());
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 1.1,
          colors: [palette.inner, palette.outer],
        ),
      ),
      child: Padding(
        // Clear of the panel, wherever the athlete moved it.
        padding: panelY >= 0
            ? EdgeInsets.fromLTRB(36, 36, 36, reserve)
            : EdgeInsets.fromLTRB(36, reserve, 36, 36),
        child: CustomPaint(
          painter: RouteOutlinePainter(
            route,
            thickness: 2.2,
            startColor: palette.start,
            endColor: palette.end,
            glowColor: palette.glow,
            pixel: palette.pixel,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Frosted glass: the photo behind is blurred and darkened.
class _Glass extends StatelessWidget {
  const _Glass({super.key, required this.child, required this.radius});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x66101418),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white24, width: .8),
        ),
        child: child,
      ),
    ),
  );
}

/// The route's shape, scaled into the box, with start and finish dots.
class RouteOutlinePainter extends CustomPainter {
  RouteOutlinePainter(
    this.route, {
    this.thickness = 1,
    this.startColor = const Color(0xFF00D4A0),
    this.endColor = const Color(0xFFFFB347),
    this.glowColor = const Color(0x8000D4A0),
    this.dots = true,
    this.pixel = 0,
  });
  final List<RoutePoint> route;

  /// Draws the route as blocks of this size instead of a line.
  final double pixel;

  /// Line and dot size relative to the small route tile.
  final double thickness;

  /// The line runs from [startColor] to [endColor] over a [glowColor] halo.
  final Color startColor, endColor, glowColor;
  final bool dots;

  @override
  void paint(Canvas canvas, Size size) {
    var minLat = route.first.lat, maxLat = minLat;
    var minLng = route.first.lng, maxLng = minLng;
    for (final p in route) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }
    // Longitude degrees shrink towards the poles.
    final xScale = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final width = (maxLng - minLng) * xScale, height = maxLat - minLat;
    if (width <= 0 && height <= 0) return;
    // Fits the box both ways, leaving room for the line and the dots.
    final pad = 8 * thickness;
    final scale = math.min(
      width > 0 ? (size.width - pad) / width : double.infinity,
      height > 0 ? (size.height - pad) / height : double.infinity,
    );
    final dx = (size.width - width * scale) / 2;
    final dy = (size.height - height * scale) / 2;
    Offset at(RoutePoint p) => Offset(
      dx + (p.lng - minLng) * xScale * scale,
      dy + (maxLat - p.lat) * scale,
    );
    final path = Path()..moveTo(at(route.first).dx, at(route.first).dy);
    final step = route.length > 600 ? route.length ~/ 600 : 1;
    for (var i = step; i < route.length; i += step) {
      final o = at(route[i]);
      path.lineTo(o.dx, o.dy);
    }
    final first = at(route.first), last = at(route.last);
    if (pixel > 0) {
      // Each cell the route passes through becomes one block, shaded from
      // start to finish, with a darker edge like a voxel.
      final cells = <(int, int)>{};
      final order = <(int, int)>[];
      final step = route.length > 2000 ? route.length ~/ 2000 : 1;
      for (var i = 0; i < route.length; i += step) {
        final o = at(route[i]);
        final cell = ((o.dx / pixel).floor(), (o.dy / pixel).floor());
        if (cells.add(cell)) order.add(cell);
      }
      for (final (i, (cx, cy)) in order.indexed) {
        final t = order.length < 2 ? 0.0 : i / (order.length - 1);
        final rect = Rect.fromLTWH(cx * pixel, cy * pixel, pixel, pixel);
        canvas
          ..drawRect(
            rect,
            Paint()..color = Color.lerp(startColor, endColor, t)!,
          )
          ..drawRect(
            rect.deflate(.5),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = const Color(0x55000000),
          );
      }
      return;
    }
    path.lineTo(last.dx, last.dy);
    Paint stroke(double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    if (glowColor.a > 0) {
      // Soft glow under the line.
      canvas.drawPath(
        path,
        stroke(7 * thickness)
          ..color = glowColor
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * thickness),
      );
    }
    // From start to finish.
    canvas.drawPath(
      path,
      stroke(2.6 * thickness)
        ..shader = ui.Gradient.linear(first, last, [startColor, endColor]),
    );
    if (!dots) return;
    canvas
      ..drawCircle(first, 4.5 * thickness, Paint()..color = Colors.white)
      ..drawCircle(first, 3 * thickness, Paint()..color = startColor)
      ..drawCircle(last, 4.5 * thickness, Paint()..color = Colors.white)
      ..drawCircle(last, 3 * thickness, Paint()..color = endColor);
  }

  @override
  bool shouldRepaint(RouteOutlinePainter old) =>
      old.route != route ||
      old.thickness != thickness ||
      old.startColor != startColor ||
      old.endColor != endColor ||
      old.glowColor != glowColor ||
      old.dots != dots ||
      old.pixel != pixel;
}

/// The photo filling its box, zoomed and moved as the athlete framed it.
/// It always covers the box: the pan reaches only as far as the zoom allows.
class _FramedPhoto extends StatelessWidget {
  const _FramedPhoto({
    required this.file,
    this.zoom = 1,
    this.pan = Offset.zero,
    this.onLoaded,
  });

  final File file;
  final double zoom;
  final Offset pan;
  final VoidCallback? onLoaded;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: LayoutBuilder(
      builder: (context, box) {
        final dx = pan.dx * (zoom - 1) * box.maxWidth / 2;
        final dy = pan.dy * (zoom - 1) * box.maxHeight / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(dx, dy, 0)
            ..multiply(Matrix4.diagonal3Values(zoom, zoom, 1)),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: box.maxWidth,
            height: box.maxHeight,
            frameBuilder: (context, child, frame, sync) {
              if (frame != null || sync) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => onLoaded?.call(),
                );
              }
              return child;
            },
          ),
        );
      },
    ),
  );
}

/// The element of a sport on the holo card: frame colours and type icon.
typedef _Element = ({Color dark, Color light, Color energy, IconData icon});

_Element _elementOf(String? sport) {
  final s = (sport ?? '').toLowerCase();
  if (s.contains('cycl') || s.contains('bik') || s.contains('ride')) {
    return (
      dark: const Color(0xFFE0A800),
      light: const Color(0xFFFFE680),
      energy: const Color(0xFFF2C21A),
      icon: Icons.bolt,
    );
  }
  if (s.contains('swim')) {
    return (
      dark: const Color(0xFF2F6FD6),
      light: const Color(0xFFA9D2FF),
      energy: const Color(0xFF2F7DE1),
      icon: Icons.water_drop,
    );
  }
  if (s.contains('hik') || s.contains('walk')) {
    return (
      dark: const Color(0xFF2E9A44),
      light: const Color(0xFFB5E7A0),
      energy: const Color(0xFF3BB54A),
      icon: Icons.eco,
    );
  }
  if (s.contains('ski')) {
    return (
      dark: const Color(0xFF4DA8D0),
      light: const Color(0xFFDDF4FF),
      energy: const Color(0xFF6CC6EA),
      icon: Icons.ac_unit,
    );
  }
  return (
    dark: const Color(0xFFD8402A),
    light: const Color(0xFFFFC2A6),
    energy: const Color(0xFFE8452C),
    icon: Icons.local_fire_department,
  );
}

/// A collector card with the photo in its window and holo foil over it.
/// Fills the whole share image; the facts are its "moves".
class _HoloCard extends StatelessWidget {
  const _HoloCard({
    required this.facts,
    required this.photo,
    this.onLoaded,
    this.panelKey,
    this.zoom = 1,
    this.pan = Offset.zero,
    this.fullArt = false,
    this.panelY = 1,
    this.tileAlignment = Alignment.topRight,
    this.tileKey,
  });

  final double zoom;
  final Offset pan;

  /// The photo fills the whole card (portrait); the stats float over it
  /// and move up or down with [panelY].
  final bool fullArt;
  final double panelY;
  final Alignment tileAlignment;
  final Key? tileKey;

  final _Facts facts;
  final File? photo;
  final VoidCallback? onLoaded;
  final Key? panelKey;

  ActivityShareInfo get info => facts.info;

  @override
  Widget build(BuildContext context) {
    final element = _elementOf(info.sport);
    const ink = Color(0xFF1E1E1E);
    final hp = info.avgHeartRate?.round();
    final day = int.parse(DateFormat('D').format(info.date.toLocal()));
    Widget energy([double size = 16]) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [element.light, element.energy],
          center: const Alignment(-.3, -.3),
        ),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 2)],
      ),
      child: Icon(element.icon, size: size * .62, color: Colors.white),
    );
    Widget move(int cost, String name, String damage, String note) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Row(
                  children: [
                    for (var i = 0; i < cost; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: energy(),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                damage,
                style: const TextStyle(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 1),
              child: Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: ink, fontSize: 10.5),
              ),
            ),
        ],
      ),
    );
    Widget stat(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ink,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: ink,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
    final moves = <Widget>[
      if (facts.distance case final distance?)
        move(
          1,
          facts.labels.distance,
          distance,
          '$distance km · ${facts.date}',
        ),
      if (facts.effort case final e?)
        move(
          2,
          e.$3,
          '${e.$1}+',
          '${e.$1} ${e.$2} · ${facts.labels.time} ${facts.time}',
        )
      else
        move(2, facts.labels.time, facts.time, facts.date),
    ];
    final footer = Row(
      children: [
        Text(
          'FJL-${DateFormat('yyMMdd').format(info.date.toLocal())}',
          style: const TextStyle(color: ink, fontSize: 7.5),
        ),
        const Spacer(),
        Image.asset(
          'assets/branding/app-icon-original.png',
          width: 11,
          height: 11,
        ),
        const Text(
          ' fjelia.com',
          style: TextStyle(
            color: ink,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Text('$day/365', style: const TextStyle(color: ink, fontSize: 7.5)),
        const Icon(Icons.star, size: 9, color: ink),
      ],
    );
    if (fullArt) {
      const shade = [Shadow(color: Color(0xCC000000), blurRadius: 6)];
      final hasRoute = info.route.length > 1;
      return Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE34D), Color(0xFFF4C300), Color(0xFFFFEE88)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [element.dark, element.light, element.dark],
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo case final photo?)
                  _FramedPhoto(
                    file: photo,
                    zoom: zoom,
                    pan: pan,
                    onLoaded: onLoaded,
                  )
                else
                  Builder(
                    builder: (context) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => onLoaded?.call(),
                      );
                      return DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, -.3),
                            colors: [Color(0xFF5B6A8F), Color(0xFF141A2E)],
                          ),
                        ),
                        child: hasRoute
                            ? Padding(
                                // Clear of the stats, wherever they are.
                                padding: panelY >= 0
                                    ? const EdgeInsets.fromLTRB(30, 70, 30, 230)
                                    : const EdgeInsets.fromLTRB(
                                        30,
                                        230,
                                        30,
                                        40,
                                      ),
                                child: CustomPaint(
                                  painter: RouteOutlinePainter(
                                    info.route,
                                    thickness: 2,
                                    startColor: element.light,
                                    endColor: Colors.white,
                                    glowColor: element.energy,
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      );
                    },
                  ),
                const CustomPaint(painter: _HoloPainter()),
                // Darkens the top so the name reads on any photo.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99000000), Colors.transparent],
                      stops: [0, .22],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 8,
                  top: 6,
                  child: Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            info.title,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.3,
                              shadows: shade,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        size: 15,
                        color: Color(0xFFFFE34D),
                      ),
                      const Spacer(),
                      if (hp != null) ...[
                        const Text(
                          'HP ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            shadows: shade,
                          ),
                        ),
                        Text(
                          '$hp',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            shadows: shade,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      energy(22),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 38,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 2, 14, 2),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF2F2F2), Color(0xFFB8BCC2)],
                      ),
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      sportLabel(info.sport ?? '').toUpperCase(),
                      style: const TextStyle(
                        color: ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                ),
                if (photo != null && hasRoute)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 64, 10, 10),
                    child: Align(
                      alignment: tileAlignment,
                      child: Container(
                        key: tileKey,
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0x99101418),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD9B54A),
                            width: 1.5,
                          ),
                        ),
                        child: CustomPaint(
                          painter: RouteOutlinePainter(
                            info.route,
                            thickness: .8,
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 64, 8, 8),
                  child: Align(
                    alignment: Alignment(0, panelY),
                    child: Container(
                      key: panelKey,
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: .82),
                            element.light.withValues(alpha: .78),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xCCFFFFFF),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...moves,
                          const Divider(height: 8, color: Color(0x44000000)),
                          Row(
                            children: [
                              stat(facts.labels.ascent, facts.ascent ?? '—'),
                              stat(
                                facts.labels.heartRate,
                                facts.heartRate ?? '—',
                              ),
                              stat(facts.labels.time, facts.time),
                            ],
                          ),
                          const SizedBox(height: 4),
                          footer,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      key: panelKey,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        // The yellow outer border, with a little foil sheen.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE34D), Color(0xFFF4C300), Color(0xFFFFEE88)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [element.dark, element.light, element.dark],
            stops: const [0, .55, 1],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name, star, HP, element.
            Row(
              children: [
                // A long name shrinks to fit, as on a real card.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      info.title,
                      maxLines: 1,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.star_outline,
                  size: 16,
                  color: Color(0xFF2E7D32),
                ),
                const Spacer(),
                if (hp != null) ...[
                  const Text(
                    'HP ',
                    style: TextStyle(
                      color: ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '$hp',
                    style: const TextStyle(
                      color: ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                energy(22),
              ],
            ),
            const SizedBox(height: 4),
            // The photo window with holo foil.
            SizedBox(
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFD9B54A),
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), blurRadius: 4),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photo case final photo?)
                          _FramedPhoto(
                            file: photo,
                            zoom: zoom,
                            pan: pan,
                            onLoaded: onLoaded,
                          )
                        else
                          Builder(
                            builder: (context) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => onLoaded?.call(),
                              );
                              return DecoratedBox(
                                decoration: const BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Color(0xFF5B6A8F),
                                      Color(0xFF1C2238),
                                    ],
                                  ),
                                ),
                                child: info.route.length > 1
                                    ? Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: CustomPaint(
                                          painter: RouteOutlinePainter(
                                            info.route,
                                            thickness: 1.8,
                                            startColor: element.light,
                                            endColor: Colors.white,
                                            glowColor: element.energy,
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                              );
                            },
                          ),
                        const CustomPaint(painter: _HoloPainter()),
                        if (photo != null && info.route.length > 1)
                          Positioned(
                            right: 6,
                            top: 6,
                            width: 54,
                            height: 54,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0x99101418),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFD9B54A),
                                  width: 1.5,
                                ),
                              ),
                              child: CustomPaint(
                                painter: RouteOutlinePainter(
                                  info.route,
                                  thickness: .7,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // The silver sport tag on the window's lower edge.
                  Positioned(
                    left: -2,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 2, 14, 2),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF2F2F2), Color(0xFFB8BCC2)],
                        ),
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        sportLabel(info.sport ?? '').toUpperCase(),
                        style: const TextStyle(
                          color: ink,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The caption strip under the window.
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF4C2), Color(0xFFE7C35A)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'Fjelia · ${facts.date}',
                  style: const TextStyle(
                    color: ink,
                    fontSize: 8.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // The moves, on a pale panel.
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: .75),
                      element.light.withValues(alpha: .65),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: moves,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                stat(facts.labels.ascent, facts.ascent ?? '—'),
                stat(facts.labels.heartRate, facts.heartRate ?? '—'),
                stat(facts.labels.time, facts.time),
              ],
            ),
            const SizedBox(height: 4),
            footer,
          ],
        ),
      ),
    );
  }
}

/// Holo foil: a diagonal rainbow sheen and scattered glitter specks.
class _HoloPainter extends CustomPainter {
  const _HoloPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          const [
            Color(0x00FFFFFF),
            Color(0x33FF6FD8),
            Color(0x003EF2FF),
            Color(0x333EF2FF),
            Color(0x00FFE680),
            Color(0x33FFE680),
            Color(0x00FFFFFF),
          ],
          const [0, .2, .35, .5, .65, .8, 1],
        ),
    );
    final random = math.Random(42);
    const colors = [
      Color(0xCCFFFFFF),
      Color(0xCC8AF8FF),
      Color(0xCCFF9AE0),
      Color(0xCCFFE680),
      Color(0xCC9CFF9A),
    ];
    for (var i = 0; i < 90; i++) {
      final c = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final r = .8 + random.nextDouble() * 2.2;
      final paint = Paint()..color = colors[random.nextInt(colors.length)];
      if (i.isEven) {
        // A tiny diamond.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r * 1.6)
            ..lineTo(c.dx + r, c.dy)
            ..lineTo(c.dx, c.dy + r * 1.6)
            ..lineTo(c.dx - r, c.dy)
            ..close(),
          paint,
        );
      } else {
        canvas.drawRect(Rect.fromCenter(center: c, width: r, height: r), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HoloPainter old) => false;
}
