import type { Badge, BadgeVariant } from "./types";

/**
 * Badge configuration: display text and Tailwind classes for each variant.
 */
export const badgeConfig: Record<
	BadgeVariant,
	{ text: string; classes: string }
> = {
	// Light-mode text uses the 900 shades: the 500/700 tones are ~2.2:1 on
	// their own tinted chips, the dark ones are 6.5:1 and 5:1.
	new: {
		text: "New",
		classes:
			"bg-[var(--material-green-500)]/20 text-[var(--material-green-900)] dark:bg-[var(--material-green-500)]/10 dark:text-[var(--material-green-500)]",
	},
	experimental: {
		text: "Experimental",
		classes:
			"bg-[var(--material-orange-700)]/10 text-[var(--material-deep-orange-900)] dark:bg-[var(--material-orange-700)]/10 dark:text-[var(--material-orange-700)]",
	},
	deprecated: {
		text: "Deprecated",
		classes:
			"bg-[var(--material-brown-500)]/20 text-[var(--material-brown-500)] dark:bg-[var(--material-brown-200)]/20 dark:text-[var(--material-brown-100)]",
	},
};

/**
 * Get badge data from a variant.
 */
export function getBadge(variant: BadgeVariant | undefined): Badge | undefined {
	if (!variant) return undefined;
	const config = badgeConfig[variant];
	if (!config) return undefined;
	return { text: config.text, variant };
}

/**
 * Get the full CSS classes for a badge.
 */
export function getBadgeClasses(variant: BadgeVariant): string {
	const baseClasses = "ml-2 px-1.5 py-0.5 text-xs font-medium rounded shrink-0";
	const config = badgeConfig[variant];
	return `${baseClasses} ${config?.classes || ""}`;
}
