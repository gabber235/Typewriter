import {
	focusSection,
	recordJump,
	scrollBehavior,
	scrollToSection,
} from "./navigation";
import { pinSection, watchSections } from "./scroll-spy";
import type { SpyState } from "./types";

// Keeps the current item this far from the edges of a scrolled list.
const REVEAL_MARGIN = 32;
// The rail steps in by the list's indent per heading level (0.75rem in
// styles.ts), sits half its 2px stroke from the edge, and bends over 6px.
const RAIL_STEP_REM = 0.75;
const RAIL_INSET = 1;
const RAIL_BEND = 6;
// Longer than any rail, so the dash never repeats, not even mid-transition.
const RAIL_DASH_GAP = 100_000;

const idOf = (link: HTMLAnchorElement): string =>
	decodeURIComponent(link.hash.slice(1));

const isPlainClick = (event: MouseEvent): boolean =>
	!event.defaultPrevented &&
	event.button === 0 &&
	!event.metaKey &&
	!event.ctrlKey &&
	!event.shiftKey &&
	!event.altKey;

interface RailParts {
	root: HTMLElement;
	line: SVGSVGElement;
	track: SVGPathElement;
	thumb: SVGPathElement;
}

function findRailParts(scope: Element): RailParts | null {
	const root = scope.querySelector<HTMLElement>("[data-toc-rail]");
	const line = scope.querySelector<SVGSVGElement>("[data-toc-line]");
	const track = scope.querySelector<SVGPathElement>("[data-toc-track]");
	const thumb = scope.querySelector<SVGPathElement>("[data-toc-thumb]");
	if (!root || !line || !track || !thumb) return null;
	return { root, line, track, thumb };
}

abstract class TocElement extends HTMLElement {
	protected links = new Map<string, HTMLAnchorElement>();
	private stopWatching?: () => void;

	connectedCallback(): void {
		this.links = new Map(
			[...this.querySelectorAll<HTMLAnchorElement>("a[data-toc-link]")].map(
				(link) => [idOf(link), link],
			),
		);
		this.addEventListener("click", this.onClick);
		this.setup();
		this.stopWatching = watchSections([...this.links.keys()], (state) => {
			if (this.checkVisibility()) this.render(state);
		});
	}

	disconnectedCallback(): void {
		this.stopWatching?.();
		this.removeEventListener("click", this.onClick);
		this.teardown();
	}

	protected setup(): void {}
	protected teardown(): void {}
	protected beforeFollow(): void {}
	protected abstract render(state: SpyState): void;

	private readonly onClick = (event: MouseEvent): void => {
		if (!isPlainClick(event) || !(event.target instanceof Element)) return;
		const link = event.target.closest<HTMLAnchorElement>("a[data-toc-link]");
		if (!link) return;
		event.preventDefault();
		const id = idOf(link);
		this.beforeFollow();
		pinSection(id);
		recordJump(link.hash);
		scrollToSection(id, scrollBehavior());
		focusSection(id);
	};

	protected renderLinks(state: SpyState): HTMLAnchorElement | undefined {
		for (const [id, link] of this.links) {
			const isCurrent = id === state.current;
			link.toggleAttribute(
				"data-visible",
				!isCurrent && state.visible.includes(id),
			);
			if (isCurrent) link.setAttribute("aria-current", "true");
			else link.removeAttribute("aria-current");
		}
		return this.links.get(state.current);
	}

	protected renderProgress(progress: number): void {
		const offset = String(100 - progress * 100);
		for (const ring of this.querySelectorAll<SVGElement>("[data-toc-ring]")) {
			ring.style.strokeDashoffset = offset;
		}
		const value = String(Math.round(progress * 100));
		for (const percent of this.querySelectorAll<HTMLElement>(
			"[data-toc-percent]",
		)) {
			const bare = percent.dataset.tocPercent === "bare";
			percent.textContent = bare ? value : `${value}%`;
		}
	}
}

