// One spec line answers "will it run": six facts as large mono values under
// tiny labels, no boxes or rules. The questions sit below it; the details
// container reserves the height of one open answer so opening a question
// never pushes the section taller on desktop.
export const startStyles = {
	spec: "m-0 grid grid-cols-2 gap-x-6 gap-y-4 sm:grid-cols-3 lg:flex lg:flex-wrap lg:gap-x-12 lg:gap-y-8",
	specItem: "m-0 flex flex-col gap-2",
	specLabel:
		"m-0 font-[family-name:var(--font-sans)] text-xs font-bold uppercase tracking-[0.14em] text-[var(--on-surface-variant)]",
	specValue:
		"m-0 font-[family-name:var(--font-mono)] text-2xl font-bold leading-none tracking-tight text-[var(--sl-color-white)] lg:text-3xl",
	// Padding with matching negative margin gives the link a 44px hit area
	// without moving the line it sits on.
	specLink:
		"-my-2.5 inline-block py-2.5 text-[var(--sl-color-white)] underline decoration-[rgba(var(--color-primary-rgb),0.5)] decoration-2 underline-offset-[0.3em] hover:text-[var(--color-primary)]",

	below:
		"mt-8 grid grid-cols-1 gap-x-12 gap-y-6 lg:mt-12 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]",
	label:
		"m-0 mb-2 font-[family-name:var(--font-sans)] text-xs font-bold uppercase tracking-[0.14em] text-[var(--on-surface-variant)]",
	// `:::details` renders cards; here they flatten into a list separated by
	// hairlines between items only.
	questions:
		"lg:min-h-[19.5rem] [&>details]:my-0 [&>details]:rounded-none [&>details]:border-0 [&>details]:bg-transparent [&>details+details]:border-t [&>details+details]:border-[var(--sl-color-hairline)] [&>details>summary]:rounded-none [&>details>summary]:px-0 [&>details>summary]:py-3.5 [&>details>summary]:text-base lg:[&>details>summary]:py-3 [&>details>summary:hover]:bg-transparent [&>details>summary:hover]:text-[var(--color-primary)] [&>details>div]:max-w-[72ch] [&>details>div]:px-0 [&>details>div]:pt-0 [&>details>div]:pb-4 [&>details>div]:text-sm [&>details>div]:leading-relaxed",
	help: "flex flex-col lg:pt-8",
	helpText:
		"m-0 max-w-[36ch] font-[family-name:var(--font-reading)] text-sm leading-relaxed text-[var(--on-surface-variant)] [&_a]:-my-3 [&_a]:inline-block [&_a]:py-3 [&_a]:text-[var(--color-primary)] [&_a]:underline [&_a]:underline-offset-4",
} as const;
