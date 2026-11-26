import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fjelia_views/fjelia_views.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n_ext.dart';
import '../models/crew_card_texts.dart';
import '../models/workout_nutrition.dart' show AppNutritionTexts;
import '../services/race_library.dart';
import 'database_provider.dart';
import 'day_data_provider.dart' show syncStatusListenerProvider;
import 'race_library_provider.dart';

/// The course of a race goal, analysed and predicted by fjelia_views, the
/// same as on the computer. Reads again after a sync or an edit.
final raceCourseProvider = FutureProvider.family<RaceCourseView?, String>((
  ref,
  goalId,
) {
  ref.watch(syncStatusListenerProvider);
  return loadRaceCourse(
    ref.watch(databaseProvider),
    goalId,
    texts: const AppNutritionTexts(),
  );
});

/// Adding and changing courses.
final raceCourseActionsProvider = Provider<RaceCourseActions>(
  RaceCourseActions.new,
);

class RaceCourseActions {
  RaceCourseActions(this.ref);
  final Ref ref;

  RaceCourseEdits get edits => RaceCourseEdits(ref.read(databaseProvider));
  RaceLibrary get library => ref.read(raceLibraryProvider);

  /// Lets the athlete pick a GPX file and saves it as [goalId]'s course.
  /// False when nothing was picked. Throws [CourseRefused].
  Future<bool> pickFile(String goalId) async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return false;
    final bytes = await files.single.xFile.readAsBytes();
    // GPX is UTF-8; checkpoint names often are not ASCII.
    await edits.setFromGpx(goalId, utf8.decode(bytes, allowMalformed: true));
    _changed(goalId);
    return true;
  }

  /// Saves the library's course of [race] with its aid stations and start.
  /// False when the organiser's file could not be fetched.
  Future<bool> fromLibrary(String goalId, RaceDistance race) async {
    final gpx = await library.courseGpx(race);
    if (gpx == null) return false;
    await edits.setFromGpx(
      goalId,
      gpx,
      source: CourseSource.library,
      libraryRaceId: race.id,
      checkpoints: race.aidStations.isEmpty
          ? null
          : checkpointsFromLibrary(race.aidStations),
      startAt: race.startAt,
    );
    _changed(goalId);
    return true;
  }

  Future<void> setCheckpoints(String goalId, List<CourseCheckpoint> c) async {
    await edits.setCheckpoints(goalId, c);
    _changed(goalId);
  }

  Future<void> setSettings(String goalId, RacePlanSettings settings) async {
    await edits.setSettings(goalId, settings);
    _changed(goalId);
  }

  Future<void> setStart(String goalId, DateTime start) async {
    await edits.setStart(goalId, start);
    _changed(goalId);
  }

  Future<void> remove(String goalId) async {
    await edits.remove(goalId);
    _changed(goalId);
  }

  /// The crew card of [view] as a PDF in the temporary folder, for the
  /// share sheet; null without a plan.
  Future<String?> crewCardFile(RaceCourseView view) async {
    Future<ByteData> font(String name) =>
        rootBundle.load('packages/fjelia_views/fonts/NotoSans-$name.ttf');
    final pdf = await crewCardPdf(
      view,
      const AppCrewCardTexts(),
      regular: await font('Regular'),
      bold: await font('Bold'),
      locale: tr.localeName,
    );
    if (pdf == null) return null;
    final dir = await getTemporaryDirectory();
    final name = view.goal.name.replaceAll(RegExp(r'[^\w-]+'), '_');
    final file = File('${dir.path}/crew_card_$name.pdf');
    await file.writeAsBytes(pdf, flush: true);
    return file.path;
  }

  void _changed(String goalId) => ref.invalidate(raceCourseProvider(goalId));
}
