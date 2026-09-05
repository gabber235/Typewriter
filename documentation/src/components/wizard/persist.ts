import { validPrefix } from "./tree";
import type { WizardContext, WizardState } from "./types";

export function restorePath(wizard: WizardContext): number[] {
	if (!wizard.persistKey) return [];
	return validPrefix(wizard.tree, readStoredPath(wizard.persistKey));
}

export function persistPath(wizard: WizardContext, state: WizardState): void {
	if (!wizard.persistKey) return;
	try {
		sessionStorage.setItem(wizard.persistKey, JSON.stringify(state.path));
	} catch {
		// Storage can be unavailable (private mode, quota); the wizard still works.
	}
}

function readStoredPath(key: string): number[] {
	try {
		const parsed: unknown = JSON.parse(sessionStorage.getItem(key) ?? "");
		if (!Array.isArray(parsed)) return [];
		return parsed.filter((entry): entry is number => Number.isInteger(entry));
	} catch {
		return [];
	}
}
