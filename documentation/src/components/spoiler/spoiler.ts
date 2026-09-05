import { spoilerStyles as s, spoilerVariants } from "./styles";
import {
	isSpoilerVariant,
	type SpoilerFrame,
	type SpoilerParts,
} from "./types";

// Material 3 "standard" easing, medium durations; exits are a touch shorter.
const OPEN_MS = 350;
const CLOSE_MS = 300;
const EASING = "cubic-bezier(0.2, 0, 0, 1)";
const CARD_SCALE = "scale(0.96)";
const SETTLE_GRACE_MS = 50;

const running = new WeakMap<HTMLElement, Animation[]>();

let bound = false;

/**
 * Client controller for gated spoiler sections. Buttons and in-page anchors are
 * handled by delegated `document` listeners so they bind once and survive
 * view-transition DOM swaps.
 */
export function setupSpoilers(): void {
	for (const root of document.querySelectorAll<HTMLElement>("[data-spoiler]")) {
		initSpoiler(root);
	}
	revealForHash(window.location.hash);

	if (bound) return;
	bound = true;
	// Capture phase: the table of contents handles its own anchor clicks with
	// preventDefault + pushState and scrolls at once, so the gate must already
	// be open by the time that handler measures the target.
	document.addEventListener("click", onClick, true);
	window.addEventListener("hashchange", onHashChange);
}

function initSpoiler(root: HTMLElement): void {
	if (root.dataset.spoilerReady === "true") return;
	root.dataset.spoilerReady = "true";

	const parts = resolve(root);
	if (!parts) return;
	applyState(parts, root.dataset.spoilerOpen === "true");
}

function resolve(root: HTMLElement): SpoilerParts | null {
	const bar = root.querySelector<HTMLElement>("[data-spoiler-bar]");
	const shell = root.querySelector<HTMLElement>("[data-spoiler-shell]");
	const content = root.querySelector<HTMLElement>("[data-spoiler-content]");
	const gate = root.querySelector<HTMLElement>("[data-spoiler-gate]");
	const card = root.querySelector<HTMLElement>("[data-spoiler-card]");
	const revealButton = root.querySelector<HTMLElement>("[data-spoiler-reveal]");
	const hideButton = root.querySelector<HTMLElement>("[data-spoiler-hide]");
	if (!bar || !shell || !content || !gate || !card) return null;
	if (!revealButton || !hideButton) return null;
	return { root, bar, shell, content, gate, card, revealButton, hideButton };
}

function paletteOf(root: HTMLElement): string {
	const name = root.dataset.spoilerVariant ?? "warning";
	return spoilerVariants[isSpoilerVariant(name) ? name : "warning"];
}

function applyState(parts: SpoilerParts, open: boolean): void {
	parts.root.dataset.spoilerOpen = String(open);
	parts.root.className = `${s.root} ${paletteOf(parts.root)}`;
	parts.bar.hidden = !open;
	parts.shell.className = `${s.shell} ${open ? s.shellOpen : s.shellClosed}`;
	parts.content.className = `${s.content} ${open ? s.contentOpen : s.contentClosed}`;
	parts.gate.className = s.gate;
	parts.gate.hidden = open;

	parts.revealButton.setAttribute("aria-expanded", String(open));
	parts.hideButton.setAttribute("aria-expanded", String(open));

	toggleInert(parts.content, !open);
	toggleInert(parts.gate, open);
}

function toggleInert(element: HTMLElement, inert: boolean): void {
	if (!inert) {
		element.removeAttribute("inert");
		element.removeAttribute("aria-hidden");
		return;
	}
	element.setAttribute("inert", "");
	element.setAttribute("aria-hidden", "true");
}

function snapshot(parts: SpoilerParts): SpoilerFrame {
	const content = getComputedStyle(parts.content);
	const gateShown = !parts.gate.hidden;
	return {
		height: parts.root.getBoundingClientRect().height,
		filter: content.filter,
		opacity: content.opacity,
		gateOpacity: gateShown ? getComputedStyle(parts.gate).opacity : "0",
		cardTransform: gateShown
			? getComputedStyle(parts.card).transform
			: CARD_SCALE,
	};
}

function cancelRunning(root: HTMLElement): void {
	for (const animation of running.get(root) ?? []) animation.cancel();
	running.delete(root);
}

// The gate is lifted out of flow for the duration of a run so the root's height
// is driven purely by the animation, and the card re-centres inside it.
function liftGate(parts: SpoilerParts): void {
	parts.gate.hidden = false;
	parts.gate.className = `${s.gate} ${s.gateAnimating}`;
	parts.root.className += ` ${s.rootAnimating}`;
}

function startAnimations(
	parts: SpoilerParts,
	from: SpoilerFrame,
	to: SpoilerFrame,
	duration: number,
): Animation[] {
	const options: KeyframeAnimationOptions = { duration, easing: EASING };
	return [
		parts.root.animate(
			[{ height: `${from.height}px` }, { height: `${to.height}px` }],
			options,
		),
		parts.content.animate(
			[
				{ filter: from.filter, opacity: from.opacity },
				{ filter: to.filter, opacity: to.opacity },
			],
			options,
		),
		parts.gate.animate(
			[{ opacity: from.gateOpacity }, { opacity: to.gateOpacity }],
			options,
		),
		parts.card.animate(
			[{ transform: from.cardTransform }, { transform: to.cardTransform }],
			options,
		),
	];
}

