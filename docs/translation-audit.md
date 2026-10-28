Translation audit of the working tree, 28 October 2026.

The translation files are structurally complete, but the app is still only partly localised. Populating every ARB key does not cover text embedded directly in widgets, services or native permission dialogs.

Checks completed:

- All ten app locales (`en`, `de`, `fr`, `it`, `es`, `ca`, `nb`, `sk`, `fi`, `da`) have the same 1,055 message keys after the corrections. The original files contained 1,054 keys each; the additional key labels a rest day.
- ARB JSON parses without duplicate keys, empty messages, mismatched locale identifiers, missing placeholder names or replacement characters indicating damaged text.
- Numeric values in the original translations match English. The differences are intentionally localised example telephone country codes.
- Flutter successfully regenerated all localisations, including the new ICU plural messages.
- The website has 282 messages per language after applying its copy overrides, across English, German, Spanish, French and Italian. All 248 translation attribute references across the three HTML pages resolve. Translated HTML tags and link attributes match English.
- The 46 selected localisation, blood-pressure, navigation and strength-progression tests pass. Targeted Dart analysis reports no issues. `git diff --check` passes.

Corrections made during this audit:

- Generated-workout counts, training-day counts and blood-pressure reading counts now use locale-aware singular/plural forms, including Slovak forms for two to four items. These counts now have integer parameters.
- The weekly schedule now translates Monday, rest and strength labels. Its hint lists all three available day states.
- Apple Health onboarding now accurately explains that the app can read data and, with permission, write synchronised data. The former claim that the app never writes data contradicted its permission requests and write-back code.
- Corrected literal translations of strength “straight sets” in Catalan, Spanish and Norwegian, and the corresponding load-suggestion explanations.
- Clarified the HRV settling period in German, Danish and Norwegian. Norwegian measurement instructions now work for lying-down as well as seated measurements.
- Corrected Slovak “Undo”, German wording for sets with load, Norwegian nutrition wording and an ambiguous English nutrition validation message.
- Expanded the existing localisation tests to reject extra keys and empty strings, recognise ICU parameters, and exercise actual plural output for zero, one, two and five readings in every locale.

Visible gaps remain, including these confirmed examples:

| Area | Examples still embedded in English | Source |
| --- | --- | --- |
| Home | “Settings”, “Sync Today”, status and summary text | [Home screen](../lib/screens/home/home_screen.dart) |
| Sleep | “NO DATA”, “POOR SLEEP”, “FAIR SLEEP”, “GOOD SLEEP” | [Sleep screen](../lib/screens/sleep/sleep_screen.dart) |
| AI coach | “AI settings”, “Retry”, “Dismiss” and other controls | [Coach screen](../lib/screens/ai_coach/ai_coach_screen.dart) |
| Apple Health setup | Connection subtitle, metric names and descriptions | [Health connection screen](../lib/screens/onboarding/connect_health_screen.dart) |
| iOS permission requests | Bluetooth, Health and location explanations are English; there are no translated `InfoPlist.strings` files | [iOS Info.plist](../ios/Runner/Info.plist) |

The language review was targeted at ambiguous labels, technical terminology, representative descriptions and count grammar. It was not an exhaustive native-speaker review of every sentence. The automated website checks cover the merged dictionaries and HTML references; they do not verify browser layouts, translated screenshots, videos or generated AI responses.
