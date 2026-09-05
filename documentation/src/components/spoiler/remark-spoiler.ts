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
import { spoilerStyles as s, spoilerIcons, spoilerVariants } from "./styles";
import { isSpoilerVariant, type SpoilerVariant } from "./types";

interface Spoiler {
	id: string;
	contentId: string;
	variant: SpoilerVariant;
	title: string;
	reason: string;
	revealLabel: string;
	hideLabel: string;
	open: boolean;
	body: RootContent[];
}

const DEFAULT_TITLE = "Hidden section";
const DEFAULT_REASON =
	"This content is hidden. Reveal it only if you know what you are doing.";
const DEFAULT_REVEAL = "Reveal section";
const DEFAULT_HIDE = "Hide again";
const DEFAULT_VARIANT: SpoilerVariant = "warning";

function attribute(node: ContainerDirective, name: string): string | null {
	const value = node.attributes?.[name];
	if (typeof value !== "string") return null;
	const trimmed = value.trim();
	return trimmed.length > 0 ? trimmed : null;
}

function readVariant(node: ContainerDirective): SpoilerVariant {
	const value = attribute(node, "variant");
	if (!value || !isSpoilerVariant(value)) return DEFAULT_VARIANT;
	return value;
}

function plural(count: number, word: string): string {
	return `${count} ${word}${count === 1 ? "" : "s"}`;
}

function hint(children: RootContent[]): string {
	const code = children.filter((child) => child.type === "code").length;
	const blocks = plural(children.length, "block");
	if (code === 0) return `Reveals ${blocks}`;
	return `Reveals ${blocks}, including ${plural(code, "code block")}`;
}

function readSpoiler(node: ContainerDirective, id: string): Spoiler {
	const variant = readVariant(node);
	const title = takeDirectiveLabel(node) || DEFAULT_TITLE;
	return {
		id,
		contentId: `${id}-content`,
		variant,
		title,
		reason: attribute(node, "reason") ?? DEFAULT_REASON,
		revealLabel: attribute(node, "button") ?? DEFAULT_REVEAL,
		hideLabel: attribute(node, "hide") ?? DEFAULT_HIDE,
		open: node.attributes?.open !== undefined,
		body: node.children,
	};
}

function buildBar(spoiler: Spoiler): RootContent {
	return blockElement(
		"div",
		{ class: s.bar, "data-spoiler-bar": "", hidden: !spoiler.open },
		[
			html(
				`<span class="${s.barIcon}">${spoilerIcons[spoiler.variant]}</span>`,
			),
			blockElement("span", { class: s.barTitle }, [text(spoiler.title)]),
			blockElement(
				"button",
				{
					class: s.hideButton,
					type: "button",
					"data-spoiler-hide": "",
					"aria-expanded": "true",
					"aria-controls": spoiler.contentId,
				},
				[text(spoiler.hideLabel)],
			),
		],
	);
}

function buildShell(spoiler: Spoiler): RootContent {
	const shellState = spoiler.open ? s.shellOpen : s.shellClosed;
	const contentState = spoiler.open ? s.contentOpen : s.contentClosed;
	return blockElement(
		"div",
		{ class: `${s.shell} ${shellState}`, "data-spoiler-shell": "" },
		[
			blockElement(
				"div",
				{
					class: `${s.content} ${contentState}`,
					id: spoiler.contentId,
					"data-spoiler-content": "",
				},
				spoiler.body,
			),
		],
	);
}

function buildCard(spoiler: Spoiler): RootContent {
	return blockElement("div", { class: s.card, "data-spoiler-card": "" }, [
		html(`<span class="${s.cardIcon}">${spoilerIcons[spoiler.variant]}</span>`),
		blockElement("p", { class: s.cardTitle }, [text(spoiler.title)]),
		blockElement("p", { class: s.cardReason }, [text(spoiler.reason)]),
		blockElement(
			"button",
			{
				class: s.revealButton,
				type: "button",
				"data-spoiler-reveal": "",
				"aria-expanded": "false",
				"aria-controls": spoiler.contentId,
			},
			[text(spoiler.revealLabel)],
		),
		blockElement("p", { class: s.cardHint }, [text(hint(spoiler.body))]),
	]);
}

function buildGate(spoiler: Spoiler): RootContent {
	return blockElement(
		"div",
		{ class: s.gate, "data-spoiler-gate": "", hidden: spoiler.open },
		[buildCard(spoiler)],
	);
}

function buildSpoiler(node: ContainerDirective, id: string): RootContent {
	const spoiler = readSpoiler(node, id);
	return blockElement(
		"div",
		{
			class: `${s.root} ${spoilerVariants[spoiler.variant]}`,
			id: spoiler.id,
			"data-spoiler": "",
			"data-spoiler-variant": spoiler.variant,
			"data-spoiler-open": String(spoiler.open),
		},
		[buildBar(spoiler), buildShell(spoiler), buildGate(spoiler)],
	);
}

/**
 * Turns `:::spoiler[Title]{reason="…" button="…" variant=warning}` into a gated
 * section: the content is rendered in full (so it stays indexable and readable
 * without JavaScript) behind a blurred preview with an overlay card explaining
 * why it is hidden.
 */
export const remarkSpoiler: Plugin<[], Root> = () => {
	return (tree) => {
		let counter = 0;

		visit(tree, (node, index, parent) => {
			if (!parent || index === undefined || !isContainerDirective(node)) return;
			if (node.name !== "spoiler") return;
			counter += 1;
			parent.children[index] = buildSpoiler(node, `spoiler-${counter}`);
		});
	};
};

export default remarkSpoiler;
