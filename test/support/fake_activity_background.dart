import 'dart:async';

import 'package:fjelia/models/activity_location.dart';
import 'package:fjelia/services/activity_background.dart';
import 'package:flutter/services.dart';

class FakeActivityBackground extends ActivityBackground {
  FakeActivityBackground()
    : super(channel: const MethodChannel('fjelia/test_activity_background'));
  final fixes = StreamController<ActivityLocation>.broadcast();
  final commands = StreamController<String>.broadcast();
  final failures = StreamController<String>.broadcast();
  final owners = <String, ({bool gps, bool bluetooth})>{};
  int? clock;
  bool failStart = false;
  Completer<void>? preparing;
  final entered = Completer<void>();
  @override
  Stream<ActivityLocation> get locations => fixes.stream;
  @override
  Stream<String> get actions => commands.stream;
  @override
  Stream<String> get errors => failures.stream;
  @override
  Future<int?> monotonicMilliseconds() async => clock;
  @override
  Future<void> prepare({required bool gps, bool bluetooth = false}) async {
    if (!entered.isCompleted) entered.complete();
    await preparing?.future;
  }

  @override
  Future<void> start(
    String owner, {
    required bool gps,
    required bool bluetooth,
    required String name,
  }) async {
    if (failStart) throw StateError('Background service unavailable');
    owners[owner] = (gps: gps, bluetooth: bluetooth);
  }

  @override
  Future<void> stop(String owner) async {
    owners.remove(owner);
  }

  @override
  Future<void> dispose() async {
    await fixes.close();
    await commands.close();
    await failures.close();
    await super.dispose();
  }
}
