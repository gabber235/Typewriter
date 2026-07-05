import { glossaryStyles as s } from "./styles";

/**
 * Client controller for glossary hover cards.
 *
 * All listeners are delegated on `document`, so they bind exactly once and
 * survive view-transition DOM swaps. Card content is the build-time-rendered
 * fragment at /glossary-card/<slug>/, fetched on first hover and cached for
 * the rest of the visit.
 */

const OPEN_DELAY = 200;
const CLOSE_GRACE = 300;
const GAP = 8;
const MARGIN = 8;

const cache = new Map<string, Promise<string | null>>();

let card: HTMLDivElement | null = null;
let currentLink: HTMLAnchorElement | null = null;
let pendingLink: HTMLAnchorElement | null = null;
let openTimer = 0;
let closeTimer = 0;
let bound = false;
let lastPointerType = "mouse";
let lastPointerDownAt = 0;
// Snapshot of which term's card was visible when the current pointer press
// started. The navigate-vs-open decision uses this instead of live state, so
// a click can't race the fetch or the focus-triggered open that happens
// mid-tap.
let gestureOpenLink: HTMLAnchorElement | null = null;
let repositionQueued = false;

export function setupGlossaryPopover(): void {
	if (bound) return;
	bound = true;

	document.addEventListener("mouseover", onMouseOver);
	document.addEventListener("mouseout", onMouseOut);
	document.addEventListener("focusin", onFocusIn);
	document.addEventListener("focusout", onFocusOut);
	document.addEventListener("keydown", onKeyDown);
	document.addEventListener("pointerdown", onPointerDown);
	document.addEventListener("click", onClick);
	// Keep the card glued to its term while the page moves under it. Capture
	// catches scrolls inside nested scrollers, not just the window.
	document.addEventListener("scroll", onReposition, {
		passive: true,
		capture: true,
	});
	window.addEventListener("resize", onReposition, { passive: true });
	// Never carry an open card across a view-transition navigation.
	document.addEventListener("astro:before-swap", close);
}

function termFrom(target: EventTarget | null): HTMLAnchorElement | null {
	return target instanceof Element
		? target.closest<HTMLAnchorElement>("a[data-glossary-term]")
		: null;
}

function onMouseOver(event: MouseEvent): void {
	if (card && event.target instanceof Node && card.contains(event.target)) {
		window.clearTimeout(closeTimer);
		return;
	}

	const link = termFrom(event.target);
	if (!link) return;
	window.clearTimeout(closeTimer);
	if (link === currentLink || link === pendingLink) return;

	cancelOpen();
	pendingLink = link;
	const slug = link.dataset.glossaryTerm ?? "";
	// Warm the cache immediately; only the card itself waits for intent.
	void fetchFragment(slug);
	openTimer = window.setTimeout(() => void open(link, slug), OPEN_DELAY);
}

function onMouseOut(event: MouseEvent): void {
	const from = event.target;
	const leavingCard = card && from instanceof Node && card.contains(from);
	if (!termFrom(from) && !leavingCard) return;

	const to = event.relatedTarget;
	if (to instanceof Node) {
		if (card?.contains(to)) return;
		const toLink = termFrom(to);
		if (toLink && (toLink === currentLink || toLink === pendingLink)) return;
	}

	cancelOpen();
	scheduleClose();
}

function onFocusIn(event: FocusEvent): void {
	// Only keyboard-driven focus opens the card. A pointer press focuses the
	// link too, and letting that open the card mid-tap would make the tap
	// count as "card already open" and navigate on the first touch.
	if (event.timeStamp - lastPointerDownAt < 500) return;

	const link = termFrom(event.target);
	if (!link || link === currentLink) return;
	window.clearTimeout(closeTimer);
	cancelOpen();
	pendingLink = link;
	void open(link, link.dataset.glossaryTerm ?? "");
}

function onFocusOut(event: FocusEvent): void {
	if (!termFrom(event.target)) return;
	scheduleClose();
}

function onKeyDown(event: KeyboardEvent): void {
	if (event.key === "Escape") close();
}

