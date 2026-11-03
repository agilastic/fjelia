import AVFoundation
import ImageIO
import Flutter
import HealthKit
import PDFKit
import UIKit
import UserNotifications
// Needed for FlutterLocalNotificationsPlugin.setPluginRegistrantCallback.
import flutter_local_notifications
// The plugins the headless workout check uses.
import device_info_plus
import flutter_secure_storage_darwin
import health
import shared_preferences_foundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Local notifications (the post-training HRV reminder) show and report
    // their actions through this delegate, also while the app is running.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    // HealthKit expects observer queries to be set up on every launch, also
    // when it launched the app in the background for a new workout.
    HealthWorkoutObserver.shared.startIfEnabled()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Lets the action isolate reach the plugins when the app is not in front.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LocalModelChannel") {
      LocalModelChannel.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PdfTextChannel") {
      PdfTextChannel.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MediaChannel") {
      MediaChannel.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ActivityFileChannel") {
      ActivityFileChannel.shared.attach(registrar: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HealthWorkoutObserver") {
      HealthWorkoutObserver.shared.attach(messenger: registrar.messenger())
    }
  }
}

/// Wakes Fjelia when a workout reaches Apple Health, so the nutrition and
/// post-workout HRV reminders are scheduled without opening the app.
///
/// While the app's engine is alive the check runs there (`workoutsChanged`).
/// When iOS launched the app in the background, a headless engine runs the
/// Dart entry point `healthBackgroundMain`, which calls `done` when finished.
final class HealthWorkoutObserver {
  static let shared = HealthWorkoutObserver()

  private static let enabledKey = "fjelia.healthBackgroundDelivery"
  private static let channelName = "fjelia/health_background"
  /// iOS gives a woken app about 30 seconds; Dart stops after 22.
  private static let budget: TimeInterval = 26
  /// How long a launch may take to bring up the app's own engine.
  private static let engineGrace: TimeInterval = 2

  private let store = HKHealthStore()
  private var query: HKObserverQuery?
  private var mainChannel: FlutterMethodChannel?
  private var headless: FlutterEngine?
  private var headlessChannel: FlutterMethodChannel?
  private var completions: [HKObserverQueryCompletionHandler] = []
  private var running = false
  private var again = false
  private var runId = 0
  private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

  func startIfEnabled() {
    if UserDefaults.standard.bool(forKey: Self.enabledKey) { start() }
  }

