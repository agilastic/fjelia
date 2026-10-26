import 'dart:typed_data';

/// A minimal activity encoded independently of the FIT decoding package.
/// Values below are raw FIT units (time ms, distance cm, altitude 1/5 m + 500).
Uint8List polarFitFixture({
  double? movingSeconds = 3600,
  int? ascent = 20,
  bool records = true,
}) {
  List<int> little(int value, int size) => [
    for (var i = 0; i < size; i++) (value >> (8 * i)) & 255,
  ];
  final payload = <int>[];
  void message(int local, int global, List<(int, int, int)> fields) {
    int size(int type) => type == 0x02
        ? 1
        : type == 0x84
        ? 2
        : 4;
    payload.addAll([
      0x40 | local,
      0,
      0,
      ...little(global, 2),
      fields.length,
      for (final f in fields) ...[f.$1, size(f.$2), f.$2],
      local,
      for (final f in fields) ...little(f.$3, size(f.$2)),
    ]);
  }

  final start =
      DateTime.utc(2026, 10, 25, 14, 28).millisecondsSinceEpoch ~/ 1000 -
      631065600;
  message(0, 18, [
    (2, 0x86, start),
    (7, 0x86, 3700000),
    (8, 0x86, 3645000),
    (9, 0x86, 953000),
    (20, 0x84, 289),
    if (ascent != null) (22, 0x84, ascent),
    if (movingSeconds != null) (59, 0x86, (movingSeconds * 1000).round()),
  ]);
  if (records) {
    for (var i = 0; i < 3; i++) {
      message(1, 20, [
        (253, 0x86, start + i * 5),
        (0, 0x85, (52.1 * 2147483648 / 180).round()),
        (1, 0x85, (9.7 * 2147483648 / 180).round()),
        (2, 0x84, (([50, 52, 51][i] + 500) * 5)),
        (3, 0x02, [120, 132, 152][i]),
        (5, 0x86, i * 1250),
        (6, 0x84, 2500),
        (7, 0x84, [275, 289, 300][i]),
      ]);
    }
  }
  final bytes = [
    12,
    0x20,
    ...little(2188, 2),
    ...little(payload.length, 4),
    ...'.FIT'.codeUnits,
    ...payload,
  ];
  var crc = 0;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xA001 : crc >> 1;
    }
  }
  return Uint8List.fromList([...bytes, ...little(crc, 2)]);
}
