import 'dart:math' as math;

import 'package:fjelia_core/config/map_tiles.dart';
import 'package:fjelia_core/utils/label_rows.dart';
import 'package:fjelia_views/fjelia_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:fjelia_core/utils/distance_format.dart';
import 'package:fjelia_core/utils/target_time.dart';

import '../../db/database.dart' show RaceGoal;
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/fjelia_edition_provider.dart';
import '../../providers/race_course_provider.dart';
import '../../services/race_library.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';
import '../settings/fjelia_pro_sheet.dart';

const _accent = [Color(0xFFFFB13D), Color(0xFFE5383B)];

/// Where map tiles come from; tests set one that loads nothing.
@visibleForTesting
TileProvider? courseTileProvider;

/// The course of a race goal: its profile, climbs and gradients, and with
/// FjeliaPro the finish and checkpoint times from the athlete's own running
/// on hills. All of it from fjelia_views, as on the computer.
class RaceCourseSheet extends ConsumerStatefulWidget {
  const RaceCourseSheet({super.key, required this.goal});
  final RaceGoal goal;

  @override
  ConsumerState<RaceCourseSheet> createState() => _RaceCourseSheetState();
}

class _RaceCourseSheetState extends ConsumerState<RaceCourseSheet> {
  double? _hoverKm;
  String? _problem;
  var _busy = false;

  String get _id => widget.goal.id;

  Future<void> _run(Future<String?> Function() action) async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _problem = null;
    });
    String? problem;
    try {
      problem = await action();
    } on CourseRefused catch (e) {
      problem = switch (e.reason) {
        CourseRefusal.unreadable => l.courseUnreadable,
        CourseRefusal.noElevation => l.courseNoElevation,
      };
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _problem = problem;
      });
    }
  }

  Future<void> _fromLibrary() async {
    final race = await showModalBottomSheet<RaceDistance>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LibraryPicker(goal: widget.goal),
    );
    if (race == null || !mounted) return;
    final l = context.l10n;
    await _run(
      () async =>
          await ref.read(raceCourseActionsProvider).fromLibrary(_id, race)
          ? null
          : l.courseNotFetched,
    );
  }

  Future<void> _pickFile() => _run(() async {
    await ref.read(raceCourseActionsProvider).pickFile(_id);
    return null;
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final course = ref.watch(raceCourseProvider(_id));
    final pro = ref.watch(fjeliaEditionProvider).isPro;
    return SheetPage(
      title: widget.goal.name,
      actions: [
        if (course.valueOrNull != null)
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'replace' => _pickFile(),
              'remove' => ref.read(raceCourseActionsProvider).remove(_id),
              _ => null,
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'replace', child: Text(l.courseReplace)),
              PopupMenuItem(value: 'remove', child: Text(l.courseRemove)),
            ],
          ),
      ],
      child: course.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => DataError(e),
        data: (v) => v == null || v.profile == null
            ? _NoCourse(
                busy: _busy,
                problem: _problem,
                onLibrary: _fromLibrary,
                onFile: _pickFile,
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_problem case final p?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(p, style: const TextStyle(color: Colors.red)),
                    ),
                  _Stats(profile: v.profile!),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: _ProfileChart(
                      profile: v.profile!,
                      checkpoints: v.course.checkpoints,
                      hoverKm: _hoverKm,
                      onHover: (km) => setState(() => _hoverKm = km),
                    ),
                  ),
                  if (_hoverKm case final km?)
                    _HoverLine(profile: v.profile!, km: km),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: _CourseMap(course: v.course, hoverKm: _hoverKm),
                  ),
                  const SizedBox(height: 12),
                  _Climbs(profile: v.profile!),
                  _Bands(profile: v.profile!),
                  if (pro) ...[
                    if (v.result case final r?) _Result(result: r),
                    _Plan(view: v),
                    if (v.readiness case final r?) _Readiness(readiness: r),
                    if (v.table case final t?) _PaceTable(table: t),
                  ] else
                    SectionCard(
                      title: l.coursePlan,
                      accent: _accent,
                      onTap: () =>
                          showAppSheet(context, const FjeliaProSheet()),
                      child: Text(
                        l.courseProTeaser,
                        style: TextStyle(fontSize: 13, color: fjInk70),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _NoCourse extends StatelessWidget {
  const _NoCourse({
    required this.busy,
    required this.problem,
    required this.onLibrary,
    required this.onFile,
  });
  final bool busy;
  final String? problem;
  final VoidCallback onLibrary, onFile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l.courseAdd, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          problem ?? l.courseAddHint,
          style: TextStyle(color: problem == null ? fjInk70 : Colors.red),
        ),
        const SizedBox(height: 16),
        if (busy)
          const LinearProgressIndicator()
        else ...[
          FilledButton.icon(
            onPressed: onLibrary,
            icon: const Icon(Icons.search),
            label: Text(l.courseFromLibrary),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onFile,
            icon: const Icon(Icons.upload_file),
            label: Text(l.courseFromFile),
          ),
        ],
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.profile});
  final CourseProfile profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = profile;
    Widget stat(String label, String value, [String? note]) => SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: fjInk70)),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (note != null)
            Text(note, style: TextStyle(fontSize: 11, color: fjInk70)),
        ],
      ),
    );
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        stat(l.courseDistance, formatKm(p.distanceKm * 1000)),
        stat(l.courseClimb, '${p.gain.round()} m'),
        stat(l.courseDescent, '${p.loss.round()} m'),
        stat(l.courseEffort, '${p.effortKm.round()} km', l.courseEffortNote),
        stat(
          l.courseSteep,
          '${formatGrade(p.steepestUp)} / ${formatGrade(-p.steepestDown)}',
          l.courseSteepNote,
        ),
        stat(l.courseHighest, '${p.maxEle.round()} m'),
      ],
    );
  }
}

