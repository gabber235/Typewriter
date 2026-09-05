import type { Cta, Mockup } from "../shared/types";

export interface StepProps {
	number: number;
	title: string;
	/** Screenshot for the media column; omit to render the default slot's `media` instead. */
	mockup?: Mockup;
}

export interface StepsProps {
	cta?: Cta;
}

export interface StepsElements {
	root: HTMLElement;
	steps: HTMLElement[];
	panels: HTMLElement[];
	stage: HTMLElement;
	line: HTMLElement;
	fill: HTMLElement;
}
