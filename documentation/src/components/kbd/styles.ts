// Copies the 1.0 panel's solid key cap (panel/lib/shared/ui/components/
// shortcut_display.dart, `_KeyDisplay` + `KeyStyle.solid()` at size 12):
// one cap per key 4px apart, no visible "+"; 20px tall, at least 20px wide,
// 4px padding and radius; JetBrains Mono 12px bold, 0.5px tracking; no
// border, a hard ledge underneath (2px light, 3px dark). Colours are the
// panel's surfaceContainerHighest / onSurface / ledge, computed from its
// fromSeed(#62646A) scheme. Sizes are px like the panel, not em.
export const kbdStyles = {
	// Baseline, not middle: the cap's letters sit on the text's baseline, and
	// `middle` placed groups inconsistently on tall reading lines.
	group:
		"inline-flex items-center gap-1 align-baseline whitespace-nowrap not-italic leading-none",

	cap: "inline-flex h-5 min-w-5 items-center justify-center rounded px-1 font-(family-name:--font-mono) text-xs leading-none font-bold tracking-[0.5px] not-italic bg-[#E1E2E9] text-[#191C20] shadow-[0_2px_0_#C7C8D5] transition-[background-color,color,box-shadow] duration-200 dark:bg-[#33353A] dark:text-[#E1E2E9] dark:shadow-[0_3px_0_#1E1F23] forced-colors:border forced-colors:border-solid",

	// The panel shows no "+"; screen readers still hear "Control plus S".
	plus: "sr-only",

	chord:
		"select-none px-0.5 font-(family-name:--font-mono) text-xs leading-none not-italic text-(--on-surface-variant)",

	srOnly: "sr-only",
} as const;
