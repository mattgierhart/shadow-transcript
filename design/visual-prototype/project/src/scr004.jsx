// SCR-004 Transcript View — Money Shot
// Dense, full-width. Metadata header → speaker summary → transcript blocks → action bar.

const SPEAKERS_004 = [
  { id: 0, name: 'Lena Ortiz',  role: 'Eng lead',   time: '14:08', share: 30 },
  { id: 1, name: 'Marc Schuler', role: 'Design',     time: '09:42', share: 21 },
  { id: 2, name: 'Priya Iyer',  role: 'PM',         time: '11:31', share: 25 },
  { id: 3, name: 'You',          role: '',           time: '07:54', share: 17 },
  { id: 4, name: 'Speaker 5',    role: 'unlabeled',  time: '03:57', share: 8, unlabeled: true },
];

const TRANSCRIPT_004 = [
  { spk: 2, t: '00:00:04', text: 'Okay, last Q3 planning before we lock the roadmap. I want to spend most of our hour on three things: the diarization SLA, the export pipeline, and whether we keep the notch HUD as the primary surface or demote it.' },
  { spk: 0, t: '00:00:22', text: 'Demote it to what — Menu Bar Extra as primary? We agreed last week those are peers. BR-501 doesn\'t care which surface, only that there\'s a single Stop button and the main window is hidden.' },
  { spk: 1, t: '00:00:41', text: 'Right, but if the notch HUD can\'t reliably sit above fullscreen Zoom, we\'ve got a screen the user can\'t see. RISK-008 is the question, not the design.' },
  { spk: 2, t: '00:00:55', text: 'Lena, where did the .statusBar + 1 prototype land?' },
  { spk: 0, t: '00:01:02', text: 'Holds on macOS 14 and 15 in every meeting app we tested. Teams in fullscreen was the one that worried me — it\'s fine. NSPanel with the non-activating + can-be-visible-on-all-spaces flags, level above the menu bar.' },
  { spk: 3, t: '00:01:24', text: 'Good. Then I think we ship both surfaces as peers and stop talking about it. The risk doc said promote DES-106 if 105 breaks; it didn\'t break.' },
  { spk: 2, t: '00:01:39', text: 'Agreed. Marc, the expanded notch panel — you locked the width at 280?' },
  { spk: 1, t: '00:01:47', text: 'Yeah, 280pt expanded, 36pt tall. Red dot, "Recording" label, full-height Stop button. The dot oscillates at 1Hz — Lena measured the WhisperKit memory at ~340MB so there\'s headroom for the animation.' },
  { spk: 4, t: '00:02:08', text: 'Quick question on the popover — does that follow the same 1Hz oscillation for the dot?' },
  { spk: 1, t: '00:02:14', text: 'Same oscillation, same red, same Stop layout. Peers means peers — visual parity is the whole point. If the menu bar version looks like the consolation prize, we\'ve failed the brief.' },
  { spk: 0, t: '00:02:31', text: 'On the diarization SLA — pyannote sidecar is averaging 0.18× real-time on M2 Pro. Forty-five minute meeting processes in about eight minutes end-to-end including Whisper.' },
  { spk: 2, t: '00:02:50', text: 'That\'s well under our ten-minute target. PER-001 is the meeting-and-go user; they aren\'t watching the pipeline.' },
  { spk: 3, t: '00:03:02', text: 'Speaker rename has to be instant, though. That was the loudest piece of feedback from the design interview — they want to fix the labels once and have the whole transcript update.' },
  { spk: 0, t: '00:03:18', text: 'Already wired through. DBT-001 stores speaker_label as a nullable override; the transcript view binds to it. Rename propagates in the same render pass.' },
];

function MetadataHeader() {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 16,
      padding: '14px 24px',
      borderBottom: `0.5px solid ${TOKENS.border.default}`,
      background: TOKENS.bg.primary,
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 16, fontWeight: 600, color: TOKENS.text.primary, marginBottom: 4 }}>
          Q3 Planning · Eng + Design
        </div>
        <div style={{ display: 'flex', gap: 14, fontSize: 11.5, color: TOKENS.text.secondary, fontFamily: FONT_MONO }}>
          <span>Thu May 16 · 11:00 AM</span>
          <span style={{ color: TOKENS.text.muted }}>·</span>
          <span>47:12 duration</span>
          <span style={{ color: TOKENS.text.muted }}>·</span>
          <span>5 speakers</span>
          <span style={{ color: TOKENS.text.muted }}>·</span>
          <span>whisper:small.en · pyannote:3.1</span>
          <span style={{ color: TOKENS.text.muted }}>·</span>
          <span style={{ color: TOKENS.status.success }}>● local</span>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
        <ToolbarButton label="Copy" sub="⌘C" />
        <ToolbarButton label="Save as…" sub="⌘S" />
        <ExportButton />
      </div>
    </div>
  );
}

function ToolbarButton({ label, sub, primary = false }) {
  return (
    <button style={{
      display: 'inline-flex', alignItems: 'center', gap: 8,
      padding: '7px 12px',
      background: primary ? TOKENS.accent.primary : 'transparent',
      color: primary ? '#06281f' : TOKENS.text.primary,
      border: primary ? 'none' : `0.5px solid ${TOKENS.border.default}`,
      borderRadius: 7,
      fontSize: 12, fontWeight: primary ? 600 : 500,
      fontFamily: FONT_UI,
      cursor: 'pointer',
    }}>
      {label}
      {sub && <span style={{ fontSize: 10, color: primary ? 'rgba(6,40,31,0.6)' : TOKENS.text.muted, fontFamily: FONT_MONO }}>{sub}</span>}
    </button>
  );
}

