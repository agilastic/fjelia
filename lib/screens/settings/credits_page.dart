import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n_ext.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/settings_widgets.dart';

class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsPage(
      title: l10n.creditsAndLicenses,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionLabel(l10n.weatherData),
          for (final entry in {
            'Open-Meteo': 'https://open-meteo.com',
            'Pirate Weather': 'https://pirateweather.net',
            'Bright Sky (DWD)': 'https://brightsky.dev',
            'WeatherAPI.com': 'https://www.weatherapi.com',
            'OpenStreetMap': 'https://www.openstreetmap.org',
            'RainViewer': 'https://www.rainviewer.com',
          }.entries)
            ListTile(
              dense: true,
              title: Text(entry.key),
              trailing: const Icon(Icons.open_in_new, size: 14),
              onTap: () => runUiAction(context, () async {
                if (!await launchUrl(Uri.parse(entry.value))) {
                  throw StateError(l10n.couldNotOpenKey(entry.key));
                }
              }),
            ),
          SectionLabel(l10n.openSourceLibraries),
          for (final library in [
            (l10n.flutter, l10n.uiFrameworkByGoogle),
            ('flutter_riverpod', l10n.stateManagement),
            ('drift', l10n.sqliteOrm),
            ('flutter_blue_plus', l10n.bluetoothLe),
            ('flutter_map', l10n.interactiveMaps),
            ('fl_chart', l10n.chartsGraphs),
            ('flutter_secure_storage', l10n.secureCredentialStorage),
            ('flutter_markdown', l10n.markdownRendering),
            ('foundation_models_framework', l10n.appleOnDeviceAi),
            ('http', l10n.httpClients),
            ('encrypt / pointycastle', l10n.cryptography),
            ('health', l10n.appleHealthHealthConnect),
            ('permission_handler', l10n.runtimePermissions),
            ('location', l10n.gpsLocation),
            ('share_plus', l10n.shareExport),
            ('url_launcher', l10n.openUrls),
            ('intl', l10n.internationalisation),
            ('uuid / latlong2', l10n.utilities),
            ('font_awesome_flutter', l10n.icons),
          ])
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(library.$1, style: const TextStyle(fontSize: 12)),
              subtitle: Text(
                library.$2,
                style: const TextStyle(fontSize: 10, color: muted),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.license,
                  style: const TextStyle(fontSize: 9, color: Colors.lightBlue),
                ),
              ),
              onTap: () => _showLicenses(context),
            ),
          ListTile(
            title: Text(l10n.licenses),
            onTap: () => _showLicenses(context),
          ),
        ],
      ),
    );
  }

  void _showLicenses(BuildContext context) => showLicensePage(
    context: context,
    applicationName: context.l10n.fjelia,
    applicationLegalese:
        '© 2026 Alex Ebeling-Hoppe\nFree software under the '
        'GNU General Public License, version 3 or later.',
  );
}
