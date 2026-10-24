/// Rules for how the coach answers, shared by every provider and task.
/// The cloud models get the full block; Apple's small context window gets
/// the short one.
const coachAnswerStandard = '''

━━━ ANSWER STANDARD (applies to everything above) ━━━
- Answer the actual question first, in the user's language.
- Keep apart what was measured, what you interpret from it and what you recommend. Never present an interpretation as a measurement.
- Support a recommendation with at most three relevant observations, each with its date and figure.
- DataStatus lists the newest record per source and the gaps. A missing record means unknown, never rest, no training or good recovery. Do not say the user did not train, and do not call a gap a break. If a gap changes your advice, name it and say what would settle it.
- A later workout does not prove an earlier load was absorbed well.
- Scores, training status (CTL, ATL, TSB) and model labels are estimates, not measurements; word them that way. Mention uncertainty only where it would change the decision, in one sentence.
- Keep answers short by default and offer details on request.''';

/// For Apple Intelligence, whose context window is small.
const coachAnswerStandardShort =
    'You MUST use only numbers that appear in the data. DO NOT invent numbers; say so when a number is missing. '
    'DO NOT repeat or list the data. '
    'Missing records mean unknown, NOT rest or no training. '
    'Keep apart measured facts, interpretation and advice; give at most three reasons; '
    'name uncertainty only when it changes the advice. ';
