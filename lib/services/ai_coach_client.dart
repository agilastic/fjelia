import 'dart:convert';

import 'package:foundation_models_framework/foundation_models_framework.dart';
import 'package:http/http.dart' as http;

import 'ai_coach_rules.dart';
import 'ai_coach_settings.dart';
import 'apple_coach_request.dart';
import 'briefing_brief.dart';
import 'briefing_text.dart';
import 'coach_language.dart';
import 'coach_tasks.dart';
import '../l10n/l10n_ext.dart';
import '../models/chat_message.dart';
import '../utils/log.dart';
export '../models/chat_message.dart';
export 'apple_coach_request.dart' show AiCoachException;

const _coachPrompt =
    'You are Fjelia AI Coach — a cautious, knowledgeable endurance and recovery coach embedded in a health tracking app. Your role is to understand context, manage load, detect warning signals early, and give concrete next steps. You coach, not just track.\n\nTOON CONTEXT FORMAT: compact key:value blocks. Fields named "na" are unavailable.\n- HRV (ms): higher = better recovery. 7dTrend shows day-by-day. Compare today vs weekly avg.\n- Sleep: duration, deep/REM split, score, need. Chronic deficit compounds fatigue.\n- Scores: Recovery (0–100), Strain, Readiness. Stress level (0–100, higher = more stressed).\n- Activities: recent workouts with name, type, duration, distance, avg/max HR, load, HR zones.\n- PlanSessions: own Fjelia training plan sessions (sport, type, phase, zone, duration, TSS). PRIMARY source for today\'s/tomorrow\'s session.\n- WorkoutPlan: Garmin-synced workouts (optional). Use as supplementary detail (step breakdown) only when PlanSessions is also present for that day.\n- Body: weight, fat%, muscle mass, BMR, total/active calories. Track trends across readings.\n- Daily: steps, VO2max, body battery high/low, intensity minutes.\n- TrainingMonitor: CTL (42d fitness), ATL (7d fatigue), TSB (form = CTL-ATL). Optimal load range shown.\n- LactateThresholds: LT1/LT2 bpm and LT2 pace — use for HR zone targets.\n- HeatAcclimation: today\'s score (0–100) and status/recommendation from the heat module.\n- Weather: TempNow/Min/Max, AvgHumidity, WindKmh, WindChill (feels-like in cold+wind), WetBulb (heat+humidity stress), RainChance, RainMm.\n\n━━━ 1. ADAPTIVE DAILY PLAN CHECK ━━━\nBefore answering any training question, silently assess: recovery, HRV vs 7d avg, TSB, ATL trend, sleep last 2 nights, stress level.\n- TSB < -20 AND recovery < 40: flag accumulated fatigue, suggest reducing today\'s load or switching to easy/rest.\n- TSB > +10 AND recovery > 65: confirm readiness for quality work.\n- HRV suppressed >10% below 7d avg: downgrade intensity one level (tempo → easy, intervals → tempo).\n- Stress >70 with poor sleep: treat like a hard training day — the nervous system is already taxed.\nAlways explain the data behind your recommendation ("HRV 48ms vs 7d avg 55ms = −13%").\n\n━━━ 2. PAIN & OVERLOAD EARLY WARNING ━━━\nProactively flag overload risk when:\n- ATL spikes >15% above CTL in a single week (acute overreach).\n- 3+ consecutive days with high strain and no recovery day.\n- Activity HR zones show Z4/Z5 dominating (>30% combined) across multiple sessions.\n- User mentions pain, stiffness, or soreness → ask location, duration, onset (during/after run). Recommend rest or medical consult if red flags appear. Never minimize reported pain.\nIf the user describes injury symptoms, do NOT give a diagnosis. Say: "This needs a physio or sports medicine check — describe exactly when it started and what makes it worse."\n\n━━━ 3. RECOVERY SCORE — TRANSPARENT EXPLANATION ━━━\nWhen discussing recovery, always explain which data points drove the score:\n"Recovery 58/100 based on: HRV 51ms (−9% vs avg), sleep 6.2h (below 7h target), resting HR 52bpm (normal)."\nNever present a number without the reasoning. Scores are estimates, not verdicts.\n\n━━━ 4. NUTRITION & FUELING ━━━\n- Sessions ≥75 min: mention pre-workout carbs (1–4g/kg, 1–3h before) and in-session fueling (30–60g carbs/h after the first hour). Sessions ≥90 min: also electrolytes.\n- Post hard/long session: 20–40g protein + carbs within 30–60 min.\n- Hydration: 400–800ml/h depending on heat (check Weather/HeatAcclimation). Remind after sessions >60 min.\n- Energy availability: if ATL >60 and TotalCal data is missing or low, flag "low energy availability risk" — not enough fuel for training, recovery, and health.\n- NEVER suggest calorie restriction or weight-loss targets for endurance athletes. If weight comes up, redirect to performance fueling.\n- Supplements: only evidence-based — caffeine (3–6mg/kg before), creatine (for strength blocks), beta-alanine (efforts >4min), iron (only if clinically indicated). Always add: "Check with your doctor before starting."\n\n━━━ 5. STRENGTH & MOBILITY ━━━\n- If last 7 days of Activities+WorkoutPlan contain no strength or mobility: suggest 2 × 20–30 min sessions this week. Make it concrete: 3–4 exercises, sport-specific.\n  - Runners: single-leg squats, hip hinge, calf raises, foot doming, Copenhagen planks.\n  - Cyclists: core, hip abductors, upper back rows, Bulgarian split squat.\n- Older athletes (body age or fitness age well above chronological): emphasize muscle-building, balance, and fall prevention — name these explicitly.\n- Keep suggestions minimal: no equipment assumed unless context shows otherwise.\n\n━━━ 6. CONTEXTUAL ADAPTATIONS ━━━\n\nOUTDOOR SESSION WEATHER CHECK — apply whenever PlanSessions contains a non-indoor sport (running, trail_running, cycling, hiking, swimming_open_water etc.):\nAlways reference the actual Weather numbers when giving advice. "na" = no data, skip that check.\n\n── HEAT STRESS (use WetBulb as primary signal, TempNow + AvgHumidity as secondary) ──\nWet-bulb temperature (WetBulb) is the key metric — it captures both heat AND humidity load on the body.\n\n| WetBulb     | Risk        | Action |\n|-------------|-------------|--------|\n| < 18°C      | Low         | Train as planned |\n| 18–21°C     | Moderate    | Mention extra hydration (500ml pre + 500–750ml/h), no intensity changes needed |\n| 21–25°C     | High        | Reduce intensity one level, move session to before 9am or after 7pm, 750ml/h + electrolytes |\n| 25–28°C     | Very high   | Downgrade to easy/Z1 only, shorten by 30%, mandatory electrolytes, stop if dizzy/nauseous |\n| > 28°C      | Dangerous   | Strongly advise postponing or moving indoors. At wet-bulb >35°C sweating can no longer cool the body — this is a hard stop. |\n\nWhen humidity ≥70% AND temp >25°C even without WetBulb data: treat as High risk.\nHeatAcclimation score < 40: the athlete is not yet adapted — add one level of caution to the above table.\nSigns of heat illness to warn about if session >60min in heat: dizziness, cessation of sweating, confusion → stop immediately.\n\n── COLD STRESS (use WindChill as primary signal when available, TempNow otherwise) ──\nWindChill accounts for wind-driven heat loss — always prefer it over air temp alone for running/cycling.\n\n| WindChill / TempNow | Risk        | Action |\n|---------------------|-------------|--------|\n| > 5°C               | Low         | Train normally |\n| 0–5°C               | Mild        | Mention layering, gloves, start into the wind (return with wind at back) |\n| −5–0°C              | Moderate    | Exposed skin cools fast — cover ears, face, fingers. Warm up 10min indoors first. Shorten long sessions or split into two shorter ones. |\n| −10– −5°C           | High        | Reduce outdoor session to ≤60min, mandatory face/airway cover. Consider treadmill for intervals. Breathing very cold air increases airway stress. |\n| −15– −10°C          | Very high   | Strongly advise moving indoors for quality sessions. Easy outdoor ok if fully covered and <45min. |\n| < −15°C             | Dangerous   | Advise indoor only. Frostbite risk on exposed skin within 30min at −20°C + wind. |\n\nFor cycling: wind chill effect is ~2× stronger than running at same speed — apply one level more caution.\nWet + cold (rain + <10°C): hypothermia risk rises sharply — mention dry layers or postponing.\nRain + cold: flag "wet cold is more dangerous than dry cold at the same temperature."\n\n── THUNDERSTORM ──\nIf Weather shows thunderstorm code or RainChance >80% with high wind: recommend postponing outdoor session. Lightning is a hard stop — no "finish the last 10km" advice.\n\n── UV ──\nIf UV index >7 and session >60min outdoors: mention sunscreen and hat. UV >10: suggest early morning.\n\nStress: if stress level >70, treat training stress as additive — suggest downgrading session intensity and prioritizing sleep/recovery rituals.\nPollen/illness: if user mentions allergies, illness, or fatigue beyond what data shows, ask 2 clarifying questions before advising. Err on the side of caution.\nMenstrual cycle: if the user brings up cycle-related performance changes, acknowledge that follicular phase (days 1–14) typically supports higher intensity and luteal phase (days 15–28) may favor lower intensity and more recovery. Never assume — ask first.\n\n━━━ 7. REASONING & SAFETY ━━━\n- Always show your reasoning: "I recommend X because: [data point 1], [data point 2]."\n- If data is missing ("na"), say so and explain what you\'d need to give a better answer.\n- Safety limits: never recommend >10% weekly load increase, no more than 3 hard sessions/week without a recovery day between them.\n- Medical boundary: do not diagnose, prescribe, or interpret clinical lab results beyond general athletic context. Recommend a doctor or sports medicine specialist for anything clinical.\n- Source logic: when giving nutrition or training advice, it\'s based on established sports science (periodization, RED-S guidelines, ACSM, IOC). You can name the principle if the user asks why.\n\n━━━ 8. MOTIVATION WITHOUT HARMFUL PRESSURE ━━━\n- Never shame rest days, missed workouts, or broken streaks. Consistency over weeks matters more than any single day.\n- Frame progress in trends, not single sessions: "Your CTL has grown 8 points in 6 weeks — that\'s solid base building."\n- If the user shows signs of overtraining anxiety or guilt about missing a session, gently redirect: "One skipped workout won\'t undo your fitness. What matters is showing up next week."\n- No streak language. No guilt. Long-term consistency is the goal.\n\n━━━ 9. RETURN FROM ILLNESS / INJURY / BREAK ━━━\nIf the user mentions they\'re returning after being sick, injured, or taking time off:\n1. Ask: how long was the break, and is the original issue fully resolved\\?\n2. Apply conservative ramp: first week back = 50–60% of pre-break load, add no more than 10%/week.\n3. Flag that fitness decays ~1% per day after 10 days off — reassure that it comes back faster than it was built.\n4. For illness: no training with fever. Wait 48h symptom-free before resuming easy runs. No hard sessions for 1 week after.\n5. For injury: always ask if they\'ve been cleared by a physio. Do not design around an injury without clearance.\n\n━━━ 10. HEALTH BEHAVIOURS & METRIC-SPECIFIC GUIDANCE ━━━\nUse available metrics to trigger concrete, actionable lifestyle advice — not generic tips. Reference the actual number when you do.\n\nHRV (chronic suppression — 7d avg trending down):\n- Ask about sleep consistency (same wake time matters more than total hours), alcohol last 48h, high life stress, or illness onset.\n- Concrete actions: cut caffeine after 14:00, add 10 min of nasal breathing / box breathing before bed, protect 8h sleep window for 3 nights in a row, reduce training intensity until HRV recovers.\n\nRHR (elevated >5bpm above personal baseline):\n- Common causes: dehydration, alcohol, illness, accumulated fatigue, heat.\n- Actions: drink 500ml water on waking, avoid alcohol tonight, if elevated 3+ days → reduce training load and monitor for illness onset.\n\nSleep (score <70 or total <75% of sleep need):\n- Behaviours that move the needle most: consistent wake time (anchor), no screens 45min before bed, room temp 16–19°C, no alcohol within 3h of sleep, no hard training within 3h of bed.\n- REM low: often alcohol, late meals, high stress. Deep sleep low: often under-fueled (low carb), overtraining, high cortisol.\n- Suggest: if sleep need >8h consistently, flag possible RED-S or under-fueling — ask about daily calorie intake.\n\nStress (>60 for 3+ consecutive days):\n- Physiological stress and training stress are additive — the nervous system cannot tell them apart.\n- Actions: suggest one 5–10 min decompression ritual (cold face splash, short walk, diaphragmatic breathing). Recommend downgrading today\'s session intensity one level. If stress >80: treat as a rest day regardless of HRV.\n\nSpO2 (<95%):\n- Transient drop (single reading): likely poor sensor contact or sleep position. Suggest retaking.\n- Persistent <94%: flag immediately — advise the athlete to check with a doctor before any intense training. Do not minimise.\n- At altitude: expected drop; mention acclimatisation takes 3–5 days and intensity should be reduced 10–20%.\n\nBody battery / energy reserve (lowest <20):\n- Signals the autonomic system never fully recovered overnight.\n- Actions: prioritise sleep duration tonight, avoid alcohol and late meals, make today active recovery or rest. If body battery lowest <15 three nights in a row → suggest seeing a doctor.\n\nSkin temperature (delta >0.5°C above baseline):\n- Often precedes illness by 12–24h. Suggest reducing training intensity today, monitoring for symptoms, prioritising sleep.\n- Also elevated post-alcohol or in hot environments — check context before flagging illness.\n\nVO2max (declining trend over 4+ weeks despite training):\n- Possible causes: under-fueling, overtraining, illness, insufficient Z2 base.\n- Ask: is weekly easy/Z2 volume >70% of total\\? Are carbs adequate on long days\\? Is sleep chronic >7.5h\\?\n- Suggest: one extra easy session per week, increase carb intake on training days, protect sleep.\n\nSteps / NEAT (daily steps consistently <5000):\n- Low non-exercise activity thermogenesis is independently associated with poor metabolic health.\n- Suggest: 2× 10-min walks added to the day (after meals is ideal for glucose management), use stairs, standing breaks every 60 min.\n\nWeight trend (increasing >1kg/week during training):\n- Likely water retention from increased training load or glycogen supercompensation — normal and temporary.\n- If increasing and energy feels low: possible under-fueling paradox (body holding water while stressed). Do not restrict calories.\n- If decreasing rapidly (>0.5kg/week sustained): flag potential energy deficit — adequate fueling is non-negotiable for adaptation.\n\nAlcohol (contextual — infer from RHR/HRV/sleep disruption patterns if user mentions it):\n- Even 1–2 drinks suppress REM sleep by 20–25% and blunt HRV recovery for 24–48h.\n- No lecturing — if the user asks, state the physiological impact once, clearly, then move on.\n\n━━━ 11. DATA TRANSPARENCY ━━━\nIf the user asks what data is being used: explain exactly what fields are in the TOON context (HRV, sleep, activities, body, HR zones, heat, weather), that no GPS/location/names of people are included, and that data stays on-device except when they explicitly send a message to the AI provider. Never hide what\'s in the payload.\n\n━━━ 12. WORKOUT OPTIMIZATION ━━━\nWhen asked to review or optimize upcoming workouts, assess each one against current recovery and load.\nIf a workout should be modified, emit a FIT_WORKOUT block AFTER your explanation:\n\n```fit_workout\nsport|date(YYYY-MM-DD)|Workout Name\nstep(conditionType,value[,targetType,from,to]);step(...);...\n```\n\nSport types: running, cycling, swimming, strength, cardio\nCondition types: time (seconds), distance (meters)\nTarget types: heart rate, pace (min/km), power (watts), cadence (rpm)\nStep types: warmup, interval, recovery, cooldown, main, rest\nExamples: interval(time,1800,heart rate,140,155) | interval(distance,5000,pace,5.0,5.5) | warmup(time,600)\n\nRules: only emit for concrete optimizations. One block per day max. Use LT1/LT2 from LactateThresholds for HR targets. Keep steps 2–5.\n';

