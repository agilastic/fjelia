import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ai_coach_provider.dart';
import '../../config/free_ai.dart';
import '../../providers/local_model_provider.dart';
import '../../services/ai_coach_settings.dart';
import '../../services/local_model_catalog.dart';
import '../../widgets/app_widgets.dart';
import 'bug_report_sheet.dart';
import 'local_model_panel.dart';

class AiSettingsTab extends ConsumerWidget {
  const AiSettingsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SheetPage(
    title: context.l10n.aiAndMore,
    child: ref
        .watch(aiCoachSettingsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => DataError(e),
          data: (s) {
            final n = ref.read(aiCoachSettingsProvider.notifier);
            final supports4b =
                s.provider == AiProvider.localQwen &&
                ref.watch(
                  localModelProvider(
                    localQwen4bModelId,
                  ).select((status) => status.valueOrNull?.supported ?? false),
                );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionLabel(context.l10n.aiCoach),
                SectionCard(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.enableAiCoach),
                    subtitle: Text(
                      context.l10n.onDeviceAiOrCloud,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                    value: s.enabled,
                    onChanged: (v) =>
                        runUiAction(context, () => n.setEnabled(v)),
                  ),
                ),
                SectionLabel(context.l10n.provider),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in [
                      AiProvider.freeAi,
                      AiProvider.appleIntelligence,
                      AiProvider.localQwen,
                      ...AiProvider.values.where((p) => p.requiresUserApiKey),
                    ])
                      ChoiceChip(
                        label: Text(switch (p) {
                          AiProvider.openai => context.l10n.openai,
                          AiProvider.appleIntelligence =>
                            context.l10n.appleIntelligence,
                          AiProvider.localQwen => context.l10n.localQwen,
                          AiProvider.freeAi => context.l10n.freeAi,
                          _ => p.name[0].toUpperCase() + p.name.substring(1),
                        }),
                        selected: s.provider == p,
                        onSelected: (_) =>
                            runUiAction(context, () => n.setProvider(p)),
                      ),
                  ],
                ),
                if (s.provider == AiProvider.freeAi)
                  SectionCard(
                    child: Text(
                      s.hasApiKey
                          ? '${context.l10n.freeAiDescription(freeAiHost)} ${context.l10n.freeAiUsageTracking}'
                          : context.l10n.freeAiUnavailable,
                      style: TextStyle(
                        color: s.hasApiKey ? mint : Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (s.provider.requiresUserApiKey) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: s.provider.models.contains(s.model)
                        ? s.model
                        : s.provider.defaultModel,
                    decoration: InputDecoration(labelText: context.l10n.model),
                    items: [
                      for (final m in s.provider.models)
                        DropdownMenuItem(value: m, child: Text(m)),
                    ],
                    onChanged: (v) {
                      if (v != null) runUiAction(context, () => n.setModel(v));
                    },
                  ),
                  const SizedBox(height: 12),
                  _ApiKeyField(
                    key: ValueKey(s.provider),
                    onSave: (key) => n.setApiKey(key),
                  ),
                ],
                if (s.provider == AiProvider.appleIntelligence &&
                    !s.onDeviceAvailable)
                  SectionCard(
                    child: Text(
                      context.l10n.appleIntelligenceIsNotAvailable,
                      style: TextStyle(fontSize: 11, color: Colors.amber),
                    ),
                  ),
                if (s.provider == AiProvider.appleIntelligence)
                  SectionCard(
                    child: Text(
                      context.l10n.chatAndAiBriefingsUse,
                      style: TextStyle(color: mint, fontSize: 12),
                    ),
                  ),
                if (s.provider == AiProvider.localQwen) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey(s.model),
                    initialValue: s.model,
                    decoration: InputDecoration(labelText: context.l10n.model),
                    items: [
                      for (final model in localQwenModels)
                        DropdownMenuItem(
                          value: model.id,
                          enabled: !model.requiresIPhone18 || supports4b,
                          child: Text(
                            '${model.label} · 4-bit${model.requiresIPhone18 ? ' · iPhone 18+' : ''}',
                            style: TextStyle(
                              color: model.requiresIPhone18 && !supports4b
                                  ? muted
                                  : null,
                            ),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        runUiAction(context, () => n.setModel(value));
                      }
                    },
                  ),
                  LocalModelPanel(
                    key: ValueKey('local_${s.model}'),
                    modelId: s.model,
                  ),
                ],
                SectionLabel(context.l10n.briefing),
                for (final mode in BriefingMode.values)
                  ListTile(
                    title: Text(switch (mode) {
                      BriefingMode.ai => context.l10n.aiBriefing,
                      BriefingMode.static_ => context.l10n.nonAiBriefing,
                      BriefingMode.none => context.l10n.noBriefing,
                    }),
                    subtitle: Text(switch (mode) {
                      BriefingMode.ai =>
                        context.l10n.personalisedMorningLunchAfternoonEvening,
                      BriefingMode.static_ =>
                        context.l10n.ruleBasedSummaryFromYour,
                      BriefingMode.none => context.l10n.hideTheBriefingCard,
                    }, style: TextStyle(color: muted, fontSize: 10)),
                    leading: Icon(
                      s.briefingMode == mode
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: mint,
                    ),
                    onTap: () =>
                        runUiAction(context, () => n.setBriefingMode(mode)),
                  ),
                if (s.provider.requiresUserApiKey)
                  SwitchListTile(
                    title: Text(context.l10n.useAppleIntelligenceForBriefings),
                    subtitle: Text(context.l10n.useOnDeviceAiFor),
                    value: s.appleIntelligenceForBriefing,
                    onChanged: (v) => runUiAction(
                      context,
                      () => n.setAppleIntelligenceForBriefing(v),
                    ),
                  ),
                if (!s.provider.isLocal) ...[
                  SectionLabel(context.l10n.healthDataSharing),
                  SwitchListTile(
                    title: Text(context.l10n.askOncePerChatSession),
                    subtitle: Text(context.l10n.otherwiseAskBeforeEveryCloud),
                    value: s.consentMode == AiConsentMode.session,
                    onChanged: (v) => runUiAction(
                      context,
                      () => n.setConsentMode(
                        v ? AiConsentMode.session : AiConsentMode.everyMessage,
                      ),
                    ),
                  ),
                ],
                OutlinedButton(
                  onPressed: () => showAppSheet(context, BugReportSheet()),
                  child: Text(context.l10n.reportABug),
                ),
              ],
            );
          },
        ),
  );
}

class _ApiKeyField extends StatefulWidget {
  const _ApiKeyField({super.key, required this.onSave});
  final Future<void> Function(String) onSave;
  @override
  State<_ApiKeyField> createState() => _ApiKeyState();
}

class _ApiKeyState extends State<_ApiKeyField> {
  final c = TextEditingController();
  bool saving = false;
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: TextField(
          controller: c,
          obscureText: true,
          decoration: InputDecoration(labelText: context.l10n.apiKey),
          autocorrect: false,
          enableSuggestions: false,
        ),
      ),
      IconButton(
        tooltip: context.l10n.saveApiKey,
        onPressed: saving
            ? null
            : () async {
                setState(() => saving = true);
                await runUiAction(context, () => widget.onSave(c.text.trim()));
                if (mounted) {
                  c.clear();
                  setState(() => saving = false);
                }
              },
        icon: const Icon(Icons.save_outlined),
      ),
    ],
  );
}
