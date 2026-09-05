import { itemIn, setActive, stageOf } from "./pairs";
import { closePopoverInside } from "./popover";

// Below this the pins crowd and popovers barely fit, so phones get the legend.
const MIN_STAGE_WIDTH = 420;
const PING_DURATION = 1400;
const PING_STAGGER = 150;

let pingObserver: IntersectionObserver | null = null;
let sizeObserver: ResizeObserver | null = null;

export function initFigure(figure: HTMLElement): void {
	if (figure.dataset.hotspotsReady === "true") return;
	figure.dataset.hotspotsReady = "true";
	watchImage(figure);
	watchWidth(figure);
	observePing(figure);
}

export function measureAllStages(): void {
	for (const stage of document.querySelectorAll<HTMLElement>(
		"[data-hotspots-stage]",
	)) {
		measure(stage);
	}
}

export function needsLegendFallback(
	figure: HTMLElement,
	stage: HTMLElement,
): boolean {
	if (figure.hasAttribute("data-hotspots-broken")) return true;
	return stage.clientWidth < MIN_STAGE_WIDTH;
}

export function legendIsVisible(figure: HTMLElement): boolean {
	if (figure.dataset.hotspotsLegend === "visible") return true;
	return (
		figure.hasAttribute("data-hotspots-broken") ||
		figure.hasAttribute("data-hotspots-narrow")
	);
}

export function showInLegend(
	figure: HTMLElement,
	pin: HTMLButtonElement,
): void {
	const item = itemIn(figure, pin.dataset.hotspotPin);
	if (!item) return;
	setActive({ pin, item }, true);
	scrollIntoLegend(item);
}

export function scrollIntoLegend(item: HTMLElement): void {
	item.scrollIntoView({
		block: "nearest",
		behavior: prefersReducedMotion() ? "auto" : "smooth",
	});
}

function prefersReducedMotion(): boolean {
	return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

function watchImage(figure: HTMLElement): void {
	const image = figure.querySelector("img");
	if (!image) return;
	image.addEventListener("error", () => setBroken(figure, true));
	image.addEventListener("load", () => setBroken(figure, false));
	// A cached or already-failed image never fires either event.
	if (image.complete) setBroken(figure, image.naturalWidth === 0);
}

function setBroken(figure: HTMLElement, broken: boolean): void {
	figure.toggleAttribute("data-hotspots-broken", broken);
	if (broken) closePopoverInside(figure);
}

function watchWidth(figure: HTMLElement): void {
	const stage = stageOf(figure);
	if (!stage) return;
	measure(stage);
	if (!("ResizeObserver" in window)) return;
	sizeObserver ??= new ResizeObserver(onResizeEntries);
	sizeObserver.observe(stage);
}

function onResizeEntries(entries: ResizeObserverEntry[]): void {
	for (const entry of entries) {
		if (entry.target instanceof HTMLElement) measure(entry.target);
	}
}

function measure(stage: HTMLElement): void {
	const figure = stage.closest<HTMLElement>("[data-hotspots]");
	if (!figure) return;
	const narrow = stage.clientWidth < MIN_STAGE_WIDTH;
	figure.toggleAttribute("data-hotspots-narrow", narrow);
	if (narrow) closePopoverInside(figure);
}

function observePing(figure: HTMLElement): void {
	if (prefersReducedMotion()) return;
	if (!("IntersectionObserver" in window)) return;
	pingObserver ??= new IntersectionObserver(onIntersect, { threshold: 0.4 });
	pingObserver.observe(figure);
}

function onIntersect(
	entries: IntersectionObserverEntry[],
	observer: IntersectionObserver,
): void {
	for (const entry of entries) {
		if (!entry.isIntersecting) continue;
		observer.unobserve(entry.target);
		playPing(entry.target);
	}
}

function playPing(figure: Element): void {
	const rings = figure.querySelectorAll<HTMLElement>("[data-hotspot-ping]");
	rings.forEach((ring, index) => {
		ring.animate(
			[
				{ opacity: 0.6, transform: "scale(1)" },
				{ opacity: 0, transform: "scale(2.4)" },
			],
			{
				duration: PING_DURATION,
				delay: index * PING_STAGGER,
				iterations: 2,
				easing: "ease-out",
			},
		);
	});
}
