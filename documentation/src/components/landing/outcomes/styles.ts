export const buildStyles = {
	root: "mt-8 grid grid-cols-1 gap-5 lg:mt-16 lg:grid-cols-[minmax(0,2fr)_minmax(0,3fr)] lg:items-start lg:gap-10",

	// Phones get a segmented strip: the four labels sit in row one, the four
	// descriptions share row two, so swapping tabs never changes the height.
	list: "m-0 list-none p-0 max-lg:grid max-lg:grid-cols-4 max-lg:gap-x-0 max-lg:gap-y-4 lg:flex lg:flex-col lg:gap-1",
	item: "relative max-lg:contents lg:flex lg:flex-col lg:gap-1 lg:rounded-xl lg:border lg:border-transparent lg:px-4 lg:py-3 lg:transition-colors lg:duration-150 lg:hover:bg-[rgba(var(--color-primary-rgb),0.06)] lg:has-[:focus-visible]:outline-2 lg:has-[:focus-visible]:outline-offset-2 lg:has-[:focus-visible]:outline-primary lg:has-[[aria-selected=true]]:border-[rgba(var(--color-primary-rgb),0.35)] lg:has-[[aria-selected=true]]:bg-[rgba(var(--color-primary-rgb),0.08)] motion-reduce:transition-none",
	tab: "group peer flex w-full cursor-pointer border-0 bg-transparent p-0 text-left max-lg:min-h-11 max-lg:items-center max-lg:justify-center max-lg:px-1 max-lg:text-center max-lg:shadow-[inset_0_-2px_0_var(--sl-color-hairline)] max-lg:transition-shadow max-lg:duration-150 max-lg:focus-visible:outline-2 max-lg:focus-visible:outline-offset-2 max-lg:focus-visible:outline-primary max-lg:aria-selected:shadow-[inset_0_-2px_0_var(--color-primary)] lg:after:absolute lg:after:inset-0 lg:after:rounded-xl lg:after:content-[''] motion-reduce:transition-none",
	tabTitle:
		"font-[family-name:var(--font-sans)] text-base font-bold leading-snug text-[var(--sl-color-white)] max-lg:text-xs max-lg:leading-none max-lg:group-aria-selected:text-[var(--color-primary)] sm:max-lg:text-sm",
	tabText:
		"font-[family-name:var(--font-reading)] text-base leading-relaxed text-[var(--on-surface-variant)] [&>p]:m-0 max-lg:col-span-4 max-lg:col-start-1 max-lg:row-start-2 max-lg:invisible max-lg:opacity-0 max-lg:transition-opacity max-lg:duration-300 max-lg:peer-aria-selected:visible max-lg:peer-aria-selected:opacity-100 lg:text-sm motion-reduce:transition-none",
	progress:
		"mt-2 h-0.5 w-full overflow-hidden rounded-full bg-[var(--sl-color-hairline)] max-lg:hidden [&[hidden]]:hidden",
	progressFill:
		"block h-full w-0 rounded-full bg-[var(--color-primary)] [[data-build-running]_&]:animate-[build-progress_var(--build-interval)_linear_forwards] motion-reduce:animate-none",

	media: "mt-3 hidden aspect-[16/10] w-full",

	stage:
		"relative block aspect-[16/10] w-full overflow-hidden rounded-2xl border border-[var(--sl-color-hairline)] bg-[var(--surface-container)] max-lg:order-first",
	panel:
		"absolute inset-0 transition-opacity duration-300 ease-out motion-reduce:transition-none [&>*]:h-full [&>*]:w-full [&_img]:h-full [&_img]:w-full [&_img]:object-cover",
	panelHidden: "pointer-events-none opacity-0",
	panelActive: "opacity-100",
} as const;
