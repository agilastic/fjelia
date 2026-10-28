import '../../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/ai_coach_provider.dart';
import '../../services/ai_coach_settings.dart';
import '../../widgets/app_widgets.dart';
import 'bug_report_sheet.dart';

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
                      AiProvider.appleIntelligence,
                      ...AiProvider.values.where(
                        (p) => p != AiProvider.appleIntelligence,
                      ),
                    ])
                      ChoiceChip(
                        label: Text(switch (p) {
                          AiProvider.openai => context.l10n.openai,
                          AiProvider.appleIntelligence =>
                            context.l10n.appleIntelligence,
                          _ => p.name[0].toUpperCase() + p.name.substring(1),
                        }),
                        selected: s.provider == p,
                        onSelected: (_) =>
                            runUiAction(context, () => n.setProvider(p)),
                      ),
                  ],
                ),
                if (s.provider != AiProvider.appleIntelligence) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
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
                if (s.provider != AiProvider.appleIntelligence)
                  SwitchListTile(
                    title: Text(context.l10n.useAppleIntelligenceForBriefings),
                    subtitle: Text(context.l10n.useOnDeviceAiFor),
                    value: s.appleIntelligenceForBriefing,
                    onChanged: (v) => runUiAction(
                      context,
                      () => n.setAppleIntelligenceForBriefing(v),
                    ),
                  ),
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
                OutlinedButton(
                  onPressed: () => showAppSheet(context, BugReportSheet()),
                  child: Text(context.l10n.reportABug),
                ),
                SectionLabel(context.l10n.weatherData),
                for (final e in {
                  'Open-Meteo': 'https://open-meteo.com',
                  'Pirate Weather': 'https://pirateweather.net',
                  'Bright Sky (DWD)': 'https://brightsky.dev',
                  'WeatherAPI.com': 'https://www.weatherapi.com',
                  'OpenStreetMap': 'https://www.openstreetmap.org',
                  'RainViewer': 'https://www.rainviewer.com',
                }.entries)
                  ListTile(
                    dense: true,
                    title: Text(e.key),
                    trailing: Icon(Icons.open_in_new, size: 14),
                    onTap: () => runUiAction(context, () async {
                      if (!await launchUrl(Uri.parse(e.value))) {
                        throw StateError(tr.couldNotOpenKey(e.key));
                      }
                    }),
                  ),
                SectionLabel(context.l10n.openSourceLibraries),
                for (final library in [
                  (context.l10n.flutter, context.l10n.uiFrameworkByGoogle),
                  ('flutter_riverpod', context.l10n.stateManagement),
                  ('drift', context.l10n.sqliteOrm),
                  ('flutter_blue_plus', context.l10n.bluetoothLe),
                  ('flutter_map', context.l10n.interactiveMaps),
                  ('fl_chart', context.l10n.chartsGraphs),
                  (
                    'flutter_secure_storage',
                    context.l10n.secureCredentialStorage,
                  ),
                  ('flutter_markdown', context.l10n.markdownRendering),
                  ('foundation_models_framework', context.l10n.appleOnDeviceAi),
                  ('http', context.l10n.httpClients),
                  ('encrypt / pointycastle', context.l10n.cryptography),
                  ('health', context.l10n.appleHealthHealthConnect),
                  ('permission_handler', context.l10n.runtimePermissions),
                  ('location', context.l10n.gpsLocation),
                  ('share_plus', context.l10n.shareExport),
                  ('url_launcher', context.l10n.openUrls),
                  ('intl', context.l10n.internationalisation),
                  ('uuid / latlong2', context.l10n.utilities),
                  ('font_awesome_flutter', context.l10n.icons),
                ])
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      library.$1,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      library.$2,
                      style: const TextStyle(fontSize: 10, color: muted),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.l10n.license,
                        style: TextStyle(fontSize: 9, color: Colors.lightBlue),
                      ),
                    ),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: context.l10n.fjelia,
                      applicationLegalese:
                          '© 2026 Alex Ebeling-Hoppe\nFree software under the '
                          'GNU General Public License, version 3 or later.',
                    ),
                  ),
                ListTile(
                  title: Text(context.l10n.licenses),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: context.l10n.fjelia,
                    applicationLegalese:
                        '© 2026 Alex Ebeling-Hoppe\nFree software under the '
                        'GNU General Public License, version 3 or later.',
                  ),
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
