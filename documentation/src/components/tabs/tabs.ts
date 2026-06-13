import { tabStyles as s } from "./styles";
import type { TabContext, TabState } from "./types";

const syncGroups = new Map<string, Set<HTMLElement>>();
const tabActivators = new WeakMap<HTMLElement, (idx: number) => void>();

export function initTabs(container: HTMLElement): void {
	const tablist = container.querySelector<HTMLElement>("[role='tablist']");
	const panelsWrap = container.querySelector<HTMLElement>("[data-tab-panels]");
	const pill = container.querySelector<HTMLElement>("[data-tab-pill]");
	if (!tablist || !panelsWrap || !pill) return;

	const panels = Array.from(
		panelsWrap.querySelectorAll<HTMLElement>(":scope > [data-tab-panel]"),
	);
	if (panels.length === 0) return;

	const tabsId = container.dataset.tabsId;
	if (!tabsId) return;

	const syncKey = container.dataset.syncKey ?? null;
	const defaultTab = clamp(
		Number(container.dataset.defaultTab) || 0,
		0,
		panels.length - 1,
	);
	const labels = panels.map((p) => p.dataset.tabLabel ?? "");
	const buttons: HTMLButtonElement[] = [];

	for (let i = 0; i < labels.length; i++) {
		const btn = document.createElement("button");
		btn.type = "button";
		btn.role = "tab";
		btn.className = `${s.button} ${s.buttonInactive}`;
		btn.textContent = labels[i];
		btn.id = `tab-${tabsId}-${i}`;
		btn.setAttribute("aria-controls", `panel-${tabsId}-${i}`);
		btn.setAttribute("aria-selected", "false");
		btn.tabIndex = -1;
		tablist.appendChild(btn);
		buttons.push(btn);

		panels[i].id = `panel-${tabsId}-${i}`;
		panels[i].setAttribute("aria-labelledby", btn.id);
	}

	const ctx: TabContext = {
		container,
		tablist,
		pill,
		buttons,
		panels,
		labels,
		syncKey,
	};
	const state: TabState = { activeIndex: -1 };

	const keyMap: Record<string, (i: number, len: number) => number> = {
		ArrowRight: (i, len) => (i + 1) % len,
		ArrowLeft: (i, len) => (i - 1 + len) % len,
		Home: () => 0,
		End: (_i, len) => len - 1,
	};

	for (let i = 0; i < buttons.length; i++) {
		const index = i;
		buttons[i].addEventListener("click", () => {
			applyTab(ctx, state, index, true);
			syncSiblings(ctx, index);
			updateParam(syncKey, labels[index]);
		});
	}

	tablist.addEventListener("keydown", (e: KeyboardEvent) => {
		const move = keyMap[e.key];
		if (!move) return;
		e.preventDefault();
		const next = move(state.activeIndex, buttons.length);
		applyTab(ctx, state, next, true);
		syncSiblings(ctx, next);
		updateParam(syncKey, labels[next]);
	});

	if (syncKey) {
		if (!syncGroups.has(syncKey)) syncGroups.set(syncKey, new Set());
		syncGroups.get(syncKey)?.add(container);
	}

	tabActivators.set(container, (idx: number) =>
		applyTab(ctx, state, idx, false),
	);

	const initial = resolveInitialTab(labels, defaultTab, syncKey);
	applyTab(ctx, state, initial, false);

	const resizeObserver = new ResizeObserver(() =>
		movePill(pill, tablist, buttons[state.activeIndex], true),
	);
	resizeObserver.observe(tablist);
}

function applyTab(
	ctx: TabContext,
	state: TabState,
	index: number,
	focus: boolean,
): void {
	if (index === state.activeIndex) return;
	const prev = state.activeIndex;
	state.activeIndex = index;

	for (let i = 0; i < ctx.buttons.length; i++) {
		const isActive = i === index;
		ctx.buttons[i].setAttribute("aria-selected", String(isActive));
		ctx.buttons[i].tabIndex = isActive ? 0 : -1;
		ctx.buttons[i].className =
			`${s.button} ${isActive ? s.buttonActive : s.buttonInactive}`;

		ctx.panels[i].hidden = !isActive;
		ctx.panels[i].className =
			`${s.panel} ${isActive ? s.panelActive : s.panelHidden}`;
	}

	movePill(ctx.pill, ctx.tablist, ctx.buttons[index], prev === -1);
	if (focus) ctx.buttons[index].focus();
}

function movePill(
	pill: HTMLElement,
	tablist: HTMLElement,
	btn: HTMLButtonElement | undefined,
	instant: boolean,
): void {
	if (!btn) return;

	const barRect = tablist.getBoundingClientRect();
	const btnRect = btn.getBoundingClientRect();
	const offset = btnRect.left - barRect.left;

	if (instant) pill.style.transition = "none";
	pill.style.width = `${btnRect.width}px`;
	pill.style.transform = `translateX(${offset}px)`;

	if (!instant) return;
	pill.offsetHeight;
	pill.style.transition = "";
}

function syncSiblings(ctx: TabContext, index: number): void {
	if (!ctx.syncKey) return;
	const group = syncGroups.get(ctx.syncKey);
	if (!group) return;
	const label = ctx.labels[index];

	for (const other of group) {
		if (other === ctx.container) continue;
		const otherPanels = other.querySelectorAll<HTMLElement>("[data-tab-panel]");
		const targetIndex = findPanelIndexByLabel(otherPanels, label);
		if (targetIndex === -1) continue;
		tabActivators.get(other)?.(targetIndex);
	}
}

function findPanelIndexByLabel(
	panels: NodeListOf<HTMLElement>,
	label: string,
): number {
	for (let i = 0; i < panels.length; i++) {
		if (panels[i].dataset.tabLabel === label) return i;
	}
	return -1;
}

function resolveInitialTab(
	labels: string[],
	defaultTab: number,
	syncKey: string | null,
): number {
	if (!syncKey) return defaultTab;

	const param = new URL(window.location.href).searchParams.get(syncKey);
	if (param) {
		const idx = labels.findIndex((l) => slugify(l) === param);
		if (idx !== -1) return idx;
	}

	const group = syncGroups.get(syncKey);
	if (!group) return defaultTab;

	for (const other of group) {
		if (!tabActivators.has(other)) continue;
		const otherPanels = other.querySelectorAll<HTMLElement>("[data-tab-panel]");
		for (let i = 0; i < otherPanels.length; i++) {
			if (otherPanels[i].hidden) continue;
			const matchLabel = otherPanels[i].dataset.tabLabel ?? "";
			const idx = labels.indexOf(matchLabel);
			if (idx !== -1) return idx;
		}
	}

	return defaultTab;
}

function updateParam(syncKey: string | null, label: string): void {
	if (!syncKey) return;
	const url = new URL(window.location.href);
	url.searchParams.set(syncKey, slugify(label));
	history.replaceState(null, "", url);
}

function slugify(text: string): string {
	return text
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/(^-|-$)/g, "");
}

function clamp(value: number, min: number, max: number): number {
	return Math.max(min, Math.min(max, value));
}
