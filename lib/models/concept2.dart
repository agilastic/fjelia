import 'ftms.dart';

/// Concept2 PM5 over its own Bluetooth Smart profile ("Concept2 PM CSAFE
/// Communication Definition", rev. 0.31, Smart Bluetooth attribute table).
/// Every PM5 firmware with Bluetooth has it, whether or not it also offers
/// FTMS, so Fjelia reads a PM5 this way.
const concept2Base = '-43e5-11e4-916c-0800200c9a66';

String concept2Uuid(int id) =>
    'ce06${id.toRadixString(16).padLeft(4, '0')}$concept2Base';

/// What the PM5 advertises, for scanning.
final concept2DiscoveryService = concept2Uuid(0x0000);
final concept2InfoService = concept2Uuid(0x0010);
final concept2RowingService = concept2Uuid(0x0030);

/// The connected erg (0x0016, only on firmware V150 and later).
final concept2MachineTypeCharacteristic = concept2Uuid(0x0016);

/// How often general and additional status are sent (0x0034).
final concept2SampleRateCharacteristic = concept2Uuid(0x0034);

/// The live characteristics Fjelia subscribes to.
const concept2LiveIds = [0x31, 0x32, 0x33, 0x35, 0x36, 0x39];

/// Carries every live record whose own characteristic is not subscribed.
const concept2MultiplexedId = 0x80;

/// The erg behind the PM5: a BikeErg records as a bike; a RowErg, a SkiErg
/// and unknown types as a rower, the PM5's usual erg.
FtmsMachine concept2Machine(int? ergType) => switch (ergType) {
  final t? when t >= 192 && t <= 207 => FtmsMachine.bike,
  final t? when t == 226 => FtmsMachine.bike,
  _ => FtmsMachine.rower,
};

const _newtonPerPound = 4.4482216152605;

/// One PM5 record in the keys of the FTMS decoder, so recording, the rowing
/// display and the FIT export need nothing new. Values only the PM5 has are
/// kept as `c2_*`. Multi-byte values are little-endian. Missing or invalid
/// values stay absent.
Map<String, num> decodeConcept2(int id, List<int> bytes) {
  int? u(int at, int size) {
    if (bytes.length < at + size) return null;
    var v = 0;
    for (var i = size - 1; i >= 0; i--) {
      v = (v << 8) | bytes[at + i];
    }
    return v;
  }

  final out = <String, num>{};
  void put(String key, num? v, [double scale = 1]) {
    if (v != null) out[key] = v * scale;
  }

  switch (id) {
    case 0x31: // general status, 19 bytes
      if (bytes.length < 19) throw const FormatException('PM5 status');
      put('machine_elapsed', u(0, 3), .01);
      put('machine_distance', u(3, 3), .1);
      put('c2_workout_type', u(6, 1));
      put('c2_interval_type', u(7, 1));
      put('c2_workout_state', u(8, 1));
      put('c2_rowing_state', u(9, 1));
      put('c2_stroke_state', u(10, 1));
      final drag = u(18, 1);
      if (drag != null && drag > 0) out['c2_drag_factor'] = drag;
    case 0x32: // additional status 1, 16 or 17 bytes
      if (bytes.length < 16) throw const FormatException('PM5 status 1');
      put('machine_elapsed', u(0, 3), .01);
      final speed = u(3, 2);
      if (speed != null && speed > 0) out['spd'] = speed / 1000;
      put('cad', u(5, 1));
      final hr = u(6, 1);
      if (hr != null && hr > 0 && hr != 255) out['hr'] = hr;
      final pace = u(7, 2);
      if (pace != null && pace > 0) out['pace_500m'] = pace / 100;
      final average = u(9, 2);
      if (average != null && average > 0) out['avg_pace_500m'] = average / 100;
      put('c2_rest_distance', u(11, 2));
      put('c2_rest_time', u(13, 3), .01);
      // The erg type byte came with later firmware.
      put('c2_erg_type', u(16, 1));
    case 0x33: // additional status 2, 20 bytes
      if (bytes.length < 20) throw const FormatException('PM5 status 2');
      put('machine_elapsed', u(0, 3), .01);
      put('c2_interval_count', u(3, 1));
      put('avg_w', u(4, 2));
      put('machine_kcal', u(6, 2));
      final split = u(8, 2);
      if (split != null && split > 0) out['c2_split_pace_500m'] = split / 100;
      put('c2_split_w', u(10, 2));
      put('c2_last_split_time', u(14, 3), .1);
      put('c2_last_split_distance', u(17, 3));
    case 0x35: // stroke data, 20 bytes
      if (bytes.length < 20) throw const FormatException('PM5 stroke');
      put('machine_elapsed', u(0, 3), .01);
      put('machine_distance', u(3, 3), .1);
      put('c2_drive_length', u(6, 1), .01);
      put('c2_drive_time', u(7, 1), .01);
      put('c2_recovery_time', u(8, 2), .01);
      put('c2_stroke_distance', u(10, 2), .01);
      put('c2_peak_force_n', u(12, 2), .1 * _newtonPerPound);
      put('c2_avg_force_n', u(14, 2), .1 * _newtonPerPound);
      put('c2_work_j', u(16, 2), .1);
      put('machine_strokes', u(18, 2));
    case 0x36: // additional stroke data, 15 or 18 bytes
      if (bytes.length < 7) throw const FormatException('PM5 stroke 2');
      put('machine_elapsed', u(0, 3), .01);
      put('w', u(3, 2));
      put('c2_stroke_kcal_hour', u(5, 2));
      put('machine_strokes', u(7, 2));
    case 0x39: // end of workout summary, 20 bytes
      if (bytes.length < 20) throw const FormatException('PM5 summary');
      put('c2_summary_time', u(4, 3), .01);
      put('c2_summary_distance', u(7, 3), .1);
      put('c2_summary_cad', u(10, 1));
      final drag = u(15, 1);
      if (drag != null && drag > 0) out['c2_summary_drag_factor'] = drag;
      final pace = u(18, 2);
      if (pace != null && pace > 0) out['c2_summary_pace_500m'] = pace / 10;
    case concept2MultiplexedId:
      // An identifier byte, then the record as on its own characteristic.
      if (bytes.isEmpty) throw const FormatException('PM5 multiplexed');
      final inner = bytes[0];
      if (inner == concept2MultiplexedId) {
        throw const FormatException('PM5 multiplexed');
      }
      return decodeConcept2(inner, bytes.sublist(1));
  }
  // The PM5 sends speed and pace; FTMS readers expect both.
  if (!out.containsKey('spd') && out['pace_500m'] != null) {
    out['spd'] = 500 / out['pace_500m']!;
  }
  return out;
}
