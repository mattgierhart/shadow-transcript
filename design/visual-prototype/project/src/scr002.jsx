// SCR-002 — Recording HUD, both realizations
// DES-105 Notch HUD (left) and DES-106 Menu Bar Extra (right) as peers.

function MeetingBackdrop({ collapsed = true }) {
  // Faux meeting app behind the HUD — abstract tiles so we don't ape any product
  const tiles = [
    { name: 'Priya · iPad', color: '#5b6470', initials: 'P' },
    { name: 'Marc', color: '#574a3f', initials: 'M' },
    { name: 'Lena Ortiz', color: '#3f4d57', initials: 'L' },
    { name: 'You', color: '#1a3d3a', initials: 'You', self: true },
  ];
  return (
    <div style={{
      flex: 1, padding: 24,
      background: 'linear-gradient(180deg, #131316 0%, #0c0c0e 100%)',
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gridTemplateRows: '1fr 1fr',
      gap: 12,
    }}>
      {tiles.map((t, i) => (
        <div key={i} style={{
          background: t.color,
          borderRadius: 8,
          position: 'relative',
          overflow: 'hidden',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          border: t.self ? `1.5px solid ${TOKENS.accent.primary}66` : '0.5px solid rgba(255,255,255,0.04)',
        }}>
          <div style={{
            width: 64, height: 64, borderRadius: '50%',
            background: 'rgba(255,255,255,0.06)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: 'rgba(255,255,255,0.4)', fontWeight: 600, fontSize: 22,
            fontFamily: FONT_UI,
          }}>{t.initials}</div>
          <div style={{
            position: 'absolute', left: 10, bottom: 10,
            fontSize: 10.5, color: 'rgba(255,255,255,0.7)',
            padding: '2px 8px',
            background: 'rgba(0,0,0,0.5)',
            borderRadius: 4,
            fontFamily: FONT_UI,
            backdropFilter: 'blur(4px)',
          }}>{t.name}</div>
        </div>
      ))}
      {/* Meeting control strip */}
      <div style={{
        position: 'absolute', bottom: 24, left: '50%', transform: 'translateX(-50%)',
        display: 'flex', gap: 10, padding: '8px 10px',
        background: 'rgba(20,20,22,0.85)',
        backdropFilter: 'blur(20px)',
        border: '0.5px solid rgba(255,255,255,0.06)',
        borderRadius: 999,
      }}>
        {['mic', 'cam', 'share', 'chat', 'end'].map((k, i) => (
          <div key={k} style={{
            width: 32, height: 32, borderRadius: '50%',
            background: k === 'end' ? '#c0392b' : 'rgba(255,255,255,0.08)',
            border: '0.5px solid rgba(255,255,255,0.05)',
          }} />
        ))}
      </div>
    </div>
  );
}

