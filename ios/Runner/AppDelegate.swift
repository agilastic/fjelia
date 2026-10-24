import Flutter
import PDFKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PdfTextChannel") {
      PdfTextChannel.register(messenger: registrar.messenger())
    }
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
