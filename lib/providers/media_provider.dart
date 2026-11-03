import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../services/media_service.dart';
import 'database_provider.dart';

export '../services/media_service.dart' show MediaOwner;

final mediaServiceProvider = Provider<MediaService>(
  (ref) => MediaService(ref.watch(databaseProvider)),
);

/// The photos and videos of one activity, race goal or planned session.
/// A planned session first takes over media left by the session a new plan
/// replaced on the same day.
final mediaItemsProvider = StreamProvider.autoDispose
    .family<List<MediaItem>, MediaOwner>((ref, owner) async* {
      final service = ref.watch(mediaServiceProvider);
      if (owner.kind == 'session') await service.reattachSessionMedia();
      yield* service.watch(owner);
    });
