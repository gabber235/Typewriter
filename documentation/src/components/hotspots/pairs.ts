import type { HotspotPair } from "./types";

export function figureOf(element: Element): HTMLElement | null {
	return element.closest<HTMLElement>("[data-hotspots]");
}

export function stageOf(figure: HTMLElement): HTMLElement | null {
	return figure.querySelector<HTMLElement>("[data-hotspots-stage]");
}

export function pinFrom(target: EventTarget | null): HTMLButtonElement | null {
	if (!(target instanceof Element)) return null;
	return target.closest<HTMLButtonElement>("[data-hotspot-pin]");
}

export function itemIn(
	figure: HTMLElement,
	number: string | undefined,
): HTMLElement | null {
	return figure.querySelector<HTMLElement>(`[data-hotspot-item="${number}"]`);
}

export function pairFrom(target: EventTarget | null): HotspotPair | null {
	const pin = pinFrom(target);
	if (pin) return pairOfPin(pin);
	const item = itemFrom(target);
	if (item) return pairOfItem(item);
	return null;
}

export function pairContains(
	pair: HotspotPair,
	node: EventTarget | null,
): boolean {
	if (!(node instanceof Node)) return false;
	return Boolean(pair.pin?.contains(node) || pair.item?.contains(node));
}

export function pairHasFocus(pair: HotspotPair): boolean {
	return pairContains(pair, document.activeElement);
}

export function pairIsHovered(pair: HotspotPair): boolean {
	return Boolean(pair.pin?.matches(":hover") || pair.item?.matches(":hover"));
}

export function setActive(pair: HotspotPair, active: boolean): void {
	pair.pin?.toggleAttribute("data-active", active);
	pair.item?.toggleAttribute("data-active", active);
}

function itemFrom(target: EventTarget | null): HTMLElement | null {
	if (!(target instanceof Element)) return null;
	return target.closest<HTMLElement>("[data-hotspot-item]");
}

function pinIn(
	figure: HTMLElement,
	number: string | undefined,
): HTMLButtonElement | null {
	return figure.querySelector<HTMLButtonElement>(
		`[data-hotspot-pin="${number}"]`,
	);
}

function pairOfPin(pin: HTMLButtonElement): HotspotPair | null {
	const figure = figureOf(pin);
	if (!figure) return null;
	return { pin, item: itemIn(figure, pin.dataset.hotspotPin) };
}

function pairOfItem(item: HTMLElement): HotspotPair | null {
	const figure = figureOf(item);
	if (!figure) return null;
	return { pin: pinIn(figure, item.dataset.hotspotItem), item };
}
