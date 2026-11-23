import '../theme/fjelia_style.dart';

import 'package:flutter/material.dart';

import 'app_widgets.dart';

/// Says plainly that a day has no reading, why that usually happens and,
/// when there is one, which reading came last. Nothing is filled in.
class DataGapCard extends StatelessWidget {
  const DataGapCard({
    super.key,
    required this.title,
    required this.reason,
    this.last,
  });
  final String title, reason;

  /// The last real reading with its date, or null.
  final String? last;

  @override
  Widget build(BuildContext context) => SectionCard(
    key: const ValueKey('data-gap'),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.cloud_off_outlined, size: 20, color: muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                reason,
                style: TextStyle(fontSize: 12, color: fjInk70, height: 1.35),
              ),
              if (last != null) ...[
                const SizedBox(height: 6),
                Text(last!, style: TextStyle(fontSize: 12, color: muted)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
