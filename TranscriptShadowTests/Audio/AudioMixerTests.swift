// @implements TEST-003
import AVFoundation
import XCTest
@testable import TranscriptShadow

final class AudioMixerTests: XCTestCase {

    func test_mix_writesValidWAV_andPreservesFrameCount() throws {
        let mic = SyntheticPCMBuffer.make(sampleRate: 48_000, frameCount: 9_600, amplitude: 0.4)
        let sys = SyntheticPCMBuffer.sine(sampleRate: 48_000, frequency: 440, frameCount: 9_600, amplitude: 0.4)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("audio-mixer-test-\(UUID().uuidString).wav")
        addTeardownBlock { try? FileManager.default.removeItem(at: outputURL) }

        try AudioMixer.mix(microphoneBuffer: mic, systemBuffer: sys, sampleRate: 48_000, to: outputURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        let readback = try AVAudioFile(forReading: outputURL)
        XCTAssertEqual(readback.processingFormat.sampleRate, 48_000)
        XCTAssertEqual(readback.processingFormat.channelCount, 1)
        XCTAssertEqual(readback.length, 9_600)
    }

    func test_mix_unequalLengthBuffers_usesShorter() throws {
        let mic = SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.3)
        let sys = SyntheticPCMBuffer.make(frameCount: 9_600, amplitude: 0.3)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("audio-mixer-uneven-\(UUID().uuidString).wav")
        addTeardownBlock { try? FileManager.default.removeItem(at: outputURL) }

        try AudioMixer.mix(microphoneBuffer: mic, systemBuffer: sys, to: outputURL)

        let readback = try AVAudioFile(forReading: outputURL)
        XCTAssertEqual(readback.length, 4_800)
    }
}
