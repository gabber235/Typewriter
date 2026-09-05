import type { Mockup } from "../shared/types";

export interface BuildProps {
	label: string;
	/** Seconds each item stays before the next one is shown. */
	interval?: number;
}

export interface BuildItemProps {
	title: string;
	mockup: Mockup;
}

export interface BuildElements {
	root: HTMLElement;
	tabs: HTMLButtonElement[];
	panels: HTMLElement[];
	stage: HTMLElement;
}

export interface BuildState {
	active: number;
	timer: number;
	paused: boolean;
}
