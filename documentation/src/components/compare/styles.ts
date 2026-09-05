const clipHorizontal =
	"[clip-path:inset(0_calc(100%_-_var(--compare-pos)_*_1%)_0_0)]";
const clipVertical =
	"[clip-path:inset(0_0_calc(100%_-_var(--compare-pos)_*_1%)_0)]";

const fadeIn =
	"opacity-[clamp(0,calc((var(--compare-pos)_-_var(--compare-fade))_/_4),1)]";
const fadeOut =
	"opacity-[clamp(0,calc((100_-_var(--compare-pos)_-_var(--compare-fade))_/_4),1)]";

export const compareStyles = {
	root: "not-content my-6 w-full",

	frame:
		"relative isolate w-full select-none overflow-hidden rounded-lg border border-[var(--sl-color-hairline-shade)] bg-[var(--surface-container)] [&_img]:m-0 [&_img]:block [&_img]:h-full [&_img]:w-full [&_img]:select-none [&_img]:object-cover [&_img]:pointer-events-none",
	frameHorizontal: "touch-pan-y cursor-ew-resize",
	frameVertical: "touch-pan-x cursor-ns-resize",

	// `clip-path` makes the before layer a stacking context, so without an
	// explicit z-index ladder the after layer paints over it and the slider
	// never appears to move.
	layerAfter: "relative z-0 w-full",

	layerBefore:
		"absolute inset-0 z-10 w-full transition-[clip-path] ease-out duration-[var(--compare-dur)] motion-reduce:transition-none [@media(scripting:none)]:relative [@media(scripting:none)]:[clip-path:none]",
	layerBeforeHorizontal: clipHorizontal,
	layerBeforeVertical: clipVertical,

	label:
		"pointer-events-none absolute z-10 rounded-md bg-black/60 px-2 py-1 font-[family-name:var(--font-sans)] text-xs font-semibold tracking-[0.08em] text-white uppercase shadow-[0_1px_3px_rgba(0,0,0,0.35)] backdrop-blur-[2px] [@media(scripting:none)]:opacity-100",
	labelBeforeHorizontal: `top-3 left-3 ${fadeIn}`,
	labelAfterHorizontal: `top-3 right-3 ${fadeOut}`,
	labelBeforeVertical: `top-3 left-3 ${fadeIn}`,
	labelAfterVertical: `bottom-3 left-3 ${fadeOut}`,

	divider:
		"pointer-events-none absolute z-20 bg-white shadow-[0_0_0_1px_rgba(0,0,0,0.35)] ease-out duration-[var(--compare-dur)] motion-reduce:transition-none [@media(scripting:none)]:hidden",
	dividerHorizontal:
		"top-0 bottom-0 left-[calc(var(--compare-pos)_*_1%)] w-[2px] -translate-x-1/2 transition-[left]",
	dividerVertical:
		"top-[calc(var(--compare-pos)_*_1%)] right-0 left-0 h-[2px] -translate-y-1/2 transition-[top]",

	// The focus ring offset is solid black, not black/40: over a light image a
	// translucent scrim matches the ring's luminance and the indicator vanishes.
	handle:
		"absolute z-30 grid size-11 place-items-center rounded-full bg-white text-[var(--material-grey-900)] shadow-[0_0_0_1px_rgba(0,0,0,0.15),0_2px_10px_rgba(0,0,0,0.35)] ease-out duration-[var(--compare-dur)] motion-reduce:transition-none has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-[var(--color-primary)] has-[:focus-visible]:ring-offset-2 has-[:focus-visible]:ring-offset-black [@media(scripting:none)]:hidden",
	handleHorizontal:
		"top-1/2 left-[calc(var(--compare-pos)_*_1%)] -translate-x-1/2 -translate-y-1/2 cursor-ew-resize transition-[left]",
	handleVertical:
		"top-[calc(var(--compare-pos)_*_1%)] left-1/2 -translate-x-1/2 -translate-y-1/2 cursor-ns-resize transition-[top]",

	grip: "pointer-events-none h-5 w-5",
	gripVertical: "pointer-events-none h-5 w-5 rotate-90",

	input:
		"pointer-events-none absolute inset-0 m-0 size-full appearance-none bg-transparent p-0 opacity-0 focus:outline-none",
} as const;
