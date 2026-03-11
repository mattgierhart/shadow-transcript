# Granite 4.0 1B Speech vs WhisperKit — Evaluation for Transcript Shadow

**Date**: 2026-03-11
**Context**: TECH-002 (WhisperKit selected), ARC-001 (local pipeline), BR-101 (local-only), BR-201 (macOS), BR-401 (Apple Silicon)
**Triggered by**: IBM Granite 4.0 1B Speech gaining attention; evaluate whether it should replace or supplement WhisperKit.

---

## Model Comparison

| Dimension | WhisperKit (TECH-002) | Granite 4.0 1B Speech |
|---|---|---|
| **Architecture** | OpenAI Whisper (encoder-decoder transformer) compiled to CoreML | Encoder-decoder with speculative decoding, Hugging Face transformers |
| **Parameters** | 74M (base.en) → 769M (medium.en) | ~1B |
| **Language** | English-only models (.en) + multilingual | English, French, German, Spanish, Portuguese, Japanese |
| **Runtime** | Native Swift, CoreML, Apple Neural Engine | Python (transformers + torch), no CoreML conversion available |
| **Integration** | Swift Package Manager — `import WhisperKit` | Python library — `transformers.pipeline("automatic-speech-recognition")` |
| **Hardware Accel** | ANE (Neural Engine) via CoreML | CPU/GPU via PyTorch; no ANE path exists today |
| **License** | MIT | Apache 2.0 |
| **Streaming** | Yes (real-time capable) | No (batch only) |
| **Word Timestamps** | Yes (native) | Yes |
| **Keyword Biasing** | No | Yes (names/acronyms) |
| **Benchmarks** | Mature, ICML 2025 paper | #1 OpenASR leaderboard |
| **Maturity** | 5,700+ stars, v0.16+, production use | New release, enterprise-focused |

---

## Evaluation Against Transcript Shadow Requirements

### 1. Native Swift Integration (Critical — TECH-001)

- **WhisperKit**: First-class. SPM dependency, zero bridging. `import WhisperKit` and call `transcribe()`.
- **Granite**: No Swift support. Requires Python runtime (transformers + torch + torchaudio). Would need either:
  - A **second Python sidecar** (alongside pyannote), or
  - Running via ONNX Runtime with CoreML EP (requires manual export + C++ bridging header)

**Verdict**: WhisperKit wins decisively. Granite would double the Python sidecar burden (ARC-002 complexity) or require untested ONNX conversion.

### 2. Apple Neural Engine Acceleration (Critical — BR-401, KPI-001)

- **WhisperKit**: Runs on ANE via CoreML. This is the fastest, most power-efficient path on Apple Silicon. base.en transcribes ~10x realtime on M1.
- **Granite**: No CoreML model exists. Would run on CPU (slow) or Metal/MPS via PyTorch (not ANE). No published Apple Silicon benchmarks.

**Verdict**: WhisperKit wins. ANE acceleration is the reason local transcription of 30-min meetings in < 5 min is feasible (KPI-001).

### 3. On-Device Size & Footprint (Important — RISK-003)

- **WhisperKit**: base.en is ~148MB CoreML model. Small, cached in App Support.
- **Granite**: 1B parameter model + PyTorch runtime. Would require ~2-4GB for model + ~500MB+ for Python/torch runtime if bundled as sidecar. Combined with the pyannote sidecar, total bundle could reach 1GB+.

**Verdict**: WhisperKit wins. Granite would significantly inflate bundle size, worsening RISK-003.

### 4. Accuracy (Important — KPI-002)

- **WhisperKit**: Whisper models are well-established. base.en is good; small.en and medium.en are excellent for English.
- **Granite**: #1 on OpenASR leaderboard. Likely higher raw WER on benchmarks than Whisper base.en; comparable to or better than Whisper medium.en.

**Verdict**: Granite likely has an edge at the 1B parameter tier. However, WhisperKit's medium.en (~769M params) is already available for users who want higher accuracy, and it runs on ANE. The accuracy gap is not large enough to justify the integration cost.

