import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/threshold_overview_provider.dart';
import '../../widgets/app_widgets.dart';

/// LT1, LT2 (running, cycling) and FTP from every source side by side, the
/// value in use, and a proposal to apply or keep.
class ThresholdOverviewSection extends ConsumerWidget {
  const ThresholdOverviewSection({super.key, this.footer});

  /// Shown under the FTP card (the manual FTP button).
  final Widget? footer;

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
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              for (final row in overview.rows)
                _ThresholdCard(
                  row: row,
                  locked: overview.coachLocked,
                  footer: row.kind == ThresholdKind.ftp ? footer : null,
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

class _ThresholdCard extends ConsumerWidget {
  const _ThresholdCard({required this.row, required this.locked, this.footer});
  final ThresholdRow row;
  final bool locked;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final proposal = row.proposal;
    final now = DateTime.now();
    final actions = ref.read(thresholdActionsProvider);
    return SectionCard(
      title: thresholdTitle(row.kind),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.thresholdInUse(
              row.inUse == null
                  ? '—'
                  : thresholdValue(row.kind, row.inUse!, row.inUsePaceSecPerKm),
            ),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (proposal != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mint.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: mint.withValues(alpha: .4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.thresholdProposal(
                      thresholdValue(
                        row.kind,
                        proposal.value,
                        proposal.paceSecPerKm,
                      ),
                      thresholdSourceLabel(proposal),
                    ),
                  ),
                  if (locked)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        l10n.thresholdsCoachLocked,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => runUiAction(
                            context,
                            () => actions.keep(proposal),
                          ),
                          child: Text(l10n.keepCurrent),
                        ),
                        FilledButton(
                          onPressed: () => runUiAction(
                            context,
                            () => actions.apply(proposal),
                          ),
                          child: Text(l10n.apply),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
          if (row.candidates.isNotEmpty) const SizedBox(height: 8),
          for (final c in row.candidates)
            _CandidateLine(
              candidate: c,
              best: identical(c, row.best),
              stale: !c.isFresh(now),
            ),
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
  });
  final ThresholdCandidate candidate;
  final bool best, stale;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final color = stale ? Colors.white38 : Colors.white70;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            best ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: best ? mint : Colors.white24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                thresholdSourceLabel(c),
                if (c.date != null)
                  DateFormat.yMMMd().format(c.date!.toLocal()),
                if (stale) context.l10n.thresholdStale,
              ].join(' · '),
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
          Text(
            thresholdValue(c.kind, c.value, c.paceSecPerKm),
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
