import '../theme/fjelia_style.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../db/database.dart' show TrainingSession;
import '../l10n/formats.dart';
import '../l10n/l10n_ext.dart';
import '../models/gym_workout.dart';
import '../providers/ecg_provider.dart';
import '../providers/indoor_recording_provider.dart';
import '../providers/polar_h10_provider.dart';
import '../theme/activity_colors.dart';
import '../utils/decimal.dart';
import 'app_widgets.dart';
import 'ecg_sheet.dart';
import 'activity_blood_pressure_card.dart';
import 'indoor_recording_widgets.dart';
import 'rowing_recording_dashboard.dart';

/// The sports, outdoor first. Indoor sports record a Bluetooth (FTMS)
/// machine; a treadmill run also works without one.
const _sports = [
  'running',
  'walking',
  'cycling',
  'treadmill_running',
  'indoor_cycling',
  'rowing',
  'nordic_skiing',
  'elliptical',
  'stair_climbing',
];
const _machines = {
  'treadmill_running': {FtmsMachine.treadmill},
  'indoor_cycling': {FtmsMachine.bike},
  'rowing': {FtmsMachine.rower},
  // A Concept2 SkiErg reports through its PM5 like a rower.
  'nordic_skiing': {FtmsMachine.rower},
  'elliptical': {FtmsMachine.crossTrainer},
  'stair_climbing': {FtmsMachine.stairClimber, FtmsMachine.stepClimber},
};

/// The paused band, as bright as a traffic sign.
const _pausedColor = Color(0xFFFFC53D);

IconData _sportIcon(String sport) => switch (sport) {
  'walking' => Icons.directions_walk_rounded,
  'cycling' => Icons.directions_bike_rounded,
  'treadmill_running' => Icons.run_circle_outlined,
  'indoor_cycling' => Icons.pedal_bike_rounded,
  'rowing' => Icons.rowing_rounded,
  'nordic_skiing' => Icons.downhill_skiing_rounded,
  'elliptical' => Icons.fitness_center_rounded,
  'stair_climbing' => Icons.stairs_rounded,
  _ => Icons.directions_run_rounded,
};

/// The indoor sport of a planned session, which needs its machine.
String _sessionSport(TrainingSession s) => switch (activityKind(s.sport)) {
  ActivityKind.cycling => 'indoor_cycling',
  ActivityKind.rowing => 'rowing',
  _ when RegExp('nordic|ski', caseSensitive: false).hasMatch(s.sport) =>
    'nordic_skiing',
  _ => 'treadmill_running',
};

/// 00:00:18, like a stopwatch.
String _clock(int ms) {
  final s = ms ~/ 1000;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(s ~/ 3600)}:${two(s ~/ 60 % 60)}:${two(s % 60)}';
}