// Notch-equipped MacBook menu bar
function NotchMenuBar({ recording, hover }) {
  return (
    <div style={{
      height: 38,
      background: '#000',
      display: 'flex', alignItems: 'stretch',
      position: 'relative',
      padding: '0 18px',
      gap: 14,
      fontFamily: FONT_UI,
      color: 'rgba(255,255,255,0.85)',
      fontSize: 12,
      fontWeight: 500,
    }}>
      {/* Left side: app menus */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, flex: 1, minWidth: 0 }}>
        <span style={{ width: 16, height: 16, borderRadius: 4, background: 'rgba(255,255,255,0.2)' }} />
        <span style={{ fontWeight: 600 }}>Zoomeet</span>
        <span style={{ color: 'rgba(255,255,255,0.6)' }}>Meeting</span>
        <span style={{ color: 'rgba(255,255,255,0.6)' }}>Edit</span>
        <span style={{ color: 'rgba(255,255,255,0.6)' }}>View</span>
        <span style={{ color: 'rgba(255,255,255,0.6)' }}>Help</span>
      </div>
      {/* Right side: status items */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, fontSize: 12, color: 'rgba(255,255,255,0.85)' }}>
        <span style={{ width: 14, height: 10, border: '1px solid rgba(255,255,255,0.6)', borderRadius: 2, position: 'relative' }}>
          <span style={{ position: 'absolute', inset: 1, background: TOKENS.status.success, borderRadius: 1 }} />
        </span>
        <span>100%</span>
        <span>􀙇</span>
        <span style={{ fontFamily: FONT_MONO }}>Thu 11:48</span>
      </div>
      {/* The notch */}
      <div style={{
        position: 'absolute',
        left: '50%', top: 0,
        transform: 'translateX(-50%)',
        width: 200, height: 38,
        background: '#000',
        borderBottomLeftRadius: 16,
        borderBottomRightRadius: 16,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 0 0 0 #000',
      }}>
        {recording && !hover && (
          <span style={{
            width: 9, height: 9, borderRadius: '50%',
            background: TOKENS.accent.rec,
            boxShadow: `0 0 6px ${TOKENS.accent.rec}`,
            animation: 'rec-pulse 1s ease-in-out infinite',
          }} />
        )}
      </div>
      {/* Expanded HUD attached to notch */}
      {recording && hover && (
        <div style={{
          position: 'absolute', top: 0, left: '50%',
          transform: 'translateX(-50%)',
          width: 320, minHeight: 38,
          background: '#000',
          borderBottomLeftRadius: 18,
          borderBottomRightRadius: 18,
          display: 'flex', alignItems: 'center', gap: 12,
          padding: '0 14px',
          boxShadow: '0 12px 32px rgba(0,0,0,0.55)',
        }}>
          <span style={{
            width: 9, height: 9, borderRadius: '50%',
            background: TOKENS.accent.rec,
            boxShadow: `0 0 6px ${TOKENS.accent.rec}`,
            animation: 'rec-pulse 1s ease-in-out infinite',
          }} />
          <span style={{ fontSize: 12, fontWeight: 500, color: 'rgba(255,255,255,0.92)' }}>Recording</span>
          <span style={{ flex: 1 }} />
          <button style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            background: TOKENS.accent.rec,
            color: '#fff',
            border: 'none',
            borderRadius: 6,
            padding: '4px 12px',
            fontSize: 11.5, fontWeight: 600,
            fontFamily: FONT_UI,
            cursor: 'pointer',
            boxShadow: '0 0 0 0.5px rgba(255,255,255,0.15) inset',
          }}>
            <span style={{ width: 8, height: 8, background: '#fff', borderRadius: 1.5 }} />
            Stop
          </button>
        </div>
      )}
    </div>
  );
}

