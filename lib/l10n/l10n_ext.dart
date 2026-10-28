import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

Locale _activeLocale = const Locale('en');

/// Called whenever the app language changes, so code without a
/// [BuildContext] (helpers, services) can still use [tr].
void setActiveLocale(Locale locale) {
  _activeLocale = locale;
  // Dates and numbers follow the app language; English is British.
  Intl.defaultLocale = locale.languageCode == 'en'
      ? 'en_GB'
      : locale.languageCode;
}

/// The language the app currently shows.
Locale get activeLocale => _activeLocale;

/// Strings in the current app language, for code that has no [BuildContext].
/// Widgets should prefer `context.l10n`, which also rebuilds on a change.
AppLocalizations get tr => lookupAppLocalizations(_activeLocale);
