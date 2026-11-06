import 'dart:typed_data';

enum FtmsMachine {
  treadmill('2acd', 'treadmill_running', 'Treadmill'),
  crossTrainer('2ace', 'elliptical', 'Elliptical'),
  stepClimber('2acf', 'stair_climbing', 'Step climber'),
  stairClimber('2ad0', 'stair_climbing', 'Stair climber'),
  rower('2ad1', 'rowing', 'Rower'),
  bike('2ad2', 'indoor_cycling', 'Indoor bike');

  const FtmsMachine(this.characteristic, this.activityType, this.label);
  final String characteristic, activityType, label;
}

enum FtmsCompatibility { standard, matrix }

/// Johnson also manufactures other brands (including BowFlex). Its company
/// identifier alone must never select a Matrix packet layout.
FtmsCompatibility ftmsCompatibilityForName(String name) =>
    RegExp(
      r'^(?:matrix|ctm(?:[ _-]|[0-9]|$)|t(?:7xi|5x)(?:[ _-]|[0-9]|$))',
      caseSensitive: false,
    ).hasMatch(name.trim())
    ? FtmsCompatibility.matrix
    : FtmsCompatibility.standard;

bool ftmsControlAllowed(FtmsMachine machine, FtmsCompatibility profile) =>
    !(machine == FtmsMachine.treadmill && profile == FtmsCompatibility.matrix);

/// Every notification has its own flags, including when a data record is
/// split over several notifications. Missing/invalid values remain absent.
/// Distances are metres, speed m/s, incline percent, power W, cadence /min.
Map<String, num> decodeFtms(
  FtmsMachine machine,
  List<int> bytes, {
  FtmsCompatibility compatibility = FtmsCompatibility.standard,
}) {
  final r = _FtmsReader(bytes);
  final flags = r.raw(machine == FtmsMachine.crossTrainer ? 3 : 2);
  bool has(int bit) => flags & (1 << bit) != 0;
  final out = <String, num>{};
  void value(
    String key,
    int size, {
    bool signed = false,
    double scale = 1,
    bool positive = false,
  }) {
    final v = r.number(size, signed: signed);
    if (v != null && (!positive || v > 0)) out[key] = v * scale;
  }

  void speed(String key) => value(key, 2, scale: 1 / 360);
  void distance() => value('machine_distance', 3);
  void energy() {
    value('machine_kcal', 2);
    value('kcal_hour', 2);
    value('kcal_minute', 1);
  }

  void hr() => value('hr', 1, positive: true);
  void metabolic() => value('met', 1, scale: .1);
  void elapsed() => value('machine_elapsed', 2);
  void remaining() => value('remaining', 2);
  void elevation({double scale = .1, bool descending = true}) {
    value('machine_ascent', 2, scale: scale);
    if (descending) value('machine_descent', 2, scale: scale);
  }

  void incline() {
    value('incline', 2, signed: true, scale: .1);
    value('ramp_angle', 2, signed: true, scale: .1);
  }

  // Exact legacy Matrix signatures from TMIW issue #223. These packets
  // advertise fields that are absent on the wire. Never apply this fallback
  // to a merely truncated standard packet or to another Johnson brand.
  if (compatibility == FtmsCompatibility.matrix && bytes.length == 20) {
    if (machine == FtmsMachine.treadmill && {0x1b9e, 0x1f9e}.contains(flags)) {
      speed('spd');
      speed('avg_spd');
      distance();
      incline();
      elevation();
      value('machine_kcal', 2);
      // The last byte has no confirmed interpretation. Preserve it without
      // inventing a heart rate, power, elapsed time or energy-rate reading.
      value('matrix_tail_raw', 1);
      return out;
    }
    if (machine == FtmsMachine.bike && {0x15fe, 0x1dfe}.contains(flags)) {
      speed('spd');
      speed('avg_spd');
      value('cad', 2, scale: .5);
      value('avg_cad', 2, scale: .5);
      distance();
      value('resistance', 2, signed: true);
      value('w', 2, signed: true);
      value('avg_w', 2, signed: true);
      value('matrix_tail_raw', 1);
      return out;
    }
  }

  switch (machine) {
    case FtmsMachine.bike:
      if (!has(0)) speed('spd');
      if (has(1)) speed('avg_spd');
      if (has(2)) value('cad', 2, scale: .5);
      if (has(3)) value('avg_cad', 2, scale: .5);
      if (has(4)) distance();
      if (has(5)) value('resistance', 2, signed: true);
      if (has(6)) value('w', 2, signed: true);
      if (has(7)) value('avg_w', 2, signed: true);
      if (has(8)) energy();
      if (has(9)) hr();
      if (has(10)) metabolic();
      if (has(11)) elapsed();
      if (has(12)) remaining();
    case FtmsMachine.treadmill:
      if (!has(0)) speed('spd');
      if (has(1)) speed('avg_spd');
      if (has(2)) distance();
      if (has(3)) incline();
      if (has(4)) elevation();
      if (has(5)) value('pace_km_min', 1, scale: .1);
      if (has(6)) value('avg_pace_km_min', 1, scale: .1);
      if (has(7)) energy();
      if (has(8)) hr();
      if (has(9)) metabolic();
      if (has(10)) elapsed();
      if (has(11)) remaining();
      if (has(12)) {
        value('force_n', 2, signed: true);
        value('w', 2, signed: true);
      }
      if (!out.containsKey('spd') && out['pace_km_min'] != null) {
        out['spd'] = out['pace_km_min']! * 1000 / 60;
      }
    case FtmsMachine.rower:
      if (!has(0)) {
        value('cad', 1, scale: .5);
        value('machine_strokes', 2);
      }
      if (has(1)) value('avg_cad', 1, scale: .5);
      if (has(2)) distance();
      if (has(3)) value('pace_500m', 2, positive: true);
      if (has(4)) value('avg_pace_500m', 2);
      if (has(5)) value('w', 2, signed: true);
      if (has(6)) value('avg_w', 2, signed: true);
      if (has(7)) value('resistance', 2, signed: true);
      if (has(8)) energy();
      if (has(9)) hr();
      if (has(10)) metabolic();
      if (has(11)) elapsed();
      if (has(12)) remaining();
      if (out['pace_500m'] != null) out['spd'] = 500 / out['pace_500m']!;
    case FtmsMachine.crossTrainer:
      if (!has(0)) speed('spd');
      if (has(1)) speed('avg_spd');
      if (has(2)) distance();
      if (has(3)) {
        value('cad', 2);
        value('avg_cad', 2);
      }
      if (has(4)) value('machine_strides', 2, scale: .1);
      if (has(5)) elevation();
      if (has(6)) incline();
      if (has(7)) value('resistance', 2, signed: true, scale: .1);
      if (has(8)) value('w', 2, signed: true);
      if (has(9)) value('avg_w', 2, signed: true);
      if (has(10)) energy();
      if (has(11)) hr();
      if (has(12)) metabolic();
      if (has(13)) elapsed();
      if (has(14)) remaining();
      out['backward'] = has(15) ? 1 : 0;
    case FtmsMachine.stepClimber:
    case FtmsMachine.stairClimber:
      final step = machine == FtmsMachine.stepClimber;
      if (!has(0)) {
        value('machine_floors', 2);
        if (step) value('machine_steps', 2);
      }
      if (has(1)) value('cad', 2);
      if (has(2)) value('avg_cad', 2);
      if (has(3)) elevation(scale: 1, descending: false);
      if (!step && has(4)) value('machine_strides', 2);
      final energyBit = step ? 4 : 5;
      if (has(energyBit)) energy();
      if (has(energyBit + 1)) hr();
      if (has(energyBit + 2)) metabolic();
      if (has(energyBit + 3)) elapsed();
      if (has(energyBit + 4)) remaining();
  }
  return out;
}

