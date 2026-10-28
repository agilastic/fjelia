import '../l10n/l10n_ext.dart';

/// The language the coach answers in, named for the model.
String coachLanguageName([String? code]) =>
    switch (code ?? activeLocale.languageCode) {
      'de' => 'German',
      'fr' => 'French',
      'it' => 'Italian',
      'es' => 'Spanish',
      'ca' => 'Catalan',
      'nb' => 'Norwegian Bokmål',
      'sk' => 'Slovak',
      'fi' => 'Finnish',
      'da' => 'Danish',
      _ => 'British English',
    };

/// The locale tag handed to Apple Intelligence, e.g. `de_DE`.
String coachLocaleTag() => switch (activeLocale.languageCode) {
  'en' => 'en_GB',
  'de' => 'de_DE',
  'fr' => 'fr_FR',
  'it' => 'it_IT',
  'es' => 'es_ES',
  'ca' => 'ca_ES',
  'nb' => 'nb_NO',
  'sk' => 'sk_SK',
  'fi' => 'fi_FI',
  'da' => 'da_DK',
  final other => other,
};

/// Added to every coach prompt. The app language is the person's choice, so
/// it wins over the language of the data and of these instructions.
String coachLanguageDirective({bool chat = false}) {
  final language = coachLanguageName();
  return '\n\nLANGUAGE: Write your whole reply in $language, the language '
      'the person chose in the app, even though the data and these '
      'instructions are in English. '
      '${chat ? 'Only if the person writes in another language, answer in that language. ' : ''}'
      'Keep numbers, units and metric abbreviations (HRV, TRIMP, CTL, ATL, TSB) as they are.';
}

/// Today, from the phone clock. A record dated earlier is never "today".
String coachTodayLine([DateTime? now]) {
  final t = now ?? DateTime.now();
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final date =
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  return 'Today is ${days[t.weekday - 1]} $date (the phone clock). ';
}
