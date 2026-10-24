// Checks the Polar Flow web import against the real service.
//
//   POLAR_EMAIL=you@example.com POLAR_PASSWORD='…' \
//     flutter pub run scripts/polar_flow_probe.dart [YYYY-MM]
//
// Prints the hop-by-hop login trace (no cookies, no password), the sessions
// found for the month (default: the month 60 days ago) and a summary of the
// first exported TCX. Nothing is written to any database.
import 'dart:io';

import 'package:fjelia/api/polar_flow_web_client.dart';
import 'package:fjelia/services/tcx_parser.dart';

Future<void> main(List<String> args) async {
  final email = Platform.environment['POLAR_EMAIL'];
  final password = Platform.environment['POLAR_PASSWORD'];
  if (email == null || password == null) {
    stderr.writeln('Set POLAR_EMAIL and POLAR_PASSWORD.');
    exit(2);
  }
  final month = args.isNotEmpty
      ? DateTime.parse('${args.first}-01')
      : DateTime.now().subtract(const Duration(days: 60));
  final from = DateTime(month.year, month.month);
  final to = DateTime(month.year, month.month + 1, 0);

  final web = PolarFlowWebClient(trace: (l) => stdout.writeln('  $l'));
  try {
    stdout.writeln('Signing in…');
    await web.login(email, password);
    stdout.writeln('Signed in. Diary ${from.year}-${from.month}:');
    final list = await web.workouts(from, to);
    for (final w in list) {
      stdout.writeln(
        '  ${w.start}  id=${w.id}  ${w.durationSeconds}s  '
        '${w.distanceMeters}m  ${w.sport}',
      );
    }
    if (list.isEmpty) stdout.writeln('  (no sessions)');
    final long = list.where((w) => (w.durationSeconds ?? 0) >= 60).toList();
    if (long.isNotEmpty) {
      final tcx = parseTcx(await web.exportTcx(long.first));
      stdout.writeln(
        'TCX of ${long.first.id}: ${tcx == null ? 'not parsed' : '${tcx.sport} '
              '${tcx.durationSeconds}s ${tcx.distanceMeters}m '
              'avg ${tcx.avgHeartRate?.round()} max ${tcx.maxHeartRate} '
              'hr samples ${tcx.heartRates.length} route ${tcx.route.length}'}',
      );
    }
  } on PolarFlowException catch (e) {
    stdout.writeln('FAILED: ${e.message}');
    exit(1);
  } finally {
    web.close();
  }
}
