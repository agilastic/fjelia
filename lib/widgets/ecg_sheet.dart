import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../theme/fjelia_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../db/database.dart' show EcgRecording;
import '../l10n/l10n_ext.dart';
import '../models/coach_context_card.dart';
import '../models/ecg_sleep_staging.dart';
import '../providers/ecg_provider.dart';
import '../providers/day_data_provider.dart' show syncStatusListenerProvider;
import '../providers/polar_h10_provider.dart';
import '../screens/ai_coach/ai_coach_screen.dart' show openCoachTab;
import '../services/coach_tasks.dart' show ecgClinicalMode;
import '../services/ecg_sleep_staging_service.dart';
import '../utils/log.dart';
import 'app_widgets.dart';
import 'swipe_action_tile.dart';
import 'sleep_stages.dart'
    show SleepStageBreakdown, SleepStagesChart, sleepStageOrder;
import 'ecg_respiration_chart.dart';

class EcgSheet extends ConsumerStatefulWidget {
  const EcgSheet({super.key});
  @override
  ConsumerState<EcgSheet> createState() => _EcgSheetState();
}

class _EcgSheetState extends ConsumerState<EcgSheet> {
  bool busy = false;
  TrainingDevice? selected;

  Future<void> choose() async {
    setState(() => busy = true);
    await runUiAction(context, () async {
      final devices = await ref.read(ecgActionsProvider).scan();
      if (!mounted) return;
      final device = await chooseTrainingDevice(
        context,
        devices,
        title: context.l10n.ecgChooseDevice,
        empty: context.l10n.noPolarH10FoundWear,
      );
      if (device != null) {
        await ref.read(ecgActionsProvider).remember(device);
        if (mounted) setState(() => selected = device);
      }
    });
    if (mounted) setState(() => busy = false);
  }

