import Foundation
import XCTest
@testable import FjeliaMLX

final class LocalInferenceTests: XCTestCase {
    /// An opt-in fixture exported by a Dart coach test. Only
    /// synthetic data is used; Dart then validates the actual generated reply.
    func testDailyScheduleFixture() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let path = environment["FJELIA_LOCAL_MODEL_TEST_DIR"],
            let fixture = environment["FJELIA_QWEN_SCHEDULE_FIXTURE"]
        else { throw XCTSkip("Set the model and schedule-fixture paths") }
        if let reason = FjeliaMLXEngine.unavailableReason() {
            throw XCTSkip("MLX unavailable here: \(reason)")
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: fixture))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let messages = try XCTUnwrap(object["messages"] as? [[String: String]])
        let reply = try await FjeliaMLXEngine().generate(
            directory: URL(fileURLWithPath: path),
            messages: messages.map { LocalModelMessage(role: $0["role"]!, content: $0["content"]!) },
            maxTokens: object["maxTokens"] as? Int ?? 160
        )
        XCTAssertFalse(reply.isEmpty)
        try reply.write(toFile: fixture + ".reply", atomically: true, encoding: .utf8)
        print("LOCAL_SCHEDULE_SMOKE \(reply)")
    }

    func test4BRequiresIPhone18OrNewer() {
        for older in ["iPhone14,2", "iPhone17,1", "iPhone18,1", "iPhone18,2"] {
            XCTAssertFalse(FjeliaMLXEngine.isIPhone18OrNewer(older), older)
        }
        for newer in ["iPhone19,1", "iPhone19,2", "iPhone20,1"] {
            XCTAssertTrue(FjeliaMLXEngine.isIPhone18OrNewer(newer), newer)
        }
        for invalid in ["", "iPad19,1", "iPhone19", "iPhoneX,1", "MacBookPro19,1"] {
            XCTAssertFalse(FjeliaMLXEngine.isIPhone18OrNewer(invalid), invalid)
        }
    }

    func testPhysicalMemoryRequirementIsEnforced() throws {
        if FjeliaMLXEngine.unavailableReason() != nil {
            throw XCTSkip("MLX unavailable on this test host")
        }
        XCTAssertEqual(FjeliaMLXEngine.unavailableReason(minimumMemoryBytes: UInt64.max), "memory")
    }

    /// Opt-in, offline integration test. Download the pinned snapshot once and
    /// set FJELIA_LOCAL_MODEL_TEST_DIR. Normal CI never downloads model weights.
    func testActualModelInAppLanguages() async throws {
        guard let path = ProcessInfo.processInfo.environment["FJELIA_LOCAL_MODEL_TEST_DIR"] else {
            throw XCTSkip("Set FJELIA_LOCAL_MODEL_TEST_DIR to run real local inference")
        }
        if let reason = FjeliaMLXEngine.unavailableReason() {
            throw XCTSkip("MLX unavailable here: \(reason)")
        }
        let engine = FjeliaMLXEngine()
        let languages = [
            "British English", "German", "French", "Italian", "Spanish", "Catalan",
            "Norwegian Bokmål", "Slovak", "Finnish", "Danish",
        ]
        for language in languages {
            let reply = try await engine.generate(
                directory: URL(fileURLWithPath: path),
                messages: [
                    LocalModelMessage(role: "system", content:
                        "You explain training records. Write your whole reply in \(language). "
                        + "Use only the given facts. Missing information stays unknown. "
                        + "Reply in two short sentences. Do not diagnose or invent data."),
                    LocalModelMessage(role: "user", content:
                        "Recorded run: 40 minutes, average heart rate 138 bpm. "
                        + "There is no previous training or recovery history. "
                        + "What can you say about this session, and what cannot you conclude?"),
                ],
                maxTokens: 160
            )
            XCTAssertFalse(reply.isEmpty, language)
            XCTAssertFalse(reply.contains("<think>"), "Thinking should be disabled: \(language)")
            print("LOCAL_MODEL_SMOKE [\(language)] \(reply)")
        }
    }
}