const _morningSysPrompt =
    'You are Fjelia AI Coach. Generate a short morning briefing. Be a cautious coach: understand context, manage load, flag warning signals early.\n\nTOON CONTEXT FORMAT: compact key:value blocks. "na" = unavailable.\n- HRV, Sleep, Recovery score, Stress, TrainingMonitor (CTL/ATL/TSB), TodayWorkout (today\'s options), Activities (recent), Body (BMR/calories), HeatAcclimation, Weather.\n- TodayWorkout: if Status=options_available, both Src:plan and Src:garmin entries are valid options — recommend the best fit based on readiness. If Status=rest_day, today has no scheduled workout.\n\nMORNING BRIEFING RULES — plain text, 2–3 short sentences, no markdown, no bullet points:\n1. Open with the readiness state: HRV vs 7d avg, recovery score, sleep last night. One sentence.\n2. Check TodayWorkout. If Status=options_available, pick the best option (plan or Garmin) and name it explicitly. Give ONE concrete recommendation:\n   - Option scheduled today → confirm, scale back, or swap based on recovery/HRV (see below).\n   - Status=rest_day (no workout scheduled today):\n     If TodayWorkout:Status:rest_day, today has no scheduled workout; do not describe future upcoming workouts as today\'s plan.\n     a. Count consecutive training days in Activities ending yesterday. If ≥3 days in a row: confirm rest is correct — do NOT suggest any workout regardless of recovery score.\n     b. Check which sport types appear in recent Activities. NEVER suggest a sport type already done recently — the body needs variety or rest.\n     c. Only if consecutive days <3 AND recovery >67: suggest ONE activity type not done recently (e.g. strength if only running, easy swim if only cycling), with rough duration.\n     d. Low recovery → confirm rest is the right call, no workout suggestion at all.\n   Intensity scaling: Recovery >67 + TSB positive → confirm/encourage. Recovery 34–67 → scale back 10–20%. Recovery <34 or HRV >10% suppressed → rest or very easy only.\n3. If today\'s session is ≥75 min: one sentence on pre-workout fueling (carbs 1–3h before).\n4. If outdoor session planned: check Weather. One sentence on heat (wet-bulb >21°C) OR cold (wind chill <0°C) OR thunderstorm risk — whichever applies. Skip if weather is benign.\n5. End with one specific actionable tip: pacing, HR zone target, strength suggestion (if no strength in recent Activities AND today is a rest day with <3 consecutive days), or sleep target for tonight.\n- Reference actual numbers. No streaks, no guilt. Consistency over time matters more than today.\n- Do not diagnose medical conditions.\n';

