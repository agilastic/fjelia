import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n_ext.dart';
import '../models/gym_workout.dart';
import '../models/training_ble_profile.dart';
import '../providers/gym_treadmill_provider.dart';
import '../providers/indoor_recording_provider.dart';
import '../services/matrix_xid_client.dart';
import '../utils/decimal.dart';
import 'app_widgets.dart';
import 'ecg_sheet.dart'
    show chooseTrainingDevice, recordingDuration, shareRecordingFile;

class GymTreadmillSheet extends ConsumerStatefulWidget {
  const GymTreadmillSheet({super.key});
  @override
  ConsumerState<GymTreadmillSheet> createState() => _GymTreadmillState();
}

class _GymTreadmillState extends ConsumerState<GymTreadmillSheet> {
  bool busy = false;
  TrainingBleReport? report;
  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    await runUiAction(context, action);
    if (mounted) setState(() => busy = false);
  }

  Future<void> inspect() => run(() async {
    final actions = ref.read(gymTreadmillActionsProvider);
    final devices = await actions.scan();
    if (!mounted) return;
    final device = await chooseTrainingDevice(
      context,
      devices,
      title: context.l10n.gymFindEquipment,
      empty: context.l10n.noDevicesFoundTapTo,
    );
    if (device == null) return;
    final found = await actions.inspect(device);
    if (mounted) setState(() => report = found);
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final found = report;
    final active = ref.watch(indoorRecorderProvider).active;
    return SheetPage(
      title: l.gymTitle,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.gymDescription, style: TextStyle(color: muted)),
          const SizedBox(height: 16),
          if (busy) const LinearProgressIndicator(),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.gymDirectConnection,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(l.gymConsoleSupport, style: TextStyle(color: muted)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy || active ? null : inspect,
                  icon: const Icon(Icons.bluetooth_searching),
                  label: Text(l.gymFindEquipment),
                ),
                if (found != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    found.device.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    found.canRecord ? l.gymLiveAvailable : l.gymLiveUnavailable,
                  ),
                  if (found.machines.isEmpty && found.runningSpeed)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l.gymSpeedOnly,
                        style: TextStyle(color: muted),
                      ),
                    ),
                  if (found.canRecord)
                    FilledButton.icon(
                      onPressed: busy || active
                          ? null
                          : () => run(() async {
                              await ref
                                  .read(indoorRecorderProvider.notifier)
                                  .connect(
                                    found.device,
                                    preferred:
                                        found.machines.contains(
                                              FtmsMachine.treadmill,
                                            ) ||
                                            found.runningSpeed
                                        ? FtmsMachine.treadmill
                                        : null,
                                  );
                              if (context.mounted) Navigator.pop(context, true);
                            }),
                      icon: const Icon(Icons.bluetooth_connected),
                      label: Text(l.gymUseMachine),
                    ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(l.gymConnectionReport),
                    children: [
                      for (final service in found.services)
                        ListTile(
                          dense: true,
                          title: Text(trainingUuid(service.uuid)),
                          subtitle: Text(
                            service.characteristics
                                .map((c) => trainingUuid(c.uuid))
                                .join(', '),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: busy
                            ? null
                            : () => run(() async {
                                final dir = await getTemporaryDirectory();
                                final file = File(
                                  '${dir.path}/fjelia-equipment-services.json',
                                );
                                await file.writeAsString(
                                  const JsonEncoder.withIndent(
                                    '  ',
                                  ).convert(found.toJson()),
                                );
                                if (context.mounted) {
                                  await shareRecordingFile(context, file.path);
                                }
                              }),
                        icon: const Icon(Icons.share),
                        label: Text(l.gymShareReport),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_download_outlined, color: mint),
              title: Text(l.gymXid),
              subtitle: Text(l.gymXidDescription),
              trailing: const Icon(Icons.chevron_right),
              onTap: busy
                  ? null
                  : () => showAppSheet(context, const MatrixXidSheet()),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.document_scanner_outlined, color: mint),
              title: Text(l.gymSummary),
              subtitle: Text(l.gymSummaryDescription),
              trailing: const Icon(Icons.chevron_right),
              onTap: busy || active
                  ? null
                  : () => showAppSheet(context, const GymSummarySheet()),
            ),
          ),
        ],
      ),
    );
  }
}

class MatrixXidSheet extends ConsumerStatefulWidget {
  const MatrixXidSheet({super.key});
  @override
  ConsumerState<MatrixXidSheet> createState() => _MatrixXidState();
}

class _MatrixXidState extends ConsumerState<MatrixXidSheet> {
  final portal = TextEditingController();
  final xid = TextEditingController();
  final passcode = TextEditingController();
  bool busy = false;
  int days = 30;
  MatrixXidBatch? batch;
  final selected = <String>{};
  String? saved;
  @override
  void dispose() {
    portal.dispose();
    xid.dispose();
    passcode.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    await runUiAction(context, action);
    if (mounted) setState(() => busy = false);
  }

