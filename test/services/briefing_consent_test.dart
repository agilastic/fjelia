import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fjelia/services/ai_coach_settings.dart';
import 'package:fjelia/services/briefing_consent.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const free = AiCoachSettings(
    provider: AiProvider.freeAi,
    model: 'free',
    hasApiKey: true,
    enabled: true,
  );

  test('asked once, then given for the same provider and model', () async {
    expect(await BriefingConsent.given(free), isFalse);
    await BriefingConsent.remember(free);
    expect(await BriefingConsent.given(free), isTrue);
  });

  test('a change in the AI settings asks again', () async {
    await BriefingConsent.remember(free);
    const otherProvider = AiCoachSettings(
      provider: AiProvider.anthropic,
      model: 'claude-sonnet-5-5',
      hasApiKey: true,
      enabled: true,
    );
    expect(await BriefingConsent.given(otherProvider), isFalse);
    const otherModel = AiCoachSettings(
      provider: AiProvider.freeAi,
      model: 'free-large',
      hasApiKey: true,
      enabled: true,
    );
    expect(await BriefingConsent.given(otherModel), isFalse);
  });
}
