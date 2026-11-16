import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_ext.dart';
import '../providers/bp_monitor_provider.dart';
import '../providers/device_actions_provider.dart';
import '../providers/omron_ble_provider.dart';
import '../services/omron_ble_service.dart';
import '../theme/fjelia_style.dart';
import 'app_widgets.dart';
import 'hilo_cuff_measurement_sheet.dart';
import 'omron_ble_import_sheet.dart';

/// The blood-pressure pair of Fjelia Aurora: pink to orange.
const _bpAccent = [Color(0xFFFF5A7A), Color(0xFFFF9A5A)];

String _modelLabel(BuildContext context, BpMonitor m) {
  final l = context.l10n;
  final how = m.live ? l.bpMonitorLive : l.bpMonitorMemory;
  final model = m.live
      ? 'Hilo'
      : m.model == null || m.model == standardBpModel
      ? l.bpMonitorStandard
      : m.model!;
  return '$model · $how';
}

/// Settings → Connections: the Hilo cuff and each Omron or standard
/// monitor as an entry of its own, made like the other connections.
class BpConnectionTiles extends ConsumerWidget {
  const BpConnectionTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final monitors = ref.watch(bpMonitorsProvider).valueOrNull ?? const [];
    final cuff = monitors.where((m) => m.live).firstOrNull;
    final memory = [
      for (final m in monitors)
        if (!m.live) m,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConnectionTile(
          key: const ValueKey('bp-connection-hilo'),
          label: l.bpMonitorKindHiloCuff,
          detail: cuff?.name,
          onTap: () => showAppSheet(
            context,
            const AddBpMonitorSheet(initialKind: 'hilo'),
          ),
          remove: cuff == null
              ? null
              : () => ref.read(bpMonitorActionsProvider).remove(cuff),
        ),
        for (final m in memory)
          _ConnectionTile(
            key: ValueKey('bp-connection-${m.id}'),
            label: m.name,
            detail: _modelLabel(context, m),
            onTap: () => showAppSheet(
              context,
              const AddBpMonitorSheet(initialKind: 'memory'),
            ),
            remove: () => ref.read(bpMonitorActionsProvider).remove(m),
          ),
        // Always there, so another Omron or standard monitor can be added.
        _ConnectionTile(
          key: const ValueKey('bp-connection-add'),
          label: l.bpMonitorKindOmron,
          onTap: () => showAppSheet(
            context,
            const AddBpMonitorSheet(initialKind: 'memory'),
          ),
        ),
      ],
    );
  }
}

/// One connection, as in Settings → Connections: a link icon, the name, its
/// state, and "Connect" or "Disconnect".
class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    super.key,
    required this.label,
    required this.onTap,
    this.detail,
    this.remove,
  });
  final String label;
  final String? detail;
  final VoidCallback onTap;
  final Future<void> Function()? remove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final connected = remove != null;
    return SectionCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(Icons.link, color: connected ? mint : muted),
        title: Text(label),
        subtitle: Text(
          detail ?? (connected ? l.connected : l.notConnected),
          style: TextStyle(color: muted, fontSize: 10),
        ),
        trailing: connected
            ? TextButton(
                onPressed: () async {
                  if (await confirmAction(
                        context,
                        l.disconnectLabel(label),
                        l.yourSavedMeasurementsWillRemain,
                      ) &&
                      context.mounted) {
                    await runUiAction(context, remove!);
                  }
                },
                child: Text(
                  l.disconnect,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                ),
              )
            : Text(
                l.connect,
                style: const TextStyle(color: mint, fontSize: 11),
              ),
        onTap: onTap,
      ),
    );
  }
}