/// Minutes and seconds per [per] metres, or --:-- when standing still.
String _pace(num? metersPerSecond, {double per = 1000}) {
  if (metersPerSecond == null || metersPerSecond < .3) return '--:--';
  final s = (per / metersPerSecond).round();
  if (s >= 3600) return '--:--';
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// One place to record any activity: outdoors with the phone, on a Bluetooth
/// machine, or a planned indoor session with its intervals. ECG, heart rate
/// and blood pressure work with all of them.
class ManualActivitySheet extends ConsumerStatefulWidget {
  const ManualActivitySheet({super.key, this.session});
  final TrainingSession? session;
  @override
  ConsumerState<ManualActivitySheet> createState() => _ManualActivityState();
}

class _ManualActivityState extends ConsumerState<ManualActivitySheet> {
  TrainingDevice? chosen;
  TrainingDevice? chosenHr;
  late String type = widget.session == null
      ? 'running'
      : _sessionSport(widget.session!);
  bool withEcg = true, busy = false, showMap = false;
  bool withHr = true, withBp = true;
  late bool withGps = !_machines.containsKey(type);
  late final IndoorRecorder recorder;
  @override
  void initState() {
    super.initState();
    recorder = ref.read(indoorRecorderProvider.notifier);
  }

  @override
  void dispose() {
    recorder.disconnectIdle();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    await runUiAction(context, action);
    if (mounted) setState(() => busy = false);
  }

  String label(BuildContext context, String sport) => switch (sport) {
    'walking' => context.l10n.walking,
    'cycling' => context.l10n.cycling,
    'treadmill_running' => context.l10n.manualTreadmill,
    'indoor_cycling' => context.l10n.sportIndoorCycling,
    'rowing' => context.l10n.rowing,
    'nordic_skiing' => context.l10n.sportSkiErg,
    'elliptical' => context.l10n.sportElliptical,
    'stair_climbing' => context.l10n.sportStairClimber,
    _ => context.l10n.running,
  };

  Future<void> chooseH10() => run(() async {
    final devices = await ref.read(ecgActionsProvider).scan();
    if (!mounted) return;
    final device = await chooseTrainingDevice(
      context,
      devices,
      title: context.l10n.manualChooseH10,
      empty: context.l10n.noDevicesFoundTapTo,
    );
    if (device == null || !mounted) return;
    setState(() => chosen = device);
    await ref.read(ecgActionsProvider).remember(device);
  });

  /// Connects [device] for the chosen sport, or scans when it is null. A
  /// machine of another kind is let go again.
  Future<void> connectMachine([TrainingDevice? device]) => run(() async {
    if (device == null) {
      final found = await ref.read(indoorActionsProvider).scanEquipment();
      if (!mounted) return;
      device = await chooseTrainingDevice(
        context,
        found,
        title: type == 'treadmill_running'
            ? context.l10n.manualTreadmillConnect
            : context.l10n.indoorChooseEquipment,
        empty: context.l10n.indoorNoEquipment,
      );
      if (device == null) return;
    }
    final wanted = _machines[type]!;
    await recorder.connect(device!, preferred: wanted.first);
    final connected = ref.read(indoorRecorderProvider);
    if (connected.connected && !wanted.contains(connected.machine)) {
      await recorder.disconnectIdle();
      throw StateError(tr.manualWrongMachine);
    }
  });

  Future<void> chooseHeartRate() => run(() async {
    final devices = await ref.read(indoorActionsProvider).scanHeartRate();
    if (!mounted) return;
    final device = await chooseTrainingDevice(
      context,
      devices,
      title: context.l10n.manualChooseHr,
      empty: context.l10n.noDevicesFoundTapTo,
    );
    if (device != null && mounted) setState(() => chosenHr = device);
  });

  Future<void> chooseSport() async {
    final state = ref.read(indoorRecorderProvider);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: duo(0xFF111111, 0xFFF2F4F7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final sport in _sports)
                ChoiceChip(
                  avatar: Icon(_sportIcon(sport), size: 18),
                  label: Text(label(context, sport)),
                  selected: sport == type,
                  showCheckmark: false,
                  selectedColor: mint.withValues(alpha: .25),
                  shape: const StadiumBorder(),
                  onSelected: (_) => Navigator.pop(sheet, sport),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    if (state.connected &&
        !(_machines[picked]?.contains(state.machine) ?? false)) {
      unawaited(recorder.disconnectIdle());
    }
    setState(() {
      type = picked;
      withGps = !_machines.containsKey(type);
    });
  }

  /// Finish: a manual activity without GPS asks for its distance first.
  Future<void> finish(IndoorCapture capture) => run(() async {
    await recorder.pause();
    if (capture.isManual && !capture.gpsEnabled) {
      if (!mounted) return;
      final meters = await _askDistance(context, capture.totals['d']);
      if (meters == null) return;
      recorder.manualDistance(meters.isNaN ? null : meters);
    }
    await recorder.finish();
  });

  Future<void> discard() => run(() async {
    final l = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(l.manualDiscardNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l.recDiscard),
          ),
        ],
      ),
    );
    if (sure == true) await recorder.discard();
  });

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(indoorRecorderProvider);
    final capture = state.capture;
    final saved = capture != null && state.phase == IndoorPhase.saved;
    final live = capture != null && state.active;
    final waiting =
        busy ||
        state.phase == IndoorPhase.starting ||
        state.phase == IndoorPhase.connecting ||
        state.phase == IndoorPhase.saving;
    return SheetPage(
      title: live || saved ? capture.name : context.l10n.manualRecordTitle,
      child: saved
          ? _savedView(context, state, capture)
          : live
          ? _liveView(context, state, capture, waiting)
          : _setupView(context, state, waiting),
    );
  }

  // ── Before the start ──────────────────────────────────────────────────

  Widget _setupView(
    BuildContext context,
    IndoorRecorderState state,
    bool waiting,
  ) {
    final l = context.l10n;
    final session = widget.session;
    final paired = ref.watch(polarH10PairedProvider).valueOrNull;
    final pairedMachine = ref.watch(indoorPairedProvider).valueOrNull;
    final device =
        chosen ??
        (paired == null
            ? null
            : TrainingDevice(id: paired.id, name: paired.name));
    final pairedHr = ref.watch(indoorHeartRatePairedProvider).valueOrNull;
    final hrDevice = chosenHr ?? pairedHr ?? device;
    final indoor = _machines.containsKey(type);
    final machineReady =
        indoor &&
        state.connected &&
        (_machines[type]?.contains(state.machine) ?? false);
    // Only a treadmill run works without its machine, and not for a plan.
    final needsMachine =
        indoor && (type != 'treadmill_running' || session != null);
    final canStart =
        !waiting &&
        !(withEcg && device == null) &&
        !(withHr && !withEcg && hrDevice == null) &&
        !(needsMachine && !machineReady);
    void start() => run(() async {
      if (machineReady) {
        if (withHr && !withEcg) await recorder.connectHeartRate(hrDevice!);
        await recorder.start(
          session: session,
          // Chosen before: a SkiErg on any PM5 firmware saves as skiing.
          activityType: type == 'nordic_skiing' ? type : null,
          ecgDevice: withEcg ? device : null,
          includeBloodPressure: withBp,
        );
      } else {
        await recorder.startManual(
          type: type,
          name: label(context, type),
          ecgDevice: withEcg ? device : null,
          heartRateDevice: withHr && !withEcg ? hrDevice : null,
          recordGps: withGps,
          includeBloodPressure: withBp,
        );
      }
    });
    final pending = [
      ...?ref.watch(manualRecordingPendingProvider).valueOrNull,
      ...?ref.watch(indoorPendingProvider).valueOrNull,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (session != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              session.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        if (waiting) const LinearProgressIndicator(),
        if (state.error != null) _ErrorLine(state.error!),
        const SizedBox(height: 12),
        // Sport · Start · GPS or equipment, like a watch face.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _RoundAction(
                key: const ValueKey('record-sport'),
                icon: _sportIcon(type),
                label: label(context, type),
                checked: true,
                onTap: waiting || session != null ? null : chooseSport,
              ),
            ),
            Expanded(
              child: _RoundAction(
                key: const ValueKey('record-start'),
                icon: Icons.play_arrow_rounded,
                label: l.recStart,
                primary: true,
                onTap: canStart ? start : null,
              ),
            ),
            Expanded(
              child: indoor
                  ? _RoundAction(
                      key: const ValueKey('record-machine-round'),
                      icon: machineReady
                          ? Icons.bluetooth_connected_rounded
                          : Icons.bluetooth_searching_rounded,
                      label: machineReady
                          ? state.device?.name ?? l.recMachine
                          : l.recMachine,
                      checked: machineReady,
                      onTap: waiting ? null : connectMachine,
                    )
                  : _RoundAction(
                      key: const ValueKey('record-gps-round'),
                      icon: withGps
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_off_rounded,
                      label: l.recGps,
                      checked: withGps,
                      onTap: waiting
                          ? null
                          : () => setState(() => withGps = !withGps),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _OptionsCard(
          children: [
            if (indoor) ...[
              _OptionRow(
                key: const ValueKey('record-machine'),
                icon: machineReady
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_rounded,
                title: machineReady
                    ? state.device?.name ?? l.indoorEquipment
                    : type == 'treadmill_running' && session == null
                    ? l.manualTreadmillConnect
                    : l.indoorChooseEquipment,
                subtitle: machineReady
                    ? l.connected
                    : type == 'treadmill_running' && session == null
                    ? l.manualTreadmillHelp
                    : l.manualEquipmentHelp,
                onTap: waiting ? null : connectMachine,
              ),
              if (!machineReady && pairedMachine != null)
                _OptionRow(
                  icon: Icons.history_rounded,
                  title: '${l.connect} ${pairedMachine.name}',
                  onTap: waiting ? null : () => connectMachine(pairedMachine),
                ),
            ],
            _OptionRow(
              key: const ValueKey('record-gps'),
              icon: Icons.route_rounded,
              title: l.recGps,
              subtitle: l.manualGpsHelp,
              value: withGps,
              onChanged: waiting || indoor
                  ? null
                  : (v) => setState(() => withGps = v),
            ),
            _OptionRow(
              key: const ValueKey('record-ecg'),
              icon: Icons.monitor_heart_rounded,
              title: l.recEcg,
              subtitle: withEcg
                  ? device?.name ?? l.manualChooseHelp
                  : l.manualRecordEcg,
              value: withEcg,
              onChanged: waiting
                  ? null
                  : (v) => setState(() {
                      withEcg = v;
                      if (v) withHr = true;
                    }),
              onTap: withEcg && !waiting ? chooseH10 : null,
            ),
            _OptionRow(
              key: const ValueKey('record-hr'),
              icon: Icons.favorite_rounded,
              title: l.recHeartRate,
              subtitle: withEcg
                  ? l.manualHrWithEcg
                  : withHr
                  ? hrDevice?.name ?? l.manualChooseHr
                  : null,
              value: withHr,
              onChanged: waiting || withEcg
                  ? null
                  : (v) => setState(() => withHr = v),
              onTap: withHr && !withEcg && !waiting ? chooseHeartRate : null,
            ),
            _OptionRow(
              key: const ValueKey('record-bp'),
              icon: Icons.speed_rounded,
              title: l.recBloodPressure,
              subtitle: l.manualBpHelp,
              value: withBp,
              onChanged: waiting ? null : (v) => setState(() => withBp = v),
            ),
          ],
        ),
        if (machineReady &&
            state.machine == FtmsMachine.treadmill &&
            ftmsCompatibilityForName(state.device?.name ?? '') ==
                FtmsCompatibility.matrix)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              l.indoorMatrixReadOnly,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
        if (state.phase == IndoorPhase.starting)
          TextButton(
            onPressed: () => runUiAction(context, recorder.discard),
            child: Text(l.cancel),
          ),
        if (session == null && pending.isNotEmpty) ...[
          const SizedBox(height: 22),
          SectionLabel(l.indoorUnfinished),
          _OptionsCard(
            children: [
              for (final p in pending)
                _OptionRow(
                  icon: Icons.restore_rounded,
                  title: dayText(p.startedAt.toLocal()),
                  subtitle: l.resumeWorkout,
                  onTap: waiting
                      ? null
                      : () => run(() => recorder.restore(p.recordingId)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Text(
          l.manualRecordDescription,
          style: TextStyle(color: muted, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  // ── While recording ───────────────────────────────────────────────────

  Widget _liveView(
    BuildContext context,
    IndoorRecorderState state,
    IndoorCapture capture,
    bool waiting,
  ) {
    final l = context.l10n;
    final ecg = ref.watch(ecgRecorderProvider);
    final paused = state.phase == IndoorPhase.paused;
    final sport = capture.activityType;
    final kind = activityKind(sport);
    final rowing = kind == ActivityKind.rowing;
    final speed = state.live['spd'];
    final power = state.live['w'];
    final distanceKm = capture.distanceMeters / 1000;
    final hasDistance = capture.totals['d'] != null || capture.gpsEnabled;
    // The one figure that matters most for the sport, shown huge.
    final (String, String) primary = switch (kind) {
      ActivityKind.cycling when power != null => (
        '${power.round()}',
        l.recPowerW,
      ),
      ActivityKind.cycling => (
        speed == null ? '0' : (speed * 3.6).fixed(1),
        l.recSpeedKmh,
      ),
      ActivityKind.rowing => (_pace(speed, per: 500), l.recPace500),
      ActivityKind.running || ActivityKind.walking => (_pace(speed), l.recPace),
      _ when power != null => ('${power.round()}', l.recPowerW),
      _ => (
        state.live['hr'] == null ? '--' : '${state.live['hr']!.round()}',
        l.recHeartRate,
      ),
    };
    final avgPace = distanceKm >= .01
        ? _pace(capture.distanceMeters / (capture.elapsedMs / 1000))
        : null;
    final stats = <(IconData, String, String, Color)>[
      if (state.live['hr'] != null && primary.$2 != l.recHeartRate)
        (
          Icons.favorite_rounded,
          '${state.live['hr']!.round()}',
          'bpm',
          const Color(0xFFFF5C7A),
        ),
      if (avgPace != null &&
          (kind == ActivityKind.running || kind == ActivityKind.walking))
        (Icons.timer_outlined, avgPace, l.recAvgPace, mint),
      if (state.live['cad'] != null)
        (
          Icons.autorenew_rounded,
          state.live['cad']!.fixed(0),
          l.recCadence,
          const Color(0xFF60A5FA),
        ),
      if (power != null && primary.$2 != l.recPowerW)
        (Icons.bolt_rounded, '${power.round()}', 'W', const Color(0xFFFFC53D)),
      if (state.live['incline'] != null)
        (
          Icons.trending_up_rounded,
          '${state.live['incline']!.fixed(1)}%',
          l.recordingIncline,
          const Color(0xFFA78BFA),
        ),
      if (capture.totals['kcal'] != null)
        (
          Icons.local_fire_department_rounded,
          capture.totals['kcal']!.round().toString(),
          'kcal',
          const Color(0xFFFF8A4C),
        ),
    ];
    final route = [
      for (final p in capture.route)
        if (p['lat'] != null && p['lng'] != null)
          LatLng(p['lat']!.toDouble(), p['lng']!.toDouble()),
    ];
    return Column(
      children: [
        if (!rowing)
          _ClockBand(
            paused: paused,
            time: _clock(capture.elapsedMs),
            status: paused
                ? l.recordingPaused
                : capture.isManual
                ? l.recLive
                : state.reconnecting
                ? l.recordingReconnecting
                : state.connected
                ? '${capture.device.name} · ${l.connected}'
                : l.recordingInterrupted,
            warn: !paused && !capture.isManual && !state.connected,
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (state.error != null) _ErrorLine(state.error!),
                if (rowing)
                  RowingRecordingDashboard(
                    key: ValueKey(capture.id),
                    state: state,
                    ecg: ecg,
                    clock: _clock(capture.elapsedMs),
                    availableHeight: constraints.maxHeight,
                    onRestartEcg: waiting
                        ? null
                        : () => run(recorder.restartActivityEcg),
                  )
                else ...[
                  _BigFigure(
                    value: primary.$1,
                    label: primary.$2,
                    size: 96,
                    key: const ValueKey('record-primary'),
                  ),
                  if (hasDistance) ...[
                    const SizedBox(height: 8),
                    _BigFigure(
                      value: distanceKm.fixed(2),
                      label: l.recDistanceKm,
                      size: 64,
                    ),
                  ],
                  if (capture.gpsEnabled && capture.route.isEmpty)
                    Text(
                      l.manualGpsWaiting,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  if (stats.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in stats)
                          _StatPill(
                            icon: s.$1,
                            value: s.$2,
                            unit: s.$3,
                            color: s.$4,
                          ),
                      ],
                    ),
                  ],
                ],
                if (capture.gpsEnabled) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: FilterChip(
                      key: const ValueKey('record-map'),
                      avatar: const Icon(Icons.map_rounded, size: 18),
                      label: Text(l.recMap),
                      selected: showMap,
                      showCheckmark: false,
                      selectedColor: mint.withValues(alpha: .25),
                      shape: const StadiumBorder(),
                      onSelected: (v) => setState(() => showMap = v),
                    ),
                  ),
                  if (showMap && route.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _LiveRouteMap(route: route),
                  ],
                ],
                if (capture.heartRateDevice != null &&
                    capture.ecgDevice == null &&
                    state.phase == IndoorPhase.recording &&
                    !state.heartRateConnected)
                  _SensorWarning(
                    text: l.manualHrDisconnected,
                    action: l.manualReconnectHr,
                    onTap: waiting
                        ? null
                        : () => run(
                            () => recorder.connectHeartRate(
                              capture.heartRateDevice!,
                            ),
                          ),
                  ),
                if (capture.ecgDevice != null && !rowing) ...[
                  const SizedBox(height: 16),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.monitor_heart_rounded,
                              color: Color(0xFFFF5C7A),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                capture.ecgDevice!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              l.manualEcgSegments(
                                capture.ecgRecordingIds.length,
                              ),
                              style: TextStyle(color: muted, fontSize: 11),
                            ),
                          ],
                        ),
                        if (capture.ecgRecordingIds.contains(ecg.recordingId))
                          EcgWaveform(
                            chunks: ecg.preview,
                            hz: ecg.rate,
                            duration: ecg.durationMs / 1000,
                            live: ecg.active,
                          ),
                        if (state.phase == IndoorPhase.recording && !ecg.active)
                          _SensorWarning(
                            text: l.manualEcgInterrupted,
                            action: l.manualRestartEcg,
                            onTap: waiting
                                ? null
                                : () => run(recorder.restartActivityEcg),
                          ),
                      ],
                    ),
                  ),
                ],
                if (!capture.isManual &&
                    capture.heartRateDevice != null &&
                    capture.ecgDevice == null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.indoorExternalHeartRate),
                    subtitle: Text(l.indoorEquipmentHeartRate),
                    value: state.preferExternal,
                    onChanged: waiting ? null : recorder.preferExternal,
                  ),
                if (!capture.isManual &&
                    capture.machine == FtmsMachine.treadmill &&
                    ftmsCompatibilityForName(capture.device.name) ==
                        FtmsCompatibility.matrix)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      l.indoorMatrixReadOnly,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                IndoorIntervalCard(waiting: waiting),
                const IndoorControlCard(),
                if (capture.includeBloodPressure)
                  ActivityBloodPressureCard(capture: capture),
              ],
            ),
          ),
        ),
        // Big thumb buttons, like on a watch.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: paused
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _PillButton(
                              key: const ValueKey('record-resume'),
                              icon: Icons.play_arrow_rounded,
                              label: l.recResume,
                              background: mint,
                              foreground: Colors.black,
                              onTap: waiting
                                  ? null
                                  : () => run(recorder.resume),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PillButton(
                              key: const ValueKey('record-finish'),
                              icon: Icons.sports_score_rounded,
                              label: l.recFinish,
                              background: fjInk,
                              foreground: Colors.black,
                              onTap: waiting || capture.elapsedMs < 1000
                                  ? null
                                  : () => finish(capture),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: waiting ? null : discard,
                        child: Text(
                          l.recDiscard,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  )
                : _PillButton(
                    key: const ValueKey('record-pause'),
                    icon: Icons.pause_rounded,
                    label: l.indoorPause,
                    background: mint,
                    foreground: Colors.black,
                    onTap: waiting || state.phase != IndoorPhase.recording
                        ? null
                        : () => run(recorder.pause),
                  ),
          ),
        ),
      ],
    );
  }

  // ── After saving ──────────────────────────────────────────────────────

  Widget _savedView(
    BuildContext context,
    IndoorRecorderState state,
    IndoorCapture capture,
  ) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [mint, Color(0xFF38BDF8)],
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.black,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l.indoorSaved,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        _GlassCard(child: IndoorMetrics(state: state, saved: true)),
        const SizedBox(height: 12),
        if (capture.includeBloodPressure)
          ActivityBloodPressureCard(capture: capture),
        if (capture.ecgRecordingIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showAppSheet(context, const EcgSheet()),
            icon: const Icon(Icons.monitor_heart_outlined),
            label: Text(l.ecgTitle),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(onPressed: recorder.newRecording, child: Text(l.recNew)),
      ],
    );
  }
}

