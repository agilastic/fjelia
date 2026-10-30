import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/local_model_provider.dart';
import '../../services/local_model_service.dart';
import '../../widgets/app_widgets.dart';

class LocalModelPanel extends ConsumerWidget {
  const LocalModelPanel({super.key, required this.modelId});
  final String modelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SectionCard(
    title: '${localModelSpec(modelId).label} · MLX · 4-bit',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.localModelDescription,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.localModelRamGb(localModelSpec(modelId).minimumMemoryGb),
          style: const TextStyle(fontSize: 11, color: muted),
        ),
        const SizedBox(height: 12),
        ref
            .watch(localModelProvider(modelId))
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(context.l10n.localModelCouldNotAnswer),
              data: (status) {
                final actions = ref.read(localModelProvider(modelId).notifier);
                if (!status.supported) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        switch (status.reason) {
                          'memory' => context.l10n.localModelMemoryUnsupported,
                          'device' => context.l10n.localModelIPhone18,
                          _ => context.l10n.localModelUnsupported,
                        },
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.amber,
                        ),
                      ),
                      if (status.installed || status.downloadedBytes > 0)
                        TextButton.icon(
                          onPressed: () => runUiAction(context, actions.remove),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(context.l10n.localModelRemove),
                        ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.localModelSizeMb(
                        valueText(status.totalBytes / 1e6),
                      ),
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    if (status.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.localModelDownloadFailed,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                    if (status.downloading) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: status.progress),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.localModelDownloading(
                          valueText(status.downloadedBytes / 1e6),
                          valueText(status.totalBytes / 1e6),
                        ),
                      ),
                      TextButton(
                        onPressed: actions.cancelDownload,
                        child: Text(context.l10n.cancel),
                      ),
                    ] else if (status.installed) ...[
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.localModelInstalled,
                        style: const TextStyle(color: mint, fontSize: 12),
                      ),
                      TextButton.icon(
                        onPressed: () => runUiAction(context, actions.remove),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(context.l10n.localModelRemove),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => runUiAction(context, actions.download),
                        icon: const Icon(Icons.download_outlined),
                        label: Text(
                          status.downloadedBytes > 0
                              ? context.l10n.localModelResumeDownload
                              : context.l10n.localModelDownload,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        TextButton.icon(
          onPressed: () => runUiAction(context, () async {
            final url = Uri.parse('https://huggingface.co/$modelId');
            final failure = context.l10n.couldNotOpenKey('Hugging Face');
            if (!await launchUrl(url)) {
              throw StateError(failure);
            }
          }),
          icon: const Icon(Icons.open_in_new, size: 14),
          label: Text(context.l10n.localModelInfo),
        ),
      ],
    ),
  );
}
