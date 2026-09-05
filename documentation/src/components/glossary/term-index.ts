import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import matter from "gray-matter";
import type { TermIndex } from "./types";

const GLOSSARY_DIR = fileURLToPath(
	new URL("../../content/glossary/", import.meta.url),
);
const MARKDOWN = /\.(md|mdx)$/;

let cache: { fingerprint: string; index: TermIndex } | null = null;

/**
 * Build-time index of glossary terms. Remark plugins run inside the markdown
 * pipeline where `getCollection` is unavailable, so frontmatter is read with
 * gray-matter and cached on an mtime fingerprint of the glossary folder.
 */
export function loadTermIndex(): TermIndex {
	const files = listGlossaryFiles();
	const fingerprint = files
		.map((name) => `${name}:${statSync(join(GLOSSARY_DIR, name)).mtimeMs}`)
		.join("|");
	if (cache?.fingerprint === fingerprint) return cache.index;

	const index = buildIndex(files);
	cache = { fingerprint, index };
	return index;
}

function listGlossaryFiles(): string[] {
	try {
		return readdirSync(GLOSSARY_DIR).filter((name) => MARKDOWN.test(name));
	} catch {
		return [];
	}
}

function buildIndex(files: string[]): TermIndex {
	const aliasToSlug = new Map<string, string>();
	const slugToTitle = new Map<string, string>();
	const slugToLink = new Map<string, string>();

	for (const name of files) {
		const { data } = matter(readFileSync(join(GLOSSARY_DIR, name), "utf8"));
		const slug = name.replace(MARKDOWN, "");
		slugToTitle.set(slug, typeof data.title === "string" ? data.title : slug);
		if (typeof data.link === "string" && data.link.length > 0) {
			slugToLink.set(slug, data.link);
		}
		addAliases(aliasToSlug, data.aliases, slug);
	}

	return { aliasToSlug, slugToTitle, slugToLink };
}

function addAliases(
	aliasToSlug: Map<string, string>,
	aliases: unknown,
	slug: string,
): void {
	if (!Array.isArray(aliases)) return;

	for (const alias of aliases) {
		if (typeof alias !== "string" || alias.length === 0) continue;
		const key = alias.toLowerCase();
		const owner = aliasToSlug.get(key);
		if (owner === undefined || owner === slug) {
			aliasToSlug.set(key, slug);
			continue;
		}
		console.warn(
			`[glossary] alias "${alias}" is claimed by both "${owner}" and "${slug}"; keeping "${owner}"`,
		);
	}
}
