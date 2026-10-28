import '../l10n/app_localizations.dart';

/// What the daily briefing is about, decided by the app and not by a model:
/// the readiness colour, the few findings that matter (worst first) and what
/// was done and is planned. A small on-device model only turns this into two
/// short sentences; if its answer is unusable the app writes them itself.
///
/// Line form: `[Brief:Readiness:yellow,Findings:energyLow|sleepShort,Good:none,
/// Done:running/88,Today:none,Tomorrow:cycling_road/36|strength/35,TrainingHrv:up]`
class BriefingBrief {
  const BriefingBrief({
    required this.readiness,
    this.findings = const [],
    this.good = const [],
    this.done = const [],
    this.today = const [],
    this.tomorrow = const [],
    this.trainingHrv,
    this.outlook,
  });

  /// green, yellow or red.
  final String readiness;

  /// Worst first, at most three.
  final List<String> findings;
  final List<String> good, done, today, tomorrow;

  /// `up` or `down`: the chest-strap reading before and after a workout.
  final String? trainingHrv;

  /// What the load forecast says happens next (see [FormForecast.outlook]).
  final String? outlook;

  static String _list(List<String> v) => v.isEmpty ? 'none' : v.join('|');

  String toLine() =>
      '[Brief:Readiness:$readiness,Findings:${_list(findings)},'
      'Good:${_list(good)},Done:${_list(done)},Today:${_list(today)},'
      'Tomorrow:${_list(tomorrow)},TrainingHrv:${trainingHrv ?? 'none'},'
      'Outlook:${outlook ?? 'none'}]';

  static BriefingBrief? parse(String toon) {
    final m = RegExp(r'\[Brief:([^\]]*)\]').firstMatch(toon);
    if (m == null) return null;
    final f = <String, String>{};
    for (final part in m[1]!.split(',')) {
      final i = part.indexOf(':');
      if (i > 0) f[part.substring(0, i)] = part.substring(i + 1);
    }
    List<String> list(String? v) =>
        v == null || v == 'none' ? const [] : v.split('|');
    final readiness = f['Readiness'];
    if (readiness == null) return null;
    final hrv = f['TrainingHrv'];
    final out = f['Outlook'];
    return BriefingBrief(
      readiness: readiness,
      findings: list(f['Findings']),
      good: list(f['Good']),
      done: list(f['Done']),
      today: list(f['Today']),
      tomorrow: list(f['Tomorrow']),
      trainingHrv: hrv == null || hrv == 'none' ? null : hrv,
      outlook: out == null || out == 'none' ? null : out,
    );
  }

  /// The load forecast's outlook in English, for a model.
  static String outlookEnglish(String id) {
    if (id.startsWith('restFixes:')) {
      return 'about ${id.substring(10)} easy days bring form back to the optimal range';
    }
    return switch (id) {
      'needsLongRest' => 'form needs more than a few easy days to recover',
      'planKeepsTired' => 'the plan keeps form low for the next days',
      _ => id,
    };
  }

  /// The outlook as a sentence in the app language.
  static String? outlookText(AppLocalizations l, String? id) {
    if (id == null) return null;
    if (id.startsWith('restFixes:'))
      return l.briefOutlookRest(id.substring(10));
    return switch (id) {
      'needsLongRest' => l.briefOutlookLongRest,
      'planKeepsTired' => l.briefOutlookPlanTired,
      _ => null,
    };
  }

  /// A finding in English words, for a model.
  static String englishFinding(String id) => _english[id] ?? id;

  static const _english = {
    'hrvLow': 'low sleep HRV',
    'hrvHigh': 'high sleep HRV',
    'rhrUp': 'resting heart rate raised',
    'rhrDown': 'resting heart rate low',
    'sleepShort': 'too little sleep',
    'sleepGood': 'sleep need met',
    'energyLow': 'very low energy',
    'energyHigh': 'good energy',
    'stressHigh': 'high stress',
    'respHigh': 'breathing rate raised',
    'spo2Low': 'low blood oxygen',
    'skinTempOff': 'unusual skin temperature',
    'formTired': 'accumulated training fatigue',
    'formVeryTired': 'very high training fatigue',
    'formFresh': 'fresh and rested',
  };

