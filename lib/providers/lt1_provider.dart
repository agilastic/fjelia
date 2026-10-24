import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/lt1_estimate_service.dart';
import 'lt1_drift_provider.dart';
import 'lt2_tt_provider.dart';
import 'user_profile_provider.dart';

/// Best LT1 estimate: drift test, else LT2 − 30, else 77 % of max HR.
final lt1Provider = Provider<Lt1Estimate?>((ref) {
  final lt2 = ref.watch(lt2TtProvider).valueOrNull;
  final drift = ref.watch(lt1DriftProvider).valueOrNull;
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return Lt1EstimateService.compute(
    driftLt1: drift?.lt1,
    lt2: lt2?.lt2,
    maxHr: profile?.maxHrEstimate,
  );
});
