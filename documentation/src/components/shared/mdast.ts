import type {
	Emphasis,
	Html,
	Nodes,
	PhrasingContent,
	RootContent,
	Text,
} from "mdast";
import type { ContainerDirective, TextDirective } from "mdast-util-directive";
import type {} from "mdast-util-to-hast";
import type { Node } from "unist";

/** True for `:::name` container directives. */
export function isContainerDirective(node: Node): node is ContainerDirective {
	return node.type === "containerDirective";
}

/** True for `:name[]` text directives. */
export function isTextDirective(node: Node): node is TextDirective {
	return node.type === "textDirective";
}

/** Removes a container directive's `[label]` paragraph and returns its inline nodes. */
export function takeDirectiveLabelNodes(
	node: ContainerDirective,
): PhrasingContent[] | null {
	const first = node.children[0];
	if (first?.type !== "paragraph" || !first.data?.directiveLabel) return null;
	node.children.shift();
	return first.children;
}

/** Removes a container directive's `[label]` paragraph and returns its text. */
export function takeDirectiveLabel(node: ContainerDirective): string | null {
	const nodes = takeDirectiveLabelNodes(node);
	return nodes === null ? null : textOf(nodes);
}

/** Concatenated text of a node list, ignoring formatting. */
export function textOf(nodes: readonly Nodes[]): string {
	return nodes
		.map((node) => {
			if ("value" in node) return node.value;
			if ("children" in node) return textOf(node.children);
			return "";
		})
		.join("");
}

/**
 * A phrasing-content carrier that `hName` renames on the way to hast, so the
 * `<em>` never reaches the page.
 */
export function element(
	hName: string,
	hProperties: Record<string, string>,
	children: PhrasingContent[] = [],
): Emphasis {
	return { type: "emphasis", data: { hName, hProperties }, children };
}

/**
 * A block-content carrier for `hName`. mdast has no node type that holds
 * arbitrary block children, so a paragraph stands in and the cast lives here.
 */
export function blockElement(
	hName: string,
	hProperties: Record<string, string | boolean>,
	children: Nodes[],
): RootContent {
	return {
		type: "paragraph",
		data: { hName, hProperties },
		children,
	} as unknown as RootContent;
}

/** A plain mdast text node. */
export function text(value: string): Text {
	return { type: "text", value };
}

/** Raw HTML passed straight through to the page. */
export function html(value: string): Html {
	return { type: "html", value };
}
