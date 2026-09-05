import { updateTrailFade } from "./render";
import { wizardStyles as s } from "./styles";
import { panelKey } from "./tree";
import type { WizardContext } from "./types";

const MEASURE_DEBOUNCE_MS = 120;
const FADE_MS = 180;

/**
 * Crossfade to the panel for `path`. Only the panel being replaced stays
 * visible while it fades; every other panel is `visibility: hidden` so its
 * text cannot be selected or found in the page.
 */
export function showPanel(
	wizard: WizardContext,
	path: number[],
): HTMLElement | null {
	const key = panelKey(path);
	const previous = wizard.activeKey;
	wizard.activeKey = key;

	for (const [candidate, panel] of wizard.panels) {
		const on = candidate === key;
		panel.className = `${s.panel} ${panelState(on, candidate === previous)}`;
		panel.toggleAttribute("inert", !on);
	}
	const active = wizard.panels.get(key) ?? null;
	// Flush styles so the class swap above starts a transition.
	active?.getBoundingClientRect();

	window.clearTimeout(wizard.hideTimer);
	wizard.hideTimer = window.setTimeout(
		() => hideLeftPanel(wizard, previous),
		FADE_MS,
	);
	return active;
}

/**
 * Lock the stage to the tallest panel. Panels are absolutely positioned, so
 * their own height never depends on this value and the observer cannot loop.
 */
export function measureStage(wizard: WizardContext): void {
	let tallest = 0;
	for (const panel of wizard.panels.values()) {
		tallest = Math.max(tallest, panel.getBoundingClientRect().height);
	}
	if (tallest === 0) return;
	wizard.elements.stage.style.minHeight = `${Math.ceil(tallest)}px`;
}

export function observePanels(wizard: WizardContext): void {
	let timer = 0;
	const remeasure = () => {
		measureStage(wizard);
		updateTrailFade(wizard);
	};
	const observer = new ResizeObserver(() => {
		window.clearTimeout(timer);
		timer = window.setTimeout(remeasure, MEASURE_DEBOUNCE_MS);
	});
	for (const panel of wizard.panels.values()) observer.observe(panel);
	observer.observe(wizard.elements.trailNav);
}

function panelState(on: boolean, leaving: boolean): string {
	if (on) return s.panelActive;
	return leaving ? s.panelLeaving : s.panelHidden;
}

function hideLeftPanel(wizard: WizardContext, previous: string | null): void {
	if (previous === null || previous === wizard.activeKey) return;
	const leaving = wizard.panels.get(previous);
	if (!leaving) return;
	leaving.className = `${s.panel} ${s.panelHidden}`;
}
