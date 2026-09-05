import { icons } from "../aside/aside-config";
import type { SpoilerVariant } from "./types";

// `--spoiler-tint` paints surfaces and borders; `--spoiler-ink` is the same hue
// picked for text and icons, where 1.4.3 needs 4.5:1 against the tinted
// surface. The 500 shades only clear that on a dark background, so light mode
// steps down to an 800/900 and dark mode steps *up* for red and blue-grey.
export const spoilerVariants: Record<SpoilerVariant, string> = {
	warning:
		"[--spoiler-tint:var(--material-orange-500)] [--spoiler-ink:var(--material-deep-orange-900)] dark:[--spoiler-ink:var(--material-orange-500)]",
	danger:
		"[--spoiler-tint:var(--material-red-500)] [--spoiler-ink:var(--material-red-800)] dark:[--spoiler-ink:var(--material-red-300)]",
	info: "[--spoiler-tint:var(--material-blue-500)] [--spoiler-ink:var(--material-blue-800)] dark:[--spoiler-ink:var(--material-blue-500)]",
	neutral:
		"[--spoiler-tint:var(--material-blue-grey-500)] [--spoiler-ink:var(--material-blue-grey-700)] dark:[--spoiler-ink:var(--material-blue-grey-300)]",
};

export const spoilerIcons: Record<SpoilerVariant, string> = {
	warning: icons.warning,
	danger: icons.danger,
	info: icons.info,
	neutral: icons.note,
};

const INNER_RADIUS = "rounded-[calc(0.5rem-1px)]";
// The docs body scrolls inside the content pane, which already starts below
// the fixed nav, so the bar sticks to the pane's own top edge.
const STICKY_TOP = "top-0";

export const spoilerStyles = {
	// Two-row grid: the header bar in row 1, the preview shell and the gate
	// overlay stacked in row 2. While closed both sit in normal flow, so the
	// closed height is max(peek, card) and the card can never be clipped.
	root: `relative my-6 grid grid-cols-1 grid-rows-[auto_1fr] rounded-lg border border-[var(--spoiler-tint)]/70 bg-[var(--spoiler-surface)] [--spoiler-surface:color-mix(in_oklab,var(--spoiler-tint)_5%,var(--sl-color-bg))]`,
	rootAnimating: "overflow-hidden",

	bar: `not-content sticky ${STICKY_TOP} z-10 col-start-1 row-start-1 mt-0! flex [&[hidden]]:hidden items-center gap-2.5 rounded-t-[calc(0.5rem-1px)] border-b border-[var(--spoiler-tint)]/30 bg-[var(--spoiler-surface)] px-4 py-2`,
	barIcon: "flex shrink-0 items-center text-[var(--spoiler-ink)]",
	barTitle:
		"flex-1 truncate text-sm font-semibold text-[var(--spoiler-ink)] font-[family-name:var(--font-sans)]",
	hideButton:
		"not-content shrink-0 cursor-pointer rounded-md border border-[var(--sl-color-hairline-shade)] bg-transparent px-2.5 py-1 text-xs font-semibold text-[var(--on-surface-variant)] transition-colors duration-150 hover:bg-[var(--surface-container)]/60 hover:text-[var(--sl-color-white)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] motion-reduce:transition-none",

	shell: `relative col-start-1 row-start-2 mt-0! overflow-hidden ${INNER_RADIUS}`,
	// `contain-size` makes the shell contribute nothing but its `min-h` to the
	// row, so the closed height is the peek unless the card is taller.
	shellClosed: "contain-size min-h-[10rem]",
	shellOpen: "",

	// The header bar is sticky at the top of the scroll port, so anything that
	// can become a scroll target inside the content — a heading reached from the
	// table of contents, a control reached with Tab — needs to clear it or it
	// lands underneath the bar (2.4.11).
	content:
		"px-4 py-3 [&>:first-child]:mt-0 [&>:last-child]:mb-0 [&_:is(h1,h2,h3,h4,h5,h6,a,button,summary,[tabindex])]:scroll-mt-14",
	contentClosed: "blur-[7px] opacity-70 select-none pointer-events-none",
	contentOpen: "",

	// Scrim plus bottom fade in one gradient: translucent surface over the
	// peek, solid surface at the bottom, so the preview reads as "there is
	// more below" and ends on exactly the wrapper colour.
	gate: `not-content col-start-1 row-start-2 z-[1] mt-0! grid [&[hidden]]:hidden place-items-center ${INNER_RADIUS} p-5 bg-gradient-to-b from-[var(--spoiler-surface)]/30 via-[var(--spoiler-surface)]/30 via-35% to-[var(--spoiler-surface)]`,
	// Above the sticky bar while animating, so the bar emerges under the
	// fading overlay instead of popping in over it.
	gateAnimating: "absolute inset-0 z-20",

	card: "not-content w-full max-w-md rounded-lg border border-[var(--spoiler-tint)]/50 bg-[var(--surface-container-lowest)] px-5 py-4 text-center shadow-lg shadow-black/10",
	cardIcon:
		"mx-auto mb-2.5 flex h-9 w-9 items-center justify-center rounded-full bg-[var(--spoiler-tint)]/15 text-[var(--spoiler-ink)]",
	cardTitle:
		"text-base font-semibold text-[var(--sl-color-white)] font-[family-name:var(--font-sans)]",
	cardReason:
		"mt-1.5 text-sm leading-relaxed text-[var(--on-surface-variant)] font-[family-name:var(--font-reading)]",
	revealButton:
		"not-content mt-3.5 inline-flex cursor-pointer items-center gap-2 rounded-md border border-[var(--spoiler-tint)]/60 bg-[rgba(var(--color-primary-rgb),0.12)] px-4 py-2 text-sm font-semibold text-[var(--sl-color-white)] transition-colors duration-150 hover:bg-[rgba(var(--color-primary-rgb),0.24)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] motion-reduce:transition-none",
	cardHint: "mt-2.5 text-xs text-[var(--on-surface-variant)]",
} as const;
