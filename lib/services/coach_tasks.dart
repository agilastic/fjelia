import '../l10n/l10n_ext.dart';

/// What a coach chat is about. It decides the shape of the answer and which
/// follow-up questions are offered.
enum CoachTask { general, explainWorkout, evaluateActivity }

/// The task of a chat, read from its context: a session line for a planned or
/// skipped session, an activity line for a finished one.
CoachTask coachTaskFor(String context) {
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
1. Purpose: what this session trains, in one sentence.
2. Execution: the main blocks with their zone or effort, concrete and short.
3. Fit for today: whether it suits the current recovery and recent load, with at most three figures. If data is missing, name what would settle it.
4. One rule for when to shorten or ease it.''',
  CoachTask.evaluateActivity =>
    '''

━━━ ANSWER STRUCTURE (finished session) ━━━
1. Verdict: one sentence.
2. Measured: at most three figures, compared with similar sessions where the Compare line has them.
3. Interpretation: what the figures suggest. Say that it is an interpretation.
4. Next days: one recommendation.''',
};

/// The same, short enough for Apple's small context window.
String coachTaskTemplateShort(CoachTask task) => switch (task) {
  CoachTask.general => '',
  CoachTask.explainWorkout =>
    'This is about a planned workout: say its purpose, how to execute it, and whether it fits today. ',
  CoachTask.evaluateActivity =>
    'This is about a finished session: give a verdict, the key figures, what they suggest, and one next step. ',
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
