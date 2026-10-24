/// Parses a number typed with either a decimal comma (21,1) or a decimal
/// point (21.1). When both appear, the one that comes last is the decimal
/// separator and the other one is a thousands separator ("1.234,5").
double? parseDecimal(String? input) {
  // Keyboards and pasted text bring their own spaces and separators: no-break
  // and thin spaces, the Arabic decimal separator, full-width comma and point.
  var s =
      input
          ?.trim()
          .replaceAll(RegExp('[\\s\u00A0\u2009\u202F]'), '')
          .replaceAll('\u066B', ',')
          .replaceAll('\uFF0C', ',')
          .replaceAll('\uFF0E', '.') ??
      '';
  if (s.isEmpty) return null;
  final comma = s.lastIndexOf(','), point = s.lastIndexOf('.');
  if (comma >= 0 && point >= 0) {
    s = comma > point
        ? s.replaceAll('.', '').replaceAll(',', '.')
        : s.replaceAll(',', '');
  } else if (comma >= 0) {
    s = s.replaceAll(',', '.');
  }
  return double.tryParse(s);
}
