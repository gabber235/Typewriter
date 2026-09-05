import type {
	Definition,
	Image,
	Link,
	Nodes,
	PhrasingContent,
	Root,
	RootContent,
} from "mdast";
import type {} from "mdast-util-directive";
import type {} from "mdast-util-to-hast";
import type { Plugin } from "unified";
import { SKIP, visit } from "unist-util-visit";
import { element, text, textOf } from "../shared/mdast";
import { getSiteVariables } from "./site-variables";
import { variableStyles } from "./styles";
import type { SiteVariables } from "./types";

const TOKEN = /:var\[([\w.-]+)\]/g;

type UrlNode = Link | Image | Definition;

/**
 * Resolves `:var[name]` against `src/content/variables.yml`.
 *
 * Runs before every other directive plugin so the substituted value is plain
 * text by the time `:cmd[]`, `:kbd[]` or the glossary see it. Link, image and
 * definition URLs are rewritten by string replacement, because remark-directive
 * never parses directives inside a link destination.
 */
export const remarkVariables: Plugin<[], Root> = () => {
	return (tree, file) => {
		const values = getSiteVariables();
		const origin = file.path ?? "<unknown file>";

		visit(tree, (node, index, parent) => {
			if (isUrlNode(node)) {
				expandUrls(node, values, origin);
				return;
			}
			if (node.type !== "textDirective" || node.name !== "var") return;
			if (!parent || index === undefined) return;

			const name = textOf(node.children).trim();
			(parent.children as RootContent[])[index] = resolve(name, values, origin);
			return SKIP;
		});
	};
};

function isUrlNode(node: Nodes): node is UrlNode {
	return (
		node.type === "link" || node.type === "image" || node.type === "definition"
	);
}

function expandUrls(
	node: UrlNode,
	values: SiteVariables,
	origin: string,
): void {
	node.url = expand(node.url, values, origin);
	if (node.title) node.title = expand(node.title, values, origin);
}

function resolve(
	name: string,
	values: SiteVariables,
	origin: string,
): PhrasingContent {
	const value = values[name];
	if (value !== undefined) return text(value);
	warn(name, origin);
	return missing(name);
}

/**
 * `⚠` is a glyph a screen reader either skips or spells out, so the sign is
 * hidden and the reason is spelled out in visually hidden text instead.
 */
function missing(name: string): PhrasingContent {
	return element("span", { class: variableStyles.missing }, [
		element("span", { ariaHidden: "true" }, [text("⚠ ")]),
		element("span", { class: variableStyles.srOnly }, [
			text("Unknown variable "),
		]),
		text(`var:${name}`),
	]);
}

function expand(input: string, values: SiteVariables, origin: string): string {
	if (!input.includes(":var[")) return input;
	return input.replace(TOKEN, (raw, name: string) => {
		const value = values[name];
		if (value !== undefined) return value;
		warn(name, origin);
		return raw;
	});
}

function warn(name: string, origin: string): void {
	console.warn(
		`[remark-variables] unknown variable ":var[${name}]" in ${origin}`,
	);
}