  Future<void> load() => run(() async {
    final loaded = await ref.read(gymTreadmillActionsProvider).load(days: days);
    if (!mounted) return;
    setState(() {
      batch = loaded;
      saved = null;
      selected
        ..clear()
        ..addAll(loaded.workouts.map((w) => w.id));
    });
  });
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = ref.watch(matrixXidSessionProvider);
    final account = session.valueOrNull;
    final actions = ref.read(gymTreadmillActionsProvider);
    final error = ref.watch(matrixXidErrorProvider);
    final waiting = busy || session.isLoading;
    return SheetPage(
      title: l.gymXid,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.gymXidDescription, style: TextStyle(color: muted)),
          const SizedBox(height: 12),
          if (waiting) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                error,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          if (account == null) ...[
            TextField(
              controller: portal,
              enabled: !waiting,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l.gymPortal,
                hintText: 'https://your-gym.netpulse.com',
                helperText: l.gymPortalHelp,
                helperMaxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: xid,
              enabled: !waiting,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'xID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passcode,
              enabled: !waiting,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: l.gymPasscode),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: waiting
                  ? null
                  : () => run(() async {
                      try {
                        await actions.signIn(
                          portal.text,
                          xid.text,
                          passcode.text,
                        );
                      } finally {
                        if (mounted) passcode.clear();
                      }
                    }),
              child: Text(l.connect),
            ),
          ] else ...[
            Text(account.origin.host),
            const SizedBox(height: 8),
            Text(
              l.gymSessionHelp,
              style: TextStyle(color: muted, fontSize: 12),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.gymAutoSync),
              value: ref.watch(matrixXidAutoSyncProvider).valueOrNull ?? true,
              onChanged: waiting
                  ? null
                  : (v) => run(() => actions.setAutoSync(v)),
            ),
            DropdownButtonFormField<int>(
              initialValue: days,
              items: [
                for (final n in [7, 30, 90, 365])
                  DropdownMenuItem(value: n, child: Text(l.gymLastDays(n))),
              ],
              onChanged: waiting
                  ? null
                  : (n) => setState(() {
                      days = n!;
                      batch = null;
                      selected.clear();
                    }),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: waiting ? null : load,
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text(l.gymLoadWorkouts),
            ),
            TextButton(
              onPressed: waiting
                  ? null
                  : () => run(() async {
                      await actions.disconnect();
                      if (mounted) {
                        setState(() {
                          batch = null;
                          selected.clear();
                          saved = null;
                        });
                      }
                    }),
              child: Text(l.disconnect),
            ),
            if (batch != null) ...[
              if (batch!.skipped > 0) Text(l.gymSkipped(batch!.skipped)),
              if (batch!.workouts.isEmpty) Text(l.gymNoWorkouts),
              for (final workout in batch!.workouts)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected.contains(workout.id),
                  onChanged: waiting
                      ? null
                      : (on) => setState(() {
                          if (on == true) {
                            selected.add(workout.id);
                          } else {
                            selected.remove(workout.id);
                          }
                        }),
                  title: Text(workout.name),
                  subtitle: Text(
                    '${dayText(workout.startedAt.toLocal())} · ${recordingDuration(workout.durationSeconds * 1000)}'
                    '${workout.distanceMeters == null ? '' : ' · ${(workout.distanceMeters! / 1000).toStringAsFixed(2)} km'}',
                  ),
                ),
              if (selected.isNotEmpty)
                FilledButton(
                  onPressed: waiting
                      ? null
                      : () => run(() async {
                          final result = await actions.save(
                            batch!.workouts
                                .where((w) => selected.contains(w.id))
                                .toList(),
                          );
                          if (mounted) {
                            setState(() {
                              saved = l.gymImported(
                                result.imported,
                                result.duplicates,
                              );
                              selected.clear();
                            });
                          }
                        }),
                  child: Text(l.importActivities(selected.length)),
                ),
            ],
          ],
          if (saved != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(saved!, style: const TextStyle(color: mint)),
            ),
        ],
      ),
    );
  }
}

class GymSummarySheet extends ConsumerStatefulWidget {
  const GymSummarySheet({super.key});
  @override
  ConsumerState<GymSummarySheet> createState() => _GymSummaryState();
}

class _GymSummaryState extends ConsumerState<GymSummarySheet> {
  final duration = TextEditingController();
  final distance = TextEditingController();
  final calories = TextEditingController();
  final hr = TextEditingController();
  GymDistanceUnit unit = GymDistanceUnit.kilometers;
  bool unitReviewed = true;
  DateTime start = DateTime.now();
  bool startChosen = false;
  bool busy = false;
  String? saved;
  @override
  void dispose() {
    duration.dispose();
    distance.dispose();
    calories.dispose();
    hr.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    await runUiAction(context, action);
    if (mounted) setState(() => busy = false);
  }

