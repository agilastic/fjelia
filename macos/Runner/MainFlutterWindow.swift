import Cocoa
import FlutterMacOS
import PDFKit

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    PdfTextChannel.register(
      messenger: flutterViewController.registrar(forPlugin: "PdfTextChannel").messenger)

    super.awakeFromNib()
  }
}

/// Reads the text of a PDF with PDFKit for the Dart side (`PdfTextExtractor`).
final class PdfTextChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "fjelia/pdf_text", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "pages", let path = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        guard let document = PDFDocument(url: URL(fileURLWithPath: path)) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "open_failed", message: "Could not open the PDF.", details: nil))
          }
          return
        }
        let pages = (0..<document.pageCount).map { document.page(at: $0)?.string ?? "" }
        DispatchQueue.main.async { result(pages) }
      }
    }
  }
}
