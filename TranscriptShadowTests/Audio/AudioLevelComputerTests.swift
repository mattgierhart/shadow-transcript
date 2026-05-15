// @implements TEST-002
import AVFoundation
import XCTest
@testable import TranscriptShadow

final class AudioLevelComputerTests: XCTestCase {

    func test_silentBuffer_returnsZero() {
        let buffer = SyntheticPCMBuffer.make(amplitude: 0)
        XCTAssertEqual(AudioLevelComputer.level(for: buffer), 0, accuracy: 0.0001)
    }

    func test_constantAmplitudeBuffer_returnsThatAmplitude() {
        let buffer = SyntheticPCMBuffer.make(amplitude: 0.5)
        XCTAssertEqual(AudioLevelComputer.level(for: buffer), 0.5, accuracy: 0.0001)
    }

    func test_outputAlwaysWithinUnitRange() {
        let loud = SyntheticPCMBuffer.make(amplitude: 1.5) // outside [-1, 1]
        XCTAssertLessThanOrEqual(AudioLevelComputer.level(for: loud), 1.0)
        let quiet = SyntheticPCMBuffer.make(amplitude: 0.01)
        let level = AudioLevelComputer.level(for: quiet)
        XCTAssertGreaterThanOrEqual(level, 0)
        XCTAssertLessThanOrEqual(level, 1)
    }
}
