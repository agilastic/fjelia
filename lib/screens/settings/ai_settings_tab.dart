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
    title: 'AI & More',
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
                const SectionLabel('AI Coach'),
                SectionCard(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable AI Coach'),
                    subtitle: const Text(
                      'On-device AI or cloud provider',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                    value: s.enabled,
                    onChanged: (v) =>
                        runUiAction(context, () => n.setEnabled(v)),
                  ),
                ),
                const SectionLabel('Provider'),
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
                          AiProvider.openai => 'OpenAI',
                          AiProvider.appleIntelligence => 'Apple Intelligence',
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
                    decoration: const InputDecoration(labelText: 'Model'),
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
                  const SectionCard(
                    child: Text(
                      'Apple Intelligence is not available on this device '
                      '(it needs a supported iPhone or Mac with iOS/macOS 26 '
                      'or later and Apple Intelligence switched on in '
                      'Settings). Choose another provider and add your own '
                      'API key to use the coach.',
                      style: TextStyle(fontSize: 11, color: Colors.amber),
                    ),
                  ),
                if (s.provider == AiProvider.appleIntelligence)
                  const SectionCard(
                    child: Text(
                      'Chat and AI briefings use Apple Intelligence on this device. No API key required. If the model is unavailable, briefings show a non-AI summary.',
                      style: TextStyle(color: mint, fontSize: 12),
                    ),
                  ),
                const SectionLabel('Briefing'),
                for (final mode in BriefingMode.values)
                  ListTile(
                    title: Text(switch (mode) {
                      BriefingMode.ai => 'AI Briefing',
                      BriefingMode.static_ => 'Non-AI Briefing',
                      BriefingMode.none => 'No Briefing',
                    }),
                    subtitle: Text(switch (mode) {
                      BriefingMode.ai =>
                        'Personalised morning/lunch/afternoon/evening summary',
                      BriefingMode.static_ =>
                        'Rule-based summary from your health data — no API calls',
                      BriefingMode.none => 'Hide the briefing card',
                    }, style: const TextStyle(color: muted, fontSize: 10)),
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
                    title: const Text('Use Apple Intelligence for briefings'),
                    subtitle: const Text(
                      'Use on-device AI for briefings while keeping the selected provider for chat.',
                    ),
                    value: s.appleIntelligenceForBriefing,
                    onChanged: (v) => runUiAction(
                      context,
                      () => n.setAppleIntelligenceForBriefing(v),
                    ),
                  ),
                const SectionLabel('Health data sharing'),
                SwitchListTile(
                  title: const Text('Ask once per chat session'),
                  subtitle: const Text(
                    'Otherwise ask before every cloud message',
                  ),
                  value: s.consentMode == AiConsentMode.session,
                  onChanged: (v) => runUiAction(
                    context,
                    () => n.setConsentMode(
                      v ? AiConsentMode.session : AiConsentMode.everyMessage,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () =>
                      showAppSheet(context, const BugReportSheet()),
                  child: const Text('Report a Bug'),
                ),
                const SectionLabel('Weather data'),
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
                    trailing: const Icon(Icons.open_in_new, size: 14),
                    onTap: () => runUiAction(context, () async {
                      if (!await launchUrl(Uri.parse(e.value))) {
                        throw StateError('Could not open ${e.key}');
                      }
                    }),
                  ),
                const SectionLabel('Open source libraries'),
                for (final library in const [
                  ('Flutter', 'UI framework by Google'),
                  ('flutter_riverpod', 'State management'),
                  ('drift', 'SQLite ORM'),
                  ('flutter_blue_plus', 'Bluetooth LE'),
                  ('flutter_map', 'Interactive maps'),
                  ('fl_chart', 'Charts & graphs'),
                  ('flutter_secure_storage', 'Secure credential storage'),
                  ('flutter_markdown', 'Markdown rendering'),
                  ('foundation_models_framework', 'Apple on-device AI'),
                  ('http', 'HTTP clients'),
                  ('encrypt / pointycastle', 'Cryptography'),
                  ('health', 'Apple Health & Health Connect'),
                  ('permission_handler', 'Runtime permissions'),
                  ('location', 'GPS location'),
                  ('share_plus', 'Share & export'),
                  ('url_launcher', 'Open URLs'),
                  ('intl', 'Internationalisation'),
                  ('uuid / latlong2', 'Utilities'),
                  ('font_awesome_flutter', 'Icons'),
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
                      child: const Text(
                        'License',
                        style: TextStyle(fontSize: 9, color: Colors.lightBlue),
                      ),
                    ),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Fjelia',
                      applicationLegalese:
                          '© 2026 Alex Ebeling-Hoppe\nFree software under the '
                          'GNU General Public License, version 3 or later.',
                    ),
                  ),
                ListTile(
                  title: const Text('Licenses'),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Fjelia',
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
          decoration: const InputDecoration(labelText: 'API key'),
          autocorrect: false,
          enableSuggestions: false,
        ),
      ),
      IconButton(
        tooltip: 'Save API key',
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
