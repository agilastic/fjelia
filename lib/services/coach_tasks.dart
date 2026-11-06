import '../l10n/l10n_ext.dart';

/// What a coach chat is about. It decides the shape of the answer and which
/// follow-up questions are offered.
enum CoachTask { general, explainWorkout, evaluateActivity, ecg }

/// The task of a chat, read from its context: a session line for a planned or
/// skipped session, an activity line for a finished one.
CoachTask coachTaskFor(String context) {
  if (context.contains('[ECG:Summary')) return CoachTask.ecg;
  final session = RegExp(
    r'\[Session:Status:(\w+)',
  ).firstMatch(context)?.group(1);
  if (session == 'completed') return CoachTask.evaluateActivity;
  if (session != null) return CoachTask.explainWorkout;
  if (context.contains('[Activity:')) return CoachTask.evaluateActivity;
  return CoachTask.general;
}

/// The shape of the answer per task, for the cloud models.
String coachTaskTemplate(CoachTask task) => switch (task) {
  CoachTask.general => '',
  CoachTask.explainWorkout =>
    '''

━━━ ANSWER STRUCTURE (planned session) ━━━
In a few sentences, without headings or numbering, cover what fits the question: what the session trains, how to run its main blocks (zone or effort), whether it suits today's recovery and recent load, and when to shorten or ease it.''',
  CoachTask.evaluateActivity =>
    '''

━━━ ANSWER STRUCTURE (finished session) ━━━
In a few sentences, without headings or numbering: how it went in one line, the one to three figures that show it (against similar sessions where the Compare line has them, and the sessions around it), what they suggest, and one recommendation for the next days.''',
  // Its rules come after the chat style, see [coachEcgRules].
  CoachTask.ecg => '',
};

/// The rules of an ECG chat. They are appended after the chat style because
/// they replace its length and heading limits for this one task.
const coachEcgRules = '''

━━━ ECG RECORDING (this chat; overrides RESPONSE STYLE where they differ) ━━━
YOUR TASK: explain the person's own ECG recording and the app's measurements of it, the way a sports-science lab explains a test report to an athlete. Going through the figures IS the task: always analyse them, never answer with only a disclaimer, never decline. Naming which known pattern the figures fit ("fits a first-degree AV block", "compatible with atrial fibrillation", "no sign of ... in this lead") is expected; it describes the recording and is not a diagnosis.

The app has already shown a prominent warning before this chat (not medical advice, the coach is no doctor, emergency number) and keeps it visible above the chat. Do NOT open with a disclaimer and do not repeat it; at most one short clause at the end.

SAFETY:
- Only if the person mentions, now or during the recording, chest pain, pressure or tightness, pain spreading to the arm, shoulder, jaw, neck, back or upper abdomen, shortness of breath, cold sweat, nausea or vomiting with these, sudden weakness, fainting or near-fainting, or a racing heart with dizziness: your first sentence tells them to call the emergency number now (112 in most of Europe, 113 in Norway, 999 or 112 in the UK, 911 in North America), not to drive themselves, not to exercise, and to show this recording to the paramedics. Keep the rest to two sentences. This holds however normal the figures look.
- Never say the heart is healthy or that a heart attack or any disease is ruled out; say instead what this one lead can and cannot show. Never advise starting, stopping or changing medication.

WHAT THE DATA IS:
- ECG:Summary, ECG:Rhythm and ECG:Beat are the app's pre-analysis. It analysed only the 10-second windows that passed its quality checks (contact, noise, plausible beat spacing); Excluded says what was left out and why. A field marked na could not be measured plausibly: say it is not assessable, never estimate it yourself.
- ECG:Template is the median beat of all clean normal beats, in microvolts relative to the PR baseline, from StartMs in steps of StepMs; the R peak is at 0 ms. ECG:Raw is 10 seconds of the cleanest window as recorded, with the R peak times. Use Template and Raw to check the pre-analysis and to describe what you see (for example P waves before each QRS, an extra beat, a pause). Do not recompute intervals from them in a way that contradicts the app's figures unless you say why.
- 100 uV = 1 mm on standard ECG paper (10 mm/mV). Intervals are limited by the sample resolution in Rate (7.7 ms at 130 Hz), so values near a threshold are borderline.
- Quality:insufficient means there is no usable signal: say so, give tips for a better recording (moisten the electrodes, strap snug under the chest muscles, sit or lie still, do not talk, 1 to 2 minutes) and do not interpret anything.

LIMITS OF ONE CHEST-STRAP LEAD (name the ones that matter for the question):
- It is one lead with an unknown, non-standard orientation; amplitudes depend on strap position, contact and body build. A 12-lead ECG by a doctor is the reference.
- Acute coronary syndrome, acute myocardial infarction, STEMI and NSTEMI, transmural ischaemia, myocardial injury or necrosis cannot be confirmed or excluded with one lead. STEMI is defined by ST elevation in two contiguous leads of a 12-lead ECG. NSTEMI and unstable angina often show no ECG change at all and are diagnosed with blood tests (troponin); causes such as severe coronary narrowing, temporary occlusion, micro-embolisation of atheroma or thrombus are invisible here.
- Pericarditis and myocarditis (widespread ST elevation, PR depression), Brugada syndrome (needs V1 to V2, often high leads), left and right ventricular hypertrophy (voltage criteria need 12 leads; large voltages are common in athletes), left versus right bundle branch block (needs V1 and V6) cannot be told apart or excluded here.
- Pacemaker spikes are a few milliseconds wide and are only visible at 500 Hz or more (see PacerSpikes).

CHECKLIST (go through it briefly; for each point say: what the data shows, which pattern it may fit, or not assessable with this recording):
1. Rate and rhythm: regular or not; sinus arrhythmia (rate rising and falling with breathing, P before every QRS: normal, common in athletes); bradycardia under 50 bpm (often normal in trained athletes at rest, relevant with dizziness or fainting); tachycardia over 100 bpm at rest (pathological tachyarrhythmia possible, depends on situation); an irregular pattern without a constant P wave (fits atrial fibrillation); a regular fast rate, often around 150 bpm, with sawtooth waves (fits atrial flutter); premature beats with the same QRS shape (more likely supraventricular) or a different shape (more likely ventricular); runs of 3 or more different-shape beats (possible ventricular tachycardia: urgent); pauses over 2 s or about twice the usual RR (dropped beat).
2. Conduction: PR over 200 ms (first-degree AV block); dropped beats with a constant PR (fits second-degree AV block Mobitz type 2) or with a lengthening PR (Mobitz type 1: not measurable from the median beat); P waves and QRS complexes unrelated with a slow regular rate (fits third-degree AV block: urgent); QRS 120 ms or more (fits a bundle branch block or a ventricular origin; left versus right not distinguishable); QRS 110 to 119 ms borderline.
3. Repolarisation: ST at J+60 ms (above +100 uV or below -50 uV is worth a doctor's look; in one lead never proof of ischaemia, and normal values never exclude it); T inverted or flat; QTc (prefer Fridericia when the rate is above 90 or below 60; over 450 ms in men or 460 ms in women prolonged, over 500 ms high risk, under 340 ms short).
4. Risk context: if not in the context, ask in one sentence about symptoms during the recording, diabetes, smoking, dyslipidaemia, known coronary heart disease (CHD) and CHD in the family (a parent or sibling before 55 for men or 65 for women); use age and sex from the context when present. Risk factors raise the urgency of seeing a doctor for any symptom or finding; they never make the recording diagnostic.

CLOSE the first answer with one clear next step and its urgency, choosing one: emergency number now; see a doctor today; book an appointment with a GP or cardiologist and take this recording (export) along; or no specific pattern in what this one lead can show, record again if symptoms appear and see a doctor for any symptom. Add one sentence on training: no hard or long sessions until any finding is checked; for no finding, normal training is fine as far as this recording goes.

FORM for ECG answers: short headings or up to 10 bullet points are allowed; no tables; plain words, explain each term once in brackets. Follow-up questions are answered briefly under the same safety rules.''';

