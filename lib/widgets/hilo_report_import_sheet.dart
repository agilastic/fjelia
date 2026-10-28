import '../l10n/l10n_ext.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/hilo_report_import_provider.dart';
import 'app_widgets.dart';

/// Imports the readings of a Hilo blood-pressure report (PDF) that the user
/// exported from the Hilo app.
class HiloReportImportSheet extends ConsumerStatefulWidget {
  const HiloReportImportSheet({super.key});

  @override
  ConsumerState<HiloReportImportSheet> createState() => _State();
}

class _State extends ConsumerState<HiloReportImportSheet> {
  HiloReportPreview? preview;
  HiloReportImportResult? done;
  bool busy = false;
  String? error;

  Future<void> pick() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final p = await ref
          .read(hiloReportImportActionsProvider)
          .pickAndPreview();
      if (mounted && p != null) setState(() => preview = p);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save(HiloReportPreview p) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await ref.read(hiloReportImportActionsProvider).import(p);
      if (mounted) setState(() => done = r);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final supported = ref.watch(hiloReportImportActionsProvider).isSupported;
    final p = preview;
    final r = done;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(context.l10n.addHiloBpReport),
            const SizedBox(height: 8),
            Text(
              context.l10n.exportTheMonthlyReportAs,
              style: TextStyle(color: muted, fontSize: 12),
            ),
            if (!supported)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  context.l10n.readingPdfReportsIsOnly,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            if (r != null) ...[
              Text(
                r.added == 0
                    ? context.l10n.nothingNewAllReadingsWere
                    : '${r.added} readings added'
                          '${r.exported > 0 ? ', ${r.exported} written to Apple Health' : ''}.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.done),
              ),
            ] else if (p != null) ...[
              Text(
                '${p.report.readings.length} readings, '
                '${day(p.report.first)} to ${day(p.report.last)}',
              ),
              Text(
                '${p.newReadings} new, ${p.alreadyStored} already stored'
                '${p.report.rejected > 0 ? ', ${p.report.rejected} skipped (implausible)' : ''}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy || p.newReadings == 0 ? null : () => save(p),
                child: Text(
                  busy
                      ? context.l10n.importing
                      : context.l10n.importNewreadings(p.newReadings),
                ),
              ),
              TextButton(
                onPressed: busy ? null : pick,
                child: Text(context.l10n.chooseAnotherReport),
              ),
            ] else
              FilledButton.icon(
                onPressed: busy || !supported ? null : pick,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(
                  busy ? context.l10n.reading : context.l10n.chooseReportPdf,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
