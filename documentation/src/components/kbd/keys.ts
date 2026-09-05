/** `glyph` is printed on the cap; `spoken` replaces it for assistive technology. */
export interface KeyCap {
	glyph: string;
	spoken?: string;
}

const KEY_CAPS: Record<string, KeyCap> = {
	ctrl: { glyph: "Ctrl", spoken: "Control" },
	control: { glyph: "Ctrl", spoken: "Control" },
	cmd: { glyph: "⌘ Cmd", spoken: "Command" },
	command: { glyph: "⌘ Cmd", spoken: "Command" },
	meta: { glyph: "⌘ Cmd", spoken: "Command" },
	win: { glyph: "⊞ Win", spoken: "Windows" },
	super: { glyph: "⊞ Win", spoken: "Windows" },
	alt: { glyph: "Alt" },
	opt: { glyph: "⌥ Option", spoken: "Option" },
	option: { glyph: "⌥ Option", spoken: "Option" },
	shift: { glyph: "⇧ Shift", spoken: "Shift" },
	enter: { glyph: "Enter ↵", spoken: "Enter" },
	return: { glyph: "Enter ↵", spoken: "Enter" },
	esc: { glyph: "Esc", spoken: "Escape" },
	escape: { glyph: "Esc", spoken: "Escape" },
	tab: { glyph: "Tab" },
	space: { glyph: "Space" },
	spacebar: { glyph: "Space" },
	backspace: { glyph: "Backspace" },
	del: { glyph: "Delete" },
	delete: { glyph: "Delete" },
	up: { glyph: "↑", spoken: "Up arrow" },
	down: { glyph: "↓", spoken: "Down arrow" },
	left: { glyph: "←", spoken: "Left arrow" },
	right: { glyph: "→", spoken: "Right arrow" },
	arrowup: { glyph: "↑", spoken: "Up arrow" },
	arrowdown: { glyph: "↓", spoken: "Down arrow" },
	arrowleft: { glyph: "←", spoken: "Left arrow" },
	arrowright: { glyph: "→", spoken: "Right arrow" },
	pageup: { glyph: "Page Up" },
	pagedown: { glyph: "Page Down" },
	home: { glyph: "Home" },
	end: { glyph: "End" },
};

/**
 * Splits a `:kbd[]` label into sequential chords of simultaneous keys:
 * `Ctrl+K, Ctrl+S` -> `[["Ctrl", "K"], ["Ctrl", "S"]]`.
 */
export function parseChords(label: string): string[][] {
	return splitKeys(label, ",")
		.map((chord) => splitKeys(chord, "+"))
		.filter((chord) => chord.length > 0);
}

export function keyCap(key: string): KeyCap {
	const mapped = KEY_CAPS[key.toLowerCase()];
	if (mapped) return mapped;
	if (key.length === 1) return { glyph: key.toUpperCase() };
	return { glyph: key.charAt(0).toUpperCase() + key.slice(1) };
}

/**
 * `separator` only separates when there is something on both sides of it, so a
 * literal key survives: `Ctrl++` -> `["Ctrl", "+"]`, `+` -> `["+"]`, and the
 * trailing comma of `Ctrl+,` stays attached to its chord.
 */
function splitKeys(input: string, separator: string): string[] {
	const parts: string[] = [];
	let buffer = "";

	for (let index = 0; index < input.length; index += 1) {
		const char = input.charAt(index);
		if (char !== separator) {
			buffer += char;
			continue;
		}
		if (buffer.trim() === "") {
			parts.push(separator);
			buffer = "";
			continue;
		}
		if (input.slice(index + 1).trim() === "") {
			buffer += char;
			continue;
		}
		parts.push(buffer);
		buffer = "";
	}

	if (buffer.trim() !== "") parts.push(buffer);
	return parts.map((part) => part.trim()).filter((part) => part !== "");
}