// A background tab never ticks its animations to completion, so a timer races
// the `finished` promises.
function settle(animations: Animation[], duration: number): Promise<void> {
	const finished = Promise.all(
		animations.map((animation) => animation.finished),
	).then(
		() => undefined,
		() => undefined,
	);
	const timeout = new Promise<void>((resolve) =>
		window.setTimeout(resolve, duration + SETTLE_GRACE_MS),
	);
	return Promise.race([finished, timeout]);
}

// The map entry tells a stale run apart from one cancelled by a newer toggle.
function finish(
	parts: SpoilerParts,
	animations: Animation[],
	open: boolean,
): boolean {
	if (running.get(parts.root) !== animations) return false;
	running.delete(parts.root);
	for (const animation of animations) animation.finish();
	applyState(parts, open);
	return true;
}

/**
 * One coordinated motion: the root's height, the content's blur/dim and the
 * gate's opacity/scale all run on the same duration and easing.
 */
async function animateTo(parts: SpoilerParts, open: boolean): Promise<boolean> {
	const from = snapshot(parts);
	cancelRunning(parts.root);
	applyState(parts, open);
	const to = snapshot(parts);
	liftGate(parts);

	const duration = open ? OPEN_MS : CLOSE_MS;
	const animations = startAnimations(parts, from, to, duration);
	running.set(parts.root, animations);

	await settle(animations, duration);
	return finish(parts, animations, open);
}

function setOpen(
	parts: SpoilerParts,
	open: boolean,
	animate: boolean,
): Promise<boolean> {
	const settled = !running.has(parts.root);
	if (settled && parts.root.dataset.spoilerOpen === String(open)) {
		return Promise.resolve(true);
	}
	if (animate && !prefersReducedMotion()) return animateTo(parts, open);

	cancelRunning(parts.root);
	applyState(parts, open);
	return Promise.resolve(true);
}

function prefersReducedMotion(): boolean {
	return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

function stickyOffset(parts: SpoilerParts): number {
	const top = Number.parseFloat(getComputedStyle(parts.bar).top);
	return Number.isFinite(top) ? top : 0;
}

function scrollerOf(element: HTMLElement): Element {
	let node = element.parentElement;
	while (node) {
		const overflow = getComputedStyle(node).overflowY;
		const scrolls = overflow === "auto" || overflow === "scroll";
		if (scrolls && node.scrollHeight > node.clientHeight) return node;
		node = node.parentElement;
	}
	return document.scrollingElement ?? document.documentElement;
}

/**
 * When the header bar is stuck, the section's top edge is somewhere above the
 * scroll port. Scrolling the root up to the bar's position first keeps the bar
 * visually in place while the section collapses beneath it.
 */
function keepGateInView(parts: SpoilerParts): void {
	const scroller = scrollerOf(parts.root);
	const portTop =
		scroller === document.scrollingElement
			? 0
			: scroller.getBoundingClientRect().top;
	const top = parts.root.getBoundingClientRect().top - portTop;
	const offset = stickyOffset(parts);
	if (top >= offset) return;
	scroller.scrollBy({ top: top - offset, behavior: "instant" });
}

function focusRevealed(parts: SpoilerParts): void {
	const heading = parts.content.querySelector<HTMLElement>(
		"h1, h2, h3, h4, h5, h6",
	);
	const target = heading ?? parts.hideButton;
	if (target === heading) target.tabIndex = -1;
	target.focus({ preventScroll: true });
}

function samePageHash(origin: Element): string | null {
	const link = origin.closest<HTMLAnchorElement>("a[href]");
	if (!link) return null;
	const url = new URL(link.href, window.location.href);
	if (url.origin !== window.location.origin) return null;
	if (url.pathname !== window.location.pathname) return null;
	return url.hash.length > 0 ? url.hash : null;
}

function onClick(event: MouseEvent): void {
	if (event.button !== 0) return;
	const origin = event.target instanceof Element ? event.target : null;
	if (!origin) return;

	const toggle = origin.closest<HTMLElement>(
		"[data-spoiler-reveal], [data-spoiler-hide]",
	);
	if (toggle) {
		void onToggle(toggle);
		return;
	}

	const hash = samePageHash(origin);
	if (hash) revealForHash(hash);
}

async function onToggle(button: HTMLElement): Promise<void> {
	const root = button.closest<HTMLElement>("[data-spoiler]");
	if (!root) return;
	const parts = resolve(root);
	if (!parts) return;

	const open = button.hasAttribute("data-spoiler-reveal");
	if (!open) keepGateInView(parts);
	const finished = await setOpen(parts, open, true);
	if (!finished) return;
	if (open) {
		focusRevealed(parts);
		return;
	}
	parts.revealButton.focus({ preventScroll: true });
}

function onHashChange(): void {
	revealForHash(window.location.hash);
}

/**
 * Opens any closed spoiler that contains the element a fragment link points at,
 * so table-of-contents entries for headings inside a gate still work. The
 * reveal is instant: the browser scrolls right after, and it must land on the
 * final layout.
 */
function revealForHash(hash: string): void {
	if (hash.length < 2) return;
	const id = safeDecode(hash.slice(1));
	const target = document.getElementById(id);
	if (!target) return;

	const root = target.closest<HTMLElement>("[data-spoiler]");
	if (!root || root.dataset.spoilerOpen === "true") return;
	const parts = resolve(root);
	if (!parts) return;

	void setOpen(parts, true, false);
	requestAnimationFrame(() => target.scrollIntoView({ block: "start" }));
}

function safeDecode(value: string): string {
	try {
		return decodeURIComponent(value);
	} catch {
		return value;
	}
}
