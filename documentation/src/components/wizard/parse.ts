import type { ParsedWizard, WizardAnswer, WizardStep } from "./types";

const ARROW = /\s*(?:→|->)\s*/;

/**
 * A lone top-level item with a nested list is the root question and the
 * directive label a title; otherwise the label is the root question and the
 * top-level items are its answers.
 */
export function parseWizard(root: HTMLElement): ParsedWizard | null {
	const list = root.querySelector<HTMLElement>(":scope > ul, :scope > ol");
	if (!list) return null;

	const label = parseLabel(root);
	const rootItem = rootQuestionItem(list);
	if (rootItem) return { title: label, tree: parseStep(rootItem) };

	if (!label) return null;
	return {
		title: null,
		tree: { question: label, answers: parseAnswers(list) },
	};
}

export function hideSourceList(root: HTMLElement): void {
	const selector = ":scope > [data-wizard-question], :scope > ul, :scope > ol";
	for (const source of root.querySelectorAll<HTMLElement>(selector)) {
		source.hidden = true;
	}
}

export function cloneNodes(nodes: Node[]): Node[] {
	return nodes.map((node) => node.cloneNode(true));
}

export function textOf(nodes: Node[]): string {
	return nodes
		.map((node) => node.textContent ?? "")
		.join("")
		.replace(/\s+/g, " ")
		.trim();
}

function parseLabel(root: HTMLElement): Node[] | null {
	const label = root.querySelector<HTMLElement>(
		":scope > [data-wizard-question]",
	);
	if (!label) return null;
	return trimNodes(cloneNodes(Array.from(label.childNodes)));
}

function rootQuestionItem(list: HTMLElement): HTMLLIElement | null {
	const items = list.querySelectorAll<HTMLLIElement>(":scope > li");
	const first = items[0];
	if (items.length !== 1 || !first) return null;
	if (!childList(first) || hasArrow(ownNodes(first))) return null;
	return first;
}

function parseStep(item: HTMLLIElement): WizardStep {
	const nested = childList(item);
	const answers = nested ? parseAnswers(nested) : [];
	return { question: ownNodes(item), answers };
}

function parseAnswers(list: HTMLElement): WizardAnswer[] {
	return Array.from(
		list.querySelectorAll<HTMLLIElement>(":scope > li"),
		parseAnswer,
	);
}

function parseAnswer(item: HTMLLIElement): WizardAnswer {
	const nested = childList(item);
	const [before, after] = splitArrow(ownNodes(item));
	const label = toLabel(before);
	if (!nested) return { label, next: null, result: after ?? before };

	const question = after ?? cloneNodes(before);
	return {
		label,
		next: { question, answers: parseAnswers(nested) },
		result: [],
	};
}

function hasArrow(nodes: Node[]): boolean {
	return nodes.some((node) => node instanceof Text && ARROW.test(node.data));
}

function childList(item: HTMLLIElement): HTMLElement | null {
	return item.querySelector<HTMLElement>(":scope > ul, :scope > ol");
}

function isList(node: Node): boolean {
	return node instanceof HTMLUListElement || node instanceof HTMLOListElement;
}

function isBlankText(node: Node): boolean {
	return node.nodeType === Node.TEXT_NODE && !node.textContent?.trim();
}

/** The item's own inline content (everything except its nested list), cloned. */
function ownNodes(item: HTMLLIElement): Node[] {
	const own = Array.from(item.childNodes).filter((node) => !isList(node));
	const meaningful = own.filter((node) => !isBlankText(node));
	const only = meaningful.length === 1 ? meaningful[0] : null;
	const source =
		only instanceof HTMLParagraphElement ? Array.from(only.childNodes) : own;
	return trimNodes(cloneNodes(source));
}

function trimNodes(nodes: Node[]): Node[] {
	const trimmed = [...nodes];
	while (trimmed.length && isBlankText(trimmed[0])) trimmed.shift();
	while (trimmed.length && isBlankText(trimmed[trimmed.length - 1])) {
		trimmed.pop();
	}
	const first = trimmed[0];
	const last = trimmed[trimmed.length - 1];
	if (first instanceof Text) first.data = first.data.trimStart();
	if (last instanceof Text) last.data = last.data.trimEnd();
	return trimmed;
}

/** Split `Answer → Rest` at the first arrow in a top-level text node. */
function splitArrow(nodes: Node[]): [Node[], Node[] | null] {
	for (let index = 0; index < nodes.length; index++) {
		const node = nodes[index];
		if (!(node instanceof Text)) continue;
		const match = ARROW.exec(node.data);
		if (!match) continue;
		return splitTextNode(nodes, index, node, match);
	}
	return [nodes, null];
}

function splitTextNode(
	nodes: Node[],
	index: number,
	node: Text,
	match: RegExpExecArray,
): [Node[], Node[]] {
	const head = node.data.slice(0, match.index);
	const tail = node.data.slice(match.index + match[0].length);
	const before = [...nodes.slice(0, index), ...optionalText(head)];
	const after = [...optionalText(tail), ...nodes.slice(index + 1)];
	return [trimNodes(before), trimNodes(after)];
}

function optionalText(value: string): Text[] {
	return value ? [document.createTextNode(value)] : [];
}

/** Buttons cannot contain links, so labels downgrade anchors to spans. */
function toLabel(nodes: Node[]): Node[] {
	const fragment = document.createDocumentFragment();
	fragment.append(...cloneNodes(nodes));
	for (const anchor of Array.from(fragment.querySelectorAll("a"))) {
		const span = document.createElement("span");
		span.append(...Array.from(anchor.childNodes));
		anchor.replaceWith(span);
	}
	return Array.from(fragment.childNodes);
}
