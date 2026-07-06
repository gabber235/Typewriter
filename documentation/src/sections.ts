// The two top-level documentation sections. Each maps a directory under
// src/content/docs/ to a URL prefix and its own scoped sidebar (see
// src/route-middleware.ts). Importable from config, middleware, and
// components, mirroring src/base-path.ts.
export interface Section {
	id: string;
	label: string;
}

export const SECTIONS: Section[] = [
	{ id: "docs", label: "Documentation" },
	{ id: "develop", label: "Develop" },
];

export function sectionForRoute(routeId: string): Section {
	const head = routeId.split("/")[0];
	return SECTIONS.find((section) => section.id === head) ?? SECTIONS[0];
}
