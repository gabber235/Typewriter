import type {
	Image,
	List,
	ListItem,
	Nodes,
	Paragraph,
	PhrasingContent,
	Root,
	RootContent,
} from "mdast";
import type { ContainerDirective } from "mdast-util-directive";
import type { Plugin } from "unified";
import { visit } from "unist-util-visit";
import {
	blockElement,
	isContainerDirective,
	takeDirectiveLabelNodes,
	text,
	textOf,
} from "../shared/mdast";
import { hotspotStyles as s } from "./styles";
import type {
	HotspotCoords,
	HotspotEntry,
	HotspotPinEntry,
	HotspotsAttributes,
} from "./types";

const COORDS =
	/^\s*\[\s*(\d+(?:\.\d+)?)\s*%?\s*,\s*(\d+(?:\.\d+)?)\s*%?\s*\]\s*/;

function readAttributes(node: ContainerDirective): HotspotsAttributes {
	const attributes = node.attributes ?? {};
	return {
		numbers: attributes.numbers !== "false",
		legendVisible: attributes.legend === "visible",
	};
}

function takeImage(node: ContainerDirective): Image | null {
	const first = node.children[0];
	if (first?.type !== "paragraph") return null;
	const image = first.children.find((child) => child.type === "image");
	if (!image) return null;
	node.children.shift();
	return image;
}

function takeList(node: ContainerDirective): List | null {
	const index = node.children.findIndex((child) => child.type === "list");
	const list = node.children[index];
	if (list?.type !== "list") return null;
	node.children.splice(index, 1);
	return list;
}

function clampPercent(value: string): number {
	return Math.min(100, Math.max(0, Number(value)));
}

function takeCoords(paragraph: Paragraph): HotspotCoords | null {
	const first = paragraph.children[0];
	if (first?.type !== "text") return null;
	const match = COORDS.exec(first.value);
	if (!match) return null;
	first.value = first.value.slice(match[0].length);
	if (first.value === "") paragraph.children.shift();
	return { x: clampPercent(match[1]), y: clampPercent(match[2]) };
}

/** The bold lead-in of a legend entry names the pin; "Callout 3" alone says nothing about its purpose. */
function leadText(item: ListItem): string | null {
	const first = item.children[0];
	if (first?.type !== "paragraph") return null;
	const strong = first.children.find((child) => child.type === "strong");
	if (!strong) return null;
	const value = textOf(strong.children).replace(/\s+/g, " ").trim();
	return value.length > 0 ? value : null;
}

function pinLabel(item: ListItem, number: number): string {
	const lead = leadText(item);
	return lead ? `${lead}, callout ${number}` : `Callout ${number}`;
}

function itemContent(item: ListItem): Nodes[] {
	const first = item.children[0];
	if (item.children.length === 1 && first?.type === "paragraph") {
		return first.children;
	}
	return item.children;
}

function readEntries(list: List, baseId: string): HotspotEntry[] {
	return list.children.map((item, index) => readEntry(item, index + 1, baseId));
}

function readEntry(
	item: ListItem,
	number: number,
	baseId: string,
): HotspotEntry {
	const first = item.children[0];
	const coords = first?.type === "paragraph" ? takeCoords(first) : null;
	return { item, number, descriptionId: `${baseId}-desc-${number}`, coords };
}

function hasCoords(entry: HotspotEntry): entry is HotspotPinEntry {
	return entry.coords !== null;
}

function buildPin(entry: HotspotPinEntry, numbers: boolean): RootContent {
	const { coords, number, descriptionId, item } = entry;
	const ping = blockElement(
		"span",
		{ class: s.ping, "aria-hidden": "true", "data-hotspot-ping": "" },
		[],
	);
	const digits = numbers
		? [
				blockElement("span", { class: s.pinLabel, "aria-hidden": "true" }, [
					text(String(number)),
				]),
			]
		: [];
	return blockElement(
		"button",
		{
			type: "button",
			class: numbers ? s.pin : s.pinDot,
			style: `left:${coords.x}%;top:${coords.y}%`,
			"aria-label": pinLabel(item, number),
			"aria-describedby": descriptionId,
			"aria-expanded": "false",
			"data-hotspot-pin": String(number),
		},
		[ping, ...digits],
	);
}

function buildItemBadge(number: number, numbers: boolean): RootContent {
	if (!numbers) {
		return blockElement(
			"span",
			{ class: s.itemDot, "aria-hidden": "true" },
			[],
		);
	}
	return blockElement("span", { class: s.itemBadge, "aria-hidden": "true" }, [
		text(String(number)),
	]);
}

function buildItem(entry: HotspotEntry, numbers: boolean): RootContent {
	const { item, number, descriptionId } = entry;
	return blockElement(
		"li",
		{ class: s.item, "data-hotspot-item": String(number) },
		[
			buildItemBadge(number, numbers),
			blockElement(
				"div",
				{ class: s.itemContent, id: descriptionId },
				itemContent(item),
			),
		],
	);
}

function buildCaption(label: PhrasingContent[] | null): RootContent[] {
	if (!label) return [];
	return [blockElement("figcaption", { class: s.caption }, label)];
}

function buildLegend(
	entries: HotspotEntry[],
	options: HotspotsAttributes,
): RootContent {
	return blockElement(
		"ol",
		{
			class: options.legendVisible ? s.legendVisible : s.legend,
			"data-hotspots-list": "",
		},
		entries.map((entry) => buildItem(entry, options.numbers)),
	);
}

function buildFigure(
	node: ContainerDirective,
	baseId: string,
	options: HotspotsAttributes,
	label: PhrasingContent[] | null,
	image: Image,
	list: List,
): RootContent {
	const entries = readEntries(list, baseId);
	const pins = entries
		.filter(hasCoords)
		.map((entry) => buildPin(entry, options.numbers));

	return blockElement(
		"figure",
		{
			class: s.figure,
			"data-hotspots": "",
			"data-hotspots-numbers": String(options.numbers),
			"data-hotspots-legend": options.legendVisible ? "visible" : "auto",
		},
		[
			blockElement("div", { class: s.stage, "data-hotspots-stage": "" }, [
				image,
				...pins,
			]),
			...buildCaption(label),
			buildLegend(entries, options),
			...node.children,
		],
	);
}

/**
 * Turns `:::hotspots` into a figure with percentage-positioned pins and a
 * legend list. The mdast `image` node is kept intact so Astro's image
 * pipeline still processes it.
 */
export const remarkHotspots: Plugin<[], Root> = () => {
	return (tree) => {
		let count = 0;
		visit(tree, (node, index, parent) => {
			if (!parent || index === undefined || !isContainerDirective(node)) return;
			if (node.name !== "hotspots") return;

			const options = readAttributes(node);
			const label = takeDirectiveLabelNodes(node);
			const image = takeImage(node);
			const list = image ? takeList(node) : null;
			if (!image || !list) return;

			count += 1;
			parent.children[index] = buildFigure(
				node,
				`hotspots-${count}`,
				options,
				label,
				image,
				list,
			);
		});
	};
};

export default remarkHotspots;
