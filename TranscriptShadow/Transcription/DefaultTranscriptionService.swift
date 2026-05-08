// @implements API-101, FEA-002, BR-101, BR-202
import AVFoundation
import Foundation

/// Default implementation of `TranscriptionService`. Owns the
/// `TranscriptionModelStore`, drives the injected engine, validates the
/// audio URL, and maps engine output to the public `TranscriptionResult`.
///
/// Per Codex's path-forward: the service accepts any readable WAV and is
/// not coupled to `DefaultAudioCaptureService`. Tests inject
/// `FakeTranscriptionEngine`; production wiring uses `WhisperKitEngine`.
public actor DefaultTranscriptionService: TranscriptionService {

    private let engine: any TranscriptionEngine
    private let modelStore: TranscriptionModelStore
    private let fileManager: FileManager

    /// Designated initializer — internal so tests can inject a fake engine
    /// via `@testable import TranscriptShadow`. Production callers should use
    /// the convenience initializer below.
    init(
        engine: any TranscriptionEngine,
        modelStore: TranscriptionModelStore,
        fileManager: FileManager = .default
    ) {
        self.engine = engine
        self.modelStore = modelStore
        self.fileManager = fileManager
    }

    #if canImport(WhisperKit)
    /// Convenience initializer for production wiring. Drops in
    /// `WhisperKitEngine` + the standard Application Support model store.
    public init(fileManager: FileManager = .default) throws {
        self.engine = WhisperKitEngine()
        self.modelStore = try TranscriptionModelStore.makeDefault(fileManager: fileManager)
        self.fileManager = fileManager
    }
    #endif

    public var loadedModel: WhisperModel? {
        get async { await engine.loaded }
    }

    public func prepare(model: WhisperModel) async throws {
        try await loadIfNeeded(model: model)
    }

    public func transcribe(
        audioURL: URL,
        model: WhisperModel,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> Transcript {
        try validateAudio(at: audioURL)
        try await loadIfNeeded(model: model)

        let duration = (try? AudioDurationProbe.seconds(at: audioURL)) ?? 0

        let engineResult: EngineTranscription
        do {
            engineResult = try await engine.transcribe(
                audioURL: audioURL,
                language: "en", // BR-202 — MVP English-only
                progress: progress
            )
        } catch let error as TranscriptionError {
            throw error
        } catch {
            throw TranscriptionError.transcriptionFailed(reason: error.localizedDescription)
        }

        return Transcript(
            segments: engineResult.segments,
            language: engineResult.language,
            duration: duration,
            model: model
        )
    }

    /// Cache invariant from TEST-104: if the engine already has the requested
    /// model loaded, skip the call. Real engines also short-circuit
    /// internally, but the service-level guard keeps fakes (and any
    /// cooperative engine) honest.
    private func loadIfNeeded(model: WhisperModel) async throws {
        if await engine.loaded == model { return }
        try await engine.load(model: model, store: modelStore)
    }

    private func validateAudio(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw TranscriptionError.audioFileMissing(url: url)
        }
        do {
            _ = try AVAudioFile(forReading: url)
        } catch {
            throw TranscriptionError.audioFileUnreadable(
                url: url,
                reason: error.localizedDescription
            )
        }
    }
}
