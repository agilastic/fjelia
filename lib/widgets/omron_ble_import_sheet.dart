import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../l10n/l10n_ext.dart';
import '../providers/database_provider.dart';
import '../providers/day_data_provider.dart';
import '../services/omron_ble_service.dart';
import '../theme/fjelia_style.dart';
import 'app_widgets.dart';

class OmronBleImportSheet extends ConsumerStatefulWidget {
  const OmronBleImportSheet({super.key});

  @override
  ConsumerState<OmronBleImportSheet> createState() => _OmronBleImportState();
}

class _OmronBleImportState extends ConsumerState<OmronBleImportSheet> {
  final service = OmronBleService();
  List<OmronFoundDevice> devices = [];
  List<OmronBpRecord> readings = [];
  String? model;
  String? deviceId;
  String status = '';
  String? error;
  bool busy = false;
  int? savedCount;
  Set<int> selectedReadingIndices = {};

  bool get german => Localizations.localeOf(context).languageCode == 'de';

  Future<void> scan() async {
    setState(() {
      busy = true;
      error = null;
      status = german
          ? 'Suche Bluetooth-Blutdruckgeräte…'
          : 'Scanning for Bluetooth blood-pressure monitors…';
      devices = [];
      deviceId = null;
      readings = [];
      selectedReadingIndices = {};
      savedCount = null;
    });
    try {
      final found = await service.scan();
      if (!mounted) return;
      final selectedDevice = found.isEmpty ? null : found.first;
      final preferred = selectedDevice == null
          ? null
          : selectedDevice.advertisesStandardBp
          ? standardBpModel
          : await service.pairedModel(selectedDevice.id);
      setState(() {
        devices = found;
        if (found.isNotEmpty) {
          deviceId = found.first.id;
          if (preferred == standardBpModel ||
              omronModelProfiles.any((p) => p.model == preferred)) {
            model = preferred!;
          } else {
            model = null;
          }
        }
        status = found.isEmpty
            ? (german
                  ? 'Keine BLE-Geräte gefunden. Bluetooth aktivieren und das Messgerät einschalten.'
                  : 'No BLE devices found. Turn on Bluetooth and the monitor.')
            : '';
      });
    } catch (e) {
      if (mounted) setState(() => error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> import() async {
    final id = deviceId;
    final selectedModel = model;
    if (id == null) return;
    final mustPair = selectedModel == null
        ? false
        : await service.needsPairing(id, selectedModel);
    if (!mounted) return;
    var authorized = !mustPair;
    if (mustPair) {
      authorized =
          await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(
                german
                    ? 'Omron erstmalig koppeln?'
                    : 'Pair this Omron monitor?',
              ),
              content: Text(
                german
                    ? 'Versetze das Gerät in den Bluetooth-Kopplungsmodus (meist blinkt „-P-“). Die Kopplung kann die Verbindung zur Omron-App ersetzen. Fjelia liest nur Messwerte und ändert weder Uhr noch Messzähler.'
                    : 'Put the monitor into Bluetooth pairing mode (often shown as blinking “-P-”). Pairing may replace its connection to the Omron app. Fjelia only reads measurements; it will not change the clock or reading counter.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(
                    german ? 'Koppeln und importieren' : 'Pair and import',
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!authorized) return;
    setState(() {
      busy = true;
      error = null;
      savedCount = null;
      readings = [];
      selectedReadingIndices = {};
    });
    try {
      final records = await service.readRecords(
        deviceId: id,
        model: selectedModel,
        authorizeFirstPairing: authorized,
        onStatus: (value) {
          if (mounted) setState(() => status = value);
        },
      );
      if (!mounted) return;
      setState(() {
        readings = records;
        selectedReadingIndices = {for (var i = 0; i < records.length; i++) i};
        status = german
            ? '${records.length} Messungen gefunden. Wähle aus, was importiert werden soll.'
            : '${records.length} readings found. Choose which ones to import.';
      });
    } catch (e) {
      if (mounted) setState(() => error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> saveSelectedReadings() async {
    if (selectedReadingIndices.isEmpty || savedCount != null) return;
    final selectedModel = model;
    final selected = [
      for (var i = 0; i < readings.length; i++)
        if (selectedReadingIndices.contains(i)) readings[i],
    ];
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final count = await ref.read(databaseProvider).insertBpMeasurements([
        for (final r in selected)
          BpMeasurementsCompanion.insert(
            measuredAt: r.measuredAt,
            systolic: r.systolic,
            diastolic: r.diastolic,
            heartRate: r.heartRate,
            measurementType: Value(
              selectedModel == null || selectedModel == standardBpModel
                  ? 'BLE_STANDARD'
                  : 'OMRON',
            ),
          ),
      ]);
      ref.read(syncStatusListenerProvider.notifier).state++;
      setState(() {
        savedCount = count;
        status = german
            ? '$count neue Messungen gespeichert'
            : '$count new readings saved';
      });
    } catch (e) {
      if (mounted) setState(() => error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SheetPage(
    title: german ? 'Blutdruck über BLE' : 'Bluetooth BP',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Icon(Icons.monitor_heart_rounded, size: 76, color: mint),
        const SizedBox(height: 16),
        Text(
          german
              ? 'Bluetooth-Blutdruckgeräte suchen'
              : 'Find Bluetooth blood-pressure monitors',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          german
              ? 'Fjelia sucht nach Standard-Bluetooth-Geräten und unterstützten Omron-Profilen.'
              : 'Fjelia scans for standard Bluetooth devices and supported Omron profiles.',
          textAlign: TextAlign.center,
          style: TextStyle(color: fjInk70, height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          german
              ? 'Angekündigte Bluetooth-Dienste geben einen ersten Hinweis; Fjelia prüft die GATT-Dienste beim Verbinden. Bei Omron-Profilen muss das genaue Modell passen.'
              : 'Advertised Bluetooth services are only a first hint; Fjelia checks GATT services when connecting. Omron profiles require the exact model.',
          textAlign: TextAlign.center,
          style: TextStyle(color: fjInk70, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: model,
          decoration: InputDecoration(
            labelText: german ? 'Gerätemodell' : 'Monitor model',
            hintText: german
                ? 'Modellnummer auswählen'
                : 'Select exact model number',
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: standardBpModel,
              child: Text(
                german
                    ? 'Standard-Bluetooth-Blutdruckgerät'
                    : 'Standard Bluetooth blood-pressure monitor',
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
          onChanged: busy ? null : (value) => setState(() => model = value),
        ),
        const SizedBox(height: 12),
        if (devices.isNotEmpty)
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: deviceId,
            decoration: InputDecoration(
              labelText: german ? 'Gefundenes BLE-Gerät' : 'Found BLE device',
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final d in devices)
                DropdownMenuItem(
                  value: d.id,
                  child: Text(
                    '${d.name} · ${_compatibilityLabel(d)} · ${d.rssi} dBm · ${d.id.substring(0, d.id.length.clamp(0, 8))}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            selectedItemBuilder: (context) => [
              for (final d in devices)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${d.name} · ${_compatibilityLabel(d)} · ${d.rssi} dBm',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: busy
                ? null
                : (value) async {
                    final preferred = value == null
                        ? null
                        : await service.pairedModel(value);
                    if (!mounted) return;
                    setState(() {
                      deviceId = value;
                      final selected = devices.where((d) => d.id == value);
                      if (selected.isNotEmpty &&
                          selected.first.advertisesStandardBp) {
                        model = standardBpModel;
                      } else if (omronModelProfiles.any(
                        (p) => p.model == preferred,
                      )) {
                        model = preferred!;
                      } else {
                        model = null;
                      }
                    });
                  },
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : scan,
          icon: const Icon(Icons.bluetooth_searching),
          label: Text(
            german
                ? 'BLE-Blutdruckgeräte suchen'
                : 'Search BLE blood-pressure monitors',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed:
              busy ||
                  deviceId == null ||
                  (readings.isNotEmpty &&
                      (selectedReadingIndices.isEmpty || savedCount != null))
              ? null
              : readings.isEmpty
              ? import
              : saveSelectedReadings,
          icon: const Icon(Icons.download_rounded),
          label: Text(
            readings.isNotEmpty
                ? german
                      ? '${selectedReadingIndices.length} ausgewählte Messungen importieren'
                      : 'Import ${selectedReadingIndices.length} selected readings'
                : model == null
                ? german
                      ? 'Gerät prüfen und Messwerte lesen'
                      : 'Check device and read measurements'
                : german
                ? 'Messwerte abrufen'
                : 'Read measurements',
          ),
        ),
        if (busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(minHeight: 4),
        ],
        if (status.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(color: fjInk70),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ],
        if (readings.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SectionLabel(
                  savedCount == null
                      ? german
                            ? 'MESSUNGEN ZUM IMPORT'
                            : 'READINGS TO IMPORT'
                      : german
                      ? 'LETZTE MESSUNGEN'
                      : 'LATEST READINGS',
                ),
              ),
              if (savedCount == null)
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          selectedReadingIndices =
                              selectedReadingIndices.length == readings.length
                              ? <int>{}
                              : {for (var i = 0; i < readings.length; i++) i};
                        }),
                  child: Text(
                    selectedReadingIndices.length == readings.length
                        ? german
                              ? 'Keine'
                              : 'None'
                        : german
                        ? 'Alle'
                        : 'All',
                  ),
                ),
            ],
          ),
          for (var i = 0; i < readings.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: savedCount == null
                  ? Checkbox(
                      value: selectedReadingIndices.contains(i),
                      onChanged: busy
                          ? null
                          : (selected) => setState(() {
                              if (selected == true) {
                                selectedReadingIndices.add(i);
                              } else {
                                selectedReadingIndices.remove(i);
                              }
                            }),
                    )
                  : null,
              title: Text(
                '${readings[i].systolic}/${readings[i].diastolic} mmHg'
                '${readings[i].heartRate > 0 ? '  ·  ${readings[i].heartRate} bpm' : ''}',
              ),
              subtitle: Text(
                '${readings[i].measuredAt.toLocal()} · ${german ? 'Nutzer' : 'User'} ${readings[i].user}',
              ),
              trailing: readings[i].irregularPulse
                  ? const Icon(Icons.favorite, color: Colors.orange)
                  : null,
              onTap: savedCount != null || busy
                  ? null
                  : () => setState(() {
                      if (selectedReadingIndices.contains(i)) {
                        selectedReadingIndices.remove(i);
                      } else {
                        selectedReadingIndices.add(i);
                      }
                    }),
            ),
        ],
      ],
    ),
  );

  String _compatibilityLabel(OmronFoundDevice device) =>
      switch (device.advertisedCompatibility) {
        'standard' => german ? 'Standarddienst' : 'Standard service',
        'omron' => german ? 'Omron-Protokoll' : 'Omron protocol',
        _ => german ? 'noch ungeprüft' : 'not verified yet',
      };
}
