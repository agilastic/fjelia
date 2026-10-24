import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../db/database.dart';
import 'hilo_report_parser.dart';
import 'pdf_text_extractor.dart';

/// A parsed report together with how much of it is new.
class HiloReportPreview {
  const HiloReportPreview({
    required this.report,
    required this.fresh,
    required this.alreadyStored,
  });

  final HiloReport report;
  final List<BpMeasurementsCompanion> fresh;
  final int alreadyStored;

  int get newReadings => fresh.length;
}

/// Imports the readings of a Hilo monthly report (PDF) that the user exported
/// from the Hilo app.
class HiloReportImportService {
  HiloReportImportService(
    this._db, [
    this._extractor = const PdfTextExtractor(),
  ]);

  final AppDatabase _db;
  final PdfTextExtractor _extractor;

  /// Stored with this type so the origin of a reading stays visible.
  static const measurementType = 'REPORT';

  bool get isSupported => _extractor.isSupported;

  /// Parses the PDF [bytes] of a report and compares it with what is stored.
  Future<HiloReportPreview> preview(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/hilo_report_${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    try {
      return await previewPages(await _extractor.pages(file.path));
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  /// Same as [preview] for the text of the report pages.
  Future<HiloReportPreview> previewPages(List<String> pages) async {
    final report = HiloReportParser.parse(pages);
    final all = [
      for (final r in report.readings)
        BpMeasurementsCompanion.insert(
          measuredAt: r.at,
          systolic: r.systolic,
          diastolic: r.diastolic,
          heartRate: r.heartRate,
          measurementType: const Value(measurementType),
        ),
    ];
    final fresh = await _db.newBpMeasurements(all);
    return HiloReportPreview(
      report: report,
      fresh: fresh,
      alreadyStored: all.length - fresh.length,
    );
  }

  /// Stores the new readings of [preview] and returns how many were added.
  Future<int> import(HiloReportPreview preview) =>
      _db.insertBpMeasurements(preview.fresh);
}
