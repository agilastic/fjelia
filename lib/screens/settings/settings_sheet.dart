import 'weather_location_tab.dart';

import 'package:flutter/material.dart';

import '../../widgets/app_widgets.dart';
import '../../widgets/settings_widgets.dart';
import 'profile_tab.dart';
import 'training_tab.dart';
import 'display_tab.dart';
import 'connections_tab.dart';
import 'ai_settings_tab.dart';
import 'system_tab.dart';
import '../onboarding/welcome_screen.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});
  static Future<void> show(BuildContext context) =>
      showAppSheet(context, const SettingsSheet());
  @override
  Widget build(BuildContext context) => SettingsPage(
    title: 'Settings',
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
              'Profile',
              Icons.person_outline,
              Colors.blue,
              const ProfileTab(),
            ),
            _row(
              context,
              'Training',
              Icons.fitness_center,
              Colors.orange,
              const TrainingTab(),
            ),
            _row(
              context,
              'Weather & Location',
              Icons.cloud_outlined,
              Colors.lightBlue,
              const WeatherLocationTab(),
            ),
          ],
        ),
        SettingsGroup(
          dividerIndent: 58,
          children: [
            _row(context, 'Display', Icons.tune, mint, const DisplayTab()),
            _row(
              context,
              'Connections',
              Icons.cable,
              Colors.green,
              const ConnectionsTab(),
            ),
            _row(
              context,
              'AI & More',
              Icons.auto_awesome,
              Colors.purpleAccent,
              const AiSettingsTab(),
            ),
            _row(
              context,
              'System',
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
              leading: const SettingsIcon(Icons.replay, Colors.teal),
              title: const Text('Run setup again'),
              subtitle: const Text('Accounts, race goal and training plan'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                final root = Navigator.of(context, rootNavigator: true);
                Navigator.of(context).pop();
                root.push(
                  MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
                );
              },
            ),
          ],
        ),
      ],
    ),
  );

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
