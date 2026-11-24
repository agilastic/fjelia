import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's provider scope. [restart] throws it away and builds a new one:
/// after all data was deleted, everything is read again from empty storage,
/// as at a first start.
class AppRestart extends StatefulWidget {
  const AppRestart({super.key, required this.child});
  final Widget child;

  static void restart(BuildContext context) =>
      context.findAncestorStateOfType<_AppRestartState>()?.restart();

  @override
  State<AppRestart> createState() => _AppRestartState();
}

class _AppRestartState extends State<AppRestart> {
  var _key = UniqueKey();

  void restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      ProviderScope(key: _key, child: widget.child);
}
