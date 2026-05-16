// Design token sheet — DES-301..305

function Swatch({ color, name, hex, big = false, rec = false }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8, width: big ? 200 : 132, fontFamily: FONT_UI }}>
      <div style={{
        width: '100%', height: big ? 100 : 72,
        background: color,
        borderRadius: 8,
        border: `0.5px solid ${TOKENS.border.default}`,
        position: 'relative',
      }}>
        {rec && (
          <div style={{
            position: 'absolute', top: 8, right: 8,
            padding: '2px 6px',
            background: 'rgba(0,0,0,0.5)',
            borderRadius: 4,
            fontSize: 9, fontFamily: FONT_MONO,
            color: '#fff', fontWeight: 600,
          }}>DES-001 only</div>
        )}
      </div>
      <div>
        <div style={{ fontSize: 11, color: TOKENS.text.primary, fontWeight: 500 }}>{name}</div>
        <div style={{ fontSize: 10, color: TOKENS.text.muted, fontFamily: FONT_MONO, marginTop: 2 }}>{hex}</div>
      </div>
    </div>
  );
}

function TokenSection({ title, sub, children, span = 'auto' }) {
  return (
    <div style={{
      gridColumn: span,
      background: TOKENS.bg.secondary,
      border: `0.5px solid ${TOKENS.border.default}`,
      borderRadius: 12,
      padding: 24,
      display: 'flex', flexDirection: 'column', gap: 16,
    }}>
      <div>
        <div style={{ fontSize: 11, color: TOKENS.accent.primary, fontFamily: FONT_MONO, letterSpacing: 0.6, marginBottom: 6 }}>{title}</div>
        <div style={{ fontSize: 12, color: TOKENS.text.secondary, lineHeight: 1.5 }}>{sub}</div>
      </div>
      {children}
    </div>
  );
}

function TypeRow({ size, name, weight, family, sample }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'baseline', gap: 16,
      padding: '10px 0',
      borderBottom: `0.5px solid ${TOKENS.border.subtle}`,
    }}>
      <div style={{ width: 110, flexShrink: 0 }}>
        <div style={{ fontSize: 11, color: TOKENS.text.primary, fontFamily: FONT_MONO, fontWeight: 600 }}>{name}</div>
        <div style={{ fontSize: 10, color: TOKENS.text.muted, fontFamily: FONT_MONO, marginTop: 2 }}>{size}px · {weight}</div>
      </div>
      <div style={{
        flex: 1,
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        color: TOKENS.text.primary,
        lineHeight: 1.2,
        whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
      }}>{sample}</div>
    </div>
  );
}

function SpacingRow({ label, value, px }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 0', borderBottom: `0.5px solid ${TOKENS.border.subtle}` }}>
      <div style={{ width: 60, fontSize: 11, color: TOKENS.text.primary, fontFamily: FONT_MONO }}>{label}</div>
      <div style={{ width: 56, fontSize: 11, color: TOKENS.text.secondary, fontFamily: FONT_MONO }}>{px}px</div>
      <div style={{ flex: 1, height: 14, display: 'flex', alignItems: 'center' }}>
        <div style={{ height: 14, width: value, background: TOKENS.accent.primary, opacity: 0.6, borderRadius: 2 }} />
      </div>
    </div>
  );
}