  Future<void> import() async {
    setState(() => busy = true);
    await runUiAction(context, () async {
      final file = await ref.read(ecgActionsProvider).pick();
      if (file == null || !mounted) return;
      var at = file.preview.recordedAt ?? DateTime.now(),
          source = file.preview.source ?? 'Garmin';
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialog) => StatefulBuilder(
          builder: (dialog, update) => AlertDialog(
            title: Text(file.name),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    file.preview.kind == 'report'
                        ? context.l10n.ecgReport
                        : '${file.preview.sampleRateHz!.toStringAsFixed(1)} Hz · ${file.preview.sampleCount} samples',
                  ),
                  const SizedBox(height: 12),
                  if (file.preview.source == null)
                    DropdownButtonFormField<String>(
                      initialValue: source,
                      decoration: InputDecoration(
                        labelText: context.l10n.recordingSource,
                      ),
                      items: [
                        for (final s in ['Garmin', 'Apple Watch', 'Other'])
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (value) =>
                          update(() => source = value ?? source),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.ecgRecordingDate),
                    subtitle: Text(
                      '${dayText(at)} · ${TimeOfDay.fromDateTime(at).format(context)}',
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: file.preview.recordedAt != null
                        ? null
                        : () async {
                            final day = await showDatePicker(
                              context: dialog,
                              initialDate: at,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (day == null || !dialog.mounted) return;
                            final time = await showTimePicker(
                              context: dialog,
                              initialTime: TimeOfDay.fromDateTime(at),
                            );
                            if (time != null) {
                              update(
                                () => at = DateTime(
                                  day.year,
                                  day.month,
                                  day.day,
                                  time.hour,
                                  time.minute,
                                ),
                              );
                            }
                          },
                  ),
                  Text(
                    context.l10n.ecgImportLimitations,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: Text(context.l10n.importTitle),
              ),
            ],
          ),
        ),
      );
      if (accepted != true) return;
      final id = await ref
          .read(ecgStorageProvider)
          .import(
            file.name,
            Uint8List.fromList(file.bytes),
            at: at,
            source: source,
          );
      if (!mounted) return;
      final row = await ref.read(ecgStorageProvider).recording(id);
      if (mounted && row != null) {
        await showAppSheet(context, EcgDetailSheet(recording: row));
      }
    });
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ecgRecorderProvider), l = context.l10n;
    final paired = ref.watch(polarH10PairedProvider).valueOrNull;
    final device =
        selected ??
        (paired == null
            ? null
            : TrainingDevice(id: paired.id, name: paired.name));
    return SheetPage(
      title: l.ecgTitle,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.ecgDescription, style: TextStyle(color: muted)),
          const SizedBox(height: 12),
          if (busy ||
              state.phase == EcgPhase.connecting ||
              state.phase == EcgPhase.saving)
            const LinearProgressIndicator(),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          if (state.active)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.device?.name ?? 'Polar H10',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_ecgPhase(context, state.phase)} · ${recordingDuration(state.durationMs)} · ${state.rate.round()} Hz',
                  ),
                  EcgWaveform(
                    chunks: state.preview,
                    hz: state.rate,
                    live: true,
                    duration: state.durationMs / 1000,
                  ),
                  Text(
                    '${l.ecgSamples(state.count)} · ${l.ecgSignalGaps(state.gaps)}',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: state.phase == EcgPhase.recording
                        ? () => ref.read(ecgRecorderProvider.notifier).stop()
                        : null,
                    icon: const Icon(Icons.stop),
                    label: Text(l.ecgStopSave),
                  ),
                ],
              ),
            )
          else ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bluetooth, color: mint),
                    title: Text(device?.name ?? l.ecgChooseDevice),
                    trailing: const Icon(Icons.search),
                    onTap: busy ? null : choose,
                  ),
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            if (device == null) {
                              await choose();
                              return;
                            }
                            await runUiAction(
                              context,
                              () => ref
                                  .read(ecgRecorderProvider.notifier)
                                  .start(device),
                            );
                          },
                    icon: const Icon(Icons.monitor_heart_outlined),
                    label: Text(l.ecgStart),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : import,
                    icon: const Icon(Icons.file_open_outlined),
                    label: Text(l.ecgImport),
                  ),
                ],
              ),
            ),
          ],
          Text(l.ecgPrivacy, style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 8),
          Text(l.ecgLimitations, style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: SectionLabel(l.ecgHistory)),
              IconButton(
                tooltip: l.ecgExportMetadata,
                icon: const Icon(Icons.ios_share, size: 20),
                onPressed: busy || state.active
                    ? null
                    : () => runUiAction(context, () async {
                        final file = await ref
                            .read(ecgStorageProvider)
                            .exportMetadataCsv();
                        if (context.mounted) {
                          await shareRecordingFile(context, file.path);
                        }
                      }),
              ),
            ],
          ),
          ref
              .watch(ecgHistoryProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (rows) => Column(
                  children: [
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l.ecgNoRecordings,
                          style: TextStyle(color: muted),
                        ),
                      ),
                    for (final row in rows)
                      SectionCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            row.kind == 'report'
                                ? Icons.picture_as_pdf_outlined
                                : Icons.monitor_heart_outlined,
                            color: mint,
                          ),
                          title: Text(
                            '${row.deviceName} · ${row.kind == 'report' ? l.ecgReport : l.ecgWaveform}',
                          ),
                          subtitle: Text(
                            '${dayText(row.recordedAt.toLocal())} · ${row.status == 'interrupted' ? l.recordingInterrupted : recordingDuration(row.durationMs)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: row.status == 'recording'
                              ? null
                              : () => showAppSheet(
                                  context,
                                  EcgDetailSheet(recording: row),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

bool _isSleepCapture(EcgRecording recording) {
  try {
    return (jsonDecode(recording.metadataJson)
            as Map<String, dynamic>)['capture_purpose'] ==
        'sleep';
  } catch (_) {
    return false;
  }
}

String _sleepRespirationLabel(BuildContext context, String key) {
  final isGerman = Localizations.localeOf(context).languageCode == 'de';
  return switch ((isGerman, key)) {
    (true, 'title') => 'Atembezogenes Signal · experimentell',
    (true, 'description') =>
      'Relative Änderungen der EKG-Schlagamplitude und Bewegung des Brustgurts im Zeitverlauf. Das ist weder Atemfluss noch eine kalibrierte Atemmessung. Niedrige oder wechselnde Signale können andere Ursachen haben; Fjelia erkennt oder diagnostiziert hier keine Apnoe.',
    (true, 'working') => 'Signalübersicht wird erstellt …',
    (false, 'title') => 'Breathing-related signal · exploratory',
    (false, 'description') =>
      'Relative ECG beat-amplitude changes and chest-strap movement over time. This is not airflow or a calibrated breathing measurement. Low or changing signals can have other causes; Fjelia does not detect or diagnose apnea from this view.',
    _ => 'Preparing signal overview…',
  };
}

class EcgDetailSheet extends ConsumerStatefulWidget {
  const EcgDetailSheet({super.key, required this.recording});
  final EcgRecording recording;

  @override
  ConsumerState<EcgDetailSheet> createState() => _EcgDetailSheetState();
}

class _EcgDetailSheetState extends ConsumerState<EcgDetailSheet> {
  late final TextEditingController _noteController;
  bool _exportingSleepRaw = false;
  bool _preparingCoach = false;
  bool _savingNote = false;
  bool _noteEdited = false;
  bool _estimatingSleepStages = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.recording.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _exportSleepRaw(EcgRecording row) async {
    if (_exportingSleepRaw) return;
    setState(() => _exportingSleepRaw = true);
    List<File>? files;
    try {
      await runUiAction(context, () async {
        files = await ref.read(ecgStorageProvider).exportSleepCsvFiles(row);
      });
    } finally {
      if (mounted) setState(() => _exportingSleepRaw = false);
    }
    if (files != null && mounted) {
      await shareRecordingFiles(
        context,
        files!.map((file) => file.path).toList(),
      );
    }
  }

  Future<void> _estimateSleepStages(EcgRecording row) async {
    if (_estimatingSleepStages || row.sampleRateHz == null) return;
    setState(() => _estimatingSleepStages = true);
    try {
      final storage = ref.read(ecgStorageProvider);
      final estimate = await EcgSleepStagingService().estimate(
        chunks: await storage.chunks(row.recordingId),
        sampleRateHz: row.sampleRateHz!,
        recordedAt: row.recordedAt,
      );
      await storage.saveSleepStageEstimate(row.recordingId, estimate);
      ref.read(syncStatusListenerProvider.notifier).state++;
      ref.invalidate(ecgHistoryProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.sleepEcgStagesFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _estimatingSleepStages = false);
    }
  }

  Future<void> _askCoach(EcgRecording row) => askCoachAboutEcg(
    context,
    ref,
    row,
    onBusyChanged: (busy) {
      if (mounted) setState(() => _preparingCoach = busy);
    },
  );

  Future<void> _saveNote(EcgRecording row) async {
    if (_savingNote) return;
    setState(() => _savingNote = true);
    try {
      await ref
          .read(ecgStorageProvider)
          .updateNote(row.recordingId, _noteController.text);
      if (mounted) setState(() => _noteEdited = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(ecgHistoryProvider).valueOrNull;
    final row =
        rows
            ?.where((r) => r.recordingId == widget.recording.recordingId)
            .firstOrNull ??
        widget.recording;
    if (!_noteEdited && _noteController.text != (row.note ?? '')) {
      _noteController.text = row.note ?? '';
    }
    final l = context.l10n;
    final sleepCapture = _isSleepCapture(row);
    final sleepEstimate = sleepCapture
        ? EcgSleepStageEstimate.fromRecordingMetadata(row.metadataJson)
        : null;
    return SheetPage(
      title: l.ecgTitle,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            row.deviceName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '${dayText(row.recordedAt.toLocal())} · ${TimeOfDay.fromDateTime(row.recordedAt.toLocal()).format(context)} · ${row.source}',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 16),
          if (row.status == 'interrupted')
            Text(
              l.recordingInterrupted,
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          if (row.kind == 'waveform' && row.sampleRateHz != null) ...[
            Text(
              '${recordingDuration(row.durationMs)} · ${row.sampleRateHz!.toStringAsFixed(1)} Hz · ${l.ecgSamples(row.sampleCount)}',
            ),
            if (sleepCapture)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l.sleepEcgRawNote,
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ),
            if (sleepCapture && row.status != 'recording') ...[
              ref
                  .watch(ecgRespirationReviewProvider(row.recordingId))
                  .when(
                    loading: () => SectionCard(
                      title: _sleepRespirationLabel(context, 'title'),
                      child: Text(_sleepRespirationLabel(context, 'working')),
                    ),
                    error: (error, stack) => const SizedBox.shrink(),
                    data: (review) => review == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SectionCard(
                              title: _sleepRespirationLabel(context, 'title'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  EcgRespirationChart(review: review),
                                  const SizedBox(height: 8),
                                  Text(
                                    _sleepRespirationLabel(
                                      context,
                                      'description',
                                    ),
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
              if (sleepEstimate != null && sleepEstimate.epochs.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: l.sleepEcgStagesTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SleepStagesChart(
                        phases: sleepEstimate.fiveMinutePhases(
                          row.recordedAt.toLocal(),
                        ),
                        start: row.recordedAt.toLocal(),
                        end: row.recordedAt.toLocal().add(
                          Duration(
                            seconds:
                                sleepEstimate.epochs.last.startOffsetSeconds +
                                30,
                          ),
                        ),
                      ),
                      SleepStageBreakdown(
                        durations: {
                          for (final stage in sleepStageOrder)
                            stage: Duration(
                              seconds:
                                  sleepEstimate.epochs
                                      .where(
                                        (epoch) => epoch.chartStage == stage,
                                      )
                                      .length *
                                  30,
                            ),
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.sleepEcgStagesDisclaimer,
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              OutlinedButton.icon(
                onPressed: _estimatingSleepStages
                    ? null
                    : () => _estimateSleepStages(row),
                icon: _estimatingSleepStages
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bedtime_outlined),
                label: Text(
                  _estimatingSleepStages
                      ? l.sleepEcgStagesWorking
                      : sleepEstimate == null
                      ? l.sleepEcgStagesButton
                      : l.sleepEcgStagesAgain,
                ),
              ),
              if (_estimatingSleepStages) ...[
                const SizedBox(height: 6),
                const LinearProgressIndicator(minHeight: 3),
              ],
            ],
            Text(
              l.ecgCoverage(
                (row.durationMs <= 0
                        ? 0
                        : (row.sampleCount /
                                  (row.durationMs / 1000 * row.sampleRateHz!) *
                                  100)
                              .clamp(0, 100))
                    .toStringAsFixed(0),
              ),
              style: TextStyle(color: muted, fontSize: 12),
            ),
            ref
                .watch(ecgChunksProvider(row.recordingId))
                .when(
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('$e'),
                  data: (chunks) => EcgWaveform(
                    chunks: chunks,
                    hz: row.sampleRateHz!,
                    duration: row.durationMs / 1000,
                  ),
                ),
            OutlinedButton.icon(
              onPressed: () => runUiAction(context, () async {
                final file = await ref.read(ecgStorageProvider).exportCsv(row);
                if (context.mounted) {
                  await shareRecordingFile(context, file.path);
                }
              }),
              icon: const Icon(Icons.ios_share),
              label: Text(l.ecgExportCsv),
            ),
            if (sleepCapture)
              OutlinedButton.icon(
                onPressed: _exportingSleepRaw
                    ? null
                    : () => _exportSleepRaw(row),
                icon: _exportingSleepRaw
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.nightlight_outlined),
                label: Text(l.sleepEcgExportRaw),
              ),
            if (sleepCapture && _exportingSleepRaw) ...[
              const SizedBox(height: 6),
              const LinearProgressIndicator(minHeight: 3),
            ],
          ] else
            SectionCard(child: Text(l.ecgReportOnly)),
          if (ecgClinicalMode) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.activityNote,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 8,
                    onChanged: (_) => setState(() => _noteEdited = true),
                    decoration: InputDecoration(
                      hintText: l.activityNoteAdd,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (_noteEdited) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _savingNote ? null : () => _saveNote(row),
                        icon: _savingNote
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(l.save),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _preparingCoach ? null : () => _askCoach(row),
            icon: _preparingCoach
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chat_bubble_outline),
            label: Text(l.ecgAskCoach),
          ),
          if (_preparingCoach) ...[
            const SizedBox(height: 6),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (row.originalBase64 != null)
            OutlinedButton.icon(
              onPressed: () => runUiAction(context, () async {
                final file = await ref
                    .read(ecgStorageProvider)
                    .exportOriginal(row);
                if (context.mounted) {
                  await shareRecordingFile(context, file.path);
                }
              }),
              icon: const Icon(Icons.file_open_outlined),
              label: Text(l.ecgExportOriginal),
            ),
          const SizedBox(height: 12),
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.ecgLinkedWorkout),
              subtitle: Text(row.activityId ?? l.ecgIndependent),
              trailing: const Icon(Icons.link),
              onTap: () => runUiAction(context, () async {
                final activities = await ref.read(
                  recordingActivitiesProvider.future,
                );
                if (!context.mounted) return;
                final id = await showDialog<String>(
                  context: context,
                  builder: (dialog) => SimpleDialog(
                    title: Text(l.ecgLinkedWorkout),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(dialog, ''),
                        child: Text(l.ecgIndependent),
                      ),
                      for (final a in activities)
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(dialog, a.activityId),
                          child: Text(
                            '${dayText(a.startDate.toLocal())} · ${a.name}',
                          ),
                        ),
                    ],
                  ),
                );
                if (id != null) {
                  await ref
                      .read(ecgStorageProvider)
                      .associate(row.recordingId, id.isEmpty ? null : id);
                }
              }),
            ),
          ),
          Text(l.ecgLimitations, style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () async {
              if (!await confirmAction(
                    context,
                    l.deleteMeasurement,
                    l.ecgDeleteConfirm,
                  ) ||
                  !context.mounted) {
                return;
              }
              await runUiAction(context, () async {
                await ref.read(ecgStorageProvider).delete(row.recordingId);
                ref.invalidate(ecgChunksProvider(row.recordingId));
                if (context.mounted) Navigator.pop(context);
              });
            },
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            label: Text(
              l.deleteMeasurement,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top level on purpose: a closure inside a widget method would take the
/// widget's context and ref along, which cannot be sent to an isolate.
/// The medical warning before an ECG goes to the coach; true once the
/// athlete confirmed it. It is shown once ever: after the first confirmation
/// it is not asked again.
Future<bool> confirmEcgCoachWarning(BuildContext context, WidgetRef ref) async {
  final coach = ref.read(ecgCoachProvider);
  if (await coach.warningConfirmed()) return true;
  if (!context.mounted) return false;
  final l = context.l10n;
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialog) => AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.redAccent,
        size: 56,
      ),
      title: Text(
        ecgClinicalMode ? l.ecgCoachWarningTitle : l.ecgTrainingWarningTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Text(
          ecgClinicalMode ? l.ecgCoachWarningBody : l.ecgTrainingWarningBody,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(l.ecgCoachUnderstood),
        ),
      ],
    ),
  );
  if (accepted == true) await coach.confirmWarning();
  return accepted == true;
}

/// The warning comes first and must be confirmed; then the app analyses the
/// recording and opens the coach with the analysis as the chat's context.
Future<void> askCoachAboutEcg(
  BuildContext context,
  WidgetRef ref,
  EcgRecording row, {
  ValueChanged<bool>? onBusyChanged,
}) async {
  final l = context.l10n;
  log('[EcgCoach] ask tapped ${row.recordingId}');
  final accepted = await confirmEcgCoachWarning(context, ref);
  if (accepted != true || !context.mounted) return;
  onBusyChanged?.call(true);
  try {
    await runUiAction(context, () async {
      log('[EcgCoach] analysing ${row.recordingId}');
      final prompt = ecgClinicalMode
          ? l.ecgQuestionOverview
          : l.ecgQuestionTraining;
      final contextLines = await ref.read(ecgCoachProvider).detail(row, prompt);
      if (!context.mounted) return;

      openCoachTab(
        context,
        prompt: prompt,
        autoSend: true,
        card: CoachContextCard.ecg(
          recordingId: row.recordingId,
          recordedAt: row.recordedAt.toLocal(),
          facts: [recordingDuration(row.durationMs)],
          contextLines: contextLines,
          clinical: ecgClinicalMode,
        ),
      );
    });
  } finally {
    onBusyChanged?.call(false);
  }
}

class EcgWaveform extends StatefulWidget {
  const EcgWaveform({
    super.key,
    required this.chunks,
    required this.hz,
    required this.duration,
    this.live = false,
    this.height = 200,
    this.showControls = true,
    this.strokeWidth = 1.25,
  });
  final List<EcgChunk> chunks;
  final double hz, duration;
  final bool live;
  final double height, strokeWidth;
  final bool showControls;
  @override
  State<EcgWaveform> createState() => _WaveformState();
}

class _WaveformState extends State<EcgWaveform> {
  double window = 5, position = 0;
  @override
  Widget build(BuildContext context) {
    final maxPosition = math.max(0.0, widget.duration - window);
    final start = widget.live ? maxPosition : position.clamp(0.0, maxPosition);
    return Column(
      children: [
        if (widget.showControls) const SizedBox(height: 12),
        Semantics(
          label: context.l10n.ecgWaveform,
          child: LayoutBuilder(
            builder: (context, constraints) => Container(
              height: widget.height,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: duo(0xFF131C1A, 0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                size: Size(constraints.maxWidth, widget.height),
                painter: _EcgPainter(
                  widget.chunks,
                  widget.hz,
                  start,
                  start + window,
                  widget.strokeWidth,
                ),
              ),
            ),
          ),
        ),
        if (widget.showControls)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${start.toStringAsFixed(1)}–${(start + window).toStringAsFixed(1)} s · µV',
                style: TextStyle(fontSize: 11, color: muted),
              ),
              if (!widget.live)
                DropdownButton<double>(
                  value: window,
                  items: [
                    for (final n in [2.0, 5.0, 10.0, 30.0])
                      DropdownMenuItem(value: n, child: Text('${n.round()} s')),
                  ],
                  onChanged: (value) => setState(() => window = value ?? 5),
                ),
            ],
          ),
        if (!widget.live && widget.showControls)
          Slider(
            label: position.toStringAsFixed(1),
            value: start,
            max: math.max(.001, maxPosition),
            onChanged: maxPosition > 0
                ? (v) => setState(() => position = v)
                : null,
          ),
      ],
    );
  }
}

