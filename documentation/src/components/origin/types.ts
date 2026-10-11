import { z } from "astro/zod";

/**
 * How a page was written, ordered from fully human to fully AI. The order
 * matters: a level's index is how many of the meter's segments fill in.
 */
export const originLevels = [
	"human",
	"human-checked",
	"human-assisted",
	"ai-drafted-rewritten",
	"ai-drafted-reviewed",
	"ai-generated",
] as const;

export type OriginLevel = (typeof originLevels)[number];

/** Zod schema for the `aiDisclosure` frontmatter field. */
export const originSchema = z.enum(originLevels).optional();

export interface OriginInfo {
	label: string;
	/** One plain sentence: what a reader can assume about this page. */
	description: string;
}