  /// The app's own engine. Dart turns delivery on or off through it.
  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setEnabled", let on = call.arguments as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.setEnabled(on)
      result(nil)
    }
    mainChannel = channel
  }

  private func setEnabled(_ on: Bool) {
    UserDefaults.standard.set(on, forKey: Self.enabledKey)
    if on { start() } else { stop() }
  }

  private func start() {
    guard HKHealthStore.isHealthDataAvailable(), query == nil else { return }
    let type = HKObjectType.workoutType()
    let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completion, error in
      if let error {
        NSLog("[HealthBackground] observer error: \(error.localizedDescription)")
        completion()
        return
      }
      DispatchQueue.main.async {
        guard let self else { return completion() }
        self.workoutsChanged(completion)
      }
    }
    store.execute(query)
    self.query = query
    store.enableBackgroundDelivery(for: type, frequency: .immediate) { ok, error in
      if !ok {
        NSLog("[HealthBackground] delivery not enabled: \(error?.localizedDescription ?? "-")")
      }
    }
  }

  private func stop() {
    if let query { store.stop(query) }
    query = nil
    store.disableBackgroundDelivery(for: HKObjectType.workoutType()) { _, _ in }
  }

  private func workoutsChanged(_ completion: @escaping HKObserverQueryCompletionHandler) {
    // Health data is encrypted while the phone is locked. Without the
    // completion call, HealthKit delivers again later.
    guard UIApplication.shared.isProtectedDataAvailable else { return }
    completions.append(completion)
    if running {
      again = true
      return
    }
    run()
  }

  private func run() {
    running = true
    again = false
    runId += 1
    let id = runId
    if backgroundTask == .invalid {
      backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "HealthWorkout") {
        [weak self] in
        self?.finish(id)
        self?.endBackgroundTask()
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.budget) { [weak self] in
      self?.finish(id)
    }
    if let channel = mainChannel {
      ask(channel, id)
      return
    }
    // A normal launch connects a scene and starts the app's engine shortly;
    // its own sync covers the workout. Only a background launch has neither.
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.engineGrace) { [weak self] in
      guard let self, self.running, id == self.runId else { return }
      if let channel = self.mainChannel {
        self.ask(channel, id)
      } else if UIApplication.shared.connectedScenes.isEmpty {
        self.startHeadless(id)
      } else {
        self.finish(id)
      }
    }
  }

  private func ask(_ channel: FlutterMethodChannel, _ id: Int) {
    channel.invokeMethod("workoutsChanged", arguments: nil) { [weak self] _ in
      self?.finish(id)
    }
  }

  private func startHeadless(_ id: Int) {
    let engine = FlutterEngine(name: "health-background", project: nil, allowHeadlessExecution: true)
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      result(nil)
      if call.method == "done" { self?.finish(id) }
    }
    headless = engine
    headlessChannel = channel
    guard engine.run(withEntrypoint: "healthBackgroundMain") else {
      NSLog("[HealthBackground] headless engine did not start")
      finish(id)
      return
    }
    // Only what the check needs: no Bluetooth, location or web views.
    func add(_ name: String, _ register: (FlutterPluginRegistrar) -> Void) {
      if let registrar = engine.registrar(forPlugin: name) { register(registrar) }
    }
    add("HealthPlugin") { HealthPlugin.register(with: $0) }
    add("FPPDeviceInfoPlusPlugin") { FPPDeviceInfoPlusPlugin.register(with: $0) }
    add("SharedPreferencesPlugin") { SharedPreferencesPlugin.register(with: $0) }
    add("FlutterSecureStorageDarwinPlugin") { FlutterSecureStorageDarwinPlugin.register(with: $0) }
    add("FlutterLocalNotificationsPlugin") { FlutterLocalNotificationsPlugin.register(with: $0) }
  }

  private func finish(_ id: Int) {
    guard running, id == runId else { return }
    running = false
    headlessChannel?.setMethodCallHandler(nil)
    headlessChannel = nil
    headless?.destroyContext()
    headless = nil
    let done = completions
    completions = []
    done.forEach { $0() }
    // A workout that arrived during the run gets its own check.
    if again {
      run()
      return
    }
    endBackgroundTask()
  }

  private func endBackgroundTask() {
    guard backgroundTask != .invalid else { return }
    UIApplication.shared.endBackgroundTask(backgroundTask)
    backgroundTask = .invalid
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

/// Receives FIT, GPX and TCX files opened in Fjelia (share sheet, Files app,
/// AirDrop). Each file is copied to the temporary folder and its path kept
/// until Dart takes it (`ActivityFileInbox` in activity_file_import_provider).
final class ActivityFileChannel: NSObject, FlutterSceneLifeCycleDelegate {
  static let shared = ActivityFileChannel()

  private static let extensions: Set<String> = ["fit", "gpx", "tcx"]
  private var channel: FlutterMethodChannel?
  private var pending: [String] = []

  func attach(registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "fjelia/activity_files", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "takePending", let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self.pending)
      self.pending.removeAll()
    }
    self.channel = channel
    registrar.addSceneDelegate(self)
  }

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    _ = receive(connectionOptions?.urlContexts ?? [])
    return false
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    return receive(URLContexts)
  }

  private func receive(_ contexts: Set<UIOpenURLContext>) -> Bool {
    var received = false
    for url in contexts.map(\.url) where url.isFileURL {
      guard Self.extensions.contains(url.pathExtension.lowercased()) else { continue }
      let scoped = url.startAccessingSecurityScopedResource()
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      let folder = FileManager.default.temporaryDirectory
        .appendingPathComponent("opened_activities", isDirectory: true)
      let copy = folder.appendingPathComponent(
        "\(UUID().uuidString.prefix(8))-\(url.lastPathComponent)")
      do {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: url, to: copy)
        pending.append(copy.path)
        received = true
      } catch {
        NSLog("[ActivityFile] could not copy \(url.lastPathComponent): \(error)")
      }
      // Files handed over by copy land in Documents/Inbox; don't keep them.
      if url.path.contains("/Documents/Inbox/") {
        try? FileManager.default.removeItem(at: url)
      }
    }
    if received { channel?.invokeMethod("opened", arguments: nil) }
    return received
  }
}

