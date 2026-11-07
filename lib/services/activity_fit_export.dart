import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fit_sdk/fit_sdk.dart' as fit;

import '../db/database.dart' show ActivityRecord;
import '../theme/activity_colors.dart';
import 'activity_decoder.dart';

/// A FIT activity rebuilt from a stored workout of any source: one record
/// per stored sample, the route laid onto them, and the summary as one lap
/// and one session. Fjelia keeps the curves, not the watch's original file,
/// so this is what goes to another platform.
Uint8List activityRecordFit(ActivityRecord row) {
  final a = decodeActivityRecord(row);
  final encoder = fit.Encode()..open();
  String? definition;
  void write(fit.Mesg message) {
    message.localNum = 0;
    final def = fit.MesgDefinition.fromMesg(message);
    final signature =
        '${message.num}:${message.fields.map((f) => '${f.num}:${f.getSize()}').join(',')}';
    if (signature != definition) {
      encoder.writeMesgDefinition(def);
      definition = signature;
    }
    encoder.writeMesg(message, def);
  }

  int stamp(DateTime time) =>
      time.toUtc().millisecondsSinceEpoch ~/ 1000 - 631065600;
  final start = stamp(a.startTime);
  final samples = [
    for (final s in a.samples)
      if (s.timestamp case final t? when !t.isBefore(a.startTime)) (t, s),
  ];
  final end = samples.isEmpty
      ? start + a.duration.inSeconds
      : stamp(samples.last.$1).clamp(start, 1 << 31);
  final (sport, subSport) = switch (activityKind(a.type)) {
    ActivityKind.running => (fit.Sport.running, fit.SubSport.generic),
    ActivityKind.cycling => (
      fit.Sport.cycling,
      row.source == 'mywhoosh'
          ? fit.SubSport.virtualActivity
          : fit.SubSport.generic,
    ),
    ActivityKind.swimming => (fit.Sport.swimming, fit.SubSport.generic),
    ActivityKind.strength => (
      fit.Sport.training,
      fit.SubSport.strengthTraining,
    ),
    ActivityKind.rowing => (fit.Sport.rowing, fit.SubSport.generic),
    ActivityKind.hiking => (fit.Sport.hiking, fit.SubSport.generic),
    ActivityKind.walking => (fit.Sport.walking, fit.SubSport.generic),
    ActivityKind.yoga => (fit.Sport.training, fit.SubSport.yoga),
    ActivityKind.other => (fit.Sport.generic, fit.SubSport.generic),
  };

  write(
    fit.FileIdMesg()
      ..setFieldValue(fit.FileIdMesg.fieldType, fit.File.activity)
      ..setFieldValue(
        fit.FileIdMesg.fieldManufacturer,
        fit.Manufacturer.development,
      )
      ..setFieldValue(fit.FileIdMesg.fieldProduct, 1)
      ..setFieldValue(
        fit.FileIdMesg.fieldSerialNumber,
        int.parse(
          sha256
              .convert(utf8.encode(row.activityId))
              .toString()
              .substring(0, 8),
          radix: 16,
        ),
      )
      ..setFieldValue(fit.FileIdMesg.fieldTimeCreated, start)
      ..setFieldValue(fit.FileIdMesg.fieldProductName, 'Fjelia'),
  );
  void timer(int at, int type) => write(
    fit.EventMesg()
      ..setFieldValue(fit.EventMesg.fieldTimestamp, at)
      ..setFieldValue(fit.EventMesg.fieldEvent, fit.Event.timer)
      ..setFieldValue(fit.EventMesg.fieldEventType, type),
  );
  timer(start, fit.EventType.start);

  // The route is stored apart from the samples; spread it over them.
  final route = a.route;
  for (var i = 0; i < samples.length; i++) {
    final (time, s) = samples[i];
    final record = fit.RecordMesg()
      ..setFieldValue(fit.RecordMesg.fieldTimestamp, stamp(time));
    void field(int number, num? value) {
      if (value != null && value.isFinite) record.setFieldValue(number, value);
    }

    field(fit.RecordMesg.fieldHeartRate, s.heartRate?.round());
    if (s.distanceMeters > 0) {
      field(fit.RecordMesg.fieldDistance, s.distanceMeters);
    }
    field(fit.RecordMesg.fieldEnhancedSpeed, s.speed);
    field(fit.RecordMesg.fieldEnhancedAltitude, s.elevation);
    if ((s.power ?? -1) >= 0) {
      field(fit.RecordMesg.fieldPower, s.power!.round());
    }
    if ((s.cadence ?? 255) < 255) {
      field(fit.RecordMesg.fieldCadence, s.cadence!.floor());
    }
    if (route.isNotEmpty) {
      final p =
          route[samples.length < 2
              ? 0
              : (i * (route.length - 1) / (samples.length - 1)).round()];
      field(
        fit.RecordMesg.fieldPositionLat,
        (p.lat * 2147483648 / 180).round(),
      );
      field(
        fit.RecordMesg.fieldPositionLong,
        (p.lng * 2147483648 / 180).round(),
      );
    }
    write(record);
  }
  timer(end, fit.EventType.stopAll);

  final timerSeconds = (a.movingDuration ?? a.duration).inSeconds.toDouble();
  // The summary as lap and session totals; the field numbers differ.
  void totals(
    fit.Mesg m,
    ({
      int distance,
      int avgHr,
      int maxHr,
      int avgPower,
      int ascent,
      int calories,
    })
    f,
  ) {
    void set(int number, num? value) {
      if (value != null && value.isFinite && value > 0) {
        m.setFieldValue(number, value);
      }
    }

    set(f.distance, row.distanceMeters);
    set(f.avgHr, row.avgHeartRate?.round());
    set(f.maxHr, row.maxHeartRate?.round());
    set(f.avgPower, a.avgPower?.round());
    set(f.ascent, row.totalElevation?.round());
    set(f.calories, row.calories?.round());
  }

  final lap = fit.LapMesg()
    ..setFieldValue(fit.LapMesg.fieldMessageIndex, 0)
    ..setFieldValue(fit.LapMesg.fieldTimestamp, end)
    ..setFieldValue(fit.LapMesg.fieldStartTime, start)
    ..setFieldValue(fit.LapMesg.fieldEvent, fit.Event.lap)
    ..setFieldValue(fit.LapMesg.fieldEventType, fit.EventType.stop)
    ..setFieldValue(
      fit.LapMesg.fieldTotalElapsedTime,
      a.duration.inSeconds.toDouble(),
    )
    ..setFieldValue(fit.LapMesg.fieldTotalTimerTime, timerSeconds)
    ..setFieldValue(fit.LapMesg.fieldSport, sport)
    ..setFieldValue(fit.LapMesg.fieldSubSport, subSport);
  totals(lap, (
    distance: fit.LapMesg.fieldTotalDistance,
    avgHr: fit.LapMesg.fieldAvgHeartRate,
    maxHr: fit.LapMesg.fieldMaxHeartRate,
    avgPower: fit.LapMesg.fieldAvgPower,
    ascent: fit.LapMesg.fieldTotalAscent,
    calories: fit.LapMesg.fieldTotalCalories,
  ));
  write(lap);
  final session = fit.SessionMesg()
    ..setFieldValue(fit.SessionMesg.fieldMessageIndex, 0)
    ..setFieldValue(fit.SessionMesg.fieldTimestamp, end)
    ..setFieldValue(fit.SessionMesg.fieldStartTime, start)
    ..setFieldValue(fit.SessionMesg.fieldEvent, fit.Event.session)
    ..setFieldValue(fit.SessionMesg.fieldEventType, fit.EventType.stop)
    ..setFieldValue(fit.SessionMesg.fieldSport, sport)
    ..setFieldValue(fit.SessionMesg.fieldSubSport, subSport)
    ..setFieldValue(
      fit.SessionMesg.fieldTotalElapsedTime,
      a.duration.inSeconds.toDouble(),
    )
    ..setFieldValue(fit.SessionMesg.fieldTotalTimerTime, timerSeconds)
    ..setFieldValue(fit.SessionMesg.fieldFirstLapIndex, 0)
    ..setFieldValue(fit.SessionMesg.fieldNumLaps, 1);
  totals(session, (
    distance: fit.SessionMesg.fieldTotalDistance,
    avgHr: fit.SessionMesg.fieldAvgHeartRate,
    maxHr: fit.SessionMesg.fieldMaxHeartRate,
    avgPower: fit.SessionMesg.fieldAvgPower,
    ascent: fit.SessionMesg.fieldTotalAscent,
    calories: fit.SessionMesg.fieldTotalCalories,
  ));
  write(session);
  write(
    fit.ActivityMesg()
      ..setFieldValue(fit.ActivityMesg.fieldTimestamp, end)
      ..setFieldValue(fit.ActivityMesg.fieldTotalTimerTime, timerSeconds)
      ..setFieldValue(fit.ActivityMesg.fieldNumSessions, 1)
      ..setFieldValue(fit.ActivityMesg.fieldEvent, fit.Event.activity)
      ..setFieldValue(fit.ActivityMesg.fieldEventType, fit.EventType.stop),
  );
  return encoder.close();
}
