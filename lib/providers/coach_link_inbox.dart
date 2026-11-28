import 'dart:async';

import 'package:flutter/services.dart';

/// Coaching invitations opened in Fjelia (fjelia://link?…, from the page at
/// www.fjelia.com/link/), as the native side keeps them: `CoachLinkChannel`
/// in AppDelegate.swift, `MainActivity` on Android.
class CoachLinkInbox {
  CoachLinkInbox([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('fjelia/links');

  final MethodChannel _channel;

  /// Calls [onLinks] for invitations waiting now and whenever new ones
  /// arrive.
  void listen(void Function(List<String> links) onLinks) {
    Future<void> deliver() async {
      final links = await take();
      if (links.isNotEmpty) onLinks(links);
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'opened') await deliver();
      return null;
    });
    unawaited(deliver());
  }

  Future<List<String>> take() async {
    try {
      final links = await _channel.invokeListMethod<Object?>('takePending');
      return [...?links?.whereType<String>()];
    } on MissingPluginException {
      return const [];
    }
  }
}
