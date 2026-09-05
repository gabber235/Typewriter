import { stepStyles as s } from "./styles";
import type { StepsElements } from "./types";

export function setupSteps(): void {
	for (const root of document.querySelectorAll<HTMLElement>("[data-steps]")) {
		initSteps(root);
	}
}

function initSteps(root: HTMLElement): void {
	if (root.dataset.stepsReady === "true") return;
	const elements = resolve(root);
	if (!elements) return;
	root.dataset.stepsReady = "true";

	if (elements.staged) moveMediaToStage(elements);
	activate(elements, 0);
	observe(elements);
}

// Matches the `lg` breakpoint where the layout gains the second column.
const STAGE_QUERY = "(min-width: 64rem)";

function resolve(root: HTMLElement): StepsElements | null {
	const stage = root.querySelector<HTMLElement>("[data-steps-stage]");
	const line = root.querySelector<HTMLElement>("[data-steps-line]");
	const fill = root.querySelector<HTMLElement>("[data-steps-fill]");
	const steps = Array.from(root.querySelectorAll<HTMLElement>("[data-step]"));
	const panels = Array.from(
		root.querySelectorAll<HTMLElement>("[data-step-media]"),
	);
	if (!stage || !line || !fill || steps.length === 0) return null;
	if (steps.length !== panels.length) return null;
	const staged = window.matchMedia(STAGE_QUERY).matches;
	return { root, staged, steps, panels, stage, line, fill };
}

function moveMediaToStage({ stage, panels }: StepsElements): void {
	for (const panel of panels) {
		panel.className = `${s.panel} ${s.panelHidden}`;
		stage.append(panel);
	}
}

// A step is current once its title has crossed the middle of the viewport.
function observe(elements: StepsElements): void {
	const scroller = elements.root.closest(".content-pane") ?? window;
	let queued = false;
	const onScroll = () => {
		if (queued) return;
		queued = true;
		requestAnimationFrame(() => {
			queued = false;
			activate(elements, currentIndex(elements));
		});
	};
	scroller.addEventListener("scroll", onScroll, { passive: true });
	onScroll();

	const resize = new ResizeObserver(onScroll);
	resize.observe(elements.root);

	document.addEventListener(
		"astro:before-swap",
		() => {
			scroller.removeEventListener("scroll", onScroll);
			resize.disconnect();
		},
		{ once: true },
	);
}

function currentIndex(elements: StepsElements): number {
	const middle = window.innerHeight / 2;
	let index = 0;
	elements.steps.forEach((step, i) => {
		const title = step.querySelector("h3") ?? step;
		if (title.getBoundingClientRect().top <= middle) index = i;
	});
	return index;
}

function activate(elements: StepsElements, index: number): void {
	if (elements.root.dataset.stepsActive === String(index)) return;
	elements.root.dataset.stepsActive = String(index);

	elements.steps.forEach((step, i) => {
		step.toggleAttribute("data-active", i === index);
		step.toggleAttribute("data-passed", i < index);
	});
	if (elements.staged) showPanel(elements, index);
	positionFill(elements);
}

function showPanel({ panels }: StepsElements, index: number): void {
	panels.forEach((panel, i) => {
		panel.className = `${s.panel} ${i === index ? s.panelActive : s.panelHidden}`;
	});
}

function markerCenter(step: HTMLElement | undefined, listTop: number): number {
	const marker = step?.firstElementChild;
	if (!(marker instanceof HTMLElement)) return 0;
	return marker.getBoundingClientRect().top + marker.offsetHeight / 2 - listTop;
}

function positionFill(elements: StepsElements): void {
	const { steps, line, fill, root } = elements;
	const listTop = line.parentElement?.getBoundingClientRect().top ?? 0;
	const first = markerCenter(steps[0], listTop);
	const last = markerCenter(steps[steps.length - 1], listTop);
	const active = markerCenter(
		steps[Number(root.dataset.stepsActive ?? 0)],
		listTop,
	);

	line.style.top = `${first}px`;
	line.style.height = `${Math.max(0, last - first)}px`;
	fill.style.top = `${first}px`;
	fill.style.height = `${Math.max(0, active - first)}px`;
}
