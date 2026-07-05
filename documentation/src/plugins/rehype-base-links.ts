import type { Root } from "hast";
import type { Plugin } from "unified";
import { visit } from "unist-util-visit";
import { BASE_PATH } from "../base-path";

/**
 * Astro only base-prefixes hrefs *it* generates (sidebar, pagination,
 * glossary auto-links, ...). A hand-authored Markdown link like
 * `[Home](/)` or `[page](/glossary/#page)` stays exactly as written, so it
 * silently breaks whenever the site builds with a non-root `base` (e.g. PR
 * preview deploys at `/branches/pr-123/`). This rewrites any root-absolute
 * `<a href>` produced from content to carry the configured base path.
 */
export const rehypeBaseLinks: Plugin<[], Root> = () => {
	// Default local dev/build: base is "/", so every root-absolute href
	// already "has" the base — nothing to rewrite.
	if (BASE_PATH === "/") return () => {};

	return (tree) => {
		visit(tree, "element", (node) => {
			if (node.tagName !== "a" || !node.properties) return;
			const href = node.properties.href;
			if (typeof href !== "string") return;
			// Skip relative links, protocol-relative/external URLs, and anything
			// already carrying the base path.
			if (!href.startsWith("/") || href.startsWith("//")) return;
			if (href.startsWith(BASE_PATH)) return;
			node.properties.href = `${BASE_PATH}${href.slice(1)}`;
		});
	};
};

export default rehypeBaseLinks;
