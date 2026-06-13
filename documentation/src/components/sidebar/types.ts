/**
 * Shared TypeScript interfaces for sidebar components.
 * These types mirror Starlight's sidebar entry structure.
 */

import type { Badge } from "../badge";

export interface LinkEntry {
	type: "link";
	label: string;
	href: string;
	attrs?: Record<string, string | number | boolean | undefined>;
	isCurrent?: boolean;
	badge?: Badge;
}

export interface GroupEntry {
	type: "group";
	label: string;
	entries: Array<LinkEntry | GroupEntry>;
	collapsed?: boolean;
	badge?: Badge;
}

export type SidebarEntry = LinkEntry | GroupEntry;
