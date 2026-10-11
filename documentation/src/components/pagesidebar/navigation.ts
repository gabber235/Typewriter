export const PAGE_TOP_ID = "_top";

// `scrollTo({ behavior })` ignores the CSS reduced-motion override.
export const scrollBehavior = (): ScrollBehavior =>
	matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth";

export const getScrollPane = (): HTMLElement | null =>
	document.querySelector<HTMLElement>(".content-pane");

// Headings inside a closed <details> have no boxes; use the nearest ancestor
// that is laid out instead.
export function laidOut(element: Element): Element {
	let node = element;
	while (node.getClientRects().length === 0 && node.parentElement) {
		node = node.parentElement;
	}
	return node;
}

export function scrollToSection(id: string, behavior: ScrollBehavior): void {
	const pane = getScrollPane();
	if (id === PAGE_TOP_ID && pane) {
		pane.scrollTo({ top: 0, behavior });
		return;
	}
	const target = document.getElementById(id);
	if (!target) return;
	laidOut(target).scrollIntoView({ behavior, block: "start" });
}

// Moves keyboard and screen reader position along with the scroll.
export function focusSection(id: string): void {
	const target = document.getElementById(id);
	if (!target || target.getClientRects().length === 0) return;
	if (!target.hasAttribute("tabindex")) target.tabIndex = -1;
	target.focus({ preventScroll: true });
}

// A null state keeps Astro's router out of Back/Forward between these
// entries; the scroll spy restores the pane position itself.
export function recordJump(hash: string): void {
	if (location.hash === hash) return;
	history.pushState(null, "", hash);
}