class _EcgPainter extends CustomPainter {
  _EcgPainter(this.chunks, this.hz, this.start, this.end, this.strokeWidth);
  final List<EcgChunk> chunks;
  final double hz, start, end, strokeWidth;
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (final chunk in chunks)
        ecgDisplayPoints(
          [chunk],
          hz,
          startSeconds: start,
          endSeconds: end,
          pixels: size.width.round(),
        ),
    ];
    var amplitude = 500.0;
    for (final group in points) {
      for (final p in group) {
        amplitude = math.max(amplitude, p.uv.abs());
      }
    }
    final grid = Paint()
      ..color = duo(0xFF28433B, 0xFFD2E6DD)
      ..strokeWidth = .5;
    for (var t = (start / .2).ceil() * .2; t < end; t += .2) {
      final x = (t - start) / (end - start) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final pen = Paint()
      ..color = fjAccent(mint)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final group in points) {
      final path = Path();
      for (var i = 0; i < group.length; i++) {
        final p = group[i],
            x = (p.seconds - start) / (end - start) * size.width,
            y = size.height / 2 - p.uv / (amplitude * 2.2) * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, pen);
    }
  }

  @override
  bool shouldRepaint(_EcgPainter old) => true;
}

String recordingDuration(int ms) {
  final seconds = ms ~/ 1000;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

String _ecgPhase(BuildContext context, EcgPhase phase) => switch (phase) {
  EcgPhase.connecting => context.l10n.recordingConnecting,
  EcgPhase.saving => context.l10n.saving,
  EcgPhase.recording => context.l10n.ecgRecording,
  _ => context.l10n.saved,
};

Future<TrainingDevice?> chooseTrainingDevice(
  BuildContext context,
  List<TrainingDevice> devices, {
  required String title,
  required String empty,
}) => showDialog<TrainingDevice>(
  context: context,
  builder: (dialog) => SimpleDialog(
    title: Text(title),
    children: [
      if (devices.isEmpty)
        Padding(padding: const EdgeInsets.all(24), child: Text(empty)),
      for (final d in devices)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialog, d),
          child: Text('${d.name} · ${d.rssi} dBm'),
        ),
      SimpleDialogOption(
        onPressed: () => Navigator.pop(dialog),
        child: Text(context.l10n.cancel),
      ),
    ],
  ),
);

