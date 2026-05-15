// @implements API-001, API-002 (EPIC-02b regression coverage)
import AVFoundation
import XCTest
@testable import TranscriptShadow

final class AudioFileWriterTests: XCTestCase {

    private func tempURL(_ name: String = UUID().uuidString) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(name).wav")
    }

    private var writerFormat: AVAudioFormat {
        try! AudioMixer.outputFormat(sampleRate: 48_000)
    }

    func test_init_throws_whenFileAlreadyExists() throws {
        let url = tempURL()
        FileManager.default.createFile(atPath: url.path, contents: Data([0]))
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }

        XCTAssertThrowsError(try AudioFileWriter(url: url, format: writerFormat)) { error in
            guard case AudioCaptureError.audioFileWriteFailed(let reason) = error else {
                return XCTFail("expected audioFileWriteFailed, got \(error)")
            }
            XCTAssertTrue(reason.lowercased().contains("refusing"), "reason should explain refusal: \(reason)")
        }
    }

    func test_finishedWriter_rejectsSubsequentWrites() throws {
        let url = tempURL()
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        let writer = try AudioFileWriter(url: url, format: writerFormat)
        try writer.write(buffer: SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.2))
        try writer.finish()
        XCTAssertThrowsError(try writer.write(buffer: SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.2)))
    }

    func test_concurrentWriteAndFinish_doesNotDoubleCount() throws {
        let url = tempURL()
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        let writer = try AudioFileWriter(url: url, format: writerFormat)

        let writeIterations = 200
        let writeQueue = DispatchQueue(label: "epic02b.writer.test", attributes: .concurrent)
        let group = DispatchGroup()

        for _ in 0..<writeIterations {
            group.enter()
            writeQueue.async {
                try? writer.write(buffer: SyntheticPCMBuffer.make(frameCount: 1_024, amplitude: 0.2))
                group.leave()
            }
        }

        // Race finish() against ongoing writes — the single critical section
        // must keep totalFrameCount and on-disk frames in lockstep so we never
        // count frames that weren't actually written.
        writeQueue.asyncAfter(deadline: .now() + 0.005) {
            try? writer.finish()
        }
        group.wait()
        try? writer.finish()

        let logical = writer.totalFrameCount
        let readback = try AVAudioFile(forReading: url)
        XCTAssertEqual(readback.length, logical,
                       "write() must not bump totalFrames unless audio actually reached disk")
    }
}
