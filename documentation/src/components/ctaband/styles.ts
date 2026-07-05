export const ctaBandStyles = {
	section: "not-content mx-auto max-w-4xl px-6 py-20 text-center",
	heading: "text-3xl font-extrabold text-[var(--sl-color-white)] sm:text-4xl",
	body: "mx-auto mt-3 max-w-xl text-[var(--on-surface-variant)]",
	ctaGroup: "mt-8 flex flex-wrap items-center justify-center gap-4",
	ctaPrimary:
		"rounded-full bg-[var(--color-primary)] px-6 py-3 font-bold text-[var(--surface)] no-underline transition hover:opacity-90",
	ctaSecondary:
		"rounded-full border border-[var(--sl-color-hairline-shade)] px-6 py-3 font-bold text-[var(--sl-color-white)] no-underline transition hover:border-[var(--color-primary)] hover:text-[var(--color-primary)]",
} as const;
