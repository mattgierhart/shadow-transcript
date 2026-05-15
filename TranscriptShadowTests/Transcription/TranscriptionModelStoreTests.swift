// @implements API-101, INT-101
import XCTest
@testable import TranscriptShadow

final class TranscriptionModelStoreTests: XCTestCase {

    func test_directoryURL_isStableForGivenModel() {
        let root = URL(fileURLWithPath: "/tmp/example")
        let store = TranscriptionModelStore(directory: root)
        XCTAssertEqual(
            store.directoryURL(for: .baseEN).path,
            "/tmp/example/openai_whisper-base.en"
        )
        XCTAssertEqual(
            store.directoryURL(for: .mediumEN).path,
            "/tmp/example/openai_whisper-medium.en"
        )
    }

    func test_isCached_falseWhenDirectoryEmptyOrMissing() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("epic03-store-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let store = TranscriptionModelStore(directory: root)
        XCTAssertFalse(store.isCached(model: .baseEN))
    }

    func test_isCached_trueAfterFilesAppear() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("epic03-store-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let store = TranscriptionModelStore(directory: root)
        let modelDir = store.directoryURL(for: .smallEN)
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
        let payload = modelDir.appendingPathComponent("config.json")
        try Data("{}".utf8).write(to: payload)
        XCTAssertTrue(store.isCached(model: .smallEN))
    }
}
