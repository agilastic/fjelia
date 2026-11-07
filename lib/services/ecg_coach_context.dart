import '../db/database.dart';
import 'ecg_analysis.dart';

/// ECG context for the coach chat, in two stages. By default the coach only
/// learns that a recording exists ([ecgAvailableLine]); its analysis is added
/// to the request when the question is about the ECG ([ecgDetailLines]).
/// None of the providers can call tools, so the app reads the question and
/// enriches the context before it is sent.

/// A question about the heart's rhythm or the ECG itself, in the app's ten
/// languages. Words that also mean pace ("ritmo") only count with the heart.
final _ecgQuestion = RegExp(
  r'\b(ecg|ekg|e\.k\.g|elektrokardio|electrocardio|elettrocardio|'
  r'heart ?rhythm|herzrhythm|rythme cardi|ritmo cardi|ritme cardí|'
  r'hjerterytm|srdcov\w* rytm|sydämen rytm|rytmihäiri|'
  r'arrhythm|arythm|aritm|arytm|irregular|unregelmä|unregelmässig|'
  r'irrégul|irregolar|uregelm|nepravideln|epäsäännöl|'
  r'extrasystol|premature beat|pvcs?\b|vorhofflimmer|afib|a-fib|'
  r'fibrillation|fibrillazion|fibrilación|fibril·lació|flimmer|'
  r'qrs|qtc|st[- ](segment|strecke|hebung|senkung|elevation|depression)|'
  r'herzstolper|palpitation|skipped beats?|herzaussetzer)',
  caseSensitive: false,
);

/// Whether [question] asks about the ECG or the heart's rhythm.
bool asksAboutEcg(String question) => _ecgQuestion.hasMatch(question);

/// A period named in the question, in minutes from the start: "minute 35",
/// "min 30-40", "35. Minute", "minuto 35".
({int from, int to})? askedMinutes(String question) {
  const word =
      r'(?:minutes?|minuten?|minuto|minut[oaeiy]?|minuutilla|minuutti|min)';
  final before = RegExp(
    '\\b$word\\.?\\s*(\\d{1,3})(?:\\s*(?:-|–|to|bis|a|til|až|-)\\s*(\\d{1,3}))?',
    caseSensitive: false,
  ).firstMatch(question);
  final after = RegExp(
    '\\b(\\d{1,3})\\.?\\s*$word\\b',
    caseSensitive: false,
  ).firstMatch(question);
  final m = before ?? after;
  if (m == null) return null;
  final from = int.parse(m[1]!);
  final to = m.groupCount >= 2 && m[2] != null ? int.parse(m[2]!) : from + 1;
  return to > from ? (from: from, to: to) : (from: to, to: from + 1);
}

/// A clock time named in the question ("14:30", "14.30 Uhr").
({int hour, int minute})? askedClock(String question) {
  final m =
      RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b').firstMatch(question) ??
      RegExp(
        r'\b([01]?\d|2[0-3])\.([0-5]\d)\s*uhr\b',
        caseSensitive: false,
      ).firstMatch(question);
  if (m == null) return null;
  return (hour: int.parse(m[1]!), minute: int.parse(m[2]!));
}

final _today = RegExp(
  r'\b(today|this morning|tonight|heute|aujourd|ce matin|oggi|stamattina|'
  r'hoy|esta mañana|avui|aquest matí|i dag|i morges|i morgen tidlig|dnes|'
  r'ráno|tänään|aamulla)',
  caseSensitive: false,
);
final _yesterday = RegExp(
  r'\b(yesterday|gestern|hier\b|ieri|ayer|ahir|i går|igår|včera|eilen)',
  caseSensitive: false,
);
final _latest = RegExp(
  r'\b(last|latest|most recent|letzte|neueste|dernier|dernière|ultim[oa]|'
  r'últim[oa]|darrer|darrera|siste|seneste|posledn|viimeisin|edellinen)',
  caseSensitive: false,
);

/// Which recording a question is about.
sealed class EcgPick {
  const EcgPick();
}

class NoEcg extends EcgPick {
  const NoEcg();
}

class OneEcg extends EcgPick {
  const OneEcg(this.recording);
  final EcgRecording recording;
}

/// More than one recording fits and nothing tells them apart: the coach asks.
class SeveralEcgs extends EcgPick {
  const SeveralEcgs(this.recordings);
  final List<EcgRecording> recordings;
}

/// The recordings of [activity]: linked to it, or taken while it ran.
List<EcgRecording> activityEcgs(
  List<EcgRecording> rows,
  ActivityRecord activity,
) {
  final start = activity.startDate.subtract(const Duration(minutes: 15));
  final end = activity.startDate.add(
    Duration(seconds: activity.durationSeconds.round() + 15 * 60),
  );
  return [
    for (final r in rows)
      if (r.activityId == activity.activityId ||
          (r.activityId == null &&
              r.recordedAt.isAfter(start) &&
              r.recordedAt.isBefore(end)))
        r,
  ];
}

