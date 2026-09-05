export type SpoilerVariant = "warning" | "danger" | "info" | "neutral";

const spoilerVariantNames = new Set<string>([
	"warning",
	"danger",
	"info",
	"neutral",
]);

export const isSpoilerVariant = (value: string): value is SpoilerVariant =>
	spoilerVariantNames.has(value);

export interface SpoilerParts {
	root: HTMLElement;
	bar: HTMLElement;
	shell: HTMLElement;
	content: HTMLElement;
	gate: HTMLElement;
	card: HTMLElement;
	revealButton: HTMLElement;
	hideButton: HTMLElement;
}

export interface SpoilerFrame {
	height: number;
	filter: string;
	opacity: string;
	gateOpacity: string;
	cardTransform: string;
}
