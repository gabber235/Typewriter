import { cloneNodes, textOf } from "./parse";
import { wizardStyles as s } from "./styles";
import { panelKey } from "./tree";
import type {
	WizardAnswer,
	WizardContext,
	WizardElements,
	WizardState,
	WizardStep,
} from "./types";

const svg = (path: string, size = 16): string =>
	`<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${path}</svg>`;
const ICON_CHEVRON = svg('<path d="m9 18 6-6-6-6"/>');
const ICON_CHECK = svg(
	'<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="m9 11 3 3L22 4"/>',
);
const ICON_BACK = svg('<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>', 14);
const ICON_RESTART = svg(
	'<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>',
	14,
);

interface ShellHeader {
	element: HTMLElement;
	trailNav: HTMLElement;
	trail: HTMLOListElement;
	counter: HTMLElement;
}

interface ShellFooter {
	element: HTMLElement;
	back: HTMLButtonElement;
	restart: HTMLButtonElement;
}

export function createElement<K extends keyof HTMLElementTagNameMap>(
	tag: K,
	className: string,
	attributes: Record<string, string> = {},
): HTMLElementTagNameMap[K] {
	const node = document.createElement(tag);
	node.className = className;
	for (const [key, value] of Object.entries(attributes)) {
		node.setAttribute(key, value);
	}
	return node;
}

export function buildShell(
	root: HTMLElement,
	id: string,
	title: Node[] | null,
	context: string,
): WizardElements {
	const ui = createElement("div", s.ui, { "data-wizard-ui": "" });
	if (title) ui.append(buildTitle(title));

	const header = buildHeader(id, context);
	const stage = createElement("div", s.stage, { "data-wizard-stage": "" });
	const footer = buildFooter();
	const live = createElement("div", s.srOnly, {
		"aria-live": "polite",
		"aria-atomic": "true",
	});
	ui.append(header.element, stage, footer.element, live);
	root.prepend(ui);

	return {
		ui,
		trailNav: header.trailNav,
		trail: header.trail,
		counter: header.counter,
		stage,
		back: footer.back,
		restart: footer.restart,
		live,
	};
}

/**
 * Build a panel for every reachable state — each question and each terminal
 * answer's result — so the stage can be sized once from the tallest of them.
 */
export function buildPanels(wizard: WizardContext): void {
	walkPanels(wizard, wizard.tree, []);
	for (const panel of wizard.panels.values()) {
		panel.className = `${s.panel} ${s.panelHidden}`;
		panel.toggleAttribute("inert", true);
	}
	wizard.elements.stage.append(...wizard.panels.values());
}

export function renderTrail(
	wizard: WizardContext,
	state: WizardState,
	steps: WizardStep[],
): void {
	const items: HTMLElement[] = [];
	for (let index = 0; index < state.path.length; index++) {
		const step = steps[index];
		const answer = step?.answers[state.path[index]];
		if (!step || !answer) break;
		items.push(buildTrailItem(step, answer, index));
	}
	for (const item of items.slice(0, -1)) item.append(buildSeparator());

	const { trail, trailNav } = wizard.elements;
	trail.replaceChildren(...items);
	trailNav.scrollLeft = trailNav.scrollWidth;
	updateTrailFade(wizard);
}

export function updateTrailFade(wizard: WizardContext): void {
	const nav = wizard.elements.trailNav;
	const overflows = nav.scrollWidth - nav.clientWidth > 1;
	nav.className = overflows ? `${s.trailNav} ${s.trailFade}` : s.trailNav;
}

function buildTitle(title: Node[]): HTMLElement {
	const heading = createElement("p", s.title);
	heading.append(...cloneNodes(title));
	return heading;
}

function buildHeader(id: string, context: string): ShellHeader {
	const element = createElement("div", s.header);
	// Several wizards can share a page, so each navigation landmark carries the
	// wizard's own title (or root question) to stay distinguishable.
	const trailNav = createElement("nav", s.trailNav, {
		"aria-label": context
			? `Your answers so far: ${context}`
			: "Your answers so far",
	});
	const trail = createElement("ol", s.trail);
	trailNav.append(trail);
	const counter = createElement("span", s.counter, { id: `${id}-counter` });
	element.append(trailNav, counter);
	return { element, trailNav, trail, counter };
}

function buildFooter(): ShellFooter {
	const element = createElement("div", s.footer);
	const back = createElement("button", s.control, {
		type: "button",
		"data-wizard-back": "",
	});
	back.innerHTML = `${ICON_BACK}<span>Back</span>`;
	const restart = createElement("button", s.control, {
		type: "button",
		"data-wizard-restart": "",
	});
	restart.innerHTML = `${ICON_RESTART}<span>Start over</span>`;
	element.append(back, restart);
	return { element, back, restart };
}

function walkPanels(
	wizard: WizardContext,
	step: WizardStep,
	path: number[],
): void {
	wizard.panels.set(panelKey(path), buildQuestion(wizard, step, path));
	for (let index = 0; index < step.answers.length; index++) {
		const answer = step.answers[index];
		const next = [...path, index];
		if (answer.next) {
			walkPanels(wizard, answer.next, next);
			continue;
		}
		wizard.panels.set(panelKey(next), buildResult(wizard, answer));
	}
}

function buildQuestion(
	wizard: WizardContext,
	step: WizardStep,
	path: number[],
): HTMLElement {
	const questionId = `${wizard.id}-q${panelKey(path) || "root"}`;
	const panel = createElement("div", s.panel, {
		role: "group",
		"aria-labelledby": questionId,
	});
	const question = createElement("p", s.question, { id: questionId });
	question.append(...cloneNodes(step.question));

	const answers = createElement("div", s.answers);
	answers.append(...step.answers.map(buildAnswerButton));
	panel.append(question, answers);
	return panel;
}

function buildAnswerButton(answer: WizardAnswer, index: number): HTMLElement {
	const button = createElement("button", s.answer, {
		type: "button",
		"data-wizard-answer": String(index),
	});
	const label = createElement("span", "min-w-0");
	label.append(...cloneNodes(answer.label));
	const icon = createElement("span", s.answerIcon);
	icon.innerHTML = ICON_CHEVRON;
	button.append(label, icon);
	return button;
}

function buildResult(wizard: WizardContext, answer: WizardAnswer): HTMLElement {
	const panel = createElement("div", s.panel);
	const card = createElement("div", s.result, {
		role: "region",
		"aria-label": wizard.label
			? `Recommendation for ${wizard.label}`
			: "Recommendation",
		tabindex: "-1",
		"data-wizard-result": "",
	});
	const header = createElement("div", s.resultHeader);
	header.innerHTML = `${ICON_CHECK}<span>Recommendation</span>`;
	const body = createElement("div", s.resultBody);
	body.append(...cloneNodes(answer.result));
	card.append(header, body);
	panel.append(card);
	return panel;
}

function buildTrailItem(
	step: WizardStep,
	answer: WizardAnswer,
	index: number,
): HTMLElement {
	const chip = createElement("button", s.chip, {
		type: "button",
		"data-wizard-step": String(index),
		"aria-label": `${textOf(step.question)} — you answered "${textOf(answer.label)}". Go back to this question`,
	});
	chip.append(...cloneNodes(answer.label));
	const item = createElement("li", s.trailItem);
	item.append(chip);
	return item;
}

// A real element rather than `::after` so it can carry `aria-hidden`:
// generated content is read out by screen readers as if it were text.
function buildSeparator(): HTMLElement {
	const separator = createElement("span", s.trailSeparator, {
		"aria-hidden": "true",
	});
	separator.textContent = "›";
	return separator;
}
