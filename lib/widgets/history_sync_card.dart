import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_provider.dart';
import 'app_widgets.dart';

/// Progress of the background history import (first run after onboarding,
/// or a manual full sync): current step, progress bar and finished steps.
class HistorySyncCard extends ConsumerWidget {
  const HistorySyncCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(historicSyncProvider);
    if (!s.running && !s.done) return const SizedBox.shrink();
    final total = s.total ?? 0;
    final value = s.running && total > 0
        ? (s.progress ?? 0) / total
        : s.running
        ? null
        : 1.0;
    final notifier = ref.read(historicSyncProvider.notifier);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mint.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                s.failed
                    ? Icons.error_outline
                    : s.done
                    ? Icons.check_circle_outline
                    : Icons.cloud_download_outlined,
                color: s.failed ? Colors.orange : mint,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.done
                      ? (s.failed
                            ? context.l10n.historyImportIncomplete
                            : context.l10n.yourTrainingHistoryIsReady)
                      : context.l10n.importingYourTrainingHistory,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: s.running
                    ? context.l10n.stopImport
                    : context.l10n.dismiss,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: s.running ? notifier.cancel : notifier.dismiss,
              ),
            ],
          ),
          if (s.phase != null)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Text(
                s.phase!,
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: LinearProgressIndicator(
              value: value,
              color: mint,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          for (final step in s.completed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    step.contains('failed') ? Icons.close : Icons.check,
                    size: 14,
                    color: step.contains('failed') ? Colors.orange : mint,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(step, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          if (s.running)
            Padding(
              padding: EdgeInsets.only(top: 8, right: 8),
              child: Text(
                context.l10n.youCanKeepUsingFjelia,
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ),
        ],
      ),
    );
  }
}
