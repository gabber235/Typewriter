export interface TermIndex {
	/** Lowercased alias -> glossary entry slug. */
	aliasToSlug: Map<string, string>;
	/** Glossary entry slug -> display title. */
	slugToTitle: Map<string, string>;
	/** Glossary entry slug -> custom link target from frontmatter, if any. */
	slugToLink: Map<string, string>;
}