class PageToc extends TocElement {
	private scroller: HTMLElement | null = null;
	private rail: RailParts | null = null;
	private railPoints: { x: number; y: number }[] = [];
	// Cumulative path length at each point.
	private railLengths: number[] = [];
	private visible: readonly string[] = [];
	private pointerInside = false;
	private revealed: HTMLAnchorElement | null = null;
	private abort = new AbortController();
	// Wrapping headings and late fonts move the links; redraw with them.
	private readonly railObserver = new ResizeObserver(() => {
		this.drawRail();
		this.renderThumb(this.visible);
	});

	protected override setup(): void {
		this.abort = new AbortController();
		const { signal } = this.abort;
		this.scroller = this.querySelector("[data-toc-scroll]");
		this.rail = findRailParts(this);
		if (this.rail) this.railObserver.observe(this.rail.root);
		this.scroller?.addEventListener("scroll", () => this.updateFades(), {
			passive: true,
			signal,
		});
		this.scroller?.addEventListener(
			"pointerenter",
			() => {
				this.pointerInside = true;
			},
			{ signal },
		);
		this.scroller?.addEventListener(
			"pointerleave",
			() => {
				this.pointerInside = false;
			},
			{ signal },
		);
	}

	protected override teardown(): void {
		this.abort.abort();
		this.railObserver.disconnect();
	}

	protected render(state: SpyState): void {
		const current = this.renderLinks(state);
		this.renderProgress(state.progress);
		this.renderThumb(state.visible);
		this.updateFades();
		if (!current || current === this.revealed || this.pointerInside) return;
		this.revealed = current;
		this.reveal(current);
	}

	// One vertical run per item, indented by its depth, with a short diagonal
	// wherever the depth changes between neighbours.
	private drawRail(): void {
		const parts = this.rail;
		if (!parts) return;
		const { root, line, track, thumb } = parts;
		const rem = Number.parseFloat(
			getComputedStyle(document.documentElement).fontSize,
		);
		const origin = root.getBoundingClientRect().top;
		const runs = [...this.links.values()].map((link) => {
			const { top, bottom } = link.getBoundingClientRect();
			const depth = Number(link.dataset.depth ?? 0);
			return {
				x: depth * rem * RAIL_STEP_REM + RAIL_INSET,
				top: top - origin,
				bottom: bottom - origin,
			};
		});
		this.railPoints = runs.flatMap(({ x, top, bottom }, index) => {
			const previous = runs[index - 1];
			const next = runs[index + 1];
			const start = previous && previous.x !== x ? top + RAIL_BEND : top;
			const end = next && next.x !== x ? bottom - RAIL_BEND : bottom;
			return [
				{ x, y: start },
				{ x, y: end },
			];
		});
		this.railLengths = this.railPoints.map((point, index, points) => {
			const previous = points[index - 1];
			return previous
				? Math.hypot(point.x - previous.x, point.y - previous.y)
				: 0;
		});
		for (let i = 1; i < this.railLengths.length; i++) {
			this.railLengths[i] =
				(this.railLengths[i] ?? 0) + (this.railLengths[i - 1] ?? 0);
		}
		const path = this.railPoints
			.map(({ x, y }, index) => `${index === 0 ? "M" : "L"}${x} ${y}`)
			.join("");
		track.setAttribute("d", path);
		thumb.setAttribute("d", path);
		const width = Math.max(0, ...runs.map(({ x }) => x)) + RAIL_INSET;
		line.setAttribute("width", String(width));
		line.setAttribute("height", String(root.offsetHeight));
	}

	// Distance along the rail at a given height. The rail only ever moves
	// down, so every height maps to exactly one point.
	private railLengthAt(y: number): number {
		const points = this.railPoints;
		const lengths = this.railLengths;
		const index = points.findIndex(
			(point, i) => y <= point.y || i === points.length - 1,
		);
		const end = points[index];
		const start = points[index - 1];
		if (!end) return 0;
		if (!start || end.y === start.y) return lengths[index] ?? 0;
		const t = Math.min(Math.max((y - start.y) / (end.y - start.y), 0), 1);
		const from = lengths[index - 1] ?? 0;
		return from + t * ((lengths[index] ?? 0) - from);
	}

