// One-line previous/next links that share a row height and type scale with the
// edit link and byline under them, so the four read as one list of page actions.
export const paginationStyles = {
	container:
		"not-content mt-12 grid grid-cols-2 gap-x-6 border-t border-[var(--sl-color-hairline)] pt-4 print:hidden",

	link: "group flex min-h-11 min-w-0 flex-wrap items-center gap-x-2 gap-y-0.5 text-sm no-underline",
	linkPrev: "col-start-1 justify-start text-start",
	linkNext: "col-start-2 justify-end text-end",

	eyebrow:
		"flex items-center gap-1 font-[family-name:var(--font-sans)] text-[var(--on-surface-variant)]",

	title:
		"max-w-full break-words font-[family-name:var(--font-sans)] font-semibold leading-snug text-[var(--sl-color-white)] transition-colors duration-200 group-hover:text-[var(--color-primary)]",

	icon: "inline-flex transition-transform duration-200 motion-reduce:transition-none",
	iconPrev: "group-hover:-translate-x-0.5",
	iconNext: "group-hover:translate-x-0.5",
} as const;
