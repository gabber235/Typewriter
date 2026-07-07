// The two top-level documentation categories. Each maps a directory under
// src/content/docs/ to a URL prefix and its own scoped sidebar (see
// src/route-middleware.ts). Importable from config, middleware, and
// components, mirroring src/base-path.ts.
export interface Category {
	id: string;
	label: string;
}

export const CATEGORIES: Category[] = [
	{ id: "docs", label: "Documentation" },
	{ id: "develop", label: "Develop" },
];

export function categoryForRoute(routeId: string): Category {
	const head = routeId.split("/")[0];
	return CATEGORIES.find((category) => category.id === head) ?? CATEGORIES[0];
}
