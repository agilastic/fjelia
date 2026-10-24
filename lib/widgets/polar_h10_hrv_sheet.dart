import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/spot_hrv.dart';
import '../db/database.dart';
import '../providers/polar_h10_provider.dart';
import '../providers/spot_hrv_provider.dart';
import 'app_widgets.dart';

class PolarH10HrvSheet extends ConsumerStatefulWidget {
  const PolarH10HrvSheet({super.key, this.sensor});
  final PolarH10Service? sensor;
  @override
  ConsumerState<PolarH10HrvSheet> createState() => _HrvState();
}

class _HrvState extends ConsumerState<PolarH10HrvSheet>
    with WidgetsBindingObserver {
  late final PolarH10Service sensor;
  StreamSubscription<H10HeartRatePacket>? subscription;
  Timer? timer;
  final clock = Stopwatch();
  final notes = TextEditingController(), afterMinutes = TextEditingController();
  SpotHrvContext contextType = SpotHrvContext.beforeTraining;
  SpotHrvPosture posture = SpotHrvPosture.seated;
  int duration = 300;
  bool busy = false,
      connected = false,
      running = false,
      completed = false,
      saved = false;
  String? error;
  List<H10Device> devices = [];
  H10Device? device, pairedDevice;
  H10HeartRatePacket? lastPacket;
  DateTime? receivedAt, goodRrAt;
  SpotHrvCapture? capture;
  Duration elapsed = Duration.zero;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final actions = ref.read(polarH10ActionsProvider);
    sensor = widget.sensor ?? actions.createSensor();
    unawaited(
      actions.paired().then((found) {
        if (mounted) setState(() => pairedDevice = found);
      }),
    );
    subscription = sensor.packets.listen((packet) {
      if (!mounted) return;
      setState(() {
        lastPacket = packet;
        receivedAt = DateTime.now();
        if (packet.rrMs.isNotEmpty &&
            packet.contact != false &&
            packet.bpm > 0) {
          goodRrAt = receivedAt;
        }
        if (running) capture?.add(packet, clock.elapsed);
      });
    }, onError: (Object e) => _fail(e.toString()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (running) {
        _fail(
          'Measurement interrupted while the app was in the background. Please repeat it.',
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    clock.stop();
    unawaited(subscription?.cancel());
    unawaited(sensor.dispose());
    notes.dispose();
    afterMinutes.dispose();
    super.dispose();
  }

  void _fail(String message) {
    timer?.cancel();
    clock.stop();
    if (!mounted) return;
    setState(() {
      error = message;
      busy = false;
      running = false;
      connected = false;
      completed = false;
    });
    unawaited(sensor.disconnect());
  }

  Future<void> _scan() async {
    setState(() {
      busy = true;
      error = null;
      devices = [];
    });
    try {
      final found = await sensor.scan();
      if (!mounted) return;
      setState(() {
        devices = found;
        if (found.isEmpty) {
          error =
              'No Polar H10 found. Wear the strap, wet its electrodes and check that another app is not using both Bluetooth connections.';
        }
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _connect(H10Device found) async {
    setState(() {
      busy = true;
      error = null;
      lastPacket = null;
      receivedAt = null;
      goodRrAt = null;
    });
    try {
      await sensor.connect(found);
      if (mounted) {
        setState(() {
          device = found;
          connected = true;
        });
        // Remember the strap so the next measurement connects directly.
        unawaited(
          ref
              .read(polarH10ActionsProvider)
              .pair(found)
              .then<void>((_) {}, onError: (Object _) {}),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _start() {
    final minutes = afterMinutes.text.trim();
    if (contextType == SpotHrvContext.afterTraining &&
        minutes.isNotEmpty &&
        (int.tryParse(minutes) == null ||
            int.parse(minutes) < 0 ||
            int.parse(minutes) > 1440)) {
      setState(
        () => error = 'Enter minutes since training ended, from 0 to 1440.',
      );
      return;
    }
    setState(() {
      capture = SpotHrvCapture(
        startedAt: DateTime.now(),
        durationSeconds: duration,
      );
      running = true;
      completed = false;
      saved = false;
      error = null;
      elapsed = Duration.zero;
      clock
        ..reset()
        ..start();
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !running) return;
      if (goodRrAt == null ||
          DateTime.now().difference(goodRrAt!) > const Duration(seconds: 8)) {
        _fail(
          'No recent RR data with good contact. Check the strap and repeat the measurement.',
        );
        return;
      }
      setState(() => elapsed = clock.elapsed);
      if (capture!.complete(elapsed)) {
        timer?.cancel();
        clock.stop();
        setState(() {
          running = false;
          completed = true;
          connected = false;
        });
        unawaited(sensor.disconnect());
      }
    });
  }

  Future<void> _cancel() async {
    timer?.cancel();
    clock.stop();
    setState(() {
      running = false;
      connected = false;
      completed = false;
      capture = null;
      lastPacket = null;
    });
    await sensor.disconnect();
  }

  Future<void> _save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(polarH10ActionsProvider)
          .save(
            capture: capture!,
            context: contextType,
            posture: posture,
            device: device!,
            elapsed: elapsed,
            notes: notes.text,
            minutesAfterTraining: int.tryParse(afterMinutes.text.trim()),
          );
      if (mounted) setState(() => saved = true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _time(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  Widget metric(String title, String value) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: mint,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 11, color: muted)),
      ],
    ),
  );
  Future<void> _export(SpotHrvMeasurement row) =>
      runUiAction(context, () async {
        final path = await ref.read(polarH10ActionsProvider).exportCsv(row);
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      });

  @override
  Widget build(BuildContext context) {
    final result = capture?.analysis;
    final settling = running && elapsed.inSeconds < 60;
    final remaining = running
        ? (settling
              ? 60 - elapsed.inSeconds
              : duration - (elapsed.inSeconds - 60))
        : 0;
    final fresh =
        receivedAt != null &&
        DateTime.now().difference(receivedAt!) < const Duration(seconds: 5);
    final ready =
        connected &&
        fresh &&
        (lastPacket?.bpm ?? 0) > 0 &&
        lastPacket?.contact != false &&
        (lastPacket?.rrMs.isNotEmpty ?? false);
    final locked = running || completed || busy;
    return SheetPage(
      title: 'Polar H10 · Spot HRV',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        children: [
          const Text(
            'A separate HRV reading before or after training. These measurements do not replace Garmin overnight HRV or change your readiness score.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Wear the strap with moist electrodes. Keep still and breathe normally. Use the same posture and recording length for comparisons. After training, note how long you rested first.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<SpotHrvContext>(
            initialValue: contextType,
            decoration: const InputDecoration(labelText: 'Measurement'),
            items: [
              for (final value in SpotHrvContext.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: locked
                ? null
                : (value) => setState(() => contextType = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SpotHrvPosture>(
            initialValue: posture,
            decoration: const InputDecoration(labelText: 'Posture'),
            items: [
              for (final value in SpotHrvPosture.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: locked
                ? null
                : (value) => setState(() => posture = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: duration,
            decoration: const InputDecoration(
              labelText: 'Recording length · plus 1 min settling',
            ),
            items: const [
              DropdownMenuItem(value: 120, child: Text('2 minutes')),
              DropdownMenuItem(value: 300, child: Text('5 minutes')),
            ],
            onChanged: locked
                ? null
                : (value) => setState(() => duration = value!),
          ),
          if (contextType == SpotHrvContext.afterTraining)
            TextField(
              controller: afterMinutes,
              enabled: !locked,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutes since training ended (optional)',
              ),
            ),
          TextField(
            controller: notes,
            enabled: !locked,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Session or notes (optional)',
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (busy) const LinearProgressIndicator(),
          if (!connected && !running && !completed) ...[
            if (pairedDevice case final paired?) ...[
              FilledButton.icon(
                onPressed: busy ? null : () => _connect(paired),
                icon: const Icon(Icons.bluetooth_connected),
                label: Text('Connect ${paired.name}'),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton.icon(
              onPressed: busy ? null : _scan,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Find Polar H10'),
            ),
            for (final found in devices)
              ListTile(
                title: Text(found.name),
                subtitle: Text('Signal ${found.rssi} dBm'),
                trailing: const Icon(Icons.chevron_right),
                enabled: !busy,
                onTap: () => _connect(found),
              ),
          ],
          if (connected && !running) ...[
            Text(
              'Connected: ${device!.name}',
              style: const TextStyle(color: mint),
            ),
            if (!ready)
              const Text(
                'Waiting for heart rate and RR intervals. Check the strap contact.',
                style: TextStyle(color: muted),
              ),
            FilledButton(
              onPressed: ready ? _start : null,
              child: const Text('Start measurement'),
            ),
          ],
          if (connected || running)
            Text(
              'Heart rate: ${lastPacket?.bpm ?? '—'} bpm',
              style: const TextStyle(fontSize: 20),
            ),
          if (running)
            SectionCard(
              child: Column(
                children: [
                  Text(
                    settling
                        ? 'Settling · stay still'
                        : 'Recording · stay still',
                    style: const TextStyle(color: mint),
                  ),
                  Text(
                    _time(remaining.clamp(0, duration)),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  LinearProgressIndicator(
                    value: settling
                        ? elapsed.inSeconds / 60
                        : (elapsed.inSeconds - 60) / duration,
                  ),
                  TextButton(
                    onPressed: _cancel,
                    child: const Text('Cancel measurement'),
                  ),
                ],
              ),
            ),
          if (result?.rmssdMs != null) ...[
            const SectionLabel('Spot HRV · RMSSD'),
            Row(
              children: [
                metric('RMSSD · ms', result!.rmssdMs!.toStringAsFixed(1)),
                metric('SDNN · ms', valueText(result.sdnnMs, 1)),
                metric('Mean HR · bpm', valueText(result.meanHr, 1)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${result.accepted}/${result.samples.length} usable intervals · ${(result.coverage * 100).toStringAsFixed(0)}% coverage',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            Text(
              'lnRMSSD: ${valueText(result.lnRmssd, 2)} · Raw RMSSD: ${valueText(result.rawRmssdMs, 1)} ms',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            HistoryChart(
              points: [
                for (final s in result.samples)
                  ChartPoint(
                    capture!.measurementStartedAt.add(
                      Duration(milliseconds: s.elapsedMs.round()),
                    ),
                    s.rrMs,
                  ),
              ],
              height: 150,
            ),
          ],
          if (completed) ...[
            if (!capture!.analysis.reliable)
              const Text(
                'Signal quality is too low to save. Repeat the measurement with good strap contact. At least 95% usable intervals and 90% coverage are required.',
                style: TextStyle(color: Colors.orangeAccent),
              ),
            if (saved)
              const Text(
                'Saved to spot HRV history.',
                style: TextStyle(color: mint),
              )
            else
              FilledButton(
                onPressed: busy || !capture!.analysis.reliable ? null : _save,
                child: const Text('Save measurement'),
              ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      completed = false;
                      capture = null;
                      devices = [];
                      lastPacket = null;
                      saved = false;
                    }),
              child: const Text('New measurement'),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Signal screening excludes poor contact, RR outside 250–2500 ms and intervals more than 25% from the local median. Gaps are not bridged. This is not a medical test or a standalone readiness score.',
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ),
          SectionLabel(
            'History · ${contextType.label} · ${posture.label} · ${duration ~/ 60} min',
          ),
          const Text(
            'Only readings with the same context, posture and duration are shown together.',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          ref
              .watch(spotHrvProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => DataError(e),
                data: (rows) {
                  final matching = rows
                      .where(
                        (r) =>
                            r.context == contextType.name &&
                            r.posture == posture.name &&
                            r.durationSeconds == duration,
                      )
                      .toList();
                  if (matching.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No matching measurements yet.',
                        style: TextStyle(color: muted),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      HistoryChart(
                        points: [
                          for (final row in matching.reversed)
                            ChartPoint(row.startedAt, row.rmssdMs),
                        ],
                        height: 160,
                      ),
                      for (final row in matching)
                        ListTile(
                          title: Text(
                            '${row.rmssdMs.toStringAsFixed(1)} ms RMSSD · ${row.meanHr.toStringAsFixed(0)} bpm',
                          ),
                          subtitle: Text(
                            '${DateFormat('d MMM, HH:mm').format(row.startedAt)}${row.minutesAfterTraining == null ? '' : ' · ${row.minutesAfterTraining} min after training'}${row.notes == null ? '' : '\n${row.notes}'}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'csv') {
                                await _export(row);
                                return;
                              }
                              if (await confirmAction(
                                    context,
                                    'Delete spot HRV measurement?',
                                    'This removes the recording and its raw RR intervals.',
                                  ) &&
                                  context.mounted) {
                                await runUiAction(
                                  context,
                                  () => ref
                                      .read(polarH10ActionsProvider)
                                      .delete(row.id),
                                );
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'csv',
                                child: Text('Export RR intervals (CSV)'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete measurement'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
        ],
      ),
    );
  }
}