class _HoverLine extends StatelessWidget {
  const _HoverLine({required this.profile, required this.km});
  final CourseProfile profile;
  final double km;

  @override
  Widget build(BuildContext context) {
    final p = profile.profile.lastWhere(
      (x) => x.km <= km,
      orElse: () => profile.profile.first,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${km.toStringAsFixed(1)} km · ${p.ele.round()} m · ${formatGrade(p.grade)}',
        style: TextStyle(fontSize: 12, color: fjInk70),
      ),
    );
  }
}

/// The profile coloured by grade; touching it shows that point here and
/// on the map.
class _ProfileChart extends StatelessWidget {
  const _ProfileChart({
    required this.profile,
    required this.checkpoints,
    required this.hoverKm,
    required this.onHover,
  });
  final CourseProfile profile;
  final List<CourseCheckpoint> checkpoints;
  final double? hoverKm;
  final ValueChanged<double?> onHover;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      const left = 38.0;
      double km(double x) =>
          ((x - left) / (size.maxWidth - left) * profile.distanceKm).clamp(
            0,
            profile.distanceKm,
          );
      return GestureDetector(
        onHorizontalDragUpdate: (d) => onHover(km(d.localPosition.dx)),
        onTapDown: (d) => onHover(km(d.localPosition.dx)),
        child: CustomPaint(
          size: size.biggest,
          painter: _ProfilePainter(
            profile: profile,
            checkpoints: checkpoints,
            hoverKm: hoverKm,
            ink: fjInk70,
            line: fjInk10,
          ),
        ),
      );
    },
  );
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter({
    required this.profile,
    required this.checkpoints,
    required this.hoverKm,
    required this.ink,
    required this.line,
  });
  final CourseProfile profile;
  final List<CourseCheckpoint> checkpoints;
  final double? hoverKm;
  final Color ink, line;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = profile.profile;
    if (pts.length < 2) return;
    const left = 38.0, bottom = 16.0;
    final w = size.width - left, h = size.height - bottom;
    // Room above the profile for the checkpoint names, two rows.
    const rowHeight = 12.0;
    final band = checkpoints.isEmpty ? 0.0 : rowHeight * 2 + 4;
    final step = profile.maxEle - profile.minEle > 1000 ? 500.0 : 100.0;
    final lo = (profile.minEle / step).floor() * step;
    final hi = math.max(lo + step, (profile.maxEle / step).ceil() * step);
    double x(double km) => left + km / profile.distanceKm * w;
    double y(double ele) => h - (ele - lo) / (hi - lo) * (h - band) * 0.95;
    void label(String s, Offset at, {bool right = false}) {
      final p = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(fontSize: 9, color: ink),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(canvas, at - Offset(right ? p.width : p.width / 2, 0));
    }

    for (var e = lo; e <= hi; e += step) {
      canvas.drawLine(
        Offset(left, y(e)),
        Offset(size.width, y(e)),
        Paint()
          ..color = line
          ..strokeWidth = .5,
      );
      label('${e.round()}', Offset(left - 4, y(e) - 6), right: true);
    }
    final kmStep = profile.distanceKm > 100
        ? 20
        : profile.distanceKm > 40
        ? 10
        : 5;
    for (var k = 0; k <= profile.distanceKm; k += kmStep) {
      label('$k', Offset(x(k.toDouble()), h + 3));
    }
    final columns = w.ceil();
    var i = 0;
    for (var col = 0; col < columns; col++) {
      final km = col / columns * profile.distanceKm;
      while (i < pts.length - 1 && pts[i].km < km) {
        i++;
      }
      canvas.drawRect(
        Rect.fromLTRB(left + col, y(pts[i].ele), left + col + 1.2, h),
        Paint()..color = Color(gradeArgb(pts[i].grade)).withValues(alpha: .85),
      );
    }
    // Each checkpoint: its name above the profile (rows shared by
    // placeLabels from fjelia_core), a dashed line down to a dot on it.
    final marks = [...checkpoints]..sort((a, b) => a.km.compareTo(b.km));
    final names = [
      for (final c in marks)
        TextPainter(
          text: TextSpan(
            text: c.name,
            style: TextStyle(fontSize: 9, color: ink),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: 90),
    ];
    final places = placeLabels(
      [
        for (final (i, c) in marks.indexed)
          (centre: x(c.km.clamp(0, profile.distanceKm)), width: names[i].width),
      ],
      left: left,
      right: size.width,
    );
    for (final (i, c) in marks.indexed) {
      final cx = x(c.km.clamp(0, profile.distanceKm));
      final at =
          pts[((c.km / profile.distanceKm) * (pts.length - 1)).round().clamp(
            0,
            pts.length - 1,
          )];
      final row = places[i].row;
      names[i].paint(canvas, Offset(places[i].x, row * rowHeight));
      final dot = y(at.ele);
      final dash = Paint()
        ..color = ink.withValues(alpha: .7)
        ..strokeWidth = 1;
      for (var d = row * rowHeight + rowHeight; d < dot - 4; d += 6) {
        canvas.drawLine(
          Offset(cx, d),
          Offset(cx, math.min(d + 3, dot - 4)),
          dash,
        );
      }
      canvas.drawCircle(Offset(cx, dot), 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(cx, dot),
        3.5,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    if (hoverKm case final km?) {
      canvas.drawLine(
        Offset(x(km), 0),
        Offset(x(km), h),
        Paint()
          ..color = ink
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_ProfilePainter old) =>
      old.profile != profile ||
      old.hoverKm != hoverKm ||
      old.checkpoints != checkpoints;
}

class _CourseMap extends StatelessWidget {
  const _CourseMap({required this.course, this.hoverKm});
  final Course course;
  final double? hoverKm;

  LatLng _at(double km) {
    final pts = course.points;
    var i = pts.indexWhere((p) => p.distanceM >= km * 1000);
    if (i < 0) i = pts.length - 1;
    return LatLng(pts[i].lat, pts[i].lng);
  }

  @override
  Widget build(BuildContext context) {
    final line = [for (final p in course.points) LatLng(p.lat, p.lng)];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.coordinates(
            coordinates: line,
            padding: const EdgeInsets.all(20),
          ),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: mapTileUrl,
            userAgentPackageName: mapUserAgentPackage,
            tileProvider: courseTileProvider,
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: line,
                color: const Color(0xFFE5383B),
                strokeWidth: 3.5,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              for (final c in course.checkpoints)
                Marker(
                  point: _at(c.km),
                  width: 12,
                  height: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(width: 2.5),
                    ),
                  ),
                ),
              if (hoverKm case final km?)
                Marker(
                  point: _at(km),
                  width: 16,
                  height: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(context.l10n.openstreetmapContributors2),
            ],
          ),
        ],
      ),
    );
  }
}

