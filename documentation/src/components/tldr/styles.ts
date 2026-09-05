export const tldrClasses = {
	container:
		"my-6 rounded-lg border border-[var(--sl-color-gray-5)] border-t-[rgba(var(--color-primary-rgb),0.7)] bg-[var(--on-surface-variant)]/5 px-4 py-3.5 sm:px-5 sm:py-4",
	header: "mb-2.5 flex items-baseline gap-3",
	label:
		"shrink-0 font-sans text-xs font-[650] tracking-[0.08em] text-[var(--on-surface-variant)]",
	rule: "h-px flex-1 translate-y-[-0.25em] bg-[var(--sl-color-gray-5)]/70",
	content:
		"font-[family-name:var(--font-reading)] text-[0.9375rem] leading-6 text-[var(--sl-color-text)] [&>:first-child]:mt-0 [&>:last-child]:mb-0 [&_p]:my-2 [&_ol]:my-2 [&_ol]:ps-5 [&_ul]:my-2 [&_ul]:list-none [&_ul]:ps-0 [&_li]:my-1 [&_ol_li]:marker:font-[family-name:var(--font-sans)] [&_ol_li]:marker:text-[var(--on-surface-variant)] [&_ul>li]:relative [&_ul>li]:ps-4 [&_ul>li]:before:absolute [&_ul>li]:before:start-0 [&_ul>li]:before:top-[0.6875em] [&_ul>li]:before:h-[2px] [&_ul>li]:before:w-[7px] [&_ul>li]:before:rounded-full [&_ul>li]:before:bg-[rgba(var(--color-primary-rgb),0.65)] [&_ul>li]:before:content-['']",
} as const;
