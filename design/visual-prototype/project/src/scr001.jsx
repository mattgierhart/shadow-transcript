// SCR-001 Main Window — Idle / Pre-Record
// Spacious. Source toggles + pre-record level preview + start-only Record button.

function PreRecordLevels({ active = true }) {
  // 56 bars, simulated audio levels (mic + system audio)
  const bars = React.useMemo(() => {
    const arr = [];
    for (let i = 0; i < 56; i++) {
      // base envelope shaped like a couple of speech blobs
      const t = i / 56;
      const env = Math.sin(t * Math.PI * 2.3) * 0.45 + Math.sin(t * 11) * 0.18 + 0.45;
      const noise = (Math.sin(i * 37.7) + 1) / 2 * 0.4;
      const v = Math.max(0.08, Math.min(1, env * 0.75 + noise * 0.35));
      arr.push(v);
    }
    return arr;
  }, []);
  return (
    <div style={{
      width: '100%', height: 56,
      display: 'flex', alignItems: 'center', gap: 3,
      padding: '0 2px',
    }}>
      {bars.map((v, i) => (
        <div key={i} style={{
          flex: 1,
          height: `${v * 100}%`,
          minHeight: 3,
          background: active
            ? `linear-gradient(180deg, ${TOKENS.accent.primary}, ${TOKENS.accent.primaryHover})`
            : TOKENS.text.muted,
          opacity: active ? (0.5 + v * 0.5) : 0.35,
          borderRadius: 1.5,
        }} />
      ))}
    </div>
  );
}

function SourceToggle({ icon, label, active = true, sub }) {
  return (
    <div style={{
      flex: 1,
      padding: '14px 16px',
      background: active ? 'rgba(45,212,191,0.06)' : TOKENS.bg.tertiary,
      border: `0.5px solid ${active ? 'rgba(45,212,191,0.35)' : TOKENS.border.default}`,
      borderRadius: 10,
      display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 8,
        background: active ? 'rgba(45,212,191,0.10)' : 'rgba(255,255,255,0.03)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        border: `0.5px solid ${active ? 'rgba(45,212,191,0.3)' : TOKENS.border.default}`,
      }}>
        {icon}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 12.5, fontWeight: 500, color: TOKENS.text.primary }}>{label}</div>
        <div style={{ fontSize: 10.5, color: TOKENS.text.secondary, fontFamily: FONT_MONO, marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{sub}</div>
      </div>
      <div style={{
        width: 26, height: 16,
        background: active ? TOKENS.accent.primary : '#3a3a3c',
        borderRadius: 999,
        position: 'relative',
        transition: 'background 0.2s',
      }}>
        <div style={{
          position: 'absolute', top: 2, left: active ? 12 : 2,
          width: 12, height: 12, borderRadius: '50%', background: '#fff',
          transition: 'left 0.2s',
        }} />
      </div>
    </div>
  );
}

function RecordButton({ disabled = false }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
      <button style={{
        width: 80, height: 80, borderRadius: '50%',
        background: disabled ? '#3a3a3c' : TOKENS.accent.rec,
        border: 'none',
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.3 : 1,
        position: 'relative',
        boxShadow: disabled ? 'none' : `0 0 0 6px rgba(239,68,68,0.10), 0 8px 24px rgba(239,68,68,0.25)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{
          width: 28, height: 28, borderRadius: '50%',
          background: '#fff',
          opacity: 0.95,
        }} />
      </button>
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontSize: 13, fontWeight: 500, color: TOKENS.text.primary }}>Start recording</div>
        <div style={{ fontSize: 11, color: TOKENS.text.muted, marginTop: 3, fontFamily: FONT_MONO }}>Space</div>
      </div>
    </div>
  );
}

function ScreenSCR001({ width = 1100, height = 700 }) {
  return (
    <MacWindow
      width={width}
      height={height}
      title="Transcript Shadow"
      toolbarRight={
        <>
          <IconSidebar />
          <IconGear />
        </>
      }
    >
      <Sidebar />
      {/* Content area */}
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        background: TOKENS.bg.primary,
        position: 'relative',
      }}>
        {/* Subtle ambient glow */}
        <div style={{
          position: 'absolute', inset: 0, pointerEvents: 'none',
          background: 'radial-gradient(circle at 50% 38%, rgba(45,212,191,0.05), transparent 50%)',
        }} />
        <div style={{
          flex: 1,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          padding: 48,
        }}>
          <div style={{ width: '100%', maxWidth: 540, display: 'flex', flexDirection: 'column', gap: 32 }}>
            {/* Status line */}
            <div style={{ textAlign: 'center' }}>
              <div style={{
                display: 'inline-flex', alignItems: 'center', gap: 8,
                padding: '4px 12px',
                borderRadius: 999,
                background: TOKENS.bg.secondary,
                border: `0.5px solid ${TOKENS.border.default}`,
                fontSize: 11, color: TOKENS.text.secondary,
                fontFamily: FONT_MONO,
              }}>
                <span style={{ width: 6, height: 6, borderRadius: '50%', background: TOKENS.status.success }} />
                Ready · all processing stays on this Mac
              </div>
            </div>

            {/* Source toggles */}
            <div style={{ display: 'flex', gap: 12 }}>
              <SourceToggle
                icon={<IconMic size={16} active />}
                label="Microphone"
                sub="MacBook Pro Microphone"
                active
              />
              <SourceToggle
                icon={<IconSpeakerWave size={16} active />}
                label="System audio"
                sub="ScreenCaptureKit · all apps"
                active
              />
            </div>

            {/* Pre-record level preview */}
            <div style={{
              padding: '16px 18px',
              background: TOKENS.bg.secondary,
              border: `0.5px solid ${TOKENS.border.default}`,
              borderRadius: 10,
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 10, alignItems: 'center' }}>
                <span style={{ fontSize: 11, color: TOKENS.text.secondary, textTransform: 'uppercase', letterSpacing: 0.6, fontWeight: 600 }}>Input level</span>
                <span style={{ fontSize: 10.5, color: TOKENS.text.muted, fontFamily: FONT_MONO }}>pre-flight · −18 dBFS</span>
              </div>
              <PreRecordLevels active />
            </div>

            {/* Record button */}
            <div style={{ display: 'flex', justifyContent: 'center', marginTop: 8 }}>
              <RecordButton />
            </div>

            {/* Last recording */}
            <div style={{
              textAlign: 'center', fontSize: 11.5, color: TOKENS.text.secondary,
              borderTop: `0.5px solid ${TOKENS.border.default}`, paddingTop: 16,
            }}>
              Last: <span style={{ color: TOKENS.text.primary }}>Q3 Planning · Eng + Design</span>
              <span style={{ color: TOKENS.text.muted }}> · 32 min ago</span>
            </div>
          </div>
        </div>
      </div>
    </MacWindow>
  );
}

window.ScreenSCR001 = ScreenSCR001;
window.PreRecordLevels = PreRecordLevels;
window.RecordButton = RecordButton;
