import Foundation
import Darwin
import Metal
import MLX
import MLXLLM
import MLXLMCommon

public struct LocalModelMessage: Sendable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public enum FjeliaMLXError: String, Error {
    case unsupported, device, busy, notInstalled, contextTooLong, empty, cancelled
}

/// The downloader lives in Dart. This engine only ever opens a local directory;
/// there is no Hub identifier, network download or cloud fallback in inference.
public actor FjeliaMLXEngine {
    private var model: ModelContainer?
    private var loadedDirectory: URL?
    private var generating = false

    public init() {}

    /// iPhone 17 Pro is iPhone18,1; the iPhone 18 family starts at iPhone19,x.
    public static func isIPhone18OrNewer(_ identifier: String) -> Bool {
        guard identifier.hasPrefix("iPhone") else { return false }
        let parts = identifier.dropFirst(6).split(separator: ",")
        guard parts.count == 2, let family = Int(parts[0]), Int(parts[1]) != nil
        else { return false }
        return family >= 19
    }

    public static func unavailableReason(
        minimumMemoryBytes: UInt64 = 3_500_000_000,
        requiresIPhone18: Bool = false
    ) -> String? {
        #if targetEnvironment(simulator)
        return "simulator"
        #else
        #if os(iOS)
        if requiresIPhone18 {
            var system = utsname()
            uname(&system)
            let identifier = withUnsafeBytes(of: &system.machine) { bytes in
                String(decoding: bytes.prefix(while: { $0 != 0 }), as: UTF8.self)
            }
            guard isIPhone18OrNewer(identifier) else { return "device" }
        }
        #endif
        guard let device = MTLCreateSystemDefaultDevice() else { return "gpu" }
        // MLX's matrix kernels need the Apple7 feature set (A14/M1 and newer).
        // Check the capability, not a brittle list of iPhone model identifiers.
        guard device.supportsFamily(.apple7) else { return "gpu" }
        guard ProcessInfo.processInfo.physicalMemory >= minimumMemoryBytes else { return "memory" }
        return nil
        #endif
    }

    public func unload() throws {
        guard !generating else { throw FjeliaMLXError.busy }
        model = nil
        loadedDirectory = nil
        Memory.clearCache()
    }

    public func generate(
        directory: URL,
        messages: [LocalModelMessage],
        maxTokens: Int,
        minimumMemoryBytes: UInt64 = 3_500_000_000,
        requiresIPhone18: Bool = false
    ) async throws -> String {
        guard !generating else { throw FjeliaMLXError.busy }
        guard let last = messages.last, last.role == "user" else { throw FjeliaMLXError.empty }
        let markerURL = directory.appendingPathComponent("installed.json")
        guard let markerData = try? Data(contentsOf: markerURL),
            let object = try? JSONSerialization.jsonObject(with: markerData),
            let marker = object as? [String: String]
        else { throw FjeliaMLXError.notInstalled }
        // Enforce the policy for already downloaded 4B installations too.
        let needsIPhone18 = requiresIPhone18 || marker["model"] == "mlx-community/Qwen3.5-4B-MLX-4bit"
        if let reason = Self.unavailableReason(
            minimumMemoryBytes: minimumMemoryBytes, requiresIPhone18: needsIPhone18
        ) {
            throw reason == "device" ? FjeliaMLXError.device : FjeliaMLXError.unsupported
        }
        generating = true
        defer {
            generating = false
            // Do not retain a multi-GB model beside Fjelia's charts and sync.
            model = nil
            loadedDirectory = nil
            Memory.clearCache()
        }
        try Task.checkCancellation()
        Memory.cacheLimit = 32 * 1024 * 1024
        if model == nil || loadedDirectory != directory {
            model = try await LLMModelFactory.shared.loadContainer(
                configuration: ModelConfiguration(directory: directory)
            )
            loadedDirectory = directory
        }
        guard let model else { throw FjeliaMLXError.notInstalled }
        let instructions = messages.filter { $0.role == "system" }.map(\.content).joined(separator: "\n")
        let history = messages.dropLast().filter { $0.role != "system" }.map { message in
            Chat.Message(
                role: message.role == "assistant" ? .assistant : .user,
                content: message.content
            )
        }
        let tokenCount = await model.perform { context in
            context.tokenizer.encode(text: messages.map(\.content).joined(separator: "\n")).count
        }
        // Leave room for role tokens and the response. Never silently cut a
        // question or a health record in the middle of a value.
        guard tokenCount + maxTokens + 256 <= 8192 else { throw FjeliaMLXError.contextTooLong }
        let session = ChatSession(
            model,
            instructions: instructions,
            history: history,
            generateParameters: GenerateParameters(
                maxTokens: min(max(maxTokens, 64), 768),
                temperature: 0.7,
                topP: 0.8,
                topK: 20,
                presencePenalty: 1.5,
                prefillStepSize: 128
            ),
            additionalContext: ["enable_thinking": false]
        )
        var reply = ""
        for try await chunk in session.streamResponse(to: last.content) {
            try Task.checkCancellation()
            reply += chunk
        }
        try Task.checkCancellation()
        let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FjeliaMLXError.empty }
        return trimmed
    }
}