/// Thumbnails and size of photos and videos, and videos converted to 1080p,
/// for the media attached to activities (`MediaService` on the Dart side).
final class MediaChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "fjelia/media", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      let url = URL(fileURLWithPath: path)
      switch call.method {
      case "thumbnail":
        guard let out = args["out"] as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        let side = CGFloat(args["max"] as? Int ?? 480)
        if args["video"] as? Bool ?? false {
          videoThumbnail(url, out: URL(fileURLWithPath: out), side: side, result: result)
        } else {
          photoThumbnail(url, out: URL(fileURLWithPath: out), side: side, result: result)
        }
      case "preparePhoto":
        guard let out = args["out"] as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        let side = CGFloat(args["max"] as? Int ?? 2560)
        preparePhoto(url, out: URL(fileURLWithPath: out), side: side, result: result)
      case "transcodeVideo":
        guard let out = args["out"] as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        transcode(url, out: URL(fileURLWithPath: out), result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func reply(_ result: @escaping FlutterResult, _ value: Any?) {
    DispatchQueue.main.async { result(value) }
  }

  private static func photoThumbnail(
    _ url: URL, out: URL, side: CGFloat, result: @escaping FlutterResult
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard let image = UIImage(contentsOfFile: url.path) else {
        reply(result, FlutterError(code: "open_failed", message: "Unreadable photo.", details: nil))
        return
      }
      let size = image.size
      let scale = min(1, side / max(size.width, size.height))
      let target = CGSize(width: size.width * scale, height: size.height * scale)
      let thumb = image.preparingThumbnail(of: target) ?? image
      do {
        try thumb.jpegData(compressionQuality: 0.8)?.write(to: out)
        reply(result, ["width": Int(size.width), "height": Int(size.height)])
      } catch {
        reply(result, FlutterError(code: "write_failed", message: "\(error)", details: nil))
      }
    }
  }

  private static func videoThumbnail(
    _ url: URL, out: URL, side: CGFloat, result: @escaping FlutterResult
  ) {
    Task {
      do {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        var width = 0
        var height = 0
        if let track = try await asset.loadTracks(withMediaType: .video).first {
          let (natural, transform) = try await track.load(.naturalSize, .preferredTransform)
          let shown = natural.applying(transform)
          width = Int(abs(shown.width))
          height = Int(abs(shown.height))
        }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: side, height: side)
        let time = CMTime(seconds: min(1, duration.seconds / 2), preferredTimescale: 600)
        let (image, _) = try await generator.image(at: time)
        try UIImage(cgImage: image).jpegData(compressionQuality: 0.8)?.write(to: out)
        var info: [String: Any] = [
          "width": width, "height": height,
          "durationMs": Int((duration.seconds * 1000).rounded()),
        ]
        // When and where it was filmed, as the camera wrote it.
        for item in try await asset.load(.commonMetadata) {
          if item.commonKey == .commonKeyCreationDate,
            let date = try await item.load(.dateValue)
          {
            info["takenAt"] = Int(date.timeIntervalSince1970 * 1000)
          }
          if item.commonKey == .commonKeyLocation,
            let iso = try await item.load(.stringValue),
            let place = parseIso6709(iso)
          {
            info["lat"] = place.0
            info["lng"] = place.1
          }
        }
        reply(result, info)
      } catch {
        reply(result, FlutterError(code: "thumbnail_failed", message: "\(error)", details: nil))
      }
    }
  }

  /// "+52.3740+009.7380+070.000/" → (52.374, 9.738).
  private static func parseIso6709(_ text: String) -> (Double, Double)? {
    let pattern = #"([+-]\d+(?:\.\d+)?)([+-]\d+(?:\.\d+)?)"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
      let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
      let latRange = Range(match.range(at: 1), in: text),
      let lngRange = Range(match.range(at: 2), in: text),
      let lat = Double(text[latRange]), let lng = Double(text[lngRange]),
      abs(lat) <= 90, abs(lng) <= 180
    else { return nil }
    return (lat, lng)
  }

  /// The photo as JPEG of at most [side] px, the right way up, together with
  /// when and where it was taken (EXIF/GPS), which the picker's own scaling
  /// would drop.
  private static func preparePhoto(
    _ url: URL, out: URL, side: CGFloat, result: @escaping FlutterResult
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        reply(result, FlutterError(code: "open_failed", message: "Unreadable photo.", details: nil))
        return
      }
      let props =
        CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
      let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: side,
      ]
      guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
        let data = UIImage(cgImage: image).jpegData(compressionQuality: 0.85)
      else {
        reply(result, FlutterError(code: "resize_failed", message: "Photo not converted.", details: nil))
        return
      }
      do {
        try data.write(to: out)
      } catch {
        reply(result, FlutterError(code: "write_failed", message: "\(error)", details: nil))
        return
      }
      var info: [String: Any] = ["width": image.width, "height": image.height]
      let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
      if let original = exif?[kCGImagePropertyExifDateTimeOriginal] as? String {
        let format = DateFormatter()
        format.locale = Locale(identifier: "en_US_POSIX")
        format.dateFormat = "yyyy:MM:dd HH:mm:ss"
        // EXIF time is the camera's local time; an offset says which zone.
        if let offset = exif?[kCGImagePropertyExifOffsetTimeOriginal] as? String {
          format.dateFormat = "yyyy:MM:dd HH:mm:ssZZZZZ"
          if let date = format.date(from: original + offset) {
            info["takenAt"] = Int(date.timeIntervalSince1970 * 1000)
          }
        } else if let date = format.date(from: original) {
          info["takenAt"] = Int(date.timeIntervalSince1970 * 1000)
        }
      }
      if let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any],
        let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
        let lng = gps[kCGImagePropertyGPSLongitude] as? Double
      {
        let north = (gps[kCGImagePropertyGPSLatitudeRef] as? String ?? "N") != "S"
        let east = (gps[kCGImagePropertyGPSLongitudeRef] as? String ?? "E") != "W"
        info["lat"] = north ? lat : -lat
        info["lng"] = east ? lng : -lng
      }
      reply(result, info)
    }
  }

  /// At most 1920×1080, H.264 in MP4. A video that is already smaller keeps
  /// its size. Returns false when the export fails; the caller then keeps
  /// the original.
  private static func transcode(_ url: URL, out: URL, result: @escaping FlutterResult) {
    let asset = AVURLAsset(url: url)
    guard
      let session = AVAssetExportSession(
        asset: asset, presetName: AVAssetExportPreset1920x1080)
    else {
      reply(result, false)
      return
    }
    try? FileManager.default.removeItem(at: out)
    session.outputURL = out
    session.outputFileType = .mp4
    session.shouldOptimizeForNetworkUse = true
    session.exportAsynchronously {
      reply(result, session.status == .completed)
    }
  }
}