/// The recording [question] is about, among [rows] (newest first). With an
/// [activity] only its recordings count. A clock time, "today", "yesterday"
/// or "last" narrow the choice; without any, the only recording of the last
/// two weeks is taken. It never guesses between several.
EcgPick pickEcg(
  List<EcgRecording> rows, {
  required String question,
  ActivityRecord? activity,
  required DateTime now,
}) {
  var candidates = activity == null ? rows : activityEcgs(rows, activity);
  if (candidates.isEmpty) return const NoEcg();
  final local = now.toLocal();
  final today = DateTime(local.year, local.month, local.day);
  bool onDay(EcgRecording r, DateTime day) {
    final t = r.recordedAt.toLocal();
    return t.year == day.year && t.month == day.month && t.day == day.day;
  }

  if (_yesterday.hasMatch(question)) {
    final day = today.subtract(const Duration(days: 1));
    candidates = [
      for (final r in candidates)
        if (onDay(r, day)) r,
    ];
  } else if (_today.hasMatch(question)) {
    candidates = [
      for (final r in candidates)
        if (onDay(r, today)) r,
    ];
  }
  if (askedClock(question) case final c?) {
    final asked = c.hour * 60 + c.minute;
    candidates = [
      for (final r in candidates)
        if ((r.recordedAt.toLocal().hour * 60 +
                    r.recordedAt.toLocal().minute -
                    asked)
                .abs() <=
            20)
          r,
    ];
  }
  if (candidates.isEmpty) return const NoEcg();
  if (candidates.length == 1) return OneEcg(candidates.single);
  final newest = [...candidates]
    ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  if (_latest.hasMatch(question)) return OneEcg(newest.first);
  if (activity == null) {
    final recent = [
      for (final r in newest)
        if (now.difference(r.recordedAt).inDays < 14) r,
    ];
    if (recent.length == 1) return OneEcg(recent.single);
  }
  return SeveralEcgs(newest.take(5).toList());
}

String _stamp(DateTime at) {
  final t = at.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}

/// Stage 1: the coach knows the recording exists, and that it knows nothing
/// of its content yet.
String ecgAvailableLine(EcgRecording r) =>
    '[ECG:Available,Id:${r.recordingId},Recorded:${_stamp(r.recordedAt)},'
    'Duration:${(r.durationMs / 1000).round()}s,Kind:${r.kind},'
    'Activity:${r.activityId ?? 'none'},'
    'Analysis:not loaded (the app adds it when the athlete asks about the ECG; '
    'until then say nothing about its content)]';

/// Several recordings fit the question: the coach asks which one.
String ecgChoiceLine(List<EcgRecording> rows) =>
    '[ECG:Choose,Several ECG recordings fit the question and none is loaded; '
    'ask the athlete which one before saying anything about an ECG,'
    'Candidates:${[for (final r in rows) '${_stamp(r.recordedAt)} (${(r.durationMs / 60000).round()} min ${r.kind})'].join(' | ')}]';

/// The athlete did not want the ECG shared with the coach.
const ecgDeclinedLine =
    '[ECG:NotShared,The athlete chose not to share the ECG details; '
    'say nothing about the ECG content]';

/// The analysis could not be loaded.
const ecgFailedLine =
    '[ECG:NotLoaded,The app could not analyse this ECG just now; say so and '
    'say nothing about its content]';

/// The analysis lines the chat about one recording gets, exactly as the
/// ECG sheet builds them: the short form up to 10 minutes, the timeline
/// beyond.
List<String> ecgAnalysisLines(EcgRecording r, EcgAnalysis analysis) =>
    r.durationMs > 600000
    ? analysis.contextLinesWithTimeline(
        device: r.deviceName,
        source: r.source,
        recordedAt: r.recordedAt,
        linkedToWorkout: r.activityId != null,
      )
    : analysis.contextLines(
        device: r.deviceName,
        source: r.source,
        recordedAt: r.recordedAt,
        linkedToWorkout: r.activityId != null,
      );

/// Stage 2: the full analysis of [r], the same lines the ECG sheet's "ask
/// the coach" gives. A period in the question ([minutes], counted from the
/// start of [activity] when there is one, else of the recording) adds where
/// it lies in the recording; nothing is left out.
List<String> ecgDetailLines(
  EcgRecording r,
  EcgAnalysis? analysis, {
  ({int from, int to})? minutes,
  ActivityRecord? activity,
}) {
  if (analysis == null) {
    return [
      ecgAvailableLine(r),
      '[ECG:Summary,Kind:${r.kind},No waveform the app could analyse: '
          'nothing about rhythm or beats is known from it]',
    ];
  }
  final lines = ecgAnalysisLines(r, analysis);
  if (minutes == null) return lines;
  final offset = activity == null
      ? 0
      : r.recordedAt.difference(activity.startDate).inSeconds;
  final from = minutes.from * 60 - offset, to = minutes.to * 60 - offset;
  final asked = activity == null
      ? 'recording minute ${minutes.from}–${minutes.to}'
      : 'workout minute ${minutes.from}–${minutes.to}';
  final duration = analysis.durationSeconds.round();
  final start = activity == null
      ? ''
      : ', starting ${offset}s into the workout';
  return [
    ...lines,
    to <= 0 || from >= duration
        ? '[ECG:Focus,Asked:$asked,Outside the recording (ECG covers 0–${duration}s$start)]'
        : '[ECG:Focus,Asked:$asked,ECG:${from.clamp(0, duration)}–${to.clamp(0, duration)}s$start]',
  ];
}
