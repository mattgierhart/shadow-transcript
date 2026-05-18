// Shared chrome: macOS window, traffic lights, sidebar, toolbar, transcript blocks.

function TrafficLights({ inactive = false }) {
  const dot = {
    width: 12, height: 12, borderRadius: '50%',
    display: 'inline-block',
  };
  if (inactive) {
    return (
      <div style={{ display: 'flex', gap: 8 }}>
        <span style={{ ...dot, background: '#3a3a3c' }} />
        <span style={{ ...dot, background: '#3a3a3c' }} />
        <span style={{ ...dot, background: '#3a3a3c' }} />
      </div>
    );
  }
  return (
    <div style={{ display: 'flex', gap: 8 }}>
      <span style={{ ...dot, background: '#FF5F57', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.25)' }} />
      <span style={{ ...dot, background: '#FEBC2E', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.25)' }} />
      <span style={{ ...dot, background: '#28C840', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.25)' }} />
    </div>
  );
}

// macOS-style window shell with toolbar + traffic lights.
function MacWindow({ width, height, title, children, toolbarRight, recording, processing, hideMain, sidebarBg }) {
  return (
    <div style={{
      width, height,
      background: TOKENS.bg.primary,
      borderRadius: 10,
      overflow: 'hidden',
      boxShadow: '0 24px 80px rgba(0,0,0,0.6), 0 0 0 0.5px rgba(255,255,255,0.06)',
      color: TOKENS.text.primary,
      fontFamily: FONT_UI,
      display: 'flex',
      flexDirection: 'column',
      position: 'relative',
      opacity: hideMain ? 0 : 1,
    }}>
      {/* Title bar / toolbar */}
      <div style={{
        height: 44,
        display: 'flex', alignItems: 'center',
        padding: '0 16px',
        background: sidebarBg || 'linear-gradient(180deg,#1a1a1c 0%, #161618 100%)',
        borderBottom: `0.5px solid ${TOKENS.border.default}`,
        gap: 16,
        flexShrink: 0,
      }}>
        <TrafficLights />
        <div style={{ flex: 1, textAlign: 'center', fontSize: 12, color: TOKENS.text.secondary, fontWeight: 500, letterSpacing: 0.1 }}>
          {recording ? <RecordingPill /> : processing ? <ProcessingPill /> : title}
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center', minWidth: 56, justifyContent: 'flex-end' }}>
          {toolbarRight}
        </div>
      </div>
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>{children}</div>
    </div>
  );
}

function RecordingPill() {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 8,
      fontSize: 12, color: TOKENS.text.secondary, fontWeight: 500,
    }}>
      <span style={{ width: 8, height: 8, borderRadius: '50%', background: TOKENS.accent.rec, boxShadow: `0 0 8px ${TOKENS.accent.rec}` }} />
      Recording • shadowed
    </span>
  );
}

function ProcessingPill() {
  return (
    <span style={{ fontSize: 12, color: TOKENS.text.secondary, fontWeight: 500 }}>
      Processing transcript…
    </span>
  );
}

function IconGear({ size = 16, color = TOKENS.text.secondary }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.6 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9c.39.07.78.18 1 .51H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
    </svg>
  );
}

function IconSidebar({ size = 16, color = TOKENS.text.secondary }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="18" height="16" rx="2" />
      <line x1="9" y1="4" x2="9" y2="20" />
    </svg>
  );
}

function IconSearch({ size = 13, color = TOKENS.text.muted }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="7" />
      <line x1="21" y1="21" x2="16.65" y2="16.65" />
    </svg>
  );
}

function IconMic({ size = 14, color = TOKENS.text.secondary, active = false }) {
  const c = active ? TOKENS.accent.primary : color;
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <rect x="9" y="3" width="6" height="11" rx="3" />
      <path d="M5 11a7 7 0 0 0 14 0" />
      <line x1="12" y1="18" x2="12" y2="21" />
    </svg>
  );
}

function IconSpeakerWave({ size = 14, color = TOKENS.text.secondary, active = false }) {
  const c = active ? TOKENS.accent.primary : color;
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" />
      <path d="M15.54 8.46a5 5 0 0 1 0 7.07" />
      <path d="M19.07 4.93a10 10 0 0 1 0 14.14" />
    </svg>
  );
}

