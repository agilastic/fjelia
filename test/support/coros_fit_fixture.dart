import 'dart:typed_data';

/// A walk recorded like a COROS watch writes it: one full record, then
/// records with compressed-timestamp headers on local message 3 (header
/// 0xE0 | offset, which also has the "definition" bit set). Halfway an event
/// message declares its `data` field as a uint32 of one byte, as in a real
/// COROS export.
Uint8List corosStyleFit({int seconds = 120}) {
  List<int> little(int value, int size) => [
    for (var i = 0; i < size; i++) (value >> (8 * i)) & 255,
  ];
  int size(int type) => type == 0x00 || type == 0x02
      ? 1
      : type == 0x84
      ? 2
      : 4;
  final payload = <int>[];
  void define(
    int local,
    int global,
    List<(int, int)> fields, {
    Map<int, int> sizes = const {},
  }) => payload.addAll([
    0x40 | local,
    0,
    0,
    ...little(global, 2),
    fields.length,
    for (final f in fields) ...[f.$1, sizes[f.$1] ?? size(f.$2), f.$2],
  ]);
  void data(int header, List<(int, int)> values) =>
      payload.addAll([header, for (final v in values) ...little(v.$1, v.$2)]);

  final start =
      DateTime.utc(2026, 11, 3, 17, 44).millisecondsSinceEpoch ~/ 1000 -
      631065600;
  int lat(int i) => ((52.30 + i * .0001) * 2147483648 / 180).round();
  final lng = (9.80 * 2147483648 / 180).round();
  // Session: start, sport walking (11), timer and moving time.
  define(0, 18, [(2, 0x86), (5, 0x02), (8, 0x86), (59, 0x86)]);
  data(0, [
    (start, 4),
    (11, 1),
    (seconds * 1000, 4),
    ((seconds - 10) * 1000, 4),
  ]);
  // The first record with its own timestamp.
  define(1, 20, [(253, 0x86), (0, 0x85), (1, 0x85), (3, 0x02), (6, 0x84)]);
  data(1, [(start, 4), (lat(0), 4), (lng, 4), (90, 1), (1400, 2)]);
  // The rest without: the time comes from the header.
  define(3, 20, [(0, 0x85), (1, 0x85), (3, 0x02), (6, 0x84)]);
  for (var i = 1; i <= seconds; i++) {
    if (i == seconds ~/ 2) {
      // Timer stop: event 0, type 4, data a "uint32" of one byte.
      define(
        2,
        21,
        [(253, 0x86), (0, 0x00), (4, 0x02), (3, 0x86)],
        sizes: {3: 1},
      );
      data(2, [(start + i, 4), (0, 1), (4, 1), (0, 1)]);
    }
    data(0xE0 | ((start + i) & 0x1F), [
      (lat(i), 4),
      (lng, 4),
      (90 + i % 10, 1),
      (1400, 2),
    ]);
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