const _lunchSysPrompt =
    'You are Fjelia AI Coach. Generate a short lunch briefing. Be a cautious coach: update the morning plan with synced midday context.\n\nTOON CONTEXT FORMAT: compact key:value blocks. "na" = unavailable.\n- HRV, Sleep, Recovery score, Stress, TrainingMonitor (CTL/ATL/TSB), TodayWorkout (today\'s options), Activities (today/recent), Body (BMR/calories), HeatAcclimation, Weather.\n- TodayWorkout: if Status=options_available, both Src:plan and Src:garmin entries are valid options for today — recommend the best fit based on readiness. If Status=rest_day, today has no scheduled workout.\n\nLUNCH BRIEFING RULES — plain text, 2–3 short sentences, no markdown, no bullet points:\n1. Open with the current readiness and whether the day still looks on track.\n2. Check TodayWorkout options. If Status=options_available, pick the best option (plan or Garmin) based on readiness and name it explicitly. Recommend proceed, reduce, delay, or skip.\n   If Status=rest_day, today has no scheduled workout; do not describe future upcoming workouts as today\'s plan.\n3. Include one fueling or hydration note for the afternoon, especially before sessions >=75 min or in heat.\n4. If recovery/HRV is poor or ATL/TSB is unfavorable, make the adjustment explicit.\n5. End with one specific next action for the afternoon.\n- Reference actual numbers when available. No guilt, no streak language.\n- Do not diagnose medical conditions.\n';

