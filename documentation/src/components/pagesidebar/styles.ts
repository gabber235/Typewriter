// Desktop column. Every flex level carries `min-h-0` so the sticky sidebar's
// max-height reaches the list and only the list scrolls.
export const tocStyles = {
	// Right-aligned in Starlight's wide right column, at a fixed reading width.
	column: "hidden min-h-0 w-full max-w-68 flex-col ms-auto min-[72em]:flex",
	root: "flex min-h-0 flex-col",
	nav: "flex min-h-0 flex-col",
	header: "flex items-center gap-2 pb-2",
	title:
		"m-0 font-(family-name:--font-sans) text-sm font-bold text-(--sl-color-white)",
	// About 10% taller than the title's 20px line box.
	ring: "size-7",
	// The 4px padding keeps focus rings (2px + 2px offset) from being clipped.
	scroller:
		"toc-scroller -mx-1 min-h-0 overflow-y-auto overscroll-contain scroll-py-8 p-1 [scrollbar-width:thin]",
	rail: "relative",
	// Drawn by toc-elements.ts: one path that steps in and out with the
	// heading depth, and a copy dashed to the stretch beside the sections on
	// screen.
	line: "pointer-events-none absolute start-0 top-0 overflow-visible",
	track:
		"fill-none stroke-(--sl-color-hairline) [stroke-linecap:round] [stroke-linejoin:round] [stroke-width:2] forced-colors:stroke-[GrayText]",
	thumb:
		"fill-none stroke-(--color-primary) opacity-0 transition-[stroke-dasharray,stroke-dashoffset,opacity] duration-200 ease-out [stroke-linecap:round] [stroke-linejoin:round] [stroke-width:2] data-active:opacity-100 forced-colors:stroke-[Highlight]",
} as const;

// The percentage sits inside the ring. 12px fits "100%" in the 40px ring;
// the 20px inline ring only fits the bare number at 9px.
export const ringStyles = {
	root: "relative grid shrink-0 place-items-center",
	svg: "absolute inset-0 size-full -rotate-90",
	track: "stroke-(--sl-color-hairline-light) forced-colors:stroke-[GrayText]",
	fill: "stroke-(--color-primary) forced-colors:stroke-[Highlight]",
	percent: {
		large:
			"relative font-(family-name:--font-sans) text-xs font-semibold tracking-[-0.04em] tabular-nums text-(--sl-color-white)",
		inline:
			"relative font-(family-name:--font-sans) text-[0.5625rem] font-bold leading-none tracking-[-0.06em] tabular-nums text-(--sl-color-white)",
	},
} as const;

// Shared list markup; the two variants only differ in how a link looks.
export const tocListStyles = {
	rail: {
		list: "m-0 list-none p-0",
		// 13px text on 5px padding gives 28px rows, above the 24px target
		// minimum. The indent step (0.75rem) is also the rail's step, so the
		// text keeps the same distance from the line at every depth.
		// `data-visible` marks the other sections on screen.
		link: "block rounded-sm py-[0.3125rem] pe-1 ps-[calc(0.875rem+var(--toc-depth)*0.75rem)] font-(family-name:--font-sans) text-[0.8125rem] leading-snug text-(--on-surface-variant) no-underline [overflow-wrap:anywhere] transition-colors duration-150 hover:text-(--sl-color-white) data-visible:text-(--sl-color-white) aria-[current=true]:font-semibold aria-[current=true]:text-(--color-primary)",
	},
	sheet: {
		list: "m-0 list-none p-0",
		// 44px rows for thumbs; the bar is the non-colour cue for the current
		// item and becomes Highlight in forced colours.
		link: "relative flex min-h-11 items-center rounded-lg py-2 pe-3 ps-[calc(0.875rem+var(--toc-depth)*1rem)] font-(family-name:--font-sans) text-sm leading-snug text-(--on-surface-variant) no-underline [overflow-wrap:anywhere] transition-colors duration-150 before:absolute before:inset-y-2.5 before:start-1 before:w-1 before:rounded-full hover:bg-(--color-primary)/8 hover:text-(--sl-color-white) focus-visible:outline-offset-[-2px] data-visible:text-(--sl-color-white) aria-[current=true]:bg-(--color-primary)/10 aria-[current=true]:font-semibold aria-[current=true]:text-(--color-primary) aria-[current=true]:before:bg-(--color-primary) forced-colors:aria-[current=true]:before:bg-[Highlight]",
	},
} as const;

export const sheetStyles = {
	root: "block min-[72em]:hidden",
	dock: "fixed end-4 bottom-[max(1rem,env(safe-area-inset-bottom))] z-50 print:hidden",
	// Opaque so the pill never lowers the contrast of the text it floats over.
	// Buttons here reset their own UA chrome: the site loads no preflight.
	pill: "flex h-11 cursor-pointer max-w-[min(18rem,calc(100vw-2rem))] items-center gap-2 rounded-full border border-(--sl-color-hairline-light) bg-(--surface) ps-0.5 pe-3 font-(family-name:--font-sans) text-(--sl-color-white) shadow-lg shadow-black/25 transition-colors duration-150 hover:border-(--color-primary) aria-expanded:border-(--color-primary)",
	ring: "size-10",
	label: "min-w-0 flex-1 truncate text-start text-[0.8125rem] font-medium",
	icon: "size-4 shrink-0 text-(--on-surface-variant)",
	dialog:
		"inset-x-0 top-auto bottom-[max(0.75rem,env(safe-area-inset-bottom))] mx-auto my-0 max-h-[min(75dvh,40rem)] w-[calc(100%-1.5rem)] max-w-lg flex-col overflow-hidden rounded-2xl border border-(--sl-color-hairline-light) bg-(--surface-container-lowest) p-0 text-(--sl-color-white) shadow-2xl open:flex backdrop:bg-black/50",
	header:
		"flex shrink-0 items-center gap-2.5 border-b border-(--sl-color-hairline) py-1 ps-4 pe-1.5",
	title:
		"m-0 font-(family-name:--font-sans) text-sm font-bold text-(--sl-color-white)",
	headerRing: "size-5.5",
	close:
		"ms-auto flex size-11 shrink-0 cursor-pointer items-center justify-center rounded-full border-0 bg-transparent p-0 text-(--on-surface-variant) transition-colors duration-150 hover:bg-(--color-primary)/10 hover:text-(--sl-color-white)",
	closeIcon: "size-5",
	body: "min-h-0 flex-1 overflow-y-auto overscroll-contain scroll-py-2 p-2",
} as const;
