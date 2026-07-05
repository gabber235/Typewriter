export const heroStyles = {
	section: "relative isolate overflow-hidden not-content",
	background:
		"pointer-events-none absolute inset-0 -z-20 h-full w-full object-cover",
	overlay:
		"absolute inset-0 -z-10 bg-gradient-to-b from-[var(--surface)]/70 via-[var(--surface)]/80 to-[var(--surface)]",
	content:
		"relative z-0 mx-auto flex max-w-3xl flex-col items-center gap-6 px-6 py-24 text-center sm:py-32",
	logo: "h-16 w-16",
	title:
		"text-4xl font-extrabold tracking-tight text-[var(--sl-color-white)] sm:text-6xl",
	tagline: "max-w-xl text-lg text-[var(--on-surface-variant)] sm:text-xl",
	ctaGroup: "mt-4 flex flex-wrap items-center justify-center gap-4",
	ctaPrimary:
		"rounded-full bg-[var(--color-primary)] px-6 py-3 font-bold text-[var(--surface)] transition hover:opacity-90",
	ctaSecondary:
		"rounded-full border border-[var(--sl-color-hairline-shade)] bg-[var(--surface-container)]/60 px-6 py-3 font-bold text-[var(--sl-color-white)] transition hover:border-[var(--color-primary)] hover:text-[var(--color-primary)]",
} as const;