Future<void> shareRecordingFile(BuildContext context, String path) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path)],
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

Future<void> shareRecordingFiles(
  BuildContext context,
  List<String> paths,
) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: [for (final path in paths) XFile(path)],
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

/// The ECG segments recorded with an activity, in its details: a short look
/// at the first one, each segment one tap away.
class ActivityEcgCard extends ConsumerWidget {
  const ActivityEcgCard({super.key, required this.activityId});
  final String activityId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = [
      for (final r in ref.watch(ecgHistoryProvider).valueOrNull ?? const [])
        if (r.activityId == activityId && r.status != 'recording') r,
    ]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    if (rows.isEmpty) return const SizedBox.shrink();
    final first = rows.first;
    return SectionCard(
      title: context.l10n.ecgTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (first.kind == 'waveform' && first.sampleRateHz != null)
            ref
                .watch(ecgChunksProvider(first.recordingId))
                .when(
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('$e'),
                  data: (chunks) => EcgWaveform(
                    chunks: chunks,
                    hz: first.sampleRateHz!,
                    duration: first.durationMs / 1000,
                  ),
                ),
          for (final r in rows)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.monitor_heart_outlined,
                color: Color(0xFFFF5C7A),
              ),
              title: Text(
                '${TimeOfDay.fromDateTime(r.recordedAt.toLocal()).format(context)} · ${recordingDuration(r.durationMs)}',
              ),
              subtitle: Text(r.deviceName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAppSheet(context, EcgDetailSheet(recording: r)),
            ),
        ],
      ),
    );
  }
}

