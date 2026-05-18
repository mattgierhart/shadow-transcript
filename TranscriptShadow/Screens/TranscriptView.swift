// @implements SCR-004 (Transcript View — money shot)
// @see SoT/SoT.USER_JOURNEYS.md SCR-004
// @see design/visual-prototype/project/src/scr004.jsx :: ScreenSCR004

import SwiftUI

struct TranscriptSpeaker: Identifiable {
    let id = UUID()
    let name: String
    let colorIndex: Int
    let time: String
    /// Percent of total time (0..1).
    let share: Double
    let unlabeled: Bool
}

struct TranscriptDisplayModel {
    let title: String
    let dateLabel: String
    let duration: String
    let speakerCount: Int
    let modelLabel: String
    let speakers: [TranscriptSpeaker]
    let turns: [DisplayTurn]
    let wordCount: Int
    let markdownBytes: String
    let audioDeletedAt: String
}

extension TranscriptDisplayModel {
    static let mock = TranscriptDisplayModel(
        title: "Q3 Planning · Eng + Design",
        dateLabel: "Thu May 16 · 11:00 AM",
        duration: "47:12 duration",
        speakerCount: 5,
        modelLabel: "whisper:small.en · pyannote:3.1",
        speakers: [
            TranscriptSpeaker(name: "Lena Ortiz",    colorIndex: 0, time: "14:08", share: 0.30, unlabeled: false),
            TranscriptSpeaker(name: "Marc Schuler",  colorIndex: 1, time: "09:42", share: 0.21, unlabeled: false),
            TranscriptSpeaker(name: "Priya Iyer",    colorIndex: 2, time: "11:31", share: 0.25, unlabeled: false),
            TranscriptSpeaker(name: "You",            colorIndex: 3, time: "07:54", share: 0.17, unlabeled: false),
            TranscriptSpeaker(name: "Speaker 5",     colorIndex: 4, time: "03:57", share: 0.07, unlabeled: true),
        ],
        turns: [
            DisplayTurn(speakerColorIndex: 2, speakerName: "Priya Iyer", timestamp: "00:00:04",
                           text: "Okay, last Q3 planning before we lock the roadmap. I want to spend most of our hour on three things: the diarization SLA, the export pipeline, and whether we keep the notch HUD as the primary surface or demote it."),
            DisplayTurn(speakerColorIndex: 0, speakerName: "Lena Ortiz", timestamp: "00:00:22",
                           text: "Demote it to what — Menu Bar Extra as primary? We agreed last week those are peers. BR-501 doesn't care which surface, only that there's a single Stop button and the main window is hidden."),
            DisplayTurn(speakerColorIndex: 1, speakerName: "Marc Schuler", timestamp: "00:00:41",
                           text: "Right, but if the notch HUD can't reliably sit above fullscreen Zoom, we've got a screen the user can't see. RISK-008 is the question, not the design."),
            DisplayTurn(speakerColorIndex: 2, speakerName: "Priya Iyer", timestamp: "00:00:55",
                           text: "Lena, where did the .statusBar + 1 prototype land?"),
            DisplayTurn(speakerColorIndex: 0, speakerName: "Lena Ortiz", timestamp: "00:01:02",
                           text: "Holds on macOS 14 and 15 in every meeting app we tested. Teams in fullscreen was the one that worried me — it's fine. NSPanel with the non-activating + can-be-visible-on-all-spaces flags, level above the menu bar."),
            DisplayTurn(speakerColorIndex: 3, speakerName: "You", timestamp: "00:01:24",
                           text: "Good. Then I think we ship both surfaces as peers and stop talking about it. The risk doc said promote DES-106 if 105 breaks; it didn't break."),
            DisplayTurn(speakerColorIndex: 2, speakerName: "Priya Iyer", timestamp: "00:01:39",
                           text: "Agreed. Marc, the expanded notch panel — you locked the width at 280?"),
            DisplayTurn(speakerColorIndex: 1, speakerName: "Marc Schuler", timestamp: "00:01:47",
                           text: "Yeah, 280pt expanded, 36pt tall. Red dot, \"Recording\" label, full-height Stop button. The dot oscillates at 1Hz — Lena measured the WhisperKit memory at ~340MB so there's headroom for the animation."),
            DisplayTurn(speakerColorIndex: 4, speakerName: "Speaker 5", timestamp: "00:02:08",
                           text: "Quick question on the popover — does that follow the same 1Hz oscillation for the dot?"),
            DisplayTurn(speakerColorIndex: 1, speakerName: "Marc Schuler", timestamp: "00:02:14",
                           text: "Same oscillation, same red, same Stop layout. Peers means peers — visual parity is the whole point. If the menu bar version looks like the consolation prize, we've failed the brief."),
            DisplayTurn(speakerColorIndex: 0, speakerName: "Lena Ortiz", timestamp: "00:02:31",
                           text: "On the diarization SLA — pyannote sidecar is averaging 0.18× real-time on M2 Pro. Forty-five minute meeting processes in about eight minutes end-to-end including Whisper."),
            DisplayTurn(speakerColorIndex: 2, speakerName: "Priya Iyer", timestamp: "00:02:50",
                           text: "That's well under our ten-minute target. PER-001 is the meeting-and-go user; they aren't watching the pipeline."),
            DisplayTurn(speakerColorIndex: 3, speakerName: "You", timestamp: "00:03:02",
                           text: "Speaker rename has to be instant, though. That was the loudest piece of feedback from the design interview — they want to fix the labels once and have the whole transcript update."),
            DisplayTurn(speakerColorIndex: 0, speakerName: "Lena Ortiz", timestamp: "00:03:18",
                           text: "Already wired through. DBT-001 stores speaker_label as a nullable override; the transcript view binds to it. Rename propagates in the same render pass."),
        ],
        wordCount: 1842,
        markdownBytes: "6.4 KB",
        audioDeletedAt: "11:50:04"
    )
}

