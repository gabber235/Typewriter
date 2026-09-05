import { COMPARE_LARGE_STEP, COMPARE_STEP, COMPARE_TRANSITION } from "./types";

interface Slider {
	root: HTMLElement;
	frame: HTMLElement;
	input: HTMLInputElement;
	labels: HTMLElement[];
	vertical: boolean;
	hover: boolean;
	dragging: boolean;
	pending: number;
}

const INCREASE_KEYS = {
	horizontal: new Set(["ArrowRight", "ArrowUp"]),
	vertical: new Set(["ArrowDown", "ArrowRight"]),
};
const DECREASE_KEYS = {
	horizontal: new Set(["ArrowLeft", "ArrowDown"]),
	vertical: new Set(["ArrowUp", "ArrowLeft"]),
};

/**
 * Initializes every comparison slider on the page. Safe to call repeatedly, so
 * it can run on both `astro:after-swap` and `astro:page-load`.
 */
export function setupCompare(): void {
	for (const root of document.querySelectorAll<HTMLElement>("[data-compare]")) {
		initCompare(root);
	}
}

function initCompare(root: HTMLElement): void {
	if (root.dataset.compareReady === "true") return;
	root.dataset.compareReady = "true";

	const slider = createSlider(root);
	if (!slider) return;

	observeLabels(slider);
	bindPointer(slider);
	bindKeyboard(slider);
}

function createSlider(root: HTMLElement): Slider | null {
	const frame = root.querySelector<HTMLElement>("[data-compare-frame]");
	const input = root.querySelector<HTMLInputElement>("[data-compare-input]");
	if (!frame || !input) return null;

	return {
		root,
		frame,
		input,
		labels: [...root.querySelectorAll<HTMLElement>("[data-compare-label]")],
		vertical: root.dataset.orientation === "vertical",
		hover: root.dataset.hover === "true",
		dragging: false,
		pending: 0,
	};
}

function observeLabels(slider: Slider): void {
	measureLabels(slider);
	const observer = new ResizeObserver(() => measureLabels(slider));
	observer.observe(slider.frame);
	for (const label of slider.labels) observer.observe(label);
}

function bindPointer(slider: Slider): void {
	const { frame } = slider;
	frame.addEventListener("dragstart", (event) => event.preventDefault());
	frame.addEventListener("pointerdown", (event) => startDrag(slider, event));
	frame.addEventListener("pointermove", (event) => trackPointer(slider, event));
	frame.addEventListener("pointerup", (event) => stopDrag(slider, event));
	frame.addEventListener("pointercancel", (event) => stopDrag(slider, event));
}

function bindKeyboard(slider: Slider): void {
	slider.input.addEventListener("keydown", (event) => {
		const next = keyValue(event, Number(slider.input.value), slider.vertical);
		if (next === null) return;
		event.preventDefault();
		apply(slider, next, true);
	});
	slider.input.addEventListener("input", () => {
		apply(slider, Number(slider.input.value), true);
	});
}

function startDrag(slider: Slider, event: PointerEvent): void {
	if (followsPointer(slider, event)) return;
	if (event.pointerType === "mouse" && event.button !== 0) return;
	event.preventDefault();
	slider.dragging = true;
	apply(slider, pointerPercent(slider, event), true);
	slider.frame.setPointerCapture(event.pointerId);
}

function trackPointer(slider: Slider, event: PointerEvent): void {
	if (!slider.dragging && !followsPointer(slider, event)) return;
	const point = slider.vertical ? event.clientY : event.clientX;
	if (slider.pending) cancelAnimationFrame(slider.pending);
	slider.pending = requestAnimationFrame(() => {
		slider.pending = 0;
		apply(slider, toPercent(slider.frame, point, slider.vertical), false);
	});
}

function stopDrag(slider: Slider, event: PointerEvent): void {
	if (!slider.dragging) return;
	slider.dragging = false;
	if (slider.frame.hasPointerCapture(event.pointerId)) {
		slider.frame.releasePointerCapture(event.pointerId);
	}
	slider.root.style.setProperty("--compare-dur", COMPARE_TRANSITION);
}

/** A touch pointer never hovers, so it keeps the drag path on a hover slider. */
function followsPointer(slider: Slider, event: PointerEvent): boolean {
	return slider.hover && event.pointerType !== "touch";
}

function pointerPercent(slider: Slider, event: PointerEvent): number {
	const point = slider.vertical ? event.clientY : event.clientX;
	return toPercent(slider.frame, point, slider.vertical);
}

function apply(slider: Slider, value: number, animated: boolean): void {
	const next = Math.min(100, Math.max(0, value));
	slider.root.style.setProperty(
		"--compare-dur",
		animated ? COMPARE_TRANSITION : "0ms",
	);
	slider.root.style.setProperty("--compare-pos", next.toFixed(2));

	const rounded = Math.round(next);
	slider.input.value = String(rounded);
	slider.input.setAttribute("aria-valuetext", valueText(slider, rounded));
}

function toPercent(
	frame: HTMLElement,
	point: number,
	vertical: boolean,
): number {
	const rect = frame.getBoundingClientRect();
	const size = vertical ? rect.height : rect.width;
	if (size === 0) return 0;
	return ((point - (vertical ? rect.top : rect.left)) / size) * 100;
}

function keyValue(
	event: KeyboardEvent,
	current: number,
	vertical: boolean,
): number | null {
	if (event.key === "Home") return 0;
	if (event.key === "End") return 100;
	if (event.key === "PageUp") return current + COMPARE_LARGE_STEP;
	if (event.key === "PageDown") return current - COMPARE_LARGE_STEP;

	const axis = vertical ? "vertical" : "horizontal";
	const step = event.shiftKey ? COMPARE_LARGE_STEP : COMPARE_STEP;
	if (INCREASE_KEYS[axis].has(event.key)) return current + step;
	if (DECREASE_KEYS[axis].has(event.key)) return current - step;
	return null;
}

/**
 * `--compare-fade` is the label's own extent along the split axis, so the label
 * reaches opacity 0 exactly as the clip edge arrives at it.
 */
function measureLabels(slider: Slider): void {
	const rect = slider.frame.getBoundingClientRect();
	const span = slider.vertical ? rect.height : rect.width;
	if (span === 0) return;

	for (const label of slider.labels) {
		const lead = label.dataset.compareLabel === "before";
		const edge = labelEdge(
			rect,
			label.getBoundingClientRect(),
			lead,
			slider.vertical,
		);
		label.style.setProperty("--compare-fade", ((edge / span) * 100).toFixed(2));
	}
}

function labelEdge(
	frame: DOMRect,
	label: DOMRect,
	lead: boolean,
	vertical: boolean,
): number {
	if (vertical && lead) return label.bottom - frame.top;
	if (vertical) return frame.bottom - label.top;
	if (lead) return label.right - frame.left;
	return frame.right - label.left;
}

/**
 * A slider whose value is only "62" tells a screen reader nothing about what is
 * being split, so every change also writes how much of each image is showing.
 */
function valueText(slider: Slider, value: number): string {
	const before = labelText(slider.labels, "before", "before");
	const after = labelText(slider.labels, "after", "after");
	return `${value}% ${before}, ${100 - value}% ${after}`;
}

function labelText(
	labels: HTMLElement[],
	kind: string,
	fallback: string,
): string {
	const label = labels.find((node) => node.dataset.compareLabel === kind);
	const value = label?.textContent?.trim();
	return value && value.length > 0 ? value : fallback;
}
