export const footerStyles = {
	container: "not-content flex flex-col print:hidden",

	meta: "mt-10 flex flex-wrap items-center justify-between gap-x-6 gap-y-4 border-t border-[var(--sl-color-hairline)] pt-5",

	editLink:
		"flex items-center gap-1.5 text-sm font-medium text-[var(--sl-color-white)] no-underline transition-colors duration-200 hover:text-[var(--color-primary)]",
	editIcon: "inline-flex",

	byline: "flex flex-wrap items-center gap-x-5 gap-y-2",

	updated: "m-0 text-sm text-[var(--on-surface-variant)]",
	author:
		"inline-flex items-center gap-1.5 align-middle font-medium text-[var(--sl-color-white)] no-underline transition-colors duration-200 hover:text-[var(--color-primary)]",
	authorAvatar: "block size-6 rounded-full bg-[var(--surface-container)]",

	others: "flex items-center gap-2",
	othersLabel: "text-sm text-[var(--on-surface-variant)]",
	avatars: "m-0 flex list-none items-center -space-x-1.5 p-0",
	avatarItem: "block",
	avatarLink:
		"relative block rounded-full transition-transform duration-200 hover:z-10 hover:-translate-y-0.5",
	avatar:
		"block size-6 rounded-full bg-[var(--surface-container)] ring-2 ring-[var(--sl-color-bg)]",
	fallback:
		"flex size-6 items-center justify-center rounded-full bg-[var(--surface-container)] text-[0.65rem] font-semibold text-[var(--on-surface-variant)] ring-2 ring-[var(--sl-color-bg)]",
} as const;