class _Climbs extends StatelessWidget {
  const _Climbs({required this.profile});
  final CourseProfile profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SectionCard(
      title: l.courseClimbs,
      accent: _accent,
      child: profile.climbs.isEmpty
          ? Text(l.courseNoClimbs, style: TextStyle(color: fjInk70))
          : Column(
              children: [
                for (final c in profile.climbs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${c.startKm.toStringAsFixed(1)}–'
                            '${c.endKm.toStringAsFixed(1)} km',
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text('+${c.metres.round()} m'),
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                            formatGrade(c.grade),
                            textAlign: TextAlign.end,
                            style: TextStyle(color: Color(gradeArgb(c.grade))),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Bands extends StatelessWidget {
  const _Bands({required this.profile});
  final CourseProfile profile;

  static const _grades = [-0.25, -0.15, -0.06, 0.0, 0.06, 0.15, 0.25];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final names = [
      l.courseBandSteepDown,
      l.courseBandDown,
      l.courseBandGentlyDown,
      l.courseBandFlat,
      l.courseBandGentlyUp,
      l.courseBandUp,
      l.courseBandSteepUp,
    ];
    final most = profile.bands.fold(0.0, math.max);
    return SectionCard(
      title: l.courseGradients,
      accent: _accent,
      child: Column(
        children: [
          for (var i = 0; i < profile.bands.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(width: 110, child: Text(names[i])),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: most == 0 ? 0 : profile.bands[i] / most,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(gradeArgb(_grades[i])),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      formatKm(profile.bands[i] * 1000),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The finish and the time at each checkpoint (FjeliaPro).
class _Plan extends ConsumerWidget {
  const _Plan({required this.view});
  final RaceCourseView view;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final d = view.goal.raceDate;
    final current = view.startAt ?? DateTime(d.year, d.month, d.day, 7);
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (t == null) return;
    await ref
        .read(raceCourseActionsProvider)
        .setStart(
          view.goal.id,
          DateTime(d.year, d.month, d.day, t.hour, t.minute),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = view.plan;
    final start = view.startAt;
    final clock = DateFormat.E().add_Hm();
    return SectionCard(
      title: l.coursePlan,
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r == null)
            Text(l.coursePlanNeedsRuns, style: TextStyle(color: fjInk70))
          else ...[
            Text(
              l.coursePlanFrom,
              style: TextStyle(fontSize: 12, color: fjInk70),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.courseFinish,
                        style: TextStyle(fontSize: 12, color: fjInk70),
                      ),
                      Text(
                        formatHoursMinutes(r.seconds),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${formatHoursMinutes(r.fastest)}–${formatHoursMinutes(r.slowest)}',
                        style: TextStyle(fontSize: 12, color: fjInk70),
                      ),
                    ],
                  ),
                ),
                if (start != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l.courseArrival,
                        style: TextStyle(fontSize: 12, color: fjInk70),
                      ),
                      Text(
                        clock.format(
                          start.add(Duration(seconds: r.seconds.round())),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (r.darkHours > 0.05)
              Text(
                l.courseInDark(formatHoursMinutes(r.darkHours * 3600)),
                style: TextStyle(fontSize: 12, color: fjInk70),
              ),
            if (view.fuel case final f?)
              Text(
                l.courseFuelPerHour(
                  f.carbs.round(),
                  f.fluid.round(),
                  f.sodium.round(),
                ),
                style: TextStyle(fontSize: 12, color: fjInk70),
              ),
            const SizedBox(height: 10),
            for (final (i, leg) in r.legs.indexed)
              _LegRow(
                name: i == r.legs.length - 1 ? l.courseFinish : leg.leg.to,
                leg: leg,
                clock: start == null
                    ? null
                    : clock.format(
                        start.add(Duration(seconds: leg.arrival.round())),
                      ),
                margin: view.marginAt(leg),
                fuel: switch (view.fuelFor(leg)) {
                  null => null,
                  final f => l.courseLegFuel(
                    f.carbs.round(),
                    (f.fluid / 1000).toStringAsFixed(1),
                  ),
                },
              ),
            const SizedBox(height: 6),
            Text(
              l.coursePlanNote,
              style: TextStyle(fontSize: 11, color: fjInk70),
            ),
          ],
          // Three actions: they wrap onto a second line on a narrow phone.
          Wrap(
            children: [
              TextButton(
                onPressed: () => _start(context, ref),
                child: Text(
                  start == null
                      ? l.courseSetStart
                      : l.courseStartAt(DateFormat.Hm().format(start)),
                ),
              ),
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => _RaceDayEditor(view: view),
                ),
                child: Text(l.courseRaceDay),
              ),
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => _CheckpointEditor(view: view),
                ),
                child: Text(l.courseCheckpoints),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegRow extends StatelessWidget {
  const _LegRow({
    required this.name,
    required this.leg,
    required this.clock,
    required this.margin,
    this.fuel,
  });
  final String name;
  final PlannedLeg leg;
  final String? clock;
  final Duration? margin;

  /// What to take on the leg, written out.
  final String? fuel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = margin;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  [
                    '${leg.leg.km.toStringAsFixed(1)} km',
                    '+${leg.leg.gain.round()} / −${leg.leg.loss.round()} m',
                    formatHoursMinutes(leg.seconds),
                    if (leg.darkHours >= 0.05)
                      l.courseInDark(formatHoursMinutes(leg.darkHours * 3600)),
                    ?fuel,
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: fjInk70),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                clock ?? formatHoursMinutes(leg.arrival),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (m != null)
                Text(
                  m.isNegative
                      ? l.courseLate(
                          formatHoursMinutes(-m.inSeconds.toDouble()),
                        )
                      : l.courseAhead(
                          formatHoursMinutes(m.inSeconds.toDouble()),
                        ),
                  style: TextStyle(
                    fontSize: 12,
                    color: m.isNegative
                        ? Colors.red
                        : m.inMinutes < 30
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaceTable extends StatelessWidget {
  const _PaceTable({required this.table});
  final GradePaceTable table;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SectionCard(
      title: l.coursePace,
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.coursePaceNote(formatPace(table.flatPace)),
            style: TextStyle(fontSize: 12, color: fjInk70),
          ),
          const SizedBox(height: 6),
          for (final b in table.bands)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${formatGrade(b.from)}…${formatGrade(b.to)}',
                      style: TextStyle(color: Color(gradeArgb(b.grade))),
                    ),
                  ),
                  Expanded(child: Text(formatPace(b.pace))),
                  Text(
                    b.grade.abs() < 0.03
                        ? ''
                        : '${b.verticalSpeed.round()} m/h',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The race library: the goal's name searched, then the distance whose
/// course to use, the one nearest the goal first.
class _LibraryPicker extends ConsumerStatefulWidget {
  const _LibraryPicker({required this.goal});
  final RaceGoal goal;

  @override
  ConsumerState<_LibraryPicker> createState() => _LibraryPickerState();
}

class _LibraryPickerState extends ConsumerState<_LibraryPicker> {
  late final _query = TextEditingController(text: widget.goal.name);
  List<RaceHit>? _hits;
  RaceEdition? _edition;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    final hits = await ref
        .read(raceCourseActionsProvider)
        .library
        .search(_query.text);
    if (mounted) {
      setState(() {
        _hits = hits;
        _edition = null;
        _busy = false;
      });
    }
  }

  Future<void> _open(RaceHit hit) async {
    final id = hit.editionId;
    if (id == null) return;
    setState(() => _busy = true);
    final e = await ref.read(raceCourseActionsProvider).library.edition(id);
    if (mounted) {
      setState(() {
        _edition = e;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = _edition;
    final goalKm = widget.goal.distanceM / 1000;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _query,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.courseSearchLibrary,
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          if (_busy) const LinearProgressIndicator(),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: ListView(
              shrinkWrap: true,
              children: e == null
                  ? [
                      if (_hits?.isEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(l.courseNoRaceFound),
                        ),
                      for (final h in _hits ?? const <RaceHit>[])
                        ListTile(
                          title: Text(h.title),
                          subtitle: Text(
                            [
                              if (h.date != null)
                                DateFormat.yMMMd().format(h.date!),
                              for (final km in h.distancesKm)
                                formatKm(km * 1000),
                            ].join(' · '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(h),
                        ),
                    ]
                  : [
                      for (final r
                          in [...e.races]..sort(
                            (a, b) => (a.distanceKm - goalKm).abs().compareTo(
                              (b.distanceKm - goalKm).abs(),
                            ),
                          ))
                        ListTile(
                          enabled: r.hasCourse,
                          title: Text(
                            '${r.name ?? e.title} · ${formatKm(r.distanceKm * 1000)}',
                          ),
                          subtitle: Text(
                            r.hasCourse
                                ? [
                                    l.courseTitle,
                                    if (r.aidStations.isNotEmpty)
                                      l.courseAidStations(r.aidStations.length),
                                    if (r.elevationGainM != null)
                                      '+${r.elevationGainM} m',
                                  ].join(' · ')
                                : l.courseNoLibraryCourse,
                          ),
                          onTap: r.hasCourse
                              ? () => Navigator.pop(context, r)
                              : null,
                        ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Checkpoints: name, kilometre, cut-off as time after the start.
class _CheckpointEditor extends ConsumerStatefulWidget {
  const _CheckpointEditor({required this.view});
  final RaceCourseView view;

  @override
  ConsumerState<_CheckpointEditor> createState() => _CheckpointEditorState();
}

class _CheckpointRow {
  _CheckpointRow(CourseCheckpoint c, DateTime? start)
    : name = TextEditingController(text: c.name),
      km = TextEditingController(
        text: c.km == 0 ? '' : c.km.toStringAsFixed(1),
      ),
      cutoff = TextEditingController(
        text: c.cutoff == null || start == null
            ? ''
            : formatHoursMinutes(
                c.cutoff!.difference(start).inSeconds.toDouble(),
              ),
      );
  final TextEditingController name, km, cutoff;

  void dispose() {
    name.dispose();
    km.dispose();
    cutoff.dispose();
  }
}

class _CheckpointEditorState extends ConsumerState<_CheckpointEditor> {
  late final _start = widget.view.startAt;
  late final _rows = [
    for (final c in widget.view.course.checkpoints) _CheckpointRow(c, _start),
  ];

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final out = <CourseCheckpoint>[];
    for (final r in _rows) {
      final km = double.tryParse(r.km.text.replaceAll(',', '.'));
      if (km == null || r.name.text.trim().isEmpty) continue;
      final m = RegExp(
        r'^(\d{1,3})[:.](\d{2})$',
      ).firstMatch(r.cutoff.text.trim());
      final after = m == null
          ? null
          : Duration(hours: int.parse(m[1]!), minutes: int.parse(m[2]!));
      out.add(
        CourseCheckpoint(
          name: r.name.text.trim(),
          km: km,
          cutoff: after == null || _start == null ? null : _start.add(after),
        ),
      );
    }
    await ref
        .read(raceCourseActionsProvider)
        .setCheckpoints(widget.view.goal.id, out);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.courseCheckpoints,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_start == null)
            Text(l.courseSetStartFirst, style: TextStyle(color: fjInk70)),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final (i, r) in _rows.indexed)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: r.name,
                          decoration: InputDecoration(
                            labelText: l.courseCheckpointName,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: r.km,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'km'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: r.cutoff,
                          enabled: _start != null,
                          decoration: InputDecoration(
                            labelText: l.courseCutoff,
                            hintText: 'h:mm',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () =>
                            setState(() => _rows.removeAt(i).dispose()),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l.courseCheckpointAdd),
            onPressed: () => setState(
              () => _rows.add(
                _CheckpointRow(const CourseCheckpoint(name: '', km: 0), _start),
              ),
            ),
          ),
          FilledButton(onPressed: _save, child: Text(l.save)),
        ],
      ),
    );
  }
}

/// Race-day expectations: the day's high, how much slower in the dark,
/// minutes at each aid station.
class _RaceDayEditor extends ConsumerStatefulWidget {
  const _RaceDayEditor({required this.view});
  final RaceCourseView view;

  @override
  ConsumerState<_RaceDayEditor> createState() => _RaceDayEditorState();
}

class _RaceDayEditorState extends ConsumerState<_RaceDayEditor> {
  late final RacePlanSettings _start = widget.view.course.settings;
  late final _high = TextEditingController(
    text: _start.highTempC?.round().toString() ?? '',
  );
  late final _stop = TextEditingController(
    text: _start.stopMinutes == 0 ? '' : '${_start.stopMinutes}',
  );
  late var _night = (_start.nightSlowdown * 100).round();

  @override
  void dispose() {
    _high.dispose();
    _stop.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref
        .read(raceCourseActionsProvider)
        .setSettings(
          widget.view.goal.id,
          RacePlanSettings(
            highTempC: double.tryParse(_high.text.trim().replaceAll(',', '.')),
            nightSlowdown: _night / 100,
            stopMinutes: (int.tryParse(_stop.text.trim()) ?? 0).clamp(0, 120),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.courseRaceDay, style: Theme.of(context).textTheme.titleLarge),
          TextField(
            controller: _high,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: l.courseHigh,
              helperText: l.courseHighNote,
              helperMaxLines: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(l.courseNight),
          Slider(
            value: _night.toDouble(),
            max: 30,
            divisions: 6,
            label: '$_night %',
            onChanged: (v) => setState(() => _night = v.round()),
          ),
          Text(
            l.courseNightNote,
            style: TextStyle(fontSize: 12, color: fjInk70),
          ),
          TextField(
            controller: _stop,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.courseStop),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: Text(l.save)),
        ],
      ),
    );
  }
}

/// The last eight weeks of running next to what the course asks for.
class _Readiness extends StatelessWidget {
  const _Readiness({required this.readiness});
  final RaceReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = readiness;
    Widget row(String label, String you, String course) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            l.courseVersus(you, course),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    return SectionCard(
      title: l.courseReadiness,
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.courseReadinessNote,
            style: TextStyle(fontSize: 12, color: fjInk70),
          ),
          const SizedBox(height: 6),
          row(
            l.courseLongestRun,
            formatHoursMinutes(r.longestRun),
            formatHoursMinutes(r.raceTime),
          ),
          row(
            l.courseWeekClimb,
            '${r.bestWeekClimb.round()} m',
            '${r.courseClimb.round()} m',
          ),
          row(
            l.courseBiggestClimb,
            '${r.longestClimb.round()} m',
            '${r.courseLongestClimb.round()} m',
          ),
          row(
            l.courseBiggestDescent,
            '${r.longestDescent.round()} m',
            '${r.courseLongestDescent.round()} m',
          ),
        ],
      ),
    );
  }
}

/// After the race: each checkpoint as planned and as run.
class _Result extends StatelessWidget {
  const _Result({required this.result});
  final RaceResult result;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SectionCard(
      title: l.courseResult,
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.courseResultNote,
            style: TextStyle(fontSize: 12, color: fjInk70),
          ),
          for (final (i, leg) in result.legs.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      i == result.legs.length - 1
                          ? l.courseFinish
                          : leg.planned.leg.to,
                    ),
                  ),
                  Text(
                    '${formatHoursMinutes(leg.planned.arrival)} → '
                    '${formatHoursMinutes(leg.arrival)}',
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      leg.behind > 0
                          ? l.courseSlower(formatHoursMinutes(leg.behind))
                          : l.courseFaster(formatHoursMinutes(-leg.behind)),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 12,
                        color: leg.behind > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
