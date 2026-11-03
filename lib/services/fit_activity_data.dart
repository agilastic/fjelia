import 'dart:typed_data';

import 'package:fit_sdk/fit_sdk.dart';

/// Source-reported totals and timed records from an activity FIT export.
/// Timer time, elapsed time and moving time are deliberately kept separate.
class FitActivityData {
  const FitActivityData({
    this.sport,
    this.start,
    this.timerSeconds,
    this.movingSeconds,
    this.distanceMeters,
    this.ascentMeters,
    this.avgPower,
    this.avgHeartRate,
    this.maxHeartRate,
    this.samples = const [],
    this.route = const [],
    this.rrIntervals = const [],
  });

  final DateTime? start;
  final String? sport;
  final double? timerSeconds, movingSeconds, distanceMeters, ascentMeters;
  final double? avgPower;
  final double? avgHeartRate, maxHeartRate;
  final List<Map<String, num>> samples;
  final List<Map<String, double>> route;

  /// Beat-to-beat intervals in ms, in recording order, from HRV messages
  /// (Garmin "Log HRV" or a Polar watch with a paired chest strap). Missing
  /// beats are left out.
  final List<double> rrIntervals;
}

/// Reads normal FIT files, including their CRC. An unavailable or damaged
/// optional export must not prevent the exercise summary from being imported.
FitActivityData? parseFitActivity(Uint8List bytes) {
  if (bytes.length < 14 ||
      (bytes[0] != 12 && bytes[0] != 14) ||
      String.fromCharCodes(bytes.sublist(8, 12)) != '.FIT') {
    return null;
  }
  final size = ByteData.sublistView(bytes).getUint32(4, Endian.little);
  if (bytes.length != bytes[0] + size + 2) return null;
  final sessions = <SessionMesg>[];
  final samples = <Map<String, num>>[];
  final route = <Map<String, double>>[];
  final rr = <double>[];
  final decoder = Decode();
  decoder.onMesg = (message) {
    if (message.num == MesgNum.hrv) {
      // Up to five intervals per message, in seconds; 0xFFFF marks none.
      for (var i = 0; i < message.getNumFieldValues(HrvMesg.fieldTime); i++) {
        final value = message.getFieldValue(HrvMesg.fieldTime, index: i);
        if (value is num && value.isFinite && value > 0 && value < 65) {
          rr.add(value * 1000);
        }
      }
    } else if (message.num == MesgNum.session) {
      sessions.add(SessionMesg.fromMesg(message));
    } else if (message.num == MesgNum.record) {
      final record = RecordMesg.fromMesg(message);
      final time = record.getTimestamp();
      final distance = _nonnegative(record.getDistance());
      final speed = _nonnegative(
        record.getEnhancedSpeed() ?? record.getSpeed(),
      );
      final elevation = record.getEnhancedAltitude() ?? record.getAltitude();
      final hr = record.getHeartRate();
      final power = record.getPower();
      if (time != null) {
        samples.add({
          't': time.millisecondsSinceEpoch,
          'd': ?distance,
          'spd': ?speed,
          if (elevation != null && elevation.isFinite) 'ele': elevation,
          if (hr != null && hr > 0) 'hr': hr,
          if (power != null && power >= 0) 'w': power,
        });
      }
      final rawLat = record.getPositionLat(), rawLng = record.getPositionLong();
      if (rawLat != null && rawLng != null) {
        final lat = rawLat * 180 / 2147483648;
        final lng = rawLng * 180 / 2147483648;
        if (lat.abs() <= 90 && lng.abs() <= 180) {
          route.add({'lat': lat, 'lng': lng});
        }
      }
    }
  };
  try {
    decoder.read(bytes);
    if (sessions.isEmpty && samples.isEmpty && route.isEmpty) return null;
    // Multisport totals are usable only when every leg supplies the field.
    double? total(double? Function(SessionMesg) read) {
      if (sessions.isEmpty) return null;
      var sum = 0.0;
      for (final session in sessions) {
        final value = _nonnegative(read(session));
        if (value == null) return null;
        sum += value;
      }
      return sum;
    }

    // Heart rate from the session totals, else from the recorded samples.
    var hrSum = 0.0, hrTime = 0.0, maxHr = 0.0;
    for (final session in sessions) {
      final avg = session.getAvgHeartRate();
      final time = _nonnegative(session.getTotalTimerTime());
      if (avg != null && avg > 0 && time != null && time > 0) {
        hrSum += avg * time;
        hrTime += time;
      }
      final max = session.getMaxHeartRate();
      if (max != null && max > maxHr) maxHr = max.toDouble();
    }
    final hrSamples = [
      for (final sample in samples)
        if (sample['hr'] != null) sample['hr']!.toDouble(),
    ];
    if (hrTime <= 0 && hrSamples.isNotEmpty) {
      hrSum = hrSamples.reduce((a, b) => a + b);
      hrTime = hrSamples.length.toDouble();
    }
    for (final hr in hrSamples) {
      if (hr > maxHr) maxHr = hr;
    }

    var powerSum = 0.0, powerTime = 0.0;
    var completePower = sessions.isNotEmpty;
    for (final session in sessions) {
      final power = session.getAvgPower();
      final time = _nonnegative(session.getTotalTimerTime());
      if (power == null || power < 0 || time == null || time <= 0) {
        completePower = false;
      } else {
        powerSum += power * time;
        powerTime += time;
      }
    }
    final starts =
        sessions.map((s) => s.getStartTime()).whereType<DateTime>().toList()
          ..sort();
    final sports = sessions.map((s) => s.getSport()).whereType<int>().toSet();
    final subSports = sessions
        .map((s) => s.getSubSport())
        .whereType<int>()
        .toSet();
    return FitActivityData(
      sport: sports.length == 1
          ? switch (sports.single) {
              Sport.running => 'running',
              Sport.cycling || Sport.eBiking => 'cycling',
              Sport.swimming => 'swimming',
              Sport.walking => 'walking',
              Sport.hiking => 'hiking',
              Sport.rowing => 'rowing',
              // "Training" covers strength, yoga, cardio and more; only the
              // sub sport says which.
              Sport.training => switch (subSports.length == 1
                  ? subSports.single
                  : null) {
                SubSport.strengthTraining => 'strength',
                SubSport.yoga => 'yoga',
                _ => null,
              },
              Sport.crossCountrySkiing || Sport.alpineSkiing => 'skiing',
              _ => null,
            }
          : null,
      start: starts.firstOrNull?.toUtc(),
      timerSeconds: total((s) => s.getTotalTimerTime()),
      movingSeconds: total((s) => s.getTotalMovingTime()),
      distanceMeters: total((s) => s.getTotalDistance()),
      ascentMeters: total((s) => s.getTotalAscent()?.toDouble()),
      avgPower: completePower && powerTime > 0 ? powerSum / powerTime : null,
      avgHeartRate: hrTime > 0 ? hrSum / hrTime : null,
      maxHeartRate: maxHr > 0 ? maxHr : null,
      samples: samples,
      route: route,
      rrIntervals: rr,
    );
  } catch (_) {
    return null;
  }
}

double? _nonnegative(num? value) =>
    value != null && value.isFinite && value >= 0 ? value.toDouble() : null;
