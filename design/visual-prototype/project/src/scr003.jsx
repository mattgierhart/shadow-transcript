// SCR-003 Processing View
// Spacious. Three-stage pipeline: Transcribing → Diarizing → Formatting.

function PipelineStage({ status, label, sub, percent, icon }) {
  const isActive = status === 'active';
  const isDone = status === 'done';
  const isError = status === 'error';
  const dot = isDone ? TOKENS.status.success : isActive ? TOKENS.accent.primary : isError ? TOKENS.status.error : TOKENS.text.muted;
  const bg = isActive ? 'rgba(45,212,191,0.06)' : 'transparent';
  const border = isActive ? 'rgba(45,212,191,0.30)' : TOKENS.border.default;
  return (
    <div style={{
      padding: '14px 16px',
      background: bg,
      border: `0.5px solid ${border}`,
      borderRadius: 10,
      display: 'flex', alignItems: 'center', gap: 14,
    }}>
      {/* Status dot */}
      <div style={{
        width: 28, height: 28, borderRadius: '50%',
        background: isActive ? 'rgba(45,212,191,0.12)' : isDone ? 'rgba(34,197,94,0.12)' : TOKENS.bg.tertiary,
        border: `0.5px solid ${isActive ? 'rgba(45,212,191,0.35)' : isDone ? 'rgba(34,197,94,0.35)' : TOKENS.border.default}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative',
      }}>
        {isDone ? (
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={TOKENS.status.success} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <polyline points="20 6 9 17 4 12" />
          </svg>
        ) : isActive ? (
          <div style={{
            width: 10, height: 10, borderRadius: '50%',
            background: TOKENS.accent.primary,
            boxShadow: `0 0 12px ${TOKENS.accent.primary}`,
            animation: 'rec-pulse 1.4s ease-in-out infinite',
          }} />
        ) : (
          <div style={{ width: 8, height: 8, borderRadius: '50%', background: TOKENS.text.muted }} />
        )}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 13, fontWeight: 500, color: TOKENS.text.primary }}>{label}</span>
          <span style={{ fontSize: 11, color: TOKENS.text.secondary, fontFamily: FONT_MONO }}>{sub}</span>
        </div>
        {/* Progress bar */}
        <div style={{
          marginTop: 8,
          height: 3,
          background: TOKENS.bg.tertiary,
          borderRadius: 999,
          overflow: 'hidden',
        }}>
          <div style={{
            height: '100%',
            width: `${percent}%`,
            background: isDone ? TOKENS.status.success : TOKENS.accent.primary,
            borderRadius: 999,
            transition: 'width 0.4s',
          }} />
        </div>
      </div>
      <div style={{
        fontFamily: FONT_MONO, fontSize: 11,
        color: isActive ? TOKENS.accent.primary : isDone ? TOKENS.status.success : TOKENS.text.muted,
        minWidth: 44, textAlign: 'right',
      }}>{percent}%</div>
    </div>
  );
}

function ScreenSCR003({ width = 1100, height = 700 }) {
  return (
    <MacWindow width={width} height={height} processing>
      <Sidebar />
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        background: TOKENS.bg.primary,
        position: 'relative',
      }}>
        <div style={{
          position: 'absolute', inset: 0, pointerEvents: 'none',
          background: 'radial-gradient(circle at 50% 42%, rgba(45,212,191,0.06), transparent 55%)',
        }} />
        <div style={{
          flex: 1,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          padding: 48,
        }}>
          <div style={{ width: '100%', maxWidth: 540, display: 'flex', flexDirection: 'column', gap: 32 }}>
            {/* Heading */}
            <div style={{ textAlign: 'center' }}>
              <div style={{
                fontSize: 11, color: TOKENS.text.muted, fontFamily: FONT_MONO,
                textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 10,
              }}>Recording stopped · processing locally</div>
              <div style={{ fontSize: 22, fontWeight: 600, color: TOKENS.text.primary, marginBottom: 6 }}>
                Q3 Planning · Eng + Design
              </div>
              <div style={{ fontSize: 12, color: TOKENS.text.secondary, fontFamily: FONT_MONO }}>
                47:12 captured · est. 2 min 10 s remaining
              </div>
            </div>

            {/* Pipeline */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <PipelineStage
                status="done"
                label="Transcribing"
                sub="WhisperKit · small.en"
                percent={100}
              />
              <PipelineStage
                status="active"
                label="Identifying speakers"
                sub="pyannote · sidecar"
                percent={62}
              />
              <PipelineStage
                status="waiting"
                label="Formatting transcript"
                sub="merge · markdown"
                percent={0}
              />
            </div>

            {/* Estimated time + cancel */}
            <div style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              paddingTop: 12,
              borderTop: `0.5px solid ${TOKENS.border.default}`,
            }}>
              <div style={{ fontSize: 11, color: TOKENS.text.muted, fontFamily: FONT_MONO }}>
                <span style={{ color: TOKENS.status.success }}>●</span> audio stays on this Mac · auto-deleted on completion
              </div>
              <button style={{
                background: 'transparent',
                color: TOKENS.text.secondary,
                border: `0.5px solid ${TOKENS.border.default}`,
                borderRadius: 6,
                padding: '5px 12px',
                fontSize: 11.5,
                fontFamily: FONT_UI,
                cursor: 'pointer',
              }}>Cancel</button>
            </div>
          </div>
        </div>
      </div>
    </MacWindow>
  );
}

window.ScreenSCR003 = ScreenSCR003;
window.PipelineStage = PipelineStage;
