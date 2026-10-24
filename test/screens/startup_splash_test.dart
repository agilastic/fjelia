import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/screens/startup_splash.dart';

void main() {
  test('time of day artwork also applies during winter', () {
    for (final month in [1, 7, 12]) {
      for (final hour in [0, 4, 22, 23]) {
        expect(
          startupArtwork(DateTime(2026, month, 1, hour)),
          contains('night'),
        );
      }
      for (final hour in [5, 8]) {
        expect(
          startupArtwork(DateTime(2026, month, 1, hour)),
          contains('sunrise'),
        );
      }
      for (final hour in [18, 21]) {
        expect(
          startupArtwork(DateTime(2026, month, 1, hour)),
          contains('sunset'),
        );
      }
    }
    expect(
      startupArtwork(DateTime(2026, 7, 1, 9)),
      endsWith('fjelia-splash.png'),
    );
    expect(startupArtwork(DateTime(2026, 1, 1, 12)), contains('winter'));
  });

  testWidgets('decoded artwork stays visible for two seconds', (tester) async {
    var elapsed = false;
    await tester.pumpWidget(
      MaterialApp(home: StartupSplash(onMinimumElapsed: () => elapsed = true)),
    );
    final context = tester.element(find.byType(StartupSplash));
    await tester.runAsync(
      () => precacheImage(AssetImage(startupArtwork(DateTime.now())), context),
    );
    await tester.pump();
    expect(elapsed, isFalse);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(elapsed, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(elapsed, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
