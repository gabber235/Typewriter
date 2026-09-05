import { buildStyles as s } from "./styles";
import type { BuildElements, BuildState } from "./types";

const KEY_STEP: Record<string, number> = {
	ArrowDown: 1,
	ArrowRight: 1,
	ArrowUp: -1,
	ArrowLeft: -1,
};

export function setupBuild(): void {
	for (const root of document.querySelectorAll<HTMLElement>("[data-build]")) {
		initBuild(root);
	}
}

function initBuild(root: HTMLElement): void {
	if (root.dataset.buildReady === "true") return;

	const elements = resolve(root);
	if (!elements) return;
	root.dataset.buildReady = "true";

	moveMediaToStage(elements);
	const state: BuildState = { active: -1, timer: 0, paused: false };
	bind(elements, state);
	show(elements, state, 0);
	sync(elements, state);
}

function resolve(root: HTMLElement): BuildElements | null {
	const stage = root.querySelector<HTMLElement>("[data-build-stage]");
	const tabs = Array.from(
		root.querySelectorAll<HTMLButtonElement>("[data-build-tab]"),
	);
	const panels = Array.from(
		root.querySelectorAll<HTMLElement>("[data-build-panel]"),
	);
	if (!stage || tabs.length === 0 || tabs.length !== panels.length) return null;
	return { root, tabs, panels, stage };
}

function moveMediaToStage({ stage, panels }: BuildElements): void {
	for (const panel of panels) {
		panel.className = `${s.panel} ${s.panelHidden}`;
		stage.append(panel);
	}
}

function bind(elements: BuildElements, state: BuildState): void {
	const { root, tabs } = elements;

	tabs.forEach((tab, index) => {
		tab.addEventListener("click", () => {
			show(elements, state, index);
			restart(elements, state);
		});
	});

	root.addEventListener("keydown", (event) =>
		onKeyDown(event, elements, state),
	);

	const pause = () => setPaused(elements, state, true);
	const resume = () => setPaused(elements, state, false);
	root.addEventListener("pointerenter", pause);
	root.addEventListener("pointerleave", resume);
	root.addEventListener("focusin", pause);
	root.addEventListener("focusout", (event) => {
		if (root.contains(event.relatedTarget as Node | null)) return;
		resume();
	});

	document.addEventListener("visibilitychange", () => {
		if (!root.isConnected) return;
		sync(elements, state);
	});
	document.addEventListener("astro:before-swap", () => stop(elements, state), {
		once: true,
	});
}

function onKeyDown(
	event: KeyboardEvent,
	elements: BuildElements,
	state: BuildState,
): void {
	const step = KEY_STEP[event.key];
	if (step === undefined) return;
	if (
		!(event.target instanceof Element) ||
		!event.target.closest("[data-build-tab]")
	)
		return;

	event.preventDefault();
	const count = elements.tabs.length;
	const next = (state.active + step + count) % count;
	show(elements, state, next);
	elements.tabs[next]?.focus();
	restart(elements, state);
}

function show(elements: BuildElements, state: BuildState, index: number): void {
	if (index === state.active) return;
	state.active = index;

	elements.tabs.forEach((tab, i) => {
		const selected = i === index;
		tab.setAttribute("aria-selected", String(selected));
		tab.tabIndex = selected ? 0 : -1;
		const progress = tab.querySelector<HTMLElement>("[data-build-progress]");
		if (progress) progress.hidden = !selected;
	});

	elements.panels.forEach((panel, i) => {
		panel.className = `${s.panel} ${i === index ? s.panelActive : s.panelHidden}`;
	});
}

function shouldRun(state: BuildState): boolean {
	if (state.paused || document.hidden) return false;
	return !window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

function intervalMs(root: HTMLElement): number {
	const seconds = Number.parseFloat(
		getComputedStyle(root).getPropertyValue("--build-interval"),
	);
	return Number.isFinite(seconds) && seconds > 0 ? seconds * 1000 : 5000;
}

function sync(elements: BuildElements, state: BuildState): void {
	if (!shouldRun(state)) {
		stop(elements, state);
		return;
	}
	if (state.timer) return;
	start(elements, state);
}

function start(elements: BuildElements, state: BuildState): void {
	stop(elements, state);
	elements.root.dataset.buildRunning = "";
	restartProgress(elements);
	state.timer = window.setInterval(() => {
		const next = (state.active + 1) % elements.tabs.length;
		show(elements, state, next);
		restartProgress(elements);
	}, intervalMs(elements.root));
}

function stop(elements: BuildElements, state: BuildState): void {
	window.clearInterval(state.timer);
	state.timer = 0;
	delete elements.root.dataset.buildRunning;
}

function restart(elements: BuildElements, state: BuildState): void {
	if (!shouldRun(state)) return;
	start(elements, state);
}

// Re-inserting the fill restarts its CSS animation from zero.
function restartProgress({ tabs }: BuildElements): void {
	for (const tab of tabs) {
		const fill = tab.querySelector<HTMLElement>("[data-build-progress] > span");
		if (!fill) continue;
		fill.replaceWith(fill.cloneNode(true));
	}
}

function setPaused(
	elements: BuildElements,
	state: BuildState,
	paused: boolean,
): void {
	state.paused = paused;
	sync(elements, state);
}