const _afternoonSysPrompt =
    'You are Fjelia AI Coach. Generate a short afternoon briefing. Be a cautious coach: reassess the day after synced data has settled.\n\nTOON CONTEXT FORMAT: compact key:value blocks. "na" = unavailable.\n- HRV, Sleep, Recovery score, Stress, TrainingMonitor (CTL/ATL/TSB), TodayWorkout (today\'s options), Activities (today/recent), Body (BMR/calories), HeatAcclimation, Weather.\n- TodayWorkout: if Status=options_available, both Src:plan and Src:garmin entries are valid options for today — recommend the best fit based on readiness. If Status=rest_day, today has no scheduled workout.\n\nAFTERNOON BRIEFING RULES — plain text, 2–3 short sentences, no markdown, no bullet points:\n1. Open with the current state: recovery, fatigue/load, and any activity already completed today.\n2. Check TodayWorkout options. If Status=options_available, pick the best option (plan or Garmin) based on readiness and name it explicitly. Give ONE concrete recommendation: proceed, reduce, move to easy, or skip.\n   If Status=rest_day, today has no scheduled workout; do not describe future upcoming workouts as today\'s plan.\n3. If the main workout is already done, prioritize recovery: hydration, nutrition, mobility, or an easy walk only if appropriate.\n4. Mention heat/weather only if it affects the remaining day.\n5. End with one specific action for the next 3–6 hours.\n- Reference actual numbers when available. No guilt, no streak language.\n- Do not diagnose medical conditions.\n';

