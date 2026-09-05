// The code is the message here, so on a desktop it leads: top-left under the
// heading, wider than the copy. Labels inside the frame do the explaining.
//
// On a phone the same frame is 672px of wrapped mono before a word of prose, so
// the order flips. Both columns become `contents` under `lg`, which drops their
// children straight into the one-column grid, and `order-*` interleaves them:
// prose, a short excerpt, the whole class behind a disclosure, then the ledger.
// The excerpt scrolls sideways instead of wrapping because Kotlin indentation
// carries meaning (WCAG 1.4.10 exempts code from reflow for that reason).
export const developersStyles = {
	grid: "grid grid-cols-1 items-start gap-6 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)] lg:gap-12",
	column: "contents lg:block lg:min-w-0",
	copy: "contents lg:flex lg:flex-col lg:gap-7 lg:pt-1",
	// Expressive Code sets its own margins; the frame should sit flush.
	code: "min-w-0 max-lg:hidden [&_.expressive-code]:m-0",
	excerpt:
		"order-2 min-w-0 lg:hidden [&_.expressive-code]:m-0 [&_pre]:overscroll-x-contain",
	disclosure: "order-3 min-w-0 lg:hidden",
	summary:
		"flex min-h-11 cursor-pointer list-none select-none items-center gap-2.5 font-[family-name:var(--font-sans)] text-sm font-bold text-[var(--color-primary)] before:hidden focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[var(--color-primary)] [&::-webkit-details-marker]:hidden [&::marker]:hidden",
	caret:
		"size-2 shrink-0 -rotate-45 border-r-2 border-b-2 border-current transition-transform duration-200 [details[open]_&]:rotate-45 motion-reduce:transition-none",
	summaryOpen: "hidden [details[open]_&]:inline",
	summaryClosed: "[details[open]_&]:hidden",
	body: "min-w-0 pt-3 [&_.expressive-code]:m-0",
	text: "order-1",
	list: "order-4",
	link: "order-5",
	listLabel:
		"m-0 mb-3 font-[family-name:var(--font-sans)] text-xs font-bold uppercase tracking-[0.14em] text-[var(--on-surface-variant)] lg:text-[0.7rem]",
	rows: "m-0 flex flex-col gap-1.5 font-[family-name:var(--font-mono)] text-sm text-[var(--sl-color-white)] lg:gap-2",
	more: "m-0 mt-3 max-w-[40ch] font-[family-name:var(--font-reading)] text-sm leading-relaxed text-[var(--on-surface-variant)]",
} as const;
