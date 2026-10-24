import 'dart:io';

import 'package:flutter/services.dart';

/// Reads the text of a PDF with the platform's PDF engine (PDFKit on iOS and
/// macOS).
class PdfTextExtractor {
  const PdfTextExtractor();

  static const _channel = MethodChannel('fjelia/pdf_text');

  bool get isSupported => Platform.isIOS || Platform.isMacOS;

  /// The text of every page, in page order.
  Future<List<String>> pages(String path) async {
    if (!isSupported) {
      throw UnsupportedError('Reading PDF reports is not supported here.');
    }
    final pages = await _channel.invokeListMethod<String>('pages', path);
    return pages ?? const [];
  }
}
