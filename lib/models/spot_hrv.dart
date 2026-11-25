import 'dart:convert';

import 'package:fjelia_core/models/spot_hrv.dart';

import '../l10n/l10n_ext.dart';

export 'package:fjelia_core/models/spot_hrv.dart';

extension SpotHrvContextLabel on SpotHrvContext {
  String get label => switch (this) {
    SpotHrvContext.beforeTraining => tr.enumBeforeTraining,
    SpotHrvContext.afterTraining => tr.enumAfterTraining,
    SpotHrvContext.resting => tr.enumResting,
  };
}

extension SpotHrvPostureLabel on SpotHrvPosture {
  String get label => switch (this) {
    SpotHrvPosture.seated => tr.enumSeated,
    SpotHrvPosture.supine => tr.enumLyingDown,
  };
}

extension SpotRrRejectionText on SpotRrRejection {
  String get text => switch (this) {
    SpotRrRejection.implausible => 'RR outside 250–2500 ms',
    SpotRrRejection.poorContact => tr.poorSensorContact,
    SpotRrRejection.outlier => tr.moreThan25FromLocal,
  };
}

extension SpotHrvAnalysisText on SpotHrvAnalysis {
  /// Why each sample was left out, in the app language; null when used.
  List<String?> get rejections => [for (final r in rejectionKinds) r?.text];

  String get rrJson => jsonEncode([
    for (var i = 0; i < samples.length; i++)
      {
        'elapsed_ms': samples[i].elapsedMs,
        'rr_ms': samples[i].rrMs,
        'contact': samples[i].contact,
        'excluded': rejectionKinds[i]?.text,
      },
  ]);
}
