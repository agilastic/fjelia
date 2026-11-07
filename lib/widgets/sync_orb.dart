import 'package:flutter/material.dart';

import '../theme/fjelia_style.dart';
import 'app_widgets.dart';
import 'spinning_sync_icon.dart';

/// How fresh the data is, shown as the orb's dot.
enum SyncFreshness { fresh, stale, error }

/// The sync button, plain like the other header icons. While a sync runs
/// it turns mint with a soft light behind it; a small dot tells when the
/// data is getting old or the last sync failed.
class SyncOrb extends StatelessWidget {
  const SyncOrb({super.key, required this.spinning, required this.freshness});

  final bool spinning;
  final SyncFreshness freshness;

  @override
  Widget build(BuildContext context) {
    final dot = switch (freshness) {
      SyncFreshness.fresh => null,
      SyncFreshness.stale => Colors.amber,
      SyncFreshness.error => const Color(0xFFFF5A7A),
    };
    return SizedBox.square(
      dimension: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The light fades by its colour; an Opacity layer over a blurred
          // shadow trips Impeller's validation.
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: mint.withValues(alpha: spinning ? .45 : 0),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          SpinningSyncIcon(spinning: spinning, color: spinning ? mint : muted),
          if (dot != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                  border: Border.all(color: fjBackground, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
