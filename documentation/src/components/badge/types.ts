import { z } from 'astro/zod';

/**
 * Available badge variants for the documentation.
 * Only supports: new, experimental, deprecated
 */
export const badgeVariants = ['new', 'experimental', 'deprecated'] as const;

export type BadgeVariant = (typeof badgeVariants)[number];

/**
 * Zod schema for badge field in frontmatter.
 * Usage: `badge: new` or `badge: experimental` or `badge: deprecated`
 */
export const badgeSchema = z.enum(badgeVariants).optional();

/**
 * Badge display configuration.
 */
export interface Badge {
	text: string;
	variant: BadgeVariant;
}
