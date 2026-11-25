import 'dart:convert';

import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/screens/settings/profile_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Grunddaten says what it holds: year, age, HR zones', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final year = DateTime.now().year - 44;
    FlutterSecureStorage.setMockInitialValues({
      'user_profile_v1': jsonEncode({'birthYear': year}),
    });
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileTab(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('$year · Alter 4'), findsOneWidget);
    expect(find.textContaining(' · HF-Zonen'), findsOneWidget);
  });
}
