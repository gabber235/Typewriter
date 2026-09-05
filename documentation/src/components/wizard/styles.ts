export const wizardStyles = {
	container:
		"my-6 rounded-lg border border-[var(--sl-color-gray-5)] bg-[var(--surface-container)]/50 p-4",
	sourceQuestion: "font-semibold font-sans",

	ui: "not-content flex flex-col gap-3 text-[var(--sl-color-text)] font-[family-name:var(--font-reading)]",
	title: `m-0 text-xs font-semibold uppercase tracking-wide text-primary font-sans`,

	header: "flex min-h-6 items-center gap-3",
	trailNav:
		"min-w-0 flex-1 overflow-x-auto overscroll-x-contain [scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
	trailFade:
		"[mask-image:linear-gradient(to_right,#000_calc(100%_-_1.5rem),transparent)]",
	trail:
		"m-0 flex w-max list-none items-center gap-1.5 whitespace-nowrap p-0 leading-none",
	trailItem: "flex shrink-0 items-center gap-1.5",
	trailSeparator: "select-none text-[var(--on-surface-variant)]",
	// `h-6` plus a 22px line box (not padding) keeps the chip exactly 24px tall
	// for the 2.5.8 target size while the header row keeps its `min-h-6`.
	chip: `block h-6 max-w-[14rem] cursor-pointer truncate rounded-full border border-[var(--sl-color-gray-5)] bg-[var(--surface-container-lowest)] px-2.5 text-xs leading-[22px] font-medium text-[var(--on-surface-variant)] transition-colors duration-150 hover:border-[rgba(var(--color-primary-rgb),0.5)] hover:text-primary focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary font-sans`,
	counter:
		"shrink-0 text-xs font-semibold uppercase tracking-wide text-[var(--on-surface-variant)] font-sans",

	stage: "relative",
	// `visibility` must stay out of the transition list: an interpolated value
	// still reads as `hidden` when focus moves into the incoming panel.
	panel:
		"absolute inset-x-0 top-0 flex flex-col gap-3 transition-opacity duration-[180ms] ease-out motion-reduce:transition-none",
	panelActive: "visible opacity-100",
	panelLeaving: "visible opacity-0 pointer-events-none",
	// `invisible`, not just transparent: hidden text must not be selectable or
	// findable with find-in-page.
	panelHidden: "invisible opacity-0 pointer-events-none",

	question:
		"m-0 text-base font-semibold leading-snug text-[var(--sl-color-white)] font-sans [&_a]:text-primary",
	answers: "flex flex-col gap-2",
	answer: `group flex w-full cursor-pointer items-center justify-between gap-3 rounded-lg border border-[var(--sl-color-gray-5)] bg-[var(--surface-container-lowest)] px-4 py-3 text-left text-sm font-medium text-[var(--sl-color-white)] transition-[background-color,border-color] duration-150 hover:border-[rgba(var(--color-primary-rgb),0.6)] hover:bg-[rgba(var(--color-primary-rgb),0.07)] active:bg-[rgba(var(--color-primary-rgb),0.12)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary`,
	answerIcon: `shrink-0 text-[var(--on-surface-variant)] transition-transform duration-150 group-hover:translate-x-0.5 group-hover:text-primary motion-reduce:transition-none`,

	result: `rounded-lg border border-[rgba(var(--color-primary-rgb),0.4)] bg-[rgba(var(--color-primary-rgb),0.07)] px-4 py-3 outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary`,
	resultHeader: `mb-2 flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-primary font-sans`,
	resultBody:
		"text-sm leading-relaxed text-[var(--sl-color-text)] [&_a]:text-primary [&_a]:underline [&_a]:underline-offset-2 [&_p]:my-0 [&_p+p]:mt-2 [&_code]:rounded [&_code]:bg-[var(--sl-color-gray-6)] [&_code]:px-1",

	footer:
		"flex items-center gap-2 border-t border-[var(--sl-color-hairline-shade)] pt-3",
	control: `inline-flex cursor-pointer items-center gap-1.5 rounded-full border border-transparent bg-transparent px-3 py-1 text-xs font-semibold text-[var(--on-surface-variant)] transition-colors duration-150 hover:text-[var(--sl-color-white)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:cursor-default disabled:opacity-40 disabled:hover:text-[var(--on-surface-variant)] font-sans`,

	srOnly: "sr-only",
} as const;
