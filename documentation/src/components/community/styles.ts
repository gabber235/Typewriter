export const communityStyles = {
	section: "not-content mx-auto max-w-4xl px-6 py-16 text-center",
	links: "flex flex-wrap items-center justify-center gap-4",
	linkBase:
		"inline-flex items-center gap-2 rounded-full border border-[var(--sl-color-hairline-shade)] bg-[var(--surface-container)]/60 px-5 py-2.5 font-bold text-[var(--sl-color-white)] no-underline transition hover:border-[var(--color-primary)] hover:text-[var(--color-primary)]",
	icon: "h-5 w-5",
	sponsorsHeading: "mt-12 text-sm text-[var(--on-surface-variant)]",
	sponsorsRow: "mt-4 flex flex-wrap items-center justify-center gap-3",
	sponsorLink: "block",
	sponsorAvatar:
		"h-12 w-12 rounded-full border border-[var(--sl-color-hairline-shade)] transition hover:border-[var(--color-primary)]",
} as const;
