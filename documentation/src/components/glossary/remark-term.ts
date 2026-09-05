import type { Root } from "mdast";
import type {} from "mdast-util-directive";
import type {} from "mdast-util-to-hast";
import type { Plugin } from "unified";
import type { Data } from "unist";
import { SKIP, visit } from "unist-util-visit";
import { BASE_PATH } from "../../lib/base-path";
import { textOf } from "../shared/mdast";
import { glossaryStyles } from "./styles";
import { loadTermIndex } from "./term-index";
import type { TermIndex } from "./types";

/**
 * Turns `:term[entries]` into a glossary link with a hover card. The label is
 * matched against the glossary aliases; `:term[any wording]{as=entry}` names
 * the entry explicitly. Unknown terms render as plain text and warn.
 */
export const remarkTerm: Plugin<[], Root> = () => {
	return (tree, file) => {
		const index = loadTermIndex();
		const origin = file.path ?? "<unknown file>";

		visit(tree, "textDirective", (node) => {
			if (node.name !== "term") return;

			const label = textOf(node.children).trim();
			const slug = findSlug(index, label, node.attributes?.as?.trim());
			if (!slug) {
				console.warn(
					`[remark-term] unknown glossary term ":term[${label}]" in ${origin}`,
				);
				node.data = { hName: "span" };
				return SKIP;
			}

			node.data = linkData(index, slug);
			return SKIP;
		});
	};
};

function findSlug(
	index: TermIndex,
	label: string,
	explicit: string | undefined,
): string | undefined {
	if (!explicit) return index.aliasToSlug.get(label.toLowerCase());
	const key = explicit.toLowerCase();
	if (index.slugToTitle.has(key)) return key;
	return index.aliasToSlug.get(key);
}

function linkData(index: TermIndex, slug: string): Data {
	return {
		hName: "a",
		hProperties: {
			href: hrefFor(slug, index.slugToLink.get(slug)),
			class: glossaryStyles.term,
			dataGlossaryTerm: slug,
			dataGlossaryTitle: index.slugToTitle.get(slug),
		},
	};
}

function hrefFor(slug: string, custom: string | undefined): string {
	if (!custom) return `${BASE_PATH}glossary/#${slug}`;
	if (custom.startsWith("/")) return `${BASE_PATH}${custom.slice(1)}`;
	return custom;
}
