import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import 'database_provider.dart';

/// The athlete's memory cards for the coach, the newest change first.
final coachMemoriesProvider = StreamProvider<List<CoachMemory>>(
  (ref) => ref.watch(databaseProvider).watchCoachMemories(),
);

/// Saving, deleting and reading the memory cards, for the screens.
final coachMemoryStoreProvider = Provider<CoachMemoryStore>(
  (ref) => CoachMemoryStore(ref.watch(databaseProvider)),
);

class CoachMemoryStore {
  const CoachMemoryStore(this._db);
  final AppDatabase _db;

  Future<List<CoachMemory>> all() => _db.coachMemoryList();

  /// A new card, or [card] with a new title and text.
  Future<void> save(String title, String body, [CoachMemory? card]) {
    final now = DateTime.now();
    return _db.saveCoachMemory(
      CoachMemory(
        id: card?.id ?? const Uuid().v4(),
        title: title,
        body: body,
        createdAt: card?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<void> delete(String id) => _db.deleteCoachMemory(id);
}
