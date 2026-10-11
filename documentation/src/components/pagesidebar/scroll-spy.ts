import {
	getScrollPane,
	laidOut,
	PAGE_TOP_ID,
	scrollToSection,
} from "./navigation";
import type { SpyState } from "./types";

// A heading becomes current once it passes this line: a quarter of the way
// down the pane, but never more than 160px, so tall screens don't lag.
const READING_LINE_RATIO = 0.25;
const READING_LINE_MAX = 160;
// A clicked link stays current until the scroll it started has been still
// for this long.
const SETTLE_MS = 150;

type Listener = (state: SpyState) => void;

interface Section {
	id: string;
	start: number;
	end: number;
}

const clamp01 = (value: number): number => Math.min(Math.max(value, 0), 1);

// One per page, shared by the desktop and mobile TOC so the layout is only
// measured once per frame.
class ScrollSpy {
	readonly listeners = new Set<Listener>();
	private sections: Section[] = [];
	private pinned: string | null = null;
	private settling = false;
	private settleTimer = 0;
	private frame = 0;
	private dirty = true;
	private lastKey = "";
	private readonly abort = new AbortController();
	private readonly resizeObserver = new ResizeObserver(() => this.invalidate());

	constructor(
		readonly pane: HTMLElement,
		readonly content: HTMLElement,
		private readonly ids: readonly string[],
	) {
		const { signal } = this.abort;
		pane.addEventListener("scroll", this.onScroll, { passive: true, signal });
		for (const type of ["wheel", "touchstart", "keydown"] as const) {
			window.addEventListener(type, this.release, { passive: true, signal });
		}
		window.addEventListener("popstate", this.onPopState, { signal });
		this.resizeObserver.observe(content);
		this.resizeObserver.observe(pane);
	}

	destroy(): void {
		this.abort.abort();
		this.resizeObserver.disconnect();
		cancelAnimationFrame(this.frame);
		clearTimeout(this.settleTimer);
	}

	pin(id: string): void {
		this.pinned = id;
		this.settling = true;
		this.restartSettle();
		this.schedule();
	}

	invalidate = (): void => {
		this.dirty = true;
		this.lastKey = "";
		this.schedule();
	};

	private readonly release = (): void => {
		if (!this.pinned) return;
		this.pinned = null;
		this.schedule();
	};

	private readonly onScroll = (): void => {
		if (this.settling) this.restartSettle();
		this.schedule();
	};

	private readonly onPopState = (event: PopStateEvent): void => {
		if (event.state !== null) return;
		const id = decodeURIComponent(location.hash.slice(1)) || PAGE_TOP_ID;
		if (!this.ids.includes(id)) return;
		this.pin(id);
		scrollToSection(id, "auto");
	};

	private restartSettle(): void {
		clearTimeout(this.settleTimer);
		this.settleTimer = window.setTimeout(() => {
			this.settling = false;
			this.schedule();
		}, SETTLE_MS);
	}

	private schedule(): void {
		if (this.frame) return;
		this.frame = requestAnimationFrame(() => {
			this.frame = 0;
			this.update();
		});
	}

	private update(): void {
		if (this.dirty) this.measure();
		this.dirty = false;
		const state = this.compute();
		const key = `${state.current}|${state.visible.join()}|${state.progress.toFixed(3)}`;
		if (key === this.lastKey) return;
		this.lastKey = key;
		for (const listener of this.listeners) listener(state);
	}

	private measure(): void {
		const origin = this.pane.getBoundingClientRect().top - this.pane.scrollTop;
		const offset = (element: Element): number =>
			laidOut(element).getBoundingClientRect().top - origin;
		const starts = this.ids.flatMap((id) => {
			const element = document.getElementById(id);
			if (!element) return [];
			return [{ id, start: id === PAGE_TOP_ID ? 0 : offset(element) }];
		});
		const end = this.content.getBoundingClientRect().bottom - origin;
		this.sections = starts.map((section, index) => ({
			...section,
			end: starts[index + 1]?.start ?? end,
		}));
	}

	private compute(): SpyState {
		const { scrollTop, clientHeight } = this.pane;
		const viewBottom = scrollTop + clientHeight;
		const visible = this.sections
			.filter(
				({ start, end }) =>
					end > start && start < viewBottom && end > scrollTop,
			)
			.map(({ id }) => id);
		const span = (this.sections.at(-1)?.end ?? 0) - clientHeight;
		return {
			current: this.currentSection(visible),
			visible,
			progress: span > 0 ? clamp01(scrollTop / span) : 1,
		};
	}

	private currentSection(visible: readonly string[]): string {
		if (this.pinned && (this.settling || visible.includes(this.pinned))) {
			return this.pinned;
		}
		this.pinned = null;
		const line = this.readingLine();
		const section =
			this.sections.findLast(({ start }) => start <= line) ?? this.sections[0];
		return section?.id ?? "";
	}

	// Short final sections can never scroll up to the reading line. When the
	// page has any, the line slides down to the bottom edge over the last
	// screen of scrolling, so every heading still gets its turn.
	private readingLine(): number {
		const { scrollTop, clientHeight, scrollHeight } = this.pane;
		const offset = Math.min(
			clientHeight * READING_LINE_RATIO,
			READING_LINE_MAX,
		);
		const line = scrollTop + offset;
		const maxScroll = scrollHeight - clientHeight;
		const lastStart = this.sections.at(-1)?.start ?? 0;
		if (lastStart <= maxScroll + offset) return line;
		const ramp = clientHeight - offset;
		return line + ramp * clamp01(1 - (maxScroll - scrollTop) / ramp);
	}
}

let shared: ScrollSpy | null = null;

export function watchSections(
	ids: readonly string[],
	listener: Listener,
): () => void {
	const pane = getScrollPane();
	const content =
		document.querySelector<HTMLElement>(".sl-markdown-content") ??
		document.querySelector<HTMLElement>("main");
	if (!pane || !content) return () => {};

	if (shared?.content !== content) {
		shared?.destroy();
		shared = new ScrollSpy(pane, content, ids);
	}
	const spy = shared;
	spy.listeners.add(listener);
	spy.invalidate();

	return () => {
		spy.listeners.delete(listener);
		if (spy.listeners.size > 0) return;
		spy.destroy();
		if (shared === spy) shared = null;
	};
}

export function pinSection(id: string): void {
	shared?.pin(id);
}
