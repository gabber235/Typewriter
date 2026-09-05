import { hideSourceList, parseWizard, textOf } from "./parse";
import { persistPath, restorePath } from "./persist";
import { buildPanels, buildShell, renderTrail } from "./render";
import { measureStage, observePanels, showPanel } from "./stage";
import { panelKey, remainingDepth, resolvePath } from "./tree";
import type {
	ParsedWizard,
	WizardContext,
	WizardFocus,
	WizardState,
} from "./types";

type MoveKey = (index: number, count: number) => number;

const MOVE_KEYS: Record<string, MoveKey> = {
	ArrowDown: (index, count) => (index + 1) % count,
	ArrowRight: (index, count) => (index + 1) % count,
	ArrowUp: (index, count) => (index - 1 + count) % count,
	ArrowLeft: (index, count) => (index - 1 + count) % count,
	Home: () => 0,
	End: (_index, count) => count - 1,
};

let nextId = 0;

/** Enhance every `:::wizard` block on the page; safe to call repeatedly. */
export function setupWizards(): void {
	document.querySelectorAll<HTMLElement>("[data-wizard]").forEach(initWizard);
}

function initWizard(root: HTMLElement, index: number): void {
	if (root.dataset.wizardReady === "true") return;
	root.dataset.wizardReady = "true";

	const parsed = parseWizard(root);
	if (!parsed || parsed.tree.answers.length === 0) return;

	hideSourceList(root);
	const wizard = createContext(root, parsed, index);
	const state: WizardState = { path: restorePath(wizard) };

	buildPanels(wizard);
	// Reveal the starting panel before anything reads layout so the first paint
	// does not depend on a transition; background tabs never start one.
	showPanel(wizard, state.path);
	measureStage(wizard);
	observePanels(wizard);
	bindEvents(wizard, state);
	render(wizard, state, { kind: "none" });
}

function createContext(
	root: HTMLElement,
	{ title, tree }: ParsedWizard,
	index: number,
): WizardContext {
	const id = `wizard-${nextId++}`;
	const label = textOf(title ?? tree.question);
	const persistKey =
		root.dataset.wizardPersist === undefined
			? null
			: `wizard:${location.pathname}:${index}`;
	return {
		tree,
		elements: buildShell(root, id, title, label),
		persistKey,
		id,
		label,
		panels: new Map(),
		activeKey: null,
		hideTimer: 0,
	};
}

function render(
	wizard: WizardContext,
	state: WizardState,
	focus: WizardFocus,
): void {
	const { steps, result } = resolvePath(wizard.tree, state.path);
	const current = steps[steps.length - 1];
	const number = steps.length;
	const total = number - 1 + remainingDepth(current);
	const { counter, back, restart, live } = wizard.elements;

	renderTrail(wizard, state, steps);
	counter.textContent = result
		? "Recommendation"
		: `Question ${number} of ${total}`;
	back.disabled = state.path.length === 0;
	restart.disabled = state.path.length === 0;

	const panel = showPanel(wizard, state.path);
	live.textContent = result
		? `Recommendation: ${textOf(result.result)}`
		: `Question ${number} of ${total}: ${textOf(current.question)}`;

	if (panel) applyFocus(panel, focus);
	persistPath(wizard, state);
}

/**
 * Focus never scrolls: the stage has a fixed height, so the target is already
 * where the reader is looking and the page must not move under them.
 */
function applyFocus(panel: HTMLElement, focus: WizardFocus): void {
	if (focus.kind === "none") return;

	const result = panel.querySelector<HTMLElement>("[data-wizard-result]");
	if (result) {
		result.focus({ preventScroll: true });
		return;
	}

	const buttons = answerButtons(panel);
	const index = focus.kind === "answer" ? focus.index : 0;
	(buttons[index] ?? buttons[0])?.focus({ preventScroll: true });
}

function answerButtons(scope: ParentNode): HTMLElement[] {
	return Array.from(
		scope.querySelectorAll<HTMLElement>("[data-wizard-answer]"),
	);
}

function bindEvents(wizard: WizardContext, state: WizardState): void {
	const { ui } = wizard.elements;
	ui.addEventListener("click", (event) => onClick(wizard, state, event));
	ui.addEventListener("keydown", (event) => onKeyDown(wizard, state, event));
}

function onClick(
	wizard: WizardContext,
	state: WizardState,
	event: MouseEvent,
): void {
	const target = event.target;
	if (!(target instanceof Element)) return;

	const answer = target.closest<HTMLElement>("[data-wizard-answer]");
	if (answer) {
		choose(wizard, state, Number(answer.dataset.wizardAnswer));
		return;
	}

	const chip = target.closest<HTMLElement>("[data-wizard-step]");
	if (chip) {
		goTo(wizard, state, Number(chip.dataset.wizardStep));
		return;
	}

	if (target.closest("[data-wizard-back]")) {
		goBack(wizard, state);
		return;
	}

	if (target.closest("[data-wizard-restart]")) restart(wizard, state);
}

function onKeyDown(
	wizard: WizardContext,
	state: WizardState,
	event: KeyboardEvent,
): void {
	if (event.altKey || event.ctrlKey || event.metaKey) return;
	const target = event.target;
	if (!(target instanceof HTMLElement) || isEditable(target)) return;

	if (event.key === "Escape" || event.key === "Backspace") {
		if (state.path.length === 0) return;
		event.preventDefault();
		goBack(wizard, state);
		return;
	}

	moveFocus(wizard, state, event, target);
}

function isEditable(target: HTMLElement): boolean {
	return target.isContentEditable || target.matches("input, textarea, select");
}

function moveFocus(
	wizard: WizardContext,
	state: WizardState,
	event: KeyboardEvent,
	target: HTMLElement,
): void {
	const move = MOVE_KEYS[event.key];
	if (!move) return;
	const panel = wizard.panels.get(panelKey(state.path));
	if (!panel) return;
	const buttons = answerButtons(panel);
	const current = buttons.indexOf(target);
	if (current === -1) return;
	event.preventDefault();
	buttons[move(current, buttons.length)]?.focus();
}

function choose(
	wizard: WizardContext,
	state: WizardState,
	index: number,
): void {
	const { result } = resolvePath(wizard.tree, state.path);
	if (result) return;
	state.path = [...state.path, index];
	render(wizard, state, { kind: "first" });
}

function goTo(wizard: WizardContext, state: WizardState, step: number): void {
	if (step < 0 || step >= state.path.length) return;
	const previous = state.path[step];
	state.path = state.path.slice(0, step);
	render(wizard, state, { kind: "answer", index: previous });
}

function goBack(wizard: WizardContext, state: WizardState): void {
	goTo(wizard, state, state.path.length - 1);
}

function restart(wizard: WizardContext, state: WizardState): void {
	if (state.path.length === 0) return;
	state.path = [];
	render(wizard, state, { kind: "first" });
}
