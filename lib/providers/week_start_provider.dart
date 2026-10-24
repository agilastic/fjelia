import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_profile_provider.dart';

/// Settings → Training → Calendar week start (true = Monday, false = Sunday).
final weekStartsOnMondayProvider = Provider<bool>(
  (ref) =>
      ref.watch(
        userProfileProvider.select((v) => v.valueOrNull?.weekStartsOnMonday),
      ) ??
      true,
);
