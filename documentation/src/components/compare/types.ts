export type CompareOrientation = "horizontal" | "vertical";

export interface CompareOptions {
	/** Label for the clipped (top) image. */
	before: string;
	/** Label for the base (bottom) image. */
	after: string;
	/** Initial handle position, 0-100. */
	start: number;
	orientation: CompareOrientation;
	/** Follow the pointer on hover instead of requiring a drag. */
	hover: boolean;
}

export const COMPARE_DEFAULT_BEFORE = "Before";
export const COMPARE_DEFAULT_AFTER = "After";
export const COMPARE_DEFAULT_START = 50;
export const COMPARE_TRANSITION = "150ms";
export const COMPARE_STEP = 1;
export const COMPARE_LARGE_STEP = 10;
