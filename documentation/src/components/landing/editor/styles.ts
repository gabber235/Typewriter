export const editorStyles = {
	// Phones bleed the screenshot to both edges and keep the legend text on the
	// container's own margin, so the shot is the only thing that touches the edge.
	screenshot:
		"max-sm:-mx-5 max-sm:[&_[data-hotspots-stage]>img]:rounded-none max-sm:[&_[data-hotspots-stage]>img]:border-x-0 max-sm:[&_figcaption]:mx-5 max-sm:[&_[data-hotspot-item]]:px-5 max-sm:[&_[data-hotspot-item]]:text-base",

	// Phones scroll the tiles sideways with the next one peeking past the edge;
	// from `sm` up this is the original stacked grid.
	tiles:
		"mt-8 grid grid-cols-1 gap-5 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary sm:mt-12 md:grid-cols-3 lg:mt-16 max-sm:-mx-5 max-sm:flex max-sm:snap-x max-sm:snap-mandatory max-sm:gap-4 max-sm:overflow-x-auto max-sm:overscroll-x-contain max-sm:scroll-pl-5 max-sm:px-5",
	tile: "flex flex-col gap-4 rounded-2xl border border-[var(--sl-color-hairline)] bg-[var(--surface-container)] p-5 max-sm:w-[87%] max-sm:shrink-0 max-sm:snap-start max-sm:gap-3 max-sm:rounded-none max-sm:border-0 max-sm:bg-transparent max-sm:p-0",
	tileMedia: "w-full [&_[data-compare]]:my-0 [&_figure]:my-0 [&>*]:w-full",
	tileBody:
		"tw-prose font-[family-name:var(--font-reading)] text-sm leading-relaxed text-[var(--sl-color-text)] [&>p]:m-0 [&>p+p]:mt-2",
} as const;