// Plain menu bar for non-notch Macs (Intel iMac, MBA M1, etc.)
function PlainMenuBar({ recording, popover }) {
  return (
    <div style={{
      height: 28,
      background: 'rgba(15,15,17,0.92)',
      backdropFilter: 'blur(20px)',
      borderBottom: '0.5px solid rgba(255,255,255,0.08)',
      display: 'flex', alignItems: 'center',
      padding: '0 18px',
      gap: 14,
      fontFamily: FONT_UI,
      color: 'rgba(255,255,255,0.85)',
      fontSize: 12,
      fontWeight: 500,
      position: 'relative',
    }}>
      <span style={{ width: 16, height: 16, borderRadius: 4, background: 'rgba(255,255,255,0.18)' }} />
      <span style={{ fontWeight: 600 }}>Zoomeet</span>
      <span style={{ color: 'rgba(255,255,255,0.6)' }}>Meeting</span>
      <span style={{ color: 'rgba(255,255,255,0.6)' }}>Edit</span>
      <span style={{ color: 'rgba(255,255,255,0.6)' }}>View</span>
      <span style={{ color: 'rgba(255,255,255,0.6)' }}>Help</span>
      <span style={{ flex: 1 }} />
      {/* Status items */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, position: 'relative' }}>
        {recording && (
          <span id="ts-status-item" style={{
            display: 'inline-flex', alignItems: 'center', gap: 5,
            padding: '0 2px',
            position: 'relative',
            background: popover ? 'rgba(255,255,255,0.12)' : 'transparent',
            borderRadius: 4,
          }}>
            <span style={{
              width: 9, height: 9, borderRadius: '50%',
              background: TOKENS.accent.rec,
              boxShadow: `0 0 6px ${TOKENS.accent.rec}`,
              animation: 'rec-pulse 1s ease-in-out infinite',
            }} />
          </span>
        )}
        <span style={{ width: 14, height: 10, border: '1px solid rgba(255,255,255,0.6)', borderRadius: 2, position: 'relative' }}>
          <span style={{ position: 'absolute', inset: 1, background: TOKENS.status.success, borderRadius: 1 }} />
        </span>
        <span>100%</span>
        <span>􀙇</span>
        <span style={{ fontFamily: FONT_MONO }}>Thu 11:48</span>
      </div>
      {/* Popover */}
      {recording && popover && (
        <div style={{
          position: 'absolute',
          top: '100%', right: 96,
          marginTop: 6,
          width: 240,
          background: 'rgba(28,28,30,0.96)',
          backdropFilter: 'blur(30px)',
          border: '0.5px solid rgba(255,255,255,0.08)',
          borderRadius: 10,
          padding: 12,
          boxShadow: '0 20px 48px rgba(0,0,0,0.55), 0 0 0 0.5px rgba(0,0,0,0.4)',
          color: TOKENS.text.primary,
        }}>
          {/* Arrow */}
          <div style={{
            position: 'absolute',
            top: -5, right: 38,
            width: 10, height: 10,
            background: 'rgba(28,28,30,0.96)',
            borderTop: '0.5px solid rgba(255,255,255,0.08)',
            borderLeft: '0.5px solid rgba(255,255,255,0.08)',
            transform: 'rotate(45deg)',
          }} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <span style={{ width: 9, height: 9, borderRadius: '50%', background: TOKENS.accent.rec, animation: 'rec-pulse 1s ease-in-out infinite' }} />
            <span style={{ fontSize: 13, fontWeight: 600, color: TOKENS.text.primary }}>Recording</span>
            <span style={{ flex: 1 }} />
            <span style={{ fontSize: 10.5, color: TOKENS.text.muted, fontFamily: FONT_MONO }}>⌘⇧.</span>
          </div>
          <button style={{
            width: '100%', height: 34,
            background: TOKENS.accent.rec,
            color: '#fff',
            border: 'none',
            borderRadius: 7,
            fontSize: 13, fontWeight: 600,
            fontFamily: FONT_UI,
            cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}>
            <span style={{ width: 10, height: 10, background: '#fff', borderRadius: 2 }} />
            Stop
          </button>
        </div>
      )}
    </div>
  );
}

function DesktopWallpaper({ children, label, sublabel }) {
  return (
    <div style={{
      width: 720, height: 480,
      background: '#000',
      borderRadius: 12,
      overflow: 'hidden',
      boxShadow: '0 24px 60px rgba(0,0,0,0.5), 0 0 0 0.5px rgba(255,255,255,0.06)',
      display: 'flex', flexDirection: 'column',
      position: 'relative',
    }}>
      {children}
    </div>
  );
}

