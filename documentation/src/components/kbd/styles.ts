export const kbdStyles = {
	group:
		"inline-flex items-center gap-1 align-baseline whitespace-nowrap font-mono not-italic text-[0.9em] leading-none",

	cap: "inline-flex items-center justify-center min-w-[1.6em] rounded-[0.35em] border border-[var(--sl-color-gray-4)] border-b-2 border-b-[var(--sl-color-gray-3)] bg-[var(--surface-container-lowest)] px-[0.45em] pt-[0.2em] pb-[0.15em] text-[0.9em] font-medium not-italic text-[var(--sl-color-white)] shadow-[0_1px_0_rgba(0,0,0,0.08)]",

	plus: "select-none text-[0.85em] not-italic text-[var(--on-surface-variant)]",

	chord:
		"select-none px-[0.15em] text-[0.8em] not-italic text-[var(--on-surface-variant)]",

	srOnly: "sr-only",
} as const;
