/// Parses a number typed with either a decimal comma (21,1) or a decimal
/// point (21.1). When both appear, the one that comes last is the decimal
/// separator and the other one is a thousands separator ("1.234,5").
double? parseDecimal(String? input) {
  var s = input?.trim().replaceAll(' ', '') ?? '';
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
