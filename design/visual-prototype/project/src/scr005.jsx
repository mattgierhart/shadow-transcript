// SCR-005 Settings Sheet — overlay on main window.

function SettingRow({ label, sub, control, last = false }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 16,
      padding: '14px 0',
      borderBottom: last ? 'none' : `0.5px solid ${TOKENS.border.subtle}`,
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, color: TOKENS.text.primary, fontWeight: 500 }}>{label}</div>
        {sub && <div style={{ fontSize: 11.5, color: TOKENS.text.secondary, marginTop: 3, lineHeight: 1.45 }}>{sub}</div>}
      </div>
      <div style={{ flexShrink: 0 }}>{control}</div>
    </div>
  );
}

function Section({ title, children, footnote }) {
  return (
    <div style={{ marginBottom: 24 }}>
      <div style={{
        fontSize: 10.5, color: TOKENS.text.muted, fontFamily: FONT_MONO,
        textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 6,
        paddingLeft: 2,
      }}>{title}</div>
      <div style={{
        background: TOKENS.bg.secondary,
        border: `0.5px solid ${TOKENS.border.default}`,
        borderRadius: 10,
        padding: '0 16px',
      }}>
        {children}
      </div>
      {footnote && (
        <div style={{ fontSize: 10.5, color: TOKENS.text.muted, marginTop: 6, paddingLeft: 2, fontFamily: FONT_MONO, lineHeight: 1.5 }}>
          {footnote}
        </div>
      )}
    </div>
  );
}

function Select({ value, options }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 8,
      padding: '6px 8px 6px 10px',
      background: TOKENS.bg.tertiary,
      border: `0.5px solid ${TOKENS.border.default}`,
      borderRadius: 6,
      fontSize: 12, fontFamily: FONT_UI, color: TOKENS.text.primary,
      minWidth: 180,
    }}>
      <span style={{ flex: 1 }}>{value}</span>
      <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke={TOKENS.text.secondary} strokeWidth="2.5">
        <polyline points="6 9 12 15 18 9" />
      </svg>
    </div>
  );
}

function Toggle({ on = true }) {
  return (
    <div style={{
      width: 30, height: 18,
      background: on ? TOKENS.accent.primary : '#3a3a3c',
      borderRadius: 999,
      position: 'relative',
    }}>
      <div style={{
        position: 'absolute', top: 2, left: on ? 14 : 2,
        width: 14, height: 14, borderRadius: '50%', background: '#fff',
      }} />
    </div>
  );
}

function FolderPicker({ path }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 8,
      padding: '6px 10px',
      background: TOKENS.bg.tertiary,
      border: `0.5px solid ${TOKENS.border.default}`,
      borderRadius: 6,
      fontSize: 11.5, fontFamily: FONT_MONO, color: TOKENS.text.primary,
      maxWidth: 260,
    }}>
      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke={TOKENS.accent.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
      </svg>
      <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{path}</span>
      <button style={{
        background: 'transparent', color: TOKENS.text.secondary,
        border: 'none', cursor: 'pointer', fontSize: 11, padding: 0,
        fontFamily: FONT_UI, fontWeight: 500,
      }}>Choose…</button>
    </div>
  );
}

function StatusChip({ ok, label }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '3px 9px', borderRadius: 999,
      background: ok ? 'rgba(34,197,94,0.10)' : 'rgba(245,158,11,0.10)',
      color: ok ? TOKENS.status.success : TOKENS.status.warning,
      fontSize: 10.5, fontFamily: FONT_MONO, fontWeight: 600,
    }}>
      <span style={{
        width: 6, height: 6, borderRadius: '50%',
        background: ok ? TOKENS.status.success : TOKENS.status.warning,
      }} />
      {label}
    </span>
  );
}

