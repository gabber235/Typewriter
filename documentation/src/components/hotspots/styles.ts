// White on the dark theme's primary (#009fff) is 2.8:1; grey-900 on it is 5.7:1.
const badgeCore =
	"flex shrink-0 select-none items-center justify-center rounded-full bg-primary font-[family-name:var(--font-sans)] text-xs font-bold leading-none text-white dark:text-[var(--material-grey-900)]";
const badge = `${badgeCore} ring-2 ring-white shadow-[0_1px_4px_rgba(0,0,0,0.45)]`;

const richText =
	"[&>p]:my-0 [&_p+p]:mt-2 [&_a]:text-primary [&_a]:underline [&_a]:underline-offset-2 [&_strong]:font-semibold [&_strong]:text-[var(--sl-color-white)] [&_code]:rounded-sm [&_code]:bg-[var(--sl-color-bg-inline-code)] [&_code]:px-1 [&_code]:py-0.5 [&_code]:font-[family-name:var(--font-mono)] [&_code]:text-[0.85em]";

const pinBase = `${badge} absolute z-10 m-0 -translate-x-1/2 -translate-y-1/2 cursor-pointer touch-manipulation border-0 p-0 transition-[scale,box-shadow] duration-150 after:absolute after:-inset-2 after:rounded-full after:content-[''] hover:scale-110 data-active:scale-110 data-active:shadow-[0_0_0_5px_rgba(var(--color-primary-rgb),0.35)] aria-expanded:scale-110 aria-expanded:shadow-[0_0_0_5px_rgba(var(--color-primary-rgb),0.35)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--material-light-blue-900)] motion-reduce:transition-none [[data-hotspots-broken]_&]:hidden`;

const legendLayout = "flex list-none flex-col gap-1";

// Each fallback selector is one compound deeper than the bare `sr-only`, so
// it wins on specificity no matter how Tailwind orders the rules.
const legendFallbacks =
	"[html:not(.hotspots-js)_&]:not-sr-only [[data-hotspots-broken]_&]:not-sr-only [[data-hotspots-narrow]_&]:not-sr-only";

export const hotspotStyles = {
	figure: "not-content mx-0 my-6 flex flex-col gap-3",

	// `w-fit` makes the stage hug the image so percentage pins map onto it.
	stage:
		"relative block w-fit max-w-full leading-none [&>img]:block [&>img]:h-auto [&>img]:max-w-full [&>img]:rounded-lg [&>img]:border [&>img]:border-[var(--sl-color-hairline-shade)] [[data-hotspots-broken]_&]:w-full [[data-hotspots-broken]_&>img]:aspect-auto [[data-hotspots-broken]_&>img]:w-full [[data-hotspots-broken]_&>img]:border-dashed [[data-hotspots-broken]_&>img]:border-[rgba(var(--color-primary-rgb),0.35)] [[data-hotspots-broken]_&>img]:bg-[rgba(var(--color-primary-rgb),0.04)] [[data-hotspots-broken]_&>img]:p-4 [[data-hotspots-broken]_&>img]:font-[family-name:var(--font-sans)] [[data-hotspots-broken]_&>img]:text-xs [[data-hotspots-broken]_&>img]:leading-normal [[data-hotspots-broken]_&>img]:text-[var(--on-surface-variant)]",

	pin: `${pinBase} h-7 w-7`,
	pinDot: `${pinBase} h-4 w-4`,
	pinLabel: "relative",
	ping: "pointer-events-none absolute inset-0 rounded-full bg-primary opacity-0",

	caption:
		"m-0 max-w-[46rem] border-l-2 border-[rgba(var(--color-primary-rgb),0.35)] pl-3 font-[family-name:var(--font-sans)] text-xs leading-relaxed text-[var(--on-surface-variant)]",

	legend: `sr-only ${legendLayout} ${legendFallbacks}`,
	legendVisible: `m-0 p-0 ${legendLayout}`,

	item: "flex items-start gap-3 rounded-lg border border-transparent px-3 py-2 text-sm leading-relaxed text-[var(--sl-color-text)] transition-colors duration-150 hover:bg-[rgba(var(--color-primary-rgb),0.06)] data-active:border-[rgba(var(--color-primary-rgb),0.3)] data-active:bg-[rgba(var(--color-primary-rgb),0.1)] motion-reduce:transition-none",
	itemBadge: `${badge} mt-0.5 h-6 w-6`,
	itemDot: `${badge} mt-1.5 h-3 w-3`,
	itemContent: `min-w-0 flex-1 ${richText}`,

	popover:
		"fixed z-50 w-max max-w-[22rem] rounded-xl border border-[rgba(var(--color-primary-rgb),0.3)] bg-[var(--surface-container)] p-4 text-left shadow-xl shadow-primary/5 transition-[opacity,translate] duration-200 ease-out starting:translate-y-1 starting:opacity-0 motion-reduce:transition-none [&[hidden]]:hidden before:absolute before:left-[var(--hs-arrow-x)] before:h-3 before:w-3 before:-translate-x-1/2 before:rotate-45 before:border before:border-[rgba(var(--color-primary-rgb),0.3)] before:bg-[var(--surface-container)] before:content-[''] data-[placement=bottom]:before:-top-[7px] data-[placement=bottom]:before:border-r-0 data-[placement=bottom]:before:border-b-0 data-[placement=top]:before:-bottom-[7px] data-[placement=top]:before:border-l-0 data-[placement=top]:before:border-t-0",
	// Scrolling lives on the inner box so `overflow` never clips the arrow.
	popoverInner:
		"flex max-h-[min(22rem,60vh)] items-start gap-3 overflow-y-auto overscroll-contain",
	// No ring or shadow: the inner box's overflow clipping would cut them off.
	popoverBadge: `${badgeCore} mt-0.5 h-6 w-6 [&[hidden]]:hidden`,
	popoverBody: `min-w-0 flex-1 font-[family-name:var(--font-reading)] text-sm leading-relaxed text-[var(--sl-color-text)] ${richText}`,
} as const;