/// A recording on its own, as an entry of the activity history. Swiped like
/// an activity: to the left it is deleted (with undo), to the right the
/// coach is asked about it, the same way as from its details.
class EcgHistoryTile extends ConsumerWidget {
  const EcgHistoryTile({super.key, required this.recording});
  final EcgRecording recording;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = recording;
    return SwipeActionTile(
      deleteLabel: context.l10n.delete,
      coachLabel: context.l10n.askCoachShort,
      onDelete: () async => deleteEcgWithUndo(context, r),
      // A report alone holds no curve to analyse: its details say so.
      onCoach: () => r.kind == 'waveform' && r.sampleRateHz != null
          ? askCoachAboutEcg(context, ref, r)
          : showAppSheet(context, EcgDetailSheet(recording: r)),
      child: _card(context, r),
    );
  }

  Widget _card(BuildContext context, EcgRecording r) {
    const color = Color(0xFFFF5C7A);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          leading: CircleAvatar(
            radius: 17,
            backgroundColor: color.withValues(alpha: .12),
            child: const Icon(
              Icons.monitor_heart_outlined,
              size: 19,
              color: color,
            ),
          ),
          title: Text(
            '${context.l10n.ecgTitle} · ${r.deviceName}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${TimeOfDay.fromDateTime(r.recordedAt.toLocal()).format(context)} · ${r.kind == 'report' ? context.l10n.ecgReport : recordingDuration(r.durationMs)}',
            style: TextStyle(fontSize: 9, color: muted),
          ),
          trailing: const Icon(Icons.chevron_right, size: 15, color: color),
          onTap: () => showAppSheet(context, EcgDetailSheet(recording: r)),
        ),
      ),
    );
  }
}

