import type { PhrasingContent, Root } from "mdast";
import type {} from "mdast-util-directive";
import type {} from "mdast-util-to-hast";
import type { Plugin } from "unified";
import { SKIP, visit } from "unist-util-visit";
import { element, text, textOf } from "../shared/mdast";
import { type KeyCap, keyCap, parseChords } from "./keys";
import { kbdStyles } from "./styles";

/** Turns `:kbd[Ctrl+S]` into nested `<kbd>` keycaps. */
export const remarkKbd: Plugin<[], Root> = () => {
	return (tree) => {
		visit(tree, "textDirective", (node) => {
			if (node.name !== "kbd") return;

			const chords = parseChords(textOf(node.children));
			if (chords.length === 0) return;

			node.data = { hName: "kbd", hProperties: { class: kbdStyles.group } };
			node.children = chords.flatMap(chordNodes);
			return SKIP;
		});
	};
};

function chordNodes(keys: string[], index: number): PhrasingContent[] {
	const nodes: PhrasingContent[] = [];
	if (index > 0) {
		nodes.push(element("span", { class: kbdStyles.chord }, [text("then")]));
	}
	for (const [keyIndex, key] of keys.entries()) {
		if (keyIndex > 0) {
			nodes.push(element("span", { class: kbdStyles.plus }, [text("+")]));
		}
		nodes.push(cap(keyCap(key)));
	}
	return nodes;
}

/**
 * A cap whose glyph does not read as a key name hides it from assistive
 * technology and carries the spoken name in visually hidden text, so `↑` is
 * announced as "Up arrow" instead of being skipped or spelled out.
 */
function cap(key: KeyCap): PhrasingContent {
	const properties = { class: kbdStyles.cap };
	if (!key.spoken) return element("kbd", properties, [text(key.glyph)]);
	return element("kbd", properties, [
		element("span", { ariaHidden: "true" }, [text(key.glyph)]),
		element("span", { class: kbdStyles.srOnly }, [text(key.spoken)]),
	]);
}
