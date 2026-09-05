import {
	initFigure,
	legendIsVisible,
	measureAllStages,
	needsLegendFallback,
	scrollIntoLegend,
	showInLegend,
} from "./figure";
import {
	figureOf,
	pairContains,
	pairFrom,
	pairHasFocus,
	pairIsHovered,
	pinFrom,
	setActive,
	stageOf,
} from "./pairs";
import {
	bridgeTabOrder,
	closePopover,
	hasOpenPopover,
	isInsideOpenPopover,
	isOpenPin,
	openPopover,
	queueReposition,
	resetPopover,
} from "./popover";

let bound = false;

/** Enhance every `:::hotspots` figure on the page; safe to call repeatedly. */
export function setupHotspots(): void {
	markScripting();
	bindOnce();
	for (const figure of document.querySelectorAll<HTMLElement>(
		"[data-hotspots]",
	)) {
		initFigure(figure);
	}
}

// Without this class every legend stays visible (the no-JS fallback). The
// ClientRouter re-syncs <html> attributes on navigation, hence the re-apply.
function markScripting(): void {
	document.documentElement.classList.add("hotspots-js");
}

function bindOnce(): void {
	if (bound) return;
	bound = true;
	document.addEventListener("mouseover", onMouseOver);
	document.addEventListener("mouseout", onMouseOut);
	document.addEventListener("focusin", onFocusIn);
	document.addEventListener("focusout", onFocusOut);
	document.addEventListener("click", onClick);
	document.addEventListener("keydown", onKeyDown);
	// Capture catches scrolls inside nested scrollers, not just the window.
	document.addEventListener("scroll", queueReposition, {
		passive: true,
		capture: true,
	});
	window.addEventListener("resize", onResize, { passive: true });
	document.addEventListener("astro:before-swap", resetPopover);
}

function onMouseOver(event: MouseEvent): void {
	const pair = pairFrom(event.target);
	if (!pair) return;
	setActive(pair, true);
}

function onMouseOut(event: MouseEvent): void {
	const pair = pairFrom(event.target);
	if (!pair) return;
	if (pairContains(pair, event.relatedTarget)) return;
	if (pairHasFocus(pair)) return;
	setActive(pair, false);
}

function onFocusIn(event: FocusEvent): void {
	if (hasOpenPopover() && !isInsideOpenPopover(event.target)) {
		closePopover(false);
	}

	const pair = pairFrom(event.target);
	if (!pair) return;
	setActive(pair, true);

	const pin = pinFrom(event.target);
	if (!pin?.matches(":focus-visible") || !pair.item) return;
	const figure = figureOf(pin);
	if (!figure || !legendIsVisible(figure)) return;
	scrollIntoLegend(pair.item);
}

function onFocusOut(event: FocusEvent): void {
	const pair = pairFrom(event.target);
	if (!pair) return;
	if (pairContains(pair, event.relatedTarget)) return;
	if (pairIsHovered(pair)) return;
	setActive(pair, false);
}

function onClick(event: MouseEvent): void {
	const pin = pinFrom(event.target);
	if (pin) {
		event.preventDefault();
		toggle(pin);
		return;
	}
	if (!hasOpenPopover() || isInsideOpenPopover(event.target)) return;
	closePopover(false);
}

function onKeyDown(event: KeyboardEvent): void {
	if (!hasOpenPopover()) return;
	if (event.key === "Escape") {
		event.preventDefault();
		closePopover(true);
		return;
	}
	if (event.key === "Tab") bridgeTabOrder(event);
}

function onResize(): void {
	measureAllStages();
	queueReposition();
}

function toggle(pin: HTMLButtonElement): void {
	const wasOpen = isOpenPin(pin);
	closePopover(false);
	if (wasOpen) return;

	const figure = figureOf(pin);
	const stage = figure ? stageOf(figure) : null;
	const description = document.getElementById(
		pin.getAttribute("aria-describedby") ?? "",
	);
	if (!figure || !stage || !description) return;

	if (needsLegendFallback(figure, stage)) {
		showInLegend(figure, pin);
		return;
	}
	openPopover(pin, figure, description);
}
