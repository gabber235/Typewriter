// The code is the message here, so it leads: top-left under the heading,
// wider than the copy. Labels inside the frame do the explaining.
export const developersStyles = {
	grid: "grid grid-cols-1 items-start gap-10 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)] lg:gap-12",
	// Expressive Code sets its own margins; the frame should sit flush.
	code: "min-w-0 [&_.expressive-code]:m-0",
	copy: "flex flex-col gap-7 lg:pt-1",
	listLabel:
		"m-0 mb-3 font-[family-name:var(--font-sans)] text-[0.7rem] font-bold uppercase tracking-[0.14em] text-[var(--on-surface-variant)]",
	rows: "m-0 flex flex-col gap-2 font-[family-name:var(--font-mono)] text-sm text-[var(--sl-color-white)]",
	more: "m-0 mt-3 max-w-[40ch] font-[family-name:var(--font-reading)] text-sm leading-relaxed text-[var(--on-surface-variant)]",
} as const;
