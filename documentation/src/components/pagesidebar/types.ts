import type { MarkdownHeading } from "astro";

export interface TocItem extends MarkdownHeading {
	children: TocItem[];
}

// "rail" is the desktop column, "sheet" the mobile dialog.
export type TocVariant = "rail" | "sheet";

export interface SpyState {
	// The one section the reader is in; gets aria-current.
	current: string;
	// Every section with any part on screen, in document order.
	visible: readonly string[];
	// 0 at the top, 1 once the end of the article is on screen.
	progress: number;
}
