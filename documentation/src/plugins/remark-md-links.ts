import { dirname, relative, resolve, sep } from "node:path";
import type { Root } from "mdast";
import type { Plugin } from "unified";
import { visit } from "unist-util-visit";
import { BASE_PATH } from "../lib/base-path";

const CONTENT_ROOT = resolve(process.cwd(), "src/content/docs");
const MARKDOWN_LINK = /^(?!\w+:)(?!\/)(?!#)(.+?\.mdx?)(#.*)?$/i;

/**
 * Rewrites relative `[text](../guide/page.md)` links to the page URL they
 * describe; Astro otherwise leaves those hrefs pointing at the raw `.md` copy.
 */
export const remarkMdLinks: Plugin<[], Root> = () => {
	return (tree, file) => {
		if (!file.path) return;
		const fromDir = dirname(file.path);

		visit(tree, ["link", "definition"], (node) => {
			if (node.type !== "link" && node.type !== "definition") return;
			const match = MARKDOWN_LINK.exec(node.url);
			if (!match) return;

			const target = resolve(fromDir, match[1]);
			const insideContent = relative(CONTENT_ROOT, target);
			if (insideContent.startsWith("..")) return;

			node.url = `${BASE_PATH}${toRoute(insideContent)}${match[2] ?? ""}`;
		});
	};
};

function toRoute(contentPath: string): string {
	const segments = contentPath
		.replace(/\.mdx?$/i, "")
		.split(sep)
		.map(slugify);
	if (segments[segments.length - 1] === "index") segments.pop();
	return segments.length === 0 ? "" : `${segments.join("/")}/`;
}

function slugify(segment: string): string {
	return segment
		.toLowerCase()
		.replace(/\s+/g, "-")
		.replace(/[^\p{L}\p{N}_-]/gu, "");
}
