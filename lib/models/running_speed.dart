import 'dart:typed_data';

/// Bluetooth Running Speed and Cadence Measurement (0x2a53). This is a
/// read-only measurement service; it never authorizes equipment commands.
Map<String, num> decodeRunningSpeed(List<int> bytes) {
  if (bytes.length < 4 || bytes.any((b) => b < 0 || b > 255)) {
    throw const FormatException('Invalid running speed measurement.');
  }
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  final flags = bytes[0];
  final required = 4 + ((flags & 1 != 0) ? 2 : 0) + ((flags & 2 != 0) ? 4 : 0);
  if (bytes.length < required) {
    throw const FormatException('Truncated running speed measurement.');
  }
  final result = <String, num>{
    'spd': data.getUint16(1, Endian.little) / 256,
    'cad': bytes[3],
    'running': (flags & 4) != 0 ? 1 : 0,
  };
  var offset = 4;
  if (flags & 1 != 0) {
    result['stride_length'] = data.getUint16(offset, Endian.little) / 100;
    offset += 2;
  }
  if (flags & 2 != 0) {
    result['machine_distance'] = data.getUint32(offset, Endian.little) / 10;
  }
  return result;
}
