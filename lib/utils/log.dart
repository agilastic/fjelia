/// Timestamped debug print: `[HH:MM:SS] message`.
void log(String message) {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  // ignore: avoid_print
  print('[${two(now.hour)}:${two(now.minute)}:${two(now.second)}] $message');
}
