export const editorStyles = {
	tiles: "mt-12 grid grid-cols-1 gap-5 md:grid-cols-3 lg:mt-16",
	tile: "flex flex-col gap-4 rounded-2xl border border-[var(--sl-color-hairline)] bg-[var(--surface-container)] p-5",
	tileMedia: "w-full [&_[data-compare]]:my-0 [&_figure]:my-0 [&>*]:w-full",
	tileBody:
		"tw-prose font-[family-name:var(--font-reading)] text-sm leading-relaxed text-[var(--sl-color-text)] [&>p]:m-0 [&>p+p]:mt-2",
} as const;
