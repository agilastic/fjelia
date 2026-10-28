import '../l10n/formats.dart';
import '../l10n/l10n_ext.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/hrv_training_episode.dart';
import '../models/spot_hrv.dart';
import '../db/database.dart';
import '../providers/hrv_reminder_provider.dart';
import '../providers/polar_h10_provider.dart';
import '../providers/spot_hrv_provider.dart';
import 'app_widgets.dart';

class PolarH10HrvSheet extends ConsumerStatefulWidget {
  const PolarH10HrvSheet({super.key, this.sensor, this.launch});
  final PolarH10Service? sensor;

  /// Set when opened from a workout or a reminder: the role, the protocol of
  /// the matching pre measurement and the real end of the workout.
  final HrvLaunchContext? launch;
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

  // What the recording was made under, frozen when it started. Changing a
  // control afterwards cannot rewrite how a captured recording was done.
  SpotHrvContext? capturedContext;
  SpotHrvPosture? capturedPosture;
  late final ProviderContainer _container;
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
    _container = ProviderScope.containerOf(context, listen: false);
    final launch = widget.launch;
    if (launch != null) {
      contextType = launch.role == HrvRole.post
          ? SpotHrvContext.afterTraining
          : SpotHrvContext.beforeTraining;
      posture = SpotHrvPosture.values.firstWhere(
        (p) => p.name == launch.posture,
        orElse: () => SpotHrvPosture.seated,
      );
      if (launch.durationSeconds == 120 || launch.durationSeconds == 300) {
        duration = launch.durationSeconds!;
      }
    }
    // One capture at a time: a notification action must not open a second.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _container.read(hrvCaptureActiveProvider.notifier).state = true;
      }
    });
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
        _fail(context.l10n.measurementInterruptedWhileTheApp);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final container = _container;
    Future.microtask(() {
      try {
        container.read(hrvCaptureActiveProvider.notifier).state = false;
      } catch (_) {
        // The whole app scope was torn down first; nothing is left to clear.
      }
    });
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
          error = context.l10n.noPolarH10FoundWear;
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
      setState(() => error = context.l10n.enterMinutesSinceTrainingEnded);
      return;
    }
    setState(() {
      capturedContext = contextType;
      capturedPosture = posture;
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
        _fail(context.l10n.noRecentRrDataWith);
        return;
      }
      setState(() => elapsed = clock.elapsed);
      if (capture!.complete(elapsed)) {
        timer?.cancel();
        clock.stop();
        // Wall clock against the monotonic clock: a jump during the recording
        // keeps the RR timing but not the absolute time.
        capture!.checkClock(DateTime.now(), clock.elapsed);
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
            context: capturedContext ?? contextType,
            posture: capturedPosture ?? posture,
            device: device!,
            elapsed: elapsed,
            notes: notes.text,
            // The athlete's own figure, kept apart from the computed delay.
            // With the real workout end known there is nothing to enter.
            minutesAfterTraining: widget.launch?.workoutEnd != null
                ? null
                : int.tryParse(afterMinutes.text.trim()),
            launch: _launchFor(capturedContext ?? contextType),
          );
      if (mounted) setState(() => saved = true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// The launch link only applies to a recording made in the launched role.
  HrvLaunchContext? _launchFor(SpotHrvContext made) {
    final launch = widget.launch;
    if (launch == null) return null;
    final fits = launch.role == HrvRole.post
        ? made == SpotHrvContext.afterTraining
        : made == SpotHrvContext.beforeTraining;
    return fits ? launch : null;
  }

  /// Minutes between the real end of the workout and the sampling start,
  /// shown while measuring. Computed, never typed.
  String? _delayText() {
    final end = widget.launch?.workoutEnd;
    final started = capture?.measurementStartedAt;
    if (end == null) return null;
    final at = started ?? DateTime.now().add(const Duration(seconds: 60));
    final minutes = at.difference(end).inMinutes;
    return minutes < 0
        ? null
        : started == null
        ? context.l10n.samplingWouldStartMinutes(minutes)
        : context.l10n.samplingStartedMinutes(minutes);
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
      title: context.l10n.polarH10SpotHrv,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        children: [
          Text(context.l10n.aSeparateHrvReadingBefore),
          const SizedBox(height: 12),
          Text(
            context.l10n.wearTheStrapWithMoist,
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<SpotHrvContext>(
            initialValue: contextType,
            decoration: InputDecoration(labelText: context.l10n.measurement),
            items: [
              for (final value in SpotHrvContext.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: locked || widget.launch != null
                ? null
                : (value) => setState(() => contextType = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SpotHrvPosture>(
            initialValue: posture,
            decoration: InputDecoration(labelText: context.l10n.posture),
            items: [
              for (final value in SpotHrvPosture.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: locked
                ? null
                : (value) => setState(() => posture = value!),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: duration,
            decoration: InputDecoration(
              labelText: context.l10n.recordingLengthPlus1Min,
            ),
            items: [
              DropdownMenuItem(value: 120, child: Text(context.l10n.t2Minutes)),
              DropdownMenuItem(value: 300, child: Text(context.l10n.t5Minutes)),
            ],
            onChanged: locked
                ? null
                : (value) => setState(() => duration = value!),
          ),
          if (contextType == SpotHrvContext.afterTraining &&
              widget.launch?.workoutEnd != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _delayText() ?? context.l10n.timingFollowsYourWorkout,
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            )
          else if (contextType == SpotHrvContext.afterTraining)
            TextField(
              controller: afterMinutes,
              enabled: !locked,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.minutesSinceTrainingEndedOptional,
              ),
            ),
          TextField(
            controller: notes,
            enabled: !locked,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: context.l10n.sessionOrNotesOptional,
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
                label: Text(context.l10n.connectName(paired.name)),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton.icon(
              onPressed: busy ? null : _scan,
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(context.l10n.findPolarH10),
            ),
            for (final found in devices)
              ListTile(
                title: Text(found.name),
                subtitle: Text(context.l10n.signalRssiDbm(found.rssi)),
                trailing: const Icon(Icons.chevron_right),
                enabled: !busy,
                onTap: () => _connect(found),
              ),
          ],
          if (connected && !running) ...[
            Text(
              context.l10n.connectedName(device!.name),
              style: const TextStyle(color: mint),
            ),
            if (!ready)
              Text(
                context.l10n.waitingForHeartRateAnd,
                style: TextStyle(color: muted),
              ),
            FilledButton(
              onPressed: ready ? _start : null,
              child: Text(context.l10n.startMeasurement),
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
                        ? context.l10n.settlingStayStill
                        : context.l10n.recordingStayStill,
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
                    child: Text(context.l10n.cancelMeasurement),
                  ),
                ],
              ),
            ),
          if (result?.rmssdMs != null) ...[
            SectionLabel(context.l10n.spotHrvRmssd),
            Row(
              children: [
                metric(context.l10n.rmssdMs, result!.rmssdMs!.fixed(1)),
                metric(context.l10n.sdnnMs, valueText(result.sdnnMs, 1)),
                metric(context.l10n.meanHrBpm, valueText(result.meanHr, 1)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.acceptedLengthUsableIntervalsTostringasfixed(
                result.accepted,
                result.samples.length,
                (result.coverage * 100).fixed(0),
              ),
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            Text(
              context.l10n.lnrmssdLnrmssdRawRmssdRawrmssdms(
                valueText(result.lnRmssd, 2),
                valueText(result.rawRmssdMs, 1),
              ),
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
              Text(
                context.l10n.signalQualityIsTooLow,
                style: TextStyle(color: Colors.orangeAccent),
              ),
            if (saved) ...[
              Text(
                context.l10n.savedToSpotHrvHistory,
                style: TextStyle(color: mint),
              ),
              if (capturedContext == SpotHrvContext.beforeTraining)
                const _ReminderOffer(),
            ] else
              FilledButton(
                onPressed: busy || !capture!.analysis.reliable ? null : _save,
                child: Text(context.l10n.saveMeasurement),
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
              child: Text(context.l10n.newMeasurement),
            ),
          ],
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              context.l10n.signalScreeningExcludesPoorContact,
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ),
          SectionLabel(
            context.l10n.historyLabelLabel2DurationMin(
              contextType.label,
              posture.label,
              duration ~/ 60,
            ),
          ),
          Text(
            context.l10n.onlyReadingsWithTheSame,
            style: TextStyle(fontSize: 11, color: muted),
          ),
          ref
              .watch(spotHrvProvider)
              .when(
                loading: () => Center(child: CircularProgressIndicator()),
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
                    return Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        context.l10n.noMatchingMeasurementsYet,
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
                            context.l10n
                                .tostringasfixedMsRmssdTostringasfixed2Bpm(
                                  row.rmssdMs.fixed(1),
                                  row.meanHr.fixed(0),
                                ),
                          ),
                          subtitle: Text(
                            '${DateFormat.MMMd().add_Hm().format(row.startedAt)}${row.minutesAfterTraining == null ? '' : ' · ${row.minutesAfterTraining} min after training'}${row.notes == null ? '' : '\n${row.notes}'}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'csv') {
                                await _export(row);
                                return;
                              }
                              if (await confirmAction(
                                    context,
                                    context.l10n.deleteSpotHrvMeasurement,
                                    context.l10n.thisRemovesTheRecordingAnd,
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
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'csv',
                                child: Text(context.l10n.exportRrIntervalsCsv),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(context.l10n.deleteMeasurement),
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

/// After a first pre-training reading: an optional, contextual offer to be
/// reminded after the workout. Permission is asked only if the athlete taps.
class _ReminderOffer extends ConsumerWidget {
  const _ReminderOffer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(hrvReminderStatusProvider).valueOrNull;
    if (status == null || status.enabled) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: () => ref.read(hrvReminderActionsProvider).setEnabled(true),
        icon: const Icon(Icons.notifications_active_outlined),
        label: Text(context.l10n.remindMeToMeasureHrv),
      ),
    );
  }
}
