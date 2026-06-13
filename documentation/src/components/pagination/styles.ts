export const paginationStyles = {
	container:
		"not-content mt-12 grid grid-cols-1 gap-4 border-t border-[var(--sl-color-hairline-shade)] pt-8 sm:grid-cols-2 print:hidden",

	link: "group flex flex-col gap-2 rounded-xl border border-[var(--sl-color-gray-5)] bg-[var(--surface-container)]/40 p-4 no-underline transition-[border-color,background-color,transform] duration-200 hover:border-[var(--color-primary)]",
	linkPrev: "items-start text-left sm:col-start-1",
	linkNext: "items-end text-right sm:col-start-2",

	eyebrow:
		"flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-[var(--on-surface-variant)]",

	title:
		"text-lg font-semibold leading-snug text-[var(--sl-color-white)] transition-colors duration-200 group-hover:text-[var(--color-primary)]",

	icon: "inline-flex transition-transform duration-200",
	iconPrev: "group-hover:-translate-x-1",
	iconNext: "group-hover:translate-x-1",
} as const;
