import 'dart:async';

/// In-app log viewer backing store: captures `print` / `debugPrint` output
/// (last 500 lines) and broadcasts updates to the debug screen.
abstract class DebugLog {
  static const _maxLines = 500;
  static final List<String> _lines = [];
  static final StreamController<List<String>> _controller =
      StreamController<List<String>>.broadcast();

  static Stream<List<String>> get stream => _controller.stream;

  static List<String> get lines => List<String>.unmodifiable(_lines);

  static void add(String message) {
    _lines.add('${_timestamp()}  $message');
    if (_lines.length > _maxLines) _lines.removeAt(0);
    _controller.add(List<String>.unmodifiable(_lines));
  }

  static void clear() {
    _lines.clear();
    _controller.add(List<String>.unmodifiable(_lines));
  }

  /// Runs [body] in a zone whose `print` also feeds the log.
  static Future<void> install(Future<void> Function() body) {
    return runZoned(
      body,
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          add(line);
          parent.print(zone, line);
        },
      ),
    );
  }

  static String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final centis = (now.millisecond ~/ 10).toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}.$centis';
  }
}
