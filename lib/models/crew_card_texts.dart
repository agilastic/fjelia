import 'package:fjelia_views/fjelia_views.dart' show CrewCardTexts;

import '../l10n/l10n_ext.dart';

/// The crew card's words in the app language.
class AppCrewCardTexts implements CrewCardTexts {
  const AppCrewCardTexts();

  @override
  String get checkpoint => tr.crewCheckpoint;
  @override
  String get km => 'km';
  @override
  String get upDown => tr.crewUpDown;
  @override
  String get arrival => tr.crewDue;
  @override
  String get cutoff => tr.courseCutoff;
  @override
  String get handOver => tr.crewHandOver;
  @override
  String get finish => tr.courseFinish;
  @override
  String start(String time) => tr.crewStart(time);
  @override
  String finishRange(String time, String from, String to) =>
      tr.crewFinishRange(time, from, to);
  @override
  String ahead(String time) => tr.courseAhead(time);
  @override
  String late(String time) => tr.courseLate(time);
  @override
  String fuel(int carbs, String litres, int sodium) =>
      tr.crewFuel(carbs, litres, sodium);
  @override
  String get footer => tr.crewFooter;
}