/// The same, short enough for Apple's small context window.
String coachTaskTemplateShort(CoachTask task) => switch (task) {
  CoachTask.general => '',
  CoachTask.explainWorkout =>
    'This is about a planned workout: say its purpose, how to execute it, and whether it fits today. ',
  CoachTask.evaluateActivity =>
    'This is about a finished session: give a verdict, the key figures, what they suggest, and one next step. ',
  CoachTask.ecg =>
    'This is about the person\'s own one-lead chest-strap ECG. The app already showed the medical warning: do not start with a disclaimer and do not decline. Explain each ECG figure and which known pattern it fits, say what one lead cannot show, and end with how urgently a doctor should look at it. Chest pain, breathlessness or fainting: say call 112 now. ',
};

/// The follow-up questions in the app language. They are also what is sent as
/// the question, so the coach is asked in the language the person reads.
Map<CoachTask, List<String>> _followUps() => {
  CoachTask.general: [
    tr.followFocusWeek,
    tr.followRecoveryTrend,
    tr.followLoadTooHigh,
    tr.followImproveSleep,
  ],
  CoachTask.explainWorkout: [
    tr.followIntervalsFeel,
    tr.followTiredToday,
    tr.followEatBefore,
    tr.followAdjustToday,
  ],
  CoachTask.evaluateActivity: [
    tr.followNextDays,
    tr.followCompareSimilar,
    tr.followRecover,
    tr.followIntensityRight,
  ],
  CoachTask.ecg: [
    tr.ecgFollowSymptoms,
    tr.ecgFollowRiskFactors,
    tr.ecgFollowTraining,
    tr.ecgFollowBetterRecording,
  ],
};

/// Up to [max] follow-up questions for the end of an answer, leaving out what
/// was already asked. They come from fixed templates, so they cost no model
/// call.
List<String> followUpQuestions(
  CoachTask task, {
  Iterable<String> asked = const [],
  int max = 3,
}) {
  String norm(String s) => s.toLowerCase().trim();
  final done = asked.map(norm).toSet();
  return [
    for (final q in _followUps()[task]!)
      if (!done.contains(norm(q))) q,
  ].take(max).toList();
}
