import 'package:fjelia_core/services/coach_language.dart';

import '../l10n/l10n_ext.dart';

export 'package:fjelia_core/services/coach_language.dart' show coachTodayLine;

/// The language the coach answers in, named for the model.
String coachLanguageName([String? code]) =>
    coachLanguageNameFor(code ?? activeLocale.languageCode);

/// The locale tag handed to Apple Intelligence, e.g. `de_DE`.
String coachLocaleTag() => coachLocaleTagFor(activeLocale.languageCode);

/// Added to every coach prompt: the reply in the app language.
String coachLanguageDirective({bool chat = false}) =>
    coachLanguageDirectiveFor(activeLocale.languageCode, chat: chat);
