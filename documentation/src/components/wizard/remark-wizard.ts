import type { Root } from "mdast";
import type { ContainerDirective } from "mdast-util-directive";
import type { Plugin } from "unified";
import type { Node } from "unist";
import { visit } from "unist-util-visit";
import { isContainerDirective } from "../shared/mdast";
import { wizardStyles as s } from "./styles";

function isWizardDirective(node: Node): node is ContainerDirective {
	return isContainerDirective(node) && node.name === "wizard";
}

function containerProperties(node: ContainerDirective): Record<string, string> {
	const properties: Record<string, string> = {
		class: s.container,
		"data-wizard": "",
	};
	if ("persist" in (node.attributes ?? {})) {
		properties["data-wizard-persist"] = "";
	}
	return properties;
}

function markLabel(node: ContainerDirective): void {
	const label = node.children[0];
	if (label?.type !== "paragraph" || !label.data?.directiveLabel) return;
	label.data = {
		...label.data,
		hName: "p",
		hProperties: { class: s.sourceQuestion, "data-wizard-question": "" },
	};
}

/**
 * Wraps `:::wizard[Root question]{persist}` in `div[data-wizard]` and leaves
 * the label and list as real markdown, so links are resolved by Starlight and
 * the page reads fine without JS; the client builds the stepper from the DOM.
 */
export const remarkWizard: Plugin<[], Root> = () => {
	return (tree) => {
		visit(tree, (node) => {
			if (!isWizardDirective(node)) return;
			node.data = {
				...node.data,
				hName: "div",
				hProperties: containerProperties(node),
			};
			markLabel(node);
		});
	};
};

export default remarkWizard;