function Sidebar({ width = 240, selected = null, dense, density = 'dense' }) {
  // Sample transcripts grouped
  const groups = [
    {
      label: 'Today',
      items: [
        { id: 't1', title: 'Q3 Planning · Eng + Design', dur: '47:12', speakers: 5, time: '11:00 AM' },
        { id: 't2', title: 'Daily standup', dur: '14:08', speakers: 4, time: '9:30 AM' },
      ],
    },
    {
      label: 'Yesterday',
      items: [
        { id: 't3', title: 'Pyannote sidecar review', dur: '32:55', speakers: 3, time: 'Wed 4:15 PM' },
        { id: 't4', title: '1:1 with Priya', dur: '28:40', speakers: 2, time: 'Wed 2:00 PM' },
      ],
    },
    {
      label: 'This Week',
      items: [
        { id: 't5', title: 'Customer interview · Acme', dur: '52:01', speakers: 3, time: 'Tue 10:00 AM' },
        { id: 't6', title: 'WhisperKit benchmark sync', dur: '21:33', speakers: 4, time: 'Mon 3:30 PM' },
        { id: 't7', title: 'Roadmap rough-cut', dur: '1:04:22', speakers: 6, time: 'Mon 11:00 AM' },
      ],
    },
    {
      label: 'Older',
      items: [
        { id: 't8', title: 'BR-501 design review', dur: '38:14', speakers: 4, time: 'May 9' },
        { id: 't9', title: 'Series A prep · legal', dur: '46:50', speakers: 3, time: 'May 7' },
      ],
    },
  ];

  return (
    <div style={{
      width, flexShrink: 0,
      background: TOKENS.bg.secondary,
      borderRight: `0.5px solid ${TOKENS.border.default}`,
      display: 'flex', flexDirection: 'column',
      fontFamily: FONT_UI,
    }}>
      {/* Search bar */}
      <div style={{ padding: '12px 12px 8px' }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          height: 28,
          padding: '0 10px',
          background: TOKENS.bg.tertiary,
          border: `0.5px solid ${TOKENS.border.default}`,
          borderRadius: 6,
          fontSize: 12,
          color: TOKENS.text.muted,
        }}>
          <IconSearch />
          <span>Search transcripts</span>
          <span style={{ marginLeft: 'auto', fontFamily: FONT_MONO, fontSize: 10, color: TOKENS.text.muted, opacity: 0.7 }}>⌘F</span>
        </div>
      </div>
      <div style={{ flex: 1, overflow: 'hidden', padding: '4px 8px' }}>
        {groups.map((g, gi) => (
          <div key={g.label} style={{ marginBottom: 10 }}>
            <div style={{
              fontSize: 10, fontWeight: 600, color: TOKENS.text.muted,
              textTransform: 'uppercase', letterSpacing: 0.6,
              padding: '8px 8px 4px',
            }}>{g.label}</div>
            {g.items.map((it) => {
              const isSelected = selected === it.id;
              return (
                <div key={it.id} style={{
                  padding: '8px 10px',
                  borderRadius: 6,
                  marginBottom: 1,
                  background: isSelected ? 'rgba(45,212,191,0.12)' : 'transparent',
                  borderLeft: isSelected ? `2px solid ${TOKENS.accent.primary}` : '2px solid transparent',
                  paddingLeft: isSelected ? 8 : 10,
                  cursor: 'pointer',
                }}>
                  <div style={{
                    fontSize: 12.5, fontWeight: isSelected ? 600 : 500,
                    color: isSelected ? TOKENS.text.primary : TOKENS.text.primary,
                    whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                    lineHeight: 1.3,
                  }}>{it.title}</div>
                  <div style={{
                    fontSize: 10.5, color: TOKENS.text.secondary,
                    fontFamily: FONT_MONO, marginTop: 3,
                    display: 'flex', gap: 6, alignItems: 'center',
                  }}>
                    <span>{it.time}</span>
                    <span style={{ color: TOKENS.text.muted }}>·</span>
                    <span>{it.dur}</span>
                    <span style={{
                      marginLeft: 'auto',
                      background: TOKENS.bg.tertiary,
                      padding: '1px 5px',
                      borderRadius: 4,
                      fontSize: 9.5,
                      color: TOKENS.text.secondary,
                      fontFamily: FONT_UI,
                    }}>{it.speakers}</span>
                  </div>
                </div>
              );
            })}
          </div>
        ))}
      </div>
      {/* Footer */}
      <div style={{
        padding: '10px 14px',
        borderTop: `0.5px solid ${TOKENS.border.default}`,
        fontSize: 10.5, color: TOKENS.text.muted,
        fontFamily: FONT_MONO,
        display: 'flex', justifyContent: 'space-between',
      }}>
        <span>9 transcripts · local</span>
        <span style={{ color: TOKENS.status.success }}>● ready</span>
      </div>
    </div>
  );
}

// Speaker pill (DES-101)
function SpeakerPill({ name, colorIdx = 0, time = null, active = false, editing = false, size = 'sm' }) {
  const color = TOKENS.speakers[colorIdx % TOKENS.speakers.length];
  const padV = size === 'lg' ? 5 : 3;
  const padH = size === 'lg' ? 12 : 10;
  const fontSize = size === 'lg' ? 12.5 : 11.5;
  if (editing) {
    return (
      <span style={{
        display: 'inline-flex', alignItems: 'center', gap: 6,
        padding: `${padV}px ${padH}px`,
        borderRadius: 999,
        background: 'rgba(45,212,191,0.10)',
        border: `1px solid ${TOKENS.accent.primary}`,
        color: TOKENS.text.primary,
        fontSize, fontWeight: 500,
        fontFamily: FONT_UI,
      }}>
        <span style={{ width: 6, height: 6, borderRadius: '50%', background: color }} />
        <span style={{ borderRight: `1px solid ${TOKENS.accent.primary}`, paddingRight: 4 }}>{name}</span>
        <span style={{ width: 1, height: 12, background: TOKENS.accent.primary, animation: 'blink 1s steps(1) infinite' }} />
      </span>
    );
  }
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: `${padV}px ${padH}px`,
      borderRadius: 999,
      background: `${color}1a`,
      color, fontSize, fontWeight: 500,
      fontFamily: FONT_UI,
      border: active ? `1px solid ${color}66` : '1px solid transparent',
    }}>
      <span style={{ width: 6, height: 6, borderRadius: '50%', background: color }} />
      {name}
      {time != null && <span style={{ color: TOKENS.text.secondary, fontFamily: FONT_MONO, fontSize: fontSize - 1, fontWeight: 400, marginLeft: 4 }}>{time}</span>}
    </span>
  );
}

window.MacWindow = MacWindow;
window.TrafficLights = TrafficLights;
window.Sidebar = Sidebar;
window.SpeakerPill = SpeakerPill;
window.IconGear = IconGear;
window.IconSidebar = IconSidebar;
window.IconSearch = IconSearch;
window.IconMic = IconMic;
window.IconSpeakerWave = IconSpeakerWave;
