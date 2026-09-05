// Browsers that know `name` on <details> close the group's siblings
// themselves; this only steps in where that attribute is not implemented.
const supportsNativeGroups = "name" in document.createElement("details");

function closeSiblings(opened: HTMLDetailsElement): void {
	const name = opened.getAttribute("name");
	if (!name) return;
	for (const other of document.querySelectorAll<HTMLDetailsElement>(
		`details[name="${name}"][open]`,
	)) {
		if (other !== opened) other.open = false;
	}
}

function onToggle(event: Event): void {
	const target = event.target;
	if (!(target instanceof HTMLDetailsElement) || !target.open) return;
	closeSiblings(target);
}

export function setupExclusiveDetails(): void {
	if (supportsNativeGroups) return;
	// `toggle` does not bubble; the capture phase still reaches the document.
	document.addEventListener("toggle", onToggle, true);
}
