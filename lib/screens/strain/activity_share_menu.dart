import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/activity_share_provider.dart';
import '../../theme/fjelia_style.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/ecg_sheet.dart' show shareRecordingFile;

enum _ShareChoice { card, fitFile, garmin }

/// The share button of a workout: the picture card, the FIT file for any
/// other app, or straight to a connected platform.
Future<void> showActivityShareMenu(
  BuildContext context,
  WidgetRef ref, {
  required ActivityRecord activity,
  required Future<void> Function() shareCard,
}) async {
  final share = ref.read(activityShareProvider);
  final l10n = context.l10n;
  final choice = await showModalBottomSheet<_ShareChoice>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: duo(0xFF161616, 0xFFF7F8FA),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: GradientTitle(
              l10n.shareWorkout,
              colors: const [Color(0xFFFF7AD9), Color(0xFF9D7BFF)],
              size: 18,
            ),
          ),
          _Option(
            icon: Icons.image_outlined,
            colors: const [Color(0xFFFF7AD9), Color(0xFF9D7BFF)],
            title: l10n.mediaShareCard,
            onTap: () => Navigator.pop(context, _ShareChoice.card),
          ),
          _Option(
            icon: Icons.insert_drive_file_outlined,
            colors: const [Color(0xFF3EE0FF), mint],
            title: l10n.shareFitFile,
            subtitle: l10n.shareFitFileHint,
            onTap: () => Navigator.pop(context, _ShareChoice.fitFile),
          ),
          if (share.canSendToGarmin(activity.source))
            _Option(
              icon: Icons.watch_outlined,
              colors: const [Color(0xFF6FA8FF), Color(0xFF3EE0FF)],
              title: l10n.sendToGarmin,
              subtitle: l10n.sendToGarminHint,
              onTap: () => Navigator.pop(context, _ShareChoice.garmin),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  final id = activity.activityId;
  await runUiAction(context, () async {
    switch (choice) {
      case _ShareChoice.card:
        await shareCard();
      case _ShareChoice.fitFile:
        final path = await share.fitFile(id);
        if (context.mounted) await shareRecordingFile(context, path);
      case _ShareChoice.garmin:
        final result = await share.sendToGarmin(id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result == GarminSendResult.sent
                  ? l10n.sentToGarmin
                  : l10n.alreadyOnGarmin,
            ),
          ),
        );
    }
  });
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.colors,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final List<Color> colors;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.fromBorderSide(fjEdge(colors)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        for (final c in colors) c.withValues(alpha: .22),
                      ],
                    ),
                  ),
                  child: Icon(icon, size: 19, color: fjAccent(colors.first)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: fjInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: fjInk38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