function HudPanel({ kind, states, label, hardware, notes, badge }) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', gap: 16,
      padding: 24,
      background: TOKENS.bg.secondary,
      border: `0.5px solid ${TOKENS.border.default}`,
      borderRadius: 12,
      width: 768,
    }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
        <span style={{ fontSize: 10.5, color: TOKENS.accent.primary, fontFamily: FONT_MONO, letterSpacing: 0.6 }}>{kind}</span>
        <span style={{ fontSize: 16, fontWeight: 600, color: TOKENS.text.primary }}>{label}</span>
        <span style={{ flex: 1 }} />
        <span style={{
          fontSize: 10, color: TOKENS.text.secondary,
          padding: '2px 8px',
          background: TOKENS.bg.tertiary,
          border: `0.5px solid ${TOKENS.border.default}`,
          borderRadius: 999, fontFamily: FONT_MONO,
        }}>{badge}</span>
      </div>
      <div style={{ fontSize: 12, color: TOKENS.text.secondary, lineHeight: 1.55 }}>
        {hardware}
      </div>
      {states}
      {notes && (
        <div style={{
          padding: '10px 12px',
          background: 'rgba(45,212,191,0.05)',
          border: '0.5px solid rgba(45,212,191,0.18)',
          borderRadius: 8,
          fontSize: 11, color: TOKENS.text.secondary, fontFamily: FONT_MONO, lineHeight: 1.5,
        }}>
          <span style={{ color: TOKENS.accent.primary }}>BR-501 ·</span> {notes}
        </div>
      )}
    </div>
  );
}

function StateLabel({ children }) {
  return <div style={{ fontSize: 10, fontFamily: FONT_MONO, color: TOKENS.text.muted, textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 8 }}>{children}</div>;
}

function ScreenSCR002({ width = 1640, height = 1140 }) {
  return (
    <div style={{
      width, height,
      background: TOKENS.bg.primary,
      padding: 32,
      fontFamily: FONT_UI,
      color: TOKENS.text.primary,
      display: 'flex', flexDirection: 'column', gap: 24,
      boxSizing: 'border-box',
    }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
        <span style={{ fontSize: 11, color: TOKENS.accent.primary, fontFamily: FONT_MONO, letterSpacing: 0.6 }}>SCR-002</span>
        <span style={{ fontSize: 22, fontWeight: 600 }}>Recording HUD — peer realizations</span>
        <span style={{ fontSize: 12, color: TOKENS.text.secondary, marginLeft: 8 }}>
          Per BR-501: main window hidden · single Stop action · no timer, waveform, or settings on the HUD.
        </span>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, flex: 1 }}>
        {/* DES-105 Notch */}
        <HudPanel
          kind="DES-105"
          label="Notch HUD"
          badge="MacBook Pro 14″/16″ · 2021+"
          hardware="NSPanel at .statusBar + 1 · clamps to notch geometry · stays above fullscreen meeting apps."
          notes="Single Stop action. Red dot oscillates at 1Hz to confirm liveness without demanding attention."
          states={
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <StateLabel>Collapsed · default during recording</StateLabel>
                <DesktopWallpaper>
                  <NotchMenuBar recording />
                  <MeetingBackdrop />
                </DesktopWallpaper>
              </div>
              <div>
                <StateLabel>Expanded · on hover / single click</StateLabel>
                <DesktopWallpaper>
                  <NotchMenuBar recording hover />
                  <MeetingBackdrop />
                </DesktopWallpaper>
              </div>
            </div>
          }
        />

        {/* DES-106 Menu Bar Extra */}
        <HudPanel
          kind="DES-106"
          label="Menu Bar Extra"
          badge="Non-notch Macs · also the safety net (RISK-008)"
          hardware="NSStatusItem in the system menu bar · NSPopover on click · macOS guarantees this stays above fullscreen apps."
          notes="Peer of DES-105, not a degraded fallback — same red dot, same single Stop action, same liveness oscillation."
          states={
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <StateLabel>Status item · always visible during recording</StateLabel>
                <DesktopWallpaper>
                  <PlainMenuBar recording />
                  <MeetingBackdrop />
                </DesktopWallpaper>
              </div>
              <div>
                <StateLabel>Popover · on click</StateLabel>
                <DesktopWallpaper>
                  <PlainMenuBar recording popover />
                  <MeetingBackdrop />
                </DesktopWallpaper>
              </div>
            </div>
          }
        />
      </div>
    </div>
  );
}

window.ScreenSCR002 = ScreenSCR002;
window.NotchMenuBar = NotchMenuBar;
window.PlainMenuBar = PlainMenuBar;
window.MeetingBackdrop = MeetingBackdrop;
window.DesktopWallpaper = DesktopWallpaper;
