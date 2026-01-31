import type { MarkdownHeading } from 'astro';

export interface TocItem extends MarkdownHeading {
	children: TocItem[];
}

/**
 * Configuration for scroll-based progress tracking
 */
export interface ScrollProgressConfig {
	/** Enable scroll-based progress indicator */
	enabled: boolean;
	/** Throttle duration in ms for scroll events */
	throttleMs: number;
}

/**
 * Progress metrics for the ToC
 */
export interface ProgressMetrics {
	/** Overall scroll progress (0-1) */
	scrollProgress: number;
	/** Current heading index in flat list */
	headingIndex: number;
	/** Total number of headings */
	totalHeadings: number;
	/** Heading-based progress (0-1) */
	headingProgress: number;
}

/**
 * Collapse/expand state for ToC sections
 */
export interface CollapseState {
	[headingSlug: string]: boolean;
}

/**
 * Configuration for ToC behavior
 */
export interface TocConfig {
	/** Minimum heading level to include */
	minHeadingLevel: number;
	/** Maximum heading level to include */
	maxHeadingLevel: number;
	/** Enable smooth scroll */
	smoothScroll: boolean;
	/** Enable collapse/expand for nested sections */
	collapsible: boolean;
	/** Enable parent highlighting when child is active */
	highlightParents: boolean;
	/** Persist collapse state */
	persistCollapseState: boolean;
	/** Storage key for collapse state */
	storageKey: string;
}

/**
 * Heading element with metadata
 */
export interface HeadingElement {
	/** The heading DOM element */
	element: HTMLHeadingElement;
	/** Heading ID/slug */
	id: string;
	/** Heading level (1-6) */
	level: number;
	/** Corresponding ToC link element */
	link: HTMLAnchorElement | null;
}
