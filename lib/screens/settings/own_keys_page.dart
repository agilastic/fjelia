import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/build_features.dart';
import '../../config/secrets.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/own_keys_provider.dart';
import '../../widgets/app_widgets.dart';

/// Fjelia CE: the user's own keys for Polar and the optional weather
/// services, with where to get each. AI keys stay under AI & more.
class OwnKeysPage extends ConsumerWidget {
  const OwnKeysPage({super.key});

  static const polarRedirect = '$authCallbackScheme://polar-callback';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final entered = ref.watch(ownKeysProvider).valueOrNull ?? const {};
    Widget service(
      String title,
      String hint,
      Uri link,
      List<(OwnKey, String)> fields,
    ) => SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(hint, style: TextStyle(fontSize: 12, color: muted)),
          TextButton.icon(
            onPressed: () =>
                launchUrl(link, mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(l.ownKeysGet),
          ),
          for (final (key, label) in fields)
            _KeyField(
              key: ValueKey(key),
              label: label,
              entered: entered.contains(key),
              onSave: (value) => saveOwnKey(ref, key, value),
            ),
        ],
      ),
    );
    return SheetPage(
      title: l.ownKeys,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.ownKeysIntro, style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 12),
          service(
            'Polar Flow',
            l.ownKeysPolarHint(polarRedirect),
            Uri.https('admin.polaraccesslink.com'),
            [
              (OwnKey.polarClientId, 'Client ID'),
              (OwnKey.polarClientSecret, 'Client Secret'),
            ],
          ),
          const SizedBox(height: 12),
          service(
            'Pirate Weather',
            l.ownKeysWeatherHint,
            Uri.https('pirateweather.net'),
            [(OwnKey.pirateWeather, l.apiKey)],
          ),
          const SizedBox(height: 12),
          service(
            'WeatherAPI',
            l.ownKeysWeatherHint,
            Uri.https('www.weatherapi.com', '/signup.aspx'),
            [(OwnKey.weatherApi, l.apiKey)],
          ),
          const SizedBox(height: 16),
          Text(
            l.ownKeysAiHint(l.aiAndMore),
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }
}

/// One key: hidden while typed, saved with the button; an empty save removes
/// it. A saved key is never shown again, only that one is set.
class _KeyField extends StatefulWidget {
  const _KeyField({
    super.key,
    required this.label,
    required this.entered,
    required this.onSave,
  });
  final String label;
  final bool entered;
  final Future<void> Function(String) onSave;
  @override
  State<_KeyField> createState() => _KeyFieldState();
}

class _KeyFieldState extends State<_KeyField> {
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
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.entered ? context.l10n.ownKeysSaved : null,
          ),
        ),
      ),
      IconButton(
        tooltip: context.l10n.saveApiKey,
        onPressed: saving
            ? null
            : () async {
                setState(() => saving = true);
                await runUiAction(context, () => widget.onSave(c.text));
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
