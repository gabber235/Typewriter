import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import matter from "gray-matter";
import type { TermIndex } from "./types";

/**
 * Build-time index of glossary terms, read straight from the content folder.
 *
 * Rehype plugins run inside the markdown pipeline where `getCollection` is not
 * available, so the frontmatter is parsed here with gray-matter instead. The
 * index is cached on an mtime fingerprint: editing a glossary file refreshes
 * it, but docs pages that were already rendered only re-run rehype when they
 * are touched or the dev server restarts.
 */

const GLOSSARY_DIR = fileURLToPath(
	new URL("../../content/glossary/", import.meta.url),
);

let cache: { fingerprint: string; index: TermIndex } | null = null;

export function loadTermIndex(): TermIndex {
	let files: string[] = [];
	try {
		files = readdirSync(GLOSSARY_DIR).filter((name) =>
			/\.(md|mdx)$/.test(name),
		);
	} catch {
		return {
			pattern: null,
			aliasToSlug: new Map(),
			slugToTitle: new Map(),
			slugToLink: new Map(),
		};
	}

	const fingerprint = files
		.map((name) => `${name}:${statSync(join(GLOSSARY_DIR, name)).mtimeMs}`)
		.join("|");
	if (cache && cache.fingerprint === fingerprint) return cache.index;

	const aliasToSlug = new Map<string, string>();
	const slugToTitle = new Map<string, string>();
	const slugToLink = new Map<string, string>();
	for (const name of files) {
		const { data } = matter(readFileSync(join(GLOSSARY_DIR, name), "utf8"));
		const slug = name.replace(/\.(md|mdx)$/, "");
		slugToTitle.set(slug, typeof data.title === "string" ? data.title : slug);
		if (typeof data.link === "string" && data.link.length > 0) {
			slugToLink.set(slug, data.link);
		}

		const aliases = Array.isArray(data.aliases) ? data.aliases : [];
		for (const alias of aliases) {
			if (typeof alias !== "string" || alias.length === 0) continue;
			const key = alias.toLowerCase();
			const existing = aliasToSlug.get(key);
			if (existing && existing !== slug) {
				console.warn(
					`[glossary] alias "${alias}" is claimed by both "${existing}" and "${slug}"; keeping "${existing}"`,
				);
				continue;
			}
			aliasToSlug.set(key, slug);
		}
	}

	// Longest-first so "entry trigger" wins over "entry" in the alternation.
	const escaped = [...aliasToSlug.keys()]
		.sort((a, b) => b.length - a.length)
		.map((alias) => alias.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
	// Lookarounds instead of \b so hyphenated words ("entry-point") don't half-match.
	const pattern =
		escaped.length > 0
			? new RegExp(`(?<![\\w-])(?:${escaped.join("|")})(?![\\w-])`, "gi")
			: null;

	cache = {
		fingerprint,
		index: { pattern, aliasToSlug, slugToTitle, slugToLink },
	};
	return cache.index;
}
