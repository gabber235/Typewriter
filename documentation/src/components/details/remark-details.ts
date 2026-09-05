import type { Root, RootContent } from "mdast";
import type { ContainerDirective } from "mdast-util-directive";
import type { Plugin } from "unified";
import { visit } from "unist-util-visit";
import {
	blockElement,
	html,
	isContainerDirective,
	takeDirectiveLabel,
	text,
} from "../shared/mdast";
import { detailsClasses } from "./styles";

const DEFAULT_TITLE = "Details";

// The chevron duplicates the open state the UA already exposes on <details>,
// so it is hidden from assistive technology.
const CHEVRON_ICON = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" focusable="false" class="${detailsClasses.chevron}"><path d="M9.29 6.71a1 1 0 0 0 0 1.41L13.17 12l-3.88 3.88a1 1 0 1 0 1.41 1.41l4.59-4.59a1 1 0 0 0 0-1.41L10.7 6.7a1 1 0 0 0-1.41.01z"/></svg>`;

function isOpen(
	attributes: Record<string, string | null | undefined>,
): boolean {
	if (!("open" in attributes)) return false;
	return attributes.open !== "false";
}

function buildSummary(title: string): RootContent {
	return blockElement("summary", { class: detailsClasses.summary }, [
		html(CHEVRON_ICON),
		blockElement("span", { class: detailsClasses.title }, [text(title)]),
	]);
}

function buildDetails(node: ContainerDirective): RootContent {
	const attributes = node.attributes ?? {};
	const open = isOpen(attributes);
	const { id, name } = attributes;
	const title = takeDirectiveLabel(node) || DEFAULT_TITLE;

	// `name` makes a group exclusive: opening one closes the others.
	return blockElement(
		"details",
		{
			class: detailsClasses.container,
			...(open ? { open: true } : {}),
			...(id ? { id } : {}),
			...(name ? { name } : {}),
		},
		[
			buildSummary(title),
			blockElement("div", { class: detailsClasses.content }, node.children),
		],
	);
}

/**
 * Transforms `:::details[Label]{open}` directives into native
 * `<details>`/`<summary>` elements styled to match the aside family.
 */
export const remarkDetails: Plugin<[], Root> = () => {
	return (tree) => {
		visit(tree, (node, index, parent) => {
			if (!parent || index === undefined || !isContainerDirective(node)) return;
			if (node.name !== "details") return;
			parent.children[index] = buildDetails(node);
		});
	};
};

export default remarkDetails;