  Future<void> photo(bool camera) => run(() async {
    final draft = await ref
        .read(workoutPhotoServiceProvider)
        .pick(camera: camera);
    if (draft == null || !mounted) return;
    setState(() {
      // Replace all fields: unreadable values from a new photo must not keep
      // the previous photo's numbers.
      duration.text = draft.seconds == null
          ? ''
          : recordingDuration(draft.seconds! * 1000);
      distance.text = draft.distance?.toString() ?? '';
      calories.text = draft.calories?.toString() ?? '';
      hr.text = draft.heartRate?.toString() ?? '';
      if (draft.unit != null) unit = draft.unit!;
      unitReviewed = draft.distance == null || draft.unit != null;
      if (draft.seconds != null && !startChosen) {
        start = DateTime.now().subtract(Duration(seconds: draft.seconds!));
      }
      saved = null;
    });
  });
  Future<void> chooseStart() => run(() async {
    final date = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (time != null && mounted) {
      setState(() {
        start = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        startChosen = true;
      });
    }
  });
  Future<void> save() => run(() async {
    if (start.isAfter(DateTime.now()) ||
        distance.text.trim().isNotEmpty && !unitReviewed) {
      throw FormatException(context.l10n.gymReview);
    }
    final seconds = gymDuration(duration.text);
    if (seconds == null) throw FormatException(context.l10n.gymDurationHelp);
    double? value(TextEditingController c) {
      if (c.text.trim().isEmpty) return null;
      final n = parseDecimal(c.text);
      if (n == null) throw FormatException(context.l10n.gymReview);
      return n;
    }

    final meters = value(distance);
    final w = GymWorkout(
      id: GymWorkout.stableId(
        'gym_summary',
        '${start.toUtc().toIso8601String()}|$seconds|${meters == null ? '' : meters * unit.metersPerUnit}',
      ),
      startedAt: start.toUtc(),
      durationSeconds: seconds,
      distanceMeters: meters == null ? null : meters * unit.metersPerUnit,
      calories: value(calories),
      avgHeartRate: value(hr),
      name: context.l10n.gymSummary,
      source: 'gym_summary',
    );
    final result = await ref.read(gymTreadmillActionsProvider).save([w]);
    if (mounted) {
      setState(
        () => saved = context.l10n.gymImported(
          result.imported,
          result.duplicates,
        ),
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SheetPage(
      title: l.gymSummary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.gymSummaryDescription, style: TextStyle(color: muted)),
          const SizedBox(height: 12),
          if (busy) const LinearProgressIndicator(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy || saved != null ? null : () => photo(true),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l.gymTakePhoto),
              ),
              OutlinedButton.icon(
                onPressed: busy || saved != null ? null : () => photo(false),
                icon: const Icon(Icons.photo_outlined),
                label: Text(l.gymChoosePhoto),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l.gymReview, style: TextStyle(color: muted, fontSize: 12)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.gymStartTime),
            subtitle: Text(
              '${dayText(start)} · ${TimeOfDay.fromDateTime(start).format(context)}',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: busy || saved != null ? null : chooseStart,
          ),
          TextField(
            key: const ValueKey('gym-duration'),
            controller: duration,
            enabled: !busy && saved == null,
            onChanged: (value) {
              if (!startChosen) {
                setState(
                  () => start = DateTime.now().subtract(
                    Duration(seconds: gymDuration(value) ?? 0),
                  ),
                );
              }
            },
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(
              labelText: l.duration,
              hintText: '30:00',
              helperText: l.gymDurationHelp,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('gym-distance'),
            controller: distance,
            enabled: !busy && saved == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.distance),
          ),
          DropdownButtonFormField<GymDistanceUnit>(
            key: ValueKey('$unit:$unitReviewed'),
            initialValue: unitReviewed ? unit : null,
            decoration: InputDecoration(labelText: l.gymDistanceUnit),
            items: [
              for (final u in GymDistanceUnit.values)
                DropdownMenuItem(value: u, child: Text(u.label)),
            ],
            onChanged: busy || saved != null
                ? null
                : (v) => setState(() {
                    unit = v!;
                    unitReviewed = true;
                  }),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('gym-calories'),
            controller: calories,
            enabled: !busy && saved == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.gymCalories,
              suffixText: 'kcal',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('gym-hr'),
            controller: hr,
            enabled: !busy && saved == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.heartRate,
              suffixText: 'bpm',
            ),
          ),
          const SizedBox(height: 16),
          if (saved != null)
            Text(saved!, style: const TextStyle(color: mint))
          else
            FilledButton.icon(
              onPressed: busy ? null : save,
              icon: const Icon(Icons.save_outlined),
              label: Text(l.save),
            ),
        ],
      ),
    );
  }
}
