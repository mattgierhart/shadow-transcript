// SCR-006 Transcript History — the sidebar (DES-004) is the screen.

function SidebarSearching({ query = 'pyannote' }) {
  // Filter mode: search query active, list condenses to matches.
  const matches = [
    { id: 't3', title: 'Pyannote sidecar review', dur: '32:55', speakers: 3, time: 'Wed 4:15 PM', hl: [0, 8] },
    { id: 't6', title: 'WhisperKit benchmark sync', dur: '21:33', speakers: 4, time: 'Mon 3:30 PM', note: 'pyannote 3.1 numbers' },
    { id: 't8', title: 'BR-501 design review', dur: '38:14', speakers: 4, time: 'May 9', note: 'pyannote sidecar discussion' },
  ];
  return (
    <div style={{
      width: 280, flexShrink: 0,
      background: TOKENS.bg.secondary,
      borderRight: `0.5px solid ${TOKENS.border.default}`,
      display: 'flex', flexDirection: 'column',
      fontFamily: FONT_UI,
    }}>
      <div style={{ padding: '12px 12px 8px' }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          height: 28,
          padding: '0 10px',
          background: TOKENS.bg.tertiary,
          border: `1px solid ${TOKENS.accent.primary}66`,
          boxShadow: `0 0 0 3px rgba(45,212,191,0.10)`,
          borderRadius: 6,
          fontSize: 12, color: TOKENS.text.primary,
        }}>
          <IconSearch color={TOKENS.accent.primary} />
          <span style={{ fontFamily: FONT_UI }}>{query}</span>
          <span style={{ width: 1.5, height: 12, background: TOKENS.accent.primary, animation: 'blink 1s steps(1) infinite' }} />
          <span style={{ marginLeft: 'auto', fontFamily: FONT_MONO, fontSize: 10, color: TOKENS.text.muted }}>3 matches</span>
        </div>
      </div>
      <div style={{ flex: 1, padding: '4px 8px', overflow: 'hidden' }}>
        <div style={{ fontSize: 10, fontWeight: 600, color: TOKENS.text.muted, textTransform: 'uppercase', letterSpacing: 0.6, padding: '8px 8px 4px' }}>
          Search · "{query}"
        </div>
        {matches.map((m, i) => {
          // Highlight matched substring
          const lower = m.title.toLowerCase();
          const q = query.toLowerCase();
          const idx = lower.indexOf(q);
          const before = idx >= 0 ? m.title.slice(0, idx) : m.title;
          const match = idx >= 0 ? m.title.slice(idx, idx + q.length) : '';
          const after = idx >= 0 ? m.title.slice(idx + q.length) : '';
          return (
            <div key={m.id} style={{
              padding: '10px 10px',
              borderRadius: 6,
              marginBottom: 2,
              background: i === 0 ? 'rgba(45,212,191,0.10)' : 'transparent',
              borderLeft: i === 0 ? `2px solid ${TOKENS.accent.primary}` : '2px solid transparent',
              paddingLeft: i === 0 ? 8 : 10,
            }}>
              <div style={{ fontSize: 12.5, fontWeight: 500, lineHeight: 1.3 }}>
                {before}
                <span style={{
                  background: 'rgba(45,212,191,0.25)',
                  color: TOKENS.text.primary,
                  borderRadius: 2,
                  padding: '0 1px',
                }}>{match}</span>
                {after}
              </div>
              {m.note && (
                <div style={{ fontSize: 10.5, color: TOKENS.text.secondary, marginTop: 3, lineHeight: 1.4 }}>
                  …{m.note}…
                </div>
              )}
              <div style={{ fontSize: 10.5, color: TOKENS.text.secondary, fontFamily: FONT_MONO, marginTop: 4, display: 'flex', gap: 6 }}>
                <span>{m.time}</span>
                <span style={{ color: TOKENS.text.muted }}>·</span>
                <span>{m.dur}</span>
                <span style={{ marginLeft: 'auto', background: TOKENS.bg.tertiary, padding: '1px 5px', borderRadius: 4, fontSize: 9.5, color: TOKENS.text.secondary, fontFamily: FONT_UI }}>{m.speakers}</span>
              </div>
            </div>
          );
        })}
      </div>
      <div style={{
        padding: '10px 14px',
        borderTop: `0.5px solid ${TOKENS.border.default}`,
        fontSize: 10.5, color: TOKENS.text.muted, fontFamily: FONT_MONO,
        display: 'flex', justifyContent: 'space-between',
      }}>
        <span>9 transcripts · local</span>
        <span style={{ color: TOKENS.status.success }}>● ready</span>
      </div>
    </div>
  );
}

