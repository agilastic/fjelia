import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Tests run in the app's default language, British English, like the app.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  Intl.defaultLocale = 'en_GB';
  await testMain();
}
