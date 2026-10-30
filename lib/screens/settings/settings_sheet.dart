import 'weather_location_tab.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/settings_widgets.dart';
import 'profile_tab.dart';
import 'training_tab.dart';
import 'display_tab.dart';
import 'connections_tab.dart';
import 'ai_settings_tab.dart';
import 'system_tab.dart';
import 'language_page.dart';
import 'credits_page.dart';
import '../onboarding/welcome_screen.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});
  static Future<void> show(BuildContext context) =>
      showAppSheet(context, const SettingsSheet());
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(languageProvider).valueOrNull;
    return SettingsPage(
      title: l10n.settings,
      showBack: false,
      largeTitle: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SettingsGroup(
            dividerIndent: 58,
            children: [
              _row(
                context,
                l10n.profile,
                Icons.person_outline,
                Colors.blue,
                const ProfileTab(),
              ),
              _row(
                context,
                l10n.training,
                Icons.fitness_center,
                Colors.orange,
                const TrainingTab(),
              ),
              _row(
                context,
                l10n.weatherLocation,
                Icons.cloud_outlined,
                Colors.lightBlue,
                const WeatherLocationTab(),
              ),
            ],
          ),
          SettingsGroup(
            dividerIndent: 58,
            children: [
              _row(context, l10n.display, Icons.tune, mint, const DisplayTab()),
              _row(
                context,
                l10n.connections,
                Icons.cable,
                Colors.green,
                const ConnectionsTab(),
              ),
              _row(
                context,
                l10n.aiAndMore,
                Icons.auto_awesome,
                Colors.purpleAccent,
                const AiSettingsTab(),
              ),
              _row(
                context,
                l10n.system,
                Icons.settings_outlined,
                muted,
                const SystemTab(),
              ),
            ],
          ),
          SettingsGroup(
            dividerIndent: 58,
            children: [
              ListTile(
                leading: const SettingsIcon(Icons.language, Colors.indigo),
                title: Text(l10n.language),
                subtitle: Text(
                  saved == null ? l10n.languageSystem : languageNames[saved]!,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => showAppSheet(context, const LanguagePage()),
              ),
              ListTile(
                leading: const SettingsIcon(Icons.replay, Colors.teal),
                title: Text(l10n.runSetupAgain),
                subtitle: Text(l10n.runSetupAgainSubtitle),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  final root = Navigator.of(context, rootNavigator: true);
                  Navigator.of(context).pop();
                  root.push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WelcomeScreen(),
                    ),
                  );
                },
              ),
              _row(
                context,
                l10n.creditsAndLicenses,
                Icons.favorite_border,
                Colors.pinkAccent,
                const CreditsPage(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) => ListTile(
    leading: SettingsIcon(icon, color),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: () => showAppSheet(context, page),
  );
}