/// Asks for the final distance; NaN when none is given, null on cancel.
Future<double?> _askDistance(BuildContext context, double? current) async {
  final l = context.l10n;
  final controller = TextEditingController(
    text: current == null ? '' : (current / 1000).toString(),
  );
  var unit = GymDistanceUnit.kilometers;
  try {
    return await showDialog<double>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: Text(l.recFinish),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: l.manualFinalDistance),
              ),
              DropdownButtonFormField<GymDistanceUnit>(
                initialValue: unit,
                decoration: InputDecoration(labelText: l.gymDistanceUnit),
                items: [
                  for (final u in GymDistanceUnit.values)
                    DropdownMenuItem(value: u, child: Text(u.label)),
                ],
                onChanged: (v) => update(() => unit = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                final value = text.isEmpty ? null : parseDecimal(text);
                if (text.isNotEmpty && value == null) return;
                Navigator.pop(
                  dialog,
                  value == null ? double.nan : value * unit.metersPerUnit,
                );
              },
              child: Text(l.recFinish),
            ),
          ],
        ),
      ),
    );
  } finally {
    controller.dispose();
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(color: Colors.orangeAccent)),
  );
}

/// A round action with its name below, the start one big and bright.
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.primary = false,
    this.checked = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary, checked;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final size = primary ? 104.0 : 72.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            SizedBox(
              height: 104,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: enabled || !primary ? 1 : .35,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: primary
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [mint, Color(0xFF38BDF8)],
                                )
                              : null,
                          color: primary ? null : mint.withValues(alpha: .14),
                          boxShadow: primary && enabled
                              ? [
                                  BoxShadow(
                                    color: mint.withValues(alpha: .35),
                                    blurRadius: 28,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          size: primary ? 56 : 32,
                          color: primary ? Colors.black : mint,
                        ),
                      ),
                    ),
                    if (checked)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: mint,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: duo(0xFF111111, 0xFFF2F4F7),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: primary ? 16 : 13,
                fontWeight: primary ? FontWeight.w800 : FontWeight.w600,
                color: primary ? mint : fjInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x14FFFFFF)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, indent: 60, color: Color(0x1FFFFFFF)),
          children[i],
        ],
      ],
    ),
  );
}

