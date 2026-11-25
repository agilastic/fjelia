import 'package:fjelia_core/services/ecg_analysis.dart';
import 'package:fjelia_core/services/ecg_coach_context.dart';

import '../db/database.dart';
import 'coach_tasks.dart' show ecgClinicalMode;

export 'package:fjelia_core/services/ecg_coach_context.dart';

/// The analysis lines the chat about one recording gets, exactly as the
/// ECG sheet builds them: FjeliaPro's medical reading when this build has
/// it, the training view otherwise.
List<String> ecgAnalysisLines(EcgRecording r, EcgAnalysis analysis) =>
    ecgAnalysisLinesFor(r, analysis, clinical: ecgClinicalMode);

/// The lines for one recording: its analysis, an imported report's text or
/// what is missing, focused on [minutes] when asked.
List<String> ecgDetailLines(
  EcgRecording r,
  EcgAnalysis? analysis, {
  String? reportText,
  ({int from, int to})? minutes,
  ActivityRecord? activity,
}) => ecgDetailLinesFor(
  r,
  analysis,
  reportText: reportText,
  minutes: minutes,
  activity: activity,
  clinical: ecgClinicalMode,
);
