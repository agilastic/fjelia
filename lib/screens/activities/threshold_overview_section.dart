import '../../theme/fjelia_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/l10n_ext.dart';
import '../../providers/threshold_overview_provider.dart';
import '../../widgets/app_widgets.dart';

/// LT1, LT2 (running, cycling) and FTP from every source side by side, the
/// value in use, and a proposal to apply or keep.
class ThresholdOverviewSection extends ConsumerWidget {
  const ThresholdOverviewSection({super.key, this.footers = const {}});

  /// Shown under a threshold's card: its manual test or entry.
  final Map<ThresholdKind, Widget> footers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(thresholdOverviewProvider)
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => DataError(e),
          data: (overview) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.thresholdOrderNote,
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              for (final row in overview.rows)
                _ThresholdCard(
                  row: row,
                  locked: overview.coachLocked,
                  footer: footers[row.kind],
                ),
            ],
          ),
        );
  }
}

String thresholdTitle(ThresholdKind kind) => switch (kind) {
  ThresholdKind.lt1 => '${tr.lt1} · ${tr.aerobicThreshold}',
  ThresholdKind.lt2 => '${tr.lt2} · ${tr.lactateThreshold}',
  ThresholdKind.lt2Bike => tr.lt2Cycling,
  ThresholdKind.ftp => tr.ftp,
};

String thresholdSourceLabel(ThresholdCandidate c) => switch (c.source) {
  'tt' => tr.thresholdSourceTt,
  'drift' => tr.thresholdSourceDrift,
  'garmin_api' => tr.garmin,
  'coros' => tr.coros2,
  'dfa' => tr.thresholdSourceDfa(c.sessions ?? 0),
  'eftp' => tr.thresholdSourceEftp,
  'polar_profile' => tr.thresholdSourcePolarProfile,
  _ => c.note ?? c.source,
};

String thresholdValue(ThresholdKind kind, int value, int? pace) => [
  kind == ThresholdKind.ftp ? '$value W' : '$value bpm',
  if (pace != null)
    '${pace ~/ 60}:${(pace % 60).toString().padLeft(2, '0')} /km',
].join(' · ');

/// Colour, icon and one-line meaning of each threshold.
({Color color, IconData icon, String title, String meaning}) _look(
  ThresholdKind kind,
) => switch (kind) {
  ThresholdKind.lt1 => (
    color: const Color(0xFF00D4A0),
    icon: Icons.directions_run,
    title: tr.lt1,
    meaning: tr.aerobicThreshold,
  ),
  ThresholdKind.lt2 => (
    color: const Color(0xFFFF8A3D),
    icon: Icons.local_fire_department_outlined,
    title: tr.lt2,
    meaning: tr.lactateThreshold,
  ),
  ThresholdKind.lt2Bike => (
    color: const Color(0xFF4FC3F7),
    icon: Icons.directions_bike,
    title: tr.lt2Cycling,
    meaning: tr.lactateThreshold,
  ),
  ThresholdKind.ftp => (
    color: const Color(0xFFFFC94D),
    icon: Icons.bolt,
    title: tr.ftp,
    meaning: tr.functionalThresholdPower,
  ),
};

IconData _sourceIcon(String source) => switch (source) {
  'tt' || 'drift' => Icons.science_outlined,
  'garmin_api' || 'coros' => Icons.watch_outlined,
  'dfa' => Icons.monitor_heart_outlined,
  'eftp' => Icons.directions_bike_outlined,
  'polar_profile' => Icons.person_outline,
  _ => Icons.calculate_outlined,
};

