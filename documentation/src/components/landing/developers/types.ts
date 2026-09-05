import type { Cta } from "../shared/types";

export interface ExtensionInfo {
	name: string;
	/** Number of `@Entry` classes in the extension's source; omit for thin integrations. */
	entries?: number;
}

export interface DevelopersProps {
	extensions: ExtensionInfo[];
	docsCta: Cta;
}