	// Lights the part of the rail beside every item whose section is on
	// screen, so it mirrors the viewport rather than a single heading. Drawn
	// as a dash along the full path so it follows the bends and animates.
	private renderThumb(visible: readonly string[]): void {
		this.visible = visible;
		const parts = this.rail;
		if (!parts) return;
		if (this.railPoints.length === 0) this.drawRail();
		const { root, thumb } = parts;
		const first = this.links.get(visible[0] ?? "");
		const last = this.links.get(visible.at(-1) ?? "");
		const wasActive = thumb.hasAttribute("data-active");
		thumb.toggleAttribute("data-active", Boolean(first && last));
		if (!first || !last) return;
		const origin = root.getBoundingClientRect().top;
		const from = this.railLengthAt(first.getBoundingClientRect().top - origin);
		const to = this.railLengthAt(last.getBoundingClientRect().bottom - origin);
		// Appearing, it is placed rather than slid in from wherever it was.
		if (!wasActive) thumb.style.transition = "none";
		thumb.style.strokeDasharray = `${to - from} ${RAIL_DASH_GAP}`;
		thumb.style.strokeDashoffset = String(-from);
		if (wasActive) return;
		thumb.getBoundingClientRect();
		thumb.style.removeProperty("transition");
	}

	private reveal(link: HTMLAnchorElement): void {
		const scroller = this.scroller;
		if (!scroller || scroller.scrollHeight <= scroller.clientHeight) return;
		const box = scroller.getBoundingClientRect();
		const { top, bottom } = link.getBoundingClientRect();
		const above = top - (box.top + REVEAL_MARGIN);
		const below = bottom - (box.bottom - REVEAL_MARGIN);
		const delta = above < 0 ? above : Math.max(below, 0);
		if (delta === 0) return;
		scroller.scrollBy({ top: delta, behavior: scrollBehavior() });
	}

	private updateFades(): void {
		const scroller = this.scroller;
		if (!scroller) return;
		const { scrollTop, clientHeight, scrollHeight } = scroller;
		scroller.toggleAttribute("data-fade-top", scrollTop > 1);
		scroller.toggleAttribute(
			"data-fade-bottom",
			scrollTop + clientHeight < scrollHeight - 1,
		);
	}
}

class PageTocSheet extends TocElement {
	private dialog: HTMLDialogElement | null = null;
	private pill: HTMLButtonElement | null = null;
	private label: HTMLElement | null = null;
	private abort = new AbortController();

	protected override setup(): void {
		this.abort = new AbortController();
		const { signal } = this.abort;
		this.dialog = this.querySelector("dialog");
		this.pill = this.querySelector("[data-toc-pill]");
		this.label = this.querySelector("[data-toc-label]");
		this.pill?.addEventListener("click", () => this.open(), { signal });
		this.dialog?.addEventListener("close", () => this.onClose(), { signal });
		this.dialog?.addEventListener(
			"click",
			(event) => this.onDialogClick(event),
			{
				signal,
			},
		);
	}

	protected override teardown(): void {
		this.abort.abort();
		this.dialog?.close();
	}

	protected override beforeFollow(): void {
		this.dialog?.close();
	}

	protected render(state: SpyState): void {
		const current = this.renderLinks(state);
		this.renderProgress(state.progress);
		if (this.label && current) this.label.textContent = current.textContent;
	}

	private open(): void {
		if (!this.dialog || this.dialog.open) return;
		this.dialog.showModal();
		this.pill?.setAttribute("aria-expanded", "true");
		this.querySelector<HTMLAnchorElement>(
			'dialog a[aria-current="true"]',
		)?.focus();
	}

	private onClose(): void {
		this.pill?.setAttribute("aria-expanded", "false");
	}

	// Clicks on the ::backdrop land on the dialog itself; its content fills
	// the dialog box edge to edge, so nothing else does.
	private onDialogClick(event: MouseEvent): void {
		const target = event.target;
		if (target === this.dialog) {
			this.dialog?.close();
			return;
		}
		if (target instanceof Element && target.closest("[data-toc-close]")) {
			this.dialog?.close();
		}
	}
}

customElements.define("page-toc", PageToc);
customElements.define("page-toc-sheet", PageTocSheet);
