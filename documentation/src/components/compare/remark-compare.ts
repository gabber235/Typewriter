import type { Image, PhrasingContent, Root, RootContent } from "mdast";
import type { ContainerDirective } from "mdast-util-directive";
import type {} from "mdast-util-to-hast";
import type { Plugin } from "unified";
import { SKIP, visit } from "unist-util-visit";
import {
	element,
	html,
	isContainerDirective,
	takeDirectiveLabel,
	text,
} from "../shared/mdast";
import { compareStyles as s } from "./styles";
import {
	COMPARE_DEFAULT_AFTER,
	COMPARE_DEFAULT_BEFORE,
	COMPARE_DEFAULT_START,
	COMPARE_TRANSITION,
	type CompareOptions,
	type CompareOrientation,
} from "./types";

type Attributes = Record<string, string | null | undefined>;

/**
 * Turns `:::compare[Before|After]{start=50}` containers into a before/after
 * image slider. The two images stay mdast `image` nodes so Astro's markdown
 * image pipeline still optimizes their relative paths.
 */
export const remarkCompare: Plugin<[], Root> = () => {
	return (tree) => {
		visit(tree, (node, index, parent) => {
			if (!parent || index === undefined || !isContainerDirective(node)) return;
			if (node.name !== "compare") return;

			const [before, after] = readLabels(node);
			const images = collectImages(node);
			if (images.length < 2) return;

			const options = readOptions(node.attributes ?? {}, before, after);
			const slider = buildCompare(options, images[0], images[1]);
			(parent.children as RootContent[])[index] = slider;
			return SKIP;
		});
	};
};

function readLabels(node: ContainerDirective): [string, string] {
	const label = takeDirectiveLabel(node);
	const [before, after] = (label ?? "").split("|");
	return [
		before?.trim() || COMPARE_DEFAULT_BEFORE,
		after?.trim() || COMPARE_DEFAULT_AFTER,
	];
}

function readOptions(
	attributes: Attributes,
	before: string,
	after: string,
): CompareOptions {
	return {
		before,
		after,
		start: readStart(attributes.start),
		orientation: readOrientation(attributes.orientation),
		hover: readHover(attributes.hover),
	};
}

function readStart(value: string | null | undefined): number {
	if (!value) return COMPARE_DEFAULT_START;
	const parsed = Number.parseFloat(value);
	if (Number.isNaN(parsed)) return COMPARE_DEFAULT_START;
	return Math.min(100, Math.max(0, parsed));
}

function readOrientation(value: string | null | undefined): CompareOrientation {
	return value === "vertical" ? "vertical" : "horizontal";
}

function readHover(value: string | null | undefined): boolean {
	if (value === undefined || value === null) return false;
	return value !== "false";
}

function collectImages(node: ContainerDirective): Image[] {
	const images: Image[] = [];
	visit(node, "image", (image) => {
		images.push(image);
	});
	return images;
}

function buildCompare(
	options: CompareOptions,
	before: Image,
	after: Image,
): PhrasingContent {
	return element(
		"div",
		{
			class: s.root,
			"data-compare": "",
			"data-orientation": options.orientation,
			"data-hover": String(options.hover),
			style: `--compare-pos:${options.start};--compare-dur:${COMPARE_TRANSITION};--compare-fade:0`,
		},
		[buildFrame(options, before, after)],
	);
}

function buildFrame(
	options: CompareOptions,
	before: Image,
	after: Image,
): PhrasingContent {
	const vertical = options.orientation === "vertical";
	return element(
		"div",
		{
			class: `${s.frame} ${vertical ? s.frameVertical : s.frameHorizontal}`,
			"data-compare-frame": "",
		},
		[
			buildLayer(
				before,
				"before",
				`${s.layerBefore} ${vertical ? s.layerBeforeVertical : s.layerBeforeHorizontal}`,
				`${s.label} ${vertical ? s.labelBeforeVertical : s.labelBeforeHorizontal}`,
				options.before,
			),
			buildLayer(
				after,
				"after",
				s.layerAfter,
				`${s.label} ${vertical ? s.labelAfterVertical : s.labelAfterHorizontal}`,
				options.after,
			),
			buildDivider(vertical),
			buildHandle(options, vertical),
		],
	);
}

function buildLayer(
	image: Image,
	kind: "before" | "after",
	layerClass: string,
	labelClass: string,
	label: string,
): PhrasingContent {
	return element("div", { class: layerClass }, [
		image,
		element("span", { class: labelClass, "data-compare-label": kind }, [
			text(label),
		]),
	]);
}

function buildDivider(vertical: boolean): PhrasingContent {
	return element("div", {
		class: `${s.divider} ${vertical ? s.dividerVertical : s.dividerHorizontal}`,
		"aria-hidden": "true",
	});
}

function buildHandle(
	options: CompareOptions,
	vertical: boolean,
): PhrasingContent {
	return element(
		"div",
		{
			class: `${s.handle} ${vertical ? s.handleVertical : s.handleHorizontal}`,
			"data-compare-handle": "",
		},
		[
			html(gripIcon(vertical ? s.gripVertical : s.grip)),
			buildRangeInput(options),
		],
	);
}

function buildRangeInput(options: CompareOptions): PhrasingContent {
	const start = Math.round(options.start);
	return element("input", {
		type: "range",
		min: "0",
		max: "100",
		step: "1",
		value: String(options.start),
		"aria-label": `Comparison slider: ${options.before} versus ${options.after}`,
		"aria-orientation": options.orientation,
		// A bare "50" says nothing about what is being split; the script keeps
		// this in sync as the handle moves.
		"aria-valuetext": `${start}% ${options.before}, ${100 - start}% ${options.after}`,
		"data-compare-input": "",
		class: s.input,
	});
}

function gripIcon(className: string): string {
	return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" class="${className}"><path d="M10 7 5 12l5 5" /><path d="m14 7 5 5-5 5" /></svg>`;
}
