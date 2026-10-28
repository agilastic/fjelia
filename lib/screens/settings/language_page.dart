import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/settings_widgets.dart';

/// Lets the user pick the app language or follow the phone.
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(languageProvider).valueOrNull;
    Widget option(String? code, String title, [String? subtitle]) => ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: saved == code ? const Icon(Icons.check, size: 20) : null,
      onTap: () => runUiAction(
        context,
        () => ref.read(languageProvider.notifier).set(code),
      ),
    );
    return SettingsPage(
      title: l10n.language,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsGroup(
            children: [
              option(
                null,
                l10n.languageSystem,
                languageNames[phoneLanguageCode()],
              ),
              for (final code in supportedLanguageCodes)
                option(code, languageNames[code]!),
            ],
          ),
        ],
      ),
    );
  }
}
