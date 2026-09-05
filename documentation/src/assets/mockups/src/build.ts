// Typewriter 1.0 panel placeholder mockups.
// Run from the documentation project root:  bun run <path>/build.ts
// Palette derived from panel/lib/app/presentation/theme/color_scheme.dart
// (neutral seed #62646A, Material 3 tonal surfaces) and the Material colours
// referenced in page_type_extensions.dart / shared/utilities/color.dart.

import { mkdirSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { join } from "node:path";

// Resolve sharp from the project the script is run from (documentation root).
const projectRequire = createRequire(join(process.cwd(), "package.json"));
const sharp: typeof import("sharp") = projectRequire("sharp");

const OUT = join(process.cwd(), "src", "assets", "mockups");
const SRC = join(OUT, "src");
mkdirSync(SRC, { recursive: true });

// ---------------------------------------------------------------------------
// Theme tokens
// ---------------------------------------------------------------------------
type Theme = {
	name: string;
	canvas: string; // scaffold / behind panes
	panel: string; // app bar, sidebar, panes
	container: string; // fields, tiles
	raised: string; // node bodies, chips
	emphasized: string; // selected tile
	border: string;
	borderStrong: string;
	textStrong: string;
	text: string;
	textMuted: string;
	bar: string;
	barLight: string;
	dot: string;
	scrim: string;
	on: string; // foreground on family colours
};

const dark: Theme = {
	name: "dark",
	canvas: "#131317",
	panel: "#1C1B20",
	container: "#232228",
	raised: "#2C2B31",
	emphasized: "#36353B",
	border: "#2F2E34",
	borderStrong: "#45464E",
	textStrong: "#D9D7DD",
	text: "#8A8990",
	textMuted: "#55545B",
	bar: "#3B3A41",
	barLight: "#5A595F",
	dot: "#45464E",
	scrim: "rgba(0,0,0,0.6)",
	on: "#FFFFFF",
};

const light: Theme = {
	name: "light",
	canvas: "#ECECF0",
	panel: "#FFFFFF",
	container: "#F1F1F4",
	raised: "#E7E7EA",
	emphasized: "#DCDCE1",
	border: "#DCDCE1",
	borderStrong: "#C6C5CD",
	textStrong: "#2A2A2E",
	text: "#6E6E76",
	textMuted: "#A9A9B0",
	bar: "#C9C9CF",
	barLight: "#DADAE0",
	dot: "#C6C5CD",
	scrim: "rgba(20,20,26,0.45)",
	on: "#FFFFFF",
};

// Family colours (see report): Material values used by the panel.
const F = {
	brand: "#009FFF", // _brandColor
	event: "#FF9800", // Colors.orange (accent/warning, scene page type)
	dialogue: "#2196F3", // Colors.blue (info, sequence page type)
	action: "#9C27B0", // Colors.purple (purpleAccent family in safeColors)
	manifest: "#4CAF50", // Colors.green (manifest page type, success/online)
	scene: "#FF4081", // Colors.pinkAccent (first safeColors entry)
	danger: "#FF5252", // Colors.redAccent
	online: "#4CAF50",
	offline: "#8F9098", // neutral.secondary
	deepPurple: "#673AB7",
};

// ---------------------------------------------------------------------------
// SVG primitives
// ---------------------------------------------------------------------------
const n = (v: number) => Math.round(v * 100) / 100;

function rect(
	x: number,
	y: number,
	w: number,
	h: number,
	r: number,
	fill: string,
	o: { stroke?: string; sw?: number; opacity?: number; dash?: string } = {},
) {
	const stroke = o.stroke
		? ` stroke="${o.stroke}" stroke-width="${o.sw ?? 1}"`
		: "";
	const op = o.opacity !== undefined ? ` opacity="${o.opacity}"` : "";
	const dash = o.dash ? ` stroke-dasharray="${o.dash}"` : "";
	return `<rect x="${n(x)}" y="${n(y)}" width="${n(w)}" height="${n(h)}" rx="${r}" fill="${fill}"${stroke}${op}${dash}/>`;
}
const bar = (
	x: number,
	y: number,
	w: number,
	h: number,
	fill: string,
	opacity?: number,
) => rect(x, y, w, h, h / 2, fill, { opacity });
const circle = (
	cx: number,
	cy: number,
	r: number,
	fill: string,
	opacity?: number,
) =>
	`<circle cx="${n(cx)}" cy="${n(cy)}" r="${r}" fill="${fill}"${opacity !== undefined ? ` opacity="${opacity}"` : ""}/>`;
const line = (
	x1: number,
	y1: number,
	x2: number,
	y2: number,
	stroke: string,
	sw = 1,
	opacity?: number,
) =>
	`<line x1="${n(x1)}" y1="${n(y1)}" x2="${n(x2)}" y2="${n(y2)}" stroke="${stroke}" stroke-width="${sw}" stroke-linecap="round"${opacity !== undefined ? ` opacity="${opacity}"` : ""}/>`;
const iconSq = (
	x: number,
	y: number,
	s: number,
	fill: string,
	opacity?: number,
) => rect(x, y, s, s, Math.max(2, s / 4), fill, { opacity });

function chevron(
	cx: number,
	cy: number,
	s: number,
	color: string,
	dir: "right" | "down" | "up" = "right",
	sw = 2,
) {
	const h = s / 2;
	let d = "";
	if (dir === "right")
		d = `M${n(cx - h / 2)} ${n(cy - h)} L${n(cx + h / 2)} ${cy} L${n(cx - h / 2)} ${n(cy + h)}`;
	if (dir === "down")
		d = `M${n(cx - h)} ${n(cy - h / 2)} L${cx} ${n(cy + h / 2)} L${n(cx + h)} ${n(cy - h / 2)}`;
	if (dir === "up")
		d = `M${n(cx - h)} ${n(cy + h / 2)} L${cx} ${n(cy - h / 2)} L${n(cx + h)} ${n(cy + h / 2)}`;
	return `<path d="${d}" fill="none" stroke="${color}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"/>`;
}
const plus = (cx: number, cy: number, s: number, color: string, sw = 2) =>
	line(cx - s / 2, cy, cx + s / 2, cy, color, sw) +
	line(cx, cy - s / 2, cx, cy + s / 2, color, sw);
const cross = (cx: number, cy: number, s: number, color: string, sw = 2) =>
	line(cx - s / 2, cy - s / 2, cx + s / 2, cy + s / 2, color, sw) +
	line(cx + s / 2, cy - s / 2, cx - s / 2, cy + s / 2, color, sw);
const searchGlyph = (cx: number, cy: number, s: number, color: string) =>
	`<circle cx="${n(cx - s * 0.12)}" cy="${n(cy - s * 0.12)}" r="${n(s * 0.32)}" fill="none" stroke="${color}" stroke-width="2"/>` +
	line(cx + s * 0.14, cy + s * 0.14, cx + s * 0.42, cy + s * 0.42, color, 2.4);
const menuGlyph = (cx: number, cy: number, s: number, color: string) =>
	[-1, 0, 1]
		.map((i) =>
			line(
				cx - s / 2,
				cy + i * (s / 3),
				cx + s / 2,
				cy + i * (s / 3),
				color,
				2,
			),
		)
		.join("");
const openGlyph = (cx: number, cy: number, s: number, color: string) =>
	`<path d="M${n(cx - s / 2)} ${n(cy - s / 6)} v${n(s * 0.66)} h${n(s * 0.66)} v${n(-s / 3)} M${n(cx - s / 6)} ${n(cy - s / 2)} h${n(s * 0.66)} v${n(s * 0.66)} M${n(cx + s / 2)} ${n(cy - s / 2)} L${n(cx - s / 8)} ${n(cy + s / 8)}" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`;
const diamond = (
	cx: number,
	cy: number,
	s: number,
	fill: string,
	stroke?: string,
) =>
	`<path d="M${cx} ${n(cy - s)} L${n(cx + s)} ${cy} L${cx} ${n(cy + s)} L${n(cx - s)} ${cy} Z" fill="${fill}"${stroke ? ` stroke="${stroke}" stroke-width="2"` : ""}/>`;

function arrowEdge(
	x1: number,
	y1: number,
	x2: number,
	y2: number,
	color: string,
	sw = 3,
) {
	const dx = x2 - x1;
	const dy = y2 - y1;
	const len = Math.hypot(dx, dy) || 1;
	const ux = dx / len;
	const uy = dy / len;
	const clear = 8;
	const tx = x2 - ux * clear;
	const ty = y2 - uy * clear;
	const al = 12;
	const aw = 9;
	const bx = tx - ux * al;
	const by = ty - uy * al;
	const px = -uy * aw;
	const py = ux * aw;
	return `<path d="M${n(x1)} ${n(y1)} L${n(tx)} ${n(ty)} M${n(tx)} ${n(ty)} L${n(bx + px)} ${n(by + py)} M${n(tx)} ${n(ty)} L${n(bx - px)} ${n(by - py)}" fill="none" stroke="${color}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"/>`;
}

let patternSeq = 0;
function dotGrid(
	x: number,
	y: number,
	w: number,
	h: number,
	t: Theme,
	cell = 50,
	r = 2,
) {
	const id = `dots${patternSeq++}`;
	return (
		`<defs><pattern id="${id}" x="${n(x)}" y="${n(y)}" width="${cell}" height="${cell}" patternUnits="userSpaceOnUse">` +
		`<circle cx="${cell / 2}" cy="${cell / 2}" r="${r}" fill="${t.dot}" opacity="0.55"/></pattern></defs>` +
		`<rect x="${n(x)}" y="${n(y)}" width="${n(w)}" height="${n(h)}" fill="url(#${id})"/>`
	);
}

let clipSeq = 0;
function clipped(
	x: number,
	y: number,
	w: number,
	h: number,
	r: number,
	inner: string,
) {
	const id = `clip${clipSeq++}`;
	return `<defs><clipPath id="${id}"><rect x="${n(x)}" y="${n(y)}" width="${n(w)}" height="${n(h)}" rx="${r}"/></clipPath></defs><g clip-path="url(#${id})">${inner}</g>`;
}

function svgDoc(w: number, h: number, body: string, bg?: string) {
	return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${bg ? rect(0, 0, w, h, 0, bg) : ""}${body}</svg>`;
}

// ---------------------------------------------------------------------------
// Shared components
// ---------------------------------------------------------------------------

/** Pane background: rounded card on the canvas. */
const pane = (t: Theme, x: number, y: number, w: number, h: number, r = 12) =>
	rect(x, y, w, h, r, t.panel, { stroke: t.border, sw: 1 });

/** App bar: organization selector › realm selector … trailing status pill. */
function appBar(
	t: Theme,
	x: number,
	y: number,
	w: number,
	o: { mobile?: boolean; brandLeft?: boolean } = {},
) {
	const h = 56;
	let s = rect(x, y, w, h, 8, t.panel, { stroke: t.border });
	const cy = y + h / 2;
	// organization selector (brand icon square + name bar), realm selector
	s += rect(x + 12, y + 10, 150, 36, 8, t.container);
	s += iconSq(x + 22, cy - 9, 18, F.brand);
	s += bar(x + 48, cy - 4, 92, 8, t.textStrong);
	s += chevron(x + 178, cy, 12, t.textMuted, "right");
	s += rect(x + 194, y + 10, 128, 36, 8, t.container);
	s += iconSq(x + 204, cy - 8, 16, t.text);
	s += bar(x + 228, cy - 4, 76, 8, t.textStrong);
	if (o.mobile) {
		s += menuGlyph(x + w - 30, cy, 18, t.textStrong);
		return s;
	}
	// trailing: realm status pill (online)
	const px = x + w - 12 - 120;
	s += rect(px, y + 12, 120, 32, 16, F.online, {
		opacity: t.name === "dark" ? 0.18 : 0.16,
	});
	s += circle(px + 18, cy, 5, F.online);
	s += bar(px + 32, cy - 4, 70, 8, F.online, 0.9);
	return s;
}

/** Sidebar with page tree. */
function pagesSidebar(
	t: Theme,
	x: number,
	y: number,
	w: number,
	h: number,
	o: { activeIndex?: number; kinds?: string[] } = {},
) {
	let s = pane(t, x, y, w, h, 8);
	const px = x + 12;
	const iw = w - 24;
	// header label
	s += bar(px + 4, y + 24, 56, 8, t.text);
	// search field
	s += rect(px, y + 48, iw, 36, 8, t.container, { stroke: t.border });
	s += searchGlyph(px + 18, y + 66, 16, t.textMuted);
	s += bar(px + 36, y + 62, 90, 8, t.textMuted);
	// tree
	let cy = y + 108;
	const tile = (
		yy: number,
		indent: number,
		selected: boolean,
		width: number,
		color: string,
	) => {
		let r = "";
		if (selected) r += rect(px + indent, yy, iw - indent, 36, 8, t.emphasized);
		r += iconSq(px + indent + 12, yy + 12, 12, color, selected ? 1 : 0.8);
		r += bar(
			px + indent + 32,
			yy + 14,
			width,
			8,
			selected ? t.textStrong : t.text,
		);
		r += chevron(px + iw - 14, yy + 18, 10, t.textMuted, "right");
		return r;
	};
	const chapter = (yy: number, open: boolean, width: number) =>
		chevron(px + 12, yy + 18, 10, t.text, open ? "down" : "right") +
		bar(px + 30, yy + 14, width, 8, t.textStrong);
	const active = o.activeIndex ?? 1;
	const kinds = o.kinds ?? [
		F.dialogue,
		F.dialogue,
		F.event,
		F.scene,
		F.manifest,
	];
	// chapter 1 (open) with 3 pages
	s += chapter(cy, true, 96);
	cy += 40;
	s += rect(px + 10, cy, 2, 3 * 40 - 4, 1, t.border);
	for (let i = 0; i < 3; i++) {
		s += tile(cy, 20, active === i, [100, 132, 88][i], kinds[i]);
		cy += 40;
	}
	// chapter 2 (open) with 2 pages
	s += chapter(cy, true, 72);
	cy += 40;
	s += rect(px + 10, cy, 2, 2 * 40 - 4, 1, t.border);
	for (let i = 3; i < 5; i++) {
		s += tile(cy, 20, active === i, [116, 96][i - 3], kinds[i]);
		cy += 40;
	}
	// chapter 3 (collapsed)
	s += chapter(cy, false, 110);
	cy += 40;
	// loose page
	s += tile(cy, 0, active === 5, 120, F.deepPurple);
	cy += 48;
	// add page button (outlined)
	s += rect(px, cy, iw, 36, 8, "none", { stroke: t.borderStrong, sw: 1.2 });
	s += plus(px + 20, cy + 18, 12, t.text);
	s += bar(px + 36, cy + 14, 72, 8, t.text);
	// footer links + user menu
	let fy = y + h - 132;
	for (let i = 0; i < 2; i++) {
		s += iconSq(px + 10, fy + 10, 16, t.text, 0.8);
		s += bar(px + 36, fy + 14, [64, 48][i], 8, t.text);
		s += openGlyph(px + iw - 18, fy + 18, 12, t.textMuted);
		fy += 40;
	}
	s += rect(px, fy, iw, 44, 8, t.container);
	s += circle(px + 22, fy + 22, 13, F.brand, 0.85);
	s += bar(px + 46, fy + 13, 96, 8, t.textStrong);
	s += bar(px + 46, fy + 26, 64, 6, t.textMuted);
	return s;
}

/** Entry node card: coloured header pill + body with bars/tags. */
function nodeCard(
	t: Theme,
	x: number,
	y: number,
	w: number,
	h: number,
	color: string,
	o: {
		selected?: boolean;
		tags?: number;
		reference?: boolean;
		sub?: number;
	} = {},
) {
	let s = "";
	if (o.reference) {
		// Reference entry: surface tinted with colour, 3px colour border, open-in-new suffix.
		s += rect(x, y, w, h, 8, t.panel);
		s += rect(x, y, w, h, 8, color, { opacity: 0.08 });
		s += rect(x + 1.5, y + 1.5, w - 3, h - 3, 7, "none", {
			stroke: color,
			sw: 3,
		});
		s += iconSq(x + 14, y + h / 2 - 8, 16, color);
		s += bar(x + 40, y + h / 2 - 9, w * 0.42, 8, color);
		s += bar(x + 40, y + h / 2 + 3, w * 0.3, 6, color, 0.6);
		s += openGlyph(x + w - 18, y + h / 2, 12, color);
		return s;
	}
	const hh = 32;
	s += rect(x, y, w, h, 10, t.raised, { stroke: t.border });
	s += rect(x, y, w, hh + 10, 10, color);
	s += rect(x, y + hh, w, 1, 0, color); // square off header bottom
	s += rect(x, y + hh, w, h - hh, 0, t.raised, { opacity: 0 }); // keep
	// header overlay to square bottom corners properly
	s += `<path d="M${n(x)} ${n(y + 10)} a10 10 0 0 1 10 -10 h${n(w - 20)} a10 10 0 0 1 10 10 v${hh - 10} h${n(-w)} z" fill="${color}"/>`;
	s += iconSq(x + 12, y + 9, 14, t.on, 0.92);
	s += bar(x + 34, y + 12, w * 0.46, 8, t.on, 0.92);
	const by = y + hh + 14;
	const sub = o.sub ?? 0.56;
	s += bar(x + 14, by, w * sub, 8, t.barLight);
	const tags = o.tags ?? 0;
	if (tags > 0) {
		let tx = x + 14;
		for (let i = 0; i < tags; i++) {
			const tw = [34, 46, 28][i % 3];
			s += rect(tx, by + 16, tw, 14, 7, color, {
				opacity: t.name === "dark" ? 0.3 : 0.2,
			});
			s += bar(tx + 8, by + 20, tw - 16, 6, color, 0.95);
			tx += tw + 6;
		}
	} else {
		s += bar(x + 14, by + 16, w * 0.34, 8, t.bar);
	}
	if (o.selected) {
		s += rect(x - 3, y - 3, w + 6, h + 6, 13, "none", {
			stroke: t.name === "dark" ? "#FFFFFF" : t.textStrong,
			sw: 2.5,
			opacity: 0.9,
		});
	}
	return s;
}

/** Compact (solid) entry node as used in timeline track headers. */
function compactNode(
	t: Theme,
	x: number,
	y: number,
	w: number,
	h: number,
	color: string,
	selected = false,
) {
	let s = rect(x, y, w, h, 8, color);
	s += iconSq(x + 12, y + h / 2 - 8, 16, t.on, 0.92);
	s += bar(x + 36, y + h / 2 - 4, w * 0.5, 8, t.on, 0.92);
	if (selected)
		s += rect(x + 3, y + 3, w - 6, h - 6, 5, "none", {
			stroke: "#FFFFFF",
			sw: 3,
		});
	return s;
}

type FieldKind =
	| "text"
	| "number"
	| "dropdown"
	| "reference"
	| "toggle"
	| "color"
	| "tags"
	| "list";

/** One inspector field row (label + editor). Returns [svg, height]. */
function field(
	t: Theme,
	x: number,
	y: number,
	w: number,
	kind: FieldKind,
	o: { color?: string; on?: boolean; labelW?: number; big?: number } = {},
): [string, number] {
	const k = o.big ?? 1; // scale factor for close-up
	const lw = o.labelW ?? 84;
	const color = o.color ?? F.dialogue;
	let s = bar(x, y, lw * k, 8 * k, t.text);
	const by = y + 16 * k;
	const bh = 36 * k;
	const box = (fill = t.container) =>
		rect(x, by, w, bh, 8 * k, fill, { stroke: t.border });
	switch (kind) {
		case "text":
			s += box();
			s += bar(x + 12 * k, by + bh / 2 - 4 * k, w * 0.55, 8 * k, t.textStrong);
			return [s, 16 * k + bh];
		case "number":
			s += rect(x, by, w * 0.42, bh, 8 * k, t.container, { stroke: t.border });
			s += bar(x + 12 * k, by + bh / 2 - 4 * k, w * 0.16, 8 * k, t.textStrong);
			s += line(
				x + w * 0.42 - 24 * k,
				by + 8 * k,
				x + w * 0.42 - 24 * k,
				by + bh - 8 * k,
				t.border,
				1,
			);
			s += chevron(
				x + w * 0.42 - 12 * k,
				by + bh * 0.33,
				8 * k,
				t.textMuted,
				"up",
				1.6,
			);
			s += chevron(
				x + w * 0.42 - 12 * k,
				by + bh * 0.68,
				8 * k,
				t.textMuted,
				"down",
				1.6,
			);
			return [s, 16 * k + bh];
		case "dropdown":
			s += box();
			s += iconSq(x + 12 * k, by + bh / 2 - 7 * k, 14 * k, t.text, 0.8);
			s += bar(x + 34 * k, by + bh / 2 - 4 * k, w * 0.4, 8 * k, t.textStrong);
			s += chevron(x + w - 18 * k, by + bh / 2, 12 * k, t.textMuted, "down");
			return [s, 16 * k + bh];
		case "reference": {
			s += box();
			const cw = w * 0.6;
			s += rect(
				x + 6 * k,
				by + 6 * k,
				cw,
				bh - 12 * k,
				(bh - 12 * k) / 2,
				color,
				{ opacity: t.name === "dark" ? 0.28 : 0.18 },
			);
			s += iconSq(x + 14 * k, by + bh / 2 - 6 * k, 12 * k, color);
			s += bar(x + 34 * k, by + bh / 2 - 4 * k, cw - 48 * k, 8 * k, color);
			s += openGlyph(x + w - 18 * k, by + bh / 2, 12 * k, t.textMuted);
			return [s, 16 * k + bh];
		}
		case "toggle": {
			// inline: label left, switch right
			const sw = 44 * k;
			const sh = 24 * k;
			const sx = x + w - sw;
			const sy = y - 8 * k;
			const on = o.on ?? true;
			let r = bar(x, y, lw * k, 8 * k, t.text);
			r += rect(sx, sy, sw, sh, sh / 2, on ? F.brand : t.emphasized, {
				stroke: on ? F.brand : t.borderStrong,
			});
			r += circle(
				on ? sx + sw - sh / 2 : sx + sh / 2,
				sy + sh / 2,
				sh / 2 - 4 * k,
				on ? "#FFFFFF" : t.text,
			);
			return [r, 8 * k];
		}
		case "color": {
			s += rect(x, by, bh, bh, 8 * k, color, { stroke: t.border });
			s += rect(x + bh + 8 * k, by, w - bh - 8 * k, bh, 8 * k, t.container, {
				stroke: t.border,
			});
			s += bar(
				x + bh + 20 * k,
				by + bh / 2 - 4 * k,
				w * 0.3,
				8 * k,
				t.textStrong,
			);
			return [s, 16 * k + bh];
		}
		case "tags": {
			let tx = x;
			const cols = [F.dialogue, F.event, F.manifest];
			const ws = [72, 96, 60];
			for (let i = 0; i < 3; i++) {
				const tw = ws[i] * k;
				s += rect(tx, by, tw, 26 * k, 13 * k, cols[i], {
					opacity: t.name === "dark" ? 0.28 : 0.18,
				});
				s += circle(tx + 13 * k, by + 13 * k, 4 * k, cols[i]);
				s += bar(tx + 24 * k, by + 10 * k, tw - 36 * k, 6 * k, cols[i]);
				tx += tw + 8 * k;
			}
			s += rect(tx, by, 26 * k, 26 * k, 13 * k, "none", {
				stroke: t.borderStrong,
				dash: "3 3",
			});
			s += plus(tx + 13 * k, by + 13 * k, 10 * k, t.text, 1.6);
			return [s, 16 * k + 26 * k];
		}
		case "list": {
			// two stacked reference chips (children)
			let yy = by;
			const cols = [color, color];
			for (let i = 0; i < 2; i++) {
				s += rect(x, yy, w, 32 * k, 8 * k, t.container, { stroke: t.border });
				s += iconSq(x + 10 * k, yy + 10 * k, 12 * k, cols[i]);
				s += bar(x + 30 * k, yy + 12 * k, w * [0.4, 0.3][i], 8 * k, cols[i]);
				s += openGlyph(x + w - 16 * k, yy + 16 * k, 11 * k, t.textMuted);
				yy += 38 * k;
			}
			s += rect(x, yy, w, 28 * k, 8 * k, "none", {
				stroke: t.borderStrong,
				dash: "3 3",
			});
			s += plus(x + w / 2, yy + 14 * k, 10 * k, t.text, 1.6);
			return [s, yy + 28 * k - y];
		}
	}
}

/** Inspector pane with header, fields, operations. */
function inspector(
	t: Theme,
	x: number,
	y: number,
	w: number,
	h: number,
	o: {
		color: string;
		fields: { kind: FieldKind; color?: string; on?: boolean }[];
		ops?: boolean;
		big?: number;
		noPane?: boolean;
		extraTop?: string;
	},
) {
	const k = o.big ?? 1;
	let s = o.noPane ? "" : pane(t, x, y, w, h, 12);
	const px = x + 16 * k;
	const iw = w - 32 * k;
	let cy = y + 24 * k;
	if (o.extraTop) {
		s += o.extraTop;
	}
	// header: title (coloured) + identifier
	s += bar(px, cy, iw * 0.6, 14 * k, o.color);
	cy += 22 * k;
	s += bar(px, cy, iw * 0.4, 7 * k, t.textMuted);
	cy += 24 * k;
	s += line(px, cy, px + iw, cy, t.border, 1);
	cy += 20 * k;
	for (const f of o.fields) {
		const [fs, fh] = field(t, px, cy, iw, f.kind, {
			color: f.color,
			on: f.on,
			big: k,
		});
		s += fs;
		cy += fh + 20 * k;
	}
	if (o.ops !== false) {
		cy += 8 * k;
		s += bar(px, cy, 78 * k, 8 * k, t.text);
		cy += 20 * k;
		// outlined brand, filled brand, filled danger
		s += rect(px, cy, 118 * k, 32 * k, 8 * k, "none", {
			stroke: F.brand,
			sw: 1.4,
		});
		s += plus(px + 16 * k, cy + 16 * k, 10 * k, F.brand);
		s += bar(px + 28 * k, cy + 12 * k, 74 * k, 8 * k, F.brand);
		cy += 42 * k;
		s += rect(px, cy, 108 * k, 32 * k, 8 * k, F.brand);
		s += iconSq(px + 10 * k, cy + 10 * k, 12 * k, "#FFFFFF", 0.9);
		s += bar(px + 28 * k, cy + 12 * k, 64 * k, 8 * k, "#FFFFFF", 0.95);
		cy += 42 * k;
		s += rect(px, cy, 112 * k, 32 * k, 8 * k, F.danger);
		s += iconSq(px + 10 * k, cy + 10 * k, 12 * k, "#FFFFFF", 0.9);
		s += bar(px + 28 * k, cy + 12 * k, 68 * k, 8 * k, "#FFFFFF", 0.95);
	}
	return s;
}

/** Bottom action row with shortcut hints. */
function actionRow(t: Theme, x: number, y: number, count = 4) {
	let s = "";
	let cx = x;
	const widths = [56, 40, 72, 48, 64];
	for (let i = 0; i < count; i++) {
		s += rect(cx, y, 26, 20, 4, t.container, { stroke: t.borderStrong });
		s += bar(cx + 7, y + 7, 12, 6, t.text);
		s += bar(cx + 34, y + 6, widths[i % widths.length], 8, t.textMuted);
		cx += 34 + widths[i % widths.length] + 28;
	}
	return s;
}

// ---------------------------------------------------------------------------
// Screen: page editor (1600x1000)
// ---------------------------------------------------------------------------
const W = 1600;
const H = 1000;

type EditorOpts = { selectedInSidebar?: number };

function pageEditor(t: Theme, o: EditorOpts = {}) {
	let s = "";
	s += appBar(t, 4, 4, W - 8);
	s += pagesSidebar(t, 8, 68, 280, 884, {
		activeIndex: o.selectedInSidebar ?? 1,
	});
	// main pane
	const gx = 296;
	const gy = 68;
	const gw = 888;
	const gh = 884;
	s += pane(t, gx, gy, gw, gh, 12);
	s += clipped(
		gx + 1,
		gy + 1,
		gw - 2,
		gh - 2,
		11,
		dotGrid(gx + 1, gy + 1, gw - 2, gh - 2, t),
	);
	// group (uses primary colour in the panel)
	const oy = 96; // vertical offset to centre the graph in the pane
	s += rect(gx + 316, gy + oy + 56, 250, 302, 10, F.brand, { opacity: 0.06 });
	s += rect(gx + 316, gy + oy + 56, 250, 302, 10, "none", {
		stroke: F.brand,
		sw: 1.5,
		opacity: 0.7,
	});
	s += bar(gx + 330, gy + oy + 68, 72, 8, F.brand, 0.9);
	// nodes
	const NW = 200;
	const NH = 88;
	const nodes: [
		number,
		number,
		string,
		{ selected?: boolean; tags?: number; sub?: number },
	][] = [
		[72, oy + 160, F.event, { tags: 2 }],
		[340, oy + 92, F.dialogue, { sub: 0.5 }],
		[340, oy + 250, F.dialogue, { tags: 1 }],
		[340, oy + 440, F.action, { sub: 0.62 }],
		[620, oy + 170, F.dialogue, { selected: true, tags: 2 }],
		[620, oy + 380, F.scene, { sub: 0.48 }],
		[620, oy + 560, F.action, { tags: 1 }],
	];
	const edges: [number, number][] = [
		[0, 1],
		[0, 2],
		[0, 3],
		[1, 4],
		[2, 4],
		[3, 5],
		[3, 6],
	];
	let e = "";
	for (const [a, b] of edges) {
		const A = nodes[a];
		const B = nodes[b];
		e += arrowEdge(
			gx + A[0] + NW,
			gy + A[1] + NH / 2,
			gx + B[0],
			gy + B[1] + NH / 2,
			A[2],
		);
	}
	s += e;
	for (const [nx, ny, c, opts] of nodes)
		s += nodeCard(t, gx + nx, gy + ny, NW, NH, c, opts);
	// inspector
	s += inspector(t, 1192, 68, 400, 884, {
		color: F.dialogue,
		fields: [
			{ kind: "text" },
			{ kind: "dropdown" },
			{ kind: "number" },
			{ kind: "reference", color: F.event },
			{ kind: "toggle", on: true },
			{ kind: "tags" },
		],
	});
	s += actionRow(t, 304, 964, 5);
	return s;
}

// ---------------------------------------------------------------------------
// Screen: scene editor (timeline)
// ---------------------------------------------------------------------------
function sceneEditor(t: Theme) {
	let s = "";
	s += appBar(t, 4, 4, W - 8);
	s += pagesSidebar(t, 8, 68, 280, 884, { activeIndex: 3 });
	const gx = 296;
	const gy = 68;
	const gw = 888;
	const gh = 884;
	s += pane(t, gx, gy, gw, gh, 12);
	const hw = 220; // header column
	const rh = 56; // ruler height
	const laneH = 60;
	const gap = 8;
	let inner = "";
	// header column + ruler backgrounds
	inner += rect(gx, gy, hw, gh, 0, t.container);
	inner += rect(gx + hw, gy, gw - hw, rh, 0, t.container);
	inner += line(gx, gy + rh, gx + gw, gy + rh, t.border, 1);
	inner += line(gx + hw, gy, gx + hw, gy + gh, t.border, 1);
	// top-left title
	inner += bar(gx + hw / 2 - 36, gy + rh / 2 - 5, 72, 10, t.textStrong);
	// ruler ticks
	const tx0 = gx + hw + 24;
	for (let x = tx0, i = 0; x < gx + gw - 8; x += 20, i++) {
		const major = i % 5 === 0;
		inner += line(
			x,
			major ? gy + 4 : gy + rh / 2,
			x,
			gy + rh - 1,
			t.borderStrong,
			major ? 1.2 : 1,
			major ? 0.9 : 0.45,
		);
		if (major) inner += bar(x + 5, gy + 10, 16, 6, t.text);
	}
	// tracks
	const tracks = [F.scene, F.dialogue, F.event, F.action, F.scene, F.dialogue];
	const segs: [number, number, number][][] = [
		[[0, 120, 380]],
		[
			[1, 60, 220],
			[1, 300, 200],
		],
		[
			[2, 20, 120],
			[2, 420, 160],
		],
		[[3, 200, 260]],
		[[4, 80, 500]],
		[
			[5, 40, 140],
			[5, 360, 260],
		],
	];
	let ty = gy + rh;
	for (let i = 0; i < tracks.length; i++) {
		const alt = i % 2 === 1;
		inner += rect(
			gx + hw,
			ty,
			gw - hw,
			laneH + gap,
			0,
			alt ? t.panel : t.canvas,
			{ opacity: alt ? 1 : 0.6 },
		);
		// grid lines through lanes
		for (let x = tx0, j = 0; x < gx + gw - 8; x += 20, j++) {
			if (j % 5 === 0)
				inner += line(x, ty, x, ty + laneH + gap, t.borderStrong, 1, 0.25);
		}
		// header node
		inner += compactNode(
			t,
			gx + 12,
			ty + 6,
			hw - 24,
			laneH - 4,
			tracks[i],
			i === 0,
		);
		inner += line(gx, ty + laneH + gap, gx + hw, ty + laneH + gap, t.border, 1);
		// segments
		for (const [, sx, sw] of segs[i]) {
			const x = tx0 + sx;
			const y = ty + 8;
			const h = laneH - 8;
			const sel = i === 0;
			inner += rect(x, y, sw, h, 16, tracks[i]);
			inner += rect(x + 3, y + 3, sw - 6, h - 6, 14, "none", {
				stroke: sel ? "#FFFFFF" : "#000000",
				sw: sel ? 2.5 : 1.5,
				opacity: sel ? 0.95 : 0.25,
			});
			inner += iconSq(x + 16, y + h / 2 - 7, 14, t.on, 0.92);
			inner += bar(
				x + 38,
				y + h / 2 - 4,
				Math.min(sw * 0.45, 120),
				8,
				t.on,
				0.92,
			);
		}
		// keyframes on track 3
		if (i === 2) {
			for (const kx of [220, 300, 360])
				inner += diamond(tx0 + kx, ty + laneH / 2 + 4, 9, tracks[i], t.panel);
		}
		if (i === 5) {
			for (const kx of [230, 700])
				inner += diamond(tx0 + kx, ty + laneH / 2 + 4, 9, tracks[i], t.panel);
		}
		ty += laneH + gap;
	}
	// playhead (abstracted; scrubber not in current panel code)
	const phx = tx0 + 300;
	inner += line(phx, gy + 6, phx, gy + gh, F.brand, 2);
	inner += `<path d="M${phx - 8} ${gy + 6} h16 l-8 12 z" fill="${F.brand}"/>`;
	s += clipped(gx + 1, gy + 1, gw - 2, gh - 2, 11, inner);
	// segment inspector
	s += inspector(t, 1192, 68, 400, 884, {
		color: F.scene,
		fields: [
			{ kind: "text" },
			{ kind: "number" },
			{ kind: "number" },
			{ kind: "dropdown" },
			{ kind: "reference", color: F.dialogue },
			{ kind: "toggle", on: false },
		],
	});
	s += actionRow(t, 304, 964, 5);
	return s;
}

// ---------------------------------------------------------------------------
// Screen: manifest page (audience tree, top-to-bottom)
// ---------------------------------------------------------------------------
function manifestEditor(t: Theme) {
	let s = "";
	s += appBar(t, 4, 4, W - 8);
	s += pagesSidebar(t, 8, 68, 280, 884, { activeIndex: 4 });
	const gx = 296;
	const gy = 68;
	const gw = 888;
	const gh = 884;
	s += pane(t, gx, gy, gw, gh, 12);
	s += clipped(
		gx + 1,
		gy + 1,
		gw - 2,
		gh - 2,
		11,
		dotGrid(gx + 1, gy + 1, gw - 2, gh - 2, t),
	);
	const NW = 200;
	const NH = 88;
	const M = F.manifest;
	const nodes: [
		number,
		number,
		string,
		{ selected?: boolean; tags?: number; sub?: number; reference?: boolean },
	][] = [
		[344, 70, M, { tags: 2 }],
		[110, 260, M, { sub: 0.5 }],
		[344, 260, M, { selected: true, tags: 1 }],
		[578, 260, M, { sub: 0.62 }],
		[110, 450, M, { tags: 1 }],
		[344, 450, M, { sub: 0.4 }],
		[578, 450, F.dialogue, { reference: true }],
		[227, 640, M, { tags: 2 }],
		[461, 640, F.event, { reference: true }],
	];
	const edges: [number, number][] = [
		[0, 1],
		[0, 2],
		[0, 3],
		[1, 4],
		[2, 5],
		[3, 6],
		[4, 7],
		[5, 7],
		[5, 8],
	];
	for (const [a, b] of edges) {
		const A = nodes[a];
		const B = nodes[b];
		s += arrowEdge(
			gx + A[0] + NW / 2,
			gy + A[1] + NH,
			gx + B[0] + NW / 2,
			gy + B[1],
			A[2],
		);
	}
	for (const [nx, ny, c, opts] of nodes)
		s += nodeCard(t, gx + nx, gy + ny, NW, NH, c, opts);
	s += inspector(t, 1192, 68, 400, 884, {
		color: M,
		fields: [
			{ kind: "text" },
			{ kind: "dropdown" },
			{ kind: "list", color: M },
			{ kind: "number" },
			{ kind: "toggle", on: true },
		],
	});
	s += actionRow(t, 304, 964, 4);
	return s;
}

// ---------------------------------------------------------------------------
// Screen: search palette over dimmed editor
// ---------------------------------------------------------------------------
function searchScreen(t: Theme) {
	let s = pageEditor(t);
	s += rect(0, 0, W, H, 0, t.scrim);
	// modal (880) + external preview (320) with 12 spacing, centred
	const mw = 880;
	const pw = 320;
	const total = mw + 12 + pw;
	const mx = (W - total) / 2;
	const my = 140;
	const mh = 700;
	s += rect(mx, my, mw, mh, 12, t.panel, { stroke: t.borderStrong });
	// query bar
	s += rect(mx, my, mw, 60, 12, t.container);
	s += rect(mx, my + 48, mw, 12, 0, t.container);
	s += searchGlyph(mx + 28, my + 30, 20, t.textStrong);
	// query: a selector chip + typed text
	s += rect(mx + 52, my + 16, 112, 28, 14, F.brand, {
		opacity: t.name === "dark" ? 0.28 : 0.18,
	});
	s += bar(mx + 64, my + 26, 88, 8, F.brand);
	s += bar(mx + 176, my + 26, 220, 8, t.textStrong);
	s += rect(mx + 398, my + 20, 2, 20, 1, F.brand); // caret
	s += cross(mx + mw - 28, my + 30, 12, t.text);
	s += line(mx, my + 60, mx + mw, my + 60, t.border, 1);
	// helper row: "You can use: [chips] to filter"
	let hy = my + 78;
	s += bar(mx + 20, hy, 70, 7, t.textMuted);
	let cx = mx + 98;
	for (const w of [48, 40, 56]) {
		s += rect(cx, hy - 5, w, 17, 8.5, t.raised, { stroke: t.border });
		s += bar(cx + 10, hy + 0.5, w - 20, 6, t.text);
		cx += w + 8;
	}
	s += bar(cx + 4, hy, 90, 7, t.textMuted);
	s += rect(mx + mw - 90, hy - 6, 24, 19, 4, t.container, {
		stroke: t.borderStrong,
	});
	s += bar(mx + mw - 84, hy, 12, 6, t.text);
	s += bar(mx + mw - 60, hy, 40, 7, t.textMuted);
	// filter chips row (selectors)
	hy += 30;
	cx = mx + 20;
	const chips: [number, string, boolean][] = [
		[88, F.brand, true],
		[72, t.text, false],
		[96, t.text, false],
		[64, t.text, false],
	];
	for (const [w, c, on] of chips) {
		s += rect(cx, hy, w, 26, 13, on ? c : t.container, {
			opacity: on ? (t.name === "dark" ? 0.28 : 0.18) : 1,
			stroke: on ? undefined : t.border,
		});
		s += bar(cx + 12, hy + 10, w - 24, 6, on ? c : t.text);
		cx += w + 8;
	}
	// section header
	hy += 46;
	s += chevron(mx + 28, hy + 12, 12, t.textStrong, "down");
	s += bar(mx + 44, hy + 8, 110, 9, t.textStrong);
	s += bar(mx + mw - 52, hy + 9, 32, 7, t.textMuted);
	hy += 36;
	// result rows
	const results: [string, boolean][] = [
		[F.dialogue, true],
		[F.event, false],
		[F.action, false],
		[F.scene, false],
		[F.manifest, false],
	];
	const rx = mx + 16;
	const rw = mw - 32;
	for (const [c, sel] of results) {
		s += rect(rx, hy, rw, 64, 8, c, {
			opacity: sel
				? t.name === "dark"
					? 0.22
					: 0.16
				: t.name === "dark"
					? 0.07
					: 0.06,
		});
		if (sel) s += rect(rx, hy, rw, 64, 8, "none", { stroke: c, sw: 1.4 });
		// icon tile 50x50
		s += rect(rx + 8, hy + 7, 50, 50, 4, c);
		s += iconSq(rx + 8 + 15, hy + 7 + 15, 20, t.on, 0.95);
		// title + description with bullets
		s += bar(rx + 72, hy + 18, 160, 9, t.textStrong);
		s += bar(rx + 72, hy + 38, 70, 7, t.text);
		s += circle(rx + 150, hy + 41.5, 2, t.textMuted);
		s += bar(rx + 158, hy + 38, 90, 7, t.text, 0.85);
		s += chevron(rx + 256, hy + 41.5, 6, t.textMuted, "right", 1.4);
		s += bar(rx + 266, hy + 38, 60, 7, t.text, 0.7);
		// tags
		s += circle(rx + 340, hy + 41.5, 2, t.textMuted);
		s += rect(rx + 350, hy + 34, 44, 15, 7.5, c, {
			opacity: t.name === "dark" ? 0.3 : 0.2,
		});
		s += bar(rx + 358, hy + 38.5, 28, 6, c);
		// suffix: type label + key chip
		s += bar(rx + rw - 88, hy + 28, 34, 7, t.textMuted);
		s += rect(rx + rw - 44, hy + 22, 30, 20, 4, sel ? "none" : t.container, {
			stroke: t.borderStrong,
		});
		s += bar(rx + rw - 37, hy + 29, 16, 6, t.text);
		hy += 72;
	}
	// second section header (collapsed)
	hy += 4;
	s += chevron(mx + 28, hy + 12, 12, t.textStrong, "right");
	s += bar(mx + 44, hy + 8, 84, 9, t.textStrong);
	s += bar(mx + mw - 52, hy + 9, 32, 7, t.textMuted);
	// bottom action row inside modal
	s += line(mx, my + mh - 44, mx + mw, my + mh - 44, t.border, 1);
	s += actionRow(t, mx + 20, my + mh - 32, 4);
	// preview card (external placement)
	const px = mx + mw + 12;
	s += rect(px, my, pw, mh, 12, t.panel, { stroke: t.borderStrong });
	s += nodeCard(t, px + 16, my + 16, pw - 32, 88, F.dialogue, { tags: 2 });
	s += inspector(t, px, my + 104, pw, mh - 104, {
		color: F.dialogue,
		noPane: true,
		ops: false,
		fields: [
			{ kind: "text" },
			{ kind: "dropdown" },
			{ kind: "reference", color: F.event },
			{ kind: "toggle", on: true },
			{ kind: "number" },
		],
	});
	return s;
}

// ---------------------------------------------------------------------------
// Screen: realm / book browser (library)
// ---------------------------------------------------------------------------
function libraryScreen(t: Theme) {
	let s = "";
	s += appBar(t, 4, 4, W - 8);
	// realm sidebar (links)
	const sx = 8;
	const sy = 68;
	const sw = 280;
	const sh = 884;
	s += pane(t, sx, sy, sw, sh, 8);
	const px = sx + 12;
	const iw = sw - 24;
	s += bar(px + 4, sy + 24, 56, 8, t.text);
	const links = [
		[true, 60],
		[false, 44],
		[false, 72],
		[false, 56],
	] as [boolean, number][];
	let ly = sy + 44;
	for (const [active, w] of links) {
		if (active) s += rect(px, ly, iw, 40, 8, t.emphasized);
		s += iconSq(px + 12, ly + 10, 20, active ? t.textStrong : t.text, 0.9);
		s += bar(px + 44, ly + 16, w, 8, active ? t.textStrong : t.text);
		ly += 44;
	}
	ly += 16;
	s += bar(px + 4, ly, 72, 8, t.text);
	ly += 20;
	for (const w of [88, 64, 100]) {
		s += iconSq(px + 12, ly + 10, 20, t.text, 0.8);
		s += bar(px + 44, ly + 16, w, 8, t.text);
		ly += 44;
	}
	// footer
	let fy = sy + sh - 132;
	for (let i = 0; i < 2; i++) {
		s += iconSq(px + 10, fy + 10, 16, t.text, 0.8);
		s += bar(px + 36, fy + 14, [64, 48][i], 8, t.text);
		s += openGlyph(px + iw - 18, fy + 18, 12, t.textMuted);
		fy += 40;
	}
	s += rect(px, fy, iw, 44, 8, t.container);
	s += circle(px + 22, fy + 22, 13, F.brand, 0.85);
	s += bar(px + 46, fy + 13, 96, 8, t.textStrong);
	s += bar(px + 46, fy + 26, 64, 6, t.textMuted);

	// main pane (library) spanning to the inspector
	const gx = 296;
	const gy = 68;
	const gw = 888;
	const gh = 884;
	s += pane(t, gx, gy, gw, gh, 12);
	// page heading
	s += bar(gx + 32, gy + 36, 150, 16, t.textStrong);
	s += bar(gx + 32, gy + 66, 520, 8, t.text);
	s += bar(gx + 32, gy + 82, 380, 8, t.text);
	// realm status line: org + realm + online dot
	s += iconSq(gx + gw - 200, gy + 36, 16, F.brand);
	s += bar(gx + gw - 176, gy + 40, 60, 8, t.text);
	s += chevron(gx + gw - 106, gy + 44, 10, t.textMuted);
	s += circle(gx + gw - 90, gy + 44, 5, F.online);
	s += bar(gx + gw - 78, gy + 40, 46, 8, t.text);
	// search
	s += rect(gx + 32, gy + 112, gw - 64, 40, 8, t.container, {
		stroke: t.border,
	});
	s += searchGlyph(gx + 52, gy + 132, 18, t.textMuted);
	s += bar(gx + 72, gy + 128, 120, 8, t.textMuted);
	// book grid: 175x230 cards, 16 spacing
	const bw = 175;
	const bh = 230;
	const cols = 4;
	const gridW = cols * bw + (cols - 1) * 24;
	const startX = gx + (gw - gridW) / 2;
	const by = gy + 184;
	const bookColors = [
		F.dialogue,
		F.event,
		F.action,
		F.manifest,
		F.scene,
		F.deepPurple,
		F.brand,
		F.event,
	];
	const online = [true, true, false, true, true, true, false, true];
	for (let i = 0; i < 8; i++) {
		const c = bookColors[i];
		const bx = startX + (i % cols) * (bw + 24);
		const yy = by + Math.floor(i / cols) * (bh + 40);
		const selected = i === 0;
		// spine layers (offset to the right, darker/desaturated)
		const spines = selected ? [14, 8, 4] : [5, 5, 5];
		const tops = selected ? [5, 10, 12] : [5, 5, 5];
		for (let j = 0; j < 3; j++) {
			s += rect(
				bx + spines[j],
				yy + tops[j],
				bw - spines[j],
				bh - tops[j] * 2,
				8,
				c,
				{ opacity: 0.35 + j * 0.12 },
			);
		}
		// cover
		s += rect(
			bx,
			yy + (selected ? 15 : 10),
			bw - (selected ? 16 : 6),
			bh - (selected ? 30 : 20),
			8,
			c,
		);
		if (selected)
			s += rect(bx - 3, yy + 12, bw - 10, bh - 24, 10, "none", {
				stroke: t.name === "dark" ? "#FFFFFF" : t.textStrong,
				sw: 2.5,
				opacity: 0.9,
			});
		const cx0 = bx + 16;
		const cy0 = yy + 32;
		s += iconSq(cx0, cy0, 28, t.on, 0.92);
		s += bar(cx0, cy0 + 44, 110, 10, t.on, 0.95);
		s += bar(cx0, cy0 + 62, 70, 10, t.on, 0.7);
		// page count + last edited (abstracted)
		s += iconSq(cx0, cy0 + 96, 10, t.on, 0.7);
		s += bar(cx0 + 16, cy0 + 98, 34, 6, t.on, 0.7);
		s += circle(
			cx0 + 62,
			cy0 + 101,
			4,
			online[i] ? F.online : t.on,
			online[i] ? 1 : 0.5,
		);
		s += bar(cx0 + 72, cy0 + 98, 48, 6, t.on, 0.6);
		// tag chips
		let tx = cx0;
		for (const tw of [44, 36]) {
			s += rect(tx, cy0 + 132, tw, 16, 8, t.on, { opacity: 0.22 });
			s += bar(tx + 8, cy0 + 137, tw - 16, 6, t.on, 0.9);
			tx += tw + 6;
		}
	}
	// floating add button
	s += circle(gx + gw - 44, gy + gh - 44, 24, F.brand);
	s += plus(gx + gw - 44, gy + gh - 44, 16, "#FFFFFF", 2.5);
	// inspector for the selected book
	s += inspector(t, 1192, 68, 400, 884, {
		color: F.dialogue,
		fields: [
			{ kind: "text" },
			{ kind: "color", color: F.dialogue },
			{ kind: "dropdown" },
			{ kind: "tags" },
			{ kind: "number" },
		],
	});
	s += actionRow(t, 304, 964, 4);
	return s;
}

// ---------------------------------------------------------------------------
// Screen: organization services with the "Connect a Service" dialog
// ---------------------------------------------------------------------------
function servicesScreen(t: Theme) {
	let s = "";
	s += appBar(t, 4, 4, W - 8);
	// organization sidebar (Services active) + realm links, same layout as the library
	const sx = 8;
	const sy = 68;
	const sw = 280;
	const sh = 884;
	s += pane(t, sx, sy, sw, sh, 8);
	const px = sx + 12;
	const iw = sw - 24;
	s += bar(px + 4, sy + 24, 84, 8, t.text);
	const links = [
		[true, 60],
		[false, 56],
		[false, 88],
		[false, 72],
	] as [boolean, number][];
	let ly = sy + 44;
	for (const [active, w] of links) {
		if (active) s += rect(px, ly, iw, 40, 8, t.emphasized);
		s += iconSq(px + 12, ly + 10, 20, active ? t.textStrong : t.text, 0.9);
		s += bar(px + 44, ly + 16, w, 8, active ? t.textStrong : t.text);
		ly += 44;
	}
	ly += 16;
	s += bar(px + 4, ly, 48, 8, t.text);
	ly += 20;
	for (const w of [56, 40]) {
		s += iconSq(px + 12, ly + 10, 20, t.text, 0.8);
		s += bar(px + 44, ly + 16, w, 8, t.text);
		ly += 44;
	}
	let fy = sy + sh - 132;
	for (let i = 0; i < 2; i++) {
		s += iconSq(px + 10, fy + 10, 16, t.text, 0.8);
		s += bar(px + 36, fy + 14, [64, 48][i], 8, t.text);
		s += openGlyph(px + iw - 18, fy + 18, 12, t.textMuted);
		fy += 40;
	}
	s += rect(px, fy, iw, 44, 8, t.container);
	s += circle(px + 22, fy + 22, 13, F.brand, 0.85);
	s += bar(px + 46, fy + 13, 96, 8, t.textStrong);
	s += bar(px + 46, fy + 26, 64, 6, t.textMuted);

	// main pane: service list
	const gx = 296;
	const gy = 68;
	const gw = 1296;
	const gh = 884;
	s += pane(t, gx, gy, gw, gh, 12);
	s += bar(gx + 32, gy + 36, 120, 16, t.textStrong);
	s += bar(gx + 32, gy + 66, 460, 8, t.text);
	// "Connect a Service" button, top right (outlined brand)
	s += rect(gx + gw - 32 - 176, gy + 30, 176, 40, 8, "none", {
		stroke: F.brand,
		sw: 1.4,
	});
	s += plus(gx + gw - 32 - 156, gy + 50, 12, F.brand);
	s += bar(gx + gw - 32 - 138, gy + 46, 120, 8, F.brand);
	// rows: realm (online), engine (online), engine (offline)
	const rows: [string, boolean][] = [
		[F.brand, true],
		[F.manifest, true],
		[t.text, false],
	];
	let ry = gy + 112;
	for (const [c, online] of rows) {
		s += rect(gx + 32, ry, gw - 64, 72, 10, t.container, { stroke: t.border });
		s += rect(gx + 48, ry + 16, 40, 40, 8, c, { opacity: online ? 1 : 0.5 });
		s += iconSq(gx + 58, ry + 26, 20, t.on, 0.92);
		s += bar(gx + 104, ry + 22, 150, 9, t.textStrong);
		s += bar(gx + 104, ry + 42, 90, 7, t.text);
		s += circle(gx + 210, ry + 45.5, 2, t.textMuted);
		s += bar(gx + 220, ry + 42, 60, 7, t.text, 0.8);
		// role chip
		s += rect(gx + 320, ry + 26, 72, 20, 10, c, {
			opacity: t.name === "dark" ? 0.28 : 0.18,
		});
		s += bar(gx + 332, ry + 33, 48, 6, c);
		// status pill on the right
		const spx = gx + gw - 32 - 16 - 100;
		const sc = online ? F.online : F.offline;
		s += rect(spx, ry + 22, 100, 28, 14, sc, {
			opacity: t.name === "dark" ? 0.18 : 0.16,
		});
		s += circle(spx + 16, ry + 36, 5, sc);
		s += bar(spx + 28, ry + 32, 56, 8, sc, 0.9);
		ry += 88;
	}

	// scrim + dialog
	s += rect(0, 0, W, H, 0, t.scrim);
	const dw = 640;
	const dh = 400;
	const dx = (W - dw) / 2;
	const dy = (H - dh) / 2;
	s += rect(dx, dy, dw, dh, 16, t.panel, { stroke: t.borderStrong });
	s += bar(dx + 32, dy + 36, 200, 14, t.textStrong);
	s += cross(dx + dw - 32, dy + 42, 12, t.text);
	s += bar(dx + 32, dy + 68, dw - 64, 8, t.text);
	s += bar(dx + 32, dy + 84, dw * 0.55, 8, t.text);
	// console hint: a log line the token is copied from
	s += rect(dx + 32, dy + 112, dw - 64, 44, 8, t.canvas, { stroke: t.border });
	s += bar(dx + 48, dy + 130, 40, 8, t.textMuted);
	s += bar(dx + 96, dy + 130, 120, 8, t.text);
	s += bar(dx + 226, dy + 130, 180, 8, F.brand, 0.9);
	// 10 token cells, 7 filled + active caret cell
	const cells = 10;
	const cw = 48;
	const cgap = 8;
	const cx0 = dx + (dw - (cells * cw + (cells - 1) * cgap)) / 2;
	const cy0 = dy + 192;
	for (let i = 0; i < cells; i++) {
		const x = cx0 + i * (cw + cgap);
		const active = i === 7;
		s += rect(x, cy0, cw, 56, 8, t.container, {
			stroke: active ? F.brand : t.border,
			sw: active ? 2 : 1,
		});
		if (i < 7) s += bar(x + 14, cy0 + 24, 20, 8, t.textStrong);
		if (active) s += rect(x + cw / 2 - 1, cy0 + 16, 2, 24, 1, F.brand);
	}
	// buttons: outlined cancel, filled connect
	const by = dy + dh - 32 - 40;
	s += rect(dx + dw - 32 - 128 - 12 - 108, by, 108, 40, 8, "none", {
		stroke: t.borderStrong,
		sw: 1.2,
	});
	s += bar(dx + dw - 32 - 128 - 12 - 108 + 30, by + 16, 48, 8, t.text);
	s += rect(dx + dw - 32 - 128, by, 128, 40, 8, F.brand);
	s += bar(dx + dw - 32 - 128 + 32, by + 16, 64, 8, "#FFFFFF", 0.95);
	return s;
}

// ---------------------------------------------------------------------------
// Screen: inspector close-up (1600x1000, scaled elements)
// ---------------------------------------------------------------------------
function inspectorCloseup(t: Theme) {
	let s = "";
	// left: canvas with one large node card
	const gx = 40;
	const gy = 40;
	const gw = 820;
	const gh = 920;
	s += pane(t, gx, gy, gw, gh, 16);
	s += clipped(
		gx + 1,
		gy + 1,
		gw - 2,
		gh - 2,
		15,
		dotGrid(gx + 1, gy + 1, gw - 2, gh - 2, t, 75, 3),
	);
	// big node (scaled 2x)
	const k = 1.9;
	const nx = gx + 100;
	const ny = gy + 280;
	const nr = nx + 240 * k; // right edge of the big node
	const nm = ny + (96 * k) / 2; // vertical middle
	s += `<g transform="translate(${nx} ${ny}) scale(${k})">${nodeCard(t, 0, 0, 240, 96, F.dialogue, { selected: true, tags: 2 })}</g>`;
	// incoming/outgoing edges
	s += arrowEdge(gx + 30, nm, nx - 2, nm, F.event, 5);
	s += arrowEdge(nr, nm, gx + gw - 30, nm, F.dialogue, 5);
	s += arrowEdge(nr, nm, gx + gw - 230, gy + 664, F.dialogue, 5);
	// faded neighbour node (fully right of the big node so the edge runs forward)
	s += `<g opacity="0.45">${nodeCard(t, gx + gw - 230, gy + 620, 200, 88, F.action, { sub: 0.5 })}</g>`;
	// right: inspector at 1.45x
	const ix = 900;
	const iy = 40;
	const iw = 660;
	const ih = 920;
	s += inspector(t, ix, iy, iw, ih, {
		color: F.dialogue,
		big: 1.45,
		fields: [
			{ kind: "text" },
			{ kind: "number" },
			{ kind: "dropdown" },
			{ kind: "reference", color: F.event },
			{ kind: "toggle", on: true },
			{ kind: "color", color: F.action },
			{ kind: "tags" },
		],
		ops: false,
	});
	return s;
}

// ---------------------------------------------------------------------------
// Screen: mobile (800x1600)
// ---------------------------------------------------------------------------
function mobileScreen(t: Theme) {
	const MW = 800;
	const MH = 1600;
	let s = "";
	s += appBar(t, 4, 4, MW - 8, { mobile: true });
	const gx = 8;
	const gy = 68;
	const gw = MW - 16;
	const gh = MH - 68 - 8 - 200; // leaves room for the bottom sheet
	s += pane(t, gx, gy, gw, gh - 8, 12);
	s += clipped(
		gx + 1,
		gy + 1,
		gw - 2,
		gh - 10,
		11,
		dotGrid(gx + 1, gy + 1, gw - 2, gh - 10, t),
	);
	const NW = 200;
	const NH = 88;
	// Top-to-bottom flow reads better in portrait: edges leave the bottom of a
	// node and enter the top of the next one.
	const nodes: [
		number,
		number,
		string,
		{ selected?: boolean; tags?: number; sub?: number },
	][] = [
		[292, 80, F.event, { tags: 2 }],
		[80, 300, F.dialogue, { sub: 0.5 }],
		[504, 300, F.dialogue, { selected: true, tags: 1 }],
		[80, 540, F.action, { sub: 0.62 }],
		[504, 540, F.scene, { tags: 2 }],
		[292, 780, F.dialogue, { sub: 0.45 }],
		[292, 1020, F.action, { tags: 1 }],
	];
	const edges: [number, number][] = [
		[0, 1],
		[0, 2],
		[1, 3],
		[2, 4],
		[3, 5],
		[4, 5],
		[5, 6],
	];
	for (const [a, b] of edges) {
		const A = nodes[a];
		const B = nodes[b];
		s += arrowEdge(
			gx + A[0] + NW / 2,
			gy + A[1] + NH,
			gx + B[0] + NW / 2,
			gy + B[1],
			A[2],
		);
	}
	for (const [nx, ny, c, o] of nodes)
		s += nodeCard(t, gx + nx, gy + ny, NW, NH, c, o);
	// floating action button
	s += circle(gx + gw - 48, gy + gh - 60, 26, F.brand);
	s += plus(gx + gw - 48, gy + gh - 60, 18, "#FFFFFF", 2.5);
	// bottom sheet (peek): handle + inspector header + first field
	const shy = MH - 200;
	s += rect(0, shy, MW, 200, 16, t.panel, { stroke: t.borderStrong });
	s += rect(0, shy + 16, MW, 184, 0, t.panel);
	s += bar(MW / 2 - 24, shy + 10, 48, 5, t.borderStrong);
	s += bar(24, shy + 34, 260, 14, F.dialogue);
	s += bar(24, shy + 56, 160, 7, t.textMuted);
	s += line(24, shy + 76, MW - 24, shy + 76, t.border, 1);
	const [fs] = field(t, 24, shy + 96, MW - 48, "text");
	s += fs;
	s += rect(MW - 96, shy + 30, 72, 30, 8, F.brand);
	s += bar(MW - 84, shy + 41, 48, 8, "#FFFFFF", 0.95);
	return svgDoc(MW, MH, s, t.canvas);
}

// ---------------------------------------------------------------------------
// Screen: hero with browser chrome (2400x1350, transparent)
// ---------------------------------------------------------------------------
function heroScreen(t: Theme) {
	const HW = 2400;
	const HH = 1350;
	const winW = 1800;
	const chrome = 56;
	const scale = winW / W;
	const winH = chrome + H * scale;
	const wx = (HW - winW) / 2;
	const wy = (HH - winH) / 2;
	let s = "";
	// soft shadow
	s += `<defs><filter id="shadow" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="28"/></filter></defs>`;
	s += `<rect x="${wx}" y="${wy + 36}" width="${winW}" height="${winH}" rx="18" fill="#000000" opacity="${t.name === "dark" ? 0.55 : 0.3}" filter="url(#shadow)"/>`;
	s += rect(wx, wy, winW, winH, 16, t.canvas, {
		stroke: t.borderStrong,
		sw: 1.5,
	});
	// chrome bar
	s += `<path d="M${wx} ${wy + 16} a16 16 0 0 1 16 -16 h${winW - 32} a16 16 0 0 1 16 16 v${chrome - 16} h${-winW} z" fill="${t.panel}"/>`;
	s += line(wx, wy + chrome, wx + winW, wy + chrome, t.border, 1);
	s += circle(wx + 28, wy + chrome / 2, 7, "#FF5F57");
	s += circle(wx + 52, wy + chrome / 2, 7, "#FEBC2E");
	s += circle(wx + 76, wy + chrome / 2, 7, "#28C840");
	// nav arrows
	s += chevron(wx + 118, wy + chrome / 2, 12, t.textMuted, "right");
	s += `<g transform="translate(${wx + 100} ${wy + chrome / 2}) scale(-1 1)">${chevron(0, 0, 12, t.text, "right")}</g>`;
	// url pill
	const uw = 640;
	const ux = wx + (winW - uw) / 2;
	s += rect(ux, wy + 12, uw, chrome - 24, (chrome - 24) / 2, t.container, {
		stroke: t.border,
	});
	s += iconSq(ux + 14, wy + chrome / 2 - 7, 14, t.textMuted);
	s += bar(ux + 38, wy + chrome / 2 - 4, 210, 8, t.text);
	// right icons
	s += iconSq(wx + winW - 40, wy + chrome / 2 - 8, 16, t.textMuted, 0.8);
	s += iconSq(wx + winW - 68, wy + chrome / 2 - 8, 16, t.textMuted, 0.8);
	// page content
	const content = `<g transform="translate(${wx} ${wy + chrome}) scale(${scale})">${rect(0, 0, W, H, 0, t.canvas)}${pageEditor(t)}</g>`;
	s += clipped(wx, wy, winW, winH, 16, content);
	return svgDoc(HW, HH, s);
}

// ---------------------------------------------------------------------------
// Render
// ---------------------------------------------------------------------------
type Job = { name: string; svg: string; alpha?: boolean; w: number; h: number };

const jobs: Job[] = [
	{
		name: "panel-pages",
		svg: svgDoc(W, H, pageEditor(dark), dark.canvas),
		w: W,
		h: H,
	},
	{
		name: "panel-pages-light",
		svg: svgDoc(W, H, pageEditor(light), light.canvas),
		w: W,
		h: H,
	},
	{
		name: "panel-scene",
		svg: svgDoc(W, H, sceneEditor(dark), dark.canvas),
		w: W,
		h: H,
	},
	{
		name: "panel-manifest",
		svg: svgDoc(W, H, manifestEditor(dark), dark.canvas),
		w: W,
		h: H,
	},
	{
		name: "panel-search",
		svg: svgDoc(W, H, searchScreen(dark), dark.canvas),
		w: W,
		h: H,
	},
	{
		name: "panel-library",
		svg: svgDoc(W, H, libraryScreen(dark), dark.canvas),
		w: W,
		h: H,
	},
	{
		name: "panel-inspector",
		svg: svgDoc(W, H, inspectorCloseup(dark), dark.canvas),
		w: W,
		h: H,
	},
	{
		name: "panel-connect",
		svg: svgDoc(W, H, servicesScreen(dark), dark.canvas),
		w: W,
		h: H,
	},
	{ name: "panel-mobile", svg: mobileScreen(dark), w: 800, h: 1600 },
	{
		name: "panel-hero-light",
		svg: heroScreen(light),
		alpha: true,
		w: 2400,
		h: 1350,
	},
	{
		name: "panel-hero-dark",
		svg: heroScreen(dark),
		alpha: true,
		w: 2400,
		h: 1350,
	},
];

async function main() {
	const rendered: { name: string; png: Buffer; w: number; h: number }[] = [];
	for (const job of jobs) {
		writeFileSync(join(SRC, `${job.name}.svg`), job.svg);
		const img = sharp(Buffer.from(job.svg), { density: 72 });
		const png = job.alpha
			? await img.png({ compressionLevel: 9 }).toBuffer()
			: await img
					.flatten({ background: "#000000" })
					.png({ compressionLevel: 9, palette: true, quality: 90, dither: 0.6 })
					.toBuffer();
		writeFileSync(join(OUT, `${job.name}.png`), png);
		rendered.push({ name: job.name, png, w: job.w, h: job.h });
	}

	// Contact sheet: 2400 wide, 4 columns, caption bar under each tile.
	const cols = 4;
	const cellW = 560;
	const pad = 40;
	const gapX = (2400 - cols * cellW) / (cols + 1);
	const thumbH = 330;
	const capH = 30;
	const cellH = thumbH + 12 + capH + pad;
	const rows = Math.ceil(rendered.length / cols);
	const sheetH = pad + rows * cellH + 20;
	const composites: sharp.OverlayOptions[] = [];
	let overlay = "";
	overlay += `<text x="${gapX}" y="${pad - 8}" font-family="Segoe UI, Helvetica, Arial, sans-serif" font-size="16" fill="#8A8990">Typewriter 1.0 panel mockups</text>`;
	for (let i = 0; i < rendered.length; i++) {
		const r = rendered[i];
		const col = i % cols;
		const row = Math.floor(i / cols);
		const cx = gapX + col * (cellW + gapX);
		const cy = pad + row * cellH;
		const sc = Math.min(cellW / r.w, thumbH / r.h);
		const tw = Math.round(r.w * sc);
		const th = Math.round(r.h * sc);
		const tx = Math.round(cx + (cellW - tw) / 2);
		const ty = Math.round(cy + (thumbH - th) / 2);
		const buf = await sharp(r.png)
			.resize(tw, th, { kernel: "lanczos3" })
			.png()
			.toBuffer();
		composites.push({ input: buf, left: tx, top: ty });
		overlay += rect(cx, cy, cellW, thumbH, 8, "#1C1B20", { stroke: "#2F2E34" });
		overlay += rect(cx, cy + thumbH + 12, cellW, capH, 6, "#232228");
		overlay += `<text x="${cx + 12}" y="${cy + thumbH + 12 + 20}" font-family="Consolas, Menlo, monospace" font-size="14" fill="#D9D7DD">${r.name}.png</text>`;
		overlay += `<text x="${cx + cellW - 12}" y="${cy + thumbH + 12 + 20}" text-anchor="end" font-family="Consolas, Menlo, monospace" font-size="13" fill="#8A8990">${r.w}x${r.h}</text>`;
	}
	const bg = svgDoc(2400, sheetH, overlay, "#131317");
	// Draw cell backgrounds first, then thumbs, then captions: split overlay.
	const sheet = await sharp(Buffer.from(bg))
		.composite(composites)
		.flatten({ background: "#131317" })
		.png({ compressionLevel: 9, palette: true, quality: 90, dither: 0.6 })
		.toBuffer();
	writeFileSync(join(OUT, "contact-sheet.png"), sheet);
	writeFileSync(join(SRC, "contact-sheet-overlay.svg"), bg);

	for (const f of [...jobs.map((j) => j.name), "contact-sheet"]) {
		const meta = await sharp(join(OUT, `${f}.png`)).metadata();
		const size = (await sharp(join(OUT, `${f}.png`)).toBuffer()).length;
		console.log(
			`${f}.png ${meta.width}x${meta.height} ${meta.hasAlpha ? "alpha" : "opaque"} ${(size / 1024).toFixed(0)} KB`,
		);
	}
}

main().catch((e) => {
	console.error(e);
	process.exit(1);
});
