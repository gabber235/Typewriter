// A blank page reads better than a broken one: a big "typed" 404 with a
// blinking caret, centred in the space a real page would otherwise fill.
export const notFoundStyles = {
	root: "flex min-h-[65vh] flex-col items-center justify-center px-5 py-20 text-center sm:px-8",
	code: "m-0 flex items-baseline justify-center gap-1 font-[family-name:var(--font-sans)] text-7xl font-extrabold leading-none tracking-tight text-[var(--sl-color-white)] sm:text-8xl",
	cursor:
		"inline-block h-[0.8em] w-[0.5ch] translate-y-[0.06em] bg-[var(--color-primary)] motion-safe:animate-[notfound-caret_1.1s_steps(1,end)_infinite] motion-reduce:opacity-100",
	title:
		"mt-6 max-w-xl text-balance font-[family-name:var(--font-sans)] text-2xl font-bold leading-snug text-[var(--sl-color-white)] sm:text-3xl",
	lead: "mt-4 max-w-md text-balance font-[family-name:var(--font-reading)] text-base leading-relaxed text-[var(--on-surface-variant)]",
	actions: "mt-8 flex flex-wrap items-center justify-center gap-3",
	hint: "m-0 mt-8 font-[family-name:var(--font-reading)] text-sm text-[var(--on-surface-variant)]",
} as const;