/// A monitor as the tile head of a metric card: a tinted circle, the name
/// and how it measures.
class _MonitorRow extends StatelessWidget {
  const _MonitorRow({
    super.key,
    required this.monitor,
    this.trailing,
    this.onTap,
  });
  final BpMonitor monitor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _bpAccent.first.withValues(alpha: .16),
            ),
            child: Icon(
              monitor.live
                  ? Icons.bluetooth_rounded
                  : Icons.monitor_heart_outlined,
              size: 14,
              color: fjAccent(_bpAccent.first),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monitor.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fjInk,
                  ),
                ),
                Text(
                  _modelLabel(context, monitor),
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

/// Adds a monitor: its kind, a search, the device and, for Omron, the exact
/// model.
class AddBpMonitorSheet extends ConsumerStatefulWidget {
  const AddBpMonitorSheet({super.key, this.initialKind = 'memory'});

  /// `hilo` or `memory`: which kind the sheet starts with.
  final String initialKind;

  @override
  ConsumerState<AddBpMonitorSheet> createState() => _AddState();
}

class _AddState extends ConsumerState<AddBpMonitorSheet> {
  late String kind = widget.initialKind;
  bool busy = false, searched = false;
  List<NearbyDevice> cuffs = [];
  List<OmronFoundDevice> monitors = [];
  String? chosen;
  String? model;

  Future<void> _search() async {
    setState(() {
      busy = true;
      searched = false;
      chosen = null;
      cuffs = [];
      monitors = [];
    });
    await runUiAction(context, () async {
      if (kind == 'hilo') {
        final found = await ref
            .read(deviceActionsProvider)
            .scan(DeviceRole.cuff);
        if (!mounted) return;
        setState(() {
          cuffs = found;
          chosen = found.firstOrNull?.mac;
        });
      } else {
        final service = ref.read(omronBleServiceProvider);
        final found = await service.scan();
        final first = found.firstOrNull;
        final remembered = first == null
            ? null
            : await service.pairedModel(first.id);
        if (!mounted) return;
        setState(() {
          monitors = found;
          chosen = first?.id;
          model = _modelFor(first, remembered);
        });
      }
    });
    if (mounted) {
      setState(() {
        busy = false;
        searched = true;
      });
    }
  }

  static String? _modelFor(OmronFoundDevice? d, String? remembered) => d == null
      ? null
      : d.advertisesStandardBp
      ? standardBpModel
      : omronModelProfiles.any((p) => p.model == remembered)
      ? remembered
      : null;

  Future<void> _save() async {
    final id = chosen;
    if (id == null) return;
    setState(() => busy = true);
    await runUiAction(context, () async {
      if (kind == 'hilo') {
        await ref
            .read(deviceActionsProvider)
            .pair(DeviceRole.cuff, cuffs.firstWhere((d) => d.mac == id));
        ref.read(bpMonitorActionsProvider).refresh();
      } else {
        final d = monitors.firstWhere((d) => d.id == id);
        await ref
            .read(bpMonitorActionsProvider)
            .save(
              BpMonitor(
                kind: 'memory',
                id: d.id,
                name: d.name,
                model: model ?? standardBpModel,
              ),
            );
      }
      if (mounted) Navigator.of(context).maybePop();
    });
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final found = kind == 'hilo'
        ? [for (final d in cuffs) (d.mac, d.name, d.rssi)]
        : [for (final d in monitors) (d.id, d.name, d.rssi)];
    return SheetPage(
      title: l.bpMonitorAdd,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          SectionCard(
            accent: _bpAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'memory',
                      label: Text(l.bpMonitorKindMemory),
                    ),
                    const ButtonSegment(value: 'hilo', label: Text('Hilo')),
                  ],
                  selected: {kind},
                  onSelectionChanged: busy
                      ? null
                      : (v) => setState(() {
                          kind = v.first;
                          searched = false;
                          chosen = null;
                        }),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const ValueKey('bp-monitor-search'),
                  onPressed: busy ? null : _search,
                  icon: const Icon(Icons.bluetooth_searching_rounded),
                  label: Text(busy ? l.scanning : l.bpMonitorSearch),
                ),
                if (busy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 3),
                ],
                if (searched && found.isEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l.bpMonitorNoneFound,
                    style: TextStyle(fontSize: 13, color: fjInk70),
                  ),
                ],
                if (found.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  FigureLabel(l.bpMonitorFound),
                  const SizedBox(height: 4),
                  RadioGroup<String>(
                    groupValue: chosen,
                    onChanged: (v) async {
                      if (busy || v == null) return;
                      final d = monitors.where((m) => m.id == v).firstOrNull;
                      final remembered = d == null
                          ? null
                          : await ref
                                .read(omronBleServiceProvider)
                                .pairedModel(d.id);
                      if (!mounted) return;
                      setState(() {
                        chosen = v;
                        if (d != null) model = _modelFor(d, remembered);
                      });
                    },
                    child: Column(
                      children: [
                        for (final (id, name, rssi) in found)
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: id,
                            title: Text(name),
                            subtitle: Text(
                              '$rssi dBm',
                              style: TextStyle(fontSize: 12, color: muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (kind == 'memory' && found.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: model ?? standardBpModel,
                    decoration: InputDecoration(labelText: l.bpMonitorModel),
                    items: [
                      DropdownMenuItem(
                        value: standardBpModel,
                        child: Text(
                          l.bpMonitorStandard,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      for (final p in omronModelProfiles)
                        DropdownMenuItem(
                          value: p.model,
                          child: Text(
                            '${p.model} · ${p.alias}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: busy ? null : (v) => setState(() => model = v),
                  ),
                ],
                const SizedBox(height: 16),
                // The sheet's one action.
                FilledButton(
                  key: const ValueKey('bp-monitor-save'),
                  onPressed: busy || chosen == null ? null : _save,
                  child: Text(l.save),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "+" → blood pressure via Bluetooth: one monitor goes straight to its
/// measurement, several are offered first, none leads to adding one.
class BpMeasureSheet extends ConsumerStatefulWidget {
  const BpMeasureSheet({super.key});

  @override
  ConsumerState<BpMeasureSheet> createState() => _MeasureState();
}

class _MeasureState extends ConsumerState<BpMeasureSheet> {
  BpMonitor? chosen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final monitors = ref.watch(bpMonitorsProvider);
    final list = monitors.valueOrNull;
    final monitor = chosen ?? (list?.length == 1 ? list!.single : null);
    if (monitor != null) {
      return monitor.live
          ? const HiloCuffMeasurementSheet()
          : OmronBleImportSheet(
              deviceId: monitor.id,
              deviceName: monitor.name,
              model: monitor.model,
            );
    }
    return SheetPage(
      title: l.plusBpBle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (list == null)
            const Center(child: CircularProgressIndicator())
          else
            SectionCard(
              title: list.isEmpty ? l.bpMonitorsTitle : l.bpMonitorChoose,
              accent: _bpAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (list.isEmpty) ...[
                    Text(
                      l.bpMonitorsNone,
                      style: TextStyle(fontSize: 13, color: fjInk70),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          showAppSheet(context, const AddBpMonitorSheet()),
                      child: Text(l.bpMonitorAdd),
                    ),
                  ],
                  for (final m in list)
                    _MonitorRow(
                      key: ValueKey('bp-monitor-${m.id}'),
                      monitor: m,
                      onTap: () => setState(() => chosen = m),
                      trailing: Icon(Icons.chevron_right, color: muted),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
