import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fjelia/db/database.dart';
import 'package:fjelia/l10n/app_localizations.dart';
import 'package:fjelia/providers/database_provider.dart';
import 'package:fjelia/providers/messages_provider.dart';
import 'package:fjelia/screens/messages/coaching_screen.dart';
import 'package:fjelia_core/services/sync/sync_tables.dart';
import 'package:fjelia_data/messages.dart';
import 'package:fjelia_sync/fjelia_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _Memory implements SecretStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  late AppDatabase db;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    // Nothing reaches a relay in tests: a closed port refuses at once.
    MessagesNotifier.relayBase = Uri.parse('http://127.0.0.1:9');
    MessagesNotifier.relayTransport = null;
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester, [int rounds = 5]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CoachingScreen(),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> join(WidgetTester tester, String text) async {
    await tester.tap(find.text('Join a coach'));
    await settle(tester, 2);
    await tester.enterText(find.byType(TextField).last, text);
    await tester.tap(find.text('Continue'));
    await settle(tester);
  }

  testWidgets('without a coach it says how to join one', (tester) async {
    await open(tester);
    expect(find.textContaining('No coach yet'), findsOneWidget);
    await join(tester, 'https://example.com');
    expect(
      find.text('This is not a Fjelia coaching invitation.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an invitation needs the server to find the coach', (
    tester,
  ) async {
    await open(tester);
    final invite = LinkInvite.create(
      coach: 'a' * 32,
      name: 'Kim',
    ).toUri().toString();
    await join(tester, invite);
    expect(find.textContaining("server cannot be reached"), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the athlete changes what the coach sees, then ends it', (
    tester,
  ) async {
    late String linkId;
    await tester.runAsync(() async {
      // This phone's person, as the first start leaves it.
      final store = _Memory();
      final me = (await PersonIdentity.create(
        store,
        deviceName: 'Ana phone',
        platform: 'ios',
      )).identity;
      FlutterSecureStorage.setMockInitialValues(store.values);
      // A coach met nearby, and the link both signed.
      final coachStore = _Memory();
      final coach = (await PersonIdentity.create(
        coachStore,
        deviceName: 'Kim Mac',
        platform: 'macos',
      )).identity;
      final record = CoachLink.record(
        coach: coach.personId,
        athlete: me.personId,
        now: DateTime.utc(2026, 11, 2),
      );
      final link = CoachLink.verified(
        jsonDecode(
          jsonEncode({
            'link': record,
            'coach_sig': CoachLink.sign(coach.person, record),
            'athlete_sig': CoachLink.sign(me.person, record),
          }),
        ),
        coachKey: coach.person.spki,
        athleteKey: me.person.spki,
      )!;
      linkId = link.id;
      await db.installMessages();
      await db.savePerson(
        MessagePerson(
          person: coach.personId,
          name: 'Kim',
          role: PersonRole.coach,
          deviceList: jsonEncode(coach.signedList),
          listVersion: 1,
        ),
      );
      await db.saveSyncLink(link.toStored());
    });
    await open(tester);
    expect(find.text('Kim'), findsOneWidget);
    expect(find.textContaining('Coached since'), findsOneWidget);
    expect(find.text('What Kim sees'), findsOneWidget);
    SwitchListTile tile(String name) => tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, name),
    );
    expect(tile('Plan').value, isTrue);
    expect(tile('Health').value, isFalse);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Health'));
    await settle(tester);
    expect(tile('Health').value, isTrue);
    final shared = await tester.runAsync(() => db.syncLink(linkId));
    expect(shared!.scopes, contains(SyncCategory.health));

    await tester.scrollUntilVisible(find.text('End coaching'), 100);
    await tester.tap(find.text('End coaching'));
    await settle(tester, 2);
    expect(find.text('End coaching with Kim?'), findsOneWidget);
    await tester.tap(find.text('End'));
    await settle(tester);
    expect(find.textContaining('Ended'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    final ended = await tester.runAsync(() => db.syncLink(linkId));
    expect(ended!.active, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the athlete sees the code and what to share before sending', (
    tester,
  ) async {
    late PersonIdentity coach;
    late PersonIdentity me;
    await tester.runAsync(() async {
      final store = _Memory();
      me = (await PersonIdentity.create(
        store,
        deviceName: 'Ana phone',
        platform: 'ios',
      )).identity;
      FlutterSecureStorage.setMockInitialValues(store.values);
      coach = (await PersonIdentity.create(
        _Memory(),
        deviceName: 'Kim Mac',
        platform: 'macos',
      )).identity;
      // A relay that knows the coach's devices and nothing else.
      MessagesNotifier.relayTransport = (method, url, body, headers) async =>
          url.path == '/v1/relay/lists/${coach.personId}'
          ? (200, coach.signedList)
          : (url.path == '/v1/relay/lists' ? 200 : 404, null);
    });
    await open(tester);
    final invite = LinkInvite.create(coach: coach.personId, name: 'Kim');
    await join(tester, invite.toUri().toString());
    expect(find.text('Be coached by Kim?'), findsOneWidget);
    SwitchListTile tile(String name) => tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, name),
    );
    expect(tile('Plan').value, isTrue);
    expect(tile('Activities').value, isTrue);
    expect(tile('Health').value, isFalse);
    expect(tile('ECG').value, isFalse);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Health'));
    await tester.pump();
    // The same code as on the coach's screen.
    final code = invite.code(me.personId);
    final spaced = '${code.substring(0, 3)} ${code.substring(3)}';
    await tester.scrollUntilVisible(find.text(spaced), 100);
    expect(find.text(spaced), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Share and send'), 100);
    await tester.tap(find.text('Share and send'));
    await settle(tester);
    expect(find.textContaining('Read this code to Kim'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('Waiting for Kim to accept'), findsOneWidget);
    // The answer waits for the relay, with what Ana chose.
    final [waiting] = (await tester.runAsync(() => db.linkOutbox()))!;
    expect(waiting.people, {coach.personId});
    final request = (jsonDecode(waiting.payload) as Map)['request'] as Map;
    expect(request['token'], invite.token);
    expect((request['link'] as Map)['scopes'], [
      'activities',
      'plan',
      'health',
    ]);
    await tester.pumpWidget(const SizedBox());
  });
}
