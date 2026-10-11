// A plain row, not a card: no fill, no lines, a chevron at text size in a
// muted colour; the open content lines up with the title text. Brand colour
// only appears in the site-wide focus ring. `border-0` removes Starlight's
// own `details` border-inline-start (the site uses no divider lines).
// Adjacent blocks stack into one list without the gap between them.
export const detailsClasses = {
	container:
		"my-6 scroll-mt-4 rounded-none border-0 bg-transparent ps-0 [&:has(+details)]:mb-0 [details+&]:mt-0 [interpolate-size:allow-keywords] [&::details-content]:[display:flow-root] [&::details-content]:h-0 [&::details-content]:overflow-clip [&::details-content]:opacity-0 [&::details-content]:transition-[content-visibility,height,opacity] [&::details-content]:duration-200 [&::details-content]:ease-out [&::details-content]:[transition-behavior:allow-discrete] [&[open]::details-content]:h-auto [&[open]::details-content]:opacity-100 motion-reduce:[&::details-content]:transition-none motion-reduce:[&::details-content]:duration-0",
	summary:
		"flex list-none cursor-pointer select-none items-center gap-2.5 ms-0 mb-0 px-0 py-3 before:hidden font-sans text-[0.9375rem] font-semibold leading-6 text-[var(--sl-color-white)] decoration-(--on-surface-variant) underline-offset-4 hover:underline [&::-webkit-details-marker]:hidden [&::marker]:hidden",
	// Quieter than the title it sits beside; brightens with the row on hover.
	chevron:
		"size-4 shrink-0 text-(--on-surface-variant) transition-[transform,color] duration-200 ease-out [details[open]>summary_&]:rotate-90 [summary:hover_&]:text-[var(--sl-color-white)] motion-reduce:transition-none",
	title: "min-w-0",
	// Indented to the title text (16px chevron + 10px gap). Both paddings stay
	// non-zero: they stop block margins collapsing out of the animated box.
	content:
		"my-0 ps-[1.625rem] pe-0 pt-1 pb-4 font-[family-name:var(--font-reading)] text-[var(--sl-color-text)] [&>:first-child]:mt-0 [&>:last-child]:mb-0",
} as const;
