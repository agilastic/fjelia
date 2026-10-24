import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/hilo_report_import_service.dart';
import 'database_provider.dart';
import 'day_data_provider.dart';
import 'health_connect_provider.dart';

export '../services/hilo_report_import_service.dart' show HiloReportPreview;
export '../services/hilo_report_parser.dart' show HiloReportFormatException;

final hiloReportImportActionsProvider = Provider<HiloReportImportActions>(
  HiloReportImportActions.new,
);

/// Result of an import: readings added and, when Health export is enabled,
/// readings written to Apple Health.
class HiloReportImportResult {
  const HiloReportImportResult({required this.added, this.exported = 0});
  final int added;
  final int exported;
}

class HiloReportImportActions {
  HiloReportImportActions(this.ref);
  final Ref ref;

  HiloReportImportService get _service =>
      HiloReportImportService(ref.read(databaseProvider));

  bool get isSupported => _service.isSupported;

  /// Lets the user pick a report PDF and returns what it contains, or null
  /// when nothing was picked.
  Future<HiloReportPreview?> pickAndPreview() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (files.isEmpty) return null;
    return _service.preview(await files.single.xFile.readAsBytes());
  }

  Future<HiloReportImportResult> import(HiloReportPreview preview) async {
    final added = await _service.import(preview);
    ref
      ..invalidate(bpForDateProvider)
      ..invalidate(bpPeriodReadingsProvider)
      ..invalidate(bpWeekSummaryProvider);
    var exported = 0;
    if (added > 0 && ref.read(hiloWriteHealthProvider)) {
      final db = ref.read(databaseProvider);
      final report = preview.report;
      final rows = await db.getBpInRange(
        report.first,
        report.last.add(const Duration(minutes: 1)),
      );
      final result = await ref
          .read(healthConnectServiceProvider)
          .exportBloodPressure([
            for (final r in rows)
              if (r.measurementType == HiloReportImportService.measurementType)
                r,
          ]);
      exported = result.written;
    }
    return HiloReportImportResult(added: added, exported: exported);
  }
}
