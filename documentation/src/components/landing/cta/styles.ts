// The closing band is flat: a rule, one big line, the two actions, and the
// sponsors beside them as the page's only proof.
export const ctaStyles = {
	section: "py-16 sm:py-24",
	grid: "grid grid-cols-1 gap-x-12 gap-y-10 border-t border-[var(--sl-color-hairline)] pt-12 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)] lg:items-start lg:pt-14",
	copy: "flex flex-col gap-6",
	title:
		"m-0 font-[family-name:var(--font-sans)] text-4xl font-extrabold leading-[1.05] tracking-tight text-[var(--sl-color-white)] text-balance sm:text-5xl",
	body: "m-0 max-w-[36rem] font-[family-name:var(--font-reading)] text-base leading-relaxed text-[var(--on-surface-variant)] sm:text-lg [&>p]:m-0",
	actions: "flex flex-wrap items-center gap-3",

	sponsors: "flex flex-col gap-4 lg:pt-2",
	sponsorsLabel:
		"m-0 font-[family-name:var(--font-sans)] text-[0.7rem] font-bold uppercase tracking-[0.14em] text-[var(--on-surface-variant)]",
	// Wraps to however many sponsors there are; higher tiers get the larger size.
	sponsorsList: "m-0 flex list-none flex-wrap items-center gap-2 p-0",
	sponsorLink:
		"block rounded-full outline-offset-2 transition-opacity duration-150 hover:opacity-80 motion-reduce:transition-none",
	sponsorAvatar:
		"m-0 block rounded-full border border-[var(--sl-color-hairline)] bg-[var(--surface-container)]",
	avatarFeatured: "size-12",
	avatarRegular: "size-9",
} as const;
