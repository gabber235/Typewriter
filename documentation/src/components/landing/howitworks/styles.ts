export const stepStyles = {
	root: "relative",
	grid: "relative lg:grid lg:grid-cols-[minmax(0,2fr)_minmax(0,3fr)] lg:items-start lg:gap-14",

	// One stage for every step's picture; it sticks while the steps scroll past.
	// Below lg there is no stage: each step keeps its picture under its text.
	stage:
		"sticky top-24 z-10 aspect-[16/10] w-full overflow-hidden rounded-2xl border border-[var(--sl-color-hairline)] bg-[var(--surface-container)] max-lg:hidden lg:col-start-2 lg:row-start-1",
	panel:
		"absolute inset-0 transition-opacity duration-500 ease-out motion-reduce:transition-none [&>*]:h-full [&>*]:w-full [&_img]:h-full [&_img]:w-full [&_img]:object-cover",
	panelHidden: "pointer-events-none opacity-0",
	panelActive: "opacity-100",

	list: "relative m-0 flex list-none flex-col p-0 lg:col-start-1 lg:row-start-1",
	line: "absolute left-[1.125rem] w-px bg-[var(--sl-color-hairline)]",
	fill: "absolute left-[1.125rem] w-px bg-[var(--color-primary)] transition-[height] duration-500 ease-out motion-reduce:transition-none",

	step: "relative flex gap-5 py-5 transition-opacity duration-300 ease-out motion-reduce:transition-none lg:min-h-[38vh] lg:items-center lg:py-4 [[data-steps-ready]_&:not([data-active])]:opacity-45",
	marker:
		"relative z-10 grid size-9 shrink-0 place-items-center rounded-full border border-[var(--sl-color-hairline)] bg-[var(--surface-container-lowest)] font-[family-name:var(--font-mono)] text-sm font-bold text-[var(--on-surface-variant)] transition-colors duration-300 motion-reduce:transition-none [[data-active]_&]:border-[var(--color-primary)] [[data-active]_&]:bg-[var(--color-primary)] [[data-active]_&]:text-[var(--on-primary)] [[data-passed]_&]:border-[var(--color-primary)] [[data-passed]_&]:text-[var(--color-primary)]",
	text: "flex flex-col gap-3 pt-1",
	// Inline picture: shown below lg and without JS; moved into the stage on lg.
	media: "mt-4 aspect-[16/10] w-full lg:hidden",

	cta: "mt-8 flex justify-center",

	illustration:
		"relative flex aspect-[16/10] w-full flex-col justify-center gap-3 overflow-hidden rounded-xl border border-[var(--sl-color-hairline)] bg-[var(--surface)] p-6 max-sm:justify-start max-sm:pt-12 sm:p-8",
	illustrationLabel:
		"absolute top-3 right-3 m-0 rounded-md border border-[var(--sl-color-hairline)] bg-[var(--surface-container)] px-2 py-0.5 font-[family-name:var(--font-sans)] text-xs font-bold uppercase tracking-[0.1em] text-[var(--on-surface-variant)]",
} as const;
