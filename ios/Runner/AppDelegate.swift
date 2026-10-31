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
