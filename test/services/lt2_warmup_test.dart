import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fjelia/services/lt2_tt_service.dart';

void main() {
  String samples(int seconds) => jsonEncode([
    for (var t = 0; t <= seconds; t += 10)
      {'d': t * 3, 'spd': 3, 'hr': t < 900 ? 110 : 170},
  ]);
  test('explicit warm-up measures final 20 minutes of the selected TT', () {
    final result = Lt2TtService.calculate(
      samples(3000),
      'run',
      warmupMinutes: 15,
    );
    expect(result, isNotNull);
    expect(result!.lt2, 170);
    expect(result.paceSec, 333);
  });
  test('rejects a recording shorter than warm-up plus the full TT', () {
    expect(
      Lt2TtService.calculate(samples(2600), 'run', warmupMinutes: 15),
      isNull,
    );
  });
}
