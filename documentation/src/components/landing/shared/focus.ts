import type { Focus } from "./types";

/**
 * Inline style for a zoomed crop. The image is scaled around a transform
 * origin chosen so that the requested centre point ends up in the middle of
 * the frame: with origin `o` and zoom `z`, the visible range along one axis is
 * `[o - o/z, o + (100 - o)/z]`, whose midpoint is `o (1 - 1/z) + 50/z`.
 */
export function focusStyle(focus: Focus): string {
	const { x, y, zoom } = focus;
	const origin = (centre: number) =>
		clamp((centre - 50 / zoom) / (1 - 1 / zoom));
	return `--zoom:${zoom};transform-origin:${origin(x)}% ${origin(y)}%`;
}

function clamp(value: number): number {
	return Math.round(Math.min(100, Math.max(0, value)) * 10) / 10;
}
