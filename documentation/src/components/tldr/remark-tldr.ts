import type { List, Root, RootContent } from "mdast";
import type { ContainerDirective } from "mdast-util-directive";
import type {} from "mdast-util-to-hast";
import type { Plugin } from "unified";
import { visit } from "unist-util-visit";
import {
	blockElement,
	html,
	isContainerDirective,
	takeDirectiveLabel,
	text,
} from "../shared/mdast";
import { tldrClasses } from "./styles";

const DEFAULT_TITLE = "TL;DR";

/**
 * `list-style: none` drops the list role in Safari/VoiceOver, and the bullets
 * here are a `::before` dash rather than a marker, so the role is restated.
 */
function keepListSemantics(children: RootContent[]): void {
	visit({ type: "root", children } as Root, "list", (list: List) => {
		if (list.ordered) return;
		list.data = { ...list.data, hProperties: { role: "list" } };
	});
}

function buildHeader(title: string, labelId: string): RootContent {
	return blockElement("div", { class: tldrClasses.header }, [
		blockElement("span", { class: tldrClasses.label, id: labelId }, [
			text(title),
		]),
		html(`<span aria-hidden="true" class="${tldrClasses.rule}"></span>`),
	]);
}

function buildTldr(node: ContainerDirective, labelId: string): RootContent {
	const title = takeDirectiveLabel(node) || DEFAULT_TITLE;
	keepListSemantics(node.children);

	return blockElement(
		"div",
		{
			class: tldrClasses.container,
			// `note` is a section role, not a landmark: it groups the summary for
			// a screen reader without adding one more "complementary" entry to
			// the page's landmark list.
			role: "note",
			"aria-labelledby": labelId,
		},
		[
			buildHeader(title, labelId),
			blockElement("div", { class: tldrClasses.content }, node.children),
		],
	);
}

/**
 * Transforms `:::tldr[Label]` directives into a quiet "key takeaways" card,
 * meant to sit at the top of long pages.
 */
export const remarkTldr: Plugin<[], Root> = () => {
	return (tree) => {
		let blockCount = 0;
		visit(tree, (node, index, parent) => {
			if (!parent || index === undefined || !isContainerDirective(node)) return;
			if (node.name !== "tldr") return;
			blockCount += 1;
			parent.children[index] = buildTldr(node, `tldr-label-${blockCount}`);
		});
	};
};

export default remarkTldr;
