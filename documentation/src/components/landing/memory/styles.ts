// Facts are the purple entries in the panel; changed ledger values borrow it.
const purple =
	"text-[var(--material-deep-purple-200)] [[data-theme=light]_&]:text-[var(--material-deep-purple-700)]";
const purpleEdge =
	"border-[var(--material-deep-purple-300)] [[data-theme=light]_&]:border-[var(--material-deep-purple-500)]";

// Type scale, largest first: NPC line 1.125rem, reply/heading 1rem,
// ledger 0.875rem, cues and labels 0.7rem.
export const memoryStyles = {
	script: "mt-2",
	columns:
		"grid grid-cols-1 gap-x-12 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]",
	head: "hidden pb-3 lg:block",
	headTitle:
		"m-0 font-[family-name:var(--font-sans)] text-[0.7rem] font-bold uppercase tracking-[0.14em] text-[var(--on-surface-variant)]",
	headNote: `m-0 mt-1 font-[family-name:var(--font-reading)] text-sm text-[var(--on-surface-variant)] [&>b]:font-semibold [&>b]:${purple}`,
	beats: "m-0 list-none p-0 lg:col-span-2",
	beat: "grid grid-cols-1 gap-x-12 gap-y-6 border-t border-[var(--sl-color-hairline)] pt-5 pb-10 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)] lg:pb-12",
	when: "m-0 font-[family-name:var(--font-sans)] text-base font-bold uppercase tracking-[0.12em] text-[var(--sl-color-white)] lg:col-span-2",
	where: "font-normal text-[var(--on-surface-variant)]",
	// NPC turns sit left, the player's answers right, like a chat log.
	dialogue: "flex w-full max-w-[36rem] flex-col gap-7",
	turnNpc: "max-w-[88%] self-start",
	turnPlayer: "max-w-[88%] self-end text-right",
	cue: "m-0 mb-1 font-[family-name:var(--font-mono)] text-[0.7rem] font-bold uppercase tracking-[0.16em]",
	cueSpeaker:
		"text-[var(--material-orange-300)] [[data-theme=light]_&]:text-[var(--material-deep-orange-900)]",
	cuePlayer: "text-[var(--on-surface-variant)]",
	line: "m-0 font-[family-name:var(--font-mono)] text-lg leading-relaxed text-[var(--sl-color-white)]",
	reply:
		"m-0 font-[family-name:var(--font-mono)] text-base leading-relaxed text-[var(--sl-color-text)]",
	ledger:
		"self-start font-[family-name:var(--font-mono)] text-sm max-lg:border-t max-lg:border-dashed max-lg:border-[var(--sl-color-hairline)] max-lg:pt-5 lg:mt-7 lg:max-w-[24rem]",
	ledgerLabel:
		"m-0 mb-3 font-[family-name:var(--font-sans)] text-[0.7rem] font-bold uppercase tracking-[0.14em] text-[var(--on-surface-variant)] lg:hidden",
	rows: "m-0 flex flex-col gap-2.5",
	row: "border-l-2 border-transparent ps-3 text-[var(--sl-color-white)]",
	rowChanged: purpleEdge,
	rowMuted: "text-[var(--on-surface-variant)]",
	valueChanged: `font-bold ${purple}`,

	recall:
		"mt-4 grid grid-cols-1 gap-x-12 gap-y-8 border-t border-[var(--sl-color-hairline)] pt-10 lg:grid-cols-[minmax(0,2fr)_minmax(0,3fr)] lg:pt-12",
	recallHeader: "flex flex-col gap-3",
	recallList: "m-0 flex flex-col",
	recallItem:
		"grid grid-cols-1 gap-x-8 gap-y-1 border-b border-[var(--sl-color-hairline)] py-4 first:pt-0 sm:grid-cols-[11rem_minmax(0,1fr)]",
	recallTitle:
		"m-0 font-[family-name:var(--font-sans)] text-base font-bold text-[var(--sl-color-white)]",
	recallBody:
		"m-0 max-w-[60ch] font-[family-name:var(--font-reading)] text-sm leading-relaxed text-[var(--on-surface-variant)]",
} as const;
