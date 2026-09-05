const BASE =
	"inline-flex items-center gap-[0.35em] align-baseline whitespace-nowrap rounded-md border border-[rgba(var(--color-primary-rgb),0.25)] bg-[var(--surface-container)] px-[0.5em] py-[0.2em] font-mono text-[0.9em] not-italic leading-none text-[var(--sl-color-white)]";

const HOVER =
	"transition-colors duration-150 ease-out hover:border-[rgba(var(--color-primary-rgb),0.55)] hover:bg-[rgba(var(--color-primary-rgb),0.12)] motion-reduce:transition-none";

const COPIED =
	"data-[copied=true]:border-[var(--material-green-700)] dark:data-[copied=true]:border-[var(--material-green-400)]";

// `mt-0` defeats Starlight's `.sl-markdown-content :not(…) + :not(…)` prose
// rule, which excludes `span` but not `svg`; `transition` rather than
// `transition-[opacity,transform]` because Tailwind 4 puts `scale` on the
// standalone `scale` property, which `transform` does not cover.
const ICON =
	"col-start-1 row-start-1 mt-0 size-[1em] transition duration-150 ease-out motion-reduce:transition-none";

const HIT_AREA =
	"relative before:absolute before:inset-x-0 before:top-[-2px] before:bottom-[-2px] before:content-['']";

const FOCUS =
	"focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--material-light-blue-800)] dark:focus-visible:outline-[var(--color-primary)]";

export const cmdStyles = {
	chip: `group ${BASE} ${HOVER} ${COPIED} ${HIT_AREA} ${FOCUS} cursor-pointer`,

	staticChip: BASE,

	slash:
		"text-[var(--material-blue-grey-600)] dark:text-[var(--on-surface-variant)]",

	text: "text-inherit",

	iconSlot: "grid size-[1em] shrink-0 place-items-center",

	copyIcon: `${ICON} opacity-70 group-hover:opacity-100 group-data-[copied=true]:scale-50 group-data-[copied=true]:opacity-0`,

	checkIcon: `${ICON} scale-50 text-[var(--material-green-700)] opacity-0 group-data-[copied=true]:scale-100 group-data-[copied=true]:opacity-100 dark:text-[var(--material-green-400)]`,

	// Fixed, so no overflow ancestor can clip it; `cmd.ts` sets left/top.
	tip: "group/tip pointer-events-none fixed top-0 left-0 z-50 translate-y-1 rounded-md bg-[var(--material-green-800)] px-2 py-[0.15rem] font-mono text-xs leading-normal text-[var(--material-white)] opacity-0 shadow-lg transition duration-200 ease-out select-none data-[show=true]:translate-y-0 data-[show=true]:opacity-100 motion-reduce:transition-none",

	tipArrow:
		"absolute -bottom-[3px] size-[6px] rotate-45 rounded-[1px] bg-[var(--material-green-800)] group-data-[flip=true]/tip:top-[-3px] group-data-[flip=true]/tip:bottom-auto",

	liveRegion: "sr-only",
} as const;
