// @implements DES-003 (Transcript Block)
// @see SoT/SoT.DESIGN_COMPONENTS.md DES-003
// @see design/visual-prototype/project/src/scr004.jsx :: TranscriptBlock

import SwiftUI

struct DisplayTurn: Identifiable, Equatable {
    let id: UUID
    let speakerColorIndex: Int
    let speakerName: String
    let timestamp: String
    let text: String

    init(speakerColorIndex: Int, speakerName: String, timestamp: String, text: String) {
        self.id = UUID()
        self.speakerColorIndex = speakerColorIndex
        self.speakerName = speakerName
        self.timestamp = timestamp
        self.text = text
    }
}

struct TranscriptBlock: View {
    let turn: DisplayTurn

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            // Left column: speaker pill + timestamp
            VStack(alignment: .leading, spacing: 6) {
                SpeakerLabel(name: turn.speakerName, colorIndex: turn.speakerColorIndex)
                Text(turn.timestamp)
                    .font(DesignFonts.mono(10.5))
                    .foregroundStyle(DesignColors.textMuted)
                    .padding(.leading, 4)
            }
            .frame(width: 160, alignment: .leading)
            .padding(.top, 2)

            // Right column: text body with colored left border
            HStack(spacing: 0) {
                Rectangle()
                    .fill(DesignColors.speakerColor(index: turn.speakerColorIndex).opacity(0.33))
                    .frame(width: 2)
                Text(turn.text)
                    .font(DesignFonts.ui(14.5))
                    .lineSpacing(4)  // line-height 1.55 ≈ 14.5 × 0.55
                    .foregroundStyle(DesignColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}

#Preview {
    VStack(spacing: 0) {
        TranscriptBlock(turn: DisplayTurn(
            speakerColorIndex: 2,
            speakerName: "Priya Iyer",
            timestamp: "00:00:04",
            text: "Okay, last Q3 planning before we lock the roadmap. I want to spend most of our hour on three things: the diarization SLA, the export pipeline, and whether we keep the notch HUD as the primary surface or demote it."
        ))
        TranscriptBlock(turn: DisplayTurn(
            speakerColorIndex: 0,
            speakerName: "Lena Ortiz",
            timestamp: "00:00:22",
            text: "Demote it to what — Menu Bar Extra as primary? We agreed last week those are peers. BR-501 doesn't care which surface, only that there's a single Stop button and the main window is hidden."
        ))
    }
    .frame(width: 900)
    .background(DesignColors.bgPrimary)
}
