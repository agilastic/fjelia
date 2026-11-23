import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/models/strength_muscles.dart';
import 'package:fjelia/models/strength_workout.dart';
import 'package:fjelia/screens/strength/strength_exercise_sheet.dart';
import 'package:fjelia/services/strength/strength_focus.dart';
import 'package:fjelia/services/strength/strength_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StrengthRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StrengthRepository(db);
  });
  tearDown(() => db.close());

  group('pinned exercise notes', () {
    test('belong to the exercise and are trimmed', () async {
      await repo.setExerciseNote('bench_press', '  Keep the ribs down. ');
      await repo.setExerciseNote('plank', 'Squeeze the glutes.');
      expect(await repo.exerciseNotes(), {
        'bench_press': 'Keep the ribs down.',
        'plank': 'Squeeze the glutes.',
      });
    });

    test('an edit replaces, an empty note removes', () async {
      await repo.setExerciseNote('bench_press', 'Old');
      await repo.setExerciseNote('bench_press', 'New');
      expect((await repo.exerciseNotes())['bench_press'], 'New');
      await repo.setExerciseNote('bench_press', '   ');
      expect(await repo.exerciseNotes(), isEmpty);
      await repo.setExerciseNote('bench_press', null);
      expect(await repo.exerciseNotes(), isEmpty);
    });
  });

  group('Quick Start', () {
    test('starts empty, resumes, and is not a planned workout', () async {
      expect(await repo.openQuickSession(), isNull);
      final live = await repo.startQuickSession(title: 'Strength training');
      expect(live.isEmpty, isTrue);
      expect(live.baseline, isNull);
      expect((await repo.openQuickSession())?.activityId, live.activityId);
      // A planned live workout is never taken for a Quick Start one.
      expect(
        await repo.openLiveSession(StrengthPlanOwner.session('s')),
        isNull,
      );
    });

    test('exercises added in the gym are recorded and finish', () async {
      final live = await repo.startQuickSession(title: 'Strength training');
      final saved = await repo.saveLog(
        live.copyWith(
          exercises: [
            const StrengthPerformedExercise(
              id: 'pe1',
              variantId: 'push_up',
              name: 'Push-up',
              equipment: 'Bodyweight',
              convention: StrengthConvention(
                loadKind: StrengthLoadKind.bodyweight,
              ),
              notes: 'Wrists sore',
              sets: [StrengthSetResult(id: 'ps1')],
            ),
          ],
        ),
      );
      final order = strengthFocusOrder(saved);
      expect(order.single.set.id, 'ps1');
      expect(order.single.target, isNull);
      await repo.finishLiveSession(saved.activityId);
      expect(await repo.openQuickSession(), isNull);
      final log = await repo.loadLog(saved.activityId);
      expect(log!.exercises.single.notes, 'Wrists sore');
    });

    test('a planned live workout does not count as Quick Start', () async {
      final stored = await repo.savePlan(
        StrengthPlanOwner.session('s'),
        const StrengthWorkoutPlan(
          blocks: [
            StrengthBlock(
              id: 'b',
              exercises: [
                StrengthPlannedExercise(
                  id: 'e',
                  variantId: 'plank',
                  name: 'Plank',
                  equipment: 'Bodyweight',
                  sets: [StrengthSetTarget(id: 't', durationSeconds: 30)],
                ),
              ],
            ),
          ],
        ),
        expectedRevision: 0,
      );
      await repo.startLiveSession(stored: stored, title: 'Core');
      expect(await repo.openQuickSession(), isNull);
    });
  });

  test('every built-in exercise names the muscles it trains', () {
    for (final v in builtInStrengthVariants) {
      final m = strengthMusclesOf(v.id);
      expect(m, isNotNull, reason: v.id);
      expect(m!.primary, isNotEmpty, reason: v.id);
      expect(m.primary.toSet().intersection(m.secondary.toSet()), isEmpty);
    }
    expect(strengthMusclesOf('custom-123'), isNull);
  });

  test('the YouTube search carries only the exercise name', () {
    final uri = youtubeSearchUri('Bench press');
    expect(uri.host, 'www.youtube.com');
    expect(uri.path, '/results');
    expect(uri.queryParameters, {
      'search_query': 'Bench press exercise technique',
    });
  });
}
