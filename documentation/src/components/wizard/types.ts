export interface WizardStep {
	question: Node[];
	answers: WizardAnswer[];
}

export interface WizardAnswer {
	label: Node[];
	next: WizardStep | null;
	result: Node[];
}

export interface ParsedWizard {
	title: Node[] | null;
	tree: WizardStep;
}

export interface ResolvedPath {
	steps: WizardStep[];
	result: WizardAnswer | null;
}

export type WizardFocus =
	| { kind: "none" }
	| { kind: "first" }
	| { kind: "answer"; index: number };

export interface WizardElements {
	ui: HTMLElement;
	trailNav: HTMLElement;
	trail: HTMLOListElement;
	counter: HTMLElement;
	stage: HTMLElement;
	back: HTMLButtonElement;
	restart: HTMLButtonElement;
	live: HTMLElement;
}

export interface WizardContext {
	tree: WizardStep;
	elements: WizardElements;
	persistKey: string | null;
	id: string;
	/** The wizard's own name, used to keep its landmarks distinguishable. */
	label: string;
	/** Every reachable panel, keyed by answer path ("" = root question). */
	panels: Map<string, HTMLElement>;
	activeKey: string | null;
	hideTimer: number;
}

export interface WizardState {
	path: number[];
}
