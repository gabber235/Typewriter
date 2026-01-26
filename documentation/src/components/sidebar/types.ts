/**
 * Shared TypeScript interfaces for sidebar components.
 * These types mirror Starlight's sidebar entry structure.
 */

export interface LinkEntry {
  type: "link";
  label: string;
  href: string;
  attrs?: Record<string, any>;
  isCurrent?: boolean;
  badge?: { variant?: string; class?: string; text: string };
}

export interface GroupEntry {
  type: "group";
  label: string;
  entries: Array<LinkEntry | GroupEntry>;
  collapsed?: boolean;
  badge?: { variant?: string; class?: string; text: string };
}

export type SidebarEntry = LinkEntry | GroupEntry;
