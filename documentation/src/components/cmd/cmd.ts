import { cmdStyles } from "./styles";

const RESET_DELAY = 1500;
const GAP = 6;
const MARGIN = 8;
const ARROW = 3;

let bound = false;
let liveRegion: HTMLElement | null = null;
let tooltip: HTMLElement | null = null;
let arrow: HTMLElement | null = null;
// One chip at a time owns the copied state, so a second click can never leave a
// stale green chip or stack a second reset timer.
let activeChip: HTMLButtonElement | null = null;
let resetTimer = 0;
let repositionQueued = false;

/** Binds the delegated `:cmd[]` copy handlers, once per page load. */
export function setupCmdCopy(): void {
	if (bound) return;
	bound = true;
	// Delegated on `document` so the binding survives view-transition DOM swaps.
	document.addEventListener("click", onClick);
	// Capture, so the tooltip follows its chip inside nested scrollers too.
	document.addEventListener("scroll", onReposition, {
		passive: true,
		capture: true,
	});
	window.addEventListener("resize", onReposition, { passive: true });
	document.addEventListener("astro:before-swap", reset);
}

function onClick(event: MouseEvent): void {
	if (!(event.target instanceof Element)) return;
	const chip = event.target.closest<HTMLButtonElement>("button[data-cmd]");
	if (!chip) return;
	event.preventDefault();
	void copy(chip);
}

async function copy(chip: HTMLButtonElement): Promise<void> {
	const command = chip.dataset.cmd;
	if (!command) return;
	if (!(await writeToClipboard(command))) return;

	if (activeChip && activeChip !== chip) delete activeChip.dataset.copied;
	activeChip = chip;
	chip.dataset.copied = "true";
	// The accessible name stays "Copy command …": renaming a control mid-press
	// is announced unreliably and breaks voice control.
	announce(`Copied ${command}`);

	// Position first: measuring the tooltip flushes style and layout, which is
	// what gives a freshly created node a "before" state to transition from.
	const pill = ensureTooltip();
	position(chip, pill);
	pill.dataset.show = "true";

	window.clearTimeout(resetTimer);
	resetTimer = window.setTimeout(reset, RESET_DELAY);
}

function reset(): void {
	window.clearTimeout(resetTimer);
	if (activeChip) delete activeChip.dataset.copied;
	activeChip = null;
	if (tooltip) delete tooltip.dataset.show;
}

function onReposition(): void {
	if (repositionQueued) return;
	repositionQueued = true;
	requestAnimationFrame(reposition);
}

function reposition(): void {
	repositionQueued = false;
	if (!tooltip?.dataset.show || !activeChip) return;
	if (!activeChip.isConnected) {
		reset();
		return;
	}
	position(activeChip, tooltip);
}

function position(chip: HTMLElement, pill: HTMLElement): void {
	const anchor = chip.getBoundingClientRect();
	const box = pill.getBoundingClientRect();
	const above = anchor.top - GAP - box.height;
	const isFlipped = above < ceiling(chip);
	const center = anchor.left + anchor.width / 2;
	const left = clamp(
		center - box.width / 2,
		MARGIN,
		window.innerWidth - box.width - MARGIN,
	);

	pill.style.top = `${isFlipped ? anchor.bottom + GAP : above}px`;
	pill.style.left = `${left}px`;
	if (isFlipped) pill.dataset.flip = "true";
	else delete pill.dataset.flip;
	if (!arrow) return;
	arrow.style.left = `${clamp(center - left - ARROW, 6, box.width - 12)}px`;
}

/**
 * The tooltip is `position: fixed`, so "is there room above?" is a question
 * about the chip's scrollport, not the viewport: the docs body scrolls inside a
 * pane that starts below a fixed header, which a pill against the viewport top
 * would cover.
 */
function ceiling(chip: HTMLElement): number {
	let node = chip.parentElement;
	while (node) {
		if (scrolls(node)) {
			return Math.max(MARGIN, node.getBoundingClientRect().top + MARGIN);
		}
		node = node.parentElement;
	}
	return MARGIN;
}

function scrolls(node: HTMLElement): boolean {
	const overflow = getComputedStyle(node).overflowY;
	if (overflow !== "auto" && overflow !== "scroll") return false;
	return node.scrollHeight > node.clientHeight;
}

function clamp(value: number, min: number, max: number): number {
	return Math.min(Math.max(value, min), Math.max(min, max));
}

async function writeToClipboard(value: string): Promise<boolean> {
	try {
		await navigator.clipboard.writeText(value);
		return true;
	} catch {
		// Insecure origin, denied permission or no Clipboard API: fall back.
		return writeWithExecCommand(value);
	}
}

// `Document.execCommand` is deprecated, but remains the only synchronous copy
// path for insecure origins, denied Clipboard permission, or browsers without
// the Clipboard API. Reaching it through this undeprecated call signature
// avoids the deprecation warning without silencing diagnostics wholesale.
interface LegacyCopySupport {
	execCommand(commandId: "copy"): boolean;
}

function legacyCopy(target: Document): boolean {
	return (target as unknown as LegacyCopySupport).execCommand("copy");
}

function writeWithExecCommand(value: string): boolean {
	const area = document.createElement("textarea");
	area.value = value;
	area.setAttribute("readonly", "");
	area.style.position = "fixed";
	area.style.top = "0";
	area.style.opacity = "0";
	document.body.appendChild(area);
	area.select();
	const copied = legacyCopy(document);
	area.remove();
	return copied;
}

function announce(message: string): void {
	const region = ensureLiveRegion();
	region.textContent = "";
	// Screen readers only announce a change; re-setting the same text in the
	// same tick would be a no-op.
	window.requestAnimationFrame(() => {
		region.textContent = message;
	});
}

function ensureLiveRegion(): HTMLElement {
	// The ClientRouter swaps <body>, so re-append if the region got detached.
	if (liveRegion?.isConnected) return liveRegion;
	liveRegion ??= createLiveRegion();
	document.body.appendChild(liveRegion);
	return liveRegion;
}

function createLiveRegion(): HTMLElement {
	const region = document.createElement("div");
	region.id = "cmd-copy-status";
	region.className = cmdStyles.liveRegion;
	region.setAttribute("role", "status");
	region.setAttribute("aria-live", "polite");
	return region;
}

function ensureTooltip(): HTMLElement {
	if (tooltip?.isConnected) return tooltip;
	tooltip ??= createTooltip();
	document.body.appendChild(tooltip);
	return tooltip;
}

function createTooltip(): HTMLElement {
	const pill = document.createElement("div");
	pill.className = cmdStyles.tip;
	// The live region already announces the copy; this is the visual half.
	pill.setAttribute("aria-hidden", "true");
	pill.textContent = "Copied";
	arrow = document.createElement("span");
	arrow.className = cmdStyles.tipArrow;
	pill.appendChild(arrow);
	return pill;
}