### 5. Keyword Biasing (Nice-to-have)

- **WhisperKit**: Not supported.
- **Granite**: Supports keyword list biasing for names and acronyms — genuinely useful for meetings.

**Verdict**: Granite has a real advantage here. This is the strongest argument for Granite. However, it's a P2 feature, not MVP-critical.

### 6. Multilingual Support (Out of scope — BR-202)

- Both support multiple languages. Irrelevant for MVP (English only). If Deployment 3 adds multilingual, Granite's 6-language support would be a consideration, but WhisperKit's multilingual models cover 90+ languages.

**Verdict**: Neutral for MVP. WhisperKit covers more languages long-term.

---

## Integration Feasibility Assessment

### Option A: Replace WhisperKit with Granite (NOT RECOMMENDED)

- Would require replacing native Swift CoreML inference with a Python sidecar
- Two Python sidecars (transcription + diarization) dramatically increases complexity
- Loses ANE acceleration — processing time would likely exceed KPI-001 target
- No CoreML conversion exists; creating one for a speech model is non-trivial
- Breaks ARC-001 simplicity (sequential Swift pipeline becomes multi-subprocess)

### Option B: Add Granite as Alternative Engine (NOT RECOMMENDED for MVP)

- Could offer as user-selectable backend in Settings (SCR-005)
- But doubles testing matrix, doubles model management code
- Premature for MVP — complexity without clear user value

### Option C: Monitor for Future Consideration (RECOMMENDED)

- Track Granite speech model ecosystem maturity
- Re-evaluate when/if:
  - A CoreML or ONNX conversion becomes available
  - A Swift-native inference path emerges (e.g., via MLX or speech-swift)
  - Keyword biasing becomes a top user request post-MVP
  - Multilingual support enters scope (Deployment 3)

---

## Recommendation

**Keep WhisperKit (TECH-002). Do not adopt Granite 4.0 1B Speech for MVP.**

| Factor | Weight | WhisperKit | Granite |
|--------|--------|------------|---------|
| Native Swift integration | Critical | ★★★★★ | ★☆☆☆☆ |
| ANE acceleration | Critical | ★★★★★ | ★☆☆☆☆ |
| Bundle size | High | ★★★★☆ | ★★☆☆☆ |
| English accuracy | High | ★★★★☆ | ★★★★★ |
| Keyword biasing | Low | ★☆☆☆☆ | ★★★★★ |
| Maturity/ecosystem | High | ★★★★★ | ★★★☆☆ |
| **Overall fit** | | **Strong** | **Poor** |

Granite is an impressive model — likely the best open-source ASR model by raw accuracy today. But **it solves the wrong problem for this product**. Transcript Shadow's architecture is built around Apple-native ML inference (CoreML/ANE), and WhisperKit is the only production-ready Swift-native path to that. Adopting Granite would mean either regressing to Python-based inference (slow, heavy) or pioneering an untested CoreML conversion.

The keyword biasing feature is worth tracking. If Argmax adds similar capability to WhisperKit, or if Granite publishes a CoreML model, this evaluation should be revisited.

---

## Sources

- [IBM Granite 4.0 Announcement](https://www.ibm.com/new/announcements/ibm-granite-4-0-hyper-efficient-high-performance-hybrid-models)
- [Granite 4.0 1B Speech on Hugging Face](https://huggingface.co/ibm-granite/granite-4.0-1b-speech)
- [Granite 4.0 Speech Blog](https://huggingface.co/blog/ibm-granite/granite-4-speech)
- [WhisperKit on GitHub](https://github.com/argmaxinc/WhisperKit)
- [Argmax & Apple SpeechAnalyzer](https://www.argmaxinc.com/blog/apple-and-argmax)
- [FluidAudio (CoreML speech SDK)](https://github.com/FluidInference/FluidAudio)
- [speech-swift (MLX speech toolkit)](https://github.com/soniqo/speech-swift)