function ContextMenu({ x, y }) {
  const items = [
    { label: 'Open', sub: 'Return' },
    { label: 'Open in new window', sub: '⌘↩' },
    { divider: true },
    { label: 'Export to Obsidian', sub: '⌘E' },
    { label: 'Copy markdown', sub: '⌘C' },
    { label: 'Reveal in Finder', sub: null },
    { label: 'Rename…', sub: null },
    { divider: true },
    { label: 'Delete transcript…', sub: '⌘⌫', destructive: true },
  ];
  return (
    <div style={{
      position: 'absolute', top: y, left: x,
      width: 220,
      background: 'rgba(38,38,40,0.96)',
      backdropFilter: 'blur(24px)',
      border: '0.5px solid rgba(255,255,255,0.10)',
      borderRadius: 8,
      boxShadow: '0 16px 40px rgba(0,0,0,0.55)',
      padding: '4px 0',
      fontFamily: FONT_UI,
      zIndex: 10,
    }}>
      {items.map((it, i) => it.divider ? (
        <div key={i} style={{ height: 0.5, background: 'rgba(255,255,255,0.08)', margin: '4px 0' }} />
      ) : (
        <div key={i} style={{
          display: 'flex', alignItems: 'center', gap: 12,
          padding: '4px 12px',
          fontSize: 12.5,
          color: it.destructive ? '#ff6b6b' : '#f5f5f5',
        }}>
          <span style={{ flex: 1 }}>{it.label}</span>
          {it.sub && <span style={{ fontFamily: FONT_MONO, fontSize: 10.5, color: 'rgba(245,245,245,0.5)' }}>{it.sub}</span>}
        </div>
      ))}
    </div>
  );
}

function ScreenSCR006({ width = 1100, height = 700 }) {
  // Show the main window with the sidebar prominent (SCR-006 IS the sidebar)
  // with a context menu open on one of the items.
  return (
    <div style={{ width, height, position: 'relative' }}>
      <MacWindow width={width} height={height} title="Transcript Shadow" toolbarRight={<><IconSidebar /><IconGear /></>}>
        <SidebarSearching query="pyannote" />
        <div style={{
          flex: 1, background: TOKENS.bg.primary,
          display: 'flex', flexDirection: 'column',
          padding: 48,
          alignItems: 'center', justifyContent: 'center',
          textAlign: 'center',
        }}>
          <div style={{ maxWidth: 380 }}>
            <div style={{
              width: 64, height: 64, borderRadius: 16,
              background: TOKENS.bg.secondary,
              border: `0.5px solid ${TOKENS.border.default}`,
              margin: '0 auto 20px',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <IconSearch size={24} color={TOKENS.text.secondary} />
            </div>
            <div style={{ fontSize: 16, fontWeight: 600, color: TOKENS.text.primary, marginBottom: 8 }}>
              Searching transcripts
            </div>
            <div style={{ fontSize: 12.5, color: TOKENS.text.secondary, lineHeight: 1.5 }}>
              Full-text search runs against the local FTS index in <span style={{ fontFamily: FONT_MONO, color: TOKENS.text.primary }}>transcripts.sqlite</span>. Pick a result on the left to open it here.
            </div>
            <div style={{
              marginTop: 24, display: 'flex', gap: 8, justifyContent: 'center',
              fontSize: 10.5, color: TOKENS.text.muted, fontFamily: FONT_MONO,
            }}>
              <span>⌘F</span><span>focus search</span>
              <span style={{ color: TOKENS.text.muted }}>·</span>
              <span>⌘\</span><span>collapse sidebar</span>
              <span style={{ color: TOKENS.text.muted }}>·</span>
              <span>↑↓</span><span>navigate</span>
            </div>
          </div>
        </div>
      </MacWindow>
      {/* Right-click context menu over the first match */}
      <ContextMenu x={150} y={185} />
      {/* Arrow line pointing to the menu */}
    </div>
  );
}

window.ScreenSCR006 = ScreenSCR006;
window.SidebarSearching = SidebarSearching;
window.ContextMenu = ContextMenu;
