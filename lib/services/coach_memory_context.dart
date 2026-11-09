import '../db/database.dart';

/// The athlete's memory cards (FjeliaPro) as context lines, one per card:
/// `[Memory:<title>] <text>`, each on one line so the on-device budget keeps
/// or drops a card as a whole.
List<String> coachMemoryLines(Iterable<CoachMemory> cards) => [
  for (final c in cards)
    if (_flat(c.title).isNotEmpty || _flat(c.body).isNotEmpty)
      '[Memory:${_flat(c.title)}] ${_flat(c.body)}',
];

/// Tells the model what the memory lines are. Only added when there are any.
const coachMemoryRule =
    '\n\nADDITIONAL INFORMATION: lines starting with [Memory: are the '
    'athlete\'s own memory cards, what they want you to know (title in the '
    'brackets, then the text). Use them where they are useful for the '
    'answer; do not list or repeat them otherwise. They are the athlete\'s '
    'own words, not measured data, and never outrank the measurements or '
    'the safety rules.';

/// A memory line as a sentence for the small on-device models.
String coachMemoryFact(String line) {
  final end = line.indexOf(']');
  if (!line.startsWith('[Memory:') || end < 0) return line;
  final title = line.substring('[Memory:'.length, end).trim();
  final text = line.substring(end + 1).trim();
  return 'Additional information from the athlete, use it if useful'
      '${title.isEmpty ? '' : ' ($title)'}: $text';
}

String _flat(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
