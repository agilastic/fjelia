import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../models/renpho_data.dart';
import '../utils/log.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';

/// Ten years of scale readings, newest first.
final bodyMeasurementsProvider = FutureProvider<List<RenphoMeasurement>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  ref.watch(syncStatusListenerProvider);
  final rows = await db.getRenphoRange(3650);
  log('[Renpho] provider: ${rows.length} records from DB');
  rows.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
  return rows.map(_fromRecord).toList();
});

final latestBodyMeasurementProvider = FutureProvider<RenphoMeasurement?>((
  ref,
) async {
  final all = await ref.watch(bodyMeasurementsProvider.future);
  return all.isEmpty ? null : all.first;
});

RenphoMeasurement _fromRecord(RenphoRecord r) {
  Map<String, dynamic> raw = const {};
  try {
    raw = jsonDecode(r.rawJson) as Map<String, dynamic>;
  } catch (_) {}
  return RenphoMeasurement({
    ...raw,
    'timeStamp': r.measuredAt.millisecondsSinceEpoch ~/ 1000,
    'scaleName': r.scaleName,
    'weight': r.weight,
    'bmi': r.bmi,
    'bodyfat': r.bodyFat,
    'water': r.bodyWater,
    'muscle': r.muscleMass,
    'bone': r.boneMass,
    'bmr': r.bmr,
    'visfat': r.visceralFat,
    'subfat': r.subcutaneousFat,
    'protein': r.protein,
    'bodyage': r.bodyAge,
    'sinew': r.leanBodyMass,
    'fatFreeWeight': r.fatFreeWeight,
    'waistCm': r.waistCm,
    'heartRate': r.heartRate,
    'cardiacIndex': r.cardiacIndex,
    'bodyShape': r.bodyShape,
  });
}
