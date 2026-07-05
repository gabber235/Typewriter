// Logo pixel-art extracted from the project's own brand asset
// (design/logo/typewriter-icon.png) so the intro renders it as SVG rects.

export const LOGO_COLS = 32;
export const LOGO_ROWS = 29;

export const LOGO_PALETTE: Record<string, string> = {
	a: "#ede9e8",
	b: "#dfd7d5",
	c: "#c4b4b0",
	d: "#d2c5c2",
	e: "#804231",
	f: "#582b1f",
	g: "#3c1b13",
	h: "#663325",
	i: "#1ab4ff",
	j: "#009fff",
	k: "#84635a",
	l: "#8d6f67",
	m: "#b39f9a",
	n: "#d8cecc",
};

export const LOGO_GRID: string[] = [
	".........aaaaaaabbbbbbbbbbcc....",
	"........aaaaaaaabbbbbbbbbbcc....",
	"........aaaaaaaabbbbbbbbbcccc...",
	".......aaaaaddddcccccbbbb.......",
	".......aaaaaddddcccccbbbb.......",
	".......aaaaaaaaabbbbbbbbb.......",
	".......aaaaaaaaabbbbbbbbb.......",
	".......aaaaaaaaabbbbbbbbb.......",
	"ee...ffbaaaaddddcccccbbbbggg...h",
	"ee...ffbaaaaddddcccccbbbbggg...h",
	"eeeefffbaaaaaaaabbbbbbbbbgggghhh",
	"eeeefffbaaaaaaaabbbbbbbbbgggghhh",
	"ee..iiiiiiaaddddcccccbbjjjjjj..h",
	"ee..iiiiiiiaddddcccccbjjjjjjj..h",
	"....iiiiiiiiiaaabbbbjjjjjjjjj...",
	"....iiiiiiiiiiiijjjjjjjjjjjjj...",
	"....iiiiiiiiiiiijjjjjjjjjjjjj...",
	"....ifffffffffffgggggggggggjj...",
	"....ifffffffffffgggggggggggjj...",
	"....ifffbfffbkffdggddggfdggjj...",
	"....ifflbmffbbffdggddggddggjj...",
	"....ifffffffffffgggggggggggjj...",
	"....ifffffffffffgggggggggggjj...",
	"....ifffbfffbbbbdddddgggdggjj...",
	"....iffdbnffbbbbdddddggddggjj...",
	"....ifffffffffffgggggggggggjj...",
	"....iiffffffffffgggggggggggj....",
	".....iiiiiiiiiiijjjjjjjjjjjj....",
	".....iiiiiiiiiiijjjjjjjjjjj.....",
];

// Right-pointing pixel arrow for the "Get Started" button, built directly
// in this orientation (not rotated from the scroll-hint's down-chevron) —
// a previous attempt rotated a non-square box with CSS transform, which
// visually overflows its own layout footprint since the box never resizes
// to match. Building it right-side-up from the start avoids that class of
// bug entirely. Grid is cropped tight to the arrow's own pixels (4 wide,
// not 8) — the original 8-wide version only ever drew in the left half,
// leaving the right half of its viewBox blank and shifting the visible
// glyph off-center within its icon box.
export const ARROW_COLS = 4;
export const ARROW_ROWS = 8;

export const ARROW_GRID: string[] = [
	"#...",
	"##..",
	".##.",
	"..##",
	"..##",
	".##.",
	"##..",
	"#...",
];

export interface PixelRect {
	x: number;
	y: number;
	w: number;
	fill?: string;
}

// merge horizontal runs of identical cells into single rects
export function gridToRects(
	rows: string[],
	palette?: Record<string, string>,
): PixelRect[] {
	const rects: PixelRect[] = [];
	rows.forEach((row, y) => {
		let x = 0;
		while (x < row.length) {
			const ch = row[x];
			if (ch === ".") {
				x++;
				continue;
			}
			let end = x + 1;
			while (end < row.length && row[end] === ch) end++;
			rects.push({
				x,
				y,
				w: end - x,
				fill: palette ? palette[ch] : undefined,
			});
			x = end;
		}
	});
	return rects;
}