/// A row of the options card: icon, title, hint, and a switch or chevron.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onChanged,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap:
        onTap ??
        (value != null && onChanged != null ? () => onChanged!(!value!) : null),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Icon(icon, color: fjInk, size: 26),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (value != null)
            Switch(value: value!, onChanged: onChanged, activeThumbColor: mint)
          else
            Icon(Icons.chevron_right_rounded, color: muted),
        ],
      ),
    ),
  );
}

/// The time on top; amber while paused.
class _ClockBand extends StatelessWidget {
  const _ClockBand({
    required this.paused,
    required this.time,
    required this.status,
    this.warn = false,
  });
  final bool paused, warn;
  final String time, status;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
    color: paused ? _pausedColor : Colors.transparent,
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!paused) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: warn ? Colors.orangeAccent : const Color(0xFFFF3B5C),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                status.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: paused
                      ? Colors.black
                      : warn
                      ? Colors.orangeAccent
                      : muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          time,
          key: const ValueKey('record-clock'),
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
            color: paused ? Colors.black : fjInk,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

class _BigFigure extends StatelessWidget {
  const _BigFigure({
    super.key,
    required this.value,
    required this.label,
    required this.size,
  });
  final String value, label;
  final double size;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: TextStyle(
            fontSize: size,
            height: 1.05,
            color: fjInk,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: muted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });
  final IconData icon;
  final String value, unit;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 4),
        Text(unit, style: TextStyle(color: muted, fontSize: 12)),
      ],
    ),
  );
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x14FFFFFF)),
    ),
    child: child,
  );
}

