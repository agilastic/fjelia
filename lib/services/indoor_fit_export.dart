import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fit_sdk/fit_sdk.dart' as fit;

import '../models/ftms.dart';
import '../models/indoor_recording.dart';
import '../db/database.dart' show BpMeasurement;
import 'activity_blood_pressure.dart';

/// FIT activity with standard records, timer events, interval laps, summaries
/// and BLE device identity. Developer fields retain every original FTMS field
/// (including fractional cadence, raw counters and millisecond timestamps).
Uint8List indoorFit(
  IndoorCapture capture, {
  List<BpMeasurement> bloodPressure = const [],
}) {
  if (capture.samples.isEmpty) {
    throw StateError('There are no recorded samples to export.');
  }
  final encoder = fit.Encode()..open();
  String? definition;
  void write(fit.Mesg message) {
    message.localNum = 0;
    final def = fit.MesgDefinition.fromMesg(message);
    final signature =
        '${message.num}:${message.fields.map((f) => '${f.num}:${f.getSize()}').join(',')}:${message.developerFields.map((f) => '${f.num}:${f.getSize()}').join(',')}';
    if (signature != definition) {
      encoder.writeMesgDefinition(def);
      definition = signature;
    }
    encoder.writeMesg(message, def);
  }

  int timestamp(DateTime time) =>
      time.toUtc().millisecondsSinceEpoch ~/ 1000 - 631065600;
  final start = timestamp(capture.startedAt);
  final end = capture.samples.last['t']!.toInt() ~/ 1000 - 631065600;
  final sport = capture.isManual
      ? switch (capture.activityType) {
          'cycling' => fit.Sport.cycling,
          'walking' => fit.Sport.walking,
          _ => fit.Sport.running,
        }
      : switch (capture.machine) {
          FtmsMachine.bike => fit.Sport.cycling,
          FtmsMachine.treadmill => fit.Sport.running,
          FtmsMachine.rower => fit.Sport.rowing,
          _ => fit.Sport.fitnessEquipment,
        };
  final subSport =
      capture.isManual && capture.activityType != 'treadmill_running'
      ? fit.SubSport.generic
      : switch (capture.machine) {
          FtmsMachine.bike => fit.SubSport.indoorCycling,
          FtmsMachine.treadmill => fit.SubSport.treadmill,
          FtmsMachine.rower => fit.SubSport.indoorRowing,
          FtmsMachine.crossTrainer => fit.SubSport.elliptical,
          _ => fit.SubSport.stairClimbing,
        };
  final identity = fit.FileIdMesg()
    ..setFieldValue(fit.FileIdMesg.fieldType, fit.File.activity)
    ..setFieldValue(
      fit.FileIdMesg.fieldManufacturer,
      fit.Manufacturer.development,
    )
    ..setFieldValue(fit.FileIdMesg.fieldProduct, 1)
    ..setFieldValue(
      fit.FileIdMesg.fieldSerialNumber,
      int.parse(
        sha256.convert(utf8.encode(capture.id)).toString().substring(0, 8),
        radix: 16,
      ),
    )
    ..setFieldValue(fit.FileIdMesg.fieldTimeCreated, start)
    ..setFieldValue(fit.FileIdMesg.fieldProductName, 'Fjelia');
  write(identity);
  final developer = fit.DeveloperDataIdMesg()
    ..setFieldValue(fit.DeveloperDataIdMesg.fieldDeveloperDataIndex, 0)
    ..setFieldValue(fit.DeveloperDataIdMesg.fieldApplicationVersion, 1);
  final appId = sha256
      .convert(utf8.encode('agilastic/fjelia/indoor-ftms'))
      .bytes
      .take(16)
      .toList();
  for (var i = 0; i < appId.length; i++) {
    developer.setFieldValue(
      fit.DeveloperDataIdMesg.fieldApplicationId,
      appId[i],
      index: i,
    );
  }
  write(developer);
  final keys = capture.samples.expand((s) => s.keys).toSet().toList()..sort();
  final descriptions = <String, fit.FieldDescriptionMesg>{};
  const units = {
    't': 'ms',
    'timer': 's',
    'spd': 'm/s',
    'avg_spd': 'm/s',
    'd': 'm',
    'machine_distance': 'm',
    'w': 'W',
    'avg_w': 'W',
    'hr': 'bpm',
    'cad': 'rpm',
    'incline': 'percent',
    'ascent': 'm',
    'descent': 'm',
    'kcal': 'kcal',
    'remaining': 's',
    'machine_elapsed': 's',
    'pace_500m': 's/500m',
    'force_n': 'N',
  };
  for (var i = 0; i < keys.length; i++) {
    final desc = fit.FieldDescriptionMesg()
      ..setFieldValue(fit.FieldDescriptionMesg.fieldDeveloperDataIndex, 0)
      ..setFieldValue(fit.FieldDescriptionMesg.fieldFieldDefinitionNumber, i)
      ..setFieldValue(
        fit.FieldDescriptionMesg.fieldFitBaseTypeId,
        fit.Fit.float64,
      )
      ..setFieldValue(
        fit.FieldDescriptionMesg.fieldFieldName,
        'ftms_${keys[i]}',
      )
      ..setFieldValue(
        fit.FieldDescriptionMesg.fieldUnits,
        units[keys[i]] ?? '',
      );
    descriptions[keys[i]] = desc;
    write(desc);
  }
  void device(int index, String name) => write(
    fit.DeviceInfoMesg()
      ..setFieldValue(fit.DeviceInfoMesg.fieldTimestamp, start)
      ..setFieldValue(fit.DeviceInfoMesg.fieldDeviceIndex, index)
      ..setFieldValue(fit.DeviceInfoMesg.fieldProductName, name)
      ..setFieldValue(fit.DeviceInfoMesg.fieldDescriptor, name)
      ..setFieldValue(
        fit.DeviceInfoMesg.fieldSourceType,
        capture.isManual && index == 0
            ? fit.SourceType.local
            : fit.SourceType.bluetoothLowEnergy,
      ),
  );
  device(0, capture.device.name);
  if (capture.heartRateDevice != null) device(1, capture.heartRateDevice!.name);
  void timer(int at, int type) => write(
    fit.EventMesg()
      ..setFieldValue(fit.EventMesg.fieldTimestamp, at)
      ..setFieldValue(fit.EventMesg.fieldEvent, fit.Event.timer)
      ..setFieldValue(fit.EventMesg.fieldEventType, type),
  );
  timer(start, fit.EventType.start);
  final pauses = capture.events
      .where(
        (e) => {'pause', 'resume'}.contains(e['type']) && e['at'] is String,
      )
      .toList();
  var pauseIndex = 0;
  final bp =
      bloodPressure
          .where((r) => bloodPressureDuringActivity(capture, r))
          .toList()
        ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  var bpIndex = 0;
  for (final sample in capture.samples) {
    final at = sample['t']!.toInt() ~/ 1000 - 631065600;
    while (bpIndex < bp.length && timestamp(bp[bpIndex].measuredAt) <= at) {
      final reading = bp[bpIndex++];
      final message = fit.BloodPressureMesg()
        ..setFieldValue(
          fit.BloodPressureMesg.fieldTimestamp,
          timestamp(reading.measuredAt),
        )
        ..setFieldValue(
          fit.BloodPressureMesg.fieldSystolicPressure,
          reading.systolic,
        )
        ..setFieldValue(
          fit.BloodPressureMesg.fieldDiastolicPressure,
          reading.diastolic,
        );
      if (reading.heartRate > 0) {
        message.setFieldValue(
          fit.BloodPressureMesg.fieldHeartRate,
          reading.heartRate,
        );
      }
      write(message);
    }
    while (pauseIndex < pauses.length &&
        timestamp(DateTime.parse(pauses[pauseIndex]['at'] as String)) <= at) {
      final event = pauses[pauseIndex++];
      timer(
        timestamp(DateTime.parse(event['at'] as String)),
        event['type'] == 'pause' ? fit.EventType.stopAll : fit.EventType.start,
      );
    }
    final record = fit.RecordMesg()
      ..setFieldValue(fit.RecordMesg.fieldTimestamp, at);
    void field(int number, num? value) {
      if (value != null) record.setFieldValue(number, value);
    }

    field(fit.RecordMesg.fieldHeartRate, sample['hr']?.round());
    field(fit.RecordMesg.fieldDistance, sample['d']);
    field(fit.RecordMesg.fieldEnhancedSpeed, sample['spd']);
    field(fit.RecordMesg.fieldGrade, sample['incline']);
    if (sample['lat'] != null && sample['lng'] != null) {
      field(
        fit.RecordMesg.fieldPositionLat,
        (sample['lat']! * 2147483648 / 180).round(),
      );
      field(
        fit.RecordMesg.fieldPositionLong,
        (sample['lng']! * 2147483648 / 180).round(),
      );
    }
    field(fit.RecordMesg.fieldEnhancedAltitude, sample['ele']);
    if ((sample['w'] ?? -1) >= 0) {
      field(fit.RecordMesg.fieldPower, sample['w']?.round());
    }
    if ((sample['cad'] ?? 255) < 255) {
      field(fit.RecordMesg.fieldCadence, sample['cad']?.floor());
      if (sample['cad'] != null) {
        field(fit.RecordMesg.fieldFractionalCadence, sample['cad']! % 1);
      }
    }
    field(
      fit.RecordMesg.fieldTotalCycles,
      sample['strokes']?.round() ?? sample['steps']?.round(),
    );
    for (final e in sample.entries) {
      record.setDeveloperField(
        fit.DeveloperField.fromDescription(descriptions[e.key]!, developer)
          ..setValue(e.value.toDouble()),
      );
    }
    write(record);
  }
  timer(end, fit.EventType.stopAll);
  final lapEnds = [
    for (final e in capture.events)
      if (e['type'] == 'interval')
        (
          at: timestamp(DateTime.parse(e['ended_at'] as String)),
          timer: (e['timer_seconds'] as num).toDouble(),
          distance: (e['distance_m'] as num).toDouble(),
        ),
    (
      at: end,
      timer: capture.elapsedMs / 1000,
      distance: capture.distanceMeters,
    ),
  ];
  var lapStart = start, previousTimer = 0.0, previousDistance = 0.0, laps = 0;
  for (final lap in lapEnds) {
    if (lap.timer <= previousTimer) continue;
    write(
      fit.LapMesg()
        ..setFieldValue(fit.LapMesg.fieldMessageIndex, laps++)
        ..setFieldValue(fit.LapMesg.fieldTimestamp, lap.at)
        ..setFieldValue(fit.LapMesg.fieldStartTime, lapStart)
        ..setFieldValue(fit.LapMesg.fieldEvent, fit.Event.lap)
        ..setFieldValue(fit.LapMesg.fieldEventType, fit.EventType.stop)
        ..setFieldValue(
          fit.LapMesg.fieldTotalElapsedTime,
          (lap.at - lapStart).toDouble(),
        )
        ..setFieldValue(
          fit.LapMesg.fieldTotalTimerTime,
          lap.timer - previousTimer,
        )
        ..setFieldValue(
          fit.LapMesg.fieldTotalDistance,
          lap.distance - previousDistance,
        )
        ..setFieldValue(fit.LapMesg.fieldSport, sport)
        ..setFieldValue(fit.LapMesg.fieldSubSport, subSport),
    );
    lapStart = lap.at;
    previousTimer = lap.timer;
    previousDistance = lap.distance;
  }
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
      (end - start).toDouble(),
    )
    ..setFieldValue(
      fit.SessionMesg.fieldTotalTimerTime,
      capture.elapsedMs / 1000,
    )
    ..setFieldValue(fit.SessionMesg.fieldFirstLapIndex, 0)
    ..setFieldValue(fit.SessionMesg.fieldNumLaps, laps);
  void summary(int field, num? value) {
    if (value != null) session.setFieldValue(field, value);
  }

  if (!capture.isManual) {
    summary(fit.SessionMesg.fieldTotalMovingTime, capture.movingMs / 1000);
  }

  summary(fit.SessionMesg.fieldTotalDistance, capture.totals['d']);
  summary(fit.SessionMesg.fieldTotalCalories, capture.totals['kcal']?.round());
  summary(fit.SessionMesg.fieldAvgHeartRate, capture.average('hr')?.round());
  summary(fit.SessionMesg.fieldMaxHeartRate, capture.maximum('hr')?.round());
  summary(fit.SessionMesg.fieldAvgPower, capture.average('w')?.round());
  summary(fit.SessionMesg.fieldMaxPower, capture.maximum('w')?.round());
  summary(fit.SessionMesg.fieldTotalAscent, capture.totals['ascent']?.round());
  summary(
    fit.SessionMesg.fieldTotalDescent,
    capture.totals['descent']?.round(),
  );
  write(session);
  write(
    fit.ActivityMesg()
      ..setFieldValue(fit.ActivityMesg.fieldTimestamp, end)
      ..setFieldValue(
        fit.ActivityMesg.fieldTotalTimerTime,
        capture.elapsedMs / 1000,
      )
      ..setFieldValue(fit.ActivityMesg.fieldNumSessions, 1)
      ..setFieldValue(fit.ActivityMesg.fieldEvent, fit.Event.activity)
      ..setFieldValue(fit.ActivityMesg.fieldEventType, fit.EventType.stop),
  );
  return encoder.close();
}