function SettingsSheet() {
  return (
    <div style={{
      width: 560,
      maxHeight: 620,
      background: 'rgba(20,20,21,0.98)',
      backdropFilter: 'blur(40px)',
      border: `0.5px solid rgba(255,255,255,0.06)`,
      borderRadius: 12,
      boxShadow: '0 24px 80px rgba(0,0,0,0.7), 0 0 0 0.5px rgba(0,0,0,0.5)',
      fontFamily: FONT_UI,
      display: 'flex', flexDirection: 'column',
      overflow: 'hidden',
    }}>
      {/* Header */}
      <div style={{
        padding: '14px 20px',
        borderBottom: `0.5px solid ${TOKENS.border.default}`,
        display: 'flex', alignItems: 'center',
      }}>
        <div>
          <div style={{ fontSize: 14, fontWeight: 600, color: TOKENS.text.primary }}>Settings</div>
          <div style={{ fontSize: 11, color: TOKENS.text.muted, fontFamily: FONT_MONO, marginTop: 2 }}>auto-saves on change</div>
        </div>
        <div style={{ flex: 1 }} />
        <button style={{
          background: 'transparent',
          border: `0.5px solid ${TOKENS.border.default}`,
          borderRadius: 6, padding: '4px 10px',
          color: TOKENS.text.secondary, fontSize: 11.5, cursor: 'pointer', fontFamily: FONT_UI,
        }}>Done <span style={{ fontFamily: FONT_MONO, fontSize: 10, opacity: 0.6, marginLeft: 4 }}>esc</span></button>
      </div>

      {/* Scrollable body */}
      <div style={{ flex: 1, overflow: 'hidden', padding: '20px 20px 16px' }}>
        <Section title="Audio">
          <SettingRow
            label="Input device"
            sub="Microphone used for your voice capture."
            control={<Select value="MacBook Pro Microphone" />}
          />
          <SettingRow
            label="Capture system audio"
            sub="Pulls audio from other apps via ScreenCaptureKit. No screen content captured."
            control={
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <StatusChip ok label="granted" />
                <Toggle on />
              </div>
            }
            last
          />
        </Section>

        <Section title="Transcription">
          <SettingRow
            label="Whisper model"
            sub="small.en · 466 MB · balanced accuracy / speed"
            control={<Select value="small.en" />}
          />
          <SettingRow
            label="Speaker diarization"
            sub="pyannote 3.1 sidecar · runs locally as a separate process"
            control={<Toggle on />}
            last
          />
        </Section>

        <Section title="Export">
          <SettingRow
            label="Obsidian vault"
            sub="Path where transcripts are written as markdown."
            control={<FolderPicker path="~/Vaults/work-notes" />}
          />
          <SettingRow
            label="Subfolder"
            sub={<span style={{ fontFamily: FONT_MONO }}>./Meetings/</span>}
            control={
              <div style={{
                padding: '6px 10px',
                background: TOKENS.bg.tertiary,
                border: `0.5px solid ${TOKENS.border.default}`,
                borderRadius: 6,
                fontSize: 12, fontFamily: FONT_MONO, color: TOKENS.text.primary,
                minWidth: 120,
              }}>Meetings</div>
            }
          />
          <SettingRow
            label="Auto-export after processing"
            sub="Skip the manual Export click — useful for set-and-forget."
            control={<Toggle on={false} />}
            last
          />
        </Section>

        <Section
          title="Privacy"
          footnote="BR-101 · BR-102 · audio is held only in memory + a temp file for the duration of processing, then erased. There is no opt-out."
        >
          <SettingRow
            label="Local processing"
            sub="All transcription and diarization happens on this Mac. No network calls."
            control={<StatusChip ok label="on · locked" />}
          />
          <SettingRow
            label="Auto-delete audio after processing"
            sub="Temporary audio is removed once the markdown is written. Cannot be disabled."
            control={<StatusChip ok label="on · locked" />}
            last
          />
        </Section>
      </div>
    </div>
  );
}

function ScreenSCR005({ width = 1100, height = 700 }) {
  return (
    <div style={{ width, height, position: 'relative' }}>
      <MacWindow width={width} height={height} title="Transcript Shadow" toolbarRight={<><IconSidebar /><IconGear /></>}>
        <Sidebar selected="t1" />
        <div style={{
          flex: 1, background: TOKENS.bg.primary,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          padding: 48,
          opacity: 0.35, filter: 'blur(0.3px)',
        }}>
          <div style={{ width: '100%', maxWidth: 540, textAlign: 'center' }}>
            <div style={{ fontSize: 13, color: TOKENS.text.muted, fontFamily: FONT_MONO }}>main content (settings sheet open)</div>
          </div>
        </div>
      </MacWindow>
      {/* Dim layer */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'rgba(0,0,0,0.32)',
        pointerEvents: 'none',
        borderRadius: 10,
      }} />
      {/* Sheet — anchored from the top, like macOS */}
      <div style={{
        position: 'absolute', top: 44, left: '50%',
        transform: 'translateX(-50%)',
      }}>
        <SettingsSheet />
      </div>
    </div>
  );
}

window.ScreenSCR005 = ScreenSCR005;
window.SettingsSheet = SettingsSheet;