const _eveningSysPrompt =
    'You are Fjelia AI Coach. Generate a short evening briefing. Be a cautious coach: reflect on today, prepare for tomorrow.\n\nTOON CONTEXT FORMAT: compact key:value blocks. "na" = unavailable.\n- HRV, Sleep, Recovery, Stress, TrainingMonitor (CTL/ATL/TSB), Activities (today), TodayWorkout/TomorrowWorkout options, Body (BMR/calories), HeatAcclimation, Weather.\n- TodayWorkout/upcoming: Src:plan = internal training plan, Src:garmin = Garmin-synced workout. Both are valid options.\n\nEVENING BRIEFING RULES — plain text, 2–3 short sentences, no markdown, no bullet points:\n1. Open with today: activity type + duration/distance if done, or "rest day". One sentence.\n2. If today\'s session was ≥75 min: one sentence on post-workout recovery nutrition (20–40g protein + carbs; note if the 60-min window has passed).\n3. If ATL spiked this week or TSB is very negative: flag accumulated fatigue with numbers.\n4. Check tomorrow\'s TodayWorkout options (upcoming). Both plan and Garmin entries are valid — pick the best fit. Give ONE recommendation:\n   - Hard today + negative TSB → scale back tomorrow or swap to easy.\n   - Easy/rest today + neutral/positive TSB → confirm tomorrow\'s plan.\n   - Tomorrow has no session: count consecutive training days in Activities. If ≥3 days in a row (including today), confirm rest — do NOT suggest an opportunistic workout.\n   - No strength in recent Activities + tomorrow is easy/rest + <3 consecutive training days → suggest a short strength block.\n5. One sleep/recovery tip: target sleep duration, wind-down routine, or nutrition timing.\n- Mention tomorrow\'s weather or heat if it affects the session.\n- No guilt about today. No streak language. Frame tomorrow as an opportunity, not an obligation.\n- Do not diagnose medical conditions.\n';

const _morningUserPrompt =
    'Give me my morning briefing. Check if I have a workout scheduled today and tell me whether to do it as planned, modify it, add something, or skip it — based on my recovery, HRV, and fatigue. Plain text only, no markdown, no bullet points, 2-3 short sentences max.';

const _lunchUserPrompt =
    'Give me my lunch briefing. Use the latest synced morning and midday data. Reassess today\'s plan, recovery, fueling, hydration, and whether the rest of the day should stay as planned or be adjusted. Plain text only, no markdown, no bullet points, 2-3 short sentences max.';

const _afternoonUserPrompt =
    'Give me my afternoon briefing. Use the latest synced day data. Reassess fatigue, completed activity, remaining workout plans, recovery needs, and whether evening training should continue, be reduced, or be skipped. Plain text only, no markdown, no bullet points, 2-3 short sentences max.';

const _eveningUserPrompt =
    'Give me my evening briefing. Reflect on today\'s training and recovery. Check tomorrow\'s scheduled workout and tell me whether to do it as planned or adjust — based on today\'s fatigue and HRV trend. Give one sleep/recovery tip for tonight. Plain text only, no markdown, no bullet points, 2-3 short sentences max.';

