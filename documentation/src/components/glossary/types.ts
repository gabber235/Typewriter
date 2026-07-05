export type GlossaryMode = "all" | "first-per-page" | "first-per-section";

export interface RehypeGlossaryOptions {
	/**
	 * Which occurrences of a term get linked on a page.
	 * - "all": every occurrence (default)
	 * - "first-per-page": only the first occurrence of each term
	 * - "first-per-section": the first occurrence of each term per h2 section
	 */
	mode?: GlossaryMode;
}

export interface TermIndex {
	/** Combined case-insensitive regex over every alias, longest-first. Null when no entries exist. */
	pattern: RegExp | null;
	/** Lowercased alias -> glossary entry slug. */
	aliasToSlug: Map<string, string>;
	/** Glossary entry slug -> display title. */
	slugToTitle: Map<string, string>;
	/** Glossary entry slug -> custom link target from frontmatter, if any. */
	slugToLink: Map<string, string>;
}
