// @implements API-101, INT-101, TECH-002
import AVFoundation
import Foundation
#if canImport(WhisperKit)
import WhisperKit
#endif

#if canImport(WhisperKit)
/// Production engine backed by `WhisperKit` 0.18.x. Holds at most one loaded
/// model at a time; `load(model:store:)` swaps when a different model is
/// requested. Uses a `final class` with manual locking instead of an `actor`
/// because the underlying `WhisperKit` instance is not `Sendable`, and an
/// actor would flag any `await whisperKit.transcribe(...)` call as a
/// cross-isolation send under Swift 6 strict concurrency.
final class WhisperKitEngine: TranscriptionEngine, @unchecked Sendable {
    private let lock = NSLock()
    private var whisperKit: WhisperKit?
    private var loadedModel: WhisperModel?
    /// Serializes load + transcribe so two concurrent callers cannot drive
    /// the same `WhisperKit` instance at once (Codex P2 review finding).
    private let queue = AsyncTaskQueue()

    init() {}

    var loaded: WhisperModel? {
        get async { lock.withLock { loadedModel } }
    }

    func load(model: WhisperModel, store: TranscriptionModelStore) async throws {
        try await queue.enqueue {
            try await self.loadLocked(model: model, store: store)
        }
    }

    private func loadLocked(model: WhisperModel, store: TranscriptionModelStore) async throws {
        if let alreadyLoaded = lock.withLock({ loadedModel }), alreadyLoaded == model,
           lock.withLock({ whisperKit != nil }) {
            return
        }
        lock.withLock {
            whisperKit = nil
            loadedModel = nil
        }
        do {
            // Pass the cache root as `downloadBase` (where WhisperKit *places*
            // downloads), not `modelFolder` (which would tell WhisperKit "this
            // is already a model directory" and skip the download path
            // entirely on a fresh install). Codex P1 review finding.
            let kit = try await WhisperKit(
                model: model.rawValue,
                downloadBase: store.directory,
                load: true
            )
            lock.withLock {
                self.whisperKit = kit
                self.loadedModel = model
            }
        } catch is CancellationError {
            throw TranscriptionError.cancelled
        } catch {
            throw TranscriptionError.modelLoadFailed(
                model: model,
                reason: error.localizedDescription
            )
        }
    }

    func transcribe(
        audioURL: URL,
        language: String,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> EngineTranscription {
        try await queue.enqueue {
            try await self.transcribeLocked(audioURL: audioURL, language: language, progress: progress)
        }
    }

    private func transcribeLocked(
        audioURL: URL,
        language: String,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> EngineTranscription {
        let snapshot = lock.withLock { (whisperKit: whisperKit, model: loadedModel) }
        guard let whisperKit = snapshot.whisperKit else {
            throw TranscriptionError.modelLoadFailed(
                model: snapshot.model ?? .default,
                reason: "Engine has no model loaded; call load(_:) first."
            )
        }

        progress(0)

        // WhisperKit's native progress callback gives us elapsed pipeline time,
        // not a fraction. Convert it via the audio's known duration so callers
        // see monotonic 0→1 values.
        let duration = (try? AudioDurationProbe.seconds(at: audioURL)) ?? 0

        let options = DecodingOptions(
            verbose: false,
            task: .transcribe,
            language: language,
            temperature: 0.0,
            wordTimestamps: true,
            suppressBlank: true,
            chunkingStrategy: .vad
        )

        let progressBox = ProgressBox(progress: progress, duration: duration)

        // Inline the WhisperKit call so the non-Sendable `whisperKit` instance
        // never crosses an actor boundary (Swift 6 strict concurrency).
        let whisperResults: [TranscriptionResult]
        do {
            whisperResults = try await whisperKit.transcribe(
                audioPath: audioURL.path,
                decodeOptions: options
            ) { whisperProgress in
                if Task.isCancelled { return false }
                progressBox.report(elapsedSeconds: whisperProgress.timings.fullPipeline)
                return true
            }
        } catch is CancellationError {
            // Codex P2 review: surface user cancellation as `.cancelled`
            // rather than collapsing it into `.transcriptionFailed`.
            throw TranscriptionError.cancelled
        } catch {
            if Task.isCancelled {
                throw TranscriptionError.cancelled
            }
            throw TranscriptionError.transcriptionFailed(reason: error.localizedDescription)
        }

        progress(1.0)

        var segments: [TranscriptSegment] = []
        var detectedLanguage = language
        for result in whisperResults {
            if segments.isEmpty {
                detectedLanguage = result.language
            }
            for seg in result.segments {
                let words = (seg.words ?? []).map { word in
                    WordTimestamp(
                        word: word.word,
                        start: TimeInterval(word.start),
                        end: TimeInterval(word.end)
                    )
                }
                segments.append(TranscriptSegment(
                    text: seg.text,
                    start: TimeInterval(seg.start),
                    end: TimeInterval(seg.end),
                    words: words
                ))
            }
        }

        return EngineTranscription(language: detectedLanguage, segments: segments)
    }
}

/// Tiny container that turns WhisperKit's elapsed-seconds progress signal
/// into a monotonically non-decreasing fractional value before forwarding to
/// the public callback.
private final class ProgressBox: @unchecked Sendable {
    private let progress: @Sendable (Double) -> Void
    private let duration: TimeInterval
    private let lock = NSLock()
    private var lastFraction: Double = 0

    init(progress: @escaping @Sendable (Double) -> Void, duration: TimeInterval) {
        self.progress = progress
        self.duration = duration
    }

    func report(elapsedSeconds: TimeInterval) {
        guard duration > 0 else { return }
        let raw = elapsedSeconds / duration
        let clamped = min(max(raw, 0), 0.999)
        let fraction: Double = lock.withLock {
            if clamped > lastFraction {
                lastFraction = clamped
                return clamped
            }
            return lastFraction
        }
        progress(fraction)
    }
}
#endif

enum AudioDurationProbe {
    static func seconds(at url: URL) throws -> TimeInterval {
        let file = try AVAudioFile(forReading: url)
        return TimeInterval(file.length) / file.processingFormat.sampleRate
    }
}