/// Deletes a recording with undo. It leaves the lists at once and the snack
/// bar offers to bring it back; only once that offer has passed is it deleted
/// for good. A recording has no "Recently deleted" like an activity, so this
/// is its only way back. If the delete fails it shows again.
void deleteEcgWithUndo(BuildContext context, EcgRecording r) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final container = ProviderScope.containerOf(context);
  final l = context.l10n;
  final pending = container.read(pendingEcgDeletesProvider.notifier);
  final id = r.recordingId;
  pending.update((s) => {...s, id});
  void show() => pending.update((s) => {...s}..remove(id));
  Future<void> delete() async {
    try {
      await container.read(ecgStorageProvider).delete(id);
    } catch (e) {
      log('[Ecg] delete failed: $e');
      show();
      messenger?.showSnackBar(
        SnackBar(content: Text(l.deletingFailedFailure('$e'))),
      );
    }
  }

  if (messenger == null) {
    unawaited(delete());
    return;
  }
  messenger.hideCurrentSnackBar();
  final closed = messenger
      .showSnackBar(
        SnackBar(
          content: Text(l.activityDeleted(l.ecgTitle)),
          // A snack bar with an action stays until dismissed; this one has
          // to pass, or the recording would never be deleted.
          persist: false,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: l.undo, onPressed: () {}),
        ),
      )
      .closed;
  unawaited(
    closed.then((reason) {
      if (reason == SnackBarClosedReason.action) {
        show();
      } else {
        return delete();
      }
    }),
  );
}
