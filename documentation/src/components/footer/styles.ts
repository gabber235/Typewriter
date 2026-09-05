// The footer is a container query root: on docs pages it lives in the
// reading column, on the homepage in the wide landing container, and the
// link groups switch from two columns to one row based on that width alone.
export const footerStyles = {
	// The footer is the container-query root for everything below it.
	container: "@container not-content flex flex-col print:hidden",

	// Sits directly under the previous/next row as one "about this page" block;
	// it only draws its own rule when there is no pagination above it.
	meta: "flex flex-col items-start gap-1 @md:flex-row @md:flex-wrap @md:items-center @md:justify-between @md:gap-x-6",
	metaRule: "mt-12 border-t border-[var(--sl-color-hairline)] pt-4",

	editLink:
		"flex min-h-11 shrink-0 items-center gap-1.5 whitespace-nowrap text-sm font-semibold text-[var(--sl-color-white)] no-underline transition-colors duration-200 hover:text-[var(--color-primary)]",
	editIcon: "inline-flex",

	byline:
		"flex min-h-11 flex-col items-start justify-center gap-3 @md:flex-row @md:flex-wrap @md:items-center @md:gap-x-5 @md:gap-y-2",

	updated:
		"m-0 font-[family-name:var(--font-sans)] text-sm text-[var(--on-surface-variant)] @md:whitespace-nowrap",
	byAuthor: "relative inline-flex items-center gap-1.5",
	author:
		"relative inline-flex items-center gap-1.5 align-middle font-medium text-[var(--sl-color-white)] no-underline transition-colors duration-200 before:absolute before:-inset-2.5 before:content-[''] hover:text-[var(--color-primary)]",
	authorAvatar: "block size-6 rounded-full bg-[var(--surface-container)]",

	others: "flex flex-wrap items-center gap-2",
	othersLabel: "text-sm text-[var(--on-surface-variant)]",
	avatars: "m-0 flex list-none items-center -space-x-1.5 p-0",
	avatarItem: "block",
	avatarLink:
		"relative block rounded-full transition-transform duration-200 before:absolute before:-inset-2.5 before:content-[''] hover:z-10 hover:-translate-y-0.5",
	avatar:
		"block size-6 rounded-full bg-[var(--surface-container)] ring-2 ring-[var(--sl-color-bg)]",
	fallback:
		"flex size-6 items-center justify-center rounded-full bg-[var(--surface-container)] text-xs font-semibold text-[var(--on-surface-variant)] ring-2 ring-[var(--sl-color-bg)]",

	// Full-bleed band under every page; its own container-query root. The rule
	// only appears where no sidebar sits above it (the homepage), otherwise it
	// would cut across the sidebar column.
	site: "@container w-full bg-[var(--surface)] print:hidden",
	siteRule: "border-t border-[var(--sl-color-hairline)]",
	siteInner: "mx-auto w-full max-w-6xl px-5 py-10 sm:px-8 @md:py-12",
	// Two columns on phones, three in the docs reading column, brand beside the
	// groups only when the container is wide enough for all four.
	siteGrid:
		"grid grid-cols-2 gap-x-6 gap-y-8 @md:grid-cols-3 @md:gap-x-8 @2xl:grid-cols-[minmax(0,1.6fr)_repeat(3,minmax(0,1fr))]",
	brand: "col-span-2 flex flex-col gap-3 @md:col-span-3 @2xl:col-span-1",
	brandLink:
		"inline-flex w-fit min-h-11 items-center gap-2 font-[family-name:var(--font-sans)] text-base font-extrabold text-[var(--sl-color-white)] no-underline transition-colors duration-150 hover:text-[var(--color-primary)]",
	brandLogo: "block h-7 w-auto rounded-md",
	tagline:
		"m-0 max-w-[30ch] font-[family-name:var(--font-reading)] text-sm leading-relaxed text-[var(--on-surface-variant)]",
	group: "flex flex-col",
	groupTitle:
		"m-0 mb-1 font-[family-name:var(--font-sans)] text-xs font-bold uppercase tracking-[0.14em] text-[var(--on-surface-variant)]",
	groupList: "m-0 flex list-none flex-col p-0",
	// 44px rows where fingers do the clicking, tighter once a pointer is likely.
	groupLink:
		"flex min-h-11 items-center font-[family-name:var(--font-reading)] text-sm text-[var(--sl-color-text)] no-underline transition-colors duration-150 hover:text-[var(--color-primary)] @md:min-h-8",
} as const;
