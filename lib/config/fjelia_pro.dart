/// FjeliaPro: the App Store subscriptions and the Fjelia service that checks
/// them (`fjelia-service/push-server/pro.py`).
const proMonthlyProductId = 'fjelia.pro.monthly';
const proYearlyProductId = 'fjelia.pro.yearly';
const proProductIds = {proMonthlyProductId, proYearlyProductId};

/// Exchanges a purchase's transaction id for the subscription's own AI key.
final proActivateUri = Uri.https('push.fjelia.com', '/v1/pro/activate');

/// The gateway model a Pro key may use (Fjelia AI with the Pro model).
const proAiModel = 'ProAI';

/// The large model for the Pro analyses (plan check, weekly review, race
/// plan, season); the gateway falls back to [proAiModel] when it is missing.
const proAiDeepModel = 'ProAI-deep';

/// Links the subscription sheet must show (App Store Review Guideline
/// 3.1.2): Apple's standard terms and Fjelia's privacy policy.
final proTermsUri = Uri.https(
  'www.apple.com',
  '/legal/internet-services/itunes/dev/stdeula/',
);
final proPrivacyUri = Uri.https('www.fjelia.com', '/privacy.html');

/// Where the athlete manages or cancels the subscription.
final proManageUri = Uri.https('apps.apple.com', '/account/subscriptions');