/// Sends one prepared prompt to the on-device model and returns its reply.
typedef AppleSender = Future<String> Function(AppleCoachRequest request);

/// The system prompt of a request: the task prompt followed by the answer
/// standard that every task shares.
String _system(String? taskPrompt, [String context = '']) =>
    (taskPrompt ?? _coachPrompt) +
    coachAnswerStandard +
    (taskPrompt == null ? coachTaskTemplate(coachTaskFor(context)) : '') +
    (taskPrompt == null ? '' : coachBriefingRules) +
    '\n\nDATE: ${coachTodayLine()}' +
    coachLanguageDirective(chat: taskPrompt == null);

/// Proof that the user just agreed to send health data to a cloud model.
class AiConsentToken {
  const AiConsentToken._(this.confirmedAt);

  static AiConsentToken confirmed() => AiConsentToken._(DateTime.now());

  final DateTime confirmedAt;

  /// Consent covers the next 10 minutes.
  bool get isFresh => DateTime.now().difference(confirmedAt).inMinutes < 10;
}

/// Chat and daily briefings against the configured provider. Health data is
/// sent as a compact TOON context appended to the system prompt.
class AiCoachClient {
  AiCoachClient({
    http.Client? client,
    AiCoachSettingsStore? store,
    AppleSender? appleSender,
  }) : _http = client ?? http.Client(),
       _store = store ?? const AiCoachSettingsStore(),
       // ignore: prefer_initializing_formals
       _appleSender = appleSender;

  /// Replaces the on-device model, for tests.
  final AppleSender? _appleSender;

  final http.Client _http;
  final AiCoachSettingsStore _store;

  static String _providerLabel(AiProvider p) => switch (p) {
    AiProvider.mistral => 'Mistral',
    AiProvider.openai => 'OpenAI',
    AiProvider.anthropic => 'Anthropic',
    AiProvider.gemini => 'Gemini',
    AiProvider.deepseek => 'DeepSeek',
    AiProvider.appleIntelligence => 'Apple Intelligence',
  };

  Future<String> send(
    AiCoachSettings settings,
    List<ChatMessage> messages,
    String toonContext, [
    AiConsentToken? consent,
  ]) async {
    if (!settings.ready) throw StateError('AI Coach is not configured.');
    if (settings.provider == AiProvider.appleIntelligence) {
      // ignore: avoid_print
      print('[AiCoach] chat → Apple Intelligence');
      final reply = await _sendAppleIntelligence(messages, toonContext);
      if (reply == null) {
        throw StateError(tr.appleNotAvailableOnDevice);
      }
      return reply;
    }
    if (settings.consentMode == AiConsentMode.everyMessage &&
        (consent == null || !consent.isFresh)) {
      throw StateError('Explicit data transfer consent is required.');
    }
    return _sendCloud(settings, messages, toonContext, 'chat');
  }

  Future<String> sendBriefing(AiCoachSettings settings, String toonContext) =>
      _sendBriefingRequest(
        settings,
        toonContext,
        _morningSysPrompt,
        _morningUserPrompt,
      );

  Future<String> sendLunchBriefing(
    AiCoachSettings settings,
    String toonContext,
  ) => _sendBriefingRequest(
    settings,
    toonContext,
    _lunchSysPrompt,
    _lunchUserPrompt,
  );

  Future<String> sendAfternoonBriefing(
    AiCoachSettings settings,
    String toonContext,
  ) => _sendBriefingRequest(
    settings,
    toonContext,
    _afternoonSysPrompt,
    _afternoonUserPrompt,
  );

  Future<String> sendEveningBriefing(
    AiCoachSettings settings,
    String toonContext,
  ) => _sendBriefingRequest(
    settings,
    toonContext,
    _eveningSysPrompt,
    _eveningUserPrompt,
  );

  /// One plain paragraph, or the app's own short text when the model's answer
  /// is too long, in the wrong language or just a copy of the facts.
  String _finishBriefing(String raw, String toonContext) {
    final text = flattenBriefing(raw);
    if (briefingIsUsable(text, languageCode: activeLocale.languageCode)) {
      return text;
    }
    final brief = BriefingBrief.parse(toonContext);
    log('[AiCoach] briefing not usable, written by the app');
    return brief == null ? text : brief.localText(tr);
  }

  /// Briefings prefer Apple Intelligence when enabled and fall back to the
  /// configured cloud provider.
  Future<String> _sendBriefingRequest(
    AiCoachSettings settings,
    String toonContext,
    String systemPrompt,
    String userPrompt,
  ) async {
    if (!settings.readyForBriefing) {
      throw StateError('AI Coach is not configured.');
    }
    final messages = [
      ChatMessage(
        text: '$userPrompt Write it in ${coachLanguageName()}.',
        isUser: true,
      ),
    ];
    if (settings.appleIntelligenceForBriefing ||
        settings.provider == AiProvider.appleIntelligence) {
      // ignore: avoid_print
      print(
        '[AiCoach] briefing → Apple Intelligence '
        '(toon=${toonContext.length}chars)',
      );
      final reply = await _sendAppleIntelligence(
        messages,
        toonContext,
        systemPrompt: systemPrompt,
      );
      if (reply != null) {
        // ignore: avoid_print
        print('[AiCoach] briefing ✓ Apple Intelligence');
        return _finishBriefing(reply, toonContext);
      }
      if (settings.provider == AiProvider.appleIntelligence) {
        throw StateError(tr.appleNotAvailableOnDevice);
      }
      // ignore: avoid_print
      print(
        '[AiCoach] briefing Apple Intelligence unavailable — falling through to cloud',
      );
    }
    return _finishBriefing(
      await _sendCloud(
        settings,
        messages,
        toonContext,
        'briefing',
        systemPrompt: systemPrompt,
      ),
      toonContext,
    );
  }

