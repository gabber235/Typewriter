import type { ResolvedPath, WizardAnswer, WizardStep } from "./types";

export function panelKey(path: number[]): string {
	return path.join("-");
}

export function resolvePath(tree: WizardStep, path: number[]): ResolvedPath {
	const steps = [tree];
	let step = tree;
	for (const index of path) {
		const answer = step.answers[index];
		if (!answer) break;
		if (!answer.next) return { steps, result: answer };
		step = answer.next;
		steps.push(step);
	}
	return { steps, result: null };
}

/** Longest remaining chain of questions starting at (and including) `step`. */
export function remainingDepth(step: WizardStep): number {
	let deepest = 0;
	for (const answer of step.answers) {
		if (!answer.next) continue;
		deepest = Math.max(deepest, remainingDepth(answer.next));
	}
	return 1 + deepest;
}

/** The longest prefix of `path` that still exists in `tree`. */
export function validPrefix(tree: WizardStep, path: number[]): number[] {
	const valid: number[] = [];
	let step: WizardStep | null = tree;
	for (const index of path) {
		const answer: WizardAnswer | undefined = step?.answers[index];
		if (!answer) break;
		valid.push(index);
		step = answer.next;
		if (!step) break;
	}
	return valid;
}
