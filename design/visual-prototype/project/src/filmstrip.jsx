// Journey filmstrip — UJ-001 transitions, with the main-window hide/restore made explicit.

function FilmFrame({ idx, title, sub, children, width = 360, height = 240 }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10, width, fontFamily: FONT_UI }}>
      <div style={{
        width, height,
        background: '#050507',
        borderRadius: 10,
        overflow: 'hidden',
        position: 'relative',
        border: `0.5px solid ${TOKENS.border.default}`,
      }}>
        {children}
        {/* Frame index badge */}
        <div style={{
          position: 'absolute', top: 10, left: 10,
          padding: '3px 8px',
          background: 'rgba(0,0,0,0.6)',
          backdropFilter: 'blur(10px)',
          border: '0.5px solid rgba(255,255,255,0.10)',
          borderRadius: 999,
          fontSize: 10, color: TOKENS.text.secondary, fontFamily: FONT_MONO,
          fontWeight: 600,
        }}>{idx.toString().padStart(2, '0')}</div>
      </div>
      <div>
        <div style={{ fontSize: 12, fontWeight: 600, color: TOKENS.text.primary }}>{title}</div>
        <div style={{ fontSize: 10.5, color: TOKENS.text.secondary, marginTop: 3, lineHeight: 1.4 }}>{sub}</div>
      </div>
    </div>
  );
}

