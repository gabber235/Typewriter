export interface TabsProps {
	defaultTab?: number;
	syncKey?: string;
}

export interface TabItemProps {
	label: string;
}

export interface TabContext {
	container: HTMLElement;
	tablist: HTMLElement;
	pill: HTMLElement;
	buttons: HTMLButtonElement[];
	panels: HTMLElement[];
	labels: string[];
	syncKey: string | null;
}

export interface TabState {
	activeIndex: number;
}