class _FtmsReader {
  _FtmsReader(List<int> bytes) : bytes = Uint8List.fromList(bytes);
  final Uint8List bytes;
  int offset = 0;
  int raw(int size) {
    if (offset + size > bytes.length) {
      throw const FormatException('Truncated FTMS measurement.');
    }
    var n = 0;
    for (var i = 0; i < size; i++) {
      n |= bytes[offset++] << (8 * i);
    }
    return n;
  }

  int? number(int size, {bool signed = false}) {
    final n = raw(size), bits = size * 8;
    if (n == (signed ? (1 << (bits - 1)) - 1 : (1 << bits) - 1)) return null;
    return signed && n & (1 << (bits - 1)) != 0 ? n - (1 << bits) : n;
  }
}

enum FtmsTarget {
  speed(0, '2ad4', 2, 100, false, 'km/h'),
  incline(1, '2ad5', 3, 10, true, '%'),
  resistance(2, '2ad6', 4, 10, true, ''),
  power(3, '2ad8', 5, 1, true, 'W');

  const FtmsTarget(
    this.featureBit,
    this.rangeUuid,
    this.opcode,
    this.scale,
    this.signed,
    this.unit,
  );
  final int featureBit, opcode, scale;
  final String rangeUuid, unit;
  final bool signed;
}

class FtmsRange {
  const FtmsRange(this.min, this.max, this.increment);
  final double min, max, increment;
  factory FtmsRange.decode(FtmsTarget target, List<int> bytes) {
    if (bytes.length != 6) {
      throw const FormatException('Invalid FTMS control range.');
    }
    final r = _FtmsReader(bytes);
    final min = r.number(2, signed: target.signed),
        max = r.number(2, signed: target.signed);
    final step = r.number(2);
    if (min == null || max == null || step == null || step <= 0 || min > max) {
      throw const FormatException('Invalid FTMS control limits.');
    }
    return FtmsRange(
      min / target.scale,
      max / target.scale,
      step / target.scale,
    );
  }
  bool accepts(double value) =>
      value.isFinite &&
      value >= min &&
      value <= max &&
      ((value - min) / increment - ((value - min) / increment).round()).abs() <
          .0001;
}

List<int> ftmsTargetCommand(FtmsTarget target, FtmsRange range, double value) {
  if (!range.accepts(value)) {
    throw ArgumentError(
      'Target must be inside the supported range and increment.',
    );
  }
  final wire = (value * target.scale).round();
  if (wire < (target.signed ? -32768 : 0) ||
      wire > (target.signed ? 32766 : 65534)) {
    throw ArgumentError('Target cannot be represented by the machine.');
  }
  return [target.opcode, wire & 255, (wire >> 8) & 255];
}