  /// The compact text the model gets. Words, not figures: the person sees
  /// every figure on screen already.
  String toModelText() {
    String names(List<String> v) => v.map((e) => _english[e] ?? e).join('; ');
    String plan(List<String> v) => v
        .map((e) {
          final p = e.split('/');
          return p.length == 2 ? '${p[0].replaceAll('_', ' ')} ${p[1]} min' : e;
        })
        .join(' and ');
    final parts = <String>[
      'Readiness ${readiness.toUpperCase()}',
      if (findings.isNotEmpty)
        'Main findings, most important first: ${names(findings)}',
      if (good.isNotEmpty) 'Good: ${names(good)}',
      if (done.isNotEmpty) 'Done today: ${plan(done)}',
      if (today.isNotEmpty) 'Still planned today: ${plan(today)}',
      if (tomorrow.isNotEmpty) 'Planned tomorrow: ${plan(tomorrow)}',
      if (trainingHrv != null)
        'HRV before and after the workout ${trainingHrv == 'up' ? 'rose (favourable)' : 'fell (less favourable)'}',
      if (outlook != null) 'Outlook: ${outlookEnglish(outlook!)}',
    ];
    return '${parts.join('. ')}.';
  }

  String _reason(AppLocalizations l, String id) => switch (id) {
    'hrvLow' => l.briefReasonHrvLow,
    'hrvHigh' => l.briefReasonHrvHigh,
    'rhrUp' => l.briefReasonRhrUp,
    'rhrDown' => l.briefReasonRhrDown,
    'sleepShort' => l.briefReasonSleepShort,
    'sleepGood' => l.briefReasonSleepGood,
    'energyLow' => l.briefReasonEnergyLow,
    'energyHigh' => l.briefReasonEnergyHigh,
    'stressHigh' => l.briefReasonStressHigh,
    'respHigh' => l.briefReasonRespHigh,
    'spo2Low' => l.briefReasonSpo2Low,
    'skinTempOff' => l.briefReasonSkinTempOff,
    'formTired' => l.briefReasonFormTired,
    'formVeryTired' => l.briefReasonFormVeryTired,
    'formFresh' => l.briefReasonFormFresh,
    _ => id,
  };

  /// The briefing written by the app, in the app language: used when a model
  /// is not available or its answer is not usable. Short on purpose.
  String localText(AppLocalizations l) {
    final head = switch (readiness) {
      'red' => l.briefHeadRed,
      'yellow' => l.briefHeadYellow,
      _ => l.briefHeadGreen,
    };
    final advice = switch (readiness) {
      'red' => l.briefAdviceRed,
      'yellow' => l.briefAdviceYellow,
      _ => l.briefAdviceGreen,
    };
    final reasons = [
      for (final e in (readiness == 'green' ? good.take(2) : findings.take(3)))
        _reason(l, e),
    ];
    final why = reasons.isEmpty
        ? l.briefAllClear
        : l.briefMain(reasons.join(', '));
    // The chest-strap reading is its own remark, not a reason for strain: a
    // rise after the workout is the favourable direction.
    final training = trainingHrv == null
        ? ''
        : ' ${trainingHrv == 'up' ? l.briefTrainingHrvUp : l.briefTrainingHrvDown}';
    final outlookSentence = outlookText(l, outlook);
    return '$head $why$training${outlookSentence == null ? '' : ' $outlookSentence'} $advice';
  }
}

/// Whether a model's briefing can be shown: short, in the app language, and
/// not a copy of the facts it was given.
bool briefingIsUsable(String text, {required String languageCode}) {
  final t = text.trim();
  if (t.isEmpty) return false;
  final words = t.split(RegExp(r'\s+'));
  if (words.length > 65) return false;
  final lower = t.toLowerCase();
  const echoes = [
    '(state ',
    'readiness',
    'verdict',
    'average of',
    'key facts',
    'analysis',
    'sleephrv',
    'chest strap',
    'brief:',
    'findings',
    'never compare',
  ];
  if (echoes.any(lower.contains)) return false;
  // Many figures means it is listing values the person already sees.
  if (RegExp(r'\d+[.,]?\d*').allMatches(t).length > 4) return false;
  if (looksWrongLanguage(t, languageCode)) return false;
  return true;
}

/// Whether [text] reads as English although the app is not English: a small
/// model tends to slip back into the language of the data it was given.
bool looksWrongLanguage(String text, String languageCode) {
  if (languageCode == 'en') return false;
  const english = {
    'the', 'and', 'is', 'your', 'today', 'was', 'are', 'with', 'from', 'you', //
    'which', 'this', 'that', 'should', 'athlete', 'suggests', 'of', 'to',
  };
  final hits = text
      .split(RegExp(r'\s+'))
      .map((w) => w.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''))
      .where(english.contains)
      .length;
  return hits >= 3;
}
