import 'package:fjelia_service_api/fjelia_service_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/fjelia_edition.dart';
import 'fjelia_pro_provider.dart';

/// FjeliaPro or the free edition, for the screens. Rebuilds when the
/// subscription changes, so Pro features appear right after a purchase.
final fjeliaEditionProvider = Provider<FjeliaEdition>((ref) {
  ref.watch(fjeliaProProvider);
  return _Edition(
    proOffered: fjeliaEdition.proOffered,
    isPro: fjeliaEdition.isPro,
  );
});

/// The edition's answers at one moment, so a change is a new value.
class _Edition implements FjeliaEdition {
  const _Edition({required this.proOffered, required this.isPro});
  @override
  final bool proOffered, isPro;
  @override
  bool operator ==(Object other) =>
      other is _Edition &&
      other.proOffered == proOffered &&
      other.isPro == isPro;
  @override
  int get hashCode => Object.hash(proOffered, isPro);
}