class _SensorWarning extends StatelessWidget {
  const _SensorWarning({required this.text, required this.action, this.onTap});
  final String text, action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_off_rounded, color: Colors.orangeAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          ),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    ),
  );
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color background, foreground;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    width: double.infinity,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: .35),
        shape: const StadiumBorder(),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 28),
      label: Text(label),
    ),
  );
}

/// The route so far, following the newest position. Shown on request: map
/// tiles cost data and battery.
class _LiveRouteMap extends StatefulWidget {
  const _LiveRouteMap({required this.route});
  final List<LatLng> route;
  @override
  State<_LiveRouteMap> createState() => _LiveRouteMapState();
}

class _LiveRouteMapState extends State<_LiveRouteMap> {
  final controller = MapController();
  bool ready = false;

  @override
  void didUpdateWidget(_LiveRouteMap old) {
    super.didUpdateWidget(old);
    if (ready && widget.route.isNotEmpty) {
      controller.move(widget.route.last, controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      height: 240,
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: widget.route.last,
          initialZoom: 16,
          onMapReady: () => ready = true,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'de.ebeling-hoppe.fjelia',
          ),
          PolylineLayer(
            polylines: [
              Polyline(points: widget.route, color: mint, strokeWidth: 5),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: widget.route.last,
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF38BDF8),
                    border: Border.all(color: fjInk, width: 3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
