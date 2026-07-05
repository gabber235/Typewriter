export const glossaryStyles = {
	term: "underline decoration-dotted decoration-[var(--color-primary)] underline-offset-4 cursor-help text-inherit hover:decoration-solid",

	// Hover card: tinted border + deep shadow so it reads as an overlay, not
	// part of the page. `starting:` animates the reveal when `hidden` is
	// removed (@starting-style; older browsers just show it).
	card: "fixed z-50 w-max max-w-[24rem] max-h-[60vh] overflow-y-auto rounded-xl border border-[rgba(var(--color-primary-rgb),0.3)] bg-[var(--surface-container)] p-5 shadow-xl shadow-primary/5 text-sm transition-[opacity,transform] duration-200 ease-out starting:opacity-0 starting:translate-y-1",
	cardTitle:
		"mb-1 pb-1 border-b border-[var(--sl-color-hairline-shade)] text-base font-bold text-primary",
	cardBody: "text-[var(--sl-color-text)] leading-relaxed text-xs",

	// Glossary index page: entries render as regular docs headings + prose so
	// the page matches the rest of the site; only the alias chips are custom.
	entrySection: "scroll-mt-24",
	entryAliases: "flex flex-wrap gap-2",
} as const;
