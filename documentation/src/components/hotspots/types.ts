import type { ListItem } from "mdast";

export interface HotspotsAttributes {
	numbers: boolean;
	legendVisible: boolean;
}

export interface HotspotCoords {
	x: number;
	y: number;
}

export interface HotspotEntry {
	item: ListItem;
	number: number;
	descriptionId: string;
	coords: HotspotCoords | null;
}

export interface HotspotPinEntry extends HotspotEntry {
	coords: HotspotCoords;
}

export type HotspotPlacement = "top" | "bottom";

export interface HotspotPair {
	pin: HTMLButtonElement | null;
	item: HTMLElement | null;
}

export interface HotspotPopover {
	element: HTMLElement;
	badge: HTMLElement;
	body: HTMLElement;
}
