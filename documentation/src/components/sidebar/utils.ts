import type { LinkEntry, GroupEntry, SidebarEntry } from "./types";

/**
 * Returns the Tailwind padding class based on sidebar nesting level.
 * Level 1 = pl-3, Level 2 = pl-6, Level 3 = pl-9, Level 4+ = pl-12
 */
export function getPaddingClass(level: number): string {
  const paddingClasses = ["pl-3", "pl-6", "pl-9", "pl-12"];
  return paddingClasses[Math.min(level - 1, 3)];
}

/**
 * Format label: capitalize first word only, unless text has explicit capitals.
 * Preserves intentional capitalization (e.g., "API", "OAuth").
 */
export function formatLabel(text: string): string {
  // Check if text has intentional capitalization (multiple capital letters beyond first)
  const hasExplicitCaps = text
    .slice(1)
    .split("")
    .some((char) => char === char.toUpperCase() && char !== char.toLowerCase());
  if (hasExplicitCaps) {
    return text; // Keep original formatting
  }
  // Sentence case: first letter capital, rest lowercase
  return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
}

/**
 * Find index page for a group's entries.
 * An index entry is:
 * 1. A link ending with "/" that has sibling entries starting with its href, OR
 * 2. A single link in a group (the only entry represents the folder's index)
 */
export function findIndexEntry(
  entries: Array<SidebarEntry>,
): LinkEntry | undefined {
  const links = entries.filter((e): e is LinkEntry => e.type === "link");

  // Case 1: Single link entry in a group - it's the index for this folder
  if (entries.length === 1 && links.length === 1) {
    return links[0];
  }

  // Case 2: Multiple entries - find the one that acts as the index (parent path)
  return links.find(
    (entry) =>
      entry.href.endsWith("/") &&
      entry.href !== "/" &&
      entries.some(
        (other) =>
          other.type === "link" &&
          other !== entry &&
          other.href.startsWith(entry.href),
      ),
  );
}

/**
 * Process group entries: find index, filter it out, return metadata.
 * Used by SidebarList to determine how to render groups.
 */
export function processGroupEntries(entries: Array<SidebarEntry>) {
  const indexEntry = findIndexEntry(entries);
  const filteredEntries = indexEntry
    ? entries.filter((entry) => entry !== indexEntry)
    : entries;
  return {
    filteredEntries,
    groupHref: indexEntry?.href,
    isCurrent: indexEntry?.isCurrent,
    // If no entries remain after filtering, this group should be rendered as a link
    renderAsLink: filteredEntries.length === 0 && indexEntry !== undefined,
    indexEntry,
  };
}
