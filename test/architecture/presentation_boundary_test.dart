import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation has no device SDKs, client calls, providers or database access', () {
    final violations = <String>[];
    final forbidden = RegExp(
      r"(?:package:(?:health/|flutter_blue|permission_handler|flutter_web_auth)|/api/|services/(?:hilo_ble|renpho_ble|polar_service|suunto_service|coros_service)|\b(?:garminClientProvider|aktiiaClientProvider|renphoClientProvider|hiloBleServiceProvider|healthConnectServiceProvider|suuntoServiceProvider|polarServiceProvider|corosServiceProvider|databaseProvider)\b|^\s*final\s+\w+Provider\s*=)",
      multiLine: true,
    );
    for (final dir in ['lib/widgets', 'lib/screens']) {
      for (final file
          in Directory(dir)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        if (forbidden.hasMatch(file.readAsStringSync())) {
          violations.add(file.path);
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'Move device integration/data access into a provider or service.',
    );
  });
  test('data providers and services do not import presentation', () {
    final violations = <String>[];
    for (final dir in ['lib/providers', 'lib/services']) {
      for (final file
          in Directory(dir)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        if (RegExp(r"""(?:import|export)\s+['"][^'"]*(?:widgets|screens)/""")
            .hasMatch(file.readAsStringSync())) {
          violations.add(file.path);
        }
      }
    }
    expect(violations, isEmpty);
  });
}
