import 'package:fjelia_sync/fjelia_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/nearby_sync_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/settings_widgets.dart';

/// Settings → System → Computers: the computers this phone syncs with, and
/// pairing a new one by its QR code.
class ComputersPage extends ConsumerWidget {
  const ComputersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final peers = ref.watch(syncPeersProvider).value ?? const <SyncPeer>[];
    final status = ref.watch(nearbySyncProvider);
    return SettingsPage(
      title: l10n.syncComputers,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsGroup(
            dividerIndent: 58,
            footer: l10n.syncComputersFooter,
            children: [
              if (peers.isEmpty) ListTile(title: Text(l10n.syncNoComputers)),
              for (final peer in peers)
                ListTile(
                  leading: const SettingsIcon(Icons.computer, Colors.indigo),
                  title: Text(peer.name),
                  subtitle: _statusText(l10n, status[peer.deviceId]),
                  trailing: _PeerMenu(peer),
                ),
              ListTile(
                leading: const SettingsIcon(Icons.qr_code_scanner, mint),
                title: Text(l10n.syncPairComputer),
                onTap: () => _pair(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget? _statusText(AppLocalizations l10n, NearbySyncStatus? s) =>
      switch (s) {
        null => null,
        NearbySyncing(:final sent) => Text(l10n.syncInProgress(sent)),
        NearbySynced(:final sent, :final received) => Text(
          received == 0
              ? l10n.syncDone(sent)
              : l10n.syncDoneBoth(sent, received),
        ),
        NearbySyncFailed(:final problem) => Text(
          problemText(l10n, problem),
          style: const TextStyle(color: Colors.red),
        ),
      };

  static String problemText(AppLocalizations l10n, NearbySyncProblem p) =>
      switch (p) {
        NearbySyncProblem.unreachable => l10n.syncUnreachable,
        NearbySyncProblem.codeExpired => l10n.syncCodeExpired,
        NearbySyncProblem.updateBoth => l10n.syncUpdateBoth,
        NearbySyncProblem.pairAgain => l10n.syncPairAgain,
      };

  Future<void> _pair(BuildContext context, WidgetRef ref) async {
    final offer = await Navigator.of(context).push<PairingOffer>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _ScanPage(),
      ),
    );
    if (offer == null) return;
    final problem = await ref.read(nearbySyncProvider.notifier).pair(offer);
    if (problem != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(problemText(context.l10n, problem))),
      );
    }
  }
}

class _PeerMenu extends ConsumerWidget {
  const _PeerMenu(this.peer);
  final SyncPeer peer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sync = ref.read(nearbySyncProvider.notifier);
    return PopupMenuButton<void Function()>(
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        PopupMenuItem(value: () => sync.sync(peer), child: Text(l10n.syncNow)),
        PopupMenuItem(
          value: () => _unpair(context, ref),
          child: Text(l10n.syncUnpair),
        ),
      ],
    );
  }

  Future<void> _unpair(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.syncUnpairTitle(peer.name)),
        content: Text(l10n.syncUnpairMessage(peer.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(
              l10n.syncUnpair,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (sure == true) await ref.read(nearbySyncProvider.notifier).unpair(peer);
  }
}

/// The camera, until it sees a Fjelia pairing code.
class _ScanPage extends StatefulWidget {
  const _ScanPage();
  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  bool _done = false;
  String? _rejected;

  void _detect(BarcodeCapture capture) {
    if (_done) return;
    for (final code in capture.barcodes) {
      final text = code.rawValue;
      if (text == null) continue;
      final offer = PairingOffer.parse(text);
      if (offer != null) {
        _done = true;
        Navigator.pop(context, offer);
        return;
      }
      if (text != _rejected) setState(() => _rejected = text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncPairComputer)),
      body: Column(
        children: [
          Expanded(child: MobileScanner(onDetect: _detect)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _rejected != null ? l10n.syncNotAPairingCode : l10n.syncScanHint,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
