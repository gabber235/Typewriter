import type { Root, RootContent } from "mdast";
import type { ContainerDirective } from "mdast-util-directive";
import type { Plugin } from "unified";
import type { Node } from "unist";
import { visit } from "unist-util-visit";
import {
	asideClasses,
	defaultTitles,
	icons,
	isAsideVariant,
	variantStyles,
} from "./aside-config";

function isContainerDirective(node: Node): node is ContainerDirective {
	return node.type === "containerDirective";
}

/**
 * Custom remark plugin that transforms directives like :::info, :::warning, :::danger, etc.
 * into custom styled aside elements with Tailwind classes.
 */
export const remarkAside: Plugin<[], Root> = () => {
	return (tree) => {
		visit(tree, (node, index, parent) => {
			if (!parent || index === undefined || !isContainerDirective(node)) return;

			const variant = node.name;
			if (!isAsideVariant(variant)) return;

			// Extract custom title from directive label if present
			let title = defaultTitles[variant];
			const firstChild = node.children[0];
			if (
				firstChild?.type === "paragraph" &&
				firstChild.data?.directiveLabel &&
				firstChild.children.length > 0
			) {
				// Extract text from label
				title = firstChild.children
					.map((c) => ("value" in c ? c.value : ""))
					.join("");
				node.children.splice(0, 1);
			}

			const styles = variantStyles[variant];

			// Create the aside structure using hast properties
			// Layout: container > header (icon + title) + content
			const aside = {
				type: "paragraph",
				data: {
					hName: "aside",
					hProperties: {
						class: `${asideClasses.container} ${styles.border} ${styles.bg}`,
					},
				},
				children: [
					{
						type: "paragraph",
						data: {
							hName: "div",
							hProperties: {
								class: asideClasses.header,
							},
						},
						children: [
							{
								type: "html",
								value: `<span class="${asideClasses.icon} ${styles.text}">${icons[variant]}</span>`,
							},
							{
								type: "paragraph",
								data: {
									hName: "p",
									hProperties: {
										class: `${asideClasses.title} ${styles.text}`,
									},
								},
								children: [
									{
										type: "text",
										value: title,
									},
								],
							},
						],
					},
					{
						type: "paragraph",
						data: {
							hName: "div",
							hProperties: {
								class: `${asideClasses.content} ${styles.text}`,
							},
						},
						children: node.children,
					},
				],
			};

			parent.children[index] = aside as unknown as RootContent;
		});
	};
};

export default remarkAside;