function ExportButton() {
  return (
    <button style={{
      display: 'inline-flex', alignItems: 'center', gap: 8,
      padding: '7px 14px',
      background: TOKENS.accent.primary,
      color: '#06281f',
      border: 'none',
      borderRadius: 7,
      fontSize: 12.5, fontWeight: 600,
      fontFamily: FONT_UI,
      cursor: 'pointer',
      boxShadow: `0 0 0 0.5px rgba(255,255,255,0.1) inset, 0 4px 16px rgba(45,212,191,0.20)`,
    }}>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#06281f" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
        <polyline points="7 10 12 15 17 10"/>
        <line x1="12" y1="15" x2="12" y2="3"/>
      </svg>
      Export to Obsidian
      <span style={{ fontSize: 10.5, opacity: 0.6, fontFamily: FONT_MONO }}>⌘E</span>
    </button>
  );
}

function SpeakerSummary({ editingId = null }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '12px 24px 14px',
      borderBottom: `0.5px solid ${TOKENS.border.default}`,
      background: TOKENS.bg.primary,
      overflow: 'hidden',
    }}>
      <div style={{
        fontSize: 10, color: TOKENS.text.muted, fontFamily: FONT_MONO,
        textTransform: 'uppercase', letterSpacing: 0.6, marginRight: 6,
        flexShrink: 0,
      }}>Speakers</div>
      <div style={{ display: 'flex', gap: 8, flex: 1, flexWrap: 'wrap' }}>
        {SPEAKERS_004.map((s, i) => (
          <SpeakerPill
            key={s.id}
            name={s.unlabeled ? 'Speaker 5' : s.name}
            colorIdx={i}
            time={s.time}
            editing={editingId === s.id}
            size="lg"
          />
        ))}
      </div>
      <div style={{ fontSize: 10.5, color: TOKENS.text.muted, fontFamily: FONT_MONO, flexShrink: 0 }}>click a pill to rename</div>
    </div>
  );
}

function SpeakerShareBar() {
  return (
    <div style={{
      display: 'flex', alignItems: 'center',
      height: 6,
      borderRadius: 999, overflow: 'hidden',
      margin: '0 24px',
      background: TOKENS.bg.tertiary,
    }}>
      {SPEAKERS_004.map((s, i) => (
        <div key={s.id} style={{
          width: `${s.share}%`,
          height: '100%',
          background: TOKENS.speakers[i % TOKENS.speakers.length],
          opacity: 0.85,
        }} />
      ))}
    </div>
  );
}

function TranscriptBlock({ block }) {
  const speaker = SPEAKERS_004[block.spk];
  const color = TOKENS.speakers[block.spk % TOKENS.speakers.length];
  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: '160px 1fr',
      gap: 24,
      padding: '10px 24px',
      borderLeft: '2px solid transparent',
      transition: 'background 0.15s',
    }}>
      {/* Left column: speaker + timestamp */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 6, paddingTop: 2 }}>
        <SpeakerPill name={speaker.unlabeled ? 'Speaker 5' : speaker.name} colorIdx={block.spk} />
        <span style={{ fontSize: 10.5, color: TOKENS.text.muted, fontFamily: FONT_MONO, paddingLeft: 4 }}>{block.t}</span>
      </div>
      {/* Right column: text */}
      <div style={{
        fontSize: 14.5, lineHeight: 1.55,
        color: TOKENS.text.primary,
        fontFamily: FONT_UI,
        paddingTop: 4,
        textWrap: 'pretty',
        borderLeft: `2px solid ${color}33`,
        paddingLeft: 16,
      }}>
        {block.text}
      </div>
    </div>
  );
}

function ScreenSCR004({ width = 1440, height = 900 }) {
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
      <Sidebar selected="t1" />
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        background: TOKENS.bg.primary,
        minWidth: 0,
      }}>
        <MetadataHeader />
        <SpeakerSummary />
        <div style={{ padding: '10px 0 6px' }}>
          <SpeakerShareBar />
          <div style={{
            margin: '6px 24px 0',
            display: 'flex', justifyContent: 'space-between',
            fontSize: 10, color: TOKENS.text.muted, fontFamily: FONT_MONO,
          }}>
            <span>00:00</span>
            <span>share of voice</span>
            <span>47:12</span>
          </div>
        </div>

        {/* Transcript scroll area */}
        <div style={{
          flex: 1, minHeight: 0, overflow: 'hidden',
          paddingTop: 8, paddingBottom: 8,
          background: TOKENS.bg.primary,
          position: 'relative',
        }}>
          {TRANSCRIPT_004.map((b, i) => (
            <TranscriptBlock key={i} block={b} />
          ))}
          {/* Bottom fade */}
          <div style={{
            position: 'absolute', bottom: 0, left: 0, right: 0, height: 80,
            background: `linear-gradient(180deg, transparent, ${TOKENS.bg.primary})`,
            pointerEvents: 'none',
          }} />
        </div>

        {/* Status footer */}
        <div style={{
          height: 30, padding: '0 24px',
          borderTop: `0.5px solid ${TOKENS.border.default}`,
          background: TOKENS.bg.secondary,
          display: 'flex', alignItems: 'center', gap: 16,
          fontSize: 10.5, color: TOKENS.text.muted, fontFamily: FONT_MONO,
        }}>
          <span>14 turns · 1,842 words</span>
          <span>·</span>
          <span>~markdown · 6.4 KB</span>
          <span style={{ flex: 1 }} />
          <span style={{ color: TOKENS.status.success }}>● audio deleted at 11:50:04</span>
        </div>
      </div>
    </MacWindow>
  );
}

window.ScreenSCR004 = ScreenSCR004;
window.SPEAKERS_004 = SPEAKERS_004;
window.TRANSCRIPT_004 = TRANSCRIPT_004;
