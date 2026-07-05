export const audienceSplitStyles = {
	section:
		"not-content mx-auto grid max-w-6xl grid-cols-1 gap-6 px-6 py-16 md:grid-cols-2",
	card: "flex flex-col gap-4 rounded-2xl border p-8",
	cardPrimary:
		"border-[var(--color-primary)]/40 bg-[rgba(var(--color-primary-rgb),0.08)]",
	cardSecondary:
		"border-[var(--color-secondary)]/40 bg-[var(--surface-container)]/40",
	eyebrow: "text-label-large uppercase",
	eyebrowPrimary: "text-[var(--color-primary)]",
	eyebrowSecondary: "text-[var(--color-secondary)]",
	heading: "text-2xl font-bold text-[var(--sl-color-white)]",
	body: "text-[var(--on-surface-variant)]",
	cta: "mt-2 inline-flex w-fit items-center gap-2 rounded-full px-5 py-2.5 font-bold no-underline transition",
	ctaPrimary:
		"bg-[var(--color-primary)] text-[var(--surface)] hover:opacity-90",
	ctaSecondary:
		"border border-[var(--sl-color-hairline-shade)] text-[var(--sl-color-white)] hover:border-[var(--color-secondary)] hover:text-[var(--color-secondary)]",
} as const;
