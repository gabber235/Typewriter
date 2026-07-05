export const featureGridStyles = {
	grid: "not-content mx-auto grid max-w-6xl grid-cols-1 gap-6 px-6 py-16 md:grid-cols-2 lg:grid-cols-3",
	card: "flex flex-col gap-3 rounded-2xl border border-[var(--sl-color-hairline-shade)] bg-[var(--surface-container)]/40 p-6 no-underline transition hover:border-[var(--color-primary)]",
	icon: "h-8 w-8 text-[var(--color-primary)]",
	cardTitle: "text-lg font-bold text-[var(--sl-color-white)]",
	cardDescription: "text-sm text-[var(--on-surface-variant)]",
	cardMedia:
		"mt-2 w-full rounded-lg border border-[var(--sl-color-hairline-shade)] object-cover",
	showcase: "not-content mx-auto max-w-4xl px-6 pb-16",
	showcaseHeading:
		"mb-2 text-center text-2xl font-bold text-[var(--sl-color-white)]",
	showcaseDescription: "mb-6 text-center text-[var(--on-surface-variant)]",
} as const;
