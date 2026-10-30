import FjeliaMLX
import Flutter
import UIKit

/// MLX never runs while iOS has moved the app into the background: Metal work
/// there can terminate the process. Downloads remain restartable in Dart.
final class LocalModelChannel {
    private let engine = FjeliaMLXEngine()
    private var generation: Task<Void, Never>?
    private var backgroundObserver: NSObjectProtocol?

    static func register(messenger: FlutterBinaryMessenger) {
        let handler = LocalModelChannel()
        let channel = FlutterMethodChannel(name: "fjelia/local_model", binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in handler.handle(call, result: result) }
        handler.backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak handler] _ in
            handler?.generation?.cancel()
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "availability":
            let args = call.arguments as? [String: Any]
            let minimumMemory = (args?["minimumMemoryBytes"] as? NSNumber)?.uint64Value ?? 3_500_000_000
            let requiresIPhone18 = args?["requiresIPhone18"] as? Bool ?? false
            let reason = FjeliaMLXEngine.unavailableReason(
                minimumMemoryBytes: minimumMemory, requiresIPhone18: requiresIPhone18
            )
            if let reason {
                result(["supported": false, "reason": reason])
            } else {
                result(["supported": true])
            }
        case "excludeFromBackup":
            guard let path = call.arguments as? String else {
                result(FlutterError(code: "arguments", message: nil, details: nil))
                return
            }
            do {
                var directory = URL(fileURLWithPath: path)
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try directory.setResourceValues(values)
                result(nil)
            } catch {
                result(FlutterError(code: "storage", message: nil, details: nil))
            }
        case "unload":
            let pending = generation
            pending?.cancel()
            Task { @MainActor in
                await pending?.value
                do {
                    try await engine.unload()
                    result(nil)
                } catch {
                    result(FlutterError(code: "busy", message: nil, details: nil))
                }
            }
        case "generate":
            guard generation == nil else {
                result(FlutterError(code: "busy", message: nil, details: nil))
                return
            }
            guard UIApplication.shared.applicationState == .active else {
                result(FlutterError(code: "cancelled", message: nil, details: nil))
                return
            }
            guard let args = call.arguments as? [String: Any],
                let path = args["directory"] as? String,
                let raw = args["messages"] as? [[String: String]]
            else {
                result(FlutterError(code: "arguments", message: nil, details: nil))
                return
            }
            let messages = raw.map {
                LocalModelMessage(role: $0["role"] ?? "user", content: $0["content"] ?? "")
            }
            let maxTokens = args["maxTokens"] as? Int ?? 512
            let minimumMemory = (args["minimumMemoryBytes"] as? NSNumber)?.uint64Value ?? 3_500_000_000
            let requiresIPhone18 = args["requiresIPhone18"] as? Bool ?? false
            generation = Task { @MainActor in
                defer { generation = nil }
                do {
                    let text = try await engine.generate(
                        directory: URL(fileURLWithPath: path), messages: messages,
                        maxTokens: maxTokens, minimumMemoryBytes: minimumMemory,
                        requiresIPhone18: requiresIPhone18
                    )
                    result(text)
                } catch is CancellationError {
                    result(FlutterError(code: "cancelled", message: nil, details: nil))
                } catch let error as FjeliaMLXError {
                    result(FlutterError(code: error.rawValue, message: nil, details: nil))
                } catch {
                    // Prompts and health data must not escape through diagnostics.
                    result(FlutterError(code: "generation", message: nil, details: nil))
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
