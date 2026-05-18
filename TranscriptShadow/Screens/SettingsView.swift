// @implements SCR-005 (Settings Sheet)
// @see SoT/SoT.USER_JOURNEYS.md SCR-005
// @see design/visual-prototype/project/src/scr005.jsx :: SettingsSheet
//
// Presented as a sheet over the main window. Auto-saves on change. Per
// BR-101/BR-102, Privacy section's "Local processing" and "Auto-delete
// audio" are informational chips ("on · locked"), not toggles.

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: SettingsViewModel

    init(env: AppEnvironment) {
        _vm = StateObject(wrappedValue: SettingsViewModel(env: env))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    audioSection
                    transcriptionSection
                    exportSection
                    privacySection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .frame(width: 560)
        .frame(maxHeight: 620)
        .background(Color(hex: 0x141415).opacity(0.98))
        .preferredColorScheme(.dark)
        .task { await vm.load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(DesignFonts.ui(14, weight: .semibold))
                    .foregroundStyle(DesignColors.textPrimary)
                Text("auto-saves on change")
                    .font(DesignFonts.mono(11))
                    .foregroundStyle(DesignColors.textMuted)
            }
            Spacer()
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Text("Done").font(DesignFonts.ui(11.5))
                    Text("esc").font(DesignFonts.mono(10)).opacity(0.6)
                }
                .foregroundStyle(DesignColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 6).stroke(DesignColors.borderDefault, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .overlay(
            Rectangle().fill(DesignColors.borderDefault).frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Sections

    private var audioSection: some View {
        SettingsSection(title: "Audio") {
            SettingsRow(label: "Input device", sub: "Microphone used for your voice capture.") {
                SettingsSelect(value: Binding(get: { vm.inputDevice }, set: { vm.inputDevice = $0 }),
                               options: ["MacBook Pro Microphone",
                                         "AirPods Pro",
                                         "Built-in input"])
            }
            SettingsRow(label: "Capture system audio",
                       sub: "Pulls audio from other apps via ScreenCaptureKit. No screen content captured.",
                       isLast: true) {
                HStack(spacing: 10) {
                    StatusChip(ok: true, label: "granted")
                    SettingsToggle(isOn: Binding(get: { vm.captureSystemAudio }, set: { vm.captureSystemAudio = $0 }))
                }
            }
        }
    }

    private var transcriptionSection: some View {
        SettingsSection(title: "Transcription") {
            SettingsRow(label: "Whisper model",
                       sub: "small.en · 466 MB · balanced accuracy / speed") {
                SettingsSelect(value: Binding(
                    get: { vm.whisperModel.rawValue },
                    set: { rawValue in
                        if let model = WhisperModel(rawValue: rawValue) { vm.whisperModel = model }
                    }
                ),
                               options: WhisperModel.allCases.map(\.rawValue))
            }
            SettingsRow(label: "Speaker diarization",
                       sub: "pyannote 3.1 sidecar · runs locally as a separate process",
                       isLast: true) {
                SettingsToggle(isOn: Binding(get: { vm.diarizationOn }, set: { vm.diarizationOn = $0 }))
            }
        }
    }

    private var exportSection: some View {
        SettingsSection(title: "Export") {
            SettingsRow(label: "Obsidian vault",
                       sub: "Path where transcripts are written as markdown.") {
                FolderPickerControl(path: vm.vaultPath)
            }
            SettingsRow(label: "Subfolder", sub: "./Meetings/") {
                TextField("Meetings", text: Binding(get: { vm.subfolder }, set: { vm.subfolder = $0 }))
                    .textFieldStyle(.plain)
                    .font(DesignFonts.mono(12))
                    .foregroundStyle(DesignColors.textPrimary)
                    .frame(width: 120)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignColors.bgTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6).stroke(DesignColors.borderDefault, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            SettingsRow(label: "Auto-export after processing",
                       sub: "Skip the manual Export click — useful for set-and-forget.",
                       isLast: true) {
                SettingsToggle(isOn: Binding(get: { vm.autoExport }, set: { vm.autoExport = $0 }))
            }
        }
    }

    private var privacySection: some View {
        SettingsSection(
            title: "Privacy",
            footnote: "BR-101 · BR-102 · audio is held only in memory + a temp file for the duration of processing, then erased. There is no opt-out."
        ) {
            SettingsRow(label: "Local processing",
                       sub: "All transcription and diarization happens on this Mac. No network calls.") {
                StatusChip(ok: true, label: "on · locked")
            }
            SettingsRow(label: "Auto-delete audio after processing",
                       sub: "Temporary audio is removed once the markdown is written. Cannot be disabled.",
                       isLast: true) {
                StatusChip(ok: true, label: "on · locked")
            }
        }
    }
}

// MARK: - Sub-components

private struct SettingsSection<Content: View>: View {
    let title: String
    let footnote: String?
    let content: () -> Content

    init(title: String, footnote: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.footnote = footnote
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(DesignFonts.mono(10.5))
                .tracking(0.8)
                .foregroundStyle(DesignColors.textMuted)
                .padding(.leading, 2)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .background(DesignColors.bgSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(DesignColors.borderDefault, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if let footnote {
                Text(footnote)
                    .font(DesignFonts.mono(10.5))
                    .foregroundStyle(DesignColors.textMuted)
                    .lineSpacing(2)
                    .padding(.leading, 2)
                    .padding(.top, 4)
            }
        }
    }
}

private struct SettingsRow<Control: View>: View {
    let label: String
    let sub: String?
    let isLast: Bool
    let control: () -> Control

    init(label: String, sub: String? = nil, isLast: Bool = false, @ViewBuilder control: @escaping () -> Control) {
        self.label = label
        self.sub = sub
        self.isLast = isLast
        self.control = control
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(DesignFonts.ui(13, weight: .medium))
                        .foregroundStyle(DesignColors.textPrimary)
                    if let sub {
                        Text(sub)
                            .font(DesignFonts.ui(11.5))
                            .foregroundStyle(DesignColors.textSecondary)
                            .lineSpacing(1.5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                control()
            }
            .padding(.vertical, 14)

            if !isLast {
                Rectangle().fill(DesignColors.borderSubtle).frame(height: 0.5)
            }
        }
    }
}

private struct SettingsSelect: View {
    @Binding var value: String
    let options: [String]

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { value = option }
            }
        } label: {
            HStack(spacing: 8) {
                Text(value).font(DesignFonts.ui(12))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(DesignColors.textSecondary)
            }
            .foregroundStyle(DesignColors.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(minWidth: 180)
            .background(DesignColors.bgTertiary)
            .overlay(
                RoundedRectangle(cornerRadius: 6).stroke(DesignColors.borderDefault, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

private struct SettingsToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? DesignColors.accentPrimary : Color(hex: 0x3A3A3C))
                .frame(width: 30, height: 18)
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .padding(.horizontal, 2)
        }
        .animation(.easeInOut(duration: 0.2), value: isOn)
        .onTapGesture { isOn.toggle() }
    }
}

private struct FolderPickerControl: View {
    let path: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.system(size: 11))
                .foregroundStyle(DesignColors.accentPrimary)
            Text(path)
                .font(DesignFonts.mono(11.5))
                .foregroundStyle(DesignColors.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            Button("Choose…") { /* NSOpenPanel wiring deferred to Phase 2 */ }
                .buttonStyle(.plain)
                .font(DesignFonts.ui(11, weight: .medium))
                .foregroundStyle(DesignColors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: 260)
        .background(DesignColors.bgTertiary)
        .overlay(
            RoundedRectangle(cornerRadius: 6).stroke(DesignColors.borderDefault, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct StatusChip: View {
    let ok: Bool
    let label: String

    var body: some View {
        let tint = ok ? DesignColors.Status.success : DesignColors.Status.warning
        HStack(spacing: 6) {
            Circle().fill(tint).frame(width: 6, height: 6)
            Text(label)
        }
        .font(DesignFonts.mono(10.5).weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(tint.opacity(0.10))
        .clipShape(Capsule())
    }
}

#Preview {
    SettingsView(env: .preview())
        .background(DesignColors.bgPrimary)
}