function onPointerDown(event: PointerEvent): void {
	lastPointerType = event.pointerType || "mouse";
	lastPointerDownAt = event.timeStamp;
	gestureOpenLink = card && !card.hidden ? currentLink : null;

	// Tapping outside the card (and not on a term) dismisses it on touch.
	if (
		lastPointerType === "touch" &&
		card &&
		!card.hidden &&
		event.target instanceof Node &&
		!card.contains(event.target) &&
		!termFrom(event.target)
	) {
		close();
	}
}

function onClick(event: MouseEvent): void {
	const link = termFrom(event.target);
	if (!link) return;
	// Keyboard activation (detail === 0): focus already showed the card, so
	// Enter always navigates.
	if (event.detail === 0) return;
	// Navigate only when this term's card was already open when the press
	// started; otherwise the click opens it. Desktop hover usually opened it
	// beforehand, so clicking navigates; on mobile the first tap shows the
	// card and the second tap navigates.
	if (gestureOpenLink === link) return;
	event.preventDefault();
	window.clearTimeout(closeTimer);
	cancelOpen();
	pendingLink = link;
	void open(link, link.dataset.glossaryTerm ?? "");
}

async function open(link: HTMLAnchorElement, slug: string): Promise<void> {
	const html = await fetchFragment(slug);
	// The hover may have moved on while the fragment was loading.
	if (html === null || pendingLink !== link || !link.isConnected) return;

	if (currentLink && currentLink !== link) {
		currentLink.removeAttribute("aria-expanded");
		currentLink.removeAttribute("aria-controls");
	}
	currentLink = link;
	pendingLink = null;

	const el = ensureCard();
	el.setAttribute("aria-label", link.dataset.glossaryTitle ?? slug);
	el.innerHTML = html;
	el.hidden = false;
	link.setAttribute("aria-expanded", "true");
	link.setAttribute("aria-controls", "glossary-card");
	position(link, el);
}

function close(): void {
	cancelOpen();
	window.clearTimeout(closeTimer);
	if (card) card.hidden = true;
	if (currentLink) {
		currentLink.removeAttribute("aria-expanded");
		currentLink.removeAttribute("aria-controls");
		currentLink = null;
	}
}

function cancelOpen(): void {
	window.clearTimeout(openTimer);
	pendingLink = null;
}

function scheduleClose(): void {
	window.clearTimeout(closeTimer);
	closeTimer = window.setTimeout(close, CLOSE_GRACE);
}

function onReposition(): void {
	if (repositionQueued) return;
	repositionQueued = true;
	requestAnimationFrame(() => {
		repositionQueued = false;
		if (!card || card.hidden || !currentLink) return;
		if (!currentLink.isConnected) {
			close();
			return;
		}
		position(currentLink, card);
	});
}

function position(link: HTMLAnchorElement, el: HTMLDivElement): void {
	const anchor = link.getBoundingClientRect();
	const box = el.getBoundingClientRect();
	const fitsBelow = anchor.bottom + GAP + box.height <= window.innerHeight;
	const top = fitsBelow
		? anchor.bottom + GAP
		: Math.max(MARGIN, anchor.top - GAP - box.height);
	const left = Math.min(
		Math.max(MARGIN, anchor.left),
		Math.max(MARGIN, window.innerWidth - box.width - MARGIN),
	);
	el.style.top = `${top}px`;
	el.style.left = `${left}px`;
}

function ensureCard(): HTMLDivElement {
	// The ClientRouter swaps <body>, so re-append if the card got detached.
	if (card?.isConnected) return card;
	if (!card) {
		card = document.createElement("div");
		card.id = "glossary-card";
		card.className = s.card;
		card.setAttribute("role", "dialog");
		card.hidden = true;
	}
	document.body.appendChild(card);
	return card;
}

function fetchFragment(slug: string): Promise<string | null> {
	let pending = cache.get(slug);
	if (!pending) {
		const base = import.meta.env.BASE_URL.replace(/\/?$/, "/");
		pending = fetch(`${base}glossary-card/${slug}/`)
			.then((response) => (response.ok ? response.text() : null))
			.catch(() => null)
			.then((html) => {
				// Don't cache failures; the term degrades to a plain link.
				if (html === null) cache.delete(slug);
				return html;
			});
		cache.set(slug, pending);
	}
	return pending;
}
