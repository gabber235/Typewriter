// Requirements and questions share one section: facts to scan on the left,
// questions to open on the right. The grid reserves room for one open answer
// so opening a question never pushes the section taller.
export const startStyles = {
	grid: "grid grid-cols-1 gap-x-12 gap-y-10 lg:min-h-[25rem] lg:grid-cols-[minmax(0,2fr)_minmax(0,3fr)]",
	label:
		"m-0 mb-4 font-[family-name:var(--font-sans)] text-[0.7rem] font-bold uppercase tracking-[0.14em] text-[var(--on-surface-variant)]",

	rows: "m-0 flex flex-col gap-4 font-[family-name:var(--font-mono)] text-sm",
	item: "grid grid-cols-[auto_minmax(1rem,1fr)_auto] items-baseline gap-x-2",
	key: "m-0 text-[var(--on-surface-variant)]",
	leader:
		"min-w-4 -translate-y-[0.35em] border-b border-dotted border-[var(--sl-color-hairline)]",
	value: "m-0 font-bold text-[var(--sl-color-white)]",
	link: "text-[var(--sl-color-white)] underline decoration-[rgba(var(--color-primary-rgb),0.5)] underline-offset-4 hover:text-[var(--color-primary)]",
	note: "col-span-3 m-0 font-[family-name:var(--font-reading)] text-xs leading-relaxed text-[var(--on-surface-variant)]",

	// `:::details` renders cards; here they flatten into hairline rows.
	questions:
		"[&>details]:my-0 [&>details]:rounded-none [&>details]:border-0 [&>details]:border-b [&>details]:border-[var(--sl-color-hairline)] [&>details]:bg-transparent [&>details:first-child]:border-t [&>details>summary]:rounded-none [&>details>summary]:px-0 [&>details>summary]:py-3 [&>details>summary:hover]:bg-transparent [&>details>summary:hover]:text-[var(--color-primary)] [&>details>div]:px-0 [&>details>div]:pt-0 [&>details>div]:pb-3 [&>details>div]:text-sm",
} as const;
