import type { OriginInfo, OriginLevel } from "./types";
import { originLevels } from "./types";

/**
 * Display text for each level, in the same order as `originLevels`. Kept as a
 * plain record (rather than folded into `originLevels`) so the ordinal scale
 * and its copy can change independently.
 */
export const originInfo: Record<OriginLevel, OriginInfo> = {
	human: {
		label: "Human-written",
		description: "Written and edited by a person. No AI was used.",
	},
	"human-checked": {
		label: "Human-written, AI-checked",
		description:
			"Written by a person; AI was used only to check grammar and spelling.",
	},
	"human-assisted": {
		label: "Human-written, AI-assisted",
		description:
			"Written by a person, using AI along the way for research, examples, or wording.",
	},
	"ai-drafted-rewritten": {
		label: "AI-drafted, human-rewritten",
		description:
			"An AI wrote the first draft; a person substantially rewrote and verified it.",
	},
	"ai-drafted-reviewed": {
		label: "AI-drafted, human-reviewed",
		description:
			"An AI wrote the draft; a person reviewed it and made small edits.",
	},
	"ai-generated": {
		label: "AI-generated",
		description: "Written entirely by AI and published without human changes.",
	},
};

/** How many of the meter's segments are filled for a given level. */
export function originStep(level: OriginLevel): number {
	return originLevels.indexOf(level);
}

export const ORIGIN_STEP_COUNT = originLevels.length - 1;
