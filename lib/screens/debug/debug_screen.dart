import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/debug_log.dart';
import '../../widgets/app_widgets.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const Expanded(child: SectionLabel('Diagnostics')),
          IconButton(
            tooltip: 'Copy log',
            onPressed: () => Clipboard.setData(
              ClipboardData(text: DebugLog.lines.join('\n')),
            ),
            icon: const Icon(Icons.copy, size: 18),
          ),
          IconButton(
            tooltip: 'Clear log',
            onPressed: DebugLog.clear,
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
      Expanded(
        child: StreamBuilder<List<String>>(
          stream: DebugLog.stream,
          initialData: DebugLog.lines,
          builder: (c, s) => ListView(
            reverse: true,
            padding: const EdgeInsets.all(12),
            children: [
              for (final line in (s.data ?? []).reversed)
                SelectableText(
                  line,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
