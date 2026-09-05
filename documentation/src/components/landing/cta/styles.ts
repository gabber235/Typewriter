// The closing band is flat: a rule, one big line, the two actions, and the
// sponsors beside them as the page's only proof. On phones everything stacks
// full width and the avatars shrink a step so fourteen fit in two short rows.
export const ctaStyles = {
	section: "pt-14 pb-12 sm:pt-24 sm:pb-16",
	grid: "grid grid-cols-1 gap-x-12 gap-y-8 border-t border-[var(--sl-color-hairline)] pt-10 sm:gap-y-10 sm:pt-12 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)] lg:items-start lg:pt-14",
	copy: "flex flex-col gap-5 sm:gap-6",
	title:
		"m-0 font-[family-name:var(--font-sans)] text-3xl font-extrabold leading-[1.05] tracking-tight text-[var(--sl-color-white)] text-balance sm:text-4xl lg:text-5xl",
	body: "m-0 max-w-[36rem] font-[family-name:var(--font-reading)] text-base leading-relaxed text-[var(--on-surface-variant)] sm:text-lg [&>p]:m-0",
	actions:
		"flex flex-col items-stretch gap-3 sm:flex-row sm:flex-wrap sm:items-center",

	sponsors: "flex flex-col gap-3 sm:gap-4 lg:pt-2",
	sponsorsLabel:
		"m-0 font-[family-name:var(--font-sans)] text-xs font-bold uppercase tracking-[0.14em] text-[var(--on-surface-variant)]",
	// Wraps to however many sponsors there are; higher tiers get the larger size.
	sponsorsList: "m-0 flex list-none flex-wrap items-center gap-2 p-0",
	// The invisible `before` box lifts the smaller avatars to a 44px tap target.
	sponsorLink:
		"relative block rounded-full outline-offset-2 transition-opacity duration-150 before:absolute before:-inset-1.5 before:content-[''] hover:opacity-80 motion-reduce:transition-none",
	sponsorAvatar:
		"m-0 block rounded-full border border-[var(--sl-color-hairline)] bg-[var(--surface-container)]",
	avatarFeatured: "size-10 sm:size-12",
	avatarRegular: "size-8 sm:size-9",
} as const;
