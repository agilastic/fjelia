import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/secrets.dart';

/// Which of the keys under Settings > Own keys (Fjelia CE) the user entered.
/// The values themselves never go back to the screen.
final ownKeysProvider = FutureProvider<Set<OwnKey>>((ref) async {
  final entered = <OwnKey>{};
  for (final key in OwnKey.values) {
    if ((await key.read())?.trim().isNotEmpty ?? false) entered.add(key);
  }
  return entered;
});

/// Saves or (empty) removes an own key; it applies at once.
Future<void> saveOwnKey(WidgetRef ref, OwnKey key, String value) async {
  await key.write(value);
  ref.invalidate(ownKeysProvider);
}
