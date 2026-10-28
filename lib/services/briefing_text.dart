/// A briefing is one plain paragraph. Models still add line breaks, bullets
/// and markdown now and then, so the reply is flattened before it is shown.
String flattenBriefing(String text) {
  var t = text
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'[*`#>]+'), '')
      // List markers and numbering at the start of a line.
      .replaceAll(RegExp(r'^\s*(?:[-•·–]|\d+[.)])\s+', multiLine: true), '')
      .replaceAll(RegExp(r'[\r\n\t\u2028\u2029]+'), ' ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
  // A reply wrapped in quotation marks as a whole.
  if (t.length > 1 &&
      ((t.startsWith('"') && t.endsWith('"')) ||
          (t.startsWith('“') && t.endsWith('”')))) {
    t = t.substring(1, t.length - 1).trim();
  }
  return t;
}
