import { getCollection } from "astro:content";
import { getBadge } from "./styles";
import type { Badge, BadgeVariant } from "./types";

interface LinkEntry {
	type: "link";
	label: string;
	href: string;
	attrs?: Record<string, string | number | boolean | undefined>;
	isCurrent?: boolean;
	badge?: Badge;
}

interface GroupEntry {
	type: "group";
	label: string;
	entries: Array<LinkEntry | GroupEntry>;
	collapsed?: boolean;
	badge?: Badge;
}

type SidebarEntry = LinkEntry | GroupEntry;

/**
 * Process sidebar entries to add badges from frontmatter.
 * Call this in Sidebar.astro to merge badge data into the sidebar.
 */
export async function processSidebarBadges(
	sidebar: SidebarEntry[],
): Promise<SidebarEntry[]> {
	// Get all docs entries to access badge frontmatter
	const docsEntries = await getCollection("docs");

	// Create a map of href to badge variant
	const badgeMap = new Map<string, BadgeVariant>();
	for (const entry of docsEntries) {
		const badge = entry.data.badge as BadgeVariant | undefined;
		if (badge) {
			// Convert slug to href format (e.g., "guides/03-test/index" -> "/guides/03-test/")
			const href = `/${entry.id.replace(/\/index$/, "").replace(/\.mdx?$/, "")}/`;
			badgeMap.set(href, badge);
		}
	}

	// Recursively merge badges into sidebar entries
	function mergeBadges(entries: SidebarEntry[]): SidebarEntry[] {
		return entries.map((entry) => {
			if (entry.type === "link") {
				const variant = badgeMap.get(entry.href);
				const badge = getBadge(variant);
				if (badge && !entry.badge) {
					return { ...entry, badge };
				}
				return entry;
			} else {
				// Group entry - check for index page badge and recurse
				const indexHref = entry.entries.find(
					(e): e is LinkEntry =>
						e.type === "link" &&
						(e.href.endsWith("/") || e.href.endsWith("/index")),
				)?.href;

				const variant = indexHref ? badgeMap.get(indexHref) : undefined;
				const badge = getBadge(variant);
				const mergedEntries = mergeBadges(entry.entries);

				if (badge && !entry.badge) {
					return { ...entry, entries: mergedEntries, badge };
				}
				return { ...entry, entries: mergedEntries };
			}
		});
	}

	return mergeBadges(sidebar);
}
