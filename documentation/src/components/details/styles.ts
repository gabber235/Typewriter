export const detailsClasses = {
	container:
		"my-4 scroll-mt-4 rounded-lg border border-[var(--sl-color-gray-5)] bg-[var(--surface-container)]/40 ps-0 [interpolate-size:allow-keywords] [&::details-content]:[display:flow-root] [&::details-content]:h-0 [&::details-content]:overflow-clip [&::details-content]:opacity-0 [&::details-content]:transition-[content-visibility,height,opacity] [&::details-content]:duration-200 [&::details-content]:ease-out [&::details-content]:[transition-behavior:allow-discrete] [&[open]::details-content]:h-auto [&[open]::details-content]:opacity-100 motion-reduce:[&::details-content]:transition-none motion-reduce:[&::details-content]:duration-0",
	summary:
		"flex list-none cursor-pointer select-none items-center gap-2 rounded-lg ms-0 mb-0 px-4 py-2.5 font-semibold before:hidden font-sans text-[var(--sl-color-white)] transition-colors duration-150 hover:bg-[rgba(var(--color-primary-rgb),0.08)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--material-light-blue-800)] dark:focus-visible:outline-[var(--color-primary)] [&::-webkit-details-marker]:hidden [&::marker]:hidden",
	chevron:
		"shrink-0 text-[var(--on-surface-variant)] transition-transform duration-200 [details[open]_&]:rotate-90 motion-reduce:transition-none",
	title: "font-semibold",
	content:
		"my-0 px-4 py-3 font-[family-name:var(--font-reading)] text-[var(--sl-color-text)] [&>:first-child]:mt-0 [&>:last-child]:mb-0",
} as const;