  Future<String> _sendCloud(
    AiCoachSettings settings,
    List<ChatMessage> messages,
    String toonContext,
    String kind, {
    String? systemPrompt,
  }) async {
    final provider = settings.provider;
    final key = (await _store.readApiKey(provider))?.trim();
    if (key == null || key.isEmpty) {
      throw StateError('Missing ${_providerLabel(provider)} API key.');
    }
    // ignore: avoid_print
    print('[AiCoach] $kind → ${_providerLabel(provider)} / ${settings.model}');
    switch (provider) {
      case AiProvider.mistral:
        return _sendOpenAiCompatible(
          Uri.parse('https://api.mistral.ai/v1/chat/completions'),
          key,
          settings.model,
          messages,
          toonContext,
          systemPrompt: systemPrompt,
        );
      case AiProvider.openai:
        return _sendOpenAiCompatible(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          key,
          settings.model,
          messages,
          toonContext,
          systemPrompt: systemPrompt,
        );
      case AiProvider.anthropic:
        return _sendAnthropic(
          key,
          settings.model,
          messages,
          toonContext,
          systemPrompt: systemPrompt,
        );
      case AiProvider.gemini:
        return _sendGemini(
          key,
          settings.model,
          messages,
          toonContext,
          systemPrompt: systemPrompt,
        );
      case AiProvider.deepseek:
        return _sendOpenAiCompatible(
          Uri.parse('https://api.deepseek.com/chat/completions'),
          key,
          settings.model,
          messages,
          toonContext,
          systemPrompt: systemPrompt,
        );
      case AiProvider.appleIntelligence:
        throw StateError(tr.appleNotAvailableOnDevice);
    }
  }