// Small representation of the macOS desktop with notch
function DesktopMini({ children, showWindow = true, recording = false, hudExpanded = false, windowOpacity = 1, processing = false, transcript = false }) {
  return (
    <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg,#1a1820 0%, #0a0a12 100%)' }}>
      {/* Menu bar with notch */}
      <div style={{
        height: 16,
        background: '#000',
        position: 'relative',
        display: 'flex', alignItems: 'center',
        padding: '0 6px',
        fontSize: 7, color: 'rgba(255,255,255,0.7)',
        gap: 8,
      }}>
        <span style={{ fontWeight: 600 }}>Zoomeet</span>
        <span style={{ opacity: 0.6 }}>Meeting</span>
        <span style={{ marginLeft: 'auto', fontFamily: FONT_MONO, opacity: 0.7 }}>11:48</span>
        {/* Notch */}
        <div style={{
          position: 'absolute', top: 0, left: '50%',
          transform: 'translateX(-50%)',
          width: hudExpanded ? 116 : 64, height: 16,
          background: '#000',
          borderBottomLeftRadius: hudExpanded ? 8 : 6,
          borderBottomRightRadius: hudExpanded ? 8 : 6,
          display: 'flex', alignItems: 'center', justifyContent: hudExpanded ? 'space-between' : 'center',
          padding: hudExpanded ? '0 6px' : 0,
          transition: 'width 0.3s',
        }}>
          {recording && !hudExpanded && (
            <span style={{ width: 4, height: 4, borderRadius: '50%', background: TOKENS.accent.rec, boxShadow: `0 0 4px ${TOKENS.accent.rec}` }} />
          )}
          {recording && hudExpanded && (
            <>
              <div style={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                <span style={{ width: 4, height: 4, borderRadius: '50%', background: TOKENS.accent.rec, boxShadow: `0 0 4px ${TOKENS.accent.rec}` }} />
                <span style={{ fontSize: 6.5, color: '#fff', fontWeight: 500 }}>Recording</span>
              </div>
              <span style={{
                fontSize: 6.5, color: '#fff', fontWeight: 600,
                background: TOKENS.accent.rec,
                padding: '1px 5px', borderRadius: 3,
              }}>Stop</span>
            </>
          )}
        </div>
      </div>
      {/* Meeting backdrop */}
      <div style={{
        position: 'absolute', inset: '16px 0 0 0',
        background: 'linear-gradient(180deg,#161618,#0a0a0c)',
        display: 'grid',
        gridTemplateColumns: '1fr 1fr', gridTemplateRows: '1fr 1fr',
        gap: 4, padding: 8,
      }}>
        {['Priya', 'Marc', 'Lena', 'You'].map((n, i) => (
          <div key={n} style={{
            background: ['#5b6470','#574a3f','#3f4d57','#1a3d3a'][i],
            borderRadius: 3,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            border: i === 3 ? `1px solid ${TOKENS.accent.primary}55` : 'none',
          }}>
            <div style={{
              width: 14, height: 14, borderRadius: '50%',
              background: 'rgba(255,255,255,0.07)',
            }} />
          </div>
        ))}
      </div>
      {/* Floating main window */}
      {showWindow && (
        <div style={{
          position: 'absolute',
          left: '50%', top: '50%',
          transform: `translate(-50%, -50%)`,
          width: '78%', height: '78%',
          background: TOKENS.bg.primary,
          borderRadius: 6,
          overflow: 'hidden',
          boxShadow: '0 8px 24px rgba(0,0,0,0.6), 0 0 0 0.5px rgba(255,255,255,0.06)',
          display: 'flex', flexDirection: 'column',
          opacity: windowOpacity,
          transition: 'opacity 0.3s, transform 0.3s',
        }}>
          {/* Mini title bar */}
          <div style={{
            height: 14,
            background: TOKENS.bg.secondary,
            display: 'flex', alignItems: 'center', gap: 3,
            padding: '0 6px',
            borderBottom: '0.5px solid ' + TOKENS.border.default,
          }}>
            {[0,1,2].map(i => (
              <span key={i} style={{ width: 5, height: 5, borderRadius: '50%', background: ['#FF5F57','#FEBC2E','#28C840'][i] }} />
            ))}
            <span style={{ flex: 1, textAlign: 'center', fontSize: 6, color: TOKENS.text.muted, fontFamily: FONT_UI }}>
              {processing ? 'Processing transcript…' : transcript ? 'Q3 Planning · Eng + Design' : 'Transcript Shadow'}
            </span>
          </div>
          <div style={{ flex: 1, display: 'flex' }}>
            {/* Sidebar */}
            <div style={{
              width: 36,
              background: TOKENS.bg.secondary,
              borderRight: '0.5px solid ' + TOKENS.border.default,
              padding: '4px 3px',
              display: 'flex', flexDirection: 'column', gap: 2,
            }}>
              {[0,1,2,3,4].map(i => (
                <div key={i} style={{
                  height: 8,
                  background: i === 0 && transcript ? 'rgba(45,212,191,0.15)' : 'rgba(255,255,255,0.04)',
                  borderRadius: 1,
                  borderLeft: i === 0 && transcript ? `1px solid ${TOKENS.accent.primary}` : 'none',
                }} />
              ))}
            </div>
            {/* Content */}
            <div style={{ flex: 1, padding: 8, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 5 }}>
              {children}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function MiniIdleContent() {
  return (
    <>
      <div style={{ display: 'flex', gap: 4, width: '70%' }}>
        <div style={{ flex: 1, height: 10, background: 'rgba(45,212,191,0.10)', border: '0.5px solid rgba(45,212,191,0.25)', borderRadius: 2 }} />
        <div style={{ flex: 1, height: 10, background: 'rgba(45,212,191,0.10)', border: '0.5px solid rgba(45,212,191,0.25)', borderRadius: 2 }} />
      </div>
      <div style={{ width: '70%', height: 6, background: TOKENS.bg.secondary, borderRadius: 2, display: 'flex', gap: 1, padding: 1 }}>
        {Array.from({length: 16}).map((_, i) => (
          <div key={i} style={{ flex: 1, height: '100%', background: TOKENS.accent.primary, opacity: 0.3 + Math.random() * 0.6, borderRadius: 0.5 }} />
        ))}
      </div>
      <div style={{
        width: 24, height: 24, borderRadius: '50%',
        background: TOKENS.accent.rec,
        boxShadow: `0 0 0 3px rgba(239,68,68,0.15)`,
        marginTop: 3,
      }} />
    </>
  );
}

function MiniProcessingContent() {
  return (
    <>
      <div style={{ fontSize: 7, color: TOKENS.text.secondary, fontFamily: FONT_MONO }}>processing…</div>
      {[100, 62, 0].map((p, i) => (
        <div key={i} style={{ width: '75%', height: 6, background: TOKENS.bg.secondary, borderRadius: 3, overflow: 'hidden', display: 'flex', alignItems: 'center', padding: '0 2px', gap: 3 }}>
          <span style={{ width: 4, height: 4, borderRadius: '50%', background: i === 0 ? TOKENS.status.success : i === 1 ? TOKENS.accent.primary : TOKENS.text.muted }} />
          <div style={{ flex: 1, height: 2, background: TOKENS.bg.tertiary, borderRadius: 999 }}>
            <div style={{ width: `${p}%`, height: '100%', background: i === 0 ? TOKENS.status.success : TOKENS.accent.primary, borderRadius: 999 }} />
          </div>
        </div>
      ))}
    </>
  );
}

function MiniTranscriptContent() {
  const blocks = [
    { c: 0, w: [70, 90, 60] },
    { c: 1, w: [85, 65] },
    { c: 2, w: [75, 92, 50] },
    { c: 3, w: [60, 80] },
  ];
  return (
    <div style={{ width: '90%', display: 'flex', flexDirection: 'column', gap: 4, alignSelf: 'stretch' }}>
      {/* Speaker pills row */}
      <div style={{ display: 'flex', gap: 3, marginBottom: 2 }}>
        {TOKENS.speakers.slice(0, 5).map((c, i) => (
          <div key={i} style={{
            height: 5, width: 16, borderRadius: 999,
            background: `${c}33`, border: `0.5px solid ${c}55`,
          }} />
        ))}
        <div style={{ flex: 1 }} />
        <div style={{ height: 5, width: 22, borderRadius: 2, background: TOKENS.accent.primary }} />
      </div>
      {blocks.map((b, i) => (
        <div key={i} style={{ display: 'flex', gap: 3, alignItems: 'flex-start' }}>
          <div style={{ width: 12, height: 4, borderRadius: 999, background: `${TOKENS.speakers[b.c]}55`, marginTop: 1, flexShrink: 0 }} />
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 1.5 }}>
            {b.w.map((w, j) => (
              <div key={j} style={{ height: 2, width: `${w}%`, background: 'rgba(245,245,245,0.5)', borderRadius: 0.5 }} />
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function Arrow({ note }) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
      width: 60, marginTop: 90, fontFamily: FONT_UI, color: TOKENS.text.muted,
    }}>
      <div style={{
        fontSize: 9, fontFamily: FONT_MONO,
        color: TOKENS.text.muted, textAlign: 'center', lineHeight: 1.3,
      }}>{note}</div>
      <svg width="44" height="14" viewBox="0 0 44 14">
        <line x1="0" y1="7" x2="36" y2="7" stroke={TOKENS.text.muted} strokeWidth="0.8" strokeDasharray="2 2"/>
        <polyline points="32,3 40,7 32,11" fill="none" stroke={TOKENS.text.secondary} strokeWidth="1.2"/>
      </svg>
    </div>
  );
}

function Filmstrip({ width = 2200, height = 460 }) {
  return (
    <div style={{
      width, height,
      background: TOKENS.bg.primary,
      padding: 32,
      fontFamily: FONT_UI,
      boxSizing: 'border-box',
      color: TOKENS.text.primary,
    }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 12, marginBottom: 24 }}>
        <span style={{ fontSize: 11, color: TOKENS.accent.primary, fontFamily: FONT_MONO, letterSpacing: 0.6 }}>UJ-001</span>
        <span style={{ fontSize: 18, fontWeight: 600 }}>Pre-flight → Ambient → Review</span>
        <span style={{ fontSize: 12, color: TOKENS.text.secondary }}>
          Frames 02 + 03: main window absent, only the HUD persists.
        </span>
      </div>

      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 0 }}>
        {/* Frame 01: SCR-001 idle */}
        <FilmFrame idx={1} title="SCR-001 · Pre-flight" sub="Source toggles + level preview. Main window centered. Ambient glow.">
          <DesktopMini showWindow windowOpacity={1}>
            <MiniIdleContent />
          </DesktopMini>
        </FilmFrame>

        <Arrow note={"click\nRecord"} />

        {/* Frame 02: Transition — main window fading out, HUD collapsing to notch */}
        <FilmFrame idx={2} title="Hide transition · ~150ms" sub="Main window fades + scales down. HUD spawns at the notch.">
          <DesktopMini showWindow recording hudExpanded windowOpacity={0.18}>
            <MiniIdleContent />
          </DesktopMini>
        </FilmFrame>

        <Arrow note={"main\nhides"} />

        {/* Frame 03: Ambient — main window absent, only HUD */}
        <FilmFrame idx={3} title="SCR-002 · Ambient" sub="Main window absent. Notch HUD persists. User attends meeting.">
          <DesktopMini showWindow={false} recording />
        </FilmFrame>

        <Arrow note={"click\nStop"} />

        {/* Frame 04: Restore + processing */}
        <FilmFrame idx={4} title="SCR-003 · Restore + process" sub="HUD collapses. Main window restores into the pipeline.">
          <DesktopMini showWindow processing windowOpacity={1}>
            <MiniProcessingContent />
          </DesktopMini>
        </FilmFrame>

        <Arrow note={"~2 min\nlater"} />

        {/* Frame 05: SCR-004 transcript */}
        <FilmFrame idx={5} title="SCR-004 · Money shot" sub="Density flips dense. Speaker pills · Export to Obsidian.">
          <DesktopMini showWindow transcript windowOpacity={1}>
            <MiniTranscriptContent />
          </DesktopMini>
        </FilmFrame>
      </div>
    </div>
  );
}

window.Filmstrip = Filmstrip;
