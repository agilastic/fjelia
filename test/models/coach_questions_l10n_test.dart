import 'package:fjelia/l10n/l10n_ext.dart';
import 'package:fjelia/models/coach_context_card.dart';
import 'package:fjelia/models/garmin_data.dart';
import 'package:fjelia/services/coach_tasks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => setActiveLocale(const Locale('en')));

  test('the question chips follow the app language', () {
    setActiveLocale(const Locale('de'));
    final card = CoachContextCard.completed(
      GarminActivity(
        id: 'a',
        name: 'Lauf',
        type: 'running',
        startTime: DateTime(2026, 11, 2, 7),
        duration: const Duration(minutes: 50),
      ),
    );
    expect(card.questions, [
      'Wie lief diese Einheit?',
      'Was bedeutet das für meine nächsten Tage?',
      'Wie schneidet es im Vergleich zu ähnlichen Einheiten ab?',
    ]);
    // What the chips already offer is not suggested again afterwards.
    final follow = followUpQuestions(
      CoachTask.evaluateActivity,
      asked: card.questions,
    );
    expect(
      follow,
      isNot(contains('Was bedeutet das für meine nächsten Tage?')),
    );
    expect(follow, contains('War die Intensität richtig?'));
  });
}
