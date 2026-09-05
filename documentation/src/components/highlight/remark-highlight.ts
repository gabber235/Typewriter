import type { PhrasingContent, Root, RootContent } from "mdast";
import type {} from "mdast-util-to-hast";
import type { Plugin } from "unified";
import { SKIP, visit } from "unist-util-visit";
import { element, text } from "../shared/mdast";
import { highlightStyles } from "./styles";

// Loosely mirrors CommonMark flanking: the delimiters must hug the content, so
// `== x ==` and `====` stay literal.
const PATTERN = /==(?![\s=])([\s\S]*?)(?<![\s=])==/g;

/**
 * Turns `==highlighted==` into `<mark>`. Matching is per `text` node, so it
 * never reaches into inline code and `==**bold**==` is not supported.
 */
export const remarkHighlight: Plugin<[], Root> = () => {
	return (tree) => {
		visit(tree, "text", (node, index, parent) => {
			if (!parent || index === undefined) return;

			const nodes = split(node.value);
			if (!nodes) return;

			(parent.children as RootContent[]).splice(index, 1, ...nodes);
			return [SKIP, index + nodes.length];
		});
	};
};

function split(value: string): PhrasingContent[] | null {
	if (!value.includes("==")) return null;

	const nodes: PhrasingContent[] = [];
	let cursor = 0;
	for (const match of value.matchAll(PATTERN)) {
		if (match.index > cursor) {
			nodes.push(text(value.slice(cursor, match.index)));
		}
		nodes.push(mark(match[1]));
		cursor = match.index + match[0].length;
	}

	if (nodes.length === 0) return null;
	if (cursor < value.length) nodes.push(text(value.slice(cursor)));
	return nodes;
}

function mark(value: string): PhrasingContent {
	return element("mark", { class: highlightStyles.mark }, [text(value)]);
}
