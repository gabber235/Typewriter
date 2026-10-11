import { pinFrom } from "./pairs";
import {
	closePopover,
	currentOpenMode,
	isInsideCard,
	isOpenPin,
	openPinElement,
} from "./popover";

// A short wait before opening, so sweeping the pointer across the image does
// not flash every card on the way.
const OPEN_DELAY = 120;
// Long enough to cross the gap between the pin and its card (1.4.13:
// hover content must be hoverable).
const CLOSE_DELAY = 200;

let openTimer = 0;
let closeTimer = 0;
// A pin whose card was dismissed with Escape stays closed until the pointer
// leaves it (1.4.13: dismissible without moving the pointer).
let dismissed: HTMLButtonElement | null = null;

const canHover = (): boolean =>
	matchMedia("(hover: hover) and (pointer: fine)").matches;

const isMouse = (event: PointerEvent): boolean =>
	event.pointerType === "mouse" && canHover();

/** Opens a pin's card on hover; `open` returns false when the figure shows its legend instead. */
export function onPointerOver(
	event: PointerEvent,
	open: (pin: HTMLButtonElement) => void,
): void {
	if (!isMouse(event)) return;
	if (isInsideCard(event.target)) {
		clearTimeout(closeTimer);
		return;
	}
	const pin = pinFrom(event.target);
	if (!pin) return;
	clearTimeout(closeTimer);
	if (pin === dismissed || isOpenPin(pin)) return;
	clearTimeout(openTimer);
	openTimer = window.setTimeout(() => {
		if (pin.matches(":hover")) open(pin);
	}, OPEN_DELAY);
}

export function onPointerOut(event: PointerEvent): void {
	if (!isMouse(event)) return;
	const pin = pinFrom(event.target);
	const leavingPin = pin !== null && !pin.contains(event.relatedTarget as Node);
	if (leavingPin) {
		clearTimeout(openTimer);
		if (pin === dismissed) dismissed = null;
	}
	if (!leavingPin && !isInsideCard(event.target)) return;
	if (currentOpenMode() !== "hover") return;
	clearTimeout(closeTimer);
	closeTimer = window.setTimeout(closeIfLeft, CLOSE_DELAY);
}

/** Escape on a hover-opened card: close it in place, without moving focus. */
export function dismissHovered(): boolean {
	const pin = openPinElement();
	if (!pin || currentOpenMode() !== "hover") return false;
	dismissed = pin;
	closePopover(false);
	return true;
}

export function cancelHover(): void {
	clearTimeout(openTimer);
	clearTimeout(closeTimer);
}

function closeIfLeft(): void {
	const pin = openPinElement();
	if (!pin || currentOpenMode() !== "hover") return;
	const card = document.getElementById("hotspots-popover");
	if (pin.matches(":hover") || card?.matches(":hover")) return;
	closePopover(false);
}
