export const buildStyles = {
	root: "mt-12 grid grid-cols-1 gap-6 lg:mt-16 lg:grid-cols-[minmax(0,2fr)_minmax(0,3fr)] lg:items-start lg:gap-10",

	list: "m-0 flex list-none flex-col gap-1 p-0",
	item: "relative",
	tab: "relative flex w-full cursor-pointer flex-col gap-1 rounded-xl border border-transparent bg-transparent px-4 py-3 text-left transition-colors duration-150 hover:bg-[rgba(var(--color-primary-rgb),0.06)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary motion-reduce:transition-none aria-selected:border-[rgba(var(--color-primary-rgb),0.35)] aria-selected:bg-[rgba(var(--color-primary-rgb),0.08)]",
	tabTitle:
		"font-[family-name:var(--font-sans)] text-base font-bold leading-snug text-[var(--sl-color-white)]",
	tabText:
		"font-[family-name:var(--font-reading)] text-sm leading-relaxed text-[var(--on-surface-variant)] [&>p]:m-0",
	progress:
		"mt-2 h-0.5 w-full overflow-hidden rounded-full bg-[var(--sl-color-hairline)] [&[hidden]]:hidden",
	progressFill:
		"block h-full w-0 rounded-full bg-[var(--color-primary)] [[data-build-running]_&]:animate-[build-progress_var(--build-interval)_linear_forwards] motion-reduce:animate-none",

	media: "mt-3 hidden aspect-[16/10] w-full",

	stage:
		"relative block aspect-[16/10] w-full overflow-hidden rounded-2xl border border-[var(--sl-color-hairline)] bg-[var(--surface-container)]",
	panel:
		"absolute inset-0 transition-opacity duration-300 ease-out motion-reduce:transition-none [&>*]:h-full [&>*]:w-full [&_img]:h-full [&_img]:w-full [&_img]:object-cover",
	panelHidden: "pointer-events-none opacity-0",
	panelActive: "opacity-100",
} as const;
