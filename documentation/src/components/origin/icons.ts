import type { OriginLevel } from "./types";

// Two base glyphs (who held the pen) plus a small top-right accent (how much
// the other party did). The accent shrinks as the scale moves toward
// `ai-generated`: none, a check, a spark, then flips to the chip glyph with a
// pen mark, a check, and finally no accent at all.
const PERSON =
	'<circle cx="12" cy="8" r="3.5"/><path d="M5 20a7 7 0 0 1 14 0"/>';
const CHIP =
	'<rect x="5" y="9" width="11" height="11" rx="2"/><path d="M10.5 9V5M10.5 20v4M5 14.5H1M16 14.5h4"/>';
const CHECK_ACCENT = '<path d="M17.5 3.2 19 4.7 23 0.5"/>';
const SPARK_ACCENT =
	'<path d="M20 .5 20.9 2.6 23 3.5 20.9 4.4 20 6.5 19.1 4.4 17 3.5 19.1 2.6Z"/>';
const PEN_ACCENT = '<path d="M14.5 7.5 20.5 1.5"/><path d="m19 0 2.5 2.5"/>';

const PATHS: Record<OriginLevel, string> = {
	human: PERSON,
	"human-checked": PERSON + CHECK_ACCENT,
	"human-assisted": PERSON + SPARK_ACCENT,
	"ai-drafted-rewritten": CHIP + PEN_ACCENT,
	"ai-drafted-reviewed": CHIP + CHECK_ACCENT,
	"ai-generated": CHIP,
};

function svg(paths: string): string {
	return `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;
}

export const originIcons: Record<OriginLevel, string> = Object.fromEntries(
	Object.entries(PATHS).map(([level, paths]) => [level, svg(paths)]),
) as Record<OriginLevel, string>;
