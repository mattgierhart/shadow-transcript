// Design tokens lifted directly from SoT.DESIGN_COMPONENTS.md DES-301..305
const TOKENS = {
  bg: {
    primary: '#0A0A0B',
    secondary: '#141415',
    tertiary: '#1A1A1C',
  },
  accent: {
    primary: '#2DD4BF',
    primaryHover: '#14B8A6',
    rec: '#EF4444',
  },
  text: {
    primary: '#F5F5F5',
    secondary: '#A1A1AA',
    muted: '#52525B',
  },
  border: {
    default: '#1E1E20',
    subtle: '#161618',
  },
  speakers: [
    '#8BB8E8', // soft blue
    '#E8A87C', // soft coral
    '#82D9A5', // soft mint
    '#C4A0E8', // soft lavender
    '#E8D482', // soft gold
    '#E88B9C', // soft rose
  ],
  status: {
    success: '#22C55E',
    warning: '#F59E0B',
    error: '#EF4444',
    info: '#3B82F6',
    muted: '#52525B',
  },
};

const FONT_UI = '"SF Pro Display","SF Pro Text","Inter","Helvetica Neue",system-ui,-apple-system,sans-serif';
const FONT_MONO = '"SF Mono","JetBrains Mono","Menlo","Consolas",monospace';

window.TOKENS = TOKENS;
window.FONT_UI = FONT_UI;
window.FONT_MONO = FONT_MONO;
