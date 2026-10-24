import 'package:fjelia/models/garmin_data.dart';
import 'package:fjelia/widgets/sleep_stages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SleepData night({bool withPhases = true}) {
  final start = DateTime(2026, 10, 20, 23);
  DateTime t(int minutes) => start.add(Duration(minutes: minutes));
  return SleepData(
    date: DateTime(2026, 10, 21),
    totalSleep: const Duration(hours: 7),
    deepSleep: const Duration(minutes: 80),
    remSleep: const Duration(minutes: 100),
    lightSleep: const Duration(minutes: 240),
    awakeSleep: const Duration(minutes: 20),
    sleepStart: start,
    sleepEnd: t(8 * 60),
    phases: withPhases
        ? [
            SleepPhase(t(0), t(30), 'light'),
            SleepPhase(t(30), t(110), 'deep'),
            SleepPhase(t(110), t(130), 'awake'),
            SleepPhase(t(130), t(230), 'rem'),
            SleepPhase(t(230), t(480), 'light'),
          ]
        : const [],
  );
}

Widget host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    ),
  ),
);

void main() {
  testWidgets('shows stages chart, breakdown and tap details', (tester) async {
    await tester.pumpWidget(host(SleepStagesSection(sleep: night())));
    expect(find.text('SLEEP STAGES'), findsOneWidget);
    for (final label in ['AWAKE', 'REM', 'LIGHT', 'DEEP']) {
      // once as a chart row label, once in the breakdown
      expect(find.text(label), findsNWidgets(2));
    }
    expect(find.text('1h 20m'), findsOneWidget); // deep
    expect(find.text('1h 40m'), findsOneWidget); // REM
    expect(find.text('4h 00m'), findsOneWidget); // light
    expect(find.text('20m'), findsOneWidget); // awake
    expect(find.text('Touch the chart for details'), findsOneWidget);

    // Tap at ~1.5 h into the night: the deep phase (0:30–1:50).
    final chart = find.byType(CustomPaint).last;
    final box = tester.getRect(chart);
    await tester.tapAt(Offset(box.left + box.width * (90 / 480), box.top + 20));
    await tester.pump();
    expect(find.textContaining('DEEP · 11:30 pm'), findsOneWidget);
  });

  testWidgets('without phases only the breakdown is shown', (tester) async {
    await tester.pumpWidget(
      host(SleepStagesSection(sleep: night(withPhases: false))),
    );
    expect(find.text('No stage timeline for this night.'), findsOneWidget);
    expect(find.text('Touch the chart for details'), findsNothing);
    expect(find.text('REM'), findsOneWidget);
    expect(find.text('1h 40m'), findsOneWidget);
  });
}
