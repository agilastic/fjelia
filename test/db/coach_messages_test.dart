import 'dart:io';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('each distinct briefing text of a day is kept once, in order', () async {
    final day = DateTime(2026, 11, 11, 7, 12);
    Future<void> keep(String period, String body, int hour) =>
        db.archiveCoachMessage(
          day: day,
          kind: 'briefing',
          period: period,
          body: body,
          source: 'Local · Apple Intelligence',
          now: DateTime(2026, 11, 11, hour),
        );
    await keep('morning', 'Make room for rest.', 7);
    await keep('morning', 'Make room for rest.', 8);
    await keep('morning', 'Keep dinner lean.', 9);
    await keep('lunch', 'Keep dinner lean.', 12);
    final kept = await db.coachMessagesOn(DateTime(2026, 11, 11));
    expect(
      [for (final m in kept) '${m.period}: ${m.body}'],
      [
        'morning: Make room for rest.',
        'morning: Keep dinner lean.',
        'lunch: Keep dinner lean.',
      ],
    );
    expect(kept.first.day, DateTime(2026, 11, 11));
    expect(kept.first.source, 'Local · Apple Intelligence');
    expect(await db.coachMessagesOn(DateTime(2026, 11, 12)), isEmpty);
  });

  test('empty text is not kept; old days go after 400 days', () async {
    await db.archiveCoachMessage(
      day: DateTime(2025, 9, 1),
      kind: 'briefing',
      period: 'morning',
      body: 'Long ago.',
    );
    await db.archiveCoachMessage(
      day: DateTime(2026, 11, 11),
      kind: 'briefing',
      period: 'morning',
      body: '  ',
    );
    expect(await db.coachMessagesOn(DateTime(2025, 9, 1)), hasLength(1));
    await db.archiveCoachMessage(
      day: DateTime(2026, 11, 11),
      kind: 'briefing',
      period: 'morning',
      body: 'Today.',
    );
    expect(await db.coachMessagesOn(DateTime(2025, 9, 1)), isEmpty);
    expect(await db.coachMessagesOn(DateTime(2026, 11, 11)), hasLength(1));
  });

  test('schema 73 gains the coach messages', () async {
    final dir = await Directory.systemTemp.createTemp('fjelia-messages-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final old = AppDatabase(NativeDatabase(file));
    await old.customStatement('DROP TABLE coach_messages');
    await old.customStatement('PRAGMA user_version = 73');
    await old.close();

    final migrated = AppDatabase(NativeDatabase(file));
    addTearDown(migrated.close);
    await migrated.archiveCoachMessage(
      day: DateTime(2026, 11, 11),
      kind: 'briefing',
      period: 'evening',
      body: 'Keep tonight low-key.',
    );
    expect(
      (await migrated.coachMessagesOn(DateTime(2026, 11, 11))).single.body,
      'Keep tonight low-key.',
    );
  });
}
