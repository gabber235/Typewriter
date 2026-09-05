export const landingStyles = {
	container: "mx-auto w-full max-w-6xl px-5 sm:px-8",
	eyebrow:
		"m-0 font-[family-name:var(--font-sans)] text-xs font-bold uppercase tracking-[0.14em] text-[var(--color-primary)]",
	h2: "mt-3 mb-0 font-[family-name:var(--font-sans)] text-3xl font-extrabold leading-tight tracking-tight text-[var(--sl-color-white)] sm:text-4xl",
	h3: "m-0 font-[family-name:var(--font-sans)] text-lg font-bold leading-snug text-[var(--sl-color-white)]",
	lead: "mt-4 mb-0 max-w-2xl font-[family-name:var(--font-reading)] text-base leading-relaxed text-[var(--on-surface-variant)] sm:text-lg",
	body: "tw-prose font-[family-name:var(--font-reading)] text-base leading-relaxed text-[var(--sl-color-text)] [&>p]:m-0 [&>p+p]:mt-3 [&_a]:text-[var(--color-primary)] [&_a]:underline [&_a]:underline-offset-4 [&_strong]:font-semibold [&_strong]:text-[var(--sl-color-white)]",
	muted:
		"font-[family-name:var(--font-reading)] text-sm leading-relaxed text-[var(--on-surface-variant)]",
	buttonPrimary:
		"inline-flex min-h-11 items-center justify-center gap-2 rounded-full bg-[var(--color-primary)] px-6 py-2.5 font-[family-name:var(--font-sans)] text-sm font-bold text-[var(--on-primary)] no-underline transition-shadow duration-150 hover:shadow-[0_0_0_4px_rgba(var(--color-primary-rgb),0.3)] motion-reduce:transition-none",
	buttonSecondary:
		"inline-flex min-h-11 items-center justify-center gap-2 rounded-full border border-[var(--sl-color-hairline)] bg-[var(--surface-container)] px-6 py-2.5 font-[family-name:var(--font-sans)] text-sm font-bold text-[var(--sl-color-white)] no-underline transition-colors duration-150 hover:border-[var(--color-primary)] hover:text-[var(--color-primary)] motion-reduce:transition-none",
	textLink:
		"inline-flex min-h-11 items-center gap-1.5 font-[family-name:var(--font-sans)] text-sm font-bold text-[var(--color-primary)] no-underline underline-offset-4 hover:underline",
	card: "rounded-2xl border border-[var(--sl-color-hairline)] bg-[var(--surface-container)]",
	icon: "size-5 shrink-0",
	chip: "inline-flex items-center rounded-md border border-[var(--sl-color-hairline)] bg-[var(--surface-container-lowest)] px-2 py-0.5 font-[family-name:var(--font-mono)] text-xs text-[var(--sl-color-text)]",
} as const;

/** A schematic chat exchange: one spoken line and a numbered reply. */
export const chatStyles = {
	line: "m-0 font-[family-name:var(--font-mono)] text-sm leading-relaxed text-[var(--sl-color-text)] sm:text-base",
	speaker:
		"font-bold text-[var(--material-orange-300)] [[data-theme=light]_&]:text-[var(--material-deep-orange-900)]",
	option:
		"m-0 flex items-center gap-3 font-[family-name:var(--font-mono)] text-sm leading-relaxed text-[var(--sl-color-text)] sm:text-base",
	key: "grid size-6 shrink-0 place-items-center rounded-md border border-[var(--sl-color-hairline)] bg-[var(--surface-container)] text-xs font-bold text-[var(--sl-color-white)]",
	optionActive: "text-[var(--sl-color-white)]",
	caret: "text-[var(--color-primary)]",
} as const;

/** A dot-leader row: key left, value right, like a table of contents. */
export const ledgerStyles = {
	row: "flex items-baseline gap-2",
	key: "m-0 shrink-0",
	leader:
		"min-w-4 flex-1 -translate-y-[0.35em] border-b border-dotted border-[var(--sl-color-hairline)]",
	value: "m-0 shrink-0",
} as const;
