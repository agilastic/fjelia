import 'dart:typed_data';

import 'package:fit_sdk/fit_sdk.dart';

/// The FIT record loop of fit_sdk's `Decode` (MIT), with the header bits
/// checked in the order the FIT protocol gives.
///
/// fit_sdk 0.3.0 asks "definition?" (bit 6) before "compressed timestamp?"
/// (bit 7). A compressed-timestamp header of local message 2 or 3 also has
/// bit 6 set, so it is read as a definition, the rest of the file is
/// misread and the decoder stops early. It also looks the timestamp up by a
/// name the profile spells differently, so compressed records lost their
/// time. And a field declared smaller than its type is not read at all,
/// which shifts every later message. COROS files hit that one: their
/// activities came in as the first 40 seconds of route and heart rate.
class FitDecode {
  /// Field 253 is the timestamp in every message.
  static const _timestampField = 253;

  final _definitions = <int, MesgDefinition>{};
  final _accumulator = Accumulator();
  final _lookup = DeveloperDataLookup();
  var _timestamp = 0;
  var _lastTimeOffset = 0;

  void Function(Mesg)? onMesg;

  void read(Uint8List data) {
    final reader = EndianBinaryReader(data);
    Header().read(reader);
    final crc = data[data.length - 2] | (data[data.length - 1] << 8);
    if (Crc.calc16(data, data.length - 2) != crc) {
      throw FitException('FIT decode error: File CRC mismatch');
    }
    while (reader.position < reader.length - 2) {
      final header = reader.readByte();
      if ((header & Fit.compressedHeaderMask) != 0) {
        // Compressed timestamp: bit 7, local message in bits 5–6, a time
        // offset in bits 0–4. Checked first: bit 6 here is no definition.
        final offset = header & Fit.compressedTimeMask;
        _timestamp += (offset - _lastTimeOffset) & Fit.compressedTimeMask;
        _lastTimeOffset = offset;
        final definition =
            _definitions[(header & Fit.compressedLocalMesgNumMask) >> 5];
        if (definition == null) break;
        final mesg = Mesg.fromDefinition(definition)..read(reader, definition);
        // By number: fit_sdk asks for 'timestamp' by name, the profile
        // calls it 'Timestamp', and the time was silently dropped.
        final timestamp = Profile.getMesg(MesgNum.record)
            .getField(_timestampField);
        if (timestamp != null) {
          mesg.insertField(0, Field.fromOther(timestamp)..setValue(_timestamp));
        }
        _deliver(mesg);
      } else if ((header & Fit.mesgDefinitionMask) != 0) {
        reader.position--;
        final definition = MesgDefinition()..read(reader, lookup: _lookup);
        _fixFieldSizes(definition);
        _definitions[definition.localMesgNum] = definition;
      } else {
        final definition = _definitions[header & Fit.localMesgNumMask];
        if (definition == null) break;
        final mesg = Mesg.fromDefinition(definition)..read(reader, definition);
        final value = mesg.getField(_timestampField)?.value;
        if (value is int) {
          _timestamp = value;
          _lastTimeOffset = _timestamp & Fit.compressedTimeMask;
        }
        _accumulate(mesg);
        _deliver(mesg);
      }
    }
  }

  /// A field whose size is no whole number of its type (a 1-byte "uint32"
  /// in COROS event messages) is read as plain bytes, as the FIT SDK does.
  /// fit_sdk reads none of it, and every later message is off by the rest.
  static void _fixFieldSizes(MesgDefinition definition) {
    for (final field in definition.getFields()) {
      final size = Fit.baseType[field.type & Fit.baseTypeNumMask].size;
      if (size > 0 && field.size % size != 0) field.type = Fit.byte;
    }
  }

  void _accumulate(Mesg mesg) {
    for (final field in mesg.fields) {
      if (!field.isAccumulated) continue;
      for (var i = 0; i < field.getNumValues(); i++) {
        final raw = field.values[i];
        if (raw is! num) continue;
        var value = raw.toInt();
        for (final other in mesg.fields) {
          for (final c in other.components) {
            if (c.fieldNum == field.num && c.accumulate) {
              value =
                  ((((value / field.scale) - field.offset) + c.offset) *
                          c.scale)
                      .round();
            }
          }
        }
        _accumulator.set(mesg.num, field.num, value);
      }
    }
  }

  void _deliver(Mesg mesg) {
    mesg.expandComponents(_accumulator);
    if (mesg.num == MesgNum.developerDataId) {
      _lookup.addIdMesg(DeveloperDataIdMesg.fromMesg(mesg));
    } else if (mesg.num == MesgNum.fieldDescription) {
      _lookup.addDescriptionMesg(FieldDescriptionMesg.fromMesg(mesg));
    }
    onMesg?.call(mesg);
  }
}
