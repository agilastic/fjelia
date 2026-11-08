import 'package:fjelia_service/fjelia_service.dart';

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

/// Whether this build reads ECGs medically: with FjeliaPro, or in the
/// developer's own builds with `FJELIA_ECG_CLINICAL`; both need the private
/// package. Every other build reads them for training only.
final ecgClinical = createEcgClinicalRules();

bool get ecgClinicalMode => ecgClinical.isAvailable;

/// The rules of an ECG chat. They are appended after the chat style because
/// they replace its length and heading limits for this one task.
String get coachEcgRules =>
    ecgClinicalMode ? ecgClinical.rules : _ecgFitnessRules;

/// For training only: the ECG is a heart-rate and HRV source here. Reading
/// it medically (rhythm disorders, conduction, ischaemia, urgency) would make
/// Fjelia a medical device (MDR, Annex VIII, rule 11).
const _ecgFitnessRules = '''

━━━ ECG RECORDING, TRAINING VIEW (this chat; overrides RESPONSE STYLE where they differ) ━━━
Fjelia uses the chest-strap ECG for training only: heart rate, heart-rate variability (RMSSD, SDNN, pNN50) and signal quality. It does not read ECGs medically, and neither do you.

- Explain the figures in the context for training and recovery: the heart-rate level and range during the recording, what the HRV says about recovery (compared with the athlete's usual HRV when the context has it), and the signal quality.
- Never name, suggest or rule out a heart condition or rhythm disorder (for example atrial fibrillation, heart block, extra beats, ischaemia, QT), never say whether the heart or the recording is normal, healthy or abnormal, never say how urgently a doctor should look at it, and never interpret the waveform's shape.
- Asked about heart health, a rhythm, a pattern or anything medical about this recording: say plainly that Fjelia does not read ECGs medically and cannot answer that; a doctor can, and the recording can be exported from the ECG screen to show them. Do not soften this with a guess.
- Chest pain, pressure or tightness, shortness of breath, fainting or near-fainting, or a racing heart with dizziness, mentioned at any point: your first sentence says to call the emergency number now (112 in most of Europe, 911 in North America) and not to exercise. This is general safety advice and does not come from the recording.
- Quality:insufficient: say there is no usable signal and give tips for a better recording (moisten the electrodes, strap snug under the chest muscles, sit or lie still, do not talk, 1 to 2 minutes).

FORM: a few plain sentences, no tables, no headings.''';

/// The same, short enough for Apple's small context window.
String coachTaskTemplateShort(CoachTask task) => switch (task) {
  CoachTask.general => '',
  CoachTask.explainWorkout =>
    'This is about a planned workout: say its purpose, how to execute it, and whether it fits today. ',
  CoachTask.evaluateActivity =>
    'This is about a finished session: give a verdict, the key figures, what they suggest, and one next step. ',
  CoachTask.ecg =>
    ecgClinicalMode
        ? ecgClinical.shortRules
        : 'This is about the heart rate and HRV of the person\'s chest-strap ECG, for training only. Explain them for training and recovery. Never name or rule out a heart condition, never judge the heart or the waveform, never say how urgently to see a doctor; asked about that, say Fjelia does not read ECGs medically and a doctor can, with the exported recording. Chest pain, breathlessness or fainting: say call 112 now. ',
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
  CoachTask.ecg: ecgClinicalMode
      ? [
          tr.ecgFollowSymptoms,
          tr.ecgFollowRiskFactors,
          tr.ecgFollowTraining,
          tr.ecgFollowBetterRecording,
        ]
      : [tr.ecgFollowHrv, tr.ecgFollowHeartRate, tr.ecgFollowBetterRecording],
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