String _pace(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')} /km';

class _ThresholdCard extends ConsumerWidget {
  const _ThresholdCard({required this.row, required this.locked, this.footer});
  final ThresholdRow row;
  final bool locked;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final look = _look(row.kind);
    final proposal = row.proposal;
    final now = DateTime.now();
    final actions = ref.read(thresholdActionsProvider);
    final unit = row.kind == ThresholdKind.ftp ? 'W' : 'bpm';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            look.color.withValues(alpha: .13),
            duo(0xFF1C1C1C, 0xFFFFFFFF),
          ],
          stops: const [0, .55],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: look.color.withValues(alpha: .25)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Which threshold, and what it means.
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: look.color.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: Icon(look.icon, size: 17, color: look.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      look.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      look.meaning,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // The value zones and plan use, big.
          Text(
            l10n.thresholdInUse('').replaceAll(':', '').trim().toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 1.2,
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                row.inUse?.toString() ?? '—',
                style: TextStyle(
                  fontSize: 38,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: look.color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 5),
              Text(unit, style: TextStyle(fontSize: 14, color: fjInk70)),
              if (row.inUsePaceSecPerKm case final pace?) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: fjInk.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _pace(pace),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Every source on one scale: do they agree?
          if (row.candidates.length > 1 || row.inUse != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              width: double.infinity,
              child: CustomPaint(
                painter: _RangePainter(
                  values: [
                    for (final c in row.candidates)
                      if (c.isFresh(now))
                        (c.value.toDouble(), identical(c, row.best)),
                  ],
                  inUse: row.inUse?.toDouble(),
                  proposed: proposal?.value.toDouble(),
                  color: look.color,
                ),
              ),
            ),
          ],
          if (proposal != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    mint.withValues(alpha: .22),
                    mint.withValues(alpha: .08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: mint.withValues(alpha: .5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_sourceIcon(proposal.source), size: 16, color: mint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.thresholdProposal(
                            thresholdValue(
                              row.kind,
                              proposal.value,
                              proposal.paceSecPerKm,
                            ),
                            thresholdSourceLabel(proposal),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (locked)
                    Text(
                      l10n.thresholdsCoachLocked,
                      style: TextStyle(color: muted, fontSize: 12),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => runUiAction(
                              context,
                              () => actions.keep(proposal),
                            ),
                            child: Text(l10n.keepCurrent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: mint,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => runUiAction(
                              context,
                              () => actions.apply(proposal),
                            ),
                            child: Text(l10n.apply),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
          if (row.candidates.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final c in row.candidates)
              _CandidateLine(
                candidate: c,
                best: identical(c, row.best),
                stale: !c.isFresh(now),
                color: look.color,
              ),
          ],
          ?footer,
        ],
      ),
    );
  }
}

class _CandidateLine extends StatelessWidget {
  const _CandidateLine({
    required this.candidate,
    required this.best,
    required this.stale,
    required this.color,
  });
  final ThresholdCandidate candidate;
  final bool best, stale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    return Opacity(
      opacity: stale ? .45 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: best
              ? color.withValues(alpha: .1)
              : fjInk.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              _sourceIcon(c.source),
              size: 16,
              color: best ? color : fjInk54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thresholdSourceLabel(c),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: best ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (c.date != null || stale)
                    Text(
                      [
                        if (c.date case final d?)
                          DateFormat.yMMMd().format(d.toLocal()),
                        if (stale) context.l10n.thresholdStale,
                      ].join(' · '),
                      style: TextStyle(fontSize: 10, color: muted),
                    ),
                ],
              ),
            ),
            Text(
              thresholdValue(c.kind, c.value, c.paceSecPerKm),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: best ? color : fjInk,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (best) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, size: 15, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

/// The sources as dots on one scale, the value in use as a marker and the
/// proposal as a ring: at a glance whether they agree.
class _RangePainter extends CustomPainter {
  _RangePainter({
    required this.values,
    required this.inUse,
    required this.proposed,
    required this.color,
  });

  final List<(double, bool)> values;
  final double? inUse, proposed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final all = [for (final v in values) v.$1, ?inUse];
    if (all.isEmpty) return;
    var lo = all.reduce((a, b) => a < b ? a : b);
    var hi = all.reduce((a, b) => a > b ? a : b);
    // At least a little scale, so agreeing values sit in the middle.
    final pad = ((hi - lo) * .15).clamp(3.0, 40.0);
    lo -= pad;
    hi += pad;
    const side = 14.0;
    double x(double v) => side + (v - lo) / (hi - lo) * (size.width - 2 * side);
    final y = size.height * .55;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(side, y - 2, size.width - side, y + 2),
        const Radius.circular(2),
      ),
      Paint()..color = fjInk12,
    );
    if (values.length > 1) {
      final vs = values.map((v) => v.$1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x(vs.reduce((a, b) => a < b ? a : b)),
            y - 2,
            x(vs.reduce((a, b) => a > b ? a : b)),
            y + 2,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = color.withValues(alpha: .35),
      );
    }
    for (final (v, best) in values) {
      canvas.drawCircle(
        Offset(x(v), y),
        best ? 5.5 : 4,
        Paint()..color = best ? color : fjInk70,
      );
    }
    if (proposed case final p?) {
      canvas.drawCircle(
        Offset(x(p), y),
        8,
        Paint()
          ..color = mint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (inUse case final v?) {
      final px = x(v);
      canvas
        ..drawLine(
          Offset(px, y - 11),
          Offset(px, y + 11),
          Paint()
            ..color = fjInk
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        )
        ..drawPath(
          Path()
            ..moveTo(px - 5, 0)
            ..lineTo(px + 5, 0)
            ..lineTo(px, 6)
            ..close(),
          Paint()..color = fjInk,
        );
    }
    // Lowest and highest value at the ends.
    void label(String text, double at, TextAlign align) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: muted, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = align == TextAlign.left ? at : at - tp.width;
      tp.paint(canvas, Offset(left, size.height - tp.height));
    }

    label('${(lo + pad).round()}', side, TextAlign.left);
    label('${(hi - pad).round()}', size.width - side, TextAlign.right);
  }

  @override
  bool shouldRepaint(_RangePainter old) => true;
}
