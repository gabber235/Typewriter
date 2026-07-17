export const paginationStyles = {
	container:
		"not-content mt-12 grid grid-cols-2 gap-3 border-t border-[var(--sl-color-hairline-shade)] pt-8 sm:gap-4 print:hidden",

	link: "group flex min-w-0 flex-col gap-1 rounded-xl border border-[var(--sl-color-gray-5)] bg-[var(--surface-container)]/40 p-3 no-underline transition-[border-color,background-color,transform] duration-200 hover:border-[var(--color-primary)] sm:gap-2 sm:p-4",
	linkPrev: "col-start-1 items-start text-start",
	linkNext: "col-start-2 items-end text-end",

	eyebrow:
		"flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-[var(--on-surface-variant)]",

	title:
		"max-w-full truncate text-sm font-semibold leading-snug text-[var(--sl-color-white)] transition-colors duration-200 group-hover:text-[var(--color-primary)] sm:overflow-visible sm:whitespace-normal sm:text-lg",

	icon: "inline-flex transition-transform duration-200",
	iconPrev: "group-hover:-translate-x-1",
	iconNext: "group-hover:translate-x-1",
} as const;
