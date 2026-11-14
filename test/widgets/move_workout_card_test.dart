import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/widgets/move_workout_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  DateTime day(int n) => DateTime(today.year, today.month, today.day + n);

  List<MoveDay> days({
    Set<int> rest = const {},
    Map<int, int> sessions = const {},
  }) => [
    for (var i = 0; i < 20; i++)
      MoveDay(
        date: day(i),
        isRestDay: rest.contains(i),
        sessions: sessions[i] ?? 0,
        isFull: (sessions[i] ?? 0) >= 2,
      ),
  ];

  Finder chip(DateTime d) => find.byWidgetPredicate(
    (w) =>
        w is Semantics &&
        (w.properties.label ?? '').startsWith(_label(d)) &&
        (w.properties.button ?? false),
  );

  Future<List<DateTime>> pump(
    WidgetTester tester, {
    int current = 3,
    bool enabled = true,
    DateTime? movedFrom,
    String? note,
    VoidCallback? onUndo,
    Set<int> rest = const {},
    Map<int, int> sessions = const {},
  }) async {
    final moved = <DateTime>[];
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: MoveWorkoutCard(
              current: day(current),
              days: days(rest: rest, sessions: sessions),
              enabled: enabled,
              onMove: (d) async => moved.add(d),
              onPickDate: () {},
              movedFrom: movedFrom,
              note: note,
              onUndo: onUndo,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return moved;
  }

  testWidgets('a compact strip of days and a calendar button', (tester) async {
    await pump(tester);
    expect(find.text('MOVE THIS WORKOUT'), findsOneWidget);
    expect(find.byTooltip('Pick date'), findsOneWidget);
    // No explanation, no drag chip: tapping a day is the whole interaction.
    expect(find.textContaining('Tap a day'), findsNothing);
    expect(find.byIcon(Icons.drag_indicator), findsNothing);
    // Nothing on the strip to explain: no key.
    expect(find.text('rest day'), findsNothing);
    final card = tester.getSize(find.byType(MoveWorkoutCard));
    expect(card.height, lessThan(130));
  });

  testWidgets('tapping another day moves, the current day does nothing', (
    tester,
  ) async {
    final moved = await pump(tester);
    await tester.tap(chip(day(4)));
    await tester.pump();
    expect(moved, [day(4)]);
    await tester.tap(chip(day(3)));
    await tester.pump();
    expect(moved, [day(4)]);
  });

  testWidgets('a locked card moves nothing', (tester) async {
    final moved = await pump(tester, enabled: false);
    await tester.tap(chip(day(4)));
    await tester.pump();
    expect(moved, isEmpty);
  });

  testWidgets('rest days and busy days are marked', (tester) async {
    await pump(tester, rest: {4}, sessions: {5: 2, 6: 1});
    expect(
      find.byIcon(Icons.nightlight_outlined),
      findsNWidgets(2),
    ); // key + day
    // Only the marks on the strip are explained.
    expect(find.text('rest day'), findsOneWidget);
    expect(find.text('has a session'), findsOneWidget);
    expect(find.text('event'), findsNothing);
    final label = find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          (w.properties.label ?? '').contains('rest day') &&
          (w.properties.button ?? false),
    );
    expect(label, findsOneWidget);
    final busy = find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          (w.properties.label ?? '').contains('2 sessions planned'),
    );
    expect(busy, findsOneWidget);
  });
  testWidgets('after a move the way back is a line on the card', (
    tester,
  ) async {
    var undone = 0;
    await pump(
      tester,
      movedFrom: day(1),
      note: 'Push again to update your watch calendar.',
      onUndo: () => undone++,
    );
    expect(find.textContaining('Moved from'), findsOneWidget);
    expect(
      find.text('Push again to update your watch calendar.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Undo'));
    expect(undone, 1);
  });

  testWidgets('before a move there is nothing to undo', (tester) async {
    await pump(tester);
    expect(find.textContaining('Moved from'), findsNothing);
    expect(find.text('Undo'), findsNothing);
  });
}

String _label(DateTime d) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}