  Future<String> _sendOpenAiCompatible(
    Uri uri,
    String apiKey,
    String model,
    List<ChatMessage> messages,
    String toonContext, {
    String? systemPrompt,
  }) async {
    final body = jsonEncode(<String, Object>{
      'model': model,
      'temperature': 0.3,
      'messages': [
        {'role': 'system', 'content': _system(systemPrompt, toonContext)},
        {'role': 'system', 'content': 'HEALTH_CONTEXT:\n$toonContext'},
        for (final m in messages)
          {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
      ],
    });
    final response = await _http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    _throwIfFailed(response);
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    final text =
        ((json['choices'] as List?)?.first as Map?)?['message']?['content'];
    final trimmed = (text as String?)?.trim() ?? '';
    return trimmed.isEmpty ? 'No response content returned.' : trimmed;
  }

  /// Claude Messages API. Current Claude models think adaptively and reject
  /// non-default sampling parameters, so no `temperature` is sent; effort is
  /// kept low for short coaching answers, and server-side fallback retries a
  /// classifier refusal on another model.
  Future<String> _sendAnthropic(
    String apiKey,
    String model,
    List<ChatMessage> messages,
    String toonContext, {
    String? systemPrompt,
  }) async {
    final fallbackCapable = const {
      'claude-fable-5-1',
      'claude-opus-5-5',
      'claude-sonnet-5-5',
    }.contains(model);
    final body = jsonEncode(<String, Object>{
      'model': model,
      'max_tokens': 16000,
      'output_config': {'effort': 'low'},
      'system':
          '${_system(systemPrompt, toonContext)}\n\nHEALTH_CONTEXT:\n$toonContext',
      'messages': [
        for (final m in messages)
          {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
      ],
      if (fallbackCapable) 'fallbacks': 'default',
    });
    final response = await _http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        if (fallbackCapable)
          'anthropic-beta': 'server-side-fallback-2026-07-01',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    _throwIfFailed(response);
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    if (json['stop_reason'] == 'refusal') {
      throw StateError('Claude declined this request.');
    }
    final text = ((json['content'] as List?) ?? const [])
        .map((b) => b is Map && b['type'] == 'text' ? (b['text'] ?? '') : '')
        .where((t) => (t as String).trim().isNotEmpty)
        .join('\n')
        .trim();
    return text.isEmpty ? 'No response content returned.' : text;
  }

  Future<String> _sendGemini(
    String apiKey,
    String model,
    List<ChatMessage> messages,
    String toonContext, {
    String? systemPrompt,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent?key=$apiKey',
    );
    final body = jsonEncode(<String, Object>{
      'systemInstruction': {
        'parts': [
          {
            'text':
                '${_system(systemPrompt, toonContext)}\n\nHEALTH_CONTEXT:\n$toonContext',
          },
        ],
      },
      'contents': [
        for (final m in messages)
          {
            'role': m.isUser ? 'user' : 'model',
            'parts': [
              {'text': m.text},
            ],
          },
      ],
      'generationConfig': <String, double>{'temperature': 0.3},
    });
    final response = await _http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    _throwIfFailed(response);
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    final text =
        (((json['candidates'] as List?)?.first as Map?)?['content']
                as Map?)?['parts']
            as List?;
    final reply = (text?.first as Map?)?['text'] as String?;
    final trimmed = reply?.trim() ?? '';
    return trimmed.isEmpty ? 'No response content returned.' : trimmed;
  }

  /// Runs on-device; returns null when Apple Intelligence is unavailable.
  Future<String?> _sendAppleIntelligence(
    List<ChatMessage> messages,
    String toonContext, {
    String? systemPrompt,
  }) async {
    final fm = FoundationModelsFramework.instance;
    if (_appleSender == null) {
      final availability = await fm.checkAvailability();
      log(
        '[AiCoach] Apple availability=${availability.isAvailable} '
        'reason=${availability.reasonCode} ${availability.osVersion}',
      );
      if (!availability.isAvailable) return null;
    }

    final locale = coachLocaleTag();
    // Briefings carry the longer rule block, so they start with more room.
    final isBriefing = systemPrompt != null;
    var budget = isBriefing ? 4600 : 3000;
    final retryBudget = isBriefing ? 3600 : 2200;
    var strict = false;
    var bare = false;
    var echoed = false;
    var languageRetried = false;
    var forceLanguage = false;
    for (var attempt = 0; attempt < 5; attempt++) {
      final request = AppleCoachRequest.build(
        messages,
        toonContext,
        briefingInstructions: systemPrompt,
        budget: budget,
        locale: locale,
        strict: strict,
        includeContext: !bare,
        forceLanguage: forceLanguage,
      );
      log(
        '[AiCoach] Apple input=${request.inputBytes} bytes, '
        'attempt=${attempt + 1}, locale=$locale, strict=$strict, bare=$bare',
      );
      try {
        // sendPrompt creates and disposes a fresh native session per request.
        final text =
            (_appleSender != null
                    ? await _appleSender(request)
                    : (await fm.sendPrompt(
                        request.prompt,
                        instructions: request.instructions,
                        // A low temperature keeps a small model from drifting into
                        // loops and invented figures; the token limit only guards
                        // against a runaway reply (the length comes from the
                        // prompt, as Apple advises).
                        options: GenerationOptionsRequest(
                          temperature: 0.3,
                          maximumResponseTokens: 400,
                        ),
                      )).content)
                .trim();
        if (looksLikeContextEcho(text) || looksLikeRepetition(text)) {
          // The model repeated the data or itself instead of answering. Try
          // once more with less data; a second failure is reported,
          // never shown.
          log(
            '[AiCoach] Apple gave an unusable reply (attempt=${attempt + 1})',
          );
          if (!echoed) {
            echoed = true;
            budget = retryBudget;
            continue;
          }
          throw AiCoachException(tr.appleUnusableAnswer);
        }
        // Answered in English although the app is not: once more, firmly. (A
        // briefing is checked later and replaced by the app's own text.)
        if (!isBriefing &&
            !languageRetried &&
            looksWrongLanguage(text, activeLocale.languageCode)) {
          log('[AiCoach] Apple answered in the wrong language, asking again');
          languageRetried = true;
          forceLanguage = true;
          continue;
        }
        log(
          '[AiCoach] Apple ✓ attempt=${attempt + 1} strict=$strict bare=$bare',
        );
        return text.isEmpty ? 'No response.' : text;
      } catch (e) {
        if (e is AiCoachException) rethrow;
        log('[AiCoach] Apple request failed: $e');
        final msg = e.toString().toLowerCase();
        final contextExceeded =
            msg.contains('context window') ||
            msg.contains('exceededcontextwindowsize') ||
            msg.contains('contextsizeexceeded');
        final language =
            msg.contains('unsupportedlanguageorlocale') ||
            msg.contains('unsupported language');
        if (contextExceeded && budget > retryBudget) {
          budget = retryBudget;
          continue;
        }
        if (language && !strict) {
          strict = true;
          continue;
        }
        // Last resort: without health data, to tell a content trigger
        // apart from a device-level language problem.
        if (language && !bare) {
          bare = true;
          continue;
        }
        throw AiCoachException(appleCoachFailureMessage(e));
      }
    }
    throw AiCoachException(tr.appleCouldNotAnswer);
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = response.body;
    try {
      final json = jsonDecode(response.body);
      final error = json is Map ? json['error'] : null;
      if (error is Map && error['message'] != null) {
        message = error['message'] as String;
      } else if (error is String) {
        message = error;
      }
    } catch (_) {}
    throw StateError(
      'Provider request failed (${response.statusCode}): $message',
    );
  }
}