struct TranscriptView: View {
    @StateObject private var vm: TranscriptViewModel
    private var model: TranscriptDisplayModel { vm.displayModel }

    init(env: AppEnvironment) {
        _vm = StateObject(wrappedValue: TranscriptViewModel(env: env))
    }

    var body: some View {
        VStack(spacing: 0) {
            metadataHeader
            speakerSummary
            shareBar
            transcriptScroll
            statusFooter
        }
        .background(DesignColors.bgPrimary)
    }

    // MARK: - Pieces

    private var metadataHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(DesignFonts.ui(16, weight: .semibold))
                    .foregroundStyle(DesignColors.textPrimary)
                HStack(spacing: 14) {
                    Text(model.dateLabel)
                    Text("·").foregroundStyle(DesignColors.textMuted)
                    Text(model.duration)
                    Text("·").foregroundStyle(DesignColors.textMuted)
                    Text("\(model.speakerCount) speakers")
                    Text("·").foregroundStyle(DesignColors.textMuted)
                    Text(model.modelLabel)
                    Text("·").foregroundStyle(DesignColors.textMuted)
                    HStack(spacing: 4) {
                        Text("●").foregroundStyle(DesignColors.Status.success)
                        Text("local")
                    }
                }
                .font(DesignFonts.mono(11.5))
                .foregroundStyle(DesignColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                toolbarButton("Copy", sub: "⌘C")
                toolbarButton("Save as…", sub: "⌘S")
                exportButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .overlay(
            Rectangle().fill(DesignColors.borderDefault).frame(height: 0.5),
            alignment: .bottom
        )
    }

    private func toolbarButton(_ label: String, sub: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Text(label).font(DesignFonts.ui(12, weight: .medium))
                Text(sub).font(DesignFonts.mono(10)).foregroundStyle(DesignColors.textMuted)
            }
            .foregroundStyle(DesignColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .overlay(
                RoundedRectangle(cornerRadius: 7).stroke(DesignColors.borderDefault, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var exportButton: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                Text("Export to Obsidian")
                    .font(DesignFonts.ui(12.5, weight: .semibold))
                Text("⌘E")
                    .font(DesignFonts.mono(10.5))
                    .opacity(0.6)
            }
            .foregroundStyle(Color(hex: 0x06281F))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(DesignColors.accentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .shadow(color: DesignColors.accentPrimary.opacity(0.20), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var speakerSummary: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("SPEAKERS")
                .font(DesignFonts.mono(10))
                .tracking(0.6)
                .foregroundStyle(DesignColors.textMuted)

            HStack(spacing: 8) {
                ForEach(model.speakers) { speaker in
                    SpeakerLabel(
                        name: speaker.unlabeled ? "Speaker \(speaker.colorIndex + 1)" : speaker.name,
                        colorIndex: speaker.colorIndex,
                        time: speaker.time,
                        size: .lg
                    )
                }
            }

            Spacer()

            Text("click a pill to rename")
                .font(DesignFonts.mono(10.5))
                .foregroundStyle(DesignColors.textMuted)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .overlay(
            Rectangle().fill(DesignColors.borderDefault).frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var shareBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(model.speakers) { speaker in
                        Rectangle()
                            .fill(DesignColors.speakerColor(index: speaker.colorIndex).opacity(0.85))
                            .frame(width: geo.size.width * speaker.share)
                    }
                }
            }
            .frame(height: 6)
            .background(DesignColors.bgTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 999))

            HStack {
                Text("00:00")
                Spacer()
                Text("share of voice")
                Spacer()
                Text("47:12")
            }
            .font(DesignFonts.mono(10))
            .foregroundStyle(DesignColors.textMuted)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var transcriptScroll: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(model.turns) { turn in
                        TranscriptBlock(turn: turn)
                    }
                }
                .padding(.vertical, 8)
            }
            // Bottom fade
            LinearGradient(
                colors: [.clear, DesignColors.bgPrimary],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 60)
            .allowsHitTesting(false)
        }
    }

    private var statusFooter: some View {
        HStack(spacing: 8) {
            Text("\(model.turns.count) turns · \(model.wordCount) words")
            Text("·")
            Text("~markdown · \(model.markdownBytes)")
            Spacer()
            HStack(spacing: 4) {
                Text("●").foregroundStyle(DesignColors.Status.success)
                Text("audio deleted at \(model.audioDeletedAt)")
            }
        }
        .font(DesignFonts.mono(10.5))
        .foregroundStyle(DesignColors.textMuted)
        .padding(.horizontal, 24)
        .frame(height: 30)
        .background(DesignColors.bgSecondary)
        .overlay(
            Rectangle().fill(DesignColors.borderDefault).frame(height: 0.5),
            alignment: .top
        )
    }
}

#Preview {
    TranscriptView(env: .preview())
        .frame(width: 1200, height: 800)
}