function TokenSheet({ width = 1640, height = 1320 }) {
  return (
    <div style={{
      width, height,
      background: TOKENS.bg.primary,
      padding: 36,
      fontFamily: FONT_UI,
      color: TOKENS.text.primary,
      boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column', gap: 18,
    }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 16, justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 11, color: TOKENS.accent.primary, fontFamily: FONT_MONO, letterSpacing: 0.6 }}>DES-301 · DES-302 · DES-303 · DES-304 · DES-305</div>
          <div style={{ fontSize: 26, fontWeight: 600, marginTop: 6 }}>Design tokens · Transcript Shadow</div>
          <div style={{ fontSize: 13, color: TOKENS.text.secondary, marginTop: 4 }}>Dark only · ElevenLabs energy in an Obsidian frame · SF Pro + SF Mono · 4px base.</div>
        </div>
        <div style={{ fontSize: 11, color: TOKENS.text.muted, fontFamily: FONT_MONO }}>v2.1 · {new Date().toISOString().slice(0,10)}</div>
      </div>

      <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1.4fr 1fr', gridTemplateRows: 'auto auto auto', gap: 18, minHeight: 0 }}>
        {/* Color — span two rows */}
        <div style={{ gridRow: '1 / span 2' }}>
          <TokenSection
            title="DES-301 · Color palette"
            sub="Background hierarchy, teal accent, exclusive recording red, six muted speaker pastels."
          >
            <div>
              <div style={{ fontSize: 10, color: TOKENS.text.muted, fontFamily: FONT_MONO, textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 10 }}>Background</div>
              <div style={{ display: 'flex', gap: 12 }}>
                <Swatch color={TOKENS.bg.primary} name="bg / primary" hex="#0A0A0B" />
                <Swatch color={TOKENS.bg.secondary} name="bg / secondary" hex="#141415" />
                <Swatch color={TOKENS.bg.tertiary} name="bg / tertiary" hex="#1A1A1C" />
                <Swatch color={TOKENS.border.default} name="border" hex="#1E1E20" />
                <Swatch color={TOKENS.border.subtle} name="border / subtle" hex="#161618" />
              </div>
            </div>

            <div>
              <div style={{ fontSize: 10, color: TOKENS.text.muted, fontFamily: FONT_MONO, textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 10 }}>Accent</div>
              <div style={{ display: 'flex', gap: 12 }}>
                <Swatch color={TOKENS.accent.primary} name="accent / teal" hex="#2DD4BF" big />
                <Swatch color={TOKENS.accent.primaryHover} name="accent / hover" hex="#14B8A6" />
                <Swatch color={TOKENS.accent.rec} name="recording red" hex="#EF4444" big rec />
              </div>
            </div>

            <div>
              <div style={{ fontSize: 10, color: TOKENS.text.muted, fontFamily: FONT_MONO, textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 10 }}>Speakers · muted pastels</div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 10 }}>
                {TOKENS.speakers.map((c, i) => (
                  <div key={i} style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                    <div style={{ height: 56, background: c, borderRadius: 6 }} />
                    <div style={{
                      display: 'inline-flex', alignItems: 'center', gap: 5,
                      padding: '3px 8px', borderRadius: 999,
                      background: `${c}1a`, color: c,
                      fontSize: 10.5, fontWeight: 500, alignSelf: 'flex-start',
                    }}>
                      <span style={{ width: 5, height: 5, borderRadius: '50%', background: c }} />
                      Speaker {i + 1}
                    </div>
                    <div style={{ fontSize: 9.5, color: TOKENS.text.muted, fontFamily: FONT_MONO }}>{c}</div>
                  </div>
                ))}
              </div>
            </div>

            <div>
              <div style={{ fontSize: 10, color: TOKENS.text.muted, fontFamily: FONT_MONO, textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 10 }}>Status · DES-305</div>
              <div style={{ display: 'flex', gap: 12 }}>
                {[
                  ['Success', TOKENS.status.success, '#22C55E'],
                  ['Warning', TOKENS.status.warning, '#F59E0B'],
                  ['Error',   TOKENS.status.error,   '#EF4444'],
                  ['Info',    TOKENS.status.info,    '#3B82F6'],
                  ['Muted',   TOKENS.status.muted,   '#52525B'],
                ].map(([n, c, h]) => (
                  <div key={n} style={{ display: 'flex', flexDirection: 'column', gap: 6, width: 96 }}>
                    <div style={{ height: 38, background: c, borderRadius: 6 }} />
                    <div style={{ fontSize: 10.5, color: TOKENS.text.primary, fontWeight: 500 }}>{n}</div>
                    <div style={{ fontSize: 9.5, color: TOKENS.text.muted, fontFamily: FONT_MONO, marginTop: -4 }}>{h}</div>
                  </div>
                ))}
              </div>
            </div>
          </TokenSection>
        </div>

        {/* Typography */}
        <TokenSection title="DES-302 · Typography" sub="SF Pro for UI · SF Mono for timestamps, durations, technical metadata.">
          <TypeRow size={24} name="XL"   weight={600} family={FONT_UI}   sample="Q3 Planning · Eng + Design" />
          <TypeRow size={20} name="LG"   weight={600} family={FONT_UI}   sample="Identifying speakers…" />
          <TypeRow size={16} name="MD"   weight={500} family={FONT_UI}   sample="Speaker labels on a transcript turn" />
          <TypeRow size={14} name="Base" weight={400} family={FONT_UI}   sample="Body text, default transcript size, set+forget" />
          <TypeRow size={12} name="SM"   weight={500} family={FONT_UI}   sample="Sidebar items · speaker pills" />
          <TypeRow size={11} name="XS"   weight={500} family={FONT_MONO} sample="[00:01:24]  47:12  ⌘E  shadow.sidecar" />
        </TokenSection>

        {/* Spacing + Borders/Elevation */}
        <TokenSection title="DES-303 · Spacing scale · 4px base" sub="Two modes: spacious (idle / processing / settings) and dense (transcript / sidebar).">
          {[
            ['4',  4,  '4'],
            ['8',  8,  '8'],
            ['12', 12, '12'],
            ['16', 16, '16'],
            ['24', 24, '24'],
            ['32', 32, '32'],
            ['48', 48, '48'],
            ['64', 64, '64'],
          ].map(([l, v, px]) => <SpacingRow key={l} label={`step-${l}`} value={v} px={px} />)}
          <div style={{ display: 'flex', gap: 12, marginTop: 4 }}>
            <div style={{
              flex: 1,
              padding: 12,
              background: TOKENS.bg.tertiary,
              border: `0.5px solid ${TOKENS.border.default}`,
              borderRadius: 8,
            }}>
              <div style={{ fontSize: 10, color: TOKENS.text.muted, fontFamily: FONT_MONO, textTransform: 'uppercase', marginBottom: 6 }}>Spacious</div>
              <div style={{ fontSize: 11.5, color: TOKENS.text.secondary, lineHeight: 1.55 }}>600px content · 48px section padding · 24-32px element gap</div>
            </div>
            <div style={{
              flex: 1,
              padding: 12,
              background: TOKENS.bg.tertiary,
              border: `0.5px solid ${TOKENS.border.default}`,
              borderRadius: 8,
            }}>
              <div style={{ fontSize: 10, color: TOKENS.text.muted, fontFamily: FONT_MONO, textTransform: 'uppercase', marginBottom: 6 }}>Dense</div>
              <div style={{ fontSize: 11.5, color: TOKENS.text.secondary, lineHeight: 1.55 }}>Full width · 16px section padding · 8-12px block gap · 1.5 line-height</div>
            </div>
          </div>
        </TokenSection>

        {/* Borders / Elevation / Radii */}
        <TokenSection title="DES-304 · Radii · borders · vibrancy" sub="Continuous corners following macOS HIG · NSVisualEffectView on sidebar + HUD.">
          <div style={{ display: 'flex', gap: 12 }}>
            {[
              ['button', 6,  '6px'],
              ['card',   10, '10px'],
              ['pill',   12, '12px'],
              ['panel',  14, '14px'],
            ].map(([n, r, hex]) => (
              <div key={n} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
                <div style={{
                  width: 64, height: 64,
                  background: TOKENS.bg.tertiary,
                  borderRadius: r,
                  border: `0.5px solid ${TOKENS.border.default}`,
                }} />
                <div style={{ fontSize: 11, color: TOKENS.text.primary, fontWeight: 500 }}>{n}</div>
                <div style={{ fontSize: 10, color: TOKENS.text.muted, fontFamily: FONT_MONO, marginTop: -4 }}>radius {hex}</div>
              </div>
            ))}
          </div>
          <div style={{
            padding: 14,
            background: 'linear-gradient(135deg, rgba(45,212,191,0.04), rgba(20,20,21,0.6))',
            backdropFilter: 'blur(20px)',
            border: `0.5px solid ${TOKENS.border.default}`,
            borderRadius: 10,
          }}>
            <div style={{ fontSize: 11, color: TOKENS.text.primary, fontWeight: 600, marginBottom: 4 }}>Sidebar vibrancy</div>
            <div style={{ fontSize: 11, color: TOKENS.text.secondary, lineHeight: 1.55 }}>
              NSVisualEffectView · <span style={{ fontFamily: FONT_MONO, color: TOKENS.text.primary }}>.sidebar</span> material in DES-004 · <span style={{ fontFamily: FONT_MONO, color: TOKENS.text.primary }}>.hudWindow</span> on DES-105. Opaque <span style={{ fontFamily: FONT_MONO, color: TOKENS.text.primary }}>#0A0A0B</span> on the content area.
            </div>
          </div>
          <div style={{
            padding: 14,
            background: TOKENS.bg.tertiary,
            border: `0.5px solid ${TOKENS.border.default}`,
            borderRadius: 10,
          }}>
            <div style={{ fontSize: 11, color: TOKENS.text.primary, fontWeight: 600, marginBottom: 4 }}>Borders</div>
            <div style={{ fontSize: 11, color: TOKENS.text.secondary, lineHeight: 1.55 }}>
              1px hairlines using <span style={{ fontFamily: FONT_MONO, color: TOKENS.text.primary }}>#1E1E20</span> for visible dividers, <span style={{ fontFamily: FONT_MONO, color: TOKENS.text.primary }}>#161618</span> for inner separators. No drop shadows on cards in dark mode.
            </div>
          </div>
        </TokenSection>
      </div>
    </div>
  );
}

window.TokenSheet = TokenSheet;
