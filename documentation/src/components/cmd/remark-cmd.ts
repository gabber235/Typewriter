import type { PhrasingContent, Root } from "mdast";
import type {} from "mdast-util-directive";
import type {} from "mdast-util-to-hast";
import type { Plugin } from "unified";
import type { Data } from "unist";
import { SKIP, visit } from "unist-util-visit";
import { element, html, text, textOf } from "../shared/mdast";
import { cmdStyles } from "./styles";

const COPY_ICON = `<svg class="${cmdStyles.copyIcon}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="13" height="13" rx="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>`;

const CHECK_ICON = `<svg class="${cmdStyles.checkIcon}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m5 13 4 4L19 7"></path></svg>`;

// Both icons share one 1em grid cell, so neither the swap nor the scale
// animation can move the chip's edges or its baseline.
const ICON_SLOT = `<span class="${cmdStyles.iconSlot}">${COPY_ICON}${CHECK_ICON}</span>`;

/**
 * Turns `:cmd[/tw reload]` into a monospace chip that copies its full text;
 * `{nocopy}` renders the same chip as an inert `<span>`.
 */
export const remarkCmd: Plugin<[], Root> = () => {
	return (tree) => {
		visit(tree, "textDirective", (node) => {
			if (node.name !== "cmd") return;

			const command = textOf(node.children).trim();
			if (command === "") return;

			const copyable = !("nocopy" in (node.attributes ?? {}));
			node.data = copyable ? buttonData(command) : staticData();
			node.children = children(command, copyable);
			return SKIP;
		});
	};
};

function buttonData(command: string): Data {
	return {
		hName: "button",
		hProperties: {
			type: "button",
			class: cmdStyles.chip,
			title: "Copy command",
			"aria-label": `Copy command ${command}`,
			dataCmd: command,
		},
	};
}

function staticData(): Data {
	return { hName: "span", hProperties: { class: cmdStyles.staticChip } };
}

function children(command: string, copyable: boolean): PhrasingContent[] {
	const nodes = label(command);
	if (!copyable) return nodes;
	nodes.push(html(ICON_SLOT));
	return nodes;
}

function label(command: string): PhrasingContent[] {
	if (!command.startsWith("/")) {
		return [element("span", { class: cmdStyles.text }, [text(command)])];
	}
	return [
		element("span", { class: cmdStyles.slash }, [text("/")]),
		element("span", { class: cmdStyles.text }, [text(command.slice(1))]),
	];
}
