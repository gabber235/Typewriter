import type { Root } from "hast";
import { h } from "hastscript";
import type { Plugin } from "unified";
import { BASE_PATH } from "../../base-path";
import { glossaryStyles } from "./styles";
import { loadTermIndex } from "./term-index";
import type { GlossaryMode, RehypeGlossaryOptions, TermIndex } from "./types";

/**
 * Rehype plugin that links glossary terms in rendered docs pages.
 *
 * Wraps text matching a glossary alias in an anchor to /glossary/#slug with
 * `data-glossary-term`, which the client popover (popover.ts) uses to show a
 * hover card. Runs on hast (after Starlight's own plugins) so it works
 * identically for .md and .mdx pages.
 */

// Subtrees that must never contain term links.
const SKIP_TAGS = new Set([
	"code",
	"pre",
	"a",
	"h1",
	"h2",
	"h3",
	"h4",
	"h5",
	"h6",
	"script",
	"style",
	"svg",
]);

/**
 * Pragmatic node shape covering hast elements/text plus the MDX JSX nodes
 * (mdxJsxFlowElement/mdxJsxTextElement) that appear in .mdx trees.
 */
interface WalkNode {
	type: string;
	tagName?: string;
	value?: string;
	properties?: Record<string, unknown>;
	attributes?: Array<{ name?: string }>;
	children?: WalkNode[];
}

interface MatchContext {
	index: TermIndex;
	mode: GlossaryMode;
	/** Slugs already linked in the current page/section. */
	seen: Set<string>;
}

export const rehypeGlossary: Plugin<[RehypeGlossaryOptions?], Root> = (
	options = {},
) => {
	const mode = options.mode ?? "all";
	return (tree, file) => {
		// Never link terms inside the glossary entries themselves (the hover
		// cards and index page render them through this same pipeline).
		const path = String(file.path ?? "").replaceAll("\\", "/");
		if (path.includes("/content/glossary/")) return;

		// Per-page opt-out via `glossary: false` frontmatter.
		const astroData = (
			file.data as {
				astro?: { frontmatter?: Record<string, unknown> };
			}
		).astro;
		if (astroData?.frontmatter?.glossary === false) return;

		const index = loadTermIndex();
		if (!index.pattern) return;

		walk(tree as unknown as WalkNode, { index, mode, seen: new Set() });
	};
};

function walk(node: WalkNode, ctx: MatchContext): void {
	const children = node.children;
	if (!children) return;

	for (let i = 0; i < children.length; i++) {
		const child = children[i];
		if (!child) continue;

		if (child.type === "element") {
			if (ctx.mode === "first-per-section" && child.tagName === "h2") {
				ctx.seen.clear();
			}
			if (child.tagName && SKIP_TAGS.has(child.tagName)) continue;
			if (child.properties?.dataGlossarySkip !== undefined) continue;
			walk(child, ctx);
			continue;
		}

		// Descend into MDX JSX wrappers (<Tabs>, <Steps>, ...) — their text
		// children are ordinary hast nodes by this point.
		if (
			child.type === "mdxJsxFlowElement" ||
			child.type === "mdxJsxTextElement"
		) {
			if (child.attributes?.some((a) => a.name === "data-glossary-skip"))
				continue;
			walk(child, ctx);
			continue;
		}

		if (child.type !== "text" || typeof child.value !== "string") continue;

		const replacement = linkify(child.value, ctx);
		if (!replacement) continue;
		children.splice(i, 1, ...replacement);
		i += replacement.length - 1;
	}
}

function linkify(value: string, ctx: MatchContext): WalkNode[] | null {
	const { pattern, aliasToSlug, slugToTitle, slugToLink } = ctx.index;
	if (!pattern) return null;
	pattern.lastIndex = 0;

	const out: WalkNode[] = [];
	let last = 0;
	for (const match of value.matchAll(pattern)) {
		const matched = match[0];
		const slug = aliasToSlug.get(matched.toLowerCase());
		if (!slug) continue;
		if (ctx.mode !== "all" && ctx.seen.has(slug)) continue;
		ctx.seen.add(slug);

		if (match.index > last) {
			out.push({ type: "text", value: value.slice(last, match.index) });
		}
		// A frontmatter `link` overrides the glossary-page target. Site-absolute
		// links get the base path prepended; external URLs pass through.
		const custom = slugToLink.get(slug);
		const href = custom
			? custom.startsWith("/")
				? `${BASE_PATH}${custom.slice(1)}`
				: custom
			: `${BASE_PATH}glossary/#${slug}`;
		out.push(
			h(
				"a",
				{
					href,
					class: glossaryStyles.term,
					"data-glossary-term": slug,
					"data-glossary-title": slugToTitle.get(slug),
				},
				// Keep the author's casing ("Entries" stays "Entries").
				matched,
			) as unknown as WalkNode,
		);
		last = match.index + matched.length;
	}

	if (out.length === 0) return null;
	if (last < value.length) {
		out.push({ type: "text", value: value.slice(last) });
	}
	return out;
}

export default rehypeGlossary;
