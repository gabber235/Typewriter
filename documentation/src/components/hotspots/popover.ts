import { hotspotStyles as s } from "./styles";
import type { HotspotPlacement, HotspotPopover } from "./types";

const MARGIN = 12;
const GAP = 10;
const ARROW_INSET = 16;
const POPOVER_MAX_WIDTH = 352;
const FOCUSABLE =
	'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])';

let openPin: HTMLButtonElement | null = null;
let popover: HotspotPopover | null = null;
let repositionQueued = false;

export function hasOpenPopover(): boolean {
	return openPin !== null;
}

export function isOpenPin(pin: HTMLButtonElement): boolean {
	return openPin === pin;
}

export function isInsideOpenPopover(target: EventTarget | null): boolean {
	if (!(target instanceof Node)) return false;
	if (openPin?.contains(target)) return true;
	return Boolean(
		popover && !popover.element.hidden && popover.element.contains(target),
	);
}

export function openPopover(
	pin: HTMLButtonElement,
	figure: HTMLElement,
	description: HTMLElement,
): void {
	const card = ensurePopover();
	card.badge.textContent = pin.dataset.hotspotPin ?? "";
	card.badge.hidden = figure.dataset.hotspotsNumbers !== "true";
	card.body.innerHTML = description.innerHTML;
	card.element.setAttribute("aria-label", pin.getAttribute("aria-label") ?? "");
	card.element.hidden = false;
	pin.setAttribute("aria-expanded", "true");
	pin.setAttribute("aria-controls", card.element.id);
	openPin = pin;
	position(pin, card.element);
}

export function closePopover(refocus: boolean): void {
	const pin = openPin;
	openPin = null;
	if (popover) popover.element.hidden = true;
	if (!pin) return;
	pin.setAttribute("aria-expanded", "false");
	pin.removeAttribute("aria-controls");
	if (refocus) pin.focus();
}

export function closePopoverInside(figure: HTMLElement): void {
	if (openPin && figure.contains(openPin)) closePopover(false);
}

export function resetPopover(): void {
	openPin = null;
	if (popover) popover.element.hidden = true;
}

// The card sits at the end of <body>, so Tab order is bridged by hand: forward
// from the pin steps into the card, back from its first link returns to the
// pin. Tabbing past the last link falls through and focusin closes the card.
export function bridgeTabOrder(event: KeyboardEvent): void {
	if (!openPin || !popover || popover.element.hidden) return;
	const first = popover.element.querySelector<HTMLElement>(FOCUSABLE);
	if (!first) return;
	if (!event.shiftKey && document.activeElement === openPin) {
		event.preventDefault();
		first.focus();
		return;
	}
	if (event.shiftKey && document.activeElement === first) {
		event.preventDefault();
		openPin.focus();
	}
}

export function queueReposition(): void {
	if (repositionQueued) return;
	repositionQueued = true;
	requestAnimationFrame(reposition);
}

function reposition(): void {
	repositionQueued = false;
	if (!openPin || !popover || popover.element.hidden) return;
	if (!openPin.isConnected || !inViewport(openPin)) {
		closePopover(false);
		return;
	}
	position(openPin, popover.element);
}

function ensurePopover(): HotspotPopover {
	popover ??= createPopover();
	// The ClientRouter swaps <body>, which detaches the card.
	if (!popover.element.isConnected) document.body.appendChild(popover.element);
	return popover;
}

function createPopover(): HotspotPopover {
	const element = document.createElement("div");
	element.id = "hotspots-popover";
	element.className = s.popover;
	element.setAttribute("role", "dialog");
	element.hidden = true;

	const inner = document.createElement("div");
	inner.className = s.popoverInner;
	const badge = document.createElement("span");
	badge.className = s.popoverBadge;
	badge.setAttribute("aria-hidden", "true");
	const body = document.createElement("div");
	body.className = s.popoverBody;
	inner.append(badge, body);
	element.append(inner);
	return { element, badge, body };
}

function inViewport(pin: HTMLButtonElement): boolean {
	const box = pin.getBoundingClientRect();
	return box.bottom > 0 && box.top < window.innerHeight;
}

function clamp(value: number, min: number, max: number): number {
	return Math.max(min, Math.min(max, value));
}

function choosePlacement(anchor: DOMRect, box: DOMRect): HotspotPlacement {
	const spaceBelow = window.innerHeight - anchor.bottom - GAP - MARGIN;
	const spaceAbove = anchor.top - GAP - MARGIN;
	return spaceBelow >= box.height || spaceBelow >= spaceAbove
		? "bottom"
		: "top";
}

/** Fixed, viewport-relative placement: below the pin, flipped above when there is more room, clamped on both axes. */
function position(pin: HTMLButtonElement, card: HTMLElement): void {
	const anchor = pin.getBoundingClientRect();
	card.style.maxWidth = `${Math.min(POPOVER_MAX_WIDTH, window.innerWidth - MARGIN * 2)}px`;
	const box = card.getBoundingClientRect();
	const placement = choosePlacement(anchor, box);

	const centerX = anchor.left + anchor.width / 2;
	const top =
		placement === "bottom"
			? anchor.bottom + GAP
			: anchor.top - GAP - box.height;
	const left = clamp(
		centerX - box.width / 2,
		MARGIN,
		Math.max(MARGIN, window.innerWidth - box.width - MARGIN),
	);

	card.style.top = `${clamp(top, MARGIN, Math.max(MARGIN, window.innerHeight - box.height - MARGIN))}px`;
	card.style.left = `${left}px`;
	card.style.setProperty(
		"--hs-arrow-x",
		`${clamp(centerX - left, ARROW_INSET, Math.max(ARROW_INSET, box.width - ARROW_INSET))}px`,
	);
	card.dataset.placement = placement;
}
